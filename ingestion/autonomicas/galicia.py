"""Elecciones al Parlamento de Galicia por sección censal (Xunta de Galicia, Abertos).

La última autonómica gallega es la del 18 de febrero de 2024 (XII lexislatura). El
Ministerio del Interior no publica sus ficheros por mesa; la Xunta los difunde en su
portal de datos abiertos (Consellería de Presidencia, Xustiza e Deportes, licencia
CC BY-SA 4.0):

    https://abertos.xunta.gal/catalogo/administracion-publica/-/dataset/0656/eleccions-parlamento-galicia-resultados-2024

con un fichero por provincia y nivel (municipio o mesa), en CSV y XLSX. Se usan los
CSV por mesa, cuyo recurso tiene un número fijo dentro del conjunto de datos:

    .../eleccions-parlamento-galicia-resultados-2024/{recurso}/descarga-directa-ficheiro.csv
    recurso: 003 A Coruña, 007 Lugo, 011 Ourense, 015 Pontevedra
    (001/005/009/013 son los mismos datos por municipio; 004/008/... las versiones XLSX)

Formato y trampas
-----------------
- CSV separado por «;» en Latin-1 (cp1252), con cabecera en gallego:
  Cód Cir;Cód Con;Concello;Mesa;Censo;Certif Alta;Censo Total;Votos Totais;Votos nulos;
  Votos brancos;Abstención;Votos Válidos;Votos Candidaturas;<una columna por candidatura>
  Las columnas de candidaturas cambian por provincia (Ourense tiene además «DO»,
  Democracia Ourensana), así que se leen por nombre de cabecera, no por posición.
- «Cód Cir» es la provincia INE (15, 27, 32, 36) y «Cód Con» el municipio INE de 3
  dígitos (incluidos los fusionados 15901 Cariño, 15902 Oza-Cesuras, 27901/27902,
  36901/36902): provincia + concello = código INE de 5 dígitos, sin traducción.
- «Mesa» es «DD-SSS-M»: distrito (2), sección (3) y letra de mesa (U, A, B, C...).
  CUSEC = provincia + concello + DD + SSS; las mesas A/B/C de una sección se suman.
- Voto CERA: cada provincia trae un concello ficticio 990 «Residentes ausentes-<prov>»
  con mesas 99-001-U (con todo el voto exterior de la provincia, que en Galicia vota
  en urna y por correo) y 99-002-U... en ceros. Se descartan: en 2024 eran 476.544
  electores del CERA (17,7 % del censo) pero solo 22.960 votantes (4,8 %) y 22.504
  votos a candidaturas (11.308 del PP, 3.627 del PSdeG, 3.583 del BNG).
  Ojo: no filtrar por «990» en cualquier columna (Santiago tiene una mesa con censo
  990); el CERA es solo el concello 990.
- La última fila de cada fichero es «Total» (con el CERA incluido): se descarta.
- «Censo Total» coincide con «Censo» (las certificaciones de alta no se suman al
  censo en este fichero); se usa «Censo Total» como censo de escrutinio.
- Totales de la comunidad (con CERA) = acuerdo de la Xunta Electoral de Galicia del
  4/3/2024 (DOG núm. 47, 6/3/2024, corregido en el DOG núm. 49, 8/3/2024):
  2.693.816 electores, 1.515.944 votantes, 1.488.705 votos a candidaturas, 13.052
  blancos (nulos 14.187).
"""

import csv
import io
import time
from datetime import date

import requests

from ingestion.autonomicas import cache

SLUG = "galicia"
COD_CCAA = "12"
FUENTE = ("https://abertos.xunta.gal/catalogo/administracion-publica/-/dataset/0656/"
          "eleccions-parlamento-galicia-resultados-2024")
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

PROCESOS = [
    {"proceso": "A12202402", "fecha": date(2024, 2, 18),
     "eleccion": "Parlamento de Galicia, febrero de 2024"},
]

# Recurso del CSV por mesa de cada provincia en el conjunto de datos de cada proceso.
FICHEROS = {
    "A12202402": {
        "url": FUENTE + "/{recurso}/descarga-directa-ficheiro.csv",
        "recursos": {"15": "003", "27": "007", "32": "011", "36": "015"},
    },
}

FIJAS = ["Cód Cir", "Cód Con", "Concello", "Mesa", "Censo", "Certif Alta", "Censo Total",
         "Votos Totais", "Votos nulos", "Votos brancos", "Abstención", "Votos Válidos",
         "Votos Candidaturas"]
MUN_CERA = "990"


def _descargar(proceso: str, prov: str) -> bytes:
    conf = FICHEROS[proceso]
    ruta = cache(SLUG) / f"{proceso}_{prov}_mesas.csv"
    if not ruta.exists():
        url = conf["url"].format(recurso=conf["recursos"][prov])
        for intento in range(3):
            try:
                r = requests.get(url, headers=CABECERAS, timeout=120)
                r.raise_for_status()
                break
            except requests.RequestException:
                if intento == 2:
                    raise
                time.sleep(5)
        if not r.content.startswith("Cód Cir".encode("cp1252")):
            raise ValueError(f"{url} no parece el CSV por mesa esperado")
        ruta.write_bytes(r.content)
    return ruta.read_bytes()


def _mesas(proceso: str):
    """(cusec, fila, candidaturas) de cada mesa con sección real, sin CERA ni totales."""
    for prov in FICHEROS[proceso]["recursos"]:
        texto = _descargar(proceso, prov).decode("cp1252")
        lector = csv.reader(io.StringIO(texto), delimiter=";")
        cab = [c.strip() for c in next(lector)]
        if cab[:len(FIJAS)] != FIJAS:
            raise ValueError(f"Cabecera inesperada en {proceso}/{prov}: {cab[:len(FIJAS)]}")
        candidaturas = [c for c in cab[len(FIJAS):] if c]
        for fila in lector:
            if not fila or not fila[0].strip().isdigit():
                continue  # fila «Total»
            d = dict(zip(cab, (x.strip() for x in fila)))
            if d["Cód Cir"] != prov:
                raise ValueError(f"Provincia {d['Cód Cir']} en el fichero de {prov}")
            mun = d["Cód Con"].zfill(3)
            if mun == MUN_CERA:
                continue
            dist, secc, _letra = d["Mesa"].split("-")
            cusec = prov + mun + dist.zfill(2) + secc.zfill(3)
            yield cusec, d, candidaturas


def secciones(proceso: str):
    acc: dict[str, dict] = {}
    for cusec, d, _ in _mesas(proceso):
        s = acc.setdefault(cusec, {"cod_seccion": cusec, "censo": 0, "votos_blanco": 0,
                                   "votos_nulos": 0, "votos_candidaturas": 0})
        s["censo"] += int(d["Censo Total"])
        s["votos_blanco"] += int(d["Votos brancos"])
        s["votos_nulos"] += int(d["Votos nulos"])
        s["votos_candidaturas"] += int(d["Votos Candidaturas"])
    return list(acc.values())


def votos(proceso: str):
    acc: dict[tuple[str, str], int] = {}
    for cusec, d, candidaturas in _mesas(proceso):
        for siglas in candidaturas:
            n = int(d[siglas] or 0)
            if n:
                acc[(cusec, siglas)] = acc.get((cusec, siglas), 0) + n
    return [{"cod_seccion": c, "siglas": s, "votos": n} for (c, s), n in acc.items()]


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
