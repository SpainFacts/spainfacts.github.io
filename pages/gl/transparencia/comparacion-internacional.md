---
i18n_origen: 01ef937d2b37
title: España fronte a outros países
description: "Índices internacionais de corrupción, integridade e goberno aberto: onde está España respecto da UE, da OCDE e dos países de referencia, e como evolucionou con cada Goberno."
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

# 🌍 Transparencia: España fronte a outros países

Como se ve a integridade das institucións españolas desde fóra? Varios organismos internacionais publican cada ano **índices comparables entre países** sobre corrupción, Estado de dereito e goberno aberto. Esta páxina reúne os principais, sitúa España entre os **27 países da UE** e os **38 da OCDE**, e compáraa cos seus veciños e cos países que adoitan encabezar estas clasificacións (Dinamarca, Finlandia, Nova Zelandia e Estonia).

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">Como ler esta páxina</p>
<p class="mb-1">Ningún destes índices conta casos de corrupción: <b>miden percepcións e valoracións</b> de expertos, empresas e cidadáns enquisados. Son útiles para comparar países e ver tendencias longas, pero reaccionan con atraso, teñen marxes de erro de varios puntos e poden moverse por escándalos mediáticos tanto como por cambios reais.</p>
<p class="mb-0">Diferenzas dun ou dous puntos entre anos ou entre países veciños na clasificación <b>non adoitan ser significativas</b>. O que importa é a tendencia de varios anos e a distancia coa media.</p>
</div>

<Grid cols=4>
    <KpiCard
        title="Percepción da corrupción (CPI)"
        value={esp_cpi[0]?.valor}
        formattedValue="{formatNumber(esp_cpi[0]?.valor, 0)} / 100"
        period="{esp_cpi[0]?.anio} · posto {esp_cpi[0]?.puesto_ue} de {esp_cpi[0]?.n_ue} na UE, {esp_cpi[0]?.puesto_mundial} do mundo"
        change={esp_cpi[0]?.cambio}
        changeUnit=" pts"
        changePeriod="vs {esp_cpi[0]?.anio_anterior}"
        direction="positive-up"
        source="Transparency International"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'cpi').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Control da corrupción (Banco Mundial)"
        value={esp_wgi[0]?.valor}
        formattedValue="{formatNumber(esp_wgi[0]?.valor, 1)} / 100"
        period="{esp_wgi[0]?.anio} · posto {esp_wgi[0]?.puesto_ue} de {esp_wgi[0]?.n_ue} na UE (media UE {formatNumber(esp_wgi[0]?.valor_ue, 1)})"
        change={esp_wgi[0]?.cambio?.toFixed(1)}
        changeUnit=" pts"
        changePeriod="vs {esp_wgi[0]?.anio_anterior}"
        direction="positive-up"
        source="Banco Mundial (WGI)"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'wgi_control_corrupcion').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Goberno aberto (WJP)"
        value={esp_wjp[0]?.valor}
        formattedValue="{formatNumber(esp_wjp[0]?.valor, 0)} / 100"
        period="{esp_wjp[0]?.anio} · posto {esp_wjp[0]?.puesto_ue} de {esp_wjp[0]?.n_ue} na UE"
        change={esp_wjp[0]?.cambio?.toFixed(1)}
        changeUnit=" pts"
        changePeriod="vs {esp_wjp[0]?.anio_anterior}"
        direction="positive-up"
        source="World Justice Project"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'wjp_gobierno_abierto').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Corrupción política (V-Dem)"
        value={esp_vdem[0]?.valor}
        formattedValue="{formatNumber(esp_vdem[0]?.valor, 1)} / 100"
        period="{esp_vdem[0]?.anio} · máis baixo é mellor · posto {esp_vdem[0]?.puesto_ue} de {esp_vdem[0]?.n_ue} na UE"
        change={esp_vdem[0]?.cambio?.toFixed(1)}
        changeUnit=" pts"
        changePeriod="vs {esp_vdem[0]?.anio_anterior}"
        direction="positive-down"
        source="V-Dem"
        sparklineData={serie_esp.filter(d => d.indicador_id === 'vdem_corrupcion_politica' && d.anio >= 1977).map(d => ({...d, y: d.valor}))}
    />
