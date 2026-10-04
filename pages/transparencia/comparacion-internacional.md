---
title: España frente a otros países
description: "Índices internacionales de corrupción, integridad y gobierno abierto: dónde está España respecto a la UE, la OCDE y los países de referencia, y cómo ha evolucionado con cada Gobierno."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

```sql esp
-- Último dato de España en cada índice, con el anterior, el primero de la serie y la media UE
WITH e AS (
    SELECT *,
        lag(valor) OVER (PARTITION BY indicador_id ORDER BY anio) AS valor_anterior,
        lag(anio) OVER (PARTITION BY indicador_id ORDER BY anio) AS anio_anterior,
        row_number() OVER (PARTITION BY indicador_id ORDER BY anio DESC) AS rn
    FROM mother.transparencia_internacional
    WHERE cod_pais = 'ES'
)
SELECT e.indicador_id, e.nombre_corto, e.unidad, e.sentido, e.fuente, e.orden_indicador,
    CAST(e.anio AS INTEGER) AS anio, e.valor, e.valor_anterior, CAST(e.anio_anterior AS INTEGER) AS anio_anterior,
    e.valor - e.valor_anterior AS cambio,
    CAST(e.puesto_mundial AS INTEGER) AS puesto_mundial,
    CAST(e.puesto_ue AS INTEGER) AS puesto_ue, CAST(e.n_ue AS INTEGER) AS n_ue,
    CAST(e.puesto_ocde AS INTEGER) AS puesto_ocde, CAST(e.n_ocde AS INTEGER) AS n_ocde,
    ue.valor AS valor_ue
FROM e
LEFT JOIN mother.transparencia_internacional ue
    ON ue.indicador_id = e.indicador_id AND ue.anio = e.anio AND ue.cod_pais = 'EU27_2020'
WHERE e.rn = 1
ORDER BY e.orden_indicador
```

```sql esp_cpi
SELECT * FROM ${esp} WHERE indicador_id = 'cpi'
```

```sql esp_wgi
SELECT * FROM ${esp} WHERE indicador_id = 'wgi_control_corrupcion'
```

```sql esp_wjp
SELECT * FROM ${esp} WHERE indicador_id = 'wjp_gobierno_abierto'
```

```sql esp_vdem
SELECT * FROM ${esp} WHERE indicador_id = 'vdem_corrupcion_politica'
```

```sql rango
SELECT CAST(min(puesto_ue) AS INTEGER) AS mejor, CAST(max(puesto_ue) AS INTEGER) AS peor FROM ${esp}
```

```sql cpi_inicio
SELECT CAST(anio AS INTEGER) AS anio, valor, CAST(puesto_ue AS INTEGER) AS puesto_ue
FROM mother.transparencia_internacional
WHERE cod_pais = 'ES' AND indicador_id = 'cpi'
ORDER BY anio
LIMIT 1
```

```sql serie_esp
SELECT indicador_id, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE cod_pais = 'ES'
ORDER BY indicador_id, anio
```

```sql referencia
-- Países de referencia y medias UE/OCDE, todas las series
SELECT indicador_id, pais, cod_pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE es_referencia AND anio >= 1996
ORDER BY indicador_id, orden_pais, anio
```

```sql ranking_ue
-- Países de la UE en el último año con dato de España, España destacada
SELECT t.indicador_id, t.pais, t.valor, CAST(t.anio AS INTEGER) AS anio,
    CASE WHEN t.cod_pais = 'ES' THEN 'España' ELSE 'Resto de la UE' END AS grupo
FROM mother.transparencia_internacional t
JOIN (
    SELECT indicador_id, max(anio) AS anio
    FROM mother.transparencia_internacional
    WHERE cod_pais = 'ES'
    GROUP BY indicador_id
) u ON u.indicador_id = t.indicador_id AND u.anio = t.anio
WHERE t.es_ue
ORDER BY t.indicador_id, t.valor DESC
```

```sql puesto_ue_serie
SELECT indicador_id, nombre_corto, CAST(anio AS INTEGER) AS anio, CAST(puesto_ue AS INTEGER) AS puesto_ue, CAST(n_ue AS INTEGER) AS n_ue
FROM mother.transparencia_internacional
WHERE cod_pais = 'ES' AND indicador_id IN ('cpi', 'wgi_control_corrupcion', 'wjp_estado_derecho') AND anio >= 1996
ORDER BY indicador_id, anio
```

