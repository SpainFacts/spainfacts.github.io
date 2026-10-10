-- Modificaciones de crédito por entidad, año, capítulo y tipo: de dónde sale y adónde va el
-- dinero que no estaba en la ley de presupuestos. Comunidad de Madrid 2016- y Generalitat de
-- Catalunya 2014-.
-- Fuente Madrid: Cuenta General de la Comunidad de Madrid (Intervención General), memoria de cada
-- entidad con presupuesto limitativo, nota 23.1.1.a «Modificaciones de crédito» por centro (PDF
-- por aplicación económica, sumado aquí a capítulo; ingestion/gasto_oculto.py). El crédito
-- inicial del capítulo sale de la liquidación (gasto_oculto_ejecucion).
-- Fuente Cataluña: «Execució mensual del pressupost de la Generalitat de Catalunya. Despeses»
-- (Socrata ajns-4mi7), último mes de cada ejercicio; ahí créditos extraordinarios y suplementos
-- vienen juntos (van en suplementos_eur) y las transferencias son aumentos + minoraciones.
-- - transferencias_eur: las transferencias de crédito suman cero en el conjunto del presupuesto
--   (en Madrid, anexo 3 de la Cuenta General), así que el saldo de cada entidad dice quién cede
--   crédito (negativo: AMAS, Agencia de Vivienda Social, Administración General...) y quién lo
--   recibe (positivo: SERMAS). Es el origen y destino agregado; la relación de expedientes con
--   origen y destino de cada transferencia no se publica en formato abierto.
-- - generados_ingresos_eur: créditos generados por ingresos (fondos finalistas, MRR, aportaciones
--   de otras entidades); ampliaciones, suplementos y créditos extraordinarios: crédito nuevo.
-- - modificacion_pct = total / crédito inicial (0-100).
-- - _real: euros constantes de anio_base; _hab_real: por habitante de la comunidad.
with m as (
    select
        cast(anio as integer) as anio,
        entidad_cod,
        entidad,
        cast(substr(cast(aplicacion as varchar), 1, 1) as integer) as capitulo,
        sum(coalesce(creditos_extraordinarios, 0)) as creditos_extraordinarios,
        sum(coalesce(suplementos, 0)) as suplementos,
        sum(coalesce(ampliaciones, 0)) as ampliaciones,
        sum(coalesce(transferencias, 0)) as transferencias,
        sum(coalesce(incorporaciones, 0)) as incorporaciones,
        sum(coalesce(generados_ingresos, 0)) as generados_ingresos,
        sum(coalesce(otras, 0)) as otras,
        sum(coalesce(total, 0)) as total
    from {{ source('raw_gasto_oculto', 'gasto_oculto_cm_modificaciones') }}
    where length(cast(aplicacion as varchar)) = 5
    group by all
),

inicial as (
    select anio, entidad_cod, capitulo, max(entidad) as entidad, sum(credito_inicial_eur) as credito_inicial_eur
    from {{ ref('gasto_oculto_ejecucion') }}
    where cod_ccaa = '13'
    group by all
),

madrid as (
    select
        '13' as cod_ccaa,
        'Comunidad de Madrid' as ccaa,
        m.anio,
        12 as meses,
        m.entidad_cod,
        coalesce(i.entidad, case
            when m.entidad ilike '%SERMAS%' then 'Servicio Madrileño de Salud (SERMAS)'
            when m.entidad ilike 'Administraci_n de la Comunidad%' then 'Administración de la Comunidad de Madrid'
            else trim(m.entidad) end) as entidad,
        m.capitulo,
        i.credito_inicial_eur,
        m.creditos_extraordinarios, m.suplementos, m.ampliaciones, m.transferencias,
        m.incorporaciones, m.generados_ingresos, m.otras, m.total
    from m
    left join inicial as i
      on i.anio = m.anio and i.entidad_cod = m.entidad_cod and i.capitulo = m.capitulo
),

