"""Fuente dlt de evaluaciones oficiales del cumplimiento de la publicidad activa
(tema `transparencia_publicidad_activa`): qué administraciones publican en sus
portales lo que les obliga la ley de transparencia.

No existe una evaluación homogénea de todas las administraciones de España: cada
órgano garante evalúa a los sujetos de su ámbito, con su método y su calendario.
Solo se ingieren las evaluaciones oficiales con puntuación por entidad en un
formato reutilizable:

1) Comisionado de Transparencia de Canarias, Índice de Transparencia de Canarias
   (ITCanarias), «tabla maestra» del sector público (XLSX, CC BY 4.0): Gobierno de
   Canarias, 7 cabildos, 88 ayuntamientos, universidades y sus entes, desde la
   evaluación de 2016. Puntuación 0-10; «Inc» = incumplidora (no rindió la
   evaluación), «N/C» = no censada, «Baja» = baja del censo. El nombre del fichero
   cambia con cada edición: se localiza en la página de puntuaciones.
2) Consejo de Transparencia y Buen Gobierno (CTBG), metodología MESTA: Índice de
   Cumplimiento de la Información Obligatoria (ICIO, 0-100 %) del Portal de la
   Transparencia de la AGE (2021-2025) y de las comunidades y ciudades autónomas
   con convenio con el CTBG y algunos de sus ayuntamientos (2020 y revisión de
   2021). El CTBG no publica una tabla: el ICIO se lee del texto de cada informe
   definitivo (.docx), cuya lista se fija abajo. Reutilización con cita «Origen de
   los datos: Consejo de Transparencia y Buen Gobierno» (Ley 37/2007).

3) CTBG, informes AGREGADOS de cada plan de evaluación (2022-2026): tabla del
   anexo con el ICIO de cada entidad del sector público institucional estatal,
   entidades privadas perceptoras de subvenciones, corporaciones de derecho
   público, órganos constitucionales y reguladores, y las terceras y cuartas
   evaluaciones (seguimiento). .docx (tabla w:tbl) o PDF (pdfplumber). El
   agregado redondea a una décima y abrevia nombres que cambian entre años.
4) Síndic de Greuges de Catalunya, IDPAC (índice de desarrollo de la publicidad
   activa, 0-100, revisión externa del Síndic) con el IADAIP (acceso a la
   información, solicitante oculto) y el ITC: los 947 ayuntamientos catalanes,
   las diputaciones y consejos comarcales, los departamentos de la Generalitat,
   universidades y órganos de control. CSV en datos abiertos (CC0). Sin código
   INE: se casa por nombre en dbt.
5) Consejo de la Transparencia de la Región de Murcia, ICPA (0-10, 70 % ICIO
   MESTA + 30 % soporte web) 2020-2023, Anexo I del informe de 2023 (PDF).
   Autoevaluación voluntaria verificada por el Consejo: «NP» = no participó (no es
   un cero).

Recursos (replace): pa_itcanarias, pa_ctbg, pa_ctbg_agregados, pa_sindic, pa_murcia.
"""

import io
import logging
import re
import time
import zipfile
import xml.etree.ElementTree as ET

import dlt
import openpyxl
import requests

log = logging.getLogger(__name__)

CABECERAS = {"User-Agent": "Mozilla/5.0 (compatible; SpainFacts; +https://spainfacts.github.io)"}

ITC_PAGINA = "https://transparenciacanarias.org/evaluacion/puntuaciones/"
ITC_PATRON = re.compile(r'href="([^"]*Tabla-maestra-de-puntuaciones-Sector-publico[^"]*\.xlsx)"', re.I)

CTBG = "https://consejodetransparencia.es"
CTBG_DAM = CTBG + "/content/dam/ctransparencia/portal-ctbg/evaluacion"

