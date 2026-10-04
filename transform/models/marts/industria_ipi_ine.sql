-- Índice de producción industrial (IPI) anual del INE, base 2021 = 100, solo años completos (12 meses):
--   tipo_rama 'Destino económico': tabla 70177 (raw.ine_industria_ipi_ccaa), media anual del índice
--     mensual original, España (nivel pais, cod '00') y comunidades, por destino económico ('Total
--     industria', 'Bienes de consumo', 'Bienes de equipo', 'Bienes intermedios', 'Energía'...).
--   tipo_rama 'División CNAE': tabla 60282 (raw.ine_industria_ipi_divisiones), media anual del índice
--     corregido de estacionalidad y calendario, solo España.
-- Las dos familias no se comparan entre sí (otra serie y otra corrección): filtrar por tipo_rama.
-- variacion_anual_pct: sobre el año anterior. Los países europeos están en industria_ipi_paises.
-- El IPI mide volumen, no euros: no se deflacta ni se divide por población (es un índice).
with ine_mensual as (
    select
        trim(split_part(serie, '. ', 1)) as territorio,
        trim(split_part(serie, '. ', 2)) as destino,
        cast(anyo as integer) as anio,
        valor
    from {{ source('raw_industria', 'ine_industria_ipi_ccaa') }}
    where trim(split_part(serie, '. ', 3)) = 'Índice' and valor is not null
),

destinos as (
    select
        'Destino económico' as tipo_rama,
        c.cod_ccaa as cod,
        m.destino as rama,
        m.anio,
        avg(m.valor) as indice,
        count(*) as meses
    from ine_mensual m
    join {{ ref('ine_ccaa_nombres') }} c on c.nombre_ine = m.territorio
    group by all
),

divisiones as (
    select
        'División CNAE' as tipo_rama,
        '00' as cod,
        trim(split_part(serie, '. ', 1)) as rama,
        cast(anyo as integer) as anio,
        avg(valor) as indice,
        count(*) as meses
    from {{ source('raw_industria', 'ine_industria_ipi_divisiones') }}
    where trim(split_part(serie, '. ', 2)) = 'Índice' and valor is not null
    group by all
),

todo as (
    select * from destinos where meses = 12
    union all select * from divisiones where meses = 12
)

select
    case when x.cod = '00' then 'pais' else 'ccaa' end as nivel,
    x.cod,
    t.nombre,
    x.tipo_rama,
    x.rama,
    x.anio,
    x.indice,
    100.0 * (x.indice / lag(x.indice) over (partition by x.tipo_rama, x.cod, x.rama order by x.anio) - 1) as variacion_anual_pct
from todo x
left join {{ ref('territorios') }} t on t.nivel = case when x.cod = '00' then 'pais' else 'ccaa' end and t.cod = x.cod
