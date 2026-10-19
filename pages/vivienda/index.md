---
title: Vivienda
description: "Precio de la vivienda en España descontada la inflación, alquiler, compraventas e hipotecas por 1.000 habitantes, obra nueva y cuántos años de salario cuesta una casa, por comunidad y provincia."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../src/lib/components/MapaEspana.svelte';
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

<div class="sf-topic-banner not-prose">
    <div class="mb-3 flex flex-wrap items-center gap-2 text-xs font-medium text-slate-500 dark:text-slate-400">
        <a href="/" class="hover:underline text-slate-500 dark:text-slate-400 no-underline">Inicio</a>
        <span>/</span>
        <span class="font-semibold" style="color: var(--sf-topic-color)">Vivienda</span>
    </div>
    <div class="flex items-start gap-3.5">
        <div class="sf-icon-box mt-1">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
        </div>
        <div>
            <h1 class="font-editorial text-2xl sm:text-3xl font-bold tracking-tight text-slate-900 dark:text-white m-0">Vivienda</h1>
            <p class="mt-1.5 text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed m-0">
                Cuánto cuesta comprar o alquilar una casa en España, cuántas se venden y cuántas se construyen. Los precios se muestran <strong>descontada la inflación</strong> (en euros de {precio.slice(-1)[0]?.anio_base}) y las operaciones <strong>por cada 1.000 habitantes</strong>, para poder comparar años y territorios.
            </p>
        </div>
    </div>
    <div class="mt-4 pt-3 border-t border-slate-200/80 dark:border-slate-800 flex flex-wrap items-center gap-2 text-xs text-slate-500 dark:text-slate-400">
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Por 1.000 habitantes</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Euros constantes ({precio.slice(-1)[0]?.anio_base})</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">MIVAU · SERPAVI · INE</span>
    </div>
</div>

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
        sparklineData={precio.filter(d => d.euros_m2_real != null).map(d => ({...d, y: d.euros_m2_real}))}
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
        sparklineData={alquiler.map(d => ({...d, y: d.alquiler_mes_mediana_real}))}
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
        sparklineData={mercado_mes.map(d => ({...d, y: d.compraventas_12m_1000}))}
    />
    <KpiCard
        title="Años de salario para 90 m²"
        value={esfuerzo.slice(-1)[0]?.anios_salario}
        formattedValue="{formatNumber(esfuerzo.slice(-1)[0]?.anios_salario, 1)} años"
        period="salario bruto medio íntegro, {esfuerzo.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="Ministerio de Vivienda / INE"
        href="/vivienda/esfuerzo"
        sparklineData={esfuerzo.map(d => ({...d, y: d.anios_salario}))}
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
    title="Valor tasado de la vivienda libre en España: euros de {precio.slice(-1)[0]?.anio_base} frente a euros de cada año"
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

## Explora en detalle

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/vivienda/precios" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/><polyline points="17 6 23 6 23 12"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Precios</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Valor tasado por comunidad, provincia y municipio y el Índice de Precios de Vivienda del INE, nueva y de segunda mano, descontada la inflación.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/vivienda/alquiler" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="7.5" cy="15.5" r="5.5"/><path d="m21 2-9.6 9.6"/><path d="m15.5 7.5 3 3L22 7l-3-3"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Alquiler</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Alquiler mediano por comunidad, provincia y municipio con los datos del IRPF, y cuántas viviendas se alquilan.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/vivienda/compraventas" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Compraventas e hipotecas</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Viviendas vendidas e hipotecadas por 1.000 habitantes, obra nueva frente a segunda mano e importe medio de la hipoteca.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/vivienda/construccion" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="6" width="20" height="8" rx="1"/><path d="M17 14v7"/><path d="M7 14v7"/><path d="M17 3v3"/><path d="M7 3v3"/><path d="M10 14 2.3 6.3"/><path d="m14 6 7.7 7.7"/><path d="m8 6 8 8"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Obra nueva</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Viviendas libres que se empiezan y se terminan cada año por 1.000 habitantes, desde 1991.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/vivienda/esfuerzo" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m16 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="m2 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="M7 21h10"/><path d="M12 3v18"/><path d="M3 7h2c2 0 5-1 7-2 2 1 5 2 7 2h2"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Esfuerzo</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Cuántos años de salario cuesta una vivienda y qué parte del sueldo se va en el alquiler, por comunidad.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/vivienda/vivienda-publica" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="2" width="16" height="20" rx="2" ry="2"/><path d="M9 22v-4h6v4"/><path d="M8 6h.01"/><path d="M16 6h.01"/><path d="M12 6h.01"/><path d="M12 10h.01"/><path d="M12 14h.01"/><path d="M16 10h.01"/><path d="M16 14h.01"/><path d="M8 10h.01"/><path d="M8 14h.01"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Vivienda pública en alquiler</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Viviendas públicas en alquiler por 1.000 habitantes por comunidad, provincia y municipio, frente a Países Bajos, Austria, Francia y la media europea, y por partido.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
</div>

<div class="sf-sources-footer">

**Fuentes:** [Ministerio de Vivienda y Agenda Urbana, boletín estadístico](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000) (valor tasado y obra nueva), [Sistema Estatal de Referencia del Precio del Alquiler](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi), [INE, Estadística de Transmisiones de Derechos de la Propiedad](https://www.ine.es/jaxiT3/Tabla.htm?t=6150), [INE, Estadística de Hipotecas](https://www.ine.es/jaxiT3/Tabla.htm?t=13896) y [INE, Encuesta Trimestral de Coste Laboral](https://www.ine.es/jaxiT3/Tabla.htm?t=6061). Deflactado con el IPC general del INE (base 2025).

</div>
