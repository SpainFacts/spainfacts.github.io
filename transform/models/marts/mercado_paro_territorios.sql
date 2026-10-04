-- Mercado laboral por España, comunidad y provincia, trimestral desde 2002 (INE, EPA).
--   nivel 'pais' (cod = '00', una sola fila por trimestre): las mismas tasas que
--     las comunidades más la de empleo y actividad (65349) del total nacional;
--   nivel 'ccaa' (cod = código INE de comunidad): tasa de paro total, de
--     menores de 25 años (tabla 65334), de extranjeros (65336) y % de hogares
--     con todos sus activos en paro (65276);
--   nivel 'provincia' (cod = código INE de provincia): tasas de paro, empleo y
--     actividad (65349), total y de mujeres.
-- Las columnas que una fuente no da a un nivel quedan vacías (provincia: sin menores
-- de 25, extranjeros ni hogares; comunidad: sin empleo ni actividad).
-- La fila de España sale de las mismas tablas EPA que mercado_paro_trimestral.
-- La muestra de la EPA es pequeña en las provincias y comunidades menos
-- pobladas (Ceuta, Melilla, Soria, Teruel...): el dato trimestral oscila
-- mucho; para comparar territorios conviene la media de los cuatro últimos
-- trimestres (media_4t_*).
with ccaa_raw as (
    select 'edad' as t, fecha, string_split(rtrim(serie, '. '), '. ') as partes, valor
    from {{ source('raw_mercado', 'ine_epa_paro_edad_ccaa') }}
    union all
    select 'nacionalidad', fecha, string_split(rtrim(serie, '. '), '. '), valor
    from {{ source('raw_mercado', 'ine_epa_paro_nacionalidad') }}
    union all
    select 'hogares', fecha, string_split(rtrim(serie, '. '), '. '), valor
    from {{ source('raw_mercado', 'ine_epa_hogares_paro') }}
),

ccaa as (
    select
        case when n.cod_ccaa = '00' then 'pais' else 'ccaa' end as nivel,
        n.cod_ccaa as cod,
        date_trunc('quarter', cast(epoch_ms(r.fecha) + interval 12 hour as date)) as trimestre,
        max(r.valor) filter (where t = 'edad' and list_contains(partes, 'Ambos sexos') and list_contains(partes, 'Total')) as tasa_paro,
        max(r.valor) filter (where t = 'edad' and list_contains(partes, 'Ambos sexos') and list_contains(partes, 'Menores de 25 años')) as tasa_paro_menor25,
        max(r.valor) filter (where t = 'nacionalidad' and list_contains(partes, 'Ambos sexos') and list_contains(partes, 'Extranjera: Total')) as tasa_paro_extranjeros,
        max(r.valor) filter (where t = 'hogares' and partes[4] like 'Todos los activos son parados%') as pct_hogares_todos_parados,
        cast(null as double) as tasa_empleo,
        cast(null as double) as tasa_actividad,
        max(r.valor) filter (where t = 'edad' and list_contains(partes, 'Mujeres') and list_contains(partes, 'Total')) as tasa_paro_mujeres
    from ccaa_raw r
    join {{ ref('ine_ccaa_nombres') }} n on list_contains(r.partes, n.nombre_ine)
    where r.valor is not null
    group by all
),

-- Empleo y actividad del total nacional (las comunidades no los tienen)
nacional_tasas as (
    select
        date_trunc('quarter', cast(epoch_ms(fecha) + interval 12 hour as date)) as trimestre,
        max(valor) filter (where partes[1] = 'Tasa de empleo de la población' and list_contains(partes, 'Ambos sexos')) as tasa_empleo,
        max(valor) filter (where partes[1] = 'Tasa de actividad' and list_contains(partes, 'Ambos sexos')) as tasa_actividad
    from (
        select fecha, string_split(rtrim(serie, '. '), '. ') as partes, valor
        from {{ source('raw_mercado', 'ine_epa_tasas_provincia') }}
        where valor is not null
    )
    where list_contains(partes, 'Total Nacional')
    group by all
),

prov_nombres as (
    select nombre_ine, cod_prov from {{ ref('ine_provincias_nombres') }}
    union all
    select * from (values
        ('Araba/Álava', '01'), ('Balears, Illes', '07'), ('Coruña, A', '15'), ('Palmas, Las', '35'),
        ('Rioja, La', '26'), ('Gipuzkoa', '20'), ('Bizkaia', '48')
    ) v(nombre_ine, cod_prov)
),

provincia as (
    select
        'provincia' as nivel,
        n.cod_prov as cod,
        date_trunc('quarter', cast(epoch_ms(r.fecha) + interval 12 hour as date)) as trimestre,
        max(r.valor) filter (where partes[1] = 'Tasa de paro de la población' and list_contains(partes, 'Ambos sexos')) as tasa_paro,
        cast(null as double) as tasa_paro_menor25,
        cast(null as double) as tasa_paro_extranjeros,
        cast(null as double) as pct_hogares_todos_parados,
        max(r.valor) filter (where partes[1] = 'Tasa de empleo de la población' and list_contains(partes, 'Ambos sexos')) as tasa_empleo,
        max(r.valor) filter (where partes[1] = 'Tasa de actividad' and list_contains(partes, 'Ambos sexos')) as tasa_actividad,
        max(r.valor) filter (where partes[1] = 'Tasa de paro de la población' and list_contains(partes, 'Mujeres')) as tasa_paro_mujeres
    from (
        select fecha, string_split(rtrim(serie, '. '), '. ') as partes, valor
        from {{ source('raw_mercado', 'ine_epa_tasas_provincia') }}
        where valor is not null
    ) r
    join prov_nombres n on list_contains(r.partes, n.nombre_ine)
    group by all
),

todo as (
    select
        c.nivel, c.cod, c.trimestre, c.tasa_paro, c.tasa_paro_menor25, c.tasa_paro_extranjeros,
        c.pct_hogares_todos_parados,
        case when c.nivel = 'pais' then nt.tasa_empleo else c.tasa_empleo end as tasa_empleo,
        case when c.nivel = 'pais' then nt.tasa_actividad else c.tasa_actividad end as tasa_actividad,
        c.tasa_paro_mujeres
    from ccaa c
    left join nacional_tasas nt on c.nivel = 'pais' and nt.trimestre = c.trimestre
    union all
    select * from provincia
)

select
    t.nivel,
    t.cod,
    n.nombre as territorio,
    t.trimestre,
    t.tasa_paro,
    t.tasa_paro_menor25,
    t.tasa_paro_extranjeros,
    t.pct_hogares_todos_parados,
    t.tasa_empleo,
    t.tasa_actividad,
    t.tasa_paro_mujeres,
    avg(t.tasa_paro) over w as media_4t_tasa_paro,
    avg(t.tasa_paro_menor25) over w as media_4t_tasa_paro_menor25,
    avg(t.tasa_empleo) over w as media_4t_tasa_empleo,
    avg(t.pct_hogares_todos_parados) over w as media_4t_hogares_todos_parados,
    t.tasa_paro - lag(t.tasa_paro, 4) over (partition by t.nivel, t.cod order by t.trimestre) as tasa_paro_dif_anual
from todo t
left join {{ ref('territorios') }} n on n.nivel = t.nivel and n.cod = t.cod
window w as (partition by t.nivel, t.cod order by t.trimestre rows between 3 preceding and current row)
