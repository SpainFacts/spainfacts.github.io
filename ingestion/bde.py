"""Fuente dlt para la deuda pública territorial del Banco de España (PDE).

El Boletín Estadístico del Banco de España publica, según el Protocolo de
Déficit Excesivo (PDE, SEC 2010), la deuda de las Comunidades Autónomas
(capítulo 13) y de las Corporaciones Locales (capítulo 14). Cada capítulo se
descarga como un zip con un CSV por cuadro (ISO-8859-1, cabecera de metadatos
de 5-8 filas: código, número secuencial, alias, descripción, unidades y
frecuencia de cada serie; luego una fila por periodo "MAR 2026").

Cuadros que se cargan (carga completa, "replace"):
  be1309  deuda PDE por comunidad autónoma (miles de €, trimestral, 1994-)
  be1310  deuda PDE por comunidad autónoma en % del PIB regional (trimestral)
  be13a   capacidad (+) / necesidad (-) de financiación por comunidad
          (miles de €, flujo MENSUAL no acumulado; total desde 2005,
          por comunidad desde 2013)
  be1406-be1409  deuda PDE de las corporaciones locales por tipo de entidad,
          instrumento y ayuntamientos de más de 300.000 habitantes (trimestral)

El Banco de España no desglosa la deuda local por provincia. Esa foto la da el
Ministerio de Hacienda con la "Deuda viva de las Entidades Locales" a 31 de
diciembre de cada año, entidad a entidad (ayuntamientos, diputaciones /
consejos / cabildos y resto de entidades locales), elaborada con los datos de
la Central de Información de Riesgos del Banco de España y conciliada con su
total PDE. Se carga en `bde_deuda_viva_eell` (anual, 2008-).

Cada tabla raw guarda las series en formato largo (serie, periodo, valor) con
su descripción y unidad; el mapeo serie -> código INE vive en el seed
transform/seeds/bde_series_territorio.csv.

Documentación: https://www.bde.es/webbe/es/estadisticas/temas/administraciones-publicas.html
Deuda viva EELL: https://www.hacienda.gob.es/es-ES/CDI/Paginas/SistemasFinanciacionDeuda/InformacionEELLs/DeudaViva.aspx
"""

import calendar
import csv
import io
import re
import unicodedata
import urllib.parse
import zipfile
from datetime import date

import dlt
import requests

BDE_ZIP = "https://www.bde.es/webbe/es/estadisticas/compartido/datos/zip/{capitulo}.zip"
DEUDA_VIVA_EELL = (
    "https://www.hacienda.gob.es/es-ES/CDI/Paginas/SistemasFinanciacionDeuda/InformacionEELLs/DeudaViva.aspx"
)
CABECERAS = {"User-Agent": "Mozilla/5.0 (compatible; SpainFacts/1.0)"}

MESES = {"ENE": 1, "FEB": 2, "MAR": 3, "ABR": 4, "MAY": 5, "JUN": 6,
         "JUL": 7, "AGO": 8, "SEP": 9, "OCT": 10, "NOV": 11, "DIC": 12}
PERIODO = re.compile(r"^(ENE|FEB|MAR|ABR|MAY|JUN|JUL|AGO|SEP|OCT|NOV|DIC)\s+(\d{4})$")


def _normalizar(texto) -> str:
    """Mayúsculas sin tildes ni espacios sobrantes, para comparar etiquetas."""
    texto = unicodedata.normalize("NFKD", str(texto or ""))
    texto = "".join(c for c in texto if not unicodedata.combining(c))
    return " ".join(texto.upper().split())


def _descargar(url: str) -> bytes:
    respuesta = requests.get(url, timeout=180, headers=CABECERAS)
    respuesta.raise_for_status()
    return respuesta.content


# --------------------------------------------------------------------------
# Boletín Estadístico (CSV dentro de be13.zip / be14.zip)
# --------------------------------------------------------------------------

def _fecha_periodo(periodo: str) -> date | None:
    m = PERIODO.match(periodo.strip().upper())
    if not m:
        return None
    anio, mes = int(m.group(2)), MESES[m.group(1)]
    return date(anio, mes, calendar.monthrange(anio, mes)[1])


def _valor(texto: str) -> float | None:
    # "_" = sin dato; los CSV usan punto decimal y no llevan separador de miles
    texto = (texto or "").strip()
    if texto in ("", "_", "-", "..."):
        return None
    try:
        return float(texto.replace(",", "."))
    except ValueError:
        return None


