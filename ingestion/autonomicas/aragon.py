"""Elecciones a las Cortes de Aragón, de 1983 a 2026, por sección censal o por municipio.

Fuentes (Gobierno de Aragón, contenido bajo licencia CC BY 4.0):

1. Portal de Elecciones (Dirección General de Interior), «Resultados electorales» y
   «Resultados anteriores»:

       https://www.aragon.es/portal-de-elecciones/resultados-electorales
       https://www.aragon.es/portal-de-elecciones/resultados/anteriores

   Escrutinio definitivo por mesa en Excel 97-2003 (.xls, sin extensión en la URL), uno
   por circunscripción, con las SIGLAS de cada candidatura en la cabecera. Solo existe
   para 2011, 2015 y 2026 (los «Excel» de 2019 y 2023 de esa página son el mismo volcado
   de Aragón Open Data, sin siglas ni participación).

2. Aragón Open Data (GA_OD_Core), conjuntos «Elecciones a Cortes de Aragón, año ...»:

       https://opendata.aragon.es/GA_OD_Core/download?resource_id=N&formato=csv
           &filters={"cod_elec":"CA<año>"}

   372/373  comunidad (participación / votos por candidatura): el resultado oficial
   378/379  municipio (participación / votos), todas las elecciones desde 1983
   380/381  mesa (participación / votos): 381 desde 1995, 380 solo 2003, 2007, 2019,
            2023 y 2026

Nivel que usa el módulo en cada elección (el más fino completo):
    1983, 1987, 1991, 1995, 1999  municipio (378/379). En 1995 y 1999 hay votos por mesa
                                  (381) pero no participación (380 vacío): sin censo,
                                  blancos ni nulos no sirven para la sección.
    2003, 2007, 2019, 2023        sección, sumando mesas de Open Data (380 + 381)
    2011, 2015, 2026              sección, sumando mesas de los Excel del portal

Formato del Excel (hoja «Mesas», una fila por mesa):
    Codcir, Codmun (3 dígitos INE), Municipio, Mesa («D-SSS-L» o «D-SSS -L»), Censo,
    Certif. Alta, ..., Votos Nulos, Votos Blancos y una columna por candidatura (las
    siglas cambian por provincia). 2011 no trae «Censo Total» (se suma Censo + Certif.
    Alta) y sus columnas fijas van en otro orden: se localizan por el nombre.

Trampas:
- ¡No filtrar el CERA por «municipio >= 900»! Aragón tiene municipios reales con código
  INE 9xx (22901-22909 y 50901-50903, entidades agregadas). El CERA son las filas
  «Residentes ausentes» con Codmun 990 (en 2011 y 2015 traen votos; en 2026, ceros).
- En Open Data 2003 y 2007 el CERA es una mesa por provincia con municipio 000
  («5000001001 U», «2200000000 U», «RESIDENTES AUSENTES ZARAGOZA»): se descarta, igual
  que la 990 de los Excel. En 1983-1999 (municipio) no hay fila de CERA y la suma da
  exactamente el total oficial: ese voto, si lo hubo, va dentro de los municipios.
- Open Data no trae siglas, solo la denominación (en mayúsculas, a veces con mojibake
  «ESPAÃ‘A» en 2019): _SIGLAS les pone las siglas habituales a las candidaturas con
  familia política; el resto pasa con su denominación arreglada.
- Open Data 378 (municipio) de 2003 se queda 3.933 votos corto frente al oficial; por
  eso 2003 sale de las mesas (380/381), que sí cuadran.
- En 2003 la mesa 2200101001 U da 205 votos a candidaturas en 380 y 197 sumando 381;
  se usa 381 (el fichero de votos) para que totales y votos casen.
- Las cifras de los Excel vienen como float (61.0): se pasan a int.
- CUSEC = provincia(2) + municipio(3) + distrito(2) + sección(3); en Open Data son los
  10 primeros caracteres de cod_mesa («5029711015 C»/«4401303001U»).
"""

