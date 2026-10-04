-- Cómo se informan los españoles (2013-): % de internautas que usó cada tipo
-- de fuente para informarse en la última semana. Reuters Institute Digital
-- News Report, gráfico «Sources of news» de la página de España (raw
-- dnr_graficos; cada año se toma el valor del informe más reciente que lo
-- trae, porque cada gráfico repite la serie). Tipos: televisión, prensa
-- impresa, internet por cualquier vía (webs y apps de medios, redes, podcasts
-- y, desde 2025, chatbots de IA) y redes sociales. Muestra online: sobrerrepresenta
-- a quien usa internet y subestima la prensa y la televisión entre los mayores.
with graf as (
    select anio_informe, cast(etiqueta as integer) as anio, lower(trim(columna)) as columna, valor
    from {{ source('raw_medios_confianza', 'dnr_graficos') }}
    where pais_slug = 'spain'
      and regexp_matches(trim(etiqueta), '^(19|20)[0-9]{2}$')
      and lower(trim(columna)) in ('tv', 'print', 'any online*', 'any online', 'online (incl. social media)',
                                   'online (inc. social)', 'social', 'social media')
      and valor is not null
),

tipado as (
    select anio_informe, anio, valor,
        case
            when columna = 'tv' then 'Televisión'
            when columna = 'print' then 'Prensa impresa'
            when columna in ('social', 'social media') then 'Redes sociales'
            else 'Internet (cualquier vía)'
        end as tipo
    from graf
)

select anio, tipo, arg_max(valor, anio_informe) as pct,
    cast(max(anio_informe) as integer) as anio_informe
from tipado
group by 1, 2
order by 1, 2
