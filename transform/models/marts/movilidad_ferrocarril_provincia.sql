-- Km de red ferroviaria (corredor) por provincia: total, por tipo, por 100.000 habitantes y
-- parte de ancho ibérico sin electrificar.
with km as (
    select
        cod_prov,
        sum(km) as km_red,
        sum(km) filter (where tipo = 'alta_velocidad') as km_alta_velocidad,
        sum(km) filter (where tipo = 'estandar') as km_estandar,
        sum(km) filter (where tipo = 'iberica_electrificada') as km_iberica_electrificada,
        sum(km) filter (where tipo = 'iberica_sin_electrificar') as km_iberica_sin_electrificar,
        sum(km) filter (where tipo = 'metrica') as km_metrica
    from {{ source('raw_ferrocarril', 'ferrocarril_red_provincia') }}
    group by cod_prov
),

poblacion as (
    select cod as cod_prov, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'provincia' and sexo = 'Total'
    qualify row_number() over (partition by cod order by anio desc) = 1
)

select
    t.cod_prov,
    t.nombre as provincia,
    t.cod_ccaa,
    coalesce(k.km_red, 0) as km_red,
    coalesce(k.km_alta_velocidad, 0) as km_alta_velocidad,
    coalesce(k.km_estandar, 0) as km_estandar,
    coalesce(k.km_iberica_electrificada, 0) as km_iberica_electrificada,
    coalesce(k.km_iberica_sin_electrificar, 0) as km_iberica_sin_electrificar,
    coalesce(k.km_metrica, 0) as km_metrica,
    100.0 * coalesce(k.km_iberica_sin_electrificar, 0) / nullif(k.km_red, 0) as sin_electrificar_pct,
    100000.0 * k.km_red / nullif(h.poblacion, 0) as km_por_100k_hab,
    h.poblacion
from {{ ref('territorios_provincias') }} t
left join km k on k.cod_prov = t.cod_prov
left join poblacion h on h.cod_prov = t.cod_prov
