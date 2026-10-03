---
title: Industria
description: "Non den Espainia industria-potentzia (automobila, azulejuak, oliba-olioa, urdaiazpikoa, trenbide-materiala, dorre eolikoak) eta zenbateko pisua duen haren industriak EBko batez bestekoarekin alderatuta: manufakturen BEGa eta enplegua, industria-ekoizpena, esportazioak eta erkidegoak."
i18n_origen: 31efb7de9711
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
    // SQLtik gaztelaniaz datozen hilabeteak euskaratu: 'agosto de 2026' -> '2026ko abuztua' / '2026ko abuztuan'
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
SELECT c.cod_ccaa, c.ccaa AS comunidad, '/eu' || t.ruta AS ruta, CAST(c.anio AS INTEGER) AS anio, c.pct_vab_industria, c.pct_vab_manufacturas,
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
SELECT t.nombre AS comunidad, '/eu' || t.ruta AS ruta, p.rama_principal, p.peso_principal, e.rama_especial, e.veces, e.cuota_especial
FROM principal p
LEFT JOIN especial e USING (cod_ccaa)
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = p.cod_ccaa
ORDER BY p.peso_principal DESC
```

```sql ccaa_ramas_anio
SELECT CAST(max(anio) AS INTEGER) AS anio FROM mother.industria_ccaa_ramas
```
# 🏭 Industria

Espainia ez dago Europar Batasuneko herrialde industrialenen artean: haren manufakturek Europako batez bestekoak baino pisu txikiagoa dute ekonomian. Baina zenbait produktutan lehen mailako potentzia da, autoetatik eta azulejuetatik hasi eta oliba-olioraino, urdaiazpiko onduraino, trenbide-materialeraino edo aerosorgailuen dorreetaraino. Orri honek bi aldeak erakusten ditu Eurostat, INE, OICA eta ANFACen datuekin, beti biztanleriarekiko edo Europako guztizkoarekiko proportzioan.

<Grid cols=4>
    <KpiCard
        title="Fabrikatutako ibilgailuak"
        value={veh_res[0]?.veh_1000}
        formattedValue="{formatNumber(veh_res[0]?.veh_1000, 1)} 1.000 biz."
        period="{veh_res[0]?.anio} · {formatNumber(veh_res[0]?.vehiculos_millones, 2)} milioi · Europako {veh_res[0]?.puesto_europa}.a (OICA {veh_res[0]?.anio_oica})"
        change={veh_res[0]?.var_anual?.toFixed(1)}
        changePeriod="{veh_res[0]?.anio_ant}arekin alderatuta"
        direction="positive-up"
        source="OICA eta ANFAC"
        sparklineData={veh.map(d => d.vehiculos_1000_hab)}
    />
    <KpiCard
        title="Azulejuak: EBko ekoizpenaren kuota"
        value={prod_res[0]?.az_cuota}
        formattedValue="{formatNumber(prod_res[0]?.az_cuota, 1)} %"
        period="{prod_res[0]?.anio} · m²-tan · datua argitaratzen duten {prod_res[0]?.az_n} herrialdeen artean {prod_res[0]?.az_puesto}.a"
        direction="positive-up"
        source="Eurostat (Prodcom)"
        sparklineData={azulejos.map(d => d.cuota_cantidad_pct)}
    />
    <KpiCard
        title="Manufakturen pisua ekonomian"
        value={peso_res[0]?.es_manuf}
        formattedValue="BEGaren {formatNumber(peso_res[0]?.es_manuf, 1)} %"
        period="{peso_res[0]?.anio} · EB: {formatNumber(peso_res[0]?.ue_manuf, 1)} % · {peso_res[0]?.es_puesto}. postua, {peso_res[0]?.n_paises} herrialderen artean"
        change={peso_res[0]?.dif_manuf?.toFixed(1)}
        changeUnit="pp"
        changePeriod="EBrekin alderatuta"
        direction="positive-up"
        source="Eurostat (nama_10_a10)"
        sparklineData={peso_es.map(d => d.pct_vab_manufacturas)}
    />
    <KpiCard
        title="Industria-ekoizpenaren indizea"
        value={ipi_ult[0]?.indice}
        formattedValue={formatNumber(ipi_ult[0]?.indice, 1)}
        period="{mesEu(ipi_ult[0]?.mes_txt)} · oinarria 2021 = 100 · jatorrizko indizea"
        change={ipi_ult[0]?.variacion_anual_pct?.toFixed(1)}
        changePeriod="urte artekoa"
        direction="positive-up"
        source="INE (IPI, 70177 taula)"
        sparklineData={ipi_mes.map(d => d.indice)}
    />
</Grid>

## Non nabarmentzen den Espainia

Espainiak EBko biztanleriaren {formatNumber(ramas_res[0]?.cuota_pob, 1)} % du. Espainiako industria-adar batek Europako guztizkoaren proportzio hori baino gehiago fakturatzen badu, Espainiak biztanleen arabera dagokiona baino gehiago ekoizten du; zatidurak («biztanleria-pisuaren aldiz») laburbiltzen du: 1 espero zitekeena da, 2 bikoitza. Manufakturetan, oro har, kuota {formatNumber(ramas_res[0]?.c_cuota, 1)} %-koa da (EBko {ramas_res[0]?.c_puesto}.a negozio-zifraren arabera), biztanleria-pisuaren azpitik. Taulako {ramas_res[0]?.n_ramas} adarretatik {ramas_res[0]?.n_por_encima} baino ez daude haren gainetik, eta gehien nabarmentzen dena **azulejuen eta zeramika-baldosen** adarra da: Europako negozio-zifraren {formatNumber(ramas_res[0]?.az_cuota, 1)} %, biztanleria-pisua bider {formatNumber(ramas_res[0]?.az_veces, 1)}.

<BarChart
    data={ramas}
    x=rama_nombre
    y=cuota_cifra_negocios_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="EBko negozio-zifraren %"
    seriesColors={{'Más que su peso en población': '#c2410c', 'Menos que su peso en población': '#94a3b8'}}
    title="Espainiaren kuota EBko industria-adar bakoitzaren negozio-zifran ({ramas_res[0]?.anio}, %)"
/>

<DataTable data={ramas} rows=12 search=true>
    <Column id=rama_nombre title="Adarra" />
    <Column id=cuota_cifra_negocios_pct title="EBko kuota %" fmt='0.0' />
    <Column id=veces_peso_poblacion title="Biztanleria-pisuaren aldiz" fmt='0.00' />
    <Column id=puesto_txt title="Postua (argitaratzen dutenen artean)" />
    <Column id=lider title="Herrialde liderra" />
    <Column id=peso_manuf_es_pct title="Pisua Espainiako manufakturetan %" fmt='0.0' />
    <Column id=peso_manuf_ue_pct title="Pisua EBko manufakturetan %" fmt='0.0' />
    <Column id=cifra_negocios_es_real_meur title="Espainiako negozio-zifra (2025eko M€)" fmt='#,##0' />
</DataTable>

Adarrak enpresen negozio-zifraren arabera neurtzen dira (Eurostat, enpresen egitura-estatistikak). EBko guztizkoa Eurostaten estimazioa da, datu konfidentzialak dituzten herrialdeak barne hartzen dituena; postua, aldiz, zifra argitaratzen duten herrialdeen artean bakarrik kalkula daiteke; beraz, adibidez, «19tik 2.a» esan nahi du argitaratzen duten 19en artean bigarrena dela.

### Produktu zehatzak

Industria-ekoizpenaren estatistikak (Prodcom) produktu bakoitzaren xehetasuneraino iristen dira, unitate fisikoetan: metro karratuak, tonak, unitateak. Espainia da lehen ekoizlea zerrendako {prod_res[0]?.n_productos} produktuetatik {prod_res[0]?.n_primeros} produktutan, eta Europako ekoizpenaren erdia baino gehiagoko kuotak ditu zeramikazko esmalte eta fritetan ({formatNumber(prod_res[0]?.fri_cuota, 0)} %), mahaiko olibetan ({formatNumber(prod_res[0]?.acei_cuota, 0)} %) edo oliba-olio birjinean ({formatNumber(prod_res[0]?.ac_cuota, 0)} %).

**Kontuz bi tranparekin.** Kuota **Eurostatek estimatzen duen EBko guztizkoaren** gainean kalkulatzen da (argitaratzen ez duten herrialdeen ekoizpen konfidentziala barne hartzen duen agregatu biribildua), ez datua duten herrialdeen baturaren gainean, horrek handituko bailuke. Eta **postua zifra argitaratzen duten herrialdeen artean bakarrik da**: produktu askotan gutxi dira (oliba-olio birjinean, {prod_res[0]?.ac_n}; zeramika-fritetan, {prod_res[0]?.fri_n}), gainerakoek konfidentzialtzat jotzen dutelako. Bosten artean lehena izateak ez du bermatzen EBko lehena izatea, nahiz eta 50 %-tik gorako kuotarekin ezin den beste herrialde handiagorik egon.

<BarChart
    data={productos}
    x=producto_nombre
    y=cuota_cantidad_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="EBko ekoizpenaren % (kantitatean)"
    seriesColors={{'Más que su peso en población': '#c2410c', 'Menos que su peso en población': '#94a3b8'}}
    title="Espainiaren kuota produktu bakoitzaren EBko ekoizpenean ({prod_res[0]?.anio}, % kantitatean)"
/>

<DataTable data={productos} rows=12 search=true>
    <Column id=producto_nombre title="Produktua" />
    <Column id=cuota_cantidad_pct title="EBko kuota kantitatean %" fmt='0.0' />
    <Column id=cuota_valor_pct title="EBko kuota balioan %" fmt='0.0' />
    <Column id=veces_peso_poblacion title="Biztanleria-pisuaren aldiz" fmt='0.00' />
    <Column id=puesto_txt title="Postua (argitaratzen dutenen artean)" />
    <Column id=lider title="Datua duen ekoizle handiena" />
    <Column id=cantidad_es_legible title="Espainiako ekoizpena" fmt='#,##0.0' />
    <Column id=unidad_legible title="Unitatea" />
    <Column id=valor_es_real_meur title="Espainiako balioa (2025eko M€)" fmt='#,##0' />
</DataTable>

## Automobila

Espainiak **{formatNumber(veh_res[0]?.vehiculos_millones, 2)} milioi ibilgailu fabrikatu zituen {urtean(veh_res[0]?.anio)}**, {formatNumber(veh_res[0]?.veh_1000, 1)} 1.000 biztanleko; {urtean(veh_res[0]?.anio_ant)} baino {#if veh_res[0]?.var_anual < 0}{formatNumber(-veh_res[0]?.var_anual, 1)} % gutxiago{:else}{formatNumber(veh_res[0]?.var_anual, 1)} % gehiago{/if}, eta 2019an baino {#if veh_res[0]?.var_2019 < 0}{formatNumber(-veh_res[0]?.var_2019, 1)} % gutxiago{:else}{formatNumber(veh_res[0]?.var_2019, 1)} % gehiago{/if}; urte hartan {formatNumber(veh_res[0]?.veh_2019_millones, 2)} milioi atera ziren haren lantegietatik. {urtean(veh_res[0]?.anio_exportado)} ekoitzitakoaren **{formatNumber(veh_res[0]?.pct_exportado, 1)} %** esportatu zuen. Herrialde guztien datuak dituen azken urtean ({veh_res[0]?.anio_oica}) **Europako {veh_res[0]?.puesto_europa}. fabrikatzailea** izan zen, Alemaniaren atzetik bakarrik, eta **munduko {veh_res[0]?.puesto_mundo}.a**, munduko ekoizpenaren {formatNumber(veh_res[0]?.cuota_mundo, 1)} %-rekin. {urteko(veh_res[0]?.anio)} datuetatik Espainiakoa baino ez dago; ANFACek, sektoreko patronalak, dio bi postuak mantentzen dituela.

<BarChart
    data={veh}
    x=anio
    y=vehiculos_1000_hab
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="ibilgailuak 1.000 biztanleko"
    title="Espainian fabrikatutako ibilgailuak 1.000 biztanleko (2020a, daturik gabe seriean)"
/>

<LineChart
    data={veh}
    x=anio
    y=puesto_europa
    y2=puesto_mundo
    xFmt='0'
    yFmt='0'
    markers=true
    yAxisTitle="postua Europan"
    y2AxisTitle="postua munduan"
    title="Espainiaren postua Europako eta munduko ibilgailu-fabrikatzaileen artean (OICA)"
/>

Biztanleriarekiko proportzioan, ibilgailu gehien fabrikatzen dituzten herrialdeak Eslovakia ({formatNumber(veh_lideres[0]?.sk_1000, 0)} 1.000 biztanleko) eta Txekia ({formatNumber(veh_lideres[0]?.cz_1000, 0)}) dira. Espainia ({formatNumber(veh_res[0]?.veh_1000_oica, 1)}) Alemaniaren parean dago ({formatNumber(veh_lideres[0]?.de_1000, 1)}), nahiz eta OICAren Alemaniako zifrak turismoak bakarrik zenbatzen dituen, eta Frantziaren ({formatNumber(veh_lideres[0]?.fr_1000, 1)}, kamioi eta autobusik gabe) edo Italiaren ({formatNumber(veh_lideres[0]?.it_1000, 1)}) oso gainetik.

<BarChart
    data={veh_europa_hab}
    x=pais
    y=vehiculos_1000_hab
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="ibilgailuak 1.000 biztanleko"
    seriesColors={{'España': '#c2410c', 'Otros países': '#94a3b8'}}
    title="Fabrikatutako ibilgailuak 1.000 biztanleko EBko fabrikatzaileetan ({veh_res[0]?.anio_oica})"
/>

<DataTable data={veh_europa} rows=15>
    <Column id=puesto_europa title="Postua Europan" />
    <Column id=pais title="Herrialdea" />
    <Column id=vehiculos title="Fabrikatutako ibilgailuak" fmt='#,##0' />
    <Column id=vehiculos_1000_hab title="1.000 biz." fmt='0.0' />
    <Column id=puesto_mundo title="Postua munduan" />
    <Column id=cobertura title="OICAk zer zenbatzen duen" />
</DataTable>

### Lantegiak

ANFACek ibilgailu eta osagaien {fab_res[0]?.plantas} lantegi jasotzen ditu {fab_res[0]?.comunidades} erkidegotan; horietatik {fab_res[0]?.plantas_montaje}k ibilgailuak muntatzen dituzte, {fab_res[0]?.modelos} modelo ekoizten ari dira (horietatik {fab_res[0]?.electrificados} elektrikoak edo hibridoak) eta beste {fab_res[0]?.adjudicados} esleituta dituzte datozen urteetarako. Modelo gehien fabrikatzen dituena {fab_res[0]?.mas_modelos} da ({fab_res[0]?.max_modelos}). Adarraren negozio-zifraren arabera, ibilgailuen fabrikazioan pisu handiena duten erkidegoak hauek dira: {veh_ccaa_txt[0]?.lista}, Espainiako guztizkoarekiko.

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
        {id: 'grupo', title: 'Taldea'},
        {id: 'tipo', title: 'Zer fabrikatzen duen'},
        {id: 'municipio', title: 'Udalerria'},
        {id: 'n_modelos', title: 'Ekoizten ari diren modeloak', fmt: '0'},
        {id: 'modelos', title: 'Modeloak'}
    ]}
/>

Puntuaren tamaina ekoizten ari diren modeloen kopurua da; kokapena udalerriarena da (Bartzelonako bi lantegiak eta Madrilgo biak gainjarrita daude).

<DataTable data={fabricas} rows=16 search=true>
    <Column id=fabrica title="Lantegia" />
    <Column id=grupo title="Taldea" />
    <Column id=tipo title="Zer fabrikatzen duen" />
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=modelos title="Ekoizten ari diren modeloak" />
    <Column id=modelos_adjudicados title="Esleitutako modeloak" />
    <Column id=otras_producciones title="Beste ekoizpen batzuk" />
</DataTable>

## Azulejuak eta zeramika

Espainiak **zeramikazko baldosa eta azulejuen {formatNumber(prod_res[0]?.az_mm2, 0)} milioi m² ekoitzi zituen {urtean(prod_res[0]?.anio)}**, {formatNumber(prod_res[0]?.az_m2_1000, 0)} m² inguru 1.000 biztanleko: Europako ekoizpenaren {formatNumber(prod_res[0]?.az_cuota, 1)} % azaleran (biztanleria-pisua bider {formatNumber(prod_res[0]?.az_veces, 1)}) eta {formatNumber(prod_res[0]?.az_cuota_valor, 1)} % balioan. Datua argitaratzen duten {prod_res[0]?.az_n} herrialdeen artean lehena da. Balioko kuota azalerakoa baino txikiagoa denez, haren ekoizpenaren m²-ko batez besteko prezioa Europa osokoa baino txikiagoa da. Adarraren negozio-zifran (Eurostat, enpresak) Espainia {ramas_res[0]?.az_puesto}.a da datua duten {ramas_res[0]?.az_n} herrialdeen artean, {formatNumber(ramas_res[0]?.az_cuota, 1)} %-rekin; lehena {ramas_res[0]?.az_lider} da. Piezak estaltzeko fritak eta esmalteak ere Espainiako espezialitatea dira: EBko ekoizpenaren {formatNumber(prod_res[0]?.fri_cuota, 0)} %.

Mineral ez-metalikoen adarra (zeramika, beira, zementua) oso kontzentratuta dago: {ceramica_ccaa[0]?.comunidad} erkidegoak biltzen du Espainian haren negozio-zifraren {formatNumber(ceramica_ccaa[0]?.cuota_espana_pct, 0)} %, biztanleria-pisua bider {formatNumber(ceramica_ccaa[0]?.veces_peso_poblacion, 1)}.

<LineChart
    data={azulejos}
    x=anio
    y=cuota_cantidad_pct
    y2=cuota_valor_pct
    xFmt='0'
    yFmt='0.0'
    y2Fmt='0.0'
    markers=true
    yAxisTitle="EBko % m²-tan"
    y2AxisTitle="EBko % balioan"
    title="Espainiaren kuota EBko baldosa eta azulejuen ekoizpenean (%)"
/>

## Elikadura eta edariak

Elikadura **Espainiako lehen manufaktura-adarra** da: haren manufakturen balio erantsiaren {formatNumber(ramas_res[0]?.ali_peso_es, 1)} %, EBko {formatNumber(ramas_res[0]?.ali_peso_ue, 1)} %-ren aldean{#if ramas_rank[0]?.ali_puesto_ue > 1}; EBn {ramas_rank[0]?.ali_puesto_ue}.a da (lehena {ramas_rank[0]?.primera_ue} da, {formatNumber(ramas_rank[0]?.primera_ue_peso, 1)} %-rekin){/if}. Haren enpresek Europako elikaduraren {formatNumber(ramas_res[0]?.ali_cuota, 1)} % fakturatzen dute ({ramas_res[0]?.ali_puesto}. herrialdea; lehena {ramas_res[0]?.ali_lider} da). Edariek {formatNumber(ramas_res[0]?.beb_peso_es, 1)} %-ko pisua dute, {formatNumber(ramas_res[0]?.beb_peso_ue, 1)} %-ren aldean, eta EBko {formatNumber(ramas_res[0]?.beb_cuota, 1)} % dira.

Produktu zehatzetan, Espainiak EBko oliba-olio birjinaren {formatNumber(prod_res[0]?.ac_cuota, 0)} % ekoizten du ({formatNumber(prod_res[0]?.ac_kt, 0)} mila tona), mahaiko oliben {formatNumber(prod_res[0]?.acei_cuota, 0)} % eta hezurdun urdaiazpiko eta sorbalda onduen {formatNumber(prod_res[0]?.jam_cuota, 0)} % (datua duten {prod_res[0]?.jam_n} herrialdeen artean {prod_res[0]?.jam_puesto}.a). Ardo apardunean {prod_res[0]?.cava_n} herrialderen artean {prod_res[0]?.cava_puesto}.a da, {formatNumber(prod_res[0]?.cava_cuota, 0)} %-rekin (xanpaina ez dago kode honetan).

<BarChart
    data={ramas_peso}
    x=rama_nombre
    y=peso
    series=territorio
    type=grouped
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="manufakturen balio erantsiaren %"
    seriesColors={{'España': '#c2410c', 'Unión Europea': '#64748b'}}
    title="Adar bakoitzaren pisua manufakturetan: Espainia EBrekin alderatuta ({ramas_res[0]?.anio}, balio erantsiaren %)"
/>

Grafikoak Europarekiko aldea non dagoen ere erakusten du: Espainiak pisu askoz txikiagoa du **makinerian**, **farmazian** eta **elektronikan**, eta adar horietan Europako guztizkoaren {formatNumber(ramas_res[0]?.maq_cuota, 1)} %, {formatNumber(ramas_res[0]?.far_cuota, 1)} % eta {formatNumber(ramas_res[0]?.ele_cuota, 1)} % fakturatzen du.

## Beste sektore indartsu batzuk

- **Trenbide-materiala.** Adarrak EBko {formatNumber(ramas_res[0]?.fer_cuota, 1)} % fakturatzen du (datua duten {ramas_res[0]?.fer_n} herrialdeen artean {ramas_res[0]?.fer_puesto}.a, lehena {ramas_res[0]?.fer_lider} da; biztanleria-pisua bider {formatNumber(ramas_res[0]?.fer_veces, 1)}). Tren eta tranbiako bidaiari-kotxeetan, Espainiak {formatNumber(prod_res[0]?.tren_uds, 0)} unitate fabrikatu zituen, Europako estimazioaren {formatNumber(prod_res[0]?.tren_cuota, 0)} % ({prod_res[0]?.tren_n} herrialdek bakarrik argitaratzen dute datua), eta EBko {exp_res[0]?.tren_puesto}. esportatzailea da, {formatNumber(exp_res[0]?.tren_cuota, 0)} %-rekin.
- **Aeronautika.** Europako negozio-zifraren {formatNumber(ramas_res[0]?.aer_cuota, 1)} % (datua duten {ramas_res[0]?.aer_n} herrialdeen artean {ramas_res[0]?.aer_puesto}.a; {ramas_res[0]?.aer_lider} da liderra), biztanleria-pisuaren pixka bat azpitik.
- **Petrolio-findegiak.** EBko {formatNumber(ramas_res[0]?.ref_cuota, 1)} % (datua duten {ramas_res[0]?.ref_n} herrialdeen artean {ramas_res[0]?.ref_puesto}.a); Espainiako manufakturen {formatNumber(ramas_res[0]?.ref_peso_es, 1)} % da, EBko {formatNumber(ramas_res[0]?.ref_peso_ue, 1)} %-ren aldean.
- **Energia berriztagarriak.** Espainiak altzairuzko dorre eta zutoinen {formatNumber(prod_res[0]?.tor_kt, 0)} mila tona fabrikatu zituen, EBko {formatNumber(prod_res[0]?.tor_cuota, 0)} % (datua duten {prod_res[0]?.tor_n} herrialdeen artean {prod_res[0]?.tor_puesto}.a; kodeak dorre eolikoak eta sare-egiturako beste batzuk hartzen ditu barne), eta {formatNumber(prod_res[0]?.aero_uds, 0)} aerosorgailu, {formatNumber(prod_res[0]?.aero_cuota, 0)} % (argitaratzen duten {prod_res[0]?.aero_n} herrialdeen artean {prod_res[0]?.aero_puesto}.a; lehena: {prod_res[0]?.aero_lider}). Motor eta turbinen adarrean, aerosorgailuak beste mota bateko turbinekin nahasten dituenean, kuota {formatNumber(ramas_res[0]?.tur_cuota, 1)} %-ra jaisten da.
- **Arrantza-ontziak eta zementua.** EBn eraikitako arrantza-ontzien arkeoaren {formatNumber(prod_res[0]?.pes_cuota, 0)} % (datua duten {prod_res[0]?.pes_n} herrialdeetatik) eta Portland zementuaren {formatNumber(prod_res[0]?.cem_cuota, 1)} % ({prod_res[0]?.cem_n} herrialderen artean {prod_res[0]?.cem_puesto}.a).

<DataTable data={otros} rows=14>
    <Column id=nombre title="Adarra edo produktua" />
    <Column id=tipo title="Neurria" />
    <Column id=cuota title="EBko kuota %" fmt='0.0' />
    <Column id=veces_peso_poblacion title="Biztanleria-pisuaren aldiz" fmt='0.00' />
    <Column id=puesto_txt title="Postua (argitaratzen dutenen artean)" />
    <Column id=lider title="Datua duen lehena" />
</DataTable>

## Industria-esportazioak

Espainiak kanpora saltzen du (EBko gainerako herrialdeak barne) 27en ondasun-esportazio guztien {formatNumber(exp_res[0]?.tot_cuota, 1)} %, biztanleriaren {formatNumber(exp_res[0]?.cuota_pob, 1)} %-ren azpitik: {exp_res[0]?.tot_puesto}. esportatzailea {urtean(exp_res[0]?.anio)}, 2025eko {formatNumber(exp_res[0]?.tot_real_mm, 0)} mila milioi eurorekin. EBtik kanpo kuota {formatNumber(exp_res[0]?.ext_cuota, 1)} %-koa da ({exp_res[0]?.ext_puesto}.a). Benetan nabarmentzen den lekua oliba-olioa da (EBk esportatzen duenaren {formatNumber(exp_res[0]?.ace_cuota, 0)} %), baita zeramikazko frita eta esmalteak ({formatNumber(exp_res[0]?.fri_cuota, 0)} %), tren-kotxeak ({formatNumber(exp_res[0]?.tren_cuota, 0)} %) eta azulejuak ere ({formatNumber(exp_res[0]?.az_cuota, 0)} %, {exp_res[0]?.az_puesto}.a; lehena: {exp_res[0]?.az_lider}). Turismoak EBko {formatNumber(exp_res[0]?.tur_cuota, 1)} % dira ({exp_res[0]?.tur_puesto}.a), eta ibilgailuak, oro har, Espainiak esportatzen duen guztiaren {formatNumber(exp_res[0]?.veh_peso, 1)} %.

**Herbehereen eta Belgikaren tranpa.** Rotterdam eta Anberes dira salgaiak Europara sartzeko atea, eta haien portuetatik sartu eta beste herrialde batera birbidaltzen dena haien esportaziotzat zenbatzen da, nahiz eta haiek fabrikatu ez. Bien artean EBko esportazioen {formatNumber(exp_res[0]?.tot_nl_be, 1)} % eta petrolio-produktu finduen esportazioen {formatNumber(exp_res[0]?.ref_nl_be, 0)} % batzen dituzte. Haiek zenbatu gabe, Espainia {exp_res[0]?.tot_puesto_sin}.a izango litzateke guztizkoan, {exp_res[0]?.tur_puesto_sin}.a turismoetan eta {exp_res[0]?.ref_puesto_sin}.a produktu finduetan ({exp_res[0]?.ref_puesto}.a izan beharrean). Taulak bi postuak ematen ditu.

<BarChart
    data={exportaciones}
    x=partida_nombre
    y=cuota_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="27en esportazioen %"
    seriesColors={{'Más que su peso en población': '#c2410c', 'Menos que su peso en población': '#94a3b8'}}
    title="Espainiaren kuota EBko esportazioetan produktuka ({exp_res[0]?.anio}, %, EB barruko merkataritza barne)"
/>

<DataTable data={exportaciones} rows=12 search=true>
    <Column id=partida_nombre title="Produktua" />
    <Column id=cuota_pct title="EBko kuota %" fmt='0.0' />
    <Column id=puesto title="Postua" />
    <Column id=puesto_sin_nl_be title="Postua NL eta BE gabe" />
    <Column id=lider title="Lehen esportatzailea" />
    <Column id=cuota_nl_be_pct title="NL + BE, EBko %" fmt='0.0' />
    <Column id=peso_en_exportacion_es_pct title="Espainiako esportazioen %" fmt='0.00' />
    <Column id=exportacion_es_real_meur title="Espainiako esportazioa (2025eko M€)" fmt='#,##0' />
</DataTable>

## Zenbat industria du Espainiak?

Manufakturek **Espainiako balio erantsi gordinaren (BEG) {formatNumber(peso_res[0]?.es_manuf, 1)} % sortzen dute {urtean(peso_res[0]?.anio)}**, EBko {formatNumber(peso_res[0]?.ue_manuf, 1)} %-ren aldean: {peso_res[0]?.es_puesto}. postua {peso_res[0]?.n_paises} herrialderen artean. 1995ean {formatNumber(peso_res[0]?.es_manuf_1995, 1)} % ziren (EBn, {formatNumber(peso_res[0]?.ue_manuf_1995, 1)} %). Industria osoarekin, energia, ura, hondakinak eta meategiak batuta, proportzioa {formatNumber(peso_res[0]?.es_ind, 1)} %-koa da, {formatNumber(peso_res[0]?.ue_ind, 1)} %-ren aldean. Enpleguan, manufakturek langileen {formatNumber(peso_res[0]?.es_emp, 1)} % enplegatzen dute Espainian, eta {formatNumber(peso_res[0]?.ue_emp, 1)} % EBn.

Biztanleko, Espainiako manufakturen BEGa {formatNumber(peso_res[0]?.es_hab, 0)} eurokoa da urtean, Europako batez bestekoaren {formatNumber(peso_res[0]?.es_hab_pct_ue, 0)} % ({formatNumber(peso_res[0]?.ue_hab, 0)} €): Espainiak EBko manufakturen BEGaren {formatNumber(peso_res[0]?.es_cuota_vab, 1)} % ematen du, haren biztanleriaren {formatNumber(peso_res[0]?.es_cuota_pob, 1)} %-rekin. 2025eko euro konstanteetan, Espainiako manufakturen BEGa biztanleko 2008an baino {#if peso_res[0]?.es_hab_real_var_2008 < 0}{formatNumber(-peso_res[0]?.es_hab_real_var_2008, 1)} % txikiagoa{:else}{formatNumber(peso_res[0]?.es_hab_real_var_2008, 1)} % handiagoa{/if} da (orduan {formatNumber(peso_res[0]?.es_hab_real_2008, 0)} €, {urtean(peso_res[0]?.anio)} {formatNumber(peso_res[0]?.es_hab_real, 0)} €).

<LineChart
    data={peso_serie}
    x=anio
    y=pct_vab_manufacturas
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="BEG osoaren %"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399', 'Polonia': '#a78bfa', 'Portugal': '#fbbf24'}}
    title="Manufakturen pisua BEGan (% prezio korronteetan)"
/>

<BarChart
    data={peso_ult}
    x=pais
    y=pct_vab_manufacturas
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="BEG osoaren %"
    seriesColors={{'España': '#c2410c', 'Media UE': '#0f172a', 'Otros países': '#94a3b8'}}
    title="Manufakturen pisua EBko herrialde bakoitzaren BEGan ({peso_res[0]?.anio}, %)"
/>

<DataTable data={peso_ult} rows=28 search=true>
    <Column id=puesto title="Postua" />
    <Column id=pais title="Herrialdea" />
    <Column id=pct_vab_manufacturas title="Manufakturak, BEGaren %" fmt='0.0' />
    <Column id=pct_vab_industria title="Industria, BEGaren %" fmt='0.0' />
    <Column id=pct_empleo_manufacturas title="Manufakturak, enpleguaren %" fmt='0.0' />
    <Column id=pct_empleo_industria title="Industria, enpleguaren %" fmt='0.0' />
    <Column id=vab_manuf_hab_eur title="Manufakturen BEG biz. (€ korronteak)" fmt='#,##0' />
</DataTable>

Pisua galtzeak ez du esan nahi gutxiago ekoizten duenik: pisua prezio korronteetan neurtzen da, eta zerbitzuen hazkundearen mende ere badago. **Bolumenean** (prezioen bilakaera kenduta), Espainiako manufakturen {urteko(peso_res[0]?.anio)} BEGa {formatNumber(peso_res[0]?.es_vol, 1)} da 2015 = 100 bada (2008an, {formatNumber(peso_res[0]?.es_vol_2008, 1)}); EBkoa, {formatNumber(peso_res[0]?.ue_vol, 1)} (2008an, {formatNumber(peso_res[0]?.ue_vol_2008, 1)}).

<LineChart
    data={peso_serie}
    x=anio
    y=vab_manuf_real_indice
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="indizea 2015 = 100"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399', 'Polonia': '#a78bfa', 'Portugal': '#fbbf24'}}
    title="Manufakturen BEGa bolumenean (indizea 2015 = 100)"
/>

<LineChart
    data={peso_serie}
    x=anio
    y=pct_empleo_manufacturas
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="landunen %"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399', 'Polonia': '#a78bfa', 'Portugal': '#fbbf24'}}
    title="Manufakturen pisua enpleguan (landunen %)"
/>

## Industria-ekoizpena

Industria-ekoizpenaren indizeak (IPI) kantitatetan zenbat ekoizten den neurtzen du, prezioen eraginik gabe. {urtean(ipi_res[0]?.anio)}, Espainiako industriaren ekoizpenak {formatNumber(ipi_res[0]?.es_var, 1)} %-ko aldaketa izan zuen aurreko urtearekiko (EB: {formatNumber(ipi_res[0]?.ue_var, 1)} %). 2019arekiko aldaketa {formatNumber(ipi_res[0]?.es_var_2019, 1)} %-koa da Espainian eta {formatNumber(ipi_res[0]?.ue_var_2019, 1)} %-koa EBn; 2007arekiko, finantza-krisiaren aurretik, {formatNumber(ipi_res[0]?.es_var_2007, 1)} % eta {formatNumber(ipi_res[0]?.ue_var_2007, 1)} %.

<LineChart
    data={ipi_anual}
    x=anio
    y=indice
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="indizea 2021 = 100"
    seriesColors={{'España': '#c2410c', 'Unión Europea (27)': '#0f172a', 'Alemania': '#94a3b8', 'Francia': '#60a5fa', 'Italia': '#34d399'}}
    title="Urteko industria-ekoizpenaren indizea (industria eraikuntzarik gabe, 2021 = 100, egutegi-efektua zuzenduta)"
/>

INEren azken hileko datua **{mesEu(ipi_ult[0]?.mes_txt)}** hilabeteari dagokio: {formatNumber(ipi_ult[0]?.indice, 1)} indizea, aurreko urteko hilabete berarekiko {formatNumber(ipi_ult[0]?.variacion_anual_pct, 1)} %-ko aldaketa, eta urte hasieratik metatutako aldaketa {formatNumber(ipi_ult[0]?.variacion_acumulada_pct, 1)} %-koa. Jatorrizko hileko indizea egutegiaren arabera igo eta jaisten da (abuztua da hilabeterik baxuena urtero, 2020an izan ezik); beraz, alderaketa erabilgarria aurreko urteko hilabete berarekin egiten dena da.

<LineChart
    data={ipi_mes}
    x=mes
    y=indice
    yFmt='0.0'
    yAxisTitle="indizea 2021 = 100"
    title="Espainiako hileko industria-ekoizpenaren indizea (jatorrizkoa, azken 36 hilabeteak)"
/>

<BarChart
    data={ipi_destinos}
    x=destino
    y=variacion_acumulada_pct
    swapXY=true
    yFmt='0.0'
    yAxisTitle="% aurreko urteko aldi berarekiko"
    title="Ekoizpenaren urte hasierako aldaketa metatua (azken hilabetea: {mesEu(ipi_ult[0]?.mes_txt)}), xede ekonomikoaren arabera (%)"
/>

## Erkidegoka

Industriaren pisua oso desberdina da erkidegoaren arabera. {urtean(ccaa_res[0]?.anio)}, BEGaren pisuaren arabera industrialenak hauek ziren: {ccaa_res[0]?.mas}; Espainiako batez bestekoa {formatNumber(ccaa_espana[0]?.pct_vab_industria, 1)} %-koa da, eta {ccaa_res[0]?.n_sobre_media} erkidegok gainditzen dute. Nafarroan industriak {formatNumber(ccaa_res[0]?.navarra_ocup, 0)} pertsonari ematen die lana 1.000 biztanleko (batez bestekoa: {formatNumber(ccaa_espana[0]?.ocupados_industria_1000_hab, 0)}). Industriaren mende gutxien daudenak hauek dira: {ccaa_res[0]?.menos}. Kataluniak Espainiako industria-BEGaren {formatNumber(ccaa_res[0]?.cat_cuota, 1)} % biltzen du. Sakatu erkidego batean haren fitxa ikusteko.

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
        {id: 'pct_vab_industria', title: 'Industria, BEGaren %', fmt: '0.0'},
        {id: 'pct_vab_manufacturas', title: 'Manufakturak, BEGaren %', fmt: '0.0'},
        {id: 'vab_industria_hab_real', title: 'Industria-BEG biz. (2025eko €)', fmt: '#,##0'},
        {id: 'ocupados_industria_1000_hab', title: 'Industriako landunak 1.000 biz.', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=puesto title="Postua" />
    <Column id=comunidad title="Erkidegoa" />
    <Column id=pct_vab_industria title="Industria, BEGaren %" fmt='0.0' />
    <Column id=pct_vab_manufacturas title="Manufakturak, BEGaren %" fmt='0.0' />
    <Column id=vab_industria_hab_real title="Industria-BEG biz. (2025eko €)" fmt='#,##0' />
    <Column id=cifra_negocios_hab_real title="Industriako negozio-zifra biz. (2025eko €)" fmt='#,##0' />
    <Column id=ocupados_industria_1000_hab title="Industriako landunak 1.000 biz." fmt='0.0' />
    <Column id=cuota_vab_industria_espana_pct title="Espainiako industria-BEGaren %" fmt='0.0' />
</DataTable>

### Erkidego bakoitzaren adar indartsuak

Erkidego bakoitzerako, haren industrian pisu handiena duen adarra (negozio-zifran) eta biztanleriarekiko espezializatuena den adarra: erkidegoak adar horretan Espainian duen kuota, Espainiako biztanlerian duen pisuaz zatituta (haren industriaren gutxienez 5 % diren eta hamar erkidegok edo gehiagok argitaratzen dituzten adarrak bakarrik; INEren {urteko(ccaa_ramas_anio[0]?.anio)} datuak, Ceuta eta Melilla gabe).

<DataTable data={ccaa_ramas} rows=17 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=rama_principal title="Pisu handieneko adarra" />
    <Column id=peso_principal title="Haren industriaren %" fmt='0.0' />
    <Column id=rama_especial title="Adar espezializatuena" />
    <Column id=veces title="Biztanleria-pisuaren aldiz" fmt='0.0' />
    <Column id=cuota_especial title="Adar horren % Espainian" fmt='0.0' />
</DataTable>

## Metodologia eta iturriak

- **Industriaren pisua EBn:** Eurostat, kontu nazionalak adarka [nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table) (BEG prezio korronteetan eta bolumen kateatuan, 2010 oinarria) eta [nama_10_a10_e](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10_e/default/table) (enplegua); biztanleria, [nama_10_pe](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe/default/table). Manufakturak = NACEren C atala; industria = B-tik E-rako atalak (meategiak, manufakturak, energia, ura eta hondakinak).
- **Industria-adarrak:** Eurostat, enpresen egitura-estatistikak [sbs_ovw_act](https://ec.europa.eu/eurostat/databrowser/view/sbs_ovw_act/default/table) (negozio-zifra, balio erantsia eta enplegua). EBko guztizkoa Eurostaten estimazioa da; ez badago, datua duten herrialdeen batura (taulak oharrean adierazten du).
- **Produktuak:** Eurostat, Prodcom [DS-059358](https://ec.europa.eu/eurostat/databrowser/view/DS-059358/default/table) (saldutako ekoizpena). Kuota Eurostatek estimatutako EU27_2020 agregatuaren gainean; postua datua argitaratzen duten herrialdeen artean.
- **Esportazioak:** Eurostat, Comext [DS-045409](https://ec.europa.eu/eurostat/databrowser/view/DS-045409/default/table), Sistema Harmonizatuaren partidaka; 27 herrialdeen batura, EB barruko merkataritzarekin eta gabe.
- **Industria-ekoizpena:** Eurostat [sts_inpr_a](https://ec.europa.eu/eurostat/databrowser/view/sts_inpr_a/default/table) (urtekoa, egutegi-efektua zuzenduta) eta INE, Industria Ekoizpenaren Indizea, [70177 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=70177) (hilekoa, erkidegoka eta xede ekonomikoaren arabera) eta [60282 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=60282) (dibisioka). Oinarria 2021 = 100.
- **Erkidegoak:** Eurostat, eskualdeko BEG [nama_10r_3gva](https://ec.europa.eu/eurostat/databrowser/view/nama_10r_3gva/default/table); INE, Industria-sektoreko Enpresen Egitura Estatistika, [76823 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=76823) (negozio-zifra eta landunak erkidego eta adarka; sekretu estatistikoa duten datuak ez dira argitaratzen).
- **Ibilgailuak:** [OICA, munduko ekoizpena herrialdeka 2019-2024](https://oica.net/wp-content/uploads/2025/10/By-country-region-2024.pdf) (Alemaniarako turismoak bakarrik, eta Frantziarako turismoak eta merkataritza-ibilgailu arinak bakarrik; seriean ez dago 2020ko daturik). Espainia {veh_res[0]?.anio}: [ANFAC, ekoizpena eta esportazioa, 2025eko itxiera](https://anfac.com/wp-content/uploads/2026/01/NP-Produccion-y-exportacion-diciembre-y-cierre-2025.pdf); haren arabera, Espainia Europako 2. ibilgailu-fabrikatzailea eta munduko 9.a da. Lantegiak: [ANFAC, ekoizten ari diren eta esleitutako modeloak dituzten lantegien mapa](https://anfac.com/cifras-clave/produccion-y-exportacion/) (2025eko maiatza); udalerriaren koordenatuak, Wikidatatik.
- Urteak alderatzean, euroak 2025eko euro konstanteetan ematen dira INEren KPIarekin; urte bereko herrialdeen arteko alderaketek euro korronteak erabiltzen dituzte. Guztizkoak biztanleriarekiko proportzioan ematen dira (biztanleko, 1.000 biztanleko edo biztanleria-pisuarekiko kuota gisa).
