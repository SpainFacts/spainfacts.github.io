"""Fuente dlt de demografía: natalidad, mortalidad, fecundidad, hogares y
población por origen (INE).

Todas las tablas son del INE. Las del Movimiento Natural de la Población (MNP)
y los Indicadores Demográficos Básicos (IDB) se leen de la API JSON Tempus3 con
`tip=AM`, que añade a cada serie sus metadatos con códigos: así el territorio
llega ya como código INE (provincia '02', comunidad '01', España '00') sin
depender de cómo se escriba el nombre ("Araba/Álava", "Balears, Illes"...).

Recursos (replace):
  ine_nacimientos_mensual      MNP 6524: nacimientos por mes y provincia de residencia de la madre (1975-)
  ine_defunciones_mensual      MNP 6561: defunciones por mes y provincia de residencia (1975-)
  ine_tasa_natalidad           IDB 1470 (provincias) + 1432 (comunidades): nacidos por 1.000 hab.
  ine_tasa_mortalidad          IDB 1482 (provincias) + 1445 (comunidades): defunciones por 1.000 hab.
  ine_fecundidad               IDB 1478 (provincias) + 1441 (comunidades, por nacionalidad de la madre):
                               indicador coyuntural de fecundidad (hijos por mujer) por orden del nacimiento
  ine_edad_maternidad          IDB 1581 (provincias) + 1580 (comunidades): edad media a la maternidad
  ine_nacidos_nacionalidad_madre  IDB 2777: % de nacidos según nacionalidad de la madre, España y comunidades (2002-)
  ine_hogares                  ECP 60131 (comunidades) + 60133 (provincias): hogares por número de miembros (2021-)
  ine_hogares_tamano_medio     ECP 60132 (comunidades) + 60134 (provincias): tamaño medio del hogar (2021-)
  ine_poblacion_origen_provincia  ECP 56948 (lugar de nacimiento España/extranjero) + 56947 (nacionalidad
                               española/extranjera) por provincia, grupo quinquenal de edad y sexo, a 1 de
                               enero (2002-). CSV masivo (~300 MB cada uno) leído en streaming; solo se
                               guardan Total / España / Extranjero (no los grupos de países).
                               Las tablas 59591/59592 son solo los últimos trimestres provisionales.

La población por provincia, edad simple y sexo (ECP 56945) ya la carga
ingestion/ine.py en raw.ine_poblacion_provincias; los marts demografia_* la
reutilizan para el envejecimiento y las pirámides.
"""

import csv
import re

import dlt
import requests

INE_BASE = "https://servicios.ine.es/wstempus/js/ES/DATOS_TABLA/"
INE_CSV = "https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/{}.csv"

# Variables de territorio de la API y su nivel
_TERRITORIOS = {
    "Provincias": "provincia",
    "Comunidades y Ciudades Autónomas": "ccaa",
    "Totales Territoriales": "pais",
    "Total Nacional": "pais",
}
# Otras variables que se guardan como columnas propias
_DIMENSIONES = {
    "Nacionalidad": "nacionalidad",
    "Orden de nacimiento": "orden",
    "Composición del hogar": "miembros",
}
_MES = re.compile(r"^M(\d{2})$")


