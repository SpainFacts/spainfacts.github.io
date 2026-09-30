---
title: Rècords del sistema elèctric
description: "Rècords històrics del sistema elèctric espanyol des del 2015: demanda màxima i mínima, màxims de solar, eòlica i renovables, emissions mínimes, preus i intercanvis, a la península, les Balears i les Canàries. Dades de REE cada 5 minuts."
i18n_origen: 6182e64745d7
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    const MESES = ['gen.', 'febr.', 'març', 'abr.', 'maig', 'juny', 'jul.', 'ag.', 'set.', 'oct.', 'nov.', 'des.'];

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
        if (dias === 0) return 'batut avui';
        if (dias === 1) return 'batut ahir';
        if (dias < 60) return `fa ${dias} dies`;
        if (dias < 730) return `fa ${Math.round(dias / 30.4)} mesos`;
        return `fa ${formatNumber(dias / 365.25, 1)} anys`;
    };

    const nombreSistema = { peninsula: 'Península', baleares: 'Balears', canarias: 'Canàries' };
    const nombrePeriodo = { '5 min': 'instantani (5 min)', hora: 'mitjana horària', 'día': 'total diari' };
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

# ⚡ Rècords del sistema elèctric

Els màxims i mínims històrics de la xarxa elèctrica espanyola des del 2015, calculats amb la corba de **demanda i generació que Red Eléctrica publica cada 5 minuts** per a la península, les Balears i les Canàries. Cada rècord indica quan es va establir, quin valor va superar i quant de temps fa que es manté. En els últims 30 dies s'han batut **{recientes.length}** rècords.

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

## Tots els rècords

