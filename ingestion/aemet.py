"""Fuente dlt para las temperaturas diarias de AEMET OpenData.

Se usa el endpoint de climatología diaria de TODAS las estaciones
(/valores/climatologicos/diarios/datos/.../todasestaciones), que admite como
máximo 15 días por petición. Con una sola petición se obtienen todas las
estaciones a la vez, así que es mucho más barato que ir estación a estación
(ese endpoint solo admite 6 meses por llamada).

Tablas que se cargan en `raw`:

- ``aemet_diario``: serie diaria completa (por defecto desde 1991) de las
  estaciones de referencia de cada provincia, definidas en la semilla de dbt
  ``transform/seeds/aemet_estaciones_referencia.csv``. Con ella se calcula la
  media histórica 1991-2020 de cada día del año.
- ``aemet_diario_todas``: todas las estaciones, pero solo desde
  ``AEMET_FECHA_INICIO_TODAS`` (por defecto 2025-01-01), para saber cuál fue
  el lugar más caluroso de España cada día.
- ``aemet_estaciones``: inventario de estaciones (nombre, provincia, coordenadas).

Carga incremental: las dos tablas diarias son "merge" con clave
(indicativo, fecha). El estado del recurso guarda la última fecha cargada; en
cada ejecución se vuelve a pedir desde 20 días antes de esa fecha, porque AEMET
publica con unos días de retraso y revisa los últimos datos. La primera
ejecución (sin estado) hace el histórico completo desde ``AEMET_FECHA_INICIO``
(por defecto 1991-01-01): ~850 peticiones, alrededor de una hora. También se
puede forzar una ventana concreta con los parámetros ``desde``/``hasta``
(útil para rellenar el histórico por tramos).

Requiere la variable de entorno AEMET_API_KEY. Los ficheros de datos de AEMET
vienen en ISO-8859-15 y con decimales con coma.
Documentación: https://opendata.aemet.es/dist/index.html
"""

import csv
import json
import os
import time
from datetime import date, timedelta
from pathlib import Path

import dlt
import requests

AEMET_BASE = "https://opendata.aemet.es/opendata/api"
SEMILLA_ESTACIONES = (
    Path(__file__).resolve().parent.parent / "transform" / "seeds" / "aemet_estaciones_referencia.csv"
)
DIAS_POR_PETICION = 15  # límite de AEMET para /todasestaciones
DIAS_RELECTURA = 20  # se vuelven a pedir los últimos días por si AEMET los revisa
FECHA_INICIO_POR_DEFECTO = "1991-01-01"
FECHA_INICIO_TODAS_POR_DEFECTO = "2025-01-01"


def _estaciones_referencia() -> set[str]:
    with open(SEMILLA_ESTACIONES, encoding="utf-8", newline="") as f:
        return {fila["indicativo"].strip() for fila in csv.DictReader(f)}


def _get(url: str, **kwargs) -> requests.Response:
    """GET con reintentos: AEMET devuelve 429 al superar ~40 peticiones/minuto."""
    espera = 5
    for intento in range(8):
        try:
            r = requests.get(url, timeout=120, **kwargs)
            if r.status_code not in (429, 500, 502, 503, 504):
                return r
        except requests.RequestException:
            if intento == 7:
                raise
        time.sleep(espera)
        espera = min(espera * 2, 90)
    r.raise_for_status()
    return r


def _consultar(endpoint: str) -> list[dict]:
    """Llama a un endpoint de AEMET y descarga el fichero `datos` que devuelve."""
    clave = os.environ["AEMET_API_KEY"]
    for intento in range(6):
        meta = _get(f"{AEMET_BASE}{endpoint}", headers={"api_key": clave, "cache-control": "no-cache"}).json()
        estado = meta.get("estado")
        if estado == 200 and meta.get("datos"):
            datos = _get(meta["datos"])
            if datos.status_code == 200:
                # ISO-8859-15 (latin-1 cubre todas las tildes y la ñ que aparecen)
                return json.loads(datos.content.decode("latin-1"))
        elif estado == 404:  # "No hay datos que satisfagan esos criterios de búsqueda"
            return []
        elif estado != 429:
            raise RuntimeError(f"AEMET {endpoint}: {estado} {meta.get('descripcion')}")
        time.sleep(10 * (intento + 1))
    raise RuntimeError(f"AEMET {endpoint}: demasiados reintentos")


