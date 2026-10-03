-- Dónde es potencia España en la UE: una fila por producto (cultivo, ganadería, pesca,
-- valor de la producción agraria y exportación) con la cuota de España sobre los 27 y su
-- puesto, en el último año con datos casi completos.
-- Base: primario_paises_largo (Eurostat apro_cpsh1, apro_mt_*, apro_mk_cola, fish_*,
-- aact_eaa01 y Comext DS-045409).
-- Año elegido: el más reciente (de los últimos 8) en el que España tiene dato y la
-- cobertura es >= 97 %. cobertura = total de los países con dato ese año / (ese total + el
-- último dato conocido, desde 2010, de los países que no lo publican ese año), y sin caída
-- brusca del número de países frente al año anterior (descarta las primeras estimaciones
-- del año en curso). Si ningún año llega al 97 % (capturas: Irlanda y Portugal
-- no publican), el más reciente cuya cobertura no cae más de 2 puntos frente al año
-- anterior; en ese caso cuota_min_pct es la cifra prudente.
-- total_ue = suma de los países con dato (no el agregado EU27_2020, que Eurostat no da para
-- todos los productos). cuota_pct = España / total_ue x 100. cuota_min_pct: la misma cuota
-- sumando al total el último dato conocido de los ausentes (cota prudente).
-- cuota_poblacion_pct = población de España / población de la UE-27 (Eurostat nama_10_pe);
-- veces_peso_poblacion = cuota_pct / cuota_poblacion_pct (índice de especialización: 1 = lo
-- que le tocaría por población). valor_hab_*: por habitante en la unidad de unidad_hab (los
-- euros son corrientes del año del dato; las cuotas no dependen de la inflación).
-- pais_primero / pais_segundo: los dos primeros países (si España es la 1.ª, pais_segundo
-- es su perseguidor). nota: advertencias del producto y países sin dato.
with base as (
    select * from {{ ref('primario_paises_largo') }}
),

productos as (
    select distinct categoria, producto_id, producto, unidad, nota from base
),

paises_producto as (
    select distinct producto_id, geo from base where anio >= 2010
),

anios as (
    select producto_id, cast(unnest(range(2010, max(anio) + 1)) as integer) as anio
    from base group by producto_id
),

rejilla as (
    select a.producto_id, a.anio, pp.geo, b.valor,
           last_value(b.valor ignore nulls) over (
               partition by a.producto_id, pp.geo order by a.anio
               rows between unbounded preceding and current row) as valor_conocido
    from anios a
    join paises_producto pp on pp.producto_id = a.producto_id
    left join base b on b.producto_id = a.producto_id and b.geo = pp.geo and b.anio = a.anio
),

por_anio as (
    select producto_id, anio,
           count(valor) as n_paises,
           sum(valor) as total_ue,
           sum(case when valor is null then valor_conocido end) as ausentes_estimado,
           max(case when geo = 'ES' then valor end) as valor_espana,
           string_agg(case when valor is null and valor_conocido is not null then geo end, ', ' order by geo) as sin_dato
    from rejilla
    group by producto_id, anio
),

candidatos as (
    select *,
           total_ue / (total_ue + coalesce(ausentes_estimado, 0)) as cobertura,
           max(anio) over (partition by producto_id) as anio_max
    from por_anio
    where valor_espana is not null and total_ue > 0
),

ventana as (
    select *,
           lag(n_paises) over (partition by producto_id order by anio) as n_anterior,
           lag(cobertura) over (partition by producto_id order by anio) as cobertura_anterior
    from candidatos
    where anio >= anio_max - 8
),

elegido as (
    -- años sin caída brusca de países frente al año anterior (< 85 %) y, entre ellos, el
    -- más reciente con cobertura >= 97 % o, si no hay, el más reciente cuya cobertura
    -- no cae más de 2 puntos frente al año anterior (descarta años con un país grande nuevo
    -- sin dato)
    select * from ventana
    where n_anterior is null or n_paises >= 0.85 * n_anterior
    qualify row_number() over (
        partition by producto_id
        order by (cobertura >= 0.97) desc,
                 (cobertura_anterior is null or cobertura >= cobertura_anterior - 0.02) desc,
                 anio desc) = 1
),

