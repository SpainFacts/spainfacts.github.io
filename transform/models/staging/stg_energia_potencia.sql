-- Potencia instalada anual (MW) por tecnología, normalizada a las etiquetas de la web.
-- La fila de total se conserva (tecnologia = 'TOTAL') para calcular "Otras Tecnologías"
-- y los porcentajes. Las tecnologías no mapeadas quedan con tecnologia = null.
--   fuente = 'ree'                  -> etiquetas REE (title del widget potencia-instalada)
--   fuente = 'eurostat_nrg_inf_epc' -> códigos SIEC de Eurostat (id_serie). En Eurostat
--       el gas natural agrupa ciclos combinados y cogeneración, y la solar FV incluye
--       autoconsumo, por lo que las cifras difieren algo de las de REE.
with base as (
    select anio, fuente, id_serie, tecnologia, valor as potencia_mw
    from {{ source('raw_energia', 'ree_potencia_instalada') }}
    where valor is not null and not coalesce(provisional, false)
)
select
    anio,
    fuente,
    case
        when fuente = 'ree' then case tecnologia
            when 'Eólica' then 'Eólica'
            when 'Solar fotovoltaica' then 'Solar Fotovoltaica'
            when 'Solar térmica' then 'Solar Térmica'
            when 'Hidráulica' then 'Hidráulica'
            when 'Nuclear' then 'Nuclear'
            when 'Carbón' then 'Carbón'
            when 'Ciclo combinado' then 'Ciclos Combinados (Gas)'
            when 'Potencia total' then 'TOTAL'
        end
        else case id_serie
            when 'RA300' then 'Eólica'
            when 'RA420' then 'Solar Fotovoltaica'
            when 'RA410' then 'Solar Térmica'
            when 'RA100' then 'Hidráulica'
            when 'N9000' then 'Nuclear'
            when 'C0000' then 'Carbón'
            when 'G3000' then 'Gas Natural (Ciclos y Cogeneración)'
            when 'TOTAL' then 'TOTAL'
        end
    end as tecnologia,
    potencia_mw
from base