Tria el sistema elèctric i el període: **instantani** (el valor d'un interval de 5 minuts), **mitjana horària** o **total diari** (energia del dia, o la quota i la intensitat de tot el dia). Els rècords batuts en els últims 30 dies apareixen ressaltats.

<ButtonGroup name=sistema title="Sistema">
    <ButtonGroupItem valueLabel="Península" value="peninsula" default />
    <ButtonGroupItem valueLabel="Balears" value="baleares" />
    <ButtonGroupItem valueLabel="Canàries" value="canarias" />
</ButtonGroup>

<ButtonGroup name=periodo title="Període">
    <ButtonGroupItem valueLabel="Instantani (5 min)" value="5 min" default />
    <ButtonGroupItem valueLabel="Mitjana horària" value="hora" />
    <ButtonGroupItem valueLabel="Total diari" value="día" />
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
                <span class="shrink-0 rounded-full bg-amber-500 text-white text-xs font-bold px-2 py-0.5">Nou</span>
            {/if}
        </div>
        <div class="text-3xl font-bold text-gray-900 dark:text-white tabular-nums">
            {valor(r.valor, r.unidad)} <span class="text-base font-medium text-gray-500">{r.unidad}</span>
        </div>
        <div class="text-sm text-gray-600 dark:text-gray-400">{fecha(r.ts)} · <span class="font-medium">{vigencia(r.dias_vigente)}</span></div>
        {#if r.valor_anterior !== null && r.valor_anterior !== undefined}
            <div class="text-xs text-gray-500 dark:text-gray-500">Va superar {valor(r.valor_anterior, r.unidad)} {r.unidad} ({fecha(r.ts_anterior)}) · batut {r.veces_batido} {r.veces_batido === 1 ? 'vegada' : 'vegades'} des de l'inici de la sèrie</div>
        {/if}
        {#if r.nota}
            <div class="text-xs italic text-gray-500 dark:text-gray-500">{r.nota}</div>
        {/if}
    </div>
{/each}
</div>

---

## Rècords batuts en els últims 30 dies

{#if recientes.length > 0}

<DataTable data={recientes} rows=15 sort="fecha desc">
    <Column id=cuando title="Quan" />
    <Column id=categoria title="Rècord" />
    <Column id=sistema title="Sistema" />
    <Column id=periodo title="Període" />
    <Column id=valor title="Valor" fmt=num1 />
    <Column id=unidad title="Unitat" />
    <Column id=valor_anterior title="Rècord anterior" fmt=num1 />
    <Column id=record_anterior title="Establert" />
</DataTable>

{:else}

No s'ha batut cap rècord en els últims 30 dies.

{/if}

---

## Com ha evolucionat cada rècord

Cada esglaó és una vegada que el rècord es va superar (s'omet el primer any de cada sèrie, en què gairebé tot és rècord). Fes servir els selectors de sistema i període de dalt i tria la mètrica.

```sql metricas
SELECT DISTINCT codigo, categoria, orden
FROM mother.electricidad_records
WHERE sistema = '${inputs.sistema}' AND periodo = '${inputs.periodo}'
ORDER BY orden
```

<Dropdown data={metricas} name=metrica value=codigo label=categoria title="Mètrica" defaultValue="solar_fv_max" />

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

Aquesta mètrica no té rècords batuts fora del seu primer any de dades per a la selecció actual.

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
    title="Rècords batuts cada any (totes les mètriques, període seleccionat)"
    yAxisTitle="Rècords"
/>

{/if}

La majoria dels rècords recents són de **solar fotovoltaica, quota renovable i emissions mínimes**, a mesura que creix la potència solar instal·lada; els de demanda màxima, en canvi, es baten rarament.

---

## Metodologia i fonts

- **Dades**: corba de demanda i generació per tecnologia del [visor de demanda de Red Eléctrica](https://demanda.ree.es/visiona/peninsula/demandaau/tablas/) (una dada cada 5 minuts, en MW) per al sistema peninsular (des del 2015 en aquesta pàgina), les Balears (des del 2018) i les Canàries (des del 2015). Els preus són el preu spot del mercat diari de l'[API REData de REE](https://www.ree.es/es/datos/apidatos) (horari i, des del mercat de 15 minuts, quarthorari fet la mitjana a l'hora). Última data amb dades: **{fecha(ultimo_dato[0]?.fecha)}**.
- **Períodes**: _instantani_ és el valor d'un interval de 5 minuts; _mitjana horària_, la mitjana dels 12 intervals de l'hora (se n'exigeixen almenys 10); _total diari_, l'energia del dia (GWh) o, en quotes, intensitat i preu, el valor del dia complet (només dies complets).
- **Renovable** segueix el criteri de REE: eòlica, solar fotovoltaica, solar tèrmica, hidràulica i altres renovables (biomassa, biogàs, residus renovables). La turbinació de bombament i les bateries **no** compten com a renovables perquè retornen energia emmagatzemada. La quota renovable és renovable / generació total.
- **Emissions**: CO2 de la generació amb els factors d'emissió per tecnologia que fa servir el mateix visor de REE per a cada sistema (t CO2/MWh; a les illes són molt més alts); no inclouen les importacions.
- **Demanda sense autoconsum**: des de finals del 2025 el visor de REE suma a la demanda i a la solar fotovoltaica una estimació de l'autoconsum; aquí es descompta perquè la sèrie sigui homogènia amb els anys anteriors i amb les estadístiques oficials (la demanda màxima instantània de cada mes difereix de l'oficial de REE, mesurada al minut, en un 0,3 % de mitjana).
- **Qualitat**: es descarten els instants en què el balanç no quadra (demanda davant de generació, intercanvis i consums amb un desfasament superior al 5 %) i els pics aïllats que se separen dels valors dels 5 minuts anterior i posterior, que són errors puntuals de la font; les mitjanes horàries i els totals diaris es calculen amb els instants vàlids. S'exclouen l'**apagada del 28 d'abril de 2025** i el dia següent, que no són rècords reals de demanda mínima ni de quota renovable.
- **Intercanvis per país**: el visor desglossa els fluxos amb França, Portugal, el Marroc i Andorra només des de finals del 2024; per a les mitjanes horàries i els totals diaris anteriors es fa servir el saldo net telemesurat per frontera d'[ESIOS](https://www.esios.ree.es/) (REE).
- **Limitacions**: fins al 2018 REE agrupava la cogeneració, els residus i la biomassa en "resta de règim especial" (aquí es compta com a cogeneració, cosa que infravalora lleugerament la quota renovable d'aquells anys); entre el 2021 i el 2025 queda sense desglossar una resta d'uns 100-350 MW; fins a ~2022 la hidràulica es publica neta del consum de bombament; els rècords instantanis per frontera només cobreixen des de finals del 2024; les bateries apareixen des que REE les publica. Els valors del visor són dades en temps real i poden diferir lleugerament dels tancaments oficials de REE.
- Inspirat en la pàgina de rècords d'[Open Electricity](https://openelectricity.org.au/records) (Austràlia).
