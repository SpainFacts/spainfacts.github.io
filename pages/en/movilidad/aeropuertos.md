---
title: Airports
description: "Passengers, flights and cargo at AENA's 46 airports and heliports every month since 2004, per person and by region, how much traffic is domestic, European or from outside the EU, and how Barajas, El Prat or Palma compare with Europe's big airports."
i18n_origen: 1fc33e04e32f
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';

    // Visible chart labels: they go here and not in the SQL, which is identical in
    // every translation (tools/i18n/comprobar.mjs)
    const ESTADO = { completo: 'Full year', incompleto: 'Current year (incomplete)' };
    const MESES = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const MERCADO = { 1: 'Mostly domestic', 2: 'Mostly to the rest of the EU', 3: 'Mostly outside the EU' };
    const TIPO = { 1: 'Domestic', 2: 'Rest of the EU', 3: 'Outside the EU' };
    const GRUPO = { true: 'Spain', false: 'Rest of Europe' };
    const PAIS_RED = { reino_unido: 'United Kingdom', brasil: 'Brazil' };
    const etiquetar = (filas, columna, f) => Array.from(filas ?? []).map((d) => ({ ...d, [columna]: f(d) }));
</script>

```sql red
SELECT * FROM mother.movilidad_aeropuertos_espana
```

```sql ultimo
-- Último mes publicado, con el año móvil de un año antes
SELECT
    r.*,
    strftime(r.mes, '%m/%Y') AS mes_texto,
    a.pasajeros_12m AS pasajeros_12m_antes,
    r.pasajeros_12m / a.pasajeros_12m - 1 AS var_12m,
    r.operaciones_12m / 365.0 AS vuelos_dia
FROM ${red} r
LEFT JOIN ${red} a ON a.mes = r.mes - INTERVAL 12 MONTH
ORDER BY r.mes DESC
LIMIT 1
```

```sql serie_12m
SELECT mes, pasajeros_12m_por_hab, operaciones_12m, mercancia_kg_12m_por_hab
FROM ${red}
WHERE pasajeros_12m IS NOT NULL
ORDER BY mes
```

```sql serie_mes
SELECT mes, pasajeros_por_1000_hab
FROM ${red}
WHERE mes >= (SELECT max(mes) FROM ${red}) - INTERVAL 35 MONTH
ORDER BY mes
```

# ✈️ Airports

How many passengers, flights and goods pass through Spain's airports, according to the traffic statistics AENA publishes every month for the 46 airports and heliports in its network.

