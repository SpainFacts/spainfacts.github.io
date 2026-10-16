---
title: Aeroportos
description: "Pasaxeiros, voos e mercadorías dos 46 aeroportos e heliportos de AENA cada mes desde 2004, por habitante e por comunidade, canto tráfico é nacional, europeo ou de fóra da UE, e como se comparan Barajas, El Prat ou Palma cos grandes aeroportos de Europa."
i18n_origen: 1fc33e04e32f
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';

    // Etiquetas visibles das gráficas: van aquí e non no SQL, que é idéntico en
    // todas as traducións (tools/i18n/comprobar.mjs)
    const ESTADO = { completo: 'Ano completo', incompleto: 'Ano en curso (incompleto)' };
    const MESES = ['xan', 'feb', 'mar', 'abr', 'mai', 'xuñ', 'xul', 'ago', 'set', 'out', 'nov', 'dec'];
    const MERCADO = { 1: 'Sobre todo nacionais', 2: 'Sobre todo ao resto da UE', 3: 'Sobre todo fóra da UE' };
    const TIPO = { 1: 'Nacionais', 2: 'Resto da UE', 3: 'Fóra da UE' };
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

# ✈️ Aeroportos

Cantos pasaxeiros, voos e mercadorías moven os aeroportos españois, segundo as estatísticas de tráfico que AENA publica cada mes para os 46 aeroportos e heliportos da súa rede.

