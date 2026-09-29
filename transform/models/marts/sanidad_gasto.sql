-- Gasto sanitario corriente según quién lo paga (Eurostat hlth_sha11_hf, cuentas de salud
-- SHA 2011), España, UE-27 y países de la UE:
--   financiacion 'Total' (TOT_HF), 'Público' (HF1: administraciones y seguros sociales
--   obligatorios), 'Seguros voluntarios' (HF2: seguros privados, ONG y empresas) y
--   'Pago directo de los hogares' (HF3).
--   pct_pib (cifra de Eurostat), eur_hab (euros corrientes por habitante), pps_hab (paridad de
--   poder de compra por habitante, para comparar países) y millones_eur.
--   eur_hab_real: solo España, euros por habitante x factor del deflactor (IPC medio anual del
--   INE) = euros constantes de anio_base.
with base as (
    select
        cast(anio as integer) as anio,
        geo,
        icha11_hf,
        max(case when unit = 'PC_GDP' then valor end) as pct_pib,
        max(case when unit = 'EUR_HAB' then valor end) as eur_hab,
        max(case when unit = 'PPS_HAB' then valor end) as pps_hab,
        max(case when unit = 'MIO_EUR' then valor end) as millones_eur
    from {{ source('raw_sanidad', 'eurostat_san_gasto') }}
    group by all
)

select
    b.anio,
    case b.geo when 'EU27_2020' then 'UE' else cast(b.geo as varchar) end as geo,
    case b.geo
        when 'EU27_2020' then 'UE-27'
        when 'ES' then 'España' when 'DE' then 'Alemania' when 'FR' then 'Francia' when 'IT' then 'Italia'
        when 'PT' then 'Portugal' when 'BE' then 'Bélgica' when 'BG' then 'Bulgaria' when 'CZ' then 'Chequia'
        when 'DK' then 'Dinamarca' when 'EE' then 'Estonia' when 'IE' then 'Irlanda' when 'EL' then 'Grecia'
        when 'HR' then 'Croacia' when 'CY' then 'Chipre' when 'LV' then 'Letonia' when 'LT' then 'Lituania'
        when 'LU' then 'Luxemburgo' when 'HU' then 'Hungría' when 'MT' then 'Malta' when 'NL' then 'Países Bajos'
        when 'AT' then 'Austria' when 'PL' then 'Polonia' when 'RO' then 'Rumanía' when 'SI' then 'Eslovenia'
        when 'SK' then 'Eslovaquia' when 'FI' then 'Finlandia' when 'SE' then 'Suecia'
        else b.geo
    end as pais,
    case b.icha11_hf
        when 'TOT_HF' then 'Total'
        when 'HF1' then 'Público'
        when 'HF2' then 'Seguros voluntarios'
        when 'HF3' then 'Pago directo de los hogares'
    end as financiacion,
    b.pct_pib,
    b.eur_hab,
    b.pps_hab,
    b.millones_eur,
    case when b.geo = 'ES' then b.eur_hab * d.factor end as eur_hab_real,
    d.anio_base
from base b
left join {{ ref('deflactor') }} d on d.anio = b.anio
where coalesce(b.pct_pib, b.eur_hab, b.pps_hab, b.millones_eur) is not null
