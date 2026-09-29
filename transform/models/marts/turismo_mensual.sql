-- Turismo en España mes a mes (INE: FRONTUR 10822, EGATUR 10838, Coyuntura
-- Turística Hotelera 2074/2066 y apartamentos turísticos 1993/2021, vía
-- turismo_series). Por mes:
--   turistas internacionales llegados, gasto total (millones de euros
--   corrientes y constantes), gasto medio por turista y por día (euros
--   constantes), duración media, pernoctaciones en hoteles y apartamentos
--   turísticos por residencia, plazas y grado de ocupación por plazas.
-- Por habitante: población a 1 de enero del año (INE, poblacion_territorios;
-- para años sin dato se usa el último disponible).
-- Acumulados de 12 meses (solo cuando hay los 12 meses): turistas, gasto real,
-- pernoctaciones, y gasto en % del PIB nominal de los cuatro trimestres que
-- acaban en ese mes (Eurostat, economia_pib_trimestral B1GQ; solo en meses que
-- cierran trimestre).
-- Euros constantes: factor_real = IPC medio de anio_base / IPC del mes.
with s as (
    select * from {{ ref('turismo_series') }}
    where cod_ccaa = '00' and pais is null
),

piv as (
    select
        mes,
        max(anio_base) as anio_base,
        max(factor_real) as factor_real,
        max(case when operacion = 'frontur' and medida = 'turistas' then valor end) as turistas,
        max(case when operacion = 'egatur' and medida = 'gasto_meur' then valor end) as gasto_meur,
        max(case when operacion = 'egatur' and medida = 'gasto_medio_persona' then valor end) as gasto_medio_persona,
        max(case when operacion = 'egatur' and medida = 'gasto_medio_diario' then valor end) as gasto_medio_diario,
        max(case when operacion = 'egatur' and medida = 'duracion_media' then valor end) as duracion_media,
        max(case when operacion = 'eoh' and medida = 'pernoctaciones' and residencia = 'total' then valor end) as pernoct_hotel,
        max(case when operacion = 'eoh' and medida = 'pernoctaciones' and residencia = 'residentes' then valor end) as pernoct_hotel_residentes,
        max(case when operacion = 'eoh' and medida = 'pernoctaciones' and residencia = 'extranjeros' then valor end) as pernoct_hotel_extranjeros,
        max(case when operacion = 'eoh' and medida = 'viajeros' and residencia = 'total' then valor end) as viajeros_hotel,
        max(case when operacion = 'eoh' and medida = 'plazas' then valor end) as plazas_hotel,
        max(case when operacion = 'eoh' and medida = 'ocupacion_plazas' then valor end) as ocupacion_hotel,
        max(case when operacion = 'eoap' and medida = 'pernoctaciones' and residencia = 'total' then valor end) as pernoct_apart,
        max(case when operacion = 'eoap' and medida = 'pernoctaciones' and residencia = 'residentes' then valor end) as pernoct_apart_residentes,
        max(case when operacion = 'eoap' and medida = 'pernoctaciones' and residencia = 'extranjeros' then valor end) as pernoct_apart_extranjeros,
        max(case when operacion = 'eoap' and medida = 'plazas' then valor end) as plazas_apart,
        max(case when operacion = 'eoap' and medida = 'ocupacion_plazas' then valor end) as ocupacion_apart
    from s
    group by mes
),

pob as (
    select anio, poblacion from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and cod = '00' and sexo = 'Total'
),

pob_rango as (select min(anio) as a0, max(anio) as a1 from pob),

pib as (
    select
        cast(trimestre + interval 2 month as date) as mes,
        sum(nominal_meur) over (order by trimestre rows between 3 preceding and current row) as pib_4t,
        count(nominal_meur) over (order by trimestre rows between 3 preceding and current row) as n_trim
    from {{ ref('economia_pib_trimestral') }}
    where componente = 'B1GQ'
),

