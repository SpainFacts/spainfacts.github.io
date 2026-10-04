-- Índice de producción industrial (IPI) anual por país europeo, base 2021 = 100 (Eurostat
-- sts_inpr_a, raw.eurostat_industria_ipi), corregido de calendario: los 27 países y EU27_2020
-- (cod_pais ISO), por rama NACE (B-D = industria sin construcción ni agua, C = manufacturas, y
-- algunas divisiones). variacion_anual_pct: sobre el año anterior. Las comunidades y las
-- divisiones del INE están en industria_ipi_ine.
-- El IPI mide volumen (cantidades), no euros: no necesita deflactar ni ajustarse por población
-- (es un índice).
with ipi as (
    select
        p.cod_pais,
        p.pais,
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
        e.indice
    from {{ source('raw_industria', 'eurostat_industria_ipi') }} e
    join {{ ref('paises_iso') }} p on p.eurostat = e.pais
    where e.indice is not null
)

select
    cod_pais,
    pais,
    rama,
    rama_nombre,
    anio,
    indice,
    100.0 * (indice / lag(indice) over (partition by cod_pais, rama order by anio) - 1) as variacion_anual_pct
from ipi
