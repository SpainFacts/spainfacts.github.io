---
title: Habitatge
description: "Preu de l'habitatge a Espanya descomptada la inflació, lloguer, compravendes i hipoteques per 1.000 habitants, obra nova i quants anys de salari costa una casa, per comunitat i província."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: f97a78f90884
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql precio
SELECT fecha, periodo, euros_m2, euros_m2_real, precio_90m2_real, interanual_real, interanual_nominal, anio_base
FROM mother.vivienda_precio_tasado
WHERE nivel = 'pais'
ORDER BY fecha
```

```sql precio_largo
SELECT fecha, 'Descontada la inflación' AS serie, euros_m2_real AS euros_m2 FROM mother.vivienda_precio_tasado WHERE nivel = 'pais' AND euros_m2_real IS NOT NULL
UNION ALL
SELECT fecha, 'Sin descontar (euros de cada año)' AS serie, euros_m2 FROM mother.vivienda_precio_tasado WHERE nivel = 'pais' AND anio >= 2002
ORDER BY fecha, serie
```

```sql resumen
SELECT * FROM mother.vivienda_resumen_territorios WHERE nivel = 'pais'
```

```sql alquiler
SELECT anio, alquiler_mes_mediana, alquiler_mes_mediana_real, variacion_real, anio_base
FROM mother.vivienda_alquiler
WHERE nivel = 'pais' AND tipologia = 'Colectiva'
ORDER BY anio
```

```sql mercado_mes
SELECT fecha, compraventas_12m, compraventas_12m_1000, hipotecas_12m_1000
FROM mother.vivienda_mercado_mensual
WHERE nivel = 'pais' AND compraventas_12m_1000 IS NOT NULL
ORDER BY fecha
```

```sql mercado_ultimo
SELECT
    u.fecha,
    strftime(u.fecha, '%m/%Y') AS mes_texto,
    u.compraventas_12m,
    u.compraventas_12m_1000,
    u.hipotecas_12m_1000,
    100 * (u.compraventas_12m_1000 / a.compraventas_12m_1000 - 1) AS var_anual
FROM mother.vivienda_mercado_mensual u
LEFT JOIN mother.vivienda_mercado_mensual a
  ON a.nivel = 'pais' AND a.fecha = u.fecha - INTERVAL 1 YEAR
WHERE u.nivel = 'pais' AND u.compraventas_12m_1000 IS NOT NULL
ORDER BY u.fecha DESC
LIMIT 1
```

```sql esfuerzo
SELECT anio, anios_salario, pct_alquiler, precio_90m2, salario_anual
FROM mother.vivienda_esfuerzo
WHERE nivel = 'pais' AND anios_salario IS NOT NULL
ORDER BY anio
```

```sql mercado_anual
SELECT anio, 'Compraventas' AS operacion, compraventas_1000 AS por_1000 FROM mother.vivienda_mercado_anual WHERE nivel = 'pais' AND meses = 12
UNION ALL
SELECT anio, 'Hipotecas sobre viviendas' AS operacion, hipotecas_1000 AS por_1000 FROM mother.vivienda_mercado_anual WHERE nivel = 'pais' AND meses_hipotecas = 12
ORDER BY anio, operacion
```

```sql ccaa
SELECT cod, nombre AS comunidad, '/ca' || ruta AS ruta, euros_m2_real, precio_interanual_real, precio_vs_maximo_real,
       alquiler_mes_mediana_real, compraventas_12m_1000, anios_salario
FROM mother.vivienda_resumen_territorios
WHERE nivel = 'ccaa'
ORDER BY euros_m2_real DESC
```

```sql hitos
SELECT
    max(euros_m2_real) AS max_real,
    arg_max(periodo, euros_m2_real) AS periodo_max,
    min(euros_m2_real) FILTER (WHERE anio >= 2008) AS min_real,
    arg_min(periodo, euros_m2_real) FILTER (WHERE anio >= 2008) AS periodo_min,
    100 * (arg_max(euros_m2_real, fecha) / max(euros_m2_real) - 1) AS vs_max,
    100 * (arg_max(euros_m2_real, fecha) / min(euros_m2_real) FILTER (WHERE anio >= 2008) - 1) AS vs_min
