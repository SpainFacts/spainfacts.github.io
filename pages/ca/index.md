---
title: SpainFacts · L'estat d'Espanya en dades oficials
description: "Espanya en dades oficials: població, economia, comptes públics, energia, mobilitat, societat i transparència, d'Espanya a cada municipi. Independent i sense biaix partidista."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: c69067017fff
---

<script>
    import MapaEspana from '../../../../../src/lib/components/MapaEspana.svelte';
    import { formatNumber, formatCompact } from '../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import BuscadorInicio from '../../../../../src/lib/components/BuscadorInicio.svelte';
    import Chat from '../../../../../src/lib/components/Chat.svelte';
</script>

```sql lista_municipios
SELECT m.cod_mun, m.municipio, p.nombre AS provincia, m.poblacion
FROM mother.poblacion_municipios m
JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
WHERE m.anio = (SELECT max(anio) FROM mother.poblacion_municipios)
```

```sql poblacion
SELECT CAST(anio AS INTEGER) AS anio, poblacion AS valor
FROM mother.poblacion_territorios
WHERE nivel = 'pais' AND sexo = 'Total' AND anio >= 2000
ORDER BY anio
```

```sql metricas
SELECT metrica_id, periodo, valor
FROM mother.metricas
WHERE metrica_id IN ('tasa_paro', 'ipc_variacion_anual', 'deuda_publica_pib')
ORDER BY periodo
```

```sql ultimas_metricas
SELECT
    metrica_id,
    arg_max(valor, periodo) AS valor,
    arg_max(periodo, periodo) AS periodo,
    CASE WHEN metrica_id = 'ipc_variacion_anual' THEN strftime(max(periodo), '%m/%Y')
         ELSE CAST(CAST(year(max(periodo)) AS INTEGER) AS VARCHAR) || '-T' || CAST(CAST(quarter(max(periodo)) AS INTEGER) AS VARCHAR) END AS periodo_txt
FROM ${metricas}
GROUP BY metrica_id
```

```sql renovables_mes
SELECT
    date_trunc('month', fecha) AS mes,
    sum(renovable_mwh) / sum(generacion_total_mwh) AS valor
FROM mother.electricidad_diaria
WHERE fecha < date_trunc('month', (SELECT max(fecha) FROM mother.electricidad_diaria))
GROUP BY 1
ORDER BY 1
```

```sql renovables_30
SELECT sum(renovable_mwh) / sum(generacion_total_mwh) AS cuota
FROM mother.electricidad_diaria
WHERE fecha > (SELECT max(fecha) FROM mother.electricidad_diaria) - INTERVAL 30 DAY
```

```sql embalses
SELECT fecha, pct_llenado AS valor
FROM mother.embalses_semanal
WHERE nivel = 'pais' AND fecha >= (SELECT max(fecha) FROM mother.embalses_semanal WHERE nivel = 'pais') - INTERVAL 3 YEAR
ORDER BY fecha
```

```sql embalses_hoy
SELECT pct_llenado, dif_vs_media_10_anios, strftime(fecha, '%d/%m/%Y') AS fecha_txt
FROM mother.embalses_estado_actual
WHERE nivel = 'pais'
```

```sql enchufables
SELECT
    mes,
    sum(matriculaciones) FILTER (WHERE energia IN ('bev', 'phev')) / sum(matriculaciones) AS valor
FROM mother.movilidad_matriculaciones_mensual
WHERE grupo = 'turismo' AND nuevo_usado = 'N' AND mes >= (SELECT max(mes) FROM mother.movilidad_matriculaciones_mensual) - INTERVAL 36 MONTH
GROUP BY mes
ORDER BY mes
```

```sql vida
SELECT anio, anios AS valor
FROM mother.salud_esperanza_vida
WHERE nivel = 'pais' AND sexo = 'Ambos sexos' AND anio >= 2000
ORDER BY anio
```

