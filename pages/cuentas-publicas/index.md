---
description: "Ingresos, gastos, déficit y deuda de las administraciones públicas españolas, por habitante, descontada la inflación y en porcentaje del PIB."
title: Cuentas Públicas · El Informe Anual de España
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber, formatCurrency, formatCompact } from '../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../src/lib/components/Comparativa.svelte';
    import SankeyPresupuesto from '../../../../../src/lib/components/SankeyPresupuesto.svelte';
</script>

<div class="sf-topic-banner not-prose">
    <div class="mb-3 flex flex-wrap items-center gap-2 text-xs font-medium text-slate-500 dark:text-slate-400">
        <a href="/" class="hover:underline text-slate-500 dark:text-slate-400 no-underline">Inicio</a>
        <span>/</span>
        <span class="font-semibold" style="color: var(--sf-topic-color)">Cuentas públicas</span>
    </div>
    <div class="flex items-start gap-3.5">
        <div class="sf-icon-box mt-1">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="22" x2="21" y2="22"/><line x1="6" y1="18" x2="6" y2="11"/><line x1="10" y1="18" x2="10" y2="11"/><line x1="14" y1="18" x2="14" y2="11"/><line x1="18" y1="18" x2="18" y2="11"/><polygon points="12 2 20 7 4 7"/></svg>
        </div>
        <div>
            <h1 class="font-editorial text-2xl sm:text-3xl font-bold tracking-tight text-slate-900 dark:text-white m-0">Cuentas públicas de España: el informe anual</h1>
            <p class="mt-1.5 text-sm sm:text-base text-slate-600 dark:text-slate-300 leading-relaxed m-0">
                Como la memoria anual de una empresa, pero para el conjunto de las administraciones públicas (Estado, comunidades autónomas, ayuntamientos y Seguridad Social): <em>¿cuánto ingresa el Estado? ¿en qué se gasta el dinero de los contribuyentes? ¿cuál es el déficit anual y cómo evoluciona la deuda pública?</em>
            </p>
        </div>
    </div>
    <div class="mt-4 pt-3 border-t border-slate-200/80 dark:border-slate-800 flex flex-wrap items-center gap-2 text-xs text-slate-500 dark:text-slate-400">
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Por habitante</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">Euros constantes y % PIB</span>
        <span class="inline-flex items-center gap-1 rounded-md bg-slate-100 dark:bg-slate-800/80 px-2 py-0.5 font-medium text-slate-700 dark:text-slate-300">IGAE · Banco de España · Eurostat</span>
    </div>
</div>

```sql base_deflactor
-- Año cuyos euros se usan como referencia (último año completo con IPC)
SELECT CAST(max(anio_base) AS INTEGER) AS anio_base FROM mother.deflactor
```

```sql balance_reciente
-- Importes por habitante y en euros constantes (ya calculados en la tabla)
SELECT
    b.anio,
    b.ingresos_totales_mrd,
    b.gastos_totales_mrd,
    b.saldo_deficit_mrd,
    b.saldo_deficit_pib,
    b.deuda_publica_mrd,
    b.deuda_pib,
    b.ingresos_eur_hab_real AS ingresos_hab_real,
    b.gastos_eur_hab_real AS gastos_hab_real
FROM mother.cuentas_balance_anual b
ORDER BY b.anio DESC
LIMIT 2
```

```sql serie_balance_historico
-- Euros por habitante a precios constantes (el deflactor empieza en 1996)
SELECT
    b.anio AS año,
    b.ingresos_eur_hab_real AS "Ingresos por habitante",
    b.gastos_eur_hab_real AS "Gastos por habitante",
    b.saldo_eur_hab_real AS "Déficit / Superávit por habitante"
FROM mother.cuentas_balance_anual b
WHERE b.ingresos_eur_hab_real IS NOT NULL
ORDER BY año ASC
```

```sql serie_deficit_pib
SELECT
    anio AS año,
    saldo_deficit_pib AS deficit_pib
FROM mother.cuentas_balance_anual
ORDER BY año ASC
```

```sql serie_deuda_pib
SELECT
    anio AS año,
    deuda_pib
FROM mother.cuentas_balance_anual
ORDER BY año ASC
```

```sql sankey_anio
-- Último ejercicio con desglose publicado tanto de ingresos como de gastos
SELECT least(
    (SELECT max(anio) FROM mother.cuentas_ingresos),
    (SELECT max(anio) FROM mother.cuentas_gastos)
) AS anio
```

