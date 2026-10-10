-- Población cuya asistencia sanitaria pública está asignada a hospitales de gestión privada,
-- por comunidad y año (situación a 31 de diciembre), desde 1999 (seed sanidad_privada_concesiones
-- + serie sanidad_privada_concesiones_poblacion + población del INE, poblacion_territorios).
--   Cuenta un hospital en el año si abrió ese año o antes y no ha revertido a 31 de diciembre
--   (La Ribera revierte el 1-04-2018: cuenta hasta 2017). Modelos 'concesion_capitativa' y
--   'concierto_singular' (Fundación Jiménez Díaz); los PFI (solo servicios no sanitarios) van
--   aparte en poblacion_pfi. Povisa (Vigo) no entra: no consta el año en que su concierto empezó a
--   asignar población.
--   Población de cada hospital: la oficial del año si existe (seed de serie o año de la cifra del
--   seed principal); para los demás años se toma la cifra oficial más cercana en el tiempo y se
--   escala con la población de la comunidad (pob_ref x pob_ccaa(año) / pob_ccaa(año de la cifra)),
--   con poblacion_estimada = true. Las cifras de Dénia y Manises son de prensa (fiabilidad baja).
--   poblacion_ccaa: población a 1 de enero del año siguiente (= 31 de diciembre), o la última.
with h as (
    select * from {{ ref('sanidad_privada_gestion_privada') }}
    where poblacion_asignada is not null and anio_inicio is not null
      and modelo in ('concesion_capitativa', 'concierto_singular', 'pfi_no_sanitaria')
),

pob as (
    select cast(cod as varchar) as cod_ccaa, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total'
),

max_pob as (select max(anio) as max_anio, min(anio) as min_anio from pob),

anios as (
    select cast(a as integer) as anio
    from range(1999, (select max_anio from max_pob) + 1) t(a)
),

pob_dic as (
    -- población a 31-12 del año = 1 de enero del siguiente (acotado al rango disponible)
    select a.anio, p.cod_ccaa, p.poblacion
    from anios a
    cross join max_pob m
    join pob p on p.anio = greatest(least(a.anio + 1, m.max_anio), m.min_anio)
),

serie as (
    select cast(hospital_id as varchar) as hospital_id, cast(anio as integer) as anio,
        cast(poblacion_asignada as bigint) as poblacion, 0 as prioridad
    from {{ ref('sanidad_privada_concesiones_poblacion') }}
),

-- Cifras oficiales disponibles por hospital: la serie y la del seed principal (la serie manda si
-- coinciden en año).
refs as (
    select hospital_id, anio, poblacion, prioridad from serie
    union all
    select hospital_id, poblacion_anio, poblacion_asignada, 1 from h
),

activos_base as (
    select h.hospital_id, h.cod_ccaa, h.hospital, h.modelo, a.anio
    from h
    join anios a
        on a.anio >= h.anio_inicio
       and (h.anio_reversion is null or a.anio < h.anio_reversion)
),

-- Para cada año activo, la cifra oficial más cercana en el tiempo
ref_cercana as (
    select b.hospital_id, b.anio, r.anio as anio_ref, r.poblacion as poblacion_ref
    from activos_base b
    join refs r on r.hospital_id = b.hospital_id
    qualify row_number() over (partition by b.hospital_id, b.anio
                               order by abs(r.anio - b.anio), r.prioridad, r.anio desc) = 1
),

activos as (
    select
        b.hospital_id, b.cod_ccaa, b.hospital, b.modelo, b.anio,
        case when rc.anio_ref = b.anio then rc.poblacion_ref
             else rc.poblacion_ref * pa.poblacion / pr.poblacion end as poblacion,
        rc.anio_ref <> b.anio as estimada
    from activos_base b
    join ref_cercana rc on rc.hospital_id = b.hospital_id and rc.anio = b.anio
    left join pob_dic pa on pa.cod_ccaa = b.cod_ccaa and pa.anio = b.anio
    left join pob_dic pr on pr.cod_ccaa = b.cod_ccaa and pr.anio = rc.anio_ref
),

por_ccaa as (
    select
        cod_ccaa, anio,
        count(*) filter (where modelo <> 'pfi_no_sanitaria') as hospitales_gestion_privada,
        sum(poblacion) filter (where modelo <> 'pfi_no_sanitaria') as poblacion_gestion_privada,
        sum(poblacion) filter (where modelo = 'concesion_capitativa') as poblacion_concesion,
        sum(poblacion) filter (where modelo = 'concierto_singular') as poblacion_concierto_singular,
        count(*) filter (where modelo = 'pfi_no_sanitaria') as hospitales_pfi,
        sum(poblacion) filter (where modelo = 'pfi_no_sanitaria') as poblacion_pfi,
        bool_or(estimada) as poblacion_estimada,
        string_agg(case when modelo <> 'pfi_no_sanitaria' then hospital end, '; ' order by hospital)
            as hospitales
    from activos
    group by all
),

ccaa as (select distinct cod_ccaa from h)

select
    c.cod_ccaa,
    t.nombre as ccaa,
    a.anio,
    coalesce(p.hospitales_gestion_privada, 0) as hospitales_gestion_privada,
    round(coalesce(p.poblacion_gestion_privada, 0))::bigint as poblacion_gestion_privada,
    round(coalesce(p.poblacion_concesion, 0))::bigint as poblacion_concesion,
    round(coalesce(p.poblacion_concierto_singular, 0))::bigint as poblacion_concierto_singular,
    pd.poblacion as poblacion_ccaa,
    100.0 * coalesce(p.poblacion_gestion_privada, 0) / pd.poblacion as poblacion_gestion_privada_pct,
    coalesce(p.hospitales_pfi, 0) as hospitales_pfi,
    round(coalesce(p.poblacion_pfi, 0))::bigint as poblacion_pfi,
    100.0 * coalesce(p.poblacion_pfi, 0) / pd.poblacion as poblacion_pfi_pct,
    coalesce(p.poblacion_estimada, false) as poblacion_estimada,
    p.hospitales
from ccaa c
cross join anios a
left join por_ccaa p on p.cod_ccaa = c.cod_ccaa and p.anio = a.anio
left join pob_dic pd on pd.cod_ccaa = c.cod_ccaa and pd.anio = a.anio
left join {{ ref('territorios') }} t on t.nivel = 'ccaa' and t.cod = c.cod_ccaa
