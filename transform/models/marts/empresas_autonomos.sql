-- Trabajadores por cuenta propia (autónomos) según la EPA, por trimestre, España y
-- comunidades, desde 2002 (INE, EPA, tabla 65316: ocupados por situación
-- profesional, ambos sexos, en miles).
-- cuenta_propia = empleadores + empresarios sin asalariados o trabajadores
-- independientes + miembros de cooperativas + ayuda familiar.
-- pct_cuenta_propia = cuenta propia / ocupados x 100; pct_empleadores y
-- pct_independientes, igual para cada tipo.
-- anual: media de los cuatro trimestres (solo años completos) en empresas_autonomos
-- con trimestre = 0.
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
),

anual as (
    select
        cod, anio, 0 as trimestre,
        avg(ocupados) as ocupados,
        avg(cuenta_propia) as cuenta_propia,
        avg(empleadores) as empleadores,
        avg(independientes) as independientes,
        avg(asalariados) as asalariados
    from trimestral
    group by cod, anio
    having count(*) = 4
),

todo as (
    select * from trimestral
    union all
    select * from anual
)

select
    cod,
    anio,
    trimestre,
    case when trimestre = 0 then cast(anio as varchar)
         else cast(anio as varchar) || '-T' || cast(trimestre as varchar) end as periodo,
    case when trimestre = 0 then make_date(anio, 7, 1)
         else make_date(anio, 3 * trimestre - 2, 1) end as fecha,
    ocupados,
    cuenta_propia,
    empleadores,
    independientes,
    asalariados,
    100.0 * cuenta_propia / ocupados as pct_cuenta_propia,
    100.0 * empleadores / ocupados as pct_empleadores,
    100.0 * independientes / ocupados as pct_independientes
from todo
order by cod, anio, trimestre
