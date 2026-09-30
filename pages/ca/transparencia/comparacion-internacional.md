---
title: Espanya davant d'altres països
description: "Índexs internacionals de corrupció, integritat i govern obert: on és Espanya respecte a la UE, l'OCDE i els països de referència, i com ha evolucionat amb cada Govern."
i18n_origen: b0514e13fe1c
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql esp
-- Último dato de España en cada índice, con el anterior, el primero de la serie y la media UE
WITH e AS (
    SELECT *,
        lag(valor) OVER (PARTITION BY indicador_id ORDER BY anio) AS valor_anterior,
        lag(anio) OVER (PARTITION BY indicador_id ORDER BY anio) AS anio_anterior,
        row_number() OVER (PARTITION BY indicador_id ORDER BY anio DESC) AS rn
    FROM mother.transparencia_internacional
    WHERE cod_pais = 'ESP'
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
    ON ue.indicador_id = e.indicador_id AND ue.anio = e.anio AND ue.cod_pais = 'EUU'
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
WHERE cod_pais = 'ESP' AND indicador_id = 'cpi'
ORDER BY anio
LIMIT 1
```

```sql serie_esp
SELECT indicador_id, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE cod_pais = 'ESP'
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
    CASE WHEN t.cod_pais = 'ESP' THEN 'España' ELSE 'Resto de la UE' END AS grupo
FROM mother.transparencia_internacional t
JOIN (
    SELECT indicador_id, max(anio) AS anio
    FROM mother.transparencia_internacional
    WHERE cod_pais = 'ESP'
    GROUP BY indicador_id
) u ON u.indicador_id = t.indicador_id AND u.anio = t.anio
WHERE t.es_ue
ORDER BY t.indicador_id, t.valor DESC
```

```sql puesto_ue_serie
SELECT indicador_id, nombre_corto, CAST(anio AS INTEGER) AS anio, CAST(puesto_ue AS INTEGER) AS puesto_ue, CAST(n_ue AS INTEGER) AS n_ue
FROM mother.transparencia_internacional
WHERE cod_pais = 'ESP' AND indicador_id IN ('cpi', 'wgi_control_corrupcion', 'wjp_estado_derecho') AND anio >= 1996
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
WHERE indicador_id = 'vdem_corrupcion_politica' AND cod_pais IN ('ESP', 'EUU', 'OED') AND anio >= 1977
ORDER BY cod_pais, anio
```

```sql larga_wgi
SELECT pais, CAST(anio AS INTEGER) AS anio, valor
FROM mother.transparencia_internacional
WHERE indicador_id = 'wgi_control_corrupcion' AND cod_pais IN ('ESP', 'EUU', 'OED')
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
    SELECT indicador_id, count(*) AS n FROM base WHERE cod_pais = 'ESP' GROUP BY indicador_id
),
panel AS (
    SELECT b.indicador_id, b.cod_pais
    FROM base b JOIN anios_esp a ON a.indicador_id = b.indicador_id
    WHERE b.es_ue AND b.cod_pais <> 'ESP'
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
    WHERE e.cod_pais = 'ESP'
),
cambios AS (
    SELECT *,
        (brecha - lag(brecha) OVER (PARTITION BY indicador_id ORDER BY anio))
            * CASE WHEN sentido = 'negativo' THEN -1 ELSE 1 END AS mejora
    FROM brecha
)
SELECT
    c.indicador_id,
    CASE WHEN c.indicador_id = 'vdem_corrupcion_politica' THEN 'Corrupción política (V-Dem, centésimas)' ELSE 'Control de la corrupción (Banco Mundial, puntos)' END AS indice,
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
    CASE WHEN c.indicador_id = 'vdem_corrupcion_politica' THEN 100 ELSE 1 END * sum(c.mejora) AS mejora,
    CASE WHEN c.indicador_id = 'vdem_corrupcion_politica' THEN 100 ELSE 1 END * sum(c.mejora) / count(c.mejora) AS mejora_anual,
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
WHERE cod_pais = 'ESP' AND indicador_id LIKE 'wjp_%'
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
    CASE WHEN t.cod_pais = 'ESP' THEN 'España' WHEN t.es_ue THEN 'Resto de la UE' ELSE 'Resto de la OCDE' END AS grupo
