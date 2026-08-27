---
title: Energía y Clima
description: Transición ecológica, mix de generación eléctrica y emisiones de gases de efecto invernadero en España.
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import DownloadCsvButton from '../../../../../src/lib/components/DownloadCsvButton.svelte';
</script>

# 🌱 Energía, Clima y Transición Ecológica

España se ha posicionado como uno de los líderes europeos en despliegue de energías renovables. Esta sección presenta las cifras oficiales del sistema eléctrico, las emisiones de gases de efecto invernadero y la evolución de la potencia instalada renovable.

```sql resumen_ultimo
SELECT * FROM clima_energia.resumen_anual_mix
ORDER BY año DESC
LIMIT 1
```

```sql resumen_previo
SELECT * FROM clima_energia.resumen_anual_mix
ORDER BY año DESC
LIMIT 2
```

```sql resumen_serie
SELECT año, cuota_renovable_pct AS valor
FROM clima_energia.resumen_anual_mix
ORDER BY año ASC
```

```sql emisiones_totales
SELECT
    año,
    sum(millones_toneladas_co2eq) AS total_emisiones
FROM clima_energia.emisiones_gei
GROUP BY año
ORDER BY año DESC
```

```sql potencia_solar
SELECT potencia_mw
FROM clima_energia.potencia_instalada
WHERE tecnologia = 'Solar Fotovoltaica' AND año = 2024
```

```sql potencia_eolica
SELECT potencia_mw
FROM clima_energia.potencia_instalada
WHERE tecnologia = 'Eólica' AND año = 2024
```

<Grid cols=4>
    <KpiCard
        title="Cuota Renovable"
        value={resumen_ultimo[0]?.cuota_renovable_pct}
        unit="%"
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
        source="MITECO – Inventario GEI"
        href="/energia-clima/emisiones"
    />
    <KpiCard
        title="Potencia Solar FV"
        value={potencia_solar[0]?.potencia_mw ? (potencia_solar[0].potencia_mw / 1000).toFixed(1) : null}
        unit=" GW"
        source="Red Eléctrica de España"
        href="/energia-clima/mix-electrico"
    />
    <KpiCard
        title="Potencia Eólica"
        value={potencia_eolica[0]?.potencia_mw ? (potencia_eolica[0].potencia_mw / 1000).toFixed(1) : null}
        unit=" GW"
        source="Red Eléctrica de España"
        href="/energia-clima/mix-electrico"
    />
</Grid>

---

## Evolución del Mix Eléctrico Nacional (2015 – 2024)

El sistema eléctrico español ha protagonizado una transformación histórica: la eólica y la solar fotovoltaica han pasado de representar el ~21% a superar el **40%** de la generación total, mientras que el carbón ha colapsado del 20% a menos del 1%.

```sql mix_areas
SELECT
    año,
    tecnologia,
    generacion_twh
FROM clima_energia.mix_electrico
WHERE tecnologia IN ('Eólica', 'Solar Fotovoltaica', 'Hidroeléctrica', 'Nuclear', 'Ciclos Combinados (Gas)', 'Carbón')
ORDER BY año ASC, tecnologia ASC
```

<AreaChart
    data={mix_areas}
    x=año
    y=generacion_twh
    series=tecnologia
    yAxisTitle="Generación (TWh)"
    xAxisTitle="Año"
    title="Generación eléctrica por tecnología (TWh)"
    colorPalette={['#16a34a', '#facc15', '#3b82f6', '#a855f7', '#f97316', '#6b7280']}
/>

<DownloadCsvButton data={mix_areas} filename="spainfacts_mix_electrico.csv" label="Descargar mix eléctrico (CSV)" />

---

## Cuota de Energía Renovable y Libre de Emisiones

```sql cuota_anual
SELECT
    año,
    cuota_renovable_pct AS "Renovable (%)",
    cuota_libre_emisiones_pct AS "Libre de emisiones (%) (Renovable + Nuclear)"
FROM clima_energia.resumen_anual_mix
ORDER BY año ASC
```

<LineChart
    data={cuota_anual}
    x=año
    y={["Renovable (%)", "Libre de emisiones (%) (Renovable + Nuclear)"]}
    yAxisTitle="Porcentaje del total (%)"
    title="Cuota de generación limpia sobre el total eléctrico"
    colorPalette={['#16a34a', '#3b82f6']}
    yMin=30
    yMax=85
/>

---

## Emisiones de Gases de Efecto Invernadero por Sector

El **transporte** es el sector más resistente a la descarbonización, concentrando más del 36% de las emisiones en 2024. En cambio, la **generación eléctrica** ha reducido sus emisiones más de un 70% desde 2015 gracias al despliegue renovable.

```sql emisiones_sector
SELECT
    año,
    sector,
    millones_toneladas_co2eq
FROM clima_energia.emisiones_gei
ORDER BY año ASC, sector ASC
```

<BarChart
    data={emisiones_sector}
    x=año
    y=millones_toneladas_co2eq
    series=sector
    type=stacked
    yAxisTitle="Millones de toneladas de CO₂eq"
    title="Emisiones GEI por sector (Mt CO₂eq)"
/>

<DownloadCsvButton data={emisiones_sector} filename="spainfacts_emisiones_gei.csv" label="Descargar emisiones GEI (CSV)" />

---

## Informes Detallados

<Grid cols=2>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-green-300 dark:hover:border-green-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-950/60 text-green-600 dark:text-green-400 flex items-center justify-center font-bold text-xl mb-4">
            ⚡
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Mix de Generación Eléctrica</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Análisis profundo del mix eléctrico: el auge de la eólica y solar FV, el cierre del carbón, la dependencia del gas natural y el papel de la nuclear.
        </p>
    </div>
    <a href="/energia-clima/mix-electrico" class="text-sm font-semibold text-green-600 dark:text-green-400 hover:underline inline-flex items-center">
        Ver informe del mix eléctrico →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-amber-300 dark:hover:border-amber-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-amber-100 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center font-bold text-xl mb-4">
            🏭
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Emisiones y Descarbonización</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Desglose sectorial de los gases de efecto invernadero: por qué el transporte es el gran reto pendiente y cómo la electricidad ya se está descarbonizando.
        </p>
    </div>
    <a href="/energia-clima/emisiones" class="text-sm font-semibold text-amber-600 dark:text-amber-400 hover:underline inline-flex items-center">
        Ver informe de emisiones →
    </a>
</div>

</Grid>

---

## Metodología y Fuentes Primarias

| Organismo | Dataset | Código | Licencia |
|:---|:---|:---|:---|
| **Red Eléctrica de España (REE)** | Estadísticas del Sistema Eléctrico | [REE-MIX](https://www.ree.es/es/datos/generacion) | Datos Abiertos / RISP |
| **MITECO** | Inventario Nacional de Emisiones GEI | [MITECO-GEI](https://www.miteco.gob.es/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/inventario-gei.html) | RISP (Ley 37/2007) |

> Los datos de generación eléctrica proceden del balance medido en barras de central por REE como Operador del Sistema. Las emisiones se calculan según las directrices del IPCC y se reportan a la Convención Marco de Naciones Unidas sobre el Cambio Climático (CMNUCC).

<LastRefreshed prefix="Última sincronización de datos con fuentes oficiales" />
