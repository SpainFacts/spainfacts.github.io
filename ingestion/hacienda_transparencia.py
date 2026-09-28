"""Fuente dlt para dos indicadores oficiales de transparencia municipal del
Ministerio de Hacienda: la retención de la participación en los tributos del
Estado por no remitir información (art. 36 de la Ley 2/2011) y el periodo
medio de pago a proveedores (PMP).

1) Retenciones del art. 36 de la Ley 2/2011 (PDF mensual)
   La Secretaría General de Financiación Autonómica y Local publica cada mes en
   la Oficina Virtual de Entidades Locales (OVEELL) la relación de ayuntamientos
   y diputaciones a los que se retienen las entregas a cuenta de la PIE:
     - por no remitir la liquidación del presupuesto (art. 36.1 Ley 2/2011 y
       art. 193.5 TRLRHL): desde junio y hasta que se regulariza;
     - desde 2022, por no remitir el presupuesto del ejercicio antes del 1 de
       julio (retención de septiembre a diciembre) y las líneas fundamentales
       del presupuesto del año siguiente antes del 15 de septiembre (retención
       desde diciembre), DA 87ª de la Ley 22/2021.
   Cada lista mensual es un STOCK: quién sigue retenido ese mes.
   Los enlaces se leen de la página de noticias de la OVEELL; los nombres de
   fichero cambian con los años (Retencion art_36 2016_11.pdf,
   retencion_art_36_2019_01.pdf, retencion-art-36-2026-09.pdf...).
   Dos formatos:
     - desde noviembre de 2022, una tabla con Idente, código y nombre de
       comunidad, código y nombre de provincia, "resto código" (009AA000) y
       nombre; INE = provincia + 3 primeros dígitos del resto. Hay tres
       secciones (liquidación / presupuesto / líneas fundamentales) y las
       páginas de continuación no repiten el título. En diciembre de 2022 el
       Idente va pegado al código de comunidad (266401 = 2664 + 01);
     - hasta octubre de 2022, solo nombres agrupados por comunidad y provincia
       (sin código): el cruce con el INE por nombre se hace en dbt.
   "(*)" = retenido por tener pendiente la información de una entidad o
   sociedad dependiente.

2) Importes retenidos (Excel mensual de entregas a cuenta de la PIE)
   entrega-a-cuenta-mensual-AAAA-MM.xlsx (antes .xls con otros nombres), hojas
   "Municipios - Cesión" y "Municipios - Sistema General": C. Prov + C. Corp
   = código INE y la columna "Retención Artículo 36 Ley 2/2011" = euros
   retenidos ese mes.

3) Periodo medio de pago (PMP_NET)
   serviciostelematicosext.hacienda.gob.es/sgcief/pmp_net: un Excel por
   trimestre (periodo=Marzo/Junio/Septiembre/Diciembre, fichero2 = entidades
   locales) con una fila por entidad que ha comunicado su PMP (hojas Cesión y
   Variables). Código de entidad 01-04-006-A-A-000 = comunidad (Hacienda) -
   provincia - municipio - tipo. Quien no aparece no lo ha comunicado (RD
   635/2014 y art. 16.8 de la Orden HAP/2105/2012). La hoja "Desagregado por
   tipo" da los firmados y existentes por tipo de entidad. Si el fichero no
   existe el servidor devuelve una página HTML de ~7,8 kB.

Los ficheros originales se guardan en data/hacienda_cache/ (no versionado):
los históricos no cambian y solo se vuelven a pedir los recientes.

Recursos (carga completa "replace"):
  pie_retenciones           una fila por entidad retenida, mes y sección
  pie_retenciones_importes  euros retenidos por ayuntamiento y mes (> 0)
  pmp_entidades             PMP comunicado por entidad y trimestre
  pmp_resumen_tipos         entidades firmadas / existentes por tipo y trimestre
"""

import io
import logging
import re
import time
import zlib
from datetime import date, datetime, timedelta
from html import unescape
from pathlib import Path
from urllib.parse import quote, unquote, urljoin

import dlt
import requests

