-- Tasa de paro de España por grupos de población, trimestral desde 2002 (INE,
-- EPA): por sexo (tabla 65349), por edad (65334) y por nacionalidad (65336).
-- Formato largo: dimension ('Sexo', 'Edad', 'Nacionalidad'), grupo y orden
-- para las leyendas.
with base as (
    select 'Sexo' as dimension, fecha, string_split(rtrim(serie, '. '), '. ') as partes, valor
    from {{ source('raw_mercado', 'ine_epa_tasas_provincia') }}
    where serie like 'Tasa de paro de la población.%'
    union all
    select 'Edad', fecha, string_split(rtrim(serie, '. '), '. '), valor
    from {{ source('raw_mercado', 'ine_epa_paro_edad_ccaa') }}
    union all
    select 'Nacionalidad', fecha, string_split(rtrim(serie, '. '), '. '), valor
    from {{ source('raw_mercado', 'ine_epa_paro_nacionalidad') }}
),

clasif as (
    select
        date_trunc('quarter', cast(epoch_ms(fecha) + interval 12 hour as date)) as trimestre,
        dimension,
        case
            when dimension = 'Sexo' and list_contains(partes, 'Hombres') and list_contains(partes, 'Total') then 'Hombres'
            when dimension = 'Sexo' and list_contains(partes, 'Mujeres') and list_contains(partes, 'Total') then 'Mujeres'
            when dimension = 'Edad' and list_contains(partes, 'Ambos sexos') then
                case
                    when list_contains(partes, 'De 16 a 19 años') then '16 a 19 años'
                    when list_contains(partes, 'De 20 a 24 años') then '20 a 24 años'
                    when list_contains(partes, 'Menores de 25 años') then 'Menores de 25 años'
                    when list_contains(partes, 'De 25 a 54 años') then '25 a 54 años'
                    when list_contains(partes, 'De 55 y más años') then '55 años o más'
                end
            when dimension = 'Nacionalidad' and list_contains(partes, 'Ambos sexos') then
                case
                    when list_contains(partes, 'Española') then 'Española'
                    when list_contains(partes, 'Extranjera: Total') then 'Extranjera (total)'
                    when list_contains(partes, 'Extranjera: Unión Europea') then 'Extranjera de la UE'
                    when list_contains(partes, 'Extranjera: No pertenecientes a la Unión Europea') then 'Extranjera de fuera de la UE'
                end
        end as grupo,
        valor as tasa_paro
    from base
    where list_contains(partes, 'Total Nacional') and valor is not null
)

select
    trimestre,
    dimension,
    grupo,
    case grupo
        when 'Hombres' then 1 when 'Mujeres' then 2
        when '16 a 19 años' then 1 when '20 a 24 años' then 2 when 'Menores de 25 años' then 3
        when '25 a 54 años' then 4 when '55 años o más' then 5
        when 'Española' then 1 when 'Extranjera (total)' then 2
        when 'Extranjera de la UE' then 3 when 'Extranjera de fuera de la UE' then 4
    end as orden,
    tasa_paro
from clasif
where grupo is not null
