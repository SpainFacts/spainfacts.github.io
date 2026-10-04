-- Indicadores educativos de la Encuesta de Población Activa armonizada (Eurostat, EU-LFS)
-- para España, la UE-27 y las comunidades autónomas (regiones NUTS 2), en % de cada grupo:
--   abandono         abandono temprano de la educación y la formación: 18-24 años con, como
--                    mucho, la ESO y que no siguen estudiando ni formándose
--                    (edat_lfse_14 para España/UE, edat_lfse_16 para las regiones);
--   superior_25_64   25-64 años con estudios superiores (CINE 5-8: FP de grado superior,
--                    universidad) (edat_lfse_03 / edat_lfse_04);
--   segunda_25_64    25-64 años con segunda etapa de secundaria (bachillerato, FP de grado
--                    medio) como nivel máximo (CINE 3-4);
--   basica_25_64     25-64 años con, como mucho, la ESO (CINE 0-2);
--   neet_15_29 / neet_18_24  jóvenes que ni trabajan ni estudian ni se forman
--                    (edat_lfse_20 / edat_lfse_22).
-- nivel: 'pais' (cod '00'), 'ue' (cod 'UE') o 'ccaa' (código INE de la comunidad, a partir
-- del código NUTS 2). Las cifras regionales de Ceuta y Melilla tienen muestras pequeñas y
-- Eurostat las marca a menudo como poco fiables o las omite.
with nuts as (
    select * from (values
        ('ES11', '12'), ('ES12', '03'), ('ES13', '06'), ('ES21', '16'), ('ES22', '15'),
        ('ES23', '17'), ('ES24', '02'), ('ES30', '13'), ('ES41', '07'), ('ES42', '08'),
        ('ES43', '11'), ('ES51', '09'), ('ES52', '10'), ('ES53', '04'), ('ES61', '01'),
        ('ES62', '14'), ('ES63', '18'), ('ES64', '19'), ('ES70', '05')
    ) as t(nuts2, cod_ccaa)
),

filas as (
    select geo, anio, 'abandono' as indicador, valor
    from {{ source('raw_educacion', 'eurostat_edu_abandono') }}

    union all
    select geo, anio,
        case isced11
            when 'ED5-8' then 'superior_25_64'
            when 'ED3_4' then 'segunda_25_64'
            when 'ED0-2' then 'basica_25_64'
        end,
        valor
    from {{ source('raw_educacion', 'eurostat_edu_nivel') }}
    where isced11 in ('ED5-8', 'ED3_4', 'ED0-2')

    union all
    select geo, anio,
        case age when 'Y15-29' then 'neet_15_29' else 'neet_18_24' end,
        valor
    from {{ source('raw_educacion', 'eurostat_edu_neet') }}
    where age in ('Y15-29', 'Y18-24')
),

base as (
    select
        cast(f.anio as integer) as anio,
        case when f.geo = 'ES' then 'pais' when f.geo = 'EU27_2020' then 'ue' else 'ccaa' end as nivel,
        cast(case when f.geo = 'ES' then '00' when f.geo = 'EU27_2020' then 'UE' else n.cod_ccaa end as varchar) as cod,
        f.indicador,
        cast(f.valor as double) as valor
    from filas f
    left join nuts n on n.nuts2 = f.geo
    where f.valor is not null
      and (f.geo in ('ES', 'EU27_2020') or n.cod_ccaa is not null)
)

select
    b.anio,
    b.nivel,
    b.cod,
    coalesce(t.nombre, case when b.nivel = 'ue' then 'Unión Europea' end) as nombre,
    b.indicador,
    case b.indicador
        when 'abandono' then 'Abandono temprano de la educación y la formación (18-24 años)'
        when 'superior_25_64' then 'Población de 25-64 años con estudios superiores'
        when 'segunda_25_64' then 'Población de 25-64 años con segunda etapa de secundaria como máximo'
        when 'basica_25_64' then 'Población de 25-64 años con estudios básicos como máximo'
        when 'neet_15_29' then 'Jóvenes de 15-29 años que ni trabajan ni estudian'
        when 'neet_18_24' then 'Jóvenes de 18-24 años que ni trabajan ni estudian'
    end as indicador_nombre,
    '%' as unidad,
    b.valor
from base b
left join {{ ref('territorios') }} t on t.nivel = b.nivel and t.cod = b.cod
