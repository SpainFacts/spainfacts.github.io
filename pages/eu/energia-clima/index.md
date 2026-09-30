---
title: Energia eta klima
description: Trantsizio ekologikoa, sorkuntza elektrikoaren mixa eta berotegi-efektuko gasen isuriak Espainian.
i18n_origen: 698c69005fd6
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import DownloadCsvButton from '../../../../../../src/lib/components/DownloadCsvButton.svelte';
</script>

# 🌱 Energia, klima eta trantsizio ekologikoa

Espainia energia berriztagarrien hedapenean Europako liderretako bat bihurtu da. Atal honek sistema elektrikoaren zifra ofizialak, berotegi-efektuko gasen isuriak eta instalatutako potentzia berriztagarriaren bilakaera aurkezten ditu.

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
        title="Berriztagarrien kuota"
        value={resumen_ultimo[0]?.cuota_renovable_pct}
        unit="%"
        period={resumen_ultimo[0]?.año}
        change={resumen_previo.length > 1 ? (resumen_previo[0].cuota_renovable_pct - resumen_previo[1].cuota_renovable_pct).toFixed(1) : null}
        changeUnit="p.p."
        changePeriod="aurreko urtearekiko"
        direction="positive-up"
        source="Red Eléctrica de España (REE)"
        href="/eu/energia-clima/mix-electrico"
        sparklineData={resumen_serie}
    />
    <KpiCard
        title="CO₂eq isuri guztiak"
        value={emisiones_totales[0]?.total_emisiones}
        unit=" Mt"
        change={emisiones_totales.length > 1 ? (emisiones_totales[0].total_emisiones - emisiones_totales[1].total_emisiones).toFixed(1) : null}
        changeUnit=" Mt"
        changePeriod="aurreko urtearekiko"
        direction="positive-down"
        period={emisiones_totales[0]?.año}
        source="BEG inbentarioa (MITECO), Eurostaten bidez"
        href="/eu/energia-clima/emisiones"
        sparklineData={[...emisiones_totales].reverse().map(d => ({valor: d.total_emisiones}))}
    />
    <KpiCard
        title="Eguzki-potentzia FV"
        value={potencia_solar[0]?.potencia_mw ? (potencia_solar[0].potencia_mw / 1000).toFixed(1) : null}
        unit=" GW"
        period={potencia_solar[0]?.año}
        source="Eurostat (nrg_inf_epc)"
        href="/eu/energia-clima/mix-electrico"
        sparklineData={potencia_serie.map(d => ({valor: d.solar_mw / 1000}))}
    />
    <KpiCard
        title="Potentzia eolikoa"
        value={potencia_eolica[0]?.potencia_mw ? (potencia_eolica[0].potencia_mw / 1000).toFixed(1) : null}
        unit=" GW"
        period={potencia_eolica[0]?.año}
        source="Eurostat (nrg_inf_epc)"
        href="/eu/energia-clima/mix-electrico"
        sparklineData={potencia_serie.map(d => ({valor: d.eolica_mw / 1000}))}
    />
</Grid>

---

## Elektrizitate-mix nazionalaren bilakaera

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

Espainiako sistema elektrikoak eraldaketa historikoa izan du: {mix_hitos[0]?.año} eta {mix_hitos[1]?.año} artean, energia eolikoak eta eguzki-energia fotovoltaikoak sorkuntza osoaren {mix_hitos[0]?.pct_eolica_solar} % izatetik **{mix_hitos[1]?.pct_eolica_solar} %** izatera igaro dira, eta ikatza, berriz, {mix_hitos[0]?.pct_carbon} %-tik {mix_hitos[1]?.pct_carbon} %-ra jaitsi da.

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
    yAxisTitle="Sorkuntza (TWh)"
    xAxisTitle="Urtea"
    title="Sorkuntza elektrikoa teknologiaka (TWh)"
    colorPalette={['#16a34a', '#facc15', '#3b82f6', '#a855f7', '#f97316', '#6b7280']}
/>

<DownloadCsvButton data={mix_areas} filename="spainfacts_mix_electrico.csv" label="Deskargatu elektrizitate-mixa (CSV)" />

---

## Energia berriztagarriaren eta isuririk gabekoaren kuota

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
    yAxisTitle="Guztizkoaren ehunekoa (%)"
    title="Sorkuntza garbiaren kuota elektrizitate osoaren gainean"
    colorPalette={['#16a34a', '#3b82f6']}
    yMin=0
    yMax=85
