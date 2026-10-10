"""Fuente dlt para los resultados electorales oficiales (Ministerio del Interior).

El área de descargas de infoelectoral.interior.gob.es publica, por cada
proceso electoral, un ZIP con ficheros de texto de longitud fija (formato
descrito en el FICHEROS.doc que viene dentro de cada ZIP):

    https://infoelectoral.interior.gob.es/estaticos/docxl/apliextr/{tt}{aaaa}{mm}_MUNI.zip

    tt = tipo de proceso: 02 Congreso, 04 Municipales, 07 Parlamento Europeo.

Del ZIP se leen:
    02xxaamm.DAT  identificación del proceso (fecha de celebración)
    03xxaamm.DAT  candidaturas (siglas, denominación y cabeceras de acumulación)
    05xxaamm.DAT  datos globales por municipio (censo, votantes, blancos, nulos)
    06xxaamm.DAT  votos y electos por candidatura y municipio
    07xxaamm.DAT  datos globales de ámbito superior (provincia, comunidad, España)
    08xxaamm.DAT  votos y escaños por candidatura en ese ámbito superior

De los ficheros de municipio solo se guarda el total municipal (distrito 99),
no el desglose por distritos municipales. En municipales los ficheros 05/06
cubren los municipios de más de 250 habitantes (listas cerradas); los de
concejo abierto o listas abiertas (ficheros 11/12) no se cargan.

Los votos del C.E.R.A. (españoles residentes en el extranjero) no se reparten
por municipio: están en los totales provinciales, autonómicos y nacional (07/08)
pero no en la suma de los municipios.

Los códigos de comunidad autónoma son los del Ministerio del Interior
(01 Andalucía ... 19 Melilla), que NO coinciden con los del INE: en dbt se
obtiene la comunidad a partir de la provincia (código INE).

Resultados por sección censal (mapas de barrio): para los últimos procesos de
cada tipo (PROCESOS_SECCION) se descarga además el ZIP por mesa

    https://infoelectoral.interior.gob.es/estaticos/docxl/apliextr/{tt}{aaaa}{mm}_MESA.zip

y se suman sus mesas por sección (ficheros 09, datos globales, y 10, votos por
candidatura). La sección de Interior tiene 4 caracteres ("001 " o "001A": la
cuarta posición parte una sección en subsecciones); sus tres primeros dígitos,
con provincia, municipio y distrito, forman el código INE de la sección (CUSEC,
10 dígitos), que casa con el seccionado del INE y con la renta del ADRH. Las
filas del C.E.R.A. (municipio 999) no tienen sección y se descartan.

Carga completa ("replace"): ~40 procesos, unos 2,5 millones de filas (más
~1,5 millones de votos por sección), idempotente y sin estado.
"""

import io
import time
import zipfile
from datetime import date

import dlt
import requests

URL = "https://infoelectoral.interior.gob.es/estaticos/docxl/apliextr/{codigo}_MUNI.zip"
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

# (tipo, año, mes) de cada proceso. Congreso: todas las generales desde 1977.
PROCESOS = (
    [("02", a, m) for a, m in [
        (1977, 6), (1979, 3), (1982, 10), (1986, 6), (1989, 10), (1993, 6), (1996, 3),
        (2000, 3), (2004, 3), (2008, 3), (2011, 11), (2015, 12), (2016, 6), (2019, 4),
        (2019, 11), (2023, 7),
    ]]
    + [("04", a, m) for a, m in [
        (1979, 4), (1983, 5), (1987, 6), (1991, 5), (1995, 5), (1999, 6), (2003, 5),
        (2007, 5), (2011, 5), (2015, 5), (2019, 5), (2023, 5),
    ]]
    + [("07", a, m) for a, m in [
        (1987, 6), (1989, 6), (1994, 6), (1999, 6), (2004, 6), (2009, 6), (2014, 5),
        (2019, 5), (2024, 6),
    ]]
)

