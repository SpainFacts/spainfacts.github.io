"""Elecciones a las Cortes de Castilla y León por sección censal (Junta de Castilla y León).

Fuente: portal de datos abiertos de la Junta de Castilla y León, conjunto
«Elecciones 2026» (sector público), licencia CC BY 4.0:

    https://datosabiertos.jcyl.es/web/jcyl/set/es/sector-publico/elecciones_2026_final/1285663344325

Su recurso CSV (…/risp/es/sector-publico/elecciones_2026_final/1285663344325.csv)
redirige a un fichero estático de Transparencia, que es el que se descarga:

    https://transparencia.jcyl.es/resultadoselectorales/2026.csv

Es el escrutinio DEFINITIVO por mesa (~5,6 MB, UTF-8 con BOM, separador «;»), en
formato largo: una fila por mesa y candidatura, con los datos de la mesa repetidos
en cada fila:

    Año;Código de mesa;Provincia;Código;Municipio;Distrito;Sección;Mesa;Censo;
    Primer Avance;Segundo Avance;Tercer Avance;Total Votantes;Votos Nulos;
    Votos Blancos;Partido;Nº Votos

    2026;05-001-1-001-U;Ávila;1;Adanero;1;1;U;167;39;83;104;125;1;2;PP;52

«Código de mesa» = provincia(2)-municipio(3)-distrito(1 o 2)-sección(3)-mesa(letra).
El código de municipio es el del INE (provincia + «Código» a 3 dígitos), así que
el CUSEC sale de provincia + municipio + distrito (2) + sección (3), rellenando
con ceros. Los totales coinciden al voto con el resultado oficial de la noche
electoral publicado por la Junta (servicios.jcyl.es/elec, ámbito Castilla y León).

Trampas:
- La ficha del conjunto dice que «no incluye los residentes ausentes», pero el
  fichero SÍ trae el CERA: 19 mesas con municipio 990, distrito 99 y nombre
  «Residentes ausentes-<provincia>» (~180.000 de censo, ~12.000 votantes). Se
  descartan aquí; por eso la suma de secciones queda por debajo del total oficial.
- El censo de las mesas es el censo de escrutinio sin CERA (el CERA va aparte).
- Votos a candidaturas = Total Votantes − Nulos − Blancos (cuadra con la suma
  de partidos en todas las mesas); se calcula sumando las filas de partido.
- Los ficheros de años anteriores (p. ej. 2022.csv) tienen otro formato: Latin-1,
  sin columna «Año», cabecera partida en dos líneas. No se usan aquí.
"""

import csv
import io
from datetime import date

import requests

from ingestion.autonomicas import cache

COD_CCAA = "07"
SLUG = "castilla_leon"
FUENTE = ("https://datosabiertos.jcyl.es/web/jcyl/set/es/sector-publico/"
          "elecciones_2026_final/1285663344325")
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

PROCESOS = [
    {"proceso": "A07202603",
     "fecha": date(2026, 3, 15),
     "eleccion": "Cortes de Castilla y León, marzo de 2026"},
]

URLS = {
    "A07202603": "https://transparencia.jcyl.es/resultadoselectorales/2026.csv",
}

MUNICIPIO_CERA = "990"


def _filas(proceso: str) -> list[dict]:
    """Filas del CSV por mesa y partido (descarga en caché)."""
    destino = cache(SLUG) / f"{proceso}.csv"
    if not destino.exists():
        r = requests.get(URLS[proceso], headers=CABECERAS, timeout=300)
        r.raise_for_status()
        destino.write_bytes(r.content)
    texto = destino.read_bytes().decode("utf-8-sig")
    return list(csv.DictReader(io.StringIO(texto), delimiter=";"))


def _cusec(fila: dict) -> str | None:
    """Código de sección del INE (10 dígitos) o None si es CERA / sin sección."""
    prov, mun = fila["Código de mesa"][:2], fila["Código"].strip().zfill(3)
    if mun == MUNICIPIO_CERA or fila["Distrito"].strip() == "99":
        return None
    return prov + mun + fila["Distrito"].strip().zfill(2) + fila["Sección"].strip().zfill(3)


def secciones(proceso: str):
    """Una fila por sección: censo, blancos, nulos y votos a candidaturas."""
    mesas: dict[str, dict] = {}
    candidaturas: dict[str, int] = {}
    for f in _filas(proceso):
        mesa = f["Código de mesa"]
        if mesa not in mesas:
            mesas[mesa] = f
        candidaturas[mesa] = candidaturas.get(mesa, 0) + int(f["Nº Votos"])
    acum: dict[str, dict] = {}
    for mesa, f in mesas.items():
        cod = _cusec(f)
        if cod is None:
            continue
        s = acum.setdefault(cod, {"cod_seccion": cod, "censo": 0, "votos_blanco": 0,
                                  "votos_nulos": 0, "votos_candidaturas": 0})
        s["censo"] += int(f["Censo"])
        s["votos_blanco"] += int(f["Votos Blancos"])
        s["votos_nulos"] += int(f["Votos Nulos"])
        s["votos_candidaturas"] += candidaturas[mesa]
    yield from acum.values()


def votos(proceso: str):
    """Una fila por sección y candidatura."""
    acum: dict[tuple[str, str], int] = {}
    for f in _filas(proceso):
        cod = _cusec(f)
        if cod is None:
            continue
        clave = (cod, f["Partido"].strip())
        acum[clave] = acum.get(clave, 0) + int(f["Nº Votos"])
    for (cod, siglas), n in acum.items():
        yield {"cod_seccion": cod, "siglas": siglas, "votos": n}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
