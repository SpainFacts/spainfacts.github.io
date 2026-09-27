---
title: Ingresos Públicos y Recaudación Tributaria
---

<script>
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
</script>

# ¿De dónde provienen los recursos públicos en España?

El sector público español se financia principalmente a través de tres grandes vías: **cotizaciones sociales** abonadas por trabajadores y empresas, **impuestos directos** sobre la renta y el beneficio (IRPF e Impuesto de Sociedades) e **impuestos indirectos** sobre el consumo y la producción (IVA e Impuestos Especiales).

```sql ultimos_ingresos_totales
SELECT
    año AS anio,
    sum(millones_euros) AS total_ingresos,
    sum(porcentaje_pib) AS total_pib
FROM mother.cuentas_ingresos
WHERE año = (SELECT max(año) FROM mother.cuentas_ingresos)
GROUP BY año
```

```sql desglose_por_tipo
SELECT
    tipo_ingreso,
    sum(millones_euros) AS total_millones,
    sum(porcentaje_pib) AS pct_pib,
    sum(porcentaje_ingreso_total) AS pct_total
FROM mother.cuentas_ingresos
WHERE año = (SELECT max(año) FROM mother.cuentas_ingresos)
GROUP BY tipo_ingreso
ORDER BY total_millones DESC
```

```sql resumen_tipos
SELECT
    sum(CASE WHEN tipo_ingreso = 'Cotizaciones' THEN porcentaje_ingreso_total END) AS cot_pct,
    sum(CASE WHEN tipo_ingreso = 'Impuestos Directos' THEN porcentaje_ingreso_total END) AS dir_pct,
    sum(CASE WHEN tipo_ingreso = 'Impuestos Indirectos' THEN porcentaje_ingreso_total END) AS ind_pct,
    sum(CASE WHEN tipo_ingreso = 'No Tributarios' THEN porcentaje_ingreso_total END) AS notrib_pct,
    max(CASE WHEN categoria = 'Cotizaciones Sociales' THEN millones_euros END) AS cot_mio,
    max(CASE WHEN categoria = 'IRPF y Patrimonio' THEN millones_euros END) AS irpf_mio,
    max(CASE WHEN categoria = 'IRPF y Patrimonio' THEN porcentaje_ingreso_total END) AS irpf_pct,
    max(CASE WHEN categoria = 'IVA' THEN millones_euros END) AS iva_mio,
    max(CASE WHEN categoria = 'IVA' THEN porcentaje_ingreso_total END) AS iva_pct
FROM mother.cuentas_ingresos
WHERE año = (SELECT max(año) FROM mother.cuentas_ingresos)
```

```sql ingresos_por_categoria_ultimo
SELECT
    categoria,
    tipo_ingreso,
    millones_euros,
    porcentaje_pib,
    porcentaje_ingreso_total
FROM mother.cuentas_ingresos
WHERE año = (SELECT max(año) FROM mother.cuentas_ingresos)
ORDER BY millones_euros DESC
```

```sql serie_ingresos_categoria
SELECT
    año,
    categoria,
    millones_euros / 1000.0 AS miles_millones
FROM mother.cuentas_ingresos
ORDER BY año ASC, millones_euros DESC
```

```sql serie_ingresos_tipo
SELECT
    año,
    tipo_ingreso,
    sum(millones_euros) / 1000.0 AS miles_millones
FROM mother.cuentas_ingresos
GROUP BY año, tipo_ingreso
ORDER BY año ASC
```

<Grid cols=3>
    <KpiCard
        title="Cotizaciones Sociales"
        value={resumen_tipos[0].cot_mio}
        formattedValue="{formatNumber(resumen_tipos[0].cot_mio / 1000, 1)} mil M€"
        unit="en {ultimos_ingresos_totales[0].anio}"
        period="{formatNumber(resumen_tipos[0].cot_pct, 1)}% del total de ingresos"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
    />

    <KpiCard
        title="IRPF y Patrimonio"
        value={resumen_tipos[0].irpf_mio}
        formattedValue="{formatNumber(resumen_tipos[0].irpf_mio / 1000, 1)} mil M€"
        unit="en {ultimos_ingresos_totales[0].anio}"
        period="{formatNumber(resumen_tipos[0].irpf_pct, 1)}% del total de ingresos"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
    />

    <KpiCard
        title="IVA (Consumo)"
        value={resumen_tipos[0].iva_mio}
        formattedValue="{formatNumber(resumen_tipos[0].iva_mio / 1000, 1)} mil M€"
        unit="en {ultimos_ingresos_totales[0].anio}"
        period="{formatNumber(resumen_tipos[0].iva_pct, 1)}% del total de ingresos"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
    />
</Grid>

---

## 1. Composición de los Ingresos Públicos en España ({ultimos_ingresos_totales[0].anio})

En {ultimos_ingresos_totales[0].anio}, los ingresos del conjunto de las Administraciones Públicas alcanzaron **{formatNumber(ultimos_ingresos_totales[0].total_ingresos / 1000, 1)} mil millones de euros** ({formatNumber(ultimos_ingresos_totales[0].total_pib, 1)}% del PIB).

<BarChart
    data={ingresos_por_categoria_ultimo}
    x=categoria
    y=millones_euros
    yAxisTitle="Millones de Euros (€)"
    title="Recaudación por categoría de ingreso ({ultimos_ingresos_totales[0].anio})"
    swapXY={true}
/>

<DataTable data={ingresos_por_categoria_ultimo} title="Detalle de Ingresos ({ultimos_ingresos_totales[0].anio})">
    <Column id=categoria title="Categoría de Ingreso" />
    <Column id=tipo_ingreso title="Tipo de Tributo" />
    <Column id=millones_euros title="Recaudación (M€)" fmt='#,##0 M€' />
    <Column id=porcentaje_ingreso_total title="% sobre el Total" fmt='0.0"%"' />
    <Column id=porcentaje_pib title="% sobre el PIB" fmt='0.0"%"' />
</DataTable>

---

## 2. Evolución Histórica de los Ingresos por Tipo de Tributo

<AreaChart
    data={serie_ingresos_tipo}
    x=año
    y=miles_millones
    series=tipo_ingreso
    yAxisTitle="Miles de Millones de Euros (Mrd €)"
    title="Evolución de los Ingresos Públicos por tipo de tributo"
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
