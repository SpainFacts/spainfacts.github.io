-- Consumo de carburantes por año en España, cada comunidad y cada provincia (CORES), pasado de
-- toneladas a litros con densidades medias (gasolina 0,745 kg/l; gasóleo 0,835 kg/l) y por
-- habitante. Automoción = gasolinas + gasóleo A; el gasóleo B es el agrícola y pesquero y el C,
-- el de calefacción. `meses` < 12 marca el año en curso.
with crudo as (
    select
        c.anio,
        c.mes,
        p.cod_prov,
        c.provincia,
        c.ccaa,
        coalesce(c.gasolina_95_t, 0) + coalesce(c.gasolina_98_t, 0) + coalesce(c.gasolina_97_t, 0) as gasolina_t,
        coalesce(c.gasoleo_a_t, 0) as gasoleo_a_t,
        coalesce(c.gasoleo_b_t, 0) as gasoleo_b_t,
        coalesce(c.gasoleo_c_t, 0) as gasoleo_c_t
    from {{ source('raw_carburantes', 'carburantes_consumo_provincia') }} c
    left join {{ ref('carburantes_provincias_cores') }} p on p.provincia_cores = c.provincia
),

filas as (
    -- España: fila 'Total Nacional'; provincias: las que casan con el seed
    select anio, mes, 'pais' as nivel, '00' as cod, gasolina_t, gasoleo_a_t, gasoleo_b_t, gasoleo_c_t
    from crudo where ccaa = 'Total Nacional'
    union all
    select anio, mes, 'provincia', cod_prov, gasolina_t, gasoleo_a_t, gasoleo_b_t, gasoleo_c_t
    from crudo where cod_prov is not null
    union all
    select c.anio, c.mes, 'ccaa', t.cod_ccaa, sum(c.gasolina_t), sum(c.gasoleo_a_t), sum(c.gasoleo_b_t), sum(c.gasoleo_c_t)
    from crudo c
    join {{ ref('territorios_provincias') }} t on t.cod_prov = c.cod_prov
    group by c.anio, c.mes, t.cod_ccaa
),

anual as (
    select
        anio,
        nivel,
        cod,
        count(distinct mes) as meses,
        sum(gasolina_t) * 1000 / 0.745 as gasolina_litros,
        sum(gasoleo_a_t) * 1000 / 0.835 as gasoleo_a_litros,
        sum(gasoleo_b_t) * 1000 / 0.835 as gasoleo_b_litros,
        sum(gasoleo_c_t) * 1000 / 0.835 as gasoleo_c_litros
    from filas
    group by anio, nivel, cod
),

poblacion as (
    select anio, nivel, cod, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total'
),

-- Canarias: hasta que CORES separa Las Palmas y Santa Cruz de Tenerife solo da la comunidad,
-- así que la suma de provincias de esos años no cuadra: fuera las filas de comunidad incompletas
provincias_por_ccaa as (
    select t.cod_ccaa, count(*) as n from {{ ref('territorios_provincias') }} t group by 1
),

completas as (
    select a.*
    from anual a
    where a.nivel <> 'ccaa'
       or (select count(distinct f.cod) from filas f join {{ ref('territorios_provincias') }} t on t.cod_prov = f.cod
           where f.nivel = 'provincia' and f.anio = a.anio and t.cod_ccaa = a.cod)
          = (select n from provincias_por_ccaa where cod_ccaa = a.cod)
)

select
    a.anio,
    a.meses,
    a.nivel,
    a.cod,
    coalesce(t.nombre, case when a.nivel = 'pais' then 'España' end) as nombre,
    a.gasolina_litros,
    a.gasoleo_a_litros,
    a.gasoleo_b_litros,
    a.gasoleo_c_litros,
    a.gasolina_litros + a.gasoleo_a_litros as automocion_litros,
    100.0 * a.gasoleo_a_litros / nullif(a.gasolina_litros + a.gasoleo_a_litros, 0) as gasoleo_pct_automocion,
    (a.gasolina_litros + a.gasoleo_a_litros) / nullif(h.poblacion, 0) as litros_automocion_hab,
    a.gasolina_litros / nullif(h.poblacion, 0) as litros_gasolina_hab,
    a.gasoleo_a_litros / nullif(h.poblacion, 0) as litros_gasoleo_a_hab,
    h.poblacion
from completas a
left join {{ ref('territorios') }} t on t.nivel = a.nivel and t.cod = a.cod
left join poblacion h on h.anio = a.anio and h.nivel = a.nivel and h.cod = a.cod
