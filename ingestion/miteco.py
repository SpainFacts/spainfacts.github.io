"""Fuente dlt para la reserva hídrica semanal del MITECO (Boletín Hidrológico).

El MITECO publica cada martes el histórico completo de embalses (1988-hoy)
como una base de datos Access dentro de un zip (~10 MB comprimido, ~220 MB
el .mdb). No hay API, así que se descarga el zip, se lee la tabla con
access-parser (Python puro, sin drivers ODBC) y se carga en `raw` con
carga completa ("replace"): ~720k filas, idempotente y sin estado.

Modelo de datos oficial:
https://www.miteco.gob.es/content/dam/miteco/es/agua/temas/evaluacion-de-los-recursos-hidricos/modelo-de-datos-bd-embalses-1988-2022_tcm30-538818.pdf
"""

import io
import tempfile
import zipfile
from datetime import date
from pathlib import Path

import dlt
import requests
from access_parser import AccessParser

BD_EMBALSES_URL = (
    "https://www.miteco.gob.es/content/dam/miteco/es/agua/temas/"
    "evaluacion-de-los-recursos-hidricos/boletin-hidrologico/Historico-de-embalses/BD-Embalses.zip"
)
TABLA = "T_Datos Embalses 1988-2026"


def _numero(texto: str | None) -> float | None:
    # Access devuelve los decimales con coma: "223,00"
    if texto in (None, ""):
        return None
    return float(texto.replace(".", "").replace(",", "."))


def _leer_tabla() -> dict[str, list]:
    respuesta = requests.get(BD_EMBALSES_URL, timeout=300, headers={"User-Agent": "SpainFacts/1.0"})
    respuesta.raise_for_status()
    with tempfile.TemporaryDirectory() as tmp:
        with zipfile.ZipFile(io.BytesIO(respuesta.content)) as z:
            mdb = next(n for n in z.namelist() if n.lower().endswith(".mdb"))
            ruta = Path(z.extract(mdb, tmp))
        db = AccessParser(str(ruta))
        # El nombre de la tabla lleva el último año; se busca por prefijo para
        # que no se rompa en enero cuando pase a "1988-2027".
        tabla = next((t for t in db.catalog if t.startswith("T_Datos Embalses")), TABLA)
        return db.parse_table(tabla)


@dlt.resource(name="miteco_embalses", write_disposition="replace")
def embalses():
    t = _leer_tabla()
    for fecha, ambito, embalse, total, actual, electrico in zip(
        t["FECHA"], t["AMBITO_NOMBRE"], t["EMBALSE_NOMBRE"], t["AGUA_TOTAL"], t["AGUA_ACTUAL"], t["ELECTRICO_FLAG"]
    ):
        yield {
            "fecha": date.fromisoformat(fecha[:10]),
            "ambito": ambito,
            "embalse": embalse,
            "capacidad_hm3": _numero(total),
            "volumen_hm3": _numero(actual),
            "uso_electrico": str(electrico).startswith("1"),
        }


@dlt.source(name="miteco")
def miteco():
    return [embalses]
