"""Fuente dlt para la curva de demanda y generación en tiempo real de REE.

Red Eléctrica publica en su visor "REData / Demanda en tiempo real"
(https://demanda.ree.es/visiona/) la demanda y la generación por tecnología
cada 5 minutos para la península, Baleares y Canarias. El backend del visor
es un servicio REST sin clave (no documentado) que responde en JSONP:

  https://demanda.ree.es/WSvisionaMoviles<Sis>Rest/resources/demandaGeneracion<Sis>
      ?callback=cb&curva=<CURVA>&fecha=YYYY-MM-DD

Cada petición devuelve ~30 horas (de las 21:00 del día anterior a las 03:00
del siguiente; en Canarias una hora menos, en hora canaria). Aquí solo se
guardan las filas cuya fecha local coincide con la pedida, de modo que cada
instante se descarga una vez y la carga "merge" es idempotente.

Horas repetidas por el cambio de hora: REE las etiqueta "2A"/"2B" (península y
Baleares) o "1A"/"1B" (Canarias). "A" es la primera pasada (horario de verano)
y "B" la segunda; se convierten a UTC con zoneinfo (fold=0/1).

Tablas (esquema `raw`):
1. ree_visiona_5min: una fila por sistema e instante de 5 minutos, con todos
   los campos numéricos del visor en MW (nombres en snake_case: solFot ->
   sol_fot, consBat -> cons_bat...). merge por (sistema, ts_utc). Incremental:
   por defecto desde la última fecha cargada menos 2 días hasta hoy.
   Histórico: península desde 2012, Canarias desde 2012, Baleares desde 2018.
   REE_VISIONA_FECHA_INICIO fija el inicio de la primera carga (2015-01-01).
2. ree_precios: precios horarios/cuartohorarios del mercado (REData,
   mercados/precios-mercados-tiempo-real): PVPC y precio spot del mercado
   diario, en €/MWh. merge por (indicador, ts_utc).
3. ree_coeficientes_co2: factores de emisión (t CO2/MWh) por sistema y
   tecnología que usa el visor. Carga completa ("replace").
4. esios_intercambios: saldo neto telemedido por frontera (Francia, Portugal,
   Marruecos, Andorra; + = importación) de la API ESIOS de REE (indicadores
   10207-10209 y 10047, requiere ESIOS_TOKEN). ESIOS da energía (MWh) por periodo, horario
   hasta 2022 y cuartohorario después; saldo_mw = MW medios del periodo.
   merge por (frontera, ts_utc).

Se respeta un máximo de 1 petición por segundo, con reintentos y espera
exponencial.
"""

import json
import logging
import os
import time
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import dlt
import requests

log = logging.getLogger(__name__)

CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.org)", "Accept": "application/json"}
VISIONA = "https://demanda.ree.es/WSvisionaMoviles{s}Rest/resources/"
REDATA_PRECIOS = "https://apidatos.ree.es/es/datos/mercados/precios-mercados-tiempo-real"

# sistema -> (sufijo del servicio, curva, zona horaria de las marcas de tiempo)
SISTEMAS = {
    "peninsula": ("Peninsula", "DEMANDAAU", "Europe/Madrid"),
    "baleares": ("Baleares", "BALEARESAU", "Europe/Madrid"),
    "canarias": ("Canarias", "CANARIASAU", "Atlantic/Canary"),
}
# Primer día con datos en el visor (antes devuelve listas vacías)
INICIO_SISTEMA = {"peninsula": date(2012, 1, 1), "baleares": date(2018, 1, 1), "canarias": date(2012, 1, 1)}
PRECIOS_INICIO = date(2014, 4, 1)

# ESIOS (api.esios.ree.es, requiere ESIOS_TOKEN): saldo neto telemedido por frontera
# (+ = importación), horario desde 2015 y cuartohorario desde el mercado de 15 min.
# Sirve para tener los intercambios por país antes de finales de 2024, cuando el
# visor de 5 minutos aún no los desglosaba.
ESIOS = "https://api.esios.ree.es/indicators/{id}"
# Andorra no tiene telemedida (10210 llega vacío): se usa la generación medida de
# liquidación (10047, "Generación medida Saldo Andorra"), que llega con meses de retraso.
ESIOS_FRONTERAS = {10207: "francia", 10208: "portugal", 10209: "marruecos", 10047: "andorra"}
ESIOS_INICIO = date(2015, 1, 1)
MADRID = ZoneInfo("Europe/Madrid")

