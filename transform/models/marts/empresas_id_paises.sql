-- Gasto en I+D e investigadores por país, año y sector que ejecuta el gasto
-- (Eurostat rd_e_gerdtot y rd_p_perslf; el INE, Estadística sobre Actividades de
-- I+D, es la fuente de las cifras de España).
-- sector: Total, Empresas (BES), Administraciones públicas (GOV), Universidades
-- (HES, enseñanza superior) e IPSFL (instituciones privadas sin fines de lucro).
-- pct_pib = gasto en I+D / PIB x 100.
-- eur_hab = euros por habitante de cada año; eur_hab_real = en euros constantes
-- con el IPC español (main.deflactor), solo para España y la UE-27 (para el resto
-- de países la comparación se hace en % del PIB).
-- investigadores_1000ocup = investigadores en equivalencia a jornada completa por
-- cada 1.000 ocupados (Eurostat publica el % del empleo).
with gerd as (
    select
        geo,
        cast(periodo as integer) as anio,
        sectperf,
        max(valor) filter (where unit = 'PC_GDP') as pct_pib,
        max(valor) filter (where unit = 'EUR_HAB') as eur_hab,
        max(valor) filter (where unit = 'MIO_EUR') as millones_eur
    from {{ source('raw_empresas', 'eurostat_empresas_gerd') }}
    group by all
),

inv as (
    select
        geo,
        cast(periodo as integer) as anio,
        sectperf,
        max(valor) filter (where unit = 'PC_EMP_FTE') * 10 as investigadores_1000ocup
    from {{ source('raw_empresas', 'eurostat_empresas_investigadores') }}
    where dataset = 'rd_p_perslf'
    group by all
),

ue27 as (
    select unnest(['BE', 'BG', 'CZ', 'DK', 'DE', 'EE', 'IE', 'EL', 'ES', 'FR', 'HR', 'IT', 'CY', 'LV',
                   'LT', 'LU', 'HU', 'MT', 'NL', 'AT', 'PL', 'PT', 'RO', 'SI', 'SK', 'FI', 'SE']) as geo
),

todo as (
    select
        coalesce(g.geo, i.geo) as geo,
        coalesce(g.anio, i.anio) as anio,
        coalesce(g.sectperf, i.sectperf) as sectperf,
        g.pct_pib, g.eur_hab, g.millones_eur, i.investigadores_1000ocup
    from gerd g
    full join inv i on i.geo = g.geo and i.anio = g.anio and i.sectperf = g.sectperf
)

select
    cast(t.geo as varchar) as geo,
    case t.geo
        when 'EU27_2020' then 'UE-27' when 'EA20' then 'Zona euro'
        when 'ES' then 'España' when 'DE' then 'Alemania' when 'FR' then 'Francia' when 'IT' then 'Italia'
        when 'PT' then 'Portugal' when 'BE' then 'Bélgica' when 'BG' then 'Bulgaria' when 'CZ' then 'Chequia'
        when 'DK' then 'Dinamarca' when 'EE' then 'Estonia' when 'IE' then 'Irlanda' when 'EL' then 'Grecia'
        when 'HR' then 'Croacia' when 'CY' then 'Chipre' when 'LV' then 'Letonia' when 'LT' then 'Lituania'
        when 'LU' then 'Luxemburgo' when 'HU' then 'Hungría' when 'MT' then 'Malta' when 'NL' then 'Países Bajos'
        when 'AT' then 'Austria' when 'PL' then 'Polonia' when 'RO' then 'Rumanía' when 'SI' then 'Eslovenia'
        when 'SK' then 'Eslovaquia' when 'FI' then 'Finlandia' when 'SE' then 'Suecia'
        when 'NO' then 'Noruega' when 'CH' then 'Suiza' when 'UK' then 'Reino Unido' when 'US' then 'Estados Unidos'
        when 'JP' then 'Japón' when 'KR' then 'Corea del Sur' when 'CN_X_HK' then 'China' when 'TR' then 'Turquía'
        when 'IS' then 'Islandia'
    end as pais,
    u.geo is not null as es_ue,
    t.anio,
    case t.sectperf
        when 'TOTAL' then 'Total' when 'BES' then 'Empresas' when 'GOV' then 'Administraciones públicas'
        when 'HES' then 'Universidades' when 'PNP' then 'IPSFL'
    end as sector,
    t.pct_pib,
    t.eur_hab,
    case when t.geo in ('ES', 'EU27_2020') then t.eur_hab * d.factor end as eur_hab_real,
    t.millones_eur,
    t.investigadores_1000ocup,
    cast(d.anio_base as integer) as anio_euros
from todo t
left join ue27 u on u.geo = t.geo
left join {{ ref('deflactor') }} d on d.anio = t.anio
where t.geo in ('EU27_2020', 'EA20', 'ES', 'DE', 'FR', 'IT', 'PT', 'BE', 'BG', 'CZ', 'DK', 'EE', 'IE', 'EL',
                'HR', 'CY', 'LV', 'LT', 'LU', 'HU', 'MT', 'NL', 'AT', 'PL', 'RO', 'SI', 'SK', 'FI', 'SE',
                'NO', 'CH', 'UK', 'US', 'JP', 'KR', 'CN_X_HK', 'TR', 'IS')
  and t.sectperf in ('TOTAL', 'BES', 'GOV', 'HES', 'PNP')
order by t.geo, t.anio, t.sectperf
