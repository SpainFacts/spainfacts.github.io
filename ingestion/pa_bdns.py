"""Fuente dlt `pa_bdns`: plazos de registro de las concesiones de subvenciones en la
BDNS, agregados por órgano concedente y mes de concesión, para el indicador
propio `pa_ind_bdns` (elaboración propia, ver docs/elaboracion-propia/bdns.md).

Obligación medida: art. 5.2.b del RD 130/2019 (BOE-A-2019-4671) y art. 20 de la
Ley 38/2003 General de Subvenciones: las concesiones se registran en la Base de
Datos Nacional de Subvenciones «antes de que finalice el mes siguiente» al de la
concesión. Plazo = último día del mes siguiente a `fechaConcesion`; fuera de
plazo = `fechaAlta` (alta en la BDNS) posterior a ese día.

Fuente: API REST pública del SNPSAP (IGAE), sin clave:
  https://www.infosubvenciones.es/bdnstrans/api/   (spec: /bdnstrans/estaticos/doc/snpsap-api.json)
  - GET /organos?idAdmon=L|A            árbol de órganos concedentes (id interno)
  - GET /organos/agrupacion?idAdmon=L|A provincia › municipio con el código INE de
                                        6 cifras (5 del municipio + dígito de control;
                                        las diputaciones son PP0000) o CCAA (01..19)
  - GET /concesiones/busqueda           concesiones por tipoAdministracion (L = entidades
                                        locales, A = comunidades autónomas) y fecha de
                                        concesión (fechaDesde/fechaHasta), pageSize 10.000,
                                        ordenadas por codConcesion (único: paginación estable)

Las concesiones NO se guardan una a una ni se guarda ningún beneficiario: se agregan
al vuelo por (nivel1, nivel2, nivel3, mes de concesión): nº de concesiones, nº fuera
de plazo, nº a personas físicas (NIF enmascarado «***»), importe y el histograma de
días entre concesión y alta (`dias_hist` = «dias:n;dias:n…», para la mediana en dbt).
Las filas de la API no traen el id del órgano, solo los nombres nivel2 (municipio,
diputación, cabildo… o comunidad) y nivel3 (órgano): el cruce con el árbol se hace
en dbt. Los dos pares de nombres que se repiten en provincias distintas (Cieza en
Cantabria y Murcia, El Molar en Madrid y Tarragona) se piden además con el filtro
`organos=<id>` y se guardan con su `id_organo` (en el resto de filas id_organo = 0).

TRAMPAS
- Ventana de 4 años (art. 7.8 RD 130/2019): la API solo enseña concesiones desde el
  1 de enero de hace 4 años (hoy, 2022). Recursos en MERGE, nunca replace.
- Las concesiones a personas físicas solo se publican el año de concesión y el
  siguiente: el año N medido después de N+1 pierde esas filas (sesgo de
  supervivencia). Por eso cada medición guarda `anio_medicion` y dbt usa, para el
  año N, la medición hecha en N+1 (la última de ese año); si no la hay, la última
  disponible, marcada como tardía.
- Dentro de un mismo `anio_medicion` cada mes se vuelve a pedir entero y sus filas
  llevan `fecha_medicion`; dbt se queda solo con las de la última medición de cada
  (tipo, mes) para que no queden órganos de una pasada anterior.
- «ERR_MANTENIMIENTO_BBDD»: la API lo devuelve también cuando una consulta tarda
  demasiado (p. ej. filtrar solo por fecha de registro): se usa la fecha de concesión.
- El SNPSAP advierte de que restringirá el acceso si hay abuso: un solo hilo, pausa
  entre páginas y User-Agent identificable.

Caché: data/bdns_cache/pa_bdns/<anio_medicion>/<tipo>_<AAAA-MM>.json con el agregado
de cada mes (pocos kB). Se reutiliza si tiene menos de `max_dias` días, o siempre si el
mes es de un año ya cerrado antes de N-1 (solo sirve de medición tardía). Así una
ejecución interrumpida se reanuda sin volver a descargar.

Volumen (medido 2026-10-25): EELL ~840.000 concesiones/año (≈85 páginas), CCAA
~5,2 millones/año (≈520 páginas de 7-8 MB, 5-7 s cada una).

Recursos:
  pa_bdns_organos          (merge, pk tipo_admon + id_organo)  árbol de órganos con su código
  pa_bdns_concesiones_mes  (merge, pk tipo_admon + nivel1/2/3 + id_organo + mes + anio_medicion)
  pa_bdns_control          (merge, pk tipo_admon + mes + anio_medicion)  totales por mes
  pa_bdns_convocatorias_mes (merge, misma pk que concesiones_mes)  nº de convocatorias por órgano y
                           mes de recepción (/convocatorias/busqueda, sin ventana de 4 años). Separa,
                           entre las entidades sin concesiones, las que sí convocan subvenciones (p. ej.
                           el Ayuntamiento de Sevilla: 679 convocatorias y ninguna concesión visible)

Años: por defecto se miden el año anterior y el actual (cada mes, en la ejecución mensual).
La primera carga pide toda la ventana: --anios 2022-2026 (EELL ~20 min, CCAA ~85 min).

Uso: python -m ingestion.pa_bdns [--tipos L,A] [--anios 2022-2026] [--max-dias 30] [--solo-cache [--que convocatorias]]
"""