# (año de evaluación, página del CTBG, ruta del informe definitivo, entidad, tipo, código INE)
# tipo: age | ccaa | ayuntamiento. Código: '00' para la AGE, cod_ccaa INE o cod_mun INE.
CTBG_INFORMES = [
    # Portal de la Transparencia de la Administración General del Estado
    (2021, "evaluacion2021/2021/age", "evaluacion-de-2021/AGE/4-Informe-Definitivo-Portal-AGE-2021.docx", "Administración General del Estado (Portal de la Transparencia)", "age", "00"),
    (2022, "evaluacion2022/2022/age", "evaluacion-de-2022/AGE/4-Informe-Definitivo-Revision-Portal-AGE-2022.docx", "Administración General del Estado (Portal de la Transparencia)", "age", "00"),
    (2023, "evaluacion2023/2023/age", "evaluacion-de-2023/AGE/4-Informe-Definitivo-Portal-AGE-2023.docx", "Administración General del Estado (Portal de la Transparencia)", "age", "00"),
    (2024, "evaluacion2024/2024/age", "evaluacion-de-2024/AGE/4-Informe-Definitivo-Portal-AGE-2024.docx", "Administración General del Estado (Portal de la Transparencia)", "age", "00"),
    (2025, "evaluacion2025/2025/age", "evaluacion-de-2025/age/4-Informe-Definitivo-Portal-AGE-2025.docx", "Administración General del Estado (Portal de la Transparencia)", "age", "00"),
    # Comunidades y ciudades autónomas con convenio con el CTBG: evaluación de 2020
    (2020, "evaluacion2020/2020/ccaa", "evaluacion-de-2020/CCAA/Informedefinitivo-PrincipadodeAsturias2020.docx", "Principado de Asturias", "ccaa", "03"),
    (2020, "evaluacion2020/2020/ccaa", "evaluacion-de-2020/CCAA/Informe-definitivo-CACantabria-2020.docx", "Cantabria", "ccaa", "06"),
    (2020, "evaluacion2020/2020/ccaa", "evaluacion-de-2020/CCAA/02Informe-definitivo-Castilla-La-Mancha.docx", "Castilla-La Mancha", "ccaa", "08"),
    (2020, "evaluacion2020/2020/ccaa", "evaluacion-de-2020/CCAA/Informedefinitivo-CAExtremadura2020.docx", "Extremadura", "ccaa", "11"),
    (2020, "evaluacion2020/2020/ccaa", "evaluacion-de-2020/CCAA/Informedefinitivo-CAMadrid2020.docx", "Comunidad de Madrid", "ccaa", "13"),
    (2020, "evaluacion2020/2020/ccaa", "evaluacion-de-2020/CCAA/Informedefinitivo-CALa%20Rioja2020.docx", "La Rioja", "ccaa", "17"),
    (2020, "evaluacion2020/2020/ccaa", "evaluacion-de-2020/CCAA/Informedefinitivo-Ceuta2020.docx", "Ciudad Autónoma de Ceuta", "ccaa", "18"),
    (2020, "evaluacion2020/2020/ccaa", "evaluacion-de-2020/CCAA/Informedefinitivo-Melilla2020.docx", "Ciudad Autónoma de Melilla", "ccaa", "19"),
    # Revisión de 2021 (mismo método, tras las recomendaciones de 2020)
    (2021, "evaluacion2021/2021/ccaa", "evaluacion-de-2021/CCAA/4-Informe-Definitivo-Revision-PrincipadodeAsturias.docx", "Principado de Asturias", "ccaa", "03"),
    (2021, "evaluacion2021/2021/ccaa", "evaluacion-de-2021/CCAA/4-Informe-Revision-Definitivo-Cantabria1.docx", "Cantabria", "ccaa", "06"),
    (2021, "evaluacion2021/2021/ccaa", "evaluacion-de-2021/CCAA/4-Informe-Definitivo-Revision-Castilla-LaMancha1.docx", "Castilla-La Mancha", "ccaa", "08"),
    (2021, "evaluacion2021/2021/ccaa", "evaluacion-de-2021/CCAA/4-Informe-Definitivo-Revision-Extremadura1.docx", "Extremadura", "ccaa", "11"),
    (2021, "evaluacion2021/2021/ccaa", "evaluacion-de-2021/CCAA/4-Informe-Definitivo-Revision-Madrid1.docx", "Comunidad de Madrid", "ccaa", "13"),
    (2021, "evaluacion2021/2021/ccaa", "evaluacion-de-2021/CCAA/1-Informe-Definitivo-Revision-La-Rioja1.docx", "La Rioja", "ccaa", "17"),
    (2021, "evaluacion2021/2021/ccaa", "evaluacion-de-2021/CCAA/1-Informe-Definitivo-Revision-Ceuta1.docx", "Ciudad Autónoma de Ceuta", "ccaa", "18"),
    (2021, "evaluacion2021/2021/ccaa", "evaluacion-de-2021/CCAA/1-Informe-Definitivo-Revision-Melilla1.docx", "Ciudad Autónoma de Melilla", "ccaa", "19"),
    # Ayuntamientos de esas comunidades: evaluación de 2020
    (2020, "evaluacion2020/2020/eell", "evaluacion-de-2020/EELL/informe-definitivo-ayto-albacete.docx", "Ayuntamiento de Albacete", "ayuntamiento", "02003"),
    (2020, "evaluacion2020/2020/eell", "evaluacion-de-2020/EELL/informe-definitivo-aytoacehuche-extremadura.docx", "Ayuntamiento de Acehúche", "ayuntamiento", "10004"),
    (2020, "evaluacion2020/2020/eell", "evaluacion-de-2020/EELL/informe-definitivo-aytoaviles.docx", "Ayuntamiento de Avilés", "ayuntamiento", "33004"),
    (2020, "evaluacion2020/2020/eell", "evaluacion-de-2020/EELL/informe-definitivo-aytobadajoz.docx", "Ayuntamiento de Badajoz", "ayuntamiento", "06015"),
    (2020, "evaluacion2020/2020/eell", "evaluacion-de-2020/EELL/informe-definitivo-aytociudadreal.docx", "Ayuntamiento de Ciudad Real", "ayuntamiento", "13034"),
    (2020, "evaluacion2020/2020/eell", "evaluacion-de-2020/EELL/informe-definitivo-aytolimpias-cantabria.docx", "Ayuntamiento de Limpias", "ayuntamiento", "39038"),
    (2020, "evaluacion2020/2020/eell", "evaluacion-de-2020/EELL/informe-definitivo-aytooviedo.docx", "Ayuntamiento de Oviedo", "ayuntamiento", "33044"),
    (2020, "evaluacion2020/2020/eell", "evaluacion-de-2020/EELL/informe-definitivo-aytopolanco-cantabria.docx", "Ayuntamiento de Polanco", "ayuntamiento", "39054"),
    (2020, "evaluacion2020/2020/eell", "evaluacion-de-2020/EELL/informe-definitivo-aytosantander.docx", "Ayuntamiento de Santander", "ayuntamiento", "39075"),
    (2020, "evaluacion2020/2020/eell", "evaluacion-de-2020/EELL/informe-definitivo-aytotoledo.docx", "Ayuntamiento de Toledo", "ayuntamiento", "45168"),
    # Revisión de 2021
    (2021, "evaluacion2021/2021/eell", "evaluacion-de-2021/EELL/1-Informe-Definitivo-Revision-Albacete1.docx", "Ayuntamiento de Albacete", "ayuntamiento", "02003"),
    (2021, "evaluacion2021/2021/eell", "evaluacion-de-2021/EELL/1-Informe-Definitivo-Revision-Acehuche1.docx", "Ayuntamiento de Acehúche", "ayuntamiento", "10004"),
    (2021, "evaluacion2021/2021/eell", "evaluacion-de-2021/EELL/1-Informe-Definitivo-Revision-Aviles1.docx", "Ayuntamiento de Avilés", "ayuntamiento", "33004"),
    (2021, "evaluacion2021/2021/eell", "evaluacion-de-2021/EELL/1-Informe-Definitivo-Revision-Badajoz1.docx", "Ayuntamiento de Badajoz", "ayuntamiento", "06015"),
    (2021, "evaluacion2021/2021/eell", "evaluacion-de-2021/EELL/4-Informe-Definitivo-Revision-Ciudad-Real1.docx", "Ayuntamiento de Ciudad Real", "ayuntamiento", "13034"),
    (2021, "evaluacion2021/2021/eell", "evaluacion-de-2021/EELL/Informe-Revision-Limpias1.docx", "Ayuntamiento de Limpias", "ayuntamiento", "39038"),
    (2021, "evaluacion2021/2021/eell", "evaluacion-de-2021/EELL/1-Informe-Definitivo-Revision-Montijo1.docx", "Ayuntamiento de Montijo", "ayuntamiento", "06088"),
    (2021, "evaluacion2021/2021/eell", "evaluacion-de-2021/EELL/4-Informe-Definitivo-Revision-Oviedo1.docx", "Ayuntamiento de Oviedo", "ayuntamiento", "33044"),
    (2021, "evaluacion2021/2021/eell", "evaluacion-de-2021/EELL/1-Informe-Definitivo-Revision-Polanco1.docx", "Ayuntamiento de Polanco", "ayuntamiento", "39054"),
    (2021, "evaluacion2021/2021/eell", "evaluacion-de-2021/EELL/1-Informe-Definitivo-Revision-Santander1.docx", "Ayuntamiento de Santander", "ayuntamiento", "39075"),
    (2021, "evaluacion2021/2021/eell", "evaluacion-de-2021/EELL/1-Informe-Definitivo-Revision-Toledo1.docx", "Ayuntamiento de Toledo", "ayuntamiento", "45168"),
]

