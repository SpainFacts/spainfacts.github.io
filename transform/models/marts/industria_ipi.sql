-- Índice de producción industrial (IPI), anual, base 2021 = 100, en formato largo:
--   fuente 'eurostat': sts_inpr_a (raw.eurostat_industria_ipi), corregido de calendario, los 27
--     países y EU27_2020, por rama NACE (B-D = industria sin construcción ni agua, C = manufacturas,
--     y algunas divisiones). ambito = 'pais', cod = código del país.
--   fuente 'ine': tabla 70177 (raw.ine_industria_ipi_ccaa), media anual del índice mensual
--     original, España (cod '00') y comunidades (cod INE), por destino económico ('Total industria',
--     'Bienes de consumo', 'Bienes de equipo', 'Bienes intermedios', 'Energía'...).
--   fuente 'ine_divisiones': tabla 60282 (raw.ine_industria_ipi_divisiones), media anual del
--     índice por división CNAE corregido de estacionalidad y calendario, España.
-- Solo años completos en el INE (12 meses). variacion_anual_pct: sobre el año anterior.
-- El IPI mide volumen (cantidades), no euros: no necesita deflactar ni ajustarse por población
-- (es un índice).
with eurostat as (
    select
        'eurostat' as fuente,
        'pais' as ambito,
        e.pais as cod,
        n.pais_nombre as nombre,
        e.rama,
        case e.rama
            when 'B-D' then 'Industria (extractivas, manufacturas y energía)'
            when 'C' then 'Manufacturas'
            when 'D' then 'Energía eléctrica y gas'
            when 'C10' then 'Alimentación'
            when 'C11' then 'Bebidas'
            when 'C19' then 'Refino de petróleo'
            when 'C20' then 'Química'
            when 'C21' then 'Farmacia'
            when 'C23' then 'Minerales no metálicos'
            when 'C24' then 'Metalurgia'
            when 'C27' then 'Material eléctrico'
            when 'C28' then 'Maquinaria'
            when 'C29' then 'Automóvil'
            when 'C30' then 'Otro material de transporte'
        end as rama_nombre,
        cast(e.anio as integer) as anio,
        e.indice,
        12 as meses
    from {{ source('raw_industria', 'eurostat_industria_ipi') }} e
    left join {{ ref('industria_paises') }} n using (pais)
    where e.indice is not null
),

ine_mensual as (
    select
        trim(split_part(serie, '. ', 1)) as territorio,
        trim(split_part(serie, '. ', 2)) as destino,
        cast(anyo as integer) as anio,
        valor
    from {{ source('raw_industria', 'ine_industria_ipi_ccaa') }}
    where trim(split_part(serie, '. ', 3)) = 'Índice' and valor is not null
),

ine as (
    select
        'ine' as fuente,
        case when c.cod_ccaa = '00' then 'pais' else 'ccaa' end as ambito,
        c.cod_ccaa as cod,
        case when c.cod_ccaa = '00' then 'España' else m.territorio end as nombre,
        m.destino as rama,
        m.destino as rama_nombre,
        m.anio,
        avg(m.valor) as indice,
        count(*) as meses
    from ine_mensual m
    join {{ ref('ine_ccaa_nombres') }} c on c.nombre_ine = m.territorio
    group by all
),

ine_divisiones as (
    select
        'ine_divisiones' as fuente,
        'pais' as ambito,
        '00' as cod,
        'España' as nombre,
        trim(split_part(serie, '. ', 1)) as rama,
        trim(split_part(serie, '. ', 1)) as rama_nombre,
        cast(anyo as integer) as anio,
        avg(valor) as indice,
        count(*) as meses
    from {{ source('raw_industria', 'ine_industria_ipi_divisiones') }}
    where trim(split_part(serie, '. ', 2)) = 'Índice' and valor is not null
    group by all
),

todo as (
    select * from eurostat
    union all select * from ine where meses = 12
    union all select * from ine_divisiones where meses = 12
)

select
    fuente,
    ambito,
    cod,
    nombre,
    rama,
    rama_nombre,
    anio,
    indice,
    100.0 * (indice / lag(indice) over (partition by fuente, cod, rama order by anio) - 1) as variacion_anual_pct,
    meses
from todo
