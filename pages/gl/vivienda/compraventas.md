---
title: Compravendas e hipotecas
description: "Compravendas de vivendas e hipotecas sobre vivendas en España por 1.000 habitantes, vivenda nova fronte a segunda man e importe medio da hipoteca descontada a inflación, por comunidade e provincia."
i18n_origen: f88105740a74
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
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
SELECT r.cod, r.nombre AS comunidad, '/gl' || r.ruta AS ruta, r.compraventas_12m_1000, r.hipotecas_12m_1000, r.compraventas_12m,
       a.pct_nueva, a.importe_medio_real
FROM mother.vivienda_resumen_territorios r
LEFT JOIN mother.vivienda_mercado_anual a
  ON a.nivel = 'ccaa' AND a.cod = r.cod
 AND a.anio = (SELECT max(anio) FROM mother.vivienda_mercado_anual WHERE meses = 12)
WHERE r.nivel = 'ccaa'
ORDER BY r.compraventas_12m_1000 DESC
```

```sql provincias
SELECT r.cod AS cod_prov, r.nombre AS provincia, '/gl' || r.ruta AS ruta, r.compraventas_12m_1000, r.hipotecas_12m_1000, r.compraventas_12m,
       a.pct_nueva, a.importe_medio_real
FROM mother.vivienda_resumen_territorios r
LEFT JOIN mother.vivienda_mercado_anual a
  ON a.nivel = 'provincia' AND a.cod = r.cod
 AND a.anio = (SELECT max(anio) FROM mother.vivienda_mercado_anual WHERE meses = 12)
