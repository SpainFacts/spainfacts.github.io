"""Fuente dlt del tema `empresas`: tejido empresarial, dinámica empresarial,
autónomos e I+D.

1) INE (API JSON Tempus3, con metadatos `tip=M` para tener los códigos
   oficiales de territorio y de cada dimensión):
     39372  DIRCE: empresas activas a 1 de enero por comunidad, actividad
            principal (CNAE 2009) y estrato de asalariados (desde 2020). La
            tabla completa tiene ~87.000 series, así que se piden dos cortes:
              ine_dirce_estrato   comunidad x estrato (Total CNAE)
              ine_dirce_actividad comunidad x división CNAE (todos los
                                  estratos); solo divisiones de 2 dígitos
     302    DIRCE: empresas por provincia y condición jurídica (desde 1999)
            -> ine_dirce_provincias (serie larga para la evolución)
     13912  Sociedades mercantiles constituidas, disueltas, que amplían o
            reducen capital, número y capital (miles de euros), mensual por
            comunidad desde 1995 -> ine_sm_sociedades
     2992   Estadística del Procedimiento Concursal: deudores concursados por
            comunidad y provincia y tipo de concurso, anual 2004-2020 (el INE
            dejó de publicarla con los datos de 2020) -> ine_epc_deudores
     65316  EPA: ocupados por situación profesional, sexo y comunidad (miles,
            trimestral desde 2002) -> ine_epa_situacion

2) Eurostat:
     rd_e_gerdtot  gasto interno en I+D por sector ejecutor, % del PIB, euros por
                   habitante y millones, todos los países -> eurostat_empresas_gerd
     rd_e_gerdreg  lo mismo para España y sus regiones NUTS 2
                   -> eurostat_empresas_gerd_regiones
     rd_p_perslf / rd_p_persreg  investigadores (EJC y personas) en % del empleo,
                   países y regiones NUTS 2 de España -> eurostat_empresas_investigadores
     sbs_sc_ovw    estadística estructural de empresas por tamaño (empresas,
                   personas ocupadas, valor añadido), economía de mercado sin
                   financieras (B-S sin O ni S94), desde 2021 -> eurostat_empresas_tamano
     sts_rb_q      índices trimestrales de altas de empresas y declaraciones de
                   quiebra (2021=100, desestacionalizados) -> eurostat_empresas_altas_quiebras

Recursos (replace): los nombrados arriba.
"""

import logging
import re

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series

log = logging.getLogger(__name__)

INE = "https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/"
EUROSTAT = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
NUTS2_ES = [
    "ES", "ES11", "ES12", "ES13", "ES21", "ES22", "ES23", "ES24", "ES30", "ES41", "ES42",
    "ES43", "ES51", "ES52", "ES53", "ES61", "ES62", "ES63", "ES64", "ES70",
]
PAISES_SBS = ["EU27_2020", "ES", "DE", "FR", "IT", "PT", "NL", "PL", "SE", "AT", "BE"]
PAISES_STS = ["EU27_2020", "ES", "DE", "FR", "IT", "PT", "NL"]

# Variables INE (FK_Variable) que identifican el territorio: 349 nacional,
# 70 comunidad autónoma, 115 provincia.
VAR_TERRITORIO = {349: "pais", 70: "ccaa", 115: "provincia"}


def _ine_filas(tabla_id: str, filtros: str = "", filtro_serie=None):
    """Filas planas de una tabla Tempus con sus metadatos.

    Cada fila lleva nivel/cod_territorio y, para cada variable de la tabla que no
    sea territorio, columnas v<id> (nombre) y v<id>_cod (código INE).
    """
    url = f"{INE}{tabla_id}?tip=M" + (f"&{filtros}" if filtros else "")
    respuesta = requests.get(url, timeout=600)
    respuesta.raise_for_status()
    for serie in respuesta.json():
        meta = serie.get("MetaData") or []
        base = {"cod_serie": serie.get("COD"), "serie": (serie.get("Nombre") or "").strip()}
        for m in meta:
            var = m.get("FK_Variable")
            if var in VAR_TERRITORIO:
                base["nivel"] = VAR_TERRITORIO[var]
                base["cod_territorio"] = m.get("Codigo")
                base["territorio"] = m.get("Nombre")
            else:
                base[f"v{var}"] = m.get("Nombre")
                base[f"v{var}_cod"] = m.get("Codigo")
        if filtro_serie and not filtro_serie(base):
            continue
        for punto in serie.get("Data", []):
            yield {
                **base,
                "fecha": punto.get("Fecha"),  # epoch en milisegundos
                "anyo": punto.get("Anyo"),
                "fk_periodo": punto.get("FK_Periodo"),
                "valor": punto.get("Valor"),
                "secreto": punto.get("Secreto"),
            }


