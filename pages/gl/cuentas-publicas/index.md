---
description: "Ingresos, gastos, déficit e débeda das administracións públicas españolas, por habitante, descontada a inflación e en porcentaxe do PIB."
title: Contas Públicas · O Informe Anual de España
i18n_origen: f87d27f18aaf
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber, formatCurrency, formatCompact } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import SankeyPresupuesto from '../../../../../../src/lib/components/SankeyPresupuesto.svelte';
</script>

# Contas públicas de España: o informe anual

Como a memoria anual dunha empresa, pero para o conxunto das administracións públicas (Estado, comunidades autónomas, concellos e Seguridade Social): *canto ingresa o Estado? en que se gasta o diñeiro dos contribuíntes? cal é o déficit anual e como evoluciona a débeda pública?*

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
        changePeriod="interanual, descontada a inflación"
        direction="positive-up"
        source="Eurostat (gov_10a_main)"
        sparklineData={serie_balance_real.filter(d => d.ingresos_hab_real != null).map(d => d.ingresos_hab_real)}
        href="/gl/cuentas-publicas/ingresos"
    />

    <KpiCard
        title="Gasto por habitante"
        value={balance_reciente[0]?.gastos_hab_real}
        formattedValue="{formatNumber(balance_reciente[0]?.gastos_hab_real, 0)} €"
        unit="/ hab."
        period="{formatNumber(balance_reciente[0]?.gastos_totales_mrd, 1)} mil M€ en total · {balance_reciente[0]?.anio} (euros de {base_deflactor[0]?.anio_base})"
        change={(((balance_reciente[0]?.gastos_hab_real - balance_reciente[1]?.gastos_hab_real) / balance_reciente[1]?.gastos_hab_real) * 100).toFixed(1)}
        changeUnit="%"
        changePeriod="interanual, descontada a inflación"
        direction="neutral"
        source="Eurostat (gov_10a_main)"
        sparklineData={serie_balance_real.filter(d => d.gastos_hab_real != null).map(d => d.gastos_hab_real)}
        href="/gl/cuentas-publicas/gastos"
    />

    <KpiCard
        title="Déficit fiscal anual"
        value={balance_reciente[0].saldo_deficit_pib}
        formattedValue="{formatNumber(balance_reciente[0].saldo_deficit_pib, 1)}% PIB"
        period="Exercicio {balance_reciente[0].anio}"
        change={(balance_reciente[0].saldo_deficit_pib - balance_reciente[1].saldo_deficit_pib).toFixed(1)}
        changeUnit="pp"
        changePeriod="fronte ao ano anterior"
        direction="positive-up"
        source="Eurostat (gov_10a_main)"
        sparklineData={serie_deficit_pib.filter(d => d.deficit_pib != null).map(d => d.deficit_pib)}
    />

    <KpiCard
        title="Débeda pública / PIB"
        value={balance_reciente[0].deuda_pib}
        formattedValue="{formatNumber(balance_reciente[0].deuda_pib, 1)}%"
        period="{formatNumber(balance_reciente[0].deuda_publica_mrd, 1)} mil M€ · {balance_reciente[0].anio}"
        change={(balance_reciente[0].deuda_pib - balance_reciente[1].deuda_pib).toFixed(1)}
        changeUnit="pp"
        changePeriod="fronte ao ano anterior"
        direction="positive-down"
        source="Eurostat (PDE)"
        sparklineData={serie_deuda_pib.filter(d => d.deuda_pib != null).map(d => d.deuda_pib)}
        href="/gl/varios/indicadores/deuda_publica_pib"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('deuda_publica')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'deuda_publica')} />


<p class="text-xs text-gray-500">Principio desta web: os importes en euros móstranse <b>por habitante</b> (para que non medren só porque medra a poboación) e <b>descontada a inflación</b>, en euros de {base_deflactor[0]?.anio_base} segundo o IPC medio anual do INE. Os totais en euros correntes aparecen como dato secundario. As porcentaxes do PIB non precisan axuste.</p>

---

## 1. O percorrido do diñeiro público (fluxo orzamentario {sankey_anio[0].anio})

Este diagrama de fluxo amosa de onde proveñen os ingresos das administracións públicas e en que partidas concretas se empregan (último exercicio con desagregación completa publicada por Eurostat). A diferenza entre ambos os lados é o déficit do ano, que se financia con débeda:

<SankeyPresupuesto
    dataIngresos={ingresos_sankey}
    dataGastos={gastos_sankey}
    title="Fluxo das contas públicas de España ({sankey_anio[0].anio})"
    subtitle="Dos impostos e cotizacións ás funcións de gasto do Estado (millóns de €)"
    height="540px"
/>

