-- Inflación armonizada (IPCA) de España y de otros países de la UE (Eurostat,
-- prc_hicp_minr, ECOICOP v2, mensual): tasa anual e índice de precios
-- rebasado a 2019 = 100 (media de 2019) para comparar cuánto han subido los
-- precios acumulados desde antes de la pandemia.
with base as (
    select
        cast(strptime(mes || '-01', '%Y-%m-%d') as date) as mes,
        geo,
        max(valor) filter (where unidad = 'RCH_A') as tasa_anual,
        max(valor) filter (where unidad = 'I15') as indice_2015
    from {{ source('raw_mercado', 'eurostat_ipca') }}
    group by all
),

base2019 as (
    select geo, avg(indice_2015) as media_2019
    from base
    where year(mes) = 2019
    group by geo
)

select
    b.mes,
    b.geo,
    case b.geo
        when 'ES' then 'España'
        when 'EU27_2020' then 'UE-27'
        when 'EA20' then 'Zona euro'
        when 'DE' then 'Alemania'
        when 'FR' then 'Francia'
        when 'IT' then 'Italia'
        when 'PT' then 'Portugal'
    end as pais,
    b.tasa_anual,
    100 * b.indice_2015 / m.media_2019 as indice_2019
from base b
left join base2019 m using (geo)
where b.tasa_anual is not null or b.indice_2015 is not null
