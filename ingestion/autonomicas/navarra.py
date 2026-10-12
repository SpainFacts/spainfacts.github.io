"""Elecciones al Parlamento de Navarra por sección censal (Gobierno de Navarra).

Fuente: portal de datos abiertos del Gobierno de Navarra (CKAN), conjunto
«Resultados de las elecciones al Parlamento de Navarra agrupados por mesas
electorales» (Departamento de Presidencia e Igualdad; unidad responsable, la Junta
Electoral; resultados definitivos; licencia CC BY 4.0):

    https://datosabiertos.navarra.es/es/dataset/resultados-de-las-elecciones-al-parlamento-de-navarra-agrupados-por-mesas-electorales

Hay un CSV por elección (1999-2023), en UTF-8, separado por comas, una fila por mesa:

    Codcir,Codmun,Municipio,Mesa,Censo,Certif_Alta,Certif_Correc,Censo_Total,
    Votos_Electores,Votos_Interventores,Votos_Totales,Votos_Nulos,Votos_Blancos,
    <una columna por candidatura: PPN, GEROA_BAI, EH_BILDU, VOX, UPN, ..., PSN-PSOE>

Trampas:
- Formato «ancho»: cada candidatura es una columna, con nombres que cambian de una
  elección a otra. Se toman como candidaturas todas las columnas que siguen a
  Votos_Blancos, y su cabecera se usa tal cual como siglas.
- `Mesa` es «distrito-sección-mesa» (p. ej. «2-001-B»; «U» = mesa única): con la
  provincia (Codcir, 31) y el municipio (Codmun, código INE sin ceros a la izquierda)
  forma el CUSEC: 31 + mun(3) + distrito(2) + sección(3). Las letras son mesas de la
  misma sección y se suman.
- Codmun 990 «Residentes ausentes-Navarra» es el voto CERA (mesas 99-00x): se descarta.
- Codmun 901-908 son municipios segregados con código INE propio (Barañáin, Berrioplano,
  Orkoien, ...): son códigos reales, no agregados.
- `Censo_Total` = censo + certificaciones de alta (censo de escrutinio);
  `Votos_Totales` incluye a los interventores y es nulos + blancos + candidaturas.
- El fichero agregado por municipios del mismo portal tiene idénticos totales; sus
  sumas (con CERA) son el resultado oficial: UPN 92.392, PSN-PSOE 68.247,
  EH Bildu 56.535, blancos 5.860, nulos 4.632.
"""

import csv
import io
from datetime import date
from typing import Iterable

import requests

from ingestion.autonomicas import cache

COD_CCAA = "15"
SLUG = "navarra"
FUENTE = ("https://datosabiertos.navarra.es/es/dataset/"
          "resultados-de-las-elecciones-al-parlamento-de-navarra-agrupados-por-mesas-electorales")
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

URLS = {
    "A15202305": "https://datosabiertos.navarra.es/dataset/be88dde7-330c-4b86-aa5c-480514608cbd/"
                 "resource/56b7ce53-4881-475a-8c79-82da43cb01ed/download/escrutinio_parlamento_mesas_2023.csv",
}

PROCESOS = [
    {"proceso": "A15202305", "fecha": date(2023, 5, 28),
     "eleccion": "Parlamento de Navarra, mayo de 2023"},
]

COD_CERA = 990


def _filas(proceso: str) -> tuple[list[str], list[dict]]:
    """Filas del CSV por mesa (descargado una vez a la caché) y columnas de candidaturas."""
    ruta = cache(SLUG) / f"{proceso}.csv"
    if not ruta.exists():
        r = requests.get(URLS[proceso], headers=CABECERAS, timeout=120)
        r.raise_for_status()
        ruta.write_bytes(r.content)
    texto = ruta.read_bytes().decode("utf-8-sig")
    lector = csv.DictReader(io.StringIO(texto))
    columnas = lector.fieldnames or []
    partidos = columnas[columnas.index("Votos_Blancos") + 1:]
    return partidos, list(lector)


def _seccion(fila: dict) -> str | None:
    """CUSEC de la mesa, o None si es CERA o no tiene sección."""
    mun = int(fila["Codmun"])
    if mun >= COD_CERA:
        return None
    distrito, seccion, _mesa = fila["Mesa"].split("-")
    return f"{int(fila['Codcir']):02d}{mun:03d}{int(distrito):02d}{int(seccion):03d}"


def _agregado(proceso: str) -> tuple[list[str], dict[str, dict]]:
    partidos, filas = _filas(proceso)
    out: dict[str, dict] = {}
    for f in filas:
        cod = _seccion(f)
        if cod is None:
            continue
        s = out.setdefault(cod, {"censo": 0, "votos_blanco": 0, "votos_nulos": 0,
                                 "votos_candidaturas": 0, "partidos": {}})
        s["censo"] += int(f["Censo_Total"] or 0)
        s["votos_blanco"] += int(f["Votos_Blancos"] or 0)
        s["votos_nulos"] += int(f["Votos_Nulos"] or 0)
        for p in partidos:
            n = int(f[p] or 0)
            s["votos_candidaturas"] += n
            s["partidos"][p] = s["partidos"].get(p, 0) + n
    return partidos, out


def secciones(proceso: str) -> Iterable[dict]:
    _, agg = _agregado(proceso)
    for cod, s in sorted(agg.items()):
        yield {"cod_seccion": cod, "censo": s["censo"], "votos_blanco": s["votos_blanco"],
               "votos_nulos": s["votos_nulos"], "votos_candidaturas": s["votos_candidaturas"]}


def votos(proceso: str) -> Iterable[dict]:
    _, agg = _agregado(proceso)
    for cod, s in sorted(agg.items()):
        for siglas, n in s["partidos"].items():
            if n:
                yield {"cod_seccion": cod, "siglas": siglas, "votos": n}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