def _tabla_meta(nombre: str, tablas: list[str]):
    """Recurso con todas las series de una o varias tablas Tempus3 (con metadatos)."""

    @dlt.resource(name=nombre, write_disposition="replace")
    def filas():
        for tabla_id in tablas:
            r = requests.get(f"{INE_BASE}{tabla_id}", params={"tip": "AM"}, timeout=300)
            r.raise_for_status()
            for serie in r.json():
                nivel, cod, territorio = None, None, None
                dims = {v: None for v in _DIMENSIONES.values()}
                for m in serie.get("MetaData", []):
                    var = m.get("T3_Variable")
                    if var in _TERRITORIOS:
                        if m.get("Codigo"):  # "No residente" (madres residentes fuera) no tiene código
                            nivel, cod, territorio = _TERRITORIOS[var], m["Codigo"], m["Nombre"]
                        else:
                            nivel, cod, territorio = "extranjero", "99", m["Nombre"]
                    elif var in _DIMENSIONES:
                        dims[_DIMENSIONES[var]] = m.get("Nombre")
                if cod == "00":
                    nivel = "pais"
                for punto in serie.get("Data", []):
                    if punto.get("Valor") is None:
                        continue
                    periodo = punto.get("T3_Periodo") or ""
                    mes = _MES.match(periodo)
                    yield {
                        "tabla": tabla_id,
                        "cod_serie": serie.get("COD"),
                        "serie": serie.get("Nombre"),
                        "nivel": nivel,
                        "cod": cod,
                        "territorio": territorio,
                        **dims,
                        "anio": int(punto["Anyo"]),
                        "mes": int(mes.group(1)) if mes else None,
                        "periodo": periodo,
                        "tipo_dato": punto.get("T3_TipoDato"),
                        "valor": float(punto["Valor"]),
                    }

    return filas


_ENERO = re.compile(r"^1 de enero de (\d{4})$")
_ORIGENES = {"Total", "España", "Extranjero", "Española", "Extranjera"}


@dlt.resource(name="ine_poblacion_origen_provincia", write_disposition="replace")
def poblacion_origen_provincia():
    """Población residente a 1 de enero por provincia, grupo quinquenal de edad, sexo y
    lugar de nacimiento (ECP 56948) o nacionalidad (ECP 56947). Se descartan los
    trimestres intermedios (la cifra anual oficial es la de 1 de enero) y los
    grupos de países."""
    for tabla, criterio in (("56948", "nacimiento"), ("56947", "nacionalidad")):
        with requests.get(INE_CSV.format(tabla), stream=True, timeout=600) as r:
            r.raise_for_status()
            r.encoding = "utf-8-sig"  # la cabecera HTTP dice ISO-8859-15, pero es UTF-8 con BOM
            lector = csv.reader(r.iter_lines(decode_unicode=True), delimiter=";")
            next(lector)  # Provincias;Grupo quinquenal de edad;País de nacimiento|Nacionalidad;Sexo;Periodo;Total
            for fila in lector:
                if len(fila) != 6:
                    continue
                provincia, edad, origen, sexo, periodo, total = (x.strip() for x in fila)
                m = _ENERO.match(periodo)
                if not m or total in ("", "..", ".") or origen not in _ORIGENES:
                    continue
                # "02 Albacete" -> "02"; "Total Nacional" -> "00"
                cod = "00" if provincia.lstrip("﻿") == "Total Nacional" else provincia[:2]
                if not cod.isdigit():
                    raise ValueError(f"Provincia del INE sin código: {provincia}")
                yield {
                    "tabla": tabla,
                    "criterio": criterio,
                    "cod_prov": cod,
                    "edad": edad,
                    "origen": origen,
                    "sexo": sexo,
                    "anio": int(m.group(1)),
                    "poblacion": int(total.replace(".", "")),
                }


@dlt.source(name="demografia")
def demografia():
    return [
        _tabla_meta("ine_nacimientos_mensual", ["6524"]),
        _tabla_meta("ine_defunciones_mensual", ["6561"]),
        _tabla_meta("ine_tasa_natalidad", ["1470", "1432"]),
        _tabla_meta("ine_tasa_mortalidad", ["1482", "1445"]),
        _tabla_meta("ine_fecundidad", ["1478", "1441"]),
        _tabla_meta("ine_edad_maternidad", ["1581", "1580"]),
        _tabla_meta("ine_nacidos_nacionalidad_madre", ["2777"]),
        _tabla_meta("ine_hogares", ["60131", "60133"]),
        _tabla_meta("ine_hogares_tamano_medio", ["60132", "60134"]),
        poblacion_origen_provincia,
    ]
