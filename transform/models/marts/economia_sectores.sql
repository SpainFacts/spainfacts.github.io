-- Sectores de la economía española por año (ramas NACE A10 de Eurostat):
-- valor añadido real en euros del último año (volumen x cociente corriente /
-- volumen de ese año, por rama), su crecimiento real anual, su peso en el total
-- a precios corrientes, y el empleo (ocupados y asalariados) en valor absoluto,
-- por 1.000 habitantes y en peso. productividad_real: VAB real por ocupado.
-- es_subrama: C (manufacturas) está incluida en B-E y no debe sumarse.
with vab as (
    select
        cast(anio as integer) as anio,
        rama,
        max(case when unidad = 'CLV10_MEUR' then valor end) as volumen,
        max(case when unidad = 'CP_MEUR' then valor end) as nominal
    from {{ source('raw_economia', 'eurostat_vab_sectores') }}
    group by all
),

empleo as (
    select
        cast(anio as integer) as anio,
        rama,
        max(case when concepto = 'EMP_DC' then miles end) as ocupados_miles,
        max(case when concepto = 'SAL_DC' then miles end) as asalariados_miles
    from {{ source('raw_economia', 'eurostat_empleo_sectores') }}
    group by all
),

ultimo as (
    select max(anio) as anio from vab where nominal is not null and volumen is not null
),

escala as (
    select rama, nominal / volumen as factor from vab where anio = (select anio from ultimo)
),

total as (
    select v.anio, v.nominal as nominal_total, e.ocupados_miles as ocupados_total
    from vab v left join empleo e using (anio, rama)
    where v.rama = 'TOTAL'
),

poblacion as (
    select cast(periodo as integer) as anio, 1000 * valor as poblacion
    from {{ source('raw_eurostat_extra', 'eurostat_poblacion') }}
),

unido as (
    select
        v.anio,
        v.rama,
        v.volumen * s.factor as vab_real_meur,
        v.nominal as vab_nominal_meur,
        e.ocupados_miles,
        e.asalariados_miles,
        t.nominal_total,
        t.ocupados_total,
        p.poblacion
    from vab v
    join escala s using (rama)
    left join empleo e using (anio, rama)
    left join total t using (anio)
    left join poblacion p on p.anio = v.anio
)

select
    anio,
    rama,
    case rama
        when 'TOTAL' then 'Total'
        when 'A' then 'Agricultura y pesca'
        when 'B-E' then 'Industria y energía'
        when 'C' then 'Manufacturas'
        when 'F' then 'Construcción'
        when 'G-I' then 'Comercio, transporte y hostelería'
        when 'J' then 'Información y comunicaciones'
        when 'K' then 'Finanzas y seguros'
        when 'L' then 'Inmobiliarias'
        when 'M_N' then 'Actividades profesionales'
        when 'O-Q' then 'Administración, educación y sanidad'
        when 'R-U' then 'Ocio y otros servicios'
    end as sector,
    rama = 'C' as es_subrama,
    (select anio from ultimo) as anio_euros,
    vab_real_meur,
    vab_nominal_meur,
    100 * (vab_real_meur / lag(vab_real_meur) over (partition by rama order by anio) - 1) as crecimiento_real,
    100 * vab_nominal_meur / nominal_total as peso_vab,
    ocupados_miles,
    asalariados_miles,
    1e6 * ocupados_miles / poblacion as ocupados_1000_hab,
    100 * ocupados_miles / ocupados_total as peso_empleo,
    1e3 * vab_real_meur / nullif(ocupados_miles, 0) as productividad_real
from unido
where vab_nominal_meur is not null
