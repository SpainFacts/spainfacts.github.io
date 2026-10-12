"""Elecciones a la Junta General del Principado de Asturias por sección censal (SOLO GIJÓN).

Cobertura parcial: el Principado no publica resultados por mesa. Lo más fino que da
SADEI (https://www.sadei.es/sadei/resultados-electorales/elecciones-autonomicas_249_1_ap.html,
también en datos.gob.es como a03002951-elecciones-autonomicas-asturias) es el concejo.
La web de resultados provisionales de la noche electoral
(resultadosasturias2023.infoelecciones.com) ya no existe y, en todo caso, llegaba
como mucho a municipio. Interior no publica las autonómicas. De los 78 concejos, el
único que publica resultados por mesa en abierto es Gijón (33024), que reúne
alrededor del 23 % del censo.

Fuente: portal de datos abiertos del Ayuntamiento de Gijón, conjunto
«Datos elecciones autonómicas año 2023» (id 958, ficha en datos.gob.es
l01330241-datos-elecciones-autonomicas-ano-2023):

    https://opendata.gijon.es/descargar.php?id=958&tipo=CSV

Es un CSV UTF-8 con BOM de unos 0,7 MB y 7.644 filas, con estas columnas:
AÑO, TITULO, FECHA_ELECCIONES, DISTRITO, SECCION, MESA, PARTIDO, NUM_VOTOS, PORCENTAJE.

Trampas:
- Formato largo: en PARTIDO van tanto las candidaturas como los totales de la mesa
  (Electores, Votantes, Abstenciones, Validos, Blancos, Nulos). Se separan con
  NO_PARTIDOS. Los votos a candidaturas se calculan sumando las candidaturas, y
  coinciden con Validos - Blancos.
- DISTRITO y SECCION vienen como enteros sin ceros a la izquierda ("1", "1"). La
  sección del INE (CUSEC) es 33024 + distrito con 2 dígitos + sección con 3. La
  MESA (A, B, U…) se suma dentro de su sección.
- PORCENTAJE trae la coma decimal y no va entre comillas, así que parte la fila en
  más campos de la cuenta. No se usa: las columnas se leen por posición y solo
  hacen falta las ocho primeras.
- No hay filas del CERA: el voto de residentes ausentes no se asigna a ninguna mesa
  del municipio. El censo es el de escrutinio de las mesas.
- Siglas tal cual las da el Ayuntamiento: IU-MAS (Convocatoria por Asturies
  IU-Más País-IAS), AA (Andecha Astur), SMP (Suma Principado), PUM J (PUM+J), CS…
"""

import csv
import io
from collections import defaultdict
from datetime import date

import requests

from ingestion.autonomicas import cache

SLUG = "asturias"
COD_CCAA = "03"
FUENTE = "https://opendata.gijon.es/descargar.php?id=958&tipo=CSV"
COBERTURA = "Solo Gijón: el Principado no publica resultados por mesa"
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

PROCESOS = [
    {"proceso": "A03202305", "fecha": date(2023, 5, 28),
     "eleccion": "Junta General del Principado de Asturias, mayo de 2023"},
]

COD_MUNICIPIO = "33024"  # Gijón (INE)
NO_PARTIDOS = {"Electores", "Votantes", "Abstenciones", "Validos", "Blancos", "Nulos"}


def _filas(proceso: str) -> list[list[str]]:
    if proceso != "A03202305":
        raise ValueError(f"Proceso desconocido: {proceso}")
    ruta = cache(SLUG) / "gijon_autonomicas_2023.csv"
    if not ruta.exists():
        r = requests.get(FUENTE, headers=CABECERAS, timeout=120)
        r.raise_for_status()
        ruta.write_bytes(r.content)
    texto = ruta.read_bytes().decode("utf-8-sig")
    lector = csv.reader(io.StringIO(texto))
    cab = next(lector)
    assert cab[3:8] == ["DISTRITO", "SECCION", "MESA", "PARTIDO", "NUM_VOTOS"], cab
    return [f for f in lector if f and f[0].strip()]


def _seccion(distrito: str, seccion: str) -> str:
    return f"{COD_MUNICIPIO}{int(distrito):02d}{int(seccion):03d}"


def secciones(proceso: str):
    acum: dict[str, dict] = defaultdict(lambda: {"censo": 0, "votos_blanco": 0,
                                                 "votos_nulos": 0, "votos_candidaturas": 0})
    for f in _filas(proceso):
        cod = _seccion(f[3], f[4])
        partido, n = f[6].strip(), int(f[7])
        a = acum[cod]
        if partido == "Electores":
            a["censo"] += n
        elif partido == "Blancos":
            a["votos_blanco"] += n
        elif partido == "Nulos":
            a["votos_nulos"] += n
        elif partido not in NO_PARTIDOS:
            a["votos_candidaturas"] += n
    for cod, a in sorted(acum.items()):
        yield {"cod_seccion": cod, **a}


def votos(proceso: str):
    acum: dict[tuple[str, str], int] = defaultdict(int)
    for f in _filas(proceso):
        partido = f[6].strip()
        if partido in NO_PARTIDOS:
            continue
        acum[(_seccion(f[3], f[4]), partido)] += int(f[7])
    for (cod, siglas), n in sorted(acum.items()):
        yield {"cod_seccion": cod, "siglas": siglas, "votos": n}


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
