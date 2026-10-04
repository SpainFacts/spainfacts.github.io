-- Resumen del buscador «Quién recibe qué» (medios_receptores): una fila por medio,
-- año y vía (publicidad institucional del Estado, publicidad comercial de empresas del
-- Estado, publicidad institucional autonómica/local, contrato, subvención) con el importe
-- en euros de 2025, el número de pagos y de administraciones pagadoras distintas. Los
-- totales de cada medio (todos los años, 2019-2025, por vía) y su puesto en el ranking
-- están en medios_receptores_totales: aquí no se repiten, así que sumar esta tabla es
-- siempre correcto.
-- - Las vías no son homogéneas: la publicidad del Estado por medio solo existe para 2025,
--   la territorial solo de las comunidades y ayuntamientos que publican el medio, los
--   contratos son un mínimo documentado (desde 2018) y las subvenciones empiezan en 2022 (2018 las del Gobierno Vasco, del BOPV).
select
    r.medio_id,
    any_value(r.medio) as medio,
    r.anio,
    r.via,
    sum(r.importe_eur_nominal) as importe_eur_nominal,
    sum(r.importe_eur_real) as importe_eur_real,
    count(*) as n_pagos,
    count(distinct r.administracion) as n_administraciones,
    count(distinct r.gobierno) as n_gobiernos
from {{ ref('medios_receptores') }} r
group by r.medio_id, r.anio, r.via
