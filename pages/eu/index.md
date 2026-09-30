---
title: SpainFacts · Espainiaren Egoera Datu Ofizialetan
description: "Espainia datu ofizialetan: biztanleria, ekonomia, kontu publikoak, energia, mugikortasuna, gizartea eta gardentasuna, Espainia osotik udalerri bakoitzera. Independentea eta alderdi-joerarik gabea."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 3545b565b77e
---

<script>
    import { formatNumber, formatCompact } from '../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import BuscadorInicio from '../../../../../src/lib/components/BuscadorInicio.svelte';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
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
            Datu ofizialak · independentea · alderdi-joerarik gabe
        </p>
        <h1 class="text-3xl md:text-5xl font-extrabold tracking-tight leading-tight mb-4">
            Espainia, <span class="text-blue-300">datuetan</span>.<br class="hidden sm:inline"/> Herrialde osotik zure udalerrira.
        </h1>
        <p class="text-base md:text-lg text-slate-300 leading-relaxed mb-7">
            Zenbat garen, zertan gastatzen den diru publikoa, nola ekoizten den elektrizitatea, zer auto erosten ditugun, zenbat bizi garen edo zein administraziok ez dituen betebeharrak betetzen: erakunde ofizialen zifrak, egunero eguneratuak eta testuinguruarekin azalduak.
        </p>
        <BuscadorInicio opciones={lista_municipios} />
        <div class="mt-5 flex flex-wrap gap-2 text-sm">
            <a href="/eu/territorios" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">🗺️</span> Lurraldeak</a>
            <a href="/eu/energia-clima/directo" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">⚡</span> Elektrizitatea orain</a>
            <a href="/eu/movilidad/marcas-y-modelos" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">🚗</span> Gehien saltzen diren autoak</a>
            <a href="/eu/transparencia" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">🔎</span> Gardentasuna</a>
        </div>
    </div>
</div>

## Espainia gaur

<Grid cols=4>
    <KpiCard
        title="Biztanleria"
        value={poblacion.slice(-1)[0]?.valor}
        formattedValue={formatCompact(poblacion.slice(-1)[0]?.valor, 2)}
        unit="biz."
        period="{urteko(poblacion.slice(-1)[0]?.anio)} urtarrilaren 1a"
        change={poblacion.slice(-2)[1]?.valor && poblacion.slice(-2)[0]?.valor ? (100 * (poblacion.slice(-2)[1].valor / poblacion.slice(-2)[0].valor - 1)).toFixed(1) : null}
        changeUnit="%"
        changePeriod="urtebetean"
        direction="neutral"
        source="INE"
        href="/eu/demografia"
        sparklineData={poblacion}
    />
    <KpiCard
        title="Langabezia-tasa"
        value={ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor, 1)} %"
        period={ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.periodo_txt}
        source="INE (EPA)"
        href="/eu/economia/paro"
        sparklineData={metricas.filter(d => d.metrica_id === 'tasa_paro')}
    />
    <KpiCard
        title="Inflazioa"
        value={ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.valor, 1)} %"
        period="KPI, urte arteko aldaketa · {ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.periodo_txt}"
        source="INE"
        href="/eu/economia/ipc"
        sparklineData={metricas.filter(d => d.metrica_id === 'ipc_variacion_anual').slice(-60)}
    />
    <KpiCard
        title="Zor publikoa"
        value={ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.valor}
        formattedValue="BPGaren {formatNumber(ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.valor, 1)} %"
        period={ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.periodo_txt}
        source="Eurostat / BdE"
        href="/eu/cuentas-publicas"
        sparklineData={metricas.filter(d => d.metrica_id === 'deuda_publica_pib')}
    />
    <KpiCard
        title="Elektrizitate berriztagarria"
        value={renovables_30[0]?.cuota}
        formattedValue="{formatNumber(renovables_30[0]?.cuota / 0.01, 0)} %"
        period="azken 30 egunetako sorkuntzarena"
        source="REE"
        href="/eu/energia-clima/mix-electrico"
        sparklineData={renovables_mes.slice(-36)}
    />
    <KpiCard
        title="Urtegietan bildutako ur-erreserba"
        value={embalses_hoy[0]?.pct_llenado}
        formattedValue="{formatNumber(embalses_hoy[0]?.pct_llenado, 1)} %"
        period="{embalses_hoy[0]?.fecha_txt} · {embalses_hoy[0]?.dif_vs_media_10_anios > 0 ? '+' : ''}{formatNumber(embalses_hoy[0]?.dif_vs_media_10_anios, 1)} pp 10 urteko batez bestekoaren aldean"
        source="MITECO"
        href="/eu/energia-clima/embalses"
        sparklineData={embalses}
    />
    <KpiCard
        title="Auto berri entxufagarriak"
        value={enchufables.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(enchufables.slice(-1)[0]?.valor / 0.01, 1)} %"
        period="elektrikoak + hibrido entxufagarriak · azken hilabetea"
        source="DGT"
        href="/eu/movilidad/coche-electrico"
        sparklineData={enchufables}
    />
    <KpiCard
        title="Bizi-itxaropena"
        value={vida.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(vida.slice(-1)[0]?.valor, 1)} urte"
        period="jaiotzean · {vida.slice(-1)[0]?.anio}"
        source="INE / Eurostat"
        href="/eu/sociedad/salud"
        sparklineData={vida}
    />
