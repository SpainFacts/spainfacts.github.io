-- Libertad de los medios según V-Dem (Varieties of Democracy, versión vía Our World in
-- Data), desde 1970, formato largo: una fila por indicador, país y año.
--
-- Indicadores de valoración de expertos, en la escala latente del modelo de medida de
-- V-Dem (aprox. -4 a +4; más alto = más libertad, 0 ≈ media de todos los países y años):
--   vdem_censura_medios      ¿intenta el Gobierno censurar la prensa y la radiotelevisión? (v2mecenefm)
--   vdem_acoso_periodistas   ¿se acosa a periodistas (demandas, detenciones, agresiones)? (v2meharjrn)
--   vdem_autocensura_medios  ¿se autocensuran los periodistas en temas políticamente sensibles? (v2meslfcen)
--   vdem_sesgo_medios        ¿hay sesgo de los medios contra la oposición? (v2mebias)
-- y el índice de libertad de expresión y fuentes alternativas de información
-- (vdem_libertad_expresion, 0-1 multiplicado por 100: 0-100, más alto = más libertad).
--
-- EU27_2020: MEDIA SIMPLE de los 27 países que hoy forman la UE con dato ese año, solo si
-- hay dato de al menos el 90 % (V-Dem CC BY-SA 4.0 y OWID CC BY 4.0 permiten obras
-- derivadas). puesto_ue / n_ue: posición entre los miembros actuales con dato (1 = más
-- libertad). Países: cod_pais ISO alfa-2 (seed paises_iso).
with catalogo (indicador_id, nombre, nombre_corto, unidad, escala, orden_indicador) as (
    values
    ('vdem_libertad_expresion', 'Libertad de expresión y fuentes alternativas de información (V-Dem)', 'Libertad de expresión', 'índice 0-100 (100 = máxima libertad)', 100, 1),
    ('vdem_censura_medios', 'Ausencia de censura gubernamental de los medios (V-Dem, v2mecenefm)', 'Censura del Gobierno', 'escala latente (más alto = menos censura)', 1, 2),
    ('vdem_acoso_periodistas', 'Ausencia de acoso a periodistas (V-Dem, v2meharjrn)', 'Acoso a periodistas', 'escala latente (más alto = menos acoso)', 1, 3),
    ('vdem_autocensura_medios', 'Ausencia de autocensura de los medios (V-Dem, v2meslfcen)', 'Autocensura', 'escala latente (más alto = menos autocensura)', 1, 4),
    ('vdem_sesgo_medios', 'Ausencia de sesgo de los medios contra la oposición (V-Dem, v2mebias)', 'Sesgo de los medios', 'escala latente (más alto = menos sesgo)', 1, 5)
),

referencia (cod_pais, orden_pais) as (
    values ('ES', 1), ('FR', 4), ('DE', 5), ('IT', 6), ('PT', 7), ('NL', 8), ('FI', 9),
           ('DK', 10), ('HU', 11), ('GR', 12), ('GB', 13), ('US', 14), ('MA', 15)
),

series as (
    select v.indicador_id, p.cod_pais, p.pais, p.es_ue, cast(v.anio as integer) as anio,
           cast(v.valor as double) * c.escala as valor
    from {{ source('raw_medios_libertad', 'medios_libertad_vdem') }} v
    join {{ ref('paises_iso') }} p on p.iso3 = v.cod_pais and not p.es_agregado
    join catalogo c using (indicador_id)
    where v.valor is not null
),

con_puesto as (
    select s.*,
        case when s.es_ue then rank() over (partition by s.indicador_id, s.anio, s.es_ue order by s.valor desc) end as puesto_ue,
        case when s.es_ue then count(*) over (partition by s.indicador_id, s.anio, s.es_ue) end as n_ue
    from series s
),

ue as (
    select indicador_id, 'EU27_2020' as cod_pais, 'Unión Europea (media simple)' as pais, anio, avg(valor) as valor
    from series
    where es_ue
    group by indicador_id, anio
    having count(*) >= 0.9 * 27
),

todo as (
    select indicador_id, cod_pais, pais, false as es_agregado, es_ue, anio, valor,
           cast(puesto_ue as integer) as puesto_ue, cast(n_ue as integer) as n_ue
    from con_puesto
    union all
    select indicador_id, cod_pais, pais, true, false, anio, valor, null, null
    from ue
)

select
    t.indicador_id,
    c.nombre,
    c.nombre_corto,
    c.unidad,
    c.orden_indicador,
    t.cod_pais,
    t.pais,
    t.es_agregado,
    t.es_ue,
    (r.cod_pais is not null or t.es_agregado) as es_referencia,
    case when t.es_agregado then 2 else coalesce(r.orden_pais, 20) end as orden_pais,
    t.anio,
    round(t.valor, 3) as valor,
    t.puesto_ue,
    t.n_ue
from todo t
join catalogo c using (indicador_id)
left join referencia r on r.cod_pais = t.cod_pais
