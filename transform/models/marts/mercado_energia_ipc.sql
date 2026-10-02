-- IPC de la energía, mensual (INE, IPC base 2025): subclases ECOICOP v2 de
-- electricidad y combustibles líquidos (gasóleo de calefacción) desde 2002 y de
-- gas natural, hidrocarburos licuados (butano y propano), gasóleo y gasolina
-- desde 2017 (tabla 76128), más el grupo especial "Productos energéticos" y el
-- índice general (tabla 76130) como referencia.
--   indice_2019: índice con la media de 2019 = 100 (nivel de precios acumulado).
--   ponderacion: peso en la cesta del IPC (por mil) del último año publicado
--     (tablas 76159 y 76161).
--   contribucion_aprox: puntos de la inflación general que aporta, igual que en
--     mercado_ipc_grupos = ponderacion/1000 x índice hace 12 meses / índice
--     general hace 12 meses x var_anual (aproximación).
with sub as (
    select
        date_trunc('month', cast(epoch_ms(fecha) + interval 12 hour as date)) as mes,
        split_part(serie, '. ', 2) as producto_ine,
        split_part(serie, '. ', 3) as tipo,
        valor
    from {{ source('raw_mercado', 'ine_ipc_energia') }}
    union all
    select
        date_trunc('month', cast(epoch_ms(fecha) + interval 12 hour as date)),
        split_part(serie, '. ', 2),
        split_part(serie, '. ', 3),
        valor
    from {{ source('raw_mercado', 'ine_ipc_especiales') }}
    where split_part(serie, '. ', 2) in ('Productos energéticos', 'Índice general')
),

ancho as (
    select
        mes,
        producto_ine,
        max(valor) filter (where tipo = 'Índice') as indice,
        max(valor) filter (where tipo = 'Variación anual') as var_anual
    from sub
    where valor is not null
    group by all
),

pond as (
    select split_part(serie, '. ', 2) as producto_ine, valor as ponderacion, cast(anyo as integer) as anio_ponderacion
    from {{ source('raw_mercado', 'ine_ipc_ponderaciones_energia') }}
    where valor is not null
    qualify row_number() over (partition by split_part(serie, '. ', 2) order by anyo desc) = 1
),

con_lag as (
    select
        a.*,
        lag(a.indice, 12) over (partition by a.producto_ine order by a.mes) as indice_12m,
        avg(a.indice) filter (where year(a.mes) = 2019) over (partition by a.producto_ine) as media_2019
    from ancho a
),

general as (
    select mes, indice_12m as general_12m from con_lag where producto_ine = 'Índice general'
)
,

final as (
select
    c.mes,
    c.producto_ine,
    case c.producto_ine
        when 'Índice general' then 'IPC general'
        when 'Productos energéticos' then 'Energía (total)'
        when 'Hidrocarburos licuados' then 'Butano y propano'
        when 'Combustibles líquidos' then 'Gasóleo de calefacción'
        when 'Gasóleo' then 'Gasóleo de automoción'
        else c.producto_ine
    end as producto,
    c.indice,
    c.var_anual,
    100 * c.indice / c.media_2019 as indice_2019,
    p.ponderacion,
    p.anio_ponderacion,
    case when c.producto_ine <> 'Índice general'
        then p.ponderacion / 1000 * c.indice_12m / g.general_12m * c.var_anual end as contribucion_aprox
from con_lag c
left join general g on g.mes = c.mes
left join pond p on p.producto_ine = c.producto_ine
)

-- Sin los meses del IPC adelantado (solo índice general): ver la macro
{{ solo_meses_completos('final') }}
