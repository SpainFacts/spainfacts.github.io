"""Fuente dlt de la red ferroviaria de España y los trenes que pasan por cada tramo (tema `ferrocarril`).

Nadie publica en abierto cuántos trenes circulan por cada tramo (Adif solo da el total anual y
su servidor de mapas IDEAdif no responde). Aquí se calcula con los horarios:

1) Red: OpenStreetMap vía Overpass (© OpenStreetMap contributors, ODbL). Vías railway=rail y
   narrow_gauge sin `service` (sin apartaderos, playas de vías ni ramales particulares) y sin
   usos industrial/militar/turístico. Trae ancho (gauge), electrificación, velocidad máxima,
   alta velocidad, operador y el número de línea de Adif (ref).
   OSM dibuja cada vía por separado: una línea de vía doble son dos trazos paralelos a ~4 m.
   Para no contar dos veces ni repartir los trenes entre las dos vías, los trazados se
   densifican cada ~40 m y se encajan en una rejilla de 0,001º (~110 x 85 m): las dos vías caen
   en las mismas celdas y el grafo resultante es el del corredor. Los km de red salen de ese
   grafo (aproximados: ±5 %).

2) Trenes: horarios GTFS de un día laborable (el próximo miércoles con servicio):
   - Renfe Viajeros, alta velocidad, larga y media distancia (incluye los regionales de ancho
     métrico de la antigua FEVE) y Cercanías/Rodalies (CC BY 4.0, data.renfe.com).
   - FGC (Ferrocarrils de la Generalitat de Catalunya), Euskotren y FGV (Metrovalencia y TRAM
     d'Alacant) a través del espejo de Mobility Database.
   Faltan Iryo y Ouigo (sin GTFS oficial) y todos los trenes de mercancías: los corredores de
   alta velocidad y las líneas de mercancías salen por debajo de lo real.
   Cada par de paradas consecutivas de cada tren se traza por el camino más corto en el grafo
   (A*), con preferencia por el ancho del servicio (AVE, Avlo, Avant y Euromed por ancho
   estándar; Cercanías, Media Distancia y Regionales por ibérico o métrico). Un tren directo
   Madrid-Sevilla suma así en todos los tramos que recorre, aunque no pare en ellos.
   Los pares que no se pueden trazar (metro en túnel que OSM no marca como tren, paradas a más
   de 1,5 km de una vía) se descartan y se cuentan en el registro.

3) Eurostat: km de líneas (total, alta velocidad, electrificadas), viajeros-km y toneladas-km
   por país, para comparar con Europa.

Recursos (todos replace):
  ferrocarril_red          tramos de red con el mismo tipo, línea y operador, trazado simplificado
  ferrocarril_red_provincia  km de red por provincia y tipo
  ferrocarril_trafico      tramos con el mismo número de trenes al día (por tipo de servicio)
  ferrocarril_estaciones   trenes que paran en cada estación ese día
  ferrocarril_pares        trenes entre cada par de paradas consecutivas
  ferrocarril_eurostat     indicadores por país y año
"""

import csv
import heapq
import io
import logging
import math
import re
import time
import zipfile
from collections import Counter, defaultdict
from datetime import date, timedelta

import dlt
import requests

from ingestion.eurostat import parse_json_stat_series
from ingestion.oleoductos import simplificar, texto_trazado

log = logging.getLogger(__name__)

CABECERAS = {"User-Agent": "spainfacts.org (datos abiertos; contacto en github.com/SpainFacts)"}
OVERPASS = "https://overpass-api.de/api/interpreter"
CONSULTA = """[out:json][timeout:600];
area["ISO3166-1"="ES"][admin_level=2]->.es;
way["railway"~"^(rail|narrow_gauge)$"][!"service"](area.es);
out tags geom;"""
USOS_FUERA = {"industrial", "military", "tourism", "test", "freight_yard"}

