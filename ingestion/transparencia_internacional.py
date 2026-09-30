"""Fuente dlt de índices internacionales de corrupción, transparencia y gobierno
abierto (tema `transparencia_internacional`), para comparar España con otros países.

Se descargan todos los países (no solo los de referencia) para poder situar a
España entre los de la UE y la OCDE; el filtrado y los nombres van en dbt.

1) Transparency International, Índice de Percepción de la Corrupción (CPI),
   hoja «CPI Timeseries» del Excel anual de resultados (desde 2012, escala
   comparable). Licencia CC BY-ND 4.0: se reproducen las puntuaciones y el
   puesto oficiales tal cual, sin medias ni reescalados propios. El Excel viene
   en OOXML «estricto», que openpyxl no lee: se interpreta el XML a mano. El
   nombre del fichero lleva el año de la edición (CPI2025_Results.xlsx): se
   prueba desde el año en curso hacia atrás.
2) Banco Mundial, Worldwide Governance Indicators (API v2, fuente 3): control de
   la corrupción, voz y rendición de cuentas, eficacia del gobierno y Estado de
   derecho, en la escala 0-100 con su intervalo de confianza del 90 %. CC BY 4.0.
3) V-Dem (Varieties of Democracy) vía Our World in Data: índice de corrupción
   política y de corrupción en el sector público (0-1, series largas desde antes
   de 1977). V-Dem CC BY-SA 4.0, OWID CC BY 4.0.
4) World Justice Project, Rule of Law Index (Excel histórico, hoja «Historical
   Data»): puntuación global y factores 1 (límites al poder del gobierno),
   2 (ausencia de corrupción) y 3 (gobierno abierto). Licencia CC BY-NC-ND 4.0:
   se reproducen las puntuaciones tal cual, sin medias propias.

Recursos (replace): transparencia_int_cpi, transparencia_int_wgi,
transparencia_int_vdem, transparencia_int_wjp.
"""

import csv
import datetime as dt
import io
import logging
import re
import time
import zipfile
import xml.etree.ElementTree as ET

import dlt
import requests

log = logging.getLogger(__name__)

CABECERAS = {"User-Agent": "SpainFacts (https://spainfacts.github.io)"}

CPI_URL = "https://images.transparencycdn.org/images/CPI{anio}_Results.xlsx"
CPI_HOJA = re.compile(r"^CPI Timeseries", re.I)

WGI_URL = "https://api.worldbank.org/v2/country/all/indicator/{cod}?source=3&format=json&per_page=20000"
# código WGI -> indicador_id; de cada uno se trae la puntuación y su intervalo
WGI_INDICADORES = {
    "GOV_WGI_CC": "wgi_control_corrupcion",
    "GOV_WGI_VA": "wgi_voz_rendicion_cuentas",
    "GOV_WGI_GE": "wgi_eficacia_gobierno",
    "GOV_WGI_RL": "wgi_estado_derecho",
}

OWID_URL = "https://ourworldindata.org/grapher/{}.csv?v=1&csvType=full&useColumnShortNames=true"
VDEM_SERIES = {
    # indicador_id: gráfico OWID (la columna de valor es la que no es entity/code/year/región)
    "vdem_corrupcion_politica": "political-corruption-index",
    "vdem_corrupcion_sector_publico": "public-sector-corruption-index",
}

WJP_URL = "https://worldjusticeproject.org/rule-of-law-index/downloads/{anio}_wjp_rule_of_law_index_HISTORICAL_DATA_FILE.xlsx"
WJP_COLUMNAS = {
    # prefijo de la cabecera -> indicador_id
    "WJP Rule of Law Index: Overall Score": "wjp_estado_derecho",
    "Factor 1:": "wjp_limites_gobierno",
    "Factor 2:": "wjp_ausencia_corrupcion",
    "Factor 3:": "wjp_gobierno_abierto",
}


