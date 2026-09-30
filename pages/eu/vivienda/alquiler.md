---
title: Etxebizitzaren alokairua
description: "Etxebizitzaren alokairu mediana Espainian inflazioa kenduta, erkidego, probintzia eta udalerriaren arabera, Alokairuaren Prezioaren Estatuko Erreferentzia Sistemaren PFEZ datuekin eta INEren indizearekin."
i18n_origen: deee5f4dedc1
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
SELECT anio, alquiler_mes_mediana, alquiler_mes_mediana_real, alquiler_m2_mediana, alquiler_m2_mediana_real,
       alquiler_mes_p25_real, alquiler_mes_p75_real, superficie_mediana, viviendas_alquiladas, alquiladas_1000, variacion_real, anio_base
FROM mother.vivienda_alquiler
WHERE nivel = 'pais' AND tipologia = 'Colectiva'
ORDER BY anio
```

```sql espana_largo
SELECT anio, 'Descontada la inflación' AS serie, alquiler_mes_mediana_real AS alquiler FROM ${espana}
UNION ALL
SELECT anio, 'Sin descontar (euros de cada año)' AS serie, alquiler_mes_mediana AS alquiler FROM ${espana}
ORDER BY anio, serie
```

```sql percentiles
SELECT anio, 'El 25 % más barato paga menos de' AS tramo, alquiler_mes_p25_real AS alquiler FROM ${espana}
UNION ALL
SELECT anio, 'Mediana' AS tramo, alquiler_mes_mediana_real AS alquiler FROM ${espana}
UNION ALL
SELECT anio, 'El 25 % más caro paga más de' AS tramo, alquiler_mes_p75_real AS alquiler FROM ${espana}
ORDER BY anio, tramo
```

```sql hitos
SELECT
    min(anio) AS anio_ini,
    max(anio) AS anio_fin,
    100 * (arg_max(alquiler_mes_mediana_real, anio) / arg_min(alquiler_mes_mediana_real, anio) - 1) AS var_real,
    100 * (arg_max(alquiler_mes_mediana, anio) / arg_min(alquiler_mes_mediana, anio) - 1) AS var_nominal,
    arg_max(alquiladas_1000, anio) / arg_min(alquiladas_1000, anio) AS veces_alquiladas,
    arg_min(alquiler_mes_mediana_real, alquiler_mes_mediana_real) AS min_real,
    arg_min(anio, alquiler_mes_mediana_real) AS anio_min
FROM ${espana}
```

```sql esfuerzo
SELECT anio, pct_alquiler FROM mother.vivienda_esfuerzo WHERE nivel = 'pais' AND pct_alquiler IS NOT NULL ORDER BY anio
```

```sql ipva
SELECT anio, indice_real, variacion_real, variacion_nominal FROM mother.vivienda_ipva WHERE nivel = 'pais' ORDER BY anio
```

```sql ccaa
SELECT a.cod, a.nombre AS comunidad, '/eu' || t.ruta AS ruta, a.anio, a.alquiler_mes_mediana_real, a.alquiler_m2_mediana_real,
       a.superficie_mediana, a.alquiladas_1000, r.alquiler_var_5a, e.pct_alquiler
FROM mother.vivienda_alquiler a
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = a.cod
LEFT JOIN mother.vivienda_resumen_territorios r ON r.nivel = 'ccaa' AND r.cod = a.cod
LEFT JOIN mother.vivienda_esfuerzo e ON e.nivel = 'ccaa' AND e.cod = a.cod AND e.anio = a.anio
WHERE a.nivel = 'ccaa' AND a.tipologia = 'Colectiva'
  AND a.anio = (SELECT max(anio) FROM mother.vivienda_alquiler)
ORDER BY a.alquiler_mes_mediana_real DESC
```

```sql provincias
SELECT a.cod AS cod_prov, a.nombre AS provincia, '/eu' || t.ruta AS ruta, a.alquiler_mes_mediana_real, a.alquiler_m2_mediana_real,
       a.alquiladas_1000, r.alquiler_var_5a
FROM mother.vivienda_alquiler a
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = a.cod
LEFT JOIN mother.vivienda_resumen_territorios r ON r.nivel = 'provincia' AND r.cod = a.cod
WHERE a.nivel = 'provincia' AND a.tipologia = 'Colectiva'
  AND a.anio = (SELECT max(anio) FROM mother.vivienda_alquiler)
