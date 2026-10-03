---
title: Biztanleriaren bilakaera
description: "Espainiako biztanleria 1971tik eta haren urteko hazkundea 1.000 biztanleko, jaiotzak ken heriotzak eta migrazioa bereizita, erkidego eta probintziaka (INE)."
i18n_origen: f9535ffb3b9d
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

```sql poblacion
SELECT CAST(anio AS INTEGER) AS anio, poblacion, poblacion / 1e6 AS millones
FROM mother.demografia_envejecimiento
WHERE nivel = 'pais'
ORDER BY anio
```

```sql anual
SELECT CAST(anio AS INTEGER) AS anio, crecimiento, crecimiento_1000, vegetativo_1000, resto_1000,
    crecimiento_vegetativo, resto, saldo_exterior_1000
FROM mother.demografia_anual
WHERE nivel = 'pais' AND crecimiento_1000 IS NOT NULL
ORDER BY anio
```

```sql resumen
SELECT
    (SELECT anio FROM ${poblacion} ORDER BY anio DESC LIMIT 1) AS anio_pob,
    (SELECT poblacion FROM ${poblacion} ORDER BY anio DESC LIMIT 1) AS pob,
    (SELECT anio FROM ${poblacion} ORDER BY anio LIMIT 1) AS anio_ini,
    (SELECT poblacion FROM ${poblacion} ORDER BY anio LIMIT 1) AS pob_ini,
    (SELECT poblacion FROM ${poblacion} WHERE anio = (SELECT max(anio) - 10 FROM ${poblacion})) AS pob_10
```

# 📈 Biztanleriaren bilakaera

Nola aldatu den Espainiako biztanle kopurua 1971tik eta hazkundearen zer zati dagokien jaiotzei eta heriotzei eta zer zati migrazioari.

<Grid cols=4>
    <KpiCard
        title="Biztanleria"
        value={resumen[0]?.pob}
        formattedValue="{formatNumber(resumen[0]?.pob / 1e6, 2)} milioi"
        period="{urteko(resumen[0]?.anio_pob)} urtarrilaren 1ean · {formatNumber(resumen[0]?.pob_ini / 1e6, 1)} milioi {urtean(resumen[0]?.anio_ini)}"
        change={100 * (resumen[0]?.pob / resumen[0]?.pob_10 - 1)}
        changeUnit="%"
        changePeriod="10 urtean"
        source="INE"
        sparklineData={poblacion.map(d => ({anio: d.anio, valor: d.millones}))}
    />
    <KpiCard
        title="Urteko hazkundea"
        value={anual.slice(-1)[0]?.crecimiento_1000}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.crecimiento_1000, 1)} 1.000 biz."
        period="{formatNumber(anual.slice(-1)[0]?.crecimiento, 0)} pertsona gehiago {urtean(anual.slice(-1)[0]?.anio)}"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.crecimiento_1000}))}
    />
    <KpiCard
        title="Jaiotzak ken heriotzak"
        value={anual.slice(-1)[0]?.vegetativo_1000}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.vegetativo_1000, 1)} 1.000 biz."
        period="{formatNumber(anual.slice(-1)[0]?.crecimiento_vegetativo, 0)} pertsona {urtean(anual.slice(-1)[0]?.anio)}"
        source="INE"
        href="/eu/demografia/natalidad"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.vegetativo_1000}))}
    />
    <KpiCard
        title="Migrazioa eta doikuntzak"
        value={anual.slice(-1)[0]?.resto_1000}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.resto_1000, 1)} 1.000 biz."
        period="{formatNumber(anual.slice(-1)[0]?.resto, 0)} pertsona {urtean(anual.slice(-1)[0]?.anio)}"
        source="INE"
        href="/eu/sociedad/inmigracion"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.resto_1000}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('crecimiento_poblacion')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'crecimiento_poblacion')} />


## Biztanleria 1971tik

<LineChart
    data={poblacion}
    x=anio
    y=millones
    yFmt=num1
    xFmt="####"
    lineColor="#1d4ed8"
    yAxisTitle="milioi biztanle"
    title="Espainiako biztanleria egoiliarra urtarrilaren 1ean (milioiak)"
/>