</Grid>

## Alderatu erkidegoak

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
SELECT c.cod, c.nombre, '/eu' || c.ruta AS ruta, x.valor
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
    <ButtonGroupItem valueLabel="Biztanleriaren hazkundea" value="crecimiento" default />
    <ButtonGroupItem valueLabel="Bizi-itxaropena" value="vida" />
    <ButtonGroupItem valueLabel="Delituak" value="crimen" />
    <ButtonGroupItem valueLabel="Enplegatu publikoak" value="empleo" />
    <ButtonGroupItem valueLabel="Auto entxufagarriak" value="enchufables" />
    <ButtonGroupItem valueLabel="Zorra" value="deuda" />
</ButtonGroup>

<AreaMap
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
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'valor', title: 'Balioa', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">
{#if inputs.indicador_mapa === 'crecimiento'}Biztanleriaren hazkundea azken 10 urteetan (%), INEren errolda.{/if}
{#if inputs.indicador_mapa === 'vida'}Bizi-itxaropena jaiotzean (urteak), INE.{/if}
{#if inputs.indicador_mapa === 'crimen'}Arau-hauste penal ezagunak 1.000 biztanleko azken urtean, Barne Ministerioa. Erkidego turistikoak altuago ateratzen dira, bisitariak ez direlako izendatzailean zenbatzen.{/if}
{#if inputs.indicador_mapa === 'empleo'}Erkidegoan lanpostua duten hiru administrazioetako enplegatuak 1.000 biztanleko, Langileen Erregistro Zentrala.{/if}
{#if inputs.indicador_mapa === 'enchufables'}Elektrikoen eta hibrido entxufagarrien ehunekoa azken 12 hilabeteetako turismo berrien artean, DGT.{/if}
{#if inputs.indicador_mapa === 'deuda'}Autonomia-erkidegoaren zorra, bere BPGaren ehunekotan, Espainiako Bankua. Ceutak eta Melillak ez dute zor autonomiko propiorik.{/if}
Sakatu erkidego batean haren fitxa irekitzeko.
</p>

## Arakatu

```sql cabeceras
SELECT
    (SELECT count(*) FROM mother.territorios WHERE nivel = 'provincia') AS provincias,
    (SELECT count(*) FROM mother.trazabilidad_fuentes) AS fuentes,
    (SELECT sum(efectivos) FROM mother.empleo_territorio WHERE nivel = 'pais' AND administracion = 'Total' AND fecha = (SELECT max(fecha) FROM mother.empleo_territorio)) AS empleados,
    (SELECT sum(puntos) FROM mother.movilidad_recarga_provincia) AS puntos_recarga,
    (SELECT tasa_1000 FROM mother.crimen_balance WHERE nivel = 'pais' AND categoria = 'Total infracciones penales' ORDER BY anio DESC LIMIT 1) AS delitos_1000
```

<div class="not-prose grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 my-4">
    <a href="/eu/territorios" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🗺️</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Lurraldeak</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Erkidego, probintzia eta udalerri bakoitza: biztanleria, kontuak, zorra, nork gobernatzen duen, enplegu publikoa eta segurtasuna.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">19 erkidego · {cabeceras[0]?.provincias} probintzia · 8.100 udalerri baino gehiago →</p>
    </a>
    <a href="/eu/demografia" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">👪</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Demografia</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Biztanleriaren bilakaera, jaiotza-tasa eta ugalkortasuna, zahartzea, etxeak eta edozein probintziaren piramidea.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatCompact(poblacion.slice(-1)[0]?.valor, 2)} biztanle →</p>
    </a>
    <a href="/eu/economia" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">💼</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Ekonomia</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Biztanleko BPG, sektoreak, kanpo-merkataritza, soldata errealak, langabezia, inflazioa eta energiaren prezioa, turismoa eta enpresak.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Langabezia: {formatNumber(ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor, 1)} % →</p>
    </a>
    <a href="/eu/vivienda" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🏠</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Etxebizitza</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Erosketa- eta alokairu-prezioa inflazioa kenduta, etxe batek zenbat urteko soldata balio duen, salerosketak, hipotekak eta obra berria.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Prezioak, alokairua eta ahalegina →</p>
    </a>
    <a href="/eu/cuentas-publicas" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🏛️</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Kontu publikoak</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Administrazio guztien diru-sarrerak, gastuak, defizita eta zorra, pentsioak eta enplegu publikoa: zenbat diren, zenbat kobratzen duten eta zenbat balio duten.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatCompact(cabeceras[0]?.empleados, 2)} enplegatu publiko →</p>
    </a>
    <a href="/eu/energia-clima" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">⚡</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Energia eta klima</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Elektrizitatea zuzenean eta haren errekorrak, zentralak, biltegiratzea, elektrifikazioa, isuriak, urtegiak, suteak eta beroa.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatNumber(100 * renovables_30[0]?.cuota, 0)} % berriztagarria azken hilabetean →</p>
    </a>
    <a href="/eu/movilidad" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🚗</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Mugikortasuna</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Saltzen eta zirkulatzen duten autoak, elektrikoaren aurrerapena, markak eta modeloak, karga-puntuak eta garraio publikoa.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatNumber(cabeceras[0]?.puntos_recarga, 0)} karga-puntu publiko →</p>
    </a>
    <a href="/eu/sociedad" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">👥</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Gizartea</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Kriminalitatea, osasuna, immigrazioa, errenta eta pobrezia udalerri mailaraino, eta hezkuntza.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatNumber(cabeceras[0]?.delitos_1000, 1)} delitu ezagun 1.000 biz. →</p>
    </a>
    <a href="/eu/transparencia" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🔎</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Gardentasuna</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Zein udalek ez dioten Ogasunari kontuak ematen, nori atxikitzen zaizkion Estatuko funtsak eta nork ordaintzen dien berandu hornitzaileei.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Udalerrika eta alderdika →</p>
    </a>
    <a href="/eu/fuentes" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">📚</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Iturriak</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Nondik ateratzen den datu bakoitza: erakundea, taula ofiziala, maiztasuna, lizentzia eta metodologia.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{cabeceras[0]?.fuentes} datu-multzo ofizial →</p>
    </a>
</div>

## Nola lan egiten dugun

<div class="not-prose grid grid-cols-1 md:grid-cols-3 gap-4 my-4">
    <div class="rounded-2xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 p-5">
        <p class="font-bold text-gray-900 dark:text-white mb-1">Iturri ofizialak soilik</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">INE, Espainiako Bankua, Eurostat, ministerioak, REE, DGT, AEMET… Grafiko bakoitzak bere jatorrizko taularako esteka du.</p>
    </div>
    <div class="rounded-2xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 p-5">
        <p class="font-bold text-gray-900 dark:text-white mb-1">Testuingurua, ez iritzia</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">Zifra bakoitzak zer neurtzen duen eta zer ez azaltzen dugu, iritzi politikorik gabe: zuk ateratzen dituzu ondorioak.</p>
    </div>
    <div class="rounded-2xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 p-5">
        <p class="font-bold text-gray-900 dark:text-white mb-1">Irekia eta automatikoa</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">Datuak berez deskargatu eta argitaratzen dira egunero; kodea publikoa da eta edonork berrikus dezake.</p>
    </div>
</div>

<LastRefreshed prefix="Datuen azken eguneratzea" />
