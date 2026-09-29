"""Fuente dlt del tema `mercado`: mercado laboral (paro, empleo) y precios (IPC).

1) INE, Encuesta de Población Activa (trimestral salvo que se indique):
     65349  tasas de actividad, paro y empleo por provincia y sexo
     65334  tasas de paro por grupos de edad (menores de 25...), sexo y comunidad
     65336  tasas de paro por nacionalidad, sexo y comunidad
     66000  tasas de paro por nivel de formación, sexo y edad (ANUAL, desde 2014)
     65236  parados por tiempo de búsqueda de empleo (miles y %)
     65276  hogares según la incidencia del paro entre sus activos, por comunidad
     65194  asalariados por tipo de contrato (indefinido/temporal), miles y %
     65152  ocupados a tiempo parcial por motivo de la jornada parcial
   (la tabla 65219, tasas de paro por sexo y edad, ya la carga ingestion/ine.py
    como raw.ine_paro).

2) INE, Índice de Precios de Consumo (mensual; 76125, grupos ECOICOP, ya la
   carga ingestion/ine.py como raw.ine_ipc):
     76130  grupos especiales: subyacente, energía, alimentos sin elaborar...
     76140  tasa de variación del índice general por comunidad, desde 1978
     76156  ponderaciones de los grupos ECOICOP (por mil)

3) Eurostat:
     une_rt_m        tasa de paro mensual desestacionalizada (total y menores
                     de 25) de España, UE-27, zona euro, Alemania, Francia,
                     Italia y Portugal
     prc_hicp_minr   IPCA (ECOICOP v2; sustituye a prc_hicp_manr, congelada en
                     diciembre de 2025): tasa anual e índice 2015=100

4) SEPE, paro registrado por municipio (datos abiertos, un CSV por año desde
   2006: sede.sepe.gob.es/.../datos_abiertos/datos/Paro_por_municipios_<año>_csv.csv).
   Desde 2020 aprox. el SEPE oculta como "<5" las cifras de 1 a 4 personas:
   se guardan como NULL con la marca `oculto`.
     sepe_paro_municipios  mes x municipio (desde 2016), total, por sexo,
                           menores de 25 y sector
     sepe_paro_provincias  mes x provincia (desde 2006), sumando municipios; las
                           cifras ocultas "<5" se cuentan como 2 (error máximo de
                           unas decenas de personas por provincia)

5) Precios de la energía:
     ine_ipc_energia             INE 76128 (IPC, subclases ECOICOP v2): índice y
                                 tasas de electricidad, gas natural, hidrocarburos
                                 licuados (butano/propano), combustibles líquidos
                                 (gasóleo de calefacción), gasóleo y gasolina
     ine_ipc_ponderaciones_energia  INE 76159 (subclases) y 76161 (grupos
                                 especiales): ponderaciones por mil de esas
                                 subclases y de "Productos energéticos"
     ce_boletin_petrolero        Comisión Europea, Weekly Oil Bulletin (XLSX
                                 histórico "Prices History", hoja "Prices with
                                 taxes"): precio semanal con impuestos en €/1000 l
                                 de gasolina 95, gasóleo de automoción, gasóleo de
                                 calefacción y GLP de automoción, España y media UE
     eurostat_precio_electricidad_hogares  nrg_pc_204: €/kWh con todos los
                                 impuestos, banda DC (2.500-4.999 kWh/año), semestral
     eurostat_precio_gas_hogares nrg_pc_202: €/kWh con todos los impuestos, banda
                                 D2 (20-199 GJ/año), semestral
"""

import csv
import io
import logging
import re
import time
from datetime import date, datetime

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series

log = logging.getLogger(__name__)

EUROSTAT = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
SEPE = "https://sede.sepe.gob.es/es/portaltrabaja/resources/sede/datos_abiertos/datos/Paro_por_municipios_{}_csv.csv"
CABECERAS = {"User-Agent": "Mozilla/5.0 (spainfacts.org; datos abiertos)"}
PAISES = ["ES", "EU27_2020", "EA20", "DE", "FR", "IT", "PT"]
SEPE_PRIMER_ANIO = 2006
SEPE_MUNICIPIOS_DESDE = 2016

