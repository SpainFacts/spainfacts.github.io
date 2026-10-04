---
title: Industry
description: "Where Spain is an industrial powerhouse (cars, tiles, olive oil, cured ham, railway equipment, wind towers) and how much its industry weighs compared with the EU average: manufacturing GVA and employment, industrial production, exports and regions."
i18n_origen: 276740ec377f
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    const MESES_EN = { enero: 'January', febrero: 'February', marzo: 'March', abril: 'April', mayo: 'May', junio: 'June', julio: 'July', agosto: 'August', septiembre: 'September', octubre: 'October', noviembre: 'November', diciembre: 'December' };
    const mesEn = (s) => s ? s.replace(/^(\w+) de (\d{4})$/, (m, mes, a) => (MESES_EN[mes] ?? mes) + ' ' + a) : '';
    const decEn = (s) => s ? s.replace(/(\d),(\d)/g, '$1.$2') : '';
    const ord = (n) => { if (n === null || n === undefined || n === '') return ''; const v = Number(n) % 100; const s = ['th', 'st', 'nd', 'rd']; return n + (s[(v - 20) % 10] || s[v] || s[0]); };
</script>

```sql veh
SELECT CAST(anio AS INTEGER) AS anio, vehiculos, turismos, exportados, pct_exportado, vehiculos_1000_hab,
       CAST(puesto_europa AS INTEGER) AS puesto_europa, CAST(puesto_mundo AS INTEGER) AS puesto_mundo,
       cuota_mundo_pct, fuente_dato
FROM mother.industria_vehiculos
WHERE cod_pais = 'ES'
ORDER BY anio
```

```sql veh_res
WITH v AS (
    SELECT *, lag(vehiculos) OVER (ORDER BY anio) AS vehiculos_ant, lag(anio) OVER (ORDER BY anio) AS anio_ant
    FROM mother.industria_vehiculos
    WHERE cod_pais = 'ES'
)
SELECT
    CAST(max(anio) AS INTEGER) AS anio,
    arg_max(vehiculos, anio) AS vehiculos,
    arg_max(vehiculos, anio) / 1e6 AS vehiculos_millones,
    arg_max(vehiculos_1000_hab, anio) AS veh_1000,
    arg_max(turismos, anio) AS turismos,
    arg_max(exportados, anio) FILTER (WHERE exportados IS NOT NULL) AS exportados,
    arg_max(pct_exportado, anio) FILTER (WHERE pct_exportado IS NOT NULL) AS pct_exportado,
    CAST(max(anio) FILTER (WHERE pct_exportado IS NOT NULL) AS INTEGER) AS anio_exportado,
    100 * (arg_max(vehiculos, anio) / arg_max(vehiculos_ant, anio) - 1) AS var_anual,
    CAST(arg_max(anio_ant, anio) AS INTEGER) AS anio_ant,
    max(vehiculos) FILTER (WHERE anio = 2019) / 1e6 AS veh_2019_millones,
    100 * (arg_max(vehiculos, anio) / max(vehiculos) FILTER (WHERE anio = 2019) - 1) AS var_2019,
    CAST(max(anio) FILTER (WHERE puesto_europa IS NOT NULL) AS INTEGER) AS anio_oica,
    CAST(arg_max(puesto_europa, anio) FILTER (WHERE puesto_europa IS NOT NULL) AS INTEGER) AS puesto_europa,
    CAST(arg_max(puesto_mundo, anio) FILTER (WHERE puesto_mundo IS NOT NULL) AS INTEGER) AS puesto_mundo,
    arg_max(cuota_mundo_pct, anio) FILTER (WHERE cuota_mundo_pct IS NOT NULL) AS cuota_mundo,
    arg_max(vehiculos_1000_hab, anio) FILTER (WHERE puesto_europa IS NOT NULL) AS veh_1000_oica,
    arg_max(vehiculos, anio) FILTER (WHERE puesto_europa IS NOT NULL) / 1e6 AS veh_oica_millones
FROM v
```

```sql veh_europa
SELECT pais, CAST(vehiculos AS INTEGER) AS vehiculos, vehiculos_1000_hab, CAST(puesto_europa AS INTEGER) AS puesto_europa,
       CAST(puesto_mundo AS INTEGER) AS puesto_mundo, coalesce(cobertura, 'todos los vehículos') AS cobertura,
       CASE WHEN cod_pais = 'ES' THEN 'España' ELSE 'Otros países' END AS grupo
FROM mother.industria_vehiculos
WHERE region = 'Europa'
  AND anio = (SELECT max(anio) FROM mother.industria_vehiculos WHERE puesto_europa IS NOT NULL)
ORDER BY vehiculos DESC
```

```sql veh_europa_hab
SELECT * FROM ${veh_europa} WHERE vehiculos_1000_hab IS NOT NULL ORDER BY vehiculos_1000_hab DESC
```

```sql veh_lideres
SELECT
    max(vehiculos_1000_hab) FILTER (WHERE pais = 'Alemania') AS de_1000,
    max(vehiculos_1000_hab) FILTER (WHERE pais = 'Chequia') AS cz_1000,
    max(vehiculos_1000_hab) FILTER (WHERE pais = 'Eslovaquia') AS sk_1000,
    max(vehiculos_1000_hab) FILTER (WHERE pais = 'Francia') AS fr_1000,
    max(vehiculos_1000_hab) FILTER (WHERE pais = 'Italia') AS it_1000
FROM ${veh_europa}
```

```sql fabricas
SELECT fabrica, grupo, tipo, municipio, provincia, lat, lon, modelos, modelos_adjudicados,
       CAST(n_modelos AS INTEGER) AS n_modelos, CAST(n_adjudicados AS INTEGER) AS n_adjudicados,
       CAST(modelos_electrificados AS INTEGER) AS modelos_electrificados, otras_producciones,
       CASE WHEN tipo LIKE 'turismos%' THEN 'Turismos'
            WHEN tipo = 'componentes' THEN 'Componentes'
            ELSE 'Furgonetas, camiones y autobuses' END AS categoria,
       greatest(n_modelos, 1) AS tamano
FROM mother.industria_fabricas
ORDER BY n_modelos DESC, fabrica
```

```sql fab_res
SELECT
    CAST(count(*) AS INTEGER) AS plantas,
    CAST(count(*) FILTER (WHERE n_modelos > 0) AS INTEGER) AS plantas_montaje,
    CAST(sum(n_modelos) AS INTEGER) AS modelos,
    CAST(sum(modelos_electrificados) AS INTEGER) AS electrificados,
    CAST(sum(n_adjudicados) AS INTEGER) AS adjudicados,
    CAST(count(DISTINCT cod_ccaa) AS INTEGER) AS comunidades,
    arg_max(fabrica, n_modelos) AS mas_modelos,
    CAST(max(n_modelos) AS INTEGER) AS max_modelos
FROM mother.industria_fabricas
```

```sql veh_ccaa
SELECT t.nombre AS comunidad, r.cuota_espana_pct, r.peso_en_industria_ccaa_pct, CAST(r.n_ccaa_con_dato AS INTEGER) AS n_ccaa
FROM mother.industria_ccaa_ramas r
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = r.cod_ccaa
WHERE r.rama = 'Fabricación de vehículos de motor, remolques y semirremolques'
  AND r.anio = (SELECT max(anio) FROM mother.industria_ccaa_ramas)
ORDER BY r.cuota_espana_pct DESC
LIMIT 4
```

```sql veh_ccaa_txt
SELECT string_agg(comunidad || ' (' || CAST(round(cuota_espana_pct) AS INTEGER) || ' %)', ', ' ORDER BY cuota_espana_pct DESC) AS lista,
       sum(cuota_espana_pct) AS suma, max(n_ccaa) AS n_ccaa
FROM ${veh_ccaa}
```

```sql ramas
SELECT rama, rama_nombre, nivel, CAST(anio AS INTEGER) AS anio, cuota_cifra_negocios_pct,
       CAST(puesto_cifra_negocios AS INTEGER) AS puesto, CAST(n_paises_cifra_negocios AS INTEGER) AS n_paises,
       CAST(puesto_cifra_negocios AS INTEGER) || '.º de ' || CAST(n_paises_cifra_negocios AS INTEGER) AS puesto_txt,
       lider_cifra_negocios_nombre AS lider, veces_peso_poblacion, cifra_negocios_es_real_meur,
       peso_manuf_es_pct, peso_manuf_ue_pct, indice_especializacion, cuota_poblacion_pct, nota,
       CASE WHEN veces_peso_poblacion >= 1 THEN 'Más que su peso en población' ELSE 'Menos que su peso en población' END AS grupo
FROM mother.industria_ramas_ue
WHERE es_ultimo_anio
ORDER BY cuota_cifra_negocios_pct DESC
```