GTFS = {
    # clave: (url, operador, clase por defecto)
    "renfe_ld": ("https://ssl.renfe.com/gtransit/Fichero_AV_LD/google_transit.zip", "Renfe", None),
    "renfe_cercanias": ("https://ssl.renfe.com/ftransit/Fichero_CER_FOMENTO/fomento_transit.zip", "Renfe", "cercanias"),
    "fgc": ("https://www.fgc.cat/google/google_transit.zip", "FGC", "autonomico"),
    "euskotren": ("https://files.mobilitydatabase.org/mdb-2715/latest.zip", "Euskotren", "autonomico"),
    "fgv_valencia": ("https://files.mobilitydatabase.org/mdb-2830/latest.zip", "FGV", "autonomico"),
    "fgv_alicante": ("https://files.mobilitydatabase.org/mdb-2829/latest.zip", "FGV", "autonomico"),
}
# Productos de Renfe larga y media distancia -> clase
LARGA = {"AVE", "AVLO", "ALVIA", "INTERCITY", "AVE INT", "EUROMED", "TRENCELTA"}
MEDIA = {"MD", "REGIONAL", "REG.EXP.", "PROXIMDAD", "AVANT", "AVANT EXP"}
ESTANDAR = {"AVE", "AVLO", "AVE INT", "AVANT", "AVANT EXP", "EUROMED"}
NEUTRO = {"ALVIA", "INTERCITY", "TRENCELTA"}  # trenes de ancho variable
OPERADOR_OSM = {
    "FGC": r"\bfgc\b|generalitat de catalunya",
    "Euskotren": r"euskotren|\bets\b|eusko trenbide|euskal trenbide",
    "FGV": r"\bfgv\b|generalitat valenciana|metrovalencia",
}

CELDA = 1000  # 1/0,001º
PASO_KM = 0.04
RADIO_PARADA = 15  # celdas (~1,5 km)

EUROSTAT = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
EUROSTAT_CONSULTAS = {
    "km_lineas": ("rail_if_line_sp", "unit=KM&tra_infr=TOTAL"),
    "km_alta_velocidad_dedicada": ("rail_if_line_sp", "unit=KM&tra_infr=RL_DHSPD"),
    "km_alta_velocidad_adaptada": ("rail_if_line_sp", "unit=KM&tra_infr=RL_UHSPD"),
    "km_electrificadas": ("rail_if_line_ga", "unit=KM&tra_infr=RL_ELC&gaugert=TOTAL"),
    "km_lineas_ga": ("rail_if_line_ga", "unit=KM&tra_infr=TOTAL&gaugert=TOTAL"),
    "millones_viajeros_km": ("rail_pa_total", "unit=MIO_PKM"),
    "millones_toneladas_km": ("rail_go_total", "unit=MIO_TKM"),
}


def _get(url: str, intentos: int = 4, **kw) -> requests.Response:
    for i in range(intentos):
        try:
            r = requests.get(url, headers=CABECERAS, timeout=900, **kw)
            if r.status_code < 500 and r.status_code != 429:
                r.raise_for_status()
                return r
            log.warning("%s: HTTP %s; reintento", url, r.status_code)
        except requests.RequestException as e:
            if i == intentos - 1:
                raise
            log.warning("%s: %s; reintento", url, e)
        time.sleep(60 * (i + 1))
    r.raise_for_status()
    return r


# ---------------------------------------------------------------- 1) red


def tipo_via(tags: dict) -> str:
    gauge = tags.get("gauge", "")
    if "1435" in gauge and (tags.get("highspeed") == "yes" or _vmax(tags) >= 200):
        return "alta_velocidad"
    if "1435" in gauge:
        return "estandar"
    if gauge.startswith("1000") or gauge.startswith("914") or tags.get("railway") == "narrow_gauge":
        return "metrica"
    return "iberica_electrificada" if tags.get("electrified", "no") not in ("no", "") else "iberica_sin_electrificar"


def _vmax(tags: dict) -> int:
    m = re.match(r"\d+", tags.get("maxspeed", "") or "")
    return int(m.group()) if m else 0


def _densificar(coords: list) -> list:
    """Puntos cada ~40 m para que las vías paralelas pasen por las mismas celdas."""
    salida = [coords[0]]
    for (lo1, la1), (lo2, la2) in zip(coords, coords[1:]):
        d = _km(lo1, la1, lo2, la2)
        n = max(1, int(d / PASO_KM))
        for k in range(1, n + 1):
            salida.append((lo1 + (lo2 - lo1) * k / n, la1 + (la2 - la1) * k / n))
    return salida


def _km(lo1, la1, lo2, la2) -> float:
    dx = (lo2 - lo1) * 111.32 * math.cos(math.radians((la1 + la2) / 2))
    dy = (la2 - la1) * 110.57
    return math.hypot(dx, dy)


