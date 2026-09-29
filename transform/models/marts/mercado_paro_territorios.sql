-- Mercado laboral por comunidad y provincia, trimestral desde 2002 (INE, EPA).
--   nivel 'ccaa' (cod = código INE de comunidad): tasa de paro total, de
--     menores de 25 años (tabla 65334), de extranjeros (65336) y % de hogares
--     con todos sus activos en paro (65276);
--   nivel 'provincia' (cod = código INE de provincia): tasas de paro, empleo y
--     actividad (65349), total y de mujeres.
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
        'ccaa' as nivel,
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
    where r.valor is not null and n.cod_ccaa <> '00'
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
    select * from ccaa
    union all
    select * from provincia
)

select
    t.*,
    avg(t.tasa_paro) over w as media_4t_tasa_paro,
    avg(t.tasa_paro_menor25) over w as media_4t_tasa_paro_menor25,
    avg(t.tasa_empleo) over w as media_4t_tasa_empleo,
    avg(t.pct_hogares_todos_parados) over w as media_4t_hogares_todos_parados,
    t.tasa_paro - lag(t.tasa_paro, 4) over (partition by t.nivel, t.cod order by t.trimestre) as tasa_paro_dif_anual
from todo t
window w as (partition by t.nivel, t.cod order by t.trimestre rows between 3 preceding and current row)
