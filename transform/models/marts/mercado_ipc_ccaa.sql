-- IPC por comunidad autónoma, mensual (INE, tabla 76140: tasas de variación
-- del índice general por comunidad; la API da los datos desde 1978 para la tasa
-- mensual y desde 1979 para la anual). cod_ccaa = código INE ('00' = España).
--   var_anual, var_mensual: tal como las publica el INE.
--   subida_desde_2019: subida acumulada de los precios desde diciembre de 2019
--     (%), encadenando las tasas mensuales publicadas (redondeadas a un
--     decimal, así que puede diferir unas décimas del cálculo con índices).
with base as (
    select
        date_trunc('month', cast(epoch_ms(fecha) + interval 12 hour as date)) as mes,
        case split_part(serie, '. ', 1) when 'Nacional' then 'Total Nacional' else split_part(serie, '. ', 1) end as territorio,
        split_part(serie, '. ', 3) as tipo,
        valor
    from {{ source('raw_mercado', 'ine_ipc_ccaa_variacion') }}
    where valor is not null
),

ancho as (
    select
        b.mes,
        n.cod_ccaa,
        max(valor) filter (where tipo = 'Variación anual') as var_anual,
        max(valor) filter (where tipo = 'Variación mensual') as var_mensual
    from base b
    join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = b.territorio
    group by all
)

select
    mes,
    cast(year(mes) as integer) as anio,
    cod_ccaa,
    var_anual,
    var_mensual,
    case when mes >= date '2020-01-01' then
        100 * (exp(sum(ln(1 + var_mensual / 100)) filter (where mes >= date '2020-01-01')
            over (partition by cod_ccaa order by mes)) - 1)
    end as subida_desde_2019
from ancho
