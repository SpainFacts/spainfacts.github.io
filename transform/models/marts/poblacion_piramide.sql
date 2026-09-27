-- Pirámide nacional por grupos quinquenales de edad, sexo y año (1 de enero).
-- Consumido por sources/mother/totalAnoSexoEdad.sql (pages/demografia/estructura-edades).
select
    sexo,
    anio,
    case when edad >= 100 then '100+'
         else concat(floor(edad / 5) * 5, '-', floor(edad / 5) * 5 + 4)
    end as rango_edad,
    case when edad >= 100 then 999 else floor(edad / 5) * 5 end as orden_grupo,
    sum(poblacion) as poblacion
from {{ ref('stg_ine_poblacion') }}
where es_total_nacional
  and not es_todas_las_edades
  and sexo <> 'Total'
group by all
