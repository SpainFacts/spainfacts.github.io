-- Potencia que entró en servicio y que se retiró cada año, por tecnología y
-- comunidad autónoma (para que la página pueda filtrar por CCAA).
-- Altas: unidades construidas (en operación, retiradas o en reserva) por año de
-- puesta en marcha; las que no tienen año (sobre todo fotovoltaica y eólica
-- pequeñas, ~8 GW en operación) no entran. Bajas: unidades retiradas por año de
-- cierre. Además, la potencia en construcción por año previsto de entrada.
with u as (
    select * from {{ ref('stg_gem_centrales') }}
),

movimientos as (
    select anio_inicio as anio, tecnologia, cod_ccaa, ccaa,
           potencia_mw as mw_alta, 0.0 as mw_baja, 0.0 as mw_en_construccion
    from u
    where estado_gem in ('operating', 'retired', 'mothballed') and anio_inicio is not null
    union all
    select anio_retiro, tecnologia, cod_ccaa, ccaa, 0.0, potencia_mw, 0.0
    from u
    where estado_gem = 'retired' and anio_retiro is not null
    union all
    select anio_inicio, tecnologia, cod_ccaa, ccaa, 0.0, 0.0, potencia_mw
    from u
    where estado_gem = 'construction' and anio_inicio is not null
),

agregado as (
    select
        anio, tecnologia, cod_ccaa, ccaa,
        coalesce(sum(mw_alta), 0) as mw_alta,
        coalesce(sum(mw_baja), 0) as mw_baja,
        coalesce(sum(mw_en_construccion), 0) as mw_en_construccion
    from movimientos
    group by all
)

select
    a.anio,
    a.tecnologia,
    t.color,
    t.orden as orden_tecnologia,
    t.renovable,
    a.cod_ccaa,
    a.ccaa,
    round(a.mw_alta, 1) as mw_alta,
    round(a.mw_baja, 1) as mw_baja,
    round(a.mw_alta - a.mw_baja, 1) as mw_neta,
    round(a.mw_en_construccion, 1) as mw_en_construccion
from agregado a
left join {{ ref('tecnologias_electricas') }} t on t.tecnologia = a.tecnologia
order by anio, orden_tecnologia, cod_ccaa
