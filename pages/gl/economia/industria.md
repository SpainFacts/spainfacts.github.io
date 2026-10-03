---
title: Industria
description: "Onde é España unha potencia industrial (automóbil, azulexos, aceite de oliva, xamón, material ferroviario, torres eólicas) e canto pesa a súa industria fronte á media da UE: VEB e emprego manufactureiro, produción industrial, exportacións e comunidades."
i18n_origen: 31efb7de9711
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
SELECT CAST(anio AS INTEGER) AS anio, nombre AS pais, indice
FROM mother.industria_ipi
WHERE fuente = 'eurostat' AND rama = 'B-D' AND cod IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT') AND anio >= 2005
ORDER BY anio, pais
```

```sql ipi_res
WITH e AS (SELECT * FROM mother.industria_ipi WHERE fuente = 'eurostat' AND rama = 'B-D'),
     u AS (SELECT max(anio) AS a FROM e WHERE cod = 'ES')
SELECT
    CAST((SELECT a FROM u) AS INTEGER) AS anio,
    max(indice) FILTER (WHERE cod = 'ES' AND anio = (SELECT a FROM u)) AS es,
    max(indice) FILTER (WHERE cod = 'EU27_2020' AND anio = (SELECT a FROM u)) AS ue,
    max(variacion_anual_pct) FILTER (WHERE cod = 'ES' AND anio = (SELECT a FROM u)) AS es_var,
    max(variacion_anual_pct) FILTER (WHERE cod = 'EU27_2020' AND anio = (SELECT a FROM u)) AS ue_var,
    100 * (max(indice) FILTER (WHERE cod = 'ES' AND anio = (SELECT a FROM u)) / max(indice) FILTER (WHERE cod = 'ES' AND anio = 2019) - 1) AS es_var_2019,
    100 * (max(indice) FILTER (WHERE cod = 'EU27_2020' AND anio = (SELECT a FROM u)) / max(indice) FILTER (WHERE cod = 'EU27_2020' AND anio = 2019) - 1) AS ue_var_2019,
    100 * (max(indice) FILTER (WHERE cod = 'ES' AND anio = (SELECT a FROM u)) / max(indice) FILTER (WHERE cod = 'ES' AND anio = 2007) - 1) AS es_var_2007,
    100 * (max(indice) FILTER (WHERE cod = 'EU27_2020' AND anio = (SELECT a FROM u)) / max(indice) FILTER (WHERE cod = 'EU27_2020' AND anio = 2007) - 1) AS ue_var_2007
FROM e
```

```sql ipi_mes
SELECT mes, indice, variacion_anual_pct, variacion_acumulada_pct,
       list_extract(['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'], month(mes))
           || ' de ' || CAST(year(mes) AS VARCHAR) AS mes_txt
FROM mother.industria_ipi_mensual
WHERE cod_ccaa = '00' AND destino = 'Total industria' AND indice IS NOT NULL
  AND mes > (SELECT max(mes) FROM mother.industria_ipi_mensual) - INTERVAL 36 MONTH
