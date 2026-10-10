---
title: Construcción
description: "La construcción en España frente a la UE: peso en el valor añadido y en el empleo desde 1995, la burbuja de 2007 y el desplome, licitación de obra pública en euros reales por habitante y partido del Gobierno, viviendas visadas, cemento, producción, costes, empresas y comunidades."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql peso
SELECT
    CAST(anio AS INTEGER) AS anio,
    pais,
    CASE pais WHEN 'ES' THEN 'España' WHEN 'EU27_2020' THEN 'UE-27' ELSE pais_nombre END AS serie,
    pct_vab_construccion,
    pct_empleo_construccion,
    ocupados_constr_1000hab,
    vab_constr_real_indice_2007,
    CAST(puesto_vab AS INTEGER) AS puesto_vab,
    CAST(puesto_empleo AS INTEGER) AS puesto_empleo,
    CAST(n_paises AS INTEGER) AS n_paises,
    vab_constr_hab_eur_real,
    ocupados_constr_miles
FROM mother.construccion_peso_ue
WHERE pais IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT', 'IE')
ORDER BY pais, anio
```

```sql peso_es
SELECT * FROM ${peso} WHERE pais = 'ES' ORDER BY anio
```

```sql peso_es_ue
SELECT * FROM ${peso} WHERE pais IN ('ES', 'EU27_2020') ORDER BY pais, anio
```

```sql peso_res
SELECT
    CAST(max(anio) FILTER (WHERE pais = 'ES' AND pct_vab_construccion IS NOT NULL) AS INTEGER) AS anio,
    arg_max(pct_vab_construccion, anio) FILTER (WHERE pais = 'ES') AS es_vab,
    arg_max(pct_vab_construccion, anio) FILTER (WHERE pais = 'EU27_2020') AS ue_vab,
    arg_max(pct_empleo_construccion, anio) FILTER (WHERE pais = 'ES') AS es_emp,
    arg_max(pct_empleo_construccion, anio) FILTER (WHERE pais = 'EU27_2020') AS ue_emp,
    arg_max(puesto_vab, anio) FILTER (WHERE pais = 'ES') AS puesto,
    arg_max(n_paises, anio) FILTER (WHERE pais = 'ES') AS n_paises,
    max(pct_vab_construccion) FILTER (WHERE pais = 'ES' AND anio = 1995) AS es_vab_1995,
    max(pct_vab_construccion) FILTER (WHERE pais = 'EU27_2020' AND anio = 1995) AS ue_vab_1995,
    max(pct_vab_construccion) FILTER (WHERE pais = 'ES' AND anio = 2007) AS es_vab_2007,
    max(pct_vab_construccion) FILTER (WHERE pais = 'EU27_2020' AND anio = 2007) AS ue_vab_2007,
    max(pct_empleo_construccion) FILTER (WHERE pais = 'ES' AND anio = 2007) AS es_emp_2007,
    max(pct_empleo_construccion) FILTER (WHERE pais = 'EU27_2020' AND anio = 2007) AS ue_emp_2007,
    max(puesto_vab) FILTER (WHERE pais = 'ES' AND anio = 2007) AS puesto_2007,
    max(pct_vab_construccion) FILTER (WHERE pais = 'ES') AS es_vab_max,
    CAST(arg_max(anio, pct_vab_construccion) FILTER (WHERE pais = 'ES') AS INTEGER) AS anio_vab_max,
    max(pct_vab_construccion) FILTER (WHERE pais = 'EU27_2020' AND anio = (SELECT arg_max(anio, pct_vab_construccion) FROM ${peso} WHERE pais = 'ES')) AS ue_vab_anio_max,
    min(pct_vab_construccion) FILTER (WHERE pais = 'ES' AND anio > 2007) AS es_vab_min,
    CAST(arg_min(anio, pct_vab_construccion) FILTER (WHERE pais = 'ES' AND anio > 2007) AS INTEGER) AS anio_vab_min,
    min(vab_constr_real_indice_2007) FILTER (WHERE pais = 'ES') AS es_vol_min,
    CAST(arg_min(anio, vab_constr_real_indice_2007) FILTER (WHERE pais = 'ES') AS INTEGER) AS anio_vol_min,
    arg_max(vab_constr_real_indice_2007, anio) FILTER (WHERE pais = 'ES') AS es_vol,
    arg_max(vab_constr_real_indice_2007, anio) FILTER (WHERE pais = 'EU27_2020') AS ue_vol,
    max(vab_constr_real_indice_2007) FILTER (WHERE pais = 'ES' AND anio = 1995) AS es_vol_1995,
    max(ocupados_constr_miles) FILTER (WHERE pais = 'ES' AND anio = 2007) / 1000 AS ocup_2007_mill,
    max(ocupados_constr_1000hab) FILTER (WHERE pais = 'ES' AND anio = 2007) AS es_ocup_1000_2007,
    max(ocupados_constr_1000hab) FILTER (WHERE pais = 'EU27_2020' AND anio = 2007) AS ue_ocup_1000_2007,
    arg_max(ocupados_constr_1000hab, anio) FILTER (WHERE pais = 'ES') AS es_ocup_1000,
    arg_max(ocupados_constr_1000hab, anio) FILTER (WHERE pais = 'EU27_2020') AS ue_ocup_1000,
    max(vab_constr_hab_eur_real) FILTER (WHERE pais = 'ES' AND anio = 2007) AS es_vabhab_2007,
    arg_max(vab_constr_hab_eur_real, anio) FILTER (WHERE pais = 'ES') AS es_vabhab
FROM ${peso}
```

```sql epa
SELECT
    fecha,
    periodo,
    CAST(anio AS INTEGER) AS anio,
    CAST(trimestre AS INTEGER) AS trimestre,
    CAST(CAST(trimestre AS INTEGER) AS VARCHAR) || '.º trimestre de ' || CAST(CAST(anio AS INTEGER) AS VARCHAR) AS etiqueta,
    ocupados_constr_miles,
    ocupados_constr_1000hab,
    pct_ocupados_constr,
    parados_constr_miles,
    tasa_paro_constr
FROM mother.construccion_empleo
WHERE cod = '00' AND ocupados_constr_miles IS NOT NULL
ORDER BY fecha
```

```sql epa_res
SELECT
    arg_max(etiqueta, fecha) AS etiqueta,
    arg_max(ocupados_constr_miles, fecha) / 1000 AS ocup_mill,
    arg_max(ocupados_constr_1000hab, fecha) AS ocup_1000,
    arg_max(pct_ocupados_constr, fecha) AS pct,
    arg_max(tasa_paro_constr, fecha) AS paro,
    max(ocupados_constr_1000hab) FILTER (WHERE anio = (SELECT max(anio) FROM ${epa}) - 1
        AND trimestre = (SELECT arg_max(trimestre, fecha) FROM ${epa})) AS ocup_1000_hace_un_anio,
    max(ocupados_constr_miles) FILTER (WHERE anio = 2008 AND trimestre = 1) / 1000 AS ocup_2008_mill,
    max(ocupados_constr_1000hab) FILTER (WHERE anio = 2008 AND trimestre = 1) AS ocup_1000_2008,
    max(tasa_paro_constr) FILTER (WHERE anio = 2008 AND trimestre = 1) AS paro_2008,
    min(ocupados_constr_1000hab) AS ocup_1000_min,
    arg_min(etiqueta, ocupados_constr_1000hab) AS etiqueta_min,
    max(tasa_paro_constr) AS paro_max,
    arg_max(etiqueta, tasa_paro_constr) AS etiqueta_paro_max
FROM ${epa}
```

```sql afil
SELECT
    fecha,
    CAST(anio AS INTEGER) AS anio,
    CAST(mes AS INTEGER) AS mes,
    afiliados_constr,
    afiliados_constr_1000hab,
    pct_constr,
    pct_autonomos_constr,
    cnae