from __future__ import annotations

import argparse
import calendar
import json
import logging
import time
from collections import defaultdict
from datetime import date, datetime, timezone
from pathlib import Path

import dlt
import requests

log = logging.getLogger(__name__)

API = "https://www.infosubvenciones.es/bdnstrans/api/"
CABECERAS = {
    "User-Agent": "SpainFacts/1.0 (+https://spainfacts.org; datos abiertos; indice de publicidad activa)",
    "Accept": "application/json",
}
PAGE_SIZE = 10000
PAUSA = 1.0  # segundos entre peticiones
CACHE = Path(__file__).resolve().parent.parent / "data" / "bdns_cache" / "pa_bdns"
NIVEL1 = {"L": "LOCAL", "A": "AUTONOMICA"}


def _get(ruta: str, **params):
    """GET con reintentos y espera creciente ante timeouts, 5xx o «ERR_MANTENIMIENTO_BBDD»."""
    params.setdefault("vpd", "GE")
    ultimo = None
    for intento in range(8):
        try:
            r = requests.get(API + ruta, params=params, headers=CABECERAS, timeout=180)
            r.raise_for_status()
            d = r.json()
            if isinstance(d, dict) and d.get("codigo"):
                raise RuntimeError(f"BDNS {d.get('codigo')}: {str(d.get('mensaje') or d.get('errores'))[:160]}")
            return d
        except Exception as e:  # noqa: BLE001
            ultimo = e
            espera = 15 * (intento + 1)
            log.warning("BDNS %s %s intento %d falló (%s); espero %ds", ruta, params, intento + 1, e, espera)
            time.sleep(espera)
    raise RuntimeError(f"BDNS {ruta} {params}: {ultimo}")


def _fecha(s):
    try:
        return date.fromisoformat(str(s)[:10])
    except (TypeError, ValueError):
        return None


def _plazo(f: date) -> date:
    """Último día del mes siguiente al de la concesión."""
    a, m = (f.year + 1, 1) if f.month == 12 else (f.year, f.month + 1)
    return date(a, m, calendar.monthrange(a, m)[1])


# --------------------------------------------------------------------------
# Árbol de órganos
# --------------------------------------------------------------------------


def arbol_organos(tipo: str) -> list[dict]:
    """Una fila por órgano concedente (nivel 3) con su nodo (nivel 2) y su código de agrupación."""
    arbol = _get("organos", idAdmon=tipo)
    time.sleep(PAUSA)
    agrup = _get("organos/agrupacion", idAdmon=tipo)
    filas = []
    if tipo == "L":
        cod = {(p["descripcion"], m["descripcion"]): m["id"] for p in agrup for m in p.get("children") or []}
        for prov in arbol:
            for nodo in prov.get("children") or []:
                for o in nodo.get("children") or []:
                    filas.append({
                        "tipo_admon": tipo, "id_organo": o["id"], "organo": o["descripcion"],
                        "id_nodo": nodo["id"], "nodo": nodo["descripcion"],
                        "id_grupo": prov["id"], "grupo": prov["descripcion"],
                        "cod_agrupacion": cod.get((prov["descripcion"], nodo["descripcion"])),
                    })
    else:
        cod = {c["descripcion"]: c["id"] for c in agrup}
        for ccaa in arbol:
            for o in ccaa.get("children") or []:
                filas.append({
                    "tipo_admon": tipo, "id_organo": o["id"], "organo": o["descripcion"],
                    "id_nodo": ccaa["id"], "nodo": ccaa["descripcion"],
                    "id_grupo": ccaa["id"], "grupo": ccaa["descripcion"],
                    "cod_agrupacion": cod.get(ccaa["descripcion"]),
                })
    return filas


