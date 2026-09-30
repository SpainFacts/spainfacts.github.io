---
title: Biztanleriaren lurralde-banaketa
description: "Nola banatzen den Espainiako biztanleria erkidego eta probintzien artean 1975etik: kontzentrazioa, biztanleak galtzen dituzten probintziak eta atzerrian jaiotakoen ehunekoa probintzia bakoitzean (INE)."
i18n_origen: c8fbe04365c1
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

```sql prov_serie
SELECT CAST(e.anio AS INTEGER) AS anio, e.cod, e.poblacion, a.poblacion AS poblacion_antes,
    e.poblacion / sum(e.poblacion) OVER (PARTITION BY e.anio) AS cuota,
    row_number() OVER (PARTITION BY e.anio ORDER BY e.poblacion DESC) AS puesto
FROM mother.demografia_envejecimiento e
LEFT JOIN mother.demografia_envejecimiento a ON a.nivel = 'provincia' AND a.cod = e.cod AND a.anio = e.anio - 1
WHERE e.nivel = 'provincia'
```

```sql concentracion
SELECT anio,
    count(*) FILTER (WHERE poblacion < poblacion_antes) AS pierden,
    100 * sum(cuota) FILTER (WHERE puesto <= 5) AS pct_top5,
    count(*) FILTER (WHERE acumulada - cuota < 0.5) AS provincias_mitad
FROM (SELECT *, sum(cuota) OVER (PARTITION BY anio ORDER BY puesto) AS acumulada FROM ${prov_serie})
WHERE anio >= 1975
GROUP BY anio
ORDER BY anio
```

```sql origen
SELECT CAST(anio AS INTEGER) AS anio, pct_nacidos_extranjero, nacidos_extranjero, pct_extranjeros
FROM mother.demografia_envejecimiento
WHERE nivel = 'pais' AND pct_nacidos_extranjero IS NOT NULL
ORDER BY anio
```

# 🗺️ Biztanleriaren lurralde-banaketa

Non bizi den Espainiako biztanleria, zein erkidego eta probintziak irabazten eta galtzen duten pisua eta zein probintziatan den handiagoa atzerrian jaiotako pertsonen proportzioa.

<Grid cols=4>
    <KpiCard
        title="Biztanleriaren erdia hemen bizi da:"
        value={concentracion.slice(-1)[0]?.provincias_mitad}
        formattedValue="{concentracion.slice(-1)[0]?.provincias_mitad} probintzia"
        period="52tik, {urteko(concentracion.slice(-1)[0]?.anio)} urtarrilaren 1ean · {concentracion[0]?.provincias_mitad} {urtean(concentracion[0]?.anio)}"
        source="INE"
        sparklineData={concentracion.map(d => ({anio: d.anio, valor: d.provincias_mitad}))}
    />
    <KpiCard
        title="Biztanle gehien dituzten 5 probintziak"
        value={concentracion.slice(-1)[0]?.pct_top5}
        formattedValue="{formatNumber(concentracion.slice(-1)[0]?.pct_top5, 1)} %"
        period="biztanleriarena · {formatNumber(concentracion[0]?.pct_top5, 1)} % {urtean(concentracion[0]?.anio)}"
        source="INE"
        sparklineData={concentracion.map(d => ({anio: d.anio, valor: d.pct_top5}))}
    />
    <KpiCard
        title="Biztanleak galtzen dituzten probintziak"
        value={concentracion.slice(-1)[0]?.pierden}
        formattedValue="{concentracion.slice(-1)[0]?.pierden} / 52"
        period="urtebete lehenago baino biztanle gutxiago zituzten {urteko(concentracion.slice(-1)[0]?.anio)} urtarrilaren 1ean"
        direction="positive-down"
        source="INE"
        sparklineData={concentracion.map(d => ({anio: d.anio, valor: d.pierden}))}
    />
    <KpiCard
        title="Atzerrian jaiotakoak"
        value={origen.slice(-1)[0]?.pct_nacidos_extranjero}
        formattedValue="{formatNumber(origen.slice(-1)[0]?.pct_nacidos_extranjero, 1)} %"
        period="biztanleriarena · {formatCompact(origen.slice(-1)[0]?.nacidos_extranjero, 2)} pertsona {urtean(origen.slice(-1)[0]?.anio)}"
        source="INE"
        href="/eu/sociedad/inmigracion"
        sparklineData={origen.map(d => ({anio: d.anio, valor: d.pct_nacidos_extranjero}))}
    />
</Grid>

<p class="text-xs text-gray-500">Urtarrilaren 1eko biztanleria, Biztanleriaren Estatistika Jarraituaren arabera. Probintziak biztanleria handienetik txikienera ordenatzen dira, biztanleen erdia batzeko zenbat behar diren zenbatzeko.</p>

