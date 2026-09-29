-- Esfuerzo para comprar o alquilar vivienda, España y comunidades, por año.
--   precio_90m2: valor tasado medio de la vivienda libre (Ministerio de
--   Vivienda, media de los cuatro trimestres del año, vivienda_precio_tasado)
--   por 90 m².
--   salario_anual: coste salarial total por trabajador (INE, ETCL tabla 6061,
--   mart economia_salarios_ccaa) x 12: salario bruto medio anual con pagas
--   extra, industria, construcción y servicios.
--   anios_salario = precio_90m2 / salario_anual: años de salario bruto íntegro
--   necesarios para pagar una vivienda de 90 m² (sin impuestos ni intereses).
--   pct_alquiler = alquiler mediano de un piso (SERPAVI, colectiva) x 12 /
--   salario_anual: parte del salario bruto que se va en el alquiler.
-- Como es un cociente de euros del mismo año, no hace falta deflactar.
-- Ceuta y Melilla no tienen salario en la ETCL.
with precio as (
    select nivel, cod, anio, avg(euros_m2) as euros_m2, count(*) as trimestres
    from {{ ref('vivienda_precio_tasado') }}
    where nivel in ('pais', 'ccaa')
    group by all
    having count(*) = 4
),

salario as (
    select
        case when cod = '00' then 'pais' else 'ccaa' end as nivel,
        cod,
        anio,
        12 * salario_nominal as salario_anual
    from {{ ref('economia_salarios_ccaa') }}
    where salario_nominal is not null
),

alquiler as (
    select nivel, cod, anio, alquiler_mes_mediana
    from {{ ref('vivienda_alquiler') }}
    where tipologia = 'Colectiva' and nivel in ('pais', 'ccaa')
)

select
    s.nivel,
    s.cod,
    coalesce(t.nombre, 'España') as nombre,
    s.anio,
    p.euros_m2,
    90 * p.euros_m2 as precio_90m2,
    s.salario_anual,
    90 * p.euros_m2 / s.salario_anual as anios_salario,
    a.alquiler_mes_mediana,
    100 * 12 * a.alquiler_mes_mediana / s.salario_anual as pct_alquiler
from salario s
left join precio p on p.nivel = s.nivel and p.cod = s.cod and p.anio = s.anio
left join alquiler a on a.nivel = s.nivel and a.cod = s.cod and a.anio = s.anio
left join {{ ref('territorios') }} t on t.nivel = s.nivel and t.cod = s.cod
where p.euros_m2 is not null or a.alquiler_mes_mediana is not null
