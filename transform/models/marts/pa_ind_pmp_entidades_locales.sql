-- Índice propio (bloque aparte, «pagar a tiempo»): periodo medio de pago a
-- proveedores de las diputaciones (provinciales y forales) y de los cabildos y
-- consells insulares, por trimestre. Ver docs/elaboracion-propia/pmp_ccaa.md.
-- Los ayuntamientos ya están en transparencia_pmp (no se duplican aquí).
--
-- Fuente: PMP_NET (Hacienda), fichero2 trimestral, entidades de tipo DD
-- (raw.pmp_entidades, ingestion/hacienda_transparencia.py). Las diputaciones y
-- cabildos están en el modelo de cesión: el dato trimestral es el del último mes
-- del trimestre.
--   fuera_plazo  PMP > 30 días (máximo de la normativa de morosidad)
--   en_plazo     PMP <= 30 días
--   no_consta    no figura en la publicación del trimestre (no lo ha comunicado:
--                RD 635/2014 y art. 16.8 Orden HAP/2105/2012)
--   no_aplica    Consell de Formentera: comunica como ayuntamiento (07024)
-- Solo desde el segundo trimestre de 2018 (metodología del RD 1040/2017).

with pmp as (
    select
        cast(anio as integer) as anio,
        cast(trimestre as integer) as trimestre,
        cod_prov,
        substr(codigo_entidad, 7, 3) as cod_corp,
        max(pmp_dias) as pmp_dias,
        max(importe_pagos_realizados) as importe_pagos_realizados,
        max(importe_pagos_pendientes) as importe_pagos_pendientes,
        max(nombre) as nombre_pmp
    from {{ source('raw_hacienda_transparencia', 'pmp_entidades') }}
    where tipo_entidad = 'DD' and cast(anio as integer) * 10 + cast(trimestre as integer) >= 20182
    group by all
),

trimestres as (
    select distinct anio, trimestre from pmp
),

islas (cod_prov, cod_corp, cod_entidad, nombre) as (
    values
        ('07', '001', 'I07006', 'Consell Insular d''Eivissa'),
        ('07', '002', 'I07008', 'Consell Insular de Mallorca'),
        ('07', '003', 'I07009', 'Consell Insular de Menorca'),
        ('07', '004', 'I07001', 'Consell Insular de Formentera'),
        ('35', '001', 'I35002', 'Cabildo Insular de Fuerteventura'),
        ('35', '002', 'I35004', 'Cabildo Insular de Gran Canaria'),
        ('35', '003', 'I35007', 'Cabildo Insular de Lanzarote y La Graciosa'),
        ('38', '001', 'I38003', 'Cabildo Insular de La Gomera'),
        ('38', '002', 'I38005', 'Cabildo Insular de El Hierro'),
        ('38', '003', 'I38010', 'Cabildo Insular de La Palma'),
        ('38', '004', 'I38011', 'Cabildo Insular de Tenerife')
),

provincias as (
    select cod as cod_prov, cod_ccaa, nombre from {{ ref('territorios') }} where nivel = 'provincia'
),

ultimo_padron as (select max(anio) as anio from {{ ref('poblacion_municipios') }}),

poblacion_prov as (
    select anio, cod_prov, sum(poblacion) as poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
    group by all
),

entidades as (
    select 'Diputación provincial' as tipo_entidad, 'D' || cod_prov as cod_entidad,
        case when cod_prov in ('01', '20', '48') then 'Diputación Foral de ' else 'Diputación Provincial de ' end || nombre as nombre_entidad,
        cod_prov, cod_ccaa, '000' as cod_corp
    from provincias
    where cod_prov not in ('07', '26', '28', '30', '31', '33', '35', '38', '39', '51', '52')
    union all
    select 'Cabildo o consell insular', i.cod_entidad, i.nombre, i.cod_prov, p.cod_ccaa, i.cod_corp
    from islas i join provincias p using (cod_prov)
),

universo as (
    select t.anio, t.trimestre, e.*,
        -- último día del mes siguiente al trimestre (plazo de comunicación)
        last_day(make_date(t.anio + (t.trimestre = 4)::int, 3 * t.trimestre % 12 + 1, 1)) as fecha_plazo,
        case when e.tipo_entidad = 'Diputación provincial' then pp.poblacion end as poblacion
    from trimestres t
    cross join entidades e
    left join poblacion_prov pp
      on pp.cod_prov = e.cod_prov and pp.anio = least(t.anio, (select anio from ultimo_padron))
)

select
    'pmp_entidades_locales' as obligacion,
    'Pago a proveedores en 30 días (periodo medio de pago)' as obligacion_nombre,
    'arts. 4.2 y 13.6 LO 2/2012 (plazo máximo de la normativa de morosidad: 30 días, art. 4 Ley 3/2004 y art. 198.4 LCSP); RD 635/2014 modificado por el RD 1040/2017; art. 16.8 Orden HAP/2105/2012 (comunicación trimestral)' as base_legal,
    u.tipo_entidad,
    u.cod_entidad,
    u.nombre_entidad,
    cast(null as varchar) as cod_mun,
    u.cod_prov,
    u.cod_ccaa,
    cast(u.anio as varchar) || 'T' || cast(u.trimestre as varchar) as periodo,
    u.anio,
    u.fecha_plazo,
    case
        when u.cod_entidad = 'I07001' then 'no_aplica'
        when p.cod_prov is null then 'no_consta'
        when p.pmp_dias > 30 then 'fuera_plazo'
        else 'en_plazo'
    end as estado,
    case when p.pmp_dias is not null then cast(greatest(round(p.pmp_dias - 30), 0) as integer) end as dias_retraso,
    cast(null as integer) as n_total,
    cast(null as integer) as n_fuera_plazo,
    cast(null as double) as mediana_dias,
    u.cod_entidad <> 'I07001' as aplica_indicador,
    case when u.cod_entidad = 'I07001' then 'El Consell Insular de Formentera es también el ayuntamiento y comunica su PMP como tal (07024, en transparencia_pmp)' end as motivo_no_aplica,
    cast(u.poblacion as integer) as poblacion,
    'https://serviciostelematicosext.hacienda.gob.es/sgcief/pmp_net/aspx/consulta/descarga.aspx?ejercicio='
        || cast(u.anio as varchar) || '&periodo='
        || ['Marzo', 'Junio', 'Septiembre', 'Diciembre'][u.trimestre] || '&tipoPublicacion=2&fichero=fichero2' as url_fuente,
    -- extras
    'pagar' as x_bloque,
    u.trimestre as x_trimestre,
    p.pmp_dias as x_pmp_dias,
    p.importe_pagos_realizados as x_importe_pagos_realizados,
    p.importe_pagos_pendientes as x_importe_pagos_pendientes,
    p.nombre_pmp as x_nombre_pmp,
    'pmp_entidades_locales-' || u.cod_entidad || '-' || cast(u.anio as varchar) || 'T' || cast(u.trimestre as varchar) as clave
from universo u
left join pmp p on p.anio = u.anio and p.trimestre = u.trimestre and p.cod_prov = u.cod_prov and p.cod_corp = u.cod_corp