def _celda(lo, la):
    return (round(lo * CELDA), round(la * CELDA))


def _coord(c):
    return (c[0] / CELDA, c[1] / CELDA)


class Red:
    """Grafo del corredor: nodos = celdas, aristas = pares de celdas consecutivas."""

    def __init__(self, vias: list[dict]):
        self.adj = defaultdict(set)
        self.attr = {}  # arista (a, b) ordenada -> dict de atributos
        for v in vias:
            celdas = []
            for lo, la in _densificar(v["coords"]):
                c = _celda(lo, la)
                if not celdas or celdas[-1] != c:
                    celdas.append(c)
            for a, b in zip(celdas, celdas[1:]):
                e = (a, b) if a < b else (b, a)
                self.adj[a].add(b)
                self.adj[b].add(a)
                at = self.attr.get(e)
                if at is None:
                    self.attr[e] = {"tipos": Counter(), "ref": v["ref"], "nombre": v["nombre"], "operador": v["operador"],
                                    "vmax": v["vmax"]}
                    at = self.attr[e]
                at["tipos"][v["tipo"]] += 1
                at["vmax"] = max(at["vmax"], v["vmax"])
                if not at["ref"] and v["ref"]:
                    at["ref"] = v["ref"]
                if not at["nombre"] and v["nombre"]:
                    at["nombre"] = v["nombre"]
                if not at["operador"] and v["operador"]:
                    at["operador"] = v["operador"]
        for e, at in self.attr.items():
            # el tipo «más especial» manda: alta velocidad > estándar > métrica > ibérica
            orden = ["alta_velocidad", "estandar", "metrica", "iberica_electrificada", "iberica_sin_electrificar"]
            at["tipo"] = next(t for t in orden if t in at["tipos"])
            at["anchos"] = set(at["tipos"])
            at["km"] = _km(*_coord(e[0]), *_coord(e[1]))
        # índice para encontrar la celda de red más cercana a una parada
        self.nodos = set(self.adj)
        log.info("Grafo ferroviario: %s nodos, %s aristas, %.0f km", len(self.nodos), len(self.attr), sum(a["km"] for a in self.attr.values()))

    def cercano(self, lo, la, admite=None):
        c0 = _celda(lo, la)
        mejor, dmin = None, float("inf")
        for r in range(RADIO_PARADA + 1):
            for dx in range(-r, r + 1):
                for dy in ((-r, r) if abs(dx) != r else range(-r, r + 1)):
                    c = (c0[0] + dx, c0[1] + dy)
                    if c in self.nodos and (admite is None or any(admite(self.attr[(c, n) if c < n else (n, c)]) for n in self.adj[c])):
                        d = _km(lo, la, *_coord(c))
                        if d < dmin:
                            mejor, dmin = c, d
            if mejor is not None and r * 0.08 > dmin:
                break
        return mejor

    def ruta(self, a, b, coste_arista, limite_km: float):
        """A* entre dos celdas; devuelve la lista de aristas o None."""
        if a == b:
            return []
        objetivo = _coord(b)
        h = lambda c: _km(*_coord(c), *objetivo)
        abiertos = [(h(a), 0.0, a)]
        g = {a: 0.0}
        previo = {}
        while abiertos:
            _f, gc, c = heapq.heappop(abiertos)
            if c == b:
                break
            if gc > g.get(c, float("inf")) or gc > limite_km:
                continue
            for n in self.adj[c]:
                e = (c, n) if c < n else (n, c)
                factor = coste_arista(self.attr[e])
                if factor is None:
                    continue
                coste = gc + self.attr[e]["km"] * factor
                if coste < g.get(n, float("inf")):
                    g[n] = coste
                    previo[n] = c
                    heapq.heappush(abiertos, (coste + h(n), coste, n))
        if b not in previo:
            return None
        aristas, c = [], b
        while c != a:
            p = previo[c]
            aristas.append((p, c) if p < c else (c, p))
            c = p
        return aristas


