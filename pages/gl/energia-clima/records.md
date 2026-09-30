---
i18n_origen: 6182e64745d7
title: Récords do sistema eléctrico
description: "Récords históricos do sistema eléctrico español desde 2015: demanda máxima e mínima, máximos de solar, eólica e renovables, emisións mínimas, prezos e intercambios, na península, Baleares e Canarias. Datos de REE cada 5 minutos."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    const MESES = ['xan', 'feb', 'mar', 'abr', 'mai', 'xuñ', 'xul', 'ago', 'set', 'out', 'nov', 'dec'];

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
        if (dias === 0) return 'batido hoxe';
        if (dias === 1) return 'batido onte';
        if (dias < 60) return `hai ${dias} días`;
        if (dias < 730) return `hai ${Math.round(dias / 30.4)} meses`;
        return `hai ${formatNumber(dias / 365.25, 1)} anos`;
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

# ⚡ Récords do sistema eléctrico

Os máximos e mínimos históricos da rede eléctrica española desde 2015, calculados coa curva de **demanda e xeración que Red Eléctrica publica cada 5 minutos** para a península, Baleares e Canarias. Cada récord indica cando se estableceu, que valor superou e canto tempo leva en pé. Nos últimos 30 días batéronse **{recientes.length}** récords.

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

## Todos os récords

Escolle o sistema eléctrico e o período: **instantáneo** (o valor dun intervalo de 5 minutos), **media horaria** ou **total diario** (enerxía do día, ou a cota e a intensidade de todo o día). Os récords batidos nos últimos 30 días aparecen resaltados.

<ButtonGroup name=sistema title="Sistema">
    <ButtonGroupItem valueLabel="Península" value="peninsula" default />
    <ButtonGroupItem valueLabel="Baleares" value="baleares" />
    <ButtonGroupItem valueLabel="Canarias" value="canarias" />
</ButtonGroup>

<ButtonGroup name=periodo title="Período">
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
                <span class="shrink-0 rounded-full bg-amber-500 text-white text-xs font-bold px-2 py-0.5">Novo</span>
            {/if}
        </div>
        <div class="text-3xl font-bold text-gray-900 dark:text-white tabular-nums">
            {valor(r.valor, r.unidad)} <span class="text-base font-medium text-gray-500">{r.unidad}</span>
        </div>
        <div class="text-sm text-gray-600 dark:text-gray-400">{fecha(r.ts)} · <span class="font-medium">{vigencia(r.dias_vigente)}</span></div>
        {#if r.valor_anterior !== null && r.valor_anterior !== undefined}
            <div class="text-xs text-gray-500 dark:text-gray-500">Superou {valor(r.valor_anterior, r.unidad)} {r.unidad} ({fecha(r.ts_anterior)}) · batido {r.veces_batido} {r.veces_batido === 1 ? 'vez' : 'veces'} desde o inicio da serie</div>
        {/if}
        {#if r.nota}
            <div class="text-xs italic text-gray-500 dark:text-gray-500">{r.nota}</div>
        {/if}
    </div>
{/each}
</div>

---

## Récords batidos nos últimos 30 días

{#if recientes.length > 0}

<DataTable data={recientes} rows=15 sort="fecha desc">
    <Column id=cuando title="Cando" />
    <Column id=categoria title="Récord" />
    <Column id=sistema title="Sistema" />
    <Column id=periodo title="Período" />
    <Column id=valor title="Valor" fmt=num1 />
    <Column id=unidad title="Unidad" />
    <Column id=valor_anterior title="Récord anterior" fmt=num1 />
    <Column id=record_anterior title="Establecido" />
</DataTable>

{:else}

Non se bateu ningún récord nos últimos 30 días.

{/if}

---

## Como evolucionou cada récord

Cada chanzo é unha vez que o récord se superou (omítese o primeiro ano de cada serie, no que case todo é récord). Usa os selectores de sistema e período de arriba e escolle a métrica.

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

Esta métrica non ten récords batidos fóra do seu primeiro ano de datos para a selección actual.

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
    title="Récords batidos cada ano (todas as métricas, período seleccionado)"
    yAxisTitle="Récords"
/>

{/if}

A maioría dos récords recentes son de **solar fotovoltaica, cota renovable e emisións mínimas**, a medida que medra a potencia solar instalada; os de demanda máxima, en cambio, bátense raramente.

---

## Metodoloxía e fontes

- **Datos**: curva de demanda e xeración por tecnoloxía do [visor de demanda de Red Eléctrica](https://demanda.ree.es/visiona/peninsula/demandaau/tablas/) (un dato cada 5 minutos, en MW) para o sistema peninsular (desde 2015 nesta páxina), Baleares (desde 2018) e Canarias (desde 2015). Os prezos son o prezo spot do mercado diario da [API REData de REE](https://www.ree.es/es/datos/apidatos) (horario e, desde o mercado de 15 minutos, cuartohorario promediado á hora). Última data con datos: **{fecha(ultimo_dato[0]?.fecha)}**.
- **Períodos**: *instantáneo* é o valor dun intervalo de 5 minutos; *media horaria*, a media dos 12 intervalos da hora (esíxense polo menos 10); *total diario*, a enerxía do día (GWh) ou, en cotas, intensidade e prezo, o valor do día completo (só días completos).
- **Renovable** segue o criterio de REE: eólica, solar fotovoltaica, solar térmica, hidráulica e outras renovables (biomasa, biogás, residuos renovables). A turbinación de bombeo e as baterías **non** contan como renovables porque devolven enerxía almacenada. A cota renovable é renovable / xeración total.
- **Emisións**: CO2 da xeración cos factores de emisión por tecnoloxía que usa o propio visor de REE para cada sistema (t CO2/MWh; nas illas son moito maiores); non inclúen as importacións.
- **Demanda sen autoconsumo**: desde finais de 2025 o visor de REE suma á demanda e á solar fotovoltaica unha estimación do autoconsumo; aquí descóntase para que a serie sexa homoxénea cos anos anteriores e coas estatísticas oficiais (a demanda máxima instantánea de cada mes difire da oficial de REE, medida ao minuto, nun 0,3 % de media).
- **Calidade**: descártanse os instantes cuxo balance non cadra (demanda fronte a xeración, intercambios e consumos cun desfase superior ao 5 %) e os picos illados que se separan dos valores dos 5 minutos anterior e posterior, que son erros puntuais da fonte; as medias horarias e os totais diarios calcúlanse cos instantes válidos. Exclúense o **apagamento do 28 de abril de 2025** e o día seguinte, que non son récords reais de demanda mínima nin de cota renovable.
- **Intercambios por país**: o visor desagrega os fluxos con Francia, Portugal, Marrocos e Andorra só desde finais de 2024; para as medias horarias e os totais diarios anteriores úsase o saldo neto telemedido por fronteira de [ESIOS](https://www.esios.ree.es/) (REE).
- **Limitacións**: ata 2018 REE agrupaba a coxeración, os residuos e a biomasa en "resto de réxime especial" (aquí cóntase como coxeración, o que infravalora lixeiramente a cota renovable deses anos); entre 2021 e 2025 queda sen desagregar un resto duns 100-350 MW; ata ~2022 a hidráulica publícase neta do consumo de bombeo; os récords instantáneos por fronteira só cobren desde finais de 2024; as baterías aparecen desde que REE as publica. Os valores do visor son datos en tempo real e poden diferir lixeiramente dos peches oficiais de REE.
- Inspirado na páxina de récords de [Open Electricity](https://openelectricity.org.au/records) (Australia).
