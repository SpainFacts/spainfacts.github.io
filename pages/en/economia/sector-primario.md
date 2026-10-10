---
title: Primary sector
description: "Where Spain is a powerhouse on land and at sea: EU share and rank in olive oil, citrus, fruit and vegetables, wine, pigs, sheep, fishing and aquaculture, value of agricultural output per inhabitant in real euros and weight of the primary sector by region and province."
i18n_origen: b0106b55afc7
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    const decEn = (s) => s ? s.replace(/(\d),(\d)/g, '$1.$2') : '';
    const ord = (n) => { if (n === null || n === undefined || n === '') return ''; const v = Number(n) % 100; const s = ['th', 'st', 'nd', 'rd']; return n + (s[(v - 20) % 10] || s[v] || s[0]); };
    const ordTxt = (s) => s ? s.replace(/\((\d+)\.º\)/g, (m, n) => '(' + ord(n) + ')') : '';
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
       c.vab_primario_eur_hab_real, '/en' || t.ruta AS ruta
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
       c.vab_primario_eur_hab_real, c.vab_primario_meur, c0.peso_vab_pct AS peso_2000, '/en' || t.ruta AS ruta
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

# 🌾 Primary sector

Agriculture, livestock and fishing: where Spain is **number one in the European Union** and where it is not. Each product is measured by its **share of the total for the 27** and compared with Spain's share of the EU population ({formatNumber(ranking_resumen[0]?.peso_pob, 1)} %): a 50 % share is {formatNumber(50 / ranking_resumen[0]?.peso_pob, 1)} times «its fair share» by population. Values in euros are **per inhabitant and adjusted for inflation**.

<Grid cols=4>
    <KpiCard
        title="Olive oil: EU share"
        value={aceite_kpi[0]?.cuota_ue}
        formattedValue="{formatNumber(aceite_kpi[0]?.cuota_ue, 1)} %"
        period="{aceite_kpi[0]?.campania} season · {formatNumber(aceite_kpi[0]?.cuota_mundo, 1)} % of the world (IOC) · {formatNumber(aceite_kpi[0]?.prod_kt, 0)} thousand t"
        direction="neutral"
        source="European Commission · IOC"
        sparklineData={aceite_es.map(d => ({...d, y: d.cuota_ue_pct}))}
    />
    <KpiCard
        title="Citrus fruit: EU share"
        value={kpi[0]?.citricos}
        formattedValue="{formatNumber(kpi[0]?.citricos, 1)} %"
        period="{kpi[0]?.citricos_anio} · 1st in the EU · {formatNumber(kpi[0]?.citricos_kt, 0)} thousand t"
        direction="neutral"
        source="Eurostat (apro_cpsh1)"
        sparklineData={serie_citricos.map(d => ({...d, y: d.cuota_pct}))}
    />
    <KpiCard
        title="Pigmeat: EU share"
        value={kpi[0]?.porcino}
        formattedValue="{formatNumber(kpi[0]?.porcino, 1)} %"
        period="{kpi[0]?.porcino_anio} · 1st in the EU · {formatNumber(kpi[0]?.porcino_kg_hab, 0)} kg per inhabitant (EU: {formatNumber(kpi[0]?.porcino_kg_hab_ue, 0)})"
        change={porcino_cambio[0]?.dif_pp?.toFixed(1)}
        changeUnit="pp"
        changePeriod="vs {porcino_cambio[0]?.anio_ini}"
        direction="neutral"
        source="Eurostat (apro_mt_pann)"
        sparklineData={serie_porcino.map(d => ({...d, y: d.cuota_pct}))}
    />
    <KpiCard
        title="Agricultural output per inhabitant"
        value={valor_resumen[0]?.es}
        formattedValue="{formatNumber(valor_resumen[0]?.es, 0)} €"
        period="{valor_resumen[0]?.anio}, today's euros · EU-27: {formatNumber(valor_resumen[0]?.ue, 0)} € · {formatNumber(valor_resumen[0]?.es_meur, 0)} million € in total"
        direction="positive-up"
        source="Eurostat (aact_eaa01)"
        sparklineData={valor_es.map(d => ({...d, y: d.produccion_eur_hab_real}))}
    />
