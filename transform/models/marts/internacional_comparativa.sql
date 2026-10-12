-- España frente a otros países y agregados, formato largo: una fila por
-- indicador, país y año. cod_pais = ISO alfa-2 (EU27_2020 la UE, OECD la OCDE) con el
-- seed paises_iso; la ingesta trae el ISO3 y aquí se traduce. Países: España, Francia, Portugal, Marruecos,
-- Estados Unidos, China, Alemania e Italia; agregados: Unión Europea (EUU) y
-- OCDE (OED); y países de referencia que la web solo muestra en los indicadores
-- donde son un caso emblemático (src/lib/paisesReferencia.js): Noruega,
-- Dinamarca, Suecia, Países Bajos, Grecia, Japón, Corea del Sur e Israel
-- (es_referencia = true). Los agregados del Banco Mundial están ponderados (por población,
-- PIB...), no son medias simples de países. Los indicadores de Eurostat solo
-- tienen países europeos y la UE-27; la deuda del FMI no tiene agregado OCDE;
-- los coches eléctricos (AIE vía Our World in Data) no tienen OCDE ni Marruecos. La vivienda social
-- (OCDE PH4.2) añade Austria y Reino Unido (Inglaterra) como referencia y tiene
-- pocos años por país (hacia 2010 y hacia 2022).
-- sentido: 'positivo' si un valor mayor es mejor, 'negativo' si es peor,
-- 'neutro' si no tiene lectura clara.
-- Indicadores: los del seed internacional_indicadores con en_comparativa (nombre, unidad,
-- apartado, sentido y fuente); el mismo indicador_id puede existir con otra fuente en el
-- otro ámbito (paro de Eurostat en internacional_europa), por eso se une por ámbito.
with catalogo as (
    select ambito, indicador_id, nombre, unidad, apartado, sentido, fuente, url_fuente
    from {{ ref('internacional_indicadores') }}
    where en_comparativa
),

paises (cod_pais, pais, es_agregado, es_referencia, orden_pais) as (
    values
    ('ESP', 'España', false, false, 1),
    ('EUU', 'Unión Europea', true, false, 2),
    ('OED', 'OCDE', true, false, 3),
    ('FRA', 'Francia', false, false, 4),
    ('DEU', 'Alemania', false, false, 5),
    ('ITA', 'Italia', false, false, 6),
    ('PRT', 'Portugal', false, false, 7),
    ('MAR', 'Marruecos', false, false, 8),
    ('USA', 'Estados Unidos', false, false, 9),
    ('CHN', 'China', false, false, 10),
    ('NOR', 'Noruega', false, true, 11),
    ('DNK', 'Dinamarca', false, true, 12),
    ('SWE', 'Suecia', false, true, 13),
    ('NLD', 'Países Bajos', false, true, 14),
    ('GRC', 'Grecia', false, true, 15),
    ('JPN', 'Japón', false, true, 16),
    ('KOR', 'Corea del Sur', false, true, 17),
    ('ISR', 'Israel', false, true, 18),
    -- solo en vivienda social (OCDE PH4.2)
    ('AUT', 'Austria', false, true, 19),
    ('GBR', 'Reino Unido', false, true, 20)
)

select
    s.indicador_id,
    c.nombre,
    c.unidad,
    c.apartado,
    i.cod_pais,
    p.pais,
    p.es_agregado,
    p.es_referencia,
    p.orden_pais,
    s.anio,
    cast(s.valor as double) as valor,
    c.fuente,
    c.url_fuente,
    c.sentido,
    s.cod_indicador
from {{ ref('stg_internacional_series') }} s
join catalogo c on c.indicador_id = s.indicador_id and c.ambito = s.ambito
join paises p using (cod_pais)
join {{ ref('paises_iso') }} i on i.iso3 = s.cod_pais
where s.valor is not null
