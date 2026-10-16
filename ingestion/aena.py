"""Fuente dlt de los aeropuertos: tráfico de la red de AENA y comparación europea (tema `aena`).

1) AENA, Estadísticas de tráfico aéreo, «Informes mensuales» (descarga abierta, sin registro):
   https://www.aena.es/es/estadisticas/informes-mensuales.html?anio=AAAA
   Un XLS por mes desde enero de 2004 con pasajeros, operaciones (aterrizajes y despegues) y
   mercancía (kg) de cada aeropuerto y helipuerto de la red, llegadas + salidas. Cada página de
   año enlaza el PDF y el XLS de cada mes (blobs de /sites/Satellite).
   - Hasta ~2013 el XLS es binario (.xls, xlrd); después, .xlsx (openpyxl). La extensión no lo
     dice: se mira la firma del fichero.
   - Las tres tablas (pasajeros, operaciones, mercancía) van una al lado de la otra, cada una con
     su propia columna «Aeropuertos» ordenada por su ranking: se casan por nombre.
   - Los nombres cambian con los años (MADRID-BARAJAS -> ADOLFO SUÁREZ MADRID-BARAJAS,
     BARCELONA -> BARCELONA-EL PRAT J.T.) y traen espacios duros: aquí solo se limpian; el
     seed aena_aeropuertos_nombres los traduce al código OACI.
   - Desde 2024 el informe añade los aeropuertos de Aena Brasil (17, con sus totales) y
     Londres-Luton (participada por AENA), y desde junio de 2026 Leeds Bradford: se guardan,
     y dbt se queda con la red española (seed aena_aeropuertos, columna red).
   - Las filas de total se guardan con aeropuerto = TOTAL_ESPANA, TOTAL_REINO_UNIDO o TOTAL_RED
     para comprobar sumas en dbt.
   - Los meses recientes salen como «Datos Provisionales» y AENA los sustituye por los
     definitivos sin cambiar de mes: se guarda la marca `provisional`.

2) Eurostat avia_paoa: pasajeros transportados (llegadas + salidas) por aeropuerto declarante,
   anual, de todos los aeropuertos europeos que publica, total y por cobertura (nacional,
   dentro de la UE-27, fuera de la UE-27). Para el ranking europeo y el reparto
   nacional/internacional de los aeropuertos españoles, que el informe mensual de AENA no da.

Recursos:
  aena_trafico_mensual       merge por (anio, mes, aeropuerto). La primera carga lee desde 2004;
                             las siguientes, solo el año en curso y el anterior (los meses
                             provisionales se sustituyen por los definitivos). Para recargarlo
                             todo, borrar el estado del pipeline o lanzarlo con AENA_COMPLETO=1.
  aena_eurostat_aeropuertos  replace.
"""

import io
import logging
import os
import re
import time
import unicodedata
from datetime import date

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series

log = logging.getLogger(__name__)

BASE = "https://www.aena.es"
PAGINA_ANIO = BASE + "/es/estadisticas/informes-mensuales.html?anio={anio}"
PRIMER_ANIO = 2004
MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
         "septiembre", "octubre", "noviembre", "diciembre"]
CABECERAS = {"User-Agent": "spainfacts.org (datos abiertos; contacto en github.com/SpainFacts)"}

EUROSTAT_PAOA = (
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/avia_paoa"
    "?format=JSON&lang=EN&freq=A&unit=PAS&tra_meas=PAS_CRD&schedule=TOTAL"
    "&tra_cov=TOTAL&tra_cov=NAT&tra_cov=INTL_IEU27_2020&tra_cov=INTL_XEU27_2020"
    f"&sinceTimePeriod={PRIMER_ANIO}"
)


def _get(url: str, intentos: int = 4, **kw) -> requests.Response:
    for i in range(intentos):
        try:
            r = requests.get(url, timeout=120, headers=CABECERAS, **kw)
            r.raise_for_status()
            return r
        except requests.RequestException as e:
            if i == intentos - 1:
                raise
            log.warning("Reintentando %s (%s)", url, e)
            time.sleep(5 * (i + 1))


# ------------------------------------------------------------- índice de informes


