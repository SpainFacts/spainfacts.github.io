-- Turismo en España por año, a partir de turismo_mensual (INE: FRONTUR,
-- EGATUR, Coyuntura Turística Hotelera y apartamentos turísticos).
--   turistas_por_hab: turistas internacionales llegados en el año / población
--     a 1 de enero (INE).
--   gasto_real_meur: suma de los gastos mensuales en euros constantes de
--     anio_base; por habitante y por turista; gasto medio diario = gasto total /
--     (turistas x duración media) sumando mes a mes.
--   gasto_pct_pib: gasto nominal del año / PIB nominal del año (suma de los
--     cuatro trimestres, Eurostat); solo años completos.
--   pernoctaciones en hoteles y apartamentos por 1.000 habitantes y % de
--     no residentes; grado de ocupación anual por plazas = media de los grados
--     mensuales ponderada por plazas x días del mes.
-- meses_*: número de meses con dato (el año en curso es parcial; FRONTUR y
-- EGATUR empiezan en octubre de 2015).
with m as (
    select *, cast(day(last_day(mes)) as integer) as dias from {{ ref('turismo_mensual') }}
),

pib as (
    select anio, sum(nominal_meur) as pib_meur, count(*) as trimestres
    from {{ ref('economia_pib_trimestral') }}
    where componente = 'B1GQ'
    group by anio
),

anual as (
    select
        anio,
        max(anio_base) as anio_base,
        max(poblacion) as poblacion,
        count(turistas) as meses_frontur,
        count(gasto_meur) as meses_egatur,
        count(pernoct_hotel) as meses_hotel,
        count(pernoct_apart) as meses_apart,
        sum(turistas) as turistas,
        sum(gasto_meur) as gasto_meur,
        sum(gasto_real_meur) as gasto_real_meur,
        sum(turistas * duracion_media) as dias_turista,
        sum(pernoct_hotel) as pernoct_hotel,
        sum(pernoct_hotel_extranjeros) as pernoct_hotel_extranjeros,
        sum(pernoct_hotel_residentes) as pernoct_hotel_residentes,
        sum(pernoct_apart) as pernoct_apart,
        sum(pernoct_apart_extranjeros) as pernoct_apart_extranjeros,
        sum(ocupacion_hotel * plazas_hotel * dias) / sum(plazas_hotel * dias) as ocupacion_hotel,
        sum(ocupacion_apart * plazas_apart * dias) / sum(plazas_apart * dias) as ocupacion_apart
    from m
    group by anio
)

select
    a.anio, a.anio_base, a.poblacion,
    a.meses_frontur, a.meses_egatur, a.meses_hotel, a.meses_apart,
    a.turistas,
    a.turistas / a.poblacion as turistas_por_hab,
    a.gasto_meur, a.gasto_real_meur,
    1e6 * a.gasto_real_meur / a.poblacion as gasto_real_por_hab,
    1e6 * a.gasto_real_meur / a.turistas as gasto_medio_persona_real,
    1e6 * a.gasto_real_meur / a.dias_turista as gasto_medio_diario_real,
    a.dias_turista / a.turistas as duracion_media,
    case when p.trimestres = 4 and a.meses_egatur = 12 then 100.0 * a.gasto_meur / p.pib_meur end as gasto_pct_pib,
    a.pernoct_hotel, a.pernoct_hotel_residentes, a.pernoct_hotel_extranjeros,
    1000.0 * a.pernoct_hotel / a.poblacion as pernoct_hotel_1000hab,
    100.0 * a.pernoct_hotel_extranjeros / a.pernoct_hotel as pct_extranjeros_hotel,
    a.pernoct_apart, a.pernoct_apart_extranjeros,
    1000.0 * a.pernoct_apart / a.poblacion as pernoct_apart_1000hab,
    100.0 * a.pernoct_apart_extranjeros / a.pernoct_apart as pct_extranjeros_apart,
    a.ocupacion_hotel, a.ocupacion_apart
from anual a
left join pib p on p.anio = a.anio
order by a.anio