FROM mother.vivienda_precio_tasado
WHERE nivel = 'pais' AND euros_m2_real IS NOT NULL
```

# 🏠 Habitatge

Quant costa comprar o llogar una casa a Espanya, quantes se'n venen i quantes se'n construeixen. Els preus es mostren **descomptada la inflació** (en euros de {precio.slice(-1)[0]?.anio_base}) i les operacions **per cada 1.000 habitants**, per poder comparar anys i territoris.

<Grid cols=4>
    <KpiCard
        title="Preu de l'habitatge"
        value={precio.slice(-1)[0]?.euros_m2_real}
        formattedValue="{formatNumber(precio.slice(-1)[0]?.euros_m2_real, 0)} €/m²"
        period="valor taxat, {precio.slice(-1)[0]?.periodo} · {formatNumber(precio.slice(-1)[0]?.precio_90m2_real / 1000, 0)} mil € un pis de 90 m²"
        change={precio.slice(-1)[0]?.interanual_real?.toFixed(1)}
        changePeriod="real vs. un any abans"
        direction="neutral"
        source="Ministeri d'Habitatge"
        href="/ca/vivienda/precios"
        sparklineData={precio.filter(d => d.euros_m2_real != null).map(d => ({...d, y: d.euros_m2_real}))}
    />
    <KpiCard
        title="Lloguer medià d'un pis"
        value={alquiler.slice(-1)[0]?.alquiler_mes_mediana_real}
        formattedValue="{formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana_real, 0)} €/mes"
        period="contractes declarats a l'IRPF, {alquiler.slice(-1)[0]?.anio}"
        change={alquiler.slice(-1)[0]?.variacion_real?.toFixed(1)}
        changePeriod="real vs. any anterior"
        direction="neutral"
        source="Ministeri d'Habitatge (SERPAVI)"
        href="/ca/vivienda/alquiler"
        sparklineData={alquiler.map(d => ({...d, y: d.alquiler_mes_mediana_real}))}
    />
    <KpiCard
        title="Compravendes d'habitatges"
        value={mercado_ultimo[0]?.compraventas_12m_1000}
        formattedValue="{formatNumber(mercado_ultimo[0]?.compraventas_12m_1000, 1)} per 1.000 hab."
        period="12 mesos fins a {mercado_ultimo[0]?.mes_texto} · {formatCompact(mercado_ultimo[0]?.compraventas_12m, 0)} en total"
        change={mercado_ultimo[0]?.var_anual?.toFixed(1)}
        changePeriod="vs. un any abans"
        direction="neutral"
        source="INE / ETDP"
        href="/ca/vivienda/compraventas"
        sparklineData={mercado_mes.map(d => ({...d, y: d.compraventas_12m_1000}))}
    />
    <KpiCard
        title="Anys de salari per a 90 m²"
        value={esfuerzo.slice(-1)[0]?.anios_salario}
        formattedValue="{formatNumber(esfuerzo.slice(-1)[0]?.anios_salario, 1)} anys"
        period="salari brut mitjà íntegre, {esfuerzo.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="Ministeri d'Habitatge / INE"
        href="/ca/vivienda/esfuerzo"
        sparklineData={esfuerzo.map(d => ({...d, y: d.anios_salario}))}
    />
</Grid>

## El preu, amb inflació i sense

Valor taxat mitjà de l'habitatge lliure en euros per metre quadrat. Descomptada la inflació, el màxim de la sèrie és del {hitos[0]?.periodo_max} i el mínim després de la crisi, del {hitos[0]?.periodo_min}. Avui el metre quadrat és {#if hitos[0]?.vs_max < 0}un {formatNumber(-hitos[0]?.vs_max, 0)} % per sota d'aquell màxim{:else}en màxims{/if} i un {formatNumber(hitos[0]?.vs_min, 0)} % per sobre del mínim.

<LineChart
    data={precio_largo}
    x=fecha
    y=euros_m2
    series=serie
    yFmt='#,##0" €"'
    yAxisTitle="€/m²"
    startingAtZero={false}
    title="Valor taxat de l'habitatge lliure a Espanya: euros de {precio.slice(-1)[0]?.anio_base} davant d'euros de cada any"
/>

## Quants se'n compren i quants s'hipotequen

Compravendes d'habitatges inscrites als registres de la propietat i hipoteques constituïdes sobre habitatges, per cada 1.000 habitants i any.

<BarChart
    data={mercado_anual}
    x=anio
    y=por_1000
    series=operacion
    type=grouped
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="per 1.000 habitants"
    title="Compravendes i hipoteques d'habitatges per 1.000 habitants"
/>

## Per comunitat

Preu real del metre quadrat en l'últim trimestre. Fes clic en una comunitat per veure'n la fitxa.

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="euros_m2_real"
    valueFmt='#,##0" €"'
    link="ruta"
    colorPalette={['#fef3c7', '#f59e0b', '#92400e']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: Ministeri d'Habitatge, INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'euros_m2_real', title: '€/m²', fmt: '#,##0'},
        {id: 'precio_interanual_real', title: 'Variació real anual (%)', fmt: '0.0'},
        {id: 'alquiler_mes_mediana_real', title: 'Lloguer medià (€/mes)', fmt: '#,##0'},
        {id: 'anios_salario', title: 'Anys de salari (90 m²)', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=euros_m2_real title="€/m² (real)" fmt='#,##0' />
    <Column id=precio_interanual_real title="Var. real anual %" fmt='0.0' contentType=delta />
    <Column id=precio_vs_maximo_real title="Vs. màxim real %" fmt='0.0' />
    <Column id=alquiler_mes_mediana_real title="Lloguer €/mes" fmt='#,##0' />
    <Column id=compraventas_12m_1000 title="Compravendes per 1.000 hab." fmt='0.0' />
    <Column id=anios_salario title="Anys de salari" fmt='0.0' />
</DataTable>

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/ca/vivienda/precios" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">💶</span> Preus</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Valor taxat per comunitat, província i municipi i l'Índex de Preus d'Habitatge de l'INE, nou i de segona mà, descomptada la inflació.</p>
    </a>
    <a href="/ca/vivienda/alquiler" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔑</span> Lloguer</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Lloguer medià per comunitat, província i municipi amb les dades de l'IRPF, i quants habitatges es lloguen.</p>
    </a>
    <a href="/ca/vivienda/compraventas" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">📝</span> Compravendes i hipoteques</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Habitatges venuts i hipotecats per 1.000 habitants, obra nova davant de segona mà i import mitjà de la hipoteca.</p>
    </a>
    <a href="/ca/vivienda/construccion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏗️</span> Obra nova</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Habitatges lliures que es comencen i s'acaben cada any per 1.000 habitants, des del 1991.</p>
    </a>
    <a href="/ca/vivienda/esfuerzo" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">⚖️</span> Esforç</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Quants anys de salari costa un habitatge i quina part del sou se'n va en el lloguer, per comunitat.</p>
    </a>
    <a href="/ca/vivienda/vivienda-publica" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏘️</span> Habitatge públic de lloguer</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Habitatges públics de lloguer per 1.000 habitants per comunitat, província i municipi, davant dels Països Baixos, Àustria, França i la mitjana europea, i per partit.</p>
    </a>
</div>

---

**Fonts:** [Ministeri d'Habitatge i Agenda Urbana, butlletí estadístic](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000) (valor taxat i obra nova), [Sistema Estatal de Referència del Preu del Lloguer](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi), [INE, Estadística de Transmissions de Drets de la Propietat](https://www.ine.es/jaxiT3/Tabla.htm?t=6150), [INE, Estadística d'Hipoteques](https://www.ine.es/jaxiT3/Tabla.htm?t=13896) i [INE, Enquesta Trimestral de Cost Laboral](https://www.ine.es/jaxiT3/Tabla.htm?t=6061). Deflactat amb l'IPC general de l'INE (base 2025).
