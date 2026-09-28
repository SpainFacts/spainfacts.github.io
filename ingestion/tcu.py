"""Fuente dlt: cumplimiento de las entidades locales ante el Tribunal de Cuentas.

La Plataforma de Rendición de Cuentas de las Entidades Locales
(https://www.rendiciondecuentas.es, Tribunal de Cuentas y órganos de control
externo autonómicos) publica, entidad a entidad, si consta rendida cada
obligación. No hay API ni descarga masiva: solo páginas HTML, así que este
módulo tiene dos partes separadas:

1. Un rastreador (``python -m ingestion.tcu --crawl``) que descarga las páginas
   con mucha calma (una petición cada 2-5 s, espera larga ante un 403/5xx) y
   guarda el HTML tal cual en ``data/tcu_cache/`` (no versionado). La caché es
   por URL+parámetros: se puede matar y relanzar cuando se quiera y nunca
   vuelve a pedir lo que ya tiene (salvo los listados, que se refrescan en la
   actualización mensual ``--solo-recientes``).
2. Los recursos dlt, que leen SOLO de la caché (sin red): la carga en Dagster
   es rápida y reproducible.

Obligaciones (tres "consultas" del portal):
- ``cuenta_general`` (buscarCuentas/): Cuenta General del ejercicio N, plazo
  15 de octubre de N+1 (arts. 212.5 y 223.2 del TRLRHL). El listado da los tres
  últimos ejercicios; ``consultarCuentasEjercicios`` el histórico 2012-...; el
  detalle ``consultarCuenta`` trae la **fecha de envío**.
- ``control_interno`` (control/): información sobre acuerdos contrarios a
  reparos, anomalías de ingresos, etc. (art. 218.3 TRLRHL e Instrucción del TCu
  de 19/12/2019, BOE-A-2020-680), plazo 30 de abril de N+1. Desde 2020.
- ``contratos`` (contratos/): relación anual de contratos (art. 335 LCSP e
  Instrucción del TCu de 28/06/2018, BOE-A-2018-9585), plazo fin de febrero de
  N+1. Si no hubo contratos, se cumple con una certificación negativa: "no
  rendida" significa que no consta ni la relación ni la certificación.

País Vasco y Navarra no están en la plataforma (tienen sus propios órganos de
control externo) y no se rastrean.

Aviso legal del portal: el contenido es informativo. Solo se guardan datos
(estados y fechas), citando al Tribunal de Cuentas y la fecha de extracción.
"""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import logging
import random
import re
import sys
import time
from datetime import date, datetime, timezone
from pathlib import Path
from urllib.parse import urlencode

import dlt
import requests

REPO_ROOT = Path(__file__).resolve().parent.parent
CACHE = REPO_ROOT / "data" / "tcu_cache"

BASE = "https://www.rendiciondecuentas.es/es/consultadeentidadesycuentas/"
USER_AGENT = "SpainFacts/1.0 (+https://spainfacts.org; datos abiertos)"

# Sección del portal -> obligación
SECCIONES = {
    "buscarCuentas": "cuenta_general",
    "control": "control_interno",
    "contratos": "contratos",
}

TIPOS_ENTIDAD = {
    "A": "Ayuntamiento",
    "B": "Cabildo",
    "J": "Consejo Insular",
    "D": "Diputación Provincial",
    "E": "Entidad local menor",
    "G": "Agrupación de municipios",
    "T": "Área metropolitana",
    "R": "Comarca",
    "C": "Consorcio",
    "M": "Mancomunidad",
}
NOMBRE_A_TIPO = {v.lower(): k for k, v in TIPOS_ENTIDAD.items()}

# País Vasco (Álava, Gipuzkoa, Bizkaia) y Navarra: fuera de la plataforma.
PROVINCIAS_EXCLUIDAS = {"01", "20", "48", "31"}

