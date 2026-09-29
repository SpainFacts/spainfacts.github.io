-- Gasto de las Administraciones Públicas en educación (Eurostat gov_10a_exp, clasificación
-- funcional COFOG: GF09 Educación y sus subfunciones), España y UE-27:
--   pct_pib       gasto en % del PIB (cifra de Eurostat);
--   eur_hab_real  solo España: gasto por habitante en euros constantes del último año completo
--                 de IPC = millones de euros x 1e6 / población media anual (Eurostat nama_10_pe)
--                 x factor del deflactor (IPC medio anual del INE).
-- funcion: 'Total', 'Infantil y primaria' (GF0901), 'Secundaria' (GF0902),
-- 'Postsecundaria no superior' (GF0903), 'Superior' (GF0904).
with base as (
    select
        cast(anio as integer) as anio,
        case geo when 'ES' then 'pais' else 'ue' end as nivel,
        case cofog99
            when 'GF09' then 'Total'
            when 'GF0901' then 'Infantil y primaria'
            when 'GF0902' then 'Secundaria'
            when 'GF0903' then 'Postsecundaria no superior'
            when 'GF0904' then 'Superior'
        end as funcion,
        max(case when unit = 'PC_GDP' then valor end) as pct_pib,
        max(case when unit = 'MIO_EUR' then valor end) as millones_eur
    from {{ source('raw_educacion', 'eurostat_edu_gasto_cofog') }}
    group by all
),

poblacion as (
    select cast(periodo as integer) as anio, 1000 * valor as poblacion
    from {{ source('raw_eurostat_extra', 'eurostat_poblacion') }}
)

select
    b.anio,
    b.nivel,
    b.funcion,
    b.pct_pib,
    b.millones_eur,
    case when b.nivel = 'pais' then 1e6 * b.millones_eur / p.poblacion * d.factor end as eur_hab_real,
    d.anio_base
from base b
left join poblacion p on p.anio = b.anio
left join {{ ref('deflactor') }} d on d.anio = b.anio
where b.pct_pib is not null or b.millones_eur is not null