<div class="not-prose rounded-3xl bg-gradient-to-br from-slate-900 via-blue-950 to-slate-900 text-white px-6 py-10 md:px-12 md:py-14 mb-10 shadow-xl border border-slate-800">
    <div class="max-w-3xl">
        <p class="inline-flex items-center gap-2 rounded-full border border-blue-400/30 bg-blue-500/15 px-3 py-1 text-xs font-semibold text-blue-200 mb-5">
            <span class="h-2 w-2 rounded-full bg-emerald-400 animate-pulse"></span>
            Dades oficials · independent · sense biaix partidista
        </p>
        <h1 class="text-3xl md:text-5xl font-extrabold tracking-tight leading-tight mb-4">
            Espanya, <span class="text-blue-300">en dades</span>.<br class="hidden sm:inline"/> De tot el país al teu municipi.
        </h1>
        <p class="text-base md:text-lg text-slate-300 leading-relaxed mb-7">
            Quants som, en què es gasten els diners públics, com es produeix l'electricitat, quins cotxes comprem, quant vivim o quines administracions no compleixen les seves obligacions: les xifres dels organismes oficials, actualitzades cada dia i explicades amb context.
        </p>
        <BuscadorInicio opciones={lista_municipios} />
        <div class="mt-5 flex flex-wrap gap-2 text-sm">
            <a href="/ca/territorios" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">🗺️</span> Territoris</a>
            <a href="/ca/energia-clima/directo" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">⚡</span> Electricitat ara</a>
            <a href="/ca/movilidad/marcas-y-modelos" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">🚗</span> Cotxes més venuts</a>
            <a href="/ca/transparencia" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">🔎</span> Transparència</a>
        </div>
    </div>
</div>

## Pregunta a les dades

Escriu una pregunta i un model d’IA que funciona al teu navegador buscarà la resposta entre les taules del web. [Més sobre el xat i com fer-lo servir amb Claude o Ollama](/ca/chat).

<Chat perezoso />

## Espanya avui

<Grid cols=4>
    <KpiCard
        title="Població"
        value={poblacion.slice(-1)[0]?.valor}
        formattedValue={formatCompact(poblacion.slice(-1)[0]?.valor, 2)}
        unit="hab."
        period="1 de gener de {poblacion.slice(-1)[0]?.anio}"
        change={poblacion.slice(-2)[1]?.valor && poblacion.slice(-2)[0]?.valor ? (100 * (poblacion.slice(-2)[1].valor / poblacion.slice(-2)[0].valor - 1)).toFixed(1) : null}
        changeUnit="%"
        changePeriod="en un any"
        direction="neutral"
        source="INE"
        href="/ca/demografia"
        sparklineData={poblacion}
    />
    <KpiCard
        title="Taxa d'atur"
        value={ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor, 1)} %"
        period={ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.periodo_txt}
        source="INE (EPA)"
        href="/ca/economia/paro"
        sparklineData={metricas.filter(d => d.metrica_id === 'tasa_paro')}
    />
    <KpiCard
        title="Inflació"
        value={ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.valor, 1)} %"
        period="IPC interanual · {ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.periodo_txt}"
        source="INE"
        href="/ca/economia/ipc"
        sparklineData={metricas.filter(d => d.metrica_id === 'ipc_variacion_anual').slice(-60)}
    />
    <KpiCard
        title="Deute públic"
        value={ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.valor, 1)} % del PIB"
        period={ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.periodo_txt}
        source="Eurostat / BdE"
        href="/ca/cuentas-publicas"
        sparklineData={metricas.filter(d => d.metrica_id === 'deuda_publica_pib')}
    />
    <KpiCard
        title="Electricitat renovable"
        value={renovables_30[0]?.cuota}
        formattedValue="{formatNumber(renovables_30[0]?.cuota / 0.01, 0)} %"
        period="de la generació dels últims 30 dies"
        source="REE"
        href="/ca/energia-clima/mix-electrico"
        sparklineData={renovables_mes.slice(-36)}
    />
    <KpiCard
        title="Reserva d'aigua embassada"
        value={embalses_hoy[0]?.pct_llenado}
        formattedValue="{formatNumber(embalses_hoy[0]?.pct_llenado, 1)} %"
        period="{embalses_hoy[0]?.fecha_txt} · {embalses_hoy[0]?.dif_vs_media_10_anios > 0 ? '+' : ''}{formatNumber(embalses_hoy[0]?.dif_vs_media_10_anios, 1)} pp vs. mitjana de 10 anys"
        source="MITECO"
        href="/ca/energia-clima/embalses"
        sparklineData={embalses}
    />
    <KpiCard
        title="Cotxes nous endollables"
        value={enchufables.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(enchufables.slice(-1)[0]?.valor / 0.01, 1)} %"
        period="elèctrics + híbrids endollables · últim mes"
        source="DGT"
        href="/ca/movilidad/coche-electrico"
        sparklineData={enchufables}
    />
    <KpiCard
        title="Esperança de vida"
        value={vida.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(vida.slice(-1)[0]?.valor, 1)} anys"
        period="en néixer · {vida.slice(-1)[0]?.anio}"
        source="INE / Eurostat"
        href="/ca/sociedad/salud"
        sparklineData={vida}
    />
</Grid>

## Compara les comunitats

