"""Elecciones al Parlament de les Illes Balears por sección censal (IBESTAT).

Última autonómica celebrada: 28 de mayo de 2023 (la siguiente toca en mayo de 2027).

Fuente
------
El Govern (web de Processos Electorals, caib.es) solo publica un PDF resumen de 5
páginas por isla. El desglose por mesa lo difunde el Institut d'Estadística de les
Illes Balears (IBESTAT) en su API eDatos, catalogado en el portal de datos abiertos
del Govern (intranet.caib.es/opendatacataleg):

    https://ibestat.es/edatos/apis/statistical-resources/v1.0/datasets/IBESTAT/000199A_000012/~latest.csv
        Participació electoral i tipus de vot a les eleccions autonòmiques de 2023
        (electores, votantes, nulos, blancos, válidos a candidatura...)
    https://ibestat.es/edatos/apis/statistical-resources/v1.0/datasets/IBESTAT/000199A_000081/~latest.csv
        Resultats electorals segons candidatures a les eleccions autonòmiques de 2023
        (votos, % y diputados por candidatura)

Reutilización: aviso legal del IBESTAT (Llei 37/2007), citando «Font: Institut
d'Estadística de les Illes Balears (IBESTAT)». Los datos de origen son del
escrutinio (Ministerio del Interior / Junta Electoral).

Formato y trampas
-----------------
- CSV largo (una fila por territorio × medida [× candidatura]), UTF-8, cabeceras
  bilingües «#es»/«#ca». OJO: el orden de columnas difiere entre los dos cubos
  (en uno va primero #ca y en el otro #es): leer siempre por nombre.
- TERRITORIO_CODE mezcla niveles: ES53 (comunidad), ES532/ES533/ES531_072/ES531_071
  (islas), sufijo _RA (voto CERA por isla), 07001 (municipio), y
  aaaammdd_MMMMM_Dnn_Sxxx (sección) con un sufijo _MA/_MB/_MC/_MU (mesa). Se usa
  directamente el nivel sección (ya suma sus mesas), que se traduce a CUSEC:
  20230528_07040_D02_S015 → 0704002015. Los municipios ya llevan el código INE.
- El voto CERA solo aparece en los territorios *_RA de isla y nunca en una
  sección: no hay que descartarlo, simplemente no entra.
- Las celdas sin dato (candidatura que no se presentaba en esa isla) vienen vacías
  con estado M/O: se omiten.
- `siglas` = último paréntesis de CANDIDATURA#es ("Sa Unió de Formentera
  (PP-Compromís) (SA UNIÓ)" → "SA UNIÓ"). Hay dos candidaturas del PSIB: la
  general y la de Formentera con Gent per Formentera (GXF + PSIB-PSOE).
- ~55 MB entre los dos CSV; se descargan una vez a data/autonomicas_cache/baleares/.
"""

import csv
import re
from datetime import date
from typing import Iterable

import requests

from ingestion.autonomicas import cache

COD_CCAA = "04"
FUENTE = ("https://intranet.caib.es/opendatacataleg/dataset/"
          "resultados-electorales-segun-candidaturas-en-las-elecciones-autonomicas-de-2023-illes-balears-i")
PROCESOS = [
    {"proceso": "A04202305", "fecha": date(2023, 5, 28),
     "eleccion": "Parlament de les Illes Balears, mayo de 2023"},
]

_API = "https://ibestat.es/edatos/apis/statistical-resources/v1.0/datasets/IBESTAT/{cubo}/~latest.csv"
_CUBOS = {"A04202305": {"participacion": "000199A_000012", "candidaturas": "000199A_000081"}}
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}
_SECCION = re.compile(r"^\d{8}_(\d{5})_D(\d{2})_S(\d{3})$")


def _fichero(proceso: str, tipo: str):
    cubo = _CUBOS[proceso][tipo]
    destino = cache("baleares") / f"{cubo}.csv"
    if not destino.exists() or destino.stat().st_size == 0:
        r = requests.get(_API.format(cubo=cubo), headers=CABECERAS, timeout=300)
        r.raise_for_status()
        tmp = destino.with_suffix(".tmp")
        tmp.write_bytes(r.content)
        tmp.replace(destino)
    return destino


def _filas(proceso: str, tipo: str):
    """Filas con valor del nivel sección, con el CUSEC ya calculado."""
    with open(_fichero(proceso, tipo), encoding="utf-8", newline="") as f:
        for r in csv.DictReader(f):
            m = _SECCION.match(r["TERRITORIO_CODE"])
            if not m or r["OBS_VALUE"] == "":
                continue
            mun, dist, sec = m.groups()
            yield mun + dist + sec, r


def _entero(valor: str) -> int:
    return int(round(float(valor)))


def secciones(proceso: str) -> Iterable[dict]:
    medidas = {"ELECTORES": "censo", "VOTOS_VALIDOS_BLANCO": "votos_blanco",
               "VOTOS_NULOS": "votos_nulos", "VOTOS_VALIDOS_CANDIDATURA": "votos_candidaturas"}
    datos: dict[str, dict] = {}
    for cod, r in _filas(proceso, "participacion"):
        campo = medidas.get(r["MEDIDAS_CODE"])
        if campo:
            fila = datos.setdefault(cod, {"cod_seccion": cod, "censo": 0, "votos_blanco": 0,
                                          "votos_nulos": 0, "votos_candidaturas": 0})
            fila[campo] += _entero(r["OBS_VALUE"])
    yield from datos.values()


def votos(proceso: str) -> Iterable[dict]:
    acum: dict[tuple[str, str], int] = {}
    for cod, r in _filas(proceso, "candidaturas"):
        if r["MEDIDAS_CODE"] != "VOTOS_VALIDOS_CANDIDATURA" or r["CANDIDATURA_CODE"] == "_T":
            continue
        nombre = r["CANDIDATURA#es"]
        siglas = re.findall(r"\(([^()]*)\)", nombre)
        siglas = siglas[-1].strip() if siglas else nombre.strip()
        acum[(cod, siglas)] = acum.get((cod, siglas), 0) + _entero(r["OBS_VALUE"])
    for (cod, siglas), n in acum.items():
        if n:
            yield {"cod_seccion": cod, "siglas": siglas, "votos": n}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
