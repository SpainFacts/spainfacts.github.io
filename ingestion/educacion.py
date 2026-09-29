"""Fuente dlt de educación (Eurostat, API de diseminación JSON-stat 2.0).

Todas las series son de España (ES), de la UE-27 (EU27_2020) y, cuando existen,
de las comunidades autónomas (regiones NUTS 2, códigos ES11..ES70):

  eurostat_edu_abandono      Abandono temprano de la educación y la formación (18-24 años, %):
                             edat_lfse_14 (España y UE, desde 1992) + edat_lfse_16 (NUTS 2, desde 2000).
  eurostat_edu_nivel         Población de 25-64 años por nivel educativo máximo alcanzado (%):
                             edat_lfse_03 (España y UE) + edat_lfse_04 (NUTS 2).
  eurostat_edu_neet          Jóvenes que ni trabajan ni estudian ni se forman (NEET, %):
                             edat_lfse_20 (España y UE) + edat_lfse_22 (NUTS 2); edades 15-29 y 18-24.
  eurostat_edu_gasto_cofog   Gasto de las AAPP en educación (COFOG GF09 y subfunciones) en
                             millones de euros y % del PIB (gov_10a_exp).
  eurostat_edu_gasto_alumno  Gasto anual en centros educativos por alumno equivalente a tiempo
                             completo, por nivel, en euros, PPS y % del PIB per cápita (educ_uoe_fini04).
  eurostat_edu_matriculados  Alumnado matriculado por nivel CINE y titularidad del centro
                             (pública, privada concertada, privada no concertada), España (educ_uoe_enra01).
  eurostat_edu_secundaria2   Alumnado de secundaria superior por orientación (general / profesional),
                             España y UE (educ_uoe_enrs04), para el peso de la FP.
  eurostat_edu_pisa          % de alumnos de 15 años con bajo rendimiento en PISA (por debajo del
                             nivel 2) en lectura, matemáticas y ciencias, por sexo (educ_outc_pisa).
"""

import logging

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series

log = logging.getLogger(__name__)

EUROSTAT = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
NUTS2_ES = ["ES11", "ES12", "ES13", "ES21", "ES22", "ES23", "ES24", "ES30", "ES41", "ES42", "ES43",
            "ES51", "ES52", "ES53", "ES61", "ES62", "ES63", "ES64", "ES70"]
PAIS_UE = ["ES", "EU27_2020"]


def _datos(dataset: str, **params):
    params.update(format="JSON", lang="EN")
    r = requests.get(EUROSTAT + dataset, params=params, timeout=300)
    r.raise_for_status()
    return r.json()


def _filas(dataset: str, dims: list[str], **params):
    """Filas planas: time -> anio (texto), geo y las dimensiones pedidas; valor en float."""
    for coords, valor in parse_json_stat_series(_datos(dataset, **params)):
        if valor is None:
            continue
        fila = {"dataset": dataset, "anio": coords.get("time"), "geo": coords.get("geo")}
        for d in dims:
            fila[d] = coords.get(d)
        fila["valor"] = float(valor)
        yield fila


@dlt.source(name="educacion")
def educacion():
    @dlt.resource(name="eurostat_edu_abandono", write_disposition="replace")
    def abandono():
        yield from _filas("edat_lfse_14", [], geo=PAIS_UE, sex="T", wstatus="POP", age="Y18-24")
        yield from _filas("edat_lfse_16", [], geo=NUTS2_ES, sex="T", age="Y18-24")

    @dlt.resource(name="eurostat_edu_nivel", write_disposition="replace")
    def nivel():
        yield from _filas("edat_lfse_03", ["isced11"], geo=PAIS_UE, sex="T", age="Y25-64")
        yield from _filas("edat_lfse_04", ["isced11"], geo=NUTS2_ES, sex="T", age="Y25-64")

    @dlt.resource(name="eurostat_edu_neet", write_disposition="replace")
    def neet():
        for edad in ["Y15-29", "Y18-24"]:
            yield from _filas("edat_lfse_20", ["age"], geo=PAIS_UE, sex="T", wstatus="NEMP", age=edad)
            yield from _filas("edat_lfse_22", ["age"], geo=NUTS2_ES, sex="T", wstatus="NEMP", age=edad)

    @dlt.resource(name="eurostat_edu_gasto_cofog", write_disposition="replace")
    def gasto_cofog():
        yield from _filas("gov_10a_exp", ["cofog99", "unit"], geo=PAIS_UE, sector="S13", na_item="TE",
                          cofog99=["GF09", "GF0901", "GF0902", "GF0903", "GF0904"],
                          unit=["PC_GDP", "MIO_EUR"])

    @dlt.resource(name="eurostat_edu_gasto_alumno", write_disposition="replace")
    def gasto_alumno():
        yield from _filas("educ_uoe_fini04", ["isced11", "sector", "unit"], geo=PAIS_UE,
                          unit=["EUR", "PPS", "GDP_HAB"])

    @dlt.resource(name="eurostat_edu_matriculados", write_disposition="replace")
    def matriculados():
        yield from _filas("educ_uoe_enra01", ["isced11", "sector"], geo="ES", sex="T", worktime="TOTAL")

    @dlt.resource(name="eurostat_edu_secundaria2", write_disposition="replace")
    def secundaria2():
        yield from _filas("educ_uoe_enrs04", ["isced11", "sector"], geo=PAIS_UE, sex="T", worktime="TOTAL")

    @dlt.resource(name="eurostat_edu_pisa", write_disposition="replace")
    def pisa():
        yield from _filas("educ_outc_pisa", ["field", "sex"], geo=PAIS_UE)

    return abandono, nivel, neet, gasto_cofog, gasto_alumno, matriculados, secundaria2, pisa


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("educacion").run(educacion()))
