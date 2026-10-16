---
title: Aeroports
description: "Passatgers, vols i mercaderies dels 46 aeroports i heliports d'AENA cada mes des del 2004, per habitant i per comunitat, quant trànsit és nacional, europeu o de fora de la UE, i com es comparen Barajas, el Prat o Palma amb els grans aeroports d'Europa."
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
    const ESTADO = { completo: 'Any complet', incompleto: 'Any en curs (incomplet)' };
    const MESES = ['gen', 'febr', 'març', 'abr', 'maig', 'juny', 'jul', 'ag', 'set', 'oct', 'nov', 'des'];
    const MERCADO = { 1: 'Sobretot nacionals', 2: 'Sobretot a la resta de la UE', 3: 'Sobretot fora de la UE' };
    const TIPO = { 1: 'Nacionals', 2: 'Resta de la UE', 3: 'Fora de la UE' };
    const GRUPO = { true: 'Espanya', false: 'Resta d\'Europa' };
    const PAIS_RED = { reino_unido: 'Regne Unit', brasil: 'Brasil' };
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

# ✈️ Aeroports

Quants passatgers, vols i mercaderies mouen els aeroports espanyols, segons les estadístiques de trànsit que AENA publica cada mes per als 46 aeroports i heliports de la seva xarxa.

