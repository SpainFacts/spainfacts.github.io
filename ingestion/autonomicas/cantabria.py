"""Elecciones al Parlamento de Cantabria: 2023 por sección censal (Gobierno de Cantabria)
y 1983-2019 por municipio (ICANE; falta 2011).

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

Histórico 1983-2019 por municipio (ICANE)
-----------------------------------------
Para las autonómicas anteriores no queda ningún fichero por mesa ni por sección: la
página del Gobierno solo da los totales de la comunidad (2003-2019, con enlace al acta
del BOC, que tampoco desglosa por municipio), y las webs de resultados de cada año
(elecciones2011/2015.cantabria.es, resultados.elecciones2019.cantabria.es) ya no
existen y el Wayback no guardó sus descargas. La única serie oficial por municipio es
la del Instituto Cántabro de Estadística (ICANE), tabla «Elecciones Autonómicas. Votos
por municipio y partido político»:

    https://www.icane.es/data/elecciones-regional-votos-municipio-partido-politico
    CSV: https://www.icane.es/data/api/elecciones-regional-votos-municipio-partido-politico.csv

(~95 KB, separador «;», UTF-8; catálogo en datos.icane.es, conjunto «elecciones-regional»).
Una fila por municipio (102, «39001 - Alfoz de Lloredo», código INE) y una columna
«<año> - <partido> - Votos» por año y partido. Trampas:
- Solo trae los cinco partidos más votados de cada año y agrupa el resto en «Otros»
  (lo dice la nota de la tabla); «Total» = votos a candidaturas (= suma de las columnas
  del año). No hay censo, blancos ni nulos por municipio: municipios() devuelve None
  en esos campos (no se inventan).
- Falta 2011 (la tabla salta de 2007 a 2015): esa elección no se carga.
- 1995 trae cruzadas las columnas PP y PSOE en todos los municipios (Santander: «PSOE»
  38.056 y «PP» 22.528; los totales de las dos columnas son el PP y el PSOE oficiales
  al revés, y la correlación municipio a municipio con 1991 y 1999 solo sale positiva
  cruzándolas): el módulo las intercambia (ICANE_CRUZADAS).
- Siglas de ICANE: «AP» en 1983 es AP-PDP-UL; «IU» en 2007 es Convocatoria por
  Cantabria (IU-BR); «Otros» es el resto de candidaturas juntas.
- Las cifras son sin CERA (los residentes ausentes no están en ningún municipio), salvo
  en 1983, donde la suma municipal SUPERA al resultado oficial (+0,46 %, con diferencias
  de signo distinto por partido): ICANE debió de tomar otro recuento (¿el provisional?).
  Se carga igual, avisado aquí.
- 2023 también está en ICANE pero con errores (falta Campoo de Enmedio y El Astillero
  no cuadra): para 2023 se usa el Excel por mesa.

Resultado oficial (acta de la Junta Electoral Provincial, BOC extraordinario núm. 46
de 7-6-2023, CVE-2023-5565): 507.438 electores, 331.413 votantes, 318.919 votos a
candidaturas, 5.809 blancos, 6.685 nulos; PP 116.198, PRC 67.523, PSOE 66.917.
Sin el CERA (2.481 a candidaturas, 56 blancos, 12 nulos) la suma por sección es
316.438 / 5.753 / 6.673.
"""

import csv
import io
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

_MESES = {5: "mayo", 6: "junio"}
_FECHAS = [date(1983, 5, 8), date(1987, 6, 10), date(1991, 5, 26), date(1995, 5, 28),
           date(1999, 6, 13), date(2003, 5, 25), date(2007, 5, 27), date(2015, 5, 24),
           date(2019, 5, 26), date(2023, 5, 28)]
# 2011 (22-5-2011) no está: ICANE no la publica por municipio y no hay otro fichero.
PROCESOS = [
    {"proceso": f"A06{f.year}{f.month:02d}", "fecha": f,
     "eleccion": f"Parlamento de Cantabria, {_MESES[f.month]} de {f.year}"}
    for f in _FECHAS
]
# Elecciones que solo hay por municipio (ICANE): proceso -> año.
POR_MUNICIPIO = {p["proceso"]: p["fecha"].year for p in PROCESOS if p["fecha"].year < 2023}

ICANE_CSV = ("icane_votos_municipio_partido.csv",
             "https://www.icane.es/data/api/elecciones-regional-votos-municipio-partido-politico.csv")
# Columnas cruzadas en la tabla del ICANE (año: {columna: siglas reales}).
ICANE_CRUZADAS = {1995: {"PP": "PSOE", "PSOE": "PP"}}

