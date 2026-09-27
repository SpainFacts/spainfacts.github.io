"""Destino de las cargas dlt: MotherDuck (producción) o un DuckDB local.

Se elige con la variable de entorno SPAINFACTS_DESTINO:
  motherduck (por defecto)  md:SpainFacts, requiere MOTHERDUCK_TOKEN
  local                     fichero DuckDB en SPAINFACTS_DUCKDB
                            (por defecto <repo>/data/spainfacts.duckdb)

dbt (transform/profiles.yml) y Evidence (sources/mother/connection.yaml)
leen las mismas variables, así que toda la cadena apunta al mismo sitio.
Ver docs/desarrollo-local.md.
"""

import os
from pathlib import Path

import dlt

REPO_ROOT = Path(__file__).resolve().parent.parent
DUCKDB_LOCAL_POR_DEFECTO = REPO_ROOT / "data" / "spainfacts.duckdb"


def es_local() -> bool:
    return os.environ.get("SPAINFACTS_DESTINO", "motherduck").strip().lower() == "local"


def ruta_duckdb_local() -> Path:
    return Path(os.environ.get("SPAINFACTS_DUCKDB") or DUCKDB_LOCAL_POR_DEFECTO).resolve()


# dbt (lanzado por Dagster como subproceso) lee SPAINFACTS_DUCKDB del entorno:
# se fija aquí la ruta absoluta para que dlt y dbt usen exactamente el mismo fichero.
if es_local():
    os.environ.setdefault("SPAINFACTS_DUCKDB", str(ruta_duckdb_local()))


def destino():
    if es_local():
        ruta = ruta_duckdb_local()
        ruta.parent.mkdir(parents=True, exist_ok=True)
        return dlt.destinations.duckdb(credentials=str(ruta))
    return dlt.destinations.motherduck(
        credentials=f"md:///SpainFacts?motherduck_token={os.environ.get('MOTHERDUCK_TOKEN', '')}"
    )


def pipeline(nombre: str) -> dlt.Pipeline:
    """Pipeline dlt que escribe en el esquema `raw` del destino activo."""
    return dlt.pipeline(pipeline_name=nombre, destination=destino(), dataset_name="raw")
