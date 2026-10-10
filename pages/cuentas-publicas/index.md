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

# Cuentas públicas de España: el informe anual

Como la memoria anual de una empresa, pero para el conjunto de las administraciones públicas (Estado, comunidades autónomas, ayuntamientos y Seguridad Social): *¿cuánto ingresa el Estado? ¿en qué se gasta el dinero de los contribuyentes? ¿cuál es el déficit anual y cómo evoluciona la deuda pública?*

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
        sparklineData={serie_balance_real.filter(d => d.ingresos_hab_real != null).map(d => d.ingresos_hab_real)}
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
        sparklineData={serie_balance_real.filter(d => d.gastos_hab_real != null).map(d => d.gastos_hab_real)}
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
        sparklineData={serie_deficit_pib.filter(d => d.deficit_pib != null).map(d => d.deficit_pib)}
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
        sparklineData={serie_deuda_pib.filter(d => d.deuda_pib != null).map(d => d.deuda_pib)}
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

<Grid cols=2>
    <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-950/40 border border-blue-200 dark:border-blue-800">
        <h3 class="font-bold text-blue-900 dark:text-blue-300 mb-1"><span aria-hidden="true">📥</span> ¿Quieres profundizar en los ingresos?</h3>
        <p class="text-xs text-blue-700 dark:text-blue-400 mb-2">Consulta la recaudación por IRPF, IVA, Sociedades, Cotizaciones y tasas públicas.</p>
        <a href="/cuentas-publicas/ingresos" class="text-xs font-bold text-blue-600 dark:text-blue-300 hover:underline">
            Ver informe completo de Ingresos Públicos →
        </a>
    </div>

    <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-950/40 border border-purple-200 dark:border-purple-800">
        <h3 class="font-bold text-purple-900 dark:text-purple-300 mb-1"><span aria-hidden="true">📤</span> ¿Quieres ver el detalle de los gastos?</h3>
        <p class="text-xs text-purple-700 dark:text-purple-400 mb-2">Descubre cuánto gasta el Estado por habitante en Sanidad, Pensiones, Educación y Defensa.</p>
        <a href="/cuentas-publicas/gastos" class="text-xs font-bold text-purple-600 dark:text-purple-300 hover:underline">
            Ver informe completo de Gastos y Coste por Habitante →
        </a>
    </div>

    <div class="p-4 rounded-lg bg-teal-50 dark:bg-teal-950/40 border border-teal-200 dark:border-teal-800">
        <h3 class="font-bold text-teal-900 dark:text-teal-300 mb-1"><span aria-hidden="true">🏛️</span> ¿Cuántos empleados públicos hay?</h3>
        <p class="text-xs text-teal-700 dark:text-teal-400 mb-2">Cuántos son en cada administración y territorio, cómo han evolucionado, cuánto cobran frente al sector privado y cuánto cuestan.</p>
        <a href="/cuentas-publicas/empleo-publico" class="text-xs font-bold text-teal-700 dark:text-teal-300 hover:underline">
            Ver informe de Empleo Público →
        </a>
    </div>

    <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-800">
        <h3 class="font-bold text-amber-900 dark:text-amber-300 mb-1"><span aria-hidden="true">👵</span> ¿Cuánto cuestan las pensiones?</h3>
        <p class="text-xs text-amber-700 dark:text-amber-400 mb-2">Pensión media descontada la inflación, afiliados por pensión, gasto en % del PIB frente a la UE y diferencias entre comunidades.</p>
        <a href="/cuentas-publicas/pensiones" class="text-xs font-bold text-amber-700 dark:text-amber-300 hover:underline">
            Ver informe de Pensiones →
        </a>
    </div>
</Grid>

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

## Fuentes Oficiales y Trazabilidad
- **[Intervención General de la Administración del Estado (IGAE)](https://www.igae.pap.hacienda.gob.es/):** Contabilidad Nacional del Sector Público de España.
- **[Banco de España - Boletín Estadístico](https://www.bde.es/):** Series históricas de deuda pública y pasivos financieros de las AAPP.
- **[Eurostat - Government Finance Statistics (gov_10a_main)](https://ec.europa.eu/eurostat/web/government-finance-statistics):** Cuentas consolidadas armonizadas según el Sistema Europeo de Cuentas (SEC 2010).
