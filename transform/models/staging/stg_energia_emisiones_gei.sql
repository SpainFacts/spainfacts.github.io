-- Serie desde 1990: lee raw.eurostat_clima_gei (ingestion/clima.py), que es la misma
-- consulta a env_air_gge que raw.eurostat_gei (ingestion/emisiones.py) pero sin el corte en 2015.
-- Emisiones GEI de España (Eurostat env_air_gge, inventario nacional reportado a la
-- CMNUCC) agrupadas en los sectores divulgativos de la web. Sin LULUCF (CRF4) ni
-- partidas "memo" (búnkeres internacionales, CO2 de biomasa): la suma de sectores
-- es igual al total TOTX4_MEMO ("Total excluding LULUCF and memo items").
--
-- Mapeo CRF -> sector:
--   Generación Eléctrica     = 1A1A  (producción pública de electricidad y calor)
--   Transporte               = 1A3   (transporte nacional: carretera, aviación y navegación
--                                     domésticas, ferrocarril; sin búnkeres internacionales)
--   Industria y Procesos     = 1A1B + 1A1C (refino y otras industrias energéticas)
--                              + 1A2 (combustión en industria y construcción)
--                              + 1B  (emisiones fugitivas de combustibles)
--                              + 2 - 2F - 2G (procesos industriales sin gases fluorados)
--   Residencial y Comercial  = 1A4A + 1A4B (comercial/institucional y hogares)
--   Agricultura y Ganadería  = 3 (agricultura) + 1A4C (combustión en agricultura,
--                              silvicultura y pesca)
--   Residuos                 = 5
--   Gases Fluorados y Otros  = 2F (sustitutos de SAO: gases fluorados) + 2G (otros productos)
--                              + 1A5 (otra combustión n.c.o.p.) + 6 (otros) + INDCO2 (CO2 indirecto)
with crf as (
    select anio, src_crf, coalesce(mt_co2eq, 0) as mt
    from {{ source('raw_clima', 'eurostat_clima_gei') }}
),

mapeo as (
    select * from (values
        ('CRF1A1A', 'Generación Eléctrica', 1),
        ('CRF1A3', 'Transporte', 1),
        ('CRF1A1B', 'Industria y Procesos', 1),
        ('CRF1A1C', 'Industria y Procesos', 1),
        ('CRF1A2', 'Industria y Procesos', 1),
        ('CRF1B', 'Industria y Procesos', 1),
        ('CRF2', 'Industria y Procesos', 1),
        ('CRF2F', 'Industria y Procesos', -1),
        ('CRF2G', 'Industria y Procesos', -1),
        ('CRF1A4A', 'Residencial y Comercial', 1),
        ('CRF1A4B', 'Residencial y Comercial', 1),
        ('CRF3', 'Agricultura y Ganadería', 1),
        ('CRF1A4C', 'Agricultura y Ganadería', 1),
        ('CRF5', 'Residuos', 1),
        ('CRF2F', 'Gases Fluorados y Otros', 1),
        ('CRF2G', 'Gases Fluorados y Otros', 1),
        ('CRF1A5', 'Gases Fluorados y Otros', 1),
        ('CRF6', 'Gases Fluorados y Otros', 1),
        ('CRF_INDCO2', 'Gases Fluorados y Otros', 1)
    ) as t (src_crf, sector, signo)
),

total as (
    select anio, mt as total_mt
    from crf
    where src_crf = 'TOTX4_MEMO' and mt > 0
)

select
    c.anio,
    m.sector,
    sum(c.mt * m.signo) as mt_co2eq,
    any_value(t.total_mt) as total_inventario_mt
from crf as c
inner join mapeo as m on m.src_crf = c.src_crf
inner join total as t on t.anio = c.anio
group by c.anio, m.sector