def _leer_cuadro(contenido: bytes, cuadro: str):
    """Pasa un CSV del Boletín a filas largas (una por serie y periodo).

    La cabecera se detecta por su etiqueta en la primera columna (sin depender
    del número de filas), y los datos son las filas cuya etiqueta es un periodo.
    """
    try:
        texto = contenido.decode("utf-8-sig")
    except UnicodeDecodeError:
        texto = contenido.decode("latin-1")
    filas = list(csv.reader(io.StringIO(texto)))

    meta: dict[str, list[str]] = {}
    for fila in filas:
        if not fila or _fecha_periodo(fila[0]):
            continue
        etiqueta = _normalizar(fila[0])
        for clave, prefijo in (("serie", "CODIGO DE LA SERIE"), ("alias", "ALIAS DE LA SERIE"),
                               ("descripcion", "DESCRIPCION DE LA SERIE"),
                               ("unidad", "DESCRIPCION DE LAS UNIDADES"), ("frecuencia", "FRECUENCIA")):
            if etiqueta.startswith(prefijo) and clave not in meta:
                meta[clave] = [c.strip() for c in fila[1:]]
    if "descripcion" not in meta or not (meta.get("serie") or meta.get("alias")):
        raise ValueError(f"{cuadro}: no se encuentra la cabecera de metadatos")
    codigos = meta.get("serie") or meta["alias"]

    def _meta(clave: str, i: int) -> str | None:
        lista = meta.get(clave, [])
        return lista[i] if i < len(lista) and lista[i] else None

    for fila in filas:
        if not fila:
            continue
        fecha = _fecha_periodo(fila[0])
        if not fecha:
            continue
        for i, celda in enumerate(fila[1:]):
            valor = _valor(celda)
            if valor is None or i >= len(codigos) or not codigos[i]:
                continue
            yield {
                "cuadro": cuadro,
                "serie": codigos[i],
                "alias": _meta("alias", i),
                "descripcion": _meta("descripcion", i),
                "unidad": _meta("unidad", i),
                "frecuencia": _meta("frecuencia", i),
                "periodo": fila[0].strip(),
                "fecha": fecha,
                "valor": valor,
            }


def _cuadros(capitulo: str, cuadros: tuple[str, ...]):
    with zipfile.ZipFile(io.BytesIO(_descargar(BDE_ZIP.format(capitulo=capitulo)))) as z:
        nombres = {n.rsplit("/", 1)[-1].lower(): n for n in z.namelist()}
        for cuadro in cuadros:
            nombre = nombres.get(f"{cuadro}.csv")
            if nombre is None:
                raise FileNotFoundError(f"{cuadro}.csv no está en {capitulo}.zip")
            yield from _leer_cuadro(z.read(nombre), cuadro)


@dlt.resource(name="bde_deuda_ccaa", write_disposition="replace")
def deuda_ccaa():
    # Miles de euros (be1309) y % del PIB regional (be1310), trimestral
    yield from _cuadros("be13", ("be1309", "be1310"))


@dlt.resource(name="bde_saldo_ccaa", write_disposition="replace")
def saldo_ccaa():
    # Capacidad (+) / necesidad (-) de financiación: flujo mensual, miles de euros
    yield from _cuadros("be13", ("be13a",))


@dlt.resource(name="bde_deuda_local", write_disposition="replace")
def deuda_local():
    # Por tipo de entidad e instrumento (be1406), instrumentos y % PIB (be1407),
    # por tamaño (be1408) y ayuntamientos de más de 300.000 habitantes (be1409)
    yield from _cuadros("be14", ("be1406", "be1407", "be1408", "be1409"))


# --------------------------------------------------------------------------
# Deuda viva de las Entidades Locales (Hacienda, datos CIR del Banco de España)
# --------------------------------------------------------------------------

def _filas_excel(contenido: bytes, url: str) -> list[list]:
    """Primera hoja ("Datos") de un .xls o .xlsx como lista de filas."""
    if url.lower().endswith(".xlsx"):
        import openpyxl

        libro = openpyxl.load_workbook(io.BytesIO(contenido), read_only=True, data_only=True)
        return [list(f) for f in libro.worksheets[0].iter_rows(values_only=True)]
    import xlrd

    hoja = xlrd.open_workbook(file_contents=contenido).sheet_by_index(0)
    return [hoja.row_values(i) for i in range(hoja.nrows)]


def _texto(celda) -> str:
    if celda is None:
        return ""
    if isinstance(celda, float) and celda.is_integer():
        celda = int(celda)
    return str(celda).strip()


