---
i18n_origen: 698c69005fd6
title: Enerxía e Clima
description: Transición ecolóxica, mix de xeración eléctrica e emisións de gases de efecto invernadoiro en España.
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import DownloadCsvButton from '../../../../../../src/lib/components/DownloadCsvButton.svelte';
</script>

# 🌱 Enerxía, Clima e Transición Ecolóxica

España situouse como un dos líderes europeos no despregamento de enerxías renovables. Esta sección presenta as cifras oficiais do sistema eléctrico, as emisións de gases de efecto invernadoiro e a evolución da potencia instalada renovable.

```sql resumen_ultimo
SELECT * FROM mother.energia_resumen_anual_mix
ORDER BY año DESC
LIMIT 1
```

```sql resumen_previo
SELECT * FROM mother.energia_resumen_anual_mix
ORDER BY año DESC
LIMIT 2
```

```sql resumen_serie
SELECT año, cuota_renovable_pct AS valor
FROM mother.energia_resumen_anual_mix
ORDER BY año ASC
```

```sql emisiones_totales
SELECT
    año,
    sum(millones_toneladas_co2eq) AS total_emisiones
FROM mother.energia_emisiones_gei
GROUP BY año
ORDER BY año DESC
```

```sql potencia_solar
SELECT potencia_mw, año
FROM mother.energia_potencia_instalada
WHERE tecnologia = 'Solar Fotovoltaica'
  AND año = (SELECT max(año) FROM mother.energia_potencia_instalada)
```

```sql potencia_eolica
SELECT potencia_mw, año
FROM mother.energia_potencia_instalada
WHERE tecnologia = 'Eólica'
  AND año = (SELECT max(año) FROM mother.energia_potencia_instalada)
```

```sql potencia_serie
SELECT
    año,
    sum(potencia_mw) FILTER (WHERE tecnologia = 'Solar Fotovoltaica') AS solar_mw,
    sum(potencia_mw) FILTER (WHERE tecnologia = 'Eólica') AS eolica_mw
FROM mother.energia_potencia_instalada
GROUP BY año
ORDER BY año ASC
```

