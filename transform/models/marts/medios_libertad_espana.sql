-- España en los índices de libertad de prensa y pluralismo: una fila por índice y año,
-- con el valor de España, su puesto entre los 27 países que hoy forman la UE y, cuando la
-- licencia permite calcularla, la media simple de la UE (valor_ue).
-- Reúne los marts medios_libertad_rsf (puesto mundial y puntuación desde 2022; RSF sin
-- licencia abierta: sin media UE), medios_libertad_vdem, medios_libertad_mpm (riesgo por
-- área; anio = edición del MPM) y medios_libertad_coe_alertas (alertas por 10 millones
-- de habitantes). sentido: 'positivo' si un valor mayor es mejor, 'negativo' si es peor.
with rsf as (
    select 'rsf_puesto' as indice_id, 'Puesto en la Clasificación Mundial de la Libertad de Prensa (RSF)' as nombre,
           'puesto mundial (1 = mejor)' as unidad, 'negativo' as sentido, 'Reporters sans frontières' as fuente,
           1 as orden, edicion as anio, cast(puesto_mundial as double) as valor, n_paises as n_total,
           puesto_ue, n_ue, cast(null as double) as valor_ue
    from {{ ref('medios_libertad_rsf') }}
    where cod_pais = 'ES' and indicador = 'global'
    union all
    select 'rsf_' || indicador, 'RSF: ' || lower(nombre_indicador) || ' (puntuación, desde 2022)',
           'puntos 0-100 (100 = mejor)', 'positivo', 'Reporters sans frontières',
           1 + orden_indicador, edicion, puntuacion, n_paises, puesto_ue, n_ue, null
    from {{ ref('medios_libertad_rsf') }}
    where cod_pais = 'ES' and escala = '2022'
),

vdem as (
    select e.indicador_id, e.nombre, e.unidad, 'positivo', 'V-Dem', 10 + e.orden_indicador, e.anio, e.valor,
           null, e.puesto_ue, e.n_ue, u.valor
    from {{ ref('medios_libertad_vdem') }} e
    left join {{ ref('medios_libertad_vdem') }} u
        on u.indicador_id = e.indicador_id and u.anio = e.anio and u.cod_pais = 'EU27_2020'
    where e.cod_pais = 'ES'
),

mpm as (
    select 'mpm_' || e.area, 'Media Pluralism Monitor: ' || lower(e.nombre_area), 'riesgo % (0 = sin riesgo)', 'negativo',
           'Media Pluralism Monitor (EUI-CMPF)', 20 + e.orden_area, e.edicion, e.riesgo_pct, null, e.puesto_ue, e.n_ue, u.riesgo_pct
    from {{ ref('medios_libertad_mpm') }} e
    left join {{ ref('medios_libertad_mpm') }} u
        on u.area = e.area and u.edicion = e.edicion and u.cod_pais = 'EU27_2020'
    where e.cod_pais = 'ES'
),

coe as (
    select 'coe_alertas', 'Alertas de la Plataforma del Consejo de Europa por 10 millones de habitantes', 'alertas por 10 millones de hab.',
           'negativo', 'Consejo de Europa', 30, e.anio, e.alertas_por_10m_hab, e.alertas, e.puesto_ue, e.n_ue, u.alertas_por_10m_hab
    from {{ ref('medios_libertad_coe_alertas') }} e
    left join {{ ref('medios_libertad_coe_alertas') }} u on u.anio = e.anio and u.cod_pais = 'EU27_2020'
    where e.cod_pais = 'ES' and not e.parcial
)

select
    indice_id,
    nombre,
    unidad,
    sentido,
    fuente,
    orden,
    cast(anio as integer) as anio,
    round(valor, 3) as valor,
    cast(n_total as integer) as n_total,
    cast(puesto_ue as integer) as puesto_ue,
    cast(n_ue as integer) as n_ue,
    round(valor_ue, 3) as valor_ue
from (
    select * from rsf
    union all select * from vdem
    union all select * from mpm
    union all select * from coe
)
