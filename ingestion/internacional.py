"""Fuente dlt para comparar España con el resto del mundo y de Europa (tema `internacional`).

Todos los países del mundo (las páginas España en el mundo y España en Europa los pintan en
mapas) más los agregados Mundo (WLD), Unión Europea (EUU), zona euro (EMU) y OCDE (OED). Las
tarjetas de comparación de cada página temática (componente Comparativa) usan solo unos
pocos: España, Francia, Portugal, Marruecos, Estados Unidos, China, Alemania, Italia, UE y
OCDE, más los países de referencia de src/lib/paisesReferencia.js. El catálogo de
indicadores (nombre, unidad, apartado, sentido y fuente) es el seed internacional_indicadores.

1) Banco Mundial, World Development Indicators (API v2, JSON): todos los países y los
   agregados WLD, EUU, EMU y OED, que el Banco Mundial pondera (población, PIB...) según el
   indicador: no son medias simples de países.
2) FMI, World Economic Outlook (DataMapper API): deuda bruta (GGXWDG_NGDP) y saldo
   (GGXCNL_NGDP) de las AAPP en % del PIB. Incluye previsiones: se descartan en dbt (solo
   años cerrados). El agregado 'EU' del FMI se guarda como EUU; no hay OCDE.
3) Our World in Data: cuota renovable de la electricidad (Ember), llegadas de turistas
   internacionales (ONU Turismo), satisfacción con la vida (escalera de Cantril, World
   Happiness Report) e índice de desarrollo humano (PNUD).
4) Eurostat: unos 70 indicadores de todos los países que publica (UE, AELC y candidatos) y
   la UE-27, con el código geo de Eurostat (EL = Grecia, UK = Reino Unido), que dbt traduce
   con el seed paises_iso. Las series semestrales (precio de la luz, salario mínimo) llevan
   `periodo` (2024-S1) y dbt hace la media de los años con los dos semestres.
   También la cuota de los coches eléctricos (de batería + híbridos enchufables) en las
   ventas de turismos nuevos, de la AIE (Global EV Outlook); la API de la AIE dejó de
   responder en 2026.
5) OCDE, Affordable Housing Database, indicador PH4.2: viviendas sociales en alquiler en %
   del parque total (hacia 2010 y hacia 2022, con medias UE y OCDE). Se lee con
   ingestion/vivienda_publica.py (ocde_filas) y se añaden Austria y Reino Unido
   (Inglaterra), referentes de vivienda social.

Recursos (replace): internacional_banco_mundial, internacional_fmi,
internacional_owid, internacional_eurostat, internacional_ocde_vivienda.
"""

import csv
import io
import logging
import time

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series

log = logging.getLogger(__name__)

# Países de la comparativa de las páginas temáticas (la vivienda social de la OCDE solo trae estos)
PAISES_FIJOS = ["ESP", "FRA", "PRT", "MAR", "USA", "CHN", "EUU", "OED", "DEU", "ITA"]
# Países de referencia (ver src/lib/paisesReferencia.js para el porqué de cada uno)
PAISES_REFERENCIA = ["NOR", "DNK", "SWE", "NLD", "GRC", "JPN", "KOR", "ISR"]
PAISES_BM = PAISES_FIJOS + PAISES_REFERENCIA
# Solo en vivienda social (OCDE PH4.2): Austria y Reino Unido, los referentes clásicos
PAISES_SOLO_VIVIENDA = ["AUT", "GBR"]
# Agregados del Banco Mundial que se guardan (las regiones y los grupos de renta, no)
AGREGADOS_BM = {"WLD", "EUU", "EMU", "OED"}

