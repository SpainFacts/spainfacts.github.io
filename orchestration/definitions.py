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
from ingestion.alcaldes import alcaldes
from ingestion.almacenamiento import almacenamiento
from ingestion.bde import bde
from ingestion.conprel import conprel
from ingestion.criminalidad import criminalidad
from ingestion.clima import clima
from ingestion.demografia import demografia
from ingestion.educacion import educacion
from ingestion.elecciones import elecciones
from ingestion.internacional import internacional
from ingestion.transparencia_internacional import transparencia_internacional
from ingestion.transparencia_publicidad_activa import transparencia_publicidad_activa
from ingestion.vivienda_publica import vivienda_publica
from ingestion.medios_publicidad import medios_publicidad
from ingestion.medios_subvenciones import medios_subvenciones
from ingestion.medios_subvenciones_pv import medios_subvenciones_pv
from ingestion.medios_publicidad_territorial import medios_publicidad_territorial
from ingestion.medios_contratos import medios_contratos
from ingestion.medios_contratos_ccaa import medios_contratos_ccaa
from ingestion.primario import primario
from ingestion.industria import industria
from ingestion.construccion import construccion
from ingestion.diputados_inmuebles import diputados_inmuebles
from ingestion.medios_sector import medios_sector
from ingestion.medios_confianza import medios_confianza
from ingestion.medios_libertad import medios_libertad
from ingestion.mercado import mercado
from ingestion.pensiones import pensiones
from ingestion.renta import renta
from ingestion.sanidad import sanidad
from ingestion.gasto_oculto import gasto_oculto
from ingestion.sermas import sermas
from ingestion.educacion_privada import educacion_privada
from ingestion.sanidad_privada import sanidad_privada
from ingestion.turismo import turismo
from ingestion.vivienda import vivienda
from ingestion.hacienda_ccaa import hacienda_ccaa
from ingestion.hacienda_transparencia import hacienda_transparencia
from ingestion.transparencia_gobierno import transparencia_gobierno
from ingestion.destino import es_local
from ingestion.dgt import dgt
from ingestion.destino import pipeline as pipeline_destino
from ingestion.emisiones import emisiones
from ingestion.empleo_publico import empleo_publico
from ingestion.empresas import empresas
from ingestion.eurostat import eurostat
from ingestion.gem import gem
from ingestion.incendios import incendios
from ingestion.ine import ine
from ingestion.migracion import migracion
from ingestion.miteco import miteco
from ingestion.observatorios import observatorios
from ingestion.recarga import recarga
from ingestion.ree import ree
from ingestion.ree_visiona import ree_visiona

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


# Sistema eléctrico cada 5 minutos (visor de REE), precios y saldos por frontera
# (ESIOS, necesita ESIOS_TOKEN): incremental desde la última fecha cargada - 2 días.
@dlt_assets(dlt_source=ree_visiona(), dlt_pipeline=_pipeline_motherduck("ree_visiona"), name="ree_visiona", group_name="ingesta")
def ree_visiona_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
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


# Microdatos de la DGT: matriculaciones (se publican hacia el día 15) y parque
# (hacia el día 5, ~1,75 GB). Va en el diario porque, con la caché de agregados
# de data/dgt_cache/, solo vuelve a pedir los dos últimos meses de
# matriculaciones y descarga el parque una vez al mes, cuando aparece uno nuevo.
@dlt_assets(dlt_source=dgt(), dlt_pipeline=_pipeline_motherduck("dgt"), name="dgt", group_name="ingesta")
def dgt_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Almacenamiento (bombeo y baterías): balance REE, ESIOS (necesita ESIOS_TOKEN)
# y foto mensual de la capacidad de acceso de REE (solo está en línea la vigente).
@dlt_assets(dlt_source=almacenamiento(), dlt_pipeline=_pipeline_motherduck("almacenamiento"), name="almacenamiento", group_name="ingesta")
def almacenamiento_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Puntos de recarga eléctrica (NAP de la DGT / MITECO): foto diaria.
@dlt_assets(dlt_source=recarga(), dlt_pipeline=_pipeline_motherduck("recarga"), name="recarga", group_name="ingesta")
def recarga_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
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


