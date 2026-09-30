"""Fuente dlt para indicadores de rendición de cuentas del Gobierno de España a
partir de los sumarios diarios del BOE (API de datos abiertos de la Agencia
Estatal BOE, https://www.boe.es/datosabiertos/).

Endpoint: https://www.boe.es/datosabiertos/api/boe/sumario/AAAAMMDD
(se pide en XML; 404 los días sin BOE). Hay sumarios desde
1960; aquí se recorre desde el 1 de julio de 1977 (primer Gobierno salido de las
elecciones de 1977).

Solo se guardan las entradas que interesan (el resto del sumario se descarta):
  - Sección I: los reales decretos-ley ("Real Decreto-ley N/AAAA, de ...") y las
    resoluciones del Congreso que ordenan publicar su convalidación o derogación
    (art. 86 de la Constitución).
  - Las leyes de Presupuestos Generales del Estado ("Ley .../AAAA ... de
    Presupuestos Generales del Estado para el año ...") y el resto de leyes
    y leyes orgánicas de las Cortes (sección I, Jefatura del Estado), para
    medir qué parte de las normas con rango de ley son decretos-ley.
  - Sección III, epígrafe "Indultos": los reales decretos de indulto
    individual (Ley de 18 de junio de 1870). El nombre de la persona indultada
    NO se guarda: el título se corta tras "se indulta" / "se conmuta".

Por qué no la API de legislación consolidada: solo incluye las normas que el BOE
ha consolidado (faltan muchos decretos-ley derogados o agotados, p. ej. casi
todos los de los años ochenta y noventa) y no incluye los indultos.

Carga incremental: el estado del recurso guarda el último día recorrido; cada
ejecución vuelve a leer los últimos 15 días y sigue hasta hoy (merge por
identificador). La primera carga recorre ~18.000 días con 4 peticiones en
paralelo (unos 30-40 minutos).
"""

import json
import logging
import re
import time
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime, timedelta
from pathlib import Path

import dlt
import requests

log = logging.getLogger(__name__)

SUMARIO_URL = "https://www.boe.es/datosabiertos/api/boe/sumario/{}"  # XML
INICIO = date(1977, 7, 1)
RELECTURA_DIAS = 15
HILOS = 4
CACHE_DIR = Path(__file__).resolve().parent.parent / "data" / "boe_cache"

_sesion = requests.Session()
_sesion.headers.update({"Accept": "application/json", "User-Agent": "SpainFacts (datos abiertos; spainfacts.org)"})

RE_RDL = re.compile(r"^Real Decreto[- ]ley\b", re.I)  # alguna vez sin guion
RE_CONVALIDA = re.compile(r"(convalidaci[oó]n|derogaci[oó]n)\b.*Real Decreto[- ]ley", re.I)
RE_PGE = re.compile(r"^Ley\b.*Presupuestos Generales del Estado para", re.I)
RE_INDULTO = re.compile(r"se (indulta|conmuta)", re.I)
RE_LEY = re.compile(r"^Ley (Org[aá]nica )?\d+/\d{4}\b")


def _lista(x):
    if x is None:
        return []
    return x if isinstance(x, list) else [x]


def _items(sumario: dict):
    """Aplana el sumario: (sección, departamento, epígrafe, item)."""
    for diario in _lista(sumario.get("diario")):
        for seccion in _lista(diario.get("seccion")):
            for dep in _lista(seccion.get("departamento")):
                for ep in _lista(dep.get("epigrafe")):
                    for it in _lista(ep.get("item")):
                        yield seccion.get("codigo"), dep.get("nombre"), ep.get("nombre"), it
                for it in _lista(dep.get("item")):
                    yield seccion.get("codigo"), dep.get("nombre"), None, it


def _clasificar(seccion, departamento, epigrafe, titulo):
    if seccion == "1" and RE_RDL.search(titulo):
        return "real_decreto_ley"
    if RE_CONVALIDA.search(titulo) and titulo.startswith("Resoluci"):
        return "convalidacion_rdl"
    if RE_PGE.search(titulo):
        return "ley_presupuestos"
    if seccion == "1" and RE_LEY.search(titulo) and "JEFATURA" in (departamento or "").upper():
        return "ley"
    if seccion == "3" and ((epigrafe or "").strip().lower() == "indultos" or RE_INDULTO.search(titulo)):
        if titulo.startswith("Real Decreto") and RE_INDULTO.search(titulo):
            return "indulto"
    return None


def _redactar_indulto(titulo: str) -> str:
    m = RE_INDULTO.search(titulo)
    return titulo[: m.end()] if m else titulo


