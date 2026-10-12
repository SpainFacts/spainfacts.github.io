-- Resultado de cada elección autonómica en cada municipio (todas las de cada comunidad
-- que publica su fuente oficial, ver ingestion/autonomicas/), para la página de cada
-- comunidad. Si la fuente da el municipio entero se usa; si no, se suman sus secciones.
--   participacion   (candidaturas + blanco + nulos) / censo, en %; sin voto CERA
--   pct_*           % sobre votos válidos (candidaturas + blanco); los votos a
--                   candidaturas son el mayor entre el total y la suma por candidatura
--                   (en Murcia por mesa solo vienen los partidos de más del 1 %)
--   ganador_*       candidatura más votada y su familia (color de la familia)
-- cod_mun es el código INE en la fecha de la elección; el nombre, el del municipio
-- vigente (vacío si ya no existe).
with filas as (
    select
        proceso,
        coalesce(nivel, 'seccion') as nivel,
        coalesce(cod_mun, left(cod_seccion, 5)) as cod_mun,
        censo_escrutinio as censo,
        -- algunas fuentes antiguas por municipio no dan blancos ni nulos (ICANE en Cantabria):
        -- cuentan como 0 y la participación queda vacía si falta el censo
        coalesce(votos_blanco, 0) as blancos,
        coalesce(votos_nulos, 0) as nulos,
        votos_blanco is null or votos_nulos is null or censo_escrutinio is null as incompleto,
        votos_candidaturas
    from {{ source('raw_elecciones', 'elecciones_secciones') }}
    where tipo = '05' and vuelta = 1
),

-- municipios que la fuente da enteros: no se suman sus secciones
enteros as (
    select distinct proceso, cod_mun from filas where nivel = 'municipio'
),

mun as (
    select proceso, cod_mun, sum(censo) as censo, sum(blancos) as blancos, sum(nulos) as nulos,
        sum(votos_candidaturas) as votos_candidaturas, bool_or(incompleto) as incompleto
    from filas f
    where nivel = 'municipio'
        or not exists (select 1 from enteros e where e.proceso = f.proceso and e.cod_mun = f.cod_mun)
    group by all
),

votos as (
    select
        v.proceso,
        coalesce(v.cod_mun, left(v.cod_seccion, 5)) as cod_mun,
        sum(v.votos) as votos,
        c.siglas,
        c.familia,
        c.color,
        c.bloque
    from {{ source('raw_elecciones', 'elecciones_secciones_votos') }} v
    left join {{ ref('elecciones_candidaturas') }} c
        on c.proceso = v.proceso and c.cod_candidatura = v.cod_candidatura
    where v.tipo = '05' and v.vuelta = 1 and v.votos > 0
        and (coalesce(v.nivel, 'seccion') = 'municipio'
            or not exists (select 1 from enteros e
                           where e.proceso = v.proceso and e.cod_mun = coalesce(v.cod_mun, left(v.cod_seccion, 5))))
    group by all
),

agg as (
    select
        proceso,
        cod_mun,
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
    select proceso, cod_mun,
        siglas as ganador_siglas, familia as ganador_familia, color as ganador_color, votos as ganador_votos
    from votos
    qualify row_number() over (partition by proceso, cod_mun order by votos desc, siglas) = 1
),

pr as (
    select proceso, cast(fecha as date) as fecha, cast(anio as integer) as anio, eleccion, cod_ccaa
    from {{ source('raw_elecciones', 'elecciones_procesos') }}
    where tipo = '05'
)

select
    m.proceso,
    pr.anio,
    pr.fecha,
    pr.eleccion,
    pr.cod_ccaa,
    tc.nombre as ccaa,
    m.cod_mun,
    d.nombre as municipio,
    left(m.cod_mun, 2) as cod_prov,
    tp.nombre as provincia,
    cast(m.censo as integer) as censo,
    cast(m.blancos + m.nulos + greatest(m.votos_candidaturas, coalesce(a.v_candidaturas, 0)) as integer) as votantes,
    cast(m.blancos + greatest(m.votos_candidaturas, coalesce(a.v_candidaturas, 0)) as integer) as validos,
    m.incompleto as sin_blancos_nulos,
    -- sin blancos o nulos en la fuente, la participación quedaría por debajo de la real
    case when not m.incompleto and m.censo > 0 and m.blancos + m.nulos + m.votos_candidaturas <= m.censo then
        cast(100.0 * (m.blancos + m.nulos + m.votos_candidaturas) / nullif(m.censo, 0) as decimal(4, 1))
    end as participacion,
    g.ganador_siglas,
    g.ganador_familia,
    g.ganador_color,
    {%- set validos = "nullif(m.blancos + greatest(m.votos_candidaturas, coalesce(a.v_candidaturas, 0)), 0)" %}
    cast(100.0 * g.ganador_votos / {{ validos }} as decimal(4, 1)) as ganador_pct,
    {%- for col, v in [('pct_izquierda', 'v_izquierda'), ('pct_derecha', 'v_derecha'), ('pct_centro', 'v_centro'), ('pct_nacionalistas', 'v_nacionalistas'),
                       ('pct_psoe', 'v_psoe'), ('pct_pp', 'v_pp'), ('pct_vox', 'v_vox'), ('pct_iu_podemos_sumar', 'v_ips')] %}
    cast(100.0 * coalesce(a.{{ v }}, 0) / {{ validos }} as decimal(4, 1)) as {{ col }}{{ "," if not loop.last }}
    {%- endfor %}
from mun m
left join agg a using (proceso, cod_mun)
left join ganador g using (proceso, cod_mun)
left join pr using (proceso)
left join {{ ref('stg_ine_municipios') }} d on d.cod_mun = m.cod_mun
left join {{ ref('territorios_provincias') }} tp on tp.cod_prov = left(m.cod_mun, 2)
left join {{ ref('territorios_ccaa') }} tc on tc.cod_ccaa = pr.cod_ccaa
order by pr.cod_ccaa, m.proceso, m.cod_mun
