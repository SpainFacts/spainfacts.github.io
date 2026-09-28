{{ config(materialized='table') }}
-- Mejor valor de cada día para cada métrica de récord, sistema y periodo:
--   '5 min' -> valor instantáneo (curva de 5 minutos de REE)
--   'hora'  -> media horaria
--   'día'   -> energía (GWh), cuota o media del día completo
-- Es la base de electricidad_records y electricidad_records_historia.
--
-- Calidad ('5 min'): se descartan los picos aislados (ver es_pico) y los instantes con demanda <= 0 o cuyo balance
-- no cuadra (|demanda - generación - intercambios - enlace + consumos| > 5 % de la
-- demanda + 20 MW): son saltos o huecos puntuales de la fuente que, si no, se colarían
-- como récords. En 'hora' se exigen al menos 10 de 12 intervalos y en 'día' el día completo.
{% set metricas = [
    {'c': 'demanda_max', 'cat': 'Demanda máxima', 'dir': 'max', 'x': 'demanda_mw', 'd': 'demanda_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': None},
    {'c': 'demanda_min', 'cat': 'Demanda mínima', 'dir': 'min', 'x': 'demanda_mw', 'd': 'demanda_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': None},
    {'c': 'renovable_max', 'cat': 'Generación renovable máxima', 'dir': 'max', 'x': 'renovable_mw', 'd': 'renovable_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': None},
    {'c': 'pct_renovable_max', 'cat': 'Cuota renovable máxima', 'dir': 'max', 'x': 'pct_renovable', 'd': 'pct_renovable', 'u': '%', 'ud': '%', 's': None},
    {'c': 'eolica_max', 'cat': 'Eólica máxima', 'dir': 'max', 'x': 'eolica', 'd': 'eolica_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': None},
    {'c': 'pct_eolica_max', 'cat': 'Cuota eólica máxima', 'dir': 'max', 'x': 'case when generacion_total_mw > 0 then 100 * eolica / generacion_total_mw end', 'd': 'case when generacion_total_mwh > 0 then 100 * eolica_mwh / generacion_total_mwh end', 'u': '%', 'ud': '%', 's': None},
    {'c': 'solar_fv_max', 'cat': 'Solar fotovoltaica máxima', 'dir': 'max', 'x': 'solar_fv', 'd': 'solar_fv_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': None},
    {'c': 'pct_solar_max', 'cat': 'Cuota solar máxima', 'dir': 'max', 'x': 'case when generacion_total_mw > 0 then 100 * (solar_fv + solar_termica) / generacion_total_mw end', 'd': 'case when generacion_total_mwh > 0 then 100 * (solar_fv_mwh + solar_termica_mwh) / generacion_total_mwh end', 'u': '%', 'ud': '%', 's': None},
    {'c': 'solar_termica_max', 'cat': 'Solar térmica máxima', 'dir': 'max', 'x': 'solar_termica', 'd': 'solar_termica_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'peninsula'},
    {'c': 'hidraulica_max', 'cat': 'Hidráulica máxima', 'dir': 'max', 'x': 'hidraulica', 'd': 'hidraulica_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'peninsula'},
    {'c': 'nuclear_max', 'cat': 'Nuclear máxima', 'dir': 'max', 'x': 'nuclear', 'd': 'nuclear_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'peninsula'},
    {'c': 'ciclo_combinado_max', 'cat': 'Ciclo combinado máximo', 'dir': 'max', 'x': 'ciclo_combinado', 'd': 'ciclo_combinado_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': None},
    {'c': 'intensidad_min', 'cat': 'Intensidad de CO2 mínima', 'dir': 'min', 'x': 'intensidad_gco2_kwh', 'd': 'intensidad_gco2_kwh', 'u': 'g CO2/kWh', 'ud': 'g CO2/kWh', 's': None},
    {'c': 'emisiones_min', 'cat': 'Emisiones de CO2 mínimas', 'dir': 'min', 'x': 'co2_t_h', 'd': 'co2_t', 'u': 't CO2/h', 'ud': 't CO2', 's': None},
    {'c': 'baterias_descarga_max', 'cat': 'Descarga de baterías máxima', 'dir': 'max', 'x': 'nullif(baterias_descarga, 0)', 'd': 'nullif(baterias_descarga_mwh, 0) / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'peninsula'},
    {'c': 'baterias_carga_max', 'cat': 'Carga de baterías máxima', 'dir': 'max', 'x': 'nullif(baterias_carga, 0)', 'd': 'nullif(baterias_carga_mwh, 0) / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'peninsula'},
    {'c': 'consumo_bombeo_max', 'cat': 'Consumo de bombeo máximo', 'dir': 'max', 'x': 'consumo_bombeo', 'd': 'consumo_bombeo_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'peninsula'},
    {'c': 'turbinacion_bombeo_max', 'cat': 'Turbinación de bombeo máxima', 'dir': 'max', 'x': 'turbinacion_bombeo', 'd': 'turbinacion_bombeo_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'peninsula'},
    {'c': 'importacion_neta_max', 'cat': 'Importación neta máxima', 'dir': 'max', 'x': 'intercambio_neto', 'd': 'intercambio_neto_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'peninsula'},
    {'c': 'exportacion_neta_max', 'cat': 'Exportación neta máxima', 'dir': 'max', 'x': '-intercambio_neto', 'd': '-intercambio_neto_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'peninsula'},
    {'c': 'imp_francia_max', 'cat': 'Importación máxima desde Francia', 'dir': 'max', 'x': 'imp_francia', 'd': 'imp_francia_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'peninsula'},
    {'c': 'exp_francia_max', 'cat': 'Exportación máxima a Francia', 'dir': 'max', 'x': 'exp_francia', 'd': 'exp_francia_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'peninsula'},
    {'c': 'imp_portugal_max', 'cat': 'Importación máxima desde Portugal', 'dir': 'max', 'x': 'imp_portugal', 'd': 'imp_portugal_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'peninsula'},
    {'c': 'exp_portugal_max', 'cat': 'Exportación máxima a Portugal', 'dir': 'max', 'x': 'exp_portugal', 'd': 'exp_portugal_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'peninsula'},
    {'c': 'imp_marruecos_max', 'cat': 'Importación máxima desde Marruecos', 'dir': 'max', 'x': 'imp_marruecos', 'd': 'imp_marruecos_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'peninsula'},
    {'c': 'exp_marruecos_max', 'cat': 'Exportación máxima a Marruecos', 'dir': 'max', 'x': 'exp_marruecos', 'd': 'exp_marruecos_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'peninsula'},
    {'c': 'enlace_baleares_max', 'cat': 'Envío máximo por el enlace Península-Baleares', 'dir': 'max', 'x': 'enlace_baleares', 'd': 'enlace_baleares_mwh / 1000', 'u': 'MW', 'ud': 'GWh', 's': 'baleares'},
    {'c': 'precio_max', 'cat': 'Precio máximo', 'dir': 'max', 'x': None, 'h': 'precio_spot_eur_mwh', 'd': 'precio_spot_medio_eur_mwh', 'u': '€/MWh', 'ud': '€/MWh', 's': 'peninsula'},
    {'c': 'precio_min', 'cat': 'Precio mínimo', 'dir': 'min', 'x': None, 'h': 'precio_spot_eur_mwh', 'd': 'precio_spot_medio_eur_mwh', 'u': '€/MWh', 'ud': '€/MWh', 's': 'peninsula'},
] %}

{% set picos = ['demanda_mw', 'eolica', 'solar_fv', 'solar_termica', 'hidraulica', 'nuclear', 'carbon',
                 'ciclo_combinado', 'turbinacion_bombeo', 'consumo_bombeo', 'intercambio_neto', 'generacion_total_mw'] %}
-- Apagón ibérico del 28/04/2025 (12:33) y su recuperación: no son récords de
-- demanda mínima ni de cuota renovable, se excluyen en la península.
{% set apagon = "not (sistema = 'peninsula' and fecha between date '2025-04-28' and date '2025-04-29')" %}

with base5 as (
    select
        *,
        cast(left(ts_local, 10) as date) as fecha,
        -- pico aislado: el valor se separa del punto medio de sus dos vecinos más de un
        -- 25 % (y más de un 4 % de la demanda); son errores puntuales de la fuente
        -- (p. ej. hidráulica de 19 GW compensada con un bombeo de 17 GW el 17/07/2024)
        (
            {% for c in picos %}
            coalesce(abs({{ c }} - (lag({{ c }}) over w + lead({{ c }}) over w) / 2)
                > greatest(0.25 * abs((lag({{ c }}) over w + lead({{ c }}) over w) / 2), 0.04 * demanda_mw), false)
            {{ 'or' if not loop.last }}
            {% endfor %}
        ) as es_pico
    from {{ ref('electricidad_5min') }}
    window w as (partition by sistema order by ts_utc)
),

cinco as (
    select * from base5
    where demanda_mw > 0
      and not es_pico
      and {{ apagon }}
      and abs(
          demanda_mw - generacion_total_mw - coalesce(intercambio_neto, 0)
          - case sistema when 'peninsula' then -coalesce(enlace_baleares, 0) when 'baleares' then coalesce(enlace_baleares, 0) else 0 end
          + coalesce(consumo_bombeo, 0) + baterias_carga
      ) <= 0.05 * demanda_mw + 20
),

-- Horas y días se recalculan con los instantes limpios de `cinco` (así un tramo
-- erróneo de la fuente no contamina la media); intercambios por frontera (con ESIOS)
-- y precios salen de electricidad_horaria / electricidad_diaria.
{% set medias = ['demanda_mw', 'eolica', 'solar_fv', 'solar_termica', 'hidraulica', 'nuclear', 'carbon',
                 'ciclo_combinado', 'turbinacion_bombeo', 'consumo_bombeo', 'baterias_descarga', 'baterias_carga',
                 'intercambio_neto', 'enlace_baleares', 'generacion_total_mw', 'renovable_mw', 'co2_t_h'] %}
{% set fronteras = ['imp_francia', 'exp_francia', 'imp_portugal', 'exp_portugal', 'imp_marruecos',
                    'exp_marruecos', 'imp_andorra', 'exp_andorra'] %}
hora_limpia as (
    select
        sistema,
        date_trunc('hour', ts_utc) as hora_utc,
        min(ts_local) as primer_ts_local,
        {% for c in medias %}avg({{ c }}) as {{ c }}{{ ',' if not loop.last }}
        {% endfor %}
    from cinco
    group by all
    having count(*) >= 10
),

hora as (
    select
        l.*,
        cast(left(l.primer_ts_local, 10) as date) as fecha,
        left(l.primer_ts_local, 13) || ':00' as ts_local,
        case when l.generacion_total_mw > 0 then least(greatest(100 * l.renovable_mw / l.generacion_total_mw, 0), 100) end as pct_renovable,
        case when l.generacion_total_mw > 0 then 1000 * l.co2_t_h / l.generacion_total_mw end as intensidad_gco2_kwh,
        {% for c in fronteras %}h.{{ c }},
        {% endfor %}
        h.precio_spot_eur_mwh
    from hora_limpia as l
    left join {{ ref('electricidad_horaria') }} as h using (sistema, hora_utc)
),

dia_limpio as (
    select
        sistema,
        fecha,
        count(*) as n_limpios,
        {% for c in medias %}{% set dst = c[:-3] if c.endswith('_mw') else c %}sum({{ c }}) * 5 / 60 as {{ 'co2_t' if c == 'co2_t_h' else dst ~ '_mwh' }}{{ ',' if not loop.last }}
        {% endfor %}
    from cinco
    group by all
),

dia as (
    select
        d.sistema,
        d.fecha,
        strftime(d.fecha, '%Y-%m-%d') as ts_local,
        -- energía escalada a todo el día (los instantes descartados son < 10 %)
        {% for c in medias %}{% set dst = 'co2_t' if c == 'co2_t_h' else (c[:-3] if c.endswith('_mw') else c) ~ '_mwh' %}l.{{ dst }} * d.n_intervalos / l.n_limpios as {{ dst }},
        {% endfor %}
        case when l.generacion_total_mwh > 0 then least(greatest(100 * l.renovable_mwh / l.generacion_total_mwh, 0), 100) end as pct_renovable,
        case when l.generacion_total_mwh > 0 then 1000 * l.co2_t / l.generacion_total_mwh end as intensidad_gco2_kwh,
        {% for c in fronteras %}d.{{ c }}_mwh,
        {% endfor %}
        d.precio_spot_medio_eur_mwh
    from {{ ref('electricidad_diaria') }} as d
    join dia_limpio as l using (sistema, fecha)
    where d.completo
      and l.n_limpios >= 0.9 * d.n_intervalos
),

-- una pasada por periodo con todas las métricas como columnas
a5 as (
    select
        sistema, fecha,
        {% for m in metricas if m.x %}
        {{ m.dir }}({{ m.x }}) as v_{{ m.c }},
        arg_{{ m.dir }}(ts_local, {{ m.x }}) as t_{{ m.c }},
        arg_{{ m.dir }}(ts_utc, {{ m.x }}) as u_{{ m.c }}{{ ',' if not loop.last }}
        {% endfor %}
    from cinco
    group by all
),

ah as (
    select
        sistema, fecha,
        {% for m in metricas %}
        {% set e = m.h if m.h is defined else m.x %}
        {{ m.dir }}({{ e }}) as v_{{ m.c }},
        arg_{{ m.dir }}(ts_local, {{ e }}) as t_{{ m.c }},
        arg_{{ m.dir }}(hora_utc, {{ e }}) as u_{{ m.c }}{{ ',' if not loop.last }}
        {% endfor %}
    from hora
    group by all
),

todas as (
    {% for m in metricas %}
    {% if m.x %}
    select sistema, fecha, '{{ m.c }}' as codigo, '5 min' as periodo, v_{{ m.c }} as valor, t_{{ m.c }} as ts_local, u_{{ m.c }} as ts_utc
    from a5 where v_{{ m.c }} is not null {% if m.s %}and sistema = '{{ m.s }}'{% endif %}
    union all
    {% endif %}
    select sistema, fecha, '{{ m.c }}', 'hora', v_{{ m.c }}, t_{{ m.c }}, u_{{ m.c }}
    from ah where v_{{ m.c }} is not null {% if m.s %}and sistema = '{{ m.s }}'{% endif %}
    union all
    select sistema, fecha, '{{ m.c }}', 'día', {{ m.d }}, ts_local, null::timestamptz
    from dia where ({{ m.d }}) is not null {% if m.s %}and sistema = '{{ m.s }}'{% endif %}
    {{ 'union all' if not loop.last }}
    {% endfor %}
),

meta as (
    select * from (values
    {% for m in metricas %}
        ('{{ m.c }}', '{{ m.cat }}', '{{ m.dir }}', '{{ m.u }}', '{{ m.ud }}', {{ loop.index }}){{ ',' if not loop.last }}
    {% endfor %}
    ) as t(codigo, categoria, sentido, unidad, unidad_dia, orden)
)

select
    t.codigo,
    m.categoria,
    m.sentido,
    t.sistema,
    t.periodo,
    t.fecha,
    t.valor,
    case when t.periodo = 'día' then m.unidad_dia else m.unidad end as unidad,
    t.ts_local,
    t.ts_utc,
    m.orden
from todas as t
join meta as m using (codigo)
-- un máximo de 0 (p. ej. eólica en Baleares) no es un récord
where not (m.sentido = 'max' and t.valor <= 0 and t.codigo not like 'precio%')
