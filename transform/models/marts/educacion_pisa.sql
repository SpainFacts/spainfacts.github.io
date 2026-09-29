-- Informe PISA de la OCDE, tal como lo publica Eurostat (educ_outc_pisa): % de alumnos de
-- 15 años con bajo rendimiento (por debajo del nivel 2 de competencia) en lectura,
-- matemáticas y ciencias, por sexo, España y UE-27. Una edición cada tres años (la de 2021
-- se aplazó a 2022). España no tiene dato de lectura en 2018: la OCDE no publicó ese
-- resultado por anomalías en las respuestas.
select
    cast(anio as integer) as anio,
    case geo when 'ES' then 'pais' else 'ue' end as nivel,
    case field when 'READ' then 'Lectura' when 'EF461' then 'Matemáticas' when 'SCI' then 'Ciencias' end as materia,
    case sex when 'T' then 'Total' when 'F' then 'Mujeres' when 'M' then 'Hombres' end as sexo,
    valor as pct_bajo_rendimiento
from {{ source('raw_educacion', 'eurostat_edu_pisa') }}
where valor is not null
