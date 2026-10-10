-- Personas con seguro médico privado por comunidad según el Barómetro Sanitario (Ministerio de
-- Sanidad y CIS), tal como lo recoge la Tabla 1 del «Informe: Evaluación de la sanidad privada en
-- el sistema sanitario de España» del Ministerio de Sanidad (9-12-2025), años 2018, 2019, 2023 y
-- 2024 (seed sanidad_privada_barometro_seguros, copiado de la tabla del PDF; '-' = vacío).
--   seguro_individual_pct  contratado por la persona o su familia (también vía colegios)
--   seguro_empresa_pct     contratado por la empresa
--   seguro_privado_pct     suma de los dos (el informe da, p. ej., Madrid 44,6 % en 2024)
-- Es una encuesta de opinión (población de 18 y más años): cifras más altas que las de las
-- encuestas de salud del INE (sanidad_privada_seguros); no mezclar las dos series.
select
    lpad(cast(s.cod_ccaa as varchar), 2, '0') as cod_ccaa,
    case when lpad(cast(s.cod_ccaa as varchar), 2, '0') = '00' then 'España' else t.nombre end as ccaa,
    cast(s.anio as integer) as anio,
    cast(s.seguro_individual_pct as double) as seguro_individual_pct,
    cast(s.seguro_empresa_pct as double) as seguro_empresa_pct,
    coalesce(cast(s.seguro_individual_pct as double), 0) + coalesce(cast(s.seguro_empresa_pct as double), 0)
        as seguro_privado_pct,
    s.fuente_url
from {{ ref('sanidad_privada_barometro_seguros') }} s
left join {{ ref('territorios') }} t
    on t.nivel = 'ccaa' and t.cod = lpad(cast(s.cod_ccaa as varchar), 2, '0')
