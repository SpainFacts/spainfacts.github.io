---
title: Lehen sektorea
description: "Non den Espainia potentzia landan eta itsasoan: EBko kuota eta postua oliba-olioan, zitrikoetan, frutetan eta barazkietan, ardoan, txerrikietan, ardietan, arrantzan eta akuikulturan, nekazaritza-ekoizpenaren balioa biztanleko euro errealetan eta lehen sektorearen pisua erkidego eta probintziaka."
i18n_origen: b0106b55afc7
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
</script>

```sql ranking
SELECT
    CASE categoria WHEN 'cultivo' THEN 'Cultivos' WHEN 'ganaderia' THEN 'Ganadería'
                   WHEN 'pesca' THEN 'Pesca y acuicultura' WHEN 'exportacion' THEN 'Exportaciones'
                   ELSE 'Valor de la producción' END AS grupo,
    CASE categoria WHEN 'cultivo' THEN 1 WHEN 'ganaderia' THEN 2 WHEN 'pesca' THEN 3
                   WHEN 'exportacion' THEN 4 ELSE 5 END AS orden,
    categoria, producto_id, producto, unidad, CAST(anio AS INTEGER) AS anio,
    valor_espana, cuota_pct, cuota_min_pct, CAST(puesto AS INTEGER) AS puesto, CAST(n_paises AS INTEGER) AS n_paises,
    pais_primero, pais_segundo,
    CASE WHEN puesto = 1 THEN pais_segundo ELSE pais_primero END AS pais_referencia,
    cuota_poblacion_pct, veces_peso_poblacion, valor_hab_espana, valor_hab_ue, unidad_hab,
    cobertura_pct, paises_sin_dato, nota
FROM mother.primario_ranking_ue
WHERE producto_id <> 'HS_TOTAL'
ORDER BY orden, cuota_pct DESC
```

```sql ranking_productos
SELECT * FROM ${ranking}
WHERE categoria <> 'valor'
ORDER BY orden, cuota_pct DESC
```

```sql ranking_primeros
SELECT grupo, orden, producto, cuota_pct, veces_peso_poblacion, pais_segundo, anio
FROM ${ranking_productos}
WHERE puesto = 1
ORDER BY orden, cuota_pct DESC
```

```sql ranking_resumen
SELECT
    CAST(count(*) FILTER (WHERE puesto = 1) AS INTEGER) AS primeros,
    CAST(count(*) AS INTEGER) AS total,
    CAST(count(*) FILTER (WHERE puesto <= 3) AS INTEGER) AS podio,
    CAST(count(*) FILTER (WHERE puesto = 1 AND categoria = 'cultivo') AS INTEGER) AS prim_cultivo,
    CAST(count(*) FILTER (WHERE categoria = 'cultivo') AS INTEGER) AS n_cultivo,
    CAST(count(*) FILTER (WHERE puesto = 1 AND categoria = 'ganaderia') AS INTEGER) AS prim_ganaderia,
    CAST(count(*) FILTER (WHERE categoria = 'ganaderia') AS INTEGER) AS n_ganaderia,
    CAST(count(*) FILTER (WHERE puesto = 1 AND categoria = 'pesca') AS INTEGER) AS prim_pesca,
    CAST(count(*) FILTER (WHERE categoria = 'pesca') AS INTEGER) AS n_pesca,
    CAST(count(*) FILTER (WHERE puesto = 1 AND categoria = 'exportacion') AS INTEGER) AS prim_export,
    CAST(count(*) FILTER (WHERE categoria = 'exportacion') AS INTEGER) AS n_export,
    max(cuota_poblacion_pct) AS peso_pob,
    CAST(count(*) FILTER (WHERE veces_peso_poblacion >= 2) AS INTEGER) AS doble_peso
FROM ${ranking_productos}
```

```sql ranking_top
SELECT string_agg(lower(producto) || ' (' || CAST(round(cuota_pct) AS INTEGER) || ' %)', ', ' ORDER BY cuota_pct DESC) AS lista
FROM (
    SELECT producto, cuota_pct FROM ${ranking_productos}
    WHERE categoria = 'cultivo' AND producto_id LIKE '%_prod' AND puesto = 1
    ORDER BY cuota_pct DESC LIMIT 6
)
```

```sql ranking_flojos
SELECT string_agg(lower(producto) || ' (' || CAST(puesto AS INTEGER) || '.º)', ', ' ORDER BY puesto DESC, cuota_pct) AS lista
FROM ${ranking_productos}
WHERE categoria IN ('cultivo', 'ganaderia') AND puesto >= 4
```

```sql kpi
SELECT
    max(cuota_pct) FILTER (WHERE producto_id = 'T0000_prod') AS citricos,
    max(CAST(anio AS INTEGER)) FILTER (WHERE producto_id = 'T0000_prod') AS citricos_anio,
    max(valor_espana) FILTER (WHERE producto_id = 'T0000_prod') AS citricos_kt,
    max(puesto) FILTER (WHERE producto_id = 'T0000_prod') AS citricos_puesto,
    max(cuota_pct) FILTER (WHERE producto_id = 'B3100') AS porcino,
    max(CAST(anio AS INTEGER)) FILTER (WHERE producto_id = 'B3100') AS porcino_anio,
    max(valor_espana) FILTER (WHERE producto_id = 'B3100') AS porcino_kt,
    max(valor_hab_espana) FILTER (WHERE producto_id = 'B3100') AS porcino_kg_hab,
    max(valor_hab_ue) FILTER (WHERE producto_id = 'B3100') AS porcino_kg_hab_ue,
    max(pais_segundo) FILTER (WHERE producto_id = 'B3100') AS porcino_segundo
FROM ${ranking}
```

```sql serie_citricos
SELECT CAST(anio AS INTEGER) AS anio, cuota_pct
FROM mother.primario_serie_espana
WHERE producto_id = 'T0000_prod' AND n_paises = 27
ORDER BY anio
```

```sql serie_porcino
SELECT CAST(anio AS INTEGER) AS anio, cuota_pct, valor_hab
FROM mother.primario_serie_espana
WHERE producto_id = 'B3100' AND n_paises = 27
ORDER BY anio
```

```sql porcino_cambio
SELECT
    max(CAST(anio AS INTEGER)) FILTER (WHERE anio = (SELECT min(anio) FROM ${serie_porcino})) AS anio_ini,
    max(cuota_pct) FILTER (WHERE anio = (SELECT min(anio) FROM ${serie_porcino})) AS cuota_ini,
    max(cuota_pct) FILTER (WHERE anio = (SELECT max(anio) FROM ${serie_porcino})) AS cuota_fin,
    max(cuota_pct) FILTER (WHERE anio = (SELECT max(anio) FROM ${serie_porcino}))
      - max(cuota_pct) FILTER (WHERE anio = (SELECT min(anio) FROM ${serie_porcino})) AS dif_pp
FROM ${serie_porcino}
```

```sql aceite_es
SELECT campania, CAST(anio AS INTEGER) AS anio, produccion_miles_t, cuota_ue_pct, cuota_mundo_pct, kg_hab, estimado
FROM mother.primario_aceite
WHERE grupo = 'España'
ORDER BY anio
```

