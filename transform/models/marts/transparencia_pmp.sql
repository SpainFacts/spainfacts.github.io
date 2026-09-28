-- Periodo medio de pago a proveedores (PMP) de los ayuntamientos: ¿lo
-- comunican a Hacienda cada trimestre y cuántos días tardan en pagar?
--
-- Una fila por ayuntamiento y trimestre (todos los ayuntamientos existentes ese
-- año). reporta = aparece en la publicación de PMP_NET de ese trimestre.
-- Obligación: RD 635/2014 (modificado por el RD 1040/2017) y art. 16.8 de la
-- Orden HAP/2105/2012: el PMP de cada trimestre (o de cada mes, en los
-- municipios del modelo de cesión) se comunica antes del último día del mes
-- siguiente. supera_30: PMP por encima del máximo de 30 días de la normativa
-- de morosidad (art. 13.6 de la LO 2/2012 y RD 635/2014), solo desde 2018T2.
--
-- Responsabilidad: gobierno en funciones el día del plazo (último día del mes
-- siguiente al trimestre).
--
-- Territorios forales (tutela financiera de las Diputaciones Forales y del
-- Gobierno de Navarra): en Navarra solo comunica a PMP_NET entre un 15 % y un
-- 45 % de los ayuntamientos todos los trimestres; en Álava, un 15-25 % hasta
-- 2022 (desde 2023, ~90 %), y en Bizkaia y Gipuzkoa casi ninguno hasta el
-- segundo trimestre de 2016 (después, 75-100 %). Esos casos se marcan
-- aplica_indicador = false: el hueco refleja el cauce foral y no a cada
-- ayuntamiento. Su PMP, cuando lo comunican, sí cuenta para supera_30.
with entidades as (
    select
        cast(anio as integer) as anio,
        cast(trimestre as integer) as trimestre,
        cod_mun,
        max(pmp_dias) as pmp_dias,
        max(importe_pagos_realizados) as importe_pagos_realizados,
        max(importe_pagos_pendientes) as importe_pagos_pendientes,
        max(modelo) as modelo
    from {{ source('raw_hacienda_transparencia', 'pmp_entidades') }}
    where tipo_entidad = 'AA' and cod_mun is not null
    group by all
),

trimestres as (
    select distinct anio, trimestre from entidades
),

poblacion as (
    select anio, cod_mun, municipio, cod_prov, cod_ccaa, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total' and cod_prov not in ('51', '52')
),

universo as (
    select t.anio, t.trimestre, p.cod_mun, p.municipio, p.cod_prov, p.cod_ccaa, p.poblacion,
        -- último día del mes siguiente al trimestre
        last_day(make_date(cast(t.anio + (t.trimestre = 4)::int as integer), cast(3 * t.trimestre % 12 + 1 as integer), 1)) as fecha_plazo
    from trimestres t
    join poblacion p on p.anio = least(t.anio, (select max(anio) from poblacion))
),

base as (
    select
        u.*,
        e.cod_mun is not null as reporta,
        e.pmp_dias,
        e.importe_pagos_realizados,
        e.importe_pagos_pendientes,
        e.modelo
    from universo u
    left join entidades e on e.anio = u.anio and e.trimestre = u.trimestre and e.cod_mun = u.cod_mun
),

gobierno as (
    select
        b.cod_mun, b.anio, b.trimestre,
        h.alcalde, h.partido_original, h.familia, h.color,
        row_number() over (partition by b.cod_mun, b.anio, b.trimestre order by h.fecha_posesion desc) as n
    from base b
    join {{ ref('alcaldes_historia') }} h
      on h.cod_mun = b.cod_mun
     and h.fecha_posesion <= b.fecha_plazo
     and (h.fecha_fin is null or h.fecha_fin > b.fecha_plazo)
)

select
    b.cod_mun,
    b.municipio,
    b.cod_prov,
    b.cod_ccaa,
    b.anio,
    b.trimestre,
    b.anio || 'T' || b.trimestre as periodo,
    make_date(cast(b.anio as integer), cast(3 * b.trimestre - 2 as integer), 1) as fecha_trimestre,
    b.fecha_plazo,
    b.poblacion,
    case
        when b.poblacion < 1000 then '<1.000'
        when b.poblacion < 5000 then '1.000-5.000'
        when b.poblacion < 20000 then '5.000-20.000'
        when b.poblacion < 50000 then '20.000-50.000'
        when b.poblacion < 100000 then '50.000-100.000'
        else '>100.000'
    end as tramo_poblacion,
    case
        when b.poblacion < 1000 then 1
        when b.poblacion < 5000 then 2
        when b.poblacion < 20000 then 3
        when b.poblacion < 50000 then 4
        when b.poblacion < 100000 then 5
        else 6
    end as tramo_orden,
    b.reporta,
    b.pmp_dias,
    -- Solo con la metodología del RD 1040/2017 (desde el segundo trimestre de
    -- 2018): antes el PMP se medía descontando los 30 días de conformidad y
    -- podía ser negativo, así que el umbral no es comparable.
    case when b.anio * 10 + b.trimestre >= 20182 then b.pmp_dias > 30 end as supera_30,
    b.importe_pagos_realizados,
    b.importe_pagos_pendientes,
    b.modelo,
    not (
        b.cod_prov = '31'
        or (b.cod_prov = '01' and b.anio <= 2022)
        or (b.cod_prov in ('20', '48') and b.anio * 10 + b.trimestre <= 20162)
    ) as aplica_indicador,
    case
        when b.cod_prov = '31' then 'Régimen foral: comunicación a PMP_NET minoritaria por el cauce foral (Navarra)'
        when b.cod_prov = '01' and b.anio <= 2022 then 'Régimen foral: comunicación a PMP_NET minoritaria en Álava hasta 2022'
        when b.cod_prov in ('20', '48') and b.anio * 10 + b.trimestre <= 20162 then 'Régimen foral: casi sin comunicaciones a PMP_NET hasta 2016T2'
    end as motivo_exclusion,
    g.alcalde as alcalde_en_plazo,
    g.partido_original as lista_en_plazo,
    coalesce(g.familia, 'Sin dato de alcalde') as familia_en_plazo,
    coalesce(g.color, '#9ca3af') as color_familia,
    b.cod_mun || '-' || b.anio || 'T' || b.trimestre as clave
from base b
left join gobierno g
  on g.cod_mun = b.cod_mun and g.anio = b.anio and g.trimestre = b.trimestre and g.n = 1
