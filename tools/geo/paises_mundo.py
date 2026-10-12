"""Genera los mapas de países (static/geo/mundo.json y europa.json) y completa el seed
transform/seeds/paises_iso.csv con todos los países del Banco Mundial.

Geometría: fronteras de GISCO (Eurostat, CNTR_RG, EPSG:4326), que siguen la posición de la
UE (Crimea en Ucrania, Sáhara Occidental aparte, sin Kosovo separado). Se descargan a mano en
una carpeta propia y se pasan como argumentos:

    curl -o cntr_20M.geojson https://gisco-services.ec.europa.eu/distribution/v2/countries/geojson/CNTR_RG_20M_2024_4326.geojson
    curl -o cntr_10M.geojson https://gisco-services.ec.europa.eu/distribution/v2/countries/geojson/CNTR_RG_10M_2024_4326.geojson
    python -I tools/geo/paises_mundo.py <cntr_20M.geojson> <cntr_10M.geojson>

El mundo sale del 20M simplificado (sin la Antártida); Europa, del 10M recortado al recuadro
que se dibuja (de Islandia y Canarias a Chipre). Cada país lleva `id` = ISO alfa-2 de la web
(GR y GB, no EL y UK) y su nombre en los cinco idiomas (`es`, `en`, `ca`, `gl`, `eu`, de CLDR
vía babel). La proyección se hace en el navegador (src/lib/components/MapaMundo.svelte).

El seed conserva sus filas y añade las que faltan (nombre en castellano de CLDR) con dos
columnas: `region` (región del Banco Mundial, en castellano) y `es_europa`.
"""

import csv
import json
import math
import sys
from pathlib import Path

import requests
from babel import Locale

RAIZ = Path(__file__).resolve().parents[2]
SEED = RAIZ / "transform" / "seeds" / "paises_iso.csv"
GEO = RAIZ / "static" / "geo"
IDIOMAS = ["es", "en", "ca", "gl", "eu"]
LOCALES = {l: Locale.parse(l) for l in IDIOMAS}

GISCO_A_ISO = {"EL": "GR", "UK": "GB"}
REGIONES = {
    "Europe & Central Asia": "Europa y Asia central",
    "East Asia & Pacific": "Asia oriental y Pacífico",
    "Latin America & Caribbean": "América Latina y Caribe",
    "Middle East, North Africa, Afghanistan & Pakistan": "Oriente Medio y norte de África (con Afganistán y Pakistán)",
    "Middle East & North Africa": "Oriente Medio y norte de África",
    "North America": "América del Norte",
    "South Asia": "Asia meridional",
    "Sub-Saharan Africa": "África subsahariana",
}
# Europa geográfica y política (Consejo de Europa, la UE y sus vecinos del este)
EUROPA = set("AD AL AM AT AZ BA BE BG BY CH CY CZ DE DK EE ES FI FO FR GB GE GI GR HR HU IE IM IS IT "
             "JE GG LI LT LU LV MC MD ME MK MT NL NO PL PT RO RS RU SE SI SK SM TR UA VA XK".split())
# Recuadro de Europa (lon, lat), más amplio que lo que se ve para que no asomen los cortes
CAJA_EUROPA = (-35.0, 24.0, 70.0, 75.0)


# Nombres de CLDR que no son los de uso común en castellano
NOMBRES_ES = {"CI": "Costa de Marfil", "HK": "Hong Kong", "MO": "Macao", "PS": "Palestina",
              "MM": "Myanmar", "TL": "Timor Oriental", "JG": "Islas del Canal",
              "SX": "San Martín (Países Bajos)", "MF": "San Martín (Francia)"}


def nombre(iso2: str, idioma: str, defecto: str) -> str:
    if idioma == "es" and iso2 in NOMBRES_ES:
        return NOMBRES_ES[iso2]
    return LOCALES[idioma].territories.get(iso2) or defecto


# ---------------------------------------------------------------- simplificación
def _dist_seg(p, a, b):
    (x, y), (x1, y1), (x2, y2) = p, a, b
    dx, dy = x2 - x1, y2 - y1
    if dx == dy == 0:
        return math.hypot(x - x1, y - y1)
    t = max(0, min(1, ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy)))
    return math.hypot(x - x1 - t * dx, y - y1 - t * dy)


def douglas_peucker(puntos, tol):
    if len(puntos) < 3:
        return puntos
    marcas = [False] * len(puntos)
    marcas[0] = marcas[-1] = True
    pila = [(0, len(puntos) - 1)]
    while pila:
        i, j = pila.pop()
        dmax, k = 0, None
        for m in range(i + 1, j):
            d = _dist_seg(puntos[m], puntos[i], puntos[j])
            if d > dmax:
                dmax, k = d, m
        if k is not None and dmax > tol:
            marcas[k] = True
            pila += [(i, k), (k, j)]
    return [p for p, s in zip(puntos, marcas) if s]


def area(anillo):
    return abs(sum(x1 * y2 - x2 * y1 for (x1, y1), (x2, y2) in zip(anillo, anillo[1:] + anillo[:1]))) / 2


