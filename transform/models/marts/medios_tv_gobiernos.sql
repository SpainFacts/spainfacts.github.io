-- Dinero público a las radios y televisiones autonómicas (2017-2025) según el
-- partido que gobernaba cada comunidad a 1 de julio, sumando comunidades y años
-- (medios_tv_ccaa_anual). Solo comunidades con ente (o contrato, Castilla y
-- León) y años con dato. Observado frente a esperado, como
-- vivienda_publica_gobiernos: cuota de los euros reales aportados con cada
-- partido frente a su cuota de población-año (ratio = 1 si todos aportaran lo
-- mismo por habitante). Los importes autonómicos dependen sobre todo de la
-- estructura de cada ente (lenguas cooficiales, número de canales), no solo del
-- Gobierno de turno: la comparación es descriptiva.
with base as (
    select familia, cod_ccaa, anio, meur_real, poblacion
    from {{ ref('medios_tv_ccaa_anual') }}
    where meur_real is not null and poblacion is not null and familia is not null
),

colores as (
    select familia, any_value(color) as color
    from {{ ref('alcaldes_historia') }}
    where familia is not null and color is not null
    group by familia
),

agregado as (
    select familia,
        count(*) as anios_comunidad,
        count(distinct cod_ccaa) as comunidades,
        sum(meur_real) as meur_real,
        sum(poblacion) as poblacion_anios
    from base
    group by 1
)

select
    a.familia,
    coalesce(c.color, '#94a3b8') as color,
    cast(anios_comunidad as integer) as anios_comunidad,
    cast(comunidades as integer) as comunidades,
    meur_real,
    cast(poblacion_anios as bigint) as poblacion_anios,
    1e6 * meur_real / poblacion_anios as eur_hab_real_anio,
    100.0 * meur_real / sum(meur_real) over () as cuota_dinero,
    100.0 * poblacion_anios / sum(poblacion_anios) over () as cuota_poblacion,
    (meur_real / sum(meur_real) over ()) / (poblacion_anios / sum(poblacion_anios) over ()) as ratio_observado_esperado,
    (select min(anio) from base) as anio_desde,
    (select max(anio) from base) as anio_hasta
from agregado a
left join colores c using (familia)
order by poblacion_anios desc
