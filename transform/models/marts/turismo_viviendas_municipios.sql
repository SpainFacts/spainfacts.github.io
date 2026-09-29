-- Viviendas de uso turístico por municipio y periodo (INE, medición
-- experimental "Viviendas turísticas en España", tablas 39363 y 39366;
-- semestral desde agosto de 2020). El INE solo publica los municipios con
-- alguna vivienda turística detectada (unos 8.100). Por municipio (cod_mun =
-- código INE de 5 dígitos):
--   viviendas turísticas, plazas, % sobre las viviendas censadas (dato INE) y
--   viviendas por 1.000 habitantes (padrón del año del periodo; último año
--   disponible si no lo hay);
--   puesto: posición en España por % de viviendas turísticas en ese periodo
--   (solo municipios de 1.000 habitantes o más, para no premiar aldeas).
with v as (
    select
        cod as cod_mun, cast(periodo as date) as periodo,
        max(case when medida = 'Viviendas turísticas' then valor end) as viviendas,
        max(case when medida = 'Plazas' then valor end) as plazas
    from {{ source('raw_turismo', 'ine_vut_viviendas') }}
    where nivel = 'municipio'
    group by all
),

pct as (
    select cod as cod_mun, cast(periodo as date) as periodo, valor as pct_viviendas
    from {{ source('raw_turismo', 'ine_vut_porcentaje') }}
    where nivel = 'municipio'
),

pob as (
    select cod_mun, anio, poblacion, cod_prov, cod_ccaa, municipio
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
),

pob_rango as (select min(anio) as a0, max(anio) as a1 from pob),

unido as (
    select
        v.periodo,
        cast(year(v.periodo) as integer) as anio,
        v.cod_mun,
        po.municipio,
        left(v.cod_mun, 2) as cod_prov,
        po.cod_ccaa,
        v.viviendas, v.plazas, p.pct_viviendas,
        po.poblacion,
        1000.0 * v.viviendas / nullif(po.poblacion, 0) as viviendas_1000hab
    from v
    cross join pob_rango r
    left join pct p on p.cod_mun = v.cod_mun and p.periodo = v.periodo
    left join pob po on po.cod_mun = v.cod_mun and po.anio = greatest(least(year(v.periodo), r.a1), r.a0)
)

select
    *,
    case when poblacion >= 1000 then
        rank() over (partition by periodo, poblacion >= 1000 order by pct_viviendas desc nulls last)
    end as puesto
from unido
order by periodo, cod_mun
