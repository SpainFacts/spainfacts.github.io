"""Contorno de las regiones NUTS 2 (versión 2021) de Europa para los mapas de suelos.

Descarga el GeoJSON de GISCO (Eurostat, escala 1:20 millones, WGS84) y escribe
static/geo/nuts2_europa.geojson con las propiedades `nuts2` (código), `nombre` y `pais` (código
Eurostat). Quita las regiones de ultramar, Svalbard, Turquía e Islandia (las mismas que NUTS_FUERA de
ingestion/suelos.py) y redondea las coordenadas a 4 decimales (unos 10 m).

© EuroGeographics para los límites administrativos.

Uso:
    .venv/Scripts/python.exe -X utf8 tools/geo/nuts2_europa.py
"""

import json
import sys
from pathlib import Path

import requests

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO))

from ingestion.suelos import NUTS_FUERA  # noqa: E402

URL = "https://gisco-services.ec.europa.eu/distribution/v2/nuts/geojson/NUTS_RG_20M_2021_4326_LEVL_2.geojson"
SALIDA = REPO / "static" / "geo" / "nuts2_europa.geojson"


def redondear(c):
    if isinstance(c[0], (int, float)):
        return [round(c[0], 4), round(c[1], 4)]
    return [redondear(x) for x in c]


def main():
    geo = requests.get(URL, timeout=120).json()
    features = []
    for f in geo["features"]:
        p = f["properties"]
        # Turquía e Islandia se salen de la rejilla de los cálculos (y estirarían el mapa)
        if p["NUTS_ID"].startswith(NUTS_FUERA) or p["CNTR_CODE"] in ("TR", "IS"):
            continue
        g = f["geometry"]
        features.append({
            "type": "Feature",
            "properties": {"nuts2": p["NUTS_ID"], "nombre": p.get("NAME_LATN") or p.get("NUTS_NAME"), "pais": p["CNTR_CODE"]},
            "geometry": {"type": g["type"], "coordinates": redondear(g["coordinates"])},
        })
    SALIDA.write_text(json.dumps({"type": "FeatureCollection", "features": features}, ensure_ascii=False, separators=(",", ":")),
                      encoding="utf-8")
    print(f"{len(features)} regiones, {SALIDA.stat().st_size / 1e6:.2f} MB en {SALIDA}")


if __name__ == "__main__":
    main()
