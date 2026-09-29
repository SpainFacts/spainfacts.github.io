"""Fuente dlt del sistema sanitario: listas de espera, recursos y gasto.

Ministerio de Sanidad
  sanidad_sisle_ccaa          Listas de espera del SNS (SISLE-SNS), situación a 30 de junio y
                              31 de diciembre de cada año, por comunidad autónoma y total SNS:
                              lista quirúrgica (pacientes en espera estructural, tasa por 1.000
                              habitantes, % con más de 6 meses, tiempo medio en días) y consultas
                              externas de atención especializada (tasa por 1.000 hab., tiempo
                              medio, % de citas a más de 60 días).
  sanidad_sisle_especialidad  Las mismas cifras por especialidad (14 quirúrgicas y 10 de consultas;
                              especialidad 'TOTAL' = total SNS de la tabla de especialidades).
                              El ministerio solo publica los informes en PDF (no hay XLSX/CSV):
                              se descargan de sanidad.gob.es (listaEspera.htm y el histórico
                              listaEsperaInfAnt.htm, desde junio de 2013) y se leen sus tablas
                              de texto con pdfplumber.
  sanidad_egsp                Estadística de Gasto Sanitario Público (EGSP, cuentas satélite,
                              XLS egspGastoReal): gasto sanitario público consolidado del sector
                              Comunidades Autónomas por comunidad en euros por habitante (Anexo I.2)
                              y % del PIB regional (Anexo I.1), y gasto total por sector (Tabla 1.3,
                              miles de euros), 2002-último año (los dos últimos, provisionales).

Eurostat (API de diseminación JSON-stat 2.0), países de la UE-27:
  eurostat_san_personal       hlth_rs_prs2: médicos, enfermeras, dentistas, farmacéuticos...
                              por 100.000 hab. y número, según situación (ejerciendo = PRACT,
                              profesionalmente activos = PACT, colegiados = LIC).
  eurostat_san_camas          hlth_rs_bds1: camas hospitalarias disponibles (HBEDT, total).
  eurostat_san_regiones       hlth_rs_physreg (médicos) y hlth_rs_bdsrg2 (camas hospitalarias)
                              por región NUTS 2 española, por 100.000 hab. y número.
  eurostat_san_gasto          hlth_sha11_hf: gasto sanitario corriente por esquema de financiación
                              (total, público y seguros obligatorios, voluntario, pago directo de
                              los hogares) en % del PIB, euros por habitante, PPS por habitante
                              y millones de euros.
"""

import io
import logging
import re
from urllib.parse import urljoin

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series

log = logging.getLogger(__name__)

EUROSTAT = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
UE27 = ["AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES", "FI", "FR", "HR", "HU", "IE",
        "IT", "LT", "LU", "LV", "MT", "NL", "PL", "PT", "RO", "SE", "SI", "SK"]
NUTS2_ES = ["ES11", "ES12", "ES13", "ES21", "ES22", "ES23", "ES24", "ES30", "ES41", "ES42", "ES43",
            "ES51", "ES52", "ES53", "ES61", "ES62", "ES63", "ES64", "ES70"]

SANIDAD = "https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/"
SISLE_PAGINAS = [SANIDAD + "listaEspera.htm", SANIDAD + "listaEsperaInfAnt.htm"]
SISLE_PDF = re.compile(r"(LISTAS_PUBLICACION|Indicadores_?Resumen)[^\"']*\.pdf", re.I)
EGSP_XLS = SANIDAD + "gastoSanitario2005/tablasEstEGSP/egspGastoReal..xls"
UA = {"User-Agent": "Mozilla/5.0 (SpainFacts; datos abiertos)"}

# Nombre (en mayúsculas, como aparece en los informes) -> código INE de comunidad.
# El orden importa: 'LA MANCHA' antes que 'CASTILLA Y LE'.
CCAA_CLAVES = [
    ("ANDALUC", "01"), ("ARAG", "02"), ("ASTURIAS", "03"), ("BALEAR", "04"), ("CANARIAS", "05"),
    ("CANTABRIA", "06"), ("LA MANCHA", "08"), ("CASTILLA Y LE", "07"), ("CATALU", "09"),
    ("VALENCIA", "10"), ("EXTREMADURA", "11"), ("GALICIA", "12"), ("MADRID", "13"),
    ("MURCIA", "14"), ("NAVARRA", "15"), ("VASCO", "16"), ("RIOJA", "17"), ("CEUTA", "18"),
    ("MELILLA", "19"),
]

