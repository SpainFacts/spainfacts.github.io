-- Último año con dato de cada indicador y país (para tarjetas), con el valor de
-- España del mismo año y el último año de España, para comparar sin mezclar años.
with ultimo as (
    select *
    from {{ ref('internacional_comparativa') }}
    qualify row_number() over (partition by indicador_id, cod_pais order by anio desc) = 1
)

select
    u.indicador_id,
    u.nombre,
    u.unidad,
    u.apartado,
    u.cod_pais,
    u.pais,
    u.es_agregado,
    u.es_referencia,
    u.orden_pais,
    u.anio,
    u.valor,
    esp.valor as valor_espana_mismo_anio,
    u.fuente,
    u.url_fuente,
    u.sentido
from ultimo u
left join {{ ref('internacional_comparativa') }} esp
    on esp.indicador_id = u.indicador_id and esp.cod_pais = 'ES' and esp.anio = u.anio