# Texto del icono del portal -> estado normalizado
ESTADOS = {
    "cuenta rendida": "rendida",
    "cuenta no rendida": "no_rendida",
    "cuenta rendida no disponible": "rendida_no_disponible",
    "no aplica": "no_aplica",
}

log = logging.getLogger("tcu")

# --------------------------------------------------------------------------
# Caché en disco
# --------------------------------------------------------------------------


def _clave(metodo: str, url: str, params: dict) -> str:
    texto = f"{metodo} {url}?{urlencode(sorted(params.items()))}"
    return hashlib.sha1(texto.encode("utf-8")).hexdigest()


def _rutas(tipo: str, clave: str) -> tuple[Path, Path]:
    carpeta = CACHE / tipo / clave[:2]
    return carpeta / f"{clave}.html", carpeta / f"{clave}.json"


def _leer_meta(ruta: Path) -> dict | None:
    try:
        return json.loads(ruta.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None


def iterar_cache(tipo: str):
    """(meta, html) de cada página guardada de un tipo."""
    carpeta = CACHE / tipo
    if not carpeta.exists():
        return
    for meta_ruta in sorted(carpeta.glob("*/*.json")):
        meta = _leer_meta(meta_ruta)
        html_ruta = meta_ruta.with_suffix(".html")
        if meta is None or not html_ruta.exists():
            continue
        yield meta, html_ruta.read_bytes().decode("latin-1")


# --------------------------------------------------------------------------
# Cliente educado
# --------------------------------------------------------------------------


class Cliente:
    """Peticiones de una en una, con pausa aleatoria y espera ante bloqueos.

    El portal corta la conexión (o responde 403) si se le pide demasiado
    seguido. La pausa es adaptativa: cada bloqueo la multiplica por 1,5 (hasta
    x6) y cada 200 respuestas seguidas sin bloqueo la reduce un 10 %.
    """

    def __init__(self, pausa_min: float = 3.0, pausa_max: float = 6.0):
        self.pausa_min, self.pausa_max = pausa_min, pausa_max
        self.factor = self._leer_factor()
        self.seguidas = 0
        self.ultima = 0.0
        self.peticiones = 0
        self.bloqueos = 0
        self._nueva_sesion()

    # El factor de pausa se guarda en la caché para que un relanzamiento no
    # vuelva a empezar a toda velocidad.
    RUTA_RITMO = CACHE / "ritmo.json"

    def _leer_factor(self) -> float:
        try:
            return float(json.loads(self.RUTA_RITMO.read_text())["factor"])
        except (OSError, ValueError, KeyError):
            return 1.0

    def _guardar_factor(self):
        CACHE.mkdir(parents=True, exist_ok=True)
        self.RUTA_RITMO.write_text(json.dumps({"factor": round(self.factor, 3)}))

    def _nueva_sesion(self):
        self.s = requests.Session()
        self.s.headers.update({"User-Agent": USER_AGENT, "Accept-Language": "es"})

    def _esperar_turno(self):
        pausa = random.uniform(self.pausa_min, self.pausa_max) * self.factor
        falta = self.ultima + pausa - time.monotonic()
        if falta > 0:
            time.sleep(falta)

    def pedir(self, tipo: str, metodo: str, url: str, params: dict, *,
              refrescar_si_mas_de_dias: float | None = None,
              estados_validos=(200,)) -> tuple[int, str] | None:
        """Devuelve (status, html) desde la caché o la red. None si no se pudo."""
        clave = _clave(metodo, url, params)
        html_ruta, meta_ruta = _rutas(tipo, clave)
        meta = _leer_meta(meta_ruta) if meta_ruta.exists() else None
        if meta and html_ruta.exists():
            edad = (datetime.now(timezone.utc) - datetime.fromisoformat(meta["fecha"])).total_seconds() / 86400
            if refrescar_si_mas_de_dias is None or edad < refrescar_si_mas_de_dias:
                return meta["status"], html_ruta.read_bytes().decode("latin-1")

        espera = 300  # 5 min tras el primer bloqueo; se dobla hasta 1 h
        for intento in range(1, 13):
            self._esperar_turno()
            try:
                if metodo == "POST":
                    r = self.s.post(url, data=urlencode(params, encoding="latin-1"), timeout=60,
                                    headers={"Content-Type": "application/x-www-form-urlencoded"})
                else:
                    r = self.s.get(url, params=urlencode(params, encoding="latin-1"), timeout=60)
                status = r.status_code
            except requests.RequestException as e:
                status, r = None, None
                log.warning("error de red (%s: %.120s) en %s", e.__class__.__name__, str(e), url)
            self.ultima = time.monotonic()
            self.peticiones += 1
            if status is not None and (status in estados_validos or status == 200):
                self.seguidas += 1
                if self.seguidas % 200 == 0 and self.factor > 1:
                    self.factor = max(1.0, self.factor * 0.9)
                    self._guardar_factor()
                    log.info("pausa reducida: x%.2f", self.factor)
                html_ruta.parent.mkdir(parents=True, exist_ok=True)
                html_ruta.write_bytes(r.content)
                meta_ruta.write_text(json.dumps({
                    "metodo": metodo, "url": url, "params": params, "status": status,
                    "fecha": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                }, ensure_ascii=False), encoding="utf-8")
                return status, r.content.decode("latin-1")
            if status == 404:
                return None
            self.bloqueos += 1
            self.seguidas = 0
            self.factor = min(self.factor * 1.5, 6.0)
            self._guardar_factor()
            log.warning("HTTP %s en %s %s (intento %d, bloqueo %d tras %d peticiones): espero %d s; pausa x%.2f",
                        status, metodo, url, intento, self.bloqueos, self.peticiones, espera, self.factor)
            time.sleep(espera + random.uniform(0, 30))
            espera = min(espera * 2, 3600)
            self._nueva_sesion()
        log.error("abandono %s %s tras varios intentos", url, params)
        return None


# --------------------------------------------------------------------------
# Análisis del HTML
# --------------------------------------------------------------------------


def _limpiar(s: str) -> str:
    return html.unescape(re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", s))).strip()


def _fecha(s: str | None) -> date | None:
    m = re.search(r"(\d{2})/(\d{2})/(\d{4})", s or "")
    return date(int(m.group(3)), int(m.group(2)), int(m.group(1))) if m else None


def provincias_de_formulario(texto: str) -> list[tuple[str, str, str]]:
    """(id_ccaa_tcu, cod_prov, nombre) de las opciones del formulario de búsqueda."""
    return [(ca, prov.zfill(2), html.unescape(n).strip())
            for ca, prov, n in re.findall(r'<option\s+class="idCa_(\d+)"\s+value="(\d+)"\s*>([^<]*)</option>', texto)]


def analizar_listado(texto: str) -> dict:
    """Cabecera, filas y total de una página de listado."""
    total = re.search(r"Se han encontrado\s+([\d.]+)", texto)
    tabla = re.search(r'<table[^>]*id="resultados".*?</table>', texto, re.S)
    paginas = max([int(x) for x in re.findall(r"d-2677838-p=(\d+)", texto)] + [1])
    if not tabla:
        return {"total": 0 if re.search(r"No se ha(n)? encontrado", texto) else None,
                "cabecera": [], "filas": [], "paginas": 1}
    tb = tabla.group(0)
    cabecera = [_limpiar(h) for h in re.findall(r"<th[^>]*>(.*?)</th>", tb, re.S)]
    filas = []
    for tr in re.findall(r'<tr class="(?:odd|even)">(.*?)</tr>', tb, re.S):
        celdas = []
        for td in re.findall(r"<td[^>]*>(.*?)</td>", tr, re.S):
            alt = re.findall(r'alt="([^"]*)"', td)
            ide = re.findall(r"idEntidad=(\d+)", td)
            celdas.append({"texto": _limpiar(td), "icono": html.unescape(alt[0]).strip() if alt else None,
                           "id_entidad": int(ide[0]) if ide else None,
                           "enlace": html.unescape(re.findall(r'href="([^"]*)"', td)[0]) if "href=" in td else None})
        filas.append(celdas)
    return {"total": int(total.group(1).replace(".", "")) if total else len(filas),
            "cabecera": cabecera, "filas": filas, "paginas": paginas}


def filas_listado(texto: str):
    """Filas del listado como dicts: tipo, nombre, id_entidad, {ejercicio: (icono, enlazado)}."""
    datos = analizar_listado(texto)
    anios = [(i, int(m.group(1))) for i, h in enumerate(datos["cabecera"])
             if (m := re.search(r"Ejercicio\s+(\d{4})", h))]
    for celdas in datos["filas"]:
        if len(celdas) < 2:
            continue
        ide = next((c["id_entidad"] for c in celdas if c["id_entidad"]), None)
        yield {
            "tipo": NOMBRE_A_TIPO.get(celdas[0]["texto"].lower(), celdas[0]["texto"]),
            "nombre": celdas[1]["texto"],
            "id_entidad": ide,
            "ejercicios": {a: (celdas[i]["icono"], bool(celdas[i]["enlace"]))
                           for i, a in anios if i < len(celdas)},
        }


def analizar_ejercicios(texto: str) -> dict[int, tuple[str | None, bool]]:
    """Histórico de la Cuenta General: {ejercicio: (icono, enlazado)}."""
    tabla = re.search(r'<table[^>]*id="resultados".*?</table>', texto, re.S)
    if not tabla:
        return {}
    tb = tabla.group(0)
    anios = [int(a) for a in re.findall(r"Ejercicio\s*<span>\s*(\d{4})", tb)]
    if not anios:
        anios = [int(a) for a in re.findall(r"Ejercicio\D{0,40}?(\d{4})", _limpiar(re.search(r"<thead>.*?</thead>", tb, re.S).group(0)))]
    celdas = re.findall(r"<td[^>]*>(.*?)</td>", tb, re.S)
    out = {}
    for a, td in zip(anios, celdas):
        alt = re.findall(r'alt="([^"]*)"', td)
        icono = html.unescape(alt[0]).strip() if alt else (_limpiar(td) or None)
        out[a] = (icono, "href=" in td)
    return out


def analizar_censo(texto: str) -> dict:
    # La ficha trae después las entidades dependientes, participadas y las
    # mancomunidades de las que forma parte, con los mismos campos: solo se lee
    # el primer bloque ("Entidad Principal").
    bloques = re.split(r'<h3 class="cabeza">', texto)
    if len(bloques) > 1:
        texto = bloques[1]
    campos = dict(
        (html.unescape(k).strip().rstrip(":").strip(), _limpiar(v))
        for k, v in re.findall(r"<td>([^<]*:)\s*</td>\s*<td class=\"fnd\">(.*?)</td>", texto, re.S)
    )
    pob = campos.get("Población", "").replace(".", "")
    return {
        "nif": campos.get("NIF") or None,
        "estado_actividad": campos.get("Estado de actividad") or None,
        "tipo_nombre": campos.get("Tipo de Entidad") or None,
        "poblacion": int(pob) if pob.isdigit() else None,
        "denominacion": campos.get("Denominación") or None,
        "codigo_map": campos.get("Código MAP") or None,
        "codigo_meh": campos.get("Código MEH") or None,
        "municipio": campos.get("Municipio") or None,
        "provincia": campos.get("Provincia") or None,
    }


def analizar_cuenta(texto: str) -> dict:
    fechas = {}
    for k, v in re.findall(r"<th>([^<]*)</th>\s*<td class=\"fnd\">(.*?)</td>", texto, re.S):
        fechas[html.unescape(k).strip()] = _fecha(v)
    return {
        "fecha_envio": fechas.get("Fecha de envío"),
        "fecha_aprobacion": fechas.get("Fecha de aprobación de la Cuenta General"),
    }


# --------------------------------------------------------------------------
# Rastreo
# --------------------------------------------------------------------------

URL_FORM = BASE + "buscarEntidades/"
URL_CENSO = BASE + "buscarEntidades/consultarEntidad.html"
URL_EJERCICIOS = BASE + "buscarCuentas/consultarCuentasEjercicios.html"
URL_CUENTA = BASE + "buscarCuentas/consultarCuenta.html"


def _url_listado(seccion: str) -> str:
    return BASE + f"{seccion}/index.html"


def _params_listado(ca: str, prov: str, tipo: str, pagina: int) -> dict:
    p = {"idComunidadAutonoma": ca, "idProvincia": str(int(prov)), "idTipoEntidad": tipo,
         "denominacion": "", "submitFormBusquedaGeneral": "Buscar"}
    if pagina > 1:
        p["d-2677838-p"] = str(pagina)
    return p


def rastrear_listado(cli: Cliente, seccion: str, ca: str, prov: str, tipo: str, refrescar: float | None) -> list[dict]:
    """Todas las páginas de un listado (sección, provincia, tipo)."""
    filas, pagina, paginas = [], 1, 1
    # Al refrescar se abre sesión nueva: la paginación depende de la búsqueda (POST)
    # de la página 1 en la misma sesión.
    while pagina <= paginas:
        metodo = "POST" if pagina == 1 else "GET"
        res = cli.pedir(f"listado_{seccion}", metodo, _url_listado(seccion),
                        _params_listado(ca, prov, tipo, pagina), refrescar_si_mas_de_dias=refrescar)
        if res is None:
            log.error("listado incompleto %s %s %s página %d", seccion, prov, tipo, pagina)
            break
        datos = analizar_listado(res[1])
        if pagina == 1:
            paginas = datos["paginas"]
        filas.extend(filas_listado(res[1]))
        pagina += 1
    return filas


def crawl(provincias: list[str] | None = None, tipos: list[str] = ("A",), solo_recientes: bool = False,
          detalle_desde: int = 2012, refrescar_dias: float | None = None):
    cli = Cliente()
    res = cli.pedir("formulario", "GET", URL_FORM, {}, refrescar_si_mas_de_dias=30)
    if res is None:
        raise SystemExit("No se pudo leer el formulario de provincias")
    provs = [p for p in provincias_de_formulario(res[1]) if p[1] not in PROVINCIAS_EXCLUIDAS]
    if provincias:
        provs = [p for p in provs if p[1] in {x.zfill(2) for x in provincias}]
    if solo_recientes and refrescar_dias is None:
        refrescar_dias = 20
    log.info("provincias: %d, tipos: %s, solo_recientes=%s", len(provs), ",".join(tipos), solo_recientes)

    # Fase 1: listados (las tres obligaciones, últimos ejercicios)
    entidades: dict[int, dict] = {}
    pendientes_cuenta: list[tuple[int, int]] = []
    for ca, prov, nombre in provs:
        for tipo in tipos:
            for seccion in SECCIONES:
                filas = rastrear_listado(cli, seccion, ca, prov, tipo, refrescar_dias)
                if seccion == "buscarCuentas":
                    for f in filas:
                        if f["id_entidad"]:
                            entidades[f["id_entidad"]] = {"prov": prov, "tipo": tipo, "nombre": f["nombre"]}
                            for anio, (icono, enlazado) in f["ejercicios"].items():
                                if enlazado and ESTADOS.get((icono or "").lower()) == "rendida":
                                    pendientes_cuenta.append((f["id_entidad"], anio))
                log.info("[listado] %s %s %s tipo %s: %d filas (peticiones: %d)",
                         seccion, prov, nombre, tipo, len(filas), cli.peticiones)

    # Fase 2: censo (NIF, población, códigos) de cada entidad
    ids = sorted(entidades)
    for n, ide in enumerate(ids, 1):
        cli.pedir("censo", "POST", URL_CENSO, _params_censo(ide, entidades[ide]["tipo"]))
        if n % 100 == 0:
            log.info("[censo] %d/%d (peticiones: %d)", n, len(ids), cli.peticiones)

    # Fase 3: detalle con fecha de envío de los últimos ejercicios rendidos
    for n, (ide, anio) in enumerate(sorted(pendientes_cuenta, key=lambda x: (-x[1], x[0])), 1):
        cli.pedir("cuenta", "GET", URL_CUENTA, {"idEntidad": str(ide), "ejercicio": str(anio)},
                  estados_validos=(200, 500))
        if n % 100 == 0:
            log.info("[cuenta reciente] %d/%d (peticiones: %d)", n, len(pendientes_cuenta), cli.peticiones)

    if solo_recientes:
        log.info("fin (solo recientes). Peticiones a la red: %d", cli.peticiones)
        return

    # Fase 4: histórico de la Cuenta General de cada entidad
    historicos: list[tuple[int, int]] = []
    for n, ide in enumerate(ids, 1):
        res = cli.pedir("ejercicios", "GET", URL_EJERCICIOS, {"idEntidad": str(ide)})
        if res:
            for anio, (icono, enlazado) in analizar_ejercicios(res[1]).items():
                if enlazado and anio >= detalle_desde and ESTADOS.get((icono or "").lower()) == "rendida":
                    historicos.append((ide, anio))
        if n % 100 == 0:
            log.info("[histórico] %d/%d (peticiones: %d)", n, len(ids), cli.peticiones)

    # Fase 5: fecha de envío de los ejercicios históricos (de más reciente a más antiguo)
    for n, (ide, anio) in enumerate(sorted(historicos, key=lambda x: (-x[1], x[0])), 1):
        cli.pedir("cuenta", "GET", URL_CUENTA, {"idEntidad": str(ide), "ejercicio": str(anio)},
                  estados_validos=(200, 500))
        if n % 200 == 0:
            log.info("[cuenta histórica] %d/%d (peticiones: %d)", n, len(historicos), cli.peticiones)
    log.info("fin. Peticiones a la red: %d", cli.peticiones)


def _params_censo(ide: int, tipo: str) -> dict:
    return {"idEntidad": str(ide), "idTipoEntidad": tipo, "option": "Información Censal"}


# --------------------------------------------------------------------------
# Lectura de la caché (recursos dlt, sin red)
# --------------------------------------------------------------------------


def _fecha_meta(meta: dict) -> date:
    return datetime.fromisoformat(meta["fecha"]).date()


def _listados():
    """(sección, provincia, tipo, fila, fecha) de todos los listados en caché."""
    for seccion in SECCIONES:
        for meta, texto in iterar_cache(f"listado_{seccion}"):
            if meta["status"] != 200:
                continue
            p = meta["params"]
            for i, fila in enumerate(filas_listado(texto)):
                fila["orden"] = (int(p.get("d-2677838-p", 1)), i)
                yield seccion, p["idProvincia"].zfill(2), p["idComunidadAutonoma"], fila, _fecha_meta(meta)


def _estado(icono: str | None) -> str | None:
    return ESTADOS.get((icono or "").strip().lower())


def _cod_mun(tipo: str, censo: dict) -> tuple[str | None, str | None]:
    """Código INE del municipio (5 dígitos) de un ayuntamiento, y de dónde sale.

    El NIF (P + 7 cifras) NO sigue la numeración del INE en muchas provincias, así
    que no se usa aquí (va aparte en cod_mun_nif). Los códigos de la ficha censal
    vienen en formatos variados; se aceptan:
    - Código MEH (Hacienda): CCAA (2, numeración de Hacienda) + provincia (2) +
      municipio (3) INE + 'AA' + 3 cifras (1626011AA000 -> 26011), o el código
      INE de 5 cifras a secas.
    - Código MAP (DIR3 sin la L): '01' + provincia + municipio + dígito de control
      (01260110 -> 26011), a veces sin el cero inicial (1260239 -> 26023), solo
      INE + dígito de control (260086 -> 26008) o el INE de 5 cifras.
    El modelo dbt comprueba que el código exista en el INE en esa provincia y, si
    no, casa por nombre y provincia.
    """
    if tipo != "A":
        return None, None
    meh = (censo.get("codigo_meh") or "").strip()
    if re.fullmatch(r"\d{7}AA\d{3}", meh):
        return meh[2:7], "codigo_meh"
    if re.fullmatch(r"\d{5}", meh):
        return meh, "codigo_meh"
    cmap = (censo.get("codigo_map") or "").strip()
    if re.fullmatch(r"01\d{6}", cmap):
        return cmap[2:7], "codigo_map"
    if re.fullmatch(r"1\d{6}", cmap):
        return cmap[1:6], "codigo_map"
    if re.fullmatch(r"\d{5,6}", cmap):
        return cmap[:5], "codigo_map"
    return None, None


@dlt.resource(name="tcu_entidades", write_disposition="replace")
def tcu_entidades():
    censos = {}
    for meta, texto in iterar_cache("censo"):
        if meta["status"] == 200:
            censos[int(meta["params"]["idEntidad"])] = (analizar_censo(texto), _fecha_meta(meta))
    vistas = {}
    for seccion, prov, ca, fila, fecha in _listados():
        if seccion == "buscarCuentas" and fila["id_entidad"]:
            vistas[fila["id_entidad"]] = (prov, ca, fila)
    for ide, (prov, ca, fila) in vistas.items():
        censo, fecha_censo = censos.get(ide, ({}, None))
        nif = censo.get("nif")
        cod_mun, metodo = _cod_mun(fila["tipo"], censo)
        yield {
            "id_entidad": ide,
            "nombre": fila["nombre"],
            "tipo": fila["tipo"],
            "tipo_nombre": TIPOS_ENTIDAD.get(fila["tipo"]),
            "cod_prov": prov,
            "id_ccaa_tcu": int(ca),
            "nif": nif,
            # Solo orientativo: en muchas provincias el NIF no sigue la numeración del INE
            "cod_mun_nif": nif[1:6] if fila["tipo"] == "A" and nif and re.fullmatch(r"P\d{7}[A-Z]", nif) else None,
            "cod_mun": cod_mun,
            "metodo_cod_mun": metodo,
            "poblacion": censo.get("poblacion"),
            "estado_actividad": censo.get("estado_actividad"),
            "activa": None if not censo.get("estado_actividad") else censo["estado_actividad"].lower() == "con actividad",
            "codigo_meh": censo.get("codigo_meh"),
            "codigo_map": censo.get("codigo_map"),
            "municipio_censo": censo.get("municipio"),
            "fecha_censo": fecha_censo,
        }


@dlt.resource(name="tcu_obligaciones", write_disposition="replace",
              primary_key=["id_entidad", "obligacion", "ejercicio"])
def tcu_obligaciones():
    envios = {}
    for meta, texto in iterar_cache("cuenta"):
        if meta["status"] == 200:
            p = meta["params"]
            envios[(int(p["idEntidad"]), int(p["ejercicio"]))] = analizar_cuenta(texto)

    # Control interno no enlaza a la entidad: se casa por provincia + tipo + nombre
    # con el listado de la Cuenta General (con número de aparición por si se repite).
    ids_por_nombre: dict[tuple, int] = {}
    vistos: dict[tuple, int] = {}
    # Orden estable (sección, provincia, tipo, página, fila) para numerar los homónimos
    listados = sorted(_listados(), key=lambda x: (x[0] != "buscarCuentas", x[0], x[1], x[3]["tipo"], x[3]["orden"]))
    filas: dict[tuple, dict] = {}
    for seccion, prov, ca, fila, fecha in listados:
        base = (prov, fila["tipo"], fila["nombre"].lower())
        clave_nombre = (seccion,) + base
        orden = vistos.get(clave_nombre, 0)
        vistos[clave_nombre] = orden + 1
        ide = fila["id_entidad"]
        if seccion == "buscarCuentas" and ide:
            ids_por_nombre[base + (orden,)] = ide
        elif not ide or seccion == "control":
            ide = ids_por_nombre.get(base + (orden,), ide)
        if not ide:
            log.warning("sin idEntidad: %s %s %s", seccion, prov, fila["nombre"])
            continue
        for anio, (icono, _) in fila["ejercicios"].items():
            filas[(ide, SECCIONES[seccion], anio)] = {
                "estado_portal": icono, "estado": _estado(icono), "fecha_extraccion": fecha}

    # Histórico de la Cuenta General (solo ejercicios que ya no salen en el listado)
    for meta, texto in iterar_cache("ejercicios"):
        if meta["status"] != 200:
            continue
        ide = int(meta["params"]["idEntidad"])
        for anio, (icono, _) in analizar_ejercicios(texto).items():
            filas.setdefault((ide, "cuenta_general", anio), {
                "estado_portal": icono, "estado": _estado(icono), "fecha_extraccion": _fecha_meta(meta)})

    for (ide, obligacion, anio), f in filas.items():
        env = envios.get((ide, anio), {}) if obligacion == "cuenta_general" else {}
        yield {
            "id_entidad": ide,
            "obligacion": obligacion,
            "ejercicio": anio,
            "estado_portal": f["estado_portal"],
            "estado": f["estado"],
            "fecha_envio": env.get("fecha_envio"),
            "fecha_aprobacion": env.get("fecha_aprobacion"),
            "detalle_consultado": (ide, anio) in envios if obligacion == "cuenta_general" else False,
            "fecha_extraccion": f["fecha_extraccion"],
        }


@dlt.source(name="tcu")
def tcu():
    return [tcu_entidades, tcu_obligaciones]


# --------------------------------------------------------------------------
# Línea de órdenes
# --------------------------------------------------------------------------


def main(argv=None):
    ap = argparse.ArgumentParser(description="Rastreador de rendiciondecuentas.es hacia data/tcu_cache/")
    ap.add_argument("--crawl", action="store_true", help="descarga a la caché (reanudable)")
    ap.add_argument("--provincias", help="códigos INE separados por comas (por defecto, todas)")
    ap.add_argument("--tipos", default="A", help="tipos de entidad (A ayuntamiento, D diputación...); por defecto A")
    ap.add_argument("--solo-recientes", action="store_true",
                    help="solo listados (se refrescan si tienen >20 días), censo de entidades nuevas y fecha de "
                         "envío de los últimos ejercicios; para la actualización mensual")
    ap.add_argument("--detalle-desde", type=int, default=2020,
                    help="primer ejercicio histórico del que pedir la fecha de envío (por defecto 2020; 2012 = todo)")
    ap.add_argument("--refrescar-dias", type=float, help="volver a pedir los listados con más antigüedad (días)")
    ap.add_argument("--estado", action="store_true", help="resumen de lo que hay en la caché")
    a = ap.parse_args(argv)
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s", stream=sys.stdout)
    if a.estado:
        for d in sorted(p for p in CACHE.glob("*") if p.is_dir()):
            log.info("%s: %d páginas", d.name, sum(1 for _ in d.glob("*/*.json")))
    if a.crawl:
        crawl(provincias=a.provincias.split(",") if a.provincias else None,
              tipos=[t.strip().upper() for t in a.tipos.split(",")],
              solo_recientes=a.solo_recientes, detalle_desde=a.detalle_desde,
              refrescar_dias=a.refrescar_dias)


if __name__ == "__main__":
    main()
