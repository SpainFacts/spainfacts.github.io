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
    yFmt=pct0
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

## El transporte: poca energía eléctrica, muchos viajeros

```sql transporte_energia
WITH t AS (
    SELECT
        max(anio) AS anio,
        max(total) FILTER (WHERE cod_sector = 'FC_TRA_E') AS total,
        max(electricidad) FILTER (WHERE cod_sector = 'FC_TRA_E') AS electricidad,
        max(total) FILTER (WHERE cod_sector = 'FC_TRA_ROAD_E') AS carretera,
        max(electricidad) FILTER (WHERE cod_sector = 'FC_TRA_ROAD_E') AS carretera_elec,
        max(total) FILTER (WHERE cod_sector = 'FC_TRA_RAIL_E') AS ferrocarril,
        max(electricidad) FILTER (WHERE cod_sector = 'FC_TRA_RAIL_E') AS ferrocarril_elec
    FROM mother.electrificacion_sectores
    WHERE anio = (SELECT max(anio) FROM mother.electrificacion_sectores)
      AND cod_sector IN ('FC_TRA_E', 'FC_TRA_ROAD_E', 'FC_TRA_RAIL_E')
)
SELECT anio, 1 AS orden, 'Carretera' AS modo, 'Electricidad' AS energia, carretera_elec / total AS cuota FROM t
UNION ALL SELECT anio, 1, 'Carretera', 'Gasóleo, gasolina y otras', (carretera - carretera_elec) / total FROM t
UNION ALL SELECT anio, 2, 'Avión, barco y otros', 'Electricidad', (electricidad - carretera_elec - ferrocarril_elec) / total FROM t
UNION ALL SELECT anio, 2, 'Avión, barco y otros', 'Gasóleo, gasolina y otras', ((total - carretera - ferrocarril) - (electricidad - carretera_elec - ferrocarril_elec)) / total FROM t
UNION ALL SELECT anio, 3, 'Ferrocarril (tren, metro y tranvía)', 'Electricidad', ferrocarril_elec / total FROM t
UNION ALL SELECT anio, 3, 'Ferrocarril (tren, metro y tranvía)', 'Gasóleo, gasolina y otras', (ferrocarril - ferrocarril_elec) / total FROM t
ORDER BY orden, energia
```

```sql transporte_resumen
SELECT
    max(anio) AS anio,
    100 * sum(cuota) FILTER (WHERE orden = 3) AS ferrocarril_pct,
    100 * sum(cuota) FILTER (WHERE orden = 1) AS carretera_pct,
    100 * sum(cuota) FILTER (WHERE energia = 'Electricidad') AS electricidad_pct,
    100 * sum(cuota) FILTER (WHERE orden = 3 AND energia = 'Electricidad') / sum(cuota) FILTER (WHERE orden = 3) AS ferrocarril_elec_pct
FROM ${transporte_energia}
```

```sql reparto_modal
SELECT indicador_id, cod_pais, pais, anio, valor
FROM mother.internacional_europa
WHERE indicador_id IN ('tren_viajeros_pct', 'tren_mercancias_pct', 'electrificacion_transporte')
  AND cod_pais IN ('ES', 'EU27_2020')
ORDER BY anio
```

```sql reparto_ultimo
SELECT
    max(anio) FILTER (WHERE indicador_id = 'tren_viajeros_pct' AND cod_pais = 'ES') AS anio_viajeros,
    arg_max(valor, anio) FILTER (WHERE indicador_id = 'tren_viajeros_pct' AND cod_pais = 'ES') AS viajeros_es,
    arg_max(valor, anio) FILTER (WHERE indicador_id = 'tren_viajeros_pct' AND cod_pais = 'EU27_2020') AS viajeros_ue,
    max(anio) FILTER (WHERE indicador_id = 'tren_mercancias_pct' AND cod_pais = 'ES') AS anio_mercancias,
    arg_max(valor, anio) FILTER (WHERE indicador_id = 'tren_mercancias_pct' AND cod_pais = 'ES') AS mercancias_es,
    arg_max(valor, anio) FILTER (WHERE indicador_id = 'tren_mercancias_pct' AND cod_pais = 'EU27_2020') AS mercancias_ue
FROM ${reparto_modal}
```

