"""Fuente dlt para la API JSON del INE (Tempus3).

Cada tabla del INE se expone como un recurso dlt que carga TODAS las series
de la tabla (el script antiguo de scripts/ solo cargaba la última) en el
esquema `raw` de MotherDuck, con carga completa diaria (write_disposition
"replace": las tablas del INE son pequeñas y así la carga es idempotente).

La población por provincia, sexo y edad simple (tabla 56945 de la Estadística
Continua de Población) tiene ~16.000 series trimestrales: por JSON es enorme,
así que se lee del CSV masivo del INE y solo se guarda el dato a 1 de enero,
que es la cifra anual oficial (sumar los cuatro trimestres inflaba los totales).
"""

import codecs
import csv
import io
import re
import unicodedata
from pathlib import Path

import dlt
import requests

INE_BASE = "https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/"

# nombre de tabla destino en raw -> id de tabla del INE
TABLAS = {
    "ine_ipc": "76125",  # IPC base 2025 (ECOICOP v2, 2002-): índices y tasas de variación nacionales; la 50902 (base 2021) se congeló en dic-2025
    "ine_paro": "65219",  # EPA: tasas de paro por sexo y grupo de edad (nacional, 2002-hoy)
    # Ojo: la 65292 que usaba el script antiguo son valores ABSOLUTOS por CCAA
    # (no tiene tasas), y la 4086 está descatalogada (solo 2021-2023).
    # Estadística de Transporte de Viajeros (TV), mensual desde 2012, miles de viajeros:
    "ine_transporte_viajeros": "20239",  # por modo: urbano, metro, autobús, Cercanías, AVE, avión...
    "ine_transporte_ciudades": "20193",  # metro y autobús urbano en las 7 ciudades con metro
    # Empleo público (EPA, trimestral desde 2002, miles de personas):
    "ine_epa_asalariados_publicos": "65193",  # por tipo de administración (central, CCAA, local, empresas públicas...)
    "ine_epa_asalariados_ccaa": "65327",  # público / privado por comunidad autónoma
    # Salarios:
    "ine_epa_salarios_deciles": "66250",  # salario medio mensual por decil, asalariados públicos y privados (anual)
    "ine_ees_salarios_control": "36887",  # Encuesta Cuatrienal de Estructura Salarial 2022: control público/privado
    # Criminalidad (Estadística de Condenados, adultos, anual desde 2013):
    "ine_condenados_ccaa": "25704",  # condenados por comunidad, sexo y nacionalidad (española/extranjera)
    "ine_condenados_delitos_nacionalidad": "49050",  # delitos e infracciones por nacionalidad del condenado
    # Salud:
    "ine_esperanza_vida_ccaa": "1448",  # esperanza de vida al nacer por comunidad y sexo, anual desde 1975
    "ine_esperanza_vida_provincia": "1485",  # ídem por provincia
    "ine_defunciones_semanales": "35177",  # defunciones semanales por comunidad (EDeS), para el exceso de mortalidad
    # Inmigración:
    "ine_flujos_inmigracion": "59011",  # inmigraciones desde el extranjero por nacionalidad, trimestral (ECP)
    "ine_flujos_emigracion": "59014",  # emigraciones al extranjero por nacionalidad, trimestral (ECP)
    "ine_nacionalizaciones": "70012",  # adquisiciones de nacionalidad española por comunidad y nacionalidad previa, anual
    # Estadística de Migraciones y Cambios de Residencia (EMCR), anual:
    "ine_inmigraciones_anual": "69687",  # inmigraciones procedentes del extranjero por sexo y edad
    "ine_emigraciones_anual": "69702",  # emigraciones con destino al extranjero por sexo y edad
    "ine_saldos_migratorios": "69758",  # saldos por nacionalidad y tipo (exterior/interior), España
    "ine_saldos_migratorios_ccaa": "69762",  # saldos por comunidad, edad, nacionalidad (española/extranjera) y tipo
    # Salarios: Encuesta Trimestral de Coste Laboral (ETCL), desde 2008
    "ine_coste_salarial": "6038",  # coste salarial por trabajador y mes por jornada y sector (industria, construcción, servicios)
}


