-- Resultado de cada elección en cada municipio (Ministerio del Interior,
-- infoelectoral, ficheros 05 y 06: total municipal).
--   participacion   (candidaturas + blanco + nulos) / censo de escrutinio, en %.
--                   El voto CERA (residentes en el extranjero) no se reparte por
--                   municipio, así que no está ni en el censo ni en los votos.
--   pct_*           % sobre votos válidos (candidaturas + blanco) del bloque o familia
--   nep             número efectivo de partidos sobre los votos a candidaturas
--   ganador_*       candidatura más votada; en Municipales, `ganador_electos` son
--                   sus concejales
-- En Municipales solo hay municipios de más de 250 habitantes (listas cerradas; los
-- de concejo abierto o listas abiertas vienen en otros ficheros que no se cargan).
-- Los % se calculan sobre blancos + la suma de votos del fichero 06, para que cuadren
-- aunque el total del fichero 05 no coincida (pasa en algunos municipios de 1977-1979).
-- Si los votantes superan el censo (errores de la fuente, sobre todo en 1977), la
-- participación queda en null. Tabla ligera (decimales, sin nombres) para las fichas
-- de municipio: el nombre está en poblacion_municipios / elecciones_municipios_congreso.
with mun as (
    select
        proceso,
        tipo,
        cast(anio as integer) as anio,
        cod_mun,
        municipio,
        censo_escrutinio as censo,
        votos_blanco as blancos,
        votos_nulos as nulos,
        votos_candidaturas,
        escanos
    from {{ source('raw_elecciones', 'elecciones_municipios') }}
    where vuelta = 1
),

votos as (
    select
        v.proceso,
        v.cod_mun,
        v.votos,
        v.electos,
        c.siglas,
        c.familia,
        c.color,
        c.bloque,
        sum(v.votos) over (partition by v.proceso, v.cod_mun) as total_mun
    from {{ source('raw_elecciones', 'elecciones_municipios_votos') }} v
    left join {{ ref('elecciones_candidaturas') }} c
        on c.proceso = v.proceso and c.cod_candidatura = v.cod_candidatura
    where v.vuelta = 1 and v.votos > 0
),

agg as (
    select
        v.proceso,
        v.cod_mun,
        sum(v.votos) filter (where v.bloque = 'Izquierda') as v_izquierda,
        sum(v.votos) filter (where v.bloque = 'Derecha') as v_derecha,
        sum(v.votos) filter (where v.bloque = 'Centro') as v_centro,
        sum(v.votos) filter (where v.bloque = 'Nacionalistas y regionalistas') as v_nacionalistas,
        sum(v.votos) filter (where v.familia = 'PSOE') as v_psoe,
        sum(v.votos) filter (where v.familia = 'PP') as v_pp,
        sum(v.votos) filter (where v.familia = 'Vox') as v_vox,
        sum(v.votos) filter (where v.familia = 'IU, Podemos y Sumar') as v_ips,
        sum(v.votos) filter (where v.familia = 'Ciudadanos') as v_cs,
        sum(v.votos) as v_candidaturas,
        1.0 / nullif(sum(power(v.votos::double / v.total_mun, 2)), 0) as nep
    from votos v
    group by all
),

ganador as (
    select proceso, cod_mun,
        siglas as ganador_siglas, familia as ganador_familia, color as ganador_color,
        bloque as ganador_bloque, votos as ganador_votos, electos as ganador_electos
    from votos
    qualify row_number() over (partition by proceso, cod_mun order by votos desc, electos desc) = 1
)

select
    m.proceso,
    m.tipo,
    m.anio,
    m.cod_mun,
    cast(m.censo as integer) as censo,
    cast(m.blancos + m.nulos + m.votos_candidaturas as integer) as votantes,
    case when m.blancos + m.nulos + m.votos_candidaturas <= m.censo then
        cast(100.0 * (m.blancos + m.nulos + m.votos_candidaturas) / nullif(m.censo, 0) as decimal(5, 2))
    end as participacion,
    g.ganador_siglas,
    g.ganador_familia,
    cast(100.0 * g.ganador_votos / nullif(m.blancos + a.v_candidaturas, 0) as decimal(5, 2)) as ganador_pct,
    cast(g.ganador_electos as smallint) as ganador_electos,
    cast(m.escanos as smallint) as concejales,
    {%- for col, v in [('pct_izquierda', 'v_izquierda'), ('pct_derecha', 'v_derecha'), ('pct_centro', 'v_centro'), ('pct_nacionalistas', 'v_nacionalistas'),
                       ('pct_psoe', 'v_psoe'), ('pct_pp', 'v_pp'), ('pct_vox', 'v_vox'),
                       ('pct_iu_podemos_sumar', 'v_ips'), ('pct_cs', 'v_cs')] %}
    cast(100.0 * coalesce(a.{{ v }}, 0) / nullif(m.blancos + a.v_candidaturas, 0) as decimal(5, 2)) as {{ col }},
    {%- endfor %}
    cast(least(a.nep, 99) as decimal(4, 2)) as nep
from mun m
left join agg a using (proceso, cod_mun)
left join ganador g using (proceso, cod_mun)
