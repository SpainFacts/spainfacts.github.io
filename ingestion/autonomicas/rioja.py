"""Elecciones al Parlamento de La Rioja por sección censal, 1983-2023 (Gobierno de La Rioja).

La Rioja es la única comunidad que organiza y escruta sus autonómicas con medios
propios, y el Gobierno de La Rioja publica el resultado por MESA en su catálogo de
datos abiertos (conjunto opd-374, «Elecciones autonómicas por mesas electorales»,
federado también en datos.gob.es):

    https://web.larioja.org/dato-abierto/datoabierto?n=opd-374
    https://ias1.larioja.org/opendata/download?r=Y2Q9Mzc0fGNmPTAz      (CSV)

El parámetro `r` es base64 de "cd=374|cf=03" (cd = conjunto, cf = formato:
01 XLS, 02 XML, 03 CSV, 04 JSON). Es un único CSV (~600 KB) con TODAS las
autonómicas desde 1983 (las once, de 1983 a 2023), todas por mesa.

El mismo resultado por municipio es el conjunto opd-373 (cd=373, ~220 KB):

    https://web.larioja.org/dato-abierto/datoabierto?n=opd-373
    https://ias1.larioja.org/opendata/download?r=Y2Q9MzczfGNmPTAz      (CSV)

Histórico
---------
- 1983-2023 salvo 2011: por sección (mesas del opd-374).
- 2011: SOLO por municipio (opd-373). En el fichero por mesa de 2011 las columnas de
  UPyD (5.891 votos) y de Verdes de La Rioja-Ecolo (ECOLO-VERDE, 2.041) vienen
  vacías aunque se presentaron; sus votos sí están dentro de Votos_Validos. El
  fichero por municipio sí las trae. secciones()/votos() devuelven [] para 2011.
- Fechas: 8-5-1983, 10-6-1987, 26-5-1991, 28-5-1995, 13-6-1999, 25-5-2003,
  27-5-2007, 22-5-2011, 24-5-2015, 26-5-2019, 28-5-2023 (ojo: la Wikipedia da mal
  las de 1983 y 2007).
- El opd-373 trae una fila de total (Codigo_Municipio 0) que es el resultado
  oficial del escrutinio general (coincide con la Wikipedia). Hasta 2007 la suma de
  mesas difiere de ese total en unas decenas o cientos de votos por partido (el
  escrutinio general corrigió actas; en 2007 el total incluye además el CERA, que va
  en la fila 200 del fichero por municipio y no está en el de mesas). No se corrige:
  se dan las mesas tal cual.

Formato y trampas
-----------------
- Separador «;», codificación ISO-8859-1, fin de línea CRLF.
- Columnas fijas: Anio_Electoral; C.A.; Codigo_Municipio; Municipio; Distrito;
  Seccion; Mesa; Censo; Votos_Emitidos; Votos_Nulos; Votos_en_blanco;
  Votos_Validos; Porc_Escrutado; y después UNA COLUMNA POR CANDIDATURA de todas
  las elecciones (unión histórica, ~50 columnas), con cabecera
  "SIGLAS-DENOMINACION_TRUNCADA" (p. ej. "PSOE-PARTIDO_SOCIALISTA_OBRERO"). En una
  elección dada, las candidaturas que no se presentaron vienen vacías; las que se
  presentaron traen número (aunque sea 0): solo se toman las que traen algún número
  en esa elección. Al final hay columnas de relleno p43..p50 sin nombre ni datos.
- Las siglas se toman de la cabecera hasta el primer «-», salvo las siglas que
  llevan guion dentro (PTE-UC, ECOLO-VERDE, PODEMOS-I.U., PODEMOS-IU-EQUO,
  CR-IU-EQUO): ver SIGLAS. Las siglas cambian de una elección a otra tal como las
  escribe la fuente (AP en 1983-87, I.U. en 2011, PRx en 2015-19, «PRxE» = PR+ en
  2023, AR., IZQ., P.C.P.E....).
- Codigo_Municipio es el número INE sin la provincia y sin ceros (1 = Ábalos =
  26001); Distrito (2) y Seccion (3) ya vienen con ceros, así que el CUSEC es
  "26" + municipio(3) + distrito + sección. La mesa (U, A, B, C, D) se suma a la
  sección. En 1983 solo hay mesas A/B (las secciones de una sola mesa se llaman A).
- El voto CERA viene como municipio 200 «Residentes Ausentes» (desde 2011 en el
  fichero por mesa; en 2007 solo en el de municipio) y, de 1991 a 2003, como una
  mesa de Logroño con distrito 99 y sección 999 (2608999999, que no existe): se
  descartan los dos. En 1983 y 1987 no hay CERA aparte. Por eso el censo y los votos
  de este módulo son los de la comunidad menos el CERA.
- votos_candidaturas es la suma de las columnas de partido de la mesa (no
  Votos_Validos − Votos_en_blanco): en dos actas antiguas (1991 Logroño 03-021-B y
  2003 Lardero 01-001-A) los válidos no cuadran con los partidos por 1-2 votos.
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
URL_CSV_MUNICIPIO = "https://ias1.larioja.org/opendata/download?r=Y2Q9MzczfGNmPTAz"
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

_MESES = ["", "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
          "agosto", "septiembre", "octubre", "noviembre", "diciembre"]
_FECHAS = [date(1983, 5, 8), date(1987, 6, 10), date(1991, 5, 26), date(1995, 5, 28),
           date(1999, 6, 13), date(2003, 5, 25), date(2007, 5, 27), date(2011, 5, 22),
           date(2015, 5, 24), date(2019, 5, 26), date(2023, 5, 28)]
PROCESOS = [
    {"proceso": f"A17{d:%Y%m}", "fecha": d,
     "eleccion": f"Parlamento de La Rioja, {_MESES[d.month]} de {d.year}"}
    for d in _FECHAS
]
# Elecciones cuyo fichero por mesa está incompleto: van por municipio (opd-373).
SOLO_MUNICIPIO = {"A17201105"}

MUNICIPIO_CERA = 200
SECCION_CERA = ("99", "999")  # 1991-2003: el CERA va como Logroño, distrito 99, sección 999
PRIMERA_CANDIDATURA = 13      # índice de la primera columna de partido (por mesa)
PRIMERA_CANDIDATURA_MUN = 11  # ídem en el fichero por municipio

# Cabeceras cuyas siglas llevan guion (el corte por el primer «-» las partiría).
SIGLAS = {
    "PTE-UC-P.TRABAJADORES_ESPANA-U": "PTE-UC",
    "ECOLO-VERDE-COALICION_VERDES_D": "ECOLO-VERDE",
    "PODEMOS-I.U.-PODEMOS-IZQUIERDA": "PODEMOS-IU",
    "PODEMOS-IU-EQUO-UNIDAS_PODEMOS": "PODEMOS-IU-EQUO",
    "CR-IU-EQUO-CAMBIA_LA_RIOJA-IU-": "CR-IU-EQUO",
}


def _siglas(cabecera: str) -> str:
    s = SIGLAS.get(cabecera) or cabecera.split("-", 1)[0]
    return s.replace("_", " ").strip()


def _csv(nombre: str, url: str) -> tuple[list[str], list[list[str]]]:
    """Cabecera y filas de uno de los dos CSV (descargado una vez a la caché)."""
    fichero = cache(SLUG) / nombre
    if not fichero.exists():
        r = requests.get(url, headers=CABECERAS, timeout=120)
        r.raise_for_status()
        fichero.write_bytes(r.content)
    lector = csv.reader(io.StringIO(fichero.read_bytes().decode("latin-1")), delimiter=";")
    cabecera = next(lector)
    return cabecera, [f for f in lector if f]


def _anio(proceso: str) -> str:
    return str(next(p for p in PROCESOS if p["proceso"] == proceso)["fecha"].year)


def _columnas(cabecera: list[str], filas: list[list[str]], primera: int) -> list[int]:
    """Candidaturas presentes en la elección: columna con algún valor no vacío."""
    return [i for i in range(primera, len(cabecera))
            if any(i < len(f) and f[i].strip() for f in filas)]


def _int(v: str) -> int:
    return int(v) if v.strip() else 0


def _celda(f: list[str], i: int) -> int:
    return _int(f[i]) if i < len(f) else 0


# --- Por sección (opd-374) -----------------------------------------------------

def _filas(proceso: str) -> tuple[list[str], list[list[str]]]:
    """Cabecera y filas de mesa (sin CERA) de la elección pedida."""
    anio = _anio(proceso)
    cabecera, filas = _csv("elecciones_mesa.csv", URL_CSV)
    return cabecera, [f for f in filas
                      if f[0].strip() == anio and int(f[2]) != MUNICIPIO_CERA
                      and (f[4].strip(), f[5].strip()) != SECCION_CERA]


def _cusec(f: list[str]) -> str:
    return f"26{int(f[2]):03d}{int(f[4]):02d}{int(f[5]):03d}"


def secciones(proceso: str) -> Iterable[dict]:
    if proceso in SOLO_MUNICIPIO:
        return []
    cabecera, filas = _filas(proceso)
    columnas = _columnas(cabecera, filas, PRIMERA_CANDIDATURA)
    acc: dict[str, dict] = {}
    for f in filas:
        cod = _cusec(f)
        a = acc.setdefault(cod, {"cod_seccion": cod, "censo": 0, "votos_blanco": 0,
                                 "votos_nulos": 0, "votos_candidaturas": 0})
        a["censo"] += _int(f[7])
        a["votos_nulos"] += _int(f[9])
        a["votos_blanco"] += _int(f[10])
        a["votos_candidaturas"] += sum(_celda(f, i) for i in columnas)
    return list(acc.values())


def votos(proceso: str) -> Iterable[dict]:
    if proceso in SOLO_MUNICIPIO:
        return []
    cabecera, filas = _filas(proceso)
    columnas = _columnas(cabecera, filas, PRIMERA_CANDIDATURA)
    acc: dict[tuple[str, str], int] = {}
    for f in filas:
        cod = _cusec(f)
        for i in columnas:
            clave = (cod, _siglas(cabecera[i]))
            acc[clave] = acc.get(clave, 0) + _celda(f, i)
    return [{"cod_seccion": c, "siglas": s, "votos": v} for (c, s), v in acc.items()]


# --- Por municipio (opd-373), solo para SOLO_MUNICIPIO ---------------------------
# Columnas: Anio_Electoral; C.A.; Codigo_Municipio; Municipio; Num_Mesas; Censo;
# Votos_Emitidos; Votos_Nulos; Votos_en_blanco; Votos_Validos; Porc_Escrutado; y las
# mismas columnas de candidatura que el fichero por mesa. Codigo_Municipio 0 es el
# total de la comunidad y 200 el CERA: fuera los dos.

def _filas_municipio(proceso: str) -> tuple[list[str], list[list[str]]]:
    anio = _anio(proceso)
    cabecera, filas = _csv("elecciones_municipio.csv", URL_CSV_MUNICIPIO)
    return cabecera, [f for f in filas if f[0].strip() == anio
                      and int(f[2]) not in (0, MUNICIPIO_CERA)]


def municipios(proceso: str) -> Iterable[dict]:
    if proceso not in SOLO_MUNICIPIO:
        return []
    cabecera, filas = _filas_municipio(proceso)
    columnas = _columnas(cabecera, filas, PRIMERA_CANDIDATURA_MUN)
    return [{"cod_mun": f"26{int(f[2]):03d}", "censo": _int(f[5]),
             "votos_blanco": _int(f[8]), "votos_nulos": _int(f[7]),
             "votos_candidaturas": sum(_celda(f, i) for i in columnas)}
            for f in filas]


def votos_municipios(proceso: str) -> Iterable[dict]:
    if proceso not in SOLO_MUNICIPIO:
        return []
    cabecera, filas = _filas_municipio(proceso)
    columnas = _columnas(cabecera, filas, PRIMERA_CANDIDATURA_MUN)
    acc: dict[tuple[str, str], int] = {}
    for f in filas:
        cod = f"26{int(f[2]):03d}"
        for i in columnas:
            clave = (cod, _siglas(cabecera[i]))
            acc[clave] = acc.get(clave, 0) + _celda(f, i)
    return [{"cod_mun": c, "siglas": s, "votos": v} for (c, s), v in acc.items()]


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
