"""Fuente dlt para el turismo (INE, API JSON Tempus3).

Tablas del INE (todas mensuales salvo las viviendas turísticas):
  FRONTUR (Movimientos Turísticos en Fronteras, desde oct-2015):
    ine_frontur_pais     10822  turistas internacionales por país de residencia
    ine_frontur_ccaa     10823  turistas por comunidad de destino principal
                               (solo las 6 principales + "Otras Comunidades Autónomas")
  EGATUR (Encuesta de Gasto Turístico, desde oct-2015):
    ine_egatur_pais      10838  gasto total (millones de euros), gasto medio por
                               persona y por día y duración media, por país de residencia
    ine_egatur_ccaa      10839  ídem por comunidad de destino principal (6 + otras)
  Coyuntura Turística Hotelera (EOH, desde 1999):
    ine_eoh_viajeros     2074   viajeros y pernoctaciones por residencia (España /
                               extranjero), nacional, comunidades y provincias
    ine_eoh_ocupacion    2066   establecimientos, plazas, grado de ocupación y
                               personal, nacional, comunidades y provincias
  Encuesta de Ocupación en Apartamentos Turísticos (EOAP, desde 2000):
    ine_eoap_viajeros    1993   viajeros y pernoctaciones por comunidad y residencia
    ine_eoap_ocupacion   2021   apartamentos, plazas y grado de ocupación por comunidad
  Viviendas turísticas en España (medición experimental, semestral desde 2020):
    ine_vut_viviendas    39363  viviendas turísticas, plazas y plazas por vivienda
                               (nacional, comunidades, provincias y municipios)
    ine_vut_porcentaje   39366  % de viviendas turísticas sobre las viviendas censadas
  Las dos de viviendas turísticas se leen con metadatos (tip=AM) para tener el
  código INE del territorio (los nombres de municipio se repiten entre provincias).
"""

import dlt
import requests

from ingestion.ine import INE_BASE, _tabla_resource

TABLAS = {
    "ine_frontur_pais": "10822",
    "ine_frontur_ccaa": "10823",
    "ine_egatur_pais": "10838",
    "ine_egatur_ccaa": "10839",
    "ine_eoh_viajeros": "2074",
    "ine_eoh_ocupacion": "2066",
    "ine_eoap_viajeros": "1993",
    "ine_eoap_ocupacion": "2021",
}

VUT = {"ine_vut_viviendas": "39363", "ine_vut_porcentaje": "39366"}

NIVELES = {
    "Total Nacional": "pais",
    "Comunidades y Ciudades Autónomas": "ccaa",
    "Provincias": "provincia",
    "Municipios": "municipio",
}


def _vut_resource(nombre: str, tabla_id: str):
    @dlt.resource(name=nombre, write_disposition="replace")
    def filas():
        r = requests.get(f"{INE_BASE}{tabla_id}", params={"tip": "AM"}, timeout=600)
        r.raise_for_status()
        for serie in r.json():
            meta = serie.get("MetaData", [])
            terr = meta[0] if meta else {}
            medida = meta[1].get("Nombre") if len(meta) > 1 else None
            for punto in serie.get("Data", []):
                yield {
                    "cod_serie": serie.get("COD"),
                    "nivel": NIVELES.get(terr.get("T3_Variable"), terr.get("T3_Variable")),
                    "cod": terr.get("Codigo"),
                    "nombre": terr.get("Nombre"),
                    "medida": medida,
                    "periodo": (punto.get("Fecha") or "")[:10],  # 'AAAA-MM-DD' (primer día del mes de referencia)
                    "valor": punto.get("Valor"),
                }

    return filas


@dlt.source(name="turismo")
def turismo():
    recursos = [_tabla_resource(n, t) for n, t in TABLAS.items()]
    recursos += [_vut_resource(n, t) for n, t in VUT.items()]
    return recursos
