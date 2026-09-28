-- Viajeros de transporte público en España por mes y modo (INE TV, tabla
-- 20239), en viajeros (el INE publica miles).
with base as (
    select
        cast(epoch_ms(fecha) + interval 12 hour as date) as mes,
        split_part(serie, '. ', 1) as modo,
        valor * 1000 as viajeros
    from {{ source('raw_movilidad', 'ine_transporte_viajeros') }}
    where serie like '%Viajeros transportados%'
      and valor is not null
)
select
    date_trunc('month', mes) as mes,
    modo,
    case modo
        when 'Total de viajeros' then 'total'
        when 'Transporte urbano' then 'urbano'
        when 'Urbano por metro' then 'metro'
        when 'Transporte urbano regular por autobús' then 'autobus_urbano'
        when 'Interurbano por autobús regular' then 'autobus_interurbano'
        when 'Ferrocarril: Cercanías' then 'cercanias'
        when 'Ferrocarril: Media distancia' then 'media_distancia'
        when 'Alta Velocidad' then 'alta_velocidad'
        when 'Resto ferrocarril larga distancia' then 'larga_distancia_convencional'
        when 'Ferrocarril: Larga distancia' then 'larga_distancia'
        when 'Interurbano por ferrocarril' then 'ferrocarril'
        when 'Interurbano Aéreo (interior)' then 'avion_interior'
        when 'Interurbano Marítimo (cabotaje)' then 'maritimo'
        when 'Transporte interurbano regular' then 'interurbano'
    end as clave,
    viajeros
from base
