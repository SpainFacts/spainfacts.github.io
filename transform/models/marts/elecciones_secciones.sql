-- Resultado de las últimas elecciones de cada tipo (Congreso y Municipales de 2023,
-- Parlamento Europeo de 2024) en cada sección censal, para los mapas de barrio de la
-- ficha de municipio. Ministerio del Interior, ficheros por mesa (09 y 10) sumados por
-- sección en la ingesta (ingestion/elecciones.py, PROCESOS_SECCION).
--   participacion   (candidaturas + blanco + nulos) / censo de escrutinio, en %
--   pct_*           % sobre votos válidos (candidaturas + blanco), como en
--                   elecciones_municipios
--   ganador_*       candidatura más votada en la sección, con el color de su familia
--   geo_anio        año del seccionado del INE con el que se pinta: el fichero
--                   static-extra/geo/secciones/<geo_anio>/<cod_mun>.geojson más reciente que no
--                   sea posterior a la elección (o el primero, si todos son posteriores; seed
--                   secciones_geo, tools/geo/secciones.py)
-- Solo municipios con más de una sección (los que tienen mapa). En Municipales, solo los
-- de más de 250 habitantes (listas cerradas). Sin voto CERA, que no tiene sección.
with sec as (
    select
        proceso,
        tipo,
        cast(anio as integer) as anio,
        cod_seccion,
        cod_mun,
        censo_escrutinio as censo,
        votos_blanco as blancos,
        votos_nulos as nulos,
        votos_candidaturas
    from {{ source('raw_elecciones', 'elecciones_secciones') }}
    where vuelta = 1
),

votos as (
    select
        v.proceso,
        v.cod_seccion,
        v.votos,
        c.siglas,
        c.familia,
        c.color,
        c.bloque
    from {{ source('raw_elecciones', 'elecciones_secciones_votos') }} v
    left join {{ ref('elecciones_candidaturas') }} c
        on c.proceso = v.proceso and c.cod_candidatura = v.cod_candidatura
    where v.vuelta = 1 and v.votos > 0
),

agg as (
    select
        proceso,
        cod_seccion,
        sum(votos) filter (where bloque = 'Izquierda') as v_izquierda,
        sum(votos) filter (where bloque = 'Derecha') as v_derecha,
        sum(votos) filter (where bloque = 'Centro') as v_centro,
        sum(votos) filter (where bloque = 'Nacionalistas y regionalistas') as v_nacionalistas,
        sum(votos) filter (where familia = 'PSOE') as v_psoe,
        sum(votos) filter (where familia = 'PP') as v_pp,
        sum(votos) filter (where familia = 'Vox') as v_vox,
        sum(votos) filter (where familia = 'IU, Podemos y Sumar') as v_ips,
        sum(votos) as v_candidaturas
    from votos
    group by all
),

ganador as (
    select proceso, cod_seccion,
        siglas as ganador_siglas, familia as ganador_familia, color as ganador_color, votos as ganador_votos
    from votos
    qualify row_number() over (partition by proceso, cod_seccion order by votos desc, siglas) = 1
),

geo as (
    select cast(anio as integer) as geo_anio, cod_mun
    from {{ ref('secciones_geo') }}
),

pr as (
    select proceso, eleccion
    from {{ ref('elecciones_participacion') }}
    where nivel = 'pais'
)

select
    s.proceso,
    s.tipo,
    s.anio,
    pr.eleccion,
    s.cod_seccion,
    'Distrito ' || substr(s.cod_seccion, 6, 2) || ', sección ' || right(s.cod_seccion, 3) as seccion,
    s.cod_mun,
    d.nombre as municipio,
    cast(s.censo as integer) as censo,
    cast(s.blancos + s.nulos + s.votos_candidaturas as integer) as votantes,
    case when s.blancos + s.nulos + s.votos_candidaturas <= s.censo then
        cast(100.0 * (s.blancos + s.nulos + s.votos_candidaturas) / nullif(s.censo, 0) as decimal(4, 1))
    end as participacion,
    g.ganador_siglas,
    g.ganador_familia,
    g.ganador_color,
    cast(100.0 * g.ganador_votos / nullif(s.blancos + a.v_candidaturas, 0) as decimal(4, 1)) as ganador_pct,
    {%- for col, v in [('pct_izquierda', 'v_izquierda'), ('pct_derecha', 'v_derecha'), ('pct_centro', 'v_centro'), ('pct_nacionalistas', 'v_nacionalistas'),
                       ('pct_psoe', 'v_psoe'), ('pct_pp', 'v_pp'), ('pct_vox', 'v_vox'), ('pct_iu_podemos_sumar', 'v_ips')] %}
    cast(100.0 * coalesce(a.{{ v }}, 0) / nullif(s.blancos + a.v_candidaturas, 0) as decimal(4, 1)) as {{ col }},
    {%- endfor %}
    coalesce(
        (select max(geo.geo_anio) from geo where geo.cod_mun = s.cod_mun and geo.geo_anio <= s.anio),
        (select min(geo.geo_anio) from geo where geo.cod_mun = s.cod_mun)
    ) as geo_anio
from sec s
left join agg a using (proceso, cod_seccion)
left join ganador g using (proceso, cod_seccion)
left join pr using (proceso)
left join {{ ref('stg_ine_municipios') }} d on d.cod_mun = s.cod_mun
where s.cod_mun in (select cod_mun from geo)
order by s.cod_mun, s.proceso, s.cod_seccion
