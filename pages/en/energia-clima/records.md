---
title: Electricity system records
description: "All-time records of the Spanish electricity system since 2015: maximum and minimum demand, solar, wind and renewable peaks, minimum emissions, prices and exchanges, on the Peninsula, the Balearic Islands and the Canary Islands. REE data every 5 minutes."
i18n_origen: 6182e64745d7
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    const MESES = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    const decimales = (unidad) => {
        if (unidad === '%' || unidad === 'GWh' || unidad === 'g CO2/kWh') return 1;
        if (unidad === '€/MWh') return 2;
        return 0;
    };
    const valor = (v, unidad) => formatNumber(v, decimales(unidad));

    // ts llega como texto local 'YYYY-MM-DD HH:MM' (o 'YYYY-MM-DD' en los récords diarios)
    const fecha = (ts) => {
        if (!ts) return '-';
        const [f, h] = String(ts).split(' ');
        const [a, m, d] = f.split('-');
        return `${Number(d)} ${MESES[Number(m) - 1]} ${a}` + (h ? `, ${h}` : '');
    };

    const vigencia = (dias) => {
        if (dias === null || dias === undefined) return '-';
        if (dias === 0) return 'broken today';
        if (dias === 1) return 'broken yesterday';
        if (dias < 60) return `${dias} days ago`;
        if (dias < 730) return `${Math.round(dias / 30.4)} months ago`;
        return `${formatNumber(dias / 365.25, 1)} years ago`;
    };

    const nombreSistema = { peninsula: 'Peninsula', baleares: 'Balearic Islands', canarias: 'Canary Islands' };
    const nombrePeriodo = { '5 min': 'instantaneous (5 min)', hora: 'hourly average', 'día': 'daily total' };
</script>

```sql destacados
SELECT codigo, categoria, valor, unidad, ts, dias_vigente, reciente, valor_anterior, ts_anterior
FROM mother.electricidad_records
WHERE sistema = 'peninsula'
  AND (
      (codigo = 'demanda_max' AND periodo = '5 min')
      OR (codigo = 'pct_renovable_max' AND periodo = 'día')
      OR (codigo = 'solar_fv_max' AND periodo = '5 min')
      OR (codigo = 'precio_min' AND periodo = 'hora')
  )
ORDER BY orden
```

```sql progresion
-- Cómo ha ido mejorando cada récord destacado (del final del primer año de la serie en adelante);
-- los precios, en euros constantes del último año con IPC
WITH ipc AS (
    SELECT CAST(year(periodo) AS INTEGER) AS anio, avg(valor) AS ipc
    FROM mother.metricas
    WHERE metrica_id = 'ipc_indice'
    GROUP BY 1
),
ipc_ultimo AS (
    SELECT ipc FROM ipc ORDER BY anio DESC LIMIT 1
),
h2 AS (
    SELECT codigo, fecha, n_record, valor, unidad, es_inicio_serie,
        max(n_record) FILTER (WHERE es_inicio_serie) OVER (PARTITION BY codigo) AS ultimo_inicio
    FROM mother.electricidad_records_historia
    WHERE sistema = 'peninsula'
      AND ((codigo = 'demanda_max' AND periodo = '5 min')
        OR (codigo = 'pct_renovable_max' AND periodo = 'día')
        OR (codigo = 'solar_fv_max' AND periodo = '5 min')
        OR (codigo = 'precio_min' AND periodo = 'hora'))
)
SELECT
    h2.codigo,
    h2.fecha,
    h2.n_record,
    CASE WHEN h2.unidad = '€/MWh'
        THEN h2.valor * (SELECT ipc FROM ipc_ultimo) / coalesce(i.ipc, (SELECT ipc FROM ipc_ultimo))
        ELSE h2.valor END AS valor
FROM h2
LEFT JOIN ipc AS i ON i.anio = CAST(year(h2.fecha) AS INTEGER)
WHERE NOT h2.es_inicio_serie OR h2.n_record = h2.ultimo_inicio
ORDER BY h2.codigo, h2.fecha, h2.n_record
```

```sql recientes
SELECT
    h.categoria,
    CASE h.sistema WHEN 'peninsula' THEN 'Península' WHEN 'baleares' THEN 'Baleares' ELSE 'Canarias' END AS sistema,
    h.periodo,
    h.valor,
    h.unidad,
    h.ts_local AS cuando,
    h.valor_anterior,
    h.ts_anterior AS record_anterior,
    h.fecha
FROM mother.electricidad_records_historia AS h
WHERE h.fecha >= (SELECT max(fecha) FROM mother.electricidad_diaria) - INTERVAL 30 DAY
  AND NOT h.es_inicio_serie
ORDER BY h.fecha DESC, h.orden
```

