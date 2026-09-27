---
title: Gasto Público y Destino del Presupuesto
---

<script>
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
</script>

```sql gastos_ultimo
SELECT
    año AS anio,
    funcion_cofog,
    categoria_macro,
    millones_euros,
    porcentaje_gasto_total,
    porcentaje_pib,
    gasto_por_habitante_eur
FROM mother.cuentas_gastos
WHERE año = (SELECT max(año) FROM mother.cuentas_gastos)
ORDER BY millones_euros DESC
```

```sql resumen_gastos
SELECT
    año AS anio,
    sum(millones_euros) AS total_mio,
    sum(porcentaje_pib) AS total_pib,
    sum(CASE WHEN categoria_macro = 'Gasto Social' THEN porcentaje_gasto_total END) AS social_pct,
    max(CASE WHEN funcion_cofog = 'Protección Social y Pensiones' THEN millones_euros END) AS pens_mio,
    max(CASE WHEN funcion_cofog = 'Protección Social y Pensiones' THEN gasto_por_habitante_eur END) AS pens_hab,
    max(CASE WHEN funcion_cofog = 'Protección Social y Pensiones' THEN porcentaje_gasto_total END) AS pens_pct,
    max(CASE WHEN funcion_cofog = 'Sanidad Pública' THEN millones_euros END) AS san_mio,
    max(CASE WHEN funcion_cofog = 'Sanidad Pública' THEN gasto_por_habitante_eur END) AS san_hab,
    max(CASE WHEN funcion_cofog = 'Sanidad Pública' THEN porcentaje_gasto_total END) AS san_pct,
    max(CASE WHEN funcion_cofog = 'Educación' THEN millones_euros END) AS edu_mio,
    max(CASE WHEN funcion_cofog = 'Educación' THEN gasto_por_habitante_eur END) AS edu_hab,
    max(CASE WHEN funcion_cofog = 'Educación' THEN porcentaje_gasto_total END) AS edu_pct,
    max(CASE WHEN funcion_cofog = 'Intereses de la Deuda' THEN porcentaje_gasto_total END) AS int_pct,
    max(CASE WHEN funcion_cofog = 'Asuntos Económicos y Transporte' THEN porcentaje_gasto_total END) AS eco_pct,
    max(CASE WHEN funcion_cofog = 'Orden Público y Seguridad' THEN porcentaje_gasto_total END) AS seg_pct,
    max(CASE WHEN funcion_cofog = 'Defensa' THEN porcentaje_gasto_total END) AS def_pct
FROM mother.cuentas_gastos
WHERE año = (SELECT max(año) FROM mother.cuentas_gastos)
GROUP BY año
```

```sql poblacion_ultimo
SELECT poblacion_m
FROM mother.cuentas_balance_anual
WHERE año = (SELECT max(año) FROM mother.cuentas_gastos)
```

```sql serie_gastos_macro
SELECT
    año,
    categoria_macro,
    sum(millones_euros) / 1000.0 AS miles_millones
FROM mother.cuentas_gastos
GROUP BY año, categoria_macro
ORDER BY año ASC
```

```sql serie_gastos_funcion
SELECT
    año,
    funcion_cofog,
    millones_euros / 1000.0 AS miles_millones
FROM mother.cuentas_gastos
ORDER BY año ASC, millones_euros DESC
```

# ¿En qué gasta el Estado y cuánto cuesta por ciudadano?

El gasto público consolidado en España alcanzó en {resumen_gastos[0].anio} **{formatNumber(resumen_gastos[0].total_mio / 1000, 1)} mil millones de euros** ({formatNumber(resumen_gastos[0].total_pib, 1)}% del PIB). La mayor parte del presupuesto se destina a las funciones del **Estado del Bienestar**: protección social y pensiones, sanidad y educación representan el **{formatNumber(resumen_gastos[0].social_pct, 1)}% de todo el gasto público**.

<Grid cols=3>
    <KpiCard
        title="Pensiones y Protección Social"
        value={resumen_gastos[0].pens_mio}
        formattedValue="{formatNumber(resumen_gastos[0].pens_mio / 1000, 1)} mil M€"
        unit="{formatNumber(resumen_gastos[0].pens_hab, 0)} € / hab."
        period="{formatNumber(resumen_gastos[0].pens_pct, 1)}% del gasto total · {resumen_gastos[0].anio}"
        direction="neutral"
        source="Eurostat (COFOG GF10)"
    />

    <KpiCard
        title="Sanidad Pública"
        value={resumen_gastos[0].san_mio}
        formattedValue="{formatNumber(resumen_gastos[0].san_mio / 1000, 1)} mil M€"
        unit="{formatNumber(resumen_gastos[0].san_hab, 0)} € / hab."
        period="{formatNumber(resumen_gastos[0].san_pct, 1)}% del gasto total · {resumen_gastos[0].anio}"
        direction="neutral"
        source="Eurostat (COFOG GF07)"
    />

    <KpiCard
        title="Educación"
        value={resumen_gastos[0].edu_mio}
        formattedValue="{formatNumber(resumen_gastos[0].edu_mio / 1000, 1)} mil M€"
        unit="{formatNumber(resumen_gastos[0].edu_hab, 0)} € / hab."
        period="{formatNumber(resumen_gastos[0].edu_pct, 1)}% del gasto total · {resumen_gastos[0].anio}"
        direction="neutral"
        source="Eurostat (COFOG GF09)"
    />