def organos_ambiguos(filas: list[dict]) -> list[dict]:
    """Órganos cuyo par (nodo, órgano) se repite en nodos distintos: no se pueden casar por nombre."""
    por_par = defaultdict(set)
    for f in filas:
        por_par[(f["nodo"], f["organo"])].add(f["id_nodo"])
    return [f for f in filas if len(por_par[(f["nodo"], f["organo"])]) > 1]


# --------------------------------------------------------------------------
# Agregación de concesiones
# --------------------------------------------------------------------------


class Agregador:
    def __init__(self):
        self.g = defaultdict(lambda: {"n": 0, "n_fuera_plazo": 0, "n_sin_fecha_alta": 0, "n_negativos": 0,
                                      "n_persona_fisica": 0, "importe": 0.0, "hist": defaultdict(int),
                                      "fecha_alta_max": None})
        self.ids: set = set()
        self.duplicados = 0

    def add(self, r: dict, id_organo: int = 0):
        cod = r.get("codConcesion") or f"ID{r.get('id')}"
        if cod in self.ids:
            self.duplicados += 1
            return
        self.ids.add(cod)
        fc = _fecha(r.get("fechaConcesion"))
        if fc is None:
            return
        fa = _fecha(r.get("fechaAlta"))
        k = (r.get("nivel1") or "", r.get("nivel2") or "", r.get("nivel3") or "", id_organo, fc.strftime("%Y-%m"))
        a = self.g[k]
        a["n"] += 1
        if (r.get("beneficiario") or "").lstrip().startswith("*"):
            a["n_persona_fisica"] += 1
        if r.get("importe") is not None:
            a["importe"] += float(r["importe"])
        if fa is None:
            a["n_sin_fecha_alta"] += 1
            return
        dias = (fa - fc).days
        a["hist"][dias] += 1
        if dias < 0:
            a["n_negativos"] += 1
        if fa > _plazo(fc):
            a["n_fuera_plazo"] += 1
        fam = fa.isoformat()
        if a["fecha_alta_max"] is None or fam > a["fecha_alta_max"]:
            a["fecha_alta_max"] = fam

    def filas(self) -> list[dict]:
        out = []
        for (n1, n2, n3, ido, mes), a in self.g.items():
            out.append({
                "nivel1": n1, "nivel2": n2, "nivel3": n3, "id_organo": ido, "mes": mes,
                "n": a["n"], "n_fuera_plazo": a["n_fuera_plazo"], "n_sin_fecha_alta": a["n_sin_fecha_alta"],
                "n_negativos": a["n_negativos"], "n_persona_fisica": a["n_persona_fisica"],
                "importe": round(a["importe"], 2), "fecha_alta_max": a["fecha_alta_max"],
                "dias_hist": ";".join(f"{d}:{c}" for d, c in sorted(a["hist"].items())),
            })
        return out


def _paginas(ruta: str = "concesiones/busqueda", orden: str = "codConcesion", **filtros):
    """Recorre todas las páginas de una búsqueda con orden estable (codConcesion o numeroConvocatoria, únicos)."""
    pagina = 0
    while True:
        d = _get(ruta, page=pagina, pageSize=PAGE_SIZE, order=orden, direccion="asc", **filtros)
        yield d.get("content") or [], d.get("totalElements")
        pagina += 1
        time.sleep(PAUSA)
        if d.get("last", True) or pagina >= (d.get("totalPages") or 1):
            break


def medir_mes(tipo: str, anio: int, mes: int, ambiguos: list[dict]) -> dict:
    """Descarga y agrega todas las concesiones de un mes de concesión."""
    ini = date(anio, mes, 1)
    fin = date(anio, mes, calendar.monthrange(anio, mes)[1])
    t0 = time.time()
    ag = Agregador()
    total = None
    for filas, tot in _paginas(tipoAdministracion=tipo, fechaDesde=ini.strftime("%d/%m/%Y"),
                               fechaHasta=fin.strftime("%d/%m/%Y")):
        total = tot
        for r in filas:
            ag.add(r)
    n_unicos = len(ag.ids)
    # órganos con nombre repetido en otra provincia: se piden por id
    ag_id = Agregador()
    for o in ambiguos:
        for filas, _ in _paginas(organos=o["id_organo"], fechaDesde=ini.strftime("%d/%m/%Y"),
                                 fechaHasta=fin.strftime("%d/%m/%Y")):
            for r in filas:
                ag_id.add(r, id_organo=o["id_organo"])
    return {
        "tipo_admon": tipo, "mes": ini.strftime("%Y-%m"),
        "fecha_medicion": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "total_api": total, "n_descargadas": n_unicos, "n_duplicadas": ag.duplicados,
        "segundos": round(time.time() - t0, 1),
        "filas": ag.filas() + ag_id.filas(),
    }


