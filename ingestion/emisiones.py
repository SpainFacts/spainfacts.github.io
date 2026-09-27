"""Fuente dlt para el inventario oficial de gases de efecto invernadero de España.

Eurostat publica en env_air_gge las emisiones que cada Estado miembro reporta
a la CMNUCC y a la UE (para España, el Inventario Nacional del MITECO), en
millones de toneladas de CO2 equivalente y desglosadas por categoría CRF del
IPCC (1 Energía, 2 Procesos industriales, 3 Agricultura, 4 LULUCF, 5 Residuos...).

Se descargan TODAS las categorías CRF (geo=ES, unit=MIO_T, airpol=GHG) desde
2015 en formato JSON-stat y se cargan en `raw.eurostat_gei` con carga completa
("replace"): ~1.300 filas. La agrupación en sectores divulgativos se hace en
dbt (stg_energia_emisiones_gei), donde está documentado el mapeo CRF -> sector.
"""

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series

GEI_URL = (
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
    "env_air_gge?geo=ES&unit=MIO_T&airpol=GHG&sinceTimePeriod=2015&format=JSON&lang=EN"
)


@dlt.resource(name="eurostat_gei", write_disposition="replace")
def gei():
    respuesta = requests.get(GEI_URL, timeout=180)
    respuesta.raise_for_status()
    datos = respuesta.json()
    etiquetas = datos["dimension"]["src_crf"]["category"]["label"]
    for coords, valor in parse_json_stat_series(datos):
        yield {
            "anio": int(coords["time"]),
            "src_crf": coords["src_crf"],
            "categoria": etiquetas.get(coords["src_crf"]),
            "mt_co2eq": valor,  # millones de toneladas de CO2 equivalente
        }


@dlt.source(name="emisiones")
def emisiones():
    return [gei]