</Grid>

No último ano con datos, España queda **entre os postos {rango[0]?.mejor} e {rango[0]?.peor} dos 27 países da UE** segundo o índice, lonxe dos nórdicos, que encabezan case todas estas clasificacións. No Índice de Percepción da Corrupción pasou de {formatNumber(cpi_inicio[0]?.valor, 0)} puntos en {cpi_inicio[0]?.anio} (posto {cpi_inicio[0]?.puesto_ue} da UE) a {formatNumber(esp_cpi[0]?.valor, 0)} en {esp_cpi[0]?.anio} (posto {esp_cpi[0]?.puesto_ue}).

## España e os países de referencia

Último dato dispoñible de cada país nos índices principais. En todos, **máis é mellor** agás no de V-Dem (corrupción política), onde máis é peor. As medias da UE e da OCDE só existen para os índices do Banco Mundial e V-Dem (ver a metodoloxía).

<DataTable data={tabla_paises} rows=all>
    <Column id=pais title="País" />
    <Column id=cpi title="CPI (0-100)" fmt='0' />
    <Column id=wgi_cc title="Control corrupción (0-100)" fmt='0.0' />
    <Column id=wgi_va title="Voz e rendición de contas (0-100)" fmt='0.0' />
    <Column id=wgi_ge title="Eficacia do goberno (0-100)" fmt='0.0' />
    <Column id=wjp_ga title="Goberno aberto WJP (0-100)" fmt='0.0' />
    <Column id=vdem_cp title="Corrupción política V-Dem (0-100, menos é mellor)\" fmt='0.0' />
</DataTable>

## Percepción da corrupción

O **Índice de Percepción da Corrupción** (CPI) de Transparency International é o máis citado. Fai a media de ata 13 enquisas e valoracións de expertos e empresas sobre a corrupción no sector público; 100 é «moi limpo» e 0 «moi corrupto». O seu método só é comparable desde 2012.

