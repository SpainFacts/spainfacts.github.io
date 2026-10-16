"""Fuente dlt de la red de carreteras de España por titularidad, tipo de vía y peaje (tema `carreteras`).

1) Km de red (Anuario Estadístico del Ministerio de Transportes, a través del visor BDOTLE del
   Observatorio del Transporte y la Logística, OTLE):
   - conjunto 377: por comunidad, provincia, titularidad (Estado, comunidades autónomas,
     diputaciones y cabildos) y tipo de vía (autopistas de peaje, autopistas libres y autovías,
     multicarril, convencionales), desde 2012.
   - conjunto 452: lo mismo para toda España desde 1970.
   El visor es un ReportViewer de ASP.NET: hay que pedir la página, devolverla con «Ver datos» y
   todos los años marcados (HiddenIndices) y, con la misma sesión, pedir la exportación CSV
   (ExportUrlBase + "CSV"). Sin el postback la exportación da 404. Números con coma decimal y
   punto de miles. En la columna de diputaciones van también las diputaciones forales vascas,
   los cabildos canarios y los consells insulares de Baleares.

2) Red del Estado: catálogo oficial de la Red de Carreteras del Estado (shapefile de tramos en
   ETRS89 UTM 30N, en https://www.transportes.gob.es/carreteras/catalogo-y-evolucion-de-la-red-de-carreteras/archivos-geometrias-rce),
   con la clase de cada tramo (autopista de peaje, con peaje bonificado, libre, autovía,
   multicarril, convencional). Se lee y reproyecta con la extensión spatial de DuckDB.
   La web del Ministerio responde «Página web bloqueada» a clientes sin cabeceras de navegador.

3) Red de las comunidades y de las diputaciones: OpenStreetMap (Overpass, © colaboradores de
   OpenStreetMap, ODbL), vías con matrícula (ref) de motorway a unclassified, una consulta por
   comunidad uniprovincial o por provincia (con el servidor principal y dos espejos: Overpass
   da 502 a menudo). Nadie publica en abierto la geometría de todas las redes autonómicas y provinciales
   juntas. La titularidad sale de la matrícula y de la comunidad (ver `titular_osm`): CL- es de
   la Junta de Castilla y León, BV- de la Diputació de Barcelona, DP- de una diputación gallega...
   Las vías cuya matrícula es del Estado en esa provincia (según el catálogo RCE) se descartan:
   esas salen del punto 2. En el País Vasco todo es foral (A-8, AP-8, N-1 incluidas) y en
   Navarra, de la Comunidad Foral. En la Comunitat Valenciana todas son CV-: las de la Generalitat
   salen de su capa de aforos (WFS del ICV). Peaje: toll=yes de OSM. Las dos calzadas de una autovía se
   funden en una rejilla como la de la red ferroviaria (ingestion/ferrocarril.py), más gruesa en las
   autovías.

4) Tráfico: IMD (intensidad media diaria, vehículos al día en los dos sentidos) por tramo de la
   Red de Carreteras del Estado, capa «IMD total (por tramo)» del visor Hermes del Ministerio
   (ArcGIS REST, mapas.fomento.gob.es). Trae varios años (2020-2024) solapados: de cada carretera
   se guarda el último año que tiene. Incluye unos pocos tramos forales (Álava, Navarra).

5) Eurostat road_if_motorwa: km de autopistas por país, para comparar con Europa; superficie
   de cada país (demo_r_d3area) para la densidad.

Recursos (todos replace):
  carreteras_longitud_provincia  km por comunidad, provincia, año, titularidad y tipo (OTLE 377)
  carreteras_longitud_espana     km de España por año, titularidad y tipo (OTLE 452)
  carreteras_red                 trazados por titularidad, tipo, carretera y provincia
  carreteras_imd                 tramos de la RCE con su IMD del último año disponible
  carreteras_eurostat            km de autopistas y superficie por país y año
"""

import csv
import html
import io
import json
import logging
import re
import tempfile
import time
import unicodedata
import zipfile
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series
from ingestion.ferrocarril import _densificar, _km, cadenas
from ingestion.oleoductos import simplificar