def recortar(anillo, caja):
    """Sutherland-Hodgman contra un rectángulo (vale para rellenar, no para topología)."""
    x0, y0, x1, y1 = caja
    bordes = [
        (lambda p: p[0] >= x0, lambda a, b: (x0, a[1] + (b[1] - a[1]) * (x0 - a[0]) / (b[0] - a[0]))),
        (lambda p: p[0] <= x1, lambda a, b: (x1, a[1] + (b[1] - a[1]) * (x1 - a[0]) / (b[0] - a[0]))),
        (lambda p: p[1] >= y0, lambda a, b: (a[0] + (b[0] - a[0]) * (y0 - a[1]) / (b[1] - a[1]), y0)),
        (lambda p: p[1] <= y1, lambda a, b: (a[0] + (b[0] - a[0]) * (y1 - a[1]) / (b[1] - a[1]), y1)),
    ]
    salida = anillo
    for dentro, corte in bordes:
        if not salida:
            break
        entrada, salida = salida, []
        for i, actual in enumerate(entrada):
            previo = entrada[i - 1]
            if dentro(actual):
                if not dentro(previo):
                    salida.append(corte(previo, actual))
                salida.append(actual)
            elif dentro(previo):
                salida.append(corte(previo, actual))
    return salida


def poligonos(geom):
    return [geom["coordinates"]] if geom["type"] == "Polygon" else geom["coordinates"]


def preparar(features, tol, area_min, decimales, caja=None, excluir=()):
    salida = []
    for f in features:
        pr = f["properties"]
        cod = GISCO_A_ISO.get(pr["CNTR_ID"], pr["CNTR_ID"])
        if len(cod) != 2 or cod in excluir:
            continue
        polis = []
        for poli in poligonos(f["geometry"]):
            ext = [tuple(c) for c in poli[0][:-1]]
            if caja:
                ext = recortar(ext, caja)
                if len(ext) < 3:
                    continue
            polis.append(ext)
        if not polis:
            continue
        mayor = max(area(p) for p in polis)
        anillos = []
        for p in polis:
            a = area(p)
            if a < area_min and a < mayor:  # se quitan islotes, nunca la pieza mayor de un país
                continue
            s = douglas_peucker(p + [p[0]], tol)[:-1]
            if len(s) < 3:
                s = p[:3] if len(p) >= 3 else None
            if s:
                anillos.append([[round(x, decimales), round(y, decimales)] for x, y in s])
        if not anillos:
            continue
        salida.append({
            "type": "Feature",
            "properties": {"id": cod, **{l: nombre(cod, l, pr["NAME_ENGL"].strip()) for l in IDIOMAS}},
            "geometry": {"type": "MultiPolygon", "coordinates": [[a] for a in anillos]},
        })
    salida.sort(key=lambda f: f["properties"]["id"])
    return {"type": "FeatureCollection", "features": salida}


def escribir_geo(ruta: Path, datos):
    ruta.write_text(json.dumps(datos, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"{ruta.relative_to(RAIZ)}: {len(datos['features'])} países, {ruta.stat().st_size / 1024:.0f} KB")


# ---------------------------------------------------------------- seed de países
def completar_seed():
    with SEED.open(encoding="utf-8", newline="") as fh:
        filas = list(csv.DictReader(fh))
    meta = requests.get("https://api.worldbank.org/v2/country?format=json&per_page=400", timeout=120).json()[1]
    region_bm = {m["id"]: REGIONES.get(m["region"]["value"].strip(), m["region"]["value"].strip())
                 for m in meta if m["region"]["value"].strip() != "Aggregates"}
    existentes = {f["iso3"] for f in filas}
    for f in filas:
        f["region"] = region_bm.get(f["iso3"], "")
        f["es_europa"] = "true" if f["cod_pais"] in EUROPA else "false"
    nuevas = []
    for m in meta:
        if m["region"]["value"].strip() == "Aggregates" or m["id"] in existentes:
            continue
        iso2 = m["iso2Code"]
        if iso2 == "XK":
            continue
        nuevas.append({
            "cod_pais": iso2, "iso3": m["id"], "eurostat": {"GR": "EL", "GB": "UK"}.get(iso2, iso2),
            "pais": nombre(iso2, "es", m["name"]), "es_ue": "false", "es_ocde": "false",
            "es_agregado": "false", "region": region_bm[m["id"]],
            "es_europa": "true" if iso2 in EUROPA else "false",
        })
    nuevas.sort(key=lambda f: f["pais"])
    columnas = ["cod_pais", "iso3", "eurostat", "pais", "es_ue", "es_ocde", "es_agregado", "region", "es_europa"]
    with SEED.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=columnas, lineterminator="\n")
        w.writeheader()
        w.writerows(filas + nuevas)
    print(f"{SEED.relative_to(RAIZ)}: {len(filas)} filas previas + {len(nuevas)} nuevas")


if __name__ == "__main__":
    g20 = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["features"]
    g10 = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))["features"]
    GEO.mkdir(parents=True, exist_ok=True)
    escribir_geo(GEO / "mundo.json", preparar(g20, tol=0.12, area_min=0.15, decimales=2, excluir={"AQ"}))
    escribir_geo(GEO / "europa.json", preparar(g10, tol=0.025, area_min=0.004, decimales=3, caja=CAJA_EUROPA))
    completar_seed()