def _enlaces_deuda_viva() -> list[tuple[str, str, int]]:
    """(url, tipo de entidad, año) de cada Excel publicado en la página de Hacienda."""
    html = requests.get(DEUDA_VIVA_EELL, timeout=60, headers=CABECERAS).text
    enlaces = []
    for href in sorted(set(re.findall(r'href="([^"]+\.xlsx?)"', html, re.I))):
        url = urllib.parse.urljoin(DEUDA_VIVA_EELL, href.replace(" ", "%20"))
        nombre = urllib.parse.unquote(url.rsplit("/", 1)[-1]).lower()
        if "resumen" in nombre:
            continue
        if "ayuntamiento" in nombre or "aytos" in nombre:
            tipo = "ayuntamiento"
        elif "dipycab" in nombre or "diputacion" in nombre:
            tipo = "diputacion_consejo_cabildo"
        elif "resto" in nombre:
            tipo = "resto_eell"
        else:
            continue
        # El año del fichero (31/12) es el primer 20xx del nombre: algunas
        # cabeceras internas arrastran el año anterior por error.
        anio = re.search(r"(20[0-4]\d)", nombre)
        if anio:
            enlaces.append((url, tipo, int(anio.group(1))))
    return enlaces


def _leer_deuda_viva(contenido: bytes, url: str, tipo: str, anio: int):
    filas = _filas_excel(contenido, url)
    # Cabecera: la fila que nombra la provincia y la deuda (su posición y sus
    # columnas cambian entre años: 2011 no trae "Ejercicio" ni nombre de CCAA)
    cab = next(
        (i for i, f in enumerate(filas)
         if any("PROVIN" in _normalizar(c) for c in f) and any("DEUDA" in _normalizar(c) for c in f)),
        None,
    )
    if cab is None:
        raise ValueError(f"{url}: no se encuentra la cabecera")
    nombres = [_normalizar(c) for c in filas[cab]]

    def _col(*condiciones) -> int | None:
        return next((i for i, n in enumerate(nombres) if all(c(n) for c in condiciones)), None)

    c_prov = _col(lambda n: "PROVIN" in n, lambda n: n.startswith("COD"))
    c_mun = _col(lambda n: "MUNICIPIO" in n, lambda n: n.startswith("COD"))
    c_ent = _col(lambda n: "ENTIDAD" in n or "CORPORACION" in n, lambda n: n.startswith("COD"))
    c_nombre = _col(lambda n: n in ("MUNICIPIO", "CORPORACION", "ENTIDAD LOCAL"))
    c_deuda = _col(lambda n: "DEUDA" in n)

    for fila in filas[cab + 1:]:
        celdas = [_texto(c) for c in fila]
        valor = fila[c_deuda] if c_deuda is not None and c_deuda < len(fila) else None
        if not isinstance(valor, (int, float)) or isinstance(valor, bool):
            continue  # fila de nombres técnicos (cdprov, ImpDeudViva...), vacía o notas
        cod_prov = celdas[c_prov] if c_prov is not None else ""
        cod_ent = celdas[c_ent] if c_ent is not None else ""
        if not cod_prov.isdigit() and re.match(r"^\d{2}-\d{2}-", cod_ent):
            cod_prov = cod_ent[3:5]  # "17-46-235-A-E-002": CCAA Hacienda - provincia - ...
        cod_mun = celdas[c_mun] if c_mun is not None else ""
        # Nombre de la entidad; en filas sin provincia (conciliación con el BdE,
        # "sin desagregar", TOTAL) la etiqueta puede estar en cualquier columna
        nombre = celdas[c_nombre] if c_nombre is not None else ""
        if not cod_prov.isdigit():
            nombre = next((c for c in celdas if c and not re.match(r"^[\d.,-]+$", c)), nombre)
        yield {
            "anio": anio,
            "fecha": date(anio, 12, 31),
            "tipo_entidad": tipo,
            "cod_prov": cod_prov.zfill(2) if cod_prov.isdigit() else None,
            "cod_mun": (cod_prov.zfill(2) + cod_mun.zfill(3))
            if tipo == "ayuntamiento" and cod_prov.isdigit() and cod_mun.isdigit() else None,
            "cod_entidad": cod_ent or None,
            "entidad": nombre or None,
            # entidad: una fila por entidad local con provincia
            # total:   totales y subtotales del fichero (con o sin etiqueta)
            # ajuste:  importes sin provincia que suman al total ("Diferencias de
            #          conciliación con el Banco de España", "Sin desagregar",
            #          "Diputaciones Forales del País Vasco" en 2009 y 2011...)
            "tipo_fila": "entidad" if cod_prov.isdigit()
            else "total" if not nombre or _normalizar(nombre).startswith("TOTAL")
            else "ajuste",
            "deuda_miles_eur": float(valor),
            "url": url,
        }


@dlt.resource(name="bde_deuda_viva_eell", write_disposition="replace")
def deuda_viva_eell():
    for url, tipo, anio in _enlaces_deuda_viva():
        yield from _leer_deuda_viva(_descargar(url), url, tipo, anio)


@dlt.source(name="bde")
def bde():
    return [deuda_ccaa, saldo_ccaa, deuda_local, deuda_viva_eell]
