-- Peso de la libre elección en cada especialidad hospitalaria de la Comunidad de Madrid:
-- Memoria anual del SERMAS, «Balance por especialidad» (2022-2025). primeras_consultas =
-- primeras consultas del año en las especialidades de libre elección (fuente SIAE);
-- consultas_libre_eleccion = consultas realizadas porque el paciente eligió otro hospital
-- (fuente CMCAP). libre_eleccion_pct = consultas_libre_eleccion / primeras_consultas x 100.
-- es_agregado: filas de total (Total, Total área médica / quirúrgica / pediátrica / obstétrica).
-- En la memoria 2024 la fila «TOTAL ÁREA MÉDICA» repite la de 2023 (1.807.253 / 146.916): se
-- deja tal cual viene y se marca dato_repetido.
with raw as (
    select cast(anio as integer) as anio, trim(especialidad) as especialidad_informe,
           primeras_consultas, consultas_libre_eleccion, fuente_url
    from {{ source('raw_sermas', 'sermas_le_especialidad') }}
    where primeras_consultas is not null and consultas_libre_eleccion is not null
),

limpio as (
    select
        anio,
        case
            when upper(especialidad_informe) = 'TOTAL' then 'Total'
            when upper(strip_accents(especialidad_informe)) like 'TOTAL AREA MEDICA%' then 'Total área médica'
            when upper(strip_accents(especialidad_informe)) like 'TOTAL AREA QUIRURGICA%' then 'Total área quirúrgica'
            when upper(strip_accents(especialidad_informe)) like 'TOTAL AREA PEDIATRICA%' then 'Total área pediátrica'
            when upper(strip_accents(especialidad_informe)) like 'TOTAL AREA OBSTETRICA%' then 'Total área obstétrica'
            when especialidad_informe = 'C. Máxilofacial' then 'C. Maxilofacial'
            else especialidad_informe
        end as especialidad,
        primeras_consultas, consultas_libre_eleccion, fuente_url
    from raw
)

select
    '13' as cod_ccaa,
    'Comunidad de Madrid' as ccaa,
    l.anio,
    l.especialidad,
    l.especialidad like 'Total%' as es_agregado,
    cast(l.primeras_consultas as integer) as primeras_consultas,
    cast(l.consultas_libre_eleccion as integer) as consultas_libre_eleccion,
    round(100.0 * l.consultas_libre_eleccion / nullif(l.primeras_consultas, 0), 2) as libre_eleccion_pct,
    coalesce(l.primeras_consultas = prev.primeras_consultas
             and l.consultas_libre_eleccion = prev.consultas_libre_eleccion, false) as dato_repetido,
    l.fuente_url
from limpio l
left join limpio prev on prev.anio = l.anio - 1 and prev.especialidad = l.especialidad
order by l.anio, l.especialidad
