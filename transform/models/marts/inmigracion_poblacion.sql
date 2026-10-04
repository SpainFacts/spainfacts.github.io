-- Población extranjera residente a 1 de enero por comunidad y en España, y su
-- peso sobre el total (INE, Estadística Continua de Población, tabla 56942).
-- Por NACIONALIDAD: los nacidos fuera que ya tienen la española cuentan como
-- españoles (hay cientos de miles de nacionalizaciones al año).
with base as (
    select anio, cod_ccaa, nacionalidad, poblacion
    from {{ source('raw_criminalidad', 'ine_poblacion_nacionalidad') }}
    where edad = 'Todas las edades' and sexo = 'Total' and poblacion is not null
)

select
    cast(b.anio as integer) as anio,
    case when b.cod_ccaa = '00' then 'pais' else 'ccaa' end as nivel,
    b.cod_ccaa as cod,
    t.nombre,
    max(poblacion) filter (where nacionalidad = 'Total') as poblacion,
    max(poblacion) filter (where nacionalidad = 'Española') as espanoles,
    max(poblacion) filter (where nacionalidad = 'Extranjera') as extranjeros,
    100.0 * max(poblacion) filter (where nacionalidad = 'Extranjera') / max(poblacion) filter (where nacionalidad = 'Total') as extranjeros_pct,
    max(poblacion) filter (where nacionalidad like 'País de la UE27%') as ue,
    max(poblacion) filter (where nacionalidad like 'País de Europa menos UE27%') as resto_europa,
    max(poblacion) filter (where nacionalidad = 'De Africa') as africa,
    max(poblacion) filter (where nacionalidad = 'De América del Norte') as america_norte,
    max(poblacion) filter (where nacionalidad = 'De Centro América y Caribe') as centroamerica_caribe,
    max(poblacion) filter (where nacionalidad = 'De Sudamérica') as sudamerica,
    max(poblacion) filter (where nacionalidad = 'De Asia') as asia
from base b
left join {{ ref('territorios') }} t on t.nivel = case when b.cod_ccaa = '00' then 'pais' else 'ccaa' end and t.cod = b.cod_ccaa
group by all
