select
    make_date(cast(periodo as integer), 1, 1) as periodo,
    cast(periodo as integer) as anio,
    na_item as cod_tributo,
    case na_item
        when 'D61REC' then 'Cotizaciones Sociales'
        when 'D5REC' then 'Impuestos Directos (Renta y Patrimonio)'
        when 'D2REC' then 'Impuestos Indirectos (IVA y Producción)'
        when 'D9REC' then 'Impuestos sobre el Capital y Transferencias'
        when 'P11_P12_P131' then 'Ventas y Tasas Públicas'
        when 'D4REC' then 'Rentas de la Propiedad y Dividendos'
        else na_item
    end as categoria,
    unidad,
    valor as millones_euros
from {{ source('raw', 'eurostat_cuentas_ingresos') }}
where valor is not null
