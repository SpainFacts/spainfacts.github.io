#!/bin/sh
set -e

# Genera transform/target/manifest.json, que dagster-dbt necesita al importar
# las definiciones. `dbt parse` no conecta con MotherDuck, pero el profile
# evalúa env_var('MOTHERDUCK_TOKEN'), así que debe existir en el entorno.
dbt parse --project-dir /opt/spainfacts/transform --profiles-dir /opt/spainfacts/transform

exec "$@"