```sql aceite_kpi
SELECT
    arg_max(campania, anio) FILTER (WHERE NOT estimado) AS campania,
    arg_max(cuota_ue_pct, anio) FILTER (WHERE NOT estimado) AS cuota_ue,
    arg_max(cuota_mundo_pct, anio) FILTER (WHERE NOT estimado) AS cuota_mundo,
    arg_max(produccion_miles_t, anio) FILTER (WHERE NOT estimado) AS prod_kt,
    arg_max(kg_hab, anio) FILTER (WHERE NOT estimado) AS kg_hab,
    arg_max(campania, anio) AS campania_est,
    arg_max(cuota_ue_pct, anio) AS cuota_ue_est,
    arg_max(cuota_mundo_pct, anio) AS cuota_mundo_est,
    arg_max(produccion_miles_t, anio) AS prod_kt_est,
    bool_or(estimado) FILTER (WHERE anio = (SELECT max(anio) FROM ${aceite_es})) AS ultima_estimada,
    min(campania) AS desde,
    avg(cuota_ue_pct) AS cuota_media,
    min(cuota_ue_pct) AS cuota_min,
    arg_min(campania, cuota_ue_pct) AS campania_min,
    min(produccion_miles_t) AS prod_min,
    max(produccion_miles_t) AS prod_max,
    arg_max(campania, produccion_miles_t) AS campania_max
FROM ${aceite_es}
```

```sql aceite_grupos
SELECT campania, grupo, cuota_ue_pct, produccion_miles_t, kg_hab,
       CASE grupo WHEN 'España' THEN 1 WHEN 'Italia' THEN 2 WHEN 'Grecia' THEN 3 WHEN 'Portugal' THEN 4 ELSE 5 END AS orden
FROM mother.primario_aceite
WHERE grupo <> 'Mundo (COI)'
  AND campania >= (SELECT min(campania) FROM mother.primario_aceite WHERE grupo = 'España')
ORDER BY campania, orden
```

```sql aceite_mundo
SELECT
    max(valor) FILTER (WHERE cod = 'ES') AS espana,
    max(valor) FILTER (WHERE puesto_mundo = 2) AS segundo,
    max(pais) FILTER (WHERE puesto_mundo = 2) AS pais_segundo,
    max(valor) FILTER (WHERE cod = 'ES') / max(valor) FILTER (WHERE puesto_mundo = 2) AS veces_segundo,
    max(valor) FILTER (WHERE cod = 'MUNDO') AS mundo,
    max(periodo) AS campania
FROM mother.primario_mundo
WHERE indicador = 'aceite_produccion' AND periodo = '2024/25'
```

```sql aceite_export
SELECT cuota_pct, puesto, valor_espana, valor_hab_espana, pais_segundo
FROM ${ranking}
WHERE producto_id IN ('HS_1509_t', 'HS_1509')
ORDER BY producto_id DESC
```

```sql aceite_precios
SELECT mes, pais, eur_kg_real, eur_kg
FROM mother.primario_aceite_precios
WHERE categoria = 'Virgen extra' AND geo IN ('ES', 'IT', 'EL') AND eur_kg_real IS NOT NULL
ORDER BY mes, pais
```

```sql precio_resumen
SELECT
    max(eur_kg_real) AS maximo,
    strftime(arg_max(mes, eur_kg_real), '%m/%Y') AS mes_maximo,
    arg_max(eur_kg_real, mes) AS ultimo,
    arg_max(eur_kg, mes) AS ultimo_nominal,
    strftime(max(mes), '%m/%Y') AS mes_ultimo,
    avg(eur_kg_real) FILTER (WHERE year(mes) BETWEEN 2015 AND 2019) AS media_2015_2019,
    strftime(max(mes_base), '%m/%Y') AS mes_base
FROM mother.primario_aceite_precios
WHERE categoria = 'Virgen extra' AND geo = 'ES' AND eur_kg_real IS NOT NULL
```

```sql huerta
SELECT grupo, producto, anio, cuota_pct, puesto, pais_referencia, veces_peso_poblacion, valor_hab_espana, valor_hab_ue, unidad_hab, nota
FROM ${ranking}
WHERE (categoria = 'cultivo' AND producto_id LIKE '%_prod'
       AND (producto_id LIKE 'V%' OR producto_id LIKE 'T%' OR producto_id LIKE 'S%' OR producto_id LIKE 'F%'))
   OR producto_id IN ('HS_07', 'HS_0702', 'HS_0709', 'HS_08', 'HS_0805', 'HS_0802', 'AM060000', 'AM040000')
ORDER BY orden, cuota_pct DESC
```

```sql huerta_resumen
SELECT
    max(cuota_pct) FILTER (WHERE producto_id = 'V0000_S0000_prod') AS hortalizas,
    max(valor_hab_espana) FILTER (WHERE producto_id = 'V0000_S0000_prod') AS hortalizas_kg,
    max(valor_hab_ue) FILTER (WHERE producto_id = 'V0000_S0000_prod') AS hortalizas_kg_ue,
    max(cuota_pct) FILTER (WHERE producto_id = 'HS_07') AS exp_hortalizas,
    max(puesto) FILTER (WHERE producto_id = 'HS_07') AS exp_hortalizas_puesto,
    max(cuota_pct) FILTER (WHERE producto_id = 'HS_08') AS exp_frutas,
    max(puesto) FILTER (WHERE producto_id = 'HS_08') AS exp_frutas_puesto,
    max(cuota_pct) FILTER (WHERE producto_id = 'HS_0805') AS exp_citricos,
    max(cuota_pct) FILTER (WHERE producto_id = 'AM060000') AS valor_frutas,
    max(CAST(anio AS INTEGER)) FILTER (WHERE producto_id = 'HS_07') AS anio_exp,
    max(cuota_pct) FILTER (WHERE producto_id = 'V3100_prod') AS tomate,
    max(pais_primero) FILTER (WHERE producto_id = 'V3100_prod') AS tomate_primero
FROM ${ranking}
```

```sql huerta_serie
SELECT CAST(anio AS INTEGER) AS anio, cuota_pct,
       CASE producto_id WHEN 'V0000_S0000_prod' THEN 'Producción de hortalizas y fresa (t)'
                        WHEN 'T0000_prod' THEN 'Producción de cítricos (t)'
                        WHEN 'HS_07' THEN 'Exportación de hortalizas (€)'
                        WHEN 'HS_08' THEN 'Exportación de frutas y frutos secos (€)' END AS serie
FROM mother.primario_serie_espana
WHERE producto_id IN ('V0000_S0000_prod', 'T0000_prod', 'HS_07', 'HS_08') AND n_paises = 27
ORDER BY anio, serie
```

```sql vino
SELECT producto, cuota_pct, puesto, pais_primero, CAST(anio AS INTEGER) AS anio,
       CASE producto_id WHEN 'W1000_sup' THEN 1 WHEN 'W1100_prod' THEN 2 WHEN 'HS_2204_t' THEN 3
                        WHEN 'HS_2204' THEN 4 ELSE 5 END AS orden
FROM ${ranking}
WHERE producto_id IN ('W1000_sup', 'W1100_prod', 'HS_2204_t', 'HS_2204', 'AM070000')
ORDER BY orden
```

```sql vino_mundo
SELECT
    max(valor) FILTER (WHERE indicador = 'vinedo_superficie' AND cod = 'ES') AS vinedo_es,
    100 * max(valor) FILTER (WHERE indicador = 'vinedo_superficie' AND cod = 'ES')
        / max(valor) FILTER (WHERE indicador = 'vinedo_superficie' AND cod = 'MUNDO') AS vinedo_pct,
    max(puesto_mundo) FILTER (WHERE indicador = 'vinedo_superficie' AND cod = 'ES') AS vinedo_puesto,
    max(valor) FILTER (WHERE indicador = 'vino_produccion' AND cod = 'ES') AS vino_es,
    max(puesto_mundo) FILTER (WHERE indicador = 'vino_produccion' AND cod = 'ES') AS vino_puesto,
    100 * max(valor) FILTER (WHERE indicador = 'vino_produccion' AND cod = 'ES')
        / max(valor) FILTER (WHERE indicador = 'vino_produccion' AND cod = 'MUNDO') AS vino_pct,
    max(valor) FILTER (WHERE indicador = 'vino_exportacion_volumen' AND cod = 'ES') AS exp_vol_es,
    max(puesto_mundo) FILTER (WHERE indicador = 'vino_exportacion_volumen' AND cod = 'ES') AS exp_vol_puesto,
    max(valor) FILTER (WHERE indicador = 'vino_exportacion_valor' AND cod = 'ES') AS exp_val_es,
    max(valor) FILTER (WHERE indicador = 'vino_exportacion_valor' AND cod = 'FR') AS exp_val_fr,
    max(valor) FILTER (WHERE indicador = 'vino_exportacion_valor' AND cod = 'IT') AS exp_val_it,
    max(anio) AS anio
FROM mother.primario_mundo
WHERE indicador LIKE 'vin%'
```

