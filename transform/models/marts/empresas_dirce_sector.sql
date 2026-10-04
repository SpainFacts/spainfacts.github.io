-- Empresas activas a 1 de enero por gran sector de actividad, España y comunidades,
-- desde 2020 (INE, DIRCE, tabla 39372, todas las empresas; divisiones CNAE 2009
-- agrupadas en 11 sectores). pct = % del total de empresas del territorio;
-- por_1000_hab = empresas del sector por 1.000 habitantes (padrón a 1 de enero del
-- año, main.poblacion_territorios; si no hay padrón del año, el último).
-- En Ceuta y Melilla el INE no pone el número de división en el nombre de la
-- serie: se recupera con el código de actividad (v338_cod) del resto.
with base as (
    select
        cast(cod_territorio as varchar) as cod,
        cast(anyo as integer) as anio,
        cnae_div,
        v338_cod,
        valor
    from {{ source('raw_empresas', 'ine_dirce_actividad') }}
    where valor is not null
),

mapa as (
    select distinct v338_cod, cnae_div from base where cnae_div is not null and v338_cod is not null
),

divs as (
    select b.cod, b.anio, cast(coalesce(b.cnae_div, m.cnae_div) as integer) as div, b.valor
    from base b
    left join mapa m on m.v338_cod = b.v338_cod
),

sectores as (
    select
        cod,
        anio,
        case
            when div = 0 then 'Total'
            when div between 5 and 39 then 'Industria y energía'
            when div between 41 and 43 then 'Construcción'
            when div between 45 and 47 then 'Comercio'
            when div between 49 and 53 then 'Transporte y almacenamiento'
            when div between 55 and 56 then 'Hostelería'
            when div between 58 and 63 then 'Información y comunicaciones'
            when div between 64 and 68 then 'Finanzas, seguros e inmobiliarias'
            when div between 69 and 75 then 'Actividades profesionales y técnicas'
            when div between 77 and 82 then 'Servicios administrativos y auxiliares'
            when div between 85 and 88 then 'Educación, sanidad y servicios sociales'
            when div between 90 and 96 then 'Ocio y otros servicios personales'
        end as sector,
        valor
    from divs
),

agregado as (
    select cod, anio, sector, sum(valor) as empresas
    from sectores
    where sector is not null
    group by all
),

pob as (
    select cod, anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total' and nivel in ('pais', 'ccaa')
),

rango as (
    select max(anio) as max_anio from pob
)

select
    case when a.cod = '00' then 'pais' else 'ccaa' end as nivel,
    a.cod,
    n.nombre,
    a.anio,
    a.sector,
    a.empresas,
    100.0 * a.empresas / t.empresas as pct,
    1000.0 * a.empresas / p.poblacion as por_1000_hab
from agregado a
join agregado t on t.cod = a.cod and t.anio = a.anio and t.sector = 'Total'
cross join rango r
left join pob p on p.cod = a.cod and p.anio = least(a.anio, r.max_anio)
left join {{ ref('territorios') }} n on n.nivel = case when a.cod = '00' then 'pais' else 'ccaa' end and n.cod = a.cod
where a.sector <> 'Total'
order by a.cod, a.anio, a.empresas desc