```sql ramas_res
SELECT
    CAST(max(anio) AS INTEGER) AS anio,
    max(cuota_poblacion_pct) AS cuota_pob,
    CAST(count(*) FILTER (WHERE veces_peso_poblacion >= 1) AS INTEGER) AS n_por_encima,
    CAST(count(*) AS INTEGER) AS n_ramas,
    max(cuota_cifra_negocios_pct) FILTER (WHERE rama = 'C') AS c_cuota,
    max(puesto) FILTER (WHERE rama = 'C') AS c_puesto,
    max(cuota_cifra_negocios_pct) FILTER (WHERE rama = 'C2331') AS az_cuota,
    max(puesto) FILTER (WHERE rama = 'C2331') AS az_puesto,
    max(n_paises) FILTER (WHERE rama = 'C2331') AS az_n,
    max(lider) FILTER (WHERE rama = 'C2331') AS az_lider,
    max(veces_peso_poblacion) FILTER (WHERE rama = 'C2331') AS az_veces,
    max(indice_especializacion) FILTER (WHERE rama = 'C2331') AS az_espec,
    max(cuota_cifra_negocios_pct) FILTER (WHERE rama = 'C233') AS cer_cuota,
    max(cuota_cifra_negocios_pct) FILTER (WHERE rama = 'C302') AS fer_cuota,
    max(puesto) FILTER (WHERE rama = 'C302') AS fer_puesto,
    max(n_paises) FILTER (WHERE rama = 'C302') AS fer_n,
    max(lider) FILTER (WHERE rama = 'C302') AS fer_lider,
    max(veces_peso_poblacion) FILTER (WHERE rama = 'C302') AS fer_veces,
    max(cuota_cifra_negocios_pct) FILTER (WHERE rama = 'C303') AS aer_cuota,
    max(puesto) FILTER (WHERE rama = 'C303') AS aer_puesto,
    max(n_paises) FILTER (WHERE rama = 'C303') AS aer_n,
    max(lider) FILTER (WHERE rama = 'C303') AS aer_lider,
    max(cuota_cifra_negocios_pct) FILTER (WHERE rama = 'C19') AS ref_cuota,
    max(puesto) FILTER (WHERE rama = 'C19') AS ref_puesto,
    max(n_paises) FILTER (WHERE rama = 'C19') AS ref_n,
    max(peso_manuf_es_pct) FILTER (WHERE rama = 'C19') AS ref_peso_es,
    max(peso_manuf_ue_pct) FILTER (WHERE rama = 'C19') AS ref_peso_ue,
    max(cuota_cifra_negocios_pct) FILTER (WHERE rama = 'C10') AS ali_cuota,
    max(puesto) FILTER (WHERE rama = 'C10') AS ali_puesto,
    max(lider) FILTER (WHERE rama = 'C10') AS ali_lider,
    max(peso_manuf_es_pct) FILTER (WHERE rama = 'C10') AS ali_peso_es,
    max(peso_manuf_ue_pct) FILTER (WHERE rama = 'C10') AS ali_peso_ue,
    max(cifra_negocios_es_real_meur) FILTER (WHERE rama = 'C10') / 1000 AS ali_cn_real_mm,
    max(cuota_cifra_negocios_pct) FILTER (WHERE rama = 'C11') AS beb_cuota,
    max(puesto) FILTER (WHERE rama = 'C11') AS beb_puesto,
    max(peso_manuf_es_pct) FILTER (WHERE rama = 'C11') AS beb_peso_es,
    max(peso_manuf_ue_pct) FILTER (WHERE rama = 'C11') AS beb_peso_ue,
    max(cuota_cifra_negocios_pct) FILTER (WHERE rama = 'C29') AS aut_cuota,
    max(puesto) FILTER (WHERE rama = 'C29') AS aut_puesto,
    max(peso_manuf_es_pct) FILTER (WHERE rama = 'C29') AS aut_peso_es,
    max(peso_manuf_ue_pct) FILTER (WHERE rama = 'C29') AS aut_peso_ue,
    max(cuota_cifra_negocios_pct) FILTER (WHERE rama = 'C293') AS comp_cuota,
    max(cuota_cifra_negocios_pct) FILTER (WHERE rama = 'C2811') AS tur_cuota,
    max(cuota_cifra_negocios_pct) FILTER (WHERE rama = 'C28') AS maq_cuota,
    max(cuota_cifra_negocios_pct) FILTER (WHERE rama = 'C21') AS far_cuota,
    max(cuota_cifra_negocios_pct) FILTER (WHERE rama = 'C26') AS ele_cuota
FROM ${ramas}
```

```sql ramas_peso
SELECT rama_nombre, 'España' AS territorio, peso_manuf_es_pct AS peso, peso_manuf_es_pct AS orden
FROM ${ramas} WHERE nivel = 'division'
UNION ALL
SELECT rama_nombre, 'Unión Europea' AS territorio, peso_manuf_ue_pct AS peso, peso_manuf_es_pct AS orden
FROM ${ramas} WHERE nivel = 'division'
ORDER BY orden DESC, territorio
```

```sql ramas_rank
SELECT
    CAST(count(*) FILTER (WHERE peso_manuf_es_pct > (SELECT peso_manuf_es_pct FROM ${ramas} WHERE rama = 'C10')) + 1 AS INTEGER) AS ali_puesto_es,
    CAST(count(*) FILTER (WHERE peso_manuf_ue_pct > (SELECT peso_manuf_ue_pct FROM ${ramas} WHERE rama = 'C10')) + 1 AS INTEGER) AS ali_puesto_ue,
    arg_max(rama_nombre, peso_manuf_ue_pct) AS primera_ue,
    max(peso_manuf_ue_pct) AS primera_ue_peso
FROM ${ramas}
WHERE nivel = 'division'
```

```sql productos
SELECT producto, producto_nombre, CAST(anio AS INTEGER) AS anio, unidad_legible, cantidad_es_legible, cantidad_ue_legible,
       cuota_cantidad_pct, CAST(puesto_cantidad AS INTEGER) AS puesto, CAST(n_paises_cantidad AS INTEGER) AS n_paises,
       CAST(puesto_cantidad AS INTEGER) || '.º de ' || CAST(n_paises_cantidad AS INTEGER) AS puesto_txt,
       lider_cantidad_nombre AS lider, cuota_valor_pct, veces_peso_poblacion, valor_es_real_meur, cantidad_por_1000_hab_es,
       CASE WHEN veces_peso_poblacion >= 1 THEN 'Más que su peso en población' ELSE 'Menos que su peso en población' END AS grupo
FROM mother.industria_productos_ue
WHERE es_ultimo_anio
ORDER BY cuota_cantidad_pct DESC
```

```sql prod_res
SELECT
    CAST(max(anio) AS INTEGER) AS anio,
    CAST(count(*) FILTER (WHERE puesto = 1) AS INTEGER) AS n_primeros,
    CAST(count(*) AS INTEGER) AS n_productos,
    max(cuota_cantidad_pct) FILTER (WHERE producto = '23311000') AS az_cuota,
    max(puesto) FILTER (WHERE producto = '23311000') AS az_puesto,
    max(n_paises) FILTER (WHERE producto = '23311000') AS az_n,
    max(cantidad_es_legible) FILTER (WHERE producto = '23311000') AS az_mm2,
    max(cantidad_por_1000_hab_es) FILTER (WHERE producto = '23311000') AS az_m2_1000,
    max(cuota_valor_pct) FILTER (WHERE producto = '23311000') AS az_cuota_valor,
    max(veces_peso_poblacion) FILTER (WHERE producto = '23311000') AS az_veces,
    max(cuota_cantidad_pct) FILTER (WHERE producto = '20302150') AS fri_cuota,
    max(n_paises) FILTER (WHERE producto = '20302150') AS fri_n,
    max(cuota_cantidad_pct) FILTER (WHERE producto = '10412210') AS ac_cuota,
    max(n_paises) FILTER (WHERE producto = '10412210') AS ac_n,
    max(cantidad_es_legible) FILTER (WHERE producto = '10412210') AS ac_kt,
    max(cuota_cantidad_pct) FILTER (WHERE producto = '10391770') AS acei_cuota,
    max(cuota_cantidad_pct) FILTER (WHERE producto = '10131120') AS jam_cuota,
    max(n_paises) FILTER (WHERE producto = '10131120') AS jam_n,
    max(puesto) FILTER (WHERE producto = '10131120') AS jam_puesto,
    max(cantidad_es_legible) FILTER (WHERE producto = '10131120') AS jam_kt,
    max(cuota_cantidad_pct) FILTER (WHERE producto = '11021190') AS cava_cuota,
    max(puesto) FILTER (WHERE producto = '11021190') AS cava_puesto,
    max(n_paises) FILTER (WHERE producto = '11021190') AS cava_n,
    max(lider) FILTER (WHERE producto = '11021190') AS cava_lider,
    max(cuota_cantidad_pct) FILTER (WHERE producto = '30203200') AS tren_cuota,
    max(puesto) FILTER (WHERE producto = '30203200') AS tren_puesto,
    max(n_paises) FILTER (WHERE producto = '30203200') AS tren_n,
    max(cantidad_es_legible) FILTER (WHERE producto = '30203200') AS tren_uds,
    max(cuota_cantidad_pct) FILTER (WHERE producto = '25112200') AS tor_cuota,
    max(puesto) FILTER (WHERE producto = '25112200') AS tor_puesto,
    max(n_paises) FILTER (WHERE producto = '25112200') AS tor_n,
    max(cantidad_es_legible) FILTER (WHERE producto = '25112200') AS tor_kt,
    max(cuota_cantidad_pct) FILTER (WHERE producto = '28112400') AS aero_cuota,
    max(puesto) FILTER (WHERE producto = '28112400') AS aero_puesto,
    max(n_paises) FILTER (WHERE producto = '28112400') AS aero_n,
    max(lider) FILTER (WHERE producto = '28112400') AS aero_lider,
    max(cantidad_es_legible) FILTER (WHERE producto = '28112400') AS aero_uds,
    max(cuota_cantidad_pct) FILTER (WHERE producto = '29102100') AS tg_cuota,
    max(n_paises) FILTER (WHERE producto = '29102100') AS tg_n,
    max(cuota_cantidad_pct) FILTER (WHERE producto = '29102450') AS tel_cuota,
    max(puesto) FILTER (WHERE producto = '29102450') AS tel_puesto,
    max(n_paises) FILTER (WHERE producto = '29102450') AS tel_n,
    max(cuota_cantidad_pct) FILTER (WHERE producto = '23511210') AS cem_cuota,
    max(puesto) FILTER (WHERE producto = '23511210') AS cem_puesto,
    max(n_paises) FILTER (WHERE producto = '23511210') AS cem_n,
    max(cuota_cantidad_pct) FILTER (WHERE producto = '30113130') AS pes_cuota,
    max(n_paises) FILTER (WHERE producto = '30113130') AS pes_n
FROM ${productos}
```