```sql tabla_paises
-- Último dato de cada país de referencia en los índices principales
WITH u AS (
    SELECT t.* FROM mother.transparencia_internacional t
    JOIN (
        SELECT indicador_id, cod_pais, max(anio) AS anio
        FROM mother.transparencia_internacional
        GROUP BY indicador_id, cod_pais
    ) m ON m.indicador_id = t.indicador_id AND m.cod_pais = t.cod_pais AND m.anio = t.anio
    WHERE t.es_referencia
)
SELECT
    pais,
    min(orden_pais) AS orden,
    max(CASE WHEN indicador_id = 'cpi' THEN valor END) AS cpi,
    max(CASE WHEN indicador_id = 'wgi_control_corrupcion' THEN valor END) AS wgi_cc,
    max(CASE WHEN indicador_id = 'wgi_voz_rendicion_cuentas' THEN valor END) AS wgi_va,
    max(CASE WHEN indicador_id = 'wgi_eficacia_gobierno' THEN valor END) AS wgi_ge,
    max(CASE WHEN indicador_id = 'wjp_gobierno_abierto' THEN valor END) AS wjp_ga,
    max(CASE WHEN indicador_id = 'vdem_corrupcion_politica' THEN valor END) AS vdem_cp
FROM u
GROUP BY pais
ORDER BY orden, pais
```

```sql gobiernos
SELECT
    CAST(year(CAST(desde AS DATE)) AS INTEGER) AS anio_desde,
    CAST(coalesce(year(CAST(hasta AS DATE)), year(current_date)) AS INTEGER) AS anio_hasta,
    presidente, familia
FROM mother.gobiernos_presidentes
WHERE nivel = 'estatal'
ORDER BY anio_desde
```

```sql gob_psoe
SELECT * FROM ${gobiernos} WHERE familia = 'PSOE'
```

```sql gob_pp
SELECT * FROM ${gobiernos} WHERE familia = 'PP'
```

```sql gob_ucd
SELECT * FROM ${gobiernos} WHERE familia = 'UCD'
```

```sql larga_vdem
SELECT pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE indicador_id = 'vdem_corrupcion_politica' AND cod_pais IN ('ES', 'EU27_2020', 'OECD') AND anio >= 1977
ORDER BY cod_pais, anio
```

```sql larga_wgi
SELECT pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE indicador_id = 'wgi_control_corrupcion' AND cod_pais IN ('ES', 'EU27_2020', 'OECD')
ORDER BY cod_pais, anio
```

