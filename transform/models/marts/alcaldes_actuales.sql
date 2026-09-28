-- Alcalde vigente de cada municipio (mandato 2023-2027) con su familia política
-- y la continuidad hacia atrás en el historial desde 1979:
--   anios_en_cargo  años seguidos de la misma persona (enlazando mandatos por
--                   nombre dentro del municipio; ver alcaldes_historia)
--   anios_partido   años seguidos de la misma familia en la alcaldía, aunque
--                   cambie el alcalde; primer_anio_familia y mandatos_familia
--                   describen ese mismo tramo
--   cambio_ultimo_mandato  la familia es distinta de la del último alcalde del
--                   mandato 2019-2023 (null si aquel no tiene familia conocida)
-- Los años se cuentan hasta la fecha de construcción del modelo.
with historia as (
    select * from {{ ref('alcaldes_historia') }}
),

actual as (
    select * from historia where es_actual
),

anterior as (
    select cod_mun, familia as familia_anterior
    from historia
    where mandato = '2019-2023'
    qualify row_number() over (partition by cod_mun order by orden desc) = 1
),

pob as (
    select cod_mun, poblacion, anio as anio_poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
    qualify anio = max(anio) over ()
),

municipios as (
    select cod_mun, cod_prov, cod_ccaa, nombre from {{ ref('stg_ine_municipios') }}
)

select
    a.cod_mun,
    coalesce(m.nombre, a.municipio) as municipio,
    coalesce(m.cod_prov, left(a.cod_mun, 2)) as cod_prov,
    coalesce(m.cod_ccaa, pr.cod_ccaa) as cod_ccaa,
    a.alcalde,
    a.cargo,
    a.fecha_posesion,
    a.partido_original,
    a.familia,
    a.siglas_familia,
    a.color,
    a.inicio_tramo_persona as fecha_inicio_alcalde,
    round(date_diff('day', a.inicio_tramo_persona, current_date) / 365.25, 1) as anios_en_cargo,
    a.inicio_tramo_familia as fecha_inicio_familia,
    round(date_diff('day', a.inicio_tramo_familia, current_date) / 365.25, 1) as anios_partido,
    year(a.inicio_tramo_familia) as primer_anio_familia,
    a.mandatos_tramo_familia as mandatos_familia,
    ant.familia_anterior,
    case
        when ant.familia_anterior is null
            or ant.familia_anterior in ('Sin detalle en la fuente', 'Comisión gestora')
            or a.familia in ('Sin detalle en la fuente', 'Comisión gestora') then null
        else ant.familia_anterior <> a.familia
    end as cambio_ultimo_mandato,
    p.poblacion,
    p.anio_poblacion
from actual a
left join anterior ant using (cod_mun)
left join municipios m using (cod_mun)
left join {{ ref('territorios_provincias') }} pr on pr.cod_prov = left(a.cod_mun, 2)
left join pob p using (cod_mun)
