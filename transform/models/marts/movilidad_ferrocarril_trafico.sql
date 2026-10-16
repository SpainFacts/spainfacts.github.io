-- Trenes de viajeros programados en un día laborable por tramo de la red (horarios GTFS de
-- Renfe, FGC, Euskotren y FGV trazados sobre la red de OpenStreetMap): una fila por línea y
-- número de trenes de cada clase, con todos sus trozos en el trazado. Sin Iryo, Ouigo ni trenes
-- de mercancías.
select
    trenes_dia,
    trenes_cercanias,
    trenes_media_distancia,
    trenes_larga_distancia,
    trenes_autonomico,
    any_value(tipo) as tipo,
    any_value(ref) as linea_adif,
    nombre,
    sum(longitud_km) as longitud_km,
    any_value(fecha_horarios) as fecha_horarios,
    string_agg(trazado, '|') as trazado
from {{ source('raw_ferrocarril', 'ferrocarril_trafico') }}
where trenes_dia > 0
group by trenes_dia, trenes_cercanias, trenes_media_distancia, trenes_larga_distancia, trenes_autonomico, nombre
