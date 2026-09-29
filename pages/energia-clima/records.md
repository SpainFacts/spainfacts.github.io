---
title: Récords del sistema eléctrico
description: "Récords históricos del sistema eléctrico español desde 2015: demanda máxima y mínima, máximos de solar, eólica y renovables, emisiones mínimas, precios e intercambios, en la península, Baleares y Canarias. Datos de REE cada 5 minutos."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';

    const MESES = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

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
        if (dias === 0) return 'batido hoy';
        if (dias === 1) return 'batido ayer';
        if (dias < 60) return `hace ${dias} días`;
        if (dias < 730) return `hace ${Math.round(dias / 30.4)} meses`;
        return `hace ${formatNumber(dias / 365.25, 1)} años`;
    };

    const nombreSistema = { peninsula: 'Península', baleares: 'Baleares', canarias: 'Canarias' };
    const nombrePeriodo = { '5 min': 'instantáneo (5 min)', hora: 'media horaria', 'día': 'total diario' };
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

# ⚡ Récords del sistema eléctrico

Los máximos y mínimos históricos de la red eléctrica española desde 2015, calculados con la curva de **demanda y generación que Red Eléctrica publica cada 5 minutos** para la península, Baleares y Canarias. Cada récord indica cuándo se estableció, a qué valor superó y cuánto tiempo lleva en pie. En los últimos 30 días se han batido **{recientes.length}** récords.