FROM mother.construccion_afiliados
WHERE nivel = 'pais'
ORDER BY fecha
```

```sql afil_res
SELECT
    (['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'])[arg_max(mes, fecha)]
        || ' de ' || CAST(arg_max(anio, fecha) AS VARCHAR) AS mes_ultimo,
    arg_max(afiliados_constr, fecha) / 1e6 AS afil_mill,
    arg_max(afiliados_constr_1000hab, fecha) AS afil_1000,
    arg_max(pct_constr, fecha) AS pct,
    arg_max(pct_autonomos_constr, fecha) AS pct_aut,
    max(pct_autonomos_constr) FILTER (WHERE anio = 2021 AND mes = 1) AS pct_aut_2021,
    max(afiliados_constr_1000hab) FILTER (WHERE anio = 2021 AND mes = 1) AS afil_1000_2021,
    100 * (arg_max(afiliados_constr, fecha) / max(afiliados_constr) FILTER (WHERE anio = (SELECT max(anio) FROM ${afil}) - 1
        AND mes = (SELECT arg_max(mes, fecha) FROM ${afil})) - 1) AS var_anual
FROM ${afil}
```

```sql lic
SELECT
    CAST(anio AS INTEGER) AS anio,
    total_hab_real,
    estado_hab_real,
    entes_territoriales_hab_real,
    epe_hab_real,
    age_hab_real,
    edificacion_hab_real,
    obra_civil_hab_real,
    pct_estado,
    pct_obra_civil,
    total_real_meur,
    presidente_estatal,
    familia_estatal,
    coalesce(provisional, false) AS provisional,
    CAST(anio_base AS INTEGER) AS anio_base
FROM mother.construccion_licitacion
WHERE cod = '00' AND total_hab_real IS NOT NULL
ORDER BY anio
```

```sql lic_agentes
SELECT anio, 'Estado (con Adif, Aena, Puertos...)' AS agente, estado_hab_real AS eur_hab FROM ${lic}
UNION ALL
SELECT anio, 'Comunidades y ayuntamientos' AS agente, entes_territoriales_hab_real AS eur_hab FROM ${lic}
ORDER BY anio, agente
```

```sql lic_res
SELECT
    CAST(max(anio) AS INTEGER) AS anio,
    CAST(min(anio) AS INTEGER) AS anio_ini,
    CAST(max(anio_base) AS INTEGER) AS anio_base,
    arg_max(total_hab_real, anio) AS total,
    arg_max(estado_hab_real, anio) AS estado,
    arg_max(entes_territoriales_hab_real, anio) AS entes,
    arg_max(epe_hab_real, anio) AS epe,
    arg_max(pct_estado, anio) AS pct_estado,
    arg_max(pct_obra_civil, anio) AS pct_obra_civil,
    arg_max(total_real_meur, anio) / 1000 AS total_mm,
    bool_or(provisional) AS hay_provisional,
    CASE WHEN arg_max(provisional, anio) THEN 'dato provisional' ELSE 'dato definitivo' END AS estado_dato,
    CAST(min(anio) FILTER (WHERE provisional) AS INTEGER) AS anio_prov,
    max(total_hab_real) AS total_max,
    CAST(arg_max(anio, total_hab_real) AS INTEGER) AS anio_max,
    min(total_hab_real) AS total_min,
    CAST(arg_min(anio, total_hab_real) AS INTEGER) AS anio_min,
    max(total_hab_real) FILTER (WHERE anio = 2007) AS total_2007,
    max(estado_hab_real) AS estado_max,
    CAST(arg_max(anio, estado_hab_real) AS INTEGER) AS anio_estado_max,
    min(estado_hab_real) AS estado_min,
    CAST(arg_min(anio, estado_hab_real) AS INTEGER) AS anio_estado_min,
    100 * (arg_max(total_hab_real, anio) / max(total_hab_real) FILTER (WHERE anio = 2007) - 1) AS var_2007,
    100 * (arg_max(total_hab_real, anio) / max(total_hab_real) FILTER (WHERE anio = (SELECT max(anio) FROM ${lic}) - 1) - 1) AS var_anual
FROM ${lic}
```

```sql lic_presidentes
SELECT
    presidente_estatal AS presidente,
    familia_estatal AS partido,
    CAST(min(anio) AS VARCHAR) || '-' || CAST(max(anio) AS VARCHAR) AS anios,
    CAST(count(*) AS INTEGER) AS n_anios,
    avg(estado_hab_real) AS estado_media,
    avg(entes_territoriales_hab_real) AS entes_media,
    avg(total_hab_real) AS total_media,
    min(anio) AS orden
FROM ${lic}
GROUP BY presidente_estatal, familia_estatal
ORDER BY orden
```

```sql lic_partidos
SELECT
    familia_estatal AS partido,
    CAST(count(*) AS INTEGER) AS n_anios,
    avg(estado_hab_real) AS estado_media,
    avg(total_hab_real) AS total_media
FROM ${lic}
GROUP BY familia_estatal
ORDER BY familia_estatal
```

```sql lic_ccaa
SELECT
    l.cod AS cod_ccaa,
    l.nombre AS comunidad,
    t.ruta,
    CAST(l.anio AS INTEGER) AS anio,
    l.total_hab_real,
    l.estado_hab_real,
    l.entes_territoriales_hab_real,
    m.media_5,
    l.familia_autonomica,
    l.presidente_autonomico
FROM mother.construccion_licitacion l
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = l.cod
LEFT JOIN (
    SELECT cod, avg(total_hab_real) AS media_5
    FROM mother.construccion_licitacion
    WHERE anio > (SELECT max(anio) FROM mother.construccion_licitacion) - 5
    GROUP BY cod
) m ON m.cod = l.cod
WHERE l.cod NOT IN ('00', 'NR')
  AND l.anio = (SELECT max(anio) FROM mother.construccion_licitacion)
ORDER BY l.total_hab_real DESC
```

```sql lic_ccaa_res
SELECT
    string_agg(comunidad || ' (' || CAST(CAST(round(total_hab_real, 0) AS INTEGER) AS VARCHAR) || ' €)', ', ' ORDER BY total_hab_real DESC) FILTER (WHERE rk <= 3) AS mas,
    string_agg(comunidad || ' (' || CAST(CAST(round(total_hab_real, 0) AS INTEGER) AS VARCHAR) || ' €)', ', ' ORDER BY total_hab_real) FILTER (WHERE rk_inv <= 3) AS menos,
    (SELECT 100 * max(total_meur) FILTER (WHERE cod = 'NR') / max(total_meur) FILTER (WHERE cod = '00')
     FROM mother.construccion_licitacion WHERE anio = (SELECT max(anio) FROM mother.construccion_licitacion)) AS pct_nr
FROM (
    SELECT *, row_number() OVER (ORDER BY total_hab_real DESC) AS rk, row_number() OVER (ORDER BY total_hab_real) AS rk_inv
    FROM ${lic_ccaa}
    WHERE cod_ccaa NOT IN ('18', '19')
)
```

```sql visados
SELECT CAST(anio AS INTEGER) AS anio, viviendas_nueva, viviendas_nueva_1000hab, m2_obra_nueva_hab
FROM mother.construccion_permisos
WHERE nivel = 'pais' AND viviendas_nueva_1000hab IS NOT NULL
ORDER BY anio
```

```sql visados_res
SELECT
    CAST(max(anio) AS INTEGER) AS anio,
    CAST(min(anio) AS INTEGER) AS anio_ini,
    arg_max(viviendas_nueva_1000hab, anio) AS ult,
    arg_max(viviendas_nueva, anio) / 1000 AS ult_miles,
    max(viviendas_nueva_1000hab) AS max_1000,
    CAST(arg_max(anio, viviendas_nueva_1000hab) AS INTEGER) AS anio_max,
    max(viviendas_nueva) / 1000 AS max_miles,
    min(viviendas_nueva_1000hab) AS min_1000,
    CAST(arg_min(anio, viviendas_nueva_1000hab) AS INTEGER) AS anio_min,
    max(viviendas_nueva_1000hab) FILTER (WHERE anio = 2019) AS v2019,
    arg_max(m2_obra_nueva_hab, anio) AS m2_ult,
    max(m2_obra_nueva_hab) AS m2_max,
    100 * (arg_max(viviendas_nueva_1000hab, anio) / max(viviendas_nueva_1000hab) FILTER (WHERE anio = (SELECT max(anio) FROM ${visados}) - 1) - 1) AS var_anual
FROM ${visados}
```

```sql visados_ccaa
SELECT
    p.cod AS cod_ccaa,
    p.nombre AS comunidad,
    t.ruta,
    CAST(p.anio AS INTEGER) AS anio,
    p.viviendas_nueva_1000hab,
    p.viviendas_reforma_1000hab,
    p.viviendas_nueva,
    m.media_2004_2007
