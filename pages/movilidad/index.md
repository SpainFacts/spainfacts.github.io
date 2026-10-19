---
title: Movilidad
description: "Movilidad en España: coches que se venden y circulan por tipo de motor, transición al coche eléctrico, puntos de recarga, viajeros de metro, autobús y tren, y pasajeros de los aeropuertos."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../src/lib/utils.js';
</script>

```sql cuota
SELECT
    mes,
    strftime(mes, '%m/%Y') AS mes_texto,
    sum(matriculaciones) FILTER (WHERE energia IN ('bev', 'phev')) / sum(matriculaciones) AS cuota_enchufables,
    sum(matriculaciones) AS turismos
FROM mother.movilidad_matriculaciones_mensual
WHERE grupo = 'turismo' AND nuevo_usado = 'N'
GROUP BY mes
ORDER BY mes
```

```sql cuota_ultimo
SELECT c.*, a.cuota_enchufables AS cuota_anio_antes
FROM ${cuota} c
LEFT JOIN ${cuota} a ON a.mes = c.mes - INTERVAL 12 MONTH
ORDER BY c.mes DESC
LIMIT 1
```

```sql parque
SELECT
    strftime(mes, '%m/%Y') AS mes_texto,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo') AS turismos,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo' AND energia IN ('bev', 'phev')) AS turismos_enchufables,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo' AND distintivo = 'SIN') AS turismos_sin_distintivo,
    any_value((SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total' ORDER BY anio DESC LIMIT 1)) AS poblacion
FROM mother.movilidad_parque_provincia
GROUP BY mes
ORDER BY mes DESC
```

```sql parque_mensual
SELECT mes, turismos_1000 AS valor
FROM mother.movilidad_parque_resumen
ORDER BY mes
```

```sql recarga
SELECT sum(puntos) AS puntos, sum(puntos_rapidos) AS rapidos, (SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total' ORDER BY anio DESC LIMIT 1) AS poblacion FROM mother.movilidad_recarga_provincia
```

```sql transporte
SELECT
    strftime(mes, '%m/%Y') AS mes_texto,
    viajeros,
    (SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total' ORDER BY anio DESC LIMIT 1) AS poblacion
FROM mother.movilidad_transporte_modos
WHERE clave = 'total'
ORDER BY mes DESC
LIMIT 1
```

```sql transporte_serie
-- Viajeros por cada 1.000 habitantes, últimos 36 meses
SELECT t.mes, t.viajeros_por_1000_hab AS valor
FROM mother.movilidad_transporte_modos AS t
WHERE t.clave = 'total'
  AND t.mes >= (SELECT max(mes) FROM mother.movilidad_transporte_modos) - INTERVAL 35 MONTH
ORDER BY t.mes
```

<div class="sf-topic-banner not-prose">
    <div class="mb-3 flex flex-wrap items-center gap-2 text-xs font-medium text-slate-500 dark:text-slate-400">
        <a href="/" class="hover:underline text-slate-500 dark:text-slate-400 no-underline">Inicio</a>
        <span>/</span>
        <span class="font-semibold" style="color: var(--sf-topic-color)">Movilidad</span>
    </div>
    <div class="flex items-start gap-3.5">
        <div class="sf-icon-box mt-1">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="3" width="16" height="16" rx="2"/><path d="M4 11h16"/><path d="M12 3v8"/><path d="m8 19-2 3"/><path d="m18 22-2-3"/><path d="M8 15h0"/><path d="M16 15h0"/></svg>
        </div>
        <div>
            <h1 class="font-editorial text-2xl sm:text-3xl font-bold tracking-tight text-slate-900 dark:text-white m-0">Movilidad</h1>
            <p class="mt-1.5 text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed m-0">
                Cómo nos movemos en España: los coches que se compran y los que circulan, el avance del coche eléctrico, dónde se puede recargar, cuántos viajeros usan el transporte público y cuántos pasajeros pasan por los aeropuertos.
            </p>
        </div>
    </div>
    <div class="mt-4 pt-3 border-t border-slate-200/80 dark:border-slate-800 flex flex-wrap items-center gap-2 text-xs text-slate-500 dark:text-slate-400">
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Por 1.000 habitantes</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Provincias y municipios</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">DGT · INE · AENA · MITECO</span>
    </div>
</div>