```sql ingresos_sankey
SELECT
    categoria,
    millones_euros
FROM mother.cuentas_ingresos
WHERE anio = (SELECT least(max(i.anio), (SELECT max(g.anio) FROM mother.cuentas_gastos g)) FROM mother.cuentas_ingresos i)
ORDER BY millones_euros DESC
```

```sql gastos_sankey
SELECT
    funcion_cofog,
    millones_euros
FROM mother.cuentas_gastos
WHERE anio = (SELECT least(max(g.anio), (SELECT max(i.anio) FROM mother.cuentas_ingresos i)) FROM mother.cuentas_gastos g)
ORDER BY millones_euros DESC
```

```sql subsectores_ultimo
SELECT
    s.anio,
    s.subsector,
    s.gasto_mrd,
    s.ingreso_mrd,
    s.saldo_deficit_mrd,
    s.peso_gasto_pct,
    s.gasto_eur_hab_real AS gasto_hab_real,
    s.saldo_eur_hab_real AS saldo_hab_real
FROM mother.cuentas_subsectores s
WHERE s.anio = (SELECT max(anio) FROM mother.cuentas_subsectores)
ORDER BY s.gasto_mrd DESC
```

```sql rango_historico
-- Rango de la serie en euros constantes por habitante
SELECT min(año) AS desde, max(año) AS hasta
FROM ${serie_balance_historico}
```

```sql serie_balance_real
-- Para las mini-gráficas: euros por habitante a precios constantes (mother.deflactor)
SELECT
    año AS anio,
    "Ingresos por habitante" AS ingresos_hab_real,
    "Gastos por habitante" AS gastos_hab_real
FROM ${serie_balance_historico}
ORDER BY anio
```

<!-- KPI Ribbon: Resumen Anual del Estado -->
<Grid cols=4>
    <KpiCard
        title="Ingresos por habitante"
        value={balance_reciente[0]?.ingresos_hab_real}
        formattedValue="{formatNumber(balance_reciente[0]?.ingresos_hab_real, 0)} €"
        unit="/ hab."
        period="{formatNumber(balance_reciente[0]?.ingresos_totales_mrd, 1)} mil M€ en total · {balance_reciente[0]?.anio} (euros de {base_deflactor[0]?.anio_base})"
        change={(((balance_reciente[0]?.ingresos_hab_real - balance_reciente[1]?.ingresos_hab_real) / balance_reciente[1]?.ingresos_hab_real) * 100).toFixed(1)}
        changeUnit="%"
        changePeriod="interanual, descontada la inflación"
        direction="positive-up"
        source="Eurostat (gov_10a_main)"
        sparklineData={serie_balance_real.filter(d => d.ingresos_hab_real != null).map(d => ({...d, y: d.ingresos_hab_real}))}
        href="/cuentas-publicas/ingresos"
    />

    <KpiCard
        title="Gasto por habitante"
        value={balance_reciente[0]?.gastos_hab_real}
        formattedValue="{formatNumber(balance_reciente[0]?.gastos_hab_real, 0)} €"
        unit="/ hab."
        period="{formatNumber(balance_reciente[0]?.gastos_totales_mrd, 1)} mil M€ en total · {balance_reciente[0]?.anio} (euros de {base_deflactor[0]?.anio_base})"
        change={(((balance_reciente[0]?.gastos_hab_real - balance_reciente[1]?.gastos_hab_real) / balance_reciente[1]?.gastos_hab_real) * 100).toFixed(1)}
        changeUnit="%"
        changePeriod="interanual, descontada la inflación"
        direction="neutral"
        source="Eurostat (gov_10a_main)"
        sparklineData={serie_balance_real.filter(d => d.gastos_hab_real != null).map(d => ({...d, y: d.gastos_hab_real}))}
        href="/cuentas-publicas/gastos"
    />

    <KpiCard
        title="Déficit Fiscal Anual"
        value={balance_reciente[0].saldo_deficit_pib}
        formattedValue="{formatNumber(balance_reciente[0].saldo_deficit_pib, 1)}% PIB"
        period="Ejercicio {balance_reciente[0].anio}"
        change={(balance_reciente[0].saldo_deficit_pib - balance_reciente[1].saldo_deficit_pib).toFixed(1)}
        changeUnit="pp"
        changePeriod="vs año anterior"
        direction="positive-up"
        source="Eurostat (gov_10a_main)"
        sparklineData={serie_deficit_pib.filter(d => d.deficit_pib != null).map(d => ({...d, y: d.deficit_pib}))}
    />

    <KpiCard
        title="Deuda Pública / PIB"
        value={balance_reciente[0].deuda_pib}
        formattedValue="{formatNumber(balance_reciente[0].deuda_pib, 1)}%"
        period="{formatNumber(balance_reciente[0].deuda_publica_mrd, 1)} mil M€ · {balance_reciente[0].anio}"
        change={(balance_reciente[0].deuda_pib - balance_reciente[1].deuda_pib).toFixed(1)}
        changeUnit="pp"
        changePeriod="vs año anterior"
        direction="positive-down"
        source="Eurostat (PDE)"
        sparklineData={serie_deuda_pib.filter(d => d.deuda_pib != null).map(d => ({...d, y: d.deuda_pib}))}
        href="/varios/indicadores/deuda_publica_pib"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('deuda_publica')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'deuda_publica')} />