WOB_PAGINA = "https://energy.ec.europa.eu/data-and-analysis/weekly-oil-bulletin_en"
WOB_XLSX = ("https://energy.ec.europa.eu/document/download/906e60ca-8b6a-44e7-8589-652854d2fd3f_en"
            "?filename=Weekly_Oil_Bulletin_Prices_History_maticni_4web.xlsx")
WOB_PRODUCTOS = {"euro95": "Gasolina 95", "diesel": "Gasóleo de automoción",
                 "heating_oil": "Gasóleo de calefacción", "LPG": "GLP de automoción"}
PAISES_ENERGIA = ["ES", "EU27_2020", "DE", "FR", "IT", "PT"]
IPC_ENERGIA = r"^Nacional\. (Electricidad|Gas natural|Hidrocarburos licuados|Combustibles líquidos|Gasóleo|Gasolina)\."

TABLAS_INE = {
    "ine_epa_tasas_provincia": "65349",
    "ine_epa_paro_edad_ccaa": "65334",
    "ine_epa_paro_nacionalidad": "65336",
    "ine_epa_paro_formacion": "66000",
    "ine_epa_parados_busqueda": "65236",
    "ine_epa_hogares_paro": "65276",
    "ine_epa_asalariados_contrato": "65194",
    "ine_epa_parcial_motivo": "65152",
    "ine_ipc_especiales": "76130",
    "ine_ipc_ccaa_variacion": "76140",
    "ine_ipc_ponderaciones": "76156",
}


INE_TABLA = "https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/"
INE_SERIE = "https://servicios.ine.es/wstempus/js/ES/DATOS_SERIE/"


def _ine_get(url: str, intentos: int = 3):
    ultimo = None
    for i in range(intentos):
        try:
            r = requests.get(url, headers=CABECERAS, timeout=300)
            r.raise_for_status()
            return r.json()
        except (requests.RequestException, ValueError) as e:  # el INE a veces corta respuestas grandes
            ultimo = e
            log.warning("INE %s intento %s: %s", url, i + 1, e)
            time.sleep(5 * (i + 1))
    raise ultimo


def _ine_resource(nombre: str, tabla_id: str):
    """Como ingestion.ine._tabla_resource (mismas columnas), pero resistente a
    las respuestas truncadas del INE: si la tabla completa falla, descarga la
    lista de series (nult=1) y luego cada serie por separado."""
    @dlt.resource(name=nombre, write_disposition="replace")
    def filas():
        try:
            series = _ine_get(f"{INE_TABLA}{tabla_id}", intentos=2)
        except Exception:  # noqa: BLE001
            lista = _ine_get(f"{INE_TABLA}{tabla_id}?nult=1")
            series = [_ine_get(f"{INE_SERIE}{s['COD']}?nult=5000") for s in lista]
        for serie in series:
            for punto in serie.get("Data", []):
                yield {
                    "cod_serie": serie.get("COD"),
                    "serie": serie.get("Nombre"),
                    "fecha": punto.get("Fecha"),
                    "anyo": punto.get("Anyo"),
                    "valor": punto.get("Valor"),
                    "secreto": punto.get("Secreto"),
                }

    return filas


def _ine_series_resource(nombre: str, tablas: list[str], patron: str):
    """Solo las series de `tablas` cuyo nombre casa con `patron`, una a una."""
    @dlt.resource(name=nombre, write_disposition="replace")
    def filas():
        for tabla_id in tablas:
            for s in _ine_get(f"{INE_TABLA}{tabla_id}?nult=1"):
                if not re.search(patron, s.get("Nombre", "")):
                    continue
                serie = _ine_get(f"{INE_SERIE}{s['COD']}?nult=5000")
                for punto in serie.get("Data", []):
                    yield {
                        "tabla": tabla_id,
                        "cod_serie": serie.get("COD"),
                        "serie": serie.get("Nombre"),
                        "fecha": punto.get("Fecha"),
                        "anyo": punto.get("Anyo"),
                        "valor": punto.get("Valor"),
                    }

    return filas


