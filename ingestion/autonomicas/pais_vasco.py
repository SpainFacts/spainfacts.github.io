"""Elecciones al Parlamento Vasco por sección censal (Gobierno Vasco).

Fuente: «Descarga de ficheros de resultados de elecciones» del Gobierno Vasco
(Departamento de Seguridad, Dirección de Procesos Electorales; resultados
definitivos), en el portal electoral de euskadi.eus:

    https://www.euskadi.eus/informacion/descargas-de-ficheros-de-resultados-de-elecciones/web01-a2haukon/es/

Hay un ZIP por proceso (generales, europeas, juntas generales, municipales y
Parlamento Vasco desde 1977) en CSV o en XLS. El de las autonómicas de 2024:

    https://www.euskadi.eus/contenidos/informacion/w_em_descargas/es_def/adjuntos/csv/P24_c.zip

    P24_c/CirPV24_c.csv   por territorio histórico (circunscripción)
    P24_c/MunPV24_c.csv   por municipio
    P24_c/MesPV24_c.csv   por mesa  <- el que se usa

MesPV24_c.csv: Windows-1252, separado por «;», decimales con punto, una fila por mesa,
con DOS filas de cabecera:

    fila 1: «LISTADO DE RESULTADOS POR MESA» y, encima de cada bloque de 3 columnas,
            las siglas de la candidatura (EAJ-PNV, EH BILDU, PSE-EE/PSOE, PP, ...)
    fila 2: TH;Municipio;Cod Municipio;Distrito;Sección;Mesa;Censo;Votos;Nulos;
            Válidos;Blancos;Votos Candidaturas;Abstención; y por candidatura
            «V. Candidaturas;%V. Candidaturas;%V. Válidos»

Trampas:
- Formato «ancho»: cada candidatura ocupa tres columnas (votos y dos porcentajes);
  las siglas están en la primera fila y los votos en la columna cuya cabecera de la
  segunda fila es «V. Candidaturas» (ojo: la columna 12 se llama «Votos Candidaturas»
  y es el total).
- Las candidaturas son por territorio: si una no se presenta en un territorio, sus
  celdas van vacías (no a 0). Cualquier celda vacía cuenta como 0.
- Los códigos van entre comillas con un tabulador delante («"\t051"»): hay que
  limpiarlos. Municipio (3), distrito (2) y sección (3) son los del INE; la provincia
  no viene, se saca del territorio histórico (Álava 01, Gipuzkoa 20, Bizkaia 48).
  CUSEC = prov(2) + mun(3) + distrito(2) + sección(3). La mesa es una letra
  (U = única, A/B/C/D) y las mesas de una misma sección se suman.
- CERA: cada territorio tiene un pseudo-municipio 999 «MUNICIPIO CERA ...» (distrito
  01, sección 001, mesa U) con SOLO el censo de residentes ausentes (82.911 en total)
  y los votos vacíos. Se descarta. Sin él, el censo cuadra con el de CirPV24_c.csv
  (1.712.301, censo de residentes). Los votos CERA (6.989) no están en ningún fichero
  de la descarga: el resultado oficial (informe de resultados definitivos) los incluye
  y por eso es algo mayor que la suma de las mesas.
- Usansolo: en abril de 2024 aún votó como distrito 04 de Galdakao (48036-04-001..003),
  pero el INE ya lo tiene segregado como municipio 48916 (secciones 4891601001..003 en
  el seccionado de 2024; Interior lo usa así desde las europeas de junio de 2024, con
  el mismo censo salvo ±2 en las dos primeras secciones). Se traduce con
  RECODIFICAR para que case con el INE y con el resto de procesos.
- Comprobado con las europeas de 2024 del mismo portal (E24-c.zip): sus 1.709
  secciones (sin el 999) tienen exactamente el mismo censo que las del fichero por
  mesa del Ministerio del Interior (07202406_MESA.zip), así que el censo por mesa es
  el censo de escrutinio sin CERA y los códigos son los del INE.

Resultado oficial (informe «PV24_informe_result_definitivos.pdf», Gobierno Vasco):
censo 1.795.213, votos 1.077.456, nulos 7.859, blancos 10.523, candidaturas
1.059.074; EAJ-PNV 372.456, EH Bildu 343.609, PSE-EE/PSOE 150.752.
"""

import csv
import io
import unicodedata
import zipfile
from datetime import date
from typing import Iterable

import requests

from ingestion.autonomicas import cache

COD_CCAA = "16"
SLUG = "pais_vasco"
FUENTE = ("https://www.euskadi.eus/informacion/descargas-de-ficheros-de-resultados-de-elecciones/"
          "web01-a2haukon/es/")
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