```sql mandatos
-- Cambio de la distancia de España a la media de la UE atribuido a cada Gobierno.
-- Media de la UE: media simple de los países de la UE con serie completa desde
-- 1976 (o desde el inicio del índice), para que la composición no cambie con los
-- años. Cada año se asigna a quien gobernaba el 1 de julio; el cambio de un año es
-- la variación de la brecha respecto al año anterior con dato. Signo positivo =
-- España mejora respecto a la UE (en V-Dem, donde más es peor, se invierte).
WITH g AS (
    SELECT presidente, familia, CAST(desde AS DATE) AS desde,
        coalesce(CAST(hasta AS DATE), current_date + INTERVAL 1 DAY) AS hasta
    FROM mother.gobiernos_presidentes
    WHERE nivel = 'estatal'
),
base AS (
    SELECT indicador_id, sentido, cod_pais, es_ue, CAST(anio AS INTEGER) AS anio, valor
    FROM mother.transparencia_internacional
    WHERE indicador_id IN ('vdem_corrupcion_politica', 'wgi_control_corrupcion')
      AND anio >= 1976 AND NOT es_agregado
),
anios_esp AS (
    SELECT indicador_id, count(*) AS n FROM base WHERE cod_pais = 'ES' GROUP BY indicador_id
),
panel AS (
    SELECT b.indicador_id, b.cod_pais
    FROM base b JOIN anios_esp a ON a.indicador_id = b.indicador_id
    WHERE b.es_ue AND b.cod_pais <> 'ES'
    GROUP BY b.indicador_id, b.cod_pais, a.n
    HAVING count(*) = a.n
),
n_panel AS (
    SELECT indicador_id, CAST(count(*) AS INTEGER) AS n_panel FROM panel GROUP BY indicador_id
),
media AS (
    SELECT b.indicador_id, b.anio, avg(b.valor) AS valor
    FROM base b JOIN panel p ON p.indicador_id = b.indicador_id AND p.cod_pais = b.cod_pais
    GROUP BY b.indicador_id, b.anio
),
brecha AS (
    SELECT e.indicador_id, e.sentido, e.anio, e.valor - m.valor AS brecha
    FROM base e JOIN media m ON m.indicador_id = e.indicador_id AND m.anio = e.anio
    WHERE e.cod_pais = 'ES'
),
cambios AS (
    SELECT *,
        (brecha - lag(brecha) OVER (PARTITION BY indicador_id ORDER BY anio))
            * CASE WHEN sentido = 'negativo' THEN -1 ELSE 1 END AS mejora
    FROM brecha
)
SELECT
    c.indicador_id,
    CASE WHEN c.indicador_id = 'vdem_corrupcion_politica' THEN 'Corrupción política (V-Dem, puntos)' ELSE 'Control de la corrupción (Banco Mundial, puntos)' END AS indice,
    CASE g.presidente
        WHEN 'Adolfo Suárez / Leopoldo Calvo-Sotelo' THEN 'Suárez y Calvo-Sotelo'
        WHEN 'Felipe González' THEN 'González'
        WHEN 'José María Aznar' THEN 'Aznar'
        WHEN 'José Luis Rodríguez Zapatero' THEN 'Zapatero'
        WHEN 'Mariano Rajoy' THEN 'Rajoy'
        WHEN 'Pedro Sánchez' THEN 'Sánchez'
        ELSE g.presidente END || ' (' || CAST(year(g.desde) AS VARCHAR) || '-' ||
        CASE WHEN g.hasta > current_date THEN 'hoy' ELSE CAST(year(g.hasta) AS VARCHAR) END || ')' AS mandato,
    g.familia,
    year(g.desde) AS orden,
    CAST(count(c.mejora) AS INTEGER) AS anios,
    CAST(min(c.anio) AS INTEGER) AS primer_anio,
    CAST(max(c.anio) AS INTEGER) AS ultimo_anio,
    sum(c.mejora) AS mejora,
    sum(c.mejora) / count(c.mejora) AS mejora_anual,
    min(n.n_panel) AS n_panel
FROM cambios c
JOIN n_panel n ON n.indicador_id = c.indicador_id
JOIN g ON make_date(c.anio, 7, 1) >= g.desde AND make_date(c.anio, 7, 1) < g.hasta
WHERE c.mejora IS NOT NULL
GROUP BY c.indicador_id, indice, g.presidente, g.familia, g.desde, g.hasta
ORDER BY c.indicador_id, orden
```

```sql mandatos_vdem
SELECT * FROM ${mandatos} WHERE indicador_id = 'vdem_corrupcion_politica' ORDER BY orden
```

```sql mandatos_wgi
SELECT * FROM ${mandatos} WHERE indicador_id = 'wgi_control_corrupcion' ORDER BY orden
```

```sql wjp_factores
SELECT nombre_corto AS factor, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE cod_pais = 'ES' AND indicador_id LIKE 'wjp_%'
ORDER BY orden_indicador, anio
```

```sql opciones
SELECT DISTINCT indicador_id, nombre, orden_indicador
FROM mother.transparencia_internacional
ORDER BY orden_indicador
```

```sql exp_info
SELECT DISTINCT nombre, unidad, sentido, fuente, url_fuente
FROM mother.transparencia_internacional
WHERE indicador_id = '${inputs.ind.value}'
```

```sql exp_serie
SELECT pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE indicador_id = '${inputs.ind.value}' AND es_referencia AND anio >= 1996
ORDER BY orden_pais, anio
```

```sql exp_ranking
SELECT t.pais, t.valor,
    CASE WHEN t.cod_pais = 'ES' THEN 'España' WHEN t.es_ue THEN 'Resto de la UE' ELSE 'Resto de la OCDE' END AS grupo
FROM mother.transparencia_internacional t
WHERE t.indicador_id = '${inputs.ind.value}' AND (t.es_ue OR t.es_ocde)
  AND t.anio = (
    SELECT max(anio) FROM mother.transparencia_internacional
    WHERE indicador_id = '${inputs.ind.value}' AND cod_pais = 'ES'
  )
ORDER BY t.valor DESC
```

# 🌍 Transparencia: España frente a otros países

