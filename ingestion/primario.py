"""Fuente dlt del sector primario (agricultura, ganadería y pesca), tema `primario`.

Compara España con los 27 países de la UE (y el agregado EU27_2020 cuando Eurostat lo da)
para saber en qué productos es potencia europea. Todo son APIs abiertas sin clave:

1) Eurostat, API de diseminación (JSON-stat 2.0, CC BY 4.0):
   - apro_cpsh1: producción cosechada (HPRD_HUMD_EU_THS_T, miles de t a humedad UE) y
     superficie (AR_THS_HA, miles de ha) de una lista cerrada de cultivos (CULTIVOS), desde 2000.
     Trampa: strucpro ya no es PR_HU_EU. El último año es provisional y le faltan países.
   - apro_cpshr: lo mismo por comunidad autónoma (NUTS 2 de España).
   - apro_mt_pann (carne sacrificada en matadero, miles de t), apro_mt_lspig / apro_mt_lssheep /
     apro_mt_lscatl (cabaña de noviembre-diciembre, miles de cabezas), apro_mk_cola (leche de vaca
     entregada a centrales lecheras, miles de t).
   - aact_eaa01 (valor de la producción a precios básicos, M EUR corrientes), aact_eaa04 (lo mismo
     en volumen encadenado, CLV20_MEUR) y aact_eaa06 (renta agraria real por UTA).
   - fish_ca_main (capturas, t de peso vivo), fish_aq2a (acuicultura, t y EUR), fish_fleet_alt
     (flota: buques, arqueo GT y potencia kW).
   - nama_10r_3gva: VAB por rama A (agricultura, silvicultura y pesca) y total, por provincia
     (NUTS 3) y comunidad (NUTS 2) de España, M EUR corrientes.
   - nama_10_pe (población media, miles) y nama_10_gdp (deflactor implícito del PIB, 2020=100, en
     euros) de cada país, para cuotas de población y euros reales de los países de la UE.
2) Eurostat Comext DS-045409 (comercio por producto HS, mismo JSON-stat): exportaciones de cada
   país de la UE a todo el mundo (incluye el comercio intra-UE), en euros y en 100 kg, para una
   lista cerrada de capítulos y partidas (PRODUCTOS_HS). Países Bajos sale inflado por la
   reexportación (Róterdam): se anota en dbt.
3) Comisión Europea, Agri-food data portal (CC BY 4.0): producción de aceite de oliva por país y
   campaña (miles de t, con existencias finales y marca de estimación) y precios semanales en
   origen (EUR/100 kg) de España, Italia, Grecia y Portugal.

Recursos (replace): eurostat_cultivos, eurostat_cultivos_regiones, eurostat_ganaderia,
eurostat_cuentas_agricolas, eurostat_pesca, eurostat_vab_regiones, eurostat_poblacion_paises,
eurostat_deflactor_pib, eurostat_exportaciones, primario_aceite_produccion,
primario_aceite_precios.
"""

import logging
import re
import time

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series

log = logging.getLogger(__name__)

EUROSTAT = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
COMEXT = "https://ec.europa.eu/eurostat/api/comext/dissemination/statistics/1.0/data/"
AGRIFOOD = "https://ec.europa.eu/agrifood/api/"
CABECERAS = {"User-Agent": "Mozilla/5.0 (spainfacts.org; datos abiertos)"}

# Los 27 de la UE con el código de Eurostat (Grecia = EL)
PAISES_UE = ["AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES", "FI", "FR", "HR", "HU",
             "IE", "IT", "LT", "LU", "LV", "MT", "NL", "PL", "PT", "RO", "SE", "SI", "SK"]
GEOS = set(PAISES_UE) | {"EU27_2020"}
NUTS2_ES = ["ES11", "ES12", "ES13", "ES21", "ES22", "ES23", "ES24", "ES30", "ES41", "ES42", "ES43",
            "ES51", "ES52", "ES53", "ES61", "ES62", "ES63", "ES64", "ES70"]

