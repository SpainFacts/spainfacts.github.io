"""Elecciones a Les Corts Valencianes (Comunitat Valenciana), de 1983 a 2023.

Por sección censal de 1987 a 2023 y por municipio en 1983.

Fuentes
-------
1987-2023 · portal de datos abiertos de la Generalitat Valenciana (dadesobertes.gva.es),
conjuntos «Resultados de elecciones a Les Corts aaaa» (pre-result-elec-autonom-aaaa),
licencia CC BY 4.0. Un CSV por elección con el escrutinio definitivo desglosado por mesa
(URLS, abajo; de 5,7 a 17,5 MB cada uno).

1983 · no hay conjunto en dadesobertes (empieza en 1987). Sale del Arxiu Històric
Electoral de ARGOS (Generalitat Valenciana, www.argos.gva.es/ahe), que publica una
página por municipio y elección con censo, votantes, válidos, blancos y votos por
candidatura:

    http://www.argos.gva.es/ahe/pls/argos_elec/DMEDB_Elecmunicipios.informeElecDetallado
        ?aNMuniId=3005&aNNumElec=1&aVTipoElec=A17&aVFechaElec=1983&aVLengua=C

Se rastrean ~545 páginas (una por municipio, ~1-2 min) y se guardan ya leídas en
data/autonomicas_cache/valencia/A10198305.csv. El «Mapa electoral municipal… Elecciones
Autonómicas» de dadesobertes también llega a 1983, pero solo trae porcentajes de cinco
partidos: no sirve.

Formatos (cambian entre años)
-----------------------------
2023 · CSV con comas, ISO-8859-1, cabecera en valenciano:
    Any, CProv, Desc_Prov, CMun, Codimuni, Desc_municipi, CCom, Desc_Comarca,
    CodiMesa, Districte, Secció, Mesa, CENS, VOTANTS, V_NULS, V_BLANC, V_CAND,
    CODI_CANDIDATURA, SIGLES_CANDIDATURA, DESC_CANDIDATURA
1987-2019 · CSV con punto y coma, UTF-8, cabecera en castellano:
    ANYO; NUM_ELEC; COD_PROV; PROVINCIA; COD_COMARCA; COMARCA; COD_MUNICIPIO; MUNICIPIO;
    DISTRITO; SECCION; MESA; CANDIDATURAS; CENSO; VOTANTES; VALIDOS; BLANCOS;
    ABSTENCIONES; NULOS; CANDIDATO_COD; CANDIDATO_SIGLAS; CANDIDATO_DESC; VOTOS
En los dos, una fila por mesa y candidatura: los datos de la mesa se repiten en cada
fila; V_CAND / VOTOS son los votos de ESA candidatura. Aquí los votos a candidaturas de
la sección se suman de las filas (no de CANDIDATURAS), para que cuadren con votos().

Trampas
-------
- Códigos sin ceros a la izquierda: municipio 3001 = INE 03001; distrito 1 y sección 1
  son "01" y "001". CUSEC = municipio(5) + distrito(2) + sección(3); las mesas (U, A, B…)
  se suman a la sección.
- Los ficheros usan el código de municipio ACTUAL en todos los años: Gátova sale como
  46902 (Valencia) también en 1987 y 1991, cuando era 12066 y votaba en Castellón (pasó a
  Valencia en 1995). Se deja tal cual. Los municipios segregados después de una elección
  (p. ej. Benicull de Xúquer 46904, 2003-2007) no salen en las anteriores.
- CERA (residentes ausentes): solo viene en 1987 («Extranjeros …», municipios 3990,
  12990, 46990), 2003 (12990, 46990) y 2007 (los tres), y en 2023 (CMun 990, Districte 99).
  Se descarta siempre. En 1991, 1995, 1999, 2011, 2015 y 2019 el fichero no lo trae: la
  diferencia con el oficial es el CERA.
- 1987: aun quitando el CERA, el fichero tiene 222 votos a candidaturas más que el
  oficial (1.986.954 frente a 1.986.732); son actas, no se corrigen.
- 2019: 266 mesas (casi todas de Castellón) con VOTANTES ≠ candidaturas + blancos +
  nulos y VALIDOS > VOTANTES por unos pocos votos; se toman los votos tal cual.
- 2023: ocho mesas de Castellón con descuadres de ±1-5 votos y una de Novelda
  (01-004-A) toda a cero; se dejan.
- Siglas distintas para la misma candidatura en un mismo año (por provincia): se
  unifican con SIGLAS (2003 «L'ENTESA», 2011 «PARTIDO POPULAR», 2015 «ESPAÑA-2000»,
  2019 «COMPROMíS», 2023 «CS»). Las demás se dejan como las publica la fuente
  («P.S.O.E.», «C's», «PSOE-P»…): la familia política se asigna en dbt.
- 2023: las siglas «CENTRO MODERADO» llevan la denominación «LOS VERDES-ECOPACIFISTAS»
  (así en la fuente). Se dejan tal cual.
- 1983 (ARGOS): no hay nulos; se calculan como votantes − válidos. El municipio de
  Pilar de la Horadada (03902, segregado en 1986) y los demás posteriores salen vacíos.
"""