<p class="text-xs text-gray-500">INEren Biztanleriaren Estatistika Jarraitua, seriea 1971tik irizpide homogeneoekin berreraikitzen duena. {resumen[0]?.anio_ini} eta {resumen[0]?.anio_pob} artean, biztanleria {formatNumber(resumen[0]?.pob_ini / 1e6, 1)} milioitik {formatNumber(resumen[0]?.pob / 1e6, 1)} milioira igaro da.</p>

## Jaiotzak, heriotzak eta migrazioa

```sql componentes
SELECT anio, 'Nacimientos menos defunciones' AS componente, vegetativo_1000 AS por_1000 FROM ${anual}
UNION ALL
SELECT anio, 'Migración y ajustes', resto_1000 FROM ${anual}
ORDER BY anio
```

```sql anios_baja
SELECT count(*) AS n, string_agg(CAST(anio AS VARCHAR), ', ' ORDER BY anio) AS lista,
    count(*) FILTER (WHERE resto_1000 < 0) AS con_migracion_negativa
FROM ${anual}
WHERE crecimiento_1000 < 0
```

```sql decadas
SELECT
    CASE WHEN anio < 1985 THEN '1975-1984' WHEN anio < 1995 THEN '1985-1994' WHEN anio < 2005 THEN '1995-2004'
         WHEN anio < 2015 THEN '2005-2014' ELSE '2015-' || max(anio) OVER () END AS periodo,
    vegetativo_1000, resto_1000, crecimiento_1000
FROM ${anual}
```

```sql decadas_media
SELECT periodo, avg(vegetativo_1000) AS vegetativo, avg(resto_1000) AS migracion, avg(crecimiento_1000) AS total
FROM ${decadas}
GROUP BY 1
ORDER BY 1
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
    title="Urteko hazkundea 1.000 biztanleko eta haren osagaiak"
/>

<DataTable data={decadas_media} rows=all>
    <Column id=periodo title="Aldia" />
    <Column id=total title="Urteko batez besteko hazkundea 1.000 biz." fmt=num1 />
    <Column id=vegetativo title="…jaiotzak ken heriotzengatik" fmt=num1 contentType=delta />
    <Column id=migracion title="…migrazioagatik eta doikuntzengatik" fmt=num1 contentType=delta />
</DataTable>

<p class="text-xs text-gray-500">"Migrazioa eta doikuntzak" = hazkunde osoa ken hazkunde begetatiboa. 2021etik, Migrazioen Estatistikak zuzenean neurtzen duen atzerriarekiko migrazio-saldoarekin alderatu daiteke: {urtean(anual.slice(-1)[0]?.anio)}, {formatNumber(anual.slice(-1)[0]?.resto_1000, 1)} eta {formatNumber(anual.slice(-1)[0]?.saldo_exterior_1000, 1)}, hurrenez hurren, 1.000 biztanleko. {#if anios_baja[0]?.n > 0}1975etik, biztanleria {anios_baja[0]?.n} urtetan baino ez zen jaitsi ({anios_baja[0]?.lista}){#if anios_baja[0]?.con_migracion_negativa === anios_baja[0]?.n}, eta urte horietan guztietan migrazio-osagaia negatiboa izan zen{/if}.{/if}</p>

## Autonomia-erkidegoka

```sql ccaa
SELECT a.cod, t.nombre AS comunidad, '/eu' || t.ruta AS ruta,
    a.crecimiento_1000, a.vegetativo_1000, a.resto_1000, a.saldo_exterior_1000,
    e.poblacion, 100.0 * (e.poblacion / e10.poblacion - 1) AS crec_10
