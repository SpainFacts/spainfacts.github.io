-- Electrificación de la economía: consumo final de energía por sector y
-- combustible, y peso de la electricidad, anual desde 1990 (Eurostat nrg_bal_c,
-- uso energético, ktep). "Renovables" = biomasa, biocombustibles, solar
-- térmica, geotermia y calor ambiente de bombas de calor (la electricidad
-- renovable cuenta dentro de "electricidad").
with base as (
    select cast(anio as integer) as anio, sector, combustible, ktep
    from {{ source('raw_eurostat_extra', 'eurostat_balance_energetico') }}
    where ktep is not null
),

por_combustible as (
    select
        anio,
        sector,
        max(ktep) filter (where combustible = 'TOTAL') as total,
        max(ktep) filter (where combustible = 'E7000') as electricidad,
        max(ktep) filter (where combustible = 'G3000') as gas_natural,
        max(ktep) filter (where combustible = 'O4000XBIO') as petroleo,
        max(ktep) filter (where combustible = 'RA000') as renovables,
        max(ktep) filter (where combustible = 'RA600') as calor_ambiente,
        max(ktep) filter (where combustible = 'H8000') as calor,
        max(ktep) filter (where combustible = 'C0000X0350-0370') as carbon
    from base
    group by all
)

select
    anio,
    sector as cod_sector,
    case sector
        when 'FC_E' then 'Toda la economía'
        when 'FC_IND_E' then 'Industria'
        when 'FC_TRA_E' then 'Transporte'
        when 'FC_TRA_ROAD_E' then 'Transporte por carretera'
        when 'FC_TRA_RAIL_E' then 'Ferrocarril'
        when 'FC_OTH_HH_E' then 'Hogares'
        when 'FC_OTH_CP_E' then 'Comercio y servicios públicos'
        when 'FC_OTH_AF_E' then 'Agricultura y silvicultura'
        when 'FC_IND_IS_E' then 'Siderurgia'
        when 'FC_IND_CPC_E' then 'Química y petroquímica'
        when 'FC_IND_NFM_E' then 'Metales no férreos'
        when 'FC_IND_NMM_E' then 'Minerales no metálicos (cemento, cerámica, vidrio)'
        when 'FC_IND_TE_E' then 'Material de transporte'
        when 'FC_IND_MAC_E' then 'Maquinaria'
        when 'FC_IND_MQ_E' then 'Minería y canteras'
        when 'FC_IND_FBT_E' then 'Alimentación, bebidas y tabaco'
        when 'FC_IND_PPP_E' then 'Papel y artes gráficas'
        when 'FC_IND_WP_E' then 'Madera'
        when 'FC_IND_CON_E' then 'Construcción'
        when 'FC_IND_TL_E' then 'Textil y cuero'
        when 'FC_IND_NSP_E' then 'Otras industrias'
    end as sector,
    sector like 'FC_IND_%' and sector <> 'FC_IND_E' as es_rama_industrial,
    total,
    electricidad,
    gas_natural,
    petroleo,
    renovables,
    calor_ambiente,
    calor,
    carbon,
    electricidad / nullif(total, 0) as cuota_electricidad
from por_combustible
where total is not null
