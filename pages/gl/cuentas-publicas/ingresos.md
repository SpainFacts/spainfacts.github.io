---
description: "De onde sae o diñeiro público: impostos e cotizacións sociais en España, por habitante, descontada a inflación e en porcentaxe do PIB."
title: Ingresos públicos e recadación tributaria
i18n_origen: 41be22719404
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
</script>

# De onde proveñen os recursos públicos en España?

O sector público español finánciase principalmente a través de tres grandes vías: **cotizacións sociais** aboadas por traballadores e empresas, **impostos directos** sobre a renda e o beneficio (IRPF e Imposto sobre Sociedades) e **impostos indirectos** sobre o consumo e a produción (IVE e impostos especiais).

```sql base_deflactor
-- Año cuyos euros se usan como referencia (último año completo con IPC)
SELECT CAST(max(anio_base) AS INTEGER) AS anio_base FROM mother.deflactor
```

```sql ingresos_hab
-- Ingresos por habitante en euros constantes (ya calculados en la tabla)
SELECT
    i.anio,
    i.categoria,
    i.tipo_ingreso,
    i.millones_euros,
    i.porcentaje_pib,
    i.porcentaje_ingreso_total,
    i.ingreso_eur_hab_real AS eur_hab_real
FROM mother.cuentas_ingresos i
WHERE i.ingreso_eur_hab_real IS NOT NULL
```

```sql ultimos_ingresos_totales
SELECT
    anio,
    sum(millones_euros) AS total_ingresos,
    sum(eur_hab_real) AS total_hab_real,
    sum(porcentaje_pib) AS total_pib
FROM ${ingresos_hab}
WHERE anio = (SELECT max(anio) FROM mother.cuentas_ingresos)
GROUP BY anio
```

```sql resumen_tipos
SELECT
    sum(CASE WHEN tipo_ingreso = 'Cotizaciones' THEN porcentaje_ingreso_total END) AS cot_pct,
    sum(CASE WHEN tipo_ingreso = 'Impuestos Directos' THEN porcentaje_ingreso_total END) AS dir_pct,
    sum(CASE WHEN tipo_ingreso = 'Impuestos Indirectos' THEN porcentaje_ingreso_total END) AS ind_pct,
    sum(CASE WHEN tipo_ingreso = 'No Tributarios' THEN porcentaje_ingreso_total END) AS notrib_pct,
    max(CASE WHEN categoria = 'Cotizaciones Sociales' THEN millones_euros END) AS cot_mio,
    max(CASE WHEN categoria = 'Cotizaciones Sociales' THEN eur_hab_real END) AS cot_hab,
    max(CASE WHEN categoria = 'IRPF y Patrimonio' THEN millones_euros END) AS irpf_mio,
    max(CASE WHEN categoria = 'IRPF y Patrimonio' THEN eur_hab_real END) AS irpf_hab,
    max(CASE WHEN categoria = 'IRPF y Patrimonio' THEN porcentaje_ingreso_total END) AS irpf_pct,
    max(CASE WHEN categoria = 'IVA' THEN millones_euros END) AS iva_mio,
    max(CASE WHEN categoria = 'IVA' THEN eur_hab_real END) AS iva_hab,
    max(CASE WHEN categoria = 'IVA' THEN porcentaje_ingreso_total END) AS iva_pct
FROM ${ingresos_hab}
WHERE anio = (SELECT max(anio) FROM mother.cuentas_ingresos)
```

```sql ingresos_por_categoria_ultimo
SELECT
    categoria,
    tipo_ingreso,
    eur_hab_real,
    millones_euros,
    porcentaje_pib,
    porcentaje_ingreso_total
FROM ${ingresos_hab}
WHERE anio = (SELECT max(anio) FROM mother.cuentas_ingresos)
ORDER BY millones_euros DESC
```

```sql serie_ingresos_categoria
-- Euros por habitante a precios constantes (el deflactor empieza en 1996)
SELECT
    anio AS año,
    categoria,
    eur_hab_real
FROM ${ingresos_hab}
ORDER BY año ASC, eur_hab_real DESC
```

```sql serie_ingresos_tipo
-- Euros por habitante a precios constantes (el deflactor empieza en 1996)
SELECT
    anio AS año,
    tipo_ingreso,
    sum(eur_hab_real) AS eur_hab_real
FROM ${ingresos_hab}
GROUP BY 1, 2
ORDER BY 1 ASC
```

```sql serie_ingresos_real
-- Para las mini-gráficas: euros por habitante a precios constantes (mother.deflactor)
SELECT
    anio,
    categoria,
    eur_hab_real
FROM ${ingresos_hab}
WHERE categoria IN ('Cotizaciones Sociales', 'IRPF y Patrimonio', 'IVA')
  AND eur_hab_real IS NOT NULL
ORDER BY anio
```