# Informes agregados del CTBG con tabla del ICIO por entidad: (año, grupo, ronda, ruta).
# ronda 1 = evaluación anual; 3 y 4 = terceras y cuartas evaluaciones de seguimiento.
CTBG_AGREGADOS = [
    (2022, "Órganos constitucionales", 1, "evaluacion-de-2022/constitucionales-aai/constitucionales/Informe-agregado-de-evaluacion-organos-constitucionales.docx"),
    (2022, "Autoridades independientes y reguladores", 1, "evaluacion-de-2022/AAI/Informe-agregado-de-evaluacion-de-AAI-y-organos-supervisores-o-reguladores.docx"),
    (2022, "Corporaciones de derecho público", 1, "evaluacion-de-2022/Corporaciones_Derecho_Publico/Informe-agregado-de-evaluacion-Corporaciones-Derecho-Publico.docx"),
    (2022, "Sector público institucional estatal", 1, "evaluacion-de-2022/SPI/Informe-agregado-de-evaluacion-Sector-Publico-Institucional_20221.docx"),
    (2022, "Entidades privadas subvencionadas", 1, "evaluacion-de-2022/entidades-perceptoras-subvenciones/Informe-agregado-de-evaluacion-Entidades-perceptoras-subvenciones-2022.docx"),
    (2023, "Sector público institucional estatal", 1, "evaluacion-de-2023/SPI/Informe-agregado-de-evaluacion-Sector-Publico-Institucional-20231.docx"),
    (2023, "Entidades privadas subvencionadas", 1, "evaluacion-de-2023/Sujetos%20privados/Informe-agregado-de-evaluacion-Entidades-perceptoras-subvenciones-2023.pdf"),
    (2024, "Sector público institucional estatal", 1, "evaluacion-de-2024/spi/Informe-agregado-de-evaluacion-Sector-Publico-Institucional_20241.docx"),
    (2024, "Entidades privadas subvencionadas", 1, "evaluacion-de-2024/Sujetos-Privados/241002_Informe_agregado_evaluacion_entidades_privadas_2024.docx"),
    (2025, "Sector público institucional estatal", 1, "evaluacion-de-2025/Sector_P%C3%BAblico_Institucional/Informe-agregado-de-evaluacion-Sector-Publico-Institucional%202025.pdf"),
    (2025, "Entidades privadas subvencionadas", 1, "evaluacion-de-2025/entidades-perceptoras-de-subvenciones-y-ayudas-p%C3%BAblicas/Informe-agregado-de-evaluacion-Entidades-Privadas_2025.docx"),
    (2025, "Seguimiento (terceras evaluaciones)", 3, "evaluacion-de-2025/terceras-evaluaciones/Informe_agregado_evaluacion_terceras-evaluaciones-2025.docx"),
    (2025, "Seguimiento (cuartas evaluaciones)", 4, "evaluacion-de-2025/cuartas-evaluaciones/Informe_agregado_evaluacion_cuartas-evaluaciones.docx"),
    (2026, "Sector público institucional estatal", 1, "evaluaci%C3%B3n-de-2026/spi/Informe-agregado-de-evaluacion-Sector-Publico-Institucional%202026.pdf"),
]

