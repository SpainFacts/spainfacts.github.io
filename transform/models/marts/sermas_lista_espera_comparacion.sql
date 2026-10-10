-- La misma lista de espera de diciembre de cada año en tres documentos oficiales:
--   memoria:  Memoria anual del SERMAS (lista completa, con los pacientes sin cita) —
--             mart sermas_lista_espera, especialidad 'Total'.
--   mensual:  informe mensual de diciembre de la Consejería (solo pacientes con cita) y la
--             lista que se deduce de su propia tasa por 1.000 habitantes — sermas_lista_espera_mensual.
--   sisle:    lo que la Comunidad de Madrid comunica al Ministerio de Sanidad (SISLE-SNS, a 31 de
--             diciembre) — mart sanidad_listas_espera, cod '13'. En consultas el ministerio solo
--             publica la tasa por 1.000 habitantes: sisle_pacientes_estimados = tasa x población
--             asignada del informe mensual de diciembre / 1.000 (estimación propia).
-- Pruebas: la memoria cuenta 8 técnicas y el informe mensual todas, por eso el mensual puede
-- superar a la parte con cita de la memoria; el SISLE no publica pruebas.
with memoria as (
    select anio, tipo, total, con_cita, sin_cita, tiempo_medio_pendientes_dias, poblacion
    from {{ ref('sermas_lista_espera') }}
    where especialidad = 'Total'
),

mensual as (
    select anio, tipo, publicado, total_implicito, no_publicado_implicito, tasa_publicada_1000,
           poblacion_asignada, demora_corte_dias
    from {{ ref('sermas_lista_espera_mensual') }}
    where mes = 12
),

sisle as (
    select anio,
           case tipo when 'consultas' then 'consulta' else tipo end as tipo,
           pacientes, tasa_1000, dias_medio
    from {{ ref('sanidad_listas_espera') }}
    where nivel = 'ccaa' and cod = '13' and corte = 'diciembre'
),

claves as (
    select anio, tipo from memoria
    union select anio, tipo from mensual
    union select anio, tipo from sisle
)

select
    '13' as cod_ccaa,
    'Comunidad de Madrid' as ccaa,
    k.anio,
    make_date(k.anio, 12, 31) as fecha_corte,
    k.tipo,
    m.total as memoria_total,
    m.con_cita as memoria_con_cita,
    m.sin_cita as memoria_sin_cita,
    n.publicado as mensual_publicado,
    n.total_implicito as mensual_total_implicito,
    n.no_publicado_implicito as mensual_no_publicado_implicito,
    s.pacientes as sisle_pacientes,
    case when k.tipo = 'consulta' and s.tasa_1000 is not null and n.poblacion_asignada is not null
         then cast(round(s.tasa_1000 * n.poblacion_asignada / 1000) as integer) end as sisle_pacientes_estimados,
    s.tasa_1000 as sisle_tasa_1000,
    n.tasa_publicada_1000 as mensual_tasa_1000,
    round(1000.0 * m.total / m.poblacion, 2) as memoria_total_por_1000_hab,
    round(1000.0 * n.publicado / m.poblacion, 2) as mensual_publicado_por_1000_hab,
    cast(m.total - n.publicado as integer) as diferencia_memoria_mensual,
    round(100.0 * (m.total - n.publicado) / nullif(m.total, 0), 2) as diferencia_memoria_mensual_pct,
    m.tiempo_medio_pendientes_dias as memoria_dias_pendientes,
    n.demora_corte_dias as mensual_demora_corte_dias,
    s.dias_medio as sisle_dias_medio
from claves k
left join memoria m on m.anio = k.anio and m.tipo = k.tipo
left join mensual n on n.anio = k.anio and n.tipo = k.tipo
left join sisle s on s.anio = k.anio and s.tipo = k.tipo
order by k.tipo, k.anio
