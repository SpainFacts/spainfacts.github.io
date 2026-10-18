-- Todas las series internacionales en formato largo (ambito, indicador_id, cod_pais ISO3,
-- anio, valor), con la fuente de cada fila. ambito: 'mundo' (Banco Mundial, FMI, Our World
-- in Data y OCDE, todos los países que traen) o 'europa' (Eurostat, países europeos y
-- UE-27): un mismo indicador_id puede estar en los dos con fuentes distintas (paro del
-- Banco Mundial y de Eurostat). Del FMI solo años cerrados (el WEO publica previsiones
-- hasta cinco años vista). Eurostat trae su código geo (EL = Grecia) y aquí se pasa a ISO3
-- con el seed paises_iso; las series semestrales se promedian en los años con los dos
-- semestres. Cálculos: turistas por habitante (ONU Turismo y población del Banco Mundial),
-- peso de la electricidad en el consumo final de energía, pernoctaciones y pasajeros de
-- avión por habitante, km de autopista por 100.000 habitantes y % de nacidos en otro país
-- (Eurostat).
with bm as (
    select indicador_id, cod_indicador, cod_pais, cast(anio as integer) as anio, valor, 'bm' as origen
    from {{ source('raw_internacional', 'internacional_banco_mundial') }}
),

fmi as (
    select indicador_id, cod_indicador, cod_pais, cast(anio as integer) as anio, valor, 'fmi' as origen
    from {{ source('raw_internacional', 'internacional_fmi') }}
    where anio < extract(year from current_date)
),

owid as (
    select indicador_id, cod_indicador, cod_pais, cast(anio as integer) as anio, valor, 'owid' as origen
    from {{ source('raw_internacional', 'internacional_owid') }}
),

eurostat_bruto as (
    select e.indicador_id, e.cod_indicador, p.iso3 as cod_pais, cast(e.anio as integer) as anio,
           e.periodo, e.valor
    from {{ source('raw_internacional', 'internacional_eurostat') }} e
    join {{ ref('paises_iso') }} p on p.eurostat = e.geo
),

-- anuales tal cual; semestrales (2024-S1, 2024-S2), media de los años completos
eurostat as (
    select indicador_id, cod_indicador, cod_pais, anio, avg(valor) as valor, 'eurostat' as origen
    from eurostat_bruto
    group by all
    having count(*) = 1 and not bool_or(periodo like '%-S%') or count(*) = 2
),

ocde_vivienda as (
    select indicador_id, cod_indicador, cod_pais, cast(anio as integer) as anio, valor, 'ocde' as origen
    from {{ source('raw_internacional', 'internacional_ocde_vivienda') }}
),

-- peso de la electricidad en el consumo final de energía (uso energético), en %
electrificacion as (
    select 'electrificacion' as indicador_id, 'nrg_bal_c (FC_E, E7000 / TOTAL)' as cod_indicador,
           e.cod_pais, e.anio, 100 * e.valor / t.valor as valor, 'eurostat' as origen
    from eurostat e
    join eurostat t on t.indicador_id = 'consumo_final_energia' and t.cod_pais = e.cod_pais and t.anio = e.anio
    where e.indicador_id = 'consumo_final_electricidad' and t.valor > 0
),

-- lo mismo solo en el transporte
electrificacion_transporte as (
    select 'electrificacion_transporte' as indicador_id, 'nrg_bal_c (FC_TRA_E, E7000 / TOTAL)' as cod_indicador,
           e.cod_pais, e.anio, 100 * e.valor / t.valor as valor, 'eurostat' as origen
    from eurostat e
    join eurostat t on t.indicador_id = 'consumo_transporte_energia_aux' and t.cod_pais = e.cod_pais and t.anio = e.anio
    where e.indicador_id = 'consumo_transporte_electricidad_aux' and t.valor > 0
),

pernoctaciones as (
    select 'pernoctaciones_hab' as indicador_id, 'tin00175 / demo_gind (AVG)' as cod_indicador,
           n.cod_pais, n.anio, n.valor / p.valor as valor, 'eurostat' as origen
    from eurostat n
    join eurostat p on p.indicador_id = 'poblacion_media_aux' and p.cod_pais = n.cod_pais and p.anio = n.anio
    where n.indicador_id = 'pernoctaciones_aux' and p.valor > 0
),

pasajeros_avion as (
    select 'pasajeros_avion_hab' as indicador_id, 'ttr00012 / demo_gind (AVG)' as cod_indicador,
           n.cod_pais, n.anio, n.valor / p.valor as valor, 'eurostat' as origen
    from eurostat n
    join eurostat p on p.indicador_id = 'poblacion_media_aux' and p.cod_pais = n.cod_pais and p.anio = n.anio
    where n.indicador_id = 'pasajeros_avion_aux' and p.valor > 0
),

autopistas as (
    select 'autopistas_100k' as indicador_id, 'road_if_motorwa / demo_gind (AVG)' as cod_indicador,
           n.cod_pais, n.anio, 100000 * n.valor / p.valor as valor, 'eurostat' as origen
    from eurostat n
    join eurostat p on p.indicador_id = 'poblacion_media_aux' and p.cod_pais = n.cod_pais and p.anio = n.anio
    where n.indicador_id = 'autopistas_km_aux' and p.valor > 0
),

nacidos_extranjero as (
    select 'nacidos_extranjero' as indicador_id, 'migr_pop3ctb (FOR / TOTAL)' as cod_indicador,
           f.cod_pais, f.anio, 100 * f.valor / t.valor as valor, 'eurostat' as origen
    from eurostat f
    join eurostat t on t.indicador_id = 'nacidos_total_aux' and t.cod_pais = f.cod_pais and t.anio = f.anio
    where f.indicador_id = 'nacidos_fuera_aux' and t.valor > 0
),

turistas as (
    select 'turistas_por_habitante' as indicador_id, t.cod_indicador, t.cod_pais, t.anio,
           t.valor / p.valor as valor, 'owid' as origen
    from owid t
    join bm p on p.indicador_id = 'poblacion' and p.cod_pais = t.cod_pais and p.anio = t.anio
    where t.indicador_id = 'turistas_llegadas'
),

todas as (
    select * from bm
    union all select * from fmi
    union all select * from owid where indicador_id <> 'turistas_llegadas'
    union all select * from ocde_vivienda
    union all select * from turistas
    union all select * from eurostat
    where indicador_id not in ('consumo_final_energia', 'consumo_final_electricidad')
      and not ends_with(indicador_id, '_aux')
    union all select * from electrificacion
    union all select * from electrificacion_transporte
    union all select * from pernoctaciones
    union all select * from pasajeros_avion
    union all select * from autopistas
    union all select * from nacidos_extranjero
)

select
    case when origen = 'eurostat' then 'europa' else 'mundo' end as ambito,
    *
from todas
