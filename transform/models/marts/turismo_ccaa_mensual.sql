-- Turismo por comunidad autónoma y mes (INE, vía turismo_series):
--   pernoctaciones en hoteles (Coyuntura Turística Hotelera, tabla 2074) por
--   residencia, plazas y grado de ocupación por plazas (2066); pernoctaciones,
--   plazas y ocupación en apartamentos turísticos (1993, 2021; sin Ceuta ni
--   Melilla); turistas internacionales (FRONTUR 10823) y su gasto en euros
--   constantes (EGATUR 10839), que el INE solo da para Andalucía, Baleares,
--   Canarias, Cataluña, Comunitat Valenciana y Madrid.
-- cod_ccaa = código INE ('00' = España). Por 1.000 habitantes con la población
-- a 1 de enero del año (último disponible para años sin dato).
with s as (
    select * from {{ ref('turismo_series') }}
    where pais is null and cod_ccaa <> 'otras'
),

piv as (
    select
        mes, cod_ccaa,
        max(case when operacion = 'eoh' and medida = 'pernoctaciones' and residencia = 'total' then valor end) as pernoct_hotel,
        max(case when operacion = 'eoh' and medida = 'pernoctaciones' and residencia = 'residentes' then valor end) as pernoct_hotel_residentes,
        max(case when operacion = 'eoh' and medida = 'pernoctaciones' and residencia = 'extranjeros' then valor end) as pernoct_hotel_extranjeros,
        max(case when operacion = 'eoh' and medida = 'plazas' then valor end) as plazas_hotel,
        max(case when operacion = 'eoh' and medida = 'ocupacion_plazas' then valor end) as ocupacion_hotel,
        max(case when operacion = 'eoap' and medida = 'pernoctaciones' and residencia = 'total' then valor end) as pernoct_apart,
        max(case when operacion = 'eoap' and medida = 'pernoctaciones' and residencia = 'extranjeros' then valor end) as pernoct_apart_extranjeros,
        max(case when operacion = 'eoap' and medida = 'plazas' then valor end) as plazas_apart,
        max(case when operacion = 'eoap' and medida = 'ocupacion_plazas' then valor end) as ocupacion_apart,
        max(case when operacion = 'frontur' then valor end) as turistas,
        max(case when operacion = 'egatur' and medida = 'gasto_meur' then valor * factor_real end) as gasto_real_meur
    from s
    group by all
),

pob as (
    select cod, anio, poblacion from {{ ref('poblacion_territorios') }}
    where nivel in ('pais', 'ccaa') and sexo = 'Total'
),

pob_rango as (select min(anio) as a0, max(anio) as a1 from pob)

select
    p.mes,
    cast(year(p.mes) as integer) as anio,
    cast(month(p.mes) as integer) as mes_num,
    p.cod_ccaa,
    t.nombre as comunidad,
    po.poblacion,
    p.pernoct_hotel, p.pernoct_hotel_residentes, p.pernoct_hotel_extranjeros,
    p.plazas_hotel, p.ocupacion_hotel,
    p.pernoct_apart, p.pernoct_apart_extranjeros, p.plazas_apart, p.ocupacion_apart,
    1000.0 * p.pernoct_hotel / po.poblacion as pernoct_hotel_1000hab,
    1000.0 * (coalesce(p.pernoct_hotel, 0) + coalesce(p.pernoct_apart, 0)) / po.poblacion as pernoct_1000hab,
    p.turistas,
    1000.0 * p.turistas / po.poblacion as turistas_1000hab,
    p.gasto_real_meur
from piv p
cross join pob_rango r
left join pob po on po.cod = p.cod_ccaa and po.anio = greatest(least(year(p.mes), r.a1), r.a0)
left join {{ ref('territorios') }} t on t.cod = p.cod_ccaa and t.nivel = case when p.cod_ccaa = '00' then 'pais' else 'ccaa' end
order by p.mes, p.cod_ccaa