WHERE r.nivel = 'provincia'
ORDER BY r.compraventas_12m_1000 DESC
```

# 📝 Compravendas e hipotecas

Cantas vivendas cambian de mans cada ano e cantas se compran con hipoteca. Son compravendas **inscritas nos rexistros da propiedade** (adoitan chegar un ou dous meses despois da sinatura) e hipotecas constituídas sobre vivendas, sempre **por cada 1.000 habitantes**. O importe da hipoteca móstrase **descontada a inflación**, en euros de {anual[0]?.anio_base}.

<Grid cols=4>
    <KpiCard
        title="Compravendas de vivendas"
        value={ultimo[0]?.compraventas_12m_1000}
        formattedValue="{formatNumber(ultimo[0]?.compraventas_12m_1000, 1)} por 1.000 hab."
        period="12 meses ata {ultimo[0]?.mes_texto} · {formatCompact(ultimo[0]?.compraventas_12m, 0)} en total"
        change={ultimo[0]?.var_cv?.toFixed(1)}
        changePeriod="fronte a un ano antes"
        source="INE / ETDP"
        sparklineData={mensual.filter(d => d.compraventas_12m_1000 != null).map(d => d.compraventas_12m_1000)}
    />
    <KpiCard
        title="Hipotecas sobre vivendas"
        value={ultimo[0]?.hipotecas_12m_1000}
        formattedValue="{formatNumber(ultimo[0]?.hipotecas_12m_1000, 1)} por 1.000 hab."
        period="12 meses ata {ultimo[0]?.mes_texto} · {formatCompact(ultimo[0]?.hipotecas_12m, 0)} en total"
        change={ultimo[0]?.var_h?.toFixed(1)}
        changePeriod="fronte a un ano antes"
        source="INE / Hipotecas"
        sparklineData={mensual.filter(d => d.hipotecas_12m_1000 != null).map(d => d.hipotecas_12m_1000)}
    />
    <KpiCard
        title="Hipoteca media"
        value={importe_ult[0]?.importe_medio_real}
        formattedValue="{formatNumber(importe_ult[0]?.importe_medio_real / 1000, 0)} mil €"
        period="por vivenda en {importe_ult[0]?.anio}, en euros de {anual[0]?.anio_base}"
        source="INE / Hipotecas"
        sparklineData={anual.filter(d => d.importe_medio_real != null).map(d => d.importe_medio_real)}
    />
    <KpiCard
        title="Vivenda nova"
        value={hitos[0]?.pct_nueva_ult}
        formattedValue="{formatNumber(hitos[0]?.pct_nueva_ult, 1)} %"
        period="das compravendas en {hitos[0]?.anio_ult} · {formatNumber(hitos[0]?.pct_nueva_2008, 0)} % en 2008"
        source="INE / ETDP"
        sparklineData={anual_completo.map(d => d.pct_nueva)}
    />
</Grid>

## Evolución

Suma dos últimos 12 meses, por 1.000 habitantes. O ano con máis compravendas por habitante da serie (desde 2007) é {hitos[0]?.anio_max}, con {formatNumber(hitos[0]?.max_1000, 1)}; o mínimo, {hitos[0]?.anio_min}, con {formatNumber(hitos[0]?.min_1000, 1)}. En {hitos[0]?.anio_ult} foron {formatNumber(hitos[0]?.ult_1000, 1)}.

<LineChart
    data={movil_largo}
    x=fecha
    y=por_1000
    series=operacion
    yFmt='0.0'
    yAxisTitle="por 1.000 hab. (12 meses)"
    title="Compravendas e hipotecas de vivendas por 1.000 habitantes, suma móbil de 12 meses"
/>

## Nova ou de segunda man

<BarChart
    data={nueva_usada}
    x=anio
    y=por_1000
    series=tipo
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="por 1.000 habitantes"
    title="Compravendas de vivendas por 1.000 habitantes: nova e de segunda man"
/>

## Canto se pide prestado

Importe medio das hipotecas constituídas sobre vivendas, con e sen inflación. Hipotecas por cada 100 compravendas: {formatNumber(anual_completo.slice(-1)[0]?.pct_hipoteca, 0)} en {anual_completo.slice(-1)[0]?.anio}. Non son as mesmas operacións (tamén se hipotecan vivendas que non se acaban de comprar), pero dá unha idea de cantas compras se financian con préstamo.

<LineChart
    data={importe}
    x=anio
    y=importe
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ por hipoteca"
    startingAtZero={false}
    title="Importe medio da hipoteca sobre vivenda"
/>

<LineChart
    data={anual_completo}
    x=anio
    y=pct_hipoteca
    xFmt='0'
    yFmt='0'
    yAxisTitle="hipotecas por 100 compravendas"
    title="Hipotecas sobre vivendas por cada 100 compravendas"
/>

## Por comunidade

Compravendas dos últimos 12 meses por 1.000 habitantes.

<AreaMap
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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'compraventas_12m_1000', title: 'Compravendas por 1.000 hab.', fmt: 'num1'},
        {id: 'hipotecas_12m_1000', title: 'Hipotecas por 1.000 hab.', fmt: 'num1'},
        {id: 'pct_nueva', title: '% vivenda nova', fmt: 'num1'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidade" />
    <Column id=compraventas_12m_1000 title="Compravendas por 1.000 hab." fmt='0.0' />
    <Column id=hipotecas_12m_1000 title="Hipotecas por 1.000 hab." fmt='0.0' />
    <Column id=pct_nueva title="% nova" fmt='0.0' />
    <Column id=importe_medio_real title="Hipoteca media (€, real)" fmt='#,##0' />
    <Column id=compraventas_12m title="Compravendas (12 meses)" fmt='#,##0' />
</DataTable>

## Por provincia

<AreaMap
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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'compraventas_12m_1000', title: 'Compravendas por 1.000 hab.', fmt: 'num1'},
        {id: 'hipotecas_12m_1000', title: 'Hipotecas por 1.000 hab.', fmt: 'num1'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Provincia" />
    <Column id=compraventas_12m_1000 title="Compravendas por 1.000 hab." fmt='0.0' />
    <Column id=hipotecas_12m_1000 title="Hipotecas por 1.000 hab." fmt='0.0' />
    <Column id=pct_nueva title="% nova" fmt='0.0' />
    <Column id=importe_medio_real title="Hipoteca media (€, real)" fmt='#,##0' />
</DataTable>

---

**Fontes:** [INE, Estatística de Transmisións de Dereitos da Propiedade, táboa 6150](https://www.ine.es/jaxiT3/Tabla.htm?t=6150) (compravendas de vivendas inscritas, mensual desde 2007) e [INE, Estatística de Hipotecas, táboas 13896](https://www.ine.es/jaxiT3/Tabla.htm?t=13896) [e 3200](https://www.ine.es/jaxiT3/Tabla.htm?t=3200) (hipotecas constituídas sobre vivendas, desde 2003). Poboación: INE, a 1 de xaneiro. Importes deflactados co IPC xeral do INE (base 2025), mes a mes.
