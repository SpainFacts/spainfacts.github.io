"""Fuente dlt para la sección de Vivienda.

1) INE (API Tempus3, todas las series de cada tabla, carga completa):
   - 25171  Índice de Precios de Vivienda (IPV, base 2015), trimestral, nacional y
            CCAA, general / vivienda nueva / segunda mano.
   - 59057  Índice de Precios de Vivienda en Alquiler (IPVA, base 2015), anual, CCAA
            (sin País Vasco ni Navarra: sus datos fiscales son forales).
   - 6150   Estadística de Transmisiones de Derechos de la Propiedad (ETDP):
            compraventas de viviendas por mes, nacional, CCAA y provincia,
            general / nueva / segunda mano / libre / protegida.
   - 13896  Estadística de Hipotecas (H): número e importe (miles de euros) por mes
            y CCAA según naturaleza de la finca (nos interesa "Viviendas").
   - 3200   Ídem por provincia.
   (El salario por comunidad para el esfuerzo de compra sale de la tabla 6061
   de la ETCL, que ya carga otro módulo: mart economia_salarios_ccaa.)

2) Ministerio de Vivienda y Agenda Urbana (MIVAU), boletín estadístico en XLS
   (https://apps.fomento.gob.es/BoletinOnline2/sedal/<fichero>.XLS):
   - 35101000  Valor tasado medio de la vivienda libre (€/m²), trimestral desde
               1995, nacional, CCAA y provincia (tasaciones hipotecarias).
   - 35103500  Ídem para municipios de más de 25.000 habitantes (una hoja por
               trimestre desde 2005), con el número de tasaciones.
   - 32200500  Viviendas libres iniciadas por año (certificados de los colegios de
               aparejadores), CCAA y provincia, desde 1991.
   - 32201000  Viviendas libres terminadas por año (ídem).

3) Sistema Estatal de Referencia del Precio del Alquiler de Vivienda (SERPAVI,
   MIVAU con datos del IRPF de la AEAT), 2011-2024: alquiler mediano en €/m² y
   €/mes, por CCAA, provincia y municipio y tipología (colectiva/unifamiliar).
   https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi
   El nombre del XLSX cambia en cada publicación, así que se busca en la página.

Recursos (replace):
  ine_ipv, ine_ipva_ccaa, ine_compraventas, ine_hipotecas_ccaa,
  ine_hipotecas_provincias (formato Tempus: cod_serie, serie,
  fecha, anyo, valor, secreto)
  vivienda_valor_tasado            nivel, cod, nombre, anio, trimestre, euros_m2
  vivienda_valor_tasado_municipios provincia, cod_prov, municipio, anio, trimestre,
                                   euros_m2, tasaciones
  vivienda_obra_nueva              nivel, cod, nombre, anio, fase, viviendas
  vivienda_serpavi                 nivel, cod, nombre, anio, tipologia, ...
"""

import io
import logging
import re
import unicodedata

import dlt
import requests

from ingestion.ine import _tabla_resource

log = logging.getLogger(__name__)

CABECERAS = {"User-Agent": "Mozilla/5.0 (spainfacts.org; datos abiertos)"}
BOLETIN = "https://apps.fomento.gob.es/BoletinOnline2/sedal/{}.XLS"
SERPAVI_WEB = "https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi"

TABLAS_INE = {
    "ine_ipv": "25171",
    "ine_ipva_ccaa": "59057",
    "ine_compraventas": "6150",
    "ine_hipotecas_ccaa": "13896",
    "ine_hipotecas_provincias": "3200",
}


def _norm(texto: str) -> str:
    """Minúsculas, sin tildes, sin notas '(1)' ni artículos entre paréntesis."""
    t = unicodedata.normalize("NFKD", str(texto)).encode("ascii", "ignore").decode().lower()
    t = re.sub(r"\(\d+\)", "", t)
    return re.sub(r"[^a-z]", "", t)


