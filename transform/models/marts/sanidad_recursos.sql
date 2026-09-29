-- Recursos sanitarios de España y de los países de la UE-27 (Eurostat):
--   medicos, enfermeras: hlth_rs_prs2 (PHYS, NRS), por 100.000 habitantes. Se usa el personal
--                        que ejerce (PRACT) y, si el país no lo informa ese año, el
--                        profesionalmente activo (PACT); `situacion` dice cuál.
--   camas:               hlth_rs_bds1, camas hospitalarias disponibles (HBEDT, todas las
--                        funciones), por 100.000 habitantes.
-- geo 'UE' = media de los países con dato ese año ponderada por población: suma de efectivos
-- (NR) / suma de la población implícita (NR / tasa x 100.000); n_paises dice cuántos entran
-- (solo años con al menos 24 de los 27 países, para que la media sea comparable).
with personal as (
    select
        cast(anio as integer) as anio, geo,
        case med_spec when 'PHYS' then 'medicos' when 'NRS' then 'enfermeras' end as recurso,
        wstatus as situacion,
        max(case when unit = 'P_HTHAB' then valor end) as por_100k,
        max(case when unit = 'NR' then valor end) as numero
    from {{ source('raw_sanidad', 'eurostat_san_personal') }}
    where med_spec in ('PHYS', 'NRS') and wstatus in ('PRACT', 'PACT')
    group by all
),

personal_elegido as (
    select * from personal
    where por_100k is not null
    qualify row_number() over (partition by anio, geo, recurso order by situacion desc) = 1  -- PRACT > PACT
),

camas as (
    select
        cast(anio as integer) as anio, geo, 'camas' as recurso, 'total' as situacion,
        max(case when unit = 'P_HTHAB' then valor end) as por_100k,
        max(case when unit = 'NR' then valor end) as numero
    from {{ source('raw_sanidad', 'eurostat_san_camas') }}
    group by all
    having max(case when unit = 'P_HTHAB' then valor end) is not null
),

paises as (
    select * from personal_elegido
    union all
    select * from camas
),

ue as (
    select
        anio, 'UE' as geo, recurso, 'mixta' as situacion,
        1e5 * sum(numero) / sum(1e5 * numero / por_100k) as por_100k,
        sum(numero) as numero,
        count(*) as n_paises
    from paises
    where numero is not null and por_100k > 0
    group by all
    having count(*) >= 24
)

select
    anio,
    cast(geo as varchar) as geo,
    case geo
        when 'UE' then 'UE-27 (media)'
        when 'ES' then 'España' when 'DE' then 'Alemania' when 'FR' then 'Francia' when 'IT' then 'Italia'
        when 'PT' then 'Portugal' when 'BE' then 'Bélgica' when 'BG' then 'Bulgaria' when 'CZ' then 'Chequia'
        when 'DK' then 'Dinamarca' when 'EE' then 'Estonia' when 'IE' then 'Irlanda' when 'EL' then 'Grecia'
        when 'HR' then 'Croacia' when 'CY' then 'Chipre' when 'LV' then 'Letonia' when 'LT' then 'Lituania'
        when 'LU' then 'Luxemburgo' when 'HU' then 'Hungría' when 'MT' then 'Malta' when 'NL' then 'Países Bajos'
        when 'AT' then 'Austria' when 'PL' then 'Polonia' when 'RO' then 'Rumanía' when 'SI' then 'Eslovenia'
        when 'SK' then 'Eslovaquia' when 'FI' then 'Finlandia' when 'SE' then 'Suecia'
        else geo
    end as pais,
    recurso,
    situacion,
    por_100k,
    por_100k / 100 as por_1000,
    numero,
    cast(null as bigint) as n_paises
from paises

union all

select
    anio, geo, 'UE-27 (media)' as pais, recurso, situacion, por_100k, por_100k / 100 as por_1000,
    numero, n_paises
from ue