FROM mother.demografia_anual a
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = a.cod
JOIN mother.demografia_envejecimiento e ON e.nivel = 'ccaa' AND e.cod = a.cod AND e.anio = a.anio + 1
JOIN mother.demografia_envejecimiento e10 ON e10.nivel = 'ccaa' AND e10.cod = a.cod AND e10.anio = a.anio - 9
WHERE a.nivel = 'ccaa' AND a.anio = (SELECT max(anio) FROM mother.demografia_anual WHERE crecimiento_1000 IS NOT NULL)
ORDER BY a.crecimiento_1000 DESC
```

{urtean(anual.slice(-1)[0]?.anio)}, beren biztanleriaren proportzioan gehien hazi ziren erkidegoak hauek izan ziren: {ccaa[0]?.comunidad} ({formatNumber(ccaa[0]?.crecimiento_1000, 1)} 1.000 biz.) eta {ccaa[1]?.comunidad} ({formatNumber(ccaa[1]?.crecimiento_1000, 1)}); gutxien hazi zena, {ccaa.slice(-1)[0]?.comunidad} ({formatNumber(ccaa.slice(-1)[0]?.crecimiento_1000, 1)}).

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=crecimiento_1000 title="Hazkundea 1.000 biz." fmt=num1 contentType=bar barColor="#bfdbfe" />
    <Column id=vegetativo_1000 title="…jaiotzak ken heriotzak" fmt=num1 contentType=delta />
    <Column id=resto_1000 title="…migrazioa eta doikuntzak" fmt=num1 />
    <Column id=saldo_exterior_1000 title="Atzerriarekiko saldoa" fmt=num1 />
    <Column id=crec_10 title="Hazkundea 10 urtean (%)" fmt=num1 />
    <Column id=poblacion title="Biztanleria" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Erkidego batean, "migrazioa eta doikuntzak" kontzeptuak beste erkidego batzuetatik eta beste erkidego batzuetara egindako bizileku-aldaketak ere barne hartzen ditu; horregatik ez dator bat atzerriarekiko saldoarekin. Biztanleria {urteko(anual.slice(-1)[0]?.anio + 1)} urtarrilaren 1ean.</p>

## Probintziaka

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/eu' || t.ruta AS ruta, e.poblacion,
    100.0 * (e.poblacion / e10.poblacion - 1) AS crec_10,
    100.0 * (e.poblacion / e00.poblacion - 1) AS crec_2000
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
JOIN mother.demografia_envejecimiento e10 ON e10.nivel = 'provincia' AND e10.cod = e.cod AND e10.anio = e.anio - 10
JOIN mother.demografia_envejecimiento e00 ON e00.nivel = 'provincia' AND e00.cod = e.cod AND e00.anio = 2000
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY crec_10 DESC
```

```sql provincias_resumen
SELECT count(*) FILTER (WHERE crec_10 < 0) AS pierden_10, count(*) FILTER (WHERE crec_2000 < 0) AS pierden_2000
FROM ${provincias}
```

{provincias_resumen[0]?.pierden_10} probintziak biztanle gutxiago dituzte gaur duela hamar urte baino, eta {provincias_resumen[0]?.pierden_2000} probintziak 2000n baino gutxiago.

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="crec_10"
    valueFmt="num1"
    link="ruta"
    colorPalette={['#b91c1c', '#f8fafc', '#1d4ed8']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
    title="Biztanleriaren aldaketa azken 10 urteetan (%)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'crec_10', title: 'Aldaketa 10 urtean (%)', fmt: 'num1'},
        {id: 'crec_2000', title: 'Aldaketa 2000tik (%)', fmt: 'num1'},
        {id: 'poblacion', title: 'Biztanleria', fmt: 'num0'}
    ]}
/>

---

## Iturriak eta oharrak

- **[INE – Biztanleriaren Estatistika Jarraitua](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (56945 taula): urtarrilaren 1eko biztanleria probintziaka 1971tik. Serie ofizial homogeneoa da; zertxobait desberdina izan daiteke [lurraldeen](/eu/territorios) fitxetan erabiltzen diren udal-erroldako zifrekiko.
- **[INE – Biztanleriaren Mugimendu Naturala](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177007)** (6524 eta 6561 taulak): jaiotzak eta heriotzak bizileku-probintziaren arabera.
- **[INE – Migrazioen eta Bizileku Aldaketen Estatistika](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177000)** (69758 eta 69762 taulak): atzerriarekiko saldoa 2021etik.
- Hazkundea 1.000 biz. = (hurrengo urteko urtarrilaren 1eko biztanleria − urtarrilaren 1eko biztanleria) / urteko batez besteko biztanleria × 1.000.

<LastRefreshed prefix="Datuak eguneratuta" />