<Grid cols=4>
{#each destacados as d}
    <KpiCard
        title={d.categoria}
        value={d.valor}
        formattedValue={valor(d.valor, d.unidad)}
        unit={' ' + d.unidad}
        period={fecha(d.ts) + ' · ' + vigencia(d.dias_vigente)}
        source="REE · Península"
        sparklineData={progresion.filter(p => p.codigo === d.codigo)}
    />
{/each}
</Grid>

---

## Todos los récords

Elige el sistema eléctrico y el periodo: **instantáneo** (el valor de un intervalo de 5 minutos), **media horaria** o **total diario** (energía del día, o la cuota y la intensidad de todo el día). Los récords batidos en los últimos 30 días aparecen resaltados.

<ButtonGroup name=sistema title="Sistema">
    <ButtonGroupItem valueLabel="Península" value="peninsula" default />
    <ButtonGroupItem valueLabel="Baleares" value="baleares" />
    <ButtonGroupItem valueLabel="Canarias" value="canarias" />
</ButtonGroup>

<ButtonGroup name=periodo title="Periodo">
    <ButtonGroupItem valueLabel="Instantáneo (5 min)" value="5 min" default />
    <ButtonGroupItem valueLabel="Media horaria" value="hora" />
    <ButtonGroupItem valueLabel="Total diario" value="día" />
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
                <span class="shrink-0 rounded-full bg-amber-500 text-white text-xs font-bold px-2 py-0.5">Nuevo</span>
            {/if}
        </div>
        <div class="text-3xl font-bold text-gray-900 dark:text-white tabular-nums">
            {valor(r.valor, r.unidad)} <span class="text-base font-medium text-gray-500">{r.unidad}</span>
        </div>
        <div class="text-sm text-gray-600 dark:text-gray-400">{fecha(r.ts)} · <span class="font-medium">{vigencia(r.dias_vigente)}</span></div>
        {#if r.valor_anterior !== null && r.valor_anterior !== undefined}
            <div class="text-xs text-gray-500 dark:text-gray-500">Superó {valor(r.valor_anterior, r.unidad)} {r.unidad} ({fecha(r.ts_anterior)}) · batido {r.veces_batido} {r.veces_batido === 1 ? 'vez' : 'veces'} desde el inicio de la serie</div>
        {/if}
        {#if r.nota}
            <div class="text-xs italic text-gray-500 dark:text-gray-500">{r.nota}</div>
        {/if}
    </div>
{/each}
</div>

---

## Récords batidos en los últimos 30 días

{#if recientes.length > 0}

<DataTable data={recientes} rows=15 sort="fecha desc">
    <Column id=cuando title="Cuándo" />
    <Column id=categoria title="Récord" />
    <Column id=sistema title="Sistema" />
    <Column id=periodo title="Periodo" />
    <Column id=valor title="Valor" fmt=num1 />
    <Column id=unidad title="Unidad" />
    <Column id=valor_anterior title="Récord anterior" fmt=num1 />
    <Column id=record_anterior title="Establecido" />
</DataTable>

{:else}

No se ha batido ningún récord en los últimos 30 días.

{/if}

---

## Cómo ha evolucionado cada récord

Cada escalón es una vez que el récord se superó (se omite el primer año de cada serie, en el que casi todo es récord). Usa los selectores de sistema y periodo de arriba y elige la métrica.

```sql metricas
SELECT DISTINCT codigo, categoria, orden
FROM mother.electricidad_records
WHERE sistema = '${inputs.sistema}' AND periodo = '${inputs.periodo}'
ORDER BY orden
```

<Dropdown data={metricas} name=metrica value=codigo label=categoria title="Métrica" defaultValue="solar_fv_max" />

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

Esta métrica no tiene récords batidos fuera de su primer año de datos para la selección actual.

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
    title="Récords batidos cada año (todas las métricas, periodo seleccionado)"
    yAxisTitle="Récords"
/>

{/if}

La mayoría de los récords recientes son de **solar fotovoltaica, cuota renovable y emisiones mínimas**, a medida que crece la potencia solar instalada; los de demanda máxima, en cambio, se baten raramente.

---

## Metodología y fuentes

- **Datos**: curva de demanda y generación por tecnología del [visor de demanda de Red Eléctrica](https://demanda.ree.es/visiona/peninsula/demandaau/tablas/) (un dato cada 5 minutos, en MW) para el sistema peninsular (desde 2015 en esta página), Baleares (desde 2018) y Canarias (desde 2015). Los precios son el precio spot del mercado diario de la [API REData de REE](https://www.ree.es/es/datos/apidatos) (horario y, desde el mercado de 15 minutos, cuartohorario promediado a la hora). Última fecha con datos: **{fecha(ultimo_dato[0]?.fecha)}**.
- **Periodos**: *instantáneo* es el valor de un intervalo de 5 minutos; *media horaria*, la media de los 12 intervalos de la hora (se exigen al menos 10); *total diario*, la energía del día (GWh) o, en cuotas, intensidad y precio, el valor del día completo (solo días completos).
- **Renovable** sigue el criterio de REE: eólica, solar fotovoltaica, solar térmica, hidráulica y otras renovables (biomasa, biogás, residuos renovables). La turbinación de bombeo y las baterías **no** cuentan como renovables porque devuelven energía almacenada. La cuota renovable es renovable / generación total.
- **Emisiones**: CO2 de la generación con los factores de emisión por tecnología que usa el propio visor de REE para cada sistema (t CO2/MWh; en las islas son mucho mayores); no incluyen las importaciones.
- **Demanda sin autoconsumo**: desde finales de 2025 el visor de REE suma a la demanda y a la solar fotovoltaica una estimación del autoconsumo; aquí se descuenta para que la serie sea homogénea con los años anteriores y con las estadísticas oficiales (la demanda máxima instantánea de cada mes difiere de la oficial de REE, medida al minuto, en un 0,3 % de media).
- **Calidad**: se descartan los instantes cuyo balance no cuadra (demanda frente a generación, intercambios y consumos con un desfase superior al 5 %) y los picos aislados que se separan de los valores de los 5 minutos anterior y posterior, que son errores puntuales de la fuente; las medias horarias y los totales diarios se calculan con los instantes válidos. Se excluyen el **apagón del 28 de abril de 2025** y el día siguiente, que no son récords reales de demanda mínima ni de cuota renovable.
- **Intercambios por país**: el visor desglosa los flujos con Francia, Portugal, Marruecos y Andorra solo desde finales de 2024; para las medias horarias y los totales diarios anteriores se usa el saldo neto telemedido por frontera de [ESIOS](https://www.esios.ree.es/) (REE).
- **Limitaciones**: hasta 2018 REE agrupaba la cogeneración, los residuos y la biomasa en "resto de régimen especial" (aquí se cuenta como cogeneración, lo que infravalora ligeramente la cuota renovable de esos años); entre 2021 y 2025 queda sin desglosar un resto de unos 100-350 MW; hasta ~2022 la hidráulica se publica neta del consumo de bombeo; los récords instantáneos por frontera solo cubren desde finales de 2024; las baterías aparecen desde que REE las publica. Los valores del visor son datos en tiempo real y pueden diferir ligeramente de los cierres oficiales de REE.
- Inspirado en la página de récords de [Open Electricity](https://openelectricity.org.au/records) (Australia).