import csv
import json
import re
import unicodedata
from collections import defaultdict
from datetime import date

import requests
import xlrd

from ingestion.autonomicas import cache

COD_CCAA = "02"
SLUG = "aragon"
FUENTE = "https://www.aragon.es/portal-de-elecciones/resultados/anteriores"
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}
PROVINCIAS = ("huesca", "teruel", "zaragoza")
OPEN_DATA = "https://opendata.aragon.es/GA_OD_Core/download"
XLS = {  # escrutinio definitivo por mesa del Portal de Elecciones
    2011: "https://www.aragon.es/documents/d/guest/datosescrutinio_definitivo_{prov}-2011",
    2015: "https://www.aragon.es/documents/d/guest/datescrut_def_2015_{prov}",
    2026: "https://www.aragon.es/documents/d/guest/datescrut_def_auto_2026_{prov}",
}
MESAS_OD = (2003, 2007, 2019, 2023)  # mesas completas en Open Data (380 + 381)
MUNICIPIOS_OD = (1983, 1987, 1991, 1995, 1999)  # solo municipio

_FECHAS = [date(1983, 5, 8), date(1987, 6, 10), date(1991, 5, 26), date(1995, 5, 28),
           date(1999, 6, 13), date(2003, 5, 25), date(2007, 5, 27), date(2011, 5, 22),
           date(2015, 5, 24), date(2019, 5, 26), date(2023, 5, 28), date(2026, 2, 8)]
_MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
          "septiembre", "octubre", "noviembre", "diciembre"]
PROCESOS = [
    {"proceso": f"A02{f.year}{f.month:02d}", "fecha": f,
     "eleccion": f"Cortes de Aragón, {_MESES[f.month - 1]} de {f.year}"}
    for f in _FECHAS
]

# Denominación de Open Data (sin tildes, mayúsculas, espacios simples) -> siglas.
_SIGLAS = {
    "PARTIDO SOCIALISTA OBRERO ESPANOL": "PSOE",
    "PARTIDO POPULAR": "PP",
    "ALIANZA POPULAR / PARTIDO DEMOCRATA POPULAR / UNION LIBERAL": "AP-PDP-UL",
    "FEDERACION DE PARTIDOS DE ALIANZA POPULAR": "AP",
    "PARTIDO DEMOCRATA POPULAR": "PDP",
    "PARTIDO ARAGONES REGIONALISTA": "PAR",
    "PARTIDO ARAGONES": "PAR",
    "CENTRO DEMOCRATICO Y SOCIAL": "CDS",
    "PARTICO COMUNISTA DE ESPANA": "PCE",  # sic en la fuente
    "PARTIDO COMUNISTA DE ARAGON": "PCA",
    "IZQUIERDA UNIDA DE ARAGON": "IU",
    "IZQUIERDA UNIDA": "IU",
    "COALICION IZQUIERDA UNIDA": "IU",
    "CONVERGENCIA ALTERNATIVA DE ARAGON - IZQUIERDA UNIDA": "IU-CAA",
    "UNION ARAGONESISTA-CHUNTA ARAGONESISTA": "CHA",
    "CHUNTA ARAGONESISTA": "CHA",
    "CIUDADANOS-PARTIDO DE LA CIUDADANIA": "Cs",
    "CIUDADANOS-TU ARAGON": "Cs",
    "CIUDADANOS - TU ARAGON": "Cs",
    "PODEMOS-EQUO": "PODEMOS-EQUO",
    "PODEMOS ALIANZA VERDE": "PODEMOS-AV",
    "VOX": "VOX",
    "ARAGON EXISTE - COALICION EXISTE": "EXISTE",
    "TERUEL EXISTE-COALICION EXISTE": "EXISTE",
    "PARTIDO ANIMALISTA CONTRA EL MALTRATO ANIMAL": "PACMA",
    "PARTIDO ANIMALISTA CON EL MEDIO AMBIENTE": "PACMA",
    "ESCANOS EN BLANCO": "EB",
    "ESCANOS EN BLANCO PARA DEJAR ESCANOS VACIOS": "EB",
    "PARTIDO COMUNISTA DE LOS TRABAJADORES DE ESPANA": "PCTE",
    "FEDERACION DE LOS INDEPENDIENTES DE ARAGON": "FIA",
    "PARTIDO HUMANISTA": "PH",
}
_MESA = re.compile(r"(\d{1,2})-(\d{3})\s*-?\s*([A-Z])")


