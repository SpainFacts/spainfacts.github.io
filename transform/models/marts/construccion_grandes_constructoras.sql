-- Grandes constructoras españolas en el ranking mundial Global Powers of Construction de Deloitte
-- (seed construccion_constructoras, transcrito a mano de la página de Deloitte España; sin
-- licencia abierta: citar siempre la fuente). Una fila por empresa y edición. Los ingresos están
-- en millones de dólares corrientes (moneda del informe) y solo para ACS y Acciona.
select
    edicion,
    puesto,
    empresa,
    ingresos_mill_usd,
    ventas_internacionales_mill_usd,
    pct_ventas_exterior,
    fuente
from {{ ref('construccion_constructoras') }}
order by edicion, puesto