# Cultivos clave de apro_cpsh1 (código -> nombre en la web)
CULTIVOS = {
    "O1000": "Aceituna (olivar)", "T0000": "Cítricos", "T1000": "Naranja", "T2000": "Mandarina y pequeños cítricos",
    "T3000": "Limón", "V0000_S0000": "Hortalizas frescas y fresa", "V3100": "Tomate", "V3600": "Pimiento",
    "V2300": "Lechuga", "V3510": "Melón", "V3520": "Sandía", "V4600": "Ajo", "V4200": "Cebolla",
    "S0000": "Fresa", "F1200": "Fruta de hueso", "F1210_1220": "Melocotón y nectarina", "F1240": "Cereza",
    "F4300": "Almendra", "F2300": "Aguacate", "F1110": "Manzana", "W1000": "Uva", "W1100": "Uva de vinificación",
    "W1200": "Uva de mesa", "C0000": "Cereales", "C1100": "Trigo", "C1300": "Cebada", "C1500": "Maíz",
    "C2000": "Arroz", "I1120": "Girasol", "R1000": "Patata",
}
ESTRUCTURAS = ["HPRD_HUMD_EU_THS_T", "AR_THS_HA"]

# Capítulos/partidas HS para Comext (exportaciones a todo el mundo)
PRODUCTOS_HS = ["TOTAL", "02", "0203", "03", "07", "0702", "0709", "08", "0802", "0805", "0806",
                "1509", "2204", "1601", "0207"]

DESDE = "2000"


def _get(url: str, intentos: int = 4, timeout: int = 180) -> requests.Response:
    for i in range(intentos):
        try:
            resp = requests.get(url, headers=CABECERAS, timeout=timeout)
            if resp.status_code in (429, 500, 502, 503, 504):
                raise requests.HTTPError(f"HTTP {resp.status_code}")
            resp.raise_for_status()
            return resp
        except (requests.HTTPError, requests.ConnectionError, requests.Timeout) as e:
            if i == intentos - 1:
                raise
            log.warning("Reintento %s de %s: %s", i + 1, url[:120], e)
            time.sleep(5 * (i + 1))


def _eurostat(consulta: str, base: str = EUROSTAT):
    """Devuelve (coords, valor) de una consulta JSON-stat de Eurostat o Comext."""
    datos = _get(base + consulta + "&format=JSON&lang=EN").json()
    yield from parse_json_stat_series(datos)


def _params(nombre: str, valores) -> str:
    return "".join(f"&{nombre}={v}" for v in valores)


def _num(valor):
    return None if valor is None else float(valor)


