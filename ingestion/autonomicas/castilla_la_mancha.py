"""Elecciones a las Cortes de Castilla-La Mancha por sección censal (28 de mayo de 2023).

Fuente: la web electoral de la Junta de Comunidades de Castilla-La Mancha
(elecciones.castillalamancha.es / elecciones2023.castillalamancha.es). En su menú
«Resultados» enlaza «Descargar los resultados de las elecciones desglosado por mesas»,
que es un PDF de 87 páginas (~0,6 MB), sin ningún CSV ni XLS equivalente:

    https://elecciones2023.castillalamancha.es/sites/default/files/2023-06/ResultadosprovisionalesCLMbis.pdf

Para traducir los nombres de municipio al código del INE se usa el fichero por
municipio del portal de datos abiertos de la Junta (licencia CC BY-SA 3.0 ES,
catálogo «Resultados de elecciones autonómicas en Castilla-La Mancha. Histórico»):

    https://datosabiertos.castillalamancha.es/sites/datosabiertos.castillalamancha.es/files/Resultados_CLM_2023.csv

Formato del PDF y trampas
-------------------------
- Una tabla por provincia (ALBACETE, CIUDAD REAL, CUENCA, GUADALAJARA, TOLEDO; el
  nombre va en la cabecera de la primera página de cada una). Cada fila es una mesa:
  «Municipio  D-SSS-M  censo  cert.alta  [cert.correc.]  censo total  votantes  nulos
  blancos  votos de cada candidatura». No trae código de municipio, solo el nombre.
- Las columnas cambian por provincia: Toledo NO tiene la columna de certificaciones
  de corrección (6 columnas fijas en vez de 7) y cada provincia tiene sus candidaturas
  en su propio orden (ver COLUMNAS). Las cabeceras de partido vienen partidas en
  varias líneas («UNIDAS / PODEMO / S CLM»), así que el orden está fijado a mano y se
  comprueba que cada fila tiene exactamente el número de cifras esperado.
- pdftotext descoloca las filas; pdfplumber (palabras con su coordenada y) las lee
  bien agrupando por altura.
- La mesa es «distrito-sección-mesa» (p. ej. 1-002-A): con provincia y código INE del
  municipio forma el CUSEC (prov 2 + mun 3 + distrito 2 + sección 3). Las mesas A/B/C/U
  de una sección se suman.
- Es el escrutinio PROVISIONAL (lo dice el nombre del fichero) y al final de cada
  provincia hay una página de «MESA SIN GRABAR»: 32 mesas de toda la comunidad sin
  datos (p. ej. Albacete 1-006-A, Talavera de la Reina 1-006-A). Esas secciones quedan
  incompletas o sin fila. La Junta no publica por mesa el escrutinio definitivo.
- No incluye el voto CERA (residentes ausentes), que va aparte en el escrutinio
  general; aquí no hay que descartarlo.
- En el CSV de datos abiertos la candidatura «+CU-EV» de Cuenca sale como
  «#¿NOMBRE?» (Excel la tomó por fórmula); aquí las siglas salen del PDF/DOCM.
- Los nombres de municipio del PDF y del CSV coinciden salvo tildes/mayúsculas; se
  comparan normalizados. En Toledo la columna del municipio es más estrecha y los
  nombres largos se parten en dos renglones («Villafranca de los» / «Caballeros»): el
  primer renglón va solo, sin mesa, justo encima de la fila y se antepone al nombre.
- En el CSV los municipios 9xx (02901 Pozo Cañada, 16901...) son municipios reales;
  el CERA es el municipio 990 («Residentes ausentes-<provincia>»).
- Las secciones nuevas de 2023 (p. ej. 0200302025, 4509901003) no están aún en el
  seccionado del INE de 1-1-2023 sino en el de 2024.

Resultado oficial (DOCM nº 114, 16-06-2023, acuerdo de la Junta Electoral de
Castilla-La Mancha): 1.072.883 votos a candidaturas, 15.570 blancos, 19.054 nulos;
PSOE 490.288, PP 366.312, VOX 139.607 (con CERA).
"""

