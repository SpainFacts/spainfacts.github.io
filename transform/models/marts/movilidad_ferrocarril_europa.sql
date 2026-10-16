-- Ferrocarril en Europa por país y año (Eurostat): km de líneas, de alta velocidad y
-- electrificadas, por 100.000 habitantes, y viajeros-km y toneladas-km por habitante.
with crudo as (
    select
        e.anio,
        p.cod_pais,
        p.pais,
        max(valor) filter (where indicador = 'km_lineas') as km_lineas,
        max(valor) filter (where indicador = 'km_lineas_ga') as km_lineas_ga,
        max(valor) filter (where indicador = 'km_alta_velocidad_dedicada') as km_av_dedicada,
        max(valor) filter (where indicador = 'km_alta_velocidad_adaptada') as km_av_adaptada,
        max(valor) filter (where indicador = 'km_electrificadas') as km_electrificadas,
        max(valor) filter (where indicador = 'millones_viajeros_km') as millones_viajeros_km,
        max(valor) filter (where indicador = 'millones_toneladas_km') as millones_toneladas_km
    from {{ source('raw_ferrocarril', 'ferrocarril_eurostat') }} e
    join {{ ref('paises_iso') }} p on p.eurostat = e.cod_fuente
    group by e.anio, p.cod_pais, p.pais
),

poblacion as (
    select cod_pais, anio, poblacion from {{ ref('poblacion_paises') }}
)

select
    c.anio,
    c.cod_pais,
    c.pais,
    c.km_lineas,
    coalesce(c.km_av_dedicada, 0) + coalesce(c.km_av_adaptada, 0) as km_alta_velocidad,
    c.km_av_dedicada as km_alta_velocidad_dedicada,
    100.0 * c.km_electrificadas / nullif(c.km_lineas_ga, 0) as electrificadas_pct,
    100000.0 * c.km_lineas / nullif(h.poblacion, 0) as km_por_100k_hab,
    100000.0 * (coalesce(c.km_av_dedicada, 0) + coalesce(c.km_av_adaptada, 0)) / nullif(h.poblacion, 0) as km_alta_velocidad_por_100k_hab,
    c.millones_viajeros_km,
    1e6 * c.millones_viajeros_km / nullif(h.poblacion, 0) as viajeros_km_hab,
    c.millones_toneladas_km,
    1e6 * c.millones_toneladas_km / nullif(h.poblacion, 0) as toneladas_km_hab
from crudo c
left join poblacion h on h.cod_pais = c.cod_pais and h.anio = c.anio
