-- Clasificación Mundial de la Libertad de Prensa de Reporters sans frontières (RSF),
-- 2002-hoy, formato largo: una fila por país, edición e indicador.
--
-- indicador: 'global' (puntuación y puesto de la clasificación) y, desde 2022, los cinco
-- indicadores de la nueva metodología: 'politico', 'economico', 'legislativo', 'social'
-- y 'seguridad', cada uno con su puntuación 0-100 y su puesto mundial.
-- escala: las puntuaciones NO son comparables entre etapas: '2002-2012' (0 = mejor, sin
-- tope), '2013-2021' (0-100, 100 = mejor, como la publica hoy RSF en sus CSV) y '2022'
-- (nueva metodología, 0-100, 100 = mejor). El puesto sí se puede seguir en toda la serie,
-- con la cautela de que el número de países clasificados cambia (n_paises).
-- RSF no ofrece licencia abierta (todos los derechos reservados): se reproducen las
-- puntuaciones y puestos oficiales tal cual, sin medias ni reescalados propios.
-- puesto_ue / n_ue: orden de los puestos oficiales entre los 27 países que hoy forman la
-- UE con dato esa edición (1 = mejor), no una puntuación nueva.
-- es_referencia: países que la página enseña en las gráficas. Países: cod_pais ISO alfa-2
-- (seed paises_iso); solo los de ese seed.
with referencia (cod_pais, orden_pais) as (
    values ('ES', 1), ('FR', 4), ('DE', 5), ('IT', 6), ('PT', 7), ('NL', 8), ('FI', 9),
           ('DK', 10), ('HU', 11), ('GR', 12), ('GB', 13), ('US', 14), ('MA', 15)
),

base as (
    select
        cast(r.edicion as integer) as edicion,
        r.etiqueta_edicion,
        r.escala,
        p.cod_pais,
        p.pais,
        p.es_ue,
        r.puntuacion as global_puntuacion, r.puesto as global_puesto,
        r.politico_puntuacion, r.politico_puesto,
        r.economico_puntuacion, r.economico_puesto,
        r.legislativo_puntuacion, r.legislativo_puesto,
        r.social_puntuacion, r.social_puesto,
        r.seguridad_puntuacion, r.seguridad_puesto
    from {{ source('raw_medios_libertad', 'medios_libertad_rsf') }} r
    join {{ ref('paises_iso') }} p on p.iso3 = r.cod_pais and not p.es_agregado
),

n_paises as (
    select cast(edicion as integer) as edicion, cast(count(*) as integer) as n_paises
    from {{ source('raw_medios_libertad', 'medios_libertad_rsf') }}
    group by 1
),

largo as (
    select edicion, etiqueta_edicion, escala, cod_pais, pais, es_ue, 'global' as indicador, 1 as orden_indicador,
           global_puntuacion as puntuacion, global_puesto as puesto from base
    union all select edicion, etiqueta_edicion, escala, cod_pais, pais, es_ue, 'politico', 2, politico_puntuacion, politico_puesto from base
    union all select edicion, etiqueta_edicion, escala, cod_pais, pais, es_ue, 'economico', 3, economico_puntuacion, economico_puesto from base
    union all select edicion, etiqueta_edicion, escala, cod_pais, pais, es_ue, 'legislativo', 4, legislativo_puntuacion, legislativo_puesto from base
    union all select edicion, etiqueta_edicion, escala, cod_pais, pais, es_ue, 'social', 5, social_puntuacion, social_puesto from base
    union all select edicion, etiqueta_edicion, escala, cod_pais, pais, es_ue, 'seguridad', 6, seguridad_puntuacion, seguridad_puesto from base
),

con_ue as (
    select
        l.*,
        case when l.es_ue then rank() over (partition by l.indicador, l.edicion, l.es_ue order by l.puesto) end as puesto_ue,
        case when l.es_ue then count(*) over (partition by l.indicador, l.edicion, l.es_ue) end as n_ue
    from largo l
    where l.puntuacion is not null
)

select
    c.indicador,
    case c.indicador
        when 'global' then 'Clasificación global'
        when 'politico' then 'Contexto político'
        when 'economico' then 'Contexto económico'
        when 'legislativo' then 'Marco legal'
        when 'social' then 'Contexto social'
        when 'seguridad' then 'Seguridad de los periodistas'
    end as nombre_indicador,
    c.orden_indicador,
    c.cod_pais,
    c.pais,
    c.es_ue,
    r.cod_pais is not null as es_referencia,
    coalesce(r.orden_pais, 20) as orden_pais,
    c.edicion,
    c.etiqueta_edicion,
    c.escala,
    round(cast(c.puntuacion as double), 2) as puntuacion,
    cast(c.puesto as integer) as puesto_mundial,
    n.n_paises,
    cast(c.puesto_ue as integer) as puesto_ue,
    cast(c.n_ue as integer) as n_ue
from con_ue c
join n_paises n using (edicion)
left join referencia r on r.cod_pais = c.cod_pais
