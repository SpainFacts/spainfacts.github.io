---
title: Petrol stations and fuel
description: "Map of Spain's petrol stations by brand and group, how many there are per inhabitant in each province, municipalities with none, the price of diesel and petrol since 2007 in real euros, taxes compared with the rest of the EU and litres of fuel per inhabitant."
i18n_origen: 3712aa9c0eaa
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const CARBURANTE = { gasoleo_a: 'Road diesel', gasolina_95: 'Petrol 95', glp: 'LPG (autogas)' };
    const TIPO = {
        'Petrolera': 'Oil companies',
        'Bajo coste': 'Low cost',
        'Supermercado': 'Supermarkets',
        'Cooperativa': 'Cooperatives',
        'Independiente con marca': 'Independents',
        'Independiente u otra': 'Independents'
    };
    const COLOR_TIPO = { 'Oil companies': '#0f766e', 'Low cost': '#f59e0b', 'Supermarkets': '#7c3aed', 'Cooperatives': '#65a30d', 'Independents': '#94a3b8' };
    const PARTE = { 'Sin impuestos': 'Before tax', 'Impuestos (IVA e impuesto especial)': 'Taxes (VAT and excise duty)' };
    const etiquetar = (filas, columna, f) => Array.from(filas ?? []).map((d) => ({ ...d, [columna]: f(d) }));
</script>

```sql totales
SELECT
    count(*) AS estaciones,
    count(*) FILTER (WHERE tipo = 'Bajo coste') AS bajo_coste,
    avg(precio_gasoleo_a) AS gasoleo_a,
    avg(precio_gasolina_95) AS gasolina_95,
    strftime(max(fecha_precios), '%d/%m/%Y') AS fecha,
    (SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total' ORDER BY anio DESC LIMIT 1) AS poblacion,
    (SELECT sum(poblacion_sin_gasolinera) FROM mother.movilidad_gasolineras_provincia) AS poblacion_sin,
    (SELECT sum(municipios_sin_gasolinera) FROM mother.movilidad_gasolineras_provincia) AS municipios_sin,
    (SELECT sum(municipios) FROM mother.movilidad_gasolineras_provincia) AS municipios
FROM mother.movilidad_gasolineras
```

```sql consumo_pais
SELECT anio, litros_automocion_hab, gasoleo_pct_automocion
FROM mother.movilidad_carburantes_consumo
WHERE nivel = 'pais' AND meses = 12
ORDER BY anio
```

```sql consumo_ultimo
SELECT c.anio, c.litros_automocion_hab, m.litros_automocion_hab AS maximo, m.anio AS anio_maximo
FROM ${consumo_pais} c
CROSS JOIN (SELECT * FROM ${consumo_pais} ORDER BY litros_automocion_hab DESC LIMIT 1) m
ORDER BY c.anio DESC
LIMIT 1
```

# ⛽ Petrol stations and fuel

Where Spain's petrol stations are and who owns them, how much it costs to fill the tank compared with previous years and with the rest of Europe, and how much fuel is used per inhabitant. Prices and stations come from the Ministry for the Ecological Transition's petrol station geoportal, which every station is required to keep up to date.

<Grid cols=4>
    <KpiCard
        title="Petrol stations"
        value={totales[0]?.estaciones}
        formattedValue={formatNumber(10000 * totales[0]?.estaciones / totales[0]?.poblacion, 1)}
        unit=" per 10,000 people"
        period="{formatNumber(totales[0]?.estaciones, 0)} stations open to the public"
        source="MITECO"
    />
    <KpiCard
        title="Road diesel"
        value={totales[0]?.gasoleo_a}
        formattedValue="{formatNumber(totales[0]?.gasoleo_a, 3)} €/l"
        period="average price on {totales[0]?.fecha}"
        source="MITECO"
    />
    <KpiCard
        title="Petrol 95"
        value={totales[0]?.gasolina_95}
        formattedValue="{formatNumber(totales[0]?.gasolina_95, 3)} €/l"
        period="average price on {totales[0]?.fecha}"
        source="MITECO"
    />
    <KpiCard
        title="People with no petrol station in their municipality"
        value={totales[0]?.poblacion_sin}
        formattedValue="{formatNumber(100 * totales[0]?.poblacion_sin / totales[0]?.poblacion, 1)}%"
        period="{formatNumber(totales[0]?.municipios_sin, 0)} of {formatNumber(totales[0]?.municipios, 0)} municipalities have none"
        source="MITECO and INE"
    />