/>

---

## Berotegi-efektuko gasen isuriak sektoreka

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

**Garraioa** da deskarbonizazioari gehien eusten dion sektorea: isurien **{emisiones_hitos[1]?.pct_transporte} %** biltzen du {emisiones_hitos[1]?.año}. urtean. Aldiz, **sorkuntza elektrikoak** {emisiones_hitos.length > 1 ? ((1 - emisiones_hitos[1].mt_electrica / emisiones_hitos[0].mt_electrica) * 100).toFixed(0) : null} % murriztu ditu bere isuriak {emisiones_hitos[0]?.año}. urteaz geroztik, berriztagarrien hedapenari esker.

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
    yAxisTitle="CO₂eq milioi tona"
    title="BEG isuriak sektoreka (Mt CO₂eq)"
/>

<DownloadCsvButton data={emisiones_sector} filename="spainfacts_emisiones_gei.csv" label="Deskargatu BEG isuriak (CSV)" />

---

## Txosten xehatuak

<Grid cols=2>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-green-300 dark:hover:border-green-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-950/60 text-green-600 dark:text-green-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            ⚡
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Sorkuntza elektrikoaren mixa</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Elektrizitate-mixaren azterketa sakona: eolikoaren eta eguzki FVaren gorakada, ikatzaren itxiera, gas naturalarekiko mendekotasuna eta nuklearraren papera.
        </p>
    </div>
    <a href="/eu/energia-clima/mix-electrico" class="text-sm font-semibold text-green-700 dark:text-green-400 hover:underline inline-flex items-center">
        Ikusi elektrizitate-mixaren txostena →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-amber-300 dark:hover:border-amber-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-amber-100 dark:bg-amber-950/60 text-amber-600 dark:text-amber-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🏭
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Isuriak eta deskarbonizazioa</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Berotegi-efektuko gasen banakapena sektoreka: zergatik den garraioa egiteke dagoen erronka handia eta nola ari den elektrizitatea deskarbonizatzen.
        </p>
    </div>
    <a href="/eu/energia-clima/emisiones" class="text-sm font-semibold text-amber-700 dark:text-amber-400 hover:underline inline-flex items-center">
        Ikusi isurien txostena →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-sky-300 dark:hover:border-sky-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-sky-100 dark:bg-sky-950/60 text-sky-600 dark:text-sky-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            💧
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Ur-erreserbak eta urtegiak</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Urtegien asteko egoera arroka: zenbat ur dagoen, nola dagoen iazkoarekin eta azken hamarkadako batez bestekoarekin alderatuta.
        </p>
    </div>
    <a href="/eu/energia-clima/embalses" class="text-sm font-semibold text-sky-700 dark:text-sky-400 hover:underline inline-flex items-center">
        Ikusi urtegien egoera →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-orange-300 dark:hover:border-orange-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-950/60 text-orange-600 dark:text-orange-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🌡️
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Beroa eta tenperaturak</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Beroaren eguneko mapa probintziaka: tenperatura maximoa egun bakoitzeko batez besteko historikotik zenbat aldentzen den, errekorrak eta 1991tik aurrerako joera.
        </p>
    </div>
    <a href="/eu/energia-clima/calor" class="text-sm font-semibold text-red-600 dark:text-red-400 hover:underline inline-flex items-center">
        Ikusi beroaren mapa →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-red-300 dark:hover:border-red-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-red-100 dark:bg-red-950/60 text-red-600 dark:text-red-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🔥
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Baso-suteak</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            2000tik urtero erretako hektareak, Natura 2000 Sarearen barruan zenbat erretzen den, aurtengo suteen mapa eta sateliteek detektatutako foku aktiboak.
        </p>
    </div>
    <a href="/eu/energia-clima/incendios" class="text-sm font-semibold text-red-600 dark:text-red-400 hover:underline inline-flex items-center">
        Ikusi suteen mapa →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-teal-300 dark:hover:border-teal-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-teal-100 dark:bg-teal-950/60 text-teal-600 dark:text-teal-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            📡
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Sistema elektrikoa, orain</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Zuzenean 5 minuturo: Espainiako, Penintsulako, Balear Uharteetako, Kanarietako, Ceutako eta Melillako eskaria, % berriztagarria eta CO₂ intentsitatea, inguruko herrialdeekiko trukeak eta argindarraren prezioa.
        </p>
    </div>
    <a href="/eu/energia-clima/directo" class="text-sm font-semibold text-teal-700 dark:text-teal-400 hover:underline inline-flex items-center">
        Ikusi sistema zuzenean →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-yellow-300 dark:hover:border-yellow-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-yellow-100 dark:bg-yellow-950/60 text-yellow-600 dark:text-yellow-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🏆
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Sistema elektrikoaren errekorrak</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            2015etik aurrerako maximo eta minimo historikoak, REEren 5 minuturoko datuekin: eskaria, eguzki-energia, eolikoa, berriztagarrien kuota, isuriak, prezioak eta trukeak, eta errekor bakoitza noiz hautsi zen.
        </p>
    </div>
    <a href="/eu/energia-clima/records" class="text-sm font-semibold text-yellow-700 dark:text-yellow-400 hover:underline inline-flex items-center">
        Ikusi errekorrak →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-indigo-300 dark:hover:border-indigo-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-indigo-100 dark:bg-indigo-950/60 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🗺️
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Zentral elektrikoak</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Espainiako zentral guztien mapa teknologiaren eta potentziaren arabera: martxan daudenak, obretan edo izapidetzen daudenak eta dagoeneko itxi zirenak, beren jabearekin eta datekin.
        </p>
    </div>
    <a href="/eu/energia-clima/centrales" class="text-sm font-semibold text-indigo-600 dark:text-indigo-400 hover:underline inline-flex items-center">
        Ikusi zentralen mapa →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-violet-300 dark:hover:border-violet-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-violet-100 dark:bg-violet-950/60 text-violet-600 dark:text-violet-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🔋
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Biltegiratzea</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Ponpaketa hidraulikoa eta bateriak: zenbat energia gordetzen eta itzultzen duten, non dauden eta konexio-baimena duten proiektuak 2030eko helburuaren aldean.
        </p>
    </div>
    <a href="/eu/energia-clima/almacenamiento" class="text-sm font-semibold text-violet-600 dark:text-violet-400 hover:underline inline-flex items-center">
        Ikusi biltegiratzea →
    </a>