def vias_osm(datos: dict | None = None) -> list[dict]:
    datos = datos or _get(OVERPASS, params={"data": CONSULTA}).json()
    vias = []
    for el in datos.get("elements", []):
        if el.get("type") != "way" or not el.get("geometry"):
            continue
        t = el.get("tags", {})
        if t.get("railway") not in ("rail", "narrow_gauge") or t.get("service") or t.get("usage") in USOS_FUERA:
            continue
        vias.append({
            "osm_id": el["id"],
            "coords": [(g["lon"], g["lat"]) for g in el["geometry"]],
            "tipo": tipo_via(t),
            "ref": t.get("ref"),
            "nombre": t.get("name"),
            "operador": t.get("operator"),
            "vmax": _vmax(t),
        })
    return vias


def cadenas(red: Red, aristas: dict) -> list[list]:
    """Encadena aristas (dict arista -> clave) en polilíneas de la misma clave."""
    por_nodo = defaultdict(list)
    for e in aristas:
        por_nodo[e[0]].append(e)
        por_nodo[e[1]].append(e)
    hechas = set()
    salida = []
    for e0, clave in aristas.items():
        if e0 in hechas:
            continue
        hechas.add(e0)
        linea = [e0[0], e0[1]]
        for extremo in (1, 0):
            while True:
                c = linea[-1] if extremo else linea[0]
                sig = [e for e in por_nodo[c] if e not in hechas and aristas[e] == clave]
                if len(sig) != 1:
                    break
                e = sig[0]
                hechas.add(e)
                otro = e[1] if e[0] == c else e[0]
                if extremo:
                    linea.append(otro)
                else:
                    linea.insert(0, otro)
        salida.append((clave, linea))
    return salida


# ---------------------------------------------------------------- 2) horarios


def _leer(z: zipfile.ZipFile, nombre: str):
    try:
        with z.open(nombre) as f:
            for r in csv.DictReader(io.TextIOWrapper(f, encoding="utf-8-sig")):
                yield {(k or "").strip(): (v or "").strip() for k, v in r.items()}
    except KeyError:
        return


def _servicios(z: zipfile.ZipFile, dia: date) -> set:
    d = dia.strftime("%Y%m%d")
    semana = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"][dia.weekday()]
    activos = {r["service_id"] for r in _leer(z, "calendar.txt") if r["start_date"] <= d <= r["end_date"] and r.get(semana) == "1"}
    for r in _leer(z, "calendar_dates.txt"):
        if r["date"] == d:
            (activos.add if r["exception_type"] == "1" else activos.discard)(r["service_id"])
    return activos


def dia_tipo(z: zipfile.ZipFile) -> date:
    """Próximo miércoles (a partir de dentro de 3 días) con servicios en el horario."""
    dia = date.today() + timedelta(days=3)
    dia += timedelta(days=(2 - dia.weekday()) % 7)
    for _ in range(8):
        if _servicios(z, dia):
            return dia
        dia += timedelta(days=7)
    return dia


def clase_renfe(producto: str) -> str:
    p = producto.upper().strip()
    if p in LARGA:
        return "larga_distancia"
    if p in MEDIA:
        return "media_distancia"
    return "media_distancia"


def viajes(clave: str, contenido: bytes, dia: date | None = None):
    """Viajes del día: (producto, clase, operador, [(stop_id, nombre, lon, lat), ...])."""
    _url, operador, clase_fija = GTFS[clave]
    z = zipfile.ZipFile(io.BytesIO(contenido))
    dia = dia or dia_tipo(z)
    activos = _servicios(z, dia)
    rutas = {r["route_id"]: r for r in _leer(z, "routes.txt")}
    paradas = {}
    for r in _leer(z, "stops.txt"):
        try:
            paradas[r["stop_id"]] = (r["stop_name"], float(r["stop_lon"]), float(r["stop_lat"]))
        except (KeyError, ValueError):
            pass
    viajes_dia = {}
    for r in _leer(z, "trips.txt"):
        if r["service_id"] in activos:
            ruta = rutas.get(r["route_id"], {})
            if ruta.get("route_type") not in ("2", "100", "101", "102", "103", "106", "109", "0", "1", "900"):
                continue  # autobuses de sustitución y otros modos
            producto = ruta.get("route_short_name") or ruta.get("route_long_name") or ""
            viajes_dia[r["trip_id"]] = producto
    secuencias = defaultdict(list)
    for r in _leer(z, "stop_times.txt"):
        if r["trip_id"] in viajes_dia and r["stop_id"] in paradas:
            secuencias[r["trip_id"]].append((int(r["stop_sequence"]), r["stop_id"]))
    for trip, seq in secuencias.items():
        seq.sort()
        producto = viajes_dia[trip]
        clase = clase_fija or clase_renfe(producto)
        yield dia, producto, clase, operador, [(f"{clave}:{s}", *paradas[s]) for _n, s in seq]