ESPEC_QUIR = ["Cirugía General y de Digestivo", "Ginecología", "Oftalmología", "ORL", "Traumatología",
              "Urología", "Cirugía Cardiaca", "Angiología /Cir. Vascular", "Cirugía Maxilofacial",
              "Cirugía Pediátrica", "Cirugía Plástica", "Cirugía Torácica", "Neurocirugía",
              "Dermatología"]
ESPEC_CONS = ["Ginecología", "Oftalmología", "Traumatología", "Dermatología", "ORL", "Neurología",
              "C.Gral y A.Digestivo", "Urología", "Digestivo", "Cardiología"]

MESES = {"JUNIO": "06-30", "DICIEMBRE": "12-31"}
ENTERO = re.compile(r"^\d{1,3}(?:\.\d{3})*$")
DEC2 = re.compile(r"^\d+,\d{2}$")
DEC1 = re.compile(r"^\d+,\d$")
DIAS = re.compile(r"^\d+(?:,\d)?$")
NUM = re.compile(r"^-?[\d.,]+$")


def _num(txt):
    return float(txt.replace(".", "").replace(",", "."))


def _cod_ccaa(nombre: str):
    n = nombre.upper()
    if n == "TOTAL":
        return "00"
    for clave, cod in CCAA_CLAVES:
        if clave in n:
            return cod
    return None


def _partir(linea: str):
    """'NOMBRE (*) 1.234 5,67 ...' -> ('NOMBRE', ['1.234', '5,67', ...]) hasta el primer texto."""
    tokens = linea.split()
    nombre, nums = [], []
    for t in tokens:
        if not nums and not NUM.match(t):
            nombre.append(t)
        elif NUM.match(t):
            nums.append(t)
        else:
            break
    return " ".join(x for x in nombre if not x.startswith("(")).strip(), nums


def _secciones(texto: str):
    """Separa el informe en parte quirúrgica y parte de consultas externas."""
    m = re.search(r"SITUACI[OÓ]N DE LA LISTA DE ESPERA (?:DE )?CONSULTAS", texto, re.I)
    if not m:
        return texto, ""
    return texto[: m.start()], texto[m.start():]


