"""Fuente dlt de las reclamaciones de acceso a la información pública ante el Consejo
de Transparencia y Buen Gobierno (tema `transparencia_reclamaciones`).

El CTBG no publica datos abiertos de sus resoluciones. Se usan dos fuentes oficiales
de su web (reutilización con cita «Origen de los datos: Consejo de Transparencia y
Buen Gobierno», Ley 37/2007):

1) Listados mensuales de resoluciones (HTML), ámbito estatal (AGE y sector público
   estatal, desde 2015) y autonómico (comunidades y ciudades autónomas con convenio
   con el CTBG y sus entidades locales, desde 2016). Cada listado separa las
   resoluciones por pestañas según su sentido (estimadas, estimadas por motivos
   formales, desestimadas, inadmitidas, archivadas...). Desde que el listado es una
   tabla, trae también el ministerio u organismo (o la comunidad); en los años en que
   es una lista de enlaces solo trae número y asunto. La estimación parcial solo se
   distingue por la carpeta del PDF (ESTIMATORIAS-PARCIAL).
2) Hoja de seguimiento del cumplimiento de las resoluciones estimatorias de la AGE
   (XLSX, una pestaña por año desde 2015): número, ministerio u organismo, sentido,
   fecha y situación (cumplida, no consta cumplimiento, recurrida en vía
   contencioso-administrativa). El nombre del fichero cambia con cada corte: se
   localiza en la página de cumplimiento.

Rastreo educado y reanudable: cada listado se guarda en data/ctbg_cache/ y los meses
cerrados (más de 3 meses de antigüedad) no se vuelven a pedir. Pausa de 2 s entre
peticiones. Primera carga: ~270 páginas, unos 10-15 minutos.

    python -m ingestion.transparencia_reclamaciones --crawl   # solo descarga a la caché
    python -m ingestion.transparencia_reclamaciones           # descarga lo que falte y carga

Recursos (replace): ctbg_resoluciones, ctbg_cumplimiento_age.
"""

import datetime as dt
import html as htmllib
import io
import logging
import re
import sys
import time
import unicodedata
from pathlib import Path
from urllib.parse import unquote

import dlt
import openpyxl
import requests

log = logging.getLogger(__name__)

CABECERAS = {"User-Agent": "Mozilla/5.0 (compatible; SpainFacts; +https://spainfacts.github.io)"}
CTBG = "https://consejodetransparencia.es"
SECCION = "/reclamaciones/nuestras-resoluciones/resoluciones-ambito-{ambito}"
PAGINA_CUMPLIMIENTO = CTBG + "/reclamaciones/cumplimiento-resoluciones/ambito-estatal"
CACHE = Path(__file__).resolve().parent.parent / "data" / "ctbg_cache"
PAUSA = 2.0

MESES = {"enero": 1, "febrero": 2, "marzo": 3, "abril": 4, "mayo": 5, "junio": 6, "julio": 7,
         "agosto": 8, "septiembre": 9, "setiembre": 9, "octubre": 10, "noviembre": 11, "diciembre": 12}


def _get(url: str, intentos: int = 4) -> requests.Response:
    for i in range(intentos):
        try:
            r = requests.get(url, timeout=120, headers=CABECERAS)
            r.raise_for_status()
            return r
        except requests.RequestException as e:
            if i == intentos - 1 or (getattr(e, "response", None) is not None and e.response.status_code == 404):
                raise
            log.warning("Reintento %s de %s: %s", i + 1, url, e)
            time.sleep(10 * (i + 1))


