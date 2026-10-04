---
title: Electrificación de la economía
description: "Cuánta de la energía que consumen la industria, el transporte, los hogares y los servicios en España es electricidad, cómo se calientan las casas por provincia y cuántas bombas de calor hay."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

```sql principales
SELECT anio, cod_sector, sector, cuota_electricidad_pct, total, electricidad
FROM mother.electrificacion_sectores
WHERE cod_sector IN ('FC_E', 'FC_IND_E', 'FC_TRA_E', 'FC_OTH_HH_E', 'FC_OTH_CP_E')
ORDER BY anio
```

```sql ultimo
SELECT
    max(anio) AS anio,
    max(cuota_electricidad_pct) FILTER (WHERE cod_sector = 'FC_E') AS total,
    max(cuota_electricidad_pct) FILTER (WHERE cod_sector = 'FC_IND_E') AS industria,
    max(cuota_electricidad_pct) FILTER (WHERE cod_sector = 'FC_TRA_E') AS transporte,
    max(cuota_electricidad_pct) FILTER (WHERE cod_sector = 'FC_OTH_HH_E') AS hogares,
    max(cuota_electricidad_pct) FILTER (WHERE cod_sector = 'FC_OTH_CP_E') AS servicios
FROM ${principales}
WHERE anio = (SELECT max(anio) FROM ${principales})
```

```sql hace_10
SELECT
    max(cuota_electricidad_pct) FILTER (WHERE cod_sector = 'FC_E') AS total,
    max(cuota_electricidad_pct) FILTER (WHERE cod_sector = 'FC_OTH_HH_E') AS hogares
FROM ${principales}
WHERE anio = (SELECT max(anio) - 10 FROM ${principales})
```

# ⚡ La electrificación de la economía

Descarbonizar no es solo producir la electricidad con renovables: también hay que **usar electricidad** donde hoy se queman gas, gasóleo o gasolina, en coches eléctricos, bombas de calor o procesos industriales. ¿Cuánto hemos avanzado?

