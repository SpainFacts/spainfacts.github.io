---
title: Pentsioak
description: "Kotizaziopeko pentsioak Espainian: batez besteko pentsioa inflazioa kenduta, afiliatuak pentsioko, pentsioetako gastua BPGaren ehunekotan EBrekin alderatuta, pentsioak biztanleko eta erkidego eta probintziaka."
i18n_origen: cc5339743926
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
    // Hilabeteak (datuetan gaztelaniaz datoz): 'enero de 2024' -> '2024ko urtarrila' / 'urtarrilean' / 'urtarriletik'
    const HIL_EU = {
        enero: ['urtarrila', 'urtarrilean', 'urtarriletik'], febrero: ['otsaila', 'otsailean', 'otsailetik'],
        marzo: ['martxoa', 'martxoan', 'martxotik'], abril: ['apirila', 'apirilean', 'apiriletik'],
        mayo: ['maiatza', 'maiatzean', 'maiatzetik'], junio: ['ekaina', 'ekainean', 'ekainetik'],
        julio: ['uztaila', 'uztailean', 'uztailetik'], agosto: ['abuztua', 'abuztuan', 'abuztutik'],
        septiembre: ['iraila', 'irailean', 'irailetik'], octubre: ['urria', 'urrian', 'urritik'],
        noviembre: ['azaroa', 'azaroan', 'azarotik'], diciembre: ['abendua', 'abenduan', 'abendutik']
    };
    const hilabetea = (s, kasua = 0) => {
        const m = String(s ?? String()).match(/^([a-z]+) de (\d{4})$/);
        return m && HIL_EU[m[1]] ? `${urteko(m[2])} ${HIL_EU[m[1]][kasua]}` : (s ?? String());
    };
</script>

```sql mensual
SELECT
    fecha,
    CAST(anio AS INTEGER) AS anio,
    CAST(mes AS INTEGER) AS mes,
    pensiones,
    pensiones_jubilacion,
    pension_media,
    pension_media_jubilacion,
    pension_media_real,
    pension_media_jubilacion_real,
    pension_media_viudedad_real,
    afiliados,
    afiliados_por_pension,
    interanual_jubilacion_nominal,
    interanual_jubilacion_real,
    CAST(anio_euros AS INTEGER) AS anio_euros,
    CASE CAST(mes AS INTEGER) WHEN 1 THEN 'enero' WHEN 2 THEN 'febrero' WHEN 3 THEN 'marzo' WHEN 4 THEN 'abril'
        WHEN 5 THEN 'mayo' WHEN 6 THEN 'junio' WHEN 7 THEN 'julio' WHEN 8 THEN 'agosto' WHEN 9 THEN 'septiembre'
        WHEN 10 THEN 'octubre' WHEN 11 THEN 'noviembre' ELSE 'diciembre' END || ' de ' || CAST(anio AS INTEGER) AS mes_texto
FROM mother.pensiones_mensual
ORDER BY fecha
```

```sql mensual_real
SELECT * FROM ${mensual} WHERE pension_media_jubilacion_real IS NOT NULL ORDER BY fecha
```

```sql mensual_ratio
SELECT * FROM ${mensual} WHERE afiliados_por_pension IS NOT NULL ORDER BY fecha
```

```sql pension_series
SELECT fecha, 'Jubilación' AS clase, pension_media_jubilacion_real AS pension FROM ${mensual_real}
UNION ALL
SELECT fecha, 'Media de todas las pensiones', pension_media_real FROM ${mensual_real}
UNION ALL
SELECT fecha, 'Viudedad', pension_media_viudedad_real FROM ${mensual_real}
ORDER BY fecha, clase
```

```sql jubilacion_real_nominal
SELECT fecha, 'Descontada la inflación' AS serie, pension_media_jubilacion_real AS pension FROM ${mensual_real}
UNION ALL
SELECT fecha, 'Sin descontar (euros de cada mes)', pension_media_jubilacion FROM ${mensual_real}
ORDER BY fecha, serie
```

