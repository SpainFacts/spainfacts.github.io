-- Viviendas principales con calefacción según el combustible, por provincia
-- (INE, Encuesta de Características Esenciales de la Población y las
-- Viviendas 2021; muestral). "Electricidad" incluye radiadores, bombas de
-- calor y aire acondicionado; la encuesta no las distingue.
with base as (
    select cod_prov, combustible, viviendas
    from {{ source('raw', 'ine_ecepov_calefaccion') }}
    where tipo_edificio = 'Total' and anio_construccion = 'Total' and tamano_municipio = 'Total'
)
select
    case when b.cod_prov = '00' then 'pais' else 'provincia' end as nivel,
    b.cod_prov as cod,
    coalesce(p.nombre, 'España') as nombre,
    p.cod_ccaa,
    c.nombre as ccaa,
    2021 as anio,
    max(viviendas) filter (where combustible = 'Total') as viviendas,
    max(viviendas) filter (where combustible = 'Electricidad') as electricidad,
    max(viviendas) filter (where combustible = 'Gas natural') as gas_natural,
    max(viviendas) filter (where combustible like 'Petróleo%') as petroleo,
    max(viviendas) filter (where combustible = 'Otros') as otros,
    100.0 * max(viviendas) filter (where combustible = 'Electricidad') / nullif(max(viviendas) filter (where combustible = 'Total'), 0) as cuota_electricidad_pct,
    100.0 * max(viviendas) filter (where combustible = 'Gas natural') / nullif(max(viviendas) filter (where combustible = 'Total'), 0) as cuota_gas_pct,
    100.0 * max(viviendas) filter (where combustible like 'Petróleo%') / nullif(max(viviendas) filter (where combustible = 'Total'), 0) as cuota_petroleo_pct
from base b
left join {{ ref('territorios_provincias') }} p on p.cod_prov = b.cod_prov
left join {{ ref('territorios_ccaa') }} c on c.cod_ccaa = p.cod_ccaa
group by all