<Grid cols=4>
    <KpiCard
        title="Cota renovable"
        value={resumen_ultimo[0]?.cuota_renovable_pct}
        unit="%"
        period={resumen_ultimo[0]?.año}
        change={resumen_previo.length > 1 ? (resumen_previo[0].cuota_renovable_pct - resumen_previo[1].cuota_renovable_pct).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="vs. ano ant."
        direction="positive-up"
        source="Red Eléctrica de España (REE)"
        href="/gl/energia-clima/mix-electrico"
        sparklineData={resumen_serie}
    />
    <KpiCard
        title="Emisións totais CO₂eq"
        value={emisiones_totales[0]?.total_emisiones}
        unit=" Mt"
        change={emisiones_totales.length > 1 ? (emisiones_totales[0].total_emisiones - emisiones_totales[1].total_emisiones).toFixed(1) : null}
        changeUnit=" Mt"
        changePeriod="vs. ano ant."
        direction="positive-down"
        period={emisiones_totales[0]?.año}
        source="Inventario GEI (MITECO) vía Eurostat"
        href="/gl/energia-clima/emisiones"
        sparklineData={[...emisiones_totales].reverse().map(d => ({valor: d.total_emisiones}))}
    />
    <KpiCard
        title="Potencia solar FV"
        value={potencia_solar[0]?.potencia_mw ? (potencia_solar[0].potencia_mw / 1000).toFixed(1) : null}
        unit=" GW"
        period={potencia_solar[0]?.año}
        source="Eurostat (nrg_inf_epc)"
        href="/gl/energia-clima/mix-electrico"
        sparklineData={potencia_serie.map(d => ({valor: d.solar_mw / 1000}))}
    />
    <KpiCard
        title="Potencia eólica"
        value={potencia_eolica[0]?.potencia_mw ? (potencia_eolica[0].potencia_mw / 1000).toFixed(1) : null}
        unit=" GW"
        period={potencia_eolica[0]?.año}
        source="Eurostat (nrg_inf_epc)"
        href="/gl/energia-clima/mix-electrico"
        sparklineData={potencia_serie.map(d => ({valor: d.eolica_mw / 1000}))}
    />
</Grid>

---

## Evolución do mix eléctrico nacional

```sql mix_hitos
SELECT
    año,
    round(sum(porcentaje_total) FILTER (WHERE tecnologia IN ('Eólica', 'Solar Fotovoltaica')), 1) AS pct_eolica_solar,
    round(sum(porcentaje_total) FILTER (WHERE tecnologia = 'Carbón'), 1) AS pct_carbon
FROM mother.energia_mix_electrico
WHERE año IN ((SELECT min(año) FROM mother.energia_mix_electrico), (SELECT max(año) FROM mother.energia_mix_electrico))
GROUP BY año
ORDER BY año ASC
```

O sistema eléctrico español protagonizou unha transformación histórica: entre {mix_hitos[0]?.año} e {mix_hitos[1]?.año}, a eólica e a solar fotovoltaica pasaron de representar o {mix_hitos[0]?.pct_eolica_solar}% a un **{mix_hitos[1]?.pct_eolica_solar}%** da xeración total, mentres que o carbón caeu do {mix_hitos[0]?.pct_carbon}% ao {mix_hitos[1]?.pct_carbon}%.

```sql mix_areas
SELECT
    año,
    tecnologia,
    generacion_twh
FROM mother.energia_mix_electrico
WHERE tecnologia IN ('Eólica', 'Solar Fotovoltaica', 'Hidroeléctrica', 'Nuclear', 'Ciclos Combinados (Gas)', 'Carbón')
ORDER BY año ASC, tecnologia ASC
```

<AreaChart
    data={mix_areas}
    x=año
    y=generacion_twh
    series=tecnologia
    yAxisTitle="Xeración (TWh)"
    xAxisTitle="Ano"
    title="Xeración eléctrica por tecnoloxía (TWh)"
    colorPalette={['#16a34a', '#facc15', '#3b82f6', '#a855f7', '#f97316', '#6b7280']}
/>

<DownloadCsvButton data={mix_areas} filename="spainfacts_mix_electrico.csv" label="Descargar mix eléctrico (CSV)" />

---

## Cota de enerxía renovable e libre de emisións

```sql cuota_anual
SELECT
    año,
    cuota_renovable_pct AS "Renovable (%)",
    cuota_libre_emisiones_pct AS "Libre de emisiones (%) (Renovable + Nuclear)"
FROM mother.energia_resumen_anual_mix
ORDER BY año ASC
```

<LineChart
    data={cuota_anual}
    x=año
    y={["Renovable (%)", "Libre de emisiones (%) (Renovable + Nuclear)"]}
    yAxisTitle="Porcentaxe do total (%)"
    title="Cota de xeración limpa sobre o total eléctrico"
    colorPalette={['#16a34a', '#3b82f6']}
    yMin=0
    yMax=85
/>

---

## Emisións de gases de efecto invernadoiro por sector

```sql emisiones_hitos
SELECT
    año,
    round(max(porcentaje_total) FILTER (WHERE sector = 'Transporte'), 1) AS pct_transporte,
    max(millones_toneladas_co2eq) FILTER (WHERE sector = 'Generación Eléctrica') AS mt_electrica
FROM mother.energia_emisiones_gei
WHERE año IN ((SELECT min(año) FROM mother.energia_emisiones_gei), (SELECT max(año) FROM mother.energia_emisiones_gei))
GROUP BY año
ORDER BY año ASC
```

O **transporte** é o sector máis resistente á descarbonización: concentra o **{emisiones_hitos[1]?.pct_transporte}%** das emisións en {emisiones_hitos[1]?.año}. En cambio, a **xeración eléctrica** reduciu as súas emisións un {emisiones_hitos.length > 1 ? ((1 - emisiones_hitos[1].mt_electrica / emisiones_hitos[0].mt_electrica) * 100).toFixed(0) : null}% desde {emisiones_hitos[0]?.año} grazas ao despregamento renovable.

```sql emisiones_sector
SELECT
    año,
    sector,
    millones_toneladas_co2eq
FROM mother.energia_emisiones_gei
ORDER BY año ASC, sector ASC
```

<BarChart
    data={emisiones_sector}
    x=año
    y=millones_toneladas_co2eq
    series=sector
    type=stacked
    yAxisTitle="Millóns de toneladas de CO₂eq"
    title="Emisións GEI por sector (Mt CO₂eq)"
/>

<DownloadCsvButton data={emisiones_sector} filename="spainfacts_emisiones_gei.csv" label="Descargar emisións GEI (CSV)" />

---

## Informes detallados

<Grid cols=2>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-green-300 dark:hover:border-green-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-950/60 text-green-600 dark:text-green-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            ⚡
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Mix de xeración eléctrica</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Análise en profundidade do mix eléctrico: o auxe da eólica e a solar FV, o peche do carbón, a dependencia do gas natural e o papel da nuclear.
        </p>
    </div>
    <a href="/gl/energia-clima/mix-electrico" class="text-sm font-semibold text-green-700 dark:text-green-400 hover:underline inline-flex items-center">
        Ver informe do mix eléctrico →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-amber-300 dark:hover:border-amber-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-amber-100 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🏭
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Emisións e descarbonización</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Desagregación sectorial dos gases de efecto invernadoiro: por que o transporte é o gran reto pendente e como a electricidade xa se está a descarbonizar.
        </p>
    </div>
    <a href="/gl/energia-clima/emisiones" class="text-sm font-semibold text-amber-700 dark:text-amber-400 hover:underline inline-flex items-center">
        Ver informe de emisións →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-sky-300 dark:hover:border-sky-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-sky-100 dark:bg-sky-950/60 text-sky-600 dark:text-sky-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            💧
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Reservas de auga e encoros</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Estado semanal dos encoros por conca: canta auga hai, como está fronte ao ano pasado e fronte á media da última década.
        </p>
    </div>
    <a href="/gl/energia-clima/embalses" class="text-sm font-semibold text-sky-700 dark:text-sky-400 hover:underline inline-flex items-center">
        Ver o estado dos encoros →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-orange-300 dark:hover:border-orange-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-950/60 text-orange-600 dark:text-orange-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🌡️
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Calor e temperaturas</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            O mapa diario da calor por provincia: canto se afasta a temperatura máxima da media histórica de cada día, os récords e a tendencia desde 1991.
        </p>
    </div>
    <a href="/gl/energia-clima/calor" class="text-sm font-semibold text-red-600 dark:text-red-400 hover:underline inline-flex items-center">
        Ver o mapa da calor →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-red-300 dark:hover:border-red-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-red-100 dark:bg-red-950/60 text-red-600 dark:text-red-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🔥
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Incendios forestais</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Hectáreas queimadas cada ano desde 2000, canto arde dentro da Rede Natura 2000, o mapa dos incendios deste ano e os focos activos detectados por satélite.
        </p>
    </div>
    <a href="/gl/energia-clima/incendios" class="text-sm font-semibold text-red-600 dark:text-red-400 hover:underline inline-flex items-center">
        Ver o mapa de incendios →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-teal-300 dark:hover:border-teal-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-teal-100 dark:bg-teal-950/60 text-teal-600 dark:text-teal-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            📡
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">O sistema eléctrico, agora</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            En directo cada 5 minutos: demanda, % renovable e intensidade de CO₂ de España, a Península, Baleares, Canarias, Ceuta e Melilla, intercambios cos países veciños e o prezo da luz.
        </p>
    </div>
    <a href="/gl/energia-clima/directo" class="text-sm font-semibold text-teal-700 dark:text-teal-400 hover:underline inline-flex items-center">
        Ver o sistema en directo →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-yellow-300 dark:hover:border-yellow-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-yellow-100 dark:bg-yellow-950/60 text-yellow-600 dark:text-yellow-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🏆
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Récords do sistema eléctrico</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Máximos e mínimos históricos desde 2015 con datos de REE cada 5 minutos: demanda, solar, eólica, cota renovable, emisións, prezos e intercambios, e cando se bateu cada récord.
        </p>
    </div>
    <a href="/gl/energia-clima/records" class="text-sm font-semibold text-yellow-700 dark:text-yellow-400 hover:underline inline-flex items-center">
        Ver os récords →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-indigo-300 dark:hover:border-indigo-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-indigo-100 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🗺️
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Centrais eléctricas</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            O mapa de todas as centrais de España por tecnoloxía e potencia: as que funcionan, as que están en obras ou en tramitación e as que xa pecharon, co seu propietario e as súas datas.
        </p>
    </div>
    <a href="/gl/energia-clima/centrales" class="text-sm font-semibold text-indigo-600 dark:text-indigo-400 hover:underline inline-flex items-center">
        Ver o mapa de centrais →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-violet-300 dark:hover:border-violet-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-violet-100 dark:bg-violet-950/60 text-violet-600 dark:text-violet-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🔋
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Almacenamento</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Bombeo hidráulico e baterías: canta enerxía gardan e devolven, onde están e os proxectos con permiso de conexión fronte ao obxectivo de 2030.
        </p>
    </div>
    <a href="/gl/energia-clima/almacenamiento" class="text-sm font-semibold text-violet-600 dark:text-violet-400 hover:underline inline-flex items-center">
        Ver o almacenamento →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-blue-300 dark:hover:border-blue-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🔌
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Electrificación</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Canta enerxía da industria, o transporte, os fogares e os servizos é xa electricidade, como se quentan as casas en cada provincia e cantas bombas de calor hai.
        </p>
    </div>
    <a href="/gl/energia-clima/electrificacion" class="text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline inline-flex items-center">
        Ver a electrificación →
    </a>
</div>

</Grid>

---

## Metodoloxía e fontes primarias

| Organismo | Conxunto de datos | Código | Licenza |
|:---|:---|:---|:---|
| **Red Eléctrica de España (REE)** | Xeración e demanda anual (API REData) | [REE-MIX](https://www.ree.es/es/datos/generacion) | Datos abertos / RISP |
| **MITECO / Eurostat** | Inventario Nacional de Emisións GEI (env_air_gge) | [MITECO-GEI](https://www.miteco.gob.es/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/inventario-gei.html) · [Eurostat](https://ec.europa.eu/eurostat/databrowser/view/env_air_gge/default/table) | RISP (Ley 37/2007) / CC BY 4.0 |
| **Eurostat** | Capacidade eléctrica instalada (nrg_inf_epc) | [Eurostat](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_epc/default/table) | CC BY 4.0 |

> Os datos de xeración eléctrica proceden do balance nacional medido en barras de central por REE como Operador do Sistema (só anos completos). As emisións son as do inventario oficial de España (sen LULUCF), calculadas segundo as directrices do IPCC e comunicadas á Convención Marco das Nacións Unidas sobre o Cambio Climático (CMNUCC); Eurostat publícaas desagregadas por categoría CRF, que aquí se agrupan en sectores.

<LastRefreshed prefix="Última sincronización de datos con fontes oficiais" />
