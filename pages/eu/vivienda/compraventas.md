---
title: Salerosketak eta hipotekak
description: "Etxebizitzen salerosketak eta etxebizitzen gaineko hipotekak Espainian 1.000 biztanleko, etxebizitza berria bigarren eskukoaren aldean eta hipotekaren batez besteko zenbatekoa inflazioa kenduta, erkidego eta probintziaka."
i18n_origen: ed62e0823b71
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

```sql mensual
SELECT fecha, strftime(fecha, '%m/%Y') AS mes_texto, compraventas_12m, compraventas_12m_1000, hipotecas_12m, hipotecas_12m_1000,
       importe_medio, importe_medio_real, anio_base
FROM mother.vivienda_mercado_mensual
WHERE nivel = 'pais'
ORDER BY fecha
```

```sql movil_largo
SELECT fecha, 'Compraventas' AS operacion, compraventas_12m_1000 AS por_1000 FROM ${mensual} WHERE compraventas_12m_1000 IS NOT NULL
UNION ALL
SELECT fecha, 'Hipotecas sobre viviendas' AS operacion, hipotecas_12m_1000 AS por_1000 FROM ${mensual} WHERE hipotecas_12m_1000 IS NOT NULL
ORDER BY fecha, operacion
```

```sql ultimo
SELECT
    u.mes_texto,
    u.compraventas_12m,
    u.compraventas_12m_1000,
    u.hipotecas_12m,
    u.hipotecas_12m_1000,
    100 * (u.compraventas_12m_1000 / a.compraventas_12m_1000 - 1) AS var_cv,
    100 * (u.hipotecas_12m_1000 / a.hipotecas_12m_1000 - 1) AS var_h
FROM ${mensual} u
LEFT JOIN ${mensual} a ON a.fecha = u.fecha - INTERVAL 1 YEAR
WHERE u.compraventas_12m_1000 IS NOT NULL
ORDER BY u.fecha DESC
LIMIT 1
```

```sql anual
SELECT anio, meses, compraventas, compraventas_1000, compraventas_nueva_1000, compraventas_segunda_mano_1000,
       hipotecas, hipotecas_1000, importe_medio, importe_medio_real, pct_nueva, pct_protegida, pct_hipoteca, anio_base
FROM mother.vivienda_mercado_anual
WHERE nivel = 'pais'
ORDER BY anio
```

```sql anual_completo
SELECT * FROM ${anual} WHERE meses = 12
```

```sql nueva_usada
SELECT anio, 'Nueva' AS tipo, compraventas_nueva_1000 AS por_1000 FROM ${anual_completo}
UNION ALL
SELECT anio, 'Segunda mano' AS tipo, compraventas_segunda_mano_1000 AS por_1000 FROM ${anual_completo}
ORDER BY anio, tipo
```

```sql importe
SELECT anio, 'Descontada la inflación' AS serie, importe_medio_real AS importe FROM mother.vivienda_mercado_anual WHERE nivel = 'pais' AND meses_hipotecas = 12
UNION ALL
SELECT anio, 'Sin descontar (euros de cada año)' AS serie, importe_medio AS importe FROM mother.vivienda_mercado_anual WHERE nivel = 'pais' AND meses_hipotecas = 12
ORDER BY anio, serie
```

```sql importe_ult
SELECT anio, importe_medio_real, importe_medio, meses_hipotecas
FROM mother.vivienda_mercado_anual
WHERE nivel = 'pais' AND meses_hipotecas = 12
ORDER BY anio DESC
LIMIT 1
```

```sql hitos
SELECT
    arg_max(anio, compraventas_1000) AS anio_max,
    max(compraventas_1000) AS max_1000,
    arg_min(anio, compraventas_1000) AS anio_min,
    min(compraventas_1000) AS min_1000,
    arg_max(compraventas_1000, anio) AS ult_1000,
    max(anio) AS anio_ult,
    arg_max(pct_nueva, anio) AS pct_nueva_ult,
    max(pct_nueva) FILTER (WHERE anio = 2008) AS pct_nueva_2008
FROM ${anual_completo}
```