<Grid cols=4>
    <KpiCard
        title="Electricidad en el consumo final"
        value={ultimo[0]?.total}
        formattedValue="{formatNumber(ultimo[0]?.total, 1)} %"
        period="de toda la energía que se usa · {ultimo[0]?.anio}"
        change={hace_10[0]?.total != null ? (ultimo[0].total - hace_10[0].total).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="en 10 años"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
    />
    <KpiCard
        title="Hogares"
        value={ultimo[0]?.hogares}
        formattedValue="{formatNumber(ultimo[0]?.hogares, 1)} %"
        period="de su energía es electricidad"
        change={hace_10[0]?.hogares != null ? (ultimo[0].hogares - hace_10[0].hogares).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="en 10 años"
        direction="positive-up"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_OTH_HH_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
    />
    <KpiCard
        title="Industria"
        value={ultimo[0]?.industria}
        formattedValue="{formatNumber(ultimo[0]?.industria, 1)} %"
        period="de su energía es electricidad"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_IND_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
    />
    <KpiCard
        title="Transporte"
        value={ultimo[0]?.transporte}
        formattedValue="{formatNumber(ultimo[0]?.transporte, 1)} %"
        period="casi todo es tren; el coche eléctrico apenas se nota aún"
        source="Eurostat"
        sparklineData={principales.filter(d => d.cod_sector === 'FC_TRA_E').map(d => ({anio: d.anio, valor: d.cuota_electricidad_pct}))}
        href="/movilidad/coche-electrico"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'electrificacion'
```

<Comparativa data={comparativa_internacional} />

## ¿Cuánta de la energía que se usa es electricidad?

<LineChart
    data={principales}
    x=anio
    y=cuota_electricidad_pct
    series=sector
    yFmt='0"%"'
    xFmt="####"
    legend=true
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b', '#7c3aed', '#94a3b8']}
/>

<p class="text-xs text-gray-500">Peso de la electricidad en el consumo final de energía de cada sector (uso energético, sin materias primas). En el conjunto de la economía la electrificación está prácticamente estancada en torno a una cuarta parte desde hace una década: los hogares avanzan, pero el transporte, que gasta más energía que ningún otro sector, sigue funcionando casi solo con derivados del petróleo. "Comercio y servicios públicos" incluye oficinas, comercios, hospitales, colegios y edificios de las administraciones: Eurostat no los separa.</p>

```sql mix_sectores
SELECT
    e.sector,
    f.fuente,
    CASE f.orden
        WHEN 1 THEN e.cuota_electricidad_pct
        WHEN 2 THEN e.cuota_gas_pct
        WHEN 3 THEN e.cuota_petroleo_pct
        WHEN 4 THEN e.cuota_renovables_pct
        ELSE e.cuota_calor_carbon_pct
    END AS cuota
FROM mother.electrificacion_sectores e
CROSS JOIN (VALUES (1, 'Electricidad'), (2, 'Gas natural'), (3, 'Petróleo'), (4, 'Renovables y calor ambiente'), (5, 'Calor y carbón')) AS f(orden, fuente)
WHERE e.anio = (SELECT max(anio) FROM mother.electrificacion_sectores)
  AND e.cod_sector IN ('FC_IND_E', 'FC_TRA_E', 'FC_OTH_HH_E', 'FC_OTH_CP_E', 'FC_OTH_AF_E')
ORDER BY e.sector, f.orden
```

<BarChart
    data={mix_sectores}
    x=sector
    y=cuota
    series=fuente
    swapXY=true
    type=stacked100
    yFmt='0"%"'
    colorPalette={['#1d4ed8', '#f59e0b', '#78716c', '#0f766e', '#cbd5e1']}
    title="Con qué energía funciona cada sector ({ultimo[0]?.anio})"
/>

## La industria, rama a rama

```sql ramas
SELECT sector, cuota_electricidad_pct, total, electricidad
FROM mother.electrificacion_sectores
WHERE tipo_sector = 'rama_industria' AND anio = (SELECT max(anio) FROM mother.electrificacion_sectores)
ORDER BY cuota_electricidad_pct DESC
```

<BarChart
    data={ramas}
    x=sector
    y=cuota_electricidad_pct
    swapXY=true
    sort=false
    yFmt='0"%"'
    fillColor="#1d4ed8"
    title="Peso de la electricidad en la energía de cada rama industrial"
/>

<p class="text-xs text-gray-500">Las ramas que necesitan calor a muy alta temperatura (cemento, cerámica, vidrio, química) son las más difíciles de electrificar y siguen dependiendo del gas; la siderurgia ya es en buena parte eléctrica porque en España la mayor parte del acero se fabrica en hornos de arco eléctrico a partir de chatarra.</p>

## Cómo se calientan las casas

```sql calefaccion
SELECT anio, combustible, cuota_pct AS cuota, tj
FROM mother.electrificacion_hogares
WHERE cod_uso = 'FC_OTH_HH_E_SH'
ORDER BY anio
```

```sql agua
SELECT combustible, cuota_pct FROM mother.electrificacion_hogares
WHERE cod_uso = 'FC_OTH_HH_E_WH' AND anio = (SELECT max(anio) FROM mother.electrificacion_hogares)
ORDER BY cuota_pct DESC
```

<BarChart
    data={calefaccion}
    x=anio
    y=cuota
    series=combustible
    type=stacked100
    yFmt='0"%"'
    xFmt="####"
    colorPalette={['#1d4ed8', '#f59e0b', '#78716c', '#65a30d', '#fde047', '#0f766e', '#f472b6', '#cbd5e1']}
    title="Energía para calefacción en los hogares, por combustible"
/>

<p class="text-xs text-gray-500">En energía, la calefacción de los hogares se reparte casi a partes iguales entre biomasa (leña y pellets, sobre todo en zonas rurales), gas natural y gasóleo o butano; la electricidad y el calor que captan las bombas de calor del aire suman alrededor de un 15 %. Una bomba de calor aprovecha energía gratuita del aire: por cada kWh de electricidad entrega 3 o 4 de calor, y Eurostat cuenta esa parte como "calor ambiente".</p>

```sql bombas
SELECT anio, tecnologia, mw / 1000 AS gw
FROM mother.electrificacion_bombas_calor
ORDER BY anio
```

<BarChart
    data={bombas}
    x=anio
    y=gw
    series=tecnologia
    type=stacked
    yFmt=num1
    xFmt="####"
    yAxisTitle="GW térmicos"
    title="Bombas de calor instaladas (potencia térmica)"
/>

<p class="text-xs text-gray-500">La gran mayoría son equipos aire-aire reversibles, es decir, aparatos de aire acondicionado tipo split que también dan calor; Eurostat los cuenta como bombas de calor aunque muchos se usen sobre todo en verano. La aerotermia aire-agua (la que sustituye a una caldera y calienta radiadores, suelo radiante y agua caliente) es todavía una parte pequeña.</p>

```sql provincias
SELECT cod AS cod_prov, nombre AS provincia, viviendas, cuota_electricidad_pct, cuota_gas_pct, cuota_petroleo_pct
FROM mother.electrificacion_calefaccion_provincia
WHERE nivel = 'provincia'
ORDER BY cuota_electricidad_pct DESC
```

```sql espana_viv
SELECT * FROM mother.electrificacion_calefaccion_provincia WHERE nivel = 'pais'
```

### Viviendas que se calientan con electricidad, por provincia

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="cuota_electricidad_pct"
    valueFmt='0"%"'
    colorPalette={['#fff7ed', '#93c5fd', '#1d4ed8']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE (ECEPOV 2021)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_electricidad_pct', title: 'Electricidad', fmt: '0"%"'},
        {id: 'cuota_gas_pct', title: 'Gas natural', fmt: '0"%"'},
        {id: 'cuota_petroleo_pct', title: 'Gasóleo y derivados', fmt: '0"%"'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Provincia" />
    <Column id=viviendas title="Viviendas con calefacción" fmt=num0 />
    <Column id=cuota_electricidad_pct title="Electricidad" fmt='0"%"' contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_gas_pct title="Gas natural" fmt='0"%"' />
    <Column id=cuota_petroleo_pct title="Gasóleo y derivados" fmt='0"%"' />
</DataTable>

<p class="text-xs text-gray-500">{#if espana_viv.length > 0}En España, {formatNumber(espana_viv[0].cuota_electricidad_pct, 0)} de cada 100 viviendas con calefacción la tienen eléctrica. {/if}En el sur y en Canarias, con inviernos suaves, predominan los radiadores eléctricos y el aire acondicionado; en el interior norte, con inviernos fríos y largos, el gas natural y el gasóleo. Encuesta de Características Esenciales de la Población y las Viviendas 2021 del INE (muestral): cuenta viviendas, no energía, y no distingue un radiador de una bomba de calor.</p>

---

## Fuentes y notas

- **[Eurostat – Balances energéticos completos (nrg_bal_c)](https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table)**: consumo final de energía por sector, rama industrial y combustible, 1990-último año. La comparación con otros países usa la misma tabla y la misma definición (electricidad entre consumo final de energía, uso energético) y solo cubre países europeos; Noruega y Suecia aparecen como referencia (borde discontinuo) por ser las economías más electrificadas de Europa.
- **[Eurostat – Consumo de energía de los hogares por uso (nrg_d_hhq)](https://ec.europa.eu/eurostat/databrowser/view/nrg_d_hhq/default/table)**: calefacción, agua caliente, cocina, refrigeración e iluminación por combustible, desde 2010 (en España lo elabora el IDAE).
- **[Eurostat – Bombas de calor (nrg_inf_hptc)](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_hptc/default/table)**: potencia térmica por tecnología.
- **[INE – ECEPOV 2021, tabla 56784](https://www.ine.es/jaxi/Tabla.htm?tpx=56784)**: viviendas principales con calefacción por tipo de combustible y provincia.
- No hay estadística oficial abierta del sistema de calefacción de los edificios públicos: los registros de certificados energéticos de las comunidades no recogen el combustible.

<LastRefreshed prefix="Datos actualizados" />
