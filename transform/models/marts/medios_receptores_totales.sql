-- Totales de cada medio en «Quién recibe qué»: una fila por medio, con todo lo recibido
-- (todos los años, 2019-2025, y por vía), el número de pagos y de administraciones, el
-- primer y último año con pagos y los puestos del ranking. Sale de medios_receptores
-- (sin duplicados probables). Los importes por año y vía están en
-- medios_receptores_resumen.
-- - en_ranking = medio privado que no es una plataforma digital (Google, Meta...). Los
--   medios públicos (RTVE, radiotelevisiones autonómicas, EFE) tienen su propio puesto
--   (rango_publicos) y no compiten con los privados.
-- - rango_privados = puesto por total_2019_2025_eur_real entre los medios de en_ranking.
-- - Las vías no son homogéneas: la publicidad del Estado por medio solo existe para 2025,
--   la territorial solo de las comunidades y ayuntamientos que publican el medio, los
--   contratos son un mínimo documentado (desde 2018) y las subvenciones empiezan en 2022 (2018 las del Gobierno Vasco, del BOPV).
with r as (select * from {{ ref('medios_receptores') }}),

totales as (
    select medio_id,
        any_value(medio) as medio,
        any_value(grupo) as grupo,
        any_value(tipo_medio) as tipo_medio,
        any_value(titularidad) as titularidad,
        bool_or(es_plataforma) as es_plataforma,
        sum(importe_eur_real) as total_eur_real,
        sum(importe_eur_nominal) as total_eur_nominal,
        sum(importe_eur_real) filter (where anio between 2019 and 2025) as total_2019_2025_eur_real,
        sum(importe_eur_real) filter (where via = 'Publicidad institucional del Estado') as estado_institucional_eur_real,
        sum(importe_eur_real) filter (where via = 'Publicidad comercial de empresas del Estado') as estado_comercial_eur_real,
        sum(importe_eur_real) filter (where via = 'Publicidad institucional autonómica/local') as territorial_eur_real,
        sum(importe_eur_real) filter (where via = 'Contrato') as contratos_eur_real,
        sum(importe_eur_real) filter (where via = 'Subvención') as subvenciones_eur_real,
        count(*) as n_pagos_total,
        count(distinct administracion) as n_administraciones_total,
        count(distinct gobierno) as n_gobiernos_total,
        min(anio) as anio_min,
        max(anio) as anio_max,
        string_agg(distinct nivel_asignacion, ', ' order by nivel_asignacion) as niveles_asignacion
    from r
    group by medio_id
)

select *,
    titularidad = 'privada' and not es_plataforma as en_ranking,
    cast(case when titularidad = 'privada' and not es_plataforma
        then rank() over (partition by titularidad = 'privada' and not es_plataforma order by coalesce(total_2019_2025_eur_real, 0) desc) end as integer) as rango_privados,
    cast(case when titularidad = 'publica'
        then rank() over (partition by titularidad = 'publica' order by coalesce(total_2019_2025_eur_real, 0) desc) end as integer) as rango_publicos
from totales
