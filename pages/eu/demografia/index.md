---
title: Demografia
description: "Espainiako biztanleria INEren datu ofizialekin: hazkundea, jaiotza-tasa eta ugalkortasuna, zahartzea, lurralde-banaketa, gizonak eta emakumeak eta etxeak, erkidego eta probintziaka."
i18n_origen: 306ecbcd10ab
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
</script>

```sql edades
SELECT CAST(anio AS INTEGER) AS anio, poblacion, pct_65, pct_80, edad_media, pct_nacidos_extranjero
FROM mother.demografia_envejecimiento
WHERE nivel = 'pais'
ORDER BY anio
```

```sql anual
SELECT CAST(anio AS INTEGER) AS anio, nacimientos, defunciones, tasa_natalidad, tasa_mortalidad,
    vegetativo_1000, fecundidad, crecimiento_1000, resto_1000, crecimiento, crecimiento_vegetativo, resto, saldo_exterior_1000
FROM mother.demografia_anual
WHERE nivel = 'pais'
ORDER BY anio
```

```sql poblacion_serie
SELECT anio, poblacion / 1e6 AS valor FROM ${edades}
```

```sql crecimiento_ultimo
SELECT anio, crecimiento_1000, vegetativo_1000, resto_1000, crecimiento, crecimiento_vegetativo, resto, saldo_exterior_1000,
    100.0 * resto / crecimiento AS pct_resto
FROM ${anual}
WHERE crecimiento IS NOT NULL
ORDER BY anio DESC
LIMIT 1
```

```sql primer_negativo
SELECT min(anio) AS anio FROM ${anual} WHERE anio > (SELECT max(anio) FROM ${anual} WHERE vegetativo_1000 >= 0)
```

# 👪 Demografia

Zenbat garen, zenbat jaiotzen eta hiltzen diren, zenbat hazten den biztanleria eta zergatik, nola zahartzen den eta nola banatzen den lurraldean. Zifra guztiak INEren ofizialak dira, eta biztanleko edo ehunekotan ematen dira, urteak eta lurraldeak alderatu ahal izateko.

<Grid cols=4>
    <KpiCard
        title="Biztanleria"
        value={edades.slice(-1)[0]?.poblacion}
        formattedValue="{formatNumber(edades.slice(-1)[0]?.poblacion / 1e6, 2)} milioi"
        period="{urteko(edades.slice(-1)[0]?.anio)} urtarrilaren 1ean"
        change={100 * (edades.slice(-1)[0]?.poblacion / edades.slice(-2)[0]?.poblacion - 1)}
        changeUnit="%"
        changePeriod="urtebetean"
        direction="neutral"
        source="INE"
        href="/eu/demografia/evolucion-poblacion"
        sparklineData={poblacion_serie}
    />
    <KpiCard
        title="Jaiotza-tasa"
        value={anual.slice(-1)[0]?.tasa_natalidad}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.tasa_natalidad, 2)} 1.000 biz."
        period="{formatNumber(anual.slice(-1)[0]?.nacimientos, 0)} jaiotza {urtean(anual.slice(-1)[0]?.anio)}"
        source="INE"
        href="/eu/demografia/natalidad"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.tasa_natalidad}))}
    />
    <KpiCard
        title="Seme-alabak emakumeko"
        value={anual.slice(-1)[0]?.fecundidad}
        formattedValue={formatNumber(anual.slice(-1)[0]?.fecundidad, 2)}
        period="ugalkortasun-adierazle konjunturala, {anual.slice(-1)[0]?.anio} (belaunaldien ordezkapena 2,1 da)"
        source="INE"
        href="/eu/demografia/natalidad"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.fecundidad}))}
    />
    <KpiCard
        title="65 urtetik gorakoak"
        value={edades.slice(-1)[0]?.pct_65}
        formattedValue="{formatNumber(edades.slice(-1)[0]?.pct_65, 1)} %"
        period="biztanleriarena · batez besteko adina {formatNumber(edades.slice(-1)[0]?.edad_media, 1)} urte"
        source="INE"
        href="/eu/demografia/estructura-edades"
        sparklineData={edades.map(d => ({anio: d.anio, valor: d.pct_65}))}
    />
</Grid>

## Nondik dator biztanleriaren hazkundea

Biztanleria bi bidetatik aldatzen da: jaiotzen eta heriotzen arteko aldea (hazkunde begetatiboa) eta Espainiara bizitzera etortzen direnen eta joaten direnen arteko aldea (migrazio-saldoa).

```sql componentes
SELECT anio, 'Nacimientos menos defunciones' AS componente, vegetativo_1000 AS por_1000 FROM ${anual} WHERE crecimiento_1000 IS NOT NULL
UNION ALL
SELECT anio, 'Migración y ajustes', resto_1000 FROM ${anual} WHERE crecimiento_1000 IS NOT NULL
ORDER BY anio
```

