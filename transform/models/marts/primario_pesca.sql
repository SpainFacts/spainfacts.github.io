-- Pesca y acuicultura en los países de la UE, por año desde 2000: capturas, acuicultura
-- (volumen y valor) y flota (arqueo y número de buques), con la cuota y el puesto de cada
-- país sobre los que publican ese año.
-- Fuente: Eurostat fish_ca_main (capturas en peso vivo, todas las zonas de pesca),
-- fish_aq2a (acuicultura, t de peso vivo y euros) y fish_fleet_alt (flota a 31 de
-- diciembre), vía primario_paises_largo (pipeline dlt `primario`).
-- medida: capturas, acuicultura_t (miles de t), acuicultura_eur (M EUR corrientes),
-- flota_gt (miles de GT), flota_nr (buques). Los países sin costa no aparecen.
-- Trampa: Irlanda no publica capturas desde 2018 y Portugal desde 2022 (y el último año
-- llega incompleto): cuota_pct es sobre los países con dato y cuota_min_pct suma al total
-- el último dato conocido de los ausentes (desde 2010).
-- valor_hab / unidad_hab: por habitante (kg por habitante en capturas y acuicultura en
-- volumen, euros por habitante, GT por 1.000 hab., buques por 100.000 hab.); valor_real y
-- valor_hab_real: acuicultura en euros constantes de anio_base con el IPCA de cada país
-- (deflactor_paises). cod_pais: ISO (GR para Grecia).
with base as (
    select producto_id as medida, producto, unidad, cod_pais, pais, anio, valor, poblacion_miles,
           valor_hab, unidad_hab, valor_real, valor_hab_real, anio_base
    from {{ ref('primario_paises_largo') }}
    where categoria = 'pesca' and anio >= 2000
),

paises as (
    select distinct medida, cod_pais from base where anio >= 2010
),

rejilla as (
    select a.medida, a.anio, p.cod_pais, b.valor,
           last_value(b.valor ignore nulls) over (
               partition by a.medida, p.cod_pais order by a.anio
               rows between unbounded preceding and current row) as valor_conocido
    from (select distinct medida, anio from base) a
    join paises p on p.medida = a.medida
    left join base b on b.medida = a.medida and b.cod_pais = p.cod_pais and b.anio = a.anio
),

ausentes as (
    select medida, anio,
           sum(case when valor is null then valor_conocido end) as ausentes_estimado,
           string_agg(case when valor is null and valor_conocido is not null then cod_pais end, ', ' order by cod_pais) as paises_sin_dato
    from rejilla group by medida, anio
),

ranking as (
    select b.*,
           sum(b.valor) over (partition by b.medida, b.anio) as total_ue,
           count(*) over (partition by b.medida, b.anio) as n_paises,
           rank() over (partition by b.medida, b.anio order by b.valor desc) as puesto
    from base b
)

select
    r.medida,
    r.producto,
    r.unidad,
    r.cod_pais,
    r.pais,
    r.anio,
    r.valor,
    r.total_ue,
    round(100 * r.valor / nullif(r.total_ue, 0), 2) as cuota_pct,
    round(100 * r.valor / nullif(r.total_ue + coalesce(a.ausentes_estimado, 0), 0), 2) as cuota_min_pct,
    cast(r.puesto as integer) as puesto,
    cast(r.n_paises as integer) as n_paises,
    a.paises_sin_dato,
    r.valor_hab,
    r.unidad_hab,
    r.valor_real,
    r.valor_hab_real,
    r.anio_base
from ranking r
left join ausentes a on a.medida = r.medida and a.anio = r.anio
order by r.medida, r.anio, r.puesto