# Nombres del boletín del Ministerio (normalizados) -> código INE de CCAA
CCAA = {
    "totalnacional": "00", "andalucia": "01", "aragon": "02", "asturiasprincipadode": "03",
    "principadodeasturias": "03", "asturias": "03", "balearsilles": "04", "illesbalears": "04",
    "balears": "04", "canarias": "05", "cantabria": "06", "castillayleon": "07",
    "castillalamancha": "08", "cataluna": "09", "comunidadvalenciana": "10",
    "comunitatvalenciana": "10", "extremadura": "11", "galicia": "12",
    "madridcomunidadde": "13", "comunidaddemadrid": "13", "madrid": "13",
    "murciaregionde": "14", "regiondemurcia": "14", "murcia": "14",
    "navarracomunidadforalde": "15", "navarracomforalde": "15", "comunidadforaldenavarra": "15", "navarra": "15",
    "paisvasco": "16", "riojala": "17", "larioja": "17", "rioja": "17",
    "ceuta": "18", "melilla": "19",
}
# Comunidades uniprovinciales (y Ceuta/Melilla): código de su provincia
UNIPROVINCIAL = {"03": "33", "04": "07", "06": "39", "13": "28", "14": "30", "15": "31", "17": "26", "18": "51", "19": "52"}

PROVINCIAS = {
    "alava": "01", "araba": "01", "arabaalava": "01", "albacete": "02", "alicante": "03", "alacant": "03",
    "almeria": "04", "avila": "05", "badajoz": "06", "barcelona": "08", "burgos": "09", "caceres": "10",
    "cadiz": "11", "castellon": "12", "castello": "12", "ciudadreal": "13", "cordoba": "14",
    "corunaa": "15", "acoruna": "15", "coruna": "15", "cuenca": "16", "girona": "17", "granada": "18",
    "guadalajara": "19", "gipuzkoa": "20", "guipuzcoa": "20", "huelva": "21", "huesca": "22", "jaen": "23",
    "leon": "24", "lleida": "25", "lugo": "27", "malaga": "29", "ourense": "32", "palencia": "34",
    "palmaslas": "35", "laspalmas": "35", "pontevedra": "36", "salamanca": "37",
    "santacruzdetenerife": "38", "segovia": "40", "sevilla": "41", "soria": "42", "tarragona": "43",
    "teruel": "44", "toledo": "45", "valencia": "46", "valladolid": "47", "bizkaia": "48",
    "vizcaya": "48", "zamora": "49", "zaragoza": "50",
    # erratas y cortes de línea del boletín de municipios
    "lacoruna": "15", "cordaba": "14", "valladodid": "47", "santacruzde": "38", "tenerife": "38",
}


def _cod_provincia(nombre: str):
    n = _norm(nombre)
    if n in PROVINCIAS:
        return PROVINCIAS[n]
    for parte in str(nombre).split("/"):
        p = _norm(parte)
        if p in PROVINCIAS:
            return PROVINCIAS[p]
    return None


def _territorio(nombre: str):
    """Devuelve [(nivel, cod)] para un nombre del boletín del Ministerio."""
    n = _norm(nombre)
    if n in ("totalnacional", "espana"):
        return [("pais", "00")]
    if n in CCAA:
        cod = CCAA[n]
        salida = [("ccaa", cod)]
        if cod in UNIPROVINCIAL:
            salida.append(("provincia", UNIPROVINCIAL[cod]))
        return salida
    cod = _cod_provincia(nombre)
    return [("provincia", cod)] if cod else []


def _num(v):
    if isinstance(v, (int, float)):
        return float(v)
    try:
        return float(str(v).replace(",", "."))
    except ValueError:
        return None  # 'n.r' (no representativo), vacíos


def _xls(fichero: str):
    import xlrd

    r = requests.get(BOLETIN.format(fichero), headers=CABECERAS, timeout=300)
    r.raise_for_status()
    return xlrd.open_workbook(file_contents=r.content)