```sql hitos
SELECT
    (SELECT pension_media_jubilacion_real FROM ${mensual_real} ORDER BY fecha LIMIT 1) AS jub_real_ini,
    (SELECT mes_texto FROM ${mensual_real} ORDER BY fecha LIMIT 1) AS mes_ini,
    (SELECT pension_media_jubilacion_real FROM ${mensual_real} ORDER BY fecha DESC LIMIT 1) AS jub_real_ult,
    (SELECT pension_media_jubilacion FROM ${mensual_real} ORDER BY fecha LIMIT 1) AS jub_nom_ini,
    (SELECT pension_media_jubilacion FROM ${mensual_real} ORDER BY fecha DESC LIMIT 1) AS jub_nom_ult,
    100 * ((SELECT pension_media_jubilacion_real FROM ${mensual_real} ORDER BY fecha DESC LIMIT 1)
         / (SELECT pension_media_jubilacion_real FROM ${mensual_real} ORDER BY fecha LIMIT 1) - 1) AS jub_real_var,
    100 * ((SELECT pension_media_jubilacion FROM ${mensual_real} ORDER BY fecha DESC LIMIT 1)
         / (SELECT pension_media_jubilacion FROM ${mensual_real} ORDER BY fecha LIMIT 1) - 1) AS jub_nom_var,
    (SELECT max(afiliados_por_pension) FROM ${mensual_ratio}) AS ratio_max,
    (SELECT mes_texto FROM ${mensual_ratio} ORDER BY afiliados_por_pension DESC LIMIT 1) AS ratio_max_mes,
    (SELECT min(afiliados_por_pension) FROM ${mensual_ratio}) AS ratio_min,
    (SELECT mes_texto FROM ${mensual_ratio} ORDER BY afiliados_por_pension LIMIT 1) AS ratio_min_mes,
    100 * ((SELECT pensiones FROM ${mensual} ORDER BY fecha DESC LIMIT 1)
         / (SELECT pensiones FROM ${mensual} ORDER BY fecha LIMIT 1) - 1) AS pensiones_var
```

```sql anual
SELECT *, CAST(anio AS INTEGER) AS anio_i
FROM mother.pensiones_anual
ORDER BY anio
```

```sql anual_completo
SELECT * FROM ${anual} WHERE meses = 12 ORDER BY anio
```

```sql sustitucion
SELECT anio_i AS anio, 'Pensión media de jubilación (14 pagas prorrateadas en 12)' AS serie, pension_jubilacion_prorrateada_real AS euros FROM ${anual_completo} WHERE salario_real IS NOT NULL
UNION ALL
SELECT anio_i, 'Salario medio bruto (pagas extra prorrateadas)', salario_real FROM ${anual_completo} WHERE salario_real IS NOT NULL
ORDER BY anio, serie
```

```sql sustitucion_ult
SELECT * FROM ${anual_completo} WHERE tasa_sustitucion_aprox IS NOT NULL ORDER BY anio DESC LIMIT 1
```

```sql por_habitante
SELECT anio_i AS anio, 'Pensiones por 1.000 habitantes' AS indicador, pensiones_por_1000_hab AS valor FROM ${anual_completo}
UNION ALL
SELECT anio_i, 'Pensiones por 100 personas de 65 años o más', pensiones_por_100_mayores FROM ${anual_completo}
UNION ALL
SELECT anio_i, 'Pensiones de jubilación por 100 personas de 65 años o más', jubilaciones_por_100_mayores FROM ${anual_completo}
ORDER BY anio, indicador
```

```sql gasto
SELECT CAST(anio AS INTEGER) AS anio, pais, geo, gasto_vejez_pib, gasto_vejez_supervivientes_pib, gasto_pensiones_seepros_pib
FROM mother.pensiones_gasto_pib
WHERE geo IN ('ES', 'EU27_2020') AND gasto_vejez_supervivientes_pib IS NOT NULL
ORDER BY anio, geo
```

```sql gasto_es
SELECT * FROM ${gasto} WHERE geo = 'ES' ORDER BY anio
```

