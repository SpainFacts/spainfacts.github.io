{{ config(materialized='table') }}
-- Energía diaria (MWh) por sistema y tecnología a partir de electricidad_5min
-- (cada intervalo de 5 minutos aporta MW * 5/60 MWh), con la demanda máxima y
-- mínima instantánea del día, la cuota renovable, las emisiones y el precio spot
-- medio (península). fecha = día local del sistema. completo = el día tiene al
-- menos 23 h de datos (276 intervalos; 23 h es la duración del día del cambio de hora).
-- Los intercambios por frontera salen de electricidad_horaria (visor o ESIOS).
{% set cols = ['demanda', 'eolica', 'solar_fv', 'solar_termica', 'hidraulica', 'nuclear', 'carbon',
               'ciclo_combinado', 'cogeneracion_residuos', 'turbinacion_bombeo', 'consumo_bombeo',
               'baterias_descarga', 'baterias_carga', 'diesel', 'turbina_gas', 'motores_vapor',
               'otras_renovables', 'otras_no_renovables', 'intercambio_neto',
               'enlace_baleares', 'generacion_total', 'renovable'] %}
{% set fronteras = ['imp_francia', 'exp_francia', 'imp_portugal', 'exp_portugal', 'imp_marruecos',
                    'exp_marruecos', 'imp_andorra', 'exp_andorra'] %}
with d as (
    select
        sistema,
        cast(left(ts_local, 10) as date) as fecha,
        count(*) as n_intervalos,
        {% for c in cols %}{% set src = c ~ '_mw' if c in ['demanda', 'generacion_total', 'renovable'] else c %}sum({{ src }}) * 5 / 60 as {{ c }}_mwh,
        {% endfor %}
        sum(co2_t_h) * 5 / 60 as co2_t,
        max(demanda_mw) as demanda_max_mw,
        arg_max(ts_local, demanda_mw) as demanda_max_ts_local,
        min(demanda_mw) as demanda_min_mw,
        arg_min(ts_local, demanda_mw) as demanda_min_ts_local
    from {{ ref('electricidad_5min') }}
    group by all
),

-- intercambios por frontera desde la tabla horaria (visor desde finales de 2024,
-- ESIOS antes): MW medios de cada hora = MWh
fr as (
    select
        sistema,
        cast(left(hora_local, 10) as date) as fecha,
        {% for c in fronteras %}sum({{ c }}) as {{ c }}_mwh,
        {% endfor %}
        min(fuente_fronteras) as fuente_fronteras
    from {{ ref('electricidad_horaria') }}
    where sistema = 'peninsula'
    group by all
),

precio as (
    select cast(left(ts_local, 10) as date) as fecha, avg(precio_eur_mwh) as precio_spot_medio_eur_mwh
    from {{ source('raw_ree_visiona', 'ree_precios') }}
    where indicador = 'Precio mercado spot'
    group by all
)

select
    d.*,
    {% for c in fronteras %}fr.{{ c }}_mwh,
    {% endfor %}
    fr.fuente_fronteras,
    d.n_intervalos >= 276 as completo,
    case when d.generacion_total_mwh > 0 then least(greatest(100 * d.renovable_mwh / d.generacion_total_mwh, 0), 100) end as pct_renovable,
    case when d.generacion_total_mwh > 0 then 1000 * d.co2_t / d.generacion_total_mwh end as intensidad_gco2_kwh,
    case when d.sistema = 'peninsula' then p.precio_spot_medio_eur_mwh end as precio_spot_medio_eur_mwh
from d
left join fr on fr.sistema = d.sistema and fr.fecha = d.fecha
left join precio as p on p.fecha = d.fecha
