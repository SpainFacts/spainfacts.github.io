"""Fuente dlt de la publicidad institucional y comercial de la Administración
General del Estado (tema `medios_publicidad`).

Comisión de Publicidad y Comunicación Institucional (La Moncloa), Ley 29/2005:
cada año el Gobierno aprueba un Plan (lo previsto) y, en junio del año
siguiente, un Informe (lo ejecutado). La Moncloa publica junto a los PDF unos
CSV con las series (ISO-8859-1, separador `;`, miles con punto y, a veces,
decimales con coma; varias tablas apiladas en el mismo fichero, cada una
precedida de un título en mayúsculas y de una fila de cabecera):

- Evolucion_Informes_Publicidad.csv: gasto ejecutado y nº de campañas,
  institucionales, comerciales y total, desde 2006.
- Evolucion_Planes_Publicidad.csv: lo planificado, desde 2007 (en 2016 no hubo
  plan: Gobierno en funciones).
- Invers_herram_campanas_instituc_InformesPublicidad.csv: inversión de las
  campañas institucionales por herramienta o tipo de medio (TV, radio, medios
  gráficos, digital, exterior, cine, RRPP, marketing, otras) desde 2006.
- Invers_herram_camp_instituc_y_comerciales_InformesPublicidad.csv: lo mismo
  sumando las comerciales (desde 2009, con «resto herramientas» agregado).
- Informe_<año>_ministerios.csv: campañas y gasto por ministerio (solo existe
  para 2025 de momento).

Los nombres de fichero no son estables: se localizan en la página índice y, si
no aparecen, se usan los conocidos.

Recursos (replace): pub_ejecutado, pub_planificado, pub_medios, pub_ministerios.
"""

import logging
import re

import dlt
import requests

log = logging.getLogger(__name__)

CABECERAS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/126.0 Safari/537.36"
}
RAIZ = "https://www.lamoncloa.gob.es"
INDICE = RAIZ + "/serviciosdeprensa/cpci/paginas/planeseinformes.aspx"
DOCS = RAIZ + "/serviciosdeprensa/cpci/Documents/"

CONOCIDOS = {
    "ejecutado": DOCS + "Evolucion_Informes_Publicidad.csv",
    "planificado": DOCS + "Evolucion_Planes_Publicidad.csv",
    "medios_institucional": DOCS + "Invers_herram_campanas_instituc_InformesPublicidad.csv",
    "medios_total": DOCS + "Invers_herram_camp_instituc_y_comerciales_InformesPublicidad.csv",
}
PATRONES = {
    "ejecutado": re.compile(r"evolucion_informes", re.I),
    "planificado": re.compile(r"evolucion_planes", re.I),
    "medios_institucional": re.compile(r"invers_herram_campanas_instituc", re.I),
    "medios_total": re.compile(r"invers_herram_camp_instituc_y_comerciales", re.I),
}
PATRON_MINISTERIOS = re.compile(r"Informe_(\d{4})_ministerios\.csv$", re.I)

# Título de bloque -> tipo de campaña
TIPOS = {
    "CAMPAÑAS INSTITUCIONALES": "institucional",
    "CAMPAÑAS COMERCIALES": "comercial",
    "CAMPAÑAS INSTITUCIONALES + COMERCIALES": "total",
    "INSTITUCIONALES + COMERCIALES": "total",
}

# Título de bloque de herramientas -> medio normalizado
MEDIOS = {
    "TELEVISIÓN": "television",
    "RADIO": "radio",
    "MEDIOS GRÁFICOS": "medios_graficos",
    "DIGITAL": "digital",
    "EXTERIOR": "exterior",
    "CINE": "cine",
    "RELACIONES PÚBLICAS": "relaciones_publicas",
    "MARKETING": "marketing",
    "OTRAS HERRAMIENTAS": "otras",
    "RESTO HERRAMIENTAS": "resto",
    "TOTAL HERRAMIENTAS": "total_herramientas",
}


def _get(url: str) -> bytes:
    r = requests.get(url, headers=CABECERAS, timeout=120)
    r.raise_for_status()
    return r.content


def _enlaces() -> dict:
    """URL de cada CSV sacada del índice; si falla, las conocidas."""
    urls = dict(CONOCIDOS)
    urls_min = {}
    try:
        html = _get(INDICE).decode("utf-8", errors="replace")
        hrefs = set(re.findall(r'href="([^"]+\.csv)"', html, re.I))
        for href in hrefs:
            completo = href if href.startswith("http") else RAIZ + href
            nombre = completo.rsplit("/", 1)[-1]
            for clave, patron in PATRONES.items():
                # el patrón institucional también casaría con «..._y_comerciales» si no se excluye
                if patron.search(nombre) and not (clave == "medios_institucional" and "comerciales" in nombre.lower()):
                    urls[clave] = completo
            m = PATRON_MINISTERIOS.search(nombre)
            if m:
                urls_min[int(m.group(1))] = completo
    except Exception as e:  # noqa: BLE001
        log.warning("No se pudo leer el índice de La Moncloa (%s); se usan las URL conocidas", e)
    if not urls_min:
        urls_min[2025] = DOCS + "Informe_2025_ministerios.csv"
    return urls, urls_min


