-- Compraventas de viviendas e hipotecas sobre viviendas por mes, España,
-- comunidades y provincias.
--   Compraventas: INE, Estadística de Transmisiones de Derechos de la Propiedad
--   (ETDP), tabla 6150, desde 2007 (inscripciones en los registros de la
--   propiedad): total, nueva, segunda mano, libre y protegida.
--   Hipotecas: INE, Estadística de Hipotecas (H), tablas 13896 (CCAA) y 3200
--   (provincias), fincas de tipo "Viviendas", desde 2003: número e importe
--   (el INE lo da en miles de euros; aquí en euros).
-- importe_medio_real: importe medio por hipoteca en euros del año base de
-- main.deflactor (IPC mensual; si falta el mes, factor anual).
-- *_12m: suma de los últimos 12 meses (solo si están los 12), y por 1.000
-- habitantes con la población a 1 de enero del año del mes.
with compraventas as (
    select
        n.nivel,
        n.cod,
        -- +12 h: el INE fecha a medianoche hora peninsular (22:00 o 23:00 UTC del día anterior)
        cast(date_trunc('month', cast(epoch_ms(s.fecha + 43200000) as date)) as date) as fecha,
        max(s.valor) filter (where split_part(s.serie, '. ', 2) = 'General') as compraventas,
        max(s.valor) filter (where split_part(s.serie, '. ', 2) = 'Vivienda nueva') as compraventas_nueva,
        max(s.valor) filter (where split_part(s.serie, '. ', 2) = 'Vivienda segunda mano') as compraventas_segunda_mano,
        max(s.valor) filter (where split_part(s.serie, '. ', 2) = 'Vivienda libre') as compraventas_libre,
        max(s.valor) filter (where split_part(s.serie, '. ', 2) = 'Vivienda protegida') as compraventas_protegida
    from {{ source('raw_vivienda', 'ine_compraventas') }} s
    join {{ ref('vivienda_nombres') }} n on n.nombre_ine = split_part(s.serie, '. ', 1)
    where s.valor is not null
    group by all
),

hipotecas_ccaa as (
    -- El orden de las partes del nombre varía ("Viviendas. Número de hipotecas.
    -- Total Nacional..." frente a "Viviendas. Andalucía. Número de hipotecas..."):
    -- el territorio es la parte 2 o la 3, la que no es el tipo de dato.
    select
        case when split_part(serie, '. ', 2) like '%de hipotecas' then split_part(serie, '. ', 3) else split_part(serie, '. ', 2) end as territorio,
        case when serie like '%Número de hipotecas%' then 'numero' else 'importe' end as dato,
        fecha,
        valor
    from {{ source('raw_vivienda', 'ine_hipotecas_ccaa') }}
    where split_part(serie, '. ', 1) = 'Viviendas' and valor is not null
),

hipotecas_prov as (
    select
        split_part(serie, '. ', 3) as territorio,
        case when serie like '%Número de hipotecas%' then 'numero' else 'importe' end as dato,
        fecha,
        valor
    from {{ source('raw_vivienda', 'ine_hipotecas_provincias') }}
    where split_part(serie, '. ', 1) = 'Viviendas' and valor is not null
),

hipotecas as (
    select
        n.nivel,
        n.cod,
        cast(date_trunc('month', cast(epoch_ms(h.fecha + 43200000) as date)) as date) as fecha,
        max(h.valor) filter (where h.dato = 'numero') as hipotecas,
        1000 * max(h.valor) filter (where h.dato = 'importe') as importe_hipotecas
    from hipotecas_ccaa h
    join {{ ref('vivienda_nombres') }} n on n.nombre_ine = h.territorio and n.nivel in ('pais', 'ccaa')
    group by all
    union all
    select
        n.nivel,
        n.cod,
        cast(date_trunc('month', cast(epoch_ms(h.fecha + 43200000) as date)) as date) as fecha,
        max(h.valor) filter (where h.dato = 'numero') as hipotecas,
        1000 * max(h.valor) filter (where h.dato = 'importe') as importe_hipotecas
    from hipotecas_prov h
    join {{ ref('vivienda_nombres') }} n on n.nombre_ine = h.territorio and n.nivel = 'provincia'
    group by all
),

ipc_mes as (
    select cast(periodo as date) as fecha, valor as ipc from {{ ref('metricas') }} where metrica_id = 'ipc_indice'
),

base_ipc as (
    select ipc_medio as ipc_base, anio_base from {{ ref('deflactor') }} where anio = anio_base
),

unido as (
    select
        coalesce(c.nivel, h.nivel) as nivel,
        coalesce(c.cod, h.cod) as cod,
        coalesce(c.fecha, h.fecha) as fecha,
        c.compraventas,
        c.compraventas_nueva,
        c.compraventas_segunda_mano,
        c.compraventas_libre,
        c.compraventas_protegida,
        h.hipotecas,
        h.importe_hipotecas
    from compraventas c
    full outer join hipotecas h on h.nivel = c.nivel and h.cod = c.cod and h.fecha = c.fecha
),

con_real as (
    select
        u.*,
        cast(year(u.fecha) as integer) as anio,
        cast(month(u.fecha) as integer) as mes,
        u.importe_hipotecas / nullif(u.hipotecas, 0) as importe_medio,
        u.importe_hipotecas / nullif(u.hipotecas, 0) * coalesce(b.ipc_base / i.ipc, d.factor) as importe_medio_real,
        u.importe_hipotecas * coalesce(b.ipc_base / i.ipc, d.factor) as importe_hipotecas_real,
        b.anio_base
    from unido u
    cross join base_ipc b
    left join ipc_mes i on i.fecha = u.fecha
    left join {{ ref('deflactor') }} d on d.anio = year(u.fecha)
),

pob as (
    select nivel, cod, anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total'
),

anio_pob as (
    select min(anio) as min_anio, max(anio) as max_anio from pob
),

movil as (
    select
        r.*,
        sum(r.compraventas) over w as compraventas_12m,
        count(r.compraventas) over w as meses_cv_12m,
        sum(r.hipotecas) over w as hipotecas_12m,
        count(r.hipotecas) over w as meses_h_12m
    from con_real r
    window w as (partition by r.nivel, r.cod order by r.fecha rows between 11 preceding and current row)
)

select
    m.nivel,
    m.cod,
    coalesce(t.nombre, 'España') as nombre,
    m.fecha,
    m.anio,
    m.mes,
    m.compraventas,
    m.compraventas_nueva,
    m.compraventas_segunda_mano,
    m.compraventas_libre,
    m.compraventas_protegida,
    m.hipotecas,
    m.importe_hipotecas,
    m.importe_medio,
    m.importe_medio_real,
    m.importe_hipotecas_real,
    m.anio_base,
    case when m.meses_cv_12m = 12 then m.compraventas_12m end as compraventas_12m,
    case when m.meses_h_12m = 12 then m.hipotecas_12m end as hipotecas_12m,
    p.poblacion,
    case when m.meses_cv_12m = 12 then 1000.0 * m.compraventas_12m / p.poblacion end as compraventas_12m_1000,
    case when m.meses_h_12m = 12 then 1000.0 * m.hipotecas_12m / p.poblacion end as hipotecas_12m_1000
from movil m
cross join anio_pob a
left join pob p
  on p.nivel = m.nivel and p.cod = m.cod
 and p.anio = greatest(least(m.anio, a.max_anio), a.min_anio)
left join {{ ref('territorios') }} t on t.nivel = m.nivel and t.cod = m.cod
