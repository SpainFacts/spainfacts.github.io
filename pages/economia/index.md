---
title: Datos Económicos
---

# Panel de Datos Económicos

Esta sección presenta indicadores clave sobre la economía española, extraídos de fuentes oficiales como el Instituto Nacional de Estadística (INE).

<Grid cols=2>

<div class="card">
    <h3>Tasa de Paro</h3>
    <Value data={latest_unemployment} column=value fmt='0.0"%"' />
    <p>Último dato disponible ({latest_unemployment[0].period}).</p>
    <a href="/economia/paro">Ver evolución y detalles →</a>
</div>

<div class="card">
    <h3>Inflación (IPC Anual)</h3>
    <Value data={latest_ipc} column=value fmt='0.0"%"' />
    <p>Último dato disponible ({latest_ipc[0].period}).</p>
    <a href="/economia/ipc">Ver evolución y detalles →</a>
</div>

</Grid>

<br/>

### Fuentes de Datos

Todos los datos se extraen y procesan automáticamente desde la API del [Instituto Nacional de Estadística (INE)](https://www.ine.es/) y se cargan en nuestra base de datos en MotherDuck.

```sql latest_unemployment
-- Fetches the most recent unemployment rate from MotherDuck
SELECT
    value,
    strftime(date, '%Y-%m') as period
FROM mother.unemployment
ORDER BY date DESC
LIMIT 1
```

```sql latest_ipc
-- Fetches the most recent Consumer Price Index (CPI) annual rate from MotherDuck
SELECT
    value,
    strftime(date, '%Y-%m') as period
FROM mother.ipc
ORDER BY date DESC
LIMIT 1
```

<style>
    .card {
        border: 1px solid #e0e0e0;
        border-radius: 8px;
        padding: 16px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
</style>