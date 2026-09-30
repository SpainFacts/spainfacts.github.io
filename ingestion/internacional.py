"""Fuente dlt para comparar España con otros países (tema `internacional`).

Países y agregados: España, Francia, Portugal, Marruecos, Estados Unidos, China,
Alemania, Italia, Unión Europea (27) y OCDE (fijos en la web), más los países de
referencia que solo aparecen en los indicadores donde son un caso emblemático
(mapa PAISES_REFERENCIA en src/lib/paisesReferencia.js): Noruega, Dinamarca,
Suecia, Países Bajos, Grecia, Japón, Corea del Sur e Israel.

1) Banco Mundial, World Development Indicators (API v2, JSON). Trae los agregados
   EUU (Unión Europea) y OED (miembros de la OCDE), que el Banco Mundial pondera
   (población, PIB...) según el indicador: no son medias simples de países.
2) FMI, World Economic Outlook (DataMapper API): deuda bruta de las AAPP en % del
   PIB (GGXWDG_NGDP). El Banco Mundial solo tiene deuda del gobierno central y
   para muy pocos países. El FMI incluye previsiones: se descartan en dbt (solo
   años cerrados). El agregado 'EU' del FMI se guarda como EUU; no hay OCDE.
3) Our World in Data: cuota renovable de la electricidad (Ember; el Banco Mundial
   la dejó en 2021) y llegadas de turistas internacionales (ONU Turismo; el Banco
   Mundial la dejó en 2020).
4) Eurostat (países europeos y UE-27): tasa de riesgo de pobreza (ilc_li02,
   60 % de la mediana), población de 25 a 64 años con estudios terciarios
   (edat_lfse_03, CINE 5-8) y, del balance energético (nrg_bal_c), el consumo
   final de energía (uso energético, FC_E) total y de electricidad (E7000),
   con los que dbt calcula el peso de la electricidad en el consumo final
   (misma definición que el mart electrificacion_sectores).
5) AIE, Global EV Data Explorer (API CSV, CC BY 4.0): cuota de los coches
   eléctricos (de batería + híbridos enchufables) en las ventas de turismos
   nuevos. Sin OCDE ni Marruecos.
6) OCDE, Affordable Housing Database, indicador PH4.2: viviendas sociales en
   alquiler en % del parque total (hacia 2010 y hacia 2022, con medias UE y
   OCDE). Se lee con ingestion/vivienda_publica.py (ocde_filas) y se añaden
   Austria y Reino Unido (Inglaterra), referentes de vivienda social.

Recursos (replace): internacional_banco_mundial, internacional_fmi,
internacional_owid, internacional_eurostat, internacional_aie,
internacional_ocde_vivienda.
"""

import csv
import io
import logging
import time

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series

log = logging.getLogger(__name__)

PAISES_FIJOS = ["ESP", "FRA", "PRT", "MAR", "USA", "CHN", "EUU", "OED", "DEU", "ITA"]
# Países de referencia (ver src/lib/paisesReferencia.js para el porqué de cada uno)
PAISES_REFERENCIA = ["NOR", "DNK", "SWE", "NLD", "GRC", "JPN", "KOR", "ISR"]
PAISES_BM = PAISES_FIJOS + PAISES_REFERENCIA
# Solo en vivienda social (OCDE PH4.2): Austria y Reino Unido, los referentes clásicos
PAISES_SOLO_VIVIENDA = ["AUT", "GBR"]

