-- Emplazamientos de recarga de acceso público (foto del día, NAP DGT / MITECO):
-- un registro por emplazamiento con sus puntos y la potencia máxima.
with s as (
    select
        sitio_id,
        any_value(sitio) as sitio,
        any_value(operador) as operador,
        avg(latitud) as latitud,
        avg(longitud) as longitud,
        any_value(cod_mun) as cod_mun,
        any_value(cod_prov) as cod_prov,
        count(*) as puntos,
        max(potencia_kw) as potencia_max_kw,
        sum(coalesce(potencia_kw, 0)) as potencia_total_kw,
        case
            when max(potencia_kw) >= 150 then 'Ultrarrápida (≥150 kW)'
            when max(potencia_kw) >= 50 then 'Rápida (50-149 kW)'
            when max(potencia_kw) >= 22 then 'Semirrápida (22-49 kW)'
            else 'Lenta (<22 kW)'
        end as tramo,
        case
            when max(potencia_kw) >= 150 then 1
            when max(potencia_kw) >= 50 then 2
            when max(potencia_kw) >= 22 then 3
            else 4
        end as tramo_orden
    from {{ source('raw_movilidad', 'recarga_puntos') }}
    where latitud is not null
    group by sitio_id
)
select
    s.sitio_id,
    s.sitio,
    s.operador,
    s.latitud,
    s.longitud,
    s.cod_mun,
    m.municipio,
    s.cod_prov,
    pr.nombre as provincia,
    pr.cod_ccaa,
    c.nombre as ccaa,
    s.puntos,
    s.potencia_max_kw,
    s.potencia_total_kw,
    s.tramo,
    s.tramo_orden
from s
left join (
    select cod_mun, municipio from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
    qualify anio = max(anio) over ()
) m on m.cod_mun = s.cod_mun
left join {{ ref('territorios_provincias') }} pr on pr.cod_prov = s.cod_prov
left join {{ ref('territorios_ccaa') }} c on c.cod_ccaa = pr.cod_ccaa
