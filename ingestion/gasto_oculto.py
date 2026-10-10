"""Fuente dlt «Gasto oculto»: técnicas para ver lo que la cifra resumida de un presupuesto no enseña
(tema `gasto_oculto`). Todo sale de documentos oficiales con descarga abierta.

1. Cuenta General de la Comunidad de Madrid (Intervención General, madrid.org/cuenta-general),
   ejercicios 2016 en adelante (los de 2015 se publican en un formato binario que no es PDF). Para cada entidad con presupuesto limitativo (Administración de la
   Comunidad, SERMAS, AMAS, Agencia de Vivienda Social...) se leen dos estados en PDF:
     - E.1 «Liquidación del presupuesto de gastos» por centro (EOxxx_E.1.Liq_Ppto_Gastos_1.pdf):
       por aplicación económica (subconcepto, 5 cifras) crédito inicial, modificaciones, crédito
       definitivo, gastos comprometidos, obligaciones reconocidas netas, pagos, pendiente de pago y
       remanentes.                                            -> gasto_oculto_cm_liquidacion
     - F.23.1.1.a «Modificaciones de crédito» por centro (..._F.23.1.1.a.PptoCorr_Gtos_Modificaciones_1.pdf):
       por aplicación, cuánto vino de cada tipo de modificación (créditos extraordinarios, suplementos,
       ampliaciones, transferencias, incorporaciones de remanentes, créditos generados por ingresos,
       otras).                                                -> gasto_oculto_cm_modificaciones
   Los PDF son informes SAP con columnas a la derecha: se leen las palabras con sus coordenadas
   (pdfplumber) y cada importe se asigna a la columna cuya cabecera tiene más cerca; si la fila trae
   tantos importes como columnas, por orden. Cada fichero se cuadra con su fila «TOTAL» (resource
   gasto_oculto_cm_cuadre). La relación de expedientes de modificación (origen y destino de cada
   transferencia) no se publica en formato abierto: el origen se ve por entidad (quién pierde crédito)
   y por las aplicaciones de transferencias a entes (capítulos 4 y 7) de la Administración General.

2. Acuerdos del Consejo de Gobierno de la Comunidad de Madrid (www.comunidad.madrid/acuerdos-consejo-gobierno):
   un PDF de referencias por sesión desde 2004. Se separan los acuerdos (viñetas «Acuerdo por el que...»,
   «Decreto...», «Informe...») bajo el epígrafe de su consejería y se guardan los que convalidan gasto
   (gasto hecho sin contrato o sin fiscalización previa que el Consejo «convalida» para poder pagarlo) y
   los de modificaciones presupuestarias (transferencias, generaciones, ampliaciones, suplementos,
   créditos extraordinarios), con el importe en euros que cita el texto.
                                                              -> gasto_oculto_cm_acuerdos, gasto_oculto_cm_sesiones

1b. Ejecución mensual del presupuesto de la Generalitat de Catalunya (Socrata ajns-4mi7): la misma
   técnica con datos abiertos por entidad (Generalitat, CatSalut, ICS...), sección, programa y
   concepto, 2014 en adelante, con las modificaciones por tipo.  -> gasto_oculto_cat_execucio

3. Contratos menores de sanidad con NIF y descarga abierta (la Comunidad de Madrid no la tiene: su
   exportación CSV exige captcha y el buscador solo enseña importe y adjudicatario en la ficha de
   cada contrato, 4,8 millones de fichas; no se usa):
     - Andalucía: «Contratación menor publicada en la Plataforma de Contratación de la Junta de
       Andalucía», CSV anual (CKAN juntadeandalucia.es/datosabiertos), órganos sanitarios (Servicio
       Andaluz de Salud y sus agencias sanitarias).
     - Cataluña: «Publicacions a la Plataforma de serveis de contractació pública» (Socrata ybgg-dgi6),
       procediment = 'Contracte menor', Departament de Salut (ICS, consorcios, CatSalut...). Con CPV.
   Se agregan aquí por año, órgano, adjudicatario (NIF), tipo de contrato y «objeto parecido»
   (clave_objeto: grupo CPV de 3 cifras en Cataluña; dos primeras palabras con contenido del título
   cuando no hay CPV, siempre en Andalucía), con número de contratos e importe sin IVA, para buscar
   posibles fraccionamientos en dbt. No se guardan personas físicas (NIF de persona) ni el detalle contrato a contrato.
                                                              -> gasto_oculto_menores_grupos

Uso: gasto_oculto(cache_dir=..., desde_cuenta=2016, desde_menores=2018).
"""

from __future__ import annotations

import csv
import gzip
import hashlib
import io
import json
import logging
import re
import time
import unicodedata
from collections import defaultdict
from datetime import date
from pathlib import Path

import dlt
import requests

log = logging.getLogger(__name__)

REPO_ROOT = Path(__file__).resolve().parent.parent
CACHE_POR_DEFECTO = REPO_ROOT / "data" / "gasto_oculto_cache"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) "
                    "Chrome/130.0 Safari/537.36 (spainfacts.org; datos abiertos)",
      "Accept-Language": "es-ES,es;q=0.9"}
PAUSA_S = 0.8


# --- utilidades -------------------------------------------------------------------------------
def norm(s) -> str:
    s = " ".join(str(s or "").split()).upper()
    return "".join(c for c in unicodedata.normalize("NFKD", s) if not unicodedata.combining(c))


def num_es(t: str) -> float | None:
    """'1.234.567,89' / '-1.165.094,36' / '- 137.800.580,00' -> float."""
    t = (t or "").replace(" ", "").replace("\xa0", "")
    if not re.fullmatch(r"-?\d{1,3}(\.\d{3})*,\d{1,2}|-?\d+,\d{1,2}", t):
        return None
    return float(t.replace(".", "").replace(",", "."))