log = logging.getLogger(__name__)

REPO_ROOT = Path(__file__).resolve().parent.parent
NAVEGADOR = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36",
             "Accept-Language": "es-ES,es;q=0.9"}
CABECERAS = {"User-Agent": "spainfacts.org (datos abiertos; contacto en github.com/SpainFacts)"}

BDOTLE = "https://apps.fomento.gob.es/BDOTLE/visorBDpop.aspx?i={}"
PARAM_ANIOS = "ctl00$ContentFormulario$ReportViewer2$ctl04$ctl03$"
RCE_PAGINA = "https://www.transportes.gob.es/carreteras/catalogo-y-evolucion-de-la-red-de-carreteras/archivos-geometrias-rce"
RCE_ZIP = "https://cdn.transportes.gob.es/portal-web-transportes/carreteras/red_carreteras/rce/260306-catalogorce2025.zip"
HERMES_IMD = "https://mapas.fomento.gob.es/arcgis/rest/services/Hermes/3__USO_DE_LA_RED/MapServer/198/query"
# Overpass principal y espejos: el principal da 502 a menudo con consultas grandes
OVERPASS = ["https://overpass-api.de/api/interpreter", "https://overpass.kumi.systems/api/interpreter",
            "https://overpass.private.coffee/api/interpreter"]
CONSULTA_OSM = """[out:json][timeout:900];
area["ISO3166-2"="{iso}"]->.a;
way["highway"~"^(motorway|trunk|primary|secondary|tertiary|unclassified)$"]["ref"](area.a);
out tags geom qt;"""
CCAA_ISO = {"01": "ES-AN", "02": "ES-AR", "03": "ES-AS", "04": "ES-IB", "05": "ES-CN", "06": "ES-CB", "07": "ES-CL",
            "08": "ES-CM", "09": "ES-CT", "10": "ES-VC", "11": "ES-EX", "12": "ES-GA", "13": "ES-MD", "14": "ES-MC",
            "15": "ES-NC", "16": "ES-PV", "17": "ES-RI", "18": "ES-CE", "19": "ES-ML"}
PROVINCIA_ISO = {
    "01": "ES-VI", "02": "ES-AB", "03": "ES-A", "04": "ES-AL", "05": "ES-AV", "06": "ES-BA", "07": "ES-PM", "08": "ES-B",
    "09": "ES-BU", "10": "ES-CC", "11": "ES-CA", "12": "ES-CS", "13": "ES-CR", "14": "ES-CO", "15": "ES-C", "16": "ES-CU",
    "17": "ES-GI", "18": "ES-GR", "19": "ES-GU", "20": "ES-SS", "21": "ES-H", "22": "ES-HU", "23": "ES-J", "24": "ES-LE",
    "25": "ES-L", "26": "ES-LO", "27": "ES-LU", "28": "ES-M", "29": "ES-MA", "30": "ES-MU", "31": "ES-NA", "32": "ES-OR",
    "33": "ES-O", "34": "ES-P", "35": "ES-GC", "36": "ES-PO", "37": "ES-SA", "38": "ES-TF", "39": "ES-S", "40": "ES-SG",
    "41": "ES-SE", "42": "ES-SO", "43": "ES-T", "44": "ES-TE", "45": "ES-TO", "46": "ES-V", "47": "ES-VA", "48": "ES-BI",
    "49": "ES-ZA", "50": "ES-Z", "51": "ES-CE", "52": "ES-ML"}
EUROSTAT = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
GVA_AFOROS = ("https://terramapas.icv.gva.es/0902_Aforos?request=GetFeature&service=WFS&version=2.0.0"
              "&typename=Aforos{anio}&propertyName=carretera,titular")

TIPO_RCE = {
    "autopista de peaje": "peaje",
    "autopista con peaje bonificado": "peaje",
    "autopista libre": "autovia",
    "autopista libre de peaje para movimientos internos": "autovia",
    "autovia": "autovia",
    "carretera multicarril": "multicarril",
    "carretera convencional": "convencional",
}
PRIORIDAD_TIPO = ["peaje", "autovia", "multicarril", "convencional"]


