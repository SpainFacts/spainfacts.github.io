"""Teselas vectoriales (PMTiles) de municipios y secciones censales para el explorador de mapas.

Junta en GeoJSON por líneas (lo que lee tippecanoe):
  - municipios: static/geo/municipios.geojson -> capa «municipios» (cod, n = nombre)
  - secciones: static-extra/geo/secciones/<año>/<cod_mun>.geojson, TODAS las versiones
    -> capa «secciones» (cod, m = cod_mun, v = año del seccionado), desde el zoom 9.
    Cada dato de mapas_secciones lleva su geo_anio: el mapa enseña en cada municipio la
    versión v = geo_anio y oculta las demás.
y escribe static/geo/municipios-cajas.json ({cod: [oeste, sur, este, norte]}) para que el buscador
del mapa pueda acercarse a un municipio sin bajar las teselas.

Las teselas las hace tippecanoe (Linux; en Windows, con WSL): ver tools/geo/teselas_mapas.sh.

    python tools/geo/teselas_mapas.py <carpeta_salida>
"""

import json
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
MUNICIPIOS = RAIZ / "static" / "geo" / "municipios.geojson"
SECCIONES = RAIZ / "static-extra" / "geo" / "secciones"
CAJAS = RAIZ / "static" / "geo" / "municipios-cajas.json"


def caja(geom, b=None):
    b = b or [180.0, 90.0, -180.0, -90.0]
    polys = [geom["coordinates"]] if geom["type"] == "Polygon" else geom["coordinates"]
    for poly in polys:
        for lon, lat in poly[0]:
            b[0], b[1], b[2], b[3] = min(b[0], lon), min(b[1], lat), max(b[2], lon), max(b[3], lat)
    return b


def main(salida: Path) -> None:
    salida.mkdir(parents=True, exist_ok=True)

    cajas = {}
    n = 0
    with open(salida / "municipios.geojsonl", "w", encoding="utf-8") as out:
        for f in json.loads(MUNICIPIOS.read_text(encoding="utf-8"))["features"]:
            p = f["properties"]
            cod = p["cod_mun"]
            cajas[cod] = [round(x, 3) for x in caja(f["geometry"], cajas.get(cod))]
            out.write(json.dumps({"type": "Feature", "properties": {"cod": cod, "n": p.get("nombre", "")},
                                  "geometry": f["geometry"]}, ensure_ascii=False, separators=(",", ":")) + "\n")
            n += 1
    CAJAS.write_text(json.dumps(cajas, separators=(",", ":")), encoding="utf-8")
    print(f"municipios: {n} polígonos; cajas en {CAJAS.relative_to(RAIZ)}")

    n = 0
    with open(salida / "secciones.geojsonl", "w", encoding="utf-8") as out:
        for carpeta in sorted(p for p in SECCIONES.iterdir() if p.is_dir() and p.name.isdigit()):
            anio = int(carpeta.name)
            for fichero in sorted(carpeta.glob("*.geojson")):
                cod_mun = fichero.stem
                for f in json.loads(fichero.read_text(encoding="utf-8"))["features"]:
                    cod = str(f["properties"].get("id", ""))
                    if not cod or not f.get("geometry"):
                        continue
                    # (sin "tippecanoe": {"minzoom": ...} por polígono: con esa clave tippecanoe 2.49
                    # dejaba un solo polígono por tesela; el zoom mínimo va en teselas_mapas.sh)
                    out.write(json.dumps({"type": "Feature",
                                          "properties": {"cod": cod, "m": cod_mun, "v": anio},
                                          "geometry": f["geometry"]}, separators=(",", ":")) + "\n")
                    n += 1
    print(f"secciones: {n} polígonos (todas las versiones)")


if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp/teselas_mapas"))
