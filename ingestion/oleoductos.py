"""Fuente dlt de los oleoductos y gasoductos de España (tema `oleoductos`).

No hay ninguna fuente abierta con el tráfico de cada oleoducto: Exolum (antes CLH) no publica
geodatos ni volúmenes por tramo. Por eso:

1) Trazados de oleoductos (y gasoductos de detalle): OpenStreetMap vía Overpass API
   (© OpenStreetMap contributors, ODbL 1.0). Vías man_made=pipeline con substance oil, fuel,
   gas o natural_gas dentro de España. Cubre ~3.950 km de oleoductos frente a los más de
   4.000 que declara Exolum; las vías vienen troceadas y casi sin nombre fuera de Andalucía.
   El operador se escribe de muchas maneras («Enagas», «ENAGAS», «Énagas»): se normaliza con
   operator:wikidata cuando existe.

2) Gasoductos con nombre, estado, capacidad y año, y terminales de GNL: Global Gas
   Infrastructure Tracker de Global Energy Monitor (CC BY 4.0). El GeoJSON público de su mapa
   provisional (~200 MB, todo el mundo) cambia de nombre con cada versión: se lee de
   https://globalenergymonitor.github.io/interim-maps/trackers/ggit/config.js. Se guardan los
   elementos que tocan España, con el trazado recortado a la Península, Baleares y Canarias
   (más un margen marino).

3) Importaciones de gas natural por país de origen: Eurostat nrg_ti_gas (millones de m3,
   anual). Es lo más parecido al «tráfico» de los gasoductos internacionales (Argelia por
   Medgaz) y de las regasificadoras (GNL de Estados Unidos, Rusia, Nigeria...).

El tráfico de la red de oleoductos como conjunto (oleoducto frente a buque y camión) sale de
los boletines de la CNMC sobre Exolum y va en el seed oleoductos_exolum_cnmc.

Recursos (todos replace):
  oleoductos_osm           una fila por vía de OSM, trazado simplificado como texto
                           «lon,lat;lon,lat» (el formato del modo líneas de MapaEspana)
  oleoductos_gem           gasoductos y terminales de GNL de GEM que tocan España
  oleoductos_gas_importaciones  importaciones anuales de gas por país de origen
"""

import json
import logging
import math
import re
import time

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series

log = logging.getLogger(__name__)

CABECERAS = {"User-Agent": "spainfacts.org (datos abiertos; contacto en github.com/SpainFacts)"}
OVERPASS = "https://overpass-api.de/api/interpreter"
CONSULTA = """[out:json][timeout:300];
area["ISO3166-1"="ES"][admin_level=2]->.es;
way["man_made"="pipeline"]["substance"~"^(oil|fuel|gas|natural_gas|crude_oil)$"](area.es);
out tags geom;"""
GEM_CONFIG = "https://globalenergymonitor.github.io/interim-maps/trackers/ggit/config.js"
EUROSTAT = (
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/nrg_ti_gas"
    "?format=JSON&lang=EN&geo=ES&unit=MIO_M3&siec=G3000"
)

SUSTANCIAS = {"oil", "fuel", "gas", "natural_gas", "crude_oil"}

# Operadores por su Wikidata (OSM) y por cómo se escriben
OPERADORES_WIKIDATA = {"Q5156175": "Exolum", "Q1124060": "Enagás", "Q174747": "Repsol"}
OPERADORES_TEXTO = [
    (r"exolum|clh|compa[nñ][ií]a log[ií]stica", "Exolum"),
    (r"[eé]nag[aá]s", "Enagás"),
    (r"repsol", "Repsol"),
    (r"redexis", "Redexis"),
    (r"nedgia|naturgy|gas natural", "Nedgia (Naturgy)"),
    (r"reganosa", "Reganosa"),
    (r"endesa", "Endesa"),
    (r"nortegas", "Nortegas"),
    (r"medgaz", "Medgaz"),
    (r"cepsa|moeve", "Moeve (Cepsa)"),
    (r"bp\b", "BP"),
]

# Recorte de los trazados de GEM: Península y Baleares con margen marino, y Canarias
CAJAS = [(-10.0, 35.9, 4.6, 44.2), (-18.5, 27.4, -13.0, 29.6)]


def _get(url: str, intentos: int = 4, **kw) -> requests.Response:
    for i in range(intentos):
        try:
            r = requests.get(url, headers=CABECERAS, timeout=600, **kw)
            if r.status_code < 500 and r.status_code != 429:
                r.raise_for_status()
                return r
        except requests.RequestException as e:
            if i == intentos - 1:
                raise
            log.warning("%s: %s; reintento", url, e)
        time.sleep(30 * (i + 1))
    r.raise_for_status()
    return r


# ---------------------------------------------------------------- geometría


def _dist_segmento(p, a, b) -> float:
    (x, y), (x1, y1), (x2, y2) = p, a, b
    dx, dy = x2 - x1, y2 - y1
    if dx == dy == 0:
        return math.hypot(x - x1, y - y1)
    t = max(0.0, min(1.0, ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy)))
    return math.hypot(x - x1 - t * dx, y - y1 - t * dy)


def simplificar(puntos: list, tolerancia: float = 0.002) -> list:
    """Douglas-Peucker iterativo (tolerancia en grados; 0,002º ≈ 200 m)."""
    if len(puntos) < 3:
        return puntos
    guardar = [False] * len(puntos)
    guardar[0] = guardar[-1] = True
    pila = [(0, len(puntos) - 1)]
    while pila:
        i, j = pila.pop()
        dmax, k = 0.0, None
        for m in range(i + 1, j):
            d = _dist_segmento(puntos[m], puntos[i], puntos[j])
            if d > dmax:
                dmax, k = d, m
        if k is not None and dmax > tolerancia:
            guardar[k] = True
            pila += [(i, k), (k, j)]
    return [p for p, g in zip(puntos, guardar) if g]


