-- Producción de vehículos de motor por país y año (seed industria_vehiculos_paises: OICA 2019 y
-- 2021-2024; España 2024-2025 de ANFAC). Una fila por país y año.
--   Para cada (país, año) se usa OICA si existe y, si no, ANFAC (solo España 2025).
--   puesto_europa: posición entre los países de la región Europa de OICA (incluye Turquía,
--     Rusia y Reino Unido); puesto_mundo: entre todos los países. El seed solo trae los países
--     necesarios para que el puesto de España sea correcto (todos los que la superan): el puesto
--     de los países pequeños NO es fiable. Para 2025 solo hay dato de España y el puesto queda nulo
--     (ANFAC afirma 2.º de Europa y 9.º del mundo: ver nota).
--   cuota_mundo_pct: parte del total mundial de OICA.
--   vehiculos_1000_hab: vehículos fabricados por 1.000 habitantes (solo países de la UE, con la
--     población media de Eurostat nama_10_pe).
--   pct_exportado: exportados / producidos (España 2025, ANFAC).
--   Cobertura: Alemania solo turismos y Francia solo turismos y comerciales ligeros en OICA.
with s as (
    select *,
        row_number() over (partition by cod_pais, anio order by case fuente_dato when 'OICA' then 1 else 2 end) as rn
    from {{ ref('industria_vehiculos_paises') }}
),

anfac as (
    select anio, turismos, exportados from {{ ref('industria_vehiculos_paises') }}
    where cod_pais = 'ES' and fuente_dato = 'ANFAC'
),

v as (
    select s.anio, s.cod_pais, s.pais, s.region, s.vehiculos, s.cobertura, s.fuente_dato, s.fuente,
           a.turismos, a.exportados
    from s
    left join anfac a on s.cod_pais = 'ES' and a.anio = s.anio
    where s.rn = 1
),

n_anio as (
    select anio, count(*) filter (where cod_pais not in ('ES', 'MUNDO')) as n_otros from v group by 1
),

pob as (
    select cast(anio as integer) as anio, pais, miles from {{ source('raw_industria', 'eurostat_industria_poblacion') }}
)

select
    v.anio,
    v.cod_pais,
    v.pais,
    v.region,
    v.vehiculos,
    v.turismos,
    v.exportados,
    100.0 * v.exportados / nullif(v.vehiculos, 0) as pct_exportado,
    case when n.n_otros > 0 and v.region = 'Europa' then
        rank() over (partition by v.anio, v.region = 'Europa' order by v.vehiculos desc) end as puesto_europa,
    case when n.n_otros > 0 and v.cod_pais <> 'MUNDO' then
        rank() over (partition by v.anio, v.cod_pais <> 'MUNDO' order by v.vehiculos desc) end as puesto_mundo,
    100.0 * v.vehiculos / nullif(m.vehiculos, 0) as cuota_mundo_pct,
    1.0 * v.vehiculos / nullif(p.miles, 0) as vehiculos_1000_hab,
    v.cobertura,
    case when v.cod_pais = 'ES' and v.anio = 2025
         then 'ANFAC: «España ocupa el 2.º lugar como fabricante de vehículos en Europa y el 9.º mundial»' end as nota,
    v.fuente_dato,
    v.fuente
from v
join n_anio n using (anio)
left join v m on m.cod_pais = 'MUNDO' and m.anio = v.anio
left join pob p on p.pais = case when v.cod_pais = 'UK' then null else v.cod_pais end and p.anio = v.anio
