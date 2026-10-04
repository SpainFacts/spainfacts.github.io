-- Último trimestre publicado del Balance de Criminalidad: acumulado del año en
-- curso frente al mismo periodo del año anterior, por territorio y categoría.
-- Uniprovinciales, Ceuta y Melilla vienen solo como comunidad: se copian
-- también al nivel provincia con su código INE.
-- tasa_1000: infracciones del periodo acumulado por 1.000 habitantes (padrón más reciente), no
-- comparable con la de un año completo; variacion_pct: cambio frente al mismo periodo del año anterior.
-- nombre: el de territorios (España, comunidades y provincias); los municipios llevan el del Balance.
with parcial as (
    select * from {{ ref('crimen_balance_base') }}
    where periodo <> 'enero-diciembre'
),

ultimo as (
    select max(anio) as anio from parcial
),

tramo as (
    select any_value(periodo) as periodo from parcial where anio = (select anio from ultimo)
),

base as (
    select
        b.anio,
        b.periodo,
        case
            when b.nivel = 'municipio' then b.cod_mun
            when b.nivel = 'pais' then '00'
            else s.cod
        end as cod,
        b.nivel,
        b.territorio,
        t.categoria,
        b.infracciones
    from parcial b
    join {{ ref('crimen_tipologias') }} t on t.tipologia = b.tipologia
    left join {{ ref('ses_territorios') }} s on s.territorio_ses = b.territorio and s.nivel = b.nivel
    where t.categoria is not null
      and b.periodo = (select periodo from tramo)
      and b.anio in ((select anio from ultimo), (select anio - 1 from ultimo))
),

final as (
select
    (select anio from ultimo) as anio,
    (select periodo from tramo) as periodo,
    case when cod = '00' then 'pais' else nivel end as nivel,
    cod,
    any_value(territorio) as territorio,
    categoria,
    sum(infracciones) filter (where anio = (select anio from ultimo)) as infracciones,
    sum(infracciones) filter (where anio = (select anio - 1 from ultimo)) as infracciones_anio_anterior
from base
where cod is not null and nivel in ('pais', 'ccaa', 'provincia', 'municipio')
group by all
),

con_provincias as (
{{ con_uniprovinciales('final', ['anio', 'periodo', 'categoria']) }}
),

-- padrón más reciente de cada territorio
poblacion as (
    select nivel, cod, poblacion
    from (
        select 'municipio' as nivel, cod_mun as cod, anio, poblacion from {{ ref('poblacion_municipios') }} where sexo = 'Total'
        union all
        select nivel, cod, anio, poblacion from {{ ref('poblacion_territorios') }} where sexo = 'Total'
    )
    qualify anio = max(anio) over (partition by nivel)
)

select
    c.anio,
    c.periodo,
    c.nivel,
    c.cod,
    coalesce(t.nombre, c.territorio) as nombre,
    c.categoria,
    c.infracciones,
    c.infracciones_anio_anterior,
    p.poblacion,
    1000.0 * c.infracciones / nullif(p.poblacion, 0) as tasa_1000,
    100.0 * (c.infracciones / nullif(c.infracciones_anio_anterior, 0) - 1) as variacion_pct
from con_provincias c
left join {{ ref('territorios') }} t on t.nivel = c.nivel and t.cod = c.cod
left join poblacion p on p.nivel = c.nivel and p.cod = c.cod