```sql vino_precio
SELECT a.pais, a.valor / b.valor AS eur_kg, CAST(a.anio AS INTEGER) AS anio,
       CASE WHEN a.cod_pais = 'ES' THEN 'España' ELSE 'Otros países' END AS grupo
FROM mother.primario_paises_largo a
JOIN mother.primario_paises_largo b
  ON b.cod_pais = a.cod_pais AND b.anio = a.anio AND b.producto_id = 'HS_2204_t'
WHERE a.producto_id = 'HS_2204'
  AND a.anio = (SELECT max(anio) FROM mother.primario_paises_largo WHERE producto_id = 'HS_2204')
  AND b.valor >= 100
ORDER BY eur_kg DESC
```

```sql vino_precio_resumen
SELECT
    max(eur_kg) FILTER (WHERE pais = 'España') AS es,
    max(eur_kg) FILTER (WHERE pais = 'Francia') AS fr,
    max(eur_kg) FILTER (WHERE pais = 'Italia') AS it,
    max(anio) AS anio
FROM ${vino_precio}
```

```sql ganaderia
SELECT producto, cuota_pct, cuota_min_pct, puesto, pais_referencia, veces_peso_poblacion,
       valor_hab_espana, valor_hab_ue, unidad_hab, anio, paises_sin_dato,
       CASE WHEN puesto = 1 THEN '1.º de la UE' WHEN puesto <= 3 THEN '2.º o 3.º' ELSE '4.º o peor' END AS posicion
FROM ${ranking}
WHERE categoria = 'ganaderia'
ORDER BY cuota_pct DESC
```

```sql ganaderia_resumen
SELECT
    max(cuota_pct) FILTER (WHERE producto = 'Carne de ovino') AS ovino,
    max(cuota_pct) FILTER (WHERE producto = 'Carne de aves') AS aves,
    max(puesto) FILTER (WHERE producto = 'Carne de aves') AS aves_puesto,
    max(pais_referencia) FILTER (WHERE producto = 'Carne de aves') AS aves_primero,
    max(cuota_pct) FILTER (WHERE producto = 'Carne de bovino') AS bovino,
    max(puesto) FILTER (WHERE producto = 'Carne de bovino') AS bovino_puesto,
    max(cuota_pct) FILTER (WHERE producto = 'Leche de vaca') AS leche,
    max(puesto) FILTER (WHERE producto = 'Leche de vaca') AS leche_puesto,
    max(valor_hab_espana) FILTER (WHERE producto = 'Leche de vaca') AS leche_kg,
    max(valor_hab_ue) FILTER (WHERE producto = 'Leche de vaca') AS leche_kg_ue,
    max(valor_hab_espana) FILTER (WHERE producto = 'Cabaña porcina') AS cerdos_1000,
    max(valor_hab_ue) FILTER (WHERE producto = 'Cabaña porcina') AS cerdos_1000_ue
FROM ${ganaderia}
```

```sql pesca
SELECT producto, cuota_pct, cuota_min_pct, puesto, n_paises, pais_referencia, veces_peso_poblacion,
       valor_hab_espana, valor_hab_ue, unidad_hab, anio, paises_sin_dato
FROM ${ranking}
WHERE categoria = 'pesca'
ORDER BY cuota_pct DESC
```

```sql pesca_resumen
SELECT
    max(cuota_pct) FILTER (WHERE producto_id = 'capturas') AS capturas,
    max(cuota_min_pct) FILTER (WHERE producto_id = 'capturas') AS capturas_min,
    max(CAST(anio AS INTEGER)) FILTER (WHERE producto_id = 'capturas') AS capturas_anio,
    max(paises_sin_dato) FILTER (WHERE producto_id = 'capturas') AS capturas_sin,
    max(valor_espana) FILTER (WHERE producto_id = 'capturas') AS capturas_kt,
    max(valor_hab_espana) FILTER (WHERE producto_id = 'capturas') AS capturas_kg,
    max(cuota_pct) FILTER (WHERE producto_id = 'acuicultura_t') AS acui,
    max(valor_hab_espana) FILTER (WHERE producto_id = 'acuicultura_t') AS acui_kg,
    max(cuota_pct) FILTER (WHERE producto_id = 'acuicultura_eur') AS acui_eur,
    max(pais_primero) FILTER (WHERE producto_id = 'acuicultura_eur') AS acui_eur_primero,
    max(cuota_pct) FILTER (WHERE producto_id = 'flota_gt') AS flota_gt,
    max(cuota_pct) FILTER (WHERE producto_id = 'flota_nr') AS flota_nr,
    max(puesto) FILTER (WHERE producto_id = 'flota_nr') AS flota_nr_puesto,
    max(valor_espana) FILTER (WHERE producto_id = 'flota_nr') AS buques
FROM mother.primario_ranking_ue
WHERE categoria = 'pesca'
```

```sql pesca_serie
SELECT CAST(anio AS INTEGER) AS anio, 'Sobre los países con dato' AS medida, cuota_pct AS cuota
FROM mother.primario_pesca WHERE cod_pais = 'ES' AND medida = 'capturas' AND anio >= 2010
UNION ALL
SELECT CAST(anio AS INTEGER), 'Prudente (con el último dato de los que faltan)', cuota_min_pct
FROM mother.primario_pesca WHERE cod_pais = 'ES' AND medida = 'capturas' AND anio >= 2010
ORDER BY anio, medida
```

```sql pesca_paises
SELECT pais, valor_hab AS kg_hab, valor, CASE WHEN cod_pais = 'ES' THEN 'España' ELSE 'Otros países' END AS grupo
FROM mother.primario_pesca
WHERE medida = 'capturas' AND anio = (SELECT max(anio) FROM mother.primario_ranking_ue WHERE producto_id = 'capturas')
ORDER BY kg_hab DESC
```

```sql pesca_hab
SELECT
    CAST(max(rk) FILTER (WHERE grupo = 'España') AS INTEGER) AS puesto_hab,
    max(pais) FILTER (WHERE rk = 1) AS primero_hab,
    max(kg_hab) FILTER (WHERE rk = 1) AS primero_kg
FROM (SELECT *, rank() OVER (ORDER BY kg_hab DESC) AS rk FROM ${pesca_paises})
```

```sql valor_es
SELECT CAST(anio AS INTEGER) AS anio, produccion_eur_hab_real, vab_eur_hab_real, volumen_eur2020_hab, renta_real_uta_eur2020
FROM mother.primario_valor_produccion
WHERE geo = 'ES' AND produccion_eur_hab_real IS NOT NULL
ORDER BY anio
```

```sql valor_paises
SELECT CAST(anio AS INTEGER) AS anio, CASE WHEN geo = 'EU27_2020' THEN 'UE-27' ELSE pais END AS pais,
       produccion_eur_hab_real_pib, renta_real_uta_eur2020
FROM mother.primario_valor_produccion
WHERE geo IN ('ES', 'EU27_2020', 'FR', 'DE', 'IT', 'NL', 'PL') AND produccion_eur_hab_real_pib IS NOT NULL
ORDER BY anio, pais
```

