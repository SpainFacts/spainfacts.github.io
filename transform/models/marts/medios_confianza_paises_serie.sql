-- Confianza en las noticias por país y año (2015-): % de internautas que dice
-- confiar en la mayoría de las noticias la mayor parte del tiempo («I think you
-- can trust most news most of the time»). Reuters Institute Digital News
-- Report, gráfico «Overall trust score» de la página de cada país (raw
-- dnr_graficos; se toma el del informe más reciente de cada país, que trae la
-- serie completa). La encuesta se hace en enero-febrero del año del informe.
-- puesto_ue / paises_ue: posición del país entre los Estados de la UE que
-- cubre el DNR ese año (1 = más confianza; empates con el mismo puesto).
-- media_ue: media simple de esos países.
with graf as (
    select pais_slug, anio_informe, etiqueta, valor
    from {{ source('raw_medios_confianza', 'dnr_graficos') }}
    where titulo ilike '%overall trust%'
      and regexp_matches(etiqueta, '^(19|20)[0-9]{2}$')
      and valor is not null
),

ultimo as (
    select pais_slug, max(anio_informe) as anio_informe from graf group by 1
),

serie as (
    select g.pais_slug, cast(g.etiqueta as integer) as anio, max(g.valor) as confianza
    from graf g
    join ultimo u using (pais_slug, anio_informe)
    group by 1, 2
),

con_pais as (
    select s.anio, p.iso2, p.nombre_es as pais, p.ue, p.europa, s.confianza
    from serie s
    join {{ ref('medios_confianza_paises_dnr') }} p on p.slug = s.pais_slug
)

select anio, iso2, pais, ue, europa, confianza,
    case when ue then cast(rank() over (partition by anio, ue order by confianza desc) as integer) end as puesto_ue,
    cast(count(*) filter (where ue) over (partition by anio) as integer) as paises_ue,
    round(avg(confianza) filter (where ue) over (partition by anio), 1) as media_ue
from con_pais
order by anio, iso2