```sql azulejos
SELECT CAST(anio AS INTEGER) AS anio, cuota_cantidad_pct, cuota_valor_pct, cantidad_por_1000_hab_es,
       cantidad_es_legible, CAST(n_paises_cantidad AS INTEGER) AS n_paises
FROM mother.industria_productos_ue
WHERE producto = '23311000' AND cuota_cantidad_pct IS NOT NULL
ORDER BY anio
```

```sql ceramica_ccaa
SELECT t.nombre AS comunidad, r.cuota_espana_pct, r.veces_peso_poblacion, r.peso_en_industria_ccaa_pct, CAST(r.puesto_en_espana AS INTEGER) AS puesto
FROM mother.industria_ccaa_ramas r
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = r.cod_ccaa
WHERE r.rama = 'Fabricación de otros productos minerales no metálicos'
  AND r.anio = (SELECT max(anio) FROM mother.industria_ccaa_ramas)
ORDER BY r.cuota_espana_pct DESC
LIMIT 1
```

```sql otros
SELECT producto_nombre AS nombre, 'Producto (Prodcom, cantidad)' AS tipo, cuota_cantidad_pct AS cuota, puesto_txt, lider, veces_peso_poblacion
FROM ${productos}
WHERE producto IN ('30203200', '25112200', '28112400', '30113130', '23511210', '22111100', '24422250')
UNION ALL
SELECT rama_nombre AS nombre, 'Rama (cifra de negocios)' AS tipo, cuota_cifra_negocios_pct AS cuota, puesto_txt, lider, veces_peso_poblacion
FROM ${ramas}
WHERE rama IN ('C302', 'C303', 'C19', 'C2811', 'C301', 'C20', 'C21')
ORDER BY cuota DESC
```

```sql peso_serie
SELECT CAST(anio AS INTEGER) AS anio, pais_nombre AS pais, pct_vab_manufacturas, pct_empleo_manufacturas, vab_manuf_real_indice
FROM mother.industria_peso_ue
WHERE es_referencia AND pct_vab_manufacturas IS NOT NULL
ORDER BY anio, pais
```

```sql peso_es
SELECT CAST(anio AS INTEGER) AS anio, pct_vab_manufacturas, pct_vab_industria, pct_empleo_manufacturas, vab_manuf_hab_eur_real
FROM mother.industria_peso_ue
WHERE pais = 'ES' AND pct_vab_manufacturas IS NOT NULL
ORDER BY anio
```

```sql peso_ult
SELECT pais_nombre AS pais, pct_vab_manufacturas, pct_vab_industria, pct_empleo_manufacturas, pct_empleo_industria,
       CAST(puesto_manufacturas AS INTEGER) AS puesto, vab_manuf_hab_eur,
       CASE WHEN pais = 'ES' THEN 'España' WHEN pais = 'EU27_2020' THEN 'Media UE' ELSE 'Otros países' END AS grupo
FROM mother.industria_peso_ue
WHERE anio = (SELECT max(anio) FROM mother.industria_peso_ue WHERE pais = 'ES' AND pct_vab_manufacturas IS NOT NULL)
ORDER BY pct_vab_manufacturas DESC
```

```sql peso_res
WITH u AS (SELECT max(anio) AS a FROM mother.industria_peso_ue WHERE pais = 'ES' AND pct_vab_manufacturas IS NOT NULL)
SELECT
    CAST((SELECT a FROM u) AS INTEGER) AS anio,
    max(pct_vab_manufacturas) FILTER (WHERE pais = 'ES' AND anio = (SELECT a FROM u)) AS es_manuf,
    max(pct_vab_manufacturas) FILTER (WHERE pais = 'EU27_2020' AND anio = (SELECT a FROM u)) AS ue_manuf,
    max(pct_vab_manufacturas) FILTER (WHERE pais = 'ES' AND anio = (SELECT a FROM u))
        - max(pct_vab_manufacturas) FILTER (WHERE pais = 'EU27_2020' AND anio = (SELECT a FROM u)) AS dif_manuf,
    max(pct_vab_industria) FILTER (WHERE pais = 'ES' AND anio = (SELECT a FROM u)) AS es_ind,
    max(pct_vab_industria) FILTER (WHERE pais = 'EU27_2020' AND anio = (SELECT a FROM u)) AS ue_ind,
    max(pct_empleo_manufacturas) FILTER (WHERE pais = 'ES' AND anio = (SELECT a FROM u)) AS es_emp,
    max(pct_empleo_manufacturas) FILTER (WHERE pais = 'EU27_2020' AND anio = (SELECT a FROM u)) AS ue_emp,
    max(pct_empleo_industria) FILTER (WHERE pais = 'ES' AND anio = (SELECT a FROM u)) AS es_emp_ind,
    max(pct_empleo_industria) FILTER (WHERE pais = 'EU27_2020' AND anio = (SELECT a FROM u)) AS ue_emp_ind,
    CAST(max(puesto_manufacturas) FILTER (WHERE pais = 'ES' AND anio = (SELECT a FROM u)) AS INTEGER) AS es_puesto,
    CAST(max(n_paises) FILTER (WHERE pais = 'ES' AND anio = (SELECT a FROM u)) AS INTEGER) AS n_paises,
    max(pct_vab_manufacturas) FILTER (WHERE pais = 'ES' AND anio = 1995) AS es_manuf_1995,
    max(pct_vab_manufacturas) FILTER (WHERE pais = 'EU27_2020' AND anio = 1995) AS ue_manuf_1995,
    max(vab_manuf_hab_eur) FILTER (WHERE pais = 'ES' AND anio = (SELECT a FROM u)) AS es_hab,
    max(vab_manuf_hab_eur) FILTER (WHERE pais = 'EU27_2020' AND anio = (SELECT a FROM u)) AS ue_hab,
    100 * max(vab_manuf_hab_eur) FILTER (WHERE pais = 'ES' AND anio = (SELECT a FROM u))
        / max(vab_manuf_hab_eur) FILTER (WHERE pais = 'EU27_2020' AND anio = (SELECT a FROM u)) AS es_hab_pct_ue,
    max(vab_manuf_hab_eur_real) FILTER (WHERE pais = 'ES' AND anio = 2008) AS es_hab_real_2008,
    max(vab_manuf_hab_eur_real) FILTER (WHERE pais = 'ES' AND anio = (SELECT a FROM u)) AS es_hab_real,
    100 * (max(vab_manuf_hab_eur_real) FILTER (WHERE pais = 'ES' AND anio = (SELECT a FROM u))
        / max(vab_manuf_hab_eur_real) FILTER (WHERE pais = 'ES' AND anio = 2008) - 1) AS es_hab_real_var_2008,
    max(cuota_vab_manuf_ue_pct) FILTER (WHERE pais = 'ES' AND anio = (SELECT a FROM u)) AS es_cuota_vab,
    max(cuota_poblacion_ue_pct) FILTER (WHERE pais = 'ES' AND anio = (SELECT a FROM u)) AS es_cuota_pob,
    max(vab_manuf_real_indice) FILTER (WHERE pais = 'ES' AND anio = (SELECT a FROM u)) AS es_vol,
    max(vab_manuf_real_indice) FILTER (WHERE pais = 'EU27_2020' AND anio = (SELECT a FROM u)) AS ue_vol,
    max(vab_manuf_real_indice) FILTER (WHERE pais = 'ES' AND anio = 2008) AS es_vol_2008,
    max(vab_manuf_real_indice) FILTER (WHERE pais = 'EU27_2020' AND anio = 2008) AS ue_vol_2008
FROM mother.industria_peso_ue
```

```sql ipi_anual
SELECT CAST(anio AS INTEGER) AS anio, pais, indice
FROM mother.industria_ipi_paises
WHERE rama = 'B-D' AND cod_pais IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT') AND anio >= 2005
ORDER BY anio, pais
```

