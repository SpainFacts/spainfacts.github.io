-- Liquidación consolidada de cada comunidad autónoma por capítulo económico
-- (Ministerio de Hacienda, SGCIEF), 2002-último ejercicio cerrado, en euros.
-- ejecutado = derechos reconocidos netos (ingresos) u obligaciones reconocidas
-- netas (gastos); cobrado_pagado = ingresos o pagos líquidos del ejercicio.
-- Sin filas de totales: las páginas suman capítulos (1-7 = no financieros).
-- ejecutado_eur_hab_real: ejecutado por habitante (padrón del año, o el último anterior)
-- en euros constantes de anio_base (main.deflactor). El resto de importes, en euros corrientes.
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
),

pob as (
    select cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total'
),

base as (
    select
        s.anio,
        s.cod_ccaa,
        t.nombre as ccaa,
        s.tipo,
        s.capitulo,
        n.capitulo_nombre,
        s.presupuesto_inicial,
        s.presupuesto_definitivo,
        s.ejecutado,
        s.cobrado_pagado
    from {{ ref('stg_hacienda_ccaa_capitulos') }} as s
    join nombres as n
      on n.tipo = s.tipo and n.capitulo = s.capitulo
    left join {{ ref('territorios_ccaa') }} as t
      on t.cod_ccaa = s.cod_ccaa
)

select
    b.anio,
    b.cod_ccaa,
    b.ccaa,
    b.tipo,
    b.capitulo,
    b.capitulo_nombre,
    b.presupuesto_inicial,
    b.presupuesto_definitivo,
    b.ejecutado,
    b.cobrado_pagado,
    b.ejecutado * d.factor / p.poblacion as ejecutado_eur_hab_real,
    d.anio_base,
    b.anio || '-' || b.cod_ccaa || '-' || b.tipo || '-' || b.capitulo as clave
from base as b
asof left join pob as p
  on p.cod = b.cod_ccaa and p.anio <= b.anio
left join {{ ref('deflactor') }} as d
  on d.anio = cast(b.anio as integer)
order by b.anio, b.cod_ccaa, b.tipo desc, b.capitulo
