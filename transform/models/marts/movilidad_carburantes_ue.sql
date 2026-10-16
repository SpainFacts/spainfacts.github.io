-- Precio medio mensual de la gasolina 95 y el gasóleo de automoción en cada país de la UE y en
-- la media de la UE (Weekly Oil Bulletin), con y sin impuestos, la parte que son impuestos y el
-- precio en euros constantes con el IPCA de cada país (mother.deflactor_paises).
with semanas as (
    select
        date_trunc('month', semana)::date as fecha,
        case cod_pais_fuente when 'EU' then 'EU27_2020' else cod_pais_fuente end as cod_fuente,
        producto,
        con_impuestos,
        precio_litro
    from {{ source('raw_carburantes', 'carburantes_precios_ue') }}
    where cod_pais_fuente <> 'EUR'
),

mensual as (
    select
        fecha,
        cod_fuente,
        producto,
        avg(precio_litro) filter (where con_impuestos) as precio_litro,
        avg(precio_litro) filter (where not con_impuestos) as precio_sin_impuestos_litro
    from semanas
    group by 1, 2, 3
),

paises as (
    select * from {{ ref('paises_iso') }}
)

select
    m.fecha,
    year(m.fecha) as anio,
    p.cod_pais,
    p.pais,
    m.producto,
    case m.producto when 'gasoleo_a' then 'Gasóleo A' else 'Gasolina 95' end as carburante,
    m.precio_litro,
    m.precio_sin_impuestos_litro,
    m.precio_litro - m.precio_sin_impuestos_litro as impuestos_litro,
    100.0 * (m.precio_litro - m.precio_sin_impuestos_litro) / nullif(m.precio_litro, 0) as impuestos_pct,
    m.precio_litro * d.factor as precio_litro_real,
    d.anio_base
from mensual m
join paises p on m.cod_fuente in (p.cod_pais, p.eurostat)
left join {{ ref('deflactor_paises') }} d on d.cod_pais = p.cod_pais and d.anio = year(m.fecha)
where m.precio_litro is not null
