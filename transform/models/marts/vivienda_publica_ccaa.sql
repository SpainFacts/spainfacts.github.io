-- Vivienda pública en alquiler por comunidad autónoma (una fila por comunidad):
-- parque autonómico en alquiler 2019 y 2023 (encuestas de vivienda social del
-- MIVAU; incluye colaboración público-privada, cesión a bajo precio y
-- alojamiento temporal), parque municipal declarado por los ayuntamientos de
-- más de 20.000 habitantes que respondieron (dato parcial), suma conocida por
-- 1.000 habitantes y en % de los hogares (padrón y hogares de la ECP a 1 de
-- enero de 2023), el último dato de la ECV (alquiler inferior al precio de
-- mercado, % de hogares; media de tres años por el tamaño de la muestra) y las
-- calificaciones provisionales de vivienda protegida en alquiler 2005-2023 por
-- 1.000 habitantes. En Ceuta y Melilla la ciudad autónoma es a la vez el
-- ayuntamiento: su parque se cuenta una sola vez (el autonómico).
-- familia_2019_2023: partido del Gobierno autonómico a mitad del periodo
-- (1-7-2021), para leer la variación 2019-2023 con cautela.
with parque as (
    select cod_ccaa,
        max(arrendamiento) filter (where anio = 2019) as autonomico_2019,
        max(arrendamiento) filter (where anio = 2023) as autonomico_2023,
        max(arrendamiento_publico) filter (where anio = 2023) as autonomico_titularidad_2023,
        max(arrendamiento_ppp) filter (where anio = 2023) as autonomico_ppp_2023,
        max(opcion_compra) filter (where anio = 2023) as opcion_compra_2023,
        max(venta) filter (where anio = 2023) as venta_2023,
        max(otras) filter (where anio = 2023) as otras_2023,
        max(total) filter (where anio = 2023) as total_autonomico_2023
    from {{ source('raw_vivienda_publica', 'vp_ccaa_parque') }}
    group by 1
),

municipal as (
    select cod_ccaa,
        sum(arrendamiento) filter (where cod_ccaa not in ('18', '19')) as municipal_declarado,
        count(*) filter (where origen <> 'sin_respuesta') as municipios_con_dato,
        count(*) as municipios_20k,
        sum(poblacion) filter (where origen <> 'sin_respuesta') as poblacion_con_dato
    from {{ source('raw_vivienda_publica', 'vp_municipios') }}
    group by 1
),

pob as (
    select cod, poblacion from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total' and anio = 2023
),

hogares as (
    select cod, hogares from {{ ref('demografia_hogares') }} where nivel = 'ccaa' and anio = 2023
),

ecv as (
    select cod_ccaa, anio, pct_alquiler_inferior,
        avg(pct_alquiler_inferior) over (partition by cod_ccaa order by anio rows between 2 preceding and current row) as media_3a
    from {{ ref('stg_vivienda_publica_ecv') }}
    qualify row_number() over (partition by cod_ccaa order by anio desc) = 1
),

calif as (
    select cod_ccaa, sum(viviendas) as calif_alquiler_2005_2023
    from {{ source('raw_vivienda_publica', 'vp_calificaciones') }}
    where regimen = 'alquiler' and cod_ccaa <> '00'
    group by 1
),

gobierno as (
    select cod, familia, presidente
    from {{ ref('gobiernos_presidentes') }}
    where nivel = 'autonomico' and desde <= date '2021-07-01' and coalesce(hasta, date '2100-01-01') > date '2021-07-01'
)

select
    t.cod_ccaa,
    t.nombre as comunidad,
    cast(pa.autonomico_2019 as integer) as autonomico_2019,
    cast(pa.autonomico_2023 as integer) as autonomico_2023,
    cast(pa.autonomico_2023 - pa.autonomico_2019 as integer) as variacion_2019_2023,
    100.0 * (pa.autonomico_2023 / nullif(pa.autonomico_2019, 0) - 1) as variacion_pct_2019_2023,
    cast(pa.autonomico_titularidad_2023 as integer) as autonomico_titularidad_2023,
    cast(pa.autonomico_ppp_2023 as integer) as autonomico_ppp_2023,
    cast(pa.opcion_compra_2023 as integer) as opcion_compra_2023,
    cast(pa.venta_2023 as integer) as venta_2023,
    cast(pa.otras_2023 as integer) as otras_2023,
    cast(pa.total_autonomico_2023 as integer) as total_autonomico_2023,
    cast(coalesce(m.municipal_declarado, 0) as integer) as municipal_declarado,
    cast(coalesce(m.municipios_con_dato, 0) as integer) as municipios_con_dato,
    cast(coalesce(m.municipios_20k, 0) as integer) as municipios_20k,
    cast(pa.autonomico_2023 + coalesce(m.municipal_declarado, 0) as integer) as alquiler_publico_conocido,
    cast(p.poblacion as bigint) as poblacion,
    cast(h.hogares as bigint) as hogares,
    1000.0 * pa.autonomico_2023 / p.poblacion as autonomico_1000hab,
    1000.0 * pa.autonomico_2019 / p.poblacion as autonomico_1000hab_2019,
    1000.0 * (pa.autonomico_2023 + coalesce(m.municipal_declarado, 0)) / p.poblacion as conocido_1000hab,
    100.0 * (pa.autonomico_2023 + coalesce(m.municipal_declarado, 0)) / h.hogares as conocido_pct_hogares,
    100.0 * coalesce(m.poblacion_con_dato, 0) / p.poblacion as cobertura_municipal_pct,
    e.anio as ecv_anio,
    e.pct_alquiler_inferior as ecv_pct_alquiler_inferior,
    e.media_3a as ecv_pct_alquiler_inferior_3a,
    cast(c.calif_alquiler_2005_2023 as integer) as calif_alquiler_2005_2023,
    1000.0 * c.calif_alquiler_2005_2023 / p.poblacion as calif_alquiler_2005_2023_1000hab,
    g.familia as familia_2019_2023,
    g.presidente as presidente_2019_2023
from {{ ref('territorios_ccaa') }} t
join parque pa on pa.cod_ccaa = t.cod_ccaa
left join municipal m on m.cod_ccaa = t.cod_ccaa
left join pob p on p.cod = t.cod_ccaa
left join hogares h on h.cod = t.cod_ccaa
left join ecv e on e.cod_ccaa = t.cod_ccaa
left join calif c on c.cod_ccaa = t.cod_ccaa
left join gobierno g on g.cod = t.cod_ccaa
order by conocido_1000hab desc
