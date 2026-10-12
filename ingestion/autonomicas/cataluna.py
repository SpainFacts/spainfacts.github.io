"""Elecciones al Parlament de Catalunya por sección censal (y por municipio), de 1980 a 2024.

Fuente: portal de datos abiertos de la Generalitat (Socrata, analisi.transparenciacatalunya.cat),
conjuntos publicados por la Subdirecció General de Processos Electorals i Democràcia Directa
(Departament de la Presidència / Polítiques Digitals), los mismos que alimentan
https://eleccions.gencat.cat/ca/resultats-electorals/ :

    Processos electorals - Participació   https://analisi.transparenciacatalunya.cat/d/irrv-2mfc
        censo, votantes, nulos, blancos y votos a candidaturas por territorio
    Processos electorals - Vots           https://analisi.transparenciacatalunya.cat/d/ntc4-rnwr
        votos por candidatura y territorio
    Processos electorals - Convocatòries  https://analisi.transparenciacatalunya.cat/d/tgns-3xuy
        lista de procesos: 'A19801' ... 'A20241' (Parlament), con su fecha (data_eleccio)

Cada conjunto mezcla todos los procesos (desde 1980) y todos los niveles territoriales
(id_nivell_territorial: CA comunidad, PR provincia, VE veguería, CO comarca, MU municipio,
DM distrito municipal, SE sección, ME mesa); cada nivel suma lo mismo, así que se filtra
por proceso Y nivel con la API SODA ($where), y se pide el nivel SE, que ya suma las mesas
de cada sección (la Generalitat lo calcula; comprobado que coincide con sumar el nivel ME).
Se descarga en CSV (`/resource/<id>.csv`, solo las columnas usadas): ~0,4 MB de participación
y ~6 MB de votos por elección.

Histórico (las 14 elecciones al Parlament, 1980-2024):
- 1988-2024: el nivel SE suma exactamente lo mismo que CA y que MU (comprobado municipio a
  municipio), así que bastan las secciones.
- 1980: el nivel SE está incompleto: falta entera la provincia de Girona (219 municipios,
  226.248 votos) y a Barcelona y Vic les faltan secciones. Solo se dan municipios (nivel MU,
  que suma lo mismo que CA y que el resultado oficial: CiU 752.943, PSC 606.717...).
- 1984: el nivel SE (= ME) suma 495 votos a candidaturas MÁS que CA/MU y que el oficial
  (CiU 1.346.917 frente a 1.346.729), con votos asignados al municipio que no es (Òdena +387,
  Orpí -387, Molins de Rei +454...). Se dan las secciones tal cual (mapa de barrio) y además
  los municipios del nivel MU, que cuadran con el oficial (página de la comunidad).
- No hubo voto CERA hasta 1988 (ley de 1985); desde entonces va como municipio ficticio pp998.

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
_MESES = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
          "septiembre", "octubre", "noviembre", "diciembre"]
# id_eleccio de la Generalitat -> fecha (conjunto Convocatòries, data_eleccio)
_FECHAS = {
    "A19801": date(1980, 3, 20), "A19841": date(1984, 4, 29), "A19881": date(1988, 5, 29),
    "A19921": date(1992, 3, 15), "A19951": date(1995, 11, 19), "A19991": date(1999, 10, 17),
    "A20031": date(2003, 11, 16), "A20061": date(2006, 11, 1), "A20101": date(2010, 11, 28),
    "A20121": date(2012, 11, 25), "A20151": date(2015, 9, 27), "A20171": date(2017, 12, 21),
    "A20211": date(2021, 2, 14), "A20241": date(2024, 5, 12),
}
PROCESOS = [
    {"proceso": f"A{COD_CCAA}{f.year}{f.month:02d}", "fecha": f,
     "eleccion": f"Parlament de Catalunya, {_MESES[f.month - 1]} de {f.year}"}
    for f in sorted(_FECHAS.values())
]
# Proceso SpainFacts -> id_eleccio de la Generalitat
ID_ELECCIO = {f"A{COD_CCAA}{f.year}{f.month:02d}": i for i, f in _FECHAS.items()}
# Procesos cuyo nivel SE no sirve para el total (ver arriba): sin secciones / con municipios
SIN_SECCIONES = {"A09198003"}
CON_MUNICIPIOS = {"A09198003", "A09198404"}

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


def _csv(dataset: str, proceso: str, nivel: str = "SE") -> list[dict]:
    """Filas de un nivel territorial (SE sección, MU municipio) de un proceso (con caché local)."""
    id_eleccio = ID_ELECCIO[proceso]
    ruta = cache(SLUG) / f"{id_eleccio}_{dataset}_{nivel}.csv"
    if not ruta.exists():
        r = requests.get(
            f"{BASE}/{dataset}.csv",
            params={"$select": COLUMNAS[dataset],
                    "$where": f"id_eleccio='{id_eleccio}' AND id_nivell_territorial='{nivel}'",
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


def _municipio(fila: dict, _campo: str) -> str | None:
    """Código INE del municipio (5 dígitos) o None si es el CERA (pp998)."""
    mun = fila["territori_codi"].strip().zfill(5)
    return None if mun.endswith("998") else mun


def _int(x: str) -> int:
    return int(float(x)) if x else 0


def _participacion(proceso: str, nivel: str, clave: str) -> list[dict]:
    codigo = _seccion if nivel == "SE" else _municipio
    acum: dict[str, dict] = {}
    for f in _csv(PARTICIPACIO, proceso, nivel):
        cod = codigo(f, "seccio")
        if cod is None:
            continue
        a = acum.setdefault(cod, {clave: cod, "censo": 0, "votos_blanco": 0,
                                  "votos_nulos": 0, "votos_candidaturas": 0})
        a["censo"] += _int(f["cens_electoral"])
        a["votos_blanco"] += _int(f["vots_blancs"])
        a["votos_nulos"] += _int(f["vots_nuls"])
        a["votos_candidaturas"] += _int(f["vots_candidatures"])
    return list(acum.values())


def _votos(proceso: str, nivel: str, clave: str) -> list[dict]:
    codigo = _seccion if nivel == "SE" else _municipio
    acum: dict[tuple[str, str], int] = {}
    for f in _csv(VOTS, proceso, nivel):
        cod = codigo(f, "secci_")
        if cod is None:
            continue
        siglas = (f["candidatura_sigles"] or f["candidatura_denominacio"]).strip()
        acum[(cod, siglas)] = acum.get((cod, siglas), 0) + _int(f["vots"])
    return [{clave: c, "siglas": s, "votos": v} for (c, s), v in acum.items()]


def secciones(proceso: str) -> Iterable[dict]:
    return [] if proceso in SIN_SECCIONES else _participacion(proceso, "SE", "cod_seccion")


def votos(proceso: str) -> Iterable[dict]:
    return [] if proceso in SIN_SECCIONES else _votos(proceso, "SE", "cod_seccion")


def municipios(proceso: str) -> Iterable[dict]:
    return _participacion(proceso, "MU", "cod_mun") if proceso in CON_MUNICIPIOS else []


def votos_municipios(proceso: str) -> Iterable[dict]:
    return _votos(proceso, "MU", "cod_mun") if proceso in CON_MUNICIPIOS else []


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
