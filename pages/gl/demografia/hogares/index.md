---
title: Fogares
description: "Tamaño medio do fogar e porcentaxe de fogares dunha soa persoa en España, por comunidade e provincia, desde 2021 (INE, Estatística Continua de Poboación)."
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

# 🏠 Fogares

Cantas persoas viven de media en cada fogar e cantos fogares están formados por unha soa persoa. Os datos son da Estatística Continua de Poboación do INE, que os publica desde 2021.

<Grid cols=4>
    <KpiCard
        title="Persoas por fogar"
        value={espana.slice(-1)[0]?.tamano_medio}
        formattedValue={formatNumber(espana.slice(-1)[0]?.tamano_medio, 2)}
        period="tamaño medio, 1 de xaneiro de {espana.slice(-1)[0]?.anio} · {formatNumber(espana[0]?.tamano_medio, 2)} en {espana[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.tamano_medio}))}
    />
    <KpiCard
        title="Fogares dunha persoa"
        value={espana.slice(-1)[0]?.pct_unipersonales}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_unipersonales, 1)} %"
        period="dos fogares · {formatCompact(espana.slice(-1)[0]?.unipersonales, 2)} fogares"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_unipersonales}))}
    />
    <KpiCard
        title="Fogares de dúas persoas"
        value={espana.slice(-1)[0]?.pct_2}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_2, 1)} %"
        period="dos fogares, {espana.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_2}))}
    />
    <KpiCard
        title="Fogares de 4 ou máis persoas"
        value={espana.slice(-1)[0]?.pct_4_o_mas}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.pct_4_o_mas, 1)} %"
        period="dos fogares · {formatCompact(espana.slice(-1)[0]?.hogares, 3)} fogares en total"
        source="INE"
        sparklineData={espana.map(d => ({anio: d.anio, valor: d.pct_4_o_mas}))}
    />
</Grid>

<p class="text-xs text-gray-500">Fogares de persoas que residen en vivendas familiares (non inclúe residencias, cuarteis, conventos e outros establecementos colectivos).</p>

## Fogares segundo o número de persoas

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
    title="Fogares por número de persoas (% do total, a 1 de xaneiro)"
/>

## Por comunidade autónoma

```sql ccaa
SELECT h.cod, t.nombre AS comunidad, '/gl' || t.ruta AS ruta, h.tamano_medio, h.pct_unipersonales / 100 AS unipersonales,
    h.pct_4_o_mas / 100 AS cuatro_o_mas, h.hogares
FROM mother.demografia_hogares h
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = h.cod
WHERE h.nivel = 'ccaa' AND h.anio = (SELECT max(anio) FROM mother.demografia_hogares)
ORDER BY h.tamano_medio DESC
```

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidade" />
    <Column id=tamano_medio title="Persoas por fogar" fmt=num2 contentType=bar barColor="#fde68a" />
    <Column id=unipersonales title="Fogares de 1 persoa" fmt=pct1 />
    <Column id=cuatro_o_mas title="Fogares de 4 ou máis" fmt=pct1 />
    <Column id=hogares title="Fogares" fmt=num0 />
</DataTable>

## Por provincia

```sql provincias
SELECT h.cod AS cod_prov, t.nombre AS provincia, '/gl' || t.ruta AS ruta, h.tamano_medio, h.pct_unipersonales / 100 AS unipersonales
FROM mother.demografia_hogares h
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = h.cod
WHERE h.nivel = 'provincia' AND h.anio = (SELECT max(anio) FROM mother.demografia_hogares)
ORDER BY h.pct_unipersonales DESC
```

Os fogares dunha soa persoa van do {formatNumber(provincias[0]?.unipersonales / 0.01, 1)} % de {provincias[0]?.provincia} ao {formatNumber(provincias.slice(-1)[0]?.unipersonales / 0.01, 1)} % de {provincias.slice(-1)[0]?.provincia}.

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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    title="Fogares dunha soa persoa (% dos fogares)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'unipersonales', title: 'Fogares de 1 persoa', fmt: 'pct1'},
        {id: 'tamano_medio', title: 'Persoas por fogar', fmt: 'num2'}
    ]}
/>

---

## Fontes e notas

- **[INE – Estatística Continua de Poboación: fogares](https://www.ine.es/jaxiT3/Tabla.htm?t=60133)**: fogares por número de membros por comunidade ([60131](https://www.ine.es/jaxiT3/Tabla.htm?t=60131)) e provincia ([60133](https://www.ine.es/jaxiT3/Tabla.htm?t=60133)) e tamaño medio do fogar ([60132](https://www.ine.es/jaxiT3/Tabla.htm?t=60132) e [60134](https://www.ine.es/jaxiT3/Tabla.htm?t=60134)). Datos provisionais a 1 de xaneiro; o INE publícaos cada trimestre desde 2021. A antiga Enquisa Continua de Fogares (2013-2020) non se inclúe porque o seu método é distinto.

<LastRefreshed prefix="Datos actualizados" />