def _parsear_sisle(texto: str, url: str):
    m = re.search(r"\b3[01] DE (JUNIO|DICIEMBRE) DE (\d{4})", texto, re.I)
    if not m:
        log.warning("SISLE: sin fecha de corte en %s", url)
        return None, [], []
    fecha = f"{m.group(2)}-{MESES[m.group(1).upper()]}"
    quir, cons = _secciones(texto)
    ccaa, espec = {}, {}

    for linea in quir.splitlines():
        nombre, nums = _partir(linea)
        if not nombre or len(nums) < 3:
            continue
        cod = _cod_ccaa(nombre) if nombre.isupper() else None
        # Tabla por comunidad: pacientes, tasa, [pacientes > 6 meses], [% > 6 meses], días
        if cod and ("q", cod) not in ccaa and len(nums) <= 6 and ENTERO.match(nums[0]) \
                and DEC2.match(nums[1]) and re.match(r"^\d+$", nums[-1]):
            pct = _num(nums[-2]) if len(nums) >= 4 and DEC1.match(nums[-2]) else None
            ccaa[("q", cod)] = {"fecha_corte": fecha, "tipo": "quirurgica", "cod_ccaa": cod,
                                "nombre_informe": nombre, "pacientes": _num(nums[0]),
                                "tasa_1000": _num(nums[1]), "pct_espera_larga": pct,
                                "dias_medio": _num(nums[-1])}
            continue
        # Tabla por especialidad: pacientes, [diferencias], tasa, % > 6 meses, días, [diferencias]
        esp = next((e for e in ESPEC_QUIR + ["TOTAL"] if nombre == e), None)
        if esp and ("q", esp) not in espec and ENTERO.match(nums[0]):
            i = next((k for k in range(1, len(nums)) if DEC2.match(nums[k])), None)
            if i is not None and i + 2 < len(nums) and DEC1.match(nums[i + 1]) and DIAS.match(nums[i + 2]):
                espec[("q", esp)] = {"fecha_corte": fecha, "tipo": "quirurgica", "especialidad": esp,
                                     "pacientes": _num(nums[0]), "tasa_1000": _num(nums[i]),
                                     "pct_espera_larga": _num(nums[i + 1]),
                                     "dias_medio": _num(nums[i + 2])}

    for linea in cons.splitlines():
        nombre, nums = _partir(linea)
        if not nombre or len(nums) < 2:
            continue
        cod = _cod_ccaa(nombre) if nombre.isupper() else None
        # Tabla por comunidad: tasa, días, % citas > 60 días
        if cod and ("c", cod) not in ccaa and len(nums) in (2, 3) and DEC2.match(nums[0]) \
                and re.match(r"^\d+$", nums[1]) and (len(nums) == 2 or DEC1.match(nums[2])):
            ccaa[("c", cod)] = {"fecha_corte": fecha, "tipo": "consultas", "cod_ccaa": cod,
                                "nombre_informe": nombre, "pacientes": None,
                                "tasa_1000": _num(nums[0]),
                                "pct_espera_larga": _num(nums[2]) if len(nums) == 3 else None,
                                "dias_medio": _num(nums[1])}
            continue
        # Tabla por especialidad: tasa, [diferencia], % citas > 60 días, días, [diferencia]
        esp = next((e for e in ESPEC_CONS + ["TOTAL"] if nombre == e), None)
        if esp and ("c", esp) not in espec and re.match(r"^\d+,\d{1,2}$", nums[0]):
            i = next((k for k in range(1, len(nums)) if DEC1.match(nums[k])), None)
            if i is not None and i + 1 < len(nums) and re.match(r"^\d+$", nums[i + 1]):
                espec[("c", esp)] = {"fecha_corte": fecha, "tipo": "consultas", "especialidad": esp,
                                     "pacientes": None, "tasa_1000": _num(nums[0]),
                                     "pct_espera_larga": _num(nums[i]),
                                     "dias_medio": _num(nums[i + 1])}
    return fecha, list(ccaa.values()), list(espec.values())


def _informes_sisle():
    """Descarga y lee los informes SISLE (el más reciente primero; una fecha, un informe)."""
    import pdfplumber

    urls = []
    for pagina in SISLE_PAGINAS:
        html = requests.get(pagina, headers=UA, timeout=120).text
        for href in re.findall(r"href=\"([^\"]+\.pdf)\"", html, re.I):
            if SISLE_PDF.search(href):
                u = urljoin(pagina, href)
                if u not in urls:
                    urls.append(u)
    vistos = set()
    for url in urls:
        r = requests.get(url, headers=UA, timeout=300)
        if r.status_code != 200:
            log.warning("SISLE: %s -> HTTP %s", url, r.status_code)
            continue
        with pdfplumber.open(io.BytesIO(r.content)) as pdf:
            texto = "\n".join((p.dedupe_chars().extract_text() or "") for p in pdf.pages)
        fecha, ccaa, espec = _parsear_sisle(texto, url)
        if fecha is None or fecha in vistos:
            continue
        vistos.add(fecha)
        log.info("SISLE %s: %d filas CCAA, %d especialidad (%s)", fecha, len(ccaa), len(espec), url)
        for fila in ccaa + espec:
            fila["url"] = url
        yield fecha, ccaa, espec


