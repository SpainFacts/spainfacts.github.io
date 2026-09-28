-- Cuentas de cada ayuntamiento por ejercicio (Ministerio de Hacienda, CONPREL):
-- liquidación del presupuesto consolidado (ayuntamiento + organismos
-- autónomos), en euros. Una fila por (cod_mun, anio). Ingresos = derechos
-- reconocidos netos; gastos = obligaciones reconocidas netas.
--
-- * Capítulos: 1-5 corrientes, 6-7 de capital (1-7 = no financieros),
--   8-9 financieros (activos y pasivos: préstamos, amortización de deuda).
--   Hasta 2012 no existe el capítulo 5 de gastos (Fondo de contingencia): 0.
-- * Áreas de gasto: 0 deuda pública, 1 servicios públicos básicos, 2 protección
--   y promoción social, 3 bienes públicos de carácter preferente, 4 actuaciones
--   de carácter económico, 9 actuaciones de carácter general.
-- * El último ejercicio es el avance (provisional = true) hasta que sale la
--   liquidación definitiva.
-- * tiene_datos = false cuando el ayuntamiento no remitió la liquidación
--   (estado N, importes a 0 en el fichero): se deja la fila con importes NULOS,
--   nunca ceros. Con estado E (solo clasificación económica) las áreas son nulas.
-- * Población: padrón del INE de ese año (poblacion_municipios) y, si falta,
--   la que publica CONPREL.
-- * Solo municipios del diccionario del INE (poblacion_municipios). Las
--   diputaciones, mancomunidades y entidades menores no se suman aquí.
with liquidaciones as (
    select
        *,
        coalesce(estado_informacion, 'N') <> 'N'
            and (coalesce(ingresos_total, 0) <> 0 or coalesce(gastos_total, 0) <> 0) as tiene_datos
    from {{ source('raw_conprel', 'conprel_liquidaciones') }}
    -- por si una entidad saliera dos veces en el mismo año: la que tiene datos
    qualify row_number() over (
        partition by cod_mun, anio
        order by (coalesce(estado_informacion, 'N') = 'N'), gastos_total desc nulls last
    ) = 1
),

ine as (
    select anio, cod_mun, municipio, cod_prov, cod_ccaa, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
),

municipios as (
    -- nombre y territorio del último padrón en que aparece el municipio
    select cod_mun, municipio, cod_prov, cod_ccaa
    from ine
    qualify row_number() over (partition by cod_mun order by anio desc) = 1
),

base as (
    select
        l.cod_mun,
        l.anio::integer as anio,
        l.provisional,
        m.municipio,
        m.cod_prov,
        m.cod_ccaa,
        coalesce(i.poblacion, l.poblacion) as poblacion,
        l.estado_informacion,
        l.tiene_datos,
        -- áreas solo con la clasificación por programas informada (no estado E)
        l.tiene_datos and coalesce(l.gasto_area_total, 0) <> 0 as tiene_areas,
        {%- for c in range(1, 10) %}
        case when l.tiene_datos then l.ingresos_c{{ c }} end as ingresos_c{{ c }},
        {%- endfor %}
        case when l.tiene_datos then l.ingresos_total end as ingresos_total,
        {%- for c in range(1, 10) %}
        case when l.tiene_datos then l.gastos_c{{ c }} end as gastos_c{{ c }},
        {%- endfor %}
        case when l.tiene_datos then l.gastos_total end as gastos_total,
        {%- for a in [0, 1, 2, 3, 4, 9] %}
        l.gasto_area_{{ a }},
        {%- endfor %}
    from liquidaciones as l
    join municipios as m on m.cod_mun = l.cod_mun
    left join ine as i on i.cod_mun = l.cod_mun and i.anio = l.anio
)

select
    cod_mun,
    anio,
    provisional,
    municipio,
    cod_prov,
    cod_ccaa,
    poblacion,
    estado_informacion,
    tiene_datos,
    {%- for c in range(1, 10) %}
    ingresos_c{{ c }},
    {%- endfor %}
    ingresos_total,
    {% for c in range(1, 8) %}ingresos_c{{ c }}{{ ' + ' if not loop.last }}{% endfor %} as ingresos_no_financieros,
    {%- for c in range(1, 10) %}
    gastos_c{{ c }},
    {%- endfor %}
    gastos_total,
    {% for c in range(1, 8) %}gastos_c{{ c }}{{ ' + ' if not loop.last }}{% endfor %} as gastos_no_financieros,
    {%- for a in [0, 1, 2, 3, 4, 9] %}
    case when tiene_areas then gasto_area_{{ a }} end as gasto_area_{{ a }},
    {%- endfor %}
    ({% for c in range(1, 8) %}ingresos_c{{ c }}{{ ' + ' if not loop.last }}{% endfor %})
      - ({% for c in range(1, 8) %}gastos_c{{ c }}{{ ' + ' if not loop.last }}{% endfor %}) as saldo_no_financiero,
    round(gastos_total / nullif(poblacion, 0), 2) as gasto_hab,
    round(ingresos_total / nullif(poblacion, 0), 2) as ingreso_hab,
    cod_mun || '-' || anio as clave
from base
order by cod_mun, anio
