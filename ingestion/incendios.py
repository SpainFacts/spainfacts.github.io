"""Fuente dlt para incendios forestales en España (EFFIS + NASA FIRMS).

Dos fuentes abiertas, sin clave de API:

1. **EFFIS – Áreas quemadas** (Copernicus, European Forest Fire Information
   System): https://api.effis.emergency.copernicus.eu/rest/2/burntareas/current/
   Pese al nombre "current", el endpoint devuelve el histórico completo de
   perímetros cartografiados con satélite desde 2000 (~12.700 incendios en
   España, típicamente de 30 ha o más). Cada registro trae centroide, bbox,
   provincia (NUTS3, en las islas viene la isla: "Mallorca", "Tenerife"...),
   municipio, fecha, superficie (ha), reparto por cubierta del suelo (%) y
   porcentaje dentro de la Red Natura 2000 (`percna2k`).
   No se guarda el polígono (`shape`), que es lo que pesa (~15 kB por
   incendio): basta el centroide y el bbox para los mapas de la web.
   Se pide año a año (filtro `firedate__gte/__lt`, una sola página por año)
   porque la paginación por offset no garantiza un orden estable, y se carga
   con "replace": EFFIS revisa perímetros y superficies de temporadas pasadas,
   así que la foto completa y actual es lo correcto. Es idempotente y tarda
   unos minutos (la API es lenta, ~20 s por cada 1.000 registros).

2. **NASA FIRMS – Focos activos** (VIIRS S-NPP, NOAA-20, NOAA-21 y MODIS),
   CSV públicos de los últimos 7 días para Europa:
   https://firms.modaps.eosdis.nasa.gov/active_fire/
   Se filtran a España con un punto-en-polígono sobre
   static/spain-provinces.geojson (así se descartan Portugal, Francia,
   Marruecos y el mar) y se asigna la provincia (`cod_prov`).
   Se carga con "merge" sobre la clave (latitud, longitud, fecha, hora,
   satélite, instrumento): el CSV solo cubre 7 días, así que fusionar hace
   que el histórico se acumule día a día sin duplicar focos; la página
   filtra después los últimos 7 días en dbt.
"""

import csv
import io
import json
from concurrent.futures import ThreadPoolExecutor
from datetime import date
from pathlib import Path

import dlt
import requests

EFFIS_URL = "https://api.effis.emergency.copernicus.eu/rest/2/burntareas/current/"
EFFIS_PRIMER_ANIO = 2000

FIRMS_BASE = "https://firms.modaps.eosdis.nasa.gov/data/active_fire"
# instrumento -> ruta del CSV de 7 días para Europa
FIRMS_CSV = {
    "VIIRS_SNPP": f"{FIRMS_BASE}/suomi-npp-viirs-c2/csv/SUOMI_VIIRS_C2_Europe_7d.csv",
    "VIIRS_NOAA20": f"{FIRMS_BASE}/noaa-20-viirs-c2/csv/J1_VIIRS_C2_Europe_7d.csv",
    "VIIRS_NOAA21": f"{FIRMS_BASE}/noaa-21-viirs-c2/csv/J2_VIIRS_C2_Europe_7d.csv",
    "MODIS": f"{FIRMS_BASE}/modis-c6.1/csv/MODIS_C6_1_Europe_7d.csv",
}

PROVINCIAS_GEOJSON = Path(__file__).resolve().parents[1] / "static" / "spain-provinces.geojson"

CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

# Columnas de cubierta del suelo que EFFIS devuelve como texto "12.34000000"
COBERTURAS = [
    "broadlea", "conifer", "mixed", "scleroph", "transit",
    "othernatlc", "agriareas", "artifsurf", "otherlc", "percna2k",
]


def _texto(valor: str | None) -> str | None:
    """Arregla mojibake (UTF-8 leído como Latin-1) si aparece: 'RandÃ­n' -> 'Randín'."""
    if not valor:
        return valor
    try:
        return valor.encode("latin-1").decode("utf-8")
    except (UnicodeEncodeError, UnicodeDecodeError):
        return valor


def _float(valor) -> float | None:
    if valor in (None, ""):
        return None
    return float(valor)


# ---------------------------------------------------------------- EFFIS


def _effis_anio(anio: int) -> list[dict]:
    params = {
        "country": "ES",
        "firedate__gte": f"{anio}-01-01T00:00:00",
        "firedate__lt": f"{anio + 1}-01-01T00:00:00",
        "limit": 1,
    }
    # Primero se pide el recuento y luego todo el año en una única página.
    r = requests.get(EFFIS_URL, params=params, headers=CABECERAS, timeout=120)
    r.raise_for_status()
    total = r.json()["count"]
    if total == 0:
        return []
    params["limit"] = total + 50
    r = requests.get(EFFIS_URL, params=params, headers=CABECERAS, timeout=900)
    r.raise_for_status()
    # Se decodifica explícitamente como UTF-8 (sin fiarse del charset de la cabecera)
    resultados = json.loads(r.content.decode("utf-8"))["results"]
    if len(resultados) < total:
        raise RuntimeError(f"EFFIS {anio}: se esperaban {total} incendios y llegaron {len(resultados)}")
    return resultados


