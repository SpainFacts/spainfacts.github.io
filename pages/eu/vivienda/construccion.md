---
title: Obra berria
description: "Espainian urtero hasten eta amaitzen diren etxebizitza libreak 1.000 biztanleko 1996tik, erkidego eta probintziaka, Etxebizitza Ministerioaren datuekin."
i18n_origen: 442b873cd088
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
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
SELECT anio, iniciadas, terminadas, iniciadas_1000, terminadas_1000
FROM mother.vivienda_obra_nueva
WHERE nivel = 'pais' AND iniciadas_1000 IS NOT NULL
ORDER BY anio
```

```sql espana_largo
SELECT anio, 'Iniciadas' AS fase, iniciadas_1000 AS por_1000 FROM ${espana}
UNION ALL
SELECT anio, 'Terminadas' AS fase, terminadas_1000 AS por_1000 FROM ${espana}
ORDER BY anio, fase
```

```sql hitos
SELECT
    max(anio) AS anio_ult,
    arg_max(terminadas_1000, anio) AS term_ult,
    arg_max(iniciadas_1000, anio) AS ini_ult,
    arg_max(terminadas, anio) AS term_total,
    arg_max(iniciadas, anio) AS ini_total,
    max(terminadas_1000) AS term_max,
    arg_max(anio, terminadas_1000) AS anio_term_max,
    max(iniciadas_1000) AS ini_max,
    arg_max(anio, iniciadas_1000) AS anio_ini_max,
    min(terminadas_1000) AS term_min,
    arg_min(anio, terminadas_1000) AS anio_term_min,
    arg_max(terminadas_1000, anio) / max(terminadas_1000) AS fraccion_max,
    avg(terminadas_1000) FILTER (WHERE anio BETWEEN 1996 AND 2000) AS media_9600
FROM ${espana}
```

```sql mercado
SELECT o.anio, o.terminadas_1000, m.compraventas_nueva_1000
FROM mother.vivienda_obra_nueva o
JOIN mother.vivienda_mercado_anual m ON m.nivel = 'pais' AND m.anio = o.anio AND m.meses = 12
WHERE o.nivel = 'pais'
ORDER BY o.anio
```

```sql mercado_largo
SELECT anio, 'Viviendas libres terminadas' AS serie, terminadas_1000 AS por_1000 FROM ${mercado}
UNION ALL
SELECT anio, 'Compraventas de vivienda nueva' AS serie, compraventas_nueva_1000 AS por_1000 FROM ${mercado}
ORDER BY anio, serie
```

```sql ccaa
SELECT o.cod, o.nombre AS comunidad, '/eu' || t.ruta AS ruta, o.anio, o.iniciadas_1000, o.terminadas_1000, o.iniciadas, o.terminadas,
       (SELECT avg(x.terminadas_1000) FROM mother.vivienda_obra_nueva x WHERE x.nivel = 'ccaa' AND x.cod = o.cod AND x.anio BETWEEN o.anio - 4 AND o.anio) AS terminadas_1000_5a
