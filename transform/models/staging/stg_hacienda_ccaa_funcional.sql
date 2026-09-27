-- Una fila por (año, comunidad INE, clasificación, nivel, código) con las
-- obligaciones reconocidas brutas y depuradas de IFL y PAC, en euros.
select
    f.anio::integer as anio,
    m.cod_ccaa,
    f.clasificacion,
    f.nivel,
    f.codigo,
    f.cod_area,
    any_value(trim(f.nombre)) as nombre,
    sum(case when f.medida = 'obligaciones_depuradas' then f.importe_miles end) * 1000 as obligaciones_depuradas,
    sum(case when f.medida = 'obligaciones_brutas' then f.importe_miles end) * 1000 as obligaciones_brutas
from {{ source('raw_hacienda_ccaa', 'hacienda_ccaa_funcional') }} as f
join {{ ref('ccaa_codigos_hacienda') }} as m
  on m.cod_ccaa_hacienda = f.cod_ccaa_hacienda
group by f.anio, m.cod_ccaa, f.clasificacion, f.nivel, f.codigo, f.cod_area