ordenado as (
    select b.producto_id, b.geo, b.pais, b.valor, b.poblacion_miles,
           rank() over (partition by b.producto_id order by b.valor desc) as puesto
    from base b
    join elegido e on e.producto_id = b.producto_id and e.anio = b.anio
),

pob_ue as (
    select anio, valor as poblacion_ue_miles
    from {{ source('raw_primario', 'eurostat_poblacion_paises') }}
    where geo = 'EU27_2020' and valor is not null
),

ausente_mayor as (
    -- países sin dato cuyo último valor conocido supera al de España
    select r.producto_id, string_agg(r.geo, ', ' order by r.geo) as ausentes_por_encima
    from rejilla r
    join elegido e on e.producto_id = r.producto_id and e.anio = r.anio
    where r.valor is null and r.valor_conocido > e.valor_espana
    group by r.producto_id
)

select
    p.categoria,
    p.producto_id,
    p.producto,
    p.unidad,
    e.anio,
    e.valor_espana,
    e.total_ue,
    round(100 * e.valor_espana / e.total_ue, 2) as cuota_pct,
    round(100 * e.valor_espana / (e.total_ue + coalesce(e.ausentes_estimado, 0)), 2) as cuota_min_pct,
    cast(es.puesto as integer) as puesto,
    cast(e.n_paises as integer) as n_paises,
    p1.pais as pais_primero,
    p1.valor as valor_primero,
    p2.pais as pais_segundo,
    p2.valor as valor_segundo,
    round(100 * es.poblacion_miles / pu.poblacion_ue_miles, 2) as cuota_poblacion_pct,
    round((e.valor_espana / e.total_ue) / (es.poblacion_miles / pu.poblacion_ue_miles), 2) as veces_peso_poblacion,
    case when p.unidad = 'buques' then e.valor_espana / es.poblacion_miles * 100
         else e.valor_espana * 1000 / es.poblacion_miles end as valor_hab_espana,
    case when p.unidad = 'buques' then e.total_ue / pu.poblacion_ue_miles * 100
         else e.total_ue * 1000 / pu.poblacion_ue_miles end as valor_hab_ue,
    case p.unidad
        when 'miles de t' then 'kg por habitante'
        when 'miles de ha' then 'ha por 1.000 habitantes'
        when 'miles de cabezas' then 'cabezas por 1.000 habitantes'
        when 'M EUR' then 'euros corrientes por habitante'
        when 'miles de GT' then 'GT por 1.000 habitantes'
        when 'buques' then 'buques por 100.000 habitantes'
    end as unidad_hab,
    round(100 * e.cobertura, 1) as cobertura_pct,
    e.sin_dato as paises_sin_dato,
    concat_ws(' ',
        p.nota,
        case when e.sin_dato is not null then 'Sin dato ese año: ' || e.sin_dato || '.' end,
        case when am.ausentes_por_encima is not null
             then 'Con su último dato conocido superaban a España: ' || am.ausentes_por_encima || '.' end
    ) as nota
from elegido e
join productos p on p.producto_id = e.producto_id
join ordenado es on es.producto_id = e.producto_id and es.geo = 'ES'
left join ordenado p1 on p1.producto_id = e.producto_id and p1.puesto = 1
left join ordenado p2 on p2.producto_id = e.producto_id and p2.puesto = 2
left join pob_ue pu on pu.anio = (select max(x.anio) from pob_ue x where x.anio <= e.anio)
left join ausente_mayor am on am.producto_id = e.producto_id
qualify row_number() over (partition by p.producto_id order by p1.pais, p2.pais) = 1
order by p.categoria, cuota_pct desc
