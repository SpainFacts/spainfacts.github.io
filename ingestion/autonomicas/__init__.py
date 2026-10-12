"""Elecciones autonómicas por sección censal (mapas de barrio de la ficha de municipio).

El Ministerio del Interior no publica las autonómicas: cada comunidad difunde sus
resultados por mesa a su manera. Hay un módulo por comunidad en este paquete
(`ingestion/autonomicas/<slug>.py`) con la MISMA interfaz, y ingestion/elecciones.py
los junta en los recursos elecciones_secciones / elecciones_secciones_votos.

Interfaz de cada módulo
-----------------------
COD_CCAA: str            código INE de la comunidad ('01' Andalucía ... '17' La Rioja)
FUENTE: str              URL de la página oficial de la que salen los datos
PROCESOS: list[dict]     elecciones con datos por sección, una por dict:
    {"proceso": "A01202605",          # 'A' + COD_CCAA + aaaa + mm (no choca con Interior)
     "fecha": date(2026, 5, 17),
     "eleccion": "Parlamento de Andalucía, mayo de 2026"}

def secciones(proceso: str) -> Iterable[dict]
    Una fila por sección censal (sumando sus mesas):
    {"cod_seccion": "4109101001",     # CUSEC del INE: prov(2) + mun(3) + distrito(2) + sección(3)
     "censo": int,                    # censo de escrutinio (sin CERA si se puede separar)
     "votos_blanco": int, "votos_nulos": int, "votos_candidaturas": int}

def votos(proceso: str) -> Iterable[dict]
    Una fila por sección y candidatura:
    {"cod_seccion": str, "siglas": str, "votos": int}
    `siglas` tal como las publica la fuente (la familia política se asigna en dbt con
    el seed elecciones_partidos_reglas, como en las generales).

Histórico por municipio (opcional)
----------------------------------
PROCESOS puede incluir TODAS las autonómicas de la comunidad (las anteriores también),
de la más antigua a la más reciente. Los mapas de barrio usan solo la última con datos
por sección; la página de la comunidad usa todas, por municipio. Para cada proceso:

- si hay datos por sección, secciones()/votos() como arriba (el municipio se saca del
  código de sección);
- si solo los hay por municipio (o la sección exige rastrear una API petición a
  petición), el módulo define además

  def municipios(proceso: str) -> Iterable[dict]
      {"cod_mun": "41091", "censo": int, "votos_blanco": int, "votos_nulos": int,
       "votos_candidaturas": int}
  def votos_municipios(proceso: str) -> Iterable[dict]
      {"cod_mun": str, "siglas": str, "votos": int}

  y secciones()/votos() devuelven [] para ese proceso. Si para un proceso hay las dos
  cosas (p. ej. secciones solo de Gijón y municipios de toda Asturias), se usan los
  municipios para la página de la comunidad y las secciones para el mapa de barrio.
- cod_mun es el código INE del municipio en la fecha de la elección (5 dígitos); si un
  municipio ya no existe o ha cambiado de código, se deja tal cual.

Reglas
------
- Descargas en caché en data/autonomicas_cache/<slug>/ (ignorado por git); nada de
  MotherDuck ni de dbt desde los módulos.
- Excluir el voto CERA / residentes ausentes y cualquier fila sin sección real.
- Si la fuente parte la sección en subsecciones o mesas, sumarlas a la sección.
- Comprobar con `probar(modulo)`: votos totales frente al resultado oficial de la
  comunidad y % de secciones que casan con el seccionado del INE del año de la elección
  (data/secciones_codigos/<año>.csv; usar el año más cercano disponible, 2023-2026).
"""

import csv
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CACHE = REPO / "data" / "autonomicas_cache"
CODIGOS = REPO / "data" / "secciones_codigos"


def cache(slug: str) -> Path:
    """Carpeta de descargas del módulo."""
    d = CACHE / slug
    d.mkdir(parents=True, exist_ok=True)
    return d


def codigos_ine(anio: int) -> set[str]:
    """Códigos de sección del seccionado del INE más cercano al año pedido."""
    anios = sorted(int(p.stem) for p in CODIGOS.glob("*.csv"))
    if not anios:
        raise FileNotFoundError(f"No hay listas de secciones en {CODIGOS}")
    elegido = min(anios, key=lambda a: (abs(a - anio), -a))
    with open(CODIGOS / f"{elegido}.csv", encoding="utf-8") as f:
        return {r["cod_seccion"] for r in csv.DictReader(f)}


def probar(modulo) -> None:
    """Resumen de comprobación de un módulo: totales, siglas y casado con el INE."""
    for p in modulo.PROCESOS:
        if hasattr(modulo, "municipios"):
            m = list(modulo.municipios(p["proceso"]))
            if m:
                vm = list(modulo.votos_municipios(p["proceso"]))
                print(f"== {p['proceso']} · {p['eleccion']} · POR MUNICIPIO")
                print(f"municipios: {len({r['cod_mun'] for r in m})} · censo: {sum(r['censo'] or 0 for r in m):,}"
                      f" · candidaturas: {sum(r['votos_candidaturas'] for r in m):,}"
                      f" · blancos: {sum(r['votos_blanco'] or 0 for r in m):,} · nulos: {sum(r['votos_nulos'] or 0 for r in m):,}")
                por: dict[str, int] = {}
                for r in vm:
                    por[r["siglas"]] = por.get(r["siglas"], 0) + r["votos"]
                print(f"suma de votos por candidatura: {sum(por.values()):,} · "
                      + " · ".join(f"{k} {n:,}" for k, n in sorted(por.items(), key=lambda x: -x[1])[:6]))
        s = list(modulo.secciones(p["proceso"]))
        v = list(modulo.votos(p["proceso"]))
        if not s:
            continue
        ine = codigos_ine(p["fecha"].year)
        codigos = {r["cod_seccion"] for r in s}
        casan = len(codigos & ine)
        por_siglas: dict[str, int] = {}
        for r in v:
            por_siglas[r["siglas"]] = por_siglas.get(r["siglas"], 0) + r["votos"]
        print(f"== {p['proceso']} · {p['eleccion']}")
        print(f"secciones: {len(codigos)} · casan con el INE: {casan} ({100 * casan / max(1, len(codigos)):.1f} %)"
              f" · municipios: {len({c[:5] for c in codigos})}")
        print(f"censo: {sum(r['censo'] or 0 for r in s):,} · candidaturas: {sum(r['votos_candidaturas'] for r in s):,}"
              f" · blancos: {sum(r['votos_blanco'] or 0 for r in s):,} · nulos: {sum(r['votos_nulos'] or 0 for r in s):,}")
        print(f"suma de votos por candidatura (fichero de votos): {sum(por_siglas.values()):,}")
        for siglas, n in sorted(por_siglas.items(), key=lambda x: -x[1])[:10]:
            print(f"   {siglas}: {n:,}")
        no_casan = sorted(codigos - ine)[:10]
        if no_casan:
            print(f"ejemplos que no casan: {no_casan}")
