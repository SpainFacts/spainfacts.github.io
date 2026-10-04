---
title: Indústria
description: "On és Espanya una potència industrial (automòbil, rajoles, oli d'oliva, pernil, material ferroviari, torres eòliques) i quant pesa la seva indústria davant la mitjana de la UE: VAB i ocupació manufacturera, producció industrial, exportacions i comunitats."
i18n_origen: 276740ec377f
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
SELECT c.cod_ccaa, c.ccaa AS comunidad, '/ca' || t.ruta AS ruta, CAST(c.anio AS INTEGER) AS anio, c.pct_vab_industria, c.pct_vab_manufacturas,
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
SELECT t.nombre AS comunidad, '/ca' || t.ruta AS ruta, p.rama_principal, p.peso_principal, e.rama_especial, e.veces, e.cuota_especial
FROM principal p
LEFT JOIN especial e USING (cod_ccaa)
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = p.cod_ccaa
ORDER BY p.peso_principal DESC
```

```sql ccaa_ramas_anio
SELECT CAST(max(anio) AS INTEGER) AS anio FROM mother.industria_ccaa_ramas
```

# 🏭 Indústria

Espanya no és entre els països més industrials de la Unió Europea: les seves manufactures pesen menys en l'economia que la mitjana europea. Però en alguns productes és una potència de primer ordre, des dels cotxes i les rajoles fins a l'oli d'oliva, el pernil curat, el material ferroviari o les torres dels aerogeneradors. Aquesta pàgina mostra les dues cares amb dades d'Eurostat, l'INE, OICA i ANFAC, sempre en proporció a la població o al total europeu.

<Grid cols=4>
    <KpiCard
        title="Vehicles fabricats"
        value={veh_res[0]?.veh_1000}
        formattedValue="{formatNumber(veh_res[0]?.veh_1000, 1)} per 1.000 hab."
        period="{veh_res[0]?.anio} · {formatNumber(veh_res[0]?.vehiculos_millones, 2)} milions · {ordM(veh_res[0]?.puesto_europa)} d'Europa (OICA {veh_res[0]?.anio_oica})"
        change={veh_res[0]?.var_anual?.toFixed(1)}
        changePeriod="vs {veh_res[0]?.anio_ant}"
        direction="positive-up"
        source="OICA i ANFAC"
        sparklineData={veh.map(d => d.vehiculos_1000_hab)}
    />
    <KpiCard
        title="Rajoles: quota de la producció de la UE"
        value={prod_res[0]?.az_cuota}
        formattedValue="{formatNumber(prod_res[0]?.az_cuota, 1)} %"
        period="{prod_res[0]?.anio} · en m² · {ordM(prod_res[0]?.az_puesto)} dels {prod_res[0]?.az_n} països que publiquen la dada"
        direction="positive-up"
        source="Eurostat (Prodcom)"
        sparklineData={azulejos.map(d => d.cuota_cantidad_pct)}
    />
    <KpiCard
        title="Pes de les manufactures en l'economia"
        value={peso_res[0]?.es_manuf}
        formattedValue="{formatNumber(peso_res[0]?.es_manuf, 1)} % del VAB"
        period="{peso_res[0]?.anio} · UE: {formatNumber(peso_res[0]?.ue_manuf, 1)} % · lloc {peso_res[0]?.es_puesto} de {peso_res[0]?.n_paises}"
        change={peso_res[0]?.dif_manuf?.toFixed(1)}
        changeUnit="pp"
        changePeriod="davant la UE"
        direction="positive-up"
        source="Eurostat (nama_10_a10)"
        sparklineData={peso_es.map(d => d.pct_vab_manufacturas)}
    />
    <KpiCard
        title="Índex de producció industrial"
        value={ipi_ult[0]?.indice}
        formattedValue={formatNumber(ipi_ult[0]?.indice, 1)}
        period="{mesCa(ipi_ult[0]?.mes_txt)} · base 2021 = 100 · índex original"
        change={ipi_ult[0]?.variacion_anual_pct?.toFixed(1)}
        changePeriod="interanual"
        direction="positive-up"
        source="INE (IPI, taula 70177)"
        sparklineData={ipi_mes.map(d => d.indice)}
    />
</Grid>

## On destaca Espanya

Espanya té el {formatNumber(ramas_res[0]?.cuota_pob, 1)} % de la població de la UE. Si una branca industrial espanyola factura més d'aquesta proporció del total europeu, Espanya produeix més del que li tocaria per habitants; el quocient («vegades el seu pes en població») ho resumeix: 1 és l'esperable, 2 és el doble. En les manufactures en conjunt la quota és el {formatNumber(ramas_res[0]?.c_cuota, 1)} % ({ordM(ramas_res[0]?.c_puesto)} de la UE per xifra de negocis), per sota del seu pes en població. Només {ramas_res[0]?.n_por_encima} de les {ramas_res[0]?.n_ramas} branques de la taula el superen, i la que més destaca és la de **rajoles i paviments ceràmics**: el {formatNumber(ramas_res[0]?.az_cuota, 1)} % de la xifra de negocis europea, {formatNumber(ramas_res[0]?.az_veces, 1)} vegades el seu pes en població.

<BarChart
    data={ramas}
    x=rama_nombre
    y=cuota_cifra_negocios_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% de la xifra de negocis de la UE"
    seriesColors={{'Más que su peso en población': '#c2410c', 'Menos que su peso en población': '#94a3b8'}}
    title="Quota d'Espanya en la xifra de negocis de cada branca industrial de la UE ({ramas_res[0]?.anio}, %)"
/>

<DataTable data={ramas} rows=12 search=true>
    <Column id=rama_nombre title="Branca" />
    <Column id=cuota_cifra_negocios_pct title="Quota UE %" fmt='0.0' />
    <Column id=veces_peso_poblacion title="Vegades el seu pes en població" fmt='0.00' />
    <Column id=puesto_txt title="Lloc (entre els que publiquen)" />
    <Column id=lider title="País líder" />
    <Column id=peso_manuf_es_pct title="Pes en les manufactures d'Espanya %" fmt='0.0' />
    <Column id=peso_manuf_ue_pct title="Pes en les manufactures de la UE %" fmt='0.0' />
    <Column id=cifra_negocios_es_real_meur title="Xifra de negocis Espanya (M€ del 2025)" fmt='#,##0' />
</DataTable>

Les branques es mesuren per la xifra de negocis de les empreses (Eurostat, estadístiques estructurals d'empreses). El total de la UE és l'estimació d'Eurostat, que inclou els països amb dades confidencials; el lloc, en canvi, només es pot calcular entre els països que publiquen la xifra, així que, per exemple, «2.º de 19» vol dir segon dels 19 que la publiquen.

### Productes concrets

Les estadístiques de producció industrial (Prodcom) baixen al detall de cada producte, en unitats físiques: metres quadrats, tones, unitats. Espanya és el primer productor en {prod_res[0]?.n_primeros} dels {prod_res[0]?.n_productos} productes de la llista, amb quotes de més de la meitat de la producció europea en esmalts i frites ceràmiques ({formatNumber(prod_res[0]?.fri_cuota, 0)} %), olives de taula ({formatNumber(prod_res[0]?.acei_cuota, 0)} %) o oli d'oliva verge ({formatNumber(prod_res[0]?.ac_cuota, 0)} %).

**Compte amb dos paranys.** La quota es calcula sobre el **total de la UE que estima Eurostat** (un agregat arrodonit que inclou la producció confidencial dels països que no la publiquen), no sobre la suma dels països amb dada, que la inflaria. I el **lloc és només entre els països que publiquen la xifra**: en molts productes són pocs (en l'oli d'oliva verge, {prod_res[0]?.ac_n}; en les frites ceràmiques, {prod_res[0]?.fri_n}), perquè els altres la declaren confidencial. Ser el primer de cinc no garanteix ser el primer de la UE, tot i que amb una quota per sobre del 50 % no hi pot haver cap altre país més gran.

<BarChart
    data={productos}
    x=producto_nombre
    y=cuota_cantidad_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% de la producció de la UE (en quantitat)"
    seriesColors={{'Más que su peso en población': '#c2410c', 'Menos que su peso en población': '#94a3b8'}}
    title="Quota d'Espanya en la producció de la UE de cada producte ({prod_res[0]?.anio}, % en quantitat)"
/>

<DataTable data={productos} rows=12 search=true>
    <Column id=producto_nombre title="Producte" />
    <Column id=cuota_cantidad_pct title="Quota UE en quantitat %" fmt='0.0' />
    <Column id=cuota_valor_pct title="Quota UE en valor %" fmt='0.0' />
    <Column id=veces_peso_poblacion title="Vegades el seu pes en població" fmt='0.00' />
    <Column id=puesto_txt title="Lloc (entre els que publiquen)" />
    <Column id=lider title="Productor més gran amb dada" />
    <Column id=cantidad_es_legible title="Producció d'Espanya" fmt='#,##0.0' />
    <Column id=unidad_legible title="Unitat" />
    <Column id=valor_es_real_meur title="Valor Espanya (M€ del 2025)" fmt='#,##0' />
</DataTable>

## L'automòbil

Espanya va fabricar **{formatNumber(veh_res[0]?.vehiculos_millones, 2)} milions de vehicles el {veh_res[0]?.anio}**, {formatNumber(veh_res[0]?.veh_1000, 1)} per cada 1.000 habitants, {#if veh_res[0]?.var_anual < 0}un {formatNumber(-veh_res[0]?.var_anual, 1)} % menys{:else}un {formatNumber(veh_res[0]?.var_anual, 1)} % més{/if} que el {veh_res[0]?.anio_ant} i {#if veh_res[0]?.var_2019 < 0}un {formatNumber(-veh_res[0]?.var_2019, 1)} % menys{:else}un {formatNumber(veh_res[0]?.var_2019, 1)} % més{/if} que el 2019, quan van sortir de les seves fàbriques {formatNumber(veh_res[0]?.veh_2019_millones, 2)} milions. Va exportar el **{formatNumber(veh_res[0]?.pct_exportado, 1)} %** del que va produir el {veh_res[0]?.anio_exportado}. En l'últim any amb dades de tots els països ({veh_res[0]?.anio_oica}) va ser el **{ordM(veh_res[0]?.puesto_europa)} fabricant d'Europa**, només per darrere d'Alemanya, i el **{ordM(veh_res[0]?.puesto_mundo)} del món**, amb el {formatNumber(veh_res[0]?.cuota_mundo, 1)} % de la producció mundial. Per al {veh_res[0]?.anio} només hi ha la dada espanyola; ANFAC, la patronal del sector, afirma que manté tots dos llocs.

<BarChart
    data={veh}
    x=anio
    y=vehiculos_1000_hab
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="vehicles per 1.000 habitants"
    title="Vehicles fabricats a Espanya per 1.000 habitants (2020 sense dada a la sèrie)"
/>

<LineChart
    data={veh}
    x=anio
    y=puesto_europa
    y2=puesto_mundo
    xFmt='0'
    yFmt='0'
    markers=true
    yAxisTitle="lloc a Europa"
    y2AxisTitle="lloc al món"
    title="Lloc d'Espanya entre els fabricants de vehicles d'Europa i del món (OICA)"
/>

En proporció a la població, els països que més vehicles fabriquen són Eslovàquia ({formatNumber(veh_lideres[0]?.sk_1000, 0)} per 1.000 habitants) i Txèquia ({formatNumber(veh_lideres[0]?.cz_1000, 0)}). Espanya ({formatNumber(veh_res[0]?.veh_1000_oica, 1)}) està a la par d'Alemanya ({formatNumber(veh_lideres[0]?.de_1000, 1)}), tot i que la xifra alemanya d'OICA només compta turismes, i molt per sobre de França ({formatNumber(veh_lideres[0]?.fr_1000, 1)}, sense camions ni autobusos) o Itàlia ({formatNumber(veh_lideres[0]?.it_1000, 1)}).

<BarChart
    data={veh_europa_hab}
    x=pais
    y=vehiculos_1000_hab
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="vehicles per 1.000 habitants"
    seriesColors={{'España': '#c2410c', 'Otros países': '#94a3b8'}}
    title="Vehicles fabricats per 1.000 habitants als fabricants de la UE ({veh_res[0]?.anio_oica})"
/>

<DataTable data={veh_europa} rows=15>
    <Column id=puesto_europa title="Lloc a Europa" />
    <Column id=pais title="País" />
    <Column id=vehiculos title="Vehicles fabricats" fmt='#,##0' />
    <Column id=vehiculos_1000_hab title="Per 1.000 hab." fmt='0.0' />
    <Column id=puesto_mundo title="Lloc al món" />
    <Column id=cobertura title="Què compta OICA" />
</DataTable>

### Les fàbriques

ANFAC recull {fab_res[0]?.plantas} fàbriques de vehicles i components en {fab_res[0]?.comunidades} comunitats; {fab_res[0]?.plantas_montaje} munten vehicles, amb {fab_res[0]?.modelos} models en producció ({fab_res[0]?.electrificados} d'ells elèctrics o híbrids) i {fab_res[0]?.adjudicados} més d'adjudicats per als propers anys. La que fabrica més models és {fab_res[0]?.mas_modelos} ({fab_res[0]?.max_modelos}). Per xifra de negocis de la branca, les comunitats amb més pes en la fabricació de vehicles són {veh_ccaa_txt[0]?.lista} del total espanyol.

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
        {id: 'grupo', title: 'Grup'},
        {id: 'tipo', title: 'Què fabrica'},
        {id: 'municipio', title: 'Municipi'},
        {id: 'n_modelos', title: 'Models en producció', fmt: '0'},
        {id: 'modelos', title: 'Models'}
    ]}
/>

La mida del punt és el nombre de models en producció; la posició és la del municipi (les dues fàbriques de Barcelona i les dues de Madrid se superposen).

<DataTable data={fabricas} rows=16 search=true>
    <Column id=fabrica title="Fàbrica" />
    <Column id=grupo title="Grup" />
    <Column id=tipo title="Què fabrica" />
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=modelos title="Models en producció" />
    <Column id=modelos_adjudicados title="Models adjudicats" />
    <Column id=otras_producciones title="Altres produccions" />
</DataTable>

## Rajoles i ceràmica

Espanya va produir **{formatNumber(prod_res[0]?.az_mm2, 0)} milions de m² de rajoles i paviments ceràmics el {prod_res[0]?.anio}**, uns {formatNumber(prod_res[0]?.az_m2_1000, 0)} m² per cada 1.000 habitants: el {formatNumber(prod_res[0]?.az_cuota, 1)} % de la producció europea en superfície ({formatNumber(prod_res[0]?.az_veces, 1)} vegades el seu pes en població) i el {formatNumber(prod_res[0]?.az_cuota_valor, 1)} % en valor. És el primer dels {prod_res[0]?.az_n} països que publiquen la dada. Com que la seva quota en valor és més baixa que en superfície, el preu mitjà de la seva producció per m² és inferior al del conjunt europeu. En xifra de negocis de la branca (Eurostat, empreses) Espanya és la {ramas_res[0]?.az_puesto}a de {ramas_res[0]?.az_n} països amb dada, amb el {formatNumber(ramas_res[0]?.az_cuota, 1)} %; la primera és {ramas_res[0]?.az_lider}. Les frites i els esmalts amb què es recobreixen les peces són també una especialitat espanyola: el {formatNumber(prod_res[0]?.fri_cuota, 0)} % de la producció de la UE.

La branca de minerals no metàl·lics (ceràmica, vidre, ciment) està molt concentrada: {ceramica_ccaa[0]?.comunidad} reuneix el {formatNumber(ceramica_ccaa[0]?.cuota_espana_pct, 0)} % de la seva xifra de negocis a Espanya, {formatNumber(ceramica_ccaa[0]?.veces_peso_poblacion, 1)} vegades el seu pes en població.

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
    title="Quota d'Espanya en la producció de rajoles i paviments de la UE (%)"
/>

## Alimentació i begudes

L'alimentació és la **primera branca manufacturera d'Espanya**: el {formatNumber(ramas_res[0]?.ali_peso_es, 1)} % del valor afegit de les seves manufactures, davant el {formatNumber(ramas_res[0]?.ali_peso_ue, 1)} % a la UE{#if ramas_rank[0]?.ali_puesto_ue > 1}, on és la {ramas_rank[0]?.ali_puesto_ue}a (la primera és {ramas_rank[0]?.primera_ue}, amb el {formatNumber(ramas_rank[0]?.primera_ue_peso, 1)} %){/if}. Les seves empreses facturen el {formatNumber(ramas_res[0]?.ali_cuota, 1)} % de l'alimentació europea ({ordM(ramas_res[0]?.ali_puesto)} país; el primer és {ramas_res[0]?.ali_lider}). Les begudes pesen el {formatNumber(ramas_res[0]?.beb_peso_es, 1)} % davant el {formatNumber(ramas_res[0]?.beb_peso_ue, 1)} % i suposen el {formatNumber(ramas_res[0]?.beb_cuota, 1)} % de la UE.

En productes concrets, Espanya produeix el {formatNumber(prod_res[0]?.ac_cuota, 0)} % de l'oli d'oliva verge de la UE ({formatNumber(prod_res[0]?.ac_kt, 0)} milers de tones), el {formatNumber(prod_res[0]?.acei_cuota, 0)} % de les olives de taula i el {formatNumber(prod_res[0]?.jam_cuota, 0)} % dels pernils i espatlles curats amb os ({ordM(prod_res[0]?.jam_puesto)} de {prod_res[0]?.jam_n} països amb dada). En vi escumós és el {ordM(prod_res[0]?.cava_puesto)} de {prod_res[0]?.cava_n}, amb el {formatNumber(prod_res[0]?.cava_cuota, 0)} % (el xampany no entra en aquest codi).

<BarChart
    data={ramas_peso}
    x=rama_nombre
    y=peso
    series=territorio
    type=grouped
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% del valor afegit de les manufactures"
    seriesColors={{'España': '#c2410c', 'Unión Europea': '#64748b'}}
    title="Pes de cada branca en les manufactures: Espanya davant la UE ({ramas_res[0]?.anio}, % del valor afegit)"
/>

El gràfic ensenya també on és la diferència amb Europa: Espanya té molt menys pes en **maquinària**, **farmàcia** i **electrònica**, branques en què factura el {formatNumber(ramas_res[0]?.maq_cuota, 1)} %, el {formatNumber(ramas_res[0]?.far_cuota, 1)} % i el {formatNumber(ramas_res[0]?.ele_cuota, 1)} % del total europeu.

## Altres sectors forts

- **Material ferroviari.** La branca factura el {formatNumber(ramas_res[0]?.fer_cuota, 1)} % de la UE ({ordM(ramas_res[0]?.fer_puesto)} de {ramas_res[0]?.fer_n} països amb dada, el primer és {ramas_res[0]?.fer_lider}; {formatNumber(ramas_res[0]?.fer_veces, 1)} vegades el seu pes en població). En cotxes de viatgers de tren i tramvia, Espanya va fabricar {formatNumber(prod_res[0]?.tren_uds, 0)} unitats, el {formatNumber(prod_res[0]?.tren_cuota, 0)} % de l'estimació europea (només {prod_res[0]?.tren_n} països publiquen la dada), i és la {exp_res[0]?.tren_puesto}a exportadora de la UE, amb el {formatNumber(exp_res[0]?.tren_cuota, 0)} %.
- **Aeronàutica.** El {formatNumber(ramas_res[0]?.aer_cuota, 1)} % de la xifra de negocis europea ({ordM(ramas_res[0]?.aer_puesto)} de {ramas_res[0]?.aer_n} amb dada; lidera {ramas_res[0]?.aer_lider}), una mica per sota del seu pes en població.
- **Refinament de petroli.** El {formatNumber(ramas_res[0]?.ref_cuota, 1)} % de la UE ({ordM(ramas_res[0]?.ref_puesto)} de {ramas_res[0]?.ref_n} amb dada); pesa el {formatNumber(ramas_res[0]?.ref_peso_es, 1)} % de les manufactures espanyoles davant el {formatNumber(ramas_res[0]?.ref_peso_ue, 1)} % a la UE.
- **Renovables.** Espanya va fabricar {formatNumber(prod_res[0]?.tor_kt, 0)} milers de tones de torres i castellets d'acer, el {formatNumber(prod_res[0]?.tor_cuota, 0)} % de la UE ({ordM(prod_res[0]?.tor_puesto)} de {prod_res[0]?.tor_n} amb dada; el codi inclou les torres eòliques i altres estructures de gelosia), i {formatNumber(prod_res[0]?.aero_uds, 0)} aerogeneradors, el {formatNumber(prod_res[0]?.aero_cuota, 0)} % ({ordM(prod_res[0]?.aero_puesto)} de només {prod_res[0]?.aero_n} que publiquen, després de {prod_res[0]?.aero_lider}). En la branca de motors i turbines, que barreja aerogeneradors amb turbines d'un altre tipus, la quota baixa al {formatNumber(ramas_res[0]?.tur_cuota, 1)} %.
- **Vaixells de pesca i ciment.** El {formatNumber(prod_res[0]?.pes_cuota, 0)} % de l'arqueig dels vaixells de pesca construïts a la UE (de {prod_res[0]?.pes_n} països amb dada) i el {formatNumber(prod_res[0]?.cem_cuota, 1)} % del ciment pòrtland ({ordM(prod_res[0]?.cem_puesto)} de {prod_res[0]?.cem_n}).

<DataTable data={otros} rows=14>
    <Column id=nombre title="Branca o producte" />
    <Column id=tipo title="Mesura" />
    <Column id=cuota title="Quota UE %" fmt='0.0' />
    <Column id=veces_peso_poblacion title="Vegades el seu pes en població" fmt='0.00' />
    <Column id=puesto_txt title="Lloc (entre els que publiquen)" />
    <Column id=lider title="Primer amb dada" />
</DataTable>

## Exportacions industrials

Espanya ven a l'exterior (inclosos els altres països de la UE) el {formatNumber(exp_res[0]?.tot_cuota, 1)} % de totes les exportacions de béns dels 27, per sota del seu {formatNumber(exp_res[0]?.cuota_pob, 1)} % de la població: {ordM(exp_res[0]?.tot_puesto)} exportador el {exp_res[0]?.anio}, amb {formatNumber(exp_res[0]?.tot_real_mm, 0)} mil milions d'euros del 2025. Fora de la UE la quota és el {formatNumber(exp_res[0]?.ext_cuota, 1)} % ({ordM(exp_res[0]?.ext_puesto)}). On sí que destaca és en oli d'oliva ({formatNumber(exp_res[0]?.ace_cuota, 0)} % del que exporta la UE), frites i esmalts ceràmics ({formatNumber(exp_res[0]?.fri_cuota, 0)} %), cotxes de tren ({formatNumber(exp_res[0]?.tren_cuota, 0)} %) i rajoles ({formatNumber(exp_res[0]?.az_cuota, 0)} %, {ordM(exp_res[0]?.az_puesto)} després de {exp_res[0]?.az_lider}). Els turismes són el {formatNumber(exp_res[0]?.tur_cuota, 1)} % de la UE ({ordM(exp_res[0]?.tur_puesto)}) i els vehicles en conjunt, el {formatNumber(exp_res[0]?.veh_peso, 1)} % de tot el que exporta Espanya.

**El parany dels Països Baixos i Bèlgica.** Rotterdam i Anvers són la porta d'entrada de mercaderies a Europa, i el que entra pels seus ports i es reenvia a un altre país compta com a exportació seva encara que no ho hagin fabricat. Entre tots dos sumen el {formatNumber(exp_res[0]?.tot_nl_be, 1)} % de les exportacions de la UE i el {formatNumber(exp_res[0]?.ref_nl_be, 0)} % de les de productes refinats del petroli. Sense comptar-los, Espanya seria la {exp_res[0]?.tot_puesto_sin}a en el total, la {exp_res[0]?.tur_puesto_sin}a en turismes i la {exp_res[0]?.ref_puesto_sin}a en productes refinats (en comptes de la {exp_res[0]?.ref_puesto}a). La taula dona tots dos llocs.

<BarChart
    data={exportaciones}
    x=partida_nombre
    y=cuota_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% de les exportacions dels 27"
    seriesColors={{'Más que su peso en población': '#c2410c', 'Menos que su peso en población': '#94a3b8'}}
    title="Quota d'Espanya en les exportacions de la UE per producte ({exp_res[0]?.anio}, %, inclòs el comerç dins de la UE)"
/>

<DataTable data={exportaciones} rows=12 search=true>
    <Column id=partida_nombre title="Producte" />
    <Column id=cuota_pct title="Quota UE %" fmt='0.0' />
    <Column id=puesto title="Lloc" />
    <Column id=puesto_sin_nl_be title="Lloc sense NL ni BE" />
    <Column id=lider title="Primer exportador" />
    <Column id=cuota_nl_be_pct title="NL + BE, % de la UE" fmt='0.0' />
    <Column id=peso_en_exportacion_es_pct title="% de les exportacions espanyoles" fmt='0.00' />
    <Column id=exportacion_es_real_meur title="Exportació Espanya (M€ del 2025)" fmt='#,##0' />
    <Column id=exportacion_es_real_eur_hab title="Exportació per habitant (€ del 2025)" fmt='#,##0' />
</DataTable>

## Quanta indústria té Espanya?

Les manufactures generen el **{formatNumber(peso_res[0]?.es_manuf, 1)} % del valor afegit brut (VAB) espanyol el {peso_res[0]?.anio}**, davant el {formatNumber(peso_res[0]?.ue_manuf, 1)} % de la UE: lloc {peso_res[0]?.es_puesto} de {peso_res[0]?.n_paises}. El 1995 eren el {formatNumber(peso_res[0]?.es_manuf_1995, 1)} % (la UE, el {formatNumber(peso_res[0]?.ue_manuf_1995, 1)} %). Amb tota la indústria, que suma energia, aigua, residus i mines, la proporció és el {formatNumber(peso_res[0]?.es_ind, 1)} % davant el {formatNumber(peso_res[0]?.ue_ind, 1)} %. En ocupació, les manufactures ocupen el {formatNumber(peso_res[0]?.es_emp, 1)} % dels treballadors a Espanya i el {formatNumber(peso_res[0]?.ue_emp, 1)} % a la UE.

Per habitant, el VAB manufacturer espanyol és de {formatNumber(peso_res[0]?.es_hab, 0)} € l'any, el {formatNumber(peso_res[0]?.es_hab_pct_ue, 0)} % de la mitjana europea ({formatNumber(peso_res[0]?.ue_hab, 0)} €): Espanya aporta el {formatNumber(peso_res[0]?.es_cuota_vab, 1)} % del VAB manufacturer de la UE amb el {formatNumber(peso_res[0]?.es_cuota_pob, 1)} % de la seva població. En euros constants del 2025, el VAB manufacturer per habitant d'Espanya és {#if peso_res[0]?.es_hab_real_var_2008 < 0}un {formatNumber(-peso_res[0]?.es_hab_real_var_2008, 1)} % més baix{:else}un {formatNumber(peso_res[0]?.es_hab_real_var_2008, 1)} % més alt{/if} que el 2008 ({formatNumber(peso_res[0]?.es_hab_real_2008, 0)} € llavors, {formatNumber(peso_res[0]?.es_hab_real, 0)} € el {peso_res[0]?.anio}).

<LineChart
    data={peso_serie}
    x=anio
    y=pct_vab_manufacturas
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% del VAB total"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399', 'Polonia': '#a78bfa', 'Portugal': '#fbbf24'}}
    title="Pes de les manufactures en el VAB (% a preus corrents)"
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
    title="Pes de les manufactures en el VAB de cada país de la UE ({peso_res[0]?.anio}, %)"
/>

<DataTable data={peso_ult} rows=28 search=true>
    <Column id=puesto title="Lloc" />
    <Column id=pais title="País" />
    <Column id=pct_vab_manufacturas title="Manufactures, % del VAB" fmt='0.0' />
    <Column id=pct_vab_industria title="Indústria, % del VAB" fmt='0.0' />
    <Column id=pct_empleo_manufacturas title="Manufactures, % de l'ocupació" fmt='0.0' />
    <Column id=pct_empleo_industria title="Indústria, % de l'ocupació" fmt='0.0' />
    <Column id=vab_manuf_hab_eur title="VAB manufacturer per hab. (€ corrents)" fmt='#,##0' />
</DataTable>

Que perdi pes no vol dir que produeixi menys: el pes es mesura en preus corrents i depèn també del que creixin els serveis. En **volum** (descomptada l'evolució dels preus), el VAB manufacturer espanyol del {peso_res[0]?.anio} equival a {formatNumber(peso_res[0]?.es_vol, 1)} si 2015 = 100 (el 2008, {formatNumber(peso_res[0]?.es_vol_2008, 1)}); el de la UE, a {formatNumber(peso_res[0]?.ue_vol, 1)} (el 2008, {formatNumber(peso_res[0]?.ue_vol_2008, 1)}).

<LineChart
    data={peso_serie}
    x=anio
    y=vab_manuf_real_indice
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="índex 2015 = 100"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399', 'Polonia': '#a78bfa', 'Portugal': '#fbbf24'}}
    title="VAB de les manufactures en volum (índex 2015 = 100)"
/>

<LineChart
    data={peso_serie}
    x=anio
    y=pct_empleo_manufacturas
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% dels ocupats"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399', 'Polonia': '#a78bfa', 'Portugal': '#fbbf24'}}
    title="Pes de les manufactures en l'ocupació (% dels ocupats)"
/>

## Producció industrial

L'índex de producció industrial (IPI) mesura quant es produeix en quantitats, sense efecte dels preus. El {ipi_res[0]?.anio}, la producció de la indústria espanyola va variar un {formatNumber(ipi_res[0]?.es_var, 1)} % respecte a l'any anterior (UE: {formatNumber(ipi_res[0]?.ue_var, 1)} %). Respecte al 2019 la variació és del {formatNumber(ipi_res[0]?.es_var_2019, 1)} % a Espanya i del {formatNumber(ipi_res[0]?.ue_var_2019, 1)} % a la UE; respecte al 2007, abans de la crisi financera, del {formatNumber(ipi_res[0]?.es_var_2007, 1)} % i del {formatNumber(ipi_res[0]?.ue_var_2007, 1)} %.

<LineChart
    data={ipi_anual}
    x=anio
    y=indice
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="índex 2021 = 100"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399'}}
    title="Índex de producció industrial anual (indústria sense construcció, 2021 = 100, corregit de calendari)"
/>

L'última dada mensual de l'INE correspon a **{mesCa(ipi_ult[0]?.mes_txt, true)}**: índex {formatNumber(ipi_ult[0]?.indice, 1)}, un {formatNumber(ipi_ult[0]?.variacion_anual_pct, 1)} % respecte al mateix mes de l'any anterior, i una variació acumulada en el que va d'any del {formatNumber(ipi_ult[0]?.variacion_acumulada_pct, 1)} %. L'índex mensual original puja i baixa amb el calendari (l'agost és el mes més baix tots els anys excepte el 2020), així que la comparació útil és amb el mateix mes de l'any anterior.

<LineChart
    data={ipi_mes}
    x=mes
    y=indice
    yFmt='0.0'
    yAxisTitle="índex 2021 = 100"
    title="Índex de producció industrial mensual d'Espanya (original, últims 36 mesos)"
/>

<BarChart
    data={ipi_destinos}
    x=destino
    y=variacion_acumulada_pct
    swapXY=true
    yFmt='0.0'
    yAxisTitle="% sobre el mateix període de l'any anterior"
    title="Variació de la producció en el que va d'any fins a {mesCa(ipi_ult[0]?.mes_txt, true)}, per destinació econòmica (%)"
/>

## Per comunitat

La indústria pesa molt diferent segons la comunitat. El {ccaa_res[0]?.anio}, les més industrials per pes en el seu VAB eren {ccaa_res[0]?.mas}; la mitjana espanyola és el {formatNumber(ccaa_espana[0]?.pct_vab_industria, 1)} % i {ccaa_res[0]?.n_sobre_media} comunitats la superen. A Navarra la indústria dona feina a {formatNumber(ccaa_res[0]?.navarra_ocup, 0)} persones per cada 1.000 habitants, davant {formatNumber(ccaa_espana[0]?.ocupados_industria_1000_hab, 0)} de mitjana. Les que menys depenen de la indústria són {ccaa_res[0]?.menos}. Catalunya concentra el {formatNumber(ccaa_res[0]?.cat_cuota, 1)} % del VAB industrial d'Espanya. Prem en una comunitat per veure'n la fitxa.

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
        {id: 'pct_vab_industria', title: 'Indústria, % del VAB', fmt: '0.0'},
        {id: 'pct_vab_manufacturas', title: 'Manufactures, % del VAB', fmt: '0.0'},
        {id: 'vab_industria_hab_real', title: 'VAB industrial per hab. (€ del 2025)', fmt: '#,##0'},
        {id: 'ocupados_industria_1000_hab', title: 'Ocupats a la indústria per 1.000 hab.', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=puesto title="Lloc" />
    <Column id=comunidad title="Comunitat" />
    <Column id=pct_vab_industria title="Indústria, % del VAB" fmt='0.0' />
    <Column id=pct_vab_manufacturas title="Manufactures, % del VAB" fmt='0.0' />
    <Column id=vab_industria_hab_real title="VAB industrial per hab. (€ del 2025)" fmt='#,##0' />
    <Column id=cifra_negocios_hab_real title="Xifra de negocis industrial per hab. (€ del 2025)" fmt='#,##0' />
    <Column id=ocupados_industria_1000_hab title="Ocupats a la indústria per 1.000 hab." fmt='0.0' />
    <Column id=cuota_vab_industria_espana_pct title="% del VAB industrial d'Espanya" fmt='0.0' />
</DataTable>

### Les branques fortes de cada comunitat

Per a cada comunitat, la branca que més pesa en la seva indústria (en xifra de negocis) i la branca en què està més especialitzada respecte a la seva població: la quota de la comunitat en aquesta branca a Espanya dividida entre el seu pes en la població espanyola (només branques que suposen almenys el 5 % de la seva indústria i que publiquen deu comunitats o més; dades de l'INE del {ccaa_ramas_anio[0]?.anio}, sense Ceuta ni Melilla).

<DataTable data={ccaa_ramas} rows=17 link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=rama_principal title="Branca amb més pes" />
    <Column id=peso_principal title="% de la seva indústria" fmt='0.0' />
    <Column id=rama_especial title="Branca més especialitzada" />
    <Column id=veces title="Vegades el seu pes en població" fmt='0.0' />
    <Column id=cuota_especial title="% d'aquesta branca a Espanya" fmt='0.0' />
</DataTable>

## Metodologia i fonts

- **Pes de la indústria a la UE:** Eurostat, comptes nacionals per branca [nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table) (VAB a preus corrents i en volum encadenat, base 2010) i [nama_10_a10_e](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10_e/default/table) (ocupació); població, [nama_10_pe](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe/default/table). Manufactures = secció C de la NACE; indústria = seccions B a E (mines, manufactures, energia, aigua i residus).
- **Branques industrials:** Eurostat, estadístiques estructurals d'empreses [sbs_ovw_act](https://ec.europa.eu/eurostat/databrowser/view/sbs_ovw_act/default/table) (xifra de negocis, valor afegit i ocupació). El total de la UE és l'estimació d'Eurostat; si no existeix, la suma dels països amb dada (la taula ho indica a la nota).
- **Productes:** Eurostat, Prodcom [DS-059358](https://ec.europa.eu/eurostat/databrowser/view/DS-059358/default/table) (producció venuda). Quota sobre l'agregat EU27_2020 estimat per Eurostat; lloc entre els països que publiquen la dada.
- **Exportacions:** Eurostat, Comext [DS-045409](https://ec.europa.eu/eurostat/databrowser/view/DS-045409/default/table), per partida del Sistema Harmonitzat; suma dels 27 països, amb i sense el comerç dins de la UE.
- **Producció industrial:** Eurostat [sts_inpr_a](https://ec.europa.eu/eurostat/databrowser/view/sts_inpr_a/default/table) (anual, corregit de calendari) i INE, Índex de Producció Industrial, [taula 70177](https://www.ine.es/jaxiT3/Tabla.htm?t=70177) (mensual per comunitat i destinació econòmica) i [taula 60282](https://www.ine.es/jaxiT3/Tabla.htm?t=60282) (per divisió). Base 2021 = 100.
- **Comunitats:** Eurostat, VAB regional [nama_10r_3gva](https://ec.europa.eu/eurostat/databrowser/view/nama_10r_3gva/default/table); INE, Estadística Estructural d'Empreses del sector industrial, [taula 76823](https://www.ine.es/jaxiT3/Tabla.htm?t=76823) (xifra de negocis i ocupats per comunitat i branca; les dades amb secret estadístic no es publiquen).
- **Vehicles:** [OICA, producció mundial per país 2019-2024](https://oica.net/wp-content/uploads/2025/10/By-country-region-2024.pdf) (per a Alemanya només turismes i per a França només turismes i comercials lleugers; no hi ha dada del 2020 a la sèrie). Espanya {veh_res[0]?.anio}: [ANFAC, producció i exportació, tancament del 2025](https://anfac.com/wp-content/uploads/2026/01/NP-Produccion-y-exportacion-diciembre-y-cierre-2025.pdf), que afirma: «España ocupa el 2.º lugar como fabricante de vehículos en Europa y el 9.º mundial». Fàbriques: [ANFAC, mapa de fàbriques amb models en producció i adjudicats](https://anfac.com/cifras-clave/produccion-y-exportacion/) (maig del 2025); coordenades del municipi, de Wikidata.
- Els euros s'expressen en euros constants del 2025 amb l'IPC de l'INE quan es comparen anys; les comparacions entre països del mateix any fan servir euros corrents. Els totals es donen en proporció a la població (per habitant, per 1.000 habitants o en quota davant el pes en població).
