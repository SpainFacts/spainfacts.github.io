-- Deudores concursados (empresas y personas físicas que entran en concurso de
-- acreedores) por año, España y comunidades, 2004-2020 (INE, Estadística del
-- Procedimiento Concursal, tabla 2992; el INE no ha publicado datos posteriores a 2020).
-- concursos_100k = concursados por 100.000 habitantes (padrón a 1 de enero);
-- concursos_1000emp = concursados por cada 1.000 empresas activas a 1 de enero
-- (DIRCE, empresas_dirce_territorio). voluntarios = los pide el propio deudor;
-- necesarios = los piden los acreedores.
with base as (
    select
        case when nivel = 'pais' then '00' else cast(cod_territorio as varchar) end as cod,
        cast(anyo as integer) as anio,
        max(valor) filter (where v372 = 'Total') as concursos,
        max(valor) filter (where v372 = 'Voluntario') as voluntarios,
        max(valor) filter (where v372 = 'Necesario') as necesarios
    from {{ source('raw_empresas', 'ine_epc_deudores') }}
    where nivel in ('pais', 'ccaa')
    group by all
),

pob as (
    select cod, anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total' and nivel in ('pais', 'ccaa')
)

select
    case when b.cod = '00' then 'pais' else 'ccaa' end as nivel,
    b.cod,
    t.nombre,
    b.anio,
    b.concursos,
    b.voluntarios,
    b.necesarios,
    100000.0 * b.concursos / p.poblacion as concursos_100k,
    1000.0 * b.concursos / e.empresas as concursos_1000emp,
    e.empresas
from base b
left join pob p on p.cod = b.cod and p.anio = b.anio
left join {{ ref('territorios') }} t on t.nivel = case when b.cod = '00' then 'pais' else 'ccaa' end and t.cod = b.cod
left join {{ ref('empresas_dirce_territorio') }} e
    on e.cod = b.cod and e.anio = b.anio and e.nivel = case when b.cod = '00' then 'pais' else 'ccaa' end
where b.concursos is not null
order by b.cod, b.anio
