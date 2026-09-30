---
title: Etxeak
description: "Etxeen batez besteko tamaina eta pertsona bakarreko etxeen ehunekoa Espainian, erkidego eta probintziaka, 2021etik (INE, Biztanleriaren Estatistika Jarraitua)."
i18n_origen: 36e2d1ec8163
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
</script>

```sql espana
SELECT CAST(h.anio AS INTEGER) AS anio, h.hogares, h.tamano_medio, h.unipersonales, h.pct_unipersonales,
    h.pct_2, h.pct_3, h.pct_4_o_mas
FROM mother.demografia_hogares h
WHERE h.nivel = 'pais'
ORDER BY anio
```

# 🏠 Etxeak

Zenbat pertsona bizi diren batez beste etxe bakoitzean eta zenbat etxe dauden pertsona bakar batez osatuta. Datuak INEren Biztanleriaren Estatistika Jarraitukoak dira, 2021etik argitaratzen dituena.

<Grid cols=4>
    <KpiCard
        title="Pertsonak etxeko"
        value={espana.slice(-1)[0]?.tamano_medio}
        formattedValue={formatNumber(espana.slice(-1)[0]?.tamano_medio, 2)}
        period="batez besteko tamaina, {urteko(espana.slice(-1)[0]?.anio)} urtarrilaren 1a · {formatNumber(espana[0]?.tamano_medio, 2)} {urtean(espana[0]?.anio)}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.tamano_medio}))}
    />
    <KpiCard
        title="Pertsona bakarreko etxeak"
        value={espana.slice(-1)[0]?.pct_unipersonales}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_unipersonales, 1)} %"
        period="etxeena · {formatCompact(espana.slice(-1)[0]?.unipersonales, 2)} etxe"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_unipersonales}))}
    />
    <KpiCard
        title="Bi pertsonako etxeak"
        value={espana.slice(-1)[0]?.pct_2}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_2, 1)} %"
        period="etxeena, {espana.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_2}))}
    />
    <KpiCard
        title="4 pertsonako edo gehiagoko etxeak"
        value={espana.slice(-1)[0]?.pct_4_o_mas}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_4_o_mas, 1)} %"
        period="etxeena · {formatCompact(espana.slice(-1)[0]?.hogares, 3)} etxe guztira"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_4_o_mas}))}
    />
</Grid>

<p class="text-xs text-gray-500">Familia-etxebizitzetan bizi diren pertsonen etxeak (ez ditu barne hartzen egoitzak, kuartelak, komentuak eta beste establezimendu kolektibo batzuk).</p>

## Etxeak pertsona kopuruaren arabera

```sql tamanos
SELECT anio, '1 persona' AS tamano, pct_unipersonales / 100 AS cuota FROM ${espana}
UNION ALL SELECT anio, '2 personas', pct_2 / 100 FROM ${espana}
UNION ALL SELECT anio, '3 personas', pct_3 / 100 FROM ${espana}
UNION ALL SELECT anio, '4 o más', pct_4_o_mas / 100 FROM ${espana}
ORDER BY anio
```

<BarChart
    data={tamanos}
    x=anio
    y=cuota
    series=tamano
    type=stacked
    yFmt=pct0
    xFmt="####"
    colorPalette={['#b45309', '#f59e0b', '#fcd34d', '#fef3c7']}
    title="Etxeak pertsona kopuruaren arabera (guztizkoaren %, urtarrilaren 1ean)"
/>

## Autonomia-erkidegoka

```sql ccaa
SELECT h.cod, t.nombre AS comunidad, '/eu' || t.ruta AS ruta, h.tamano_medio, h.pct_unipersonales / 100 AS unipersonales,
    h.pct_4_o_mas / 100 AS cuatro_o_mas, h.hogares
FROM mother.demografia_hogares h
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = h.cod
WHERE h.nivel = 'ccaa' AND h.anio = (SELECT max(anio) FROM mother.demografia_hogares)
ORDER BY h.tamano_medio DESC
```

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=tamano_medio title="Pertsonak etxeko" fmt=num2 contentType=bar barColor="#fde68a" />
    <Column id=unipersonales title="Pertsona bakarreko etxeak" fmt=pct1 />
    <Column id=cuatro_o_mas title="4 pertsonako edo gehiagoko etxeak" fmt=pct1 />
    <Column id=hogares title="Etxeak" fmt=num0 />
</DataTable>

## Probintziaka

```sql provincias
SELECT h.cod AS cod_prov, t.nombre AS provincia, '/eu' || t.ruta AS ruta, h.tamano_medio, h.pct_unipersonales / 100 AS unipersonales
FROM mother.demografia_hogares h
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = h.cod
WHERE h.nivel = 'provincia' AND h.anio = (SELECT max(anio) FROM mother.demografia_hogares)
ORDER BY h.pct_unipersonales DESC
```

Pertsona bakarreko etxeak {formatNumber(provincias[0]?.unipersonales / 0.01, 1)} %-tik ({provincias[0]?.provincia}) {formatNumber(provincias.slice(-1)[0]?.unipersonales / 0.01, 1)} %-ra ({provincias.slice(-1)[0]?.provincia}) bitartekoak dira.

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="unipersonales"
    valueFmt="pct1"
    link="ruta"
    colorPalette={['#fffbeb', '#f59e0b', '#78350f']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
    title="Pertsona bakarreko etxeak (etxeen %)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'unipersonales', title: 'Pertsona bakarreko etxeak', fmt: 'pct1'},
        {id: 'tamano_medio', title: 'Pertsonak etxeko', fmt: 'num2'}
    ]}
/>

---

## Iturriak eta oharrak

- **[INE – Biztanleriaren Estatistika Jarraitua: etxeak](https://www.ine.es/jaxiT3/Tabla.htm?t=60133)**: etxeak kide kopuruaren arabera, erkidegoka ([60131](https://www.ine.es/jaxiT3/Tabla.htm?t=60131)) eta probintziaka ([60133](https://www.ine.es/jaxiT3/Tabla.htm?t=60133)), eta etxearen batez besteko tamaina ([60132](https://www.ine.es/jaxiT3/Tabla.htm?t=60132) eta [60134](https://www.ine.es/jaxiT3/Tabla.htm?t=60134)). Urtarrilaren 1eko behin-behineko datuak; INEk hiruhilero argitaratzen ditu 2021etik. Etxeen Inkesta Jarraitu zaharra (2013-2020) ez da sartzen, metodoa desberdina delako.

<LastRefreshed prefix="Datuak eguneratuta" />
