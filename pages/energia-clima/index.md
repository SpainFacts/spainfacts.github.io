---
title: Energía y Clima
description: Transición ecológica, mix de generación eléctrica y emisiones de gases de efecto invernadero en España.
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import { formatDecimal } from '../../../../../src/lib/utils.js';
</script>

<div class="sf-topic-banner not-prose">
    <div class="mb-3 flex flex-wrap items-center gap-2 text-xs font-medium text-slate-500 dark:text-slate-400">
        <a href="/" class="hover:underline text-slate-500 dark:text-slate-400 no-underline">Inicio</a>
        <span>/</span>
        <span class="font-semibold" style="color: var(--sf-topic-color)">Energía y Clima</span>
    </div>
    <div class="flex items-start gap-3.5">
        <div class="sf-icon-box mt-1">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
        </div>
        <div>
            <h1 class="font-editorial text-2xl sm:text-3xl font-bold tracking-tight text-slate-900 dark:text-white m-0">Energía, Clima y Transición Ecológica</h1>
            <p class="mt-1.5 text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed m-0">
                En {resumen_ultimo[0]?.anio}, las renovables generaron el {formatDecimal(resumen_ultimo[0]?.cuota_renovable_pct)} % de la electricidad en España, según Red Eléctrica. Esta sección presenta las cifras oficiales del sistema eléctrico, las emisiones de gases de efecto invernadero y la evolución de la potencia instalada renovable.
            </p>
        </div>
    </div>
    <div class="mt-4 pt-3 border-t border-slate-200/80 dark:border-slate-800 flex flex-wrap items-center gap-2 text-xs text-slate-500 dark:text-slate-400">
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Por habitante y %</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Tiempo real (REE 5 min)</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">REE · MITECO · AEMET · Eurostat</span>
    </div>
</div>

```sql resumen_ultimo
SELECT * FROM mother.energia_resumen_anual_mix
ORDER BY anio DESC
LIMIT 1
```

```sql resumen_previo
SELECT * FROM mother.energia_resumen_anual_mix
ORDER BY anio DESC
LIMIT 2
```

```sql resumen_serie
SELECT anio, cuota_renovable_pct AS valor
FROM mother.energia_resumen_anual_mix
ORDER BY anio ASC
```

```sql emisiones_totales
SELECT
    anio,
    sum(millones_toneladas_co2eq) AS total_emisiones
FROM mother.energia_emisiones_gei
GROUP BY anio
ORDER BY anio DESC
```

```sql potencia_solar
SELECT potencia_mw, anio
FROM mother.energia_potencia_instalada
WHERE tecnologia = 'Solar Fotovoltaica'
  AND anio = (SELECT max(anio) FROM mother.energia_potencia_instalada)
```

```sql potencia_eolica
SELECT potencia_mw, anio
FROM mother.energia_potencia_instalada
WHERE tecnologia = 'Eólica'
  AND anio = (SELECT max(anio) FROM mother.energia_potencia_instalada)
```

```sql potencia_serie
SELECT
    anio,
    sum(potencia_mw) FILTER (WHERE tecnologia = 'Solar Fotovoltaica') AS solar_mw,
    sum(potencia_mw) FILTER (WHERE tecnologia = 'Eólica') AS eolica_mw
FROM mother.energia_potencia_instalada
GROUP BY anio
ORDER BY anio ASC
```

