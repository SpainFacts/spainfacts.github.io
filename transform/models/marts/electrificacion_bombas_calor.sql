-- Potencia térmica instalada de bombas de calor por tecnología, anual (Eurostat
-- nrg_inf_hptc, MW). Ojo: "aerotérmica aire-aire reversible" son sobre todo
-- los aparatos de aire acondicionado split que también calientan; Eurostat los
-- cuenta como bombas de calor aunque muchos se usen sobre todo para refrigerar.
select
    cast(anio as integer) as anio,
    tecnologia as cod_tecnologia,
    case tecnologia
        when 'ATH_RAA' then 'Aire-aire reversible (splits de aire acondicionado)'
        when 'ATH_AA' then 'Aire-aire'
        when 'ATH_RAW' then 'Aire-agua reversible (aerotermia)'
        when 'ATH_AW' then 'Aire-agua (aerotermia)'
        when 'ATH_EAA' then 'Aire extraído-aire'
        when 'ATH_EAW' then 'Aire extraído-agua'
        when 'GTH' then 'Geotérmica'
        when 'HTH' then 'Hidrotérmica'
    end as tecnologia,
    valor as mw
from {{ source('raw_eurostat_extra', 'eurostat_bombas_calor') }}
where unidad = 'MW'
  and tecnologia in ('ATH_RAA', 'ATH_AA', 'ATH_RAW', 'ATH_AW', 'ATH_EAA', 'ATH_EAW', 'GTH', 'HTH')
  and valor is not null
  and valor > 0
