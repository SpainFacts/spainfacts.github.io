---
title: Pensions
description: "Pensions contributives a Espanya: pensió mitjana descomptada la inflació, afiliats per pensió, despesa en pensions en % del PIB davant la UE, pensions per habitant i per comunitat i província."
i18n_origen: 3f8817a42d1f
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    // Els mesos arriben de SQL en castellà ('enero de 2025')
    const MESOS = {enero: 'gener', febrero: 'febrer', marzo: 'març', abril: 'abril', mayo: 'maig', junio: 'juny', julio: 'juliol', agosto: 'agost', septiembre: 'setembre', octubre: 'octubre', noviembre: 'novembre', diciembre: 'desembre'};
    const mesCa = (s) => s == null ? s : String(s).replace(/^[a-z]+/, (m) => MESOS[m] ?? m);
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
    '/ca' || t.ruta AS ruta,
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
    '/ca' || t.ruta AS ruta,
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

# 👵 Pensions

Quant cobren els pensionistes a Espanya, quants treballadors cotitzen per cada pensió i quant pesen les pensions en l'economia. Són les **pensions contributives de la Seguretat Social** (jubilació, incapacitat permanent, viduïtat, orfandat i a favor de familiars), sense les de classes passives de l'Estat ni les no contributives. Els imports són la pensió bruta de cadascuna de les 14 pagues i es mostren **descomptada la inflació**, en euros de {mensual[0]?.anio_euros}.

<Grid cols=4>
    <KpiCard
        title="Pensió mitjana de jubilació"
        value={mensual_real.slice(-1)[0]?.pension_media_jubilacion_real}
        formattedValue="{formatNumber(mensual_real.slice(-1)[0]?.pension_media_jubilacion_real, 0)} €/mes"
        period="{mesCa(mensual_real.slice(-1)[0]?.mes_texto)}, euros de {mensual[0]?.anio_euros} · {formatNumber(mensual_real.slice(-1)[0]?.pension_media_jubilacion, 0)} € corrents, 14 pagues"
        change={mensual_real.slice(-1)[0]?.interanual_jubilacion_real?.toFixed(1)}
        changeUnit="%"
        changePeriod="real vs. un any abans"
        direction="positive-up"
        source="Seguretat Social"
        sparklineData={mensual_real.map(d => d.pension_media_jubilacion_real)}
    />
    <KpiCard
        title="Afiliats per pensió"
        value={mensual_ratio.slice(-1)[0]?.afiliados_por_pension}
        formattedValue={formatNumber(mensual_ratio.slice(-1)[0]?.afiliados_por_pension, 2)}
        period="{mesCa(mensual_ratio.slice(-1)[0]?.mes_texto)} · {formatNumber(mensual_ratio.slice(-1)[0]?.afiliados / 1e6, 1)} milions d'afiliats i {formatNumber(mensual_ratio.slice(-1)[0]?.pensiones / 1e6, 1)} milions de pensions"
        direction="positive-up"
        source="Seguretat Social"
        sparklineData={mensual_ratio.map(d => d.afiliados_por_pension)}
    />
    <KpiCard
        title="Despesa en pensions"
        value={gasto_ult[0]?.es}
        formattedValue="{formatNumber(gasto_ult[0]?.es, 1)} % del PIB"
        period="{gasto_ult[0]?.anio} · vellesa i supervivència, totes les AP · mitjana UE-27: {formatNumber(gasto_ult[0]?.ue, 1)} %"
        direction="positive-down"
        source="Eurostat (COFOG)"
        sparklineData={gasto_es.map(d => d.gasto_vejez_supervivientes_pib)}
    />
    <KpiCard
        title="Pensions per 1.000 habitants"
        value={anual_completo.slice(-1)[0]?.pensiones_por_1000_hab}
        formattedValue={formatNumber(anual_completo.slice(-1)[0]?.pensiones_por_1000_hab, 0)}
        period="{anual_completo.slice(-1)[0]?.anio_i}, mitjana de l'any · {formatNumber(anual_completo.slice(-1)[0]?.pensiones_por_100_mayores, 0)} per cada 100 persones de 65 anys o més"
        source="Seguretat Social / INE"
        sparklineData={anual_completo.map(d => d.pensiones_por_1000_hab)}
    />
</Grid>

## La pensió mitjana, descomptada la inflació

