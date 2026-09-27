"""Fuente dlt para la API pública REData de Red Eléctrica (REE), sin clave.

REE, como Operador del Sistema, publica el balance eléctrico nacional en
https://apidatos.ree.es/es/datos/<categoria>/<widget>. La API rechaza rangos
largos con time_trunc=year (error 400 "datos no disponibles"), así que se pide
año a año desde 2015. Todo se carga en `raw` con carga completa ("replace"):
son unos pocos cientos de filas, idempotente y sin estado.

Tablas:
1. ree_estructura_generacion: generación anual (MWh) por tecnología, sistema
   nacional (generacion/estructura-generacion), incluida la fila "Generación total".
2. ree_demanda: demanda eléctrica anual nacional en MWh (demanda/evolucion).
3. ree_potencia_instalada: potencia instalada (MW) a cierre de año por tecnología
   (generacion/potencia-instalada). Ese widget devuelve HTTP 500 de forma
   persistente desde 2026; si falla, el recurso usa como respaldo la estadística
   oficial de capacidad eléctrica de Eurostat (nrg_inf_epc, que España reporta a
   partir de los datos de REE/MITECO) y lo indica en la columna `fuente`.

El año en curso se carga también, marcado con provisional=true (acumulado
hasta la fecha); los marts de dbt solo usan años completos.
"""

import logging
from datetime import date

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series

REE_BASE = "https://apidatos.ree.es/es/datos/"
ANIO_INICIO = 2015
CABECERAS = {"Accept": "application/json", "User-Agent": "SpainFacts/1.0"}

EUROSTAT_CAPACIDAD = (
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
    "nrg_inf_epc?geo=ES&unit=MW&plant_tec=CAP_NET_ELC&operator=TOTAL"
    f"&sinceTimePeriod={ANIO_INICIO}&format=JSON&lang=EN"
)

log = logging.getLogger(__name__)

# Tipos explícitos: algunas columnas pueden llegar vacías (p. ej. en el respaldo
# de Eurostat) y dlt no las materializaría.
COLUMNAS = {
    "anio": {"data_type": "bigint"},
    "id_serie": {"data_type": "text"},
    "tecnologia": {"data_type": "text"},
    "tipo": {"data_type": "text"},
    "valor": {"data_type": "double"},
    "porcentaje": {"data_type": "double"},
    "provisional": {"data_type": "bool"},
}


def _anios():
    # (año, provisional): todos los años completos más el año en curso
    actual = date.today().year
    return [(a, a == actual) for a in range(ANIO_INICIO, actual + 1)]


def _widget(ruta: str, anio: int) -> list[dict]:
    """Devuelve la lista `included` de un widget REE para un año natural."""
    fin = min(date(anio, 12, 31), date.today())
    params = {
        "start_date": f"{anio}-01-01T00:00",
        "end_date": f"{fin.isoformat()}T23:59",
        "time_trunc": "year",
    }
    respuesta = requests.get(REE_BASE + ruta, params=params, headers=CABECERAS, timeout=120)
    respuesta.raise_for_status()
    return respuesta.json().get("included", [])


def _filas_widget(ruta: str):
    for anio, provisional in _anios():
        for serie in _widget(ruta, anio):
            atributos = serie["attributes"]
            for punto in atributos.get("values", []):
                yield {
                    "anio": int(punto["datetime"][:4]),
                    "id_serie": serie.get("id"),
                    "tecnologia": atributos.get("title"),
                    "tipo": atributos.get("type"),  # Renovable / No-Renovable / total
                    "valor": punto.get("value"),
                    "porcentaje": punto.get("percentage"),
                    "provisional": provisional,
                }


@dlt.resource(name="ree_estructura_generacion", write_disposition="replace", columns=COLUMNAS)
def estructura_generacion():
    # valor en MWh; porcentaje sobre la generación total (0-1)
    yield from _filas_widget("generacion/estructura-generacion")


@dlt.resource(name="ree_demanda", write_disposition="replace", columns=COLUMNAS)
def demanda():
    # valor en MWh (demanda nacional en barras de central)
    yield from _filas_widget("demanda/evolucion")


def _potencia_eurostat():
    respuesta = requests.get(EUROSTAT_CAPACIDAD, timeout=180)
    respuesta.raise_for_status()
    datos = respuesta.json()
    etiquetas = datos["dimension"]["siec"]["category"]["label"]
    for coords, valor in parse_json_stat_series(datos):
        yield {
            "anio": int(coords["time"]),
            "id_serie": coords["siec"],
            "tecnologia": etiquetas.get(coords["siec"]),
            "tipo": None,
            "valor": valor,
            "porcentaje": None,
            "provisional": False,
            "fuente": "eurostat_nrg_inf_epc",
        }


@dlt.resource(
    name="ree_potencia_instalada",
    write_disposition="replace",
    columns={**COLUMNAS, "fuente": {"data_type": "text"}},
)
def potencia_instalada():
    # valor en MW. Se intenta primero REE; si el widget falla se usa Eurostat.
    try:
        filas = [dict(f, fuente="ree") for f in _filas_widget("generacion/potencia-instalada")]
    except requests.RequestException as error:
        log.warning("REE potencia-instalada no disponible (%s); se usa Eurostat nrg_inf_epc", error)
        filas = list(_potencia_eurostat())
    yield from filas


@dlt.source(name="ree")
def ree():
    return [estructura_generacion, demanda, potencia_instalada]