</Grid>

## Map of petrol stations

<ButtonGroup name=tipo_mapa title="Type">
    <ButtonGroupItem valueLabel="All" value="todas" default />
    <ButtonGroupItem valueLabel="Oil companies" value="Petrolera" />
    <ButtonGroupItem valueLabel="Low cost" value="Bajo coste" />
    <ButtonGroupItem valueLabel="Supermarkets" value="Supermercado" />
</ButtonGroup>

```sql mapa
-- Primero una estación de cada tipo, en orden fijo, para que los colores de la leyenda no
-- cambien con el filtro; después el resto, con las petroleras debajo para que se vean las demás
SELECT * FROM (
    SELECT
        ideess, rotulo, grupo, tipo, municipio, provincia, latitud, longitud,
        precio_gasoleo_a, precio_gasolina_95,
        CASE tipo WHEN 'Petrolera' THEN 1 WHEN 'Bajo coste' THEN 2 WHEN 'Supermercado' THEN 3 WHEN 'Cooperativa' THEN 4 ELSE 5 END AS orden,
        row_number() OVER (PARTITION BY tipo ORDER BY ideess) = 1 AS primera
    FROM mother.movilidad_gasolineras
    WHERE latitud IS NOT NULL
      AND ('${inputs.tipo_mapa}' = 'todas' OR tipo = '${inputs.tipo_mapa}')
)
ORDER BY primera DESC, CASE WHEN primera THEN orden END, orden
```

<MapaEspana
    data={etiquetar(mapa, 'tipo_texto', (d) => TIPO[d.tipo] ?? d.tipo)}
    lat=latitud
    long=longitud
    value=tipo_texto
    legendType=categorical
    colorPalette={[...new Set(etiquetar(mapa, 'tipo_texto', (d) => TIPO[d.tipo] ?? d.tipo).map((d) => d.tipo_texto))].map((t) => COLOR_TIPO[t] ?? '#94a3b8')}
    maxSize={4}
    opacity={0.75}
    pointName=rotulo
    height={620}
    tooltip={[
        {id: 'rotulo', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'grupo', title: 'Group'},
        {id: 'municipio', title: 'Municipality'},
        {id: 'precio_gasoleo_a', title: 'Road diesel (€/l)', fmt: '#,##0.000'},
        {id: 'precio_gasolina_95', title: 'Petrol 95 (€/l)', fmt: '#,##0.000'}
    ]}
/>

<p class="text-xs text-gray-500">Each dot is a petrol station open to the public; prices as of the latest data load. The Canary Islands are in the inset at the bottom left.</p>

## Who owns the petrol stations

```sql grupos
SELECT grupo, tipo, estaciones, cuota_pct, precio_gasoleo_a, precio_gasolina_95, dif_gasoleo_a, dif_gasolina_95
FROM mother.movilidad_gasolineras_grupos
WHERE estaciones >= 20
ORDER BY estaciones DESC
```

```sql por_tipo
SELECT tipo, sum(estaciones) AS estaciones, sum(estaciones) * 1.0 / (SELECT sum(estaciones) FROM mother.movilidad_gasolineras_grupos) AS cuota,
    sum(precio_gasoleo_a * estaciones) / sum(estaciones) AS precio_gasoleo_a
FROM mother.movilidad_gasolineras_grupos
GROUP BY tipo
ORDER BY estaciones DESC
```

