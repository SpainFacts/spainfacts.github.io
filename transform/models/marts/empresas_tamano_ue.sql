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

-- vab_meur_real y vab_eur_hab_real: valor añadido en euros constantes de anio_euros (IPCA de
-- cada país, deflactor_paises) y por habitante (población media, poblacion_paises).
select
    p.cod_pais,
    p.pais,
    a.anio,
    a.tamano,
    case a.tamano when 'Micro (0-9)' then 1 when 'Pequeñas (10-49)' then 2
        when 'Medianas (50-249)' then 3 else 4 end as orden,
    a.empresas,
    a.ocupados,
    a.vab_meur * d.factor as vab_meur_real,
    a.vab_meur * d.factor * 1e6 / pb.poblacion as vab_eur_hab_real,
    d.anio_base as anio_euros,
    100.0 * a.empresas / t.empresas as pct_empresas,
    100.0 * a.ocupados / t.ocupados as pct_empleo,
    100.0 * a.vab_meur / t.vab_meur as pct_vab
from agregado a
join agregado t on t.geo = a.geo and t.anio = a.anio and t.tamano = 'Total'
join {{ ref('paises_iso') }} p on p.eurostat = a.geo
left join {{ ref('deflactor_paises') }} d on d.cod_pais = p.cod_pais and d.anio = a.anio
left join {{ ref('poblacion_paises') }} pb on pb.cod_pais = p.cod_pais and pb.anio = a.anio
where a.tamano <> 'Total'
order by a.geo, a.anio, orden
