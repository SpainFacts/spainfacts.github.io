---
title: Eraikuntza
description: "Espainiako eraikuntza EBrekin alderatuta: balio erantsian eta enpleguan duen pisua 1995etik, 2007ko burbuila eta kolapsoa, obra publikoaren lizitazioa biztanleko euro errealetan eta Gobernuko alderdiaren arabera, ikus-onetsitako etxebizitzak, zementua, ekoizpena, kostuak, enpresak eta erkidegoak."
i18n_origen: 9b8936d58932
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
    // SQLtik gaztelaniaz datozen testuak euskaratu: '2.º trimestre de 2025', 'agosto de 2026', 'dato provisional'
    const MESES = {
        enero: ['urtarrila', 'urtarrilean'], febrero: ['otsaila', 'otsailean'], marzo: ['martxoa', 'martxoan'],
        abril: ['apirila', 'apirilean'], mayo: ['maiatza', 'maiatzean'], junio: ['ekaina', 'ekainean'],
        julio: ['uztaila', 'uztailean'], agosto: ['abuztua', 'abuztuan'], septiembre: ['iraila', 'irailean'],
        octubre: ['urria', 'urrian'], noviembre: ['azaroa', 'azaroan'], diciembre: ['abendua', 'abenduan']
    };
    const mesEu = (t, caso = 0) => {
        const m = /^(\S+) de (\d{4})$/.exec(t ?? String());
        return m && MESES[m[1]] ? `${urteko(m[2])} ${MESES[m[1]][caso]}` : t;
    };
    const hiru = (t, kasua = 'a') => {
        const m = /^(\d)\.º trimestre de (\d{4})$/.exec(t ?? String());
        return m ? `${urteko(m[2])} ${m[1]}. hiruhileko${kasua}` : t;
    };
    const datuEgoera = (t) => ({ 'dato provisional': 'behin-behineko datua', 'dato definitivo': 'behin betiko datua' })[t] ?? t;
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
    '/eu' || t.ruta AS ruta,
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
    '/eu' || t.ruta AS ruta,
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
    '/eu' || t.ruta AS ruta,
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
# 🏗️ Eraikuntza

Eraikuntza Espainiako ekonomiaren motorra izan zen, eta gero haren zama. {urtean(peso_res[0]?.anio_vab_max)} Espainiako **balio erantsiaren {formatNumber(peso_res[0]?.es_vab_max, 1)} %** sortzera iritsi zen, EBko batez besteko {formatNumber(peso_res[0]?.ue_vab_anio_max, 1)} %-ren aldean, eta 2007an {formatNumber(peso_res[0]?.ocup_2007_mill, 2)} milioi pertsonari ematen zion lana, landunen {formatNumber(peso_res[0]?.es_emp_2007, 1)} %-ri. Burbuila lehertu ondoren, sektorearen jarduera erreala 2007koaren {formatNumber(peso_res[0]?.es_vol_min, 0)} %-ra jaitsi zen {urtean(peso_res[0]?.anio_vol_min)}. {urtean(peso_res[0]?.anio)} {formatNumber(peso_res[0]?.es_vab, 1)} %-ko pisua du (EB: {formatNumber(peso_res[0]?.ue_vab, 1)} %), eta Espainia {peso_res[0]?.puesto}. postuan dago EBko {peso_res[0]?.n_paises} herrialdeen artean. Zifrak **biztanleko** ematen dira, eta euroetakoak, **inflazioa kenduta** ({urteko(lic_res[0]?.anio_base)} euroak). Urtero hasten eta amaitzen den etxebizitza [Obra berria](/eu/vivienda/construccion) atalean dago.

