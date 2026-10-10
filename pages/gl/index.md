---
title: SpainFacts · O Estado de España en Datos Oficiais
description: "España en datos oficiais: poboación, economía, contas públicas, enerxía, mobilidade, sociedade e transparencia, de España a cada municipio. Independente e sen nesgo partidista."
i18n_origen: d80e2a3839de
og:
  image: https://spainfacts.org/og-spainfacts.png
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
            Fontes oficiais e documentadas · independente · sen nesgo partidista
        </p>
        <h1 class="text-3xl md:text-5xl font-extrabold tracking-tight leading-tight mb-4">
            España, <span class="text-blue-300">en datos</span>.<br class="hidden sm:inline"/> De todo o país ao teu municipio.
        </h1>
        <p class="text-base md:text-lg text-slate-300 leading-relaxed mb-7">
            Poboación, economía, contas públicas, enerxía e vida cotiá: cifras oficiais e outras fontes documentadas, con contexto e ligazóns á súa orixe.
        </p>
        <BuscadorInicio opciones={lista_municipios} />
        <div class="mt-5 flex flex-wrap gap-2 text-sm">
            <a href="/gl/territorios" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">🗺️</span> Territorios</a>
            <a href="/gl/energia-clima/directo" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">⚡</span> Electricidade agora</a>
            <a href="/gl/movilidad/marcas-y-modelos" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">🚗</span> Coches máis vendidos</a>
            <a href="/gl/transparencia" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">🔎</span> Transparencia</a>
        </div>
    </div>
</div>

## España hoxe

<Grid cols=4>
    <KpiCard
        title="Poboación"
        value={poblacion.slice(-1)[0]?.valor}
        formattedValue={formatCompact(poblacion.slice(-1)[0]?.valor, 2)}
        unit="hab."
        period="1 de xaneiro de {poblacion.slice(-1)[0]?.anio}"
        change={poblacion.slice(-2)[1]?.valor && poblacion.slice(-2)[0]?.valor ? (100 * (poblacion.slice(-2)[1].valor / poblacion.slice(-2)[0].valor - 1)).toFixed(1) : null}
        changeUnit="%"
        changePeriod="nun ano"
        direction="neutral"
        source="INE · Padrón"
        href="/gl/demografia"
        sparklineData={poblacion}
    />
    <KpiCard
        title="Taxa de paro"
        value={ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor, 1)} %"
        period={ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.periodo_txt}
        source="INE (EPA)"
        href="/gl/economia/paro"
        sparklineData={metricas.filter(d => d.metrica_id === 'tasa_paro')}
    />
    <KpiCard
        title="Inflación"
        value={ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.valor, 1)} %"
        period="IPC interanual · {ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.periodo_txt}"
        source="INE"
        href="/gl/economia/ipc"
        sparklineData={metricas.filter(d => d.metrica_id === 'ipc_variacion_anual').slice(-60)}
    />
    <KpiCard
        title="Débeda pública"
        value={ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.valor, 1)} % do PIB"
        period={ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.periodo_txt}
        source="Eurostat / BdE"
        href="/gl/cuentas-publicas"
        sparklineData={metricas.filter(d => d.metrica_id === 'deuda_publica_pib')}
    />
    <KpiCard
        title="Electricidade renovable"
        value={renovables_30[0]?.cuota}
        formattedValue="{formatNumber(renovables_30[0]?.cuota / 0.01, 0)} %"
        period="da xeración dos últimos 30 días"
        source="REE"
        href="/gl/energia-clima/mix-electrico"
        sparklineData={renovables_mes.slice(-36)}
    />
    <KpiCard
        title="Reserva de auga encorada"
        value={embalses_hoy[0]?.pct_llenado}
        formattedValue="{formatNumber(embalses_hoy[0]?.pct_llenado, 1)} %"
        period="{embalses_hoy[0]?.fecha_txt} · {embalses_hoy[0]?.dif_vs_media_10_anios > 0 ? '+' : ''}{formatNumber(embalses_hoy[0]?.dif_vs_media_10_anios, 1)} pp fronte á media de 10 anos"
        source="MITECO"
        href="/gl/energia-clima/embalses"
        sparklineData={embalses}
    />
    <KpiCard
        title="Coches novos enchufables"
        value={enchufables.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(enchufables.slice(-1)[0]?.valor / 0.01, 1)} %"
        period="eléctricos + híbridos enchufables · último mes"
        source="DGT"
        href="/gl/movilidad/coche-electrico"
        sparklineData={enchufables}
    />
    <KpiCard
        title="Esperanza de vida"
        value={vida.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(vida.slice(-1)[0]?.valor, 1)} anos"
        period="ao nacer · {vida.slice(-1)[0]?.anio}"
        source="INE / Eurostat"
        href="/gl/sociedad/salud"
        sparklineData={vida}
    />
</Grid>

<p class="my-3 text-sm text-gray-600 dark:text-gray-400">
    A poboación destacada aquí procede do Padrón do INE a 1 de xaneiro. A sección de <a href="/gl/demografia">Demografía</a> tamén mostra a Estatística Continua de Poboación, unha serie distinta; por iso as cifras poden diferir lixeiramente.
</p>