</div>

<div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-6 shadow-sm flex flex-col justify-between hover:border-blue-300 dark:hover:border-blue-700 transition-all">
    <div>
        <div class="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center font-bold text-xl mb-4" aria-hidden="true">
            🔌
        </div>
        <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Elektrifikazioa</h3>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4 leading-relaxed">
            Industriaren, garraioaren, etxeen eta zerbitzuen energiaren zenbat den jada elektrizitatea, nola berotzen diren etxeak probintzia bakoitzean eta zenbat bero-ponpa dauden.
        </p>
    </div>
    <a href="/eu/energia-clima/electrificacion" class="text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline inline-flex items-center">
        Ikusi elektrifikazioa →
    </a>
</div>

</Grid>

---

## Metodologia eta lehen mailako iturriak

| Erakundea | Datu-multzoa | Kodea | Lizentzia |
|:---|:---|:---|:---|
| **Red Eléctrica de España (REE)** | Urteko sorkuntza eta eskaria (REData APIa) | [REE-MIX](https://www.ree.es/es/datos/generacion) | Datu irekiak / RISP |
| **MITECO / Eurostat** | BEG Isurien Inbentario Nazionala (env_air_gge) | [MITECO-GEI](https://www.miteco.gob.es/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/inventario-gei.html) · [Eurostat](https://ec.europa.eu/eurostat/databrowser/view/env_air_gge/default/table) | RISP (37/2007 Legea) / CC BY 4.0 |
| **Eurostat** | Instalatutako ahalmen elektrikoa (nrg_inf_epc) | [Eurostat](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_epc/default/table) | CC BY 4.0 |

> Sorkuntza elektrikoaren datuak REEk, Sistemaren Operadore gisa, zentralen barretan neurtutako balantze nazionaletik datoz (urte osoak soilik). Isuriak Espainiako inbentario ofizialekoak dira (LULUCF gabe), IPCCren jarraibideen arabera kalkulatuak eta Nazio Batuen Klima Aldaketari buruzko Esparru Hitzarmenari (CMNUCC) jakinaraziak; Eurostatek CRF kategoriaka banatuta argitaratzen ditu, eta hemen sektoretan biltzen dira.

<LastRefreshed prefix="Iturri ofizialekin egindako azken datu-sinkronizazioa" />