ORDER BY a.alquiler_mes_mediana_real DESC
```

```sql municipios
SELECT m.municipio, p.nombre AS provincia, m.poblacion, m.alquiler_mes_mediana_real, m.alquiler_m2_mediana_real,
       m.superficie_mediana, m.alquiladas_1000, m.variacion_real_5a, m.anio
FROM mother.vivienda_alquiler_municipios m
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
WHERE m.anio = (SELECT max(anio) FROM mother.vivienda_alquiler_municipios)
ORDER BY m.alquiler_mes_mediana_real DESC
```

# 🔑 Alokairua

Zenbat ordaintzen den Espainian etxebizitza bat alokatzeagatik. Datuak **jabeen PFEZ aitorpenetatik** datoz (Etxebizitza Ministerioaren Alokairuaren Prezioaren Estatuko Erreferentzia Sistema): ohiko etxebizitzaren indarreko kontratuen errentak dira, ez iragarkietako prezioak, altuagoak izan ohi direnak. Zifrak pisuenak dira (etxebizitza kolektiboa) eta **inflazioa kenduta** daude, {urteko(espana[0]?.anio_base)} eurotan.

<Grid cols=4>
    <KpiCard
        title="Pisu baten alokairu mediana"
        value={espana.slice(-1)[0]?.alquiler_mes_mediana_real}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.alquiler_mes_mediana_real, 0)} €/hil."
        period="{espana.slice(-1)[0]?.anio} · {formatNumber(espana.slice(-1)[0]?.alquiler_mes_mediana, 0)} € urte horretako eurotan"
        change={espana.slice(-1)[0]?.variacion_real?.toFixed(1)}
        changePeriod="erreala, aurreko urtearekiko"
        source="Etxebizitza Ministerioa (SERPAVI)"
        sparklineData={espana.map(d => d.alquiler_mes_mediana_real)}
    />
    <KpiCard
        title="Metro koadroko"
        value={espana.slice(-1)[0]?.alquiler_m2_mediana_real}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.alquiler_m2_mediana_real, 2)} €/m² hilean"
        period="alokatutako pisuaren azalera mediana: {formatNumber(espana.slice(-1)[0]?.superficie_mediana, 0)} m²"
        source="Etxebizitza Ministerioa (SERPAVI)"
        sparklineData={espana.map(d => d.alquiler_m2_mediana_real)}
    />
    <KpiCard
        title="Alokatutako pisuak"
        value={espana.slice(-1)[0]?.alquiladas_1000}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.alquiladas_1000, 1)} 1.000 biz."
        period="PFEZean aitortuak {urtean(espana.slice(-1)[0]?.anio)} · {formatCompact(espana.slice(-1)[0]?.viviendas_alquiladas, 1)} guztira"
        source="Etxebizitza Ministerioa (SERPAVI)"
        sparklineData={espana.map(d => d.alquiladas_1000)}
    />
    <KpiCard
        title="Soldataren zatia"
        value={esfuerzo.slice(-1)[0]?.pct_alquiler}
        formattedValue="{formatNumber(esfuerzo.slice(-1)[0]?.pct_alquiler, 1)} %"
        period="batez besteko soldata gordinetik alokairu medianara joaten dena, {esfuerzo.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="Etxebizitza Ministerioa / INE"
        href="/eu/vivienda/esfuerzo"
        sparklineData={esfuerzo.map(d => d.pct_alquiler)}
    />
</Grid>

## Inflazioarekin eta inflaziorik gabe

{hitos[0]?.anio_ini} eta {hitos[0]?.anio_fin} artean, alokairu mediana {formatNumber(hitos[0]?.var_nominal, 0)} % igo zen urte bakoitzeko eurotan; inflazioa kenduta, {#if hitos[0]?.var_real < 0}{formatNumber(-hitos[0]?.var_real, 1)} % jaitsi zen{:else}{formatNumber(hitos[0]?.var_real, 1)} % igo zen{/if}. Gutxieneko erreala {urtean(hitos[0]?.anio_min)} izan zen. Urte horietan, alokairua PFEZean aitortzen den pisuen kopurua, biztanleko, {formatNumber(hitos[0]?.veces_alquiladas, 1)} aldiz biderkatu zen.

<LineChart
    data={espana_largo}
    x=anio
    y=alquiler
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ hilean"
    startingAtZero={false}
    title="Pisu baten hileko alokairu mediana Espainian"
/>

<LineChart
    data={percentiles}
    x=anio
    y=alquiler
    series=tramo
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ hilean (errealak)"
    title="Alokairuen banaketa: kuartilak, {urteko(espana[0]?.anio_base)} eurotan"
/>

Espainia ez da horrela agertzen Ministerioaren fitxategian: estatuko zifra erkidego bakoitzeko medianen batez bestekoa da, alokatutako pisu kopuruaren arabera haztatua.

INEk, gainera, kontratu berberen errentari urtez urte jarraitzen dion indize bat argitaratzen du (Euskadi eta Nafarroa gabe):

<LineChart
    data={ipva}
    x=anio
    y=indice_real
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="indize erreala, 2015 = 100"
    startingAtZero={false}
    title="Alokairuko Etxebizitzaren Prezioen Indizea, inflazioa kenduta (INE, 2015 = 100)"
/>

## Erkidegoka

Pisu baten alokairu mediana {urtean(ccaa[0]?.anio)}, {urteko(espana[0]?.anio_base)} eurotan.

<AreaMap
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="alquiler_mes_mediana_real"
    valueFmt='#,##0" €"'
    link="ruta"
    colorPalette={['#ede9fe', '#8b5cf6', '#4c1d95']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: Etxebizitza Ministerioa"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'alquiler_mes_mediana_real', title: '€/hil.', fmt: '#,##0'},
        {id: 'alquiler_m2_mediana_real', title: '€/m²', fmt: '0.00'},
        {id: 'pct_alquiler', title: 'Soldataren %', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=alquiler_mes_mediana_real title="€/hil. (erreala)" fmt='#,##0' />
    <Column id=alquiler_m2_mediana_real title="€/m² (erreala)" fmt='0.00' />
    <Column id=alquiler_var_5a title="Aldaketa erreala 5 urtean %" fmt='0.0' contentType=delta />
    <Column id=pct_alquiler title="Soldataren %" fmt='0.0' />
    <Column id=alquiladas_1000 title="Alokatutako pisuak 1.000 biz." fmt='0.0' />
</DataTable>

## Probintziaka

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="alquiler_mes_mediana_real"
    valueFmt='#,##0" €"'
    link="ruta"
    colorPalette={['#ede9fe', '#8b5cf6', '#4c1d95']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: Etxebizitza Ministerioa"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'alquiler_mes_mediana_real', title: '€/hil.', fmt: '#,##0'},
        {id: 'alquiler_var_5a', title: 'Aldaketa erreala 5 urtean (%)', fmt: '0.0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Probintzia" />
    <Column id=alquiler_mes_mediana_real title="€/hil. (erreala)" fmt='#,##0' />
    <Column id=alquiler_m2_mediana_real title="€/m² (erreala)" fmt='0.00' />
    <Column id=alquiler_var_5a title="Aldaketa erreala 5 urtean %" fmt='0.0' contentType=delta />
    <Column id=alquiladas_1000 title="Alokatutako pisuak 1.000 biz." fmt='0.0' />
</DataTable>

## Udalerrika

20.000 biztanleko edo gehiagoko udalerriak, gutxienez alokatutako 100 pisu aitortuta dituztenak, {municipios[0]?.anio}.

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=alquiler_mes_mediana_real title="€/hil. (erreala)" fmt='#,##0' />
    <Column id=alquiler_m2_mediana_real title="€/m² (erreala)" fmt='0.00' />
    <Column id=superficie_mediana title="m² medianak" fmt='0' />
    <Column id=variacion_real_5a title="Aldaketa erreala 5 urtean %" fmt='0.0' contentType=delta />
    <Column id=alquiladas_1000 title="Alokatuak 1.000 biz." fmt='0.0' />
</DataTable>

---

**Iturriak:** [Garraio eta Hiri Agendako Ministerioa, Etxebizitzaren Alokairuaren Prezioaren Estatuko Erreferentzia Sistema](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi) (PFEZaren 100 ereduen eta Katastroaren ustiapena, 2011-2024; Euskadi eta Nafarroa erkidego mailan soilik) eta [INE, Alokairuko Etxebizitzaren Prezioen Indizea, 59057 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=59057). INEren KPI orokorrarekin deflaktatuak (2025 oinarria).
