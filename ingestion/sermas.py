"""Fuente dlt del Servicio Madrileño de Salud (SERMAS): listas de espera y libre elección.

Todo sale de la Consejería de Sanidad de la Comunidad de Madrid (comunidad.madrid), descarga
abierta, sin formularios:

  sermas_memoria_le          Memoria anual del SERMAS, capítulo «Lista de espera»: situación a
                             31 de diciembre de la lista de primera consulta (total y 10
                             especialidades), de primera prueba diagnóstica (8 técnicas) y de la
                             lista quirúrgica (LEQ). Incluye la fila «Número de pacientes sin fecha
                             asignada», que NO sale en el informe mensual. 2021-2025 de las hojas de
                             datos abiertos (XLSX en ZIP); 2015-2020 del PDF de la memoria completa
                             (bvirtual, pdfplumber). En la memoria 2024 la hoja de pruebas es una
                             copia de la de 2023 (mismo encabezado «Enero-diciembre 2023»): ese año
                             las pruebas se toman del PDF del Resumen Ejecutivo 2024.
  sermas_mensual             Informe mensual de listas de espera (CSV de cada mes, desde 2017) de
                             consultas externas (le_c_*), pruebas diagnósticas (le_t_*) y lista
                             quirúrgica (le_q_*): las cifras que se difunden cada mes.
  sermas_le_balance          Memoria anual del SERMAS, «Libertad de elección»: citas entrantes y
                             salientes de libre elección por hospital (cada memoria trae su año y
                             el anterior). XLSX 2021-2023 (la de 2024 y 2025 ya no la traen) y PDF
                             de la memoria completa 2015-2020.
  sermas_le_especialidad     Memoria anual del SERMAS, «Balance por especialidad»: primeras
                             consultas y consultas realizadas por libre elección (2022-2025).
  sermas_le_hospital         Memoria anual de cada hospital, hoja «Consultas Libre Elección»:
                             citas entrantes y salientes por especialidad (2021-2024, XLSX).
  sermas_consultas_hospital  Memoria anual de cada hospital, hoja «Consultas Externas»: primeras
                             consultas y sucesivas por especialidad (2021-2024, XLSX).

Página índice de las memorias: https://www.comunidad.madrid/salud/memorias-e-informes-servicio-madrileno-salud
Informes mensuales: https://www.comunidad.madrid/salud/lista-espera-consultas-externas,
.../lista-espera-pruebas-diagnosticas-terapeuticas y .../lista-espera-quirurgica
"""

import io
import logging
import re
import unicodedata
import zipfile
from urllib.parse import urljoin

import dlt
import requests
from functools import lru_cache

log = logging.getLogger(__name__)

CM = "https://www.comunidad.madrid"
PAG_MEMORIAS = CM + "/salud/memorias-e-informes-servicio-madrileno-salud"
PAG_MENSUAL = {
    "consulta": CM + "/salud/lista-espera-consultas-externas",
    "prueba": CM + "/salud/lista-espera-pruebas-diagnosticas-terapeuticas",
    "quirurgica": CM + "/salud/lista-espera-quirurgica",
}
UA = {"User-Agent": "Mozilla/5.0 (SpainFacts; datos abiertos)"}

# Memoria completa en PDF (biblioteca virtual de la Comunidad de Madrid), de la página índice.
MEMORIA_PDF = {
    2015: "https://gestiona3.madrid.org/bvirtual/BVCM017858.pdf",
    2016: "https://gestiona3.madrid.org/bvirtual/BVCM017969.pdf",
    2017: "https://gestiona3.madrid.org/bvirtual/BVCM020190.pdf",
    2018: "https://gestiona3.madrid.org/bvirtual/BVCM020283.pdf",
    2019: "https://gestiona3.madrid.org/bvirtual/BVCM050222.pdf",
    2020: "https://gestiona3.madrid.org/bvirtual/BVCM050404.pdf",
}
# Datos abiertos (XLSX) de la memoria del SERMAS.
MEMORIA_ZIP = {
    2021: CM + "/docs/assets/2022/06/30/memoria_sermas_2021_datos_abiertos.zip",
    2022: CM + "/docs/assets/2023/07/26/datos_abiertos_memoria_2022.zip",
    2023: CM + "/docs/assets/2024/07/08/datos_abiertos_memoria_sermas_2023.zip",
    2024: CM + "/docs/assets/2025/10/30/3.datos_abiertos_memoria_2024.zip",
    2025: CM + "/docs/2026-07/datos-abiertos-memoria-2025.zip",
}
RESUMEN_EJECUTIVO_PDF = {
    2024: CM + "/docs/assets/2025/10/30/resumen_ejecutivo_memoria_sermas_2024.pdf",
}

PRUEBAS = ["Tomografía computerizada", "Resonancia magnética", "Ecografía", "Mamografía",
           "Endoscopia", "Hemodinámica", "Ecocardiografía", "Ergometría"]