# código WDI -> indicador_id (el catálogo con nombre, unidad y sentido es un seed de dbt)
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
    # solo en España en el mundo
    "SP.URB.TOTL.IN.ZS": "urbanizacion",
    "EN.POP.DNST": "densidad",
    "SP.POP.0014.TO.ZS": "poblacion_0_14",
    "SP.DYN.CBRT.IN": "natalidad",
    "SH.DYN.MORT": "mortalidad_menores_5",
    "SH.XPD.OOPC.CH.ZS": "gasto_sanitario_bolsillo",
    "SH.STA.TRAF.P5": "muertes_trafico",
    "SI.POV.DDAY": "pobreza_extrema",
    "SG.GEN.PARL.ZS": "mujeres_parlamento",
    "MS.MIL.XPND.GD.ZS": "gasto_militar_pib",
    "NE.GDI.TOTL.ZS": "inversion_pib",
    "BX.KLT.DINV.WD.GD.ZS": "ied_pib",
    "NV.IND.MANF.ZS": "manufactura_pib",
    "SL.AGR.EMPL.ZS": "empleo_agricultura",
    "SL.IND.EMPL.ZS": "empleo_industria",
    "AG.LND.FRST.ZS": "bosques",
    "EG.FEC.RNEW.ZS": "energia_renovable",
    "EN.ATM.PM25.MC.M3": "pm25",
    "ER.H2O.FWST.ZS": "estres_hidrico",
}

BM_URL = "https://api.worldbank.org/v2/country/all/indicator/{cod}?format=json&per_page=20000&date=1990:2030"
BM_PAISES_URL = "https://api.worldbank.org/v2/country?format=json&per_page=400"

# La API del FMI devuelve todos los países (ISO3) y grupos con códigos propios: dbt se queda
# con los del seed paises_iso
FMI_URL = "https://www.imf.org/external/datamapper/api/v1/{}"
FMI_INDICADORES = {"GGXWDG_NGDP": "deuda_publica", "GGXCNL_NGDP": "saldo_publico"}
FMI_PAISES = {"EU": "EUU"}

OWID_URL = "https://ourworldindata.org/grapher/{}.csv?v=1&csvType=full&useColumnShortNames=true"
OWID_SERIES = {
    # indicador_id: (gráfico OWID, columna)
    "electricidad_renovable": ("share-electricity-renewables", "renewable_share_of_electricity__pct"),
    "turistas_llegadas": ("international-tourist-trips", "in_tour_arrivals_trips_total_overnight_vis_tourists"),
    "satisfaccion_vida": ("happiness-cantril-ladder", "cantril_ladder_score"),
    "idh": ("human-development-index", "hdi__sex_total"),
    "coche_electrico_cuota": ("electric-car-sales-share", "ev_sales_share"),
}
OWID_AGREGADOS = {"European Union (27)": "EUU", "OECD (Ember)": "OED", "World": "WLD"}

