---
title: Ingresos Públicos y Recaudación Tributaria
---

<script>
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
</script>

# ¿De dónde provienen los recursos públicos en España?

El sector público español se financia principalmente a través de tres grandes vías: **cotizaciones sociales** abonadas por trabajadores y empresas, **impuestos directos** sobre la renta y el beneficio (IRPF e Impuesto de Sociedades) e **impuestos indirectos** sobre el consumo y la producción (IVA e Impuestos Especiales).

```sql base_deflactor
-- Año cuyos euros se usan como referencia (último año completo con IPC)
SELECT CAST(max(anio_base) AS INTEGER) AS anio_base FROM mother.deflactor
```

```sql ingresos_hab
-- Ingresos por habitante en euros constantes: millones / población (millones) * factor del deflactor
SELECT
    CAST(i.año AS INTEGER) AS anio,
    i.categoria,
    i.tipo_ingreso,
    i.millones_euros,
    i.porcentaje_pib,
    i.porcentaje_ingreso_total,
    i.millones_euros / b.poblacion_m * d.factor AS eur_hab_real
FROM mother.cuentas_ingresos i
JOIN mother.cuentas_balance_anual b ON CAST(b.año AS INTEGER) = CAST(i.año AS INTEGER)
JOIN mother.deflactor d ON CAST(d.anio AS INTEGER) = CAST(i.año AS INTEGER)
WHERE b.poblacion_m > 0
```

```sql ultimos_ingresos_totales
SELECT
    anio,
    sum(millones_euros) AS total_ingresos,
    sum(eur_hab_real) AS total_hab_real,
    sum(porcentaje_pib) AS total_pib
FROM ${ingresos_hab}
WHERE anio = (SELECT max(año) FROM mother.cuentas_ingresos)
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
WHERE anio = (SELECT max(año) FROM mother.cuentas_ingresos)
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
WHERE anio = (SELECT max(año) FROM mother.cuentas_ingresos)
ORDER BY millones_euros DESC
```

```sql serie_ingresos_categoria
-- Euros por habitante a precios constantes (el deflactor empieza en 2002)
SELECT
    anio AS año,
    categoria,
    eur_hab_real
FROM ${ingresos_hab}
ORDER BY año ASC, eur_hab_real DESC
```

