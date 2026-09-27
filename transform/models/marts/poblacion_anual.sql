-- Población total a 1 de enero por año, ámbito (nacional/provincia) y sexo.
-- Consumido por sources/mother/totalAno*.sql.
select
    anio,
    es_total_nacional,
    cod_prov,
    provincia,
    sexo,
    poblacion
from {{ ref('stg_ine_poblacion') }}
where es_todas_las_edades