</Grid>

## Where Spain is number one in the EU

Of the {ranking_resumen[0]?.total} indicators of production, area, livestock, fishing and exports compared here, Spain is **first in the EU in {ranking_resumen[0]?.primeros}** and among the top three in {ranking_resumen[0]?.podio}: it is 1st in {ranking_resumen[0]?.prim_cultivo} of {ranking_resumen[0]?.n_cultivo} crop indicators, {ranking_resumen[0]?.prim_ganaderia} of {ranking_resumen[0]?.n_ganaderia} livestock indicators, {ranking_resumen[0]?.prim_pesca} of {ranking_resumen[0]?.n_pesca} fishing and aquaculture indicators and {ranking_resumen[0]?.prim_export} of {ranking_resumen[0]?.n_export} export indicators. The highest production shares are those of {ranking_top[0]?.lista}. In {ranking_resumen[0]?.doble_peso} indicators Spain's share is at least double its population weight.

<BarChart
    data={ranking_primeros}
    x=producto
    y=cuota_pct
    series=grupo
    swapXY=true
    sort=false
    yFmt='0"%"'
    yAxisTitle="% of the EU-27 total"
    seriesColors={{'Cultivos': '#16a34a', 'Ganadería': '#b45309', 'Pesca y acuicultura': '#0284c7', 'Exportaciones': '#7c3aed'}}
    title="Indicators in which Spain is first in the EU: share of the total for the 27 (%)"
/>

