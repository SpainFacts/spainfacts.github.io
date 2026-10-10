-- Hospitales públicos de gestión privada con población asignada (seed sanidad_privada_concesiones,
-- construido a mano con cita por fila: DOGV, memorias 2024 de los hospitales del SERMAS, Xunta,
-- Sindicatura de Comptes y prensa solvente cuando no hay dato oficial; columna fiabilidad).
--   modelo 'concesion_capitativa': concesión administrativa de la asistencia sanitaria integral de
--          un departamento o área, pagada por habitante asignado (cápita): modelo Alzira (Comunitat
--          Valenciana) y hospitales de Valdemoro, Torrejón, Móstoles y Collado Villalba (Madrid).
--   modelo 'concierto_singular': hospital privado con concierto que le asigna población
--          (Fundación Jiménez Díaz en Madrid, Povisa en Vigo).
--   modelo 'pfi_no_sanitaria': concesión de obra y servicios no sanitarios (iniciativa de
--          financiación privada) con personal sanitario público: NO es gestión sanitaria privada.
-- en_gestion_privada = sigue sin revertir a gestión pública directa (octubre de 2026).
select
    cast(s.hospital_id as varchar) as hospital_id,
    lpad(cast(s.cod_ccaa as varchar), 2, '0') as cod_ccaa,
    t.nombre as ccaa,
    s.hospital,
    s.municipio,
    s.modelo,
    s.empresa_inicial,
    s.empresa_actual,
    cast(s.anio_inicio as integer) as anio_inicio,
    cast(s.anio_fin_o_reversion as integer) as anio_reversion,
    cast(s.fecha_reversion as date) as fecha_reversion,
    s.anio_fin_o_reversion is null as en_gestion_privada,
    cast(s.duracion_contrato_anios as integer) as duracion_contrato_anios,
    cast(s.poblacion_asignada as bigint) as poblacion_asignada,
    cast(s.poblacion_anio as integer) as poblacion_anio,
    s.poblacion_fuente_url,
    cast(s.capita_eur as double) as capita_eur,
    cast(s.capita_anio as varchar) as capita_anio,
    s.capita_fuente_url,
    s.fiabilidad,
    s.fuente_url,
    s.nota
from {{ ref('sanidad_privada_concesiones') }} s
left join {{ ref('territorios') }} t
    on t.nivel = 'ccaa' and t.cod = lpad(cast(s.cod_ccaa as varchar), 2, '0')
