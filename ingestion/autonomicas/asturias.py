"""Elecciones a la Junta General del Principado de Asturias: por concejo (toda la
comunidad, 1983-2023) y por sección censal (solo Gijón).

Asturias no publica resultados por mesa para toda la comunidad. Hay dos fuentes
oficiales que se usan juntas (ver el apartado «Histórico por municipio» de
ingestion/autonomicas/__init__.py):

1. MUNICIPIOS (los 78 concejos, todas las autonómicas): SADEI, la estadística del
   Principado, con los resultados definitivos de las Juntas Electorales:

       https://www.sadei.es/sadei/resultados-electorales/elecciones-autonomicas_249_1_ap.html

   Son tablas PC-Axis en un PxWeb 2020 (ASP.NET):
   - 190402: censo, votantes, votos a candidaturas, blancos, nulos y abstención por
     concejo para las 12 convocatorias (1983-2023).
   - 190404 ... 190426 (de dos en dos): votos y escaños por concejo y candidatura,
     una tabla por elección (190404 = 1983 ... 190426 = 2023).

   Trampas de SADEI:
   - El enlace «directo» a cada .px (y los botones de descarga de la portada)
     devuelve un fichero con la cabecera y DATA vacío: PxWeb solo entrega datos
     después de seleccionar valores. Hay que abrir la página de selección
     (/sadei/pxweb/es/01/19__04/<tabla>.px) con sesión, mandar el formulario
     (postback ASP.NET con __VIEWSTATE, todos los valores de cada lista y el botón
     ButtonViewTable) y, con la MISMA sesión, pedir
     <tabla>.px/table/tableViewLayout1/?downloadfile=FileTypePX. La API REST de
     PxWeb (/api/v1/...) no está publicada.
   - El .px va en iso-8859-15; ".." es «sin dato» (partido que no se presentó en ese
     concejo) y cuenta como 0.
   - En el territorio vienen también ASTURIAS (33000), las tres circunscripciones
     (33501-33503) y el voto CERA: «Residentes ausentes» (33099) en la 190402 y uno
     por circunscripción (33079-33081) en las de votos. Se quedan solo los 78
     concejos (33001-33078, ya con el código INE).
   - El campo MATRIX del .px no coincide con la tabla (la de 2023 dice 1904022019):
     el año sale de la tabla pedida, no del fichero.
   - Las siglas son lo que va antes de « - » en la etiqueta del partido; SADEI
     cambia los puntos por guiones bajos (BLOQUE POR AST_-UNA, HARTOS_ORG).
   - Los votos a candidaturas por concejo de la 190402 coinciden con la suma de
     partidos de la tabla de votos; el censo es el de los concejos, sin CERA.

   Búsqueda de resultados por mesa del resto de concejos (repetida el 13-10-2026, sin
   éxito): el PxWeb de SADEI (19__04) solo tiene tablas por concejo; datos.gob.es solo
   lista ese conjunto de SADEI (a03002951-elecciones-autonomicas-asturias); la Junta
   General (jgpa.es) solo publica las actas por circunscripción; la web de resultados del
   Principado de 2023 no consta en la Wayback (solo www.elecciones2012.asturias.es); el
   portal de datos de Oviedo responde 403 y Avilés no tiene portal con elecciones.

2. SECCIONES (solo Gijón, 33024, ~23 % del censo): datos abiertos del Ayuntamiento
   de Gijón, un CSV por convocatoria (https://opendata.gijon.es/descargar.php?id=<id>&tipo=CSV;
   fichas en datos.gob.es l01330241-datos-elecciones-autonomicas-...). Columnas:
   AÑO, TITULO, FECHA_ELECCIONES, DISTRITO, SECCION, MESA, PARTIDO, NUM_VOTOS, PORCENTAJE.

   Trampas de Gijón:
   - Formato largo: en PARTIDO van tanto las candidaturas como los totales de la mesa
     (Electores, Votantes, Abstenciones, Validos, Blancos, Nulos).
   - Hasta 2011 un mismo fichero junta varias elecciones del mismo año (autonómicas
     y municipales, y en 1999 también europeas, en 2011 generales): se filtra por
     TITULO = «Elecciones Autonómicas»/«Elecciones Autonomicas».
   - DISTRITO y SECCION sin ceros a la izquierda; CUSEC = 33024 + distrito(2) +
     sección(3). La MESA se suma dentro de su sección. Las secciones son las del
     seccionado de cada año, no las de hoy.
   - PORCENTAJE lleva coma decimal y en los ficheros sin comillas parte la fila: se
     lee por posición (solo las ocho primeras columnas).
   - No hay filas del CERA. El censo es el de escrutinio de las mesas.
   - Hay CSV de todas las autonómicas, pero solo se usan los que cuadran con el
     total de Gijón en SADEI (2007, 2011, 2015, 2019 y 2023, diferencias de menos del
     0,05 %). Los de 1983, 1987, 1991, 1999, 2003 y 2012 omiten a IU (o a los
     partidos pequeños) y el de 1995 no trae mesas: ver GIJON_DESCARTADOS.
   - Siglas tal cual las da el Ayuntamiento (FAC, IU-IAS, C s, F.A.C.…), distintas de
     las de SADEI; la familia política se asigna en dbt.
"""

