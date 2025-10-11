---
title: Tasa de Paro 
---
# Evolución de la Tasa de Paro

La tasa de paro es uno de los indicadores más importantes para medir la salud del mercado laboral de un país. Representa el porcentaje de la población activa que se encuentra desempleada.

Los datos presentados a continuación provienen de la Encuesta de Población Activa (EPA) y reflejan la serie histórica más reciente publicada por el Instituto Nacional de Estadística (INE).

## Gráfico de la Tasa de Paro

Este gráfico muestra la fluctuación de la tasa de paro a lo largo del tiempo, permitiendo identificar tendencias y ciclos económicos.

<LineChart
    data={unemployment_data}
    x=date
    y=value
    yAxisTitle="Tasa de Paro (%)"
    title="Tasa de Paro en España (Serie Histórica)"
/>

<DataTable
    data={unemployment_data}
    title="Datos Históricos de la Tasa de Paro"
/>

<br/>

**Fuente:** [INE - Encuesta de Población Activa (EPA)](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176918&menu=ultiDatos&idp=1254735976595)

```sql unemployment_data
-- Fetches the complete time series for the unemployment rate from MotherDuck
SELECT
    date,
    value
FROM mother.unemployment
ORDER BY date ASC
```