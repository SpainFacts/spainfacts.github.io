-- Gasto público en conciertos educativos por comunidad autónoma y año. Fuente: Ministerio de
-- Educación, FP y Deportes, Estadística del Gasto Público en Educación (EDUCAbase):
--   * serie 7 (series_07.px): gasto en conciertos y subvenciones a la enseñanza privada de cada
--     administración educativa (consejería/departamento de educación; España = TOTAL, que suma
--     además el Ministerio, que paga los conciertos de Ceuta y Melilla);
--   * serie 1 (series_01.px): gasto público en educación de cada consejería de educación,
--     excluidos capítulos financieros (España = Ministerio + administraciones educativas de las
--     CCAA). peso_pct = conciertos / ese gasto. No incluye el gasto educativo de otras
--     consejerías ni de los ayuntamientos.
-- Euros reales: deflactor IPC de España (main.deflactor, euros de anio_base). Por habitante:
-- población a 1 de enero del año (main.poblacion_territorios).
-- Por alumno de la concertada: alumnado en enseñanza privada concertada (todas las enseñanzas
-- de régimen general, incluido el primer ciclo de infantil subvencionado) del curso que acaba
-- en el año (curso 2023-2024 para 2024), de educacion_privada_alumnado; solo desde 2012.
-- Nota: la partida incluye también subvenciones a centros privados no concertados y las
-- transferencias a universidades privadas (cuadra con el total de la tabla anual de
-- transferencias por enseñanza): universitaria_meur las separa desde 2017 y
-- conciertos_no_univ_eur_alumno_real calcula el euro por alumno sin ellas.
with conciertos_raw as (
    select
        trim(regexp_replace(split_part(administracion, ' - ', 1), '\s*\(\d+\)$', '')) as adm,
        anio,
        miles_eur
    from {{ source('raw_educacion_privada', 'educacion_privada_gasto_conciertos') }}
),

conciertos as (
    select
        case when c.adm = 'TOTAL' then '00' else n.cod_ccaa end as cod_ccaa,
        c.anio,
        c.miles_eur / 1000.0 as conciertos_meur
    from conciertos_raw c
    left join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = replace(c.adm, 'Castilla-La Mancha', 'Castilla - La Mancha')
    where c.adm = 'TOTAL' or n.cod_ccaa is not null
),

gasto_raw as (
    select
        trim(regexp_replace(split_part(administracion, ' - ', 1), '\s*\(\d+\)$', '')) as adm,
        administracion,
        anio,
        miles_eur
    from {{ source('raw_educacion_privada', 'educacion_privada_gasto_admin') }}
    where cobertura = 'Excluídos capitulos financieros'
),

gasto as (
    select
        case when g.administracion like 'Minist. de Educación y Admones.%' then '00' else n.cod_ccaa end as cod_ccaa,
        g.anio,
        g.miles_eur / 1000.0 as gasto_educacion_meur
    from gasto_raw g
    left join {{ ref('ine_ccaa_nombres') }} n
        on n.nombre_ine = replace(g.adm, 'Castilla-La Mancha', 'Castilla - La Mancha') and g.administracion like '%Consejería/Dpto. de Educación%'
    where g.administracion like 'Minist. de Educación y Admones.%' or n.cod_ccaa is not null
),

concertada as (
    select cod_ccaa, anio, alumnos as alumnos_concertada
    from {{ ref('educacion_privada_alumnado') }}
    where ensenanza = 'Total' and titularidad = 'Privada concertada'
),

universitaria as (
    select cod_ccaa, anio, transferencias_meur as universitaria_meur
    from {{ ref('educacion_privada_conciertos_ensenanza') }}
    where ensenanza = 'Universitaria'
),

poblacion as (
    select cod, anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel in ('pais', 'ccaa') and sexo = 'Total'
)

select
    c.cod_ccaa,
    t.nombre as ccaa,
    c.anio,
    c.conciertos_meur,
    c.conciertos_meur * d.factor as conciertos_meur_real,
    1e6 * c.conciertos_meur * d.factor / p.poblacion as conciertos_eur_hab_real,
    g.gasto_educacion_meur,
    g.gasto_educacion_meur * d.factor as gasto_educacion_meur_real,
    100.0 * c.conciertos_meur / nullif(g.gasto_educacion_meur, 0) as peso_pct,
    a.alumnos_concertada,
    1e6 * c.conciertos_meur * d.factor / nullif(a.alumnos_concertada, 0) as conciertos_eur_alumno_real,
    u.universitaria_meur,
    1e6 * (c.conciertos_meur - u.universitaria_meur) * d.factor
        / nullif(a.alumnos_concertada, 0) as conciertos_no_univ_eur_alumno_real,
    p.poblacion,
    d.anio_base
from conciertos c
join {{ ref('territorios') }} t
    on t.cod = c.cod_ccaa and t.nivel = case when c.cod_ccaa = '00' then 'pais' else 'ccaa' end
left join gasto g on g.cod_ccaa = c.cod_ccaa and g.anio = c.anio
left join concertada a on a.cod_ccaa = c.cod_ccaa and a.anio = c.anio
left join universitaria u on u.cod_ccaa = c.cod_ccaa and u.anio = c.anio
left join poblacion p on p.cod = c.cod_ccaa and p.anio = c.anio
left join {{ ref('deflactor') }} d on d.anio = c.anio
-- Antes del traspaso de competencias (1999-2000 en la mayoría) pagaba el Ministerio: sin fila
where c.conciertos_meur > 0
