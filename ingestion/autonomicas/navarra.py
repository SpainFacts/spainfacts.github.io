"""Elecciones al Parlamento de Navarra, de 1983 a 2023 (Gobierno de Navarra).

Fuente: portal de datos abiertos del Gobierno de Navarra (CKAN), dos conjuntos del
Departamento de Presidencia e Igualdad (unidad responsable, la Junta Electoral;
resultados definitivos; licencia CC BY 4.0):

- «... agrupados por mesas electorales» (1999-2023), un CSV por elección y una fila
  por mesa: se suma a sección censal (secciones()/votos()).
    https://datosabiertos.navarra.es/es/dataset/resultados-de-las-elecciones-al-parlamento-de-navarra-agrupados-por-mesas-electorales
- «... agrupados por municipios» (1979-2023), un CSV por elección y una fila por
  municipio: se usa para 1983-1995, que no tienen fichero por mesas
  (municipios()/votos_municipios()).
    https://datosabiertos.navarra.es/es/dataset/resultados-de-las-elecciones-al-parlamento-de-navarra-agrupados-por-municipios

Trampas:
- Cada año tiene un formato distinto (separador, codificación, nombres de columna,
  orden), así que hay una ficha por elección en FORMATOS. En todos es «ancho»: una
  columna por candidatura, con la cabecera como siglas tal cual (cambian cada año).
- 1979 NO está: el recurso «1979» del conjunto por municipios descarga
  resultadosparlamentopormunicipio1983.csv, idéntico byte a byte al de 1983 (y sus
  candidaturas, AP-PDP-UL o Auzolan, son de 1983). No hay otra fuente abierta por
  municipio en el portal (NASTAT solo lo ofrece en tablas de Power BI).
- 1999-2003-2007-2011 traen distrito y sección en columnas propias; 2015-2023 en
  `Mesa` = «distrito-sección -mesa» (p. ej. «2-001 -B»). CUSEC = 31 + mun(3) +
  distrito(2) + sección(3); las letras de mesa (A, B, U = única) se suman.
- CERA (residentes ausentes), descartado: código 990 (2015-2023), 999 (2007, 2011 y
  municipios 1987-2003, «CEDA» en 1987-1991), 899 (mesas de 1999, ¡no es un
  municipio!) o fila sin código (2003). 2007 trae
  además una fila 9999 «NAVARRA» con el total, y 2015-2019 una fila «Total».
  1983 no separa el voto de los ausentes.
- Codmun 901-908 son municipios segregados con código INE propio (Barañáin desde
  1984, Berrioplano, Orkoien, ...), no agregados.
- Censo: censo + certificaciones de alta cuando la fuente las separa (Censo_Total en
  2015-2023, «Al Cen» en 2003, «Certificados A» en 2007).
- 2011 trae tras cada candidatura su porcentaje (columnas *_P, con coma decimal): se
  descartan. 2011 y los municipios 1983-1995 van separados por «;», y estos en Latin-1.
- Las sumas del fichero por municipios (con la fila CERA) son el resultado oficial;
  sin la fila CERA casan exactamente con las del fichero por mesas.
"""

import csv
import io
from datetime import date
from typing import Iterable

import requests

from ingestion.autonomicas import cache

COD_CCAA = "15"
SLUG = "navarra"
FUENTE = ("https://datosabiertos.navarra.es/es/dataset/"
          "resultados-de-las-elecciones-al-parlamento-de-navarra-agrupados-por-mesas-electorales")
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

_MESAS = "https://datosabiertos.navarra.es/dataset/be88dde7-330c-4b86-aa5c-480514608cbd/resource/"
_MUNIS = "https://datosabiertos.navarra.es/dataset/fa95fdf0-4aa1-4194-84b3-2779c9bc8e5e/resource/"

