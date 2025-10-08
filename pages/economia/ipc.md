---
title: Inflación (IPC) en España
---

# Evolución de la Inflación (IPC)

El Índice de Precios de Consumo (IPC) mide la evolución del conjunto de precios de los bienes y servicios que consume la población residente en España. La tasa de variación anual del IPC es el indicador más utilizado para medir la inflación.

A continuación se presenta la serie histórica de la tasa de variación anual del IPC, extraída directamente de las publicaciones del Instituto Nacional de Estadística (INE).

## Gráfico de la Tasa de Inflación Anual

Este gráfico muestra cómo ha variado la inflación a lo largo de los años, lo que es clave para entender el poder adquisitivo y las políticas económicas.

<LineChart
    data={ipc_data}
    x=date
    y=value
    yAxisTitle="Tasa de Inflación Anual (%)"
    title="IPC en España (Variación Anual)"
/>

<DataTable
    data={ipc_data}
    title="Datos Históricos del IPC (Variación Anual)"
/>

<br/>

**Fuente:** [INE - Índice de Precios de Consumo (IPC)](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176802&menu=ultiDatos&idp=1254735976607)

```sql ipc_data
-- Fetches the complete time series for the Consumer Price Index (CPI) from MotherDuck
SELECT
    date,
    value
FROM mother.ipc
ORDER BY date ASC
```