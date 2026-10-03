-- Producción y superficie de los cultivos herbáceos por comunidad autónoma, desde 2000:
-- cereales, cebada, maíz, arroz, girasol y patata.
-- Fuente: Eurostat apro_cpshr (producción cosechada en miles de t a humedad UE y
-- superficie en miles de ha, regiones NUTS 2; pipeline dlt `primario`). Trampa: Eurostat
-- solo da por región los cultivos herbáceos; olivar, viñedo, cítricos, frutales y
-- hortalizas solo vienen para el total de España (para comunidades habría que usar el
-- Anuario o ESYRCE del MAPA).
-- cod: código INE de la comunidad. cuota_espana_pct = comunidad / suma de las comunidades.
-- kg_hab: producción por habitante (main.poblacion_territorios); ha_1000hab: superficie por
-- 1.000 habitantes.
with nuts2 as (
    select * from (values
        ('ES11', '12', 'Galicia'), ('ES12', '03', 'Asturias'), ('ES13', '06', 'Cantabria'),
        ('ES21', '16', 'País Vasco'), ('ES22', '15', 'Navarra'), ('ES23', '17', 'La Rioja'),
        ('ES24', '02', 'Aragón'), ('ES30', '13', 'Madrid'), ('ES41', '07', 'Castilla y León'),
        ('ES42', '08', 'Castilla-La Mancha'), ('ES43', '11', 'Extremadura'), ('ES51', '09', 'Cataluña'),
        ('ES52', '10', 'Comunitat Valenciana'), ('ES53', '04', 'Illes Balears'), ('ES61', '01', 'Andalucía'),
        ('ES62', '14', 'Región de Murcia'), ('ES63', '18', 'Ceuta'), ('ES64', '19', 'Melilla'),
        ('ES70', '05', 'Canarias')
    ) as t(geo, cod, ccaa)
),

productos as (
    select * from (values
        ('C0000', 'Cereales'), ('C1300', 'Cebada'), ('C1500', 'Maíz en grano'),
        ('C2000', 'Arroz'), ('I1120', 'Girasol'), ('R1000', 'Patata')
    ) as t(crops, producto)
),

datos as (
    select n.cod, n.ccaa, c.crops, p.producto, cast(c.anio as integer) as anio,
           max(c.valor) filter (where c.strucpro = 'HPRD_HUMD_EU_THS_T') as produccion_miles_t,
           max(c.valor) filter (where c.strucpro = 'AR_THS_HA') as superficie_miles_ha
    from {{ source('raw_primario', 'eurostat_cultivos_regiones') }} c
    join nuts2 n on n.geo = c.geo
    join productos p on p.crops = c.crops
    group by all
),

pob as (
    select cod, anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total' and nivel = 'ccaa'
),

pob_rango as (
    select min(anio) as anio_min, max(anio) as anio_max from pob
)

select
    d.cod,
    d.ccaa,
    d.crops as producto_id,
    d.producto,
    d.anio,
    d.produccion_miles_t,
    d.superficie_miles_ha,
    round(100 * d.produccion_miles_t / sum(d.produccion_miles_t) over (partition by d.crops, d.anio), 2) as cuota_espana_pct,
    d.produccion_miles_t * 1e6 / p.poblacion as kg_hab,
    d.superficie_miles_ha * 1e6 / p.poblacion as ha_1000hab,
    p.poblacion
from datos d
cross join pob_rango r
left join pob p on p.cod = d.cod and p.anio = greatest(least(d.anio, r.anio_max), r.anio_min)
where d.anio >= 2000 and (d.produccion_miles_t is not null or d.superficie_miles_ha is not null)
order by d.crops, d.anio, d.cod