</Grid>

---

## 1. Gasto Anual por Habitante en España ({resumen_gastos[0].anio})

Dividiendo el gasto de cada función entre los ~{formatNumber(poblacion_ultimo[0].poblacion_m, 1)} millones de residentes en España (población media anual), este es el coste promedio anual por habitante de cada servicio público:

<BarChart
    data={gastos_ultimo}
    x=funcion_cofog
    y=gasto_por_habitante_eur
    yAxisTitle="Euros (€) por habitante al año"
    title="Gasto público por habitante al año según función ({resumen_gastos[0].anio})"
    swapXY={true}
/>

<DataTable data={gastos_ultimo} title="Clasificación Funcional del Gasto (COFOG {resumen_gastos[0].anio})">
    <Column id=funcion_cofog title="Función de Gasto" />
    <Column id=categoria_macro title="Macro-Categoría" />
    <Column id=millones_euros title="Total (M€)" fmt='#,##0 M€' />
    <Column id=porcentaje_gasto_total title="% Gasto Total" fmt='0.0"%"' />
    <Column id=gasto_por_habitante_eur title="Por Habitante" fmt='#,##0 €' />
    <Column id=porcentaje_pib title="% sobre el PIB" fmt='0.0"%"' />
</DataTable>

---

## 2. Evolución del Gasto por Grandes Bloques

<AreaChart
    data={serie_gastos_macro}
    x=año
    y=miles_millones
    series=categoria_macro
    yAxisTitle="Miles de Millones de Euros (Mrd €)"
    title="Evolución del Gasto Público por Bloque Funcional"
/>

---

## 3. Desglose de las Principales Funciones de Gasto ({resumen_gastos[0].anio})

- **Protección Social y Pensiones ({formatNumber(resumen_gastos[0].pens_pct, 1)}%):** El mayor desembolso del sector público, que incluye pensiones contributivas de jubilación, viudedad e incapacidad, así como subsidios de desempleo y dependencia.
- **Sanidad Pública ({formatNumber(resumen_gastos[0].san_pct, 1)}%):** Gestionada fundamentalmente por las 17 Comunidades Autónomas para financiar hospitales, centros de salud, personal médico y gasto farmacéutico.
- **Educación ({formatNumber(resumen_gastos[0].edu_pct, 1)}%):** Financiación de la enseñanza infantil, primaria, secundaria, formación profesional y universidades públicas.
- **Intereses de la Deuda Pública ({formatNumber(resumen_gastos[0].int_pct, 1)}%):** Pago periódico de intereses a los inversores tenedores de bonos y obligaciones del Estado (COFOG GF0107, separado aquí de los Servicios Públicos Generales), un coste financiero que no genera servicio directo pero condiciona la capacidad presupuestaria.
- **Economía, Transporte e Infraestructuras ({formatNumber(resumen_gastos[0].eco_pct, 1)}%):** Inversión en red ferroviaria (AVE/Cercanías), carreteras, aeropuertos, agricultura y transición energética.
- **Seguridad Ciudadana y Justicia ({formatNumber(resumen_gastos[0].seg_pct, 1)}%):** Mantenimiento de las Fuerzas y Cuerpos de Seguridad (Policía Nacional, Guardia Civil, Policías Autonómicas), tribunales y centros penitenciarios.
- **Defensa ({formatNumber(resumen_gastos[0].def_pct, 1)}%):** Mantenimiento de las Fuerzas Armadas (Ejército de Tierra, Armada y Ejército del Aire y del Espacio) y programas de modernización militar.

---

## Fuentes Oficiales
- **[Clasificación Funcional del Gasto COFOG (Eurostat gov_10a_exp)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp):** Gasto consolidado de las AAPP por función según la clasificación estandarizada de Naciones Unidas y la Unión Europea.
- **[PIB a precios corrientes (Eurostat nama_10_gdp)](https://ec.europa.eu/eurostat/databrowser/view/nama_10_gdp) y [población media (nama_10_pe)](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe):** Denominadores para los porcentajes sobre PIB y el gasto por habitante.
- **[Presupuestos Generales del Estado (Ministerio de Hacienda)](https://www.sepg.pap.hacienda.gob.es/):** Series de gasto de los ministerios y organismos públicos.
