-- Migraciones exteriores trimestrales de España por nacionalidad (INE,
-- Estadística Continua de Población, tablas 59011 y 59014): inmigraciones
-- desde el extranjero y emigraciones hacia él, con el saldo y las tasas por
-- 1.000 habitantes. Los datos más recientes son provisionales. fecha = primer día del trimestre;
-- es_parcial = último trimestre publicado (puede estar incompleto). Solo las nacionalidades
-- principales: no suman el total.
with entradas as (
    select
        date_trunc('quarter', cast(epoch_ms(fecha) + interval 12 hour as date)) as trimestre,
        split_part(serie, '. ', 2) as nacionalidad,
        valor as inmigraciones
    from {{ source('raw_migracion', 'ine_flujos_inmigracion') }}
    where valor is not null
),

salidas as (
    select
        date_trunc('quarter', cast(epoch_ms(fecha) + interval 12 hour as date)) as trimestre,
        split_part(serie, '. ', 2) as nacionalidad,
        valor as emigraciones
    from {{ source('raw_migracion', 'ine_flujos_emigracion') }}
    where valor is not null
),

poblacion as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and sexo = 'Total'
)

select
    coalesce(e.trimestre, s.trimestre) as fecha,
    cast(year(coalesce(e.trimestre, s.trimestre)) as integer) as anio,
    coalesce(e.trimestre, s.trimestre) = max(coalesce(e.trimestre, s.trimestre)) over () as es_parcial,
    coalesce(e.nacionalidad, s.nacionalidad) as nacionalidad,
    e.inmigraciones,
    s.emigraciones,
    coalesce(e.inmigraciones, 0) - coalesce(s.emigraciones, 0) as saldo,
    1000.0 * e.inmigraciones / p.poblacion as inmigraciones_1000,
    1000.0 * s.emigraciones / p.poblacion as emigraciones_1000,
    1000.0 * (coalesce(e.inmigraciones, 0) - coalesce(s.emigraciones, 0)) / p.poblacion as saldo_1000
from entradas e
full join salidas s on s.trimestre = e.trimestre and s.nacionalidad = e.nacionalidad
left join poblacion p
  on p.anio = greatest(least(cast(year(coalesce(e.trimestre, s.trimestre)) as integer), (select max(anio) from poblacion)), (select min(anio) from poblacion))