ORDER BY mes
```

```sql ipi_ult
SELECT * FROM ${ipi_mes} ORDER BY mes DESC LIMIT 1
```

```sql ipi_destinos
SELECT destino, variacion_anual_pct, variacion_acumulada_pct
FROM mother.industria_ipi_mensual
WHERE cod_ccaa = '00' AND es_ultimo_mes AND destino <> 'Total industria'
ORDER BY variacion_acumulada_pct DESC
```

```sql exportaciones
SELECT partida, partida_nombre, CAST(anio AS INTEGER) AS anio, cuota_pct, CAST(puesto AS INTEGER) AS puesto,
       CAST(puesto_sin_nl_be AS INTEGER) AS puesto_sin_nl_be, lider_nombre AS lider, cuota_nl_be_pct,
       veces_peso_poblacion, exportacion_es_real_meur, peso_en_exportacion_es_pct,
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
SELECT c.cod_ccaa, c.ccaa AS comunidad, '/gl' || t.ruta AS ruta, CAST(c.anio AS INTEGER) AS anio, c.pct_vab_industria, c.pct_vab_manufacturas,
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
SELECT t.nombre AS comunidad, '/gl' || t.ruta AS ruta, p.rama_principal, p.peso_principal, e.rama_especial, e.veces, e.cuota_especial
FROM principal p
LEFT JOIN especial e USING (cod_ccaa)
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = p.cod_ccaa
ORDER BY p.peso_principal DESC
```

```sql ccaa_ramas_anio
SELECT CAST(max(anio) AS INTEGER) AS anio FROM mother.industria_ccaa_ramas
```

# 🏭 Industria

España non está entre os países máis industriais da Unión Europea: as súas manufacturas pesan menos na economía que a media europea. Pero nalgúns produtos é unha potencia de primeira orde, desde os coches e os azulexos ata o aceite de oliva, o xamón curado, o material ferroviario ou as torres dos aeroxeradores. Esta páxina mostra os dous lados con datos de Eurostat, o INE, OICA e ANFAC, sempre en proporción á poboación ou ao total europeo.

<Grid cols=4>
    <KpiCard
        title="Vehículos fabricados"
        value={veh_res[0]?.veh_1000}
        formattedValue="{formatNumber(veh_res[0]?.veh_1000, 1)} por 1.000 hab."
        period="{veh_res[0]?.anio} · {formatNumber(veh_res[0]?.vehiculos_millones, 2)} millóns · {veh_res[0]?.puesto_europa}.º de Europa (OICA {veh_res[0]?.anio_oica})"
        change={veh_res[0]?.var_anual?.toFixed(1)}
        changePeriod="vs {veh_res[0]?.anio_ant}"
        direction="positive-up"
        source="OICA e ANFAC"
        sparklineData={veh.map(d => d.vehiculos_1000_hab)}
    />
    <KpiCard
        title="Azulexos: cota da produción da UE"
        value={prod_res[0]?.az_cuota}
        formattedValue="{formatNumber(prod_res[0]?.az_cuota, 1)} %"
        period="{prod_res[0]?.anio} · en m² · {prod_res[0]?.az_puesto}.º dos {prod_res[0]?.az_n} países que publican o dato"
        direction="positive-up"
        source="Eurostat (Prodcom)"
        sparklineData={azulejos.map(d => d.cuota_cantidad_pct)}
    />
    <KpiCard
        title="Peso das manufacturas na economía"
        value={peso_res[0]?.es_manuf}
        formattedValue="{formatNumber(peso_res[0]?.es_manuf, 1)} % do VEB"
        period="{peso_res[0]?.anio} · UE: {formatNumber(peso_res[0]?.ue_manuf, 1)} % · posto {peso_res[0]?.es_puesto} de {peso_res[0]?.n_paises}"
        change={peso_res[0]?.dif_manuf?.toFixed(1)}
        changeUnit="pp"
        changePeriod="fronte á UE"
        direction="positive-up"
        source="Eurostat (nama_10_a10)"
        sparklineData={peso_es.map(d => d.pct_vab_manufacturas)}
    />
    <KpiCard
        title="Índice de produción industrial"
        value={ipi_ult[0]?.indice}
        formattedValue={formatNumber(ipi_ult[0]?.indice, 1)}
        period="{mesGl(ipi_ult[0]?.mes_txt)} · base 2021 = 100 · índice orixinal"
        change={ipi_ult[0]?.variacion_anual_pct?.toFixed(1)}
        changePeriod="interanual"
        direction="positive-up"
        source="INE (IPI, táboa 70177)"
        sparklineData={ipi_mes.map(d => d.indice)}
    />
</Grid>

## Onde destaca España

España ten o {formatNumber(ramas_res[0]?.cuota_pob, 1)} % da poboación da UE. Se unha rama industrial española factura máis desa proporción do total europeo, España produce máis do que lle tocaría por habitantes; o cociente («veces o seu peso en poboación») resúmeo: 1 é o esperable, 2 é o dobre. Nas manufacturas en conxunto a cota é o {formatNumber(ramas_res[0]?.c_cuota, 1)} % ({ramas_res[0]?.c_puesto}.º da UE por cifra de negocios), por debaixo do seu peso en poboación. Só {ramas_res[0]?.n_por_encima} das {ramas_res[0]?.n_ramas} ramas da táboa o superan, e a que máis destaca é a de **azulexos e baldosas cerámicas**: o {formatNumber(ramas_res[0]?.az_cuota, 1)} % da cifra de negocios europea, {formatNumber(ramas_res[0]?.az_veces, 1)} veces o seu peso en poboación.

<BarChart
    data={ramas}
    x=rama_nombre
    y=cuota_cifra_negocios_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% da cifra de negocios da UE"
    seriesColors={{'Más que su peso en población': '#c2410c', 'Menos que su peso en población': '#94a3b8'}}
    title="Cota de España na cifra de negocios de cada rama industrial da UE ({ramas_res[0]?.anio}, %)"
/>

<DataTable data={ramas} rows=12 search=true>
    <Column id=rama_nombre title="Rama" />
    <Column id=cuota_cifra_negocios_pct title="Cota UE %" fmt='0.0' />
    <Column id=veces_peso_poblacion title="Veces o seu peso en poboación" fmt='0.00' />
    <Column id=puesto_txt title="Posto (entre os que publican)" />
    <Column id=lider title="País líder" />
    <Column id=peso_manuf_es_pct title="Peso nas manufacturas de España %" fmt='0.0' />
    <Column id=peso_manuf_ue_pct title="Peso nas manufacturas da UE %" fmt='0.0' />
    <Column id=cifra_negocios_es_real_meur title="Cifra de negocios España (M€ de 2025)" fmt='#,##0' />
</DataTable>

As ramas mídense pola cifra de negocios das empresas (Eurostat, estatísticas estruturais de empresas). O total da UE é a estimación de Eurostat, que inclúe os países con datos confidenciais; o posto, en cambio, só se pode calcular entre os países que publican a cifra, así que, por exemplo, «2.º de 19» quere dicir segundo dos 19 que a publican.

### Produtos concretos

As estatísticas de produción industrial (Prodcom) baixan ao detalle de cada produto, en unidades físicas: metros cadrados, toneladas, unidades. España é o primeiro produtor en {prod_res[0]?.n_primeros} dos {prod_res[0]?.n_productos} produtos da lista, con cotas de máis da metade da produción europea en esmaltes e fritas cerámicas ({formatNumber(prod_res[0]?.fri_cuota, 0)} %), olivas de mesa ({formatNumber(prod_res[0]?.acei_cuota, 0)} %) ou aceite de oliva virxe ({formatNumber(prod_res[0]?.ac_cuota, 0)} %).

**Ollo con dúas trampas.** A cota calcúlase sobre o **total da UE que estima Eurostat** (un agregado redondeado que inclúe a produción confidencial dos países que non a publican), non sobre a suma dos países con dato, que a inflaría. E o **posto é só entre os países que publican a cifra**: en moitos produtos son poucos (no aceite de oliva virxe, {prod_res[0]?.ac_n}; nas fritas cerámicas, {prod_res[0]?.fri_n}), porque os demais a declaran confidencial. Ser o primeiro de cinco non garante ser o primeiro da UE, aínda que cunha cota por riba do 50 % non pode haber outro país maior.

<BarChart
    data={productos}
    x=producto_nombre
    y=cuota_cantidad_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% da produción da UE (en cantidade)"
    seriesColors={{'Más que su peso en población': '#c2410c', 'Menos que su peso en población': '#94a3b8'}}
    title="Cota de España na produción da UE de cada produto ({prod_res[0]?.anio}, % en cantidade)"
/>

<DataTable data={productos} rows=12 search=true>
    <Column id=producto_nombre title="Produto" />
    <Column id=cuota_cantidad_pct title="Cota UE en cantidade %" fmt='0.0' />
    <Column id=cuota_valor_pct title="Cota UE en valor %" fmt='0.0' />
    <Column id=veces_peso_poblacion title="Veces o seu peso en poboación" fmt='0.00' />
    <Column id=puesto_txt title="Posto (entre os que publican)" />
    <Column id=lider title="Maior produtor con dato" />
    <Column id=cantidad_es_legible title="Produción de España" fmt='#,##0.0' />
    <Column id=unidad_legible title="Unidade" />
    <Column id=valor_es_real_meur title="Valor España (M€ de 2025)" fmt='#,##0' />
</DataTable>

## O automóbil

España fabricou **{formatNumber(veh_res[0]?.vehiculos_millones, 2)} millóns de vehículos en {veh_res[0]?.anio}**, {formatNumber(veh_res[0]?.veh_1000, 1)} por cada 1.000 habitantes, {#if veh_res[0]?.var_anual < 0}un {formatNumber(-veh_res[0]?.var_anual, 1)} % menos{:else}un {formatNumber(veh_res[0]?.var_anual, 1)} % máis{/if} que en {veh_res[0]?.anio_ant} e {#if veh_res[0]?.var_2019 < 0}un {formatNumber(-veh_res[0]?.var_2019, 1)} % menos{:else}un {formatNumber(veh_res[0]?.var_2019, 1)} % máis{/if} que en 2019, cando saíron das súas fábricas {formatNumber(veh_res[0]?.veh_2019_millones, 2)} millóns. Exportou o **{formatNumber(veh_res[0]?.pct_exportado, 1)} %** do que produciu en {veh_res[0]?.anio_exportado}. No último ano con datos de todos os países ({veh_res[0]?.anio_oica}) foi o **{veh_res[0]?.puesto_europa}.º fabricante de Europa**, só por detrás de Alemaña, e o **{veh_res[0]?.puesto_mundo}.º do mundo**, co {formatNumber(veh_res[0]?.cuota_mundo, 1)} % da produción mundial. Para {veh_res[0]?.anio} só hai o dato español; ANFAC, a patronal do sector, afirma que mantén ambos os postos.

<BarChart
    data={veh}
    x=anio
    y=vehiculos_1000_hab
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="vehículos por 1.000 habitantes"
    title="Vehículos fabricados en España por 1.000 habitantes (2020 sen dato na serie)"
/>

<LineChart
    data={veh}
    x=anio
    y=puesto_europa
    y2=puesto_mundo
    xFmt='0'
    yFmt='0'
    markers=true
    yAxisTitle="posto en Europa"
    y2AxisTitle="posto no mundo"
    title="Posto de España entre os fabricantes de vehículos de Europa e do mundo (OICA)"
/>

En proporción á poboación, os países que máis vehículos fabrican son Eslovaquia ({formatNumber(veh_lideres[0]?.sk_1000, 0)} por 1.000 habitantes) e Chequia ({formatNumber(veh_lideres[0]?.cz_1000, 0)}). España ({formatNumber(veh_res[0]?.veh_1000_oica, 1)}) está á par de Alemaña ({formatNumber(veh_lideres[0]?.de_1000, 1)}), aínda que a cifra alemá de OICA só conta turismos, e moi por riba de Francia ({formatNumber(veh_lideres[0]?.fr_1000, 1)}, sen camións nin autobuses) ou Italia ({formatNumber(veh_lideres[0]?.it_1000, 1)}).

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
    title="Vehículos fabricados por 1.000 habitantes nos fabricantes da UE ({veh_res[0]?.anio_oica})"
/>

<DataTable data={veh_europa} rows=15>
    <Column id=puesto_europa title="Posto en Europa" />
    <Column id=pais title="País" />
    <Column id=vehiculos title="Vehículos fabricados" fmt='#,##0' />
    <Column id=vehiculos_1000_hab title="Por 1.000 hab." fmt='0.0' />
    <Column id=puesto_mundo title="Posto no mundo" />
    <Column id=cobertura title="Que conta OICA" />
</DataTable>

### As fábricas

ANFAC recolle {fab_res[0]?.plantas} fábricas de vehículos e compoñentes en {fab_res[0]?.comunidades} comunidades; {fab_res[0]?.plantas_montaje} montan vehículos, con {fab_res[0]?.modelos} modelos en produción ({fab_res[0]?.electrificados} deles eléctricos ou híbridos) e {fab_res[0]?.adjudicados} máis adxudicados para os próximos anos. A que máis modelos fabrica é {fab_res[0]?.mas_modelos} ({fab_res[0]?.max_modelos}). Por cifra de negocios da rama, as comunidades con máis peso na fabricación de vehículos son {veh_ccaa_txt[0]?.lista} do total español.

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
        {id: 'tipo', title: 'Que fabrica'},
        {id: 'municipio', title: 'Municipio'},
        {id: 'n_modelos', title: 'Modelos en produción', fmt: '0'},
        {id: 'modelos', title: 'Modelos'}
    ]}
/>

O tamaño do punto é o número de modelos en produción; a posición é a do municipio (as dúas fábricas de Barcelona e as dúas de Madrid superpóñense).

<DataTable data={fabricas} rows=16 search=true>
    <Column id=fabrica title="Fábrica" />
    <Column id=grupo title="Grupo" />
    <Column id=tipo title="Que fabrica" />
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=modelos title="Modelos en produción" />
    <Column id=modelos_adjudicados title="Modelos adxudicados" />
    <Column id=otras_producciones title="Outras producións" />
</DataTable>

## Azulexos e cerámica

España produciu **{formatNumber(prod_res[0]?.az_mm2, 0)} millóns de m² de baldosas e azulexos cerámicos en {prod_res[0]?.anio}**, uns {formatNumber(prod_res[0]?.az_m2_1000, 0)} m² por cada 1.000 habitantes: o {formatNumber(prod_res[0]?.az_cuota, 1)} % da produción europea en superficie ({formatNumber(prod_res[0]?.az_veces, 1)} veces o seu peso en poboación) e o {formatNumber(prod_res[0]?.az_cuota_valor, 1)} % en valor. É o 1.º dos {prod_res[0]?.az_n} países que publican o dato. Como a súa cota en valor é menor que en superficie, o prezo medio da súa produción por m² é inferior ao do conxunto europeo. En cifra de negocios da rama (Eurostat, empresas) España é {ramas_res[0]?.az_puesto}.ª de {ramas_res[0]?.az_n} países con dato, co {formatNumber(ramas_res[0]?.az_cuota, 1)} %; a primeira é {ramas_res[0]?.az_lider}. As fritas e esmaltes cos que se recobren as pezas son tamén unha especialidade española: o {formatNumber(prod_res[0]?.fri_cuota, 0)} % da produción da UE.

A rama de minerais non metálicos (cerámica, vidro, cemento) está moi concentrada: {ceramica_ccaa[0]?.comunidad} reúne o {formatNumber(ceramica_ccaa[0]?.cuota_espana_pct, 0)} % da súa cifra de negocios en España, {formatNumber(ceramica_ccaa[0]?.veces_peso_poblacion, 1)} veces o seu peso en poboación.

<LineChart
    data={azulejos}
    x=anio
    y=cuota_cantidad_pct
    y2=cuota_valor_pct
    xFmt='0'
    yFmt='0.0'
    y2Fmt='0.0'
    markers=true
    yAxisTitle="% da UE en m²"
    y2AxisTitle="% da UE en valor"
    title="Cota de España na produción de baldosas e azulexos da UE (%)"
/>

## Alimentación e bebidas

A alimentación é a **primeira rama manufactureira de España**: o {formatNumber(ramas_res[0]?.ali_peso_es, 1)} % do valor engadido das súas manufacturas, fronte ao {formatNumber(ramas_res[0]?.ali_peso_ue, 1)} % na UE{#if ramas_rank[0]?.ali_puesto_ue > 1}, onde é a {ramas_rank[0]?.ali_puesto_ue}.ª (a primeira é {ramas_rank[0]?.primera_ue}, co {formatNumber(ramas_rank[0]?.primera_ue_peso, 1)} %){/if}. As súas empresas facturan o {formatNumber(ramas_res[0]?.ali_cuota, 1)} % da alimentación europea ({ramas_res[0]?.ali_puesto}.º país; o primeiro é {ramas_res[0]?.ali_lider}). As bebidas pesan o {formatNumber(ramas_res[0]?.beb_peso_es, 1)} % fronte ao {formatNumber(ramas_res[0]?.beb_peso_ue, 1)} % e supoñen o {formatNumber(ramas_res[0]?.beb_cuota, 1)} % da UE.

En produtos concretos, España produce o {formatNumber(prod_res[0]?.ac_cuota, 0)} % do aceite de oliva virxe da UE ({formatNumber(prod_res[0]?.ac_kt, 0)} miles de toneladas), o {formatNumber(prod_res[0]?.acei_cuota, 0)} % das olivas de mesa e o {formatNumber(prod_res[0]?.jam_cuota, 0)} % dos xamóns e lacóns curados con óso ({prod_res[0]?.jam_puesto}.º de {prod_res[0]?.jam_n} países con dato). En viño espumoso é {prod_res[0]?.cava_puesto}.º de {prod_res[0]?.cava_n}, co {formatNumber(prod_res[0]?.cava_cuota, 0)} % (o champaña non entra neste código).

<BarChart
    data={ramas_peso}
    x=rama_nombre
    y=peso
    series=territorio
    type=grouped
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% do valor engadido das manufacturas"
    seriesColors={{'España': '#c2410c', 'Unión Europea': '#64748b'}}
    title="Peso de cada rama nas manufacturas: España fronte á UE ({ramas_res[0]?.anio}, % do valor engadido)"
/>

O gráfico ensina tamén onde está a diferenza con Europa: España ten moito menos peso en **maquinaria**, **farmacia** e **electrónica**, ramas nas que factura o {formatNumber(ramas_res[0]?.maq_cuota, 1)} %, o {formatNumber(ramas_res[0]?.far_cuota, 1)} % e o {formatNumber(ramas_res[0]?.ele_cuota, 1)} % do total europeo.

## Outros sectores fortes

- **Material ferroviario.** A rama factura o {formatNumber(ramas_res[0]?.fer_cuota, 1)} % da UE ({ramas_res[0]?.fer_puesto}.º de {ramas_res[0]?.fer_n} países con dato, o primeiro é {ramas_res[0]?.fer_lider}; {formatNumber(ramas_res[0]?.fer_veces, 1)} veces o seu peso en poboación). En coches de viaxeiros de tren e tranvía, España fabricou {formatNumber(prod_res[0]?.tren_uds, 0)} unidades, o {formatNumber(prod_res[0]?.tren_cuota, 0)} % da estimación europea (só {prod_res[0]?.tren_n} países publican o dato), e é a {exp_res[0]?.tren_puesto}.ª exportadora da UE, co {formatNumber(exp_res[0]?.tren_cuota, 0)} %.
- **Aeronáutica.** O {formatNumber(ramas_res[0]?.aer_cuota, 1)} % da cifra de negocios europea ({ramas_res[0]?.aer_puesto}.º de {ramas_res[0]?.aer_n} con dato; lidera {ramas_res[0]?.aer_lider}), algo por debaixo do seu peso en poboación.
- **Refinado de petróleo.** O {formatNumber(ramas_res[0]?.ref_cuota, 1)} % da UE ({ramas_res[0]?.ref_puesto}.º de {ramas_res[0]?.ref_n} con dato); pesa o {formatNumber(ramas_res[0]?.ref_peso_es, 1)} % das manufacturas españolas fronte ao {formatNumber(ramas_res[0]?.ref_peso_ue, 1)} % na UE.
- **Renovables.** España fabricou {formatNumber(prod_res[0]?.tor_kt, 0)} miles de toneladas de torres e castelos de aceiro, o {formatNumber(prod_res[0]?.tor_cuota, 0)} % da UE ({prod_res[0]?.tor_puesto}.º de {prod_res[0]?.tor_n} con dato; o código inclúe as torres eólicas e outras estruturas de celosía), e {formatNumber(prod_res[0]?.aero_uds, 0)} aeroxeradores, o {formatNumber(prod_res[0]?.aero_cuota, 0)} % ({prod_res[0]?.aero_puesto}.º de só {prod_res[0]?.aero_n} que publican, tras {prod_res[0]?.aero_lider}). Na rama de motores e turbinas, que mestura aeroxeradores con turbinas doutro tipo, a cota baixa ao {formatNumber(ramas_res[0]?.tur_cuota, 1)} %.
- **Barcos de pesca e cemento.** O {formatNumber(prod_res[0]?.pes_cuota, 0)} % do arqueo dos buques de pesca construídos na UE (de {prod_res[0]?.pes_n} países con dato) e o {formatNumber(prod_res[0]?.cem_cuota, 1)} % do cemento Portland ({prod_res[0]?.cem_puesto}.º de {prod_res[0]?.cem_n}).

<DataTable data={otros} rows=14>
    <Column id=nombre title="Rama ou produto" />
    <Column id=tipo title="Medida" />
    <Column id=cuota title="Cota UE %" fmt='0.0' />
    <Column id=veces_peso_poblacion title="Veces o seu peso en poboación" fmt='0.00' />
    <Column id=puesto_txt title="Posto (entre os que publican)" />
    <Column id=lider title="Primeiro con dato" />
</DataTable>

## Exportacións industriais

España vende ao exterior (incluídos os demais países da UE) o {formatNumber(exp_res[0]?.tot_cuota, 1)} % de todas as exportacións de bens dos 27, por debaixo do seu {formatNumber(exp_res[0]?.cuota_pob, 1)} % da poboación: {exp_res[0]?.tot_puesto}.º exportador en {exp_res[0]?.anio}, con {formatNumber(exp_res[0]?.tot_real_mm, 0)} mil millóns de euros de 2025. Fóra da UE a cota é o {formatNumber(exp_res[0]?.ext_cuota, 1)} % ({exp_res[0]?.ext_puesto}.º). Onde si destaca é en aceite de oliva ({formatNumber(exp_res[0]?.ace_cuota, 0)} % do que exporta a UE), fritas e esmaltes cerámicos ({formatNumber(exp_res[0]?.fri_cuota, 0)} %), coches de tren ({formatNumber(exp_res[0]?.tren_cuota, 0)} %) e azulexos ({formatNumber(exp_res[0]?.az_cuota, 0)} %, {exp_res[0]?.az_puesto}.º tras {exp_res[0]?.az_lider}). Os turismos son o {formatNumber(exp_res[0]?.tur_cuota, 1)} % da UE ({exp_res[0]?.tur_puesto}.º) e os vehículos en conxunto, o {formatNumber(exp_res[0]?.veh_peso, 1)} % de todo o que exporta España.

**A trampa dos Países Baixos e Bélxica.** Róterdam e Amberes son a porta de entrada de mercadorías a Europa, e o que entra polos seus portos e se reenvía a outro país conta como exportación súa aínda que non o fabricasen. Entre os dous suman o {formatNumber(exp_res[0]?.tot_nl_be, 1)} % das exportacións da UE e o {formatNumber(exp_res[0]?.ref_nl_be, 0)} % das de produtos refinados do petróleo. Sen contalos, España sería {exp_res[0]?.tot_puesto_sin}.ª no total, {exp_res[0]?.tur_puesto_sin}.ª en turismos e {exp_res[0]?.ref_puesto_sin}.ª en produtos refinados (en vez de {exp_res[0]?.ref_puesto}.ª). A táboa dá os dous postos.

<BarChart
    data={exportaciones}
    x=partida_nombre
    y=cuota_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% das exportacións dos 27"
    seriesColors={{'Más que su peso en población': '#c2410c', 'Menos que su peso en población': '#94a3b8'}}
    title="Cota de España nas exportacións da UE por produto ({exp_res[0]?.anio}, %, incluído o comercio dentro da UE)"
/>

<DataTable data={exportaciones} rows=12 search=true>
    <Column id=partida_nombre title="Produto" />
    <Column id=cuota_pct title="Cota UE %" fmt='0.0' />
    <Column id=puesto title="Posto" />
    <Column id=puesto_sin_nl_be title="Posto sen NL nin BE" />
    <Column id=lider title="Primeiro exportador" />
    <Column id=cuota_nl_be_pct title="NL + BE, % da UE" fmt='0.0' />
    <Column id=peso_en_exportacion_es_pct title="% das exportacións españolas" fmt='0.00' />
    <Column id=exportacion_es_real_meur title="Exportación España (M€ de 2025)" fmt='#,##0' />
</DataTable>

## Canta industria ten España?

As manufacturas xeran o **{formatNumber(peso_res[0]?.es_manuf, 1)} % do valor engadido bruto (VEB) español en {peso_res[0]?.anio}**, fronte ao {formatNumber(peso_res[0]?.ue_manuf, 1)} % da UE: posto {peso_res[0]?.es_puesto} de {peso_res[0]?.n_paises}. En 1995 eran o {formatNumber(peso_res[0]?.es_manuf_1995, 1)} % (a UE, o {formatNumber(peso_res[0]?.ue_manuf_1995, 1)} %). Con toda a industria, que suma enerxía, auga, residuos e minas, a proporción é o {formatNumber(peso_res[0]?.es_ind, 1)} % fronte ao {formatNumber(peso_res[0]?.ue_ind, 1)} %. En emprego, as manufacturas ocupan o {formatNumber(peso_res[0]?.es_emp, 1)} % dos traballadores en España e o {formatNumber(peso_res[0]?.ue_emp, 1)} % na UE.

Por habitante, o VEB manufactureiro español é de {formatNumber(peso_res[0]?.es_hab, 0)} € ao ano, o {formatNumber(peso_res[0]?.es_hab_pct_ue, 0)} % da media europea ({formatNumber(peso_res[0]?.ue_hab, 0)} €): España achega o {formatNumber(peso_res[0]?.es_cuota_vab, 1)} % do VEB manufactureiro da UE co {formatNumber(peso_res[0]?.es_cuota_pob, 1)} % da súa poboación. En euros constantes de 2025, o VEB manufactureiro por habitante de España é {#if peso_res[0]?.es_hab_real_var_2008 < 0}un {formatNumber(-peso_res[0]?.es_hab_real_var_2008, 1)} % menor{:else}un {formatNumber(peso_res[0]?.es_hab_real_var_2008, 1)} % maior{/if} que en 2008 ({formatNumber(peso_res[0]?.es_hab_real_2008, 0)} € entón, {formatNumber(peso_res[0]?.es_hab_real, 0)} € en {peso_res[0]?.anio}).

<LineChart
    data={peso_serie}
    x=anio
    y=pct_vab_manufacturas
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% do VEB total"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399', 'Polonia': '#a78bfa', 'Portugal': '#fbbf24'}}
    title="Peso das manufacturas no VEB (% a prezos correntes)"
/>

<BarChart
    data={peso_ult}
    x=pais
    y=pct_vab_manufacturas
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% do VEB total"
    seriesColors={{'España': '#c2410c', 'Media UE': '#0f172a', 'Otros países': '#94a3b8'}}
    title="Peso das manufacturas no VEB de cada país da UE ({peso_res[0]?.anio}, %)"
/>

<DataTable data={peso_ult} rows=28 search=true>
    <Column id=puesto title="Posto" />
    <Column id=pais title="País" />
    <Column id=pct_vab_manufacturas title="Manufacturas, % do VEB" fmt='0.0' />
    <Column id=pct_vab_industria title="Industria, % do VEB" fmt='0.0' />
    <Column id=pct_empleo_manufacturas title="Manufacturas, % do emprego" fmt='0.0' />
    <Column id=pct_empleo_industria title="Industria, % do emprego" fmt='0.0' />
    <Column id=vab_manuf_hab_eur title="VEB manufactureiro por hab. (€ correntes)" fmt='#,##0' />
</DataTable>

Que perda peso non quere dicir que produza menos: o peso mídese en prezos correntes e depende tamén do que medren os servizos. En **volume** (descontada a evolución dos prezos), o VEB manufactureiro español de {peso_res[0]?.anio} equivale a {formatNumber(peso_res[0]?.es_vol, 1)} se 2015 = 100 (en 2008, {formatNumber(peso_res[0]?.es_vol_2008, 1)}); o da UE, a {formatNumber(peso_res[0]?.ue_vol, 1)} (en 2008, {formatNumber(peso_res[0]?.ue_vol_2008, 1)}).

<LineChart
    data={peso_serie}
    x=anio
    y=vab_manuf_real_indice
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="índice 2015 = 100"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399', 'Polonia': '#a78bfa', 'Portugal': '#fbbf24'}}
    title="VEB das manufacturas en volume (índice 2015 = 100)"
/>

<LineChart
    data={peso_serie}
    x=anio
    y=pct_empleo_manufacturas
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% dos ocupados"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399', 'Polonia': '#a78bfa', 'Portugal': '#fbbf24'}}
    title="Peso das manufacturas no emprego (% dos ocupados)"
/>

## Produción industrial

O índice de produción industrial (IPI) mide canto se produce en cantidades, sen efecto dos prezos. En {ipi_res[0]?.anio}, a produción da industria española variou un {formatNumber(ipi_res[0]?.es_var, 1)} % respecto ao ano anterior (UE: {formatNumber(ipi_res[0]?.ue_var, 1)} %). Respecto a 2019 a variación é do {formatNumber(ipi_res[0]?.es_var_2019, 1)} % en España e do {formatNumber(ipi_res[0]?.ue_var_2019, 1)} % na UE; respecto a 2007, antes da crise financeira, do {formatNumber(ipi_res[0]?.es_var_2007, 1)} % e do {formatNumber(ipi_res[0]?.ue_var_2007, 1)} %.

<LineChart
    data={ipi_anual}
    x=anio
    y=indice
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="índice 2021 = 100"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399'}}
    title="Índice de produción industrial anual (industria sen construción, 2021 = 100, corrixido de calendario)"
/>

O último dato mensual do INE é de **{mesGl(ipi_ult[0]?.mes_txt)}**: índice {formatNumber(ipi_ult[0]?.indice, 1)}, un {formatNumber(ipi_ult[0]?.variacion_anual_pct, 1)} % respecto ao mesmo mes do ano anterior, e unha variación acumulada no que vai de ano do {formatNumber(ipi_ult[0]?.variacion_acumulada_pct, 1)} %. O índice mensual orixinal sobe e baixa co calendario (agosto é o mes máis baixo todos os anos agás 2020), así que a comparación útil é co mesmo mes do ano anterior.

<LineChart
    data={ipi_mes}
    x=mes
    y=indice
    yFmt='0.0'
    yAxisTitle="índice 2021 = 100"
    title="Índice de produción industrial mensual de España (orixinal, últimos 36 meses)"
/>

<BarChart
    data={ipi_destinos}
    x=destino
    y=variacion_acumulada_pct
    swapXY=true
    yFmt='0.0'
    yAxisTitle="% sobre o mesmo período do ano anterior"
    title="Variación da produción no que vai de ano ata {mesGl(ipi_ult[0]?.mes_txt)}, por destino económico (%)"
/>

## Por comunidade

A industria pesa moi distinto segundo a comunidade. En {ccaa_res[0]?.anio}, as máis industriais por peso no seu VEB eran {ccaa_res[0]?.mas}; a media española é o {formatNumber(ccaa_espana[0]?.pct_vab_industria, 1)} % e {ccaa_res[0]?.n_sobre_media} comunidades supérana. En Navarra a industria dá emprego a {formatNumber(ccaa_res[0]?.navarra_ocup, 0)} persoas por cada 1.000 habitantes, fronte a {formatNumber(ccaa_espana[0]?.ocupados_industria_1000_hab, 0)} de media. As que menos dependen da industria son {ccaa_res[0]?.menos}. Cataluña concentra o {formatNumber(ccaa_res[0]?.cat_cuota, 1)} % do VEB industrial de España. Preme nunha comunidade para ver a súa ficha.

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
        {id: 'pct_vab_industria', title: 'Industria, % do VEB', fmt: '0.0'},
        {id: 'pct_vab_manufacturas', title: 'Manufacturas, % do VEB', fmt: '0.0'},
        {id: 'vab_industria_hab_real', title: 'VEB industrial por hab. (€ de 2025)', fmt: '#,##0'},
        {id: 'ocupados_industria_1000_hab', title: 'Ocupados na industria por 1.000 hab.', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=puesto title="Posto" />
    <Column id=comunidad title="Comunidade" />
    <Column id=pct_vab_industria title="Industria, % do VEB" fmt='0.0' />
    <Column id=pct_vab_manufacturas title="Manufacturas, % do VEB" fmt='0.0' />
    <Column id=vab_industria_hab_real title="VEB industrial por hab. (€ de 2025)" fmt='#,##0' />
    <Column id=cifra_negocios_hab_real title="Cifra de negocios industrial por hab. (€ de 2025)" fmt='#,##0' />
    <Column id=ocupados_industria_1000_hab title="Ocupados na industria por 1.000 hab." fmt='0.0' />
    <Column id=cuota_vab_industria_espana_pct title="% do VEB industrial de España" fmt='0.0' />
</DataTable>

### As ramas fortes de cada comunidade

Para cada comunidade, a rama que máis pesa na súa industria (en cifra de negocios) e a rama na que está máis especializada respecto á súa poboación: a cota da comunidade nesa rama en España dividida entre o seu peso na poboación española (só ramas que supoñen polo menos o 5 % da súa industria e que publican dez comunidades ou máis; datos do INE de {ccaa_ramas_anio[0]?.anio}, sen Ceuta nin Melilla).

<DataTable data={ccaa_ramas} rows=17 link=ruta>
    <Column id=comunidad title="Comunidade" />
    <Column id=rama_principal title="Rama con máis peso" />
    <Column id=peso_principal title="% da súa industria" fmt='0.0' />
    <Column id=rama_especial title="Rama máis especializada" />
    <Column id=veces title="Veces o seu peso en poboación" fmt='0.0' />
    <Column id=cuota_especial title="% desa rama en España" fmt='0.0' />
</DataTable>

## Metodoloxía e fontes

- **Peso da industria na UE:** Eurostat, contas nacionais por rama [nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table) (VEB a prezos correntes e en volume encadeado, base 2010) e [nama_10_a10_e](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10_e/default/table) (emprego); poboación, [nama_10_pe](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe/default/table). Manufacturas = sección C da NACE; industria = seccións B a E (minas, manufacturas, enerxía, auga e residuos).
- **Ramas industriais:** Eurostat, estatísticas estruturais de empresas [sbs_ovw_act](https://ec.europa.eu/eurostat/databrowser/view/sbs_ovw_act/default/table) (cifra de negocios, valor engadido e emprego). O total da UE é a estimación de Eurostat; se non existe, a suma dos países con dato (a táboa indícao na nota).
- **Produtos:** Eurostat, Prodcom [DS-059358](https://ec.europa.eu/eurostat/databrowser/view/DS-059358/default/table) (produción vendida). Cota sobre o agregado EU27_2020 estimado por Eurostat; posto entre os países que publican o dato.
- **Exportacións:** Eurostat, Comext [DS-045409](https://ec.europa.eu/eurostat/databrowser/view/DS-045409/default/table), por partida do Sistema Harmonizado; suma dos 27 países, con e sen o comercio dentro da UE.
- **Produción industrial:** Eurostat [sts_inpr_a](https://ec.europa.eu/eurostat/databrowser/view/sts_inpr_a/default/table) (anual, corrixido de calendario) e INE, Índice de Produción Industrial, [táboa 70177](https://www.ine.es/jaxiT3/Tabla.htm?t=70177) (mensual por comunidade e destino económico) e [táboa 60282](https://www.ine.es/jaxiT3/Tabla.htm?t=60282) (por división). Base 2021 = 100.
- **Comunidades:** Eurostat, VEB rexional [nama_10r_3gva](https://ec.europa.eu/eurostat/databrowser/view/nama_10r_3gva/default/table); INE, Estatística Estrutural de Empresas do sector industrial, [táboa 76823](https://www.ine.es/jaxiT3/Tabla.htm?t=76823) (cifra de negocios e ocupados por comunidade e rama; os datos con segredo estatístico non se publican).
- **Vehículos:** [OICA, produción mundial por país 2019-2024](https://oica.net/wp-content/uploads/2025/10/By-country-region-2024.pdf) (para Alemaña só turismos e para Francia só turismos e comerciais lixeiros; non hai dato de 2020 na serie). España {veh_res[0]?.anio}: [ANFAC, produción e exportación, peche de 2025](https://anfac.com/wp-content/uploads/2026/01/NP-Produccion-y-exportacion-diciembre-y-cierre-2025.pdf), que afirma: «España ocupa el 2.º lugar como fabricante de vehículos en Europa y el 9.º mundial». Fábricas: [ANFAC, mapa de fábricas con modelos en produción e adxudicados](https://anfac.com/cifras-clave/produccion-y-exportacion/) (maio de 2025); coordenadas do municipio, de Wikidata.
- Os euros exprésanse en euros constantes de 2025 co IPC do INE cando se comparan anos; as comparacións entre países do mesmo ano usan euros correntes. Os totais dánse en proporción á poboación (por habitante, por 1.000 habitantes ou en cota fronte ao peso en poboación).
