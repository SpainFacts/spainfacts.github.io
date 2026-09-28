"""Fuente dlt para el almacenamiento de electricidad: bombeo y baterías.

1) Balance eléctrico oficial de REE (REData, sin token), bloque "Almacenamiento":
     https://apidatos.ree.es/es/datos/balance/balance-electrico?start_date=...&end_date=...&time_trunc=month
   ids nacionales: 1445 turbinación bombeo, 1472 consumo bombeo, 2180 entrega
   batería, 2181 carga batería, 10483 saldo (MWh; los consumos en negativo).
   La API devuelve 400 con rangos de más de un año: se pide año a año.
   Es la cifra de referencia: la turbinación que se deduce del visor de 5
   minutos (electricidad_5min) sobrestima el bombeo en 2022-2024.

2) ESIOS (requiere ESIOS_TOKEN; ojo: 403 si se manda Content-Type):
   - diario, nacional: 2066 turbinación bombeo, 2065 consumo bombeo, 2198
     entrega de baterías, 2199 carga de baterías. Son MW cada 5 minutos: con
     time_trunc=day&time_agg=sum, energía MWh = suma / 12; con time_agg=max,
     el pico del día (MW).
   - potencia instalada por comunidad (mensual): 1476 turbinación de bombeo
     puro, 2275 baterías hibridadas. No hay indicador de baterías "stand-alone".

3) Capacidad de acceso a la red de transporte (REE, fichero mensual
   AAAA_MM_DD_GRT_generacion.csv enlazado desde "Conoce la capacidad de
   acceso"): por nudo, capacidad de acceso OTORGADA y EN TRAMITACIÓN para
   almacenamiento (columnas "... ALM"). Solo está en línea el fichero del mes
   vigente, así que cada carga guarda una foto (merge por fecha del fichero).
   Solo red de transporte: no incluye las baterías conectadas a distribución.

Recursos:
  ree_balance_almacenamiento     mensual desde 2015, MWh            (replace)
  esios_almacenamiento_diario    diario desde que hay dato, MWh y MW (replace)
  esios_almacenamiento_potencia  mensual por comunidad, MW           (replace)
  ree_acceso_almacenamiento      foto por nudo y fecha del fichero   (merge por fecha)
"""

import csv
import io
import logging
import os
import re
from datetime import date, timedelta

import dlt
import requests

log = logging.getLogger(__name__)

CABECERAS = {"User-Agent": "Mozilla/5.0 (spainfacts.org; datos abiertos)"}
REDATA = "https://apidatos.ree.es/es/datos/balance/balance-electrico"
ESIOS = "https://api.esios.ree.es/indicators/{id}"
PAGINA_ACCESO = "https://www.ree.es/es/clientes/generador/acceso-conexion/conoce-la-capacidad-de-acceso"
PRIMER_ANIO = 2015
PRIMER_ANIO_ESIOS_DIARIO = 2024  # los indicadores 2066/2065/2198/2199 empiezan a finales de 2024

ALMACENAMIENTO_REDATA = {
    "1445": "turbinacion_bombeo", "1472": "consumo_bombeo",
    "2180": "baterias_entrega", "2181": "baterias_carga", "10483": "saldo_almacenamiento",
}
ESIOS_DIARIO = {2066: "turbinacion_bombeo", 2065: "consumo_bombeo", 2198: "baterias_entrega", 2199: "baterias_carga"}
ESIOS_POTENCIA = {1476: "bombeo_puro", 2275: "baterias_hibridadas"}


def _cabeceras_esios() -> dict | None:
    token = os.environ.get("ESIOS_TOKEN")
    if not token:
        return None
    return {"Accept": "application/json; application/vnd.esios-api-v1+json", "x-api-key": token,
            "User-Agent": CABECERAS["User-Agent"]}


def _esios(indicador: int, desde: str, hasta: str, cabeceras: dict, **extra) -> list[dict]:
    r = requests.get(ESIOS.format(id=indicador), headers=cabeceras, timeout=180,
                     params={"start_date": desde, "end_date": hasta, **extra})
    if r.status_code != 200:
        log.warning("ESIOS %s %s-%s: HTTP %s", indicador, desde, hasta, r.status_code)
        return []
    return r.json()["indicator"]["values"]


