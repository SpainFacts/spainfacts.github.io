-- Defunciones semanales por comunidad y en España (INE, EDeS, tabla 35177) y
-- exceso sobre la media de la misma semana en 2015-2019 (antes de la COVID-19).
-- fecha = primer día (lunes) de la semana. Las muertes crudas crecen con la población
-- y el envejecimiento, así que se dan también por 100.000 habitantes (padrón del año;
-- los años posteriores al último padrón usan el último) y el exceso se mide de las dos
-- formas: exceso_pct sobre las defunciones brutas y exceso_hab_pct sobre la tasa por
-- habitante de 2015-2019 (corrige el crecimiento de la población, pero NO el
-- envejecimiento: no hay defunciones semanales por edad en este corte).
-- Los porcentajes van en 0-100.
with base as (
    select
        cast(epoch_ms(fecha) + interval 12 hour as date) as semana,
        anyo as anio,
        split_part(serie, '. ', 1) as territorio,
        valor as defunciones
    from {{ source('raw', 'ine_defunciones_semanales') }}
    where serie like '%. Total. Todas las edades. Dato base.%' and valor is not null
),

pob as (
    select nivel, cod, anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total' and nivel in ('pais', 'ccaa')
),

pob_rango as (
    select min(anio) as anio_min, max(anio) as anio_max from pob
),

con_cod as (
    select
        b.semana,
        b.anio,
        b.defunciones,
        n.cod_ccaa as cod,
        case when n.cod_ccaa = '00' then 'pais' else 'ccaa' end as nivel,
        cast(weekofyear(b.semana) as integer) as semana_anio,
        p.poblacion
    from base b
    join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = b.territorio
    cross join pob_rango r
    left join pob p
      on p.cod = n.cod_ccaa
     and p.nivel = case when n.cod_ccaa = '00' then 'pais' else 'ccaa' end
     and p.anio = greatest(least(b.anio, r.anio_max), r.anio_min)
),

referencia as (
    select cod, semana_anio,
        avg(defunciones) as media_2015_2019,
        avg(defunciones / nullif(poblacion, 0)) as media_tasa_2015_2019
    from con_cod
    where anio between 2015 and 2019
    group by all
)

select
    cast(c.semana - 6 as date) as fecha,
    c.anio,
    c.semana_anio,
    c.nivel,
    c.cod,
    t.nombre,
    c.defunciones,
    c.poblacion,
    100000.0 * c.defunciones / nullif(c.poblacion, 0) as defunciones_por_100k_hab,
    r.media_2015_2019,
    100000.0 * r.media_tasa_2015_2019 as media_2015_2019_por_100k_hab,
    100 * (c.defunciones / nullif(r.media_2015_2019, 0) - 1) as exceso_pct,
    100 * ((c.defunciones / nullif(c.poblacion, 0)) / nullif(r.media_tasa_2015_2019, 0) - 1) as exceso_hab_pct
from con_cod c
left join referencia r using (cod, semana_anio)
left join {{ ref('territorios') }} t on t.nivel = c.nivel and t.cod = c.cod
