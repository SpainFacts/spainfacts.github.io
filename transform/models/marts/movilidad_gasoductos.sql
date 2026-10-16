-- Gasoductos y terminales de gas natural licuado (GNL) que tocan España según Global Energy
-- Monitor (CC BY 4.0), con el estado traducido. Los gasoductos llevan su trazado recortado a
-- España y la capacidad en miles de millones de m3 al año (bcm) cuando GEM la conoce; las
-- terminales, su capacidad de regasificación en millones de toneladas de GNL al año (mtpa).
select
    proyecto_id,
    nombre,
    tipo,
    case tipo when 'gasoducto' then 'Gasoducto' else 'Terminal de GNL (regasificadora)' end as tipo_texto,
    estado as estado_fuente,
    case estado
        when 'operating' then 'En servicio'
        when 'construction' then 'En construcción'
        when 'proposed' then 'Propuesto'
        when 'shelved' then 'Paralizado'
        when 'cancelled' then 'Cancelado'
        when 'mothballed' then 'Fuera de servicio'
        when 'retired' then 'Cerrado'
        else estado
    end as estado,
    estado = 'operating' as en_servicio,
    propietario,
    anio_inicio,
    capacidad,
    case unidad_capacidad when 'bcm/y of gas' then 'bcm/año' when 'mtpa of LNG' then 'Mt de GNL/año' else unidad_capacidad end as unidad_capacidad,
    paises,
    strpos(paises, ';') > 0 as internacional,
    latitud,
    longitud,
    longitud_km_espana,
    trazado
from {{ source('raw_oleoductos', 'oleoductos_gem') }}
-- duplicados de GEM con el mismo nombre (Reganosa) se conservan: son tramos distintos
