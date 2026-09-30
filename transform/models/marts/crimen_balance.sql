-- Infracciones penales conocidas por año completo (2019-) y territorio
-- (España, comunidad, provincia, isla y municipios de más de 20.000
-- habitantes), por categoría normalizada, con la tasa por 1.000 habitantes.
-- Fuente: Balance de Criminalidad (Ministerio del Interior). Solo año
-- completo (enero-diciembre); el trimestre en curso está en crimen_ultimo_periodo.
-- El Balance publica las comunidades uniprovinciales (Asturias, Baleares,
-- Cantabria, La Rioja, Madrid, Murcia, Navarra) y Ceuta y Melilla solo como
-- comunidad: se copian también al nivel provincia con su código INE.
with base as (
    select
        b.anio,
        b.nivel,
        case
            when b.nivel = 'municipio' then b.cod_mun
            when b.nivel = 'pais' then '00'
            else s.cod
        end as cod,
        b.territorio,
        t.categoria,
        b.infracciones
    from {{ ref('crimen_balance_base') }} b
    join {{ ref('crimen_tipologias') }} t on t.tipologia = b.tipologia
    left join {{ ref('ses_territorios') }} s on s.territorio_ses = b.territorio and s.nivel = b.nivel
    where b.periodo = 'enero-diciembre' and t.categoria is not null
),

-- algunos ficheros dan el total nacional como fila 'ccaa' ("TOTAL NACIONAL")
normalizado as (
    select anio, case when cod = '00' then 'pais' else nivel end as nivel, cod, territorio, categoria, infracciones
    from base
),

poblacion as (
    select anio, 'municipio' as nivel, cod_mun as cod, poblacion from {{ ref('poblacion_municipios') }} where sexo = 'Total'
    union all
    select anio, nivel, cod, poblacion from {{ ref('poblacion_territorios') }} where sexo = 'Total'
),

final as (
select
    n.anio,
    n.nivel,
    n.cod,
    any_value(n.territorio) as territorio,
    n.categoria,
    sum(n.infracciones) as infracciones,
    max(p.poblacion) as poblacion,
    1000.0 * sum(n.infracciones) / nullif(max(p.poblacion), 0) as tasa_1000
from normalizado n
left join poblacion p
  on p.nivel = n.nivel and p.cod = n.cod
 and p.anio = least(n.anio, (select max(anio) from poblacion))
where n.nivel in ('pais', 'ccaa', 'provincia', 'municipio') and n.cod is not null
group by n.anio, n.nivel, n.cod, n.categoria
)

{{ con_uniprovinciales('final', ['anio', 'categoria']) }}
