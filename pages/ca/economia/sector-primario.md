---
title: Sector primari
description: "On és una potència Espanya al camp i al mar: quota a la UE i lloc en oli d'oliva, cítrics, fruites i hortalisses, vi, porcí, oví, pesca i aqüicultura, valor de la producció agrària per habitant en euros reals i pes del sector primari per comunitat i província."
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
       c.vab_primario_eur_hab_real, '/ca' || t.ruta AS ruta
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
       c.vab_primario_eur_hab_real, c.vab_primario_meur, c0.peso_vab_pct AS peso_2000, '/ca' || t.ruta AS ruta
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

# 🌾 Sector primari

Agricultura, ramaderia i pesca: en què és Espanya **la primera de la Unió Europea** i en què no. Cada producte es mesura per la seva **quota en el total dels 27** i es compara amb el pes d'Espanya en la població de la UE ({formatNumber(ranking_resumen[0]?.peso_pob, 1)} %): una quota del 50 % és {formatNumber(50 / ranking_resumen[0]?.peso_pob, 1)} vegades «el que li tocaria» per habitants. Els valors en euros van **per habitant i descomptada la inflació**.

<Grid cols=4>
    <KpiCard
        title="Oli d'oliva: quota a la UE"
        value={aceite_kpi[0]?.cuota_ue}
        formattedValue="{formatNumber(aceite_kpi[0]?.cuota_ue, 1)} %"
        period="campanya {aceite_kpi[0]?.campania} · {formatNumber(aceite_kpi[0]?.cuota_mundo, 1)} % del món (COI) · {formatNumber(aceite_kpi[0]?.prod_kt, 0)} milers de t"
        direction="neutral"
        source="Comissió Europea · COI"
        sparklineData={aceite_es.map(d => d.cuota_ue_pct)}
    />
    <KpiCard
        title="Cítrics: quota a la UE"
        value={kpi[0]?.citricos}
        formattedValue="{formatNumber(kpi[0]?.citricos, 1)} %"
        period="{kpi[0]?.citricos_anio} · 1a de la UE · {formatNumber(kpi[0]?.citricos_kt, 0)} milers de t"
        direction="neutral"
        source="Eurostat (apro_cpsh1)"
        sparklineData={serie_citricos.map(d => d.cuota_pct)}
    />
    <KpiCard
        title="Carn de porcí: quota a la UE"
        value={kpi[0]?.porcino}
        formattedValue="{formatNumber(kpi[0]?.porcino, 1)} %"
        period="{kpi[0]?.porcino_anio} · 1a de la UE · {formatNumber(kpi[0]?.porcino_kg_hab, 0)} kg per habitant (UE: {formatNumber(kpi[0]?.porcino_kg_hab_ue, 0)})"
        change={porcino_cambio[0]?.dif_pp?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs {porcino_cambio[0]?.anio_ini}"
        direction="neutral"
        source="Eurostat (apro_mt_pann)"
        sparklineData={serie_porcino.map(d => d.cuota_pct)}
    />
    <KpiCard
        title="Producció agrària per habitant"
        value={valor_resumen[0]?.es}
        formattedValue="{formatNumber(valor_resumen[0]?.es, 0)} €"
        period="{valor_resumen[0]?.anio}, euros d'avui · UE-27: {formatNumber(valor_resumen[0]?.ue, 0)} € · {formatNumber(valor_resumen[0]?.es_meur, 0)} milions de € en total"
        direction="positive-up"
        source="Eurostat (aact_eaa01)"
        sparklineData={valor_es.map(d => d.produccion_eur_hab_real)}
    />
</Grid>

## On Espanya és la primera de la UE

Dels {ranking_resumen[0]?.total} indicadors de producció, superfície, cabana, pesca i exportació que es comparen aquí, Espanya és **la primera de la UE en {ranking_resumen[0]?.primeros}** i està entre les tres primeres en {ranking_resumen[0]?.podio}: és la 1a en {ranking_resumen[0]?.prim_cultivo} de {ranking_resumen[0]?.n_cultivo} indicadors de conreus, {ranking_resumen[0]?.prim_ganaderia} de {ranking_resumen[0]?.n_ganaderia} de ramaderia, {ranking_resumen[0]?.prim_pesca} de {ranking_resumen[0]?.n_pesca} de pesca i aqüicultura i {ranking_resumen[0]?.prim_export} de {ranking_resumen[0]?.n_export} d'exportació. Les quotes més altes en producció són les de {ranking_top[0]?.lista}. En {ranking_resumen[0]?.doble_peso} indicadors la quota d'Espanya és almenys el doble del seu pes en població.

<BarChart
    data={ranking_primeros}
    x=producto
    y=cuota_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0"%"'
    yAxisTitle="% del total de la UE-27"
    seriesColors={{'Cultivos': '#16a34a', 'Ganadería': '#b45309', 'Pesca y acuicultura': '#0284c7', 'Exportaciones': '#7c3aed'}}
    title="Indicadors en què Espanya és la primera de la UE: quota en el total dels 27 (%)"
/>

La taula completa, amb el lloc i «vegades el seu pes en població» (quota d'Espanya dividida entre el seu pes en la població de la UE; 1 és el que li tocaria per habitants). L'any és l'últim amb dades de gairebé tots els països; l'última columna dona el primer país, o el segon quan Espanya és la primera.

<DataTable data={ranking_productos} rows=20 search=true groupBy=grupo groupsOpen=true>
    <Column id=producto title="Producte" />
    <Column id=cuota_pct title="Quota a la UE %" fmt='0.0' contentType=bar barColor='#16a34a' />
    <Column id=puesto title="Lloc" fmt='0' />
    <Column id=veces_peso_poblacion title="Vegades el seu pes en població" fmt='0.0' />
    <Column id=valor_hab_espana title="Espanya per hab." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="UE per hab." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unitat" />
    <Column id=pais_referencia title="1r (o 2n si lidera Espanya)" />
    <Column id=anio title="Any" fmt='0' />
</DataTable>

On Espanya queda lluny dels primers llocs (conreus i ramaderia, del pitjor al millor): {ranking_flojos[0]?.lista}.

## L'horta d'Europa

Espanya produeix el {formatNumber(huerta_resumen[0]?.hortalizas, 1)} % de les hortalisses fresques (amb meló i maduixa) de la UE, {formatNumber(huerta_resumen[0]?.hortalizas_kg, 0)} kg per habitant davant {formatNumber(huerta_resumen[0]?.hortalizas_kg_ue, 0)} de mitjana a la UE, i el {formatNumber(huerta_resumen[0]?.valor_frutas, 1)} % del valor de la fruita (amb cítrics, raïm i oliva). En exportacions del {huerta_resumen[0]?.anio_exp} és la {huerta_resumen[0]?.exp_hortalizas_puesto}a en hortalisses ({formatNumber(huerta_resumen[0]?.exp_hortalizas, 1)} % del que exporten els 27, inclòs el que es venen entre ells) i la {huerta_resumen[0]?.exp_frutas_puesto}a en fruites i fruits secs ({formatNumber(huerta_resumen[0]?.exp_frutas, 1)} %); en cítrics arriba al {formatNumber(huerta_resumen[0]?.exp_citricos, 1)} %. En tomàquet el primer productor és {huerta_resumen[0]?.tomate_primero}: Espanya en té el {formatNumber(huerta_resumen[0]?.tomate, 1)} %.

<LineChart
    data={huerta_serie}
    x=anio
    y=cuota_pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% del total de la UE-27"
    title="Quota d'Espanya a la UE: fruites i hortalisses (només anys amb els 27 països)"
/>

<DataTable data={huerta} rows=30 search=true groupBy=grupo groupsOpen=true>
    <Column id=producto title="Producte" />
    <Column id=cuota_pct title="Quota a la UE %" fmt='0.0' contentType=bar barColor='#16a34a' />
    <Column id=puesto title="Lloc" fmt='0' />
    <Column id=veces_peso_poblacion title="Vegades el seu pes en població" fmt='0.0' />
    <Column id=valor_hab_espana title="Espanya per hab." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="UE per hab." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unitat" />
    <Column id=pais_referencia title="1r (o 2n si lidera Espanya)" />
</DataTable>

En les exportacions, els Països Baixos surten inflats perquè reexporten des de Rotterdam el que importen de fora; i totes les xifres inclouen el comerç dins de la UE.

## Oli d'oliva

Segons la Comissió Europea, en la campanya {aceite_kpi[0]?.campania} (d'octubre a setembre) Espanya va produir **{formatNumber(aceite_kpi[0]?.prod_kt, 0)} milers de tones**, el {formatNumber(aceite_kpi[0]?.cuota_ue, 1)} % de l'oli de la UE i {formatNumber(aceite_kpi[0]?.kg_hab, 1)} kg per habitant. Des del {aceite_kpi[0]?.desde} la seva quota mitjana és del {formatNumber(aceite_kpi[0]?.cuota_media, 1)} %; la més baixa va ser la del {aceite_kpi[0]?.campania_min} ({formatNumber(aceite_kpi[0]?.cuota_min, 1)} %), amb {formatNumber(aceite_kpi[0]?.prod_min, 0)} milers de tones, i el màxim de producció, {formatNumber(aceite_kpi[0]?.prod_max, 0)}, es va assolir el {aceite_kpi[0]?.campania_max}.

{#if aceite_kpi[0]?.ultima_estimada}
<p>La campanya {aceite_kpi[0]?.campania_est} és encara <strong>una estimació</strong>: {formatNumber(aceite_kpi[0]?.prod_kt_est, 0)} milers de tones, el {formatNumber(aceite_kpi[0]?.cuota_ue_est, 1)} % de la UE i el {formatNumber(aceite_kpi[0]?.cuota_mundo_est, 1)} % de la previsió mundial del COI.</p>
{/if}

<BarChart
    data={aceite_grupos}
    x=campania
    y=cuota_ue_pct
    series=grupo
    type=stacked
    sort=false
    yFmt='0"%"'
    yAxisTitle="% de la producció de la UE"
    seriesColors={{'España': '#dc2626', 'Italia': '#16a34a', 'Grecia': '#2563eb', 'Portugal': '#f59e0b', 'Resto de la UE': '#94a3b8'}}
    title="Producció d'oli d'oliva de la UE per país, % de cada campanya (l'última, estimada)"
/>

Fora de la UE, el Consell Oleícola Internacional (COI) dona per al {aceite_mundo[0]?.campania} una producció mundial de {formatNumber(aceite_mundo[0]?.mundo, 0)} milers de tones: Espanya, amb {formatNumber(aceite_mundo[0]?.espana, 0)}, va ser la primera i va produir {formatNumber(aceite_mundo[0]?.veces_segundo, 1)} vegades el que va produir la segona, {aceite_mundo[0]?.pais_segundo}. Espanya és també la primera exportadora de la UE: el {formatNumber(aceite_export[0]?.cuota_pct, 1)} % de l'oli que venen els 27 en volum i el {formatNumber(aceite_export[1]?.cuota_pct, 1)} % en euros.

El preu en origen de l'**oli verge extra** als mercats espanyols, en euros de {precio_resumen[0]?.mes_base}, va tocar sostre el {precio_resumen[0]?.mes_maximo} amb {formatNumber(precio_resumen[0]?.maximo, 2)} €/kg; el {precio_resumen[0]?.mes_ultimo} estava a {formatNumber(precio_resumen[0]?.ultimo, 2)} €/kg, davant una mitjana de {formatNumber(precio_resumen[0]?.media_2015_2019, 2)} €/kg d'avui entre el 2015 i el 2019.

<LineChart
    data={aceite_precios}
    x=mes
    y=eur_kg_real
    series=pais
    yFmt='0.00" €"'
    yAxisTitle="€/kg en euros d'avui"
    seriesColors={{'España': '#dc2626', 'Italia': '#16a34a', 'Grecia': '#2563eb'}}
    title="Preu en origen de l'oli d'oliva verge extra, €/kg descomptada la inflació (mitjana mensual dels mercats)"
/>

## Vi

Espanya té **la vinya més gran del món**: {formatNumber(vino_mundo[0]?.vinedo_es, 0)} milers d'hectàrees el {vino_mundo[0]?.anio}, el {formatNumber(vino_mundo[0]?.vinedo_pct, 1)} % del total mundial segons l'OIV. En vi és la {vino_mundo[0]?.vino_puesto}a productora del món ({formatNumber(vino_mundo[0]?.vino_es, 1)} milions d'hectolitres, el {formatNumber(vino_mundo[0]?.vino_pct, 1)} %) i la {vino_mundo[0]?.exp_vol_puesto}a exportadora en volum ({formatNumber(vino_mundo[0]?.exp_vol_es, 1)} milions d'hectolitres); en valor exporta {formatNumber(vino_mundo[0]?.exp_val_es, 1)} milers de milions d'euros, davant {formatNumber(vino_mundo[0]?.exp_val_fr, 1)} de França i {formatNumber(vino_mundo[0]?.exp_val_it, 1)} d'Itàlia.

La diferència és en el preu: el {vino_precio_resumen[0]?.anio} el vi que va exportar Espanya va sortir a {formatNumber(vino_precio_resumen[0]?.es, 2)} € per quilo (gairebé el mateix que per litre), davant {formatNumber(vino_precio_resumen[0]?.it, 2)} € l'italià i {formatNumber(vino_precio_resumen[0]?.fr, 2)} € el francès.

<BarChart
    data={vino}
    x=producto
    y=cuota_pct
    swapXY=true
    sort=false
    yFmt='0"%"'
    yAxisTitle="% del total de la UE-27"
    fillColor='#7c2d12'
    title="Vi: quota d'Espanya a la UE segons què es mesuri (%)"
/>

<BarChart
    data={vino_precio}
    x=pais
    y=eur_kg
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.00" €"'
    yAxisTitle="€ per kg exportat"
    seriesColors={{'España': '#dc2626', 'Otros países': '#93c5fd'}}
    title="Preu mitjà del vi exportat (països que exporten més de 100.000 t), € per kg"
/>

**Compte amb els comptes agraris:** el «valor del vi» d'Eurostat deixa Espanya en un {formatNumber(vino[4]?.cuota_pct, 1)} % de la UE perquè només compta el vi que elaboren les mateixes explotacions; a Espanya la major part el fan cellers i cooperatives fora de la branca agrària i es comptabilitza com a raïm venut. Per comparar vi és millor l'OIV o la vinya.

## Ramaderia

Espanya és la primera de la UE en **carn de porcí** ({formatNumber(kpi[0]?.porcino, 1)} %, per davant de {kpi[0]?.porcino_segundo}) i en **carn d'oví** ({formatNumber(ganaderia_resumen[0]?.ovino, 1)} %). Té {formatNumber(ganaderia_resumen[0]?.cerdos_1000, 0)} porcs per cada 1.000 habitants, davant {formatNumber(ganaderia_resumen[0]?.cerdos_1000_ue, 0)} a la UE. La seva quota en porcí ha passat del {formatNumber(porcino_cambio[0]?.cuota_ini, 1)} % el {porcino_cambio[0]?.anio_ini} al {formatNumber(porcino_cambio[0]?.cuota_fin, 1)} %. En aviram és la {ganaderia_resumen[0]?.aves_puesto}a ({formatNumber(ganaderia_resumen[0]?.aves, 1)} %, després de {ganaderia_resumen[0]?.aves_primero}) i en boví la {ganaderia_resumen[0]?.bovino_puesto}a ({formatNumber(ganaderia_resumen[0]?.bovino, 1)} %). El punt feble és **la llet**: és la {ganaderia_resumen[0]?.leche_puesto}a, amb el {formatNumber(ganaderia_resumen[0]?.leche, 1)} % de la UE i {formatNumber(ganaderia_resumen[0]?.leche_kg, 0)} kg de llet de vaca lliurada per habitant, menys de la meitat de la mitjana ({formatNumber(ganaderia_resumen[0]?.leche_kg_ue, 0)} kg).

<BarChart
    data={ganaderia}
    x=producto
    y=cuota_pct
    series=posicion
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    yAxisTitle="% del total de la UE-27"
    seriesColors={{'1.º de la UE': '#b45309', '2.º o 3.º': '#f59e0b', '4.º o peor': '#94a3b8'}}
    title="Ramaderia: quota d'Espanya a la UE (%)"
/>

<LineChart
    data={serie_porcino}
    x=anio
    y=cuota_pct
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% de la carn de porcí de la UE-27"
    lineColor='#b45309'
    title="Quota d'Espanya en la carn de porcí de la UE (sacrifici a l'escorxador)"
/>

<DataTable data={ganaderia} rows=10>
    <Column id=producto title="Producte" />
    <Column id=cuota_pct title="Quota a la UE %" fmt='0.0' contentType=bar barColor='#b45309' />
    <Column id=puesto title="Lloc" fmt='0' />
    <Column id=valor_hab_espana title="Espanya per hab." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="UE per hab." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unitat" />
    <Column id=pais_referencia title="1r (o 2n si lidera Espanya)" />
    <Column id=anio title="Any" fmt='0' />
</DataTable>

La cabana ovina només la publiquen els països amb més de 500.000 ovelles, i la carn és la sacrificada a l'escorxador (no inclou la que s'exporta en viu).

## Pesca i aqüicultura

Espanya és la primera de la UE en **captures**, en **aqüicultura** (en tones: el {formatNumber(pesca_resumen[0]?.acui, 1)} %, sobretot musclo) i en **arqueig de la flota** ({formatNumber(pesca_resumen[0]?.flota_gt, 1)} % de la capacitat). En nombre de vaixells és la {pesca_resumen[0]?.flota_nr_puesto}a ({formatNumber(pesca_resumen[0]?.buques, 0)} vaixells): els seus vaixells són més grans que la mitjana. En valor de l'aqüicultura la primera és {pesca_resumen[0]?.acui_eur_primero} i Espanya en té el {formatNumber(pesca_resumen[0]?.acui_eur, 1)} %.

En captures cal anar amb compte: diversos països han deixat de publicar a Eurostat (el {pesca_resumen[0]?.capturas_anio} en falten {pesca_resumen[0]?.capturas_sin}). Sobre els que publiquen, Espanya va pescar el {formatNumber(pesca_resumen[0]?.capturas, 1)} % ({formatNumber(pesca_resumen[0]?.capturas_kt, 0)} milers de t); sumant al total l'última dada coneguda dels que falten, la **quota prudent és del {formatNumber(pesca_resumen[0]?.capturas_min, 1)} %**, que és la xifra que convé fer servir. Per habitant ({formatNumber(pesca_resumen[0]?.capturas_kg, 1)} kg) Espanya és la {pesca_hab[0]?.puesto_hab}a: la primera és {pesca_hab[0]?.primero_hab}, amb {formatNumber(pesca_hab[0]?.primero_kg, 0)} kg.

<LineChart
    data={pesca_serie}
    x=anio
    y=cuota
    series=medida
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% de les captures de la UE"
    seriesColors={{'Sobre los países con dato': '#93c5fd', 'Prudente (con el último dato de los que faltan)': '#0369a1'}}
    title="Quota d'Espanya en les captures de pesca de la UE (%)"
/>

<BarChart
    data={pesca_paises}
    x=pais
    y=kg_hab
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="kg per habitant (pes viu)"
    seriesColors={{'España': '#dc2626', 'Otros países': '#93c5fd'}}
    title="Captures de pesca per habitant, països de la UE que publiquen la dada"
/>

<DataTable data={pesca} rows=5>
    <Column id=producto title="Indicador" />
    <Column id=cuota_pct title="Quota a la UE %" fmt='0.0' contentType=bar barColor='#0284c7' />
    <Column id=cuota_min_pct title="Quota prudent %" fmt='0.0' />
    <Column id=puesto title="Lloc" fmt='0' />
    <Column id=valor_hab_espana title="Espanya per hab." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="UE per hab." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unitat" />
    <Column id=paises_sin_dato title="Països sense dada" />
    <Column id=anio title="Any" fmt='0' />
</DataTable>

## El que val el camp

La branca agrària (agricultura i ramaderia, sense pesca ni silvicultura) va produir el {valor_resumen[0]?.anio} **{formatNumber(valor_resumen[0]?.es, 0)} € per habitant** a Espanya, davant {formatNumber(valor_resumen[0]?.ue, 0)} € a la UE-27; de valor afegit, un cop restats pinsos, fertilitzants, energia i altres consums, queden {formatNumber(valor_resumen[0]?.es_vab, 0)} € per habitant ({formatNumber(valor_resumen[0]?.ue_vab, 0)} € a la UE). Entre els {valor_rank.length} països que es comparen aquí, Espanya és la {valor_rank.filter(d => d.geo === 'ES')[0]?.rk}a per habitant; el primer és {valor_rank[0]?.pais}. Sense l'efecte dels preus (en volum), la producció per habitant {#if valor_resumen[0]?.vol_var >= 0}ha crescut un {formatNumber(valor_resumen[0]?.vol_var, 1)} %{:else}ha baixat un {formatNumber(-valor_resumen[0]?.vol_var, 1)} %{/if} des del 2005.

<LineChart
    data={valor_paises}
    x=anio
    y=produccion_eur_hab_real_pib
    series=pais
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per habitant, euros d'avui"
    seriesColors={{'España': '#dc2626', 'UE-27': '#0f172a'}}
    title="Producció de la branca agrària per habitant, en euros d'avui (deflactor del PIB de cada país)"
/>

La **renda agrària** per unitat de treball a temps complet (el que queda per remunerar el treball, la terra i el capital, en euros del 2020 descomptada la inflació) va ser a Espanya de {formatNumber(valor_resumen[0]?.renta_es, 0)} € el {valor_resumen[0]?.anio}, davant {formatNumber(valor_resumen[0]?.renta_ue, 0)} € de mitjana a la UE.

<LineChart
    data={valor_paises}
    x=anio
    y=renta_real_uta_eur2020
    series=pais
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ del 2020 per UTA"
    seriesColors={{'España': '#dc2626', 'UE-27': '#0f172a'}}
    title="Renda agrària real per unitat de treball any (euros del 2020)"
/>

Per productes, el valor de la producció confirma el rànquing en tones: Espanya és la primera en oli d'oliva, fruites i porcí, i queda lluny en llet i en el vi dels comptes agraris.

<DataTable data={valor_productos} rows=10>
    <Column id=producto title="Producció" />
    <Column id=cuota_pct title="Quota a la UE %" fmt='0.0' contentType=bar barColor='#16a34a' />
    <Column id=puesto title="Lloc" fmt='0' />
    <Column id=valor_hab_espana title="Espanya, € per hab." fmt='#,##0' />
    <Column id=valor_hab_ue title="UE, € per hab." fmt='#,##0' />
    <Column id=pais_referencia title="1r (o 2n si lidera Espanya)" />
    <Column id=anio title="Any" fmt='0' />
</DataTable>

## Per comunitat i província

El sector primari (agricultura, ramaderia, silvicultura i pesca) va generar el {espana_vab[0]?.anio} el {formatNumber(espana_vab[0]?.peso, 1)} % del valor afegit d'Espanya ({formatNumber(espana_vab[0]?.peso_2000, 1)} % el 2000), {formatNumber(espana_vab[0]?.eur_hab, 0)} € per habitant. Les comunitats on pesa més són {ccaa_resumen[0]?.mas}; {ccaa_resumen[0]?.max_hab_ccaa} és on produeix més per habitant ({formatNumber(ccaa_resumen[0]?.max_hab, 0)} €). Per província ({provincias_resumen[0]?.anio}), les de més pes són {provincias_resumen[0]?.mas}; en {provincias_resumen[0]?.mas_10} províncies supera el 10 %.

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
        {id: 'peso_vab_pct', title: '% del valor afegit', fmt: '0.0'},
        {id: 'vab_primario_eur_hab_real', title: "€ per habitant (euros d'avui)", fmt: '#,##0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=peso_vab_pct title="% del valor afegit" fmt='0.0' contentType=bar barColor='#65a30d' />
    <Column id=peso_2000 title="% el 2000" fmt='0.0' />
    <Column id=vab_primario_eur_hab_real title="€ per hab. (euros d'avui)" fmt='#,##0' />
    <Column id=vab_primario_meur title="Milions de € (corrents)" fmt='#,##0' />
    <Column id=anio title="Any" fmt='0' />
</DataTable>

Eurostat només dona per comunitat els conreus herbacis. En **cereals**, {cereales_resumen[0]?.lista} reuneixen el {formatNumber(cereales_resumen[0]?.top3, 1)} % de la collita espanyola del {cereales_resumen[0]?.anio}:

<BarChart
    data={cereales_ccaa}
    x=ccaa
    y=kg_hab
    swapXY=true
    yFmt='#,##0'
    yAxisTitle="kg per habitant"
    fillColor='#ca8a04'
    title="Collita de cereals per habitant i comunitat (comunitats amb almenys el 0,5 % del total)"
/>

## Metodologia i fonts

- **Producció de conreus**: [Eurostat apro_cpsh1](https://ec.europa.eu/eurostat/databrowser/view/apro_cpsh1/default/table) (producció collida a humitat UE i superfície) i, per comunitat, [apro_cpshr](https://ec.europa.eu/eurostat/databrowser/view/apro_cpshr/default/table).
- **Ramaderia**: [apro_mt_pann](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_pann/default/table) (carn sacrificada a l'escorxador, pes en canal), [apro_mt_lspig](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_lspig/default/table), [apro_mt_lssheep](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_lssheep/default/table) i [apro_mt_lscatl](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_lscatl/default/table) (cabana de novembre-desembre) i [apro_mk_cola](https://ec.europa.eu/eurostat/databrowser/view/apro_mk_cola/default/table) (llet lliurada a les centrals).
- **Pesca**: [fish_ca_main](https://ec.europa.eu/eurostat/databrowser/view/fish_ca_main/default/table) (captures en pes viu), [fish_aq2a](https://ec.europa.eu/eurostat/databrowser/view/fish_aq2a/default/table) (aqüicultura) i [fish_fleet_alt](https://ec.europa.eu/eurostat/databrowser/view/fish_fleet_alt/default/table) (flota a 31 de desembre). Irlanda, Letònia i Portugal no publiquen captures en els últims anys: la quota prudent suma al total la seva última dada coneguda.
- **Valor de la producció i renda agrària**: comptes econòmics de l'agricultura d'Eurostat, [aact_eaa01](https://ec.europa.eu/eurostat/databrowser/view/aact_eaa01/default/table) (a preus bàsics), [aact_eaa04](https://ec.europa.eu/eurostat/databrowser/view/aact_eaa04/default/table) (volum) i [aact_eaa06](https://ec.europa.eu/eurostat/databrowser/view/aact_eaa06/default/table) (renda real per UTA). Euros d'avui: Espanya amb l'IPC de l'INE; per comparar països, tots amb el seu deflactor del PIB ([nama_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/nama_10_gdp/default/table)).
- **Exportacions**: [Eurostat Comext](https://ec.europa.eu/eurostat/comext/newxtweb/) (DS-045409), a totes les destinacions, inclòs el comerç dins de la UE.
- **Per comunitat i província**: valor afegit brut de la branca A, [Eurostat nama_10r_3gva](https://ec.europa.eu/eurostat/databrowser/view/nama_10r_3gva/default/table), que reprodueix la Comptabilitat Regional de l'INE. Població de l'INE i d'Eurostat ([nama_10_pe](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe/default/table)).
- **Oli d'oliva**: producció per campanya i preus en origen de la Comissió Europea, [Agri-food data portal](https://agridata.ec.europa.eu/extensions/DataPortal/olive-oil.html) (l'última campanya és una estimació; el preu del mes és la mitjana de les cotitzacions setmanals dels mercats del país, en euros d'avui amb l'IPC d'Espanya). Producció mundial: [Consell Oleícola Internacional, Olive sector statistics (desembre del 2025)](https://www.internationaloliveoil.org/olive-sector-statistics-december-2025-and-forecasts/), xifres citades amb font.
- **Vi i vinya al món**: [OIV, State of the World Wine Sector in 2025](https://www.oiv.int/sites/default/files/2026-05/OIV-State_of_the_World_Wine_Sector_in_2025.pdf) (maig del 2026), xifres citades amb font.
- **Quotes**: Espanya sobre la suma dels 27 països amb dada, en l'últim any amb dades de gairebé tots (cobertura d'almenys el 97 %). «Vegades el seu pes en població» = quota d'Espanya / pes d'Espanya en la població de la UE-27.
