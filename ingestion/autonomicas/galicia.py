"""Elecciones al Parlamento de Galicia por sección censal y por municipio (Xunta, Abertos).

El Ministerio del Interior no publica las autonómicas gallegas; la Xunta difunde los
resultados definitivos en su portal de datos abiertos, con un conjunto de datos por
elección (Consellería de Presidencia, Xustiza e Deportes, licencia CC BY-SA 4.0):

    https://abertos.xunta.gal/catalogo/administracion-publica/-/dataset/<id>/eleccions-parlamento-galicia-resultados-<año>

    año   id     ficheros (recurso: .../<recurso>/descarga-directa-ficheiro.csv)
    2001  0263   001 municipios (toda Galicia)                 -> solo por MUNICIPIO
    2005  0261   001 municipios · 003 mesas (toda Galicia)
    2009  0260   001 municipios · 003 mesas
    2012  0048   001 municipios · 003 mesas
    2016  0371   001 municipios · 003 mesas
    2020  0426   por provincia: 001/005/009/013 concellos, 003/007/011/015 mesas
    2024  0656   por provincia: 001/005/009/013 concellos, 003/007/011/015 mesas
    (los pares 002/004/... son las mismas tablas en XLS/XLSX; el recurso redirige a
    ficheiros-web.xunta.gal/abertos/eleccions_parlamento/<año>/...)

De 2005 en adelante se usan los ficheros por mesa, sumados a sección (el municipio sale
del código de sección); de 2001 solo hay fichero por municipio. Las autonómicas de
1981, 1985, 1989, 1993 y 1997 NO están en Abertos (el buscador del portal solo da
2001-2024), ni en el IGE, ni en el Ministerio del Interior; la biblioteca del
Parlamento solo tiene los totales por provincia (y su web responde 403 a descargas
automáticas). Por eso no figuran en PROCESOS.

Formato y trampas (cambian de un año a otro)
--------------------------------------------
- CSV separado por «;». 2001-2016 y 2024 en cp1252; 2020 en cp850 (la «ó» de «Cód.»
  es el byte 0xA2): se detecta por la cabecera.
- Cabeceras distintas cada año («CÓD. PROVINCIA» / «Cód Cir», «VOTOS EN BRANCO» /
  «Votos brancos», «TOTAL VOTOS» / «VOTOS TOTAIS»...), en 2001 y 2012 rellenas de
  espacios y en 2001 con «CÓD. MUNICIPIO» repetido: se normalizan (mayúsculas, sin
  tildes ni puntos) y se leen por nombre. Las columnas que no son fijas son las
  candidaturas; las que no se presentan en una provincia vienen vacías (= 0).
- Nombres de candidatura: 2001-2016 «SIGLAS (NOMBRE COMPLETO)» -> se quedan las siglas
  (lo de antes del último paréntesis; «AGE (EU-ANOVA)(ALTERNATIVA GALEGA DE ESQUERDA
  (...))» -> «AGE (EU-ANOVA)»); 2020-2024 ya son siglas. El BNG sale como «B.N.G.» en
  unas provincias y «BNG» en otras en 2020: se deja tal cual (lo resuelve dbt).
- Números: 2012 y 2020 usan punto de miles en filas grandes («137.901»); el CERA de
  Pontevedra en 2001 trae decimales («77866,00»).
- Mesa: 2005-2016 en columnas DISTRITO / SECCIÓN / MESA; 2020 «1-001 -A» y 2024
  «01-001-A» en una sola columna. CUSEC = provincia + municipio + DD + SSS.
- Votos a candidaturas = suma de las columnas de candidatura (2020 no trae el total, y
  en 2001 la columna «VOTOS A CANDIDATURAS» descuadra en 22 concellos). El censo de
  escrutinio es «Censo Total» en 2020-2024 y «CENSO» antes (en 2001 el fichero suma
  2.567.656 electores frente a 2.567.308 del DOG; los votos sí cuadran).
- CERA / residentes ausentes: municipio ficticio 990 (999 en 2005), uno por provincia;
  se descarta (también del fichero de 2001). Ojo: no filtrar «990» en cualquier columna
  (en 2024 una mesa de Santiago tiene censo 990).
- Filas «Total»/«TOTAL» al final y filas vacías (2016 trae ~1.700): se descartan.
- Municipio: «Cód Con»/«CÓD. MUNICIPIO» es el código INE de 3 dígitos del momento
  (2001-2012: 315 concellos, con Cesuras, Oza dos Ríos, Cerdedo y Cotobade aún
  separados; desde 2016/2020 los fusionados 15901, 15902, 36902...).
- Totales con CERA = escrutinio de la Xunta Electoral de Galicia publicado en el DOG.
  Votos a candidaturas con CERA (fichero = oficial): 2001 1.507.937 (DOG 13/11/2001);
  2005 1.651.644 (DOG 134, 13/7/2005; blancos 20.912, nulos 7.646); 2009 1.662.904
  (DOG 60, 27/3/2009; blancos 28.071, nulos 15.223); 2012 1.405.400 (blancos 38.448,
  nulos 37.531); 2016 1.420.381 (DOG 11/10/2016); 2020 1.297.175 (DOG 151, 29/7/2020;
  blancos 11.774, nulos 12.006); 2024 1.488.705 (DOG 47 y 49, 2024).
  El CERA pesa mucho antes del voto rogado (2011): en 2005 fueron 105.510 votos a
  candidaturas (6,4 % del total) de 305.017 electores; desde 2012 la participación
  exterior cae a un 2-5 % y su peso en los votos a menos del 1,5 %.
"""