import csv
import io
import re
import unicodedata
from datetime import date
from functools import lru_cache

import requests

from ingestion.autonomicas import cache

COD_CCAA = "08"
SLUG = "castilla_la_mancha"
FUENTE = "https://elecciones2023.castillalamancha.es/resultados/resultados-def"
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

# La Junta solo publica por mesa el escrutinio provisional (faltan 32 mesas sin grabar)
COBERTURA = "Escrutinio provisional: faltan 32 mesas sin grabar (1,2 % de los votos)"

PROCESOS = [
    {"proceso": "A08202305", "fecha": date(2023, 5, 28),
     "eleccion": "Cortes de Castilla-La Mancha, mayo de 2023"},
]

URLS = {
    "A08202305": {
        "mesas": ("https://elecciones2023.castillalamancha.es/sites/default/files/2023-06/"
                  "ResultadosprovisionalesCLMbis.pdf"),
        "municipios": ("https://datosabiertos.castillalamancha.es/sites/"
                       "datosabiertos.castillalamancha.es/files/Resultados_CLM_2023.csv"),
    },
}

# Por provincia: código INE, nº de columnas fijas tras la mesa (censo ... blancos) y
# candidaturas en el orden de las columnas del PDF.
PROVINCIAS = {
    "ALBACETE": ("02", 7, ["PSOE", "PP", "VOX", "CS", "PACMA", "UNIDAS PODEMOS CLM",
                           "PAIS CON GESTORES"]),
    "CIUDAD REAL": ("13", 7, ["PP", "PSOE", "VOX", "PACMA", "UNIDAS PODEMOS CLM", "CS"]),
    "CUENCA": ("16", 7, ["PP", "PSOE", "+CU-EV", "TÚPATRIA", "UNIDAS PODEMOS CLM", "CS",
                         "PCAS-TC-RC", "VOX", "PACMA", "PAIS CON GESTORES"]),
    "GUADALAJARA": ("19", 7, ["PP", "PSOE", "FE DE LAS JONS", "VOX", "UNIDAS PODEMOS CLM",
                              "PACMA", "PAIS CON GESTORES", "PCAS-TC-RC", "CS"]),
    # Toledo no tiene la columna de certificaciones de corrección.
    "TOLEDO": ("45", 6, ["ESPAÑA VACIADA", "PP", "AQUI AHORA", "PSOE", "VOX",
                         "UNIDAS PODEMOS CLM", "P.C.P.E.", "PACMA", "PCAS-TC-RC", "CS",
                         "PAIS CON GESTORES"]),
}

MESA = re.compile(r"^(\d{1,2})-(\d{3})-([A-Z])$")
NUMERO = re.compile(r"^\d{1,3}(\.\d{3})*$|^\d+$")


def _norm(texto: str) -> str:
    t = unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", " ", t).strip()


def _bajar(url: str, nombre: str, inicio: bytes) -> bytes:
    destino = cache(SLUG) / nombre
    if not destino.exists():
        r = requests.get(url, headers=CABECERAS, timeout=120)
        r.raise_for_status()
        if not r.content.startswith(inicio):
            raise ValueError(f"Respuesta inesperada al bajar {url}")
        destino.write_bytes(r.content)
    return destino.read_bytes()


def _codigos_municipio(proceso: str) -> dict[tuple[str, str], str]:
    """(provincia INE, nombre normalizado) -> código INE de municipio (5 dígitos)."""
    raw = _bajar(URLS[proceso]["municipios"], f"{proceso}_municipios.csv", b"ELECCIONES")
    lineas = raw.decode("cp1252").splitlines()
    inicio = next(i for i, l in enumerate(lineas) if l.startswith("Año;Provincia;"))
    codigos = {}
    for f in csv.DictReader(io.StringIO("\n".join(lineas[inicio:])), delimiter=";"):
        prov, mun = f["Provincia"].strip().zfill(2), f["Municipio"].strip().zfill(3)
        if mun == "990":                  # residentes ausentes (CERA)
            continue
        codigos[(prov, _norm(f["Nombre"]))] = prov + mun
    return codigos


