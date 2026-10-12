"""Elecciones al Parlamento de Canarias por sección censal (Parlamento de Canarias).

Fuente
------
El Parlamento de Canarias publica en su portal de datos abiertos (datos.parcan.es,
licencia Open Data Commons PDDL: dominio público) los resultados de las elecciones
autonómicas POR MESA, servidos por su propia API:

    https://www.parcan.es/api/resultados_electorales/{año}/{circunscripción}?format=csv

    circunscripción: 1 El Hierro, 2 Fuerteventura, 3 Gran Canaria, 4 La Gomera,
                     5 Lanzarote, 6 La Palma, 7 Tenerife (insulares) y 8 Autonómica
                     (la circunscripción regional creada por la reforma electoral
                     de 2018). Con /{municipio} detrás, solo ese municipio.

Cada fila es una mesa y candidatura: ID_MESA, ELECCION, ID_CIRCUNSCRIPCION,
CIRCUNSCRIPCION, ID_MUNICIPIO, MUNICIPIO, DISTRITO, SECCION, MESA, CENSADOS,
PAPELETAS_NULAS, VOTOS_BLANCOS, PARTIDO, SIGLAS, VOTOS. Los datos de mesa (censo,
nulos, blancos) se repiten en cada fila de candidatura: hay que tomarlos una sola vez
por ID_MESA. CSV en UTF-8 con todos los campos entrecomillados.

Cobertura: por mesa de 1995 a 2023 (ocho elecciones). Para 1983, 1987 y 1991 la API
responde 200 con el CSV vacío (y [] en JSON), el portal datos.parcan.es solo tiene
conjuntos desde 1999 y el ISTAC solo publica resultados por candidatura de las
autonómicas desde 2007: no hay fuente abierta por municipio o mesa de esas tres
elecciones, así que no se cargan. El resumen oficial por isla del Parlamento
(https://www.parcan.es/api2/resultados_electorales/{año}/resumen/?format=csv y
.../votos/) existe desde 1999 y es contra el que se cuadra.

Voto doble: desde 2019 cada elector vota dos veces, a su isla y a la lista
autonómica. Se usa la urna INSULAR (circunscripciones 1-7) porque es la elección
"de toda la vida" (comparable con 1995-2015), reparte 61 de los 70 escaños y es la
que tiene candidaturas propias de cada isla (ASG en La Gomera, AHI en El Hierro,
AMF en Fuerteventura...). Cada isla es una provincia completa en el seccionado, así
que las siete juntas cubren toda la comunidad sin solapes. La urna autonómica (8)
daría casi el mismo mapa pero con otro reparto de siglas; no se carga.

Trampas
-------
- parcan.es redirige (301) a www.parcan.es: se pide directamente a www.
- ID_MUNICIPIO trae solo los 2 últimos dígitos del código INE y sin provincia: la
  provincia sale de la isla (Las Palmas 35: Lanzarote, Fuerteventura, Gran Canaria;
  Santa Cruz de Tenerife 38: el resto) y se rellena a 3 dígitos. El Pinar de El
  Hierro viene como "01" (desde 2011) pero su código INE es 38901.
- Los residentes ausentes (CERA) van como un municipio ficticio por isla (91-97,
  "Residentes Ausentes <isla>"); hasta 2015 con distrito 01, desde 2019 con
  distrito 99: se descartan (todo municipio >= 90 y todo distrito 99).
- En 2019 los campos de texto vienen rellenos de espacios (SIGLAS "Cs       ") y el
  DISTRITO sin cero a la izquierda ("1"): se limpia todo y se rellena.
- Las siglas cambian de forma entre años (P.P. en 2015, PP el resto...): se dejan
  como vienen de la fuente.
- Mesas anuladas: la fuente trae los votos de todas las mesas escrutadas, pero el
  resultado oficial (proclamación) excluye unas pocas mesas cuya votación se anuló
  (2007: 4; 2011: 2; 2015: 2). Se localizaron porque su total, blancos, nulos y
  votos de cada candidatura son exactamente la diferencia con el oficial; se quitan
  enteras (también su censo) en MESAS_ANULADAS.
- DISTRITO (2) y SECCION (3) llevan ceros a la izquierda; MESA es la letra
  (U, A, B, C...), que se suma a la sección.

Última elección celebrada: 28 de mayo de 2023 (la siguiente toca en 2027).
"""

import csv
import time
from datetime import date
from typing import Iterable

import requests

from ingestion.autonomicas import cache

COD_CCAA = "05"
SLUG = "canarias"
FUENTE = "https://datos.parcan.es/dataset/?q=resultados+electorales"
URL = "https://www.parcan.es/api/resultados_electorales/{anio}/{circ}?format=csv"
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

_FECHAS = [date(1995, 5, 28), date(1999, 6, 13), date(2003, 5, 25), date(2007, 5, 27),
           date(2011, 5, 22), date(2015, 5, 24), date(2019, 5, 26), date(2023, 5, 28)]
_MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
          "septiembre", "octubre", "noviembre", "diciembre"]
