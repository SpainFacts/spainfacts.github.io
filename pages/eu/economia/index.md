---
title: Ekonomia
description: "BPG biztanleko, hazkundea, kanpo-merkataritza, sektoreak, enplegua, soldatak, langabezia eta inflazioa Espainian, inflazioa kenduta eta biztanleriaren arabera."
i18n_origen: 21e2042a9bd3
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
</script>

```sql pib_hab
SELECT anio, real_eur AS valor, 100 * (real_eur / lag(real_eur) OVER (ORDER BY anio) - 1) AS crecimiento
FROM mother.economia_pib_per_capita
WHERE pais = 'ES'
ORDER BY anio
```

```sql pib_trim
SELECT trimestre, CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo, interanual, anio_base
FROM mother.economia_pib_trimestral
WHERE componente = 'B1GQ'
ORDER BY trimestre
```

```sql exportaciones
SELECT trimestre, CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo, pct_pib
FROM mother.economia_pib_trimestral
WHERE componente = 'P6'
ORDER BY trimestre
```

```sql salario
SELECT anio, salario_real, crecimiento_real
FROM mother.economia_salarios_anual
WHERE jornada = 'Todas' AND sector = 'Total'
ORDER BY anio
```

```sql empleo
SELECT anio, ocupados_1000_hab, ocupados_miles
FROM mother.economia_sectores
WHERE rama = 'TOTAL'
ORDER BY anio
```

```sql serie_paro
SELECT periodo, valor AS paro, strftime(periodo, '%Y') || '-T' || quarter(periodo) AS periodo_txt
FROM mother.metricas
WHERE metrica_id = 'tasa_paro'
ORDER BY periodo
```

```sql serie_ipc
SELECT periodo, valor AS ipc, strftime(periodo, '%Y-%m') AS periodo_txt
FROM mother.metricas
WHERE metrica_id = 'ipc_variacion_anual'
ORDER BY periodo
```

```sql sectores_crec
SELECT
    s.sector,
    100 * (s.vab_real_meur / b.vab_real_meur - 1) AS crecimiento,
    s.anio
FROM mother.economia_sectores s
JOIN mother.economia_sectores b ON b.rama = s.rama AND b.anio = 2019
WHERE s.anio = (SELECT max(anio) FROM mother.economia_sectores)
  AND s.rama <> 'TOTAL' AND NOT s.es_subrama
ORDER BY crecimiento DESC
```

# 📊 Ekonomia

Nola ari den bilakatzen Espainiako ekonomia. Webgune osoko irizpideari jarraituz, herrialdearen tamainaren araberakoa dena **biztanleko** erakusten da, eta eurotan neurtzen dena, **inflazioa kenduta** ({pib_trim[0]?.anio_base}. urteko eurotan).

<Grid cols=3>
    <KpiCard
        title="BPG biztanleko"
        value={pib_hab.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pib_hab.slice(-1)[0]?.valor, 0)} €"
        period="{pib_hab.slice(-1)[0]?.anio}. urtean, {pib_trim[0]?.anio_base}. urteko eurotan"
        change={pib_hab.slice(-1)[0]?.crecimiento?.toFixed(1)}
        changePeriod="erreala, aurreko urtearekin alderatuta"
        direction="positive-up"
        source="Eurostat"
        sparklineData={pib_hab.map(d => ({...d, y: d.valor}))}
        href="/eu/economia/pib"
    />
    <KpiCard
        title="BPGaren hazkundea"
        value={pib_trim.slice(-1)[0]?.interanual}
        formattedValue="{formatNumber(pib_trim.slice(-1)[0]?.interanual, 1)} %"
        period="urtetik urterakoa, erreala, {pib_trim.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={pib_trim.slice(-24).map(d => ({...d, y: d.interanual}))}
        href="/eu/economia/pib"
    />
    <KpiCard
        title="Esportazioak"
        value={exportaciones.slice(-1)[0]?.pct_pib}
        formattedValue="BPGaren {formatNumber(exportaciones.slice(-1)[0]?.pct_pib, 1)} %"
        period="ondasunak eta zerbitzuak, {exportaciones.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={exportaciones.slice(-40).map(d => ({...d, y: d.pct_pib}))}
        href="/eu/economia/comercio-exterior"
    />
    <KpiCard
        title="Batez besteko soldata"
        value={salario.slice(-1)[0]?.salario_real}
        formattedValue="{formatNumber(salario.slice(-1)[0]?.salario_real, 0)} €/hilean"
        period="gordina, {salario.slice(-1)[0]?.anio}. urtean, inflazioa kenduta"
        change={salario.slice(-1)[0]?.crecimiento_real?.toFixed(1)}
        changePeriod="erreala, aurreko urtearekin alderatuta"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={salario.map(d => ({...d, y: d.salario_real}))}
        href="/eu/economia/salarios"
    />
    <KpiCard
        title="Langabezia-tasa"
        value={serie_paro.slice(-1)[0]?.paro}
        formattedValue="{formatNumber(serie_paro.slice(-1)[0]?.paro, 1)} %"
        period={serie_paro.slice(-1)[0]?.periodo_txt}
        change={serie_paro.length > 1 ? (serie_paro.slice(-1)[0]?.paro - serie_paro.slice(-2)[0]?.paro).toFixed(1) : null}
        changeUnit="p.p."
        changePeriod="aurreko hiruhilekoarekin alderatuta"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={serie_paro.slice(-40).map(d => ({...d, y: d.paro}))}
        href="/eu/economia/paro"
    />
    <KpiCard
        title="Inflazioa"
        value={serie_ipc.slice(-1)[0]?.ipc}
        formattedValue="{formatNumber(serie_ipc.slice(-1)[0]?.ipc, 1)} %"
        period="KPI urtetik urtera, {serie_ipc.slice(-1)[0]?.periodo_txt}"
        change={serie_ipc.length > 1 ? (serie_ipc.slice(-1)[0]?.ipc - serie_ipc.slice(-2)[0]?.ipc).toFixed(1) : null}
        changeUnit="p.p."
        changePeriod="aurreko hilabetearekin alderatuta"
        direction="positive-down"
        source="INE / KPI"
        sparklineData={serie_ipc.slice(-36).map(d => ({...d, y: d.ipc}))}
        href="/eu/economia/ipc"
    />