```sql viajes_publico
WITH completos AS (
    SELECT anio FROM mother.movilidad_transporte_modos
    WHERE clave = 'total'
    GROUP BY anio HAVING count(DISTINCT mes) = 12
),
anual AS (
    SELECT
        m.anio,
        CASE
            WHEN m.clave = 'metro' THEN 'Metro'
            WHEN m.clave IN ('cercanias', 'media_distancia', 'alta_velocidad', 'larga_distancia_convencional') THEN 'Tren (Cercanías, media y larga distancia)'
            WHEN m.clave = 'autobus_urbano' THEN 'Autobús urbano'
            WHEN m.clave LIKE 'autobus_%' THEN 'Autobús interurbano'
            WHEN m.clave LIKE 'aereo_%' OR m.clave = 'maritimo' THEN 'Avión y barco (interior)'
            ELSE 'Autobús escolar, de empresa y discrecional'
        END AS modo,
        m.clave IN ('metro', 'cercanias', 'media_distancia', 'alta_velocidad', 'larga_distancia_convencional') AS sobre_railes,
        sum(m.viajeros) AS viajes,
        avg(m.poblacion) AS poblacion
    FROM mother.movilidad_transporte_modos m
    JOIN completos c ON c.anio = m.anio
    WHERE m.es_hoja
    GROUP BY ALL
)
SELECT anio, modo, sobre_railes, viajes, viajes / poblacion AS viajes_hab
FROM anual
ORDER BY anio, viajes DESC
```

```sql viajes_ultimo
SELECT
    anio,
    modo,
    CASE WHEN sobre_railes THEN 'Sobre raíles' ELSE 'Por carretera, aire o mar' END AS tipo,
    viajes,
    viajes_hab,
    viajes / sum(viajes) OVER () AS cuota
FROM ${viajes_publico}
WHERE anio = (SELECT max(anio) FROM ${viajes_publico})
ORDER BY viajes DESC
```

```sql viajes_resumen
SELECT
    anio,
    sum(viajes) FILTER (WHERE modo = 'Metro') AS metro,
    sum(viajes_hab) FILTER (WHERE modo = 'Metro') AS metro_hab,
    sum(viajes) FILTER (WHERE modo LIKE 'Tren%') AS tren,
    100 * sum(viajes) FILTER (WHERE sobre_railes) / sum(viajes) AS railes_pct
FROM ${viajes_publico}
GROUP BY anio
ORDER BY anio
```

