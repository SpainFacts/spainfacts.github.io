-- España frente a otros países en índices internacionales de corrupción,
-- integridad y gobierno abierto. Formato largo: una fila por indicador, país y año.
--
-- Países: los de la UE-27 y la OCDE (38), más Marruecos y China. es_referencia
-- marca los que la página enseña en las gráficas (España, Francia, Portugal,
-- Alemania, Italia, Marruecos, EE. UU., China y los referentes de integridad:
-- Dinamarca, Finlandia, Nueva Zelanda y Estonia).
--
-- Agregados EUU (UE-27) y OED (OCDE): MEDIA SIMPLE de los países miembros actuales
-- con dato ese año (no ponderada por población), solo si hay dato de al menos el
-- 90 % de ellos, y solo en los índices cuya licencia permite obras derivadas
-- (Banco Mundial WGI y V-Dem). El CPI (CC BY-ND) y el WJP (CC BY-NC-ND) se
-- reproducen tal cual, sin medias propias.
--
-- puesto_ue / puesto_ocde: posición del país entre los miembros con dato ese año
-- (1 = el mejor según `sentido`); n_ue / n_ocde: cuántos tienen dato.
-- puesto_mundial: el oficial de Transparency International (CPI, desde 2017).
-- sentido: 'positivo' si un valor mayor es mejor, 'negativo' si es peor.
with catalogo (indicador_id, nombre, nombre_corto, unidad, sentido, agregable, fuente, url_fuente, orden_indicador) as (
    values
    ('cpi', 'Índice de Percepción de la Corrupción (CPI)', 'Percepción de la corrupción', 'puntos (0-100; 100 = muy limpio)', 'positivo', false, 'Transparency International', 'https://www.transparency.org/en/cpi', 1),
    ('wgi_control_corrupcion', 'Control de la corrupción (WGI)', 'Control de la corrupción', 'puntuación 0-100', 'positivo', true, 'Banco Mundial (Worldwide Governance Indicators)', 'https://www.worldbank.org/en/publication/worldwide-governance-indicators', 2),
    ('wgi_voz_rendicion_cuentas', 'Voz y rendición de cuentas (WGI)', 'Voz y rendición de cuentas', 'puntuación 0-100', 'positivo', true, 'Banco Mundial (Worldwide Governance Indicators)', 'https://www.worldbank.org/en/publication/worldwide-governance-indicators', 3),
    ('wgi_eficacia_gobierno', 'Eficacia del gobierno (WGI)', 'Eficacia del gobierno', 'puntuación 0-100', 'positivo', true, 'Banco Mundial (Worldwide Governance Indicators)', 'https://www.worldbank.org/en/publication/worldwide-governance-indicators', 4),
    ('wgi_estado_derecho', 'Estado de derecho (WGI)', 'Estado de derecho', 'puntuación 0-100', 'positivo', true, 'Banco Mundial (Worldwide Governance Indicators)', 'https://www.worldbank.org/en/publication/worldwide-governance-indicators', 5),
    ('vdem_corrupcion_politica', 'Índice de corrupción política (V-Dem)', 'Corrupción política', 'índice 0-1 (1 = máxima corrupción)', 'negativo', true, 'V-Dem vía Our World in Data', 'https://ourworldindata.org/grapher/political-corruption-index', 6),
    ('vdem_corrupcion_sector_publico', 'Corrupción en el sector público (V-Dem)', 'Corrupción en el sector público', 'índice 0-1 (1 = máxima corrupción)', 'negativo', true, 'V-Dem vía Our World in Data', 'https://ourworldindata.org/grapher/public-sector-corruption-index', 7),
    ('wjp_estado_derecho', 'Índice de Estado de Derecho (WJP)', 'Estado de derecho (WJP)', 'puntuación 0-1', 'positivo', false, 'World Justice Project', 'https://worldjusticeproject.org/rule-of-law-index/', 8),
    ('wjp_ausencia_corrupcion', 'Ausencia de corrupción (WJP, factor 2)', 'Ausencia de corrupción', 'puntuación 0-1', 'positivo', false, 'World Justice Project', 'https://worldjusticeproject.org/rule-of-law-index/', 9),
    ('wjp_gobierno_abierto', 'Gobierno abierto (WJP, factor 3)', 'Gobierno abierto', 'puntuación 0-1', 'positivo', false, 'World Justice Project', 'https://worldjusticeproject.org/rule-of-law-index/', 10),
    ('wjp_limites_gobierno', 'Límites al poder del gobierno (WJP, factor 1)', 'Límites al poder del gobierno', 'puntuación 0-1', 'positivo', false, 'World Justice Project', 'https://worldjusticeproject.org/rule-of-law-index/', 11)
),

