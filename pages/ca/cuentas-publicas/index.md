---
description: "Ingressos, despeses, dèficit i deute de les administracions públiques espanyoles, per habitant, descomptada la inflació i en percentatge del PIB."
title: Comptes Públics · L'informe anual d'Espanya
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 0fb297ecbee4
---

<script>
    import { formatNumber, formatCurrency, formatCompact } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import SankeyPresupuesto from '../../../../../../src/lib/components/SankeyPresupuesto.svelte';
</script>

# El "10-K" dels comptes públics d'Espanya

Inspirat en l'informe anual que presenten les empreses cotitzades davant dels mercats, aquest apartat presenta el **balanç consolidat del Regne d'Espanya**: *quant ingressa l'Estat? en què es gasten els diners dels contribuents? quin és el dèficit anual i com evoluciona el deute públic?*

```sql base_deflactor
-- Año cuyos euros se usan como referencia (último año completo con IPC)
SELECT CAST(max(anio_base) AS INTEGER) AS anio_base FROM mother.deflactor
```

```sql balance_reciente
-- Importes por habitante y en euros constantes: nominal * 1000 / población (millones) * factor del deflactor
SELECT
    CAST(b.año AS INTEGER) AS anio,
    b.ingresos_totales_mrd,
    b.gastos_totales_mrd,
    b.saldo_deficit_mrd,
    b.saldo_deficit_pib,
    b.deuda_publica_mrd,
    b.deuda_pib,
    b.poblacion_m,
    b.ingresos_totales_mrd * 1000 / b.poblacion_m * d.factor AS ingresos_hab_real,
    b.gastos_totales_mrd * 1000 / b.poblacion_m * d.factor AS gastos_hab_real
FROM mother.cuentas_balance_anual b
LEFT JOIN mother.deflactor d ON CAST(d.anio AS INTEGER) = CAST(b.año AS INTEGER)
ORDER BY b.año DESC
LIMIT 2
```

```sql serie_balance_historico
-- Euros por habitante a precios constantes (el deflactor empieza en 2002)
SELECT
    CAST(b.año AS INTEGER) AS año,
    b.ingresos_totales_mrd * 1000 / b.poblacion_m * d.factor AS "Ingresos por habitante",
    b.gastos_totales_mrd * 1000 / b.poblacion_m * d.factor AS "Gastos por habitante",
    b.saldo_deficit_mrd * 1000 / b.poblacion_m * d.factor AS "Déficit / Superávit por habitante"
FROM mother.cuentas_balance_anual b
JOIN mother.deflactor d ON CAST(d.anio AS INTEGER) = CAST(b.año AS INTEGER)
WHERE b.poblacion_m > 0
ORDER BY año ASC
```

```sql serie_deficit_pib
SELECT
    año,
    saldo_deficit_pib AS deficit_pib
FROM mother.cuentas_balance_anual
ORDER BY año ASC
```

```sql serie_deuda_pib
SELECT
    año,
    deuda_pib
FROM mother.cuentas_balance_anual
ORDER BY año ASC
```

```sql sankey_anio
-- Último ejercicio con desglose publicado tanto de ingresos como de gastos
SELECT least(
    (SELECT max(año) FROM mother.cuentas_ingresos),
    (SELECT max(año) FROM mother.cuentas_gastos)
) AS anio
```

```sql ingresos_sankey
SELECT
    categoria,
    millones_euros
FROM mother.cuentas_ingresos
WHERE año = (SELECT least(max(i.año), (SELECT max(g.año) FROM mother.cuentas_gastos g)) FROM mother.cuentas_ingresos i)
ORDER BY millones_euros DESC
```

```sql gastos_sankey
SELECT
    funcion_cofog,
    millones_euros
FROM mother.cuentas_gastos
WHERE año = (SELECT least(max(g.año), (SELECT max(i.año) FROM mother.cuentas_ingresos i)) FROM mother.cuentas_gastos g)
ORDER BY millones_euros DESC
```

