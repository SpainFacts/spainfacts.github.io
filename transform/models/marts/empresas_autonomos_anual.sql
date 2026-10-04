-- Trabajadores por cuenta propia (autónomos) según la EPA, media anual (media de los cuatro
-- trimestres, solo años completos), España y comunidades, desde 2002 (INE, EPA, tabla 65316,
-- ocupados en miles). Los trimestres están en empresas_autonomos.
-- cuenta_propia = empleadores + empresarios sin asalariados o trabajadores independientes +
-- miembros de cooperativas + ayuda familiar. pct_* = % de los ocupados.
select
    nivel,
    cod,
    nombre,
    anio,
    cast(anio as varchar) as periodo,
    avg(ocupados) as ocupados,
    avg(cuenta_propia) as cuenta_propia,
    avg(empleadores) as empleadores,
    avg(independientes) as independientes,
    avg(asalariados) as asalariados,
    100.0 * avg(cuenta_propia) / avg(ocupados) as pct_cuenta_propia,
    100.0 * avg(empleadores) / avg(ocupados) as pct_empleadores,
    100.0 * avg(independientes) / avg(ocupados) as pct_independientes
from {{ ref('empresas_autonomos') }}
group by nivel, cod, nombre, anio
having count(*) = 4
order by cod, anio