NECESARIOS = {"02", "03", "05", "06", "07", "08"}

# Procesos con resultados por sección censal: el último de cada tipo. Al añadir
# uno, comprobar que static-extra/geo/secciones tiene el seccionado de su año
# (tools/geo/secciones.py).
URL_MESA = "https://infoelectoral.interior.gob.es/estaticos/docxl/apliextr/{codigo}_MESA.zip"
PROCESOS_SECCION = [("02", 2023, 7), ("04", 2023, 5), ("07", 2024, 6)]

TIPOS = {"02": "Congreso", "04": "Municipales", "07": "Parlamento Europeo"}


def _codigo(tipo: str, anio: int, mes: int) -> str:
    return f"{tipo}{anio}{mes:02d}"


def _descargar(codigo: str) -> dict[str, list[str]]:
    """Devuelve {prefijo de fichero '02'...'08': líneas} del ZIP del proceso."""
    r = requests.get(URL.format(codigo=codigo), headers=CABECERAS, timeout=180)
    r.raise_for_status()
    ficheros = {}
    with zipfile.ZipFile(io.BytesIO(r.content)) as z:
        for nombre in z.namelist():
            base = nombre.rsplit("/", 1)[-1].upper()
            # nnxxaamm.DAT: solo los del propio tipo (en municipales el ZIP trae
            # también los 0510/0610/0710/0810 de partidos judiciales y diputaciones)
            if (base.endswith(".DAT") and len(base) == 12 and base[:2] in NECESARIOS
                    and base[2:4] == codigo[:2]):
                texto = z.read(nombre).decode("cp1252", errors="replace")
                ficheros[base[:2]] = [l for l in texto.splitlines() if l.strip()]
    return ficheros


def _n(linea: str, ini: int, fin: int) -> int | None:
    """Campo numérico en las posiciones ini..fin (1-based, inclusivas)."""
    t = linea[ini - 1:fin].strip()
    return int(t) if t.isdigit() else None


def _s(linea: str, ini: int, fin: int) -> str | None:
    t = linea[ini - 1:fin].strip()
    return t or None


def _procesos():
    """Descarga cada proceso una sola vez y lo reparte entre los recursos."""
    for tipo, anio, mes in PROCESOS:
        codigo = _codigo(tipo, anio, mes)
        yield tipo, anio, mes, codigo, _descargar(codigo)


# Cada proceso se descarga una vez por carga y lo leen los seis recursos. La
# caché caduca a las 2 horas para que una ejecución posterior en el mismo
# proceso (Dagster) vuelva a descargar.
_CACHE: list = []
_CACHE_T = [0.0]


def _datos():
    if not _CACHE or time.time() - _CACHE_T[0] > 7200:
        _CACHE.clear()
        _CACHE.extend(_procesos())
        _CACHE_T[0] = time.time()
    return _CACHE


@dlt.resource(name="elecciones_procesos", write_disposition="replace")
def elecciones_procesos():
    for tipo, anio, mes, codigo, f in _datos():
        l = (f.get("02") or [""])[0]
        dia, mes_c, anio_c = _n(l, 13, 14), _n(l, 15, 16), _n(l, 17, 20)
        yield {
            "proceso": codigo,
            "tipo": tipo,
            "tipo_nombre": TIPOS[tipo],
            "anio": anio,
            "mes": mes,
            "fecha": date(anio_c, mes_c, dia) if dia and mes_c and anio_c else None,
            "ambito": _s(l, 10, 10),
        }


@dlt.resource(name="elecciones_candidaturas", write_disposition="replace")
def elecciones_candidaturas():
    for tipo, anio, mes, codigo, f in _datos():
        yield [
            {
                "proceso": codigo,
                "tipo": tipo,
                "anio": anio,
                "cod_candidatura": _s(l, 9, 14),
                "siglas": _s(l, 15, 64),
                "denominacion": _s(l, 65, 214),
                "cod_acum_provincial": _s(l, 215, 220),
                "cod_acum_autonomico": _s(l, 221, 226),
                "cod_acum_nacional": _s(l, 227, 232),
            }
            for l in f.get("03", [])
        ]