```sql valor_resumen
SELECT
    max(CAST(anio AS INTEGER)) AS anio,
    max(produccion_eur_hab_real) FILTER (WHERE geo = 'ES' AND anio = (SELECT max(anio) FROM mother.primario_valor_produccion)) AS es,
    max(produccion_eur_hab_real) FILTER (WHERE geo = 'EU27_2020' AND anio = (SELECT max(anio) FROM mother.primario_valor_produccion)) AS ue,
    max(produccion_meur) FILTER (WHERE geo = 'ES' AND anio = (SELECT max(anio) FROM mother.primario_valor_produccion)) AS es_meur,
    max(vab_eur_hab_real) FILTER (WHERE geo = 'ES' AND anio = (SELECT max(anio) FROM mother.primario_valor_produccion)) AS es_vab,
    max(vab_eur_hab_real) FILTER (WHERE geo = 'EU27_2020' AND anio = (SELECT max(anio) FROM mother.primario_valor_produccion)) AS ue_vab,
    max(renta_real_uta_eur2020) FILTER (WHERE geo = 'ES' AND anio = (SELECT max(anio) FROM mother.primario_valor_produccion)) AS renta_es,
    max(renta_real_uta_eur2020) FILTER (WHERE geo = 'EU27_2020' AND anio = (SELECT max(anio) FROM mother.primario_valor_produccion)) AS renta_ue,
    max(volumen_eur2020_hab) FILTER (WHERE geo = 'ES' AND anio = 2005) AS vol_2005,
    max(volumen_eur2020_hab) FILTER (WHERE geo = 'ES' AND anio = (SELECT max(anio) FROM mother.primario_valor_produccion)) AS vol_ultimo,
    100 * (max(volumen_eur2020_hab) FILTER (WHERE geo = 'ES' AND anio = (SELECT max(anio) FROM mother.primario_valor_produccion))
           / max(volumen_eur2020_hab) FILTER (WHERE geo = 'ES' AND anio = 2005) - 1) AS vol_var
FROM mother.primario_valor_produccion
```

```sql valor_rank
SELECT CAST(rank() OVER (ORDER BY produccion_eur_hab_real_pib DESC) AS INTEGER) AS rk, pais, geo, produccion_eur_hab_real_pib
FROM mother.primario_valor_produccion
WHERE anio = (SELECT max(anio) FROM mother.primario_valor_produccion) AND geo <> 'EU27_2020'
ORDER BY rk
```

```sql valor_productos
SELECT producto, cuota_pct, puesto, pais_referencia, veces_peso_poblacion, valor_hab_espana, valor_hab_ue, anio
FROM ${ranking}
WHERE categoria = 'valor'
ORDER BY cuota_pct DESC
```

```sql provincias
SELECT c.cod AS cod_prov, c.nombre AS provincia, CAST(c.anio AS INTEGER) AS anio, c.peso_vab_pct,
       c.vab_primario_eur_hab_real, '/eu' || t.ruta AS ruta
FROM mother.primario_ccaa c
LEFT JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = c.cod
WHERE c.nivel = 'provincia' AND c.anio = (SELECT max(anio) FROM mother.primario_ccaa WHERE nivel = 'provincia')
ORDER BY c.peso_vab_pct DESC
```

```sql provincias_resumen
SELECT
    max(anio) AS anio,
    string_agg(provincia || ' (' || replace(CAST(round(peso_vab_pct, 1) AS VARCHAR), '.', ',') || ' %)', ', ' ORDER BY peso_vab_pct DESC) FILTER (WHERE rk <= 5) AS mas,
    CAST(count(*) FILTER (WHERE peso_vab_pct >= 10) AS INTEGER) AS mas_10
FROM (SELECT *, row_number() OVER (ORDER BY peso_vab_pct DESC) AS rk FROM ${provincias})
```

```sql ccaa
SELECT c.cod AS cod_ccaa, c.nombre AS comunidad, CAST(c.anio AS INTEGER) AS anio, c.peso_vab_pct,
       c.vab_primario_eur_hab_real, c.vab_primario_meur, c0.peso_vab_pct AS peso_2000, '/eu' || t.ruta AS ruta
FROM mother.primario_ccaa c
LEFT JOIN mother.primario_ccaa c0 ON c0.nivel = c.nivel AND c0.cod = c.cod AND c0.anio = 2000
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = c.cod
WHERE c.nivel = 'ccaa' AND c.anio = (SELECT max(anio) FROM mother.primario_ccaa WHERE nivel = 'ccaa')
ORDER BY c.peso_vab_pct DESC
```

```sql espana_vab
SELECT
    max(CAST(anio AS INTEGER)) AS anio,
    arg_max(peso_vab_pct, anio) AS peso,
    max(peso_vab_pct) FILTER (WHERE anio = 2000) AS peso_2000,
    arg_max(vab_primario_eur_hab_real, anio) AS eur_hab
FROM mother.primario_ccaa
WHERE nivel = 'pais'
```

```sql ccaa_resumen
SELECT
    string_agg(comunidad, ', ' ORDER BY peso_vab_pct DESC) FILTER (WHERE rk <= 3) AS mas,
    max(peso_vab_pct) FILTER (WHERE rk = 1) AS max_peso,
    max(vab_primario_eur_hab_real) FILTER (WHERE rk = 1) AS max_eur_hab,
    max(comunidad) FILTER (WHERE rk_hab = 1) AS max_hab_ccaa,
    max(vab_primario_eur_hab_real) FILTER (WHERE rk_hab = 1) AS max_hab
FROM (
    SELECT *, row_number() OVER (ORDER BY peso_vab_pct DESC) AS rk,
              row_number() OVER (ORDER BY vab_primario_eur_hab_real DESC) AS rk_hab
    FROM ${ccaa}
    WHERE cod_ccaa NOT IN ('18', '19')
)
```

```sql cereales_ccaa
SELECT ccaa, cuota_espana_pct, kg_hab, produccion_miles_t, CAST(anio AS INTEGER) AS anio
FROM mother.primario_ccaa_cultivos
WHERE producto_id = 'C0000'
  AND anio = (SELECT max(anio) FROM mother.primario_ccaa_cultivos WHERE producto_id = 'C0000')
  AND cuota_espana_pct >= 0.5
ORDER BY cuota_espana_pct DESC
```

```sql cereales_resumen
SELECT
    max(anio) AS anio,
    sum(cuota_espana_pct) FILTER (WHERE rk <= 3) AS top3,
    string_agg(ccaa, ', ' ORDER BY cuota_espana_pct DESC) FILTER (WHERE rk <= 3) AS lista
FROM (SELECT *, row_number() OVER (ORDER BY cuota_espana_pct DESC) AS rk FROM ${cereales_ccaa})
```
# 🌾 Lehen sektorea

Nekazaritza, abeltzaintza eta arrantza: zertan den Espainia **Europar Batasuneko lehena** eta zertan ez. Produktu bakoitza **27en guztizkoan duen kuotaren** arabera neurtzen da, eta Espainiak EBko biztanlerian duen pisuarekin alderatzen da ({formatNumber(ranking_resumen[0]?.peso_pob, 1)} %): 50 %-ko kuota bat biztanleen arabera «dagokiona» bider {formatNumber(50 / ranking_resumen[0]?.peso_pob, 1)} da. Euroetako balioak **biztanleko eta inflazioa kenduta** ematen dira.