def _wob_url() -> str:
    """Enlace vigente al XLSX histórico (el identificador cambia al republicarlo)."""
    try:
        html = requests.get(WOB_PAGINA, headers=CABECERAS, timeout=120).text
        m = re.search(r'href="(/document/download/[^"]*Prices_History[^"]*\.xlsx)"', html)
        if m:
            return "https://energy.ec.europa.eu" + m.group(1).replace("&amp;", "&")
    except requests.RequestException as e:
        log.warning("Weekly Oil Bulletin: no se pudo leer la página (%s)", e)
    return WOB_XLSX


def _eurostat(consulta: str) -> dict:
    r = requests.get(EUROSTAT + consulta + "&format=JSON&lang=EN", headers=CABECERAS, timeout=180)
    r.raise_for_status()
    return r.json()


def _num(texto: str):
    """'123' -> (123, False); '<5' -> (None, True); '' -> (None, False)."""
    t = (texto or "").strip()
    if not t:
        return None, False
    if t.startswith("<"):
        return None, True
    return int(t.replace(".", "")), False


def _sepe_filas(anio: int):
    r = requests.get(SEPE.format(anio), headers=CABECERAS, timeout=300)
    if r.status_code == 404:
        log.info("SEPE %s todavía no publicado", anio)
        return
    r.raise_for_status()
    texto = r.content.decode("latin-1")
    lector = csv.reader(io.StringIO(texto), delimiter=";")
    for fila in lector:
        if len(fila) < 20 or not fila[0].strip().isdigit():
            continue  # título y cabecera
        yield fila


