---
title: SpainFacts · El Estado de España en Datos Oficiales
description: "España en datos oficiales: población, economía, cuentas públicas, energía, movilidad, sociedad y transparencia, de España a cada municipio. Independiente y sin sesgo partidista."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber, formatCompact } from '../../../../src/lib/utils.js';
    import KpiCard from '../../../../src/lib/components/KpiCard.svelte';
    import BuscadorInicio from '../../../../src/lib/components/BuscadorInicio.svelte';
    import Chat from '../../../../src/lib/components/Chat.svelte';
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
            Datos oficiales · independiente · sin sesgo partidista
        </p>
        <h1 class="text-3xl md:text-5xl font-extrabold tracking-tight leading-tight mb-4">
            España, <span class="text-blue-300">en datos</span>.<br class="hidden sm:inline"/> De todo el país a tu municipio.
        </h1>
        <p class="text-base md:text-lg text-slate-300 leading-relaxed mb-7">
            Cuántos somos, en qué se gasta el dinero público, cómo se produce la electricidad, qué coches compramos, cuánto vivimos o qué administraciones no cumplen con sus obligaciones: las cifras de los organismos oficiales, actualizadas cada día y explicadas con contexto.
        </p>
        <BuscadorInicio opciones={lista_municipios} />
        <div class="mt-5 flex flex-wrap gap-2 text-sm">
            <a href="/territorios" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">🗺️</span> Territorios</a>
            <a href="/energia-clima/directo" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">⚡</span> Electricidad ahora</a>
            <a href="/movilidad/marcas-y-modelos" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">🚗</span> Coches más vendidos</a>
            <a href="/transparencia" class="rounded-lg bg-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 no-underline"><span aria-hidden="true">🔎</span> Transparencia</a>
        </div>
    </div>
</div>

## Pregunta a los datos

Escribe una pregunta y un modelo de IA que corre en tu navegador buscará la respuesta entre las tablas de la web. [Más sobre el chat y cómo usarlo con Claude u Ollama](/chat).

<Chat perezoso />

## España hoy

<Grid cols=4>
    <KpiCard
        title="Población"
        value={poblacion.slice(-1)[0]?.valor}
        formattedValue={formatCompact(poblacion.slice(-1)[0]?.valor, 2)}
        unit="hab."
        period="1 de enero de {poblacion.slice(-1)[0]?.anio}"
        change={poblacion.slice(-2)[1]?.valor && poblacion.slice(-2)[0]?.valor ? (100 * (poblacion.slice(-2)[1].valor / poblacion.slice(-2)[0].valor - 1)).toFixed(1) : null}
        changeUnit="%"
        changePeriod="en un año"
        direction="neutral"
        source="INE"
        href="/demografia"
        sparklineData={poblacion}
    />
    <KpiCard
        title="Tasa de paro"
        value={ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor, 1)} %"
        period={ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.periodo_txt}
        source="INE (EPA)"
        href="/economia/paro"
        sparklineData={metricas.filter(d => d.metrica_id === 'tasa_paro')}
    />
    <KpiCard
        title="Inflación"
        value={ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.valor, 1)} %"
        period="IPC interanual · {ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.periodo_txt}"
        source="INE"
        href="/economia/ipc"
        sparklineData={metricas.filter(d => d.metrica_id === 'ipc_variacion_anual').slice(-60)}
    />
    <KpiCard
        title="Deuda pública"
        value={ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.valor, 1)} % del PIB"
        period={ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.periodo_txt}
        source="Eurostat / BdE"
        href="/cuentas-publicas"
        sparklineData={metricas.filter(d => d.metrica_id === 'deuda_publica_pib')}
    />
    <KpiCard
        title="Electricidad renovable"
        value={renovables_30[0]?.cuota}
        formattedValue="{formatNumber(renovables_30[0]?.cuota / 0.01, 0)} %"
        period="de la generación de los últimos 30 días"
        source="REE"
        href="/energia-clima/mix-electrico"
        sparklineData={renovables_mes.slice(-36)}
    />
    <KpiCard
        title="Reserva de agua embalsada"
        value={embalses_hoy[0]?.pct_llenado}
        formattedValue="{formatNumber(embalses_hoy[0]?.pct_llenado, 1)} %"
        period="{embalses_hoy[0]?.fecha_txt} · {embalses_hoy[0]?.dif_vs_media_10_anios > 0 ? '+' : ''}{formatNumber(embalses_hoy[0]?.dif_vs_media_10_anios, 1)} pp vs. media de 10 años"
        source="MITECO"
        href="/energia-clima/embalses"
        sparklineData={embalses}
    />
    <KpiCard
        title="Coches nuevos enchufables"
        value={enchufables.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(enchufables.slice(-1)[0]?.valor / 0.01, 1)} %"
        period="eléctricos + híbridos enchufables · último mes"
        source="DGT"
        href="/movilidad/coche-electrico"
        sparklineData={enchufables}
    />
    <KpiCard
        title="Esperanza de vida"
        value={vida.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(vida.slice(-1)[0]?.valor, 1)} años"
        period="al nacer · {vida.slice(-1)[0]?.anio}"
        source="INE / Eurostat"
        href="/sociedad/salud"
        sparklineData={vida}
    />
</Grid>

