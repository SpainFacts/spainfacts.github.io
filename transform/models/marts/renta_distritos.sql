-- Renta de los hogares por distrito censal (código de 7 dígitos: municipio +
-- distrito) y año, según el Atlas de Distribución de Renta de los Hogares del
-- INE (ADRH, tabla 30824; 2015-2023). Solo municipios con más de un distrito
-- (en los de uno solo el distrito coincide con el municipio). Importes reales
-- deflactados con el IPC medio del año (euros de anio_base).
with base as (
    select
        cod_mun,
        cod_distrito,
        max(distrito) as distrito,
        cast(anio as integer) as anio,
        max(valor) filter (where indicador = 'Renta neta media por persona') as renta_persona,
        max(valor) filter (where indicador = 'Renta neta media por hogar') as renta_hogar,
        max(valor) filter (where indicador = 'Mediana de la renta por unidad de consumo') as renta_uc_mediana
    from {{ source('raw_renta', 'ine_adrh_municipios') }}
    where nivel = 'distrito'
    group by cod_mun, cod_distrito, anio
),

varios as (
    select cod_mun from base group by cod_mun having count(distinct cod_distrito) > 1
)

select
    cast(b.cod_mun as varchar) as cod_mun,
    cast(b.cod_distrito as varchar) as cod_distrito,
    'Distrito ' || right(b.cod_distrito, 2) as distrito,
    b.anio,
    b.renta_persona * d.factor as renta_persona_real,
    b.renta_hogar * d.factor as renta_hogar_real,
    b.renta_uc_mediana * d.factor as renta_uc_mediana_real,
    d.anio_base
from base b
join varios v using (cod_mun)
left join {{ ref('deflactor') }} d on d.anio = b.anio