<BarChart
    data={componentes}
    x=anio
    y=por_1000
    series=componente
    type=stacked
    yFmt=num1
    xFmt="####"
    colorPalette={['#be185d', '#0f766e']}
    yAxisTitle="1.000 biztanleko"
    title="Biztanleriaren urteko hazkundea 1.000 biztanleko eta haren osagaiak"
/>

<p class="text-xs text-gray-500">Hazkundea = hurrengo urteko urtarrilaren 1eko biztanleria ken urte horretakoa, Biztanleriaren Estatistika Jarraituaren arabera. "Migrazioa eta doikuntzak" jaiotzek eta heriotzek azaltzen ez duten hazkunde-zatia da. Ia zehatz-mehatz bat dator Migrazioen Estatistikak 2021etik neurtzen duen atzerriarekiko migrazio-saldoarekin: {urtean(crecimiento_ultimo[0]?.anio)}, {formatNumber(crecimiento_ultimo[0]?.resto_1000, 1)} eta {formatNumber(crecimiento_ultimo[0]?.saldo_exterior_1000, 1)}, hurrenez hurren, 1.000 biztanleko (ikus <a href="/eu/sociedad/inmigracion">Immigrazioa</a>).</p>

{#if crecimiento_ultimo[0]?.vegetativo_1000 < 0}

Biztanleria {formatNumber(crecimiento_ultimo[0]?.crecimiento_1000, 1)} pertsona hazi zen 1.000 biztanleko {urtean(crecimiento_ultimo[0]?.anio)} ({formatNumber(crecimiento_ultimo[0]?.crecimiento, 0)} guztira). Jaio zirenak baino pertsona gehiago hil ziren ({formatNumber(crecimiento_ultimo[0]?.vegetativo_1000, 1)} 1.000 biztanleko), {urtetik(primer_negativo[0]?.anio)} urtero gertatzen den bezala; beraz, hazkunde osoa migraziotik dator.

{:else}

Biztanleria {formatNumber(crecimiento_ultimo[0]?.crecimiento_1000, 1)} pertsona hazi zen 1.000 biztanleko {urtean(crecimiento_ultimo[0]?.anio)}: {formatNumber(crecimiento_ultimo[0]?.vegetativo_1000, 1)} jaiotzak ken heriotzengatik eta {formatNumber(crecimiento_ultimo[0]?.resto_1000, 1)} migrazioagatik eta doikuntzengatik.

{/if}

## Arakatu

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/eu/demografia/evolucion-poblacion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">📈</span> Biztanleriaren bilakaera</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Biztanleria 1971tik, urteko hazkundea 1.000 biztanleko eta zenbat ekartzen duten jaiotzek, heriotzek eta migrazioak erkidego bakoitzean.</p>
    </a>
    <a href="/eu/demografia/natalidad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-pink-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">👶</span> Jaiotza-tasa eta ugalkortasuna</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Jaiotzak eta heriotzak 1.000 biztanleko, seme-alabak emakumeko, amen adina eta ama atzerritarren jaiotzak, erkidego eta probintziaka.</p>
    </a>
    <a href="/eu/demografia/estructura-edades" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-rose-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔺</span> Adinak eta zahartzea</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Espainiako, erkidego bakoitzeko eta probintzia bakoitzeko biztanleria-piramideak; 65 eta 80 urtetik gorakoak, mendekotasuna eta batez besteko adina.</p>
    </a>
    <a href="/eu/demografia/distribucion-territorial" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-emerald-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🗺️</span> Lurralde-banaketa</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Zein probintziak irabazten eta galtzen duten biztanleria, erkidego bakoitzaren pisua eta atzerrian jaiotakoen ehunekoa probintzia bakoitzean.</p>
    </a>
    <a href="/eu/demografia/poblacion-sexo" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-purple-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">⚖️</span> Gizonak eta emakumeak</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Gizonak 100 emakumeko, adinaren arabera, denboran zehar eta probintzia bakoitzean.</p>
    </a>
    <a href="/eu/demografia/hogares" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏠</span> Etxeak</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Etxeen batez besteko tamaina eta pertsona bakarreko etxeak, erkidego eta probintziaka.</p>
    </a>
</div>

---

## Iturriak eta oharrak

- **[INE – Biztanleriaren Estatistika Jarraitua](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177095)**: urtarrilaren 1eko biztanleria probintzia, adin eta sexuaren arabera (56945 taula), jaioterriaren arabera (56948) eta nazionalitatearen arabera (56947), eta etxeak (60131etik 60134ra).
- **[INE – Biztanleriaren Mugimendu Naturala](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177007)**: jaiotzak (6524 taula) eta heriotzak (6561) bizileku-probintziaren arabera.
- **[INE – Oinarrizko Adierazle Demografikoak](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002)**: jaiotza- eta heriotza-tasak, ugalkortasuna, amatasunerako batez besteko adina eta ama atzerritarren jaioberriak.
- **[INE – Migrazioen eta Bizileku Aldaketen Estatistika](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177000)**: atzerriarekiko migrazio-saldoa 2021etik (ikus [Immigrazioa](/eu/sociedad/inmigracion)).

<LastRefreshed prefix="Datuak eguneratuta" />
