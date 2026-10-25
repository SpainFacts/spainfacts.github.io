-- Indicadores por municipio para el explorador de mapas (/varios/mapas/, nivel «Municipio»).
-- Mismo formato largo que mapas_indicadores (una fila por indicador, municipio y año), hecho
-- con marts que ya existen. Importes por habitante y en euros reales; los flujos anuales sin
-- el año en curso (incompleto). Ordenado por indicador y año para que el navegador lea solo
-- los grupos de filas del indicador elegido.
WITH
padron AS (
    SELECT CAST(anio AS INTEGER) AS anio, cod_mun, municipio, poblacion
    FROM poblacion_municipios WHERE sexo = 'Total'
),
nombres AS (
    SELECT cod_mun, arg_max(municipio, anio) AS municipio FROM padron GROUP BY cod_mun
),
largo AS (
    -- Demografía ---------------------------------------------------------------
    SELECT 'mun_poblacion' AS indicador_id, cod_mun AS cod, anio, CAST(poblacion AS DOUBLE) AS valor
    FROM padron WHERE anio >= 2000
    UNION ALL
    SELECT 'mun_crecimiento_10', p.cod_mun, p.anio, 100.0 * (p.poblacion - a.poblacion) / nullif(a.poblacion, 0)
    FROM padron p JOIN padron a ON a.cod_mun = p.cod_mun AND a.anio = p.anio - 10
    WHERE p.anio >= 2010
    -- Renta (ADRH) -------------------------------------------------------------
    UNION ALL
    SELECT 'mun_renta_persona', cod_mun, CAST(anio AS INTEGER), renta_persona_real FROM renta_municipios WHERE renta_persona_real IS NOT NULL
    UNION ALL
    SELECT 'mun_renta_hogar', cod_mun, CAST(anio AS INTEGER), renta_hogar_real FROM renta_municipios WHERE renta_hogar_real IS NOT NULL
    -- Paro registrado (último mes publicado) -----------------------------------
    UNION ALL
    SELECT 'mun_paro_100', cod_municipio, CAST(year(mes) AS INTEGER), por_100_hab FROM mercado_paro_municipios
    WHERE NOT coalesce(oculto, false) AND por_100_hab IS NOT NULL
    -- Vivienda ------------------------------------------------------------------
    UNION ALL
    SELECT 'mun_vivienda_precio_m2', cod_mun, CAST(anio AS INTEGER), euros_m2_real FROM vivienda_precio_municipios WHERE euros_m2_real IS NOT NULL
    UNION ALL
    SELECT 'mun_alquiler_mes', cod_mun, CAST(anio AS INTEGER), alquiler_mes_mediana_real FROM vivienda_alquiler_municipios WHERE alquiler_mes_mediana_real IS NOT NULL
    UNION ALL
    SELECT 'mun_alquiladas_1000', cod_mun, CAST(anio AS INTEGER), alquiladas_1000 FROM vivienda_alquiler_municipios WHERE alquiladas_1000 IS NOT NULL
    UNION ALL
    -- viviendas turísticas: el último recuento de cada año (es un parque, no un flujo)
    SELECT 'mun_turisticas_1000', cod_mun, CAST(anio AS INTEGER), arg_max(viviendas_1000hab, periodo)
    FROM turismo_viviendas_municipios WHERE viviendas_1000hab IS NOT NULL GROUP BY cod_mun, anio
    UNION ALL
    SELECT 'mun_turisticas_pct', cod_mun, CAST(anio AS INTEGER), arg_max(pct_viviendas, periodo)
    FROM turismo_viviendas_municipios WHERE pct_viviendas IS NOT NULL GROUP BY cod_mun, anio
    -- Cuentas del ayuntamiento --------------------------------------------------
    UNION ALL
    SELECT 'mun_gasto_hab', cod_mun, CAST(anio AS INTEGER), gasto_hab_real FROM municipios_cuentas WHERE tiene_datos AND gasto_hab_real IS NOT NULL
    UNION ALL
    SELECT 'mun_ingreso_hab', cod_mun, CAST(anio AS INTEGER), ingreso_hab_real FROM municipios_cuentas WHERE tiene_datos AND ingreso_hab_real IS NOT NULL
    UNION ALL
    SELECT 'mun_saldo_hab', cod_mun, CAST(anio AS INTEGER), saldo_hab_real FROM municipios_cuentas WHERE tiene_datos AND saldo_hab_real IS NOT NULL
    -- Movilidad (matriculaciones: años completos) -------------------------------
    UNION ALL
    SELECT 'mun_matric_1000', cod_mun, CAST(anio AS INTEGER), particulares_por_1000_hab FROM movilidad_matriculaciones_municipio
    WHERE anio < year(current_date) AND particulares_por_1000_hab IS NOT NULL
    UNION ALL
    SELECT 'mun_matric_pct_enchufables', cod_mun, CAST(anio AS INTEGER), coalesce(bev_pct, 0) + coalesce(phev_pct, 0) FROM movilidad_matriculaciones_municipio
    WHERE anio < year(current_date) AND turismos >= 20 AND (bev_pct IS NOT NULL OR phev_pct IS NOT NULL)
    -- Elecciones al Congreso (cada elección es un «año») ------------------------
    UNION ALL
    SELECT 'mun_congreso_' || capa, cod_mun, CAST(anio AS INTEGER), v
    FROM (
        SELECT cod_mun, anio,
            unnest(['participacion', 'izquierda', 'derecha', 'psoe', 'pp', 'vox', 'ips', 'nacionalistas']) AS capa,
            unnest([participacion, pct_izquierda, pct_derecha, pct_psoe, pct_pp, pct_vox, pct_iu_podemos_sumar, pct_nacionalistas]) AS v
        FROM elecciones_municipios WHERE tipo = '02'
          -- años con dos elecciones (2019): solo la última
          AND proceso = (SELECT max(e2.proceso) FROM elecciones_municipios e2 WHERE e2.tipo = '02' AND e2.anio = elecciones_municipios.anio)
    ) WHERE v IS NOT NULL
),
meta (indicador_id, nombre, tema, unidad, sentido, fuente, url_fuente, pagina, nota) AS (
    VALUES
    ('mun_poblacion', 'Población', 'Demografía', 'habitantes', 'neutro', 'INE (padrón)', 'https://www.ine.es/dynt3/inebase/es/index.htm?padre=517', '/territorios/municipios/', NULL),
    ('mun_crecimiento_10', 'Variación de la población en 10 años', 'Demografía', '%', 'neutro', 'INE (padrón)', 'https://www.ine.es/dynt3/inebase/es/index.htm?padre=517', '/demografia/evolucion-poblacion/', 'Cambio del padrón respecto al de diez años antes'),
    ('mun_renta_persona', 'Renta neta media por persona (real)', 'Economía', '€/hab (€ constantes)', 'positivo', 'INE (ADRH)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=53689', '/territorios/municipios/', 'Solo municipios de más de 1.000 habitantes'),
    ('mun_renta_hogar', 'Renta neta media por hogar (real)', 'Economía', '€/hogar (€ constantes)', 'positivo', 'INE (ADRH)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=53689', '/territorios/municipios/', 'Solo municipios de más de 1.000 habitantes'),
    ('mun_paro_100', 'Paro registrado por 100 habitantes', 'Economía', 'por 100 hab', 'negativo', 'SEPE', 'https://sede.sepe.gob.es/es/portaltrabaja/resources/sede/datos_abiertos/datos/Paro_por_municipios_2026_csv.csv', '/economia/paro/', 'Último mes publicado; el SEPE oculta los municipios con menos de 5 parados'),
    ('mun_vivienda_precio_m2', 'Precio de la vivienda libre por m² (tasación, real)', 'Vivienda', '€/m² (€ constantes)', 'neutro', 'Ministerio de Vivienda', 'https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000', '/vivienda/precios/', 'Solo municipios de más de 25.000 habitantes'),
    ('mun_alquiler_mes', 'Alquiler mensual mediano (real)', 'Vivienda', '€/mes (€ constantes)', 'negativo', 'Ministerio de Vivienda (SERPAVI)', 'https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi', '/vivienda/alquiler/', 'Mediana de los contratos con fianza depositada'),
    ('mun_alquiladas_1000', 'Viviendas en alquiler por 1.000 habitantes', 'Vivienda', 'por 1.000 hab', 'neutro', 'Ministerio de Vivienda (SERPAVI)', 'https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi', '/vivienda/alquiler/', NULL),
    ('mun_turisticas_1000', 'Viviendas turísticas por 1.000 habitantes', 'Vivienda', 'por 1.000 hab', 'neutro', 'INE (medición experimental)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=39363', '/economia/turismo/', 'Último recuento de cada año'),
    ('mun_turisticas_pct', 'Viviendas turísticas (% de las viviendas)', 'Vivienda', '%', 'neutro', 'INE (medición experimental)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=39363', '/economia/turismo/', 'Último recuento de cada año'),
    ('mun_gasto_hab', 'Gasto del ayuntamiento por habitante (real)', 'Cuentas públicas', '€/hab (€ constantes)', 'neutro', 'Ministerio de Hacienda (liquidaciones)', 'https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL', '/territorios/municipios/', 'Obligaciones reconocidas en la liquidación del presupuesto'),
    ('mun_ingreso_hab', 'Ingresos del ayuntamiento por habitante (real)', 'Cuentas públicas', '€/hab (€ constantes)', 'neutro', 'Ministerio de Hacienda (liquidaciones)', 'https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL', '/territorios/municipios/', 'Derechos reconocidos en la liquidación del presupuesto'),
    ('mun_saldo_hab', 'Saldo no financiero del ayuntamiento por habitante (real)', 'Cuentas públicas', '€/hab (€ constantes)', 'positivo', 'Ministerio de Hacienda (liquidaciones)', 'https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL', '/territorios/municipios/', 'Superávit (+) o déficit (−)'),
    ('mun_matric_1000', 'Turismos matriculados por particulares por 1.000 habitantes', 'Movilidad', 'por 1.000 hab', 'neutro', 'DGT', 'https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html', '/movilidad/coche-electrico/', 'Por el domicilio del titular; años completos'),
    ('mun_matric_pct_enchufables', 'Turismos enchufables (% de las matriculaciones)', 'Movilidad', '%', 'positivo', 'DGT', 'https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html', '/movilidad/coche-electrico/', 'Eléctricos e híbridos enchufables; municipios con al menos 20 matriculaciones en el año'),
    ('mun_congreso_participacion', 'Participación en las elecciones al Congreso', 'Sociedad', '% del censo', 'positivo', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'Cada año es una elección (en 2019, la de noviembre)'),
    ('mun_congreso_izquierda', 'Voto a la izquierda (Congreso)', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'Cada año es una elección (en 2019, la de noviembre)'),
    ('mun_congreso_derecha', 'Voto a la derecha (Congreso)', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'Cada año es una elección (en 2019, la de noviembre)'),
    ('mun_congreso_psoe', 'Voto al PSOE (Congreso)', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'Cada año es una elección (en 2019, la de noviembre)'),
    ('mun_congreso_pp', 'Voto al PP (Congreso)', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'Cada año es una elección (en 2019, la de noviembre)'),
    ('mun_congreso_vox', 'Voto a Vox (Congreso)', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'Cada año es una elección (en 2019, la de noviembre)'),
    ('mun_congreso_ips', 'Voto a IU, Podemos y Sumar (Congreso)', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'Cada año es una elección (en 2019, la de noviembre)'),
    ('mun_congreso_nacionalistas', 'Voto a nacionalistas y regionalistas (Congreso)', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'Cada año es una elección (en 2019, la de noviembre)')
)
SELECT l.indicador_id, m.nombre, m.tema, 'Municipio' AS nivel, l.cod, n.municipio AS territorio,
    l.anio, l.valor, m.unidad, m.sentido, m.fuente, m.url_fuente, m.pagina, m.nota
FROM largo l
JOIN meta m USING (indicador_id)
LEFT JOIN nombres n ON n.cod_mun = l.cod
WHERE l.valor IS NOT NULL AND isfinite(l.valor)
ORDER BY l.indicador_id, l.anio, l.cod
