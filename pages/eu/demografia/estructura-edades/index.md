---
title: Adinak eta zahartzea
description: "Espainiako, erkidego bakoitzeko eta probintzia bakoitzeko biztanleria-piramideak; 65 eta 80 urtetik gorakoen ehunekoa, mendekotasun-tasa eta batez besteko adina 1971tik (INE)."
i18n_origen: 4e6c769248eb
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
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
SELECT CAST(anio AS INTEGER) AS anio, poblacion, mayores_65, mayores_80, pct_menores_16, pct_65, pct_80,
    dependencia, dependencia_mayores, indice_envejecimiento, edad_media
FROM mother.demografia_envejecimiento
WHERE nivel = 'pais'
ORDER BY anio
```

```sql inicio
SELECT * FROM ${espana} ORDER BY anio LIMIT 1
```

```sql anios
SELECT DISTINCT CAST(anio AS INTEGER) AS anio, CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio_txt
FROM mother.demografia_envejecimiento
ORDER BY anio DESC
```

# 🔺 Adinak eta zahartzea

Nola banatzen den biztanleria adinaren arabera, zenbat zahartu den Espainia 1971tik eta zein erkidego eta probintziak duten biztanleria zaharrena.

<Grid cols=4>
    <KpiCard
        title="65 urtetik gorakoak"
        value={espana.slice(-1)[0]?.pct_65}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_65, 1)} %"
        period="{formatCompact(espana.slice(-1)[0]?.mayores_65, 2)} pertsona {urtean(espana.slice(-1)[0]?.anio)} · {formatNumber(inicio[0]?.pct_65, 1)} % {urtean(inicio[0]?.anio)}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_65}))}
    />
    <KpiCard
        title="80 urtetik gorakoak"
        value={espana.slice(-1)[0]?.pct_80}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_80, 1)} %"
        period="{formatCompact(espana.slice(-1)[0]?.mayores_80, 2)} pertsona · {formatNumber(inicio[0]?.pct_80, 1)} % {urtean(inicio[0]?.anio)}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_80}))}
    />
    <KpiCard
        title="Mendekotasun-tasa"
        value={espana.slice(-1)[0]?.dependencia}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.dependencia, 1)} %"
        period="16 urtetik beherakoak eta 64 urtetik gorakoak 16-64 urteko 100 pertsonako, {espana.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.dependencia}))}
    />
    <KpiCard
        title="Batez besteko adina"
        value={espana.slice(-1)[0]?.edad_media}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.edad_media, 1)} urte"
        period="{espana.slice(-1)[0]?.anio} · {formatNumber(inicio[0]?.edad_media, 1)} urte {urtean(inicio[0]?.anio)}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.edad_media}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('poblacion_65')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'poblacion_65')} />


## Espainiako biztanleria-piramidea

Alderatu piramidearen forma bi urtetan. Barra bakoitza adin eta sexu hori duen biztanleria osoaren ehunekoa da; beraz, biztanleria desberdineko urteetako piramideak zuzenean alderatu daitezke.

<Dropdown data={anios} name=anio_a value=anio_txt title="Lehen urtea" defaultValue="1975" />
<Dropdown data={anios} name=anio_b value=anio_txt title="Bigarren urtea" />

```sql piramide_a
SELECT grupo, edad_desde, sexo, CASE WHEN sexo = 'Hombres' THEN -pct ELSE pct END AS pct
FROM mother.demografia_piramide
WHERE nivel = 'pais' AND CAST(anio AS INTEGER) = CAST('${inputs.anio_a.value}' AS INTEGER)
ORDER BY edad_desde, sexo
```

```sql piramide_b
SELECT grupo, edad_desde, sexo, CASE WHEN sexo = 'Hombres' THEN -pct ELSE pct END AS pct
FROM mother.demografia_piramide
WHERE nivel = 'pais' AND CAST(anio AS INTEGER) = CAST('${inputs.anio_b.value}' AS INTEGER)
ORDER BY edad_desde, sexo
```

<Grid cols=2>
    <BarChart
        data={piramide_a}
        x=grupo
        y=pct
        series=sexo
        swapXY=true
        type=stacked
        sort=false
        yFmt='0.0"%";0.0"%"'
        colorPalette={['#0f766e', '#7c3aed']}
        title="Espainia, {inputs.anio_a.value}"
    />
    <BarChart
        data={piramide_b}
        x=grupo
        y=pct
        series=sexo
        swapXY=true
        type=stacked
        sort=false
        yFmt='0.0"%";0.0"%"'
        colorPalette={['#0f766e', '#7c3aed']}
        title="Espainia, {inputs.anio_b.value}"
    />
</Grid>

## Erkidego eta probintzia bakoitzeko piramidea, jaioterriaren arabera

```sql territorios_opciones
SELECT '00' AS id, 'España' AS nombre, 0 AS orden
UNION ALL
SELECT 'c' || cod, nombre, 1 FROM mother.territorios WHERE nivel = 'ccaa'
UNION ALL
SELECT 'p' || cod, nombre || ' (provincia)', 2 FROM mother.territorios WHERE nivel = 'provincia'
ORDER BY orden, nombre
```

<Dropdown data={territorios_opciones} name=terr value=id label=nombre order=orden title="Lurraldea" defaultValue="00" />

```sql piramide_terr
WITH p AS (
    SELECT * FROM mother.demografia_piramide
    WHERE anio = (SELECT max(anio) FROM mother.demografia_piramide WHERE nacidos_extranjero IS NOT NULL)
      AND CASE WHEN '${inputs.terr.value}' = '00' THEN nivel = 'pais'
               WHEN left('${inputs.terr.value}', 1) = 'c' THEN nivel = 'ccaa' AND cod = substr('${inputs.terr.value}', 2)
               ELSE nivel = 'provincia' AND cod = substr('${inputs.terr.value}', 2) END
)
SELECT grupo, edad_desde, CAST(anio AS INTEGER) AS anio,
    CASE WHEN sexo = 'Hombres' THEN 'Hombres nacidos en España' ELSE 'Mujeres nacidas en España' END AS serie,
    CASE WHEN sexo = 'Hombres' THEN -1 ELSE 1 END * (pct - pct_nacidos_extranjero) AS pct,
    CASE WHEN sexo = 'Hombres' THEN 1 ELSE 3 END AS orden_serie
