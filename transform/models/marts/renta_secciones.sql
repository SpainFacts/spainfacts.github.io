-- Renta de los hogares por sección censal (código INE de 10 dígitos: municipio +
-- distrito + sección) y año, según el Atlas de Distribución de Renta de los Hogares
-- del INE (ADRH, tabla 30824; 2015-2023), para los mapas de barrio de la ficha de
-- municipio. Importes reales deflactados con el IPC medio del año (euros de anio_base).
-- Solo municipios con más de una sección en el seccionado (los que tienen mapa).
--   geo_anio   año del seccionado del INE con el que se pinta (ver elecciones_secciones);
--              para años anteriores al primer seccionado guardado, ese primero.
--   renta_*_tope  el INE corta las secciones más ricas a un mismo valor máximo cada año
--                 (en 2023, ~180 secciones a 36.918 € por persona): verdadero si la sección
--                 está en ese tope, es decir, su renta real es ese valor «o más».
--   renta_*_suelo lo mismo por abajo (en 2023, 32 secciones a 5.522 € por persona): su
--                 renta real es ese valor «o menos».
-- El ADRH lista a la vez los códigos de sección de varios seccionados (los viejos y los
-- nuevos de las secciones partidas), así que casa con la geometría de cualquier año.
-- Las secciones se parten y renumeran de un año a otro: la serie de una misma sección
-- solo es comparable mientras no cambie su código.
with base as (
    select
        cod_mun,
        cod_seccion,
        cast(anio as integer) as anio,
        max(valor) filter (where indicador = 'Renta neta media por persona') as renta_persona,
        max(valor) filter (where indicador = 'Renta neta media por hogar') as renta_hogar,
        max(valor) filter (where indicador = 'Mediana de la renta por unidad de consumo') as renta_uc_mediana
    from {{ source('raw_renta', 'ine_adrh_municipios') }}
    where nivel = 'seccion'
    group by cod_mun, cod_seccion, anio
),

topes as (
    select anio, max(renta_persona) as tope_persona, max(renta_hogar) as tope_hogar,
        min(renta_persona) as suelo_persona, min(renta_hogar) as suelo_hogar
    from base
    group by anio
),

geo as (
    select cast(anio as integer) as geo_anio, cod_mun
    from {{ ref('secciones_geo') }}
)

select
    cast(b.cod_seccion as varchar) as cod_seccion,
    'Distrito ' || substr(b.cod_seccion, 6, 2) || ', sección ' || right(b.cod_seccion, 3) as seccion,
    cast(b.cod_mun as varchar) as cod_mun,
    m.nombre as municipio,
    b.anio,
    b.renta_persona * d.factor as renta_persona_real,
    b.renta_hogar * d.factor as renta_hogar_real,
    b.renta_uc_mediana * d.factor as renta_uc_mediana_real,
    b.renta_persona = t.tope_persona as renta_persona_tope,
    b.renta_hogar = t.tope_hogar as renta_hogar_tope,
    b.renta_persona = t.suelo_persona as renta_persona_suelo,
    b.renta_hogar = t.suelo_hogar as renta_hogar_suelo,
    d.anio_base,
    coalesce(
        (select max(geo.geo_anio) from geo where geo.cod_mun = b.cod_mun and geo.geo_anio <= b.anio),
        (select min(geo.geo_anio) from geo where geo.cod_mun = b.cod_mun)
    ) as geo_anio
from base b
join topes t using (anio)
left join {{ ref('deflactor') }} d on d.anio = b.anio
left join {{ ref('stg_ine_municipios') }} m on m.cod_mun = b.cod_mun
where b.cod_mun in (select cod_mun from geo)
order by b.cod_mun, b.anio, b.cod_seccion
