-- Renta, pobreza y desigualdad por comunidad autónoma y para España (cod '00')
-- según la Encuesta de Condiciones de Vida del INE (ECV, base 2013), tablas
-- 9947 (renta por persona y por unidad de consumo), 9949 (renta por hogar),
-- 9963 (tasa de riesgo de pobreza), 76847 (AROPE y componentes, desde 2014),
-- 9990 (dificultad para llegar a fin de mes) y 76846 (Gini y S80/S20).
-- anio = año de la encuesta. La renta (y por tanto la pobreza, el Gini y el
-- S80/S20) es la del año anterior: anio_renta = anio - 1. Los importes reales
-- se deflactan con el IPC medio de anio_renta (mart deflactor) y quedan en
-- euros de anio_base. fin_mes_dificultad = % de personas que llegan a fin de
-- mes "con dificultad" o "con mucha dificultad" (definición de Eurostat).
-- Se usan las series sin alquiler imputado (las de referencia de Eurostat).
with renta as (
    select anyo as anio, split_part(serie, '. ', 1) as territorio,
        max(valor) filter (where split_part(serie, '. ', 2) = 'Renta neta media por persona') as renta_persona,
        max(valor) filter (where split_part(serie, '. ', 2) = 'Renta media por unidad de consumo') as renta_uc
    from {{ source('raw_renta', 'ine_ecv_renta_ccaa') }}
    where valor is not null
    group by all
),

hogar as (
    select anyo as anio, split_part(serie, '. ', 1) as territorio,
        max(valor) filter (where split_part(serie, '. ', 2) = 'Renta neta media por hogar') as renta_hogar
    from {{ source('raw_renta', 'ine_ecv_renta_hogar_ccaa') }}
    where valor is not null
    group by all
),

pobreza as (
    select anyo as anio, split_part(serie, '. ', 1) as territorio,
        max(valor) as tasa_pobreza
    from {{ source('raw_renta', 'ine_ecv_pobreza_ccaa') }}
    where valor is not null and serie not like '%alquiler imputado%'
    group by all
),

arope as (
    select anyo as anio, split_part(serie, '. ', 1) as territorio,
        max(valor) filter (where serie like '%(indicador AROPE)%') as arope,
        max(valor) filter (where serie like '%carencia material y social severa%') as carencia_severa,
        max(valor) filter (where serie like '%baja intensidad en el trabajo%') as baja_intensidad
    from {{ source('raw_renta', 'ine_ecv_arope_ccaa') }}
    where valor is not null
    group by all
),

fin_mes as (
    select anyo as anio, split_part(serie, '. ', 1) as territorio,
        sum(valor) filter (where split_part(serie, '. ', 2) in ('Con mucha dificultad', 'Con dificultad')) as fin_mes_dificultad,
        sum(valor) filter (where split_part(serie, '. ', 2) = 'Con mucha dificultad') as fin_mes_mucha_dificultad
    from {{ source('raw_renta', 'ine_ecv_fin_mes_ccaa') }}
    where valor is not null
    group by all
),

gini as (
    select anyo as anio, split_part(serie, '. ', 1) as territorio,
        max(valor) filter (where serie like '%. Gini. %') as gini,
        max(valor) filter (where serie like '%Desigualdad (S80/S20)%') as s80_s20
    from {{ source('raw_renta', 'ine_ecv_gini_ccaa') }}
    where valor is not null
    group by all
),

claves as (
    select anio, territorio from renta
    union select anio, territorio from pobreza
    union select anio, territorio from arope
    union select anio, territorio from fin_mes
    union select anio, territorio from gini
)

select
    cast(k.anio as integer) as anio,
    cast(k.anio - 1 as integer) as anio_renta,
    cast(n.cod_ccaa as varchar) as cod,
    case when n.cod_ccaa = '00' then 'pais' else 'ccaa' end as nivel,
    r.renta_persona,
    r.renta_uc,
    h.renta_hogar,
    r.renta_persona * d.factor as renta_persona_real,
    r.renta_uc * d.factor as renta_uc_real,
    h.renta_hogar * d.factor as renta_hogar_real,
    d.anio_base,
    p.tasa_pobreza,
    a.arope,
    a.carencia_severa,
    a.baja_intensidad,
    f.fin_mes_dificultad,
    f.fin_mes_mucha_dificultad,
    g.gini,
    g.s80_s20
from claves k
join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = k.territorio
left join renta r on r.anio = k.anio and r.territorio = k.territorio
left join hogar h on h.anio = k.anio and h.territorio = k.territorio
left join pobreza p on p.anio = k.anio and p.territorio = k.territorio
left join arope a on a.anio = k.anio and a.territorio = k.territorio
left join fin_mes f on f.anio = k.anio and f.territorio = k.territorio
left join gini g on g.anio = k.anio and g.territorio = k.territorio
left join {{ ref('deflactor') }} d on d.anio = k.anio - 1
