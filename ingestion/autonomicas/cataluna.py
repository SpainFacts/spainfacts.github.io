"""Elecciones al Parlament de Catalunya por sección censal.

Fuente: portal de datos abiertos de la Generalitat (Socrata, analisi.transparenciacatalunya.cat),
conjuntos publicados por la Subdirecció General de Processos Electorals i Democràcia Directa
(Departament de la Presidència / Polítiques Digitals), los mismos que alimentan
https://eleccions.gencat.cat/ca/resultats-electorals/ :

    Processos electorals - Participació   https://analisi.transparenciacatalunya.cat/d/irrv-2mfc
        censo, votantes, nulos, blancos y votos a candidaturas por territorio
    Processos electorals - Vots           https://analisi.transparenciacatalunya.cat/d/ntc4-rnwr
        votos por candidatura y territorio
    Processos electorals - Convocatòries  https://analisi.transparenciacatalunya.cat/d/tgns-3xuy
        lista de procesos (id_eleccio 'A20241' = Parlament, 12 de mayo de 2024)

Cada conjunto mezcla todos los procesos (desde 1980) y todos los niveles territoriales
(id_nivell_territorial: CA comunidad, PR provincia, VE veguería, CO comarca, MU municipio,
DM distrito municipal, SE sección, ME mesa); cada nivel suma lo mismo, así que se filtra
por proceso Y nivel con la API SODA ($where), y se pide el nivel SE, que ya suma las mesas
de cada sección (la Generalitat lo calcula; comprobado que coincide con sumar el nivel ME).
Se descarga en CSV (`/resource/<id>.csv`, solo las columnas usadas): ~0,4 MB de participación
y ~6 MB de votos, unos 5 s.

Trampas:
- Los dos conjuntos NO formatean igual los códigos: Participació los da sin ceros a la
  izquierda ("8089", distrito "1", sección "4") y Vots con ceros ("08089", "01", "004").
  Se normalizan con zfill: municipio INE 5 dígitos (sin dígito de control), distrito 2,
  sección 3 → CUSEC de 10 dígitos.
- El voto de los residentes ausentes (CERA) va como un municipio ficticio por provincia,
  código pp998 ("Residents Absents Barcelona"...), con una única "sección" 01/001: se
  descarta. Por eso el total que sale aquí es el oficial menos el CERA.
- La API SODA devuelve como mucho las filas que se pidan en $limit (por defecto 1.000):
  se pide un $limit holgado y se comprueba que no se ha llegado a él.
- Las siglas (`candidatura_sigles`) son las de la papeleta: "JUNTS+", "COMUNS SUMAR",
  "PP", "VOX", "CUP-DT", "AC"...; la familia política se asigna en dbt.

Licencia: datos abiertos de la Generalitat de Catalunya, reutilización libre con cita de
la fuente (https://administraciodigital.gencat.cat/ca/dades/dades-obertes/informacio-practica/llicencies/).
"""

import csv
import io
from datetime import date
from typing import Iterable

import requests

from ingestion.autonomicas import cache

COD_CCAA = "09"
SLUG = "cataluna"
FUENTE = "https://analisi.transparenciacatalunya.cat/d/irrv-2mfc"
PROCESOS = [
    {"proceso": "A09202405", "fecha": date(2024, 5, 12),
     "eleccion": "Parlament de Catalunya, mayo de 2024"},
]
# Proceso SpainFacts -> id_eleccio de la Generalitat
ID_ELECCIO = {"A09202405": "A20241"}

BASE = "https://analisi.transparenciacatalunya.cat/resource"
PARTICIPACIO = "irrv-2mfc"
VOTS = "ntc4-rnwr"
LIMITE = 500_000
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}


# Solo las columnas que se usan (el conjunto de votos trae logotipos, colores... y triplica el peso)
COLUMNAS = {
    PARTICIPACIO: "territori_codi,territori_nom,districte,seccio,cens_electoral,votants,"
                  "vots_nuls,vots_blancs,vots_candidatures",
    VOTS: "territori_codi,territori_nom,districte,secci_,candidatura_codi,candidatura_sigles,"
          "candidatura_denominacio,vots",
}


def _csv(dataset: str, proceso: str) -> list[dict]:
    """Filas del nivel sección de un proceso (con caché local)."""
    id_eleccio = ID_ELECCIO[proceso]
    ruta = cache(SLUG) / f"{id_eleccio}_{dataset}_SE.csv"
    if not ruta.exists():
        r = requests.get(
            f"{BASE}/{dataset}.csv",
            params={"$select": COLUMNAS[dataset],
                    "$where": f"id_eleccio='{id_eleccio}' AND id_nivell_territorial='SE'",
                    "$limit": LIMITE},
            headers=CABECERAS, timeout=300)
        r.raise_for_status()
        ruta.write_bytes(r.content)
    with open(ruta, encoding="utf-8", newline="") as f:
        filas = list(csv.DictReader(f))
    if len(filas) >= LIMITE:
        raise RuntimeError(f"{ruta.name}: {len(filas)} filas, se ha llegado al $limit")
    return filas


def _seccion(fila: dict, campo_seccion: str) -> str | None:
    """CUSEC (10 dígitos) o None si es el CERA (municipio pp998)."""
    mun = fila["territori_codi"].strip().zfill(5)
    if mun.endswith("998"):
        return None
    return mun + fila["districte"].strip().zfill(2) + fila[campo_seccion].strip().zfill(3)


def _int(x: str) -> int:
    return int(float(x)) if x else 0


def secciones(proceso: str) -> Iterable[dict]:
    acum: dict[str, dict] = {}
    for f in _csv(PARTICIPACIO, proceso):
        cod = _seccion(f, "seccio")
        if cod is None:
            continue
        a = acum.setdefault(cod, {"cod_seccion": cod, "censo": 0, "votos_blanco": 0,
                                  "votos_nulos": 0, "votos_candidaturas": 0})
        a["censo"] += _int(f["cens_electoral"])
        a["votos_blanco"] += _int(f["vots_blancs"])
        a["votos_nulos"] += _int(f["vots_nuls"])
        a["votos_candidaturas"] += _int(f["vots_candidatures"])
    return list(acum.values())


def votos(proceso: str) -> Iterable[dict]:
    acum: dict[tuple[str, str], int] = {}
    for f in _csv(VOTS, proceso):
        cod = _seccion(f, "secci_")
        if cod is None:
            continue
        siglas = (f["candidatura_sigles"] or f["candidatura_denominacio"]).strip()
        acum[(cod, siglas)] = acum.get((cod, siglas), 0) + _int(f["vots"])
    return [{"cod_seccion": c, "siglas": s, "votos": v} for (c, s), v in acum.items()]


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
