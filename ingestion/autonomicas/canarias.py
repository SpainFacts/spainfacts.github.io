"""Elecciones al Parlamento de Canarias por sección censal (Parlamento de Canarias).

Fuente
------
El Parlamento de Canarias publica en su portal de datos abiertos (datos.parcan.es,
licencia Open Data Commons PDDL: dominio público) los resultados de las elecciones
autonómicas desde 1983 POR MESA, servidos por su propia API:

    https://parcan.es/api/resultados_electorales/{año}/{circunscripción}?format=csv

    circunscripción: 1 El Hierro, 2 Fuerteventura, 3 Gran Canaria, 4 La Gomera,
                     5 Lanzarote, 6 La Palma, 7 Tenerife (insulares) y 8 Autonómica
                     (la circunscripción regional creada por la reforma electoral
                     de 2018). Con /{municipio} detrás, solo ese municipio.

Cada fila es una mesa y candidatura: ID_MESA, ELECCION, ID_CIRCUNSCRIPCION,
CIRCUNSCRIPCION, ID_MUNICIPIO, MUNICIPIO, DISTRITO, SECCION, MESA, CENSADOS,
PAPELETAS_NULAS, VOTOS_BLANCOS, PARTIDO, SIGLAS, VOTOS. Los datos de mesa (censo,
nulos, blancos) se repiten en cada fila de candidatura: hay que tomarlos una sola vez
por ID_MESA. CSV en UTF-8 con todos los campos entrecomillados.

Voto doble: desde 2019 cada elector vota dos veces, a su isla y a la lista
autonómica. Se usa la urna INSULAR (circunscripciones 1-7) porque es la elección
"de toda la vida" (comparable con 1983-2015), reparte 61 de los 70 escaños y es la
que tiene candidaturas propias de cada isla (ASG en La Gomera, AHI en El Hierro,
AMF en Fuerteventura...). Cada isla es una provincia completa en el seccionado, así
que las siete juntas cubren toda la comunidad sin solapes. La urna autonómica (8)
daría casi el mismo mapa pero con otro reparto de siglas; no se carga.

Trampas
-------
- ID_MUNICIPIO trae solo los 2 últimos dígitos del código INE y sin provincia: la
  provincia sale de la isla (Las Palmas 35: Lanzarote, Fuerteventura, Gran Canaria;
  Santa Cruz de Tenerife 38: el resto) y se rellena a 3 dígitos. El Pinar de El
  Hierro viene como "01" pero su código INE es 38901 (municipio creado en 2007).
- Los residentes ausentes (CERA) van como un municipio ficticio por isla (91-97,
  "Residentes Ausentes <isla>") con distrito 99 y ocho "secciones" vacías: se
  descartan (todo municipio >= 90 y todo distrito 99).
- DISTRITO (2) y SECCION (3) ya vienen con ceros a la izquierda; MESA es la letra
  (U, A, B, C...), que se suma a la sección.

Última elección celebrada: 28 de mayo de 2023 (la siguiente toca en 2027).
"""

import csv
from datetime import date
from typing import Iterable

import requests

from ingestion.autonomicas import cache

COD_CCAA = "05"
SLUG = "canarias"
FUENTE = "https://datos.parcan.es/dataset/?q=resultados+electorales+2023"
URL = "https://parcan.es/api/resultados_electorales/{anio}/{circ}?format=csv"
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

PROCESOS = [
    {"proceso": "A05202305", "fecha": date(2023, 5, 28),
     "eleccion": "Parlamento de Canarias, mayo de 2023"},
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


def _anio(proceso: str) -> int:
    return int(proceso[3:7])


def _fichero(anio: int, circ: int):
    destino = cache(SLUG) / f"{anio}_{circ}.csv"
    if not destino.exists() or destino.stat().st_size == 0:
        r = requests.get(URL.format(anio=anio, circ=circ), headers=CABECERAS, timeout=300)
        r.raise_for_status()
        if not r.content.startswith(b"ID_MESA"):
            raise ValueError(f"Respuesta inesperada de {r.url}: {r.content[:200]!r}")
        destino.write_bytes(r.content)
    return destino


def _filas(proceso: str) -> Iterable[tuple[str, dict]]:
    """(CUSEC, fila) de cada mesa y candidatura, sin CERA."""
    anio = _anio(proceso)
    for circ, (_, prov) in ISLAS.items():
        with open(_fichero(anio, circ), encoding="utf-8", newline="") as f:
            for r in csv.DictReader(f):
                mun = r["ID_MUNICIPIO"].strip()
                if r["DISTRITO"] == "99" or int(mun) >= 90:
                    continue  # residentes ausentes
                mun3 = EXCEPCIONES_MUN.get((circ, mun), mun.zfill(3))
                cusec = prov + mun3 + r["DISTRITO"].zfill(2) + r["SECCION"].zfill(3)
                yield cusec, r


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
        clave = (cusec, r["SIGLAS"].strip())
        acum[clave] = acum.get(clave, 0) + int(r["VOTOS"] or 0)
    for (cusec, siglas), n in acum.items():
        yield {"cod_seccion": cusec, "siglas": siglas, "votos": n}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