def _egsp():
    import xlrd

    r = requests.get(EGSP_XLS, headers=UA, timeout=300)
    r.raise_for_status()
    wb = xlrd.open_workbook(file_contents=r.content)

    def tabla(hoja, medida, fila_anios=6):
        sh = wb.sheet_by_name(hoja)
        anios = {}
        for c in range(sh.ncols):
            v = str(sh.cell_value(fila_anios, c))
            m = re.match(r"^(\d{4})", v)
            if m:
                anios[c] = (int(m.group(1)), "(*)" in v)
        for f in range(fila_anios + 1, sh.nrows):
            etiqueta = str(sh.cell_value(f, 1)).strip()
            if not etiqueta:
                if any(str(sh.cell_value(f, c)).strip() for c in range(2, sh.ncols)):
                    continue
                if f > fila_anios + 3:
                    break
                continue
            for c, (anio, provisional) in anios.items():
                v = sh.cell_value(f, c)
                if isinstance(v, float):
                    yield {"medida": medida, "etiqueta": etiqueta,
                           "cod_ccaa": None if medida == "miles_eur_sector"
                           else "00" if etiqueta.upper() == "COMUNIDADES AUTÓNOMAS" else _cod_ccaa(etiqueta),
                           "anio": anio, "provisional": provisional, "valor": float(v)}

    yield from tabla("Anexo I.2", "eur_hab_ccaa")
    yield from tabla("Anexo I.1", "pct_pib_ccaa")
    yield from tabla("Tabla 1.3", "miles_eur_sector")


def _filas(dataset: str, dims: list[str], **params):
    params.update(format="JSON", lang="EN")
    r = requests.get(EUROSTAT + dataset, params=params, timeout=300)
    r.raise_for_status()
    for coords, valor in parse_json_stat_series(r.json()):
        if valor is None:
            continue
        fila = {"dataset": dataset, "anio": coords.get("time"), "geo": coords.get("geo")}
        for d in dims:
            fila[d] = coords.get(d)
        fila["valor"] = float(valor)
        yield fila


@dlt.source(name="sanidad")
def sanidad():
    # Los PDF se descargan una sola vez (y solo al extraer, no al definir la fuente)
    # para los dos recursos de listas de espera.
    cache = []

    def informes():
        if not cache:
            cache.extend(_informes_sisle())
        return cache

    @dlt.resource(name="sanidad_sisle_ccaa", write_disposition="replace")
    def sisle_ccaa():
        for _, ccaa, espec in informes():
            yield from ccaa

    @dlt.resource(name="sanidad_sisle_especialidad", write_disposition="replace")
    def sisle_especialidad():
        for _, ccaa, espec in informes():
            yield from espec

    @dlt.resource(name="sanidad_egsp", write_disposition="replace")
    def egsp():
        yield from _egsp()

    @dlt.resource(name="eurostat_san_personal", write_disposition="replace")
    def personal():
        yield from _filas("hlth_rs_prs2", ["med_spec", "wstatus", "unit"], geo=UE27,
                          med_spec=["PHYS", "NRS", "MWS", "DENT", "PHARM"], unit=["P_HTHAB", "NR"])

    @dlt.resource(name="eurostat_san_camas", write_disposition="replace")
    def camas():
        yield from _filas("hlth_rs_bds1", ["unit"], geo=UE27, facility="HBEDT", hlthcare="TOTAL",
                          unit=["P_HTHAB", "NR"])

    @dlt.resource(name="eurostat_san_regiones", write_disposition="replace")
    def regiones():
        for fila in _filas("hlth_rs_physreg", ["unit"], geo=["ES"] + NUTS2_ES, unit=["P_HTHAB", "NR"]):
            yield {**fila, "recurso": "medicos"}
        for fila in _filas("hlth_rs_bdsrg2", ["unit"], geo=["ES"] + NUTS2_ES, unit=["P_HTHAB", "NR"]):
            yield {**fila, "recurso": "camas"}

    @dlt.resource(name="eurostat_san_gasto", write_disposition="replace")
    def gasto():
        yield from _filas("hlth_sha11_hf", ["icha11_hf", "unit"], geo=UE27 + ["EU27_2020"],
                          icha11_hf=["TOT_HF", "HF1", "HF2", "HF3"],
                          unit=["PC_GDP", "EUR_HAB", "PPS_HAB", "MIO_EUR"])

    return sisle_ccaa, sisle_especialidad, egsp, personal, camas, regiones, gasto


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("sanidad").run(sanidad()))
