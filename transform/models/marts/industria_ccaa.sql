-- Peso de la industria por comunidad autónoma y año.
--   VAB: Eurostat nama_10r_3gva (raw.eurostat_industria_vab_regional), NUTS 2 = comunidades,
--     precios corrientes, desde 2000. pct_vab_*: VAB de la industria (B-E) y de las manufacturas (C)
--     sobre el VAB total de la comunidad. vab_*_hab_real: euros por habitante en euros constantes
--     de anio_base (main.deflactor; población a 1 de enero de main.poblacion_territorios).
--   Cifra de negocios y empleo: INE, Estadística Estructural de Empresas del sector industrial,
--     tabla 76823 (raw.ine_industria_eee_ccaa; miles de euros, actividad por establecimiento,
--     desde 2018), rama «Industria» (B-E). cifra_negocios_hab_real: euros constantes por habitante;
--     ocupados_industria_1000_hab: personal ocupado en la industria por 1.000 habitantes.
--   cod_ccaa: código INE (País Vasco 16, Navarra 15). cod 00 = España.
--   puesto_pct_vab_industria: posición de la comunidad por peso de la industria en su VAB.
with nuts as (
    select * from (values
        ('ES', '00'), ('ES11', '12'), ('ES12', '03'), ('ES13', '06'), ('ES21', '16'), ('ES22', '15'),
        ('ES23', '17'), ('ES24', '02'), ('ES30', '13'), ('ES41', '07'), ('ES42', '08'), ('ES43', '11'),
        ('ES51', '09'), ('ES52', '10'), ('ES53', '04'), ('ES61', '01'), ('ES62', '14'), ('ES63', '18'),
        ('ES64', '19'), ('ES70', '05')
    ) as t(nuts, cod_ccaa)
),

vab as (
    select
        n.cod_ccaa,
        cast(r.anio as integer) as anio,
        max(case when r.rama = 'TOTAL' then r.mill_eur end) as vab_total_meur,
        max(case when r.rama = 'B-E' then r.mill_eur end) as vab_industria_meur,
        max(case when r.rama = 'C' then r.mill_eur end) as vab_manuf_meur
    from {{ source('raw_industria', 'eurostat_industria_vab_regional') }} r
    join nuts n using (nuts)
    group by all
),

eee as (
    select
        c.cod_ccaa,
        cast(e.anyo as integer) as anio,
        max(case when split_part(e.serie, '. ', 2) = 'Cifra de negocios' then e.valor end) as cifra_negocios_miles_eur,
        max(case when split_part(e.serie, '. ', 2) = 'Personal ocupado' then e.valor end) as ocupados_industria
    from {{ source('raw_industria', 'ine_industria_eee_ccaa') }} e
    join {{ ref('ine_ccaa_nombres') }} c on c.nombre_ine = split_part(e.serie, '. ', 1)
    where split_part(e.serie, '. ', 3) = 'Industria' and e.valor is not null
    group by all
),

eee_total as (
    -- la tabla 76823 no trae total nacional: suma de las comunidades
    select '00' as cod_ccaa, anio, sum(cifra_negocios_miles_eur) as cifra_negocios_miles_eur,
           sum(ocupados_industria) as ocupados_industria
    from eee group by all
),

pob as (
    select cod as cod_ccaa, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel in ('ccaa', 'pais') and sexo = 'Total'
),

pob_rango as (
    select min(anio) as amin, max(anio) as amax from pob
),

base as (
    select
        coalesce(v.cod_ccaa, e.cod_ccaa) as cod_ccaa,
        coalesce(v.anio, e.anio) as anio,
        v.vab_total_meur,
        v.vab_industria_meur,
        v.vab_manuf_meur,
        e.cifra_negocios_miles_eur,
        e.ocupados_industria
    from vab v
    full join (select * from eee union all select * from eee_total) e using (cod_ccaa, anio)
)

select
    b.cod_ccaa,
    case when b.cod_ccaa = '00' then 'España' else t.nombre end as ccaa,
    b.anio,
    100.0 * b.vab_industria_meur / nullif(b.vab_total_meur, 0) as pct_vab_industria,
    100.0 * b.vab_manuf_meur / nullif(b.vab_total_meur, 0) as pct_vab_manufacturas,
    case when b.cod_ccaa <> '00' and b.vab_industria_meur is not null then
        rank() over (partition by b.anio, (b.cod_ccaa <> '00' and b.vab_industria_meur is not null)
                     order by b.vab_industria_meur / nullif(b.vab_total_meur, 0) desc) end as puesto_pct_vab_industria,
    b.vab_industria_meur,
    b.vab_manuf_meur,
    b.vab_industria_meur * 1e6 / nullif(p.poblacion, 0) * d.factor as vab_industria_hab_real,
    b.vab_manuf_meur * 1e6 / nullif(p.poblacion, 0) * d.factor as vab_manuf_hab_real,
    100.0 * b.vab_industria_meur / nullif(es.vab_industria_meur, 0) as cuota_vab_industria_espana_pct,
    b.cifra_negocios_miles_eur,
    b.cifra_negocios_miles_eur * 1000.0 / nullif(p.poblacion, 0) * d.factor as cifra_negocios_hab_real,
    b.ocupados_industria,
    1000.0 * b.ocupados_industria / nullif(p.poblacion, 0) as ocupados_industria_1000_hab,
    p.poblacion,
    d.anio_base,
    case when b.cod_ccaa in ('15', '16')
         then 'Código INE (Navarra 15, País Vasco 16); Eurostat ES22 y ES21' end as nota
from base b
left join {{ ref('territorios_ccaa') }} t on t.cod_ccaa = b.cod_ccaa
cross join pob_rango r
left join pob p on p.cod_ccaa = b.cod_ccaa and p.anio = greatest(least(b.anio, r.amax), r.amin)
left join {{ ref('deflactor') }} d on d.anio = b.anio
left join base es on es.cod_ccaa = '00' and es.anio = b.anio