import csv
import html
import io
import re
from collections import defaultdict
from datetime import date

import requests

from ingestion.autonomicas import cache

SLUG = "asturias"
COD_CCAA = "03"
FUENTE = "https://www.sadei.es/sadei/resultados-electorales/elecciones-autonomicas_249_1_ap.html"
COBERTURA = ("Por concejo en toda Asturias; por sección censal solo en Gijón "
             "(el Principado no publica resultados por mesa)")
CABECERAS = {"User-Agent": "Mozilla/5.0 (SpainFacts/1.0; +https://spainfacts.github.io)"}

_MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
          "septiembre", "octubre", "noviembre", "diciembre"]

# fecha, tabla de votos de SADEI, id del CSV de Gijón (None si no hay o no cuadra)
_ELECCIONES = [
    (date(1983, 5, 8), "190404", None),
    (date(1987, 6, 10), "190406", None),
    (date(1991, 5, 26), "190408", None),
    (date(1995, 5, 28), "190410", None),
    (date(1999, 6, 13), "190412", None),
    (date(2003, 5, 25), "190414", None),
    (date(2007, 5, 27), "190416", 196),
    (date(2011, 5, 22), "190418", 199),
    (date(2012, 3, 25), "190420", None),
    (date(2015, 5, 24), "190422", 456),
    (date(2019, 5, 26), "190424", 918),
    (date(2023, 5, 28), "190426", 958),
]

# CSV de Gijón que existen pero no se usan, y por qué (comprobado contra SADEI).
GIJON_DESCARTADOS = {
    183: "1983: sin blancos ni nulos y solo 4 partidos (faltan ~3.300 votos)",
    185: "1987: falta IU y los electores son los votantes de las municipales",
    187: "1991: falta IU (16.593 votos en Gijón según SADEI)",
    190: "1995: solo una fila con el total del municipio, sin mesas",
    192: "1999: falta IU (9.216)",
    194: "2003: falta IU-BA (14.033)",
    200: "2012: falta IU-IX (18.565)",
}

PROCESOS = [
    {"proceso": f"A{COD_CCAA}{f.year}{f.month:02d}", "fecha": f,
     "eleccion": f"Junta General del Principado de Asturias, {_MESES[f.month - 1]} de {f.year}"}
    for f, _, _ in _ELECCIONES
]
_POR_PROCESO = {p["proceso"]: e for p, e in zip(PROCESOS, _ELECCIONES)}

TABLA_PARTICIPACION = "190402"
SADEI_PX = "https://www.sadei.es/sadei/pxweb/es/01/19__04/{tabla}.px"
GIJON_CSV = "https://opendata.gijon.es/descargar.php?id={id}&tipo=CSV"
COD_GIJON = "33024"
NO_PARTIDOS = {"Electores", "Votantes", "Abstenciones", "Validos", "Blancos", "Nulos"}


def _eleccion(proceso: str):
    if proceso not in _POR_PROCESO:
        raise ValueError(f"Proceso desconocido: {proceso}")
    return _POR_PROCESO[proceso]


# ----------------------------------------------------------------- SADEI (PC-Axis)

