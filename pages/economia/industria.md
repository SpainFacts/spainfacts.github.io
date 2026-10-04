---
title: Industria
description: "Dónde es España una potencia industrial (automóvil, azulejos, aceite de oliva, jamón, material ferroviario, torres eólicas) y cuánto pesa su industria frente a la media de la UE: VAB y empleo manufacturero, producción industrial, exportaciones y comunidades."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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
SELECT c.cod_ccaa, c.ccaa AS comunidad, t.ruta, CAST(c.anio AS INTEGER) AS anio, c.pct_vab_industria, c.pct_vab_manufacturas,
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
SELECT t.nombre AS comunidad, t.ruta, p.rama_principal, p.peso_principal, e.rama_especial, e.veces, e.cuota_especial
FROM principal p
LEFT JOIN especial e USING (cod_ccaa)
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = p.cod_ccaa
ORDER BY p.peso_principal DESC
```

```sql ccaa_ramas_anio
SELECT CAST(max(anio) AS INTEGER) AS anio FROM mother.industria_ccaa_ramas
```

# 🏭 Industria

España no está entre los países más industriales de la Unión Europea: sus manufacturas pesan menos en la economía que la media europea. Pero en algunos productos es una potencia de primer orden, desde los coches y los azulejos hasta el aceite de oliva, el jamón curado, el material ferroviario o las torres de los aerogeneradores. Esta página muestra los dos lados con datos de Eurostat, el INE, OICA y ANFAC, siempre en proporción a la población o al total europeo.

<Grid cols=4>
    <KpiCard
        title="Vehículos fabricados"
        value={veh_res[0]?.veh_1000}
        formattedValue="{formatNumber(veh_res[0]?.veh_1000, 1)} por 1.000 hab."
        period="{veh_res[0]?.anio} · {formatNumber(veh_res[0]?.vehiculos_millones, 2)} millones · {veh_res[0]?.puesto_europa}.º de Europa (OICA {veh_res[0]?.anio_oica})"
        change={veh_res[0]?.var_anual?.toFixed(1)}
        changePeriod="vs {veh_res[0]?.anio_ant}"
        direction="positive-up"
        source="OICA y ANFAC"
        sparklineData={veh.map(d => d.vehiculos_1000_hab)}
    />
    <KpiCard
        title="Azulejos: cuota de la producción de la UE"
        value={prod_res[0]?.az_cuota}
        formattedValue="{formatNumber(prod_res[0]?.az_cuota, 1)} %"
        period="{prod_res[0]?.anio} · en m² · {prod_res[0]?.az_puesto}.º de los {prod_res[0]?.az_n} países que publican el dato"
        direction="positive-up"
        source="Eurostat (Prodcom)"
        sparklineData={azulejos.map(d => d.cuota_cantidad_pct)}
    />
    <KpiCard
        title="Peso de las manufacturas en la economía"
        value={peso_res[0]?.es_manuf}
        formattedValue="{formatNumber(peso_res[0]?.es_manuf, 1)} % del VAB"
        period="{peso_res[0]?.anio} · UE: {formatNumber(peso_res[0]?.ue_manuf, 1)} % · puesto {peso_res[0]?.es_puesto} de {peso_res[0]?.n_paises}"
        change={peso_res[0]?.dif_manuf?.toFixed(1)}
        changeUnit="pp"
        changePeriod="frente a la UE"
        direction="positive-up"
        source="Eurostat (nama_10_a10)"
        sparklineData={peso_es.map(d => d.pct_vab_manufacturas)}
    />
    <KpiCard
        title="Índice de producción industrial"
        value={ipi_ult[0]?.indice}
        formattedValue={formatNumber(ipi_ult[0]?.indice, 1)}
        period="{ipi_ult[0]?.mes_txt} · base 2021 = 100 · índice original"
        change={ipi_ult[0]?.variacion_anual_pct?.toFixed(1)}
        changePeriod="interanual"
        direction="positive-up"
        source="INE (IPI, tabla 70177)"
        sparklineData={ipi_mes.map(d => d.indice)}
    />
</Grid>

## Dónde destaca España

España tiene el {formatNumber(ramas_res[0]?.cuota_pob, 1)} % de la población de la UE. Si una rama industrial española factura más de esa proporción del total europeo, España produce más de lo que le tocaría por habitantes; el cociente («veces su peso en población») lo resume: 1 es lo esperable, 2 es el doble. En las manufacturas en conjunto la cuota es el {formatNumber(ramas_res[0]?.c_cuota, 1)} % ({ramas_res[0]?.c_puesto}.º de la UE por cifra de negocios), por debajo de su peso en población. Solo {ramas_res[0]?.n_por_encima} de las {ramas_res[0]?.n_ramas} ramas de la tabla lo superan, y la que más destaca es la de **azulejos y baldosas cerámicas**: el {formatNumber(ramas_res[0]?.az_cuota, 1)} % de la cifra de negocios europea, {formatNumber(ramas_res[0]?.az_veces, 1)} veces su peso en población.

<BarChart
    data={ramas}
    x=rama_nombre
    y=cuota_cifra_negocios_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% de la cifra de negocios de la UE"
    seriesColors={{'Más que su peso en población': '#c2410c', 'Menos que su peso en población': '#94a3b8'}}
    title="Cuota de España en la cifra de negocios de cada rama industrial de la UE ({ramas_res[0]?.anio}, %)"
/>

<DataTable data={ramas} rows=12 search=true>
    <Column id=rama_nombre title="Rama" />
    <Column id=cuota_cifra_negocios_pct title="Cuota UE %" fmt='0.0' />
    <Column id=veces_peso_poblacion title="Veces su peso en población" fmt='0.00' />
    <Column id=puesto_txt title="Puesto (entre los que publican)" />
    <Column id=lider title="País líder" />
    <Column id=peso_manuf_es_pct title="Peso en las manufacturas de España %" fmt='0.0' />
    <Column id=peso_manuf_ue_pct title="Peso en las manufacturas de la UE %" fmt='0.0' />
    <Column id=cifra_negocios_es_real_meur title="Cifra de negocios España (M€ de 2025)" fmt='#,##0' />
</DataTable>

Las ramas se miden por la cifra de negocios de las empresas (Eurostat, estadísticas estructurales de empresas). El total de la UE es la estimación de Eurostat, que incluye a los países con datos confidenciales; el puesto, en cambio, solo se puede calcular entre los países que publican la cifra, así que, por ejemplo, «2.º de 19» quiere decir segundo de los 19 que la publican.

### Productos concretos

Las estadísticas de producción industrial (Prodcom) bajan al detalle de cada producto, en unidades físicas: metros cuadrados, toneladas, unidades. España es el primer productor en {prod_res[0]?.n_primeros} de los {prod_res[0]?.n_productos} productos de la lista, con cuotas de más de la mitad de la producción europea en esmaltes y fritas cerámicas ({formatNumber(prod_res[0]?.fri_cuota, 0)} %), aceitunas de mesa ({formatNumber(prod_res[0]?.acei_cuota, 0)} %) o aceite de oliva virgen ({formatNumber(prod_res[0]?.ac_cuota, 0)} %).

**Ojo con dos trampas.** La cuota se calcula sobre el **total de la UE que estima Eurostat** (un agregado redondeado que incluye la producción confidencial de los países que no la publican), no sobre la suma de los países con dato, que la inflaría. Y el **puesto es solo entre los países que publican la cifra**: en muchos productos son pocos (en el aceite de oliva virgen, {prod_res[0]?.ac_n}; en las fritas cerámicas, {prod_res[0]?.fri_n}), porque los demás la declaran confidencial. Ser el primero de cinco no garantiza ser el primero de la UE, aunque con una cuota por encima del 50 % no puede haber otro país mayor.

<BarChart
    data={productos}
    x=producto_nombre
    y=cuota_cantidad_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% de la producción de la UE (en cantidad)"
    seriesColors={{'Más que su peso en población': '#c2410c', 'Menos que su peso en población': '#94a3b8'}}
    title="Cuota de España en la producción de la UE de cada producto ({prod_res[0]?.anio}, % en cantidad)"
/>

<DataTable data={productos} rows=12 search=true>
    <Column id=producto_nombre title="Producto" />
    <Column id=cuota_cantidad_pct title="Cuota UE en cantidad %" fmt='0.0' />
    <Column id=cuota_valor_pct title="Cuota UE en valor %" fmt='0.0' />
    <Column id=veces_peso_poblacion title="Veces su peso en población" fmt='0.00' />
    <Column id=puesto_txt title="Puesto (entre los que publican)" />
    <Column id=lider title="Mayor productor con dato" />
    <Column id=cantidad_es_legible title="Producción de España" fmt='#,##0.0' />
    <Column id=unidad_legible title="Unidad" />
    <Column id=valor_es_real_meur title="Valor España (M€ de 2025)" fmt='#,##0' />
</DataTable>

## El automóvil

España fabricó **{formatNumber(veh_res[0]?.vehiculos_millones, 2)} millones de vehículos en {veh_res[0]?.anio}**, {formatNumber(veh_res[0]?.veh_1000, 1)} por cada 1.000 habitantes, {#if veh_res[0]?.var_anual < 0}un {formatNumber(-veh_res[0]?.var_anual, 1)} % menos{:else}un {formatNumber(veh_res[0]?.var_anual, 1)} % más{/if} que en {veh_res[0]?.anio_ant} y {#if veh_res[0]?.var_2019 < 0}un {formatNumber(-veh_res[0]?.var_2019, 1)} % menos{:else}un {formatNumber(veh_res[0]?.var_2019, 1)} % más{/if} que en 2019, cuando salieron de sus fábricas {formatNumber(veh_res[0]?.veh_2019_millones, 2)} millones. Exportó el **{formatNumber(veh_res[0]?.pct_exportado, 1)} %** de lo que produjo en {veh_res[0]?.anio_exportado}. En el último año con datos de todos los países ({veh_res[0]?.anio_oica}) fue el **{veh_res[0]?.puesto_europa}.º fabricante de Europa**, solo por detrás de Alemania, y el **{veh_res[0]?.puesto_mundo}.º del mundo**, con el {formatNumber(veh_res[0]?.cuota_mundo, 1)} % de la producción mundial. Para {veh_res[0]?.anio} solo hay el dato español; ANFAC, la patronal del sector, afirma que mantiene ambos puestos.

<BarChart
    data={veh}
    x=anio
    y=vehiculos_1000_hab
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="vehículos por 1.000 habitantes"
    title="Vehículos fabricados en España por 1.000 habitantes (2020 sin dato en la serie)"
/>

<LineChart
    data={veh}
    x=anio
    y=puesto_europa
    y2=puesto_mundo
    xFmt='0'
    yFmt='0'
    markers=true
    yAxisTitle="puesto en Europa"
    y2AxisTitle="puesto en el mundo"
    title="Puesto de España entre los fabricantes de vehículos de Europa y del mundo (OICA)"
/>

En proporción a la población, los países que más vehículos fabrican son Eslovaquia ({formatNumber(veh_lideres[0]?.sk_1000, 0)} por 1.000 habitantes) y Chequia ({formatNumber(veh_lideres[0]?.cz_1000, 0)}). España ({formatNumber(veh_res[0]?.veh_1000_oica, 1)}) está a la par que Alemania ({formatNumber(veh_lideres[0]?.de_1000, 1)}), aunque la cifra alemana de OICA solo cuenta turismos, y muy por encima de Francia ({formatNumber(veh_lideres[0]?.fr_1000, 1)}, sin camiones ni autobuses) o Italia ({formatNumber(veh_lideres[0]?.it_1000, 1)}).

<BarChart
    data={veh_europa_hab}
    x=pais
    y=vehiculos_1000_hab
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="vehículos por 1.000 habitantes"
    seriesColors={{'España': '#c2410c', 'Otros países': '#94a3b8'}}
    title="Vehículos fabricados por 1.000 habitantes en los fabricantes de la UE ({veh_res[0]?.anio_oica})"
/>

<DataTable data={veh_europa} rows=15>
    <Column id=puesto_europa title="Puesto en Europa" />
    <Column id=pais title="País" />
    <Column id=vehiculos title="Vehículos fabricados" fmt='#,##0' />
    <Column id=vehiculos_1000_hab title="Por 1.000 hab." fmt='0.0' />
    <Column id=puesto_mundo title="Puesto en el mundo" />
    <Column id=cobertura title="Qué cuenta OICA" />
</DataTable>

### Las fábricas

ANFAC recoge {fab_res[0]?.plantas} fábricas de vehículos y componentes en {fab_res[0]?.comunidades} comunidades; {fab_res[0]?.plantas_montaje} montan vehículos, con {fab_res[0]?.modelos} modelos en producción ({fab_res[0]?.electrificados} de ellos eléctricos o híbridos) y {fab_res[0]?.adjudicados} más adjudicados para los próximos años. La que más modelos fabrica es {fab_res[0]?.mas_modelos} ({fab_res[0]?.max_modelos}). Por cifra de negocios de la rama, las comunidades con más peso en la fabricación de vehículos son {veh_ccaa_txt[0]?.lista} del total español.

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
        {id: 'grupo', title: 'Grupo'},
        {id: 'tipo', title: 'Qué fabrica'},
        {id: 'municipio', title: 'Municipio'},
        {id: 'n_modelos', title: 'Modelos en producción', fmt: '0'},
        {id: 'modelos', title: 'Modelos'}
    ]}
/>

El tamaño del punto es el número de modelos en producción; la posición es la del municipio (las dos fábricas de Barcelona y las dos de Madrid se superponen).

<DataTable data={fabricas} rows=16 search=true>
    <Column id=fabrica title="Fábrica" />
    <Column id=grupo title="Grupo" />
    <Column id=tipo title="Qué fabrica" />
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=modelos title="Modelos en producción" />
    <Column id=modelos_adjudicados title="Modelos adjudicados" />
    <Column id=otras_producciones title="Otras producciones" />
</DataTable>

## Azulejos y cerámica

España produjo **{formatNumber(prod_res[0]?.az_mm2, 0)} millones de m² de baldosas y azulejos cerámicos en {prod_res[0]?.anio}**, unos {formatNumber(prod_res[0]?.az_m2_1000, 0)} m² por cada 1.000 habitantes: el {formatNumber(prod_res[0]?.az_cuota, 1)} % de la producción europea en superficie ({formatNumber(prod_res[0]?.az_veces, 1)} veces su peso en población) y el {formatNumber(prod_res[0]?.az_cuota_valor, 1)} % en valor. Es el 1.º de los {prod_res[0]?.az_n} países que publican el dato. Como su cuota en valor es menor que en superficie, el precio medio de su producción por m² es inferior al del conjunto europeo. En cifra de negocios de la rama (Eurostat, empresas) España es {ramas_res[0]?.az_puesto}.ª de {ramas_res[0]?.az_n} países con dato, con el {formatNumber(ramas_res[0]?.az_cuota, 1)} %; la primera es {ramas_res[0]?.az_lider}. Las fritas y esmaltes con que se recubren las piezas son también una especialidad española: el {formatNumber(prod_res[0]?.fri_cuota, 0)} % de la producción de la UE.

La rama de minerales no metálicos (cerámica, vidrio, cemento) está muy concentrada: {ceramica_ccaa[0]?.comunidad} reúne el {formatNumber(ceramica_ccaa[0]?.cuota_espana_pct, 0)} % de su cifra de negocios en España, {formatNumber(ceramica_ccaa[0]?.veces_peso_poblacion, 1)} veces su peso en población.

<LineChart
    data={azulejos}
    x=anio
    y=cuota_cantidad_pct
    y2=cuota_valor_pct
    xFmt='0'
    yFmt='0.0'
    y2Fmt='0.0'
    markers=true
    yAxisTitle="% de la UE en m²"
    y2AxisTitle="% de la UE en valor"
    title="Cuota de España en la producción de baldosas y azulejos de la UE (%)"
/>

## Alimentación y bebidas

La alimentación es la **primera rama manufacturera de España**: el {formatNumber(ramas_res[0]?.ali_peso_es, 1)} % del valor añadido de sus manufacturas, frente al {formatNumber(ramas_res[0]?.ali_peso_ue, 1)} % en la UE{#if ramas_rank[0]?.ali_puesto_ue > 1}, donde es la {ramas_rank[0]?.ali_puesto_ue}.ª (la primera es {ramas_rank[0]?.primera_ue}, con el {formatNumber(ramas_rank[0]?.primera_ue_peso, 1)} %){/if}. Sus empresas facturan el {formatNumber(ramas_res[0]?.ali_cuota, 1)} % de la alimentación europea ({ramas_res[0]?.ali_puesto}.º país; el primero es {ramas_res[0]?.ali_lider}). Las bebidas pesan el {formatNumber(ramas_res[0]?.beb_peso_es, 1)} % frente al {formatNumber(ramas_res[0]?.beb_peso_ue, 1)} % y suponen el {formatNumber(ramas_res[0]?.beb_cuota, 1)} % de la UE.

En productos concretos, España produce el {formatNumber(prod_res[0]?.ac_cuota, 0)} % del aceite de oliva virgen de la UE ({formatNumber(prod_res[0]?.ac_kt, 0)} miles de toneladas), el {formatNumber(prod_res[0]?.acei_cuota, 0)} % de las aceitunas de mesa y el {formatNumber(prod_res[0]?.jam_cuota, 0)} % de los jamones y paletas curados con hueso ({prod_res[0]?.jam_puesto}.º de {prod_res[0]?.jam_n} países con dato). En vino espumoso es {prod_res[0]?.cava_puesto}.º de {prod_res[0]?.cava_n}, con el {formatNumber(prod_res[0]?.cava_cuota, 0)} % (el champán no entra en este código).

<BarChart
    data={ramas_peso}
    x=rama_nombre
    y=peso
    series=territorio
    type=grouped
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% del valor añadido de las manufacturas"
    seriesColors={{'España': '#c2410c', 'Unión Europea': '#64748b'}}
    title="Peso de cada rama en las manufacturas: España frente a la UE ({ramas_res[0]?.anio}, % del valor añadido)"
/>

El gráfico enseña también dónde está la diferencia con Europa: España tiene mucho menos peso en **maquinaria**, **farmacia** y **electrónica**, ramas en las que factura el {formatNumber(ramas_res[0]?.maq_cuota, 1)} %, el {formatNumber(ramas_res[0]?.far_cuota, 1)} % y el {formatNumber(ramas_res[0]?.ele_cuota, 1)} % del total europeo.

## Otros sectores fuertes

- **Material ferroviario.** La rama factura el {formatNumber(ramas_res[0]?.fer_cuota, 1)} % de la UE ({ramas_res[0]?.fer_puesto}.º de {ramas_res[0]?.fer_n} países con dato, el primero es {ramas_res[0]?.fer_lider}; {formatNumber(ramas_res[0]?.fer_veces, 1)} veces su peso en población). En coches de viajeros de tren y tranvía, España fabricó {formatNumber(prod_res[0]?.tren_uds, 0)} unidades, el {formatNumber(prod_res[0]?.tren_cuota, 0)} % de la estimación europea (solo {prod_res[0]?.tren_n} países publican el dato), y es la {exp_res[0]?.tren_puesto}.ª exportadora de la UE, con el {formatNumber(exp_res[0]?.tren_cuota, 0)} %.
- **Aeronáutica.** El {formatNumber(ramas_res[0]?.aer_cuota, 1)} % de la cifra de negocios europea ({ramas_res[0]?.aer_puesto}.º de {ramas_res[0]?.aer_n} con dato; lidera {ramas_res[0]?.aer_lider}), algo por debajo de su peso en población.
- **Refino de petróleo.** El {formatNumber(ramas_res[0]?.ref_cuota, 1)} % de la UE ({ramas_res[0]?.ref_puesto}.º de {ramas_res[0]?.ref_n} con dato); pesa el {formatNumber(ramas_res[0]?.ref_peso_es, 1)} % de las manufacturas españolas frente al {formatNumber(ramas_res[0]?.ref_peso_ue, 1)} % en la UE.
- **Renovables.** España fabricó {formatNumber(prod_res[0]?.tor_kt, 0)} miles de toneladas de torres y castilletes de acero, el {formatNumber(prod_res[0]?.tor_cuota, 0)} % de la UE ({prod_res[0]?.tor_puesto}.º de {prod_res[0]?.tor_n} con dato; el código incluye las torres eólicas y otras estructuras de celosía), y {formatNumber(prod_res[0]?.aero_uds, 0)} aerogeneradores, el {formatNumber(prod_res[0]?.aero_cuota, 0)} % ({prod_res[0]?.aero_puesto}.º de solo {prod_res[0]?.aero_n} que publican, tras {prod_res[0]?.aero_lider}). En la rama de motores y turbinas, que mezcla aerogeneradores con turbinas de otro tipo, la cuota baja al {formatNumber(ramas_res[0]?.tur_cuota, 1)} %.
- **Barcos de pesca y cemento.** El {formatNumber(prod_res[0]?.pes_cuota, 0)} % del arqueo de los buques de pesca construidos en la UE (de {prod_res[0]?.pes_n} países con dato) y el {formatNumber(prod_res[0]?.cem_cuota, 1)} % del cemento Portland ({prod_res[0]?.cem_puesto}.º de {prod_res[0]?.cem_n}).

<DataTable data={otros} rows=14>
    <Column id=nombre title="Rama o producto" />
    <Column id=tipo title="Medida" />
    <Column id=cuota title="Cuota UE %" fmt='0.0' />
    <Column id=veces_peso_poblacion title="Veces su peso en población" fmt='0.00' />
    <Column id=puesto_txt title="Puesto (entre los que publican)" />
    <Column id=lider title="Primero con dato" />
</DataTable>

## Exportaciones industriales

España vende al exterior (incluidos los demás países de la UE) el {formatNumber(exp_res[0]?.tot_cuota, 1)} % de todas las exportaciones de bienes de los 27, por debajo de su {formatNumber(exp_res[0]?.cuota_pob, 1)} % de la población: {exp_res[0]?.tot_puesto}.º exportador en {exp_res[0]?.anio}, con {formatNumber(exp_res[0]?.tot_real_mm, 0)} mil millones de euros de 2025. Fuera de la UE la cuota es el {formatNumber(exp_res[0]?.ext_cuota, 1)} % ({exp_res[0]?.ext_puesto}.º). Donde sí destaca es en aceite de oliva ({formatNumber(exp_res[0]?.ace_cuota, 0)} % de lo que exporta la UE), fritas y esmaltes cerámicos ({formatNumber(exp_res[0]?.fri_cuota, 0)} %), coches de tren ({formatNumber(exp_res[0]?.tren_cuota, 0)} %) y azulejos ({formatNumber(exp_res[0]?.az_cuota, 0)} %, {exp_res[0]?.az_puesto}.º tras {exp_res[0]?.az_lider}). Los turismos son el {formatNumber(exp_res[0]?.tur_cuota, 1)} % de la UE ({exp_res[0]?.tur_puesto}.º) y los vehículos en conjunto, el {formatNumber(exp_res[0]?.veh_peso, 1)} % de todo lo que exporta España.

**La trampa de Países Bajos y Bélgica.** Róterdam y Amberes son la puerta de entrada de mercancías a Europa, y lo que entra por sus puertos y se reenvía a otro país cuenta como exportación suya aunque no lo hayan fabricado. Entre los dos suman el {formatNumber(exp_res[0]?.tot_nl_be, 1)} % de las exportaciones de la UE y el {formatNumber(exp_res[0]?.ref_nl_be, 0)} % de las de productos refinados del petróleo. Sin contarlos, España sería {exp_res[0]?.tot_puesto_sin}.ª en el total, {exp_res[0]?.tur_puesto_sin}.ª en turismos y {exp_res[0]?.ref_puesto_sin}.ª en productos refinados (en vez de {exp_res[0]?.ref_puesto}.ª). La tabla da los dos puestos.

<BarChart
    data={exportaciones}
    x=partida_nombre
    y=cuota_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% de las exportaciones de los 27"
    seriesColors={{'Más que su peso en población': '#c2410c', 'Menos que su peso en población': '#94a3b8'}}
    title="Cuota de España en las exportaciones de la UE por producto ({exp_res[0]?.anio}, %, incluido el comercio dentro de la UE)"
/>

<DataTable data={exportaciones} rows=12 search=true>
    <Column id=partida_nombre title="Producto" />
    <Column id=cuota_pct title="Cuota UE %" fmt='0.0' />
    <Column id=puesto title="Puesto" />
    <Column id=puesto_sin_nl_be title="Puesto sin NL ni BE" />
    <Column id=lider title="Primer exportador" />
    <Column id=cuota_nl_be_pct title="NL + BE, % de la UE" fmt='0.0' />
    <Column id=peso_en_exportacion_es_pct title="% de las exportaciones españolas" fmt='0.00' />
    <Column id=exportacion_es_real_meur title="Exportación España (M€ de 2025)" fmt='#,##0' />
    <Column id=exportacion_es_real_eur_hab title="Exportación por habitante (€ de 2025)" fmt='#,##0' />
</DataTable>

## ¿Cuánta industria tiene España?

Las manufacturas generan el **{formatNumber(peso_res[0]?.es_manuf, 1)} % del valor añadido bruto (VAB) español en {peso_res[0]?.anio}**, frente al {formatNumber(peso_res[0]?.ue_manuf, 1)} % de la UE: puesto {peso_res[0]?.es_puesto} de {peso_res[0]?.n_paises}. En 1995 eran el {formatNumber(peso_res[0]?.es_manuf_1995, 1)} % (la UE, el {formatNumber(peso_res[0]?.ue_manuf_1995, 1)} %). Con toda la industria, que suma energía, agua, residuos y minas, la proporción es el {formatNumber(peso_res[0]?.es_ind, 1)} % frente al {formatNumber(peso_res[0]?.ue_ind, 1)} %. En empleo, las manufacturas ocupan al {formatNumber(peso_res[0]?.es_emp, 1)} % de los trabajadores en España y al {formatNumber(peso_res[0]?.ue_emp, 1)} % en la UE.

Por habitante, el VAB manufacturero español es de {formatNumber(peso_res[0]?.es_hab, 0)} € al año, el {formatNumber(peso_res[0]?.es_hab_pct_ue, 0)} % de la media europea ({formatNumber(peso_res[0]?.ue_hab, 0)} €): España aporta el {formatNumber(peso_res[0]?.es_cuota_vab, 1)} % del VAB manufacturero de la UE con el {formatNumber(peso_res[0]?.es_cuota_pob, 1)} % de su población. En euros constantes de 2025, el VAB manufacturero por habitante de España es {#if peso_res[0]?.es_hab_real_var_2008 < 0}un {formatNumber(-peso_res[0]?.es_hab_real_var_2008, 1)} % menor{:else}un {formatNumber(peso_res[0]?.es_hab_real_var_2008, 1)} % mayor{/if} que en 2008 ({formatNumber(peso_res[0]?.es_hab_real_2008, 0)} € entonces, {formatNumber(peso_res[0]?.es_hab_real, 0)} € en {peso_res[0]?.anio}).

<LineChart
    data={peso_serie}
    x=anio
    y=pct_vab_manufacturas
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% del VAB total"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399', 'Polonia': '#a78bfa', 'Portugal': '#fbbf24'}}
    title="Peso de las manufacturas en el VAB (% a precios corrientes)"
/>

<BarChart
    data={peso_ult}
    x=pais
    y=pct_vab_manufacturas
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% del VAB total"
    seriesColors={{'España': '#c2410c', 'Media UE': '#0f172a', 'Otros países': '#94a3b8'}}
    title="Peso de las manufacturas en el VAB de cada país de la UE ({peso_res[0]?.anio}, %)"
/>

<DataTable data={peso_ult} rows=28 search=true>
    <Column id=puesto title="Puesto" />
    <Column id=pais title="País" />
    <Column id=pct_vab_manufacturas title="Manufacturas, % del VAB" fmt='0.0' />
    <Column id=pct_vab_industria title="Industria, % del VAB" fmt='0.0' />
    <Column id=pct_empleo_manufacturas title="Manufacturas, % del empleo" fmt='0.0' />
    <Column id=pct_empleo_industria title="Industria, % del empleo" fmt='0.0' />
    <Column id=vab_manuf_hab_eur title="VAB manufacturero por hab. (€ corrientes)" fmt='#,##0' />
</DataTable>

Que pierda peso no quiere decir que produzca menos: el peso se mide en precios corrientes y depende también de lo que crezcan los servicios. En **volumen** (descontada la evolución de los precios), el VAB manufacturero español de {peso_res[0]?.anio} equivale a {formatNumber(peso_res[0]?.es_vol, 1)} si 2015 = 100 (en 2008, {formatNumber(peso_res[0]?.es_vol_2008, 1)}); el de la UE, a {formatNumber(peso_res[0]?.ue_vol, 1)} (en 2008, {formatNumber(peso_res[0]?.ue_vol_2008, 1)}).

<LineChart
    data={peso_serie}
    x=anio
    y=vab_manuf_real_indice
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="índice 2015 = 100"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399', 'Polonia': '#a78bfa', 'Portugal': '#fbbf24'}}
    title="VAB de las manufacturas en volumen (índice 2015 = 100)"
/>

<LineChart
    data={peso_serie}
    x=anio
    y=pct_empleo_manufacturas
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% de los ocupados"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399', 'Polonia': '#a78bfa', 'Portugal': '#fbbf24'}}
    title="Peso de las manufacturas en el empleo (% de los ocupados)"
/>

## Producción industrial

El índice de producción industrial (IPI) mide cuánto se produce en cantidades, sin efecto de los precios. En {ipi_res[0]?.anio}, la producción de la industria española varió un {formatNumber(ipi_res[0]?.es_var, 1)} % respecto al año anterior (UE: {formatNumber(ipi_res[0]?.ue_var, 1)} %). Respecto a 2019 la variación es del {formatNumber(ipi_res[0]?.es_var_2019, 1)} % en España y del {formatNumber(ipi_res[0]?.ue_var_2019, 1)} % en la UE; respecto a 2007, antes de la crisis financiera, del {formatNumber(ipi_res[0]?.es_var_2007, 1)} % y del {formatNumber(ipi_res[0]?.ue_var_2007, 1)} %.

<LineChart
    data={ipi_anual}
    x=anio
    y=indice
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="índice 2021 = 100"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399'}}
    title="Índice de producción industrial anual (industria sin construcción, 2021 = 100, corregido de calendario)"
/>

El último dato mensual del INE es de **{ipi_ult[0]?.mes_txt}**: índice {formatNumber(ipi_ult[0]?.indice, 1)}, un {formatNumber(ipi_ult[0]?.variacion_anual_pct, 1)} % respecto al mismo mes del año anterior, y una variación acumulada en lo que va de año del {formatNumber(ipi_ult[0]?.variacion_acumulada_pct, 1)} %. El índice mensual original sube y baja con el calendario (agosto es el mes más bajo todos los años salvo 2020), así que la comparación útil es con el mismo mes del año anterior.

<LineChart
    data={ipi_mes}
    x=mes
    y=indice
    yFmt='0.0'
    yAxisTitle="índice 2021 = 100"
    title="Índice de producción industrial mensual de España (original, últimos 36 meses)"
/>

<BarChart
    data={ipi_destinos}
    x=destino
    y=variacion_acumulada_pct
    swapXY=true
    yFmt='0.0'
    yAxisTitle="% sobre el mismo periodo del año anterior"
    title="Variación de la producción en lo que va de año hasta {ipi_ult[0]?.mes_txt}, por destino económico (%)"
/>

## Por comunidad

La industria pesa muy distinto según la comunidad. En {ccaa_res[0]?.anio}, las más industriales por peso en su VAB eran {ccaa_res[0]?.mas}; la media española es el {formatNumber(ccaa_espana[0]?.pct_vab_industria, 1)} % y {ccaa_res[0]?.n_sobre_media} comunidades la superan. En Navarra la industria da empleo a {formatNumber(ccaa_res[0]?.navarra_ocup, 0)} personas por cada 1.000 habitantes, frente a {formatNumber(ccaa_espana[0]?.ocupados_industria_1000_hab, 0)} de media. Las que menos dependen de la industria son {ccaa_res[0]?.menos}. Cataluña concentra el {formatNumber(ccaa_res[0]?.cat_cuota, 1)} % del VAB industrial de España. Pulsa en una comunidad para ver su ficha.

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
        {id: 'pct_vab_industria', title: 'Industria, % del VAB', fmt: '0.0'},
        {id: 'pct_vab_manufacturas', title: 'Manufacturas, % del VAB', fmt: '0.0'},
        {id: 'vab_industria_hab_real', title: 'VAB industrial por hab. (€ de 2025)', fmt: '#,##0'},
        {id: 'ocupados_industria_1000_hab', title: 'Ocupados en la industria por 1.000 hab.', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=puesto title="Puesto" />
    <Column id=comunidad title="Comunidad" />
    <Column id=pct_vab_industria title="Industria, % del VAB" fmt='0.0' />
    <Column id=pct_vab_manufacturas title="Manufacturas, % del VAB" fmt='0.0' />
    <Column id=vab_industria_hab_real title="VAB industrial por hab. (€ de 2025)" fmt='#,##0' />
    <Column id=cifra_negocios_hab_real title="Cifra de negocios industrial por hab. (€ de 2025)" fmt='#,##0' />
    <Column id=ocupados_industria_1000_hab title="Ocupados en la industria por 1.000 hab." fmt='0.0' />
    <Column id=cuota_vab_industria_espana_pct title="% del VAB industrial de España" fmt='0.0' />
</DataTable>

### Las ramas fuertes de cada comunidad

Para cada comunidad, la rama que más pesa en su industria (en cifra de negocios) y la rama en la que está más especializada respecto a su población: la cuota de la comunidad en esa rama en España dividida entre su peso en la población española (solo ramas que suponen al menos el 5 % de su industria y que publican diez comunidades o más; datos del INE de {ccaa_ramas_anio[0]?.anio}, sin Ceuta ni Melilla).

<DataTable data={ccaa_ramas} rows=17 link=ruta>
    <Column id=comunidad title="Comunidad" />
    <Column id=rama_principal title="Rama con más peso" />
    <Column id=peso_principal title="% de su industria" fmt='0.0' />
    <Column id=rama_especial title="Rama más especializada" />
    <Column id=veces title="Veces su peso en población" fmt='0.0' />
    <Column id=cuota_especial title="% de esa rama en España" fmt='0.0' />
</DataTable>

## Metodología y fuentes

- **Peso de la industria en la UE:** Eurostat, cuentas nacionales por rama [nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table) (VAB a precios corrientes y en volumen encadenado, base 2010) y [nama_10_a10_e](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10_e/default/table) (empleo); población, [nama_10_pe](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe/default/table). Manufacturas = sección C de la NACE; industria = secciones B a E (minas, manufacturas, energía, agua y residuos).
- **Ramas industriales:** Eurostat, estadísticas estructurales de empresas [sbs_ovw_act](https://ec.europa.eu/eurostat/databrowser/view/sbs_ovw_act/default/table) (cifra de negocios, valor añadido y empleo). El total de la UE es la estimación de Eurostat; si no existe, la suma de los países con dato (la tabla lo indica en la nota).
- **Productos:** Eurostat, Prodcom [DS-059358](https://ec.europa.eu/eurostat/databrowser/view/DS-059358/default/table) (producción vendida). Cuota sobre el agregado EU27_2020 estimado por Eurostat; puesto entre los países que publican el dato.
- **Exportaciones:** Eurostat, Comext [DS-045409](https://ec.europa.eu/eurostat/databrowser/view/DS-045409/default/table), por partida del Sistema Armonizado; suma de los 27 países, con y sin el comercio dentro de la UE.
- **Producción industrial:** Eurostat [sts_inpr_a](https://ec.europa.eu/eurostat/databrowser/view/sts_inpr_a/default/table) (anual, corregido de calendario) e INE, Índice de Producción Industrial, [tabla 70177](https://www.ine.es/jaxiT3/Tabla.htm?t=70177) (mensual por comunidad y destino económico) y [tabla 60282](https://www.ine.es/jaxiT3/Tabla.htm?t=60282) (por división). Base 2021 = 100.
- **Comunidades:** Eurostat, VAB regional [nama_10r_3gva](https://ec.europa.eu/eurostat/databrowser/view/nama_10r_3gva/default/table); INE, Estadística Estructural de Empresas del sector industrial, [tabla 76823](https://www.ine.es/jaxiT3/Tabla.htm?t=76823) (cifra de negocios y ocupados por comunidad y rama; los datos con secreto estadístico no se publican).
- **Vehículos:** [OICA, producción mundial por país 2019-2024](https://oica.net/wp-content/uploads/2025/10/By-country-region-2024.pdf) (para Alemania solo turismos y para Francia solo turismos y comerciales ligeros; no hay dato de 2020 en la serie). España {veh_res[0]?.anio}: [ANFAC, producción y exportación, cierre de 2025](https://anfac.com/wp-content/uploads/2026/01/NP-Produccion-y-exportacion-diciembre-y-cierre-2025.pdf), que afirma: «España ocupa el 2.º lugar como fabricante de vehículos en Europa y el 9.º mundial». Fábricas: [ANFAC, mapa de fábricas con modelos en producción y adjudicados](https://anfac.com/cifras-clave/produccion-y-exportacion/) (mayo de 2025); coordenadas del municipio, de Wikidata.
- Los euros se expresan en euros constantes de 2025 con el IPC del INE cuando se comparan años; las comparaciones entre países del mismo año usan euros corrientes. Los totales se dan en proporción a la población (por habitante, por 1.000 habitantes o en cuota frente al peso en población).
