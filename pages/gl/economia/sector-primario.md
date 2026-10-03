---
title: Sector primario
description: "Onde é potencia España no campo e no mar: cota na UE e posto en aceite de oliva, cítricos, froitas e hortalizas, viño, porcino, ovino, pesca e acuicultura, valor da produción agraria por habitante en euros reais e peso do sector primario por comunidade e provincia."
i18n_origen: 68bd98eb8470
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
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
       CASE WHEN a.geo = 'ES' THEN 'España' ELSE 'Otros países' END AS grupo
FROM mother.primario_paises_largo a
JOIN mother.primario_paises_largo b
  ON b.geo = a.geo AND b.anio = a.anio AND b.producto_id = 'HS_2204_t'
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
FROM mother.primario_pesca WHERE geo = 'ES' AND medida = 'capturas' AND anio >= 2010
UNION ALL
SELECT CAST(anio AS INTEGER), 'Prudente (con el último dato de los que faltan)', cuota_min_pct
FROM mother.primario_pesca WHERE geo = 'ES' AND medida = 'capturas' AND anio >= 2010
ORDER BY anio, medida
```

```sql pesca_paises
SELECT pais, kg_hab, valor, CASE WHEN geo = 'ES' THEN 'España' ELSE 'Otros países' END AS grupo
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
       c.vab_primario_eur_hab_real, '/gl' || t.ruta AS ruta
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
       c.vab_primario_eur_hab_real, c.vab_primario_meur, c0.peso_vab_pct AS peso_2000, '/gl' || t.ruta AS ruta
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

# 🌾 Sector primario

Agricultura, gandaría e pesca: en que é España **a primeira da Unión Europea** e en que non. Cada produto mídese pola súa **cota no total dos 27** e compárase co peso de España na poboación da UE ({formatNumber(ranking_resumen[0]?.peso_pob, 1)} %): unha cota do 50 % é {formatNumber(50 / ranking_resumen[0]?.peso_pob, 1)} veces «o que lle tocaría» por habitantes. Os valores en euros van **por habitante e descontada a inflación**.