def informes(desde: int = PRIMER_ANIO, hasta: int | None = None):
    """(anio, mes, url_xls) de cada informe mensual publicado."""
    hasta = hasta or date.today().year
    for anio in range(desde, hasta + 1):
        html = _get(PAGINA_ANIO.format(anio=anio)).content.decode("latin-1")
        bloques = re.findall(r'<div class="informes" id="([^"]+)">(.*?)<div class="descargas">(.*?)</div>\s*</div>',
                             html, re.S)
        for _, cabecera, descargas in bloques:
            titulo = re.search(r"Informe\s+(\w+)\s+(\d{4})", cabecera, re.I)
            if not titulo or titulo.group(1).lower() not in MESES:
                continue
            if int(titulo.group(2)) != anio:
                log.warning("Informe %s en la página de %s", titulo.group(0), anio)
            enlaces = re.findall(r'href="([^"]+)"[^>]*>.*?titulo-descarga">\s*(\w+)', descargas, re.S)
            xls = [u for u, tipo in enlaces if tipo.upper().startswith("XLS")]
            if not xls:
                log.warning("Sin XLS: %s", titulo.group(0))
                continue
            yield int(titulo.group(2)), MESES.index(titulo.group(1).lower()) + 1, BASE + xls[0].replace("&amp;", "&")


# ------------------------------------------------------------- lectura del XLS


def _hojas(contenido: bytes):
    """Filas (listas de celdas) de cada hoja, sea .xls binario o .xlsx.

    Algunos .xlsx (los exportados desde MicroStrategy, 2022-2023) declaran ~100.000 filas
    vacías: se deja de leer tras 200 filas vacías seguidas."""
    if contenido[:2] == b"PK":
        import openpyxl

        wb = openpyxl.load_workbook(io.BytesIO(contenido), read_only=True, data_only=True)
        hojas = ((f for f in ws.iter_rows(values_only=True)) for ws in wb.worksheets)
    else:
        import xlrd

        wb = xlrd.open_workbook(file_contents=contenido)
        hojas = ((s.row_values(i) for i in range(s.nrows)) for s in wb.sheets())
    for filas in hojas:
        out, vacias = [], 0
        for f in filas:
            f = list(f)
            vacias = vacias + 1 if all(c in (None, "") for c in f) else 0
            if vacias > 200:
                break
            out.append(f)
        yield out


# Filas de total: hasta 2023 el informe solo traía aeropuertos españoles («TOTAL» o «Total
# aeropuertos españoles»); desde que añade Luton, también «Total Red Aena».
TOTALES = {
    "TOTAL": "TOTAL_ESPANA",
    "TOTAL AEROPUERTOS ESPAÑOLES": "TOTAL_ESPANA",
    "TOTAL AEROPUERTOS BRITÁNICOS": "TOTAL_REINO_UNIDO",
    "TOTAL RED AENA": "TOTAL_RED",
    # Aena Brasil (desde 2024): total y sus dos concesiones (ANB y BOAB)
    "TOTAL AEROPUERTOS BRASILEÑOS": "TOTAL_BRASIL",
    "TOTAL ANB": "TOTAL_BRASIL_ANB",
    "TOTAL BOAB": "TOTAL_BRASIL_BOAB",
}


def limpiar_nombre(texto) -> str:
    t = unicodedata.normalize("NFC", str(texto)).replace("\xa0", " ").replace("\n", " ")
    return re.sub(r"\s+", " ", t).strip().upper()


def _numero(v):
    if isinstance(v, (int, float)):
        return float(v)
    if isinstance(v, str):
        t = v.strip().replace(".", "").replace(",", ".")
        try:
            return float(t)
        except ValueError:
            return None
    return None


def leer_informe(contenido: bytes):
    """{aeropuerto: {pasajeros, operaciones, mercancia_kg}} y si los datos son provisionales."""
    for filas in _hojas(contenido):
        cabecera = None
        for i, fila in enumerate(filas[:30]):
            cols = [j for j, c in enumerate(fila) if isinstance(c, str) and limpiar_nombre(c) == "AEROPUERTOS"]
            if len(cols) >= 3:
                cabecera = i, cols[:3]
                break
        if not cabecera:
            continue
        texto = " ".join(limpiar_nombre(c) for f in filas[:12] for c in f if isinstance(c, str))
        provisional = "PROVISIONAL" in texto
        i0, cols = cabecera
        # La columna del valor es la primera «Total» a la derecha de cada «Aeropuertos» (en
        # 2009-2020 hay columnas combinadas vacías en medio).
        cab = [limpiar_nombre(c) if isinstance(c, str) else "" for c in filas[i0]]
        valores = []
        for j in cols:
            k = next((k for k in range(j + 1, len(cab)) if cab[k] == "TOTAL"), None)
            if k is None:
                raise ValueError(f"Sin columna Total tras la columna {j}: {cab}")
            valores.append(k)
        datos: dict[str, dict] = {}
        for fila in filas[i0 + 1:]:
            for medida, j, k in zip(("pasajeros", "operaciones", "mercancia_kg"), cols, valores):
                if k >= len(fila):
                    continue
                nombre, valor = fila[j], _numero(fila[k])
                if not isinstance(nombre, str) or not nombre.strip() or valor is None:
                    continue
                nombre = TOTALES.get(limpiar_nombre(nombre), limpiar_nombre(nombre))
                datos.setdefault(nombre, {})[medida] = valor
        if datos:
            return datos, provisional
    raise ValueError("No se encontró la tabla de aeropuertos en el informe")


