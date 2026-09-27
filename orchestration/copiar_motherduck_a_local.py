"""Copia la base de datos de MotherDuck (SpainFacts) a un DuckDB local.

Atajo para empezar a desarrollar en local sin volver a descargar todas las
fuentes (algunas, como el histórico de AEMET, tardan mucho). Copia todos los
esquemas (raw, staging, main) y sus tablas. Las vistas de staging se recrean
con `dbt build` en modo local.

Uso (desde la raíz del repo, con MOTHERDUCK_TOKEN en el entorno):
    .venv/Scripts/python -m orchestration.copiar_motherduck_a_local
    # destino: SPAINFACTS_DUCKDB o data/spainfacts.duckdb
"""

import os

import duckdb

from ingestion.destino import ruta_duckdb_local


def main() -> None:
    if not os.environ.get("MOTHERDUCK_TOKEN") and not os.environ.get("motherduck_token"):
        raise SystemExit("Falta MOTHERDUCK_TOKEN en el entorno (carga el .env primero).")

    destino = ruta_duckdb_local()
    destino.parent.mkdir(parents=True, exist_ok=True)
    if destino.exists():
        raise SystemExit(f"{destino} ya existe: bórralo o usa otro SPAINFACTS_DUCKDB para no mezclar datos.")

    con = duckdb.connect("md:")
    con.execute(f"ATTACH '{destino.as_posix()}' AS local_db")
    # COPY FROM DATABASE copia esquemas, tablas y vistas en una sola operación
    con.execute("COPY FROM DATABASE SpainFacts TO local_db")
    tablas = con.execute(
        "SELECT schema_name, count(*) FROM duckdb_tables() WHERE database_name = 'local_db' GROUP BY 1 ORDER BY 1"
    ).fetchall()
    con.close()
    print(f"Copiado a {destino}")
    for esquema, n in tablas:
        print(f"  {esquema}: {n} tablas")


if __name__ == "__main__":
    main()