def _get(url: str, intentos: int = 4, sesion=None, cabeceras=None, **kw) -> requests.Response:
    s = sesion or requests
    for i in range(intentos):
        try:
            r = s.get(url, headers=cabeceras or CABECERAS, timeout=900, **kw)
            if r.status_code < 500 and r.status_code != 429:
                r.raise_for_status()
                return r
            log.warning("%s: HTTP %s; reintento", url, r.status_code)
        except requests.RequestException as e:
            if i == intentos - 1:
                raise
            log.warning("%s: %s; reintento", url, e)
        time.sleep(60 * (i + 1))
    r.raise_for_status()
    return r


def _sin_tildes(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn").lower().strip()


def _numero(s: str) -> float | None:
    s = (s or "").strip()
    if not s:
        return None
    return float(s.replace(".", "").replace(",", "."))


# ---------------------------------------------------------------- provincias


def _provincias() -> dict:
    """cod_prov -> (cod_ccaa, nombre) del seed territorios_provincias."""
    with open(REPO_ROOT / "transform" / "seeds" / "territorios_provincias.csv", encoding="utf-8") as f:
        return {r["cod_prov"]: (r["cod_ccaa"], r["nombre"]) for r in csv.DictReader(f)}


# Variantes de nombre de provincia en el OTLE y en el catálogo RCE
ALIAS_PROVINCIA = {
    "coruna, a": "15", "a coruna": "15", "palmas, las": "35", "las palmas": "35", "balears, illes": "07",
    "illes balears": "07", "rioja, la": "26", "la rioja": "26", "guipuzcoa": "20", "gipuzkoa": "20",
    "vizcaya": "48", "bizkaia": "48", "alava": "01", "araba/alava": "01", "alicante/alacant": "03",
    "castellon/castello": "12", "valencia/valencia": "46", "asturias": "33", "navarra": "31",
}


def codigo_provincia(nombre: str, provincias: dict) -> str | None:
    n = _sin_tildes(nombre)
    if n in ALIAS_PROVINCIA:
        return ALIAS_PROVINCIA[n]
    for cod, (_ccaa, nom) in provincias.items():
        if _sin_tildes(nom) == n or _sin_tildes(nom).split("/")[0] == n.split("/")[0]:
            return cod
    return None


# ---------------------------------------------------------------- 1) OTLE


def otle_csv(conjunto: int) -> list[dict]:
    """Todas las filas de un conjunto del visor BDOTLE con todos los años marcados."""
    s = requests.Session()
    s.headers.update(NAVEGADOR)
    url = BDOTLE.format(conjunto)
    pagina = _get(url, sesion=s, cabeceras=NAVEGADOR).text
    formulario = {}
    for etiqueta in re.findall(r"<input[^>]*>", pagina):
        nombre = re.search(r'name="([^"]+)"', etiqueta)
        tipo = re.search(r'type="([^"]+)"', etiqueta)
        valor = re.search(r'value="([^"]*)"', etiqueta)
        if nombre and tipo and tipo.group(1) in ("hidden", "text"):
            formulario[html.unescape(nombre.group(1))] = html.unescape(valor.group(1)) if valor else ""
    anios = [a for _i, a in re.findall(r'<label for="[^"]*divDropDown_ctl(\d+)">([^<]+)</label>', pagina) if a.strip().isdigit()]
    if not anios:
        raise RuntimeError(f"BDOTLE {conjunto}: no se encuentran los años del desplegable")
    formulario[PARAM_ANIOS + "divDropDown$ctl01$HiddenIndices"] = ",".join(str(i) for i in range(len(anios)))
    formulario[PARAM_ANIOS + "txtValue"] = ", ".join(anios)
    formulario["ctl00$ContentFormulario$ReportViewer2$ctl04$ctl00"] = "Ver datos"
    informe = s.post(url, data=formulario, timeout=600)
    informe.raise_for_status()
    base = re.search(r'ExportUrlBase":"([^"]*)', informe.text)
    if not base:
        raise RuntimeError(f"BDOTLE {conjunto}: el informe no trae ExportUrlBase")
    exportar = json.loads('"' + base.group(1) + '"')
    r = _get("https://apps.fomento.gob.es" + exportar + "CSV", sesion=s, cabeceras=NAVEGADOR)
    texto = r.content.decode("utf-8-sig")
    filas = list(csv.DictReader(io.StringIO(texto)))
    log.info("BDOTLE %s: %s filas, años %s-%s", conjunto, len(filas), anios[-1], anios[0])
    return filas


def _tipo_otle(tipo_via: str) -> str | None:
    t = _sin_tildes(tipo_via)
    if "peaje" in t:
        return "peaje"
    if "autovia" in t or "libres" in t:
        return "autovia"
    if "multicarril" in t:
        return "multicarril"
    if "convencional" in t:
        return "convencional"
    return None


def _titular_otle(titularidad: str) -> str | None:
    t = _sin_tildes(titularidad)
    return {"estado": "estado", "comunidades autonomas": "comunidad", "diputaciones y cabildos": "diputacion"}.get(t)


def longitud_provincia(filas: list[dict], provincias: dict):
    for f in filas:
        tipo, titular = _tipo_otle(f.get("tipo_via")), _titular_otle(f.get("Titularidad"))
        km = _numero(f.get("longitud"))
        if not tipo or not titular or km is None or not (f.get("year") or "").isdigit():
            continue
        yield {
            "cod_prov": codigo_provincia(f["provincia"], provincias),
            "provincia_fuente": f["provincia"],
            "comunidad_fuente": f["comunidad"],
            "anio": int(f["year"]),
            "titular": titular,
            "tipo": tipo,
            "km": km,
        }


def longitud_espana(filas: list[dict]):
    for f in filas:
        tipo, titular = _tipo_otle(f.get("tipo_via")), _titular_otle(f.get("Titularidad"))
        km = _numero(f.get("longitud"))
        if not tipo or not titular or km is None or not (f.get("year") or "").isdigit():
            continue
        yield {"anio": int(f["year"]), "titular": titular, "tipo": tipo, "km": km}


# ---------------------------------------------------------------- 2) RCE


def url_catalogo_rce() -> str:
    """Enlace al zip del catálogo más reciente (cambia de nombre cada año)."""
    try:
        pagina = _get(RCE_PAGINA, cabeceras=NAVEGADOR).text
        enlaces = re.findall(r'href="([^"]*catalogorce(\d{4})\.zip)"', pagina, re.I)
        if enlaces:
            return max(enlaces, key=lambda e: e[1])[0]
    except requests.RequestException as e:
        log.warning("Página del catálogo RCE: %s", e)
    return RCE_ZIP


def tramos_rce(contenido: bytes) -> list[dict]:
    """Tramos del catálogo RCE en lon/lat con su clase."""
    import duckdb

    with tempfile.TemporaryDirectory() as tmp:
        zipfile.ZipFile(io.BytesIO(contenido)).extractall(tmp)
        shp = next(Path(tmp).rglob("*.shp"))
        con = duckdb.connect()
        con.sql("INSTALL spatial; LOAD spatial;")
        filas = con.execute(
            """
            SELECT carretera, provincia, clase, longitud,
                   ST_AsText(ST_Transform(geom, 'EPSG:25830', 'EPSG:4326', always_xy := true)) AS wkt
            FROM ST_Read(?)
            """,
            [str(shp)],
        ).fetchall()
        con.close()
    tramos = []
    for carretera, provincia, clase, longitud, wkt in filas:
        partes = [[tuple(map(float, p.split()[:2])) for p in parte.split(",")]  # sin Z ni M
                  for parte in re.findall(r"\(([^()]+)\)", wkt or "")]
        tramos.append({"carretera": (carretera or "").strip(), "provincia": provincia, "clase": clase,
                       "km": float(longitud or 0), "partes": [p for p in partes if len(p) > 1]})
    log.info("Catálogo RCE: %s tramos, %.0f km", len(tramos), sum(t["km"] for t in tramos))
    return tramos


# ---------------------------------------------------------------- 3) OSM


def refs(ref: str) -> list[str]:
    """Matrículas de una vía de OSM normalizadas ('A-8;E-70' -> ['A-8']; 'LR 202' -> ['LR-202'])."""
    salida = []
    for r in re.split(r"[;,/]", ref or ""):
        r = re.sub(r"\s+", "-", r.strip().upper())
        r = re.sub(r"-+", "-", r)
        if r and not r.startswith("E-") and re.match(r"^[A-ZÑ]+(?:-[A-Z]+)*-?\d", r):
            salida.append(r)
    return salida


def _partes_ref(r: str) -> tuple[str, str]:
    m = re.match(r"^([A-ZÑ]+(?:-[A-Z]+)*)-?(\d+)", r)
    return (m.group(1), m.group(2)) if m else ("", "")


LETRAS_ANDALUCIA = {"AL", "CA", "CO", "GR", "H", "HU", "J", "JA", "MA", "SE"}
LETRAS_CYL = {"AV", "BU", "LE", "P", "SA", "SG", "SO", "VA", "ZA"}
LETRAS_GALICIA = {"AC", "C", "LU", "OU", "PO"}


def titular_osm(ref: str, ccaa: str, generalitat_valenciana: set | None = None) -> str | None:
    """'comunidad' o 'diputacion' según la matrícula y la comunidad; None si no se reconoce.

    Las comunidades uniprovinciales no tienen diputación (todo lo que no es del Estado es de la
    comunidad); en Baleares, Canarias y el País Vasco todo es de los consells, cabildos y
    diputaciones forales (el Ministerio los cuenta con las diputaciones)."""
    pre, num = _partes_ref(ref)
    if not pre:
        return None
    # AP-, N-, R- (y A- donde las comunidades no la usan) son del Estado aunque la variante
    # (AP-9FS, N-640a...) no esté tal cual en el catálogo; salvo en el País Vasco y Navarra
    if ccaa not in ("15", "16") and (pre in ("AP", "N", "R") or (pre == "A" and ccaa not in ("01", "02", "07"))):
        return None
    if ccaa in ("03", "06", "13", "14", "15", "17", "18", "19"):
        return "comunidad"
    if ccaa in ("04", "05", "16"):
        return "diputacion"
    corto = len(num) <= 3
    if ccaa == "01":  # Andalucía: A-xxx y A-xxxx de la Junta; MA-xxxx, SE-xxxx... de las diputaciones
        return "comunidad" if pre == "A" or (pre in LETRAS_ANDALUCIA and corto) else "diputacion"
    if ccaa == "02":  # Aragón: A-xxxx del Gobierno; HU-V, TE-V, Z-V de las diputaciones
        return "comunidad" if pre == "A" else "diputacion"
    if ccaa == "07":  # Castilla y León: CL-xxx, autovías A-xxx (A-231, A-601) y las de tres cifras con letras de provincia
        return "comunidad" if pre in ("CL", "A") or (pre in LETRAS_CYL and corto) else "diputacion"
    if ccaa == "08":  # Castilla-La Mancha: CM-
        return "comunidad" if pre == "CM" else "diputacion"
    if ccaa == "09":  # Cataluña: BV-, GIV-, LV-, TV- de las diputacions; el resto, Generalitat
        return "diputacion" if pre.endswith("V") and len(pre) >= 2 else "comunidad"
    if ccaa == "10":  # Comunitat Valenciana: todas son CV-; la lista de la Generalitat dice cuáles son suyas
        if generalitat_valenciana:
            return "comunidad" if ref in generalitat_valenciana else "diputacion"
        return "comunidad" if pre == "CV" and len(num) <= 2 else "diputacion"
    if ccaa == "11":  # Extremadura: EX- y autovías EX-A1, EX-A2; BA-, CC- de las diputaciones
        return "comunidad" if pre.startswith("EX") else "diputacion"
    if ccaa == "12":  # Galicia: AG-, CG-, vías rápidas VG- y provincia + tres cifras de la Xunta; DP- de las deputacións
        return "comunidad" if pre in ("AG", "CG", "VG") or (pre in LETRAS_GALICIA and corto) else "diputacion"
    return None


def tipo_osm(tags: dict) -> str:
    hw = tags.get("highway")
    if tags.get("toll") == "yes" and hw in ("motorway", "trunk"):
        return "peaje"
    if hw == "motorway":
        return "autovia"
    if hw == "trunk":
        try:
            carriles = int(re.match(r"\d+", tags.get("lanes", "") or "0").group())
        except AttributeError:
            carriles = 0
        return "multicarril" if tags.get("oneway") == "yes" or carriles >= 4 else "convencional"
    return "convencional"


def overpass(iso: str) -> dict:
    """Vías con matrícula de un territorio ISO 3166-2, probando el servidor principal y los espejos."""
    for i in range(6 * len(OVERPASS)):
        servidor = OVERPASS[i % len(OVERPASS)]
        try:
            r = requests.post(servidor, data={"data": CONSULTA_OSM.format(iso=iso)}, headers=CABECERAS, timeout=1200)
            if r.status_code == 200 and r.content.lstrip().startswith(b"{"):
                return r.json()
            log.warning("Overpass %s (%s): HTTP %s; reintento", iso, servidor, r.status_code)
        except (requests.RequestException, ValueError) as e:
            log.warning("Overpass %s (%s): %s; reintento", iso, servidor, e)
        time.sleep(30 * (i // len(OVERPASS) + 1))
    raise RuntimeError(f"Overpass no responde para {iso}")


def vias_osm(ccaa: str, datos: dict | None = None, provincias: dict | None = None) -> list[dict]:
    """Vías de OSM con matrícula de una comunidad. Las comunidades de varias provincias se piden
    provincia a provincia: Castilla y León o Andalucía enteras agotan a menudo los servidores.
    Las vías de la frontera entre provincias salen dos veces; la rejilla de `red` las funde."""
    if datos is None:
        provs = sorted(c for c, (cc, _n) in (provincias or _provincias()).items() if cc == ccaa)
        isos = [PROVINCIA_ISO[c] for c in provs] if len(provs) > 1 else [CCAA_ISO[ccaa]]
        datos = {"elements": [el for iso in isos for el in overpass(iso).get("elements", [])]}
    vias = []
    for el in datos.get("elements", []):
        if el.get("type") != "way" or not el.get("geometry"):
            continue
        t = el.get("tags", {})
        rs = refs(t.get("ref"))
        if not rs:
            continue
        vias.append({"ref": rs[0], "tipo": tipo_osm(t), "coords": [(g["lon"], g["lat"]) for g in el["geometry"]]})
    return vias


def carreteras_generalitat_valenciana() -> set:
    """Matrículas de la red de la Generalitat Valenciana: las de su capa de aforos (WFS del ICV).

    En la Comunitat Valenciana la Generalitat y las tres diputaciones numeran todas sus carreteras
    CV-xx, CV-xxx o CV-xxxx, sin que las cifras digan de quién es. Si la capa no responde, vacío
    (titular_osm usa entonces una regla aproximada)."""
    for anio in range(datetime.now().year, datetime.now().year - 4, -1):
        try:
            r = requests.get(GVA_AFOROS.format(anio=anio), headers=CABECERAS, timeout=300)
            nombres = set(re.findall(r"<ms:carretera>([^<]+)</ms:carretera>", r.text))
            if r.status_code == 200 and len(nombres) > 50:
                log.info("Red de la Generalitat Valenciana (aforos %s): %s carreteras", anio, len(nombres))
                return {n.strip().upper() for n in nombres}
        except requests.RequestException as e:
            log.warning("Aforos de la Generalitat Valenciana %s: %s", anio, e)
    log.warning("Sin la lista de carreteras de la Generalitat Valenciana: regla aproximada")
    return set()


# ---------------------------------------------------------------- red completa


def _texto(tramos: list[list], decimales: int = 3) -> str:
    return "|".join(";".join(f"{lo:.{decimales}f},{la:.{decimales}f}" for lo, la in t) for t in tramos if len(t) > 1)


def red(tramos: list[dict], vias_por_ccaa: dict[str, list[dict]], provincias: dict, generalitat_valenciana: set | None = None):
    """Filas de carreteras_red: Estado (catálogo RCE) y el resto (OSM) por titular, tipo, carretera y provincia."""
    from ingestion.recarga import Localizador

    filas = []
    estatales = set()  # (cod_prov, carretera) del catálogo
    grupos = defaultdict(list)
    sin_tipo = Counter()
    for t in tramos:
        cod = codigo_provincia(t["provincia"] or "", provincias)
        estatales.add((cod, t["carretera"].upper()))
        tipo = TIPO_RCE.get(_sin_tildes(t["clase"]))
        if tipo is None:
            sin_tipo[t["clase"]] += 1
            tipo = "convencional"
        grupos[("estado", tipo, t["carretera"], cod)].append(t)
    if sin_tipo:
        log.warning("Clases del catálogo RCE sin tipo: %s", dict(sin_tipo))
    for (titular, tipo, carretera, cod), ts in grupos.items():
        filas.append({
            "titular": titular, "tipo": tipo, "carretera": carretera, "cod_prov": cod,
            "longitud_km": sum(t["km"] for t in ts),
            "trazado": _texto([simplificar(p, 0.003) for t in ts for p in t["partes"]]),
        })

    localizar = Localizador()
    descartadas = Counter()
    for ccaa, vias in vias_por_ccaa.items():
        # Aristas de la rejilla con su clave: las dos calzadas caen en las mismas celdas
        aristas = {}
        for v in sorted(vias, key=lambda v: PRIORIDAD_TIPO.index(v["tipo"])):
            medio = v["coords"][len(v["coords"]) // 2]
            _mun, cod = localizar(*medio)
            if cod is None or provincias.get(cod, ("",))[0] != ccaa:
                descartadas["fuera"] += 1
                continue
            if (cod, v["ref"]) in estatales:
                descartadas["estado"] += 1
                continue
            titular = titular_osm(v["ref"], ccaa, generalitat_valenciana)
            if titular is None:
                descartadas["matricula"] += 1
                continue
            # Rejilla de ~100 m; ~250 m en autopistas, autovías y multicarril, cuyas dos calzadas
            # van a veces a más de 100 m una de otra
            k = 1000 if v["tipo"] == "convencional" else 400
            celdas = []
            for lo, la in _densificar(v["coords"]):
                c = (round(lo * k), round(la * k), k)
                if not celdas or celdas[-1] != c:
                    celdas.append(c)
            for a, b in zip(celdas, celdas[1:]):
                e = (a, b) if a < b else (b, a)
                aristas.setdefault(e, (titular, v["tipo"], v["ref"], cod))
        for (titular, tipo, carretera, cod), linea in cadenas(None, aristas):
            coords = [(c[0] / c[2], c[1] / c[2]) for c in linea]
            km = sum(_km(*a, *b) for a, b in zip(coords, coords[1:]))
            if km < 0.2:
                continue
            filas.append({"titular": titular, "tipo": tipo, "carretera": carretera, "cod_prov": cod,
                          "longitud_km": km, "trazado": _texto([simplificar(coords, 0.004)])})
    log.info("Vías de OSM descartadas: %s", dict(descartadas))
    # una fila por titular, tipo, carretera y provincia
    juntas = {}
    for f in filas:
        k = (f["titular"], f["tipo"], f["carretera"], f["cod_prov"])
        if k in juntas:
            juntas[k]["longitud_km"] += f["longitud_km"]
            juntas[k]["trazado"] += "|" + f["trazado"]
        else:
            juntas[k] = dict(f)
    return [f for f in juntas.values() if f["trazado"]]


# ---------------------------------------------------------------- 4) IMD


def imd_tramos() -> list[dict]:
    campos = "Carretera,Longitud,PK_inicio,PK_fin,IMD_total,IMD_asc,IMD_desc,Pesados,IMD_motos,IMD_coches,IMD_camionetas,IMD_autobuses,Dato_desde,Titular"
    tramos, desde = [], 0
    while True:
        r = _get(HERMES_IMD, cabeceras=NAVEGADOR, params={
            "where": "Valido_hasta IS NULL", "outFields": campos, "returnGeometry": "true", "outSR": "4326",
            "maxAllowableOffset": "0.0008", "geometryPrecision": "4", "resultOffset": desde,
            "resultRecordCount": 2000, "orderByFields": "id", "f": "json",
        })
        datos = r.json()
        if "error" in datos:
            raise RuntimeError(f"Hermes IMD: {datos['error']}")
        lote = datos.get("features", [])
        for f in lote:
            a = f["attributes"]
            partes = [[(p[0], p[1]) for p in camino] for camino in (f.get("geometry") or {}).get("paths", [])]
            if not partes or a.get("IMD_total") is None or not a.get("Dato_desde"):
                continue
            tramos.append({
                "carretera": (a.get("Carretera") or "").strip(),
                "pk_inicio": a.get("PK_inicio"), "pk_fin": a.get("PK_fin"),
                "longitud_km": (a.get("Longitud") or 0) / 1000,
                "imd": a["IMD_total"],
                "imd_ascendente": a.get("IMD_asc"), "imd_descendente": a.get("IMD_desc"),
                "pesados_pct": a.get("Pesados"),
                "anio": datetime.fromtimestamp(a["Dato_desde"] / 1000, tz=timezone.utc).year,
                "titular": a.get("Titular"),
                "trazado": _texto(partes, 4),
            })
        if len(lote) < 2000 and not datos.get("exceededTransferLimit"):
            break
        desde += len(lote)
    # De cada carretera, solo el último año que tiene (los años se solapan con otra partición en tramos)
    ultimo = {}
    for t in tramos:
        ultimo[t["carretera"]] = max(ultimo.get(t["carretera"], 0), t["anio"])
    salida = [t for t in tramos if t["anio"] == ultimo[t["carretera"]]]
    log.info("IMD: %s tramos leídos, %s del último año de cada carretera", len(tramos), len(salida))
    return salida


# ---------------------------------------------------------------- 5) Eurostat


def eurostat():
    consultas = {
        "km_autopistas": "road_if_motorwa?format=JSON&lang=EN&unit=KM&tra_infr=MWAY",
        "superficie_km2": "demo_r_d3area?format=JSON&lang=EN&unit=KM2&landuse=TOTAL",
    }
    for indicador, consulta in consultas.items():
        datos = _get(EUROSTAT + consulta).json()
        for coords, valor in parse_json_stat_series(datos):
            geo = coords.get("geo", "")
            if valor is None or len(geo) != 2:  # solo países (no regiones NUTS)
                continue
            yield {"indicador": indicador, "cod_fuente": geo, "anio": int(coords["time"]), "valor": float(valor)}


# ---------------------------------------------------------------- fuente


@dlt.source(name="carreteras", max_table_nesting=0)
def carreteras():
    provincias = _provincias()
    cache = {}

    def red_calculada():
        if "red" not in cache:
            tramos = tramos_rce(_get(url_catalogo_rce(), cabeceras=NAVEGADOR).content)
            vias = {}
            for ccaa in CCAA_ISO:
                vias[ccaa] = vias_osm(ccaa, provincias=provincias)
                log.info("OSM %s: %s vías con matrícula", ccaa, len(vias[ccaa]))
                time.sleep(5)
            cache["red"] = red(tramos, vias, provincias, carreteras_generalitat_valenciana())
        return cache["red"]

    @dlt.resource(name="carreteras_longitud_provincia", write_disposition="replace")
    def r_provincia():
        yield list(longitud_provincia(otle_csv(377), provincias))

    @dlt.resource(name="carreteras_longitud_espana", write_disposition="replace")
    def r_espana():
        yield list(longitud_espana(otle_csv(452)))

    @dlt.resource(name="carreteras_red", write_disposition="replace")
    def r_red():
        yield red_calculada()

    @dlt.resource(name="carreteras_imd", write_disposition="replace")
    def r_imd():
        yield imd_tramos()

    @dlt.resource(name="carreteras_eurostat", write_disposition="replace")
    def r_eurostat():
        yield list(eurostat())

    return r_provincia, r_espana, r_red, r_imd, r_eurostat
