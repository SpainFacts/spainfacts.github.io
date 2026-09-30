-- Último trimestre publicado del Balance de Criminalidad: acumulado del año en
-- curso frente al mismo periodo del año anterior, por territorio y categoría.
-- Uniprovinciales, Ceuta y Melilla vienen solo como comunidad: se copian
-- también al nivel provincia con su código INE.
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
)

{{ con_uniprovinciales('final', ['anio', 'periodo', 'categoria']) }}
