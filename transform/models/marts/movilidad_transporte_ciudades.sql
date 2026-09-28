-- Viajeros de metro y autobús urbano en las ciudades con metro (INE TV, tabla
-- 20193), en viajeros (el INE publica miles).
select
    date_trunc('month', cast(epoch_ms(fecha) + interval 12 hour as date)) as mes,
    case when serie like 'Urbano por metro%' then 'Metro' else 'Autobús urbano' end as modo,
    split_part(serie, '. ', 2) as ciudad,
    valor * 1000 as viajeros
from {{ source('raw_movilidad', 'ine_transporte_ciudades') }}
where serie like '%Viajeros transportados%'
  and valor is not null