<Grid cols=4>
    <KpiCard
        title="Aceite de oliva: cota na UE"
        value={aceite_kpi[0]?.cuota_ue}
        formattedValue="{formatNumber(aceite_kpi[0]?.cuota_ue, 1)} %"
        period="campaña {aceite_kpi[0]?.campania} · {formatNumber(aceite_kpi[0]?.cuota_mundo, 1)} % do mundo (COI) · {formatNumber(aceite_kpi[0]?.prod_kt, 0)} miles de t"
        direction="neutral"
        source="Comisión Europea · COI"
        sparklineData={aceite_es.map(d => d.cuota_ue_pct)}
    />
    <KpiCard
        title="Cítricos: cota na UE"
        value={kpi[0]?.citricos}
        formattedValue="{formatNumber(kpi[0]?.citricos, 1)} %"
        period="{kpi[0]?.citricos_anio} · 1.ª da UE · {formatNumber(kpi[0]?.citricos_kt, 0)} miles de t"
        direction="neutral"
        source="Eurostat (apro_cpsh1)"
        sparklineData={serie_citricos.map(d => d.cuota_pct)}
    />
    <KpiCard
        title="Carne de porcino: cota na UE"
        value={kpi[0]?.porcino}
        formattedValue="{formatNumber(kpi[0]?.porcino, 1)} %"
        period="{kpi[0]?.porcino_anio} · 1.ª da UE · {formatNumber(kpi[0]?.porcino_kg_hab, 0)} kg por habitante (UE: {formatNumber(kpi[0]?.porcino_kg_hab_ue, 0)})"
        change={porcino_cambio[0]?.dif_pp?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs {porcino_cambio[0]?.anio_ini}"
        direction="neutral"
        source="Eurostat (apro_mt_pann)"
        sparklineData={serie_porcino.map(d => d.cuota_pct)}
    />
    <KpiCard
        title="Produción agraria por habitante"
        value={valor_resumen[0]?.es}
        formattedValue="{formatNumber(valor_resumen[0]?.es, 0)} €"
        period="{valor_resumen[0]?.anio}, euros de hoxe · UE-27: {formatNumber(valor_resumen[0]?.ue, 0)} € · {formatNumber(valor_resumen[0]?.es_meur, 0)} millóns de € en total"
        direction="positive-up"
        source="Eurostat (aact_eaa01)"
        sparklineData={valor_es.map(d => d.produccion_eur_hab_real)}
    />
</Grid>

## Onde España é primeira da UE

Dos {ranking_resumen[0]?.total} indicadores de produción, superficie, cabana, pesca e exportación que se comparan aquí, España é **a primeira da UE en {ranking_resumen[0]?.primeros}** e está entre as tres primeiras en {ranking_resumen[0]?.podio}: é 1.ª en {ranking_resumen[0]?.prim_cultivo} de {ranking_resumen[0]?.n_cultivo} indicadores de cultivos, {ranking_resumen[0]?.prim_ganaderia} de {ranking_resumen[0]?.n_ganaderia} de gandaría, {ranking_resumen[0]?.prim_pesca} de {ranking_resumen[0]?.n_pesca} de pesca e acuicultura e {ranking_resumen[0]?.prim_export} de {ranking_resumen[0]?.n_export} de exportación. As cotas máis altas en produción son as de {ranking_top[0]?.lista}. En {ranking_resumen[0]?.doble_peso} indicadores a cota de España é polo menos o dobre do seu peso en poboación.

<BarChart
    data={ranking_primeros}
    x=producto
    y=cuota_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0"%"'
    yAxisTitle="% do total da UE-27"
    seriesColors={{'Cultivos': '#16a34a', 'Ganadería': '#b45309', 'Pesca y acuicultura': '#0284c7', 'Exportaciones': '#7c3aed'}}
    title="Indicadores nos que España é a primeira da UE: cota no total dos 27 (%)"
/>

A táboa completa, co posto e «veces o seu peso en poboación» (cota de España dividida entre o seu peso na poboación da UE; 1 é o que lle tocaría por habitantes). O ano é o último con datos de case todos os países; a última columna dá o primeiro país, ou o segundo cando España é a primeira.

<DataTable data={ranking_productos} rows=20 search=true groupBy=grupo groupsOpen=true>
    <Column id=producto title="Produto" />
    <Column id=cuota_pct title="Cota na UE %" fmt='0.0' contentType=bar barColor='#16a34a' />
    <Column id=puesto title="Posto" fmt='0' />
    <Column id=veces_peso_poblacion title="Veces o seu peso en poboación" fmt='0.0' />
    <Column id=valor_hab_espana title="España por hab." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="UE por hab." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unidade" />
    <Column id=pais_referencia title="1.º (ou 2.º se lidera España)" />
    <Column id=anio title="Ano" fmt='0' />
</DataTable>

Onde España queda lonxe dos primeiros postos (cultivos e gandaría, do peor ao mellor): {ranking_flojos[0]?.lista}.

## A horta de Europa

España produce o {formatNumber(huerta_resumen[0]?.hortalizas, 1)} % das hortalizas frescas (con melón e amorodo) da UE, {formatNumber(huerta_resumen[0]?.hortalizas_kg, 0)} kg por habitante fronte a {formatNumber(huerta_resumen[0]?.hortalizas_kg_ue, 0)} de media na UE, e o {formatNumber(huerta_resumen[0]?.valor_frutas, 1)} % do valor da froita (con cítricos, uva e oliva). En exportacións de {huerta_resumen[0]?.anio_exp} é a {huerta_resumen[0]?.exp_hortalizas_puesto}.ª en hortalizas ({formatNumber(huerta_resumen[0]?.exp_hortalizas, 1)} % do que exportan os 27, incluído o que se venden entre eles) e a {huerta_resumen[0]?.exp_frutas_puesto}.ª en froitas e froitos secos ({formatNumber(huerta_resumen[0]?.exp_frutas, 1)} %); en cítricos chega ao {formatNumber(huerta_resumen[0]?.exp_citricos, 1)} %. En tomate o primeiro produtor é {huerta_resumen[0]?.tomate_primero}: España ten o {formatNumber(huerta_resumen[0]?.tomate, 1)} %.

<LineChart
    data={huerta_serie}
    x=anio
    y=cuota_pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% do total da UE-27"
    title="Cota de España na UE: froitas e hortalizas (só anos cos 27 países)"
/>

<DataTable data={huerta} rows=30 search=true groupBy=grupo groupsOpen=true>
    <Column id=producto title="Produto" />
    <Column id=cuota_pct title="Cota na UE %" fmt='0.0' contentType=bar barColor='#16a34a' />
    <Column id=puesto title="Posto" fmt='0' />
    <Column id=veces_peso_poblacion title="Veces o seu peso en poboación" fmt='0.0' />
    <Column id=valor_hab_espana title="España por hab." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="UE por hab." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unidade" />
    <Column id=pais_referencia title="1.º (ou 2.º se lidera España)" />
</DataTable>

Nas exportacións, os Países Baixos saen inflados porque reexportan desde Róterdam o que importan de fóra; e todas as cifras inclúen o comercio dentro da UE.

## Aceite de oliva

Segundo a Comisión Europea, na campaña {aceite_kpi[0]?.campania} (outubro a setembro) España produciu **{formatNumber(aceite_kpi[0]?.prod_kt, 0)} miles de toneladas**, o {formatNumber(aceite_kpi[0]?.cuota_ue, 1)} % do aceite da UE e {formatNumber(aceite_kpi[0]?.kg_hab, 1)} kg por habitante. Desde {aceite_kpi[0]?.desde} a súa cota media é do {formatNumber(aceite_kpi[0]?.cuota_media, 1)} %; a máis baixa foi a de {aceite_kpi[0]?.campania_min} ({formatNumber(aceite_kpi[0]?.cuota_min, 1)} %), con {formatNumber(aceite_kpi[0]?.prod_min, 0)} miles de toneladas, e o máximo de produción, {formatNumber(aceite_kpi[0]?.prod_max, 0)}, acadouse en {aceite_kpi[0]?.campania_max}.

{#if aceite_kpi[0]?.ultima_estimada}
<p>A campaña {aceite_kpi[0]?.campania_est} é aínda <strong>unha estimación</strong>: {formatNumber(aceite_kpi[0]?.prod_kt_est, 0)} miles de toneladas, o {formatNumber(aceite_kpi[0]?.cuota_ue_est, 1)} % da UE e o {formatNumber(aceite_kpi[0]?.cuota_mundo_est, 1)} % da previsión mundial do COI.</p>
{/if}

<BarChart
    data={aceite_grupos}
    x=campania
    y=cuota_ue_pct
    series=grupo
    type=stacked
    sort=false
    yFmt='0"%"'
    yAxisTitle="% da produción da UE"
    seriesColors={{'España': '#dc2626', 'Italia': '#16a34a', 'Grecia': '#2563eb', 'Portugal': '#f59e0b', 'Resto de la UE': '#94a3b8'}}
    title="Produción de aceite de oliva da UE por país, % de cada campaña (a última, estimada)"
/>

Fóra da UE, o Consello Oleícola Internacional (COI) dá para {aceite_mundo[0]?.campania} unha produción mundial de {formatNumber(aceite_mundo[0]?.mundo, 0)} miles de toneladas: España, con {formatNumber(aceite_mundo[0]?.espana, 0)}, foi a primeira e produciu {formatNumber(aceite_mundo[0]?.veces_segundo, 1)} veces o da segunda, {aceite_mundo[0]?.pais_segundo}. España é tamén a primeira exportadora da UE: o {formatNumber(aceite_export[0]?.cuota_pct, 1)} % do aceite que venden os 27 en volume e o {formatNumber(aceite_export[1]?.cuota_pct, 1)} % en euros.

O prezo en orixe do **virxe extra** nos mercados españois, en euros de {precio_resumen[0]?.mes_base}, tocou teito en {precio_resumen[0]?.mes_maximo} con {formatNumber(precio_resumen[0]?.maximo, 2)} €/kg; en {precio_resumen[0]?.mes_ultimo} estaba en {formatNumber(precio_resumen[0]?.ultimo, 2)} €/kg, fronte a unha media de {formatNumber(precio_resumen[0]?.media_2015_2019, 2)} €/kg de hoxe entre 2015 e 2019.

<LineChart
    data={aceite_precios}
    x=mes
    y=eur_kg_real
    series=pais
    yFmt='0.00" €"'
    yAxisTitle="€/kg en euros de hoxe"
    seriesColors={{'España': '#dc2626', 'Italia': '#16a34a', 'Grecia': '#2563eb'}}
    title="Prezo en orixe do aceite de oliva virxe extra, €/kg descontada a inflación (media mensual dos mercados)"
/>

## Viño

España ten **o maior viñedo do mundo**: {formatNumber(vino_mundo[0]?.vinedo_es, 0)} miles de hectáreas en {vino_mundo[0]?.anio}, o {formatNumber(vino_mundo[0]?.vinedo_pct, 1)} % do total mundial segundo a OIV. En viño é a {vino_mundo[0]?.vino_puesto}.ª produtora do mundo ({formatNumber(vino_mundo[0]?.vino_es, 1)} millóns de hectolitros, o {formatNumber(vino_mundo[0]?.vino_pct, 1)} %) e a {vino_mundo[0]?.exp_vol_puesto}.ª exportadora en volume ({formatNumber(vino_mundo[0]?.exp_vol_es, 1)} millóns de hectolitros); en valor exporta {formatNumber(vino_mundo[0]?.exp_val_es, 1)} miles de millóns de euros, fronte a {formatNumber(vino_mundo[0]?.exp_val_fr, 1)} de Francia e {formatNumber(vino_mundo[0]?.exp_val_it, 1)} de Italia.

A diferenza está no prezo: en {vino_precio_resumen[0]?.anio} o viño que exportou España saíu a {formatNumber(vino_precio_resumen[0]?.es, 2)} € por quilo (case o mesmo que por litro), fronte a {formatNumber(vino_precio_resumen[0]?.it, 2)} € o italiano e {formatNumber(vino_precio_resumen[0]?.fr, 2)} € o francés.

<BarChart
    data={vino}
    x=producto
    y=cuota_pct
    swapXY=true
    sort=false
    yFmt='0"%"'
    yAxisTitle="% do total da UE-27"
    fillColor='#7c2d12'
    title="Viño: cota de España na UE segundo que se mida (%)"
/>

<BarChart
    data={vino_precio}
    x=pais
    y=eur_kg
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.00" €"'
    yAxisTitle="€ por kg exportado"
    seriesColors={{'España': '#dc2626', 'Otros países': '#93c5fd'}}
    title="Prezo medio do viño exportado (países que exportan máis de 100.000 t), € por kg"
/>

**Ollo coas contas agrarias:** o «valor do viño» de Eurostat deixa a España nun {formatNumber(vino[4]?.cuota_pct, 1)} % da UE porque só conta o viño que elaboran as propias explotacións; en España a maior parte fano adegas e cooperativas fóra da rama agraria e contabilízase como uva vendida. Para comparar viño é mellor a OIV ou o viñedo.

## Gandaría

España é a primeira da UE en **carne de porcino** ({formatNumber(kpi[0]?.porcino, 1)} %, por diante de {kpi[0]?.porcino_segundo}) e en **carne de ovino** ({formatNumber(ganaderia_resumen[0]?.ovino, 1)} %). Ten {formatNumber(ganaderia_resumen[0]?.cerdos_1000, 0)} porcos por cada 1.000 habitantes, fronte a {formatNumber(ganaderia_resumen[0]?.cerdos_1000_ue, 0)} na UE. A súa cota en porcino pasou do {formatNumber(porcino_cambio[0]?.cuota_ini, 1)} % en {porcino_cambio[0]?.anio_ini} ao {formatNumber(porcino_cambio[0]?.cuota_fin, 1)} %. En aves é a {ganaderia_resumen[0]?.aves_puesto}.ª ({formatNumber(ganaderia_resumen[0]?.aves, 1)} %, tras {ganaderia_resumen[0]?.aves_primero}) e en bovino a {ganaderia_resumen[0]?.bovino_puesto}.ª ({formatNumber(ganaderia_resumen[0]?.bovino, 1)} %). O punto débil é **o leite**: é a {ganaderia_resumen[0]?.leche_puesto}.ª, co {formatNumber(ganaderia_resumen[0]?.leche, 1)} % da UE e {formatNumber(ganaderia_resumen[0]?.leche_kg, 0)} kg de leite de vaca entregado por habitante, menos da metade da media ({formatNumber(ganaderia_resumen[0]?.leche_kg_ue, 0)} kg).

<BarChart
    data={ganaderia}
    x=producto
    y=cuota_pct
    series=posicion
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    yAxisTitle="% do total da UE-27"
    seriesColors={{'1.º de la UE': '#b45309', '2.º o 3.º': '#f59e0b', '4.º o peor': '#94a3b8'}}
    title="Gandaría: cota de España na UE (%)"
/>

<LineChart
    data={serie_porcino}
    x=anio
    y=cuota_pct
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% da carne de porcino da UE-27"
    lineColor='#b45309'
    title="Cota de España na carne de porcino da UE (sacrificio en matadoiro)"
/>

<DataTable data={ganaderia} rows=10>
    <Column id=producto title="Produto" />
    <Column id=cuota_pct title="Cota na UE %" fmt='0.0' contentType=bar barColor='#b45309' />
    <Column id=puesto title="Posto" fmt='0' />
    <Column id=valor_hab_espana title="España por hab." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="UE por hab." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unidade" />
    <Column id=pais_referencia title="1.º (ou 2.º se lidera España)" />
    <Column id=anio title="Ano" fmt='0' />
</DataTable>

A cabana ovina só a publican os países con máis de 500.000 ovellas, e a carne é a sacrificada en matadoiro (non inclúe a que se exporta en vivo).

## Pesca e acuicultura

España é a primeira da UE en **capturas**, en **acuicultura** (en toneladas: o {formatNumber(pesca_resumen[0]?.acui, 1)} %, sobre todo mexillón) e en **arqueo da frota** ({formatNumber(pesca_resumen[0]?.flota_gt, 1)} % da capacidade). En número de barcos é a {pesca_resumen[0]?.flota_nr_puesto}.ª ({formatNumber(pesca_resumen[0]?.buques, 0)} buques): os seus barcos son máis grandes que a media. En valor da acuicultura a primeira é {pesca_resumen[0]?.acui_eur_primero} e España ten o {formatNumber(pesca_resumen[0]?.acui_eur, 1)} %.

Nas capturas hai que ter coidado: varios países deixaron de publicar en Eurostat (en {pesca_resumen[0]?.capturas_anio} faltan {pesca_resumen[0]?.capturas_sin}). Sobre os que publican, España pescou o {formatNumber(pesca_resumen[0]?.capturas, 1)} % ({formatNumber(pesca_resumen[0]?.capturas_kt, 0)} miles de t); sumando ao total o último dato coñecido dos que faltan, a **cota prudente é do {formatNumber(pesca_resumen[0]?.capturas_min, 1)} %**, que é a cifra que convén usar. Por habitante ({formatNumber(pesca_resumen[0]?.capturas_kg, 1)} kg) España é a {pesca_hab[0]?.puesto_hab}.ª: a primeira é {pesca_hab[0]?.primero_hab}, con {formatNumber(pesca_hab[0]?.primero_kg, 0)} kg.

<LineChart
    data={pesca_serie}
    x=anio
    y=cuota
    series=medida
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% das capturas da UE"
    seriesColors={{'Sobre los países con dato': '#93c5fd', 'Prudente (con el último dato de los que faltan)': '#0369a1'}}
    title="Cota de España nas capturas de pesca da UE (%)"
/>

<BarChart
    data={pesca_paises}
    x=pais
    y=kg_hab
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="kg por habitante (peso vivo)"
    seriesColors={{'España': '#dc2626', 'Otros países': '#93c5fd'}}
    title="Capturas de pesca por habitante, países da UE que publican o dato"
/>

<DataTable data={pesca} rows=5>
    <Column id=producto title="Indicador" />
    <Column id=cuota_pct title="Cota na UE %" fmt='0.0' contentType=bar barColor='#0284c7' />
    <Column id=cuota_min_pct title="Cota prudente %" fmt='0.0' />
    <Column id=puesto title="Posto" fmt='0' />
    <Column id=valor_hab_espana title="España por hab." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="UE por hab." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unidade" />
    <Column id=paises_sin_dato title="Países sen dato" />
    <Column id=anio title="Ano" fmt='0' />
</DataTable>

## O que vale o campo

A rama agraria (agricultura e gandaría, sen pesca nin silvicultura) produciu en {valor_resumen[0]?.anio} **{formatNumber(valor_resumen[0]?.es, 0)} € por habitante** en España, fronte a {formatNumber(valor_resumen[0]?.ue, 0)} € na UE-27; de valor engadido, unha vez restados pensos, fertilizantes, enerxía e demais consumos, quedan {formatNumber(valor_resumen[0]?.es_vab, 0)} € por habitante ({formatNumber(valor_resumen[0]?.ue_vab, 0)} € na UE). Entre os {valor_rank.length} países que se comparan aquí, España é a {valor_rank.filter(d => d.geo === 'ES')[0]?.rk}.ª por habitante; a primeira é {valor_rank[0]?.pais}. Sen o efecto dos prezos (en volume), a produción por habitante {#if valor_resumen[0]?.vol_var >= 0}medrou un {formatNumber(valor_resumen[0]?.vol_var, 1)} %{:else}baixou un {formatNumber(-valor_resumen[0]?.vol_var, 1)} %{/if} desde 2005.

<LineChart
    data={valor_paises}
    x=anio
    y=produccion_eur_hab_real_pib
    series=pais
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ por habitante, euros de hoxe"
    seriesColors={{'España': '#dc2626', 'UE-27': '#0f172a'}}
    title="Produción da rama agraria por habitante, en euros de hoxe (deflactor do PIB de cada país)"
/>

A **renda agraria** por unidade de traballo a tempo completo (o que queda para remunerar o traballo, a terra e o capital, en euros de 2020 descontada a inflación) foi en España de {formatNumber(valor_resumen[0]?.renta_es, 0)} € en {valor_resumen[0]?.anio}, fronte a {formatNumber(valor_resumen[0]?.renta_ue, 0)} € de media na UE.

<LineChart
    data={valor_paises}
    x=anio
    y=renta_real_uta_eur2020
    series=pais
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ de 2020 por UTA"
    seriesColors={{'España': '#dc2626', 'UE-27': '#0f172a'}}
    title="Renda agraria real por unidade de traballo-ano (euros de 2020)"
/>

Por produtos, o valor da produción confirma o ranking en toneladas: España é a primeira en aceite de oliva, froitas e porcino, e queda lonxe en leite e no viño das contas agrarias.

<DataTable data={valor_productos} rows=10>
    <Column id=producto title="Produción" />
    <Column id=cuota_pct title="Cota na UE %" fmt='0.0' contentType=bar barColor='#16a34a' />
    <Column id=puesto title="Posto" fmt='0' />
    <Column id=valor_hab_espana title="España, € por hab." fmt='#,##0' />
    <Column id=valor_hab_ue title="UE, € por hab." fmt='#,##0' />
    <Column id=pais_referencia title="1.º (ou 2.º se lidera España)" />
    <Column id=anio title="Ano" fmt='0' />
</DataTable>

## Por comunidade e provincia

O sector primario (agricultura, gandaría, silvicultura e pesca) xerou en {espana_vab[0]?.anio} o {formatNumber(espana_vab[0]?.peso, 1)} % do valor engadido de España ({formatNumber(espana_vab[0]?.peso_2000, 1)} % en 2000), {formatNumber(espana_vab[0]?.eur_hab, 0)} € por habitante. As comunidades onde máis pesa son {ccaa_resumen[0]?.mas}; en {ccaa_resumen[0]?.max_hab_ccaa} é onde máis produce por habitante ({formatNumber(ccaa_resumen[0]?.max_hab, 0)} €). Por provincia ({provincias_resumen[0]?.anio}), as de máis peso son {provincias_resumen[0]?.mas}; en {provincias_resumen[0]?.mas_10} provincias supera o 10 %.

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
        {id: 'peso_vab_pct', title: '% do valor engadido', fmt: '0.0'},
        {id: 'vab_primario_eur_hab_real', title: '€ por habitante (euros de hoxe)', fmt: '#,##0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidade" />
    <Column id=peso_vab_pct title="% do valor engadido" fmt='0.0' contentType=bar barColor='#65a30d' />
    <Column id=peso_2000 title="% en 2000" fmt='0.0' />
    <Column id=vab_primario_eur_hab_real title="€ por hab. (euros de hoxe)" fmt='#,##0' />
    <Column id=vab_primario_meur title="Millóns de € (correntes)" fmt='#,##0' />
    <Column id=anio title="Ano" fmt='0' />
</DataTable>

Eurostat só dá por comunidade os cultivos herbáceos. En **cereais**, {cereales_resumen[0]?.lista} reúnen o {formatNumber(cereales_resumen[0]?.top3, 1)} % da colleita española de {cereales_resumen[0]?.anio}:

<BarChart
    data={cereales_ccaa}
    x=ccaa
    y=kg_hab
    swapXY=true
    yFmt='#,##0'
    yAxisTitle="kg por habitante"
    fillColor='#ca8a04'
    title="Colleita de cereais por habitante e comunidade (comunidades con polo menos o 0,5 % do total)"
/>

## Metodoloxía e fontes

- **Produción de cultivos**: [Eurostat apro_cpsh1](https://ec.europa.eu/eurostat/databrowser/view/apro_cpsh1/default/table) (produción colleitada a humidade UE e superficie) e, por comunidade, [apro_cpshr](https://ec.europa.eu/eurostat/databrowser/view/apro_cpshr/default/table).
- **Gandaría**: [apro_mt_pann](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_pann/default/table) (carne sacrificada en matadoiro, peso en canal), [apro_mt_lspig](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_lspig/default/table), [apro_mt_lssheep](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_lssheep/default/table) e [apro_mt_lscatl](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_lscatl/default/table) (cabana de novembro-decembro) e [apro_mk_cola](https://ec.europa.eu/eurostat/databrowser/view/apro_mk_cola/default/table) (leite entregado ás centrais).
- **Pesca**: [fish_ca_main](https://ec.europa.eu/eurostat/databrowser/view/fish_ca_main/default/table) (capturas en peso vivo), [fish_aq2a](https://ec.europa.eu/eurostat/databrowser/view/fish_aq2a/default/table) (acuicultura) e [fish_fleet_alt](https://ec.europa.eu/eurostat/databrowser/view/fish_fleet_alt/default/table) (frota a 31 de decembro). Irlanda, Letonia e Portugal non publican capturas nos últimos anos: a cota prudente suma ao total o seu último dato coñecido.
- **Valor da produción e renda agraria**: contas económicas da agricultura de Eurostat, [aact_eaa01](https://ec.europa.eu/eurostat/databrowser/view/aact_eaa01/default/table) (a prezos básicos), [aact_eaa04](https://ec.europa.eu/eurostat/databrowser/view/aact_eaa04/default/table) (volume) e [aact_eaa06](https://ec.europa.eu/eurostat/databrowser/view/aact_eaa06/default/table) (renda real por UTA). Euros de hoxe: España co IPC do INE; para comparar países, todos co seu deflactor do PIB ([nama_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/nama_10_gdp/default/table)).
- **Exportacións**: [Eurostat Comext](https://ec.europa.eu/eurostat/comext/newxtweb/) (DS-045409), a todos os destinos, incluído o comercio dentro da UE.
- **Por comunidade e provincia**: valor engadido bruto da rama A, [Eurostat nama_10r_3gva](https://ec.europa.eu/eurostat/databrowser/view/nama_10r_3gva/default/table), que reproduce a Contabilidade Rexional do INE. Poboación do INE e de Eurostat ([nama_10_pe](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe/default/table)).
- **Aceite de oliva**: produción por campaña e prezos en orixe da Comisión Europea, [Agri-food data portal](https://agridata.ec.europa.eu/extensions/DataPortal/olive-oil.html) (a última campaña é unha estimación; o prezo do mes é a media das cotizacións semanais dos mercados do país, en euros de hoxe co IPC de España). Produción mundial: [Consello Oleícola Internacional, Olive sector statistics (decembro de 2025)](https://www.internationaloliveoil.org/olive-sector-statistics-december-2025-and-forecasts/), cifras citadas con fonte.
- **Viño e viñedo no mundo**: [OIV, State of the World Wine Sector in 2025](https://www.oiv.int/sites/default/files/2026-05/OIV-State_of_the_World_Wine_Sector_in_2025.pdf) (maio de 2026), cifras citadas con fonte.
- **Cotas**: España sobre a suma dos 27 países con dato, no último ano con datos de case todos (cobertura de polo menos o 97 %). «Veces o seu peso en poboación» = cota de España / peso de España na poboación da UE-27.
