-- Médicos y camas hospitalarias por comunidad autónoma (Eurostat, regiones NUTS 2):
--   medicos: hlth_rs_physreg (médicos por región; para España, los que ejercen);
--   camas:   hlth_rs_bdsrg2 (camas hospitalarias disponibles).
-- Por 100.000 habitantes (cifra de Eurostat) y número. cod = código INE de la comunidad
-- (NUTS 2 -> INE con la tabla de correspondencia de abajo) o '00' para España (ES).
with base as (
    select
        cast(anio as integer) as anio,
        geo,
        recurso,
        max(case when unit = 'P_HTHAB' then valor end) as por_100k,
        max(case when unit = 'NR' then valor end) as numero
    from {{ source('raw_sanidad', 'eurostat_san_regiones') }}
    group by all
),

conc as (
    select
        *,
        case geo
            when 'ES' then '00'
            when 'ES61' then '01' when 'ES24' then '02' when 'ES12' then '03' when 'ES53' then '04'
            when 'ES70' then '05' when 'ES13' then '06' when 'ES41' then '07' when 'ES42' then '08'
            when 'ES51' then '09' when 'ES52' then '10' when 'ES43' then '11' when 'ES11' then '12'
            when 'ES30' then '13' when 'ES62' then '14' when 'ES22' then '15' when 'ES21' then '16'
            when 'ES23' then '17' when 'ES63' then '18' when 'ES64' then '19'
        end as cod,
        case when geo = 'ES' then 'pais' else 'ccaa' end as nivel
    from base
    where por_100k is not null
)

select
    b.anio,
    b.nivel,
    b.cod,
    t.nombre as nombre,
    b.geo as nuts2,
    b.recurso,
    b.por_100k,
    b.por_100k / 100 as por_1000,
    b.numero
from conc b
left join {{ ref('territorios') }} t on t.nivel = b.nivel and t.cod = b.cod