base as (
    select
        p.*,
        cast(year(p.mes) as integer) as anio,
        cast(month(p.mes) as integer) as mes_num,
        p.gasto_meur * p.factor_real as gasto_real_meur,
        p.gasto_medio_persona * p.factor_real as gasto_medio_persona_real,
        p.gasto_medio_diario * p.factor_real as gasto_medio_diario_real,
        po.poblacion
    from piv p
    cross join pob_rango r
    left join pob po on po.anio = greatest(least(year(p.mes), r.a1), r.a0)
),

acumulado as (
    select
        b.*,
        sum(turistas) over w as turistas_12m,
        count(turistas) over w as n_turistas_12m,
        sum(gasto_real_meur) over w as gasto_real_12m,
        sum(gasto_meur) over w as gasto_nominal_12m,
        count(gasto_meur) over w as n_gasto_12m,
        sum(pernoct_hotel) over w as pernoct_hotel_12m,
        count(pernoct_hotel) over w as n_hotel_12m,
        sum(pernoct_apart) over w as pernoct_apart_12m,
        count(pernoct_apart) over w as n_apart_12m,
        lag(turistas, 12) over (order by mes) as turistas_hace_un_anio,
        lag(gasto_real_meur, 12) over (order by mes) as gasto_real_hace_un_anio,
        lag(pernoct_hotel, 12) over (order by mes) as pernoct_hotel_hace_un_anio
    from base b
    window w as (order by mes range between interval 11 month preceding and current row)
)

select
    a.mes, a.anio, a.mes_num, a.anio_base, a.poblacion,
    a.turistas,
    1000.0 * a.turistas / a.poblacion as turistas_1000hab,
    100.0 * (a.turistas / nullif(a.turistas_hace_un_anio, 0) - 1) as turistas_interanual,
    a.gasto_meur, a.gasto_real_meur,
    100.0 * (a.gasto_real_meur / nullif(a.gasto_real_hace_un_anio, 0) - 1) as gasto_real_interanual,
    a.gasto_medio_persona, a.gasto_medio_persona_real,
    a.gasto_medio_diario, a.gasto_medio_diario_real,
    a.duracion_media,
    a.pernoct_hotel, a.pernoct_hotel_residentes, a.pernoct_hotel_extranjeros,
    1000.0 * a.pernoct_hotel / a.poblacion as pernoct_hotel_1000hab,
    100.0 * (a.pernoct_hotel / nullif(a.pernoct_hotel_hace_un_anio, 0) - 1) as pernoct_hotel_interanual,
    a.viajeros_hotel, a.plazas_hotel, a.ocupacion_hotel,
    a.pernoct_apart, a.pernoct_apart_residentes, a.pernoct_apart_extranjeros,
    1000.0 * a.pernoct_apart / a.poblacion as pernoct_apart_1000hab,
    a.plazas_apart, a.ocupacion_apart,
    case when a.n_turistas_12m = 12 then a.turistas_12m end as turistas_12m,
    case when a.n_turistas_12m = 12 then a.turistas_12m / a.poblacion end as turistas_por_hab_12m,
    case when a.n_gasto_12m = 12 then a.gasto_real_12m end as gasto_real_12m,
    case when a.n_gasto_12m = 12 then 1e6 * a.gasto_real_12m / a.poblacion end as gasto_real_por_hab_12m,
    case when a.n_gasto_12m = 12 and a.n_turistas_12m = 12 then 1e6 * a.gasto_real_12m / a.turistas_12m end as gasto_medio_persona_real_12m,
    case when a.n_gasto_12m = 12 and pib.n_trim = 4 then 100.0 * a.gasto_nominal_12m / pib.pib_4t end as gasto_pct_pib_12m,
    case when a.n_hotel_12m = 12 then a.pernoct_hotel_12m end as pernoct_hotel_12m,
    case when a.n_hotel_12m = 12 then 1000.0 * a.pernoct_hotel_12m / a.poblacion end as pernoct_hotel_1000hab_12m,
    case when a.n_apart_12m = 12 then 1000.0 * a.pernoct_apart_12m / a.poblacion end as pernoct_apart_1000hab_12m
from acumulado a
left join pib on pib.mes = a.mes
order by a.mes
