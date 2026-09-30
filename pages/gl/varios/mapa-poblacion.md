---
title: Mapa da poboación
description: "Como cambiou a poboación de cada provincia española desde 1971: crecemento en porcentaxe entre o ano que escollas e o último dato do padrón."
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

# 🗺️ Mapa da poboación

Crecemento da poboación de cada provincia entre o ano que escollas e o último padrón, en porcentaxe. Así compáranse provincias de tamaños moi distintos.

<Dropdown data={anios} name=anio_inicio value=anio title="Desde o ano" defaultValue={1971}/>

<Grid cols=3>
    <KpiCard
        title="Provincias que perden poboación"
        value={resumen[0]?.pierden}
        formattedValue="{resumen[0]?.pierden} de {resumen[0]?.total}"
        period="entre {resumen[0]?.anio_inicio} e {resumen[0]?.anio_fin}"
        source="INE / Padrón"
        sparklineData={cambio.map(d => d.cambio_pct).sort((a, b) => a - b)}
    />
    <KpiCard
        title="A que máis medra"
        value={cambio[0]?.cambio_pct}
        formattedValue="+{formatNumber(cambio[0]?.cambio_pct, 1)} %"
        period="{cambio[0]?.provincia}: de {formatNumber(cambio[0]?.poblacion_inicio, 0)} a {formatNumber(cambio[0]?.poblacion_fin, 0)} habitantes"
        source="INE / Padrón"
        sparklineData={cambio.map(d => d.cambio_pct).sort((a, b) => a - b)}
    />
    <KpiCard
        title="A que máis cae"
        value={cambio.slice(-1)[0]?.cambio_pct}
        formattedValue="{formatNumber(cambio.slice(-1)[0]?.cambio_pct, 1)} %"
        period="{cambio.slice(-1)[0]?.provincia}: de {formatNumber(cambio.slice(-1)[0]?.poblacion_inicio, 0)} a {formatNumber(cambio.slice(-1)[0]?.poblacion_fin, 0)} habitantes"
        source="INE / Padrón"
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
        {id: 'cambio_pct', title: 'Cambio', fmt: '0.0"%"'},
        {id: 'poblacion_fin', title: 'Habitantes hoxe', fmt: '#,##0'}
    ]}
/>

<DataTable data={cambio} rows=52 search=true>
    <Column id=provincia title="Provincia"/>
    <Column id=cambio_pct title="Cambio (%)" fmt='0.0' contentType=delta/>
    <Column id=poblacion_inicio title="Habitantes ao inicio" fmt='#,##0'/>
    <Column id=poblacion_fin title="Habitantes hoxe" fmt='#,##0'/>
</DataTable>

---

**Fonte:** [INE, Padrón Municipal e cifras de poboación](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177011) (poboación a 1 de xaneiro por provincia).
