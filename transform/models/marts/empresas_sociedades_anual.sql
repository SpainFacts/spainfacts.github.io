-- Sociedades mercantiles constituidas y disueltas por año, España y comunidades,
-- desde 1995 (INE, Estadística de Sociedades Mercantiles, tabla 13912). Solo años
-- con los 12 meses publicados.
-- Por 100.000 habitantes con el padrón a 1 de enero del año (main.poblacion_territorios;
-- años posteriores al último padrón usan el último). capital_real: capital suscrito
-- por las nuevas sociedades en euros constantes (nominal x factor de main.deflactor,
-- IPC medio anual); capital_medio_real = capital_real / constituidas;
-- capital_real_hab = capital_real / población.
-- ratio_disueltas = disueltas por cada 100 constituidas.
with mensual as (
    select * from {{ ref('empresas_sociedades_mensual') }}
),

anual as (
    select
        cod,
        anio,
        count(*) as meses,
        sum(constituidas) as constituidas,
        sum(disueltas) as disueltas,
        sum(capital_nominal) as capital_nominal
    from mensual
    group by all
    having count(constituidas) = 12
),

pob as (
    select cod, anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total' and nivel in ('pais', 'ccaa')
),

rango as (
    select max(anio) as max_anio, min(anio) as min_anio from pob
)

select
    a.cod,
    a.anio,
    a.constituidas,
    a.disueltas,
    a.constituidas - a.disueltas as saldo,
    100000.0 * a.constituidas / p.poblacion as constituidas_100k,
    100000.0 * a.disueltas / p.poblacion as disueltas_100k,
    100000.0 * (a.constituidas - a.disueltas) / p.poblacion as saldo_100k,
    100.0 * a.disueltas / a.constituidas as ratio_disueltas,
    a.capital_nominal,
    a.capital_nominal * d.factor as capital_real,
    a.capital_nominal * d.factor / a.constituidas as capital_medio_real,
    a.capital_nominal * d.factor / p.poblacion as capital_real_hab,
    p.poblacion,
    cast(d.anio_base as integer) as anio_euros
from anual a
cross join rango r
left join pob p on p.cod = a.cod and p.anio = greatest(least(a.anio, r.max_anio), r.min_anio)
left join {{ ref('deflactor') }} d on d.anio = a.anio
order by a.cod, a.anio
