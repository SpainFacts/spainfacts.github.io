{{ config(materialized='ephemeral') }}
-- Normaliza los nombres de las tipologías del Balance de Criminalidad, que
-- cambian de numeración y redacción entre años ("1.-Homicidios..." / "1. Homicidios...").
select distinct
    tipologia,
    case
        when t like '%total infracciones%' then 'Total infracciones penales'
        when t like 'criminalidad convencional%' then 'Criminalidad convencional'
        when t like 'cibercriminalidad%' then 'Cibercriminalidad'
        when t like '%consumados%' then 'Homicidios y asesinatos consumados'
        when t like '%tentativa%' then 'Homicidios y asesinatos en tentativa'
        when t like '%lesiones%' then 'Lesiones graves y riña tumultuaria'
        when t like 'secuestro%' then 'Secuestro'
        when t like 'agresion sexual con penetracion%' then 'Agresión sexual con penetración'
        when t like 'resto de delitos contra la libertad%' then 'Resto de delitos sexuales'
        when t like 'delitos contra la libertad%' then 'Delitos contra la libertad sexual'
        when t like 'robos con violencia%' then 'Robos con violencia o intimidación'
        when t like 'robos con fuerza en domicilios,%' then 'Robos con fuerza (domicilios, establecimientos...)'
        when t like 'robos con fuerza en domicilios%' then 'Robos con fuerza en domicilios'
        when t like 'hurtos%' then 'Hurtos'
        when t like 'sustracciones de vehiculos%' then 'Sustracción de vehículos'
        when t like 'trafico de drogas%' then 'Tráfico de drogas'
        when t like 'estafas informaticas%' then 'Estafas informáticas'
        when t like 'otros ciberdelitos%' then 'Otros ciberdelitos'
        when t like 'resto de%' then 'Resto de infracciones'
    end as categoria
from (
    select
        tipologia,
        trim(regexp_replace(lower(strip_accents(tipologia)), '^[ivx0-9.\s-]+', '')) as t
    from {{ ref('crimen_balance_base') }}
)