_ultima_peticion = 0.0


def _get(url: str, params: dict | None = None, intentos: int = 6, cabeceras: dict | None = None) -> requests.Response:
    """GET educado: como mucho 1 petición/segundo y reintentos con espera exponencial."""
    global _ultima_peticion
    espera = 2.0
    for intento in range(intentos):
        pausa = 1.0 - (time.monotonic() - _ultima_peticion)
        if pausa > 0:
            time.sleep(pausa)
        _ultima_peticion = time.monotonic()
        try:
            r = requests.get(url, params=params, headers=cabeceras or CABECERAS, timeout=120)
            if r.status_code < 500 and r.status_code != 429:
                return r
            log.warning("HTTP %s en %s (intento %s)", r.status_code, url, intento + 1)
        except requests.RequestException as e:
            log.warning("Error de red en %s: %s (intento %s)", url, e, intento + 1)
        time.sleep(espera)
        espera = min(espera * 2, 120)
    r = requests.get(url, params=params, headers=cabeceras or CABECERAS, timeout=120)
    r.raise_for_status()
    return r


def _jsonp(texto: str):
    # "cb({...});" -> {...}
    return json.loads(texto[texto.index("(") + 1 : texto.rindex(")")])


def _hoy() -> date:
    return datetime.now(MADRID).date()


def _ts_utc(ts: str, zona: ZoneInfo) -> tuple[str, datetime]:
    """'2018-10-28 2B:05' -> ('2018-10-28 02:05', instante UTC) resolviendo el cambio de hora."""
    fecha, hora = ts.split(" ")
    hh, mm = hora.split(":")
    fold = 0
    if hh[-1] in "AB":
        fold = 1 if hh[-1] == "B" else 0
        hh = hh[:-1]
    local = datetime.fromisoformat(f"{fecha} {int(hh):02d}:{mm}").replace(tzinfo=zona, fold=fold)
    return f"{fecha} {int(hh):02d}:{mm}", local.astimezone(timezone.utc)


def _dia_visiona(sistema: str, dia: date) -> list[dict]:
    sufijo, curva, tz = SISTEMAS[sistema]
    zona = ZoneInfo(tz)
    url = VISIONA.format(s=sufijo) + f"demandaGeneracion{sufijo}"
    r = _get(url, {"callback": "cb", "curva": curva, "fecha": dia.isoformat()})
    r.raise_for_status()
    valores = _jsonp(r.text).get("valoresHorariosGeneracion") or []
    filas, vistos = [], set()
    for v in valores:
        ts = v.get("ts")
        if not ts or not ts.startswith(dia.isoformat()):
            continue  # solapes con el día anterior/siguiente: los trae su propia petición
        ts_local, ts_utc = _ts_utc(ts, zona)
        if ts_utc in vistos:
            continue
        vistos.add(ts_utc)
        fila = {"sistema": sistema, "ts_local": ts_local, "ts_ree": ts, "ts_utc": ts_utc, "fecha": dia}
        for k, x in v.items():
            if k != "ts":
                # siempre float: la península da enteros y las islas decimales
                fila[k] = None if x is None else float(x)
        filas.append(fila)
    return filas


def _rango(desde: date | None, hasta: date | None, estado: dict, clave: str, inicio: date) -> tuple[date, date]:
    hasta = hasta or _hoy()
    if desde is None:
        ultima = estado.get(clave)
        desde = date.fromisoformat(ultima) - timedelta(days=2) if ultima else inicio
    return desde, hasta


