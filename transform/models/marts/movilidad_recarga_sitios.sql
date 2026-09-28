-- Emplazamientos de recarga de acceso público (foto del día, NAP DGT / MITECO):
-- un registro por emplazamiento con sus puntos y la potencia máxima.
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