```sql ipi_res
WITH e AS (SELECT * FROM mother.industria_ipi_paises WHERE rama = 'B-D'),
     u AS (SELECT max(anio) AS a FROM e WHERE cod_pais = 'ES')
SELECT
    CAST((SELECT a FROM u) AS INTEGER) AS anio,
    max(indice) FILTER (WHERE cod_pais = 'ES' AND anio = (SELECT a FROM u)) AS es,
    max(indice) FILTER (WHERE cod_pais = 'EU27_2020' AND anio = (SELECT a FROM u)) AS ue,
    max(variacion_anual_pct) FILTER (WHERE cod_pais = 'ES' AND anio = (SELECT a FROM u)) AS es_var,
    max(variacion_anual_pct) FILTER (WHERE cod_pais = 'EU27_2020' AND anio = (SELECT a FROM u)) AS ue_var,
    100 * (max(indice) FILTER (WHERE cod_pais = 'ES' AND anio = (SELECT a FROM u)) / max(indice) FILTER (WHERE cod_pais = 'ES' AND anio = 2019) - 1) AS es_var_2019,
    100 * (max(indice) FILTER (WHERE cod_pais = 'EU27_2020' AND anio = (SELECT a FROM u)) / max(indice) FILTER (WHERE cod_pais = 'EU27_2020' AND anio = 2019) - 1) AS ue_var_2019,
    100 * (max(indice) FILTER (WHERE cod_pais = 'ES' AND anio = (SELECT a FROM u)) / max(indice) FILTER (WHERE cod_pais = 'ES' AND anio = 2007) - 1) AS es_var_2007,
    100 * (max(indice) FILTER (WHERE cod_pais = 'EU27_2020' AND anio = (SELECT a FROM u)) / max(indice) FILTER (WHERE cod_pais = 'EU27_2020' AND anio = 2007) - 1) AS ue_var_2007
FROM e
```

```sql ipi_mes
SELECT fecha AS mes, indice, variacion_anual_pct, variacion_acumulada_pct,
       list_extract(['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'], month(fecha))
           || ' de ' || CAST(year(fecha) AS VARCHAR) AS mes_txt
FROM mother.industria_ipi_mensual
WHERE nivel = 'pais' AND destino = 'Total industria' AND indice IS NOT NULL
  AND fecha > (SELECT max(fecha) FROM mother.industria_ipi_mensual) - INTERVAL 36 MONTH
ORDER BY mes
```

```sql ipi_ult
SELECT * FROM ${ipi_mes} ORDER BY mes DESC LIMIT 1
```

```sql ipi_destinos
SELECT destino, variacion_anual_pct, variacion_acumulada_pct
FROM mother.industria_ipi_mensual
WHERE nivel = 'pais' AND es_ultimo_mes AND destino <> 'Total industria'
ORDER BY variacion_acumulada_pct DESC
```

```sql exportaciones
SELECT partida, partida_nombre, CAST(anio AS INTEGER) AS anio, cuota_pct, CAST(puesto AS INTEGER) AS puesto,
       CAST(puesto_sin_nl_be AS INTEGER) AS puesto_sin_nl_be, lider_nombre AS lider, cuota_nl_be_pct,
       veces_peso_poblacion, exportacion_es_real_meur, exportacion_es_real_eur_hab, peso_en_exportacion_es_pct,
       CASE WHEN veces_peso_poblacion >= 1 THEN 'Más que su peso en población' ELSE 'Menos que su peso en población' END AS grupo
FROM mother.industria_exportaciones_ue
WHERE es_ultimo_anio AND destino = 'WORLD' AND partida <> 'TOTAL'
ORDER BY cuota_pct DESC
```

```sql exp_res
SELECT
    CAST(max(anio) AS INTEGER) AS anio,
    max(cuota_pct) FILTER (WHERE partida = 'TOTAL' AND destino = 'WORLD') AS tot_cuota,
    CAST(max(puesto) FILTER (WHERE partida = 'TOTAL' AND destino = 'WORLD') AS INTEGER) AS tot_puesto,
    CAST(max(puesto_sin_nl_be) FILTER (WHERE partida = 'TOTAL' AND destino = 'WORLD') AS INTEGER) AS tot_puesto_sin,
    max(cuota_nl_be_pct) FILTER (WHERE partida = 'TOTAL' AND destino = 'WORLD') AS tot_nl_be,
    max(cuota_poblacion_pct) FILTER (WHERE partida = 'TOTAL' AND destino = 'WORLD') AS cuota_pob,
    max(exportacion_es_real_meur) FILTER (WHERE partida = 'TOTAL' AND destino = 'WORLD') / 1000 AS tot_real_mm,
    max(cuota_pct) FILTER (WHERE partida = 'TOTAL' AND destino = 'EXT_EU27_2020') AS ext_cuota,
    CAST(max(puesto) FILTER (WHERE partida = 'TOTAL' AND destino = 'EXT_EU27_2020') AS INTEGER) AS ext_puesto,
    max(cuota_pct) FILTER (WHERE partida = '1509' AND destino = 'WORLD') AS ace_cuota,
    max(cuota_pct) FILTER (WHERE partida = '6907' AND destino = 'WORLD') AS az_cuota,
    CAST(max(puesto) FILTER (WHERE partida = '6907' AND destino = 'WORLD') AS INTEGER) AS az_puesto,
    max(lider_nombre) FILTER (WHERE partida = '6907' AND destino = 'WORLD') AS az_lider,
    max(cuota_pct) FILTER (WHERE partida = '3207' AND destino = 'WORLD') AS fri_cuota,
    max(cuota_pct) FILTER (WHERE partida = '8605' AND destino = 'WORLD') AS tren_cuota,
    CAST(max(puesto) FILTER (WHERE partida = '8605' AND destino = 'WORLD') AS INTEGER) AS tren_puesto,
    max(cuota_pct) FILTER (WHERE partida = '8703' AND destino = 'WORLD') AS tur_cuota,
    CAST(max(puesto) FILTER (WHERE partida = '8703' AND destino = 'WORLD') AS INTEGER) AS tur_puesto,
    CAST(max(puesto_sin_nl_be) FILTER (WHERE partida = '8703' AND destino = 'WORLD') AS INTEGER) AS tur_puesto_sin,
    max(peso_en_exportacion_es_pct) FILTER (WHERE partida = '87' AND destino = 'WORLD') AS veh_peso,
    max(cuota_pct) FILTER (WHERE partida = '2710' AND destino = 'WORLD') AS ref_cuota,
    CAST(max(puesto) FILTER (WHERE partida = '2710' AND destino = 'WORLD') AS INTEGER) AS ref_puesto,
    CAST(max(puesto_sin_nl_be) FILTER (WHERE partida = '2710' AND destino = 'WORLD') AS INTEGER) AS ref_puesto_sin,
    max(cuota_nl_be_pct) FILTER (WHERE partida = '2710' AND destino = 'WORLD') AS ref_nl_be
FROM mother.industria_exportaciones_ue
WHERE es_ultimo_anio
```

```sql ccaa
SELECT c.cod_ccaa, c.ccaa AS comunidad, '/en' || t.ruta AS ruta, CAST(c.anio AS INTEGER) AS anio, c.pct_vab_industria, c.pct_vab_manufacturas,
       CAST(c.puesto_pct_vab_industria AS INTEGER) AS puesto, c.vab_industria_hab_real, c.cifra_negocios_hab_real,
       c.ocupados_industria_1000_hab, c.cuota_vab_industria_espana_pct
FROM mother.industria_ccaa c
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = c.cod_ccaa
WHERE c.cod_ccaa <> '00'
  AND c.anio = (SELECT max(anio) FROM mother.industria_ccaa WHERE pct_vab_industria IS NOT NULL AND cod_ccaa <> '00')
ORDER BY c.pct_vab_industria DESC
```

```sql ccaa_res
SELECT
    CAST(max(anio) AS INTEGER) AS anio,
    string_agg(comunidad || ' (' || replace(CAST(round(pct_vab_industria, 1) AS VARCHAR), '.', ',') || ' %)', ', ' ORDER BY pct_vab_industria DESC) FILTER (WHERE puesto <= 4) AS mas,
    string_agg(comunidad, ', ' ORDER BY pct_vab_industria) FILTER (WHERE puesto >= 14 AND cod_ccaa NOT IN ('18', '19')) AS menos,
    max(pct_vab_industria) FILTER (WHERE cod_ccaa = '15') AS navarra,
    max(ocupados_industria_1000_hab) FILTER (WHERE cod_ccaa = '15') AS navarra_ocup,
    max(cuota_vab_industria_espana_pct) FILTER (WHERE cod_ccaa = '09') AS cat_cuota,
    max(pct_vab_industria) FILTER (WHERE cod_ccaa = '13') AS madrid,
    CAST(count(*) FILTER (WHERE pct_vab_industria > (SELECT pct_vab_industria FROM mother.industria_ccaa WHERE cod_ccaa = '00' AND anio = (SELECT max(anio) FROM ${ccaa}))) AS INTEGER) AS n_sobre_media
FROM ${ccaa}
```

```sql ccaa_espana
SELECT pct_vab_industria, pct_vab_manufacturas, ocupados_industria_1000_hab, vab_industria_hab_real
FROM mother.industria_ccaa
WHERE cod_ccaa = '00' AND anio = (SELECT max(anio) FROM mother.industria_ccaa WHERE pct_vab_industria IS NOT NULL AND cod_ccaa = '00')
```

