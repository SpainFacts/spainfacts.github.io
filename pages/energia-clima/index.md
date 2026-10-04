---
title: Energía y Clima
description: Transición ecológica, mix de generación eléctrica y emisiones de gases de efecto invernadero en España.
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import DownloadCsvButton from '../../../../../src/lib/components/DownloadCsvButton.svelte';
</script>

# 🌱 Energía, Clima y Transición Ecológica

España se ha posicionado como uno de los líderes europeos en despliegue de energías renovables. Esta sección presenta las cifras oficiales del sistema eléctrico, las emisiones de gases de efecto invernadero y la evolución de la potencia instalada renovable.

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
        sparklineData={[...emisiones_totales].reverse().map(d => ({valor: d.total_emisiones}))}
    />
    <KpiCard
        title="Potencia Solar FV"
        value={potencia_solar[0]?.potencia_mw ? (potencia_solar[0].potencia_mw / 1000).toFixed(1) : null}
        unit=" GW"
        period={potencia_solar[0]?.anio}
        source="Eurostat (nrg_inf_epc)"
        href="/energia-clima/mix-electrico"
        sparklineData={potencia_serie.map(d => ({valor: d.solar_mw / 1000}))}
    />
    <KpiCard
        title="Potencia Eólica"
        value={potencia_eolica[0]?.potencia_mw ? (potencia_eolica[0].potencia_mw / 1000).toFixed(1) : null}
        unit=" GW"
        period={potencia_eolica[0]?.anio}
        source="Eurostat (nrg_inf_epc)"
        href="/energia-clima/mix-electrico"
        sparklineData={potencia_serie.map(d => ({valor: d.eolica_mw / 1000}))}
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

El sistema eléctrico español ha protagonizado una transformación histórica: entre {mix_hitos[0]?.anio} y {mix_hitos[1]?.anio}, la eólica y la solar fotovoltaica han pasado de representar el {mix_hitos[0]?.pct_eolica_solar}% a un **{mix_hitos[1]?.pct_eolica_solar}%** de la generación total, mientras que el carbón ha caído del {mix_hitos[0]?.pct_carbon}% al {mix_hitos[1]?.pct_carbon}%.

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

<DownloadCsvButton data={mix_areas} filename="spainfacts_mix_electrico.csv" label="Descargar mix eléctrico (CSV)" />

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

El **transporte** es el sector más resistente a la descarbonización: concentra el **{emisiones_hitos[1]?.pct_transporte}%** de las emisiones en {emisiones_hitos[1]?.anio}. En cambio, la **generación eléctrica** ha reducido sus emisiones un {emisiones_hitos.length > 1 ? ((1 - emisiones_hitos[1].mt_electrica / emisiones_hitos[0].mt_electrica) * 100).toFixed(0) : null}% desde {emisiones_hitos[0]?.anio} gracias al despliegue renovable.

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

<DownloadCsvButton data={emisiones_sector} filename="spainfacts_emisiones_gei.csv" label="Descargar emisiones GEI (CSV)" />

---

## Informes Detallados

