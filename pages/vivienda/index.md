---
title: Vivienda
description: "Precio de la vivienda en España descontada la inflación, alquiler, compraventas e hipotecas por 1.000 habitantes, obra nueva y cuántos años de salario cuesta una casa, por comunidad y provincia."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../src/lib/utils.js';
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
SELECT cod, nombre AS comunidad, ruta, euros_m2_real, precio_interanual_real, precio_vs_maximo_real,
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

# 🏠 Vivienda

Cuánto cuesta comprar o alquilar una casa en España, cuántas se venden y cuántas se construyen. Los precios se muestran **descontada la inflación** (en euros de {precio[0]?.anio_base}) y las operaciones **por cada 1.000 habitantes**, para poder comparar años y territorios.

<Grid cols=4>
    <KpiCard
        title="Precio de la vivienda"
        value={precio.slice(-1)[0]?.euros_m2_real}
        formattedValue="{formatNumber(precio.slice(-1)[0]?.euros_m2_real, 0)} €/m²"
        period="valor tasado, {precio.slice(-1)[0]?.periodo} · {formatNumber(precio.slice(-1)[0]?.precio_90m2_real / 1000, 0)} mil € un piso de 90 m²"
        change={precio.slice(-1)[0]?.interanual_real?.toFixed(1)}
        changePeriod="real vs un año antes"
        direction="neutral"
        source="Ministerio de Vivienda"
        href="/vivienda/precios"
        sparklineData={precio.filter(d => d.euros_m2_real != null).map(d => d.euros_m2_real)}
    />
    <KpiCard
        title="Alquiler mediano de un piso"
        value={alquiler.slice(-1)[0]?.alquiler_mes_mediana_real}
        formattedValue="{formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana_real, 0)} €/mes"
        period="contratos declarados en el IRPF, {alquiler.slice(-1)[0]?.anio}"
        change={alquiler.slice(-1)[0]?.variacion_real?.toFixed(1)}
        changePeriod="real vs año anterior"
        direction="neutral"
        source="Ministerio de Vivienda (SERPAVI)"
        href="/vivienda/alquiler"
        sparklineData={alquiler.map(d => d.alquiler_mes_mediana_real)}
    />
    <KpiCard
        title="Compraventas de viviendas"
        value={mercado_ultimo[0]?.compraventas_12m_1000}
        formattedValue="{formatNumber(mercado_ultimo[0]?.compraventas_12m_1000, 1)} por 1.000 hab."
        period="12 meses hasta {mercado_ultimo[0]?.mes_texto} · {formatCompact(mercado_ultimo[0]?.compraventas_12m, 0)} en total"
        change={mercado_ultimo[0]?.var_anual?.toFixed(1)}
        changePeriod="vs un año antes"
        direction="neutral"
        source="INE / ETDP"
        href="/vivienda/compraventas"
        sparklineData={mercado_mes.map(d => d.compraventas_12m_1000)}
    />
    <KpiCard
        title="Años de salario para 90 m²"
        value={esfuerzo.slice(-1)[0]?.anios_salario}
        formattedValue="{formatNumber(esfuerzo.slice(-1)[0]?.anios_salario, 1)} años"
        period="salario bruto medio íntegro, {esfuerzo.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="Ministerio de Vivienda / INE"
        href="/vivienda/esfuerzo"
        sparklineData={esfuerzo.map(d => d.anios_salario)}
    />
</Grid>

## El precio, con y sin inflación

Valor tasado medio de la vivienda libre en euros por metro cuadrado. Descontada la inflación, el máximo de la serie es de {hitos[0]?.periodo_max} y el mínimo tras la crisis, de {hitos[0]?.periodo_min}. Hoy el metro cuadrado está {#if hitos[0]?.vs_max < 0}un {formatNumber(-hitos[0]?.vs_max, 0)} % por debajo de aquel máximo{:else}en máximos{/if} y un {formatNumber(hitos[0]?.vs_min, 0)} % por encima del mínimo.

<LineChart
    data={precio_largo}
    x=fecha
    y=euros_m2
    series=serie
    yFmt='#,##0" €"'
    yAxisTitle="€/m²"
    startingAtZero={false}
    title="Valor tasado de la vivienda libre en España: euros de {precio[0]?.anio_base} frente a euros de cada año"
/>

## Cuántas se compran y cuántas se hipotecan

Compraventas de viviendas inscritas en los registros de la propiedad e hipotecas constituidas sobre viviendas, por cada 1.000 habitantes y año.

<BarChart
    data={mercado_anual}
    x=anio
    y=por_1000
    series=operacion
    type=grouped
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="por 1.000 habitantes"
    title="Compraventas e hipotecas de viviendas por 1.000 habitantes"
/>

## Por comunidad

Precio real del metro cuadrado en el último trimestre. Pulsa en una comunidad para ver su ficha.

<AreaMap
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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio de Vivienda, INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'euros_m2_real', title: '€/m²', fmt: '#,##0'},
        {id: 'precio_interanual_real', title: 'Variación real anual (%)', fmt: '0.0'},
        {id: 'alquiler_mes_mediana_real', title: 'Alquiler mediano (€/mes)', fmt: '#,##0'},
        {id: 'anios_salario', title: 'Años de salario (90 m²)', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidad" />
    <Column id=euros_m2_real title="€/m² (real)" fmt='#,##0' />
    <Column id=precio_interanual_real title="Var. real anual %" fmt='0.0' contentType=delta />
    <Column id=precio_vs_maximo_real title="Vs. máximo real %" fmt='0.0' />
    <Column id=alquiler_mes_mediana_real title="Alquiler €/mes" fmt='#,##0' />
    <Column id=compraventas_12m_1000 title="Compraventas por 1.000 hab." fmt='0.0' />
    <Column id=anios_salario title="Años de salario" fmt='0.0' />
</DataTable>

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/vivienda/precios" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">💶</span> Precios</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Valor tasado por comunidad, provincia y municipio y el Índice de Precios de Vivienda del INE, nueva y de segunda mano, descontada la inflación.</p>
    </a>
    <a href="/vivienda/alquiler" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔑</span> Alquiler</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Alquiler mediano por comunidad, provincia y municipio con los datos del IRPF, y cuántas viviendas se alquilan.</p>
    </a>
    <a href="/vivienda/compraventas" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">📝</span> Compraventas e hipotecas</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Viviendas vendidas e hipotecadas por 1.000 habitantes, obra nueva frente a segunda mano e importe medio de la hipoteca.</p>
    </a>
    <a href="/vivienda/construccion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏗️</span> Obra nueva</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Viviendas libres que se empiezan y se terminan cada año por 1.000 habitantes, desde 1991.</p>
    </a>
    <a href="/vivienda/esfuerzo" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">⚖️</span> Esfuerzo</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Cuántos años de salario cuesta una vivienda y qué parte del sueldo se va en el alquiler, por comunidad.</p>
    </a>
</div>

---

**Fuentes:** [Ministerio de Vivienda y Agenda Urbana, boletín estadístico](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000) (valor tasado y obra nueva), [Sistema Estatal de Referencia del Precio del Alquiler](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi), [INE, Estadística de Transmisiones de Derechos de la Propiedad](https://www.ine.es/jaxiT3/Tabla.htm?t=6150), [INE, Estadística de Hipotecas](https://www.ine.es/jaxiT3/Tabla.htm?t=13896) y [INE, Encuesta Trimestral de Coste Laboral](https://www.ine.es/jaxiT3/Tabla.htm?t=6061). Deflactado con el IPC general del INE (base 2025).
