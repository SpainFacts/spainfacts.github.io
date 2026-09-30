-- Todas las series internacionales en formato largo (indicador_id, cod_pais,
-- anio, valor), con la fuente de cada fila. Del FMI solo años cerrados (el WEO
-- publica previsiones hasta cinco años vista). Las llegadas de turistas se
-- pasan a turistas por habitante con la población del Banco Mundial.
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
union all select * from eurostat
union all select * from turistas
