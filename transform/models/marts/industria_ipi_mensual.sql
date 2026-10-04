-- Índice de producción industrial mensual del INE (tabla 70177, raw.ine_industria_ipi_ccaa),
-- base 2021 = 100, índice original (sin corregir de calendario ni estacionalidad), España
-- (nivel pais, cod '00') y comunidades, por destino económico. variacion_anual_pct es la tasa interanual
-- que publica el INE (mismo mes del año anterior). Útil para el dato del último mes en la página.
-- Ojo: 'Bienes de consumo duradero' y 'no duradero' están dentro de 'Bienes de consumo': no sumar.
with m as (
    select
        trim(split_part(serie, '. ', 1)) as territorio,
        trim(split_part(serie, '. ', 2)) as destino,
        trim(split_part(serie, '. ', 3)) as dato,
        -- fecha: epoch en ms a medianoche de Madrid; +12 h para caer en el día correcto en cualquier zona
        cast(to_timestamp(fecha / 1000 + 43200) as date) as fecha_raw,
        valor
    from {{ source('raw_industria', 'ine_industria_ipi_ccaa') }}
    where valor is not null
),

mensual as (
    select
        case when c.cod_ccaa = '00' then 'pais' else 'ccaa' end as nivel,
        c.cod_ccaa as cod,
        m.destino,
        date_trunc('month', m.fecha_raw) as fecha,
        max(case when m.dato = 'Índice' then m.valor end) as indice,
        max(case when m.dato = 'Variación anual' then m.valor end) as variacion_anual_pct,
        max(case when m.dato = 'Variación de la media en lo que va de año' then m.valor end) as variacion_acumulada_pct
    from m
    join {{ ref('ine_ccaa_nombres') }} c on c.nombre_ine = m.territorio
    group by all
)

select
    x.nivel,
    x.cod,
    t.nombre,
    x.destino,
    x.fecha,
    cast(year(x.fecha) as integer) as anio,
    x.indice,
    x.variacion_anual_pct,
    x.variacion_acumulada_pct,
    x.fecha = max(x.fecha) over () as es_ultimo_mes
from mensual x
left join {{ ref('territorios') }} t on t.nivel = x.nivel and t.cod = x.cod
