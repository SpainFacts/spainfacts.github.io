-- Índice propio de publicidad activa y remisión de información (elaboración propia
-- de SpainFacts): una fila por entidad, obligación y periodo, uniendo todos los
-- indicadores pa_ind_* (mismo contrato de columnas; criterios en
-- docs/elaboracion-propia/).
--
-- Puntuación de cada obligación y periodo (0 a 1):
--   en_plazo, consta                  1     (consta = remitida, sin fecha para medir el plazo)
--   fuera_plazo                       0,5   (se remitió/publicó, tarde)
--   no_consta                         0     (plazo vencido y no consta en la fuente oficial)
--   con_registros                     1 - n_fuera_plazo / n_total (muchos elementos:
--                                     subvenciones, contratos, trimestres de PMP)
--   sin_registros, no_vencido,        sin puntuación: no hay nada que medir, el plazo no ha
--   no_aplica                         vencido o la fuente no mide a la entidad (foral...)
--
-- Gobierno: el que estaba en funciones el día del plazo (alcalde, presidente
-- autonómico); diputaciones, cabildos y consells quedan sin atribuir.

{% set indicadores = ['pa_ind_existentes', 'pa_ind_ispa', 'pa_ind_presupuesto', 'pa_ind_presupuestos_ccaa',
                       'pa_ind_pmp_ccaa', 'pa_ind_pmp_entidades_locales',
                       'pa_ind_contratos_adjudicacion', 'pa_ind_contratos_formalizacion', 'pa_ind_contratos_menores',
                       'pa_ind_bdns'] %}
-- Bloque «pago»: miden si se paga a tiempo a los proveedores, no si se publica o
-- remite. Se muestran, pero no entran en el índice ni en los incumplimientos.
{% set bloque_pago = ['pa_ind_pmp_ccaa', 'pa_ind_pmp_entidades_locales'] %}

with unido as (
    {% for m in indicadores %}
    select
        obligacion, obligacion_nombre, base_legal, tipo_entidad, cod_entidad, nombre_entidad,
        cod_mun, cod_prov, cod_ccaa, periodo, cast(anio as integer) as anio, fecha_plazo, estado,
        dias_retraso, n_total, n_fuera_plazo, mediana_dias, aplica_indicador, motivo_no_aplica,
        poblacion, url_fuente, '{{ m }}' as modelo,
        '{{ 'pago' if m in bloque_pago else 'remision' }}' as bloque
    from {{ ref(m) }}
    {% if m == 'pa_ind_bdns' %}
    -- la BDNS borra las concesiones a personas físicas al segundo año: los años medidos
    -- tarde (2022-2024, descargados en 2026) no son comparables y no se usan
    where not coalesce(x_medicion_tardia, false)
    {% endif %}
    {% if not loop.last %}union all{% endif %}
    {% endfor %}
),

puntuado as (
    select
        *,
        case
            when not coalesce(aplica_indicador, true) then null
            -- nada puntúa antes de que venza su plazo (el año en curso, la ley del año que viene...)
            when fecha_plazo >= current_date then null
            when estado in ('en_plazo', 'consta') then 1.0
            when estado = 'fuera_plazo' then 0.5
            when estado = 'no_consta' then 0.0
            when estado = 'con_registros' and n_total > 0 then 1.0 - n_fuera_plazo::double / n_total
        end as puntuacion,
        fecha_plazo < current_date as vencido
    from unido
),

alcaldes as (
    select cod_mun, fecha_posesion, fecha_fin, alcalde, partido_original, familia, color
    from {{ ref('alcaldes_historia') }}
),

presidentes as (
    select cod, desde, hasta, presidente, familia
    from {{ ref('gobiernos_presidentes') }}
    where nivel = 'autonomico'
),

atribuido as (
    select
        p.*,
        -- el seed de presidentes agrupa a veces varios por tramo del mismo partido
        -- («Urkullu, Pradales»): entonces solo se sabe el partido, no la persona
        coalesce(a.alcalde, case when g.presidente not like '%,%' then g.presidente end) as gobernante_en_plazo,
        coalesce(a.familia, g.familia) as familia_en_plazo,
        a.partido_original as lista_en_plazo
    from puntuado p
    left join alcaldes a
        on p.tipo_entidad = 'Ayuntamiento'
        and a.cod_mun = p.cod_mun
        and a.fecha_posesion <= p.fecha_plazo
        and coalesce(a.fecha_fin, date '9999-12-31') > p.fecha_plazo
    left join presidentes g
        on p.tipo_entidad = 'Comunidad autónoma'
        and g.cod = p.cod_ccaa
        and g.desde <= p.fecha_plazo
        and coalesce(g.hasta, date '9999-12-31') > p.fecha_plazo
    qualify row_number() over (
        partition by p.obligacion, p.cod_entidad, p.periodo
        order by a.fecha_posesion desc nulls last, g.desde desc nulls last
    ) = 1
),

ultimo as (
    select
        *,
        -- último periodo con puntuación de cada entidad y obligación
        puntuacion is not null and row_number() over (
            partition by obligacion, cod_entidad, (puntuacion is not null)
            order by fecha_plazo desc, periodo desc
        ) = 1 as es_ultimo
    from atribuido
)

select
    u.*,
    case
        when u.poblacion is null then null
        when u.poblacion < 1000 then '<1.000'
        when u.poblacion < 5000 then '1.000-5.000'
        when u.poblacion < 20000 then '5.000-20.000'
        when u.poblacion < 100000 then '20.000-100.000'
        else '>100.000'
    end as tramo_poblacion,
    case
        when u.poblacion is null then null
        when u.poblacion < 1000 then 1
        when u.poblacion < 5000 then 2
        when u.poblacion < 20000 then 3
        when u.poblacion < 100000 then 4
        else 5
    end as tramo_orden,
    -- incumplimiento a destacar: plazo vencido hace más de 3 meses y no consta nada
    u.bloque = 'remision' and u.es_ultimo and u.estado = 'no_consta' and u.fecha_plazo < current_date - interval 90 day as incumplimiento_destacado,
    tc.nombre as ccaa,
    tp.nombre as provincia,
    u.obligacion || '|' || u.cod_entidad || '|' || u.periodo as clave
from ultimo u
left join {{ ref('territorios') }} tc on tc.nivel = 'ccaa' and tc.cod = u.cod_ccaa
left join {{ ref('territorios') }} tp on tp.nivel = 'provincia' and tp.cod = u.cod_prov
