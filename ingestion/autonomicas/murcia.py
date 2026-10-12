"""Elecciones a la Asamblea Regional de Murcia, 1983-2023 (CREM, CARM).

Fuente
------
El Centro Regional de Estadística de Murcia (CREM, Consejería de Presidencia de
la CARM) publica en su sistema SICREM la publicación PU2077 «Elecciones
Autonómicas», con un bloque por convocatoria. El de las del 28 de mayo de 2023
(Indice50.html) trae, entre otras, dos tablas «Principales resultados según
mesa», partidas por orden alfabético de municipios:

    https://econet.carm.es/inicio/-/crem/sicrem/PU2077/excel/sec56.xls   Abanilla a Mazarrón
    https://econet.carm.es/inicio/-/crem/sicrem/PU2077/excel/sec57.xls   Molina de Segura a Yecla

(también en /pdf/secNN.pdf; sec54/sec55 son lo mismo agregado por distrito y
sección, pero sin código de municipio, solo el nombre: por eso se leen las de
mesa y se suman aquí).

Formato y trampas
-----------------
- Excel 97 (.xls, se lee con xlrd). Una hoja; cabecera de columnas en la fila 5;
  cada magnitud ocupa DOS columnas (valor y porcentaje): CENSO, ABSTENCIÓN,
  PARTICIPACIÓN, VOTOS NULOS, VOTOS VÁLIDOS, Votos Blancos, Votos a candidaturas
  y después una pareja por candidatura. Solo se leen las columnas de valor.
- Filas mezcladas: total regional, total de cada municipio (por nombre) y las
  mesas, cuyo rótulo es «MMM-DD-SSS-L»: municipio (3 dígitos, el código INE dentro
  de la provincia 30), distrito, sección y letra de mesa (U, A, B, C). El CUSEC
  es '30' + MMM + DD + SSS. Solo se usan las filas de mesa.
- Solo vienen las candidaturas que superaron el 1 % del voto regional (7 de
  ellas: PP, PSOE, VOX, Podemos+IU-Verdes+AV, MC REG, Cs, MR-VE). La columna
  «Votos a candidaturas» sí incluye a todas, así que la suma del fichero de votos
  queda algo por debajo de votos_candidaturas (el resto son partidos menores
  que no se publican por mesa).
- Las siglas son el texto entre paréntesis del nombre de la columna.
- El C.E.R.A. aparece como una fila «C.E.R.A.» sin código de mesa al final de
  sec57: se descarta. Los totales regionales oficiales lo incluyen.
- Las páginas HTML de econet.carm.es están detrás de un antibots (Radware) que
  devuelve una página de captcha a clientes automáticos; los ficheros /excel/ y
  /pdf/ se descargan sin problema. Si algún día devuelve HTML en vez de .xls, se
  avisa con un error claro.

Histórico (1983-2019)
---------------------
La misma publicación PU2077 trae un bloque por convocatoria. Ficheros usados:

    año   fecha        nivel     tablas (excel/<tabla>.xls)
    1983  8-5-1983     municipio sec92
    1987  10-6-1987    municipio sec87
    1991  26-5-1991    municipio sec82
    1995  28-5-1995    municipio sec77
    1999  13-6-1999    municipio sec72   (sec41 es una versión anterior del mismo cuadro)
    2003  25-5-2003    mesa      sec66, sec67
    2007  27-5-2007    mesa      sec34, sec35
    2011  22-5-2011    mesa      sec25, sec26
    2015  24-5-2015    mesa      sec16, sec17
    2019  26-5-2019    mesa      sec7, sec8   (¡sin cero a la izquierda! sec07 da 404)
    2023  28-5-2023    mesa      sec56, sec57

- 2003-2023 por mesa, con el mismo formato que 2023: solo candidaturas de más del 1 %
  regional, y el CERA en filas «C.E.R.A. (CIRCUNSCRIPCIÓN N)» o «C.E.R.A.», que se
  descartan. El CREM tampoco da por municipio las candidaturas pequeñas (sec52 y sus
  equivalentes tienen el mismo corte del 1 %), así que esos años no tienen
  municipios(): la página de la comunidad sale de las secciones.
- 1983-1999 solo por municipio («Principales resultados según circunscripciones y
  municipios»), por NOMBRE y sin código: se traduce con MUNICIPIOS. Aquí sí están
  todas las candidaturas, pero 1987, 1991 y 1995 agrupan las pequeñas en «Otros» (se
  deja con esas siglas). Las filas de municipio son datos PROVISIONALES (Junta
  Electoral, Delegación del Gobierno o INE); solo la fila regional y las de
  circunscripción vienen del BORM. Desde 1991 hay filas «C.E.R.A. (CIRCUNSCRIPCIÓN
  N)», que se descartan; 1983 y 1987 no separan el CERA.
  Cuadre (municipios + CERA frente a la fila regional oficial): 1983, 1995 (votos) y
  1999 exactos; 1991 a 47 votos a candidaturas (40 en «Otros»); 1987 no cuadra por
  ser provisional: faltan 988 votos a candidaturas (PSOE -516, AP -329) y sobran 197
  de censo y 335 nulos. En 1991 y 1995 el censo municipal suma 1.040 y 305 más que
  el oficial.
- 2003-2023: secciones + filas CERA = fila regional oficial, exacto en censo, nulos,
  blancos, votos a candidaturas y en cada candidatura publicada.
- 1983: Los Alcázares (30902) aún no existía (era parte de San Javier y
  Torre-Pacheco); Santomera (30901) ya estaba segregada.
- Siglas: el último paréntesis del nombre, contando paréntesis anidados
  («...Región de Murcia ((IU+LV)RM)» -> «(IU+LV)RM»); si no hay, el nombre entero
  («Coalición AP-PDP-UL», «Otros»).
  2015: la candidatura «Ganar la Región de Murcia.IP» sale con el texto largo de su
  paréntesis («Izquierda Unida-Verdes Región de Murcia y Construyendo la
  Izquierda-Alternativa Socialista»), tal cual lo publica el CREM.
- Los ficheros de 2019 son sec2..sec9 con UNA cifra (sec2 regional, sec3 municipios,
  sec5/6 secciones, sec7/8 mesas, sec9 escaños); sec02..sec09 dan 404.

Comprobación 2023: total oficial (edicto de la Junta Electoral, BORM 14-6-2023, y
sec51.xls del CREM): censo 1.098.543, nulos 10.038, blancos 8.263,
candidaturas 676.554; PP 293.051, PSOE 175.505, VOX 121.321 (con el CERA). Sin
el CERA (censo 37.536, 2.640 votantes) cuadra exacto con la suma de las mesas.
"""

