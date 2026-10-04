-- Trabajadores por cuenta propia (autónomos) según la EPA, por trimestre, España y
-- comunidades, desde 2002 (INE, EPA, tabla 65316: ocupados por situación
-- profesional, ambos sexos, en miles).
-- cuenta_propia = empleadores + empresarios sin asalariados o trabajadores
-- independientes + miembros de cooperativas + ayuda familiar.
-- pct_cuenta_propia = cuenta propia / ocupados x 100; pct_empleadores y
-- pct_independientes, igual para cada tipo.
-- La media anual (cuatro trimestres, solo años completos) está en empresas_autonomos_anual.
with base as (
    select
        case when nivel = 'pais' then '00' else cast(cod_territorio as varchar) end as cod,
        cast(anyo as integer) as anio,
        cast(fk_periodo as integer) - 18 as trimestre,
        v552 as situacion,
        valor
    from {{ source('raw_empresas', 'ine_epa_situacion') }}
    where v18 = 'Ambos sexos' and nivel in ('pais', 'ccaa') and fk_periodo between 19 and 22
),

trimestral as (
    select
        cod,
        anio,
        trimestre,
        max(valor) filter (where situacion = 'Total') as ocupados,
        max(valor) filter (where situacion = 'Trabajador por cuenta propia') as cuenta_propia,
        max(valor) filter (where situacion = 'Empleador') as empleadores,
        max(valor) filter (where situacion like 'Empresario sin asalariados%') as independientes,
        max(valor) filter (where situacion = 'Asalariados : Total') as asalariados
    from base
    group by all
)

select
    case when x.cod = '00' then 'pais' else 'ccaa' end as nivel,
    x.cod,
    t.nombre,
    x.anio,
    x.trimestre,
    cast(x.anio as varchar) || '-T' || cast(x.trimestre as varchar) as periodo,
    make_date(x.anio, 3 * x.trimestre - 2, 1) as fecha,
    x.ocupados,
    x.cuenta_propia,
    x.empleadores,
    x.independientes,
    x.asalariados,
    100.0 * x.cuenta_propia / x.ocupados as pct_cuenta_propia,
    100.0 * x.empleadores / x.ocupados as pct_empleadores,
    100.0 * x.independientes / x.ocupados as pct_independientes
from trimestral x
left join {{ ref('territorios') }} t on t.nivel = case when x.cod = '00' then 'pais' else 'ccaa' end and t.cod = x.cod
order by x.cod, x.anio, x.trimestre