<Grid cols=4>
    <KpiCard
        title="Cuota Renovable"
        value={resumen_ultimo[0]?.cuota_renovable_pct}
        unit="%"
        period={resumen_ultimo[0]?.anio}
        change={resumen_previo.length > 1 ? (resumen_previo[0].cuota_renovable_pct - resumen_previo[1].cuota_renovable_pct).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="vs año ant."
        direction="positive-up"
        source="Red Eléctrica de España (REE)"
        href="/energia-clima/mix-electrico"
        sparklineData={resumen_serie}
    />
    <KpiCard
        title="Emisiones Totales CO₂eq"
        value={emisiones_totales[0]?.total_emisiones}
        unit=" Mt"
        change={emisiones_totales.length > 1 ? (emisiones_totales[0].total_emisiones - emisiones_totales[1].total_emisiones).toFixed(1) : null}
        changeUnit=" Mt"
        changePeriod="vs año ant."
        direction="positive-down"
        period={emisiones_totales[0]?.anio}
        source="Inventario GEI (MITECO) vía Eurostat"
        href="/energia-clima/emisiones"
        sparklineData={[...emisiones_totales].reverse().map(d => ({...d, valor: d.total_emisiones}))}
    />
    <KpiCard
        title="Potencia Solar FV"
        value={potencia_solar[0]?.potencia_mw ? (potencia_solar[0].potencia_mw / 1000).toFixed(1) : null}
        unit=" GW"
        period={potencia_solar[0]?.anio}
        source="Eurostat (nrg_inf_epc)"
        href="/energia-clima/mix-electrico"
        sparklineData={potencia_serie.map(d => ({...d, valor: d.solar_mw / 1000}))}
    />
    <KpiCard
        title="Potencia Eólica"
        value={potencia_eolica[0]?.potencia_mw ? (potencia_eolica[0].potencia_mw / 1000).toFixed(1) : null}
        unit=" GW"
        period={potencia_eolica[0]?.anio}
        source="Eurostat (nrg_inf_epc)"
        href="/energia-clima/mix-electrico"
        sparklineData={potencia_serie.map(d => ({...d, valor: d.eolica_mw / 1000}))}
    />
</Grid>

---

## Evolución del Mix Eléctrico Nacional

```sql mix_hitos
SELECT
    anio,
    round(sum(cuota_pct) FILTER (WHERE tecnologia IN ('Eólica', 'Solar Fotovoltaica')), 1) AS pct_eolica_solar,
    round(sum(cuota_pct) FILTER (WHERE tecnologia = 'Carbón'), 1) AS pct_carbon
FROM mother.energia_mix_electrico
WHERE anio IN ((SELECT min(anio) FROM mother.energia_mix_electrico), (SELECT max(anio) FROM mother.energia_mix_electrico))
GROUP BY anio
ORDER BY anio ASC
```

El sistema eléctrico español ha protagonizado una transformación histórica: entre {mix_hitos[0]?.anio} y {mix_hitos[1]?.anio}, la eólica y la solar fotovoltaica han pasado de representar el {formatDecimal(mix_hitos[0]?.pct_eolica_solar)}% a un **{formatDecimal(mix_hitos[1]?.pct_eolica_solar)}%** de la generación total, mientras que el carbón ha caído del {formatDecimal(mix_hitos[0]?.pct_carbon)}% al {formatDecimal(mix_hitos[1]?.pct_carbon)}%.

```sql mix_areas
SELECT
    anio,
    tecnologia,
    generacion_twh
FROM mother.energia_mix_electrico
WHERE tecnologia IN ('Eólica', 'Solar Fotovoltaica', 'Hidroeléctrica', 'Nuclear', 'Ciclos Combinados (Gas)', 'Carbón')
ORDER BY anio ASC, tecnologia ASC
```

<AreaChart
    data={mix_areas}
    x=anio
    y=generacion_twh
    series=tecnologia
    yAxisTitle="Generación (TWh)"
    xAxisTitle="Año"
    title="Generación eléctrica por tecnología (TWh)"
    colorPalette={['#16a34a', '#facc15', '#3b82f6', '#a855f7', '#f97316', '#6b7280']}
/>

---

## Cuota de Energía Renovable y Libre de Emisiones

```sql cuota_anual
SELECT
    anio,
    cuota_renovable_pct AS "Renovable (%)",
    cuota_libre_emisiones_pct AS "Libre de emisiones (%) (Renovable + Nuclear)"
FROM mother.energia_resumen_anual_mix
ORDER BY anio ASC
```

<LineChart
    data={cuota_anual}
    x=anio
    y={["Renovable (%)", "Libre de emisiones (%) (Renovable + Nuclear)"]}
    yAxisTitle="Porcentaje del total (%)"
    title="Cuota de generación limpia sobre el total eléctrico"
    colorPalette={['#16a34a', '#3b82f6']}
    yMin=0
    yMax=85
/>

---

## Emisiones de Gases de Efecto Invernadero por Sector

```sql emisiones_hitos
SELECT
    anio,
    round(max(cuota_pct) FILTER (WHERE sector = 'Transporte'), 1) AS pct_transporte,
    max(millones_toneladas_co2eq) FILTER (WHERE sector = 'Generación Eléctrica') AS mt_electrica
FROM mother.energia_emisiones_gei
WHERE anio IN ((SELECT min(anio) FROM mother.energia_emisiones_gei), (SELECT max(anio) FROM mother.energia_emisiones_gei))
GROUP BY anio
ORDER BY anio ASC
```

El **transporte** es el sector más resistente a la descarbonización: concentra el **{formatDecimal(emisiones_hitos[1]?.pct_transporte)}%** de las emisiones en {emisiones_hitos[1]?.anio}. En cambio, la **generación eléctrica** ha reducido sus emisiones un {emisiones_hitos.length > 1 ? ((1 - emisiones_hitos[1].mt_electrica / emisiones_hitos[0].mt_electrica) * 100).toFixed(0) : null}% desde {emisiones_hitos[0]?.anio} gracias al despliegue renovable.

```sql emisiones_sector
SELECT
    anio,
    sector,
    millones_toneladas_co2eq,
    t_co2eq_hab
FROM mother.energia_emisiones_gei
ORDER BY anio ASC, sector ASC
```

<BarChart
    data={emisiones_sector}
    x=anio
    y=millones_toneladas_co2eq
    series=sector
    type=stacked
    yAxisTitle="Millones de toneladas de CO₂eq"
    title="Emisiones GEI por sector (Mt CO₂eq)"
/>

<BarChart
    data={emisiones_sector}
    x=anio
    y=t_co2eq_hab
    series=sector
    type=stacked
    yAxisTitle="Toneladas de CO₂eq por habitante"
    title="Emisiones GEI por sector, por habitante (t CO₂eq por habitante)"
/>

---

## Informes Detallados

<Grid cols=2>

<a href="/energia-clima/mix-electrico" class="sf-subtopic-card no-underline">
    <div class="sf-icon-box">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
    </div>
    <h3 class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-1">Mix de Generación Eléctrica</h3>
    <p class="text-sm text-slate-600 dark:text-slate-400 m-0 leading-relaxed">
        Análisis profundo del mix eléctrico: el auge de la eólica y solar FV, el cierre del carbón, la dependencia del gas natural y el papel de la nuclear.
    </p>
    <span class="sf-card-cta">Ver informe del mix eléctrico →</span>
</a>

<a href="/energia-clima/emisiones" class="sf-subtopic-card no-underline">
    <div class="sf-icon-box">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/></svg>
    </div>
    <h3 class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-1">Emisiones y Descarbonización</h3>
    <p class="text-sm text-slate-600 dark:text-slate-400 m-0 leading-relaxed">
        Desglose sectorial de los gases de efecto invernadero: por qué el transporte es el gran reto pendiente y cómo la electricidad ya se está descarbonizando.
    </p>
    <span class="sf-card-cta">Ver informe de emisiones →</span>
</a>

<a href="/energia-clima/embalses" class="sf-subtopic-card no-underline">
    <div class="sf-icon-box">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>
    </div>
    <h3 class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-1">Reservas de Agua y Embalses</h3>
    <p class="text-sm text-slate-600 dark:text-slate-400 m-0 leading-relaxed">
        Estado semanal de los embalses por cuenca: cuánta agua hay, cómo está frente al año pasado y frente a la media de la última década.
    </p>
    <span class="sf-card-cta">Ver el estado de los embalses →</span>
</a>

<a href="/energia-clima/calor" class="sf-subtopic-card no-underline">
    <div class="sf-icon-box">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"/></svg>
    </div>
    <h3 class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-1">Calor y Temperaturas</h3>
    <p class="text-sm text-slate-600 dark:text-slate-400 m-0 leading-relaxed">
        El mapa diario del calor por provincia: cuánto se aleja la temperatura máxima de la media histórica de cada día, los récords y la tendencia desde 1991.
    </p>
    <span class="sf-card-cta">Ver el mapa del calor →</span>
</a>

<a href="/energia-clima/incendios" class="sf-subtopic-card no-underline">
    <div class="sf-icon-box">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z"/></svg>
    </div>
    <h3 class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-1">Incendios Forestales</h3>
    <p class="text-sm text-slate-600 dark:text-slate-400 m-0 leading-relaxed">
        Hectáreas quemadas cada año desde 2000, cuánto arde dentro de la Red Natura 2000, el mapa de los incendios de este año y los focos activos detectados por satélite.
    </p>
    <span class="sf-card-cta">Ver el mapa de incendios →</span>
</a>

<a href="/energia-clima/directo" class="sf-subtopic-card no-underline">
    <div class="sf-icon-box">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="2"/><path d="M16.24 7.76a6 6 0 0 1 0 8.49m-8.48-.01a6 6 0 0 1 0-8.49m11.31-2.82a10 10 0 0 1 0 14.14m-14.14 0a10 10 0 0 1 0-14.14"/></svg>
    </div>
    <h3 class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-1">El Sistema Eléctrico, Ahora</h3>
    <p class="text-sm text-slate-600 dark:text-slate-400 m-0 leading-relaxed">
        En directo cada 5 minutos: demanda, % renovable e intensidad de CO₂ de España, la Península, Baleares, Canarias, Ceuta y Melilla, intercambios con los países vecinos y el precio de la luz.
    </p>
    <span class="sf-card-cta">Ver el sistema en directo →</span>
</a>

<a href="/energia-clima/records" class="sf-subtopic-card no-underline">
    <div class="sf-icon-box">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9H4.5a2.5 2.5 0 0 1 0-5H6"/><path d="M18 9h1.5a2.5 2.5 0 0 0 0-5H18"/><path d="M4 22h16"/><path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22"/><path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22"/><path d="M18 2H6v7a6 6 0 0 0 12 0V2Z"/></svg>
    </div>
    <h3 class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-1">Récords del Sistema Eléctrico</h3>
    <p class="text-sm text-slate-600 dark:text-slate-400 m-0 leading-relaxed">
        Máximos y mínimos históricos desde 2015 con datos de REE cada 5 minutos: demanda, solar, eólica, cuota renovable, emisiones, precios e intercambios, y cuándo se batió cada récord.
    </p>
    <span class="sf-card-cta">Ver los récords →</span>
</a>

<a href="/energia-clima/centrales" class="sf-subtopic-card no-underline">
    <div class="sf-icon-box">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="3 6 9 3 15 6 21 3 21 18 15 21 9 18 3 21"/><line x1="9" y1="3" x2="9" y2="18"/><line x1="15" y1="6" x2="15" y2="21"/></svg>
    </div>
    <h3 class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-1">Centrales Eléctricas</h3>
    <p class="text-sm text-slate-600 dark:text-slate-400 m-0 leading-relaxed">
        El mapa de todas las centrales de España por tecnología y potencia: las que funcionan, las que están en obras o en tramitación y las que ya cerraron, con su propietario y sus fechas.
    </p>
    <span class="sf-card-cta">Ver el mapa de centrales →</span>
</a>

<a href="/energia-clima/almacenamiento" class="sf-subtopic-card no-underline">
    <div class="sf-icon-box">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="1" y="6" width="18" height="12" rx="2" ry="2"/><line x1="23" y1="13" x2="23" y2="11"/></svg>
    </div>
    <h3 class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-1">Almacenamiento</h3>
    <p class="text-sm text-slate-600 dark:text-slate-400 m-0 leading-relaxed">
        Bombeo hidráulico y baterías: cuánta energía guardan y devuelven, dónde están y los proyectos con permiso de conexión frente al objetivo de 2030.
    </p>
    <span class="sf-card-cta">Ver el almacenamiento →</span>
</a>

<a href="/energia-clima/electrificacion" class="sf-subtopic-card no-underline">
    <div class="sf-icon-box">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22v-5"/><path d="M9 8V2"/><path d="M15 8V2"/><path d="M18 8v5a4 4 0 0 1-4 4h-4a4 4 0 0 1-4-4V8Z"/></svg>
    </div>
    <h3 class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-1">Electrificación</h3>
    <p class="text-sm text-slate-600 dark:text-slate-400 m-0 leading-relaxed">
        Cuánta energía de la industria, el transporte, los hogares y los servicios es ya electricidad, cómo se calientan las casas en cada provincia y cuántas bombas de calor hay.
    </p>
    <span class="sf-card-cta">Ver la electrificación →</span>
</a>

</Grid>

<div class="sf-sources-footer">

## Metodología y Fuentes Primarias

| Organismo | Dataset | Código | Licencia |
|:---|:---|:---|:---|
| **Red Eléctrica de España (REE)** | Generación y demanda anual (API REData) | [REE-MIX](https://www.ree.es/es/datos/generacion) | Datos Abiertos / RISP |
| **MITECO / Eurostat** | Inventario Nacional de Emisiones GEI (env_air_gge) | [MITECO-GEI](https://www.miteco.gob.es/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/inventario-gei.html) · [Eurostat](https://ec.europa.eu/eurostat/databrowser/view/env_air_gge/default/table) | RISP (Ley 37/2007) / CC BY 4.0 |
| **Eurostat** | Capacidad eléctrica instalada (nrg_inf_epc) | [Eurostat](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_epc/default/table) | CC BY 4.0 |

> Los datos de generación eléctrica proceden del balance nacional medido en barras de central por REE como Operador del Sistema (solo años completos). Las emisiones son las del inventario oficial de España (sin LULUCF), calculadas según las directrices del IPCC y reportadas a la Convención Marco de Naciones Unidas sobre el Cambio Climático (CMNUCC); Eurostat las publica desglosadas por categoría CRF, que aquí se agrupan en sectores.

<LastRefreshed prefix="Última sincronización de datos con fuentes oficiales" />

</div>