def medir_convocatorias_mes(tipo: str, anio: int, mes: int, ambiguos: list[dict]) -> dict:
    """Cuenta las convocatorias registradas (fecha de recepción) en un mes, por órgano.

    Sirve para distinguir, entre las entidades sin concesiones, las que sí convocan
    subvenciones de las que no convocan ninguna."""
    ini = date(anio, mes, 1)
    fin = date(anio, mes, calendar.monthrange(anio, mes)[1])
    t0 = time.time()
    cuenta: dict = defaultdict(int)
    vistos: set = set()
    total = None

    def _suma(filas, id_organo=0):
        for r in filas:
            num = r.get("numeroConvocatoria") or f"ID{r.get('id')}"
            if (num, id_organo) in vistos:
                continue
            vistos.add((num, id_organo))
            fr = _fecha(r.get("fechaRecepcion"))
            if fr is None:
                continue
            cuenta[(r.get("nivel1") or "", r.get("nivel2") or "", r.get("nivel3") or "", id_organo,
                    fr.strftime("%Y-%m"))] += 1

    rango = dict(fechaDesde=ini.strftime("%d/%m/%Y"), fechaHasta=fin.strftime("%d/%m/%Y"))
    for filas, tot in _paginas("convocatorias/busqueda", "numeroConvocatoria", tipoAdministracion=tipo, **rango):
        total = tot
        _suma(filas)
    for o in ambiguos:
        for filas, _ in _paginas("convocatorias/busqueda", "numeroConvocatoria", organos=o["id_organo"], **rango):
            _suma(filas, o["id_organo"])
    return {
        "tipo_admon": tipo, "mes": ini.strftime("%Y-%m"),
        "fecha_medicion": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "total_api": total, "segundos": round(time.time() - t0, 1),
        "filas": [{"nivel1": a, "nivel2": b, "nivel3": c, "id_organo": i, "mes": m, "n_convocatorias": n}
                  for (a, b, c, i, m), n in cuenta.items()],
    }


def _meses(anios: list[int], hoy: date):
    for a in anios:
        for m in range(1, 13):
            if date(a, m, 1) <= hoy:
                yield a, m


def _cache_valida(ruta: Path, anio: int, anio_medicion: int, max_dias: float) -> bool:
    if not ruta.exists():
        return False
    if anio < anio_medicion - 1:  # año viejo: solo medición tardía, basta una por año de medición
        return True
    return (time.time() - ruta.stat().st_mtime) / 86400 < max_dias


def mediciones(tipos, anios, max_dias: float, hoy: date | None = None, que: str = "concesiones"):
    """Mediciones mensuales (de la caché o de la API). que = concesiones | convocatorias."""
    hoy = hoy or date.today()
    anio_medicion = hoy.year
    prefijo, medir = ("", medir_mes) if que == "concesiones" else ("CV_", medir_convocatorias_mes)
    for tipo in tipos:
        ambiguos = organos_ambiguos(arbol_organos(tipo))
        log.info("BDNS %s %s: %d órganos con nombre ambiguo: %s", que, tipo, len(ambiguos),
                 [(o["grupo"], o["organo"]) for o in ambiguos])
        for anio, mes in _meses(anios, hoy):
            ruta = CACHE / str(anio_medicion) / f"{prefijo}{tipo}_{anio}-{mes:02d}.json"
            if _cache_valida(ruta, anio, anio_medicion, max_dias):
                res = json.loads(ruta.read_text(encoding="utf-8"))
            else:
                res = medir(tipo, anio, mes, ambiguos)
                ruta.parent.mkdir(parents=True, exist_ok=True)
                tmp = ruta.with_suffix(".tmp")
                tmp.write_text(json.dumps(res, ensure_ascii=False), encoding="utf-8")
                tmp.replace(ruta)
                log.info("BDNS %s %s %s: %s (api %s, dup %s) en %ss, %d filas agregadas", que,
                         tipo, res["mes"], res.get("n_descargadas", sum(f["n_convocatorias"] for f in res["filas"])),
                         res["total_api"], res.get("n_duplicadas"), res["segundos"], len(res["filas"]))
            yield anio_medicion, res


# --------------------------------------------------------------------------
# Fuente dlt
# --------------------------------------------------------------------------


def anios_por_defecto(hoy: date) -> list[int]:
    """Año anterior y año en curso: el año N se mide durante N+1 y los anteriores ya
    tienen su medición guardada (merge). La primera carga pide la ventana entera."""
    return [hoy.year - 1, hoy.year]


