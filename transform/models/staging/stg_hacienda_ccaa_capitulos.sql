-- Una fila por (año, comunidad INE, ingreso/gasto, capítulo) con las cuatro
-- medidas de la liquidación consolidada, ya en euros (el fichero viene en miles).
-- El total de comunidades (código 00 de Hacienda) se descarta al no tener
-- traducción en la semilla.
select
    c.anio::integer as anio,
    m.cod_ccaa,
    case c.tipo when 'I' then 'ingreso' else 'gasto' end as tipo,
    c.capitulo::integer as capitulo,
    sum(case when c.medida = 'presupuesto_inicial' then c.importe_miles end) * 1000 as presupuesto_inicial,
    sum(case when c.medida = 'presupuesto_definitivo' then c.importe_miles end) * 1000 as presupuesto_definitivo,
    sum(case when c.medida = 'ejecutado' then c.importe_miles end) * 1000 as ejecutado,
    sum(case when c.medida = 'cobrado_pagado' then c.importe_miles end) * 1000 as cobrado_pagado
from {{ source('raw_hacienda_ccaa', 'hacienda_ccaa_capitulos') }} as c
join {{ ref('ccaa_codigos_hacienda') }} as m
  on m.cod_ccaa_hacienda = c.cod_ccaa_hacienda
group by all
