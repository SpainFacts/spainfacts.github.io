---
title: Vivenda
description: "Prezo da vivenda en España descontada a inflación, aluguer, compravendas e hipotecas por 1.000 habitantes, obra nova e cantos anos de salario custa unha casa, por comunidade e provincia."
i18n_origen: 9445f0493756
og:
  image: https://spainfacts.org/og-spainfacts.png
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
SELECT cod, nombre AS comunidad, '/gl' || ruta AS ruta, euros_m2_real, precio_interanual_real, precio_vs_maximo_real,
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

# 🏠 Vivenda

Canto custa comprar ou alugar unha casa en España, cantas se venden e cantas se constrúen. Os prezos móstranse **descontada a inflación** (en euros de {precio[0]?.anio_base}) e as operacións **por cada 1.000 habitantes**, para poder comparar anos e territorios.

<Grid cols=4>
    <KpiCard
        title="Prezo da vivenda"
        value={precio.slice(-1)[0]?.euros_m2_real}
        formattedValue="{formatNumber(precio.slice(-1)[0]?.euros_m2_real, 0)} €/m²"
        period="valor taxado, {precio.slice(-1)[0]?.periodo} · {formatNumber(precio.slice(-1)[0]?.precio_90m2_real / 1000, 0)} mil € un piso de 90 m²"
        change={precio.slice(-1)[0]?.interanual_real?.toFixed(1)}
        changePeriod="real fronte a un ano antes"
        direction="neutral"
        source="Ministerio de Vivenda"
        href="/gl/vivienda/precios"
        sparklineData={precio.filter(d => d.euros_m2_real != null).map(d => d.euros_m2_real)}
    />
    <KpiCard
        title="Aluguer mediano dun piso"
        value={alquiler.slice(-1)[0]?.alquiler_mes_mediana_real}
        formattedValue="{formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana_real, 0)} €/mes"
        period="contratos declarados no IRPF, {alquiler.slice(-1)[0]?.anio}"
        change={alquiler.slice(-1)[0]?.variacion_real?.toFixed(1)}
        changePeriod="real fronte ao ano anterior"
        direction="neutral"
        source="Ministerio de Vivenda (SERPAVI)"
        href="/gl/vivienda/alquiler"
        sparklineData={alquiler.map(d => d.alquiler_mes_mediana_real)}
    />
    <KpiCard
        title="Compravendas de vivendas"
        value={mercado_ultimo[0]?.compraventas_12m_1000}
        formattedValue="{formatNumber(mercado_ultimo[0]?.compraventas_12m_1000, 1)} por 1.000 hab."
        period="12 meses ata {mercado_ultimo[0]?.mes_texto} · {formatCompact(mercado_ultimo[0]?.compraventas_12m, 0)} en total"
        change={mercado_ultimo[0]?.var_anual?.toFixed(1)}
        changePeriod="fronte a un ano antes"
        direction="neutral"
        source="INE / ETDP"
        href="/gl/vivienda/compraventas"
        sparklineData={mercado_mes.map(d => d.compraventas_12m_1000)}
    />
    <KpiCard
        title="Anos de salario para 90 m²"
        value={esfuerzo.slice(-1)[0]?.anios_salario}
        formattedValue="{formatNumber(esfuerzo.slice(-1)[0]?.anios_salario, 1)} anos"
        period="salario bruto medio íntegro, {esfuerzo.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="Ministerio de Vivenda / INE"
        href="/gl/vivienda/esfuerzo"
        sparklineData={esfuerzo.map(d => d.anios_salario)}
    />
</Grid>

## O prezo, con e sen inflación

