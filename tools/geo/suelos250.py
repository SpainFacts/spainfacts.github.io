"""Ficheros del mapa de suelo de cada municipio, celdas de 250 m.

Lee las celdas que guarda el cálculo de suelos (data/suelos_cache/celdas250_<rejilla>_v<N>.npz,
ver ingestion/suelos.py) y escribe un JSON por municipio en
static-extra/suelos250/<cod_mun>.json (servido como /suelos250/<cod_mun>.json; ver
tools/evidence-build.mjs). Lo lee src/lib/suelos.js (celdasMunicipio) para el mapa de puntos del
municipio sobre el callejero del IGN.

Formato compacto (casi 4 millones de celdas en España):
    {"v": 1, "paso": 250, "a": [lon0, dlon_col, dlon_fila, lat0, dlat_col, dlat_fila], "d": "<base64>"}
- "a": transformación afín de (columna, fila) de la celda, contadas desde la esquina del municipio,
  a lon/lat de su centro (ajustada por mínimos cuadrados; error de unos metros).
- "d": 10 bytes por celda: columna y fila (uint16, little endian), textura (índice de TEXTURAS),
  grupo WRB (índice de WRB), cultivo (índice de CULTIVOS), pH × 20, materia orgánica × 10 (%) y
  arcilla (%), uint8; 255 = sin dato (pH: 0).

Los mapas de SoilGrids y CORINE 2018 no cambian: basta con regenerar los ficheros si cambia el
cálculo (VERSION de ingestion/suelos.py).

Uso:
    .venv/Scripts/python.exe -X utf8 tools/geo/suelos250.py
"""

import base64
import json
import shutil
import sys
from pathlib import Path

import numpy as np

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO))

from ingestion.suelos import CACHE, VERSION  # noqa: E402

SALIDA = REPO / "static-extra" / "suelos250"


def bytes_u8(x, escala=1.0, nulo=255):
    v = np.where(np.isnan(x), nulo, np.clip(np.round(x * escala), 0 if nulo == 255 else 1, 254 if nulo == 255 else 255))
    return v.astype(np.uint8)


def main():
    from rasterio.warp import transform as reproyectar

    if SALIDA.exists():
        shutil.rmtree(SALIDA)
    SALIDA.mkdir(parents=True)
    total = 0
    tam = 0
    for f in sorted(CACHE.glob(f"celdas250_*_v{VERSION}.npz")):
        with np.load(f, allow_pickle=False) as z:
            c = {k: z[k] for k in z.files}
        codigos = c["codigos"]
        paso = float(c["paso"])
        x = c["x0"] + (c["col"] + 0.5) * paso
        y = c["y0"] - (c["fila"] + 0.5) * paso
        lon, lat = reproyectar("EPSG:3035", "EPSG:4326", x.tolist(), y.tolist())
        lon, lat = np.array(lon), np.array(lat)
        orden = np.argsort(c["mun"], kind="stable")
        mun = c["mun"][orden]
        cortes = np.flatnonzero(np.diff(mun)) + 1
        for trozo in np.split(orden, cortes):
            cod = str(codigos[c["mun"][trozo[0]]])
            col = c["col"][trozo] - c["col"][trozo].min()
            fil = c["fila"][trozo] - c["fila"][trozo].min()
            # lon/lat del centro ≈ afín de (columna, fila) dentro del municipio
            A = np.column_stack([np.ones(len(trozo)), col, fil])
            alon = np.linalg.lstsq(A, lon[trozo], rcond=None)[0]
            alat = np.linalg.lstsq(A, lat[trozo], rcond=None)[0]
            reg = np.zeros(len(trozo), dtype=[("c", "<u2"), ("f", "<u2"), ("t", "u1"), ("w", "u1"), ("k", "u1"),
                                              ("ph", "u1"), ("mo", "u1"), ("ar", "u1")])
            reg["c"], reg["f"] = col, fil
            t = c["textura"][trozo].astype(np.int16)
            wr = c["wrb"][trozo].astype(np.int16)
            reg["t"] = np.where(t < 0, 255, t)
            reg["w"] = np.where(wr < 0, 255, wr)
            reg["k"] = c["cultivo"][trozo]
            reg["ph"] = bytes_u8(c["ph"][trozo], 20, nulo=0)
            reg["mo"] = bytes_u8(c["mo"][trozo], 10)
            reg["ar"] = bytes_u8(c["arcilla"][trozo], 1)
            datos = {"v": 1, "paso": paso, "a": [round(v, 7) for v in (*alon, *alat)],
                     "d": base64.b64encode(reg.tobytes()).decode("ascii")}
            texto = json.dumps(datos, separators=(",", ":"))
            (SALIDA / f"{cod}.json").write_text(texto, encoding="ascii")
            total += 1
            tam += len(texto)
        print(f"{f.name}: {len(cortes) + 1} municipios")
    print(f"{total} ficheros, {tam / 1e6:.1f} MB en {SALIDA}")


if __name__ == "__main__":
    main()