Entre {mesCa(hitos[0]?.mes_ini)} i {mesCa(mensual_real.slice(-1)[0]?.mes_texto)} la pensió mitjana de jubilació va passar de {formatNumber(hitos[0]?.jub_nom_ini, 0)} € a {formatNumber(hitos[0]?.jub_nom_ult, 0)} € al mes, un {formatNumber(hitos[0]?.jub_nom_var, 0)} % més en euros de cada moment. Descomptada la inflació, la pujada és {#if hitos[0]?.jub_real_var >= 0}del {formatNumber(hitos[0]?.jub_real_var, 0)} %{:else}negativa: un {formatNumber(-hitos[0]?.jub_real_var, 0)} % menys{/if}.

<LineChart
    data={jubilacion_real_nominal}
    x=fecha
    y=pension
    series=serie
    yFmt='#,##0" €"'
    yAxisTitle="€ al mes (per paga)"
    startingAtZero={false}
    seriesColors={{'Descontada la inflación': '#0f766e', 'Sin descontar (euros de cada mes)': '#94a3b8'}}
    title="Pensió mitjana de jubilació: euros de {mensual[0]?.anio_euros} davant d'euros de cada mes"
/>

<LineChart
    data={pension_series}
    x=fecha
    y=pension
    series=clase
    yFmt='#,##0" €"'
    yAxisTitle="€ al mes, euros de {mensual[0]?.anio_euros}"
    colorPalette={['#0f766e', '#1d4ed8', '#f59e0b']}
    title="Pensió mitjana real per classe de pensió"
/>

Els salts de cada gener són la revalorització anual de les pensions; entre revaloritzacions, la inflació es va menjant poder adquisitiu mes a mes.

## Quants afiliats hi ha per cada pensió

És la xifra que més s'utilitza per parlar de la sostenibilitat del sistema: quantes persones cotitzen a la Seguretat Social (afiliats en alta, mitjana del mes) per cada pensió contributiva en vigor. Des de {mesCa(hitos[0]?.mes_ini)}, el màxim va ser de {formatNumber(hitos[0]?.ratio_max, 2)} ({mesCa(hitos[0]?.ratio_max_mes)}) i el mínim, de {formatNumber(hitos[0]?.ratio_min, 2)} ({mesCa(hitos[0]?.ratio_min_mes)}). El nombre de pensions ha crescut un {formatNumber(hitos[0]?.pensiones_var, 0)} % en aquest temps.

<LineChart
    data={mensual_ratio}
    x=fecha
    y=afiliados_por_pension
    yFmt='0.00'
    yAxisTitle="afiliats per pensió"
    startingAtZero={false}
    colorPalette={['#1d4ed8']}
    title="Afiliats a la Seguretat Social per cada pensió contributiva"
/>

<BarChart
    data={regimenes}
    x=anio
    y=pct_del_total
    series=regimen
    type=stacked
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% dels afiliats"
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b', '#64748b']}
    title="Afiliats per règim (% del total, mitjana anual)"
/>

## La pensió davant del salari

Pensió mitjana de jubilació i salari mitjà brut en euros de {mensual[0]?.anio_euros}. Per comparar-los, la pensió es prorrateja en 12 mesos (es cobren 14 pagues) igual que el salari de l'Enquesta Trimestral de Cost Laboral. El {sustitucion_ult[0]?.anio_i} la pensió mitjana de jubilació equivalia al {formatNumber(sustitucion_ult[0]?.tasa_sustitucion_aprox, 0)} % del salari mitjà. És una **taxa de substitució aproximada**: compara la pensió mitjana de tots els jubilats amb el salari mitjà d'aquell any, no la primera pensió de cada persona amb el seu últim sou.

<LineChart
    data={sustitucion}
    x=anio
    y=euros
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ bruts al mes (reals)"
    seriesColors={{'Pensión media de jubilación (14 pagas prorrateadas en 12)': '#0f766e', 'Salario medio bruto (pagas extra prorrateadas)': '#94a3b8'}}
    title="Pensió mitjana de jubilació i salari mitjà, descomptada la inflació"
/>

<LineChart
    data={anual_completo.filter(d => d.tasa_sustitucion_aprox != null)}
    x=anio_i
    y=tasa_sustitucion_aprox
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% del salari mitjà"
    startingAtZero={false}
    colorPalette={['#0f766e']}
    title="Pensió mitjana de jubilació en % del salari mitjà"
/>

## Quant gasta Espanya en pensions

Despesa de totes les administracions públiques en les funcions de vellesa i supervivència (viduïtat i orfandat) segons la classificació COFOG d'Eurostat, que inclou també les pensions de classes passives i les no contributives. El {gasto_ult[0]?.anio} va ser el {formatNumber(gasto_ult[0]?.es, 1)} % del PIB, davant del {formatNumber(gasto_ult[0]?.ue, 1)} % de la mitjana de la UE-27{#if gasto_ult[0]?.dif_2007 != null} i {formatNumber(Math.abs(gasto_ult[0]?.dif_2007), 1)} punts {#if gasto_ult[0]?.dif_2007 >= 0}més{:else}menys{/if} que el 2007{/if}. Espanya és el país número {gasto_ult[0]?.puesto} dels {gasto_ult[0]?.paises} de la UE amb dada per aquesta despesa en percentatge del PIB.

<LineChart
    data={gasto}
    x=anio
    y=gasto_vejez_supervivientes_pib
    series=pais
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% del PIB"
    startingAtZero={false}
    seriesColors={{'España': '#b91c1c', 'UE-27': '#94a3b8'}}
    title="Despesa pública en vellesa i supervivència, % del PIB: Espanya i UE-27"
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
    title="Despesa pública en vellesa i supervivència per país el {gasto_ult[0]?.anio} (% del PIB)"
/>

## Més pensions per a una població que envelleix

Nombre de pensions per cada 1.000 habitants i per cada 100 persones de 65 anys o més (padró de l'INE). Una persona pot cobrar més d'una pensió (per exemple, jubilació i viduïtat), de manera que aquestes xifres compten pensions, no pensionistes.

<LineChart
    data={por_habitante}
    x=anio
    y=valor
    series=indicador
    xFmt='0'
    yFmt='0'
    yAxisTitle="pensions"
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b']}
    title="Pensions per habitant i per persona gran"
/>

## Per comunitat autònoma

Dades del {ccaa_extremos[0]?.anio}{#if ccaa_extremos[0]?.meses < 12} (mitjana dels {ccaa_extremos[0]?.meses} mesos publicats){/if}, en euros de {mensual[0]?.anio_euros}. La pensió mitjana de jubilació més alta és la de {ccaa_extremos[0]?.max_nombre} ({formatNumber(ccaa_extremos[0]?.max_valor, 0)} €) i la més baixa, la de {ccaa_extremos[0]?.min_nombre} ({formatNumber(ccaa_extremos[0]?.min_valor, 0)} €). Pel que fa als afiliats per pensió, va de {formatNumber(ccaa_extremos[0]?.ratio_max_valor, 2)} a {ccaa_extremos[0]?.ratio_max_nombre} a {formatNumber(ccaa_extremos[0]?.ratio_min_valor, 2)} a {ccaa_extremos[0]?.ratio_min_nombre}.

<MapaEspana
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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: Seguretat Social"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pension_media_jubilacion_real', title: 'Pensió mitjana de jubilació', fmt: '#,##0" €"'},
        {id: 'pensiones_por_1000_hab', title: 'Pensions per 1.000 hab.', fmt: 'num0'},
        {id: 'afiliados_por_pension', title: 'Afiliats per pensió', fmt: 'num2'}
    ]}
/>

<DataTable data={ccaa} rows=all link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=pension_media_jubilacion_real title="Pensió mitjana de jubilació (€/mes)" fmt='#,##0' contentType=colorscale colorScale=positive />
    <Column id=pension_media_real title="Pensió mitjana, totes (€/mes)" fmt='#,##0' />
    <Column id=pensiones_por_1000_hab title="Pensions per 1.000 hab." fmt='#,##0' />
    <Column id=pensiones_por_100_mayores title="Pensions per 100 persones de 65+" fmt='#,##0' />
    <Column id=afiliados_por_pension title="Afiliats per pensió" fmt='0.00' contentType=colorscale colorScale=positive />
</DataTable>

### Per província

<MapaEspana
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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: Seguretat Social"
    title="Afiliats per pensió a cada província"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'afiliados_por_pension', title: 'Afiliats per pensió', fmt: 'num2'},
        {id: 'pension_media_jubilacion_real', title: 'Pensió mitjana de jubilació', fmt: '#,##0" €"'},
        {id: 'pensiones_por_1000_hab', title: 'Pensions per 1.000 hab.', fmt: 'num0'}
    ]}
/>

Més sobre la despesa de l'Estat per funcions a [Despeses](/ca/cuentas-publicas/gastos) i sobre els sous a [Salaris](/ca/economia/salarios).

---

**Fonts:** [Seguretat Social, estadístiques de pensions contributives en vigor](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/EST24) (llibres mensuals per comunitat i província, dia 1 de cada mes, i [el seu històric des del 2008](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/2575)); [Seguretat Social, afiliació mitjana mensual](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST8/EST10/EST290/EST291) (sèrie per règims des del 2001 i per província des del 2021); [Eurostat, despesa de les administracions públiques per funció, gov_10a_exp](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp/default/table) (COFOG GF1002 vellesa i GF1003 supervivents, % del PIB); [INE, padró municipal](https://www.ine.es/jaxiT3/Tabla.htm?t=29005) i [Enquesta Trimestral de Cost Laboral](https://www.ine.es/jaxiT3/Tabla.htm?t=6038). Imports deflactats amb l'IPC general de l'INE (base 2025).
