---
title: Llars
description: "Mida mitjana de la llar i percentatge de llars d'una sola persona a Espanya, per comunitat i província, des del 2021 (INE, Estadística Contínua de Població)."
i18n_origen: 36e2d1ec8163
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT CAST(h.anio AS INTEGER) AS anio, h.hogares, h.tamano_medio, h.unipersonales, h.pct_unipersonales,
    h.pct_2, h.pct_3, h.pct_4_o_mas
FROM mother.demografia_hogares h
WHERE h.nivel = 'pais'
ORDER BY anio
```

# 🏠 Llars

Quantes persones viuen de mitjana a cada llar i quantes llars estan formades per una sola persona. Les dades són de l'Estadística Contínua de Població de l'INE, que les publica des del 2021.

<Grid cols=4>
    <KpiCard
        title="Persones per llar"
        value={espana.slice(-1)[0]?.tamano_medio}
        formattedValue={formatNumber(espana.slice(-1)[0]?.tamano_medio, 2)}
        period="mida mitjana, 1 de gener de {espana.slice(-1)[0]?.anio} · {formatNumber(espana[0]?.tamano_medio, 2)} el {espana[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.tamano_medio}))}
    />
    <KpiCard
        title="Llars d'una persona"
        value={espana.slice(-1)[0]?.pct_unipersonales}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_unipersonales, 1)} %"
        period="de les llars · {formatCompact(espana.slice(-1)[0]?.unipersonales, 2)} llars"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_unipersonales}))}
    />
    <KpiCard
        title="Llars de dues persones"
        value={espana.slice(-1)[0]?.pct_2}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_2, 1)} %"
        period="de les llars, {espana.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_2}))}
    />
    <KpiCard
        title="Llars de 4 persones o més"
        value={espana.slice(-1)[0]?.pct_4_o_mas}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_4_o_mas, 1)} %"
        period="de les llars · {formatCompact(espana.slice(-1)[0]?.hogares, 3)} llars en total"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_4_o_mas}))}
    />
</Grid>

<p class="text-xs text-gray-500">Llars de persones que resideixen en habitatges familiars (no inclou residències, casernes, convents i altres establiments col·lectius).</p>

## Llars segons el nombre de persones

```sql tamanos
SELECT anio, '1 persona' AS tamano, pct_unipersonales / 100 AS cuota FROM ${espana}
UNION ALL SELECT anio, '2 personas', pct_2 / 100 FROM ${espana}
UNION ALL SELECT anio, '3 personas', pct_3 / 100 FROM ${espana}
UNION ALL SELECT anio, '4 o más', pct_4_o_mas / 100 FROM ${espana}
ORDER BY anio
```

<BarChart
    data={tamanos}
    x=anio
    y=cuota
    series=tamano
    type=stacked
    yFmt=pct0
    xFmt="####"
    colorPalette={['#b45309', '#f59e0b', '#fcd34d', '#fef3c7']}
    title="Llars per nombre de persones (% del total, a 1 de gener)"
/>

## Per comunitat autònoma

```sql ccaa
SELECT h.cod, t.nombre AS comunidad, '/ca' || t.ruta AS ruta, h.tamano_medio, h.pct_unipersonales / 100 AS unipersonales,
    h.pct_4_o_mas / 100 AS cuatro_o_mas, h.hogares
FROM mother.demografia_hogares h
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = h.cod
WHERE h.nivel = 'ccaa' AND h.anio = (SELECT max(anio) FROM mother.demografia_hogares)
ORDER BY h.tamano_medio DESC
```

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=tamano_medio title="Persones per llar" fmt=num2 contentType=bar barColor="#fde68a" />
    <Column id=unipersonales title="Llars d'1 persona" fmt=pct1 />
    <Column id=cuatro_o_mas title="Llars de 4 o més" fmt=pct1 />
    <Column id=hogares title="Llars" fmt=num0 />
</DataTable>

## Per província

```sql provincias
SELECT h.cod AS cod_prov, t.nombre AS provincia, '/ca' || t.ruta AS ruta, h.tamano_medio, h.pct_unipersonales / 100 AS unipersonales
FROM mother.demografia_hogares h
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = h.cod
WHERE h.nivel = 'provincia' AND h.anio = (SELECT max(anio) FROM mother.demografia_hogares)
ORDER BY h.pct_unipersonales DESC
```

Les llars d'una sola persona van del {formatNumber(provincias[0]?.unipersonales / 0.01, 1)} % de {provincias[0]?.provincia} al {formatNumber(provincias.slice(-1)[0]?.unipersonales / 0.01, 1)} % de {provincias.slice(-1)[0]?.provincia}.

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="unipersonales"
    valueFmt="pct1"
    link="ruta"
    colorPalette={['#fffbeb', '#f59e0b', '#78350f']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
    title="Llars d'una sola persona (% de les llars)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'unipersonales', title: "Llars d'1 persona", fmt: 'pct1'},
        {id: 'tamano_medio', title: 'Persones per llar', fmt: 'num2'}
    ]}
/>

---

## Fonts i notes

- **[INE – Estadística Contínua de Població: llars](https://www.ine.es/jaxiT3/Tabla.htm?t=60133)**: llars per nombre de membres per comunitat ([60131](https://www.ine.es/jaxiT3/Tabla.htm?t=60131)) i província ([60133](https://www.ine.es/jaxiT3/Tabla.htm?t=60133)) i mida mitjana de la llar ([60132](https://www.ine.es/jaxiT3/Tabla.htm?t=60132) i [60134](https://www.ine.es/jaxiT3/Tabla.htm?t=60134)). Dades provisionals a 1 de gener; l'INE les publica cada trimestre des del 2021. L'antiga Enquesta Contínua de Llars (2013-2020) no s'inclou perquè el seu mètode és diferent.

<LastRefreshed prefix="Dades actualitzades" />