# proceso -> (URL del ZIP, fichero por mesa dentro del ZIP)
URLS = {
    "A16202404": ("https://www.euskadi.eus/contenidos/informacion/w_em_descargas/es_def/adjuntos/csv/P24_c.zip",
                  "MesPV24_c.csv"),
}

PROCESOS = [
    {"proceso": "A16202404", "fecha": date(2024, 4, 21),
     "eleccion": "Parlamento Vasco, abril de 2024"},
]

COD_CERA = "999"

# Secciones con código antiguo en la fuente -> CUSEC actual del INE (ver docstring).
RECODIFICAR = {
    "4803604001": "4891601001",
    "4803604002": "4891601002",
    "4803604003": "4891601003",
}


def _sin_tildes(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn").lower()


def _provincia(territorio: str) -> str:
    t = _sin_tildes(territorio)
    if "alava" in t or "araba" in t:
        return "01"
    if "gipuzkoa" in t or "guipuzcoa" in t:
        return "20"
    if "bizkaia" in t or "vizcaya" in t:
        return "48"
    raise ValueError(f"Territorio histórico desconocido: {territorio!r}")


def _codigo(celda: str) -> str:
    """Quita comillas, tabuladores y espacios de los códigos («"\\t051"» -> «051»)."""
    return celda.strip().strip('"').strip()


def _n(celda: str) -> int:
    celda = celda.strip()
    return int(celda) if celda else 0


def _filas(proceso: str) -> list[list[str]]:
    """Filas del CSV por mesa (el ZIP se descarga una vez a la caché)."""
    url, nombre = URLS[proceso]
    ruta = cache(SLUG) / url.rsplit("/", 1)[-1]
    if not ruta.exists():
        r = requests.get(url, headers=CABECERAS, timeout=120)
        r.raise_for_status()
        ruta.write_bytes(r.content)
    with zipfile.ZipFile(ruta) as z:
        interno = next(n for n in z.namelist() if n.rsplit("/", 1)[-1] == nombre)
        texto = z.read(interno).decode("cp1252")
    return list(csv.reader(io.StringIO(texto), delimiter=";"))


_CACHE: dict[str, dict] = {}


def _agregado(proceso: str) -> dict[str, dict]:
    if proceso in _CACHE:
        return _CACHE[proceso]
    filas = _filas(proceso)
    siglas_fila, cab = filas[0], [c.strip() for c in filas[1]]
    i = {c: cab.index(c) for c in ("TH", "Cod Municipio", "Distrito", "Mesa", "Censo",
                                   "Nulos", "Blancos", "Votos Candidaturas")}
    i_seccion = next(k for k, c in enumerate(cab) if _sin_tildes(c) == "seccion")
    partidos = [(k, siglas_fila[k].strip()) for k, c in enumerate(cab) if c == "V. Candidaturas"]

    out: dict[str, dict] = {}
    for f in filas[2:]:
        if not f or not f[0].strip():
            continue
        mun = _codigo(f[i["Cod Municipio"]])
        if mun == COD_CERA:
            continue
        distrito, seccion = _codigo(f[i["Distrito"]]), _codigo(f[i_seccion])
        if not (mun.isdigit() and distrito.isdigit() and seccion.isdigit()):
            continue
        cod = f"{_provincia(f[i['TH']])}{int(mun):03d}{int(distrito):02d}{int(seccion):03d}"
        cod = RECODIFICAR.get(cod, cod)
        s = out.setdefault(cod, {"censo": 0, "votos_blanco": 0, "votos_nulos": 0,
                                 "votos_candidaturas": 0, "partidos": {}})
        s["censo"] += _n(f[i["Censo"]])
        s["votos_blanco"] += _n(f[i["Blancos"]])
        s["votos_nulos"] += _n(f[i["Nulos"]])
        s["votos_candidaturas"] += _n(f[i["Votos Candidaturas"]])
        for k, siglas in partidos:
            n = _n(f[k])
            if n:
                s["partidos"][siglas] = s["partidos"].get(siglas, 0) + n
    _CACHE[proceso] = out
    return out


def secciones(proceso: str) -> Iterable[dict]:
    for cod, s in sorted(_agregado(proceso).items()):
        yield {"cod_seccion": cod, "censo": s["censo"], "votos_blanco": s["votos_blanco"],
               "votos_nulos": s["votos_nulos"], "votos_candidaturas": s["votos_candidaturas"]}


def votos(proceso: str) -> Iterable[dict]:
    for cod, s in sorted(_agregado(proceso).items()):
        for siglas, n in s["partidos"].items():
            yield {"cod_seccion": cod, "siglas": siglas, "votos": n}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