@lru_cache(maxsize=None)
def _mesas(proceso: str) -> tuple[dict, ...]:
    """Una fila por mesa leída del PDF, con su CUSEC."""
    import pdfplumber

    pdf = _bajar(URLS[proceso]["mesas"], f"{proceso}_mesas.pdf", b"%PDF")
    codigos = _codigos_municipio(proceso)
    filas, provincia, prefijo = [], None, ""
    with pdfplumber.open(io.BytesIO(pdf)) as doc:
        for pagina in doc.pages:
            palabras = sorted(pagina.extract_words(), key=lambda w: (w["top"], w["x0"]))
            renglones: list[list[dict]] = []
            for w in palabras:
                if renglones and abs(w["top"] - renglones[-1][0]["top"]) < 2:
                    renglones[-1].append(w)
                else:
                    renglones.append([w])
            for r in renglones:
                textos = [w["text"] for w in sorted(r, key=lambda w: w["x0"])]
                linea = " ".join(textos)
                if linea in PROVINCIAS:
                    provincia = linea
                    continue
                pos = next((i for i, t in enumerate(textos) if MESA.match(t)), None)
                if pos is None:
                    # Nombre largo partido en dos renglones: el primero va solo, en la
                    # columna del municipio, justo encima de la fila de la mesa.
                    prefijo = linea if max(w["x1"] for w in r) < 150 else ""
                    continue
                if "GRABAR" in linea:                    # «MESA SIN GRABAR»
                    prefijo = ""
                    continue
                if provincia is None:
                    raise ValueError(f"Fila antes de la cabecera de provincia: {linea}")
                prov, n_fijas, siglas = PROVINCIAS[provincia]
                cifras = textos[pos + 1:]
                if len(cifras) != n_fijas + len(siglas) or not all(NUMERO.match(c) for c in cifras):
                    raise ValueError(f"Fila con columnas inesperadas ({provincia}): {linea}")
                cifras = [int(c.replace(".", "")) for c in cifras]
                nombre = " ".join(textos[:pos])
                cod_mun = codigos.get((prov, _norm(nombre)))
                if cod_mun is None and prefijo:
                    nombre = f"{prefijo} {nombre}"
                    cod_mun = codigos.get((prov, _norm(nombre)))
                prefijo = ""
                if cod_mun is None:
                    raise ValueError(f"Municipio sin código INE: {prov} {nombre}")
                distrito, seccion, _ = MESA.match(textos[pos]).groups()
                fijas, partidos = cifras[:n_fijas], cifras[n_fijas:]
                # Fijas: censo, cert. alta, [cert. correc.], censo total, votantes, nulos, blancos
                filas.append({
                    "cod_seccion": cod_mun + distrito.zfill(2) + seccion,
                    "censo": fijas[-4],
                    "votos_nulos": fijas[-2],
                    "votos_blanco": fijas[-1],
                    "votos": dict(zip(siglas, partidos)),
                })
    return tuple(filas)


def secciones(proceso: str):
    acc: dict[str, dict] = {}
    for m in _mesas(proceso):
        a = acc.setdefault(m["cod_seccion"], {"cod_seccion": m["cod_seccion"], "censo": 0,
                                              "votos_blanco": 0, "votos_nulos": 0,
                                              "votos_candidaturas": 0})
        a["censo"] += m["censo"]
        a["votos_blanco"] += m["votos_blanco"]
        a["votos_nulos"] += m["votos_nulos"]
        a["votos_candidaturas"] += sum(m["votos"].values())
    return list(acc.values())


def votos(proceso: str):
    acc: dict[tuple[str, str], int] = {}
    for m in _mesas(proceso):
        for siglas, n in m["votos"].items():
            k = (m["cod_seccion"], siglas)
            acc[k] = acc.get(k, 0) + n
    return [{"cod_seccion": s, "siglas": g, "votos": n} for (s, g), n in acc.items()]


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
