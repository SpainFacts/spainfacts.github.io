-- Entradas del BOE sobre actos del Gobierno (decretos-ley, sus convalidaciones,
-- leyes, presupuestos e indultos), con número oficial y fecha de la disposición
-- sacados del título ("Real Decreto-ley 8/2020, de 17 de marzo, ...").
-- La fecha de la disposición es la del Consejo de Ministros (o la sanción de la
-- ley): es la que decide a qué Gobierno se atribuye. Si el título no la trae
-- (algunos indultos de 1977-1978), se usa la de publicación.
with base as (
    select
        identificador,
        cast(fecha_publicacion as date) as fecha_publicacion,
        tipo,
        departamento,
        titulo,
        url_html,
        case when tipo = 'convalidacion_rdl'
            then regexp_extract(titulo, 'Real Decreto[- ][Ll]ey (\d+)/(\d{4})', ['num', 'anio'])
            else regexp_extract(titulo, '^[^0-9]*(\d+)/(\d{4})', ['num', 'anio'])
        end as num,
        -- primera fecha "de D de mes" (tras el número, o la de la resolución del Congreso)
        regexp_extract(
            titulo,
            'de (\d{1,2}) de (enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|setiembre|octubre|noviembre|diciembre)',
            ['dia', 'mes']
        ) as f,
        regexp_extract(titulo, '^Resoluci[oó]n de \d{1,2} de [a-z]+ de (\d{4})', 1) as anio_resolucion
    from {{ source('raw_transparencia_gobierno', 'boe_actos_gobierno') }}
),

fechas as (
    select
        *,
        try_cast(num.num as integer) as numero,
        try_cast(num.anio as integer) as anio_numero,
        list_position(
            ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'],
            replace(f.mes, 'setiembre', 'septiembre')
        ) as mes_n,
        try_cast(f.dia as integer) as dia_n
    from base
)

select
    identificador,
    tipo,
    departamento,
    titulo,
    url_html,
    fecha_publicacion,
    numero,
    anio_numero,
    -- serie de numeración oficial: la misma norma publicada en varias partes
    -- («Conclusión», «Continuación») comparte serie, número y año
    case
        when tipo in ('ley', 'ley_presupuestos') and titulo ilike 'Ley Org%' then 'ley_organica'
        when tipo in ('ley', 'ley_presupuestos') then 'ley'
        else tipo
    end as serie_numeracion,
    case when tipo = 'convalidacion_rdl' then numero || '/' || anio_numero end as rdl_referido,
    case when tipo = 'convalidacion_rdl'
        then case when titulo ilike '%derogaci%' then 'Derogado' else 'Convalidado' end
    end as resultado,
    -- nunca posterior a la publicación (si lo es, el título se ha leído mal)
    least(coalesce(fecha_titulo, fecha_publicacion), fecha_publicacion) as fecha_disposicion,
    fecha_titulo is null or fecha_titulo > fecha_publicacion as fecha_estimada
from (
    select
        *,
        case when mes_n > 0 and dia_n is not null then try_cast(
            coalesce(try_cast(nullif(anio_resolucion, '') as integer), anio_numero, year(fecha_publicacion))
            || '-' || lpad(mes_n::varchar, 2, '0') || '-' || lpad(dia_n::varchar, 2, '0') as date)
        end as fecha_titulo
    from fechas
)
