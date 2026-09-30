-- Todas las series internacionales en formato largo (indicador_id, cod_pais,
-- anio, valor), con la fuente de cada fila. Del FMI solo años cerrados (el WEO
-- publica previsiones hasta cinco años vista). Las llegadas de turistas se
-- pasan a turistas por habitante con la población del Banco Mundial y el
-- consumo final de energía de Eurostat, a peso de la electricidad en él.
with bm as (
    select indicador_id, cod_indicador, cod_pais, cast(anio as integer) as anio, valor, 'bm' as origen
    from {{ source('raw_internacional', 'internacional_banco_mundial') }}
),

fmi as (
    select indicador_id, cod_indicador, cod_pais, cast(anio as integer) as anio, valor, 'fmi' as origen
    from {{ source('raw_internacional', 'internacional_fmi') }}
    where anio < extract(year from current_date)
),

owid as (
    select indicador_id, cod_indicador, cod_pais, cast(anio as integer) as anio, valor, 'owid' as origen
    from {{ source('raw_internacional', 'internacional_owid') }}
),

eurostat as (
    select indicador_id, cod_indicador, cod_pais, cast(anio as integer) as anio, valor, 'eurostat' as origen
    from {{ source('raw_internacional', 'internacional_eurostat') }}
),

aie as (
    select indicador_id, cod_indicador, cod_pais, cast(anio as integer) as anio, valor, 'aie' as origen
    from {{ source('raw_internacional', 'internacional_aie') }}
),

-- peso de la electricidad en el consumo final de energía (uso energético), en %
electrificacion as (
    select 'electrificacion' as indicador_id, 'nrg_bal_c (FC_E, E7000 / TOTAL)' as cod_indicador,
           e.cod_pais, e.anio, 100 * e.valor / t.valor as valor, 'eurostat' as origen
    from eurostat e
    join eurostat t on t.indicador_id = 'consumo_final_energia' and t.cod_pais = e.cod_pais and t.anio = e.anio
    where e.indicador_id = 'consumo_final_electricidad' and t.valor > 0
),

turistas as (
    select 'turistas_por_habitante' as indicador_id, t.cod_indicador, t.cod_pais, t.anio,
           t.valor / p.valor as valor, 'owid' as origen
    from owid t
    join bm p on p.indicador_id = 'poblacion' and p.cod_pais = t.cod_pais and p.anio = t.anio
    where t.indicador_id = 'turistas_llegadas'
)

select * from bm
union all select * from fmi
union all select * from owid where indicador_id <> 'turistas_llegadas'
union all select * from eurostat where indicador_id not in ('consumo_final_energia', 'consumo_final_electricidad')
union all select * from aie
union all select * from electrificacion
union all select * from turistas