def _tabla_resource(nombre: str, tabla_id: str):
    @dlt.resource(name=nombre, write_disposition="replace")
    def filas():
        respuesta = requests.get(f"{INE_BASE}{tabla_id}", timeout=120)
        respuesta.raise_for_status()
        for serie in respuesta.json():
            for punto in serie.get("Data", []):
                yield {
                    "cod_serie": serie.get("COD"),
                    "serie": serie.get("Nombre"),
                    "fecha": punto.get("Fecha"),  # epoch en milisegundos
                    "anyo": punto.get("Anyo"),
                    "valor": punto.get("Valor"),
                    "secreto": punto.get("Secreto"),
                }

    return filas


POBLACION_CSV = "https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/56945.csv"
_ANIO_ENERO = re.compile(r"^1 de enero de (\d{4})$")


def _edad(etiqueta: str) -> int | None:
    # "0 años", "1 año", "100 y más años" -> 0, 1, 100; "Todas las edades" -> None
    m = re.match(r"^(\d+)", etiqueta)
    return int(m.group(1)) if m else None


@dlt.resource(name="ine_poblacion_provincias", write_disposition="replace")
def poblacion_provincias():
    with requests.get(POBLACION_CSV, stream=True, timeout=600) as respuesta:
        respuesta.raise_for_status()
        lineas = codecs.iterdecode(respuesta.iter_lines(), "utf-8-sig")  # el servidor dice ISO-8859-15, pero es UTF-8 con BOM
        lector = csv.reader(lineas, delimiter=";")
        next(lector)  # cabecera: Edad simple;Provincias;Sexo;Periodo;Total
        for edad, provincia, sexo, periodo, total in lector:
            anio = _ANIO_ENERO.match(periodo)
            if not anio:
                continue
            # "02 Albacete" -> ("02", "Albacete"); "Total Nacional" -> (None, ...)
            cod_prov, _, nombre = provincia.partition(" ") if provincia[:2].isdigit() else (None, "", provincia)
            yield {
                "anio": int(anio.group(1)),
                "cod_prov": cod_prov,
                "provincia": nombre,
                "sexo": sexo,
                "edad_etiqueta": edad,
                "edad": _edad(edad),
                "edad_abierta": "y más" in edad,
                "poblacion": int(total.replace(".", "")) if total.strip() else None,
            }


# --- Territorios: padrón municipal y diccionario de municipios -------------

# Cifras oficiales de población de los municipios (revisión anual del padrón),
# 1996-hoy por municipio y sexo. 1997 no tiene revisión (celdas vacías) y los
# municipios aún no creados en un año vienen también vacíos: se descartan.
POBLACION_MUNICIPIOS_CSV = "https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/29005.csv?nocab=1"
# Relación de municipios a 1 de enero (se prueba la edición más reciente primero)
DICCIONARIO_MUNICIPIOS_URLS = [
    f"https://www.ine.es/daco/daco42/codmun/diccionario{aa:02d}.xlsx" for aa in (27, 26, 25, 24)
]


@dlt.resource(name="ine_poblacion_municipios", write_disposition="replace")
def poblacion_municipios():
    with requests.get(POBLACION_MUNICIPIOS_CSV, stream=True, timeout=600) as respuesta:
        respuesta.raise_for_status()
        lineas = codecs.iterdecode(respuesta.iter_lines(), "utf-8-sig")  # igual que 56945: UTF-8 con BOM
        lector = csv.reader(lineas, delimiter=";")
        next(lector)  # cabecera: Municipios;Sexo;Periodo;Total
        for municipio, sexo, periodo, total in lector:
            total = total.strip()
            if not total or not periodo.strip().isdigit():
                continue
            # "28079 Madrid" -> ("28079", "Madrid")
            cod_mun, _, nombre = municipio.partition(" ")
            if len(cod_mun) != 5 or not cod_mun.isdigit():
                continue
            yield {
                "anio": int(periodo),
                "cod_mun": cod_mun,
                "municipio": nombre,
                "sexo": sexo,
                "poblacion": int(total.replace(".", "")),
            }


