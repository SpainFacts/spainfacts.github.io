---
description: "D'on surten els diners públics: impostos i cotitzacions socials a Espanya, per habitant, descomptada la inflació i en percentatge del PIB."
title: Ingressos públics i recaptació tributària
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 41be22719404
---

<script>
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
</script>

# D'on provenen els recursos públics a Espanya?

El sector públic espanyol es finança principalment per tres grans vies: **cotitzacions socials** pagades per treballadors i empreses, **impostos directes** sobre la renda i el benefici (IRPF i impost de societats) i **impostos indirectes** sobre el consum i la producció (IVA i impostos especials).

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
        title="Cotitzacions socials"
        value={resumen_tipos[0]?.cot_hab}
        formattedValue="{formatNumber(resumen_tipos[0]?.cot_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_tipos[0]?.cot_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_tipos[0]?.cot_pct, 1)}% dels ingressos · {ultimos_ingresos_totales[0]?.anio}"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
        sparklineData={serie_ingresos_real.filter(d => d.categoria === 'Cotizaciones Sociales').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="IRPF i patrimoni"
        value={resumen_tipos[0]?.irpf_hab}
        formattedValue="{formatNumber(resumen_tipos[0]?.irpf_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_tipos[0]?.irpf_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_tipos[0]?.irpf_pct, 1)}% dels ingressos · {ultimos_ingresos_totales[0]?.anio}"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
        sparklineData={serie_ingresos_real.filter(d => d.categoria === 'IRPF y Patrimonio').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="IVA (consum)"
        value={resumen_tipos[0]?.iva_hab}
        formattedValue="{formatNumber(resumen_tipos[0]?.iva_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_tipos[0]?.iva_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_tipos[0]?.iva_pct, 1)}% dels ingressos · {ultimos_ingresos_totales[0]?.anio}"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
        sparklineData={serie_ingresos_real.filter(d => d.categoria === 'IVA').map(d => d.eur_hab_real)}
    />
</Grid>

<p class="text-xs text-gray-500">Principi d'aquest web: els imports es mostren <b>per habitant</b> i <b>descomptada la inflació</b>, en euros de {base_deflactor[0]?.anio_base} segons l'IPC mitjà anual de l'INE, perquè les xifres d'anys diferents siguin comparables. Els totals en euros corrents apareixen com a dada secundària; els percentatges (dels ingressos o del PIB) no necessiten ajust.</p>

---

## 1. Composició dels ingressos públics a Espanya ({ultimos_ingresos_totales[0].anio})

El {ultimos_ingresos_totales[0]?.anio}, els ingressos del conjunt de les administracions públiques van arribar a **{formatNumber(ultimos_ingresos_totales[0]?.total_hab_real, 0)} euros per habitant** (en euros de {base_deflactor[0]?.anio_base}; {formatNumber(ultimos_ingresos_totales[0]?.total_ingresos / 1000, 1)} mil milions en total, el {formatNumber(ultimos_ingresos_totales[0]?.total_pib, 1)}% del PIB).

<BarChart
    data={ingresos_por_categoria_ultimo}
    x=categoria
    y=eur_hab_real
    yAxisTitle="Euros per habitant (euros de {base_deflactor[0]?.anio_base})"
    yFmt=num0
    title="Recaptació per habitant segons la categoria d'ingrés ({ultimos_ingresos_totales[0]?.anio}, euros de {base_deflactor[0]?.anio_base})"
    swapXY={true}
/>

<DataTable data={ingresos_por_categoria_ultimo} title="Detall dels ingressos ({ultimos_ingresos_totales[0].anio})">
    <Column id=categoria title="Categoria d'ingrés" />
    <Column id=tipo_ingreso title="Tipus de tribut" />
    <Column id=eur_hab_real title="Per habitant" fmt='#,##0 €' />
    <Column id=porcentaje_ingreso_total title="% sobre el total" fmt='0.0"%"' />
    <Column id=porcentaje_pib title="% sobre el PIB" fmt='0.0"%"' />
    <Column id=millones_euros title="Recaptació total (M€ corrents)" fmt='#,##0' />
</DataTable>

---

## 2. Evolució històrica dels ingressos per tipus de tribut

Ingressos per habitant de cada tipus, en euros de {base_deflactor[0]?.anio_base} (descomptada la inflació), des del 1996, primer any amb IPC anual disponible:

<AreaChart
    data={serie_ingresos_tipo}
    x=año
    y=eur_hab_real
    series=tipo_ingreso
    yAxisTitle="Euros per habitant (euros de {base_deflactor[0]?.anio_base})"
    yFmt=num0
    title="Ingressos públics per habitant i tipus de tribut (euros de {base_deflactor[0]?.anio_base}, descomptada la inflació)"
/>

---

## 3. Com es distribueix la càrrega fiscal?

- **Cotitzacions a la Seguretat Social ({formatNumber(resumen_tipos[0].cot_pct, 1)}%):** La principal font d'ingressos públics, destinada a sostenir les pensions contributives i les prestacions d'atur.
- **Impostos directes ({formatNumber(resumen_tipos[0].dir_pct, 1)}%):** Graven directament la renda dels ciutadans (IRPF), els beneficis declarats per les societats mercantils, el patrimoni i les herències.
- **Impostos indirectes ({formatNumber(resumen_tipos[0].ind_pct, 1)}%):** Graven el consum general (IVA) i productes específics com els carburants, el tabac, l'alcohol i l'electricitat (impostos especials), a més d'altres impostos sobre la producció.
- **Ingressos no tributaris i fons UE ({formatNumber(resumen_tipos[0].notrib_pct, 1)}%):** Vendes i taxes de serveis públics, rendes de la propietat (interessos, dividends) i transferències rebudes, inclosos els fons europeus Next Generation EU.

<small>Metodologia: els impostos i les cotitzacions procedeixen d'Eurostat (gov_10a_taxag) i els ingressos totals, de gov_10a_main. Les categories «Altres impostos» i «Ingressos no tributaris i fons UE» es calculen per diferència, de manera que la suma coincideix amb els ingressos totals oficials.</small>

---

## Fonts oficials
- **[Eurostat - Impostos i cotitzacions socials per figura (gov_10a_taxag)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_taxag):** Recaptació harmonitzada segons el SEC 2010.
- **[Eurostat - Comptes de les AP (gov_10a_main)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_main):** Ingressos totals de les administracions públiques.
- **[Agència Estatal d'Administració Tributària (AEAT)](https://sede.agenciatributaria.gob.es/Sede/estadisticas/recaudacion-tributaria.html):** Informes anuals i mensuals de recaptació.
- **[Intervenció General de l'Administració de l'Estat (IGAE)](https://www.igae.pap.hacienda.gob.es/):** Comptes econòmics i comptabilitat nacional del sector públic.
