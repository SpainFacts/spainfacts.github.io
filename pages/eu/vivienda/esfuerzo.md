---
title: Erosteko edo alokatzeko ahalegina
description: "90 m²-ko etxebizitza batek zenbat urteko soldata gordin balio duen Espainian eta erkidego bakoitzean, eta soldataren zer zati joaten den alokairura, Etxebizitza Ministerioaren eta INEren datuekin."
i18n_origen: 5b404f87105a
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
</script>

```sql espana
SELECT anio, anios_salario, pct_alquiler, precio_90m2, salario_anual, alquiler_mes_mediana
FROM mother.vivienda_esfuerzo
WHERE nivel = 'pais'
ORDER BY anio
```

```sql compra
SELECT * FROM ${espana} WHERE anios_salario IS NOT NULL ORDER BY anio
```

```sql alquiler
SELECT * FROM ${espana} WHERE pct_alquiler IS NOT NULL ORDER BY anio
```

```sql hitos
SELECT
    max(anio) AS anio_ult,
    arg_max(anios_salario, anio) AS anios_ult,
    arg_max(precio_90m2, anio) AS precio_ult,
    arg_max(salario_anual, anio) AS salario_ult,
    max(anios_salario) AS anios_max,
    arg_max(anio, anios_salario) AS anio_max,
    min(anios_salario) AS anios_min,
    arg_min(anio, anios_salario) AS anio_min,
    100 * (arg_max(precio_90m2, anio) / arg_min(precio_90m2, anio) - 1) AS var_precio,
    100 * (arg_max(salario_anual, anio) / arg_min(salario_anual, anio) - 1) AS var_salario,
    min(anio) AS anio_ini
FROM ${compra}
```

```sql ccaa
SELECT e.cod, e.nombre AS comunidad, '/eu' || t.ruta AS ruta, e.anio, e.anios_salario, e.precio_90m2, e.salario_anual,
       a.anio AS anio_alquiler, a.pct_alquiler, a.alquiler_mes_mediana
FROM mother.vivienda_esfuerzo e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
LEFT JOIN mother.vivienda_esfuerzo a
  ON a.nivel = 'ccaa' AND a.cod = e.cod
 AND a.anio = (SELECT max(anio) FROM mother.vivienda_esfuerzo WHERE nivel = 'ccaa' AND pct_alquiler IS NOT NULL)
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.vivienda_esfuerzo WHERE nivel = 'ccaa' AND anios_salario IS NOT NULL)
ORDER BY e.anios_salario DESC
```

```sql ccaa_alquiler
SELECT e.cod, e.nombre AS comunidad, e.anio, e.pct_alquiler
FROM mother.vivienda_esfuerzo e
WHERE e.nivel = 'ccaa' AND e.pct_alquiler IS NOT NULL
  AND e.anio = (SELECT max(anio) FROM mother.vivienda_esfuerzo WHERE nivel = 'ccaa' AND pct_alquiler IS NOT NULL)
ORDER BY e.pct_alquiler DESC
```

```sql ccaa_serie
SELECT anio, nombre, anios_salario
FROM mother.vivienda_esfuerzo
WHERE anios_salario IS NOT NULL
  AND (nivel = 'pais' OR cod IN (SELECT cod FROM ${ccaa} ORDER BY anios_salario DESC LIMIT 3) OR cod IN (SELECT cod FROM ${ccaa} ORDER BY anios_salario LIMIT 1))
ORDER BY anio, nombre
```

# ⚖️ Erosteko edo alokatzeko ahalegina

Zenbat eragiten duen etxebizitzak soldatan. Erosteko: **zenbat urteko soldata gordin oso** behar den 90 m²-ko pisu bat ordaintzeko batez besteko tasazio-balioan, zergak, gastuak eta interesak kontatu gabe. Alokatzeko: **soldata gordinaren zer zati** joaten den pisu baten alokairu medianara. Urte bereko euroak alderatzen direnez, inflazioak ez du emaitza aldatzen.