PROCESOS = [
    {"proceso": f"A05{f.year}{f.month:02d}", "fecha": f,
     "eleccion": f"Parlamento de Canarias, {_MESES[f.month - 1]} de {f.year}"}
    for f in _FECHAS
]

# circunscripción insular -> (isla, provincia INE)
ISLAS = {
    1: ("El Hierro", "38"),
    2: ("Fuerteventura", "35"),
    3: ("Gran Canaria", "35"),
    4: ("La Gomera", "38"),
    5: ("Lanzarote", "35"),
    6: ("La Palma", "38"),
    7: ("Tenerife", "38"),
}

# (circunscripción, ID_MUNICIPIO de la fuente) -> municipio INE de 3 dígitos cuando
# no basta con rellenar con un cero.
EXCEPCIONES_MUN = {(1, "01"): "901"}  # El Pinar de El Hierro (38901)

# Mesas cuya votación no entra en el resultado oficial (año, circunscripción,
# ID_MUNICIPIO, DISTRITO, SECCION, MESA): quitarlas deja los votos a candidaturas,
# blancos, nulos y los votos de cada candidatura iguales al resumen del Parlamento.
MESAS_ANULADAS = {
    (2007, 5, "04", "02", "006", "B"),  # Arrecife
    (2007, 7, "22", "03", "003", "B"),  # Icod de los Vinos
    (2007, 3, "19", "03", "002", "A"),  # San Bartolomé de Tirajana
    (2007, 3, "31", "01", "001", "B"),  # Valsequillo de Gran Canaria
    (2011, 4, "50", "01", "001", "A"),  # Vallehermoso
    (2011, 7, "23", "01", "008", "A"),  # San Cristóbal de La Laguna
    (2015, 3, "16", "05", "034", "B"),  # Las Palmas de Gran Canaria
    (2015, 7, "23", "02", "017", "B"),  # San Cristóbal de La Laguna
}


def _anio(proceso: str) -> int:
    return int(proceso[3:7])


def _fichero(anio: int, circ: int):
    destino = cache(SLUG) / f"{anio}_{circ}.csv"
    if destino.exists() and destino.stat().st_size > 0:
        return destino
    url = URL.format(anio=anio, circ=circ)
    for intento in range(1, 6):  # servidor lento: secuencial y con reintentos
        try:
            r = requests.get(url, headers=CABECERAS, timeout=600)
            r.raise_for_status()
            if not r.content.startswith(b"ID_MESA"):
                raise ValueError(f"Respuesta inesperada de {r.url}: {r.content[:200]!r}")
            tmp = destino.with_suffix(".tmp")
            tmp.write_bytes(r.content)
            tmp.replace(destino)
            return destino
        except (requests.RequestException, ValueError):
            if intento == 5:
                raise
            time.sleep(10 * intento)
    return destino


def _filas(proceso: str) -> Iterable[tuple[str, dict]]:
    """(CUSEC, fila) de cada mesa y candidatura, sin CERA."""
    anio = _anio(proceso)
    for circ, (_, prov) in ISLAS.items():
        with open(_fichero(anio, circ), encoding="utf-8", newline="") as f:
            for r in csv.DictReader(f):
                r = {k: (v or "").strip() for k, v in r.items()}  # 2019: relleno de espacios
                mun = r["ID_MUNICIPIO"].zfill(2)
                dist = r["DISTRITO"].zfill(2)
                secc = r["SECCION"].zfill(3)
                if dist == "99" or int(mun) >= 90:
                    continue  # residentes ausentes
                if (anio, circ, mun, dist, secc, r["MESA"]) in MESAS_ANULADAS:
                    continue
                mun3 = EXCEPCIONES_MUN.get((circ, mun), mun.zfill(3))
                yield prov + mun3 + dist + secc, r


def secciones(proceso: str) -> Iterable[dict]:
    acum: dict[str, dict] = {}
    vistas: set[str] = set()
    for cusec, r in _filas(proceso):
        s = acum.setdefault(cusec, {"cod_seccion": cusec, "censo": 0, "votos_blanco": 0,
                                    "votos_nulos": 0, "votos_candidaturas": 0})
        s["votos_candidaturas"] += int(r["VOTOS"] or 0)
        if r["ID_MESA"] not in vistas:  # datos de mesa repetidos en cada candidatura
            vistas.add(r["ID_MESA"])
            s["censo"] += int(r["CENSADOS"] or 0)
            s["votos_blanco"] += int(r["VOTOS_BLANCOS"] or 0)
            s["votos_nulos"] += int(r["PAPELETAS_NULAS"] or 0)
    yield from acum.values()


def votos(proceso: str) -> Iterable[dict]:
    acum: dict[tuple[str, str], int] = {}
    for cusec, r in _filas(proceso):
        clave = (cusec, r["SIGLAS"])
        acum[clave] = acum.get(clave, 0) + int(r["VOTOS"] or 0)
    for (cusec, siglas), n in acum.items():
        yield {"cod_seccion": cusec, "siglas": siglas, "votos": n}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
