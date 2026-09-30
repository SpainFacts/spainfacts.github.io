---
title: Pensións
description: "Pensións contributivas en España: pensión media descontada a inflación, afiliados por pensión, gasto en pensións en % do PIB fronte á UE, pensións por habitante e por comunidade e provincia."
i18n_origen: cc5339743926
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    const mesesGl = {enero: 'xaneiro', febrero: 'febreiro', marzo: 'marzo', abril: 'abril', mayo: 'maio', junio: 'xuño', julio: 'xullo', agosto: 'agosto', septiembre: 'setembro', octubre: 'outubro', noviembre: 'novembro', diciembre: 'decembro'};
    const mesGl = (t) => (t == null ? t : String(t).replace(/^(\S+) de /, (m, mes) => (mesesGl[mes] ?? mes) + ' de '));
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
    '/gl' || t.ruta AS ruta,
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
    '/gl' || t.ruta AS ruta,
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

# 👵 Pensións

Canto cobran os pensionistas en España, cantos traballadores cotizan por cada pensión e canto pesan as pensións na economía. Son as **pensións contributivas da Seguridade Social** (xubilación, incapacidade permanente, viuvez, orfandade e favor de familiares), sen as de clases pasivas do Estado nin as non contributivas. Os importes son a pensión bruta de cada unha das 14 pagas e móstranse **descontada a inflación**, en euros de {mensual[0]?.anio_euros}.

<Grid cols=4>
    <KpiCard
        title="Pensión media de xubilación"
        value={mensual_real.slice(-1)[0]?.pension_media_jubilacion_real}
        formattedValue="{formatNumber(mensual_real.slice(-1)[0]?.pension_media_jubilacion_real, 0)} €/mes"
        period="{mesGl(mensual_real.slice(-1)[0]?.mes_texto)}, euros de {mensual[0]?.anio_euros} · {formatNumber(mensual_real.slice(-1)[0]?.pension_media_jubilacion, 0)} € correntes, 14 pagas"
        change={mensual_real.slice(-1)[0]?.interanual_jubilacion_real?.toFixed(1)}
        changeUnit="%"
        changePeriod="real fronte a un ano antes"
        direction="positive-up"
        source="Seguridade Social"
        sparklineData={mensual_real.map(d => d.pension_media_jubilacion_real)}
    />
    <KpiCard
        title="Afiliados por pensión"
        value={mensual_ratio.slice(-1)[0]?.afiliados_por_pension}
        formattedValue={formatNumber(mensual_ratio.slice(-1)[0]?.afiliados_por_pension, 2)}
        period="{mesGl(mensual_ratio.slice(-1)[0]?.mes_texto)} · {formatNumber(mensual_ratio.slice(-1)[0]?.afiliados / 1e6, 1)} millóns de afiliados e {formatNumber(mensual_ratio.slice(-1)[0]?.pensiones / 1e6, 1)} millóns de pensións"
        direction="positive-up"
        source="Seguridade Social"
        sparklineData={mensual_ratio.map(d => d.afiliados_por_pension)}
    />
    <KpiCard
        title="Gasto en pensións"
        value={gasto_ult[0]?.es}
        formattedValue="{formatNumber(gasto_ult[0]?.es, 1)} % do PIB"
        period="{gasto_ult[0]?.anio} · vellez e supervivencia, todas as AAPP · media UE-27: {formatNumber(gasto_ult[0]?.ue, 1)} %"
        direction="positive-down"
        source="Eurostat (COFOG)"
        sparklineData={gasto_es.map(d => d.gasto_vejez_supervivientes_pib)}
    />
    <KpiCard
        title="Pensións por 1.000 habitantes"
        value={anual_completo.slice(-1)[0]?.pensiones_por_1000_hab}
        formattedValue={formatNumber(anual_completo.slice(-1)[0]?.pensiones_por_1000_hab, 0)}
        period="{anual_completo.slice(-1)[0]?.anio_i}, media do ano · {formatNumber(anual_completo.slice(-1)[0]?.pensiones_por_100_mayores, 0)} por cada 100 persoas de 65 anos ou máis"
        source="Seguridade Social / INE"
        sparklineData={anual_completo.map(d => d.pensiones_por_1000_hab)}
    />
</Grid>

## A pensión media, descontada a inflación