```sql ccaa
SELECT r.cod, r.nombre AS comunidad, '/eu' || r.ruta AS ruta, r.compraventas_12m_1000, r.hipotecas_12m_1000, r.compraventas_12m,
       a.pct_nueva, a.importe_medio_real
FROM mother.vivienda_resumen_territorios r
LEFT JOIN mother.vivienda_mercado_anual a
  ON a.nivel = 'ccaa' AND a.cod = r.cod
 AND a.anio = (SELECT max(anio) FROM mother.vivienda_mercado_anual WHERE meses = 12)
WHERE r.nivel = 'ccaa'
ORDER BY r.compraventas_12m_1000 DESC
```

```sql provincias
SELECT r.cod AS cod_prov, r.nombre AS provincia, '/eu' || r.ruta AS ruta, r.compraventas_12m_1000, r.hipotecas_12m_1000, r.compraventas_12m,
       a.pct_nueva, a.importe_medio_real
FROM mother.vivienda_resumen_territorios r
LEFT JOIN mother.vivienda_mercado_anual a
  ON a.nivel = 'provincia' AND a.cod = r.cod
 AND a.anio = (SELECT max(anio) FROM mother.vivienda_mercado_anual WHERE meses = 12)
WHERE r.nivel = 'provincia'
ORDER BY r.compraventas_12m_1000 DESC
```

# 📝 Salerosketak eta hipotekak

Zenbat etxebizitzak aldatzen duten jabez urtero eta zenbat erosten diren hipotekarekin. **Jabetza-erregistroetan inskribatutako** salerosketak dira (sinatu eta hilabete edo bi geroago iritsi ohi dira) eta etxebizitzen gainean eratutako hipotekak, beti **1.000 biztanleko**. Hipotekaren zenbatekoa **inflazioa kenduta** erakusten da, {urteko(anual[0]?.anio_base)} eurotan.

<Grid cols=4>
    <KpiCard
        title="Etxebizitzen salerosketak"
        value={ultimo[0]?.compraventas_12m_1000}
        formattedValue="{formatNumber(ultimo[0]?.compraventas_12m_1000, 1)} 1.000 biz."
        period="12 hilabete, {ultimo[0]?.mes_texto} arte · {formatCompact(ultimo[0]?.compraventas_12m, 0)} guztira"
        change={ultimo[0]?.var_cv?.toFixed(1)}
        changePeriod="urtebete lehenagorekiko"
        source="INE / ETDP"
        sparklineData={mensual.filter(d => d.compraventas_12m_1000 != null).map(d => d.compraventas_12m_1000)}
    />
    <KpiCard
        title="Etxebizitzen gaineko hipotekak"
        value={ultimo[0]?.hipotecas_12m_1000}
        formattedValue="{formatNumber(ultimo[0]?.hipotecas_12m_1000, 1)} 1.000 biz."
        period="12 hilabete, {ultimo[0]?.mes_texto} arte · {formatCompact(ultimo[0]?.hipotecas_12m, 0)} guztira"
        change={ultimo[0]?.var_h?.toFixed(1)}
        changePeriod="urtebete lehenagorekiko"
        source="INE / Hipotekak"
        sparklineData={mensual.filter(d => d.hipotecas_12m_1000 != null).map(d => d.hipotecas_12m_1000)}
    />
    <KpiCard
        title="Batez besteko hipoteka"
        value={importe_ult[0]?.importe_medio_real}
        formattedValue="{formatNumber(importe_ult[0]?.importe_medio_real / 1000, 0)} mila €"
        period="etxebizitzako {urtean(importe_ult[0]?.anio)}, {urteko(anual[0]?.anio_base)} eurotan"
        source="INE / Hipotekak"
        sparklineData={anual.filter(d => d.importe_medio_real != null).map(d => d.importe_medio_real)}
    />
    <KpiCard
        title="Etxebizitza berria"
        value={hitos[0]?.pct_nueva_ult}
        formattedValue="{formatNumber(hitos[0]?.pct_nueva_ult, 1)} %"
        period="salerosketena {urtean(hitos[0]?.anio_ult)} · {formatNumber(hitos[0]?.pct_nueva_2008, 0)} % 2008an"
        source="INE / ETDP"
        sparklineData={anual_completo.map(d => d.pct_nueva)}
    />
</Grid>

## Bilakaera

Azken 12 hilabeteen batura, 1.000 biztanleko. Seriean (2007tik) biztanleko salerosketa gehien izan zituen urtea {hitos[0]?.anio_max} da, {formatNumber(hitos[0]?.max_1000, 1)} salerosketarekin; gutxienekoa, {hitos[0]?.anio_min}, {formatNumber(hitos[0]?.min_1000, 1)} salerosketarekin. {urtean(hitos[0]?.anio_ult)} {formatNumber(hitos[0]?.ult_1000, 1)} izan ziren.

