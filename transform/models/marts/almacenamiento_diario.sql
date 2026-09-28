-- Almacenamiento día a día (ESIOS, tiempo real): energía (MWh) y pico (MW) de
-- bombeo y baterías, en positivo. Serie disponible desde finales de 2024.
select
    cast(fecha as date) as fecha,
    sum(mwh) filter (where concepto = 'turbinacion_bombeo') as bombeo_turbinado_mwh,
    -sum(mwh) filter (where concepto = 'consumo_bombeo') as bombeo_consumido_mwh,
    sum(mwh) filter (where concepto = 'baterias_entrega') as baterias_entregado_mwh,
    -sum(mwh) filter (where concepto = 'baterias_carga') as baterias_cargado_mwh,
    max(abs(pico_mw)) filter (where concepto = 'turbinacion_bombeo') as bombeo_turbinado_pico_mw,
    max(abs(pico_mw)) filter (where concepto = 'consumo_bombeo') as bombeo_consumido_pico_mw,
    max(abs(pico_mw)) filter (where concepto = 'baterias_entrega') as baterias_entregado_pico_mw,
    max(abs(pico_mw)) filter (where concepto = 'baterias_carga') as baterias_cargado_pico_mw
from {{ source('raw_almacenamiento', 'esios_almacenamiento_diario') }}
group by 1
