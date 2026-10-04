-- Adquisiciones de la nacionalidad española por año, comunidad de residencia y
-- nacionalidad previa (INE, Estadística de Adquisiciones de Nacionalidad
-- Española de Residentes, tabla 70012), con la tasa por 1.000 extranjeros
-- residentes a 1 de enero del mismo año. es_grupo = agregado (Total, continentes, UE...) frente
-- a país concreto: no sumar grupos con países.
with base as (
    select
        anyo as anio,
        split_part(serie, '. ', 1) as sexo,
        case when split_part(serie, '. ', 2) = 'Total Nacional' then 'Total Nacional' else split_part(serie, '. ', 3) end as territorio,
        split_part(serie, '. ', 4) as nacionalidad_previa,
        valor as nacionalizaciones
    from {{ source('raw_migracion', 'ine_nacionalizaciones') }}
    where valor is not null
),

extranjeros as (
    select anio, cod, extranjeros from {{ ref('inmigracion_poblacion') }}
)

select
    b.anio,
    case when n.cod_ccaa = '00' then 'pais' else 'ccaa' end as nivel,
    n.cod_ccaa as cod,
    t.nombre,
    b.nacionalidad_previa,
    (b.nacionalidad_previa like 'De %' or b.nacionalidad_previa like 'País de%' or b.nacionalidad_previa like 'Resto%'
        or b.nacionalidad_previa like 'Otro%' or b.nacionalidad_previa = 'Total') as es_grupo,
    b.nacionalizaciones,
    1000.0 * b.nacionalizaciones / nullif(e.extranjeros, 0) as por_1000_extranjeros
from base b
join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = b.territorio
left join {{ ref('territorios') }} t on t.nivel = case when n.cod_ccaa = '00' then 'pais' else 'ccaa' end and t.cod = n.cod_ccaa
left join extranjeros e on e.anio = b.anio and e.cod = n.cod_ccaa and b.nacionalidad_previa = 'Total'
where b.sexo = 'Total'
