-- Inmigraciones desde el extranjero y emigraciones hacia él en España por año
-- (INE, Estadística de Migraciones y Cambios de Residencia, tablas 69687 y
-- 69702, desde 2021), con tasas por 1.000 habitantes. Incluye españoles.
with entradas as (
    select cast(anyo as integer) as anio, valor as inmigraciones
    from {{ source('raw_migracion', 'ine_inmigraciones_anual') }}
    where serie like 'Todas las edades. Total. Dato base.%' and valor is not null
),

salidas as (
    select cast(anyo as integer) as anio, valor as emigraciones
    from {{ source('raw_migracion', 'ine_emigraciones_anual') }}
    where serie like 'Todas las edades. Total. Dato base.%' and valor is not null
),

poblacion as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and sexo = 'Total'
)

select
    e.anio,
    e.inmigraciones,
    s.emigraciones,
    e.inmigraciones - s.emigraciones as saldo,
    1000.0 * e.inmigraciones / p.poblacion as inmigraciones_1000,
    1000.0 * s.emigraciones / p.poblacion as emigraciones_1000,
    1000.0 * (e.inmigraciones - s.emigraciones) / p.poblacion as saldo_1000
from entradas e
join salidas s using (anio)
left join poblacion p on p.anio = least(e.anio, (select max(anio) from poblacion))