def coste_para(producto: str, clase: str, operador: str):
    """Multiplicador del coste de cada arista según el servicio; None = no puede pasar por ella.

    Los operadores autonómicos solo circulan por vías suyas (o sin operador en OSM); Renfe, por
    las de Adif y nunca por las autonómicas. Así una parada de metro en túnel (que OSM no marca
    como tren) no se pega a la vía de Adif más cercana."""
    p = producto.upper().strip()
    if clase == "autonomico":
        patron = OPERADOR_OSM.get(operador)

        def coste(at):
            op = at["operador"] or ""
            if not op:
                return 2.0
            return 1.0 if patron and re.search(patron, op, re.I) else None
        return coste

    def ajeno(at):
        op = at["operador"] or ""
        return op and any(re.search(pt, op, re.I) for pt in OPERADOR_OSM.values())

    if p in ESTANDAR:
        return lambda at: None if ajeno(at) else 1.0 if at["anchos"] & {"alta_velocidad", "estandar"} else 4.0
    if p in NEUTRO:
        return lambda at: None if ajeno(at) else 1.0
    return lambda at: None if ajeno(at) else 4.0 if at["anchos"] <= {"alta_velocidad", "estandar"} else 1.0


# ---------------------------------------------------------------- cálculo completo


def calcular(vias: list[dict], feeds: dict[str, bytes]):
    red = Red(vias)
    from ingestion.recarga import Localizador

    localizar = Localizador()

    # Red por tipo, línea y operador, y km por provincia
    red_filas, km_prov = [], Counter()
    clave_red = {e: (at["tipo"], at["ref"] or "", at["nombre"] or "", at["operador"] or "") for e, at in red.attr.items()}
    for e, at in red.attr.items():
        lo, la = _coord(e[0])
        _mun, prov = localizar(lo, la)
        if prov:
            km_prov[(prov, at["tipo"])] += at["km"]
    for (tipo, ref, nombre, operador), linea in cadenas(red, clave_red):
        coords = [_coord(c) for c in linea]
        aristas = [(a, b) if a < b else (b, a) for a, b in zip(linea, linea[1:])]
        km = sum(red.attr[e]["km"] for e in aristas if e in red.attr)
        if km < 0.3:
            continue
        red_filas.append({
            "tipo": tipo, "ref": ref or None, "nombre": nombre or None, "operador": operador or None,
            "vmax": max((red.attr[e]["vmax"] for e in aristas if e in red.attr), default=0) or None,
            "longitud_km": km, "trazado": texto_trazado([simplificar(coords, 0.0015)]),
        })

    # Trenes por arista, estación y par de paradas
    trenes = defaultdict(Counter)  # arista -> clase -> trenes
    estaciones = {}
    pares = Counter()
    rutas_cache = {}
    descartados = Counter()
    fecha = None
    for clave, contenido in feeds.items():
        for dia, producto, clase, operador, seq in viajes(clave, contenido):
            fecha = fecha or dia
            for sid, nombre, lo, la in seq:
                est = estaciones.setdefault(sid, {"estacion_id": sid, "nombre": nombre, "longitud": lo, "latitud": la,
                                                  "operador": operador, "trenes": Counter()})
                est["trenes"][clase] += 1
            for (s1, n1, lo1, la1), (s2, n2, lo2, la2) in zip(seq, seq[1:]):
                par = tuple(sorted(((s1, n1), (s2, n2))))
                pares[(par, clase, operador)] += 1
                cache = (s1, s2, producto.upper().strip() if clase != "autonomico" else operador, clase)
                if cache not in rutas_cache:
                    coste = coste_para(producto, clase, operador)
                    admite = lambda at, coste=coste: coste(at) is not None
                    a = red.cercano(lo1, la1, admite)
                    b = red.cercano(lo2, la2, admite)
                    recta = _km(lo1, la1, lo2, la2)
                    ruta = None
                    if a and b:
                        ruta = red.ruta(a, b, coste, limite_km=4 * (3 * recta + 10))
                        if ruta is not None and sum(red.attr[e]["km"] for e in ruta) > 3 * recta + 10:
                            ruta = None
                    rutas_cache[cache] = ruta
                    if ruta is None:
                        descartados[clave] += 1
                for e in rutas_cache[cache] or ():
                    trenes[e][clase] += 1
    log.info("Pares sin trazar por fuente: %s", dict(descartados))

    # Tramos de tráfico: aristas encadenadas con el mismo número de trenes de cada clase
    CLASES = ("cercanias", "media_distancia", "larga_distancia", "autonomico")
    clave_tr = {e: tuple(c.get(k, 0) for k in CLASES) for e, c in trenes.items()}
    trafico = []
    for cuenta, linea in cadenas(red, clave_tr):
        coords = [_coord(c) for c in linea]
        aristas = [(a, b) if a < b else (b, a) for a, b in zip(linea, linea[1:])]
        at = red.attr.get(aristas[0], {})
        trafico.append({
            "trenes_dia": sum(cuenta), **dict(zip((f"trenes_{k}" for k in CLASES), cuenta)),
            "tipo": at.get("tipo"), "ref": at.get("ref"), "nombre": at.get("nombre"),
            "longitud_km": sum(red.attr[e]["km"] for e in aristas if e in red.attr),
            "trazado": texto_trazado([simplificar(coords, 0.0015)]),
            "fecha_horarios": fecha,
        })

    estaciones_filas = []
    for est in estaciones.values():
        c = est.pop("trenes")
        est.update({"trenes_dia": sum(c.values()), **{f"trenes_{k}": c.get(k, 0) for k in CLASES}, "fecha_horarios": fecha})
        estaciones_filas.append(est)

    pares_filas = [
        {"estacion_a": a[1], "estacion_b": b[1], "estacion_a_id": a[0], "estacion_b_id": b[0], "clase": clase,
         "operador": op, "trenes_dia": n, "fecha_horarios": fecha}
        for ((a, b), clase, op), n in pares.items()
    ]
    provincia_filas = [{"cod_prov": p, "tipo": t, "km": km} for (p, t), km in km_prov.items()]
    return red_filas, provincia_filas, trafico, estaciones_filas, pares_filas


