-- Sociedades mercantiles constituidas y disueltas cada mes, España y comunidades,
-- desde 1995 (INE, Estadística de Sociedades Mercantiles, tabla 13912; datos del
-- Registro Mercantil). cod: '00' España o código INE de la comunidad.
-- capital_real: capital suscrito por las sociedades constituidas, en euros
-- constantes del año base del deflactor (nominal en miles de euros x 1.000 x IPC
-- medio del año base / IPC del mes; IPC general del INE base 2025, 'ipc_indice').
-- *_12m: suma de los últimos 12 meses (solo si están los 12);
-- *_12m_100k: esa suma por 100.000 habitantes (padrón del año del mes o el último).
with base as (
    select
        case when nivel = 'pais' then '00' else cast(cod_territorio as varchar) end as cod,
        cast(anyo as integer) as anio,
        cast(fk_periodo as integer) as mes,
        v568 as concepto,
        v3 as medida,
        valor
    from {{ source('raw_empresas', 'ine_sm_sociedades') }}
    where nivel in ('pais', 'ccaa') and fk_periodo between 1 and 12
),

mensual as (
    select
        cod,
        anio,
        mes,
        max(valor) filter (where concepto = 'Sociedades Constituídas' and medida = 'Número de Sociedades') as constituidas,
        max(valor) filter (where concepto = 'Disueltas' and medida = 'Número de Sociedades') as disueltas,
        max(valor) filter (where concepto = 'Sociedades Constituídas' and medida = 'Capital') as capital_miles
    from base
    group by all
),

ipc as (
    select cast(year(periodo) as integer) as anio, cast(month(periodo) as integer) as mes, valor as ipc
    from {{ ref('metricas_base') }}
    where metrica_id = 'ipc_indice'
),

deflactor_base as (
    select any_value(anio_base) as anio_base,
           max(ipc_medio) filter (where anio = anio_base) as ipc_base
    from {{ ref('deflactor') }}
),

pob as (
    select cod, anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total' and nivel in ('pais', 'ccaa')
),

rango as (
    select max(anio) as max_anio from pob
),

con_real as (
    select
        m.*,
        make_date(m.anio, m.mes, 1) as fecha,
        m.capital_miles * 1000 * b.ipc_base / i.ipc as capital_real,
        p.poblacion,
        cast(b.anio_base as integer) as anio_euros
    from mensual m
    cross join deflactor_base b
    cross join rango r
    left join ipc i on i.anio = m.anio and i.mes = m.mes
    left join pob p on p.cod = m.cod and p.anio = least(m.anio, r.max_anio)
),

movil as (
    select
        *,
        count(constituidas) over w as meses_12,
        sum(constituidas) over w as constituidas_12m,
        sum(disueltas) over w as disueltas_12m,
        sum(capital_real) over w as capital_real_12m
    from con_real
    window w as (partition by cod order by fecha rows between 11 preceding and current row)
)

select
    cod,
    anio,
    mes,
    fecha,
    constituidas,
    disueltas,
    constituidas - disueltas as saldo,
    capital_miles * 1000 as capital_nominal,
    capital_real,
    case when meses_12 = 12 then constituidas_12m end as constituidas_12m,
    case when meses_12 = 12 then disueltas_12m end as disueltas_12m,
    case when meses_12 = 12 then capital_real_12m end as capital_real_12m,
    case when meses_12 = 12 then 100000.0 * constituidas_12m / poblacion end as constituidas_12m_100k,
    case when meses_12 = 12 then 100000.0 * disueltas_12m / poblacion end as disueltas_12m_100k,
    poblacion,
    anio_euros
from movil
order by cod, fecha
