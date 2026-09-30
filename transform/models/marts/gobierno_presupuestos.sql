-- Un ejercicio por fila (1978-año en curso): si tuvo Ley de Presupuestos
-- Generales del Estado propia, cuándo se publicó en el BOE y cuántos días estuvo
-- el Estado funcionando con los presupuestos del año anterior prorrogados
-- (art. 134.4 de la Constitución: si la ley no está aprobada el 1 de enero, se
-- prorrogan automáticamente los del ejercicio anterior).
--   situacion   'A tiempo'           ley publicada antes del 1 de enero
--               'Tarde'              ley publicada durante el propio ejercicio
--               'Prorrogado'         ejercicio entero sin ley propia
--               'Prorrogado (en curso)'  ejercicio actual todavía sin ley
--   dias_prorroga  días del ejercicio sin ley propia en vigor (desde el 1 de enero
--                  hasta la publicación; el año entero si no la hubo; hasta hoy
--                  en el ejercicio en curso)
-- Atribución: al Gobierno que debía presentar el proyecto, el que estaba en
-- funciones el 30 de septiembre del año anterior (art. 134.3: el proyecto se
-- presenta «al menos tres meses antes de la expiración» del ejercicio). También
-- se da el presidente el 1 de enero del ejercicio, que es quien gobierna con la prórroga.
with leyes as (
    select
        try_cast(regexp_extract(titulo,
            'Presupuestos Generales del Estado para (?:el )?(?:año |ejercicio (?:de )?)?(\d{4})', 1) as integer) as ejercicio,
        numero || '/' || anio_numero as ley,
        fecha_disposicion,
        fecha_publicacion,
        titulo,
        url_html
    from {{ ref('stg_boe_actos_gobierno') }}
    where tipo = 'ley_presupuestos'
        and regexp_matches(titulo, '^Ley \d+/\d{4}, de [^,]+, de Presupuestos Generales del Estado para')
    qualify row_number() over (partition by ejercicio order by fecha_publicacion, identificador) = 1
),

ejercicios as (
    select cast(unnest(range(1978, year(current_date) + 1)) as integer) as ejercicio
),

presidencias as (
    select presidente, familia, desde, coalesce(hasta, current_date + 1) as hasta
    from {{ ref('stg_presidencias_gobierno') }}
),

base as (
    select
        e.ejercicio,
        l.ley,
        l.fecha_disposicion,
        l.fecha_publicacion,
        l.titulo,
        l.url_html,
        make_date(e.ejercicio, 1, 1) as inicio,
        least(make_date(e.ejercicio + 1, 1, 1), current_date) as fin_computable,
        e.ejercicio = year(current_date) as en_curso
    from ejercicios e
    left join leyes l using (ejercicio)
)

select
    b.ejercicio,
    case
        when b.fecha_publicacion < b.inicio then 'A tiempo'
        when b.fecha_publicacion is not null then 'Tarde'
        when b.en_curso then 'Prorrogado (en curso)'
        else 'Prorrogado'
    end as situacion,
    b.ley,
    b.fecha_disposicion,
    b.fecha_publicacion,
    case
        when b.fecha_publicacion < b.inicio then 0
        when b.fecha_publicacion is not null then date_diff('day', b.inicio, b.fecha_publicacion)
        else date_diff('day', b.inicio, b.fecha_fin)
    end as dias_prorroga,
    b.fecha_publicacion is not null and b.fecha_publicacion < b.inicio as en_plazo,
    b.en_curso,
    pr.presidente as presidente_responsable,
    pr.familia as partido_responsable,
    pe.presidente as presidente_1_enero,
    pe.familia as partido_1_enero,
    b.titulo,
    b.url_html
from (select *, fin_computable as fecha_fin from base) b
left join presidencias pr
    on make_date(b.ejercicio - 1, 9, 30) >= pr.desde and make_date(b.ejercicio - 1, 9, 30) < pr.hasta
left join presidencias pe
    on b.inicio >= pe.desde and b.inicio < pe.hasta
order by b.ejercicio
