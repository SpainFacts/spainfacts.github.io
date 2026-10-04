---
title: Construcció
description: "La construcció a Espanya davant la UE: pes en el valor afegit i en l'ocupació des del 1995, la bombolla del 2007 i l'enfonsament, licitació d'obra pública en euros reals per habitant i partit del Govern, habitatges visats, ciment, producció, costos, empreses i comunitats."
i18n_origen: 60f03001a5e1
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';

    const MESOS_CA = { enero: 'gener', febrero: 'febrer', marzo: 'març', abril: 'abril', mayo: 'maig', junio: 'juny', julio: 'juliol', agosto: 'agost', septiembre: 'setembre', octubre: 'octubre', noviembre: 'novembre', diciembre: 'desembre' };
    function mesCa(t, article = false) {
        const m = (t ?? '').match(/^(\S+) de (\d{4})$/);
        if (!m) return t;
        const mes = MESOS_CA[m[1]] ?? m[1];
        const art = article ? (/^[aeiou]/.test(mes) ? "l'" : 'el ') : '';
        return `${art}${mes} del ${m[2]}`;
    }
    function ordM(n) {
        if (n === null || n === undefined) return n;
        const k = Number(n);
        return k + (k === 1 || k === 3 ? 'r' : k === 2 ? 'n' : k === 4 ? 't' : 'è');
    }
    function trimCa(t) {
        const m = (t ?? '').match(/^(\d)\.º trimestre de (\d{4})$/);
        return m ? `${ordM(m[1])} trimestre del ${m[2]}` : t;
    }
    const ESTAT_DADA = { 'dato provisional': 'dada provisional', 'dato definitivo': 'dada definitiva' };
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
    '/ca' || t.ruta AS ruta,
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
    '/ca' || t.ruta AS ruta,
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
    '/ca' || t.ruta AS ruta,
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


# 🏗️ Construcció

La construcció va ser el motor i després el llast de l'economia espanyola. El {peso_res[0]?.anio_vab_max} va arribar a generar el **{formatNumber(peso_res[0]?.es_vab_max, 1)} % del valor afegit** d'Espanya, davant el {formatNumber(peso_res[0]?.ue_vab_anio_max, 1)} % de mitjana a la UE, i el 2007 donava feina a {formatNumber(peso_res[0]?.ocup_2007_mill, 2)} milions de persones, el {formatNumber(peso_res[0]?.es_emp_2007, 1)} % dels ocupats. Després de l'esclat de la bombolla, l'activitat real del sector va caure fins al {formatNumber(peso_res[0]?.es_vol_min, 0)} % de la del 2007 el {peso_res[0]?.anio_vol_min}. El {peso_res[0]?.anio} pesa el {formatNumber(peso_res[0]?.es_vab, 1)} % (UE: {formatNumber(peso_res[0]?.ue_vab, 1)} %) i Espanya ocupa el lloc {peso_res[0]?.puesto} de {peso_res[0]?.n_paises} països de la UE. Les xifres van **per habitant** i, les d'euros, **descomptada la inflació** (euros del {lic_res[0]?.anio_base}). L'habitatge que es comença i s'acaba cada any és a [Obra nova](/ca/vivienda/construccion).

