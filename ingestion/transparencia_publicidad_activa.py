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

Recursos (replace): pa_itcanarias, pa_ctbg.
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

    return [itcanarias, ctbg]


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("transparencia_publicidad_activa").run(transparencia_publicidad_activa()))
