-- Índice de producción en la construcción por país de la UE, rama y año (Eurostat sts_copr_a,
-- raw.eurostat_construccion_produccion; indicador PRD, corregido de efectos de calendario).
-- Una fila por país (27 + EU27_2020), rama y año desde 1995 (España desde 2000; F41-F43 desde 2005).
--   rama: F (total construcción), F41 (construcción de edificios), F42 (ingeniería civil / obra
--     pública), F43 (actividades de construcción especializada: instalaciones, acabados...).
--   indice_2021: índice publicado, 2021 = 100.
--   indice_2007: el mismo índice rebasado a 2007 = 100 (máximo de la burbuja en España).
--   var_anual_pct: variación sobre el año anterior.
--   nota: España F y F43 de 2025 saltan +26 % y +32 % sobre 2024 en el dato de Eurostat (que viene
--     del índice de producción de la industria de la construcción del INE); hay que tratar ese
--     salto con cautela (posible ruptura de serie): F41 y F42 no lo muestran.
with base as (
    select cast(anio as integer) as anio, pais, rama, indice as indice_2021
    from {{ source('raw_construccion', 'eurostat_construccion_produccion') }}
    where indice is not null
)

select
    b.anio,
    b.pais,
    n.pais_nombre,
    b.pais in ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT', 'IE') as es_referencia,
    b.rama,
    case b.rama
        when 'F' then 'Construcción (total)'
        when 'F41' then 'Edificación'
        when 'F42' then 'Ingeniería civil (obra pública)'
        when 'F43' then 'Construcción especializada'
    end as rama_nombre,
    b.indice_2021,
    100.0 * b.indice_2021
        / nullif(max(case when b.anio = 2007 then b.indice_2021 end) over (partition by b.pais, b.rama), 0)
        as indice_2007,
    100.0 * (b.indice_2021 / nullif(lag(b.indice_2021) over (partition by b.pais, b.rama order by b.anio), 0) - 1)
        as var_anual_pct,
    case when b.pais = 'ES' and b.anio >= 2025 and b.rama in ('F', 'F43')
        then 'Salto atípico en 2025 (posible ruptura de serie): usar con cautela' end as nota
from base b
left join {{ ref('industria_paises') }} n using (pais)
