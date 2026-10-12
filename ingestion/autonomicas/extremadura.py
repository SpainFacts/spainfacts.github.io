"""Elecciones a la Asamblea de Extremadura por sección censal: SOLO la ciudad de Cáceres.

La Junta de Extremadura no publica resultados por mesa ni por sección
----------------------------------------------------------------------
- La web de la noche electoral (https://resultados.elecciones2025.juntaex.es) solo daba
  datos por municipio y comunidad. Además, su dominio ya no existe: no resuelve en DNS
  desde 2026, y la sección /es/descargas daba 404 desde febrero de 2026.
- Los CSV para medios (prensa.elecciones2025.juntaex.es) iban con credenciales y solo para
  medios acreditados.
- El DOE (proclamación de la Junta Electoral de Extremadura) solo publica totales por
  circunscripción.
- Ni datos.gob.es ni el catálogo de datos abiertos de la Junta tienen datasets electorales.
- Interior no publica las autonómicas.
Los portales de Badajoz, Mérida y Plasencia tampoco publican resultados por mesa
(comprobado el 12-10-2026).

Fuente: Ayuntamiento de Cáceres (SIG / IDE municipal)
-----------------------------------------------------
El catálogo de datos abiertos del Ayuntamiento de Cáceres
(https://opendata.caceres.es/datosabiertos/catalogo/dataset/elecciones-autonomicas-de-2025,
y el equivalente "-de-2023") publica una capa por elección en su GeoServer, con una fila
por sección censal del municipio (ya sumadas sus mesas) y geometría:

    https://ide.caceres.es/geoserver/elecciones/ows?service=WFS&version=1.0.0
        &request=GetFeature&typeName=elecciones:elecciones_autonomicas_{aaaa}&outputFormat=csv

Aviso legal del portal (https://opendata.caceres.es/aviso-legal.html): los datos «pueden
ser reutilizados y redistribuidos libremente». El dataset de CKAN no declara licencia.

Columnas: distrito (3 dígitos, «001»), seccion (3), censados, votos (= votantes, incluye
blancos y nulos), votos_blancos/votos_nulos (en 2023, votos_blan/votos_nulo), una
columna de votos por candidatura en minúsculas (psoe, pp, vox, podemos...), sus
porcentajes por_* (que se descartan), area, color y geom (polígono WKT; se descarta).

Trampas
-------
- El distrito viene con 3 dígitos: el CUSEC usa los 2 últimos (10037 + "01" + "001").
- Las candidaturas son nombres de columna, no siglas oficiales: se traducen con SIGLAS a
  algo que entienda el seed elecciones_partidos_reglas (p. ej., podemos → PODEMOS-IU-AV,
  que es Unidas por Extremadura). Si aparece una columna nueva, se usa en mayúsculas.
- «votos» incluye blancos y nulos. Los votos a candidaturas se calculan sumando las
  columnas de partido, no restando. En 2023, la sección 02-004 tiene 1 voto más en
  «votos» que la suma de sus partes.
- El censo es el CER de residentes en cada sección; el CERA no se reparte por secciones.
- 2025: las secciones 04-026 y 06-006 son nuevas. Están en el seccionado del INE de 2026,
  pero no en el de 2025, que es el que usa probar() para esta elección.
- ide.caceres.es sirve el certificado sin el intermedio (Thawte TLS RSA CA G1): curl en
  Windows lo tolera y requests no. Se arma en caché un bundle certifi + intermedio
  (descargado de DigiCert) sin desactivar la verificación.
- Se desconoce si son datos del escrutinio provisional o del definitivo: la fuente no lo
  dice.
"""

import csv
import io
import ssl
from datetime import date
from typing import Iterable

import requests

from ingestion.autonomicas import cache

COD_CCAA = "11"
SLUG = "extremadura"
FUENTE = "https://opendata.caceres.es/datosabiertos/catalogo/dataset/elecciones-autonomicas-de-2025"
COBERTURA = "Solo Cáceres (ciudad): la Junta no publica resultados por mesa"

COD_MUN = "10037"  # Cáceres (INE)
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}
URL = ("https://ide.caceres.es/geoserver/elecciones/ows?service=WFS&version=1.0.0"
       "&request=GetFeature&typeName=elecciones%3Aelecciones_autonomicas_{anio}&outputFormat=csv")
# ide.caceres.es no envía el certificado intermedio (Thawte TLS RSA CA G1): Python falla
# con CERTIFICATE_VERIFY_FAILED. Se descarga de DigiCert (AIA) y se añade a certifi.
URL_INTERMEDIO = "http://cacerts.digicert.com/ThawteTLSRSACAG1.crt"

PROCESOS = [
    {"proceso": "A11202512", "fecha": date(2025, 12, 21),
     "eleccion": "Asamblea de Extremadura, diciembre de 2025 (solo Cáceres ciudad)"},
    {"proceso": "A11202305", "fecha": date(2023, 5, 28),
     "eleccion": "Asamblea de Extremadura, mayo de 2023 (solo Cáceres ciudad)"},
]