<Grid cols=3>
    <KpiCard
        title="Cotizacións sociais"
        value={resumen_tipos[0]?.cot_hab}
        formattedValue="{formatNumber(resumen_tipos[0]?.cot_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_tipos[0]?.cot_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_tipos[0]?.cot_pct, 1)}% dos ingresos · {ultimos_ingresos_totales[0]?.anio}"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
        sparklineData={serie_ingresos_real.filter(d => d.categoria === 'Cotizaciones Sociales').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="IRPF e Patrimonio"
        value={resumen_tipos[0]?.irpf_hab}
        formattedValue="{formatNumber(resumen_tipos[0]?.irpf_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_tipos[0]?.irpf_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_tipos[0]?.irpf_pct, 1)}% dos ingresos · {ultimos_ingresos_totales[0]?.anio}"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
        sparklineData={serie_ingresos_real.filter(d => d.categoria === 'IRPF y Patrimonio').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="IVE (consumo)"
        value={resumen_tipos[0]?.iva_hab}
        formattedValue="{formatNumber(resumen_tipos[0]?.iva_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_tipos[0]?.iva_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_tipos[0]?.iva_pct, 1)}% dos ingresos · {ultimos_ingresos_totales[0]?.anio}"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
        sparklineData={serie_ingresos_real.filter(d => d.categoria === 'IVA').map(d => d.eur_hab_real)}
    />
</Grid>

<p class="text-xs text-gray-500">Principio desta web: os importes móstranse <b>por habitante</b> e <b>descontada a inflación</b>, en euros de {base_deflactor[0]?.anio_base} segundo o IPC medio anual do INE, para que as cifras de anos distintos sexan comparables. Os totais en euros correntes aparecen como dato secundario; as porcentaxes (dos ingresos ou do PIB) non precisan axuste.</p>

---

## 1. Composición dos ingresos públicos en España ({ultimos_ingresos_totales[0].anio})

En {ultimos_ingresos_totales[0]?.anio}, os ingresos do conxunto das administracións públicas alcanzaron **{formatNumber(ultimos_ingresos_totales[0]?.total_hab_real, 0)} euros por habitante** (en euros de {base_deflactor[0]?.anio_base}; {formatNumber(ultimos_ingresos_totales[0]?.total_ingresos / 1000, 1)} mil millóns en total, o {formatNumber(ultimos_ingresos_totales[0]?.total_pib, 1)}% do PIB).

<BarChart
    data={ingresos_por_categoria_ultimo}
    x=categoria
    y=eur_hab_real
    yAxisTitle="Euros por habitante (euros de {base_deflactor[0]?.anio_base})"
    yFmt=num0
    title="Recadación por habitante segundo a categoría de ingreso ({ultimos_ingresos_totales[0]?.anio}, euros de {base_deflactor[0]?.anio_base})"
    swapXY={true}
/>

<DataTable data={ingresos_por_categoria_ultimo} title="Detalle dos ingresos ({ultimos_ingresos_totales[0].anio})">
    <Column id=categoria title="Categoría de ingreso" />
    <Column id=tipo_ingreso title="Tipo de tributo" />
    <Column id=eur_hab_real title="Por habitante" fmt='#,##0 €' />
    <Column id=porcentaje_ingreso_total title="% sobre o total" fmt='0.0"%"' />
    <Column id=porcentaje_pib title="% sobre o PIB" fmt='0.0"%"' />
    <Column id=millones_euros title="Recadación total (M€ correntes)" fmt='#,##0' />
</DataTable>

---

## 2. Evolución histórica dos ingresos por tipo de tributo

Ingresos por habitante de cada tipo, en euros de {base_deflactor[0]?.anio_base} (descontada a inflación), desde 1996, primeiro ano con IPC anual dispoñible:

<AreaChart
    data={serie_ingresos_tipo}
    x=año
    y=eur_hab_real
    series=tipo_ingreso
    yAxisTitle="Euros por habitante (euros de {base_deflactor[0]?.anio_base})"
    yFmt=num0
    title="Ingresos públicos por habitante e tipo de tributo (euros de {base_deflactor[0]?.anio_base}, descontada a inflación)"
/>

---

## 3. Como se distribúe a carga fiscal?

- **Cotizacións á Seguridade Social ({formatNumber(resumen_tipos[0].cot_pct, 1)}%):** a principal fonte de ingresos públicos, destinada a soster as pensións contributivas e as prestacións por desemprego.
- **Impostos directos ({formatNumber(resumen_tipos[0].dir_pct, 1)}%):** gravan directamente a renda dos cidadáns (IRPF), os beneficios declarados polas sociedades mercantís, o patrimonio e as herdanzas.
- **Impostos indirectos ({formatNumber(resumen_tipos[0].ind_pct, 1)}%):** gravan o consumo xeral (IVE) e produtos específicos como carburantes, tabaco, alcohol e electricidade (impostos especiais), ademais doutros impostos sobre a produción.
- **Ingresos non tributarios e fondos UE ({formatNumber(resumen_tipos[0].notrib_pct, 1)}%):** vendas e taxas de servizos públicos, rendas da propiedade (xuros, dividendos) e transferencias recibidas, incluídos os fondos europeos Next Generation EU.

<small>Metodoloxía: os impostos e cotizacións proceden de Eurostat (gov_10a_taxag) e os ingresos totais de gov_10a_main. As categorías «Outros impostos» e «Ingresos non tributarios e fondos UE» calcúlanse por diferenza, de modo que a suma coincide cos ingresos totais oficiais.</small>

---

## Fontes oficiais
- **[Eurostat - Impostos e cotizacións sociais por figura (gov_10a_taxag)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_taxag):** recadación harmonizada segundo o SEC 2010.
- **[Eurostat - Contas das AAPP (gov_10a_main)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_main):** ingresos totais das administracións públicas.
- **[Axencia Estatal de Administración Tributaria (AEAT)](https://sede.agenciatributaria.gob.es/Sede/estadisticas/recaudacion-tributaria.html):** informes anuais e mensuais de recadación.
- **[Intervención Xeral da Administración do Estado (IGAE)](https://www.igae.pap.hacienda.gob.es/):** contas económicas e contabilidade nacional do sector público.
