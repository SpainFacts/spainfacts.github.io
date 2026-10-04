-- Delitos por los que se condena en España por tipo de delito y nacionalidad
-- del condenado (INE, Estadística de Condenados, tabla 49050). Una persona
-- condenada por varios delitos cuenta una vez por cada delito.
-- Los delitos forman un árbol (seed crimen_delitos_jerarquia): «Delitos» es el total, y cada
-- nivel suma el del padre; sumar solo dentro de un mismo nivel_delito.
-- *_por_100k_hab: delitos por 100.000 habitantes del mismo grupo (población total de España, o
-- solo la española / extranjera, a 1 de enero del año; INE 56942). Los condenados extranjeros
-- incluyen personas que no residen en España, lo que eleva la tasa de extranjeros.
with base as (
    select
        anyo as anio,
        split_part(serie, '. ', 3) as delito,
        split_part(serie, '. ', 4) as nacionalidad,
        valor as delitos
    from {{ source('raw_criminalidad', 'ine_condenados_delitos_nacionalidad') }}
    where serie like 'Total Nacional. Dato base.%' and valor is not null
),

por_delito as (
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
),

poblacion as (
    select
        anio,
        max(poblacion) filter (where nacionalidad = 'Total') as total,
        max(poblacion) filter (where nacionalidad = 'Española') as espanola,
        max(poblacion) filter (where nacionalidad = 'Extranjera') as extranjera
    from {{ source('raw_criminalidad', 'ine_poblacion_nacionalidad') }}
    where cod_ccaa = '00' and sexo = 'Total' and edad = 'Todas las edades'
    group by anio
)

select
    d.anio,
    d.delito,
    j.nivel_delito,
    j.delito_padre,
    d.total,
    d.espanola,
    d.extranjera,
    d.ue,
    d.resto_europa,
    d.africa,
    d.america,
    d.asia,
    100000.0 * d.total / nullif(p.total, 0) as total_por_100k_hab,
    100000.0 * d.espanola / nullif(p.espanola, 0) as espanola_por_100k_hab,
    100000.0 * d.extranjera / nullif(p.extranjera, 0) as extranjera_por_100k_hab
from por_delito d
left join {{ ref('crimen_delitos_jerarquia') }} j on j.delito = d.delito
left join poblacion p on p.anio = d.anio
