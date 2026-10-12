"""Elecciones al Parlamento de Andalucía: 2026 por sección censal y 1986-2022 por municipio.

Fuente: Sistema de Información Electoral de Andalucía (SIEL), de la Consejería
competente en procesos electorales de la Junta de Andalucía, enlazado desde
https://eleccionesparlamentoandalucia2026.es/resultados-electorales/resultados-electorales-parlamento/
como visor en https://resultadoseleccionesandalucia.es. El visor no ofrece un
fichero descargable por mesa: lee una API REST pública en JSON

    https://ws040.juntadeandalucia.es/siel-api/v1/...

que es la que se usa aquí, con los mismos parámetros que el visor
(cautonoma=1, tconvocatoria=5 «Elecciones Autonómicas», fconvocatoria=aaaamm):

    /opciones/municipio?provincia=P            municipios (clave = código INE de 3 dígitos)
    /opciones/distrito?provincia=P&municipio=M distritos (clave = número de distrito)
    /opciones/seccion?...&distrito=D           secciones (valor = "0036", 4 dígitos)
    /resumen/seccion?...&seccion=0036          censo, votantes, blancos, nulos, candidaturas
    /escrutinio/ambito/seccion?...&seccion=... votos por candidatura de la sección

Trampas:
- La sección se pasa por su `valor` con 4 dígitos ("0036"), no por la clave
  numérica (con la clave responde un HTML de error 500). Los demás niveles
  (provincia, municipio, distrito) van por clave numérica.
- No hay descarga masiva: son 2 peticiones por sección (~6.500 secciones, ~0,8 s
  cada una). Se guardan en caché por municipio (JSON) y se descargan con pocos
  hilos en paralelo; una segunda ejecución no toca la red.
- La candidatura llega como "SIGLAS - DENOMINACIÓN" ("PP - PARTIDO POPULAR",
  "ANDALUCISTAS - PA - ANDALUCISTAS - PUEBLO ANDALUZ"). Las siglas se obtienen
  quitando la denominación oficial (de /opciones/partido); si no casa, se toma lo
  que hay antes del primer " - ", como hace el propio visor.
- El voto CERA (residentes ausentes) va por endpoints aparte (/rausentes) y no
  está en ninguna sección: los totales de la comunidad del resumen sí lo incluyen.
- Los nombres de municipio vienen con grafías dispares ("CUERVO DE SEVILLA (EL)",
  "El Saucejo"); solo se usan los códigos. Los municipios segregados recientes
  tienen códigos INE 9xx, que la API ya usa.
- CUSEC = provincia(2) + municipio(3) + distrito(2) + últimos 3 dígitos de la sección.

Histórico (1986-2022) por municipio:
- /opciones/fconvocatoria?cautonoma=1&tconvocatoria=5 da las 13 autonómicas (198205 ...
  202605). La de 1982 se excluye (ver _FECHAS): su desglose municipal no es fiable. Para las anteriores a 2026 se piden /resumen/municipio y
  /escrutinio/ambito/municipio (2 peticiones por municipio, ~1.570 por elección) y
  se exponen con municipios()/votos_municipios(); secciones()/votos() solo para 2026.
  Caché: <fconvocatoria>/municipios/<prov><mun>.json y _lista.json (municipios y
  denominaciones de partido de esa elección).
- /opciones/municipio devuelve los municipios de HOY también para elecciones
  anteriores a su segregación (p. ej. 41903 El Cuervo en 1982); para esos la API
  responde HTML 500 en /resumen/municipio. Se guardan con censo 0 y se descartan.
  Los códigos son los INE actuales, no los de la fecha de la elección.
- El CERA nunca está en los municipios: /resumen/rausentes/cautonoma lo da aparte
  desde 1986 (en 1982 responde 500: no se escrutó por separado en la API).
- La denominación de los partidos cambia de una elección a otra («PSOE de A»
  en 2004) e incluso de una provincia a otra (2008: «P.P.» en seis provincias y
  «PP» en Córdoba y Sevilla); las siglas se dejan como vienen y se unifican en dbt.
- Descuadres pequeños de la propia API entre municipios y resumen provincial: 1986
  Jaén y Málaga (en Málaga el CERA va dentro de los municipios), 1990 Jaén y
  Sevilla, 1994 Almería. Desde 1996 municipios + CERA = total al voto.

Licencia: aviso legal del visor (https://resultadoseleccionesandalucia.es/aviso-legal.html),
reutilización libre con reconocimiento (CC BY 3.0, «Información obtenida del Portal
de la Junta de Andalucía»).
"""

import json
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import date

import requests

from ingestion.autonomicas import cache

COD_CCAA = "01"
SLUG = "andalucia"
FUENTE = "https://resultadoseleccionesandalucia.es"
API = "https://ws040.juntadeandalucia.es/siel-api/v1"
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}
PROVINCIAS = [4, 11, 14, 18, 21, 23, 29, 41]
HILOS = 6

_MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
          "septiembre", "octubre", "noviembre", "diciembre"]
# Fechas de las autonómicas andaluzas (las que da /opciones/fconvocatoria), salvo la
# de 1982 (23-5-1982, fconvocatoria 198205): su desglose municipal en la API está
# mal asignado (códigos desplazados en Sevilla 41050-41065, Málaga capital con un
# 25 % menos de censo que en 1986, municipios que ya existían sin datos, provincias
# que no suman su propio resumen: Málaga -54.000 votos, Sevilla +31.800). No hay
# otra fuente municipal; se deja fuera hasta tener una fiable.
_FECHAS = [date(1986, 6, 22), date(1990, 6, 23), date(1994, 6, 12),
           date(1996, 3, 3), date(2000, 3, 12), date(2004, 3, 14), date(2008, 3, 9),
           date(2012, 3, 25), date(2015, 3, 22), date(2018, 12, 2), date(2022, 6, 19),
           date(2026, 5, 17)]
PROCESOS = [{"proceso": f"A01{f:%Y%m}", "fecha": f,
             "eleccion": f"Parlamento de Andalucía, {_MESES[f.month - 1]} de {f.year}"}
            for f in _FECHAS]
# Elecciones con datos por sección (rastreo de la API sección a sección, ~13.000
# peticiones). Las demás van por municipio (~1.600 peticiones).
POR_SECCION = {"A01202605"}

_sesion = requests.Session()
_sesion.headers.update(CABECERAS)


def _get(ruta: str, _vacio_si_500: bool = False, **params):
    """GET a la API con reintentos; devuelve el JSON.

    Con _vacio_si_500, un error 500 repetido (3 veces) devuelve None: es lo que
    responde la API para un municipio que aún no existía en esa elección."""
    errores_500 = 0
    for intento in range(5):
        try:
            r = _sesion.get(f"{API}/{ruta}", params=params, timeout=60)
            if r.status_code == 200:
                return r.json()
            if r.status_code < 500:
                r.raise_for_status()
            errores_500 += 1
            if _vacio_si_500 and errores_500 >= 3:
                return None
        except (requests.ConnectionError, requests.Timeout, ValueError):
            pass
        time.sleep(2 * (intento + 1))
    raise RuntimeError(f"La API del SIEL no responde: {ruta} {params}")


def _fconv(proceso: str) -> str:
    return proceso[3:]  # 'A01202605' -> '202605'


def _siglas(conjunto: str, denominaciones: list[str]) -> str:
    for d in denominaciones:
        if conjunto.endswith(" - " + d):
            return conjunto[: -len(d) - 3].strip()
    return conjunto.split(" - ")[0].strip()


def _municipio(fconv: str, prov: int, mun: int, denominaciones: list[str]) -> list[dict]:
    """Secciones de un municipio, con resumen y votos (en caché)."""
    ruta = cache(SLUG) / fconv / f"{prov:02d}{mun:03d}.json"
    if ruta.exists():
        return json.loads(ruta.read_text(encoding="utf-8"))
    base = {"cautonoma": 1, "provincia": prov, "municipio": mun,
            "tconvocatoria": 5, "fconvocatoria": fconv}
    filas = []
    for dist in _get("opciones/distrito", **base):
        d = dist["clave"]
        for sec in _get("opciones/seccion", **base, distrito=d):
            s = sec["valor"]
            q = {**base, "distrito": d, "seccion": s, "mesa": -1, "partido": -1}
            res = _get("resumen/seccion", **q)
            esc = _get("escrutinio/ambito/seccion", **q)
            filas.append({
                "cod_seccion": f"{prov:02d}{mun:03d}{d:02d}{int(s):03d}",
                "censo": res["censo"], "votos_blanco": res["votosblanco"],
                "votos_nulos": res["votosnulos"], "votos_candidaturas": res["votoscandidatura"],
                "votos": [{"siglas": _siglas(v["conjunto"], denominaciones), "votos": v["numvotos"]}
                          for v in esc.get("votos") or [] if v["numvotos"]],
            })
    ruta.parent.mkdir(parents=True, exist_ok=True)
    ruta.write_text(json.dumps(filas, ensure_ascii=False), encoding="utf-8")
    return filas


_memo: dict[str, list[dict]] = {}


