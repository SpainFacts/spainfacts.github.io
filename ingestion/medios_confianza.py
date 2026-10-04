"""Fuente dlt de la confianza en las noticias y en los medios (tema `medios_confianza`).

Dos organismos:

1. Reuters Institute for the Study of Journalism (Universidad de Oxford),
   Digital News Report (DNR). Encuesta online anual de YouGov (enero-febrero,
   ~2.000 internautas por país; en España con la Universidad de Navarra).
   No publica microdatos ni un CSV por país, pero cada página de país del
   informe web (https://reutersinstitute.politics.ox.ac.uk/digital-news-report/<año>/<país>)
   trae:
     - unas «tarjetas» con cifras clave (pagar por noticias online, evitar las
       noticias, confianza general...), en HTML, y
     - gráficos Datawrapper incrustados cuyo CSV se descarga en
       https://datawrapper.dwcdn.net/<id>/<versión>/dataset.csv (los antiguos
       redirigen con meta-refresh a la versión vigente; si no hay dataset.csv,
       los datos van en el `chartData` del HTML del gráfico).
   Se leen todas las páginas de país desde 2021 (formato actual) con sus
   tarjetas y el gráfico «Overall trust score» (serie desde 2015), todos los
   gráficos de la página de España desde 2017 (archivo antiguo incluido) y, del
   resumen ejecutivo de cada año, los gráficos de confianza, pago, evitación,
   interés y preocupación por lo falso. Licencia: el DNR se publica con
   licencia Creative Commons CC BY 4.0 (se cita la fuente).

2. Comisión Europea, Eurobarómetro Standard: pregunta «How much trust you have
   in certain types of media» (prensa escrita, radio, televisión, internet,
   redes sociales online; tiende a confiar / no confiar / NS), en las oleadas
   que la incluyen (normalmente la de otoño/invierno). Los datos por país están
   en el «Data annex» en PDF de cada oleada, que se descarga de la API pública
   del portal (https://europa.eu/eurobarometer/api/, deliverable/download/file).
   El texto se extrae con pypdfium2 (sale una fila por país en orden; ojo:
   `pdftotext -layout` desplaza las etiquetas de país una fila). Oleadas con la
   pregunta: 80 (2013, sin prensa ni redes), 82-96 pares y 102 (sin redes) y
   104; la 98 y la 100 no la traen. Licencia: reutilización libre con cita
   (Decisión 2011/833/UE).

La carga completa tarda unos 20 minutos (~330 páginas del DNR, ~400 gráficos
Datawrapper y ~25 PDF del Eurobarómetro).

Recursos (replace): dnr_tarjetas, dnr_graficos, eurobarometro_confianza_medios.
"""

import io
import logging
import re
import time
from datetime import date

import dlt
import requests

log = logging.getLogger(__name__)

UA = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/126.0 Safari/537.36"
}
RISJ = "https://reutersinstitute.politics.ox.ac.uk"
DW = "https://datawrapper.dwcdn.net"
EB_API = "https://europa.eu/eurobarometer/api/"

PRIMER_ANIO_ACTUAL = 2021  # desde 2021 las páginas de país tienen el formato actual
# Archivo antiguo de la página de España (WordPress migrado)
ESPANA_ARCHIVO = {a: f"{RISJ}/digital-news-report/archive/survey/{a}/spain-{a}/index.html" for a in (2017, 2018, 2019, 2020)}

# Gráficos del resumen ejecutivo que interesan (título, sin distinguir mayúsculas)
TITULOS_RESUMEN = re.compile(
    r"trust most news most of the time|concerned about (what is real and (what is )?fake|fake news)"
    r"|paid for (any )?online news|paying for (online )?news|avoid the news|interested in (the )?news",
    re.I,
)


def _get(url, **kw):
    for intento in range(4):
        try:
            r = requests.get(url, headers=UA, timeout=120, **kw)
            if r.status_code in (429, 500, 502, 503, 504):
                raise requests.HTTPError(str(r.status_code))
            return r
        except (requests.RequestException,) as e:
            if intento == 3:
                raise
            log.warning("Reintento %s (%s)", url, e)
            time.sleep(5 * (intento + 1))


# ---------------------------------------------------------------- Datawrapper

