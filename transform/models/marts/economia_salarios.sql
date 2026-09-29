-- Coste salarial por trabajador y mes (INE, Encuesta Trimestral de Coste
-- Laboral, tabla 6038), por trimestre, jornada y sector, desde 2008. Incluye
-- pagas extraordinarias y atrasos (coste salarial total), por lo que el dato
-- trimestral es estacional: se compara siempre con el mismo trimestre del año
-- anterior. real: en euros del último año completo del IPC, usando la media
-- del IPC general (base 2025) de los tres meses del trimestre.
with base as (
    select
        cast(epoch_ms(fecha) + interval 12 hour as date) as fecha,  -- el INE fecha a medianoche peninsular (22:00/23:00 UTC del día anterior)
        split_part(serie, '. ', 1) as jornada_ine,
        split_part(serie, '. ', 2) as sector_ine,
        split_part(serie, '. ', 3) as componente,
        valor
    from {{ source('raw_economia', 'ine_coste_salarial') }}
    where valor is not null
      and split_part(serie, '. ', 3) in ('Coste salarial total', 'Coste salarial ordinario')
),

pivotado as (
    select
        make_date(year(fecha), 3 * quarter(fecha) - 2, 1) as trimestre,
        case jornada_ine
            when 'Ambas jornadas' then 'Todas'
            when 'Jornada a tiempo completo' then 'Tiempo completo'
            when 'Jornada a tiempo parcial' then 'Tiempo parcial'
        end as jornada,
        case when sector_ine like 'Industria, construcción y servicios%' then 'Total' else sector_ine end as sector,
        max(case when componente = 'Coste salarial total' then valor end) as salario_total,
        max(case when componente = 'Coste salarial ordinario' then valor end) as salario_ordinario
    from base
    group by all
),

ipc_trim as (
    select
        make_date(year(periodo), 3 * quarter(periodo) - 2, 1) as trimestre,
        avg(valor) as ipc,
        count(*) as meses
    from {{ ref('metricas_base') }}
    where metrica_id = 'ipc_indice'
    group by 1
),

base_ipc as (
    select ipc_medio as ipc_base, anio_base from {{ ref('deflactor') }}
    where anio = anio_base
),

unido as (
    select
        p.*,
        p.salario_total * b.ipc_base / i.ipc as salario_total_real,
        p.salario_ordinario * b.ipc_base / i.ipc as salario_ordinario_real,
        p.salario_total / i.ipc as salario_ipc,
        b.anio_base
    from pivotado p
    left join ipc_trim i on i.trimestre = p.trimestre and i.meses = 3
    cross join base_ipc b
)

-- Interanual contra el mismo trimestre del año anterior
select
    u.trimestre,
    cast(year(u.trimestre) as integer) as anio,
    cast(quarter(u.trimestre) as integer) as trim,
    u.jornada,
    u.sector,
    u.salario_total,
    u.salario_ordinario,
    u.anio_base as anio_euros,
    u.salario_total_real,
    u.salario_ordinario_real,
    100 * (u.salario_total / a.salario_total - 1) as interanual_nominal,
    100 * (u.salario_ipc / a.salario_ipc - 1) as interanual_real
from unido u
left join unido a
  on a.jornada = u.jornada and a.sector = u.sector
 and a.trimestre = cast(u.trimestre - interval 1 year as date)