```sql serie_ingresos_tipo
-- Euros por habitante a precios constantes (el deflactor empieza en 2002)
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
        title="Cotizaciones Sociales"
        value={resumen_tipos[0]?.cot_hab}
        formattedValue="{formatNumber(resumen_tipos[0]?.cot_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_tipos[0]?.cot_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_tipos[0]?.cot_pct, 1)}% de los ingresos · {ultimos_ingresos_totales[0]?.anio}"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
        sparklineData={serie_ingresos_real.filter(d => d.categoria === 'Cotizaciones Sociales').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="IRPF y Patrimonio"
        value={resumen_tipos[0]?.irpf_hab}
        formattedValue="{formatNumber(resumen_tipos[0]?.irpf_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_tipos[0]?.irpf_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_tipos[0]?.irpf_pct, 1)}% de los ingresos · {ultimos_ingresos_totales[0]?.anio}"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
        sparklineData={serie_ingresos_real.filter(d => d.categoria === 'IRPF y Patrimonio').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="IVA (Consumo)"
        value={resumen_tipos[0]?.iva_hab}
        formattedValue="{formatNumber(resumen_tipos[0]?.iva_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_tipos[0]?.iva_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_tipos[0]?.iva_pct, 1)}% de los ingresos · {ultimos_ingresos_totales[0]?.anio}"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
        sparklineData={serie_ingresos_real.filter(d => d.categoria === 'IVA').map(d => d.eur_hab_real)}
    />
</Grid>

<p class="text-xs text-gray-500">Principio de esta web: los importes se muestran <b>por habitante</b> y <b>descontada la inflación</b>, en euros de {base_deflactor[0]?.anio_base} según el IPC medio anual del INE, para que las cifras de años distintos sean comparables. Los totales en euros corrientes aparecen como dato secundario; los porcentajes (de los ingresos o del PIB) no necesitan ajuste.</p>

---

## 1. Composición de los Ingresos Públicos en España ({ultimos_ingresos_totales[0].anio})

En {ultimos_ingresos_totales[0]?.anio}, los ingresos del conjunto de las Administraciones Públicas alcanzaron **{formatNumber(ultimos_ingresos_totales[0]?.total_hab_real, 0)} euros por habitante** (en euros de {base_deflactor[0]?.anio_base}; {formatNumber(ultimos_ingresos_totales[0]?.total_ingresos / 1000, 1)} mil millones en total, el {formatNumber(ultimos_ingresos_totales[0]?.total_pib, 1)}% del PIB).

<BarChart
    data={ingresos_por_categoria_ultimo}
    x=categoria
    y=eur_hab_real
    yAxisTitle="Euros por habitante (euros de {base_deflactor[0]?.anio_base})"
    yFmt=num0
    title="Recaudación por habitante según categoría de ingreso ({ultimos_ingresos_totales[0]?.anio}, euros de {base_deflactor[0]?.anio_base})"
    swapXY={true}
/>

<DataTable data={ingresos_por_categoria_ultimo} title="Detalle de Ingresos ({ultimos_ingresos_totales[0].anio})">
    <Column id=categoria title="Categoría de Ingreso" />
    <Column id=tipo_ingreso title="Tipo de Tributo" />
    <Column id=eur_hab_real title="Por habitante" fmt='#,##0 €' />
    <Column id=porcentaje_ingreso_total title="% sobre el Total" fmt='0.0"%"' />
    <Column id=porcentaje_pib title="% sobre el PIB" fmt='0.0"%"' />
    <Column id=millones_euros title="Recaudación total (M€ corrientes)" fmt='#,##0' />
</DataTable>

---

## 2. Evolución Histórica de los Ingresos por Tipo de Tributo

Ingresos por habitante de cada tipo, en euros de {base_deflactor[0]?.anio_base} (descontada la inflación), desde 2002, primer año con IPC anual disponible:

<AreaChart
    data={serie_ingresos_tipo}
    x=año
    y=eur_hab_real
    series=tipo_ingreso
    yAxisTitle="Euros por habitante (euros de {base_deflactor[0]?.anio_base})"
    yFmt=num0
    title="Ingresos públicos por habitante y tipo de tributo (euros de {base_deflactor[0]?.anio_base}, descontada la inflación)"
/>

---

## 3. ¿Cómo se distribuye la carga fiscal?

- **Cotizaciones a la Seguridad Social ({formatNumber(resumen_tipos[0].cot_pct, 1)}%):** La principal fuente de ingresos públicos, destinada a sostener las pensiones contributivas y las prestaciones por desempleo.
- **Impuestos Directos ({formatNumber(resumen_tipos[0].dir_pct, 1)}%):** Gravan directamente la renta de los ciudadanos (IRPF), los beneficios declarados por las sociedades mercantiles, el patrimonio y las herencias.
- **Impuestos Indirectos ({formatNumber(resumen_tipos[0].ind_pct, 1)}%):** Gravan el consumo general (IVA) y productos específicos como carburantes, tabaco, alcohol y electricidad (Impuestos Especiales), además de otros impuestos sobre la producción.
- **Ingresos No Tributarios y Fondos UE ({formatNumber(resumen_tipos[0].notrib_pct, 1)}%):** Ventas y tasas de servicios públicos, rentas de la propiedad (intereses, dividendos) y transferencias recibidas, incluidos los fondos europeos Next Generation EU.

<small>Metodología: los impuestos y cotizaciones proceden de Eurostat (gov_10a_taxag) y los ingresos totales de gov_10a_main. Las categorías «Otros impuestos» e «Ingresos No Tributarios y Fondos UE» se calculan por diferencia, de modo que la suma coincide con los ingresos totales oficiales.</small>

---

## Fuentes Oficiales
- **[Eurostat - Impuestos y cotizaciones sociales por figura (gov_10a_taxag)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_taxag):** Recaudación armonizada según el SEC 2010.
- **[Eurostat - Cuentas de las AAPP (gov_10a_main)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_main):** Ingresos totales de las Administraciones Públicas.
- **[Agencia Estatal de Administración Tributaria (AEAT)](https://sede.agenciatributaria.gob.es/Sede/estadisticas/recaudacion-tributaria.html):** Informes Anuales y Mensuales de Recaudación.
- **[Intervención General de la Administración del Estado (IGAE)](https://www.igae.pap.hacienda.gob.es/):** Cuentas Económicas y Contabilidad Nacional del Sector Público.
