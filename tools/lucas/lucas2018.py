"""Resumen de LUCAS 2018 TOPSOIL (análisis de laboratorio del suelo) por país y comunidad autónoma.

LUCAS 2018 son 18.984 muestras de la capa de 0-20 cm de toda la UE (y Reino Unido) analizadas
en laboratorio: pH, carbono orgánico, carbonatos, nitrógeno, fósforo y potasio. La JRC (ESDAC)
solo entrega los datos bajo solicitud, así que no se descargan en la ingesta: el fichero lo baja a
mano el dueño del proyecto y este script escribe SOLO medianas y porcentajes por país y por
comunidad (NUTS 2 de España) y por región NUTS 2 de Europa (versión 2016, la de LUCAS) en el seed
transform/seeds/suelos_lucas_2018.csv, nunca los puntos. Incluye el % de puntos con señales de
erosión a menos de 500 m (LUCAS2018_EROSION.csv, mismo directorio) y el de cárcavas, las únicas
que el JRC pudo validar; las señales se ven peor con el cultivo crecido: es un mínimo.

Hay que citar: European Soil Data Centre (ESDAC), esdac.jrc.ec.europa.eu, European Commission,
Joint Research Centre, y Panagos et al. (2022), European Journal of Soil Science 73(6), e13315,
doi:10.1111/ejss.13315.

Uso (con el zip LUCAS-SOIL-2018-data-report-readme-v2.zip descomprimido):
    .venv/Scripts/python.exe -X utf8 tools/lucas/lucas2018.py <ruta>/LUCAS-SOIL-2018.csv
"""

import sys
from pathlib import Path

import duckdb

REPO = Path(__file__).resolve().parents[2]
SALIDA = REPO / "transform" / "seeds" / "suelos_lucas_2018.csv"

# NUTS 2 (versión 2016, la de LUCAS 2018) de España -> código INE de la comunidad
NUTS2_CCAA = {
    "ES11": "12", "ES12": "03", "ES13": "06", "ES21": "16", "ES22": "15", "ES23": "17", "ES24": "02",
    "ES30": "13", "ES41": "07", "ES42": "08", "ES43": "11", "ES51": "09", "ES52": "10", "ES53": "04",
    "ES61": "01", "ES62": "14", "ES63": "18", "ES64": "19", "ES70": "05",
}
# Usos del suelo de LUCAS (LC0_Desc) que entran en cada grupo
USOS = {"Cultivos": ("Cropland",), "Prados": ("Grassland",), "Agraria": ("Cropland", "Grassland")}
MO = 1.724 / 10  # materia orgánica (%) = carbono orgánico (g/kg) × 1,724 / 10
MINIMO = 10  # muestras mínimas para publicar un territorio y uso


