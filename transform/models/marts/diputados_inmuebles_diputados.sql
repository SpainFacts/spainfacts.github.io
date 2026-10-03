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
-- extraccion_ok = false: el OCR no reconoce las tablas o la declaración remite a otra;
-- esas filas tienen las capas a null y se excluyen de los porcentajes.
with d as (
    select * from {{ source('raw_diputados_inmuebles', 'cong_declaraciones_bienes') }}
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
    d.circunscripcion,
    cast(d.fecha_declaracion as date) as fecha_declaracion,
    cast(d.ejercicio_rentas as integer) as ejercicio_rentas,
    d.extraccion_ok,
    case when d.extraccion_ok then cast(d.n_inmuebles as integer) end as n_inmuebles,
    case when d.extraccion_ok then cast(d.n_urbanos as integer) end as n_urbanos,
    case when d.extraccion_ok then cast(d.n_viviendas_urbanas as integer) end as n_viviendas_urbanas,
    case when d.extraccion_ok then cast(d.n_rusticos as integer) end as n_rusticos,
    case when d.extraccion_ok then cast(d.n_sociedad as integer) end as n_inmuebles_sociedad,
    case when d.extraccion_ok then d.urbanos_equivalentes end as urbanos_equivalentes,
    case when d.extraccion_ok then d.n_rentas_alquiler > 0 end as alquila,
    case when d.extraccion_ok then d.rend_capital_inmobiliario_eur end as rend_capital_inmobiliario_eur,
    case when d.extraccion_ok then round(d.rend_capital_inmobiliario_eur * f.factor, 2) end as rend_real_eur,
    case when d.extraccion_ok then d.n_urbanos >= 2 end as dos_urbanos,
    case when d.extraccion_ok then d.n_viviendas_urbanas >= 2 end as dos_viviendas,
    case when d.extraccion_ok then d.urbanos_equivalentes >= 2 end as dos_equivalentes,
    case when d.extraccion_ok then d.vivienda_habitual_declarada end as vivienda_habitual_declarada,
    case when d.extraccion_ok then d.menciona_alquiler_fuera_rentas end as menciona_alquiler_fuera_rentas,
    cast(d.n_declaraciones_bienes as integer) as n_declaraciones_bienes,
    d.url_pdf,
    d.url_ultima_declaracion,
    d.nota
from d
left join {{ ref('deflactor') }} f on f.anio = cast(d.ejercicio_rentas as integer)