FROM p
UNION ALL
SELECT grupo, edad_desde, CAST(anio AS INTEGER),
    CASE WHEN sexo = 'Hombres' THEN 'Hombres nacidos en el extranjero' ELSE 'Mujeres nacidas en el extranjero' END,
    CASE WHEN sexo = 'Hombres' THEN -1 ELSE 1 END * pct_nacidos_extranjero,
    CASE WHEN sexo = 'Hombres' THEN 2 ELSE 4 END
FROM p
ORDER BY edad_desde, orden_serie
```

```sql terr_resumen
SELECT e.*, CAST(e.anio AS INTEGER) AS anio_int
FROM mother.demografia_envejecimiento e
WHERE anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
  AND CASE WHEN '${inputs.terr.value}' = '00' THEN nivel = 'pais'
           WHEN left('${inputs.terr.value}', 1) = 'c' THEN nivel = 'ccaa' AND cod = substr('${inputs.terr.value}', 2)
           ELSE nivel = 'provincia' AND cod = substr('${inputs.terr.value}', 2) END
```

<BarChart
    data={piramide_terr}
    x=grupo
    y=pct
    series=serie
    swapXY=true
    type=stacked
    sort=false
    yFmt='0.0"%";0.0"%"'
    colorPalette={['#0f766e', '#5eead4', '#7c3aed', '#c4b5fd']}
    height=460
    title="Biztanleria adinaren, sexuaren eta jaioterriaren arabera, {piramide_terr[0]?.anio} (guztizkoaren %)"
/>

<p class="text-xs text-gray-500">Lurralde honetan, {urteko(terr_resumen[0]?.anio_int)} urtarrilaren 1ean: 65 urtetik gorakoak {formatNumber(terr_resumen[0]?.pct_65, 1)} %, batez besteko adina {formatNumber(terr_resumen[0]?.edad_media, 1)} urte eta atzerrian jaiotakoak {formatNumber(terr_resumen[0]?.pct_nacidos_extranjero, 1)} %. Atzerrian jaiotzea ez da atzerritarra izatearen baliokidea: biztanleriaren {formatNumber(terr_resumen[0]?.pct_extranjeros, 1)} %-k du atzerriko nazionalitatea.</p>

## Nola zahartu den Espainia

```sql grandes_grupos
SELECT anio, 'Menores de 16' AS grupo, pct_menores_16 / 100 AS cuota FROM ${espana}
UNION ALL
SELECT anio, 'De 16 a 64', (100 - pct_menores_16 - pct_65) / 100 FROM ${espana}
UNION ALL
SELECT anio, 'De 65 a 79', (pct_65 - pct_80) / 100 FROM ${espana}
UNION ALL
SELECT anio, '80 y más', pct_80 / 100 FROM ${espana}
ORDER BY anio
```

```sql dependencia
SELECT anio, 'Total (menores de 16 y mayores de 64)' AS tasa, dependencia AS valor FROM ${espana}
UNION ALL
SELECT anio, 'Solo mayores de 64', dependencia_mayores FROM ${espana}
ORDER BY anio
```

```sql dep_min
SELECT anio, dependencia FROM ${espana} ORDER BY dependencia LIMIT 1
```

```sql cruce
SELECT min(anio) AS anio FROM ${espana} WHERE indice_envejecimiento >= 100
```

<Grid cols=2>
    <AreaChart
        data={grandes_grupos}
        x=anio
        y=cuota
        series=grupo
        type=stacked
        yFmt=pct0
        xFmt="####"
        colorPalette={['#60a5fa', '#94a3b8', '#fb923c', '#c2410c']}
        title="Biztanleria adin-talde handien arabera (guztizkoaren %)"
    />
    <LineChart
        data={dependencia}
        x=anio
        y=valor
        series=tasa
        yFmt=num1
        xFmt="####"
        colorPalette={['#1e293b', '#c2410c']}
        yAxisTitle="16-64 urteko 100 pertsonako"
        title="Mendekotasun-tasa"
    />
</Grid>

<p class="text-xs text-gray-500">{urtean(cruce[0]?.anio)}, Espainiak lehen aldiz izan zituen 64 urtetik gorako gehiago 16 urtetik beherakoak baino; gaur {formatNumber(espana.slice(-1)[0]?.indice_envejecimiento, 0)} adineko daude 100 adingabeko (zahartze-indizea). Mendekotasun-tasak gutxienekoa jo zuen {urtean(dep_min[0]?.anio)} ({formatNumber(dep_min[0]?.dependencia, 1)}); adinekoei dagokien zatia 16-64 urteko 100 pertsonako {formatNumber(inicio[0]?.dependencia_mayores, 1)} izatetik {formatNumber(espana.slice(-1)[0]?.dependencia_mayores, 1)} izatera igaro da.</p>

## Autonomia-erkidegoka

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/eu' || t.ruta AS ruta, e.pct_65 / 100 AS pct_65, e.pct_80 / 100 AS pct_80,
    e.pct_menores_16 / 100 AS pct_menores_16, e.dependencia, e.indice_envejecimiento, e.edad_media,
    e.pct_65 - e10.pct_65 AS cambio_65
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
JOIN mother.demografia_envejecimiento e10 ON e10.nivel = 'ccaa' AND e10.cod = e.cod AND e10.anio = e.anio - 10
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY e.pct_65 DESC
```

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=pct_65 title="65 eta gehiago" fmt=pct1 contentType=bar barColor="#fed7aa" />
    <Column id=pct_80 title="80 eta gehiago" fmt=pct1 />
    <Column id=pct_menores_16 title="16 urtetik behera" fmt=pct1 />
    <Column id=dependencia title="Mendekotasun-tasa" fmt=num1 />
    <Column id=indice_envejecimiento title="Adinekoak 100 adingabeko" fmt=num0 />
    <Column id=edad_media title="Batez besteko adina" fmt=num1 />
    <Column id=cambio_65 title="65+ duela 10 urterekiko (p.p.)" fmt=num1 contentType=delta />
