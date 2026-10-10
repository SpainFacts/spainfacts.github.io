-- Presupuesto inicial frente a ejecutado por entidad y partida económica: Comunidad de Madrid
-- (subconcepto, 2016-) y Generalitat de Catalunya (concepto y programa, 2014-).
-- Fuente Madrid: Cuenta General de la Comunidad de Madrid (Intervención General), cuentas
-- anuales de cada entidad con presupuesto limitativo (Administración de la Comunidad,
-- SERMAS, AMAS, Agencia de Vivienda Social...), estado E.1 «Liquidación del presupuesto
-- de gastos» por centro (PDF; ingestion/gasto_oculto.py, cuadrado con la fila TOTAL).
-- - credito_inicial_eur: lo que aprobó la Asamblea en la ley de presupuestos.
-- - modificaciones_eur / credito_definitivo_eur: lo que el Gobierno añade o quita durante el
--   año (transferencias, generaciones, ampliaciones...) y el crédito que queda.
-- - obligaciones_eur: obligaciones reconocidas netas (gasto ejecutado).
-- - desviacion_eur = obligaciones - crédito inicial; desviacion_pct = desviación / crédito
--   inicial (0-100; NULL si el crédito inicial es 0: partidas que nacen durante el año).
-- - partida: grupo de análisis por la descripción (las descripciones vienen recortadas en el
--   PDF; se usa la más larga del año entre entidades y estados): conciertos con la Fundación
--   Jiménez Díaz, hospitales de gestión privada (concesiones de servicio), resto de conciertos
--   de asistencia sanitaria con medios ajenos (artículo 25), canon de los hospitales de
--   concesión de obra (arrendamiento operativo de centros hospitalarios), intereses de demora
--   (concepto 342) y el resto por capítulo.
-- - _real: euros constantes de anio_base (main.deflactor); _hab_real: por habitante de la
--   Comunidad de Madrid (padrón del año, o el último anterior).
-- programa = 'Total' en Madrid: la Cuenta General liquida por centro y aplicación económica, sin
-- programa.
-- Fuente Cataluña: «Execució mensual del pressupost de la Generalitat de Catalunya. Despeses»
-- (Socrata ajns-4mi7), último mes publicado de cada ejercicio (diciembre en los cerrados; meses
-- < 12 = año en curso), agregado a entidad (Generalitat, CatSalut, ICS...), sección, programa y
-- concepto (subconcepto NULL). Partidas: 251 prestación de servicios con medios ajenos (conciertos
-- sanitarios, solo en CatSalut, ICS y secciones de salud: en otras entidades son servicios externalizados), 489 farmacia por receta, 488 conciertos educativos.
with liq as (
    select
        cast(anio as integer) as anio,
        entidad_cod,
        entidad,
        cast(aplicacion as varchar) as aplicacion,
        descripcion,
        credito_inicial,
        modificaciones,
        credito_definitivo,
        gastos_comprometidos,
        obligaciones_netas,
        pagos,
        pendiente_pago,
        remanentes,
        url
    from {{ source('raw_gasto_oculto', 'gasto_oculto_cm_liquidacion') }}
    where length(cast(aplicacion as varchar)) = 5
),

descripciones as (
    select anio, aplicacion, max_by(descripcion, length(descripcion)) as descripcion
    from (
        select cast(anio as integer) as anio, cast(aplicacion as varchar) as aplicacion, descripcion
        from {{ source('raw_gasto_oculto', 'gasto_oculto_cm_liquidacion') }}
        union all
        select cast(anio as integer), cast(aplicacion as varchar), descripcion
        from {{ source('raw_gasto_oculto', 'gasto_oculto_cm_modificaciones') }}
    )
    where descripcion is not null
    group by all
),

cat as (
    select
        cast(anio as integer) as anio,
        cast(mes_num as integer) as meses,
        'CAT' || entitat_codi as entidad_cod,
        entitat as entidad,
        secci as seccion,
        coalesce(programa_codi || ' ' || programa, programa, 'Sin programa') as programa,
        cast(cap_tol_codi as integer) as capitulo,
        article_codi as articulo,
        concepte_codi as concepto,
        concepte as descripcion,
        sum(cr_dits_inicials) as credito_inicial,
        sum(pressupost_definitiu - cr_dits_inicials) as modificaciones,
        sum(pressupost_definitiu) as credito_definitivo,
        sum(disposicions) as gastos_comprometidos,
        sum(obligacions_reconegudes) as obligaciones_netas,
        sum(obligacions_pagades) as pagos
    from {{ source('raw_gasto_oculto', 'gasto_oculto_cat_execucio') }}
    group by all
),

pob_cat as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and cod = '09' and sexo = 'Total'
),

pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and cod = '13' and sexo = 'Total'
),

base as (
    select
        l.*,
        coalesce(d.descripcion, l.descripcion) as descripcion_larga,
        case
            when l.entidad ilike '%SERMAS%' or l.entidad ilike '%Madrile_o de Salud%' then 'Servicio Madrileño de Salud (SERMAS)'
            when l.entidad ilike 'Administraci_n de la Comunidad%' then 'Administración de la Comunidad de Madrid'
            else trim(l.entidad)
        end as seccion,
        cast(substr(l.aplicacion, 1, 1) as integer) as capitulo,
        substr(l.aplicacion, 1, 2) as articulo,
        substr(l.aplicacion, 1, 3) as concepto
    from liq as l
    left join descripciones as d
      on d.anio = l.anio and d.aplicacion = l.aplicacion
),

