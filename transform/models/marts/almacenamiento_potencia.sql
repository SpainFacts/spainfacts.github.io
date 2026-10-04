-- Potencia instalada de almacenamiento por comunidad y mes (ESIOS): bombeo
-- puro (sin contar el bombeo mixto, que ESIOS no desglosa) y baterías
-- hibridadas con renovables (desde mayo de 2023). No hay dato público de las
-- baterías independientes ("stand-alone").
with base as (
    select
        cast(mes as date) as mes,
        tipo,
        case ccaa
            when 'Islas Baleares' then 'Illes Balears'
            when 'Islas Canarias' then 'Canarias'
            else ccaa
        end as ccaa,
        max(mw) as mw
    from {{ source('raw_almacenamiento', 'esios_almacenamiento_potencia') }}
    group by all
)
select
    b.mes as fecha,
    year(b.mes) as anio,
    b.mes = max(b.mes) over () as es_ultimo,
    b.tipo,
    c.cod_ccaa,
    c.nombre as ccaa,
    b.mw
from base b
left join {{ ref('territorios_ccaa') }} c on c.nombre = b.ccaa