<p class="text-xs text-gray-500">Principio de esta web: los importes en euros se muestran <b>por habitante</b> (para que no crezcan solo porque crece la población) y <b>descontada la inflación</b>, en euros de {base_deflactor[0]?.anio_base} según el IPC medio anual del INE. Los totales en euros corrientes aparecen como dato secundario. Los porcentajes del PIB no necesitan ajuste.</p>

---

## 1. El Recorrido del Dinero Público (Flujo Presupuestario {sankey_anio[0].anio})

Este diagrama de flujo visualiza de dónde provienen los ingresos de las Administraciones Públicas y en qué partidas concretas se emplean (último ejercicio con desglose completo publicado por Eurostat). La diferencia entre ambos lados es el déficit del año, que se financia con deuda:

<SankeyPresupuesto
    dataIngresos={ingresos_sankey}
    dataGastos={gastos_sankey}
    title="Flujo de Cuentas Públicas de España ({sankey_anio[0].anio})"
    subtitle="De los impuestos y cotizaciones a las funciones de gasto del Estado (Millones de €)"
    height="540px"
/>

---

## 2. El Balance Histórico: Ingresos vs Gastos ({rango_historico[0].desde} - {rango_historico[0].hasta})

La diferencia anual entre lo que ingresa el sector público y lo que desembolsa define el **saldo presupuestario** (superávit si es positivo, déficit si es negativo). Para que la comparación entre años sea justa, las cifras se expresan por habitante y en euros de {base_deflactor[0]?.anio_base} (la serie empieza en {rango_historico[0]?.desde}, primer año con IPC anual disponible):

<LineChart
    data={serie_balance_historico}
    x=año
    y={["Ingresos por habitante", "Gastos por habitante"]}
    yAxisTitle="Euros por habitante (euros de {base_deflactor[0]?.anio_base})"
    yFmt=num0
    title="Ingresos y gastos públicos por habitante (euros de {base_deflactor[0]?.anio_base}, descontada la inflación)"
    startingAtZero={false}
/>

<BarChart
    data={serie_deficit_pib}
    x=año
    y=deficit_pib
    yAxisTitle="Déficit / Superávit (% del PIB)"
    title="Capacidad (+) o Necesidad (-) de Financiación de las AAPP (% PIB)"
/>

---

## 3. ¿Quién administra el gasto público en España?

España es un estado descentralizado donde las competencias de gasto se distribuyen entre cuatro subsectores institucionales. Las cifras de cada subsector no están consolidadas entre sí (incluyen las transferencias entre administraciones), por lo que sus pesos sobre el gasto total suman más del 100%:

<Grid cols=2>

<DataTable data={subsectores_ultimo} title="Desglose por Nivel de Administración ({subsectores_ultimo[0]?.anio})">
    <Column id=subsector title="Subsector Institucional" />
    <Column id=gasto_hab_real title="Gasto por habitante" fmt='#,##0 €' />
    <Column id=peso_gasto_pct title="% del Gasto" fmt='0.0"%"' />
    <Column id=saldo_hab_real title="Saldo por habitante" fmt='#,##0 €' />
    <Column id=gasto_mrd title="Gasto total (Mrd €)" fmt='#,##0.0' />
</DataTable>

