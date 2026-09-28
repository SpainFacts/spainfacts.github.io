"""Fuente dlt para los puntos de recarga eléctrica de acceso público.

Fuente: Punto de Acceso Nacional de tráfico y movilidad (NAP, DGT), conjunto
"Puntos de recarga eléctrica para vehículos", publicado por el Ministerio para
la Transición Ecológica (MITECO) a partir de lo que declaran los operadores
(RD 184/2022):
  https://nap.dgt.es/datex2/v3/miterd/EnergyInfrastructureTablePublication/electrolineras.xml
DATEX II v3 (~80 MB), se regenera cada día. Estructura:
  energyInfrastructureSite (emplazamiento: nombre, operador, coordenadas, dirección)
    energyInfrastructureStation (estación)
      refillPoint (punto de recarga = un vehículo cargando a la vez)
        connector (tipo, modo AC/DC, potencia máxima en W)

El código postal pierde el cero inicial (7011 = 07011) y el municipio viene en
texto libre, así que el municipio y la provincia se asignan por coordenadas
con los polígonos de static/geo (punto en polígono).
Los operadores solo están obligados a declarar los puntos de 43 kW o más en
tiempo real; los pequeños (garajes, hoteles...) son voluntarios, así que el
recuento de puntos lentos es un mínimo.

Recursos:
  recarga_puntos           foto actual, un registro por punto (replace)
  recarga_resumen_diario   puntos y potencia por provincia y tramo cada día
                           (merge por fecha: la serie empieza el primer día que se carga)
"""

import json
import logging
import xml.etree.ElementTree as ET
from collections import defaultdict
from datetime import date
from pathlib import Path

import dlt
import requests

REPO_ROOT = Path(__file__).resolve().parent.parent
MUNICIPIOS_GEOJSON = REPO_ROOT / "static" / "geo" / "municipios.geojson"
PROVINCIAS_GEOJSON = REPO_ROOT / "static" / "geo" / "provincias.geojson"
URL = "https://nap.dgt.es/datex2/v3/miterd/EnergyInfrastructureTablePublication/electrolineras.xml"
CABECERAS = {"User-Agent": "spainfacts.org (datos abiertos; contacto en github.com/SpainFacts)"}

log = logging.getLogger(__name__)

NS = {
    "com": "http://datex2.eu/schema/3/common",
    "loc": "http://datex2.eu/schema/3/locationReferencing",
    "locx": "http://datex2.eu/schema/3/locationExtension",
    "fac": "http://datex2.eu/schema/3/facilities",
    "egi": "http://datex2.eu/schema/3/energyInfrastructure",
}
SITE = "{%s}energyInfrastructureSite" % NS["egi"]


def tramo_potencia(kw: float | None) -> str:
    """Tramos habituales: lenta (<22 kW, AC), semirrápida, rápida y ultrarrápida."""
    if kw is None:
        return "desconocida"
    if kw < 22:
        return "lenta (<22 kW)"
    if kw < 50:
        return "semirrápida (22-49 kW)"
    if kw < 150:
        return "rápida (50-149 kW)"
    return "ultrarrápida (≥150 kW)"


# ---------------------------------------------------------------- geometría


def _cargar(ruta: Path, clave: str):
    geo = json.loads(ruta.read_text(encoding="utf-8"))
    zonas = []
    for f in geo["features"]:
        g = f["geometry"]
        poligonos = g["coordinates"] if g["type"] == "MultiPolygon" else [g["coordinates"]]
        anillos = [anillo for pol in poligonos for anillo in pol]
        xs = [p[0] for a in anillos for p in a]
        ys = [p[1] for a in anillos for p in a]
        zonas.append((f["properties"][clave], (min(xs), min(ys), max(xs), max(ys)), anillos))
    return zonas


def _dentro(lon: float, lat: float, anillos: list) -> bool:
    dentro = False
    for anillo in anillos:
        j = len(anillo) - 1
        for i in range(len(anillo)):
            xi, yi = anillo[i][0], anillo[i][1]
            xj, yj = anillo[j][0], anillo[j][1]
            if (yi > lat) != (yj > lat) and lon < (xj - xi) * (lat - yi) / (yj - yi) + xi:
                dentro = not dentro
            j = i
    return dentro


