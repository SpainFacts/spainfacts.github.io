-- Una fila por incendio cartografiado por EFFIS (Copernicus) en España, desde 2000.
with base as (
    select * from {{ ref('stg_effis_areas_quemadas') }}
)

select
    id,
    fecha,
    anio,
    fecha_actualizacion,
    cod_prov,
    coalesce(provincia, provincia_effis) as provincia,
    provincia_effis,
    municipio,
    area_ha,
    latitud,
    longitud,
    round(area_ha * pct_natura2000 / 100, 1) as ha_natura2000,
    pct_natura2000,
    pct_frondosas + pct_coniferas + pct_bosque_mixto as pct_arbolado,
    pct_esclerofila + pct_matorral_transicion as pct_matorral,
    pct_otra_natural,
    pct_agricola,
    pct_artificial + pct_otras as pct_otras,
    -- Cubierta dominante (la de mayor porcentaje entre los grandes grupos)
    case greatest(
            pct_frondosas + pct_coniferas + pct_bosque_mixto,
            pct_esclerofila + pct_matorral_transicion,
            pct_otra_natural,
            pct_agricola,
            pct_artificial + pct_otras
        )
        when pct_frondosas + pct_coniferas + pct_bosque_mixto then 'Arbolado'
        when pct_esclerofila + pct_matorral_transicion then 'Matorral'
        when pct_otra_natural then 'Pastos y otra vegetación natural'
        when pct_agricola then 'Agrícola'
        else 'Otras'
    end as cubierta_principal
from base
