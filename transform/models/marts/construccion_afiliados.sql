-- Afiliados a la Seguridad Social en la construcción (sección F de la CNAE) por mes, España,
-- comunidades y provincias (Seguridad Social, ficheros «Afiliación AAAA.xlsx», hoja de
-- actividades por provincia; raw.construccion_afiliados). Afiliados medios del mes, Régimen
-- General + Autónomos (sin Mar ni Carbón). Desde enero de 2021.
--   afiliados_constr / afiliados_total: afiliados medios del mes en la sección F y en todas.
--   pct_constr: % de los afiliados que están en la construcción.
--   pct_autonomos_constr: % de los afiliados de la construcción que son autónomos.
--   afiliados_constr_1000hab: por 1.000 habitantes (población a 1 de enero, último padrón).
--   cnae: desde 2026 la Seguridad Social clasifica con la CNAE-2025 (la sección F sigue siendo
--     construcción, pero puede haber pequeños saltos en enero de 2026).
with base as (
    select
        cast(anio as integer) as anio,
        cast(mes as integer) as mes,
        cod_prov,
        any_value(cnae) as cnae,
        sum(afiliados) filter (where seccion = 'F') as afiliados_constr,
        sum(afiliados) filter (where seccion = 'F' and regimen = 'Autónomos') as autonomos_constr,
        sum(afiliados) filter (where seccion = 'Total') as afiliados_total
    from {{ source('raw_construccion', 'construccion_afiliados') }}
    group by all
),

con_ccaa as (
    select b.*, tp.cod_ccaa, tp.nombre as provincia
    from base b
    join {{ ref('territorios_provincias') }} tp on tp.cod_prov = b.cod_prov
),

niveles as (
    select 'provincia' as nivel, cod_prov as cod, provincia as nombre, anio, mes, cnae,
        afiliados_constr, autonomos_constr, afiliados_total
    from con_ccaa
    union all
    select 'ccaa', c.cod_ccaa, any_value(t.nombre), c.anio, c.mes, any_value(c.cnae),
        sum(c.afiliados_constr), sum(c.autonomos_constr), sum(c.afiliados_total)
    from con_ccaa c
    join {{ ref('territorios_ccaa') }} t on t.cod_ccaa = c.cod_ccaa
    group by c.cod_ccaa, c.anio, c.mes
    union all
    select 'pais', '00', 'España', anio, mes, any_value(cnae),
        sum(afiliados_constr), sum(autonomos_constr), sum(afiliados_total)
    from con_ccaa
    group by anio, mes
),

pob as (
    select nivel, cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total'
)

select
    n.nivel,
    n.cod,
    n.nombre,
    n.anio,
    n.mes,
    make_date(n.anio, n.mes, 1) as fecha,
    n.afiliados_constr,
    n.afiliados_total,
    100.0 * n.afiliados_constr / nullif(n.afiliados_total, 0) as pct_constr,
    100.0 * n.autonomos_constr / nullif(n.afiliados_constr, 0) as pct_autonomos_constr,
    1000.0 * n.afiliados_constr / nullif(p.poblacion, 0) as afiliados_constr_1000hab,
    n.cnae,
    cast(p.poblacion as bigint) as poblacion
from niveles n
asof left join pob p on p.nivel = n.nivel and p.cod = n.cod and p.anio <= n.anio
order by n.nivel, n.cod, n.anio, n.mes
