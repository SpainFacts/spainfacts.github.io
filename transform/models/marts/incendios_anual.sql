-- Superficie quemada y número de incendios por año (EFFIS), con la parte en
-- Red Natura 2000, el reparto por cubierta y el acumulado "hasta la misma
-- fecha" para comparar el año en curso con años anteriores en igualdad de días.
with base as (
    select * from {{ ref('stg_effis_areas_quemadas') }}
),

hoy as (
    -- Día del año de referencia: el del último incendio cartografiado (o hoy)
    select
        (select max(fecha) from base) as ultima_fecha,
        dayofyear((select max(fecha) from base)) as dia_corte,
        (select max(anio) from base) as anio_actual
)

select
    b.anio,
    count(*) as n_incendios,
    round(sum(b.area_ha), 0) as ha_quemadas,
    round(sum(b.area_ha * b.pct_natura2000 / 100), 0) as ha_natura2000,
    round(100 * sum(b.area_ha * b.pct_natura2000 / 100) / sum(b.area_ha), 1) as pct_natura2000,
    round(sum(b.area_ha * (b.pct_frondosas + b.pct_coniferas + b.pct_bosque_mixto) / 100), 0) as ha_arbolado,
    round(sum(b.area_ha * (b.pct_esclerofila + b.pct_matorral_transicion) / 100), 0) as ha_matorral,
    round(sum(b.area_ha * b.pct_otra_natural / 100), 0) as ha_otra_natural,
    round(sum(b.area_ha * b.pct_agricola / 100), 0) as ha_agricola,
    round(sum(b.area_ha * (b.pct_artificial + b.pct_otras) / 100), 0) as ha_otras,
    count(*) filter (where b.area_ha >= 500) as n_grandes_incendios,
    round(max(b.area_ha), 0) as ha_mayor_incendio,
    -- Acumulado hasta el mismo día del año que el último dato disponible
    count(*) filter (where dayofyear(b.fecha) <= h.dia_corte) as n_incendios_misma_fecha,
    round(coalesce(sum(b.area_ha) filter (where dayofyear(b.fecha) <= h.dia_corte), 0), 0) as ha_misma_fecha,
    h.ultima_fecha,
    b.anio = h.anio_actual as es_anio_actual
from base b
cross join hoy h
group by b.anio, h.ultima_fecha, h.dia_corte, h.anio_actual
order by b.anio
