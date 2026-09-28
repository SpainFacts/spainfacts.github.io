-- Empleados públicos por territorio (España, comunidad y provincia del puesto),
-- edición y administración, con la tasa por 1.000 habitantes (padrón del mismo
-- año o el último disponible).
with agregados as (
    select fecha, 'pais' as nivel, '00' as cod, administracion, sum(efectivos) as efectivos
    from {{ ref('empleo_efectivos') }} group by all
    union all
    select fecha, 'ccaa', cod_ccaa, administracion, sum(efectivos)
    from {{ ref('empleo_efectivos') }} where cod_ccaa is not null group by all
    union all
    select fecha, 'provincia', cod_prov, administracion, sum(efectivos)
    from {{ ref('empleo_efectivos') }} where cod_prov is not null group by all
),

con_total as (
    select * from agregados
    union all
    select fecha, nivel, cod, 'Total', sum(efectivos) from agregados group by all
),

poblacion as (
    select anio, nivel, cod, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total'
)

select
    e.fecha,
    e.nivel,
    e.cod,
    e.administracion,
    e.efectivos,
    p.poblacion,
    1000.0 * e.efectivos / p.poblacion as por_1000_hab
from con_total e
left join poblacion p
  on p.nivel = e.nivel and p.cod = e.cod
 and p.anio = least(year(e.fecha), (select max(anio) from poblacion))