<Grid cols=4>
    <KpiCard
        title="Pasaxeiros nos aeroportos"
        value={ultimo[0]?.pasajeros_12m_por_hab}
        formattedValue="{formatNumber(ultimo[0]?.pasajeros_12m_por_hab, 1)} por habitante"
        period="nos últimos 12 meses · {formatCompact(ultimo[0]?.pasajeros_12m, 1)} pasaxeiros ata {ultimo[0]?.mes_texto}"
        change={ultimo[0]?.var_12m != null ? (ultimo[0].var_12m * 100).toFixed(1) : null}
        changePeriod="fronte aos 12 meses anteriores"
        direction="neutral"
        source="AENA"
        sparklineData={serie_12m.map(d => ({...d, y: d.pasajeros_12m_por_hab}))}
    />
    <KpiCard
        title="Pasaxeiros no último mes"
        value={ultimo[0]?.pasajeros_por_1000_hab}
        formattedValue="{formatNumber(ultimo[0]?.pasajeros_por_1000_hab, 0)} por 1.000 hab."
        period="{formatCompact(ultimo[0]?.pasajeros, 1)} pasaxeiros en {ultimo[0]?.mes_texto} · {ultimo[0]?.var_2019 > 0 ? '+' : ''}{formatNumber(ultimo[0]?.var_2019 * 100, 0)} % que o mesmo mes de 2019"
        change={ultimo[0]?.var_anual != null ? (ultimo[0].var_anual * 100).toFixed(1) : null}
        changePeriod="fronte ao mesmo mes do ano anterior"
        direction="neutral"
        source="AENA"
        sparklineData={serie_mes.map(d => ({...d, y: d.pasajeros_por_1000_hab}))}
    />
    <KpiCard
        title="Voos (aterraxes e despegues)"
        value={ultimo[0]?.vuelos_dia}
        formattedValue="{formatNumber(ultimo[0]?.vuelos_dia, 0)} ao día"
        period="media dos últimos 12 meses · {formatNumber(ultimo[0]?.pasajeros_por_operacion, 0)} pasaxeiros por voo en {ultimo[0]?.mes_texto}"
        source="AENA"
        sparklineData={serie_12m.map(d => ({...d, y: d.operaciones_12m / 365}))}
    />
    <KpiCard
        title="Mercadorías por avión"
        value={ultimo[0]?.mercancia_kg_12m_por_hab}
        formattedValue="{formatNumber(ultimo[0]?.mercancia_kg_12m_por_hab, 1)} kg por habitante"
        period="nos últimos 12 meses · {formatNumber(ultimo[0]?.mercancia_t_12m / 1000, 0)} miles de toneladas"
        source="AENA"
        sparklineData={serie_12m.map(d => ({...d, y: d.mercancia_kg_12m_por_hab}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'pasajeros_avion_hab'
```

<Comparativa data={comparativa_internacional} decimales={1} />

<p class="text-xs text-gray-500">Comparación con Eurostat, que conta unha soa vez a quen voa entre dous aeroportos do mesmo país; por iso a súa cifra para España é algo menor ca a de AENA. Os países con moito turismo (Grecia, Portugal, España) ou que dependen do avión para moverse por dentro (Noruega) saen máis altos.</p>

## Como cambiou desde 2004

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
    yAxisTitle="pasaxeiros por habitante"
    title="Pasaxeiros dos aeroportos de AENA por habitante"
/>

{/if}

<p class="text-xs text-gray-500">Pasaxeiros que saen ou chegan nun aeroporto de AENA no ano, divididos pola poboación de España, para que o crecemento da poboación non se confunda cun maior uso do avión. Unha viaxe de ida e volta entre dous aeroportos españois suma catro (dúas saídas e dúas chegadas); unha ao estranxeiro, dúas. As caídas son a crise de 2008-2013 (co peche de Spanair en 2012) e a pandemia de 2020-2021. O último ano está incompleto.</p>

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
    yAxisTitle="pasaxeiros por 1.000 habitantes"
    title="Pasaxeiros de cada mes: o verán tira do ano"
    legend=true
/>

{/if}

## Os aeroportos un a un

```sql anios
SELECT
    CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio,
    CAST(CAST(anio AS INTEGER) AS VARCHAR) || CASE WHEN bool_or(completo) THEN '' ELSE ' (01-' || lpad(CAST(CAST(max(ultimo_mes) AS INTEGER) AS VARCHAR), 2, '0') || ')' END AS etiqueta
FROM mother.movilidad_aeropuertos_anual
WHERE red = 'espana'
GROUP BY anio
```

<!-- «ultimo» = último ano completo: un defaultValue sacado da consulta chega tarde ao despregable -->
<Dropdown name=anio data={anios} value=anio label=etiqueta title="Ano" order="anio desc" defaultValue="ultimo">
    <DropdownOption value="ultimo" valueLabel="Último ano completo" />
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
    <Column id=aeropuerto title="Aeroporto" />
    <Column id=provincia title="Provincia" />
    <Column id=pasajeros title="Pasaxeiros" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=variacion title="fronte ao ano anterior" fmt=pct1 contentType=delta />
    <Column id=var_2019 title="fronte a 2019" fmt=pct0 contentType=delta />
    <Column id=operaciones title="Voos" fmt=num0 />
    <Column id=pasajeros_por_operacion title="Pasaxeiros por voo" fmt=num0 />
    <Column id=cuota_internacional title="% internacional" fmt=pct0 />
    <Column id=mercancia_t title="Mercadorías (t)" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Nun ano incompleto, a variación compara cos mesmos meses do ano anterior. Voos = aterraxes + despegues, tamén de aviación xeral e escolas (por iso Sabadell ou Cuatro Vientos teñen moitos voos e case ningún pasaxeiro). % internacional: pasaxeiros de voos a outro país segundo Eurostat, desde 2020 (o ano en curso aínda non o ten).</p>

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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Datos: AENA e Eurostat"
    tooltip={[
        {id: 'aeropuerto', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pasajeros', title: 'Pasaxeiros', fmt: 'num0'},
        {id: 'cuota_nacional', title: 'Voos nacionais', fmt: 'pct0'},
        {id: 'cuota_ue', title: 'Resto da UE', fmt: 'pct0'},
        {id: 'cuota_fuera_ue', title: 'Fóra da UE', fmt: 'pct0'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Tamaño segundo os pasaxeiros do último ano completo; cor segundo de onde vén ou cara a onde vai a maior parte dos seus pasaxeiros (Eurostat). O Reino Unido conta fóra da UE: por iso en Alacante ou Tenerife Sur os voos de fóra da UE case igualan aos europeos.</p>

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
    title="De onde veñen e cara a onde van os seus pasaxeiros"
/>

{/if}

<p class="text-xs text-gray-500">Os quince aeroportos con máis pasaxeiros no último ano completo. Tenerife Norte, Gran Canaria, Sevilla ou Bilbao viven sobre todo do voo nacional (entre illas ou coa península); Palma, Málaga ou Valencia, do resto da UE; en Madrid, Alacante e Tenerife Sur uns catro de cada dez pasaxeiros voan fóra da UE, Reino Unido incluído.</p>

## Un aeroporto mes a mes

```sql lista_aeropuertos
SELECT oaci, aeropuerto || ' (' || coalesce(iata, oaci) || ')' AS etiqueta, sum(pasajeros) AS pasajeros
FROM mother.movilidad_aeropuertos_anual
WHERE red = 'espana' AND anio >= (SELECT max(anio) FROM mother.movilidad_aeropuertos_anual) - 1
GROUP BY oaci, aeropuerto, iata
ORDER BY pasajeros DESC NULLS LAST
```

<Dropdown name=aeropuerto data={lista_aeropuertos} value=oaci label=etiqueta title="Aeroporto" defaultValue="LEMD" />

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
    title="Pasaxeiros ao mes"
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
    title="Pasaxeiros por ano"
/>

{/if}

<p class="text-xs text-gray-500">Cifras absolutas: un aeroporto dá servizo a residentes e a visitantes de moitos sitios, así que non se divide pola poboación da súa provincia. Os nomes que cambiaron cos anos (Madrid-Barajas pasou a chamarse Adolfo Suárez Madrid-Barajas en 2014) van xuntos. Murcia-San Javier pechou ao tráfico comercial en xaneiro de 2019, cando abriu o aeroporto da Rexión de Murcia (Corvera). O último ano está incompleto.</p>

## Por comunidade autónoma

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
    title="Pasaxeiros por habitante da comunidade (último ano completo)"
/>

<p class="text-xs text-gray-500">Pasaxeiros dos aeroportos de AENA de cada comunidade divididos pola súa poboación. Baleares e Canarias multiplican varias veces a media porque reciben millóns de turistas e porque entre illas, e coa península, case todo se move en avión. Castela-A Mancha (Albacete) apenas ten voos comerciais; os aeroportos de Ciudad Real, Castelló, Lleida, Teruel e Andorra-La Seu non son de AENA e non están aquí.</p>

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
    title="Os 25 aeroportos europeos con máis pasaxeiros en {europa_anio[0]?.anio}"
/>

{/if}

<p class="text-xs text-gray-500">Eurostat, pasaxeiros que chegan ou saen de cada aeroporto. Faltan os do Reino Unido, que deixou de enviar datos a Eurostat tras o Brexit: con eles, Londres-Heathrow estaría entre os primeiros. Istambul e Antalya (Turquía) si están.</p>

```sql europa_espana
SELECT puesto, aeropuerto, pasajeros, cuota_internacional
FROM mother.movilidad_aeropuertos_europa
WHERE es_espana AND anio = (SELECT max(anio) FROM mother.movilidad_aeropuertos_europa)
ORDER BY puesto
LIMIT 15
```

<DataTable data={europa_espana} rows=15>
    <Column id=puesto title="Posto en Europa" />
    <Column id=aeropuerto title="Aeroporto" />
    <Column id=pasajeros title="Pasaxeiros" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_internacional title="% internacional" fmt=pct0 />
</DataTable>

## AENA fóra de España

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

AENA é unha empresa que cotiza en bolsa e cuxo accionista maioritario é o Estado, a través de ENAIRE. Tamén xestiona aeroportos fóra de España, que o seu informe mensual inclúe desde 2024. Non contan en ningunha outra cifra desta páxina.

{#if Array.from(exterior ?? []).length > 0}

<DataTable data={etiquetar(exterior, 'pais', (d) => PAIS_RED[d.red])}>
    <Column id=pais title="País" />
    <Column id=aeropuertos title="Aeroportos" />
    <Column id=pasajeros title="Pasaxeiros en {exterior_anio[0]?.anio}" fmt=num0 />
    <Column id=lista title="Cales" wrap=true />
</DataTable>

{/if}

---

## Fontes e notas

- **[AENA – Estatísticas de tráfico aéreo, informes mensuais](https://www.aena.es/es/estadisticas/informes-mensuales.html)**, desde xaneiro de 2004: pasaxeiros, operacións e mercadorías de cada aeroporto e heliporto da rede. Os meses máis recentes son provisionais ata que AENA publica os definitivos.
- **Pasaxeiros**: os que chegan máis os que saen, incluídos os que fan escala sen cambiar de avión (tránsito). Unha viaxe de ida e volta entre dous aeroportos españois conta catro veces no total da rede. **Operacións**: aterraxes máis despegues, de todo tipo de aviación (comercial, privada, escolas, traballos aéreos). **Mercadorías**: carga e correo, en toneladas.
- Por habitante: poboación de España ou de cada comunidade segundo o padrón do INE (o último dispoñible para o ano en curso).
- **[Eurostat – avia_paoa](https://ec.europa.eu/eurostat/databrowser/view/avia_paoa/default/table)**: pasaxeiros por aeroporto europeo e o seu reparto entre voos nacionais, dentro da UE-27 e fóra dela (co Reino Unido fóra desde 2020). **[ttr00012](https://ec.europa.eu/eurostat/databrowser/view/ttr00012/default/table)**: pasaxeiros por país, para a comparación por habitante.
- Coordenadas dos aeroportos: [OurAirports](https://ourairports.com/) (dominio público). Os viaxeiros de avión en voos interiores xunto ao tren e o autobús están en [Transporte público](/gl/movilidad/transporte-publico).

<LastRefreshed prefix="Datos actualizados" />