def _descargar_px(tabla: str) -> bytes:
    """Selecciona todos los valores en el PxWeb y descarga el .px con datos."""
    url = SADEI_PX.format(tabla=tabla)
    s = requests.Session()
    s.headers.update(CABECERAS)
    r = s.get(url, timeout=120)
    r.raise_for_status()
    t = r.text
    datos: list[tuple[str, str]] = []
    for m in re.finditer(r"<input[^>]*>", t):
        etiqueta = m.group(0)
        nombre = re.search(r'name="([^"]*)"', etiqueta)
        tipo = re.search(r'type="([^"]*)"', etiqueta)
        if not nombre or (tipo and tipo.group(1) in ("submit", "button", "image", "checkbox")):
            continue
        valor = re.search(r'value="([^"]*)"', etiqueta)
        datos.append((nombre.group(1), html.unescape(valor.group(1)) if valor else ""))
    for m in re.finditer(r'<select[^>]*name="([^"]*)"[^>]*>(.*?)</select>', t, re.S):
        opciones = re.findall(r'<option[^>]*value="([^"]*)"', m.group(2))
        if m.group(1).endswith("ValuesListBox"):
            datos += [(m.group(1), html.unescape(o)) for o in opciones]
        else:
            elegida = (re.search(r'<option[^>]*selected[^>]*value="([^"]*)"', m.group(2))
                       or re.search(r'<option[^>]*value="([^"]*)"', m.group(2)))
            if elegida:
                datos.append((m.group(1), html.unescape(elegida.group(1))))
    boton = re.search(r'name="([^"]*ButtonViewTable)"', t)
    if not boton:
        raise RuntimeError(f"SADEI {tabla}: no encuentro el botón de ver tabla")
    datos.append((boton.group(1), "Continuar"))
    r = s.post(url, data=datos, timeout=180)
    r.raise_for_status()
    r = s.get(f"{url}/table/tableViewLayout1/?downloadfile=FileTypePX", timeout=180)
    r.raise_for_status()
    return r.content


def _px(tabla: str) -> dict:
    """Lee un .px de SADEI (con caché): {'dims': [(variable, [códigos])], 'data': [...]}."""
    ruta = cache(SLUG) / f"sadei_{tabla}.px"
    if not ruta.exists():
        contenido = _descargar_px(tabla)
        if b"DATA=" not in contenido:
            raise RuntimeError(f"SADEI {tabla}: la descarga no es un PC-Axis")
        ruta.write_bytes(contenido)
    texto = ruta.read_bytes().decode("iso-8859-15")
    cab, _, datos = texto.partition("\nDATA=")
    claves: dict[str, list[str]] = {}
    for m in re.finditer(r'([A-Z-]+(?:\("[^"]*"\))?)=((?:"[^"]*"|[^;"])*);', cab):
        claves[m.group(1)] = re.findall(r'"([^"]*)"', m.group(2)) or [m.group(2).strip()]
    variables = claves["STUB"] + claves.get("HEADING", [])
    dims = []
    for v in variables:
        codigos = claves.get(f'CODES("{v}")') or claves[f'VALUES("{v}")']
        dims.append((v, codigos, claves[f'VALUES("{v}")']))
    celdas = []
    for tok in re.findall(r'"[^"]*"|[^\s;"]+', datos.split(";")[0]):
        tok = tok.strip('"')
        celdas.append(int(float(tok)) if re.fullmatch(r"-?\d+(\.\d+)?", tok) else 0)
    total = 1
    for _, c, _ in dims:
        total *= len(c)
    if len(celdas) != total:
        raise RuntimeError(f"SADEI {tabla}: {len(celdas)} celdas, se esperaban {total} "
                           "(¿descarga vacía?); borra la caché y repite")
    return {"dims": dims, "data": celdas}


def _celdas(px: dict):
    """Recorre el cubo: ({variable: (código, etiqueta)}, valor), la última dimensión la más rápida."""
    dims, data = px["dims"], px["data"]
    tam = [len(c) for _, c, _ in dims]
    for i, valor in enumerate(data):
        resto, pos = i, {}
        for (v, cod, etq), n in reversed(list(zip(dims, tam))):
            resto, k = divmod(resto, n)
            pos[v] = (cod[k], etq[k])
        yield pos, valor


def _es_concejo(cod: str) -> bool:
    return cod.startswith("33") and 1 <= int(cod[2:]) <= 78


