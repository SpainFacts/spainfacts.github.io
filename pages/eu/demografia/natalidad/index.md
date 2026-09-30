---
title: Jaiotza-tasa eta ugalkortasuna
description: "Jaiotzak eta heriotzak 1.000 biztanleko, seme-alabak emakumeko, amen batez besteko adina eta ama atzerritarren jaiotzak Espainian, erkidego eta probintziaka, 1975etik (INE)."
i18n_origen: a59927850e3c
---

<script>
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

```sql anual
SELECT CAST(anio AS INTEGER) AS anio, nacimientos, defunciones, crecimiento_vegetativo,
    tasa_natalidad, tasa_mortalidad, vegetativo_1000, fecundidad, fecundidad_espanolas,
    fecundidad_extranjeras, edad_maternidad, edad_primer_hijo, pct_madre_extranjera
FROM mother.demografia_anual
WHERE nivel = 'pais'
ORDER BY anio
```

```sql ultimo
SELECT a.*, p.anio AS anio_pico, p.nacimientos AS nacimientos_pico, p.tasa_natalidad AS tasa_pico,
    f.anio AS anio_icf_max, f.fecundidad AS icf_max
FROM ${anual} a
CROSS JOIN (SELECT anio, nacimientos, tasa_natalidad FROM ${anual} WHERE anio >= 2000 ORDER BY nacimientos DESC LIMIT 1) p
CROSS JOIN (SELECT anio, fecundidad FROM ${anual} WHERE anio >= 1990 ORDER BY fecundidad DESC LIMIT 1) f
ORDER BY a.anio DESC
LIMIT 1
```

```sql primero
SELECT * FROM ${anual} ORDER BY anio LIMIT 1
```

```sql vegetativo_negativo
SELECT min(anio) AS desde, count(*) AS anios
FROM ${anual}
WHERE anio > (SELECT max(anio) FROM ${anual} WHERE vegetativo_1000 >= 0)
```

# 👶 Jaiotza-tasa eta ugalkortasuna

Zenbat haur jaiotzen diren Espainian biztanleriarekiko, zenbat seme-alaba dituen batez beste emakume bakoitzak, zer adinetan eta zenbat jaiotzen diren ama atzerritarrengandik, biztanleriaren hazkunde naturala markatzen duten heriotzekin batera.

