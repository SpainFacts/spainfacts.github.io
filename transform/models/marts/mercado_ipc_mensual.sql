-- IPC de España, una fila por mes desde 2002 (INE, IPC base 2025, tabla 76130
-- de grupos especiales):
--   indice / var_anual / var_mensual: índice general;
--   subyacente: general sin alimentos no elaborados ni productos energéticos;
--   energia: productos energéticos (electricidad, gas, carburantes...);
--   alimentos_sin_elaborar, alimentos_elaborados (incluye bebidas y tabaco),
--   bienes_industriales (sin energía) y servicios (sin alquiler de vivienda):
--   tasas anuales de cada grupo especial.
--   indice_2008 / indice_2019: índice general con la media de 2008 / 2019 = 100
--   (nivel de precios acumulado: 125 = los precios son un 25 % más altos).
--   perdida_poder_compra_2019: % de poder de compra que pierde un importe fijo
--   en euros desde la media de 2019 = (1 - 100 / indice_2019) x 100.
with base as (
    select
        cast(epoch_ms(fecha) + interval 12 hour as date) as mes,
        split_part(serie, '. ', 2) as grupo,
        split_part(serie, '. ', 3) as tipo,
        valor
    from {{ source('raw_mercado', 'ine_ipc_especiales') }}
    where valor is not null
),

ancho as (
    select
        date_trunc('month', mes) as mes,
        max(valor) filter (where grupo = 'Índice general' and tipo = 'Índice') as indice,
        max(valor) filter (where grupo = 'Índice general' and tipo = 'Variación anual') as var_anual,
        max(valor) filter (where grupo = 'Índice general' and tipo = 'Variación mensual') as var_mensual,
        max(valor) filter (where grupo like 'Subyacente%' and tipo = 'Variación anual') as subyacente,
        max(valor) filter (where grupo like 'Subyacente%' and tipo = 'Índice') as indice_subyacente,
        max(valor) filter (where grupo = 'Productos energéticos' and tipo = 'Variación anual') as energia,
        max(valor) filter (where grupo = 'Alimentos sin elaboración' and tipo = 'Variación anual') as alimentos_sin_elaborar,
        max(valor) filter (where grupo = 'Alimentos con elaboración, bebidas y tabaco' and tipo = 'Variación anual') as alimentos_elaborados,
        max(valor) filter (where grupo = 'Bienes industriales sin productos energéticos' and tipo = 'Variación anual') as bienes_industriales,
        max(valor) filter (where grupo = 'Servicios sin alquiler de vivienda' and tipo = 'Variación anual') as servicios
    from base
    group by 1
),

medias as (
    select
        avg(indice) filter (where year(mes) = 2008) as m2008,
        avg(indice) filter (where year(mes) = 2019) as m2019
    from ancho
)

select
    a.mes,
    cast(year(a.mes) as integer) as anio,
    a.indice,
    a.var_anual,
    a.var_mensual,
    a.subyacente,
    a.energia,
    a.alimentos_sin_elaborar,
    a.alimentos_elaborados,
    a.bienes_industriales,
    a.servicios,
    100 * a.indice / m.m2008 as indice_2008,
    100 * a.indice / m.m2019 as indice_2019,
    100 * (1 - m.m2019 / a.indice) as perdida_poder_compra_2019
from ancho a
cross join medias m
where a.indice is not null
