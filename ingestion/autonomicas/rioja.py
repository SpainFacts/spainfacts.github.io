"""Elecciones al Parlamento de La Rioja por sección censal (Gobierno de La Rioja).

La Rioja es la única comunidad que organiza y escruta sus autonómicas con medios
propios, y el Gobierno de La Rioja publica el resultado por MESA en su catálogo de
datos abiertos (conjunto opd-374, «Elecciones autonómicas por mesas electorales»,
federado también en datos.gob.es):

    https://web.larioja.org/dato-abierto/datoabierto?n=opd-374
    https://ias1.larioja.org/opendata/download?r=Y2Q9Mzc0fGNmPTAz      (CSV)

El parámetro `r` es base64 de "cd=374|cf=03" (cd = conjunto, cf = formato:
01 XLS, 02 XML, 03 CSV, 04 JSON). Es un único CSV (~600 KB) con TODAS las
autonómicas desde 1983; solo se usa la última (28 de mayo de 2023).

Formato y trampas
-----------------
- Separador «;», codificación ISO-8859-1, fin de línea CRLF.
- Columnas fijas: Anio_Electoral; C.A.; Codigo_Municipio; Municipio; Distrito;
  Seccion; Mesa; Censo; Votos_Emitidos; Votos_Nulos; Votos_en_blanco;
  Votos_Validos; Porc_Escrutado; y después UNA COLUMNA POR CANDIDATURA de todas
  las elecciones (unión histórica, ~50 columnas), con cabecera
  "SIGLAS-DENOMINACION_TRUNCADA" (p. ej. "PSOE-PARTIDO_SOCIALISTA_OBRERO"). En una
  elección dada, las candidaturas que no se presentaron vienen vacías; las que se
  presentaron traen número (aunque sea 0). Al final hay columnas de relleno p43..p50
  sin nombre ni datos.
- Las siglas se toman de la cabecera hasta el primer «-», salvo las siglas que
  llevan guion dentro (PODEMOS-I.U., PODEMOS-IU-EQUO, CR-IU-EQUO): ver SIGLAS.
  La fuente escribe «PRxE» para el Partido Riojano + España (PR+).
- Codigo_Municipio es el número INE sin la provincia y sin ceros (1 = Ábalos =
  26001); Distrito (2) y Seccion (3) ya vienen con ceros, así que el CUSEC es
  "26" + municipio(3) + distrito + sección. La mesa (U, A, B, C) se suma a la sección.
- El voto CERA viene como municipio 200 «Residentes Ausentes» (distrito 01,
  sección 001, mesa U): se descarta. Por eso el censo y los votos de este módulo
  son los de la comunidad menos el CERA.
- El fichero por municipio (opd-373) trae además una fila de total: no se usa.
"""

import csv
import io
from datetime import date
from typing import Iterable

import requests

from ingestion.autonomicas import cache

COD_CCAA = "17"
SLUG = "rioja"
FUENTE = "https://web.larioja.org/dato-abierto/datoabierto?n=opd-374"
URL_CSV = "https://ias1.larioja.org/opendata/download?r=Y2Q9Mzc0fGNmPTAz"
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

PROCESOS = [
    {"proceso": "A17202305", "fecha": date(2023, 5, 28),
     "eleccion": "Parlamento de La Rioja, mayo de 2023"},
]

MUNICIPIO_CERA = 200
PRIMERA_CANDIDATURA = 13  # índice de la primera columna de votos por candidatura

# Cabeceras cuyas siglas llevan guion (el corte por el primer «-» las partiría).
SIGLAS = {
    "PODEMOS-I.U.-PODEMOS-IZQUIERDA": "PODEMOS-IU",
    "PODEMOS-IU-EQUO-UNIDAS_PODEMOS": "PODEMOS-IU-EQUO",
    "CR-IU-EQUO-CAMBIA_LA_RIOJA-IU-": "CR-IU-EQUO",
}


def _siglas(cabecera: str) -> str:
    s = SIGLAS.get(cabecera) or cabecera.split("-", 1)[0]
    return s.replace("_", " ").strip()


def _filas(proceso: str) -> tuple[list[str], list[list[str]]]:
    """Cabecera y filas de mesa (sin CERA) de la elección pedida."""
    anio = next(p for p in PROCESOS if p["proceso"] == proceso)["fecha"].year
    fichero = cache(SLUG) / "elecciones_mesa.csv"
    if not fichero.exists():
        r = requests.get(URL_CSV, headers=CABECERAS, timeout=120)
        r.raise_for_status()
        fichero.write_bytes(r.content)
    texto = fichero.read_bytes().decode("latin-1")
    lector = csv.reader(io.StringIO(texto), delimiter=";")
    cabecera = next(lector)
    filas = [
        f for f in lector
        if f and f[0].strip() == str(anio) and int(f[2]) != MUNICIPIO_CERA
    ]
    return cabecera, filas


def _cusec(f: list[str]) -> str:
    return f"26{int(f[2]):03d}{int(f[4]):02d}{int(f[5]):03d}"


def _int(v: str) -> int:
    return int(v) if v.strip() else 0


def secciones(proceso: str) -> Iterable[dict]:
    _, filas = _filas(proceso)
    acc: dict[str, dict] = {}
    for f in filas:
        cod = _cusec(f)
        a = acc.setdefault(cod, {"cod_seccion": cod, "censo": 0, "votos_blanco": 0,
                                 "votos_nulos": 0, "votos_candidaturas": 0})
        a["censo"] += _int(f[7])
        a["votos_nulos"] += _int(f[9])
        a["votos_blanco"] += _int(f[10])
        a["votos_candidaturas"] += _int(f[11]) - _int(f[10])  # válidos − blancos
    return list(acc.values())


def votos(proceso: str) -> Iterable[dict]:
    cabecera, filas = _filas(proceso)
    # Candidaturas presentes en esta elección: columna con algún valor no vacío.
    columnas = [
        i for i in range(PRIMERA_CANDIDATURA, len(cabecera))
        if any(i < len(f) and f[i].strip() for f in filas)
    ]
    acc: dict[tuple[str, str], int] = {}
    for f in filas:
        cod = _cusec(f)
        for i in columnas:
            clave = (cod, _siglas(cabecera[i]))
            acc[clave] = acc.get(clave, 0) + _int(f[i])
    return [{"cod_seccion": c, "siglas": s, "votos": v} for (c, s), v in acc.items()]


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