<BarChart
    data={etiquetar(grupos.slice(0, 15), 'tipo_texto', (d) => TIPO[d.tipo] ?? d.tipo)}
    x=grupo
    y=estaciones
    series=tipo_texto
    swapXY=true
    sort=false
    yFmt=num0
    colorPalette={['#0f766e', '#f59e0b', '#7c3aed', '#94a3b8', '#65a30d']}
    title="The 15 groups with the most petrol stations"
/>

One in four petrol stations belongs to Repsol (including Campsa and Petronor). Low-cost chains, almost always unstaffed, sell diesel several cents below the average:

<DataTable data={grupos} rows=15 search=true>
    <Column id=grupo title="Group" />
    <Column id=estaciones title="Petrol stations" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_pct title="% of the network" fmt=num1 />
    <Column id=precio_gasoleo_a title="Road diesel (€/l)" fmt="#,##0.000" />
    <Column id=dif_gasoleo_a title="Vs the average (€/l)" fmt="+#,##0.000;-#,##0.000" contentType=delta downIsGood=true />
    <Column id=precio_gasolina_95 title="Petrol 95 (€/l)" fmt="#,##0.000" />
    <Column id=dif_gasolina_95 title="Vs the average (€/l)" fmt="+#,##0.000;-#,##0.000" contentType=delta downIsGood=true />
</DataTable>

<p class="text-xs text-gray-500">Group taken from the station's brand sign: Campsa and Petronor belong to Repsol; Shell stations in Spain are run by DISA under a brand licence; Cepsa has been called Moeve since 2024. Simple average across stations, not weighted by litres sold (the Ministry does not publish them). Only groups with 20 or more petrol stations.</p>

## By province

```sql provincias
SELECT * FROM mother.movilidad_gasolineras_provincia ORDER BY estaciones_por_10k_hab DESC
```

<ButtonGroup name=indicador_prov title="Show">
    <ButtonGroupItem valueLabel="Petrol stations per inhabitant" value="estaciones_por_10k_hab" default />
    <ButtonGroupItem valueLabel="People with no petrol station" value="poblacion_sin_gasolinera_pct" />
    <ButtonGroupItem valueLabel="Diesel price" value="precio_gasoleo_a" />
    <ButtonGroupItem valueLabel="Litres per inhabitant" value="litros_automocion_hab" />
</ButtonGroup>

```sql prov_mapa
SELECT cod_prov, provincia, estaciones, estaciones_por_10k_hab, poblacion_sin_gasolinera_pct, precio_gasoleo_a, litros_automocion_hab,
    ${inputs.indicador_prov} AS valor
FROM ${provincias}
```

