"""Definiciones Dagster: ingesta dlt -> dbt -> disparo del deploy de Evidence.

Grafo de assets:
  raw (dlt: INE) -> staging/marts (dbt) -> deploy_web (repository_dispatch)

Variables de entorno necesarias (ver .env.example):
  MOTHERDUCK_TOKEN        token read_write para dlt y dbt
  GITHUB_DISPATCH_TOKEN   PAT fine-grained con permiso Actions sobre el repo
"""

import os
from pathlib import Path

import dlt
import requests
from dagster import (
    AssetExecutionContext,
    AssetKey,
    AssetSelection,
    Definitions,
    ScheduleDefinition,
    asset,
    define_asset_job,
)
from dagster_dbt import DagsterDbtTranslator, DbtCliResource, DbtProject, dbt_assets
from dagster_dlt import DagsterDltResource, dlt_assets

from ingestion.aemet import aemet
from ingestion.bde import bde
from ingestion.hacienda_ccaa import hacienda_ccaa
from ingestion.destino import es_local
from ingestion.destino import pipeline as pipeline_destino
from ingestion.emisiones import emisiones
from ingestion.eurostat import eurostat
from ingestion.incendios import incendios
from ingestion.ine import ine
from ingestion.miteco import miteco
from ingestion.observatorios import observatorios
from ingestion.ree import ree

REPO_ROOT = Path(__file__).resolve().parent.parent
TRANSFORM_DIR = REPO_ROOT / "transform"

# --- Ingesta: dlt --------------------------------------------------------


def _pipeline_motherduck(nombre: str) -> dlt.Pipeline:
    # El nombre se mantiene por compatibilidad: el destino real (MotherDuck o
    # DuckDB local) lo decide SPAINFACTS_DESTINO, ver ingestion/destino.py.
    return pipeline_destino(nombre)


@dlt_assets(dlt_source=ine(), dlt_pipeline=_pipeline_motherduck("ine"), name="ine", group_name="ingesta")
def ine_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


@dlt_assets(
    dlt_source=eurostat(),
    dlt_pipeline=_pipeline_motherduck("eurostat"),
    name="eurostat",
    group_name="ingesta",
)
def eurostat_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


@dlt_assets(dlt_source=miteco(), dlt_pipeline=_pipeline_motherduck("miteco"), name="miteco", group_name="ingesta")
def miteco_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


@dlt_assets(
    dlt_source=observatorios(),
    dlt_pipeline=_pipeline_motherduck("observatorios"),
    name="observatorios",
    group_name="ingesta",
)
def observatorios_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


@dlt_assets(
    dlt_source=incendios(),
    dlt_pipeline=_pipeline_motherduck("incendios"),
    name="incendios",
    group_name="ingesta",
)
def incendios_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


@dlt_assets(dlt_source=ree(), dlt_pipeline=_pipeline_motherduck("ree"), name="ree", group_name="ingesta")
def ree_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


@dlt_assets(
    dlt_source=emisiones(),
    dlt_pipeline=_pipeline_motherduck("emisiones"),
    name="emisiones",
    group_name="ingesta",
)
def emisiones_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Incremental: dlt guarda en el destino la última fecha cargada y cada día
# vuelve a pedir los 20 días anteriores. Un destino vacío (p. ej. un DuckDB
# local nuevo) dispara el backfill desde 1991 (~1 h): ver docs/desarrollo-local.md.
@dlt_assets(dlt_source=aemet(), dlt_pipeline=_pipeline_motherduck("aemet"), name="aemet", group_name="ingesta")
def aemet_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


@dlt_assets(dlt_source=bde(), dlt_pipeline=_pipeline_motherduck("bde"), name="bde", group_name="ingesta")
def bde_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Liquidaciones de las CCAA (Hacienda): ~920 descargas lentas (~45 min) de un
# dato anual, así que va en un job mensual propio y no en el diario.
@dlt_assets(
    dlt_source=hacienda_ccaa(),
    dlt_pipeline=_pipeline_motherduck("hacienda_ccaa"),
    name="hacienda_ccaa",
    group_name="ingesta_mensual",
)
def hacienda_ccaa_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# --- Transformación: dbt --------------------------------------------------

dbt_project = DbtProject(project_dir=TRANSFORM_DIR)
dbt_project.prepare_if_dev()  # en dev genera target/manifest.json; en Docker lo hace el entrypoint


class _Translator(DagsterDbtTranslator):
    def get_asset_key(self, dbt_resource_props):
        # Conecta las sources de dbt (raw.*) con los assets dlt,
        # cuyo key por defecto es dlt_<source>_<recurso>.
        if dbt_resource_props["resource_type"] == "source":
            nombre = dbt_resource_props["name"]
            fuente = "ine" if nombre.startswith("ine_") else "eurostat"
            return AssetKey(f"dlt_{fuente}_{nombre}")
        return super().get_asset_key(dbt_resource_props)


@dbt_assets(manifest=dbt_project.manifest_path, dagster_dbt_translator=_Translator())
def transform_assets(context: AssetExecutionContext, dbt: DbtCliResource):
    # `build` = run + test: si un test falla, el asset falla y no se publica la web
    yield from dbt.cli(["build"], context=context).stream()


# --- Publicación: disparar el deploy de Evidence en GitHub Actions --------

@asset(deps=[transform_assets], group_name="publicacion")
def deploy_web(context: AssetExecutionContext):
    """Lanza el workflow deploy.yml vía repository_dispatch (event: data-updated)."""
    if es_local():
        context.log.info("SPAINFACTS_DESTINO=local: no se dispara el deploy (la web publicada lee de MotherDuck).")
        return
    respuesta = requests.post(
        "https://api.github.com/repos/SpainFacts/spainfacts.github.io/dispatches",
        headers={
            "Authorization": f"Bearer {os.environ['GITHUB_DISPATCH_TOKEN']}",
            "Accept": "application/vnd.github+json",
        },
        json={"event_type": "data-updated"},
        timeout=30,
    )
    respuesta.raise_for_status()
    context.log.info("Deploy de Evidence disparado en GitHub Actions.")


# --- Job y schedule -------------------------------------------------------

# El diario lo refresca todo salvo las fuentes lentas de dato anual (grupo
# ingesta_mensual); dbt y el deploy van en los dos jobs.
actualizacion_diaria = define_asset_job(
    "actualizacion_diaria", selection=AssetSelection.all() - AssetSelection.groups("ingesta_mensual")
)

actualizacion_mensual = define_asset_job(
    "actualizacion_mensual",
    selection=AssetSelection.groups("ingesta_mensual") | AssetSelection.assets(transform_assets, deploy_web),
)

schedule_diario = ScheduleDefinition(
    job=actualizacion_diaria,
    cron_schedule="0 6 * * *",
    execution_timezone="Europe/Madrid",
)

schedule_mensual = ScheduleDefinition(
    job=actualizacion_mensual,
    cron_schedule="0 3 2 * *",  # día 2 de cada mes, antes del diario
    execution_timezone="Europe/Madrid",
)

defs = Definitions(
    assets=[ine_assets, eurostat_assets, miteco_assets, observatorios_assets, incendios_assets, ree_assets, emisiones_assets, aemet_assets, bde_assets, hacienda_ccaa_assets, transform_assets, deploy_web],
    jobs=[actualizacion_diaria, actualizacion_mensual],
    schedules=[schedule_diario, schedule_mensual],
    resources={
        "dlt_resource": DagsterDltResource(),
        "dbt": DbtCliResource(project_dir=str(TRANSFORM_DIR), profiles_dir=str(TRANSFORM_DIR)),
    },
)