```sql mapa_ccaa
WITH ccaa AS (
    SELECT cod, nombre, ruta FROM mother.territorios WHERE nivel = 'ccaa'
),
crimen AS (
    SELECT cod, tasa_1000 AS valor FROM mother.crimen_balance
    WHERE nivel = 'ccaa' AND categoria = 'Total infracciones penales' AND anio = (SELECT max(anio) FROM mother.crimen_balance)
),
vida AS (
    SELECT cod, anios AS valor FROM mother.salud_esperanza_vida
    WHERE nivel = 'ccaa' AND sexo = 'Ambos sexos' AND anio = (SELECT max(anio) FROM mother.salud_esperanza_vida WHERE nivel = 'ccaa')
),
empleo AS (
    SELECT cod, por_1000_hab AS valor FROM mother.empleo_territorio
    WHERE nivel = 'ccaa' AND administracion = 'Total' AND fecha = (SELECT max(fecha) FROM mother.empleo_territorio)
),
deuda AS (
    SELECT cod_ccaa AS cod, deuda_pct_pib AS valor FROM mother.ccaa_deuda WHERE fecha = (SELECT max(fecha) FROM mother.ccaa_deuda)
),
enchufables AS (
    SELECT cod_ccaa AS cod,
        100.0 * sum(matriculaciones) FILTER (WHERE energia IN ('bev', 'phev')) / sum(matriculaciones) AS valor
    FROM mother.movilidad_matriculaciones_provincia
    WHERE nuevo_usado = 'N' AND mes > (SELECT max(mes) FROM mother.movilidad_matriculaciones_provincia) - INTERVAL 12 MONTH
    GROUP BY cod_ccaa
),
crecimiento AS (
    SELECT a.cod, 100.0 * (a.poblacion / b.poblacion - 1) AS valor
    FROM mother.poblacion_territorios a
    JOIN mother.poblacion_territorios b ON b.nivel = a.nivel AND b.cod = a.cod AND b.sexo = a.sexo AND b.anio = a.anio - 10
    WHERE a.nivel = 'ccaa' AND a.sexo = 'Total' AND a.anio = (SELECT max(anio) FROM mother.poblacion_territorios)
)
SELECT c.cod, c.nombre, '/ca' || c.ruta AS ruta, x.valor
FROM ccaa c
LEFT JOIN (
    SELECT 'crimen' AS indicador, * FROM crimen
    UNION ALL SELECT 'vida', * FROM vida
    UNION ALL SELECT 'empleo', * FROM empleo
    UNION ALL SELECT 'deuda', * FROM deuda
    UNION ALL SELECT 'enchufables', * FROM enchufables
    UNION ALL SELECT 'crecimiento', * FROM crecimiento
) x ON x.cod = c.cod AND x.indicador = '${inputs.indicador_mapa}'
```

<ButtonGroup name=indicador_mapa>
    <ButtonGroupItem valueLabel="Creixement de la població" value="crecimiento" default />
    <ButtonGroupItem valueLabel="Esperança de vida" value="vida" />
    <ButtonGroupItem valueLabel="Delictes" value="crimen" />
    <ButtonGroupItem valueLabel="Empleats públics" value="empleo" />
    <ButtonGroupItem valueLabel="Cotxes endollables" value="enchufables" />
    <ButtonGroupItem valueLabel="Deute" value="deuda" />
</ButtonGroup>