paises (cod_pais, pais, es_ue, es_ocde, es_referencia, orden_pais) as (
    values
    ('ESP', 'España', true, true, true, 1),
    ('FRA', 'Francia', true, true, true, 4),
    ('DEU', 'Alemania', true, true, true, 5),
    ('ITA', 'Italia', true, true, true, 6),
    ('PRT', 'Portugal', true, true, true, 7),
    ('MAR', 'Marruecos', false, false, true, 8),
    ('USA', 'Estados Unidos', false, true, true, 9),
    ('CHN', 'China', false, false, true, 10),
    ('DNK', 'Dinamarca', true, true, true, 11),
    ('FIN', 'Finlandia', true, true, true, 12),
    ('NZL', 'Nueva Zelanda', false, true, true, 13),
    ('EST', 'Estonia', true, true, true, 14),
    ('AUT', 'Austria', true, true, false, 20),
    ('BEL', 'Bélgica', true, true, false, 20),
    ('BGR', 'Bulgaria', true, false, false, 20),
    ('HRV', 'Croacia', true, false, false, 20),
    ('CYP', 'Chipre', true, false, false, 20),
    ('CZE', 'Chequia', true, true, false, 20),
    ('GRC', 'Grecia', true, true, false, 20),
    ('HUN', 'Hungría', true, true, false, 20),
    ('IRL', 'Irlanda', true, true, false, 20),
    ('LVA', 'Letonia', true, true, false, 20),
    ('LTU', 'Lituania', true, true, false, 20),
    ('LUX', 'Luxemburgo', true, true, false, 20),
    ('MLT', 'Malta', true, false, false, 20),
    ('NLD', 'Países Bajos', true, true, false, 20),
    ('POL', 'Polonia', true, true, false, 20),
    ('ROU', 'Rumanía', true, false, false, 20),
    ('SVK', 'Eslovaquia', true, true, false, 20),
    ('SVN', 'Eslovenia', true, true, false, 20),
    ('SWE', 'Suecia', true, true, false, 20),
    ('AUS', 'Australia', false, true, false, 30),
    ('CAN', 'Canadá', false, true, false, 30),
    ('CHL', 'Chile', false, true, false, 30),
    ('COL', 'Colombia', false, true, false, 30),
    ('CRI', 'Costa Rica', false, true, false, 30),
    ('ISL', 'Islandia', false, true, false, 30),
    ('ISR', 'Israel', false, true, false, 30),
    ('JPN', 'Japón', false, true, false, 30),
    ('KOR', 'Corea del Sur', false, true, false, 30),
    ('MEX', 'México', false, true, false, 30),
    ('NOR', 'Noruega', false, true, false, 30),
    ('CHE', 'Suiza', false, true, false, 30),
    ('TUR', 'Turquía', false, true, false, 30),
    ('GBR', 'Reino Unido', false, true, false, 30)
),

series as (
    select s.*, p.pais, p.es_ue, p.es_ocde, p.es_referencia, p.orden_pais
    from {{ ref('stg_transparencia_internacional') }} s
    join paises p using (cod_pais)
    where s.valor is not null
),

con_puesto as (
    select
        s.*,
        case when s.es_ue then rank() over (
            partition by s.indicador_id, s.anio, s.es_ue
            order by case when c.sentido = 'negativo' then s.valor else -s.valor end) end as puesto_ue,
        case when s.es_ue then count(*) over (partition by s.indicador_id, s.anio, s.es_ue) end as n_ue,
        case when s.es_ocde then rank() over (
            partition by s.indicador_id, s.anio, s.es_ocde
            order by case when c.sentido = 'negativo' then s.valor else -s.valor end) end as puesto_ocde,
        case when s.es_ocde then count(*) over (partition by s.indicador_id, s.anio, s.es_ocde) end as n_ocde
    from series s
    join catalogo c using (indicador_id)
),

agregados as (
    select s.indicador_id, 'EUU' as cod_pais, 'Unión Europea (media simple)' as pais, s.anio, avg(s.valor) as valor
    from series s join catalogo c using (indicador_id)
    where c.agregable and s.es_ue
    group by s.indicador_id, s.anio
    having count(*) >= 0.9 * 27
    union all
    select s.indicador_id, 'OED', 'OCDE (media simple)', s.anio, avg(s.valor)
    from series s join catalogo c using (indicador_id)
    where c.agregable and s.es_ocde
    group by s.indicador_id, s.anio
    having count(*) >= 0.9 * 38
),

todo as (
    select indicador_id, cod_pais, pais, false as es_agregado, es_ue, es_ocde, es_referencia, orden_pais,
           anio, valor, valor_min, valor_max, puesto_mundial,
           cast(puesto_ue as integer) as puesto_ue, cast(n_ue as integer) as n_ue,
           cast(puesto_ocde as integer) as puesto_ocde, cast(n_ocde as integer) as n_ocde
    from con_puesto
    union all
    select indicador_id, cod_pais, pais, true, false, false, true,
           case cod_pais when 'EUU' then 2 else 3 end,
           anio, valor, null, null, null, null, null, null, null
    from agregados
)

select
    t.indicador_id,
    c.nombre,
    c.nombre_corto,
    t.pais,
    t.cod_pais,
    cast(t.anio as integer) as anio,
    cast(t.valor as double) as valor,
    c.unidad,
    c.sentido,
    c.fuente,
    c.url_fuente,
    c.orden_indicador,
    t.es_agregado,
    t.es_ue,
    t.es_ocde,
    t.es_referencia,
    t.orden_pais,
    cast(t.valor_min as double) as valor_min,
    cast(t.valor_max as double) as valor_max,
    cast(t.puesto_mundial as integer) as puesto_mundial,
    t.puesto_ue,
    t.n_ue,
    t.puesto_ocde,
    t.n_ocde
from todo t
join catalogo c using (indicador_id)
