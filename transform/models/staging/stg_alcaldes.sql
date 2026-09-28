-- Todos los periodos de alcalde (1979-hoy) en una sola tabla: mandatos cerrados
-- del SIL + alcalde vigente del mandato 2023-2027, con la familia política
-- asignada por el seed partidos_familias.
--
-- partido_clave: etiqueta normalizada (mayúsculas, sin tildes, signos -> espacio);
-- es la clave del seed. Las excepciones del seed acotadas a un mandato o
-- municipio tienen prioridad sobre la regla general de la etiqueta.
-- nombre_tokens: palabras del nombre (>= 3 letras, sin tildes, sin orden) para
-- reconocer a la misma persona aunque el fichero la escriba "APELLIDOS, NOMBRE",
-- "APELLIDOS NOMBRE" o "NOMBRE APELLIDOS".
with unido as (
    select
        'historico' as origen,
        mandato,
        cod_mun,
        municipio,
        provincia,
        nombre,
        'Alcalde' as cargo,
        partido_original,
        fecha_posesion,
        fecha_baja,
        orden_fichero
    from {{ source('raw_alcaldes', 'alcaldes_historico') }}
    union all
    select
        'actual',
        mandato,
        cod_mun,
        municipio,
        provincia,
        nombre,
        cargo,
        partido_original,
        fecha_posesion,
        null::date,
        null::bigint
    from {{ source('raw_alcaldes', 'alcaldes_actuales') }}
),

normalizado as (
    select
        *,
        cast(left(mandato, 4) as integer) as anio_inicio_mandato,
        trim(regexp_replace(upper(strip_accents(coalesce(partido_original, ''))), '[^A-Z0-9]+', ' ', 'g')) as partido_clave,
        list_sort(list_distinct(list_filter(
            string_split(trim(regexp_replace(upper(strip_accents(coalesce(nombre, ''))), '[^A-Z]+', ' ', 'g')), ' '),
            x -> length(x) >= 3 and x not in ('DEL', 'LAS', 'LOS')
        ))) as nombre_tokens
    from unido
),

-- quita duplicados exactos (misma persona, misma fecha, mismo mandato)
dedup as (
    select *
    from normalizado
    qualify row_number() over (
        partition by cod_mun, mandato, fecha_posesion, nombre_tokens, partido_clave
        order by orden_fichero
    ) = 1
),

con_familia as (
    select
        d.*,
        s.familia,
        s.siglas_familia,
        s.color,
        s.ambito,
        s.regla
    from dedup d
    left join {{ ref('partidos_familias') }} s
        on s.partido_original = d.partido_clave
        and (s.mandato is null or s.mandato = d.mandato)
        and (s.cod_mun is null or s.cod_mun = d.cod_mun)
    qualify row_number() over (
        partition by d.cod_mun, d.mandato, d.fecha_posesion, d.nombre_tokens, d.partido_clave
        order by (s.cod_mun is not null) desc, (s.mandato is not null) desc
    ) = 1
)

select
    origen,
    mandato,
    anio_inicio_mandato,
    cod_mun,
    municipio,
    provincia,
    nombre as alcalde,
    nombre_tokens,
    cargo,
    partido_original,
    partido_clave,
    -- dos filas del SIL 2019-2023 no traen fecha: se usa el inicio del mandato
    coalesce(fecha_posesion, make_date(anio_inicio_mandato, 6, 1)) as fecha_posesion,
    fecha_baja,
    coalesce(orden_fichero, 0) as orden_fichero,
    coalesce(familia, 'Independientes y locales') as familia,
    coalesce(siglas_familia, 'Ind.') as siglas_familia,
    coalesce(color, '#9ca3af') as color,
    coalesce(ambito, 'local') as ambito,
    familia is not null as familia_en_seed
from con_familia