SINDIC_CSV = "https://dadesobertes.seu-e.cat/dataset/5f8e4974-9cb0-4483-b7e7-ec844500b6c3/resource/6b81069f-19ce-4b75-b9d2-33ad43c1d70d/download/idpac.csv"
SINDIC_PAGINA = "https://www.sindic.cat/ca/page.asp?id=904"
SINDIC_EDICION = 2026  # trabajo de campo de enero a mayo de 2026

MURCIA_PDF = "https://comisionadotransparencia.carm.es/documents/d/guest/INFOR_-EVAL_CTRM_2023-IT-RM_Y_PORTADA-cleaned"
MURCIA_PAGINA = "https://comisionadotransparencia.carm.es/informes-de-evaluacion"
MURCIA_ANIOS = (2020, 2021, 2022, 2023)

NUM = re.compile(r"^-?\d{1,3}(?:[,.]\d+)?$")

# Frases con que los informes dan el ICIO global: «(ICIO) se sitúa en el 72,9 %» (desde
# 2021) o «puede considerarse elevado, un 84,5 %» (2020; a veces «51, 7 %» o «medio: un»).
ICIO_PATRONES = [
    re.compile(r"\(ICIO\)\s*se\s+sit[úu]a\s+en\s+el\s+(\d{1,3}(?:,\s?\d{1,2})?)\s*%", re.I),
    re.compile(r"informaci[óo]n\s+obligatoria\s+por\s+parte\s+de.{0,160}?puede\s+considerarse[^%]{0,40}?un\s+(\d{1,3}(?:,\s?\d{1,2})?)\s*%", re.I | re.S),
]

