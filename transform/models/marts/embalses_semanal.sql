-- Serie semanal de reserva hídrica a tres niveles de agregación (cod: nombre de la cuenca,
-- código de la demarcación o '00' para España):
--   nivel = 'cuenca'      ámbitos del Boletín Hidrológico (16)
--   nivel = 'demarcacion' demarcaciones hidrográficas (código ES0xx, para el mapa)
--   nivel = 'pais'        total España
-- Consumido por sources/mother/embalses_semanal.sql.
with base as (
    select * from {{ ref('stg_miteco_embalses') }}
),

agregado as (
    select fecha, anio, semana, 'cuenca' as nivel, cuenca as cod, cuenca as nombre,
           sum(capacidad_hm3) as capacidad_hm3, sum(volumen_hm3) as volumen_hm3, count(*) as n_embalses
    from base group by all
    union all
    select fecha, anio, semana, 'demarcacion', cod_demarcacion, demarcacion,
           sum(capacidad_hm3), sum(volumen_hm3), count(*)
    from base where cod_demarcacion is not null group by all
    union all
    select fecha, anio, semana, 'pais', '00', 'España',
           sum(capacidad_hm3), sum(volumen_hm3), count(*)
    from base group by all
)

select
    *,
    nivel || ':' || cod as id,
    round(100 * volumen_hm3 / capacidad_hm3, 1) as pct_llenado
from agregado
