-- Delitos por los que se condena en España por tipo de delito y nacionalidad
-- del condenado (INE, Estadística de Condenados, tabla 49050). Una persona
-- condenada por varios delitos cuenta una vez por cada delito.
with base as (
    select
        anyo as anio,
        split_part(serie, '. ', 3) as delito,
        split_part(serie, '. ', 4) as nacionalidad,
        valor as delitos
    from {{ source('raw_criminalidad', 'ine_condenados_delitos_nacionalidad') }}
    where serie like 'Total Nacional. Dato base.%' and valor is not null
)
select
    anio,
    delito,
    max(delitos) filter (where nacionalidad = 'Total') as total,
    max(delitos) filter (where nacionalidad = 'Española') as espanola,
    max(delitos) filter (where nacionalidad = 'Total') - max(delitos) filter (where nacionalidad = 'Española') as extranjera,
    max(delitos) filter (where nacionalidad like '%UE27%') as ue,
    max(delitos) filter (where nacionalidad like '%Europa menos UE27%') as resto_europa,
    max(delitos) filter (where nacionalidad = 'De Africa') as africa,
    max(delitos) filter (where nacionalidad = 'De América') as america,
    max(delitos) filter (where nacionalidad = 'De Asia') as asia
from base
group by all
