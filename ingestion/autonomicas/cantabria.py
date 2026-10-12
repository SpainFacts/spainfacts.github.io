"""Elecciones al Parlamento de Cantabria por sección censal (Gobierno de Cantabria).

Fuente: página «Histórico Resultados Elecciones» del portal del Gobierno de Cantabria

    https://www.cantabria.es/historico-resultados-elecciones

que, para las autonómicas del 28 de mayo de 2023, enlaza el Excel del escrutinio
definitivo (DatEscrut_Def_Auto_2023_Cantabria.xls, ~350 KB, formato .xls BIFF de
Excel 97, se lee con xlrd). Contenidos del portal bajo licencia Creative Commons
Atribución 3.0 España (pie de página y aviso legal de cantabria.es).

Hojas del Excel:
    Mesas       una fila por mesa: Codcir (39), Codmun (municipio INE, 3 dígitos),
                Municipio, Mesa ("D-SSS-M": distrito-sección-letra de mesa), Censo,
                Certif. Alta, Certif. Correc., Censo Total, Votos Electores,
                Votos Interventores, Votos Totales (= votantes), Votos Nulos,
                Votos Blancos y una columna de votos por candidatura (PP, P.R.C.,
                PSC-PSOE, VOX, PODEMOS-IU...). Última fila: «Total».
    Municipios  lo mismo agregado por municipio (no se usa).

Trampas:
- La web de resultados de la noche electoral (resultados.elecciones2023.cantabria.es)
  ya no existe; el único fichero por mesa que queda es este Excel del escrutinio
  definitivo, publicado en el portal general cantabria.es con una URL de Liferay
  (carpeta/uuid) que no se puede deducir: si cambia, buscarla en la página.
- Los votos del CERA van en un municipio ficticio 990 «Residentes ausentes-Cantabria»
  con mesas "99-00N-U" (todo el voto CERA está en la primera): se descartan.
- La mesa trae distrito y sección sin ceros ("1-001-A"): CUSEC = 39 + Codmun(3)
  + distrito(2) + sección(3). Codmun es el código INE del municipio.
- No hay columna de votos a candidaturas: se calcula sumando las columnas de partido
  (cuadra con «Votos Candidaturas» de la hoja Municipios).
- Censo: «Censo Total» (censo + certificaciones de alta), como en el acta de la Junta.
- Los números vienen como float (xlrd): se convierten a int.

Resultado oficial (acta de la Junta Electoral Provincial, BOC extraordinario núm. 46
de 7-6-2023, CVE-2023-5565): 507.438 electores, 331.413 votantes, 318.919 votos a
candidaturas, 5.809 blancos, 6.685 nulos; PP 116.198, PRC 67.523, PSOE 66.917.
Sin el CERA (2.481 a candidaturas, 56 blancos, 12 nulos) la suma por sección es
316.438 / 5.753 / 6.673.
"""

from collections import defaultdict
from datetime import date
from functools import lru_cache
from typing import Iterable

import requests
import xlrd

from ingestion.autonomicas import cache

COD_CCAA = "06"
FUENTE = "https://www.cantabria.es/historico-resultados-elecciones"
SLUG = "cantabria"
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

PROCESOS = [
    {"proceso": "A06202305", "fecha": date(2023, 5, 28),
     "eleccion": "Parlamento de Cantabria, mayo de 2023"},
]

FICHEROS = {
    "A06202305": (
        "DatEscrut_Def_Auto_2023_Cantabria.xls",
        "https://www.cantabria.es/documents/16323/31095795/DatEscrut_Def_Auto_2023_Cantabria.xls/"
        "1d402f4a-a879-9e12-13c5-f297fe0b0fc8?t=1690804216170",
    ),
}

# Columnas de la hoja Mesas que no son candidaturas.
NO_PARTIDOS = {
    "Codcir", "Codmun", "Municipio", "Mesa", "Censo", "Certif. Alta", "Certif. Correc.",
    "Censo Total", "Votos Electores", "Votos Interventores", "Votos Totales",
    "Votos Nulos", "Votos Blancos",
}
MUNICIPIO_CERA = 990


def _descargar(proceso: str) -> bytes:
    nombre, url = FICHEROS[proceso]
    ruta = cache(SLUG) / nombre
    if not ruta.exists():
        r = requests.get(url, headers=CABECERAS, timeout=120)
        r.raise_for_status()
        if not r.content.startswith(b"\xd0\xcf\x11\xe0"):
            raise ValueError(f"{url} no devuelve un .xls ({r.headers.get('content-type')})")
        ruta.write_bytes(r.content)
    return ruta.read_bytes()


@lru_cache(maxsize=None)
def _agregado(proceso: str) -> tuple[dict, dict]:
    """(globales por sección, votos por sección y siglas) sumando las mesas."""
    libro = xlrd.open_workbook(file_contents=_descargar(proceso))
    hoja = libro.sheet_by_name("Mesas")
    cab = [str(c).strip() for c in hoja.row_values(0)]
    partidos = [c for c in cab if c and c not in NO_PARTIDOS]
    glob: dict[str, dict] = {}
    votos: dict[tuple[str, str], int] = defaultdict(int)
    for i in range(1, hoja.nrows):
        f = dict(zip(cab, hoja.row_values(i)))
        if not isinstance(f["Codmun"], float):  # fila «Total»
            continue
        mun = int(f["Codmun"])
        if mun == MUNICIPIO_CERA:
            continue
        distrito, seccion, _mesa = str(f["Mesa"]).split("-")
        cod = f"{int(f['Codcir']):02d}{mun:03d}{int(distrito):02d}{int(seccion):03d}"
        g = glob.setdefault(cod, {"cod_seccion": cod, "censo": 0, "votos_blanco": 0,
                                  "votos_nulos": 0, "votos_candidaturas": 0})
        g["censo"] += int(f["Censo Total"])
        g["votos_blanco"] += int(f["Votos Blancos"])
        g["votos_nulos"] += int(f["Votos Nulos"])
        for p in partidos:
            n = int(f[p] or 0)
            g["votos_candidaturas"] += n
            votos[(cod, p)] += n
    return glob, dict(votos)


def secciones(proceso: str) -> Iterable[dict]:
    glob, _ = _agregado(proceso)
    yield from glob.values()


def votos(proceso: str) -> Iterable[dict]:
    _, v = _agregado(proceso)
    for (cod, siglas), n in v.items():
        if n:
            yield {"cod_seccion": cod, "siglas": siglas, "votos": n}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