def _num(txt):
    """'55,97' -> 55.97; '32% (+14)' -> 32.0; '' -> None."""
    if txt is None:
        return None
    m = re.search(r"-?\d+(?:[.,]\d+)?", str(txt))
    if not m:
        return None
    return float(m.group(0).replace(",", "."))


def _csv_datawrapper(chart):
    """Devuelve (url_final, filas) del gráfico `chart` ('id' o 'id/versión')."""
    url = f"{DW}/{chart.strip('/')}/"
    r = None
    for _ in range(6):
        r = _get(url)
        m = re.search(r'http-equiv="REFRESH" content="0; url=([^"]+)"', r.text, re.I)
        if not m:
            break
        sig = m.group(1)
        url = sig if sig.startswith("http") else DW + sig
    texto = None
    for nombre in ("dataset.csv", "data.csv"):
        r2 = _get(url + nombre)
        if r2.status_code == 200 and "<html" not in r2.text[:300].lower():
            r2.encoding = "utf-8"
            texto = r2.text
            break
    if texto is None and r is not None:
        m = re.search(r'chartData\\?"\s*:\s*\\?"(.*?)(?<!\\)\\?"\s*,\s*\\?"', r.text, re.S)
        if m:
            texto = m.group(1)
            # deshace el escapado JSON (una o dos capas)
            for _ in range(3):
                texto = texto.replace('\\\\', '\\').replace('\\"', '"').replace('\\r\\n', '\n').replace('\\n', '\n').replace('\\t', '\t')
            texto = re.sub(r"\\u([0-9a-fA-F]{4})", lambda x: chr(int(x.group(1), 16)), texto)
    if not texto:
        return url, []
    texto = texto.lstrip("﻿")
    lineas = [l for l in texto.replace("\r\n", "\n").split("\n")]
    cab = lineas[0] if lineas else ""
    sep = max(["\t", ";", ","], key=lambda s: cab.count(s))
    import csv
    filas = list(csv.reader(io.StringIO("\n".join(lineas)), delimiter=sep))
    return url, filas


def _largo(filas):
    """Pasa una tabla (cabecera + filas) a formato largo: (fila, etiqueta, columna, texto, valor)."""
    if not filas:
        return
    cab = [c.strip() for c in filas[0]]
    for i, f in enumerate(filas[1:], start=1):
        if not f or not f[0].strip():
            continue
        etiqueta = f[0].strip()
        for j, celda in enumerate(f[1:], start=1):
            col = cab[j] if j < len(cab) else ""
            celda = celda.strip()
            if not col or not celda:
                continue
            yield i, etiqueta, col, celda, _num(celda)


def _iframes(html):
    """[(titulo, chart)] de los iframes Datawrapper de una página (cualquier orden de atributos)."""
    res = []
    for tag in re.findall(r"<iframe[^>]+>", html, re.I):
        m = re.search(r'src="https://datawrapper\.dwcdn\.net/([^"]+)"', tag)
        if not m:
            continue
        t = re.search(r'title="([^"]*)"', tag)
        res.append(((t.group(1) if t else "").strip(), m.group(1).strip("/")))
    return res


def _tarjetas(html):
    """Tarjetas de cifras de la página de país: [(titulo, valor, resto)]."""
    res = []
    for titulo, cuerpo in re.findall(r"<h2>([^<]+)</h2>\s*</div>\s*<div[^>]*>(.*?)</div>", html, re.S):
        if "dnr-h1" not in cuerpo:
            continue
        partes = [p.strip() for p in re.findall(r">([^<>]+)<", cuerpo) if p.strip()]
        if not partes:
            continue
        res.append((titulo.strip(), partes[0], " ".join(partes[1:])))
    return res


def _paises(anio):
    """Slugs de las páginas de país del año (de la portada del informe)."""
    html = _get(f"{RISJ}/digital-news-report/{anio}").text
    noes = {"dnr-executive-summary", "methodology", "country-and-market-data", "podcast-and-launch-videos"}
    slugs = []
    for s in re.findall(rf'href="(?:{re.escape(RISJ)})?/digital-news-report/{anio}/([a-z-]+)"', html):
        if s in noes or s in slugs:
            continue
        slugs.append(s)
    return slugs