def _get(url: str, intentos: int = 4, **kw) -> requests.Response:
    for i in range(intentos):
        try:
            r = requests.get(url, timeout=180, headers=CABECERAS, **kw)
            r.raise_for_status()
            return r
        except requests.RequestException as e:
            if i == intentos - 1 or (getattr(e, "response", None) is not None and e.response.status_code in (403, 404)):
                # edición anual aún no publicada: la CDN de TI responde 403 y la de WJP 404
                raise
            log.warning("Reintento %s de %s: %s", i + 1, url, e)
            time.sleep(5 * (i + 1))


def _ultima_edicion(plantilla: str) -> tuple[int, bytes]:
    """Descarga la edición más reciente de un fichero anual (prueba del año en curso hacia atrás)."""
    hoy = dt.date.today().year
    for anio in range(hoy, hoy - 4, -1):
        try:
            r = _get(plantilla.format(anio=anio))
        except requests.RequestException as e:
            log.info("Sin edición %s (%s)", anio, e)
            continue
        if r.content[:2] == b"PK":
            return anio, r.content
    raise ValueError(f"No se encontró ninguna edición reciente de {plantilla}")


def _xlsx_filas(contenido: bytes, hoja: re.Pattern) -> list[dict]:
    """Lee una hoja de un .xlsx (también OOXML estricto) como lista de {columna: valor}."""
    z = zipfile.ZipFile(io.BytesIO(contenido))
    wb = ET.fromstring(z.read("xl/workbook.xml"))
    rels = {r.get("Id"): r.get("Target") for r in ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))}
    destino = None
    for s in wb.iter():
        if s.tag.endswith("}sheet") and hoja.search(s.get("name", "").strip()):
            rid = next(v for k, v in s.attrib.items() if k.endswith("}id"))
            destino = rels[rid]
            break
    if destino is None:
        raise ValueError(f"No está la hoja {hoja.pattern}")
    destino = destino.lstrip("/")
    destino = destino if destino.startswith("xl/") else "xl/" + destino
    compartidas = []
    if "xl/sharedStrings.xml" in z.namelist():
        for si in ET.fromstring(z.read("xl/sharedStrings.xml")):
            compartidas.append("".join(t.text or "" for t in si.iter() if t.tag.endswith("}t")))
    filas = []
    for fila in ET.fromstring(z.read(destino)).iter():
        if not fila.tag.endswith("}row"):
            continue
        f = {}
        for c in fila:
            col = re.match(r"[A-Z]+", c.get("r")).group()
            v = None
            for hijo in c:
                if hijo.tag.endswith("}v"):
                    v = hijo.text
                elif hijo.tag.endswith("}is"):
                    v = "".join(t.text or "" for t in hijo.iter() if t.tag.endswith("}t"))
            if c.get("t") == "s" and v is not None:
                v = compartidas[int(v)]
            f[col] = v
        filas.append(f)
    return filas