# nivel: "mesa" (sumada a sección) o "municipio".
# mun/dis/sec/mesa: columnas de municipio, distrito, sección y mesa (mesa="Mesa" en
# 2015-2023 lleva distrito y sección dentro); censo: columnas que se suman;
# tras: la columna a partir de la cual empiezan las candidaturas.
FORMATOS = {
    "A15198305": {"nivel": "municipio", "sep": ";",
                  "url": _MUNIS + "5a502d9d-d3f1-4f0f-bcc8-11e0620fe205/download/resultadosparlamentopormunicipio1983.csv",
                  "mun": "CODIGO", "censo": ["CENSO"], "blancos": "BLANCOS", "nulos": "NULOS", "tras": "A_CANDID"},
    "A15198706": {"nivel": "municipio", "sep": ";",
                  "url": _MUNIS + "198ccaea-2e5b-42bd-a2e2-1b061bebc665/download/resultadosparlamentopormunicipio1987.csv",
                  "mun": "CODIGO", "censo": ["CENSO"], "blancos": "BLANCOS", "nulos": "NULOS", "tras": "A_CANDID"},
    "A15199105": {"nivel": "municipio", "sep": ";",
                  "url": _MUNIS + "cb192f08-9c2a-4fe7-ba81-0db5075f0120/download/resultadosparlamentopormunicipio1991.csv",
                  "mun": "CODIGO", "censo": ["CENSO"], "blancos": "BLANCOS", "nulos": "NULOS", "tras": "A_CANDID"},
    "A15199505": {"nivel": "municipio", "sep": ";",
                  "url": _MUNIS + "ccad11ed-3d6d-4862-ace7-c712a3d1115a/download/resultadosparlamentopormunicipio1995.csv",
                  "mun": "CODIGO", "censo": ["CENSO"], "blancos": "BLANCOS", "nulos": "NULOS", "tras": "CANDIDATURAS"},
    "A15199906": {"nivel": "mesa", "sep": ",",
                  "url": _MESAS + "e5a78fc3-b93a-4cad-a2aa-cbae6f51ace7/download/resultadosparlamentopormesas_1999.csv",
                  "mun": "CÓDIGO", "dis": "DISTRITO", "sec": "SECCIÓN", "censo": ["CENSO ELECTORAL"], "cera": 899,
                  "blancos": "BLANCOS", "nulos": "NULOS", "tras": "A CAND"},
    "A15200305": {"nivel": "mesa", "sep": ",",
                  "url": _MESAS + "18d4381d-e165-472c-bf98-41a28780a0b0/download/resultadosparlamentopormesas_2003.csv",
                  "mun": "Codigo", "dis": "Distr", "sec": "Secc", "censo": ["Censo", "Al Cen"],
                  "blancos": "Blanco", "nulos": "Nulos", "tras": "Nulos"},
    "A15200705": {"nivel": "mesa", "sep": ",",
                  "url": _MESAS + "12169d64-afdd-4c6f-b5e2-5c9f724984bd/download/resultadosparlamentopormesas2007.csv",
                  "mun": "Codigo Municipio", "dis": "Distrito", "sec": "Seccion", "censo": ["Censo", "Certificados A"],
                  "blancos": "Votos Blanco", "nulos": "Votos Nulo", "tras": "Votos Nulo"},
    "A15201105": {"nivel": "mesa", "sep": ";",
                  "url": _MESAS + "09263838-3ee6-43ed-ac4d-40cc4c78e5ee/download/resultadosparlamentopormesas2011.csv",
                  "mun": "MUNICIPIO", "dis": "DISTRITO", "sec": "SECCION", "censo": ["CENSO"],
                  "blancos": "BLANCOS", "nulos": "NULOS", "tras": "NULOS"},
    "A15201505": {"nivel": "mesa", "sep": ",",
                  "url": _MESAS + "1d1e6459-d8b4-4281-bf0e-3791f1762b03/download/escrutinio_parlamento_mesas_2015.csv",
                  "mun": "Codmun", "mesa": "Mesa", "censo": ["Censo total"],
                  "blancos": "Votos_blancos", "nulos": "Votos_nulos", "tras": "Votos_blancos"},
    "A15201905": {"nivel": "mesa", "sep": ",",
                  "url": _MESAS + "2b4845fd-1c75-4aaf-b87c-5b4a2fc0b126/download/escrutinio_parlamento_mesas_2019.csv",
                  "mun": "Codmun", "mesa": "Mesa", "censo": ["Censo Total"],
                  "blancos": "Votos Blancos", "nulos": "Votos Nulos", "tras": "Votos Blancos"},
    "A15202305": {"nivel": "mesa", "sep": ",",
                  "url": _MESAS + "56b7ce53-4881-475a-8c79-82da43cb01ed/download/escrutinio_parlamento_mesas_2023.csv",
                  "mun": "Codmun", "mesa": "Mesa", "censo": ["Censo_Total"],
                  "blancos": "Votos_Blancos", "nulos": "Votos_Nulos", "tras": "Votos_Blancos"},
}

PROCESOS = [
    {"proceso": "A15198305", "fecha": date(1983, 5, 8), "eleccion": "Parlamento de Navarra, mayo de 1983"},
    {"proceso": "A15198706", "fecha": date(1987, 6, 10), "eleccion": "Parlamento de Navarra, junio de 1987"},
    {"proceso": "A15199105", "fecha": date(1991, 5, 26), "eleccion": "Parlamento de Navarra, mayo de 1991"},
    {"proceso": "A15199505", "fecha": date(1995, 5, 28), "eleccion": "Parlamento de Navarra, mayo de 1995"},
    {"proceso": "A15199906", "fecha": date(1999, 6, 13), "eleccion": "Parlamento de Navarra, junio de 1999"},
    {"proceso": "A15200305", "fecha": date(2003, 5, 25), "eleccion": "Parlamento de Navarra, mayo de 2003"},
    {"proceso": "A15200705", "fecha": date(2007, 5, 27), "eleccion": "Parlamento de Navarra, mayo de 2007"},
    {"proceso": "A15201105", "fecha": date(2011, 5, 22), "eleccion": "Parlamento de Navarra, mayo de 2011"},
    {"proceso": "A15201505", "fecha": date(2015, 5, 24), "eleccion": "Parlamento de Navarra, mayo de 2015"},
    {"proceso": "A15201905", "fecha": date(2019, 5, 26), "eleccion": "Parlamento de Navarra, mayo de 2019"},
    {"proceso": "A15202305", "fecha": date(2023, 5, 28), "eleccion": "Parlamento de Navarra, mayo de 2023"},
]

