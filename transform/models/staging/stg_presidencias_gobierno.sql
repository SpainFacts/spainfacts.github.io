-- Presidencias del Gobierno de España desde 1977, a partir del seed
-- gobiernos_presidentes (nivel estatal). El seed agrupa a Suárez y Calvo-Sotelo
-- (UCD) en una fila: aquí se separan en la toma de posesión de Calvo-Sotelo
-- (26 de febrero de 1981) para poder comparar Gobiernos, no solo partidos.
with estatal as (
    select
        cast(desde as date) as desde,
        cast(hasta as date) as hasta,
        presidente,
        familia
    from {{ ref('gobiernos_presidentes') }}
    where nivel = 'estatal'
),

partido as (
    select desde, hasta, 'Adolfo Suárez' as presidente, familia
    from estatal where presidente like 'Adolfo Suárez%'
        and desde < date '1981-02-26'
    union all
    select date '1981-02-26', hasta, 'Leopoldo Calvo-Sotelo', familia
    from estatal where presidente like 'Adolfo Suárez%'
    union all
    select desde, hasta, presidente, familia
    from estatal where presidente not like 'Adolfo Suárez%'
)

select
    presidente,
    familia,
    desde,
    case when presidente = 'Adolfo Suárez' then date '1981-02-26' else hasta end as hasta,
    row_number() over (order by desde) as orden
from partido
