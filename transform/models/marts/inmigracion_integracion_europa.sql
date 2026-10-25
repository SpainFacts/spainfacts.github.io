-- Integración de los extranjeros en los países europeos (Eurostat): para cada
-- indicador, el valor de los nacionales del país, de los extranjeros (todos, de otro
-- país de la UE y de fuera de la UE) y la brecha extranjeros - nacionales en puntos.
--   empleo               tasa de empleo de 20 a 64 años (lfsa_ergan), %
--   paro                 tasa de paro de 15 a 74 años (lfsa_urgan), %
--   arope                riesgo de pobreza o exclusión social, 18 o más años (ilc_peps05n), %
--   abandono_escolar     abandono temprano de la educación, 18 a 24 años (edat_lfse_01), %
--   sobrecualificacion   ocupados con estudios superiores en empleos que no los piden, 20-64 (lfsa_eoqgan), %
--   hacinamiento         personas de 18 o más en viviendas hacinadas (ilc_lvho15), %
--   nacionalizaciones    adquisiciones de nacionalidad por 100 extranjeros residentes a 1 de
--                        enero (migr_acq / migr_pop1ctz); solo tiene valor en `extranjeros`
-- `sentido`: 1 si más es mejor (empleo), -1 si más es peor; la brecha se lee con él.
with indicadores as (
    select * from (values
        ('empleo', 'Tasa de empleo (20-64 años)', 1, 1),
        ('paro', 'Tasa de paro', -1, 2),
        ('arope', 'Riesgo de pobreza o exclusión social', -1, 3),
        ('abandono_escolar', 'Abandono escolar temprano (18-24 años)', -1, 4),
        ('sobrecualificacion', 'Sobrecualificación (20-64 años)', -1, 5),
        ('hacinamiento', 'Hacinamiento en la vivienda', -1, 6),
        ('nacionalizaciones', 'Nacionalizaciones por 100 extranjeros residentes', 1, 7)
    ) as t(indicador, nombre, sentido, orden)
),

integracion as (
    select
        indicador, geo, anio,
        max(valor) filter (where citizen = 'NAT') as nacionales,
        max(valor) filter (where citizen = 'FOR') as extranjeros,
        max(valor) filter (where citizen = 'EU27_2020_FOR') as extranjeros_ue,
        max(valor) filter (where citizen = 'NEU27_2020_FOR') as extranjeros_no_ue
    from {{ source('raw_migracion', 'eurostat_integracion') }}
    group by indicador, geo, anio
),

nacionalizaciones as (
    select
        'nacionalizaciones' as indicador, n.geo, n.anio,
        null::double as nacionales,
        100.0 * n.nacionalizaciones / p.poblacion as extranjeros,
        null::double as extranjeros_ue,
        null::double as extranjeros_no_ue
    from {{ source('raw_migracion', 'eurostat_nacionalizaciones') }} n
    join {{ source('raw_migracion', 'eurostat_poblacion_nacionalidad') }} p
      on p.geo = n.geo and p.anio = n.anio and p.citizen = 'FOR' and p.sexo = 'T' and p.edad = 'TOTAL'
    where p.poblacion > 0
),

todo as (
    select * from integracion
    union all
    select * from nacionalizaciones
)

select
    p.cod_pais,
    p.pais,
    t.anio,
    t.indicador,
    i.nombre,
    i.sentido,
    i.orden,
    t.nacionales,
    t.extranjeros,
    t.extranjeros_ue,
    t.extranjeros_no_ue,
    t.extranjeros - t.nacionales as brecha
from todo t
join indicadores i using (indicador)
join {{ ref('paises_iso') }} p on p.eurostat = t.geo
where t.extranjeros is not null