@dlt.resource(name="elecciones_municipios", write_disposition="replace")
def elecciones_municipios():
    for tipo, anio, mes, codigo, f in _datos():
        filas = []
        for l in f.get("05", []):
            if l[16:18] != "99":  # solo el total municipal
                continue
            filas.append({
                "proceso": codigo,
                "tipo": tipo,
                "anio": anio,
                "vuelta": _n(l, 9, 9),
                "cod_ccaa_mir": _s(l, 10, 11),
                "cod_prov": _s(l, 12, 13),
                "cod_mun": l[11:16],
                "municipio": _s(l, 19, 118),
                # 05: población 129-136 ... votos a candidaturas 206-213
                "poblacion": _n(l, 129, 136),
                "mesas": _n(l, 137, 141),
                "censo_ine": _n(l, 142, 149),
                "censo_escrutinio": _n(l, 150, 157),
                "censo_cere": _n(l, 158, 165),
                "votantes_cere": _n(l, 166, 173),
                "votos_blanco": _n(l, 190, 197),
                "votos_nulos": _n(l, 198, 205),
                "votos_candidaturas": _n(l, 206, 213),
                "escanos": _n(l, 214, 216),
                "datos_oficiales": _s(l, 233, 233),
            })
        yield filas


@dlt.resource(name="elecciones_municipios_votos", write_disposition="replace")
def elecciones_municipios_votos():
    for tipo, anio, mes, codigo, f in _datos():
        yield [
            {
                "proceso": codigo,
                "tipo": tipo,
                "anio": anio,
                "vuelta": _n(l, 9, 9),
                "cod_mun": l[9:14],
                "cod_candidatura": _s(l, 17, 22),
                "votos": _n(l, 23, 30),
                "electos": _n(l, 31, 33),
            }
            for l in f.get("06", [])
            if l[14:16] == "99"
        ]


@dlt.resource(name="elecciones_ambitos", write_disposition="replace")
def elecciones_ambitos():
    for tipo, anio, mes, codigo, f in _datos():
        yield [
            {
                "proceso": codigo,
                "tipo": tipo,
                "anio": anio,
                "vuelta": _n(l, 9, 9),
                "cod_ccaa_mir": _s(l, 10, 11),
                "cod_prov": _s(l, 12, 13),
                "distrito": _s(l, 14, 14),
                "nombre": _s(l, 15, 64),
                "poblacion": _n(l, 65, 72),
                "mesas": _n(l, 73, 77),
                "censo_ine": _n(l, 78, 85),
                "censo_escrutinio": _n(l, 86, 93),
                "censo_cere": _n(l, 94, 101),
                "votantes_cere": _n(l, 102, 109),
                "votos_blanco": _n(l, 126, 133),
                "votos_nulos": _n(l, 134, 141),
                "votos_candidaturas": _n(l, 142, 149),
                "escanos": _n(l, 150, 155),
                "datos_oficiales": _s(l, 172, 172),
            }
            for l in f.get("07", [])
        ]


@dlt.resource(name="elecciones_ambitos_votos", write_disposition="replace")
def elecciones_ambitos_votos():
    for tipo, anio, mes, codigo, f in _datos():
        yield [
            {
                "proceso": codigo,
                "tipo": tipo,
                "anio": anio,
                "vuelta": _n(l, 9, 9),
                "cod_ccaa_mir": _s(l, 10, 11),
                "cod_prov": _s(l, 12, 13),
                "distrito": _s(l, 14, 14),
                "cod_candidatura": _s(l, 15, 20),
                "votos": _n(l, 21, 28),
                "escanos": _n(l, 29, 33),
            }
            for l in f.get("08", [])
        ]


