"""Elecciones a las Cortes de Castilla y León por sección censal, 1983-2026 (Junta de CyL).

Fuente: portal de datos abiertos de la Junta de Castilla y León, licencia CC BY 4.0.
El conjunto de la última elección es «Elecciones 2026» (sector público):

    https://datosabiertos.jcyl.es/web/jcyl/set/es/sector-publico/elecciones_2026_final/1285663344325

y su recurso CSV redirige a un fichero estático de Transparencia. Hay uno por elección,
desde la primera (1983), con el escrutinio por MESA:

    https://transparencia.jcyl.es/resultadoselectorales/<año>.csv

(los mismos datos, todos juntos, están en la API de Opendatasoft de la Junta,
https://analisis.datosabiertos.jcyl.es, conjunto `resultados-electorales-1983-actualidad`;
se ha comprobado que la suma de votos por año es idéntica a la de los CSV).

Formato largo, separador «;»: una fila por mesa y candidatura, con los datos de la mesa
repetidos en cada fila:

    Código de mesa;Provincia;Código municipio;Municipio;Distrito;Sección;Mesa;Censo;
    Primer Avance;Segundo Avance;Total Votantes;Votos Nulos;Votos Blanco;Partido;Nº Votos

«Código de mesa» = provincia(2)-municipio(3)-distrito(1 o 2)-sección-mesa, y es la única
columna geográfica que viene igual en todos los años: el CUSEC sale de ella (provincia +
municipio + distrito a 2 + sección a 3).

Trampas (comprobadas fichero a fichero):
- Dos formatos. 2026: UTF-8 con BOM, columna «Año», «Código», «Votos Blancos» y tres
  avances. 1983-2022: Latin-1, sin «Año», cabecera partida en dos líneas («"Código
  \\nmunicipio"», entre comillas: el lector CSV la junta), «Votos Blanco».
- 1983-1995: la sección viene con 4 caracteres («0001»); en 1991 y 1995 además partida
  en subsecciones con letra («001A», «001B»…). Se quitan las letras y se suman a la sección.
- 2022: las columnas «Código municipio» y «Sección» vienen sin ceros a la izquierda (el
  código de mesa sí los trae; por eso se usa este).
- 2019: 110 cifras con punto de millar («1.034»).
- CERA: 2026 lo trae en 19 mesas (municipio 990, distrito 99); 1983 trae dos mesas con
  distrito 99 en Burgos y Miranda de Ebro (643 y 116 de censo, 14 % de votantes, sin
  sección real). Se descartan ambas. El resto de años no traen el CERA.
- Siglas tal como vienen, y cambian de provincia a provincia en la misma elección
  («P.S.O.E.»/«PSOE», «U.P.L.»/«UPL», «PSCL-PSOE» en 1991, cinco grafías de IU en 2019…).
- Votos a candidaturas = suma de las filas de partido de la mesa. No siempre es votantes −
  nulos − blancos: 2 mesas en 1983 (a Adanero le falta la fila de AP; Langa de Duero
  suma 425 votos con 100 votantes), 2 en 1995 (Cacabelos, compensadas entre sí) y 7 en
  2019 (174 votos de menos).
- Municipios con el código INE de la fecha de la elección (no se recodifican).

Cuadre con el resultado oficial (web de resultados de la Junta, servicios.jcyl.es/elec,
JSON …/backend-difu/<aaaamm>/scope/000000000000000000000334/1/508/1/1/30.json, que trae
el CERA aparte en «scopeCera» desde 1987 salvo 1999). El JSON no es coherente consigo
mismo: en 1995 y 1999 su «votosPartidos» ya va sin CERA y la lista de partidos con él;
en 2019 es al revés (la lista va sin CERA y «votosPartidos» suma 174 de más por las 7
mesas de arriba). Votos a candidaturas del módulo frente al oficial sin CERA:
    1983 −2.211 (0,16 %: filas de partido que faltan; siglas BAE-PRE / BAE-PRE-ACP)
    1987 +4.426 (0,31 %), 1991 +1.678 (0,12 %), 1995 +383 (0,03 %): el fichero no
      coincide con el JSON partido a partido; no hay forma de saber cuál está bien.
    1999 (sin CERA separado: la lista de partidos lleva 12.198 votos más repartidos en
      proporción, que es el CERA), 2003, 2007, 2011, 2015, 2019, 2022 y 2026: exacto.
`python -m ingestion.autonomicas.castilla_leon` imprime las cifras para comprobarlo.
"""

import csv
import io
import json
import re
from datetime import date

import requests

from ingestion.autonomicas import cache

COD_CCAA = "07"
SLUG = "castilla_leon"
FUENTE = ("https://datosabiertos.jcyl.es/web/jcyl/set/es/sector-publico/"
          "elecciones_2026_final/1285663344325")
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}


def _p(proceso: str, d: date) -> dict:
    meses = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
             "septiembre", "octubre", "noviembre", "diciembre"]
    return {"proceso": proceso, "fecha": d,
            "eleccion": f"Cortes de Castilla y León, {meses[d.month - 1]} de {d.year}"}


