-- Índices internacionales de transparencia e integridad en formato largo
-- (indicador_id, cod_pais, anio, valor), todos los países. V-Dem desde 1970.
with cpi as (
    select 'cpi' as indicador_id, cod_pais, cast(anio as integer) as anio, cast(valor as double) as valor,
           -- CC BY-ND: no se calcula intervalo propio a partir del error estándar
           cast(null as double) as valor_min,
           cast(null as double) as valor_max,
           cast(puesto as integer) as puesto_mundial
    from {{ source('raw_transparencia_internacional', 'transparencia_int_cpi') }}
),

wgi as (
    select indicador_id, cod_pais, cast(anio as integer), cast(valor as double),
           cast(valor_min as double), cast(valor_max as double), cast(null as integer)
    from {{ source('raw_transparencia_internacional', 'transparencia_int_wgi') }}
),

vdem as (
    select indicador_id, cod_pais, cast(anio as integer), cast(valor as double),
           cast(null as double), cast(null as double), cast(null as integer)
    from {{ source('raw_transparencia_internacional', 'transparencia_int_vdem') }}
    where anio >= 1970
),

wjp as (
    select indicador_id, cod_pais, cast(anio as integer), cast(valor as double),
           cast(null as double), cast(null as double), cast(null as integer)
    from {{ source('raw_transparencia_internacional', 'transparencia_int_wjp') }}
)

select * from cpi
union all select * from wgi
union all select * from vdem
union all select * from wjp
