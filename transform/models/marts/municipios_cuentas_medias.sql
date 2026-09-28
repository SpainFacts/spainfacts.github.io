-- Referencias para comparar un ayuntamiento con los de su tamaño: por año y
-- tramo de población, mediana y media ponderada (suma de euros / suma de
-- habitantes) del gasto e ingreso por habitante, y mediana por habitante de
-- cada capítulo y área de gasto. Solo municipios con datos (tiene_datos).
-- tramo 'Todos' (tramo_orden 0) = todos los municipios con datos.
{%- set tramos = [
    ('<1.000', 1, 0, 1000),
    ('1.000-5.000', 2, 1000, 5000),
    ('5.000-20.000', 3, 5000, 20000),
    ('20.000-50.000', 4, 20000, 50000),
    ('50.000-100.000', 5, 50000, 100000),
    ('100.000-500.000', 6, 100000, 500000),
    ('>500.000', 7, 500000, 1000000000),
] %}
{%- set medidas = [] %}
{%- for c in range(1, 10) %}{% do medidas.append('ingresos_c' ~ c) %}{% endfor %}
{%- for c in range(1, 10) %}{% do medidas.append('gastos_c' ~ c) %}{% endfor %}
{%- for a in [0, 1, 2, 3, 4, 9] %}{% do medidas.append('gasto_area_' ~ a) %}{% endfor %}
with datos as (
    select
        *,
        case
        {%- for nombre, orden, desde, hasta in tramos %}
            when poblacion >= {{ desde }} and poblacion < {{ hasta }} then '{{ nombre }}'
        {%- endfor %}
        end as tramo_poblacion
    from {{ ref('municipios_cuentas') }}
    where tiene_datos and poblacion > 0
),

con_todos as (
    select * from datos
    union all
    select * replace ('Todos' as tramo_poblacion) from datos
)

select
    anio,
    tramo_poblacion,
    case tramo_poblacion
        when 'Todos' then 0
        {%- for nombre, orden, desde, hasta in tramos %}
        when '{{ nombre }}' then {{ orden }}
        {%- endfor %}
    end as tramo_orden,
    bool_or(provisional) as provisional,
    count(*) as n_municipios,
    sum(poblacion) as poblacion,
    round(median(gasto_hab), 2) as gasto_hab_mediana,
    round(sum(gastos_total) / sum(poblacion), 2) as gasto_hab_media,
    round(median(ingreso_hab), 2) as ingreso_hab_mediana,
    round(sum(ingresos_total) / sum(poblacion), 2) as ingreso_hab_media,
    round(median(gastos_no_financieros / poblacion), 2) as gastos_no_financieros_hab_mediana,
    round(median(ingresos_no_financieros / poblacion), 2) as ingresos_no_financieros_hab_mediana,
    round(median(saldo_no_financiero / poblacion), 2) as saldo_no_financiero_hab_mediana,
    {%- for m in medidas %}
    round(median({{ m }} / poblacion), 2) as {{ m }}_hab_mediana,
    {%- endfor %}
    anio || '-' || tramo_poblacion as clave
from con_todos
group by anio, tramo_poblacion
order by anio, tramo_orden
