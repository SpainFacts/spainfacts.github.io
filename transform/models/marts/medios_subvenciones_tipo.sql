-- Subvenciones a medios de comunicación por año y tipo de ayuda (clasificación
-- manual de cada convocatoria en la seed medios_subvenciones_convocatorias):
-- estructural, lengua (uso de una lengua cooficial o propia), digitalizacion_ia,
-- proyectos (incluye revistas culturales) y otras (convenios y nominativas).
-- Fuente: BDNS (IGAE). Euros de 2025 (main.deflactor); eur_hab_real sobre la
-- población de España (todas las administraciones juntas). El último año es
-- parcial. Ver medios_subvenciones_concesiones.
with conc as (
    select * from {{ ref('medios_subvenciones_concesiones') }}
),

pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and cod = '00' and sexo = 'Total'
),

rango_pob as (select min(anio) as amin, max(anio) as amax from pob),

ultimo as (select max(anio) as anio_max from conc)

select
    c.anio,
    c.tipo_ayuda,
    case c.tipo_ayuda
        when 'estructural' then 'Estructurales (funcionamiento y edición)'
        when 'lengua' then 'Lengua cooficial o propia'
        when 'digitalizacion_ia' then 'Digitalización e IA'
        when 'proyectos' then 'Proyectos y revistas culturales'
        else 'Convenios y nominativas'
    end as tipo_ayuda_nombre,
    sum(c.importe_eur) as importe_eur_nominal,
    sum(c.importe_eur_real) as importe_eur_real,
    sum(c.importe_eur_real) / any_value(p.poblacion) as eur_hab_real,
    cast(count(*) as integer) as n_concesiones,
    cast(count(distinct c.cod_bdns) as integer) as n_convocatorias,
    any_value(c.anio = u.anio_max) as parcial
from conc c
cross join ultimo u
cross join rango_pob r
left join pob p on p.anio = greatest(least(c.anio, r.amax), r.amin)
group by c.anio, c.tipo_ayuda
order by c.anio, c.tipo_ayuda
