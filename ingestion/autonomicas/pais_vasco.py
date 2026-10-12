"""Elecciones al Parlamento Vasco (1980-2024) por sección censal o por municipio (Gobierno Vasco).

Fuente: «Descarga de ficheros de resultados de elecciones» del Gobierno Vasco
(Departamento de Seguridad, Dirección de Procesos Electorales; resultados
definitivos), en el portal electoral de euskadi.eus (hoy hauteskundeak.euskadi.eus):

    https://hauteskundeak.euskadi.eus/informacion/descargas-de-ficheros-de-resultados-de-elecciones/webelec00-content/es/

Hay un ZIP por proceso (generales, europeas, juntas generales, municipales y
Parlamento Vasco desde 1977) en CSV o en XLS. Los del Parlamento Vasco son
P80, P84, P86, P90, P94, P98, P01, P05, P09, P12, P16, P20 y P24:

    https://www.euskadi.eus/contenidos/informacion/w_em_descargas/es_def/adjuntos/csv/P<aa>_c.zip

    CirP<aa>_c.csv   por territorio histórico (circunscripción): el resultado oficial
    MunP<aa>_c.csv   por municipio
    MesP<aa>_c.csv   por mesa
    ElecP<aa>_c.csv  electos
(en 2024 los ficheros se llaman CirPV24_c.csv, MunPV24_c.csv y MesPV24_c.csv; el
enlace de P24 no sale en el HTML de la página, pero la URL responde).

Formatos (todos en Windows-1252; la fila de cabecera es la que empieza por «TH»):
- 1980-2012: separados por «,», una sola fila de cabecera
      TH,Cod.Municipio,AMBITO,Distrito,Sección,Mesa,Censo,Votantes,Nulos,Válidos,
      Blancos,Votos Cand.,Abstenciones,<una columna de votos por candidatura>
- 2016: igual pero separado por «;» y con dos filas de título encima de la cabecera.
- 2020: separado por «;», con columnas TH;Ámbito;Nota;Cod Municipio;...;
      Votos Candidatura;Abstención;<candidaturas>, y los códigos entre comillas con un
      tabulador delante («"\\t051"»).
- 2024: formato «ancho»: cada candidatura ocupa tres columnas (votos y dos
  porcentajes); las siglas están en la fila de encima de la cabecera y los votos en
  la columna «V. Candidaturas» (ojo: la columna «Votos Candidaturas» es el total).
  Códigos con tabulador, como en 2020.
- Las candidaturas son por territorio: si una no se presenta, sus celdas van vacías
  (cuentan como 0). La provincia no viene: se saca del territorio histórico (Álava 01,
  Gipuzkoa 20, Bizkaia 48). Municipio (3), distrito (2) y sección (3) son los del INE;
  las mesas (U, A, B, ...) se suman a su sección.

Códigos de municipio: son los del INE vigentes en cada elección (los nombres casan
año a año y las segregaciones aparecen cuando tocan: Derio, Erandio, Loiu, Sondika y
Zamudio (48901-48905) desde 1984, Lasarte-Oria (20902) desde 1986, Zierbena (48913)
desde 1998, Ziortza-Bolibar (48915) desde 2009 —en 2001 y 2005 va dentro de las
secciones de Markina-Xemein, sin forma de separarlo—, etc.). La única traducción es
Usansolo en 2024 (ver RECODIFICAR). Los cambios de nombre sin cambio de código
(Arrazua/Arratzua-Ubarrundia, Bidegoian/Bidania-Goiatz) no afectan.

CERA: desde 1986 cada territorio tiene un pseudo-municipio 999 «MUNICIPIO CERA ...»
con el censo y (hasta 2020) los votos de los residentes ausentes. Se descarta. En 2024
la fila 999 solo trae el censo y los votos CERA (6.989) no están en ningún fichero.
En 1980 y 1984 no hay fila CERA.

Ficheros por mesa defectuosos (1980, 1984 y 1986): sus sumas no casan con el
resultado oficial (CirPxx), así que para esos años se usa el fichero por municipio
(municipios()/votos_municipios()) y secciones()/votos() devuelven []:
- 1980: el fichero por mesa da 31.777 electores y 1.769 votos a candidaturas de más
  que CirP80 (Barakaldo, Bermeo, Ermua, Karrantza... con censos imposibles). El
  fichero por municipio tampoco cuadra del todo con CirP80 (censo +12.400,
  candidaturas -217); es lo más cercano y se usa tal cual, sin retocar nada.
- 1984: por mesa faltan 1.381 electores y 425 votos (Bilbao, Donostia, ...); por
  municipio cuadra exacto con CirP84.
- 1986: al fichero por mesa le faltan 10 municipios de Bizkaia (Artzentales,
  Karrantza, Galdames, Gordexola, Güeñes, Lanestosa, Sopuerta, Trucios, Balmaseda y
  Zalla); por municipio cuadra exacto con CirP86 salvo una errata en Laudio
  (CORREGIR_MUN). En Vitoria-Gasteiz los votos por partido suman 42 menos que
  «Votos Cand.» en los tres ficheros (también en el oficial): se deja así.
- 1990: por mesa cuadra salvo 58 votos de EE en Donostia (82.278 frente a 82.336 por
  municipio). Se dan las dos cosas: secciones (mapa) y municipios (página de la
  comunidad, exacto).
De 1994 a 2020, mesas = municipios = circunscripciones (con el CERA), voto a voto.
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
FUENTE = ("https://hauteskundeak.euskadi.eus/informacion/descargas-de-ficheros-de-resultados-de-elecciones/"
          "webelec00-content/es/")
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}
BASE = "https://www.euskadi.eus/contenidos/informacion/w_em_descargas/es_def/adjuntos/csv/"

_MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
          "septiembre", "octubre", "noviembre", "diciembre"]

# (fecha, ZIP, sufijo de los CSV de dentro: Mes<sufijo>.csv, Mun<sufijo>.csv, Cir<sufijo>.csv)
_ELECCIONES = [
    (date(1980, 3, 9), "P80_c.zip", "P80_c"),
    (date(1984, 2, 26), "P84_c.zip", "P84_c"),
    (date(1986, 11, 30), "P86_c.zip", "P86_c"),
    (date(1990, 10, 28), "P90_c.zip", "P90_c"),
    (date(1994, 10, 23), "P94_c.zip", "P94_c"),
    (date(1998, 10, 25), "P98_c.zip", "P98_c"),
    (date(2001, 5, 13), "P01_c.zip", "P01_c"),
    (date(2005, 4, 17), "P05_c.zip", "P05_c"),
    (date(2009, 3, 1), "P09_c.zip", "P09_c"),
    (date(2012, 10, 21), "P12_c.zip", "P12_c"),
    (date(2016, 9, 25), "P16_c.zip", "P16_c"),
    (date(2020, 7, 12), "P20_c.zip", "P20_c"),
    (date(2024, 4, 21), "P24_c.zip", "PV24_c"),
]


def _proceso(f: date) -> str:
    return f"A{COD_CCAA}{f.year}{f.month:02d}"


PROCESOS = [{"proceso": _proceso(f), "fecha": f,
             "eleccion": f"Parlamento Vasco, {_MESES[f.month - 1]} de {f.year}"}
            for f, _, _ in _ELECCIONES]

# proceso -> (URL del ZIP, sufijo de los CSV)
URLS = {_proceso(f): (BASE + z, suf) for f, z, suf in _ELECCIONES}

# Procesos cuyo fichero por mesa no cuadra con el oficial (ver docstring): solo municipios.
SIN_SECCIONES = {"A16198003", "A16198402", "A16198611"}
# Procesos que se dan por municipio: los anteriores y 1990 (su fichero por mesa pierde 58 votos).
CON_MUNICIPIOS = SIN_SECCIONES | {"A16199010"}

COD_CERA = "999"

# Erratas del fichero por municipio corregidas con el fichero por mesa, solo cuando la
# corrección hace que la suma de municipios case con el oficial (CirPxx) partido a partido.
# 1986, Laudio/Llodio (01036): MunP86 da EA 1.772, CDS 808 y PSE-PSOE 2.309, pero sus
# mesas suman 1.672, 798 y 2.310, y con esos valores EA (181.175), CDS (40.445) y
# PSE-PSOE (252.233) cuadran con CirP86.
CORREGIR_MUN = {
    ("A16198611", "01036"): {"EA": 1672, "CDS": 798, "PSE-PSOE": 2310},
}

# Secciones con código antiguo en la fuente -> CUSEC del INE, por proceso.
# Usansolo: en abril de 2024 aún votó como distrito 04 de Galdakao (48036-04-001..003),
# pero el INE ya lo tiene segregado como municipio 48916 (secciones 4891601001..003 en
# el seccionado de 2024; Interior lo usa así desde las europeas de junio de 2024, con
# el mismo censo salvo ±2 en las dos primeras secciones). Antes de 2024 Usansolo era
# legalmente parte de Galdakao y se deja en 48036.
RECODIFICAR = {
    "A16202404": {
        "4803604001": "4891601001",
        "4803604002": "4891601002",
        "4803604003": "4891601003",
    },
}


def _sin_tildes(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn").lower().strip()


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


def _csv(proceso: str, tipo: str) -> list[list[str]]:
    """Filas del CSV «Mes», «Mun» o «Cir» del proceso (el ZIP se descarga una vez a la caché)."""
    url, suf = URLS[proceso]
    ruta = cache(SLUG) / url.rsplit("/", 1)[-1]
    if not ruta.exists():
        r = requests.get(url, headers=CABECERAS, timeout=120)
        r.raise_for_status()
        ruta.write_bytes(r.content)
    nombre = f"{tipo}{suf}.csv"
    with zipfile.ZipFile(ruta) as z:
        interno = next(n for n in z.namelist() if n.rsplit("/", 1)[-1] == nombre)
        texto = z.read(interno).decode("cp1252")
    sep = ";" if texto.count(";") > texto.count(",") else ","
    return list(csv.reader(io.StringIO(texto), delimiter=sep))


def _tabla(proceso: str, tipo: str) -> list[dict]:
    """Filas del fichero por mesa («Mes») o por municipio («Mun»), normalizadas:
    {"mun", "cera", "distrito", "seccion", "censo", "votos_blanco", "votos_nulos",
     "votos_candidaturas", "partidos": {siglas: votos}}."""
    filas = _csv(proceso, tipo)
    hi = next(k for k, f in enumerate(filas) if f and _sin_tildes(f[0]) == "th")
    cab = [_sin_tildes(c) for c in filas[hi]]

    def col(*nombres: str) -> int | None:
        return next((k for k, c in enumerate(cab) if c in nombres), None)

    i_mun = col("cod.municipio", "cod municipio")
    i_dis, i_sec = col("distrito"), col("seccion")
    i_censo, i_nul, i_bla = col("censo"), col("nulos"), col("blancos")
    i_cand = col("votos cand.", "votos candidatura", "votos candidaturas")
    if "v. candidaturas" in cab:   # formato ancho (2024): siglas en la fila de encima
        partidos = [(k, filas[hi - 1][k].strip()) for k, c in enumerate(cab) if c == "v. candidaturas"]
    else:                          # una columna por candidatura tras «Abstención(es)»
        i_abs = next(k for k, c in enumerate(cab) if c.startswith("abstenc"))
        partidos = [(k, filas[hi][k].strip()) for k in range(i_abs + 1, len(cab)) if filas[hi][k].strip()]

    out = []
    for f in filas[hi + 1:]:
        if not f or not f[0].strip():
            continue
        mun = _codigo(f[i_mun])
        if not mun.isdigit():
            continue
        fila = {"mun": f"{_provincia(f[0])}{int(mun):03d}", "cera": mun == COD_CERA,
                "distrito": _codigo(f[i_dis]) if i_dis is not None else "",
                "seccion": _codigo(f[i_sec]) if i_sec is not None else "",
                "censo": _n(f[i_censo]), "votos_blanco": _n(f[i_bla]), "votos_nulos": _n(f[i_nul]),
                "votos_candidaturas": _n(f[i_cand]), "partidos": {}}
        for k, siglas in partidos:
            n = _n(f[k]) if k < len(f) else 0
            if n:
                fila["partidos"][siglas] = fila["partidos"].get(siglas, 0) + n
        out.append(fila)
    return out


def _nuevo() -> dict:
    return {"censo": 0, "votos_blanco": 0, "votos_nulos": 0, "votos_candidaturas": 0, "partidos": {}}


def _sumar(destino: dict, fila: dict) -> None:
    for c in ("censo", "votos_blanco", "votos_nulos", "votos_candidaturas"):
        destino[c] += fila[c]
    for siglas, n in fila["partidos"].items():
        destino["partidos"][siglas] = destino["partidos"].get(siglas, 0) + n


_CACHE: dict[tuple[str, str], dict] = {}


def _agregado(proceso: str) -> dict[str, dict]:
    """Por sección (CUSEC), sumando las mesas y sin el CERA."""
    if (proceso, "sec") not in _CACHE:
        recod = RECODIFICAR.get(proceso, {})
        out: dict[str, dict] = {}
        for f in _tabla(proceso, "Mes"):
            if f["cera"] or not (f["distrito"].isdigit() and f["seccion"].isdigit()):
                continue
            cod = f"{f['mun']}{int(f['distrito']):02d}{int(f['seccion']):03d}"
            _sumar(out.setdefault(recod.get(cod, cod), _nuevo()), f)
        _CACHE[(proceso, "sec")] = out
    return _CACHE[(proceso, "sec")]


def _agregado_mun(proceso: str) -> dict[str, dict]:
    """Por municipio (fichero «Mun»), sin el CERA."""
    if (proceso, "mun") not in _CACHE:
        out: dict[str, dict] = {}
        for f in _tabla(proceso, "Mun"):
            if not f["cera"]:
                _sumar(out.setdefault(f["mun"], _nuevo()), f)
        for (pr, mun), cambios in CORREGIR_MUN.items():
            if pr == proceso:
                out[mun]["partidos"].update(cambios)
        _CACHE[(proceso, "mun")] = out
    return _CACHE[(proceso, "mun")]


def secciones(proceso: str) -> Iterable[dict]:
    if proceso in SIN_SECCIONES:
        return
    for cod, s in sorted(_agregado(proceso).items()):
        yield {"cod_seccion": cod, "censo": s["censo"], "votos_blanco": s["votos_blanco"],
               "votos_nulos": s["votos_nulos"], "votos_candidaturas": s["votos_candidaturas"]}


def votos(proceso: str) -> Iterable[dict]:
    if proceso in SIN_SECCIONES:
        return
    for cod, s in sorted(_agregado(proceso).items()):
        for siglas, n in s["partidos"].items():
            yield {"cod_seccion": cod, "siglas": siglas, "votos": n}


def municipios(proceso: str) -> Iterable[dict]:
    if proceso not in CON_MUNICIPIOS:
        return
    for cod, s in sorted(_agregado_mun(proceso).items()):
        yield {"cod_mun": cod, "censo": s["censo"], "votos_blanco": s["votos_blanco"],
               "votos_nulos": s["votos_nulos"], "votos_candidaturas": s["votos_candidaturas"]}


def votos_municipios(proceso: str) -> Iterable[dict]:
    if proceso not in CON_MUNICIPIOS:
        return
    for cod, s in sorted(_agregado_mun(proceso).items()):
        for siglas, n in s["partidos"].items():
            yield {"cod_mun": cod, "siglas": siglas, "votos": n}


def oficial(proceso: str) -> dict:
    """Resultado oficial por circunscripción (fichero «Cir», CERA incluido), para comprobar."""
    filas = _csv(proceso, "Cir")
    hi = next(k for k, f in enumerate(filas) if f and _sin_tildes(f[0]) in ("ambito", "th"))
    cab = [_sin_tildes(c) for c in filas[hi]]
    ic = {c: k for k, c in enumerate(cab)}
    i_cand = next(ic[c] for c in ("votos cand.", "votos candidatura", "votos candidaturas") if c in ic)
    if "v. candidaturas" in cab:
        partidos = [(k, filas[hi - 1][k].strip()) for k, c in enumerate(cab) if c == "v. candidaturas"]
    else:
        i_abs = next(k for k, c in enumerate(cab) if c.startswith("abstenc"))
        partidos = [(k, filas[hi][k].strip()) for k in range(i_abs + 1, len(cab)) if filas[hi][k].strip()]
    tot = {"censo": 0, "votos_blanco": 0, "votos_nulos": 0, "votos_candidaturas": 0, "partidos": {}}
    for f in filas[hi + 1:]:
        if f and f[0].strip():
            tot["censo"] += _n(f[ic["censo"]])
            tot["votos_blanco"] += _n(f[ic["blancos"]])
            tot["votos_nulos"] += _n(f[ic["nulos"]])
            tot["votos_candidaturas"] += _n(f[i_cand])
            for k, siglas in partidos:
                tot["partidos"][siglas] = tot["partidos"].get(siglas, 0) + (_n(f[k]) if k < len(f) else 0)
    return tot


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
    print("\n== Votos a candidaturas frente al oficial (CirPxx, con CERA)")
    for p in PROCESOS:
        pr = p["proceso"]
        datos = _agregado_mun(pr) if pr in CON_MUNICIPIOS else _agregado(pr)
        nuestro = sum(s["votos_candidaturas"] for s in datos.values())
        filas_cera = [f for f in _tabla(pr, "Mes") if f["cera"]]
        cera = sum(f["votos_candidaturas"] for f in filas_cera)
        ofi = oficial(pr)
        of = ofi["votos_candidaturas"]
        # partido a partido: nuestro + CERA frente al oficial
        por: dict[str, int] = {}
        for s in list(datos.values()) + filas_cera:
            for siglas, n in s["partidos"].items():
                por[siglas] = por.get(siglas, 0) + n
        difs = {k: por.get(k, 0) - v for k, v in ofi["partidos"].items() if por.get(k, 0) != v}
        print(f"{pr} ({'municipio' if pr in CON_MUNICIPIOS else 'sección'}): {nuestro:,} sin CERA"
              f" + {cera:,} CERA = {nuestro + cera:,} · oficial {of:,} · dif {nuestro + cera - of:+,}"
              f" · municipios {len({c[:5] for c in datos})}"
              f" · partidos que no cuadran: {difs or 'ninguno'}")