cataluna as (
    select
        '09' as cod_ccaa,
        'Cataluña' as ccaa,
        cast(anio as integer) as anio,
        max(cast(mes_num as integer)) as meses,
        'CAT' || entitat_codi as entidad_cod,
        entitat as entidad,
        cast(cap_tol_codi as integer) as capitulo,
        sum(cr_dits_inicials) as credito_inicial_eur,
        0.0 as creditos_extraordinarios,
        sum(coalesce(cr_dits_extraord_supl_de_cr_dit, 0)) as suplementos,
        sum(coalesce(ampliacions_de_cr_dit, 0)) as ampliaciones,
        sum(coalesce(augments_per_transfer_ncia, 0) + coalesce(minoracions_per_transfer_ncia, 0)) as transferencias,
        sum(coalesce(incorporaci_de_romanents_de_cr_dit, 0)) as incorporaciones,
        sum(coalesce(generacions_de_cr_dit, 0)) as generados_ingresos,
        sum(pressupost_definitiu - cr_dits_inicials
            - coalesce(cr_dits_extraord_supl_de_cr_dit, 0) - coalesce(ampliacions_de_cr_dit, 0)
            - coalesce(augments_per_transfer_ncia, 0) - coalesce(minoracions_per_transfer_ncia, 0)
            - coalesce(incorporaci_de_romanents_de_cr_dit, 0) - coalesce(generacions_de_cr_dit, 0)) as otras,
        sum(pressupost_definitiu - cr_dits_inicials) as total
    from {{ source('raw_gasto_oculto', 'gasto_oculto_cat_execucio') }}
    group by cast(anio as integer), 'CAT' || entitat_codi, entitat, cast(cap_tol_codi as integer)
),

todo as (
    select * from madrid
    union all
    select * from cataluna
),

pob as (
    select cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total'
),

capitulos(capitulo, capitulo_nombre) as (
    values (1, 'Gastos de personal'), (2, 'Gastos corrientes en bienes y servicios'), (3, 'Gastos financieros'),
           (4, 'Transferencias corrientes'), (5, 'Fondo de contingencia'), (6, 'Inversiones reales'),
           (7, 'Transferencias de capital'), (8, 'Activos financieros'), (9, 'Pasivos financieros')
)

select
    t.cod_ccaa,
    t.ccaa,
    t.anio,
    t.meses,
    t.meses < 12 as es_parcial,
    t.entidad_cod,
    t.entidad,
    t.capitulo,
    k.capitulo_nombre,
    t.credito_inicial_eur,
    t.creditos_extraordinarios as creditos_extraordinarios_eur,
    t.suplementos as suplementos_eur,
    t.ampliaciones as ampliaciones_eur,
    t.transferencias as transferencias_eur,
    t.incorporaciones as incorporaciones_eur,
    t.generados_ingresos as generados_ingresos_eur,
    t.otras as otras_eur,
    t.total as total_modificaciones_eur,
    case when t.credito_inicial_eur > 0 then 100 * t.total / t.credito_inicial_eur end as modificacion_pct,
    case when t.credito_inicial_eur > 0 then 100 * t.transferencias / t.credito_inicial_eur end as transferencias_pct,
    t.transferencias * d.factor as transferencias_eur_real,
    t.generados_ingresos * d.factor as generados_ingresos_eur_real,
    t.total * d.factor as total_modificaciones_eur_real,
    t.transferencias * d.factor / p.poblacion as transferencias_eur_hab_real,
    t.total * d.factor / p.poblacion as total_modificaciones_eur_hab_real,
    d.anio_base
from todo as t
left join capitulos as k
  on k.capitulo = t.capitulo
asof left join pob as p
  on p.cod = t.cod_ccaa and p.anio <= t.anio
left join {{ ref('deflactor') }} as d
  on d.anio = t.anio
order by t.cod_ccaa, t.anio, t.entidad, t.capitulo
