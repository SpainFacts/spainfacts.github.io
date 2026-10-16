-- IMD (intensidad media diaria: vehículos al día sumando los dos sentidos) por tramo de la Red de
-- Carreteras del Estado, del último año que tiene cada carretera, con el número y el % de
-- vehículos pesados. Los tramos seguidos de una carretera medidos por la misma estación de aforo
-- (misma IMD y % de pesados) van en una sola fila con todos sus trozos en el trazado.
select
    carretera,
    min(pk_inicio) as pk_inicio,
    max(pk_fin) as pk_fin,
    sum(longitud_km) as longitud_km,
    imd,
    pesados_pct,
    round(imd * pesados_pct / 100) as imd_pesados,
    anio,
    coalesce(any_value(titular), 'Estado') as titular,
    string_agg(trazado, '|') as trazado
from {{ source('raw_carreteras', 'carreteras_imd') }}
where imd > 0
group by carretera, imd, pesados_pct, anio
