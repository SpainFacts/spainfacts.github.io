-- PIB y componentes de la demanda de España por trimestre (Eurostat namq_10_gdp,
-- desestacionalizados y corregidos de calendario). El volumen encadenado (base
-- 2010) se reexpresa en euros del último año completo multiplicándolo, para
-- cada componente, por su cociente precios corrientes / volumen de ese año; así
-- el nivel es comparable con los euros de hoy y la evolución es la real.
-- pct_pib: peso nominal sobre el PIB del trimestre. por_habitante_real: euros
-- reales por habitante en ritmo anual (trimestre x 4 / población media del año).
with base as (
    select
        cast(left(trimestre, 4) as integer) as anio,
        cast(right(trimestre, 1) as integer) as trim,
        componente,
        max(case when unidad = 'CLV10_MEUR' then valor end) as volumen,
        max(case when unidad = 'CP_MEUR' then valor end) as nominal,
        max(case when unidad = 'CLV_PCH_SM' then valor end) as interanual
    from {{ source('raw_economia', 'eurostat_pib_trimestral') }}
    group by all
),


completo as (
    select max(anio) as anio
    from (select anio from base where componente = 'B1GQ' and nominal is not null group by anio having count(*) = 4)
),

escala as (
    select componente, sum(nominal) / sum(volumen) as factor
    from base
    where anio = (select anio from completo)
    group by componente
),

pib as (
    select anio, trim, nominal as pib_nominal from base where componente = 'B1GQ'
),

poblacion as (
    select cast(periodo as integer) as anio, 1000 * valor as poblacion
    from {{ source('raw_eurostat_extra', 'eurostat_poblacion') }}
)

select
    make_date(b.anio, 3 * b.trim - 2, 1) as trimestre,
    b.anio,
    b.trim,
    b.componente,
    case b.componente
        when 'B1GQ' then 'PIB'
        when 'P3' then 'Consumo final'
        when 'P31_S14_S15' then 'Consumo de los hogares'
        when 'P3_S13' then 'Consumo público'
        when 'P51G' then 'Inversión'
        when 'P6' then 'Exportaciones'
        when 'P7' then 'Importaciones'
    end as nombre,
    b.nominal as nominal_meur,
    b.volumen * e.factor as real_meur,
    (select anio from completo) as anio_base,
    b.interanual,
    100 * b.nominal / p.pib_nominal as pct_pib,
    4e6 * b.volumen * e.factor / po.poblacion as por_habitante_real
from base b
join escala e using (componente)
join pib p using (anio, trim)
left join poblacion po
  on po.anio = least(b.anio, (select max(anio) from poblacion))
where b.nominal is not null