def main(ruta: str):
    c = duckdb.connect()
    c.sql(f"CREATE TABLE l AS SELECT * FROM read_csv('{Path(ruta).as_posix()}', all_varchar = true)")
    # Erosión: el fichero solo trae los puntos con señales (a menos de 500 m); cárcavas = GULLY en
    # el punto o en alguna dirección. Según el informe del JRC solo las cárcavas se pudieron validar
    erosion = Path(ruta).with_name("LUCAS2018_EROSION.csv").as_posix()
    c.sql(f"""
        CREATE TABLE e AS SELECT POINT_ID AS pointid,
            coalesce('1' IN (SURVEY_EROSION_GULLY_P, SURVEY_EROSION_GULLY_N, SURVEY_EROSION_GULLY_E,
                             SURVEY_EROSION_GULLY_S, SURVEY_EROSION_GULLY_W), false) AS carcava
        FROM read_csv('{erosion}', all_varchar = true)
        WHERE SURVEY_EROSION_SIGNS = '1'
    """)
    # Valores por debajo del límite de detección («< LOD») cuentan como 0 en las medianas
    num = lambda col: f"coalesce(try_cast(\"{col}\" AS DOUBLE), CASE WHEN \"{col}\" LIKE '<%' THEN 0 END)"
    c.sql(f"""
        CREATE TABLE m AS SELECT
            NUTS_0 AS pais, NUTS_2 AS nuts2, LC0_Desc AS uso,
            {num('OC')} AS oc, {num('pH_H2O')} AS ph, {num('CaCO3')} AS caco3,
            {num('N')} AS n, {num('P')} AS p, {num('K')} AS k,
            e.pointid IS NOT NULL AS erosion, coalesce(e.carcava, false) AS carcava
        FROM l LEFT JOIN e ON e.pointid = l.POINTID
    """)
    mapa = ", ".join(f"('{k}', '{v}')" for k, v in NUTS2_CCAA.items())
    c.sql(f"CREATE TABLE ccaa (nuts2 VARCHAR, cod VARCHAR); INSERT INTO ccaa VALUES {mapa}")
    partes = []
    for uso, lc in USOS.items():
        en = ", ".join(f"'{x}'" for x in lc)
        cuerpo = f"""
            '{uso}' AS uso, count(*) AS muestras,
            round(median(oc), 1) AS carbono_g_kg, round(median(oc) * {MO}, 2) AS materia_organica_pct,
            round(avg(oc), 1) AS carbono_medio_g_kg,
            round(100.0 * avg(CASE WHEN oc * {MO} < 1 THEN 1 ELSE 0 END), 1) AS pct_mo_menos_1,
            round(100.0 * avg(CASE WHEN oc * {MO} < 2 THEN 1 ELSE 0 END), 1) AS pct_mo_menos_2,
            round(median(ph), 2) AS ph,
            round(100.0 * avg(CASE WHEN ph >= 7.5 THEN 1 ELSE 0 END), 1) AS pct_basico,
            round(100.0 * avg(CASE WHEN ph < 6.5 THEN 1 ELSE 0 END), 1) AS pct_acido,
            round(median(caco3), 0) AS carbonatos_g_kg,
            round(100.0 * avg(CASE WHEN caco3 >= 50 THEN 1 ELSE 0 END), 1) AS pct_calizo,
            round(median(n), 2) AS nitrogeno_g_kg, round(median(p), 1) AS fosforo_mg_kg, round(median(k), 0) AS potasio_mg_kg,
            round(100.0 * avg(CASE WHEN erosion THEN 1 ELSE 0 END), 1) AS pct_erosion_visible,
            round(100.0 * avg(CASE WHEN carcava THEN 1 ELSE 0 END), 1) AS pct_carcavas
        """
        partes.append(f"""
            SELECT 'pais' AS nivel, pais AS cod, {cuerpo}
            FROM m WHERE uso IN ({en}) AND oc IS NOT NULL GROUP BY pais HAVING count(*) >= {MINIMO}
            UNION ALL
            SELECT 'ccaa', ccaa.cod, {cuerpo}
            FROM m JOIN ccaa USING (nuts2) WHERE uso IN ({en}) AND oc IS NOT NULL GROUP BY ccaa.cod HAVING count(*) >= {MINIMO}
            UNION ALL
            SELECT 'nuts2', nuts2, {cuerpo}
            FROM m WHERE uso IN ({en}) AND oc IS NOT NULL AND nuts2 IS NOT NULL GROUP BY nuts2 HAVING count(*) >= {MINIMO}
        """)
    sql = " UNION ALL ".join(partes) + " ORDER BY nivel, cod, uso"
    c.sql(f"COPY ({sql}) TO '{SALIDA.as_posix()}' (HEADER, DELIMITER ',')")
    print(c.sql(f"SELECT nivel, uso, count(*) FROM read_csv('{SALIDA.as_posix()}') GROUP BY ALL ORDER BY ALL").fetchall())


if __name__ == "__main__":
    main(sys.argv[1])