<div>
    <BarChart
        data={subsectores_ultimo}
        x=subsector
        y=gasto_hab_real
        yAxisTitle="Euros por habitante"
        yFmt=num0
        title="Gasto por habitante de cada subsector ({subsectores_ultimo[0]?.anio}, euros de {base_deflactor[0]?.anio_base})"
        swapXY={true}
    />
</div>

</Grid>

- **Administración Central (Estado):** Financia los ministerios, policía nacional, defensa, infraestructuras de interés general y la mayor parte del pago de intereses de la deuda.
- **Comunidades Autónomas (CC.AA.):** Gestionan los dos pilares principales del bienestar ciudadano: la **Sanidad pública** y la **Educación**.
- **Fondos de la Seguridad Social:** Entidad especializada en el pago de las pensiones y subsidios a trabajadores y jubilados.
- **Corporaciones Locales (Ayuntamientos y Diputaciones):** Encargadas del urbanismo, recogida de residuos, transporte urbano y servicios municipales.

---

## 4. Evolución de la Deuda Pública sobre el PIB

El déficit acumulado a lo largo de los años se financia mediante la emisión de **Deuda Pública** (letras, bonos y obligaciones del Tesoro):

<LineChart
    data={serie_deuda_pib}
    x=año
    y=deuda_pib
    yAxisTitle="Deuda Pública (% del PIB)"
    title="Evolución de la Deuda Pública de España (% PIB según el PDE)"
    startingAtZero={false}
/>

---

## Explora en detalle

<Grid cols=2>
    <a href="/cuentas-publicas/ingresos" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v12"/><path d="m8 11 4 4 4-4"/><path d="M8 5H4a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-4"/></svg>
        </div>
        <h3 class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-1">Ingresos públicos</h3>
        <p class="text-sm text-slate-600 dark:text-slate-400 m-0">Recaudación por IRPF, IVA, Impuesto de Sociedades, cotizaciones sociales y tasas públicas en euros constantes por habitante.</p>
        <span class="sf-card-cta">Ver informe de Ingresos Públicos →</span>
    </a>

    <a href="/cuentas-publicas/gastos" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 15V3"/><path d="m8 7 4-4 4 4"/><path d="M8 5H4a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-4"/></svg>
        </div>
        <h3 class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-1">Gastos por función (COFOG)</h3>
        <p class="text-sm text-slate-600 dark:text-slate-400 m-0">Cuánto gasta el Estado por habitante en Sanidad, Pensiones, Educación, Defensa e intereses de la deuda.</p>
        <span class="sf-card-cta">Ver informe de Gastos Públicos →</span>
    </a>

    <a href="/cuentas-publicas/empleo-publico" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="22" x2="21" y2="22"/><line x1="6" y1="18" x2="6" y2="11"/><line x1="10" y1="18" x2="10" y2="11"/><line x1="14" y1="18" x2="14" y2="11"/><line x1="18" y1="18" x2="18" y2="11"/><polygon points="12 2 20 7 4 7"/></svg>
        </div>
        <h3 class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-1">Empleo público</h3>
        <p class="text-sm text-slate-600 dark:text-slate-400 m-0">Cuántos empleados públicos hay en cada administración y territorio, cómo han evolucionado y cuánto cobran frente al sector privado.</p>
        <span class="sf-card-cta">Ver informe de Empleo Público →</span>
    </a>

    <a href="/cuentas-publicas/pensiones" class="sf-subtopic-card no-underline">
        <div class="sf-icon-box">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
        </div>
        <h3 class="text-base font-bold text-slate-900 dark:text-white mt-3 mb-1">Pensiones</h3>
        <p class="text-sm text-slate-600 dark:text-slate-400 m-0">Pensión media descontada la inflación, afiliados por pensión, gasto en % del PIB frente a la UE y diferencias entre comunidades.</p>
        <span class="sf-card-cta">Ver informe de Pensiones →</span>
    </a>
</Grid>

<div class="sf-sources-footer">

## Fuentes Oficiales y Trazabilidad
- **[Intervención General de la Administración del Estado (IGAE)](https://www.igae.pap.hacienda.gob.es/):** Contabilidad Nacional del Sector Público de España.
- **[Banco de España - Boletín Estadístico](https://www.bde.es/):** Series históricas de deuda pública y pasivos financieros de las AAPP.
- **[Eurostat - Government Finance Statistics (gov_10a_main)](https://ec.europa.eu/eurostat/web/government-finance-statistics):** Cuentas consolidadas armonizadas según el Sistema Europeo de Cuentas (SEC 2010).

</div>
