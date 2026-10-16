-- Red ferroviaria de España (OpenStreetMap): una fila por tipo, línea de Adif, nombre y
-- operador, con todos sus trozos en el trazado («lon,lat;...|lon,lat;...», el formato del modo
-- líneas de MapaEspana). Las vías paralelas de una línea de vía doble están fundidas: la
-- longitud es la del corredor, no la de vía.
select
    tipo,
    case tipo
        when 'alta_velocidad' then 1 when 'estandar' then 2 when 'iberica_electrificada' then 3
        when 'iberica_sin_electrificar' then 4 when 'metrica' then 5
    end as tipo_orden,
    ref as linea_adif,
    nombre,
    case when upper(operador) like 'ADIF%' then 'Adif' when upper(operador) like 'RENFE%' then 'Renfe' else operador end as operador,
    max(vmax) as velocidad_maxima,
    sum(longitud_km) as longitud_km,
    string_agg(trazado, '|') as trazado
from {{ source('raw_ferrocarril', 'ferrocarril_red') }}
group by all
