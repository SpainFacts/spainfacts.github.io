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

3) Extranjeros en Europa (Eurostat, todos los países que publican), para comparar a
   España con otros países:
   - crim_just_ctz: condenados por nacionalidad (del país / extranjera / total);
   - crim_pris_ctz: presos por nacionalidad;
   - migr_pop1ctz: población a 1 de enero por nacionalidad (del país / extranjera y apátrida), sexo
     y edad en grupos de cinco años (para las tasas y la corrección por edad);
   - indicadores de integración por nacionalidad: empleo (lfsa_ergan), paro (lfsa_urgan),
     riesgo de pobreza o exclusión (ilc_peps05n), abandono escolar temprano
     (edat_lfse_01), sobrecualificación (lfsa_eoqgan) y hacinamiento (ilc_lvho15);
   - migr_acq: adquisiciones de nacionalidad (para la tasa de nacionalización).

Recursos (replace):
  acnur_llegadas             mes x vía, personas
  eurostat_asilo_mensual     mes, primeras solicitudes
  eurostat_asilo_nacionalidad año x nacionalidad, primeras solicitudes
  eurostat_condenados_nacionalidad  país x año x nacionalidad, condenados
  eurostat_presos_nacionalidad      país x año x nacionalidad, presos
  eurostat_poblacion_nacionalidad   país x año x nacionalidad x sexo x edad, habitantes
  eurostat_integracion              indicador x país x año x nacionalidad, %
  eurostat_nacionalizaciones        país x año, adquisiciones de nacionalidad
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

    def _eurostat(dataset: str, params: dict) -> dict:
        r = requests.get(EUROSTAT + dataset, timeout=300, headers=CABECERAS,
                         params={**params, "format": "JSON", "lang": "EN"})
        r.raise_for_status()
        return r.json()

    @dlt.resource(name="eurostat_condenados_nacionalidad", write_disposition="replace")
    def condenados_nacionalidad():
        datos = _eurostat("crim_just_ctz", {"leg_stat": "PER_CNV", "unit": "NR"})
        for c, valor in parse_json_stat_series(datos):
            yield {"geo": c["geo"], "anio": int(c["time"]), "citizen": c["citizen"], "condenados": valor}

    @dlt.resource(name="eurostat_presos_nacionalidad", write_disposition="replace")
    def presos_nacionalidad():
        datos = _eurostat("crim_pris_ctz", {"unit": "NR"})
        for c, valor in parse_json_stat_series(datos):
            yield {"geo": c["geo"], "anio": int(c["time"]), "citizen": c["citizen"], "presos": valor}

    EDADES = ["TOTAL", "Y15-19", "Y20-24", "Y25-29", "Y30-34", "Y35-39", "Y40-44", "Y45-49", "Y50-54",
              "Y55-59", "Y60-64", "Y65-69", "Y70-74", "Y75-79", "Y80-84", "Y_GE85"]

    @dlt.resource(name="eurostat_poblacion_nacionalidad", write_disposition="replace")
    def poblacion_nacionalidad():
        # en migr_pop1ctz los extranjeros son FOR_STLS (extranjeros y apátridas): se guardan como FOR
        datos = _eurostat("migr_pop1ctz", {"unit": "NR", "citizen": ["FOR_STLS", "NAT"], "sex": ["T", "M", "F"],
                                           "age": EDADES, "sinceTimePeriod": "2008"})
        for c, valor in parse_json_stat_series(datos):
            yield {"geo": c["geo"], "anio": int(c["time"]), "citizen": "FOR" if c["citizen"] == "FOR_STLS" else c["citizen"],
                   "sexo": c["sex"],
                   "edad": c["age"], "poblacion": valor}

    # indicador -> (dataset, filtros fijos); todos en % y por nacionalidad
    INTEGRACION = {
        "empleo": ("lfsa_ergan", {"age": "Y20-64", "sex": "T", "unit": "PC"}),
        "paro": ("lfsa_urgan", {"age": "Y15-74", "sex": "T", "unit": "PC"}),
        "arope": ("ilc_peps05n", {"age": "Y_GE18", "sex": "T", "unit": "PC"}),
        "abandono_escolar": ("edat_lfse_01", {"age": "Y18-24", "sex": "T", "unit": "PC", "wstatus": "POP"}),
        "sobrecualificacion": ("lfsa_eoqgan", {"age": "Y20-64", "sex": "T", "unit": "PC"}),
        "hacinamiento": ("ilc_lvho15", {"age": "Y_GE18", "sex": "T", "unit": "PC"}),
    }

    @dlt.resource(name="eurostat_integracion", write_disposition="replace")
    def integracion():
        for indicador, (dataset, filtros) in INTEGRACION.items():
            datos = _eurostat(dataset, {**filtros, "citizen": ["NAT", "FOR", "EU27_2020_FOR", "NEU27_2020_FOR"]})
            for c, valor in parse_json_stat_series(datos):
                yield {"indicador": indicador, "geo": c["geo"], "anio": int(c["time"]),
                       "citizen": c["citizen"], "valor": valor}

    @dlt.resource(name="eurostat_nacionalizaciones", write_disposition="replace")
    def nacionalizaciones():
        datos = _eurostat("migr_acq", {"agedef": "COMPLET", "age": "TOTAL", "sex": "T", "unit": "NR",
                                       "citizen": "TOTAL"})
        for c, valor in parse_json_stat_series(datos):
            yield {"geo": c["geo"], "anio": int(c["time"]), "nacionalizaciones": valor}

    return (llegadas, asilo_mensual, asilo_nacionalidad, condenados_nacionalidad, presos_nacionalidad,
            poblacion_nacionalidad, integracion, nacionalizaciones)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("migracion").run(migracion()))