</Grid>

## BPG biztanleko

Ekonomiak biztanle bakoitzeko ekoizten duena, euro konstanteetan. [Hiruhileko hazkundea, eskaria eta Europarekiko alderaketa →](/eu/economia/pib)

<LineChart
    data={pib_hab}
    x=anio
    y=valor
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ biztanleko (errealak)"
    startingAtZero={false}
    title="BPG biztanleko, {pib_trim[0]?.anio_base}. urteko eurotan"
/>

## Sektoreak

Sektore handi bakoitzaren balio erantsiaren hazkunde erreala 2019tik. [Enplegua, pisua eta produktibitatea sektoreka →](/eu/economia/sectores)

<BarChart
    data={sectores_crec}
    x=sector
    y=crecimiento
    swapXY=true
    yFmt='0.0"%"'
    title="Balio erantsiaren hazkunde erreala 2019tik {sectores_crec[0]?.anio}. urtera arte (%)"
/>

## Enplegua

Landunak 1.000 biztanleko: igo egiten da enplegua biztanleria baino azkarrago sortzen denean. [Langabezia-tasa →](/eu/economia/paro)

<LineChart
    data={empleo}
    x=anio
    y=ocupados_1000_hab
    xFmt='0'
    yAxisTitle="Landunak 1.000 biztanleko"
    startingAtZero={false}
    title="Landunak 1.000 biztanleko"
/>

## Soldatak

Hileko batez besteko soldata gordina, inflazioa kenduta. [Hazkundea, sektoreak eta dezilak →](/eu/economia/salarios)

<LineChart
    data={salario}
    x=anio
    y=salario_real
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ hilean (errealak)"
    startingAtZero={false}
    title="Hileko batez besteko soldata, {pib_trim[0]?.anio_base}. urteko eurotan"
/>

## Langabezia eta inflazioa

<Grid cols=2>
<LineChart
    data={serie_paro}
    x=periodo
    y=paro
    yAxisTitle="Biztanleria aktiboaren %"
    title="Langabezia-tasa (EPA)"
    startingAtZero={false}
/>
<LineChart
    data={serie_ipc}
    x=periodo
    y=ipc
    yAxisTitle="% urtetik urtera"
    title="Inflazioa (KPI, urteko aldakuntza)"
    startingAtZero={false}
/>
</Grid>

<Grid cols=3>
    <a href="/eu/economia/comercio-exterior" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🚢</span> Kanpo-merkataritza</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Esportazioak, inportazioak eta kanpo-saldoa BPGarekiko</div>
    </a>
    <a href="/eu/economia/paro" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">👷</span> Langabezia</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">EPAren serie historikoa</div>
    </a>
    <a href="/eu/economia/ipc" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🛒</span> Inflazioa</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Kontsumoko prezioen indizea eta energiaren prezioa</div>
    </a>
    <a href="/eu/economia/turismo" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🏖️</span> Turismoa</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Turistak biztanleko, haien gastu erreala eta BPGaren % gisa, hotelak eta etxebizitza turistikoak</div>
    </a>
    <a href="/eu/economia/empresas" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🏢</span> Enpresak, ekintzailetza eta I+G</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Enpresak biztanleko eta tamainaren arabera, sortutako eta desegindako sozietateak, konkurtsoak, autonomoak eta I+Gko gastua Europarekin alderatuta</div>
    </a>
    <a href="/eu/economia/sector-primario" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🌾</span> Nekazaritza, abeltzaintza eta arrantza</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Europako baratza: oliba-olioa, zitrikoak, frutak eta barazkiak, txerrikiak, ardoa eta arrantza, eta Espainiaren postua EBn</div>
    </a>
    <a href="/eu/economia/industria" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🏭</span> Industria</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Autoak, azulejuak, elikagaiak, trena eta aerosorgailuak: non nabarmentzen den Espainia eta zenbat industria duen EBrekin alderatuta</div>
    </a>
    <a href="/eu/economia/construccion" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🏗️</span> Eraikuntza</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">2007ko burbuila, kolapsoa eta susperraldia: enplegua, lizitatutako obra publikoa, ikus-onetsitako etxebizitzak eta zementua EBrekin alderatuta</div>
    </a>
</Grid>

---

**Iturriak:** Eurostat (kontabilitate nazionala: [namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table), [nama_10_pc](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table), [nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table)) eta INE ([EPA](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176918), [KPI](https://www.ine.es/jaxiT3/Tabla.htm?t=76125), [Lan Kostuaren Hiruhileko Inkesta](https://www.ine.es/jaxiT3/Tabla.htm?t=6038)).