def _eurostat(dataset: str, **params):
    respuesta = requests.get(
        EUROSTAT + dataset, params={**params, "format": "JSON", "lang": "EN"}, timeout=600
    )
    respuesta.raise_for_status()
    for coords, valor in parse_json_stat_series(respuesta.json()):
        if valor is None:
            continue
        fila = {k: v for k, v in coords.items() if k != "freq"}
        fila["periodo"] = fila.pop("time")
        fila["valor"] = float(valor)
        fila["dataset"] = dataset
        yield fila


@dlt.source(name="empresas")
def empresas():
    @dlt.resource(name="ine_dirce_estrato", write_disposition="replace")
    def dirce_estrato():
        # Total CNAE (valor 23092 de la variable 393) x comunidad x estrato
        yield from _ine_filas("39372", "tv=393:23092")

    @dlt.resource(name="ine_dirce_actividad", write_disposition="replace")
    def dirce_actividad():
        # Todos los estratos (valor 15723 de la variable 336) x comunidad x CNAE;
        # el total va en la variable 393 ('AAA') y las actividades en la 338; los
        # códigos de división acaban en 'X' (p. ej. 'BAX' = 10 Alimentación) y el
        # número de división CNAE solo aparece en el nombre de la serie ("... 10 Industria ...")
        def es_division(fila):
            if fila.get("v393_cod") == "AAA":
                fila["cnae_div"] = "00"
                return True
            cod = fila.get("v338_cod") or ""
            if not cod.endswith("X"):
                return False
            m = re.search(r"(?:^|\. )(\d{2}) ", fila["serie"])
            fila["cnae_div"] = m.group(1) if m else None
            return True

        yield from _ine_filas("39372", "tv=336:15723", es_division)

    @dlt.resource(name="ine_dirce_provincias", write_disposition="replace")
    def dirce_provincias():
        yield from _ine_filas("302")

    @dlt.resource(name="ine_sm_sociedades", write_disposition="replace")
    def sm_sociedades():
        yield from _ine_filas("13912")

    @dlt.resource(name="ine_epc_deudores", write_disposition="replace")
    def epc_deudores():
        yield from _ine_filas("2992")

    @dlt.resource(name="ine_epa_situacion", write_disposition="replace")
    def epa_situacion():
        yield from _ine_filas("65316")

    @dlt.resource(name="eurostat_empresas_gerd", write_disposition="replace")
    def gerd():
        yield from _eurostat(
            "rd_e_gerdtot", unit=["PC_GDP", "EUR_HAB", "MIO_EUR"], sinceTimePeriod="1995"
        )

    @dlt.resource(name="eurostat_empresas_gerd_regiones", write_disposition="replace")
    def gerd_regiones():
        yield from _eurostat(
            "rd_e_gerdreg", geo=NUTS2_ES, unit=["PC_GDP", "EUR_HAB", "MIO_EUR"],
            sinceTimePeriod="1995",
        )

    @dlt.resource(name="eurostat_empresas_investigadores", write_disposition="replace")
    def investigadores():
        yield from _eurostat(
            "rd_p_perslf", prof_pos="RSE", sex="T", unit=["PC_EMP_FTE", "PC_EMP_HC"],
            sinceTimePeriod="1995",
        )
        yield from _eurostat(
            "rd_p_persreg", geo=NUTS2_ES, prof_pos="RSE", sex="T",
            unit=["PC_EMP_FTE", "PC_EMP_HC", "FTE"], sinceTimePeriod="1995",
        )

    @dlt.resource(name="eurostat_empresas_tamano", write_disposition="replace")
    def tamano():
        yield from _eurostat(
            "sbs_sc_ovw", geo=PAISES_SBS, nace_r2="B-S_X_O_S94",
            indic_sbs=["ENT_NR", "EMP_NR", "AV_MEUR"],
        )

    @dlt.resource(name="eurostat_empresas_altas_quiebras", write_disposition="replace")
    def altas_quiebras():
        yield from _eurostat(
            "sts_rb_q", geo=PAISES_STS, nace_r2="B-S_X_O_S94", unit="I21", s_adj="SCA",
            indic_bt=["BKRT", "REG"],
        )

    return (
        dirce_estrato, dirce_actividad, dirce_provincias, sm_sociedades, epc_deudores,
        epa_situacion, gerd, gerd_regiones, investigadores, tamano, altas_quiebras,
    )


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("empresas").run(empresas()))
