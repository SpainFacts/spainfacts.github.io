---
title: Etxebizitza
description: "Etxebizitzaren prezioa Espainian inflazioa kenduta, alokairua, salerosketak eta hipotekak 1.000 biztanleko, obra berria eta etxe batek zenbat urteko soldata balio duen, erkidego eta probintziaka."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 0e532c3339dc
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
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
SELECT cod, nombre AS comunidad, '/eu' || ruta AS ruta, euros_m2_real, precio_interanual_real, precio_vs_maximo_real,
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

# 🏠 Etxebizitza

Zenbat balio duen Espainian etxe bat erosteak edo alokatzeak, zenbat saltzen diren eta zenbat eraikitzen diren. Prezioak **inflazioa kenduta** erakusten dira ({urteko(precio.slice(-1)[0]?.anio_base)} eurotan) eta eragiketak **1.000 biztanleko**, urteak eta lurraldeak alderatu ahal izateko.

<Grid cols=4>
    <KpiCard
        title="Etxebizitzaren prezioa"
        value={precio.slice(-1)[0]?.euros_m2_real}
        formattedValue="{formatNumber(precio.slice(-1)[0]?.euros_m2_real, 0)} €/m²"
        period="tasazio-balioa, {precio.slice(-1)[0]?.periodo} · {formatNumber(precio.slice(-1)[0]?.precio_90m2_real / 1000, 0)} mila € 90 m²-ko pisu batek"
        change={precio.slice(-1)[0]?.interanual_real?.toFixed(1)}
        changePeriod="erreala, urtebete lehenagorekiko"
        direction="neutral"
        source="Etxebizitza Ministerioa"
        href="/eu/vivienda/precios"
        sparklineData={precio.filter(d => d.euros_m2_real != null).map(d => d.euros_m2_real)}
    />
    <KpiCard
        title="Pisu baten alokairu mediana"
        value={alquiler.slice(-1)[0]?.alquiler_mes_mediana_real}
        formattedValue="{formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana_real, 0)} €/hil."
        period="PFEZean aitortutako kontratuak, {alquiler.slice(-1)[0]?.anio}"
        change={alquiler.slice(-1)[0]?.variacion_real?.toFixed(1)}
        changePeriod="erreala, aurreko urtearekiko"
        direction="neutral"
        source="Etxebizitza Ministerioa (SERPAVI)"
        href="/eu/vivienda/alquiler"
        sparklineData={alquiler.map(d => d.alquiler_mes_mediana_real)}
    />
    <KpiCard
        title="Etxebizitzen salerosketak"
        value={mercado_ultimo[0]?.compraventas_12m_1000}
        formattedValue="{formatNumber(mercado_ultimo[0]?.compraventas_12m_1000, 1)} 1.000 biz."
        period="12 hilabete, {mercado_ultimo[0]?.mes_texto} arte · {formatCompact(mercado_ultimo[0]?.compraventas_12m, 0)} guztira"
        change={mercado_ultimo[0]?.var_anual?.toFixed(1)}
        changePeriod="urtebete lehenagorekiko"
        direction="neutral"
        source="INE / ETDP"
        href="/eu/vivienda/compraventas"
        sparklineData={mercado_mes.map(d => d.compraventas_12m_1000)}
    />
    <KpiCard
        title="90 m²-rako soldata-urteak"
        value={esfuerzo.slice(-1)[0]?.anios_salario}
        formattedValue="{formatNumber(esfuerzo.slice(-1)[0]?.anios_salario, 1)} urte"
        period="batez besteko soldata gordin osoa, {esfuerzo.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="Etxebizitza Ministerioa / INE"
        href="/eu/vivienda/esfuerzo"
        sparklineData={esfuerzo.map(d => d.anios_salario)}
    />
</Grid>

## Prezioa, inflazioarekin eta inflaziorik gabe