REPO_ROOT = Path(__file__).resolve().parent.parent
CACHE = REPO_ROOT / "data" / "hacienda_cache"

log = logging.getLogger(__name__)

HACIENDA = "https://www.hacienda.gob.es"
NOTICIAS_OVEELL = (
    HACIENDA + "/es-ES/Areas%20Tematicas/Administracion%20Electronica/OVEELL/Paginas/Noticias.aspx"
)
INFO_EELL = HACIENDA + "/cdi/sist%20financiacion%20y%20deuda/informacioneells"
PMP_URL = (
    "https://serviciostelematicosext.hacienda.gob.es/sgcief/pmp_net/aspx/consulta/descarga.aspx"
    "?ejercicio={anio}&periodo={periodo}&tipoPublicacion=2&fichero=fichero2"
)
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) SpainFacts/1.0 (+https://spainfacts.github.io)"}
PAUSA_S = 1.0
PRIMER_MES_RETENCIONES = date(2016, 10, 1)
PRIMER_ANIO_PMP = 2014
PERIODOS_PMP = {1: "Marzo", 2: "Junio", 3: "Septiembre", 4: "Diciembre"}
MESES = {
    "enero": 1, "febrero": 2, "marzo": 3, "abril": 4, "mayo": 5, "junio": 6, "julio": 7,
    "agosto": 8, "septiembre": 9, "octubre": 10, "noviembre": 11, "diciembre": 12,
}

_ultima_peticion = 0.0


# ---------------------------------------------------------------------------
# Descarga con reintentos, pausa entre peticiones y caché en disco
# ---------------------------------------------------------------------------

def _get(url: str, intentos: int = 4) -> requests.Response | None:
    """GET educado: una petición por segundo y reintentos con espera creciente.
    Devuelve None si el recurso no existe (404)."""
    global _ultima_peticion
    for intento in range(intentos):
        falta = PAUSA_S - (time.monotonic() - _ultima_peticion)
        if falta > 0:
            time.sleep(falta)
        _ultima_peticion = time.monotonic()
        try:
            r = requests.get(url, headers=UA, timeout=120)
        except requests.RequestException as e:
            log.warning("Error de red en %s (%s), intento %s", url, e, intento + 1)
            time.sleep(5 * 2**intento)
            continue
        if r.status_code == 404:
            return None
        if r.status_code >= 500 or r.status_code == 429:
            time.sleep(5 * 2**intento)
            continue
        r.raise_for_status()
        return r
    raise RuntimeError(f"No se pudo descargar {url}")


def _es_fichero(contenido: bytes) -> bool:
    # PDF, xlsx (zip) o xls (OLE2); lo demás es una página de error HTML
    return contenido[:4] in (b"%PDF", b"PK\x03\x04", b"\xd0\xcf\x11\xe0")


def _descarga(url: str, destino: Path, reciente: bool) -> bytes | None:
    """Devuelve el fichero (de la caché si existe). Los ficheros "recientes" se
    vuelven a pedir si la copia tiene más de 5 días. Las ausencias de periodos
    antiguos se recuerdan con un fichero .missing para no reintentarlas."""
    falta = destino.with_suffix(destino.suffix + ".missing")
    if destino.exists():
        edad = datetime.now() - datetime.fromtimestamp(destino.stat().st_mtime)
        if not reciente or edad < timedelta(days=5):
            return destino.read_bytes()
    if falta.exists() and not reciente:
        return None
    r = _get(url)
    if r is None or not _es_fichero(r.content):
        if not reciente:
            falta.parent.mkdir(parents=True, exist_ok=True)
            falta.touch()
        return destino.read_bytes() if destino.exists() else None
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_bytes(r.content)
    return r.content


def _meses_desde(inicio: date, hoy: date) -> list[date]:
    meses, m = [], inicio
    while m <= hoy:
        meses.append(m)
        m = date(m.year + (m.month == 12), m.month % 12 + 1, 1)
    return meses


# ---------------------------------------------------------------------------
# Enlaces de la página de noticias de la OVEELL
# ---------------------------------------------------------------------------

def _enlaces_oveell() -> list[str]:
    r = _get(NOTICIAS_OVEELL)
    if r is None:
        return []
    hrefs = re.findall(r'href="([^"]+\.(?:pdf|xlsx?))"', r.text, flags=re.I)
    urls = []
    for h in hrefs:
        h = unescape(h).strip()
        h = re.sub(r"^https?://www\.(minhafp|hacienda)\.gob\.es", HACIENDA, h, flags=re.I)
        urls.append(urljoin(HACIENDA + "/", h.replace(" ", "%20")))
    return list(dict.fromkeys(urls))


def _mes_de_url(url: str) -> date | None:
    nombre = unquote(url.rsplit("/", 1)[-1]).lower()
    m = re.search(r"(20\d\d)[ _\-]+(\d{1,2})\.(?:pdf|xlsx?)$", nombre)
    if m:
        return date(int(m.group(1)), int(m.group(2)), 1)
    m = re.search(r"(" + "|".join(MESES) + r")[ _\-]*(20\d\d)", nombre)
    if m:
        return date(int(m.group(2)), MESES[m.group(1)], 1)
    return None


def _urls_retenciones(enlaces: list[str], hoy: date) -> dict[date, str]:
    urls: dict[date, str] = {}
    for u in enlaces:
        n = unquote(u).lower()
        if "reten" in n and "36" in n and n.endswith(".pdf") and "/fondos/" not in n:
            mes = _mes_de_url(u)
            if mes and mes not in urls:
                urls[mes] = u
    # Meses recientes que aún no estén enlazados en la página: patrón actual
    for mes in _meses_desde(date(2021, 1, 1), hoy):
        urls.setdefault(mes, f"{INFO_EELL}/{mes.year}/retencion-art-36-{mes.year}-{mes.month:02d}.pdf")
    return dict(sorted(urls.items()))


def _urls_entregas(enlaces: list[str], mes: date) -> list[str]:
    a, m = mes.year, mes.month
    candidatos = [
        u for u in enlaces
        if "entrega" in unquote(u).lower() and "mensual" in unquote(u).lower() and _mes_de_url(u) == mes
    ]
    for base in (INFO_EELL, HACIENDA + "/documentacion/publico/cdi/sist%20financiacion%20y%20deuda/informacioneells"):
        candidatos += [
            f"{base}/{a}/entrega-a-cuenta-mensual-{a}-{m:02d}.xlsx",
            f"{base}/{a}/entrega-a-cuenta-mensual-{a}-{m:02d}.xls",
            f"{base}/{a}/entregas_a_cuenta_mensual_{a}_{m:02d}.xls",
            f"{base}/{a}/Entregas_a_cuenta_mensual_{a}_{m:02d}.xls",
            f"{base}/{a}/Entregas_a_cuenta_mensual_{a}_{m:02d}.xlsx",
            f"{base}/{a}/" + quote(f"Entrega a cuenta mensual {a}_{m:02d}.xls"),
            f"{base}/{a}/" + quote(f"Entregas a cuenta mensual {a}_{m:02d}.xls"),
        ]
        if a >= 2021:
            break  # desde 2021 solo se usa el patrón actual
    return list(dict.fromkeys(candidatos))


# ---------------------------------------------------------------------------
# PDF de retenciones
# ---------------------------------------------------------------------------

# Formato con códigos (noviembre de 2022 en adelante)
_FILA = re.compile(
    r"^(?P<idente>\d+) (?:(?P<ccaa>\d{2}) )?(?:(?P<ccaa_nombre>\D+?) )?(?P<prov>\d{2}) (?P<prov_nombre>\D+?) "
    r"(?P<resto>\d{3}[A-Z]{2}\d{3})(?: (?P<nombre>.*))?$"
)
_CABECERA_TABLA = re.compile(r"^(C.digo|Idente|Nombre|Aut.noma|Comunidad de la|provincia)\b")


def _seccion(cabecera: str) -> str | None:
    c = re.sub(r"\s+", " ", cabecera).lower()
    if "neas fundamentales" in c:
        return "lineas_fundamentales"
    if "remisión de los presupuestos" in c or "remision de los presupuestos" in c:
        return "presupuesto"
    if "liquidaci" in c:
        return "liquidacion"
    return None


def _parsea_con_codigos(paginas: list[str]):
    seccion, ejercicio = None, None
    for texto in paginas:
        lineas = [ln.strip() for ln in texto.split("\n")]
        # Título de la página = líneas hasta la cabecera de la tabla o la primera fila
        titulo = []
        for ln in lineas:
            if _CABECERA_TABLA.match(ln) or _FILA.match(ln) or ln.startswith("(*) Retenci"):
                break
            titulo.append(ln)
        cab = " ".join(titulo)
        # La portada enumera todas las secciones y no tiene filas: se ignora su título
        num_titulos = len(re.findall(r"Relaci.n de ayuntamientos", cab))
        if num_titulos == 1 and _seccion(cab):
            seccion = _seccion(cab)
            m = re.search(r"ejercicio (\d{4})", cab)
            ejercicio = int(m.group(1)) if m else None
        ultima = None
        for ln in lineas:
            m = _FILA.match(ln)
            if m:
                ccaa = m.group("ccaa") or m.group("idente")[-2:]
                idente = m.group("idente") if m.group("ccaa") else m.group("idente")[:-2]
                resto = m.group("resto")
                nombre = (m.group("nombre") or "").strip()
                ultima = {
                    "seccion": seccion,
                    "ejercicio_referencia": ejercicio,
                    "idente": idente,
                    "codigo_entidad": ccaa + m.group("prov") + resto,
                    "tipo_entidad": resto[3:5],
                    "cod_prov": m.group("prov"),
                    "cod_mun": m.group("prov") + resto[:3] if resto[3:5] == "AA" else None,
                    "nombre": nombre.replace("(*)", "").strip(),
                    "por_dependientes": "(*)" in nombre,
                }
                yield ultima
            elif ultima is not None and "(*)" in ln and "Retenci" not in ln:
                # nombre partido en dos líneas: el "(*)" cae en la segunda
                ultima["por_dependientes"] = True


# Formato solo con nombres (hasta octubre de 2022)
_RUIDO = re.compile(
    r"^(P.gina \d|Secretar|Local$|Comunidad Aut|\(\*\) Retenci|Relaci|apartado|art.culo|incumplimiento)", re.I
)


def _parsea_con_nombres(paginas: list[str]):
    for texto in paginas:
        prov = None
        for ln in (x.strip() for x in texto.split("\n")):
            if ln.startswith("Comunidad Aut"):
                prov = None
                continue
            if ln.startswith("(*) Retenci"):
                break
            m = re.match(r"^(\d{2}) (\D+)$", ln)
            if m:
                prov = m.group(1)
                continue
            if prov is None or not ln or _RUIDO.match(ln):
                continue
            yield {
                "seccion": "liquidacion",
                "ejercicio_referencia": None,
                "idente": None,
                "codigo_entidad": None,
                "tipo_entidad": None,
                "cod_prov": prov,
                "cod_mun": None,
                "nombre": ln.replace("(*)", "").strip(),
                "por_dependientes": "(*)" in ln,
            }


def _filas_pdf(contenido: bytes):
    import pdfplumber

    with pdfplumber.open(io.BytesIO(contenido)) as pdf:
        paginas = [p.extract_text() or "" for p in pdf.pages]
    if any(re.search(r"\d{3}[A-Z]{2}\d{3}", p) for p in paginas):
        return list(_parsea_con_codigos(paginas))
    return list(_parsea_con_nombres(paginas))


@dlt.resource(name="pie_retenciones", write_disposition="replace")
def pie_retenciones():
    hoy = date.today()
    urls = _urls_retenciones(_enlaces_oveell(), hoy)
    for mes, url in urls.items():
        if mes < PRIMER_MES_RETENCIONES:
            continue
        reciente = (hoy - mes).days < 100
        contenido = _descarga(url, CACHE / "retenciones" / f"{mes:%Y-%m}.pdf", reciente)
        if contenido is None:
            continue
        filas = _filas_pdf(contenido)
        if not filas:
            log.warning("Sin filas en %s", url)
        for f in filas:
            yield {"periodo": mes, **f, "fuente_pdf": url}


# ---------------------------------------------------------------------------
# Excel de entregas a cuenta: importe retenido por el art. 36
# ---------------------------------------------------------------------------

def _hojas(contenido: bytes):
    """Filas de cada hoja como listas de valores, para .xlsx y .xls."""
    if contenido[:2] == b"PK":
        import openpyxl

        wb = openpyxl.load_workbook(io.BytesIO(contenido), read_only=True, data_only=True)
        for ws in wb.worksheets:
            yield ws.title, (list(r) for r in ws.iter_rows(values_only=True))
    else:
        import xlrd

        wb = xlrd.open_workbook(file_contents=contenido)
        for ws in wb.sheets():
            yield ws.name, (ws.row_values(i) for i in range(ws.nrows))


def _codigo(v, n: int) -> str | None:
    if v is None or v == "":
        return None
    if isinstance(v, float):
        v = int(v)
    s = str(v).strip()
    return s.zfill(n) if s.isdigit() else None


def _num(v) -> float | None:
    if v is None or v == "":
        return None
    if isinstance(v, (int, float)):
        return float(v)
    try:
        return float(str(v).replace(".", "").replace(",", "."))
    except ValueError:
        return None


def _filas_entregas(contenido: bytes):
    for hoja, filas in _hojas(contenido):
        if not hoja.strip().lower().startswith("municipios"):
            continue
        cols = None
        for fila in filas:
            textos = [str(x or "").replace("\n", " ").lower() for x in fila]
            if cols is None:
                if any(t.startswith("c. prov") for t in textos):
                    i_ret = next(
                        (i for i, t in enumerate(textos) if "retenci" in t and "36" in t), None
                    )
                    if i_ret is None:
                        break  # hoja sin la columna del art. 36
                    cols = {
                        "prov": next(i for i, t in enumerate(textos) if t.startswith("c. prov")),
                        "corp": next(i for i, t in enumerate(textos) if t.startswith("c. corp")),
                        "nombre": next(i for i, t in enumerate(textos) if t.strip() == "nombre"),
                        "ret": i_ret,
                    }
                continue
            prov, corp = _codigo(fila[cols["prov"]], 2), _codigo(fila[cols["corp"]], 3)
            importe = _num(fila[cols["ret"]])
            if prov and corp and importe:
                yield {
                    "cod_mun": prov + corp,
                    "nombre": str(fila[cols["nombre"]] or "").strip(),
                    "modelo": "cesion" if "cesi" in hoja.lower() else "sistema_general",
                    "retencion_art36_eur": importe,
                }


@dlt.resource(name="pie_retenciones_importes", write_disposition="replace")
def pie_retenciones_importes():
    hoy = date.today()
    enlaces = _enlaces_oveell()
    for mes in _meses_desde(PRIMER_MES_RETENCIONES, hoy):
        reciente = (hoy - mes).days < 100
        contenido, fuente = None, None
        for url in _urls_entregas(enlaces, mes):
            ext = ".xlsx" if url.lower().endswith(".xlsx") else ".xls"
            contenido = _descarga(url, CACHE / "entregas" / f"{mes:%Y-%m}-{zlib.crc32(url.encode()):08x}{ext}", reciente)
            if contenido:
                fuente = url
                break
        if contenido is None:
            log.info("Sin Excel de entregas a cuenta para %s", mes)
            continue
        for f in _filas_entregas(contenido):
            yield {"periodo": mes, **f, "fuente_excel": fuente}


# ---------------------------------------------------------------------------
# Periodo medio de pago (PMP_NET)
# ---------------------------------------------------------------------------

# 01-04-006-A-A-000 (en 2014: 01-04-013-AA-000)
_CODIGO_PMP = re.compile(r"^(\d{2})-(\d{2})-(\d{3})-([A-Z])-?([A-Z])-(\d{3})$")


def _texto(v) -> str:
    return re.sub(r"\s+", " ", str(v or "")).strip()


def _filas_pmp(contenido: bytes):
    entidades, tipos = [], []
    for hoja, filas in _hojas(contenido):
        h = hoja.lower()
        if h.startswith("resumen"):
            continue
        if h.startswith(("desagregado", "desglosado")):
            for fila in filas:
                if len(fila) > 5 and isinstance(fila[2], str) and re.fullmatch(r"[A-Z]{2}", fila[2].strip()):
                    tipos.append({
                        "tipo_entidad": fila[2].strip(),
                        "tipo_entidad_nombre": _texto(fila[1]),
                        "firmados": int(_num(fila[3]) or 0),
                        "existentes": int(_num(fila[4]) or 0),
                    })
            continue
        modelo = "cesion" if "cesi" in h else "variables"
        firmado_col = None
        for fila in filas:
            textos = [_texto(x).lower() for x in fila]
            if "código de entidad" in textos or "codigo de entidad" in textos:
                firmado_col = next((i for i, t in enumerate(textos) if t.startswith("firmado")), None)
                continue
            if len(fila) < 11:
                continue
            m = _CODIGO_PMP.match(_texto(fila[3]))
            if not m:
                continue
            tipo = m.group(4) + m.group(5)
            entidades.append({
                "codigo_entidad": _texto(fila[3]),
                "tipo_entidad": tipo,
                "cod_prov": m.group(2),
                "cod_mun": m.group(2) + m.group(3) if tipo == "AA" else None,
                "nombre": _texto(fila[5]),
                "ccaa_nombre": _texto(fila[1]),
                "modelo": modelo,
                "ratio_operaciones_pagadas": _num(fila[6]),
                "importe_pagos_realizados": _num(fila[7]),
                "ratio_operaciones_pendientes": _num(fila[8]),
                "importe_pagos_pendientes": _num(fila[9]),
                "pmp_dias": _num(fila[10]),
                "firmado_en_plazo": (
                    None if firmado_col is None else _texto(fila[firmado_col]).lower().startswith("s")
                ),
            })
    return entidades, tipos


def _trimestres_pmp(hoy: date):
    for anio in range(PRIMER_ANIO_PMP, hoy.year + 1):
        for trimestre, periodo in PERIODOS_PMP.items():
            fin = date(anio, 3 * trimestre, 1)
            # la publicación llega hacia el final del mes siguiente al plazo
            if fin + timedelta(days=45) > hoy:
                continue
            yield anio, trimestre, periodo, fin


_pmp_cache: dict[tuple[int, int], tuple[list, list]] = {}


def _pmp(anio: int, trimestre: int, periodo: str, fin: date, hoy: date):
    if (anio, trimestre) not in _pmp_cache:
        reciente = (hoy - fin).days < 200
        contenido = _descarga(
            PMP_URL.format(anio=anio, periodo=periodo), CACHE / "pmp" / f"{anio}-T{trimestre}.bin", reciente
        )
        _pmp_cache[(anio, trimestre)] = _filas_pmp(contenido) if contenido else ([], [])
    return _pmp_cache[(anio, trimestre)]


@dlt.resource(name="pmp_entidades", write_disposition="replace")
def pmp_entidades():
    hoy = date.today()
    for anio, trimestre, periodo, fin in _trimestres_pmp(hoy):
        entidades, _ = _pmp(anio, trimestre, periodo, fin, hoy)
        for e in entidades:
            yield {"anio": anio, "trimestre": trimestre, **e}


@dlt.resource(name="pmp_resumen_tipos", write_disposition="replace")
def pmp_resumen_tipos():
    hoy = date.today()
    for anio, trimestre, periodo, fin in _trimestres_pmp(hoy):
        _, tipos = _pmp(anio, trimestre, periodo, fin, hoy)
        for t in tipos:
            yield {"anio": anio, "trimestre": trimestre, **t}


@dlt.source(name="hacienda_transparencia")
def hacienda_transparencia():
    return [pie_retenciones, pie_retenciones_importes, pmp_entidades, pmp_resumen_tipos]
