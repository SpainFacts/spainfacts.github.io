"""Fuente dlt para el personal al servicio de las administraciones públicas.

Boletín Estadístico del Personal al Servicio de las Administraciones Públicas
(BEPSAP; desde enero de 2026, EPSAP), del Registro Central de Personal
(Ministerio para la Transformación Digital y de la Función Pública). Semestral,
con datos a 1 de enero y 1 de julio. Desde julio de 2019 se publican los
"microdatos": una tabla agregada con el número de efectivos (NIF distintos)
por administración, organismo, comunidad, provincia, tipo de personal, área,
subgrupo, sexo y fuente.
  Página: https://digital.gob.es/funcion-publica/dgfp/registro-central-personal/boletin.html
  Ficheros: .../rcp/boletin/{2006_2022/}AAAA_MM/{Agrupaciones*|Microdatos_*|BEPSAP_microdatos_*}.zip
Los nombres de fichero no siguen un patrón, así que se leen de la página.
El .xlsx trae la tabla en formato largo (hasta 2022 en la hoja "TOTAL", junto a
tablas dinámicas de ejemplo); el .txt tabulado que la acompaña hasta 2022 está
INCOMPLETO en 2019-07 a 2021-01, así que siempre se lee el .xlsx. Tres columnas cambian de nombre:
NIVEL_COMP_DEST -> NIVEL, FUENTE_DATOS -> FUENTE, TOTAL_EFECT -> Num_NIF.

Limitaciones que hay que contar en la web:
  - no llega a municipio: las entidades locales solo se desglosan por tipo
    (ayuntamientos, diputaciones...) y provincia;
  - no incluye empresas públicas ni fundaciones (sí organismos y universidades);
  - el personal de las entidades locales sale de la afiliación a la Seguridad
    Social (fuente TGSS);
  - en agosto de 2026 se revisaron todas las ediciones de 2023-01 a 2025-07
    ("revisión exhaustiva de fuentes y diccionarios"): hay un escalón en 2023.

Los zip se guardan en data/empleo_cache/ (no versionado): los publicados no cambian.

Recurso (carga completa "replace"):
  bepsap_efectivos   efectivos por edición y todas las dimensiones del fichero "Total"
(El fichero "Edad" no se carga: cubre ~200.000 efectivos hasta 2022 y ~830.000
desde 2023, así que no es comparable.)
"""

import csv
import io
import logging
import re
import zipfile
from datetime import date
from pathlib import Path
from urllib.parse import unquote, urljoin

import dlt
import requests

REPO_ROOT = Path(__file__).resolve().parent.parent
CACHE = REPO_ROOT / "data" / "empleo_cache"
PAGINA = "https://digital.gob.es/funcion-publica/dgfp/registro-central-personal/boletin.html"
CABECERAS = {"User-Agent": "Mozilla/5.0 (spainfacts.org; datos abiertos)"}

log = logging.getLogger(__name__)

RENOMBRAR = {"NIVEL_COMP_DEST": "NIVEL", "FUENTE_DATOS": "FUENTE", "TOTAL_EFECT": "EFECTIVOS",
             "SUMA DE NUM_NIF": "EFECTIVOS", "NUM_NIF": "EFECTIVOS"}


def enlaces_microdatos() -> list[tuple[date, str]]:
    """[(fecha de referencia, url del zip)] de cada edición con microdatos."""
    html = requests.get(PAGINA, headers=CABECERAS, timeout=60).text
    ediciones = {}
    for href in re.findall(r'href="([^"]+\.zip)"', html):
        m = re.search(r"/(\d{4})_(\d{2})/", href)
        nombre = unquote(href.rsplit("/", 1)[-1]).lower()
        # RCP_BOLSEM_* (2019-2020) son tablas del boletín, no los microdatos
        if not m or not ("agrupaciones" in nombre or "microdatos" in nombre):
            continue
        ediciones[date(int(m.group(1)), int(m.group(2)), 1)] = urljoin(PAGINA, href)
    return sorted(ediciones.items())


def _zip(fecha: date, url: str) -> zipfile.ZipFile:
    ruta = CACHE / f"bepsap_{fecha:%Y_%m}.zip"
    if not ruta.exists():
        CACHE.mkdir(parents=True, exist_ok=True)
        r = requests.get(url, headers=CABECERAS, timeout=300)
        r.raise_for_status()
        tmp = ruta.with_suffix(".part")
        tmp.write_bytes(r.content)
        tmp.replace(ruta)
    return zipfile.ZipFile(ruta)


