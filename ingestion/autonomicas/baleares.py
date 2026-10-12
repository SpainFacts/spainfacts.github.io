"""Elecciones al Parlament de les Illes Balears por sección censal (IBESTAT), 1983-2023.

Todas las autonómicas celebradas: 1983, 1987, 1991, 1995, 1999, 2003, 2007, 2011,
2015, 2019 y 2023 (la siguiente toca en mayo de 2027). Todas tienen desglose por
sección y mesa, así que no hace falta municipios()/votos_municipios().

Fuente
------
El Govern (web de Processos Electorals, caib.es, «Resultats al Parlament») solo
publica un PDF resumen de 5 páginas por elección. El desglose por mesa lo difunde el
Institut d'Estadística de les Illes Balears (IBESTAT) en su API eDatos (operación
000199A, catalogada en el portal de datos abiertos del Govern), dos cubos por
elección:

    https://ibestat.es/edatos/apis/statistical-resources/v1.0/datasets/IBESTAT/<cubo>/~latest.csv
        000199A_000002 ... 000199A_000012   Participació electoral i tipus de vot a les
                                             eleccions autonòmiques de 1983 ... 2023
        000199A_000071 ... 000199A_000081   Resultats electorals segons candidatures a les
                                             eleccions autonòmiques de 1983 ... 2023
    (el cubo de candidaturas es el de participación + 69; ojo: 000013-000017 y
    000082-000086 son los Consells Insulars, no el Parlament)

Reutilización: aviso legal del IBESTAT (Llei 37/2007), citando «Font: Institut
d'Estadística de les Illes Balears (IBESTAT)». Los datos de origen son del
escrutinio (Ministerio del Interior / Junta Electoral).

Formato y trampas
-----------------
- CSV largo (una fila por territorio × medida [× candidatura]), UTF-8, cabeceras
  bilingües «#es»/«#ca». OJO: el orden de columnas difiere entre cubos (en unos va
  primero #ca y en otros #es): leer siempre por nombre.
- TERRITORIO_CODE mezcla niveles: ES53 (comunidad), ES532/ES533/ES531_072/ES531_071
  (islas), sufijo _RA (voto CERA por isla; filas desde 1999, con datos desde 2007), 07001 (municipio, código INE
  actual), aaaammdd_MMMMM_Dnn (distrito) y aaaammdd_MMMMM_Dnn_Sxxx (sección) con un
  sufijo _MA/_MB/_MC/_MU (mesa). Se usa el nivel sección (ya suma sus mesas), que se
  traduce a CUSEC: 20230528_07040_D02_S015 → 0704002015. La fecha del prefijo es la
  de la elección.
- 1983: Palma trae una pseudo-sección «Districte 99, Secció 001» (840 electores,
  138 votos a candidaturas) sin desglose por candidatura en ese nivel: no es una
  sección real y se descarta (sus votos solo están en el total de Palma).
- La fila ES53 NO siempre es la suma de las secciones: en 2007-2023 la diferencia
  es exactamente el voto CERA (filas _RA); en 1983-1995 ES53 es otro recuento (el de
  la proclamación) y difiere en unos cientos de votos de las actas por mesa. El PDF
  del Govern cuadra al voto con la suma de secciones en 1987-2003. En 1999 y 2003 el
  CERA no aparece separado (ni _RA ni diferencia con ES53).
- El voto CERA solo aparece en territorios *_RA de isla y nunca en una sección.
- Las celdas sin dato (candidatura que no se presentaba en esa isla) vienen vacías
  con estado M/O: se omiten.
- `siglas` = último paréntesis (equilibrado) de CANDIDATURA#es: "Sa Unió de
  Formentera (PP-Compromís) (SA UNIÓ)" → "SA UNIÓ", y en 2007 "Partido Balear
  (PB(M))" → "PB(M)" (una regex de paréntesis simples daría "M"). Varias
  candidaturas comparten siglas en una misma elección (1995: tres «IU», una por
  isla) y se suman.
- 1983 y 1987: 66 municipios (Ariany, 07902, aún dentro de Petra); desde 1991, 67.
- ~640 MB entre los 22 CSV; se descargan una vez a data/autonomicas_cache/baleares/
  (~2 min la primera vez).
"""

import csv
import re
from datetime import date
from typing import Iterable

import requests

from ingestion.autonomicas import cache

COD_CCAA = "04"
FUENTE = "https://ibestat.es/edatos/apis/statistical-resources/v1.0/datasets/IBESTAT?query=ID%20LIKE%20%27000199A%27"

_ELECCIONES = [  # (fecha, nº del cubo de participación; el de candidaturas es +69)
    (date(1983, 5, 8), 2), (date(1987, 6, 10), 3), (date(1991, 5, 26), 4),
    (date(1995, 5, 28), 5), (date(1999, 6, 13), 6), (date(2003, 5, 25), 7),
    (date(2007, 5, 27), 8), (date(2011, 5, 22), 9), (date(2015, 5, 24), 10),
    (date(2019, 5, 26), 11), (date(2023, 5, 28), 12),
]
_MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
          "septiembre", "octubre", "noviembre", "diciembre"]
PROCESOS = [
    {"proceso": f"A04{f:%Y%m}", "fecha": f,
     "eleccion": f"Parlament de les Illes Balears, {_MESES[f.month - 1]} de {f.year}"}
    for f, _ in _ELECCIONES
]

_API = "https://ibestat.es/edatos/apis/statistical-resources/v1.0/datasets/IBESTAT/{cubo}/~latest.csv"
_CUBOS = {f"A04{f:%Y%m}": {"participacion": f"000199A_{n:06d}", "candidaturas": f"000199A_{n + 69:06d}"}
          for f, n in _ELECCIONES}
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}
_SECCION = re.compile(r"^\d{8}_(\d{5})_D(\d{2})_S(\d{3})$")


def _fichero(proceso: str, tipo: str):
    cubo = _CUBOS[proceso][tipo]
    destino = cache("baleares") / f"{cubo}.csv"
    if not destino.exists() or destino.stat().st_size == 0:
        r = requests.get(_API.format(cubo=cubo), headers=CABECERAS, timeout=600)
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
            if dist == "99":  # pseudo-sección de Palma en 1983 (ver arriba)
                continue
            yield mun + dist + sec, r


def _entero(valor: str) -> int:
    return int(round(float(valor)))


def _siglas(nombre: str) -> str:
    """Contenido del último paréntesis equilibrado al final del nombre."""
    s = nombre.strip()
    if s.endswith(")"):
        nivel = 0
        for i in range(len(s) - 1, -1, -1):
            if s[i] == ")":
                nivel += 1
            elif s[i] == "(":
                nivel -= 1
                if nivel == 0:
                    return s[i + 1:-1].strip()
    return s


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
        siglas = _siglas(r["CANDIDATURA#es"])
        acum[(cod, siglas)] = acum.get((cod, siglas), 0) + _entero(r["OBS_VALUE"])
    for (cod, siglas), n in acum.items():
        if n:
            yield {"cod_seccion": cod, "siglas": siglas, "votos": n}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
