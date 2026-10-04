-- Precio de la electricidad y del gas natural para los hogares, semestral desde
-- 2007 (Eurostat): €/kWh con todos los impuestos para un consumo medio
--   electricidad: nrg_pc_204, banda DC (2.500-4.999 kWh al año);
--   gas natural: nrg_pc_202, banda D2 (20-199 GJ al año).
-- eur_kwh_real: descontada la inflación, en euros de anio_euros (último año
-- completo del IPC), con la media del IPC general español en los seis meses del
-- semestre. Todos los países se deflactan con el IPC español para conservar la
-- comparación con España.
with precios as (
    select 'Electricidad' as energia, semestre, geo, eur_kwh
    from {{ source('raw_mercado', 'eurostat_precio_electricidad_hogares') }}
    union all
    select 'Gas natural', semestre, geo, eur_kwh
    from {{ source('raw_mercado', 'eurostat_precio_gas_hogares') }}
),

ipc_sem as (
    select
        cast(year(mes) as integer) as anio,
        case when month(mes) <= 6 then 1 else 2 end as sem,
        avg(indice) as indice
    from {{ ref('mercado_ipc_mensual') }}
    group by all
),

base as (
    select avg(indice) as indice_base, max(year(mes)) as anio_euros
    from {{ ref('mercado_ipc_mensual') }}
    where year(mes) = (select max(anio) from {{ ref('deflactor') }} where meses = 12)
)

select
    make_date(cast(left(p.semestre, 4) as integer), case when right(p.semestre, 1) = '1' then 1 else 7 end, 1) as fecha,
    cast(left(p.semestre, 4) as integer) as anio,
    p.semestre,
    p.energia,
    p.geo as cod_pais,
    case p.geo
        when 'ES' then 'España'
        when 'EU27_2020' then 'UE-27'
        when 'DE' then 'Alemania'
        when 'FR' then 'Francia'
        when 'IT' then 'Italia'
        when 'PT' then 'Portugal'
    end as pais,
    p.eur_kwh,
    p.eur_kwh * b.indice_base / i.indice as eur_kwh_real,
    b.anio_euros
from precios p
cross join base b
join ipc_sem i on i.anio = cast(left(p.semestre, 4) as integer) and i.sem = cast(right(p.semestre, 1) as integer)
where p.eur_kwh is not null