The full table, with the rank and «times its population weight» (Spain's share divided by its share of the EU population; 1 is its fair share by population). The year is the latest with data for almost all countries; the last column gives the first country, or the second when Spain is first.

<DataTable data={ranking_productos} rows=20 search=true groupBy=grupo groupsOpen=true>
    <Column id=producto title="Product" />
    <Column id=cuota_pct title="EU share %" fmt='0.0' contentType=bar barColor='#16a34a' />
    <Column id=puesto title="Rank" fmt='0' />
    <Column id=veces_peso_poblacion title="Times its population weight" fmt='0.0' />
    <Column id=valor_hab_espana title="Spain per inhab." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="EU per inhab." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unit" />
    <Column id=pais_referencia title="1st (or 2nd if Spain leads)" />
    <Column id=anio title="Year" fmt='0' />
</DataTable>

Where Spain is far from the top places (crops and livestock, from worst to best): {ordTxt(ranking_flojos[0]?.lista)}.

## Europe's market garden

Spain produces {formatNumber(huerta_resumen[0]?.hortalizas, 1)} % of the EU's fresh vegetables (including melon and strawberries), {formatNumber(huerta_resumen[0]?.hortalizas_kg, 0)} kg per inhabitant compared with an EU average of {formatNumber(huerta_resumen[0]?.hortalizas_kg_ue, 0)}, and {formatNumber(huerta_resumen[0]?.valor_frutas, 1)} % of the value of fruit (including citrus, grapes and olives). In {huerta_resumen[0]?.anio_exp} exports it ranks {ord(huerta_resumen[0]?.exp_hortalizas_puesto)} in vegetables ({formatNumber(huerta_resumen[0]?.exp_hortalizas, 1)} % of what the 27 export, including what they sell to each other) and {ord(huerta_resumen[0]?.exp_frutas_puesto)} in fruit and nuts ({formatNumber(huerta_resumen[0]?.exp_frutas, 1)} %); in citrus it reaches {formatNumber(huerta_resumen[0]?.exp_citricos, 1)} %. In tomatoes the leading producer is {huerta_resumen[0]?.tomate_primero}: Spain has {formatNumber(huerta_resumen[0]?.tomate, 1)} %.

<LineChart
    data={huerta_serie}
    x=anio
    y=cuota_pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% of the EU-27 total"
    title="Spain's share of the EU: fruit and vegetables (only years with all 27 countries)"
/>

<DataTable data={huerta} rows=30 search=true groupBy=grupo groupsOpen=true>
    <Column id=producto title="Product" />
    <Column id=cuota_pct title="EU share %" fmt='0.0' contentType=bar barColor='#16a34a' />
    <Column id=puesto title="Rank" fmt='0' />
    <Column id=veces_peso_poblacion title="Times its population weight" fmt='0.0' />
    <Column id=valor_hab_espana title="Spain per inhab." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="EU per inhab." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unit" />
    <Column id=pais_referencia title="1st (or 2nd if Spain leads)" />
</DataTable>

In exports, the Netherlands appears inflated because it re-exports from Rotterdam what it imports from outside; and all figures include intra-EU trade.

## Olive oil

According to the European Commission, in the {aceite_kpi[0]?.campania} season (October to September) Spain produced **{formatNumber(aceite_kpi[0]?.prod_kt, 0)} thousand tonnes**, {formatNumber(aceite_kpi[0]?.cuota_ue, 1)} % of the EU's oil and {formatNumber(aceite_kpi[0]?.kg_hab, 1)} kg per inhabitant. Since {aceite_kpi[0]?.desde} its average share has been {formatNumber(aceite_kpi[0]?.cuota_media, 1)} %; the lowest was in {aceite_kpi[0]?.campania_min} ({formatNumber(aceite_kpi[0]?.cuota_min, 1)} %), with {formatNumber(aceite_kpi[0]?.prod_min, 0)} thousand tonnes, and peak production, {formatNumber(aceite_kpi[0]?.prod_max, 0)}, was reached in {aceite_kpi[0]?.campania_max}.

{#if aceite_kpi[0]?.ultima_estimada}
<p>The {aceite_kpi[0]?.campania_est} season is still <strong>an estimate</strong>: {formatNumber(aceite_kpi[0]?.prod_kt_est, 0)} thousand tonnes, {formatNumber(aceite_kpi[0]?.cuota_ue_est, 1)} % of the EU and {formatNumber(aceite_kpi[0]?.cuota_mundo_est, 1)} % of the IOC's world forecast.</p>
{/if}

<BarChart
    data={aceite_grupos}
    x=campania
    y=cuota_ue_pct
    series=grupo
    type=stacked
    sort=false
    yFmt='0"%"'
    yAxisTitle="% of EU production"
    seriesColors={{'España': '#dc2626', 'Italia': '#16a34a', 'Grecia': '#2563eb', 'Portugal': '#f59e0b', 'Resto de la UE': '#94a3b8'}}
    title="EU olive oil production by country, % of each season (the latest, estimated)"
/>

Outside the EU, the International Olive Council (IOC) puts world production for {aceite_mundo[0]?.campania} at {formatNumber(aceite_mundo[0]?.mundo, 0)} thousand tonnes: Spain, with {formatNumber(aceite_mundo[0]?.espana, 0)}, was first and produced {formatNumber(aceite_mundo[0]?.veces_segundo, 1)} times as much as the second, {aceite_mundo[0]?.pais_segundo}. Spain is also the EU's largest exporter: {formatNumber(aceite_export[0]?.cuota_pct, 1)} % of the oil sold by the 27 by volume and {formatNumber(aceite_export[1]?.cuota_pct, 1)} % in euros.

The farm-gate price of **extra virgin** oil in Spanish markets, in euros of {precio_resumen[0]?.mes_base}, peaked in {precio_resumen[0]?.mes_maximo} at {formatNumber(precio_resumen[0]?.maximo, 2)} €/kg; in {precio_resumen[0]?.mes_ultimo} it stood at {formatNumber(precio_resumen[0]?.ultimo, 2)} €/kg, compared with an average of {formatNumber(precio_resumen[0]?.media_2015_2019, 2)} €/kg in today's money between 2015 and 2019.

<LineChart
    data={aceite_precios}
    x=mes
    y=eur_kg_real
    series=pais
    yFmt='0.00" €"'
    yAxisTitle="€/kg in today's euros"
    seriesColors={{'España': '#dc2626', 'Italia': '#16a34a', 'Grecia': '#2563eb'}}
    title="Farm-gate price of extra virgin olive oil, €/kg adjusted for inflation (monthly market average)"
/>

## Wine

Spain has **the largest vineyard area in the world**: {formatNumber(vino_mundo[0]?.vinedo_es, 0)} thousand hectares in {vino_mundo[0]?.anio}, {formatNumber(vino_mundo[0]?.vinedo_pct, 1)} % of the world total according to the OIV. In wine it is the world's {ord(vino_mundo[0]?.vino_puesto)} largest producer ({formatNumber(vino_mundo[0]?.vino_es, 1)} million hectolitres, {formatNumber(vino_mundo[0]?.vino_pct, 1)} %) and {ord(vino_mundo[0]?.exp_vol_puesto)} largest exporter by volume ({formatNumber(vino_mundo[0]?.exp_vol_es, 1)} million hectolitres); by value it exports {formatNumber(vino_mundo[0]?.exp_val_es, 1)} billion euros, compared with {formatNumber(vino_mundo[0]?.exp_val_fr, 1)} for France and {formatNumber(vino_mundo[0]?.exp_val_it, 1)} for Italy.

The difference lies in the price: in {vino_precio_resumen[0]?.anio} the wine Spain exported sold at {formatNumber(vino_precio_resumen[0]?.es, 2)} € per kilo (almost the same as per litre), compared with {formatNumber(vino_precio_resumen[0]?.it, 2)} € for Italian wine and {formatNumber(vino_precio_resumen[0]?.fr, 2)} € for French.

<BarChart
    data={vino}
    x=producto
    y=cuota_pct
    swapXY=true
    sort=false
    yFmt='0"%"'
    yAxisTitle="% of the EU-27 total"
    fillColor='#7c2d12'
    title="Wine: Spain's share of the EU depending on what is measured (%)"
/>

<BarChart
    data={vino_precio}
    x=pais
    y=eur_kg
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.00" €"'
    yAxisTitle="€ per kg exported"
    seriesColors={{'España': '#dc2626', 'Otros países': '#93c5fd'}}
    title="Average price of exported wine (countries exporting more than 100,000 t), € per kg"
/>

**Beware of the agricultural accounts:** Eurostat's «value of wine» puts Spain at {formatNumber(vino[4]?.cuota_pct, 1)} % of the EU because it only counts wine made by the farms themselves; in Spain most is made by wineries and cooperatives outside the agricultural industry and is recorded as grapes sold. To compare wine, the OIV or vineyard area are better.

## Livestock

Spain is first in the EU in **pigmeat** ({formatNumber(kpi[0]?.porcino, 1)} %, ahead of {kpi[0]?.porcino_segundo}) and in **sheepmeat** ({formatNumber(ganaderia_resumen[0]?.ovino, 1)} %). It has {formatNumber(ganaderia_resumen[0]?.cerdos_1000, 0)} pigs per 1,000 inhabitants, compared with {formatNumber(ganaderia_resumen[0]?.cerdos_1000_ue, 0)} in the EU. Its share of pigmeat has gone from {formatNumber(porcino_cambio[0]?.cuota_ini, 1)} % in {porcino_cambio[0]?.anio_ini} to {formatNumber(porcino_cambio[0]?.cuota_fin, 1)} %. In poultry it ranks {ord(ganaderia_resumen[0]?.aves_puesto)} ({formatNumber(ganaderia_resumen[0]?.aves, 1)} %, behind {ganaderia_resumen[0]?.aves_primero}) and in beef {ord(ganaderia_resumen[0]?.bovino_puesto)} ({formatNumber(ganaderia_resumen[0]?.bovino, 1)} %). The weak point is **milk**: it ranks {ord(ganaderia_resumen[0]?.leche_puesto)}, with {formatNumber(ganaderia_resumen[0]?.leche, 1)} % of the EU and {formatNumber(ganaderia_resumen[0]?.leche_kg, 0)} kg of cow's milk delivered per inhabitant, less than half the average ({formatNumber(ganaderia_resumen[0]?.leche_kg_ue, 0)} kg).

<BarChart
    data={ganaderia}
    x=producto
    y=cuota_pct
    series=posicion
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    yAxisTitle="% of the EU-27 total"
    seriesColors={{'1.º de la UE': '#b45309', '2.º o 3.º': '#f59e0b', '4.º o peor': '#94a3b8'}}
    title="Livestock: Spain's share of the EU (%)"
/>

<LineChart
    data={serie_porcino}
    x=anio
    y=cuota_pct
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of EU-27 pigmeat"
    lineColor='#b45309'
    title="Spain's share of EU pigmeat (slaughterhouse slaughterings)"
/>

<DataTable data={ganaderia} rows=10>
    <Column id=producto title="Product" />
    <Column id=cuota_pct title="EU share %" fmt='0.0' contentType=bar barColor='#b45309' />
    <Column id=puesto title="Rank" fmt='0' />
    <Column id=valor_hab_espana title="Spain per inhab." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="EU per inhab." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unit" />
    <Column id=pais_referencia title="1st (or 2nd if Spain leads)" />
    <Column id=anio title="Year" fmt='0' />
</DataTable>

The sheep population is only published by countries with more than 500,000 sheep, and meat is that slaughtered in slaughterhouses (it does not include animals exported live).

## Fishing and aquaculture

Spain is first in the EU in **catches**, in **aquaculture** (in tonnes: {formatNumber(pesca_resumen[0]?.acui, 1)} %, mostly mussels) and in **fleet tonnage** ({formatNumber(pesca_resumen[0]?.flota_gt, 1)} % of capacity). By number of vessels it ranks {ord(pesca_resumen[0]?.flota_nr_puesto)} ({formatNumber(pesca_resumen[0]?.buques, 0)} vessels): its boats are larger than average. By value of aquaculture the leader is {pesca_resumen[0]?.acui_eur_primero} and Spain has {formatNumber(pesca_resumen[0]?.acui_eur, 1)} %.

Catches call for caution: several countries have stopped publishing on Eurostat (in {pesca_resumen[0]?.capturas_anio} {pesca_resumen[0]?.capturas_sin} are missing). Over those that publish, Spain caught {formatNumber(pesca_resumen[0]?.capturas, 1)} % ({formatNumber(pesca_resumen[0]?.capturas_kt, 0)} thousand t); adding the latest known figure for the missing ones to the total, the **prudent share is {formatNumber(pesca_resumen[0]?.capturas_min, 1)} %**, which is the figure to use. Per inhabitant ({formatNumber(pesca_resumen[0]?.capturas_kg, 1)} kg) Spain ranks {ord(pesca_hab[0]?.puesto_hab)}: first is {pesca_hab[0]?.primero_hab}, with {formatNumber(pesca_hab[0]?.primero_kg, 0)} kg.

<LineChart
    data={pesca_serie}
    x=anio
    y=cuota
    series=medida
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% of EU catches"
    seriesColors={{'Sobre los países con dato': '#93c5fd', 'Prudente (con el último dato de los que faltan)': '#0369a1'}}
    title="Spain's share of EU fish catches (%)"
/>

<BarChart
    data={pesca_paises}
    x=pais
    y=kg_hab
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="kg per inhabitant (live weight)"
    seriesColors={{'España': '#dc2626', 'Otros países': '#93c5fd'}}
    title="Fish catches per inhabitant, EU countries that publish the figure"
/>

<DataTable data={pesca} rows=5>
    <Column id=producto title="Indicator" />
    <Column id=cuota_pct title="EU share %" fmt='0.0' contentType=bar barColor='#0284c7' />
    <Column id=cuota_min_pct title="Prudent share %" fmt='0.0' />
    <Column id=puesto title="Rank" fmt='0' />
    <Column id=valor_hab_espana title="Spain per inhab." fmt='#,##0.0' />
    <Column id=valor_hab_ue title="EU per inhab." fmt='#,##0.0' />
    <Column id=unidad_hab title="Unit" />
    <Column id=paises_sin_dato title="Countries without data" />
    <Column id=anio title="Year" fmt='0' />
</DataTable>

## What farming is worth

The agricultural industry (crops and livestock, excluding fishing and forestry) produced **{formatNumber(valor_resumen[0]?.es, 0)} € per inhabitant** in Spain in {valor_resumen[0]?.anio}, compared with {formatNumber(valor_resumen[0]?.ue, 0)} € in the EU-27; in value added, once feed, fertilisers, energy and other inputs are deducted, {formatNumber(valor_resumen[0]?.es_vab, 0)} € per inhabitant remain ({formatNumber(valor_resumen[0]?.ue_vab, 0)} € in the EU). Among the {valor_rank.length} countries compared here, Spain ranks {ord(valor_rank.filter(d => d.geo === 'ES')[0]?.rk)} per inhabitant; first is {valor_rank[0]?.pais}. Without the effect of prices (in volume), output per inhabitant {#if valor_resumen[0]?.vol_var >= 0}has grown by {formatNumber(valor_resumen[0]?.vol_var, 1)} %{:else}has fallen by {formatNumber(-valor_resumen[0]?.vol_var, 1)} %{/if} since 2005.

<LineChart
    data={valor_paises}
    x=anio
    y=produccion_eur_hab_real_pib
    series=pais
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per inhabitant, today's euros"
    seriesColors={{'España': '#dc2626', 'UE-27': '#0f172a'}}
    title="Output of the agricultural industry per inhabitant, in today's euros (each country's GDP deflator)"
/>

**Agricultural income** per annual work unit (what is left to pay for labour, land and capital, in 2020 euros adjusted for inflation) was {formatNumber(valor_resumen[0]?.renta_es, 0)} € in Spain in {valor_resumen[0]?.anio}, compared with an EU average of {formatNumber(valor_resumen[0]?.renta_ue, 0)} €.

<LineChart
    data={valor_paises}
    x=anio
    y=renta_real_uta_eur2020
    series=pais
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="2020 € per AWU"
    seriesColors={{'España': '#dc2626', 'UE-27': '#0f172a'}}
    title="Real agricultural income per annual work unit (2020 euros)"
/>

By product, the value of output confirms the ranking in tonnes: Spain is first in olive oil, fruit and pigmeat, and lags far behind in milk and in the wine of the agricultural accounts.

<DataTable data={valor_productos} rows=10>
    <Column id=producto title="Output" />
    <Column id=cuota_pct title="EU share %" fmt='0.0' contentType=bar barColor='#16a34a' />
    <Column id=puesto title="Rank" fmt='0' />
    <Column id=valor_hab_espana title="Spain, € per inhab." fmt='#,##0' />
    <Column id=valor_hab_ue title="EU, € per inhab." fmt='#,##0' />
    <Column id=pais_referencia title="1st (or 2nd if Spain leads)" />
    <Column id=anio title="Year" fmt='0' />
</DataTable>

## By region and province

The primary sector (agriculture, livestock, forestry and fishing) generated {formatNumber(espana_vab[0]?.peso, 1)} % of Spain's value added in {espana_vab[0]?.anio} ({formatNumber(espana_vab[0]?.peso_2000, 1)} % in 2000), {formatNumber(espana_vab[0]?.eur_hab, 0)} € per inhabitant. The regions where it weighs most are {ccaa_resumen[0]?.mas}; {ccaa_resumen[0]?.max_hab_ccaa} is where it produces most per inhabitant ({formatNumber(ccaa_resumen[0]?.max_hab, 0)} €). By province ({provincias_resumen[0]?.anio}), those where it weighs most are {decEn(provincias_resumen[0]?.mas)}; in {provincias_resumen[0]?.mas_10} provinces it exceeds 10 %.

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
        {id: 'peso_vab_pct', title: '% of value added', fmt: '0.0'},
        {id: 'vab_primario_eur_hab_real', title: "€ per inhabitant (today's euros)", fmt: '#,##0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=peso_vab_pct title="% of value added" fmt='0.0' contentType=bar barColor='#65a30d' />
    <Column id=peso_2000 title="% in 2000" fmt='0.0' />
    <Column id=vab_primario_eur_hab_real title="€ per inhab. (today's euros)" fmt='#,##0' />
    <Column id=vab_primario_meur title="Million € (current)" fmt='#,##0' />
    <Column id=anio title="Year" fmt='0' />
</DataTable>

Eurostat only gives arable crops by region. In **cereals**, {cereales_resumen[0]?.lista} account for {formatNumber(cereales_resumen[0]?.top3, 1)} % of Spain's {cereales_resumen[0]?.anio} harvest:

<BarChart
    data={cereales_ccaa}
    x=ccaa
    y=kg_hab
    swapXY=true
    yFmt='#,##0'
    yAxisTitle="kg per inhabitant"
    fillColor='#ca8a04'
    title="Cereal harvest per inhabitant by region (regions with at least 0.5 % of the total)"
/>

## Methodology and sources

- **Crop production**: [Eurostat apro_cpsh1](https://ec.europa.eu/eurostat/databrowser/view/apro_cpsh1/default/table) (harvested production at EU standard humidity and area) and, by region, [apro_cpshr](https://ec.europa.eu/eurostat/databrowser/view/apro_cpshr/default/table).
- **Livestock**: [apro_mt_pann](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_pann/default/table) (meat from slaughterhouse slaughterings, carcass weight), [apro_mt_lspig](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_lspig/default/table), [apro_mt_lssheep](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_lssheep/default/table) and [apro_mt_lscatl](https://ec.europa.eu/eurostat/databrowser/view/apro_mt_lscatl/default/table) (November-December livestock numbers) and [apro_mk_cola](https://ec.europa.eu/eurostat/databrowser/view/apro_mk_cola/default/table) (milk delivered to dairies).
- **Fishing**: [fish_ca_main](https://ec.europa.eu/eurostat/databrowser/view/fish_ca_main/default/table) (catches in live weight), [fish_aq2a](https://ec.europa.eu/eurostat/databrowser/view/fish_aq2a/default/table) (aquaculture) and [fish_fleet_alt](https://ec.europa.eu/eurostat/databrowser/view/fish_fleet_alt/default/table) (fleet at 31 December). Ireland, Latvia and Portugal have not published catches in recent years: the prudent share adds their latest known figure to the total.
- **Value of output and agricultural income**: Eurostat economic accounts for agriculture, [aact_eaa01](https://ec.europa.eu/eurostat/databrowser/view/aact_eaa01/default/table) (at basic prices), [aact_eaa04](https://ec.europa.eu/eurostat/databrowser/view/aact_eaa04/default/table) (volume) and [aact_eaa06](https://ec.europa.eu/eurostat/databrowser/view/aact_eaa06/default/table) (real income per AWU). Today's euros: Spain with the INE's CPI; to compare countries, each with its own GDP deflator ([nama_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/nama_10_gdp/default/table)).
- **Exports**: [Eurostat Comext](https://ec.europa.eu/eurostat/comext/newxtweb/) (DS-045409), to all destinations, including intra-EU trade.
- **By region and province**: gross value added of industry A, [Eurostat nama_10r_3gva](https://ec.europa.eu/eurostat/databrowser/view/nama_10r_3gva/default/table), which reproduces the INE's Regional Accounts. Population from the INE and Eurostat ([nama_10_pe](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe/default/table)).
- **Olive oil**: production by season and farm-gate prices from the European Commission, [Agri-food data portal](https://agridata.ec.europa.eu/extensions/DataPortal/olive-oil.html) (the latest season is an estimate; the monthly price is the average of the country's weekly market quotations, in today's euros using Spain's CPI). World production: [International Olive Council, Olive sector statistics (December 2025)](https://www.internationaloliveoil.org/olive-sector-statistics-december-2025-and-forecasts/), figures cited with source.
- **Wine and vineyards worldwide**: [OIV, State of the World Wine Sector in 2025](https://www.oiv.int/sites/default/files/2026-05/OIV-State_of_the_World_Wine_Sector_in_2025.pdf) (May 2026), figures cited with source.
- **Shares**: Spain over the sum of the 27 countries with data, in the latest year with data for almost all of them (coverage of at least 97 %). «Times its population weight» = Spain's share / Spain's share of the EU-27 population.
