"""Fuente dlt para renta, pobreza y desigualdad.

1) INE, Encuesta de Condiciones de Vida (ECV, base 2013), tablas JSON Tempus3.
   OJO: la ECV de un año pregunta por la renta del AÑO ANTERIOR (ECV 2025 ->
   renta de 2024); la pobreza, el Gini y el S80/S20 también se calculan con esa
   renta, mientras que la carencia material y las dificultades para llegar a
   fin de mes se refieren al año de la encuesta.
     9947  renta media por persona y por unidad de consumo, por CCAA
     9949  renta media por hogar, por CCAA
     9963  tasa de riesgo de pobreza por CCAA
     76847 AROPE (objetivo Europa 2030) y sus componentes por CCAA (desde 2014)
     9990  personas según dificultades para llegar a fin de mes, por CCAA
     76846 Gini y S80/S20 por CCAA
     67240 AROPE y componentes por edad y sexo (nacional)
     76844 renta por persona y unidad de consumo por edad y sexo (nacional)

2) INE, Atlas de Distribución de Renta de los Hogares (ADRH), a partir de los
   datos tributarios (renta del año del periodo, 2015-2023):
     30824 "Indicadores de renta media": TODOS los municipios de España con sus
           distritos y secciones censales en un único CSV (~350 MB). Las tablas
           30656 y 30833...31295 son las mismas cifras partidas por provincia
           (comprobado: 30656 = Albacete, 31295 = Melilla); se usa la 30824
           porque cubre todo en una sola descarga. Solo se guardan las filas de
           municipio y de distrito (no las ~36.000 secciones).
     53689 los mismos indicadores para España, CCAA, provincias e islas.

3) Eurostat (EU-SILC), todos los países: ilc_di12 (Gini), ilc_di11 (S80/S20) y
   ilc_peps01n (AROPE, % de población).

Recursos (replace): ine_ecv_*, ine_adrh_municipios, ine_adrh_territorios,
eurostat_renta_desigualdad.
"""

import codecs
import csv
import logging

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series
from ingestion.ine import _tabla_resource

log = logging.getLogger(__name__)

TABLAS_ECV = {
    "ine_ecv_renta_ccaa": "9947",
    "ine_ecv_renta_hogar_ccaa": "9949",
    "ine_ecv_pobreza_ccaa": "9963",
    "ine_ecv_arope_ccaa": "76847",
    "ine_ecv_fin_mes_ccaa": "9990",
    "ine_ecv_gini_ccaa": "76846",
    "ine_ecv_arope_edad": "67240",
    "ine_ecv_renta_edad": "76844",
}

ADRH_CSV = "https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/{}.csv"
EUROSTAT = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"


def _numero(texto: str):
    # "14.105" -> 14105.0 (punto de miles, coma decimal); "" o '""' -> None
    texto = (texto or "").strip().strip('"')
    if not texto or texto in (".", "..", "-"):
        return None
    return float(texto.replace(".", "").replace(",", "."))


def _filas_csv(tabla_id: str):
    with requests.get(ADRH_CSV.format(tabla_id), stream=True, timeout=1800) as r:
        r.raise_for_status()
        lineas = codecs.iterdecode(r.iter_lines(), "utf-8-sig")
        lector = csv.reader(lineas, delimiter=";")
        next(lector)
        yield from lector


@dlt.source(name="renta")
def renta():
    @dlt.resource(name="ine_adrh_municipios", write_disposition="replace")
    def adrh_municipios():
        # Municipios;Distritos;Secciones;Indicadores de renta media;Periodo;Total
        lote = []
        for municipio, distrito, seccion, indicador, periodo, total in _filas_csv("30824"):
            if seccion.strip():
                continue
            cod_mun, _, nombre = municipio.partition(" ")
            cod_dis, _, nombre_dis = distrito.strip().partition(" ")
            lote.append({
                "nivel": "distrito" if distrito.strip() else "municipio",
                "cod_mun": cod_mun,
                "municipio": nombre,
                "cod_distrito": cod_dis or None,
                "distrito": nombre_dis or None,
                "indicador": indicador,
                "anio": int(periodo),
                "valor": _numero(total),
            })
            if len(lote) >= 20000:
                yield lote
                lote = []
        if lote:
            yield lote

    @dlt.resource(name="ine_adrh_territorios", write_disposition="replace")
    def adrh_territorios():
        # Total Nacional;Comunidades y Ciudades Autónomas;Provincias;Islas;Indicador;Periodo;Total
        for nacional, ccaa, provincia, isla, indicador, periodo, total in _filas_csv("53689"):
            if isla.strip():
                nivel, etiqueta = "isla", isla
            elif provincia.strip():
                nivel, etiqueta = "provincia", provincia
            elif ccaa.strip():
                nivel, etiqueta = "ccaa", ccaa
            else:
                nivel, etiqueta = "pais", nacional
            # sin códigos: nombres del INE ("Balears, Illes", "Palmas, Las"); se
            # traducen a código con las semillas ine_ccaa_nombres / ine_provincias_nombres
            yield {"nivel": nivel, "nombre": etiqueta.strip(), "ccaa": ccaa.strip() or None,
                   "provincia": provincia.strip() or None, "indicador": indicador,
                   "anio": int(periodo), "valor": _numero(total)}

    @dlt.resource(name="eurostat_renta_desigualdad", write_disposition="replace")
    def eurostat_desigualdad():
        consultas = {
            "gini": "ilc_di12?age=TOTAL&statinfo=GINI_HND",
            "s80_s20": "ilc_di11?age=TOTAL&sex=T&unit=RAT",
            "arope": "ilc_peps01n?age=TOTAL&sex=T&unit=PC",
        }
        for indicador, consulta in consultas.items():
            r = requests.get(EUROSTAT + consulta + "&format=JSON&lang=EN", timeout=180)
            r.raise_for_status()
            datos = r.json()
            etiquetas = datos["dimension"]["geo"]["category"]["label"]
            for coords, valor in parse_json_stat_series(datos):
                if valor is None:
                    continue
                yield {"indicador": indicador, "geo": coords.get("geo"), "pais": etiquetas.get(coords.get("geo")),
                       "anio": int(coords.get("time")), "valor": float(valor)}

    return [_tabla_resource(n, t) for n, t in TABLAS_ECV.items()] + [
        adrh_municipios, adrh_territorios, eurostat_desigualdad]


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("renta").run(renta()))