<Grid cols=4>
    <KpiCard
        title="90 m²-rako soldata-urteak"
        value={hitos[0]?.anios_ult}
        formattedValue="{formatNumber(hitos[0]?.anios_ult, 1)} urte"
        period="Espainia, {hitos[0]?.anio_ult} · gehienekoa: {formatNumber(hitos[0]?.anios_max, 1)}, {urtean(hitos[0]?.anio_max)}"
        direction="positive-down"
        source="Etxebizitza Ministerioa / INE"
        sparklineData={compra.map(d => d.anios_salario)}
    />
    <KpiCard
        title="Alokairua soldataren gainean"
        value={alquiler.slice(-1)[0]?.pct_alquiler}
        formattedValue="{formatNumber(alquiler.slice(-1)[0]?.pct_alquiler, 1)} %"
        period="batez besteko soldata gordinarena, {alquiler.slice(-1)[0]?.anio} · {formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana, 0)} € hilean"
        direction="positive-down"
        source="Etxebizitza Ministerioa / INE"
        sparklineData={alquiler.map(d => d.pct_alquiler)}
    />
    <KpiCard
        title="Erostea garestien den lekua"
        value={ccaa[0]?.anios_salario}
        formattedValue="{formatNumber(ccaa[0]?.anios_salario, 1)} urte"
        period="{ccaa[0]?.comunidad}, {ccaa[0]?.anio} · merkeena: {ccaa.slice(-1)[0]?.comunidad}, {formatNumber(ccaa.slice(-1)[0]?.anios_salario, 1)}"
        direction="positive-down"
        source="Etxebizitza Ministerioa / INE"
        sparklineData={ccaa_serie.filter(d => d.nombre === ccaa[0]?.comunidad).map(d => d.anios_salario)}
    />
    <KpiCard
        title="Batez besteko soldata gordina"
        value={hitos[0]?.salario_ult}
        formattedValue="{formatNumber(hitos[0]?.salario_ult, 0)} € urtean"
        period="Espainia, {hitos[0]?.anio_ult} · 90 m²-ko pisu bat {formatNumber(hitos[0]?.precio_ult, 0)} €-tan tasatzen da"
        source="INE / ETCL"
        sparklineData={compra.map(d => d.salario_anual)}
    />
</Grid>

## Erostea: soldata-urteak

{hitos[0]?.anio_ini} eta {hitos[0]?.anio_ult} artean, 90 m²-ko pisu baten tasazio-balioa {formatNumber(hitos[0]?.var_precio, 1)} % aldatu zen, eta batez besteko soldata gordina {formatNumber(hitos[0]?.var_salario, 1)} %, biak urte bakoitzeko eurotan. Seriearen gutxienekoa {urtean(hitos[0]?.anio_min)} izan zen, {formatNumber(hitos[0]?.anios_min, 1)} soldata-urterekin.

<LineChart
    data={compra}
    x=anio
    y=anios_salario
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="soldata gordinaren urteak"
    startingAtZero={false}
    title="90 m²-ko etxebizitza bat ordaintzeko batez besteko soldata gordinaren urteak Espainian"
/>

<LineChart
    data={ccaa_serie}
    x=anio
    y=anios_salario
    series=nombre
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="soldata gordinaren urteak"
    title="Ahalegin handieneko hiru erkidegoak, txikienekoa eta Espainia"
/>

## Alokatzea: soldataren zatia

<LineChart
    data={alquiler}
    x=anio
    y=pct_alquiler
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="soldata gordinaren %"
    startingAtZero={false}
    title="Pisu baten alokairu mediana batez besteko soldata gordinaren gainean Espainian"
/>

## Erkidegoka

Erosketa: {urteko(ccaa[0]?.anio)} datuak; alokairua: {urteko(ccaa[0]?.anio_alquiler)} datuak, argitaratutako azken urtekoak. Soldata erkidego bakoitzekoa da; beraz, konparazioak kontuan hartzen du batzuetan besteetan baino gehiago kobratzen dela.

<BarChart
    data={ccaa}
    x=comunidad
    y=anios_salario
    swapXY=true
    yFmt='0.0'
    yAxisTitle="soldata gordinaren urteak"
    title="90 m² ordaintzeko soldata-urteak erkidegoka, {ccaa[0]?.anio}"
/>

<BarChart
    data={ccaa_alquiler}
    x=comunidad
    y=pct_alquiler
    swapXY=true
    yFmt='0.0"%"'
    yAxisTitle="soldata gordinaren %"
    title="Alokairu mediana soldataren gainean erkidegoka, {ccaa_alquiler[0]?.anio}"
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=anios_salario title="Soldata-urteak (90 m²)" fmt='0.0' />
    <Column id=precio_90m2 title="90 m²-ko pisua (€)" fmt='#,##0' />
    <Column id=salario_anual title="Urteko soldata gordina (€)" fmt='#,##0' />
    <Column id=pct_alquiler title="Alokairua / soldata %" fmt='0.0' />
    <Column id=alquiler_mes_mediana title="Alokairu mediana (€/hil.)" fmt='#,##0' />
</DataTable>

Ceuta eta Melilla ez dira agertzen, Lan Kostuaren Inkestak ez duelako haien soldata ematen.

---

**Kalkulua:** soldata-urteak = urteko etxebizitza librearen batez besteko tasazio-balioa (lau hiruhilekoen batez bestekoa, [Etxebizitza Ministerioa](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000)) × 90 m² ÷ (langileko eta hileko soldata-kostu osoa × 12, [INE, Lan Kostuaren Hiruhileko Inkesta, 6061 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=6061), industria, eraikuntza eta zerbitzuak). Alokairua soldataren gainean = pisu baten hileko alokairu mediana ([SERPAVI](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi)) × 12 ÷ urteko soldata bera. Langileko batez besteko soldata gordinak dira, ez etxeko diru-sarrerak.
