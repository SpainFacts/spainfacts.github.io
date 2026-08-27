select
    make_date(cast(periodo as integer), 1, 1) as periodo,
    cast(periodo as integer) as anio,
    na_item,
    case na_item
        when 'TR' then 'ingresos_totales'
        when 'TE' then 'gastos_totales'
        when 'B9' then 'saldo_deficit'
        when 'GD' then 'deuda_publica'
        else lower(na_item)
    end as concepto,
    unidad,
    valor as millones_euros
from {{ source('raw', 'eurostat_cuentas_balance') }}
where valor is not null