@dlt.resource(
    name="ree_visiona_5min",
    write_disposition="merge",
    primary_key=("sistema", "ts_utc"),
    columns={
        "sistema": {"data_type": "text", "nullable": False},
        "ts_utc": {"data_type": "timestamp", "timezone": True, "nullable": False},
        "ts_local": {"data_type": "text"},
        "ts_ree": {"data_type": "text"},
        "fecha": {"data_type": "date"},
    },
)
def visiona_5min(desde: date | None = None, hasta: date | None = None, sistemas: tuple[str, ...] = tuple(SISTEMAS)):
    estado = dlt.current.resource_state()
    inicio = date.fromisoformat(os.environ.get("REE_VISIONA_FECHA_INICIO", "2015-01-01"))
    desde, hasta = _rango(desde, hasta, estado, "ultima_fecha", inicio)
    log.info("ree_visiona_5min: %s -> %s", desde, hasta)
    dia = desde
    while dia <= hasta:
        for sistema in sistemas:
            if dia < INICIO_SISTEMA[sistema]:
                continue
            try:
                filas = _dia_visiona(sistema, dia)
            except Exception as e:  # un día roto no debe tumbar la carga entera
                log.warning("ree_visiona %s %s: %s", sistema, dia, e)
                continue
            if filas:
                yield filas
        # la fecha de hoy se volverá a pedir en la próxima carga (desde = última - 2 días)
        if estado.get("ultima_fecha", "") < dia.isoformat():
            estado["ultima_fecha"] = dia.isoformat()
        dia += timedelta(days=1)


def _precios_mes(inicio: date, fin: date) -> list[dict]:
    params = {
        "start_date": f"{inicio.isoformat()}T00:00",
        "end_date": f"{fin.isoformat()}T23:59",
        "time_trunc": "hour",
    }
    r = _get(REDATA_PRECIOS, params)
    if r.status_code != 200:
        log.warning("ree_precios %s-%s: HTTP %s", inicio, fin, r.status_code)
        return []
    filas = []
    for serie in r.json().get("included", []):
        at = serie.get("attributes", {})
        for p in at.get("values", []):
            dt = datetime.fromisoformat(p["datetime"])
            filas.append(
                {
                    "indicador": serie.get("type") or at.get("title"),
                    "indicador_id": serie.get("id"),
                    "ts_utc": dt.astimezone(timezone.utc),
                    "ts_local": dt.strftime("%Y-%m-%d %H:%M"),
                    "precio_eur_mwh": None if p.get("value") is None else float(p["value"]),
                }
            )
    return filas


@dlt.resource(
    name="ree_precios",
    write_disposition="merge",
    primary_key=("indicador", "ts_utc"),
    columns={
        "indicador": {"data_type": "text", "nullable": False},
        "ts_utc": {"data_type": "timestamp", "timezone": True, "nullable": False},
        "ts_local": {"data_type": "text"},
        "precio_eur_mwh": {"data_type": "double"},
    },
)
def precios(desde: date | None = None, hasta: date | None = None):
    estado = dlt.current.resource_state()
    desde, hasta = _rango(desde, hasta, estado, "ultima_fecha", PRECIOS_INICIO)
    # REData admite ~1 mes por petición con time_trunc=hour
    mes = desde.replace(day=1)
    while mes <= hasta:
        siguiente = (mes + timedelta(days=32)).replace(day=1)
        ini, fin = max(mes, desde), min(siguiente - timedelta(days=1), hasta)
        filas = _precios_mes(ini, fin)
        if filas:
            yield filas
        if estado.get("ultima_fecha", "") < fin.isoformat():
            estado["ultima_fecha"] = fin.isoformat()
        mes = siguiente


@dlt.resource(name="ree_coeficientes_co2", write_disposition="replace")
def coeficientes_co2():
    # Cada sistema tiene sus propios factores (las islas, muy distintos). Sin `curva`
    # y `fecha` el servicio responde 204 (vacío); los factores no cambian con la fecha.
    for sistema, (sufijo, curva, _) in SISTEMAS.items():
        r = _get(VISIONA.format(s=sufijo) + "coeficientesCO2", {"callback": "cb", "curva": curva, "fecha": _hoy().isoformat()})
        r.raise_for_status()
        for clave, valor in _jsonp(r.text).items():
            yield {
                "sistema": sistema,
                "tecnologia": clave.replace("factorEmisionCO2_", ""),
                "t_co2_mwh": float(valor),
            }


