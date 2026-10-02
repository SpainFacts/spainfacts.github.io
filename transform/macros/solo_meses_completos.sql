{#
  Devuelve las filas de la CTE `cte` quitando los meses incompletos: los que tienen menos
  del 80 % de las filas de un mes normal (mediana). Sirve para el IPC adelantado del INE,
  que publica a final de mes solo el índice general (y la energía) sin el desglose por
  grupos o comunidades: ese mes aparecía como «el último» y dejaba vacías las gráficas.

  Uso, al final de un modelo:
      with ..., final as (select ...)
      {{ solo_meses_completos('final') }}
#}
{% macro solo_meses_completos(cte, columna='mes') -%}
, _cobertura_meses as (
    select {{ columna }}, count(*) as _n from {{ cte }} group by {{ columna }}
)
select {{ cte }}.*
from {{ cte }}
join _cobertura_meses using ({{ columna }})
where _cobertura_meses._n >= 0.8 * (select median(_n) from _cobertura_meses)
{%- endmacro %}
