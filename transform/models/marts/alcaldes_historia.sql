-- Un periodo de alcalde por fila (1979-hoy), con su familia política y los
-- tramos continuos de la misma persona y de la misma familia en cada municipio.
--
-- Etiquetas genéricas: en 2015-2023 el SIL agrupa muchas coaliciones como
-- "C. ELECTORAL" u "OTROS" (familia 'Sin detalle en la fuente'). Si la misma
-- persona fue alcalde del mismo municipio con una etiqueta concreta en otro
-- mandato a 8 años o menos, se toma esa familia (familia_inferida = true).
--
-- Misma persona: comparten todas las palabras del nombre más corto (o todas
-- menos una si tiene 4 o más), sin importar el orden nombre/apellidos.
{% set misma_persona %}
    len(list_intersect({a}, {b})) >= case
        when least(len({a}), len({b})) >= 4 then least(len({a}), len({b})) - 1
        else greatest(least(len({a}), len({b})), 1)
    end
{% endset %}
{% set generica = "'Sin detalle en la fuente'" %}

with base as (
    select * from {{ ref('stg_alcaldes') }}
),

inferida as (
    select
        b.cod_mun,
        b.mandato,
        b.fecha_posesion,
        b.nombre_tokens,
        b.partido_clave,
        o.familia,
        o.siglas_familia,
        o.color
    from base b
    join base o
        on o.cod_mun = b.cod_mun
        and o.mandato <> b.mandato
        and abs(o.anio_inicio_mandato - b.anio_inicio_mandato) <= 8
        and o.familia not in ({{ generica }}, 'Comisión gestora')
        and {{ misma_persona | replace('{a}', 'b.nombre_tokens') | replace('{b}', 'o.nombre_tokens') }}
    where b.familia = {{ generica }}
    qualify row_number() over (
        partition by b.cod_mun, b.mandato, b.fecha_posesion, b.nombre_tokens, b.partido_clave
        order by abs(o.anio_inicio_mandato - b.anio_inicio_mandato), o.anio_inicio_mandato desc, o.fecha_posesion desc
    ) = 1
),

con_inferencia as (
    select
        b.*,
        b.familia as familia_fuente,
        i.familia is not null as familia_inferida,
        coalesce(i.familia, b.familia) as familia_final,
        coalesce(i.siglas_familia, b.siglas_familia) as siglas_final,
        coalesce(i.color, b.color) as color_final
    from base b
    left join inferida i
        on i.cod_mun = b.cod_mun
        and i.mandato = b.mandato
        and i.fecha_posesion = b.fecha_posesion
        and i.nombre_tokens = b.nombre_tokens
        and i.partido_clave = b.partido_clave
),

ordenado as (
    select
        *,
        row_number() over w as orden,
        lag(nombre_tokens) over w as tokens_prev,
        lag(familia_final) over w as familia_prev,
        lead(fecha_posesion) over w as fecha_siguiente
    from con_inferencia
    window w as (
        partition by cod_mun
        order by fecha_posesion, anio_inicio_mandato, origen desc, orden_fichero
    )
),

marcas as (
    select
        *,
        case
            when tokens_prev is null then 1
            when {{ misma_persona | replace('{a}', 'tokens_prev') | replace('{b}', 'nombre_tokens') }} then 0
            else 1
        end as nueva_persona,
        case
            when familia_prev is null or familia_prev <> familia_final or familia_final = {{ generica }} then 1
            else 0
        end as nueva_familia
    from ordenado
),

tramos as (
    select
        *,
        sum(nueva_persona) over w as tramo_persona,
        sum(nueva_familia) over w as tramo_familia
    from marcas
    window w as (partition by cod_mun order by orden rows unbounded preceding)
)

select
    cod_mun,
    mandato,
    orden,
    origen = 'actual' as es_actual,
    municipio,
    provincia,
    alcalde,
    cargo,
    fecha_posesion,
    -- fin: la baja del fichero o, si no la trae, la toma de posesión del siguiente
    case when origen = 'actual' then null else coalesce(fecha_baja, fecha_siguiente) end as fecha_fin,
    partido_original,
    partido_clave,
    familia_final as familia,
    siglas_final as siglas_familia,
    color_final as color,
    familia_fuente,
    familia_inferida,
    familia_en_seed,
    tramo_persona,
    tramo_familia,
    min(fecha_posesion) over (partition by cod_mun, tramo_persona) as inicio_tramo_persona,
    min(fecha_posesion) over (partition by cod_mun, tramo_familia) as inicio_tramo_familia,
    count(distinct mandato) over (partition by cod_mun, tramo_familia) as mandatos_tramo_familia,
    cod_mun || '-' || orden as clave
from tramos
