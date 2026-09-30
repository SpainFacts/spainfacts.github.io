-- Vivienda pública en alquiler por provincia. No hay un recuento oficial del
-- parque autonómico por provincia: aquí se suma lo que sí se sabe por
-- provincia, el parque municipal en alquiler que declararon los ayuntamientos
-- de más de 20.000 habitantes (MIVAU, encuesta 2023 o, si no respondieron, la
-- de 2019), por 1.000 habitantes de la provincia y con la cobertura (% de la
-- población provincial que vive en municipios con dato). En las comunidades
-- uniprovinciales (y Ceuta y Melilla) se añade el parque autonómico, que ahí sí
-- es provincial: conocido_1000hab solo existe en ellas. En Ceuta y Melilla el
-- parque de la ciudad autónoma es el mismo en las dos tablas y se cuenta una vez.
with mun as (
    select cod_prov,
        -- Ceuta y Melilla: el parque de la ciudad autónoma ya va en el autonómico
        sum(case when cod_prov in ('51', '52') then 0 else arrendamiento end) as municipal_declarado,
        count(*) filter (where origen <> 'sin_respuesta') as municipios_con_dato,
        count(*) as municipios_20k,
        sum(poblacion) filter (where origen <> 'sin_respuesta') as poblacion_con_dato
    from {{ source('raw_vivienda_publica', 'vp_municipios') }}
    group by 1
),

uniprov as (
    select p.cod_prov, c.arrendamiento as autonomico_2023
    from {{ source('raw_vivienda_publica', 'vp_ccaa_parque') }} c
    join {{ ref('territorios_provincias') }} p on p.cod_ccaa = c.cod_ccaa
    where c.anio = 2023
      and (select count(*) from {{ ref('territorios_provincias') }} q where q.cod_ccaa = c.cod_ccaa) = 1
),

pob as (
    select cod, poblacion from {{ ref('poblacion_territorios') }}
    where nivel = 'provincia' and sexo = 'Total' and anio = 2023
)

select
    p.cod_prov,
    p.nombre as provincia,
    p.cod_ccaa,
    c.nombre as comunidad,
    u.cod_prov is not null as uniprovincial,
    cast(coalesce(m.municipal_declarado, 0) as integer) as municipal_declarado,
    cast(coalesce(m.municipios_con_dato, 0) as integer) as municipios_con_dato,
    cast(coalesce(m.municipios_20k, 0) as integer) as municipios_20k,
    cast(po.poblacion as bigint) as poblacion,
    100.0 * coalesce(m.poblacion_con_dato, 0) / po.poblacion as cobertura_pct,
    1000.0 * coalesce(m.municipal_declarado, 0) / po.poblacion as municipal_1000hab,
    1000.0 * coalesce(m.municipal_declarado, 0) / nullif(m.poblacion_con_dato, 0) as municipal_1000hab_con_dato,
    cast(u.autonomico_2023 as integer) as autonomico_2023,
    case when u.cod_prov is not null then
        1000.0 * (u.autonomico_2023 + coalesce(m.municipal_declarado, 0)) / po.poblacion
    end as conocido_1000hab
from {{ ref('territorios_provincias') }} p
join {{ ref('territorios_ccaa') }} c on c.cod_ccaa = p.cod_ccaa
left join mun m on m.cod_prov = p.cod_prov
left join uniprov u on u.cod_prov = p.cod_prov
left join pob po on po.cod = p.cod_prov
order by municipal_1000hab desc
