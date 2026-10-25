-- Detenciones e investigados en España por procedencia (Interior, Portal Estadístico
-- de Criminalidad, tablas 03007 y 03001) por 1.000 residentes de 15 o más años de la
-- misma nacionalidad (INE 56936, a mitad de año), comparadas con las de los españoles.
-- Baja más que la Estadística de Condenados del INE (que solo da continentes): separa el
-- norte de África (Marruecos y Argelia) del resto del continente, Hispanoamérica, y unos
-- 40 países. Qué suma cada procedencia en cada fuente: seed crimen_procedencias.
--
-- tipo: 'total' (todos los extranjeros), 'region' o 'pais'.
--   veces            tasa de la procedencia / tasa de los españoles
--   veces_edad_sexo  corregida por la pirámide de sexo y edad con la curva de
--                    crimen_curva_edad_referencia (detenciones observadas / esperadas)
--   veces_visitantes además suma al denominador los visitantes de esa procedencia presentes
--                    en un día medio (crimen_visitantes_presentes repartido según el país
--                    de residencia de los turistas de Frontur); vacío si Frontur no la separa.
--
-- Cautelas: cuenta detenciones e investigaciones, no personas (una persona puede contar
-- varias veces) ni condenas; incluye a no residentes que no son turistas (personas de
-- paso, trabajadores transfronterizos en Ceuta y Melilla, extranjeros no empadronados);
-- rupturas de serie en 2020 (Mossos) y 2025 (Ertzaintza), comunes a todas las
-- nacionalidades. Europa solo desde 2020 (antes el INE agrupaba con el Reino Unido en la UE).
with mapa as (
    select * from {{ ref('crimen_procedencias') }}
),

detenidos_etiqueta as (
    select anio, nacionalidad as etiqueta, detenidos
    from {{ source('raw_criminalidad', 'ses_detenidos_nacionalidad') }}
    where sexo = 'Ambos sexos' and detenidos is not null
),

detenidos as (
    select m.procedencia, any_value(m.tipo) as tipo, d.anio, sum(m.cuota * d.detenidos) as detenidos
    from detenidos_etiqueta d
    join mapa m on m.fuente = 'mir' and m.etiqueta = d.etiqueta
    group by m.procedencia, d.anio
    union all
    -- españoles = todas las detenciones e investigados - las de extranjeros
    select 'España', 'espanoles', t.anio, t.detenidos - x.detenidos
    from {{ source('raw_criminalidad', 'ses_detenidos_total') }} t
    join detenidos_etiqueta x on x.anio = t.anio and x.etiqueta = 'TOTAL'
),

poblacion_enero as (
    select
        nacionalidad as etiqueta, anio, sexo,
        cast(regexp_extract(edad, '([0-9]+)', 1) as integer) as grupo_desde,
        poblacion
    from {{ source('raw_criminalidad', 'ine_poblacion_pais') }}
    where sexo in ('Hombres', 'Mujeres')
      and edad <> 'Todas las edades'
      and cast(regexp_extract(edad, '([0-9]+)', 1) as integer) >= 15
      and poblacion is not null
),

poblacion_grupo as (
    select
        m.procedencia, p.anio, p.sexo, least(p.grupo_desde, 85) as grupo_desde,
        sum(m.cuota * p.poblacion) as poblacion
    from poblacion_enero p
    join (select procedencia, etiqueta, cuota from mapa where fuente = 'ine'
          union all select 'España', 'Española', 1) m on m.etiqueta = p.etiqueta
    group by all
),

-- mitad de año: media con el 1 de enero siguiente; el último año se extrapola y
-- Europa en 2020 toma el 1-1-2021
poblacion_media as (
    select
        procedencia, anio, sexo, grupo_desde,
        coalesce(
            (poblacion + lead(poblacion) over w) / 2,
            poblacion * sqrt(poblacion / nullif(lag(poblacion) over w, 0)),
            lead(poblacion) over w
        ) as poblacion
    from poblacion_grupo
    window w as (partition by procedencia, sexo, grupo_desde order by anio)
),

-- años de detenciones sin población propia (el último): se repite la extrapolación
anios as (
    select distinct anio from detenidos
),

poblacion_anio as (
    select a.anio, p.procedencia, p.sexo, p.grupo_desde, p.poblacion
    from anios a
    join poblacion_media p
      on p.anio = (select max(q.anio) from poblacion_media q where q.anio <= a.anio)
),

poblacion as (
    select
        p.anio, p.procedencia,
        sum(p.poblacion) as poblacion_15,
        sum(p.poblacion * c.tasa) as esperados
    from poblacion_anio p
    join {{ ref('crimen_curva_edad_referencia') }} c on c.sexo = p.sexo and c.grupo_desde = p.grupo_desde
    group by p.anio, p.procedencia
),

-- tasa de referencia media de toda la población de 15 o más (para los visitantes)
referencia as (
    select anio, sum(esperados) / sum(poblacion_15) as tasa_media
    from poblacion
    where procedencia in ('España', 'Todos los extranjeros')
    group by anio
),

turistas as (
    select
        f.anyo as anio, m.procedencia,
        sum(m.cuota * f.valor) as turistas
    from {{ source('raw_criminalidad', 'ine_frontur_pais_anual') }} f
    join mapa m on m.fuente = 'frontur' and m.etiqueta = split_part(f.serie, '. ', 1)
    where f.serie like '%. Dato base.%' and f.valor is not null
    group by f.anyo, m.procedencia
),

visitantes as (
    select t.anio, t.procedencia, v.presentes * t.turistas / tt.turistas as visitantes
    from turistas t
    join turistas tt on tt.anio = t.anio and tt.procedencia = 'Todos los extranjeros'
    join {{ ref('crimen_visitantes_presentes') }} v on v.anio = t.anio
),

tasas as (
    select
        d.procedencia, d.tipo, d.anio, d.detenidos,
        p.poblacion_15, p.esperados,
        v.visitantes,
        r.tasa_media
    from detenidos d
    join poblacion p using (procedencia, anio)
    join referencia r using (anio)
    left join visitantes v using (procedencia, anio)
    where p.poblacion_15 > 0
),

espanoles as (
    select * from tasas where procedencia = 'España'
)

select
    x.anio,
    x.tipo,
    x.procedencia,
    x.detenidos,
    round(x.poblacion_15) as poblacion_15,
    round(x.visitantes) as visitantes_presentes,
    1000.0 * x.detenidos / x.poblacion_15 as detenidos_por_1000_hab,
    1000.0 * e.detenidos / e.poblacion_15 as espanoles_por_1000_hab,
    (x.detenidos / x.poblacion_15) / (e.detenidos / e.poblacion_15) as veces,
    (x.detenidos / x.esperados) / (e.detenidos / e.esperados) as veces_edad_sexo,
    (x.detenidos / (x.esperados + x.visitantes * x.tasa_media)) / (e.detenidos / e.esperados) as veces_visitantes
from tasas x
join espanoles e using (anio)
where x.procedencia <> 'España'
