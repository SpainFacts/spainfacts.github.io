---
title: Economia
description: "PIB per habitant, creixement, comerç exterior, sectors, ocupació, salaris, atur i inflació a Espanya, descomptada la inflació i en proporció a la població."
i18n_origen: 835b12e5d68d
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
</script>

```sql pib_hab
SELECT anio, real_eur AS valor, 100 * (real_eur / lag(real_eur) OVER (ORDER BY anio) - 1) AS crecimiento
FROM mother.economia_pib_per_capita
WHERE pais = 'ES'
ORDER BY anio
```

```sql pib_trim
SELECT trimestre, CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo, interanual, anio_base
FROM mother.economia_pib_trimestral
WHERE componente = 'B1GQ'
ORDER BY trimestre
```

```sql exportaciones
SELECT trimestre, CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo, pct_pib
FROM mother.economia_pib_trimestral
WHERE componente = 'P6'
ORDER BY trimestre
```

```sql salario
SELECT anio, salario_real, crecimiento_real
FROM mother.economia_salarios_anual
WHERE jornada = 'Todas' AND sector = 'Total'
ORDER BY anio
```

```sql empleo
SELECT anio, ocupados_1000_hab, ocupados_miles
FROM mother.economia_sectores
WHERE rama = 'TOTAL'
ORDER BY anio
```

```sql serie_paro
SELECT periodo, valor AS paro, strftime(periodo, '%Y') || '-T' || quarter(periodo) AS periodo_txt
FROM mother.metricas
WHERE metrica_id = 'tasa_paro'
ORDER BY periodo
```

```sql serie_ipc
SELECT periodo, valor AS ipc, strftime(periodo, '%Y-%m') AS periodo_txt
FROM mother.metricas
WHERE metrica_id = 'ipc_variacion_anual'
ORDER BY periodo
```

```sql sectores_crec
SELECT
    s.sector,
    100 * (s.vab_real_meur / b.vab_real_meur - 1) AS crecimiento,
    s.anio
FROM mother.economia_sectores s
JOIN mother.economia_sectores b ON b.rama = s.rama AND b.anio = 2019
WHERE s.anio = (SELECT max(anio) FROM mother.economia_sectores)
  AND s.rama <> 'TOTAL' AND NOT s.es_subrama
ORDER BY crecimiento DESC
```

# 📊 Economia

Com evoluciona l'economia espanyola. Seguint el criteri de tot el web, el que depèn de la mida del país es mostra **per habitant** i el que es mesura en euros, **descomptada la inflació** (en euros del {pib_trim[0]?.anio_base}).