<Grid cols=4>
    <KpiCard
        title="Passatgers als aeroports"
        value={ultimo[0]?.pasajeros_12m_por_hab}
        formattedValue="{formatNumber(ultimo[0]?.pasajeros_12m_por_hab, 1)} per habitant"
        period="en els últims 12 mesos · {formatCompact(ultimo[0]?.pasajeros_12m, 1)} passatgers fins al {ultimo[0]?.mes_texto}"
        change={ultimo[0]?.var_12m != null ? (ultimo[0].var_12m * 100).toFixed(1) : null}
        changePeriod="vs. els 12 mesos anteriors"
        direction="neutral"
        source="AENA"
        sparklineData={serie_12m.map(d => ({...d, y: d.pasajeros_12m_por_hab}))}
    />
    <KpiCard
        title="Passatgers en l'últim mes"
        value={ultimo[0]?.pasajeros_por_1000_hab}
        formattedValue="{formatNumber(ultimo[0]?.pasajeros_por_1000_hab, 0)} per 1.000 hab."
        period="{formatCompact(ultimo[0]?.pasajeros, 1)} passatgers el {ultimo[0]?.mes_texto} · {ultimo[0]?.var_2019 > 0 ? '+' : ''}{formatNumber(ultimo[0]?.var_2019 * 100, 0)} % respecte al mateix mes del 2019"
        change={ultimo[0]?.var_anual != null ? (ultimo[0].var_anual * 100).toFixed(1) : null}
        changePeriod="vs. el mateix mes de l'any anterior"
        direction="neutral"
        source="AENA"
        sparklineData={serie_mes.map(d => ({...d, y: d.pasajeros_por_1000_hab}))}
    />
    <KpiCard
        title="Vols (aterratges i enlairaments)"
        value={ultimo[0]?.vuelos_dia}
        formattedValue="{formatNumber(ultimo[0]?.vuelos_dia, 0)} al dia"
        period="mitjana dels últims 12 mesos · {formatNumber(ultimo[0]?.pasajeros_por_operacion, 0)} passatgers per vol el {ultimo[0]?.mes_texto}"
        source="AENA"
        sparklineData={serie_12m.map(d => ({...d, y: d.operaciones_12m / 365}))}
    />
    <KpiCard
        title="Mercaderies per avió"
        value={ultimo[0]?.mercancia_kg_12m_por_hab}
        formattedValue="{formatNumber(ultimo[0]?.mercancia_kg_12m_por_hab, 1)} kg per habitant"
        period="en els últims 12 mesos · {formatNumber(ultimo[0]?.mercancia_t_12m / 1000, 0)} milers de tones"
        source="AENA"
        sparklineData={serie_12m.map(d => ({...d, y: d.mercancia_kg_12m_por_hab}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'pasajeros_avion_hab'
```

<Comparativa data={comparativa_internacional} decimales={1} />

<p class="text-xs text-gray-500">Comparació amb Eurostat, que compta una sola vegada qui vola entre dos aeroports del mateix país; per això la seva xifra per a Espanya és una mica més baixa que la d'AENA. Els països amb molt de turisme (Grècia, Portugal, Espanya) o que depenen de l'avió per moure's per dins (Noruega) surten més amunt.</p>

## Com ha canviat des del 2004

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
    yAxisTitle="passatgers per habitant"
    title="Passatgers dels aeroports d'AENA per habitant"
/>

{/if}

<p class="text-xs text-gray-500">Passatgers que surten o arriben en un aeroport d'AENA durant l'any, dividits per la població d'Espanya, perquè el creixement de la població no es confongui amb un ús més gran de l'avió. Un viatge d'anada i tornada entre dos aeroports espanyols en suma quatre (dues sortides i dues arribades); un a l'estranger, dos. Les caigudes són la crisi del 2008-2013 (amb el tancament de Spanair el 2012) i la pandèmia del 2020-2021. L'últim any és incomplet.</p>

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
    yAxisTitle="passatgers per 1.000 habitants"
    title="Passatgers de cada mes: l'estiu estira l'any"
    legend=true
/>

{/if}

## Els aeroports un per un

```sql anios
SELECT
    CAST(CAST(anio AS INTEGER) AS VARCHAR) AS anio,
    CAST(CAST(anio AS INTEGER) AS VARCHAR) || CASE WHEN bool_or(completo) THEN '' ELSE ' (01-' || lpad(CAST(CAST(max(ultimo_mes) AS INTEGER) AS VARCHAR), 2, '0') || ')' END AS etiqueta
FROM mother.movilidad_aeropuertos_anual
WHERE red = 'espana'
GROUP BY anio
```

<!-- «ultimo» = último any complet: un defaultValue tret de la consulta arriba tard al desplegable -->
<Dropdown name=anio data={anios} value=anio label=etiqueta title="Any" order="anio desc" defaultValue="ultimo">
    <DropdownOption value="ultimo" valueLabel="Últim any complet" />
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
    <Column id=aeropuerto title="Aeroport" />
    <Column id=provincia title="Província" />
    <Column id=pasajeros title="Passatgers" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=variacion title="vs. any anterior" fmt=pct1 contentType=delta />
    <Column id=var_2019 title="vs. 2019" fmt=pct0 contentType=delta />
    <Column id=operaciones title="Vols" fmt=num0 />
    <Column id=pasajeros_por_operacion title="Passatgers per vol" fmt=num0 />
    <Column id=cuota_internacional title="% internacional" fmt=pct0 />
    <Column id=mercancia_t title="Mercaderies (t)" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">En un any incomplet, la variació es compara amb els mateixos mesos de l'any anterior. Vols = aterratges + enlairaments, també d'aviació general i escoles (per això Sabadell o Cuatro Vientos tenen molts vols i gairebé cap passatger). % internacional: passatgers de vols a un altre país segons Eurostat, des del 2020 (l'any en curs encara no el té).</p>

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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Dades: AENA i Eurostat"
    tooltip={[
        {id: 'aeropuerto', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pasajeros', title: 'Passatgers', fmt: 'num0'},
        {id: 'cuota_nacional', title: 'Vols nacionals', fmt: 'pct0'},
        {id: 'cuota_ue', title: 'Resta de la UE', fmt: 'pct0'},
        {id: 'cuota_fuera_ue', title: 'Fora de la UE', fmt: 'pct0'}
    ]}
/>

{/if}

<p class="text-xs text-gray-500">Mida segons els passatgers de l'últim any complet; color segons d'on venen o cap a on van la major part dels seus passatgers (Eurostat). El Regne Unit compta com a fora de la UE: per això a Alacant o Tenerife Sud els vols de fora de la UE gairebé igualen els europeus.</p>

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
    title="D'on venen i cap a on van els seus passatgers"
/>

{/if}

<p class="text-xs text-gray-500">Els quinze aeroports amb més passatgers de l'últim any complet. Tenerife Nord, Gran Canària, Sevilla o Bilbao viuen sobretot del vol nacional (entre illes o amb la península); Palma, Màlaga o València, de la resta de la UE; a Madrid, Alacant i Tenerife Sud uns quatre de cada deu passatgers volen fora de la UE, Regne Unit inclòs.</p>

## Un aeroport mes a mes

```sql lista_aeropuertos
SELECT oaci, aeropuerto || ' (' || coalesce(iata, oaci) || ')' AS etiqueta, sum(pasajeros) AS pasajeros
FROM mother.movilidad_aeropuertos_anual
WHERE red = 'espana' AND anio >= (SELECT max(anio) FROM mother.movilidad_aeropuertos_anual) - 1
GROUP BY oaci, aeropuerto, iata
ORDER BY pasajeros DESC NULLS LAST
```

<Dropdown name=aeropuerto data={lista_aeropuertos} value=oaci label=etiqueta title="Aeroport" defaultValue="LEMD" />

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
    title="Passatgers al mes"
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
    title="Passatgers per any"
/>

{/if}

<p class="text-xs text-gray-500">Xifres absolutes: un aeroport dona servei a residents i a visitants de molts llocs, així que no es divideix per la població de la seva província. Els noms que han canviat amb els anys (Madrid-Barajas va passar a dir-se Adolfo Suárez Madrid-Barajas el 2014) van junts. Múrcia-San Javier va tancar al trànsit comercial el gener del 2019, quan va obrir l'aeroport de la Regió de Múrcia (Corvera). L'últim any és incomplet.</p>

## Per comunitat autònoma

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
    title="Passatgers per habitant de la comunitat (últim any complet)"
/>

<p class="text-xs text-gray-500">Passatgers dels aeroports d'AENA de cada comunitat dividits per la seva població. Balears i Canàries multipliquen diverses vegades la mitjana perquè reben milions de turistes i perquè entre illes, i amb la península, gairebé tot es mou en avió. Castella-la Manxa (Albacete) amb prou feines té vols comercials; els aeroports de Ciudad Real, Castelló, Lleida, Terol i Andorra-la Seu no són d'AENA i no hi surten.</p>

## Espanya a Europa

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
    title="Els 25 aeroports europeus amb més passatgers el {europa_anio[0]?.anio}"
/>

{/if}

<p class="text-xs text-gray-500">Eurostat, passatgers que arriben o surten de cada aeroport. Hi falten els del Regne Unit, que va deixar d'enviar dades a Eurostat després del Brexit: amb ells, Londres-Heathrow seria entre els primers. Istanbul i Antalya (Turquia) sí que hi són.</p>

```sql europa_espana
SELECT puesto, aeropuerto, pasajeros, cuota_internacional
FROM mother.movilidad_aeropuertos_europa
WHERE es_espana AND anio = (SELECT max(anio) FROM mother.movilidad_aeropuertos_europa)
ORDER BY puesto
LIMIT 15
```

<DataTable data={europa_espana} rows=15>
    <Column id=puesto title="Posició a Europa" />
    <Column id=aeropuerto title="Aeroport" />
    <Column id=pasajeros title="Passatgers" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_internacional title="% internacional" fmt=pct0 />
</DataTable>

## AENA fora d'Espanya

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

AENA és una empresa que cotitza en borsa i que té l'Estat com a accionista majoritari, a través d'ENAIRE. També gestiona aeroports fora d'Espanya, que el seu informe mensual inclou des del 2024. No compten en cap altra xifra d'aquesta pàgina.

{#if Array.from(exterior ?? []).length > 0}

<DataTable data={etiquetar(exterior, 'pais', (d) => PAIS_RED[d.red])}>
    <Column id=pais title="País" />
    <Column id=aeropuertos title="Aeroports" />
    <Column id=pasajeros title="Passatgers el {exterior_anio[0]?.anio}" fmt=num0 />
    <Column id=lista title="Quins" wrap=true />
</DataTable>

{/if}

---

## Fonts i notes

- **[AENA – Estadístiques de trànsit aeri, informes mensuals](https://www.aena.es/es/estadisticas/informes-mensuales.html)**, des del gener del 2004: passatgers, operacions i mercaderies de cada aeroport i heliport de la xarxa. Els mesos més recents són provisionals fins que AENA publica els definitius.
- **Passatgers**: els que arriben més els que surten, inclosos els que fan escala sense canviar d'avió (trànsit). Un viatge d'anada i tornada entre dos aeroports espanyols compta quatre vegades en el total de la xarxa. **Operacions**: aterratges més enlairaments, de tota mena d'aviació (comercial, privada, escoles, treballs aeris). **Mercaderies**: càrrega i correu, en tones.
- Per habitant: població d'Espanya o de cada comunitat segons el padró de l'INE (l'últim disponible per a l'any en curs).
- **[Eurostat – avia_paoa](https://ec.europa.eu/eurostat/databrowser/view/avia_paoa/default/table)**: passatgers per aeroport europeu i el seu repartiment entre vols nacionals, dins de la UE-27 i fora (amb el Regne Unit fora des del 2020). **[ttr00012](https://ec.europa.eu/eurostat/databrowser/view/ttr00012/default/table)**: passatgers per país, per a la comparació per habitant.
- Coordenades dels aeroports: [OurAirports](https://ourairports.com/) (domini públic). Els viatgers d'avió en vols interiors juntament amb el tren i l'autobús són a [Transport públic](/ca/movilidad/transporte-publico).

<LastRefreshed prefix="Dades actualitzades" />
