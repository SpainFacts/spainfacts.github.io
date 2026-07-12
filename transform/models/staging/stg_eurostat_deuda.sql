select
    -- "2025-Q3" -> primer día del trimestre
    make_date(
        cast(substr(periodo, 1, 4) as integer),
        (cast(substr(periodo, 7, 1) as integer) - 1) * 3 + 1,
        1
    ) as periodo,
    unidad,
    valor
from {{ source('raw', 'eurostat_deuda') }}
where valor is not null