# ---------------------------------------------------------------- 3) Eurostat


def eurostat():
    for indicador, (dataset, filtro) in EUROSTAT_CONSULTAS.items():
        datos = _get(f"{EUROSTAT}{dataset}?format=JSON&lang=EN&{filtro}").json()
        for coords, valor in parse_json_stat_series(datos):
            if valor is None:
                continue
            yield {"indicador": indicador, "dataset": dataset, "cod_fuente": coords["geo"], "anio": int(coords["time"]), "valor": float(valor)}


# ---------------------------------------------------------------- fuente


@dlt.source(name="ferrocarril", max_table_nesting=0)
def ferrocarril():
    resultado = {}

    def calculado():
        if not resultado:
            vias = vias_osm()
            feeds = {}
            for clave, (url, *_r) in GTFS.items():
                try:
                    feeds[clave] = _get(url).content
                except requests.RequestException as e:
                    log.warning("Sin horarios de %s: %s", clave, e)
            red, prov, trafico, est, pares = calcular(vias, feeds)
            resultado.update(red=red, prov=prov, trafico=trafico, est=est, pares=pares)
        return resultado

    @dlt.resource(name="ferrocarril_red", write_disposition="replace")
    def r_red():
        yield calculado()["red"]

    @dlt.resource(name="ferrocarril_red_provincia", write_disposition="replace")
    def r_prov():
        yield calculado()["prov"]

    @dlt.resource(name="ferrocarril_trafico", write_disposition="replace")
    def r_trafico():
        yield calculado()["trafico"]

    @dlt.resource(name="ferrocarril_estaciones", write_disposition="replace")
    def r_est():
        yield calculado()["est"]

    @dlt.resource(name="ferrocarril_pares", write_disposition="replace")
    def r_pares():
        yield calculado()["pares"]

    @dlt.resource(name="ferrocarril_eurostat", write_disposition="replace")
    def r_eurostat():
        yield from eurostat()

    return r_red, r_prov, r_trafico, r_est, r_pares, r_eurostat