</DataTable>

## Probintziaka

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/eu' || t.ruta AS ruta, e.pct_65 / 100 AS pct_65, e.pct_80 / 100 AS pct_80,
    e.edad_media, e.dependencia
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY e.pct_65 DESC
```

Probintzia zahartuena {provincias[0]?.provincia} da: 65 urtetik gorakoak {formatNumber(provincias[0]?.pct_65 / 0.01, 1)} % dira eta batez besteko adina {formatNumber(provincias[0]?.edad_media, 1)} urtekoa da; gazteena, {provincias.slice(-1)[0]?.provincia}, {formatNumber(provincias.slice(-1)[0]?.pct_65 / 0.01, 1)} %-rekin.

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="pct_65"
    valueFmt="pct1"
    link="ruta"
    colorPalette={['#fff7ed', '#fb923c', '#7c2d12']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
    title="65 urtetik gorakoak, biztanleriaren ehunekotan"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_65', title: '65 eta gehiago', fmt: 'pct1'},
        {id: 'pct_80', title: '80 eta gehiago', fmt: 'pct1'},
        {id: 'edad_media', title: 'Batez besteko adina', fmt: 'num1'},
        {id: 'dependencia', title: 'Mendekotasun-tasa', fmt: 'num1'}
    ]}
/>

---

## Iturriak eta oharrak

- **[INE – Biztanleriaren Estatistika Jarraitua](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (56945 taula): urtarrilaren 1eko biztanleria probintzia, sexu eta adin bakunaren arabera 1971tik. Erkidegoek beren probintziak batzen dituzte.
- **[INE – Biztanleria jaioterriaren arabera](https://www.ine.es/jaxiT3/Tabla.htm?t=56948)** (56948 taula): Espainian eta atzerrian jaiotakoak probintzia, sexu eta adin-taldearen arabera 2002tik.
- INEren Oinarrizko Adierazle Demografikoen definizioak: mendekotasun-tasa = (16 urtetik beherakoak + 64 urtetik gorakoak) / 16-64 urteko biztanleria × 100; zahartze-indizea = 64 urtetik gorakoak / 16 urtetik beherakoak × 100. Batez besteko adina adin bakunarekin kalkulatzen da (100 urteko eta gehiagoko taldea 100,5 gisa zenbatzen da); beraz, INEk argitaratzen duenetik hamarrenetan alda daiteke.

<LastRefreshed prefix="Datuak eguneratuta" />