```sql ccaa_ramas
WITH r AS (
    SELECT cod_ccaa, rama, peso_en_industria_ccaa_pct, veces_peso_poblacion, cuota_espana_pct, n_ccaa_con_dato
    FROM mother.industria_ccaa_ramas
    WHERE anio = (SELECT max(anio) FROM mother.industria_ccaa_ramas)
      AND NOT es_agregado
      AND rama NOT LIKE 'Suministro de agua%'
      AND cod_ccaa NOT IN ('18', '19')
),
principal AS (
    SELECT cod_ccaa, arg_max(rama, peso_en_industria_ccaa_pct) AS rama_principal, max(peso_en_industria_ccaa_pct) AS peso_principal
    FROM r GROUP BY 1
),
especial AS (
    SELECT cod_ccaa, arg_max(rama, veces_peso_poblacion) AS rama_especial, max(veces_peso_poblacion) AS veces,
           arg_max(cuota_espana_pct, veces_peso_poblacion) AS cuota_especial
    FROM r WHERE n_ccaa_con_dato >= 10 AND peso_en_industria_ccaa_pct >= 5
    GROUP BY 1
)
SELECT t.nombre AS comunidad, '/en' || t.ruta AS ruta, p.rama_principal, p.peso_principal, e.rama_especial, e.veces, e.cuota_especial
FROM principal p
LEFT JOIN especial e USING (cod_ccaa)
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = p.cod_ccaa
ORDER BY p.peso_principal DESC
```

```sql ccaa_ramas_anio
SELECT CAST(max(anio) AS INTEGER) AS anio FROM mother.industria_ccaa_ramas
```

# 🏭 Industry

Spain is not among the most industrial countries in the European Union: its manufacturing weighs less in the economy than the European average. But for some products it is a leading power, from cars and tiles to olive oil, cured ham, railway equipment and wind turbine towers. This page shows both sides with data from Eurostat, the INE, OICA and ANFAC, always in proportion to population or to the European total.

