-- Calificaciones provisionales de vivienda protegida en alquiler (MIVAU,
-- 2005-2023) según el partido que gobernaba cada comunidad (a 1 de julio de
-- cada año), sumando comunidades y años. Observado frente a esperado: la cuota
-- de las calificaciones de alquiler que se dieron con cada partido frente a la
-- cuota de población-año que gobernó (si todos promovieran igual por
-- habitante, las dos cuotas coincidirían; ratio = 1). Solo años con dato.
-- Las viviendas calificadas no son independientes entre sí (llegan en
-- promociones), así que no se calcula una prueba de significación.
with base as (
    select familia, cod_ccaa, anio, calif_alquiler, poblacion
    from {{ ref('vivienda_publica_ccaa_anual') }}
    where calif_alquiler is not null and poblacion is not null and familia is not null
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
        sum(calif_alquiler) as calif_alquiler,
        sum(poblacion) as poblacion_anios
    from base
    group by 1
)

select
    a.familia,
    coalesce(c.color, '#94a3b8') as color,
    cast(anios_comunidad as integer) as anios_comunidad,
    cast(comunidades as integer) as comunidades,
    cast(calif_alquiler as integer) as calif_alquiler,
    cast(poblacion_anios as bigint) as poblacion_anios,
    100000.0 * calif_alquiler / poblacion_anios as calif_alquiler_100k_anio,
    100.0 * calif_alquiler / sum(calif_alquiler) over () as cuota_calif,
    100.0 * poblacion_anios / sum(poblacion_anios) over () as cuota_poblacion,
    (calif_alquiler / sum(calif_alquiler) over ()) / (poblacion_anios / sum(poblacion_anios) over ()) as ratio_observado_esperado,
    (select min(anio) from base) as anio_desde,
    (select max(anio) from base) as anio_hasta
from agregado a
left join colores c using (familia)
order by poblacion_anios desc
