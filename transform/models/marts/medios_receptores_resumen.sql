-- Resumen del buscador «Quién recibe qué» (medios_receptores): una fila por medio,
-- año y vía (publicidad institucional del Estado, publicidad comercial de empresas del
-- Estado, publicidad institucional autonómica/local, contrato, subvención) con el importe
-- en euros de 2025, el número de pagos y de administraciones pagadoras distintas; y los
-- totales del medio repetidos en cada fila (todos los años y 2019-2025, total y por vía)
-- para el desplegable y el ranking.
-- - Sin las filas duplicado_probable de medios_receptores.
-- - en_ranking = medio privado que no es una plataforma digital (Google, Meta...). Los
--   medios públicos (RTVE, radiotelevisiones autonómicas, EFE) tienen su propio puesto
--   (rango_publicos) y no compiten con los privados.
-- - rango_privados = puesto por total_2019_2025_eur_real entre los medios de en_ranking.
-- - Las vías no son homogéneas: la publicidad del Estado por medio solo existe para 2025,
--   la territorial solo de las comunidades y ayuntamientos que publican el medio, los
--   contratos son un mínimo documentado (desde 2018) y las subvenciones empiezan en 2022.
with r as (select * from {{ ref('medios_receptores') }} where not duplicado_probable),

anual as (
    select medio_id, anio, via,
        sum(importe_eur_nominal) as importe_eur_nominal,
        sum(importe_eur_real) as importe_eur_real,
        count(*) as n_pagos,
        count(distinct administracion) as n_administraciones,
        count(distinct gobierno) as n_gobiernos
    from r
    group by all
),

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
),

rangos as (
    select *,
        titularidad = 'privada' and not es_plataforma as en_ranking,
        case when titularidad = 'privada' and not es_plataforma
            then rank() over (partition by titularidad = 'privada' and not es_plataforma order by coalesce(total_2019_2025_eur_real, 0) desc) end as rango_privados,
        case when titularidad = 'publica'
            then rank() over (partition by titularidad = 'publica' order by coalesce(total_2019_2025_eur_real, 0) desc) end as rango_publicos
    from totales
)

select
    a.medio_id, t.medio, t.grupo, t.tipo_medio, t.titularidad, t.es_plataforma, t.en_ranking,
    a.anio, a.via,
    a.importe_eur_nominal, a.importe_eur_real, a.n_pagos, a.n_administraciones, a.n_gobiernos,
    t.total_eur_real, t.total_eur_nominal, t.total_2019_2025_eur_real,
    t.estado_institucional_eur_real, t.estado_comercial_eur_real, t.territorial_eur_real,
    t.contratos_eur_real, t.subvenciones_eur_real,
    t.n_pagos_total, t.n_administraciones_total, t.n_gobiernos_total,
    t.anio_min, t.anio_max, t.niveles_asignacion,
    cast(t.rango_privados as integer) as rango_privados,
    cast(t.rango_publicos as integer) as rango_publicos
from anual a
join rangos t using (medio_id)
