-- IPC por grupos ECOICOP v2, mensual desde 2002 (INE, IPC base 2025, tabla
-- 76125, vía el mart ipc), con el índice general como un grupo más.
--   indice, var_anual, var_mensual: tal como los publica el INE.
--   ponderacion: peso del grupo en la cesta (por mil) del último año publicado
--     (INE tabla 76156).
--   contribucion_aprox: puntos del IPC general que aporta el grupo a la tasa
--     anual = ponderacion/1000 x (índice del grupo hace 12 meses / índice
--     general hace 12 meses) x var_anual del grupo. Es una aproximación (el INE
--     encadena las ponderaciones cada diciembre) y la suma de los grupos puede
--     diferir unas décimas de la tasa general.
with base as (
    select
        date as mes,
        split_part(serie, '. ', 2) as grupo,
        split_part(serie, '. ', 3) as tipo,
        value as valor
    from {{ ref('ipc') }}
    where serie like 'Nacional. %' and value is not null
),

ancho as (
    select
        mes,
        grupo,
        max(valor) filter (where tipo = 'Índice') as indice,
        max(valor) filter (where tipo = 'Variación anual') as var_anual,
        max(valor) filter (where tipo = 'Variación mensual') as var_mensual
    from base
    group by all
),

pond as (
    select
        case split_part(serie, '. ', 2)
            when 'Bebidas alcohólicas, tabaco y estupefacientes' then 'Bebidas alcohólicas y tabaco'
            when 'Servicios de educación' then 'Enseñanza'
            else split_part(serie, '. ', 2)
        end as grupo,
        cast(anyo as integer) as anio_ponderacion,
        valor as ponderacion
    from {{ source('raw_mercado', 'ine_ipc_ponderaciones') }}
    where valor is not null
    qualify row_number() over (partition by cod_serie order by anyo desc) = 1
),

con_lag as (
    select
        a.*,
        lag(a.indice, 12) over (partition by a.grupo order by a.mes) as indice_12m
    from ancho a
),

general as (
    select mes, indice_12m as general_12m from con_lag where grupo = 'Índice general'
)

select
    c.mes,
    c.grupo,
    case c.grupo
        when 'Índice general' then 'General'
        when 'Alimentos y bebidas no alcohólicas' then 'Alimentos'
        when 'Bebidas alcohólicas y tabaco' then 'Alcohol y tabaco'
        when 'Vestido y calzado' then 'Ropa y calzado'
        when 'Vivienda, agua, electricidad, gas y otros combustibles' then 'Vivienda y energía'
        when 'Muebles, artículos del hogar y artículos para el mantenimiento corriente del hogar' then 'Hogar'
        when 'Sanidad' then 'Sanidad'
        when 'Transporte' then 'Transporte'
        when 'Información y comunicaciones' then 'Comunicaciones'
        when 'Actividades recreativas, deporte y cultura' then 'Ocio y cultura'
        when 'Enseñanza' then 'Enseñanza'
        when 'Restaurantes y servicios de alojamiento' then 'Restaurantes y hoteles'
        when 'Seguros y servicios financieros' then 'Seguros y finanzas'
        else 'Otros bienes y servicios'
    end as grupo_corto,
    c.grupo = 'Índice general' as es_general,
    c.indice,
    c.var_anual,
    c.var_mensual,
    p.ponderacion,
    p.anio_ponderacion,
    p.ponderacion / 1000 * c.indice_12m / g.general_12m * c.var_anual as contribucion_aprox
from con_lag c
left join general g on g.mes = c.mes
left join pond p on p.grupo = c.grupo