import csv
import io
import re
from collections.abc import Iterable
from concurrent.futures import ThreadPoolExecutor
from datetime import date

import requests

from ingestion.autonomicas import cache

COD_CCAA = "10"
SLUG = "valencia"
FUENTE = "https://dadesobertes.gva.es/es/dataset/?q=pre-result-elec-autonom"
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

PROCESOS = [
    {"proceso": "A10198305", "fecha": date(1983, 5, 8),
     "eleccion": "Corts Valencianes, mayo de 1983"},
    {"proceso": "A10198706", "fecha": date(1987, 6, 10),
     "eleccion": "Corts Valencianes, junio de 1987"},
    {"proceso": "A10199105", "fecha": date(1991, 5, 26),
     "eleccion": "Corts Valencianes, mayo de 1991"},
    {"proceso": "A10199505", "fecha": date(1995, 5, 28),
     "eleccion": "Corts Valencianes, mayo de 1995"},
    {"proceso": "A10199906", "fecha": date(1999, 6, 13),
     "eleccion": "Corts Valencianes, junio de 1999"},
    {"proceso": "A10200305", "fecha": date(2003, 5, 25),
     "eleccion": "Corts Valencianes, mayo de 2003"},
    {"proceso": "A10200705", "fecha": date(2007, 5, 27),
     "eleccion": "Corts Valencianes, mayo de 2007"},
    {"proceso": "A10201105", "fecha": date(2011, 5, 22),
     "eleccion": "Corts Valencianes, mayo de 2011"},
    {"proceso": "A10201505", "fecha": date(2015, 5, 24),
     "eleccion": "Corts Valencianes, mayo de 2015"},
    {"proceso": "A10201904", "fecha": date(2019, 4, 28),
     "eleccion": "Corts Valencianes, abril de 2019"},
    {"proceso": "A10202305", "fecha": date(2023, 5, 28),
     "eleccion": "Corts Valencianes, mayo de 2023"},
]

_GVA = "https://dadesobertes.gva.es/dataset/"
URLS = {
    "A10198706": _GVA + "a460a562-f98c-4de7-854a-80b470e32b0a/resource/213ed4cd-1f7c-496c-8632-"
                 "8e0e7a2e3532/download/resultados-elecciones-autonomicas-1-1987.csv",
    "A10199105": _GVA + "c471dcef-5f8c-4b25-a2b8-67fbf984bd4d/resource/93ae8d1d-2ae9-4a6d-bdf9-"
                 "0afce02a68a9/download/resultados-elecciones-autonomicas-1-1991.csv",
    "A10199505": _GVA + "2d5f1b52-16fa-4b45-8be2-05e0fabc0bf8/resource/0208dae1-f391-4979-8c9b-"
                 "41e1a93f96ce/download/resultados-elecciones-autonomicas-1-1995.csv",
    "A10199906": _GVA + "8db4ba36-b916-422e-9c6d-54cb80d71793/resource/15c896c5-ef68-4ff5-a54d-"
                 "3aac6fda794c/download/resultados-elecciones-autonomicas-1-1999.csv",
    "A10200305": _GVA + "d5bd6f04-6241-4b68-99e6-d672c577759d/resource/137f29b0-09d1-49cc-9e97-"
                 "17d73cdb0a7b/download/resultados-elecciones-autonomicas-1-2003.csv",
    "A10200705": _GVA + "5bb24ae7-1edf-4063-af31-3597a93c3b94/resource/72caa9fa-a7ce-4e1f-9a92-"
                 "9cf0427d4d4e/download/resultados-elecciones-autonomicas-1-2007.csv",
    "A10201105": _GVA + "19427339-0190-403f-a21b-e451fe0755d7/resource/ce84c2db-5aad-42e2-87b1-"
                 "ff5e303e24cc/download/resultados-elecciones-autonomicas-1-2011.csv",
    "A10201505": _GVA + "b0da3175-5548-4fde-8c14-8598992254ee/resource/eb90d248-55c8-4921-aa91-"
                 "d21538b89fdf/download/resultados-elecciones-autonomicas-1-2015.csv",
    "A10201904": _GVA + "76c7861d-c10f-4d75-9749-4f07b28e7339/resource/f7449546-df34-40b3-b84a-"
                 "006d4736063a/download/resultados-elecciones-autonomicas-1-2019.csv",
    "A10202305": _GVA + "dfbe99da-62d8-4be9-86bd-4ac965abfe03/resource/60f818a5-9ae2-483a-ad31-"
                 "f61b8d016513/download/resultados-elecciones-autonomicas-1-2023.csv",
}

