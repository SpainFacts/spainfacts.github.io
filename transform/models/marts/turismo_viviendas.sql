-- Viviendas de uso turístico por territorio y periodo (INE, medición
-- experimental "Viviendas turísticas en España" a partir de los anuncios de
-- las plataformas digitales; tablas 39363 y 39366). Semestral desde agosto de
-- 2020 (febrero/agosto hasta 2024; mayo/noviembre desde noviembre de 2024, así
-- que las comparaciones se hacen con el mismo mes del año anterior).
-- Niveles: pais ('00'), ccaa y provincia (códigos INE; cod_ccaa de la
-- provincia sale de territorios). Por territorio:
--   viviendas turísticas, plazas y % de viviendas turísticas sobre el total de
--   viviendas censadas (dato del INE);
--   viviendas_1000hab: viviendas turísticas por 1.000 habitantes (población a
--   1 de enero del año del periodo, último año disponible si no lo hay);
--   viviendas_hace_un_anio: mismo mes del año anterior, si se publicó.
with v as (
    select
        nivel, cod, cast(periodo as date) as periodo,
        max(case when medida = 'Viviendas turísticas' then valor end) as viviendas,
        max(case when medida = 'Plazas' then valor end) as plazas
    from {{ source('raw_turismo', 'ine_vut_viviendas') }}
    where nivel in ('pais', 'ccaa', 'provincia')
    group by all
),

pct as (
    select nivel, cod, cast(periodo as date) as periodo, valor as pct_viviendas
    from {{ source('raw_turismo', 'ine_vut_porcentaje') }}
    where nivel in ('pais', 'ccaa', 'provincia')
),

pob as (
    select nivel, cod, anio, poblacion from {{ ref('poblacion_territorios') }}
    where sexo = 'Total'
),

pob_rango as (select min(anio) as a0, max(anio) as a1 from pob)

select
    v.periodo,
    cast(year(v.periodo) as integer) as anio,
    v.nivel, v.cod,
    case when v.nivel = 'provincia' then t.cod_ccaa when v.nivel = 'ccaa' then v.cod end as cod_ccaa,
    t.nombre, t.ruta,
    v.viviendas, v.plazas, p.pct_viviendas,
    po.poblacion,
    1000.0 * v.viviendas / po.poblacion as viviendas_1000hab,
    prev.viviendas as viviendas_hace_un_anio,
    100.0 * (v.viviendas / nullif(prev.viviendas, 0) - 1) as var_interanual
from v
cross join pob_rango r
left join pct p on p.nivel = v.nivel and p.cod = v.cod and p.periodo = v.periodo
left join pob po on po.nivel = v.nivel and po.cod = v.cod and po.anio = greatest(least(year(v.periodo), r.a1), r.a0)
left join {{ ref('territorios') }} t on t.nivel = v.nivel and t.cod = v.cod
left join v prev on prev.nivel = v.nivel and prev.cod = v.cod and prev.periodo = v.periodo - interval 1 year
order by v.periodo, v.nivel, v.cod