<Grid cols=4>
    <KpiCard
        title="Jaiotza-tasa"
        value={ultimo[0]?.tasa_natalidad}
        formattedValue="{formatNumber(ultimo[0]?.tasa_natalidad, 2)} 1.000 biz."
        period="{formatNumber(ultimo[0]?.nacimientos, 0)} jaiotza {urtean(ultimo[0]?.anio)} · {formatNumber(primero[0]?.tasa_natalidad, 1)} {urtean(primero[0]?.anio)}"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.tasa_natalidad}))}
    />
    <KpiCard
        title="Seme-alabak emakumeko"
        value={ultimo[0]?.fecundidad}
        formattedValue={formatNumber(ultimo[0]?.fecundidad, 2)}
        period="{ultimo[0]?.anio} · {formatNumber(ultimo[0]?.fecundidad_espanolas, 2)} espainiarrek eta {formatNumber(ultimo[0]?.fecundidad_extranjeras, 2)} atzerritarrek"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.fecundidad}))}
    />
    <KpiCard
        title="Amen batez besteko adina"
        value={ultimo[0]?.edad_maternidad}
        formattedValue="{formatNumber(ultimo[0]?.edad_maternidad, 1)} urte"
        period="{formatNumber(ultimo[0]?.edad_primer_hijo, 1)} lehen seme-alaba izatean, {ultimo[0]?.anio}"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.edad_maternidad}))}
    />
    <KpiCard
        title="Ama atzerritarren jaiotzak"
        value={ultimo[0]?.pct_madre_extranjera}
        formattedValue="{formatNumber(ultimo[0]?.pct_madre_extranjera, 1)} %"
        period="{urtean(ultimo[0]?.anio)} jaiotakoena"
        source="INE"
        sparklineData={anual.filter(d => d.pct_madre_extranjera !== null).map(d => ({anio: d.anio, valor: d.pct_madre_extranjera}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('fecundidad')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'fecundidad')} />


<p class="text-xs text-gray-500">Tasak urteko batez besteko biztanleriaren gainean kalkulatzen dira. Ugalkortasun-adierazle konjunturala emakume batek bere bizitzan izango lukeen batez besteko seme-alaba kopurua da, urte horretako adinaren araberako ugalkortasun-tasek bere horretan jarraituko balute; biztanleria bat migraziorik gabe mantentzeko 2,1 inguru behar dira.</p>

## Jaiotzak eta heriotzak

{urtetik(primero[0]?.anio)}, jaiotza-tasa {formatNumber(primero[0]?.tasa_natalidad, 1)} jaiotzatik {formatNumber(ultimo[0]?.tasa_natalidad, 1)} jaiotzara igaro da 1.000 biztanleko. {urtetik(vegetativo_negativo[0]?.desde)}, urtero jaiotzen direnak baino pertsona gehiago hiltzen dira.

```sql tasas
SELECT anio, 'Nacimientos' AS fenomeno, tasa_natalidad AS por_1000 FROM ${anual}
UNION ALL
SELECT anio, 'Defunciones', tasa_mortalidad FROM ${anual}
ORDER BY anio
```

<Grid cols=2>
    <LineChart
        data={tasas}
        x=anio
        y=por_1000
        series=fenomeno
        yFmt=num1
        xFmt="####"
        colorPalette={['#db2777', '#475569']}
        yAxisTitle="1.000 biztanleko"
        title="Jaiotzak eta heriotzak 1.000 biztanleko"
    />
    <BarChart
        data={anual}
        x=anio
        y=vegetativo_1000
        yFmt=num1
        xFmt="####"
        fillColor="#be185d"
        yAxisTitle="1.000 biztanleko"
        title="Hazkunde begetatiboa (jaiotzak ken heriotzak) 1.000 biz."
    />
</Grid>

<p class="text-xs text-gray-500">2020ko heriotzen gailurra COVID-19aren pandemiari dagokio. Zenbaki absolututan, {urtean(ultimo[0]?.anio)} {formatNumber(ultimo[0]?.nacimientos, 0)} jaiotza eta Espainiako egoiliarren {formatNumber(ultimo[0]?.defunciones, 0)} heriotza izan ziren; mende honetako jaiotzen gehienekoa {urtean(ultimo[0]?.anio_pico)} izan zen, {formatNumber(ultimo[0]?.nacimientos_pico, 0)} jaiotzarekin.</p>

## Seme-alabak emakumeko

```sql fecundidad_nac
SELECT anio, 'Total' AS madre, fecundidad AS hijos FROM ${anual}
UNION ALL
SELECT anio, 'Madres españolas', fecundidad_espanolas FROM ${anual} WHERE fecundidad_espanolas IS NOT NULL
UNION ALL
SELECT anio, 'Madres extranjeras', fecundidad_extranjeras FROM ${anual} WHERE fecundidad_extranjeras IS NOT NULL
ORDER BY anio
```

```sql edad_madres
SELECT anio, 'Todos los hijos' AS hijo, edad_maternidad AS edad FROM ${anual}
UNION ALL
SELECT anio, 'Primer hijo', edad_primer_hijo FROM ${anual}
ORDER BY anio
```

<Grid cols=2>
    <LineChart
        data={fecundidad_nac}
        x=anio
        y=hijos
        series=madre
        yFmt=num2
        xFmt="####"
        colorPalette={['#1e293b', '#db2777', '#0f766e']}
        yAxisTitle="seme-alabak emakumeko"
        title="Ugalkortasun-adierazle konjunturala, amaren nazionalitatearen arabera"
    >
        <ReferenceLine y=2.1 label="Ordezkapena (2,1)" color="#94a3b8" />
    </LineChart>
    <LineChart
        data={edad_madres}
        x=anio
        y=edad
        series=hijo
        yFmt=num1
        xFmt="####"
        colorPalette={['#7c3aed', '#c4b5fd']}
        yAxisTitle="urteak"
        yMin=24
        title="Amatasunerako batez besteko adina"
    />
</Grid>

<p class="text-xs text-gray-500">Nazionalitatearen araberako ugalkortasuna 2002an hasten da. {urtean(ultimo[0]?.anio)}, emakume bakoitzak batez beste {formatNumber(ultimo[0]?.fecundidad, 2)} seme-alaba zituen; {urtean(primero[0]?.anio)}, berriz, {formatNumber(primero[0]?.fecundidad, 2)}; 1990etik izandako balio altuena {formatNumber(ultimo[0]?.icf_max, 2)} izan zen, {urtean(ultimo[0]?.anio_icf_max)}. Lehen seme-alabarako batez besteko adina {formatNumber(primero[0]?.edad_primer_hijo, 1)} urtetik {formatNumber(ultimo[0]?.edad_primer_hijo, 1)} urtera igaro da.</p>

```sql madre_extranjera
SELECT anio, pct_madre_extranjera / 100 AS cuota FROM ${anual} WHERE pct_madre_extranjera IS NOT NULL
```

<LineChart
    data={madre_extranjera}
    x=anio
    y=cuota
    yFmt=pct0
    xFmt="####"
    lineColor="#0f766e"
    title="Ama atzerritarren jaiotzak, guztizkoaren ehunekotan"
/>

<p class="text-xs text-gray-500">Amak erditzean zuen nazionalitatearen arabera; kanpoan jaio eta dagoeneko Espainiako nazionalitatea duen ama espainiartzat zenbatzen da.</p>

## Autonomia-erkidegoka

```sql ccaa
SELECT a.cod, t.nombre AS comunidad, '/eu' || t.ruta AS ruta,
    a.tasa_natalidad, a.tasa_mortalidad, a.vegetativo_1000, a.fecundidad,
    a.edad_maternidad, a.pct_madre_extranjera / 100 AS madre_extranjera, a.nacimientos
FROM mother.demografia_anual a
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = a.cod
WHERE a.nivel = 'ccaa' AND a.anio = (SELECT max(anio) FROM mother.demografia_anual WHERE tasa_natalidad IS NOT NULL)
ORDER BY a.fecundidad DESC
```

<Grid cols=2>
    <AreaMap
        data={ccaa}
        geoJsonUrl="/geo/ccaa.geojson"
        geoId="cod_ccaa"
        areaCol="cod"
        value="fecundidad"
        valueFmt="num2"
        link="ruta"
        colorPalette={['#fdf2f8', '#f472b6', '#9d174d']}
        height={400}
        basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
        attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
        title="Seme-alabak emakumeko, {ultimo[0]?.anio}"
        tooltip={[
            {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'fecundidad', title: 'Seme-alabak emakumeko', fmt: 'num2'},
            {id: 'tasa_natalidad', title: 'Jaiotzak 1.000 biz.', fmt: 'num1'},
            {id: 'edad_maternidad', title: 'Amaren batez besteko adina', fmt: 'num1'}
        ]}
    />
    <AreaMap
        data={ccaa}
        geoJsonUrl="/geo/ccaa.geojson"
        geoId="cod_ccaa"
        areaCol="cod"
        value="vegetativo_1000"
        valueFmt="num1"
        link="ruta"
        colorPalette={['#b91c1c', '#f8fafc', '#15803d']}
        height={400}
        basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
        attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
        title="Jaiotzak ken heriotzak 1.000 biz., {ultimo[0]?.anio}"
        tooltip={[
            {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'vegetativo_1000', title: 'Hazkunde begetatiboa 1.000 biz.', fmt: 'num1'},
            {id: 'tasa_natalidad', title: 'Jaiotzak 1.000 biz.', fmt: 'num1'},
            {id: 'tasa_mortalidad', title: 'Heriotzak 1.000 biz.', fmt: 'num1'}
        ]}
    />
</Grid>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=fecundidad title="Seme-alabak emakumeko" fmt=num2 contentType=bar barColor="#fbcfe8" />
    <Column id=tasa_natalidad title="Jaiotzak 1.000 biz." fmt=num1 />
    <Column id=tasa_mortalidad title="Heriotzak 1.000 biz." fmt=num1 />
    <Column id=vegetativo_1000 title="Begetatiboa 1.000 biz." fmt=num1 contentType=delta />
    <Column id=edad_maternidad title="Amaren batez besteko adina" fmt=num1 />
    <Column id=madre_extranjera title="Ama atzerritarra" fmt=pct1 />
    <Column id=nacimientos title="Jaiotzak" fmt=num0 />
</DataTable>

## Probintziaka

```sql provincias
SELECT a.cod AS cod_prov, t.nombre AS provincia, '/eu' || t.ruta AS ruta,
    a.tasa_natalidad, a.tasa_mortalidad, a.vegetativo_1000, a.fecundidad, a.edad_maternidad, a.nacimientos
FROM mother.demografia_anual a
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = a.cod
WHERE a.nivel = 'provincia' AND a.anio = (SELECT max(anio) FROM mother.demografia_anual WHERE tasa_natalidad IS NOT NULL)
ORDER BY a.tasa_natalidad DESC
```

```sql provincias_resumen
SELECT count(*) FILTER (WHERE vegetativo_1000 < 0) AS negativas, count(*) AS total,
    arg_max(provincia, tasa_natalidad) AS max_prov, max(tasa_natalidad) AS max_tasa,
    arg_min(provincia, tasa_natalidad) AS min_prov, min(tasa_natalidad) AS min_tasa
FROM ${provincias}
```

{urtean(ultimo[0]?.anio)}, {provincias_resumen[0]?.total} probintzietatik {provincias_resumen[0]?.negativas} probintziatan heriotza gehiago izan ziren jaiotzak baino. Jaiotza-tasa {formatNumber(provincias_resumen[0]?.max_tasa, 1)} jaiotzatik ({provincias_resumen[0]?.max_prov}) {formatNumber(provincias_resumen[0]?.min_tasa, 1)} jaiotzara ({provincias_resumen[0]?.min_prov}) bitartekoa da, 1.000 biztanleko.

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="tasa_natalidad"
    valueFmt="num1"
    link="ruta"
    colorPalette={['#fdf2f8', '#f472b6', '#9d174d']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
    title="Jaiotzak 1.000 biztanleko probintzia bakoitzean, {ultimo[0]?.anio}"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_natalidad', title: 'Jaiotzak 1.000 biz.', fmt: 'num1'},
        {id: 'tasa_mortalidad', title: 'Heriotzak 1.000 biz.', fmt: 'num1'},
        {id: 'fecundidad', title: 'Seme-alabak emakumeko', fmt: 'num2'},
        {id: 'nacimientos', title: 'Jaiotzak', fmt: 'num0'}
    ]}