ARGOS = ("http://www.argos.gva.es/ahe/pls/argos_elec/DMEDB_Elecmunicipios.informeElecDetallado"
         "?aNMuniId={mun}&aNNumElec=1&aVTipoElec=A17&aVFechaElec={anio}&aVLengua=C")
SOLO_MUNICIPIO = {"A10198305"}

# Misma candidatura con siglas distintas dentro de una elección (por provincia).
SIGLAS = {
    "A10200305": {"L'ENTESA": "ENTESA"},
    "A10201105": {"PARTIDO POPULAR": "PP"},
    "A10201505": {"ESPAÑA-2000": "ESPAÑA 2000"},
    "A10201904": {"COMPROMíS": "COMPROMÍS"},
    "A10202305": {"CS": "Cs"},
}


def _descargar(proceso: str) -> bytes:
    ruta = cache(SLUG) / f"{proceso}.csv"
    if not ruta.exists():
        r = requests.get(URLS[proceso], headers=CABECERAS, timeout=300)
        r.raise_for_status()
        ruta.write_bytes(r.content)
    return ruta.read_bytes()


def _filas(proceso: str) -> list[dict]:
    """Filas del CSV por mesa, con nombres de campo comunes a todos los años.

    Campos: mun, dist, secc, mesa, censo, blancos, nulos, siglas, votos (enteros salvo
    los códigos y las siglas).
    """
    b = _descargar(proceso)
    if proceso == "A10202305":
        lector = csv.DictReader(io.StringIO(b.decode("latin-1")))
        campos = ("CMun", "Codimuni", "Districte", "Secció", "CodiMesa", "CENS",
                  "V_BLANC", "V_NULS", "SIGLES_CANDIDATURA", "V_CAND")
    else:
        lector = csv.DictReader(io.StringIO(b.decode("utf-8")), delimiter=";")
        campos = ("COD_MUNICIPIO", "COD_MUNICIPIO", "DISTRITO", "SECCION", "MESA", "CENSO",
                  "BLANCOS", "NULOS", "CANDIDATO_SIGLAS", "VOTOS")
    cmun, mun, dist, secc, mesa, censo, blancos, nulos, siglas, votos = campos
    cambios = SIGLAS.get(proceso, {})
    filas = []
    for f in lector:
        s = f[siglas].strip()
        filas.append({
            "cmun": int(f[cmun]), "mun": f[mun].strip(), "dist": f[dist].strip(),
            "secc": f[secc].strip(), "mesa": f[mesa].strip(),
            "censo": int(f[censo] or 0), "blancos": int(f[blancos] or 0),
            "nulos": int(f[nulos] or 0), "siglas": cambios.get(s, s),
            "votos": int(f[votos] or 0),
        })
    return filas


def _seccion(f: dict) -> str | None:
    """CUSEC del INE de la fila, o None si es CERA o no tiene sección real."""
    if f["dist"] == "99" or f["cmun"] % 1000 >= 990:
        return None
    try:
        return f"{int(f['mun']):05d}{int(f['dist']):02d}{int(f['secc']):03d}"
    except ValueError:
        return None


def secciones(proceso: str) -> Iterable[dict]:
    if proceso in SOLO_MUNICIPIO:
        return []
    mesas: dict[tuple, tuple[str, dict]] = {}
    votos_cand: dict[tuple, int] = {}
    for f in _filas(proceso):
        sec = _seccion(f)
        if sec is None:
            continue
        clave = (sec, f["mesa"])
        mesas[clave] = (sec, f)
        votos_cand[clave] = votos_cand.get(clave, 0) + f["votos"]
    tot: dict[str, dict] = {}
    for clave, (sec, f) in mesas.items():
        t = tot.setdefault(sec, {"cod_seccion": sec, "censo": 0, "votos_blanco": 0,
                                 "votos_nulos": 0, "votos_candidaturas": 0})
        t["censo"] += f["censo"]
        t["votos_blanco"] += f["blancos"]
        t["votos_nulos"] += f["nulos"]
        t["votos_candidaturas"] += votos_cand[clave]
    return list(tot.values())


