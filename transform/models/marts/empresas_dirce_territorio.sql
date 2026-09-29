-- Empresas activas a 1 de enero por territorio y año (INE, Directorio Central de
-- Empresas DIRCE, tabla 302: empresas por provincia y condición jurídica, desde 1999).
-- nivel: 'pais' (cod '00'), 'ccaa' (código INE, suma de sus provincias) y 'provincia'.
-- Se cuentan todas las empresas activas, incluidos los autónomos (personas
-- físicas); el DIRCE no incluye la producción agraria y pesquera, las
-- administraciones públicas ni el servicio doméstico.
-- empresas_1000hab = empresas / población del padrón a 1 de enero del mismo año x 1.000
-- (población de main.poblacion_territorios; si aún no hay padrón del año, la última).
-- sociedades = sociedades anónimas + de responsabilidad limitada.
with base as (
    select
        case when nivel = 'pais' then '00' else cast(cod_territorio as varchar) end as cod_prov,
        nivel,
        cast(anyo as integer) as anio,
        v337_cod as cond,
        valor
    from {{ source('raw_empresas', 'ine_dirce_provincias') }}
    where valor is not null
),

prov as (
    select
        b.nivel,
        b.cod_prov as cod,
        b.anio,
        sum(valor) filter (where cond = '01') as empresas,
        sum(valor) filter (where cond = '10') as personas_fisicas,
        sum(valor) filter (where cond in ('02', '03')) as sociedades
    from base b
    group by all
),

ccaa as (
    select
        'ccaa' as nivel,
        cast(t.cod_ccaa as varchar) as cod,
        p.anio,
        sum(p.empresas) as empresas,
        sum(p.personas_fisicas) as personas_fisicas,
        sum(p.sociedades) as sociedades
    from prov p
    join {{ ref('territorios_provincias') }} t on cast(t.cod_prov as varchar) = p.cod
    where p.nivel = 'provincia'
    group by all
),

todo as (
    select * from prov
    union all
    select * from ccaa
),

pob as (
    select nivel, cod, anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total'
),

rango as (
    select max(anio) as max_anio, min(anio) as min_anio from pob
)

select
    t.nivel,
    t.cod,
    t.anio,
    t.empresas,
    t.personas_fisicas,
    t.sociedades,
    100.0 * t.personas_fisicas / t.empresas as pct_personas_fisicas,
    p.poblacion,
    1000.0 * t.empresas / p.poblacion as empresas_1000hab,
    100.0 * (t.empresas / lag(t.empresas) over (partition by t.nivel, t.cod order by t.anio) - 1) as crecimiento
from todo t
cross join rango r
left join pob p
    on p.nivel = t.nivel and p.cod = t.cod
    and p.anio = greatest(least(t.anio, r.max_anio), r.min_anio)
order by t.nivel, t.cod, t.anio
