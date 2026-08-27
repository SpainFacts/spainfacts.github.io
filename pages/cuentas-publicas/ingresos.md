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
    sum(millones_euros) AS total_ingresos,
    año
FROM cuentas.ingresos
WHERE año = 2024
GROUP BY año
```

```sql desglose_por_tipo
SELECT
    tipo_ingreso,
    sum(millones_euros) AS total_millones,
    sum(porcentaje_pib) AS pct_pib,
    sum(porcentaje_ingreso_total) AS pct_total
FROM cuentas.ingresos
WHERE año = 2024
GROUP BY tipo_ingreso
ORDER BY total_millones DESC
```

```sql ingresos_por_categoria_2024
SELECT
    categoria,
    tipo_ingreso,
    millones_euros,
    porcentaje_pib,
    porcentaje_ingreso_total
FROM cuentas.ingresos
WHERE año = 2024
ORDER BY millones_euros DESC
```

```sql serie_ingresos_categoria
SELECT
    año,
    categoria,
    millones_euros / 1000.0 AS miles_millones
FROM cuentas.ingresos
ORDER BY año ASC, millones_euros DESC
```

```sql serie_ingresos_tipo
SELECT
    año,
    tipo_ingreso,
    sum(millones_euros) / 1000.0 AS miles_millones
FROM cuentas.ingresos
GROUP BY año, tipo_ingreso
ORDER BY año ASC
```

<Grid cols=3>
    <KpiCard
        title="Cotizaciones Sociales"
        value={211500}
        formattedValue="211,5 mil M€"
        unit="en 2024"
        period="33,3% del total de ingresos"
        direction="neutral"
        source="Seguridad Social / IGAE"
    />

    <KpiCard
        title="IRPF y Patrimonio"
        value={144800}
        formattedValue="144,8 mil M€"
        unit="en 2024"
        period="22,8% del total de ingresos"
        direction="neutral"
        source="AEAT / IGAE"
    />

    <KpiCard
        title="IVA (Consumo)"
        value={104600}
        formattedValue="104,6 mil M€"
        unit="en 2024"
        period="16,5% del total de ingresos"
        direction="neutral"
        source="AEAT / IGAE"
    />
</Grid>

---

## 1. Composición de los Ingresos Públicos en España (2024)

En 2024, los ingresos del conjunto de las Administraciones Públicas alcanzaron aproximadamente **635.800 millones de euros** (~41% del PIB).

<BarChart
    data={ingresos_por_categoria_2024}
    x=categoria
    y=millones_euros
    yAxisTitle="Millones de Euros (€)"
    title="Recaudación por categoría de ingreso (2024)"
    swapXY={true}
/>

<DataTable data={ingresos_por_categoria_2024} title="Detalle de Ingresos (2024)">
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
    title="Evolución de los Ingresos Públicos por tipo de tributo (2019-2024)"
/>

---

## 3. ¿Cómo se distribuye la carga fiscal?

- **Cotizaciones a la Seguridad Social (33,3%):** La principal fuente de ingresos públicos, destinada a sostener las pensiones contributivas y las prestaciones por desempleo.
- **Impuestos Directos (~29,5%):** Gravan directamente la renta de los ciudadanos (IRPF) y los beneficios declarados por las sociedades mercantiles.
- **Impuestos Indirectos (~27,2%):** Gravan el consumo general (IVA) y productos específicos como carburantes, tabaco, alcohol y electricidad (Impuestos Especiales).
- **Ingresos No Tributarios y Fondos UE (~10,2%):** Tasas administrativas, ingresos patrimoniales (dividendos públicos, loterías) y transferencias procedentes de los fondos europeos Next Generation EU.

---

## Fuentes Oficiales
- **[Intervención General de la Administración del Estado (IGAE)](https://www.igae.pap.hacienda.gob.es/):** Cuentas Económicas y Contabilidad Nacional del Sector Público.
- **[Agencia Estatal de Administración Tributaria (AEAT)](https://sede.agenciatributaria.gob.es/Sede/estadisticas/recaudacion-tributaria.html):** Informes Anuales y Mensuales de Recaudación.
- **[Eurostat - Government Revenue (gov_10a_rev)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_rev):** Cuentas no financieras anuales armonizadas.
