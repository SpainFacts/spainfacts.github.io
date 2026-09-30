---
title: Sistema elektrikoaren errekorrak
description: "Espainiako sistema elektrikoaren errekor historikoak 2015etik: eskari maximoa eta minimoa, eguzki-energiaren, eolikoaren eta berriztagarrien maximoak, isuri minimoak, prezioak eta trukeak, Penintsulan, Balear Uharteetan eta Kanarietan. REEren datuak 5 minuturo."
i18n_origen: 6182e64745d7
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    const MESES = ['urt', 'ots', 'mar', 'api', 'mai', 'eka', 'uzt', 'abu', 'ira', 'urr', 'aza', 'abe'];

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
        return `${a} ${MESES[Number(m) - 1]} ${Number(d)}` + (h ? `, ${h}` : '');
    };

    const vigencia = (dias) => {
        if (dias === null || dias === undefined) return '-';
        if (dias === 0) return 'gaur hautsia';
        if (dias === 1) return 'atzo hautsia';
        if (dias < 60) return `duela ${dias} egun`;
        if (dias < 730) return `duela ${Math.round(dias / 30.4)} hilabete`;
        return `duela ${formatNumber(dias / 365.25, 1)} urte`;
    };

    const nombreSistema = { peninsula: 'Penintsula', baleares: 'Balear Uharteak', canarias: 'Kanariak' };
    const nombrePeriodo = { '5 min': 'berehalakoa (5 min)', hora: 'orduko batez bestekoa', 'día': 'eguneko guztizkoa' };
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

# ⚡ Sistema elektrikoaren errekorrak

Espainiako sare elektrikoaren maximo eta minimo historikoak 2015etik, Red Eléctricak Penintsula, Balear Uharteak eta Kanarietarako **5 minuturo argitaratzen duen eskari- eta sorkuntza-kurbarekin** kalkulatuak. Errekor bakoitzak adierazten du noiz ezarri zen, zer balio gainditu zuen eta zenbat denbora daraman indarrean. Azken 30 egunetan **{recientes.length}** errekor hautsi dira.