def votos(proceso: str) -> Iterable[dict]:
    if proceso in SOLO_MUNICIPIO:
        return []
    tot: dict[tuple, int] = {}
    for f in _filas(proceso):
        sec = _seccion(f)
        if sec is None:
            continue
        tot[(sec, f["siglas"])] = tot.get((sec, f["siglas"]), 0) + f["votos"]
    return [{"cod_seccion": s, "siglas": g, "votos": n} for (s, g), n in tot.items()]


# --- 1983: ARGOS, una página por municipio ---------------------------------------

def _num(texto: str) -> int:
    texto = texto.replace(".", "").strip()
    return int(texto) if texto else 0


def _celdas(fila_html: str) -> list[str]:
    celdas = re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", fila_html, re.S | re.I)
    return [re.sub(r"\s+", " ", re.sub(r"<[^>]+>|&nbsp;", " ", c)).strip() for c in celdas]


def _pagina_argos(mun: int, anio: int) -> list[dict]:
    """Filas (una por candidatura) de la página de ARGOS; [] si no hay datos."""
    r = requests.get(ARGOS.format(mun=mun, anio=anio), headers=CABECERAS, timeout=120)
    r.raise_for_status()
    html = r.content.decode("latin-1")
    generales: dict[str, int] = {}
    cand: list[tuple[str, int]] = []
    for fila in re.findall(r"<tr[^>]*>(.*?)</tr>", html, re.S | re.I):
        c = _celdas(fila)
        for i in range(len(c) - 1):
            if c[i] in ("Censo", "Votantes", "Válidos", "A candidatura", "Blancos"):
                generales[c[i]] = _num(c[i + 1])
        if len(c) == 4 and re.fullmatch(r"[\d.]+", c[2]) and c[1] != "Siglas":
            cand.append((c[1], _num(c[2])))
    if not generales.get("Censo"):
        return []
    base = {"cod_mun": f"{mun:05d}", "censo": generales["Censo"],
            "votantes": generales.get("Votantes", 0), "validos": generales.get("Válidos", 0),
            "candidaturas": generales.get("A candidatura", 0),
            "blancos": generales.get("Blancos", 0)}
    return [{**base, "siglas": s, "votos": v} for s, v in cand]


def _argos(proceso: str) -> list[dict]:
    """Filas por municipio y candidatura de 1983 (rastreadas una vez y en caché)."""
    ruta = cache(SLUG) / f"{proceso}.csv"
    if not ruta.exists():
        anio = int(proceso[3:7])
        # Todos los códigos de municipio que conoce la fuente (los actuales y los de 1987).
        codigos = sorted({f["cmun"] for p in ("A10198706", "A10202305") for f in _filas(p)
                          if f["cmun"] % 1000 < 990})
        with ThreadPoolExecutor(max_workers=4) as ex:
            paginas = list(ex.map(lambda m: _pagina_argos(m, anio), codigos))
        filas = [f for p in paginas for f in p]
        campos = ["cod_mun", "censo", "votantes", "validos", "candidaturas", "blancos",
                  "siglas", "votos"]
        texto = io.StringIO()
        w = csv.DictWriter(texto, fieldnames=campos, lineterminator="\n")
        w.writeheader()
        w.writerows(filas)
        ruta.write_text(texto.getvalue(), encoding="utf-8")
    with open(ruta, encoding="utf-8") as f:
        return [{**r, **{k: int(r[k]) for k in ("censo", "votantes", "validos",
                                                    "candidaturas", "blancos", "votos")}}
                for r in csv.DictReader(f)]


def municipios(proceso: str) -> Iterable[dict]:
    if proceso not in SOLO_MUNICIPIO:
        return []
    tot: dict[str, dict] = {}
    for f in _argos(proceso):
        tot[f["cod_mun"]] = {"cod_mun": f["cod_mun"], "censo": f["censo"],
                             "votos_blanco": f["blancos"],
                             "votos_nulos": f["votantes"] - f["validos"],
                             "votos_candidaturas": f["candidaturas"]}
    return list(tot.values())


def votos_municipios(proceso: str) -> Iterable[dict]:
    if proceso not in SOLO_MUNICIPIO:
        return []
    return [{"cod_mun": f["cod_mun"], "siglas": f["siglas"], "votos": f["votos"]}
            for f in _argos(proceso)]


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