<LineChart
    data={referencia.filter(d => d.indicador_id === 'cpi')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yMin=20
    yAxisTitle="puntos (0-100)"
    title="Índice de Percepción da Corrupción"
    seriesColors={{'España': '#b91c1c'}}
/>

<BarChart
    data={ranking_ue.filter(d => d.indicador_id === 'cpi')}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    yFmt='0'
    title="CPI: países da UE en {esp_cpi[0]?.anio}"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#94a3b8'}}
/>

## Gobernanza segundo o Banco Mundial

Os **Worldwide Governance Indicators** do Banco Mundial combinan máis de 30 fontes (enquisas a fogares e empresas, ONG, organismos públicos e axencias de risco) en seis dimensións de gobernanza. Aquí amósanse catro, na súa escala de 0 a 100. As medias da UE e da OCDE son **medias simples** dos seus países membros actuais.

<Grid cols=2>
<LineChart
    data={referencia.filter(d => d.indicador_id === 'wgi_control_corrupcion')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Control da corrupción"
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
    title="Voz e rendición de contas"
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
    title="Eficacia do goberno"
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
    title="Estado de dereito"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>
</Grid>

**Voz e rendición de contas** mide a liberdade de expresión, de prensa e de asociación e a calidade das eleccións; **eficacia do goberno**, a calidade dos servizos públicos e da administración e a súa independencia de presións políticas; **Estado de dereito**, a confianza nas leis, os tribunais, a policía e o cumprimento dos contratos. Cada puntuación leva un intervalo de confianza do 90 % de varios puntos: os cambios dun ano a outro adoitan quedar dentro del.

### Posto de España na UE

<LineChart
    data={puesto_ue_serie}
    x=anio
    y=puesto_ue
    series=nombre_corto
    xFmt='0'
    yFmt='0'
    yAxisTitle="posto entre os 27 (1 = o mellor)"
    title="Posición de España entre os países da UE-27"
/>

A posición calcúlase entre os países que hoxe forman a UE-27 con dato ese ano (1 = o mellor). No eixe, un número máis alto significa unha posición peor.

## Serie longa e cambios de Goberno

O proxecto **V-Dem** (Universidade de Gotemburgo) reconstrúe con valoracións de expertos un índice de corrupción política desde moito antes da democracia, así que permite ver toda a etapa constitucional. As bandas de fondo marcan quen gobernaba: <span style="color:#16a34a">UCD</span>, <span style="color:#dc2626">PSOE</span> e <span style="color:#2563eb">PP</span>. A media da UE só aparece desde que hai dato de polo menos o 90 % dos países que hoxe a forman (varios non existían como Estados independentes antes de 1991).

<LineChart
    data={larga_vdem}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="0-100 (máis alto = máis corrupción)"
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
    yAxisTitle="0-100 (máis alto = mellor)"
    title="Control da corrupción (Banco Mundial), 1996-{esp_wgi[0]?.anio}"
    seriesColors={{'España': '#b91c1c', 'Unión Europea (media simple)': '#475569', 'OCDE (media simple)': '#94a3b8'}}
/>

### Por Goberno, fronte á media da UE

Para non lle atribuír a un Goberno o que é unha tendencia europea, mídese **canto cambiou a distancia entre España e a media da UE** durante cada mandato. A media é a dos países da UE con serie completa, para que non cambie a súa composición cos anos ({mandatos_vdem[0]?.n_panel} países en V-Dem desde 1976 e {mandatos_wgi[0]?.n_panel} no Banco Mundial desde 1996). Cada ano asígnaselle a quen gobernaba o 1 de xullo. Un valor positivo significa que España **mellorou respecto da UE**; negativo, que empeorou. Exprésase en puntos da escala 0-100.

<BarChart
    data={mandatos_vdem}
    x=mandato
    y=mejora
    series=familia
    swapXY=true
    sort=false
    yFmt='0.0'
    title="V-Dem, corrupción política: mellora fronte á UE (puntos)"
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
    title="Banco Mundial, control da corrupción: mellora fronte á UE (puntos)"
    seriesColors={{'UCD': '#16a34a', 'PSOE': '#dc2626', 'PP': '#2563eb'}}
/>

<DataTable data={mandatos} rows=all>
    <Column id=indice title="Índice" />
    <Column id=mandato title="Mandato" />
    <Column id=familia title="Partido" />
    <Column id=primer_anio title="Desde" fmt='0' />
    <Column id=ultimo_anio title="Ata" fmt='0' />
    <Column id=anios title="Anos con dato" fmt='0' />
    <Column id=mejora title="Mellora fronte á UE" fmt='0.0' contentType=delta />
    <Column id=mejora_anual title="Por ano" fmt='0.00' contentType=delta />
</DataTable>

Hai que ler estas barras con cautela. Os índices de percepción **reaccionan con anos de atraso**: os grandes casos de corrupción adoitan xulgarse e publicarse moito despois dos feitos, e con frecuencia durante o mandato seguinte. Tampouco separan o que depende do Goberno central do que depende de comunidades, concellos, partidos ou tribunais. E os mandatos curtos suman poucos anos, de modo que un só dato atípico pesa moito.

## Estado de dereito e goberno aberto

O **Rule of Law Index** do World Justice Project baséase nunha enquisa á poboación xeral (unhas 1.000 persoas por país) e en cuestionarios a expertos xurídicos. Dos seus oito factores, estes catro son os máis relacionados coa transparencia: o índice global, os **límites ao poder do goberno** (controis do Parlamento, os tribunais e os órganos de auditoría), a **ausencia de corrupción** e o **goberno aberto** (leis e datos publicados, dereito de acceso á información, participación cidadá e vías de queixa).

<LineChart
    data={wjp_factores}
    x=anio
    y=valor
    series=factor
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="España no Rule of Law Index (WJP)"
/>

<LineChart
    data={referencia.filter(d => d.indicador_id === 'wjp_gobierno_abierto')}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0'
    yAxisTitle="0-100"
    title="Goberno aberto (WJP, factor 3)"
    seriesColors={{'España': '#b91c1c'}}
/>

As edicións 2012-2013 e 2017-2018 do WJP foron bienais e aparecen no segundo ano.

## Explorar calquera índice

Escolle un índice para ver a súa evolución nos países de referencia e a clasificación dos países da UE e da OCDE no último ano con dato de España.

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
    title="{exp_info[0]?.nombre}: países da UE e da OCDE"
    seriesColors={{'España': '#b91c1c', 'Resto de la UE': '#64748b', 'Resto de la OCDE': '#cbd5e1'}}
/>

Unidade: {exp_info[0]?.unidad}. {exp_info[0]?.sentido === 'negativo' ? 'Neste índice, un valor máis alto é peor.' : 'Neste índice, un valor máis alto é mellor.'} Fonte: <a href={exp_info[0]?.url_fuente}>{exp_info[0]?.fuente}</a>.

## Metodoloxía e fontes

- **Índice de Percepción da Corrupción (CPI)**, [Transparency International](https://www.transparency.org/en/cpi). Media de entre 3 e 13 fontes (avaliacións de risco país, enquisas a directivos e valoracións de expertos) reescaladas de 0 a 100. Mide a corrupción **percibida no sector público**, non a privada, o branqueo nin o financiamento ilegal de partidos. Comparable desde 2012. Tómase a folla de series do Excel anual de resultados. Licenza CC BY-ND 4.0: reprodúcense as puntuacións e o posto mundial oficiais **sen transformalos** e por iso non se calcula media da UE nin da OCDE (a posición de España na UE é só a orde das puntuacións publicadas).
- **Worldwide Governance Indicators (WGI)**, [Banco Mundial](https://www.worldbank.org/en/publication/worldwide-governance-indicators), API de datos do Banco Mundial (fonte 3). Modelo estatístico que combina máis de 30 fontes de percepción en seis dimensións; úsase a puntuación de 0 a 100 da revisión metodolóxica de 2024, co seu intervalo de confianza do 90 %. Bienal ata 2002. Licenza CC BY 4.0.
- **V-Dem** (Varieties of Democracy, Universidade de Gotemburgo), vía [Our World in Data](https://ourworldindata.org/grapher/political-corruption-index). Índices de corrupción política (executivo, lexislativo, xudicial e sector público) e de corrupción no sector público, de 0 a 100 (100 = máxima corrupción; a escala orixinal de 0 a 1, multiplicada por 100), construídos cun modelo de medida sobre as valoracións de miles de expertos por país. Licenzas CC BY-SA 4.0 (V-Dem) e CC BY 4.0 (OWID).
- **Rule of Law Index**, [World Justice Project](https://worldjusticeproject.org/rule-of-law-index/). Enquisa á poboación xeral e cuestionarios a expertos; escala de 0 a 100 (a orixinal de 0 a 1, multiplicada por 100). Cobertura crecente de países desde 2012-2013. Licenza CC BY-NC-ND 4.0: puntuacións reproducidas tal cal, sen medias propias.
- **Medias da UE e da OCDE**: medias simples (non ponderadas por poboación) dos países que **hoxe** son membros, calculadas só para WGI e V-Dem e só nos anos con dato de polo menos o 90 % deles. **Posto na UE/OCDE**: orde entre os membros actuais con dato ese ano (1 = o mellor).
- **Gobernos**: presidentes do Goberno e partido, do seed de gobernos de SpainFacts. Na análise por mandato, cada ano atribúeselle a quen gobernaba o 1 de xullo, e o cambio anual é a variación da distancia entre España e a media da UE respecto do ano anterior con dato.
- **Límites comúns**: todos son **índices de percepción**, compostos a partir de enquisas e valoracións subxectivas; varios comparten fontes (por iso se parecen tanto); teñen marxes de erro de varios puntos; e reflicten feitos con atraso. Non substitúen os datos de condenas ou investigacións (ver a [criminalidade](/gl/sociedad/criminalidad/) e a [rendición de contas municipal](/gl/transparencia/cuentas-municipales/)).
- **Fontes descartadas**: o Open Data Maturity da Comisión Europea e os indicadores de contratación pública do Single Market Scoreboard (licitador único, adxudicacións sen convocatoria) non ofrecen hoxe unha descarga de datos por país e ano reutilizable (só informes en PDF e paneis interactivos); o Global Right to Information Rating avalía a lei de acceso á información, que cambia moi poucas veces, e non forma unha serie anual.
