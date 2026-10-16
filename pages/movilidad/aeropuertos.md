---
title: Aeropuertos
description: "Pasajeros, vuelos y mercancía de los 46 aeropuertos y helipuertos de AENA cada mes desde 2004, por habitante y por comunidad, cuánto tráfico es nacional, europeo o de fuera de la UE, y cómo se comparan Barajas, El Prat o Palma con los grandes aeropuertos de Europa."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';

    // Etiquetas visibles de las gráficas: van aquí y no en el SQL, que es idéntico en
    // todas las traducciones (tools/i18n/comprobar.mjs)
    const ESTADO = { completo: 'Año completo', incompleto: 'Año en curso (incompleto)' };
    const MESES = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    const MERCADO = { 1: 'Sobre todo nacionales', 2: 'Sobre todo al resto de la UE', 3: 'Sobre todo fuera de la UE' };
    const TIPO = { 1: 'Nacionales', 2: 'Resto de la UE', 3: 'Fuera de la UE' };
    const GRUPO = { true: 'España', false: 'Resto de Europa' };
    const PAIS_RED = { reino_unido: 'Reino Unido', brasil: 'Brasil' };
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

# ✈️ Aeropuertos

Cuántos pasajeros, vuelos y mercancías mueven los aeropuertos españoles, según las estadísticas de tráfico que AENA publica cada mes para los 46 aeropuertos y helipuertos de su red.

