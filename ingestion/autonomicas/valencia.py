"""Elecciones a Les Corts Valencianes por sección censal (Comunitat Valenciana).

Fuente: portal de datos abiertos de la Generalitat Valenciana (dadesobertes.gva.es),
conjunto «Resultados de elecciones a Les Corts 2023» (pre-result-elec-autonom-2023),
licencia CC BY 4.0. Un único CSV con el escrutinio definitivo desglosado por mesa:

    https://dadesobertes.gva.es/dataset/dfbe99da-62d8-4be9-86bd-4ac965abfe03/resource/60f818a5-9ae2-483a-ad31-f61b8d016513/download/resultados-elecciones-autonomicas-1-2023.csv

(~13 MB, ~97.000 filas). Hay conjuntos equivalentes para todas las autonómicas
desde 1987 (pre-result-elec-autonom-aaaa); aquí solo se carga la última, la del
28 de mayo de 2023 (la siguiente toca en 2027).

Formato
-------
CSV separado por comas, codificación ISO-8859-1 (no UTF-8), cabecera en valenciano:

    Any, CProv, Desc_Prov, CMun, Codimuni, Desc_municipi, CCom, Desc_Comarca,
    CodiMesa, Districte, Secció, Mesa, CENS, VOTANTS, V_NULS, V_BLANC, V_CAND,
    CODI_CANDIDATURA, SIGLES_CANDIDATURA, DESC_CANDIDATURA

Una fila por mesa y candidatura: los datos de la mesa (CENS, VOTANTS, V_NULS,
V_BLANC) se repiten en cada fila de candidatura; V_CAND son los votos de ESA
candidatura en la mesa, no el total de votos a candidaturas.

Trampas
-------
- Los códigos van sin ceros a la izquierda: Codimuni = 3001 es el municipio INE
  03001; Districte = 1 y Secció = 1 son "01" y "001". El CUSEC se forma con
  Codimuni (5) + Districte (2) + Secció (3). La letra de mesa (U, A, B, C, D) se
  suma a la sección.
- El voto de los residentes ausentes (CERA) va como un municipio más por provincia
  (CMun 990, Codimuni 3990 / 12990 / 46990, Districte 99, «Residentes ausentes-…»):
  se descarta. Los totales del fichero incluyen el CERA y cuadran con el escrutinio
  oficial; sin él faltan ~125.700 de censo y ~10.100 votantes.
- La misma candidatura sale con dos siglas: «Cs» y «CS» (Ciudadanos, en una
  provincia). Se unifican en «Cs».
- Las siglas «CENTRO MODERADO» llevan la denominación «LOS VERDES-ECOPACIFISTAS»
  (así figura en la fuente; las Corts la publican como Los Verdes-Ecopacifistas).
  Se dejan tal cual: la familia política se asigna en dbt.
- Ocho mesas de Castellón tienen VOTANTS ≠ nulos + blancos + candidaturas por
  ±1-5 votos (errores de acta); se toman los votos tal cual.
- Una mesa de Novelda (01-004-A) viene con todo a cero; se deja.
"""

import csv
import io
from collections.abc import Iterable
from datetime import date

import requests

from ingestion.autonomicas import cache

COD_CCAA = "10"
SLUG = "valencia"
FUENTE = "https://dadesobertes.gva.es/es/dataset/pre-result-elec-autonom-2023"
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

PROCESOS = [
    {"proceso": "A10202305", "fecha": date(2023, 5, 28),
     "eleccion": "Corts Valencianes, mayo de 2023"},
]

URLS = {
    "A10202305": "https://dadesobertes.gva.es/dataset/dfbe99da-62d8-4be9-86bd-4ac965abfe03/"
                 "resource/60f818a5-9ae2-483a-ad31-f61b8d016513/download/"
                 "resultados-elecciones-autonomicas-1-2023.csv",
}

SIGLAS = {"CS": "Cs"}


def _filas(proceso: str) -> list[dict]:
    """Filas del CSV (descargado una vez y guardado en la caché)."""
    ruta = cache(SLUG) / f"{proceso}.csv"
    if not ruta.exists():
        r = requests.get(URLS[proceso], headers=CABECERAS, timeout=300)
        r.raise_for_status()
        ruta.write_bytes(r.content)
    texto = ruta.read_bytes().decode("latin-1")
    return list(csv.DictReader(io.StringIO(texto)))


def _seccion(fila: dict) -> str | None:
    """CUSEC del INE de la fila, o None si es CERA o no tiene sección real."""
    if fila["Districte"].strip() == "99" or int(fila["CMun"]) >= 990:
        return None
    try:
        return (f"{int(fila['Codimuni']):05d}{int(fila['Districte']):02d}"
                f"{int(fila['Secció']):03d}")
    except ValueError:
        return None


def secciones(proceso: str) -> Iterable[dict]:
    mesas: dict[tuple, tuple[str, dict]] = {}
    votos_cand: dict[tuple, int] = {}
    for f in _filas(proceso):
        sec = _seccion(f)
        if sec is None:
            continue
        clave = (f["Codimuni"], f["CodiMesa"])
        mesas[clave] = (sec, f)
        votos_cand[clave] = votos_cand.get(clave, 0) + int(f["V_CAND"] or 0)
    tot: dict[str, dict] = {}
    for clave, (sec, f) in mesas.items():
        t = tot.setdefault(sec, {"cod_seccion": sec, "censo": 0, "votos_blanco": 0,
                                 "votos_nulos": 0, "votos_candidaturas": 0})
        t["censo"] += int(f["CENS"] or 0)
        t["votos_blanco"] += int(f["V_BLANC"] or 0)
        t["votos_nulos"] += int(f["V_NULS"] or 0)
        t["votos_candidaturas"] += votos_cand[clave]
    return list(tot.values())


def votos(proceso: str) -> Iterable[dict]:
    tot: dict[tuple, int] = {}
    for f in _filas(proceso):
        sec = _seccion(f)
        if sec is None:
            continue
        siglas = f["SIGLES_CANDIDATURA"].strip()
        siglas = SIGLAS.get(siglas, siglas)
        tot[(sec, siglas)] = tot.get((sec, siglas), 0) + int(f["V_CAND"] or 0)
    return [{"cod_seccion": s, "siglas": g, "votos": n} for (s, g), n in tot.items()]


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
