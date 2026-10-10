-- Presupuesto inicial, definitivo y ejecutado de los gastos de cada comunidad autónoma
-- por capítulo económico, 2002-último ejercicio cerrado: la misma técnica que
-- gasto_oculto_ejecucion pero para todas las comunidades y solo por capítulos.
-- Fuente: Ministerio de Hacienda (SGCIEF), liquidación consolidada de los presupuestos de
-- las CCAA (mart ccaa_cuentas_capitulos; ingestion/hacienda_ccaa.py). Consolidada:
-- administración general, organismos y entes incluidos, sin transferencias internas.
-- - modificaciones_eur = presupuesto definitivo - inicial; obligaciones_eur = obligaciones
--   reconocidas netas.
-- - desviacion_pct = (obligaciones - inicial) / inicial (0-100); modificacion_pct =
--   modificaciones / inicial.
-- - capitulo 0 = 'Total' (capítulos 1-9) para comparar comunidades de un vistazo.
-- - _hab_real: por habitante (padrón del año o el último anterior) en euros constantes de
--   anio_base (main.deflactor).
with capitulos as (
    select
        cod_ccaa, ccaa, anio, capitulo, capitulo_nombre,
        presupuesto_inicial, presupuesto_definitivo, ejecutado
    from {{ ref('ccaa_cuentas_capitulos') }}
    where tipo = 'gasto' and cod_ccaa is not null
),

con_total as (
    select * from capitulos
    union all
    select cod_ccaa, ccaa, anio, 0, 'Total',
        sum(presupuesto_inicial), sum(presupuesto_definitivo), sum(ejecutado)
    from capitulos
    group by all
),

pob as (
    select cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total'
)

select
    c.cod_ccaa,
    c.ccaa,
    cast(c.anio as integer) as anio,
    cast(c.capitulo as integer) as capitulo,
    c.capitulo_nombre,
    c.presupuesto_inicial as credito_inicial_eur,
    c.presupuesto_definitivo - c.presupuesto_inicial as modificaciones_eur,
    c.presupuesto_definitivo as credito_definitivo_eur,
    c.ejecutado as obligaciones_eur,
    c.ejecutado - c.presupuesto_inicial as desviacion_eur,
    case when c.presupuesto_inicial > 0 then 100 * (c.ejecutado - c.presupuesto_inicial) / c.presupuesto_inicial end as desviacion_pct,
    case when c.presupuesto_inicial > 0 then 100 * (c.presupuesto_definitivo - c.presupuesto_inicial) / c.presupuesto_inicial end as modificacion_pct,
    c.presupuesto_inicial * d.factor / p.poblacion as credito_inicial_eur_hab_real,
    c.ejecutado * d.factor / p.poblacion as obligaciones_eur_hab_real,
    (c.ejecutado - c.presupuesto_inicial) * d.factor / p.poblacion as desviacion_eur_hab_real,
    d.anio_base
from con_total as c
asof left join pob as p
  on p.cod = c.cod_ccaa and p.anio <= c.anio
left join {{ ref('deflactor') }} as d
  on d.anio = cast(c.anio as integer)
order by c.anio, c.cod_ccaa, c.capitulo
