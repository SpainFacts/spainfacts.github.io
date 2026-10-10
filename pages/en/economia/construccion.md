---
title: Construction
description: "Construction in Spain compared with the EU: share of value added and employment since 1995, the 2007 bubble and the collapse, public works tendered in real euros per inhabitant and by governing party, housing permits, cement, output, costs, companies and regions."
i18n_origen: 9b8936d58932
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    const MESES_EN = { enero: 'January', febrero: 'February', marzo: 'March', abril: 'April', mayo: 'May', junio: 'June', julio: 'July', agosto: 'August', septiembre: 'September', octubre: 'October', noviembre: 'November', diciembre: 'December' };
    const mesEn = (s) => s ? s.replace(/^(\w+) de (\d{4})$/, (m, mes, a) => (MESES_EN[mes] ?? mes) + ' ' + a) : '';
    const trimEn = (s) => s ? s.replace(/^(\d)\.º trimestre de (\d{4})$/, 'Q$1 $2') : '';
    const decEn = (s) => s ? s.replace(/(\d),(\d)/g, '$1.$2') : '';
    const estadoDatoEn = (s) => ({ 'dato provisional': 'provisional data', 'dato definitivo': 'final data' })[s] ?? s ?? '';
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
    '/en' || t.ruta AS ruta,
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
    '/en' || t.ruta AS ruta,
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
    '/en' || t.ruta AS ruta,
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

# 🏗️ Construction

Construction was first the engine and then the dead weight of the Spanish economy. In {peso_res[0]?.anio_vab_max} it came to generate **{formatNumber(peso_res[0]?.es_vab_max, 1)} % of Spain's value added**, compared with an EU average of {formatNumber(peso_res[0]?.ue_vab_anio_max, 1)} %, and in 2007 it employed {formatNumber(peso_res[0]?.ocup_2007_mill, 2)} million people, {formatNumber(peso_res[0]?.es_emp_2007, 1)} % of everyone in work. After the bubble burst, the sector's real activity fell to {formatNumber(peso_res[0]?.es_vol_min, 0)} % of its 2007 level in {peso_res[0]?.anio_vol_min}. In {peso_res[0]?.anio} it accounts for {formatNumber(peso_res[0]?.es_vab, 1)} % (EU: {formatNumber(peso_res[0]?.ue_vab, 1)} %) and Spain ranks {peso_res[0]?.puesto} of {peso_res[0]?.n_paises} EU countries. Figures are **per inhabitant** and, those in euros, **adjusted for inflation** ({lic_res[0]?.anio_base} euros). The homes started and completed each year are covered in [New construction](/en/vivienda/construccion).

