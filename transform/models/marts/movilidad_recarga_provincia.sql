-- Puntos de recarga públicos por provincia frente a los turismos enchufables
-- (BEV + PHEV) del último parque de la DGT y la población.
with puntos as (
    select
        cod_prov,
        count(*) as puntos,
        count(*) filter (where potencia_kw >= 50) as puntos_rapidos,
        count(*) filter (where potencia_kw >= 150) as puntos_ultrarrapidos,
        count(distinct sitio_id) as sitios,
        sum(coalesce(potencia_kw, 0)) as potencia_kw
    from {{ source('raw_movilidad', 'recarga_puntos') }}
    where cod_prov is not null
    group by cod_prov
),

enchufables as (
    select cod_prov, sum(vehiculos) as turismos_enchufables
    from {{ ref('movilidad_parque_provincia') }}
    where grupo = 'turismo' and energia in ('bev', 'phev')
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
    t.cod_ccaa,
    t.nombre as provincia,
    coalesce(p.puntos, 0) as puntos,
    coalesce(p.puntos_rapidos, 0) as puntos_rapidos,
    coalesce(p.puntos_ultrarrapidos, 0) as puntos_ultrarrapidos,
    coalesce(p.sitios, 0) as sitios,
    coalesce(p.potencia_kw, 0) as potencia_kw,
    e.turismos_enchufables,
    e.turismos_enchufables / nullif(p.puntos, 0) as enchufables_por_punto,
    100000.0 * p.puntos / nullif(h.poblacion, 0) as puntos_por_100k_hab
from {{ ref('territorios_provincias') }} t
left join puntos p on p.cod_prov = t.cod_prov
left join enchufables e on e.cod_prov = t.cod_prov
left join poblacion h on h.cod_prov = t.cod_prov