import csv
import io
import time
import unicodedata
from datetime import date

import requests

from ingestion.autonomicas import cache

SLUG = "galicia"
COD_CCAA = "12"
ABERTOS = ("https://abertos.xunta.gal/catalogo/administracion-publica/-/dataset/"
           "{id}/eleccions-parlamento-galicia-resultados-{anio}")
FUENTE = ABERTOS.format(id="0656", anio=2024)
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

PROCESOS = [
    {"proceso": "A12200110", "fecha": date(2001, 10, 21),
     "eleccion": "Parlamento de Galicia, octubre de 2001"},
    {"proceso": "A12200506", "fecha": date(2005, 6, 19),
     "eleccion": "Parlamento de Galicia, junio de 2005"},
    {"proceso": "A12200903", "fecha": date(2009, 3, 1),
     "eleccion": "Parlamento de Galicia, marzo de 2009"},
    {"proceso": "A12201210", "fecha": date(2012, 10, 21),
     "eleccion": "Parlamento de Galicia, octubre de 2012"},
    {"proceso": "A12201609", "fecha": date(2016, 9, 25),
     "eleccion": "Parlamento de Galicia, septiembre de 2016"},
    {"proceso": "A12202007", "fecha": date(2020, 7, 12),
     "eleccion": "Parlamento de Galicia, julio de 2020"},
    {"proceso": "A12202402", "fecha": date(2024, 2, 18),
     "eleccion": "Parlamento de Galicia, febrero de 2024"},
]

# Por proceso: conjunto de Abertos, nivel y ficheros {etiqueta de caché: recurso}.
_TODA = "gal"
FICHEROS = {
    "A12200110": {"id": "0263", "anio": 2001, "nivel": "municipio",
                  "recursos": {f"{_TODA}_municipios": "001"}},
    "A12200506": {"id": "0261", "anio": 2005, "nivel": "mesa",
                  "recursos": {f"{_TODA}_mesas": "003"}},
    "A12200903": {"id": "0260", "anio": 2009, "nivel": "mesa",
                  "recursos": {f"{_TODA}_mesas": "003"}},
    "A12201210": {"id": "0048", "anio": 2012, "nivel": "mesa",
                  "recursos": {f"{_TODA}_mesas": "003"}},
    "A12201609": {"id": "0371", "anio": 2016, "nivel": "mesa",
                  "recursos": {f"{_TODA}_mesas": "003"}},
    "A12202007": {"id": "0426", "anio": 2020, "nivel": "mesa",
                  "recursos": {"15_mesas": "003", "27_mesas": "007",
                               "32_mesas": "011", "36_mesas": "015"}},
    "A12202402": {"id": "0656", "anio": 2024, "nivel": "mesa",
                  "recursos": {"15_mesas": "003", "27_mesas": "007",
                               "32_mesas": "011", "36_mesas": "015"}},
}

