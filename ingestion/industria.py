"""Fuente dlt para la industria española comparada con la UE (página /economia/industria).

Eurostat, API de diseminación (JSON-stat 2.0), los 27 países y el agregado EU27_2020:
  eurostat_industria_vab        nama_10_a10: VAB por rama (TOTAL, B-E industria, C manufacturas),
                                % del total (PC_TOT), precios corrientes (CP_MEUR) y volumen (CLV10_MEUR).
                                (eurostat_vab_sectores de ingestion/eurostat.py solo tiene España.)
  eurostat_industria_empleo     nama_10_a10_e: ocupados por rama (miles, EMP_DC).
  eurostat_industria_poblacion  nama_10_pe: población media anual (miles), para el peso de cada país en la UE.
  eurostat_industria_sbs        sbs_ovw_act: estadísticas estructurales de empresas por rama NACE
                                (2 dígitos y algunas de 3-4): cifra de negocios neta (NETTUR_MEUR; TURN_MEUR
                                ya no existe), valor añadido (AV_MEUR), personas ocupadas (EMP_NR) y peso
                                en el VAB / empleo manufacturero (AV_MFG_PC, EMP_MFG_PC). 2021-último.
  eurostat_industria_ipi        sts_inpr_a: índice de producción industrial anual (2021=100,
                                corregido de calendario) por rama.
  eurostat_industria_vab_regional  nama_10r_3gva: VAB por rama de las comunidades (NUTS 2) y España,
                                precios corrientes.
Eurostat, API de Comext (misma codificación JSON-stat, otra URL base). Ojo: en Comext Grecia es GR, no EL.
  eurostat_industria_prodcom    DS-059358 (Prodcom «Sold production, exports and imports»; el antiguo
                                DS-056120 ya no existe): producción vendida en cantidad (PRODQNT), valor
                                (PRODVAL, euros) y unidad (QNTUNIT) de una lista cerrada de productos.
                                Muchos países tienen el dato confidencial: se carga también el agregado
                                EU27_2020 (estimación de Eurostat que incluye los confidenciales) para la
                                cuota; el puesto es entre los países que publican el dato.
  eurostat_industria_comext     DS-045409: exportaciones (flow=2) por partida HS en euros y en 100 kg,
                                al mundo (WORLD, incluye el comercio dentro de la UE) y fuera de la UE
                                (EXT_EU27_2020). Países Bajos y Bélgica salen inflados por reexportación
                                (puertos de Róterdam y Amberes).
INE (Tempus3):
  ine_industria_ipi_ccaa        70177: IPI base 2021, general y por destino económico, nacional y por
                                comunidad, mensual desde 2002 (índice y tasas).
  ine_industria_ipi_divisiones  60282: IPI por división CNAE (2 dígitos), corregido de estacionalidad y
                                calendario. (La 60286 que a veces se cita son solo las ponderaciones.)
  ine_industria_eee_ccaa        76823: Estadística Estructural de Empresas, sector industrial: cifra de
                                negocios, personal ocupado, sueldos, inversión y locales por comunidad
                                y rama CNAE (actividad por establecimiento).
"""

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series
from ingestion.ine import _tabla_resource

BASE = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
COMEXT = "https://ec.europa.eu/eurostat/api/comext/dissemination/statistics/1.0/data/"

UE27 = ["AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES", "FI", "FR", "HR", "HU", "IE", "IT",
        "LT", "LU", "LV", "MT", "NL", "PL", "PT", "RO", "SE", "SI", "SK"]
# Comext usa GR para Grecia; se normaliza a EL al cargar
UE27_COMEXT = [("GR" if p == "EL" else p) for p in UE27]

NUTS2_ES = ["ES11", "ES12", "ES13", "ES21", "ES22", "ES23", "ES24", "ES30", "ES41", "ES42", "ES43",
            "ES51", "ES52", "ES53", "ES61", "ES62", "ES63", "ES64", "ES70"]

RAMAS_SBS = ["B", "C", "D", "E", "C10", "C11", "C12", "C13", "C14", "C15", "C16", "C17", "C18", "C19", "C20",
             "C21", "C22", "C23", "C233", "C2331", "C235", "C24", "C241", "C25", "C26", "C27", "C28", "C2811",
             "C29", "C291", "C293", "C30", "C301", "C302", "C303", "C31", "C32", "C33"]

RAMAS_IPI = ["B-D", "C", "D", "C10", "C11", "C19", "C20", "C21", "C23", "C24", "C27", "C28", "C29", "C30"]

