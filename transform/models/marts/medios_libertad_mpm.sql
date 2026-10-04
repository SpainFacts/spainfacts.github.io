-- Media Pluralism Monitor (MPM) del Centre for Media Pluralism and Media Freedom (EUI,
-- Florencia), riesgo para el pluralismo de los medios por país, edición y área.
-- Una fila por país, edición y área. riesgo_pct: 0 = sin riesgo, 100 = riesgo máximo
-- (más alto = peor).
--
-- Ediciones: MPM2016, MPM2017 y MPM2020-MPM2024 transcritas del índice de cada informe
-- país en PDF (seed medios_libertad_mpm_historico, con el handle de Cadmus de cada fila);
-- MPM2025 solo España (gráfico del informe país); la edición en curso, de las fichas de
-- país de cmpf.eui.eu (raw medios_libertad_mpm), que sustituye al seed si coinciden.
-- La edición N evalúa el año N-1 (MPM2020 cubre 2018-2019; MPM2016 y MPM2017, sus propios
-- años): periodo_datos.
-- Áreas: proteccion_fundamental (hasta 2020 «Basic Protection»), pluralidad_mercado,
-- independencia_politica, inclusion_social y total. El total de las ediciones con ficha
-- web es el publicado por el CMPF; en las demás es la media simple de las cuatro áreas,
-- que es como el CMPF calcula el riesgo global desde 2022 (cálculo propio, CC BY 4.0).
-- banda: hasta MPM2024 tres tramos (bajo 0-33, medio 34-66, alto 67-100); desde MPM2025,
-- seis (muy bajo 0-16, bajo 17-33, medio-bajo 34-50, medio-alto 51-66, alto 67-83, muy
-- alto 84-100). El cuestionario cambia en cada edición: las variaciones de pocos puntos
-- entre ediciones no son comparables en sentido estricto.
-- EU27_2020: media simple de los países que hoy forman la UE con dato esa edición (solo
-- si están los 27). puesto_ue / n_ue: posición entre ellos (1 = menor riesgo), solo en
-- las ediciones con los 27 países.
with historico as (
    select cast(edicion as integer) as edicion, cod_pais, area, cast(riesgo_pct as double) as riesgo_pct,
           fuente as url_fuente, 'informe país (PDF)' as origen
    from {{ ref('medios_libertad_mpm_historico') }}
),

web as (
    select cast(m.edicion as integer) as edicion, n.cod_pais, m.area, cast(m.riesgo_pct as double) as riesgo_pct,
           m.url as url_fuente, 'ficha web del CMPF' as origen
    from {{ source('raw_medios_libertad', 'medios_libertad_mpm') }} m
    join {{ ref('medios_libertad_paises_nombres') }} n on n.nombre_fuente = m.pais_fuente
),

areas as (
    select * from web
    union all
    select h.* from historico h
    where not exists (select 1 from web w where w.edicion = h.edicion and w.cod_pais = h.cod_pais)
),

totales as (
    -- total calculado solo donde la fuente no lo publica y están las cuatro áreas
    select edicion, cod_pais, 'total' as area, avg(riesgo_pct) as riesgo_pct, min(url_fuente) as url_fuente,
           'media de las 4 áreas' as origen
    from areas a
    where area <> 'total'
      and not exists (select 1 from areas t where t.area = 'total' and t.edicion = a.edicion and t.cod_pais = a.cod_pais)
    group by edicion, cod_pais
    having count(*) = 4
),

todo as (
    select a.*, p.pais, p.es_ue
    from (select * from areas union all select * from totales) a
    join {{ ref('paises_iso') }} p on p.cod_pais = a.cod_pais
),

con_puesto as (
    select t.*,
        case when t.es_ue then rank() over (partition by t.edicion, t.area, t.es_ue order by t.riesgo_pct) end as puesto_ue,
        case when t.es_ue then count(*) over (partition by t.edicion, t.area, t.es_ue) end as n_ue
    from todo t
),

ue as (
    select edicion, 'EU27_2020' as cod_pais, 'Unión Europea (media simple)' as pais, area, avg(riesgo_pct) as riesgo_pct
    from todo
    where es_ue
    group by edicion, area
    having count(*) = 27
),

final as (
    select edicion, cod_pais, pais, false as es_agregado, es_ue, area, riesgo_pct, url_fuente, origen,
           cast(puesto_ue as integer) as puesto_ue, cast(n_ue as integer) as n_ue
    from con_puesto
    union all
    select edicion, cod_pais, pais, true, false, area, riesgo_pct, null, 'media simple UE-27', null, null
    from ue
)

select
    f.edicion,
    'MPM' || cast(f.edicion as varchar) as etiqueta_edicion,
    case when f.edicion = 2020 then '2018-2019'
         when f.edicion <= 2017 then cast(f.edicion as varchar)
         else cast(f.edicion - 1 as varchar) end as periodo_datos,
    f.cod_pais,
    f.pais,
    f.es_agregado,
    f.es_ue,
    f.area,
    case f.area
        when 'total' then 'Riesgo global'
        when 'proteccion_fundamental' then 'Protección fundamental'
        when 'pluralidad_mercado' then 'Pluralidad del mercado'
        when 'independencia_politica' then 'Independencia política'
        when 'inclusion_social' then 'Inclusión social'
    end as nombre_area,
    case f.area when 'total' then 0 when 'proteccion_fundamental' then 1 when 'pluralidad_mercado' then 2
        when 'independencia_politica' then 3 else 4 end as orden_area,
    round(f.riesgo_pct, 1) as riesgo_pct,
    case
        when f.edicion <= 2024 then
            case when round(f.riesgo_pct) <= 33 then 'Bajo' when round(f.riesgo_pct) <= 66 then 'Medio' else 'Alto' end
        else
            case when round(f.riesgo_pct) <= 16 then 'Muy bajo' when round(f.riesgo_pct) <= 33 then 'Bajo'
                 when round(f.riesgo_pct) <= 50 then 'Medio-bajo' when round(f.riesgo_pct) <= 66 then 'Medio-alto'
                 when round(f.riesgo_pct) <= 83 then 'Alto' else 'Muy alto' end
    end as banda,
    f.origen,
    f.url_fuente,
    -- puesto solo en las ediciones con los 27 evaluados (en MPM2025 solo hay España)
    case when f.n_ue = 27 then f.puesto_ue end as puesto_ue,
    case when f.n_ue = 27 then f.n_ue end as n_ue
from final f