# Centrales de Global Energy Monitor: lee el extracto de España versionado en
# ingestion/datos/ (se renueva a mano con cada edición del GIPT).
@dlt_assets(dlt_source=gem(), dlt_pipeline=_pipeline_motherduck("gem"), name="gem", group_name="ingesta_mensual")
def gem_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Alcaldes (Ministerio de Política Territorial): el actual cambia poco y el
# histórico nunca, así que basta con la carga mensual.
@dlt_assets(dlt_source=alcaldes(), dlt_pipeline=_pipeline_motherduck("alcaldes"), name="alcaldes", group_name="ingesta_mensual")
def alcaldes_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Liquidaciones de los ayuntamientos (Hacienda, CONPREL): ~290 Excel y 3 bases
# Access (~14 min) de un dato anual; va en el job mensual.
@dlt_assets(dlt_source=conprel(), dlt_pipeline=_pipeline_motherduck("conprel"), name="conprel", group_name="ingesta_mensual")
def conprel_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Transparencia (Hacienda): retenciones de la PIE (art. 36 Ley 2/2011, PDF y
# Excel mensuales) y periodo medio de pago de los ayuntamientos (trimestral).
@dlt_assets(
    dlt_source=hacienda_transparencia(),
    dlt_pipeline=_pipeline_motherduck("hacienda_transparencia"),
    name="hacienda_transparencia",
    group_name="ingesta_mensual",
)
def hacienda_transparencia_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Personal de las AAPP (Registro Central de Personal): ediciones semestrales
# (1 de enero y 1 de julio) publicadas meses después; basta con el job mensual.
@dlt_assets(
    dlt_source=empleo_publico(),
    dlt_pipeline=_pipeline_motherduck("empleo_publico"),
    name="empleo_publico",
    group_name="ingesta_mensual",
)
def empleo_publico_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Criminalidad (Ministerio del Interior): serie anual y Balance trimestral por
# municipio; basta con el job mensual.
@dlt_assets(dlt_source=criminalidad(), dlt_pipeline=_pipeline_motherduck("criminalidad"), name="criminalidad", group_name="ingesta_mensual")
def criminalidad_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Inmigración: llegadas irregulares (Interior vía ACNUR) y asilo (Eurostat).
@dlt_assets(dlt_source=migracion(), dlt_pipeline=_pipeline_motherduck("migracion"), name="migracion", group_name="ingesta_mensual")
def migracion_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# --- Temas añadidos en septiembre de 2026 (una fuente dlt por tema) --------

# Paro, IPC y precios de la energía: EPA, IPC (INE), paro registrado (SEPE),
# Eurostat y Boletín Petrolero de la Comisión Europea.
@dlt_assets(dlt_source=mercado(), dlt_pipeline=_pipeline_motherduck("mercado"), name="mercado", group_name="ingesta_mensual")
def mercado_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Vivienda: precios (INE, MIVAU), alquiler (SERPAVI), compraventas, hipotecas y obra nueva.
@dlt_assets(dlt_source=vivienda(), dlt_pipeline=_pipeline_motherduck("vivienda"), name="vivienda", group_name="ingesta_mensual")
def vivienda_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Pensiones contributivas y afiliación (Seguridad Social) y gasto en pensiones (Eurostat).
@dlt_assets(dlt_source=pensiones(), dlt_pipeline=_pipeline_motherduck("pensiones"), name="pensiones", group_name="ingesta_mensual")
def pensiones_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Renta, pobreza y desigualdad: INE ECV y Atlas de Distribución de Renta (ADRH, CSV ~350 MB) y Eurostat EU-SILC.
@dlt_assets(dlt_source=renta(), dlt_pipeline=_pipeline_motherduck("renta"), name="renta", group_name="ingesta_mensual")
def renta_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Educación: abandono, nivel educativo, NEET, gasto, alumnado y PISA (Eurostat).
@dlt_assets(dlt_source=educacion(), dlt_pipeline=_pipeline_motherduck("educacion"), name="educacion", group_name="ingesta_mensual")
def educacion_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Turismo: FRONTUR, EGATUR, ocupación hotelera y de apartamentos y viviendas turísticas (INE).
@dlt_assets(dlt_source=turismo(), dlt_pipeline=_pipeline_motherduck("turismo"), name="turismo", group_name="ingesta_mensual")
def turismo_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Demografía: natalidad, mortalidad, fecundidad, hogares y población por origen (INE, MNP/IDB/ECP).
@dlt_assets(dlt_source=demografia(), dlt_pipeline=_pipeline_motherduck("demografia"), name="demografia", group_name="ingesta_mensual")
def demografia_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Clima: inventario GEI desde 1990 (Eurostat), población (demo_gind) y series REE desde 2007.
@dlt_assets(dlt_source=clima(), dlt_pipeline=_pipeline_motherduck("clima"), name="clima", group_name="ingesta_mensual")
def clima_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Empresas: DIRCE, sociedades mercantiles, concursos, EPA por situación profesional (INE) e I+D, tamaño y quiebras (Eurostat).
@dlt_assets(dlt_source=empresas(), dlt_pipeline=_pipeline_motherduck("empresas"), name="empresas", group_name="ingesta_mensual")
def empresas_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Sistema sanitario: listas de espera SISLE-SNS (PDF semestrales) y gasto sanitario público (EGSP)
# del Ministerio de Sanidad, y recursos y gasto sanitario de Eurostat.
@dlt_assets(dlt_source=sanidad(), dlt_pipeline=_pipeline_motherduck("sanidad"), name="sanidad", group_name="ingesta_mensual")
def sanidad_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Lo que no sale en la cifra resumida: ejecución presupuestaria por concepto, modificaciones de crédito,
# convalidaciones de gasto y contratos menores (Comunidad de Madrid).
@dlt_assets(dlt_source=gasto_oculto(), dlt_pipeline=_pipeline_motherduck("gasto_oculto"), name="gasto_oculto", group_name="ingesta_mensual")
def gasto_oculto_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Servicio Madrileño de Salud: lista de espera real (con y sin cita) y libre elección, de sus memorias anuales.
@dlt_assets(dlt_source=sermas(), dlt_pipeline=_pipeline_motherduck("sermas"), name="sermas", group_name="ingesta_mensual")
def sermas_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Educación pública, concertada y privada por comunidad (EDUCAbase, SIIU y RUCT).
@dlt_assets(dlt_source=educacion_privada(), dlt_pipeline=_pipeline_motherduck("educacion_privada"), name="educacion_privada", group_name="ingesta_mensual")
def educacion_privada_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Sanidad pública y privada: EGSP por comunidad y clasificación (conciertos), Catálogo Nacional de
# Hospitales, cobertura sanitaria de las encuestas de salud del INE y gasto en sanidad de la EPF.
@dlt_assets(dlt_source=sanidad_privada(), dlt_pipeline=_pipeline_motherduck("sanidad_privada"), name="sanidad_privada", group_name="ingesta_mensual")
def sanidad_privada_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Resultados electorales oficiales (Interior, infoelectoral): Congreso, Municipales y Europeas.
# Al celebrarse unas elecciones nuevas hay que añadirlas a PROCESOS en ingestion/elecciones.py.
@dlt_assets(dlt_source=elecciones(), dlt_pipeline=_pipeline_motherduck("elecciones"), name="elecciones", group_name="ingesta_mensual")
def elecciones_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Comparativa internacional: Banco Mundial (WDI), deuda del FMI, Ember y ONU Turismo (OWID) y Eurostat,
# para España, Francia, Portugal, Alemania, Italia, Marruecos, EE. UU., China, UE y OCDE.
@dlt_assets(dlt_source=internacional(), dlt_pipeline=_pipeline_motherduck("internacional"), name="internacional", group_name="ingesta_mensual")
def internacional_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)

