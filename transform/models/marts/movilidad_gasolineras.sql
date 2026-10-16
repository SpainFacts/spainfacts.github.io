-- Gasolineras (estaciones de servicio terrestres) de la foto actual del geoportal del
-- Ministerio, con su grupo empresarial (seed carburantes_rotulos_grupos: gana el patrón más
-- largo que casa con el rótulo) y los precios del momento de la carga.
with estaciones as (
    select * from {{ source('raw_carburantes', 'carburantes_estaciones') }}
    where tipo_venta = 'P' or tipo_venta is null
),

grupo as (
    select e.ideess, g.grupo, g.tipo
    from estaciones e
    join {{ ref('carburantes_rotulos_grupos') }} g
        on e.rotulo = g.patron or e.rotulo like g.patron || ' %'
    qualify row_number() over (partition by e.ideess order by length(g.patron) desc) = 1
),

municipios as (
    select cod_mun, municipio
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
    qualify row_number() over (partition by cod_mun order by anio desc) = 1
)

select
    e.ideess,
    e.rotulo,
    coalesce(g.grupo, case when e.rotulo = 'SIN ROTULO' then 'Sin rótulo' else array_to_string(list_transform(string_split(lower(e.rotulo), ' '), w -> upper(w[1]) || w[2:]), ' ') end) as grupo,
    coalesce(g.tipo, 'Independiente u otra') as tipo,
    coalesce(e.cod_mun, '') <> '' as municipio_asignado,
    e.cod_mun,
    coalesce(m.municipio, e.municipio_fuente) as municipio,
    e.cod_prov,
    p.nombre as provincia,
    p.cod_ccaa,
    e.direccion,
    e.horario,
    e.abierta_24h,
    e.latitud,
    e.longitud,
    e.precio_gasoleo_a,
    e.precio_gasolina_95,
    e.precio_glp,
    e.precio_gasoleo_premium,
    e.precio_gasolina_98,
    e.precio_gnc,
    e.precio_gnl,
    e.precio_hidrogeno,
    e.precio_diesel_renovable,
    strptime(e.fecha_precios, '%d/%m/%Y %H:%M:%S') as fecha_precios
from estaciones e
left join grupo g on g.ideess = e.ideess
left join municipios m on m.cod_mun = e.cod_mun
left join {{ ref('territorios_provincias') }} p on p.cod_prov = e.cod_prov
