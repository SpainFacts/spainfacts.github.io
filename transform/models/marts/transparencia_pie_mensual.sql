-- Retención de la participación en los tributos del Estado (PIE) por no
-- remitir información a Hacienda: stock mensual de ayuntamientos retenidos.
--
-- Una fila por (periodo, cod_mun, seccion). Fuente: relación mensual de la
-- OVEELL (art. 36.1 de la Ley 2/2011 y DA 87ª de la Ley 22/2021):
--   liquidacion           liquidación del presupuesto (TRLRHL art. 193.5)
--   presupuesto           presupuesto del ejercicio corriente (antes del 1 de julio)
--   lineas_fundamentales  líneas fundamentales del presupuesto del año siguiente
--                         (antes del 15 de septiembre)
-- Cada lista mensual es un stock (quién sigue retenido ese mes), no un flujo.
--
-- Hasta octubre de 2022 los PDF solo traen el nombre y la provincia: se cruzan
-- con el INE por nombre normalizado (sin tildes, artículo delante, cualquiera
-- de las formas bilingües "A/B") dentro de la provincia, usando también los
-- nombres con código de los PDF posteriores (misma grafía de Hacienda); si no
-- hay coincidencia exacta y única, la más parecida (Jaro-Winkler >= 0,93).
-- En ese formato el ejercicio de referencia no se indica: se infiere de la
-- campaña (la lista se renueva cuando crece de golpe, en mayo-octubre, y cada
-- campaña de retenciones del año A corresponde a la liquidación de A-2, como
-- en los PDF posteriores: junio de 2023 -> liquidación de 2021).
--
-- Importes: el Excel de entregas a cuenta da los euros retenidos por el art.
-- 36 a cada ayuntamiento y mes, sin distinguir la sección; si un ayuntamiento
-- está retenido por varias secciones el mismo mes, el importe se reparte a
-- partes iguales (importe_compartido = true) para no contarlo dos veces.
with raw as (
    select
        cast(periodo as date) as periodo,
        seccion,
        cast(ejercicio_referencia as integer) as ejercicio_referencia,
        tipo_entidad,
        cod_prov,
        cod_mun,
        nombre,
        coalesce(por_dependientes, false) as por_dependientes,
        fuente_pdf
    from {{ source('raw_hacienda_transparencia', 'pie_retenciones') }}
    where tipo_entidad = 'AA' or tipo_entidad is null
),

-- Diccionario de nombres: INE (todas las grafías históricas) + PDF con código
-- (prioridad 1 el INE; los nombres de los PDF solo si el INE no casa, porque
-- a veces vienen partidos: "San Esteban de" / "Gormaz")
nombres as (
    select distinct cod_mun, cod_prov, municipio as nombre, 1 as prioridad
    from {{ ref('poblacion_municipios') }}
    union
    select distinct cod_mun, cod_prov, nombre, 2 as prioridad
    from raw
    where cod_mun is not null and nombre <> ''
),

diccionario as (
    select distinct
        cod_prov,
        cod_mun,
        prioridad,
        trim(regexp_replace(strip_accents(lower(regexp_replace(trim(alt),
            '^(.*?)\s*[,(]\s*(el|la|los|las|l''|els|les|lo|o|a|os|as|es|sa|ses|s'')\s*\)?\s*$',
            '\2 \1', 'i'))), '[^a-z0-9]+', ' ', 'g')) as clave_nombre
    from (select cod_prov, cod_mun, prioridad, unnest(string_split(nombre, '/')) as alt from nombres)
),

sin_codigo as (
    select distinct
        cod_prov,
        nombre,
        trim(regexp_replace(strip_accents(lower(regexp_replace(trim(alt),
            '^(.*?)\s*[,(]\s*(el|la|los|las|l''|els|les|lo|o|a|os|as|es|sa|ses|s'')\s*\)?\s*$',
            '\2 \1', 'i'))), '[^a-z0-9]+', ' ', 'g')) as clave_nombre
    from (select distinct cod_prov, nombre, unnest(string_split(nombre, '/')) as alt from raw where cod_mun is null)
),