# Rendición de cuentas del Gobierno de España: decretos-ley (y su convalidación), leyes,
# presupuestos e indultos sacados de los sumarios diarios del BOE (carga incremental).
@dlt_assets(dlt_source=transparencia_gobierno(), dlt_pipeline=_pipeline_motherduck("transparencia_gobierno"), name="transparencia_gobierno", group_name="ingesta")
def transparencia_gobierno_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Índices internacionales de corrupción, integridad y gobierno abierto: CPI (Transparency International),
# WGI (Banco Mundial), V-Dem (vía OWID) y Rule of Law Index (World Justice Project), todos los países.
@dlt_assets(dlt_source=transparencia_internacional(), dlt_pipeline=_pipeline_motherduck("transparencia_internacional"), name="transparencia_internacional", group_name="ingesta_mensual")
def transparencia_internacional_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Evaluaciones oficiales de la publicidad activa con puntuación por entidad: Índice de Transparencia
# de Canarias (Comisionado de Transparencia de Canarias) e ICIO del CTBG (informes .docx).
@dlt_assets(dlt_source=transparencia_publicidad_activa(), dlt_pipeline=_pipeline_motherduck("transparencia_publicidad_activa"), name="transparencia_publicidad_activa", group_name="ingesta_mensual")
def transparencia_publicidad_activa_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Vivienda pública en alquiler: Boletín especial Vivienda Social del MIVAU (PDF), OCDE PH4.2 (XLSX)
# y régimen de tenencia de la ECV del INE por comunidad.
@dlt_assets(dlt_source=vivienda_publica(), dlt_pipeline=_pipeline_motherduck("vivienda_publica"), name="vivienda_publica", group_name="ingesta_mensual")
def vivienda_publica_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Publicidad institucional y comercial de la AGE (CSV de la Comisión de Publicidad
# y Comunicación Institucional, La Moncloa). Se actualiza una vez al año (junio).
@dlt_assets(dlt_source=medios_publicidad(), dlt_pipeline=_pipeline_motherduck("medios_publicidad"), name="medios_publicidad", group_name="ingesta_mensual")
def medios_publicidad_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Subvenciones a medios: concesiones BDNS de la lista curada (seed medios_subvenciones_convocatorias).
# Merge: la BDNS solo muestra 4 años, así que lo ya cargado se conserva.
@dlt_assets(dlt_source=medios_subvenciones(), dlt_pipeline=_pipeline_motherduck("medios_subvenciones"), name="medios_subvenciones", group_name="ingesta_mensual")
def medios_subvenciones_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Subvenciones del Gobierno Vasco a medios: resoluciones de concesión del BOPV (no publica en la BDNS).
# Merge por cod_concesion; valida que cada tabla cuadre con su total publicado.
@dlt_assets(dlt_source=medios_subvenciones_pv(), dlt_pipeline=_pipeline_motherduck("medios_subvenciones_pv"), name="medios_subvenciones_pv", group_name="ingesta_mensual")
def medios_subvenciones_pv_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Publicidad institucional de CCAA (Cataluña, CyL, Aragón, Navarra, Murcia) y de los
# Ayuntamientos de Madrid y Barcelona, por medio.
@dlt_assets(dlt_source=medios_publicidad_territorial(), dlt_pipeline=_pipeline_motherduck("medios_publicidad_territorial"), name="medios_publicidad_territorial", group_name="ingesta_mensual")
def medios_publicidad_territorial_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Contratos adjudicados a empresas de medios (PLACSP: perfiles, agregación y menores).
# Últimos 3 meses + mes en curso (ficheros mensuales), merge por expediente/órgano/lote/NIF.
@dlt_assets(dlt_source=medios_contratos(meses=3), dlt_pipeline=_pipeline_motherduck("medios_contratos"), name="medios_contratos", group_name="ingesta_mensual")
def medios_contratos_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Contratos menores a empresas de medios en las plataformas autonómicas que PLACSP no trae
# (Cataluña, Euskadi, Andalucía, Galicia, La Rioja, Ayuntamientos de Madrid y Barcelona).
# Caché persistente: sin ella, Galicia tarda unas 2 h en releerse cada mes.
@dlt_assets(dlt_source=medios_contratos_ccaa(cache_dir=str(REPO_ROOT / "data" / "medios_contratos_ccaa_cache")), dlt_pipeline=_pipeline_motherduck("medios_contratos_ccaa"), name="medios_contratos_ccaa", group_name="ingesta_mensual")
def medios_contratos_ccaa_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Sector primario: Eurostat (cultivos, ganadería, cuentas agrarias, pesca, VAB regional),
# Comext (exportaciones) y Agri-food data portal (aceite de oliva).
@dlt_assets(dlt_source=primario(), dlt_pipeline=_pipeline_motherduck("primario"), name="primario", group_name="ingesta_mensual")
def primario_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Industria frente a la UE: Eurostat (nama_10_a10, sbs_ovw_act, sts_inpr_a, nama_10r_3gva,
# Prodcom DS-059358, Comext DS-045409) e INE (IPI 70177/60282, EEE 76823).
@dlt_assets(dlt_source=industria(), dlt_pipeline=_pipeline_motherduck("industria"), name="industria", group_name="ingesta_mensual")
def industria_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Construcción (sector) frente a la UE: Eurostat (nama_10_a10/_e, sts_copr_a, sts_cobp_a, sts_copi_a,
# sbs_ovw_act, nama_10r_3gva, prc_hicp_aind), INE EPA (65354, 65331), Banco de España be23
# (visados, licitación, cemento), ISTAC (licitación y visados por CCAA) y Seguridad Social (afiliados F).
@dlt_assets(dlt_source=construccion(), dlt_pipeline=_pipeline_motherduck("construccion"), name="construccion", group_name="ingesta_mensual")
def construccion_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Diputados caseros: declaraciones de bienes del Congreso (extracto versionado, OCR en Windows) + AEAT IRPF.
@dlt_assets(dlt_source=diputados_inmuebles(), dlt_pipeline=_pipeline_motherduck("diputados_inmuebles"), name="diputados_inmuebles", group_name="ingesta_mensual")
def diputados_inmuebles_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Negocio de los medios: estadísticas estructurales de empresas de Eurostat (ramas J58-J63.91).
@dlt_assets(dlt_source=medios_sector(), dlt_pipeline=_pipeline_motherduck("medios_sector"), name="medios_sector", group_name="ingesta_mensual")
def medios_sector_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Confianza y consumo de noticias: Reuters Institute Digital News Report (páginas de país y
# gráficos Datawrapper) y Eurobarómetro Standard (anexos PDF). Datos anuales; carga ~20 min.
@dlt_assets(dlt_source=medios_confianza(), dlt_pipeline=_pipeline_motherduck("medios_confianza"), name="medios_confianza", group_name="ingesta_mensual")
def medios_confianza_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# Libertad de prensa y pluralismo: RSF, Media Pluralism Monitor (EUI), V-Dem (vía OWID) y alertas
# de la plataforma del Consejo de Europa para la protección del periodismo. Carga ~10 min.
@dlt_assets(dlt_source=medios_libertad(), dlt_pipeline=_pipeline_motherduck("medios_libertad"), name="medios_libertad", group_name="ingesta_mensual")
def medios_libertad_assets(context: AssetExecutionContext, dlt_resource: DagsterDltResource):
    yield from dlt_resource.run(context=context)


# --- Transformación: dbt --------------------------------------------------

dbt_project = DbtProject(project_dir=TRANSFORM_DIR)
dbt_project.prepare_if_dev()  # en dev genera target/manifest.json; en Docker lo hace el entrypoint


PIPELINE_POR_TEMA = {"clima", "demografia", "educacion", "elecciones", "empresas", "internacional", "mercado", "pensiones", "renta", "sanidad", "transparencia_gobierno", "turismo", "vivienda", "transparencia_internacional", "transparencia_publicidad_activa", "vivienda_publica", "medios_publicidad", "medios_subvenciones", "medios_publicidad_territorial", "medios_contratos", "primario", "industria", "construccion", "diputados_inmuebles", "medios_contratos_ccaa", "medios_sector", "medios_confianza", "medios_libertad", "medios_subvenciones_pv", "sanidad_privada", "educacion_privada", "sermas", "gasto_oculto"}


class _Translator(DagsterDbtTranslator):
    def get_asset_key(self, dbt_resource_props):
        # Conecta las sources de dbt (raw.*) con los assets dlt,
        # cuyo key por defecto es dlt_<source>_<recurso>.
        if dbt_resource_props["resource_type"] == "source":
            nombre = dbt_resource_props["name"]
            # Temas con fuente dlt propia: la source dbt raw_<tema> se carga con el pipeline <tema>
            tema = dbt_resource_props.get("source_name", "").removeprefix("raw_")
            if tema in PIPELINE_POR_TEMA:
                return AssetKey(f"dlt_{tema}_{nombre}")
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
    assets=[ine_assets, eurostat_assets, miteco_assets, observatorios_assets, incendios_assets, ree_assets, emisiones_assets, ree_visiona_assets, aemet_assets, bde_assets, dgt_assets, recarga_assets, almacenamiento_assets, hacienda_ccaa_assets, gem_assets, alcaldes_assets, conprel_assets, hacienda_transparencia_assets, empleo_publico_assets, criminalidad_assets, migracion_assets, mercado_assets, vivienda_assets, pensiones_assets, renta_assets, educacion_assets, turismo_assets, demografia_assets, clima_assets, empresas_assets, sanidad_assets, sanidad_privada_assets, educacion_privada_assets, elecciones_assets, internacional_assets, transparencia_gobierno_assets, transparencia_internacional_assets, transparencia_publicidad_activa_assets, vivienda_publica_assets, medios_publicidad_assets, medios_subvenciones_assets, medios_subvenciones_pv_assets, medios_publicidad_territorial_assets, medios_contratos_assets, medios_contratos_ccaa_assets, primario_assets, industria_assets, construccion_assets, diputados_inmuebles_assets, medios_sector_assets, medios_confianza_assets, medios_libertad_assets, sermas_assets, gasto_oculto_assets, transform_assets, deploy_web],
    jobs=[actualizacion_diaria, actualizacion_mensual],
    schedules=[schedule_diario, schedule_mensual],
    resources={
        "dlt_resource": DagsterDltResource(),
        "dbt": DbtCliResource(project_dir=str(TRANSFORM_DIR), profiles_dir=str(TRANSFORM_DIR)),
    },
)
