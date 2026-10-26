"""Extracción y normalización de fechas según las 5 reglas jerárquicas del robot.

Reglas por orden de fiabilidad:
1. plataforma: fecha estructurada de la plataforma (API JSON, campos data-*).
2. contenido: fecha dentro del documento (sesión del acta, año del presupuesto).
3. titulo: año o fecha en el título del enlace o nombre de archivo.
4. pdf: metadatos /CreationDate o /ModDate del PDF.
5. last_modified: cabecera Last-Modified SOLO en ficheros estáticos descargables.
"""

from __future__ import annotations

import email.utils
import io
import re
from datetime import date, datetime
from typing import Any, Tuple

from pypdf import PdfReader

MESES = {
    # Castellano
    "enero": 1, "febrero": 2, "marzo": 3, "abril": 4, "mayo": 5, "junio": 6,
    "julio": 7, "agosto": 8, "septiembre": 9, "setiembre": 9, "octubre": 10,
    "noviembre": 11, "diciembre": 12,
    # Catalán
    "gener": 1, "febrer": 2, "març": 3, "marc": 3, "maig": 5, "juny": 6,
    "juliol": 7, "agost": 8, "setembre": 9, "desembre": 12,
    # Gallego
    "xaneiro": 1, "febreiro": 2, "maio": 5, "xuño": 6, "xullo": 7,
    # Euskera
    "urtarrila": 1, "otsaila": 2, "martxoa": 3, "apirila": 4, "maiatza": 5,
    "ekaina": 6, "uztaila": 7, "abuztua": 8, "iraila": 9, "urria": 10,
    "azaroa": 11, "abendua": 12,
}

RE_FECHA_TEXTO = re.compile(
    r"\b(\d{1,2})\s+(?:de\s+)?([a-zçñáéíóú]+)\s+(?:de\s+|del\s+)?(20\d{2})\b",
    re.I,
)
RE_FECHA_ISO_O_BARRA = re.compile(
    r"\b(?:(20\d{2})[-/.](0[1-9]|1[0-2])[-/.](0[1-9]|[12]\d|3[01])|(0[1-9]|[12]\d|3[01])[-/.](0[1-9]|1[0-2])[-/.](20\d{2}))\b"
)
RE_ANIO = re.compile(r"\b(20[12]\d)\b")

EXTENSIONES_ESTATICAS = {
    ".pdf", ".xlsx", ".xls", ".csv", ".ods", ".doc", ".docx", ".zip",
    ".odt", ".xml", ".json", ".parquet",
}


def parse_fecha_iso(texto: str) -> date | None:
    """Intenta parsear cadenas ISO como YYYY-MM-DD o YYYY-MM-DDTHH:MM:SS."""
    if not texto:
        return None
    try:
        t = texto.strip().split("T")[0].split(" ")[0]
        return date.fromisoformat(t)
    except Exception:
        return None


def parse_fecha_contenido(texto: str) -> date | None:
    """Extrae la fecha más reciente mencionada dentro de un texto o documento."""
    if not texto:
        return None

    candidatas: list[date] = []

    # 1. Búsqueda de fechas con nombre de mes
    for m in RE_FECHA_TEXTO.finditer(texto):
        dia_s, mes_s, anio_s = m.groups()
        mes_norm = mes_s.lower()
        if mes_norm in MESES:
            try:
                dia = int(dia_s)
                mes = MESES[mes_norm]
                anio = int(anio_s)
                candidatas.append(date(anio, mes, dia))
            except Exception:
                continue

    # 2. Búsqueda de fechas numéricas YYYY-MM-DD o DD-MM-YYYY
    for m in RE_FECHA_ISO_O_BARRA.finditer(texto):
        y1, m1, d1, d2, m2, y2 = m.groups()
        try:
            if y1:
                candidatas.append(date(int(y1), int(m1), int(d1)))
            elif y2:
                candidatas.append(date(int(y2), int(m2), int(d2)))
        except Exception:
            continue

    # Filtrar fechas inverosímiles (anteriores a 2010 o posteriores al año próximo)
    anio_actual = date.today().year
    validas = [f for f in candidatas if 2010 <= f.year <= anio_actual + 1]
    if validas:
        return max(validas)

    # 3. Si solo hay año en el texto
    anios = [int(a) for a in RE_ANIO.findall(texto) if 2010 <= int(a) <= anio_actual + 1]
    if anios:
        return date(max(anios), 1, 1)

    return None