<Grid cols=4>
    <KpiCard
        title="Share of value added"
        value={peso_res[0]?.es_vab}
        formattedValue="{formatNumber(peso_res[0]?.es_vab, 1)} %"
        period="{peso_res[0]?.anio} · EU-27: {formatNumber(peso_res[0]?.ue_vab, 1)} % · rank {peso_res[0]?.puesto} of {peso_res[0]?.n_paises}"
        change={(peso_res[0]?.es_vab - peso_res[0]?.es_vab_2007)?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs 2007"
        direction="neutral"
        source="Eurostat (nama_10_a10)"
        sparklineData={peso_es.map(d => ({...d, y: d.pct_vab_construccion}))}
    />
    <KpiCard
        title="Employed per 1,000 inhabitants"
        value={epa_res[0]?.ocup_1000}
        formattedValue="{formatNumber(epa_res[0]?.ocup_1000, 1)}"
        period="{trimEn(epa_res[0]?.etiqueta)} · {formatNumber(epa_res[0]?.ocup_mill, 2)} million · EU-27 ({peso_res[0]?.anio}): {formatNumber(peso_res[0]?.ue_ocup_1000, 1)}"
        change={(epa_res[0]?.ocup_1000 - epa_res[0]?.ocup_1000_hace_un_anio)?.toFixed(1)}
        changeUnit=""
        changePeriod="vs a year earlier"
        direction="positive-up"
        source="INE (LFS)"
        sparklineData={epa.map(d => ({...d, y: d.ocupados_constr_1000hab}))}
    />
    <KpiCard
        title="Public tenders per inhabitant"
        value={lic_res[0]?.total}
        formattedValue="{formatNumber(lic_res[0]?.total, 0)} €"
        period="{lic_res[0]?.anio}, {lic_res[0]?.anio_base} euros · {formatNumber(lic_res[0]?.total_mm, 1)} billion in total · {estadoDatoEn(lic_res[0]?.estado_dato)}"
        change={lic_res[0]?.var_2007?.toFixed(0)}
        changeUnit="%"
        changePeriod="vs 2007"
        direction="neutral"
        source="Ministry of Transport"
        sparklineData={lic.map(d => ({...d, y: d.total_hab_real}))}
    />
    <KpiCard
        title="Homes approved per 1,000 inhab."
        value={visados_res[0]?.ult}
        formattedValue="{formatNumber(visados_res[0]?.ult, 2)}"
        period="{visados_res[0]?.anio} · new build · {formatNumber(visados_res[0]?.ult_miles, 0)} thousand homes · peak: {formatNumber(visados_res[0]?.max_1000, 1)} in {visados_res[0]?.anio_max}"
        change={visados_res[0]?.var_anual?.toFixed(1)}
        changeUnit="%"
        changePeriod="vs previous year"
        direction="neutral"
        source="Associations of quantity surveyors (BdE)"
        sparklineData={visados.map(d => ({...d, y: d.viviendas_nueva_1000hab}))}
    />
</Grid>

## The boom and the bust

In 1995 construction already weighed more in Spain than in the EU ({formatNumber(peso_res[0]?.es_vab_1995, 1)} % of value added compared with {formatNumber(peso_res[0]?.ue_vab_1995, 1)} %). In 2007 {#if peso_res[0]?.puesto_2007 == 1}it was the country of the 27 where it weighed most{:else}it ranked {peso_res[0]?.puesto_2007} of the 27{/if} and accounted for {formatNumber(peso_res[0]?.es_emp_2007, 1)} % of employment, compared with {formatNumber(peso_res[0]?.ue_emp_2007, 1)} % in Europe. The lowest share since then was in {peso_res[0]?.anio_vab_min}, at {formatNumber(peso_res[0]?.es_vab_min, 1)} %. In {peso_res[0]?.anio}, with {formatNumber(peso_res[0]?.es_vab, 1)} % of value added and {formatNumber(peso_res[0]?.es_emp, 1)} % of employment (EU: {formatNumber(peso_res[0]?.ue_vab, 1)} % and {formatNumber(peso_res[0]?.ue_emp, 1)} %), Spain ranks {peso_res[0]?.puesto} of {peso_res[0]?.n_paises}.

<LineChart
    data={peso}
    x=anio
    y=pct_vab_construccion
    series=serie
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of gross value added"
    title="Construction's share of value added, % at current prices"
/>

<LineChart
    data={peso_es_ue}
    x=anio
    y=pct_empleo_construccion
    series=serie
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of people in employment"
    seriesColors={{'España': '#dc2626', 'UE-27': '#64748b'}}
    title="Construction's share of employment, % of people in employment"
/>

Without the effect of prices (in volume), the value added of Spanish construction in 1995 was {formatNumber(peso_res[0]?.es_vol_1995, 0)} % of its 2007 level; it bottomed out in {peso_res[0]?.anio_vol_min} at {formatNumber(peso_res[0]?.es_vol_min, 0)} % and in {peso_res[0]?.anio} it stands at {formatNumber(peso_res[0]?.es_vol, 0)} %. For the EU as a whole it is at {formatNumber(peso_res[0]?.ue_vol, 0)} % of 2007. Per inhabitant, the sector's value added went from {formatNumber(peso_res[0]?.es_vabhab_2007, 0)} € in 2007 to {formatNumber(peso_res[0]?.es_vabhab, 0)} € in {peso_res[0]?.anio}, in today's euros.

<LineChart
    data={peso}
    x=anio
    y=vab_constr_real_indice_2007
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="2007 = 100"
    title="Construction value added in volume (without the effect of prices), 2007 = 100"
/>

## Employment

According to the LFS, in {trimEn(epa_res[0]?.etiqueta)} **{formatNumber(epa_res[0]?.ocup_mill, 2)} million people** worked in construction, {formatNumber(epa_res[0]?.ocup_1000, 1)} per 1,000 inhabitants and {formatNumber(epa_res[0]?.pct, 1)} % of everyone in work. At the start of 2008 there were {formatNumber(epa_res[0]?.ocup_2008_mill, 2)} million ({formatNumber(epa_res[0]?.ocup_1000_2008, 1)} per 1,000 inhabitants); the low point of the series was {formatNumber(epa_res[0]?.ocup_1000_min, 1)} in {trimEn(epa_res[0]?.etiqueta_min)}. In 2007, using Eurostat's annual data, Spain had {formatNumber(peso_res[0]?.es_ocup_1000_2007, 1)} people employed in the sector per 1,000 inhabitants compared with {formatNumber(peso_res[0]?.ue_ocup_1000_2007, 1)} in the EU; in {peso_res[0]?.anio}, {formatNumber(peso_res[0]?.es_ocup_1000, 1)} compared with {formatNumber(peso_res[0]?.ue_ocup_1000, 1)}.

<LineChart
    data={epa}
    x=fecha
    y=ocupados_constr_1000hab
    yFmt='0.0'
    yAxisTitle="employed per 1,000 inhabitants"
    colorPalette={['#b45309']}
    title="People employed in construction per 1,000 inhabitants, by quarter (LFS)"
/>

The sector's unemployment rate, calculated with the unemployed who left a construction job less than a year ago, went from {formatNumber(epa_res[0]?.paro_2008, 1)} % at the start of 2008 to a peak of {formatNumber(epa_res[0]?.paro_max, 1)} % in {trimEn(epa_res[0]?.etiqueta_paro_max)}; in {trimEn(epa_res[0]?.etiqueta)} it is {formatNumber(epa_res[0]?.paro, 1)} %.

<LineChart
    data={epa}
    x=fecha
    y=tasa_paro_constr
    yFmt='0.0"%"'
    yAxisTitle="% of the sector's labour force"
    colorPalette={['#dc2626']}
    title="Approximate unemployment rate in construction, by quarter (LFS)"
/>

In the Social Security system, construction had an average of **{formatNumber(afil_res[0]?.afil_mill, 2)} million registered workers** in {mesEn(afil_res[0]?.mes_ultimo)} ({formatNumber(afil_res[0]?.afil_1000, 1)} per 1,000 inhabitants and {formatNumber(afil_res[0]?.pct, 1)} % of all registered workers), {#if afil_res[0]?.var_anual >= 0}{formatNumber(afil_res[0]?.var_anual, 1)} % more{:else}{formatNumber(-afil_res[0]?.var_anual, 1)} % fewer{/if} than a year earlier. {formatNumber(afil_res[0]?.pct_aut, 1)} % are self-employed, compared with {formatNumber(afil_res[0]?.pct_aut_2021, 1)} % in January 2021. Since January 2026 the Social Security system classifies using the new CNAE-2025, which may cause small jumps.

<LineChart
    data={afil}
    x=fecha
    y=afiliados_constr_1000hab
    yFmt='0.0'
    yAxisTitle="registered workers per 1,000 inhabitants"
    colorPalette={['#b45309']}
    title="Social Security registered workers in construction per 1,000 inhabitants, monthly average"
/>

<LineChart
    data={afil}
    x=fecha
    y=pct_autonomos_constr
    yFmt='0.0"%"'
    yAxisTitle="% of the sector's registered workers"
    colorPalette={['#7c3aed']}
    title="Self-employed in construction, % of the sector's registered workers"
/>

## Public works

Official tendering is the budget of the works that administrations put out to tender (including VAT). In {lic_res[0]?.anio} it came to **{formatNumber(lic_res[0]?.total, 0)} € per inhabitant** in {lic_res[0]?.anio_base} euros: {formatNumber(lic_res[0]?.estado, 0)} € from central government (including its public entities, such as Adif, Aena or the Port Authorities, which contribute {formatNumber(lic_res[0]?.epe, 0)} €) and {formatNumber(lic_res[0]?.entes, 0)} € from the «territorial bodies», which in this statistic combine regional governments and town councils without separating them. {formatNumber(lic_res[0]?.pct_obra_civil, 0)} % was civil engineering and the rest building. The highest figure since {lic_res[0]?.anio_ini} was {formatNumber(lic_res[0]?.total_max, 0)} € in {lic_res[0]?.anio_max} and the lowest, {formatNumber(lic_res[0]?.total_min, 0)} € in {lic_res[0]?.anio_min}.

{#if lic_res[0]?.hay_provisional}
<p>Data from {lic_res[0]?.anio_prov} onwards are <strong>provisional</strong>.</p>
{/if}

<BarChart
    data={lic_agentes}
    x=anio
    y=eur_hab
    series=agente
    type=stacked
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per inhabitant (today's euros)"
    seriesColors={{'Estado (con Adif, Aena, Puertos...)': '#b45309', 'Comunidades y ayuntamientos': '#0d9488'}}
    title="Official public works tendering per inhabitant, constant euros"
/>

Central government's share depends on the Spanish Government. Each bar is coloured by the party in government on 1 July of that year; this is a description, not an explanation: each period coincides with a different phase of the economic cycle. Under PP governments ({lic_partidos.filter(d => d.partido === 'PP')[0]?.n_anios} years of the series) central government tendering averaged {formatNumber(lic_partidos.filter(d => d.partido === 'PP')[0]?.estado_media, 0)} € per inhabitant per year, and under PSOE governments ({lic_partidos.filter(d => d.partido === 'PSOE')[0]?.n_anios} years), {formatNumber(lic_partidos.filter(d => d.partido === 'PSOE')[0]?.estado_media, 0)} €. The highest was {formatNumber(lic_res[0]?.estado_max, 0)} € per inhabitant in {lic_res[0]?.anio_estado_max} and the lowest, {formatNumber(lic_res[0]?.estado_min, 0)} € in {lic_res[0]?.anio_estado_min}.

<BarChart
    data={lic}
    x=anio
    y=estado_hab_real
    series=familia_estatal
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per inhabitant (today's euros)"
    seriesColors={{'PSOE': '#e30613', 'PP': '#1d84ce'}}
    title="Central government tendering per inhabitant and party of the Spanish Government on 1 July, constant euros"
/>

<DataTable data={lic_presidentes} rows=10>
    <Column id=presidente title="Prime minister" />
    <Column id=partido title="Party" />
    <Column id=anios title="Years" />
    <Column id=n_anios title="No. of years" fmt='0' />
    <Column id=estado_media title="Central government, € per inhab. per year" fmt='#,##0' contentType=bar barColor='#b45309' />
    <Column id=entes_media title="Regions and town councils, € per inhab. per year" fmt='#,##0' />
    <Column id=total_media title="Total, € per inhab. per year" fmt='#,##0' />
</DataTable>

By region, in {lic_ccaa[0]?.anio} those receiving the most tendering per inhabitant were {lic_ccaa_res[0]?.mas}, and those receiving the least, {lic_ccaa_res[0]?.menos}. {formatNumber(lic_ccaa_res[0]?.pct_nr, 1)} % of the total for Spain cannot be assigned to any region (works spanning several) and does not appear on the map. The party column is that of the regional government, but territorial tendering mixes the region's with that of its town councils.

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
        {id: 'total_hab_real', title: 'Total, € per inhab.', fmt: '#,##0'},
        {id: 'estado_hab_real', title: 'Central government, € per inhab.', fmt: '#,##0'},
        {id: 'entes_territoriales_hab_real', title: 'Region and town councils, € per inhab.', fmt: '#,##0'},
        {id: 'media_5', title: '5-year average, € per inhab.', fmt: '#,##0'}
    ]}
/>

<DataTable data={lic_ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=total_hab_real title="Total, € per inhab." fmt='#,##0' contentType=bar barColor='#14b8a6' />
    <Column id=estado_hab_real title="Central government" fmt='#,##0' />
    <Column id=entes_territoriales_hab_real title="Region and town councils" fmt='#,##0' />
    <Column id=media_5 title="5-year average" fmt='#,##0' />
    <Column id=familia_autonomica title="Party of the regional government" />
    <Column id=anio title="Year" fmt='0' />
</DataTable>

## How much is built

In {visados_res[0]?.anio} the associations of quantity surveyors approved projects for **{formatNumber(visados_res[0]?.ult, 2)} new-build homes per 1,000 inhabitants** ({formatNumber(visados_res[0]?.ult_miles, 0)} thousand). In {visados_res[0]?.anio_max}, at the height of the bubble, there were {formatNumber(visados_res[0]?.max_1000, 1)} per 1,000 ({formatNumber(visados_res[0]?.max_miles, 0)} thousand homes); in {visados_res[0]?.anio_min}, just {formatNumber(visados_res[0]?.min_1000, 2)}. The floor area to be built went from a peak of {formatNumber(visados_res[0]?.m2_max, 2)} m² per inhabitant to {formatNumber(visados_res[0]?.m2_ult, 2)} m².

<BarChart
    data={visados}
    x=anio
    y=viviendas_nueva_1000hab
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="homes per 1,000 inhabitants"
    fillColor='#b45309'
    title="New-build homes approved per 1,000 inhabitants in Spain"
/>

By region, in {visados_ccaa[0]?.anio} the most new homes per inhabitant were approved in {visados_ccaa_res[0]?.mas} and the fewest in {visados_ccaa_res[0]?.menos} (from {formatNumber(visados_ccaa_res[0]?.max_1000, 1)} to {formatNumber(visados_ccaa_res[0]?.min_1000, 1)} per 1,000 inhabitants). The statistic does not include Ceuta or Melilla.

<BarChart
    data={visados_ccaa}
    x=comunidad
    y=viviendas_nueva_1000hab
    swapXY=true
    yFmt='0.0'
    yAxisTitle="homes per 1,000 inhabitants"
    fillColor='#b45309'
    title="New-build homes approved per 1,000 inhabitants by region, latest year"
/>

<DataTable data={visados_ccaa} rows=17 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=viviendas_nueva_1000hab title="New build per 1,000 inhab." fmt='0.00' contentType=bar barColor='#b45309' />
    <Column id=media_2004_2007 title="2004-2007 average" fmt='0.00' />
    <Column id=viviendas_reforma_1000hab title="Renovation per 1,000 inhab." fmt='0.00' />
    <Column id=viviendas_nueva title="Homes (total)" fmt='#,##0' />
    <Column id=anio title="Year" fmt='0' />
</DataTable>

To compare with Europe, Eurostat's **building permits** have to be used, which are not the same as the surveyors' approvals: for Spain, Eurostat gives {formatNumber(permisos_res[0]?.es_miles, 0)} thousand homes with permits in {permisos_res[0]?.anio}, compared with {formatNumber(permisos_res[0]?.visados_miles, 0)} thousand approved, because the INE sends it a different source (municipal licences). The two series cannot be mixed. Using permits, in {permisos_res[0]?.anio} Spain ranked {permisos_res[0]?.puesto} of {permisos_res[0]?.n} countries, with {formatNumber(permisos_res[0]?.es, 1)} homes per 1,000 inhabitants compared with {formatNumber(permisos_res[0]?.ue, 1)} in the EU.

<LineChart
    data={permisos_ue}
    x=anio
    y=viviendas_nueva_1000hab
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="homes with permits per 1,000 inhab."
    title="Homes with building permits per 1,000 inhabitants (Eurostat)"
/>

Cement gives another measure of activity. In {cemento_res[0]?.anio_max} Spain consumed **{formatNumber(cemento_res[0]?.max_kg, 0)} kg per inhabitant**; in {cemento_res[0]?.anio_min}, {formatNumber(cemento_res[0]?.min_kg, 0)} kg, and in {cemento_res[0]?.anio}, {formatNumber(cemento_res[0]?.ult, 0)} kg (in {cemento_res[0]?.anio_ini} it was {formatNumber(cemento_res[0]?.kg_1995, 0)}). {formatNumber(cemento_res[0]?.pct_export, 0)} % of output was exported.

<LineChart
    data={cemento_largo}
    x=anio
    y=kg_hab
    series=serie
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kg per inhabitant"
    seriesColors={{'Consumo aparente': '#78716c', 'Producción': '#b45309'}}
    title="Cement in Spain: apparent consumption and production, kg per inhabitant"
/>

## Output and costs

Eurostat's construction production index measures activity in volume. In 2024 Spain's stood at {formatNumber(prod_res[0]?.f_2024, 0)} % of its 2007 level (EU: {formatNumber(prod_res[0]?.ue_2024, 0)} %); the low point was {formatNumber(prod_res[0]?.f_min, 0)} % in {prod_res[0]?.anio_f_min}. By branch, in {prod_res[0]?.anio} building stood at {formatNumber(prod_res[0]?.f41_ult, 0)} % of 2007 and civil engineering at {formatNumber(prod_res[0]?.f42_ult, 0)} %.

{#if prod_res[0]?.hay_salto}
<p><strong>Beware of {prod_res[0]?.anio}:</strong> the total rises by {formatNumber(prod_res[0]?.f_var, 1)} % and specialised construction by {formatNumber(prod_res[0]?.f43_var, 1)} %, while building changes by {formatNumber(prod_res[0]?.f41_var, 1)} % and civil engineering by {formatNumber(prod_res[0]?.f42_var, 1)} %. That jump looks like a break in the series and should not be read as a boom.</p>
{/if}

<LineChart
    data={prod}
    x=anio
    y=indice_2007
    series=rama_nombre
    xFmt='0'
    yFmt='0'
    yAxisTitle="2007 = 100"
    title="Construction output in Spain by branch, 2007 = 100 (the latest year for the total and specialised construction is doubtful)"
/>

<LineChart
    data={prod_es_ue}
    x=anio
    y=indice_2007
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="2007 = 100"
    title="Construction output (total), 2007 = 100"
/>

Building a new home (materials and labour) cost an index of {formatNumber(costes_res[0]?.es_nom, 1)} in {costes_res[0]?.anio} (2021 = 100), compared with {formatNumber(costes_res[0]?.es_nom_2020, 1)} in 2020. Adjusted for general inflation, the index stands at {formatNumber(costes_res[0]?.es_real, 1)}: above 100 means building has become more expensive than other prices since 2021. The real peak was {formatNumber(costes_res[0]?.es_real_max, 1)} in {costes_res[0]?.anio_real_max}. Spain does not publish its own cost index on Eurostat: its cost series is the same as the output price series. In the EU, the output price of new housing stood at {formatNumber(costes_res[0]?.ue_precio, 1)} in {costes_res[0]?.anio_ue}.

<LineChart
    data={costes}
    x=anio
    y=indice
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="2021 = 100"
    seriesColors={{'Coste nominal': '#b45309', 'Coste descontada la inflación': '#0d9488', 'UE-27, precio de producción nominal': '#64748b'}}
    title="Construction costs of new housing in Spain, 2021 = 100"
/>

## The companies

In {empresas_res[0]?.anio} Spain had {formatNumber(empresas_res[0]?.es_emp, 1)} construction companies per 1,000 inhabitants (EU: {formatNumber(empresas_res[0]?.ue_emp, 1)}; rank {empresas_res[0]?.puesto} of {empresas_res[0]?.n}), with an average of {formatNumber(empresas_res[0]?.es_tam, 1)} people employed in each (EU: {formatNumber(empresas_res[0]?.ue_tam, 1)}). Each person employed generated {formatNumber(empresas_res[0]?.es_prod, 1)} thousand euros of value added, {formatNumber(empresas_res[0]?.pct_prod_ue, 0)} % of the EU average ({formatNumber(empresas_res[0]?.ue_prod, 1)} thousand); in Germany, {formatNumber(empresas_res[0]?.de_prod, 1)} thousand; in France, {formatNumber(empresas_res[0]?.fr_prod, 1)}, and in Italy, {formatNumber(empresas_res[0]?.it_prod, 1)}.

<BarChart
    data={empresas_productividad}
    x=serie
    y=productividad_miles_eur
    series=grupo
    swapXY=true
    sort=false
    yFmt='#,##0'
    yAxisTitle="thousand € per person employed (current euros)"
    seriesColors={{'España': '#dc2626', 'UE-27': '#64748b', 'Otros países': '#93c5fd'}}
    title="Construction productivity: value added per person employed, latest year"
/>

<DataTable data={empresas_ramas} rows=4>
    <Column id=rama title="Branch" />
    <Column id=es_empresas title="Companies per 1,000 inhab., Spain" fmt='0.00' />
    <Column id=ue_empresas title="EU" fmt='0.00' />
    <Column id=puesto_empresas title="Spain's rank" fmt='0' />
    <Column id=es_tamano title="Employed per company, Spain" fmt='0.0' />
    <Column id=ue_tamano title="EU" fmt='0.0' />
    <Column id=es_productividad title="Thousand € per person employed, Spain" fmt='0.0' />
    <Column id=ue_productividad title="EU" fmt='0.0' />
</DataTable>

Spain also has some of the world's largest construction companies. Deloitte's Global Powers of Construction {constructoras_res[0]?.edicion} ranking includes {constructoras_res[0]?.n} Spanish groups among the world's 100 largest listed construction companies by revenue, {constructoras_res[0]?.n_top50} of them in the top 50; the highest placed is {constructoras_res[0]?.primera} (number {constructoras_res[0]?.puesto_primera} in the world), which earns {formatNumber(constructoras_res[0]?.pct_exterior_primera, 1)} % of its sales outside Spain.

<DataTable data={constructoras} rows=10>
    <Column id=puesto title="World rank" fmt='0' />
    <Column id=empresa title="Company" />
    <Column id=ingresos_mill_usd title="Revenue ($ million)" fmt='#,##0' />
    <Column id=pct_ventas_exterior title="% of sales outside Spain" fmt='0.0' />
    <Column id=edicion title="Edition" fmt='0' />
</DataTable>

## By region

In {ccaa_res[0]?.anio} construction generated {formatNumber(ccaa_res[0]?.es, 1)} % of Spain's value added ({formatNumber(ccaa_res[0]?.es_2007, 1)} % in 2007), {formatNumber(ccaa_res[0]?.es_hab, 0)} € per inhabitant in today's euros. It weighs most in {decEn(ccaa_res[0]?.mas)}, and least in {ccaa_res[0]?.menos}. {#if ccaa_res[0]?.n_debajo == ccaa_res[0]?.n}All regions weigh less today than in 2007{:else}{ccaa_res[0]?.n_debajo} of the {ccaa_res[0]?.n} regions weigh less today than in 2007{/if}; the biggest fall is in {ccaa_res[0]?.mas_caida}, which has gone from {formatNumber(ccaa_res[0]?.mas_caida_2007, 1)} % to {formatNumber(ccaa_res[0]?.mas_caida_ult, 1)} % ({formatNumber(ccaa_res[0]?.caida_max, 1)} points).

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
        {id: 'pct_vab_construccion', title: 'Construction, % of GVA', fmt: '0.0'},
        {id: 'pct_vab_2007', title: '% of GVA in 2007', fmt: '0.0'},
        {id: 'dif_pp_vs_2007', title: 'Difference from 2007 (points)', fmt: '0.0'},
        {id: 'vab_constr_hab_real', title: "Sector GVA per inhab. (today's euros)", fmt: '#,##0'}
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
        {id: 'dif_pp_vs_2007', title: 'Difference from 2007 (GVA points)', fmt: '0.0'},
        {id: 'pct_vab_2007', title: '% of GVA in 2007', fmt: '0.0'},
        {id: 'pct_vab_construccion', title: '% of GVA today', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=pct_vab_construccion title="% of GVA" fmt='0.0' contentType=bar barColor='#f59e0b' />
    <Column id=pct_vab_2007 title="% in 2007" fmt='0.0' />
    <Column id=dif_pp_vs_2007 title="Difference (points)" fmt='0.0' />
    <Column id=vab_constr_hab_real title="€ per inhab. (today's euros)" fmt='#,##0' />
    <Column id=ocupados_constr_1000hab_epa title="Employed per 1,000 inhab. (LFS)" fmt='0.0' />
    <Column id=anio title="Year" fmt='0' />
</DataTable>

## Methodology and sources

- **Share of the economy and comparison with the EU:** Eurostat, national accounts by industry [nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table) (GVA at current prices and in chain-linked volumes) and [nama_10_a10_e](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10_e/default/table) (employment); population, [nama_10_pe](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe/default/table). Construction = NACE section F.
- **Employment:** INE, Labour Force Survey (EPA), people employed by sector and province ([table 65354](https://www.ine.es/jaxiT3/Tabla.htm?t=65354)) and unemployed by sector of last job ([table 65331](https://www.ine.es/jaxiT3/Tabla.htm?t=65331)), CNAE-2009, since 2008. The sector's unemployment rate is an approximation: the unemployed who left their job more than a year ago have no sector. Registered workers: [Social Security, average registered workers by activity](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST8) (General Scheme and Self-employed).
- **Official tendering:** Ministry of Transport and Sustainable Mobility, [official construction tendering](https://www.transportes.gob.es/informacion-para-el-ciudadano/informacion-estadistica/construccion/licitacion-oficial-en-construccion), by region via [ISTAC](https://datos.canarias.es/api/estadisticas/) (E20004A_000001); the share of state public entities, from the [Banco de España, Statistical Bulletin, table 23.9](https://www.bde.es/webbe/es/estadisticas/compartido/datos/pdf/be2309.pdf). Budget including VAT in the year of tender. «Territorial bodies» = regional governments + local authorities (the open source does not separate them). Party of the Government on 1 July of each year.
- **Approvals:** site management approvals (visados) from the associations of quantity surveyors (Ministry of Transport), by region via ISTAC (E20006A_000002) since 2000 and for Spain since 1992 in the [Banco de España, table 23.8](https://www.bde.es/webbe/es/estadisticas/compartido/datos/pdf/be2308.pdf). **Permits:** Eurostat [sts_cobp_a](https://ec.europa.eu/eurostat/databrowser/view/sts_cobp_a/default/table) (dwellings in residential buildings excluding communal residences); they are not comparable with the approvals.
- **Cement:** [Banco de España, table 23.11](https://www.bde.es/webbe/es/estadisticas/compartido/datos/pdf/be2311.pdf) (data from Oficemen and the Ministry of Industry). Apparent consumption = production + imports − exports; full years only.
- **Output and costs:** Eurostat [sts_copr_a](https://ec.europa.eu/eurostat/databrowser/view/sts_copr_a/default/table) (production index, calendar adjusted, 2021 = 100, rebased to 2007 = 100) and [sts_copi_a](https://ec.europa.eu/eurostat/databrowser/view/sts_copi_a/default/table) (construction costs and output prices of new housing). The 2025 jump in the total and in specialised construction for Spain is treated as a possible break in the series.
- **Companies:** Eurostat, structural business statistics [sbs_ovw_act](https://ec.europa.eu/eurostat/databrowser/view/sbs_ovw_act/default/table) (enterprises, persons employed and value added; current euros of the year, for comparing countries only). Large construction companies: [Deloitte, Global Powers of Construction](https://www.deloitte.com/es/es/Industries/energy/perspectives/deloitte-global-powers-of-construction.html), figures cited with source (revenue in millions of current dollars, only those given by the source).
- **Regions:** Eurostat, regional GVA [nama_10r_3gva](https://ec.europa.eu/eurostat/databrowser/view/nama_10r_3gva/default/table), which reproduces the INE's Regional Accounts.
- **Constant euros:** INE CPI ({lic_res[0]?.anio_base} euros); between 1996 and 2001, linked with Eurostat's HICP for Spain ([prc_hicp_aind](https://ec.europa.eu/eurostat/databrowser/view/prc_hicp_aind/default/table)). No figures in euros are given before 1996. Population from the INE (regions) and Eurostat (Spain and EU).
