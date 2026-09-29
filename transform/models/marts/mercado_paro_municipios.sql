-- Paro registrado por municipio (SEPE, datos abiertos), último mes publicado y
-- el mismo mes del año anterior, por cada 100 habitantes (padrón del último
-- año disponible, INE vía poblacion_municipios). El SEPE oculta las cifras de
-- 1 a 4 personas ("<5"): esos municipios quedan con paro_registrado NULL y
-- oculto = true. Serie mensual completa desde 2016 en raw.sepe_paro_municipios.
with ult as (
    select max(mes) as mes from {{ source('raw_mercado', 'sepe_paro_municipios') }}
),

base as (
    select
        s.cod_municipio,
        s.cod_prov,
        max(s.municipio) as municipio,
        max(s.paro_total) filter (where s.mes = u.mes) as paro_registrado,
        bool_or(s.oculto) filter (where s.mes = u.mes) as oculto,
        max(s.paro_total) filter (where s.mes = u.mes - 100) as paro_registrado_hace_1_anio,
        max(s.hombres_menor25 + s.mujeres_menor25) filter (where s.mes = u.mes) as paro_menor25,
        make_date(cast(u.mes / 100 as integer), cast(u.mes % 100 as integer), 1) as mes
    from {{ source('raw_mercado', 'sepe_paro_municipios') }} s
    cross join ult u
    where s.mes in (u.mes, u.mes - 100)
    group by s.cod_municipio, s.cod_prov, u.mes
),

pob as (
    select cod_mun, poblacion, anio
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
    qualify row_number() over (partition by cod_mun order by anio desc) = 1
)

select
    b.mes,
    b.cod_municipio,
    b.cod_prov,
    b.municipio,
    b.paro_registrado,
    b.oculto,
    b.paro_registrado_hace_1_anio,
    b.paro_menor25,
    p.poblacion,
    p.anio as anio_poblacion,
    100.0 * b.paro_registrado / p.poblacion as por_100_hab,
    100.0 * (b.paro_registrado / b.paro_registrado_hace_1_anio - 1) as variacion_anual_pct
from base b
left join pob p on p.cod_mun = b.cod_municipio
