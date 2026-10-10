"""Contornos de las secciones censales por municipio para los mapas de barrio.

Descarga el seccionado del INE de cada año pedido (shapefile de toda España en
ETRS89 UTM 30N, también Canarias), lo pasa a WGS84, lo simplifica y escribe un
GeoJSON por municipio en static-extra/geo/secciones/<año>/<cod_mun>.geojson
(servido como /geo/secciones/...), con la
propiedad `id` = código de sección INE (CUSEC, 10 dígitos). Solo municipios con
más de una sección: con una sola, el mapa sería el propio término municipal.

Para no repetir ~35 MB por año, el primer año pedido se escribe entero y los
siguientes solo con los municipios cuyo contorno cambió (de un año a otro cambia
~1 % de las secciones). La lista de ficheros escritos va al seed
transform/seeds/secciones_geo.csv (anio, cod_mun): el mart elecciones_secciones
usa, para cada elección, el fichero más reciente que no sea posterior a ella.
Hay que pasar siempre todos los años a la vez y en orden.

    https://www.ine.es/prodyser/cartografia/seccionado_<año>.zip

Qué año usar: las secciones cambian cada 1 de enero (se parten o se renumeran
las que crecen). Cada elección se pinta con el seccionado vigente ese año (las
generales y municipales de 2023 con el de 2023, las europeas de 2024 con el de
2024) y la renta del ADRH con el de su año.

Uso (requiere el entorno del repo, con duckdb):
    .venv/Scripts/python.exe -X utf8 tools/geo/secciones.py 2023 2024
"""

import json
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path

import duckdb
import requests

REPO = Path(__file__).resolve().parents[2]
# fuera de static/: ver tools/evidence-build.mjs
SALIDA = REPO / "static-extra" / "geo" / "secciones"
URL = "https://www.ine.es/prodyser/cartografia/seccionado_{}.zip"
TOLERANCIA_M = 6  # simplificación en metros (en UTM, antes de pasar a grados)
DECIMALES = 5  # ~1 m


def _redondear(c):
    if isinstance(c[0], (int, float)):
        return [round(c[0], DECIMALES), round(c[1], DECIMALES)]
    return [_redondear(x) for x in c]


def generar(anio: int, cache: Path, previo: dict[str, str]) -> list[str]:
    """Escribe los municipios de `anio` que cambian respecto a `previo` (cod_mun -> texto) y los devuelve."""
    zip_local = cache / f"seccionado_{anio}.zip"
    if not zip_local.exists():
        print(f"Descargando {URL.format(anio)}")
        with requests.get(URL.format(anio), stream=True, timeout=600,
                          headers={"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}) as r:
            r.raise_for_status()
            with open(zip_local, "wb") as f:
                shutil.copyfileobj(r.raw, f)
    carpeta = cache / f"seccionado_{anio}"
    if not carpeta.exists():
        with zipfile.ZipFile(zip_local) as z:
            z.extractall(carpeta)
    shp = next(carpeta.rglob("SECC_CE_*.shp"))

    con = duckdb.connect()
    con.sql("INSTALL spatial; LOAD spatial;")
    filas = con.execute(f"""
        WITH s AS (
            SELECT CUSEC AS id, CUMUN AS cod_mun,
                   ST_Transform(ST_SimplifyPreserveTopology(geom, {TOLERANCIA_M}),
                                'EPSG:25830', 'EPSG:4326', always_xy := true) AS g
            FROM ST_Read(?)
        )
        SELECT cod_mun, id, ST_AsGeoJSON(g)
        FROM s
        WHERE cod_mun IN (SELECT cod_mun FROM s GROUP BY cod_mun HAVING count(*) > 1)
        ORDER BY cod_mun, id
    """, [str(shp)]).fetchall()

    destino = SALIDA / str(anio)
    destino.mkdir(parents=True, exist_ok=True)
    por_mun: dict[str, list] = {}
    for cod_mun, cusec, geojson in filas:
        g = json.loads(geojson)
        g["coordinates"] = _redondear(g["coordinates"])
        por_mun.setdefault(cod_mun, []).append({"type": "Feature", "properties": {"id": cusec}, "geometry": g})
    total, escritos = 0, []
    for cod_mun, features in por_mun.items():
        texto = json.dumps({"type": "FeatureCollection", "features": features}, separators=(",", ":"))
        if previo.get(cod_mun) == texto:
            continue
        previo[cod_mun] = texto
        (destino / f"{cod_mun}.geojson").write_text(texto, encoding="utf-8")
        total += len(texto)
        escritos.append(cod_mun)
    print(f"{anio}: {len(por_mun)} municipios con secciones, {len(escritos)} escritos, {total / 1e6:.1f} MB")
    return escritos


if __name__ == "__main__":
    anios = [int(a) for a in sys.argv[1:]] or [2023, 2024]
    cache = Path(tempfile.gettempdir()) / "spainfacts_seccionado"
    cache.mkdir(exist_ok=True)
    if SALIDA.exists():
        shutil.rmtree(SALIDA)
    previo: dict[str, str] = {}
    lineas = ["anio,cod_mun"]
    for a in sorted(anios):
        lineas += [f"{a},{m}" for m in generar(a, cache, previo)]
    (REPO / "transform" / "seeds" / "secciones_geo.csv").write_text("\n".join(lineas) + "\n", encoding="utf-8")
