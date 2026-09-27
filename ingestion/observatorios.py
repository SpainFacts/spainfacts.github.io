"""Fuente dlt para el censo de observatorios públicos (observatoriospublicos.es).

Sustituye a scripts/clean_observatories_data.py + load_observatories_to_motherduck.py:
aquí solo se carga el JSON tal cual en raw.observatorios_publicos; la limpieza
(año de creación, activo sí/no) vive en dbt (stg_observatorios).
"""

import dlt
import requests

OBSERVATORIOS_URL = "https://observatoriospublicos.es/observatories.json"


@dlt.resource(name="observatorios_publicos", write_disposition="replace")
def observatorios_publicos():
    respuesta = requests.get(OBSERVATORIOS_URL, timeout=60)
    respuesta.raise_for_status()
    for registro in respuesta.json():
        yield {
            "nombre": registro.get("name"),
            "ambito": registro.get("scope"),
            "tipo": registro.get("type"),
            "fecha_creacion_texto": registro.get("from_date"),
            "activo_texto": registro.get("is_active"),
            "organismos_padre": registro.get("parents"),
        }


@dlt.source(name="observatorios")
def observatorios():
    return [observatorios_publicos]