def _normalizar_cabecera(cabecera) -> list[str]:
    return [RENOMBRAR.get(str(c or "").strip().upper(), str(c or "").strip().upper()) for c in cabecera]


def _filas_txt(datos: bytes):
    texto = datos.decode("utf-8") if datos[:3] == b"\xef\xbb\xbf" else datos.decode("latin-1")
    lector = csv.reader(io.StringIO(texto.lstrip("﻿")), delimiter="\t")
    yield from lector


def _filas_xlsx(datos: bytes):
    import openpyxl

    wb = openpyxl.load_workbook(io.BytesIO(datos), read_only=True)
    for hoja in wb.worksheets:
        filas = hoja.iter_rows(values_only=True)
        primera = next(filas, None)
        if primera and str(primera[0] or "").strip().upper() == "TIPO_ADMINISTRACION":
            yield primera
            yield from filas
            return


def leer_tabla(zf: zipfile.ZipFile, clave: str):
    """Dicts de la tabla 'Total' o 'Edad' del zip."""
    nombres = [n for n in zf.namelist() if clave in n.lower().replace("_", "") and not n.endswith("/")]
    txt = [n for n in nombres if n.lower().endswith(".txt")]
    xlsx = [n for n in nombres if n.lower().endswith(".xlsx")]
    # El .xlsx primero: en 2019-07 a 2021-01 el .txt está incompleto (1,15 M de
    # efectivos frente a los ~2,6 M de la hoja TOTAL del .xlsx y del boletín).
    if xlsx:
        filas = _filas_xlsx(zf.read(xlsx[0]))
    elif txt:
        filas = _filas_txt(zf.read(txt[0]))
    else:
        raise ValueError(f"Sin tabla {clave} en {zf.filename}")
    cabecera = _normalizar_cabecera(next(filas))
    for fila in filas:
        if not fila or fila[0] in (None, ""):
            continue
        registro = {c: fila[i] for i, c in enumerate(cabecera) if c and i < len(fila)}
        try:
            registro["EFECTIVOS"] = int(float(str(registro.get("EFECTIVOS", "")).replace(",", ".")))
        except ValueError:
            continue
        yield registro


def _limpio(v) -> str | None:
    v = str(v).strip() if v is not None else ""
    return None if v in ("", "N/D", "N/A", "SIN DEFINIR", "NO APLICA") else v


@dlt.source(name="empleo_publico")
def empleo_publico():
    ediciones = None

    def _ediciones():
        nonlocal ediciones
        if ediciones is None:
            ediciones = enlaces_microdatos()
            log.info("BEPSAP: %d ediciones con microdatos", len(ediciones))
        return ediciones

    @dlt.resource(name="bepsap_efectivos", write_disposition="replace")
    def efectivos():
        for fecha, url in _ediciones():
            n = 0
            for r in leer_tabla(_zip(fecha, url), "total"):
                n += r["EFECTIVOS"]
                yield {
                    "fecha": fecha,
                    "tipo_administracion": _limpio(r.get("TIPO_ADMINISTRACION")),
                    "subtipo_administracion": _limpio(r.get("SUBTIPO_ADMINISTRACION")),
                    "tipo_organismo": _limpio(r.get("TIPO_ORGANISMO")),
                    "ministerio": _limpio(r.get("MINIST_ADSCRIPCION")),
                    "organismo": _limpio(r.get("NOMBRE_ORGANISMO")),
                    "tipo_centro": _limpio(r.get("TIPO_CENTRO")),
                    "ccaa": _limpio(r.get("CCAA")),
                    "provincia": _limpio(r.get("PROVINCIA")),
                    "tipo_personal": _limpio(r.get("TIPO_PERSONAL")),
                    "subtipo_personal": _limpio(r.get("SUBTIPO_PERSONAL")),
                    "area": _limpio(r.get("AREA")),
                    "subarea": _limpio(r.get("SUBAREA")),
                    "subgrupo": _limpio(r.get("SUBGRUPO_O_GR_PROF")),
                    "nivel": _limpio(r.get("NIVEL")),
                    "sexo": _limpio(r.get("SEXO")),
                    "fuente": _limpio(r.get("FUENTE")),
                    "efectivos": r["EFECTIVOS"],
                }
            log.info("BEPSAP %s: %d efectivos", f"{fecha:%Y-%m}", n)

    return efectivos


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("empleo_publico").run(empleo_publico()))
