-- Comparación entre países del último Digital News Report (Reuters Institute):
-- confianza en las noticias (% que confía en la mayoría de las noticias la
-- mayor parte del tiempo), su valor en el primer año de la serie (2015 en casi
-- todos), % que pagó por noticias online el último año y % que evita las
-- noticias a menudo o a veces (tarjetas de la página de cada país, raw
-- dnr_tarjetas), y % preocupado por distinguir lo real de lo falso en internet
-- y % que usó redes sociales o de vídeo para informarse la última semana
-- (gráfico del resumen ejecutivo «Proportion concerned about fake news online
-- plotted against...», raw dnr_graficos). Puestos entre los Estados de la UE
-- que cubre el DNR (1 = el valor más alto).
with serie as (
    select * from {{ ref('medios_confianza_paises_serie') }}
),

ult_anio as (
    select iso2, max(anio) as anio from serie group by 1
),

primero as (
    select iso2, min(anio) as anio from serie group by 1
),

tarj as (
    select t.pais_slug, t.anio_informe, t.indicador, t.valor
    from {{ source('raw_medios_confianza', 'dnr_tarjetas') }} t
    where t.valor is not null
),

tarj_ult as (
    select pais_slug,
        arg_max(valor, anio_informe) filter (where indicador ilike 'pay for online news%') as paga,
        max(anio_informe) filter (where indicador ilike 'pay for online news%') as paga_anio,
        arg_max(valor, anio_informe) filter (where indicador ilike 'avoid the news%') as evita,
        max(anio_informe) filter (where indicador ilike 'avoid the news%') as evita_anio
    from tarj
    group by 1
),

falso_graf as (
    select anio_informe, fila, etiqueta, columna, valor
    from {{ source('raw_medios_confianza', 'dnr_graficos') }}
    where pais_slug = 'resumen' and titulo ilike '%concerned about fake news%plotted%'
),

falso as (
    select f.etiqueta,
        max(f.valor) filter (where f.columna ilike '%concerned%') as preocupa_falso,
        max(f.valor) filter (where f.columna ilike '%social media%') as redes_noticias,
        max(f.anio_informe) as falso_anio
    from falso_graf f
    where f.anio_informe = (select max(anio_informe) from falso_graf)
    group by 1
)

select p.iso2, p.nombre_es as pais, p.ue, p.europa,
    cast(u.anio as integer) as anio,
    s.confianza,
    s.puesto_ue as confianza_puesto_ue,
    s.paises_ue,
    s.media_ue as confianza_media_ue,
    cast(pr.anio as integer) as anio_inicio,
    s0.confianza as confianza_inicio,
    s.confianza - s0.confianza as confianza_cambio_pp,
    t.paga, cast(t.paga_anio as integer) as paga_anio,
    t.evita, cast(t.evita_anio as integer) as evita_anio,
    f.preocupa_falso, f.redes_noticias, cast(f.falso_anio as integer) as falso_anio,
    case when p.ue and t.paga is not null and t.paga_anio = u.anio
        then cast(rank() over (partition by (p.ue and t.paga is not null and t.paga_anio = u.anio) order by t.paga desc) as integer) end as paga_puesto_ue,
    case when p.ue and t.evita is not null
        then cast(rank() over (partition by (p.ue and t.evita is not null) order by t.evita desc) as integer) end as evita_puesto_ue,
    case when p.ue and f.preocupa_falso is not null
        then cast(rank() over (partition by (p.ue and f.preocupa_falso is not null) order by f.preocupa_falso desc) as integer) end as preocupa_falso_puesto_ue
from ult_anio u
join {{ ref('medios_confianza_paises_dnr') }} p on p.iso2 = u.iso2
join serie s on s.iso2 = u.iso2 and s.anio = u.anio
join primero pr on pr.iso2 = u.iso2
join serie s0 on s0.iso2 = pr.iso2 and s0.anio = pr.anio
left join tarj_ult t on t.pais_slug = p.slug
left join falso f on f.etiqueta in (p.nombre_en, p.nombre_alt)
order by s.confianza desc