```sql gasto_ult
SELECT
    e.anio,
    e.gasto_vejez_supervivientes_pib AS es,
    u.gasto_vejez_supervivientes_pib AS ue,
    e.gasto_vejez_pib AS es_vejez,
    e.gasto_vejez_supervivientes_pib - p.gasto_vejez_supervivientes_pib AS dif_2007,
    (SELECT count(*) + 1 FROM mother.pensiones_gasto_pib g
        WHERE g.anio = e.anio AND g.es_miembro_ue AND g.gasto_vejez_supervivientes_pib > e.gasto_vejez_supervivientes_pib) AS puesto,
    (SELECT count(*) FROM mother.pensiones_gasto_pib g
        WHERE g.anio = e.anio AND g.es_miembro_ue AND g.gasto_vejez_supervivientes_pib IS NOT NULL) AS paises
FROM ${gasto_es} e
LEFT JOIN ${gasto} u ON u.anio = e.anio AND u.geo = 'EU27_2020'
LEFT JOIN ${gasto_es} p ON p.anio = 2007
ORDER BY e.anio DESC
LIMIT 1
```

```sql gasto_paises
SELECT
    pais,
    gasto_vejez_supervivientes_pib,
    CASE WHEN geo = 'ES' THEN 'España' WHEN es_ue THEN 'Media UE-27' ELSE 'Otros países de la UE' END AS grupo
FROM mother.pensiones_gasto_pib
WHERE anio = (SELECT max(anio) FROM ${gasto_es})
  AND gasto_vejez_supervivientes_pib IS NOT NULL
  AND (es_miembro_ue OR es_ue)
ORDER BY gasto_vejez_supervivientes_pib DESC
```

```sql regimenes
SELECT CAST(anio AS INTEGER) AS anio, regimen, pct_del_total
FROM mother.pensiones_afiliados_regimen
WHERE regimen <> 'Total' AND meses = 12
ORDER BY anio, regimen
```

```sql ccaa
SELECT
    p.cod,
    t.nombre AS comunidad,
    '/eu' || t.ruta AS ruta,
    CAST(p.anio AS INTEGER) AS anio,
    p.meses,
    p.pensiones,
    p.pension_media_jubilacion_real,
    p.pension_media_real,
    p.pensiones_por_1000_hab,
    p.pensiones_por_100_mayores,
    p.afiliados_por_pension
FROM mother.pensiones_territorio p
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = p.cod
WHERE p.nivel = 'ccaa' AND p.anio = (SELECT max(anio) FROM mother.pensiones_territorio)
ORDER BY p.pension_media_jubilacion_real DESC
```

```sql provincias
SELECT
    p.cod AS cod_prov,
    p.nombre AS provincia,
    '/eu' || t.ruta AS ruta,
    p.pension_media_jubilacion_real,
    p.pensiones_por_1000_hab,
    p.afiliados_por_pension
FROM mother.pensiones_territorio p
LEFT JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = p.cod
WHERE p.nivel = 'provincia' AND p.anio = (SELECT max(anio) FROM mother.pensiones_territorio)
ORDER BY p.cod
```

```sql ccaa_extremos
SELECT
    (SELECT comunidad FROM ${ccaa} ORDER BY pension_media_jubilacion_real DESC LIMIT 1) AS max_nombre,
    (SELECT pension_media_jubilacion_real FROM ${ccaa} ORDER BY pension_media_jubilacion_real DESC LIMIT 1) AS max_valor,
    (SELECT comunidad FROM ${ccaa} ORDER BY pension_media_jubilacion_real LIMIT 1) AS min_nombre,
    (SELECT pension_media_jubilacion_real FROM ${ccaa} ORDER BY pension_media_jubilacion_real LIMIT 1) AS min_valor,
    (SELECT comunidad FROM ${ccaa} ORDER BY afiliados_por_pension DESC LIMIT 1) AS ratio_max_nombre,
    (SELECT afiliados_por_pension FROM ${ccaa} ORDER BY afiliados_por_pension DESC LIMIT 1) AS ratio_max_valor,
    (SELECT comunidad FROM ${ccaa} ORDER BY afiliados_por_pension LIMIT 1) AS ratio_min_nombre,
    (SELECT afiliados_por_pension FROM ${ccaa} ORDER BY afiliados_por_pension LIMIT 1) AS ratio_min_valor,
    (SELECT max(meses) FROM ${ccaa}) AS meses,
    (SELECT max(anio) FROM ${ccaa}) AS anio
```

