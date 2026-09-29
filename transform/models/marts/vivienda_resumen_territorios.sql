-- Ficha de vivienda por territorio (España, comunidades y provincias) con el
-- último dato de cada indicador, para mapas, rankings y páginas de territorio.
--   Precio: valor tasado €/m² del último trimestre (Ministerio de Vivienda), en
--   euros del año base, variación real interanual y frente al máximo real de
--   la serie (desde 2002).
--   Alquiler: mediana mensual de pisos (SERPAVI) del último año, real, y su
--   cambio real en cinco años.
--   Compraventas e hipotecas: últimos 12 meses por 1.000 habitantes (INE).
--   Obra nueva: viviendas libres terminadas por 1.000 hab. del último año.
--   Esfuerzo: años de salario bruto para 90 m² (solo España y comunidades).
with precio_ult as (
    select *
    from {{ ref('vivienda_precio_tasado') }}
    qualify row_number() over (partition by nivel, cod order by fecha desc) = 1
),

precio_max as (
    select nivel, cod, max(euros_m2_real) as max_real, arg_max(periodo, euros_m2_real) as periodo_max
    from {{ ref('vivienda_precio_tasado') }}
    where euros_m2_real is not null
    group by all
),

alquiler_ult as (
    select a.nivel, a.cod, a.anio, a.alquiler_mes_mediana_real, a.alquiler_m2_mediana_real,
           100 * (a.alquiler_mes_mediana_real / c.alquiler_mes_mediana_real - 1) as alquiler_var_5a
    from {{ ref('vivienda_alquiler') }} a
    left join {{ ref('vivienda_alquiler') }} c
      on c.nivel = a.nivel and c.cod = a.cod and c.tipologia = a.tipologia and c.anio = a.anio - 5
    where a.tipologia = 'Colectiva'
    qualify row_number() over (partition by a.nivel, a.cod order by a.anio desc) = 1
),

mercado_ult as (
    select nivel, cod, fecha, compraventas_12m, compraventas_12m_1000, hipotecas_12m_1000
    from {{ ref('vivienda_mercado_mensual') }}
    where compraventas_12m_1000 is not null
    qualify row_number() over (partition by nivel, cod order by fecha desc) = 1
),

obra_ult as (
    select nivel, cod, anio, terminadas_1000
    from {{ ref('vivienda_obra_nueva') }}
    where terminadas_1000 is not null
    qualify row_number() over (partition by nivel, cod order by anio desc) = 1
),

esfuerzo_ult as (
    select nivel, cod, anio, anios_salario, pct_alquiler
    from {{ ref('vivienda_esfuerzo') }}
    where anios_salario is not null
    qualify row_number() over (partition by nivel, cod order by anio desc) = 1
)

select
    t.nivel,
    t.cod,
    t.cod_ccaa,
    t.nombre,
    t.ruta,
    p.periodo as precio_periodo,
    p.euros_m2,
    p.euros_m2_real,
    p.precio_90m2_real,
    p.interanual_real as precio_interanual_real,
    100 * (p.euros_m2_real / m.max_real - 1) as precio_vs_maximo_real,
    m.periodo_max as precio_periodo_maximo,
    a.anio as alquiler_anio,
    a.alquiler_mes_mediana_real,
    a.alquiler_m2_mediana_real,
    a.alquiler_var_5a,
    mk.fecha as mercado_fecha,
    mk.compraventas_12m,
    mk.compraventas_12m_1000,
    mk.hipotecas_12m_1000,
    o.anio as obra_anio,
    o.terminadas_1000,
    e.anio as esfuerzo_anio,
    e.anios_salario,
    e.pct_alquiler,
    p.anio_base
from {{ ref('territorios') }} t
left join precio_ult p on p.nivel = t.nivel and p.cod = t.cod
left join precio_max m on m.nivel = t.nivel and m.cod = t.cod
left join alquiler_ult a on a.nivel = t.nivel and a.cod = t.cod
left join mercado_ult mk on mk.nivel = t.nivel and mk.cod = t.cod
left join obra_ult o on o.nivel = t.nivel and o.cod = t.cod
left join esfuerzo_ult e on e.nivel = t.nivel and e.cod = t.cod
where t.nivel in ('pais', 'ccaa', 'provincia')
