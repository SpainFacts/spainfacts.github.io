-- Transferencias de las administraciones educativas a centros de titularidad privada por
-- comunidad autónoma, año y enseñanza (conciertos y subvenciones: infantil, primaria, ESO,
-- bachillerato, FP, educación especial y también universidades privadas). Fuente: Ministerio
-- de Educación, FP y Deportes, Estadística del Gasto Público en Educación, tabla anual
-- «Transferencias de las Admones. Educativas a centros educativos de titularidad privada por
-- administración educativa y enseñanza» (economicas/gasto/<año>/gasto07.px; gasto06.px en 2024),
-- desde 2017. Es el desglose que no da la serie de conciertos (educacion_privada_conciertos).
-- Grupos de la fuente: 'Total' (incluye universitaria), 'Total no universitaria',
-- 'Infantil y primaria', 'Secundaria y FP'. Trampas de la fuente: Asturias incluye el
-- bachillerato en ESO; Galicia incluyó en 2017 la ESO en primaria; el infantil solo se separa en
-- primer y segundo ciclo en algunos años.
-- Euros reales con main.deflactor; por alumno: alumnado de enseñanza privada concertada de la
-- misma enseñanza del curso que termina en el año (educacion_privada_alumnado).
-- peso_pct: % sobre el total de transferencias a centros privados de la misma administración.
with base as (
    select
        anio,
        trim(regexp_replace(split_part(administracion, ' - ', 1), '\s*\(\d+\)$', '')) as adm,
        case ensenanza
            when 'TOTAL' then 'Total'
            when 'TOTAL EDUCACIÓN NO UNIVERSITARIA' then 'Total no universitaria'
            when 'EDUCACIÓN INFANTIL Y PRIMARIA' then 'Infantil y primaria'
            when 'Educación Infantil' then 'Infantil'
            when 'Educación Infantil 1er ciclo' then 'Infantil primer ciclo'
            when 'Educación Infantil 2º ciclo' then 'Infantil segundo ciclo'
            when 'Educación Primaria' then 'Primaria'
            when 'EDUCACIÓN SECUNDARIA Y F.P.' then 'Secundaria y FP'
            when 'ESO' then 'ESO'
            when 'Bachillerato' then 'Bachillerato'
            when 'Formación Profesional (Total)' then 'FP'
            when 'FP Grado Medio' then 'FP grado medio'
            when 'FP Grado Superior' then 'FP grado superior'
            when 'FP Básica' then 'FP grado básico'
            when 'FP Grado Básica' then 'FP grado básico'
            when 'EDUCACIÓN ESPECIAL' then 'Educación especial'
            when 'OTRAS ENSEÑANZAS' then 'Otras enseñanzas'
            when 'EDUCACIÓN UNIVERSITARIA' then 'Universitaria'
        end as ensenanza,
        miles_eur
    from {{ source('raw_educacion_privada', 'educacion_privada_gasto_transferencias') }}
),

con_cod as (
    select
        case when b.adm = 'TOTAL' then '00' else n.cod_ccaa end as cod_ccaa,
        b.anio,
        b.ensenanza,
        b.miles_eur / 1000.0 as transferencias_meur
    from base b
    left join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = replace(b.adm, 'Castilla-La Mancha', 'Castilla - La Mancha')
    where (b.adm = 'TOTAL' or n.cod_ccaa is not null) and b.ensenanza is not null
),

con_total as (
    select
        *,
        sum(case when ensenanza = 'Total' then transferencias_meur end)
            over (partition by cod_ccaa, anio) as total_meur
    from con_cod
),

concertada as (
    select cod_ccaa, anio,
        case ensenanza when 'Total' then 'Total no universitaria' else ensenanza end as ensenanza,
        alumnos as alumnos_concertada
    from {{ ref('educacion_privada_alumnado') }}
    where titularidad = 'Privada concertada'
)

select
    c.cod_ccaa,
    t.nombre as ccaa,
    c.anio,
    c.ensenanza,
    c.transferencias_meur,
    c.transferencias_meur * d.factor as transferencias_meur_real,
    100.0 * c.transferencias_meur / nullif(c.total_meur, 0) as peso_pct,
    a.alumnos_concertada,
    1e6 * c.transferencias_meur * d.factor / nullif(a.alumnos_concertada, 0) as eur_alumno_concertada_real,
    d.anio_base
from con_total c
join {{ ref('territorios') }} t
    on t.cod = c.cod_ccaa and t.nivel = case when c.cod_ccaa = '00' then 'pais' else 'ccaa' end
left join concertada a on a.cod_ccaa = c.cod_ccaa and a.anio = c.anio and a.ensenanza = c.ensenanza
left join {{ ref('deflactor') }} d on d.anio = c.anio
