---
title: Economía
description: "PIB por habitante, crecimiento, comercio exterior, sectores, empleo, salarios, paro e inflación en España, descontada la inflación y en proporción a la población."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber } from '../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
</script>

```sql pib_hab
SELECT anio, real_eur AS valor, 100 * (real_eur / lag(real_eur) OVER (ORDER BY anio) - 1) AS crecimiento
FROM mother.economia_pib_per_capita
WHERE pais = 'ES'
ORDER BY anio
```

```sql pib_trim
SELECT trimestre, CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo, interanual, anio_base
FROM mother.economia_pib_trimestral
WHERE componente = 'B1GQ'
ORDER BY trimestre
```

```sql exportaciones
SELECT trimestre, CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo, pct_pib
FROM mother.economia_pib_trimestral
WHERE componente = 'P6'
ORDER BY trimestre
```

```sql salario
SELECT anio, salario_real, crecimiento_real
FROM mother.economia_salarios_anual
WHERE jornada = 'Todas' AND sector = 'Total'
ORDER BY anio
```

```sql empleo
SELECT anio, ocupados_1000_hab, ocupados_miles
FROM mother.economia_sectores
WHERE rama = 'TOTAL'
ORDER BY anio
```

```sql serie_paro
SELECT periodo, valor AS paro, strftime(periodo, '%Y') || '-T' || quarter(periodo) AS periodo_txt
FROM mother.metricas
WHERE metrica_id = 'tasa_paro'
ORDER BY periodo
```

```sql serie_ipc
SELECT periodo, valor AS ipc, strftime(periodo, '%Y-%m') AS periodo_txt
FROM mother.metricas
WHERE metrica_id = 'ipc_variacion_anual'
ORDER BY periodo
```

```sql sectores_crec
SELECT
    s.sector,
    100 * (s.vab_real_meur / b.vab_real_meur - 1) AS crecimiento,
    s.anio
FROM mother.economia_sectores s
JOIN mother.economia_sectores b ON b.rama = s.rama AND b.anio = 2019
WHERE s.anio = (SELECT max(anio) FROM mother.economia_sectores)
  AND s.rama <> 'TOTAL' AND NOT s.es_subrama
ORDER BY crecimiento DESC
```

# 📊 Economía

Cómo evoluciona la economía española. Siguiendo el criterio de toda la web, lo que depende del tamaño del país se muestra **por habitante** y lo que se mide en euros, **descontada la inflación** (en euros de {pib_trim[0]?.anio_base}).

