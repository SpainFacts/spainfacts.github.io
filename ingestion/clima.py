"""Fuente dlt `clima`: series largas de emisiones de GEI y del sistema eléctrico.

Amplía hacia atrás las series que ya cargan ingestion/emisiones.py (Eurostat
env_air_gge desde 2015) e ingestion/ree.py (REE REData desde 2015), sin tocarlos:

1. eurostat_clima_gei: inventario oficial de GEI de España (el que el MITECO
   reporta a la CMNUCC y a la UE) por categoría CRF, en Mt CO2eq, desde 1990.
   Eurostat env_air_gge, geo=ES, unit=MIO_T, airpol=GHG, todas las categorías.
2. eurostat_clima_gei_paises: total sin LULUCF (TOTX4_MEMO) de España, la UE-27
   y los grandes países de comparación, desde 1990 (env_air_gge).
3. eurostat_clima_poblacion: población media anual (demo_gind, indic_de=AVG)
   de esos mismos territorios, para calcular toneladas por habitante.
4. clima_ree_generacion: generación anual nacional por tecnología (MWh), REE
   REData generacion/estructura-generacion, desde 2007 (primer año que sirve la
   API con time_trunc=year; 2006 y anteriores devuelven HTTP 400).
5. clima_ree_demanda: demanda nacional anual en barras de central (MWh), REE
   demanda/evolucion, desde 2007.
6. clima_ree_emisiones_co2: emisiones de CO2eq de la generación no renovable
   por tecnología (tCO2eq) y factor de emisión del conjunto (tCO2eq/MWh),
   REE generacion/no-renovables-detalle-emisiones-CO2, desde 2007.

Las tablas REE usan el mismo esquema de columnas que ingestion/ree.py (el año en
curso se carga con provisional=true). Todo con carga completa ("replace").
"""

from datetime import date

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series
from ingestion.ree import COLUMNAS, _widget

EUROSTAT = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
ANIO_INICIO_GEI = 1990
ANIO_INICIO_REE = 2007
# Territorios de comparación internacional (códigos Eurostat)
PAISES = ["ES", "EU27_2020", "DE", "FR", "IT", "PT", "PL", "NL"]


def _eurostat(dataset: str, params: list[tuple[str, str]]) -> dict:
    params = params + [("format", "JSON"), ("lang", "EN")]
    respuesta = requests.get(EUROSTAT + dataset, params=params, timeout=180)
    respuesta.raise_for_status()
    return respuesta.json()


@dlt.resource(name="eurostat_clima_gei", write_disposition="replace")
def gei_espana():
    datos = _eurostat(
        "env_air_gge",
        [("geo", "ES"), ("unit", "MIO_T"), ("airpol", "GHG"), ("sinceTimePeriod", str(ANIO_INICIO_GEI))],
    )
    etiquetas = datos["dimension"]["src_crf"]["category"]["label"]
    for coords, valor in parse_json_stat_series(datos):
        yield {
            "anio": int(coords["time"]),
            "src_crf": coords["src_crf"],
            "categoria": etiquetas.get(coords["src_crf"]),
            "mt_co2eq": float(valor) if valor is not None else None,
        }


@dlt.resource(name="eurostat_clima_gei_paises", write_disposition="replace")
def gei_paises():
    datos = _eurostat(
        "env_air_gge",
        [("unit", "MIO_T"), ("airpol", "GHG"), ("src_crf", "TOTX4_MEMO"), ("sinceTimePeriod", str(ANIO_INICIO_GEI))]
        + [("geo", g) for g in PAISES],
    )
    for coords, valor in parse_json_stat_series(datos):
        yield {
            "anio": int(coords["time"]),
            "geo": coords["geo"],
            "mt_co2eq": float(valor) if valor is not None else None,
        }


@dlt.resource(name="eurostat_clima_poblacion", write_disposition="replace")
def poblacion():
    datos = _eurostat(
        "demo_gind",
        [("indic_de", "AVG"), ("sinceTimePeriod", str(ANIO_INICIO_GEI))] + [("geo", g) for g in PAISES],
    )
    for coords, valor in parse_json_stat_series(datos):
        yield {
            "anio": int(coords["time"]),
            "geo": coords["geo"],
            "poblacion_media": float(valor) if valor is not None else None,
        }


def _filas_ree(ruta: str):
    actual = date.today().year
    for anio in range(ANIO_INICIO_REE, actual + 1):
        for serie in _widget(ruta, anio):
            atributos = serie["attributes"]
            for punto in atributos.get("values", []):
                yield {
                    "anio": int(punto["datetime"][:4]),
                    "id_serie": serie.get("id"),
                    "tecnologia": atributos.get("title"),
                    "tipo": atributos.get("type"),
                    "valor": punto.get("value"),
                    "porcentaje": punto.get("percentage"),
                    "provisional": anio == actual,
                }


@dlt.resource(name="clima_ree_generacion", write_disposition="replace", columns=COLUMNAS)
def ree_generacion():
    # valor en MWh; porcentaje sobre la generación total (0-1)
    yield from _filas_ree("generacion/estructura-generacion")


@dlt.resource(name="clima_ree_demanda", write_disposition="replace", columns=COLUMNAS)
def ree_demanda():
    # valor en MWh (demanda nacional en barras de central)
    yield from _filas_ree("demanda/evolucion")


@dlt.resource(name="clima_ree_emisiones_co2", write_disposition="replace", columns=COLUMNAS)
def ree_emisiones_co2():
    # valor en tCO2eq por tecnología; la serie "tCO2 eq./MWh" es el factor de emisión
    yield from _filas_ree("generacion/no-renovables-detalle-emisiones-CO2")


@dlt.source(name="clima")
def clima():
    return [gei_espana, gei_paises, poblacion, ree_generacion, ree_demanda, ree_emisiones_co2]
