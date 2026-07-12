"""Fuente dlt para la API JSON del INE (Tempus3).

Cada tabla del INE se expone como un recurso dlt que carga TODAS las series
de la tabla (el script antiguo de scripts/ solo cargaba la última) en el
esquema `raw` de MotherDuck, con carga completa diaria (write_disposition
"replace": las tablas del INE son pequeñas y así la carga es idempotente).
"""

import dlt
import requests

INE_BASE = "https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/"

# nombre de tabla destino en raw -> id de tabla del INE
TABLAS = {
    "ine_ipc": "50902",  # IPC: índices y tasas de variación (nacional, por grupo COICOP)
    "ine_paro": "65219",  # EPA: tasas de paro por sexo y grupo de edad (nacional, 2002-hoy)
    # Ojo: la 65292 que usaba el script antiguo son valores ABSOLUTOS por CCAA
    # (no tiene tasas), y la 4086 está descatalogada (solo 2021-2023).
}


def _tabla_resource(nombre: str, tabla_id: str):
    @dlt.resource(name=nombre, write_disposition="replace")
    def filas():
        respuesta = requests.get(f"{INE_BASE}{tabla_id}", timeout=120)
        respuesta.raise_for_status()
        for serie in respuesta.json():
            for punto in serie.get("Data", []):
                yield {
                    "cod_serie": serie.get("COD"),
                    "serie": serie.get("Nombre"),
                    "fecha": punto.get("Fecha"),  # epoch en milisegundos
                    "anyo": punto.get("Anyo"),
                    "valor": punto.get("Valor"),
                    "secreto": punto.get("Secreto"),
                }

    return filas


@dlt.source(name="ine")
def ine():
    return [_tabla_resource(nombre, tabla_id) for nombre, tabla_id in TABLAS.items()]
