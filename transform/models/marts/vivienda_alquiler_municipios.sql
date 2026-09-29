-- Alquiler mediano de pisos (vivienda colectiva) por municipio y año
-- (2011-2024), SERPAVI del Ministerio de Vivienda y Agenda Urbana (datos del
-- IRPF). Solo municipios de 20.000 habitantes o más (población del último
-- año disponible) y con al menos 100 viviendas alquiladas declaradas, para que
-- la mediana sea representativa. *_real: euros del año base de main.deflactor.
-- variacion_real_5a: cambio real frente a cinco años antes.
with base as (
    select
        cod as cod_mun,
        cast(anio as integer) as anio,
        viviendas_alquiladas,
        alquiler_m2_mediana,
        alquiler_mes_mediana,
        superficie_mediana
    from {{ source('raw_vivienda', 'vivienda_serpavi') }}
    where nivel = 'municipio' and tipologia = 'Colectiva'
      and viviendas_alquiladas >= 100 and alquiler_mes_mediana is not null
),

mun as (
    select cod_mun, municipio, cod_prov, cod_ccaa, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total' and anio = (select max(anio) from {{ ref('poblacion_municipios') }})
      and poblacion >= 20000
),

real as (
    select
        b.*,
        b.alquiler_m2_mediana * d.factor as alquiler_m2_mediana_real,
        b.alquiler_mes_mediana * d.factor as alquiler_mes_mediana_real,
        d.anio_base
    from base b
    join {{ ref('deflactor') }} d on d.anio = b.anio
)

select
    r.cod_mun,
    m.municipio,
    m.cod_prov,
    m.cod_ccaa,
    m.poblacion,
    r.anio,
    r.viviendas_alquiladas,
    1000.0 * r.viviendas_alquiladas / m.poblacion as alquiladas_1000,
    r.alquiler_m2_mediana,
    r.alquiler_mes_mediana,
    r.superficie_mediana,
    r.alquiler_m2_mediana_real,
    r.alquiler_mes_mediana_real,
    r.anio_base,
    100 * (r.alquiler_mes_mediana_real / c.alquiler_mes_mediana_real - 1) as variacion_real_5a
from real r
join mun m on m.cod_mun = r.cod_mun
left join real c on c.cod_mun = r.cod_mun and c.anio = r.anio - 5
