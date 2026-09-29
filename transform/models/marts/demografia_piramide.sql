-- Pirámide de población a 1 de enero por año, territorio (España 'pais',
-- comunidad 'ccaa', provincia 'provincia'), sexo y grupo quinquenal de edad
-- (0-4 ... 80-84 y 85 y más), desde 1971. El último grupo es "85 y más" porque
-- hasta finales de los 80 el INE no da más detalle.
-- Fuentes (INE, Estadística Continua de Población):
--   * 56945 (vía demografia_edad_simple): población por provincia, sexo y edad simple,
--     agrupada en quinquenios; las comunidades suman sus provincias.
--   * 56948 (raw_demografia.ine_poblacion_origen_provincia): nacidos en el
--     extranjero por provincia, sexo y grupo quinquenal, desde 2002.
-- pct = % del grupo sobre la población total del territorio (ambos sexos), para
-- comparar pirámides de territorios de distinto tamaño.
with provincias as (
    select cod_prov, cod_ccaa from {{ ref('territorios_provincias') }}
),

prov as (
    select anio,
        case when cod = '00' then 'pais' else 'provincia' end as nivel,
        cod,
        sexo,
        cast(least(floor(edad / 5) * 5, 85) as integer) as edad_desde,
        sum(poblacion) as poblacion
    from {{ ref('demografia_edad_simple') }}
    where sexo in ('Hombres', 'Mujeres')
    group by all
),

origen_prov as (
    select cast(anio as integer) as anio,
        case when cod_prov = '00' then 'pais' else 'provincia' end as nivel,
        cod_prov as cod,
        sexo,
        cast(least(cast(regexp_extract(edad, '(\d+)', 1) as integer), 85) as integer) as edad_desde,
        sum(poblacion) as nacidos_extranjero
    from {{ source('raw_demografia', 'ine_poblacion_origen_provincia') }}
    where criterio = 'nacimiento' and origen = 'Extranjero'
      and edad <> 'Todas las edades' and sexo in ('Hombres', 'Mujeres')
    group by all
),

unido as (
    select p.anio, p.nivel, p.cod, p.sexo, p.edad_desde, p.poblacion, o.nacidos_extranjero
    from prov p
    left join origen_prov o using (anio, nivel, cod, sexo, edad_desde)
),

todo as (
    select * from unido
    union all
    select u.anio, 'ccaa', pr.cod_ccaa, u.sexo, u.edad_desde, sum(u.poblacion), sum(u.nacidos_extranjero)
    from unido u
    join provincias pr on pr.cod_prov = u.cod
    where u.nivel = 'provincia'
    group by all
)

select
    anio,
    nivel,
    cod,
    sexo,
    edad_desde,
    case when edad_desde = 85 then '85 y más' else edad_desde || '-' || (edad_desde + 4) end as grupo,
    poblacion,
    nacidos_extranjero,
    100.0 * poblacion / sum(poblacion) over (partition by anio, nivel, cod) as pct,
    100.0 * nacidos_extranjero / sum(poblacion) over (partition by anio, nivel, cod) as pct_nacidos_extranjero
from todo
