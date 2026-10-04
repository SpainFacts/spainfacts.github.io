-- Gasto en I+D e investigadores por comunidad autónoma, año y sector ejecutor
-- (Eurostat rd_e_gerdreg y rd_p_persreg, regiones NUTS 2, a partir de la
-- Estadística sobre Actividades de I+D del INE). cod: '00' España o código INE de la
-- comunidad (traducido del código NUTS 2).
-- pct_pib = gasto en I+D / PIB regional x 100; eur_hab = euros por habitante de cada
-- año; eur_hab_real y gasto_real_meur en euros constantes (main.deflactor).
-- investigadores_1000ocup = investigadores en equivalencia a jornada completa por
-- 1.000 ocupados; investigadores_ejc = número en jornada completa.
-- sector: Total, Empresas, Administraciones públicas, Universidades, IPSFL.
with nuts as (
    select * from (values
        ('ES', '00'),
        ('ES11', '12'), ('ES12', '03'), ('ES13', '06'), ('ES21', '16'), ('ES22', '15'),
        ('ES23', '17'), ('ES24', '02'), ('ES30', '13'), ('ES41', '07'), ('ES42', '08'),
        ('ES43', '11'), ('ES51', '09'), ('ES52', '10'), ('ES53', '04'), ('ES61', '01'),
        ('ES62', '14'), ('ES63', '18'), ('ES64', '19'), ('ES70', '05')
    ) as t(nuts2, cod)
),

gerd as (
    select
        geo,
        cast(periodo as integer) as anio,
        sectperf,
        max(valor) filter (where unit = 'PC_GDP') as pct_pib,
        max(valor) filter (where unit = 'EUR_HAB') as eur_hab,
        max(valor) filter (where unit = 'MIO_EUR') as millones_eur
    from {{ source('raw_empresas', 'eurostat_empresas_gerd_regiones') }}
    group by all
),

inv as (
    select
        geo,
        cast(periodo as integer) as anio,
        sectperf,
        max(valor) filter (where unit = 'PC_EMP_FTE') * 10 as investigadores_1000ocup,
        max(valor) filter (where unit = 'FTE') as investigadores_ejc
    from {{ source('raw_empresas', 'eurostat_empresas_investigadores') }}
    where dataset = 'rd_p_persreg'
    group by all
),

todo as (
    select
        coalesce(g.geo, i.geo) as geo,
        coalesce(g.anio, i.anio) as anio,
        coalesce(g.sectperf, i.sectperf) as sectperf,
        g.pct_pib, g.eur_hab, g.millones_eur, i.investigadores_1000ocup, i.investigadores_ejc
    from gerd g
    full join inv i on i.geo = g.geo and i.anio = g.anio and i.sectperf = g.sectperf
)

select
    case when n.cod = '00' then 'pais' else 'ccaa' end as nivel,
    n.cod,
    tt.nombre,
    t.anio,
    case t.sectperf
        when 'TOTAL' then 'Total' when 'BES' then 'Empresas' when 'GOV' then 'Administraciones públicas'
        when 'HES' then 'Universidades' when 'PNP' then 'IPSFL'
    end as sector,
    t.pct_pib,
    t.eur_hab,
    t.eur_hab * d.factor as eur_hab_real,
    t.millones_eur,
    t.millones_eur * d.factor as gasto_real_meur,
    t.investigadores_1000ocup,
    t.investigadores_ejc,
    cast(d.anio_base as integer) as anio_euros
from todo t
join nuts n on n.nuts2 = t.geo
left join {{ ref('territorios') }} tt on tt.nivel = case when n.cod = '00' then 'pais' else 'ccaa' end and tt.cod = n.cod
left join {{ ref('deflactor') }} d on d.anio = t.anio
where t.sectperf in ('TOTAL', 'BES', 'GOV', 'HES', 'PNP')
order by n.cod, t.anio, t.sectperf
