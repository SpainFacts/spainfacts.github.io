---
title: Construción
description: "A construción en España fronte á UE: peso no valor engadido e no emprego desde 1995, a burbulla de 2007 e o derrubamento, licitación de obra pública en euros reais por habitante e partido do Goberno, vivendas visadas, cemento, produción, custos, empresas e comunidades."
i18n_origen: 60f03001a5e1
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    const mesesGl = {enero: 'xaneiro', febrero: 'febreiro', marzo: 'marzo', abril: 'abril', mayo: 'maio', junio: 'xuño', julio: 'xullo', agosto: 'agosto', septiembre: 'setembro', octubre: 'outubro', noviembre: 'novembro', diciembre: 'decembro'};
    const mesGl = (t) => (t == null ? t : String(t).replace(/^(\S+) de /, (m, mes) => (mesesGl[mes] ?? mes) + ' de '));
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
    '/gl' || t.ruta AS ruta,
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
    '/gl' || t.ruta AS ruta,
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
    '/gl' || t.ruta AS ruta,
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

# 🏗️ Construción

A construción foi o motor e despois o lastre da economía española. En {peso_res[0]?.anio_vab_max} chegou a xerar o **{formatNumber(peso_res[0]?.es_vab_max, 1)} % do valor engadido** de España, fronte ao {formatNumber(peso_res[0]?.ue_vab_anio_max, 1)} % de media na UE, e en 2007 daba traballo a {formatNumber(peso_res[0]?.ocup_2007_mill, 2)} millóns de persoas, o {formatNumber(peso_res[0]?.es_emp_2007, 1)} % dos ocupados. Tras o estoupido da burbulla, a actividade real do sector caeu ata o {formatNumber(peso_res[0]?.es_vol_min, 0)} % da de 2007 en {peso_res[0]?.anio_vol_min}. En {peso_res[0]?.anio} pesa o {formatNumber(peso_res[0]?.es_vab, 1)} % (UE: {formatNumber(peso_res[0]?.ue_vab, 1)} %) e España ocupa o posto {peso_res[0]?.puesto} de {peso_res[0]?.n_paises} países da UE. As cifras van **por habitante** e, as de euros, **descontada a inflación** (euros de {lic_res[0]?.anio_base}). A vivenda que se empeza e se remata cada ano está en [Obra nova](/gl/vivienda/construccion).