@dlt.resource(name="ine_municipios", write_disposition="replace")
def municipios():
    import io

    import openpyxl

    for url in DICCIONARIO_MUNICIPIOS_URLS:
        respuesta = requests.get(url, timeout=120)
        if respuesta.status_code == 200 and respuesta.content[:2] == b"PK":  # xlsx = zip
            break
    else:
        raise RuntimeError("No se encontró ningún diccionario de municipios del INE")
    hoja = openpyxl.load_workbook(io.BytesIO(respuesta.content), read_only=True).active
    filas = hoja.iter_rows(values_only=True)
    for fila in filas:  # 1 fila de título y luego la cabecera
        if fila and fila[0] == "CODAUTO":
            break
    for codauto, cpro, cmun, dc, nombre in (f[:5] for f in filas):
        if not cpro or not cmun:
            continue
        cod_prov = str(cpro).zfill(2)
        yield {
            "cod_mun": cod_prov + str(cmun).zfill(3),
            "cod_prov": cod_prov,
            "cod_ccaa": str(codauto).zfill(2),
            "dc": str(dc),
            "nombre": nombre,
            "edicion": url.rsplit("/", 1)[-1],
        }


ECEPOV_CALEFACCION_CSV = "https://www.ine.es/jaxi/files/tpx/es/csv_bdsc/56784.csv"
_PROVINCIAS_SEED = Path(__file__).resolve().parent.parent / "transform" / "seeds" / "territorios_provincias.csv"
# Nombres del INE que no coinciden con el seed de provincias (sin tildes y en minúsculas)
_ALIAS_PROVINCIAS_INE = {
    "alicante/alacant": "03", "araba/alava": "01", "balears, illes": "07", "castellon/castello": "12",
    "coruna, a": "15", "palmas, las": "35", "rioja, la": "26", "valencia/valencia": "46",
    "santa cruz de tenerife": "38", "bizkaia": "48", "gipuzkoa": "20", "madrid": "28", "navarra": "31",
    "asturias": "33", "cantabria": "39", "murcia": "30", "girona": "17", "lleida": "25", "ourense": "32",
}