El transporte es el sector menos electrificado: {#if transporte_resumen.length > 0}solo un {formatNumber(transporte_resumen[0].electricidad_pct, 1)} % de la energía que gasta es electricidad{/if}. Puede parecer poco para un país con metro en siete ciudades, Cercanías y una de las mayores redes de alta velocidad del mundo, pero la cifra mide **energía, no viajes**, y el tren eléctrico es tan eficiente que gasta muy poca para el trabajo que hace.

<Grid cols=4>
    <KpiCard
        title="Energía del transporte que gasta el ferrocarril"
        value={transporte_resumen[0]?.ferrocarril_pct}
        formattedValue="{formatNumber(transporte_resumen[0]?.ferrocarril_pct, 1)} %"
        period="tren, metro y tranvía · {transporte_resumen[0]?.anio}"
        source="Eurostat"
    />
    <KpiCard
        title="Viajeros-km que van en tren"
        value={reparto_ultimo[0]?.viajeros_es}
        formattedValue="{formatNumber(reparto_ultimo[0]?.viajeros_es, 1)} %"
        period="frente a coche y autobús, sin contar el metro · UE: {formatNumber(reparto_ultimo[0]?.viajeros_ue, 1)} % · {reparto_ultimo[0]?.anio_viajeros}"
        source="Eurostat"
        sparklineData={reparto_modal.filter(d => d.indicador_id === 'tren_viajeros_pct' && d.cod_pais === 'ES').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Mercancías que van en tren"
        value={reparto_ultimo[0]?.mercancias_es}
        formattedValue="{formatNumber(reparto_ultimo[0]?.mercancias_es, 1)} %"
        period="de las toneladas-km por tierra · UE: {formatNumber(reparto_ultimo[0]?.mercancias_ue, 1)} % · {reparto_ultimo[0]?.anio_mercancias}"
        direction="positive-up"
        source="Eurostat"
        sparklineData={reparto_modal.filter(d => d.indicador_id === 'tren_mercancias_pct' && d.cod_pais === 'ES').map(d => ({...d, y: d.valor}))}
    />
    <KpiCard
        title="Viajes en metro por habitante"
        value={viajes_resumen[viajes_resumen.length - 1]?.metro_hab}
        formattedValue="{formatNumber(viajes_resumen[viajes_resumen.length - 1]?.metro_hab, 0)}"
        period="al año · {formatNumber(viajes_resumen[viajes_resumen.length - 1]?.metro / 1e6, 0)} millones de viajes en {viajes_resumen[viajes_resumen.length - 1]?.anio}"
        source="INE"
        sparklineData={viajes_resumen.map(d => ({...d, y: d.metro_hab}))}
        href="/movilidad/ferrocarril"
    />
</Grid>

<BarChart
    data={transporte_energia}
    x=modo
    y=cuota
    series=energia
    swapXY=true
    type=stacked
    sort=false
    yFmt=pct0
    colorPalette={['#1d4ed8', '#78716c']}
    title="En qué se va la energía del transporte ({transporte_energia[0]?.anio})"
/>

<p class="text-xs text-gray-500">Consumo final de energía del transporte dentro de España (Eurostat). «Ferrocarril» incluye trenes de viajeros y de mercancías, metro y tranvía. «Avión, barco y otros» son los vuelos y barcos nacionales y los oleoductos y gasoductos; los vuelos y barcos internacionales no están en esta cifra. Las bombas de los oleoductos y gasoductos son eléctricas: de ahí la pequeña parte azul de esa barra.</p>

### Por qué pesa tan poco: la eficiencia del tren eléctrico

Las cifras lo dejan claro. {#if transporte_resumen.length > 0 && reparto_ultimo.length > 0}El ferrocarril hace el **{formatNumber(reparto_ultimo[0].viajeros_es, 1)} % de los viajeros-km** por tierra y el **{formatNumber(reparto_ultimo[0].mercancias_es, 1)} % de las toneladas-km** con solo el **{formatNumber(transporte_resumen[0].ferrocarril_pct, 1)} % de la energía** del transporte, y eso que esa energía incluye también el metro y el tranvía, que no están en los viajeros-km. Del ferrocarril, un {formatNumber(transporte_resumen[0].ferrocarril_elec_pct, 0)} % de la energía ya es electricidad.{/if} Hay dos motivos. El primero es el motor: uno eléctrico convierte en movimiento casi toda la energía que recibe, mientras que uno de gasolina o gasóleo pierde la mayor parte en calor. El segundo es la rueda de acero sobre el carril, que roza mucho menos que un neumático sobre el asfalto, y un tren lleva a cientos de personas a la vez. Por eso pasar viajeros y mercancías de la carretera al tren reduce el consumo de energía mucho más de lo que sube el consumo de electricidad.

Lo contrario también se cumple: la electrificación del transporte está estancada porque {#if transporte_resumen.length > 0}el {formatNumber(transporte_resumen[0].carretera_pct, 0)} %{:else}casi toda{/if} de su energía se gasta en carretera, y ahí el coche eléctrico todavía es una parte muy pequeña del parque y los camiones casi no han empezado. En mercancías, España está muy por debajo de Europa: casi todo va en camión.

```sql transporte_paises
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = '${inputs.transporte_indicador}'
```

<ButtonGroup name=transporte_indicador title="Comparar con Europa">
    <ButtonGroupItem valueLabel="Viajeros en tren" value="tren_viajeros_pct" default />
    <ButtonGroupItem valueLabel="Mercancías en tren" value="tren_mercancias_pct" />
    <ButtonGroupItem valueLabel="Electricidad en el transporte" value="electrificacion_transporte" />
</ButtonGroup>

<Comparativa data={transporte_paises} />

<LineChart
    data={reparto_modal.filter(d => d.indicador_id === inputs.transporte_indicador)}
    x=anio
    y=valor
    series=pais
    yFmt='0.0"%"'
    xFmt="####"
    legend=true
    colorPalette={['#c2410c', '#94a3b8']}
    title="España frente a la UE"
/>

<p class="text-xs text-gray-500">Viajeros: reparto de los viajeros-km entre coche, autobús y tren. Mercancías: reparto de las toneladas-km entre carretera, tren y vías navegables (en España no hay transporte fluvial de mercancías). Eurostat no incluye el metro ni el tranvía en el reparto de viajeros porque no hay datos armonizados de los kilómetros que recorren sus viajeros, y tampoco los aviones.</p>

### El metro sí cuenta en los viajes

Los viajeros-km de Eurostat dejan fuera el metro, pero el INE cuenta cuántos viajes se hacen en cada medio de transporte público. {#if viajes_resumen.length > 0}En {viajes_resumen[viajes_resumen.length - 1].anio} el metro hizo {formatNumber(viajes_resumen[viajes_resumen.length - 1].metro / 1e6, 0)} millones de viajes, {#if viajes_resumen[viajes_resumen.length - 1].metro > viajes_resumen[viajes_resumen.length - 1].tren}más que todos los trenes juntos ({formatNumber(viajes_resumen[viajes_resumen.length - 1].tren / 1e6, 0)} millones){:else}frente a {formatNumber(viajes_resumen[viajes_resumen.length - 1].tren / 1e6, 0)} millones en tren{/if}, y {formatNumber(viajes_resumen[viajes_resumen.length - 1].railes_pct, 0)} de cada 100 viajes en transporte público fueron sobre raíles.{/if}

<BarChart
    data={viajes_ultimo}
    x=modo
    y=viajes_hab
    series=tipo
    swapXY=true
    sort=false
    yFmt=num0
    colorPalette={['#1d4ed8', '#94a3b8']}
    title="Viajes en transporte público por habitante y año ({viajes_ultimo[0]?.anio})"
/>

<p class="text-xs text-gray-500">Estadística de Transporte de Viajeros del INE: viajes (no kilómetros) en metro, autobús, tren, avión y barco dentro de España, divididos por la población. Un viaje en metro es mucho más corto que uno en AVE, así que estas cifras no se pueden sumar a los viajeros-km de arriba. El tranvía no tiene una partida propia en esta estadística. «Sobre raíles» no siempre es eléctrico: algunas líneas de media distancia siguen siendo de gasóleo.</p>

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
    yFmt=pct0
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
SELECT
    cod AS cod_prov, nombre AS provincia, viviendas,
    cuota_electricidad_pct, cuota_gas_pct, cuota_petroleo_pct,
    100.0 * otros / nullif(viviendas, 0) AS cuota_otros_pct
FROM mother.electrificacion_calefaccion_provincia
WHERE nivel = 'provincia'
ORDER BY ${inputs.calefaccion_tec} DESC
```

```sql espana_viv
SELECT *, 100.0 * otros / nullif(viviendas, 0) AS cuota_otros_pct
FROM mother.electrificacion_calefaccion_provincia WHERE nivel = 'pais'
```

### Con qué se calientan las viviendas, por provincia

<ButtonGroup name=calefaccion_tec title="Combustible">
    <ButtonGroupItem valueLabel="Electricidad" value="cuota_electricidad_pct" default />
    <ButtonGroupItem valueLabel="Gas natural" value="cuota_gas_pct" />
    <ButtonGroupItem valueLabel="Gasóleo y derivados" value="cuota_petroleo_pct" />
    <ButtonGroupItem valueLabel="Biomasa y otros" value="cuota_otros_pct" />
</ButtonGroup>

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value={inputs.calefaccion_tec}
    valueFmt='0"%"'
    colorPalette={({
        cuota_gas_pct: ['#fffbeb', '#fcd34d', '#d97706'],
        cuota_petroleo_pct: ['#fafaf9', '#a8a29e', '#57534e'],
        cuota_otros_pct: ['#f7fee7', '#a3e635', '#4d7c0f']
    })[inputs.calefaccion_tec] ?? ['#fff7ed', '#93c5fd', '#1d4ed8']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE (ECEPOV 2021)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_electricidad_pct', title: 'Electricidad', fmt: '0"%"'},
        {id: 'cuota_gas_pct', title: 'Gas natural', fmt: '0"%"'},
        {id: 'cuota_petroleo_pct', title: 'Gasóleo y derivados', fmt: '0"%"'},
        {id: 'cuota_otros_pct', title: 'Biomasa y otros', fmt: '0"%"'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Provincia" />
    <Column id=viviendas title="Viviendas con calefacción" fmt=num0 />
    <Column id=cuota_electricidad_pct title="Electricidad" fmt='0"%"' contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_gas_pct title="Gas natural" fmt='0"%"' contentType=bar barColor="#fde68a" />
    <Column id=cuota_petroleo_pct title="Gasóleo y derivados" fmt='0"%"' contentType=bar barColor="#d6d3d1" />
    <Column id=cuota_otros_pct title="Biomasa y otros" fmt='0"%"' contentType=bar barColor="#d9f99d" />
</DataTable>

<p class="text-xs text-gray-500">{#if espana_viv.length > 0}En España, de cada 100 viviendas con calefacción {formatNumber(espana_viv[0].cuota_electricidad_pct, 0)} la tienen eléctrica, {formatNumber(espana_viv[0].cuota_gas_pct, 0)} de gas natural, {formatNumber(espana_viv[0].cuota_petroleo_pct, 0)} de gasóleo o derivados y {formatNumber(espana_viv[0].cuota_otros_pct, 0)} de biomasa u otros. {/if}En el sur y en Canarias, con inviernos suaves, predominan los radiadores eléctricos y el aire acondicionado; en el interior norte, con inviernos fríos y largos, el gas natural y el gasóleo; y en la España rural más fría (Ourense, Lugo, Soria, Cuenca) y en Jaén, donde se quema mucho hueso de aceituna, la biomasa. Encuesta de Características Esenciales de la Población y las Viviendas 2021 del INE (muestral): cuenta viviendas, no energía, y solo pregunta por cuatro opciones. «Biomasa y otros» es la respuesta «Otros» del INE, que en la práctica es sobre todo leña, pellets y hueso de aceituna, pero incluye también carbón y solar. La bomba de calor no se puede separar por provincia: la encuesta la cuenta dentro de «Electricidad» junto con radiadores y aire acondicionado, y la cifra de bombas de calor de más arriba (Eurostat) solo existe para toda España.</p>

---

## Fuentes y notas

- **[Eurostat – Balances energéticos completos (nrg_bal_c)](https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table)**: consumo final de energía por sector, rama industrial y combustible, 1990-último año. La comparación con otros países usa la misma tabla y la misma definición (electricidad entre consumo final de energía, uso energético) y solo cubre países europeos; Noruega y Suecia aparecen como referencia (borde discontinuo) por ser las economías más electrificadas de Europa.
- **[Eurostat – Reparto modal del transporte de viajeros (tran_hv_psmod)](https://ec.europa.eu/eurostat/databrowser/view/tran_hv_psmod/default/table)** y **[de mercancías (tran_hv_frmod)](https://ec.europa.eu/eurostat/databrowser/view/tran_hv_frmod/default/table)**: % de los viajeros-km en coche, autobús y tren y de las toneladas-km por carretera, tren y vías navegables. No incluyen metro, tranvía ni avión.
- **[INE – Estadística de Transporte de Viajeros, tabla 20239](https://www.ine.es/jaxiT3/Tabla.htm?t=20239)**: viajes mensuales en metro, autobús urbano e interurbano, tren, avión y barco. Cuenta viajes, no kilómetros.
- **[Eurostat – Consumo de energía de los hogares por uso (nrg_d_hhq)](https://ec.europa.eu/eurostat/databrowser/view/nrg_d_hhq/default/table)**: calefacción, agua caliente, cocina, refrigeración e iluminación por combustible, desde 2010 (en España lo elabora el IDAE).
- **[Eurostat – Bombas de calor (nrg_inf_hptc)](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_hptc/default/table)**: potencia térmica por tecnología.
- **[INE – ECEPOV 2021, tabla 56784](https://www.ine.es/jaxi/Tabla.htm?tpx=56784)**: viviendas principales con calefacción por tipo de combustible y provincia.
- No hay estadística oficial abierta del sistema de calefacción de los edificios públicos: los registros de certificados energéticos de las comunidades no recogen el combustible.

<LastRefreshed prefix="Datos actualizados" />