class Localizador:
    """Municipio (y si no cae en ninguno por la simplificación de los bordes, provincia)."""

    def __init__(self):
        self.municipios = _cargar(MUNICIPIOS_GEOJSON, "cod_mun")
        self.provincias = _cargar(PROVINCIAS_GEOJSON, "cod_prov")
        # rejilla de 0,1º para no recorrer los 8.000 municipios en cada punto
        self.rejilla = defaultdict(list)
        for zona in self.municipios:
            x0, y0, x1, y1 = zona[1]
            for gx in range(int(x0 * 10) - 1, int(x1 * 10) + 1):
                for gy in range(int(y0 * 10) - 1, int(y1 * 10) + 1):
                    self.rejilla[(gx, gy)].append(zona)

    def __call__(self, lon: float, lat: float) -> tuple[str | None, str | None]:
        gx, gy = int(lon * 10), int(lat * 10)
        for cod, (x0, y0, x1, y1), anillos in self.rejilla.get((gx, gy), []):
            if x0 <= lon <= x1 and y0 <= lat <= y1 and _dentro(lon, lat, anillos):
                return cod, cod[:2]
        # Puertos y paseos marítimos quedan fuera de la costa simplificada:
        # municipio con el vértice más cercano (a menos de ~3 km).
        mejor, dist = None, 0.03 ** 2
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for cod, _bbox, anillos in self.rejilla.get((gx + dx, gy + dy), []):
                    for anillo in anillos:
                        for x, y in anillo:
                            d = (x - lon) ** 2 + (y - lat) ** 2
                            if d < dist:
                                mejor, dist = cod, d
        if mejor:
            return mejor, mejor[:2]
        return None, None


# ---------------------------------------------------------------- lectura


def _texto(elem, ruta: str) -> str | None:
    e = elem.find(ruta, NS)
    return e.text.strip() if e is not None and e.text else None


def leer_puntos(fichero) -> list[dict]:
    """Recorre el XML en streaming y devuelve un dict por punto de recarga."""
    puntos = []
    for _evento, site in ET.iterparse(fichero, events=("end",)):
        if site.tag != SITE:
            continue
        site_id = site.get("id")
        nombre = _texto(site, "fac:name/com:values/com:value")
        operador = _texto(site, "fac:operator/fac:name/com:values/com:value")
        operador_id = site.find("fac:operator", NS).get("id") if site.find("fac:operator", NS) is not None else None
        lat = _texto(site, "fac:locationReference/loc:coordinatesForDisplay/loc:latitude")
        lon = _texto(site, "fac:locationReference/loc:coordinatesForDisplay/loc:longitude")
        tipo_sitio = _texto(site, "egi:typeOfSite")
        for punto in site.iterfind("egi:energyInfrastructureStation/egi:refillPoint", NS):
            potencias, tipos, modos = [], set(), set()
            for c in punto.iterfind("egi:connector", NS):
                p = _texto(c, "egi:maxPowerAtSocket")
                if p:
                    try:
                        potencias.append(float(p) / 1000)
                    except ValueError:
                        pass
                if t := _texto(c, "egi:connectorType"):
                    tipos.add(t)
                if m := _texto(c, "egi:chargingMode"):
                    modos.add(m)
            kw = max(potencias) if potencias else None
            puntos.append({
                "punto_id": punto.get("id"),
                "sitio_id": site_id,
                "sitio": nombre,
                "operador": operador,
                "operador_id": operador_id,
                "tipo_sitio": tipo_sitio,
                "latitud": float(lat) if lat else None,
                "longitud": float(lon) if lon else None,
                "potencia_kw": kw,
                "tramo_potencia": tramo_potencia(kw),
                "corriente_continua": any("DC" in m.upper() for m in modos),
                "conectores": ",".join(sorted(tipos)) or None,
            })
        site.clear()
    return puntos


@dlt.source(name="recarga")
def recarga():
    datos = None

    def _datos():
        nonlocal datos
        if datos is None:
            with requests.get(URL, headers=CABECERAS, stream=True, timeout=300) as r:
                r.raise_for_status()
                r.raw.decode_content = True
                puntos = leer_puntos(r.raw)
            localizar = Localizador()
            for p in puntos:
                if p["latitud"] is not None and p["longitud"] is not None:
                    p["cod_mun"], p["cod_prov"] = localizar(p["longitud"], p["latitud"])
                else:
                    p["cod_mun"] = p["cod_prov"] = None
            sin = sum(1 for p in puntos if p["cod_prov"] is None)
            log.info("Puntos de recarga: %d (%d sin provincia)", len(puntos), sin)
            datos = puntos
        return datos

    @dlt.resource(name="recarga_puntos", write_disposition="replace")
    def puntos():
        yield from _datos()

    @dlt.resource(
        name="recarga_resumen_diario",
        write_disposition={"disposition": "merge", "strategy": "delete-insert"},
        merge_key="fecha",
    )
    def resumen_diario():
        hoy = date.today()
        grupos = defaultdict(lambda: {"puntos": 0, "potencia_kw": 0.0, "sitios": set()})
        for p in _datos():
            g = grupos[(p["cod_prov"], p["tramo_potencia"])]
            g["puntos"] += 1
            g["potencia_kw"] += p["potencia_kw"] or 0
            g["sitios"].add(p["sitio_id"])
        for (cod_prov, tramo), g in grupos.items():
            yield {
                "fecha": hoy, "cod_prov": cod_prov, "tramo_potencia": tramo,
                "puntos": g["puntos"], "sitios": len(g["sitios"]), "potencia_kw": round(g["potencia_kw"], 1),
            }

    return puntos, resumen_diario


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("recarga").run(recarga()))
