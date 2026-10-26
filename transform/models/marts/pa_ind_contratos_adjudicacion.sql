-- Índice propio de publicidad activa: contratos_adjudicacion (perfil del contratante, LCSP).
-- Universo, fuentes, exclusiones y fórmulas en pa_contratos_entidades y en
-- docs/elaboracion-propia/contratos.md.
--   estado con_registros   la entidad tiene elementos con el plazo vencido (n_total > 0):
--                          el modelo común convierte n_fuera_plazo / n_total en estado
--          sin_registros   no consta ningún elemento en la plataforma ese año (no es por
--                          sí un incumplimiento: en municipios pequeños contratan la
--                          diputación, la mancomunidad o una central de contratación)
--          no_vencido      año en curso o plazo del último elemento aún no vencido en la
--                          fecha de corte (n_total cuenta solo los elementos ya vencidos)
--          no_aplica       aplica_indicador = false (motivo_no_aplica)
select
    obligacion,
    obligacion_nombre,
    base_legal,
    tipo_entidad,
    cod_entidad,
    nombre_entidad,
    cod_mun,
    cod_prov,
    cod_ccaa,
    periodo,
    anio,
    fecha_plazo,
    case
        when not aplica_indicador then 'no_aplica'
        when fecha_corte is null or fecha_plazo > fecha_corte then 'no_vencido'
        when coalesce(n_total, 0) > 0 then 'con_registros'
        else 'sin_registros'
    end as estado,
    cast(null as integer) as dias_retraso,
    cast(case when aplica_indicador then coalesce(n_total, 0) end as integer) as n_total,
    cast(case when aplica_indicador then coalesce(n_fuera_plazo, 0) end as integer) as n_fuera_plazo,
    case when aplica_indicador then mediana_dias end as mediana_dias,
    aplica_indicador,
    motivo_no_aplica,
    poblacion,
    url_fuente,
    -- extras
    case when n_total > 0 then round(100.0 * n_fuera_plazo / n_total, 1) end as x_pct_fuera_plazo,
    cast(n_sin_anuncio as integer) as x_n_sin_anuncio,
    cast(n_negativos as integer) as x_n_negativos,
    cast(n_pendientes as integer) as x_n_pendientes,
    cast(n_sin_fecha as integer) as x_n_sin_fecha,
    cast(n_organos as integer) as x_n_organos,
    fuente as x_fuente,
    conjuntos as x_conjuntos,
    publica_en_agregada as x_publica_en_agregada,
    -- tiene adjudicaciones o formalizaciones en el perfil ese año (en menores: sin_registros con
    -- perfil activo = publica sus menores fuera de la plataforma, p. ej. en su sede o portal)
    publica_en_perfil as x_publica_en_perfil,
    fecha_corte as x_fecha_corte,
    obligacion || '-' || cod_entidad || '-' || periodo as clave
from {{ ref('pa_contratos_entidades') }}
where obligacion = 'contratos_adjudicacion'
