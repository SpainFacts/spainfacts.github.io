-- Normas con rango de ley e indultos por año (fecha de la disposición), desde
-- 1978 (primer año completo tras las elecciones de 1977), con el presidente que
-- más días gobernó ese año. Fuente: sumarios del BOE.
--   rdl            reales decretos-ley
--   leyes          leyes y leyes orgánicas de las Cortes (incluida la de presupuestos)
--   pct_rdl        % de decretos-ley sobre el total de normas con rango de ley
--   indultos       reales decretos de indulto individual
with actos as (
    select year(fecha_disposicion) as anio, tipo, numero, anio_numero, identificador
    from {{ ref('stg_boe_actos_gobierno') }}
    where tipo in ('real_decreto_ley', 'ley', 'ley_presupuestos', 'indulto')
    qualify tipo = 'indulto'
        or row_number() over (partition by serie_numeracion, anio_numero, numero
                              order by fecha_publicacion, identificador) = 1
),

conteo as (
    select
        anio,
        count(*) filter (where tipo = 'real_decreto_ley') as rdl,
        count(*) filter (where tipo in ('ley', 'ley_presupuestos')) as leyes,
        count(*) filter (where tipo = 'indulto') as indultos
    from actos
    group by anio
),

anios as (
    select cast(unnest(range(1978, year(current_date) + 1)) as integer) as anio
),

dias as (
    select
        a.anio,
        p.presidente,
        p.familia,
        greatest(0, date_diff('day',
            greatest(p.desde, make_date(a.anio, 1, 1)),
            least(coalesce(p.hasta, current_date + 1), make_date(a.anio + 1, 1, 1)))) as dias
    from anios a
    cross join {{ ref('stg_presidencias_gobierno') }} p
),

principal as (
    select anio, presidente, familia
    from dias
    where dias > 0
    qualify row_number() over (partition by anio order by dias desc) = 1
),

cambio as (
    select anio, count(*) filter (where dias > 0) > 1 as cambio_de_gobierno
    from dias group by anio
)

select
    a.anio,
    coalesce(c.rdl, 0) as rdl,
    coalesce(c.leyes, 0) as leyes,
    100.0 * coalesce(c.rdl, 0) / nullif(coalesce(c.rdl, 0) + coalesce(c.leyes, 0), 0) as pct_rdl,
    coalesce(c.indultos, 0) as indultos,
    p.presidente,
    p.familia,
    k.cambio_de_gobierno,
    a.anio = year(current_date) as anio_en_curso
from anios a
left join conteo c using (anio)
left join principal p using (anio)
left join cambio k using (anio)
order by a.anio