¿Cómo se ve la integridad de las instituciones españolas desde fuera? Varios organismos internacionales publican cada año **índices comparables entre países** sobre corrupción, Estado de derecho y gobierno abierto. Esta página reúne los principales, sitúa a España entre los **27 países de la UE** y los **38 de la OCDE**, y la compara con sus vecinos y con los países que suelen encabezar estas clasificaciones (Dinamarca, Finlandia, Nueva Zelanda y Estonia).

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">Cómo leer esta página</p>
<p class="mb-1">Ninguno de estos índices cuenta casos de corrupción: <b>miden percepciones y valoraciones</b> de expertos, empresas y ciudadanos encuestados. Son útiles para comparar países y ver tendencias largas, pero reaccionan con retraso, tienen márgenes de error de varios puntos y pueden moverse por escándalos mediáticos tanto como por cambios reales.</p>
<p class="mb-0">Diferencias de uno o dos puntos entre años o entre países vecinos en la clasificación <b>no suelen ser significativas</b>. Lo que importa es la tendencia de varios años y la distancia con la media.</p>
</div>

<Grid cols=4>
    <KpiCard
        title="Percepción de la corrupción (CPI)"
        value={esp_cpi[0]?.valor}
        formattedValue="{formatNumber(esp_cpi[0]?.valor, 0)} / 100"
        period="{esp_cpi[0]?.anio} · puesto {esp_cpi[0]?.puesto_ue} de {esp_cpi[0]?.n_ue} en la UE, {esp_cpi[0]?.puesto_mundial} del mundo"
        change={esp_cpi[0]?.cambio}
        changeUnit=" pts"
        changePeriod="vs {esp_cpi[0]?.anio_anterior}"
        direction="positive-up"
        source="Transparency International"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'cpi').map(d => d.valor)}
    />
    <KpiCard
        title="Control de la corrupción (Banco Mundial)"
        value={esp_wgi[0]?.valor}
        formattedValue="{formatNumber(esp_wgi[0]?.valor, 1)} / 100"
        period="{esp_wgi[0]?.anio} · puesto {esp_wgi[0]?.puesto_ue} de {esp_wgi[0]?.n_ue} en la UE (media UE {formatNumber(esp_wgi[0]?.valor_ue, 1)})"
        change={esp_wgi[0]?.cambio?.toFixed(1)}
        changeUnit=" pts"
        changePeriod="vs {esp_wgi[0]?.anio_anterior}"
        direction="positive-up"
        source="Banco Mundial (WGI)"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'wgi_control_corrupcion').map(d => d.valor)}
    />
    <KpiCard
        title="Gobierno abierto (WJP)"
        value={esp_wjp[0]?.valor}
        formattedValue="{formatNumber(esp_wjp[0]?.valor, 0)} / 100"
        period="{esp_wjp[0]?.anio} · puesto {esp_wjp[0]?.puesto_ue} de {esp_wjp[0]?.n_ue} en la UE"
        change={esp_wjp[0]?.cambio?.toFixed(1)}
        changeUnit=" pts"
        changePeriod="vs {esp_wjp[0]?.anio_anterior}"
        direction="positive-up"
        source="World Justice Project"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'wjp_gobierno_abierto').map(d => d.valor)}
    />
    <KpiCard
        title="Corrupción política (V-Dem)"
        value={esp_vdem[0]?.valor}
        formattedValue="{formatNumber(esp_vdem[0]?.valor, 1)} / 100"
        period="{esp_vdem[0]?.anio} · más bajo es mejor · puesto {esp_vdem[0]?.puesto_ue} de {esp_vdem[0]?.n_ue} en la UE"
        change={esp_vdem[0]?.cambio?.toFixed(1)}
        changeUnit=" pts"
        changePeriod="vs {esp_vdem[0]?.anio_anterior}"
        direction="positive-down"
        source="V-Dem"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'vdem_corrupcion_politica' && d.anio >= 1977).map(d => d.valor)}
    />
</Grid>

En el último año con datos, España queda **entre los puestos {rango[0]?.mejor} y {rango[0]?.peor} de los 27 países de la UE** según el índice, lejos de los nórdicos, que encabezan casi todas estas clasificaciones. En el Índice de Percepción de la Corrupción ha pasado de {formatNumber(cpi_inicio[0]?.valor, 0)} puntos en {cpi_inicio[0]?.anio} (puesto {cpi_inicio[0]?.puesto_ue} de la UE) a {formatNumber(esp_cpi[0]?.valor, 0)} en {esp_cpi[0]?.anio} (puesto {esp_cpi[0]?.puesto_ue}).

