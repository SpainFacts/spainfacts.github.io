-- Hospitales y camas por comunidad según quién los gestiona y cómo se vinculan al SNS (Ministerio de
-- Sanidad, Catálogo Nacional de Hospitales, ediciones 2020 en adelante; anio = año al que se
-- refiere la edición: la edición N describe la situación a 31-12-N-1).
--   dependencia_grupo (dependencia funcional del CNH):
--     'publica'  servicios de salud de las comunidades, INGESA, Defensa, diputaciones, municipios y
--                otros organismos públicos (incluye consorcios públicos catalanes)
--     'privada'  privados (con o sin ánimo de lucro: fundaciones, órdenes religiosas, empresas)
--     'mutua'    mutuas colaboradoras con la Seguridad Social
--     'ong'      organizaciones no gubernamentales (Cruz Roja...)
--   vinculacion_sns (campo Concierto):
--     'red_publica'       red de utilización pública (RUP: XHUP/SISCAT catalana y similares)
--     'sustitutorio'      concierto sustitutorio (el centro hace de hospital público de un área)
--     'concierto_parcial' concierto parcial (pruebas, cirugías...)
--     'sin_concierto'
--   OJO: el CNH clasifica como dependencia 'publica' (servicio de salud) hospitales de concesión
--   capitativa como Valdemoro, Villalba, Torrejón, Rey Juan Carlos («ID Dalud Móstoles») o
--   Vinalopó: este catálogo NO identifica la gestión privada por concesión (para eso,
--   sanidad_privada_gestion_privada). En cambio, la Fundación Jiménez Díaz figura como privada con
--   concierto sustitutorio.
--   camas: instaladas. _por_100k_hab con la población a 1 de enero de N (= 31-12-N-1).
--   _pct: sobre el total de hospitales / camas de la comunidad en ese año.
with h as (
    select
        cast(edicion as integer) as edicion,
        cast(edicion as integer) - 1 as anio,
        lpad(cast(cod_ccaa as varchar), 2, '0') as cod_ccaa,
        codcnh,
        coalesce(camas, 0) as camas,
        lower(dependencia) as dep,
        lower(coalesce(concierto, '')) as conc
    from {{ source('raw_sanidad_privada', 'sanidad_privada_cnh') }}
),

clas as (
    select *,
        case
            when dep like '%privad%' then 'privada'
            when dep like '%mutua%' or dep like '%mútua%' then 'mutua'
            when dep like '%no gubernamental%' then 'ong'
            else 'publica'
        end as dependencia_grupo,
        case
            when conc like '%rup%' or conc like 'red de utiliz%' then 'red_publica'
            when conc like '%sustitut%' then 'sustitutorio'
            when conc like '%parcial%' then 'concierto_parcial'
            else 'sin_concierto'
        end as vinculacion_sns
    from h
),

agr as (
    select cod_ccaa, anio, edicion, dependencia_grupo, vinculacion_sns,
        count(*) as hospitales, sum(camas) as camas
    from clas
    group by all
    union all
    select '00', anio, edicion, dependencia_grupo, vinculacion_sns, count(*), sum(camas)
    from clas
    group by all
),

pob as (
    select cast(cod as varchar) as cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel in ('ccaa', 'pais') and sexo = 'Total'
),

max_pob as (select max(anio) as max_anio from pob)

select
    a.cod_ccaa,
    case when a.cod_ccaa = '00' then 'España' else t.nombre end as ccaa,
    a.anio,
    a.edicion,
    a.dependencia_grupo,
    a.vinculacion_sns,
    a.dependencia_grupo <> 'publica' and a.vinculacion_sns in ('red_publica', 'sustitutorio')
        as privado_en_red_publica,
    a.hospitales,
    a.camas,
    100.0 * a.hospitales / sum(a.hospitales) over (partition by a.cod_ccaa, a.anio) as hospitales_pct,
    100.0 * a.camas / nullif(sum(a.camas) over (partition by a.cod_ccaa, a.anio), 0) as camas_pct,
    1e5 * a.camas / p.poblacion as camas_por_100k_hab
from agr a
cross join max_pob m
left join pob p on p.cod = a.cod_ccaa and p.anio = least(a.edicion, m.max_anio)
left join {{ ref('territorios') }} t on t.nivel = 'ccaa' and t.cod = a.cod_ccaa
