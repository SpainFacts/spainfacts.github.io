-- Valor de la producción agraria y renta agraria: España frente a la UE-27 y los países
-- grandes, por habitante y en euros reales, desde 2000.
-- Fuentes (pipeline dlt `primario`): Eurostat, cuentas económicas de la agricultura
--   aact_eaa01: producción de la rama agraria (AM160000) y valor añadido bruto (AM260000)
--               a precios básicos, M EUR corrientes;
--   aact_eaa04: producción de la rama agraria en volumen encadenado (CLV20_MEUR, euros de 2020);
--   aact_eaa06: renta real de los factores por unidad de trabajo-año (RFI_AWU_CLV,
--               CLV20_EUR_AWU) e indicador A (índice 2020 = 100).
--   nama_10_pe: población media; nama_10_gdp: deflactor implícito del PIB (PD20_EUR).
-- Euros reales (euros de anio_base, el último año completo del IPC):
--   eur_hab_real: España con el IPC del INE (main.deflactor, como en el resto de la web);
--     los demás países y la UE con su deflactor del PIB de Eurostat (no hay IPC comparable
--     en el repo para todos). eur_hab_real_pib: todos con el deflactor del PIB (para
--     comparar países con el mismo método).
--   volumen_eur_hab: producción en volumen (CLV20) por habitante, euros de 2020; mide
--     cantidades producidas sin el efecto de los precios agrarios.
-- geo: ES, EU27_2020 y FR, DE, IT, PL, NL, PT, EL, RO.
with eaa as (
    select geo, anio,
           max(valor) filter (where dataset = 'aact_eaa01' and item = 'AM160000') as produccion_meur,
           max(valor) filter (where dataset = 'aact_eaa01' and item = 'AM260000') as vab_meur,
           max(valor) filter (where dataset = 'aact_eaa04' and item = 'AM160000') as produccion_clv20_meur,
           max(valor) filter (where dataset = 'aact_eaa06' and indicador = 'RFI_AWU_CLV') as renta_real_uta_eur2020,
           max(valor) filter (where dataset = 'aact_eaa06' and indicador = 'IND_A') as renta_indicador_a
    from {{ source('raw_primario', 'eurostat_cuentas_agricolas') }}
    where geo in ('ES', 'EU27_2020', 'FR', 'DE', 'IT', 'PL', 'NL', 'PT', 'EL', 'RO')
      and indicador in ('PRD_BP', 'RFI_AWU_CLV', 'IND_A')
    group by geo, anio
),

pob as (
    select geo, anio, valor as poblacion_miles
    from {{ source('raw_primario', 'eurostat_poblacion_paises') }}
),

defl as (
    select geo, anio, valor as deflactor_pib
    from {{ source('raw_primario', 'eurostat_deflactor_pib') }}
    where valor is not null
),

ipc as (
    select anio, factor, anio_base from {{ ref('deflactor') }}
),

base_anio as (
    select max(anio_base) as anio_base from ipc
)

select
    e.geo,
    coalesce(p.pais, e.geo) as pais,
    cast(e.anio as integer) as anio,
    e.produccion_meur,
    e.vab_meur,
    po.poblacion_miles,
    e.produccion_meur * 1000 / po.poblacion_miles as produccion_eur_hab,
    case when e.geo = 'ES' then e.produccion_meur * i.factor
         else e.produccion_meur * db.deflactor_pib / d.deflactor_pib end * 1000 / po.poblacion_miles as produccion_eur_hab_real,
    e.produccion_meur * db.deflactor_pib / d.deflactor_pib * 1000 / po.poblacion_miles as produccion_eur_hab_real_pib,
    case when e.geo = 'ES' then e.vab_meur * i.factor
         else e.vab_meur * db.deflactor_pib / d.deflactor_pib end * 1000 / po.poblacion_miles as vab_eur_hab_real,
    case when e.geo = 'ES' then e.produccion_meur * i.factor
         else e.produccion_meur * db.deflactor_pib / d.deflactor_pib end as produccion_meur_real,
    e.produccion_clv20_meur * 1000 / po.poblacion_miles as volumen_eur2020_hab,
    e.renta_real_uta_eur2020,
    e.renta_indicador_a,
    case when e.geo = 'ES' then 'IPC (INE)' else 'Deflactor del PIB (Eurostat)' end as metodo_real,
    b.anio_base
from eaa e
cross join base_anio b
left join {{ ref('primario_paises') }} p on p.geo = e.geo
left join pob po on po.geo = e.geo and po.anio = e.anio
left join defl d on d.geo = e.geo and d.anio = e.anio
left join defl db on db.geo = e.geo and db.anio = b.anio_base
left join ipc i on i.anio = e.anio
where e.anio >= 2000 and e.produccion_meur is not null
order by e.geo, e.anio
