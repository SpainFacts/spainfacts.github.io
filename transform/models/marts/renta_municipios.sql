-- Renta de los hogares por municipio (código INE de 5 dígitos) y año, según
-- el Atlas de Distribución de Renta de los Hogares del INE (ADRH, tabla 30824,
-- elaborado con datos tributarios; 2015-2023, renta del propio año). Renta
-- neta = después de impuestos y cotizaciones. Los importes reales se
-- deflactan con el IPC medio del año (mart deflactor) y quedan en euros de
-- anio_base. poblacion = padrón a 1 de enero del año (o el más cercano
-- disponible); sirve para filtrar por tamaño. puesto_* = posición en España por
-- renta neta por persona ese año entre todos los municipios con dato.
with base as (
    select
        cod_mun,
        max(municipio) as municipio,
        cast(anio as integer) as anio,
        max(valor) filter (where indicador = 'Renta neta media por persona') as renta_persona,
        max(valor) filter (where indicador = 'Renta neta media por hogar') as renta_hogar,
        max(valor) filter (where indicador = 'Media de la renta por unidad de consumo') as renta_uc,
        max(valor) filter (where indicador = 'Mediana de la renta por unidad de consumo') as renta_uc_mediana,
        max(valor) filter (where indicador = 'Renta bruta media por persona') as renta_bruta_persona
    from {{ source('raw_renta', 'ine_adrh_municipios') }}
    where nivel = 'municipio'
    group by cod_mun, anio
),

pob as (
    select cod_mun, anio, poblacion, municipio, cod_prov, cod_ccaa
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
),

rango as (
    select min(anio) as minimo, max(anio) as maximo from pob
)

select
    cast(b.cod_mun as varchar) as cod_mun,
    coalesce(p.municipio, b.municipio) as municipio,
    cast(left(b.cod_mun, 2) as varchar) as cod_prov,
    cast(coalesce(p.cod_ccaa, pu.cod_ccaa) as varchar) as cod_ccaa,
    b.anio,
    p.poblacion,
    b.renta_persona,
    b.renta_hogar,
    b.renta_uc,
    b.renta_uc_mediana,
    b.renta_persona * d.factor as renta_persona_real,
    b.renta_hogar * d.factor as renta_hogar_real,
    b.renta_uc * d.factor as renta_uc_real,
    b.renta_uc_mediana * d.factor as renta_uc_mediana_real,
    b.renta_bruta_persona * d.factor as renta_bruta_persona_real,
    d.anio_base,
    case when b.renta_persona is not null then
        cast(rank() over (partition by b.anio, b.renta_persona is null order by b.renta_persona desc) as integer)
    end as puesto_espana,
    cast(count(b.renta_persona) over (partition by b.anio) as integer) as municipios_con_dato
from base b
cross join rango r
left join pob p on p.cod_mun = b.cod_mun and p.anio = greatest(least(b.anio, r.maximo), r.minimo)
left join (
    select cod_mun, any_value(cod_ccaa) as cod_ccaa from pob group by cod_mun
) pu on pu.cod_mun = b.cod_mun
left join {{ ref('deflactor') }} d on d.anio = b.anio
