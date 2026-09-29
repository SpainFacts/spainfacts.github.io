-- Natalidad, mortalidad y crecimiento de la población por año y territorio
-- (España 'pais', comunidad 'ccaa', provincia 'provincia'), desde 1975.
-- Fuentes (INE):
--   * Movimiento Natural de la Población, tablas 6524 (nacimientos por residencia
--     de la madre) y 6561 (defunciones por residencia): datos mensuales sumados
--     al año. Las comunidades suman sus provincias.
--   * Indicadores Demográficos Básicos: tasa bruta de natalidad (1470/1432) y de
--     mortalidad (1482/1445) por 1.000 hab.; indicador coyuntural de fecundidad
--     (1478/1441, hijos por mujer, con desglose por nacionalidad de la madre en
--     España y comunidades); edad media a la maternidad (1581/1580); % de nacidos
--     de madre extranjera (2777, España y comunidades, desde 2002).
--   * Estadística Continua de Población (56945, vía stg_ine_poblacion): población
--     a 1 de enero, para el crecimiento total.
-- Cálculos:
--   vegetativo_1000   = tasa de natalidad - tasa de mortalidad (lo que el INE llama
--                       saldo vegetativo por 1.000 hab.).
--   crecimiento       = población a 1 de enero de anio+1 - población a 1 de enero de anio.
--   crecimiento_1000  = crecimiento por 1.000 hab. de la población media del año
--                       (media de ambos 1 de enero).
--   resto_1000        = crecimiento_1000 - vegetativo por 1.000 hab. de esa misma
--                       población media: la parte del crecimiento que no explican
--                       nacimientos y defunciones, es decir, el saldo migratorio
--                       (exterior y, en comunidades y provincias, también interior)
--                       más ajustes estadísticos.
--   saldo_exterior_1000 = saldo migratorio con el extranjero de la Estadística de
--                       Migraciones (mart inmigracion_saldos, desde 2021, España y comunidades).
with provincias as (
    select cod_prov, cod_ccaa from {{ ref('territorios_provincias') }}
),

-- Nacimientos y defunciones: suma de los 12 meses; solo años completos
mnp as (
    select 'nac' as fenomeno, cod, nivel, anio, sum(valor) as n, count(*) as meses
    from {{ source('raw_demografia', 'ine_nacimientos_mensual') }}
    where nivel in ('pais', 'provincia')
    group by all
    union all
    select 'def', cod, nivel, anio, sum(valor), count(*)
    from {{ source('raw_demografia', 'ine_defunciones_mensual') }}
    where nivel in ('pais', 'provincia')
    group by all
),

mnp_territorios as (
    select fenomeno, nivel, cod, anio, n from mnp where meses = 12
    union all
    select m.fenomeno, 'ccaa', p.cod_ccaa, m.anio, sum(m.n)
    from mnp m
    join provincias p on p.cod_prov = m.cod
    where m.nivel = 'provincia' and m.meses = 12
    group by all
),

conteos as (
    select nivel, cod, cast(anio as integer) as anio,
        max(n) filter (where fenomeno = 'nac') as nacimientos,
        max(n) filter (where fenomeno = 'def') as defunciones
    from mnp_territorios
    group by all
),

-- Indicadores del INE. España aparece en las tablas de provincias y en las de
-- comunidades con el mismo valor: se toma una sola vez.
tasas as (
    select 'tbn' as indicador, nivel, cod, anio, nacionalidad, null as orden, valor
    from {{ source('raw_demografia', 'ine_tasa_natalidad') }}
    union all
    select 'tbm', nivel, cod, anio, null, null, valor
    from {{ source('raw_demografia', 'ine_tasa_mortalidad') }}
    union all
    select 'icf', nivel, cod, anio, nacionalidad, orden, valor
    from {{ source('raw_demografia', 'ine_fecundidad') }}
    union all
    select 'emm', nivel, cod, anio, nacionalidad, orden, valor
    from {{ source('raw_demografia', 'ine_edad_maternidad') }}
    union all
    select 'pme', nivel, cod, anio, nacionalidad, orden, valor
    from {{ source('raw_demografia', 'ine_nacidos_nacionalidad_madre') }}
    where nacionalidad = 'Extranjera'
),

