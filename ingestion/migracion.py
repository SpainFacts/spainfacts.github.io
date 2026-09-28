"""Fuente dlt para la llegada de migrantes en situación irregular y el asilo.

1) Llegadas irregulares a España por vía (ACNUR, portal de datos operativos):
     https://data.unhcr.org/population/get/timeseries?widget_id=696926&geo_id=729&sv_id=100
       &population_group=<grupo>&frequency=month&fromDate=2014-01-01
   ACNUR republica las cifras del Ministerio del Interior (cuyo informe
   quincenal en PDF responde 403 a las descargas automáticas). Grupos:
     4797 = por mar a la península y Baleares, 5634 = por mar a Canarias,
     4798 = por tierra a Ceuta y Melilla.
   Comprobado con los totales anuales de Interior (2018: 57.264 por mar a la
   península y Baleares; 2024: 46.843 a Canarias).

2) Solicitudes de protección internacional (Eurostat):
   - migr_asyappctzm: primeras solicitudes al mes (total, España);
   - migr_asyappctza: primeras solicitudes al año por nacionalidad.

Recursos (replace):
  acnur_llegadas             mes x vía, personas
  eurostat_asilo_mensual     mes, primeras solicitudes
  eurostat_asilo_nacionalidad año x nacionalidad, primeras solicitudes
"""

import logging

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series

log = logging.getLogger(__name__)

ACNUR = "https://data.unhcr.org/population/get/timeseries"
VIAS = {"4797": "Mar: península y Baleares", "5634": "Mar: Canarias", "4798": "Tierra: Ceuta y Melilla"}
EUROSTAT = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
CABECERAS = {"User-Agent": "Mozilla/5.0 (spainfacts.org; datos abiertos)"}


@dlt.source(name="migracion")
def migracion():
    @dlt.resource(name="acnur_llegadas", write_disposition="replace")
    def llegadas():
        for grupo, via in VIAS.items():
            r = requests.get(ACNUR, headers=CABECERAS, timeout=120, params={
                "widget_id": 696926, "geo_id": 729, "sv_id": 100, "population_group": grupo,
                "frequency": "month", "fromDate": "2014-01-01"})
            r.raise_for_status()
            for x in r.json()["data"]["timeseries"]:
                yield {"anio": int(x["year"]), "mes": int(x["month"]), "via": via, "personas": x["individuals"]}

    @dlt.resource(name="eurostat_asilo_mensual", write_disposition="replace")
    def asilo_mensual():
        r = requests.get(EUROSTAT + "migr_asyappctzm", timeout=180, params={
            "geo": "ES", "applicant": "FRST", "sex": "T", "age": "TOTAL", "unit": "PER", "citizen": "TOTAL",
            "format": "JSON", "lang": "EN"})
        r.raise_for_status()
        for coords, valor in parse_json_stat_series(r.json()):
            yield {"mes": coords.get("time"), "solicitudes": valor}

    @dlt.resource(name="eurostat_asilo_nacionalidad", write_disposition="replace")
    def asilo_nacionalidad():
        r = requests.get(EUROSTAT + "migr_asyappctza", timeout=180, params={
            "geo": "ES", "applicant": "FRST", "sex": "T", "age": "TOTAL", "unit": "PER",
            "format": "JSON", "lang": "EN"})
        r.raise_for_status()
        datos = r.json()
        etiquetas = datos["dimension"]["citizen"]["category"]["label"]
        for coords, valor in parse_json_stat_series(datos):
            yield {"anio": coords.get("time"), "cod_nacionalidad": coords.get("citizen"),
                   "nacionalidad": etiquetas.get(coords.get("citizen")), "solicitudes": valor}

    return llegadas, asilo_mensual, asilo_nacionalidad


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("migracion").run(migracion()))