# Prodcom: código de 8 dígitos -> nombre corto en español
PRODUCTOS_PRODCOM = {
    "23311000": "Baldosas y azulejos cerámicos",
    "20302150": "Esmaltes y fritas cerámicas",
    "29102100": "Turismos de gasolina hasta 1.500 cm³",
    "29102230": "Turismos de gasolina de más de 1.500 cm³",
    "29102310": "Turismos diésel hasta 1.500 cm³",
    "29102330": "Turismos diésel de 1.500 a 2.500 cm³",
    "29102450": "Turismos eléctricos",
    "29103000": "Autobuses y autocares (10 o más plazas)",
    "10131120": "Jamones y paletas curados con hueso",
    "10412210": "Aceite de oliva virgen",
    "10415331": "Otros aceites de oliva (refinado y mezclas)",
    "10391770": "Aceitunas preparadas o en conserva",
    "11021190": "Vino espumoso (cava y otros, sin champán)",
    "23511210": "Cemento Portland",
    "24106210": "Barras corrugadas de acero para hormigón",
    "24105130": "Chapa de acero recubierta en caliente (galvanizada)",
    "24422250": "Perfiles y barras de aleación de aluminio",
    "28112400": "Aerogeneradores",
    "25112200": "Torres y castilletes de hierro o acero",
    "30203200": "Coches de viajeros de ferrocarril y tranvía",
    "30305091": "Partes de aviones y helicópteros",
    "30113130": "Buques de pesca",
    "22111100": "Neumáticos nuevos para turismos",
    "23131150": "Botellas de vidrio de color",
}

# Comext: partida HS (2 o 4 dígitos) -> nombre corto en español
PARTIDAS_HS = {
    "TOTAL": "Total de bienes",
    "8703": "Turismos",
    "8704": "Vehículos para transporte de mercancías",
    "8702": "Autobuses y autocares",
    "8708": "Partes y accesorios de vehículos",
    "87": "Vehículos (capítulo 87)",
    "6907": "Baldosas y azulejos cerámicos",
    "69": "Productos cerámicos (capítulo 69)",
    "3207": "Esmaltes, fritas y pigmentos cerámicos",
    "2523": "Cemento",
    "3004": "Medicamentos dosificados",
    "30": "Productos farmacéuticos (capítulo 30)",
    "8802": "Aviones y helicópteros",
    "88": "Aeronáutica y espacio (capítulo 88)",
    "8901": "Barcos de pasajeros y de carga",
    "8605": "Coches de viajeros de ferrocarril",
    "8502": "Grupos electrógenos y aerogeneradores",
    "2710": "Productos petrolíferos refinados",
    "27": "Combustibles y aceites minerales (capítulo 27)",
    "4011": "Neumáticos nuevos",
    "7208": "Laminados planos de acero en caliente",
    "72": "Fundición, hierro y acero (capítulo 72)",
    "84": "Máquinas y aparatos mecánicos (capítulo 84)",
    "85": "Máquinas y material eléctrico (capítulo 85)",
    "1509": "Aceite de oliva",
    "0210": "Jamones y carnes curadas",
    "3304": "Cosméticos y maquillaje",
}

INE_TABLAS = {
    "ine_industria_ipi_ccaa": "70177",
    "ine_industria_ipi_divisiones": "60282",
    "ine_industria_eee_ccaa": "76823",
}


def _json(url: str, timeout: int = 180) -> dict:
    resp = requests.get(url, timeout=timeout)
    resp.raise_for_status()
    return resp.json()


def _f(valor):
    # Eurostat mezcla enteros y decimales: float() para que dlt no cree columnas variantes
    return float(valor) if isinstance(valor, (int, float)) else None


def _geo(lista, campo="geo"):
    return "".join(f"&{campo}={g}" for g in lista)