def _paginas_pais():
    hoy = date.today().year
    for anio in range(PRIMER_ANIO_ACTUAL, hoy + 1):
        try:
            slugs = _paises(anio)
        except Exception as e:  # noqa: BLE001
            log.warning("DNR %s: sin portada (%s)", anio, e)
            continue
        for slug in slugs:
            url = f"{RISJ}/digital-news-report/{anio}/{slug}"
            r = _get(url)
            if r.status_code != 200 or "dnr-h1" not in r.text:
                continue  # es un capítulo, no una página de país
            yield anio, slug, url, r.text
    for anio, url in ESPANA_ARCHIVO.items():
        r = _get(url)
        if r.status_code == 200:
            yield anio, "spain", url, r.text


_CACHE = {}


def _paginas():
    """Páginas de país descargadas una sola vez al día (las usan dos recursos)."""
    clave = date.today().isoformat()
    if clave not in _CACHE:
        _CACHE.clear()
        _CACHE[clave] = list(_paginas_pais())
    return _CACHE[clave]


@dlt.resource(name="dnr_tarjetas", write_disposition="replace")
def _recurso_tarjetas():
    for anio, slug, url, html in _paginas():
        for titulo, valor, resto in _tarjetas(html):
            yield {"anio_informe": anio, "pais_slug": slug, "indicador": titulo,
                   "valor_texto": valor, "valor": _num(valor), "detalle": resto, "url": url}


def _graficos_de(anio, slug, url, html, solo):
    for titulo, chart in _iframes(html):
        if solo and not solo.search(titulo):
            continue
        try:
            url_dw, filas = _csv_datawrapper(chart)
        except Exception as e:  # noqa: BLE001
            log.warning("Datawrapper %s: %s", chart, e)
            continue
        for fila, etiqueta, col, texto, valor in _largo(filas):
            yield {"anio_informe": anio, "pais_slug": slug, "grafico": chart.split("/")[0],
                   "titulo": titulo, "fila": fila, "etiqueta": etiqueta, "columna": col,
                   "valor_texto": texto, "valor": valor, "url": url, "url_datos": url_dw}


@dlt.resource(name="dnr_graficos", write_disposition="replace")
def _recurso_graficos():
    confianza = re.compile(r"overall trust score", re.I)
    for anio, slug, url, html in _paginas():
        # España: todos los gráficos; resto: solo la serie de confianza general
        yield from _graficos_de(anio, slug, url, html, None if slug == "spain" else confianza)
    hoy = date.today().year
    for anio in range(PRIMER_ANIO_ACTUAL, hoy + 1):
        url = f"{RISJ}/digital-news-report/{anio}/dnr-executive-summary"
        r = _get(url)
        if r.status_code != 200:
            continue
        yield from _graficos_de(anio, "resumen", url, r.text, TITULOS_RESUMEN)


# ---------------------------------------------------------------- Eurobarómetro

# Etiqueta de medio tal como aparece, sola en su línea, en cada página del anexo
MEDIOS_EB = [
    ("prensa", re.compile(r"^\s*(the\s+)?written press\b", re.I)),
    ("radio", re.compile(r"^\s*radio\b", re.I)),
    ("television", re.compile(r"^\s*television\b|^\s*tv\b", re.I)),
    ("internet", re.compile(r"^\s*(the\s+)?internet\b|^\s*websites\b", re.I)),
    ("redes_sociales", re.compile(r"^\s*online social networks\b|^\s*social networks\b", re.I)),
]
PREGUNTA_EB = re.compile(r"trust\s+(you\s+have|do\s+you\s+have)\s+in\s+certain\s+(types\s+of\s+)?media", re.I)
PAISES_EB = {"EU27", "EU28", "BE", "BG", "CZ", "DK", "DE", "EE", "IE", "EL", "ES", "FR", "HR", "IT", "CY", "LV",
             "LT", "LU", "HU", "MT", "NL", "AT", "PL", "PT", "RO", "SI", "SK", "FI", "SE", "UK"}
FILA_EB = re.compile(r"^\s*(EU\s?2[78]|[A-Z]{2})\s+((?:[-+]?\d+\s*)+)$")


