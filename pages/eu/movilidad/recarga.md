---
title: Karga-puntuak
description: "Espainian auto elektrikoentzako karga-puntu publikoen mapa potentziaren eta operadorearen arabera, eta probintzia bakoitzean puntu bakoitzeko zenbat auto entxufagarri dauden."
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

# 🔌 Karga-puntu publikoak

Non karga daitekeen auto elektriko bat Espainian, Trantsizio Ekologikorako Ministerioak DGTren Sarbide Puntu Nazionalean egunero argitaratzen duen sarbide publikoko karga-puntuen erregistro ofizialaren arabera.

<Grid cols=3>
    <KpiCard
        title="Karga-puntu publikoak"
        value={totales[0]?.puntos}
        formattedValue="{formatNumber(100000 * totales[0]?.puntos / totales[0]?.poblacion, 0)} 100.000 biztanleko"
        period="{formatNumber(totales[0]?.puntos, 0)} puntu, {formatNumber(totales[0]?.sitios, 0)} kokalekutan"
        source="NAP DGT / MITECO"
    />
    <KpiCard
        title="Azkarrak (50 kW edo gehiago)"
        value={totales[0]?.puntos_rapidos}
        formattedValue="Puntuen {formatNumber(totales[0]?.puntos_rapidos / totales[0]?.puntos / 0.01, 1)} %"
        period="{formatNumber(totales[0]?.puntos_rapidos, 0)} puntu azkar; horietatik {formatNumber(totales[0]?.puntos_ultrarrapidos, 0)}, 150 kW edo gehiagokoak"
        source="NAP DGT / MITECO"
    />
    <KpiCard
        title="Auto entxufagarriak puntu bakoitzeko"
        value={totales[0]?.enchufables_por_punto}
        formattedValue={formatNumber(totales[0]?.enchufables_por_punto, 1)}
        period="{formatNumber(totales[0]?.enchufables, 0)} turismo elektriko eta hibrido entxufagarri"
        source="DGT"
    />
</Grid>

## Mapa

<ButtonGroup name=tramo title="Potentzia">
    <ButtonGroupItem valueLabel="Guztiak" value="todos" default />
    <ButtonGroupItem valueLabel="Ultra-azkarrak (≥150 kW)" value="Ultrarrápida (≥150 kW)" />
    <ButtonGroupItem valueLabel="Azkarrak (50-149 kW)" value="Rápida (50-149 kW)" />
    <ButtonGroupItem valueLabel="Erdi-azkarrak (22-49 kW)" value="Semirrápida (22-49 kW)" />
    <ButtonGroupItem valueLabel="Motelak (<22 kW)" value="Lenta (<22 kW)" />
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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Karga-puntuak: MITECO, NAP (DGT) bidez"
    tooltip={[
        {id: 'sitio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'operador', title: 'Operadorea'},
        {id: 'puntos', title: 'Puntuak', fmt: 'num0'},
        {id: 'potencia_max_kw', title: 'Gehieneko potentzia (kW)', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Zirkulu bakoitza kokaleku bat da (elektrolinera bat, aparkaleku bat...), eta haren tamaina, puntu-kopurua. Kolorea kokalekuko punturik ahaltsuenaren araberakoa da. Kanariak hego-mendebaldean agertzen dira: handitu mapa.</p>

<BarChart
    data={tramos}
    x=tramo
    y=puntos
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Karga-puntuak potentziaren arabera"
/>

## Probintziaka

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
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: DGT eta MITECO"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'enchufables_por_punto', title: 'Entxufagarriak puntu bakoitzeko', fmt: 'num1'},
        {id: 'puntos', title: 'Puntuak', fmt: 'num0'},
        {id: 'puntos_por_100k_hab', title: 'Puntuak 100.000 biztanleko', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Ilunago = auto entxufagarri gehiago puntu publiko bakoitzeko, hau da, presio handiagoa karga-sarearen gainean.</p>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Probintzia" />
    <Column id=puntos title="Puntuak" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=puntos_rapidos title="Azkarrak (≥50 kW)" fmt=num0 />
    <Column id=puntos_por_100k_hab title="100.000 biztanleko" fmt=num0 />
    <Column id=turismos_enchufables title="Turismo entxufagarriak" fmt=num0 />
    <Column id=enchufables_por_punto title="Entxufagarriak puntu bakoitzeko" fmt=num1 />
</DataTable>

```sql operadores
SELECT operador, sum(puntos) AS puntos, count(*) AS sitios, sum(puntos) FILTER (WHERE potencia_max_kw >= 50) AS puntos_en_sitios_rapidos
FROM mother.movilidad_recarga_sitios
GROUP BY operador
ORDER BY puntos DESC
```

## Operadoreak

<DataTable data={operadores} rows=15 search=true>
    <Column id=operador title="Operadorea" />
    <Column id=puntos title="Puntuak" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=sitios title="Kokalekuak" fmt=num0 />
</DataTable>

---

## Iturriak eta oharrak

- **[Trafikoaren eta mugikortasunaren Sarbide Puntu Nazionala (DGT) – Karga elektrikoko puntuak](https://nap.dgt.es/dataset/puntos-de-recarga-electrica-para-vehiculos)**, Trantsizio Ekologikorako Ministerioaren datuak, operadoreek aitortzen dutenaren arabera (184/2022 Errege Dekretua). Egunero eguneratzen da.
- 43 kW edo gehiagoko puntuak soilik aitortu behar dira nahitaez; motelak (hotelak, merkataritza-guneak, garajeak) borondatez aitortzen dira, beraz haien kopurua **gutxienekoa** da. Ez ditu barne hartzen etxebizitzetako edo enpresetako puntu pribatuak.
- Udalerria eta probintzia kokaleku bakoitzaren koordenatuen arabera esleituta. Puntu baten potentzia = konektore ahaltsuenarena.
- Turismo entxufagarriak: argitaratutako azken hilabeteko DGTren parkea (elektriko hutsak eta hibrido entxufagarriak), helbideko probintziaren arabera.

<LastRefreshed prefix="Datuak eguneratuta" />
