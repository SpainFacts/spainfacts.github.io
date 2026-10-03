-- Sector primario de los 27 países de la UE en formato largo: una fila por producto,
-- país y año, con la población media del país. Es la base de primario_ranking_ue y
-- primario_serie_espana, y sirve para comparar países en cualquier producto.
-- Fuentes (pipeline dlt `primario`, ingestion/primario.py):
--   cultivo     Eurostat apro_cpsh1: producción cosechada (miles de t a humedad UE) y
--               superficie (miles de ha) de olivar, viñedo, cítricos y almendro.
--   ganaderia   Eurostat apro_mt_pann (carne sacrificada en matadero, miles de t),
--               apro_mt_lspig / lssheep / lscatl (cabaña de noviembre-diciembre, miles de
--               cabezas) y apro_mk_cola (leche de vaca entregada a centrales, miles de t).
--   pesca       Eurostat fish_ca_main (capturas, t -> miles de t), fish_aq2a (acuicultura,
--               t -> miles de t y EUR -> M EUR) y fish_fleet_alt (arqueo GT -> miles de GT;
--               número de buques).
--   valor       Eurostat aact_eaa01: valor de la producción a precios básicos, M EUR corrientes.
--   exportacion Eurostat Comext DS-045409: exportaciones a todo el mundo (incluido el
--               comercio dentro de la UE), EUR -> M EUR y 100 kg -> miles de t.
-- Solo los 27 países (el agregado EU27_2020 se calcula sumando países en los marts).
-- poblacion_miles: Eurostat nama_10_pe (población media); el año sin dato toma el último
-- disponible. nota: advertencias del producto (reexportación de Países Bajos, vino en las
-- cuentas agrarias...).
with catalogo as (
    select * from (values
        -- categoria, producto_id, producto, unidad, nota
        ('cultivo', 'O1000_prod', 'Aceituna', 'miles de t', null),
        ('cultivo', 'O1000_sup', 'Olivar (superficie)', 'miles de ha', null),
        ('cultivo', 'T0000_prod', 'Cítricos', 'miles de t', null),
        ('cultivo', 'T0000_sup', 'Cítricos (superficie)', 'miles de ha', null),
        ('cultivo', 'T1000_prod', 'Naranja', 'miles de t', null),
        ('cultivo', 'T2000_prod', 'Mandarina y pequeños cítricos', 'miles de t', null),
        ('cultivo', 'T3000_prod', 'Limón y lima', 'miles de t', null),
        ('cultivo', 'V0000_S0000_prod', 'Hortalizas frescas (con melón) y fresa', 'miles de t', null),
        ('cultivo', 'V3100_prod', 'Tomate', 'miles de t', null),
        ('cultivo', 'V3600_prod', 'Pimiento', 'miles de t', null),
        ('cultivo', 'V2300_prod', 'Lechuga', 'miles de t', null),
        ('cultivo', 'V3510_prod', 'Melón', 'miles de t', null),
        ('cultivo', 'V3520_prod', 'Sandía', 'miles de t', null),
        ('cultivo', 'V4600_prod', 'Ajo', 'miles de t', null),
        ('cultivo', 'V4200_prod', 'Cebolla y chalota', 'miles de t', null),
        ('cultivo', 'S0000_prod', 'Fresa', 'miles de t', null),
        ('cultivo', 'F1200_prod', 'Fruta de hueso', 'miles de t', null),
        ('cultivo', 'F1210_1220_prod', 'Melocotón y nectarina', 'miles de t', null),
        ('cultivo', 'F1240_prod', 'Cereza y guinda', 'miles de t', null),
        ('cultivo', 'F4300_prod', 'Almendra', 'miles de t', null),
        ('cultivo', 'F4300_sup', 'Almendro (superficie)', 'miles de ha', null),
        ('cultivo', 'F2300_prod', 'Aguacate', 'miles de t', null),
        ('cultivo', 'F1110_prod', 'Manzana', 'miles de t', null),
        ('cultivo', 'W1000_prod', 'Uva', 'miles de t', null),
        ('cultivo', 'W1000_sup', 'Viñedo (superficie)', 'miles de ha', null),
        ('cultivo', 'W1100_prod', 'Uva de vinificación', 'miles de t', null),
        ('cultivo', 'W1200_prod', 'Uva de mesa', 'miles de t', null),
        ('cultivo', 'C0000_prod', 'Cereales', 'miles de t', null),
        ('cultivo', 'C1100_prod', 'Trigo', 'miles de t', null),
        ('cultivo', 'C1300_prod', 'Cebada', 'miles de t', null),
        ('cultivo', 'C1500_prod', 'Maíz en grano', 'miles de t', null),
        ('cultivo', 'C2000_prod', 'Arroz', 'miles de t', null),
        ('cultivo', 'I1120_prod', 'Girasol', 'miles de t', null),
        ('cultivo', 'R1000_prod', 'Patata', 'miles de t', null),
        ('ganaderia', 'B3100', 'Carne de porcino', 'miles de t', 'Sacrificio en matadero (peso en canal).'),
        ('ganaderia', 'B1000', 'Carne de bovino', 'miles de t', 'Sacrificio en matadero (peso en canal).'),
        ('ganaderia', 'B7000', 'Carne de aves', 'miles de t', 'Sacrificio en matadero (peso en canal).'),
        ('ganaderia', 'B4100', 'Carne de ovino', 'miles de t', 'Sacrificio en matadero (peso en canal).'),
        ('ganaderia', 'B4200', 'Carne de caprino', 'miles de t', 'Sacrificio en matadero (peso en canal).'),
        ('ganaderia', 'A3100', 'Cabaña porcina', 'miles de cabezas', 'Censo de noviembre-diciembre.'),
        ('ganaderia', 'A4100', 'Cabaña ovina', 'miles de cabezas', 'Censo de noviembre-diciembre; solo publican los países con más de 500.000 ovejas.'),
        ('ganaderia', 'A4200', 'Cabaña caprina', 'miles de cabezas', 'Censo de noviembre-diciembre; no todos los países lo publican.'),
        ('ganaderia', 'A2000', 'Cabaña bovina', 'miles de cabezas', 'Censo de noviembre-diciembre.'),
        ('ganaderia', 'D1110D', 'Leche de vaca', 'miles de t', 'Leche cruda de vaca entregada a las centrales lecheras.'),
        ('pesca', 'capturas', 'Capturas de pesca', 'miles de t', 'Peso vivo, todas las zonas de pesca. Irlanda y Portugal no publican capturas en Eurostat en los últimos años.'),
        ('pesca', 'acuicultura_t', 'Acuicultura (volumen)', 'miles de t', 'Peso vivo; en España es sobre todo mejillón.'),
        ('pesca', 'acuicultura_eur', 'Acuicultura (valor)', 'M EUR', 'Euros corrientes.'),
        ('pesca', 'flota_gt', 'Flota pesquera (arqueo)', 'miles de GT', 'Arqueo bruto de la flota registrada a 31 de diciembre.'),
        ('pesca', 'flota_nr', 'Flota pesquera (buques)', 'buques', 'Número de buques registrados.'),
        ('valor', 'AM160000', 'Producción de la rama agraria', 'M EUR', 'Valor a precios básicos, euros corrientes.'),
        ('valor', 'AM100000', 'Producción vegetal', 'M EUR', 'Valor a precios básicos, euros corrientes.'),
        ('valor', 'AM060000', 'Frutas (valor)', 'M EUR', 'Valor a precios básicos, euros corrientes; incluye cítricos, uva y aceituna.'),
        ('valor', 'AM040000', 'Hortalizas y horticultura (valor)', 'M EUR', 'Valor a precios básicos, euros corrientes; incluye plantas y flores.'),
        ('valor', 'AM080000', 'Aceite de oliva (valor)', 'M EUR', 'Valor a precios básicos, euros corrientes.'),
        ('valor', 'AM070000', 'Vino (valor)', 'M EUR', 'Infravalora a España: la mayor parte del vino lo elaboran bodegas y cooperativas fuera de la rama agraria y se contabiliza como uva vendida. Para comparar vino, usar OIV.'),
        ('valor', 'AM010000', 'Cereales (valor)', 'M EUR', 'Valor a precios básicos, euros corrientes.'),
        ('valor', 'AM110000', 'Animales (valor)', 'M EUR', 'Valor a precios básicos, euros corrientes.'),
        ('valor', 'AM112000', 'Porcino (valor)', 'M EUR', 'Valor a precios básicos, euros corrientes.'),
        ('valor', 'AM121000', 'Leche (valor)', 'M EUR', 'Valor a precios básicos, euros corrientes.'),
        ('exportacion', 'HS_TOTAL', 'Exportaciones de bienes (total)', 'M EUR', 'Comext, todos los destinos (incluida la UE), euros corrientes.'),
        ('exportacion', 'HS_07', 'Exportación de hortalizas (HS 07)', 'M EUR', 'Países Bajos aparece inflado por la reexportación desde Róterdam. Incluye el comercio dentro de la UE.'),
        ('exportacion', 'HS_0702', 'Exportación de tomate (HS 0702)', 'M EUR', 'Países Bajos aparece inflado por la reexportación. Incluye el comercio dentro de la UE.'),
        ('exportacion', 'HS_0709', 'Exportación de otras hortalizas, con pimiento (HS 0709)', 'M EUR', 'Países Bajos aparece inflado por la reexportación. Incluye el comercio dentro de la UE.'),
        ('exportacion', 'HS_08', 'Exportación de frutas y frutos secos (HS 08)', 'M EUR', 'Países Bajos aparece inflado por la reexportación. Incluye el comercio dentro de la UE.'),
        ('exportacion', 'HS_0805', 'Exportación de cítricos (HS 0805)', 'M EUR', 'Incluye el comercio dentro de la UE.'),
        ('exportacion', 'HS_0802', 'Exportación de frutos secos (HS 0802)', 'M EUR', 'Incluye el comercio dentro de la UE.'),
        ('exportacion', 'HS_0806', 'Exportación de uva y pasas (HS 0806)', 'M EUR', 'Incluye el comercio dentro de la UE.'),
        ('exportacion', 'HS_1509', 'Exportación de aceite de oliva (HS 1509)', 'M EUR', 'Incluye el comercio dentro de la UE.'),
        ('exportacion', 'HS_1509_t', 'Exportación de aceite de oliva (volumen)', 'miles de t', 'Incluye el comercio dentro de la UE.'),
        ('exportacion', 'HS_02', 'Exportación de carne (HS 02)', 'M EUR', 'Países Bajos aparece inflado por la reexportación. Incluye el comercio dentro de la UE.'),
        ('exportacion', 'HS_0203', 'Exportación de carne de porcino (HS 0203)', 'M EUR', 'Incluye el comercio dentro de la UE.'),
        ('exportacion', 'HS_0207', 'Exportación de carne de aves (HS 0207)', 'M EUR', 'Incluye el comercio dentro de la UE.'),
        ('exportacion', 'HS_1601', 'Exportación de embutidos (HS 1601)', 'M EUR', 'Incluye el comercio dentro de la UE. El jamón curado va en HS 0210, no en 1601.'),
        ('exportacion', 'HS_03', 'Exportación de pescado y marisco (HS 03)', 'M EUR', 'Países Bajos aparece inflado por la reexportación. Incluye el comercio dentro de la UE.'),
        ('exportacion', 'HS_2204', 'Exportación de vino (HS 2204)', 'M EUR', 'Incluye el comercio dentro de la UE.'),
        ('exportacion', 'HS_2204_t', 'Exportación de vino (volumen)', 'miles de t', 'Incluye el comercio dentro de la UE; en volumen España es segunda tras Italia.')
    ) as t(categoria, producto_id, producto, unidad, nota)
),