<Grid cols=4>
    <KpiCard
        title="Oliba-olioa: kuota EBn"
        value={aceite_kpi[0]?.cuota_ue}
        formattedValue="{formatNumber(aceite_kpi[0]?.cuota_ue, 1)} %"
        period="{aceite_kpi[0]?.campania} kanpaina · munduaren {formatNumber(aceite_kpi[0]?.cuota_mundo, 1)} % (COI) · {formatNumber(aceite_kpi[0]?.prod_kt, 0)} mila t"
        direction="neutral"
        source="Europako Batzordea · COI"
        sparklineData={aceite_es.map(d => ({...d, y: d.cuota_ue_pct}))}
    />
    <KpiCard
        title="Zitrikoak: kuota EBn"
        value={kpi[0]?.citricos}
        formattedValue="{formatNumber(kpi[0]?.citricos, 1)} %"
        period="{kpi[0]?.citricos_anio} · EBko 1.a · {formatNumber(kpi[0]?.citricos_kt, 0)} mila t"
        direction="neutral"
        source="Eurostat (apro_cpsh1)"
        sparklineData={serie_citricos.map(d => ({...d, y: d.cuota_pct}))}
    />
    <KpiCard
        title="Txerri-haragia: kuota EBn"
        value={kpi[0]?.porcino}
        formattedValue="{formatNumber(kpi[0]?.porcino, 1)} %"
        period="{kpi[0]?.porcino_anio} · EBko 1.a · {formatNumber(kpi[0]?.porcino_kg_hab, 0)} kg biztanleko (EB: {formatNumber(kpi[0]?.porcino_kg_hab_ue, 0)})"
        change={porcino_cambio[0]?.dif_pp?.toFixed(1)}
        changeUnit="pp"
        changePeriod="{porcino_cambio[0]?.anio_ini}arekin alderatuta"
        direction="neutral"
        source="Eurostat (apro_mt_pann)"
        sparklineData={serie_porcino.map(d => ({...d, y: d.cuota_pct}))}
    />
    <KpiCard
        title="Nekazaritza-ekoizpena biztanleko"
        value={valor_resumen[0]?.es}
        formattedValue="{formatNumber(valor_resumen[0]?.es, 0)} €"
        period="{valor_resumen[0]?.anio}, gaurko euroak · EB-27: {formatNumber(valor_resumen[0]?.ue, 0)} € · {formatNumber(valor_resumen[0]?.es_meur, 0)} milioi € guztira"
        direction="positive-up"
        source="Eurostat (aact_eaa01)"
        sparklineData={valor_es.map(d => ({...d, y: d.produccion_eur_hab_real}))}
    />
</Grid>

## Non den Espainia EBko lehena

Hemen alderatzen diren ekoizpen, azalera, abere-buru, arrantza eta esportazioko {ranking_resumen[0]?.total} adierazleetatik, Espainia **EBko lehena da {ranking_resumen[0]?.primeros} adierazletan**, eta lehen hiruren artean dago {ranking_resumen[0]?.podio} adierazletan: lehena da laborantzako adierazleetan {ranking_resumen[0]?.prim_cultivo}/{ranking_resumen[0]?.n_cultivo}, abeltzaintzakoetan {ranking_resumen[0]?.prim_ganaderia}/{ranking_resumen[0]?.n_ganaderia}, arrantza eta akuikulturakoetan {ranking_resumen[0]?.prim_pesca}/{ranking_resumen[0]?.n_pesca} eta esportaziokoetan {ranking_resumen[0]?.prim_export}/{ranking_resumen[0]?.n_export}. Ekoizpenean kuotarik handienak hauek dira: {ranking_top[0]?.lista}. {ranking_resumen[0]?.doble_peso} adierazletan Espainiaren kuota haren biztanleria-pisuaren bikoitza da, gutxienez.

<BarChart
    data={ranking_primeros}
    x=producto
    y=cuota_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0"%"'
    yAxisTitle="EB-27ko guztizkoaren %"
    seriesColors={{'Cultivos': '#16a34a', 'Ganadería': '#b45309', 'Pesca y acuicultura': '#0284c7', 'Exportaciones': '#7c3aed'}}
    title="Espainia EBko lehena den adierazleak: kuota 27en guztizkoan (%)"
/>

Taula osoa, postuarekin eta «biztanleria-pisuaren aldiz» zutabearekin (Espainiaren kuota, EBko biztanlerian duen pisuaz zatituta; 1 da biztanleen arabera dagokiona). Urtea herrialde ia guztien datuak dituen azkena da; azken zutabeak lehen herrialdea ematen du, edo bigarrena Espainia lehena denean.

<DataTable data={ranking_productos} rows=20 search=true groupBy=grupo groupsOpen=true>
    <Column id=producto title="Produktua" />
    <Column id=cuota_pct title="Kuota EBn %" fmt='0.0' contentType=bar barColor='#16a34a' />
    <Column id=puesto title="Postua" fmt='0' />
    <Column id=veces_peso_poblacion title="Biztanleria-pisuaren aldiz" fmt='0.0' />
    <Column id=valor_hab_espana title="Espainia biz." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="EB biz." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unitatea" />
    <Column id=pais_referencia title="1.a (edo 2.a Espainia lider bada)" />
    <Column id=anio title="Urtea" fmt='0' />
</DataTable>

Espainia lehen postuetatik urrun dagoen lekuak (laborantza eta abeltzaintza, txarrenetik onenera): {ranking_flojos[0]?.lista}.

## Europako baratza

Espainiak EBko barazki freskoen {formatNumber(huerta_resumen[0]?.hortalizas, 1)} % ekoizten du (meloia eta marrubia barne), {formatNumber(huerta_resumen[0]?.hortalizas_kg, 0)} kg biztanleko, EBko batez besteko {formatNumber(huerta_resumen[0]?.hortalizas_kg_ue, 0)} kg-ren aldean, eta frutaren balioaren {formatNumber(huerta_resumen[0]?.valor_frutas, 1)} % (zitrikoak, mahatsa eta oliba barne). {urteko(huerta_resumen[0]?.anio_exp)} esportazioetan {huerta_resumen[0]?.exp_hortalizas_puesto}.a da barazkietan (27ek esportatzen dutenaren {formatNumber(huerta_resumen[0]?.exp_hortalizas, 1)} %, elkarri saltzen diotena barne) eta {huerta_resumen[0]?.exp_frutas_puesto}.a frutetan eta fruitu lehorretan ({formatNumber(huerta_resumen[0]?.exp_frutas, 1)} %); zitrikoetan {formatNumber(huerta_resumen[0]?.exp_citricos, 1)} %-ra iristen da. Tomatean lehen ekoizlea {huerta_resumen[0]?.tomate_primero} da: Espainiak {formatNumber(huerta_resumen[0]?.tomate, 1)} % du.

<LineChart
    data={huerta_serie}
    x=anio
    y=cuota_pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="EB-27ko guztizkoaren %"
    title="Espainiaren kuota EBn: frutak eta barazkiak (27 herrialdeak dituzten urteak bakarrik)"
/>

<DataTable data={huerta} rows=30 search=true groupBy=grupo groupsOpen=true>
    <Column id=producto title="Produktua" />
    <Column id=cuota_pct title="Kuota EBn %" fmt='0.0' contentType=bar barColor='#16a34a' />
    <Column id=puesto title="Postua" fmt='0' />
    <Column id=veces_peso_poblacion title="Biztanleria-pisuaren aldiz" fmt='0.0' />
    <Column id=valor_hab_espana title="Espainia biz." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="EB biz." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unitatea" />
    <Column id=pais_referencia title="1.a (edo 2.a Espainia lider bada)" />
</DataTable>

