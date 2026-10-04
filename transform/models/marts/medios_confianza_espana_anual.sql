-- España, indicadores de confianza y consumo de noticias por año de encuesta
-- (Reuters Institute Digital News Report; encuesta online de YouGov en
-- enero-febrero, ~2.000 internautas; en España con la Universidad de Navarra):
--   confianza: % que confía en la mayoría de las noticias la mayor parte del
--     tiempo (gráfico «Overall trust score», 2015-);
--   confianza_puesto_ue / paises_ue: puesto de España entre los Estados de la
--     UE que cubre el DNR (medios_confianza_paises_serie);
--   paga: % que pagó por noticias online el último año (tarjeta de la página
--     de España, 2021-; 2022-2023 coinciden con los gráficos del resumen);
--   evita: % que evita las noticias a menudo o a veces (gráficos del resumen
--     de 2022 y 2025 con 2017, 2019, 2022 y 2025, y tarjeta de 2026);
--   interes: % muy o extremadamente interesado en las noticias (gráfico del
--     resumen de 2026 con la serie de España desde 2015);
--   tv, prensa, online, redes: % que usó cada fuente para informarse la última
--     semana (medios_confianza_fuentes).
with serie as (
    select anio, confianza, puesto_ue, paises_ue, media_ue
    from {{ ref('medios_confianza_paises_serie') }}
    where iso2 = 'ES'
),

graf as (
    select anio_informe, titulo, trim(regexp_replace(regexp_replace(etiqueta, ':[a-z]{2}:', ''), '\*', '')) as etiqueta,
        trim(columna) as columna, valor
    from {{ source('raw_medios_confianza', 'dnr_graficos') }}
    where pais_slug = 'resumen' and valor is not null
),

evita_graf as (
    -- columnas = años (2017, 2019, 2022...) o «Avoid news» (= año del informe)
    select case when regexp_matches(columna, '^20[0-9]{2}$') then cast(columna as integer)
                else cast(anio_informe as integer) end as anio,
        valor, anio_informe
    from graf
    where titulo ilike '%avoid the news%' and titulo not ilike '%because%' and etiqueta = 'Spain'
      and (regexp_matches(columna, '^20[0-9]{2}$') or columna ilike 'avoid%')
),

tarj as (
    select cast(anio_informe as integer) as anio, indicador, valor
    from {{ source('raw_medios_confianza', 'dnr_tarjetas') }}
    where pais_slug = 'spain' and valor is not null
),

evita as (
    select anio, arg_max(valor, anio_informe) as evita from (
        select anio, valor, anio_informe from evita_graf
        union all
        select anio, valor, anio + 1000 from tarj where indicador ilike 'avoid the news%'
    ) group by 1
),

paga as (
    select anio, max(valor) as paga from tarj where indicador ilike 'pay for online news%' group by 1
),

interes as (
    select cast(etiqueta as integer) as anio, arg_max(valor, anio_informe) as interes
    from graf
    where titulo ilike '%interested in%news%' and columna = 'Spain' and regexp_matches(etiqueta, '^20[0-9]{2}$')
    group by 1
),

fuentes as (
    select anio,
        max(pct) filter (where tipo = 'Televisión') as tv,
        max(pct) filter (where tipo = 'Prensa impresa') as prensa,
        max(pct) filter (where tipo = 'Internet (cualquier vía)') as online,
        max(pct) filter (where tipo = 'Redes sociales') as redes
    from {{ ref('medios_confianza_fuentes') }}
    group by 1
),

anios as (
    select anio from serie union select anio from paga union select anio from evita
    union select anio from interes union select anio from fuentes
)

select a.anio, s.confianza, s.puesto_ue as confianza_puesto_ue, s.paises_ue, s.media_ue as confianza_media_ue,
    p.paga, e.evita, i.interes, f.tv, f.prensa, f.online, f.redes
from anios a
left join serie s using (anio)
left join paga p using (anio)
left join evita e using (anio)
left join interes i using (anio)
left join fuentes f using (anio)
order by a.anio