def km(puntos: list) -> float:
    total = 0.0
    for (lo1, la1), (lo2, la2) in zip(puntos, puntos[1:]):
        f1, f2 = math.radians(la1), math.radians(la2)
        a = math.sin((f2 - f1) / 2) ** 2 + math.cos(f1) * math.cos(f2) * math.sin(math.radians(lo2 - lo1) / 2) ** 2
        total += 2 * 6371 * math.asin(math.sqrt(a))
    return total


def texto_trazado(tramos: list[list]) -> str:
    return "|".join(";".join(f"{lo:.4f},{la:.4f}" for lo, la in t) for t in tramos if len(t) > 1)


def _dentro(p) -> bool:
    return any(x0 <= p[0] <= x1 and y0 <= p[1] <= y1 for x0, y0, x1, y1 in CAJAS)


def recortar(tramo: list) -> list[list]:
    """Parte un trazado en los trozos que caen dentro de las cajas de España."""
    trozos, actual = [], []
    for p in tramo:
        if _dentro(p):
            actual.append(p)
        elif actual:
            trozos.append(actual)
            actual = []
    if actual:
        trozos.append(actual)
    return [t for t in trozos if len(t) > 1]


# ---------------------------------------------------------------- 1) OSM


def operador(tags: dict) -> str | None:
    if (w := tags.get("operator:wikidata")) in OPERADORES_WIKIDATA:
        return OPERADORES_WIKIDATA[w]
    texto = tags.get("operator") or tags.get("owner")
    if not texto:
        return None
    for patron, nombre in OPERADORES_TEXTO:
        if re.search(patron, texto, re.I):
            return nombre
    return texto.strip()


def tuberias_osm():
    datos = _get(OVERPASS, params={"data": CONSULTA}).json()
    for el in datos.get("elements", []):
        if el.get("type") != "way" or not el.get("geometry"):
            continue
        tags = el.get("tags", {})
        puntos = [(g["lon"], g["lat"]) for g in el["geometry"]]
        sustancia = tags.get("substance")
        if sustancia not in SUSTANCIAS:
            continue
        yield {
            "osm_id": el["id"],
            "sustancia": "gas" if sustancia in ("gas", "natural_gas") else "petroleo",
            "substance": sustancia,
            "operador": operador(tags),
            "nombre": tags.get("name"),
            "uso": tags.get("usage"),
            "diametro": tags.get("diameter"),
            "presion": tags.get("pressure"),
            "ubicacion": tags.get("location"),
            "longitud_km": km(puntos),
            "trazado": texto_trazado([simplificar(puntos)]),
        }


# ---------------------------------------------------------------- 2) GEM


def _url_gem() -> str:
    js = _get(GEM_CONFIG).text
    urls = re.findall(r"https://[^'\"\s]+\.geojson", js)
    if not urls:
        raise RuntimeError("No encuentro el GeoJSON del GGIT en config.js de GEM")
    return urls[0]


def _numero(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


def infraestructura_gem(contenido: bytes | None = None):
    if contenido is None:
        url = _url_gem()
        log.info("GEM GGIT: %s", url)
        contenido = _get(url).content
    datos = json.loads(contenido)
    for f in datos["features"]:
        p = f["properties"]
        paises = str(p.get("all-countries") or p.get("country-area1") or "")
        if "Spain" not in paises:
            continue
        g = f.get("geometry") or {}
        lat = lon = None
        trazado = None
        longitud = None
        if g.get("type") == "Point":
            lon, lat = g["coordinates"][:2]
        elif g.get("type") in ("LineString", "MultiLineString"):
            lineas = [g["coordinates"]] if g["type"] == "LineString" else g["coordinates"]
            trozos = [t for linea in lineas for t in recortar([tuple(c[:2]) for c in linea])]
            if trozos:
                longitud = sum(km(t) for t in trozos)
                trazado = texto_trazado([simplificar(t) for t in trozos])
        yield {
            "proyecto_id": p.get("project-id"),
            "nombre": p.get("name"),
            "tipo": "terminal_gnl" if g.get("type") == "Point" else "gasoducto",
            "estado": p.get("status"),
            "propietario": p.get("owner"),
            "matriz": p.get("parent"),
            "anio_inicio": int(_numero(p.get("start-year"))) if _numero(p.get("start-year")) else None,
            "capacidad": _numero(p.get("capacity")),
            "unidad_capacidad": p.get("units-of-m"),
            "paises": paises,
            "url": p.get("url"),
            "latitud": lat,
            "longitud": lon,
            "longitud_km_espana": longitud,
            "trazado": trazado,
        }


# ---------------------------------------------------------------- 3) Eurostat


def importaciones_gas():
    datos = _get(EUROSTAT).json()
    etiquetas = datos["dimension"]["partner"]["category"]["label"]
    for coords, valor in parse_json_stat_series(datos):
        if valor is None:
            continue
        yield {
            "anio": int(coords["time"]),
            "socio": coords["partner"],
            "socio_nombre": etiquetas.get(coords["partner"]),
            "millones_m3": float(valor),
        }


# ---------------------------------------------------------------- fuente


@dlt.source(name="oleoductos", max_table_nesting=0)
def oleoductos():
    @dlt.resource(name="oleoductos_osm", write_disposition="replace")
    def r_osm():
        yield from tuberias_osm()

    @dlt.resource(name="oleoductos_gem", write_disposition="replace")
    def r_gem():
        yield from infraestructura_gem()

    @dlt.resource(name="oleoductos_gas_importaciones", write_disposition="replace")
    def r_importaciones():
        yield from importaciones_gas()

    return r_osm, r_gem, r_importaciones