# 👵 Pentsioak

Zenbat kobratzen duten pentsiodunek Espainian, zenbat langilek kotizatzen duten pentsio bakoitzeko eta zenbateko pisua duten pentsioek ekonomian. **Gizarte Segurantzaren kotizaziopeko pentsioak** dira (erretiroa, ezintasun iraunkorra, alarguntasuna, zurztasuna eta senideen aldekoak), Estatuaren klase pasiboenak eta kotizazio gabekoak kanpo. Zenbatekoak 14 ordainsarietako bakoitzaren pentsio gordina dira, eta **inflazioa kenduta** erakusten dira, {urteko(mensual[0]?.anio_euros)} eurotan.

<Grid cols=4>
    <KpiCard
        title="Erretiroko batez besteko pentsioa"
        value={mensual_real.slice(-1)[0]?.pension_media_jubilacion_real}
        formattedValue="{formatNumber(mensual_real.slice(-1)[0]?.pension_media_jubilacion_real, 0)} €/hil."
        period="{hilabetea(mensual_real.slice(-1)[0]?.mes_texto)}, {urteko(mensual[0]?.anio_euros)} euroak · {formatNumber(mensual_real.slice(-1)[0]?.pension_media_jubilacion, 0)} € korronte, 14 ordainsari"
        change={mensual_real.slice(-1)[0]?.interanual_jubilacion_real?.toFixed(1)}
        changeUnit="%"
        changePeriod="erreala, urtebete lehenagorekiko"
        direction="positive-up"
        source="Gizarte Segurantza"
        sparklineData={mensual_real.map(d => d.pension_media_jubilacion_real)}
    />
    <KpiCard
        title="Afiliatuak pentsioko"
        value={mensual_ratio.slice(-1)[0]?.afiliados_por_pension}
        formattedValue={formatNumber(mensual_ratio.slice(-1)[0]?.afiliados_por_pension, 2)}
        period="{hilabetea(mensual_ratio.slice(-1)[0]?.mes_texto)} · {formatNumber(mensual_ratio.slice(-1)[0]?.afiliados / 1e6, 1)} milioi afiliatu eta {formatNumber(mensual_ratio.slice(-1)[0]?.pensiones / 1e6, 1)} milioi pentsio"
        direction="positive-up"
        source="Gizarte Segurantza"
        sparklineData={mensual_ratio.map(d => d.afiliados_por_pension)}
    />
    <KpiCard
        title="Pentsioetako gastua"
        value={gasto_ult[0]?.es}
        formattedValue="BPGaren {formatNumber(gasto_ult[0]?.es, 1)} %"
        period="{gasto_ult[0]?.anio} · zahartzaroa eta biziraupena, administrazio publiko guztiak · EB-27ko batez bestekoa: {formatNumber(gasto_ult[0]?.ue, 1)} %"
        direction="positive-down"
        source="Eurostat (COFOG)"
        sparklineData={gasto_es.map(d => d.gasto_vejez_supervivientes_pib)}
    />
    <KpiCard
        title="Pentsioak 1.000 biztanleko"
        value={anual_completo.slice(-1)[0]?.pensiones_por_1000_hab}
        formattedValue={formatNumber(anual_completo.slice(-1)[0]?.pensiones_por_1000_hab, 0)}
        period="{anual_completo.slice(-1)[0]?.anio_i}, urteko batez bestekoa · {formatNumber(anual_completo.slice(-1)[0]?.pensiones_por_100_mayores, 0)} 65 urteko edo gehiagoko 100 pertsonako"
        source="Gizarte Segurantza / INE"
        sparklineData={anual_completo.map(d => d.pensiones_por_1000_hab)}
    />