def _descargar(url: str) -> bytes:
    """Con AENA_CACHE=<carpeta> guarda los XLS (para pruebas: evita volver a bajarlos)."""
    cache = os.environ.get("AENA_CACHE")
    if not cache:
        return _get(url).content
    ruta = os.path.join(cache, re.search(r"blobwhere=(\d+)", url).group(1) + ".bin")
    if not os.path.exists(ruta):
        os.makedirs(cache, exist_ok=True)
        with open(ruta, "wb") as f:
            f.write(_get(url).content)
    with open(ruta, "rb") as f:
        return f.read()


def trafico_mensual(desde: int = PRIMER_ANIO, hasta: int | None = None):
    for anio, mes, url in informes(desde, hasta):
        datos, provisional = leer_informe(_descargar(url))
        if not {"TOTAL_ESPANA", "TOTAL_RED"} & datos.keys():
            raise ValueError(f"Informe {mes}/{anio} sin fila de total: {sorted(datos)[:5]}...")
        log.info("AENA %s/%s: %s filas%s", mes, anio, len(datos), " (provisional)" if provisional else "")
        for nombre, m in datos.items():
            yield {
                "anio": anio,
                "mes": mes,
                "aeropuerto": nombre,
                "pasajeros": m.get("pasajeros"),
                "operaciones": m.get("operaciones"),
                "mercancia_kg": m.get("mercancia_kg"),
                "provisional": provisional,
                "fuente_url": url,
            }


# ------------------------------------------------------------- Eurostat


def eurostat_aeropuertos():
    datos = _get(EUROSTAT_PAOA).json()
    if "error" in datos:
        raise ValueError(f"Eurostat avia_paoa: {datos['error']}")
    nombres = datos["dimension"]["rep_airp"]["category"]["label"]
    n = 0
    for fila, valor in parse_json_stat_series(datos):
        codigo = fila["rep_airp"]
        if valor is None:
            continue
        n += 1
        yield {
            "cod_aeropuerto": codigo,
            "pais": codigo.split("_")[0],
            "oaci": codigo.split("_", 1)[1] if "_" in codigo else None,
            "nombre": nombres.get(codigo),
            "nombre_legible": nombre_legible(nombres.get(codigo)),
            "cobertura": fila["tra_cov"],
            "anio": int(fila["time"]),
            "pasajeros": valor,
        }
    log.info("Eurostat avia_paoa: %s filas", n)


def nombre_legible(etiqueta: str | None) -> str | None:
    """'PARIS-CHARLES DE GAULLE airport' -> 'Paris-Charles de Gaulle'."""
    if not etiqueta:
        return None
    t = re.sub(r"\s+airport$", "", etiqueta.strip(), flags=re.I).title()
    return re.sub(r"(?<=[ /-])(De|Del|Di|Da|La|Le|Am|Im)(?= )", lambda m: m.group(1).lower(), t)


@dlt.source(name="aena", max_table_nesting=0)
def aena():
    @dlt.resource(name="aena_trafico_mensual", write_disposition="merge", primary_key=("anio", "mes", "aeropuerto"))
    def r_trafico():
        estado = dlt.current.resource_state()
        completo = not estado.get("carga_completa") or os.environ.get("AENA_COMPLETO") == "1"
        yield from trafico_mensual(PRIMER_ANIO if completo else date.today().year - 1)
        estado["carga_completa"] = True

    @dlt.resource(name="aena_eurostat_aeropuertos", write_disposition="replace")
    def r_eurostat():
        yield from eurostat_aeropuertos()

    return r_trafico, r_eurostat


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("aena").run(aena()))