def _lineas(contenido: bytes) -> list[list[str]]:
    texto = contenido.decode("latin-1")
    return [[c.strip() for c in linea.split(";")] for linea in texto.splitlines()]


def _numero(s: str):
    s = (s or "").strip().replace("€", "").replace(" ", "")
    if not s or s.endswith("%"):
        return None
    s = s.replace(".", "").replace(",", ".")
    try:
        return float(s)
    except ValueError:
        return None


def _anio(s: str):
    m = re.fullmatch(r"(?:TOTAL\s+)?(\d{4})", (s or "").strip(), re.I)
    return int(m.group(1)) if m else None


def _bloques(contenido: bytes):
    """Recorre las tablas apiladas: devuelve (título del bloque, fila) para cada fila de datos."""
    titulo = None
    for celdas in _lineas(contenido):
        no_vacias = [c for c in celdas if c]
        if not no_vacias:
            continue
        primera = celdas[0]
        if len(no_vacias) == 1 and _anio(primera) is None:
            # título de bloque (o nota al pie con asterisco, que se ignora)
            if not primera.startswith("*"):
                titulo = primera.upper().rstrip(".").strip()
            continue
        if primera.upper() in ("INFORME", "PLAN", "MINISTERIO"):
            continue  # fila de cabecera
        yield titulo, celdas


def _serie_tipos(url: str, clave: str):
    """Evolución de informes o planes: anio, tipo, importe_eur, campanas."""
    for titulo, celdas in _bloques(_get(url)):
        tipo = TIPOS.get(titulo or "")
        anio = _anio(celdas[0])
        if tipo is None or anio is None:
            continue
        importe = _numero(celdas[1]) if len(celdas) > 1 else None
        campanas = _numero(celdas[2]) if len(celdas) > 2 else None
        yield {
            "anio": anio,
            "tipo": tipo,
            "importe_eur": importe,
            "campanas": int(campanas) if campanas is not None else None,
            "fichero": url.rsplit("/", 1)[-1],
        }


@dlt.source(name="medios_publicidad")
def medios_publicidad():
    urls, urls_min = _enlaces()

    @dlt.resource(name="pub_ejecutado", write_disposition="replace")
    def pub_ejecutado():
        yield from _serie_tipos(urls["ejecutado"], "ejecutado")

    @dlt.resource(name="pub_planificado", write_disposition="replace")
    def pub_planificado():
        yield from _serie_tipos(urls["planificado"], "planificado")

    @dlt.resource(name="pub_medios", write_disposition="replace")
    def pub_medios():
        """Inversión por herramienta (tipo de medio). ambito = institucional |
        institucional_comercial. medio 'total_campanas' = coste total (con
        producción y evaluación); se omite el bloque de porcentajes."""
        for ambito, clave in (("institucional", "medios_institucional"), ("institucional_comercial", "medios_total")):
            for titulo, celdas in _bloques(_get(urls[clave])):
                if not titulo:
                    continue
                if titulo.startswith("TOTAL CAMPAÑAS"):
                    medio, etiqueta = "total_campanas", "TOTAL CAMPAÑAS"
                elif titulo in MEDIOS:
                    medio, etiqueta = MEDIOS[titulo], titulo
                else:
                    continue  # porcentaje, títulos generales
                anio = _anio(celdas[0])
                importe = _numero(celdas[1]) if len(celdas) > 1 else None
                if anio is None or importe is None:
                    continue
                yield {
                    "anio": anio,
                    "ambito": ambito,
                    "medio": medio,
                    "medio_etiqueta": etiqueta,
                    "importe_eur": importe,
                    "fichero": urls[clave].rsplit("/", 1)[-1],
                }

    @dlt.resource(name="pub_ministerios", write_disposition="replace")
    def pub_ministerios():
        for anio, url in sorted(urls_min.items()):
            try:
                contenido = _get(url)
            except requests.HTTPError as e:
                log.warning("Sin CSV por ministerios para %s: %s", anio, e)
                continue
            for titulo, celdas in _bloques(contenido):
                tipo = TIPOS.get(titulo or "")
                if tipo is None or len(celdas) < 3:
                    continue
                ministerio = celdas[0].strip()
                if ministerio.upper() == "TOTAL":
                    ministerio = "TOTAL"
                campanas = _numero(celdas[1])
                yield {
                    "anio": anio,
                    "tipo": tipo,
                    "ministerio": ministerio,
                    "campanas": int(campanas) if campanas is not None else None,
                    "importe_eur": _numero(celdas[2]),
                    "fichero": url.rsplit("/", 1)[-1],
                }

    return pub_ejecutado, pub_planificado, pub_medios, pub_ministerios
