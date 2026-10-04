-- Personal al servicio de las administraciones públicas por edición semestral,
-- administración, sector, provincia (y comunidad), tipo de personal y sexo
-- (Registro Central de Personal, BEPSAP/EPSAP).
-- La provincia es la del puesto de trabajo. "Extranjero" (embajadas, misiones
-- de las Fuerzas Armadas...) queda sin provincia ni comunidad.
-- Las ediciones de 2023 en adelante se revisaron en agosto de 2026: el salto
-- de ~+240.000 efectivos entre julio de 2022 y enero de 2023 es metodológico.
with base as (
    select
        fecha,
        tipo_administracion,
        upper(strip_accents(coalesce(subtipo_administracion, ''))) as subtipo,
        upper(strip_accents(coalesce(area, ''))) as area,
        upper(strip_accents(coalesce(subtipo_personal, tipo_personal, ''))) as personal,
        upper(strip_accents(coalesce(provincia, ''))) as provincia,
        sexo,
        efectivos
    from {{ source('raw_empleo', 'bepsap_efectivos') }}
),

clasificado as (
    select
        fecha,
        case
            when tipo_administracion like '%ESTADO%' then 'Estado'
            when tipo_administracion like '%COMUNIDADES%' then 'Comunidades autónomas'
            else 'Entidades locales'
        end as administracion,
        case
            when subtipo like 'AYUNTAMIENTOS%' then 'Ayuntamientos'
            when subtipo like 'DIPUTACIONES%' then 'Diputaciones, cabildos y consejos insulares'
            when area like '%SANITARIA%' then 'Sanidad'
            when area like '%DOCENCIA NO UNIVERSITARIA%' then 'Educación no universitaria'
            when area like 'UNIVERSITARIA%' then 'Universidades'
            when area = 'FUERZAS ARMADAS' then 'Fuerzas Armadas'
            when area in ('GUARDIA CIVIL', 'POLICIA NACIONAL') then 'Policía Nacional y Guardia Civil'
            when area = 'POLICIA' then 'Policías autonómicas'
            when area like '%JUSTICIA%' or area like 'CARRERA %' or subtipo like '%TRIBUNALES%' then 'Justicia'
            when area like '%PENITENCIARI%' then 'Prisiones'
            when area = 'SEGURIDAD SOCIAL' then 'Seguridad Social'
            when tipo_administracion like '%ESTADO%' then 'Administración General del Estado'
            else 'Administración general autonómica'
        end as sector,
        case
            when personal = 'PERSONAL FUNCIONARIO DE CARRERA' then 'Funcionario de carrera'
            when personal like '%FUNCIONARIO INTERINO%' then 'Funcionario interino'
            when personal like 'PERSONAL LABORAL FIJO%' then 'Laboral fijo'
            when personal like 'PERSONAL LABORAL TEMPORAL%' or personal like '%<6 MESES%'
                 or personal like '%INDEFINIDO NO FIJO%' then 'Laboral temporal'
            when personal = 'PERSONAL LABORAL' then 'Laboral (sin detalle)'
            else 'Otro personal'
        end as tipo_personal,
        p.cod_prov,
        case sexo when 'H' then 'Hombres' when 'M' then 'Mujeres' end as sexo,
        efectivos
    from base b
    left join {{ ref('empleo_provincias_bepsap') }} p on p.provincia_bepsap = b.provincia
)

select
    c.fecha,
    c.administracion,
    c.sector,
    c.tipo_personal,
    year(c.fecha) as anio,
    c.cod_prov,
    coalesce(t.nombre, 'Extranjero') as provincia,
    t.cod_ccaa,
    coalesce(cc.nombre, 'Extranjero') as ccaa,
    c.sexo,
    sum(c.efectivos) as efectivos
from clasificado c
left join {{ ref('territorios_provincias') }} t on t.cod_prov = c.cod_prov
left join {{ ref('territorios_ccaa') }} cc on cc.cod_ccaa = t.cod_ccaa
group by all