# código WDI -> indicador_id (el catálogo con nombre, unidad y sentido está en dbt)
INDICADORES_BM = {
    "NY.GDP.PCAP.PP.KD": "pib_pc_ppa",
    "NY.GDP.MKTP.KD.ZG": "crecimiento_pib",
    "SL.UEM.TOTL.ZS": "paro",
    "SL.UEM.1524.ZS": "paro_juvenil",
    "SL.EMP.TOTL.SP.ZS": "tasa_empleo",
    "SL.TLF.CACT.FE.ZS": "actividad_femenina",
    "FP.CPI.TOTL.ZG": "inflacion",
    "NE.EXP.GNFS.ZS": "exportaciones_pib",
    "SP.POP.TOTL": "poblacion",
    "SP.DYN.LE00.IN": "esperanza_vida",
    "SP.DYN.TFRT.IN": "fecundidad",
    "SP.DYN.IMRT.IN": "mortalidad_infantil",
    "SP.POP.65UP.TO.ZS": "poblacion_65",
    "SP.POP.GROW": "crecimiento_poblacion",
    "SM.POP.TOTL.ZS": "migrantes",
    "EN.GHG.ALL.PC.CE.AR5": "gei_pc",
    "EN.GHG.CO2.PC.CE.AR5": "co2_pc",
    "EG.USE.ELEC.KH.PC": "consumo_electrico_pc",
    "VC.IHR.PSRC.P5": "homicidios",
    "SH.STA.SUIC.P5": "suicidios",
    "SH.XPD.CHEX.PP.CD": "gasto_sanitario_pc_ppa",
    "SH.XPD.CHEX.GD.ZS": "gasto_sanitario_pib",
    "SH.MED.PHYS.ZS": "medicos",
    "SH.MED.BEDS.ZS": "camas",
    "SE.XPD.TOTL.GD.ZS": "gasto_educacion_pib",
    "SE.TER.CUAT.ST.ZS": "estudios_terciarios_25mas",
    "GB.XPD.RSDV.GD.ZS": "id_pib",
    "SI.POV.GINI": "gini",
    "IT.NET.USER.ZS": "internet",
}

BM_URL = "https://api.worldbank.org/v2/country/{paises}/indicator/{cod}?format=json&per_page=20000&date=1990:2030"

FMI_URL = "https://www.imf.org/external/datamapper/api/v1/GGXWDG_NGDP/" + "/".join(
    [c for c in PAISES_BM if c not in ("EUU", "OED")] + ["EU"])
FMI_PAISES = {"EU": "EUU"}

OWID_URL = "https://ourworldindata.org/grapher/{}.csv?v=1&csvType=full&useColumnShortNames=true"
OWID_SERIES = {
    # indicador_id: (gráfico OWID, columna)
    "electricidad_renovable": ("share-electricity-renewables", "renewable_share_of_electricity__pct"),
    "turistas_llegadas": ("international-tourist-trips", "in_tour_arrivals_trips_total_overnight_vis_tourists"),
}
OWID_AGREGADOS = {"European Union (27)": "EUU", "OECD (Ember)": "OED"}

EUROSTAT_URL = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
EUROSTAT_GEO = {"ES": "ESP", "FR": "FRA", "PT": "PRT", "DE": "DEU", "IT": "ITA", "EU27_2020": "EUU",
                # Grecia es EL (no GR) en Eurostat; Noruega está en EU-SILC, LFS y balances
                "NO": "NOR", "DK": "DNK", "SE": "SWE", "NL": "NLD", "EL": "GRC"}
EUROSTAT_CONSULTAS = {
    "riesgo_pobreza": "ilc_li02?age=TOTAL&sex=T&unit=PC&rskpovth=B_60&statinfo=MED_EI",
    "estudios_terciarios": "edat_lfse_03?age=Y25-64&sex=T&isced11=ED5-8&unit=PC",
    # consumo final de energía (uso energético) total y de electricidad, en ktep:
    # el cociente (electrificacion) se calcula en dbt
    "consumo_final_energia": "nrg_bal_c?nrg_bal=FC_E&siec=TOTAL&unit=KTOE",
    "consumo_final_electricidad": "nrg_bal_c?nrg_bal=FC_E&siec=E7000&unit=KTOE",
}

# AIE Global EV Data Explorer: la API devuelve todos los parámetros de una región
AIE_URL = "https://api.iea.org/evs?parameters=EV%20sales%20share&category=Historical&mode=Cars&csv=true&region={}"
AIE_REGIONES = {
    "Spain": "ESP", "France": "FRA", "Portugal": "PRT", "Germany": "DEU", "Italy": "ITA",
    "USA": "USA", "China": "CHN", "European Union": "EUU", "Norway": "NOR", "Denmark": "DNK",
    "Sweden": "SWE", "Netherlands": "NLD", "Greece": "GRC", "Japan": "JPN", "Korea": "KOR",
    "Israel": "ISR",
}

CABECERAS = {"User-Agent": "SpainFacts (https://spainfacts.github.io)"}


def _get(url: str, intentos: int = 4, **kw) -> requests.Response:
    for i in range(intentos):
        try:
            r = requests.get(url, timeout=180, headers=CABECERAS, **kw)
            r.raise_for_status()
            return r
        except requests.RequestException as e:
            if i == intentos - 1:
                raise
            log.warning("Reintento %s de %s: %s", i + 1, url, e)
            time.sleep(5 * (i + 1))