# Columnas que no son candidaturas
NO_PARTIDO = {"FID", "geom", "distrito", "seccion", "censados", "votos", "area", "color",
              "votos_blancos", "votos_nulos", "votos_blan", "votos_nulo", "por_participacion",
              "por_parti"}

# Columna de la capa -> siglas de la candidatura
SIGLAS = {
    "pp": "PP",
    "psoe": "PSOE",
    "vox": "VOX",
    "podemos": "PODEMOS-IU-AV",          # Unidas por Extremadura (Podemos-IU-Alianza Verde)
    "cs": "CS",
    "ued_syt": "UED-SYT",                # Una Extremadura Digna-Soberanía y Trabajo
    "ued": "UED",
    "juntos_levanta": "JUEX-LEVANTA",    # Juntos por Extremadura-Levanta Extremadura
    "juex": "JUEX",                      # Juntos por Extremadura
    "levanta": "LEVANTA",                # Levanta Extremadura
    "extremadura_unida": "EXTREMADURA UNIDA",
    "nex": "NEX",                        # Nuevo Extremeñismo-Adelante Extremadura
    "mundo_justo": "PUM+J",              # Por un Mundo Más Justo
    "pumj": "PUM+J",
    "pacma": "PACMA",
    "caceres_vi": "CACERES VIVA",
    "somos_cc": "SOMOS CC",
    "pex_ext": "PEX-EXT",
}


def _anio(proceso: str) -> int:
    for p in PROCESOS:
        if p["proceso"] == proceso:
            return p["fecha"].year
    raise ValueError(f"Proceso desconocido: {proceso}")


def _ca_bundle() -> str:
    """certifi + el intermedio que ide.caceres.es no envía (verificación TLS intacta)."""
    destino = cache(SLUG) / "ca_bundle_caceres.pem"
    if not destino.exists():
        import certifi
        der = requests.get(URL_INTERMEDIO, headers=CABECERAS, timeout=60).content
        pem = ssl.DER_cert_to_PEM_cert(der) if not der.startswith(b"-----") else der.decode()
        destino.write_text(open(certifi.where(), encoding="utf-8").read() + "\n" + pem,
                           encoding="utf-8")
    return str(destino)


def _filas(proceso: str) -> list[dict]:
    anio = _anio(proceso)
    f = cache(SLUG) / f"caceres_autonomicas_{anio}.csv"
    if not f.exists():
        r = requests.get(URL.format(anio=anio), headers=CABECERAS, timeout=180,
                         verify=_ca_bundle())
        r.raise_for_status()
        if not r.content.startswith(b"FID,"):
            raise RuntimeError(f"Respuesta inesperada del GeoServer de Cáceres: {r.content[:200]!r}")
        f.write_bytes(r.content)
    csv.field_size_limit(1 << 30)  # la geometría WKT es muy larga
    with open(f, encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(io.StringIO(fh.read())))


def _partidos(fila: dict) -> list[str]:
    return [c for c in fila if c not in NO_PARTIDO and not c.startswith("por_")]


def _cod_seccion(fila: dict) -> str:
    d, s = fila["distrito"].strip(), fila["seccion"].strip()
    if len(d) == 3 and d.startswith("0"):
        d = d[1:]
    if len(d) != 2 or len(s) != 3 or not (d + s).isdigit():
        raise ValueError(f"Sección con formato inesperado: distrito={d!r} seccion={s!r}")
    return COD_MUN + d + s


def secciones(proceso: str) -> Iterable[dict]:
    acum: dict[str, dict] = {}
    for f in _filas(proceso):
        cod = _cod_seccion(f)
        blanco = int(f.get("votos_blancos") or f.get("votos_blan") or 0)
        nulos = int(f.get("votos_nulos") or f.get("votos_nulo") or 0)
        cand = sum(int(f[c] or 0) for c in _partidos(f))
        a = acum.setdefault(cod, {"cod_seccion": cod, "censo": 0, "votos_blanco": 0,
                                  "votos_nulos": 0, "votos_candidaturas": 0})
        a["censo"] += int(f["censados"] or 0)
        a["votos_blanco"] += blanco
        a["votos_nulos"] += nulos
        a["votos_candidaturas"] += cand
    return list(acum.values())


def votos(proceso: str) -> Iterable[dict]:
    acum: dict[tuple[str, str], int] = {}
    for f in _filas(proceso):
        cod = _cod_seccion(f)
        for c in _partidos(f):
            n = int(f[c] or 0)
            siglas = SIGLAS.get(c, c.upper())
            acum[(cod, siglas)] = acum.get((cod, siglas), 0) + n
    return [{"cod_seccion": c, "siglas": s, "votos": n} for (c, s), n in acum.items() if n]


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