W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"


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
            time.sleep(5 * (i + 1))


def _texto_docx(contenido: bytes) -> str:
    x = ET.fromstring(zipfile.ZipFile(io.BytesIO(contenido)).read("word/document.xml"))
    return "\n".join("".join(t.text or "" for t in p.iter(W + "t")) for p in x.iter(W + "p"))


def _icio(texto: str) -> float | None:
    for patron in ICIO_PATRONES:
        m = patron.search(texto)
        if m:
            return float(m.group(1).replace(" ", "").replace(",", "."))
    return None


def _num(txt: str) -> float | None:
    """Primer número de una celda («100 + 68,7» -> 100; «99,6 %» -> 99.6)."""
    tok = (txt or "").replace("%", " ").split()
    if not tok or not NUM.match(tok[0]):
        return None
    v = float(tok[0].replace(",", "."))
    return v if 0 <= v <= 100 else None


def _tablas_docx(contenido: bytes):
    x = ET.fromstring(zipfile.ZipFile(io.BytesIO(contenido)).read("word/document.xml"))
    for t in x.iter(W + "tbl"):
        yield [[" ".join("".join(n.text or "" for n in p.iter(W + "t")) for p in tc.iter(W + "p")).strip()
                for tc in tr.findall(W + "tc")] for tr in t.findall(W + "tr")]