## España y los países de referencia

Último dato disponible de cada país en los índices principales. En todos, **más es mejor** salvo en el de V-Dem (corrupción política), donde más es peor. Las medias de la UE y la OCDE solo existen para los índices del Banco Mundial y V-Dem (ver la metodología).

<DataTable data={tabla_paises} rows=all>
    <Column id=pais title="País" />
    <Column id=cpi title="CPI (0-100)" fmt='0' />
    <Column id=wgi_cc title="Control corrupción (0-100)" fmt='0.0' />
    <Column id=wgi_va title="Voz y rendición de cuentas (0-100)" fmt='0.0' />
    <Column id=wgi_ge title="Eficacia del gobierno (0-100)" fmt='0.0' />
    <Column id=wjp_ga title="Gobierno abierto WJP (0-100)" fmt='0.0' />
    <Column id=vdem_cp title="Corrupción política V-Dem (0-100, menos es mejor)\" fmt='0.0' />
</DataTable>

## Percepción de la corrupción

El **Índice de Percepción de la Corrupción** (CPI) de Transparency International es el más citado. Promedia hasta 13 encuestas y valoraciones de expertos y empresas sobre la corrupción en el sector público; 100 es «muy limpio» y 0 «muy corrupto». Su método solo es comparable desde 2012.