## Compara las comunidades

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
SELECT c.cod, c.nombre, c.ruta, x.valor
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
    <ButtonGroupItem valueLabel="Crecimiento de la población" value="crecimiento" default />
    <ButtonGroupItem valueLabel="Esperanza de vida" value="vida" />
    <ButtonGroupItem valueLabel="Delitos" value="crimen" />
    <ButtonGroupItem valueLabel="Empleados públicos" value="empleo" />
    <ButtonGroupItem valueLabel="Coches enchufables" value="enchufables" />
    <ButtonGroupItem valueLabel="Deuda" value="deuda" />
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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'valor', title: 'Valor', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">
{#if inputs.indicador_mapa === 'crecimiento'}Crecimiento de la población en los últimos 10 años (%), padrón del INE.{/if}
{#if inputs.indicador_mapa === 'vida'}Esperanza de vida al nacer (años), INE.{/if}
{#if inputs.indicador_mapa === 'crimen'}Infracciones penales conocidas por 1.000 habitantes en el último año, Ministerio del Interior. Las comunidades turísticas salen más altas porque los visitantes no cuentan en el denominador.{/if}
{#if inputs.indicador_mapa === 'empleo'}Empleados de las tres administraciones con puesto en la comunidad por 1.000 habitantes, Registro Central de Personal.{/if}
{#if inputs.indicador_mapa === 'enchufables'}Porcentaje de eléctricos e híbridos enchufables entre los turismos nuevos de los últimos 12 meses, DGT.{/if}
{#if inputs.indicador_mapa === 'deuda'}Deuda de la comunidad autónoma en % de su PIB, Banco de España. Ceuta y Melilla no tienen deuda autonómica propia.{/if}
Pulsa en una comunidad para abrir su ficha.
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
    <a href="/territorios" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🗺️</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Territorios</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Cada comunidad, provincia y municipio: población, cuentas, deuda, quién gobierna, empleo público y seguridad.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">19 comunidades · {cabeceras[0]?.provincias} provincias · +8.100 municipios →</p>
    </a>
    <a href="/demografia" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">👪</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Demografía</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Evolución de la población, natalidad y fecundidad, envejecimiento, hogares y pirámide de cualquier provincia.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatCompact(poblacion.slice(-1)[0]?.valor, 2)} habitantes →</p>
    </a>
    <a href="/economia" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">💼</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Economía</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">PIB por habitante, sectores, comercio exterior, salarios reales, paro, inflación y precio de la energía, turismo y empresas.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Paro: {formatNumber(ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor, 1)} % →</p>
    </a>
    <a href="/vivienda" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🏠</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Vivienda</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Precio de compra y alquiler descontada la inflación, cuántos años de sueldo cuesta una casa, compraventas, hipotecas y obra nueva.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Precios, alquiler y esfuerzo →</p>
    </a>
    <a href="/cuentas-publicas" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🏛️</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Cuentas públicas</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Ingresos, gastos, déficit y deuda de todas las administraciones, pensiones y empleo público: cuántos son, cuánto cobran y cuánto cuestan.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatCompact(cabeceras[0]?.empleados, 2)} empleados públicos →</p>
    </a>
    <a href="/energia-clima" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">⚡</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Energía y clima</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">La electricidad en directo y sus récords, centrales, almacenamiento, electrificación, emisiones, embalses, incendios y calor.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatNumber(100 * renovables_30[0]?.cuota, 0)} % renovable en el último mes →</p>
    </a>
    <a href="/movilidad" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🚗</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Movilidad</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Coches que se venden y circulan, el avance del eléctrico, marcas y modelos, puntos de recarga y transporte público.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatNumber(cabeceras[0]?.puntos_recarga, 0)} puntos de recarga públicos →</p>
    </a>
    <a href="/sociedad" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">👥</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Sociedad</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Criminalidad, salud, inmigración, renta y pobreza hasta el nivel de municipio, y educación.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{formatNumber(cabeceras[0]?.delitos_1000, 1)} delitos conocidos por 1.000 hab. →</p>
    </a>
    <a href="/transparencia" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">🔎</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Transparencia</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Qué ayuntamientos no rinden cuentas a Hacienda, a quién se le retienen fondos del Estado y quién paga tarde a sus proveedores.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">Por municipio y por partido →</p>
    </a>
    <a href="/fuentes" class="group rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <p class="text-2xl mb-1" aria-hidden="true">📚</p>
        <p class="text-lg font-bold text-gray-900 dark:text-white">Fuentes</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">De dónde sale cada dato: organismo, tabla oficial, frecuencia, licencia y metodología.</p>
        <p class="mt-3 text-sm font-semibold text-blue-600 dark:text-blue-400">{cabeceras[0]?.fuentes} conjuntos de datos oficiales →</p>
    </a>
</div>

## Cómo trabajamos

<div class="not-prose grid grid-cols-1 md:grid-cols-3 gap-4 my-4">
    <div class="rounded-2xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 p-5">
        <p class="font-bold text-gray-900 dark:text-white mb-1">Solo fuentes oficiales</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">INE, Banco de España, Eurostat, ministerios, REE, DGT, AEMET… Cada gráfico enlaza a su tabla de origen.</p>
    </div>
    <div class="rounded-2xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 p-5">
        <p class="font-bold text-gray-900 dark:text-white mb-1">Contexto, no opinión</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">Explicamos qué mide cada cifra y qué no, sin juicios políticos: tú sacas las conclusiones.</p>
    </div>
    <div class="rounded-2xl bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 p-5">
        <p class="font-bold text-gray-900 dark:text-white mb-1">Abierto y automático</p>
        <p class="text-sm text-gray-600 dark:text-gray-400">Los datos se descargan y se publican solos cada día; el código es público y cualquiera puede revisarlo.</p>
    </div>
</div>

<LastRefreshed prefix="Última actualización de los datos" />
