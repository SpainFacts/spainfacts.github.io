"""Elecciones a las Cortes de Castilla-La Mancha: todas desde 1983.

Fuentes (todas de la Junta de Comunidades de Castilla-La Mancha)
----------------------------------------------------------------
- 1983-2015, por municipio: portal de datos abiertos de la Junta, catálogo «Resultados
  de elecciones autonómicas en Castilla-La Mancha. Histórico» (datos.gob.es,
  a08002880-resultandos-de-elecciones-autonomicas-en-castilla-la-mancha; licencia
  CC BY-SA 3.0 ES). Un CSV por elección (los mismos datos que los .xls de
  elecciones.castillalamancha.es/resultados/descargar-los-resultados-de-las-
  elecciones-autonomicas-anteriores-por-municipio). No hay nada por mesa ni sección.
- 2019, por mesa: elecciones2019.castillalamancha.es, «Descargar los resultados de las
  elecciones desglosado por mesas» (resultados2019.xlsx, 4,8 MB). Es el escrutinio
  DEFINITIVO: cuadra al voto con el acta de la Junta Electoral (DOCM).
- 2023, por mesa: elecciones2023.castillalamancha.es, PDF de 87 páginas del escrutinio
  PROVISIONAL (ResultadosprovisionalesCLMbis.pdf). Por municipio, el CSV DEFINITIVO de
  datos abiertos (Resultados_CLM_2023.csv), que además da el código INE de cada nombre.

Formato y trampas
-----------------
1983-2015 (CSV por municipio, cp1252, «;»):
- Columnas «Año;Provincia;Código INE;Municipio;Partido;Votos», una fila por municipio
  y «partido». El código es prov + mun + «0000» como número (20010000 = 02001).
- «Partido» trae CENSO, ABSTEN, 4-6 partidos principales y OTROS (la suma del resto de
  candidaturas). OTROS se publica tal cual con las siglas «OTROS».
- NO separa blancos ni nulos: CENSO - ABSTEN (votantes) - candidaturas = blancos +
  nulos juntos. Por eso votos_blanco y votos_nulos van a None (no se inventa el
  reparto); los votos a candidaturas sí cuadran con el oficial.
- Las siglas son las de la Junta, no las de la papeleta: en 1983 «PP» es la coalición
  AP-PDP-UL e «IU» es el PCE; en 1987 «PP» es AP. En 2015 hay una fila «C’s» (con
  apóstrofo tipográfico) que se une a «C's».
- Los códigos son los actuales, aplicados hacia atrás: 1983 ya trae 16901 Campos del
  Paraíso o 13901 Robledo (El). Se dejan tal cual. No hay CERA en estos ficheros.
- Los totales salen algo por debajo del oficial porque el oficial incluye el CERA
  (1983 no tenía CERA aparte: ahí la diferencia es solo de 622 votos).
2019 (xlsx por mesa):
- La hoja buena es «BBDD» (las «BBDD1»...«BBDD9» son mesas de Castilla y León que se
  quedaron en el libro). Cabecera en la 2.ª fila; «Código de mesa» = PP-MMM-DD-SSS-M.
- El municipio 999 de cada provincia es el CERA («Residentes Ausentes»): se excluye.
  Los 9xx restantes (02901 Pozo Cañada...) son municipios reales.
- Las candidaturas que no se presentan en una provincia vienen vacías (None).
2023 (PDF por mesa, provisional):
- Una tabla por provincia (ALBACETE, CIUDAD REAL...). Cada fila es una mesa: «Municipio
  D-SSS-M  censo  cert.alta  [cert.correc.]  censo total  votantes  nulos  blancos
  votos de cada candidatura». No trae código de municipio, solo el nombre.
- Toledo NO tiene la columna de certificaciones de corrección y cada provincia tiene
  sus candidaturas en su propio orden (ver PROVINCIAS). Se comprueba que cada fila
  tiene exactamente el número de cifras esperado.
- pdftotext descoloca las filas; pdfplumber (palabras con su coordenada y) las lee
  bien agrupando por altura. En Toledo los nombres largos se parten en dos renglones
  («Villafranca de los» / «Caballeros»): se antepone el renglón sin mesa de encima.
- 32 mesas «MESA SIN GRABAR» sin datos (Albacete 1-006-A, Fuenllana 1-001-U...).
- En el CSV 2023 la candidatura «+CU-EV» de Cuenca sale como «#¿NOMBRE?» (Excel la
  tomó por fórmula): se corrige. El CERA es el municipio 990.
- El CSV 2023 solo trae votos por candidatura: el censo, los blancos y los nulos de
  municipios() salen del PDF provisional y quedan a None en los municipios con alguna
  mesa sin grabar (22 municipios, entre ellos Albacete, Talavera y Fuenllana).

Búsqueda del escrutinio DEFINITIVO por mesa de 2023 (repetida el 13-10-2026, sin éxito):
- elecciones2023.castillalamancha.es/resultados/resultados-def es una vista de Drupal que
  solo filtra por provincia; el menú «desglosado por mesas» sigue llevando al PDF provisional.
- «Resultados electorales 2023.pdf» del mismo sitio es el acuerdo de la Junta Electoral en
  el DOCM (16-6-2023): solo comunidad y circunscripciones.
- datos.gob.es / datosabiertos.castillalamancha.es: Resultados_CLM_2023.xlsx es la misma
  tabla por municipio que el CSV (una hoja, Municipios_Resultados); no hay nada por mesa.
- La Wayback Machine no guardó ningún xls/csv en elecciones2023.castillalamancha.es/sites/;
  la app de la Junta solo daba el provisional. Ningún ayuntamiento afectado (Albacete,
  Talavera...) publica las autonómicas por mesa.
- Mesas sin grabar en 22 municipios: 02003 02009 02030 02037 02081 02901 13013 13042 13043
  13053 13071 13093 45028 45038 45046 45069 45081 45121 45125 45165 45180 45205. No se
  imputan (restar al municipal definitivo mezclaría provisional y definitivo).

Resultado oficial (actas de la Junta Electoral de Castilla-La Mancha; DOCM/BOE; para
1983-2007 los PDF escaneados de la JEC no tienen texto y las cifras son las de esas
actas recogidas en Wikipedia): ver OFICIAL más abajo.
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
FUENTE = "https://elecciones.castillalamancha.es/resultados/anteriores"
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

# La Junta solo publica por mesa el escrutinio provisional de 2023 (faltan 32 mesas)
COBERTURA = "2023 por sección: escrutinio provisional, faltan 32 mesas sin grabar (1,2 % de los votos)"

_MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
          "septiembre", "octubre", "noviembre", "diciembre"]
_FECHAS = [date(1983, 5, 8), date(1987, 6, 10), date(1991, 5, 26), date(1995, 5, 28),
           date(1999, 6, 13), date(2003, 5, 25), date(2007, 5, 27), date(2011, 5, 22),
           date(2015, 5, 24), date(2019, 5, 26), date(2023, 5, 28)]
PROCESOS = [
    {"proceso": f"A{COD_CCAA}{f.year}{f.month:02d}", "fecha": f,
     "eleccion": f"Cortes de Castilla-La Mancha, {_MESES[f.month - 1]} de {f.year}"}
    for f in _FECHAS
]

_DA = "https://datosabiertos.castillalamancha.es/sites/datosabiertos.castillalamancha.es/files/"
URLS = {
    "A08198305": {"municipios": _DA + "1983.csv"},
    "A08198706": {"municipios": _DA + "Resultados%20electorales%201987.csv"},
    "A08199105": {"municipios": _DA + "Resultados%20electorales%201991.csv"},
    "A08199505": {"municipios": _DA + "Resultados%20electorales%201995.csv"},
    "A08199906": {"municipios": _DA + "1999.csv"},
    "A08200305": {"municipios": _DA + "2003.csv"},
    "A08200705": {"municipios": _DA + "2007.csv"},
    "A08201105": {"municipios": _DA + "2011.csv"},
    "A08201505": {"municipios": _DA + "elecciones%202015.csv"},
    "A08201905": {
        "mesas": ("https://elecciones2019.castillalamancha.es/sites/elecciones2019.castillalamancha.es/"
                  "files/documentos/paginas/archivos/resultados2019.xlsx"),
    },
    "A08202305": {
        "mesas": ("https://elecciones2023.castillalamancha.es/sites/default/files/2023-06/"
                  "ResultadosprovisionalesCLMbis.pdf"),
        "municipios": _DA + "Resultados_CLM_2023.csv",
    },
}

# Resultado oficial de toda la comunidad (CON el CERA): votos a candidaturas, blancos,
# nulos y los dos primeros partidos (con las siglas que usa este módulo).
OFICIAL = {
    "A08198305": (885365, 5823, 10684, {"PSOE": 416177, "PP": 364676}),
    "A08198706": (929962, 9247, 11053, {"PSOE": 435121, "PP": 319978}),
    "A08199105": (929674, 9300, 7164, {"PSOE": 489876, "PP": 336642}),
    "A08199505": (1047746, 11128, 7697, {"PSOE": 483888, "PP": 469127}),
    "A08199906": (1035935, 14929, 7146, {"PSOE": 561332, "PP": 424531}),
    "A08200305": (1082030, 14554, 7534, {"PSOE": 634132, "PP": 402047}),
    "A08200705": (1088483, 14080, 8322, {"PSOE": 572849, "PP": 467319}),
    "A08201105": (1154773, 19643, 15570, {"PP": 564954, "PSOE": 509738}),
    "A08201505": (1083272, 19256, 24609, {"PP": 413349, "PSOE": 398104}),
    "A08201905": (1071640, 8754, 11506, {"PSOE": 476469, "PP": 308184}),
    "A08202305": (1072883, 15570, 19054, {"PSOE": 490288, "PP": 366312}),
}

# 2023 (PDF). Por provincia: código INE, nº de columnas fijas tras la mesa (censo ...
# blancos) y candidaturas en el orden de las columnas del PDF.
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
MESA_2019 = re.compile(r"^(\d{2})-(\d{3})-(\d{2})-(\d{3})-([A-Z])$")
NUMERO = re.compile(r"^\d{1,3}(\.\d{3})*$|^\d+$")
SIGLAS = {"C’s": "C's", "#¿NOMBRE?": "+CU-EV"}


def _norm(texto: str) -> str:
    t = unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", " ", t).strip()


def _int(texto) -> int:
    if texto is None or texto == "":
        return 0
    if isinstance(texto, (int, float)):
        return int(texto)
    return int(str(texto).strip().replace(".", ""))


def _bajar(url: str, nombre: str, inicio: bytes) -> bytes:
    destino = cache(SLUG) / nombre
    if not destino.exists():
        r = requests.get(url, headers=CABECERAS, timeout=300)
        r.raise_for_status()
        if not r.content.startswith(inicio):
            raise ValueError(f"Respuesta inesperada al bajar {url}")
        destino.write_bytes(r.content)
    return destino.read_bytes()


# --------------------------------------------------------------------------- 1983-2015

@lru_cache(maxsize=None)
def _historico(proceso: str) -> dict[str, dict[str, int]]:
    """cod_mun -> {CENSO, ABSTEN, siglas...: votos} del CSV por municipio de 1983-2015."""
    raw = _bajar(URLS[proceso]["municipios"], f"{proceso}_municipios.csv", "Año;".encode("cp1252"))
    filas = csv.DictReader(io.StringIO(raw.decode("cp1252")), delimiter=";")
    anio = proceso[3:7]
    out: dict[str, dict[str, int]] = {}
    for f in filas:
        if f["Año"].strip() != anio:
            raise ValueError(f"Fila de otro año en {proceso}: {f}")
        codigo = f["Código INE"].strip()
        if not codigo.endswith("0000"):
            raise ValueError(f"Código INE inesperado en {proceso}: {codigo}")
        cod_mun = codigo[:-4].zfill(5)
        partido = SIGLAS.get(f["Partido"].strip(), f["Partido"].strip())
        d = out.setdefault(cod_mun, {})
        if partido in d and partido in ("CENSO", "ABSTEN"):
            raise ValueError(f"{partido} repetido en {proceso} {cod_mun}")
        d[partido] = d.get(partido, 0) + _int(f["Votos"])
    return out


# --------------------------------------------------------------------------- 2019

@lru_cache(maxsize=None)
def _mesas_2019(proceso: str) -> tuple[dict, ...]:
    import warnings

    import openpyxl

    raw = _bajar(URLS[proceso]["mesas"], f"{proceso}_mesas.xlsx", b"PK")
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")            # «Slicer List extension is not supported»
        libro = openpyxl.load_workbook(io.BytesIO(raw), read_only=True, data_only=True)
    hoja = libro["BBDD"]
    cab, filas, vistas = None, [], set()
    for r in hoja.iter_rows(values_only=True):
        if r and r[0] == "Código de mesa":
            cab = [c for c in r if c]
            continue
        if not r or not isinstance(r[0], str) or not MESA_2019.match(r[0]):
            continue
        if cab is None:
            raise ValueError("Fila de mesa antes de la cabecera en la hoja BBDD")
        d = dict(zip(cab, r))
        prov, mun, dist, secc, _ = MESA_2019.match(d["Código de mesa"]).groups()
        if mun == "999":                           # residentes ausentes (CERA)
            continue
        if d["Código de mesa"] in vistas:
            raise ValueError(f"Mesa repetida: {d['Código de mesa']}")
        vistas.add(d["Código de mesa"])
        partidos = cab[cab.index("Votos Blanco") + 1:]
        filas.append({
            "cod_seccion": prov + mun + dist + secc,
            "censo": _int(d["Censo total"]),
            "votos_nulos": _int(d["Votos Nulos"]),
            "votos_blanco": _int(d["Votos Blanco"]),
            "votos": {p: _int(d[p]) for p in partidos},
        })
    libro.close()
    return tuple(filas)


# --------------------------------------------------------------------------- 2023

@lru_cache(maxsize=None)
def _csv_2023(proceso: str) -> tuple[dict, ...]:
    """Filas del CSV definitivo por municipio (sin CERA): prov, mun, nombre, siglas, votos."""
    raw = _bajar(URLS[proceso]["municipios"], f"{proceso}_municipios.csv", b"ELECCIONES")
    lineas = raw.decode("cp1252").splitlines()
    inicio = next(i for i, l in enumerate(lineas) if l.startswith("Año;Provincia;"))
    filas = []
    for f in csv.DictReader(io.StringIO("\n".join(lineas[inicio:])), delimiter=";"):
        prov, mun = f["Provincia"].strip().zfill(2), f["Municipio"].strip().zfill(3)
        if mun == "990":                  # residentes ausentes (CERA)
            continue
        siglas = f["Siglas"].strip()
        filas.append({"cod_mun": prov + mun, "nombre": f["Nombre"],
                      "siglas": SIGLAS.get(siglas, siglas), "votos": _int(f["Votos"])})
    return tuple(filas)


def _codigos_municipio(proceso: str) -> dict[tuple[str, str], str]:
    """(provincia INE, nombre normalizado) -> código INE de municipio (5 dígitos)."""
    return {(f["cod_mun"][:2], _norm(f["nombre"])): f["cod_mun"] for f in _csv_2023(proceso)}


@lru_cache(maxsize=None)
def _pdf_2023(proceso: str) -> tuple[tuple[dict, ...], frozenset[str]]:
    """Mesas leídas del PDF (con su CUSEC) y municipios con alguna mesa sin grabar."""
    import pdfplumber

    pdf = _bajar(URLS[proceso]["mesas"], f"{proceso}_mesas.pdf", b"%PDF")
    codigos = _codigos_municipio(proceso)
    filas, sin_grabar, provincia, prefijo = [], set(), None, ""
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
                if provincia is None:
                    raise ValueError(f"Fila antes de la cabecera de provincia: {linea}")
                prov, n_fijas, siglas = PROVINCIAS[provincia]
                nombre = " ".join(textos[:pos])
                cod_mun = codigos.get((prov, _norm(nombre)))
                if cod_mun is None and prefijo:
                    nombre = f"{prefijo} {nombre}"
                    cod_mun = codigos.get((prov, _norm(nombre)))
                prefijo = ""
                if cod_mun is None:
                    raise ValueError(f"Municipio sin código INE: {prov} {nombre}")
                if "GRABAR" in linea:                    # «MESA SIN GRABAR»
                    sin_grabar.add(cod_mun)
                    continue
                cifras = textos[pos + 1:]
                if len(cifras) != n_fijas + len(siglas) or not all(NUMERO.match(c) for c in cifras):
                    raise ValueError(f"Fila con columnas inesperadas ({provincia}): {linea}")
                cifras = [int(c.replace(".", "")) for c in cifras]
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
    return tuple(filas), frozenset(sin_grabar)


# --------------------------------------------------------------------------- interfaz

def _mesas(proceso: str) -> tuple[dict, ...]:
    if proceso == "A08201905":
        return _mesas_2019(proceso)
    if proceso == "A08202305":
        return _pdf_2023(proceso)[0]
    return ()


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


def municipios(proceso: str):
    """Por municipio: 1983-2015 (única fuente) y 2023 (CSV definitivo). 2019 va por sección.

    1983-2015 no separan blancos ni nulos: van a None. En 2023 el censo, los blancos y los
    nulos son los del PDF provisional y van a None si el municipio tiene mesas sin grabar.
    """
    if proceso == "A08202305":
        cand: dict[str, int] = {}
        for f in _csv_2023(proceso):
            cand[f["cod_mun"]] = cand.get(f["cod_mun"], 0) + f["votos"]
        mesas, sin_grabar = _pdf_2023(proceso)
        prov: dict[str, dict] = {}
        for m in mesas:
            a = prov.setdefault(m["cod_seccion"][:5], {"censo": 0, "votos_blanco": 0, "votos_nulos": 0})
            for k in a:
                a[k] += m[k]
        vacio = {"censo": None, "votos_blanco": None, "votos_nulos": None}
        return [{"cod_mun": c, **(vacio if c in sin_grabar or c not in prov else prov[c]),
                 "votos_candidaturas": n} for c, n in cand.items()]
    if "municipios" not in URLS.get(proceso, {}):
        return []
    return [{"cod_mun": c, "censo": d.get("CENSO"), "votos_blanco": None, "votos_nulos": None,
             "votos_candidaturas": sum(v for k, v in d.items() if k not in ("CENSO", "ABSTEN"))}
            for c, d in _historico(proceso).items()]


def votos_municipios(proceso: str):
    if proceso == "A08202305":
        acc: dict[tuple[str, str], int] = {}
        for f in _csv_2023(proceso):
            k = (f["cod_mun"], f["siglas"])
            acc[k] = acc.get(k, 0) + f["votos"]
        return [{"cod_mun": c, "siglas": s, "votos": n} for (c, s), n in acc.items()]
    if "municipios" not in URLS.get(proceso, {}):
        return []
    return [{"cod_mun": c, "siglas": k, "votos": v}
            for c, d in _historico(proceso).items()
            for k, v in d.items() if k not in ("CENSO", "ABSTEN")]


def comprobar() -> None:
    """Cada elección frente al resultado oficial (que incluye el CERA)."""
    from ingestion.autonomicas import codigos_ine

    for p in PROCESOS:
        proc = p["proceso"]
        cand_o, bl_o, nu_o, partidos_o = OFICIAL[proc]
        print(f"== {proc} · {p['eleccion']} · {p['fecha'].isoformat()}")
        for nivel, filas, votos_ in (("municipio", municipios(proc), votos_municipios(proc)),
                                     ("sección", secciones(proc), votos(proc))):
            if not filas:
                continue
            clave = "cod_mun" if nivel == "municipio" else "cod_seccion"
            cand = sum(r["votos_candidaturas"] for r in filas)
            suma = lambda k: (None if any(r[k] is None for r in filas)
                              else sum(r[k] for r in filas))
            por: dict[str, int] = {}
            for r in votos_:
                por[r["siglas"]] = por.get(r["siglas"], 0) + r["votos"]
            assert sum(por.values()) == cand, "votos por candidatura != votos_candidaturas"
            muns = {r[clave][:5] for r in filas}
            linea = (f"  {nivel}: {len(filas):,} filas · {len(muns)} municipios · censo {suma('censo') or '—'}"
                     f" · candidaturas {cand:,} (oficial {cand_o:,}, {cand - cand_o:+,},"
                     f" {100 * (cand - cand_o) / cand_o:+.2f} %)"
                     f" · blancos {suma('votos_blanco') if suma('votos_blanco') is not None else '—'}"
                     f" (of. {bl_o:,}) · nulos {suma('votos_nulos') if suma('votos_nulos') is not None else '—'}"
                     f" (of. {nu_o:,})")
            print(linea)
            print("    " + " · ".join(f"{s} {por.get(s, 0):,} (of. {n:,})" for s, n in partidos_o.items())
                  + " · otras: " + ", ".join(f"{s} {n:,}" for s, n in
                                             sorted(por.items(), key=lambda x: -x[1]) if s not in partidos_o)[:200])
            if nivel == "sección":
                ine = codigos_ine(p["fecha"].year)
                cods = {r["cod_seccion"] for r in filas}
                print(f"    secciones que casan con el INE ({max(2023, min(2026, p['fecha'].year))}): "
                      f"{len(cods & ine)} de {len(cods)} ({100 * len(cods & ine) / len(cods):.1f} %)")


if __name__ == "__main__":
    comprobar()
