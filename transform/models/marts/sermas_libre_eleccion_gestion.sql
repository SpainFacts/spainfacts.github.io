-- Libre elección de hospital por tipo de gestión del hospital y año: suma de las entradas,
-- salidas y saldo (entradas - salidas) de los hospitales de cada tipo (mart
-- sermas_libre_eleccion). gestion_privada = concesión + concierto singular (los cinco hospitales
-- de Quirónsalud y Ribera). saldo_por_1000_hab: saldo neto por cada 1.000 habitantes de la
-- Comunidad de Madrid (INE). entradas_pct_total: % de todas las citas de libre elección del año
-- (de la especialidad) que entran en hospitales de ese tipo. Especialidad 'Total' 2014-2024; el
-- resto, 2021-2024 (memorias de los hospitales).
with le as (
    select * from {{ ref('sermas_libre_eleccion') }}
),

tot as (
    select anio, especialidad, sum(entradas) as entradas_todas
    from le
    group by all
),

pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and cod = '13' and sexo = 'Total'
)

select
    '13' as cod_ccaa,
    'Comunidad de Madrid' as ccaa,
    le.anio,
    le.especialidad,
    le.gestion,
    bool_and(le.gestion_privada) as gestion_privada,
    count(*) as hospitales,
    cast(sum(le.entradas) as integer) as entradas,
    cast(sum(le.salidas) as integer) as salidas,
    cast(sum(le.saldo) as integer) as saldo,
    cast(sum(le.primeras_consultas) as integer) as primeras_consultas,
    round(100.0 * sum(le.entradas) / nullif(max(t.entradas_todas), 0), 2) as entradas_pct_total,
    round(1000.0 * sum(le.saldo) / max(p.poblacion), 3) as saldo_por_1000_hab,
    round(1000.0 * sum(le.entradas) / max(p.poblacion), 3) as entradas_por_1000_hab,
    cast(max(p.poblacion) as integer) as poblacion
from le
join tot t on t.anio = le.anio and t.especialidad = le.especialidad
left join pob p on p.anio = le.anio
group by 1, 2, le.anio, le.especialidad, le.gestion
order by le.anio, le.especialidad, le.gestion
