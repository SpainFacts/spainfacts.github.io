---
title: SpainFacts · El Estado de España en Datos Oficiales
description: "España en datos oficiales: población, economía, cuentas públicas, energía, movilidad, sociedad y transparencia, de España a cada municipio. Independiente y sin sesgo partidista."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../src/lib/components/MapaEspana.svelte';
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

<div class="not-prose sf-hero rounded-2xl text-white px-6 py-8 md:px-10 md:py-12 mb-10 shadow-xl border border-slate-800/80">
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
        <div class="lg:col-span-7">
            <p class="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/10 px-3 py-1 text-xs font-semibold text-blue-100 mb-5">
                <span class="h-2 w-2 rounded-full bg-emerald-400 animate-pulse"></span>
                Fuentes oficiales y documentadas · independiente · sin sesgo partidista
            </p>
            <h1 class="font-editorial text-3xl md:text-5xl font-bold tracking-tight leading-tight mb-4 text-white">
                España, <span class="underline decoration-[var(--sf-accent)] decoration-2 underline-offset-4 text-blue-200">en datos</span>.<br class="hidden sm:inline"/> De todo el país a tu municipio.
            </h1>
            <p class="text-base md:text-lg text-slate-300 leading-relaxed mb-6">
                Población, economía, cuentas públicas, energía y vida cotidiana: cifras oficiales en euros constantes y por habitante, con contexto y enlace directo a su origen.
            </p>
            <BuscadorInicio opciones={lista_municipios} />
            <div class="mt-5 flex flex-wrap gap-2 text-xs sm:text-sm">
                <a href="/analisis" class="inline-flex items-center gap-1.5 rounded-lg bg-blue-500/30 border border-blue-400/40 px-3 py-1.5 font-semibold text-white hover:bg-blue-500/40 transition no-underline">
                    <svg class="h-4 w-4 text-blue-200" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                    Análisis en datos
                </a>
                <a href="/territorios" class="inline-flex items-center gap-1.5 rounded-lg bg-white/10 border border-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 transition no-underline">
                    <svg class="h-4 w-4 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7"/></svg>
                    Territorios
                </a>
                <a href="/energia-clima/directo" class="inline-flex items-center gap-1.5 rounded-lg bg-white/10 border border-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 transition no-underline">
                    <svg class="h-4 w-4 text-emerald-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z"/></svg>
                    Electricidad ahora
                </a>
                <a href="/movilidad/marcas-y-modelos" class="inline-flex items-center gap-1.5 rounded-lg bg-white/10 border border-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 transition no-underline">
                    <svg class="h-4 w-4 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
                    Coches más vendidos
                </a>
                <a href="/transparencia" class="inline-flex items-center gap-1.5 rounded-lg bg-white/10 border border-white/10 px-3 py-1.5 font-semibold text-white hover:bg-white/20 transition no-underline">
                    <svg class="h-4 w-4 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z"/></svg>
                    Transparencia
                </a>
            </div>
        </div>

        <div class="lg:col-span-5">
            <div class="rounded-xl bg-white/5 backdrop-blur-sm border border-white/15 p-5 space-y-3.5">
                <div class="flex items-center justify-between border-b border-white/10 pb-2.5">
                    <span class="inline-flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-white">
                        <span class="h-2 w-2 rounded-full bg-emerald-400"></span>
                        Pulso de España
                    </span>
                    <a href="/energia-clima/directo" class="text-xs font-medium text-blue-200 hover:text-white no-underline">Ver en directo →</a>
                </div>

                <a href="/energia-clima/mix-electrico" class="flex items-center justify-between rounded-lg bg-white/5 hover:bg-white/10 p-3 border border-white/5 transition no-underline">
                    <div>
                        <p class="text-xs font-semibold text-white">Generación eléctrica renovable</p>
                        <p class="text-xs text-slate-300">Últimos 30 días · Red Eléctrica (REE)</p>
                    </div>
                    <div class="text-right tabular-nums">
                        <span class="text-lg font-extrabold text-emerald-300">{formatNumber(renovables_30[0]?.cuota / 0.01, 0)} %</span>
                    </div>
                </a>

                <a href="/energia-clima/embalses" class="flex items-center justify-between rounded-lg bg-white/5 hover:bg-white/10 p-3 border border-white/5 transition no-underline">
                    <div>
                        <p class="text-xs font-semibold text-white">Reserva de agua embalsada</p>
                        <p class="text-xs text-slate-300">{embalses_hoy[0]?.fecha_txt} · MITECO</p>
                    </div>
                    <div class="text-right tabular-nums">
                        <span class="text-lg font-extrabold text-sky-300">{formatNumber(embalses_hoy[0]?.pct_llenado, 1)} %</span>
                    </div>
                </a>

                <a href="/movilidad/coche-electrico" class="flex items-center justify-between rounded-lg bg-white/5 hover:bg-white/10 p-3 border border-white/5 transition no-underline">
                    <div>
                        <p class="text-xs font-semibold text-white">Turismos nuevos enchufables</p>
                        <p class="text-xs text-slate-300">Último mes · DGT</p>
                    </div>
                    <div class="text-right tabular-nums">
                        <span class="text-lg font-extrabold text-amber-300">{formatNumber(enchufables.slice(-1)[0]?.valor / 0.01, 1)} %</span>
                    </div>
                </a>

                <div class="pt-1 flex items-center justify-between text-xs text-slate-300">
                    <span>{cabeceras[0]?.fuentes} conjuntos de datos oficiales</span>
                    <a href="/fuentes" class="font-semibold text-white underline decoration-blue-400">Catálogo y método →</a>
                </div>
            </div>
        </div>
    </div>