RE_IMPORTE_PDF = re.compile(r"^-?\d{1,3}(\.\d{3})*,\d{2}$|^-?\d+,\d{2}$")


def _get(url, sesion=None, intentos=5, timeout=(30, 300), params=None):
    s = sesion or requests
    for i in range(intentos):
        try:
            r = s.get(url, headers=UA, timeout=timeout, params=params)
            if r.status_code in (403, 404, 410):
                return r
            if r.status_code == 429 or r.status_code >= 500:
                time.sleep(10 * (i + 1))
                continue
            return r
        except requests.RequestException as e:
            log.warning("GET %s (intento %d): %s", url[:150], i + 1, e)
            time.sleep(5 * (i + 1))
    raise RuntimeError(f"No se pudo descargar {url}")


class _Cache:
    def __init__(self, cache_dir):
        self.dir = Path(cache_dir or CACHE_POR_DEFECTO)
        self.dir.mkdir(parents=True, exist_ok=True)

    def ruta(self, sub, url):
        d = self.dir / sub
        d.mkdir(parents=True, exist_ok=True)
        nombre = re.sub(r"[^A-Za-z0-9._-]+", "_", url.split("?")[0].rsplit("/", 1)[-1])[-80:]
        return d / f"{hashlib.md5(url.encode()).hexdigest()[:10]}_{nombre}"

    def bytes(self, sub, url, sesion=None, refrescar=False):
        p = self.ruta(sub, url)
        if p.exists() and not refrescar:
            return p.read_bytes() or None
        time.sleep(PAUSA_S)
        r = _get(url, sesion=sesion)
        contenido = r.content if r.status_code == 200 else b""
        if contenido[:5] != b"%PDF-" and p.suffix.lower() == ".pdf":
            contenido = b""  # páginas de error HTML: se marca como «sin fichero»
        p.write_bytes(contenido)
        return contenido or None

    def json(self, nombre, funcion, refrescar=False):
        p = self.dir / f"{nombre}.json.gz"
        if p.exists() and not refrescar:
            with gzip.open(p, "rt", encoding="utf-8") as f:
                return json.load(f)
        d = funcion()
        with gzip.open(p, "wt", encoding="utf-8") as f:
            json.dump(d, f, ensure_ascii=False)
        return d


# --- 1. Cuenta General de la Comunidad de Madrid --------------------------------------------------
CG_BASE = "https://www.madrid.org/cuenta-general/CUENTA%20GENERAL%20{a}/"


def _cg_bases(anio):
    """La carpeta de cada ejercicio cambió: 2015-2021 «CUENTA GENERAL AAAA/Cuenta AAAA/», 2022- sin subcarpeta."""
    b = CG_BASE.format(a=anio)
    return [b, b + f"Cuenta%20{anio}/"] if anio >= 2022 else [b + f"Cuenta%20{anio}/", b]


def cg_entidades(anio, cache):
    """{código EOxxx: (nombre, base)} de las «Cuentas anuales de las entidades» del ejercicio."""
    for base in _cg_bases(anio):
        raw = cache.bytes("cg_html", base + "index3.htm")
        if not raw:
            continue
        html = raw.decode("latin1")
        out = {}
        for eo in sorted(set(re.findall(r"(EO\d{3})_marcos\.htm", html))):
            t = cache.bytes("cg_html", base + f"{eo}_marcos.htm")
            m = re.search(r"<title>([^<]*)", (t or b"").decode("latin1"), re.I)
            out[eo] = ((m.group(1).strip() if m else eo), base)
        if out:
            return out
    return {}


COLS_LIQ = [("INICIAL", "credito_inicial"), ("MODIFICAC.", "modificaciones"), ("DEFINITIVO", "credito_definitivo"),
            ("COMPROMETIDOS", "gastos_comprometidos"), ("NETAS", "obligaciones_netas"), ("PAGOS", "pagos"),
            ("DICIEMBRE", "pendiente_pago"), ("REMANENTES", "remanentes")]
COLS_MOD = [("EXTRAOR.", "creditos_extraordinarios"), ("SUPLEMENTOS", "suplementos"), ("AMPLIACIONES", "ampliaciones"),
            ("TRANSF.", "transferencias"), ("INCORPOR.", "incorporaciones"), ("GNRADO.", "generados_ingresos"),
            ("OTRAS", "otras"), ("TOTAL", "total")]


def _filas_palabras(words, tol=2.5):
    filas = []
    for w in sorted(words, key=lambda w: (round(w["top"], 1), w["x0"])):
        if filas and abs(filas[-1][0] - w["top"]) <= tol:
            filas[-1][1].append(w)
        else:
            filas.append([w["top"], [w]])
    return [(t, sorted(ws, key=lambda w: w["x0"])) for t, ws in filas]


