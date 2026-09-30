-- Un real decreto-ley por fila (BOE, desde julio de 1977), con el Gobierno que
-- lo aprobó (fecha del Consejo de Ministros que figura en el título) y lo que
-- decidió el Congreso en el plazo de 30 días hábiles del art. 86 de la
-- Constitución: convalidado o derogado, según la resolución del Congreso
-- publicada en el BOE. Estado 'Sin resolución en el BOE' = no se ha encontrado
-- la resolución (pendiente de votación si el decreto es reciente; en los
-- primeros años el Congreso no siempre la publicaba en el BOE).
with rdl as (
    select *
    from {{ ref('stg_boe_actos_gobierno') }}
    where tipo = 'real_decreto_ley' and numero is not null
    qualify row_number() over (partition by anio_numero, numero order by fecha_publicacion, identificador) = 1
),

votaciones as (
    select
        rdl_referido,
        -- si hubiera más de una resolución, manda la derogación
        max(resultado) filter (where resultado = 'Derogado') as derogado,
        min(fecha_disposicion) as fecha_votacion
    from {{ ref('stg_boe_actos_gobierno') }}
    where tipo = 'convalidacion_rdl' and rdl_referido is not null
    group by rdl_referido
),

presidencias as (
    select *, coalesce(hasta, current_date + 1) as hasta_efectiva
    from {{ ref('stg_presidencias_gobierno') }}
)

select
    r.identificador,
    r.numero || '/' || r.anio_numero as numero_oficial,
    r.anio_numero as anio,
    r.numero,
    r.fecha_disposicion,
    r.fecha_publicacion,
    r.titulo,
    r.url_html,
    p.presidente,
    p.familia,
    p.orden as orden_presidencia,
    case
        when v.derogado is not null then 'Derogado'
        when v.rdl_referido is not null then 'Convalidado'
        else 'Sin resolución en el BOE'
    end as estado,
    v.fecha_votacion
from rdl r
left join votaciones v on v.rdl_referido = r.numero || '/' || r.anio_numero
left join presidencias p
    on r.fecha_disposicion >= p.desde and r.fecha_disposicion < p.hasta_efectiva