def _numero(texto: str | None) -> float | None:
    # "12,3" -> 12.3; "Ip" (precipitación inapreciable) -> 0.0; "Acum"/"Varias" -> None
    if texto in (None, ""):
        return None
    if texto == "Ip":
        return 0.0
    try:
        return float(texto.replace(",", "."))
    except ValueError:
        return None


def _grados(texto: str | None) -> float | None:
    # Coordenadas en grados-minutos-segundos: "402456N" -> 40.4156; "034041W" -> -3.678
    if not texto:
        return None
    hemisferio, cifras = texto[-1], texto[:-1]
    valor = int(cifras[:-4]) + int(cifras[-4:-2]) / 60 + int(cifras[-2:]) / 3600
    return round(-valor if hemisferio in "SW" else valor, 5)


def _fila(r: dict) -> dict:
    return {
        "fecha": date.fromisoformat(r["fecha"]),
        "indicativo": r["indicativo"],
        "nombre": r.get("nombre"),
        "provincia": r.get("provincia"),
        "altitud": _numero(r.get("altitud")),
        "tmed": _numero(r.get("tmed")),
        "tmax": _numero(r.get("tmax")),
        "tmin": _numero(r.get("tmin")),
        "hora_tmax": r.get("horatmax"),
        "hora_tmin": r.get("horatmin"),
        "prec": _numero(r.get("prec")),
        "hr_media": _numero(r.get("hrMedia")),
    }


@dlt.resource(name="aemet_estaciones", write_disposition="replace")
def estaciones():
    for r in _consultar("/valores/climatologicos/inventarioestaciones/todasestaciones"):
        yield {
            "indicativo": r["indicativo"],
            "nombre": r.get("nombre"),
            "provincia": r.get("provincia"),
            "altitud": _numero(r.get("altitud")),
            "latitud": _grados(r.get("latitud")),
            "longitud": _grados(r.get("longitud")),
            "indsinop": r.get("indsinop") or None,
        }


@dlt.resource(name="aemet_diario", write_disposition="merge", primary_key=("indicativo", "fecha"))
def diario(desde: str | None = None, hasta: str | None = None):
    """Temperaturas diarias. Filas de estaciones de referencia -> aemet_diario;
    todas las estaciones desde AEMET_FECHA_INICIO_TODAS -> aemet_diario_todas."""
    estado = dlt.current.resource_state()
    if desde:
        inicio = date.fromisoformat(desde)
    elif estado.get("ultima_fecha"):
        inicio = date.fromisoformat(estado["ultima_fecha"]) - timedelta(days=DIAS_RELECTURA)
    else:
        inicio = date.fromisoformat(os.environ.get("AEMET_FECHA_INICIO") or FECHA_INICIO_POR_DEFECTO)
    fin = date.fromisoformat(hasta) if hasta else date.today()
    inicio_todas = date.fromisoformat(os.environ.get("AEMET_FECHA_INICIO_TODAS") or FECHA_INICIO_TODAS_POR_DEFECTO)
    referencia = _estaciones_referencia()

    tramo = inicio
    while tramo <= fin:
        fin_tramo = min(tramo + timedelta(days=DIAS_POR_PETICION - 1), fin)
        registros = _consultar(
            f"/valores/climatologicos/diarios/datos/fechaini/{tramo}T00:00:00UTC"
            f"/fechafin/{fin_tramo}T23:59:59UTC/todasestaciones"
        )
        filas = [_fila(r) for r in registros if r.get("fecha") and r.get("indicativo")]
        ref = [f for f in filas if f["indicativo"] in referencia]
        if ref:
            yield ref
        if fin_tramo >= inicio_todas:
            todas = [f for f in filas if f["fecha"] >= inicio_todas]
            if todas:
                yield dlt.mark.with_table_name(todas, "aemet_diario_todas")
        if filas:
            maxima = max(f["fecha"] for f in filas).isoformat()
            estado["ultima_fecha"] = max(estado.get("ultima_fecha") or "", maxima)
        tramo = fin_tramo + timedelta(days=1)


@dlt.source(name="aemet")
def aemet(desde: str | None = None, hasta: str | None = None):
    return [estaciones, diario(desde=desde, hasta=hasta)]