<Grid cols=4>
    <KpiCard
        title="Turismos nuevos enchufables"
        value={cuota_ultimo[0]?.cuota_enchufables * 100}
        formattedValue={formatNumber(cuota_ultimo[0]?.cuota_enchufables * 100, 1)}
        unit="%"
        period="eléctricos + híbridos enchufables · {cuota_ultimo[0]?.mes_texto}"
        change={cuota_ultimo[0]?.cuota_anio_antes != null ? ((cuota_ultimo[0].cuota_enchufables - cuota_ultimo[0].cuota_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. un año antes"
        direction="positive-up"
        source="DGT"
        href="/movilidad/coche-electrico"
        sparklineData={cuota.map(d => ({...d, valor: d.cuota_enchufables * 100}))}
    />
    <KpiCard
        title="Turismos en circulación"
        value={parque[0]?.turismos}
        formattedValue="{formatNumber(1000 * parque[0]?.turismos / parque[0]?.poblacion, 0)} por 1.000 hab."
        period="{formatCompact(parque[0]?.turismos, 1)} turismos · {formatNumber(parque[0]?.turismos_enchufables / parque[0]?.turismos / 0.01, 1)} % enchufables · {parque[0]?.mes_texto}"
        source="DGT"
        href="/movilidad/parque"
        sparklineData={parque_mensual}
    />
    <KpiCard
        title="Puntos de recarga públicos"
        value={recarga[0]?.puntos}
        formattedValue="{formatNumber(100000 * recarga[0]?.puntos / recarga[0]?.poblacion, 0)} por 100.000 hab."
        period="{formatNumber(recarga[0]?.puntos, 0)} puntos, {formatNumber(recarga[0]?.rapidos, 0)} rápidos (≥50 kW)"
        source="NAP DGT / MITECO"
        href="/movilidad/recarga"
    />
    <KpiCard
        title="Viajeros de transporte público"
        value={transporte[0]?.viajeros}
        formattedValue="{formatNumber(transporte[0]?.viajeros / transporte[0]?.poblacion, 1)} viajes por hab."
        period="al mes · {formatCompact(transporte[0]?.viajeros, 1)} viajeros · {transporte[0]?.mes_texto}"
        source="INE"
        href="/movilidad/transporte-publico"
        sparklineData={transporte_serie}
    />
</Grid>

## Vehículos y modos de transporte

<div class="grid grid-cols-1 md:grid-cols-2 gap-4 not-prose my-6">
    <a href="/movilidad/coche-electrico" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Coche eléctrico</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Turismos nuevos por tipo de motor cada mes desde 2015, cuota de eléctricos por provincia y emisiones de CO2.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/movilidad/marcas-y-modelos" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/><circle cx="7" cy="17" r="2"/><path d="M9 17h6"/><circle cx="17" cy="17" r="2"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Marcas y modelos más vendidos</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Ranking mensual de coches, motos, furgonetas, camiones y autobuses por marca, modelo y grupo, filtrable por motor y por canal (particulares o flotas).</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/movilidad/parque" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M9 17V7h4a3 3 0 0 1 0 6H9"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Parque de vehículos</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Los vehículos que circulan hoy: motor, etiqueta ambiental, antigüedad y modelos más comunes, por provincia y municipio.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/movilidad/camiones-y-autobuses" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 17h4V5H2v12h3"/><path d="M20 17h2v-3.34a4 4 0 0 0-1.17-2.83L19 9h-5v8h1"/><circle cx="7.5" cy="17.5" r="2.5"/><circle cx="17.5" cy="17.5" r="2.5"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Camiones y autobuses</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Matriculaciones por tipo de motor, avance del autobús eléctrico, grupos más vendidos y antigüedad de los que circulan.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/movilidad/flotas-e-impuestos" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Los paraísos fiscales de las flotas</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Pueblos de unas decenas de vecinos con miles de coches de empresa: dónde se matriculan las flotas para pagar menos impuesto de circulación.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/movilidad/recarga" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22v-5"/><path d="M9 8V2"/><path d="M15 8V2"/><path d="M18 8v5a4 4 0 0 1-4 4h-4a4 4 0 0 1-4-4V8Z"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Puntos de recarga</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Mapa de los puntos públicos por potencia y operador, y coches enchufables por punto en cada provincia.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/movilidad/transporte-publico" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="4" y="3" width="16" height="16" rx="2"/><path d="M4 11h16"/><path d="M12 3v8"/><path d="m8 19-2 3"/><path d="m18 22-2-3"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Transporte público</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Viajeros de metro, autobús, Cercanías, AVE y avión cada mes, y el metro de las siete ciudades que lo tienen.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/movilidad/aeropuertos" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Aeropuertos</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Pasajeros, vuelos y mercancía de cada aeropuerto de AENA desde 2004, cuánto tráfico es nacional o internacional y cómo se comparan con los grandes aeropuertos europeos.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
</div>

## Infraestructuras

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/movilidad/carreteras" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19 8 5"/><path d="m16 5 4 14"/><path d="M12 6v2"/><path d="M12 11v2"/><path d="M12 16v2"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Carreteras</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Mapa de todas las carreteras según las gestione el Estado, la comunidad o la diputación, cuáles son de peaje, cuántos vehículos pasan por cada tramo y la comparación con Europa.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/movilidad/ferrocarril" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><line x1="4" y1="22" x2="4" y2="15"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Red de ferrocarril</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Mapa de todas las vías de tren y de cuántos trenes de viajeros pasan al día por cada tramo y estación, con la comparación con Europa.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/movilidad/gasolineras" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="22" x2="15" y2="22"/><line x1="4" y1="9" x2="14" y2="9"/><path d="M14 22V4a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v18"/><path d="M14 13h2a2 2 0 0 1 2 2v2a2 2 0 0 0 2 2h0a2 2 0 0 0 2-2V9.83a2 2 0 0 0-.59-1.42L18 5"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Gasolineras y carburantes</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">Las 11.500 gasolineras por marca y grupo, pueblos sin ninguna, precio del gasóleo y la gasolina desde 2007 en euros reales e impuestos frente a la UE.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
    <a href="/movilidad/oleoductos" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12h20"/><path d="M6 8v8"/><path d="M18 8v8"/><circle cx="12" cy="12" r="3"/></svg>
        </div>
        <p class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-0">Oleoductos y gasoductos</p>
        <p class="text-sm text-slate-600 dark:text-slate-400 mt-1 mb-0">La red de oleoductos de Exolum, cuánto combustible va por tubo, barco o camión, los gasoductos y regasificadoras y de dónde viene el gas.</p>
        <span class="sf-card-cta">Explorar datos →</span>
    </a>
</div>

<div class="sf-sources-footer">
<LastRefreshed prefix="Datos actualizados" />
</div>