def _datos(proceso: str) -> list[dict]:
    if proceso in _memo:
        return _memo[proceso]
    fconv = _fconv(proceso)
    base = {"cautonoma": 1, "tconvocatoria": 5, "fconvocatoria": fconv}
    denominaciones = sorted({p["valor"] for p in _get("opciones/partido/cautonoma", **base)},
                            key=len, reverse=True)
    tareas = [(p, m["clave"]) for p in PROVINCIAS
              for m in _get("opciones/municipio", **base, provincia=p)]
    with ThreadPoolExecutor(HILOS) as ex:
        bloques = list(ex.map(lambda t: _municipio(fconv, t[0], t[1], denominaciones), tareas))
    # Sumar por sección por si una sección apareciera partida.
    por_sec: dict[str, dict] = {}
    for filas in bloques:
        for f in filas:
            a = por_sec.setdefault(f["cod_seccion"], {"cod_seccion": f["cod_seccion"], "censo": 0,
                                                     "votos_blanco": 0, "votos_nulos": 0,
                                                     "votos_candidaturas": 0, "votos": {}})
            for k in ("censo", "votos_blanco", "votos_nulos", "votos_candidaturas"):
                a[k] += f[k]
            for v in f["votos"]:
                a["votos"][v["siglas"]] = a["votos"].get(v["siglas"], 0) + v["votos"]
    _memo[proceso] = list(por_sec.values())
    return _memo[proceso]


def secciones(proceso: str):
    if proceso not in POR_SECCION:
        return
    for s in _datos(proceso):
        yield {k: s[k] for k in ("cod_seccion", "censo", "votos_blanco", "votos_nulos",
                                 "votos_candidaturas")}


def votos(proceso: str):
    if proceso not in POR_SECCION:
        return
    for s in _datos(proceso):
        for siglas, n in s["votos"].items():
            yield {"cod_seccion": s["cod_seccion"], "siglas": siglas, "votos": n}


# --- Histórico por municipio ----------------------------------------------------

def _un_municipio(fconv: str, prov: int, mun: int, denominaciones: list[str]) -> dict:
    """Resumen y votos de un municipio (en caché)."""
    ruta = cache(SLUG) / fconv / "municipios" / f"{prov:02d}{mun:03d}.json"
    if ruta.exists():
        return json.loads(ruta.read_text(encoding="utf-8"))
    q = {"cautonoma": 1, "provincia": prov, "municipio": mun, "tconvocatoria": 5,
         "fconvocatoria": fconv, "partido": -1}
    res = _get("resumen/municipio", _vacio_si_500=True, **q)
    if res is None:  # municipio segregado después de esta elección
        res, esc = {"censo": 0, "votosblanco": 0, "votosnulos": 0, "votoscandidatura": 0}, {}
    else:
        esc = _get("escrutinio/ambito/municipio", **q)
    fila = {"cod_mun": f"{prov:02d}{mun:03d}", "censo": res["censo"] or 0,
            "votos_blanco": res["votosblanco"] or 0, "votos_nulos": res["votosnulos"] or 0,
            "votos_candidaturas": res["votoscandidatura"] or 0,
            "votos": [{"siglas": _siglas(v["conjunto"], denominaciones), "votos": v["numvotos"]}
                      for v in esc.get("votos") or [] if v["numvotos"]]}
    ruta.parent.mkdir(parents=True, exist_ok=True)
    ruta.write_text(json.dumps(fila, ensure_ascii=False), encoding="utf-8")
    return fila


_memo_mun: dict[str, list[dict]] = {}


def _datos_mun(proceso: str) -> list[dict]:
    if proceso in _memo_mun:
        return _memo_mun[proceso]
    fconv = _fconv(proceso)
    base = {"cautonoma": 1, "tconvocatoria": 5, "fconvocatoria": fconv}
    ruta = cache(SLUG) / fconv / "municipios" / "_lista.json"
    if ruta.exists():
        lista = json.loads(ruta.read_text(encoding="utf-8"))
    else:
        lista = {"denominaciones": sorted({p["valor"] for p in
                                           _get("opciones/partido/cautonoma", **base)},
                                          key=len, reverse=True),
                 "tareas": [(p, m["clave"]) for p in PROVINCIAS
                            for m in _get("opciones/municipio", **base, provincia=p)]}
        ruta.parent.mkdir(parents=True, exist_ok=True)
        ruta.write_text(json.dumps(lista, ensure_ascii=False), encoding="utf-8")
    den = lista["denominaciones"]
    with ThreadPoolExecutor(HILOS) as ex:
        filas = list(ex.map(lambda t: _un_municipio(fconv, t[0], t[1], den), lista["tareas"]))
    # Fuera los municipios sin censo (la API lista los de hoy también en elecciones
    # anteriores a su segregación).
    _memo_mun[proceso] = [f for f in filas if f["censo"]]
    return _memo_mun[proceso]


def municipios(proceso: str):
    if proceso in POR_SECCION:
        return
    for f in _datos_mun(proceso):
        yield {k: f[k] for k in ("cod_mun", "censo", "votos_blanco", "votos_nulos",
                                 "votos_candidaturas")}


def votos_municipios(proceso: str):
    if proceso in POR_SECCION:
        return
    for f in _datos_mun(proceso):
        por: dict[str, int] = {}
        for v in f["votos"]:
            por[v["siglas"]] = por.get(v["siglas"], 0) + v["votos"]
        for siglas, n in por.items():
            yield {"cod_mun": f["cod_mun"], "siglas": siglas, "votos": n}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