@dlt.source(name="mercado")
def mercado():
    recursos = [_ine_resource(nombre, tabla) for nombre, tabla in TABLAS_INE.items()]

    @dlt.resource(name="eurostat_paro_mensual", write_disposition="replace")
    def paro_mensual():
        consulta = ("une_rt_m?sex=T&s_adj=SA&unit=PC_ACT&age=TOTAL&age=Y_LT25"
                    + "".join(f"&geo={g}" for g in PAISES))
        for coords, valor in parse_json_stat_series(_eurostat(consulta)):
            yield {"mes": coords.get("time"), "geo": coords.get("geo"), "edad": coords.get("age"),
                   "tasa_paro": float(valor) if valor is not None else None}

    @dlt.resource(name="eurostat_ipca", write_disposition="replace")
    def ipca():
        consulta = ("prc_hicp_minr?coicop18=TOTAL&unit=RCH_A&unit=I15"
                    + "".join(f"&geo={g}" for g in PAISES))
        for coords, valor in parse_json_stat_series(_eurostat(consulta)):
            yield {"mes": coords.get("time"), "geo": coords.get("geo"), "unidad": coords.get("unit"),
                   "valor": float(valor) if valor is not None else None}

    @dlt.resource(name="sepe_paro_municipios", write_disposition="replace")
    def sepe_municipios():
        for anio in range(SEPE_MUNICIPIOS_DESDE, date.today().year + 1):
            for f in _sepe_filas(anio):
                total, oculto = _num(f[8])
                vals = [_num(x)[0] for x in f[9:20]]
                yield {
                    "mes": int(f[0]),
                    "cod_ccaa_sepe": int(f[2]),
                    "cod_prov": f[4].strip().zfill(2),
                    "cod_municipio": f[6].strip().zfill(5),
                    "municipio": f[7].strip(),
                    "paro_total": total,
                    "oculto": oculto,
                    "hombres_menor25": vals[0], "hombres_25_44": vals[1], "hombres_45_mas": vals[2],
                    "mujeres_menor25": vals[3], "mujeres_25_44": vals[4], "mujeres_45_mas": vals[5],
                    "agricultura": vals[6], "industria": vals[7], "construccion": vals[8],
                    "servicios": vals[9], "sin_empleo_anterior": vals[10],
                }

    @dlt.resource(name="sepe_paro_provincias", write_disposition="replace")
    def sepe_provincias():
        # Suma de los municipios; "<5" cuenta como 2.
        for anio in range(SEPE_PRIMER_ANIO, date.today().year + 1):
            acum: dict[tuple, list] = {}
            for f in _sepe_filas(anio):
                clave = (int(f[0]), f[4].strip().zfill(2), f[5].strip())
                a = acum.setdefault(clave, [0] * 13)
                for i, x in enumerate(f[8:20]):
                    n, oculto = _num(x)
                    a[i] += 2 if oculto else (n or 0)
                if _num(f[8])[1]:
                    a[12] += 1
            for (mes, cod_prov, provincia), a in sorted(acum.items()):
                yield {
                    "mes": mes, "cod_prov": cod_prov, "provincia": provincia,
                    "paro_total": a[0],
                    "hombres_menor25": a[1], "hombres_25_44": a[2], "hombres_45_mas": a[3],
                    "mujeres_menor25": a[4], "mujeres_25_44": a[5], "mujeres_45_mas": a[6],
                    "agricultura": a[7], "industria": a[8], "construccion": a[9],
                    "servicios": a[10], "sin_empleo_anterior": a[11],
                    "municipios_ocultos": a[12],
                }

    ipc_energia = _ine_series_resource("ine_ipc_energia", ["76128"], IPC_ENERGIA)
    ponderaciones_energia = _ine_series_resource(
        "ine_ipc_ponderaciones_energia", ["76159", "76161"],
        r"(Electricidad|Gas natural|Hidrocarburos licuados|Combustibles líquidos|Gasóleo|Gasolina"
        r"|Productos energéticos|Índice general)\. Ponderación")

    @dlt.resource(name="ce_boletin_petrolero", write_disposition="replace")
    def boletin_petrolero():
        import openpyxl  # dependencia ya presente en el entorno

        r = requests.get(_wob_url(), headers=CABECERAS, timeout=300)
        r.raise_for_status()
        libro = openpyxl.load_workbook(io.BytesIO(r.content), read_only=True, data_only=True)
        filas = libro["Prices with taxes"].iter_rows(values_only=True)
        cabecera = next(filas)
        columnas = {}
        for i, nombre in enumerate(cabecera):
            m = re.match(r"^(ES|EU)_price_with_tax_(euro95|diesel|heating_oil|LPG)$", str(nombre or ""))
            if m:
                columnas[i] = (m.group(1), WOB_PRODUCTOS[m.group(2)])
        for fila in filas:
            if not isinstance(fila[0], datetime):
                continue
            for i, (geo, producto) in columnas.items():
                v = fila[i] if i < len(fila) else None
                if isinstance(v, (int, float)):
                    yield {"fecha": fila[0].date(), "geo": geo, "producto": producto,
                           "eur_1000l": float(v)}

    def _precio_hogares(dataset: str, banda: str):
        consulta = (f"{dataset}?nrg_cons={banda}&tax=I_TAX&currency=EUR&unit=KWH"
                    + "".join(f"&geo={g}" for g in PAISES_ENERGIA))
        for coords, valor in parse_json_stat_series(_eurostat(consulta)):
            yield {"semestre": coords.get("time"), "geo": coords.get("geo"),
                   "eur_kwh": float(valor) if valor is not None else None}

    @dlt.resource(name="eurostat_precio_electricidad_hogares", write_disposition="replace")
    def precio_electricidad():
        yield from _precio_hogares("nrg_pc_204", "KWH2500-4999")

    @dlt.resource(name="eurostat_precio_gas_hogares", write_disposition="replace")
    def precio_gas():
        yield from _precio_hogares("nrg_pc_202", "GJ20-199")

    return recursos + [paro_mensual, ipca, sepe_municipios, sepe_provincias,
                       ipc_energia, ponderaciones_energia, boletin_petrolero, precio_electricidad, precio_gas]