COD_CERA = 990  # 990 (2015-2023), 999 (CERA/CEDA), 9999 (total 2007): todo lo >= 990 fuera


def _entero(v) -> int:
    v = (v or "").strip()
    return int(v) if v else 0


def _filas(proceso: str) -> tuple[list[str], list[dict]]:
    """Filas del CSV (descargado una vez a la caché) y columnas de candidaturas."""
    fmt = FORMATOS[proceso]
    ruta = cache(SLUG) / f"{proceso}.csv"
    if not ruta.exists():
        r = requests.get(fmt["url"], headers=CABECERAS, timeout=120)
        r.raise_for_status()
        ruta.write_bytes(r.content)
    datos = ruta.read_bytes()
    try:
        texto = datos.decode("utf-8-sig")
    except UnicodeDecodeError:
        texto = datos.decode("latin-1")
    lector = csv.DictReader(io.StringIO(texto), delimiter=fmt["sep"])
    columnas = [c.strip() for c in (lector.fieldnames or [])]
    lector.fieldnames = columnas
    partidos = [c for c in columnas[columnas.index(fmt["tras"]) + 1:]
                if c and not c.endswith("_P")]
    return partidos, list(lector)


def _cod_mun(fila: dict, fmt: dict) -> int | None:
    """Código INE del municipio (sin provincia), o None si es CERA, total o vacío."""
    v = (fila.get(fmt["mun"]) or "").strip()
    if not v.isdigit() or int(v) >= COD_CERA or int(v) == fmt.get("cera"):
        return None
    return int(v)


def _seccion(fila: dict, fmt: dict) -> str | None:
    """CUSEC de la mesa, o None si es CERA o no tiene sección."""
    mun = _cod_mun(fila, fmt)
    if mun is None:
        return None
    if "mesa" in fmt:
        distrito, seccion, _mesa = fila[fmt["mesa"]].split("-")
    else:
        distrito, seccion = fila[fmt["dis"]], fila[fmt["sec"]]
    return f"31{mun:03d}{int(distrito):02d}{int(seccion):03d}"


def _agregado(proceso: str) -> dict[str, dict]:
    """Suma por sección (nivel mesa) o por municipio (nivel municipio)."""
    fmt = FORMATOS[proceso]
    partidos, filas = _filas(proceso)
    out: dict[str, dict] = {}
    for f in filas:
        if fmt["nivel"] == "mesa":
            cod = _seccion(f, fmt)
        else:
            mun = _cod_mun(f, fmt)
            cod = None if mun is None else f"31{mun:03d}"
        if cod is None:
            continue
        s = out.setdefault(cod, {"censo": 0, "votos_blanco": 0, "votos_nulos": 0,
                                 "votos_candidaturas": 0, "partidos": {}})
        s["censo"] += sum(_entero(f[c]) for c in fmt["censo"])
        s["votos_blanco"] += _entero(f[fmt["blancos"]])
        s["votos_nulos"] += _entero(f[fmt["nulos"]])
        for p in partidos:
            n = _entero(f[p])
            s["votos_candidaturas"] += n
            s["partidos"][p] = s["partidos"].get(p, 0) + n
    return out


def _nivel(proceso: str) -> str:
    return FORMATOS[proceso]["nivel"]


def secciones(proceso: str) -> Iterable[dict]:
    if _nivel(proceso) != "mesa":
        return []
    return [{"cod_seccion": cod, "censo": s["censo"], "votos_blanco": s["votos_blanco"],
             "votos_nulos": s["votos_nulos"], "votos_candidaturas": s["votos_candidaturas"]}
            for cod, s in sorted(_agregado(proceso).items())]


def votos(proceso: str) -> Iterable[dict]:
    if _nivel(proceso) != "mesa":
        return []
    return [{"cod_seccion": cod, "siglas": siglas, "votos": n}
            for cod, s in sorted(_agregado(proceso).items())
            for siglas, n in s["partidos"].items() if n]


def municipios(proceso: str) -> Iterable[dict]:
    if _nivel(proceso) != "municipio":
        return []
    return [{"cod_mun": cod, "censo": s["censo"], "votos_blanco": s["votos_blanco"],
             "votos_nulos": s["votos_nulos"], "votos_candidaturas": s["votos_candidaturas"]}
            for cod, s in sorted(_agregado(proceso).items())]


def votos_municipios(proceso: str) -> Iterable[dict]:
    if _nivel(proceso) != "municipio":
        return []
    return [{"cod_mun": cod, "siglas": siglas, "votos": n}
            for cod, s in sorted(_agregado(proceso).items())
            for siglas, n in s["partidos"].items() if n]


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
