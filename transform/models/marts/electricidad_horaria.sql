{{ config(materialized='table') }}
-- Medias horarias (MW) por sistema a partir de electricidad_5min, más el precio
-- spot medio de la hora (mercado diario peninsular, €/MWh; solo península).
-- hora_utc agrupa los 12 intervalos de 5 minutos de cada hora; hora_local es la
-- hora local del sistema (Canarias en hora canaria). n_intervalos < 12 indica
-- huecos en la fuente.
-- Intercambios por frontera: el visor de 5 minutos solo los desglosa desde finales
-- de 2024; antes se completan con el saldo neto telemedido de ESIOS (indicadores
-- 10207-10209; Andorra, 10047 de liquidación), repartido en importación (saldo > 0) o exportación (saldo < 0).
-- fuente_fronteras indica de dónde sale cada hora ('visor' o 'esios').
{% set cols = ['demanda_mw', 'eolica', 'solar_fv', 'solar_termica', 'hidraulica', 'nuclear', 'carbon',
               'ciclo_combinado', 'cogeneracion_residuos', 'turbinacion_bombeo', 'consumo_bombeo',
               'baterias_descarga', 'baterias_carga', 'diesel', 'turbina_gas', 'motores_vapor',
               'otras_renovables', 'otras_no_renovables', 'intercambio_neto',
               'enlace_baleares', 'generacion_total_mw', 'renovable_mw', 'co2_t_h'] %}
{% set paises = ['francia', 'portugal', 'marruecos', 'andorra'] %}
with h as (
    select
        sistema,
        date_trunc('hour', ts_utc) as hora_utc,
        min(ts_local) as primer_ts_local,
        count(*) as n_intervalos,
        {% for c in cols %}avg({{ c }}) as {{ c }},
        {% endfor %}
        {% for p in paises %}avg(imp_{{ p }}) as imp_{{ p }}, avg(exp_{{ p }}) as exp_{{ p }}{{ ',' if not loop.last }}
        {% endfor %}
    from {{ ref('electricidad_5min') }}
    group by all
),

esios_h as (
    select frontera, date_trunc('hour', ts_utc) as hora_utc, avg(saldo_mw) as saldo
    from {{ source('raw_ree_visiona', 'esios_intercambios') }}
    group by all
),

-- ESIOS tiene horas sueltas con el valor duplicado (p. ej. 01/08/2018 12:00, el doble
-- que las horas vecinas): se descarta la hora que se separa más de un 40 % y de 300 MW
-- del punto medio de sus vecinas
esios_ok as (
    select *,
        abs(saldo - (lag(saldo) over w + lead(saldo) over w) / 2) > greatest(0.4 * abs((lag(saldo) over w + lead(saldo) over w) / 2), 300) as es_pico
    from esios_h
    window w as (partition by frontera order by hora_utc)
),

esios as (
    select
        hora_utc,
        {% for p in paises %}avg(case when frontera = '{{ p }}' and not coalesce(es_pico, false) then saldo end) as saldo_{{ p }}{{ ',' if not loop.last }}
        {% endfor %}
    from esios_ok
    group by all
),

precio as (
    select date_trunc('hour', ts_utc) as hora_utc, avg(precio_eur_mwh) as precio_spot_eur_mwh
    from {{ source('raw_ree_visiona', 'ree_precios') }}
    where indicador = 'Precio mercado spot'
    group by all
)

select
    h.sistema,
    h.hora_utc,
    left(h.primer_ts_local, 13) || ':00' as hora_local,
    h.n_intervalos,
    {% for c in cols %}h.{{ c }},
    {% endfor %}
    {% for p in paises %}
    case when h.sistema = 'peninsula' then coalesce(h.imp_{{ p }}, greatest(e.saldo_{{ p }}, 0)) end as imp_{{ p }},
    case when h.sistema = 'peninsula' then coalesce(h.exp_{{ p }}, greatest(-e.saldo_{{ p }}, 0)) end as exp_{{ p }},
    {% endfor %}
    case
        when h.sistema <> 'peninsula' then null
        when h.imp_francia is not null then 'visor'
        when e.saldo_francia is not null then 'esios'
    end as fuente_fronteras,
    case when h.generacion_total_mw > 0 then least(greatest(100 * h.renovable_mw / h.generacion_total_mw, 0), 100) end as pct_renovable,
    case when h.generacion_total_mw > 0 then 1000 * h.co2_t_h / h.generacion_total_mw end as intensidad_gco2_kwh,
    case when h.sistema = 'peninsula' then p.precio_spot_eur_mwh end as precio_spot_eur_mwh
from h
left join esios as e on e.hora_utc = h.hora_utc
left join precio as p on p.hora_utc = h.hora_utc
