---
title: Aireportuak
description: "AENAren 46 aireportu eta heliportuetako bidaiariak, hegaldiak eta salgaiak hilero 2004tik, biztanleko eta erkidegoka, trafikoaren zenbat den nazionala, europarra edo EBtik kanpokoa, eta nola alderatzen diren Barajas, El Prat edo Palma Europako aireportu handiekin."
i18n_origen: 1fc33e04e32f
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';

    // Etiquetas visibles de las gráficas: van aquí y no en el SQL, que es idéntico en
    // todas las traducciones (tools/i18n/comprobar.mjs)
    const ESTADO = { completo: 'Urte osoa', incompleto: 'Aurtengo urtea (osatu gabea)' };
    const MESES = ['urt', 'ots', 'mar', 'api', 'mai', 'eka', 'uzt', 'abu', 'ira', 'urr', 'aza', 'abe'];
    const MERCADO = { 1: 'Batez ere nazionalak', 2: 'Batez ere EBko beste herrialdeetara', 3: 'Batez ere EBtik kanpora' };
    const TIPO = { 1: 'Nazionalak', 2: 'EBko gainerakoak', 3: 'EBtik kanpo' };
    const GRUPO = { true: 'Espainia', false: 'Europako gainerakoak' };
    const PAIS_RED = { reino_unido: 'Erresuma Batua', brasil: 'Brasil' };
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

# ✈️ Aireportuak

Zenbat bidaiari, hegaldi eta salgai mugitzen dituzten Espainiako aireportuek, AENAk bere sareko 46 aireportu eta heliportuetarako hilero argitaratzen dituen trafiko-estatistiken arabera.