# Cabeceras normalizadas -> campo interno. Lo que no está aquí es una candidatura.
FIJAS = {
    "COD PROVINCIA": "prov", "COD CIR": "prov",
    "COD MUNICIPIO": "mun", "COD CON": "mun",
    "PROVINCIA": None, "MUNICIPIO": None, "CONCELLO": None,
    "DISTRITO": "dist", "SECCION": "secc", "MESA": "mesa",
    "CENSO": "censo", "CENSO TOTAL": "censo_total",
    "CERTIF ALTA": None, "CERTIF CORREC": None,
    "TOTAL VOTOS": None, "VOTOS TOTAIS": None, "VOTOS ELECTORES": None,
    "VOTOS INTERVENTORES": None, "TOTAL ABSTENCION": None, "ABSTENCION": None,
    "VOTOS EN BRANCO": "blanco", "VOTOS BRANCOS": "blanco",
    "VOTOS NULOS": "nulos",
    "VOTOS A CANDIDATURAS": "cand", "VOTOS CANDIDATURAS": "cand",
    "VOTOS VALIDOS": None,
}
MUN_CERA = {"990", "999"}


def _norm(s: str) -> str:
    s = unicodedata.normalize("NFKD", s.strip().upper())
    s = "".join(c for c in s if not unicodedata.combining(c)).replace(".", " ")
    return " ".join(s.split())


def _siglas(cab: str) -> str:
    """«PP (PARTIDO POPULAR)» -> «PP»; sin paréntesis final, el nombre tal cual."""
    cab = " ".join(cab.split())
    if cab.endswith(")"):
        nivel = 0
        for i in range(len(cab) - 1, -1, -1):
            nivel += {")": 1, "(": -1}.get(cab[i], 0)
            if nivel == 0:
                previo = cab[:i].strip()
                return previo or cab
    return cab


def _num(s: str) -> int:
    s = (s or "").strip().replace(".", "")
    if not s:
        return 0
    return int(s.split(",")[0])


def _descargar(proceso: str, etiqueta: str) -> str:
    conf = FICHEROS[proceso]
    ruta = cache(SLUG) / f"{proceso}_{etiqueta}.csv"
    if not ruta.exists():
        url = (ABERTOS.format(id=conf["id"], anio=conf["anio"])
               + f"/{conf['recursos'][etiqueta]}/descarga-directa-ficheiro.csv")
        for intento in range(3):
            try:
                r = requests.get(url, headers=CABECERAS, timeout=120)
                r.raise_for_status()
                break
            except requests.RequestException:
                if intento == 2:
                    raise
                time.sleep(5)
        if not r.content[:1] == b"C" or b";" not in r.content[:200]:
            raise ValueError(f"{url} no parece el CSV de resultados esperado")
        ruta.write_bytes(r.content)
    datos = ruta.read_bytes()
    return datos.decode("cp850" if datos.startswith(b"C\xa2d") else "cp1252")