def _filas_valor_tasado():
    """Tabla 1 del boletín: €/m² por trimestre; cada hoja agrupa 4-5 años."""
    libro = _xls("35101000")
    vistos = set()
    for hoja in libro.sheets():
        fila_anios = None
        for i in range(min(hoja.nrows, 30)):
            if any(re.match(r"\s*A\S+o\s+\d{4}", str(c)) for c in hoja.row_values(i)):
                fila_anios = i
                break
        if fila_anios is None:
            continue
        cols = {}  # columna -> (anio, trimestre)
        anio_actual, col_inicio = None, None
        for j, c in enumerate(hoja.row_values(fila_anios)):
            m = re.search(r"(\d{4})", str(c))
            if m:
                anio_actual, col_inicio = int(m.group(1)), j
            # la fila de trimestres ('1º', '2º'...) está dos filas más abajo; tras
            # el último año vienen columnas de variación que hay que descartar
            etiqueta = str(hoja.cell_value(fila_anios + 2, j)) if fila_anios + 2 < hoja.nrows else ""
            mt = re.match(r"\s*([1-4])\D", etiqueta + " ")
            if anio_actual is not None and mt and j - col_inicio < 4:
                cols[j] = (anio_actual, int(mt.group(1)))
        for i in range(fila_anios + 1, hoja.nrows):
            fila = hoja.row_values(i)
            nombre = str(fila[1]).strip()
            if not nombre:
                continue
            territorios = _territorio(nombre)
            if not territorios:
                if not nombre.lower().startswith(("ceuta y", "n.r", "(", "nota", "fuente", "a")):
                    log.warning("Valor tasado: territorio no reconocido %r", nombre)
                continue
            for j, (anio, trim) in cols.items():
                v = _num(fila[j]) if j < len(fila) else None
                if v is None:
                    continue
                for nivel, cod in territorios:
                    clave = (nivel, cod, anio, trim)
                    if clave in vistos:
                        continue
                    vistos.add(clave)
                    yield {"nivel": nivel, "cod": cod, "nombre": nombre, "anio": anio, "trimestre": trim, "euros_m2": v}


def _filas_valor_tasado_municipios():
    """Tabla 4/5 del boletín: una hoja por trimestre ('T1A2005'...)."""
    libro = _xls("35103500")
    for hoja in libro.sheets():
        m = re.match(r"\s*T(\d)A(\d{4})", hoja.name)
        if not m:
            continue
        trim, anio = int(m.group(1)), int(m.group(2))
        cab = None
        for i in range(min(hoja.nrows, 40)):
            if str(hoja.cell_value(i, 1)).strip() == "Provincia":
                cab = i
                break
        if cab is None:
            continue
        totales = [j for j, c in enumerate(hoja.row_values(cab + 1)) if str(c).strip() == "Total"]
        if len(totales) < 2:
            continue
        col_valor, col_tasaciones = totales[0], totales[-1]
        provincia = None
        for i in range(cab + 2, hoja.nrows):
            fila = hoja.row_values(i)
            if str(fila[1]).strip():
                provincia = str(fila[1]).strip()
            municipio = str(fila[2]).strip()
            if not municipio or provincia is None:
                continue
            yield {
                "provincia": provincia,
                "cod_prov": _cod_provincia(provincia) or (UNIPROVINCIAL.get(CCAA.get(_norm(provincia), ""), None)),
                "municipio": municipio,
                "anio": anio,
                "trimestre": trim,
                "euros_m2": _num(fila[col_valor]),
                "tasaciones": _num(fila[col_tasaciones]),
            }


def _filas_obra_nueva():
    for fichero, fase in (("32200500", "Iniciadas"), ("32201000", "Terminadas")):
        libro = _xls(fichero)
        hoja = libro.sheet_by_index(0)
        fila_anios, cols = None, {}
        for i in range(min(hoja.nrows, 30)):
            anios = {j: int(c) for j, c in enumerate(hoja.row_values(i)) if isinstance(c, float) and 1950 < c < 2100}
            if len(anios) > 5:
                fila_anios, cols = i, anios
                break
        if fila_anios is None:
            raise ValueError(f"Cabecera de años no encontrada en {fichero}")
        vistos = set()
        for i in range(fila_anios + 1, hoja.nrows):
            fila = hoja.row_values(i)
            nombre = str(fila[1]).strip()
            territorios = _territorio(nombre) if nombre else []
            for j, anio in cols.items():
                v = _num(fila[j])
                if v is None:
                    continue
                for nivel, cod in territorios:
                    if (nivel, cod, anio) in vistos:
                        continue
                    vistos.add((nivel, cod, anio))
                    yield {"nivel": nivel, "cod": cod, "nombre": nombre, "anio": anio, "fase": fase, "viviendas": v}