def parse_fecha_titulo(titulo: str) -> date | None:
    """Extrae fecha o año presente en el título de un documento o enlace."""
    if not titulo:
        return None

    # Primero buscar fecha completa en título
    f = parse_fecha_contenido(titulo)
    if f:
        return f

    # Buscar año explícito
    anios = [int(a) for a in RE_ANIO.findall(titulo)]
    anio_actual = date.today().year
    validos = [a for a in anios if 2010 <= a <= anio_actual + 1]
    if validos:
        return date(max(validos), 1, 1)

    return None


def parse_fecha_pdf(pdf_bytes_o_stream: bytes | io.BytesIO) -> date | None:
    """Extrae /CreationDate o /ModDate de los metadatos de un PDF."""
    try:
        stream = io.BytesIO(pdf_bytes_o_stream) if isinstance(pdf_bytes_o_stream, bytes) else pdf_bytes_o_stream
        reader = PdfReader(stream)
        metadata = reader.metadata
        if not metadata:
            return None

        # Formato PDF típico: D:YYYYMMDDHHmmSS...
        fechas_raw = [metadata.creation_date, metadata.modification_date]
        candidatas: list[date] = []
        for dt in fechas_raw:
            if isinstance(dt, datetime):
                candidatas.append(dt.date())
            elif isinstance(dt, str):
                m = re.search(r"D:(\d{4})(\d{2})(\d{2})", dt)
                if m:
                    try:
                        candidatas.append(date(int(m.group(1)), int(m.group(2)), int(m.group(3))))
                    except Exception:
                        pass

        anio_actual = date.today().year
        validas = [d for d in candidatas if 2010 <= d.year <= anio_actual + 1]
        if validas:
            return max(validas)
    except Exception:
        pass
    return None


def parse_fecha_last_modified(header_val: str, url: str) -> date | None:
    """Extrae la fecha de Last-Modified SOLO si la URL es un recurso estático."""
    if not header_val or not url:
        return None

    # Comprobar que la URL termina en una extensión de archivo estática
    url_limpia = url.split("?")[0].lower()
    es_estatico = any(url_limpia.endswith(ext) for ext in EXTENSIONES_ESTATICAS)
    if not es_estatico:
        return None

    try:
        dt = email.utils.parsedate_to_datetime(header_val)
        d = dt.date()
        if 2010 <= d.year <= date.today().year + 1:
            return d
    except Exception:
        pass
    return None


def resolver_fecha_elemento(
    fecha_plataforma: str | date | None = None,
    texto_contenido: str | None = None,
    titulo: str | None = None,
    pdf_bytes: bytes | None = None,
    header_last_modified: str | None = None,
    url_recurso: str | None = None,
) -> Tuple[date | None, str | None]:
    """Aplica la jerarquía de las 5 reglas para determinar la fecha y la regla de origen."""
    # Regla 1: plataforma
    if fecha_plataforma:
        if isinstance(fecha_plataforma, date):
            return fecha_plataforma, "plataforma"
        p = parse_fecha_iso(str(fecha_plataforma))
        if p:
            return p, "plataforma"

    # Regla 2: contenido
    if texto_contenido:
        c = parse_fecha_contenido(texto_contenido)
        if c:
            return c, "contenido"

    # Regla 3: titulo
    if titulo:
        t = parse_fecha_titulo(titulo)
        if t:
            return t, "titulo"

    # Regla 4: pdf
    if pdf_bytes:
        pdf_date = parse_fecha_pdf(pdf_bytes)
        if pdf_date:
            return pdf_date, "pdf"

    # Regla 5: last_modified (solo binarios estáticos)
    if header_last_modified and url_recurso:
        lm = parse_fecha_last_modified(header_last_modified, url_recurso)
        if lm:
            return lm, "last_modified"

    return None, None