## Erkidego bakoitzaren pisua

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/eu' || t.ruta AS ruta,
    e.poblacion / p.poblacion AS peso,
    e75.poblacion / p75.poblacion AS peso_1975,
    100.0 * (e.poblacion / p.poblacion - e75.poblacion / p75.poblacion) AS cambio_pp,
    100.0 * (e.poblacion / e75.poblacion - 1) AS crec_1975,
    e.poblacion
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
JOIN mother.demografia_envejecimiento p ON p.nivel = 'pais' AND p.anio = e.anio
JOIN mother.demografia_envejecimiento e75 ON e75.nivel = 'ccaa' AND e75.cod = e.cod AND e75.anio = 1975
JOIN mother.demografia_envejecimiento p75 ON p75.nivel = 'pais' AND p75.anio = 1975
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY cambio_pp DESC
```

1975etik, Espainiako biztanlerian pisu gehien irabazi duen erkidegoa {ccaa[0]?.comunidad} da ({formatNumber(ccaa[0]?.cambio_pp, 1)} puntu), eta gehien galdu duena, {ccaa.slice(-1)[0]?.comunidad} ({formatNumber(ccaa.slice(-1)[0]?.cambio_pp, 1)} puntu).

<BarChart
    data={ccaa}
    x=comunidad
    y=cambio_pp
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#059669"
    title="Erkidego bakoitzak Espainiako biztanlerian duen pisuaren aldaketa 1975etik (ehuneko-puntuak)"
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=peso title="Egungo pisua" fmt=pct1 contentType=bar barColor="#a7f3d0" />
    <Column id=peso_1975 title="Pisua 1975ean" fmt=pct1 />
    <Column id=cambio_pp title="Aldaketa (p.p.)" fmt=num2 contentType=delta />
    <Column id=crec_1975 title="Hazkundea 1975etik (%)" fmt=num1 />
    <Column id=poblacion title="Biztanleria" fmt=num0 />
</DataTable>

## Biztanleak irabazten eta galtzen dituzten probintziak

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/eu' || t.ruta AS ruta, e.poblacion,
    100.0 * (e.poblacion / e75.poblacion - 1) AS crec_1975,
    e.pct_nacidos_extranjero / 100 AS nacidos_extranjero,
    e.pct_extranjeros / 100 AS extranjeros
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
JOIN mother.demografia_envejecimiento e75 ON e75.nivel = 'provincia' AND e75.cod = e.cod AND e75.anio = 1975
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY crec_1975 DESC
```

```sql provincias_resumen
SELECT count(*) FILTER (WHERE crec_1975 < 0) AS pierden_1975,
    arg_max(provincia, nacidos_extranjero) AS max_prov, max(nacidos_extranjero) AS max_pct,
    arg_min(provincia, nacidos_extranjero) AS min_prov, min(nacidos_extranjero) AS min_pct
FROM ${provincias}
```

{provincias_resumen[0]?.pierden_1975} probintziak biztanle gutxiago dituzte gaur 1975ean baino. Gehien hazi dena {provincias[0]?.provincia} da ({formatNumber(provincias[0]?.crec_1975, 0)} %), eta gehien galdu duena, {provincias.slice(-1)[0]?.provincia} ({formatNumber(provincias.slice(-1)[0]?.crec_1975, 0)} %).

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="crec_1975"
    valueFmt="num0"
    link="ruta"
    colorPalette={['#b91c1c', '#f8fafc', '#1d4ed8']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
    title="Biztanleriaren aldaketa 1975etik (%)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'crec_1975', title: 'Aldaketa 1975etik (%)', fmt: 'num1'},
        {id: 'poblacion', title: 'Biztanleria', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Bilakaera berriena (azken 10 urteak) hemen dago: <a href="/eu/demografia/evolucion-poblacion">Biztanleriaren bilakaera</a>; eta udalerrikako xehetasuna, <a href="/eu/territorios">lurraldeen</a> fitxetan.</p>

## Atzerrian jaiotakoak probintziaka

Beste herrialde batean jaiotako egoiliarren proportzioa {formatNumber(provincias_resumen[0]?.max_pct / 0.01, 1)} %-tik ({provincias_resumen[0]?.max_prov}) {formatNumber(provincias_resumen[0]?.min_pct / 0.01, 1)} %-ra ({provincias_resumen[0]?.min_prov}) bitartekoa da.

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="nacidos_extranjero"
    valueFmt="pct1"
    link="ruta"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
    title="Atzerrian jaiotako biztanleria (biztanleriaren %)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'nacidos_extranjero', title: 'Atzerrian jaiotakoak', fmt: 'pct1'},
        {id: 'extranjeros', title: 'Atzerriko nazionalitatearekin', fmt: 'pct1'}
    ]}
/>

<p class="text-xs text-gray-500">Atzerrian jaiotzea ez da atzerritarra izatearen baliokidea: Espainiako nazionalitatea lortu dutenak eta kanpoan jaiotako espainiarren seme-alabak ere barne hartzen ditu. Espainian, biztanleriaren {formatNumber(origen.slice(-1)[0]?.pct_nacidos_extranjero, 1)} % kanpoan jaio zen, eta {formatNumber(origen.slice(-1)[0]?.pct_extranjeros, 1)} %-k atzerriko nazionalitatea du.</p>

---

## Iturriak eta oharrak

- **[INE – Biztanleriaren Estatistika Jarraitua](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (56945 taula): urtarrilaren 1eko biztanleria probintziaka 1971tik.
- **[INE – Biztanleria jaioterriaren arabera](https://www.ine.es/jaxiT3/Tabla.htm?t=56948)** (56948 taula) eta **[nazionalitatearen arabera](https://www.ine.es/jaxiT3/Tabla.htm?t=56947)** (56947 taula), probintziaka, 2002tik.

<LastRefreshed prefix="Datuak eguneratuta" />
