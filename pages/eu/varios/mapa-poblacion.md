---
title: Biztanleriaren mapa
description: "Nola aldatu den Espainiako probintzia bakoitzeko biztanleria 1971tik: hazkundea ehunekotan, zuk aukeratutako urtearen eta erroldako azken datuaren artean."
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

# 🗺️ Biztanleriaren mapa

Probintzia bakoitzeko biztanleriaren hazkundea, zuk aukeratutako urtearen eta azken erroldaren artean, ehunekotan. Horrela alderatu daitezke tamaina oso desberdineko probintziak.

<Dropdown data={anios} name=anio_inicio value=anio title="Urte honetatik" defaultValue={1971}/>

<Grid cols=3>
    <KpiCard
        title="Biztanleak galtzen dituzten probintziak"
        value={resumen[0]?.pierden}
        formattedValue="{resumen[0]?.pierden} / {resumen[0]?.total}"
        period="{resumen[0]?.anio_inicio} eta {resumen[0]?.anio_fin} artean"
        source="INE / Errolda"
        sparklineData={cambio.map(d => d.cambio_pct).sort((a, b) => a - b)}
    />
    <KpiCard
        title="Gehien hazten dena"
        value={cambio[0]?.cambio_pct}
        formattedValue="+{formatNumber(cambio[0]?.cambio_pct, 1)} %"
        period="{cambio[0]?.provincia}: {formatNumber(cambio[0]?.poblacion_inicio, 0)} biztanletik {formatNumber(cambio[0]?.poblacion_fin, 0)} biztanlera"
        source="INE / Errolda"
        sparklineData={cambio.map(d => d.cambio_pct).sort((a, b) => a - b)}
    />
    <KpiCard
        title="Gehien jaisten dena"
        value={cambio.slice(-1)[0]?.cambio_pct}
        formattedValue="{formatNumber(cambio.slice(-1)[0]?.cambio_pct, 1)} %"
        period="{cambio.slice(-1)[0]?.provincia}: {formatNumber(cambio.slice(-1)[0]?.poblacion_inicio, 0)} biztanletik {formatNumber(cambio.slice(-1)[0]?.poblacion_fin, 0)} biztanlera"
        source="INE / Errolda"
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
        {id: 'cambio_pct', title: 'Aldaketa', fmt: '0.0"%"'},
        {id: 'poblacion_fin', title: 'Biztanleak gaur', fmt: '#,##0'}
    ]}
/>

<DataTable data={cambio} rows=52 search=true>
    <Column id=provincia title="Probintzia"/>
    <Column id=cambio_pct title="Aldaketa (%)" fmt='0.0' contentType=delta/>
    <Column id=poblacion_inicio title="Biztanleak hasieran" fmt='#,##0'/>
    <Column id=poblacion_fin title="Biztanleak gaur" fmt='#,##0'/>
</DataTable>

---

**Iturria:** [INE, Udal Errolda eta biztanleria-zifrak](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177011) (urtarrilaren 1eko biztanleria, probintziaka).
