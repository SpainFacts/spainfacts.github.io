-- Tasa de paro mensual desestacionalizada de España y de otros países de la UE
-- (Eurostat, une_rt_m, % de la población activa): total y menores de 25 años.
-- Eurostat estima los meses a partir de las encuestas de población activa de
-- cada país, por lo que el dato de España difiere unas décimas de la EPA
-- trimestral del INE.
select
    cast(strptime(mes || '-01', '%Y-%m-%d') as date) as mes,
    geo,
    case geo
        when 'ES' then 'España'
        when 'EU27_2020' then 'UE-27'
        when 'EA20' then 'Zona euro'
        when 'DE' then 'Alemania'
        when 'FR' then 'Francia'
        when 'IT' then 'Italia'
        when 'PT' then 'Portugal'
    end as pais,
    max(tasa_paro) filter (where edad = 'TOTAL') as tasa_paro,
    max(tasa_paro) filter (where edad = 'Y_LT25') as tasa_paro_menor25
from {{ source('raw_mercado', 'eurostat_paro_mensual') }}
where tasa_paro is not null
group by all