<Grid cols=4>
    <KpiCard
        title="Pes en el valor afegit"
        value={peso_res[0]?.es_vab}
        formattedValue="{formatNumber(peso_res[0]?.es_vab, 1)} %"
        period="{peso_res[0]?.anio} · UE-27: {formatNumber(peso_res[0]?.ue_vab, 1)} % · lloc {peso_res[0]?.puesto} de {peso_res[0]?.n_paises}"
        change={(peso_res[0]?.es_vab - peso_res[0]?.es_vab_2007)?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs 2007"
        direction="neutral"
        source="Eurostat (nama_10_a10)"
        sparklineData={peso_es.map(d => d.pct_vab_construccion)}
    />
    <KpiCard
        title="Ocupats per 1.000 habitants"
        value={epa_res[0]?.ocup_1000}
        formattedValue="{formatNumber(epa_res[0]?.ocup_1000, 1)}"
        period="{trimCa(epa_res[0]?.etiqueta)} · {formatNumber(epa_res[0]?.ocup_mill, 2)} milions · UE-27 ({peso_res[0]?.anio}): {formatNumber(peso_res[0]?.ue_ocup_1000, 1)}"
        change={(epa_res[0]?.ocup_1000 - epa_res[0]?.ocup_1000_hace_un_anio)?.toFixed(1)}
        changeUnit=""
        changePeriod="vs fa un any"
        direction="positive-up"
        source="INE (EPA)"
        sparklineData={epa.map(d => d.ocupados_constr_1000hab)}
    />
    <KpiCard
        title="Licitació pública per habitant"
        value={lic_res[0]?.total}
        formattedValue="{formatNumber(lic_res[0]?.total, 0)} €"
        period="{lic_res[0]?.anio}, euros del {lic_res[0]?.anio_base} · {formatNumber(lic_res[0]?.total_mm, 1)} mil milions en total · {ESTAT_DADA[lic_res[0]?.estado_dato] ?? lic_res[0]?.estado_dato}"
        change={lic_res[0]?.var_2007?.toFixed(0)}
        changeUnit="%"
        changePeriod="vs 2007"
        direction="neutral"
        source="Ministeri de Transports"
        sparklineData={lic.map(d => d.total_hab_real)}
    />
    <KpiCard
        title="Habitatges visats per 1.000 hab."
        value={visados_res[0]?.ult}
        formattedValue="{formatNumber(visados_res[0]?.ult, 2)}"
        period="{visados_res[0]?.anio} · obra nova · {formatNumber(visados_res[0]?.ult_miles, 0)} mil habitatges · màxim: {formatNumber(visados_res[0]?.max_1000, 1)} el {visados_res[0]?.anio_max}"
        change={visados_res[0]?.var_anual?.toFixed(1)}
        changeUnit="%"
        changePeriod="vs any anterior"
        direction="neutral"
        source="Col·legis d'aparelladors (BdE)"
        sparklineData={visados.map(d => d.viviendas_nueva_1000hab)}
    />
</Grid>

## L'auge i la caiguda

El 1995 la construcció ja pesava més a Espanya que a la UE ({formatNumber(peso_res[0]?.es_vab_1995, 1)} % del valor afegit davant el {formatNumber(peso_res[0]?.ue_vab_1995, 1)} %). El 2007 {#if peso_res[0]?.puesto_2007 == 1}era el país dels 27 on més pesava{:else}era el {ordM(peso_res[0]?.puesto_2007)} dels 27{/if} i concentrava el {formatNumber(peso_res[0]?.es_emp_2007, 1)} % de l'ocupació, davant el {formatNumber(peso_res[0]?.ue_emp_2007, 1)} % europeu. El pes més baix des de llavors va ser el del {peso_res[0]?.anio_vab_min}, el {formatNumber(peso_res[0]?.es_vab_min, 1)} %. El {peso_res[0]?.anio}, amb el {formatNumber(peso_res[0]?.es_vab, 1)} % del valor afegit i el {formatNumber(peso_res[0]?.es_emp, 1)} % de l'ocupació (UE: {formatNumber(peso_res[0]?.ue_vab, 1)} % i {formatNumber(peso_res[0]?.ue_emp, 1)} %), Espanya és la {peso_res[0]?.puesto}a de {peso_res[0]?.n_paises}.

<LineChart
    data={peso}
    x=anio
    y=pct_vab_construccion
    series=serie
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% del valor afegit brut"
    title="Pes de la construcció en el valor afegit, % a preus corrents"
/>

<LineChart
    data={peso_es_ue}
    x=anio
    y=pct_empleo_construccion
    series=serie
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% dels ocupats"
    seriesColors={{'España': '#dc2626', 'UE-27': '#64748b'}}
    title="Pes de la construcció en l'ocupació, % dels ocupats"
/>

Sense l'efecte dels preus (en volum), el valor afegit de la construcció espanyola era el 1995 el {formatNumber(peso_res[0]?.es_vol_1995, 0)} % del del 2007; va tocar fons el {peso_res[0]?.anio_vol_min} amb el {formatNumber(peso_res[0]?.es_vol_min, 0)} % i el {peso_res[0]?.anio} és al {formatNumber(peso_res[0]?.es_vol, 0)} %. En el conjunt de la UE és al {formatNumber(peso_res[0]?.ue_vol, 0)} % del 2007. Per habitant, el valor afegit del sector va passar de {formatNumber(peso_res[0]?.es_vabhab_2007, 0)} € el 2007 a {formatNumber(peso_res[0]?.es_vabhab, 0)} € el {peso_res[0]?.anio}, en euros d'avui.

<LineChart
    data={peso}
    x=anio
    y=vab_constr_real_indice_2007
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="2007 = 100"
    title="Valor afegit de la construcció en volum (sense efecte dels preus), 2007 = 100"
/>

## Ocupació

Segons l'EPA, el {trimCa(epa_res[0]?.etiqueta)} treballaven en la construcció **{formatNumber(epa_res[0]?.ocup_mill, 2)} milions de persones**, {formatNumber(epa_res[0]?.ocup_1000, 1)} per cada 1.000 habitants i el {formatNumber(epa_res[0]?.pct, 1)} % dels ocupats. A començament del 2008 eren {formatNumber(epa_res[0]?.ocup_2008_mill, 2)} milions ({formatNumber(epa_res[0]?.ocup_1000_2008, 1)} per 1.000 habitants); el mínim de la sèrie va ser {formatNumber(epa_res[0]?.ocup_1000_min, 1)} el {trimCa(epa_res[0]?.etiqueta_min)}. El 2007, amb les dades anuals d'Eurostat, Espanya tenia {formatNumber(peso_res[0]?.es_ocup_1000_2007, 1)} ocupats en el sector per 1.000 habitants davant {formatNumber(peso_res[0]?.ue_ocup_1000_2007, 1)} a la UE; el {peso_res[0]?.anio}, {formatNumber(peso_res[0]?.es_ocup_1000, 1)} davant {formatNumber(peso_res[0]?.ue_ocup_1000, 1)}.

<LineChart
    data={epa}
    x=fecha
    y=ocupados_constr_1000hab
    yFmt='0.0'
    yAxisTitle="ocupats per 1.000 habitants"
    colorPalette={['#b45309']}
    title="Ocupats en la construcció per 1.000 habitants, per trimestre (EPA)"
/>

La taxa d'atur del sector, calculada amb els aturats que van deixar la seva feina en la construcció fa menys d'un any, va passar del {formatNumber(epa_res[0]?.paro_2008, 1)} % a començament del 2008 a un màxim del {formatNumber(epa_res[0]?.paro_max, 1)} % el {trimCa(epa_res[0]?.etiqueta_paro_max)}; el {trimCa(epa_res[0]?.etiqueta)} és del {formatNumber(epa_res[0]?.paro, 1)} %.

<LineChart
    data={epa}
    x=fecha
    y=tasa_paro_constr
    yFmt='0.0"%"'
    yAxisTitle="% dels actius del sector"
    colorPalette={['#dc2626']}
    title="Taxa d'atur aproximada de la construcció, per trimestre (EPA)"
/>

A la Seguretat Social, la construcció tenia {mesCa(afil_res[0]?.mes_ultimo, true)} **{formatNumber(afil_res[0]?.afil_mill, 2)} milions d'afiliats** de mitjana ({formatNumber(afil_res[0]?.afil_1000, 1)} per 1.000 habitants i el {formatNumber(afil_res[0]?.pct, 1)} % de tots els afiliats), un {#if afil_res[0]?.var_anual >= 0}{formatNumber(afil_res[0]?.var_anual, 1)} % més{:else}{formatNumber(-afil_res[0]?.var_anual, 1)} % menys{/if} que un any abans. El {formatNumber(afil_res[0]?.pct_aut, 1)} % són autònoms, davant el {formatNumber(afil_res[0]?.pct_aut_2021, 1)} % del gener del 2021. Des del gener del 2026 la Seguretat Social classifica amb la nova CNAE-2025, cosa que pot donar petits salts.

<LineChart
    data={afil}
    x=fecha
    y=afiliados_constr_1000hab
    yFmt='0.0'
    yAxisTitle="afiliats per 1.000 habitants"
    colorPalette={['#b45309']}
    title="Afiliats a la Seguretat Social en la construcció per 1.000 habitants, mitjana mensual"
/>

<LineChart
    data={afil}
    x=fecha
    y=pct_autonomos_constr
    yFmt='0.0"%"'
    yAxisTitle="% dels afiliats del sector"
    colorPalette={['#7c3aed']}
    title="Autònoms en la construcció, % dels afiliats del sector"
/>

## Obra pública

La licitació oficial és el pressupost de les obres que les administracions treuen a concurs (amb IVA). El {lic_res[0]?.anio} va sumar **{formatNumber(lic_res[0]?.total, 0)} € per habitant** en euros del {lic_res[0]?.anio_base}: {formatNumber(lic_res[0]?.estado, 0)} € de l'Estat (incloses les seves entitats públiques, com Adif, Aena o Puertos, que aporten {formatNumber(lic_res[0]?.epe, 0)} €) i {formatNumber(lic_res[0]?.entes, 0)} € dels «ens territorials», que en aquesta estadística sumen comunitats autònomes i ajuntaments sense separar-los. El {formatNumber(lic_res[0]?.pct_obra_civil, 0)} % va ser obra civil i la resta edificació. El màxim des del {lic_res[0]?.anio_ini} va ser {formatNumber(lic_res[0]?.total_max, 0)} € el {lic_res[0]?.anio_max} i el mínim, {formatNumber(lic_res[0]?.total_min, 0)} € el {lic_res[0]?.anio_min}.

{#if lic_res[0]?.hay_provisional}
<p>Les dades des del {lic_res[0]?.anio_prov} són <strong>provisionals</strong>.</p>
{/if}

<BarChart
    data={lic_agentes}
    x=anio
    y=eur_hab
    series=agente
    type=stacked
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per habitant (euros d'avui)"
    seriesColors={{'Estado (con Adif, Aena, Puertos...)': '#b45309', 'Comunidades y ayuntamientos': '#0d9488'}}
    title="Licitació oficial d'obra pública per habitant, euros constants"
/>

La part de l'Estat depèn del Govern central. Cada barra es pinta amb el partit que governava a 1 de juliol d'aquell any; és una descripció, no una explicació: cada període coincideix amb una fase diferent del cicle econòmic. Amb governs del PP ({lic_partidos.filter(d => d.partido === 'PP')[0]?.n_anios} anys de la sèrie) la licitació de l'Estat va ser de {formatNumber(lic_partidos.filter(d => d.partido === 'PP')[0]?.estado_media, 0)} € per habitant i any de mitjana, i amb governs del PSOE ({lic_partidos.filter(d => d.partido === 'PSOE')[0]?.n_anios} anys), de {formatNumber(lic_partidos.filter(d => d.partido === 'PSOE')[0]?.estado_media, 0)} €. La més alta va ser de {formatNumber(lic_res[0]?.estado_max, 0)} € per habitant el {lic_res[0]?.anio_estado_max} i la més baixa, {formatNumber(lic_res[0]?.estado_min, 0)} € el {lic_res[0]?.anio_estado_min}.

<BarChart
    data={lic}
    x=anio
    y=estado_hab_real
    series=familia_estatal
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per habitant (euros d'avui)"
    seriesColors={{'PSOE': '#e30613', 'PP': '#1d84ce'}}
    title="Licitació de l'Estat per habitant i partit del Govern central a 1 de juliol, euros constants"
/>

<DataTable data={lic_presidentes} rows=10>
    <Column id=presidente title="President del Govern" />
    <Column id=partido title="Partit" />
    <Column id=anios title="Anys" />
    <Column id=n_anios title="Nre. d'anys" fmt='0' />
    <Column id=estado_media title="Estat, € per hab. i any" fmt='#,##0' contentType=bar barColor='#b45309' />
    <Column id=entes_media title="Comunitats i ajuntaments, € per hab. i any" fmt='#,##0' />
    <Column id=total_media title="Total, € per hab. i any" fmt='#,##0' />
</DataTable>

Per comunitat, el {lic_ccaa[0]?.anio} les que van rebre més licitació per habitant van ser {lic_ccaa_res[0]?.mas}, i les que menys, {lic_ccaa_res[0]?.menos}. El {formatNumber(lic_ccaa_res[0]?.pct_nr, 1)} % del total d'Espanya no es pot assignar a cap comunitat (obres que n'abasten diverses) i no apareix al mapa. La columna del partit és la del Govern autonòmic, però la licitació territorial barreja la de la comunitat amb la dels seus ajuntaments.

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
        {id: 'total_hab_real', title: 'Total, € per hab.', fmt: '#,##0'},
        {id: 'estado_hab_real', title: 'Estat, € per hab.', fmt: '#,##0'},
        {id: 'entes_territoriales_hab_real', title: 'Comunitat i ajuntaments, € per hab.', fmt: '#,##0'},
        {id: 'media_5', title: 'Mitjana de 5 anys, € per hab.', fmt: '#,##0'}
    ]}
/>

<DataTable data={lic_ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=total_hab_real title="Total, € per hab." fmt='#,##0' contentType=bar barColor='#14b8a6' />
    <Column id=estado_hab_real title="Estat" fmt='#,##0' />
    <Column id=entes_territoriales_hab_real title="Comunitat i ajuntaments" fmt='#,##0' />
    <Column id=media_5 title="Mitjana 5 anys" fmt='#,##0' />
    <Column id=familia_autonomica title="Partit del Govern autonòmic" />
    <Column id=anio title="Any" fmt='0' />
</DataTable>

## Quant es construeix

Els col·legis d'aparelladors van visar el {visados_res[0]?.anio} projectes de **{formatNumber(visados_res[0]?.ult, 2)} habitatges d'obra nova per cada 1.000 habitants** ({formatNumber(visados_res[0]?.ult_miles, 0)} mil). El {visados_res[0]?.anio_max}, en plena bombolla, van ser {formatNumber(visados_res[0]?.max_1000, 1)} per 1.000 ({formatNumber(visados_res[0]?.max_miles, 0)} mil habitatges); el {visados_res[0]?.anio_min}, només {formatNumber(visados_res[0]?.min_1000, 2)}. La superfície a construir va passar d'un màxim de {formatNumber(visados_res[0]?.m2_max, 2)} m² per habitant a {formatNumber(visados_res[0]?.m2_ult, 2)} m².

<BarChart
    data={visados}
    x=anio
    y=viviendas_nueva_1000hab
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="habitatges per 1.000 habitants"
    fillColor='#b45309'
    title="Habitatges d'obra nova visats per 1.000 habitants a Espanya"
/>

Per comunitat, el {visados_ccaa[0]?.anio} on es van visar més habitatges nous per habitant va ser a {visados_ccaa_res[0]?.mas} i on menys, a {visados_ccaa_res[0]?.menos} (de {formatNumber(visados_ccaa_res[0]?.max_1000, 1)} a {formatNumber(visados_ccaa_res[0]?.min_1000, 1)} per 1.000 habitants). L'estadística no inclou Ceuta ni Melilla.

<BarChart
    data={visados_ccaa}
    x=comunidad
    y=viviendas_nueva_1000hab
    swapXY=true
    yFmt='0.0'
    yAxisTitle="habitatges per 1.000 habitants"
    fillColor='#b45309'
    title="Habitatges d'obra nova visats per 1.000 habitants i comunitat, últim any"
/>

<DataTable data={visados_ccaa} rows=17 link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=viviendas_nueva_1000hab title="Obra nova per 1.000 hab." fmt='0.00' contentType=bar barColor='#b45309' />
    <Column id=media_2004_2007 title="Mitjana 2004-2007" fmt='0.00' />
    <Column id=viviendas_reforma_1000hab title="Reforma per 1.000 hab." fmt='0.00' />
    <Column id=viviendas_nueva title="Habitatges (total)" fmt='#,##0' />
    <Column id=anio title="Any" fmt='0' />
</DataTable>

Per comparar amb Europa cal fer servir els **permisos de construcció** d'Eurostat, que no són el mateix que els visats: per a Espanya, Eurostat dona {formatNumber(permisos_res[0]?.es_miles, 0)} mil habitatges amb permís el {permisos_res[0]?.anio}, davant {formatNumber(permisos_res[0]?.visados_miles, 0)} mil de visats, perquè l'INE li envia una altra font (llicències municipals). Les dues sèries no es poden barrejar. Amb els permisos, Espanya va ser el {permisos_res[0]?.anio} la {permisos_res[0]?.puesto}a de {permisos_res[0]?.n} països, amb {formatNumber(permisos_res[0]?.es, 1)} habitatges per 1.000 habitants davant {formatNumber(permisos_res[0]?.ue, 1)} a la UE.

<LineChart
    data={permisos_ue}
    x=anio
    y=viviendas_nueva_1000hab
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="habitatges amb permís per 1.000 hab."
    title="Habitatges amb permís de construcció per 1.000 habitants (Eurostat)"
/>

El ciment dona una altra mesura de l'activitat. El {cemento_res[0]?.anio_max} Espanya va consumir **{formatNumber(cemento_res[0]?.max_kg, 0)} kg per habitant**; el {cemento_res[0]?.anio_min}, {formatNumber(cemento_res[0]?.min_kg, 0)} kg, i el {cemento_res[0]?.anio}, {formatNumber(cemento_res[0]?.ult, 0)} kg (el {cemento_res[0]?.anio_ini} eren {formatNumber(cemento_res[0]?.kg_1995, 0)}). Es va exportar el {formatNumber(cemento_res[0]?.pct_export, 0)} % del que es va produir.

<LineChart
    data={cemento_largo}
    x=anio
    y=kg_hab
    series=serie
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kg per habitant"
    seriesColors={{'Consumo aparente': '#78716c', 'Producción': '#b45309'}}
    title="Ciment a Espanya: consum aparent i producció, kg per habitant"
/>

## Producció i costos

L'índex de producció de la construcció d'Eurostat mesura l'activitat en volum. El 2024 la d'Espanya era al {formatNumber(prod_res[0]?.f_2024, 0)} % de la del 2007 (UE: {formatNumber(prod_res[0]?.ue_2024, 0)} %); el mínim va ser el {formatNumber(prod_res[0]?.f_min, 0)} % el {prod_res[0]?.anio_f_min}. Per branques, el {prod_res[0]?.anio} l'edificació era al {formatNumber(prod_res[0]?.f41_ult, 0)} % del 2007 i l'enginyeria civil, al {formatNumber(prod_res[0]?.f42_ult, 0)} %.

{#if prod_res[0]?.hay_salto}
<p><strong>Compte amb el {prod_res[0]?.anio}:</strong> el total puja un {formatNumber(prod_res[0]?.f_var, 1)} % i la construcció especialitzada un {formatNumber(prod_res[0]?.f43_var, 1)} %, mentre que l'edificació varia un {formatNumber(prod_res[0]?.f41_var, 1)} % i l'enginyeria civil un {formatNumber(prod_res[0]?.f42_var, 1)} %. Aquest salt sembla una ruptura de la sèrie i no s'ha de llegir com un auge.</p>
{/if}

<LineChart
    data={prod}
    x=anio
    y=indice_2007
    series=rama_nombre
    xFmt='0'
    yFmt='0'
    yAxisTitle="2007 = 100"
    title="Producció de la construcció a Espanya per branca, 2007 = 100 (l'últim any del total i de l'especialitzada és dubtós)"
/>

<LineChart
    data={prod_es_ue}
    x=anio
    y=indice_2007
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="2007 = 100"
    title="Producció de la construcció (total), 2007 = 100"
/>

Construir un habitatge nou (materials i mà d'obra) costava el {costes_res[0]?.anio} un índex de {formatNumber(costes_res[0]?.es_nom, 1)} (2021 = 100), davant {formatNumber(costes_res[0]?.es_nom_2020, 1)} el 2020. Descomptada la inflació general, l'índex és a {formatNumber(costes_res[0]?.es_real, 1)}: si passa de 100, construir s'ha encarit més que la resta de preus des del 2021. El màxim real va ser {formatNumber(costes_res[0]?.es_real_max, 1)} el {costes_res[0]?.anio_real_max}. Espanya no publica a Eurostat un índex de costos propi: la seva sèrie de costos és la mateixa que la de preus de producció. A la UE, el preu de producció de l'habitatge nou era el {costes_res[0]?.anio_ue} a {formatNumber(costes_res[0]?.ue_precio, 1)}.

<LineChart
    data={costes}
    x=anio
    y=indice
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="2021 = 100"
    seriesColors={{'Coste nominal': '#b45309', 'Coste descontada la inflación': '#0d9488', 'UE-27, precio de producción nominal': '#64748b'}}
    title="Costos de construcció de l'habitatge nou a Espanya, 2021 = 100"
/>

## Les empreses

El {empresas_res[0]?.anio} hi havia a Espanya {formatNumber(empresas_res[0]?.es_emp, 1)} empreses de construcció per cada 1.000 habitants (UE: {formatNumber(empresas_res[0]?.ue_emp, 1)}; lloc {empresas_res[0]?.puesto} de {empresas_res[0]?.n}), amb {formatNumber(empresas_res[0]?.es_tam, 1)} ocupats de mitjana cadascuna (UE: {formatNumber(empresas_res[0]?.ue_tam, 1)}). Cada persona ocupada va generar {formatNumber(empresas_res[0]?.es_prod, 1)} mil euros de valor afegit, el {formatNumber(empresas_res[0]?.pct_prod_ue, 0)} % de la mitjana de la UE ({formatNumber(empresas_res[0]?.ue_prod, 1)} mil); a Alemanya, {formatNumber(empresas_res[0]?.de_prod, 1)} mil; a França, {formatNumber(empresas_res[0]?.fr_prod, 1)}, i a Itàlia, {formatNumber(empresas_res[0]?.it_prod, 1)}.

<BarChart
    data={empresas_productividad}
    x=serie
    y=productividad_miles_eur
    series=grupo
    swapXY=true
    sort=false
    yFmt='#,##0'
    yAxisTitle="milers de € per ocupat (euros corrents)"
    seriesColors={{'España': '#dc2626', 'UE-27': '#64748b', 'Otros países': '#93c5fd'}}
    title="Productivitat de la construcció: valor afegit per persona ocupada, últim any"
/>

<DataTable data={empresas_ramas} rows=4>
    <Column id=rama title="Branca" />
    <Column id=es_empresas title="Empreses per 1.000 hab., Espanya" fmt='0.00' />
    <Column id=ue_empresas title="UE" fmt='0.00' />
    <Column id=puesto_empresas title="Lloc d'Espanya" fmt='0' />
    <Column id=es_tamano title="Ocupats per empresa, Espanya" fmt='0.0' />
    <Column id=ue_tamano title="UE" fmt='0.0' />
    <Column id=es_productividad title="Milers de € per ocupat, Espanya" fmt='0.0' />
    <Column id=ue_productividad title="UE" fmt='0.0' />
</DataTable>

Espanya té també algunes de les constructores més grans del món. En el rànquing Global Powers of Construction {constructoras_res[0]?.edicion} de Deloitte apareixen {constructoras_res[0]?.n} grups espanyols entre les 100 constructores cotitzades més grans del món per ingressos, {constructoras_res[0]?.n_top50} d'ells entre els 50 primers; el més ben situat és {constructoras_res[0]?.primera} ({ordM(constructoras_res[0]?.puesto_primera)} del món), que obté fora d'Espanya el {formatNumber(constructoras_res[0]?.pct_exterior_primera, 1)} % de les seves vendes.

<DataTable data={constructoras} rows=10>
    <Column id=puesto title="Lloc mundial" fmt='0' />
    <Column id=empresa title="Empresa" />
    <Column id=ingresos_mill_usd title="Ingressos (milions de $)" fmt='#,##0' />
    <Column id=pct_ventas_exterior title="% vendes fora d'Espanya" fmt='0.0' />
    <Column id=edicion title="Edició" fmt='0' />
</DataTable>

## Per comunitat

El {ccaa_res[0]?.anio} la construcció va generar el {formatNumber(ccaa_res[0]?.es, 1)} % del valor afegit d'Espanya ({formatNumber(ccaa_res[0]?.es_2007, 1)} % el 2007), {formatNumber(ccaa_res[0]?.es_hab, 0)} € per habitant en euros d'avui. On pesa més és a {ccaa_res[0]?.mas}, i on menys, a {ccaa_res[0]?.menos}. {#if ccaa_res[0]?.n_debajo == ccaa_res[0]?.n}Totes les comunitats pesen avui menys que el 2007{:else}{ccaa_res[0]?.n_debajo} de les {ccaa_res[0]?.n} comunitats pesen avui menys que el 2007{/if}; la caiguda més gran és la de {ccaa_res[0]?.mas_caida}, que ha passat del {formatNumber(ccaa_res[0]?.mas_caida_2007, 1)} % al {formatNumber(ccaa_res[0]?.mas_caida_ult, 1)} % ({formatNumber(ccaa_res[0]?.caida_max, 1)} punts).

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
        {id: 'pct_vab_construccion', title: 'Construcció, % del VAB', fmt: '0.0'},
        {id: 'pct_vab_2007', title: '% del VAB el 2007', fmt: '0.0'},
        {id: 'dif_pp_vs_2007', title: 'Diferència amb el 2007 (punts)', fmt: '0.0'},
        {id: 'vab_constr_hab_real', title: "VAB del sector per hab. (euros d'avui)", fmt: '#,##0'}
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
        {id: 'dif_pp_vs_2007', title: 'Diferència amb el 2007 (punts de VAB)', fmt: '0.0'},
        {id: 'pct_vab_2007', title: '% del VAB el 2007', fmt: '0.0'},
        {id: 'pct_vab_construccion', title: '% del VAB avui', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=pct_vab_construccion title="% del VAB" fmt='0.0' contentType=bar barColor='#f59e0b' />
    <Column id=pct_vab_2007 title="% el 2007" fmt='0.0' />
    <Column id=dif_pp_vs_2007 title="Diferència (punts)" fmt='0.0' />
    <Column id=vab_constr_hab_real title="€ per hab. (euros d'avui)" fmt='#,##0' />
    <Column id=ocupados_constr_1000hab_epa title="Ocupats per 1.000 hab. (EPA)" fmt='0.0' />
    <Column id=anio title="Any" fmt='0' />
</DataTable>

## Metodologia i fonts

- **Pes en l'economia i comparació amb la UE:** Eurostat, comptes nacionals per branca [nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table) (VAB a preus corrents i en volum encadenat) i [nama_10_a10_e](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10_e/default/table) (ocupació); població, [nama_10_pe](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe/default/table). Construcció = secció F de la NACE.
- **Ocupació:** INE, Enquesta de Població Activa, ocupats per sector i província ([taula 65354](https://www.ine.es/jaxiT3/Tabla.htm?t=65354)) i aturats per sector de l'última feina ([taula 65331](https://www.ine.es/jaxiT3/Tabla.htm?t=65331)), CNAE-2009, des del 2008. La taxa d'atur del sector és una aproximació: els aturats que van deixar la feina fa més d'un any no tenen sector. Afiliats: [Seguretat Social, afiliats mitjans per activitat](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST8) (Règim General i Autònoms).
- **Licitació oficial:** Ministeri de Transports i Mobilitat Sostenible, [licitació oficial en construcció](https://www.transportes.gob.es/informacion-para-el-ciudadano/informacion-estadistica/construccion/licitacion-oficial-en-construccion), per comunitat via [ISTAC](https://datos.canarias.es/api/estadisticas/) (E20004A_000001); la part de les entitats públiques estatals, del [Banc d'Espanya, Butlletí Estadístic, quadre 23.9](https://www.bde.es/webbe/es/estadisticas/compartido/datos/pdf/be2309.pdf). Pressupost amb IVA l'any en què es licita. «Ens territorials» = comunitats autònomes + entitats locals (la font oberta no les separa). Partit del Govern a 1 de juliol de cada any.
- **Visats:** visats de direcció d'obra dels col·legis d'aparelladors (Ministeri de Transports), per comunitat via ISTAC (E20006A_000002) des del 2000 i per a Espanya des del 1992 al [Banc d'Espanya, quadre 23.8](https://www.bde.es/webbe/es/estadisticas/compartido/datos/pdf/be2308.pdf). **Permisos:** Eurostat [sts_cobp_a](https://ec.europa.eu/eurostat/databrowser/view/sts_cobp_a/default/table) (habitatges en edificis residencials sense residències col·lectives); no són comparables amb els visats.
- **Ciment:** [Banc d'Espanya, quadre 23.11](https://www.bde.es/webbe/es/estadisticas/compartido/datos/pdf/be2311.pdf) (dades d'Oficemen i del Ministeri d'Indústria). Consum aparent = producció + importacions − exportacions; només anys complets.
- **Producció i costos:** Eurostat [sts_copr_a](https://ec.europa.eu/eurostat/databrowser/view/sts_copr_a/default/table) (índex de producció, corregit de calendari, 2021 = 100, rebasat a 2007 = 100) i [sts_copi_a](https://ec.europa.eu/eurostat/databrowser/view/sts_copi_a/default/table) (costos i preus de producció de l'habitatge nou). El salt del 2025 en el total i en la construcció especialitzada d'Espanya es tracta com a possible ruptura de sèrie.
- **Empreses:** Eurostat, estadístiques estructurals d'empreses [sbs_ovw_act](https://ec.europa.eu/eurostat/databrowser/view/sbs_ovw_act/default/table) (empreses, ocupats i valor afegit; euros corrents de l'any, només per comparar països). Grans constructores: [Deloitte, Global Powers of Construction](https://www.deloitte.com/es/es/Industries/energy/perspectives/deloitte-global-powers-of-construction.html), xifres citades amb font (ingressos en milions de dòlars corrents, només els que dona la font).
- **Comunitats:** Eurostat, VAB regional [nama_10r_3gva](https://ec.europa.eu/eurostat/databrowser/view/nama_10r_3gva/default/table), que reprodueix la Comptabilitat Regional de l'INE.
- **Euros constants:** IPC de l'INE (euros del {lic_res[0]?.anio_base}); entre el 1996 i el 2001, enllaçat amb l'IPCA d'Espanya d'Eurostat ([prc_hicp_aind](https://ec.europa.eu/eurostat/databrowser/view/prc_hicp_aind/default/table)). Abans del 1996 no es donen xifres en euros. Població de l'INE (comunitats) i d'Eurostat (Espanya i UE).