@dlt.source(name="almacenamiento")
def almacenamiento():
    hoy = date.today()

    @dlt.resource(name="ree_balance_almacenamiento", write_disposition="replace")
    def balance():
        for anio in range(PRIMER_ANIO, hoy.year + 1):
            fin = min(date(anio, 12, 31), hoy)
            r = requests.get(REDATA, headers=CABECERAS, timeout=120, params={
                "start_date": f"{anio}-01-01T00:00", "end_date": f"{fin.isoformat()}T23:59", "time_trunc": "month"})
            if r.status_code != 200:
                log.warning("REData balance %s: HTTP %s", anio, r.status_code)
                continue
            for bloque in r.json().get("included", []):
                if bloque.get("type") != "Almacenamiento":
                    continue
                for c in bloque["attributes"]["content"]:
                    clave = ALMACENAMIENTO_REDATA.get(str(c.get("id")))
                    if not clave:
                        continue
                    for v in c["attributes"].get("values", []):
                        yield {"mes": v["datetime"][:10], "concepto": clave, "mwh": v["value"]}

    @dlt.resource(name="esios_almacenamiento_diario", write_disposition="replace")
    def diario():
        cab = _cabeceras_esios()
        if not cab:
            log.warning("esios_almacenamiento_diario: falta ESIOS_TOKEN, no se carga")
            return
        for anio in range(PRIMER_ANIO_ESIOS_DIARIO, hoy.year + 1):
            desde, hasta = f"{anio}-01-01T00:00", f"{min(date(anio, 12, 31), hoy).isoformat()}T23:59"
            for ind, concepto in ESIOS_DIARIO.items():
                sumas = {v["datetime"][:10]: v["value"] for v in _esios(ind, desde, hasta, cab, time_trunc="day", time_agg="sum")}
                maximos = {v["datetime"][:10]: v["value"] for v in _esios(ind, desde, hasta, cab, time_trunc="day", time_agg="max")}
                minimos = {v["datetime"][:10]: v["value"] for v in _esios(ind, desde, hasta, cab, time_trunc="day", time_agg="min")}
                for dia, suma in sumas.items():
                    # los consumos vienen en negativo: el pico de consumo es el mínimo
                    pico = minimos.get(dia) if suma < 0 else maximos.get(dia)
                    yield {"fecha": dia, "concepto": concepto, "mwh": suma / 12, "pico_mw": pico}

    @dlt.resource(name="esios_almacenamiento_potencia", write_disposition="replace")
    def potencia():
        cab = _cabeceras_esios()
        if not cab:
            return
        for ind, tipo in ESIOS_POTENCIA.items():
            for anio in range(PRIMER_ANIO, hoy.year + 1):
                valores = _esios(ind, f"{anio}-01-01T00:00", f"{min(date(anio, 12, 31), hoy).isoformat()}T23:59", cab)
                if not valores:
                    # ESIOS a veces responde 500 al año completo (2275) pero no a cada mes
                    for mes in range(1, 13):
                        inicio = date(anio, mes, 1)
                        if inicio > hoy:
                            break
                        fin = date(anio + (mes == 12), mes % 12 + 1, 1) - timedelta(days=1)
                        valores += _esios(ind, f"{inicio.isoformat()}T00:00", f"{fin.isoformat()}T23:59", cab)
                for v in valores:
                    yield {"mes": v["datetime"][:10], "tipo": tipo, "ccaa": v.get("geo_name"), "mw": v["value"]}

    @dlt.resource(
        name="ree_acceso_almacenamiento",
        write_disposition={"disposition": "merge", "strategy": "delete-insert"},
        merge_key="fecha_fichero",
    )
    def acceso():
        html = requests.get(PAGINA_ACCESO, headers=CABECERAS, timeout=60).text
        m = re.search(r'href="([^"]*?(\d{4})_(\d{2})_(\d{2})_GRT_generacion\.csv)"', html)
        if not m:
            log.warning("No se encuentra el CSV de capacidad de acceso en %s", PAGINA_ACCESO)
            return
        url = m.group(1) if m.group(1).startswith("http") else "https://www.ree.es" + m.group(1)
        fecha = date(int(m.group(2)), int(m.group(3)), int(m.group(4)))
        texto = requests.get(url, headers=CABECERAS, timeout=120).content.decode("utf-8-sig")
        filas = list(csv.reader(io.StringIO(texto), delimiter=";"))
        grupo, cabecera = "", []
        for a, b in zip(filas[0], filas[1]):
            grupo = a or grupo
            cabecera.append((grupo.upper(), b.strip()))
        i_otorgada = next(i for i, (g, b) in enumerate(cabecera) if "OTORGADA" in g and b.endswith(" ALM"))
        i_curso = next(i for i, (g, b) in enumerate(cabecera) if "TRAMITACI" in g and b.endswith(" ALM"))

        def num(x: str) -> float:
            x = (x or "").strip().replace(".", "").replace(",", ".")
            try:
                return float(x)
            except ValueError:
                return 0.0

        for f in filas[2:]:
            if len(f) <= max(i_otorgada, i_curso) or not f[0].strip() or not f[2].strip():
                continue  # la tercera línea de cabecera y las vacías
            yield {
                "fecha_fichero": fecha, "nudo": f[0].strip(), "subestacion": f[1].strip(), "ccaa": f[2].strip(),
                "otorgada_mw": num(f[i_otorgada]), "en_tramitacion_mw": num(f[i_curso]),
            }

    return balance, diario, potencia, acceso


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("almacenamiento").run(almacenamiento()))
