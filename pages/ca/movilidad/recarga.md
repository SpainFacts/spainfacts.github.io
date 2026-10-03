---
title: Punts de recàrrega
description: "Mapa dels punts de recàrrega públics per a cotxes elèctrics a Espanya per potència i operador, i quants cotxes endollables hi ha per cada punt a cada província."
i18n_origen: ddaf573592d6
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql totales
SELECT
    sum(puntos) AS puntos,
    sum(sitios) AS sitios,
    sum(puntos_rapidos) AS puntos_rapidos,
    sum(puntos_ultrarrapidos) AS puntos_ultrarrapidos,
    sum(turismos_enchufables) AS enchufables,
    sum(turismos_enchufables) / sum(puntos) AS enchufables_por_punto,
    (SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total' ORDER BY anio DESC LIMIT 1) AS poblacion
FROM mother.movilidad_recarga_provincia
```

```sql tramos
SELECT tramo, tramo_orden, count(*) AS sitios, sum(puntos) AS puntos
FROM mother.movilidad_recarga_sitios
GROUP BY ALL
ORDER BY tramo_orden
```

# 🔌 Punts de recàrrega públics

On es pot carregar un cotxe elèctric a Espanya, segons el registre oficial de punts de recàrrega d'accés públic que el Ministeri per a la Transició Ecològica publica cada dia al Punt d'Accés Nacional de la DGT.

<Grid cols=3>
    <KpiCard
        title="Punts de recàrrega públics"
        value={totales[0]?.puntos}
        formattedValue="{formatNumber(100000 * totales[0]?.puntos / totales[0]?.poblacion, 0)} per 100.000 hab."
        period="{formatNumber(totales[0]?.puntos, 0)} punts en {formatNumber(totales[0]?.sitios, 0)} emplaçaments"
        source="NAP DGT / MITECO"
    />
    <KpiCard
        title="Ràpids (50 kW o més)"
        value={totales[0]?.puntos_rapidos}
        formattedValue="{formatNumber(totales[0]?.puntos_rapidos / totales[0]?.puntos / 0.01, 1)} % dels punts"
        period="{formatNumber(totales[0]?.puntos_rapidos, 0)} punts ràpids, {formatNumber(totales[0]?.puntos_ultrarrapidos, 0)} dels quals de 150 kW o més"
        source="NAP DGT / MITECO"
    />
    <KpiCard
        title="Cotxes endollables per punt"
        value={totales[0]?.enchufables_por_punto}
        formattedValue={formatNumber(totales[0]?.enchufables_por_punto, 1)}
        period="{formatNumber(totales[0]?.enchufables, 0)} turismes elèctrics i híbrids endollables"
        source="DGT"
    />
</Grid>

## Mapa

<ButtonGroup name=tramo title="Potència">
    <ButtonGroupItem valueLabel="Tots" value="todos" default />
    <ButtonGroupItem valueLabel="Ultraràpids (≥150 kW)" value="Ultrarrápida (≥150 kW)" />
    <ButtonGroupItem valueLabel="Ràpids (50-149 kW)" value="Rápida (50-149 kW)" />
    <ButtonGroupItem valueLabel="Semiràpids (22-49 kW)" value="Semirrápida (22-49 kW)" />
    <ButtonGroupItem valueLabel="Lents (<22 kW)" value="Lenta (<22 kW)" />
</ButtonGroup>

```sql mapa
-- Primero un emplazamiento de cada tramo (en orden) para fijar los colores de
-- la leyenda; luego el resto, de menos a más potencia para que los rápidos queden encima.
SELECT *
FROM (
    SELECT *, row_number() OVER (PARTITION BY tramo ORDER BY potencia_max_kw DESC, sitio_id) = 1 AS primera
    FROM mother.movilidad_recarga_sitios
    WHERE '${inputs.tramo}' = 'todos' OR tramo = '${inputs.tramo}'
)
ORDER BY primera DESC, CASE WHEN primera THEN tramo_orden END, potencia_max_kw
```

```sql colores
SELECT DISTINCT tramo, tramo_orden,
    CASE tramo_orden WHEN 1 THEN '#7c3aed' WHEN 2 THEN '#0f766e' WHEN 3 THEN '#14b8a6' ELSE '#a3e635' END AS color
FROM ${mapa}
ORDER BY tramo_orden
```

<MapaEspana
    data={mapa}
    lat=latitud
    long=longitud
    size=puntos
    sizeFmt=num0
    maxSize={14}
    value=tramo
    legendType=categorical
    colorPalette={colores?.length ? colores.map(d => d.color) : ['#7c3aed', '#0f766e', '#14b8a6', '#a3e635']}
    opacity={0.7}
    pointName=sitio
    height={600}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Punts de recàrrega: MITECO via NAP (DGT)"
    tooltip={[
        {id: 'sitio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'operador', title: 'Operador'},
        {id: 'puntos', title: 'Punts', fmt: 'num0'},
        {id: 'potencia_max_kw', title: 'Potència màxima (kW)', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Cada cercle és un emplaçament (una electrolinera, un aparcament...) i la seva mida, el nombre de punts. Color segons el punt més potent de l'emplaçament. Les Canàries apareixen al sud-oest: amplia el mapa.</p>

<BarChart
    data={tramos}
    x=tramo
    y=puntos
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Punts de recàrrega per potència"
/>

## Per província

```sql provincias
SELECT * FROM mother.movilidad_recarga_provincia ORDER BY puntos DESC
```

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="enchufables_por_punto"
    valueFmt="num1"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: DGT i MITECO"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'enchufables_por_punto', title: 'Endollables per punt', fmt: 'num1'},
        {id: 'puntos', title: 'Punts', fmt: 'num0'},
        {id: 'puntos_por_100k_hab', title: 'Punts per 100.000 hab.', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Més fosc = més cotxes endollables per cada punt públic, és a dir, més pressió sobre la xarxa de recàrrega.</p>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Província" />
    <Column id=puntos title="Punts" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=puntos_rapidos title="Ràpids (≥50 kW)" fmt=num0 />
    <Column id=puntos_por_100k_hab title="Per 100.000 hab." fmt=num0 />
    <Column id=turismos_enchufables title="Turismes endollables" fmt=num0 />
    <Column id=enchufables_por_punto title="Endollables per punt" fmt=num1 />
</DataTable>

```sql operadores
SELECT operador, sum(puntos) AS puntos, count(*) AS sitios, sum(puntos) FILTER (WHERE potencia_max_kw >= 50) AS puntos_en_sitios_rapidos
FROM mother.movilidad_recarga_sitios
GROUP BY operador
ORDER BY puntos DESC
```

## Operadors

<DataTable data={operadores} rows=15 search=true>
    <Column id=operador title="Operador" />
    <Column id=puntos title="Punts" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=sitios title="Emplaçaments" fmt=num0 />
</DataTable>

---

## Fonts i notes

- **[Punt d'Accés Nacional de trànsit i mobilitat (DGT) – Punts de recàrrega elèctrica](https://nap.dgt.es/dataset/puntos-de-recarga-electrica-para-vehiculos)**, dades del Ministeri per a la Transició Ecològica a partir del que declaren els operadors (Reial decret 184/2022). S'actualitza cada dia.
- Només és obligatori declarar els punts de 43 kW o més; els lents (hotels, centres comercials, garatges) es declaren de manera voluntària, de manera que el seu nombre és un **mínim**. No inclou punts privats en habitatges o empreses.
- Municipi i província assignats per les coordenades de cada emplaçament. Potència d'un punt = la del connector més potent.
- Turismes endollables: parc de la DGT (elèctrics purs i híbrids endollables) de l'últim mes publicat, per província del domicili.

<LastRefreshed prefix="Dades actualitzades" />
