-- Confianza en cada medio en España (2020-): % de quienes conocen la marca que
-- le da 6-10 en una escala de 0 a 10 de confianza («confía»), 5 («ni
-- confía ni desconfía») y 0-4 («no confía»). Reuters Institute Digital News
-- Report, gráfico de confianza por marca de la página de España («BRAND
-- TRUST» 2020, «Brand trust scores» 2021-2023, «Public opinion on brand
-- trust» 2024-; raw dnr_graficos). Antes de 2020 el informe daba una
-- puntuación media 0-10, no comparable, y no se incluye. Se pregunta por unas
-- 15 marcas elegidas por el propio informe; no es un ranking de todos los
-- medios. neto = confía - no confía. puesto: 1 = más confianza ese año.
-- Los nombres se unifican (TVE/RTVE, periódico regional o local...).
with graf as (
    select anio_informe, etiqueta, lower(trim(columna)) as columna, valor
    from {{ source('raw_medios_confianza', 'dnr_graficos') }}
    where pais_slug = 'spain'
      and anio_informe >= 2020
      and (titulo ilike '%brand trust%')
      and valor is not null
),

ancho as (
    select cast(anio_informe as integer) as anio,
        case
            when etiqueta ilike '%RTVE%' or etiqueta ilike 'TVE%' then 'RTVE'
            when etiqueta ilike '%regional or local newspaper%' then 'Periódico regional o local'
            when lower(trim(etiqueta)) = 'eldiario.es' then 'elDiario.es'
            when etiqueta ilike 'okdiario%' then 'OKDiario'
            when etiqueta ilike 'elconfidencial%' or etiqueta ilike 'el confidencial%' then 'El Confidencial'
            when etiqueta ilike 'elespañol%' or etiqueta ilike 'el español%' then 'El Español'
            when etiqueta ilike 'publico%' or etiqueta ilike 'público%' then 'Público'
            else trim(etiqueta)
        end as marca,
        max(valor) filter (where columna = 'trust') as confia,
        max(valor) filter (where columna = 'neither') as ni_confia_ni_desconfia,
        max(valor) filter (where columna = 'don''t trust') as no_confia
    from graf
    group by 1, 2
)

select anio, marca,
    round(confia, 1) as confia,
    round(ni_confia_ni_desconfia, 1) as ni_confia_ni_desconfia,
    round(no_confia, 1) as no_confia,
    round(confia - no_confia, 1) as neto,
    cast(rank() over (partition by anio order by confia desc) as integer) as puesto,
    cast(count(*) over (partition by anio) as integer) as marcas_anio
from ancho
where confia is not null
order by anio, confia desc