def _sumario_xml(url: str) -> dict:
    """Lee el sumario en XML y lo devuelve como dict {diario: [{seccion: [...]}]}.
    Se usa XML y no JSON porque la conversión a JSON del BOE es irregular: cuando
    un nodo tiene un solo hijo lo envuelve en "texto" (p. ej. el BOE extraordinario
    del 29-03-2020, con el Real Decreto-ley 10/2020) y algunos días da error 500."""
    r = _sesion.get(url, timeout=60, headers={"Accept": "application/xml"})
    if r.status_code == 404:
        return None
    r.raise_for_status()
    raiz = ET.fromstring(r.content)
    item = lambda it: {k: (it.findtext(k) or "") for k in ("identificador", "titulo", "url_html")}
    diarios = []
    for d in raiz.iter("diario"):
        secciones = []
        for s in d.iter("seccion"):
            deps = []
            for dep in s.iter("departamento"):
                eps, sueltos = [], []
                vistos = set()
                for ep in dep.iter("epigrafe"):
                    its = list(ep.iter("item"))
                    vistos.update(id(i) for i in its)
                    eps.append({"nombre": ep.get("nombre"), "item": [item(i) for i in its]})
                sueltos = [item(i) for i in dep.iter("item") if id(i) not in vistos]
                deps.append({"nombre": dep.get("nombre"), "epigrafe": eps, "item": sueltos})
            secciones.append({"codigo": s.get("codigo"), "departamento": deps})
        diarios.append({"seccion": secciones})
    return {"diario": diarios}


def _leer_dia(dia: date):
    url = SUMARIO_URL.format(dia.strftime("%Y%m%d"))
    for intento in range(5):
        try:
            sumario = _sumario_xml(url)
            break
        except (requests.RequestException, ET.ParseError) as e:
            if intento == 4:
                raise RuntimeError(f"BOE sumario {dia}: {e}") from e
            time.sleep(2 + 3 * intento)
    if sumario is None:
        return dia, []
    filas = []
    for seccion, dep, ep, it in _items(sumario):
        titulo = (it.get("titulo") or "").strip()
        tipo = _clasificar(seccion, dep, ep, titulo)
        if not tipo:
            continue
        filas.append({
            "identificador": it.get("identificador"),
            "fecha_publicacion": dia,
            "tipo": tipo,
            "seccion": seccion,
            "departamento": dep,
            "epigrafe": ep,
            "titulo": _redactar_indulto(titulo) if tipo == "indulto" else titulo,
            "url_html": it.get("url_html"),
        })
    return dia, filas


def _leer_anio(anio: int, inicio: date, fin: date, ex: ThreadPoolExecutor) -> list[dict]:
    """Entradas de un año (entre inicio y fin). Los años cerrados y completos se
    guardan en data/boe_cache/AAAA.json: los sumarios pasados no cambian."""
    desde, hasta = max(inicio, date(anio, 1, 1)), min(fin, date(anio, 12, 31))
    completo = desde == date(anio, 1, 1) and hasta == date(anio, 12, 31) and anio < date.today().year
    cache = CACHE_DIR / f"{anio}.json"
    if completo and cache.exists():
        filas = json.loads(cache.read_text(encoding="utf-8"))
        for f in filas:
            f["fecha_publicacion"] = date.fromisoformat(f["fecha_publicacion"])
        return filas
    dias = [desde + timedelta(days=i) for i in range((hasta - desde).days + 1)]
    filas = [f for _, fs in ex.map(_leer_dia, dias) for f in fs]
    if completo:
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        cache.write_text(json.dumps(filas, default=str, ensure_ascii=False), encoding="utf-8")
    return filas


@dlt.source(name="transparencia_gobierno")
def transparencia_gobierno(desde: str | None = None, hasta: str | None = None):
    @dlt.resource(name="boe_actos_gobierno", write_disposition="merge", primary_key="identificador")
    def boe_actos_gobierno():
        estado = dlt.current.resource_state()
        if desde:
            inicio = date.fromisoformat(desde)
        elif estado.get("ultimo_dia"):
            inicio = date.fromisoformat(estado["ultimo_dia"]) - timedelta(days=RELECTURA_DIAS)
        else:
            inicio = INICIO
        fin = date.fromisoformat(hasta) if hasta else date.today()
        log.info("BOE sumarios: %s -> %s", inicio, fin)
        with ThreadPoolExecutor(max_workers=HILOS) as ex:
            for anio in range(inicio.year, fin.year + 1):
                filas = _leer_anio(anio, inicio, fin, ex)
                log.info("  %d: %d entradas", anio, len(filas))
                yield from filas
        estado["ultimo_dia"] = fin.isoformat()

    return boe_actos_gobierno


if __name__ == "__main__":
    import sys

    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    args = dict(a.split("=", 1) for a in sys.argv[1:])  # desde=AAAA-MM-DD hasta=AAAA-MM-DD
    print(datetime.now(), pipeline("transparencia_gobierno").run(transparencia_gobierno(**args)))