FROM mother.construccion_permisos p
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = p.cod
LEFT JOIN (
    SELECT cod, avg(viviendas_nueva_1000hab) AS media_2004_2007
    FROM mother.construccion_permisos
    WHERE nivel = 'ccaa' AND anio BETWEEN 2004 AND 2007
    GROUP BY cod
) m ON m.cod = p.cod
WHERE p.nivel = 'ccaa'
  AND p.anio = (SELECT max(anio) FROM mother.construccion_permisos WHERE nivel = 'ccaa')
ORDER BY p.viviendas_nueva_1000hab DESC
```

```sql visados_ccaa_res
SELECT
    string_agg(comunidad, ', ' ORDER BY viviendas_nueva_1000hab DESC) FILTER (WHERE rk <= 3) AS mas,
    string_agg(comunidad, ', ' ORDER BY viviendas_nueva_1000hab) FILTER (WHERE rk_inv <= 3) AS menos,
    max(viviendas_nueva_1000hab) AS max_1000,
    min(viviendas_nueva_1000hab) AS min_1000
FROM (
    SELECT *, row_number() OVER (ORDER BY viviendas_nueva_1000hab DESC) AS rk,
              row_number() OVER (ORDER BY viviendas_nueva_1000hab) AS rk_inv
    FROM ${visados_ccaa}
)
```

```sql permisos_ue
SELECT
    CAST(anio AS INTEGER) AS anio,
    cod_pais,
    CASE cod_pais WHEN 'ES' THEN 'España' WHEN 'EU27_2020' THEN 'UE-27' ELSE pais END AS serie,
    viviendas_nueva_1000hab
FROM mother.construccion_permisos_ue
WHERE cod_pais IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT', 'IE')
  AND viviendas_nueva_1000hab IS NOT NULL
ORDER BY cod_pais, anio
```

```sql permisos_res
WITH u AS (
    SELECT * FROM mother.construccion_permisos_ue
    WHERE viviendas_nueva_1000hab IS NOT NULL
      AND anio = (SELECT max(anio) FROM mother.construccion_permisos_ue WHERE cod_pais = 'ES' AND viviendas_nueva_1000hab IS NOT NULL)
),
r AS (
    SELECT cod_pais, viviendas_nueva_1000hab, row_number() OVER (ORDER BY viviendas_nueva_1000hab DESC) AS rk
    FROM u WHERE cod_pais <> 'EU27_2020'
)
SELECT
    CAST(max(u.anio) AS INTEGER) AS anio,
    max(u.viviendas_nueva_1000hab) FILTER (WHERE u.cod_pais = 'ES') AS es,
    max(u.viviendas_nueva_1000hab) FILTER (WHERE u.cod_pais = 'EU27_2020') AS ue,
    max(u.viviendas_nueva) FILTER (WHERE u.cod_pais = 'ES') / 1000 AS es_miles,
    (SELECT CAST(rk AS INTEGER) FROM r WHERE cod_pais = 'ES') AS puesto,
    (SELECT CAST(count(*) AS INTEGER) FROM r) AS n,
    (SELECT max(viviendas_nueva) / 1000 FROM mother.construccion_permisos
     WHERE nivel = 'pais' AND anio = (SELECT max(anio) FROM u)) AS visados_miles
FROM u
```

```sql cemento
SELECT CAST(anio AS INTEGER) AS anio, consumo_kg_hab, produccion_kg_hab, pct_produccion_exportada
FROM mother.construccion_cemento
WHERE consumo_kg_hab IS NOT NULL
ORDER BY anio
```

```sql cemento_largo
SELECT anio, 'Consumo aparente' AS serie, consumo_kg_hab AS kg_hab FROM ${cemento}
UNION ALL
SELECT anio, 'Producción' AS serie, produccion_kg_hab AS kg_hab FROM ${cemento}
ORDER BY anio, serie
```

```sql cemento_res
SELECT
    CAST(max(anio) AS INTEGER) AS anio,
    CAST(min(anio) AS INTEGER) AS anio_ini,
    arg_max(consumo_kg_hab, anio) AS ult,
    max(consumo_kg_hab) AS max_kg,
    CAST(arg_max(anio, consumo_kg_hab) AS INTEGER) AS anio_max,
    min(consumo_kg_hab) AS min_kg,
    CAST(arg_min(anio, consumo_kg_hab) AS INTEGER) AS anio_min,
    max(consumo_kg_hab) FILTER (WHERE anio = 1995) AS kg_1995,
    arg_max(pct_produccion_exportada, anio) AS pct_export
FROM ${cemento}
```

```sql prod
SELECT CAST(anio AS INTEGER) AS anio, rama, rama_nombre, indice_2021, indice_2007, var_anual_pct, nota
FROM mother.construccion_produccion
WHERE cod_pais = 'ES' AND anio >= 2000
ORDER BY rama, anio
```

```sql prod_es_ue
SELECT CAST(anio AS INTEGER) AS anio,
       CASE cod_pais WHEN 'ES' THEN 'España' WHEN 'EU27_2020' THEN 'UE-27' ELSE pais END AS serie,
       indice_2007
FROM mother.construccion_produccion
WHERE rama = 'F' AND cod_pais IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT') AND anio >= 2000
ORDER BY cod_pais, anio
```

```sql prod_res
SELECT
    CAST(max(anio) AS INTEGER) AS anio,
    max(indice_2007) FILTER (WHERE rama = 'F' AND anio = 2024) AS f_2024,
    max(indice_2007) FILTER (WHERE rama = 'F' AND anio = (SELECT max(anio) FROM ${prod})) AS f_ult,
    max(var_anual_pct) FILTER (WHERE rama = 'F' AND anio = (SELECT max(anio) FROM ${prod})) AS f_var,
    max(var_anual_pct) FILTER (WHERE rama = 'F43' AND anio = (SELECT max(anio) FROM ${prod})) AS f43_var,
    max(var_anual_pct) FILTER (WHERE rama = 'F41' AND anio = (SELECT max(anio) FROM ${prod})) AS f41_var,
    max(var_anual_pct) FILTER (WHERE rama = 'F42' AND anio = (SELECT max(anio) FROM ${prod})) AS f42_var,
    max(indice_2007) FILTER (WHERE rama = 'F41' AND anio = (SELECT max(anio) FROM ${prod})) AS f41_ult,
    max(indice_2007) FILTER (WHERE rama = 'F42' AND anio = (SELECT max(anio) FROM ${prod})) AS f42_ult,
    min(indice_2007) FILTER (WHERE rama = 'F') AS f_min,
    CAST(arg_min(anio, indice_2007) FILTER (WHERE rama = 'F') AS INTEGER) AS anio_f_min,
    bool_or(nota IS NOT NULL) AS hay_salto,
    (SELECT max(indice_2007) FROM mother.construccion_produccion
     WHERE cod_pais = 'EU27_2020' AND rama = 'F' AND anio = 2024) AS ue_2024
FROM ${prod}
```

```sql costes
SELECT CAST(anio AS INTEGER) AS anio, 'Coste nominal' AS serie, coste_indice_2021 AS indice
FROM mother.construccion_costes WHERE cod_pais = 'ES' AND coste_indice_2021 IS NOT NULL
UNION ALL
SELECT CAST(anio AS INTEGER) AS anio, 'Coste descontada la inflación' AS serie, coste_real_indice_2021 AS indice
FROM mother.construccion_costes WHERE cod_pais = 'ES' AND coste_real_indice_2021 IS NOT NULL
UNION ALL
SELECT CAST(anio AS INTEGER) AS anio, 'UE-27, precio de producción nominal' AS serie, precio_produccion_indice_2021 AS indice
FROM mother.construccion_costes WHERE cod_pais = 'EU27_2020' AND precio_produccion_indice_2021 IS NOT NULL
ORDER BY serie, anio
```

```sql costes_res
SELECT
    CAST(max(anio) FILTER (WHERE cod_pais = 'ES') AS INTEGER) AS anio,
    arg_max(coste_indice_2021, anio) FILTER (WHERE cod_pais = 'ES') AS es_nom,
    arg_max(coste_real_indice_2021, anio) FILTER (WHERE cod_pais = 'ES') AS es_real,
    max(coste_real_indice_2021) FILTER (WHERE cod_pais = 'ES' AND anio = 2007) AS es_real_2007,
    max(coste_real_indice_2021) FILTER (WHERE cod_pais = 'ES') AS es_real_max,
    CAST(arg_max(anio, coste_real_indice_2021) FILTER (WHERE cod_pais = 'ES') AS INTEGER) AS anio_real_max,
    max(coste_indice_2021) FILTER (WHERE cod_pais = 'ES' AND anio = 2020) AS es_nom_2020,
    arg_max(precio_produccion_indice_2021, anio) FILTER (WHERE cod_pais = 'EU27_2020') AS ue_precio,
    CAST(max(anio) FILTER (WHERE cod_pais = 'EU27_2020' AND precio_produccion_indice_2021 IS NOT NULL) AS INTEGER) AS anio_ue