datos as (
    select crops || case strucpro when 'AR_THS_HA' then '_sup' else '_prod' end as producto_id,
           geo, anio, valor
    from {{ source('raw_primario', 'eurostat_cultivos') }}

    union all
    select item, geo, anio, valor
    from {{ source('raw_primario', 'eurostat_ganaderia') }}

    union all
    select case dataset || '_' || unidad
               when 'fish_ca_main_TLW' then 'capturas'
               when 'fish_aq2a_TLW' then 'acuicultura_t'
               when 'fish_aq2a_EUR' then 'acuicultura_eur'
               when 'fish_fleet_alt_GT' then 'flota_gt'
               when 'fish_fleet_alt_NR' then 'flota_nr'
           end,
           geo, anio,
           case when unidad = 'TLW' or unidad = 'GT' then valor / 1000
                when unidad = 'EUR' then valor / 1e6
                else valor end
    from {{ source('raw_primario', 'eurostat_pesca') }}

    union all
    select item, geo, anio, valor
    from {{ source('raw_primario', 'eurostat_cuentas_agricolas') }}
    where dataset = 'aact_eaa01' and indicador = 'PRD_BP'

    union all
    select 'HS_' || producto || case when indicador = 'QUANTITY_IN_100KG' then '_t' else '' end,
           reporter, anio,
           case when indicador = 'QUANTITY_IN_100KG' then valor / 10000 else valor / 1e6 end
    from {{ source('raw_primario', 'eurostat_exportaciones') }}
),

poblacion as (
    select geo, anio, valor as poblacion_miles
    from {{ source('raw_primario', 'eurostat_poblacion_paises') }}
    where valor is not null
)

select
    c.categoria,
    c.producto_id,
    c.producto,
    c.unidad,
    d.geo,
    p.pais,
    cast(d.anio as integer) as anio,
    cast(d.valor as double) as valor,
    coalesce(
        po.poblacion_miles,
        (select last(x.poblacion_miles order by x.anio) from poblacion x where x.geo = d.geo)
    ) as poblacion_miles,
    c.nota
from datos d
join catalogo c on c.producto_id = d.producto_id
join {{ ref('primario_paises') }} p on p.geo = d.geo and p.geo <> 'EU27_2020'
left join poblacion po on po.geo = d.geo and po.anio = d.anio
where d.valor is not null
order by c.categoria, c.producto_id, d.geo, d.anio