<Grid cols=2>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-green-300 dark:hover:border-green-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-950/60 text-green-600 dark:text-green-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            ⚡
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Mix de Generación Eléctrica</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Análisis profundo del mix eléctrico: el auge de la eólica y solar FV, el cierre del carbón, la dependencia del gas natural y el papel de la nuclear.
        </p>
    </div>
    <a href="/energia-clima/mix-electrico" class="text-sm font-semibold text-green-700 dark:text-green-400 hover:underline inline-flex items-center">
        Ver informe del mix eléctrico →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-amber-300 dark:hover:border-amber-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-amber-100 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🏭
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Emisiones y Descarbonización</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Desglose sectorial de los gases de efecto invernadero: por qué el transporte es el gran reto pendiente y cómo la electricidad ya se está descarbonizando.
        </p>
    </div>
    <a href="/energia-clima/emisiones" class="text-sm font-semibold text-amber-700 dark:text-amber-400 hover:underline inline-flex items-center">
        Ver informe de emisiones →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-sky-300 dark:hover:border-sky-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-sky-100 dark:bg-sky-950/60 text-sky-600 dark:text-sky-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            💧
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Reservas de Agua y Embalses</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Estado semanal de los embalses por cuenca: cuánta agua hay, cómo está frente al año pasado y frente a la media de la última década.
        </p>
    </div>
    <a href="/energia-clima/embalses" class="text-sm font-semibold text-sky-700 dark:text-sky-400 hover:underline inline-flex items-center">
        Ver el estado de los embalses →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-orange-300 dark:hover:border-orange-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-950/60 text-orange-600 dark:text-orange-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🌡️
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Calor y Temperaturas</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            El mapa diario del calor por provincia: cuánto se aleja la temperatura máxima de la media histórica de cada día, los récords y la tendencia desde 1991.
        </p>
    </div>
    <a href="/energia-clima/calor" class="text-sm font-semibold text-red-600 dark:text-red-400 hover:underline inline-flex items-center">
        Ver el mapa del calor →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-red-300 dark:hover:border-red-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-red-100 dark:bg-red-950/60 text-red-600 dark:text-red-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🔥
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Incendios Forestales</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Hectáreas quemadas cada año desde 2000, cuánto arde dentro de la Red Natura 2000, el mapa de los incendios de este año y los focos activos detectados por satélite.
        </p>
    </div>
    <a href="/energia-clima/incendios" class="text-sm font-semibold text-red-600 dark:text-red-400 hover:underline inline-flex items-center">
        Ver el mapa de incendios →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-teal-300 dark:hover:border-teal-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-teal-100 dark:bg-teal-950/60 text-teal-600 dark:text-teal-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            📡
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">El Sistema Eléctrico, Ahora</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            En directo cada 5 minutos: demanda, % renovable e intensidad de CO₂ de España, la Península, Baleares, Canarias, Ceuta y Melilla, intercambios con los países vecinos y el precio de la luz.
        </p>
    </div>
    <a href="/energia-clima/directo" class="text-sm font-semibold text-teal-700 dark:text-teal-400 hover:underline inline-flex items-center">
        Ver el sistema en directo →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-yellow-300 dark:hover:border-yellow-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-yellow-100 dark:bg-yellow-950/60 text-yellow-600 dark:text-yellow-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🏆
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Récords del Sistema Eléctrico</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Máximos y mínimos históricos desde 2015 con datos de REE cada 5 minutos: demanda, solar, eólica, cuota renovable, emisiones, precios e intercambios, y cuándo se batió cada récord.
        </p>
    </div>
    <a href="/energia-clima/records" class="text-sm font-semibold text-yellow-700 dark:text-yellow-400 hover:underline inline-flex items-center">
        Ver los récords →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-indigo-300 dark:hover:border-indigo-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-indigo-100 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🗺️
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Centrales Eléctricas</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            El mapa de todas las centrales de España por tecnología y potencia: las que funcionan, las que están en obras o en tramitación y las que ya cerraron, con su propietario y sus fechas.
        </p>
    </div>
    <a href="/energia-clima/centrales" class="text-sm font-semibold text-indigo-600 dark:text-indigo-400 hover:underline inline-flex items-center">
        Ver el mapa de centrales →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-violet-300 dark:hover:border-violet-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-violet-100 dark:bg-violet-950/60 text-violet-600 dark:text-violet-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🔋
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Almacenamiento</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Bombeo hidráulico y baterías: cuánta energía guardan y devuelven, dónde están y los proyectos con permiso de conexión frente al objetivo de 2030.
        </p>
    </div>
    <a href="/energia-clima/almacenamiento" class="text-sm font-semibold text-violet-600 dark:text-violet-400 hover:underline inline-flex items-center">
        Ver el almacenamiento →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-blue-300 dark:hover:border-blue-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🔌
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Electrificación</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Cuánta energía de la industria, el transporte, los hogares y los servicios es ya electricidad, cómo se calientan las casas en cada provincia y cuántas bombas de calor hay.
        </p>
    </div>
    <a href="/energia-clima/electrificacion" class="text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline inline-flex items-center">
        Ver la electrificación →
    </a>
</div>

</Grid>

---

## Metodología y Fuentes Primarias

| Organismo | Dataset | Código | Licencia |
|:---|:---|:---|:---|
| **Red Eléctrica de España (REE)** | Generación y demanda anual (API REData) | [REE-MIX](https://www.ree.es/es/datos/generacion) | Datos Abiertos / RISP |
| **MITECO / Eurostat** | Inventario Nacional de Emisiones GEI (env_air_gge) | [MITECO-GEI](https://www.miteco.gob.es/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/inventario-gei.html) · [Eurostat](https://ec.europa.eu/eurostat/databrowser/view/env_air_gge/default/table) | RISP (Ley 37/2007) / CC BY 4.0 |
| **Eurostat** | Capacidad eléctrica instalada (nrg_inf_epc) | [Eurostat](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_epc/default/table) | CC BY 4.0 |

> Los datos de generación eléctrica proceden del balance nacional medido en barras de central por REE como Operador del Sistema (solo años completos). Las emisiones son las del inventario oficial de España (sin LULUCF), calculadas según las directrices del IPCC y reportadas a la Convención Marco de Naciones Unidas sobre el Cambio Climático (CMNUCC); Eurostat las publica desglosadas por categoría CRF, que aquí se agrupan en sectores.

<LastRefreshed prefix="Última sincronización de datos con fuentes oficiales" />