</div>

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
        source="INE · Padrón"
        href="/demografia"
        sparklineData={poblacion}
    />
    <KpiCard
        title="Tasa de paro"
        value={ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor, 1)} %"
        period={ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.periodo_txt}
        change={metricas.filter(d => d.metrica_id === 'tasa_paro').slice(-5).length === 5 ? (metricas.filter(d => d.metrica_id === 'tasa_paro').slice(-1)[0].valor - metricas.filter(d => d.metrica_id === 'tasa_paro').slice(-5)[0].valor).toFixed(1) : null}
        changeUnit=" p.p."
        changePeriod="en un año"
        direction="positive-down"
        source="INE (EPA)"
        href="/economia/paro"
        sparklineData={metricas.filter(d => d.metrica_id === 'tasa_paro')}
    />
    <KpiCard
        title="Inflación"
        value={ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.valor, 1)} %"
        period="IPC interanual · {ultimas_metricas.find(d => d.metrica_id === 'ipc_variacion_anual')?.periodo_txt}"
        change={metricas.filter(d => d.metrica_id === 'ipc_variacion_anual').slice(-2).length === 2 ? (metricas.filter(d => d.metrica_id === 'ipc_variacion_anual').slice(-1)[0].valor - metricas.filter(d => d.metrica_id === 'ipc_variacion_anual').slice(-2)[0].valor).toFixed(1) : null}
        changeUnit=" p.p."
        changePeriod="vs mes ant."
        direction="positive-down"
        source="INE"
        href="/economia/ipc"
        sparklineData={metricas.filter(d => d.metrica_id === 'ipc_variacion_anual').slice(-60)}
    />
    <KpiCard
        title="Deuda pública"
        value={ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.valor}
        formattedValue="{formatNumber(ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.valor, 1)} % del PIB"
        period={ultimas_metricas.find(d => d.metrica_id === 'deuda_publica_pib')?.periodo_txt}
        change={metricas.filter(d => d.metrica_id === 'deuda_publica_pib').slice(-5).length === 5 ? (metricas.filter(d => d.metrica_id === 'deuda_publica_pib').slice(-1)[0].valor - metricas.filter(d => d.metrica_id === 'deuda_publica_pib').slice(-5)[0].valor).toFixed(1) : null}
        changeUnit=" p.p."
        changePeriod="en un año"
        direction="positive-down"
        source="Eurostat / BdE"
        href="/cuentas-publicas"
        sparklineData={metricas.filter(d => d.metrica_id === 'deuda_publica_pib')}
    />
    <KpiCard
        title="Electricidad renovable"
        value={renovables_30[0]?.cuota}
        formattedValue="{formatNumber(renovables_30[0]?.cuota / 0.01, 0)} %"
        period="de la generación de los últimos 30 días"
        change={renovables_mes.slice(-13).length === 13 ? (100 * (renovables_mes.slice(-1)[0].valor - renovables_mes.slice(-13)[0].valor)).toFixed(1) : null}
        changeUnit=" p.p."
        changePeriod="interanual"
        direction="positive-up"
        source="REE"
        href="/energia-clima/mix-electrico"
        sparklineData={renovables_mes.slice(-36)}
    />
    <KpiCard
        title="Reserva de agua embalsada"
        value={embalses_hoy[0]?.pct_llenado}
        formattedValue="{formatNumber(embalses_hoy[0]?.pct_llenado, 1)} %"
        period="{embalses_hoy[0]?.fecha_txt}"
        change={embalses_hoy[0]?.dif_vs_media_10_anios?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="vs media 10 años"
        direction="positive-up"
        source="MITECO"
        href="/energia-clima/embalses"
        sparklineData={embalses}
    />
    <KpiCard
        title="Coches nuevos enchufables"
        value={enchufables.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(enchufables.slice(-1)[0]?.valor / 0.01, 1)} %"
        period="eléctricos + híbridos enchufables · último mes"
        change={enchufables.slice(-13).length === 13 ? (100 * (enchufables.slice(-1)[0].valor - enchufables.slice(-13)[0].valor)).toFixed(1) : null}
        changeUnit=" p.p."
        changePeriod="en un año"
        direction="positive-up"
        source="DGT"
        href="/movilidad/coche-electrico"
        sparklineData={enchufables}
    />
    <KpiCard
        title="Esperanza de vida"
        value={vida.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(vida.slice(-1)[0]?.valor, 1)} años"
        period="al nacer · {vida.slice(-1)[0]?.anio}"
        change={vida.slice(-2).length === 2 ? (vida.slice(-1)[0].valor - vida.slice(-2)[0].valor).toFixed(1) : null}
        changeUnit=" años"
        changePeriod="en un año"
        direction="positive-up"
        source="INE / Eurostat"
        href="/sociedad/salud"
        sparklineData={vida}
    />
</Grid>

<p class="my-3 text-sm text-gray-600 dark:text-gray-400">
    La población destacada aquí usa el Padrón del INE a 1 de enero. La sección de <a href="/demografia">Demografía</a> también muestra la Estadística Continua de Población, una serie distinta; por eso sus cifras pueden diferir ligeramente.
</p>

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

<div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start my-4">
    <div class="lg:col-span-7">
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
            attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional"
            tooltip={[
                {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
                {id: 'valor', title: 'Valor', fmt: 'num1'}
            ]}
        />
        <p class="text-xs text-gray-500 mt-2">
        {#if inputs.indicador_mapa === 'crecimiento'}Crecimiento de la población en los últimos 10 años (%), padrón del INE.{/if}
        {#if inputs.indicador_mapa === 'vida'}Esperanza de vida al nacer (años), INE.{/if}
        {#if inputs.indicador_mapa === 'crimen'}Infracciones penales conocidas por 1.000 habitantes en el último año, Ministerio del Interior. Las comunidades turísticas salen más altas porque los visitantes no cuentan en el denominador.{/if}
        {#if inputs.indicador_mapa === 'empleo'}Empleados de las tres administraciones con puesto en la comunidad por 1.000 habitantes, Registro Central de Personal.{/if}
        {#if inputs.indicador_mapa === 'enchufables'}Porcentaje de eléctricos e híbridos enchufables entre los turismos nuevos de los últimos 12 meses, DGT.{/if}
        {#if inputs.indicador_mapa === 'deuda'}Deuda de la comunidad autónoma en % de su PIB, Banco de España. Ceuta y Melilla no tienen deuda autonómica propia.{/if}
        Pulsa en una comunidad para abrir su ficha.
        </p>
    </div>

    <div class="lg:col-span-5 not-prose rounded-xl border border-[var(--sf-border)] bg-[var(--sf-bg-card)] p-5 shadow-xs">
        <div class="flex items-center justify-between border-b border-[var(--sf-border)] pb-3 mb-3">
            <span class="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Clasificación autonómica</span>
            <a href="/territorios" class="text-xs font-semibold sf-brand-accent no-underline hover:underline">Ver todas las CCAA →</a>
        </div>
        {#if mapa_ccaa.length}
            {@const ordenadas = [...mapa_ccaa].filter(d => d.valor != null && Number.isFinite(Number(d.valor))).sort((a, b) => Number(b.valor) - Number(a.valor))}
            {@const maxVal = Math.max(...ordenadas.map(d => Math.abs(Number(d.valor))), 1)}
            {@const sufijo = inputs.indicador_mapa === 'vida' ? ' años' : (inputs.indicador_mapa === 'crimen' || inputs.indicador_mapa === 'empleo') ? ' /1.000' : ' %'}
            <div class="space-y-2.5 text-xs">
                <p class="text-xs font-semibold text-gray-500 dark:text-gray-400">Valores más altos</p>
                {#each ordenadas.slice(0, 4) as item, idx}
                    <a href={item.ruta} class="block group no-underline">
                        <div class="flex justify-between items-baseline mb-1">
                            <span class="font-medium text-gray-800 dark:text-gray-200 group-hover:text-blue-600 dark:group-hover:text-blue-400 truncate">{idx + 1}. {item.nombre}</span>
                            <span class="font-bold text-gray-900 dark:text-white tabular-nums ml-2">{formatNumber(item.valor, 1)}{sufijo}</span>
                        </div>
                        <div class="h-1.5 w-full rounded-full bg-[var(--sf-bg-subtle)] overflow-hidden">
                            <div class="h-full rounded-full" style="width: {Math.max(8, Math.min(100, (Math.abs(Number(item.valor)) / maxVal) * 100))}%; background-color: var(--sf-accent);"></div>
                        </div>
                    </a>
                {/each}

                <div class="border-t border-[var(--sf-border)] my-3 pt-2">
                    <p class="text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2">Valores más bajos</p>
                    <div class="space-y-2.5">
                        {#each ordenadas.slice(-3) as item, idx}
                            <a href={item.ruta} class="block group no-underline">
                                <div class="flex justify-between items-baseline mb-1">
                                    <span class="font-medium text-gray-700 dark:text-gray-300 group-hover:text-blue-600 dark:group-hover:text-blue-400 truncate">{ordenadas.length - 2 + idx}. {item.nombre}</span>
                                    <span class="font-bold text-gray-900 dark:text-white tabular-nums ml-2">{formatNumber(item.valor, 1)}{sufijo}</span>
                                </div>
                                <div class="h-1.5 w-full rounded-full bg-[var(--sf-bg-subtle)] overflow-hidden">
                                    <div class="h-full rounded-full opacity-55" style="width: {Math.max(6, Math.min(100, (Math.abs(Number(item.valor)) / maxVal) * 100))}%; background-color: var(--sf-accent);"></div>
                                </div>
                            </a>
                        {/each}
                    </div>
                </div>
            </div>
        {/if}
    </div>
</div>

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
    <a href="/territorios" class="sf-subtopic-card group" style="--sf-card-accent: #1e3a8a;">
        <div>
            <div class="flex items-center gap-3 mb-2.5">
                <span class="sf-icon-box" style="background-color: rgba(30, 58, 138, 0.1); color: #1e3a8a;">
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7"/></svg>
                </span>
                <p class="font-editorial text-lg font-bold text-gray-900 dark:text-white">Territorios</p>
            </div>
            <p class="text-sm text-gray-600 dark:text-gray-400">Cada comunidad, provincia y municipio: población, cuentas, deuda, quién gobierna, empleo público y seguridad.</p>
        </div>
        <p class="mt-4 pt-3 border-t border-[var(--sf-border)] text-xs font-bold sf-brand-accent tabular-nums">19 comunidades · {cabeceras[0]?.provincias} provincias · +8.100 municipios →</p>
    </a>

    <a href="/demografia" class="sf-subtopic-card group" style="--sf-card-accent: #4338ca;">
        <div>
            <div class="flex items-center gap-3 mb-2.5">
                <span class="sf-icon-box" style="background-color: rgba(67, 56, 202, 0.1); color: #4338ca;">
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
                </span>
                <p class="font-editorial text-lg font-bold text-gray-900 dark:text-white">Demografía</p>
            </div>
            <p class="text-sm text-gray-600 dark:text-gray-400">Evolución de la población, natalidad y fecundidad, envejecimiento, hogares y pirámide de cualquier provincia.</p>
        </div>
        <p class="mt-4 pt-3 border-t border-[var(--sf-border)] text-xs font-bold sf-brand-accent tabular-nums">{formatCompact(poblacion.slice(-1)[0]?.valor, 2)} habitantes →</p>
    </a>

    <a href="/economia" class="sf-subtopic-card group" style="--sf-card-accent: #0f4c81;">
        <div>
            <div class="flex items-center gap-3 mb-2.5">
                <span class="sf-icon-box" style="background-color: rgba(15, 76, 129, 0.1); color: #0f4c81;">
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
                </span>
                <p class="font-editorial text-lg font-bold text-gray-900 dark:text-white">Economía</p>
            </div>
            <p class="text-sm text-gray-600 dark:text-gray-400">PIB por habitante, sectores, comercio exterior, salarios reales, paro, inflación y precio de la energía, turismo y empresas.</p>
        </div>
        <p class="mt-4 pt-3 border-t border-[var(--sf-border)] text-xs font-bold sf-brand-accent tabular-nums">Paro: {formatNumber(ultimas_metricas.find(d => d.metrica_id === 'tasa_paro')?.valor, 1)} % →</p>
    </a>

    <a href="/vivienda" class="sf-subtopic-card group" style="--sf-card-accent: #b45309;">
        <div>
            <div class="flex items-center gap-3 mb-2.5">
                <span class="sf-icon-box" style="background-color: rgba(180, 83, 9, 0.1); color: #b45309;">
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>
                </span>
                <p class="font-editorial text-lg font-bold text-gray-900 dark:text-white">Vivienda</p>
            </div>
            <p class="text-sm text-gray-600 dark:text-gray-400">Precio de compra y alquiler descontada la inflación, cuántos años de sueldo cuesta una casa, compraventas, hipotecas y obra nueva.</p>
        </div>
        <p class="mt-4 pt-3 border-t border-[var(--sf-border)] text-xs font-bold sf-brand-accent">Precios, alquiler y esfuerzo →</p>
    </a>

    <a href="/cuentas-publicas" class="sf-subtopic-card group" style="--sf-card-accent: #5b21b6;">
        <div>
            <div class="flex items-center gap-3 mb-2.5">
                <span class="sf-icon-box" style="background-color: rgba(91, 33, 182, 0.1); color: #5b21b6;">
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M8 14v3m4-3v3m4-3v3M3 21h18M3 10h18M3 7l9-4 9 4M4 10h16v11H4V10z"/></svg>
                </span>
                <p class="font-editorial text-lg font-bold text-gray-900 dark:text-white">Cuentas públicas</p>
            </div>
            <p class="text-sm text-gray-600 dark:text-gray-400">Ingresos, gastos, déficit y deuda de todas las administraciones, pensiones y empleo público: cuántos son, cuánto cobran y cuánto cuestan.</p>
        </div>
        <p class="mt-4 pt-3 border-t border-[var(--sf-border)] text-xs font-bold sf-brand-accent tabular-nums">{formatCompact(cabeceras[0]?.empleados, 2)} empleados públicos →</p>
    </a>

    <a href="/energia-clima" class="sf-subtopic-card group" style="--sf-card-accent: #047857;">
        <div>
            <div class="flex items-center gap-3 mb-2.5">
                <span class="sf-icon-box" style="background-color: rgba(4, 120, 87, 0.1); color: #047857;">
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z"/></svg>
                </span>
                <p class="font-editorial text-lg font-bold text-gray-900 dark:text-white">Energía y clima</p>
            </div>
            <p class="text-sm text-gray-600 dark:text-gray-400">La electricidad en directo y sus récords, centrales, almacenamiento, electrificación, emisiones, embalses, incendios y calor.</p>
        </div>
        <p class="mt-4 pt-3 border-t border-[var(--sf-border)] text-xs font-bold sf-brand-accent tabular-nums">{formatNumber(100 * renovables_30[0]?.cuota, 0)} % renovable en el último mes →</p>
    </a>

    <a href="/movilidad" class="sf-subtopic-card group" style="--sf-card-accent: #0f766e;">
        <div>
            <div class="flex items-center gap-3 mb-2.5">
                <span class="sf-icon-box" style="background-color: rgba(15, 118, 110, 0.1); color: #0f766e;">
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M8 7h8m-8 5h8m-4 5v3m-6-3h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v9a2 2 0 002 2z"/></svg>
                </span>
                <p class="font-editorial text-lg font-bold text-gray-900 dark:text-white">Movilidad</p>
            </div>
            <p class="text-sm text-gray-600 dark:text-gray-400">Coches que se venden y circulan, el avance del eléctrico, marcas y modelos, puntos de recarga y transporte público.</p>
        </div>
        <p class="mt-4 pt-3 border-t border-[var(--sf-border)] text-xs font-bold sf-brand-accent tabular-nums">{formatNumber(cabeceras[0]?.puntos_recarga, 0)} puntos de recarga públicos →</p>
    </a>

    <a href="/sociedad" class="sf-subtopic-card group" style="--sf-card-accent: #9d174d;">
        <div>
            <div class="flex items-center gap-3 mb-2.5">
                <span class="sf-icon-box" style="background-color: rgba(157, 23, 77, 0.1); color: #9d174d;">
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/></svg>
                </span>
                <p class="font-editorial text-lg font-bold text-gray-900 dark:text-white">Sociedad</p>
            </div>
            <p class="text-sm text-gray-600 dark:text-gray-400">Criminalidad, salud, inmigración, renta y pobreza hasta el nivel de municipio, y educación.</p>
        </div>
        <p class="mt-4 pt-3 border-t border-[var(--sf-border)] text-xs font-bold sf-brand-accent tabular-nums">{formatNumber(cabeceras[0]?.delitos_1000, 1)} delitos conocidos por 1.000 hab. →</p>
    </a>

    <a href="/medios" class="sf-subtopic-card group">
        <div>
            <div class="flex items-center gap-3 mb-2.5">
                <span class="sf-icon-box">
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"/></svg>
                </span>
                <p class="font-editorial text-lg font-bold text-gray-900 dark:text-white">Medios de comunicación</p>
            </div>
            <p class="text-sm text-gray-600 dark:text-gray-400">Cuánto dinero público reciben los medios: televisiones públicas, publicidad institucional y subvenciones, por comunidad y por partido.</p>
        </div>
        <p class="mt-4 pt-3 border-t border-[var(--sf-border)] text-xs font-bold sf-brand-accent">Dinero público en los medios →</p>
    </a>

    <a href="/transparencia" class="sf-subtopic-card group">
        <div>
            <div class="flex items-center gap-3 mb-2.5">
                <span class="sf-icon-box">
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z"/></svg>
                </span>
                <p class="font-editorial text-lg font-bold text-gray-900 dark:text-white">Transparencia</p>
            </div>
            <p class="text-sm text-gray-600 dark:text-gray-400">Qué ayuntamientos no rinden cuentas a Hacienda, a quién se le retienen fondos del Estado y quién paga tarde a sus proveedores.</p>
        </div>
        <p class="mt-4 pt-3 border-t border-[var(--sf-border)] text-xs font-bold sf-brand-accent">Por municipio y por partido →</p>
    </a>

    <a href="/fuentes" class="sf-subtopic-card group">
        <div>
            <div class="flex items-center gap-3 mb-2.5">
                <span class="sf-icon-box">
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/></svg>
                </span>
                <p class="font-editorial text-lg font-bold text-gray-900 dark:text-white">Fuentes</p>
            </div>
            <p class="text-sm text-gray-600 dark:text-gray-400">De dónde sale cada dato: organismo, tabla oficial, frecuencia, licencia y metodología.</p>
        </div>
        <p class="mt-4 pt-3 border-t border-[var(--sf-border)] text-xs font-bold sf-brand-accent tabular-nums">{cabeceras[0]?.fuentes} conjuntos de datos documentados →</p>
    </a>
</div>

## Análisis y reportajes en datos

Además de los grandes paneles permanentes, publicamos investigaciones y cruces especiales sobre cuestiones de actualidad. [Ver todos los análisis →](/analisis)

<div class="not-prose sf-analysis-section my-4">
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <a href="/varios/diputados-caseros" class="group rounded-xl border border-[var(--sf-border)] border-t-4 border-t-[var(--sf-accent)] bg-[var(--sf-bg-card)] p-5 hover:shadow-md transition flex flex-col justify-between no-underline">
            <div>
                <span class="inline-flex items-center gap-1.5 rounded-full bg-[var(--sf-accent-soft)] px-2.5 py-0.5 text-xs font-bold sf-brand-accent mb-2.5">
                    Parlamento y Vivienda
                </span>
                <p class="font-editorial text-xl font-bold text-gray-900 dark:text-white group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">¿Cuántos diputados son caseros?</p>
                <p class="text-sm text-gray-600 dark:text-gray-400 mt-1.5 leading-relaxed">Cruce de las 350 declaraciones de bienes del Congreso con las estadísticas del IRPF: quién declara rentas de alquiler o varias viviendas por partido.</p>
            </div>
            <p class="mt-4 pt-3 border-t border-[var(--sf-border)] text-xs font-bold sf-brand-accent">Leer investigación →</p>
        </a>

        <a href="/analisis/brecha-vivienda-salarios" class="group rounded-xl border border-[var(--sf-border)] border-t-4 border-t-[#b45309] bg-[var(--sf-bg-card)] p-5 hover:shadow-md transition flex flex-col justify-between no-underline">
            <div>
                <span class="inline-flex items-center gap-1.5 rounded-full bg-amber-100 dark:bg-amber-950/60 px-2.5 py-0.5 text-xs font-bold text-amber-800 dark:text-amber-300 mb-2.5">
                    Vivienda y Salarios
                </span>
                <p class="font-editorial text-xl font-bold text-gray-900 dark:text-white group-hover:text-amber-700 dark:group-hover:text-amber-400 transition-colors">La brecha entre vivienda y salarios</p>
                <p class="text-sm text-gray-600 dark:text-gray-400 mt-1.5 leading-relaxed">Cuántos años de sueldo íntegro cuesta comprar un piso de 90 m² y qué parte del salario absorbe el alquiler en cada comunidad autónoma.</p>
            </div>
            <p class="mt-4 pt-3 border-t border-[var(--sf-border)] text-xs font-bold text-amber-700 dark:text-amber-400">Leer análisis →</p>
        </a>

        <a href="/movilidad/flotas-e-impuestos" class="group rounded-xl border border-[var(--sf-border)] border-t-4 border-t-[#5b21b6] bg-[var(--sf-bg-card)] p-5 hover:shadow-md transition flex flex-col justify-between no-underline">
            <div>
                <span class="inline-flex items-center gap-1.5 rounded-full bg-purple-100 dark:bg-purple-950/60 px-2.5 py-0.5 text-xs font-bold text-purple-800 dark:text-purple-300 mb-2.5">
                    Movilidad y Fiscalidad
                </span>
                <p class="font-editorial text-xl font-bold text-gray-900 dark:text-white group-hover:text-purple-700 dark:group-hover:text-purple-400 transition-colors">¿Quién compra los coches nuevos y dónde tributan?</p>
                <p class="text-sm text-gray-600 dark:text-gray-400 mt-1.5 leading-relaxed">Por qué cuatro de cada diez turismos nuevos los matriculan empresas y por qué pequeños pueblos concentran miles de vehículos de flota.</p>
            </div>
            <p class="mt-4 pt-3 border-t border-[var(--sf-border)] text-xs font-bold text-purple-700 dark:text-purple-400">Leer análisis →</p>
        </a>

        <a href="/analisis/revolucion-renovable" class="group rounded-xl border border-[var(--sf-border)] border-t-4 border-t-[#047857] bg-[var(--sf-bg-card)] p-5 hover:shadow-md transition flex flex-col justify-between no-underline">
            <div>
                <span class="inline-flex items-center gap-1.5 rounded-full bg-emerald-100 dark:bg-emerald-950/60 px-2.5 py-0.5 text-xs font-bold text-emerald-800 dark:text-emerald-300 mb-2.5">
                    Energía y Transición
                </span>
                <p class="font-editorial text-xl font-bold text-gray-900 dark:text-white group-hover:text-emerald-700 dark:group-hover:text-emerald-400 transition-colors">Del carbón a superar el 50 % renovable</p>
                <p class="text-sm text-gray-600 dark:text-gray-400 mt-1.5 leading-relaxed">Cómo el despliegue eólico y fotovoltaico ha cerrado las térmicas de carbón y reducido a un tercio las emisiones de CO₂ por cada kWh eléctrico.</p>
            </div>
            <p class="mt-4 pt-3 border-t border-[var(--sf-border)] text-xs font-bold text-emerald-700 dark:text-emerald-400">Leer análisis →</p>
        </a>
    </div>
</div>

## Pregunta a los datos

Escribe una pregunta sobre las estadísticas. El chat busca respuestas en las tablas de la web; puedes abrir sus opciones si prefieres usar Claude, Ollama u otro proveedor. [Más sobre el chat](/chat).

<Chat perezoso />

## Cómo trabajamos

<div class="not-prose grid grid-cols-1 md:grid-cols-3 gap-4 my-4">
    <div class="rounded-xl bg-[var(--sf-bg-card)] border border-[var(--sf-border)] p-5">
        <div class="flex items-center gap-3 mb-2">
            <span class="sf-icon-box">
                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/></svg>
            </span>
            <p class="font-editorial font-bold text-gray-900 dark:text-white">Fuentes oficiales y documentadas</p>
        </div>
        <p class="text-sm text-gray-600 dark:text-gray-400">INE, Banco de España, Eurostat, ministerios, REE, DGT, AEMET y otras fuentes identificadas. Cada gráfico enlaza a su origen.</p>
    </div>
    <div class="rounded-xl bg-[var(--sf-bg-card)] border border-[var(--sf-border)] p-5">
        <div class="flex items-center gap-3 mb-2">
            <span class="sf-icon-box">
                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3"/></svg>
            </span>
            <p class="font-editorial font-bold text-gray-900 dark:text-white">Contexto, no opinión</p>
        </div>
        <p class="text-sm text-gray-600 dark:text-gray-400">Explicamos qué mide cada cifra y qué no, sin juicios políticos: tú sacas las conclusiones.</p>
    </div>
    <div class="rounded-xl bg-[var(--sf-bg-card)] border border-[var(--sf-border)] p-5">
        <div class="flex items-center gap-3 mb-2">
            <span class="sf-icon-box">
                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/></svg>
            </span>
            <p class="font-editorial font-bold text-gray-900 dark:text-white">Abierto y automático</p>
        </div>
        <p class="text-sm text-gray-600 dark:text-gray-400">Los datos se descargan y se publican solos cada día; el código es público y cualquiera puede revisarlo.</p>
    </div>
</div>

<LastRefreshed prefix="Última publicación del sitio" />
