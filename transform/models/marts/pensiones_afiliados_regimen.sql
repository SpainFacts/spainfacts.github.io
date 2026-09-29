-- Afiliados a la Seguridad Social por régimen y año (media de los afiliados
-- medios mensuales publicados; meses indica cuántos), desde 2001.
-- Fuente: Seguridad Social, serie de afiliación media por regímenes (total del
-- sistema). Agrupación de columnas: General incluye los sistemas especiales
-- agrario y de empleados de hogar (y los antiguos regímenes especiales de hogar y
-- agrario por cuenta ajena, integrados en 2012); Autónomos incluye el sistema
-- especial agrario por cuenta propia (SETA) y el antiguo régimen agrario por
-- cuenta propia (integrado en 2008).
-- por_1000_hab: afiliados / población del padrón (INE) del año o del más cercano.
with anual as (
    select
        cast(anio as integer) as anio,
        regimen,
        count(*) as meses,
        avg(afiliados) as afiliados
    from {{ source('raw_pensiones', 'ss_afiliados_regimen') }}
    group by 1, 2
),

pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and sexo = 'Total'
)

select
    a.anio,
    a.regimen,
    a.meses,
    a.afiliados,
    100.0 * a.afiliados / t.afiliados as pct_del_total,
    1000.0 * a.afiliados / p.poblacion as por_1000_hab
from anual a
join anual t on t.anio = a.anio and t.regimen = 'Total'
left join pob p on p.anio = greatest(least(a.anio, (select max(anio) from pob)), (select min(anio) from pob))
order by a.anio, a.regimen
