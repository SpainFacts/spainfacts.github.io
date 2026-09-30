-- Decretos-ley, leyes e indultos por presidencia del Gobierno y por partido,
-- normalizados por el tiempo gobernado (desde el 5 de julio de 1977).
--   *_por_anio        media anual durante el mandato
--   *_esperados       los que le tocarían si todos los Gobiernos hubieran usado
--                     la herramienta al mismo ritmo: total x (días gobernados / días totales)
--   *_ratio           observados / esperados (1 = lo esperable; 2 = el doble)
--   *_z               distancia al esperado en desviaciones típicas (binomial,
--                     aproximación normal); |z| > 1,96 = diferencia mayor de lo
--                     que explicaría el azar si el ritmo fuera constante
-- Cautela: el ritmo NO es constante (el uso del decreto-ley crece con los años),
-- así que la comparación favorece a los primeros Gobiernos; ver la página.
with presidencias as (
    select
        presidente,
        familia,
        orden,
        greatest(desde, date '1977-07-05') as desde,
        coalesce(hasta, current_date + 1) as hasta
    from {{ ref('stg_presidencias_gobierno') }}
),

actos as (
    select a.tipo, p.presidente, p.familia
    from {{ ref('stg_boe_actos_gobierno') }} a
    join presidencias p on a.fecha_disposicion >= p.desde and a.fecha_disposicion < p.hasta
    where a.tipo in ('real_decreto_ley', 'ley', 'ley_presupuestos', 'indulto')
    qualify a.tipo = 'indulto'
        or row_number() over (partition by a.serie_numeracion, a.anio_numero, a.numero
                              order by a.fecha_publicacion, a.identificador) = 1
),

derogados as (
    select presidente, count(*) as rdl_derogados
    from {{ ref('gobierno_decretos_ley') }}
    where estado = 'Derogado'
    group by presidente
),

por_presidente as (
    select
        'Presidente' as nivel,
        p.presidente as grupo,
        p.familia,
        min(p.orden) as orden,
        min(p.desde) as desde,
        max(p.hasta) as hasta,
        sum(date_diff('day', p.desde, p.hasta)) as dias
    from presidencias p
    group by p.presidente, p.familia
),

por_partido as (
    select
        'Partido' as nivel,
        familia as grupo,
        familia,
        min(orden) as orden,
        min(desde) as desde,
        max(hasta) as hasta,
        sum(date_diff('day', desde, hasta)) as dias
    from presidencias
    group by familia
),

grupos as (
    select * from por_presidente
    union all
    select * from por_partido
),

conteos as (
    select
        g.nivel,
        g.grupo,
        count(*) filter (where a.tipo = 'real_decreto_ley') as rdl,
        count(*) filter (where a.tipo in ('ley', 'ley_presupuestos')) as leyes,
        count(*) filter (where a.tipo = 'indulto') as indultos
    from grupos g
    join actos a on (g.nivel = 'Presidente' and a.presidente = g.grupo) or (g.nivel = 'Partido' and a.familia = g.grupo)
    group by g.nivel, g.grupo
),

totales as (
    select
        count(*) filter (where tipo = 'real_decreto_ley') as rdl_total,
        count(*) filter (where tipo = 'indulto') as indultos_total
    from actos
),

base as (
    select
        g.*,
        g.dias / 365.25 as anios,
        g.dias / sum(g.dias) over (partition by g.nivel) as cuota,
        coalesce(c.rdl, 0) as rdl,
        coalesce(c.leyes, 0) as leyes,
        coalesce(c.indultos, 0) as indultos,
        t.rdl_total,
        t.indultos_total
    from grupos g
    left join conteos c using (nivel, grupo)
    cross join totales t
)

select
    b.nivel,
    b.grupo,
    b.familia,
    b.orden,
    b.desde,
    case when b.hasta > current_date then null else b.hasta end as hasta,
    b.anios,
    b.cuota,
    b.rdl,
    b.rdl / b.anios as rdl_por_anio,
    b.leyes,
    b.leyes / b.anios as leyes_por_anio,
    100.0 * b.rdl / nullif(b.rdl + b.leyes, 0) as pct_rdl,
    coalesce(d.rdl_derogados, 0) as rdl_derogados,
    b.rdl_total * b.cuota as rdl_esperados,
    b.rdl / nullif(b.rdl_total * b.cuota, 0) as rdl_ratio,
    (b.rdl - b.rdl_total * b.cuota) / sqrt(b.rdl_total * b.cuota * (1 - b.cuota)) as rdl_z,
    b.indultos,
    b.indultos / b.anios as indultos_por_anio,
    b.indultos_total * b.cuota as indultos_esperados,
    b.indultos / nullif(b.indultos_total * b.cuota, 0) as indultos_ratio,
    (b.indultos - b.indultos_total * b.cuota) / sqrt(b.indultos_total * b.cuota * (1 - b.cuota)) as indultos_z
from base b
left join (
    select presidente as grupo, 'Presidente' as nivel, rdl_derogados from derogados
    union all
    select p.familia, 'Partido', sum(d.rdl_derogados)
    from derogados d join (select distinct presidente, familia from presidencias) p using (presidente)
    group by p.familia
) d using (nivel, grupo)
order by b.nivel desc, b.orden
