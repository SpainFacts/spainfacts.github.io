"""Fuente dlt para el negocio de los medios (página /medios/sector).

Eurostat, estadísticas estructurales de empresas (SBS; para España las elabora el INE con la
Estadística Estructural de Empresas del sector servicios), los 27 países y el agregado de la UE:
  eurostat_medios_sbs        sbs_ovw_act (2021-último, metodología FRIBS): empresas (ENT_NR),
                             personas ocupadas (EMP_NR), cifra de negocios neta (NETTUR_MEUR) y valor
                             añadido (AV_MEUR) de las ramas NACE de los medios.
  eurostat_medios_sbs_2008   sbs_na_1a_se_r2 (2005-2020, metodología anterior): empresas (V11110),
                             cifra de negocios (V12110), valor añadido a coste de factores (V12150) y
                             personas ocupadas (V16110). Los indicadores se renombran a los de
                             sbs_ovw_act para poder unir las dos series (hay ruptura en 2021).
Ramas: J58 edición; J581 edición de libros, periódicos y revistas; J5813 edición de periódicos;
J5814 edición de revistas; J59 cine, vídeo, televisión y música; J60 programación y emisión de
radio y televisión; J601 radio; J602 televisión; J639 otros servicios de información; J6391
agencias de noticias.

El resto de datos de la página (inversión publicitaria de InfoAdex, audiencias del EGM y cuentas de
los grupos cotizados) son seeds transcritos de PDF: transform/seeds/medios_sector_*.csv.
"""

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series

BASE = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"

UE27 = ["AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES", "FI", "FR", "HR", "HU", "IE", "IT",
        "LT", "LU", "LV", "MT", "NL", "PL", "PT", "RO", "SE", "SI", "SK"]

RAMAS = ["J58", "J581", "J5813", "J5814", "J59", "J60", "J601", "J602", "J639", "J6391"]

INDICADORES_ANTIGUOS = {"V11110": "ENT_NR", "V12110": "NETTUR_MEUR", "V12150": "AV_MEUR", "V16110": "EMP_NR"}


def _json(url: str, timeout: int = 180) -> dict:
    resp = requests.get(url, timeout=timeout)
    resp.raise_for_status()
    return resp.json()


def _f(valor):
    # Eurostat mezcla enteros y decimales: float() para que dlt no cree columnas variantes
    return float(valor) if isinstance(valor, (int, float)) else None


def _q(lista, campo):
    return "".join(f"&{campo}={x}" for x in lista)


@dlt.source(name="medios_sector")
def medios_sector():
    @dlt.resource(name="eurostat_medios_sbs", write_disposition="replace")
    def sbs():
        url = (BASE + "sbs_ovw_act?format=JSON&lang=EN" + _q(UE27 + ["EU27_2020"], "geo") + _q(RAMAS, "nace_r2")
               + _q(["ENT_NR", "EMP_NR", "NETTUR_MEUR", "AV_MEUR"], "indic_sbs"))
        for c, v in parse_json_stat_series(_json(url)):
            yield {"anio": int(c["time"]), "pais": c["geo"], "rama": c["nace_r2"], "indicador": c["indic_sbs"],
                   "valor": _f(v)}

    @dlt.resource(name="eurostat_medios_sbs_2008", write_disposition="replace")
    def sbs_2008():
        url = (BASE + "sbs_na_1a_se_r2?format=JSON&lang=EN" + _q(UE27 + ["EU27_2020", "EU28"], "geo")
               + _q(RAMAS, "nace_r2") + _q(INDICADORES_ANTIGUOS, "indic_sb"))
        for c, v in parse_json_stat_series(_json(url)):
            yield {"anio": int(c["time"]), "pais": c["geo"], "rama": c["nace_r2"],
                   "indicador": INDICADORES_ANTIGUOS[c["indic_sb"]], "indicador_original": c["indic_sb"],
                   "valor": _f(v)}

    return [sbs, sbs_2008]