<Grid cols=4>
    <KpiCard
        title="Peso no valor engadido"
        value={peso_res[0]?.es_vab}
        formattedValue="{formatNumber(peso_res[0]?.es_vab, 1)} %"
        period="{peso_res[0]?.anio} · UE-27: {formatNumber(peso_res[0]?.ue_vab, 1)} % · posto {peso_res[0]?.puesto} de {peso_res[0]?.n_paises}"
        change={(peso_res[0]?.es_vab - peso_res[0]?.es_vab_2007)?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs 2007"
        direction="neutral"
        source="Eurostat (nama_10_a10)"
        sparklineData={peso_es.map(d => d.pct_vab_construccion)}
    />
    <KpiCard
        title="Ocupados por 1.000 habitantes"
        value={epa_res[0]?.ocup_1000}
        formattedValue="{formatNumber(epa_res[0]?.ocup_1000, 1)}"
        period="{epa_res[0]?.etiqueta} · {formatNumber(epa_res[0]?.ocup_mill, 2)} millóns · UE-27 ({peso_res[0]?.anio}): {formatNumber(peso_res[0]?.ue_ocup_1000, 1)}"
        change={(epa_res[0]?.ocup_1000 - epa_res[0]?.ocup_1000_hace_un_anio)?.toFixed(1)}
        changeUnit=""
        changePeriod="vs hai un ano"
        direction="positive-up"
        source="INE (EPA)"
        sparklineData={epa.map(d => d.ocupados_constr_1000hab)}
    />
    <KpiCard
        title="Licitación pública por habitante"
        value={lic_res[0]?.total}
        formattedValue="{formatNumber(lic_res[0]?.total, 0)} €"
        period="{lic_res[0]?.anio}, euros de {lic_res[0]?.anio_base} · {formatNumber(lic_res[0]?.total_mm, 1)} mil millóns en total · {lic_res[0]?.estado_dato}"
        change={lic_res[0]?.var_2007?.toFixed(0)}
        changeUnit="%"
        changePeriod="vs 2007"
        direction="neutral"
        source="Mº de Transportes"
        sparklineData={lic.map(d => d.total_hab_real)}
    />
    <KpiCard
        title="Vivendas visadas por 1.000 hab."
        value={visados_res[0]?.ult}
        formattedValue="{formatNumber(visados_res[0]?.ult, 2)}"
        period="{visados_res[0]?.anio} · obra nova · {formatNumber(visados_res[0]?.ult_miles, 0)} mil vivendas · máximo: {formatNumber(visados_res[0]?.max_1000, 1)} en {visados_res[0]?.anio_max}"
        change={visados_res[0]?.var_anual?.toFixed(1)}
        changeUnit="%"
        changePeriod="vs ano anterior"
        direction="neutral"
        source="Colexios de aparelladores (BdE)"
        sparklineData={visados.map(d => d.viviendas_nueva_1000hab)}
    />
</Grid>

## O auxe e a caída

En 1995 a construción xa pesaba máis en España que na UE ({formatNumber(peso_res[0]?.es_vab_1995, 1)} % do valor engadido fronte a {formatNumber(peso_res[0]?.ue_vab_1995, 1)} %). En 2007 {#if peso_res[0]?.puesto_2007 == 1}era o país dos 27 onde máis pesaba{:else}era o {peso_res[0]?.puesto_2007}.º dos 27{/if} e concentraba o {formatNumber(peso_res[0]?.es_emp_2007, 1)} % do emprego, fronte ao {formatNumber(peso_res[0]?.ue_emp_2007, 1)} % europeo. O peso máis baixo desde entón foi o de {peso_res[0]?.anio_vab_min}, o {formatNumber(peso_res[0]?.es_vab_min, 1)} %. En {peso_res[0]?.anio}, co {formatNumber(peso_res[0]?.es_vab, 1)} % do valor engadido e o {formatNumber(peso_res[0]?.es_emp, 1)} % do emprego (UE: {formatNumber(peso_res[0]?.ue_vab, 1)} % e {formatNumber(peso_res[0]?.ue_emp, 1)} %), España é a {peso_res[0]?.puesto}.ª de {peso_res[0]?.n_paises}.

<LineChart
    data={peso}
    x=anio
    y=pct_vab_construccion
    series=serie
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% do valor engadido bruto"
    title="Peso da construción no valor engadido, % a prezos correntes"
/>

<LineChart
    data={peso_es_ue}
    x=anio
    y=pct_empleo_construccion
    series=serie
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% dos ocupados"
    seriesColors={{'España': '#dc2626', 'UE-27': '#64748b'}}
    title="Peso da construción no emprego, % dos ocupados"
/>

Sen o efecto dos prezos (en volume), o valor engadido da construción española era en 1995 o {formatNumber(peso_res[0]?.es_vol_1995, 0)} % do de 2007; tocou fondo en {peso_res[0]?.anio_vol_min} co {formatNumber(peso_res[0]?.es_vol_min, 0)} % e en {peso_res[0]?.anio} está no {formatNumber(peso_res[0]?.es_vol, 0)} %. No conxunto da UE está no {formatNumber(peso_res[0]?.ue_vol, 0)} % de 2007. Por habitante, o valor engadido do sector pasou de {formatNumber(peso_res[0]?.es_vabhab_2007, 0)} € en 2007 a {formatNumber(peso_res[0]?.es_vabhab, 0)} € en {peso_res[0]?.anio}, en euros de hoxe.

<LineChart
    data={peso}
    x=anio
    y=vab_constr_real_indice_2007
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="2007 = 100"
    title="Valor engadido da construción en volume (sen efecto dos prezos), 2007 = 100"
/>

## Emprego

Segundo a EPA, no {epa_res[0]?.etiqueta} traballaban na construción **{formatNumber(epa_res[0]?.ocup_mill, 2)} millóns de persoas**, {formatNumber(epa_res[0]?.ocup_1000, 1)} por cada 1.000 habitantes e o {formatNumber(epa_res[0]?.pct, 1)} % dos ocupados. A comezos de 2008 eran {formatNumber(epa_res[0]?.ocup_2008_mill, 2)} millóns ({formatNumber(epa_res[0]?.ocup_1000_2008, 1)} por 1.000 habitantes); o mínimo da serie foi {formatNumber(epa_res[0]?.ocup_1000_min, 1)} no {epa_res[0]?.etiqueta_min}. En 2007, cos datos anuais de Eurostat, España tiña {formatNumber(peso_res[0]?.es_ocup_1000_2007, 1)} ocupados no sector por 1.000 habitantes fronte a {formatNumber(peso_res[0]?.ue_ocup_1000_2007, 1)} na UE; en {peso_res[0]?.anio}, {formatNumber(peso_res[0]?.es_ocup_1000, 1)} fronte a {formatNumber(peso_res[0]?.ue_ocup_1000, 1)}.

<LineChart
    data={epa}
    x=fecha
    y=ocupados_constr_1000hab
    yFmt='0.0'
    yAxisTitle="ocupados por 1.000 habitantes"
    colorPalette={['#b45309']}
    title="Ocupados na construción por 1.000 habitantes, por trimestre (EPA)"
/>

A taxa de paro do sector, calculada cos parados que deixaron o seu emprego na construción hai menos dun ano, pasou do {formatNumber(epa_res[0]?.paro_2008, 1)} % a comezos de 2008 a un máximo do {formatNumber(epa_res[0]?.paro_max, 1)} % no {epa_res[0]?.etiqueta_paro_max}; no {epa_res[0]?.etiqueta} é do {formatNumber(epa_res[0]?.paro, 1)} %.

<LineChart
    data={epa}
    x=fecha
    y=tasa_paro_constr
    yFmt='0.0"%"'
    yAxisTitle="% dos activos do sector"
    colorPalette={['#dc2626']}
    title="Taxa de paro aproximada da construción, por trimestre (EPA)"
/>

Na Seguridade Social, a construción tiña en {mesGl(afil_res[0]?.mes_ultimo)} **{formatNumber(afil_res[0]?.afil_mill, 2)} millóns de afiliados** de media ({formatNumber(afil_res[0]?.afil_1000, 1)} por 1.000 habitantes e o {formatNumber(afil_res[0]?.pct, 1)} % de todos os afiliados), un {#if afil_res[0]?.var_anual >= 0}{formatNumber(afil_res[0]?.var_anual, 1)} % máis{:else}{formatNumber(-afil_res[0]?.var_anual, 1)} % menos{/if} que un ano antes. O {formatNumber(afil_res[0]?.pct_aut, 1)} % son autónomos, fronte ao {formatNumber(afil_res[0]?.pct_aut_2021, 1)} % de xaneiro de 2021. Desde xaneiro de 2026 a Seguridade Social clasifica coa nova CNAE-2025, o que pode dar pequenos saltos.

<LineChart
    data={afil}
    x=fecha
    y=afiliados_constr_1000hab
    yFmt='0.0'
    yAxisTitle="afiliados por 1.000 habitantes"
    colorPalette={['#b45309']}
    title="Afiliados á Seguridade Social na construción por 1.000 habitantes, media mensual"
/>

<LineChart
    data={afil}
    x=fecha
    y=pct_autonomos_constr
    yFmt='0.0"%"'
    yAxisTitle="% dos afiliados do sector"
    colorPalette={['#7c3aed']}
    title="Autónomos na construción, % dos afiliados do sector"
/>

## Obra pública

A licitación oficial é o orzamento das obras que sacan a concurso as administracións (con IVE). En {lic_res[0]?.anio} sumou **{formatNumber(lic_res[0]?.total, 0)} € por habitante** en euros de {lic_res[0]?.anio_base}: {formatNumber(lic_res[0]?.estado, 0)} € do Estado (incluídas as súas entidades públicas, como Adif, Aena ou Portos, que achegan {formatNumber(lic_res[0]?.epe, 0)} €) e {formatNumber(lic_res[0]?.entes, 0)} € dos «entes territoriais», que nesta estatística suman comunidades autónomas e concellos sen separalos. O {formatNumber(lic_res[0]?.pct_obra_civil, 0)} % foi obra civil e o resto edificación. O máximo desde {lic_res[0]?.anio_ini} foi {formatNumber(lic_res[0]?.total_max, 0)} € en {lic_res[0]?.anio_max} e o mínimo, {formatNumber(lic_res[0]?.total_min, 0)} € en {lic_res[0]?.anio_min}.

{#if lic_res[0]?.hay_provisional}
<p>Os datos desde {lic_res[0]?.anio_prov} son <strong>provisionais</strong>.</p>
{/if}

<BarChart
    data={lic_agentes}
    x=anio
    y=eur_hab
    series=agente
    type=stacked
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ por habitante (euros de hoxe)"
    seriesColors={{'Estado (con Adif, Aena, Puertos...)': '#b45309', 'Comunidades y ayuntamientos': '#0d9488'}}
    title="Licitación oficial de obra pública por habitante, euros constantes"
/>

A parte do Estado depende do Goberno central. Cada barra coloréase co partido que gobernaba a 1 de xullo dese ano; é unha descrición, non unha explicación: cada período coincide cunha fase distinta do ciclo económico. Con Gobernos do PP ({lic_partidos.filter(d => d.partido === 'PP')[0]?.n_anios} anos da serie) a licitación do Estado foi de {formatNumber(lic_partidos.filter(d => d.partido === 'PP')[0]?.estado_media, 0)} € por habitante e ano de media, e con Gobernos do PSOE ({lic_partidos.filter(d => d.partido === 'PSOE')[0]?.n_anios} anos), de {formatNumber(lic_partidos.filter(d => d.partido === 'PSOE')[0]?.estado_media, 0)} €. A máis alta foi de {formatNumber(lic_res[0]?.estado_max, 0)} € por habitante en {lic_res[0]?.anio_estado_max} e a máis baixa, {formatNumber(lic_res[0]?.estado_min, 0)} € en {lic_res[0]?.anio_estado_min}.

<BarChart
    data={lic}
    x=anio
    y=estado_hab_real
    series=familia_estatal
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ por habitante (euros de hoxe)"
    seriesColors={{'PSOE': '#e30613', 'PP': '#1d84ce'}}
    title="Licitación do Estado por habitante e partido do Goberno central a 1 de xullo, euros constantes"
/>

<DataTable data={lic_presidentes} rows=10>
    <Column id=presidente title="Presidente do Goberno" />
    <Column id=partido title="Partido" />
    <Column id=anios title="Anos" />
    <Column id=n_anios title="N.º de anos" fmt='0' />
    <Column id=estado_media title="Estado, € por hab. e ano" fmt='#,##0' contentType=bar barColor='#b45309' />
    <Column id=entes_media title="Comunidades e concellos, € por hab. e ano" fmt='#,##0' />
    <Column id=total_media title="Total, € por hab. e ano" fmt='#,##0' />
</DataTable>

Por comunidade, en {lic_ccaa[0]?.anio} as que máis licitación recibiron por habitante foron {lic_ccaa_res[0]?.mas}, e as que menos, {lic_ccaa_res[0]?.menos}. O {formatNumber(lic_ccaa_res[0]?.pct_nr, 1)} % do total de España non se pode asignar a ningunha comunidade (obras que abranguen varias) e non aparece no mapa. A columna do partido é a do Goberno autonómico, pero a licitación territorial mestura a da comunidade coa dos seus concellos.

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
        {id: 'entes_territoriales_hab_real', title: 'Comunidade e concellos, € por hab.', fmt: '#,##0'},
        {id: 'media_5', title: 'Media de 5 anos, € por hab.', fmt: '#,##0'}
    ]}
/>

<DataTable data={lic_ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidade" />
    <Column id=total_hab_real title="Total, € por hab." fmt='#,##0' contentType=bar barColor='#14b8a6' />
    <Column id=estado_hab_real title="Estado" fmt='#,##0' />
    <Column id=entes_territoriales_hab_real title="Comunidade e concellos" fmt='#,##0' />
    <Column id=media_5 title="Media 5 anos" fmt='#,##0' />
    <Column id=familia_autonomica title="Partido do Goberno autonómico" />
    <Column id=anio title="Ano" fmt='0' />
</DataTable>

## Canto se constrúe

Os colexios de aparelladores visaron en {visados_res[0]?.anio} proxectos de **{formatNumber(visados_res[0]?.ult, 2)} vivendas de obra nova por cada 1.000 habitantes** ({formatNumber(visados_res[0]?.ult_miles, 0)} mil). En {visados_res[0]?.anio_max}, en plena burbulla, foron {formatNumber(visados_res[0]?.max_1000, 1)} por 1.000 ({formatNumber(visados_res[0]?.max_miles, 0)} mil vivendas); en {visados_res[0]?.anio_min}, só {formatNumber(visados_res[0]?.min_1000, 2)}. A superficie para construír pasou dun máximo de {formatNumber(visados_res[0]?.m2_max, 2)} m² por habitante a {formatNumber(visados_res[0]?.m2_ult, 2)} m².

<BarChart
    data={visados}
    x=anio
    y=viviendas_nueva_1000hab
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="vivendas por 1.000 habitantes"
    fillColor='#b45309'
    title="Vivendas de obra nova visadas por 1.000 habitantes en España"
/>

Por comunidade, en {visados_ccaa[0]?.anio} onde máis vivendas novas se visaron por habitante foi en {visados_ccaa_res[0]?.mas} e onde menos, en {visados_ccaa_res[0]?.menos} (de {formatNumber(visados_ccaa_res[0]?.max_1000, 1)} a {formatNumber(visados_ccaa_res[0]?.min_1000, 1)} por 1.000 habitantes). A estatística non inclúe Ceuta nin Melilla.

<BarChart
    data={visados_ccaa}
    x=comunidad
    y=viviendas_nueva_1000hab
    swapXY=true
    yFmt='0.0'
    yAxisTitle="vivendas por 1.000 habitantes"
    fillColor='#b45309'
    title="Vivendas de obra nova visadas por 1.000 habitantes e comunidade, último ano"
/>

<DataTable data={visados_ccaa} rows=17 link=ruta>
    <Column id=comunidad title="Comunidade" />
    <Column id=viviendas_nueva_1000hab title="Obra nova por 1.000 hab." fmt='0.00' contentType=bar barColor='#b45309' />
    <Column id=media_2004_2007 title="Media 2004-2007" fmt='0.00' />
    <Column id=viviendas_reforma_1000hab title="Reforma por 1.000 hab." fmt='0.00' />
    <Column id=viviendas_nueva title="Vivendas (total)" fmt='#,##0' />
    <Column id=anio title="Ano" fmt='0' />
</DataTable>

Para comparar con Europa hai que usar os **permisos de construción** de Eurostat, que non son o mesmo que os visados: para España, Eurostat dá {formatNumber(permisos_res[0]?.es_miles, 0)} mil vivendas con permiso en {permisos_res[0]?.anio}, fronte a {formatNumber(permisos_res[0]?.visados_miles, 0)} mil visadas, porque o INE lle envía outra fonte (licenzas municipais). As dúas series non se poden mesturar. Cos permisos, España foi en {permisos_res[0]?.anio} a {permisos_res[0]?.puesto}.ª de {permisos_res[0]?.n} países, con {formatNumber(permisos_res[0]?.es, 1)} vivendas por 1.000 habitantes fronte a {formatNumber(permisos_res[0]?.ue, 1)} na UE.

<LineChart
    data={permisos_ue}
    x=anio
    y=viviendas_nueva_1000hab
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="vivendas con permiso por 1.000 hab."
    title="Vivendas con permiso de construción por 1.000 habitantes (Eurostat)"
/>

O cemento dá outra medida da actividade. En {cemento_res[0]?.anio_max} España consumiu **{formatNumber(cemento_res[0]?.max_kg, 0)} kg por habitante**; en {cemento_res[0]?.anio_min}, {formatNumber(cemento_res[0]?.min_kg, 0)} kg, e en {cemento_res[0]?.anio}, {formatNumber(cemento_res[0]?.ult, 0)} kg (en {cemento_res[0]?.anio_ini} eran {formatNumber(cemento_res[0]?.kg_1995, 0)}). Exportouse o {formatNumber(cemento_res[0]?.pct_export, 0)} % do producido.

<LineChart
    data={cemento_largo}
    x=anio
    y=kg_hab
    series=serie
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kg por habitante"
    seriesColors={{'Consumo aparente': '#78716c', 'Producción': '#b45309'}}
    title="Cemento en España: consumo aparente e produción, kg por habitante"
/>

## Produción e custos

O índice de produción da construción de Eurostat mide a actividade en volume. En 2024 a de España estaba no {formatNumber(prod_res[0]?.f_2024, 0)} % da de 2007 (UE: {formatNumber(prod_res[0]?.ue_2024, 0)} %); o mínimo foi o {formatNumber(prod_res[0]?.f_min, 0)} % en {prod_res[0]?.anio_f_min}. Por ramas, en {prod_res[0]?.anio} a edificación estaba no {formatNumber(prod_res[0]?.f41_ult, 0)} % de 2007 e a enxeñaría civil, no {formatNumber(prod_res[0]?.f42_ult, 0)} %.

{#if prod_res[0]?.hay_salto}
<p><strong>Coidado con {prod_res[0]?.anio}:</strong> o total sobe un {formatNumber(prod_res[0]?.f_var, 1)} % e a construción especializada un {formatNumber(prod_res[0]?.f43_var, 1)} %, mentres que a edificación varía un {formatNumber(prod_res[0]?.f41_var, 1)} % e a enxeñaría civil un {formatNumber(prod_res[0]?.f42_var, 1)} %. Ese salto semella unha ruptura da serie e non se debe ler como un auxe.</p>
{/if}

<LineChart
    data={prod}
    x=anio
    y=indice_2007
    series=rama_nombre
    xFmt='0'
    yFmt='0'
    yAxisTitle="2007 = 100"
    title="Produción da construción en España por rama, 2007 = 100 (o último ano do total e da especializada é dubidoso)"
/>

<LineChart
    data={prod_es_ue}
    x=anio
    y=indice_2007
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="2007 = 100"
    title="Produción da construción (total), 2007 = 100"
/>

Construír unha vivenda nova (materiais e man de obra) custaba en {costes_res[0]?.anio} un índice de {formatNumber(costes_res[0]?.es_nom, 1)} (2021 = 100), fronte a {formatNumber(costes_res[0]?.es_nom_2020, 1)} en 2020. Descontada a inflación xeral, o índice está en {formatNumber(costes_res[0]?.es_real, 1)}: se pasa de 100, construír encareceu máis que o resto de prezos desde 2021. O máximo real foi {formatNumber(costes_res[0]?.es_real_max, 1)} en {costes_res[0]?.anio_real_max}. España non publica en Eurostat un índice de custos propio: a súa serie de custos é a mesma que a de prezos de produción. Na UE, o prezo de produción da vivenda nova estaba en {costes_res[0]?.anio_ue} en {formatNumber(costes_res[0]?.ue_precio, 1)}.

<LineChart
    data={costes}
    x=anio
    y=indice
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="2021 = 100"
    seriesColors={{'Coste nominal': '#b45309', 'Coste descontada la inflación': '#0d9488', 'UE-27, precio de producción nominal': '#64748b'}}
    title="Custos de construción da vivenda nova en España, 2021 = 100"
/>

## As empresas

En {empresas_res[0]?.anio} había en España {formatNumber(empresas_res[0]?.es_emp, 1)} empresas de construción por cada 1.000 habitantes (UE: {formatNumber(empresas_res[0]?.ue_emp, 1)}; posto {empresas_res[0]?.puesto} de {empresas_res[0]?.n}), con {formatNumber(empresas_res[0]?.es_tam, 1)} ocupados de media cada unha (UE: {formatNumber(empresas_res[0]?.ue_tam, 1)}). Cada persoa ocupada xerou {formatNumber(empresas_res[0]?.es_prod, 1)} mil euros de valor engadido, o {formatNumber(empresas_res[0]?.pct_prod_ue, 0)} % da media da UE ({formatNumber(empresas_res[0]?.ue_prod, 1)} mil); en Alemaña, {formatNumber(empresas_res[0]?.de_prod, 1)} mil; en Francia, {formatNumber(empresas_res[0]?.fr_prod, 1)}, e en Italia, {formatNumber(empresas_res[0]?.it_prod, 1)}.

<BarChart
    data={empresas_productividad}
    x=serie
    y=productividad_miles_eur
    series=grupo
    swapXY=true
    sort=false
    yFmt='#,##0'
    yAxisTitle="miles de € por ocupado (euros correntes)"
    seriesColors={{'España': '#dc2626', 'UE-27': '#64748b', 'Otros países': '#93c5fd'}}
    title="Produtividade da construción: valor engadido por persoa ocupada, último ano"
/>

<DataTable data={empresas_ramas} rows=4>
    <Column id=rama title="Rama" />
    <Column id=es_empresas title="Empresas por 1.000 hab., España" fmt='0.00' />
    <Column id=ue_empresas title="UE" fmt='0.00' />
    <Column id=puesto_empresas title="Posto de España" fmt='0' />
    <Column id=es_tamano title="Ocupados por empresa, España" fmt='0.0' />
    <Column id=ue_tamano title="UE" fmt='0.0' />
    <Column id=es_productividad title="Miles de € por ocupado, España" fmt='0.0' />
    <Column id=ue_productividad title="UE" fmt='0.0' />
</DataTable>

España ten tamén algunhas das maiores construtoras do mundo. No ranking Global Powers of Construction {constructoras_res[0]?.edicion} de Deloitte aparecen {constructoras_res[0]?.n} grupos españois entre as 100 maiores construtoras cotizadas do mundo por ingresos, {constructoras_res[0]?.n_top50} deles entre os 50 primeiros; o mellor situado é {constructoras_res[0]?.primera} ({constructoras_res[0]?.puesto_primera}.º do mundo), que obtén fóra de España o {formatNumber(constructoras_res[0]?.pct_exterior_primera, 1)} % das súas vendas.

<DataTable data={constructoras} rows=10>
    <Column id=puesto title="Posto mundial" fmt='0' />
    <Column id=empresa title="Empresa" />
    <Column id=ingresos_mill_usd title="Ingresos (millóns de $)" fmt='#,##0' />
    <Column id=pct_ventas_exterior title="% vendas fóra de España" fmt='0.0' />
    <Column id=edicion title="Edición" fmt='0' />
</DataTable>

## Por comunidade

En {ccaa_res[0]?.anio} a construción xerou o {formatNumber(ccaa_res[0]?.es, 1)} % do valor engadido de España ({formatNumber(ccaa_res[0]?.es_2007, 1)} % en 2007), {formatNumber(ccaa_res[0]?.es_hab, 0)} € por habitante en euros de hoxe. Onde máis pesa é en {ccaa_res[0]?.mas}, e onde menos, en {ccaa_res[0]?.menos}. {#if ccaa_res[0]?.n_debajo == ccaa_res[0]?.n}Todas as comunidades pesan hoxe menos que en 2007{:else}{ccaa_res[0]?.n_debajo} das {ccaa_res[0]?.n} comunidades pesan hoxe menos que en 2007{/if}; a maior caída é a de {ccaa_res[0]?.mas_caida}, que pasou do {formatNumber(ccaa_res[0]?.mas_caida_2007, 1)} % ao {formatNumber(ccaa_res[0]?.mas_caida_ult, 1)} % ({formatNumber(ccaa_res[0]?.caida_max, 1)} puntos).

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
        {id: 'pct_vab_construccion', title: 'Construción, % do VEB', fmt: '0.0'},
        {id: 'pct_vab_2007', title: '% do VEB en 2007', fmt: '0.0'},
        {id: 'dif_pp_vs_2007', title: 'Diferenza con 2007 (puntos)', fmt: '0.0'},
        {id: 'vab_constr_hab_real', title: 'VEB do sector por hab. (euros de hoxe)', fmt: '#,##0'}
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
        {id: 'dif_pp_vs_2007', title: 'Diferenza con 2007 (puntos de VEB)', fmt: '0.0'},
        {id: 'pct_vab_2007', title: '% do VEB en 2007', fmt: '0.0'},
        {id: 'pct_vab_construccion', title: '% do VEB hoxe', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidade" />
    <Column id=pct_vab_construccion title="% do VEB" fmt='0.0' contentType=bar barColor='#f59e0b' />
    <Column id=pct_vab_2007 title="% en 2007" fmt='0.0' />
    <Column id=dif_pp_vs_2007 title="Diferenza (puntos)" fmt='0.0' />
    <Column id=vab_constr_hab_real title="€ por hab. (euros de hoxe)" fmt='#,##0' />
    <Column id=ocupados_constr_1000hab_epa title="Ocupados por 1.000 hab. (EPA)" fmt='0.0' />
    <Column id=anio title="Ano" fmt='0' />
</DataTable>

## Metodoloxía e fontes

- **Peso na economía e comparación coa UE:** Eurostat, contas nacionais por rama [nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table) (VEB a prezos correntes e en volume encadeado) e [nama_10_a10_e](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10_e/default/table) (emprego); poboación, [nama_10_pe](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe/default/table). Construción = sección F da NACE.
- **Emprego:** INE, Enquisa de Poboación Activa, ocupados por sector e provincia ([táboa 65354](https://www.ine.es/jaxiT3/Tabla.htm?t=65354)) e parados por sector do último emprego ([táboa 65331](https://www.ine.es/jaxiT3/Tabla.htm?t=65331)), CNAE-2009, desde 2008. A taxa de paro do sector é unha aproximación: os parados que deixaron o seu emprego hai máis dun ano non teñen sector. Afiliados: [Seguridade Social, afiliados medios por actividade](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST8) (Réxime Xeral e Autónomos).
- **Licitación oficial:** Ministerio de Transportes e Mobilidade Sustentable, [licitación oficial en construción](https://www.transportes.gob.es/informacion-para-el-ciudadano/informacion-estadistica/construccion/licitacion-oficial-en-construccion), por comunidade vía [ISTAC](https://datos.canarias.es/api/estadisticas/) (E20004A_000001); a parte das entidades públicas estatais, do [Banco de España, Boletín Estatístico, cadro 23.9](https://www.bde.es/webbe/es/estadisticas/compartido/datos/pdf/be2309.pdf). Orzamento con IVE no ano en que se licita. «Entes territoriais» = comunidades autónomas + entidades locais (a fonte aberta non as separa). Partido do Goberno a 1 de xullo de cada ano.
- **Visados:** visados de dirección de obra dos colexios de aparelladores (Ministerio de Transportes), por comunidade vía ISTAC (E20006A_000002) desde 2000 e para España desde 1992 no [Banco de España, cadro 23.8](https://www.bde.es/webbe/es/estadisticas/compartido/datos/pdf/be2308.pdf). **Permisos:** Eurostat [sts_cobp_a](https://ec.europa.eu/eurostat/databrowser/view/sts_cobp_a/default/table) (vivendas en edificios residenciais sen residencias colectivas); non son comparables cos visados.
- **Cemento:** [Banco de España, cadro 23.11](https://www.bde.es/webbe/es/estadisticas/compartido/datos/pdf/be2311.pdf) (datos de Oficemen e do Ministerio de Industria). Consumo aparente = produción + importacións − exportacións; só anos completos.
- **Produción e custos:** Eurostat [sts_copr_a](https://ec.europa.eu/eurostat/databrowser/view/sts_copr_a/default/table) (índice de produción, corrixido de calendario, 2021 = 100, rebasado a 2007 = 100) e [sts_copi_a](https://ec.europa.eu/eurostat/databrowser/view/sts_copi_a/default/table) (custos e prezos de produción da vivenda nova). O salto de 2025 no total e na construción especializada de España trátase como posible ruptura de serie.
- **Empresas:** Eurostat, estatísticas estruturais de empresas [sbs_ovw_act](https://ec.europa.eu/eurostat/databrowser/view/sbs_ovw_act/default/table) (empresas, ocupados e valor engadido; euros correntes do ano, só para comparar países). Grandes construtoras: [Deloitte, Global Powers of Construction](https://www.deloitte.com/es/es/Industries/energy/perspectives/deloitte-global-powers-of-construction.html), cifras citadas con fonte (ingresos en millóns de dólares correntes, só os que dá a fonte).
- **Comunidades:** Eurostat, VEB rexional [nama_10r_3gva](https://ec.europa.eu/eurostat/databrowser/view/nama_10r_3gva/default/table), que reproduce a Contabilidade Rexional do INE.
- **Euros constantes:** IPC do INE (euros de {lic_res[0]?.anio_base}); entre 1996 e 2001, enlazado co IPCA de España de Eurostat ([prc_hicp_aind](https://ec.europa.eu/eurostat/databrowser/view/prc_hicp_aind/default/table)). Antes de 1996 non se dan cifras en euros. Poboación do INE (comunidades) e de Eurostat (España e UE).
