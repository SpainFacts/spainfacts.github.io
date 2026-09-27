-- Liquidación consolidada de cada comunidad autónoma por capítulo económico
-- (Ministerio de Hacienda, SGCIEF), 2002-último ejercicio cerrado, en euros.
-- ejecutado = derechos reconocidos netos (ingresos) u obligaciones reconocidas
-- netas (gastos); cobrado_pagado = ingresos o pagos líquidos del ejercicio.
-- Sin filas de totales: las páginas suman capítulos (1-7 = no financieros).
with nombres(tipo, capitulo, capitulo_nombre) as (
    values
        ('ingreso', 1, 'Impuestos directos'),
        ('ingreso', 2, 'Impuestos indirectos'),
        ('ingreso', 3, 'Tasas, precios públicos y otros ingresos'),
        ('ingreso', 4, 'Transferencias corrientes'),
        ('ingreso', 5, 'Ingresos patrimoniales'),
        ('ingreso', 6, 'Enajenación de inversiones reales'),
        ('ingreso', 7, 'Transferencias de capital'),
        ('ingreso', 8, 'Activos financieros'),
        ('ingreso', 9, 'Pasivos financieros'),
        ('gasto', 1, 'Gastos de personal'),
        ('gasto', 2, 'Gastos corrientes en bienes y servicios'),
        ('gasto', 3, 'Gastos financieros'),
        ('gasto', 4, 'Transferencias corrientes'),
        ('gasto', 5, 'Fondo de contingencia'),
        ('gasto', 6, 'Inversiones reales'),
        ('gasto', 7, 'Transferencias de capital'),
        ('gasto', 8, 'Activos financieros'),
        ('gasto', 9, 'Pasivos financieros')
)

select
    s.anio,
    s.cod_ccaa,
    s.tipo,
    s.capitulo,
    n.capitulo_nombre,
    s.presupuesto_inicial,
    s.presupuesto_definitivo,
    s.ejecutado,
    s.cobrado_pagado,
    s.anio || '-' || s.cod_ccaa || '-' || s.tipo || '-' || s.capitulo as clave
from {{ ref('stg_hacienda_ccaa_capitulos') }} as s
join nombres as n
  on n.tipo = s.tipo and n.capitulo = s.capitulo
order by s.anio, s.cod_ccaa, s.tipo desc, s.capitulo