def municipios(proceso: str):
    fecha = _eleccion(proceso)[0]
    px = _px(TABLA_PARTICIPACION)
    var_conv = next(v for v, _, _ in px["dims"] if v.startswith("Convocatoria"))
    var_cifra = next(v for v, _, _ in px["dims"] if v.startswith("Censo"))
    var_terr = px["dims"][0][0]
    etiqueta = f"{fecha.day} de {_MESES[fecha.month - 1]} de {fecha.year}"
    campos = {"Censo electoral": "censo", "- Votos a candidaturas": "votos_candidaturas",
              "- Votos en blanco": "votos_blanco", "- Votos nulos": "votos_nulos"}
    acum: dict[str, dict] = defaultdict(dict)
    for pos, n in _celdas(px):
        cod = pos[var_terr][0]
        if pos[var_conv][1].lower() != etiqueta or not _es_concejo(cod):
            continue
        campo = campos.get(pos[var_cifra][1])
        if campo:
            acum[cod][campo] = n
    if len(acum) != 78:
        raise RuntimeError(f"{proceso}: {len(acum)} concejos en la tabla {TABLA_PARTICIPACION}")
    for cod, a in sorted(acum.items()):
        yield {"cod_mun": cod, "censo": a["censo"], "votos_blanco": a["votos_blanco"],
               "votos_nulos": a["votos_nulos"], "votos_candidaturas": a["votos_candidaturas"]}


def votos_municipios(proceso: str):
    px = _px(_eleccion(proceso)[1])
    var_terr = px["dims"][0][0]
    var_tipo = next(v for v, _, _ in px["dims"] if v.startswith("Votos"))
    var_part = next(v for v, _, _ in px["dims"] if v.startswith("Partidos"))
    acum: dict[tuple[str, str], int] = defaultdict(int)
    for pos, n in _celdas(px):
        cod = pos[var_terr][0]
        etq = pos[var_part][1]
        if pos[var_tipo][1] != "Votos" or etq == "TOTAL" or not _es_concejo(cod):
            continue
        acum[(cod, etq.split(" - ", 1)[0].strip())] += n
    for (cod, siglas), n in sorted(acum.items()):
        if n:
            yield {"cod_mun": cod, "siglas": siglas, "votos": n}


# ------------------------------------------------------------ Gijón (por sección)

def _filas(proceso: str) -> list[list[str]]:
    fecha, _, id_gijon = _eleccion(proceso)
    if id_gijon is None:
        return []
    ruta = cache(SLUG) / f"gijon_autonomicas_{fecha.year}.csv"
    if not ruta.exists():
        r = requests.get(GIJON_CSV.format(id=id_gijon), headers=CABECERAS, timeout=120)
        r.raise_for_status()
        ruta.write_bytes(r.content)
    lector = csv.reader(io.StringIO(ruta.read_bytes().decode("utf-8-sig")))
    cab = next(lector)
    assert cab[3:8] == ["DISTRITO", "SECCION", "MESA", "PARTIDO", "NUM_VOTOS"], cab
    filas = [f for f in lector
             if len(f) >= 8 and f[1].strip().startswith("Elecciones Auton")
             and f[3].strip() not in ("", "0")]
    if not filas:
        raise RuntimeError(f"{proceso}: el CSV de Gijón no trae autonómicas por mesa")
    return filas


def _seccion(distrito: str, seccion: str) -> str:
    return f"{COD_GIJON}{int(distrito):02d}{int(seccion):03d}"


def secciones(proceso: str):
    acum: dict[str, dict] = defaultdict(lambda: {"censo": 0, "votos_blanco": 0,
                                                 "votos_nulos": 0, "votos_candidaturas": 0})
    for f in _filas(proceso):
        cod = _seccion(f[3], f[4])
        partido, n = f[6].strip(), int(f[7] or 0)
        a = acum[cod]
        if partido == "Electores":
            a["censo"] += n
        elif partido == "Blancos":
            a["votos_blanco"] += n
        elif partido == "Nulos":
            a["votos_nulos"] += n
        elif partido not in NO_PARTIDOS:
            a["votos_candidaturas"] += n
    for cod, a in sorted(acum.items()):
        yield {"cod_seccion": cod, **a}


def votos(proceso: str):
    acum: dict[tuple[str, str], int] = defaultdict(int)
    for f in _filas(proceso):
        partido = f[6].strip()
        if partido in NO_PARTIDOS:
            continue
        acum[(_seccion(f[3], f[4]), partido)] += int(f[7] or 0)
    for (cod, siglas), n in sorted(acum.items()):
        if n:
            yield {"cod_seccion": cod, "siglas": siglas, "votos": n}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
