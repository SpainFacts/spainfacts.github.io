-- Alquiler de vivienda habitual por año (2011-2024), España, comunidades y
-- provincias: Sistema Estatal de Referencia del Precio del Alquiler de Vivienda
-- (SERPAVI, Ministerio de Vivienda y Agenda Urbana), elaborado con las
-- declaraciones del IRPF de los caseros (AEAT) y el Catastro. No incluye País
-- Vasco ni Navarra por provincia/municipio (régimen foral) salvo lo que el
-- Ministerio publica por comunidad.
-- tipologia: 'Colectiva' (pisos) o 'Unifamiliar'. Las medianas son del
-- alquiler en €/m² al mes y del alquiler mensual de toda la vivienda.
-- *_real: en euros del año base de main.deflactor.
-- España no viene en el fichero: se calcula como media de las medianas
-- autonómicas ponderada por el número de viviendas alquiladas (aproximación;
-- la mediana nacional real no se publica).
-- alquiladas_1000: viviendas declaradas en alquiler por 1.000 habitantes.
with base as (
    select
        nivel,
        cod,
        nombre,
        cast(anio as integer) as anio,
        tipologia,
        viviendas_alquiladas,
        alquiler_m2_mediana,
        alquiler_m2_p25,
        alquiler_m2_p75,
        alquiler_mes_mediana,
        alquiler_mes_p25,
        alquiler_mes_p75,
        superficie_mediana
    from {{ source('raw_vivienda', 'vivienda_serpavi') }}
    where nivel in ('ccaa', 'provincia')
),

espana as (
    select
        'pais' as nivel,
        '00' as cod,
        'España' as nombre,
        anio,
        tipologia,
        sum(viviendas_alquiladas) as viviendas_alquiladas,
        sum(alquiler_m2_mediana * viviendas_alquiladas) / sum(viviendas_alquiladas) as alquiler_m2_mediana,
        sum(alquiler_m2_p25 * viviendas_alquiladas) / sum(viviendas_alquiladas) as alquiler_m2_p25,
        sum(alquiler_m2_p75 * viviendas_alquiladas) / sum(viviendas_alquiladas) as alquiler_m2_p75,
        sum(alquiler_mes_mediana * viviendas_alquiladas) / sum(viviendas_alquiladas) as alquiler_mes_mediana,
        sum(alquiler_mes_p25 * viviendas_alquiladas) / sum(viviendas_alquiladas) as alquiler_mes_p25,
        sum(alquiler_mes_p75 * viviendas_alquiladas) / sum(viviendas_alquiladas) as alquiler_mes_p75,
        sum(superficie_mediana * viviendas_alquiladas) / sum(viviendas_alquiladas) as superficie_mediana
    from base
    where nivel = 'ccaa' and viviendas_alquiladas > 0 and alquiler_mes_mediana is not null
    group by all
),

todo as (
    select * from base
    union all by name
    select * from espana
),

pob as (
    select nivel, cod, anio, poblacion from {{ ref('poblacion_territorios') }} where sexo = 'Total'
)

select
    a.nivel,
    a.cod,
    coalesce(t.nombre, a.nombre) as nombre,
    a.anio,
    a.tipologia,
    a.viviendas_alquiladas,
    a.alquiler_m2_mediana,
    a.alquiler_m2_p25,
    a.alquiler_m2_p75,
    a.alquiler_mes_mediana,
    a.alquiler_mes_p25,
    a.alquiler_mes_p75,
    a.superficie_mediana,
    a.alquiler_m2_mediana * d.factor as alquiler_m2_mediana_real,
    a.alquiler_mes_mediana * d.factor as alquiler_mes_mediana_real,
    a.alquiler_mes_p25 * d.factor as alquiler_mes_p25_real,
    a.alquiler_mes_p75 * d.factor as alquiler_mes_p75_real,
    d.anio_base,
    p.poblacion,
    1000.0 * a.viviendas_alquiladas / p.poblacion as alquiladas_1000,
    100 * (a.alquiler_mes_mediana * d.factor / (l.alquiler_mes_mediana * dl.factor) - 1) as variacion_real
from todo a
left join {{ ref('deflactor') }} d on d.anio = a.anio
left join todo l on l.nivel = a.nivel and l.cod = a.cod and l.tipologia = a.tipologia and l.anio = a.anio - 1
left join {{ ref('deflactor') }} dl on dl.anio = a.anio - 1
left join pob p on p.nivel = a.nivel and p.cod = a.cod and p.anio = a.anio
left join {{ ref('territorios') }} t on t.nivel = a.nivel and t.cod = a.cod
