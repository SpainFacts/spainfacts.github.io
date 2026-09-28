-- Energía almacenada y devuelta cada mes en España (balance oficial de REE),
-- en GWh positivos. Rendimiento = energía devuelta / energía consumida para
-- almacenar (en el bombeo, ~65 % en 2023-2025: el resto se pierde en bombas y
-- turbinas; el bombeo mixto recibe además aportaciones del río).
with base as (
    select
        cast(mes as date) as mes,
        sum(mwh) filter (where concepto = 'turbinacion_bombeo') / 1000 as bombeo_turbinado_gwh,
        -sum(mwh) filter (where concepto = 'consumo_bombeo') / 1000 as bombeo_consumido_gwh,
        sum(mwh) filter (where concepto = 'baterias_entrega') / 1000 as baterias_entregado_gwh,
        -sum(mwh) filter (where concepto = 'baterias_carga') / 1000 as baterias_cargado_gwh
    from {{ source('raw_almacenamiento', 'ree_balance_almacenamiento') }}
    group by 1
)
select
    *,
    bombeo_turbinado_gwh / nullif(bombeo_consumido_gwh, 0) as rendimiento_bombeo
from base