@dlt.source(name="pa_bdns")
def pa_bdns(tipos: tuple[str, ...] = ("L", "A"), anios: list[int] | None = None, max_dias: float = 30):
    """anios: años de concesión a medir (por defecto, anios_por_defecto). La fecha se toma al
    ejecutar los recursos, no al crear la fuente (Dagster la crea al arrancar)."""

    def _hoy_y_anios():
        hoy = date.today()
        return hoy, (anios or anios_por_defecto(hoy))

    @dlt.resource(name="pa_bdns_organos", write_disposition="merge", primary_key=["tipo_admon", "id_organo"])
    def pa_bdns_organos():
        ahora = datetime.now(timezone.utc).isoformat(timespec="seconds")
        for tipo in tipos:
            for f in arbol_organos(tipo):
                yield {**f, "visto": ahora}
            time.sleep(PAUSA)

    # Las mediciones alimentan dos recursos: se calculan una vez y se reparten.
    cache_res: list = []

    def _todas():
        if not cache_res:
            hoy, an = _hoy_y_anios()
            cache_res.extend(mediciones(tipos, an, max_dias, hoy))
        return cache_res

    @dlt.resource(name="pa_bdns_concesiones_mes", write_disposition="merge",
                  primary_key=["tipo_admon", "nivel1", "nivel2", "nivel3", "id_organo", "mes", "anio_medicion"])
    def pa_bdns_concesiones_mes():
        for anio_medicion, res in _todas():
            for f in res["filas"]:
                yield {"tipo_admon": res["tipo_admon"], **f, "anio_medicion": anio_medicion,
                       "fecha_medicion": res["fecha_medicion"]}

    @dlt.resource(name="pa_bdns_control", write_disposition="merge",
                  primary_key=["tipo_admon", "mes", "anio_medicion"])
    def pa_bdns_control():
        for anio_medicion, res in _todas():
            yield {k: v for k, v in res.items() if k != "filas"} | {
                "anio_medicion": anio_medicion, "filas_agregadas": len(res["filas"])}

    @dlt.resource(name="pa_bdns_convocatorias_mes", write_disposition="merge",
                  primary_key=["tipo_admon", "nivel1", "nivel2", "nivel3", "id_organo", "mes", "anio_medicion"])
    def pa_bdns_convocatorias_mes():
        hoy, an = _hoy_y_anios()
        for anio_medicion, res in mediciones(tipos, an, max_dias, hoy, que="convocatorias"):
            for f in res["filas"]:
                yield {"tipo_admon": res["tipo_admon"], **f, "anio_medicion": anio_medicion,
                       "fecha_medicion": res["fecha_medicion"]}

    return pa_bdns_organos, pa_bdns_concesiones_mes, pa_bdns_control, pa_bdns_convocatorias_mes


def _anios(txt: str) -> list[int]:
    if "-" in txt:
        a, b = txt.split("-")
        return list(range(int(a), int(b) + 1))
    return [int(x) for x in txt.split(",")]


if __name__ == "__main__":
    import sys

    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s", stream=sys.stdout)
    from ingestion.destino import pipeline

    ap = argparse.ArgumentParser(description="Plazos de registro de concesiones en la BDNS (índice propio)")
    ap.add_argument("--tipos", default="L,A", help="L (entidades locales), A (CCAA); por defecto L,A")
    ap.add_argument("--anios", help="p. ej. 2022-2026 (primera carga: la ventana de 4 años + el actual) o 2025; "
                                    "por defecto, el año anterior y el actual")
    ap.add_argument("--max-dias", type=float, default=30, help="antigüedad máxima de la caché de cada mes")
    ap.add_argument("--solo-cache", action="store_true", help="descarga a la caché sin cargar en la base")
    ap.add_argument("--que", default="concesiones,convocatorias",
                    help="con --solo-cache: concesiones, convocatorias o ambas (por defecto)")
    a = ap.parse_args()
    tipos = tuple(t.strip().upper() for t in a.tipos.split(","))
    anios = _anios(a.anios) if a.anios else None
    t0 = time.time()
    if a.solo_cache:
        hoy = date.today()
        for que in a.que.split(","):
            for _ in mediciones(tipos, anios or anios_por_defecto(hoy), a.max_dias, hoy, que=que):
                pass
    else:
        print(datetime.now(), pipeline("pa_bdns").run(pa_bdns(tipos=tipos, anios=anios, max_dias=a.max_dias)))
    log.info("terminado en %.1f min", (time.time() - t0) / 60)
