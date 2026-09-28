-- Defunciones semanales por comunidad y en España (INE, EDeS, tabla 35177) y
-- exceso sobre la media de la misma semana en 2015-2019 (antes de la COVID-19).
-- Es una referencia sencilla: no corrige por el envejecimiento ni por el
-- crecimiento de la población (que elevan las muertes esperadas año a año).
with base as (
    select
        cast(epoch_ms(fecha) + interval 12 hour as date) as semana,
        anyo as anio,
        split_part(serie, '. ', 1) as territorio,
        valor as defunciones
    from {{ source('raw', 'ine_defunciones_semanales') }}
    where serie like '%. Total. Todas las edades. Dato base.%' and valor is not null
),

con_cod as (
    select b.*, n.cod_ccaa as cod, cast(weekofyear(b.semana) as integer) as semana_anio
    from base b
    join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = b.territorio
),

referencia as (
    select cod, semana_anio, avg(defunciones) as media_2015_2019
    from con_cod
    where anio between 2015 and 2019
    group by all
)

select
    c.semana,
    c.anio,
    c.semana_anio,
    case when c.cod = '00' then 'pais' else 'ccaa' end as nivel,
    c.cod,
    c.defunciones,
    r.media_2015_2019,
    c.defunciones / nullif(r.media_2015_2019, 0) - 1 as exceso
from con_cod c
left join referencia r using (cod, semana_anio)