def _icio_tabla_docx(tablas) -> list[tuple[str, float]]:
    """Filas (entidad, ICIO) de las tablas de un agregado del CTBG en Word.

    Cabeceras vistas: «Entidad | ICIO | Diferencia…», «Institución | Cumplimiento | …»,
    « | Cumplimiento | …» y, en el seguimiento, « | ICIO 2ª evaluación | … | ICIO 3ª
    evaluación | …»: entonces vale la ÚLTIMA evaluación con dato."""
    out = []
    for t in tablas:
        if len(t) < 2:
            continue
        cab = [c.strip().lower() for c in t[0]]
        directa = [i for i, c in enumerate(cab) if c in ("icio", "cumplimiento") or c.startswith("índice de cumplimiento")]
        rondas = [i for i, c in enumerate(cab) if re.match(r"icio \d", c)]
        if directa:
            k = directa[0]
            ent = cab.index("entidad") if "entidad" in cab else max(k - 1, 0)
            cols = [k]
        elif rondas:
            ent = cab.index("entidad") if "entidad" in cab else 0
            cols = rondas
        else:
            continue
        for r in t[1:]:
            if len(r) <= max(cols) or not r[ent].strip():
                continue
            valores = [v for v in (_num(r[c]) for c in cols) if v is not None]
            if valores:
                out.append((re.sub(r"\s+", " ", r[ent]).strip(), valores[-1]))
    return out


def _icio_tabla_pdf(contenido: bytes) -> list[tuple[str, float]]:
    """Filas (entidad, ICIO) del anexo de un agregado del CTBG en PDF.

    pdfplumber parte los nombres largos en dos filas (la segunda sin cifras) y a
    veces separa las cifras en una fila aparte; se vuelven a unir. En 2026 la tabla
    tiene 15 columnas y las páginas de continuación no repiten la cabecera."""
    import pdfplumber

    filas: list[list[str]] = []
    with pdfplumber.open(io.BytesIO(contenido)) as pdf:
        for pg in pdf.pages:
            for t in pg.extract_tables():
                if not t:
                    continue
                cab = " ".join(c or "" for c in t[0])
                es_cab = cab.startswith("Entidad") and ("Cumplimient" in cab or "ICIO" in cab)
                if not es_cab and not (len(t[0]) == 15 and len(t) > 30):
                    continue
                for r in (t[1:] if es_cab else t):
                    c = [x for x in ((y or "").replace("\n", " ").strip() for y in r) if x]
                    if not c:
                        continue
                    if NUM.match(c[0].split()[0]) or c[0].startswith("Primera"):
                        if filas:
                            filas[-1] += c
                        continue
                    if len(c) > 1:
                        filas.append(c)
                    elif filas:
                        filas[-1][0] += " " + c[0]
    out = []
    for f in filas:
        v = _num(f[1]) if len(f) > 1 else None
        nombre = re.sub(r"\s+", " ", f[0]).strip()
        if v is not None and len(nombre) > 2 and not nombre.lower().startswith(("entidad", "total", "media")):
            out.append((nombre, v))
    return out


def _periodo_itc(cabecera) -> tuple[str, int] | None:
    """Etiqueta de la columna de la tabla maestra -> (periodo, año de referencia)."""
    if isinstance(cabecera, (int, float)):
        return str(int(cabecera)), int(cabecera)
    txt = str(cabecera or "").strip()
    anios = re.findall(r"20\d\d", txt)
    if not anios:
        return None
    return txt, int(anios[-1])


