-- Estructura por edades y origen de la población a 1 de enero, por año y
-- territorio (España 'pais', comunidad 'ccaa', provincia 'provincia'), desde 1971.
-- Fuentes (INE, Estadística Continua de Población):
--   * 56945 (vía demografia_edad_simple): población por provincia, sexo y edad
--     simple; las comunidades suman sus provincias.
--   * 56948 y 56947 (raw_demografia.ine_poblacion_origen_provincia): población
--     nacida en el extranjero y de nacionalidad extranjera, desde 2002.
-- Indicadores (definiciones de los Indicadores Demográficos Básicos del INE):
--   pct_menores_16, pct_65, pct_80 = % de la población con <16, 65+ y 80+ años.
--   dependencia        = (menores de 16 + mayores de 64) / población de 16 a 64 x 100.
--   dependencia_mayores = mayores de 64 / población de 16 a 64 x 100.
--   indice_envejecimiento = mayores de 64 / menores de 16 x 100.
--   edad_media         = media de (edad + 0,5); "100 y más" cuenta como 100,5 y, en
--                        los años antiguos sin detalle, "85 y más" como 90.
--   hombres_por_100_mujeres = ratio de masculinidad.
with provincias as (
    select cod_prov, cod_ccaa from {{ ref('territorios_provincias') }}
),

edades_prov as (
    select anio,
        case when cod = '00' then 'pais' else 'provincia' end as nivel,
        cod, sexo, edad,
        case when es_85_y_mas then 90 else edad + 0.5 end as edad_centro,
        poblacion
    from {{ ref('demografia_edad_simple') }}
),

edades as (
    select * from edades_prov
    union all
    select e.anio, 'ccaa', p.cod_ccaa, e.sexo, e.edad, e.edad_centro, sum(e.poblacion)
    from edades_prov e
    join provincias p on p.cod_prov = e.cod
    where e.nivel = 'provincia'
    group by all
),

resumen as (
    select anio, nivel, cod,
        sum(poblacion) filter (where sexo = 'Total') as poblacion,
        sum(poblacion) filter (where sexo = 'Total' and edad < 16) as menores_16,
        sum(poblacion) filter (where sexo = 'Total' and edad between 16 and 64) as de_16_a_64,
        sum(poblacion) filter (where sexo = 'Total' and edad >= 65) as mayores_65,
        sum(poblacion) filter (where sexo = 'Total' and edad >= 80) as mayores_80,
        sum(poblacion * edad_centro) filter (where sexo = 'Total') as suma_edades,
        sum(poblacion) filter (where sexo = 'Hombres') as hombres,
        sum(poblacion) filter (where sexo = 'Mujeres') as mujeres,
        sum(poblacion) filter (where sexo = 'Hombres' and edad >= 65) as hombres_65,
        sum(poblacion) filter (where sexo = 'Mujeres' and edad >= 65) as mujeres_65
    from edades
    group by all
),

origen_prov as (
    select cast(anio as integer) as anio,
        case when cod_prov = '00' then 'pais' else 'provincia' end as nivel,
        cod_prov as cod, criterio, origen, poblacion
    from {{ source('raw_demografia', 'ine_poblacion_origen_provincia') }}
    where edad = 'Todas las edades' and sexo = 'Total'
),

origen_todo as (
    select * from origen_prov
    union all
    select o.anio, 'ccaa', p.cod_ccaa, o.criterio, o.origen, sum(o.poblacion)
    from origen_prov o
    join provincias p on p.cod_prov = o.cod
    where o.nivel = 'provincia'
    group by all
),

origen as (
    select anio, nivel, cod,
        max(poblacion) filter (where criterio = 'nacimiento' and origen = 'Total') as poblacion_ecp,
        max(poblacion) filter (where criterio = 'nacimiento' and origen = 'Extranjero') as nacidos_extranjero,
        max(poblacion) filter (where criterio = 'nacionalidad' and origen = 'Extranjera') as extranjeros
    from origen_todo
    group by all
)

select
    r.anio,
    r.nivel,
    r.cod,
    t.nombre,
    r.poblacion,
    r.menores_16,
    r.mayores_65,
    r.mayores_80,
    100.0 * r.menores_16 / r.poblacion as pct_menores_16,
    100.0 * r.mayores_65 / r.poblacion as pct_65,
    100.0 * r.mayores_80 / r.poblacion as pct_80,
    100.0 * (r.menores_16 + r.mayores_65) / r.de_16_a_64 as dependencia,
    100.0 * r.mayores_65 / r.de_16_a_64 as dependencia_mayores,
    100.0 * r.mayores_65 / nullif(r.menores_16, 0) as indice_envejecimiento,
    r.suma_edades / r.poblacion as edad_media,
    100.0 * r.hombres / r.mujeres as hombres_por_100_mujeres,
    100.0 * r.hombres_65 / r.mujeres_65 as hombres_por_100_mujeres_65,
    o.nacidos_extranjero,
    100.0 * o.nacidos_extranjero / o.poblacion_ecp as pct_nacidos_extranjero,
    o.extranjeros,
    100.0 * o.extranjeros / o.poblacion_ecp as pct_extranjeros,
    r.nivel || '-' || r.cod || '-' || r.anio as clave
from resumen r
left join origen o on o.anio = r.anio and o.nivel = r.nivel and o.cod = r.cod
left join {{ ref('territorios') }} t on t.nivel = r.nivel and t.cod = r.cod