def _mesas(codigo: str) -> dict[str, list[str]]:
    """Líneas de los ficheros 09 y 10 del ZIP por mesa del proceso."""
    r = requests.get(URL_MESA.format(codigo=codigo), headers=CABECERAS, timeout=300)
    r.raise_for_status()
    ficheros = {}
    with zipfile.ZipFile(io.BytesIO(r.content)) as z:
        for nombre in z.namelist():
            base = nombre.rsplit("/", 1)[-1].upper()
            if base.endswith(".DAT") and len(base) == 12 and base[:2] in {"09", "10"} and base[2:4] == codigo[:2]:
                texto = z.read(nombre).decode("cp1252", errors="replace")
                ficheros[base[:2]] = [l for l in texto.splitlines() if l.strip()]
    return ficheros


def _cusec(l: str) -> str | None:
    """Código INE de la sección (prov + mun + distrito + 3 dígitos de sección); None en el CERA."""
    if l[13:16] == "999" or not l[18:21].isdigit():
        return None
    return l[11:18] + l[18:21]


_CACHE_MESAS: dict = {}


def _datos_mesas():
    if not _CACHE_MESAS or time.time() - _CACHE_MESAS.get("_t", 0) > 7200:
        _CACHE_MESAS.clear()
        for tipo, anio, mes in PROCESOS_SECCION:
            _CACHE_MESAS[_codigo(tipo, anio, mes)] = (tipo, anio, _mesas(_codigo(tipo, anio, mes)))
        _CACHE_MESAS["_t"] = time.time()
    return [(c, *v) for c, v in _CACHE_MESAS.items() if c != "_t"]


@dlt.resource(name="elecciones_secciones", write_disposition="replace")
def elecciones_secciones():
    campos = ("censo_ine", "censo_escrutinio", "votos_blanco", "votos_nulos", "votos_candidaturas")
    for codigo, tipo, anio, f in _datos_mesas():
        secciones = {}
        for l in f.get("09", []):
            cusec = _cusec(l)
            if not cusec:
                continue
            clave = (_n(l, 9, 9), cusec)
            s = secciones.setdefault(clave, dict.fromkeys(campos, 0) | {"mesas": 0})
            s["mesas"] += 1
            # 09: censo INE 24-30, escrutinio 31-37, blancos 66-72, nulos 73-79, candidaturas 80-86
            for campo, (ini, fin) in zip(campos, [(24, 30), (31, 37), (66, 72), (73, 79), (80, 86)]):
                s[campo] += _n(l, ini, fin) or 0
        yield [
            {"proceso": codigo, "tipo": tipo, "anio": anio, "vuelta": vuelta, "cod_seccion": cusec,
             "cod_mun": cusec[:5], **s}
            for (vuelta, cusec), s in secciones.items()
        ]


@dlt.resource(name="elecciones_secciones_votos", write_disposition="replace")
def elecciones_secciones_votos():
    for codigo, tipo, anio, f in _datos_mesas():
        votos = {}
        for l in f.get("10", []):
            cusec = _cusec(l)
            if not cusec:
                continue
            # 10: candidatura 24-29, votos 30-36
            clave = (_n(l, 9, 9), cusec, _s(l, 24, 29))
            votos[clave] = votos.get(clave, 0) + (_n(l, 30, 36) or 0)
        yield [
            {"proceso": codigo, "tipo": tipo, "anio": anio, "vuelta": vuelta, "cod_seccion": cusec,
             "cod_candidatura": cand, "votos": v}
            for (vuelta, cusec, cand), v in votos.items()
            if v > 0
        ]


@dlt.source(name="elecciones")
def elecciones():
    return [
        elecciones_procesos,
        elecciones_candidaturas,
        elecciones_municipios,
        elecciones_municipios_votos,
        elecciones_ambitos,
        elecciones_ambitos_votos,
        elecciones_secciones,
        elecciones_secciones_votos,
    ]


if __name__ == "__main__":
    from ingestion.destino import pipeline

    print(pipeline("elecciones").run(elecciones()))