indicadores as (
    select nivel, cod, cast(anio as integer) as anio,
        max(valor) filter (where indicador = 'tbn') as tasa_natalidad,
        max(valor) filter (where indicador = 'tbm') as tasa_mortalidad,
        max(valor) filter (where indicador = 'icf' and coalesce(nacionalidad, 'Ambas nacionalidades') = 'Ambas nacionalidades' and orden = 'Todos') as fecundidad,
        max(valor) filter (where indicador = 'icf' and nacionalidad = 'Española' and orden = 'Todos') as fecundidad_espanolas,
        max(valor) filter (where indicador = 'icf' and nacionalidad = 'Extranjera' and orden = 'Todos') as fecundidad_extranjeras,
        max(valor) filter (where indicador = 'emm' and coalesce(nacionalidad, 'Ambas nacionalidades') = 'Ambas nacionalidades' and orden = 'Todos') as edad_maternidad,
        max(valor) filter (where indicador = 'emm' and coalesce(nacionalidad, 'Ambas nacionalidades') = 'Ambas nacionalidades' and orden = 'Primero') as edad_primer_hijo,
        max(valor) filter (where indicador = 'pme' and orden = 'Todos') as pct_madre_extranjera
    from tasas
    where nivel in ('pais', 'ccaa', 'provincia')
    group by all
),

-- Población a 1 de enero (ECP): provincias, España y comunidades como suma
pob_prov as (
    select cast(anio as integer) as anio, coalesce(cod_prov, '00') as cod,
        case when es_total_nacional then 'pais' else 'provincia' end as nivel,
        poblacion
    from {{ ref('stg_ine_poblacion') }}
    where es_todas_las_edades and sexo = 'Total'
),

poblacion as (
    select * from pob_prov
    union all
    select a.anio, p.cod_ccaa, 'ccaa', sum(a.poblacion)
    from pob_prov a
    join provincias p on p.cod_prov = a.cod
    where a.nivel = 'provincia'
    group by all
),

saldo_exterior as (
    select anio, nivel, cod, saldo_exterior
    from {{ ref('inmigracion_saldos') }}
    where nacionalidad = 'Total' and nivel in ('pais', 'ccaa')
),

base as (
    select
        coalesce(c.nivel, i.nivel) as nivel,
        coalesce(c.cod, i.cod) as cod,
        coalesce(c.anio, i.anio) as anio,
        c.nacimientos, c.defunciones,
        i.tasa_natalidad, i.tasa_mortalidad, i.fecundidad, i.fecundidad_espanolas,
        i.fecundidad_extranjeras, i.edad_maternidad, i.edad_primer_hijo, i.pct_madre_extranjera
    from conteos c
    full join indicadores i on i.nivel = c.nivel and i.cod = c.cod and i.anio = c.anio
)

select
    b.anio,
    b.nivel,
    b.cod,
    p0.poblacion as poblacion_inicio,
    p1.poblacion as poblacion_fin,
    b.nacimientos,
    b.defunciones,
    b.nacimientos - b.defunciones as crecimiento_vegetativo,
    b.tasa_natalidad,
    b.tasa_mortalidad,
    b.tasa_natalidad - b.tasa_mortalidad as vegetativo_1000,
    b.fecundidad,
    b.fecundidad_espanolas,
    b.fecundidad_extranjeras,
    b.edad_maternidad,
    b.edad_primer_hijo,
    b.pct_madre_extranjera,
    p1.poblacion - p0.poblacion as crecimiento,
    1000.0 * (p1.poblacion - p0.poblacion) / ((p0.poblacion + p1.poblacion) / 2.0) as crecimiento_1000,
    1000.0 * ((p1.poblacion - p0.poblacion) - (b.nacimientos - b.defunciones)) / ((p0.poblacion + p1.poblacion) / 2.0) as resto_1000,
    (p1.poblacion - p0.poblacion) - (b.nacimientos - b.defunciones) as resto,
    s.saldo_exterior,
    1000.0 * s.saldo_exterior / ((p0.poblacion + p1.poblacion) / 2.0) as saldo_exterior_1000,
    b.nivel || '-' || b.cod || '-' || b.anio as clave
from base b
left join poblacion p0 on p0.nivel = b.nivel and p0.cod = b.cod and p0.anio = b.anio
left join poblacion p1 on p1.nivel = b.nivel and p1.cod = b.cod and p1.anio = b.anio + 1
left join saldo_exterior s on s.nivel = b.nivel and s.cod = b.cod and s.anio = b.anio