@dlt.source(name="internacional")
def internacional():
    @dlt.resource(name="internacional_banco_mundial", write_disposition="replace")
    def banco_mundial():
        for cod, indicador_id in INDICADORES_BM.items():
            datos = _get(BM_URL.format(paises=";".join(PAISES_BM), cod=cod)).json()
            if len(datos) < 2 or not datos[1]:
                raise ValueError(f"Banco Mundial sin datos para {cod}: {datos[0]}")
            filas = [{
                "indicador_id": indicador_id,
                "cod_indicador": cod,
                "nombre_fuente": d["indicator"]["value"],
                "cod_pais": d["countryiso3code"] or d["country"]["id"],
                "anio": int(d["date"]),
                "valor": float(d["value"]),
            } for d in datos[1] if d["value"] is not None]
            log.info("Banco Mundial %s: %s filas", cod, len(filas))
            yield filas

    @dlt.resource(name="internacional_fmi", write_disposition="replace")
    def fmi():
        valores = _get(FMI_URL).json()["values"]["GGXWDG_NGDP"]
        # la API devuelve todos los países aunque se pidan unos pocos: se filtran aquí
        for pais, serie in valores.items():
            if FMI_PAISES.get(pais, pais) not in PAISES_BM:
                continue
            for anio, valor in serie.items():
                if valor is None:
                    continue
                yield {"indicador_id": "deuda_publica", "cod_indicador": "GGXWDG_NGDP",
                       "cod_pais": FMI_PAISES.get(pais, pais), "anio": int(anio), "valor": float(valor)}

    @dlt.resource(name="internacional_owid", write_disposition="replace")
    def owid():
        for indicador_id, (grafico, columna) in OWID_SERIES.items():
            texto = _get(OWID_URL.format(grafico)).text
            for fila in csv.DictReader(io.StringIO(texto)):
                cod = OWID_AGREGADOS.get(fila["entity"]) or fila["code"]
                if cod not in PAISES_BM or not fila.get(columna):
                    continue
                yield {"indicador_id": indicador_id, "cod_indicador": grafico, "cod_pais": cod,
                       "entidad": fila["entity"], "anio": int(fila["year"]), "valor": float(fila[columna])}

    @dlt.resource(name="internacional_eurostat", write_disposition="replace")
    def eurostat():
        geos = "".join(f"&geo={g}" for g in EUROSTAT_GEO)
        for indicador_id, consulta in EUROSTAT_CONSULTAS.items():
            datos = _get(EUROSTAT_URL + consulta + geos + "&format=JSON&lang=EN").json()
            for coords, valor in parse_json_stat_series(datos):
                if valor is None:
                    continue
                yield {"indicador_id": indicador_id, "cod_indicador": consulta.split("?")[0],
                       "cod_pais": EUROSTAT_GEO[coords["geo"]], "anio": int(coords["time"]),
                       "valor": float(valor)}

    @dlt.resource(name="internacional_aie", write_disposition="replace")
    def aie():
        for region, cod in AIE_REGIONES.items():
            texto = _get(AIE_URL.format(requests.utils.quote(region))).text
            filas = [f for f in csv.DictReader(io.StringIO(texto))
                     if f["parameter"] == "EV sales share" and f["mode"] == "Cars"
                     and f["powertrain"] == "EV" and f["category"] == "Historical" and f["value"]]
            if not filas:
                raise ValueError(f"AIE sin cuota de ventas de eléctricos para {region}")
            for f in filas:
                yield {"indicador_id": "coche_electrico_cuota", "cod_indicador": "EV sales share (Cars, EV)",
                       "cod_pais": cod, "anio": int(f["year"]), "valor": float(f["value"])}

    @dlt.resource(name="internacional_ocde_vivienda", write_disposition="replace")
    def ocde_vivienda():
        from ingestion.vivienda_publica import ocde_filas

        paises = set(PAISES_BM) | set(PAISES_SOLO_VIVIENDA)
        for f in ocde_filas():
            if f["cod_pais"] in paises:
                yield {"indicador_id": "vivienda_social_pct", "cod_indicador": "PH4.2",
                       "cod_pais": f["cod_pais"], "anio": f["anio"], "valor": f["pct_parque"]}

    return [banco_mundial, fmi, owid, eurostat, aie, ocde_vivienda]


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("internacional").run(internacional()))