FROM mother.construccion_costes
WHERE cod_pais IN ('ES', 'EU27_2020')
```

```sql empresas
SELECT
    CAST(anio AS INTEGER) AS anio,
    pais,
    CASE pais WHEN 'ES' THEN 'España' WHEN 'EU27_2020' THEN 'UE-27' ELSE pais_nombre END AS serie,
    CASE pais WHEN 'ES' THEN 'España' WHEN 'EU27_2020' THEN 'UE-27' ELSE 'Otros países' END AS grupo,
    rama,
    rama_nombre,
    empresas_1000hab,
    ocupados_por_empresa,
    productividad_miles_eur,
    CAST(puesto_empresas_1000hab AS INTEGER) AS puesto_empresas
FROM mother.construccion_empresas_ue
WHERE anio = (SELECT max(anio) FROM mother.construccion_empresas_ue WHERE pais = 'ES' AND productividad_miles_eur IS NOT NULL)
```

```sql empresas_productividad
SELECT serie, grupo, productividad_miles_eur
FROM ${empresas}
WHERE rama = 'F' AND productividad_miles_eur IS NOT NULL
ORDER BY productividad_miles_eur DESC
```

```sql empresas_ramas
SELECT
    e.rama_nombre AS rama,
    e.empresas_1000hab AS es_empresas,
    u.empresas_1000hab AS ue_empresas,
    e.ocupados_por_empresa AS es_tamano,
    u.ocupados_por_empresa AS ue_tamano,
    e.productividad_miles_eur AS es_productividad,
    u.productividad_miles_eur AS ue_productividad,
    e.puesto_empresas
FROM ${empresas} e
LEFT JOIN ${empresas} u ON u.pais = 'EU27_2020' AND u.rama = e.rama
WHERE e.pais = 'ES'
ORDER BY e.rama
```

```sql empresas_res
SELECT
    max(anio) AS anio,
    max(empresas_1000hab) FILTER (WHERE pais = 'ES' AND rama = 'F') AS es_emp,
    max(empresas_1000hab) FILTER (WHERE pais = 'EU27_2020' AND rama = 'F') AS ue_emp,
    max(puesto_empresas) FILTER (WHERE pais = 'ES' AND rama = 'F') AS puesto,
    CAST(count(*) FILTER (WHERE rama = 'F' AND puesto_empresas IS NOT NULL) AS INTEGER) AS n,
    max(ocupados_por_empresa) FILTER (WHERE pais = 'ES' AND rama = 'F') AS es_tam,
    max(ocupados_por_empresa) FILTER (WHERE pais = 'EU27_2020' AND rama = 'F') AS ue_tam,
    max(productividad_miles_eur) FILTER (WHERE pais = 'ES' AND rama = 'F') AS es_prod,
    max(productividad_miles_eur) FILTER (WHERE pais = 'EU27_2020' AND rama = 'F') AS ue_prod,
    100 * max(productividad_miles_eur) FILTER (WHERE pais = 'ES' AND rama = 'F')
        / max(productividad_miles_eur) FILTER (WHERE pais = 'EU27_2020' AND rama = 'F') AS pct_prod_ue,
    max(productividad_miles_eur) FILTER (WHERE pais = 'DE' AND rama = 'F') AS de_prod,
    max(productividad_miles_eur) FILTER (WHERE pais = 'FR' AND rama = 'F') AS fr_prod,
    max(productividad_miles_eur) FILTER (WHERE pais = 'IT' AND rama = 'F') AS it_prod
FROM ${empresas}
```

```sql constructoras
SELECT CAST(anio AS INTEGER) AS edicion, CAST(puesto AS INTEGER) AS puesto, empresa,
       ingresos_mill_usd, pct_ventas_exterior
FROM mother.construccion_grandes_constructoras
WHERE anio = (SELECT max(anio) FROM mother.construccion_grandes_constructoras)
ORDER BY puesto
```

```sql constructoras_res
SELECT
    CAST(max(edicion) AS INTEGER) AS edicion,
    CAST(count(*) AS INTEGER) AS n,
    CAST(count(*) FILTER (WHERE puesto <= 50) AS INTEGER) AS n_top50,
    arg_min(empresa, puesto) AS primera,
    CAST(min(puesto) AS INTEGER) AS puesto_primera,
    arg_min(pct_ventas_exterior, puesto) AS pct_exterior_primera
FROM ${constructoras}
```

```sql ccaa
SELECT
    c.cod AS cod_ccaa,
    c.nombre AS comunidad,
    t.ruta,
    CAST(c.anio AS INTEGER) AS anio,
    c.pct_vab_construccion,
    c.pct_vab_2007,
    c.dif_pp_vs_2007,
    c.vab_constr_hab_real,
    CAST(c.puesto AS INTEGER) AS puesto,
    c.ocupados_constr_1000hab_epa
FROM mother.construccion_ccaa c
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = c.cod
WHERE c.cod <> '00'
  AND c.anio = (SELECT max(anio) FROM mother.construccion_ccaa WHERE cod <> '00')
ORDER BY c.pct_vab_construccion DESC
```

```sql ccaa_res
SELECT
    CAST(max(c.anio) AS INTEGER) AS anio,
    string_agg(c.comunidad || ' (' || replace(CAST(round(c.pct_vab_construccion, 1) AS VARCHAR), '.', ',') || ' %)', ', ' ORDER BY c.pct_vab_construccion DESC) FILTER (WHERE c.rk <= 3) AS mas,
    string_agg(c.comunidad, ', ' ORDER BY c.pct_vab_construccion) FILTER (WHERE c.rk_inv <= 3) AS menos,
    arg_min(c.comunidad, c.dif_pp_vs_2007) AS mas_caida,
    min(c.dif_pp_vs_2007) AS caida_max,
    arg_min(c.pct_vab_2007, c.dif_pp_vs_2007) AS mas_caida_2007,
    arg_min(c.pct_vab_construccion, c.dif_pp_vs_2007) AS mas_caida_ult,
    CAST(count(*) FILTER (WHERE c.dif_pp_vs_2007 < 0) AS INTEGER) AS n_debajo,
    CAST(count(*) AS INTEGER) AS n,
    (SELECT pct_vab_construccion FROM mother.construccion_ccaa WHERE cod = '00' AND anio = (SELECT max(anio) FROM ${ccaa})) AS es,
    (SELECT pct_vab_2007 FROM mother.construccion_ccaa WHERE cod = '00' AND anio = (SELECT max(anio) FROM ${ccaa})) AS es_2007,
    (SELECT vab_constr_hab_real FROM mother.construccion_ccaa WHERE cod = '00' AND anio = (SELECT max(anio) FROM ${ccaa})) AS es_hab
