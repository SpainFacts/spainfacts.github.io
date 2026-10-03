-- Productos industriales con nombre propio: producción de España frente a la UE (Eurostat,
-- Prodcom, Comext DS-059358 «Sold production», raw.eurostat_industria_prodcom). Una fila por
-- producto y año (2015-último).
--   cantidad_*: producción vendida en la unidad del producto (unidad: M2 metros cuadrados,
--     KG kilogramos, P/ST piezas o unidades, L litros, CGT arqueo compensado de buques; se convierte a una unidad legible en
--     unidad_legible / *_legible: millones de m², miles de toneladas, millones de litros, unidades).
--   *_ue: agregado EU27_2020 de Eurostat (estimación redondeada que incluye los países
--     con dato confidencial); si falta, la suma de los países que publican el dato (`nota`).
--   puesto_*: posición de España entre los países que publican el dato (n_paises_*), que pueden
--     ser pocos: «1.º de los que publican», no necesariamente de la UE.
--   veces_peso_poblacion: cuota en cantidad / peso de España en la población de la UE.
--   cantidad_por_1000_hab_es: producción de España por 1.000 habitantes (población media de
--     Eurostat nama_10_pe).
--   valor_es_real_meur: valor de la producción vendida de España en millones de euros
--     constantes de anio_base (main.deflactor).
--   es_ultimo_anio: último año con cantidad de España y de la UE.
with p as (
    select cast(anio as integer) as anio, pais, producto, producto_nombre, producto_nombre_en,
           unidad, cantidad, valor_eur
    from {{ source('raw_industria', 'eurostat_industria_prodcom') }}
),

agregado as (
    select
        anio,
        producto,
        max(producto_nombre) as producto_nombre,
        max(producto_nombre_en) as producto_nombre_en,
        max(unidad) as unidad,
        max(case when pais = 'ES' and cantidad > 0 then cantidad end) as cantidad_es,
        max(case when pais = 'EU27_2020' and cantidad > 0 then cantidad end) as cantidad_ue_agregado,
        sum(case when pais <> 'EU27_2020' and cantidad > 0 then cantidad end) as cantidad_ue_suma,
        count(case when pais <> 'EU27_2020' and cantidad > 0 then 1 end) as n_paises_cantidad,
        arg_max(pais, cantidad) filter (where pais <> 'EU27_2020' and cantidad > 0) as lider_cantidad,
        max(case when pais = 'ES' and valor_eur > 0 then valor_eur end) as valor_es_eur,
        max(case when pais = 'EU27_2020' and valor_eur > 0 then valor_eur end) as valor_ue_agregado,
        sum(case when pais <> 'EU27_2020' and valor_eur > 0 then valor_eur end) as valor_ue_suma,
        count(case when pais <> 'EU27_2020' and valor_eur > 0 then 1 end) as n_paises_valor,
        arg_max(pais, valor_eur) filter (where pais <> 'EU27_2020' and valor_eur > 0) as lider_valor
    from p
    group by all
),

puestos as (
    select
        a.anio,
        a.producto,
        1 + count(*) filter (where p.pais not in ('ES', 'EU27_2020') and p.cantidad > a.cantidad_es) as puesto_cantidad,
        1 + count(*) filter (where p.pais not in ('ES', 'EU27_2020') and p.valor_eur > a.valor_es_eur) as puesto_valor
    from agregado a
    join p using (anio, producto)
    group by all
),

poblacion as (
    select
        cast(anio as integer) as anio,
        max(case when pais = 'ES' then miles end) as poblacion_es_miles,
        100.0 * max(case when pais = 'ES' then miles end) / max(case when pais = 'EU27_2020' then miles end)
            as cuota_poblacion_pct
    from {{ source('raw_industria', 'eurostat_industria_poblacion') }}
    group by 1
),

calc as (
    select
        a.*,
        coalesce(a.cantidad_ue_agregado, a.cantidad_ue_suma) as cantidad_ue,
        coalesce(a.valor_ue_agregado, a.valor_ue_suma) as valor_ue_eur,
        case when a.cantidad_es is not null then pu.puesto_cantidad end as puesto_cantidad,
        case when a.valor_es_eur is not null then pu.puesto_valor end as puesto_valor,
        case a.unidad when 'M2' then 1e6 when 'KG' then 1e6 when 'L' then 1e6 else 1 end as divisor,
        case a.unidad when 'M2' then 'millones de m²' when 'KG' then 'miles de toneladas' when 'P/ST' then 'unidades' when 'L' then 'millones de litros'
             when 'CGT' then 'arqueo bruto compensado (CGT)'
             else a.unidad end as unidad_legible
    from agregado a
    left join puestos pu using (anio, producto)
),

ultimo as (
    select producto, max(anio) as anio from calc
    where cantidad_es is not null and cantidad_ue is not null group by 1
)

select
    c.producto,
    c.producto_nombre,
    c.producto_nombre_en,
    c.anio,
    c.anio = u.anio as es_ultimo_anio,
    c.unidad,
    c.unidad_legible,
    c.cantidad_es,
    c.cantidad_ue,
    c.cantidad_es / c.divisor as cantidad_es_legible,
    c.cantidad_ue / c.divisor as cantidad_ue_legible,
    100.0 * c.cantidad_es / nullif(c.cantidad_ue, 0) as cuota_cantidad_pct,
    c.puesto_cantidad,
    c.n_paises_cantidad,
    c.lider_cantidad,
    nl.pais_nombre as lider_cantidad_nombre,
    c.valor_es_eur,
    c.valor_es_eur / 1e6 * d.factor as valor_es_real_meur,
    d.anio_base,
    c.valor_ue_eur,
    100.0 * c.valor_es_eur / nullif(c.valor_ue_eur, 0) as cuota_valor_pct,
    c.puesto_valor,
    c.n_paises_valor,
    c.lider_valor,
    po.cuota_poblacion_pct,
    (100.0 * c.cantidad_es / nullif(c.cantidad_ue, 0)) / po.cuota_poblacion_pct as veces_peso_poblacion,
    c.cantidad_es / nullif(po.poblacion_es_miles, 0) as cantidad_por_1000_hab_es,
    concat_ws('; ',
        case when c.cantidad_ue_agregado is null and c.cantidad_es is not null
             then 'UE = suma de los países que publican la cantidad (sin estimación de Eurostat)' end,
        case when c.n_paises_cantidad < 27
             then 'puesto entre ' || c.n_paises_cantidad || ' países que publican la cantidad' end
    ) as nota
from calc c
left join ultimo u using (producto)
left join poblacion po on po.anio = c.anio
left join {{ ref('deflactor') }} d on d.anio = c.anio
left join {{ ref('industria_paises') }} nl on nl.pais = c.lider_cantidad
where c.cantidad_es is not null or c.valor_es_eur is not null