Entre {mesGl(hitos[0]?.mes_ini)} e {mesGl(mensual_real.slice(-1)[0]?.mes_texto)} a pensión media de xubilación pasou de {formatNumber(hitos[0]?.jub_nom_ini, 0)} € a {formatNumber(hitos[0]?.jub_nom_ult, 0)} € ao mes, un {formatNumber(hitos[0]?.jub_nom_var, 0)} % máis en euros de cada momento. Descontada a inflación, a suba é {#if hitos[0]?.jub_real_var >= 0}do {formatNumber(hitos[0]?.jub_real_var, 0)} %{:else}negativa: un {formatNumber(-hitos[0]?.jub_real_var, 0)} % menos{/if}.

<LineChart
    data={jubilacion_real_nominal}
    x=fecha
    y=pension
    series=serie
    yFmt='#,##0" €"'
    yAxisTitle="€ ao mes (por paga)"
    startingAtZero={false}
    seriesColors={{'Descontada la inflación': '#0f766e', 'Sin descontar (euros de cada mes)': '#94a3b8'}}
    title="Pensión media de xubilación: euros de {mensual[0]?.anio_euros} fronte a euros de cada mes"
/>

<LineChart
    data={pension_series}
    x=fecha
    y=pension
    series=clase
    yFmt='#,##0" €"'
    yAxisTitle="€ ao mes, euros de {mensual[0]?.anio_euros}"
    colorPalette={['#0f766e', '#1d4ed8', '#f59e0b']}
    title="Pensión media real por clase de pensión"
/>

Os saltos de cada xaneiro son a revalorización anual das pensións; entre revalorizacións, a inflación vai comendo poder de compra mes a mes.

## Cantos afiliados hai por cada pensión

É a cifra que máis se usa para falar da sustentabilidade do sistema: cantas persoas cotizan á Seguridade Social (afiliados en alta, media do mes) por cada pensión contributiva en vigor. Desde {mesGl(hitos[0]?.mes_ini)}, o máximo foi de {formatNumber(hitos[0]?.ratio_max, 2)} en {mesGl(hitos[0]?.ratio_max_mes)} e o mínimo de {formatNumber(hitos[0]?.ratio_min, 2)} en {mesGl(hitos[0]?.ratio_min_mes)}. O número de pensións medrou un {formatNumber(hitos[0]?.pensiones_var, 0)} % nese tempo.

<LineChart
    data={mensual_ratio}
    x=fecha
    y=afiliados_por_pension
    yFmt='0.00'
    yAxisTitle="afiliados por pensión"
    startingAtZero={false}
    colorPalette={['#1d4ed8']}
    title="Afiliados á Seguridade Social por cada pensión contributiva"
/>

<BarChart
    data={regimenes}
    x=anio
    y=pct_del_total
    series=regimen
    type=stacked
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% dos afiliados"
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b', '#64748b']}
    title="Afiliados por réxime (% do total, media anual)"
/>

## A pensión fronte ao salario

Pensión media de xubilación e salario medio bruto en euros de {mensual[0]?.anio_euros}. Para comparalos, a pensión prorratéase en 12 meses (cóbranse 14 pagas) igual que o salario da Enquisa Trimestral de Custo Laboral. En {sustitucion_ult[0]?.anio_i} a pensión media de xubilación equivalía ao {formatNumber(sustitucion_ult[0]?.tasa_sustitucion_aprox, 0)} % do salario medio. É unha **taxa de substitución aproximada**: compara a pensión media de todos os xubilados co salario medio dese ano, non a primeira pensión de cada persoa co seu último soldo.

<LineChart
    data={sustitucion}
    x=anio
    y=euros
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ brutos ao mes (reais)"
    seriesColors={{'Pensión media de jubilación (14 pagas prorrateadas en 12)': '#0f766e', 'Salario medio bruto (pagas extra prorrateadas)': '#94a3b8'}}
    title="Pensión media de xubilación e salario medio, descontada a inflación"
/>

<LineChart
    data={anual_completo.filter(d => d.tasa_sustitucion_aprox != null)}
    x=anio_i
    y=tasa_sustitucion_aprox
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% do salario medio"
    startingAtZero={false}
    colorPalette={['#0f766e']}
    title="Pensión media de xubilación en % do salario medio"
/>

## Canto gasta España en pensións

Gasto de todas as administracións públicas nas funcións de vellez e supervivencia (viuvez e orfandade) segundo a clasificación COFOG de Eurostat, que inclúe tamén as pensións de clases pasivas e as non contributivas. En {gasto_ult[0]?.anio} foi o {formatNumber(gasto_ult[0]?.es, 1)} % do PIB, fronte ao {formatNumber(gasto_ult[0]?.ue, 1)} % da media da UE-27{#if gasto_ult[0]?.dif_2007 != null} e {formatNumber(Math.abs(gasto_ult[0]?.dif_2007), 1)} puntos {#if gasto_ult[0]?.dif_2007 >= 0}máis{:else}menos{/if} ca en 2007{/if}. España é o país número {gasto_ult[0]?.puesto} dos {gasto_ult[0]?.paises} da UE con dato por este gasto en porcentaxe do PIB.

<LineChart
    data={gasto}
    x=anio
    y=gasto_vejez_supervivientes_pib
    series=pais
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% do PIB"
    startingAtZero={false}
    seriesColors={{'España': '#b91c1c', 'UE-27': '#94a3b8'}}
    title="Gasto público en vellez e supervivencia, % do PIB: España e UE-27"
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
    title="Gasto público en vellez e supervivencia por país en {gasto_ult[0]?.anio} (% do PIB)"
/>

## Máis pensións para unha poboación que envellece

Número de pensións por cada 1.000 habitantes e por cada 100 persoas de 65 anos ou máis (padrón do INE). Unha persoa pode cobrar máis dunha pensión (por exemplo, xubilación e viuvez), así que estas cifras contan pensións, non pensionistas.

<LineChart
    data={por_habitante}
    x=anio
    y=valor
    series=indicador
    xFmt='0'
    yFmt='0'
    yAxisTitle="pensións"
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b']}
    title="Pensións por habitante e por persoa maior"
/>

## Por comunidade autónoma

Datos de {ccaa_extremos[0]?.anio}{#if ccaa_extremos[0]?.meses < 12} (media dos {ccaa_extremos[0]?.meses} meses publicados){/if}, en euros de {mensual[0]?.anio_euros}. A pensión media de xubilación máis alta é a de {ccaa_extremos[0]?.max_nombre} ({formatNumber(ccaa_extremos[0]?.max_valor, 0)} €) e a máis baixa a de {ccaa_extremos[0]?.min_nombre} ({formatNumber(ccaa_extremos[0]?.min_valor, 0)} €). Por afiliados por pensión, vai de {formatNumber(ccaa_extremos[0]?.ratio_max_valor, 2)} en {ccaa_extremos[0]?.ratio_max_nombre} a {formatNumber(ccaa_extremos[0]?.ratio_min_valor, 2)} en {ccaa_extremos[0]?.ratio_min_nombre}.

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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: Seguridade Social"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pension_media_jubilacion_real', title: 'Pensión media de xubilación', fmt: '#,##0" €"'},
        {id: 'pensiones_por_1000_hab', title: 'Pensións por 1.000 hab.', fmt: 'num0'},
        {id: 'afiliados_por_pension', title: 'Afiliados por pensión', fmt: 'num2'}
    ]}
/>

<DataTable data={ccaa} rows=all link=ruta>
    <Column id=comunidad title="Comunidade" />
    <Column id=pension_media_jubilacion_real title="Pensión media de xubilación (€/mes)" fmt='#,##0' contentType=colorscale colorScale=positive />
    <Column id=pension_media_real title="Pensión media, todas (€/mes)" fmt='#,##0' />
    <Column id=pensiones_por_1000_hab title="Pensións por 1.000 hab." fmt='#,##0' />
    <Column id=pensiones_por_100_mayores title="Pensións por 100 persoas de 65+" fmt='#,##0' />
    <Column id=afiliados_por_pension title="Afiliados por pensión" fmt='0.00' contentType=colorscale colorScale=positive />
</DataTable>

### Por provincia

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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: Seguridade Social"
    title="Afiliados por pensión en cada provincia"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'afiliados_por_pension', title: 'Afiliados por pensión', fmt: 'num2'},
        {id: 'pension_media_jubilacion_real', title: 'Pensión media de xubilación', fmt: '#,##0" €"'},
        {id: 'pensiones_por_1000_hab', title: 'Pensións por 1.000 hab.', fmt: 'num0'}
    ]}
/>

Máis sobre o gasto do Estado por funcións en [Gastos](/gl/cuentas-publicas/gastos) e sobre os soldos en [Salarios](/gl/economia/salarios).

---

**Fontes:** [Seguridade Social, estatísticas de pensións contributivas en vigor](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/EST24) (libros mensuais por comunidade e provincia, día 1 de cada mes, e [o seu histórico desde 2008](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/2575)); [Seguridade Social, afiliación media mensual](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST8/EST10/EST290/EST291) (serie por réximes desde 2001 e por provincia desde 2021); [Eurostat, gasto das administracións públicas por función, gov_10a_exp](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp/default/table) (COFOG GF1002 vellez e GF1003 superviventes, % do PIB); [INE, padrón municipal](https://www.ine.es/jaxiT3/Tabla.htm?t=29005) e [Enquisa Trimestral de Custo Laboral](https://www.ine.es/jaxiT3/Tabla.htm?t=6038). Importes deflactados co IPC xeral do INE (base 2025).