<Grid cols=2>
    <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-950/40 border border-blue-200 dark:border-blue-800">
        <h3 class="font-bold text-blue-900 dark:text-blue-300 mb-1"><span aria-hidden="true">📥</span> Queres afondar nos ingresos?</h3>
        <p class="text-xs text-blue-700 dark:text-blue-400 mb-2">Consulta a recadación por IRPF, IVE, Sociedades, cotizacións e taxas públicas.</p>
        <a href="/gl/cuentas-publicas/ingresos" class="text-xs font-bold text-blue-600 dark:text-blue-300 hover:underline">
            Ver o informe completo de ingresos públicos →
        </a>
    </div>

    <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-950/40 border border-purple-200 dark:border-purple-800">
        <h3 class="font-bold text-purple-900 dark:text-purple-300 mb-1"><span aria-hidden="true">📤</span> Queres ver o detalle dos gastos?</h3>
        <p class="text-xs text-purple-700 dark:text-purple-400 mb-2">Descobre canto gasta o Estado por habitante en sanidade, pensións, educación e defensa.</p>
        <a href="/gl/cuentas-publicas/gastos" class="text-xs font-bold text-purple-600 dark:text-purple-300 hover:underline">
            Ver o informe completo de gastos e custo por habitante →
        </a>
    </div>

    <div class="p-4 rounded-lg bg-teal-50 dark:bg-teal-950/40 border border-teal-200 dark:border-teal-800">
        <h3 class="font-bold text-teal-900 dark:text-teal-300 mb-1"><span aria-hidden="true">🏛️</span> Cantos empregados públicos hai?</h3>
        <p class="text-xs text-teal-700 dark:text-teal-400 mb-2">Cantos son en cada administración e territorio, como evolucionaron, canto cobran fronte ao sector privado e canto custan.</p>
        <a href="/gl/cuentas-publicas/empleo-publico" class="text-xs font-bold text-teal-700 dark:text-teal-300 hover:underline">
            Ver o informe de emprego público →
        </a>
    </div>

    <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-800">
        <h3 class="font-bold text-amber-900 dark:text-amber-300 mb-1"><span aria-hidden="true">👵</span> Canto custan as pensións?</h3>
        <p class="text-xs text-amber-700 dark:text-amber-400 mb-2">Pensión media descontada a inflación, afiliados por pensión, gasto en % do PIB fronte á UE e diferenzas entre comunidades.</p>
        <a href="/gl/cuentas-publicas/pensiones" class="text-xs font-bold text-amber-700 dark:text-amber-300 hover:underline">
            Ver o informe de pensións →
        </a>
    </div>
</Grid>

---

## 2. O balance histórico: ingresos fronte a gastos ({rango_historico[0].desde} - {rango_historico[0].hasta})

A diferenza anual entre o que ingresa o sector público e o que desembolsa define o **saldo orzamentario** (superávit se é positivo, déficit se é negativo). Para que a comparación entre anos sexa xusta, as cifras exprésanse por habitante e en euros de {base_deflactor[0]?.anio_base} (a serie comeza en {rango_historico[0]?.desde}, primeiro ano con IPC anual dispoñible):

<LineChart
    data={serie_balance_historico}
    x=año
    y={["Ingresos por habitante", "Gastos por habitante"]}
    yAxisTitle="Euros por habitante (euros de {base_deflactor[0]?.anio_base})"
    yFmt=num0
    title="Ingresos e gastos públicos por habitante (euros de {base_deflactor[0]?.anio_base}, descontada a inflación)"
    startingAtZero={false}
/>

<BarChart
    data={serie_deficit_pib}
    x=año
    y=deficit_pib
    yAxisTitle="Déficit / superávit (% do PIB)"
    title="Capacidade (+) ou necesidade (-) de financiamento das AAPP (% PIB)"
/>

---

## 3. Quen administra o gasto público en España?

España é un estado descentralizado onde as competencias de gasto se distribúen entre catro subsectores institucionais. As cifras de cada subsector non están consolidadas entre si (inclúen as transferencias entre administracións), polo que os seus pesos sobre o gasto total suman máis do 100%:

<Grid cols=2>

<DataTable data={subsectores_ultimo} title="Desagregación por nivel de administración ({subsectores_ultimo[0]?.anio})">
    <Column id=subsector title="Subsector institucional" />
    <Column id=gasto_hab_real title="Gasto por habitante" fmt='#,##0 €' />
    <Column id=peso_gasto_pct title="% do gasto" fmt='0.0"%"' />
    <Column id=saldo_hab_real title="Saldo por habitante" fmt='#,##0 €' />
    <Column id=gasto_mrd title="Gasto total (mil M€)" fmt='#,##0.0' />
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

- **Administración Central (Estado):** financia os ministerios, a policía nacional, a defensa, as infraestruturas de interese xeral e a maior parte do pagamento de xuros da débeda.
- **Comunidades autónomas (CC.AA.):** xestionan os dous piares principais do benestar cidadán: a **sanidade pública** e a **educación**.
- **Fondos da Seguridade Social:** entidade especializada no pagamento das pensións e subsidios a traballadores e xubilados.
- **Corporacións locais (concellos e deputacións):** encargadas do urbanismo, a recollida de residuos, o transporte urbano e os servizos municipais.

---

## 4. Evolución da débeda pública sobre o PIB

O déficit acumulado ao longo dos anos finánciase mediante a emisión de **débeda pública** (letras, bonos e obrigas do Tesouro):

<LineChart
    data={serie_deuda_pib}
    x=año
    y=deuda_pib
    yAxisTitle="Débeda pública (% do PIB)"
    title="Evolución da débeda pública de España (% PIB segundo o PDE)"
    startingAtZero={false}
/>

---

## Fontes oficiais e trazabilidade
- **[Intervención Xeral da Administración do Estado (IGAE)](https://www.igae.pap.hacienda.gob.es/):** contabilidade nacional do sector público de España.
- **[Banco de España - Boletín Estatístico](https://www.bde.es/):** series históricas de débeda pública e pasivos financeiros das AAPP.
- **[Eurostat - Government Finance Statistics (gov_10a_main)](https://ec.europa.eu/eurostat/web/government-finance-statistics):** contas consolidadas harmonizadas segundo o Sistema Europeo de Contas (SEC 2010).