<Grid cols=3>
    <KpiCard
        title="PIB por habitante"
        value={pib_hab.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pib_hab.slice(-1)[0]?.valor, 0)} €"
        period="en {pib_hab.slice(-1)[0]?.anio}, en euros de {pib_trim[0]?.anio_base}"
        change={pib_hab.slice(-1)[0]?.crecimiento?.toFixed(1)}
        changePeriod="real vs año anterior"
        direction="positive-up"
        source="Eurostat"
        sparklineData={pib_hab.map(d => ({...d, y: d.valor}))}
        href="/economia/pib"
    />
    <KpiCard
        title="Crecimiento del PIB"
        value={pib_trim.slice(-1)[0]?.interanual}
        formattedValue="{formatNumber(pib_trim.slice(-1)[0]?.interanual, 1)} %"
        period="interanual real, {pib_trim.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={pib_trim.slice(-24).map(d => ({...d, y: d.interanual}))}
        href="/economia/pib"
    />
    <KpiCard
        title="Exportaciones"
        value={exportaciones.slice(-1)[0]?.pct_pib}
        formattedValue="{formatNumber(exportaciones.slice(-1)[0]?.pct_pib, 1)} % del PIB"
        period="bienes y servicios, {exportaciones.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={exportaciones.slice(-40).map(d => ({...d, y: d.pct_pib}))}
        href="/economia/comercio-exterior"
    />
    <KpiCard
        title="Salario medio"
        value={salario.slice(-1)[0]?.salario_real}
        formattedValue="{formatNumber(salario.slice(-1)[0]?.salario_real, 0)} €/mes"
        period="bruto en {salario.slice(-1)[0]?.anio}, descontada la inflación"
        change={salario.slice(-1)[0]?.crecimiento_real?.toFixed(1)}
        changePeriod="real vs año anterior"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={salario.map(d => ({...d, y: d.salario_real}))}
        href="/economia/salarios"
    />
    <KpiCard
        title="Tasa de paro"
        value={serie_paro.slice(-1)[0]?.paro}
        formattedValue="{formatNumber(serie_paro.slice(-1)[0]?.paro, 1)} %"
        period={serie_paro.slice(-1)[0]?.periodo_txt}
        change={serie_paro.length > 1 ? (serie_paro.slice(-1)[0]?.paro - serie_paro.slice(-2)[0]?.paro).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="vs trimestre anterior"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={serie_paro.slice(-40).map(d => ({...d, y: d.paro}))}
        href="/economia/paro"
    />
    <KpiCard
        title="Inflación"
        value={serie_ipc.slice(-1)[0]?.ipc}
        formattedValue="{formatNumber(serie_ipc.slice(-1)[0]?.ipc, 1)} %"
        period="IPC interanual, {serie_ipc.slice(-1)[0]?.periodo_txt}"
        change={serie_ipc.length > 1 ? (serie_ipc.slice(-1)[0]?.ipc - serie_ipc.slice(-2)[0]?.ipc).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="vs mes anterior"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={serie_ipc.slice(-36).map(d => ({...d, y: d.ipc}))}
        href="/economia/ipc"
    />
</Grid>

## PIB por habitante

Lo que produce la economía por cada habitante, en euros constantes. [Crecimiento trimestral, demanda y comparación con Europa →](/economia/pib)

<LineChart
    data={pib_hab}
    x=anio
    y=valor
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ por habitante (reales)"
    startingAtZero={false}
    title="PIB por habitante en euros de {pib_trim[0]?.anio_base}"
/>

## Sectores

Crecimiento real del valor añadido de cada gran sector desde 2019. [Empleo, peso y productividad por sector →](/economia/sectores)

<BarChart
    data={sectores_crec}
    x=sector
    y=crecimiento
    swapXY=true
    yFmt='0.0"%"'
    title="Crecimiento real del valor añadido entre 2019 y {sectores_crec[0]?.anio} (%)"
/>

## Empleo

Ocupados por cada 1.000 habitantes: sube cuando se crea empleo más deprisa de lo que crece la población. [Tasa de paro →](/economia/paro)

<LineChart
    data={empleo}
    x=anio
    y=ocupados_1000_hab
    xFmt='0'
    yAxisTitle="Ocupados por 1.000 hab."
    startingAtZero={false}
    title="Ocupados por 1.000 habitantes"
/>

## Salarios

Salario medio mensual bruto descontada la inflación. [Crecimiento, sectores y deciles →](/economia/salarios)

<LineChart
    data={salario}
    x=anio
    y=salario_real
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ al mes (reales)"
    startingAtZero={false}
    title="Salario medio mensual en euros de {pib_trim[0]?.anio_base}"
/>

## Paro e inflación

<Grid cols=2>
<LineChart
    data={serie_paro}
    x=periodo
    y=paro
    yAxisTitle="% de la población activa"
    title="Tasa de paro (EPA)"
    startingAtZero={false}
/>
<LineChart
    data={serie_ipc}
    x=periodo
    y=ipc
    yAxisTitle="% interanual"
    title="Inflación (IPC, variación anual)"
    startingAtZero={false}
/>
</Grid>

<Grid cols=3>
    <a href="/economia/comercio-exterior" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🚢</span> Comercio exterior</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Exportaciones, importaciones y saldo exterior sobre el PIB</div>
    </a>
    <a href="/economia/paro" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">👷</span> Paro</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Serie histórica de la EPA</div>
    </a>
    <a href="/economia/ipc" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🛒</span> Inflación</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Índice de precios de consumo y precio de la energía</div>
    </a>
    <a href="/economia/turismo" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🏖️</span> Turismo</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Turistas por habitante, su gasto real y en % del PIB, hoteles y viviendas turísticas</div>
    </a>
    <a href="/economia/empresas" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🏢</span> Empresas, emprendimiento e I+D</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Empresas por habitante y tamaño, sociedades creadas y disueltas, concursos, autónomos y gasto en I+D frente a Europa</div>
    </a>
    <a href="/economia/sector-primario" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🌾</span> Agricultura, ganadería y pesca</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">La huerta de Europa: aceite, cítricos, frutas y hortalizas, porcino, vino y pesca, y el puesto de España en la UE</div>
    </a>
    <a href="/economia/industria" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🏭</span> Industria</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Coches, azulejos, alimentación, tren y aerogeneradores: dónde destaca España y cuánta industria tiene frente a la UE</div>
    </a>
    <a href="/economia/construccion" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🏗️</span> Construcción</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">La burbuja de 2007, el desplome y la recuperación: empleo, obra pública licitada, viviendas visadas y cemento frente a la UE</div>
    </a>
</Grid>

---

**Fuentes:** Eurostat (contabilidad nacional: [namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table), [nama_10_pc](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table), [nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table)) e INE ([EPA](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176918), [IPC](https://www.ine.es/jaxiT3/Tabla.htm?t=76125), [Encuesta Trimestral de Coste Laboral](https://www.ine.es/jaxiT3/Tabla.htm?t=6038)).