<Grid cols=4>
    <KpiCard
        title="Bidaiariak aireportuetan"
        value={ultimo[0]?.pasajeros_12m_por_hab}
        formattedValue="{formatNumber(ultimo[0]?.pasajeros_12m_por_hab, 1)} biztanleko"
        period="azken 12 hilabeteetan · {formatCompact(ultimo[0]?.pasajeros_12m, 1)} bidaiari {ultimo[0]?.mes_texto} arte"
        change={ultimo[0]?.var_12m != null ? (ultimo[0].var_12m * 100).toFixed(1) : null}
        changePeriod="aurreko 12 hilabeteekin alderatuta"
        direction="neutral"
        source="AENA"
        sparklineData={serie_12m.map(d => ({...d, y: d.pasajeros_12m_por_hab}))}
    />
    <KpiCard
        title="Bidaiariak azken hilabetean"
        value={ultimo[0]?.pasajeros_por_1000_hab}
        formattedValue="{formatNumber(ultimo[0]?.pasajeros_por_1000_hab, 0)} 1.000 biztanleko"
        period="{formatCompact(ultimo[0]?.pasajeros, 1)} bidaiari {ultimo[0]?.mes_texto} · {ultimo[0]?.var_2019 > 0 ? '+' : ''}{formatNumber(ultimo[0]?.var_2019 * 100, 0)} % 2019ko hilabete berarekin alderatuta"
        change={ultimo[0]?.var_anual != null ? (ultimo[0].var_anual * 100).toFixed(1) : null}
        changePeriod="aurreko urteko hilabete berarekin alderatuta"
        direction="neutral"
        source="AENA"
        sparklineData={serie_mes.map(d => ({...d, y: d.pasajeros_por_1000_hab}))}
    />
    <KpiCard
        title="Hegaldiak (lurreratzeak eta aireratzeak)"
        value={ultimo[0]?.vuelos_dia}
        formattedValue="{formatNumber(ultimo[0]?.vuelos_dia, 0)} egunean"
        period="azken 12 hilabeteetako batez bestekoa · {formatNumber(ultimo[0]?.pasajeros_por_operacion, 0)} bidaiari hegaldiko {ultimo[0]?.mes_texto}"
        source="AENA"
        sparklineData={serie_12m.map(d => ({...d, y: d.operaciones_12m / 365}))}
    />
    <KpiCard
        title="Hegazkinezko salgaiak"
        value={ultimo[0]?.mercancia_kg_12m_por_hab}
        formattedValue="{formatNumber(ultimo[0]?.mercancia_kg_12m_por_hab, 1)} kg biztanleko"
        period="azken 12 hilabeteetan · {formatNumber(ultimo[0]?.mercancia_t_12m / 1000, 0)} mila tona"
        source="AENA"
        sparklineData={serie_12m.map(d => ({...d, y: d.mercancia_kg_12m_por_hab}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'pasajeros_avion_hab'
```

<Comparativa data={comparativa_internacional} decimales={1} />

<p class="text-xs text-gray-500">Eurostatekin alderatuta; Eurostatek behin bakarrik zenbatzen du herrialde bereko bi aireporturen artean hegan egiten duena, eta horregatik Espainiarako haren zifra AENArena baino zertxobait txikiagoa da. Turismo handiko herrialdeak (Grezia, Portugal, Espainia) edo barrualdean mugitzeko hegazkinaren mende daudenak (Norvegia) gorago ateratzen dira.</p>

## Nola aldatu den 2004tik

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
    yAxisTitle="bidaiariak biztanleko"
    title="AENAren aireportuetako bidaiariak biztanleko"
/>

{/if}

<p class="text-xs text-gray-500">Urtean AENAren aireportu batetik irten edo bertara iristen diren bidaiariak, Espainiako biztanleriarekin zatituta, biztanleriaren hazkundea hegazkinaren erabilera handiagoarekin nahas ez dadin. Espainiako bi aireporturen arteko joan-etorriko bidaia batek lau balio ditu (bi irteera eta bi iritsiera); atzerrira egindako batek, bi. Beherakadak 2008-2013ko krisia (Spanair 2012an itxi zelarik) eta 2020-2021eko pandemia dira. Azken urtea osatu gabe dago.</p>

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
    yAxisTitle="bidaiariak 1.000 biztanleko"
    title="Hilabete bakoitzeko bidaiariak: udak tiratzen dio urteari"
    legend=true
/>

{/if}

## Aireportuak banan-banan

```sql anios
SELECT
    CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio,
    CAST(CAST(anio AS INTEGER) AS VARCHAR) || CASE WHEN bool_or(completo) THEN '' ELSE ' (01-' || lpad(CAST(CAST(max(ultimo_mes) AS INTEGER) AS VARCHAR), 2, '0') || ')' END AS etiqueta
FROM mother.movilidad_aeropuertos_anual
WHERE red = 'espana'
GROUP BY anio
```

<!-- «ultimo» = azken urte osoa: kontsultatik ateratako defaultValue berandu iristen da goitibeherara -->
<Dropdown name=anio data={anios} value=anio label=etiqueta title="Urtea" order="anio desc" defaultValue="ultimo">
    <DropdownOption value="ultimo" valueLabel="Azken urte osoa" />
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
    <Column id=aeropuerto title="Aireportua" />
    <Column id=provincia title="Probintzia" />
    <Column id=pasajeros title="Bidaiariak" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=variacion title="Aurreko urtearekin alderatuta" fmt=pct1 contentType=delta />
    <Column id=var_2019 title="2019arekin alderatuta" fmt=pct0 contentType=delta />
    <Column id=operaciones title="Hegaldiak" fmt=num0 />
    <Column id=pasajeros_por_operacion title="Bidaiariak hegaldiko" fmt=num0 />
    <Column id=cuota_internacional title="% nazioartekoa" fmt=pct0 />
    <Column id=mercancia_t title="Salgaiak (t)" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Urte osatu gabe batean, aldakuntzak aurreko urteko hilabete berekin alderatzen du. Hegaldiak = lurreratzeak + aireratzeak, hegazkintza orokorrekoak eta eskoletakoak barne (horregatik dituzte Sabadellek edo Cuatro Vientosek hegaldi asko eta ia bidaiaririk ez). % nazioartekoa: beste herrialde batera doazen hegaldietako bidaiariak, Eurostaten arabera, 2020tik (aurtengo urteak oraindik ez du datu hori).</p>

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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Datuak: AENA eta Eurostat"
    tooltip={[
        {id: 'aeropuerto', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pasajeros', title: 'Bidaiariak', fmt: 'num0'},
        {id: 'cuota_nacional', title: 'Hegaldi nazionalak', fmt: 'pct0'},
        {id: 'cuota_ue', title: 'EBko gainerakoak', fmt: 'pct0'},
        {id: 'cuota_fuera_ue', title: 'EBtik kanpo', fmt: 'pct0'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Tamaina azken urte osoko bidaiarien araberakoa; kolorea, bidaiari gehienak nondik datozen edo nora doazen kontuan hartuta (Eurostat). Erresuma Batua EBtik kanpokotzat hartzen da: horregatik Alacanten edo Tenerife Hegoan EBtik kanpoko hegaldiak ia europarren adina dira.</p>

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
    title="Nondik datozen eta nora doazen bidaiariak"
/>

{/if}

<p class="text-xs text-gray-500">Azken urte osoan bidaiari gehien izan zituzten hamabost aireportuak. Tenerife Iparra, Gran Canaria, Sevilla edo Bilbo batez ere hegaldi nazionalei esker bizi dira (uharteen artean edo penintsularekin); Palma, Malaga edo Valentzia, EBko gainerako herrialdeei esker; Madrilen, Alacanten eta Tenerife Hegoan, hamar bidaiaritik lau inguruk EBtik kanpora egiten dute hegan, Erresuma Batua barne.</p>

## Aireportu bat hilabetez hilabete

```sql lista_aeropuertos
SELECT oaci, aeropuerto || ' (' || coalesce(iata, oaci) || ')' AS etiqueta, sum(pasajeros) AS pasajeros
FROM mother.movilidad_aeropuertos_anual
WHERE red = 'espana' AND anio >= (SELECT max(anio) FROM mother.movilidad_aeropuertos_anual) - 1
GROUP BY oaci, aeropuerto, iata
ORDER BY pasajeros DESC NULLS LAST
```

<Dropdown name=aeropuerto data={lista_aeropuertos} value=oaci label=etiqueta title="Aireportua" defaultValue="LEMD" />

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
    title="Bidaiariak hilean"
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
    title="Bidaiariak urtean"
/>

{/if}

<p class="text-xs text-gray-500">Zifra absolutuak: aireportu batek leku askotako egoiliarrei eta bisitariei ematen die zerbitzua, eta beraz ez da bere probintziako biztanleriarekin zatitzen. Urteetan zehar izena aldatu dutenak (Madrid-Barajas Adolfo Suárez Madrid-Barajas izatera pasatu zen 2014an) elkarrekin doaz. Murtzia-San Javier merkataritza-trafikoari itxi zitzaion 2019ko urtarrilean, Murtziako Eskualdeko aireportua (Corvera) ireki zenean. Azken urtea osatu gabe dago.</p>

## Autonomia-erkidegoka

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
    title="Bidaiariak erkidegoko biztanleko (azken urte osoa)"
/>

<p class="text-xs text-gray-500">Erkidego bakoitzeko AENAren aireportuetako bidaiariak, haren biztanleriarekin zatituta. Balear eta Kanariar uharteek batez bestekoa hainbat aldiz biderkatzen dute, milioika turista hartzen dituztelako eta uharteen artean, eta penintsularekin, ia dena hegazkinez mugitzen delako. Gaztela-Mantxak (Albacete) ia ez du merkataritza-hegaldirik; Ciudad Real, Castelló, Lleida, Teruel eta Andorra-La Seuko aireportuak ez dira AENArenak, eta ez daude hemen.</p>

## Espainia Europan

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
    title="Bidaiari gehien izan zituzten Europako 25 aireportuak {europa_anio[0]?.anio}an"
/>

{/if}

<p class="text-xs text-gray-500">Eurostat, aireportu bakoitzera iristen edo bertatik irteten diren bidaiariak. Erresuma Batukoak falta dira, Brexitaren ondoren Eurostati datuak bidaltzeari utzi baitzion: haiekin, Londres-Heathrow lehenengoen artean egongo litzateke. Istanbul eta Antalya (Turkia) badaude.</p>

```sql europa_espana
SELECT puesto, aeropuerto, pasajeros, cuota_internacional
FROM mother.movilidad_aeropuertos_europa
WHERE es_espana AND anio = (SELECT max(anio) FROM mother.movilidad_aeropuertos_europa)
ORDER BY puesto
LIMIT 15
```

<DataTable data={europa_espana} rows=15>
    <Column id=puesto title="Postua Europan" />
    <Column id=aeropuerto title="Aireportua" />
    <Column id=pasajeros title="Bidaiariak" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_internacional title="% nazioartekoa" fmt=pct0 />
</DataTable>

## AENA Espainiatik kanpo

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

AENA burtsan kotizatzen duen enpresa bat da, eta haren akziodun nagusia Estatua da, ENAIREren bidez. Espainiatik kanpoko aireportuak ere kudeatzen ditu, eta haren hileko txostenak 2024tik jasotzen ditu. Ez dira orri honetako beste inongo zifratan sartzen.

{#if Array.from(exterior ?? []).length > 0}

<DataTable data={etiquetar(exterior, 'pais', (d) => PAIS_RED[d.red])}>
    <Column id=pais title="Herrialdea" />
    <Column id=aeropuertos title="Aireportuak" />
    <Column id=pasajeros title="Bidaiariak {exterior_anio[0]?.anio}an" fmt=num0 />
    <Column id=lista title="Zeintzuk" wrap=true />
</DataTable>

{/if}

---

## Iturriak eta oharrak

- **[AENA – Aire-trafikoaren estatistikak, hileko txostenak](https://www.aena.es/es/estadisticas/informes-mensuales.html)**, 2004ko urtarriletik: sareko aireportu eta heliportu bakoitzeko bidaiariak, eragiketak eta salgaiak. Hilabete berrienak behin-behinekoak dira AENAk behin betikoak argitaratu arte.
- **Bidaiariak**: iristen direnak gehi irteten direnak, hegazkinez aldatu gabe eskala egiten dutenak barne (igarotzea). Espainiako bi aireporturen arteko joan-etorriko bidaia batek lau aldiz zenbatzen du sare osoaren guztizkoan. **Eragiketak**: lurreratzeak gehi aireratzeak, hegazkintza mota guztietakoak (komertziala, pribatua, eskolak, aireko lanak). **Salgaiak**: karga eta posta, tonatan.
- Biztanleko: Espainiako edo erkidego bakoitzeko biztanleria, INEren erroldaren arabera (aurtengo urterako eskuragarri dagoen azkena).
- **[Eurostat – avia_paoa](https://ec.europa.eu/eurostat/databrowser/view/avia_paoa/default/table)**: Europako aireportu bakoitzeko bidaiariak eta haien banaketa hegaldi nazionalen, EB-27 barrukoen eta hortik kanpokoen artean (Erresuma Batua kanpo 2020tik). **[ttr00012](https://ec.europa.eu/eurostat/databrowser/view/ttr00012/default/table)**: herrialde bakoitzeko bidaiariak, biztanleko alderaketarako.
- Aireportuen koordenatuak: [OurAirports](https://ourairports.com/) (jabari publikoa). Barne-hegaldietako hegazkin-bidaiariak, trenarekin eta autobusarekin batera, [Garraio publikoa](/eu/movilidad/transporte-publico) orrian daude.

<LastRefreshed prefix="Datuak eguneratuta" />
