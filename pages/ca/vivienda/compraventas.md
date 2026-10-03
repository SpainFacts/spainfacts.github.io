---
title: Compravendes i hipoteques
description: "Compravendes d'habitatges i hipoteques sobre habitatges a Espanya per 1.000 habitants, habitatge nou davant de segona mà i import mitjà de la hipoteca descomptada la inflació, per comunitat i província."
i18n_origen: ed62e0823b71
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
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
SELECT r.cod, r.nombre AS comunidad, '/ca' || r.ruta AS ruta, r.compraventas_12m_1000, r.hipotecas_12m_1000, r.compraventas_12m,
       a.pct_nueva, a.importe_medio_real
FROM mother.vivienda_resumen_territorios r
LEFT JOIN mother.vivienda_mercado_anual a
  ON a.nivel = 'ccaa' AND a.cod = r.cod
 AND a.anio = (SELECT max(anio) FROM mother.vivienda_mercado_anual WHERE meses = 12)
WHERE r.nivel = 'ccaa'
ORDER BY r.compraventas_12m_1000 DESC
```

```sql provincias
SELECT r.cod AS cod_prov, r.nombre AS provincia, '/ca' || r.ruta AS ruta, r.compraventas_12m_1000, r.hipotecas_12m_1000, r.compraventas_12m,
       a.pct_nueva, a.importe_medio_real
FROM mother.vivienda_resumen_territorios r
LEFT JOIN mother.vivienda_mercado_anual a
  ON a.nivel = 'provincia' AND a.cod = r.cod
 AND a.anio = (SELECT max(anio) FROM mother.vivienda_mercado_anual WHERE meses = 12)
