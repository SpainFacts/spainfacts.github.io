-- Paro registrado en las oficinas de empleo (SEPE), mensual desde 2006, por
-- provincia, comunidad y España, en relación con la población de 16 a 64 años.
--   paro_registrado: demandantes de empleo parados el último día del mes
--     (suma de los municipios; las cifras ocultas "<5" cuentan como 2).
--   poblacion_16_64: población de 16 a 64 años a 1 de enero del año (INE,
--     Estadística Continua de Población, tabla 56945; para los años aún no
--     publicados se usa el último disponible).
--   por_100_16_64: parados registrados por cada 100 habitantes de 16 a 64
--     años. No es la tasa de paro de la EPA (que divide entre la población
--     activa y mide el paro con criterios de la OIT), pero se publica antes, es
--     mensual y llega a provincia y municipio.
with prov as (
    select
        make_date(cast(mes / 100 as integer), cast(mes % 100 as integer), 1) as mes,
        cod_prov,
        paro_total,
        hombres_menor25 + mujeres_menor25 as paro_menor25,
        hombres_menor25 + hombres_25_44 + hombres_45_mas as paro_hombres,
        mujeres_menor25 + mujeres_25_44 + mujeres_45_mas as paro_mujeres
    from {{ source('raw_mercado', 'sepe_paro_provincias') }}
),

pob as (
    select cast(anio as integer) as anio, cod_prov, sum(poblacion) as poblacion_16_64
    from {{ source('raw', 'ine_poblacion_provincias') }}
    where sexo = 'Total' and edad between 16 and 64 and cod_prov is not null
    group by all
),

rango as (select min(anio) as a_min, max(anio) as a_max from pob),

prov_pob as (
    select p.*, t.cod_ccaa, b.poblacion_16_64
    from prov p
    cross join rango r
    join {{ ref('territorios_provincias') }} t on t.cod_prov = p.cod_prov
    left join pob b on b.cod_prov = p.cod_prov
        and b.anio = greatest(least(year(p.mes), r.a_max), r.a_min)
),

niveles as (
    select mes, 'provincia' as nivel, cod_prov as cod, paro_total, paro_menor25, paro_hombres, paro_mujeres, poblacion_16_64
    from prov_pob
    union all
    select mes, 'ccaa', cod_ccaa, sum(paro_total), sum(paro_menor25), sum(paro_hombres), sum(paro_mujeres), sum(poblacion_16_64)
    from prov_pob group by all
    union all
    select mes, 'pais', '00', sum(paro_total), sum(paro_menor25), sum(paro_hombres), sum(paro_mujeres), sum(poblacion_16_64)
    from prov_pob group by all
)

select
    n.mes,
    cast(year(n.mes) as integer) as anio,
    n.nivel,
    n.cod,
    t.nombre as territorio,
    paro_total as paro_registrado,
    paro_menor25,
    paro_hombres,
    paro_mujeres,
    poblacion_16_64,
    100.0 * paro_total / poblacion_16_64 as por_100_16_64,
    paro_total - lag(paro_total) over (partition by n.nivel, n.cod order by n.mes) as variacion_mensual,
    paro_total - lag(paro_total, 12) over (partition by n.nivel, n.cod order by n.mes) as variacion_anual,
    100.0 * (paro_total / lag(paro_total, 12) over (partition by n.nivel, n.cod order by n.mes) - 1) as variacion_anual_pct
from niveles n
left join {{ ref('territorios') }} t on t.nivel = n.nivel and t.cod = n.cod