<MapaEspana
    data={mapa_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="valor"
    valueFmt="num1"
    link="ruta"
    colorPalette={['#eff6ff', '#60a5fa', '#1e3a8a']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'valor', title: 'Valor', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">
{#if inputs.indicador_mapa === 'crecimiento'}Creixement de la població en els últims 10 anys (%), padró de l'INE.{/if}
{#if inputs.indicador_mapa === 'vida'}Esperança de vida en néixer (anys), INE.{/if}
{#if inputs.indicador_mapa === 'crimen'}Infraccions penals conegudes per 1.000 habitants en l'últim any, Ministeri de l'Interior. Les comunitats turístiques surten més altes perquè els visitants no compten en el denominador.{/if}
{#if inputs.indicador_mapa === 'empleo'}Empleats de les tres administracions amb lloc de treball a la comunitat per 1.000 habitants, Registre Central de Personal.{/if}
{#if inputs.indicador_mapa === 'enchufables'}Percentatge d'elèctrics i híbrids endollables entre els turismes nous dels últims 12 mesos, DGT.{/if}
{#if inputs.indicador_mapa === 'deuda'}Deute de la comunitat autònoma en % del seu PIB, Banc d'Espanya. Ceuta i Melilla no tenen deute autonòmic propi.{/if}
Fes clic en una comunitat per obrir-ne la fitxa.
</p>

## Explora

```sql cabeceras
SELECT
    (SELECT count(*) FROM mother.territorios WHERE nivel = 'provincia') AS provincias,
    (SELECT count(*) FROM mother.trazabilidad_fuentes) AS fuentes,
    (SELECT sum(efectivos) FROM mother.empleo_territorio WHERE nivel = 'pais' AND administracion = 'Total' AND fecha = (SELECT max(fecha) FROM mother.empleo_territorio)) AS empleados,
    (SELECT sum(puntos) FROM mother.movilidad_recarga_provincia) AS puntos_recarga,
    (SELECT tasa_1000 FROM mother.crimen_balance WHERE nivel = 'pais' AND categoria = 'Total infracciones penales' ORDER BY anio DESC LIMIT 1) AS delitos_1000
```

<div class="not-prose grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 my-4">
    <a href="/ca/territorios" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🗺️</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Territoris</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Cada comunitat, província i municipi: població, comptes, deute, qui governa, ocupació pública i seguretat.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">19 comunitats · {cabeceras[0]?.provincias} províncies · +8.100 municipis →</p>
    </a>
    <a href="/ca/demografia" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">👪</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Demografia</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Evolució de la població, natalitat i fecunditat, envelliment, llars i piràmide de qualsevol província.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatCompact(poblacion.slice(-1)[0]?.valor, 2)} habitants →</p>
    </a>
    <a href="/ca/economia" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">💼</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Economia</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">PIB per habitant, sectors, comerç exterior, salaris reals, atur, inflació i preu de l'energia, turisme i empreses.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Atur: {formatNumber(ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor, 1)} % →</p>
    </a>
    <a href="/ca/vivienda" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🏠</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Habitatge</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Preu de compra i de lloguer descomptada la inflació, quants anys de sou costa una casa, compravendes, hipoteques i obra nova.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Preus, lloguer i esforç →</p>
    </a>
    <a href="/ca/cuentas-publicas" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🏛️</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Comptes públics</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Ingressos, despeses, dèficit i deute de totes les administracions, pensions i ocupació pública: quants són, quant cobren i quant costen.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatCompact(cabeceras[0]?.empleados, 2)} empleats públics →</p>
    </a>
    <a href="/ca/energia-clima" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">⚡</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Energia i clima</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">L'electricitat en directe i els seus rècords, centrals, emmagatzematge, electrificació, emissions, embassaments, incendis i calor.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatNumber(100 * renovables_30[0]?.cuota, 0)} % renovable l'últim mes →</p>
    </a>
    <a href="/ca/movilidad" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🚗</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Mobilitat</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Cotxes que es venen i que circulen, l'avenç de l'elèctric, marques i models, punts de recàrrega i transport públic.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatNumber(cabeceras[0]?.puntos_recarga, 0)} punts de recàrrega públics →</p>
    </a>
    <a href="/ca/sociedad" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">👥</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Societat</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Criminalitat, salut, immigració, renda i pobresa fins al nivell de municipi, i educació.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatNumber(cabeceras[0]?.delitos_1000, 1)} delictes coneguts per 1.000 hab. →</p>
    </a>
    <a href="/ca/medios" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">📰</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Mitjans de comunicació</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Quants diners públics reben els mitjans: televisions públiques, publicitat institucional i subvencions, per comunitat i per partit.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Diners públics als mitjans →</p>
    </a>
    <a href="/ca/transparencia" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🔎</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Transparència</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Quins ajuntaments no reten comptes a Hisenda, a qui es retenen fons de l'Estat i qui paga tard als seus proveïdors.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Per municipi i per partit →</p>
    </a>
    <a href="/ca/fuentes" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">📚</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Fonts</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">D'on surt cada dada: organisme, taula oficial, freqüència, llicència i metodologia.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{cabeceras[0]?.fuentes} conjunts de dades oficials →</p>
    </a>
</div>

## Com treballem

<div class="not-prose grid grid-cols-1 md:grid-cols-3 gap-4 my-4">
    <div class="rounded-2xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 p-5">
        <p class="font-bold text-gray-900 dark:text-white mb-1">Només fonts oficials</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">INE, Banc d'Espanya, Eurostat, ministeris, REE, DGT, AEMET… Cada gràfic enllaça a la taula d'origen.</p>
    </div>
    <div class="rounded-2xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 p-5">
        <p class="font-bold text-gray-900 dark:text-white mb-1">Context, no opinió</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">Expliquem què mesura cada xifra i què no, sense judicis polítics: les conclusions les treus tu.</p>
    </div>
    <div class="rounded-2xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 p-5">
        <p class="font-bold text-gray-900 dark:text-white mb-1">Obert i automàtic</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">Les dades es descarreguen i es publiquen soles cada dia; el codi és públic i qualsevol el pot revisar.</p>
    </div>
</div>

<LastRefreshed prefix="Última actualització de les dades" />
