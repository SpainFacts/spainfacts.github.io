-- Alumnado de enseñanzas no universitarias (régimen general) por comunidad autónoma, curso,
-- enseñanza y titularidad/financiación del centro. Fuente: Ministerio de Educación, FP y
-- Deportes, Estadística de las Enseñanzas no universitarias (EDUCAbase):
--   * cursos 2011-2012 a último definitivo: resultados detallados del curso (tabla 1.1,
--     gen-todas/todas_01.px) con las cinco titularidades: Total, Pública, Privada (suma de las
--     dos siguientes), Privada concertada y Privada no concertada;
--   * cursos 1990-1991 a 2010-2011 y el último curso de avance (es_avance): series
--     AlumnadoGen/alumnado_N_NN.px, que solo separan Pública y Privada (la concertada no se
--     publica por comunidad en .px antes de 2011-12).
-- Enseñanzas armonizadas: FP de grado medio y superior suman presencial y a distancia (sin los
-- cursos de especialización); Bachillerato suma presencial y a distancia. «Total» es todo el
-- régimen general de la fuente (incluye además PCPI, Garantía Social, FP I/II, BUP/COU y otros
-- programas formativos que no tienen fila propia).
-- cuota_pct: alumnos de la titularidad sobre el Total de la misma comunidad, curso y enseñanza.
-- anio = año de fin del curso (2024-2025 -> 2025).
with curso_raw as (
    select
        curso,
        cod_ccaa,
        case titularidad
            when 'TODOS LOS CENTROS' then 'Total'
            when 'CENTROS PÚBLICOS' then 'Pública'
            when 'CENTROS PRIVADOS' then 'Privada'
            when 'Enseñanza privada concertada' then 'Privada concertada'
            when 'Enseñanza privada no concertada' then 'Privada no concertada'
        end as titularidad,
        lower(ensenanza) as e,
        alumnos
    from {{ source('raw_educacion_privada', 'educacion_privada_alumnado_curso') }}
),

curso as (
    select
        curso,
        cod_ccaa,
        titularidad,
        case
            when e = 'total' then 'Total'
            when e like '%infantil%primer%' then 'Infantil primer ciclo'
            when e like '%infantil%segundo%' then 'Infantil segundo ciclo'
            when e = 'e. primaria' then 'Primaria'
            when e like 'educación especial%' then 'Educación especial'
            when e = 'eso' then 'ESO'
            when e like 'bachillerato%' then 'Bachillerato'
            when e like 'c%f%b_sic%' and e not like 'cursos%' then 'FP grado básico'
            when e like 'c%f%grado medio%' and e not like 'cursos%' then 'FP grado medio'
            when e like 'c%f%grado superior%' and e not like 'cursos%' then 'FP grado superior'
        end as ensenanza,
        false as es_avance,
        'EDUCAbase, resultados detallados del curso (gen-todas/todas_01)' as fuente,
        alumnos
    from curso_raw
),

serie_raw as (
    select
        cast(left(periodo, 4) as integer) as ini,
        es_avance,
        regexp_replace(territorio, '\s*\(\d+\)$', '') as territorio,
        case titularidad
            when 'TODOS LOS CENTROS' then 'Total'
            when 'CENTROS PÚBLICOS' then 'Pública'
            when 'CENTROS PRIVADOS' then 'Privada'
        end as titularidad,
        case ensenanza
            when 'Total régimen general' then 'Total'
            when 'E. Infantil primer ciclo' then 'Infantil primer ciclo'
            when 'E. Infantil segundo ciclo' then 'Infantil segundo ciclo'
            when 'E. Primaria' then 'Primaria'
            when 'Educación Especial' then 'Educación especial'
            when 'ESO' then 'ESO'
            when 'Bachillerato' then 'Bachillerato'
            when 'FP Grado Básico' then 'FP grado básico'
            when 'FP Grado Medio presencial' then 'FP grado medio'
            when 'FP Grado Medio a distancia' then 'FP grado medio'
            when 'FP Grado Superior presencial' then 'FP grado superior'
            when 'FP Grado Superior a distancia' then 'FP grado superior'
        end as ensenanza,
        alumnos
    from {{ source('raw_educacion_privada', 'educacion_privada_alumnado_serie') }}
),

anios_detalle as (
    select distinct cast(right(curso, 4) as integer) as anio from curso
),

serie as (
    select
        cast(s.ini as varchar) || '-' || cast(s.ini + 1 as varchar) as curso,
        case when s.territorio = 'TOTAL' then '00' else n.cod_ccaa end as cod_ccaa,
        s.titularidad,
        s.ensenanza,
        s.es_avance,
        'EDUCAbase, series de alumnado (AlumnadoGen)' as fuente,
        s.alumnos
    from serie_raw s
    left join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = replace(s.territorio, 'Castilla-La Mancha', 'Castilla - La Mancha')
    where s.ensenanza is not null
      -- solo los cursos sin resultados detallados (anteriores a 2011-12 y el avance)
      and s.ini + 1 not in (select anio from anios_detalle)
),

unido as (
    select curso, cod_ccaa, titularidad, ensenanza, es_avance, fuente, sum(alumnos) as alumnos
    from (select * from curso where ensenanza is not null union all select * from serie)
    group by all
),

con_total as (
    select
        u.*,
        sum(case when titularidad = 'Total' then alumnos end)
            over (partition by curso, cod_ccaa, ensenanza) as alumnos_total
    from unido u
)

select
    c.cod_ccaa,
    t.nombre as ccaa,
    c.curso,
    cast(right(c.curso, 4) as integer) as anio,
    c.ensenanza,
    case c.ensenanza
        when 'Total' then 0 when 'Infantil primer ciclo' then 1 when 'Infantil segundo ciclo' then 2
        when 'Primaria' then 3 when 'ESO' then 4 when 'Bachillerato' then 5
        when 'FP grado básico' then 6 when 'FP grado medio' then 7 when 'FP grado superior' then 8
        when 'Educación especial' then 9
    end as orden_ensenanza,
    c.titularidad,
    cast(c.alumnos as bigint) as alumnos,
    100.0 * c.alumnos / nullif(c.alumnos_total, 0) as cuota_pct,
    c.es_avance,
    c.fuente
from con_total c
join {{ ref('territorios') }} t
    on t.cod = c.cod_ccaa and t.nivel = case when c.cod_ccaa = '00' then 'pais' else 'ccaa' end
-- ensenanzas que aún no existían en el curso (FP básica antes de 2014-15...) vienen a 0 en la fuente
where c.alumnos_total > 0
