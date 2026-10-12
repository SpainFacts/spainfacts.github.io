"""Elecciones a las Cortes de Aragón por sección censal (Gobierno de Aragón).

Fuente: Portal de Elecciones del Gobierno de Aragón (Dirección General de Interior),
página «Resultados electorales»:

    https://www.aragon.es/portal-de-elecciones/resultados-electorales

que publica, por circunscripción, los «datos de escrutinio definitivo» por mesa en un
Excel 97-2003 (.xls, sin extensión en la URL):

    https://www.aragon.es/documents/d/guest/datescrut_def_auto_2026_{zaragoza|huesca|teruel}

Contenido de aragon.es bajo licencia CC BY 4.0 (aviso legal del portal). Los mismos
datos están en Aragón Open Data (conjunto «Elecciones a Cortes de Aragón, año 2026,
detalle distrito mesa electoral», recursos 380 y 381 de GA_OD_Core, CC BY 4.0), pero
allí los partidos van con su denominación completa y sin siglas; el Excel trae las
siglas en la cabecera (PSOE, PP, VOX, CHA, EXISTE...), que es lo que esperan las
reglas de familias políticas de dbt. Se ha comprobado que ambos cuadran mesa a mesa en
totales.

Formato del Excel (hoja «Mesas», una fila por mesa):
    Codcir (provincia INE), Codmun (municipio INE, 3 dígitos), Municipio,
    Mesa («D-SSS-L»: distrito, sección de 3 dígitos y letra de mesa U/A/B/C...),
    Censo, Certif. Alta, Certif. Correc., Censo Total, Votos Electores,
    Votos Interventores, Votos Totales, Votos Nulos, Votos Blancos y una columna por
    candidatura (las siglas varían por provincia: EXISTE no se presenta igual en todas,
    PCTE y MUNDO+JUSTO solo en Zaragoza, etc.).

Trampas:
- La cabecera llega en cp1252 dentro del .xls («COALICIÓN», «ESCAÑOS EN BLANCO»):
  xlrd la decodifica bien; no tocarla.
- Las cifras vienen como float (61.0): se pasan a int.
- Última fila «Total» y filas de «Residentes ausentes-<provincia>» (Codmun 990, mesas
  «99-00x-U», todo a cero): son el CERA y se descartan. El voto CERA solo está en el
  resumen oficial de la Junta Electoral, por eso la suma de las mesas queda unos 4.300
  votos a candidaturas por debajo del total autonómico publicado.
- ¡No filtrar el CERA por «municipio >= 900»! Aragón tiene municipios reales con
  código INE 9xx (entidades agregadas/segregadas: 22901-22909 en Huesca, 50901-50903
  en Zaragoza, unas 18 mesas y ~4.900 votos). El CERA se reconoce por Codmun 990 y el
  nombre «Residentes ausentes».
- Votos a candidaturas = suma de las columnas de partido (= Votos Totales - nulos -
  blancos). Censo = «Censo Total» (censo + certificaciones de alta).
- CUSEC = Codcir(2) + Codmun(3) + distrito(2) + sección(3); varias mesas (A, B, C...)
  de la misma sección se suman.
"""

import re
from collections import defaultdict
from datetime import date

import requests
import xlrd

from ingestion.autonomicas import cache

COD_CCAA = "02"
SLUG = "aragon"
FUENTE = "https://www.aragon.es/portal-de-elecciones/resultados-electorales"
URL = "https://www.aragon.es/documents/d/guest/datescrut_def_auto_{anio}_{prov}"
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}
PROVINCIAS = ("huesca", "teruel", "zaragoza")

PROCESOS = [
    {"proceso": "A02202602", "fecha": date(2026, 2, 8),
     "eleccion": "Cortes de Aragón, febrero de 2026"},
]

_FIJAS = 13  # columnas antes de la primera candidatura
_MESA = re.compile(r"(\d{1,2})-(\d{3})-([A-Z])")


def _descargar(anio: int, prov: str):
    ruta = cache(SLUG) / f"datescrut_def_auto_{anio}_{prov}.xls"
    if not ruta.exists() or ruta.stat().st_size == 0:
        r = requests.get(URL.format(anio=anio, prov=prov), headers=CABECERAS, timeout=120)
        r.raise_for_status()
        ruta.write_bytes(r.content)
    return ruta


def _mesas(proceso: str):
    """Filas de mesa ya limpias: (cusec, censo, blancos, nulos, {siglas: votos})."""
    anio = int(proceso[3:7])
    for prov in PROVINCIAS:
        hoja = xlrd.open_workbook(_descargar(anio, prov)).sheet_by_name("Mesas")
        cab = [str(c).strip() for c in hoja.row_values(0)]
        assert cab[4] == "Censo" and cab[7] == "Censo Total" and cab[12] == "Votos Blancos", cab
        partidos = cab[_FIJAS:]
        for i in range(1, hoja.nrows):
            f = hoja.row_values(i)
            if not isinstance(f[0], float) or not isinstance(f[1], float):
                continue  # fila «Total»
            mun = int(f[1])
            m = _MESA.fullmatch(str(f[3]).strip())
            if mun in (990, 999) or "ausentes" in str(f[2]).lower() or not m:
                continue  # residentes ausentes (CERA)
            cusec = f"{int(f[0]):02d}{mun:03d}{int(m.group(1)):02d}{m.group(2)}"
            votos = {s: int(v or 0) for s, v in zip(partidos, f[_FIJAS:]) if s}
            yield cusec, int(f[7] or 0), int(f[12] or 0), int(f[11] or 0), votos


def secciones(proceso: str):
    acc = defaultdict(lambda: {"censo": 0, "votos_blanco": 0, "votos_nulos": 0, "votos_candidaturas": 0})
    for cusec, censo, blancos, nulos, votos in _mesas(proceso):
        a = acc[cusec]
        a["censo"] += censo
        a["votos_blanco"] += blancos
        a["votos_nulos"] += nulos
        a["votos_candidaturas"] += sum(votos.values())
    for cusec, a in sorted(acc.items()):
        yield {"cod_seccion": cusec, **a}


def votos(proceso: str):
    acc = defaultdict(int)
    for cusec, _, _, _, v in _mesas(proceso):
        for siglas, n in v.items():
            acc[(cusec, siglas)] += n
    for (cusec, siglas), n in sorted(acc.items()):
        if n:
            yield {"cod_seccion": cusec, "siglas": siglas, "votos": n}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