def _num(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


@dlt.source(name="transparencia_internacional")
def transparencia_internacional():
    @dlt.resource(name="transparencia_int_cpi", write_disposition="replace")
    def cpi():
        edicion, contenido = _ultima_edicion(CPI_URL)
        filas = _xlsx_filas(contenido, CPI_HOJA)
        i_cab = next(i for i, f in enumerate(filas) if (f.get("B") or "").strip() == "ISO3")
        cab = {col: (v or "").strip() for col, v in filas[i_cab].items()}
        # columnas "CPI score 2025", "Rank 2025", "Sources 2025", "Standard error 2025"
        campos = {}
        for col, nombre in cab.items():
            m = re.match(r"(CPI score|Rank|Sources|Standard error) (\d{4})$", nombre, re.I)
            if m:
                campos[col] = (m.group(1).lower(), int(m.group(2)))
        n = 0
        for f in filas[i_cab + 1:]:
            iso3 = (f.get("B") or "").strip()
            if not re.fullmatch(r"[A-Z]{3}", iso3):
                continue
            por_anio = {}
            for col, (campo, anio) in campos.items():
                por_anio.setdefault(anio, {})[campo] = _num(f.get(col))
            for anio, d in por_anio.items():
                if d.get("cpi score") is None:
                    continue
                n += 1
                yield {"cod_pais": iso3, "pais_fuente": f.get("A"), "region": f.get("C"), "anio": anio,
                       "valor": d["cpi score"], "puesto": d.get("rank"), "n_fuentes": d.get("sources"),
                       "error_estandar": d.get("standard error"), "edicion": edicion}
        log.info("CPI %s: %s filas", edicion, n)

    @dlt.resource(name="transparencia_int_wgi", write_disposition="replace")
    def wgi():
        for base, indicador_id in WGI_INDICADORES.items():
            valores = {}
            for sufijo, campo in ((".SC", "valor"), (".SC_LB", "valor_min"), (".SC_UB", "valor_max")):
                datos = _get(WGI_URL.format(cod=base + sufijo)).json()
                if len(datos) < 2 or not datos[1]:
                    raise ValueError(f"WGI sin datos para {base + sufijo}: {datos[0]}")
                for d in datos[1]:
                    if d["value"] is None or not d["countryiso3code"]:
                        continue
                    clave = (d["countryiso3code"], int(d["date"]))
                    valores.setdefault(clave, {"pais_fuente": d["country"]["value"]})[campo] = float(d["value"])
            n = 0
            for (cod, anio), v in valores.items():
                if v.get("valor") is None:
                    continue
                n += 1
                yield {"indicador_id": indicador_id, "cod_indicador": base + ".SC", "cod_pais": cod,
                       "pais_fuente": v["pais_fuente"], "anio": anio, "valor": v["valor"],
                       "valor_min": v.get("valor_min"), "valor_max": v.get("valor_max")}
            log.info("WGI %s: %s filas", base, n)

    @dlt.resource(name="transparencia_int_vdem", write_disposition="replace")
    def vdem():
        for indicador_id, grafico in VDEM_SERIES.items():
            lector = csv.DictReader(io.StringIO(_get(OWID_URL.format(grafico)).text))
            columna = next(c for c in lector.fieldnames if c not in ("entity", "code", "year", "owid_region"))
            n = 0
            for fila in lector:
                if not re.fullmatch(r"[A-Z]{3}", fila.get("code") or "") or not fila.get(columna):
                    continue
                n += 1
                yield {"indicador_id": indicador_id, "cod_indicador": grafico, "cod_pais": fila["code"],
                       "pais_fuente": fila["entity"], "anio": int(fila["year"]), "valor": float(fila[columna])}
            log.info("V-Dem %s (%s): %s filas", grafico, columna, n)

    @dlt.resource(name="transparencia_int_wjp", write_disposition="replace")
    def wjp():
        edicion, contenido = _ultima_edicion(WJP_URL)
        filas = _xlsx_filas(contenido, re.compile(r"^Historical Data$", re.I))
        cab = {col: (v or "").strip() for col, v in filas[0].items()}
        col_pais = next(c for c, v in cab.items() if v == "Country Code")
        col_anio = next(c for c, v in cab.items() if v == "Year")
        col_nombre = next(c for c, v in cab.items() if v == "Country")
        cols = {c: ind for c, v in cab.items() for pref, ind in WJP_COLUMNAS.items() if v.startswith(pref)}
        n = 0
        for f in filas[1:]:
            cod = (f.get(col_pais) or "").strip()
            anio_txt = str(f.get(col_anio) or "").strip()
            if not re.fullmatch(r"[A-Z]{3}", cod) or not anio_txt:
                continue
            # las ediciones bienales se etiquetan "2012-2013" y "2017-2018": se asignan al segundo año
            anio = int(re.findall(r"\d{4}", anio_txt)[-1])
            for col, indicador_id in cols.items():
                v = _num(f.get(col))
                if v is None:
                    continue
                n += 1
                yield {"indicador_id": indicador_id, "cod_pais": cod, "pais_fuente": f.get(col_nombre),
                       "anio": anio, "edicion_fuente": anio_txt, "valor": v, "edicion": edicion}
        log.info("WJP %s: %s filas", edicion, n)

    return [cpi, wgi, vdem, wjp]


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("transparencia_internacional").run(transparencia_internacional()))