<LineChart
    data={referencia.filter(d => d.indicador_id === 'cpi')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yMin=20
    yAxisTitle="puntos (0-100)"
    title="Índice de Percepción de la Corrupción"
    seriesColors={{'España': '#b91c1c'}}
/>

<BarChart
    data={ranking_ue.filter(d => d.indicador_id === 'cpi')}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    yFmt='0'
    title="CPI: países de la UE en {esp_cpi[0]?.anio}"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

## Gobernanza según el Banco Mundial

Los **Worldwide Governance Indicators** del Banco Mundial combinan más de 30 fuentes (encuestas a hogares y empresas, ONG, organismos públicos y agencias de riesgo) en seis dimensiones de gobernanza. Aquí se muestran cuatro, en su escala de 0 a 100. Las medias de la UE y la OCDE son **medias simples** de sus países miembros actuales.

<Grid cols=2>
<LineChart
    data={referencia.filter(d => d.indicador_id === 'wgi_control_corrupcion')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Control de la corrupción"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>
<LineChart
    data={referencia.filter(d => d.indicador_id === 'wgi_voz_rendicion_cuentas')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Voz y rendición de cuentas"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>
<LineChart
    data={referencia.filter(d => d.indicador_id === 'wgi_eficacia_gobierno')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Eficacia del gobierno"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>
<LineChart
    data={referencia.filter(d => d.indicador_id === 'wgi_estado_derecho')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Estado de derecho"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>
</Grid>

**Voz y rendición de cuentas** mide libertad de expresión, de prensa y de asociación y la calidad de las elecciones; **eficacia del gobierno**, la calidad de los servicios públicos y de la administración y su independencia de presiones políticas; **Estado de derecho**, la confianza en las leyes, los tribunales, la policía y el cumplimiento de los contratos. Cada puntuación lleva un intervalo de confianza del 90 % de varios puntos: los cambios de un año a otro suelen quedar dentro de él.

### Puesto de España en la UE

<LineChart
    data={puesto_ue_serie}
    x=anio
    y=puesto_ue
    series=nombre_corto
    xFmt='0'
    yFmt='0'
    yAxisTitle="puesto entre los 27 (1 = el mejor)"
    title="Posición de España entre los países de la UE-27"
/>

La posición se calcula entre los países que hoy forman la UE-27 con dato ese año (1 = el mejor). En el eje, un número más alto significa una posición peor.

## Serie larga y cambios de Gobierno

El proyecto **V-Dem** (Universidad de Gotemburgo) reconstruye con valoraciones de expertos un índice de corrupción política desde mucho antes de la democracia, así que permite ver toda la etapa constitucional. Las bandas de fondo marcan quién gobernaba: <span style="color:#16a34a">UCD</span>, <span style="color:#dc2626">PSOE</span> y <span style="color:#2563eb">PP</span>. La media de la UE solo aparece desde que hay dato de al menos el 90 % de los países que hoy la forman (varios no existían como Estados independientes antes de 1991).

<LineChart
    data={larga_vdem}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="0-100 (más alto = más corrupción)"
    title="Índice de corrupción política (V-Dem), 1977-{esp_vdem[0]?.anio}"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
>
    <ReferenceArea data={gob_ucd} xMin=anio_desde xMax=anio_hasta label=familia color="#16a34a" opacity=0.08 />
    <ReferenceArea data={gob_psoe} xMin=anio_desde xMax=anio_hasta label=familia color="#dc2626" opacity=0.08 />
    <ReferenceArea data={gob_pp} xMin=anio_desde xMax=anio_hasta label=familia color="#2563eb" opacity=0.08 />
</LineChart>

<LineChart
    data={larga_wgi}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100 (más alto = mejor)"
    title="Control de la corrupción (Banco Mundial), 1996-{esp_wgi[0]?.anio}"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>

### Por Gobierno, frente a la media de la UE

Para no atribuir a un Gobierno lo que es una tendencia europea, se mide **cuánto cambió la distancia entre España y la media de la UE** durante cada mandato. La media es la de los países de la UE con serie completa, para que no cambie su composición con los años ({mandatos_vdem[0]?.n_panel} países en V-Dem desde 1976 y {mandatos_wgi[0]?.n_panel} en el Banco Mundial desde 1996). Cada año se asigna a quien gobernaba el 1 de julio. Un valor positivo significa que España **mejoró respecto a la UE**; negativo, que empeoró. Se expresa en puntos de la escala 0-100.

<BarChart
    data={mandatos_vdem}
    x=mandato
    y=mejora
    series=familia
    swapXY=true
    sort=false
    yFmt='0.0'
    title="V-Dem, corrupción política: mejora frente a la UE (puntos)"
    seriesColors={{'UCD': '#16a34a', 'PSOE': '#dc2626', 'PP': '#2563eb'}}
/>

<BarChart
    data={mandatos_wgi}
    x=mandato
    y=mejora
    series=familia
    swapXY=true
    sort=false
    yFmt='0.0'
    title="Banco Mundial, control de la corrupción: mejora frente a la UE (puntos)"
    seriesColors={{'UCD': '#16a34a', 'PSOE': '#dc2626', 'PP': '#2563eb'}}
/>

<DataTable data={mandatos} rows=all>
    <Column id=indice title="Índice" />
    <Column id=mandato title="Mandato" />
    <Column id=familia title="Partido" />
    <Column id=primer_anio title="Desde" fmt='0' />
    <Column id=ultimo_anio title="Hasta" fmt='0' />
    <Column id=anios title="Años con dato" fmt='0' />
    <Column id=mejora title="Mejora frente a la UE" fmt='0.0' contentType=delta />
    <Column id=mejora_anual title="Por año" fmt='0.00' contentType=delta />
</DataTable>

Hay que leer estas barras con cautela. Los índices de percepción **reaccionan con años de retraso**: los grandes casos de corrupción suelen juzgarse y publicarse mucho después de los hechos, y con frecuencia durante el mandato siguiente. Tampoco separan lo que depende del Gobierno central de lo que depende de comunidades, ayuntamientos, partidos o tribunales. Y los mandatos cortos suman pocos años, de modo que un solo dato atípico pesa mucho.

## Estado de derecho y gobierno abierto

El **Rule of Law Index** del World Justice Project se basa en una encuesta a la población general (unas 1.000 personas por país) y en cuestionarios a expertos jurídicos. De sus ocho factores, estos cuatro son los más relacionados con la transparencia: el índice global, los **límites al poder del gobierno** (controles del Parlamento, los tribunales y los órganos de auditoría), la **ausencia de corrupción** y el **gobierno abierto** (leyes y datos publicados, derecho de acceso a la información, participación ciudadana y vías de queja).

<LineChart
    data={wjp_factores}
    x=anio
    y=valor
    series=factor
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="España en el Rule of Law Index (WJP)"
/>

<LineChart
    data={referencia.filter(d => d.indicador_id === 'wjp_gobierno_abierto')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Gobierno abierto (WJP, factor 3)"
    seriesColors={{'España': '#b91c1c'}}
/>

Las ediciones 2012-2013 y 2017-2018 del WJP fueron bienales y aparecen en el segundo año.

## Explorar cualquier índice

Elige un índice para ver su evolución en los países de referencia y la clasificación de los países de la UE y la OCDE en el último año con dato de España.

<Dropdown data={opciones} name=ind value=indicador_id label=nombre order=orden_indicador title="Índice" defaultValue="cpi" />

<LineChart
    data={exp_serie}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yAxisTitle={exp_info[0]?.unidad}
    title={exp_info[0]?.nombre}
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>

<BarChart
    data={exp_ranking}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    title="{exp_info[0]?.nombre}: países de la UE y la OCDE"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#64748b', 'Resto de la OCDE': '#cbd5e1'}}
/>

Unidad: {exp_info[0]?.unidad}. {exp_info[0]?.sentido === 'negativo' ? 'En este índice, un valor más alto es peor.' : 'En este índice, un valor más alto es mejor.'} Fuente: <a href={exp_info[0]?.url_fuente}>{exp_info[0]?.fuente}</a>.

## Metodología y fuentes

- **Índice de Percepción de la Corrupción (CPI)**, [Transparency International](https://www.transparency.org/en/cpi). Media de entre 3 y 13 fuentes (evaluaciones de riesgo país, encuestas a directivos y valoraciones de expertos) reescaladas de 0 a 100. Mide la corrupción **percibida en el sector público**, no la privada, el blanqueo ni la financiación ilegal de partidos. Comparable desde 2012. Se toma la hoja de series del Excel anual de resultados. Licencia CC BY-ND 4.0: se reproducen las puntuaciones y el puesto mundial oficiales **sin transformarlos** y por eso no se calcula media de la UE ni de la OCDE (la posición de España en la UE es solo el orden de las puntuaciones publicadas).
- **Worldwide Governance Indicators (WGI)**, [Banco Mundial](https://www.worldbank.org/en/publication/worldwide-governance-indicators), API de datos del Banco Mundial (fuente 3). Modelo estadístico que combina más de 30 fuentes de percepción en seis dimensiones; se usa la puntuación de 0 a 100 de la revisión metodológica de 2024, con su intervalo de confianza del 90 %. Bienal hasta 2002. Licencia CC BY 4.0.
- **V-Dem** (Varieties of Democracy, Universidad de Gotemburgo), vía [Our World in Data](https://ourworldindata.org/grapher/political-corruption-index). Índices de corrupción política (ejecutivo, legislativo, judicial y sector público) y de corrupción en el sector público, de 0 a 100 (100 = máxima corrupción; la escala original de 0 a 1, multiplicada por 100), construidos con un modelo de medida sobre las valoraciones de miles de expertos por país. Licencias CC BY-SA 4.0 (V-Dem) y CC BY 4.0 (OWID).
- **Rule of Law Index**, [World Justice Project](https://worldjusticeproject.org/rule-of-law-index/). Encuesta a la población general y cuestionarios a expertos; escala de 0 a 100 (la original de 0 a 1, multiplicada por 100). Cobertura creciente de países desde 2012-2013. Licencia CC BY-NC-ND 4.0: puntuaciones reproducidas tal cual, sin medias propias.
- **Medias de la UE y la OCDE**: medias simples (no ponderadas por población) de los países que **hoy** son miembros, calculadas solo para WGI y V-Dem y solo en los años con dato de al menos el 90 % de ellos. **Puesto en la UE/OCDE**: orden entre los miembros actuales con dato ese año (1 = el mejor).
- **Gobiernos**: presidentes del Gobierno y partido, del seed de gobiernos de SpainFacts. En el análisis por mandato, cada año se atribuye a quien gobernaba el 1 de julio, y el cambio anual es la variación de la distancia entre España y la media de la UE respecto al año anterior con dato.
- **Límites comunes**: todos son **índices de percepción**, compuestos a partir de encuestas y valoraciones subjetivas; varios comparten fuentes (por eso se parecen tanto); tienen márgenes de error de varios puntos; y reflejan hechos con retraso. No sustituyen a los datos de condenas o investigaciones (ver la [criminalidad](/sociedad/criminalidad/) y la [rendición de cuentas municipal](/transparencia/cuentas-municipales/)).
- **Fuentes descartadas**: el Open Data Maturity de la Comisión Europea y los indicadores de contratación pública del Single Market Scoreboard (licitador único, adjudicaciones sin convocatoria) no ofrecen hoy una descarga de datos por país y año reutilizable (solo informes en PDF y paneles interactivos); el Global Right to Information Rating evalúa la ley de acceso a la información, que cambia muy pocas veces, y no forma una serie anual.