Valor taxado medio da vivenda libre en euros por metro cadrado. Descontada a inflación, o máximo da serie é de {hitos[0]?.periodo_max} e o mínimo tras a crise, de {hitos[0]?.periodo_min}. Hoxe o metro cadrado está {#if hitos[0]?.vs_max < 0}un {formatNumber(-hitos[0]?.vs_max, 0)} % por debaixo daquel máximo{:else}en máximos{/if} e un {formatNumber(hitos[0]?.vs_min, 0)} % por riba do mínimo.

<LineChart
    data={precio_largo}
    x=fecha
    y=euros_m2
    series=serie
    yFmt='#,##0" €"'
    yAxisTitle="€/m²"
    startingAtZero={false}
    title="Valor taxado da vivenda libre en España: euros de {precio[0]?.anio_base} fronte a euros de cada ano"
/>

## Cantas se compran e cantas se hipotecan

Compravendas de vivendas inscritas nos rexistros da propiedade e hipotecas constituídas sobre vivendas, por cada 1.000 habitantes e ano.

<BarChart
    data={mercado_anual}
    x=anio
    y=por_1000
    series=operacion
    type=grouped
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="por 1.000 habitantes"
    title="Compravendas e hipotecas de vivendas por 1.000 habitantes"
/>

## Por comunidade

Prezo real do metro cadrado no último trimestre. Preme nunha comunidade para ver a súa ficha.

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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio de Vivenda, INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'euros_m2_real', title: '€/m²', fmt: '#,##0'},
        {id: 'precio_interanual_real', title: 'Variación real anual (%)', fmt: '0.0'},
        {id: 'alquiler_mes_mediana_real', title: 'Aluguer mediano (€/mes)', fmt: '#,##0'},
        {id: 'anios_salario', title: 'Anos de salario (90 m²)', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidade" />
    <Column id=euros_m2_real title="€/m² (real)" fmt='#,##0' />
    <Column id=precio_interanual_real title="Var. real anual %" fmt='0.0' contentType=delta />
    <Column id=precio_vs_maximo_real title="Fronte ao máximo real %" fmt='0.0' />
    <Column id=alquiler_mes_mediana_real title="Aluguer €/mes" fmt='#,##0' />
    <Column id=compraventas_12m_1000 title="Compravendas por 1.000 hab." fmt='0.0' />
    <Column id=anios_salario title="Anos de salario" fmt='0.0' />
</DataTable>

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/gl/vivienda/precios" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">💶</span> Prezos</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Valor taxado por comunidade, provincia e municipio e o Índice de Prezos de Vivenda do INE, nova e de segunda man, descontada a inflación.</p>
    </a>
    <a href="/gl/vivienda/alquiler" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔑</span> Aluguer</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Aluguer mediano por comunidade, provincia e municipio cos datos do IRPF, e cantas vivendas se alugan.</p>
    </a>
    <a href="/gl/vivienda/compraventas" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">📝</span> Compravendas e hipotecas</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Vivendas vendidas e hipotecadas por 1.000 habitantes, obra nova fronte a segunda man e importe medio da hipoteca.</p>
    </a>
    <a href="/gl/vivienda/construccion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏗️</span> Obra nova</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Vivendas libres que se comezan e se rematan cada ano por 1.000 habitantes, desde 1991.</p>
    </a>
    <a href="/gl/vivienda/esfuerzo" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">⚖️</span> Esforzo</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Cantos anos de salario custa unha vivenda e que parte do soldo se vai no aluguer, por comunidade.</p>
    </a>
    <a href="/gl/vivienda/vivienda-publica" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏘️</span> Vivenda pública en aluguer</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Vivendas públicas en aluguer por 1.000 habitantes por comunidade, provincia e municipio, fronte aos Países Baixos, Austria, Francia e a media europea, e por partido.</p>
    </a>
</div>

---

**Fontes:** [Ministerio de Vivenda e Axenda Urbana, boletín estatístico](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000) (valor taxado e obra nova), [Sistema Estatal de Referencia do Prezo do Aluguer](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi), [INE, Estatística de Transmisións de Dereitos da Propiedade](https://www.ine.es/jaxiT3/Tabla.htm?t=6150), [INE, Estatística de Hipotecas](https://www.ine.es/jaxiT3/Tabla.htm?t=13896) e [INE, Enquisa Trimestral de Custo Laboral](https://www.ine.es/jaxiT3/Tabla.htm?t=6061). Deflactado co IPC xeral do INE (base 2025).
