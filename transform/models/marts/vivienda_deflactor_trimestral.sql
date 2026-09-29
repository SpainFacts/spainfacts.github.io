-- Deflactor trimestral para las series de vivienda: factor que convierte euros
-- de un trimestre en euros del año base de main.deflactor (último año completo
-- de IPC). factor = IPC medio del año base / IPC medio del trimestre (IPC
-- general del INE, base 2025, metrica 'ipc_indice', mensual desde 2002).
-- Si el trimestre aún no tiene sus tres meses de IPC se usa el factor anual.
with ipc_trim as (
    select
        cast(year(periodo) as integer) as anio,
        cast(quarter(periodo) as integer) as trimestre,
        avg(valor) as ipc,
        count(*) as meses
    from {{ ref('metricas_base') }}
    where metrica_id = 'ipc_indice'
    group by 1, 2
),

base as (
    select ipc_medio as ipc_base, anio_base from {{ ref('deflactor') }} where anio = anio_base
),

trimestres as (
    select d.anio, t.trimestre
    from {{ ref('deflactor') }} d
    cross join (select unnest([1, 2, 3, 4]) as trimestre) t
)

select
    t.anio,
    t.trimestre,
    make_date(t.anio, 3 * t.trimestre - 2, 1) as fecha,
    coalesce(
        case when i.meses = 3 then b.ipc_base / i.ipc end,
        d.factor
    ) as factor,
    b.anio_base
from trimestres t
cross join base b
left join ipc_trim i on i.anio = t.anio and i.trimestre = t.trimestre
left join {{ ref('deflactor') }} d on d.anio = t.anio