WHERE r.nivel = 'provincia'
ORDER BY r.compraventas_12m_1000 DESC
```

# 📝 Compravendes i hipoteques

Quants habitatges canvien de mans cada any i quants es compren amb hipoteca. Són compravendes **inscrites als registres de la propietat** (solen arribar un o dos mesos després de la signatura) i hipoteques constituïdes sobre habitatges, sempre **per cada 1.000 habitants**. L'import de la hipoteca es mostra **descomptada la inflació**, en euros de {anual[0]?.anio_base}.

<Grid cols=4>
    <KpiCard
        title="Compravendes d'habitatges"
        value={ultimo[0]?.compraventas_12m_1000}
        formattedValue="{formatNumber(ultimo[0]?.compraventas_12m_1000, 1)} per 1.000 hab."
        period="12 mesos fins a {ultimo[0]?.mes_texto} · {formatCompact(ultimo[0]?.compraventas_12m, 0)} en total"
        change={ultimo[0]?.var_cv?.toFixed(1)}
        changePeriod="vs. un any abans"
        source="INE / ETDP"
        sparklineData={mensual.filter(d => d.compraventas_12m_1000 != null).map(d => d.compraventas_12m_1000)}
    />
    <KpiCard
        title="Hipoteques sobre habitatges"
        value={ultimo[0]?.hipotecas_12m_1000}
        formattedValue="{formatNumber(ultimo[0]?.hipotecas_12m_1000, 1)} per 1.000 hab."
        period="12 mesos fins a {ultimo[0]?.mes_texto} · {formatCompact(ultimo[0]?.hipotecas_12m, 0)} en total"
        change={ultimo[0]?.var_h?.toFixed(1)}
        changePeriod="vs. un any abans"
        source="INE / Hipoteques"
        sparklineData={mensual.filter(d => d.hipotecas_12m_1000 != null).map(d => d.hipotecas_12m_1000)}
    />
    <KpiCard
        title="Hipoteca mitjana"
        value={importe_ult[0]?.importe_medio_real}
        formattedValue="{formatNumber(importe_ult[0]?.importe_medio_real / 1000, 0)} mil €"
        period="per habitatge el {importe_ult[0]?.anio}, en euros de {anual[0]?.anio_base}"
        source="INE / Hipoteques"
        sparklineData={anual.filter(d => d.importe_medio_real != null).map(d => d.importe_medio_real)}
    />
    <KpiCard
        title="Habitatge nou"
        value={hitos[0]?.pct_nueva_ult}
        formattedValue="{formatNumber(hitos[0]?.pct_nueva_ult, 1)} %"
        period="de les compravendes el {hitos[0]?.anio_ult} · {formatNumber(hitos[0]?.pct_nueva_2008, 0)} % el 2008"
        source="INE / ETDP"
        sparklineData={anual_completo.map(d => d.pct_nueva)}
    />
</Grid>

## Evolució

Suma dels últims 12 mesos, per 1.000 habitants. L'any amb més compravendes per habitant de la sèrie (des del 2007) és el {hitos[0]?.anio_max}, amb {formatNumber(hitos[0]?.max_1000, 1)}; el mínim, el {hitos[0]?.anio_min}, amb {formatNumber(hitos[0]?.min_1000, 1)}. El {hitos[0]?.anio_ult} van ser {formatNumber(hitos[0]?.ult_1000, 1)}.

<LineChart
    data={movil_largo}
    x=fecha
    y=por_1000
    series=operacion
    yFmt='0.0'
    yAxisTitle="per 1.000 hab. (12 mesos)"
    title="Compravendes i hipoteques d'habitatges per 1.000 habitants, suma mòbil de 12 mesos"
/>

## Nou o de segona mà

<BarChart
    data={nueva_usada}
    x=anio
    y=por_1000
    series=tipo
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="per 1.000 habitants"
    title="Compravendes d'habitatges per 1.000 habitants: nou i de segona mà"
/>

## Quant es demana en préstec

Import mitjà de les hipoteques constituïdes sobre habitatges, amb inflació i sense. Hipoteques per cada 100 compravendes: {formatNumber(anual_completo.slice(-1)[0]?.pct_hipoteca, 0)} el {anual_completo.slice(-1)[0]?.anio}. No són les mateixes operacions (també s'hipotequen habitatges que no s'acaben de comprar), però dona una idea de quantes compres es financen amb préstec.

<LineChart
    data={importe}
    x=anio
    y=importe
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per hipoteca"
    startingAtZero={false}
    title="Import mitjà de la hipoteca sobre habitatge"
/>

<LineChart
    data={anual_completo}
    x=anio
    y=pct_hipoteca
    xFmt='0'
    yFmt='0'
    yAxisTitle="hipoteques per 100 compravendes"
    title="Hipoteques sobre habitatges per cada 100 compravendes"
/>

## Per comunitat

Compravendes dels últims 12 mesos per 1.000 habitants.

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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'compraventas_12m_1000', title: 'Compravendes per 1.000 hab.', fmt: 'num1'},
        {id: 'hipotecas_12m_1000', title: 'Hipoteques per 1.000 hab.', fmt: 'num1'},
        {id: 'pct_nueva', title: '% habitatge nou', fmt: 'num1'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=compraventas_12m_1000 title="Compravendes per 1.000 hab." fmt='0.0' />
    <Column id=hipotecas_12m_1000 title="Hipoteques per 1.000 hab." fmt='0.0' />
    <Column id=pct_nueva title="% nou" fmt='0.0' />
    <Column id=importe_medio_real title="Hipoteca mitjana (€, real)" fmt='#,##0' />
    <Column id=compraventas_12m title="Compravendes (12 mesos)" fmt='#,##0' />
</DataTable>

## Per província

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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'compraventas_12m_1000', title: 'Compravendes per 1.000 hab.', fmt: 'num1'},
        {id: 'hipotecas_12m_1000', title: 'Hipoteques per 1.000 hab.', fmt: 'num1'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Província" />
    <Column id=compraventas_12m_1000 title="Compravendes per 1.000 hab." fmt='0.0' />
    <Column id=hipotecas_12m_1000 title="Hipoteques per 1.000 hab." fmt='0.0' />
    <Column id=pct_nueva title="% nou" fmt='0.0' />
    <Column id=importe_medio_real title="Hipoteca mitjana (€, real)" fmt='#,##0' />
</DataTable>

---

**Fonts:** [INE, Estadística de Transmissions de Drets de la Propietat, taula 6150](https://www.ine.es/jaxiT3/Tabla.htm?t=6150) (compravendes d'habitatges inscrites, mensual des del 2007) i [INE, Estadística d'Hipoteques, taules 13896](https://www.ine.es/jaxiT3/Tabla.htm?t=13896) [i 3200](https://www.ine.es/jaxiT3/Tabla.htm?t=3200) (hipoteques constituïdes sobre habitatges, des del 2003). Població: INE, a 1 de gener. Imports deflactats amb l'IPC general de l'INE (base 2025), mes a mes.
