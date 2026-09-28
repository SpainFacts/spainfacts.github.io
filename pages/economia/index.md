---
title: Datos Económicos
---

<script>
    import { formatNumber } from '../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
</script>

# Panel de Economía y Empleo

Principales indicadores macroeconómicos y del mercado laboral en España, obtenidos de las publicaciones oficiales del Instituto Nacional de Estadística (INE) y el Banco de España.

```sql latest_unemployment
SELECT
    valor,
    strftime(periodo, '%Y') || '-T' || quarter(periodo) AS periodo_txt,
    periodo
FROM mother.metricas
WHERE metrica_id = 'tasa_paro'
ORDER BY periodo DESC
LIMIT 2
```

```sql latest_ipc
SELECT
    valor,
    strftime(periodo, '%Y-%m') AS periodo_txt,
    periodo
FROM mother.metricas
WHERE metrica_id = 'ipc_variacion_anual'
ORDER BY periodo DESC
LIMIT 2
```

```sql serie_paro
SELECT
    periodo,
    valor AS paro
FROM mother.metricas
WHERE metrica_id = 'tasa_paro'
ORDER BY periodo ASC
```

```sql serie_ipc
SELECT
    periodo,
    valor AS ipc
FROM mother.metricas
WHERE metrica_id = 'ipc_variacion_anual'
ORDER BY periodo ASC
```

<Grid cols=2>
    <KpiCard
        title="Tasa de Paro (EPA)"
        value={latest_unemployment[0].valor}
        formattedValue="{formatNumber(latest_unemployment[0].valor, 1)}%"
        period="{latest_unemployment[0].periodo_txt}"
        change={latest_unemployment.length > 1 ? (latest_unemployment[0].valor - latest_unemployment[1].valor).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="vs trimestre anterior"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={serie_paro.filter(d => d.paro != null).slice(-40).map(d => d.paro)}
        href="/economia/paro"
    />

    <KpiCard
        title="Inflación (IPC Anual)"
        value={latest_ipc[0].valor}
        formattedValue="{formatNumber(latest_ipc[0].valor, 1)}%"
        period="{latest_ipc[0].periodo_txt}"
        change={latest_ipc.length > 1 ? (latest_ipc[0].valor - latest_ipc[1].valor).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="vs mes anterior"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={serie_ipc.filter(d => d.ipc != null).slice(-36).map(d => d.ipc)}
        href="/economia/ipc"
    />
</Grid>

---

## 1. Evolución de la Tasa de Paro (Encuesta de Población Activa)

<LineChart
    data={serie_paro}
    x=periodo
    y=paro
    yAxisTitle="Tasa de Paro (%)"
    title="Tasa de Paro en España (Histórico trimestral)"
    startingAtZero={false}
/>

<a href="/economia/paro" class="text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline">
    Ver informe completo y desglose de desempleo →
</a>

---

## 2. Evolución de la Inflación (Variación Interanual del IPC)

<LineChart
    data={serie_ipc}
    x=periodo
    y=ipc
    yAxisTitle="Variación anual (%)"
    title="Índice de Precios de Consumo (Variación anual %)"
    startingAtZero={false}
/>

<a href="/economia/ipc" class="text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline">
    Ver informe detallado del IPC →
</a>

---

## Fuentes Oficiales
- **[INE - Encuesta de Población Activa (EPA)](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176918):** Serie trimestral EPA423474 (tabla 65219).
- **[INE - Índice de Precios de Consumo (IPC)](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176802):** Serie mensual IPC290750 (tabla 76125, base 2025).