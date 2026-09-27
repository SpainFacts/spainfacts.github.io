-- Dimensión territorial: España, 19 comunidades y 52 provincias, con la ruta de
-- su página y la última población oficial (padrón). Las comunidades
-- uniprovinciales también tienen fila de provincia.
with ccaa as (
    select * from {{ ref('territorios_ccaa') }}
),

prov as (
    select * from {{ ref('territorios_provincias') }}
),

pob as (
    select nivel, cod, anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total'
    qualify anio = max(anio) over ()
),

base as (
    select 'pais' as nivel, '00' as cod, null as cod_ccaa, null as cod_ccaa_hacienda,
        'España' as nombre, 'espana' as slug, '/territorios' as ruta, 0 as orden
    union all
    select 'ccaa', cod_ccaa, cod_ccaa, cod_ccaa_hacienda, nombre, slug,
        '/territorios/' || slug, 1
    from ccaa
    union all
    select 'provincia', p.cod_prov, p.cod_ccaa, c.cod_ccaa_hacienda, p.nombre, p.slug,
        '/territorios/' || c.slug || '/' || p.slug, 2
    from prov p
    join ccaa c using (cod_ccaa)
)

select
    b.nivel,
    b.cod,
    cast(b.cod_ccaa as varchar) as cod_ccaa,
    cast(b.cod_ccaa_hacienda as varchar) as cod_ccaa_hacienda,
    b.nombre,
    b.slug,
    b.ruta,
    pob.poblacion as poblacion_ultima,
    pob.anio as anio_poblacion,
    b.nivel || '-' || b.cod as clave
from base b
left join pob on pob.nivel = b.nivel and pob.cod = b.cod
order by b.orden, b.cod