import re
from collections import defaultdict
from datetime import date
from typing import Iterable

import requests
import xlrd

from ingestion.autonomicas import cache

COD_CCAA = "14"
SLUG = "murcia"
FUENTE = "https://econet.carm.es/inicio/-/crem/sicrem/PU2077/Indice50.html"
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

URL_XLS = "https://econet.carm.es/inicio/-/crem/sicrem/PU2077/excel/{tabla}.xls"

_MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
          "septiembre", "octubre", "noviembre", "diciembre"]
_FECHAS = [date(1983, 5, 8), date(1987, 6, 10), date(1991, 5, 26), date(1995, 5, 28),
           date(1999, 6, 13), date(2003, 5, 25), date(2007, 5, 27), date(2011, 5, 22),
           date(2015, 5, 24), date(2019, 5, 26), date(2023, 5, 28)]
PROCESOS = [
    {"proceso": f"A14{f.year}{f.month:02d}", "fecha": f,
     "eleccion": f"Asamblea Regional de Murcia, {_MESES[f.month - 1]} de {f.year}"}
    for f in _FECHAS
]

# Tablas de resultados por mesa (2003-2023) y por municipio (1983-1999) de cada proceso.
TABLAS = {
    "A14200305": ["sec66", "sec67"],
    "A14200705": ["sec34", "sec35"],
    "A14201105": ["sec25", "sec26"],
    "A14201505": ["sec16", "sec17"],
    "A14201905": ["sec7", "sec8"],
    "A14202305": ["sec56", "sec57"],
}
TABLAS_MUNICIPIO = {
    "A14198305": "sec92",
    "A14198706": "sec87",
    "A14199105": "sec82",
    "A14199505": "sec77",
    "A14199906": "sec72",
}

# Nombre del CREM -> código INE (sacado de los rótulos de mesa de 2003-2023).
MUNICIPIOS = {
    "Abanilla": "001", "Abarán": "002", "Águilas": "003", "Albudeite": "004",
    "Alcantarilla": "005", "Aledo": "006", "Alguazas": "007", "Alhama de Murcia": "008",
    "Archena": "009", "Beniel": "010", "Blanca": "011", "Bullas": "012",
    "Calasparra": "013", "Campos del Río": "014", "Caravaca de la Cruz": "015",
    "Cartagena": "016", "Cehegín": "017", "Ceutí": "018", "Cieza": "019",
    "Fortuna": "020", "Fuente Álamo": "021", "Jumilla": "022", "Librilla": "023",
    "Lorca": "024", "Lorquí": "025", "Mazarrón": "026", "Molina de Segura": "027",
    "Moratalla": "028", "Mula": "029", "Murcia": "030", "Ojós": "031", "Pliego": "032",
    "Puerto Lumbreras": "033", "Ricote": "034", "San Javier": "035",
    "San Pedro del Pinatar": "036", "Torre-Pacheco": "037",
    "Torres de Cotillas (Las)": "038", "Totana": "039", "Ulea": "040",
    "Unión (La)": "041", "Villanueva del Río Segura": "042", "Yecla": "043",
    "Santomera": "901", "Alcázares (Los)": "902",
}

MESA = re.compile(r"^(\d{3})-(\d{2})-(\d{3})-([A-Z])$")
GENERALES = {
    "CENSO": "censo",
    "VOTOS NULOS": "votos_nulos",
    "Votos Blancos": "votos_blanco",
    "Votos a candidaturas": "votos_candidaturas",
}