def parse_estado_cg(pdf_bytes, columnas):
    """Lee un estado por aplicación de la Cuenta General. Devuelve (filas, totales, centro):
    filas = [{aplicacion, descripcion, <columnas>}], totales = {'TOTAL': {...}, 'TOTAL CAPÍTULO 2': {...}}."""
    import pdfplumber

    nombres = [c for _, c in columnas]
    filas, totales, centro = [], {}, None
    with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
        for page in pdf.pages:
            words = page.extract_words(use_text_flow=False, keep_blank_chars=False)
            if not words:
                continue
            rows = _filas_palabras(words)
            # cabecera: centro presupuestario y posición de las columnas
            centros = {}
            for _, ws in rows:
                txt = " ".join(w["text"] for w in ws)
                m = re.search(r"CENTRO PRESUPUESTARIO\s+(\w+)\s+(.*)", txt)
                if m:
                    centro = (m.group(1), m.group(2).strip())
                for w in ws:
                    for clave, col in columnas:
                        if w["text"] == clave and col not in centros and w["top"] < 175:
                            if col == "total" and w["x0"] < 700:
                                continue
                            centros[col] = (w["x0"] + w["x1"]) / 2
            if len(centros) < len(columnas) - 1:
                continue
            xs = [centros.get(c) for c in nombres]
            # desplazamiento típico de los importes respecto a su cabecera (importes alineados a la derecha)
            desp = []
            datos = []
            for top, ws in rows:
                nums = [w for w in ws if RE_IMPORTE_PDF.match(w["text"])]
                # «- 137.800.580,00»: signo suelto delante
                for i, w in enumerate(ws):
                    if w["text"] == "-" and i + 1 < len(ws) and RE_IMPORTE_PDF.match(ws[i + 1]["text"]):
                        ws[i + 1] = dict(ws[i + 1], text="-" + ws[i + 1]["text"])
                nums = [w for w in ws if RE_IMPORTE_PDF.match(w["text"])]
                if not nums:
                    continue
                cab = [w for w in ws if w["x1"] < min(n["x0"] for n in nums)]
                etiqueta = " ".join(w["text"] for w in cab)
                datos.append((etiqueta, nums))
                if len(nums) == len(columnas):
                    for n, x in zip(nums, xs):
                        if x is not None:
                            desp.append((n["x0"] + n["x1"]) / 2 - x)
            off = sorted(desp)[len(desp) // 2] if desp else 20.0
            for etiqueta, nums in datos:
                valores = dict.fromkeys(nombres)
                if len(nums) == len(columnas):
                    for n, c in zip(nums, nombres):
                        valores[c] = num_es(n["text"])
                else:
                    for n in nums:
                        cx = (n["x0"] + n["x1"]) / 2 - off
                        j = min((k for k in range(len(xs)) if xs[k] is not None), key=lambda k: abs(xs[k] - cx))
                        if valores[nombres[j]] is None:
                            valores[nombres[j]] = num_es(n["text"])
                m = re.match(r"^(\d{3,5})\s*(.*)$", etiqueta)
                if m:
                    filas.append(dict(aplicacion=m.group(1), descripcion=m.group(2).strip() or None,
                                      centro=centro[0] if centro else None, **valores))
                elif etiqueta.upper().startswith("TOTAL"):
                    totales[re.sub(r"\s+", " ", etiqueta.strip())] = valores
    return filas, totales, centro


def cuenta_general(cache, desde=2016, hasta=None):
    hasta = hasta or date.today().year - 1
    liq, mod, cuadre = [], [], []
    for anio in range(desde, hasta + 1):
        ents = cg_entidades(anio, cache)
        if not ents:
            log.info("Cuenta General %s: no publicada", anio)
            continue
        for eo, (nombre, base) in ents.items():
            for estado, fichero, columnas, destino in (
                    ("liquidacion", f"pdfs/{eo}_E.1.Liq_Ppto_Gastos_1.pdf", COLS_LIQ, liq),
                    ("modificaciones", f"pdfs/{eo}_F.23.1.1.a.PptoCorr_Gtos_Modificaciones_1.pdf", COLS_MOD, mod)):
                url = base + fichero
                raw = cache.bytes("cg_pdf", url)
                if not raw:
                    continue
                try:
                    # leer un PDF grande con pdfplumber tarda; el resultado se guarda junto al PDF
                    clave = "cg_parse_" + hashlib.md5(raw).hexdigest()[:16]
                    filas, totales, centro = cache.json(clave, lambda raw=raw, columnas=columnas:
                                                        list(parse_estado_cg(raw, columnas)))
                except Exception as e:  # noqa: BLE001 - un PDF roto no para la carga
                    log.warning("Cuenta General %s %s %s: %s", anio, eo, estado, e)
                    continue
                for f in filas:
                    f.update(anio=anio, entidad_cod=eo, entidad=nombre,
                             centro_nombre=centro[1] if centro else None, url=url)
                destino.extend(filas)
                tot = totales.get("TOTAL") or {}
                col = "obligaciones_netas" if estado == "liquidacion" else "total"
                suma = sum(f[col] or 0 for f in filas)
                cuadre.append(dict(anio=anio, entidad_cod=eo, entidad=nombre, estado=estado, url=url,
                                   filas=len(filas), columna=col, suma_aplicaciones=round(suma, 2),
                                   total_documento=tot.get(col),
                                   descuadre=None if tot.get(col) is None else round(suma - tot[col], 2)))
                if tot.get(col) is not None and abs(suma - tot[col]) > 1:
                    log.warning("Cuenta General %s %s %s: descuadre %.2f", anio, eo, estado, suma - tot[col])
    return liq, mod, cuadre


# --- 1b. Ejecución del presupuesto de la Generalitat de Catalunya --------------------------------------
CAT_EXECUCIO = "https://analisi.transparenciacatalunya.cat/resource/ajns-4mi7.json"
CAT_MEDIDAS = ("cr_dits_inicials", "cr_dits_extraord_supl_de_cr_dit", "ampliacions_de_cr_dit",
               "incorporaci_de_romanents_de_cr_dit", "generacions_de_cr_dit", "augments_per_transfer_ncia",
               "minoracions_per_transfer_ncia", "pressupost_definitiu", "autoritzacions", "disposicions",
               "obligacions_reconegudes", "obligacions_pagades")
CAT_GRUPO = ("exercici", "mes", "entitat_codi", "entitat", "secci_codi", "secci", "programa_codi", "programa",
             "cap_tol_codi", "article_codi", "concepte_codi", "concepte")


def execucio_cataluna(cache, desde=2014):
    """«Execució mensual del pressupost de la Generalitat de Catalunya. Despeses» (Socrata ajns-4mi7):
    crèdits inicials, modificacions per tipus, pressupost definitiu i obligacions reconegudes per
    entitat (Generalitat, CatSalut, ICS...), secció, programa i aplicació. Se agrega en el servidor a
    concepto (3 cifras) y se guarda el último mes publicado de cada ejercicio (diciembre en los
    cerrados)."""
    filas = []
    for anio in range(desde, date.today().year + 1):
        def _f(anio=anio):
            r = _get(CAT_EXECUCIO, params={"$select": "max(mes) as mes", "$where": f"exercici='{anio}'"})
            mes = (r.json() or [{}])[0].get("mes") if r.status_code == 200 else None
            if not mes:
                return []
            sel = ", ".join(c for c in CAT_GRUPO) + ", " + ", ".join(f"sum({m}) as {m}" for m in CAT_MEDIDAS)
            out, off = [], 0
            while True:
                r = _get(CAT_EXECUCIO, params={"$select": sel, "$where": f"exercici='{anio}' and mes='{mes}'",
                                               "$group": ", ".join(CAT_GRUPO), "$order": ", ".join(CAT_GRUPO),
                                               "$limit": 50000, "$offset": off}, timeout=(30, 900))
                if r.status_code != 200:
                    raise RuntimeError(f"Socrata ajns-4mi7 {anio}: {r.status_code} {r.text[:300]}")
                d = r.json()
                out += d
                if len(d) < 50000:
                    break
                off += 50000
            for x in out:
                for m in CAT_MEDIDAS:
                    x[m] = float(x[m]) if x.get(m) not in (None, "") else None
                x["anio"] = anio
                x["mes_num"] = int(re.match(r"(\d+)", x["mes"]).group(1))
            return out
        d = cache.json(f"cat_execucio_{anio}", _f, refrescar=anio >= date.today().year - 1)
        filas += d
        print(f"[gasto_oculto] ejecución Generalitat {anio}: {len(d)} filas", flush=True)
    return filas


# --- 2. Acuerdos del Consejo de Gobierno ------------------------------------------------------------
CG_INDICE = "https://www.comunidad.madrid/acuerdos-consejo-gobierno"
RE_PDF_INDICE = re.compile(r'href="((?:https://www\.comunidad\.madrid)?/(?:docs|sites)/[^"]+?\.pdf)[^"]*"', re.I)
RE_FECHA_URL = re.compile(r"acuerdos-gobierno/(\d{4})/(\d{2})/(\d{2})/")
RE_CONSEJERIA = re.compile(r"^\s*(CONSEJER[IÍ]A|VICEPRESIDENCIA|PRESIDENCIA|VICEPRESIDENTE|CONSEJERO|"
                           r"Consejer[ií]a|Vicepresidencia|Presidencia)\b")
RE_INICIO_ACUERDO = re.compile(r"^\s*(?:[o•·▪•]\s*|\d+[.)]\s+)?(Acuerdo|Decreto|Informe|Orden|Proyecto|"
                               r"Real Decreto|Ley|Toma de conocimiento|Se aprueba|Aprobaci[oó]n|Autorizaci[oó]n)\b")
RE_CONVALIDA = re.compile(r"(?i)convalid")
RE_MODIF = re.compile(r"(?i)transferencias? de cr[eé]dito|generaci[oó]n(?:es)? de cr[eé]dito|ampliaci[oó]n(?:es)? de "
                      r"cr[eé]dito|suplementos? de cr[eé]dito|cr[eé]ditos? extraordinarios?|modificaci[oó]n(?:es)? "
                      r"presupuestarias?|modificaci[oó]n(?:es)? de cr[eé]dito|incorporaci[oó]n(?:es)? de remanentes")
RE_EUROS = re.compile(r"(\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?|\d+,\d{1,2}|\d{4,})\s*(millones de\s*)?(?:euros|€)", re.I)


def cg_indice(cache, paginas=200, refrescar=True):
    def _f():
        s = requests.Session()
        sesiones = {}
        for p in range(paginas):
            time.sleep(PAUSA_S)
            r = _get(CG_INDICE, sesion=s, params={"page": p})
            if r.status_code != 200:
                break
            t = r.text
            pdfs = [u if u.startswith("http") else "https://www.comunidad.madrid" + u for u in RE_PDF_INDICE.findall(t)]
            fechas = ["-".join(m) for m in RE_FECHA_URL.findall(t)]
            # el JSON-LD de la página lista las sesiones en el mismo orden que los enlaces PDF
            fechas_unicas = list(dict.fromkeys(fechas))
            if not pdfs:
                break
            for i, u in enumerate(dict.fromkeys(pdfs)):
                f = fechas_unicas[i] if i < len(fechas_unicas) and len(fechas_unicas) == len(set(pdfs)) else None
                sesiones.setdefault(u, f)
            print(f"[gasto_oculto] índice Consejo de Gobierno página {p}: {len(sesiones)} sesiones", flush=True)
        return sesiones
    return cache.json("cg_indice", _f, refrescar=refrescar)


def _fecha_pdf(url, texto):
    nombre = url.rsplit("/", 1)[-1]
    m = re.search(r"(20\d{2})-(\d{2})-(\d{2})", nombre)
    if m:
        return "-".join(m.groups())
    m = re.search(r"(?<!\d)(\d{2})(\d{2})(\d{2})(?:_cg|_|\.)", nombre) or re.search(r"cg_(\d{2})(\d{2})(\d{2})", nombre)
    if m:
        return f"20{m.group(1)}-{m.group(2)}-{m.group(3)}"
    meses = {m: i + 1 for i, m in enumerate(("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
                                             "septiembre", "octubre", "noviembre", "diciembre"))}
    m = re.search(r"(\d{1,2}) de ([a-záéíóú]+) de (20\d{2})", texto[:3000].lower())
    if m and m.group(2) in meses:
        return f"{m.group(3)}-{meses[m.group(2)]:02d}-{int(m.group(1)):02d}"
    return None


def _texto_pdf(raw):
    import pdfplumber
    partes = []
    with pdfplumber.open(io.BytesIO(raw)) as pdf:
        for p in pdf.pages:
            partes.append(p.extract_text() or "")
    return "\n".join(partes)


RE_IMPORTE_DE = re.compile(r"(?i)importe(?: total| global| m[aá]ximo| conjunto)?(?: de| ascendente a)?\s*"
                           r"(\d{1,3}(?:\.\d{3})+(?:,\s?\d{1,2})?|\d+(?:,\s?\d{1,2})?)(?!\d)\s*(millones)?")


def _importe_euros(texto):
    """Importe del acuerdo (el de la convalidación o la modificación): el que sigue a «importe
    (total) de», y si no hay, el primero seguido de «euros». Admite «8.014, 71»."""
    m = RE_IMPORTE_DE.search(texto)
    if m:
        v = m.group(1).replace(" ", "")
        x = float(v.replace(".", "").replace(",", ".")) if "," in v else float(v.replace(".", ""))
        if m.group(2):
            x *= 1e6
        if x >= 1:
            return x
    for m in RE_EUROS.finditer(texto.replace(", ", ",")):
        v = m.group(1)
        if "," in v:
            x = float(v.replace(".", "").replace(",", "."))
        else:
            x = float(v.replace(".", ""))
        if m.group(2):
            x *= 1e6
        if x >= 1:
            return x
    return None


RE_PIE = re.compile(r"(?i)puerta del sol|comunicacion@|facebook\.com|twitter\.com|gabinete de comunicaci|"
                    r"direcci[oó]n general de medios de comunicaci|esta informaci[oó]n puede ser utilizada|"
                    r"tel[eé]fono 91|^p[aá]gina \d|^\d+$|^www\.")
RE_VINETA = re.compile(r"^\s*[o•·▪•]\s*$|^\s*[o•·▪•]\s+\S")
RE_DEPARTAMENTO = re.compile(r"(?i)consejer|vicepresiden|presidencia|econom|hacienda|empleo|sanidad|educaci|familia|"
                             r"asuntos sociales|pol[ií]ticas sociales|cultura|turismo|deporte|medio ambiente|transporte|"
                             r"vivienda|infraestructura|justicia|interior|inmigraci|cooperaci|ciencia|universidad|"
                             r"digitalizaci|administraci[oó]n local|portavoc|innovaci|mujer|juventud|ordenaci[oó]n")
RE_FIN_FRASE = re.compile(r"[.\)”\"»:]\s*$")


def parse_referencias(texto):
    """Separa el PDF de referencias en acuerdos con su consejería. Devuelve [{consejeria, texto}].

    Formatos: hasta 2016 epígrafes en minúscula («Presidencia, Justicia y Portavocía del Gobierno.»,
    a veces partidos en dos líneas) y viñetas «o»; desde 2017 epígrafes en mayúsculas («CONSEJERÍA DE
    SANIDAD») y viñetas «•». Se quitan los pies de página del gabinete de comunicación."""
    lineas = [l.strip() for l in texto.splitlines()]
    lineas = [l for l in lineas if l and not RE_PIE.search(l)]
    acuerdos, cons, actual, en_cabecera = [], None, None, False

    def es_cabecera(i):
        s = lineas[i]
        if RE_VINETA.match(s) or RE_INICIO_ACUERDO.match(s) or len(s) > 95 or s[0].islower() or s[0] in "*(“\"":
            return False
        if not RE_DEPARTAMENTO.search(s):
            return False
        previa_completa = (i == 0 or en_cabecera or actual is None or not actual["texto"].strip()
                           or RE_FIN_FRASE.search(lineas[i - 1]) is not None)
        if not previa_completa:
            return False
        # lo que sigue (quizá tras una segunda línea del epígrafe) tiene que ser una viñeta o un acuerdo
        for j in (i + 1, i + 2):
            if j < len(lineas) and (RE_VINETA.match(lineas[j]) or RE_INICIO_ACUERDO.match(lineas[j])):
                return True
        return False

    for i, s in enumerate(lineas):
        if es_cabecera(i):
            if actual:
                acuerdos.append(actual)
                actual = None
            if en_cabecera and cons and not RE_FIN_FRASE.search(cons):
                cons += " " + s  # segunda línea del epígrafe
            else:
                cons = s
            en_cabecera = True
            continue
        if RE_VINETA.match(s) or RE_INICIO_ACUERDO.match(s):
            if actual:
                acuerdos.append(actual)
            actual = {"consejeria": cons, "texto": re.sub(r"^[o•·▪•]\s+|^[•·▪•]", "", s)}
            en_cabecera = False
            continue
        if en_cabecera and cons and actual is None:
            cons += " " + s
            continue
        if actual:
            actual["texto"] += " " + s
    if actual:
        acuerdos.append(actual)
    out = []
    for a in acuerdos:
        a["texto"] = re.sub(r"\s+", " ", a["texto"]).strip()
        a["consejeria"] = re.sub(r"\s+", " ", a["consejeria"] or "").strip().rstrip(".") or None
        if a["texto"]:
            out.append(a)
    return out


RE_EMERGENCIA = re.compile(r"(?i)(tramitaci[oó]n|declaraci[oó]n|contrataci[oó]n|r[eé]gimen) de emergencia|"
                           r"tramitados? (por|de) emergencia|por (la v[ií]a de )?emergencia")


def tipo_acuerdo(texto):
    """convalidacion (se convalida un gasto hecho sin procedimiento o sin fiscalización previa),
    modificacion_presupuestaria (transferencias, generaciones, ampliaciones, suplementos, créditos
    extraordinarios) o emergencia (informes que dan cuenta de contratos tramitados por emergencia,
    sin licitación). None para el resto."""
    if re.search(r"(?i)\bse convalid|convalidaci[oó]n (del|de un|de los) gastos?\b", texto[:200]) \
            and not re.search(r"(?i)convalidaci[oó]n de (estudios|t[ií]tulos|cr[eé]ditos acad)", texto):
        return "convalidacion"
    if RE_MODIF.search(texto):
        return "modificacion_presupuestaria"
    if RE_EMERGENCIA.search(texto) and re.search(r"(?i)contrat|suministro|servicio|obra", texto):
        return "emergencia"
    return None


def subtipo_convalidacion(texto):
    """gasto (se convalida un gasto: servicio prestado sin contrato en vigor, facturas de otros
    ejercicios...), omision_fiscalizacion (se convalida la omisión del trámite de fiscalización previa)
    o actuaciones (se convalidan actuaciones administrativas: modificados, ocupaciones, convenios)."""
    t = texto[:300].lower()
    if re.search(r"fiscalizaci[oó]n", t):
        return "omision_fiscalizacion"
    if re.search(r"convalidan? (el|un|los|unos) gastos?|convalidaci[oó]n (del|de un|de los) gasto", t):
        return "gasto"
    return "actuaciones"


def subtipo_modificacion(texto):
    t = texto.lower()
    for clave, pat in (("transferencia", r"transferencias? de cr[eé]dito"), ("generacion", r"generaci[oó]n"),
                       ("ampliacion", r"ampliaci[oó]n"), ("suplemento", r"suplemento"),
                       ("credito_extraordinario", r"cr[eé]ditos? extraordinario"),
                       ("incorporacion", r"incorporaci[oó]n")):
        if re.search(pat, t):
            return clave
    return "otra"


ENTES = {"menciona_sermas": r"SERMAS|Servicio Madrile[nñ]o de Salud|hospital",
         "menciona_amas": r"AMAS|Agencia Madrile[nñ]a de Atenci[oó]n Social|residencias?",
         "menciona_avs": r"\bAVS\b|Agencia de Vivienda Social|IVIMA",
         "menciona_educacion": r"educaci[oó]n|colegio|centros? docentes?|escuelas? infantil|universidad"}


def consejo_gobierno(cache, refrescar_indice=True):
    indice = cg_indice(cache, refrescar=refrescar_indice)
    sesiones, acuerdos = [], []
    for i, (url, fecha_indice) in enumerate(sorted(indice.items())):
        raw = cache.bytes("cg_acuerdos", url)
        if not raw:
            sesiones.append(dict(url=url, fecha=fecha_indice, n_acuerdos=None, descargado=False))
            continue
        tp = cache.ruta("cg_acuerdos_txt", url).with_suffix(".txt")
        if tp.exists():
            texto = tp.read_text(encoding="utf-8")
        else:
            try:
                texto = _texto_pdf(raw)
            except Exception as e:  # noqa: BLE001
                log.warning("PDF ilegible %s: %s", url, e)
                texto = ""
            tp.write_text(texto, encoding="utf-8")
        fecha = _fecha_pdf(url, texto) or fecha_indice
        lista = parse_referencias(texto)
        sesiones.append(dict(url=url, fecha=fecha, n_acuerdos=len(lista), descargado=True,
                             n_caracteres=len(texto)))
        for j, a in enumerate(lista):
            tipo = tipo_acuerdo(a["texto"])
            if not tipo:
                continue
            fila = dict(id_acuerdo=f"{url.rsplit('/', 1)[-1]}#{j}", fecha=fecha, url=url, consejeria=a["consejeria"],
                        tipo=tipo, subtipo=(subtipo_convalidacion(a["texto"]) if tipo == "convalidacion" else
                                            subtipo_modificacion(a["texto"]) if tipo == "modificacion_presupuestaria" else None),
                        importe_eur=_importe_euros(a["texto"]), texto=a["texto"][:4000])
            for k, pat in ENTES.items():
                fila[k] = bool(re.search(pat, a["texto"], re.I))
            acuerdos.append(fila)
        if i % 100 == 0:
            print(f"[gasto_oculto] Consejo de Gobierno {i}/{len(indice)} sesiones, {len(acuerdos)} acuerdos", flush=True)
    return sesiones, acuerdos


# --- 3. Contratos menores de sanidad ---------------------------------------------------------------
UMBRAL_INICIO = date(2018, 3, 9)  # entrada en vigor de la LCSP 2017 (15.000 / 40.000 € sin IVA)
RE_PERSONA = re.compile(r"^[0-9XYZKLM]\d{7}[A-Z]$")
AND_CKAN = ("https://www.juntadeandalucia.es/datosabiertos/portal/api/3/action/package_show"
            "?id=contratacion-menor-plataforma-de-contratacion-andalucia-{anio}")
RE_ORG_SANITARIO_AND = re.compile(r"(?i)servicio andaluz de salud|sanitari|hospital|salud|transfusi|emergencias sanitarias")
SOCRATA = "https://analisi.transparenciacatalunya.cat/resource/ybgg-dgi6.json"


def _nif(v):
    v = re.sub(r"[^0-9A-Z]", "", norm(v))
    return v or None


def tipo_normalizado(t):
    n = norm(t)
    if n.startswith("SUMINISTR") or n.startswith("SUBMINISTR"):
        return "Suministros"
    if n.startswith("SERVEI") or n.startswith("SERVICI"):
        return "Servicios"
    if n.startswith("OBRA"):
        return "Obras"
    return "Otros"


GENERICAS = set("""SUMINISTRO SUMINISTROS SUBMINISTRAMENT SUBMINISTRAMENTS ADQUISICION ADQUISICIONES COMPRA COMPRAS
SERVICIO SERVICIOS SERVEI SERVEIS CONTRATO CONTRACTE MENOR CONTRATACION ADQUISICIO DE DEL LA LAS LOS EL PARA POR CON Y E EN
A AL UN UNA UNOS UNAS D DELS LES ELS PER I O U SU SUS""".split())


def clave_titulo(t):
    """«Objeto parecido» sin CPV: las dos primeras palabras con contenido del título
    («SUMINISTRO DE BATA QUIRÚRGICA ESTÉRIL» -> «TIT BATA QUIRURGICA»)."""
    pal = [w for w in re.findall(r"[A-Z0-9]+", norm(t)) if w not in GENERICAS and len(w) > 2 and not w.isdigit()]
    return ("TIT " + " ".join(pal[:2])) if pal else None


class _Grupos:
    def __init__(self):
        self.g = defaultdict(lambda: [0, 0.0, 0.0, None])  # n, importe, max, nombre

    def add(self, clave, importe, nombre):
        x = self.g[clave]
        x[0] += 1
        x[1] += importe
        x[2] = max(x[2], importe)
        x[3] = x[3] or nombre

    def filas(self, ccaa, cod_ccaa, fuente):
        for (anio, organo, nif, tipo, clave), (n, imp, mx, nombre) in self.g.items():
            yield dict(cod_ccaa=cod_ccaa, ccaa=ccaa, fuente=fuente, anio=anio, organo=organo, nif_adjudicatario=nif,
                       nombre_adjudicatario=nombre, tipo_contrato=tipo, clave_objeto=clave, n_contratos=n,
                       importe_sin_iva_eur=round(imp, 2), importe_max_eur=round(mx, 2))


def _fecha_iso(v):
    """'2024-02-20T00:00:00+0100' o '17/01/2025' (los CSV de Andalucía cambian de formato en 2025)."""
    t = str(v or "").strip()
    m = re.match(r"(\d{4})-(\d{2})-(\d{2})", t)
    d = (m.group(1), m.group(2), m.group(3)) if m else None
    if not d:
        m = re.match(r"(\d{1,2})/(\d{1,2})/(\d{4})", t)
        d = (m.group(3), m.group(2), m.group(1)) if m else None
    if not d:
        return None
    try:
        return date(int(d[0]), int(d[1]), int(d[2]))
    except ValueError:
        return None


def _num_csv(v):
    """'9588' / '31.34' / '11119,9' / '1.234,56' -> float."""
    t = str(v or "").strip().replace(" ", "")
    if not t:
        return None
    if "," in t:
        t = t.replace(".", "").replace(",", ".")
    try:
        return float(t)
    except ValueError:
        return None


def menores_andalucia(cache, desde=2018):
    def _anio(anio):
        def _f():
            r = _get(AND_CKAN.format(anio=anio))
            if r.status_code != 200 or not r.json().get("success"):
                return {"filas": [], "cob": None}
            res = [x for x in r.json()["result"]["resources"] if (x.get("format") or "").upper() == "CSV"]
            if not res:
                return {"filas": [], "cob": None}
            url = re.sub(r"^https?://[^/]+/datosabiertos", "https://www.juntadeandalucia.es/datosabiertos", res[0]["url"])
            raw = _get(url, timeout=(30, 1800)).content
            if raw[:2] == b"PK":
                import zipfile
                with zipfile.ZipFile(io.BytesIO(raw)) as z:
                    raw = z.read(next(n for n in z.namelist() if n.lower().endswith(".csv")))
            for enc in ("utf-8-sig", "cp1252", "latin1"):
                try:
                    t = raw.decode(enc)
                    break
                except UnicodeDecodeError:
                    continue
            del raw
            sep = "|" if t[:3000].count("|") > t[:3000].count(";") else ";"
            lector = csv.DictReader(io.StringIO(t), delimiter=sep)
            lector.fieldnames = [norm(c).replace(" ", "_") for c in lector.fieldnames]
            grupos, n, n_org, n_fuera = _Grupos(), 0, 0, 0
            for x in lector:
                n += 1
                org = " ".join((x.get("ORGANO_CONTRATACION") or "").split())
                if not RE_ORG_SANITARIO_AND.search(org) or re.search(r"(?i)prevenci[oó]n de riesgos|seguridad y salud en el trabajo", org):
                    continue
                n_org += 1
                fe = _fecha_iso(x.get("FECHA_ADJUDICACION")) or _fecha_iso(x.get("FECHA_FORMALIZACION"))
                if not fe or fe < UMBRAL_INICIO or fe.year != anio or fe > date.today():
                    n_fuera += 1
                    continue
                imp = _num_csv(x.get("IMPORTE_ADJUDICACION_SIN_IVA"))
                if imp is None or imp <= 0:
                    continue
                nifs = [v for v in (x.get("NIF_ADJUDICATARIO") or "").split(";") if v.strip()]
                noms = [v for v in (x.get("ADJUDICATARIO_DENOMINACION") or "").split(";") if v.strip()]
                if len(nifs) != 1:  # varias empresas: no se puede atribuir el importe
                    continue
                nif = _nif(nifs[0])
                if not nif or RE_PERSONA.match(nif):
                    nif, nombre = "PERSONA_FISICA", None
                else:
                    nombre = " ".join(noms[0].split()) if noms else None
                # el SAS es un solo órgano de contratación: se separa por provincia de ejecución
                prov = " ".join((x.get("LUGAR_EJECUCION_DENOMINACION") or "").split()) or None
                organo = f"{org} ({prov})" if prov and re.search(r"(?i)servicio andaluz de salud", org) else org
                clave = clave_titulo(x.get("TITULO") or x.get("DESCRIPCION"))
                grupos.add((anio, organo, nif, tipo_normalizado(x.get("TIPO_CONTRATO")), clave), imp, nombre)
            return {"filas": list(grupos.filas("Andalucía", "01", "and_junta")),
                    "cob": dict(fuente="and_junta", anio=anio, filas_leidas=n, filas_sanidad=n_org,
                                fuera_de_plazo=n_fuera, url=url)}
        return cache.json(f"menores_and_v2_{anio}", _f, refrescar=anio >= date.today().year)

    filas, cob = [], []
    for anio in range(desde, date.today().year + 1):
        d = _anio(anio)
        filas += d["filas"]
        if d["cob"]:
            cob.append(d["cob"])
        print(f"[gasto_oculto] menores Andalucía {anio}: {len(d['filas'])} grupos", flush=True)
    return filas, cob


def menores_cataluna(cache, desde=2018):
    cols = ("nom_organ,identificacio_adjudicatari,denominacio_adjudicatari,codi_cpv,tipus_contracte,"
            "import_adjudicacio_sense,data_adjudicacio_contracte,data_formalitzacio_contracte,data_publicacio_contracte,id_intern")

    def _f():
        out, off, pagina = [], 0, 50000
        donde = ("procediment='Contracte menor' and identificacio_adjudicatari is not null and "
                 "(nom_departament_ens='Departament de Salut' or starts_with(nom_departament_ens, 'ICS'))")
        while True:
            r = _get(SOCRATA, params={"$select": cols, "$where": donde, "$order": "id_intern",
                                      "$limit": pagina, "$offset": off}, timeout=(30, 900))
            if r.status_code != 200:
                raise RuntimeError(f"Socrata ybgg-dgi6: {r.status_code} {r.text[:300]}")
            d = r.json()
            out += d
            print(f"[gasto_oculto] menores Cataluña: {len(out)} filas", flush=True)
            if len(d) < pagina:
                return out
            off += pagina

    regs = cache.json("menores_cat_salut", _f, refrescar=False)
    grupos, n, n_fuera = _Grupos(), 0, 0
    for x in regs:
        nifs = [v.strip() for v in str(x.get("identificacio_adjudicatari") or "").split("||") if v.strip()]
        imps = [v.strip() for v in str(x.get("import_adjudicacio_sense") or "").split("||") if v.strip()]
        noms = [v.strip() for v in str(x.get("denominacio_adjudicatari") or "").split("||") if v.strip()]
        if len(nifs) != 1 or len(imps) != 1:
            continue
        n += 1
        fe = (_fecha_iso(x.get("data_adjudicacio_contracte")) or _fecha_iso(x.get("data_formalitzacio_contracte"))
              or _fecha_iso(x.get("data_publicacio_contracte")))
        if not fe or fe < UMBRAL_INICIO or fe.year < desde or fe > date.today():
            n_fuera += 1
            continue
        try:
            imp = float(imps[0])
        except ValueError:
            continue
        if imp <= 0:
            continue
        nif = _nif(nifs[0])
        if not nif or RE_PERSONA.match(nif) or "*" in nifs[0]:
            nif, nombre = "PERSONA_FISICA", None
        else:
            nombre = noms[0] if noms else None
        cpv = re.sub(r"\D", "", str(x.get("codi_cpv") or ""))[:3]
        clave = f"CPV {cpv}" if cpv else clave_titulo(x.get("objecte_contracte") or x.get("denominacio"))
        grupos.add((fe.year, x.get("nom_organ"), nif, tipo_normalizado(x.get("tipus_contracte")), clave), imp, nombre)
    cob = [dict(fuente="cat_pscp", anio=None, filas_leidas=len(regs), filas_sanidad=n, fuera_de_plazo=n_fuera,
                url=SOCRATA + " (procediment = 'Contracte menor', Departament de Salut e ICS)")]
    return list(grupos.filas("Cataluña", "09", "cat_pscp")), cob


# --- fuente dlt --------------------------------------------------------------------------------
@dlt.source(name="gasto_oculto")
def gasto_oculto(cache_dir: str | None = None, desde_cuenta: int = 2016, desde_menores: int = 2018,
                 partes: tuple = ("cuenta_general", "cataluna", "consejo_gobierno", "menores")):
    cache = _Cache(cache_dir)
    recursos = []
    if "cuenta_general" in partes:
        liq, mod, cuadre = cuenta_general(cache, desde=desde_cuenta)
        recursos += [
            dlt.resource(liq, name="gasto_oculto_cm_liquidacion", write_disposition="replace"),
            dlt.resource(mod, name="gasto_oculto_cm_modificaciones", write_disposition="replace"),
            dlt.resource(cuadre, name="gasto_oculto_cm_cuadre", write_disposition="replace"),
        ]
    if "cataluna" in partes:
        recursos.append(dlt.resource(execucio_cataluna(cache), name="gasto_oculto_cat_execucio",
                                     write_disposition="replace"))
    if "consejo_gobierno" in partes:
        sesiones, acuerdos = consejo_gobierno(cache)
        recursos += [
            dlt.resource(sesiones, name="gasto_oculto_cm_sesiones", write_disposition="replace"),
            dlt.resource(acuerdos, name="gasto_oculto_cm_acuerdos", write_disposition="replace"),
        ]
    if "menores" in partes:
        fa, ca = menores_andalucia(cache, desde=desde_menores)
        fc, cc = menores_cataluna(cache, desde=desde_menores)
        recursos += [
            dlt.resource(fa + fc, name="gasto_oculto_menores_grupos", write_disposition="replace",
                         columns={"clave_objeto": {"data_type": "text"}, "nombre_adjudicatario": {"data_type": "text"}}),
            dlt.resource(ca + cc, name="gasto_oculto_menores_cobertura", write_disposition="replace",
                         columns={"anio": {"data_type": "bigint"}}),
        ]
    return recursos