EUROSTAT_URL = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
# indicador_id -> consulta (dataset?filtros). Sin filtro geo: llegan todos los países y
# agregados que publica Eurostat; dbt se queda con los del seed paises_iso y la UE-27.
# Los que acaban en _aux sirven para calcular otros en dbt y no se publican.
EUROSTAT_CONSULTAS = {
    # Economía
    "pib_pc_indice_ue": "prc_ppp_ind?na_item=VI_PPS_EU27_2020_HAB&ppp_cat=GDP",
    "consumo_pc_indice_ue": "prc_ppp_ind?na_item=VI_PPS_EU27_2020_HAB&ppp_cat=A01",
    "nivel_precios": "prc_ppp_ind?na_item=PLI_EU27_2020&ppp_cat=A01",
    "crecimiento_pib": "nama_10_gdp?na_item=B1GQ&unit=CLV_PCH_PRE",
    "productividad_hora": "tesem160?na_item=NLPR_HW",
    "inflacion": "prc_hicp_aind?coicop=CP00&unit=RCH_A_AVG",
    "exportaciones_pib": "nama_10_gdp?na_item=P6&unit=PC_GDP",
    "inversion_pib": "nama_10_gdp?na_item=P51G&unit=PC_GDP",
    "industria_vab": "nama_10_a10?nace_r2=B-E&na_item=B1G&unit=PC_TOT",
    "id_pib": "rd_e_gerdtot?sectperf=TOTAL&unit=PC_GDP",
    "ahorro_hogares": "tec00131",
    "deuda_hogares": "tipspd22?unit=PC_GDP",
    "cuenta_corriente": "tipsbp10?partner=WRL_REST",
    "pernoctaciones_aux": "tin00175?c_resid=TOTAL",
    # Cuentas públicas
    "deuda_publica": "gov_10dd_edpt1?na_item=GD&sector=S13&unit=PC_GDP",
    "saldo_publico": "gov_10dd_edpt1?na_item=B9&sector=S13&unit=PC_GDP",
    "gasto_publico": "gov_10a_main?na_item=TE&sector=S13&unit=PC_GDP",
    "ingresos_publicos": "gov_10a_main?na_item=TR&sector=S13&unit=PC_GDP",
    "presion_fiscal": "gov_10a_taxag?na_item=D2_D5_D91_D61_M_D995&sector=S13_S212&unit=PC_GDP",
    "gasto_sanidad_publico": "gov_10a_exp?cofog99=GF07&na_item=TE&sector=S13&unit=PC_GDP",
    "gasto_educacion_publico": "gov_10a_exp?cofog99=GF09&na_item=TE&sector=S13&unit=PC_GDP",
    "gasto_proteccion_social": "gov_10a_exp?cofog99=GF10&na_item=TE&sector=S13&unit=PC_GDP",
    "gasto_defensa": "gov_10a_exp?cofog99=GF02&na_item=TE&sector=S13&unit=PC_GDP",
    # Empleo
    "paro": "une_rt_a?age=Y15-74&sex=T&unit=PC_ACT",
    "paro_juvenil": "une_rt_a?age=Y15-24&sex=T&unit=PC_ACT",
    "paro_larga_duracion": "une_ltu_a?age=Y15-74&sex=T&unit=PC_ACT&indic_em=LTU",
    "tasa_empleo": "lfsi_emp_a?indic_em=EMP_LFS&age=Y20-64&sex=T&unit=PC_POP",
    "tasa_empleo_mujeres": "lfsi_emp_a?indic_em=EMP_LFS&age=Y20-64&sex=F&unit=PC_POP",
    "temporalidad": "tps00073?age=Y15-64&sex=T",
    "parcialidad": "lfsa_eppga?age=Y15-74&sex=T&unit=PC",
    "nini": "edat_lfse_20?age=Y15-29&sex=T&wstatus=NEMP&unit=PC",
    "salario_minimo_pps": "earn_mw_cur?currency=PPS",
    # Desigualdad
    "riesgo_pobreza": "ilc_li02?age=TOTAL&sex=T&unit=PC&rskpovth=B_60&statinfo=MED_EI",
    "pobreza_infantil": "ilc_li02?age=Y_LT18&sex=T&unit=PC&rskpovth=B_60&statinfo=MED_EI",
    "arope": "ilc_peps01n?age=TOTAL&sex=T&unit=PC",
    "privacion_severa": "ilc_mdsd11?age=TOTAL&sex=T&unit=PC",
    "gini": "ilc_di12?age=TOTAL&statinfo=GINI_HND",
    "s80s20": "ilc_di11?age=TOTAL&sex=T&unit=RAT",
    "renta_mediana_pps": "ilc_di03?age=TOTAL&sex=T&statinfo=MED_EI&unit=PPS",
    # Educación
    "estudios_terciarios": "edat_lfse_03?age=Y25-64&sex=T&isced11=ED5-8&unit=PC",
    "terciarios_25_34": "edat_lfse_03?age=Y25-34&sex=T&isced11=ED5-8&unit=PC",
    "estudios_basicos": "edat_lfse_03?age=Y25-64&sex=T&isced11=ED0-2&unit=PC",
    "abandono_escolar": "edat_lfse_14?age=Y18-24&sex=T&wstatus=POP&unit=PC",
    "aprendizaje_adultos": "trng_lfse_01?age=Y25-64&sex=T&unit=PC",
    "competencias_digitales": "isoc_sk_dskl_i21?indic_is=I_DSK2_BAB&ind_type=IND_TOTAL&unit=PC_IND",
    "internet": "isoc_ci_ifp_iu?indic_is=I_ILT12&ind_type=IND_TOTAL&unit=PC_IND",
    # Población
    "fecundidad": "demo_find?indic_de=TOTFERRT",
    "edad_madre": "demo_find?indic_de=AGEMOTH",
    "edad_mediana": "demo_pjanind?indic_de=MEDAGEPOP",
    "dependencia_mayores": "demo_pjanind?indic_de=OLDDEP1",
    "migracion_neta": "demo_gind?indic_de=CNMIGRATRT",
    "poblacion_media_aux": "demo_gind?indic_de=AVG",
    "nacidos_fuera_aux": "migr_pop3ctb?age=TOTAL&sex=T&c_birth=FOR&unit=NR",
    "nacidos_total_aux": "migr_pop3ctb?age=TOTAL&sex=T&c_birth=TOTAL&unit=NR",
    "emancipacion": "yth_demo_030?sex=T",
    "densidad": "demo_r_d3dens?unit=PER_KM2",
    # Salud
    "esperanza_vida": "demo_mlexpec?age=Y_LT1&sex=T&unit=YR",
    "vida_saludable": "hlth_hlye?unit=YR&sex=T&hlth_hle=HLY_Y0",
    "suicidios": "hlth_cd_asdr2?icd10=X60-X84_Y870&sex=T&unit=RT&age=TOTAL",
    "obesidad": "sdg_02_10?unit=PC&bmi=BMI_GE30",
    "fumadores": "sdg_03_30?age=Y_GE15&sex=T&unit=PC_POP",
    "camas": "hlth_rs_bds1?unit=P_HTHAB&facility=HBEDT&hlthcare=TOTAL",
    "gasto_sanitario_pib": "hlth_sha11_hf?icha11_hf=TOT_HF&unit=PC_GDP",
    "gasto_sanitario_pps_hab": "hlth_sha11_hf?icha11_hf=TOT_HF&unit=PPS_HAB",
    # Vivienda
    "propiedad_vivienda": "ilc_lvho02?rskpovth=TOTAL&hhcomp=TOTAL&tenure=OWN&unit=PC",
    "sobrecarga_vivienda": "ilc_lvho07a?unit=PC&rskpovth=TOTAL&age=TOTAL&sex=T",
    "hacinamiento": "ilc_lvho05a?unit=PC&rskpovth=TOTAL&age=TOTAL&sex=T",
    "precio_vivienda_var": "prc_hpi_a?purchase=TOTAL&unit=RCH_A_AVG",
    # Energía, clima y medio ambiente
    "gei_pc": "sdg_13_10?src_crf=TOTX4_MEMO&unit=T_HAB",
    "energia_renovable": "nrg_ind_ren?nrg_bal=REN&unit=PC",
    "dependencia_energetica": "nrg_ind_id?siec=TOTAL&unit=PC",
    "precio_luz_pps": "nrg_pc_204?siec=E7000&nrg_cons=KWH2500-4999&unit=KWH&tax=I_TAX&currency=PPS",
    # consumo final de energía (uso energético) total y de electricidad, en ktep:
    # el cociente (electrificacion) se calcula en dbt
    "consumo_final_energia": "nrg_bal_c?nrg_bal=FC_E&siec=TOTAL&unit=KTOE",
    "consumo_final_electricidad": "nrg_bal_c?nrg_bal=FC_E&siec=E7000&unit=KTOE",
    # lo mismo solo en el transporte (electrificacion_transporte en dbt)
    "consumo_transporte_energia_aux": "nrg_bal_c?nrg_bal=FC_TRA_E&siec=TOTAL&unit=KTOE",
    "consumo_transporte_electricidad_aux": "nrg_bal_c?nrg_bal=FC_TRA_E&siec=E7000&unit=KTOE",
    "residuos_hab": "env_wasmun?wst_oper=GEN&unit=KG_HAB",
    "reciclaje": "cei_wm011?wst_oper=RCY&unit=PC",
    # Movilidad y seguridad
    "coches_1000": "road_eqs_carhab",
    # reparto modal del transporte terrestre: % de viajeros-km en tren (frente a coche y
    # autobús; sin metro ni tranvía) y % de toneladas-km en tren (frente a carretera y
    # vías navegables)
    "tren_viajeros_pct": "tran_hv_psmod?vehicle=TRN&unit=PC",
    "tren_mercancias_pct": "tran_hv_frmod?tra_mode=RAIL&unit=PC",
    # pasajeros de avión del país (llegadas + salidas); por habitante en dbt
    "pasajeros_avion_aux": "ttr00012?unit=PAS&tra_meas=PAS_CRD&tra_cov=TOTAL&schedule=TOTAL",
    # km de autopistas del país; por 100.000 habitantes en dbt
    "autopistas_km_aux": "road_if_motorwa?unit=KM&tra_infr=MWAY",
    "muertes_trafico": "sdg_11_40?tra_infr=TOTAL&unit=RT",
    "homicidios": "crim_off_cat?iccs=ICCS0101&unit=P_HTHAB",
    # Política
    "mujeres_parlamento": "sdg_05_50?org_inst=PARL_NAT&sex=F&unit=PC_WMN",
}
EUROSTAT_DESDE = 1990

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
        # países (no las regiones ni los grupos de renta) y los agregados que se usan
        meta = _get(BM_PAISES_URL).json()[1]
        validos = {m["id"] for m in meta if m["region"]["value"].strip() != "Aggregates"} | AGREGADOS_BM
        for cod, indicador_id in INDICADORES_BM.items():
            datos = _get(BM_URL.format(cod=cod)).json()
            if len(datos) < 2 or not datos[1]:
                raise ValueError(f"Banco Mundial sin datos para {cod}: {datos[0]}")
            filas = [{
                "indicador_id": indicador_id,
                "cod_indicador": cod,
                "nombre_fuente": d["indicator"]["value"],
                "cod_pais": d["countryiso3code"] or d["country"]["id"],
                "anio": int(d["date"]),
                "valor": float(d["value"]),
            } for d in datos[1] if d["value"] is not None
                and (d["countryiso3code"] or d["country"]["id"]) in validos]
            log.info("Banco Mundial %s: %s filas", cod, len(filas))
            yield filas

    @dlt.resource(name="internacional_fmi", write_disposition="replace")
    def fmi():
        for cod, indicador_id in FMI_INDICADORES.items():
            valores = _get(FMI_URL.format(cod)).json()["values"][cod]
            for pais, serie in valores.items():
                for anio, valor in serie.items():
                    if valor is None:
                        continue
                    yield {"indicador_id": indicador_id, "cod_indicador": cod,
                           "cod_pais": FMI_PAISES.get(pais, pais), "anio": int(anio), "valor": float(valor)}

    @dlt.resource(name="internacional_owid", write_disposition="replace")
    def owid():
        for indicador_id, (grafico, columna) in OWID_SERIES.items():
            texto = _get(OWID_URL.format(grafico)).text
            for fila in csv.DictReader(io.StringIO(texto)):
                cod = OWID_AGREGADOS.get(fila["entity"]) or fila["code"]
                # países (ISO3) y los agregados de OWID_AGREGADOS; fuera OWID_* y regiones
                if not cod or cod.startswith("OWID_") or not fila.get(columna):
                    continue
                yield {"indicador_id": indicador_id, "cod_indicador": grafico, "cod_pais": cod,
                       "entidad": fila["entity"], "anio": int(fila["year"]), "valor": float(fila[columna])}

    @dlt.resource(name="internacional_eurostat", write_disposition="replace")
    def eurostat():
        for indicador_id, consulta in EUROSTAT_CONSULTAS.items():
            sep = "&" if "?" in consulta else "?"
            datos = _get(f"{EUROSTAT_URL}{consulta}{sep}sinceTimePeriod={EUROSTAT_DESDE}&format=JSON&lang=EN").json()
            filas = []
            for coords, valor in parse_json_stat_series(datos):
                if valor is None:
                    continue
                periodo = coords["time"]  # 2024 o, en las semestrales, 2024-S1
                filas.append({"indicador_id": indicador_id, "cod_indicador": consulta.split("?")[0],
                              "geo": coords["geo"], "anio": int(periodo[:4]), "periodo": periodo,
                              "valor": float(valor)})
            if not filas:
                raise ValueError(f"Eurostat sin datos para {indicador_id} ({consulta})")
            log.info("Eurostat %s: %s filas", indicador_id, len(filas))
            yield filas

    @dlt.resource(name="internacional_ocde_vivienda", write_disposition="replace")
    def ocde_vivienda():
        from ingestion.vivienda_publica import ocde_filas

        paises = set(PAISES_BM) | set(PAISES_SOLO_VIVIENDA)
        for f in ocde_filas():
            if f["cod_pais"] in paises:
                yield {"indicador_id": "vivienda_social_pct", "cod_indicador": "PH4.2",
                       "cod_pais": f["cod_pais"], "anio": f["anio"], "valor": f["pct_parque"]}

    return [banco_mundial, fmi, owid, eurostat, ocde_vivienda]


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("internacional").run(internacional()))
