-- Km de carretera de toda España por año (desde 1970), titular y tipo de vía (Anuario del
-- Ministerio de Transportes), con los km por 100.000 habitantes del año (sin población, NULL).
with poblacion as (
    select anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and sexo = 'Total'
)

select
    k.anio,
    k.titular,
    case k.titular when 'estado' then 1 when 'comunidad' then 2 when 'diputacion' then 3 end as titular_orden,
    k.tipo,
    case k.tipo when 'peaje' then 1 when 'autovia' then 2 when 'multicarril' then 3 when 'convencional' then 4 end as tipo_orden,
    k.km,
    100000.0 * k.km / nullif(h.poblacion, 0) as km_por_100k_hab
from {{ source('raw_carreteras', 'carreteras_longitud_espana') }} k
left join poblacion h on h.anio = k.anio
