---
title: Energia i Clima
description: Transició ecològica, mix de generació elèctrica i emissions de gasos d'efecte d'hivernacle a Espanya.
i18n_origen: 698c69005fd6
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import DownloadCsvButton from '../../../../../../src/lib/components/DownloadCsvButton.svelte';
</script>

# 🌱 Energia, Clima i Transició Ecològica

Espanya s'ha situat com un dels líders europeus en el desplegament d'energies renovables. Aquesta secció presenta les xifres oficials del sistema elèctric, les emissions de gasos d'efecte d'hivernacle i l'evolució de la potència instal·lada renovable.

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
        title="Quota Renovable"
        value={resumen_ultimo[0]?.cuota_renovable_pct}
        unit="%"
        period={resumen_ultimo[0]?.año}
        change={resumen_previo.length > 1 ? (resumen_previo[0].cuota_renovable_pct - resumen_previo[1].cuota_renovable_pct).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="vs. any ant."
        direction="positive-up"
        source="Red Eléctrica de España (REE)"
        href="/ca/energia-clima/mix-electrico"
        sparklineData={resumen_serie}
    />
    <KpiCard
        title="Emissions Totals CO₂eq"
        value={emisiones_totales[0]?.total_emisiones}
        unit=" Mt"
        change={emisiones_totales.length > 1 ? (emisiones_totales[0].total_emisiones - emisiones_totales[1].total_emisiones).toFixed(1) : null}
        changeUnit=" Mt"
        changePeriod="vs. any ant."
        direction="positive-down"
        period={emisiones_totales[0]?.año}
        source="Inventari GEH (MITECO) via Eurostat"
        href="/ca/energia-clima/emisiones"
        sparklineData={[...emisiones_totales].reverse().map(d => ({valor: d.total_emisiones}))}
    />
    <KpiCard
        title="Potència Solar FV"
        value={potencia_solar[0]?.potencia_mw ? (potencia_solar[0].potencia_mw / 1000).toFixed(1) : null}
        unit=" GW"
        period={potencia_solar[0]?.año}
        source="Eurostat (nrg_inf_epc)"
        href="/ca/energia-clima/mix-electrico"
        sparklineData={potencia_serie.map(d => ({valor: d.solar_mw / 1000}))}
    />
    <KpiCard
        title="Potència Eòlica"
        value={potencia_eolica[0]?.potencia_mw ? (potencia_eolica[0].potencia_mw / 1000).toFixed(1) : null}
        unit=" GW"
        period={potencia_eolica[0]?.año}
        source="Eurostat (nrg_inf_epc)"
        href="/ca/energia-clima/mix-electrico"
        sparklineData={potencia_serie.map(d => ({valor: d.eolica_mw / 1000}))}
    />
</Grid>

---

## Evolució del Mix Elèctric Nacional

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

El sistema elèctric espanyol ha protagonitzat una transformació històrica: entre {mix_hitos[0]?.año} i {mix_hitos[1]?.año}, l'eòlica i la solar fotovoltaica han passat de representar el {mix_hitos[0]?.pct_eolica_solar}% a un **{mix_hitos[1]?.pct_eolica_solar}%** de la generació total, mentre que el carbó ha caigut del {mix_hitos[0]?.pct_carbon}% al {mix_hitos[1]?.pct_carbon}%.

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
    yAxisTitle="Generació (TWh)"
    xAxisTitle="Any"
    title="Generació elèctrica per tecnologia (TWh)"
    colorPalette={['#16a34a', '#facc15', '#3b82f6', '#a855f7', '#f97316', '#6b7280']}
/>

<DownloadCsvButton data={mix_areas} filename="spainfacts_mix_electrico.csv" label="Descarregar el mix elèctric (CSV)" />

---

## Quota d'Energia Renovable i Lliure d'Emissions

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
    yAxisTitle="Percentatge del total (%)"
    title="Quota de generació neta sobre el total elèctric"
    colorPalette={['#16a34a', '#3b82f6']}
    yMin=0
    yMax=85
/>

---

## Emissions de Gasos d'Efecte d'Hivernacle per Sector

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

El **transport** és el sector més resistent a la descarbonització: concentra el **{emisiones_hitos[1]?.pct_transporte}%** de les emissions el {emisiones_hitos[1]?.año}. En canvi, la **generació elèctrica** ha reduït les seves emissions un {emisiones_hitos.length > 1 ? ((1 - emisiones_hitos[1].mt_electrica / emisiones_hitos[0].mt_electrica) * 100).toFixed(0) : null}% des del {emisiones_hitos[0]?.año} gràcies al desplegament renovable.

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
    yAxisTitle="Milions de tones de CO₂eq"
    title="Emissions GEH per sector (Mt CO₂eq)"
/>

<DownloadCsvButton data={emisiones_sector} filename="spainfacts_emisiones_gei.csv" label="Descarregar les emissions GEH (CSV)" />

---

## Informes Detallats

<Grid cols=2>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-green-300 dark:hover:border-green-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-950/60 text-green-600 dark:text-green-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            ⚡
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Mix de Generació Elèctrica</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Anàlisi a fons del mix elèctric: l'auge de l'eòlica i la solar FV, el tancament del carbó, la dependència del gas natural i el paper de la nuclear.
        </p>
    </div>
    <a href="/ca/energia-clima/mix-electrico" class="text-sm font-semibold text-green-700 dark:text-green-400 hover:underline inline-flex items-center">
        Veure l'informe del mix elèctric →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-amber-300 dark:hover:border-amber-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-amber-100 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🏭
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Emissions i Descarbonització</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Desglossament sectorial dels gasos d'efecte d'hivernacle: per què el transport és el gran repte pendent i com l'electricitat ja s'està descarbonitzant.
        </p>
    </div>
    <a href="/ca/energia-clima/emisiones" class="text-sm font-semibold text-amber-700 dark:text-amber-400 hover:underline inline-flex items-center">
        Veure l'informe d'emissions →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-sky-300 dark:hover:border-sky-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-sky-100 dark:bg-sky-950/60 text-sky-600 dark:text-sky-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            💧
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Reserves d'Aigua i Embassaments</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Estat setmanal dels embassaments per conca: quanta aigua hi ha, com està respecte a l'any passat i respecte a la mitjana de l'última dècada.
        </p>
    </div>
    <a href="/ca/energia-clima/embalses" class="text-sm font-semibold text-sky-700 dark:text-sky-400 hover:underline inline-flex items-center">
        Veure l'estat dels embassaments →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-orange-300 dark:hover:border-orange-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-950/60 text-orange-600 dark:text-orange-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🌡️
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Calor i Temperatures</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            El mapa diari de la calor per província: quant s'allunya la temperatura màxima de la mitjana històrica de cada dia, els rècords i la tendència des del 1991.
        </p>
    </div>
    <a href="/ca/energia-clima/calor" class="text-sm font-semibold text-red-600 dark:text-red-400 hover:underline inline-flex items-center">
        Veure el mapa de la calor →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-red-300 dark:hover:border-red-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-red-100 dark:bg-red-950/60 text-red-600 dark:text-red-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🔥
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Incendis Forestals</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Hectàrees cremades cada any des del 2000, quant crema dins de la Xarxa Natura 2000, el mapa dels incendis d'aquest any i els focus actius detectats per satèl·lit.
        </p>
    </div>
    <a href="/ca/energia-clima/incendios" class="text-sm font-semibold text-red-600 dark:text-red-400 hover:underline inline-flex items-center">
        Veure el mapa d'incendis →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-teal-300 dark:hover:border-teal-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-teal-100 dark:bg-teal-950/60 text-teal-600 dark:text-teal-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            📡
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">El Sistema Elèctric, Ara</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            En directe cada 5 minuts: demanda, % renovable i intensitat de CO₂ d'Espanya, la Península, les Balears, les Canàries, Ceuta i Melilla, intercanvis amb els països veïns i el preu de la llum.
        </p>
    </div>
    <a href="/ca/energia-clima/directo" class="text-sm font-semibold text-teal-700 dark:text-teal-400 hover:underline inline-flex items-center">
        Veure el sistema en directe →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-yellow-300 dark:hover:border-yellow-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-yellow-100 dark:bg-yellow-950/60 text-yellow-600 dark:text-yellow-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🏆
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Rècords del Sistema Elèctric</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Màxims i mínims històrics des del 2015 amb dades de REE cada 5 minuts: demanda, solar, eòlica, quota renovable, emissions, preus i intercanvis, i quan es va batre cada rècord.
        </p>
    </div>
    <a href="/ca/energia-clima/records" class="text-sm font-semibold text-yellow-700 dark:text-yellow-400 hover:underline inline-flex items-center">
        Veure els rècords →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-indigo-300 dark:hover:border-indigo-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-indigo-100 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🗺️
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Centrals Elèctriques</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            El mapa de totes les centrals d'Espanya per tecnologia i potència: les que funcionen, les que estan en obres o en tramitació i les que ja han tancat, amb el propietari i les dates.
        </p>
    </div>
    <a href="/ca/energia-clima/centrales" class="text-sm font-semibold text-indigo-600 dark:text-indigo-400 hover:underline inline-flex items-center">
        Veure el mapa de centrals →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-violet-300 dark:hover:border-violet-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-violet-100 dark:bg-violet-950/60 text-violet-600 dark:text-violet-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🔋
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Emmagatzematge</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Bombament hidràulic i bateries: quanta energia guarden i retornen, on són i els projectes amb permís de connexió davant l'objectiu del 2030.
        </p>
    </div>
    <a href="/ca/energia-clima/almacenamiento" class="text-sm font-semibold text-violet-600 dark:text-violet-400 hover:underline inline-flex items-center">
        Veure l'emmagatzematge →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-blue-300 dark:hover:border-blue-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🔌
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Electrificació</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Quanta energia de la indústria, el transport, les llars i els serveis ja és electricitat, com s'escalfen les cases a cada província i quantes bombes de calor hi ha.
        </p>
    </div>
    <a href="/ca/energia-clima/electrificacion" class="text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline inline-flex items-center">
        Veure l'electrificació →
    </a>
</div>

</Grid>

---

## Metodologia i Fonts Primàries

| Organisme | Conjunt de dades | Codi | Llicència |
|:---|:---|:---|:---|
| **Red Eléctrica de España (REE)** | Generació i demanda anual (API REData) | [REE-MIX](https://www.ree.es/es/datos/generacion) | Dades Obertes / RISP |
| **MITECO / Eurostat** | Inventari Nacional d'Emissions GEH (env_air_gge) | [MITECO-GEI](https://www.miteco.gob.es/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/inventario-gei.html) · [Eurostat](https://ec.europa.eu/eurostat/databrowser/view/env_air_gge/default/table) | RISP (Llei 37/2007) / CC BY 4.0 |
| **Eurostat** | Capacitat elèctrica instal·lada (nrg_inf_epc) | [Eurostat](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_epc/default/table) | CC BY 4.0 |

> Les dades de generació elèctrica provenen del balanç nacional mesurat en barres de central per REE com a Operador del Sistema (només anys complets). Les emissions són les de l'inventari oficial d'Espanya (sense LULUCF), calculades segons les directrius de l'IPCC i reportades a la Convenció Marc de les Nacions Unides sobre el Canvi Climàtic (CMNUCC); Eurostat les publica desglossades per categoria CRF, que aquí s'agrupen en sectors.

<LastRefreshed prefix="Última sincronització de dades amb fonts oficials" />
