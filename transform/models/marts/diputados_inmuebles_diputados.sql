-- Inmuebles y alquileres declarados por cada diputado del Congreso (XV Legislatura),
-- según su declaración INICIAL de Bienes y Rentas (Registro de Intereses del Congreso,
-- PDF escaneados de la ficha de cada diputado, leídos por OCR en
-- ingestion/diputados_inmuebles.py). Son declaraciones oficiales publicadas.
--
-- Capas de "casero" (definiciones objetivas, cada una en su columna):
--   alquila            (a) declara al menos una renta cuyo concepto es un alquiler o
--                      arrendamiento (el formulario no tiene casilla de capital
--                      inmobiliario: se declara en "otras rentas"); importe en
--                      rend_capital_inmobiliario_eur, del ejercicio anterior a la declaración.
--   dos_urbanos        (b) declara 2 o más inmuebles urbanos (garajes y trasteros incluidos).
--   dos_viviendas      (b') declara 2 o más inmuebles urbanos que son viviendas.
--   dos_equivalentes   (c) la suma de su fracción de titularidad en inmuebles urbanos es >= 2
--                      (un piso al 50 % cuenta 0,5; ganancial sin % = 0,5).
-- Euros reales: rend_real_eur = nominal * factor de main.deflactor del ejercicio (euros de 2025).
-- extraccion_ok = false: la declaración no se puede usar (ilegible o remite a otra);
-- esas filas tienen las capas a null y se excluyen de los porcentajes.
-- Todas las declaraciones se han revisado a mano en el PDF (seed
-- diputados_inmuebles_revisados): sus recuentos, fracciones, desglose por tipo y título
-- de adquisición, si declara ingresos por alquiler y si la lectura es válida mandan sobre
-- el OCR, que solo queda como respaldo para un diputado nuevo aún sin revisar
-- (revisado_a_mano = false). n_inmuebles = urbanos + rústicos a su nombre (los de
-- sociedades no cotizadas van aparte, en n_inmuebles_sociedad). El importe del alquiler
-- (rend_*) es el leído por el OCR, solo si la revisión confirma que declara alquiler.
-- partido: formación por la que fue elegido, con las federaciones del PSOE (PSC, PSdeG...)
-- dentro de PSOE.
with r as (
    select * from {{ ref('diputados_inmuebles_revisados') }}
),

d as (
    select
        o.* replace (
            coalesce(r.n_urbanos, o.n_urbanos) as n_urbanos,
            coalesce(r.n_viviendas_urbanas, o.n_viviendas_urbanas) as n_viviendas_urbanas,
            coalesce(r.n_rusticos, o.n_rusticos) as n_rusticos,
            coalesce(r.n_sociedad, o.n_sociedad) as n_sociedad,
            coalesce(r.urbanos_equivalentes, o.urbanos_equivalentes) as urbanos_equivalentes,
            coalesce(r.lectura_valida, o.extraccion_ok) as extraccion_ok
        ),
        r.n_garajes_trasteros,
        r.n_locales,
        r.n_otros_urbanos,
        r.n_urbanos_herencia,
        r.n_urbanos_compra,
        coalesce(r.declara_alquiler, o.n_rentas_alquiler > 0) as declara_alquiler,
        r.id_diputado is not null as revisado_a_mano
    from {{ source('raw_diputados_inmuebles', 'cong_declaraciones_bienes') }} o
    left join r on r.id_diputado = cast(o.id_diputado as integer)
)

select
    cast(d.legislatura as integer) as legislatura,
    cast(d.id_diputado as integer) as id_diputado,
    d.nombre,
    d.grupo_parlamentario,
    case
        when d.grupo_parlamentario like '%Popular%' then 'PP'
        when d.grupo_parlamentario like '%Socialista%' then 'PSOE'
        when d.grupo_parlamentario like '%VOX%' then 'Vox'
        when d.grupo_parlamentario like '%SUMAR%' then 'Sumar'
        when d.grupo_parlamentario like '%Republicano%' then 'ERC'
        when d.grupo_parlamentario like '%Junts%' then 'Junts'
        when d.grupo_parlamentario like '%Bildu%' then 'EH Bildu'
        when d.grupo_parlamentario like '%Vasco%' then 'PNV'
        when d.grupo_parlamentario like '%Mixto%' then 'Mixto'
        else d.grupo_parlamentario
    end as grupo,
    d.formacion,
    case
        when d.formacion like '%PSOE%' then 'PSOE'
        when d.formacion = 'VOX' then 'Vox'
        when d.formacion = 'SUMAR' then 'Sumar'
        when d.formacion = 'JxCAT-JUNTS' then 'Junts'
        when d.formacion = 'EAJ-PNV' then 'PNV'
        when d.formacion = 'CCa' then 'CC'
        else d.formacion
    end as partido,
    d.circunscripcion,
    try_strptime(d.fecha_alta, '%d/%m/%Y')::date as fecha_alta,
    cast(d.fecha_declaracion as date) as fecha_declaracion,
    -- valida | sin_declaracion (su ficha no enlaza ninguna declaración de bienes) |
    -- incompleta (ilegible o remite a una declaración anterior que ya no se publica)
    case
        when d.url_pdf is null then 'sin_declaracion'
        when not d.extraccion_ok then 'incompleta'
        else 'valida'
    end as estado_declaracion,
    cast(d.ejercicio_rentas as integer) as ejercicio_rentas,
    d.extraccion_ok,
    case when d.extraccion_ok then cast(d.n_urbanos + d.n_rusticos as integer) end as n_inmuebles,
    case when d.extraccion_ok then cast(d.n_urbanos as integer) end as n_urbanos,
    case when d.extraccion_ok then cast(d.n_viviendas_urbanas as integer) end as n_viviendas_urbanas,
    case when d.extraccion_ok then d.n_garajes_trasteros end as n_garajes_trasteros,
    case when d.extraccion_ok then d.n_locales end as n_locales,
    case when d.extraccion_ok then d.n_otros_urbanos end as n_otros_urbanos,
    case when d.extraccion_ok then d.n_urbanos_herencia end as n_urbanos_herencia,
    case when d.extraccion_ok then d.n_urbanos_compra end as n_urbanos_compra,
    case when d.extraccion_ok then cast(d.n_rusticos as integer) end as n_rusticos,
    case when d.extraccion_ok then cast(d.n_sociedad as integer) end as n_inmuebles_sociedad,
    case when d.extraccion_ok then d.urbanos_equivalentes end as urbanos_equivalentes,
    case when d.extraccion_ok then d.declara_alquiler end as alquila,
    case when d.extraccion_ok and d.declara_alquiler then nullif(d.rend_capital_inmobiliario_eur, 0) end as rend_capital_inmobiliario_eur,
    case when d.extraccion_ok and d.declara_alquiler then round(nullif(d.rend_capital_inmobiliario_eur, 0) * f.factor, 2) end as rend_real_eur,
    case when d.extraccion_ok then d.n_urbanos >= 2 end as dos_urbanos,
    case when d.extraccion_ok then d.n_viviendas_urbanas >= 2 end as dos_viviendas,
    case when d.extraccion_ok then d.urbanos_equivalentes >= 2 end as dos_equivalentes,
    case when d.extraccion_ok then d.vivienda_habitual_declarada end as vivienda_habitual_declarada,
    case when d.extraccion_ok then d.menciona_alquiler_fuera_rentas end as menciona_alquiler_fuera_rentas,
    cast(d.n_declaraciones_bienes as integer) as n_declaraciones_bienes,
    d.url_pdf,
    d.url_ultima_declaracion,
    d.revisado_a_mano,
    d.nota
from d
left join {{ ref('deflactor') }} f on f.anio = cast(d.ejercicio_rentas as integer)
