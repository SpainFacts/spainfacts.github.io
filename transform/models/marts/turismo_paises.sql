-- Turistas internacionales y su gasto por país de residencia y año (INE:
-- FRONTUR 10822, 15 países o grupos; EGATUR 10838, que solo desglosa Alemania,
-- Francia, Italia, Países Nórdicos, Reino Unido y "Resto del Mundo", así que el
-- gasto queda nulo para los demás). Suma de los meses del año; gasto en euros
-- constantes de anio_base (IPC del mes). cuota: % de los turistas del año;
-- turistas_2019: mismo país en 2019 (último año antes de la pandemia);
-- gasto_medio_persona_real: gasto real / turistas del país.
-- meses: meses con dato (el año en curso es parcial; la serie empieza en
-- octubre de 2015).
with s as (
    select * from {{ ref('turismo_series') }}
    where operacion in ('frontur', 'egatur') and cod_ccaa = '00'
),

anual as (
    select
        cast(year(mes) as integer) as anio,
        coalesce(pais, 'Total') as pais,
        max(anio_base) as anio_base,
        count(distinct case when medida = 'turistas' then mes end) as meses,
        sum(case when medida = 'turistas' then valor end) as turistas,
        -- "Resto del Mundo" de EGATUR agrupa todos los países no desglosados y no
        -- equivale al "Resto del Mundo" de FRONTUR: su gasto no se asigna.
        sum(case when medida = 'gasto_meur' and coalesce(pais, '') <> 'Resto del Mundo' then valor * factor_real end) as gasto_real_meur
    from s
    group by all
),

totales as (
    select anio, turistas as turistas_total from anual where pais = 'Total'
)

select
    a.anio, a.pais, a.anio_base, a.meses,
    a.turistas,
    100.0 * a.turistas / t.turistas_total as cuota,
    a.gasto_real_meur,
    1e6 * a.gasto_real_meur / a.turistas as gasto_medio_persona_real,
    b.turistas as turistas_2019,
    100.0 * (a.turistas / nullif(b.turistas, 0) - 1) as var_2019
from anual a
left join totales t on t.anio = a.anio
left join anual b on b.pais = a.pais and b.anio = 2019
order by a.anio, a.turistas desc