@dlt.source(name="industria")
def industria():
    @dlt.resource(name="eurostat_industria_vab", write_disposition="replace")
    def vab():
        url = (BASE + "nama_10_a10?na_item=B1G&unit=PC_TOT&unit=CP_MEUR&unit=CLV10_MEUR"
               "&nace_r2=TOTAL&nace_r2=B-E&nace_r2=C&sinceTimePeriod=1995" + _geo(UE27 + ["EU27_2020"])
               + "&format=JSON&lang=EN")
        for c, v in parse_json_stat_series(_json(url)):
            yield {"anio": int(c["time"]), "pais": c["geo"], "rama": c["nace_r2"], "unidad": c["unit"], "valor": _f(v)}

    @dlt.resource(name="eurostat_industria_empleo", write_disposition="replace")
    def empleo():
        url = (BASE + "nama_10_a10_e?na_item=EMP_DC&unit=THS_PER&nace_r2=TOTAL&nace_r2=B-E&nace_r2=C"
               "&sinceTimePeriod=1995" + _geo(UE27 + ["EU27_2020"]) + "&format=JSON&lang=EN")
        for c, v in parse_json_stat_series(_json(url)):
            yield {"anio": int(c["time"]), "pais": c["geo"], "rama": c["nace_r2"], "miles": _f(v)}

    @dlt.resource(name="eurostat_industria_poblacion", write_disposition="replace")
    def poblacion():
        """nama_10_pe: población media anual (miles) de los 27 y EU27_2020, para el peso poblacional."""
        url = (BASE + "nama_10_pe?na_item=POP_NC&unit=THS_PER&sinceTimePeriod=1995" + _geo(UE27 + ["EU27_2020"])
               + "&format=JSON&lang=EN")
        for c, v in parse_json_stat_series(_json(url)):
            yield {"anio": int(c["time"]), "pais": c["geo"], "miles": _f(v)}

    @dlt.resource(name="eurostat_industria_sbs", write_disposition="replace")
    def sbs():
        indicadores = ["NETTUR_MEUR", "AV_MEUR", "EMP_NR", "AV_MFG_PC", "EMP_MFG_PC"]
        url = (BASE + "sbs_ovw_act?" + _geo(UE27 + ["EU27_2020"])[1:] + _geo(RAMAS_SBS, "nace_r2")
               + _geo(indicadores, "indic_sbs") + "&format=JSON&lang=EN")
        datos = _json(url)
        etiquetas = datos["dimension"]["nace_r2"]["category"]["label"]
        for c, v in parse_json_stat_series(datos):
            yield {"anio": int(c["time"]), "pais": c["geo"], "rama": c["nace_r2"],
                   "rama_nombre_en": etiquetas.get(c["nace_r2"]), "indicador": c["indic_sbs"], "valor": _f(v)}

    @dlt.resource(name="eurostat_industria_ipi", write_disposition="replace")
    def ipi():
        url = (BASE + "sts_inpr_a?indic_bt=PRD&unit=I21&s_adj=CA&sinceTimePeriod=2000"
               + _geo(UE27 + ["EU27_2020"]) + _geo(RAMAS_IPI, "nace_r2") + "&format=JSON&lang=EN")
        for c, v in parse_json_stat_series(_json(url)):
            yield {"anio": int(c["time"]), "pais": c["geo"], "rama": c["nace_r2"], "indice": _f(v)}

    @dlt.resource(name="eurostat_industria_vab_regional", write_disposition="replace")
    def vab_regional():
        url = (BASE + "nama_10r_3gva?unit=CP_MEUR&nace_r2=TOTAL&nace_r2=B-E&nace_r2=C&sinceTimePeriod=2000"
               + _geo(NUTS2_ES + ["ES"]) + "&format=JSON&lang=EN")
        for c, v in parse_json_stat_series(_json(url)):
            yield {"anio": int(c["time"]), "nuts": c["geo"], "rama": c["nace_r2"], "mill_eur": _f(v)}

    @dlt.resource(name="eurostat_industria_prodcom", write_disposition="replace")
    def prodcom():
        url = (COMEXT + "DS-059358?freq=A" + _geo(UE27_COMEXT + ["EU27_2020"], "reporter") + _geo(PRODUCTOS_PRODCOM, "product")
               + "&indicators=PRODQNT&indicators=PRODVAL&indicators=QNTUNIT&sinceTimePeriod=2015&format=JSON")
        datos = _json(url, timeout=300)
        etiquetas = datos["dimension"]["product"]["category"]["label"]
        filas = {}
        for c, v in parse_json_stat_series(datos):
            clave = (c["reporter"], c["product"], c["time"])
            fila = filas.setdefault(clave, {})
            fila[c["indicators"]] = v
        for (pais, producto, anio), x in filas.items():
            yield {
                "anio": int(anio),
                "pais": "EL" if pais == "GR" else pais,
                "producto": producto,
                "producto_nombre": PRODUCTOS_PRODCOM.get(producto),
                "producto_nombre_en": etiquetas.get(producto),
                "unidad": x.get("QNTUNIT") if isinstance(x.get("QNTUNIT"), str) else None,
                "cantidad": _f(x.get("PRODQNT")),
                "valor_eur": _f(x.get("PRODVAL")),
            }

    @dlt.resource(name="eurostat_industria_comext", write_disposition="replace")
    def comext():
        url = (COMEXT + "DS-045409?freq=A&flow=2&partner=WORLD&partner=EXT_EU27_2020"
               + _geo(UE27_COMEXT, "reporter") + _geo(PARTIDAS_HS, "product")
               + "&indicators=VALUE_IN_EUROS&indicators=QUANTITY_IN_100KG&sinceTimePeriod=2015&format=JSON")
        filas = {}
        for c, v in parse_json_stat_series(_json(url, timeout=300)):
            clave = (c["reporter"], c["partner"], c["product"], c["time"])
            filas.setdefault(clave, {})[c["indicators"]] = v
        for (pais, socio, partida, anio), x in filas.items():
            yield {
                "anio": int(anio),
                "pais": "EL" if pais == "GR" else pais,
                "destino": socio,
                "partida": partida,
                "partida_nombre": PARTIDAS_HS.get(partida),
                "valor_eur": _f(x.get("VALUE_IN_EUROS")),
                "cantidad_100kg": _f(x.get("QUANTITY_IN_100KG")),
            }

    recursos = [vab, empleo, poblacion, sbs, ipi, vab_regional, prodcom, comext]
    recursos += [_tabla_resource(nombre, tabla) for nombre, tabla in INE_TABLAS.items()]
    return recursos