clasificado as (
    select
        *,
        case
            when strip_accents(upper(descripcion_larga)) like '%JIMENEZ DIAZ%' then 'Conciertos con la Fundación Jiménez Díaz'
            when articulo = '25' and strip_accents(upper(descripcion_larga)) like 'HOSPITAL%' then 'Hospitales de gestión privada (concesiones)'
            when articulo = '25' then 'Conciertos de asistencia sanitaria'
            when articulo = '20' and strip_accents(upper(descripcion_larga)) similar to '.*(HOSPIT|CENTR.*HOSP).*' then 'Canon de hospitales de concesión de obra'
            when concepto = '342' or strip_accents(upper(descripcion_larga)) like '%DEMORA%' then 'Intereses de demora'
            when strip_accents(upper(descripcion_larga)) like '%RECETA%' then 'Farmacia por receta'
            when strip_accents(upper(descripcion_larga)) like '%CONCIERTO%EDUCA%' or strip_accents(upper(descripcion_larga)) like '%CENTROS CONCERTADOS%' then 'Conciertos educativos'
            else 'Resto del capítulo ' || capitulo
        end as partida
    from base
),

madrid as (
    select
        '13' as cod_ccaa,
        'Comunidad de Madrid' as ccaa,
        c.anio,
        12 as meses,
        c.entidad_cod,
        c.seccion as entidad,
        c.seccion,
        'Total' as programa,
        c.capitulo,
        c.articulo,
        c.concepto,
        c.aplicacion as subconcepto,
        c.descripcion_larga as descripcion,
        c.partida,
        c.credito_inicial, c.modificaciones, c.credito_definitivo, c.gastos_comprometidos,
        c.obligaciones_netas, c.pagos, c.pendiente_pago, c.remanentes,
        p.poblacion,
        c.url as fuente_url
    from clasificado as c
    asof left join pob as p
      on p.anio <= c.anio
),

cataluna as (
    select
        '09' as cod_ccaa,
        'Cataluña' as ccaa,
        c.anio,
        c.meses,
        c.entidad_cod,
        c.entidad,
        c.seccion,
        c.programa,
        c.capitulo,
        c.articulo,
        c.concepto,
        cast(null as varchar) as subconcepto,
        c.descripcion,
        case
            when c.concepto = '251' and (c.entidad in ('CatSalut', 'ICS') or c.seccion ilike '%salut%') then 'Conciertos de asistencia sanitaria'
            when c.concepto = '489' then 'Farmacia por receta'
            when c.concepto = '488' then 'Conciertos educativos'
            when strip_accents(upper(c.descripcion)) like '%DEMORA%' then 'Intereses de demora'
            else 'Resto del capítulo ' || c.capitulo
        end as partida,
        c.credito_inicial, c.modificaciones, c.credito_definitivo, c.gastos_comprometidos,
        c.obligaciones_netas, c.pagos,
        c.obligaciones_netas - c.pagos as pendiente_pago,
        c.credito_definitivo - c.obligaciones_netas as remanentes,
        p.poblacion,
        'https://analisi.transparenciacatalunya.cat/d/ajns-4mi7' as fuente_url
    from cat as c
    asof left join pob_cat as p
      on p.anio <= c.anio
),

todo as (
    select * from madrid
    union all
    select * from cataluna
)

select
    t.cod_ccaa,
    t.ccaa,
    t.anio,
    t.meses,
    t.meses < 12 as es_parcial,
    t.entidad_cod,
    t.entidad,
    t.seccion,
    t.programa,
    t.capitulo,
    t.articulo,
    t.concepto,
    t.subconcepto,
    t.descripcion,
    t.partida,
    t.credito_inicial as credito_inicial_eur,
    t.modificaciones as modificaciones_eur,
    t.credito_definitivo as credito_definitivo_eur,
    t.gastos_comprometidos as gastos_comprometidos_eur,
    t.obligaciones_netas as obligaciones_eur,
    t.pagos as pagos_eur,
    t.pendiente_pago as pendiente_pago_eur,
    t.remanentes as remanentes_eur,
    t.obligaciones_netas - t.credito_inicial as desviacion_eur,
    case when t.credito_inicial > 0 then 100 * (t.obligaciones_netas - t.credito_inicial) / t.credito_inicial end as desviacion_pct,
    case when t.credito_inicial > 0 then 100 * t.modificaciones / t.credito_inicial end as modificacion_pct,
    t.credito_inicial * d.factor as credito_inicial_eur_real,
    t.obligaciones_netas * d.factor as obligaciones_eur_real,
    (t.obligaciones_netas - t.credito_inicial) * d.factor as desviacion_eur_real,
    t.credito_inicial * d.factor / t.poblacion as credito_inicial_eur_hab_real,
    t.obligaciones_netas * d.factor / t.poblacion as obligaciones_eur_hab_real,
    (t.obligaciones_netas - t.credito_inicial) * d.factor / t.poblacion as desviacion_eur_hab_real,
    d.anio_base,
    t.fuente_url
from todo as t
left join {{ ref('deflactor') }} as d
  on d.anio = t.anio
order by t.cod_ccaa, t.anio, t.entidad, t.concepto, t.subconcepto