@dlt.source(name="primario")
def primario():
    @dlt.resource(name="eurostat_cultivos", write_disposition="replace")
    def cultivos():
        """apro_cpsh1: producción (miles t) y superficie (miles ha) por país, desde 2000."""
        for codigo in CULTIVOS:
            consulta = (f"apro_cpsh1?crops={codigo}" + _params("strucpro", ESTRUCTURAS)
                        + f"&sinceTimePeriod={DESDE}")
            for c, v in _eurostat(consulta):
                if c["geo"] in GEOS:
                    yield {"crops": codigo, "strucpro": c["strucpro"], "geo": c["geo"],
                           "anio": int(c["time"]), "valor": _num(v)}

    @dlt.resource(name="eurostat_cultivos_regiones", write_disposition="replace")
    def cultivos_regiones():
        """apro_cpshr: lo mismo por comunidad (NUTS 2 de España)."""
        consulta = ("apro_cpshr?" + _params("crops", CULTIVOS).lstrip("&") + _params("strucpro", ESTRUCTURAS)
                    + _params("geo", ["ES"] + NUTS2_ES) + f"&sinceTimePeriod={DESDE}")
        for c, v in _eurostat(consulta):
            yield {"crops": c["crops"], "strucpro": c["strucpro"], "geo": c["geo"],
                   "anio": int(c["time"]), "valor": _num(v)}

    @dlt.resource(name="eurostat_ganaderia", write_disposition="replace")
    def ganaderia():
        """Carne sacrificada (miles t), cabaña de nov-dic (miles de cabezas) y leche (miles t)."""
        consultas = [
            ("apro_mt_pann", "apro_mt_pann?meatitem=SLAUGHT&unit=THS_T"
             + _params("meat", ["B1000", "B3100", "B4100", "B4200", "B7000"]), "meat", "THS_T"),
            ("apro_mt_lspig", "apro_mt_lspig?month=M11_M12&animals=A3100&unit=THS_HD", "animals", "THS_HD"),
            ("apro_mt_lssheep", "apro_mt_lssheep?month=M11_M12&animals=A4100&animals=A4200&unit=THS_HD",
             "animals", "THS_HD"),
            ("apro_mt_lscatl", "apro_mt_lscatl?month=M11_M12&animals=A2000&unit=THS_HD", "animals", "THS_HD"),
            ("apro_mk_cola", "apro_mk_cola?dairyprod=D1110D&milkitem=PRD&unit=THS_T", "dairyprod", "THS_T"),
        ]
        for dataset, consulta, dim, unidad in consultas:
            for c, v in _eurostat(consulta + f"&sinceTimePeriod={DESDE}"):
                if c["geo"] in GEOS:
                    yield {"dataset": dataset, "item": c[dim], "geo": c["geo"], "anio": int(c["time"]),
                           "unidad": unidad, "valor": _num(v)}

    @dlt.resource(name="eurostat_cuentas_agricolas", write_disposition="replace")
    def cuentas_agricolas():
        """aact_eaa01 (M EUR corrientes), aact_eaa04 (CLV20_MEUR) y aact_eaa06 (renta real por UTA).

        De las 157 partidas se guardan las de nivel alto (código acabado en 000)."""
        consultas = [
            ("aact_eaa01", "aact_eaa01?indic_agr=PRD_BP&unit=MIO_EUR"),
            ("aact_eaa04", "aact_eaa04?indic_agr=PRD_BP&unit=CLV20_MEUR"),
        ]
        for dataset, consulta in consultas:
            for c, v in _eurostat(consulta + f"&sinceTimePeriod={DESDE}"):
                if c["geo"] in GEOS and c["am_item"].endswith("000"):
                    yield {"dataset": dataset, "item": c["am_item"], "indicador": c["indic_agr"],
                           "unidad": c["unit"], "geo": c["geo"], "anio": int(c["time"]), "valor": _num(v)}
        consulta = ("aact_eaa06?indic_agr=RFI_AWU_CLV&indic_agr=IND_A&unit=CLV20_EUR_AWU&unit=I20"
                    f"&sinceTimePeriod={DESDE}")
        for c, v in _eurostat(consulta):
            if c["geo"] in GEOS:
                yield {"dataset": "aact_eaa06", "item": "RENTA", "indicador": c["indic_agr"],
                       "unidad": c["unit"], "geo": c["geo"], "anio": int(c["time"]), "valor": _num(v)}

    @dlt.resource(name="eurostat_pesca", write_disposition="replace")
    def pesca():
        """Capturas (t), acuicultura (t y EUR) y flota (número, GT, kW)."""
        for c, v in _eurostat(f"fish_ca_main?species=F00&fishreg=0&unit=TLW&sinceTimePeriod={DESDE}"):
            if c["geo"] in GEOS:
                yield {"dataset": "fish_ca_main", "unidad": "TLW", "geo": c["geo"],
                       "anio": int(c["time"]), "valor": _num(v)}
        consulta = (f"fish_aq2a?species=F00&aquameth=TOTAL&aquaenv=TOTAL&fishreg=0&unit=TLW&unit=EUR"
                    f"&sinceTimePeriod={DESDE}")
        for c, v in _eurostat(consulta):
            if c["geo"] in GEOS:
                yield {"dataset": "fish_aq2a", "unidad": c["unit"], "geo": c["geo"],
                       "anio": int(c["time"]), "valor": _num(v)}
        consulta = (f"fish_fleet_alt?tonnage=TOTAL&length=TOTAL&age=TOTAL&unit=NR&unit=GT&unit=KW"
                    f"&sinceTimePeriod={DESDE}")
        for c, v in _eurostat(consulta):
            if c["geo"] in GEOS:
                yield {"dataset": "fish_fleet_alt", "unidad": c["unit"], "geo": c["geo"],
                       "anio": int(c["time"]), "valor": _num(v)}

    @dlt.resource(name="eurostat_vab_regiones", write_disposition="replace")
    def vab_regiones():
        """nama_10r_3gva: VAB rama A y total, M EUR corrientes, España y sus NUTS 2 y NUTS 3."""
        datos = _get(EUROSTAT + "nama_10r_3gva?unit=CP_MEUR&nace_r2=A&nace_r2=TOTAL"
                     f"&sinceTimePeriod={DESDE}&format=JSON&lang=EN").json()
        etiquetas = datos["dimension"]["geo"]["category"]["label"]
        for c, v in parse_json_stat_series(datos):
            if c["geo"].startswith("ES"):
                yield {"geo": c["geo"], "nombre": etiquetas.get(c["geo"]), "nivel_nuts": len(c["geo"]) - 2,
                       "nace_r2": c["nace_r2"], "anio": int(c["time"]), "valor": _num(v)}

    @dlt.resource(name="eurostat_poblacion_paises", write_disposition="replace")
    def poblacion_paises():
        """nama_10_pe: población media anual (miles) de cada país de la UE y de la UE-27."""
        for c, v in _eurostat(f"nama_10_pe?na_item=POP_NC&unit=THS_PER&sinceTimePeriod={DESDE}"):
            if c["geo"] in GEOS:
                yield {"geo": c["geo"], "anio": int(c["time"]), "valor": _num(v)}

    @dlt.resource(name="eurostat_deflactor_pib", write_disposition="replace")
    def deflactor_pib():
        """nama_10_gdp: deflactor implícito del PIB en euros (PD20_EUR, 2020=100)."""
        for c, v in _eurostat(f"nama_10_gdp?na_item=B1GQ&unit=PD20_EUR&sinceTimePeriod={DESDE}"):
            if c["geo"] in GEOS:
                yield {"geo": c["geo"], "anio": int(c["time"]), "valor": _num(v)}

    @dlt.resource(name="eurostat_exportaciones", write_disposition="replace")
    def exportaciones():
        """Comext DS-045409: exportaciones (flow=2) de cada país de la UE a WORLD, EUR y 100 kg."""
        for producto in PRODUCTOS_HS:
            consulta = ("DS-045409?freq=A" + _params("reporter", [("GR" if p == "EL" else p) for p in PAISES_UE]) + "&partner=WORLD"
                        f"&product={producto}&flow=2&indicators=VALUE_IN_EUROS&indicators=QUANTITY_IN_100KG"
                        "&sinceTimePeriod=2002")
            for c, v in _eurostat(consulta, base=COMEXT):
                yield {"producto": c["product"], "reporter": "EL" if c["reporter"] == "GR" else c["reporter"], "indicador": c["indicators"],
                       "anio": int(c["time"]), "valor": _num(v)}

    @dlt.resource(name="primario_aceite_produccion", write_disposition="replace")
    def aceite_produccion():
        """Producción de aceite de oliva por país y campaña (miles de t), Agri-food data portal."""
        for f in _get(AGRIFOOD + "oliveOil/production?granularity=annual").json():
            yield {"geo": f.get("memberStateCode"), "pais": f.get("memberStateName"),
                   "campania": f.get("marketingYear"), "anio_produccion": f.get("productionYear"),
                   "produccion_miles_t": _num(f.get("yearProductionQuantity")),
                   "existencias_finales_miles_t": _num(f.get("endingStockQuantity")),
                   "estimado": f.get("isEstimated") == "Y"}

    @dlt.resource(name="primario_aceite_precios", write_disposition="replace")
    def aceite_precios():
        """Precios semanales del aceite de oliva en origen (EUR/100 kg) por mercado."""
        for pais in ["ES", "IT", "EL", "PT"]:
            url = AGRIFOOD + f"oliveOil/prices?memberStateCodes={pais}&beginDate=01/01/2010"
            for f in _get(url, timeout=300).json():
                m = re.search(r"[\d.,]+", f.get("price") or "")
                precio = float(m.group(0).replace(",", "")) if m else None
                d, mes, a = (f.get("beginDate") or "//").split("/")
                yield {"geo": f.get("memberStateCode"), "mercado": f.get("market"), "producto": f.get("product"),
                       "fecha_inicio": f"{a}-{mes}-{d}" if a else None, "semana": f.get("weekNumber"),
                       "campania": f.get("marketingYear"), "precio_eur_100kg": precio}

    return [cultivos, cultivos_regiones, ganaderia, cuentas_agricolas, pesca, vab_regiones,
            poblacion_paises, deflactor_pib, exportaciones, aceite_produccion, aceite_precios]