def _descargar(proceso: str, tabla: str) -> str:
    destino = cache(SLUG) / f"{proceso}_{tabla}.xls"
    if not destino.exists():
        r = requests.get(URL_XLS.format(tabla=tabla), headers=CABECERAS, timeout=120)
        r.raise_for_status()
        if not r.content.startswith(b"\xd0\xcf\x11\xe0"):  # cabecera OLE2 de un .xls
            raise RuntimeError(f"{r.url} no devolvió un .xls (¿captcha del CREM?)")
        destino.write_bytes(r.content)
    return str(destino)


def _siglas(nombre: str) -> str:
    """Texto del último paréntesis (con anidados); si no hay, el nombre entero."""
    nombre = nombre.strip()
    if nombre.endswith(")"):
        nivel = 0
        for i in range(len(nombre) - 1, -1, -1):
            nivel += {")": 1, "(": -1}.get(nombre[i], 0)
            if nivel == 0:
                dentro = nombre[i + 1:-1].strip()
                if dentro and i > 0:
                    return dentro
                break
    return nombre


def _filas(proceso: str, tabla: str) -> Iterable[tuple[str, dict[str, int], dict[str, int]]]:
    """(rótulo, generales, votos por siglas) de cada fila con datos del cuadro."""
    hoja = xlrd.open_workbook(_descargar(proceso, tabla)).sheet_by_index(0)
    cab = None
    for r in range(hoja.nrows):
        fila = hoja.row_values(r)
        if cab is None:
            if str(fila[1]).strip() == "CENSO":
                cab = {}
                for c, v in enumerate(fila):
                    v = str(v).strip()
                    if not v:
                        continue
                    if v in GENERALES:
                        cab[c] = ("g", GENERALES[v])
                    elif c >= 15:
                        cab[c] = ("p", _siglas(v))
            continue
        if not isinstance(fila[1], float):  # filas vacías y la de «Electores / Porcentajes»
            continue
        gen, par = {}, {}
        for c, (tipo, nombre) in cab.items():
            n = int(round(float(fila[c] or 0)))
            d = gen if tipo == "g" else par
            d[nombre] = d.get(nombre, 0) + n
        yield str(fila[0]).strip(), gen, par
    if cab is None:
        raise RuntimeError(f"{tabla}: no se encontró la fila de cabecera")


def _mesas(proceso: str) -> Iterable[tuple[str, dict[str, int], dict[str, int]]]:
    """(cusec, generales, votos por siglas) de cada mesa (2003-2023)."""
    for tabla in TABLAS.get(proceso, []):
        for rotulo, gen, par in _filas(proceso, tabla):
            m = MESA.match(rotulo)
            if m:
                yield "30" + m.group(1) + m.group(2) + m.group(3), gen, par


def _municipios(proceso: str) -> Iterable[tuple[str, dict[str, int], dict[str, int]]]:
    """(cod_mun, generales, votos por siglas) de cada municipio (1983-1999)."""
    tabla = TABLAS_MUNICIPIO.get(proceso)
    if not tabla:
        return
    vistos = 0
    for rotulo, gen, par in _filas(proceso, tabla):
        if rotulo == "Región de Murcia" or rotulo.startswith(("CIRCUNSCRIPCIÓN", "C.E.R.A.")):
            continue
        if rotulo not in MUNICIPIOS:
            raise RuntimeError(f"{tabla}: municipio desconocido {rotulo!r}")
        vistos += 1
        yield "30" + MUNICIPIOS[rotulo], gen, par
    if vistos < 44:
        raise RuntimeError(f"{tabla}: solo {vistos} municipios")


def secciones(proceso: str) -> Iterable[dict]:
    acum: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    for cusec, gen, _ in _mesas(proceso):
        for k, v in gen.items():
            acum[cusec][k] += v
    for cusec, d in sorted(acum.items()):
        yield {"cod_seccion": cusec, "censo": d["censo"], "votos_blanco": d["votos_blanco"],
               "votos_nulos": d["votos_nulos"], "votos_candidaturas": d["votos_candidaturas"]}


def votos(proceso: str) -> Iterable[dict]:
    acum: dict[tuple[str, str], int] = defaultdict(int)
    for cusec, _, par in _mesas(proceso):
        for siglas, n in par.items():
            acum[(cusec, siglas)] += n
    for (cusec, siglas), n in sorted(acum.items()):
        if n:
            yield {"cod_seccion": cusec, "siglas": siglas, "votos": n}


def municipios(proceso: str) -> Iterable[dict]:
    """Solo 1983-1999, que no tienen datos por mesa; [] para el resto."""
    for cod, g, _ in _municipios(proceso):
        yield {"cod_mun": cod, "censo": g["censo"], "votos_blanco": g["votos_blanco"],
               "votos_nulos": g["votos_nulos"], "votos_candidaturas": g["votos_candidaturas"]}


def votos_municipios(proceso: str) -> Iterable[dict]:
    for cod, _, par in _municipios(proceso):
        for siglas, n in par.items():
            if n:
                yield {"cod_mun": cod, "siglas": siglas, "votos": n}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