```sql ultimo_dato
SELECT strftime(max(fecha), '%Y-%m-%d') AS fecha FROM mother.electricidad_diaria
```

# ⚡ Electricity system records

The all-time highs and lows of the Spanish electricity grid since 2015, calculated from the **demand and generation curve that Red Eléctrica publishes every 5 minutes** for the Peninsula, the Balearic Islands and the Canary Islands. Each record shows when it was set, which value it beat and how long it has stood. In the last 30 days **{recientes.length}** records have been broken.

<Grid cols=4>
{#each destacados as d}
    <KpiCard
        title={d.categoria}
        value={d.valor}
        formattedValue={valor(d.valor, d.unidad)}
        unit={' ' + d.unidad}
        period={fecha(d.ts) + ' · ' + vigencia(d.dias_vigente)}
        source="REE · Peninsula"
        sparklineData={progresion.filter(p => p.codigo === d.codigo)}
    />
{/each}
</Grid>

---

## All records

Choose the electricity system and the period: **instantaneous** (the value for a 5-minute interval), **hourly average** or **daily total** (the day's energy, or the share and intensity over the whole day). Records broken in the last 30 days are highlighted.

<ButtonGroup name=sistema title="System">
    <ButtonGroupItem valueLabel="Peninsula" value="peninsula" default />
    <ButtonGroupItem valueLabel="Balearic Islands" value="baleares" />
    <ButtonGroupItem valueLabel="Canary Islands" value="canarias" />
</ButtonGroup>

<ButtonGroup name=periodo title="Period">
    <ButtonGroupItem valueLabel="Instantaneous (5 min)" value="5 min" default />
    <ButtonGroupItem valueLabel="Hourly average" value="hora" />
    <ButtonGroupItem valueLabel="Daily total" value="día" />
</ButtonGroup>

```sql records_sel
SELECT codigo, categoria, valor, unidad, ts, dias_vigente, reciente, valor_anterior, ts_anterior, veces_batido, nota, orden
FROM mother.electricidad_records
WHERE sistema = '${inputs.sistema}' AND periodo = '${inputs.periodo}'
ORDER BY orden
```

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 my-6">
{#each records_sel as r}
    <div class="rounded-xl border p-5 shadow-sm flex flex-col gap-2 {r.reciente ? 'border-amber-400 bg-amber-50 dark:bg-amber-950/30 dark:border-amber-600' : 'border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900'}">
        <div class="flex items-start justify-between gap-2">
            <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 m-0">{r.categoria}</h3>
            {#if r.reciente}
                <span class="shrink-0 rounded-full bg-amber-500 text-white text-xs font-bold px-2 py-0.5">New</span>
            {/if}
        </div>
        <div class="text-3xl font-bold text-gray-900 dark:text-white tabular-nums">
            {valor(r.valor, r.unidad)} <span class="text-base font-medium text-gray-500">{r.unidad}</span>
        </div>
        <div class="text-sm text-gray-600 dark:text-gray-400">{fecha(r.ts)} · <span class="font-medium">{vigencia(r.dias_vigente)}</span></div>
        {#if r.valor_anterior !== null && r.valor_anterior !== undefined}
            <div class="text-xs text-gray-500 dark:text-gray-500">Beat {valor(r.valor_anterior, r.unidad)} {r.unidad} ({fecha(r.ts_anterior)}) · broken {r.veces_batido} {r.veces_batido === 1 ? 'time' : 'times'} since the start of the series</div>
        {/if}
        {#if r.nota}
            <div class="text-xs italic text-gray-500 dark:text-gray-500">{r.nota}</div>
        {/if}
    </div>
{/each}
</div>

---

## Records broken in the last 30 days

{#if recientes.length > 0}

<DataTable data={recientes} rows=15 sort="fecha desc">
    <Column id=cuando title="When" />
    <Column id=categoria title="Record" />
    <Column id=sistema title="System" />
    <Column id=periodo title="Period" />
    <Column id=valor title="Value" fmt=num1 />
    <Column id=unidad title="Unit" />
    <Column id=valor_anterior title="Previous record" fmt=num1 />
    <Column id=record_anterior title="Set on" />
</DataTable>

{:else}

No records have been broken in the last 30 days.

{/if}

---

## How each record has evolved

Each step marks a time the record was beaten (the first year of each series, when almost everything is a record, is left out). Use the system and period selectors above and choose the metric.

```sql metricas
SELECT DISTINCT codigo, categoria, orden
FROM mother.electricidad_records
WHERE sistema = '${inputs.sistema}' AND periodo = '${inputs.periodo}'
ORDER BY orden
```

<Dropdown data={metricas} name=metrica value=codigo label=categoria title="Metric" defaultValue="solar_fv_max" />

```sql evolucion
SELECT fecha, valor, unidad, ts_local AS cuando, categoria
FROM mother.electricidad_records_historia
WHERE codigo = '${inputs.metrica.value}'
  AND sistema = '${inputs.sistema}'
  AND periodo = '${inputs.periodo}'
  AND NOT es_inicio_serie
ORDER BY fecha
```

{#if evolucion.length > 0}

<LineChart
    data={evolucion}
    x=fecha
    y=valor
    step=true
    markers=true
    yAxisTitle={evolucion[0].unidad}
    title={evolucion[0].categoria + ' · ' + nombreSistema[inputs.sistema] + ' · ' + nombrePeriodo[inputs.periodo]}
/>

{:else}

This metric has no records broken outside its first year of data for the current selection.

{/if}

```sql por_anio
SELECT
    CAST(year(fecha) AS INTEGER) AS anio,
    CASE sistema WHEN 'peninsula' THEN 'Península' WHEN 'baleares' THEN 'Baleares' ELSE 'Canarias' END AS sistema,
    count(*) AS records
FROM mother.electricidad_records_historia
WHERE periodo = '${inputs.periodo}' AND NOT es_inicio_serie
GROUP BY ALL
ORDER BY anio
```

{#if por_anio.length > 0}

<BarChart
    data={por_anio}
    x=anio
    y=records
    series=sistema
    xType=category
    title="Records broken each year (all metrics, selected period)"
    yAxisTitle="Records"
/>

{/if}

Most recent records are for **solar PV, renewable share and minimum emissions**, as installed solar capacity grows; maximum demand records, by contrast, are rarely broken.

---

## Methodology and sources

- **Data**: demand and generation curve by technology from [Red Eléctrica's demand viewer](https://demanda.ree.es/visiona/peninsula/demandaau/tablas/) (one value every 5 minutes, in MW) for the peninsular system (from 2015 on this page), the Balearic Islands (from 2018) and the Canary Islands (from 2015). Prices are the day-ahead market spot price from [REE's REData API](https://www.ree.es/es/datos/apidatos) (hourly and, since the 15-minute market, quarter-hourly averaged to the hour). Latest date with data: **{fecha(ultimo_dato[0]?.fecha)}**.
- **Periods**: *instantaneous* is the value for a 5-minute interval; *hourly average*, the mean of the 12 intervals in the hour (at least 10 are required); *daily total*, the day's energy (GWh) or, for shares, intensity and price, the value for the whole day (complete days only).
- **Renewable** follows REE's definition: wind, solar PV, solar thermal, hydro and other renewables (biomass, biogas, renewable waste). Pumped storage turbining and batteries do **not** count as renewable because they return stored energy. The renewable share is renewable / total generation.
- **Emissions**: CO2 from generation using the emission factors by technology that REE's own viewer applies to each system (t CO2/MWh; much higher on the islands); imports are not included.
- **Demand excluding self-consumption**: since late 2025 REE's viewer adds an estimate of self-consumption to demand and to solar PV; here it is subtracted so that the series is consistent with earlier years and with official statistics (each month's maximum instantaneous demand differs from REE's official figure, measured by the minute, by 0.3 % on average).
- **Quality**: instants whose balance does not add up (demand versus generation, exchanges and consumption with a gap of more than 5 %) are discarded, as are isolated spikes that stand apart from the values for the 5 minutes before and after, which are one-off errors in the source; hourly averages and daily totals are calculated from valid instants. The **blackout of 28 April 2025** and the following day are excluded, as they are not genuine records for minimum demand or renewable share.
- **Exchanges by country**: the viewer only breaks down flows with France, Portugal, Morocco and Andorra from late 2024; for earlier hourly averages and daily totals, the net balance telemetered at each border by [ESIOS](https://www.esios.ree.es/) (REE) is used.
- **Limitations**: until 2018 REE grouped cogeneration, waste and biomass under "other special regime" (counted here as cogeneration, which slightly understates the renewable share for those years); between 2021 and 2025 a remainder of about 100-350 MW is not broken down; until around 2022 hydro is published net of pumping consumption; instantaneous records by border only cover the period from late 2024; batteries appear from when REE began publishing them. The viewer's values are real-time data and may differ slightly from REE's official closing figures.
- Inspired by the records page of [Open Electricity](https://openelectricity.org.au/records) (Australia).
