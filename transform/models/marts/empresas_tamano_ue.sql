-- Peso de cada tamaño de empresa en España, la UE-27 y otros países europeos
-- (Eurostat sbs_sc_ovw, estadística estructural de empresas, desde 2021; economía
-- de mercado sin actividades financieras: NACE B a S sin O ni S94).
-- A diferencia del DIRCE, el tamaño se mide por personas ocupadas (incluidos los
-- propietarios), no por asalariados: Micro 0-9, Pequeñas 10-49, Medianas 50-249,
-- Grandes 250 o más.
-- pct_empresas, pct_empleo y pct_vab = % del total de empresas, de personas
-- ocupadas y del valor añadido que corresponde a cada tamaño.
with base as (
    select
        geo,
        cast(periodo as integer) as anio,
        case size_emp
            when '0-9' then 'Micro (0-9)'
            when '10-19' then 'Pequeñas (10-49)' when '20-49' then 'Pequeñas (10-49)'
            when '50-249' then 'Medianas (50-249)'
            when 'GE250' then 'Grandes (250 o más)'
            when 'TOTAL' then 'Total'
        end as tamano,
        indic_sbs,
        valor
    from {{ source('raw_empresas', 'eurostat_empresas_tamano') }}
),

agregado as (
    select
        geo, anio, tamano,
        sum(valor) filter (where indic_sbs = 'ENT_NR') as empresas,
        sum(valor) filter (where indic_sbs = 'EMP_NR') as ocupados,
        sum(valor) filter (where indic_sbs = 'AV_MEUR') as vab_meur
    from base
    where tamano is not null
    group by all
)

select
    cast(a.geo as varchar) as geo,
    case a.geo
        when 'EU27_2020' then 'UE-27' when 'ES' then 'España' when 'DE' then 'Alemania'
        when 'FR' then 'Francia' when 'IT' then 'Italia' when 'PT' then 'Portugal'
        when 'NL' then 'Países Bajos' when 'PL' then 'Polonia' when 'SE' then 'Suecia'
        when 'AT' then 'Austria' when 'BE' then 'Bélgica'
    end as pais,
    a.anio,
    a.tamano,
    case a.tamano when 'Micro (0-9)' then 1 when 'Pequeñas (10-49)' then 2
        when 'Medianas (50-249)' then 3 else 4 end as orden,
    a.empresas,
    a.ocupados,
    a.vab_meur,
    100.0 * a.empresas / t.empresas as pct_empresas,
    100.0 * a.ocupados / t.ocupados as pct_empleo,
    100.0 * a.vab_meur / t.vab_meur as pct_vab
from agregado a
join agregado t on t.geo = a.geo and t.anio = a.anio and t.tamano = 'Total'
where a.tamano <> 'Total'
order by a.geo, a.anio, orden