def _oleadas_eb(desde=78):
    """Oleadas Standard con su anexo de datos en inglés: (num, referencia, inicio campo, id entregable)."""
    ids = set()
    for pagina in range(1, 30):
        x = requests.post(EB_API + "survey/search", json={"keywords": "Standard Eurobarometer", "page": pagina, "size": 100},
                          headers=UA, timeout=120).json()
        res = x.get("results") or []
        if not res:
            break
        for r in res:
            if "ST" in (r.get("metadata") or {}).get("instrument", []):
                ids.add(r["groupById"])
    for i in sorted(ids, key=int):
        d = _get(EB_API + "survey/get/one", params={"id": i}).json()
        m = re.match(r"STD(\d+)", d.get("reference") or "")
        if not m or int(m.group(1)) < desde:
            continue
        anexos = [dl for dl in d.get("deliverables") or []
                  if (dl["type"]["code"] == "DATANX" or re.search(r"anx|annex", dl["name"], re.I))
                  and not re.search(r"_(fr|de)\b|_(fr|de)\.pdf|full|vol[12]|keytrends|public_opinion", dl["name"].lower())]
        if anexos:
            yield int(m.group(1)), d["reference"], d.get("fieldworkStartDate"), anexos[0]["id"], anexos[0]["name"]


def _parsear_anexo(contenido):
    """Filas (medio, pais, confia, no_confia, ns) de la pregunta de confianza en los medios.

    El texto de cada página (pypdfium2) sale con una fila por país en orden:
    «ES 47 14 47 -13 6 -1» = confía, dif., no confía, dif., NS, dif. (la última
    diferencia a veces falta). La etiqueta del medio va sola en una línea
    («The written press (%)», «Radio»...). Solo se aceptan filas cuyos tres
    porcentajes suman 100 ± 2 y medios con al menos 20 países.
    """
    import pypdfium2

    doc = pypdfium2.PdfDocument(contenido)
    filas = {}
    for i in range(len(doc)):
        t = doc[i].get_textpage().get_text_range()
        if not PREGUNTA_EB.search(t):
            continue
        lineas = [l.strip() for l in t.replace("\r", "").split("\n")]
        medios = {m for l in lineas for m, rx in MEDIOS_EB if rx.search(re.sub(r"\(%\)", "", l)) and len(l) < 40}
        if len(medios) != 1:
            continue  # página sin medio claro (instituciones) o con varios
        medio = medios.pop()
        for l in lineas:
            m = FILA_EB.match(l)
            if not m:
                continue
            pais = m.group(1).replace(" ", "")
            if pais not in PAISES_EB or (medio, pais) in filas:
                continue
            nums = [float(x) for x in m.group(2).split()]
            if len(nums) >= 5:
                confia, no_confia, ns = nums[0], nums[2], nums[4]
            elif len(nums) == 3:
                confia, no_confia, ns = nums
            else:
                continue
            if not (98 <= confia + no_confia + ns <= 102) or min(confia, no_confia, ns) < 0:
                continue
            filas[(medio, pais)] = (confia, no_confia, ns)
    doc.close()
    cuenta = {}
    for (medio, _pais) in filas:
        cuenta[medio] = cuenta.get(medio, 0) + 1
    for (medio, pais), (c, n, d) in filas.items():
        if cuenta[medio] >= 20:
            yield medio, pais, c, n, d


@dlt.resource(name="eurobarometro_confianza_medios", write_disposition="replace")
def _recurso_eurobarometro():
    for num, ref, inicio, entregable, nombre in _oleadas_eb():
        url = f"{EB_API}deliverable/download/file?deliverableId={entregable}"
        try:
            r = _get(url)
            if r.status_code != 200 or not r.content.startswith(b"%PDF"):
                log.warning("Eurobarómetro %s: anexo no descargable", ref)
                continue
            filas = list(_parsear_anexo(r.content))
        except Exception as e:  # noqa: BLE001
            log.warning("Eurobarómetro %s: %s", ref, e)
            continue
        log.info("Eurobarómetro %s: %d filas de confianza en medios", ref, len(filas))
        for medio, pais, confia, no_confia, ns in filas:
            yield {"oleada": num, "referencia": ref, "inicio_campo": inicio, "medio": medio, "pais": pais,
                   "confia": confia, "no_confia": no_confia, "ns_nc": ns, "anexo": nombre, "url": url}


@dlt.source(name="medios_confianza")
def medios_confianza(eurobarometro: bool = True):
    recursos = [_recurso_tarjetas(), _recurso_graficos()]
    if eurobarometro:
        recursos.append(_recurso_eurobarometro())
    return recursos
