-- Renta de los hogares de España (cod '00'), comunidades y provincias por año
-- según el Atlas de Distribución de Renta de los Hogares del INE (ADRH, tabla
-- 53689; 2015-2023, renta del propio año, datos tributarios). Complementa a la
-- ECV (renta_ecv_ccaa) porque llega a provincia. Los nombres del INE ("Palmas,
-- Las") se pasan al formato de las semillas ("Palmas (Las)") para obtener el
-- código INE. Importes reales deflactados con el IPC medio del año (euros de
-- anio_base). Las islas no se incluyen. OJO: el INE solo publica País Vasco
-- desde 2020 y Navarra desde 2021 (haciendas forales), por eso el total de
-- España empieza en 2021.
with base as (
    select
        nivel,
        case when nivel = 'provincia'
            then regexp_replace(nombre, '^(.*), (.*)$', '\1 (\2)')
            else nombre end as nombre_semilla,
        nombre,
        cast(anio as integer) as anio,
        max(valor) filter (where indicador = 'Renta neta media por persona') as renta_persona,
        max(valor) filter (where indicador = 'Renta neta media por hogar') as renta_hogar,
        max(valor) filter (where indicador = 'Media de la renta por unidad de consumo') as renta_uc,
        max(valor) filter (where indicador = 'Mediana de la renta por unidad de consumo') as renta_uc_mediana
    from {{ source('raw_renta', 'ine_adrh_territorios') }}
    where nivel in ('pais', 'ccaa', 'provincia')
    group by all
)

select
    b.nivel,
    cast(case b.nivel
        when 'pais' then '00'
        when 'ccaa' then c.cod_ccaa
        else coalesce(p.cod_prov, p2.cod_prov, case b.nombre
            when 'Araba/Álava' then '01' when 'Bizkaia' then '48' when 'Gipuzkoa' then '20' end) end as varchar) as cod,
    b.nombre,
    b.anio,
    b.renta_persona,
    b.renta_hogar,
    b.renta_persona * d.factor as renta_persona_real,
    b.renta_hogar * d.factor as renta_hogar_real,
    b.renta_uc * d.factor as renta_uc_real,
    b.renta_uc_mediana * d.factor as renta_uc_mediana_real,
    d.anio_base
from base b
left join {{ ref('ine_ccaa_nombres') }} c on b.nivel = 'ccaa' and c.nombre_ine = b.nombre
left join {{ ref('ine_provincias_nombres') }} p on b.nivel = 'provincia' and p.nombre_ine = b.nombre_semilla
left join {{ ref('ine_provincias_nombres') }} p2 on b.nivel = 'provincia' and p2.nombre_ine = b.nombre
left join {{ ref('deflactor') }} d on d.anio = b.anio
where b.renta_persona is not null
qualify row_number() over (partition by b.nivel, b.nombre, b.anio order by 1) = 1