<Grid cols=4>
    <KpiCard
        title="Vehicles manufactured"
        value={veh_res[0]?.veh_1000}
        formattedValue="{formatNumber(veh_res[0]?.veh_1000, 1)} per 1,000 inhab."
        period="{veh_res[0]?.anio} · {formatNumber(veh_res[0]?.vehiculos_millones, 2)} million · {ord(veh_res[0]?.puesto_europa)} in Europe (OICA {veh_res[0]?.anio_oica})"
        change={veh_res[0]?.var_anual?.toFixed(1)}
        changePeriod="vs {veh_res[0]?.anio_ant}"
        direction="positive-up"
        source="OICA and ANFAC"
        sparklineData={veh.map(d => d.vehiculos_1000_hab)}
    />
    <KpiCard
        title="Tiles: share of EU production"
        value={prod_res[0]?.az_cuota}
        formattedValue="{formatNumber(prod_res[0]?.az_cuota, 1)} %"
        period="{prod_res[0]?.anio} · in m² · {ord(prod_res[0]?.az_puesto)} of the {prod_res[0]?.az_n} countries that publish the figure"
        direction="positive-up"
        source="Eurostat (Prodcom)"
        sparklineData={azulejos.map(d => d.cuota_cantidad_pct)}
    />
    <KpiCard
        title="Manufacturing's share of the economy"
        value={peso_res[0]?.es_manuf}
        formattedValue="{formatNumber(peso_res[0]?.es_manuf, 1)} % of GVA"
        period="{peso_res[0]?.anio} · EU: {formatNumber(peso_res[0]?.ue_manuf, 1)} % · rank {peso_res[0]?.es_puesto} of {peso_res[0]?.n_paises}"
        change={peso_res[0]?.dif_manuf?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs the EU"
        direction="positive-up"
        source="Eurostat (nama_10_a10)"
        sparklineData={peso_es.map(d => d.pct_vab_manufacturas)}
    />
    <KpiCard
        title="Industrial production index"
        value={ipi_ult[0]?.indice}
        formattedValue={formatNumber(ipi_ult[0]?.indice, 1)}
        period="{mesEn(ipi_ult[0]?.mes_txt)} · base 2021 = 100 · unadjusted index"
        change={ipi_ult[0]?.variacion_anual_pct?.toFixed(1)}
        changePeriod="year on year"
        direction="positive-up"
        source="INE (IPI, table 70177)"
        sparklineData={ipi_mes.map(d => d.indice)}
    />
</Grid>

## Where Spain stands out

Spain has {formatNumber(ramas_res[0]?.cuota_pob, 1)} % of the EU's population. If a Spanish industrial branch has a turnover above that proportion of the European total, Spain produces more than its population would suggest; the ratio («times its population weight») sums it up: 1 is what would be expected, 2 is double. For manufacturing as a whole the share is {formatNumber(ramas_res[0]?.c_cuota, 1)} % ({ord(ramas_res[0]?.c_puesto)} in the EU by turnover), below its population weight. Only {ramas_res[0]?.n_por_encima} of the {ramas_res[0]?.n_ramas} branches in the table exceed it, and the one that stands out most is **ceramic wall and floor tiles**: {formatNumber(ramas_res[0]?.az_cuota, 1)} % of European turnover, {formatNumber(ramas_res[0]?.az_veces, 1)} times its population weight.

<BarChart
    data={ramas}
    x=rama_nombre
    y=cuota_cifra_negocios_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% of EU turnover"
    seriesColors={{'Más que su peso en población': '#c2410c', 'Menos que su peso en población': '#94a3b8'}}
    title="Spain's share of the turnover of each EU industrial branch ({ramas_res[0]?.anio}, %)"
/>

<DataTable data={ramas} rows=12 search=true>
    <Column id=rama_nombre title="Branch" />
    <Column id=cuota_cifra_negocios_pct title="EU share %" fmt='0.0' />
    <Column id=veces_peso_poblacion title="Times its population weight" fmt='0.00' />
    <Column id=puesto_txt title="Rank (among those publishing)" />
    <Column id=lider title="Leading country" />
    <Column id=peso_manuf_es_pct title="Share of Spain's manufacturing %" fmt='0.0' />
    <Column id=peso_manuf_ue_pct title="Share of EU manufacturing %" fmt='0.0' />
    <Column id=cifra_negocios_es_real_meur title="Spain's turnover (2025 € million)" fmt='#,##0' />
</DataTable>

Branches are measured by company turnover (Eurostat, structural business statistics). The EU total is Eurostat's estimate, which includes countries with confidential data; the rank, on the other hand, can only be calculated among the countries that publish the figure, so, for example, «2.º de 19» means second of the 19 that publish it.

### Specific products

Industrial production statistics (Prodcom) go down to the detail of each product, in physical units: square metres, tonnes, units. Spain is the leading producer of {prod_res[0]?.n_primeros} of the {prod_res[0]?.n_productos} products on the list, with shares of more than half of European production in ceramic glazes and frits ({formatNumber(prod_res[0]?.fri_cuota, 0)} %), table olives ({formatNumber(prod_res[0]?.acei_cuota, 0)} %) and virgin olive oil ({formatNumber(prod_res[0]?.ac_cuota, 0)} %).

**Watch out for two pitfalls.** The share is calculated over the **EU total estimated by Eurostat** (a rounded aggregate that includes the confidential production of countries that do not publish it), not over the sum of the countries with data, which would inflate it. And the **rank is only among the countries that publish the figure**: for many products there are few (for virgin olive oil, {prod_res[0]?.ac_n}; for ceramic frits, {prod_res[0]?.fri_n}), because the rest declare it confidential. Being first of five does not guarantee being first in the EU, although with a share above 50 % no other country can be larger.

<BarChart
    data={productos}
    x=producto_nombre
    y=cuota_cantidad_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% of EU production (by quantity)"
    seriesColors={{'Más que su peso en población': '#c2410c', 'Menos que su peso en población': '#94a3b8'}}
    title="Spain's share of EU production of each product ({prod_res[0]?.anio}, % by quantity)"
/>

<DataTable data={productos} rows=12 search=true>
    <Column id=producto_nombre title="Product" />
    <Column id=cuota_cantidad_pct title="EU share by quantity %" fmt='0.0' />
    <Column id=cuota_valor_pct title="EU share by value %" fmt='0.0' />
    <Column id=veces_peso_poblacion title="Times its population weight" fmt='0.00' />
    <Column id=puesto_txt title="Rank (among those publishing)" />
    <Column id=lider title="Largest producer with data" />
    <Column id=cantidad_es_legible title="Spain's production" fmt='#,##0.0' />
    <Column id=unidad_legible title="Unit" />
    <Column id=valor_es_real_meur title="Spain's value (2025 € million)" fmt='#,##0' />
</DataTable>

## The car industry

Spain manufactured **{formatNumber(veh_res[0]?.vehiculos_millones, 2)} million vehicles in {veh_res[0]?.anio}**, {formatNumber(veh_res[0]?.veh_1000, 1)} per 1,000 inhabitants, {#if veh_res[0]?.var_anual < 0}{formatNumber(-veh_res[0]?.var_anual, 1)} % fewer{:else}{formatNumber(veh_res[0]?.var_anual, 1)} % more{/if} than in {veh_res[0]?.anio_ant} and {#if veh_res[0]?.var_2019 < 0}{formatNumber(-veh_res[0]?.var_2019, 1)} % fewer{:else}{formatNumber(veh_res[0]?.var_2019, 1)} % more{/if} than in 2019, when {formatNumber(veh_res[0]?.veh_2019_millones, 2)} million left its factories. It exported **{formatNumber(veh_res[0]?.pct_exportado, 1)} %** of what it produced in {veh_res[0]?.anio_exportado}. In the latest year with data for all countries ({veh_res[0]?.anio_oica}) it was the **{ord(veh_res[0]?.puesto_europa)} largest manufacturer in Europe**, behind only Germany, and the **{ord(veh_res[0]?.puesto_mundo)} in the world**, with {formatNumber(veh_res[0]?.cuota_mundo, 1)} % of world production. For {veh_res[0]?.anio} only the Spanish figure is available; ANFAC, the industry association, says it holds both positions.

<BarChart
    data={veh}
    x=anio
    y=vehiculos_1000_hab
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="vehicles per 1,000 inhabitants"
    title="Vehicles manufactured in Spain per 1,000 inhabitants (2020 missing from the series)"
/>

<LineChart
    data={veh}
    x=anio
    y=puesto_europa
    y2=puesto_mundo
    xFmt='0'
    yFmt='0'
    markers=true
    yAxisTitle="rank in Europe"
    y2AxisTitle="rank in the world"
    title="Spain's rank among vehicle manufacturers in Europe and the world (OICA)"
/>

In proportion to population, the countries that manufacture the most vehicles are Slovakia ({formatNumber(veh_lideres[0]?.sk_1000, 0)} per 1,000 inhabitants) and Czechia ({formatNumber(veh_lideres[0]?.cz_1000, 0)}). Spain ({formatNumber(veh_res[0]?.veh_1000_oica, 1)}) is on a par with Germany ({formatNumber(veh_lideres[0]?.de_1000, 1)}), although OICA's German figure only counts cars, and well above France ({formatNumber(veh_lideres[0]?.fr_1000, 1)}, excluding lorries and buses) or Italy ({formatNumber(veh_lideres[0]?.it_1000, 1)}).

<BarChart
    data={veh_europa_hab}
    x=pais
    y=vehiculos_1000_hab
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="vehicles per 1,000 inhabitants"
    seriesColors={{'España': '#c2410c', 'Otros países': '#94a3b8'}}
    title="Vehicles manufactured per 1,000 inhabitants among EU manufacturers ({veh_res[0]?.anio_oica})"
/>

<DataTable data={veh_europa} rows=15>
    <Column id=puesto_europa title="Rank in Europe" />
    <Column id=pais title="Country" />
    <Column id=vehiculos title="Vehicles manufactured" fmt='#,##0' />
    <Column id=vehiculos_1000_hab title="Per 1,000 inhab." fmt='0.0' />
    <Column id=puesto_mundo title="Rank in the world" />
    <Column id=cobertura title="What OICA counts" />
</DataTable>

### The factories

ANFAC lists {fab_res[0]?.plantas} vehicle and component factories in {fab_res[0]?.comunidades} regions; {fab_res[0]?.plantas_montaje} assemble vehicles, with {fab_res[0]?.modelos} models in production ({fab_res[0]?.electrificados} of them electric or hybrid) and {fab_res[0]?.adjudicados} more allocated for the coming years. The one that builds the most models is {fab_res[0]?.mas_modelos} ({fab_res[0]?.max_modelos}). By turnover of the branch, the regions with the largest share of vehicle manufacturing are {veh_ccaa_txt[0]?.lista} of the Spanish total.

<MapaEspana
    data={fabricas}
    lat=lat
    long=lon
    size=tamano
    maxSize={22}
    value=categoria
    legendType=categorical
    colorPalette={['#c2410c', '#2563eb', '#64748b']}
    opacity={0.8}
    pointName=fabrica
    height={520}
    tooltip={[
        {id: 'fabrica', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'grupo', title: 'Group'},
        {id: 'tipo', title: 'What it makes'},
        {id: 'municipio', title: 'Municipality'},
        {id: 'n_modelos', title: 'Models in production', fmt: '0'},
        {id: 'modelos', title: 'Models'}
    ]}
/>

The size of the dot is the number of models in production; the position is that of the municipality (the two factories in Barcelona and the two in Madrid overlap).

<DataTable data={fabricas} rows=16 search=true>
    <Column id=fabrica title="Factory" />
    <Column id=grupo title="Group" />
    <Column id=tipo title="What it makes" />
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=modelos title="Models in production" />
    <Column id=modelos_adjudicados title="Models allocated" />
    <Column id=otras_producciones title="Other production" />
</DataTable>

## Tiles and ceramics

Spain produced **{formatNumber(prod_res[0]?.az_mm2, 0)} million m² of ceramic tiles in {prod_res[0]?.anio}**, some {formatNumber(prod_res[0]?.az_m2_1000, 0)} m² per 1,000 inhabitants: {formatNumber(prod_res[0]?.az_cuota, 1)} % of European production by area ({formatNumber(prod_res[0]?.az_veces, 1)} times its population weight) and {formatNumber(prod_res[0]?.az_cuota_valor, 1)} % by value. It ranks 1st of the {prod_res[0]?.az_n} countries that publish the figure. As its share by value is lower than by area, the average price of its output per m² is lower than the European average. By turnover of the branch (Eurostat, businesses) Spain ranks {ord(ramas_res[0]?.az_puesto)} of {ramas_res[0]?.az_n} countries with data, with {formatNumber(ramas_res[0]?.az_cuota, 1)} %; first is {ramas_res[0]?.az_lider}. The frits and glazes used to coat the tiles are also a Spanish speciality: {formatNumber(prod_res[0]?.fri_cuota, 0)} % of EU production.

The non-metallic minerals branch (ceramics, glass, cement) is highly concentrated: {ceramica_ccaa[0]?.comunidad} accounts for {formatNumber(ceramica_ccaa[0]?.cuota_espana_pct, 0)} % of its turnover in Spain, {formatNumber(ceramica_ccaa[0]?.veces_peso_poblacion, 1)} times its population weight.

<LineChart
    data={azulejos}
    x=anio
    y=cuota_cantidad_pct
    y2=cuota_valor_pct
    xFmt='0'
    yFmt='0.0'
    y2Fmt='0.0'
    markers=true
    yAxisTitle="% of the EU in m²"
    y2AxisTitle="% of the EU by value"
    title="Spain's share of EU production of wall and floor tiles (%)"
/>

## Food and drink

Food is **Spain's largest manufacturing branch**: {formatNumber(ramas_res[0]?.ali_peso_es, 1)} % of the value added of its manufacturing, compared with {formatNumber(ramas_res[0]?.ali_peso_ue, 1)} % in the EU{#if ramas_rank[0]?.ali_puesto_ue > 1}, where it ranks {ord(ramas_rank[0]?.ali_puesto_ue)} (first is {ramas_rank[0]?.primera_ue}, with {formatNumber(ramas_rank[0]?.primera_ue_peso, 1)} %){/if}. Its companies account for {formatNumber(ramas_res[0]?.ali_cuota, 1)} % of European food turnover ({ord(ramas_res[0]?.ali_puesto)} country; first is {ramas_res[0]?.ali_lider}). Beverages weigh {formatNumber(ramas_res[0]?.beb_peso_es, 1)} % compared with {formatNumber(ramas_res[0]?.beb_peso_ue, 1)} % and make up {formatNumber(ramas_res[0]?.beb_cuota, 1)} % of the EU.

For specific products, Spain produces {formatNumber(prod_res[0]?.ac_cuota, 0)} % of the EU's virgin olive oil ({formatNumber(prod_res[0]?.ac_kt, 0)} thousand tonnes), {formatNumber(prod_res[0]?.acei_cuota, 0)} % of table olives and {formatNumber(prod_res[0]?.jam_cuota, 0)} % of bone-in cured hams and shoulders ({ord(prod_res[0]?.jam_puesto)} of {prod_res[0]?.jam_n} countries with data). In sparkling wine it ranks {ord(prod_res[0]?.cava_puesto)} of {prod_res[0]?.cava_n}, with {formatNumber(prod_res[0]?.cava_cuota, 0)} % (champagne is not included in this code).

<BarChart
    data={ramas_peso}
    x=rama_nombre
    y=peso
    series=territorio
    type=grouped
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% of manufacturing value added"
    seriesColors={{'España': '#c2410c', 'Unión Europea': '#64748b'}}
    title="Share of each branch in manufacturing: Spain compared with the EU ({ramas_res[0]?.anio}, % of value added)"
/>

The chart also shows where the difference with Europe lies: Spain has much less weight in **machinery**, **pharmaceuticals** and **electronics**, branches in which its turnover is {formatNumber(ramas_res[0]?.maq_cuota, 1)} %, {formatNumber(ramas_res[0]?.far_cuota, 1)} % and {formatNumber(ramas_res[0]?.ele_cuota, 1)} % of the European total.

## Other strong sectors

- **Railway equipment.** The branch accounts for {formatNumber(ramas_res[0]?.fer_cuota, 1)} % of EU turnover ({ord(ramas_res[0]?.fer_puesto)} of {ramas_res[0]?.fer_n} countries with data, first is {ramas_res[0]?.fer_lider}; {formatNumber(ramas_res[0]?.fer_veces, 1)} times its population weight). In railway and tram passenger coaches, Spain manufactured {formatNumber(prod_res[0]?.tren_uds, 0)} units, {formatNumber(prod_res[0]?.tren_cuota, 0)} % of the European estimate (only {prod_res[0]?.tren_n} countries publish the figure), and it is the EU's {ord(exp_res[0]?.tren_puesto)} largest exporter, with {formatNumber(exp_res[0]?.tren_cuota, 0)} %.
- **Aerospace.** {formatNumber(ramas_res[0]?.aer_cuota, 1)} % of European turnover ({ord(ramas_res[0]?.aer_puesto)} of {ramas_res[0]?.aer_n} with data; led by {ramas_res[0]?.aer_lider}), somewhat below its population weight.
- **Oil refining.** {formatNumber(ramas_res[0]?.ref_cuota, 1)} % of the EU ({ord(ramas_res[0]?.ref_puesto)} of {ramas_res[0]?.ref_n} with data); it accounts for {formatNumber(ramas_res[0]?.ref_peso_es, 1)} % of Spanish manufacturing compared with {formatNumber(ramas_res[0]?.ref_peso_ue, 1)} % in the EU.
- **Renewables.** Spain manufactured {formatNumber(prod_res[0]?.tor_kt, 0)} thousand tonnes of steel towers and lattice masts, {formatNumber(prod_res[0]?.tor_cuota, 0)} % of the EU ({ord(prod_res[0]?.tor_puesto)} of {prod_res[0]?.tor_n} with data; the code includes wind towers and other lattice structures), and {formatNumber(prod_res[0]?.aero_uds, 0)} wind turbines, {formatNumber(prod_res[0]?.aero_cuota, 0)} % ({ord(prod_res[0]?.aero_puesto)} of only {prod_res[0]?.aero_n} that publish, behind {prod_res[0]?.aero_lider}). In the engines and turbines branch, which mixes wind turbines with other types of turbine, the share falls to {formatNumber(ramas_res[0]?.tur_cuota, 1)} %.
- **Fishing vessels and cement.** {formatNumber(prod_res[0]?.pes_cuota, 0)} % of the tonnage of fishing vessels built in the EU (out of {prod_res[0]?.pes_n} countries with data) and {formatNumber(prod_res[0]?.cem_cuota, 1)} % of Portland cement ({ord(prod_res[0]?.cem_puesto)} of {prod_res[0]?.cem_n}).

<DataTable data={otros} rows=14>
    <Column id=nombre title="Branch or product" />
    <Column id=tipo title="Measure" />
    <Column id=cuota title="EU share %" fmt='0.0' />
    <Column id=veces_peso_poblacion title="Times its population weight" fmt='0.00' />
    <Column id=puesto_txt title="Rank (among those publishing)" />
    <Column id=lider title="First with data" />
</DataTable>

## Industrial exports

Spain sells abroad (including to other EU countries) {formatNumber(exp_res[0]?.tot_cuota, 1)} % of all goods exports of the 27, below its {formatNumber(exp_res[0]?.cuota_pob, 1)} % of the population: {ord(exp_res[0]?.tot_puesto)} largest exporter in {exp_res[0]?.anio}, with {formatNumber(exp_res[0]?.tot_real_mm, 0)} billion 2025 euros. Outside the EU its share is {formatNumber(exp_res[0]?.ext_cuota, 1)} % ({ord(exp_res[0]?.ext_puesto)}). Where it does stand out is in olive oil ({formatNumber(exp_res[0]?.ace_cuota, 0)} % of what the EU exports), ceramic frits and glazes ({formatNumber(exp_res[0]?.fri_cuota, 0)} %), railway coaches ({formatNumber(exp_res[0]?.tren_cuota, 0)} %) and tiles ({formatNumber(exp_res[0]?.az_cuota, 0)} %, {ord(exp_res[0]?.az_puesto)} behind {exp_res[0]?.az_lider}). Cars are {formatNumber(exp_res[0]?.tur_cuota, 1)} % of the EU ({ord(exp_res[0]?.tur_puesto)}) and vehicles as a whole, {formatNumber(exp_res[0]?.veh_peso, 1)} % of everything Spain exports.

**The Netherlands and Belgium pitfall.** Rotterdam and Antwerp are Europe's gateway for goods, and whatever comes in through their ports and is re-sent to another country counts as their export even though they did not make it. Together they account for {formatNumber(exp_res[0]?.tot_nl_be, 1)} % of EU exports and {formatNumber(exp_res[0]?.ref_nl_be, 0)} % of exports of refined petroleum products. Leaving them out, Spain would be {ord(exp_res[0]?.tot_puesto_sin)} overall, {ord(exp_res[0]?.tur_puesto_sin)} in cars and {ord(exp_res[0]?.ref_puesto_sin)} in refined products (instead of {ord(exp_res[0]?.ref_puesto)}). The table gives both ranks.

<BarChart
    data={exportaciones}
    x=partida_nombre
    y=cuota_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% of the exports of the 27"
    seriesColors={{'Más que su peso en población': '#c2410c', 'Menos que su peso en población': '#94a3b8'}}
    title="Spain's share of EU exports by product ({exp_res[0]?.anio}, %, including intra-EU trade)"
/>

<DataTable data={exportaciones} rows=12 search=true>
    <Column id=partida_nombre title="Product" />
    <Column id=cuota_pct title="EU share %" fmt='0.0' />
    <Column id=puesto title="Rank" />
    <Column id=puesto_sin_nl_be title="Rank without NL or BE" />
    <Column id=lider title="Top exporter" />
    <Column id=cuota_nl_be_pct title="NL + BE, % of the EU" fmt='0.0' />
    <Column id=peso_en_exportacion_es_pct title="% of Spanish exports" fmt='0.00' />
    <Column id=exportacion_es_real_meur title="Spain's exports (2025 € million)" fmt='#,##0' />
    <Column id=exportacion_es_real_eur_hab title="Exports per person (2025 €)" fmt='#,##0' />
</DataTable>

## How much industry does Spain have?

Manufacturing generates **{formatNumber(peso_res[0]?.es_manuf, 1)} % of Spain's gross value added (GVA) in {peso_res[0]?.anio}**, compared with {formatNumber(peso_res[0]?.ue_manuf, 1)} % in the EU: rank {peso_res[0]?.es_puesto} of {peso_res[0]?.n_paises}. In 1995 it was {formatNumber(peso_res[0]?.es_manuf_1995, 1)} % (the EU, {formatNumber(peso_res[0]?.ue_manuf_1995, 1)} %). With all of industry, which adds energy, water, waste and mining, the proportion is {formatNumber(peso_res[0]?.es_ind, 1)} % compared with {formatNumber(peso_res[0]?.ue_ind, 1)} %. In employment, manufacturing employs {formatNumber(peso_res[0]?.es_emp, 1)} % of workers in Spain and {formatNumber(peso_res[0]?.ue_emp, 1)} % in the EU.

Per inhabitant, Spain's manufacturing GVA is {formatNumber(peso_res[0]?.es_hab, 0)} € a year, {formatNumber(peso_res[0]?.es_hab_pct_ue, 0)} % of the European average ({formatNumber(peso_res[0]?.ue_hab, 0)} €): Spain contributes {formatNumber(peso_res[0]?.es_cuota_vab, 1)} % of EU manufacturing GVA with {formatNumber(peso_res[0]?.es_cuota_pob, 1)} % of its population. In constant 2025 euros, Spain's manufacturing GVA per inhabitant is {#if peso_res[0]?.es_hab_real_var_2008 < 0}{formatNumber(-peso_res[0]?.es_hab_real_var_2008, 1)} % lower{:else}{formatNumber(peso_res[0]?.es_hab_real_var_2008, 1)} % higher{/if} than in 2008 ({formatNumber(peso_res[0]?.es_hab_real_2008, 0)} € then, {formatNumber(peso_res[0]?.es_hab_real, 0)} € in {peso_res[0]?.anio}).

<LineChart
    data={peso_serie}
    x=anio
    y=pct_vab_manufacturas
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% of total GVA"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399', 'Polonia': '#a78bfa', 'Portugal': '#fbbf24'}}
    title="Manufacturing's share of GVA (% at current prices)"
/>

<BarChart
    data={peso_ult}
    x=pais
    y=pct_vab_manufacturas
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% of total GVA"
    seriesColors={{'España': '#c2410c', 'Media UE': '#0f172a', 'Otros países': '#94a3b8'}}
    title="Manufacturing's share of GVA in each EU country ({peso_res[0]?.anio}, %)"
/>

<DataTable data={peso_ult} rows=28 search=true>
    <Column id=puesto title="Rank" />
    <Column id=pais title="Country" />
    <Column id=pct_vab_manufacturas title="Manufacturing, % of GVA" fmt='0.0' />
    <Column id=pct_vab_industria title="Industry, % of GVA" fmt='0.0' />
    <Column id=pct_empleo_manufacturas title="Manufacturing, % of employment" fmt='0.0' />
    <Column id=pct_empleo_industria title="Industry, % of employment" fmt='0.0' />
    <Column id=vab_manuf_hab_eur title="Manufacturing GVA per inhab. (current €)" fmt='#,##0' />
</DataTable>

Losing weight does not mean producing less: the share is measured at current prices and also depends on how much services grow. In **volume** (stripping out price changes), Spain's manufacturing GVA in {peso_res[0]?.anio} is equivalent to {formatNumber(peso_res[0]?.es_vol, 1)} if 2015 = 100 (in 2008, {formatNumber(peso_res[0]?.es_vol_2008, 1)}); the EU's, to {formatNumber(peso_res[0]?.ue_vol, 1)} (in 2008, {formatNumber(peso_res[0]?.ue_vol_2008, 1)}).

<LineChart
    data={peso_serie}
    x=anio
    y=vab_manuf_real_indice
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="index 2015 = 100"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399', 'Polonia': '#a78bfa', 'Portugal': '#fbbf24'}}
    title="Manufacturing GVA in volume (index 2015 = 100)"
/>

<LineChart
    data={peso_serie}
    x=anio
    y=pct_empleo_manufacturas
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% of people in employment"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399', 'Polonia': '#a78bfa', 'Portugal': '#fbbf24'}}
    title="Manufacturing's share of employment (% of people in employment)"
/>

## Industrial production

The industrial production index (IPI) measures how much is produced in quantities, without the effect of prices. In {ipi_res[0]?.anio}, Spanish industrial output changed by {formatNumber(ipi_res[0]?.es_var, 1)} % on the previous year (EU: {formatNumber(ipi_res[0]?.ue_var, 1)} %). Compared with 2019 the change is {formatNumber(ipi_res[0]?.es_var_2019, 1)} % in Spain and {formatNumber(ipi_res[0]?.ue_var_2019, 1)} % in the EU; compared with 2007, before the financial crisis, {formatNumber(ipi_res[0]?.es_var_2007, 1)} % and {formatNumber(ipi_res[0]?.ue_var_2007, 1)} %.

<LineChart
    data={ipi_anual}
    x=anio
    y=indice
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="index 2021 = 100"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399'}}
    title="Annual industrial production index (industry excluding construction, 2021 = 100, calendar adjusted)"
/>

The INE's latest monthly figure is for **{mesEn(ipi_ult[0]?.mes_txt)}**: index {formatNumber(ipi_ult[0]?.indice, 1)}, {formatNumber(ipi_ult[0]?.variacion_anual_pct, 1)} % on the same month of the previous year, and a cumulative change so far this year of {formatNumber(ipi_ult[0]?.variacion_acumulada_pct, 1)} %. The unadjusted monthly index rises and falls with the calendar (August is the lowest month every year except 2020), so the useful comparison is with the same month of the previous year.

<LineChart
    data={ipi_mes}
    x=mes
    y=indice
    yFmt='0.0'
    yAxisTitle="index 2021 = 100"
    title="Spain's monthly industrial production index (unadjusted, last 36 months)"
/>

<BarChart
    data={ipi_destinos}
    x=destino
    y=variacion_acumulada_pct
    swapXY=true
    yFmt='0.0'
    yAxisTitle="% on the same period of the previous year"
    title="Change in output so far this year up to {mesEn(ipi_ult[0]?.mes_txt)}, by economic destination (%)"
/>

## By region

The weight of industry varies greatly from region to region. In {ccaa_res[0]?.anio}, the most industrial by share of their GVA were {decEn(ccaa_res[0]?.mas)}; the Spanish average is {formatNumber(ccaa_espana[0]?.pct_vab_industria, 1)} % and {ccaa_res[0]?.n_sobre_media} regions exceed it. In Navarre industry employs {formatNumber(ccaa_res[0]?.navarra_ocup, 0)} people per 1,000 inhabitants, compared with an average of {formatNumber(ccaa_espana[0]?.ocupados_industria_1000_hab, 0)}. The least dependent on industry are {ccaa_res[0]?.menos}. Catalonia accounts for {formatNumber(ccaa_res[0]?.cat_cuota, 1)} % of Spain's industrial GVA. Click on a region to see its profile.

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod_ccaa"
    value="pct_vab_industria"
    valueFmt='0.0'
    link="ruta"
    colorPalette={['#fff7ed', '#f97316', '#7c2d12']}
    height={440}
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_vab_industria', title: 'Industry, % of GVA', fmt: '0.0'},
        {id: 'pct_vab_manufacturas', title: 'Manufacturing, % of GVA', fmt: '0.0'},
        {id: 'vab_industria_hab_real', title: 'Industrial GVA per inhab. (2025 €)', fmt: '#,##0'},
        {id: 'ocupados_industria_1000_hab', title: 'Employed in industry per 1,000 inhab.', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=puesto title="Rank" />
    <Column id=comunidad title="Region" />
    <Column id=pct_vab_industria title="Industry, % of GVA" fmt='0.0' />
    <Column id=pct_vab_manufacturas title="Manufacturing, % of GVA" fmt='0.0' />
    <Column id=vab_industria_hab_real title="Industrial GVA per inhab. (2025 €)" fmt='#,##0' />
    <Column id=cifra_negocios_hab_real title="Industrial turnover per inhab. (2025 €)" fmt='#,##0' />
    <Column id=ocupados_industria_1000_hab title="Employed in industry per 1,000 inhab." fmt='0.0' />
    <Column id=cuota_vab_industria_espana_pct title="% of Spain's industrial GVA" fmt='0.0' />
</DataTable>

### Each region's strongest branches

For each region, the branch that weighs most in its industry (by turnover) and the branch in which it is most specialised relative to its population: the region's share of that branch in Spain divided by its share of the Spanish population (only branches that account for at least 5 % of its industry and that ten or more regions publish; INE data for {ccaa_ramas_anio[0]?.anio}, excluding Ceuta and Melilla).

<DataTable data={ccaa_ramas} rows=17 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=rama_principal title="Branch with most weight" />
    <Column id=peso_principal title="% of its industry" fmt='0.0' />
    <Column id=rama_especial title="Most specialised branch" />
    <Column id=veces title="Times its population weight" fmt='0.0' />
    <Column id=cuota_especial title="% of that branch in Spain" fmt='0.0' />
</DataTable>

## Methodology and sources

- **Weight of industry in the EU:** Eurostat, national accounts by industry [nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table) (GVA at current prices and in chain-linked volumes, base 2010) and [nama_10_a10_e](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10_e/default/table) (employment); population, [nama_10_pe](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe/default/table). Manufacturing = NACE section C; industry = sections B to E (mining, manufacturing, energy, water and waste).
- **Industrial branches:** Eurostat, structural business statistics [sbs_ovw_act](https://ec.europa.eu/eurostat/databrowser/view/sbs_ovw_act/default/table) (turnover, value added and employment). The EU total is Eurostat's estimate; where none exists, the sum of the countries with data (the table indicates this in the note).
- **Products:** Eurostat, Prodcom [DS-059358](https://ec.europa.eu/eurostat/databrowser/view/DS-059358/default/table) (sold production). Share of the EU27_2020 aggregate estimated by Eurostat; rank among the countries that publish the figure.
- **Exports:** Eurostat, Comext [DS-045409](https://ec.europa.eu/eurostat/databrowser/view/DS-045409/default/table), by Harmonised System heading; sum of the 27 countries, with and without intra-EU trade.
- **Industrial production:** Eurostat [sts_inpr_a](https://ec.europa.eu/eurostat/databrowser/view/sts_inpr_a/default/table) (annual, calendar adjusted) and INE, Industrial Production Index, [table 70177](https://www.ine.es/jaxiT3/Tabla.htm?t=70177) (monthly by region and economic destination) and [table 60282](https://www.ine.es/jaxiT3/Tabla.htm?t=60282) (by division). Base 2021 = 100.
- **Regions:** Eurostat, regional GVA [nama_10r_3gva](https://ec.europa.eu/eurostat/databrowser/view/nama_10r_3gva/default/table); INE, Structural Business Statistics for the industrial sector, [table 76823](https://www.ine.es/jaxiT3/Tabla.htm?t=76823) (turnover and employment by region and branch; data subject to statistical confidentiality are not published).
- **Vehicles:** [OICA, world production by country 2019-2024](https://oica.net/wp-content/uploads/2025/10/By-country-region-2024.pdf) (for Germany cars only and for France only cars and light commercial vehicles; there is no 2020 figure in the series). Spain {veh_res[0]?.anio}: [ANFAC, production and exports, 2025 year-end](https://anfac.com/wp-content/uploads/2026/01/NP-Produccion-y-exportacion-diciembre-y-cierre-2025.pdf), which states: «Spain ranks 2nd as a vehicle manufacturer in Europe and 9th in the world». Factories: [ANFAC, map of factories with models in production and allocated](https://anfac.com/cifras-clave/produccion-y-exportacion/) (May 2025); municipality coordinates from Wikidata.
- Euros are expressed in constant 2025 euros using the INE's CPI when comparing years; comparisons between countries in the same year use current euros. Totals are given in proportion to population (per inhabitant, per 1,000 inhabitants or as a share compared with population weight).