Esportazioetan, Herbehereak puztuta ateratzen dira, kanpotik inportatzen dutena Rotterdametik berresportatzen dutelako; eta zifra guztiek EB barruko merkataritza hartzen dute barne.

## Oliba-olioa

Europako Batzordearen arabera, {aceite_kpi[0]?.campania} kanpainan (urritik irailera) Espainiak **{formatNumber(aceite_kpi[0]?.prod_kt, 0)} mila tona** ekoitzi zituen, EBko olioaren {formatNumber(aceite_kpi[0]?.cuota_ue, 1)} % eta {formatNumber(aceite_kpi[0]?.kg_hab, 1)} kg biztanleko. {aceite_kpi[0]?.desde} kanpainatik, haren batez besteko kuota {formatNumber(aceite_kpi[0]?.cuota_media, 1)} %-koa da; txikiena {aceite_kpi[0]?.campania_min} kanpainakoa izan zen ({formatNumber(aceite_kpi[0]?.cuota_min, 1)} %), {formatNumber(aceite_kpi[0]?.prod_min, 0)} mila tonarekin, eta ekoizpenaren gehienekoa, {formatNumber(aceite_kpi[0]?.prod_max, 0)}, {aceite_kpi[0]?.campania_max} kanpainan lortu zen.

{#if aceite_kpi[0]?.ultima_estimada}
<p>{aceite_kpi[0]?.campania_est} kanpaina oraindik <strong>estimazio bat</strong> da: {formatNumber(aceite_kpi[0]?.prod_kt_est, 0)} mila tona, EBko {formatNumber(aceite_kpi[0]?.cuota_ue_est, 1)} % eta COIen munduko aurreikuspenaren {formatNumber(aceite_kpi[0]?.cuota_mundo_est, 1)} %.</p>
{/if}

<BarChart
    data={aceite_grupos}
    x=campania
    y=cuota_ue_pct
    series=grupo
    type=stacked
    sort=false
    yFmt='0"%"'
    yAxisTitle="EBko ekoizpenaren %"
    seriesColors={{'España': '#dc2626', 'Italia': '#16a34a', 'Grecia': '#2563eb', 'Portugal': '#f59e0b', 'Resto de la UE': '#94a3b8'}}
    title="EBko oliba-olioaren ekoizpena herrialdeka, kanpaina bakoitzaren % (azkena, estimatua)"
/>

EBtik kanpo, Nazioarteko Oliba Kontseiluak (COI) {aceite_mundo[0]?.campania} kanpainarako {formatNumber(aceite_mundo[0]?.mundo, 0)} mila tonako munduko ekoizpena ematen du: Espainia, {formatNumber(aceite_mundo[0]?.espana, 0)} mila tonarekin, lehena izan zen, eta bigarrenak ({aceite_mundo[0]?.pais_segundo}) baino {formatNumber(aceite_mundo[0]?.veces_segundo, 1)} aldiz gehiago ekoitzi zuen. Espainia EBko lehen esportatzailea ere bada: 27ek saltzen duten olioaren {formatNumber(aceite_export[0]?.cuota_pct, 1)} % bolumenean eta {formatNumber(aceite_export[1]?.cuota_pct, 1)} % euroetan.

Espainiako merkatuetan **birjina estraren** jatorriko prezioak, {precio_resumen[0]?.mes_base} hilabeteko euroetan, goia jo zuen {precio_resumen[0]?.mes_maximo} hilabetean, {formatNumber(precio_resumen[0]?.maximo, 2)} €/kg-rekin; {precio_resumen[0]?.mes_ultimo} hilabetean {formatNumber(precio_resumen[0]?.ultimo, 2)} €/kg zen, 2015 eta 2019 arteko gaurko {formatNumber(precio_resumen[0]?.media_2015_2019, 2)} €/kg-ko batez bestekoaren aldean.

<LineChart
    data={aceite_precios}
    x=mes
    y=eur_kg_real
    series=pais
    yFmt='0.00" €"'
    yAxisTitle="€/kg gaurko euroetan"
    seriesColors={{'España': '#dc2626', 'Italia': '#16a34a', 'Grecia': '#2563eb'}}
    title="Oliba-olio birjina estraren jatorriko prezioa, €/kg inflazioa kenduta (merkatuen hileko batez bestekoa)"
/>

## Ardoa

Espainiak **munduko mahasti handiena** du: {formatNumber(vino_mundo[0]?.vinedo_es, 0)} mila hektarea {urtean(vino_mundo[0]?.anio)}, munduko guztizkoaren {formatNumber(vino_mundo[0]?.vinedo_pct, 1)} %, OIVren arabera. Ardoan munduko {vino_mundo[0]?.vino_puesto}. ekoizlea da ({formatNumber(vino_mundo[0]?.vino_es, 1)} milioi hektolitro, {formatNumber(vino_mundo[0]?.vino_pct, 1)} %) eta bolumenean {vino_mundo[0]?.exp_vol_puesto}. esportatzailea ({formatNumber(vino_mundo[0]?.exp_vol_es, 1)} milioi hektolitro); balioan {formatNumber(vino_mundo[0]?.exp_val_es, 1)} mila milioi euro esportatzen ditu, Frantziaren {formatNumber(vino_mundo[0]?.exp_val_fr, 1)} eta Italiaren {formatNumber(vino_mundo[0]?.exp_val_it, 1)} mila milioien aldean.

Aldea prezioan dago: {urtean(vino_precio_resumen[0]?.anio)} Espainiak esportatutako ardoa {formatNumber(vino_precio_resumen[0]?.es, 2)} €-tan atera zen kiloko (litroko ia berdin), italiarra {formatNumber(vino_precio_resumen[0]?.it, 2)} €-tan eta frantziarra {formatNumber(vino_precio_resumen[0]?.fr, 2)} €-tan.

<BarChart
    data={vino}
    x=producto
    y=cuota_pct
    swapXY=true
    sort=false
    yFmt='0"%"'
    yAxisTitle="EB-27ko guztizkoaren %"
    fillColor='#7c2d12'
    title="Ardoa: Espainiaren kuota EBn, zer neurtzen den kontuan hartuta (%)"
/>

<BarChart
    data={vino_precio}
    x=pais
    y=eur_kg
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.00" €"'
    yAxisTitle="€ esportatutako kiloko"
    seriesColors={{'España': '#dc2626', 'Otros países': '#93c5fd'}}
    title="Esportatutako ardoaren batez besteko prezioa (100.000 t baino gehiago esportatzen dituzten herrialdeak), € kiloko"
/>

**Kontuz nekazaritzako kontuekin:** Eurostaten «ardoaren balioak» EBko {formatNumber(vino[4]?.cuota_pct, 1)} %-an uzten du Espainia, ustiategiek berek egiten duten ardoa bakarrik zenbatzen duelako; Espainian, gehiena nekazaritza-adarretik kanpoko upategiek eta kooperatibek egiten dute, eta saldutako mahats gisa kontabilizatzen da. Ardoa alderatzeko, hobe da OIV edo mahastia erabiltzea.

## Abeltzaintza

Espainia EBko lehena da **txerri-haragian** ({formatNumber(kpi[0]?.porcino, 1)} %, {kpi[0]?.porcino_segundo} herrialdearen aurretik) eta **ardi-haragian** ({formatNumber(ganaderia_resumen[0]?.ovino, 1)} %). {formatNumber(ganaderia_resumen[0]?.cerdos_1000, 0)} txerri ditu 1.000 biztanleko, EBko {formatNumber(ganaderia_resumen[0]?.cerdos_1000_ue, 0)} txerrien aldean. Txerrikietan duen kuota {urteko(porcino_cambio[0]?.anio_ini)} {formatNumber(porcino_cambio[0]?.cuota_ini, 1)} %-tik {formatNumber(porcino_cambio[0]?.cuota_fin, 1)} %-ra igaro da. Hegaztietan {ganaderia_resumen[0]?.aves_puesto}.a da ({formatNumber(ganaderia_resumen[0]?.aves, 1)} %; lehena: {ganaderia_resumen[0]?.aves_primero}), eta behi-haragian {ganaderia_resumen[0]?.bovino_puesto}.a ({formatNumber(ganaderia_resumen[0]?.bovino, 1)} %). Ahulgunea **esnea** da: {ganaderia_resumen[0]?.leche_puesto}.a da, EBko {formatNumber(ganaderia_resumen[0]?.leche, 1)} %-rekin eta biztanleko entregatutako {formatNumber(ganaderia_resumen[0]?.leche_kg, 0)} kg behi-esnerekin, batez bestekoaren erdia baino gutxiago ({formatNumber(ganaderia_resumen[0]?.leche_kg_ue, 0)} kg).

<BarChart
    data={ganaderia}
    x=producto
    y=cuota_pct
    series=posicion
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    yAxisTitle="EB-27ko guztizkoaren %"
    seriesColors={{'1.º de la UE': '#b45309', '2.º o 3.º': '#f59e0b', '4.º o peor': '#94a3b8'}}
    title="Abeltzaintza: Espainiaren kuota EBn (%)"
/>

<LineChart
    data={serie_porcino}
    x=anio
    y=cuota_pct
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="EB-27ko txerri-haragiaren %"
    lineColor='#b45309'
    title="Espainiaren kuota EBko txerri-haragian (hiltegiko hilketa)"
/>

<DataTable data={ganaderia} rows=10>
    <Column id=producto title="Produktua" />
    <Column id=cuota_pct title="Kuota EBn %" fmt='0.0' contentType=bar barColor='#b45309' />
    <Column id=puesto title="Postua" fmt='0' />
    <Column id=valor_hab_espana title="Espainia biz." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="EB biz." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unitatea" />
    <Column id=pais_referencia title="1.a (edo 2.a Espainia lider bada)" />
    <Column id=anio title="Urtea" fmt='0' />
</DataTable>

Ardi-abereak 500.000 ardi baino gehiago dituzten herrialdeek bakarrik argitaratzen dituzte, eta haragia hiltegian hildakoa da (ez du barne hartzen bizirik esportatzen dena).

## Arrantza eta akuikultura

Espainia EBko lehena da **harrapaketetan**, **akuikulturan** (tonatan: {formatNumber(pesca_resumen[0]?.acui, 1)} %, batez ere muskuiluak) eta **flotaren arkeoan** (ahalmenaren {formatNumber(pesca_resumen[0]?.flota_gt, 1)} %). Ontzi kopuruan {pesca_resumen[0]?.flota_nr_puesto}.a da ({formatNumber(pesca_resumen[0]?.buques, 0)} ontzi): haren ontziak batez bestekoa baino handiagoak dira. Akuikulturaren balioan lehena {pesca_resumen[0]?.acui_eur_primero} da, eta Espainiak {formatNumber(pesca_resumen[0]?.acui_eur, 1)} % du.

Harrapaketetan kontuz ibili behar da: hainbat herrialdek utzi diote Eurostaten argitaratzeari ({urtean(pesca_resumen[0]?.capturas_anio)} hauek falta dira: {pesca_resumen[0]?.capturas_sin}). Argitaratzen dutenen gainean, Espainiak {formatNumber(pesca_resumen[0]?.capturas, 1)} % arrantzatu zuen ({formatNumber(pesca_resumen[0]?.capturas_kt, 0)} mila t); falta direnen azken datu ezaguna guztizkoari gehituta, **kuota zuhurra {formatNumber(pesca_resumen[0]?.capturas_min, 1)} %-koa da**, eta hori da erabili beharreko zifra. Biztanleko ({formatNumber(pesca_resumen[0]?.capturas_kg, 1)} kg) Espainia {pesca_hab[0]?.puesto_hab}.a da: lehena {pesca_hab[0]?.primero_hab} da, {formatNumber(pesca_hab[0]?.primero_kg, 0)} kg-rekin.

<LineChart
    data={pesca_serie}
    x=anio
    y=cuota
    series=medida
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="EBko harrapaketen %"
    seriesColors={{'Sobre los países con dato': '#93c5fd', 'Prudente (con el último dato de los que faltan)': '#0369a1'}}
    title="Espainiaren kuota EBko arrantza-harrapaketetan (%)"
/>

<BarChart
    data={pesca_paises}
    x=pais
    y=kg_hab
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="kg biztanleko (pisu bizia)"
    seriesColors={{'España': '#dc2626', 'Otros países': '#93c5fd'}}
    title="Arrantza-harrapaketak biztanleko, datua argitaratzen duten EBko herrialdeak"
/>

<DataTable data={pesca} rows=5>
    <Column id=producto title="Adierazlea" />
    <Column id=cuota_pct title="Kuota EBn %" fmt='0.0' contentType=bar barColor='#0284c7' />
    <Column id=cuota_min_pct title="Kuota zuhurra %" fmt='0.0' />
    <Column id=puesto title="Postua" fmt='0' />
    <Column id=valor_hab_espana title="Espainia biz." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="EB biz." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unitatea" />
    <Column id=paises_sin_dato title="Daturik gabeko herrialdeak" />
    <Column id=anio title="Urtea" fmt='0' />
</DataTable>

## Landak zenbat balio duen

Nekazaritza-adarrak (nekazaritza eta abeltzaintza, arrantzarik eta basogintzarik gabe) **{formatNumber(valor_resumen[0]?.es, 0)} € ekoitzi zituen biztanleko** Espainian {urtean(valor_resumen[0]?.anio)}, EB-27ko {formatNumber(valor_resumen[0]?.ue, 0)} €-ren aldean; balio erantsitik, pentsuak, ongarriak, energia eta gainerako kontsumoak kenduta, {formatNumber(valor_resumen[0]?.es_vab, 0)} € geratzen dira biztanleko (EBn, {formatNumber(valor_resumen[0]?.ue_vab, 0)} €). Hemen alderatzen diren {valor_rank.length} herrialdeen artean, Espainia {valor_rank.filter(d => d.geo === 'ES')[0]?.rk}.a da biztanleko; lehena {valor_rank[0]?.pais} da. Prezioen eraginik gabe (bolumenean), biztanleko ekoizpena 2005etik {#if valor_resumen[0]?.vol_var >= 0}{formatNumber(valor_resumen[0]?.vol_var, 1)} % hazi da{:else}{formatNumber(-valor_resumen[0]?.vol_var, 1)} % jaitsi da{/if}.

<LineChart
    data={valor_paises}
    x=anio
    y=produccion_eur_hab_real_pib
    series=pais
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ biztanleko, gaurko euroak"
    seriesColors={{'España': '#dc2626', 'UE-27': '#0f172a'}}
    title="Nekazaritza-adarraren ekoizpena biztanleko, gaurko euroetan (herrialde bakoitzaren BPGaren deflatorea)"
/>

Lanaldi osoko lan-unitate bakoitzeko **nekazaritza-errenta** (lana, lurra eta kapitala ordaintzeko geratzen dena, 2020ko euroetan inflazioa kenduta) {formatNumber(valor_resumen[0]?.renta_es, 0)} € izan zen Espainian {urtean(valor_resumen[0]?.anio)}, EBko batez besteko {formatNumber(valor_resumen[0]?.renta_ue, 0)} €-ren aldean.

<LineChart
    data={valor_paises}
    x=anio
    y=renta_real_uta_eur2020
    series=pais
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="2020ko € UTA bakoitzeko"
    seriesColors={{'España': '#dc2626', 'UE-27': '#0f172a'}}
    title="Nekazaritza-errenta erreala urteko lan-unitate bakoitzeko (2020ko euroak)"
/>

Produktuka, ekoizpenaren balioak tonen rankinga berresten du: Espainia lehena da oliba-olioan, frutetan eta txerrikietan, eta urrun geratzen da esnean eta nekazaritzako kontuetako ardoan.

<DataTable data={valor_productos} rows=10>
    <Column id=producto title="Ekoizpena" />
    <Column id=cuota_pct title="Kuota EBn %" fmt='0.0' contentType=bar barColor='#16a34a' />
    <Column id=puesto title="Postua" fmt='0' />
    <Column id=valor_hab_espana title="Espainia, € biz." fmt='#,##0' />
    <Column id=valor_hab_ue title="EB, € biz." fmt='#,##0' />
    <Column id=pais_referencia title="1.a (edo 2.a Espainia lider bada)" />
    <Column id=anio title="Urtea" fmt='0' />
</DataTable>

## Erkidegoka eta probintziaka

Lehen sektoreak (nekazaritza, abeltzaintza, basogintza eta arrantza) Espainiako balio erantsiaren {formatNumber(espana_vab[0]?.peso, 1)} % sortu zuen {urtean(espana_vab[0]?.anio)} (2000an, {formatNumber(espana_vab[0]?.peso_2000, 1)} %), {formatNumber(espana_vab[0]?.eur_hab, 0)} € biztanleko. Pisu handiena duen erkidegoak hauek dira: {ccaa_resumen[0]?.mas}; biztanleko gehien ekoizten duena {ccaa_resumen[0]?.max_hab_ccaa} da ({formatNumber(ccaa_resumen[0]?.max_hab, 0)} €). Probintziaka ({provincias_resumen[0]?.anio}), pisu handienekoak hauek dira: {provincias_resumen[0]?.mas}; {provincias_resumen[0]?.mas_10} probintziatan 10 % gainditzen du.

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="peso_vab_pct"
    valueFmt='0.0'
    link="ruta"
    colorPalette={['#f7fee7', '#65a30d', '#1a2e05']}
    height={460}
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'peso_vab_pct', title: 'Balio erantsiaren %', fmt: '0.0'},
        {id: 'vab_primario_eur_hab_real', title: '€ biztanleko (gaurko euroak)', fmt: '#,##0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=peso_vab_pct title="Balio erantsiaren %" fmt='0.0' contentType=bar barColor='#65a30d' />
    <Column id=peso_2000 title="% 2000n" fmt='0.0' />
    <Column id=vab_primario_eur_hab_real title="€ biz. (gaurko euroak)" fmt='#,##0' />
    <Column id=vab_primario_meur title="Milioi € (korronteak)" fmt='#,##0' />
    <Column id=anio title="Urtea" fmt='0' />
</DataTable>

Eurostatek laborantza belarkarak baino ez ditu ematen erkidegoka. **Zerealetan**, hauek biltzen dute {urteko(cereales_resumen[0]?.anio)} Espainiako uztaren {formatNumber(cereales_resumen[0]?.top3, 1)} %: {cereales_resumen[0]?.lista}.

<BarChart
    data={cereales_ccaa}
    x=ccaa
    y=kg_hab
    swapXY=true
    yFmt='#,##0'
    yAxisTitle="kg biztanleko"
    fillColor='#ca8a04'
    title="Zereal-uzta biztanleko eta erkidegoka (guztizkoaren gutxienez 0,5 % duten erkidegoak)"
/>

## Metodologia eta iturriak

- **Laboreen ekoizpena**: [Eurostat apro_cpsh1](https://ec.europa.eu/eurostat/databrowser/view/apro_cpsh1/default/table) (EBko hezetasunean bildutako ekoizpena eta azalera) eta, erkidegoka, [apro_cpshr](https://ec.europa.eu/eurostat/databrowser/view/apro_cpshr/default/table).
- **Abeltzaintza**: [apro_mt_pann](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_pann/default/table) (hiltegian hildako haragia, kanal-pisua), [apro_mt_lspig](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_lspig/default/table), [apro_mt_lssheep](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_lssheep/default/table) eta [apro_mt_lscatl](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_lscatl/default/table) (azaro-abenduko abere-buruak) eta [apro_mk_cola](https://ec.europa.eu/eurostat/databrowser/view/apro_mk_cola/default/table) (esnetegietara entregatutako esnea).
- **Arrantza**: [fish_ca_main](https://ec.europa.eu/eurostat/databrowser/view/fish_ca_main/default/table) (harrapaketak pisu bizian), [fish_aq2a](https://ec.europa.eu/eurostat/databrowser/view/fish_aq2a/default/table) (akuikultura) eta [fish_fleet_alt](https://ec.europa.eu/eurostat/databrowser/view/fish_fleet_alt/default/table) (flota abenduaren 31n). Irlandak, Letoniak eta Portugalek ez dituzte harrapaketak argitaratzen azken urteetan: kuota zuhurrak haien azken datu ezaguna gehitzen dio guztizkoari.
- **Ekoizpenaren balioa eta nekazaritza-errenta**: Eurostaten nekazaritzaren kontu ekonomikoak, [aact_eaa01](https://ec.europa.eu/eurostat/databrowser/view/aact_eaa01/default/table) (oinarrizko prezioetan), [aact_eaa04](https://ec.europa.eu/eurostat/databrowser/view/aact_eaa04/default/table) (bolumena) eta [aact_eaa06](https://ec.europa.eu/eurostat/databrowser/view/aact_eaa06/default/table) (errenta erreala UTA bakoitzeko). Gaurko euroak: Espainia INEren KPIarekin; herrialdeak alderatzeko, guztiak beren BPGaren deflatorearekin ([nama_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/nama_10_gdp/default/table)).
- **Esportazioak**: [Eurostat Comext](https://ec.europa.eu/eurostat/comext/newxtweb/) (DS-045409), helmuga guztietara, EB barruko merkataritza barne.
- **Erkidegoka eta probintziaka**: A adarraren balio erantsi gordina, [Eurostat nama_10r_3gva](https://ec.europa.eu/eurostat/databrowser/view/nama_10r_3gva/default/table), INEren Eskualdeko Kontabilitatea islatzen duena. Biztanleria INErena eta Eurostatena ([nama_10_pe](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe/default/table)).
- **Oliba-olioa**: kanpainako ekoizpena eta jatorriko prezioak, Europako Batzordearena, [Agri-food data portal](https://agridata.ec.europa.eu/extensions/DataPortal/olive-oil.html) (azken kanpaina estimazio bat da; hilabeteko prezioa herrialdeko merkatuen asteko kotizazioen batez bestekoa da, gaurko euroetan Espainiako KPIarekin). Munduko ekoizpena: [Nazioarteko Oliba Kontseilua, Olive sector statistics (2025eko abendua)](https://www.internationaloliveoil.org/olive-sector-statistics-december-2025-and-forecasts/), iturria aipatuta emandako zifrak.
- **Ardoa eta mahastia munduan**: [OIV, State of the World Wine Sector in 2025](https://www.oiv.int/sites/default/files/2026-05/OIV-State_of_the_World_Wine_Sector_in_2025.pdf) (2026ko maiatza), iturria aipatuta emandako zifrak.
- **Kuotak**: Espainia datua duten 27 herrialdeen baturaren gainean, ia guztien datuak dituen azken urtean (gutxienez 97 %-ko estaldura). «Biztanleria-pisuaren aldiz» = Espainiaren kuota / Espainiak EB-27ko biztanlerian duen pisua.