<Grid cols=4>
    <KpiCard
        title="Pisua balio erantsian"
        value={peso_res[0]?.es_vab}
        formattedValue="{formatNumber(peso_res[0]?.es_vab, 1)} %"
        period="{peso_res[0]?.anio} · EB-27: {formatNumber(peso_res[0]?.ue_vab, 1)} % · {peso_res[0]?.puesto}. postua, {peso_res[0]?.n_paises} herrialderen artean"
        change={(peso_res[0]?.es_vab - peso_res[0]?.es_vab_2007)?.toFixed(1)}
        changeUnit="pp"
        changePeriod="2007arekin alderatuta"
        direction="neutral"
        source="Eurostat (nama_10_a10)"
        sparklineData={peso_es.map(d => ({...d, y: d.pct_vab_construccion}))}
    />
    <KpiCard
        title="Landunak 1.000 biztanleko"
        value={epa_res[0]?.ocup_1000}
        formattedValue="{formatNumber(epa_res[0]?.ocup_1000, 1)}"
        period="{hiru(epa_res[0]?.etiqueta)} · {formatNumber(epa_res[0]?.ocup_mill, 2)} milioi · EB-27 ({peso_res[0]?.anio}): {formatNumber(peso_res[0]?.ue_ocup_1000, 1)}"
        change={(epa_res[0]?.ocup_1000 - epa_res[0]?.ocup_1000_hace_un_anio)?.toFixed(1)}
        changeUnit=""
        changePeriod="duela urtebeterekin alderatuta"
        direction="positive-up"
        source="INE (EPA)"
        sparklineData={epa.map(d => ({...d, y: d.ocupados_constr_1000hab}))}
    />
    <KpiCard
        title="Lizitazio publikoa biztanleko"
        value={lic_res[0]?.total}
        formattedValue="{formatNumber(lic_res[0]?.total, 0)} €"
        period="{lic_res[0]?.anio}, {urteko(lic_res[0]?.anio_base)} euroak · {formatNumber(lic_res[0]?.total_mm, 1)} mila milioi guztira · {datuEgoera(lic_res[0]?.estado_dato)}"
        change={lic_res[0]?.var_2007?.toFixed(0)}
        changeUnit="%"
        changePeriod="2007arekin alderatuta"
        direction="neutral"
        source="Garraio Ministerioa"
        sparklineData={lic.map(d => ({...d, y: d.total_hab_real}))}
    />
    <KpiCard
        title="Ikus-onetsitako etxebizitzak 1.000 biz."
        value={visados_res[0]?.ult}
        formattedValue="{formatNumber(visados_res[0]?.ult, 2)}"
        period="{visados_res[0]?.anio} · obra berria · {formatNumber(visados_res[0]?.ult_miles, 0)} mila etxebizitza · gehienekoa: {formatNumber(visados_res[0]?.max_1000, 1)}, {urtean(visados_res[0]?.anio_max)}"
        change={visados_res[0]?.var_anual?.toFixed(1)}
        changeUnit="%"
        changePeriod="aurreko urtearekin alderatuta"
        direction="neutral"
        source="Aparejadoreen elkargoak (Espainiako Bankua)"
        sparklineData={visados.map(d => ({...d, y: d.viviendas_nueva_1000hab}))}
    />
</Grid>

## Gorakada eta beherakada