@dlt.source(name="transparencia_publicidad_activa")
def transparencia_publicidad_activa():
    @dlt.resource(name="pa_itcanarias", write_disposition="replace")
    def itcanarias():
        html = _get(ITC_PAGINA).text
        enlaces = ITC_PATRON.findall(html)
        if not enlaces:
            raise ValueError("No se encuentra la tabla maestra del ITCanarias en la página de puntuaciones")
        url = enlaces[0] if enlaces[0].startswith("http") else "https://transparenciacanarias.org" + enlaces[0]
        wb = openpyxl.load_workbook(io.BytesIO(_get(url).content), read_only=True, data_only=True)
        ws = wb.worksheets[0]
        filas = list(ws.iter_rows(values_only=True))
        cab = filas[0]
        if str(cab[0]).strip() != "Entidad" or str(cab[1]).strip() != "Tipo de entidad":
            raise ValueError(f"Cabecera inesperada en la tabla maestra del ITCanarias: {cab}")
        periodos = {i: _periodo_itc(c) for i, c in enumerate(cab) if i >= 4}
        periodos = {i: p for i, p in periodos.items() if p}
        n = 0
        for f in filas[1:]:
            if not f or not f[0]:
                continue
            for i, (periodo, anio) in periodos.items():
                v = f[i] if i < len(f) else None
                if isinstance(v, (int, float)):
                    estado, punt = "evaluada", float(v)
                else:
                    t = str(v or "").strip().upper().replace("/", "")
                    estado = {"INC": "incumplidora", "NC": "no_censada", "BAJA": "baja"}.get(t, "sin_dato")
                    punt = None
                    if estado in ("no_censada", "sin_dato", "baja"):
                        continue
                n += 1
                yield {"entidad": str(f[0]).strip(), "tipo_entidad": str(f[1] or "").strip(),
                       "entidad_principal": str(f[2] or "").strip(), "sector": str(f[3] or "").strip(),
                       "periodo": periodo, "anio": anio, "orden_periodo": i - 3, "estado": estado,
                       "puntuacion": punt, "url_fuente": url}
        if n < 500:
            raise ValueError(f"Tabla maestra del ITCanarias con muy pocas filas: {n}")
        log.info("ITCanarias: %s filas (%s)", n, url)

    @dlt.resource(name="pa_ctbg", write_disposition="replace")
    def ctbg():
        n = 0
        for anio, pagina, ruta, entidad, tipo, cod in CTBG_INFORMES:
            url = f"{CTBG_DAM}/{ruta}"
            try:
                texto = _texto_docx(_get(url).content)
            except (requests.RequestException, zipfile.BadZipFile, KeyError) as e:
                log.warning("CTBG: no se pudo leer %s: %s", url, e)
                continue
            icio = _icio(texto)
            if icio is None or not 0 <= icio <= 100:
                log.warning("CTBG: sin ICIO legible en %s", url)
                continue
            n += 1
            yield {"anio": anio, "entidad": entidad, "tipo": tipo, "cod": cod, "icio": icio,
                   "url_fuente": url, "url_pagina": f"{CTBG}/evaluacion/{pagina}"}
            time.sleep(0.5)
        if n < len(CTBG_INFORMES) * 0.8:
            raise ValueError(f"CTBG: solo se leyeron {n} de {len(CTBG_INFORMES)} informes")
        log.info("CTBG: %s informes", n)

    @dlt.resource(name="pa_ctbg_agregados", write_disposition="replace")
    def ctbg_agregados():
        n_inf = 0
        vistos = set()
        for anio, grupo, ronda, ruta in CTBG_AGREGADOS:
            url = f"{CTBG_DAM}/{ruta}"
            try:
                contenido = _get(url).content
                filas = _icio_tabla_pdf(contenido) if ruta.endswith(".pdf") else _icio_tabla_docx(_tablas_docx(contenido))
            except (requests.RequestException, zipfile.BadZipFile, KeyError) as e:
                log.warning("CTBG agregado: no se pudo leer %s: %s", url, e)
                continue
            if len(filas) < 5:
                log.warning("CTBG agregado sin tabla legible: %s (%s filas)", url, len(filas))
                continue
            n_inf += 1
            for entidad, icio in filas:
                clave = (anio, grupo, entidad)
                if clave in vistos:   # la misma entidad en la tabla resumen del seguimiento
                    continue
                vistos.add(clave)
                yield {"anio": anio, "grupo": grupo, "ronda": ronda, "entidad": entidad, "icio": icio,
                       "url_fuente": url}
            log.info("CTBG agregado %s %s: %s entidades", anio, grupo, len(filas))
            time.sleep(0.5)
        if n_inf < len(CTBG_AGREGADOS) * 0.7:
            raise ValueError(f"CTBG: solo se leyeron {n_inf} de {len(CTBG_AGREGADOS)} informes agregados")

    @dlt.resource(name="pa_sindic", write_disposition="replace")
    def sindic():
        import csv

        texto = _get(SINDIC_CSV).content.decode("utf-8-sig")
        filas = list(csv.DictReader(io.StringIO(texto)))
        if not filas or "IDPAC" not in filas[0] or "Municipi" not in filas[0]:
            raise ValueError("CSV del Síndic (IDPAC) con columnas inesperadas")

        def f(v):
            try:
                return float(str(v).strip().replace(",", "."))
            except ValueError:
                return None

        n = 0
        for r in filas:
            idpac = f(r.get("IDPAC"))
            n += idpac is not None
            yield {"edicion": SINDIC_EDICION, "entidad": (r.get("nom") or "").strip(),
                   "municipio": (r.get("Municipi") or "").strip(), "provincia": (r.get("provincia") or "").strip(),
                   "comarca": (r.get("Comarca") or "").strip(),
                   "categoria_n1": (r.get("CategoriaN1") or "").strip(), "categoria_n2": (r.get("CategoriaN2") or "").strip(),
                   "categoria_n3": (r.get("CategoriaN3") or "").strip(),
                   "categoria_municipi": (r.get("CategoriaMunicipi") or "").strip(),
                   "cens": f(r.get("cens")), "idpac": idpac, "iadaip": f(r.get("IADAIP")), "itc": f(r.get("ITC")),
                   "url_fuente": SINDIC_CSV, "url_pagina": SINDIC_PAGINA}
        if n < 900:
            raise ValueError(f"CSV del Síndic con muy pocas notas: {n}")
        log.info("Síndic: %s entidades con IDPAC", n)

    @dlt.resource(name="pa_murcia", write_disposition="replace")
    def murcia():
        import pdfplumber

        contenido = _get(MURCIA_PDF).content
        n = 0
        with pdfplumber.open(io.BytesIO(contenido)) as pdf:
            # el Anexo I ocupa las últimas páginas (67-78 en la edición de 2023)
            for pg in pdf.pages[max(len(pdf.pages) - 20, 0):]:
                for t in pg.extract_tables():
                    for r in t:
                        c = [(x or "").replace("\n", " ").strip() for x in r]
                        c = [x for x in c if x]
                        if len(c) < 6 or c[0] == "Entidad":
                            continue
                        notas = c[-4:]
                        if not all(NUM.match(v) or v.upper() in ("NP", "NC", "-") for v in notas):
                            continue
                        entidad, tipo = re.sub(r"\s+", " ", " ".join(c[:-5])).strip(), c[-5]
                        for anio, v in zip(MURCIA_ANIOS, notas):
                            num = float(v.replace(",", ".")) if NUM.match(v) else None
                            yield {"anio": anio, "entidad": entidad, "tipo_entidad": tipo,
                                   "estado": "evaluada" if num is not None else ("no_participo" if v.upper() == "NP" else "sin_dato"),
                                   "icpa": num, "url_fuente": MURCIA_PDF, "url_pagina": MURCIA_PAGINA}
                        n += 1
        if n < 250:
            raise ValueError(f"Anexo I de Murcia con muy pocas entidades: {n}")
        log.info("Murcia: %s entidades", n)

    return [itcanarias, ctbg, ctbg_agregados, sindic, murcia]


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("transparencia_publicidad_activa").run(transparencia_publicidad_activa()))