## Compara as comunidades

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
SELECT c.cod, c.nombre, '/gl' || c.ruta AS ruta, x.valor
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
    <ButtonGroupItem valueLabel="Crecemento da poboación" value="crecimiento" default />
    <ButtonGroupItem valueLabel="Esperanza de vida" value="vida" />
    <ButtonGroupItem valueLabel="Delitos" value="crimen" />
    <ButtonGroupItem valueLabel="Empregados públicos" value="empleo" />
    <ButtonGroupItem valueLabel="Coches enchufables" value="enchufables" />
    <ButtonGroupItem valueLabel="Débeda" value="deuda" />
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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'valor', title: 'Valor', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">
{#if inputs.indicador_mapa === 'crecimiento'}Crecemento da poboación nos últimos 10 anos (%), padrón do INE.{/if}
{#if inputs.indicador_mapa === 'vida'}Esperanza de vida ao nacer (anos), INE.{/if}
{#if inputs.indicador_mapa === 'crimen'}Infraccións penais coñecidas por 1.000 habitantes no último ano, Ministerio do Interior. As comunidades turísticas saen máis altas porque os visitantes non contan no denominador.{/if}
{#if inputs.indicador_mapa === 'empleo'}Empregados das tres administracións con posto na comunidade por 1.000 habitantes, Rexistro Central de Persoal.{/if}
{#if inputs.indicador_mapa === 'enchufables'}Porcentaxe de eléctricos e híbridos enchufables entre os turismos novos dos últimos 12 meses, DGT.{/if}
{#if inputs.indicador_mapa === 'deuda'}Débeda da comunidade autónoma en % do seu PIB, Banco de España. Ceuta e Melilla non teñen débeda autonómica propia.{/if}
Preme nunha comunidade para abrir a súa ficha.
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
    <a href="/gl/territorios" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🗺️</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Territorios</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Cada comunidade, provincia e municipio: poboación, contas, débeda, quen goberna, emprego público e seguridade.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">19 comunidades · {cabeceras[0]?.provincias} provincias · +8.100 municipios →</p>
    </a>
    <a href="/gl/demografia" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">👪</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Demografía</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Evolución da poboación, natalidade e fecundidade, avellentamento, fogares e pirámide de calquera provincia.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatCompact(poblacion.slice(-1)[0]?.valor, 2)} habitantes →</p>
    </a>
    <a href="/gl/economia" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">💼</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Economía</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">PIB por habitante, sectores, comercio exterior, salarios reais, paro, inflación e prezo da enerxía, turismo e empresas.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Paro: {formatNumber(ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor, 1)} % →</p>
    </a>
    <a href="/gl/vivienda" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🏠</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Vivenda</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Prezo de compra e aluguer descontada a inflación, cantos anos de soldo custa unha casa, compravendas, hipotecas e obra nova.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Prezos, aluguer e esforzo →</p>
    </a>
    <a href="/gl/cuentas-publicas" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🏛️</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Contas públicas</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Ingresos, gastos, déficit e débeda de todas as administracións, pensións e emprego público: cantos son, canto cobran e canto custan.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatCompact(cabeceras[0]?.empleados, 2)} empregados públicos →</p>
    </a>
    <a href="/gl/energia-clima" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">⚡</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Enerxía e clima</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">A electricidade en directo e os seus récords, centrais, almacenamento, electrificación, emisións, encoros, incendios e calor.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatNumber(100 * renovables_30[0]?.cuota, 0)} % renovable no último mes →</p>
    </a>
    <a href="/gl/movilidad" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🚗</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Mobilidade</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Coches que se venden e circulan, o avance do eléctrico, marcas e modelos, puntos de recarga e transporte público.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatNumber(cabeceras[0]?.puntos_recarga, 0)} puntos de recarga públicos →</p>
    </a>
    <a href="/gl/sociedad" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">👥</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Sociedade</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Criminalidade, saúde, inmigración, renda e pobreza ata o nivel de municipio, e educación.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatNumber(cabeceras[0]?.delitos_1000, 1)} delitos coñecidos por 1.000 hab. →</p>
    </a>
    <a href="/gl/medios" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">📰</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Medios de comunicación</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Canto diñeiro público reciben os medios: televisións públicas, publicidade institucional e subvencións, por comunidade e por partido.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Diñeiro público nos medios →</p>
    </a>
    <a href="/gl/transparencia" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🔎</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Transparencia</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Que concellos non renden contas a Facenda, a quen se lle reteñen fondos do Estado e quen lles paga tarde aos seus provedores.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Por municipio e por partido →</p>
    </a>
    <a href="/gl/fuentes" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">📚</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Fontes</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">De onde sae cada dato: organismo, táboa oficial, frecuencia, licenza e metodoloxía.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{cabeceras[0]?.fuentes} conxuntos de datos documentados →</p>
    </a>
</div>

## Pregúntalles aos datos

Fai unha pregunta sobre as estatísticas. O chat busca respostas nas táboas da web; abre as opcións se prefires usar Claude, Ollama ou outro provedor. [Máis sobre o chat](/gl/chat).

<Chat perezoso />

## Como traballamos

<div class="not-prose grid grid-cols-1 md:grid-cols-3 gap-4 my-4">
    <div class="rounded-2xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 p-5">
        <p class="font-bold text-gray-900 dark:text-white mb-1">Fontes oficiais e documentadas</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">INE, Banco de España, Eurostat, ministerios, REE, DGT, AEMET e outras fontes identificadas. Cada gráfico enlaza coa súa orixe.</p>
    </div>
    <div class="rounded-2xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 p-5">
        <p class="font-bold text-gray-900 dark:text-white mb-1">Contexto, non opinión</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">Explicamos que mide cada cifra e que non, sen xuízos políticos: ti sacas as conclusións.</p>
    </div>
    <div class="rounded-2xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 p-5">
        <p class="font-bold text-gray-900 dark:text-white mb-1">Aberto e automático</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">Os datos descárganse e publícanse sós cada día; o código é público e calquera pode revisalo.</p>
    </div>
</div>

<LastRefreshed prefix="Última publicación do sitio" />