# Votos a candidaturas oficiales (con CERA), solo para comprobar. 1983-2007 y 2019: suma
# de la tabla del ICANE «Votos y escaños por partido político» (acta de la Junta); 2015:
# página del Gobierno (votantes - blancos - nulos = suma de partidos; la tabla del ICANE
# de 2015 no cuadra); 2023: BOC. En 1987 la tabla «Datos regionales» del ICANE da otro
# total (291.726) que la suma por partido (293.850).
OFICIAL = {1983: 277440, 1987: 293850, 1991: 290797, 1995: 313846, 1999: 309716,
           2003: 338316, 2007: 340321, 2015: 320108, 2019: 322723, 2023: 318919}

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
    if proceso not in FICHEROS:
        return
    glob, _ = _agregado(proceso)
    yield from glob.values()


def votos(proceso: str) -> Iterable[dict]:
    if proceso not in FICHEROS:
        return
    _, v = _agregado(proceso)
    for (cod, siglas), n in v.items():
        if n:
            yield {"cod_seccion": cod, "siglas": siglas, "votos": n}


@lru_cache(maxsize=None)
def _icane() -> tuple[list[str], list[list[str]]]:
    nombre, url = ICANE_CSV
    ruta = cache(SLUG) / nombre
    if not ruta.exists():
        r = requests.get(url, headers=CABECERAS, timeout=120)
        r.raise_for_status()
        if b" - Votos" not in r.content[:2000]:
            raise ValueError(f"{url} no devuelve el CSV esperado ({r.headers.get('content-type')})")
        ruta.write_bytes(r.content)
    filas = list(csv.reader(io.StringIO(ruta.read_text(encoding="utf-8-sig")), delimiter=";"))
    return filas[0], filas[1:]


@lru_cache(maxsize=None)
def _icane_anio(anio: int) -> dict[str, dict[str, int]]:
    """{cod_mun: {siglas: votos}} de un año (sin la fila ni la columna Total)."""
    cab, filas = _icane()
    cols = {i: c.split(" - ")[1] for i, c in enumerate(cab) if c.startswith(f"{anio} - ")}
    i_total = next(i for i, s in cols.items() if s == "Total")
    cruce = ICANE_CRUZADAS.get(anio, {})
    out: dict[str, dict[str, int]] = {}
    for f in filas:
        cod = f[0].split(" - ")[0].strip()
        if not (len(cod) == 5 and cod.isdigit()) or not f[i_total].strip():
            continue  # fila Total o municipio sin datos ese año
        votos = {cruce.get(s, s): int(f[i]) for i, s in cols.items()
                 if i != i_total and f[i].strip()}
        if sum(votos.values()) != int(f[i_total]):
            raise ValueError(f"ICANE {anio} {cod}: Total {f[i_total]} != suma {sum(votos.values())}")
        out[cod] = votos
    return out


def municipios(proceso: str) -> Iterable[dict]:
    if proceso not in POR_MUNICIPIO:
        return []
    # Sin censo, blancos ni nulos por municipio en la fuente: None, no se inventan.
    return [{"cod_mun": cod, "censo": None, "votos_blanco": None, "votos_nulos": None,
             "votos_candidaturas": sum(v.values())}
            for cod, v in _icane_anio(POR_MUNICIPIO[proceso]).items()]


def votos_municipios(proceso: str) -> Iterable[dict]:
    if proceso not in POR_MUNICIPIO:
        return []
    return [{"cod_mun": cod, "siglas": s, "votos": n}
            for cod, v in _icane_anio(POR_MUNICIPIO[proceso]).items()
            for s, n in v.items() if n]


def comprobar() -> None:
    """Votos a candidaturas de cada elección frente al oficial (que incluye el CERA)."""
    for p in PROCESOS:
        if p["proceso"] in POR_MUNICIPIO:
            filas, nivel = list(municipios(p["proceso"])), "municipio"
            n = len(filas)
            vm = votos_municipios(p["proceso"])
        else:
            filas, nivel = list(secciones(p["proceso"])), "sección"
            n = len({r["cod_seccion"][:5] for r in filas})
            vm = votos(p["proceso"])
        por: dict[str, int] = defaultdict(int)
        for r in vm:
            por[r["siglas"]] += r["votos"]
        cand = sum(r["votos_candidaturas"] for r in filas)
        of = OFICIAL[p["fecha"].year]
        print(f"{p['proceso']} {p['fecha']} {nivel:9} municipios {n:3} · candidaturas {cand:,}"
              f" · oficial {of:,} · diferencia {cand - of:+,} ({100 * (cand - of) / of:+.2f} %)")
        print("     " + " · ".join(f"{k} {v:,}" for k, v in sorted(por.items(), key=lambda x: -x[1])[:6]))


if __name__ == "__main__":
    import types
    from ingestion.autonomicas import probar

    comprobar()
    # probar() suma censo y blancos, que no hay por municipio antes de 2023: se le pasa
    # el módulo solo con la elección por sección.
    probar(types.SimpleNamespace(PROCESOS=[p for p in PROCESOS if p["proceso"] in FICHEROS],
                                 secciones=secciones, votos=votos))
