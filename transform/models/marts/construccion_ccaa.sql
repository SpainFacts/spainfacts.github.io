-- Peso de la construcción en la economía de cada comunidad, por año (Eurostat, cuentas regionales
-- nama_10r_3gva, raw.eurostat_construccion_vab_regional: VAB a precios corrientes por rama, NUTS 2).
-- Una fila por comunidad (código INE) y España ('00') y año desde 2000.
--   pct_vab_construccion: VAB de la construcción (rama F) en % del VAB total de la comunidad.
--   vab_constr_hab_real: VAB de la construcción por habitante en euros constantes de anio_base
--     (población a 1 de enero, main.poblacion_territorios; deflactor IPC: construccion_deflactor).
--   puesto: posición entre las 19 comunidades y ciudades autónomas (1 = más peso).
--   pct_vab_2007 / dif_pp_vs_2007: peso en 2007 (año de máximo nacional) y diferencia en puntos.
--   ocupados_constr_1000hab_epa / pct_ocupados_constr_epa: media anual de la EPA (construccion_empleo),
--     desde 2008; solo años con los cuatro trimestres.
with v as (
    select
        m.cod_ccaa as cod,
        m.nombre,
        cast(r.anio as integer) as anio,
        max(r.mill_eur) filter (where r.rama = 'F') as vab_constr_meur,
        max(r.mill_eur) filter (where r.rama = 'TOTAL') as vab_total_meur
    from {{ source('raw_construccion', 'eurostat_construccion_vab_regional') }} r
    join {{ ref('construccion_nuts') }} m on m.nuts = r.nuts
    group by all
),

pob as (
    select nivel, cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total' and nivel in ('pais', 'ccaa')
),

epa as (
    select cod, anio,
        avg(ocupados_constr_1000hab) as ocupados_constr_1000hab_epa,
        avg(pct_ocupados_constr) as pct_ocupados_constr_epa
    from {{ ref('construccion_empleo') }}
    group by cod, anio
    having count(*) = 4
),

base as (
    select
        v.*,
        100.0 * v.vab_constr_meur / nullif(v.vab_total_meur, 0) as pct_vab_construccion,
        p.poblacion
    from v
    asof left join pob p
      on p.nivel = case when v.cod = '00' then 'pais' else 'ccaa' end and p.cod = v.cod and p.anio <= v.anio
)

select
    b.cod,
    b.nombre,
    b.anio,
    b.pct_vab_construccion,
    b.vab_constr_meur * 1e6 / nullif(b.poblacion, 0) * d.factor as vab_constr_hab_real,
    case when b.cod <> '00' then
        rank() over (partition by b.anio, b.cod <> '00' order by b.pct_vab_construccion desc) end as puesto,
    max(case when b.anio = 2007 then b.pct_vab_construccion end) over (partition by b.cod) as pct_vab_2007,
    b.pct_vab_construccion
        - max(case when b.anio = 2007 then b.pct_vab_construccion end) over (partition by b.cod) as dif_pp_vs_2007,
    e.ocupados_constr_1000hab_epa,
    e.pct_ocupados_constr_epa,
    b.vab_constr_meur,
    b.vab_total_meur,
    cast(b.poblacion as bigint) as poblacion,
    d.anio_base
from base b
left join {{ ref('construccion_deflactor') }} d on d.anio = b.anio
left join epa e on e.cod = b.cod and e.anio = b.anio
where b.pct_vab_construccion is not null
order by b.cod, b.anio
