-- Indicadores por sección censal para el explorador de mapas (/varios/mapas/, nivel «Barrio»).
-- Mismo formato largo que mapas_indicadores, más:
--   geo_anio: año del seccionado al que corresponde el código (las teselas guardan cada versión
--             de las secciones; el mapa dibuja la de este año en cada municipio)
--   indicador_municipio: indicador de mapas_municipios que se pinta al alejarse (o NULL)
-- Renta: último año del ADRH. Voto: la última elección de cada tipo (autonómicas: la última de
-- cada comunidad).
WITH
renta AS (
    SELECT 'secc_renta_persona' AS indicador_id, cod_seccion AS cod, seccion, municipio,
        CAST(anio AS INTEGER) AS anio, renta_persona_real AS valor, CAST(geo_anio AS INTEGER) AS geo_anio,
        NULL::VARCHAR AS eleccion
    FROM renta_secciones WHERE anio = (SELECT max(anio) FROM renta_secciones)
    UNION ALL
    SELECT 'secc_renta_hogar', cod_seccion, seccion, municipio, CAST(anio AS INTEGER), renta_hogar_real,
        CAST(geo_anio AS INTEGER), NULL
    FROM renta_secciones WHERE anio = (SELECT max(anio) FROM renta_secciones)
),
ultima AS (
    -- la última elección de cada tipo en cada municipio (en autonómicas cambia por comunidad)
    SELECT cod_mun, tipo, max(proceso) AS proceso FROM elecciones_secciones GROUP BY cod_mun, tipo
),
voto AS (
    SELECT 'secc_' || tipo_txt || '_' || capa AS indicador_id, cod_seccion AS cod, seccion, municipio,
        CAST(anio AS INTEGER) AS anio, v AS valor, CAST(geo_anio AS INTEGER) AS geo_anio, eleccion
    FROM (
        SELECT e.*,
            CASE e.tipo WHEN '02' THEN 'congreso' WHEN '04' THEN 'municipales' WHEN '07' THEN 'europeas' ELSE 'autonomicas' END AS tipo_txt,
            unnest(['participacion', 'izquierda', 'derecha', 'psoe', 'pp', 'vox', 'ips', 'nacionalistas']) AS capa,
            unnest([participacion, pct_izquierda, pct_derecha, pct_psoe, pct_pp, pct_vox, pct_iu_podemos_sumar, pct_nacionalistas]) AS v
        FROM elecciones_secciones e
        JOIN ultima u USING (cod_mun, tipo, proceso)
    )
),
largo AS (SELECT * FROM renta UNION ALL SELECT * FROM voto),
capas (capa, capa_nombre, unidad, sentido) AS (
    VALUES
    ('participacion', 'Participación', '% del censo', 'positivo'),
    ('izquierda', 'Voto a la izquierda', '% de los votos válidos', 'neutro'),
    ('derecha', 'Voto a la derecha', '% de los votos válidos', 'neutro'),
    ('psoe', 'Voto al PSOE', '% de los votos válidos', 'neutro'),
    ('pp', 'Voto al PP', '% de los votos válidos', 'neutro'),
    ('vox', 'Voto a Vox', '% de los votos válidos', 'neutro'),
    ('ips', 'Voto a IU, Podemos y Sumar', '% de los votos válidos', 'neutro'),
    ('nacionalistas', 'Voto a nacionalistas y regionalistas', '% de los votos válidos', 'neutro')
),
tipos (tipo_txt, tipo_nombre, nota) AS (
    VALUES
    ('congreso', 'Congreso', 'Elecciones generales de julio de 2023'),
    ('municipales', 'municipales', 'Elecciones municipales de mayo de 2023 (solo municipios de más de 250 habitantes con listas cerradas)'),
    ('europeas', 'europeas', 'Elecciones europeas de junio de 2024'),
    ('autonomicas', 'autonómicas', 'La última elección autonómica de cada comunidad, con su año (Asturias: solo Gijón; Extremadura: solo Cáceres)')
),
meta AS (
    SELECT 'secc_renta_persona' AS indicador_id, 'Renta neta media por persona (real), por sección' AS nombre, 'Economía' AS tema,
        '€/hab (€ constantes)' AS unidad, 'positivo' AS sentido, 'INE (ADRH)' AS fuente,
        'https://www.ine.es/jaxiT3/Tabla.htm?t=53689' AS url_fuente, '/territorios/municipios/' AS pagina,
        'El ADRH agrupa por arriba y por abajo las secciones extremas' AS nota, 'mun_renta_persona' AS indicador_municipio
    UNION ALL
    SELECT 'secc_renta_hogar', 'Renta neta media por hogar (real), por sección', 'Economía', '€/hogar (€ constantes)', 'positivo',
        'INE (ADRH)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=53689', '/territorios/municipios/',
        'El ADRH agrupa por arriba y por abajo las secciones extremas', 'mun_renta_hogar'
    UNION ALL
    SELECT 'secc_' || t.tipo_txt || '_' || c.capa,
        c.capa_nombre || ' (' || t.tipo_nombre || '), por sección', 'Sociedad', c.unidad, c.sentido,
        'Ministerio del Interior (infoelectoral) y comunidades autónomas',
        'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/territorios/municipios/', t.nota,
        CASE WHEN t.tipo_txt = 'congreso' THEN 'mun_congreso_' || c.capa END
    FROM tipos t CROSS JOIN capas c
)
SELECT l.indicador_id, m.nombre, m.tema, 'Sección censal' AS nivel, l.cod,
    l.seccion || ' · ' || l.municipio AS territorio, l.anio, l.valor, m.unidad, m.sentido, m.fuente,
    m.url_fuente, m.pagina, m.nota, l.geo_anio, m.indicador_municipio
FROM largo l
JOIN meta m USING (indicador_id)
WHERE l.valor IS NOT NULL AND isfinite(l.valor)
ORDER BY l.indicador_id, l.cod