# ---------------------------------------------------------------- descargas

def _bajar(url: str, nombre: str, params: dict | None = None):
    ruta = cache(SLUG) / nombre
    if not ruta.exists() or ruta.stat().st_size == 0:
        r = requests.get(url, params=params, headers=CABECERAS, timeout=300)
        r.raise_for_status()
        ruta.write_bytes(r.content)
    return ruta


def _od(recurso: int, anio: int) -> list[dict]:
    """Un recurso de Aragón Open Data filtrado por elección (CSV en UTF-8)."""
    ruta = _bajar(OPEN_DATA, f"od_{recurso}_CA{anio}.csv",
                  {"resource_id": recurso, "formato": "csv",
                   "filters": json.dumps({"cod_elec": f"CA{anio}"})})
    with open(ruta, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def _arreglar(s: str) -> str:
    """Deshace el mojibake UTF-8 leído como cp1252 («ESPAÃ‘A» -> «ESPAÑA»)."""
    s = " ".join(s.split())
    if "Ã" not in s and "Â" not in s:
        return s
    b = bytearray()
    for ch in s:
        try:
            b += ch.encode("cp1252")
        except UnicodeEncodeError:
            b += ch.encode("latin-1", errors="replace")
    try:
        return b.decode("utf-8")
    except UnicodeDecodeError:
        return s


def _siglas(nombre: str) -> str:
    nombre = _arreglar(nombre)
    clave = "".join(c for c in unicodedata.normalize("NFD", nombre.upper())
                    if unicodedata.category(c) != "Mn")
    return _SIGLAS.get(clave, nombre)


def _anio(proceso: str) -> int:
    return int(proceso[3:7])


# ---------------------------------------------------------------- mesas

def _mesas_xls(anio: int):
    """Excel del portal: (cusec, censo, blancos, nulos, {siglas: votos}) por mesa."""
    for prov in PROVINCIAS:
        url = XLS[anio].format(prov=prov)
        ruta = _bajar(url, url.rsplit("/", 1)[1] + ".xls")
        hoja = xlrd.open_workbook(ruta).sheet_by_name("Mesas")
        cab = [str(c).strip() for c in hoja.row_values(0)]
        low = [c.lower() for c in cab]
        i_nul = next(i for i, c in enumerate(low) if "nulo" in c)
        i_bla = next(i for i, c in enumerate(low) if "blanc" in c)
        i_cen = next((i for i, c in enumerate(low) if c.replace("_", " ") == "censo total"), None)
        i_alta = next(i for i, c in enumerate(low) if "alta" in c)
        primera = max(i_nul, i_bla) + 1
        assert low[3] == "mesa" and low[4] == "censo", cab
        partidos = cab[primera:]
        for i in range(1, hoja.nrows):
            f = hoja.row_values(i)
            if not isinstance(f[0], float) or not isinstance(f[1], float):
                continue  # fila «Total»
            mun = int(f[1])
            m = _MESA.fullmatch(str(f[3]).strip())
            if mun in (990, 999) or "ausentes" in str(f[2]).lower() or not m:
                continue  # residentes ausentes (CERA)
            censo = int(f[i_cen] or 0) if i_cen is not None else int(f[4] or 0) + int(f[i_alta] or 0)
            cusec = f"{int(f[0]):02d}{mun:03d}{int(m.group(1)):02d}{m.group(2)}"
            votos = defaultdict(int)
            for s, v in zip(partidos, f[primera:]):
                if s:
                    votos[s] += int(v or 0)
            yield cusec, censo, int(f[i_bla] or 0), int(f[i_nul] or 0), dict(votos)


def _mesas_od(anio: int):
    """Open Data 380 + 381: (cusec, censo, blancos, nulos, {siglas: votos}) por mesa."""
    votos = defaultdict(lambda: defaultdict(int))
    for r in _od(381, anio):
        votos[r["cod_mesa"].strip()][_siglas(r["nombre_par"])] += int(r["votos_e"] or 0)
    for r in _od(380, anio):
        mesa = r["cod_mesa"].strip()
        cusec = mesa[:10]
        if not cusec.isdigit() or int(cusec[2:5]) in (0, 990, 999) or "AUSENTES" in r["municipio"].upper():
            continue
        yield (cusec, int(r["electores_e"] or 0), int(r["blancos_e"] or 0),
               int(r["nulos_e"] or 0), dict(votos.get(mesa, {})))


def _mesas(proceso: str):
    anio = _anio(proceso)
    if anio in XLS:
        return _mesas_xls(anio)
    if anio in MESAS_OD:
        return _mesas_od(anio)
    return iter(())


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


# ---------------------------------------------------------------- municipios

def _votos_mun(anio: int) -> dict:
    acc = defaultdict(int)
    for r in _od(379, anio):
        acc[(r["cod_municipio"].zfill(5), _siglas(r["nombre_par"]))] += int(r["votos_m"] or 0)
    return acc


def municipios(proceso: str):
    anio = _anio(proceso)
    if anio not in MUNICIPIOS_OD:
        return
    cand = defaultdict(int)
    for (mun, _), n in _votos_mun(anio).items():
        cand[mun] += n
    for r in sorted(_od(378, anio), key=lambda r: r["cod_municipio"]):
        mun = r["cod_municipio"].zfill(5)
        if int(mun[2:]) in (0, 990, 999) or "AUSENTES" in r["nombre_m"].upper():
            continue
        yield {"cod_mun": mun, "censo": int(r["electores_m"] or 0),
               "votos_blanco": int(r["blancos_m"] or 0), "votos_nulos": int(r["nulos_m"] or 0),
               "votos_candidaturas": cand.get(mun, 0)}


def votos_municipios(proceso: str):
    anio = _anio(proceso)
    if anio not in MUNICIPIOS_OD:
        return
    for (mun, siglas), n in sorted(_votos_mun(anio).items()):
        if n and int(mun[2:]) not in (0, 990, 999):
            yield {"cod_mun": mun, "siglas": siglas, "votos": n}


# ---------------------------------------------------------------- comprobación

def oficial(proceso: str) -> dict:
    """Resultado oficial de la comunidad (Open Data 372/373, CERA incluido)."""
    anio = _anio(proceso)
    c = _od(372, anio)[0]
    por = defaultdict(int)
    for r in _od(373, anio):
        por[_siglas(r["nombre_par"])] += int(r["votos_c"] or 0)
    return {"censo": int(c["electores_c"]), "votos_candidaturas": int(c["candidatura_c"]),
            "votos_blanco": int(c["blancos_c"]), "votos_nulos": int(c["nulos_c"]), "partidos": dict(por)}


def comparar() -> None:
    print("\nproceso    nivel      munis  cand. módulo  cand. oficial  diferencia")
    for p in PROCESOS:
        pr = p["proceso"]
        m = list(municipios(pr))
        if m:
            nivel, munis = "municipio", len({r["cod_mun"] for r in m})
            suma = sum(r["votos"] for r in votos_municipios(pr))
        else:
            s = list(secciones(pr))
            nivel, munis = f"sección {len(s)}", len({r['cod_seccion'][:5] for r in s})
            suma = sum(r["votos"] for r in votos(pr))
        of = oficial(pr)["votos_candidaturas"]
        print(f"{pr}  {nivel:<13} {munis:>4}  {suma:>12,}  {of:>13,}  {suma - of:>+8,} ({100 * (suma - of) / of:+.2f} %)")


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
    comparar()
