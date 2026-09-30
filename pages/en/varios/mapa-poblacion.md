---
title: Population map
description: "How the population of each Spanish province has changed since 1971: percentage growth between the year you choose and the latest municipal register figure."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 42c652677b2f
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql anios
SELECT DISTINCT CAST(Year AS INTEGER) AS anio
FROM mother.totalAnoProvincia
ORDER BY anio
```

```sql cambio
WITH datos AS (
    SELECT statecode, Provincias, CAST(Year AS INTEGER) AS anio, CAST("Población" AS DOUBLE) AS poblacion
    FROM mother.totalAnoProvincia
),
fin AS (SELECT max(anio) AS anio FROM datos)
SELECT
    i.statecode,
    i.Provincias AS provincia,
    i.poblacion AS poblacion_inicio,
    f.poblacion AS poblacion_fin,
    100 * (f.poblacion / i.poblacion - 1) AS cambio_pct,
    i.anio AS anio_inicio,
    f.anio AS anio_fin
FROM datos i
JOIN datos f ON f.statecode = i.statecode AND f.anio = (SELECT anio FROM fin)
WHERE i.anio = ${inputs.anio_inicio.value}
ORDER BY cambio_pct DESC
```

```sql resumen
SELECT
    count(*) FILTER (WHERE cambio_pct < 0) AS pierden,
    count(*) AS total,
    max(anio_inicio) AS anio_inicio,
    max(anio_fin) AS anio_fin
FROM ${cambio}
```

# 🗺️ Population map

Population growth in each province between the year you choose and the latest municipal register, in percentage terms. This makes it possible to compare provinces of very different sizes.

<Dropdown data={anios} name=anio_inicio value=anio title="From the year" defaultValue={1971}/>

<Grid cols=3>
    <KpiCard
        title="Provinces losing population"
        value={resumen[0]?.pierden}
        formattedValue="{resumen[0]?.pierden} of {resumen[0]?.total}"
        period="between {resumen[0]?.anio_inicio} and {resumen[0]?.anio_fin}"
        source="INE / Municipal Register"
        sparklineData={cambio.map(d => d.cambio_pct).sort((a, b) => a - b)}
    />
    <KpiCard
        title="Fastest growing"
        value={cambio[0]?.cambio_pct}
        formattedValue="+{formatNumber(cambio[0]?.cambio_pct, 1)}%"
        period="{cambio[0]?.provincia}: from {formatNumber(cambio[0]?.poblacion_inicio, 0)} to {formatNumber(cambio[0]?.poblacion_fin, 0)} inhabitants"
        source="INE / Municipal Register"
        sparklineData={cambio.map(d => d.cambio_pct).sort((a, b) => a - b)}
    />
    <KpiCard
        title="Steepest decline"
        value={cambio.slice(-1)[0]?.cambio_pct}
        formattedValue="{formatNumber(cambio.slice(-1)[0]?.cambio_pct, 1)}%"
        period="{cambio.slice(-1)[0]?.provincia}: from {formatNumber(cambio.slice(-1)[0]?.poblacion_inicio, 0)} to {formatNumber(cambio.slice(-1)[0]?.poblacion_fin, 0)} inhabitants"
        source="INE / Municipal Register"
        sparklineData={cambio.map(d => d.cambio_pct).sort((a, b) => a - b)}
    />
</Grid>

<AreaMap
    data={cambio}
    areaCol=statecode
    geoJsonUrl="/spain-provinces.geojson"
    geoId=cod_prov
    value=cambio_pct
    valueFmt='0.0"%"'
    colorPalette={['#b91c1c', '#f5f5f4', '#1d4ed8']}
    height=520
    tooltip={[
        {id: 'provincia', fmt: 'id', showColumnName: false, valueClass: 'text-xl font-semibold'},
        {id: 'cambio_pct', title: 'Change', fmt: '0.0"%"'},
        {id: 'poblacion_fin', title: 'Inhabitants today', fmt: '#,##0'}
    ]}
/>

<DataTable data={cambio} rows=52 search=true>
    <Column id=provincia title="Province"/>
    <Column id=cambio_pct title="Change (%)" fmt='0.0' contentType=delta/>
    <Column id=poblacion_inicio title="Inhabitants at start" fmt='#,##0'/>
    <Column id=poblacion_fin title="Inhabitants today" fmt='#,##0'/>
</DataTable>

---

**Source:** [INE, Municipal Register and population figures](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177011) (population on 1 January by province).