1995ean eraikuntzak jada pisu handiagoa zuen Espainian EBn baino (balio erantsiaren {formatNumber(peso_res[0]?.es_vab_1995, 1)} %, {formatNumber(peso_res[0]?.ue_vab_1995, 1)} %-ren aldean). 2007an {#if peso_res[0]?.puesto_2007 == 1}27en artean pisu handiena zuen herrialdea zen{:else}27en artean {peso_res[0]?.puesto_2007}. postuan zegoen{/if}, eta enpleguaren {formatNumber(peso_res[0]?.es_emp_2007, 1)} % biltzen zuen, Europako {formatNumber(peso_res[0]?.ue_emp_2007, 1)} %-ren aldean. Harrezkero pisurik txikiena {urteko(peso_res[0]?.anio_vab_min)}a izan zen, {formatNumber(peso_res[0]?.es_vab_min, 1)} %. {urtean(peso_res[0]?.anio)}, balio erantsiaren {formatNumber(peso_res[0]?.es_vab, 1)} %-rekin eta enpleguaren {formatNumber(peso_res[0]?.es_emp, 1)} %-rekin (EB: {formatNumber(peso_res[0]?.ue_vab, 1)} % eta {formatNumber(peso_res[0]?.ue_emp, 1)} %), Espainia {peso_res[0]?.puesto}. postuan dago {peso_res[0]?.n_paises} herrialderen artean.

<LineChart
    data={peso}
    x=anio
    y=pct_vab_construccion
    series=serie
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="balio erantsi gordinaren %"
    title="Eraikuntzaren pisua balio erantsian, % prezio korronteetan"
/>

<LineChart
    data={peso_es_ue}
    x=anio
    y=pct_empleo_construccion
    series=serie
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="landunen %"
    seriesColors={{'España': '#dc2626', 'UE-27': '#64748b'}}
    title="Eraikuntzaren pisua enpleguan, landunen %"
/>

Prezioen eragina kenduta (bolumenean), Espainiako eraikuntzaren balio erantsia 1995ean 2007koaren {formatNumber(peso_res[0]?.es_vol_1995, 0)} % zen; {urtean(peso_res[0]?.anio_vol_min)} jo zuen hondoa, {formatNumber(peso_res[0]?.es_vol_min, 0)} %-rekin, eta {urtean(peso_res[0]?.anio)} {formatNumber(peso_res[0]?.es_vol, 0)} %-an dago. EB osoan 2007koaren {formatNumber(peso_res[0]?.ue_vol, 0)} %-an dago. Biztanleko, sektorearen balio erantsia 2007ko {formatNumber(peso_res[0]?.es_vabhab_2007, 0)} eurotik {urteko(peso_res[0]?.anio)} {formatNumber(peso_res[0]?.es_vabhab, 0)} eurora igaro zen, gaurko euroetan.

<LineChart
    data={peso}
    x=anio
    y=vab_constr_real_indice_2007
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="2007 = 100"
    title="Eraikuntzaren balio erantsia bolumenean (prezioen eraginik gabe), 2007 = 100"
/>

## Enplegua

EPAren arabera, {hiru(epa_res[0]?.etiqueta, 'an')} **{formatNumber(epa_res[0]?.ocup_mill, 2)} milioi pertsonak** egiten zuten lan eraikuntzan, {formatNumber(epa_res[0]?.ocup_1000, 1)} 1.000 biztanleko eta landunen {formatNumber(epa_res[0]?.pct, 1)} %. 2008aren hasieran {formatNumber(epa_res[0]?.ocup_2008_mill, 2)} milioi ziren ({formatNumber(epa_res[0]?.ocup_1000_2008, 1)} 1.000 biztanleko); seriearen gutxienekoa {formatNumber(epa_res[0]?.ocup_1000_min, 1)} izan zen, {hiru(epa_res[0]?.etiqueta_min, 'an')}. 2007an, Eurostaten urteko datuekin, Espainiak {formatNumber(peso_res[0]?.es_ocup_1000_2007, 1)} landun zituen sektorean 1.000 biztanleko, EBko {formatNumber(peso_res[0]?.ue_ocup_1000_2007, 1)}-en aldean; {urtean(peso_res[0]?.anio)}, {formatNumber(peso_res[0]?.es_ocup_1000, 1)}, {formatNumber(peso_res[0]?.ue_ocup_1000, 1)}-en aldean.

<LineChart
    data={epa}
    x=fecha
    y=ocupados_constr_1000hab
    yFmt='0.0'
    yAxisTitle="landunak 1.000 biztanleko"
    colorPalette={['#b45309']}
    title="Eraikuntzako landunak 1.000 biztanleko, hiruhilekoka (EPA)"
/>

Sektorearen langabezia-tasa, duela urtebete baino gutxiago eraikuntzako enplegua utzi zuten langabeekin kalkulatua, 2008aren hasierako {formatNumber(epa_res[0]?.paro_2008, 1)} %-tik {formatNumber(epa_res[0]?.paro_max, 1)} %-ko gehienekora igo zen {hiru(epa_res[0]?.etiqueta_paro_max, 'an')}; {hiru(epa_res[0]?.etiqueta, 'an')} {formatNumber(epa_res[0]?.paro, 1)} %-koa da.

<LineChart
    data={epa}
    x=fecha
    y=tasa_paro_constr
    yFmt='0.0"%"'
    yAxisTitle="sektoreko aktiboen %"
    colorPalette={['#dc2626']}
    title="Eraikuntzaren gutxi gorabeherako langabezia-tasa, hiruhilekoka (EPA)"
/>

Gizarte Segurantzan, eraikuntzak **{formatNumber(afil_res[0]?.afil_mill, 2)} milioi afiliatu** zituen batez beste {mesEu(afil_res[0]?.mes_ultimo, 1)} ({formatNumber(afil_res[0]?.afil_1000, 1)} 1.000 biztanleko eta afiliatu guztien {formatNumber(afil_res[0]?.pct, 1)} %), urtebete lehenago baino {#if afil_res[0]?.var_anual >= 0}{formatNumber(afil_res[0]?.var_anual, 1)} % gehiago{:else}{formatNumber(-afil_res[0]?.var_anual, 1)} % gutxiago{/if}. {formatNumber(afil_res[0]?.pct_aut, 1)} % autonomoak dira, 2021eko urtarrileko {formatNumber(afil_res[0]?.pct_aut_2021, 1)} %-ren aldean. 2026ko urtarriletik, Gizarte Segurantzak CNAE-2025 berriarekin sailkatzen du, eta horrek jauzi txikiak eragin ditzake.

<LineChart
    data={afil}
    x=fecha
    y=afiliados_constr_1000hab
    yFmt='0.0'
    yAxisTitle="afiliatuak 1.000 biztanleko"
    colorPalette={['#b45309']}
    title="Gizarte Segurantzako afiliatuak eraikuntzan 1.000 biztanleko, hileko batez bestekoa"
/>

<LineChart
    data={afil}
    x=fecha
    y=pct_autonomos_constr
    yFmt='0.0"%"'
    yAxisTitle="sektoreko afiliatuen %"
    colorPalette={['#7c3aed']}
    title="Autonomoak eraikuntzan, sektoreko afiliatuen %"
/>

## Obra publikoa

Lizitazio ofiziala administrazioek lehiaketara ateratzen dituzten obren aurrekontua da (BEZarekin). {urtean(lic_res[0]?.anio)} **{formatNumber(lic_res[0]?.total, 0)} euro biztanleko** izan zen, {urteko(lic_res[0]?.anio_base)} euroetan: {formatNumber(lic_res[0]?.estado, 0)} euro Estatuarenak (haren erakunde publikoak barne, hala nola Adif, Aena edo Portuak, {formatNumber(lic_res[0]?.epe, 0)} euro jartzen dituztenak) eta {formatNumber(lic_res[0]?.entes, 0)} euro «lurralde-erakundeenak»; estatistika honetan autonomia-erkidegoak eta udalak batera biltzen dira, bereizi gabe. {formatNumber(lic_res[0]?.pct_obra_civil, 0)} % obra zibila izan zen, eta gainerakoa, eraikingintza. {urtetik(lic_res[0]?.anio_ini)} gehienekoa {formatNumber(lic_res[0]?.total_max, 0)} euro izan zen, {urtean(lic_res[0]?.anio_max)}, eta gutxienekoa, {formatNumber(lic_res[0]?.total_min, 0)} euro, {urtean(lic_res[0]?.anio_min)}.

{#if lic_res[0]?.hay_provisional}
<p>{urtetik(lic_res[0]?.anio_prov)} aurrerako datuak <strong>behin-behinekoak</strong> dira.</p>
{/if}

<BarChart
    data={lic_agentes}
    x=anio
    y=eur_hab
    series=agente
    type=stacked
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ biztanleko (gaurko euroak)"
    seriesColors={{'Estado (con Adif, Aena, Puertos...)': '#b45309', 'Comunidades y ayuntamientos': '#0d9488'}}
    title="Obra publikoaren lizitazio ofiziala biztanleko, euro konstanteak"
/>

Estatuaren zatia Gobernu zentralaren mende dago. Barra bakoitza urte horretako uztailaren 1ean gobernatzen zuen alderdiaren kolorez margotzen da; deskribapen bat da, ez azalpen bat: aldi bakoitza ziklo ekonomikoaren fase desberdin batekin dator bat. PPren gobernuekin (serieko {lic_partidos.filter(d => d.partido === 'PP')[0]?.n_anios} urte) Estatuaren lizitazioa {formatNumber(lic_partidos.filter(d => d.partido === 'PP')[0]?.estado_media, 0)} euro izan zen biztanleko eta urteko batez beste, eta PSOEren gobernuekin ({lic_partidos.filter(d => d.partido === 'PSOE')[0]?.n_anios} urte), {formatNumber(lic_partidos.filter(d => d.partido === 'PSOE')[0]?.estado_media, 0)} euro. Handiena {formatNumber(lic_res[0]?.estado_max, 0)} euro izan zen biztanleko, {urtean(lic_res[0]?.anio_estado_max)}, eta txikiena, {formatNumber(lic_res[0]?.estado_min, 0)} euro, {urtean(lic_res[0]?.anio_estado_min)}.

<BarChart
    data={lic}
    x=anio
    y=estado_hab_real
    series=familia_estatal
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ biztanleko (gaurko euroak)"
    seriesColors={{'PSOE': '#e30613', 'PP': '#1d84ce'}}
    title="Estatuaren lizitazioa biztanleko eta Gobernu zentralaren alderdia uztailaren 1ean, euro konstanteak"
/>

<DataTable data={lic_presidentes} rows=10>
    <Column id=presidente title="Gobernuko presidentea" />
    <Column id=partido title="Alderdia" />
    <Column id=anios title="Urteak" />
    <Column id=n_anios title="Urte kopurua" fmt='0' />
    <Column id=estado_media title="Estatua, € biz. eta urteko" fmt='#,##0' contentType=bar barColor='#b45309' />
    <Column id=entes_media title="Erkidegoak eta udalak, € biz. eta urteko" fmt='#,##0' />
    <Column id=total_media title="Guztira, € biz. eta urteko" fmt='#,##0' />
</DataTable>

Erkidegoka, {urtean(lic_ccaa[0]?.anio)} biztanleko lizitazio gehien jaso zutenak hauek izan ziren: {lic_ccaa_res[0]?.mas}; eta gutxien jaso zutenak: {lic_ccaa_res[0]?.menos}. Espainia osoko guztizkoaren {formatNumber(lic_ccaa_res[0]?.pct_nr, 1)} % ezin zaio inongo erkidegori esleitu (hainbat erkidego hartzen dituzten obrak), eta ez da mapan agertzen. Alderdiaren zutabea autonomia-gobernuarena da, baina lurralde-lizitazioak erkidegoarena eta haren udalena nahasten ditu.

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
        {id: 'total_hab_real', title: 'Guztira, € biz.', fmt: '#,##0'},
        {id: 'estado_hab_real', title: 'Estatua, € biz.', fmt: '#,##0'},
        {id: 'entes_territoriales_hab_real', title: 'Erkidegoa eta udalak, € biz.', fmt: '#,##0'},
        {id: 'media_5', title: '5 urteko batez bestekoa, € biz.', fmt: '#,##0'}
    ]}
/>

<DataTable data={lic_ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=total_hab_real title="Guztira, € biz." fmt='#,##0' contentType=bar barColor='#14b8a6' />
    <Column id=estado_hab_real title="Estatua" fmt='#,##0' />
    <Column id=entes_territoriales_hab_real title="Erkidegoa eta udalak" fmt='#,##0' />
    <Column id=media_5 title="5 urteko batez bestekoa" fmt='#,##0' />
    <Column id=familia_autonomica title="Autonomia-gobernuaren alderdia" />
    <Column id=anio title="Urtea" fmt='0' />
</DataTable>

## Zenbat eraikitzen den

Aparejadoreen elkargoek {urtean(visados_res[0]?.anio)} **obra berriko {formatNumber(visados_res[0]?.ult, 2)} etxebizitzaren proiektuak ikus-onetsi zituzten 1.000 biztanleko** ({formatNumber(visados_res[0]?.ult_miles, 0)} mila). {urtean(visados_res[0]?.anio_max)}, burbuila betean, {formatNumber(visados_res[0]?.max_1000, 1)} izan ziren 1.000 biztanleko ({formatNumber(visados_res[0]?.max_miles, 0)} mila etxebizitza); {urtean(visados_res[0]?.anio_min)}, {formatNumber(visados_res[0]?.min_1000, 2)} besterik ez. Eraiki beharreko azalera biztanleko {formatNumber(visados_res[0]?.m2_max, 2)} m²-ko gehienekotik {formatNumber(visados_res[0]?.m2_ult, 2)} m²-ra igaro zen.

<BarChart
    data={visados}
    x=anio
    y=viviendas_nueva_1000hab
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="etxebizitzak 1.000 biztanleko"
    fillColor='#b45309'
    title="Obra berriko etxebizitza ikus-onetsiak 1.000 biztanleko Espainian"
/>

Erkidegoka, {urtean(visados_ccaa[0]?.anio)} biztanleko etxebizitza berri gehien ikus-onetsi zituztenak hauek izan ziren: {visados_ccaa_res[0]?.mas}; eta gutxien: {visados_ccaa_res[0]?.menos} ({formatNumber(visados_ccaa_res[0]?.max_1000, 1)} eta {formatNumber(visados_ccaa_res[0]?.min_1000, 1)} artean 1.000 biztanleko). Estatistikak ez ditu Ceuta eta Melilla barne hartzen.

<BarChart
    data={visados_ccaa}
    x=comunidad
    y=viviendas_nueva_1000hab
    swapXY=true
    yFmt='0.0'
    yAxisTitle="etxebizitzak 1.000 biztanleko"
    fillColor='#b45309'
    title="Obra berriko etxebizitza ikus-onetsiak 1.000 biztanleko eta erkidegoka, azken urtea"
/>

<DataTable data={visados_ccaa} rows=17 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=viviendas_nueva_1000hab title="Obra berria 1.000 biz." fmt='0.00' contentType=bar barColor='#b45309' />
    <Column id=media_2004_2007 title="2004-2007ko batez bestekoa" fmt='0.00' />
    <Column id=viviendas_reforma_1000hab title="Erreforma 1.000 biz." fmt='0.00' />
    <Column id=viviendas_nueva title="Etxebizitzak (guztira)" fmt='#,##0' />
    <Column id=anio title="Urtea" fmt='0' />
</DataTable>

Europarekin alderatzeko, Eurostaten **eraikuntza-baimenak** erabili behar dira, eta ez dira ikus-onespenen gauza bera: Espainiarako, Eurostatek {formatNumber(permisos_res[0]?.es_miles, 0)} mila etxebizitza ematen ditu baimenarekin {urtean(permisos_res[0]?.anio)}, {formatNumber(permisos_res[0]?.visados_miles, 0)} mila ikus-onetsiren aldean, INEk beste iturri bat bidaltzen diolako (udal-lizentziak). Bi serieak ezin dira nahastu. Baimenekin, Espainia {permisos_res[0]?.puesto}. postuan egon zen {urtean(permisos_res[0]?.anio)} {permisos_res[0]?.n} herrialderen artean, {formatNumber(permisos_res[0]?.es, 1)} etxebizitzarekin 1.000 biztanleko, EBko {formatNumber(permisos_res[0]?.ue, 1)}-en aldean.

<LineChart
    data={permisos_ue}
    x=anio
    y=viviendas_nueva_1000hab
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="baimendun etxebizitzak 1.000 biz."
    title="Eraikuntza-baimena duten etxebizitzak 1.000 biztanleko (Eurostat)"
/>

Zementuak jardueraren beste neurri bat ematen du. {urtean(cemento_res[0]?.anio_max)} Espainiak **{formatNumber(cemento_res[0]?.max_kg, 0)} kg kontsumitu zituen biztanleko**; {urtean(cemento_res[0]?.anio_min)}, {formatNumber(cemento_res[0]?.min_kg, 0)} kg, eta {urtean(cemento_res[0]?.anio)}, {formatNumber(cemento_res[0]?.ult, 0)} kg ({urtean(cemento_res[0]?.anio_ini)} {formatNumber(cemento_res[0]?.kg_1995, 0)} ziren). Ekoitzitakoaren {formatNumber(cemento_res[0]?.pct_export, 0)} % esportatu zen.

<LineChart
    data={cemento_largo}
    x=anio
    y=kg_hab
    series=serie
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kg biztanleko"
    seriesColors={{'Consumo aparente': '#78716c', 'Producción': '#b45309'}}
    title="Zementua Espainian: itxurazko kontsumoa eta ekoizpena, kg biztanleko"
/>

## Ekoizpena eta kostuak

Eurostaten eraikuntzaren ekoizpen-indizeak jarduera bolumenean neurtzen du. 2024an Espainiakoa 2007koaren {formatNumber(prod_res[0]?.f_2024, 0)} %-an zegoen (EB: {formatNumber(prod_res[0]?.ue_2024, 0)} %); gutxienekoa {formatNumber(prod_res[0]?.f_min, 0)} % izan zen, {urtean(prod_res[0]?.anio_f_min)}. Adarka, {urtean(prod_res[0]?.anio)} eraikingintza 2007koaren {formatNumber(prod_res[0]?.f41_ult, 0)} %-an zegoen, eta ingeniaritza zibila, {formatNumber(prod_res[0]?.f42_ult, 0)} %-an.

{#if prod_res[0]?.hay_salto}
<p><strong>Kontuz {urteko(prod_res[0]?.anio)} datuarekin:</strong> guztizkoa {formatNumber(prod_res[0]?.f_var, 1)} % igotzen da, eta eraikuntza espezializatua {formatNumber(prod_res[0]?.f43_var, 1)} %; eraikingintzak, berriz, {formatNumber(prod_res[0]?.f41_var, 1)} %-ko aldaketa du, eta ingeniaritza zibilak, {formatNumber(prod_res[0]?.f42_var, 1)} %-koa. Jauzi hori seriearen haustura dirudi, eta ez da gorakada gisa irakurri behar.</p>
{/if}

<LineChart
    data={prod}
    x=anio
    y=indice_2007
    series=rama_nombre
    xFmt='0'
    yFmt='0'
    yAxisTitle="2007 = 100"
    title="Eraikuntzaren ekoizpena Espainian adarka, 2007 = 100 (guztizkoaren eta espezializatuaren azken urtea zalantzazkoa da)"
/>

<LineChart
    data={prod_es_ue}
    x=anio
    y=indice_2007
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="2007 = 100"
    title="Eraikuntzaren ekoizpena (guztira), 2007 = 100"
/>

Etxebizitza berri bat eraikitzeak (materialak eta eskulana) {formatNumber(costes_res[0]?.es_nom, 1)} indizea zuen {urtean(costes_res[0]?.anio)} (2021 = 100), 2020ko {formatNumber(costes_res[0]?.es_nom_2020, 1)}-en aldean. Inflazio orokorra kenduta, indizea {formatNumber(costes_res[0]?.es_real, 1)}-ean dago: 100 gainditzen badu, eraikitzea gainerako prezioak baino gehiago garestitu da 2021etik. Gehieneko erreala {formatNumber(costes_res[0]?.es_real_max, 1)} izan zen, {urtean(costes_res[0]?.anio_real_max)}. Espainiak ez du Eurostaten kostu-indize propiorik argitaratzen: haren kostu-seriea ekoizpen-prezioena bera da. EBn, etxebizitza berriaren ekoizpen-prezioa {formatNumber(costes_res[0]?.ue_precio, 1)} zen {urtean(costes_res[0]?.anio_ue)}.

<LineChart
    data={costes}
    x=anio
    y=indice
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="2021 = 100"
    seriesColors={{'Coste nominal': '#b45309', 'Coste descontada la inflación': '#0d9488', 'UE-27, precio de producción nominal': '#64748b'}}
    title="Etxebizitza berriaren eraikuntza-kostuak Espainian, 2021 = 100"
/>

## Enpresak

{urtean(empresas_res[0]?.anio)} {formatNumber(empresas_res[0]?.es_emp, 1)} eraikuntza-enpresa zeuden Espainian 1.000 biztanleko (EB: {formatNumber(empresas_res[0]?.ue_emp, 1)}; {empresas_res[0]?.puesto}. postua {empresas_res[0]?.n} herrialderen artean), bakoitzak batez beste {formatNumber(empresas_res[0]?.es_tam, 1)} landun zituela (EB: {formatNumber(empresas_res[0]?.ue_tam, 1)}). Landun bakoitzak {formatNumber(empresas_res[0]?.es_prod, 1)} mila euroko balio erantsia sortu zuen, EBko batez bestekoaren {formatNumber(empresas_res[0]?.pct_prod_ue, 0)} % ({formatNumber(empresas_res[0]?.ue_prod, 1)} mila); Alemanian, {formatNumber(empresas_res[0]?.de_prod, 1)} mila; Frantzian, {formatNumber(empresas_res[0]?.fr_prod, 1)}, eta Italian, {formatNumber(empresas_res[0]?.it_prod, 1)}.

<BarChart
    data={empresas_productividad}
    x=serie
    y=productividad_miles_eur
    series=grupo
    swapXY=true
    sort=false
    yFmt='#,##0'
    yAxisTitle="milaka € landuneko (euro korronteak)"
    seriesColors={{'España': '#dc2626', 'UE-27': '#64748b', 'Otros países': '#93c5fd'}}
    title="Eraikuntzaren produktibitatea: balio erantsia landuneko, azken urtea"
/>

<DataTable data={empresas_ramas} rows=4>
    <Column id=rama title="Adarra" />
    <Column id=es_empresas title="Enpresak 1.000 biz., Espainia" fmt='0.00' />
    <Column id=ue_empresas title="EB" fmt='0.00' />
    <Column id=puesto_empresas title="Espainiaren postua" fmt='0' />
    <Column id=es_tamano title="Landunak enpresako, Espainia" fmt='0.0' />
    <Column id=ue_tamano title="EB" fmt='0.0' />
    <Column id=es_productividad title="Milaka € landuneko, Espainia" fmt='0.0' />
    <Column id=ue_productividad title="EB" fmt='0.0' />
</DataTable>

Espainiak munduko eraikuntza-enpresa handienetako batzuk ere baditu. Deloitteren Global Powers of Construction {constructoras_res[0]?.edicion} rankingean, {constructoras_res[0]?.n} talde espainiar agertzen dira diru-sarreren arabera munduko burtsan kotizatzen duten 100 eraikuntza-enpresa handienen artean, eta horietatik {constructoras_res[0]?.n_top50} lehen 50en artean; ondoen kokatuta dagoena {constructoras_res[0]?.primera} da (munduko {constructoras_res[0]?.puesto_primera}.a), eta salmenten {formatNumber(constructoras_res[0]?.pct_exterior_primera, 1)} % Espainiatik kanpo lortzen du.

<DataTable data={constructoras} rows=10>
    <Column id=puesto title="Munduko postua" fmt='0' />
    <Column id=empresa title="Enpresa" />
    <Column id=ingresos_mill_usd title="Diru-sarrerak (milioi $)" fmt='#,##0' />
    <Column id=pct_ventas_exterior title="Espainiatik kanpoko salmenten %" fmt='0.0' />
    <Column id=edicion title="Edizioa" fmt='0' />
</DataTable>

## Erkidegoka

{urtean(ccaa_res[0]?.anio)} eraikuntzak Espainiako balio erantsiaren {formatNumber(ccaa_res[0]?.es, 1)} % sortu zuen (2007an, {formatNumber(ccaa_res[0]?.es_2007, 1)} %), {formatNumber(ccaa_res[0]?.es_hab, 0)} euro biztanleko gaurko euroetan. Pisu handiena hemen du: {ccaa_res[0]?.mas}; eta txikiena, hemen: {ccaa_res[0]?.menos}. {#if ccaa_res[0]?.n_debajo == ccaa_res[0]?.n}Erkidego guztiek pisu txikiagoa dute gaur 2007an baino{:else}{ccaa_res[0]?.n} erkidegoetatik {ccaa_res[0]?.n_debajo}k pisu txikiagoa dute gaur 2007an baino{/if}; beherakadarik handiena hemen izan da: {ccaa_res[0]?.mas_caida}, {formatNumber(ccaa_res[0]?.mas_caida_2007, 1)} %-tik {formatNumber(ccaa_res[0]?.mas_caida_ult, 1)} %-ra igaro baita ({formatNumber(ccaa_res[0]?.caida_max, 1)} puntu).

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
        {id: 'pct_vab_construccion', title: 'Eraikuntza, BEGaren %', fmt: '0.0'},
        {id: 'pct_vab_2007', title: 'BEGaren % 2007an', fmt: '0.0'},
        {id: 'dif_pp_vs_2007', title: 'Aldea 2007arekin (puntuak)', fmt: '0.0'},
        {id: 'vab_constr_hab_real', title: 'Sektorearen BEG biz. (gaurko euroak)', fmt: '#,##0'}
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
        {id: 'dif_pp_vs_2007', title: 'Aldea 2007arekin (BEGaren puntuak)', fmt: '0.0'},
        {id: 'pct_vab_2007', title: 'BEGaren % 2007an', fmt: '0.0'},
        {id: 'pct_vab_construccion', title: 'BEGaren % gaur', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=pct_vab_construccion title="BEGaren %" fmt='0.0' contentType=bar barColor='#f59e0b' />
    <Column id=pct_vab_2007 title="% 2007an" fmt='0.0' />
    <Column id=dif_pp_vs_2007 title="Aldea (puntuak)" fmt='0.0' />
    <Column id=vab_constr_hab_real title="€ biz. (gaurko euroak)" fmt='#,##0' />
    <Column id=ocupados_constr_1000hab_epa title="Landunak 1.000 biz. (EPA)" fmt='0.0' />
    <Column id=anio title="Urtea" fmt='0' />
</DataTable>

## Metodologia eta iturriak

- **Pisua ekonomian eta EBrekiko alderaketa:** Eurostat, kontu nazionalak adarka, [nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table) (BEG prezio korronteetan eta bolumen kateatuan) eta [nama_10_a10_e](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10_e/default/table) (enplegua); biztanleria, [nama_10_pe](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe/default/table). Eraikuntza = NACEren F atala.
- **Enplegua:** INE, Biztanleria Aktiboaren Inkesta (EPA), landunak sektore eta probintziaka ([65354 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=65354)) eta langabeak azken enpleguaren sektorearen arabera ([65331 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=65331)), CNAE-2009, 2008tik. Sektorearen langabezia-tasa hurbilketa bat da: duela urtebete baino gehiago enplegua utzi zuten langabeek ez dute sektorerik. Afiliatuak: [Gizarte Segurantza, batez besteko afiliatuak jardueraren arabera](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST8) (Erregimen Orokorra eta Autonomoak).
- **Lizitazio ofiziala:** Garraio eta Mugikortasun Iraunkorreko Ministerioa, [eraikuntzako lizitazio ofiziala](https://www.transportes.gob.es/informacion-para-el-ciudadano/informacion-estadistica/construccion/licitacion-oficial-en-construccion), erkidegoka [ISTAC](https://datos.canarias.es/api/estadisticas/) bidez (E20004A_000001); estatuko erakunde publikoen zatia, [Espainiako Bankua, Buletin Estatistikoa, 23.9 koadroa](https://www.bde.es/webbe/es/estadisticas/compartido/datos/pdf/be2309.pdf). Aurrekontua BEZarekin, lizitatzen den urtean. «Lurralde-erakundeak» = autonomia-erkidegoak + toki-erakundeak (iturri irekiak ez ditu bereizten). Gobernuaren alderdia urte bakoitzeko uztailaren 1ean.
- **Ikus-onespenak:** aparejadoreen elkargoen obra-zuzendaritzako ikus-onespenak (Garraio Ministerioa), erkidegoka ISTAC bidez (E20006A_000002) 2000tik, eta Espainiarako 1992tik [Espainiako Bankuaren 23.8 koadroan](https://www.bde.es/webbe/es/estadisticas/compartido/datos/pdf/be2308.pdf). **Baimenak:** Eurostat [sts_cobp_a](https://ec.europa.eu/eurostat/databrowser/view/sts_cobp_a/default/table) (bizitegi-eraikinetako etxebizitzak, egoitza kolektiborik gabe); ez dira ikus-onespenekin alderagarriak.
- **Zementua:** [Espainiako Bankua, 23.11 koadroa](https://www.bde.es/webbe/es/estadisticas/compartido/datos/pdf/be2311.pdf) (Oficemen eta Industria Ministerioaren datuak). Itxurazko kontsumoa = ekoizpena + inportazioak − esportazioak; urte osoak bakarrik.
- **Ekoizpena eta kostuak:** Eurostat [sts_copr_a](https://ec.europa.eu/eurostat/databrowser/view/sts_copr_a/default/table) (ekoizpen-indizea, egutegi-efektua zuzenduta, 2021 = 100, 2007 = 100 oinarrira aldatua) eta [sts_copi_a](https://ec.europa.eu/eurostat/databrowser/view/sts_copi_a/default/table) (etxebizitza berriaren kostuak eta ekoizpen-prezioak). Espainiako guztizkoaren eta eraikuntza espezializatuaren 2025eko jauzia seriearen balizko haustura gisa hartzen da.
- **Enpresak:** Eurostat, enpresen egitura-estatistikak [sbs_ovw_act](https://ec.europa.eu/eurostat/databrowser/view/sbs_ovw_act/default/table) (enpresak, landunak eta balio erantsia; urteko euro korronteak, herrialdeak alderatzeko bakarrik). Eraikuntza-enpresa handiak: [Deloitte, Global Powers of Construction](https://www.deloitte.com/es/es/Industries/energy/perspectives/deloitte-global-powers-of-construction.html), iturria aipatuta emandako zifrak (diru-sarrerak dolar korronteetan, milioitan, iturriak ematen dituenak bakarrik).
- **Erkidegoak:** Eurostat, eskualdeko BEG [nama_10r_3gva](https://ec.europa.eu/eurostat/databrowser/view/nama_10r_3gva/default/table), INEren Eskualdeko Kontabilitatea islatzen duena.
- **Euro konstanteak:** INEren KPIa ({urteko(lic_res[0]?.anio_base)} euroak); 1996 eta 2001 artean, Eurostaten Espainiako KPIHarekin lotua ([prc_hicp_aind](https://ec.europa.eu/eurostat/databrowser/view/prc_hicp_aind/default/table)). 1996 baino lehen ez da euro-zifrarik ematen. Biztanleria INErena (erkidegoak) eta Eurostatena (Espainia eta EB).
