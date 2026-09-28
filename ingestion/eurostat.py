"""Fuente dlt para la API de diseminación de Eurostat (JSON-stat 2.0).

Descarga series oficiales de finanzas y cuentas públicas para España (geo=ES, sector=S13):
1. eurostat_deuda: Deuda pública trimestral según PDE (gov_10q_ggdebt).
2. eurostat_cuentas_balance: Agregados anuales de ingresos, gastos, déficit y deuda (gov_10a_main).
3. eurostat_cuentas_gastos: Gasto público anual por función COFOG (gov_10a_exp).
4. eurostat_cuentas_ingresos: Recaudación anual de impuestos y cotizaciones por figura tributaria
   (gov_10a_taxag; el antiguo gov_10a_rev ya no se disemina).
5. eurostat_cuentas_subsectores: Ingresos (TR), gastos (TE), saldo (B9) y remuneración de asalariados
   (D1PAY, el coste del personal) del total AAPP y de sus
   subsectores (S1311 central, S1312 CCAA, S1313 local, S1314 Seguridad Social), en MIO_EUR y PC_GDP
   (gov_10a_main).
6. eurostat_pib: PIB anual a precios corrientes (nama_10_gdp, B1GQ, CP_MEUR).
7. eurostat_poblacion: Población media anual de contabilidad nacional (nama_10_pe, POP_NC, THS_PER).
8. eurostat_balance_energetico: consumo final de energía por sector (industria y sus ramas,
   transporte, hogares, servicios) y combustible, en ktep (nrg_bal_c), para medir la electrificación.
9. eurostat_hogares_usos: energía de los hogares por uso (calefacción, agua caliente, cocina...)
   y combustible, en TJ (nrg_d_hhq).
10. eurostat_bombas_calor: potencia térmica y número de bombas de calor por tecnología (nrg_inf_hptc).
"""

import dlt
import requests


def parse_json_stat_series(datos: dict):
    """Decodifica cualquier dataset multidimensional JSON-stat 2.0 de Eurostat."""
    dim_ids = datos.get("id", [])
    dim_sizes = datos.get("size", [])
    if not dim_ids or not dim_sizes:
        return

    # Construir la lista de códigos para cada dimensión
    dim_codes = []
    for dim_id in dim_ids:
        dim_info = datos["dimension"][dim_id]["category"]
        if "index" in dim_info and isinstance(dim_info["index"], dict):
            inv_index = {v: k for k, v in dim_info["index"].items()}
            codes = [inv_index[i] for i in range(len(inv_index))]
        elif "index" in dim_info and isinstance(dim_info["index"], list):
            codes = dim_info["index"]
        else:
            codes = list(dim_info["label"].keys())
        dim_codes.append(codes)

    # Decodificar cada posición plana
    for flat_str, val in datos.get("value", {}).items():
        flat_idx = int(flat_str)
        coords = {}
        temp = flat_idx
        for k in reversed(range(len(dim_ids))):
            dim_size = dim_sizes[k]
            idx_in_dim = temp % dim_size
            temp = temp // dim_size
            coords[dim_ids[k]] = dim_codes[k][idx_in_dim]

        yield coords, val