<LineChart
    data={movil_largo}
    x=fecha
    y=por_1000
    series=operacion
    yFmt='0.0'
    yAxisTitle="1.000 biz. (12 hilabete)"
    title="Etxebizitzen salerosketak eta hipotekak 1.000 biztanleko, 12 hilabeteko batura mugikorra"
/>

## Berria edo bigarren eskukoa

<BarChart
    data={nueva_usada}
    x=anio
    y=por_1000
    series=tipo
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="1.000 biztanleko"
    title="Etxebizitzen salerosketak 1.000 biztanleko: berria eta bigarren eskukoa"
/>

## Zenbat eskatzen den mailegutan

Etxebizitzen gainean eratutako hipoteken batez besteko zenbatekoa, inflazioarekin eta inflaziorik gabe. Hipotekak 100 salerosketako: {formatNumber(anual_completo.slice(-1)[0]?.pct_hipoteca, 0)} {urtean(anual_completo.slice(-1)[0]?.anio)}. Ez dira eragiketa berberak (erosi berri ez diren etxebizitzak ere hipotekatzen dira), baina erosketetatik zenbat finantzatzen diren maileguarekin jakiteko ideia ematen du.

<LineChart
    data={importe}
    x=anio
    y=importe
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ hipotekako"
    startingAtZero={false}
    title="Etxebizitzaren gaineko hipotekaren batez besteko zenbatekoa"
/>

<LineChart
    data={anual_completo}
    x=anio
    y=pct_hipoteca
    xFmt='0'
    yFmt='0'
    yAxisTitle="hipotekak 100 salerosketako"
    title="Etxebizitzen gaineko hipotekak 100 salerosketako"
/>

## Erkidegoka

Azken 12 hilabeteetako salerosketak 1.000 biztanleko.

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="compraventas_12m_1000"
    valueFmt="num1"
    link="ruta"
    colorPalette={['#e0f2fe', '#38bdf8', '#075985']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'compraventas_12m_1000', title: 'Salerosketak 1.000 biz.', fmt: 'num1'},
        {id: 'hipotecas_12m_1000', title: 'Hipotekak 1.000 biz.', fmt: 'num1'},
        {id: 'pct_nueva', title: 'Etxebizitza berriaren %', fmt: 'num1'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=compraventas_12m_1000 title="Salerosketak 1.000 biz." fmt='0.0' />
    <Column id=hipotecas_12m_1000 title="Hipotekak 1.000 biz." fmt='0.0' />
    <Column id=pct_nueva title="Berrien %" fmt='0.0' />
    <Column id=importe_medio_real title="Batez besteko hipoteka (€, erreala)" fmt='#,##0' />
    <Column id=compraventas_12m title="Salerosketak (12 hilabete)" fmt='#,##0' />
</DataTable>

## Probintziaka

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="compraventas_12m_1000"
    valueFmt="num1"
    link="ruta"
    colorPalette={['#e0f2fe', '#38bdf8', '#075985']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'compraventas_12m_1000', title: 'Salerosketak 1.000 biz.', fmt: 'num1'},
        {id: 'hipotecas_12m_1000', title: 'Hipotekak 1.000 biz.', fmt: 'num1'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Probintzia" />
    <Column id=compraventas_12m_1000 title="Salerosketak 1.000 biz." fmt='0.0' />
    <Column id=hipotecas_12m_1000 title="Hipotekak 1.000 biz." fmt='0.0' />
    <Column id=pct_nueva title="Berrien %" fmt='0.0' />
    <Column id=importe_medio_real title="Batez besteko hipoteka (€, erreala)" fmt='#,##0' />
</DataTable>

---

**Iturriak:** [INE, Jabetza Eskubideen Eskualdaketen Estatistika, 6150 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=6150) (inskribatutako etxebizitzen salerosketak, hilero 2007tik) eta [INE, Hipoteken Estatistika, 13896](https://www.ine.es/jaxiT3/Tabla.htm?t=13896) [eta 3200 taulak](https://www.ine.es/jaxiT3/Tabla.htm?t=3200) (etxebizitzen gainean eratutako hipotekak, 2003tik). Biztanleria: INE, urtarrilaren 1ean. Zenbatekoak INEren KPI orokorrarekin deflaktatuak (2025 oinarria), hilez hil.