@dlt.resource(name="effis_areas_quemadas", write_disposition="replace", primary_key="id")
def effis_areas_quemadas():
    anios = range(EFFIS_PRIMER_ANIO, date.today().year + 1)
    vistos: set[int] = set()
    # Pocas peticiones en paralelo para no castigar la API (cada año tarda ~20-60 s)
    with ThreadPoolExecutor(max_workers=4) as pool:
        for resultados in pool.map(_effis_anio, anios):
            for x in resultados:
                if x["id"] in vistos:
                    continue
                vistos.add(x["id"])
                lon, lat = (x.get("centroid") or {}).get("coordinates", [None, None])
                bbox = x.get("bbox") or [None, None, None, None]
                fila = {
                    "id": x["id"],
                    "firedate": x.get("firedate"),
                    "lastupdate": x.get("lastupdate"),
                    "country": x.get("country"),
                    "province": _texto(x.get("province")),
                    "commune": _texto(x.get("commune")),
                    "area_ha": _float(x.get("area_ha")),
                    "longitud": lon,
                    "latitud": lat,
                    "bbox_lon_min": bbox[0],
                    "bbox_lat_min": bbox[1],
                    "bbox_lon_max": bbox[2],
                    "bbox_lat_max": bbox[3],
                    "noneu": x.get("noneu"),
                }
                for c in COBERTURAS:
                    fila[c] = _float(x.get(c))
                yield fila


# ---------------------------------------------------------------- FIRMS


def _cargar_provincias() -> list[tuple[str, str, tuple, list]]:
    """Devuelve [(cod_prov, nombre, bbox, anillos)] con los anillos exteriores e interiores."""
    geo = json.loads(PROVINCIAS_GEOJSON.read_text(encoding="utf-8"))
    provincias = []
    for f in geo["features"]:
        g = f["geometry"]
        poligonos = g["coordinates"] if g["type"] == "MultiPolygon" else [g["coordinates"]]
        anillos = [anillo for pol in poligonos for anillo in pol]
        xs = [p[0] for a in anillos for p in a]
        ys = [p[1] for a in anillos for p in a]
        bbox = (min(xs), min(ys), max(xs), max(ys))
        provincias.append((f["properties"]["cod_prov"], f["properties"]["name"], bbox, anillos))
    return provincias


def _dentro(lon: float, lat: float, anillos: list) -> bool:
    # Ray casting con regla par-impar sobre todos los anillos (los huecos se restan solos)
    dentro = False
    for anillo in anillos:
        n = len(anillo)
        j = n - 1
        for i in range(n):
            xi, yi = anillo[i][0], anillo[i][1]
            xj, yj = anillo[j][0], anillo[j][1]
            if (yi > lat) != (yj > lat) and lon < (xj - xi) * (lat - yi) / (yj - yi) + xi:
                dentro = not dentro
            j = i
    return dentro


def _provincia(lon: float, lat: float, provincias) -> str | None:
    for cod, _nombre, (x0, y0, x1, y1), anillos in provincias:
        if x0 <= lon <= x1 and y0 <= lat <= y1 and _dentro(lon, lat, anillos):
            return cod
    return None


@dlt.resource(
    name="firms_focos",
    write_disposition="merge",
    primary_key=["latitude", "longitude", "acq_date", "acq_time", "satellite", "instrument"],
)
def firms_focos():
    provincias = _cargar_provincias()
    for instrumento, url in FIRMS_CSV.items():
        r = requests.get(url, headers=CABECERAS, timeout=300)
        r.raise_for_status()
        for fila in csv.DictReader(io.StringIO(r.content.decode("utf-8"))):
            lat, lon = float(fila["latitude"]), float(fila["longitude"])
            # Prefiltro rápido: península + Baleares + Canarias + Ceuta y Melilla
            if not (-18.5 <= lon <= 4.5 and 27.4 <= lat <= 44.0):
                continue
            cod_prov = _provincia(lon, lat, provincias)
            if cod_prov is None:
                continue
            yield {
                "latitude": lat,
                "longitude": lon,
                "acq_date": date.fromisoformat(fila["acq_date"]),
                "acq_time": fila["acq_time"].zfill(4),  # HHMM en UTC
                "satellite": fila["satellite"],
                "instrument": instrumento,
                # VIIRS: l/n/h o low/nominal/high; MODIS: 0-100
                "confidence": fila["confidence"],
                "frp": _float(fila.get("frp")),  # potencia radiativa del fuego (MW)
                "brightness": _float(fila.get("bright_ti4") or fila.get("brightness")),
                "daynight": fila.get("daynight"),
                "version": fila.get("version"),
                "cod_prov": cod_prov,
            }


@dlt.source(name="incendios")
def incendios():
    return [effis_areas_quemadas, firms_focos]