</Grid>

## Batez besteko pentsioa, inflazioa kenduta

{hilabetea(hitos[0]?.mes_ini)} eta {hilabetea(mensual_real.slice(-1)[0]?.mes_texto)} artean, erretiroko batez besteko pentsioa {formatNumber(hitos[0]?.jub_nom_ini, 0)} €-tik {formatNumber(hitos[0]?.jub_nom_ult, 0)} €-ra igaro zen hilean, {formatNumber(hitos[0]?.jub_nom_var, 0)} % gehiago une bakoitzeko eurotan. Inflazioa kenduta, igoera {#if hitos[0]?.jub_real_var >= 0}{formatNumber(hitos[0]?.jub_real_var, 0)} %-koa da{:else}negatiboa da: {formatNumber(-hitos[0]?.jub_real_var, 0)} % gutxiago{/if}.

<LineChart
    data={jubilacion_real_nominal}
    x=fecha
    y=pension
    series=serie
    yFmt='#,##0" €"'
    yAxisTitle="€ hilean (ordainsariko)"
    startingAtZero={false}
    seriesColors={{'Descontada la inflación': '#0f766e', 'Sin descontar (euros de cada mes)': '#94a3b8'}}
    title="Erretiroko batez besteko pentsioa: {urteko(mensual[0]?.anio_euros)} euroak hilabete bakoitzeko euroen aldean"
/>

<LineChart
    data={pension_series}
    x=fecha
    y=pension
    series=clase
    yFmt='#,##0" €"'
    yAxisTitle="€ hilean, {urteko(mensual[0]?.anio_euros)} euroak"
    colorPalette={['#0f766e', '#1d4ed8', '#f59e0b']}
    title="Batez besteko pentsio erreala, pentsio-motaren arabera"
/>

Urtarril bakoitzeko jauziak pentsioen urteko errebalorizazioa dira; errebalorizazioen artean, inflazioak erosteko ahalmena jaten du hilez hil.

## Zenbat afiliatu dauden pentsio bakoitzeko

Sistemaren iraunkortasunaz hitz egiteko gehien erabiltzen den zifra da: zenbat pertsonak kotizatzen duten Gizarte Segurantzan (altan dauden afiliatuak, hileko batez bestekoa) indarrean dagoen kotizaziopeko pentsio bakoitzeko. {hilabetea(hitos[0]?.mes_ini, 2)}, gehienekoa {formatNumber(hitos[0]?.ratio_max, 2)} izan zen, {hilabetea(hitos[0]?.ratio_max_mes, 1)}, eta gutxienekoa {formatNumber(hitos[0]?.ratio_min, 2)}, {hilabetea(hitos[0]?.ratio_min_mes, 1)}. Pentsio kopurua {formatNumber(hitos[0]?.pensiones_var, 0)} % hazi da denbora horretan.

<LineChart
    data={mensual_ratio}
    x=fecha
    y=afiliados_por_pension
    yFmt='0.00'
    yAxisTitle="afiliatuak pentsioko"
    startingAtZero={false}
    colorPalette={['#1d4ed8']}
    title="Gizarte Segurantzako afiliatuak kotizaziopeko pentsio bakoitzeko"
/>

<BarChart
    data={regimenes}
    x=anio
    y=pct_del_total
    series=regimen
    type=stacked
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="afiliatuen %"
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b', '#64748b']}
    title="Afiliatuak erregimenaren arabera (guztizkoaren %, urteko batez bestekoa)"
/>

## Pentsioa soldatarekin alderatuta

Erretiroko batez besteko pentsioa eta batez besteko soldata gordina, {urteko(mensual[0]?.anio_euros)} eurotan. Alderatzeko, pentsioa 12 hilabetetan hainbanatzen da (14 ordainsari kobratzen dira), Lan Kostuaren Hiruhileko Inkestako soldata bezala. {urtean(sustitucion_ult[0]?.anio_i)}, erretiroko batez besteko pentsioa batez besteko soldataren {formatNumber(sustitucion_ult[0]?.tasa_sustitucion_aprox, 0)} %-ren baliokidea zen. **Ordezte-tasa hurbildua** da: erretiratu guztien batez besteko pentsioa urte horretako batez besteko soldatarekin alderatzen du, ez pertsona bakoitzaren lehen pentsioa haren azken soldatarekin.

<LineChart
    data={sustitucion}
    x=anio
    y=euros
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ gordin hilean (errealak)"
    seriesColors={{'Pensión media de jubilación (14 pagas prorrateadas en 12)': '#0f766e', 'Salario medio bruto (pagas extra prorrateadas)': '#94a3b8'}}
    title="Erretiroko batez besteko pentsioa eta batez besteko soldata, inflazioa kenduta"
/>

<LineChart
    data={anual_completo.filter(d => d.tasa_sustitucion_aprox != null)}
    x=anio_i
    y=tasa_sustitucion_aprox
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="batez besteko soldataren %"
    startingAtZero={false}
    colorPalette={['#0f766e']}
    title="Erretiroko batez besteko pentsioa, batez besteko soldataren ehunekotan"
/>

## Zenbat gastatzen duen Espainiak pentsioetan

Administrazio publiko guztiek zahartzaro- eta biziraupen-funtzioetan (alarguntasuna eta zurztasuna) egiten duten gastua, Eurostaten COFOG sailkapenaren arabera; klase pasiboen pentsioak eta kotizazio gabekoak ere barne hartzen ditu. {urtean(gasto_ult[0]?.anio)}, BPGaren {formatNumber(gasto_ult[0]?.es, 1)} % izan zen, EB-27ko batez bestekoaren {formatNumber(gasto_ult[0]?.ue, 1)} %-ren aldean{#if gasto_ult[0]?.dif_2007 != null}, eta 2007an baino {formatNumber(Math.abs(gasto_ult[0]?.dif_2007), 1)} puntu {#if gasto_ult[0]?.dif_2007 >= 0}gehiago{:else}gutxiago{/if}{/if}. Datua duten EBko {gasto_ult[0]?.paises} herrialdeetatik, Espainia {gasto_ult[0]?.puesto}. postuan dago gastu honetan, BPGaren ehunekotan.

<LineChart
    data={gasto}
    x=anio
    y=gasto_vejez_supervivientes_pib
    series=pais
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="BPGaren %"
    startingAtZero={false}
    seriesColors={{'España': '#b91c1c', 'UE-27': '#94a3b8'}}
    title="Zahartzaro eta biziraupeneko gastu publikoa, BPGaren %: Espainia eta EB-27"
/>

<BarChart
    data={gasto_paises}
    x=pais
    y=gasto_vejez_supervivientes_pib
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    seriesColors={{'España': '#b91c1c', 'Media UE-27': '#1d4ed8', 'Otros países de la UE': '#94a3b8'}}
    title="Zahartzaro eta biziraupeneko gastu publikoa herrialdeka, {urtean(gasto_ult[0]?.anio)} (BPGaren %)"
/>

## Pentsio gehiago zahartzen ari den biztanleria batentzat

Pentsio kopurua 1.000 biztanleko eta 65 urteko edo gehiagoko 100 pertsonako (INEren errolda). Pertsona batek pentsio bat baino gehiago kobra ditzake (adibidez, erretiroa eta alarguntasuna); beraz, zifra hauek pentsioak zenbatzen dituzte, ez pentsiodunak.

<LineChart
    data={por_habitante}
    x=anio
    y=valor
    series=indicador
    xFmt='0'
    yFmt='0'
    yAxisTitle="pentsioak"
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b']}
    title="Pentsioak biztanleko eta adineko pertsonako"
/>

## Autonomia-erkidegoka

{urteko(ccaa_extremos[0]?.anio)} datuak{#if ccaa_extremos[0]?.meses < 12} (argitaratutako {ccaa_extremos[0]?.meses} hilabeteen batez bestekoa){/if}, {urteko(mensual[0]?.anio_euros)} eurotan. Erretiroko batez besteko pentsio altuena {ccaa_extremos[0]?.max_nombre} erkidegoan dago ({formatNumber(ccaa_extremos[0]?.max_valor, 0)} €), eta baxuena {ccaa_extremos[0]?.min_nombre} erkidegoan ({formatNumber(ccaa_extremos[0]?.min_valor, 0)} €). Pentsioko afiliatuei dagokienez, {formatNumber(ccaa_extremos[0]?.ratio_max_valor, 2)} ({ccaa_extremos[0]?.ratio_max_nombre}) eta {formatNumber(ccaa_extremos[0]?.ratio_min_valor, 2)} ({ccaa_extremos[0]?.ratio_min_nombre}) bitartean dago.

<AreaMap
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="pension_media_jubilacion_real"
    valueFmt='#,##0" €"'
    link="ruta"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: Gizarte Segurantza"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pension_media_jubilacion_real', title: 'Erretiroko batez besteko pentsioa', fmt: '#,##0" €"'},
        {id: 'pensiones_por_1000_hab', title: 'Pentsioak 1.000 biz.', fmt: 'num0'},
        {id: 'afiliados_por_pension', title: 'Afiliatuak pentsioko', fmt: 'num2'}
    ]}
/>

<DataTable data={ccaa} rows=all link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=pension_media_jubilacion_real title="Erretiroko batez besteko pentsioa (€/hil.)" fmt='#,##0' contentType=colorscale colorScale=positive />
    <Column id=pension_media_real title="Batez besteko pentsioa, guztiak (€/hil.)" fmt='#,##0' />
    <Column id=pensiones_por_1000_hab title="Pentsioak 1.000 biz." fmt='#,##0' />
    <Column id=pensiones_por_100_mayores title="Pentsioak 65+ urteko 100 pertsonako" fmt='#,##0' />
    <Column id=afiliados_por_pension title="Afiliatuak pentsioko" fmt='0.00' contentType=colorscale colorScale=positive />
</DataTable>

### Probintziaka

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="afiliados_por_pension"
    valueFmt='0.00'
    link="ruta"
    colorPalette={['#fef3c7', '#93c5fd', '#1d4ed8']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: Gizarte Segurantza"
    title="Afiliatuak pentsioko probintzia bakoitzean"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'afiliados_por_pension', title: 'Afiliatuak pentsioko', fmt: 'num2'},
        {id: 'pension_media_jubilacion_real', title: 'Erretiroko batez besteko pentsioa', fmt: '#,##0" €"'},
        {id: 'pensiones_por_1000_hab', title: 'Pentsioak 1.000 biz.', fmt: 'num0'}
    ]}
/>

Estatuaren gastuari buruz funtzioen arabera, ikus [Gastuak](/eu/cuentas-publicas/gastos); soldatei buruz, [Soldatak](/eu/economia/salarios).

---

**Iturriak:** [Gizarte Segurantza, indarrean dauden kotizaziopeko pentsioen estatistikak](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/EST24) (hileko liburuak erkidego eta probintziaka, hilabete bakoitzeko 1ean, eta [2008tik aurrerako historikoa](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/2575)); [Gizarte Segurantza, hileko batez besteko afiliazioa](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST8/EST10/EST290/EST291) (erregimenen araberako seriea 2001etik eta probintziakakoa 2021etik); [Eurostat, administrazio publikoen gastua funtzioaren arabera, gov_10a_exp](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp/default/table) (COFOG GF1002 zahartzaroa eta GF1003 bizirik daudenak, BPGaren %); [INE, udal-errolda](https://www.ine.es/jaxiT3/Tabla.htm?t=29005) eta [Lan Kostuaren Hiruhileko Inkesta](https://www.ine.es/jaxiT3/Tabla.htm?t=6038). Zenbatekoak INEren KPI orokorrarekin deflaktatuak (2025 oinarria).
