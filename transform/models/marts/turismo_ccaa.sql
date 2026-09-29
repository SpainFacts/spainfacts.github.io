-- Turismo por comunidad autónoma y año (INE), a partir de turismo_ccaa_mensual
-- más la fila 'otras' de FRONTUR/EGATUR (turistas y gasto del resto de
-- comunidades, que el INE no desglosa; su población = España menos las seis
-- comunidades desglosadas).
--   pernoct_1000hab: pernoctaciones en hoteles + apartamentos turísticos por
--     1.000 habitantes (población a 1 de enero); pct_extranjeros_hotel: % de
--     pernoctaciones hoteleras de no residentes en España.
--   ocupacion_hotel / ocupacion_apart: grado de ocupación por plazas del año =
--     media mensual ponderada por plazas x días.
--   turistas_por_hab y gasto_real_por_hab: turistas internacionales (FRONTUR) y
--     su gasto en euros constantes de anio_base (EGATUR) por habitante; solo
--     para las seis comunidades desglosadas, 'otras' y España.
-- meses_hotel / meses_frontur: meses con dato (el año en curso es parcial).
with m as (
    select *, cast(day(last_day(mes)) as integer) as dias from {{ ref('turismo_ccaa_mensual') }}
),

base_ipc as (
    select anio_base from {{ ref('deflactor') }} where anio = anio_base
),

anual as (
    select
        anio, cod_ccaa, max(comunidad) as comunidad, max(poblacion) as poblacion,
        count(pernoct_hotel) as meses_hotel,
        count(turistas) as meses_frontur,
        sum(pernoct_hotel) as pernoct_hotel,
        sum(pernoct_hotel_residentes) as pernoct_hotel_residentes,
        sum(pernoct_hotel_extranjeros) as pernoct_hotel_extranjeros,
        sum(pernoct_apart) as pernoct_apart,
        sum(ocupacion_hotel * plazas_hotel * dias) / sum(plazas_hotel * dias) as ocupacion_hotel,
        sum(ocupacion_apart * plazas_apart * dias) / sum(plazas_apart * dias) as ocupacion_apart,
        sum(turistas) as turistas,
        sum(gasto_real_meur) as gasto_real_meur
    from m
    group by anio, cod_ccaa
),

otras as (
    select
        cast(year(mes) as integer) as anio,
        count(distinct case when medida = 'turistas' then mes end) as meses_frontur,
        sum(case when medida = 'turistas' then valor end) as turistas,
        sum(case when medida = 'gasto_meur' then valor * factor_real end) as gasto_real_meur
    from {{ ref('turismo_series') }}
    where cod_ccaa = 'otras'
    group by 1
),

otras_pob as (
    select
        o.*,
        max(case when a.cod_ccaa = '00' then a.poblacion end)
          - sum(case when a.cod_ccaa in ('01', '04', '05', '09', '10', '13') then a.poblacion else 0 end) as poblacion
    from otras o
    join anual a on a.anio = o.anio
    group by all
),

unido as (
    select * from anual
    union all by name
    select anio, 'otras' as cod_ccaa, 'Resto de comunidades' as comunidad, poblacion, meses_frontur, turistas, gasto_real_meur
    from otras_pob
)

select
    u.anio, u.cod_ccaa, u.comunidad, t.ruta, u.poblacion, b.anio_base,
    u.meses_hotel, u.meses_frontur,
    u.pernoct_hotel, u.pernoct_hotel_residentes, u.pernoct_hotel_extranjeros, u.pernoct_apart,
    1000.0 * u.pernoct_hotel / u.poblacion as pernoct_hotel_1000hab,
    case when u.pernoct_hotel is not null then 1000.0 * (u.pernoct_hotel + coalesce(u.pernoct_apart, 0)) / u.poblacion end as pernoct_1000hab,
    100.0 * u.pernoct_hotel_extranjeros / u.pernoct_hotel as pct_extranjeros_hotel,
    u.ocupacion_hotel, u.ocupacion_apart,
    u.turistas,
    u.turistas / u.poblacion as turistas_por_hab,
    u.gasto_real_meur,
    1e6 * u.gasto_real_meur / u.poblacion as gasto_real_por_hab,
    1e6 * u.gasto_real_meur / u.turistas as gasto_medio_persona_real
from unido u
cross join base_ipc b
left join {{ ref('territorios') }} t on t.nivel = 'ccaa' and t.cod = u.cod_ccaa
order by u.anio, u.cod_ccaa