FROM mother.transparencia_internacional t
WHERE t.indicador_id = '${inputs.ind.value}' AND (t.es_ue OR t.es_ocde)
  AND t.anio = (
    SELECT max(anio) FROM mother.transparencia_internacional
    WHERE indicador_id = '${inputs.ind.value}' AND cod_pais = 'ESP'
  )
ORDER BY t.valor DESC
```

# 🌍 Transparència: Espanya davant d'altres països

Com es veu des de fora la integritat de les institucions espanyoles? Diversos organismes internacionals publiquen cada any **índexs comparables entre països** sobre corrupció, estat de dret i govern obert. Aquesta pàgina en reuneix els principals, situa Espanya entre els **27 països de la UE** i els **38 de l'OCDE**, i la compara amb els seus veïns i amb els països que solen encapçalar aquestes classificacions (Dinamarca, Finlàndia, Nova Zelanda i Estònia).

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">Com llegir aquesta pàgina</p>
<p class="mb-1">Cap d'aquests índexs no compta casos de corrupció: <b>mesuren percepcions i valoracions</b> d'experts, empreses i ciutadans enquestats. Són útils per comparar països i veure tendències llargues, però reaccionen amb retard, tenen marges d'error de diversos punts i es poden moure tant per escàndols mediàtics com per canvis reals.</p>
<p class="mb-0">Les diferències d'un o dos punts entre anys o entre països veïns a la classificació <b>no solen ser significatives</b>. El que importa és la tendència de diversos anys i la distància amb la mitjana.</p>
</div>

<Grid cols=4>
    <KpiCard
        title="Percepció de la corrupció (CPI)"
        value={esp_cpi[0]?.valor}
        formattedValue="{formatNumber(esp_cpi[0]?.valor, 0)} / 100"
        period="{esp_cpi[0]?.anio} · lloc {esp_cpi[0]?.puesto_ue} de {esp_cpi[0]?.n_ue} a la UE, {esp_cpi[0]?.puesto_mundial} del món"
        change={esp_cpi[0]?.cambio}
        changeUnit=" pts"
        changePeriod="vs {esp_cpi[0]?.anio_anterior}"
        direction="positive-up"
        source="Transparency International"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'cpi').map(d => d.valor)}
    />
    <KpiCard
        title="Control de la corrupció (Banc Mundial)"
        value={esp_wgi[0]?.valor}
        formattedValue="{formatNumber(esp_wgi[0]?.valor, 1)} / 100"
        period="{esp_wgi[0]?.anio} · lloc {esp_wgi[0]?.puesto_ue} de {esp_wgi[0]?.n_ue} a la UE (mitjana UE {formatNumber(esp_wgi[0]?.valor_ue, 1)})"
        change={esp_wgi[0]?.cambio?.toFixed(1)}
        changeUnit=" pts"
        changePeriod="vs {esp_wgi[0]?.anio_anterior}"
        direction="positive-up"
        source="Banc Mundial (WGI)"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'wgi_control_corrupcion').map(d => d.valor)}
    />
    <KpiCard
        title="Govern obert (WJP)"
        value={esp_wjp[0]?.valor}
        formattedValue="{formatNumber(esp_wjp[0]?.valor, 2)} / 1"
        period="{esp_wjp[0]?.anio} · lloc {esp_wjp[0]?.puesto_ue} de {esp_wjp[0]?.n_ue} a la UE"
        change={(esp_wjp[0]?.cambio / 0.01)?.toFixed(1)}
        changeUnit=" centèsimes"
        changePeriod="vs {esp_wjp[0]?.anio_anterior}"
        direction="positive-up"
        source="World Justice Project"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'wjp_gobierno_abierto').map(d => d.valor)}
    />
    <KpiCard
        title="Corrupció política (V-Dem)"
        value={esp_vdem[0]?.valor}
        formattedValue="{formatNumber(esp_vdem[0]?.valor, 2)} / 1"
        period="{esp_vdem[0]?.anio} · més baix és millor · lloc {esp_vdem[0]?.puesto_ue} de {esp_vdem[0]?.n_ue} a la UE"
        change={(esp_vdem[0]?.cambio / 0.01)?.toFixed(1)}
        changeUnit=" centèsimes"
        changePeriod="vs {esp_vdem[0]?.anio_anterior}"
        direction="positive-down"
        source="V-Dem"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'vdem_corrupcion_politica' && d.anio >= 1977).map(d => d.valor)}
    />
</Grid>

En l'últim any amb dades, Espanya queda **entre els llocs {rango[0]?.mejor} i {rango[0]?.peor} dels 27 països de la UE** segons l'índex, lluny dels nòrdics, que encapçalen gairebé totes aquestes classificacions. A l'Índex de Percepció de la Corrupció ha passat de {formatNumber(cpi_inicio[0]?.valor, 0)} punts el {cpi_inicio[0]?.anio} (lloc {cpi_inicio[0]?.puesto_ue} de la UE) a {formatNumber(esp_cpi[0]?.valor, 0)} el {esp_cpi[0]?.anio} (lloc {esp_cpi[0]?.puesto_ue}).

## Espanya i els països de referència

Última dada disponible de cada país en els índexs principals. En tots, **més és millor** excepte en el de V-Dem (corrupció política), on més és pitjor. Les mitjanes de la UE i l'OCDE només existeixen per als índexs del Banc Mundial i V-Dem (vegeu la metodologia).

<DataTable data={tabla_paises} rows=all>
    <Column id=pais title="País" />
    <Column id=cpi title="CPI (0-100)" fmt='0' />
    <Column id=wgi_cc title="Control corrupció (0-100)" fmt='0.0' />
    <Column id=wgi_va title="Veu i retiment de comptes (0-100)" fmt='0.0' />
    <Column id=wgi_ge title="Eficàcia del govern (0-100)" fmt='0.0' />
    <Column id=wjp_ga title="Govern obert WJP (0-1)" fmt='0.00' />
    <Column id=vdem_cp title="Corrupció política V-Dem (0-1, menys és millor)" fmt='0.00' />
</DataTable>

## Percepció de la corrupció

L'**Índex de Percepció de la Corrupció** (CPI) de Transparency International és el més citat. Fa la mitjana de fins a 13 enquestes i valoracions d'experts i empreses sobre la corrupció al sector públic; 100 és «molt net» i 0 «molt corrupte». El seu mètode només és comparable des de 2012.

<LineChart
    data={referencia.filter(d => d.indicador_id === 'cpi')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yMin=20
    yAxisTitle="punts (0-100)"
    title="Índex de Percepció de la Corrupció"
    seriesColors={{'España': '#b91c1c'}}
/>

<BarChart
    data={ranking_ue.filter(d => d.indicador_id === 'cpi')}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    yFmt='0'
    title="CPI: països de la UE el {esp_cpi[0]?.anio}"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

## Governança segons el Banc Mundial

Els **Worldwide Governance Indicators** del Banc Mundial combinen més de 30 fonts (enquestes a llars i empreses, ONG, organismes públics i agències de risc) en sis dimensions de governança. Aquí se'n mostren quatre, en la seva escala de 0 a 100. Les mitjanes de la UE i l'OCDE són **mitjanes simples** dels seus països membres actuals.

<Grid cols=2>
<LineChart
    data={referencia.filter(d => d.indicador_id === 'wgi_control_corrupcion')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Control de la corrupció"
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
    title="Veu i retiment de comptes"
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
    title="Eficàcia del govern"
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
    title="Estat de dret"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>
</Grid>

**Veu i retiment de comptes** mesura la llibertat d'expressió, de premsa i d'associació i la qualitat de les eleccions; **eficàcia del govern**, la qualitat dels serveis públics i de l'administració i la seva independència de pressions polítiques; **estat de dret**, la confiança en les lleis, els tribunals, la policia i el compliment dels contractes. Cada puntuació porta un interval de confiança del 90 % de diversos punts: els canvis d'un any a l'altre solen quedar-hi dins.

### Lloc d'Espanya a la UE

<LineChart
    data={puesto_ue_serie}
    x=anio
    y=puesto_ue
    series=nombre_corto
    xFmt='0'
    yFmt='0'
    yAxisTitle="lloc entre els 27 (1 = el millor)"
    title="Posició d'Espanya entre els països de la UE-27"
/>

La posició es calcula entre els països que avui formen la UE-27 amb dada aquell any (1 = el millor). A l'eix, un nombre més alt vol dir una posició pitjor.

## Sèrie llarga i canvis de Govern

El projecte **V-Dem** (Universitat de Göteborg) reconstrueix amb valoracions d'experts un índex de corrupció política des de molt abans de la democràcia, de manera que permet veure tota l'etapa constitucional. Les bandes de fons marquen qui governava: <span style="color:#16a34a">UCD</span>, <span style="color:#dc2626">PSOE</span> i <span style="color:#2563eb">PP</span>. La mitjana de la UE només apareix des que hi ha dada d'almenys el 90 % dels països que avui la formen (diversos no existien com a estats independents abans de 1991).

<LineChart
    data={larga_vdem}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="0-1 (més alt = més corrupció)"
    title="Índex de corrupció política (V-Dem), 1977-{esp_vdem[0]?.anio}"
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
    yAxisTitle="0-100 (més alt = millor)"
    title="Control de la corrupció (Banc Mundial), 1996-{esp_wgi[0]?.anio}"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>

### Per Govern, davant la mitjana de la UE

Per no atribuir a un Govern el que és una tendència europea, es mesura **quant va canviar la distància entre Espanya i la mitjana de la UE** durant cada mandat. La mitjana és la dels països de la UE amb sèrie completa, perquè no en canviï la composició amb els anys ({mandatos_vdem[0]?.n_panel} països a V-Dem des de 1976 i {mandatos_wgi[0]?.n_panel} al Banc Mundial des de 1996). Cada any s'assigna a qui governava l'1 de juliol. Un valor positiu vol dir que Espanya **va millorar respecte a la UE**; negatiu, que va empitjorar. A V-Dem s'expressa en centèsimes de l'índex (escala 0-100).

<BarChart
    data={mandatos_vdem}
    x=mandato
    y=mejora
    series=familia
    swapXY=true
    sort=false
    yFmt='0.0'
    title="V-Dem, corrupció política: millora davant la UE (centèsimes)"
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
    title="Banc Mundial, control de la corrupció: millora davant la UE (punts)"
    seriesColors={{'UCD': '#16a34a', 'PSOE': '#dc2626', 'PP': '#2563eb'}}
/>

<DataTable data={mandatos} rows=all>
    <Column id=indice title="Índex" />
    <Column id=mandato title="Mandat" />
    <Column id=familia title="Partit" />
    <Column id=primer_anio title="Des de" fmt='0' />
    <Column id=ultimo_anio title="Fins a" fmt='0' />
    <Column id=anios title="Anys amb dada" fmt='0' />
    <Column id=mejora title="Millora davant la UE" fmt='0.0' contentType=delta />
    <Column id=mejora_anual title="Per any" fmt='0.00' contentType=delta />
</DataTable>

Cal llegir aquestes barres amb cautela. Els índexs de percepció **reaccionen amb anys de retard**: els grans casos de corrupció se solen jutjar i publicar molt després dels fets, i sovint durant el mandat següent. Tampoc no separen el que depèn del Govern central del que depèn de comunitats, ajuntaments, partits o tribunals. I els mandats curts sumen pocs anys, de manera que una sola dada atípica pesa molt.

## Estat de dret i govern obert

El **Rule of Law Index** del World Justice Project es basa en una enquesta a la població general (unes 1.000 persones per país) i en qüestionaris a experts jurídics. Dels seus vuit factors, aquests quatre són els més relacionats amb la transparència: l'índex global, els **límits al poder del govern** (controls del Parlament, els tribunals i els òrgans d'auditoria), l'**absència de corrupció** i el **govern obert** (lleis i dades publicades, dret d'accés a la informació, participació ciutadana i vies de queixa).

<LineChart
    data={wjp_factores}
    x=anio
    y=valor
    series=factor
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="0-1"
    title="Espanya al Rule of Law Index (WJP)"
/>

<LineChart
    data={referencia.filter(d => d.indicador_id === 'wjp_gobierno_abierto')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="0-1"
    title="Govern obert (WJP, factor 3)"
    seriesColors={{'España': '#b91c1c'}}
/>

Les edicions 2012-2013 i 2017-2018 del WJP van ser biennals i apareixen en el segon any.

## Explora qualsevol índex

Tria un índex per veure'n l'evolució als països de referència i la classificació dels països de la UE i l'OCDE en l'últim any amb dada d'Espanya.

<Dropdown data={opciones} name=ind value=indicador_id label=nombre order=orden_indicador title="Índex" defaultValue="cpi" />

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
    title="{exp_info[0]?.nombre}: països de la UE i l'OCDE"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#64748b', 'Resto de la OCDE': '#cbd5e1'}}
/>

Unitat: {exp_info[0]?.unidad}. {exp_info[0]?.sentido === 'negativo' ? 'En aquest índex, un valor més alt és pitjor.' : 'En aquest índex, un valor més alt és millor.'} Font: <a href={exp_info[0]?.url_fuente}>{exp_info[0]?.fuente}</a>.

## Metodologia i fonts

- **Índex de Percepció de la Corrupció (CPI)**, [Transparency International](https://www.transparency.org/en/cpi). Mitjana d'entre 3 i 13 fonts (avaluacions de risc país, enquestes a directius i valoracions d'experts) reescalades de 0 a 100. Mesura la corrupció **percebuda al sector públic**, no la privada, el blanqueig ni el finançament il·legal de partits. Comparable des de 2012. Es pren el full de sèries de l'Excel anual de resultats. Llicència CC BY-ND 4.0: es reprodueixen les puntuacions i el lloc mundial oficials **sense transformar-los** i per això no es calcula mitjana de la UE ni de l'OCDE (la posició d'Espanya a la UE és només l'ordre de les puntuacions publicades).
- **Worldwide Governance Indicators (WGI)**, [Banc Mundial](https://www.worldbank.org/en/publication/worldwide-governance-indicators), API de dades del Banc Mundial (font 3). Model estadístic que combina més de 30 fonts de percepció en sis dimensions; es fa servir la puntuació de 0 a 100 de la revisió metodològica de 2024, amb el seu interval de confiança del 90 %. Biennal fins a 2002. Llicència CC BY 4.0.
- **V-Dem** (Varieties of Democracy, Universitat de Göteborg), via [Our World in Data](https://ourworldindata.org/grapher/political-corruption-index). Índexs de corrupció política (executiu, legislatiu, judicial i sector públic) i de corrupció al sector públic, de 0 a 1 (1 = màxima corrupció), construïts amb un model de mesura sobre les valoracions de milers d'experts per país. Llicències CC BY-SA 4.0 (V-Dem) i CC BY 4.0 (OWID).
- **Rule of Law Index**, [World Justice Project](https://worldjusticeproject.org/rule-of-law-index/). Enquesta a la població general i qüestionaris a experts; escala de 0 a 1. Cobertura creixent de països des de 2012-2013. Llicència CC BY-NC-ND 4.0: puntuacions reproduïdes tal qual, sense mitjanes pròpies.
- **Mitjanes de la UE i l'OCDE**: mitjanes simples (no ponderades per població) dels països que **avui** en són membres, calculades només per a WGI i V-Dem i només en els anys amb dada d'almenys el 90 % d'aquests. **Lloc a la UE/OCDE**: ordre entre els membres actuals amb dada aquell any (1 = el millor).
- **Governs**: presidents del Govern i partit, del seed de governs de SpainFacts. En l'anàlisi per mandat, cada any s'atribueix a qui governava l'1 de juliol, i el canvi anual és la variació de la distància entre Espanya i la mitjana de la UE respecte a l'any anterior amb dada.
- **Límits comuns**: tots són **índexs de percepció**, compostos a partir d'enquestes i valoracions subjectives; diversos comparteixen fonts (per això s'assemblen tant); tenen marges d'error de diversos punts; i reflecteixen fets amb retard. No substitueixen les dades de condemnes o investigacions (vegeu la [criminalitat](/ca/sociedad/criminalidad/) i el [retiment de comptes municipal](/ca/transparencia/cuentas-municipales/)).
- **Fonts descartades**: l'Open Data Maturity de la Comissió Europea i els indicadors de contractació pública del Single Market Scoreboard (licitador únic, adjudicacions sense convocatòria) no ofereixen avui una descàrrega de dades per país i any reutilitzable (només informes en PDF i taulers interactius); el Global Right to Information Rating avalua la llei d'accés a la informació, que canvia molt poques vegades, i no forma una sèrie anual.