<MapaEspana
    data={prov_mapa}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="valor"
    valueFmt={inputs.indicador_prov === 'precio_gasoleo_a' ? '#,##0.000' : inputs.indicador_prov === 'litros_automocion_hab' ? 'num0' : 'num1'}
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={460}
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'estaciones_por_10k_hab', title: 'Petrol stations per 10,000 people', fmt: 'num1'},
        {id: 'poblacion_sin_gasolinera_pct', title: '% of people with no petrol station in their municipality', fmt: 'num1'},
        {id: 'precio_gasoleo_a', title: 'Road diesel (€/l)', fmt: '#,##0.000'},
        {id: 'litros_automocion_hab', title: 'Litres of fuel per inhabitant per year', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Depopulated provinces have more petrol stations per inhabitant, but also more people living in a municipality with none. Fuel use per inhabitant in each province includes lorries and drivers who fill up while passing through, which is why it is higher in transit provinces.</p>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Province" />
    <Column id=estaciones title="Petrol stations" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=estaciones_por_10k_hab title="Per 10,000 people" fmt=num1 />
    <Column id=municipios_sin_gasolinera title="Municipalities with no petrol station" fmt=num0 />
    <Column id=poblacion_sin_gasolinera_pct title="% of people with no petrol station" fmt=num1 />
    <Column id=bajo_coste_pct title="% low cost" fmt=num1 />
    <Column id=grupo_principal title="Largest group" />
    <Column id=grupo_principal_pct title="% of the largest group" fmt=num0 />
    <Column id=precio_gasoleo_a title="Road diesel (€/l)" fmt="#,##0.000" />
    <Column id=precio_gasolina_95 title="Petrol 95 (€/l)" fmt="#,##0.000" />
</DataTable>

## Prices since 2007

```sql provincias_lista
SELECT DISTINCT cod, nombre, CASE WHEN cod = '00' THEN 0 ELSE 1 END AS orden
FROM mother.movilidad_carburantes_precios
ORDER BY orden, nombre
```

<Dropdown name=territorio_precio title="Area" data={provincias_lista} value=cod label=nombre order=orden defaultValue="00" />

```sql precios
SELECT fecha, producto, precio_litro, precio_litro_real, anio_base
FROM mother.movilidad_carburantes_precios
WHERE cod = '${inputs.territorio_precio.value}'
ORDER BY fecha, producto
```

<LineChart
    data={etiquetar(precios, 'carburante', (d) => CARBURANTE[d.producto] ?? d.producto)}
    x=fecha
    y=precio_litro_real
    series=carburante
    yFmt="#,##0.00"
    yAxisTitle="€ per litre, in constant euros of {precios[0]?.anio_base ?? 'today'}"
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#f59e0b', '#7c3aed']}
    legend=true
/>

<p class="text-xs text-gray-500">Average pump price in constant euros (adjusted for inflation with the CPI), averaged over stations with a price on the 1st, 8th, 15th and 22nd of each month. The peaks of 2008, 2012 and 2022 follow the price of oil; in 2022 the Government gave a 20-cent-per-litre discount at the till, which does not show in the published price.</p>

<LineChart
    data={etiquetar(precios, 'carburante', (d) => CARBURANTE[d.producto] ?? d.producto)}
    x=fecha
    y=precio_litro
    series=carburante
    yFmt="#,##0.00"
    yAxisTitle="€ per litre (euros of each year)"
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#f59e0b', '#7c3aed']}
    legend=true
    title="In euros of the time"
/>

## Compared with the rest of Europe

```sql ue_ultimo
SELECT pais, cod_pais, producto, precio_litro, precio_sin_impuestos_litro, impuestos_litro, impuestos_pct, strftime(fecha, '%m/%Y') AS mes_texto
FROM mother.movilidad_carburantes_ue
WHERE fecha = (SELECT max(fecha) FROM mother.movilidad_carburantes_ue WHERE cod_pais = 'ES')
  AND producto = 'gasoleo_a'
ORDER BY precio_litro DESC
```

```sql ue_barras
SELECT pais, 'Sin impuestos' AS parte, precio_sin_impuestos_litro AS euros, precio_litro FROM ${ue_ultimo}
UNION ALL
SELECT pais, 'Impuestos (IVA e impuesto especial)', impuestos_litro, precio_litro FROM ${ue_ultimo}
ORDER BY precio_litro DESC
```

<BarChart
    data={etiquetar(ue_barras, 'parte', (d) => PARTE[d.parte] ?? d.parte)}
    x=pais
    y=euros
    series=parte
    swapXY=true
    sort=false
    yFmt="#,##0.00"
    colorPalette={['#0f766e', '#fca5a5']}
    title="Road diesel: price per litre in {ue_ultimo[0]?.mes_texto}"
/>

<p class="text-xs text-gray-500">Spanish diesel is among the cheapest in the EU, mainly because it carries less tax: in {ue_ultimo[0]?.mes_texto} taxes made up {formatNumber(ue_ultimo.find((d) => d.cod_pais === 'ES')?.impuestos_pct, 0)}% of the price in Spain and {formatNumber(ue_ultimo.find((d) => d.cod_pais === 'EU27_2020')?.impuestos_pct, 0)}% on average in the EU. Source: European Commission Weekly Oil Bulletin.</p>

```sql ue_serie
SELECT fecha, pais, producto, precio_litro_real
FROM mother.movilidad_carburantes_ue
WHERE cod_pais IN ('ES', 'EU27_2020', 'FR', 'PT', 'DE', 'IT')
  AND producto = 'gasoleo_a'
  AND precio_litro_real IS NOT NULL
ORDER BY fecha, pais
```

<LineChart
    data={ue_serie}
    x=fecha
    y=precio_litro_real
    series=pais
    yFmt="#,##0.00"
    yAxisTitle="€ per litre, constant euros of each country"
    xFmt="mmm yyyy"
    legend=true
    title="Road diesel since 2005, adjusted for each country's inflation"
/>

## How much fuel we use

<KpiCard
    title="Road petrol and diesel per inhabitant"
    value={consumo_ultimo[0]?.litros_automocion_hab}
    formattedValue="{formatNumber(consumo_ultimo[0]?.litros_automocion_hab, 0)} litres a year"
    period="in {consumo_ultimo[0]?.anio}; the peak was {formatNumber(consumo_ultimo[0]?.maximo, 0)} litres in {consumo_ultimo[0]?.anio_maximo}"
    source="CORES"
/>

<BarChart
    data={consumo_pais}
    x=anio
    y=litros_automocion_hab
    yFmt=num0
    fillColor="#0f766e"
    title="Litres of petrol and road diesel per inhabitant per year"
/>

<p class="text-xs text-gray-500">Sales of petrol and road diesel (including lorries, buses and vans), converted from tonnes to litres with the average density of each fuel. Consumption per inhabitant peaked in 2007 and fell 26% by 2013 with the crisis; in 2020 it plunged during the lockdowns. Diesel went from 56% of road fuel in 1997 to close to 80%, and is now falling.</p>

```sql consumo_ccaa
SELECT nombre, anio, litros_automocion_hab
FROM mother.movilidad_carburantes_consumo
WHERE nivel = 'ccaa' AND meses = 12
  AND anio = (SELECT max(anio) FROM mother.movilidad_carburantes_consumo WHERE meses = 12)
ORDER BY litros_automocion_hab DESC
```

<BarChart
    data={consumo_ccaa}
    x=nombre
    y=litros_automocion_hab
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#5eead4"
    title="Litres per inhabitant in {consumo_ccaa[0]?.anio}, by region"
/>

<p class="text-xs text-gray-500">Sales are counted where people fill up, not where the driver lives: Navarre, Castile and León and the Basque Country rank high because the main lorry routes run through them, and in the border provinces (Girona, Gipuzkoa, Navarre) many French drivers fill up, because fuel is cheaper in Spain. Madrid, Ceuta and Melilla sell the least per inhabitant.</p>

---

## Sources and notes

- **[Ministry for the Ecological Transition petrol station geoportal](https://geoportalgasolineras.es/)**, through its [REST fuel price service](https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/): every service station is required to report its prices (Order ITC/2308/2007). Only stations open to the public; restricted-sale stations (cooperatives, fleets) are not included. The history starts in January 2007.
- Municipality of each petrol station assigned from its coordinates; population from the INE municipal register.
- **[CORES, consumption of petroleum products by province](https://www.cores.es/es/estadisticas)**, monthly since 1997, in tonnes; converted to litres with 0.745 kg/l for petrol and 0.835 kg/l for diesel.
- **[European Commission, Weekly Oil Bulletin](https://energy.ec.europa.eu/data-and-analysis/weekly-oil-bulletin_en)**: weekly prices with and without taxes for each EU country since 2005; constant euros with each country's HICP (Eurostat).
- Constant euros for Spain with the INE CPI.

<LastRefreshed prefix="Data updated" />
