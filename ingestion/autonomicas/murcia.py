"""Elecciones a la Asamblea Regional de Murcia por sección censal (CREM, CARM).

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

Comprobación: total oficial (edicto de la Junta Electoral, BORM 14-6-2023, y
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

PROCESOS = [
    {"proceso": "A14202305", "fecha": date(2023, 5, 28),
     "eleccion": "Asamblea Regional de Murcia, mayo de 2023"},
]

# Tablas de resultados por mesa de cada proceso.
TABLAS = {"A14202305": ["sec56", "sec57"]}

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


def _mesas(proceso: str) -> Iterable[tuple[str, dict[str, int], dict[str, int]]]:
    """(cusec, generales, votos por siglas) de cada mesa."""
    for tabla in TABLAS[proceso]:
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
                            m = re.search(r"\(([^()]*)\)\s*$", v)
                            cab[c] = ("p", (m.group(1) if m else v).strip())
                continue
            m = MESA.match(str(fila[0]).strip())
            if not m:
                continue
            cusec = "30" + m.group(1) + m.group(2) + m.group(3)
            gen, par = {}, {}
            for c, (tipo, nombre) in cab.items():
                n = int(round(float(fila[c] or 0)))
                (gen if tipo == "g" else par)[nombre] = n
            yield cusec, gen, par
        if cab is None:
            raise RuntimeError(f"{tabla}: no se encontró la fila de cabecera")


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


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