FROM (
    SELECT *, row_number() OVER (ORDER BY pct_vab_construccion DESC) AS rk,
              row_number() OVER (ORDER BY pct_vab_construccion) AS rk_inv
    FROM ${ccaa}
    WHERE cod_ccaa NOT IN ('18', '19')
) c
```

# 🏗️ Construcción

La construcción fue el motor y luego el lastre de la economía española. En {peso_res[0]?.anio_vab_max} llegó a generar el **{formatNumber(peso_res[0]?.es_vab_max, 1)} % del valor añadido** de España, frente al {formatNumber(peso_res[0]?.ue_vab_anio_max, 1)} % de media en la UE, y en 2007 daba trabajo a {formatNumber(peso_res[0]?.ocup_2007_mill, 2)} millones de personas, el {formatNumber(peso_res[0]?.es_emp_2007, 1)} % de los ocupados. Tras el estallido de la burbuja, la actividad real del sector cayó hasta el {formatNumber(peso_res[0]?.es_vol_min, 0)} % de la de 2007 en {peso_res[0]?.anio_vol_min}. En {peso_res[0]?.anio} pesa el {formatNumber(peso_res[0]?.es_vab, 1)} % (UE: {formatNumber(peso_res[0]?.ue_vab, 1)} %) y España ocupa el puesto {peso_res[0]?.puesto} de {peso_res[0]?.n_paises} países de la UE. Las cifras van **por habitante** y, las de euros, **descontada la inflación** (euros de {lic_res[0]?.anio_base}). La vivienda que se empieza y se termina cada año está en [Obra nueva](/vivienda/construccion).

<Grid cols=4>
    <KpiCard
        title="Peso en el valor añadido"
        value={peso_res[0]?.es_vab}
        formattedValue="{formatNumber(peso_res[0]?.es_vab, 1)} %"
        period="{peso_res[0]?.anio} · UE-27: {formatNumber(peso_res[0]?.ue_vab, 1)} % · puesto {peso_res[0]?.puesto} de {peso_res[0]?.n_paises}"
        change={(peso_res[0]?.es_vab - peso_res[0]?.es_vab_2007)?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs 2007"
        direction="neutral"
        source="Eurostat (nama_10_a10)"
        sparklineData={peso_es.map(d => ({...d, y: d.pct_vab_construccion}))}
    />
    <KpiCard
        title="Ocupados por 1.000 habitantes"
        value={epa_res[0]?.ocup_1000}
        formattedValue="{formatNumber(epa_res[0]?.ocup_1000, 1)}"
        period="{epa_res[0]?.etiqueta} · {formatNumber(epa_res[0]?.ocup_mill, 2)} millones · UE-27 ({peso_res[0]?.anio}): {formatNumber(peso_res[0]?.ue_ocup_1000, 1)}"
        change={(epa_res[0]?.ocup_1000 - epa_res[0]?.ocup_1000_hace_un_anio)?.toFixed(1)}
        changeUnit=""
        changePeriod="vs hace un año"
        direction="positive-up"
        source="INE (EPA)"
        sparklineData={epa.map(d => ({...d, y: d.ocupados_constr_1000hab}))}
    />
    <KpiCard
        title="Licitación pública por habitante"
        value={lic_res[0]?.total}
        formattedValue="{formatNumber(lic_res[0]?.total, 0)} €"
        period="{lic_res[0]?.anio}, euros de {lic_res[0]?.anio_base} · {formatNumber(lic_res[0]?.total_mm, 1)} mil millones en total · {lic_res[0]?.estado_dato}"
        change={lic_res[0]?.var_2007?.toFixed(0)}
        changeUnit="%"
        changePeriod="vs 2007"
        direction="neutral"
        source="Mº de Transportes"
        sparklineData={lic.map(d => ({...d, y: d.total_hab_real}))}
    />
    <KpiCard
        title="Viviendas visadas por 1.000 hab."
        value={visados_res[0]?.ult}
        formattedValue="{formatNumber(visados_res[0]?.ult, 2)}"
        period="{visados_res[0]?.anio} · obra nueva · {formatNumber(visados_res[0]?.ult_miles, 0)} mil viviendas · máximo: {formatNumber(visados_res[0]?.max_1000, 1)} en {visados_res[0]?.anio_max}"
        change={visados_res[0]?.var_anual?.toFixed(1)}
        changeUnit="%"
        changePeriod="vs año anterior"
        direction="neutral"
        source="Colegios de aparejadores (BdE)"
        sparklineData={visados.map(d => ({...d, y: d.viviendas_nueva_1000hab}))}
    />
</Grid>

## El auge y la caída

En 1995 la construcción ya pesaba más en España que en la UE ({formatNumber(peso_res[0]?.es_vab_1995, 1)} % del valor añadido frente a {formatNumber(peso_res[0]?.ue_vab_1995, 1)} %). En 2007 {#if peso_res[0]?.puesto_2007 == 1}era el país de los 27 donde más pesaba{:else}era el {peso_res[0]?.puesto_2007}.º de los 27{/if} y concentraba el {formatNumber(peso_res[0]?.es_emp_2007, 1)} % del empleo, frente al {formatNumber(peso_res[0]?.ue_emp_2007, 1)} % europeo. El peso más bajo desde entonces fue el de {peso_res[0]?.anio_vab_min}, el {formatNumber(peso_res[0]?.es_vab_min, 1)} %. En {peso_res[0]?.anio}, con el {formatNumber(peso_res[0]?.es_vab, 1)} % del valor añadido y el {formatNumber(peso_res[0]?.es_emp, 1)} % del empleo (UE: {formatNumber(peso_res[0]?.ue_vab, 1)} % y {formatNumber(peso_res[0]?.ue_emp, 1)} %), España es la {peso_res[0]?.puesto}.ª de {peso_res[0]?.n_paises}.

<LineChart
    data={peso}
    x=anio
    y=pct_vab_construccion
    series=serie
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% del valor añadido bruto"
    title="Peso de la construcción en el valor añadido, % a precios corrientes"
/>

<LineChart
    data={peso_es_ue}
    x=anio
    y=pct_empleo_construccion
    series=serie
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% de los ocupados"
    seriesColors={{'España': '#dc2626', 'UE-27': '#64748b'}}
    title="Peso de la construcción en el empleo, % de los ocupados"
/>

Sin el efecto de los precios (en volumen), el valor añadido de la construcción española era en 1995 el {formatNumber(peso_res[0]?.es_vol_1995, 0)} % del de 2007; tocó fondo en {peso_res[0]?.anio_vol_min} con el {formatNumber(peso_res[0]?.es_vol_min, 0)} % y en {peso_res[0]?.anio} está en el {formatNumber(peso_res[0]?.es_vol, 0)} %. En el conjunto de la UE está en el {formatNumber(peso_res[0]?.ue_vol, 0)} % de 2007. Por habitante, el valor añadido del sector pasó de {formatNumber(peso_res[0]?.es_vabhab_2007, 0)} € en 2007 a {formatNumber(peso_res[0]?.es_vabhab, 0)} € en {peso_res[0]?.anio}, en euros de hoy.

<LineChart
    data={peso}
    x=anio
    y=vab_constr_real_indice_2007
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="2007 = 100"
    title="Valor añadido de la construcción en volumen (sin efecto de los precios), 2007 = 100"
/>

## Empleo

Según la EPA, en el {epa_res[0]?.etiqueta} trabajaban en la construcción **{formatNumber(epa_res[0]?.ocup_mill, 2)} millones de personas**, {formatNumber(epa_res[0]?.ocup_1000, 1)} por cada 1.000 habitantes y el {formatNumber(epa_res[0]?.pct, 1)} % de los ocupados. A comienzos de 2008 eran {formatNumber(epa_res[0]?.ocup_2008_mill, 2)} millones ({formatNumber(epa_res[0]?.ocup_1000_2008, 1)} por 1.000 habitantes); el mínimo de la serie fue {formatNumber(epa_res[0]?.ocup_1000_min, 1)} en el {epa_res[0]?.etiqueta_min}. En 2007, con los datos anuales de Eurostat, España tenía {formatNumber(peso_res[0]?.es_ocup_1000_2007, 1)} ocupados en el sector por 1.000 habitantes frente a {formatNumber(peso_res[0]?.ue_ocup_1000_2007, 1)} en la UE; en {peso_res[0]?.anio}, {formatNumber(peso_res[0]?.es_ocup_1000, 1)} frente a {formatNumber(peso_res[0]?.ue_ocup_1000, 1)}.

<LineChart
    data={epa}
    x=fecha
    y=ocupados_constr_1000hab
    yFmt='0.0'
    yAxisTitle="ocupados por 1.000 habitantes"
    colorPalette={['#b45309']}
    title="Ocupados en la construcción por 1.000 habitantes, por trimestre (EPA)"
/>

La tasa de paro del sector, calculada con los parados que dejaron su empleo en la construcción hace menos de un año, pasó del {formatNumber(epa_res[0]?.paro_2008, 1)} % a comienzos de 2008 a un máximo del {formatNumber(epa_res[0]?.paro_max, 1)} % en el {epa_res[0]?.etiqueta_paro_max}; en el {epa_res[0]?.etiqueta} es del {formatNumber(epa_res[0]?.paro, 1)} %.

<LineChart
    data={epa}
    x=fecha
    y=tasa_paro_constr
    yFmt='0.0"%"'
    yAxisTitle="% de los activos del sector"
    colorPalette={['#dc2626']}
    title="Tasa de paro aproximada de la construcción, por trimestre (EPA)"
/>

En la Seguridad Social, la construcción tenía en {afil_res[0]?.mes_ultimo} **{formatNumber(afil_res[0]?.afil_mill, 2)} millones de afiliados** de media ({formatNumber(afil_res[0]?.afil_1000, 1)} por 1.000 habitantes y el {formatNumber(afil_res[0]?.pct, 1)} % de todos los afiliados), un {#if afil_res[0]?.var_anual >= 0}{formatNumber(afil_res[0]?.var_anual, 1)} % más{:else}{formatNumber(-afil_res[0]?.var_anual, 1)} % menos{/if} que un año antes. El {formatNumber(afil_res[0]?.pct_aut, 1)} % son autónomos, frente al {formatNumber(afil_res[0]?.pct_aut_2021, 1)} % de enero de 2021. Desde enero de 2026 la Seguridad Social clasifica con la nueva CNAE-2025, lo que puede dar pequeños saltos.

<LineChart
    data={afil}
    x=fecha
    y=afiliados_constr_1000hab
    yFmt='0.0'
    yAxisTitle="afiliados por 1.000 habitantes"
    colorPalette={['#b45309']}
    title="Afiliados a la Seguridad Social en la construcción por 1.000 habitantes, media mensual"
/>

<LineChart
    data={afil}
    x=fecha
    y=pct_autonomos_constr
    yFmt='0.0"%"'
    yAxisTitle="% de los afiliados del sector"
    colorPalette={['#7c3aed']}
    title="Autónomos en la construcción, % de los afiliados del sector"
/>

## Obra pública

La licitación oficial es el presupuesto de las obras que sacan a concurso las administraciones (con IVA). En {lic_res[0]?.anio} sumó **{formatNumber(lic_res[0]?.total, 0)} € por habitante** en euros de {lic_res[0]?.anio_base}: {formatNumber(lic_res[0]?.estado, 0)} € del Estado (incluidas sus entidades públicas, como Adif, Aena o Puertos, que aportan {formatNumber(lic_res[0]?.epe, 0)} €) y {formatNumber(lic_res[0]?.entes, 0)} € de los «entes territoriales», que en esta estadística suman comunidades autónomas y ayuntamientos sin separarlos. El {formatNumber(lic_res[0]?.pct_obra_civil, 0)} % fue obra civil y el resto edificación. El máximo desde {lic_res[0]?.anio_ini} fue {formatNumber(lic_res[0]?.total_max, 0)} € en {lic_res[0]?.anio_max} y el mínimo, {formatNumber(lic_res[0]?.total_min, 0)} € en {lic_res[0]?.anio_min}.

{#if lic_res[0]?.hay_provisional}
<p>Los datos desde {lic_res[0]?.anio_prov} son <strong>provisionales</strong>.</p>
{/if}

<BarChart
    data={lic_agentes}
    x=anio
    y=eur_hab
    series=agente
    type=stacked
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ por habitante (euros de hoy)"
    seriesColors={{'Estado (con Adif, Aena, Puertos...)': '#b45309', 'Comunidades y ayuntamientos': '#0d9488'}}
    title="Licitación oficial de obra pública por habitante, euros constantes"
/>

La parte del Estado depende del Gobierno central. Cada barra se colorea con el partido que gobernaba a 1 de julio de ese año; es una descripción, no una explicación: cada periodo coincide con una fase distinta del ciclo económico. Con Gobiernos del PP ({lic_partidos.filter(d => d.partido === 'PP')[0]?.n_anios} años de la serie) la licitación del Estado fue de {formatNumber(lic_partidos.filter(d => d.partido === 'PP')[0]?.estado_media, 0)} € por habitante y año de media, y con Gobiernos del PSOE ({lic_partidos.filter(d => d.partido === 'PSOE')[0]?.n_anios} años), de {formatNumber(lic_partidos.filter(d => d.partido === 'PSOE')[0]?.estado_media, 0)} €. La más alta fue de {formatNumber(lic_res[0]?.estado_max, 0)} € por habitante en {lic_res[0]?.anio_estado_max} y la más baja, {formatNumber(lic_res[0]?.estado_min, 0)} € en {lic_res[0]?.anio_estado_min}.

<BarChart
    data={lic}
    x=anio
    y=estado_hab_real
    series=familia_estatal
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ por habitante (euros de hoy)"
    seriesColors={{'PSOE': '#e30613', 'PP': '#1d84ce'}}
    title="Licitación del Estado por habitante y partido del Gobierno central a 1 de julio, euros constantes"
/>

<DataTable data={lic_presidentes} rows=10>
    <Column id=presidente title="Presidente del Gobierno" />
    <Column id=partido title="Partido" />
    <Column id=anios title="Años" />
    <Column id=n_anios title="N.º de años" fmt='0' />
    <Column id=estado_media title="Estado, € por hab. y año" fmt='#,##0' contentType=bar barColor='#b45309' />
    <Column id=entes_media title="Comunidades y ayuntamientos, € por hab. y año" fmt='#,##0' />
    <Column id=total_media title="Total, € por hab. y año" fmt='#,##0' />
</DataTable>

Por comunidad, en {lic_ccaa[0]?.anio} las que más licitación recibieron por habitante fueron {lic_ccaa_res[0]?.mas}, y las que menos, {lic_ccaa_res[0]?.menos}. El {formatNumber(lic_ccaa_res[0]?.pct_nr, 1)} % del total de España no se puede asignar a ninguna comunidad (obras que abarcan varias) y no aparece en el mapa. La columna del partido es el del Gobierno autonómico, pero la licitación territorial mezcla la de la comunidad con la de sus ayuntamientos.

<MapaEspana
    data={lic_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod_ccaa"
    value="total_hab_real"
    valueFmt='#,##0'
    link="ruta"
    colorPalette={['#f0fdfa', '#14b8a6', '#134e4a']}
    height={440}
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'total_hab_real', title: 'Total, € por hab.', fmt: '#,##0'},
        {id: 'estado_hab_real', title: 'Estado, € por hab.', fmt: '#,##0'},
        {id: 'entes_territoriales_hab_real', title: 'Comunidad y ayuntamientos, € por hab.', fmt: '#,##0'},
        {id: 'media_5', title: 'Media de 5 años, € por hab.', fmt: '#,##0'}
    ]}
/>

<DataTable data={lic_ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidad" />
    <Column id=total_hab_real title="Total, € por hab." fmt='#,##0' contentType=bar barColor='#14b8a6' />
    <Column id=estado_hab_real title="Estado" fmt='#,##0' />
    <Column id=entes_territoriales_hab_real title="Comunidad y ayuntamientos" fmt='#,##0' />
    <Column id=media_5 title="Media 5 años" fmt='#,##0' />
    <Column id=familia_autonomica title="Partido del Gobierno autonómico" />
    <Column id=anio title="Año" fmt='0' />
</DataTable>

## Cuánto se construye

Los colegios de aparejadores visaron en {visados_res[0]?.anio} proyectos de **{formatNumber(visados_res[0]?.ult, 2)} viviendas de obra nueva por cada 1.000 habitantes** ({formatNumber(visados_res[0]?.ult_miles, 0)} mil). En {visados_res[0]?.anio_max}, en plena burbuja, fueron {formatNumber(visados_res[0]?.max_1000, 1)} por 1.000 ({formatNumber(visados_res[0]?.max_miles, 0)} mil viviendas); en {visados_res[0]?.anio_min}, solo {formatNumber(visados_res[0]?.min_1000, 2)}. La superficie a construir pasó de un máximo de {formatNumber(visados_res[0]?.m2_max, 2)} m² por habitante a {formatNumber(visados_res[0]?.m2_ult, 2)} m².

<BarChart
    data={visados}
    x=anio
    y=viviendas_nueva_1000hab
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="viviendas por 1.000 habitantes"
    fillColor='#b45309'
    title="Viviendas de obra nueva visadas por 1.000 habitantes en España"
/>

Por comunidad, en {visados_ccaa[0]?.anio} donde más viviendas nuevas se visaron por habitante fue en {visados_ccaa_res[0]?.mas} y donde menos, en {visados_ccaa_res[0]?.menos} (de {formatNumber(visados_ccaa_res[0]?.max_1000, 1)} a {formatNumber(visados_ccaa_res[0]?.min_1000, 1)} por 1.000 habitantes). La estadística no incluye Ceuta ni Melilla.

<BarChart
    data={visados_ccaa}
    x=comunidad
    y=viviendas_nueva_1000hab
    swapXY=true
    yFmt='0.0'
    yAxisTitle="viviendas por 1.000 habitantes"
    fillColor='#b45309'
    title="Viviendas de obra nueva visadas por 1.000 habitantes y comunidad, último año"
/>

<DataTable data={visados_ccaa} rows=17 link=ruta>
    <Column id=comunidad title="Comunidad" />
    <Column id=viviendas_nueva_1000hab title="Obra nueva por 1.000 hab." fmt='0.00' contentType=bar barColor='#b45309' />
    <Column id=media_2004_2007 title="Media 2004-2007" fmt='0.00' />
    <Column id=viviendas_reforma_1000hab title="Reforma por 1.000 hab." fmt='0.00' />
    <Column id=viviendas_nueva title="Viviendas (total)" fmt='#,##0' />
    <Column id=anio title="Año" fmt='0' />
</DataTable>

Para comparar con Europa hay que usar los **permisos de construcción** de Eurostat, que no son lo mismo que los visados: para España, Eurostat da {formatNumber(permisos_res[0]?.es_miles, 0)} mil viviendas con permiso en {permisos_res[0]?.anio}, frente a {formatNumber(permisos_res[0]?.visados_miles, 0)} mil visadas, porque el INE le envía otra fuente (licencias municipales). Las dos series no se pueden mezclar. Con los permisos, España fue en {permisos_res[0]?.anio} la {permisos_res[0]?.puesto}.ª de {permisos_res[0]?.n} países, con {formatNumber(permisos_res[0]?.es, 1)} viviendas por 1.000 habitantes frente a {formatNumber(permisos_res[0]?.ue, 1)} en la UE.

<LineChart
    data={permisos_ue}
    x=anio
    y=viviendas_nueva_1000hab
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="viviendas con permiso por 1.000 hab."
    title="Viviendas con permiso de construcción por 1.000 habitantes (Eurostat)"
/>

El cemento da otra medida de la actividad. En {cemento_res[0]?.anio_max} España consumió **{formatNumber(cemento_res[0]?.max_kg, 0)} kg por habitante**; en {cemento_res[0]?.anio_min}, {formatNumber(cemento_res[0]?.min_kg, 0)} kg, y en {cemento_res[0]?.anio}, {formatNumber(cemento_res[0]?.ult, 0)} kg (en {cemento_res[0]?.anio_ini} eran {formatNumber(cemento_res[0]?.kg_1995, 0)}). Se exportó el {formatNumber(cemento_res[0]?.pct_export, 0)} % de lo producido.

<LineChart
    data={cemento_largo}
    x=anio
    y=kg_hab
    series=serie
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kg por habitante"
    seriesColors={{'Consumo aparente': '#78716c', 'Producción': '#b45309'}}
    title="Cemento en España: consumo aparente y producción, kg por habitante"
/>

## Producción y costes

El índice de producción de la construcción de Eurostat mide la actividad en volumen. En 2024 la de España estaba en el {formatNumber(prod_res[0]?.f_2024, 0)} % de la de 2007 (UE: {formatNumber(prod_res[0]?.ue_2024, 0)} %); el mínimo fue el {formatNumber(prod_res[0]?.f_min, 0)} % en {prod_res[0]?.anio_f_min}. Por ramas, en {prod_res[0]?.anio} la edificación estaba en el {formatNumber(prod_res[0]?.f41_ult, 0)} % de 2007 y la ingeniería civil, en el {formatNumber(prod_res[0]?.f42_ult, 0)} %.

{#if prod_res[0]?.hay_salto}
<p><strong>Cuidado con {prod_res[0]?.anio}:</strong> el total sube un {formatNumber(prod_res[0]?.f_var, 1)} % y la construcción especializada un {formatNumber(prod_res[0]?.f43_var, 1)} %, mientras que la edificación varía un {formatNumber(prod_res[0]?.f41_var, 1)} % y la ingeniería civil un {formatNumber(prod_res[0]?.f42_var, 1)} %. Ese salto parece una ruptura de la serie y no se debe leer como un auge.</p>
{/if}

<LineChart
    data={prod}
    x=anio
    y=indice_2007
    series=rama_nombre
    xFmt='0'
    yFmt='0'
    yAxisTitle="2007 = 100"
    title="Producción de la construcción en España por rama, 2007 = 100 (el último año del total y de la especializada es dudoso)"
/>

<LineChart
    data={prod_es_ue}
    x=anio
    y=indice_2007
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="2007 = 100"
    title="Producción de la construcción (total), 2007 = 100"
/>

Construir una vivienda nueva (materiales y mano de obra) costaba en {costes_res[0]?.anio} un índice de {formatNumber(costes_res[0]?.es_nom, 1)} (2021 = 100), frente a {formatNumber(costes_res[0]?.es_nom_2020, 1)} en 2020. Descontada la inflación general, el índice está en {formatNumber(costes_res[0]?.es_real, 1)}: si pasa de 100, construir se ha encarecido más que el resto de precios desde 2021. El máximo real fue {formatNumber(costes_res[0]?.es_real_max, 1)} en {costes_res[0]?.anio_real_max}. España no publica en Eurostat un índice de costes propio: su serie de costes es la misma que la de precios de producción. En la UE, el precio de producción de la vivienda nueva estaba en {costes_res[0]?.anio_ue} en {formatNumber(costes_res[0]?.ue_precio, 1)}.

<LineChart
    data={costes}
    x=anio
    y=indice
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="2021 = 100"
    seriesColors={{'Coste nominal': '#b45309', 'Coste descontada la inflación': '#0d9488', 'UE-27, precio de producción nominal': '#64748b'}}
    title="Costes de construcción de la vivienda nueva en España, 2021 = 100"
/>

## Las empresas

En {empresas_res[0]?.anio} había en España {formatNumber(empresas_res[0]?.es_emp, 1)} empresas de construcción por cada 1.000 habitantes (UE: {formatNumber(empresas_res[0]?.ue_emp, 1)}; puesto {empresas_res[0]?.puesto} de {empresas_res[0]?.n}), con {formatNumber(empresas_res[0]?.es_tam, 1)} ocupados de media cada una (UE: {formatNumber(empresas_res[0]?.ue_tam, 1)}). Cada persona ocupada generó {formatNumber(empresas_res[0]?.es_prod, 1)} mil euros de valor añadido, el {formatNumber(empresas_res[0]?.pct_prod_ue, 0)} % de la media de la UE ({formatNumber(empresas_res[0]?.ue_prod, 1)} mil); en Alemania, {formatNumber(empresas_res[0]?.de_prod, 1)} mil; en Francia, {formatNumber(empresas_res[0]?.fr_prod, 1)}, y en Italia, {formatNumber(empresas_res[0]?.it_prod, 1)}.

<BarChart
    data={empresas_productividad}
    x=serie
    y=productividad_miles_eur
    series=grupo
    swapXY=true
    sort=false
    yFmt='#,##0'
    yAxisTitle="miles de € por ocupado (euros corrientes)"
    seriesColors={{'España': '#dc2626', 'UE-27': '#64748b', 'Otros países': '#93c5fd'}}
    title="Productividad de la construcción: valor añadido por persona ocupada, último año"
/>

<DataTable data={empresas_ramas} rows=4>
    <Column id=rama title="Rama" />
    <Column id=es_empresas title="Empresas por 1.000 hab., España" fmt='0.00' />
    <Column id=ue_empresas title="UE" fmt='0.00' />
    <Column id=puesto_empresas title="Puesto de España" fmt='0' />
    <Column id=es_tamano title="Ocupados por empresa, España" fmt='0.0' />
    <Column id=ue_tamano title="UE" fmt='0.0' />
    <Column id=es_productividad title="Miles de € por ocupado, España" fmt='0.0' />
    <Column id=ue_productividad title="UE" fmt='0.0' />
</DataTable>

España tiene también algunas de las mayores constructoras del mundo. En el ranking Global Powers of Construction {constructoras_res[0]?.edicion} de Deloitte aparecen {constructoras_res[0]?.n} grupos españoles entre las 100 mayores constructoras cotizadas del mundo por ingresos, {constructoras_res[0]?.n_top50} de ellos entre los 50 primeros; el mejor situado es {constructoras_res[0]?.primera} ({constructoras_res[0]?.puesto_primera}.º del mundo), que obtiene fuera de España el {formatNumber(constructoras_res[0]?.pct_exterior_primera, 1)} % de sus ventas.

<DataTable data={constructoras} rows=10>
    <Column id=puesto title="Puesto mundial" fmt='0' />
    <Column id=empresa title="Empresa" />
    <Column id=ingresos_mill_usd title="Ingresos (millones de $)" fmt='#,##0' />
    <Column id=pct_ventas_exterior title="% ventas fuera de España" fmt='0.0' />
    <Column id=edicion title="Edición" fmt='0' />
</DataTable>

## Por comunidad

En {ccaa_res[0]?.anio} la construcción generó el {formatNumber(ccaa_res[0]?.es, 1)} % del valor añadido de España ({formatNumber(ccaa_res[0]?.es_2007, 1)} % en 2007), {formatNumber(ccaa_res[0]?.es_hab, 0)} € por habitante en euros de hoy. Donde más pesa es en {ccaa_res[0]?.mas}, y donde menos, en {ccaa_res[0]?.menos}. {#if ccaa_res[0]?.n_debajo == ccaa_res[0]?.n}Todas las comunidades pesan hoy menos que en 2007{:else}{ccaa_res[0]?.n_debajo} de las {ccaa_res[0]?.n} comunidades pesan hoy menos que en 2007{/if}; la mayor caída es la de {ccaa_res[0]?.mas_caida}, que ha pasado del {formatNumber(ccaa_res[0]?.mas_caida_2007, 1)} % al {formatNumber(ccaa_res[0]?.mas_caida_ult, 1)} % ({formatNumber(ccaa_res[0]?.caida_max, 1)} puntos).

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod_ccaa"
    value="pct_vab_construccion"
    valueFmt='0.0'
    link="ruta"
    colorPalette={['#fffbeb', '#f59e0b', '#78350f']}
    height={440}
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_vab_construccion', title: 'Construcción, % del VAB', fmt: '0.0'},
        {id: 'pct_vab_2007', title: '% del VAB en 2007', fmt: '0.0'},
        {id: 'dif_pp_vs_2007', title: 'Diferencia con 2007 (puntos)', fmt: '0.0'},
        {id: 'vab_constr_hab_real', title: 'VAB del sector por hab. (euros de hoy)', fmt: '#,##0'}
    ]}
/>

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod_ccaa"
    value="dif_pp_vs_2007"
    valueFmt='0.0'
    link="ruta"
    colorPalette={['#7f1d1d', '#f87171', '#fef2f2']}
    height={440}
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'dif_pp_vs_2007', title: 'Diferencia con 2007 (puntos de VAB)', fmt: '0.0'},
        {id: 'pct_vab_2007', title: '% del VAB en 2007', fmt: '0.0'},
        {id: 'pct_vab_construccion', title: '% del VAB hoy', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidad" />
    <Column id=pct_vab_construccion title="% del VAB" fmt='0.0' contentType=bar barColor='#f59e0b' />
    <Column id=pct_vab_2007 title="% en 2007" fmt='0.0' />
    <Column id=dif_pp_vs_2007 title="Diferencia (puntos)" fmt='0.0' />
    <Column id=vab_constr_hab_real title="€ por hab. (euros de hoy)" fmt='#,##0' />
    <Column id=ocupados_constr_1000hab_epa title="Ocupados por 1.000 hab. (EPA)" fmt='0.0' />
    <Column id=anio title="Año" fmt='0' />
</DataTable>

## Metodología y fuentes

- **Peso en la economía y comparación con la UE:** Eurostat, cuentas nacionales por rama [nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table) (VAB a precios corrientes y en volumen encadenado) y [nama_10_a10_e](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10_e/default/table) (empleo); población, [nama_10_pe](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe/default/table). Construcción = sección F de la NACE.
- **Empleo:** INE, Encuesta de Población Activa, ocupados por sector y provincia ([tabla 65354](https://www.ine.es/jaxiT3/Tabla.htm?t=65354)) y parados por sector del último empleo ([tabla 65331](https://www.ine.es/jaxiT3/Tabla.htm?t=65331)), CNAE-2009, desde 2008. La tasa de paro del sector es una aproximación: los parados que dejaron su empleo hace más de un año no tienen sector. Afiliados: [Seguridad Social, afiliados medios por actividad](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST8) (Régimen General y Autónomos).
- **Licitación oficial:** Ministerio de Transportes y Movilidad Sostenible, [licitación oficial en construcción](https://www.transportes.gob.es/informacion-para-el-ciudadano/informacion-estadistica/construccion/licitacion-oficial-en-construccion), por comunidad vía [ISTAC](https://datos.canarias.es/api/estadisticas/) (E20004A_000001); la parte de las entidades públicas estatales, del [Banco de España, Boletín Estadístico, cuadro 23.9](https://www.bde.es/webbe/es/estadisticas/compartido/datos/pdf/be2309.pdf). Presupuesto con IVA en el año en que se licita. «Entes territoriales» = comunidades autónomas + entidades locales (la fuente abierta no las separa). Partido del Gobierno a 1 de julio de cada año.
- **Visados:** visados de dirección de obra de los colegios de aparejadores (Ministerio de Transportes), por comunidad vía ISTAC (E20006A_000002) desde 2000 y para España desde 1992 en el [Banco de España, cuadro 23.8](https://www.bde.es/webbe/es/estadisticas/compartido/datos/pdf/be2308.pdf). **Permisos:** Eurostat [sts_cobp_a](https://ec.europa.eu/eurostat/databrowser/view/sts_cobp_a/default/table) (viviendas en edificios residenciales sin residencias colectivas); no son comparables con los visados.
- **Cemento:** [Banco de España, cuadro 23.11](https://www.bde.es/webbe/es/estadisticas/compartido/datos/pdf/be2311.pdf) (datos de Oficemen y del Ministerio de Industria). Consumo aparente = producción + importaciones − exportaciones; solo años completos.
- **Producción y costes:** Eurostat [sts_copr_a](https://ec.europa.eu/eurostat/databrowser/view/sts_copr_a/default/table) (índice de producción, corregido de calendario, 2021 = 100, rebasado a 2007 = 100) y [sts_copi_a](https://ec.europa.eu/eurostat/databrowser/view/sts_copi_a/default/table) (costes y precios de producción de la vivienda nueva). El salto de 2025 en el total y en la construcción especializada de España se trata como posible ruptura de serie.
- **Empresas:** Eurostat, estadísticas estructurales de empresas [sbs_ovw_act](https://ec.europa.eu/eurostat/databrowser/view/sbs_ovw_act/default/table) (empresas, ocupados y valor añadido; euros corrientes del año, solo para comparar países). Grandes constructoras: [Deloitte, Global Powers of Construction](https://www.deloitte.com/es/es/Industries/energy/perspectives/deloitte-global-powers-of-construction.html), cifras citadas con fuente (ingresos en millones de dólares corrientes, solo los que da la fuente).
- **Comunidades:** Eurostat, VAB regional [nama_10r_3gva](https://ec.europa.eu/eurostat/databrowser/view/nama_10r_3gva/default/table), que reproduce la Contabilidad Regional del INE.
- **Euros constantes:** IPC del INE (euros de {lic_res[0]?.anio_base}); entre 1996 y 2001, enlazado con el IPCA de España de Eurostat ([prc_hicp_aind](https://ec.europa.eu/eurostat/databrowser/view/prc_hicp_aind/default/table)). Antes de 1996 no se dan cifras en euros. Población del INE (comunidades) y de Eurostat (España y UE).
