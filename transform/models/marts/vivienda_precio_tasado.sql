-- Valor tasado medio de la vivienda libre (€/m²) por trimestre, España,
-- comunidades y provincias (Ministerio de Vivienda y Agenda Urbana, boletín
-- estadístico, tabla 35101000; tasaciones hechas para conceder hipotecas).
-- euros_m2_real: en euros del año base de main.deflactor (IPC trimestral, ver
-- vivienda_deflactor_trimestral); solo desde 2002, primer año con IPC en la base.
-- precio_90m2_real: valor de una vivienda tipo de 90 m² (referencia habitual
-- de superficie media). interanual_*: frente al mismo trimestre del año anterior.
with base as (
    select
        nivel,
        cod,
        cast(anio as integer) as anio,
        cast(trimestre as integer) as trimestre,
        euros_m2
    from {{ source('raw_vivienda', 'vivienda_valor_tasado') }}
    where euros_m2 is not null
),

real as (
    select
        b.*,
        make_date(b.anio, 3 * b.trimestre - 2, 1) as fecha,
        b.euros_m2 * d.factor as euros_m2_real,
        d.anio_base
    from base b
    left join {{ ref('vivienda_deflactor_trimestral') }} d
      on d.anio = b.anio and d.trimestre = b.trimestre
)

select
    r.nivel,
    r.cod,
    coalesce(t.nombre, case when r.cod = '00' then 'España' end) as nombre,
    r.fecha,
    r.anio,
    r.trimestre,
    cast(r.anio as varchar) || '-T' || cast(r.trimestre as varchar) as periodo,
    r.euros_m2,
    r.euros_m2_real,
    90 * r.euros_m2 as precio_90m2,
    90 * r.euros_m2_real as precio_90m2_real,
    r.anio_base,
    100 * (r.euros_m2 / a.euros_m2 - 1) as interanual_nominal,
    100 * (r.euros_m2_real / a.euros_m2_real - 1) as interanual_real
from real r
left join real a
  on a.nivel = r.nivel and a.cod = r.cod and a.anio = r.anio - 1 and a.trimestre = r.trimestre
left join {{ ref('territorios') }} t
  on t.nivel = r.nivel and t.cod = r.cod