<Grid cols=3>
    <KpiCard
        title="PIB per habitant"
        value={pib_hab.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pib_hab.slice(-1)[0]?.valor, 0)} €"
        period="el {pib_hab.slice(-1)[0]?.anio}, en euros del {pib_trim[0]?.anio_base}"
        change={pib_hab.slice(-1)[0]?.crecimiento?.toFixed(1)}
        changePeriod="real respecte a l'any anterior"
        direction="positive-up"
        source="Eurostat"
        sparklineData={pib_hab.map(d => d.valor)}
        href="/ca/economia/pib"
    />
    <KpiCard
        title="Creixement del PIB"
        value={pib_trim.slice(-1)[0]?.interanual}
        formattedValue="{formatNumber(pib_trim.slice(-1)[0]?.interanual, 1)} %"
        period="interanual real, {pib_trim.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={pib_trim.slice(-24).map(d => d.interanual)}
        href="/ca/economia/pib"
    />
    <KpiCard
        title="Exportacions"
        value={exportaciones.slice(-1)[0]?.pct_pib}
        formattedValue="{formatNumber(exportaciones.slice(-1)[0]?.pct_pib, 1)} % del PIB"
        period="béns i serveis, {exportaciones.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={exportaciones.slice(-40).map(d => d.pct_pib)}
        href="/ca/economia/comercio-exterior"
    />
    <KpiCard
        title="Salari mitjà"
        value={salario.slice(-1)[0]?.salario_real}
        formattedValue="{formatNumber(salario.slice(-1)[0]?.salario_real, 0)} €/mes"
        period="brut el {salario.slice(-1)[0]?.anio}, descomptada la inflació"
        change={salario.slice(-1)[0]?.crecimiento_real?.toFixed(1)}
        changePeriod="real respecte a l'any anterior"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={salario.map(d => d.salario_real)}
        href="/ca/economia/salarios"
    />
    <KpiCard
        title="Taxa d'atur"
        value={serie_paro.slice(-1)[0]?.paro}
        formattedValue="{formatNumber(serie_paro.slice(-1)[0]?.paro, 1)} %"
        period={serie_paro.slice(-1)[0]?.periodo_txt}
        change={serie_paro.length > 1 ? (serie_paro.slice(-1)[0]?.paro - serie_paro.slice(-2)[0]?.paro).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="respecte al trimestre anterior"
        direction="positive-down"
        source="INE / EPA"
        sparklineData={serie_paro.slice(-40).map(d => d.paro)}
        href="/ca/economia/paro"
    />
    <KpiCard
        title="Inflació"
        value={serie_ipc.slice(-1)[0]?.ipc}
        formattedValue="{formatNumber(serie_ipc.slice(-1)[0]?.ipc, 1)} %"
        period="IPC interanual, {serie_ipc.slice(-1)[0]?.periodo_txt}"
        change={serie_ipc.length > 1 ? (serie_ipc.slice(-1)[0]?.ipc - serie_ipc.slice(-2)[0]?.ipc).toFixed(1) : null}
        changeUnit="pp"
        changePeriod="respecte al mes anterior"
        direction="positive-down"
        source="INE / IPC"
        sparklineData={serie_ipc.slice(-36).map(d => d.ipc)}
        href="/ca/economia/ipc"
    />
</Grid>

## PIB per habitant

El que produeix l'economia per cada habitant, en euros constants. [Creixement trimestral, demanda i comparació amb Europa →](/ca/economia/pib)

<LineChart
    data={pib_hab}
    x=anio
    y=valor
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per habitant (reals)"
    startingAtZero={false}
    title="PIB per habitant en euros del {pib_trim[0]?.anio_base}"
/>

## Sectors

Creixement real del valor afegit de cada gran sector des del 2019. [Ocupació, pes i productivitat per sector →](/ca/economia/sectores)

<BarChart
    data={sectores_crec}
    x=sector
    y=crecimiento
    swapXY=true
    yFmt='0.0"%"'
    title="Creixement real del valor afegit entre el 2019 i el {sectores_crec[0]?.anio} (%)"
/>

## Ocupació

Ocupats per cada 1.000 habitants: puja quan es crea ocupació més de pressa del que creix la població. [Taxa d'atur →](/ca/economia/paro)

<LineChart
    data={empleo}
    x=anio
    y=ocupados_1000_hab
    xFmt='0'
    yAxisTitle="Ocupats per 1.000 hab."
    startingAtZero={false}
    title="Ocupats per 1.000 habitants"
/>

## Salaris

Salari mitjà mensual brut descomptada la inflació. [Creixement, sectors i decils →](/ca/economia/salarios)

<LineChart
    data={salario}
    x=anio
    y=salario_real
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ al mes (reals)"
    startingAtZero={false}
    title="Salari mitjà mensual en euros del {pib_trim[0]?.anio_base}"
/>

## Atur i inflació

<Grid cols=2>
<LineChart
    data={serie_paro}
    x=periodo
    y=paro
    yAxisTitle="% de la població activa"
    title="Taxa d'atur (EPA)"
    startingAtZero={false}
/>
<LineChart
    data={serie_ipc}
    x=periodo
    y=ipc
    yAxisTitle="% interanual"
    title="Inflació (IPC, variació anual)"
    startingAtZero={false}
/>
</Grid>

<Grid cols=3>
    <a href="/ca/economia/comercio-exterior" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🚢</span> Comerç exterior</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Exportacions, importacions i saldo exterior sobre el PIB</div>
    </a>
    <a href="/ca/economia/paro" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">👷</span> Atur</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Sèrie històrica de l'EPA</div>
    </a>
    <a href="/ca/economia/ipc" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🛒</span> Inflació</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Índex de preus de consum i preu de l'energia</div>
    </a>
    <a href="/ca/economia/turismo" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🏖️</span> Turisme</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Turistes per habitant, la seva despesa real i en % del PIB, hotels i habitatges turístics</div>
    </a>
    <a href="/ca/economia/empresas" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🏢</span> Empreses, emprenedoria i R+D</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Empreses per habitant i mida, societats creades i dissoltes, concursos, autònoms i despesa en R+D davant d'Europa</div>
    </a>
    <a href="/ca/economia/sector-primario" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🌾</span> Agricultura, ramaderia i pesca</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">L'horta d'Europa: oli, cítrics, fruites i hortalisses, porcí, vi i pesca, i el lloc d'Espanya a la UE</div>
    </a>
    <a href="/ca/economia/industria" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🏭</span> Indústria</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">Cotxes, rajoles, alimentació, tren i aerogeneradors: on destaca Espanya i quanta indústria té davant la UE</div>
    </a>
    <a href="/ca/economia/construccion" class="block rounded-xl border border-gray-200 dark:border-gray-800 p-4 hover:border-blue-400 no-underline">
        <div class="font-semibold"><span aria-hidden="true">🏗️</span> Construcció</div>
        <div class="text-sm text-gray-600 dark:text-gray-400">La bombolla del 2007, l'enfonsament i la recuperació: ocupació, obra pública licitada, habitatges visats i ciment davant la UE</div>
    </a>
</Grid>

---

**Fonts:** Eurostat (comptabilitat nacional: [namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table), [nama_10_pc](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table), [nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table)) i INE ([EPA](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176918), [IPC](https://www.ine.es/jaxiT3/Tabla.htm?t=76125), [Enquesta trimestral de cost laboral](https://www.ine.es/jaxiT3/Tabla.htm?t=6038)).
