-- Peso del sector primario (agricultura, ganadería, silvicultura y pesca, rama A de la
-- CNAE) por comunidad autónoma y provincia, desde 2000.
-- Fuente: Eurostat nama_10r_3gva (VAB a precios básicos por región NUTS 2 y NUTS 3, M EUR
-- corrientes; pipeline dlt `primario`), que reproduce la Contabilidad Regional del INE.
-- Las provincias de Baleares (Eivissa y Formentera, Mallorca, Menorca) y Canarias (islas)
-- se suman a sus provincias INE (07; 35 = Fuerteventura, Gran Canaria, Lanzarote; 38 = El
-- Hierro, La Gomera, La Palma, Tenerife). cod: '00' España, código INE de comunidad o de
-- provincia (no de Hacienda). El último año provincial suele ir un año por detrás.
-- peso_vab_pct = VAB primario / VAB total x 100.
-- vab_primario_eur_hab_real: euros por habitante (main.poblacion_territorios) en euros
-- constantes con el IPC (main.deflactor).
with nuts2 as (
    select * from (values
        ('ES', '00'),
        ('ES11', '12'), ('ES12', '03'), ('ES13', '06'), ('ES21', '16'), ('ES22', '15'),
        ('ES23', '17'), ('ES24', '02'), ('ES30', '13'), ('ES41', '07'), ('ES42', '08'),
        ('ES43', '11'), ('ES51', '09'), ('ES52', '10'), ('ES53', '04'), ('ES61', '01'),
        ('ES62', '14'), ('ES63', '18'), ('ES64', '19'), ('ES70', '05')
    ) as t(geo, cod)
),

nuts3 as (
    select * from (values
        ('ES111', '15'), ('ES112', '27'), ('ES113', '32'), ('ES114', '36'), ('ES120', '33'),
        ('ES130', '39'), ('ES211', '01'), ('ES212', '20'), ('ES213', '48'), ('ES220', '31'),
        ('ES230', '26'), ('ES241', '22'), ('ES242', '44'), ('ES243', '50'), ('ES300', '28'),
        ('ES411', '05'), ('ES412', '09'), ('ES413', '24'), ('ES414', '34'), ('ES415', '37'),
        ('ES416', '40'), ('ES417', '42'), ('ES418', '47'), ('ES419', '49'), ('ES421', '02'),
        ('ES422', '13'), ('ES423', '16'), ('ES424', '19'), ('ES425', '45'), ('ES431', '06'),
        ('ES432', '10'), ('ES511', '08'), ('ES512', '17'), ('ES513', '25'), ('ES514', '43'),
        ('ES521', '03'), ('ES522', '12'), ('ES523', '46'), ('ES531', '07'), ('ES532', '07'),
        ('ES533', '07'), ('ES611', '04'), ('ES612', '11'), ('ES613', '14'), ('ES614', '18'),
        ('ES615', '21'), ('ES616', '23'), ('ES617', '29'), ('ES618', '41'), ('ES620', '30'),
        ('ES630', '51'), ('ES640', '52'), ('ES703', '38'), ('ES704', '35'), ('ES705', '35'),
        ('ES706', '38'), ('ES707', '38'), ('ES708', '35'), ('ES709', '38')
    ) as t(geo, cod)
),

vab as (
    select geo, anio, nombre,
           max(valor) filter (where nace_r2 = 'A') as vab_a,
           max(valor) filter (where nace_r2 = 'TOTAL') as vab_total
    from {{ source('raw_primario', 'eurostat_vab_regiones') }}
    group by geo, anio, nombre
),

territorios as (
    select case when n.cod = '00' then 'pais' else 'ccaa' end as nivel, n.cod,
           v.nombre, v.anio, v.vab_a, v.vab_total
    from vab v join nuts2 n on n.geo = v.geo

    union all
    select 'provincia', n.cod,
           case n.cod when '07' then 'Illes Balears' when '35' then 'Las Palmas'
                      when '38' then 'Santa Cruz de Tenerife' else max(v.nombre) end,
           v.anio,
           -- solo si están todas las islas de la provincia
           case when count(v.vab_a) = count(*) then sum(v.vab_a) end,
           case when count(v.vab_total) = count(*) then sum(v.vab_total) end
    from vab v join nuts3 n on n.geo = v.geo
    group by n.cod, v.anio
),

pob as (
    select nivel, cod, anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total'
),

pob_rango as (
    select min(anio) as anio_min, max(anio) as anio_max from pob
)

select
    t.nivel,
    t.cod,
    t.nombre,
    cast(t.anio as integer) as anio,
    t.vab_a as vab_primario_meur,
    t.vab_total as vab_total_meur,
    round(100 * t.vab_a / t.vab_total, 2) as peso_vab_pct,
    p.poblacion,
    t.vab_a * 1e6 / p.poblacion as vab_primario_eur_hab,
    t.vab_a * d.factor * 1e6 / p.poblacion as vab_primario_eur_hab_real,
    d.anio_base
from territorios t
cross join pob_rango r
left join pob p on p.nivel = t.nivel and p.cod = t.cod
                and p.anio = greatest(least(t.anio, r.anio_max), r.anio_min)
left join {{ ref('deflactor') }} d on d.anio = t.anio
where t.vab_a is not null and t.anio >= 2000
order by t.nivel, t.cod, t.anio