def _sin_tildes(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn").lower()


def _limpia(fragmento: str) -> str:
    t = re.sub(r"<br\s*/?>", " ", fragmento, flags=re.I)
    t = re.sub(r"<[^>]+>", " ", t)
    return re.sub(r"\s+", " ", htmllib.unescape(t)).strip()


# --- índice de meses ------------------------------------------------------------------

def meses_publicados(ambito: str) -> list[tuple[int, int, str]]:
    """(año, mes, ruta) de cada listado mensual enlazado desde la página de la sección."""
    base = SECCION.format(ambito=ambito)
    html = _get(CTBG + base).text
    vistos = {}
    for ruta in re.findall(r'href="(' + re.escape(base) + r'/(\d{4})/([^"#?]+))"', html):
        url, anio, resto = ruta
        anio = int(anio)
        if re.fullmatch(r"\d{2}", resto):
            mes = int(resto)
        else:
            m = re.search(r"(" + "|".join(MESES) + r")", resto)
            if not m:
                continue
            mes = MESES[m.group(1)]
        vistos[(anio, mes)] = url
    return sorted((a, m, u) for (a, m), u in vistos.items())


def _ruta_cache(ambito: str, anio: int, mes: int) -> Path:
    return CACHE / "listados" / ambito / f"{anio}-{mes:02d}.html"


def descargar(ambito: str) -> list[tuple[int, int, str, Path]]:
    """Baja a la caché los listados que falten (y vuelve a pedir los de los 3 últimos meses)."""
    hoy = dt.date.today()
    limite = (hoy.year * 12 + hoy.month) - 3
    salida = []
    meses = meses_publicados(ambito)
    if len(meses) < 50:
        raise ValueError(f"CTBG {ambito}: solo {len(meses)} listados mensuales en el índice")
    for anio, mes, url in meses:
        p = _ruta_cache(ambito, anio, mes)
        reciente = anio * 12 + mes > limite
        if not p.exists() or reciente:
            p.parent.mkdir(parents=True, exist_ok=True)
            try:
                contenido = _get(CTBG + url).content
            except requests.RequestException as e:
                log.warning("CTBG %s %s-%02d: %s", ambito, anio, mes, e)
                continue
            p.write_bytes(contenido)
            log.info("CTBG %s %s-%02d descargado (%s KB)", ambito, anio, mes, len(contenido) // 1024)
            time.sleep(PAUSA)
        salida.append((anio, mes, url, p))
    return salida


# --- lectura de un listado ------------------------------------------------------------

TAB_PATRON = re.compile(r'role="tabpanel"[^>]*?dc:title&#34;:&#34;([^&]*)&#34;')


def _sentido_pestana(titulo: str) -> str:
    t = _sin_tildes(titulo)
    if "formal" in t:
        return "Estimada por motivos formales"
    if t.startswith("estimad"):
        return "Estimada"
    if t.startswith("desestim"):
        return "Desestimada"
    if t.startswith("inadmit"):
        return "Inadmitida"
    if "archiv" in t:
        return "Archivada"
    if "suspen" in t and "levantamiento" not in t:
        return "Suspendida"
    if "retrotra" in t:
        return "Retroacción de actuaciones"
    return "Otras"


def _campo(cabecera: str) -> str | None:
    c = _sin_tildes(cabecera)
    if "ministerio" in c or c.startswith("organismo"):
        return "organismo"
    if "comunidad" in c:
        return "comunidad"
    if "administraci" in c:
        return "tipo_administracion"
    if "asunto" in c:
        return "asunto"
    if "motivo" in c or "palabras" in c:
        return "motivo"
    if "resoluci" in c or "expediente" in c or c.startswith("num"):
        return "numero"
    return None


def _numero_de_texto(t: str) -> str:
    m = re.search(r"(R[A-Z]*\s*(?:CTBG)?\s*[/ ]?\s*\d{1,5}\s*/\s*\d{4})", t)
    return re.sub(r"\s+", " ", m.group(1)).strip() if m else t[:40]


def _clave_numero(numero: str, url_pdf: str | None) -> str | None:
    """Clave homogénea 'NNNN/AAAA' a partir del número o, si no, del nombre del PDF."""
    for txt in (numero or "", unquote(url_pdf or "").rsplit("/", 1)[-1]):
        m = re.search(r"(\d{1,5})\s*/\s*(20\d\d)", txt)
        if m:
            return f"{int(m.group(1)):04d}/{m.group(2)}"
        m = re.search(r"(20\d\d)[-_ ](\d{3,5})\b", txt)
        if m:
            return f"{int(m.group(2)):04d}/{m.group(1)}"
        m = re.search(r"R[T]?[-_ ](\d{3,5})[-_ ](20\d\d)", txt)
        if m:
            return f"{int(m.group(1)):04d}/{m.group(2)}"
        m = re.search(r"(?<!\d)(\d{3,5})[-_](20\d\d)(?!\d)", txt)
        if m:
            return f"{int(m.group(1)):04d}/{m.group(2)}"
    return None


def _expediente(url_pdf: str | None) -> str | None:
    """Número de expediente de la reclamación ('NNNN/AAAA') si el nombre del PDF lo trae."""
    nombre = unquote(url_pdf or "").rsplit("/", 1)[-1]
    m = re.search(r"expte?s?\.?\s*(?:n\S*\s*)?R?[-_ ]?(\d{1,5})[-_/](20\d\d)", nombre, flags=re.I)
    return f"{int(m.group(1)):04d}/{m.group(2)}" if m else None


def _parcial(url_pdf: str | None) -> bool:
    return bool(url_pdf) and "PARCIAL" in unquote(url_pdf).upper()


def leer_listado(contenido: str, ambito: str, anio: int, mes: int, url: str):
    cortes = [(m.start(), m.group(1)) for m in TAB_PATRON.finditer(contenido)]
    for k, (ini, titulo) in enumerate(cortes):
        fin = cortes[k + 1][0] if k + 1 < len(cortes) else len(contenido)
        bloque = contenido[ini:fin]
        sentido = _sentido_pestana(htmllib.unescape(titulo))
        # Formato tabla (vista de escritorio; la vista móvil repite las filas)
        tablas = re.findall(r'data-visible="desktop".*?(<table.*?</table>)', bloque, flags=re.S)
        if not tablas:  # tablas «tableizer» incrustadas en un texto (2022-11, desde 2025-07)
            tablas = re.findall(r"<table.*?</table>", bloque, flags=re.S)
        if tablas:
            for tabla in tablas:
                cab = [_campo(_limpia(h)) for h in re.findall(r"<th[^>]*>(.*?)</th>", tabla, flags=re.S)]
                for fila in re.findall(r"<tr[^>]*>(.*?)</tr>", tabla, flags=re.S):
                    celdas = re.findall(r"<td[^>]*>(.*?)</td>", fila, flags=re.S)
                    if not celdas:
                        continue
                    # Desde 2026 la cabecera va en la primera fila, con <td> en vez de <th>
                    if not re.search(r"\.pdf", fila, flags=re.I) and _campo(_limpia(celdas[0])) == "numero":
                        cab = [_campo(_limpia(c)) for c in celdas]
                        continue
                    reg = {}
                    for i, celda in enumerate(celdas):
                        nombre = cab[i] if i < len(cab) and cab[i] else f"col{i}"
                        reg[nombre] = _limpia(celda)
                    pdf = re.search(r'href="([^"]+\.pdf)"', celdas[0], flags=re.I)
                    url_pdf = CTBG + pdf.group(1) if pdf and pdf.group(1).startswith("/") else (pdf.group(1) if pdf else None)
                    numero = _numero_de_texto(reg.get("numero") or _limpia(celdas[0]))
                    n_exptes = re.search(r"\((\d+)\s*exptes?", reg.get("numero", ""))
                    yield {
                        "ambito": ambito, "anio_listado": anio, "mes_listado": mes, "formato": "tabla",
                        "pestana": _limpia(htmllib.unescape(titulo)), "sentido": sentido,
                        "parcial": sentido == "Estimada" and _parcial(url_pdf),
                        "numero": numero, "clave": _clave_numero(numero, url_pdf), "expediente": _expediente(url_pdf),
                        "n_expedientes": int(n_exptes.group(1)) if n_exptes else 1,
                        "organismo": reg.get("organismo"), "comunidad": reg.get("comunidad"),
                        "tipo_administracion": reg.get("tipo_administracion"),
                        "asunto": reg.get("asunto"), "motivo": reg.get("motivo"),
                        "url_pdf": url_pdf, "url_listado": CTBG + url,
                    }
            continue
        # Formato lista de enlaces: «R/0049/2016 Asunto (3313 KB)»
        for href, texto in re.findall(r'<li[^>]*>\s*<a[^>]*\shref="([^"]+\.pdf)"[^>]*>(.*?)</a>', bloque, flags=re.S | re.I):
            t = re.sub(r"\(\s*\d+\s*KB\s*\)\s*$", "", _limpia(texto)).strip()
            url_pdf = CTBG + href if href.startswith("/") else href
            numero = _numero_de_texto(t)
            asunto = t[t.find(numero) + len(numero):].strip(" -–:") if numero in t else t
            yield {
                "ambito": ambito, "anio_listado": anio, "mes_listado": mes, "formato": "lista",
                "pestana": _limpia(htmllib.unescape(titulo)), "sentido": sentido,
                "parcial": sentido == "Estimada" and _parcial(url_pdf),
                "numero": numero, "clave": _clave_numero(numero, url_pdf), "expediente": _expediente(url_pdf), "n_expedientes": 1,
                "organismo": None, "comunidad": None, "tipo_administracion": None,
                "asunto": asunto or None, "motivo": None,
                "url_pdf": url_pdf, "url_listado": CTBG + url,
            }


# --- cumplimiento (XLSX) --------------------------------------------------------------

def _cumplimiento():
    html = _get(PAGINA_CUMPLIMIENTO).text
    m = re.search(r'href="([^"]*cumplimiento-age/[^"]*\.xlsx)"', html, flags=re.I)
    if not m:
        raise ValueError("No se encuentra la hoja de seguimiento del cumplimiento de la AGE")
    url = CTBG + m.group(1) if m.group(1).startswith("/") else m.group(1)
    corte = re.search(r"(\d{1,2})-(\d{1,2})-(\d{4})", unquote(url))
    fecha_corte = dt.date(int(corte.group(3)), int(corte.group(2)), int(corte.group(1))) if corte else None
    contenido = _get(url).content
    (CACHE / "cumplimiento").mkdir(parents=True, exist_ok=True)
    (CACHE / "cumplimiento" / Path(unquote(url)).name).write_bytes(contenido)
    wb = openpyxl.load_workbook(io.BytesIO(contenido), read_only=True, data_only=True)
    for ws in wb.worksheets:
        anio_hoja = re.fullmatch(r"\s*(20\d\d)\s*", ws.title)
        if not anio_hoja:
            continue  # hojas de tablas dinámicas
        filas = list(ws.iter_rows(values_only=True))
        icab = next((i for i, f in enumerate(filas[:6]) if f and any("Situaci" in str(c or "") for c in f)), None)
        if icab is None:
            raise ValueError(f"Hoja {ws.title} sin cabecera reconocible")
        cab = [_sin_tildes(str(c or "")) for c in filas[icab]]

        def col(*claves):
            for i, c in enumerate(cab):
                if all(k in c for k in claves):
                    return i
            return None

        c_num = col("resoluci")
        c_exp = col("expte") if col("expte") is not None else col("expediente")
        c_min = col("ministerio")
        c_org = next((i for i, c in enumerate(cab) if c.strip() == "organismo"), None)
        c_asu, c_sen, c_fec, c_sit = col("asunto"), col("sentido"), col("fecha"), col("situaci")
        for f in filas[icab + 1:]:
            if not f or c_num is None or not f[c_num]:
                continue
            numero = re.sub(r"\s+", " ", str(f[c_num])).strip()
            fecha = f[c_fec] if c_fec is not None else None
            if isinstance(fecha, dt.datetime):
                fecha = fecha.date()
            elif not isinstance(fecha, dt.date):
                fecha = None
            claves = re.findall(r"(\d{1,5})\s*/\s*(20\d\d)", numero) or [
                (b, a) for a, b in re.findall(r"(20\d\d)-(\d{3,5})", numero)]
            yield {
                "anio_hoja": int(anio_hoja.group(1)), "numero": numero,
                "clave": f"{int(claves[0][0]):04d}/{claves[0][1]}" if claves else None,
                "expediente": str(f[c_exp]).strip() if c_exp is not None and f[c_exp] else None,
                "ministerio": re.sub(r"\s+", " ", str(f[c_min] or "")).strip() or None if c_min is not None else None,
                "organismo": re.sub(r"\s+", " ", str(f[c_org] or "")).strip() or None if c_org is not None else None,
                "asunto": re.sub(r"\s+", " ", str(f[c_asu] or "")).strip() or None if c_asu is not None else None,
                "sentido": re.sub(r"\s+", " ", str(f[c_sen] or "")).strip() or None if c_sen is not None else None,
                "fecha_resolucion": fecha,
                "situacion": re.sub(r"\s+", " ", str(f[c_sit] or "")).strip().upper() or None if c_sit is not None else None,
                "fecha_corte": fecha_corte, "url_fuente": url,
            }


@dlt.source(name="transparencia_reclamaciones")
def transparencia_reclamaciones():
    @dlt.resource(name="ctbg_resoluciones", write_disposition="replace")
    def resoluciones():
        for ambito in ("estatal", "autonomico"):
            n = 0
            for anio, mes, url, p in descargar(ambito):
                for fila in leer_listado(p.read_bytes().decode("utf-8", "replace"), ambito, anio, mes, url):
                    n += 1
                    yield fila
            if n < 1000:
                raise ValueError(f"CTBG {ambito}: solo {n} resoluciones leídas")
            log.info("CTBG %s: %s resoluciones", ambito, n)

    @dlt.resource(name="ctbg_cumplimiento_age", write_disposition="replace")
    def cumplimiento():
        n = 0
        for fila in _cumplimiento():
            n += 1
            yield fila
        if n < 3000:
            raise ValueError(f"Seguimiento del cumplimiento con muy pocas filas: {n}")
        log.info("CTBG cumplimiento AGE: %s resoluciones estimatorias", n)

    return [resoluciones, cumplimiento]


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    if "--crawl" in sys.argv:
        for amb in ("estatal", "autonomico"):
            print(amb, len(descargar(amb)), "listados en caché")
    else:
        from ingestion.destino import pipeline

        print(pipeline("transparencia_reclamaciones").run(transparencia_reclamaciones()))