<Grid cols=4>
{#each destacados as d}
    <KpiCard
        title={d.categoria}
        value={d.valor}
        formattedValue={valor(d.valor, d.unidad)}
        unit={' ' + d.unidad}
        period={fecha(d.ts) + ' · ' + vigencia(d.dias_vigente)}
        source="REE · Penintsula"
        sparklineData={progresion.filter(p => p.codigo === d.codigo)}
    />
{/each}
</Grid>

---

## Errekor guztiak

Aukeratu sistema elektrikoa eta aldia: **berehalakoa** (5 minutuko tarte baten balioa), **orduko batez bestekoa** edo **eguneko guztizkoa** (eguneko energia, edo egun osoko kuota eta intentsitatea). Azken 30 egunetan hautsitako errekorrak nabarmenduta agertzen dira.

<ButtonGroup name=sistema title="Sistema">
    <ButtonGroupItem valueLabel="Penintsula" value="peninsula" default />
    <ButtonGroupItem valueLabel="Balear Uharteak" value="baleares" />
    <ButtonGroupItem valueLabel="Kanariak" value="canarias" />
</ButtonGroup>

<ButtonGroup name=periodo title="Aldia">
    <ButtonGroupItem valueLabel="Berehalakoa (5 min)" value="5 min" default />
    <ButtonGroupItem valueLabel="Orduko batez bestekoa" value="hora" />
    <ButtonGroupItem valueLabel="Eguneko guztizkoa" value="día" />
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
                <span class="shrink-0 rounded-full bg-amber-500 text-white text-xs font-bold px-2 py-0.5">Berria</span>
            {/if}
        </div>
        <div class="text-3xl font-bold text-gray-900 dark:text-white tabular-nums">
            {valor(r.valor, r.unidad)} <span class="text-base font-medium text-gray-500">{r.unidad}</span>
        </div>
        <div class="text-sm text-gray-600 dark:text-gray-400">{fecha(r.ts)} · <span class="font-medium">{vigencia(r.dias_vigente)}</span></div>
        {#if r.valor_anterior !== null && r.valor_anterior !== undefined}
            <div class="text-xs text-gray-500 dark:text-gray-500">Aurreko errekorra: {valor(r.valor_anterior, r.unidad)} {r.unidad} ({fecha(r.ts_anterior)}) · seriearen hasieratik {r.veces_batido} aldiz hautsia</div>
        {/if}
        {#if r.nota}
            <div class="text-xs italic text-gray-500 dark:text-gray-500">{r.nota}</div>
        {/if}
    </div>
{/each}
</div>

---

## Azken 30 egunetan hautsitako errekorrak

{#if recientes.length > 0}

<DataTable data={recientes} rows=15 sort="fecha desc">
    <Column id=cuando title="Noiz" />
    <Column id=categoria title="Errekorra" />
    <Column id=sistema title="Sistema" />
    <Column id=periodo title="Aldia" />
    <Column id=valor title="Balioa" fmt=num1 />
    <Column id=unidad title="Unitatea" />
    <Column id=valor_anterior title="Aurreko errekorra" fmt=num1 />
    <Column id=record_anterior title="Ezarria" />
</DataTable>

{:else}

Azken 30 egunetan ez da errekorrik hautsi.

{/if}

---

## Nola aldatu den errekor bakoitza

Maila bakoitza errekorra gainditu zen aldi bat da (serie bakoitzaren lehen urtea baztertzen da, ia dena baita errekorra orduan). Erabili goiko sistema- eta aldi-hautatzaileak eta aukeratu metrika.

```sql metricas
SELECT DISTINCT codigo, categoria, orden
FROM mother.electricidad_records
WHERE sistema = '${inputs.sistema}' AND periodo = '${inputs.periodo}'
ORDER BY orden
```

<Dropdown data={metricas} name=metrica value=codigo label=categoria title="Metrika" defaultValue="solar_fv_max" />

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

Metrika honek ez du hautsitako errekorrik bere lehen datu-urtetik kanpo, uneko hautaketarako.

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
    title="Urtero hautsitako errekorrak (metrika guztiak, hautatutako aldia)"
    yAxisTitle="Errekorrak"
/>

{/if}

Azken errekor gehienak **eguzki-energia fotovoltaikoarenak, berriztagarrien kuotarenak eta isuri minimoenak** dira, instalatutako eguzki-potentzia hazi ahala; eskari maximokoak, aldiz, gutxitan hausten dira.

---

## Metodologia eta iturriak

- **Datuak**: [Red Eléctricaren eskari-tresnaren](https://demanda.ree.es/visiona/peninsula/demandaau/tablas/) eskari- eta sorkuntza-kurba teknologiaka (datu bat 5 minuturo, MWtan), sistema penintsularrerako (orri honetan 2015etik), Balear Uharteetarako (2018tik) eta Kanarietarako (2015etik). Prezioak [REEren REData APIko](https://www.ree.es/es/datos/apidatos) eguneko merkatuaren spot prezioa dira (orduka eta, 15 minutuko merkatutik aurrera, ordu-laurdenekoa orduko batez bestekora eramanda). Datuak dituen azken data: **{fecha(ultimo_dato[0]?.fecha)}**.
- **Aldiak**: *berehalakoa* 5 minutuko tarte baten balioa da; *orduko batez bestekoa*, orduko 12 tarteen batez bestekoa (gutxienez 10 eskatzen dira); *eguneko guztizkoa*, eguneko energia (GWh) edo, kuotetan, intentsitatean eta prezioan, egun osoko balioa (egun osoak soilik).
- **Berriztagarria** REEren irizpideari jarraitzen dio: eolikoa, eguzki-energia fotovoltaikoa, eguzki-energia termikoa, hidraulikoa eta beste berriztagarri batzuk (biomasa, biogasa, hondakin berriztagarriak). Ponpaketaren turbinazioa eta bateriak **ez** dira berriztagarritzat hartzen, biltegiratutako energia itzultzen dutelako. Berriztagarrien kuota berriztagarria / sorkuntza osoa da.
- **Isuriak**: sorkuntzaren CO2a, REEren tresnak berak sistema bakoitzerako erabiltzen dituen teknologiakako isuri-faktoreekin (t CO2/MWh; uharteetan askoz handiagoak dira); ez dituzte inportazioak barne hartzen.
- **Eskaria autokontsumorik gabe**: 2025 amaieratik, REEren tresnak autokontsumoaren estimazio bat gehitzen die eskariari eta eguzki-energia fotovoltaikoari; hemen kendu egiten da, seriea aurreko urteekin eta estatistika ofizialekin homogeneoa izan dadin (hilabete bakoitzeko berehalako eskari maximoa REEren ofizialetik, minutuka neurtutakotik, 0,3 % aldentzen da batez beste).
- **Kalitatea**: balantzea bat ez datorren uneak baztertzen dira (eskaria sorkuntzaren, trukeen eta kontsumoen aldean 5 %-etik gorako desfasearekin) eta aurreko eta ondorengo 5 minutuetako balioetatik aldentzen diren gailur isolatuak, iturriaren akats puntualak baitira; orduko batez bestekoak eta eguneko guztizkoak baliozko uneekin kalkulatzen dira. Baztertu egiten dira **2025eko apirilaren 28ko itzalaldia** eta hurrengo eguna, ez baitira eskari minimoaren edo berriztagarrien kuotaren benetako errekorrak.
- **Herrialdekako trukeak**: tresnak 2024 amaieratik baino ez ditu banatzen Frantziarekin, Portugalekin, Marokorekin eta Andorrarekin izandako fluxuak; aurreko orduko batez bestekoetarako eta eguneko guztizkoetarako, [ESIOSen](https://www.esios.ree.es/) (REE) mugaka telemedikatutako saldo garbia erabiltzen da.
- **Mugak**: 2018ra arte, REEk kogenerazioa, hondakinak eta biomasa "araubide bereziko gainerakoa" atalean biltzen zituen (hemen kogenerazio gisa zenbatzen da, eta horrek urte horietako berriztagarrien kuota zertxobait gutxiesten du); 2021 eta 2025 artean, 100-350 MW inguruko hondar bat banatu gabe geratzen da; ~2022ra arte, hidraulikoa ponpaketa-kontsumoa kenduta argitaratzen da; mugakako berehalako errekorrek 2024 amaieratik aurrerakoa baino ez dute hartzen; bateriak REEk argitaratzen dituenetik agertzen dira. Tresnaren balioak denbora errealeko datuak dira, eta REEren itxiera ofizialetatik zertxobait alda daitezke.
- [Open Electricity](https://openelectricity.org.au/records) (Australia) webguneko errekorren orrian oinarritua.