def _sin_tildes(texto: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", texto) if unicodedata.category(c) != "Mn").lower().strip()


def _codigos_provincia() -> dict[str, str]:
    """Nombre de provincia sin tildes y en minúsculas -> código INE (seed + alias del INE)."""
    por_nombre = {}
    with open(_PROVINCIAS_SEED, encoding="utf-8") as f:
        for fila in csv.DictReader(f):
            por_nombre[_sin_tildes(fila["nombre"])] = fila["cod_prov"]
    por_nombre.update(_ALIAS_PROVINCIAS_INE)
    return por_nombre


@dlt.resource(name="ine_ecepov_calefaccion", write_disposition="replace")
def ecepov_calefaccion():
    """Encuesta de Características Esenciales de la Población y las Viviendas 2021
    (INE, tabla 56784): viviendas principales con calefacción según el combustible,
    por provincia, tipo de edificio, año de construcción y tamaño del municipio."""
    por_nombre = _codigos_provincia()
    respuesta = requests.get(ECEPOV_CALEFACCION_CSV, timeout=120)
    respuesta.raise_for_status()
    lector = csv.reader(io.StringIO(respuesta.content.decode("utf-8-sig")), delimiter=";")
    next(lector)
    for provincia, edificio, construccion, tamano, combustible, total in lector:
        cod = None if provincia == "Total Nacional" else por_nombre.get(_sin_tildes(provincia))
        if provincia != "Total Nacional" and cod is None:
            raise ValueError(f"Provincia del INE sin código: {provincia}")
        yield {
            "cod_prov": cod or "00",
            "tipo_edificio": edificio,
            "anio_construccion": construccion,
            "tamano_municipio": tamano,
            "combustible": combustible,
            "viviendas": int(total.replace(".", "")) if total.strip() not in ("", "..", ".") else None,
        }


POBLACION_NACIONALIDAD_CSV = "https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/56942.csv"


@dlt.resource(name="ine_poblacion_nacionalidad", write_disposition="replace")
def poblacion_nacionalidad():
    """Población residente por comunidad, grupo quinquenal de edad, nacionalidad
    (española, extranjera y grandes grupos) y sexo (INE 56942, Estadística Continua
    de Población). CSV de ~130 MB: se lee en streaming y solo se guarda el dato a
    1 de enero de cada año (la cifra anual oficial)."""
    with requests.get(POBLACION_NACIONALIDAD_CSV, stream=True, timeout=600) as r:
        r.raise_for_status()
        r.encoding = "utf-8-sig"
        lector = csv.reader(r.iter_lines(decode_unicode=True), delimiter=";")
        next(lector)
        for fila in lector:
            if len(fila) != 6:
                continue  # líneas vacías del CSV
            territorio, edad, nacionalidad, sexo, periodo, total = fila
            m = _ANIO_ENERO.match(periodo.strip())
            if not m or "UE28" in nacionalidad or "menos UE28" in nacionalidad:
                continue  # trimestres intermedios y los agregados con Reino Unido (duplican a los UE27)
            territorio = territorio.strip()
            yield {
                "cod_ccaa": "00" if territorio == "Total Nacional" else territorio[:2],
                "edad": edad.strip(),
                "nacionalidad": nacionalidad.strip(),
                "sexo": sexo.strip(),
                "anio": int(m.group(1)),
                "poblacion": int(total.replace(".", "")) if total.strip() not in ("", "..") else None,
            }


DEFUNCIONES_CAUSAS_CSV = "https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/9936.csv"


@dlt.resource(name="ine_defunciones_causas", write_disposition="replace")
def defunciones_causas():
    """Estadística de Defunciones según la Causa de Muerte (INE, tabla 9936): defunciones
    por causa (lista reducida de 102), sexo y provincia de residencia, anual desde 1980.
    CSV (UTF-8) leído en streaming; provincia resuelta a código INE ('00' = Nacional)."""
    por_nombre = _codigos_provincia()
    with requests.get(DEFUNCIONES_CAUSAS_CSV, stream=True, timeout=600) as r:
        r.raise_for_status()
        r.encoding = "utf-8-sig"  # la cabecera HTTP dice ISO-8859-15, pero el fichero es UTF-8
        lector = csv.reader(r.iter_lines(decode_unicode=True), delimiter=";")
        next(lector)
        for fila in lector:
            if len(fila) != 5:
                continue
            causa, sexo, provincia, periodo, total = (x.strip() for x in fila)
            provincia = provincia.lstrip("﻿")
            if provincia == "Nacional":
                cod = "00"
            elif provincia == "Extranjero":
                cod = "99"
            elif re.match(r"^\d{2} ", provincia):
                cod = provincia[:2]  # "02 Albacete"
            else:
                cod = por_nombre.get(_sin_tildes(provincia))
                if cod is None:
                    raise ValueError(f"Provincia del INE sin código: {provincia}")
            m = re.match(r"^([0-9A-Z-]+)\s+(.+)$", causa)  # "001-102  I-XXII...", "00A COVID-19..."
            yield {
                "codigo_causa": m.group(1) if m else None,
                "causa": m.group(2) if m else causa,
                "sexo": sexo,
                "cod_prov": cod,
                "anio": int(periodo),
                "defunciones": int(total.replace(".", "")) if total not in ("", "..", ".") else None,
            }


@dlt.source(name="ine")
def ine():
    return [_tabla_resource(nombre, tabla_id) for nombre, tabla_id in TABLAS.items()] + [
        poblacion_provincias,
        poblacion_municipios,
        municipios,
        ecepov_calefaccion,
        poblacion_nacionalidad,
        defunciones_causas,
    ]
