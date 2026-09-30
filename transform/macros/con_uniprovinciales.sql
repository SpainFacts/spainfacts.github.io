{#
  Devuelve las filas de `cte` y, además, copia al nivel 'provincia' las filas de
  comunidad de las comunidades con una sola provincia (Asturias, Illes Balears,
  Cantabria, La Rioja, Madrid, Murcia, Navarra) y de Ceuta y Melilla, cuando la
  fuente solo las publica como comunidad. No duplica: si ya hay fila de esa
  provincia con las mismas `claves` (p. ej. anio, categoria), no se copia.

  Uso (al final del modelo):
      with ..., final as (select ...)
      {{ con_uniprovinciales('final', ['anio', 'categoria']) }}
#}
{% macro con_uniprovinciales(cte, claves, nivel_col='nivel', cod_col='cod') %}
select * from {{ cte }}
union all by name
select c.* replace ('provincia' as {{ nivel_col }}, u.cod_prov as {{ cod_col }})
from {{ cte }} c
join (
    select cod_ccaa, min(cod_prov) as cod_prov
    from {{ ref('territorios_provincias') }}
    group by cod_ccaa
    having count(*) = 1
) u on u.cod_ccaa = c.{{ cod_col }}
where c.{{ nivel_col }} = 'ccaa'
  and not exists (
      select 1 from {{ cte }} p
      where p.{{ nivel_col }} = 'provincia' and p.{{ cod_col }} = u.cod_prov
      {%- for k in claves %}
        and p.{{ k }} is not distinct from c.{{ k }}
      {%- endfor %}
  )
{% endmacro %}