@dlt.resource(
    name="esios_intercambios",
    write_disposition="merge",
    primary_key=("frontera", "ts_utc"),
    columns={
        "frontera": {"data_type": "text", "nullable": False},
        "ts_utc": {"data_type": "timestamp", "timezone": True, "nullable": False},
        "ts_local": {"data_type": "text"},
        "saldo_mw": {"data_type": "double"},
        "energia_mwh": {"data_type": "double"},
        "minutos": {"data_type": "bigint"},
        "indicador_id": {"data_type": "bigint"},
    },
)
def esios_intercambios(desde: date | None = None, hasta: date | None = None):
    """Saldo neto telemedido por frontera (ESIOS 10207-10209 y 10047), en MW medios del periodo."""
    token = os.environ.get("ESIOS_TOKEN")
    if not token:
        log.warning("esios_intercambios: falta ESIOS_TOKEN, no se carga")
        return
    # Ojo: el WAF de ESIOS responde 403 si se manda Content-Type en un GET
    cabeceras = {"Accept": "application/json; application/vnd.esios-api-v1+json", "x-api-key": token,
                 "User-Agent": CABECERAS["User-Agent"]}
    estado = dlt.current.resource_state()
    desde, hasta = _rango(desde, hasta, estado, "ultima_fecha", ESIOS_INICIO)
    trozo = desde
    while trozo <= hasta:
        # trimestres: las respuestas anuales cuartohorarias (35k valores) fallan a veces
        fin_trimestre = date(trozo.year + (trozo.month > 9), (((trozo.month - 1) // 3 + 1) * 3) % 12 + 1, 1) - timedelta(days=1)
        fin = min(fin_trimestre, hasta)
        for ind, frontera in ESIOS_FRONTERAS.items():
            r = _get(
                ESIOS.format(id=ind),
                {"start_date": f"{trozo.isoformat()}T00:00", "end_date": f"{fin.isoformat()}T23:59"},
                cabeceras=cabeceras,
            )
            if r.status_code != 200:
                log.warning("esios %s %s-%s: HTTP %s", ind, trozo, fin, r.status_code)
                continue
            valores = sorted(
                # se descartan marcas fuera de la rejilla de 15 min (en 2019 hay valores a las xx:59)
                (v for v in r.json().get("indicator", {}).get("values", [])
                 if v.get("value") is not None and int(v["datetime_utc"][14:16]) % 15 == 0),
                key=lambda v: v["datetime_utc"],
            )
            instantes = [datetime.fromisoformat(v["datetime_utc"].replace("Z", "+00:00")) for v in valores]
            filas = []
            for i, (v, ts) in enumerate(zip(valores, instantes)):
                # Los valores son ENERGÍA (MWh) de cada periodo: horario hasta 2022 y
                # cuartohorario después. MW medios = MWh * 60 / minutos del periodo.
                vecinos = [instantes[i + 1] - ts] if i + 1 < len(instantes) else []
                vecinos += [ts - instantes[i - 1]] if i else []
                minutos = 15 if vecinos and min(vecinos) <= timedelta(minutes=15) else 60
                filas.append({
                    "frontera": frontera,
                    "indicador_id": ind,
                    "ts_utc": ts,
                    "ts_local": datetime.fromisoformat(v["datetime"]).strftime("%Y-%m-%d %H:%M"),
                    "minutos": minutos,
                    "energia_mwh": float(v["value"]),
                    "saldo_mw": float(v["value"]) * 60 / minutos,
                })
            if filas:
                yield filas
        if estado.get("ultima_fecha", "") < fin.isoformat():
            estado["ultima_fecha"] = fin.isoformat()
        trozo = fin + timedelta(days=1)


@dlt.source(name="ree_visiona")
def ree_visiona(
    desde: date | None = None,
    hasta: date | None = None,
    precios_desde: date | None = None,
    esios_desde: date | None = None,
):
    """Curvas de 5 minutos del visor de demanda de REE, precios y factores de CO2.

    Sin argumentos es incremental (última fecha cargada - 2 días -> hoy).
    `desde`/`hasta` fuerzan un rango (backfill) en la curva de 5 minutos;
    `precios_desde` y `esios_desde` hacen lo mismo con los precios y con los
    intercambios por frontera de ESIOS (este último necesita ESIOS_TOKEN).
    """
    return [
        visiona_5min(desde=desde, hasta=hasta),
        precios(desde=precios_desde),
        coeficientes_co2,
        esios_intercambios(desde=esios_desde),
    ]