CONSULTAS = ["Total", "Ginecología", "Oftalmología", "Traumatología", "Dermatología",
             "Otorrinolaringología", "Neurología", "Cirugía", "Urología", "Digestivo", "Cardiología"]

MESES = {"ENERO": 1, "FEBRERO": 2, "MARZO": 3, "ABRIL": 4, "MAYO": 5, "JUNIO": 6, "JULIO": 7,
         "AGOSTO": 8, "SEPTIEMBRE": 9, "OCTUBRE": 10, "NOVIEMBRE": 11, "DICIEMBRE": 12,
         "ENE": 1, "FEB": 2, "MAR": 3, "ABR": 4, "MAY": 5, "JUN": 6, "JUL": 7, "AGO": 8,
         "SEP": 9, "SEPT": 9, "OCT": 10, "NOV": 11, "DIC": 12}


def _get(url, timeout=300):
    r = requests.get(url, headers=UA, timeout=timeout)
    r.raise_for_status()
    return r


def _sin_tildes(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")


def _num(v):
    """'1.234' / '12,5' / 1234 / '-' -> float o None."""
    if v is None:
        return None
    if isinstance(v, (int, float)):
        return float(v)
    s = str(v).strip().replace("\xa0", "").replace(" ", "").replace("%", "")
    if s in ("", "-", "–"):
        return None
    if re.match(r"^-?\d{1,3}(\.\d{3})+$", s):
        return float(s.replace(".", ""))
    if re.match(r"^-?\d+(\.\d{3})*,\d+$", s):
        return float(s.replace(".", "").replace(",", "."))
    try:
        return float(s)
    except ValueError:
        return None


def _openpyxl(contenido: bytes):
    import openpyxl
    return openpyxl.load_workbook(io.BytesIO(contenido), read_only=True, data_only=True)


def _filas(ws):
    for row in ws.iter_rows(values_only=True):
        yield [c for c in row]


def _texto_fila(row):
    return " ".join(str(c) for c in row if c is not None and not isinstance(c, (int, float))).strip()


def _nums_fila(row):
    out = []
    for c in row:
        if isinstance(c, (int, float)):
            out.append(float(c))
        elif c is not None and re.match(r"^\s*(-|–|\d[\d.,]*)\s*$", str(c)):
            out.append(_num(c))
    return out


# ---------------------------------------------------------------- lista de espera (memoria)

# Etiqueta (sin tildes, minúsculas) -> campo. El orden importa (la primera que encaja).
CAMPOS_LE = [
    (r"sin fecha", "sin_fecha"),
    (r"de 0 a 30", "t0_30"),
    (r"31-60|31 - 60", "t31_60"),
    (r"61-90|61 - 90", "t61_90"),
    (r"> ?90", "t_mas_90"),
    (r"prueba de control", "control"),
    (r"entradas por|^tasa.*entrad", "entradas_tasa_1000"),
    (r"total de entradas", "entradas"),
    (r"pacientes atendidos durante|total de pacientes atendidos|pacientes atendidos en el periodo", "atendidos"),
    (r"total de salidas", "salidas"),
    (r"espera media", "espera_media_atendidos"),
    (r"prospectiva", "demora_prospectiva"),
    (r"tiempo medio", "tiempo_medio_pendientes"),
    (r"^tasa", "tasa_1000"),
    (r"espera estructural para (la realizacion de )?una primera|espera estructural para una primera", "estructural"),
]


def _campo_le(etiqueta: str):
    e = _sin_tildes(etiqueta).lower().strip()
    for patron, campo in CAMPOS_LE:
        if re.search(patron, e):
            return campo
    return None


def _validar_le(fila):
    """¿Los tramos suman el total estructural con la fila «sin fecha» (True), sin ella (False)?"""
    partes = [fila.get(k) for k in ("t0_30", "t31_60", "t61_90", "t_mas_90")]
    if fila.get("estructural") is None or any(p is None for p in partes[:3]):
        return None
    base = sum(p or 0 for p in partes)
    if abs(base + (fila.get("sin_fecha") or 0) - fila["estructural"]) <= 1:
        return True
    if abs(base - fila["estructural"]) <= 1:
        return False
    return None


def _hoja_le_xlsx(ws, tipo, anio, url, hoja):
    """Hoja 'Consultas' o 'Pruebas-Tcas Diagnósticas' de la memoria (XLSX)."""
    nombres = CONSULTAS if tipo == "consulta" else PRUEBAS
    filas = list(_filas(ws))
    cab = " ".join(_texto_fila(r) for r in filas[:4])
    m = re.search(r"diciembre (\d{4})", _sin_tildes(cab).lower())
    anio_hoja = int(m.group(1)) if m else None
    pob = re.search(r"Poblaci\S*n:?\s*([\d.]+)", cab)
    datos = {}
    seccion_salidas = False
    for r in filas:
        etiqueta = _texto_fila(r)
        if not etiqueta:
            continue
        if re.search(r"n[uú]mero de salidas|total de salidas del registro", _sin_tildes(etiqueta).lower()):
            seccion_salidas = True
        campo = _campo_le(etiqueta)
        nums = _nums_fila(r)
        if campo is None or len(nums) < len(nombres) - 1:
            continue
        if campo == "tasa_1000" and "entradas" in datos:
            campo = "salidas_tasa_1000" if seccion_salidas else "entradas_tasa_1000"
        if campo in datos:
            continue
        datos[campo] = (nums + [None] * len(nombres))[: len(nombres)]
    for i, nombre in enumerate(nombres):
        fila = {"anio": anio, "tipo": tipo, "especialidad": nombre,
                "poblacion_asignada": _num(pob.group(1)) if pob else None,
                "anio_hoja": anio_hoja, "fuente_url": url, "fuente_doc": f"datos abiertos XLSX, hoja {hoja}"}
        for campo, valores in datos.items():
            fila[campo] = valores[i]
        v = _validar_le(fila)
        fila["cuadra"] = v is not None
        fila["sin_fecha_en_total"] = v if fila.get("sin_fecha") is not None else None
        yield fila


def _hoja_leq_xlsx(ws, anio, url, hoja):
    fila = {"anio": anio, "tipo": "quirurgica", "especialidad": "Total", "fuente_url": url,
            "fuente_doc": f"datos abiertos XLSX, hoja {hoja}"}
    for r in _filas(ws):
        etiqueta = _sin_tildes(_texto_fila(r)).lower()
        nums = _nums_fila(r)
        if not etiqueta or not nums:
            continue
        v = nums[0]
        _leq_campo(fila, etiqueta, v)
    fila["anio_hoja"] = anio
    return fila


def _leq_campo(fila, e, v):
    reglas = [
        (r"poblacion asignada", "poblacion_asignada"),
        (r"total pacientes", "total_leq"),
        (r"^estructural$|^estructural ", "estructural"),
        (r"rechazo derivacion$|^rechazo derivacion ", "rechazo_derivacion"),
        (r"tnp|transitoriamente", "tnp"),
        (r"demora media estructural", "demora_media"),
        (r"demora media rechazo", "demora_media_rechazo"),
        (r"0.30 d", "t0_30"),
        (r"30.60 d", "t31_60"),
        (r"60.90 d", "t61_90"),
        (r"90.180 d", "t91_180"),
        (r"> ?180", "t_mas_180"),
        (r"total salidas mes", "salidas"),
    ]
    e = e.strip(" .-")
    for patron, campo in reglas:
        if re.search(patron, e) and campo not in fila:
            # En la memoria 2024-2025 los tramos vienen como texto '29.934' (con punto de miles)
            # que openpyxl lee como 29.934: se corrige si es menor que 1000 y tiene decimales.
            if campo.startswith("t") and campo not in ("tnp",) and v is not None and v < 1000 and v != int(v):
                v = round(v * 1000)
            fila[campo] = v
            return


def _memoria_xlsx(anio, url):
    z = zipfile.ZipFile(io.BytesIO(_get(url).content))
    for n in z.namelist():
        base = n.split("/")[-1]
        if not re.search(r"Lista de Espera", base, re.I) or not base.lower().endswith(".xlsx"):
            continue
        wb = _openpyxl(z.read(n))
        for ws in wb.worksheets:
            t = ws.title.strip()
            if t.upper().startswith("LEQ"):
                yield _hoja_leq_xlsx(ws, anio, url, t)
            elif t.lower().startswith("pruebas"):
                yield from _hoja_le_xlsx(ws, "prueba", anio, url, t)
            elif t.lower().startswith("consultas"):
                yield from _hoja_le_xlsx(ws, "consulta", anio, url, t)


@lru_cache(maxsize=16)
def _pdf_texto(url):
    import pdfplumber
    contenido = _get(url, timeout=600).content
    paginas = []
    with pdfplumber.open(io.BytesIO(contenido)) as pdf:
        for p in pdf.pages:
            paginas.append(p.dedupe_chars().extract_text() or "")
    return tuple(paginas)


NUMTOK = re.compile(r"^(-|–|\d{1,3}(?:\.\d{3})+|\d+(?:,\d+)?)$")


def _filas_numericas(texto, n):
    """Filas de n números (o '-') del texto, en orden, con el texto de alrededor.

    Una línea puede traer varias filas pegadas o números de la etiqueta delante ('de 0 a 30
    49.439 ...', '> 90 4.647 ...'): de cada tramo de números de longitud >= n se toman los n
    últimos."""
    filas = []
    previo = []
    for linea in texto.splitlines():
        toks = linea.split()
        tramos, actual, ini = [], [], 0
        for i, t in enumerate(toks + ["|"]):
            if NUMTOK.match(t):
                if not actual:
                    ini = i
                actual.append(t)
            else:
                if len(actual) >= n:
                    tramos.append((ini + len(actual) - n, actual[-n:]))
                actual = []
        if not tramos:
            if filas:
                filas[-1]["despues"] += " " + linea
            previo.append(linea)
            continue
        cursor = 0
        for ini, nums in tramos:
            etiqueta = " ".join(previo + toks[cursor:ini])
            if filas:
                filas[-1]["despues"] += " " + " ".join(toks[cursor:ini])
            filas.append({"nums": [_num(t) for t in nums], "etiqueta": etiqueta, "despues": ""})
            cursor = ini + n
            previo = []
        resto = " ".join(toks[cursor:])
        filas[-1]["despues"] += " " + resto
        previo = [resto] if resto else []
    return filas


def _seccion(paginas, inicio, fin_patrones):
    texto = "\n".join(paginas)
    m = re.search(inicio, texto)
    if not m:
        return None
    resto = texto[m.end():]
    fin = len(resto)
    for p in fin_patrones:
        mf = re.search(p, resto)
        if mf:
            fin = min(fin, mf.start())
    return texto[m.start(): m.end() + fin]


def _le_pdf(texto, tipo, anio, url, doc):
    """Tabla de consultas o de pruebas de la memoria en PDF.

    Se localiza el total estructural y los 4 tramos de espera que lo suman (con o sin la fila
    de «sin fecha asignada»); el resto de filas se asigna por su posición y por el tipo de cifra
    (recuentos grandes frente a tasas y días con decimales), porque las etiquetas vienen partidas
    en varias líneas y en orden distinto según el año."""
    nombres = CONSULTAS if tipo == "consulta" else PRUEBAS
    n = len(nombres)
    filas = _filas_numericas(texto, n)
    pob = re.search(r"Poblaci\S*n:?\s*([\d.]+)", texto)
    asignado = None
    for i in range(len(filas)):
        total = filas[i]["nums"]
        if total[0] is None:
            continue
        for j in range(i + 1, len(filas) - 3):
            tramos = [filas[k]["nums"] for k in range(j, j + 4)]
            base = [sum((t[c] or 0) for t in tramos) for c in range(n)]
            sf = filas[j + 4]["nums"] if j + 4 < len(filas) else None
            if sf and all(total[c] is not None and abs(base[c] + (sf[c] or 0) - total[c]) <= 1 for c in range(n)):
                asignado = (i, j, "dentro")
            elif all(total[c] is not None and abs(base[c] - total[c]) <= 1 for c in range(n)):
                fuera = sf is not None and sf[0] is not None and sf[0] < total[0] and \
                    all(v is None or v == int(v) for v in sf)
                asignado = (i, j, "fuera" if fuera else "no")
            if asignado:
                break
        if asignado:
            break
    if not asignado:
        log.warning("SERMAS PDF %s %s: no cuadran los tramos", anio, tipo)
        return []
    i, j, sf_modo = asignado
    campos = {i: "estructural", j: "t0_30", j + 1: "t31_60", j + 2: "t61_90", j + 3: "t_mas_90"}
    if sf_modo != "no":
        campos[j + 4] = "sin_fecha"
    # Entre el total y los tramos: [prueba de control], tasa, tiempo medio de los pendientes
    decimales = []
    for k in range(i + 1, j):
        nums = filas[k]["nums"]
        enteros = all(v is None or v == int(v) for v in nums)
        if tipo == "prueba" and enteros and "control" not in campos.values():
            campos[k] = "control"
        else:
            decimales.append(k)
    if len(decimales) >= 2:
        campos[decimales[0]] = "tasa_1000"
        campos[decimales[1]] = "tiempo_medio_pendientes"
    elif len(decimales) == 1:
        k = decimales[0]
        txt = _sin_tildes(filas[k]["etiqueta"][-80:] + " " + filas[k]["despues"][:30]).lower()
        campos[k] = "tiempo_medio_pendientes" if "tiempo medio" in txt and "tasa" not in txt else "tasa_1000"
    # Después: entradas, [tasa], atendidos, salidas, [tasa], espera media, demora prospectiva
    tras = [k for k in range(j + 4 + (1 if sf_modo != "no" else 0), len(filas))]
    grandes = [k for k in tras if all(v is None or v == int(v) for v in filas[k]["nums"])
               and (filas[k]["nums"][0] or 0) >= 1000]
    for k, campo in zip(grandes[:3], ["entradas", "atendidos", "salidas"]):
        campos[k] = campo
    if len(grandes) >= 3:
        entre = [k for k in tras if grandes[0] < k < grandes[1]]
        if entre:
            campos[entre[0]] = "entradas_tasa_1000"
        finales = [k for k in tras if k > grandes[2]]
        if len(finales) >= 3:
            campos[finales[0]], campos[finales[1]], campos[finales[2]] = \
                "salidas_tasa_1000", "espera_media_atendidos", "demora_prospectiva"
        elif len(finales) == 2:
            campos[finales[0]], campos[finales[1]] = "espera_media_atendidos", "demora_prospectiva"
    out = []
    for c, nombre in enumerate(nombres):
        fila = {"anio": anio, "tipo": tipo, "especialidad": nombre,
                "poblacion_asignada": _num(pob.group(1)) if pob else None, "anio_hoja": anio,
                "fuente_url": url, "fuente_doc": doc,
                "sin_fecha_en_total": {"dentro": True, "fuera": False}.get(sf_modo)}
        for k, campo in campos.items():
            fila[campo] = filas[k]["nums"][c]
        fila["cuadra"] = True
        out.append(fila)
    return out


def _leq_pdf(texto, anio, url, doc):
    fila = {"anio": anio, "tipo": "quirurgica", "especialidad": "Total", "anio_hoja": anio,
            "fuente_url": url, "fuente_doc": doc}
    for linea in texto.splitlines():
        e = _sin_tildes(linea).replace("‐", "-")
        # fuera la parte numérica de la etiqueta del tramo ('0-30 días', '> 180 días')
        sin_tramo = re.sub(r"\d+\s*-\s*\d+\s*d\S*s|>\s*\d+\s*d\S*s", " ", e)
        toks = sin_tramo.split()
        # el PDF parte a veces una cifra en dos ('2 8.323' = 28.323)
        unidos = []
        for t in toks:
            if unidos and re.match(r"^\d$", unidos[-1]) and re.match(r"^\d{1,2}\.\d{3}$", t):
                unidos[-1] = unidos[-1] + t
            else:
                unidos.append(t)
        nums = [t for t in unidos if NUMTOK.match(t)]
        if not nums:
            continue
        etiqueta = re.sub(r"\s+", " ", e.lower().replace("*", "")).strip()
        _leq_campo(fila, etiqueta, _num(nums[0]))
    return fila


def _memoria_pdf(anio, url):
    paginas = _pdf_texto(url)
    doc = "PDF de la memoria completa"
    leq = _seccion(paginas, r"Registro Unificado de Lista de Espera Qui", [r"Lista de Espera Pruebas"])
    pru = _seccion(paginas, r"Lista de Espera Pruebas ?/ ?T\S+cnicas Diagn\S+sticas", [r"Lista de Espera Consultas"])
    con = _seccion(paginas, r"Lista de Espera Consultas", [r"ACTIVIDAD EN CENTROS CONCERTADOS", r"\nCALIDAD\n", r"Tiempo medio de absorci\S+n en d\S+as de los pacientes en espera estructural para una primera consulta"])
    if leq:
        yield _leq_pdf(leq, anio, url, doc)
    if pru:
        yield from _le_pdf(pru, "prueba", anio, url, doc)
    if con:
        yield from _le_pdf(con + "\n", "consulta", anio, url, doc)


def _pruebas_resumen(anio, url):
    paginas = _pdf_texto(url)
    pru = _seccion(paginas, r"(?i)lista de espera (de )?pruebas", [r"(?i)lista de espera (de )?consultas"])
    if not pru:
        return []
    return _le_pdf(pru, "prueba", anio, url, "PDF del Resumen Ejecutivo")


def memoria_le():
    previas = {}
    for anio, url in MEMORIA_PDF.items():
        try:
            for f in _memoria_pdf(anio, url):
                yield f
        except Exception as e:  # noqa: BLE001
            log.warning("SERMAS memoria PDF %s: %s", anio, e)
    for anio, url in MEMORIA_ZIP.items():
        filas = list(_memoria_xlsx(anio, url))
        # Hoja copiada de la memoria anterior (pasa con las pruebas en la memoria 2024): mismas cifras
        sustituir = set()
        for tipo in ("prueba", "consulta"):
            actual = tuple(f.get("estructural") for f in filas if f["tipo"] == tipo)
            if actual and previas.get(tipo) == actual:
                sustituir.add(tipo)
            previas[tipo] = actual
        for f in filas:
            if f["tipo"] not in sustituir:
                yield f
        for tipo in sustituir:
            log.warning("SERMAS %s: la hoja de %s repite la de %s; se usa el Resumen Ejecutivo", anio, tipo, anio - 1)
            if tipo == "prueba" and anio in RESUMEN_EJECUTIVO_PDF:
                yield from _pruebas_resumen(anio, RESUMEN_EJECUTIVO_PDF[anio])


# ---------------------------------------------------------------- informes mensuales

def _csv_links(pagina):
    html = _get(pagina, timeout=120).text
    links = []
    for href in re.findall(r'href="([^"]+\.csv[^"]*)"', html, re.I):
        u = urljoin(CM + "/", href.replace("&amp;", "&"))
        if u not in links:
            links.append(u)
    return links


MENSUAL_CAMPOS = [
    (r"poblacion asignada", "poblacion_asignada"),
    (r"total pacientes", "total_leq"),
    (r"^estructural$", "estructural"),
    (r"pacientes en espera estructural", "estructural"),
    (r"^rechazo derivacion$", "rechazo_derivacion"),
    (r"tnp|transitoriamente", "tnp"),
    (r"demora media estructural", "demora_corte"),
    (r"demora media de espera", "demora_corte"),
    (r"demora media rechazo", "demora_media_rechazo"),
    (r"de 0 a 30|0-30 d", "t0_30"),
    (r"31-60|30-60 d", "t31_60"),
    (r"61-90|60-90 d", "t61_90"),
    (r"90-180", "t91_180"),
    (r"> ?180", "t_mas_180"),
    (r"> ?90", "t_mas_90"),
    (r"entradas por 1000", "entradas_tasa_1000"),
    (r"total de entradas", "entradas"),
    (r"tasa por 1000 habitantes de pacientes atendidos", "salidas_tasa_1000"),
    (r"^tasa por 1000", "tasa_1000"),
    (r"total salidas mes", "salidas"),
    (r"total de salidas", "salidas"),
    (r"total de pacientes atendidos", "atendidos"),
    (r"espera media estructural para pacientes atendidos|espera media estructural\*$", "espera_media_atendidos"),
    (r"prospectiva", "demora_prospectiva"),
]


def _parsear_mensual(texto, tipo, url):
    # El tipo se toma del título del fichero: la página enlaza algún mes con el fichero de otra
    # lista (p. ej. pruebas de noviembre de 2017 apunta al CSV de consultas).
    cabecera = _sin_tildes(texto[:400]).lower()
    if "quirurgica" in cabecera:
        tipo = "quirurgica"
    elif "pruebas" in cabecera:
        tipo = "prueba"
    elif "consultas externas" in cabecera:
        tipo = "consulta"
    fila = {"tipo": tipo, "fuente_url": url}
    m = re.search(r"\b(ENERO|FEBRERO|MARZO|ABRIL|MAYO|JUNIO|JULIO|AGOSTO|SEPTIEMBRE|OCTUBRE|NOVIEMBRE|DICIEMBRE)\s+(\d{4})\b",
                  _sin_tildes(texto).upper())
    if m:
        fila["anio"], fila["mes"] = int(m.group(2)), MESES[m.group(1)]
    else:
        b = _sin_tildes(url.split("/")[-1].split("?")[0]).upper()
        mm = re.search(r"(ENERO|FEBRERO|MARZO|ABRIL|MAYO|JUNIO|JULIO|AGOSTO|SEPTIEMBRE|OCTUBRE|NOVIEMBRE|DICIEMBRE|ENE|FEB|SEPT|SEP|OCT|NOV|DIC)[-_]?(\d{2,4})", b)
        if not mm:
            return None
        a = int(mm.group(2))
        fila["anio"], fila["mes"] = (a + 2000 if a < 100 else a), MESES[mm.group(1)]
    for linea in texto.splitlines():
        celdas = [c.strip().strip('"') for c in linea.split(";")]
        celdas = [c for c in celdas if c]
        if len(celdas) < 2:
            continue
        etiqueta = _sin_tildes(celdas[0]).lower().strip(" .*")
        etiqueta = re.sub(r"\s+", " ", etiqueta)
        v = _num(celdas[1])
        if v is None:
            continue
        for patron, campo in MENSUAL_CAMPOS:
            if re.search(patron, etiqueta) and campo not in fila:
                fila[campo] = v
                break
    return fila if "estructural" in fila else None


def mensual():
    vistos = set()
    for tipo, pagina in PAG_MENSUAL.items():
        for url in _csv_links(pagina):
            try:
                r = requests.get(url, headers=UA, timeout=120)
                if r.status_code != 200:
                    log.warning("SERMAS mensual %s -> HTTP %s", url, r.status_code)
                    continue
                try:
                    texto = r.content.decode("utf-8")
                except UnicodeDecodeError:
                    texto = r.content.decode("latin-1")
                fila = _parsear_mensual(texto, tipo, url)
            except Exception as e:  # noqa: BLE001
                log.warning("SERMAS mensual %s: %s", url, e)
                continue
            if not fila:
                log.warning("SERMAS mensual sin datos: %s", url)
                continue
            clave = (fila["tipo"], fila["anio"], fila["mes"])
            if clave in vistos:
                continue
            vistos.add(clave)
            yield fila


# ---------------------------------------------------------------- libre elección (memoria SERMAS)

def _balance_xlsx_hoja(ws, memoria, url):
    filas = list(_filas(ws))
    anios = [int(x) for x in re.findall(r"(\d{4})", " ".join(_texto_fila(r) for r in filas[:2]))]
    if len(anios) < 2:
        return
    a1, a2 = anios[0], anios[1]
    for r in filas[2:]:
        nombre = _texto_fila(r)
        nums = _nums_fila(r)
        if not nombre or len(nums) < 4 or nombre.upper().startswith("TOTAL"):
            continue
        yield {"anio": a1, "hospital_informe": nombre, "entrantes": nums[0], "salientes": nums[1],
               "memoria_anio": memoria, "fuente_url": url}
        yield {"anio": a2, "hospital_informe": nombre, "entrantes": nums[2], "salientes": nums[3],
               "memoria_anio": memoria, "fuente_url": url}


def _balance_pdf(paginas, memoria, url):
    texto = _seccion(paginas, r"Balance de Libre Elecci\S+n( en hospitales)?\s*\n", [r"TOTAL CITAS[^\n]*\n"])
    if not texto:
        return []
    texto_total = re.search(r"TOTAL CITAS\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)", "\n".join(paginas))
    t = [_num(x) for x in texto_total.groups()] if texto_total else None
    # (e1, e2, s1, s2) si el total de entrantes de cada año es igual al de salientes; si no, (e1, s1, e2, s2)
    orden_a = t and t[0] == t[2] and t[1] == t[3]
    out = []
    for linea in texto.splitlines():
        m = re.match(r"^(H[\w.\s´'’–\-,()ÁÉÍÓÚáéíóúñÑ]+?)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s*$", linea.strip())
        if not m:
            continue
        nombre = m.group(1).strip()
        v = [_num(x) for x in m.groups()[1:]]
        e1, e2, s1, s2 = (v[0], v[1], v[2], v[3]) if orden_a else (v[0], v[2], v[1], v[3])
        out.append({"anio": memoria - 1, "hospital_informe": nombre, "entrantes": e1, "salientes": s1,
                    "memoria_anio": memoria, "fuente_url": url})
        out.append({"anio": memoria, "hospital_informe": nombre, "entrantes": e2, "salientes": s2,
                    "memoria_anio": memoria, "fuente_url": url})
    return out


def _libertad_xlsx(url):
    z = zipfile.ZipFile(io.BytesIO(_get(url).content))
    for n in z.namelist():
        base = n.split("/")[-1]
        if re.search(r"Libertad de Elecci", base, re.I) and base.lower().endswith(".xlsx"):
            yield _openpyxl(z.read(n))


def le_balance():
    for memoria, url in MEMORIA_PDF.items():
        try:
            yield from _balance_pdf(_pdf_texto(url), memoria, url)
        except Exception as e:  # noqa: BLE001
            log.warning("SERMAS balance PDF %s: %s", memoria, e)
    for memoria, url in MEMORIA_ZIP.items():
        for wb in _libertad_xlsx(url):
            for ws in wb.worksheets:
                if ws.title.strip().lower().startswith("balance le"):
                    yield from _balance_xlsx_hoja(ws, memoria, url)


def le_especialidad():
    for memoria, url in MEMORIA_ZIP.items():
        for wb in _libertad_xlsx(url):
            for ws in wb.worksheets:
                if not ws.title.strip().lower().startswith("balance por especialidad"):
                    continue
                for r in _filas(ws):
                    nombre = _texto_fila(r)
                    nums = _nums_fila(r)
                    if not nombre or len(nums) < 2 or nombre.lower().startswith("especialidad"):
                        continue
                    yield {"anio": memoria, "especialidad": nombre.strip(), "primeras_consultas": nums[0],
                           "consultas_libre_eleccion": nums[1], "fuente_url": url}


# ---------------------------------------------------------------- memorias de cada hospital

def _zips_hospital():
    html = _get(PAG_MEMORIAS, timeout=120).text
    out = []
    for href in re.findall(r'href="([^"]+\.zip[^"]*)"', html, re.I):
        u = urljoin(CM + "/", href.replace("&amp;", "&"))
        b = u.split("/")[-1].split("?")[0].lower()
        if re.search(r"^(3\.)?datos[-_]abiertos[-_]memoria[-_](sermas[-_])?20\d\d\.zip$|memoria_sermas_2021_datos", b):
            continue  # memoria del SERMAS, no de un hospital
        if u not in out:
            out.append(u)
    return out


def _hospital_y_anio(wb_portadas):
    hospital, anio = None, None
    for ws in wb_portadas:
        for r in _filas(ws):
            t = _texto_fila(r)
            m = re.search(r"MEMORIA (?:DE ACTIVIDAD )?(\d{4})", t.upper())
            if m and not anio:
                anio = int(m.group(1))
            if not hospital and re.search(r"^(Hospital|H\.|Instituto|Centro)", t) and "Servicio Madrile" not in t:
                hospital = t.strip()
        if hospital and anio:
            break
    return hospital, anio


def hospitales():
    """(le_hospital, consultas_hospital) de las memorias de cada hospital."""
    le, consultas = [], []
    vistos_le, vistos_c = set(), set()
    for url in _zips_hospital():
        try:
            z = zipfile.ZipFile(io.BytesIO(_get(url, timeout=180).content))
        except Exception as e:  # noqa: BLE001
            log.warning("SERMAS hospital %s: %s", url, e)
            continue
        libros = {}
        for n in z.namelist():
            if n.lower().endswith(".xlsx"):
                try:
                    libros[n] = _openpyxl(z.read(n))
                except Exception:  # noqa: BLE001
                    pass
        # hospital y año por carpeta (un ZIP puede traer dos hospitales)
        por_carpeta = {}
        for n, wb in libros.items():
            carpeta = n.rsplit("/", 1)[0] if "/" in n else ""
            por_carpeta.setdefault(carpeta, []).append(wb)
        ident = {}
        for carpeta, wbs in por_carpeta.items():
            portadas = [ws for wb in wbs for ws in wb.worksheets if ws.title.lower().startswith("portada")]
            ident[carpeta] = _hospital_y_anio(portadas)
        for n, wb in libros.items():
            carpeta = n.rsplit("/", 1)[0] if "/" in n else ""
            hospital, anio = ident.get(carpeta, (None, None))
            # El año se toma del nombre del ZIP (..._2021_..., damemoria23_..., ..._24_...): alguna
            # portada trae el año anterior (El Escorial 2024 dice «MEMORIA 2023» en la hoja 1).
            b = url.split("/")[-1].lower()
            m = re.search(r"(20[12]\d)", b) or re.search(r"memoria_?(2\d)_", b)
            if m:
                anio = int(m.group(1)) if len(m.group(1)) == 4 else 2000 + int(m.group(1))
            if not hospital or not anio:
                continue
            for ws in wb.worksheets:
                titulo = ws.title.strip().lower()
                if titulo.startswith("consultas libre"):
                    for r in _filas(ws):
                        nombre = _texto_fila(r)
                        nums = _nums_fila(r)
                        if not nombre or len(nums) < 2 or "ESPECIALIDAD" in nombre.upper() \
                                or nombre.lower().startswith(("consultas solicitadas", "fuente")):
                            continue
                        clave = (anio, hospital, nombre.strip())
                        if clave in vistos_le:
                            continue
                        vistos_le.add(clave)
                        le.append({"anio": anio, "hospital_informe": hospital, "especialidad": nombre.strip(),
                                   "entrantes": nums[0], "salientes": nums[1], "fuente_url": url})
                elif titulo == "consultas externas":
                    en_tabla = False
                    resumen = {}
                    for r in _filas(ws):
                        nombre = _texto_fila(r)
                        nums = _nums_fila(r)
                        if nombre.upper().startswith("ESPECIALIDAD"):
                            en_tabla = True
                            continue
                        if not en_tabla:
                            # cuadro resumen de arriba: «Primeras consultas», «Consultas sucesivas»
                            e = _sin_tildes(nombre).lower()
                            if nums and e.startswith("primeras consultas"):
                                resumen["primeras"] = nums[0]
                            elif nums and e.startswith("consultas sucesivas"):
                                resumen["sucesivas"] = nums[0]
                            continue
                        if not nombre or len(nums) < 2:
                            continue
                        clave = (anio, hospital, nombre.strip())
                        if clave in vistos_c:
                            continue
                        vistos_c.add(clave)
                        consultas.append({"anio": anio, "hospital_informe": hospital, "especialidad": nombre.strip(),
                                          "primeras": nums[0], "sucesivas": nums[1], "fuente_url": url})
                    clave = (anio, hospital, "TOTAL")
                    if resumen.get("primeras") and clave not in vistos_c:
                        vistos_c.add(clave)
                        consultas.append({"anio": anio, "hospital_informe": hospital, "especialidad": "TOTAL",
                                          "primeras": resumen["primeras"], "sucesivas": resumen.get("sucesivas"),
                                          "fuente_url": url})
    return le, consultas


@dlt.source(name="sermas")
def sermas():
    cache = []

    def hosp():
        if not cache:
            cache.append(hospitales())
        return cache[0]

    @dlt.resource(name="sermas_memoria_le", write_disposition="replace")
    def r_memoria_le():
        yield from memoria_le()

    @dlt.resource(name="sermas_mensual", write_disposition="replace")
    def r_mensual():
        yield from mensual()

    @dlt.resource(name="sermas_le_balance", write_disposition="replace")
    def r_le_balance():
        yield from le_balance()

    @dlt.resource(name="sermas_le_especialidad", write_disposition="replace")
    def r_le_especialidad():
        yield from le_especialidad()

    @dlt.resource(name="sermas_le_hospital", write_disposition="replace")
    def r_le_hospital():
        yield from hosp()[0]

    @dlt.resource(name="sermas_consultas_hospital", write_disposition="replace")
    def r_consultas_hospital():
        yield from hosp()[1]

    return r_memoria_le, r_mensual, r_le_balance, r_le_especialidad, r_le_hospital, r_consultas_hospital


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("sermas").run(sermas()))