<Grid cols=4>
    <KpiCard
        title="Airport passengers"
        value={ultimo[0]?.pasajeros_12m_por_hab}
        formattedValue="{formatNumber(ultimo[0]?.pasajeros_12m_por_hab, 1)} per person"
        period="in the last 12 months · {formatCompact(ultimo[0]?.pasajeros_12m, 1)} passengers up to {ultimo[0]?.mes_texto}"
        change={ultimo[0]?.var_12m != null ? (ultimo[0].var_12m * 100).toFixed(1) : null}
        changePeriod="vs. the previous 12 months"
        direction="neutral"
        source="AENA"
        sparklineData={serie_12m.map(d => ({...d, y: d.pasajeros_12m_por_hab}))}
    />
    <KpiCard
        title="Passengers in the latest month"
        value={ultimo[0]?.pasajeros_por_1000_hab}
        formattedValue="{formatNumber(ultimo[0]?.pasajeros_por_1000_hab, 0)} per 1,000 people"
        period="{formatCompact(ultimo[0]?.pasajeros, 1)} passengers in {ultimo[0]?.mes_texto} · {ultimo[0]?.var_2019 > 0 ? '+' : ''}{formatNumber(ultimo[0]?.var_2019 * 100, 0)}% vs. the same month of 2019"
        change={ultimo[0]?.var_anual != null ? (ultimo[0].var_anual * 100).toFixed(1) : null}
        changePeriod="vs. the same month a year earlier"
        direction="neutral"
        source="AENA"
        sparklineData={serie_mes.map(d => ({...d, y: d.pasajeros_por_1000_hab}))}
    />
    <KpiCard
        title="Flights (landings and take-offs)"
        value={ultimo[0]?.vuelos_dia}
        formattedValue="{formatNumber(ultimo[0]?.vuelos_dia, 0)} a day"
        period="average of the last 12 months · {formatNumber(ultimo[0]?.pasajeros_por_operacion, 0)} passengers per flight in {ultimo[0]?.mes_texto}"
        source="AENA"
        sparklineData={serie_12m.map(d => ({...d, y: d.operaciones_12m / 365}))}
    />
    <KpiCard
        title="Air cargo"
        value={ultimo[0]?.mercancia_kg_12m_por_hab}
        formattedValue="{formatNumber(ultimo[0]?.mercancia_kg_12m_por_hab, 1)} kg per person"
        period="in the last 12 months · {formatNumber(ultimo[0]?.mercancia_t_12m / 1000, 0)} thousand tonnes"
        source="AENA"
        sparklineData={serie_12m.map(d => ({...d, y: d.mercancia_kg_12m_por_hab}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'pasajeros_avion_hab'
```

<Comparativa data={comparativa_internacional} decimales={1} />

<p class="text-xs text-gray-500">Comparison with Eurostat, which counts someone flying between two airports in the same country only once; that is why its figure for Spain is somewhat lower than AENA's. Countries with a lot of tourism (Greece, Portugal, Spain) or that rely on planes to get around inside the country (Norway) come out higher.</p>

## How it has changed since 2004

```sql anual_red
SELECT
    CAST(CAST(anio AS INTEGER) AS VARCHAR) AS periodo,
    CASE WHEN count(*) < 12 THEN 'incompleto' ELSE 'completo' END AS estado,
    sum(pasajeros) AS pasajeros,
    sum(pasajeros) / any_value(poblacion) AS pasajeros_por_hab,
    sum(operaciones) AS operaciones,
    sum(mercancia_t) AS mercancia_t
FROM ${red}
GROUP BY anio
ORDER BY anio
```

{#if Array.from(anual_red ?? []).length > 0}

<BarChart
    data={etiquetar(anual_red, 'estado', (d) => ESTADO[d.estado])}
    x=periodo
    y=pasajeros_por_hab
    series=estado
    sort=false
    yFmt=num1
    colorPalette={['#0f766e', '#99f6e4']}
    legend=true
    yAxisTitle="passengers per person"
    title="Passengers at AENA airports per person"
/>

{/if}

<p class="text-xs text-gray-500">Passengers departing from or arriving at an AENA airport during the year, divided by Spain's population, so that population growth is not mistaken for people flying more. A return trip between two Spanish airports counts four times (two departures and two arrivals); one abroad, twice. The dips are the 2008-2013 crisis (with the collapse of Spanair in 2012) and the 2020-2021 pandemic. The latest year is incomplete.</p>

```sql estacionalidad
-- Pasajeros de cada mes por 1.000 habitantes, últimos cuatro años
SELECT
    mes,
    CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio_texto,
    CAST(mes_num AS INTEGER) AS mes_num,
    pasajeros_por_1000_hab
FROM ${red}
WHERE anio >= (SELECT max(anio) FROM ${red}) - 3
ORDER BY mes_num, anio
```

{#if Array.from(estacionalidad ?? []).length > 0}

<LineChart
    data={etiquetar(estacionalidad, 'mes_nombre', (d) => MESES[d.mes_num - 1])}
    x=mes_nombre
    y=pasajeros_por_1000_hab
    series=anio_texto
    sort=false
    yFmt=num0
    yAxisTitle="passengers per 1,000 people"
    title="Passengers each month: summer carries the year"
    legend=true
/>

{/if}

## Airport by airport

```sql anios
SELECT
    CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio,
    CAST(CAST(anio AS INTEGER) AS VARCHAR) || CASE WHEN bool_or(completo) THEN '' ELSE ' (01-' || lpad(CAST(CAST(max(ultimo_mes) AS INTEGER) AS VARCHAR), 2, '0') || ')' END AS etiqueta
FROM mother.movilidad_aeropuertos_anual
WHERE red = 'espana'
GROUP BY anio
```

<!-- "ultimo" = latest full year: a defaultValue taken from the query reaches the dropdown too late -->
<Dropdown name=anio data={anios} value=anio label=etiqueta title="Year" order="anio desc" defaultValue="ultimo">
    <DropdownOption value="ultimo" valueLabel="Latest full year" />
</Dropdown>

```sql anio_elegido
SELECT CASE WHEN '${inputs.anio.value}' = 'ultimo'
    THEN (SELECT max(anio) FROM mother.movilidad_aeropuertos_anual WHERE red = 'espana' AND completo)
    ELSE TRY_CAST('${inputs.anio.value}' AS INTEGER) END AS anio
```

```sql ranking
SELECT
    puesto,
    aeropuerto,
    iata,
    provincia,
    pasajeros,
    coalesce(var_anual, var_anual_mismos_meses) AS variacion,
    var_2019,
    operaciones,
    pasajeros_por_operacion,
    1 - cuota_nacional AS cuota_internacional,
    mercancia_t
FROM mother.movilidad_aeropuertos_anual
WHERE red = 'espana' AND anio = (SELECT anio FROM ${anio_elegido})
ORDER BY pasajeros DESC NULLS LAST, operaciones DESC
```

<DataTable data={ranking} rows=15 search=true>
    <Column id=puesto title="#" />
    <Column id=aeropuerto title="Airport" />
    <Column id=provincia title="Province" />
    <Column id=pasajeros title="Passengers" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=variacion title="vs. previous year" fmt=pct1 contentType=delta />
    <Column id=var_2019 title="vs. 2019" fmt=pct0 contentType=delta />
    <Column id=operaciones title="Flights" fmt=num0 />
    <Column id=pasajeros_por_operacion title="Passengers per flight" fmt=num0 />
    <Column id=cuota_internacional title="% international" fmt=pct0 />
    <Column id=mercancia_t title="Cargo (t)" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">In an incomplete year, the change is measured against the same months of the previous year. Flights = landings + take-offs, including general aviation and flight schools (which is why Sabadell or Cuatro Vientos have lots of flights and hardly any passengers). % international: passengers on flights to another country according to Eurostat, since 2020 (not yet available for the current year).</p>

## Map

```sql mapa
-- Último año completo con desglose de Eurostat. Un aeropuerto de cada tipo primero (en
-- orden) para fijar los colores de la leyenda; luego el resto, de más a menos pasajeros
-- para que los pequeños queden encima.
WITH a AS (
    SELECT
        aeropuerto, iata, lat, lon, pasajeros,
        cuota_nacional, cuota_ue, cuota_fuera_ue,
        CASE
            WHEN cuota_nacional >= greatest(cuota_ue, cuota_fuera_ue) THEN 1
            WHEN cuota_ue >= cuota_fuera_ue THEN 2
            ELSE 3
        END AS orden
    FROM mother.movilidad_aeropuertos_anual
    WHERE red = 'espana' AND pasajeros > 0 AND cuota_nacional IS NOT NULL
      AND anio = (SELECT max(anio) FROM mother.movilidad_aeropuertos_anual WHERE completo AND cuota_nacional IS NOT NULL)
),
b AS (
    SELECT *,
        row_number() OVER (PARTITION BY orden ORDER BY pasajeros DESC) = 1 AS primera
    FROM a
)
SELECT * FROM b
ORDER BY primera DESC, CASE WHEN primera THEN orden END, pasajeros DESC
```

{#if Array.from(mapa ?? []).length > 0}

<MapaEspana
    data={etiquetar(mapa, 'mercado', (d) => MERCADO[d.orden])}
    lat=lat
    long=lon
    size=pasajeros
    sizeFmt=num0
    maxSize={28}
    value=mercado
    legendType=categorical
    colorPalette={['#f59e0b', '#0f766e', '#7c3aed']}
    opacity={0.75}
    pointName=aeropuerto
    height={600}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Data: AENA and Eurostat"
    tooltip={[
        {id: 'aeropuerto', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pasajeros', title: 'Passengers', fmt: 'num0'},
        {id: 'cuota_nacional', title: 'Domestic flights', fmt: 'pct0'},
        {id: 'cuota_ue', title: 'Rest of the EU', fmt: 'pct0'},
        {id: 'cuota_fuera_ue', title: 'Outside the EU', fmt: 'pct0'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Size by passengers in the latest full year; colour by where most of its passengers come from or are going to (Eurostat). The United Kingdom counts as outside the EU: that is why at Alicante or Tenerife Sur flights from outside the EU almost match European ones.</p>

```sql mercados
-- Los 15 con más pasajeros del último año con desglose de Eurostat
WITH a AS (
    SELECT aeropuerto, pasajeros, cuota_nacional, cuota_ue, cuota_fuera_ue
    FROM mother.movilidad_aeropuertos_anual
    WHERE red = 'espana' AND cuota_nacional IS NOT NULL
      AND anio = (SELECT max(anio) FROM mother.movilidad_aeropuertos_anual WHERE completo AND cuota_nacional IS NOT NULL)
    ORDER BY pasajeros DESC
    LIMIT 15
)
SELECT aeropuerto, pasajeros, 1 AS orden_tipo, cuota_nacional AS cuota FROM a
UNION ALL SELECT aeropuerto, pasajeros, 2, cuota_ue FROM a
UNION ALL SELECT aeropuerto, pasajeros, 3, cuota_fuera_ue FROM a
ORDER BY pasajeros DESC, orden_tipo
```

{#if Array.from(mercados ?? []).length > 0}

<BarChart
    data={etiquetar(mercados, 'tipo', (d) => TIPO[d.orden_tipo])}
    x=aeropuerto
    y=cuota
    series=tipo
    type=stacked100
    swapXY=true
    sort=false
    yFmt=pct0
    colorPalette={['#f59e0b', '#0f766e', '#7c3aed']}
    title="Where their passengers come from and go to"
/>

{/if}

<p class="text-xs text-gray-500">The fifteen airports with the most passengers in the latest full year. Tenerife Norte, Gran Canaria, Sevilla or Bilbao depend mainly on domestic flights (between the islands or to and from the mainland); Palma, Málaga or Valencia, on the rest of the EU; at Madrid, Alicante and Tenerife Sur about four in ten passengers fly outside the EU, the United Kingdom included.</p>

## One airport month by month

```sql lista_aeropuertos
SELECT oaci, aeropuerto || ' (' || coalesce(iata, oaci) || ')' AS etiqueta, sum(pasajeros) AS pasajeros
FROM mother.movilidad_aeropuertos_anual
WHERE red = 'espana' AND anio >= (SELECT max(anio) FROM mother.movilidad_aeropuertos_anual) - 1
GROUP BY oaci, aeropuerto, iata
ORDER BY pasajeros DESC NULLS LAST
```

<Dropdown name=aeropuerto data={lista_aeropuertos} value=oaci label=etiqueta title="Airport" defaultValue="LEMD" />

```sql serie_aeropuerto
SELECT mes, pasajeros, pasajeros_12m / 12 AS media_12_meses
FROM mother.movilidad_aeropuertos_mensual
WHERE oaci = '${inputs.aeropuerto.value}'
ORDER BY mes
```

<LineChart
    data={serie_aeropuerto}
    x=mes
    y={['pasajeros', 'media_12_meses']}
    yFmt=num0
    xFmt="mmm yyyy"
    colorPalette={['#99f6e4', '#0f766e']}
    legend=true
    title="Passengers per month"
/>

```sql anual_aeropuerto
SELECT
    CAST(CAST(anio AS INTEGER) AS VARCHAR) AS periodo,
    CASE WHEN completo THEN 'completo' ELSE 'incompleto' END AS estado,
    pasajeros, operaciones, mercancia_t
FROM mother.movilidad_aeropuertos_anual
WHERE oaci = '${inputs.aeropuerto.value}'
ORDER BY anio
```

{#if Array.from(anual_aeropuerto ?? []).length > 0}

<BarChart
    data={etiquetar(anual_aeropuerto, 'estado', (d) => ESTADO[d.estado])}
    x=periodo
    y=pasajeros
    series=estado
    sort=false
    yFmt=num0
    colorPalette={['#0f766e', '#99f6e4']}
    legend=true
    title="Passengers per year"
/>

{/if}

<p class="text-xs text-gray-500">Absolute figures: an airport serves residents and visitors from many places, so it is not divided by the population of its province. Names that changed over the years (Madrid-Barajas was renamed Adolfo Suárez Madrid-Barajas in 2014) are kept together. Murcia-San Javier closed to commercial traffic in January 2019, when the Región de Murcia airport (Corvera) opened. The latest year is incomplete.</p>

## By region

```sql ccaa
SELECT ccaa, pasajeros, pasajeros_por_hab, operaciones, mercancia_t
FROM mother.movilidad_aeropuertos_ccaa
WHERE anio = (SELECT max(anio) FROM mother.movilidad_aeropuertos_ccaa WHERE completo)
ORDER BY pasajeros_por_hab DESC
```

<BarChart
    data={ccaa}
    x=ccaa
    y=pasajeros_por_hab
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#0f766e"
    title="Passengers per person in each region (latest full year)"
/>

<p class="text-xs text-gray-500">Passengers at each region's AENA airports divided by its population. The Balearic and Canary Islands are several times the average because they receive millions of tourists and because between the islands, and to and from the mainland, almost everything travels by plane. Castilla-La Mancha (Albacete) has hardly any commercial flights; the airports of Ciudad Real, Castellón, Lleida, Teruel and Andorra-La Seu are not run by AENA and are not included here.</p>

## Spain in Europe

```sql europa
SELECT
    puesto, aeropuerto, pais, pasajeros, cuota_internacional, es_espana
FROM mother.movilidad_aeropuertos_europa
WHERE anio = (SELECT max(anio) FROM mother.movilidad_aeropuertos_europa)
ORDER BY puesto
LIMIT 25
```

```sql europa_anio
SELECT max(anio) AS anio FROM mother.movilidad_aeropuertos_europa
```

{#if Array.from(europa ?? []).length > 0}

<BarChart
    data={etiquetar(europa, 'grupo', (d) => GRUPO[d.es_espana])}
    x=aeropuerto
    y=pasajeros
    series=grupo
    swapXY=true
    sort=false
    yFmt=num0
    colorPalette={['#cbd5e1', '#0f766e']}
    title="The 25 European airports with the most passengers in {europa_anio[0]?.anio}"
/>

{/if}

<p class="text-xs text-gray-500">Eurostat, passengers arriving at or departing from each airport. UK airports are missing because the UK stopped sending data to Eurostat after Brexit: with them, London Heathrow would be near the top. Istanbul and Antalya (Turkey) are included.</p>

```sql europa_espana
SELECT puesto, aeropuerto, pasajeros, cuota_internacional
FROM mother.movilidad_aeropuertos_europa
WHERE es_espana AND anio = (SELECT max(anio) FROM mother.movilidad_aeropuertos_europa)
ORDER BY puesto
LIMIT 15
```

<DataTable data={europa_espana} rows=15>
    <Column id=puesto title="Rank in Europe" />
    <Column id=aeropuerto title="Airport" />
    <Column id=pasajeros title="Passengers" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_internacional title="% international" fmt=pct0 />
</DataTable>

## AENA outside Spain

```sql exterior
SELECT
    red,
    count(*) FILTER (WHERE pasajeros > 0) AS aeropuertos,
    sum(pasajeros) AS pasajeros,
    string_agg(aeropuerto, ', ' ORDER BY pasajeros DESC) AS lista
FROM mother.movilidad_aeropuertos_anual
WHERE red <> 'espana' AND anio = (SELECT max(anio) FROM mother.movilidad_aeropuertos_anual WHERE red <> 'espana' AND completo)
GROUP BY red
ORDER BY pasajeros DESC
```

```sql exterior_anio
SELECT max(anio) AS anio FROM mother.movilidad_aeropuertos_anual WHERE red <> 'espana' AND completo
```

AENA is a listed company whose majority shareholder is the Spanish State, through ENAIRE. It also runs airports outside Spain, which its monthly report has included since 2024. They are not counted in any other figure on this page.

{#if Array.from(exterior ?? []).length > 0}

<DataTable data={etiquetar(exterior, 'pais', (d) => PAIS_RED[d.red])}>
    <Column id=pais title="Country" />
    <Column id=aeropuertos title="Airports" />
    <Column id=pasajeros title="Passengers in {exterior_anio[0]?.anio}" fmt=num0 />
    <Column id=lista title="Which ones" wrap=true />
</DataTable>

{/if}

---

## Sources and notes

- **[AENA – Air traffic statistics, monthly reports](https://www.aena.es/es/estadisticas/informes-mensuales.html)**, since January 2004: passengers, aircraft movements and cargo at every airport and heliport in the network. The most recent months are provisional until AENA publishes the final figures.
- **Passengers**: arrivals plus departures, including those who stop over without changing plane (transit). A return trip between two Spanish airports counts four times in the network total. **Movements**: landings plus take-offs, for all kinds of aviation (commercial, private, flight schools, aerial work). **Cargo**: freight and mail, in tonnes.
- Per person: population of Spain or of each region according to the INE's municipal register (the latest available for the current year).
- **[Eurostat – avia_paoa](https://ec.europa.eu/eurostat/databrowser/view/avia_paoa/default/table)**: passengers by European airport and how they split between domestic flights, flights within the EU-27 and flights outside it (with the United Kingdom outside since 2020). **[ttr00012](https://ec.europa.eu/eurostat/databrowser/view/ttr00012/default/table)**: passengers by country, for the per-person comparison.
- Airport coordinates: [OurAirports](https://ourairports.com/) (public domain). Air travellers on domestic flights, alongside rail and bus, are in [Public transport](/en/movilidad/transporte-publico).

<LastRefreshed prefix="Data updated" />
