"""Fuente dlt para comparar las ciudades españolas con las europeas (tema `ciudades`).

1) Eurostat, Urban Audit (estadísticas de ciudades, tablas urb_c*): unos 900 municipios
   europeos de más de 50.000 habitantes con las mismas definiciones; en España, unas 110
   ciudades (las que la Comisión Europea define como «city», que suelen coincidir con el
   municipio). Solo los códigos de ciudad (ES001C), no los de ciudad funcional (ES001F) ni
   los de «greater city» (ES001K). Cobertura irregular: no todas las ciudades tienen todos
   los años, por eso las páginas comparan el último dato de cada ciudad. Se han dejado
   fuera indicadores con definiciones incoherentes entre países (alquiler por m², tamaño
   medio del hogar, variación anual de la población: Berlín con 0,12 personas por hogar o
   9 €/m² de alquiler al año frente a 160 € en Madrid).
2) Eurostat, encuesta de percepción sobre la calidad de vida en las ciudades europeas
   (urb_percep, 2004-2023): ~80-100 ciudades, de ellas cuatro españolas (Madrid, Barcelona,
   Málaga y Oviedo). Porcentajes de cada respuesta; dbt suma «muy» y «bastante» de acuerdo.
3) GISCO (Eurostat): punto de etiqueta de cada ciudad (URAU_LB_2021_4326_CITIES), para
   situarlas en el mapa, con su NUTS3.

El catálogo (nombre, unidad, apartado, sentido y qué códigos se suman) es el seed
ciudades_indicadores; aquí solo se piden los códigos que usa.

Recursos (replace): ciudades_urban_audit, ciudades_gisco.
"""

import logging
import re
import time

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series

log = logging.getLogger(__name__)

EUROSTAT_URL = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
GISCO_URL = "https://gisco-services.ec.europa.eu/distribution/v2/urau/geojson/URAU_LB_2021_4326_CITIES.geojson"
CABECERAS = {"User-Agent": "SpainFacts (https://spainfacts.github.io)"}
DESDE = 1990

# tabla de Eurostat -> códigos indic_ur que se descargan (ver seed ciudades_indicadores)
CODIGOS = {
    "urb_cpop1": ["DE1001V"],
    "urb_cpopstr": ["DE1073V"],
    "urb_cpopcb": ["DE2009I", "DE2007I"],
    "urb_cfermor": ["SA2007I", "SA2029I", "SA2004I"],
    "urb_clma": ["EC1020I"],
    "urb_clivcon": ["DE3002I", "SA1053V"],
    "urb_ctran": ["TT1057I", "TT1060I"],
    "urb_ceduc": ["TE2031I"],
    "urb_percep": [
        "PS3360V", "PS3361V",  # satisfecho de vivir en la ciudad
        "PS3514V", "PS3515V",  # seguro andando solo de noche
        "PS2012V", "PS2013V",  # fácil encontrar un buen empleo
        "PS2032V", "PS2033V",  # fácil encontrar buena vivienda a precio razonable
        "PS3260V", "PS3261V",  # satisfecho con la calidad del aire
        "PS1012V", "PS1013V",  # satisfecho con el transporte público
        "PS1052V", "PS1053V",  # satisfecho con las zonas verdes
        "PS3092V", "PS3093V",  # se puede confiar en la mayoría de la gente
        "PS3611V", "PS3612V",  # hay corrupción en la administración local
    ],
}

# Código de ciudad de Urban Audit: país (2 letras) + 3 cifras + C (ES001C)
CIUDAD = re.compile(r"[A-Z]{2}[0-9]{3}C")


def _get(url: str, intentos: int = 4) -> requests.Response:
    for i in range(intentos):
        try:
            r = requests.get(url, timeout=300, headers=CABECERAS)
            r.raise_for_status()
            return r
        except requests.RequestException as e:
            if i == intentos - 1:
                raise
            log.warning("Reintento %s de %s: %s", i + 1, url, e)
            time.sleep(5 * (i + 1))


@dlt.source(name="ciudades")
def ciudades():
    @dlt.resource(name="ciudades_urban_audit", write_disposition="replace")
    def urban_audit():
        for tabla, codigos in CODIGOS.items():
            filtro = "&".join(f"indic_ur={c}" for c in codigos)
            datos = _get(f"{EUROSTAT_URL}{tabla}?{filtro}&sinceTimePeriod={DESDE}&format=JSON&lang=EN").json()
            nombres = datos["dimension"]["cities"]["category"].get("label", {})
            filas = [{
                "tabla": tabla,
                "indic_ur": c["indic_ur"],
                "cod_ciudad": c["cities"],
                "nombre_eurostat": nombres.get(c["cities"]),
                "anio": int(c["time"][:4]),
                "valor": float(v),
            } for c, v in parse_json_stat_series(datos) if v is not None and CIUDAD.fullmatch(c["cities"])]
            if not filas:
                raise ValueError(f"Urban Audit sin datos de ciudades en {tabla}")
            log.info("Urban Audit %s: %s filas", tabla, len(filas))
            yield filas

    @dlt.resource(name="ciudades_gisco", write_disposition="replace")
    def gisco():
        for f in _get(GISCO_URL).json()["features"]:
            p = f["properties"]
            if not CIUDAD.fullmatch(p["URAU_CODE"] or ""):
                continue
            lon, lat = f["geometry"]["coordinates"]
            yield {"cod_ciudad": p["URAU_CODE"], "nombre": p["URAU_NAME"], "pais_gisco": p["CNTR_CODE"],
                   "nuts3": p["NUTS3_2021"], "capital": p["CITY_CPTL"] == "Y", "superficie_km2": p["AREA_SQM"],
                   "lon": lon, "lat": lat}

    return [urban_audit, gisco]


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("ciudades").run(ciudades()))
