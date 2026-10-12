"""Elecciones a la Asamblea de Madrid por sección censal (Comunidad de Madrid).

Fuente: portal de datos abiertos de la Comunidad de Madrid (CKAN), conjunto
«Datos electorales elecciones autonómicas Comunidad de Madrid 2023», licencia
CC BY 4.0:

    https://datos.comunidad.madrid/dataset/datos_electorales_elecciones_autonomicas_comunidad_de_madrid_2023

Se descarga el recurso CSV por su enlace directo de CKAN (el portal a veces pone un
captcha en la vista de descarga; el enlace /resource/<id>/download/ no lo tiene). Hay
también un JSON con lo mismo (4 MB) y un CSV de candidaturas (siglas -> nombre).

Formato del CSV (una fila por MESA, ~7.170 filas, ~0,6 MB):
    cod_muni;Municipio;Distrito;Seccion;Mesa;Censo;Certif_alta;Certif_correc.;Electores;
    Votos_electores;Votos_Interventores;Votos_blancos;Votos_nulos;Votos_total;<siglas>...

Trampas:
- Codificación Windows-1252 (no UTF-8), separador «;», fin de línea CRLF.
- cod_muni es el código INE del municipio SIN la provincia y sin ceros (1 = La Acebeda
  28001; 901-903 son los municipios segregados con código INE 289xx). Distrito y
  Seccion también van sin ceros: CUSEC = '28' + muni(3) + distrito(2) + sección(3).
- La mesa (A, B, C, U) no parte la sección en subsecciones: se suman todas.
- cod_muni 990 «Residentes ausentes-Madrid» (distrito 99) es el voto CERA repartido en
  ~52 pseudo-secciones: se descarta.
- Electores = Censo + certificaciones de alta y de corrección (es el censo de
  escrutinio) y viene con decimal «,0»: se usa Electores como censo.
- Votos_total = votos de electores + de interventores, e incluye blancos y nulos:
  votos a candidaturas = Votos_total - blancos - nulos (cuadra mesa a mesa con la
  suma de columnas de partido).
- Las columnas de partido van desde Votos_total en adelante; la cabecera trae
  «FE DE LAS JONS» mientras el CSV de candidaturas dice «FE DE LA JONS». Se usan las
  siglas de la cabecera.

La anterior (4 de mayo de 2021) tiene su propio conjunto con el mismo nombre y año;
solo se carga la última celebrada (28 de mayo de 2023; la siguiente toca en 2027).
"""

import csv
import io
from datetime import date

import requests

from ingestion.autonomicas import cache

COD_CCAA = "13"
SLUG = "madrid"
FUENTE = ("https://datos.comunidad.madrid/dataset/"
          "datos_electorales_elecciones_autonomicas_comunidad_de_madrid_2023")
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

PROCESOS = [
    {"proceso": "A13202305", "fecha": date(2023, 5, 28),
     "eleccion": "Asamblea de Madrid, mayo de 2023"},
]

URLS = {
    "A13202305": ("https://datos.comunidad.madrid/dataset/23a6a982-110a-4f87-859f-4c036e493aac/"
                  "resource/9a7c670b-7d20-4ddd-93ba-d21ad5f85653/download/"
                  "datos_electorales_elecciones_autonomicas_comunidad_de_madrid_2023.csv"),
}

FIJAS = ["cod_muni", "Municipio", "Distrito", "Seccion", "Mesa", "Censo", "Certif_alta",
         "Certif_correc.", "Electores", "Votos_electores", "Votos_Interventores",
         "Votos_blancos", "Votos_nulos", "Votos_total"]
CERA = "990"


def _entero(v: str) -> int:
    v = (v or "").strip().replace(".", "").replace(",", ".")
    return int(float(v)) if v else 0


def _mesas(proceso: str) -> tuple[list[str], list[dict]]:
    """Filas por mesa (sin CERA) y lista de siglas, con el CSV en caché."""
    destino = cache(SLUG) / f"{proceso}.csv"
    if not destino.exists():
        r = requests.get(URLS[proceso], headers=CABECERAS, timeout=120)
        r.raise_for_status()
        if r.content[:9] != b"cod_muni;":
            raise ValueError(f"Respuesta inesperada (¿captcha?) al bajar {URLS[proceso]}")
        destino.write_bytes(r.content)
    texto = destino.read_bytes().decode("cp1252")
    lector = csv.DictReader(io.StringIO(texto), delimiter=";")
    cabecera = lector.fieldnames or []
    if cabecera[:len(FIJAS)] != FIJAS:
        raise ValueError(f"Cabecera inesperada: {cabecera[:len(FIJAS)]}")
    siglas = [s.strip() for s in cabecera[len(FIJAS):] if s.strip()]
    filas = []
    for f in lector:
        muni = (f["cod_muni"] or "").strip()
        if not muni or muni == CERA or (f["Distrito"] or "").strip() == "99":
            continue
        f["cod_seccion"] = "28" + muni.zfill(3) + f["Distrito"].strip().zfill(2) + f["Seccion"].strip().zfill(3)
        filas.append(f)
    return siglas, filas


def secciones(proceso: str):
    _, filas = _mesas(proceso)
    acc: dict[str, dict] = {}
    for f in filas:
        a = acc.setdefault(f["cod_seccion"], {"cod_seccion": f["cod_seccion"], "censo": 0,
                                              "votos_blanco": 0, "votos_nulos": 0,
                                              "votos_candidaturas": 0})
        blancos, nulos = _entero(f["Votos_blancos"]), _entero(f["Votos_nulos"])
        a["censo"] += _entero(f["Electores"])
        a["votos_blanco"] += blancos
        a["votos_nulos"] += nulos
        a["votos_candidaturas"] += _entero(f["Votos_total"]) - blancos - nulos
    yield from acc.values()


def votos(proceso: str):
    siglas, filas = _mesas(proceso)
    acc: dict[tuple[str, str], int] = {}
    for f in filas:
        for s in siglas:
            n = _entero(f[s])
            if n:
                acc[(f["cod_seccion"], s)] = acc.get((f["cod_seccion"], s), 0) + n
    for (sec, s), n in acc.items():
        yield {"cod_seccion": sec, "siglas": s, "votos": n}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
