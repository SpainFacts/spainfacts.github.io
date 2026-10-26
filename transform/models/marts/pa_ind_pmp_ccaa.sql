-- Índice propio (bloque aparte, «pagar a tiempo»): periodo medio de pago a
-- proveedores mensual de cada comunidad autónoma. Ver docs/elaboracion-propia/pmp_ccaa.md.
--
-- Mide retraso en PAGAR, no en publicar ni en remitir: las 17 comunidades
-- comunican su PMP todos los meses. Va en un bloque separado del índice de
-- remisión de información.
-- Máximo legal: el plazo de la normativa de morosidad, 30 días (art. 4 Ley 3/2004
-- y art. 198.4 LCSP), al que remiten los arts. 4.2 y 13.6 de la LO 2/2012 de
-- Estabilidad Presupuestaria y Sostenibilidad Financiera (redacción de la LO
-- 9/2013). Metodología del RD 635/2014 modificado por el RD 1040/2017,
-- comparable desde abril de 2018.
--   fuera_plazo  PMP del mes > 30 días (dias_retraso = días por encima de 30, redondeados)
--   en_plazo     PMP <= 30 días
--   no_consta    el mes no aparece en la serie para esa comunidad
--   no_aplica    Ceuta y Melilla: comunican su PMP como entidad local (PMP_NET,
--                trimestral), no en la serie mensual de las comunidades.

with pmp as (
    select cod_ccaa, cast(anio as integer) as anio, cast(mes as integer) as mes,
        pmp_dias, ratio_operaciones_pagadas, ratio_operaciones_pendientes,
        importe_pagos_realizados, importe_pagos_pendientes, url_fuente
    from {{ source('raw_pa_registros', 'pmp_ccaa') }}
),

meses as (
    select distinct anio, mes from pmp
),

ultimo_padron as (select max(anio) as anio from {{ ref('poblacion_municipios') }}),

poblacion as (
    select anio, cod_ccaa, sum(poblacion) as poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
    group by all
),

ccaa as (
    select cod as cod_ccaa, nombre from {{ ref('territorios') }} where nivel = 'ccaa'
),

universo as (
    select m.anio, m.mes, c.cod_ccaa, c.nombre, po.poblacion
    from meses m
    cross join ccaa c
    left join poblacion po
      on po.cod_ccaa = c.cod_ccaa and po.anio = least(m.anio, (select anio from ultimo_padron))
)

select
    'pmp_ccaa' as obligacion,
    'Pago a proveedores en 30 días (periodo medio de pago)' as obligacion_nombre,
    'arts. 4.2 y 13.6 LO 2/2012 (plazo máximo de la normativa de morosidad: 30 días, art. 4 Ley 3/2004 y art. 198.4 LCSP); RD 635/2014 modificado por el RD 1040/2017 (cálculo)' as base_legal,
    'Comunidad autónoma' as tipo_entidad,
    'C' || u.cod_ccaa as cod_entidad,
    u.nombre as nombre_entidad,
    cast(null as varchar) as cod_mun,
    case u.cod_ccaa when '18' then '51' when '19' then '52' end as cod_prov,
    u.cod_ccaa,
    cast(u.anio as varchar) || '-' || lpad(cast(u.mes as varchar), 2, '0') as periodo,
    u.anio,
    last_day(make_date(u.anio, u.mes, 1)) as fecha_plazo,
    case
        when u.cod_ccaa in ('18', '19') then 'no_aplica'
        when p.pmp_dias is null then 'no_consta'
        when p.pmp_dias > 30 then 'fuera_plazo'
        else 'en_plazo'
    end as estado,
    case when p.pmp_dias is not null then cast(greatest(round(p.pmp_dias - 30), 0) as integer) end as dias_retraso,
    cast(null as integer) as n_total,
    cast(null as integer) as n_fuera_plazo,
    cast(null as double) as mediana_dias,
    u.cod_ccaa not in ('18', '19') as aplica_indicador,
    case when u.cod_ccaa in ('18', '19') then 'Ciudad autónoma: comunica su PMP como entidad local (PMP_NET trimestral), no en la serie mensual de comunidades' end as motivo_no_aplica,
    cast(u.poblacion as integer) as poblacion,
    coalesce(p.url_fuente, 'https://www.hacienda.gob.es/cdi/pmp/pmp-series-rd-1040-2017.xlsx') as url_fuente,
    -- extras
    'pagar' as x_bloque,
    u.mes as x_mes,
    p.pmp_dias as x_pmp_dias,
    p.ratio_operaciones_pagadas as x_ratio_operaciones_pagadas,
    p.ratio_operaciones_pendientes as x_ratio_operaciones_pendientes,
    p.importe_pagos_realizados as x_importe_pagos_realizados,
    p.importe_pagos_pendientes as x_importe_pagos_pendientes,
    'pmp_ccaa-C' || u.cod_ccaa || '-' || cast(u.anio as varchar) || '-' || lpad(cast(u.mes as varchar), 2, '0') as clave
from universo u
left join pmp p on p.cod_ccaa = u.cod_ccaa and p.anio = u.anio and p.mes = u.mes
