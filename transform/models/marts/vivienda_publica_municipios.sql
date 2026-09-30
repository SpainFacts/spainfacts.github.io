-- Parque de vivienda de titularidad municipal (ayuntamientos de más de 20.000
-- habitantes y sus entes dependientes) por régimen de tenencia (MIVAU, Tabla
-- 2.8 del Boletín especial Vivienda Social 2024), con el alquiler por 1.000
-- habitantes (padrón 2023). origen: encuesta_2023, boletin_2020 (dato de la
-- encuesta de 2019 repetido; sin desglose público/PPP) o sin_respuesta.
-- No incluye las viviendas de la comunidad autónoma situadas en el municipio.
select
    m.cod_prov,
    p.nombre as provincia,
    m.cod_ccaa,
    m.municipio,
    cast(m.poblacion as bigint) as poblacion,
    m.origen,
    cast(m.arrendamiento as integer) as alquiler,
    cast(m.arrendamiento_publico as integer) as alquiler_titularidad_publica,
    cast(m.arrendamiento_ppp as integer) as alquiler_ppp,
    cast(m.opcion_compra as integer) as opcion_compra,
    cast(m.venta as integer) as venta,
    cast(m.otras as integer) as otras,
    cast(m.total as integer) as total,
    1000.0 * m.arrendamiento / m.poblacion as alquiler_1000hab
from {{ source('raw_vivienda_publica', 'vp_municipios') }} m
left join {{ ref('territorios_provincias') }} p on p.cod_prov = m.cod_prov
