-- Índice de Precios de Vivienda (INE, tabla 25171; base 2015 = 100), trimestral
-- desde 2007, España y comunidades, general / nueva / segunda mano. Mide la
-- evolución del precio de compraventa (escrituras notariales) a calidad
-- constante; no da euros por m² (para eso, vivienda_precio_tasado).
-- indice_real: el índice descontada la inflación (IPC trimestral), reescalado
-- para que 2015 = 100 también en términos reales.
-- interanual_*: frente al mismo trimestre del año anterior.
with base as (
    select
        n.nivel,
        n.cod,
        -- +12 h: el INE fecha a medianoche hora peninsular (22:00 o 23:00 UTC del día anterior)
        cast(epoch_ms(s.fecha + 43200000) as date) as fecha_ine,
        case split_part(s.serie, '. ', 2)
            when 'General' then 'General'
            when 'Vivienda nueva' then 'Nueva'
            when 'Vivienda segunda mano' then 'Segunda mano'
        end as tipo,
        s.valor as indice
    from {{ source('raw_vivienda', 'ine_ipv') }} s
    join {{ ref('vivienda_nombres') }} n
      on n.nombre_ine = split_part(s.serie, '. ', 1) and n.nivel in ('pais', 'ccaa')
    where split_part(s.serie, '. ', 3) = 'Índice'
      and s.valor is not null
),

con_ipc as (
    select
        b.nivel,
        b.cod,
        cast(year(b.fecha_ine) as integer) as anio,
        cast(quarter(b.fecha_ine) as integer) as trimestre,
        b.tipo,
        b.indice,
        b.indice * d.factor as indice_deflactado
    from base b
    left join {{ ref('vivienda_deflactor_trimestral') }} d
      on d.anio = year(b.fecha_ine) and d.trimestre = quarter(b.fecha_ine)
),

base2015 as (
    select nivel, cod, tipo, avg(indice_deflactado) / avg(indice) as ajuste
    from con_ipc
    where anio = 2015
    group by all
),

serie as (
    select
        c.nivel,
        c.cod,
        c.anio,
        c.trimestre,
        make_date(c.anio, 3 * c.trimestre - 2, 1) as fecha,
        c.tipo,
        c.indice,
        c.indice_deflactado / b.ajuste as indice_real
    from con_ipc c
    join base2015 b using (nivel, cod, tipo)
)

select
    s.nivel,
    s.cod,
    coalesce(t.nombre, 'España') as nombre,
    s.fecha,
    s.anio,
    s.trimestre,
    cast(s.anio as varchar) || '-T' || cast(s.trimestre as varchar) as periodo,
    s.tipo,
    s.indice,
    s.indice_real,
    100 * (s.indice / a.indice - 1) as interanual_nominal,
    100 * (s.indice_real / a.indice_real - 1) as interanual_real
from serie s
left join serie a
  on a.nivel = s.nivel and a.cod = s.cod and a.tipo = s.tipo
 and a.anio = s.anio - 1 and a.trimestre = s.trimestre
left join {{ ref('territorios') }} t on t.nivel = s.nivel and t.cod = s.cod