exacto as (
    select s.cod_prov, s.nombre, d.prioridad, min(d.cod_mun) as cod_mun, count(distinct d.cod_mun) as candidatos
    from sin_codigo s
    join diccionario d on d.cod_prov = s.cod_prov and d.clave_nombre = s.clave_nombre
    group by s.cod_prov, s.nombre, d.prioridad
    qualify d.prioridad = min(d.prioridad) over (partition by s.cod_prov, s.nombre)
),

aproximado as (
    select s.cod_prov, s.nombre, d.cod_mun,
        jaro_winkler_similarity(s.clave_nombre, d.clave_nombre) as similitud
    from sin_codigo s
    join diccionario d on d.cod_prov = s.cod_prov
    where not exists (select 1 from exacto e where e.cod_prov = s.cod_prov and e.nombre = s.nombre)
      and jaro_winkler_similarity(s.clave_nombre, d.clave_nombre) >= 0.93
    qualify row_number() over (partition by s.cod_prov, s.nombre order by similitud desc, d.cod_mun) = 1
),

cruce as (
    select cod_prov, nombre, cod_mun, 'nombre' as metodo from exacto where candidatos = 1
    union all
    select cod_prov, nombre, cod_mun, 'nombre_aproximado' from aproximado
),

con_codigo as (
    select
        r.periodo, r.seccion, r.ejercicio_referencia, r.cod_prov,
        coalesce(r.cod_mun, c.cod_mun) as cod_mun,
        r.nombre, r.por_dependientes, r.fuente_pdf,
        case when r.cod_mun is not null then 'codigo' else c.metodo end as metodo_cruce
    from raw r
    left join cruce c on r.cod_mun is null and c.cod_prov = r.cod_prov and c.nombre = r.nombre
),

-- Campañas del formato antiguo (solo liquidación): empieza una cuando la lista
-- crece al menos un 50 % respecto al mes anterior (o es el primer mes)
tamanos as (
    select periodo, count(*) as n
    from con_codigo
    where seccion = 'liquidacion'
    group by periodo
),

campanias as (
    select periodo,
        max(case when lag_n is null or n >= 1.5 * lag_n then periodo end)
            over (order by periodo rows between unbounded preceding and current row) as inicio_campania
    from (select *, lag(n) over (order by periodo) as lag_n from tamanos)
),

importes as (
    select cast(periodo as date) as periodo, cod_mun, sum(retencion_art36_eur) as importe_eur
    from {{ source('raw_hacienda_transparencia', 'pie_retenciones_importes') }}
    group by all
),

final as (
    -- Una sola fila por (periodo, cod_mun, seccion) aunque dos nombres del PDF
    -- antiguo cayeran en el mismo municipio
    select
        c.periodo,
        c.seccion,
        coalesce(
            c.ejercicio_referencia,
            case when c.seccion = 'liquidacion' then year(k.inicio_campania) - 2 end
        ) as ejercicio_referencia,
        c.ejercicio_referencia is null as ejercicio_inferido,
        c.cod_mun,
        c.cod_prov,
        c.nombre as nombre_pdf,
        c.por_dependientes,
        c.metodo_cruce,
        c.fuente_pdf
    from con_codigo c
    left join campanias k on k.periodo = c.periodo and c.seccion = 'liquidacion'
    where c.cod_mun is not null
    qualify row_number() over (partition by c.periodo, c.cod_mun, c.seccion order by c.por_dependientes desc) = 1
)

select
    f.*,
    count(*) over (partition by f.periodo, f.cod_mun) as secciones_mes,
    i.importe_eur as importe_mes_eur,
    i.importe_eur / count(*) over (partition by f.periodo, f.cod_mun) as importe_eur,
    count(*) over (partition by f.periodo, f.cod_mun) > 1 and i.importe_eur is not null as importe_compartido,
    f.periodo || '-' || f.cod_mun || '-' || f.seccion as clave
from final f
left join importes i on i.periodo = f.periodo and i.cod_mun = f.cod_mun
