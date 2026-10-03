-- Empleo y paro de la construcción por trimestre, España y comunidades (INE, Encuesta de
-- Población Activa, CNAE-2009): ocupados por sector y provincia (tabla 65354, sumados a comunidad)
-- y parados por sector del último empleo y comunidad (tabla 65331). Desde 2008T1.
--   ocupados_constr_miles / ocupados_total_miles: miles de personas.
--   pct_ocupados_constr: % de los ocupados que trabajan en la construcción.
--   ocupados_constr_1000hab: ocupados de la construcción por 1.000 habitantes (población a
--     1 de enero, main.poblacion_territorios; para años sin padrón, el último disponible).
--   parados_constr_miles: parados cuyo último empleo (dejado hace menos de un año) era en la
--     construcción. tasa_paro_constr = parados / (ocupados + parados) del sector, en %: es una
--     aproximación, porque los parados que dejaron su empleo hace más de un año no tienen sector.
--   OJO: desde 2026 el INE publica también tablas en CNAE-2025 (79333, 79336) con cifras algo
--   distintas; aquí se sigue la serie CNAE-2009 para no romper la comparación.
--   La serie anual larga (desde 1995) y la comparación con la UE están en construccion_peso_ue.
with ocup_prov as (
    select
        split_part(serie, '. ', 1) as territorio,
        split_part(serie, '. ', 4) as sector,
        cast(anyo as integer) as anio,
        quarter(cast(to_timestamp(fecha / 1000 + 43200) as date)) as trimestre,
        valor
    from {{ source('raw_construccion', 'ine_construccion_ocupados_prov') }}
    where split_part(serie, '. ', 3) = 'Ambos sexos' and valor is not null
),

-- variantes de nombre de la tabla 65354 que no están en el seed ine_provincias_nombres
extra_nombres as (
    select * from (values
        ('Araba/Álava', '01'), ('Balears, Illes', '07'), ('Bizkaia', '48'), ('Coruña, A', '15'),
        ('Gipuzkoa', '20'), ('Palmas, Las', '35'), ('Rioja, La', '26')
    ) as t(nombre_ine, cod_prov)
),

nombres as (
    select nombre_ine, cod_prov from {{ ref('ine_provincias_nombres') }}
    union all
    select nombre_ine, cod_prov from extra_nombres
    where nombre_ine not in (select nombre_ine from {{ ref('ine_provincias_nombres') }})
),

ocup_cod as (
    select
        case when o.territorio = 'Total Nacional' then '00' else tp.cod_ccaa end as cod,
        o.territorio,
        o.sector, o.anio, o.trimestre, o.valor
    from ocup_prov o
    left join nombres pn on pn.nombre_ine = o.territorio
    left join {{ ref('territorios_provincias') }} tp on tp.cod_prov = pn.cod_prov
),

ocup as (
    select
        cod, anio, trimestre,
        sum(valor) filter (where sector = 'Construcción') as ocupados_constr_miles,
        sum(valor) filter (where sector = 'Total') as ocupados_total_miles,
        count(distinct territorio) filter (where sector = 'Total') as n_provincias
    from ocup_cod
    where cod is not null
    group by all
),

par as (
    select
        n.cod_ccaa as cod,
        cast(p.anyo as integer) as anio,
        quarter(cast(to_timestamp(p.fecha / 1000 + 43200) as date)) as trimestre,
        max(p.valor) filter (where split_part(p.serie, '. ', 4) = 'Construcción') as parados_constr_miles,
        max(p.valor) filter (where split_part(p.serie, '. ', 4) = 'Total') as parados_total_miles
    from {{ source('raw_construccion', 'ine_construccion_parados_ccaa') }} p
    join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = split_part(p.serie, '. ', 1)
    where split_part(p.serie, '. ', 3) = 'Ambos sexos'
    group by all
),

base as (
    select
        coalesce(o.cod, p.cod) as cod,
        coalesce(o.anio, p.anio) as anio,
        coalesce(o.trimestre, p.trimestre) as trimestre,
        o.ocupados_constr_miles, o.ocupados_total_miles, o.n_provincias,
        p.parados_constr_miles, p.parados_total_miles
    from ocup o
    full join par p on p.cod = o.cod and p.anio = o.anio and p.trimestre = o.trimestre
),

pob as (
    select nivel, cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total' and nivel in ('pais', 'ccaa')
)

select
    b.cod,
    coalesce(t.nombre, 'España') as nombre,
    b.n_provincias,
    b.anio,
    b.trimestre,
    b.anio || 'T' || b.trimestre as periodo,
    make_date(b.anio, 3 * b.trimestre - 2, 1) as fecha,
    b.ocupados_constr_miles,
    b.ocupados_total_miles,
    100.0 * b.ocupados_constr_miles / nullif(b.ocupados_total_miles, 0) as pct_ocupados_constr,
    1000.0 * b.ocupados_constr_miles * 1000.0 / nullif(p.poblacion, 0) as ocupados_constr_1000hab,
    b.parados_constr_miles,
    b.parados_total_miles,
    100.0 * b.parados_constr_miles / nullif(b.ocupados_constr_miles + b.parados_constr_miles, 0) as tasa_paro_constr,
    cast(p.poblacion as bigint) as poblacion
from base b
left join {{ ref('territorios_ccaa') }} t on t.cod_ccaa = b.cod
asof left join pob p
  on p.nivel = case when b.cod = '00' then 'pais' else 'ccaa' end and p.cod = b.cod and p.anio <= b.anio
order by b.cod, b.anio, b.trimestre