@dlt.source(name="eurostat")
def eurostat():
    @dlt.resource(name="eurostat_deuda", write_disposition="replace")
    def deuda():
        url = (
            "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
            "gov_10q_ggdebt?freq=Q&geo=ES&sector=S13&na_item=GD&unit={unit}&format=JSON&lang=EN"
        )
        for unidad in ["MIO_EUR", "PC_GDP"]:
            resp = requests.get(url.format(unit=unidad), timeout=120)
            resp.raise_for_status()
            for coords, valor in parse_json_stat_series(resp.json()):
                yield {
                    "periodo": coords.get("time"),
                    "unidad": unidad,
                    "valor": valor,
                }

    @dlt.resource(name="eurostat_cuentas_balance", write_disposition="replace")
    def balance():
        url = (
            "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
            "gov_10a_main?geo=ES&sector=S13&unit=MIO_EUR&format=JSON&lang=EN"
        )
        resp = requests.get(url, timeout=120)
        resp.raise_for_status()
        for coords, valor in parse_json_stat_series(resp.json()):
            yield {
                "periodo": coords.get("time"),
                "na_item": coords.get("na_item"),
                "unidad": coords.get("unit"),
                "sector": coords.get("sector"),
                "valor": valor,
            }

    @dlt.resource(name="eurostat_cuentas_gastos", write_disposition="replace")
    def gastos():
        url = (
            "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
            "gov_10a_exp?geo=ES&sector=S13&unit=MIO_EUR&na_item=TE&format=JSON&lang=EN"
        )
        resp = requests.get(url, timeout=120)
        resp.raise_for_status()
        for coords, valor in parse_json_stat_series(resp.json()):
            yield {
                "periodo": coords.get("time"),
                "cofog99": coords.get("cofog99"),
                "na_item": coords.get("na_item"),
                "unidad": coords.get("unit"),
                "valor": valor,
            }

    @dlt.resource(name="eurostat_cuentas_ingresos", write_disposition="replace")
    def ingresos():
        url = (
            "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
            "gov_10a_taxag?geo=ES&sector=S13&unit=MIO_EUR&format=JSON&lang=EN"
        )
        resp = requests.get(url, timeout=120)
        resp.raise_for_status()
        for coords, valor in parse_json_stat_series(resp.json()):
            yield {
                "periodo": coords.get("time"),
                "na_item": coords.get("na_item"),
                "unidad": coords.get("unit"),
                "valor": valor,
            }

    @dlt.resource(name="eurostat_cuentas_subsectores", write_disposition="replace")
    def subsectores():
        url = (
            "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
            "gov_10a_main?geo=ES"
            "&sector=S13&sector=S1311&sector=S1312&sector=S1313&sector=S1314"
            "&unit=MIO_EUR&unit=PC_GDP&na_item=TE&na_item=TR&na_item=B9&na_item=D1PAY"
            "&format=JSON&lang=EN"
        )
        resp = requests.get(url, timeout=120)
        resp.raise_for_status()
        for coords, valor in parse_json_stat_series(resp.json()):
            yield {
                "periodo": coords.get("time"),
                "sector": coords.get("sector"),
                "na_item": coords.get("na_item"),
                "unidad": coords.get("unit"),
                "valor": valor,
            }

    @dlt.resource(name="eurostat_pib", write_disposition="replace")
    def pib():
        url = (
            "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
            "nama_10_gdp?geo=ES&na_item=B1GQ&unit=CP_MEUR&format=JSON&lang=EN"
        )
        resp = requests.get(url, timeout=120)
        resp.raise_for_status()
        for coords, valor in parse_json_stat_series(resp.json()):
            yield {
                "periodo": coords.get("time"),
                "unidad": coords.get("unit"),
                "valor": valor,
            }

    @dlt.resource(name="eurostat_poblacion", write_disposition="replace")
    def poblacion():
        url = (
            "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
            "nama_10_pe?geo=ES&na_item=POP_NC&unit=THS_PER&format=JSON&lang=EN"
        )
        resp = requests.get(url, timeout=120)
        resp.raise_for_status()
        for coords, valor in parse_json_stat_series(resp.json()):
            yield {
                "periodo": coords.get("time"),
                "unidad": coords.get("unit"),
                "valor": valor,
            }

    # --- Electrificación de la economía ------------------------------------
    BASE = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"

    def _json(consulta: str) -> dict:
        resp = requests.get(BASE + consulta + "&format=JSON&lang=EN", timeout=180)
        resp.raise_for_status()
        return resp.json()

    @dlt.resource(name="eurostat_balance_energetico", write_disposition="replace")
    def balance_energetico():
        """nrg_bal_c: consumo final de energía por sector y combustible (ktep), desde 1990."""
        sectores = ["FC_E", "FC_IND_E", "FC_TRA_E", "FC_TRA_ROAD_E", "FC_TRA_RAIL_E", "FC_OTH_HH_E",
                    "FC_OTH_CP_E", "FC_OTH_AF_E", "FC_IND_IS_E", "FC_IND_CPC_E", "FC_IND_NFM_E",
                    "FC_IND_NMM_E", "FC_IND_TE_E", "FC_IND_MAC_E", "FC_IND_MQ_E", "FC_IND_FBT_E",
                    "FC_IND_PPP_E", "FC_IND_WP_E", "FC_IND_CON_E", "FC_IND_TL_E", "FC_IND_NSP_E"]
        combustibles = ["TOTAL", "E7000", "G3000", "O4000XBIO", "RA000", "RA600", "H8000", "C0000X0350-0370"]
        consulta = ("nrg_bal_c?geo=ES&unit=KTOE" + "".join(f"&nrg_bal={x}" for x in sectores)
                    + "".join(f"&siec={x}" for x in combustibles))
        for coords, valor in parse_json_stat_series(_json(consulta)):
            yield {"anio": coords.get("time"), "sector": coords.get("nrg_bal"), "combustible": coords.get("siec"), "ktep": valor}

    @dlt.resource(name="eurostat_hogares_usos", write_disposition="replace")
    def hogares_usos():
        """nrg_d_hhq: consumo de energía de los hogares por uso final y combustible (TJ), desde 2010."""
        combustibles = ["TOTAL", "E7000", "G3000", "O4000", "R5110-5150_W6000RI", "RA410", "RA600", "H8000"]
        consulta = "nrg_d_hhq?geo=ES&unit=TJ" + "".join(f"&siec={x}" for x in combustibles)
        for coords, valor in parse_json_stat_series(_json(consulta)):
            yield {"anio": coords.get("time"), "uso": coords.get("nrg_bal"), "combustible": coords.get("siec"), "tj": valor}

    @dlt.resource(name="eurostat_bombas_calor", write_disposition="replace")
    def bombas_calor():
        """nrg_inf_hptc: potencia térmica (MW) y número de bombas de calor por tecnología, desde 1990."""
        datos = _json("nrg_inf_hptc?geo=ES&plant_tec=CAP_HEAT")
        etiquetas = datos["dimension"]["hp_tech"]["category"]["label"]
        for coords, valor in parse_json_stat_series(datos):
            yield {"anio": coords.get("time"), "tecnologia": coords.get("hp_tech"),
                   "tecnologia_nombre": etiquetas.get(coords.get("hp_tech")), "unidad": coords.get("unit"), "valor": valor}

    return [deuda, balance, gastos, ingresos, subsectores, pib, poblacion, balance_energetico, hogares_usos, bombas_calor]