def _filas(proceso: str):
    """(campos fijos, {siglas: votos}) por fila de mesa o municipio, sin CERA ni totales."""
    for etiqueta in FICHEROS[proceso]["recursos"]:
        lector = csv.reader(io.StringIO(_descargar(proceso, etiqueta)), delimiter=";")
        cab = next(lector)
        campos: list[tuple[int, str]] = []
        partidos: list[tuple[int, str]] = []
        vistos = set()
        for i, c in enumerate(cab):
            n = _norm(c)
            if not n:
                continue
            if n in FIJAS:
                if FIJAS[n] and FIJAS[n] not in vistos:  # 2001 repite «CÓD. MUNICIPIO»
                    campos.append((i, FIJAS[n]))
                    vistos.add(FIJAS[n])
            else:
                partidos.append((i, _siglas(c)))
        if len({s for _, s in partidos}) != len(partidos):
            raise ValueError(f"Siglas repetidas en {proceso}/{etiqueta}: {partidos}")
        if not {"prov", "mun", "censo", "blanco", "nulos"} <= vistos:
            raise ValueError(f"Cabecera inesperada en {proceso}/{etiqueta}: {cab[:15]}")
        for fila in lector:
            if not fila or not fila[0].strip().isdigit():
                continue  # filas vacías y «Total»
            fila = fila + [""] * (len(cab) - len(fila))
            d = {k: fila[i].strip() for i, k in campos}
            if d["mun"].zfill(3) in MUN_CERA:
                continue
            votos = {s: _num(fila[i]) for i, s in partidos}
            yield d, votos


def _cusec(d: dict) -> str:
    prov, mun = d["prov"].zfill(2), d["mun"].zfill(3)
    if "dist" in d:
        dist, secc = d["dist"], d["secc"]
    else:  # «01-001-A» (2024) o «1-001 -A» (2020)
        dist, secc, _letra = (x.strip() for x in d["mesa"].split("-"))
    return prov + mun + dist.zfill(2) + secc.zfill(3)


def _base(d: dict, votos: dict) -> dict:
    return {"censo": _num(d.get("censo_total") or d["censo"]),
            "votos_blanco": _num(d["blanco"]), "votos_nulos": _num(d["nulos"]),
            # Suma de las columnas de candidatura: en 2020 no hay columna de total y en
            # 2001 la de «VOTOS A CANDIDATURAS» descuadra en 22 concellos (-167 votos);
            # la suma por partidos es la que da el total oficial del DOG (1.507.937).
            "votos_candidaturas": sum(votos.values())}


def _sumar(acc: dict, clave: str, campo: str, d: dict, votos: dict) -> None:
    s = acc.setdefault(clave, {campo: clave, "censo": 0, "votos_blanco": 0,
                               "votos_nulos": 0, "votos_candidaturas": 0})
    for k, v in _base(d, votos).items():
        s[k] += v


def secciones(proceso: str):
    if FICHEROS[proceso]["nivel"] != "mesa":
        return []
    acc: dict[str, dict] = {}
    for d, votos in _filas(proceso):
        _sumar(acc, _cusec(d), "cod_seccion", d, votos)
    return list(acc.values())


def votos(proceso: str):
    if FICHEROS[proceso]["nivel"] != "mesa":
        return []
    acc: dict[tuple[str, str], int] = {}
    for d, vs in _filas(proceso):
        cusec = _cusec(d)
        for siglas, n in vs.items():
            if n:
                acc[(cusec, siglas)] = acc.get((cusec, siglas), 0) + n
    return [{"cod_seccion": c, "siglas": s, "votos": n} for (c, s), n in acc.items()]


def municipios(proceso: str):
    """Solo para los procesos sin mesas (2001); el resto sale de las secciones."""
    if FICHEROS[proceso]["nivel"] != "municipio":
        return []
    acc: dict[str, dict] = {}
    for d, vs in _filas(proceso):
        _sumar(acc, d["prov"].zfill(2) + d["mun"].zfill(3), "cod_mun", d, vs)
    return list(acc.values())


def votos_municipios(proceso: str):
    if FICHEROS[proceso]["nivel"] != "municipio":
        return []
    acc: dict[tuple[str, str], int] = {}
    for d, vs in _filas(proceso):
        mun = d["prov"].zfill(2) + d["mun"].zfill(3)
        for siglas, n in vs.items():
            if n:
                acc[(mun, siglas)] = acc.get((mun, siglas), 0) + n
    return [{"cod_mun": m, "siglas": s, "votos": n} for (m, s), n in acc.items()]


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