<Grid cols=4>
    <KpiCard
        title="Pasajeros en los aeropuertos"
        value={ultimo[0]?.pasajeros_12m_por_hab}
        formattedValue="{formatNumber(ultimo[0]?.pasajeros_12m_por_hab, 1)} por habitante"
        period="en los últimos 12 meses · {formatCompact(ultimo[0]?.pasajeros_12m, 1)} pasajeros hasta {ultimo[0]?.mes_texto}"
        change={ultimo[0]?.var_12m != null ? (ultimo[0].var_12m * 100).toFixed(1) : null}
        changePeriod="vs. los 12 meses anteriores"
        direction="neutral"
        source="AENA"
        sparklineData={serie_12m.map(d => ({...d, y: d.pasajeros_12m_por_hab}))}
    />
    <KpiCard
        title="Pasajeros en el último mes"
        value={ultimo[0]?.pasajeros_por_1000_hab}
        formattedValue="{formatNumber(ultimo[0]?.pasajeros_por_1000_hab, 0)} por 1.000 hab."
        period="{formatCompact(ultimo[0]?.pasajeros, 1)} pasajeros en {ultimo[0]?.mes_texto} · {ultimo[0]?.var_2019 > 0 ? '+' : ''}{formatNumber(ultimo[0]?.var_2019 * 100, 0)} % que el mismo mes de 2019"
        change={ultimo[0]?.var_anual != null ? (ultimo[0].var_anual * 100).toFixed(1) : null}
        changePeriod="vs. el mismo mes del año anterior"
        direction="neutral"
        source="AENA"
        sparklineData={serie_mes.map(d => ({...d, y: d.pasajeros_por_1000_hab}))}
    />
    <KpiCard
        title="Vuelos (aterrizajes y despegues)"
        value={ultimo[0]?.vuelos_dia}
        formattedValue="{formatNumber(ultimo[0]?.vuelos_dia, 0)} al día"
        period="media de los últimos 12 meses · {formatNumber(ultimo[0]?.pasajeros_por_operacion, 0)} pasajeros por vuelo en {ultimo[0]?.mes_texto}"
        source="AENA"
        sparklineData={serie_12m.map(d => ({...d, y: d.operaciones_12m / 365}))}
    />
    <KpiCard
        title="Mercancía por avión"
        value={ultimo[0]?.mercancia_kg_12m_por_hab}
        formattedValue="{formatNumber(ultimo[0]?.mercancia_kg_12m_por_hab, 1)} kg por habitante"
        period="en los últimos 12 meses · {formatNumber(ultimo[0]?.mercancia_t_12m / 1000, 0)} miles de toneladas"
        source="AENA"
        sparklineData={serie_12m.map(d => ({...d, y: d.mercancia_kg_12m_por_hab}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'pasajeros_avion_hab'
```

<Comparativa data={comparativa_internacional} decimales={1} />

<p class="text-xs text-gray-500">Comparación con Eurostat, que cuenta una sola vez a quien vuela entre dos aeropuertos del mismo país; por eso su cifra para España es algo menor que la de AENA. Los países con mucho turismo (Grecia, Portugal, España) o que dependen del avión para moverse por dentro (Noruega) salen más altos.</p>

## Cómo ha cambiado desde 2004

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
    yAxisTitle="pasajeros por habitante"
    title="Pasajeros de los aeropuertos de AENA por habitante"
/>

{/if}

<p class="text-xs text-gray-500">Pasajeros que salen o llegan en un aeropuerto de AENA en el año, divididos por la población de España, para que el crecimiento de la población no se confunda con un mayor uso del avión. Un viaje de ida y vuelta entre dos aeropuertos españoles suma cuatro (dos salidas y dos llegadas); uno al extranjero, dos. Las caídas son la crisis de 2008-2013 (con el cierre de Spanair en 2012) y la pandemia de 2020-2021. El último año está incompleto.</p>

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
    yAxisTitle="pasajeros por 1.000 habitantes"
    title="Pasajeros de cada mes: el verano tira del año"
    legend=true
/>

{/if}

## Los aeropuertos uno a uno

```sql anios
SELECT
    CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio,
    CAST(CAST(anio AS INTEGER) AS VARCHAR) || CASE WHEN bool_or(completo) THEN '' ELSE ' (01-' || lpad(CAST(CAST(max(ultimo_mes) AS INTEGER) AS VARCHAR), 2, '0') || ')' END AS etiqueta
FROM mother.movilidad_aeropuertos_anual
WHERE red = 'espana'
GROUP BY anio
```

<!-- «ultimo» = último año completo: un defaultValue sacado de la consulta llega tarde al desplegable -->
<Dropdown name=anio data={anios} value=anio label=etiqueta title="Año" order="anio desc" defaultValue="ultimo">
    <DropdownOption value="ultimo" valueLabel="Último año completo" />
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
    <Column id=aeropuerto title="Aeropuerto" />
    <Column id=provincia title="Provincia" />
    <Column id=pasajeros title="Pasajeros" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=variacion title="vs. año anterior" fmt=pct1 contentType=delta />
    <Column id=var_2019 title="vs. 2019" fmt=pct0 contentType=delta />
    <Column id=operaciones title="Vuelos" fmt=num0 />
    <Column id=pasajeros_por_operacion title="Pasajeros por vuelo" fmt=num0 />
    <Column id=cuota_internacional title="% internacional" fmt=pct0 />
    <Column id=mercancia_t title="Mercancía (t)" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">En un año incompleto, la variación compara con los mismos meses del año anterior. Vuelos = aterrizajes + despegues, también de aviación general y escuelas (por eso Sabadell o Cuatro Vientos tienen muchos vuelos y casi ningún pasajero). % internacional: pasajeros de vuelos a otro país según Eurostat, desde 2020 (el año en curso aún no lo tiene).</p>

## Mapa

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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Datos: AENA y Eurostat"
    tooltip={[
        {id: 'aeropuerto', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pasajeros', title: 'Pasajeros', fmt: 'num0'},
        {id: 'cuota_nacional', title: 'Vuelos nacionales', fmt: 'pct0'},
        {id: 'cuota_ue', title: 'Resto de la UE', fmt: 'pct0'},
        {id: 'cuota_fuera_ue', title: 'Fuera de la UE', fmt: 'pct0'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Tamaño según los pasajeros del último año completo; color según de dónde viene o adónde va la mayor parte de sus pasajeros (Eurostat). El Reino Unido cuenta fuera de la UE: por eso en Alicante o Tenerife Sur los vuelos de fuera de la UE casi igualan a los europeos.</p>

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
    title="De dónde vienen y adónde van sus pasajeros"
/>

{/if}

<p class="text-xs text-gray-500">Los quince aeropuertos con más pasajeros en el último año completo. Tenerife Norte, Gran Canaria, Sevilla o Bilbao viven sobre todo del vuelo nacional (entre islas o con la península); Palma, Málaga o Valencia, del resto de la UE; en Madrid, Alicante y Tenerife Sur unos cuatro de cada diez pasajeros vuelan fuera de la UE, Reino Unido incluido.</p>

## Un aeropuerto mes a mes

```sql lista_aeropuertos
SELECT oaci, aeropuerto || ' (' || coalesce(iata, oaci) || ')' AS etiqueta, sum(pasajeros) AS pasajeros
FROM mother.movilidad_aeropuertos_anual
WHERE red = 'espana' AND anio >= (SELECT max(anio) FROM mother.movilidad_aeropuertos_anual) - 1
GROUP BY oaci, aeropuerto, iata
ORDER BY pasajeros DESC NULLS LAST
```

<Dropdown name=aeropuerto data={lista_aeropuertos} value=oaci label=etiqueta title="Aeropuerto" defaultValue="LEMD" />

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
    title="Pasajeros al mes"
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
    title="Pasajeros por año"
/>

{/if}

<p class="text-xs text-gray-500">Cifras absolutas: un aeropuerto da servicio a residentes y a visitantes de muchos sitios, así que no se divide por la población de su provincia. Los nombres que cambiaron con los años (Madrid-Barajas pasó a llamarse Adolfo Suárez Madrid-Barajas en 2014) van juntos. Murcia-San Javier cerró al tráfico comercial en enero de 2019, cuando abrió el aeropuerto de la Región de Murcia (Corvera). El último año está incompleto.</p>

## Por comunidad autónoma

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
    title="Pasajeros por habitante de la comunidad (último año completo)"
/>

<p class="text-xs text-gray-500">Pasajeros de los aeropuertos de AENA de cada comunidad divididos por su población. Baleares y Canarias multiplican varias veces la media porque reciben millones de turistas y porque entre islas, y con la península, casi todo se mueve en avión. Castilla-La Mancha (Albacete) apenas tiene vuelos comerciales; los aeropuertos de Ciudad Real, Castellón, Lleida, Teruel y Andorra-La Seu no son de AENA y no están aquí.</p>

## España en Europa

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
    title="Los 25 aeropuertos europeos con más pasajeros en {europa_anio[0]?.anio}"
/>

{/if}

<p class="text-xs text-gray-500">Eurostat, pasajeros que llegan o salen de cada aeropuerto. Faltan los del Reino Unido, que dejó de enviar datos a Eurostat tras el Brexit: con ellos, Londres-Heathrow estaría entre los primeros. Estambul y Antalya (Turquía) sí están.</p>

```sql europa_espana
SELECT puesto, aeropuerto, pasajeros, cuota_internacional
FROM mother.movilidad_aeropuertos_europa
WHERE es_espana AND anio = (SELECT max(anio) FROM mother.movilidad_aeropuertos_europa)
ORDER BY puesto
LIMIT 15
```

<DataTable data={europa_espana} rows=15>
    <Column id=puesto title="Puesto en Europa" />
    <Column id=aeropuerto title="Aeropuerto" />
    <Column id=pasajeros title="Pasajeros" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_internacional title="% internacional" fmt=pct0 />
</DataTable>

## AENA fuera de España

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

AENA es una empresa que cotiza en bolsa y cuyo accionista mayoritario es el Estado, a través de ENAIRE. También gestiona aeropuertos fuera de España, que su informe mensual incluye desde 2024. No cuentan en ninguna otra cifra de esta página.

{#if Array.from(exterior ?? []).length > 0}

<DataTable data={etiquetar(exterior, 'pais', (d) => PAIS_RED[d.red])}>
    <Column id=pais title="País" />
    <Column id=aeropuertos title="Aeropuertos" />
    <Column id=pasajeros title="Pasajeros en {exterior_anio[0]?.anio}" fmt=num0 />
    <Column id=lista title="Cuáles" wrap=true />
</DataTable>

{/if}

---

## Fuentes y notas

- **[AENA – Estadísticas de tráfico aéreo, informes mensuales](https://www.aena.es/es/estadisticas/informes-mensuales.html)**, desde enero de 2004: pasajeros, operaciones y mercancía de cada aeropuerto y helipuerto de la red. Los meses más recientes son provisionales hasta que AENA publica los definitivos.
- **Pasajeros**: los que llegan más los que salen, incluidos los que hacen escala sin cambiar de avión (tránsito). Un viaje de ida y vuelta entre dos aeropuertos españoles cuenta cuatro veces en el total de la red. **Operaciones**: aterrizajes más despegues, de todo tipo de aviación (comercial, privada, escuelas, trabajos aéreos). **Mercancía**: carga y correo, en toneladas.
- Por habitante: población de España o de cada comunidad según el padrón del INE (el último disponible para el año en curso).
- **[Eurostat – avia_paoa](https://ec.europa.eu/eurostat/databrowser/view/avia_paoa/default/table)**: pasajeros por aeropuerto europeo y su reparto entre vuelos nacionales, dentro de la UE-27 y fuera de ella (con el Reino Unido fuera desde 2020). **[ttr00012](https://ec.europa.eu/eurostat/databrowser/view/ttr00012/default/table)**: pasajeros por país, para la comparación por habitante.
- Coordenadas de los aeropuertos: [OurAirports](https://ourairports.com/) (dominio público). Los viajeros de avión en vuelos interiores junto al tren y el autobús están en [Transporte público](/movilidad/transporte-publico).

<LastRefreshed prefix="Datos actualizados" />
