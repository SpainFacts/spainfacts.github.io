-- Empresas activas a 1 de enero por tamaño (estrato de asalariados), España y
-- comunidades, desde 2020 (INE, DIRCE, tabla 39372, total de actividades).
-- Tamaños agrupados según el número de asalariados (no de ocupados, que es el
-- criterio de la UE):
--   Sin asalariados   autónomos y sociedades sin empleados
--   Micro (1-9), Pequeñas (10-49), Medianas (50-249), Grandes (250 o más)
-- Los estratos 'De 200 a 249' y 'De 250 a 999' vienen sin código en el INE y se
-- identifican por nombre. pct = % del total de empresas del territorio y año.
with base as (
    select
        cast(cod_territorio as varchar) as cod,
        cast(anyo as integer) as anio,
        v336 as estrato,
        v336_cod as estrato_cod,
        valor
    from {{ source('raw_empresas', 'ine_dirce_estrato') }}
    where valor is not null
),

clasif as (
    select
        cod,
        anio,
        case
            when estrato_cod = '01' then 'Total'
            when estrato_cod = '02' then 'Sin asalariados'
            when estrato_cod in ('03', '04', '05') then 'Micro (1-9)'
            when estrato_cod in ('06', '07') then 'Pequeñas (10-49)'
            when estrato_cod in ('08', '09') or estrato like 'De 200 a 249%' then 'Medianas (50-249)'
            when estrato_cod in ('12', '13') or estrato like 'De 250 a 999%' then 'Grandes (250 o más)'
        end as tamano,
        valor
    from base
),

agregado as (
    select cod, anio, tamano, sum(valor) as empresas
    from clasif
    where tamano is not null
    group by all
)

select
    a.cod,
    a.anio,
    a.tamano,
    case a.tamano
        when 'Sin asalariados' then 1 when 'Micro (1-9)' then 2 when 'Pequeñas (10-49)' then 3
        when 'Medianas (50-249)' then 4 when 'Grandes (250 o más)' then 5 else 0 end as orden,
    a.empresas,
    100.0 * a.empresas / t.empresas as pct
from agregado a
join agregado t on t.cod = a.cod and t.anio = a.anio and t.tamano = 'Total'
where a.tamano <> 'Total'
order by a.cod, a.anio, orden
