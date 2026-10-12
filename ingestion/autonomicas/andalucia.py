"""Elecciones al Parlamento de Andalucía por sección censal (Junta de Andalucía).

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

PROCESOS = [
    {"proceso": "A01202605", "fecha": date(2026, 5, 17),
     "eleccion": "Parlamento de Andalucía, mayo de 2026"},
]

_sesion = requests.Session()
_sesion.headers.update(CABECERAS)


def _get(ruta: str, **params):
    """GET a la API con reintentos; devuelve el JSON."""
    for intento in range(5):
        try:
            r = _sesion.get(f"{API}/{ruta}", params=params, timeout=60)
            if r.status_code == 200:
                return r.json()
            if r.status_code < 500:
                r.raise_for_status()
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
    for s in _datos(proceso):
        yield {k: s[k] for k in ("cod_seccion", "censo", "votos_blanco", "votos_nulos",
                                 "votos_candidaturas")}


def votos(proceso: str):
    for s in _datos(proceso):
        for siglas, n in s["votos"].items():
            yield {"cod_seccion": s["cod_seccion"], "siglas": siglas, "votos": n}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