/>

---

## Iturriak eta oharrak

- **[INE – Oinarrizko Adierazle Demografikoak](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002)**: jaiotza-tasa gordina ([1470](https://www.ine.es/jaxiT3/Tabla.htm?t=1470) eta [1432](https://www.ine.es/jaxiT3/Tabla.htm?t=1432) taulak) eta heriotza-tasa gordina ([1482](https://www.ine.es/jaxiT3/Tabla.htm?t=1482) eta [1445](https://www.ine.es/jaxiT3/Tabla.htm?t=1445)), ugalkortasun-adierazle konjunturala ([1478](https://www.ine.es/jaxiT3/Tabla.htm?t=1478) eta [1441](https://www.ine.es/jaxiT3/Tabla.htm?t=1441)), amatasunerako batez besteko adina ([1581](https://www.ine.es/jaxiT3/Tabla.htm?t=1581) eta [1580](https://www.ine.es/jaxiT3/Tabla.htm?t=1580)) eta jaioberriak amaren nazionalitatearen arabera ([2777](https://www.ine.es/jaxiT3/Tabla.htm?t=2777)).
- **[INE – Biztanleriaren Mugimendu Naturala](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177007)**: jaiotzak amaren bizilekuaren arabera ([6524](https://www.ine.es/jaxiT3/Tabla.htm?t=6524)) eta heriotzak bizilekuaren arabera ([6561](https://www.ine.es/jaxiT3/Tabla.htm?t=6561)). Behin betiko datuak; argitaratutako azken urtea {ultimo[0]?.anio} da.
- Hazkunde begetatiboa 1.000 biz. = jaiotza-tasa ken heriotza-tasa.

<LastRefreshed prefix="Datuak eguneratuta" />