SERPAVI_MEDIDAS = {
    "BI_ALVHEPCO_T{t}": "viviendas_alquiladas",
    "ALQM2_LV_M_{t}": "alquiler_m2_mediana",
    "ALQM2_LV_25_{t}": "alquiler_m2_p25",
    "ALQM2_LV_75_{t}": "alquiler_m2_p75",
    "ALQTBID12_M_{t}": "alquiler_mes_mediana",
    "ALQTBID12_25_{t}": "alquiler_mes_p25",
    "ALQTBID12_75_{t}": "alquiler_mes_p75",
    "SLVM2_M_{t}": "superficie_mediana",
}


def _url_serpavi() -> str:
    r = requests.get(SERPAVI_WEB, headers=CABECERAS, timeout=120)
    r.raise_for_status()
    enlaces = re.findall(r'https://[^"\']*serpavi[^"\']*\.xlsx', r.text, flags=re.I)
    if not enlaces:
        raise ValueError("No se encuentra el XLSX del SERPAVI en la web del Ministerio")
    return enlaces[0].replace(" ", "%20")


def _filas_serpavi():
    import openpyxl

    r = requests.get(_url_serpavi(), headers=CABECERAS, timeout=600)
    r.raise_for_status()
    libro = openpyxl.load_workbook(io.BytesIO(r.content), read_only=True, data_only=True)
    for hoja, nivel, col_cod, col_nombre in (("CCAA", "ccaa", "CCAA", "LITCCAA"), ("Provincias", "provincia", "CPRO", "LITPRO"), ("Municipios", "municipio", "CUMUN", "NMUN")):
        filas = libro[hoja].iter_rows(values_only=True)
        cab = [str(c) if c is not None else "" for c in next(filas)]
        idx = {c: i for i, c in enumerate(cab)}
        anios = sorted({int(m.group(1)) for c in cab if (m := re.search(r"_(\d{2})$", c))})
        for fila in filas:
            cod = fila[idx[col_cod]]
            if cod is None or not str(cod).strip():
                continue
            cod = str(cod).strip()
            cod = cod.zfill(5 if nivel == "municipio" else 2)
            for aa in anios:
                for tipo, tipologia in (("VC", "Colectiva"), ("VU", "Unifamiliar")):
                    registro = {"nivel": nivel, "cod": cod, "nombre": fila[idx[col_nombre]], "anio": 2000 + aa, "tipologia": tipologia}
                    hay = False
                    for patron, campo in SERPAVI_MEDIDAS.items():
                        # p. ej. ALQM2_LV_M_VC_24 o BI_ALVHEPCO_TVC_24
                        j = idx.get(patron.format(t=tipo) + f"_{aa:02d}")
                        v = _num(fila[j]) if j is not None and fila[j] is not None else None
                        registro[campo] = v
                        hay = hay or v is not None
                    if hay:
                        yield registro


@dlt.source(name="vivienda")
def vivienda():
    recursos = [_tabla_resource(nombre, tabla) for nombre, tabla in TABLAS_INE.items()]

    @dlt.resource(name="vivienda_valor_tasado", write_disposition="replace")
    def valor_tasado():
        yield from _filas_valor_tasado()

    @dlt.resource(name="vivienda_valor_tasado_municipios", write_disposition="replace")
    def valor_tasado_municipios():
        yield from _filas_valor_tasado_municipios()

    @dlt.resource(name="vivienda_obra_nueva", write_disposition="replace")
    def obra_nueva():
        yield from _filas_obra_nueva()

    @dlt.resource(name="vivienda_serpavi", write_disposition="replace")
    def serpavi():
        yield from _filas_serpavi()

    return recursos + [valor_tasado, valor_tasado_municipios, obra_nueva, serpavi]