PROCESOS = [
    _p("A07198305", date(1983, 5, 8)),
    _p("A07198706", date(1987, 6, 10)),
    _p("A07199105", date(1991, 5, 26)),
    _p("A07199505", date(1995, 5, 28)),
    _p("A07199906", date(1999, 6, 13)),
    _p("A07200305", date(2003, 5, 25)),
    _p("A07200705", date(2007, 5, 27)),
    _p("A07201105", date(2011, 5, 22)),
    _p("A07201505", date(2015, 5, 24)),
    _p("A07201905", date(2019, 5, 26)),
    _p("A07202202", date(2022, 2, 13)),
    _p("A07202603", date(2026, 3, 15)),
]

URL = "https://transparencia.jcyl.es/resultadoselectorales/{anio}.csv"
URL_OFICIAL = ("https://servicios.jcyl.es/elec/backend-difu/{conv}/scope/"
               "000000000000000000000334/1/508/1/1/30.json")

MUNICIPIO_CERA = "990"
DISTRITO_CERA = "99"


def _n(texto: str) -> int:
    """Entero de la fuente (2019 trae punto de millar)."""
    return int(texto.replace(".", "").strip() or 0)


def _filas(proceso: str) -> list[dict]:
    """Filas del CSV por mesa y partido (descarga en caché)."""
    destino = cache(SLUG) / f"{proceso}.csv"
    if not destino.exists():
        r = requests.get(URL.format(anio=proceso[3:7]), headers=CABECERAS, timeout=300)
        r.raise_for_status()
        destino.write_bytes(r.content)
    datos = destino.read_bytes()
    try:
        texto = datos.decode("utf-8-sig")
    except UnicodeDecodeError:
        texto = datos.decode("latin-1")
    lector = csv.DictReader(io.StringIO(texto), delimiter=";")
    # Cabeceras de 1983-2022 y de 2026 a un mismo nombre («Código \nmunicipio», «Votos Blanco»).
    lector.fieldnames = [" ".join(c.split()).replace("Votos Blancos", "Votos Blanco")
                         for c in lector.fieldnames]
    return [f for f in lector if f.get("Nº Votos") is not None]


def _cusec(fila: dict) -> str | None:
    """Código de sección del INE (10 dígitos) o None si es CERA / sin sección."""
    prov, mun, dist, secc = fila["Código de mesa"].strip().split("-")[:4]
    if mun == MUNICIPIO_CERA or dist == DISTRITO_CERA:
        return None
    secc = re.sub(r"\D", "", secc)          # subsecciones «001A» de 1991 y 1995
    return prov + mun + dist.zfill(2) + secc[-3:].zfill(3)


def secciones(proceso: str):
    """Una fila por sección: censo, blancos, nulos y votos a candidaturas."""
    mesas: dict[str, dict] = {}
    candidaturas: dict[str, int] = {}
    for f in _filas(proceso):
        mesa = f["Código de mesa"]
        mesas.setdefault(mesa, f)
        candidaturas[mesa] = candidaturas.get(mesa, 0) + _n(f["Nº Votos"])
    acum: dict[str, dict] = {}
    for mesa, f in mesas.items():
        cod = _cusec(f)
        if cod is None:
            continue
        s = acum.setdefault(cod, {"cod_seccion": cod, "censo": 0, "votos_blanco": 0,
                                  "votos_nulos": 0, "votos_candidaturas": 0})
        s["censo"] += _n(f["Censo"])
        s["votos_blanco"] += _n(f["Votos Blanco"])
        s["votos_nulos"] += _n(f["Votos Nulos"])
        s["votos_candidaturas"] += candidaturas[mesa]
    yield from acum.values()


def votos(proceso: str):
    """Una fila por sección y candidatura."""
    acum: dict[tuple[str, str], int] = {}
    for f in _filas(proceso):
        cod = _cusec(f)
        if cod is None:
            continue
        clave = (cod, f["Partido"].strip())
        acum[clave] = acum.get(clave, 0) + _n(f["Nº Votos"])
    for (cod, siglas), n in acum.items():
        yield {"cod_seccion": cod, "siglas": siglas, "votos": n}


def oficial(proceso: str) -> dict:
    """Totales de la web oficial de resultados de la Junta (solo para comprobar)."""
    destino = cache(SLUG) / f"{proceso}_oficial.json"
    if not destino.exists():
        r = requests.get(URL_OFICIAL.format(conv=proceso[3:]), headers=CABECERAS, timeout=120)
        r.raise_for_status()
        destino.write_bytes(r.content)
    d = json.loads(destino.read_text(encoding="utf-8"))
    e = d["scope"]["escrutinio"]
    cera = (d.get("scopeCera") or {}).get("escrutinio") or {}
    return {"votos_partidos": e["votosPartidos"]["def"],
            "suma_partidos": sum(p["votos"]["def"] for p in e["partidos"]),
            "cera": cera.get("votosPartidos", {}).get("def")}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
    print("\n== Cuadre con la web oficial (votos a candidaturas)")
    for p in PROCESOS:
        mod = sum(r["votos_candidaturas"] for r in secciones(p["proceso"]))
        o = oficial(p["proceso"])
        c = o["cera"] or 0
        print(f"{p['proceso']}: módulo {mod:,} · votosPartidos {o['votos_partidos']:,}"
              f" · suma de partidos {o['suma_partidos']:,} · CERA {o['cera'] if o['cera'] is not None else '—'}"
              f" · dif. con votosPartidos−CERA {mod - o['votos_partidos'] + c:+,}"
              f" · con partidos−CERA {mod - o['suma_partidos'] + c:+,}"
              f" · con votosPartidos {mod - o['votos_partidos']:+,}")
