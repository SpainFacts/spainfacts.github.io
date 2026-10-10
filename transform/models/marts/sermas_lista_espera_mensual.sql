-- Informe mensual de listas de espera de la Comunidad de Madrid (Consejería de Sanidad,
-- comunidad.madrid, un CSV por mes y lista desde 2015-2016): lo que se difunde cada mes.
--   publicado: «Número de pacientes en espera estructural» del informe. Es la suma de los
--              tramos de espera por fecha de cita (0-30, 31-60, 61-90, >90 días): no incluye a
--              los pacientes sin fecha asignada.
--   tasa_publicada_1000: «Tasa por 1.000 habitantes» del mismo informe, sobre la población
--              asignada (tarjeta sanitaria). En consultas y pruebas esa tasa no sale del número
--              publicado: total_implicito = tasa x población asignada / 1.000 reproduce la
--              lista con los sin cita de la memoria anual (diciembre de 2023: 728.878 frente a
--              728.851; diciembre de 2025: 965.521 frente a 965.548). no_publicado_implicito =
--              total_implicito - publicado, con un error de redondeo de la tasa de unas
--              ±35 personas. En la lista quirúrgica no hay tasa ni «sin cita».
-- demora_corte_dias: «Demora media de espera a fecha de corte» de los pendientes con cita.
-- Por 1.000 habitantes con la población del INE (poblacion_territorios, cod '13'; el último
-- año con dato para los meses posteriores).
with raw as (
    select
        cast(anio as integer) as anio,
        cast(mes as integer) as mes,
        tipo,
        estructural, tasa_1000, poblacion_asignada, demora_corte,
        t0_30, t31_60, t61_90, t_mas_90, t91_180, t_mas_180,
        total_leq, rechazo_derivacion, tnp,
        entradas, salidas, atendidos, espera_media_atendidos, demora_prospectiva,
        fuente_url
    from {{ source('raw_sermas', 'sermas_mensual') }}
    where estructural is not null
),

pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and cod = '13' and sexo = 'Total'
),

rango as (select min(anio) as amin, max(anio) as amax from pob)

select
    '13' as cod_ccaa,
    'Comunidad de Madrid' as ccaa,
    make_date(r.anio, r.mes, 1) as fecha,
    r.anio,
    r.mes,
    r.tipo,
    cast(r.estructural as integer) as publicado,
    r.tasa_1000 as tasa_publicada_1000,
    cast(r.poblacion_asignada as integer) as poblacion_asignada,
    case when r.tipo <> 'quirurgica' and r.tasa_1000 is not null and r.poblacion_asignada is not null
         then cast(round(r.tasa_1000 * r.poblacion_asignada / 1000) as integer) end as total_implicito,
    case when r.tipo <> 'quirurgica' and r.tasa_1000 is not null and r.poblacion_asignada is not null
         then cast(round(r.tasa_1000 * r.poblacion_asignada / 1000) - r.estructural as integer) end as no_publicado_implicito,
    case when r.tipo <> 'quirurgica' and r.tasa_1000 is not null and r.poblacion_asignada is not null
         then round(100.0 * (r.tasa_1000 * r.poblacion_asignada / 1000 - r.estructural)
                    / (r.tasa_1000 * r.poblacion_asignada / 1000), 2) end as no_publicado_implicito_pct,
    round(1000.0 * r.estructural / p.poblacion, 2) as publicado_por_1000_hab,
    case when r.tipo <> 'quirurgica' and r.tasa_1000 is not null and r.poblacion_asignada is not null
         then round(r.tasa_1000 * r.poblacion_asignada / p.poblacion, 2) end as total_implicito_por_1000_hab,
    r.demora_corte as demora_corte_dias,
    r.demora_prospectiva as demora_prospectiva_dias,
    r.espera_media_atendidos as espera_media_atendidos_dias,
    cast(r.t0_30 as integer) as con_cita_0_30_dias,
    cast(r.t31_60 as integer) as con_cita_31_60_dias,
    cast(r.t61_90 as integer) as con_cita_61_90_dias,
    cast(coalesce(r.t_mas_90, r.t91_180 + r.t_mas_180) as integer) as con_cita_mas_90_dias,
    cast(r.total_leq as integer) as quirurgica_total_registro,
    cast(r.rechazo_derivacion as integer) as rechazo_derivacion,
    cast(r.tnp as integer) as transitoriamente_no_programables,
    cast(r.entradas as integer) as entradas_mes,
    cast(r.salidas as integer) as salidas_mes,
    cast(p.poblacion as integer) as poblacion,
    r.fuente_url
from raw r
cross join rango g
left join pob p on p.anio = greatest(least(r.anio, g.amax), g.amin)
order by r.tipo, fecha