```sql subsectores_ultimo
SELECT
    CAST(s.año AS INTEGER) AS anio,
    s.subsector,
    s.gasto_mrd,
    s.ingreso_mrd,
    s.saldo_deficit_mrd,
    s.peso_gasto_pct,
    s.gasto_mrd * 1000 / b.poblacion_m * d.factor AS gasto_hab_real,
    s.saldo_deficit_mrd * 1000 / b.poblacion_m * d.factor AS saldo_hab_real
FROM mother.cuentas_subsectores s
JOIN mother.cuentas_balance_anual b ON CAST(b.año AS INTEGER) = CAST(s.año AS INTEGER)
JOIN mother.deflactor d ON CAST(d.anio AS INTEGER) = CAST(s.año AS INTEGER)
WHERE s.año = (SELECT max(año) FROM mother.cuentas_subsectores)
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
        title="Ingressos per habitant"
        value={balance_reciente[0]?.ingresos_hab_real}
        formattedValue="{formatNumber(balance_reciente[0]?.ingresos_hab_real, 0)} €"
        unit="/ hab."
        period="{formatNumber(balance_reciente[0]?.ingresos_totales_mrd, 1)} mil M€ en total · {balance_reciente[0]?.anio} (euros de {base_deflactor[0]?.anio_base})"
        change={(((balance_reciente[0]?.ingresos_hab_real - balance_reciente[1]?.ingresos_hab_real) / balance_reciente[1]?.ingresos_hab_real) * 100).toFixed(1)}
        changeUnit="%"
        changePeriod="interanual, descomptada la inflació"
        direction="positive-up"
        source="Eurostat (gov_10a_main)"
        sparklineData={serie_balance_real.filter(d => d.ingresos_hab_real != null).map(d => d.ingresos_hab_real)}
        href="/ca/cuentas-publicas/ingresos"
    />

    <KpiCard
        title="Despesa per habitant"
        value={balance_reciente[0]?.gastos_hab_real}
        formattedValue="{formatNumber(balance_reciente[0]?.gastos_hab_real, 0)} €"
        unit="/ hab."
        period="{formatNumber(balance_reciente[0]?.gastos_totales_mrd, 1)} mil M€ en total · {balance_reciente[0]?.anio} (euros de {base_deflactor[0]?.anio_base})"
        change={(((balance_reciente[0]?.gastos_hab_real - balance_reciente[1]?.gastos_hab_real) / balance_reciente[1]?.gastos_hab_real) * 100).toFixed(1)}
        changeUnit="%"
        changePeriod="interanual, descomptada la inflació"
        direction="neutral"
        source="Eurostat (gov_10a_main)"
        sparklineData={serie_balance_real.filter(d => d.gastos_hab_real != null).map(d => d.gastos_hab_real)}
        href="/ca/cuentas-publicas/gastos"
    />

    <KpiCard
        title="Dèficit fiscal anual"
        value={balance_reciente[0].saldo_deficit_pib}
        formattedValue="{formatNumber(balance_reciente[0].saldo_deficit_pib, 1)}% PIB"
        period="Exercici {balance_reciente[0].anio}"
        change={(balance_reciente[0].saldo_deficit_pib - balance_reciente[1].saldo_deficit_pib).toFixed(1)}
        changeUnit="pp"
        changePeriod="vs. any anterior"
        direction="positive-down"
        source="Eurostat (gov_10a_main)"
        sparklineData={serie_deficit_pib.filter(d => d.deficit_pib != null).map(d => d.deficit_pib)}
    />

    <KpiCard
        title="Deute públic / PIB"
        value={balance_reciente[0].deuda_pib}
        formattedValue="{formatNumber(balance_reciente[0].deuda_pib, 1)}%"
        period="{formatNumber(balance_reciente[0].deuda_publica_mrd, 1)} mil M€ · {balance_reciente[0].anio}"
        change={(balance_reciente[0].deuda_pib - balance_reciente[1].deuda_pib).toFixed(1)}
        changeUnit="pp"
        changePeriod="vs. any anterior"
        direction="positive-down"
        source="Eurostat (PDE)"
        sparklineData={serie_deuda_pib.filter(d => d.deuda_pib != null).map(d => d.deuda_pib)}
        href="/ca/varios/indicadores/deuda_publica_pib"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('deuda_publica')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'deuda_publica')} />


<p class="text-xs text-gray-500">Principi d'aquest web: els imports en euros es mostren <b>per habitant</b> (perquè no creixin només perquè creix la població) i <b>descomptada la inflació</b>, en euros de {base_deflactor[0]?.anio_base} segons l'IPC mitjà anual de l'INE. Els totals en euros corrents apareixen com a dada secundària. Els percentatges del PIB no necessiten ajust.</p>

---

## 1. El recorregut dels diners públics (flux pressupostari {sankey_anio[0].anio})

Aquest diagrama de flux mostra d'on provenen els ingressos de les administracions públiques i en quines partides concretes es fan servir (últim exercici amb desglossament complet publicat per Eurostat). La diferència entre tots dos costats és el dèficit de l'any, que es finança amb deute:

<SankeyPresupuesto
    dataIngresos={ingresos_sankey}
    dataGastos={gastos_sankey}
    title="Flux dels comptes públics d'Espanya ({sankey_anio[0].anio})"
    subtitle="Dels impostos i cotitzacions a les funcions de despesa de l'Estat (milions d'€)"
    height="540px"
/>

<Grid cols=2>
    <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-950/40 border border-blue-200 dark:border-blue-800">
        <h3 class="font-bold text-blue-900 dark:text-blue-300 mb-1"><span aria-hidden="true">📥</span> Vols aprofundir en els ingressos?</h3>
        <p class="text-xs text-blue-700 dark:text-blue-400 mb-2">Consulta la recaptació per IRPF, IVA, Societats, cotitzacions i taxes públiques.</p>
        <a href="/ca/cuentas-publicas/ingresos" class="text-xs font-bold text-blue-600 dark:text-blue-300 hover:underline">
            Mostra l'informe complet d'ingressos públics →
        </a>
    </div>

    <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-950/40 border border-purple-200 dark:border-purple-800">
        <h3 class="font-bold text-purple-900 dark:text-purple-300 mb-1"><span aria-hidden="true">📤</span> Vols veure el detall de les despeses?</h3>
        <p class="text-xs text-purple-700 dark:text-purple-400 mb-2">Descobreix quant gasta l'Estat per habitant en sanitat, pensions, educació i defensa.</p>
        <a href="/ca/cuentas-publicas/gastos" class="text-xs font-bold text-purple-600 dark:text-purple-300 hover:underline">
            Mostra l'informe complet de despeses i cost per habitant →
        </a>
    </div>

    <div class="p-4 rounded-lg bg-teal-50 dark:bg-teal-950/40 border border-teal-200 dark:border-teal-800">
        <h3 class="font-bold text-teal-900 dark:text-teal-300 mb-1"><span aria-hidden="true">🏛️</span> Quants empleats públics hi ha?</h3>
        <p class="text-xs text-teal-700 dark:text-teal-400 mb-2">Quants són a cada administració i territori, com han evolucionat, quant cobren davant del sector privat i quant costen.</p>
        <a href="/ca/cuentas-publicas/empleo-publico" class="text-xs font-bold text-teal-700 dark:text-teal-300 hover:underline">
            Mostra l'informe d'ocupació pública →
        </a>
    </div>

    <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-800">
        <h3 class="font-bold text-amber-900 dark:text-amber-300 mb-1"><span aria-hidden="true">👵</span> Quant costen les pensions?</h3>
        <p class="text-xs text-amber-700 dark:text-amber-400 mb-2">Pensió mitjana descomptada la inflació, afiliats per pensió, despesa en % del PIB davant la UE i diferències entre comunitats.</p>
        <a href="/ca/cuentas-publicas/pensiones" class="text-xs font-bold text-amber-700 dark:text-amber-300 hover:underline">
            Mostra l'informe de pensions →
        </a>
    </div>
</Grid>

---

## 2. El balanç històric: ingressos vs. despeses ({rango_historico[0].desde} - {rango_historico[0].hasta})

La diferència anual entre el que ingressa el sector públic i el que desemborsa defineix el **saldo pressupostari** (superàvit si és positiu, dèficit si és negatiu). Perquè la comparació entre anys sigui justa, les xifres s'expressen per habitant i en euros de {base_deflactor[0]?.anio_base} (la sèrie comença el {rango_historico[0]?.desde}, primer any amb IPC anual disponible):

<LineChart
    data={serie_balance_historico}
    x=año
    y={["Ingresos por habitante", "Gastos por habitante"]}
    yAxisTitle="Euros per habitant (euros de {base_deflactor[0]?.anio_base})"
    yFmt=num0
    title="Ingressos i despeses públics per habitant (euros de {base_deflactor[0]?.anio_base}, descomptada la inflació)"
    startingAtZero={false}
/>

<BarChart
    data={serie_deficit_pib}
    x=año
    y=deficit_pib
    yAxisTitle="Dèficit / superàvit (% del PIB)"
    title="Capacitat (+) o necessitat (-) de finançament de les AP (% PIB)"
/>

---

## 3. Qui administra la despesa pública a Espanya?

Espanya és un estat descentralitzat on les competències de despesa es distribueixen entre quatre subsectors institucionals. Les xifres de cada subsector no estan consolidades entre si (inclouen les transferències entre administracions), per la qual cosa els seus pesos sobre la despesa total sumen més del 100%:

<Grid cols=2>

<DataTable data={subsectores_ultimo} title="Desglossament per nivell d'administració ({subsectores_ultimo[0]?.anio})">
    <Column id=subsector title="Subsector institucional" />
    <Column id=gasto_hab_real title="Despesa per habitant" fmt='#,##0 €' />
    <Column id=peso_gasto_pct title="% de la despesa" fmt='0.0"%"' />
    <Column id=saldo_hab_real title="Saldo per habitant" fmt='#,##0 €' />
    <Column id=gasto_mrd title="Despesa total (Mrd €)" fmt='#,##0.0' />
</DataTable>

<div>
    <BarChart
        data={subsectores_ultimo}
        x=subsector
        y=gasto_hab_real
        yAxisTitle="Euros per habitant"
        yFmt=num0
        title="Despesa per habitant de cada subsector ({subsectores_ultimo[0]?.anio}, euros de {base_deflactor[0]?.anio_base})"
        swapXY={true}
    />
</div>

</Grid>

- **Administració central (Estat):** Finança els ministeris, la policia nacional, la defensa, les infraestructures d'interès general i la major part del pagament d'interessos del deute.
- **Comunitats autònomes (CA):** Gestionen els dos pilars principals del benestar ciutadà: la **sanitat pública** i l'**educació**.
- **Fons de la Seguretat Social:** Entitat especialitzada en el pagament de les pensions i subsidis a treballadors i jubilats.
- **Corporacions locals (ajuntaments i diputacions):** Encarregades de l'urbanisme, la recollida de residus, el transport urbà i els serveis municipals.

---

## 4. Evolució del deute públic sobre el PIB

El dèficit acumulat al llarg dels anys es finança mitjançant l'emissió de **deute públic** (lletres, bons i obligacions del Tresor):

<LineChart
    data={serie_deuda_pib}
    x=año
    y=deuda_pib
    yAxisTitle="Deute públic (% del PIB)"
    title="Evolució del deute públic d'Espanya (% PIB segons el PDE)"
    startingAtZero={false}
/>

---

## Fonts oficials i traçabilitat
- **[Intervenció General de l'Administració de l'Estat (IGAE)](https://www.igae.pap.hacienda.gob.es/):** Comptabilitat nacional del sector públic d'Espanya.
- **[Banc d'Espanya - Butlletí Estadístic](https://www.bde.es/):** Sèries històriques de deute públic i passius financers de les AP.
- **[Eurostat - Government Finance Statistics (gov_10a_main)](https://ec.europa.eu/eurostat/web/government-finance-statistics):** Comptes consolidats harmonitzats segons el Sistema Europeu de Comptes (SEC 2010).