Etxebizitza libreen batez besteko tasazio-balioa, metro koadroko eurotan. Inflazioa kenduta, seriearen gehienekoa {hitos[0]?.periodo_max} aldikoa da, eta krisiaren ondorengo gutxienekoa, {hitos[0]?.periodo_min} aldikoa. Gaur metro koadroa {#if hitos[0]?.vs_max < 0}gehieneko haren {formatNumber(-hitos[0]?.vs_max, 0)} % azpitik dago{:else}gehienekoetan dago{/if}, eta gutxienekoaren {formatNumber(hitos[0]?.vs_min, 0)} % gainetik.

<LineChart
    data={precio_largo}
    x=fecha
    y=euros_m2
    series=serie
    yFmt='#,##0" €"'
    yAxisTitle="€/m²"
    startingAtZero={false}
    title="Etxebizitza libreen tasazio-balioa Espainian: {urteko(precio.slice(-1)[0]?.anio_base)} euroak urte bakoitzeko euroen aldean"
/>

## Zenbat erosten diren eta zenbat hipotekatzen diren

Jabetza-erregistroetan inskribatutako etxebizitzen salerosketak eta etxebizitzen gainean eratutako hipotekak, 1.000 biztanleko eta urteko.

<BarChart
    data={mercado_anual}
    x=anio
    y=por_1000
    series=operacion
    type=grouped
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="1.000 biztanleko"
    title="Etxebizitzen salerosketak eta hipotekak 1.000 biztanleko"
/>

## Erkidegoka

Metro koadroaren prezio erreala azken hiruhilekoan. Sakatu erkidego batean haren fitxa ikusteko.

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
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: Etxebizitza Ministerioa, INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'euros_m2_real', title: '€/m²', fmt: '#,##0'},
        {id: 'precio_interanual_real', title: 'Urteko aldaketa erreala (%)', fmt: '0.0'},
        {id: 'alquiler_mes_mediana_real', title: 'Alokairu mediana (€/hil.)', fmt: '#,##0'},
        {id: 'anios_salario', title: 'Soldata-urteak (90 m²)', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=euros_m2_real title="€/m² (erreala)" fmt='#,##0' />
    <Column id=precio_interanual_real title="Urteko aldaketa erreala %" fmt='0.0' contentType=delta />
    <Column id=precio_vs_maximo_real title="Gehieneko errealarekiko %" fmt='0.0' />
    <Column id=alquiler_mes_mediana_real title="Alokairua €/hil." fmt='#,##0' />
    <Column id=compraventas_12m_1000 title="Salerosketak 1.000 biz." fmt='0.0' />
    <Column id=anios_salario title="Soldata-urteak" fmt='0.0' />
</DataTable>

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/eu/vivienda/precios" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">💶</span> Prezioak</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Tasazio-balioa erkidego, probintzia eta udalerriaren arabera, eta INEren Etxebizitzaren Prezioen Indizea, berria eta bigarren eskukoa, inflazioa kenduta.</p>
    </a>
    <a href="/eu/vivienda/alquiler" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🔑</span> Alokairua</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Alokairu mediana erkidego, probintzia eta udalerriaren arabera, PFEZaren datuekin, eta zenbat etxebizitza alokatzen diren.</p>
    </a>
    <a href="/eu/vivienda/compraventas" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">📝</span> Salerosketak eta hipotekak</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Saldutako eta hipotekatutako etxebizitzak 1.000 biztanleko, obra berria bigarren eskukoaren aldean eta hipotekaren batez besteko zenbatekoa.</p>
    </a>
    <a href="/eu/vivienda/construccion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏗️</span> Obra berria</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Urtero hasten eta amaitzen diren etxebizitza libreak 1.000 biztanleko, 1991tik.</p>
    </a>
    <a href="/eu/vivienda/esfuerzo" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">⚖️</span> Ahalegina</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Etxebizitza batek zenbat urteko soldata balio duen eta soldataren zer zati joaten den alokairura, erkidegoka.</p>
    </a>
    <a href="/eu/vivienda/vivienda-publica" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-amber-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏘️</span> Alokairuko etxebizitza publikoa</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Alokairuko etxebizitza publikoak 1.000 biztanleko, erkidego, probintzia eta udalerriaren arabera, Herbehereekin, Austriarekin, Frantziarekin eta Europako batez bestekoarekin alderatuta, eta alderdika.</p>
    </a>
</div>

---

**Iturriak:** [Garraio eta Hiri Agendako Ministerioa, buletin estatistikoa](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000) (tasazio-balioa eta obra berria), [Alokairuaren Prezioaren Estatuko Erreferentzia Sistema](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi), [INE, Jabetza Eskubideen Eskualdaketen Estatistika](https://www.ine.es/jaxiT3/Tabla.htm?t=6150), [INE, Hipoteken Estatistika](https://www.ine.es/jaxiT3/Tabla.htm?t=13896) eta [INE, Lan Kostuaren Hiruhileko Inkesta](https://www.ine.es/jaxiT3/Tabla.htm?t=6061). INEren KPI orokorrarekin deflaktatua (2025 oinarria).