FROM mother.vivienda_obra_nueva o
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = o.cod
WHERE o.nivel = 'ccaa' AND o.anio = (SELECT max(anio) FROM mother.vivienda_obra_nueva)
ORDER BY o.terminadas_1000 DESC
```

```sql provincias
SELECT o.cod AS cod_prov, o.nombre AS provincia, '/eu' || t.ruta AS ruta, o.iniciadas_1000, o.terminadas_1000, o.iniciadas, o.terminadas
FROM mother.vivienda_obra_nueva o
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = o.cod
WHERE o.nivel = 'provincia' AND o.anio = (SELECT max(anio) FROM mother.vivienda_obra_nueva)
ORDER BY o.terminadas_1000 DESC
```

# 🏗️ Obra berria

Zenbat etxebizitza eraikitzen diren Espainian. **Etxebizitza libreak** dira (babestuak kanpo) urtero hasten direnak (**hasiak**) eta amaitzen direnak (**amaituak**), Etxebizitza Ministerioak aparejadoreen elkargoen ziurtagirietatik abiatuta estimatuak, beti **1.000 biztanleko**.

<Grid cols=4>
    <KpiCard
        title="Amaitutako etxebizitzak"
        value={hitos[0]?.term_ult}
        formattedValue="{formatNumber(hitos[0]?.term_ult, 2)} 1.000 biz."
        period="{hitos[0]?.anio_ult} · {formatCompact(hitos[0]?.term_total, 0)} etxebizitza libre"
        source="Etxebizitza Ministerioa"
        sparklineData={espana.map(d => ({...d, y: d.terminadas_1000}))}
    />
    <KpiCard
        title="Hasitako etxebizitzak"
        value={hitos[0]?.ini_ult}
        formattedValue="{formatNumber(hitos[0]?.ini_ult, 2)} 1.000 biz."
        period="{hitos[0]?.anio_ult} · {formatCompact(hitos[0]?.ini_total, 0)} etxebizitza libre"
        source="Etxebizitza Ministerioa"
        sparklineData={espana.map(d => ({...d, y: d.iniciadas_1000}))}
    />
    <KpiCard
        title="Gehienekoarekiko"
        value={hitos[0]?.fraccion_max}
        formattedValue="{formatNumber(hitos[0]?.fraccion_max / 0.01, 0)} %"
        period="{urteko(hitos[0]?.anio_term_max)} biztanleko amaitutako etxebizitzena ({formatNumber(hitos[0]?.term_max, 1)} 1.000 biz.)"
        source="Etxebizitza Ministerioa"
        sparklineData={espana.map(d => ({...d, y: d.terminadas_1000}))}
    />
    <KpiCard
        title="90eko hamarkadaren amaierarekiko"
        value={hitos[0]?.media_9600}
        formattedValue="{formatNumber(hitos[0]?.media_9600, 1)} 1.000 biz."
        period="urtean amaitutako etxebizitzak, batez beste, 1996-2000 aldian"
        source="Etxebizitza Ministerioa"
        sparklineData={espana.filter(d => d.anio <= 2000).map(d => ({...d, y: d.terminadas_1000}))}
    />
</Grid>

## Bilakaera

Biztanleko amaitutako etxebizitzen gehienekoa {urtean(hitos[0]?.anio_term_max)} izan zen ({formatNumber(hitos[0]?.term_max, 1)} 1.000 biztanleko), eta gutxienekoa {urtean(hitos[0]?.anio_term_min)} ({formatNumber(hitos[0]?.term_min, 2)}). {urtean(hitos[0]?.anio_ult)}, {formatNumber(hitos[0]?.term_ult, 2)} amaitu ziren 1.000 biztanleko, eta {formatNumber(hitos[0]?.ini_ult, 2)} hasi.

<LineChart
    data={espana_largo}
    x=anio
    y=por_1000
    series=fase
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="1.000 biztanleko"
    title="Hasitako eta amaitutako etxebizitza libreak 1.000 biztanleko"
/>

Amaitutako etxebizitzak INEk erregistratzen dituen etxebizitza berrien salerosketekin alderatu daitezke (babestuak ere barne hartzen dituzte):

<LineChart
    data={mercado_largo}
    x=anio
    y=por_1000
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="1.000 biztanleko"
    title="Amaitutako etxebizitzak eta etxebizitza berrien salerosketak 1.000 biztanleko"
/>

## Erkidegoka

Amaitutako etxebizitza libreak 1.000 biztanleko, {urtean(ccaa[0]?.anio)}.

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="terminadas_1000"
    valueFmt="num2"
    link="ruta"
    colorPalette={['#ecfccb', '#84cc16', '#365314']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: Etxebizitza Ministerioa"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'terminadas_1000', title: 'Amaituak 1.000 biz.', fmt: 'num2'},
        {id: 'iniciadas_1000', title: 'Hasiak 1.000 biz.', fmt: 'num2'},
        {id: 'terminadas', title: 'Amaituak', fmt: 'num0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=terminadas_1000 title="Amaituak 1.000 biz." fmt='0.00' />
    <Column id=terminadas_1000_5a title="5 urteko batez bestekoa" fmt='0.00' />
    <Column id=iniciadas_1000 title="Hasiak 1.000 biz." fmt='0.00' />
    <Column id=terminadas title="Amaituak" fmt='#,##0' />
</DataTable>

## Probintziaka

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Probintzia" />
    <Column id=terminadas_1000 title="Amaituak 1.000 biz." fmt='0.00' />
    <Column id=iniciadas_1000 title="Hasiak 1.000 biz." fmt='0.00' />
    <Column id=terminadas title="Amaituak" fmt='#,##0' />
    <Column id=iniciadas title="Hasiak" fmt='#,##0' />
</DataTable>

---

**Iturriak:** [Garraio eta Hiri Agendako Ministerioa, buletin estatistikoa: hasitako eta amaitutako etxebizitza libreak](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=32000000) (3.1 eta 3.2 taulak, urtekoak 1991tik, aparejadoreen elkargoen ziurtagirietatik abiatuta; biztanleko seriea 1996an hasten da, INEren biztanleriaren lehen urtean) eta [INE, Jabetza Eskubideen Eskualdaketen Estatistika](https://www.ine.es/jaxiT3/Tabla.htm?t=6150).
