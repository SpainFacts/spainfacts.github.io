---
title: Gasto Público y Destino del Presupuesto
---

<script>
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
</script>

# ¿En qué gasta el Estado y cuánto cuesta por ciudadano?

El gasto público consolidado en España alcanzó en 2024 aproximadamente **683.400 millones de euros** (~44% del PIB). La mayor parte del presupuesto se destina a las funciones del **Estado del Bienestar**: pensiones, sanidad y educación representan más del **61% de todo el gasto público**.

```sql gastos_2024
SELECT
    funcion_cofog,
    categoria_macro,
    millones_euros,
    porcentaje_gasto_total,
    porcentaje_pib,
    gasto_por_habitante_eur
FROM cuentas.gastos
WHERE año = 2024
ORDER BY millones_euros DESC
```

```sql serie_gastos_macro
SELECT
    año,
    categoria_macro,
    sum(millones_euros) / 1000.0 AS miles_millones
FROM cuentas.gastos
GROUP BY año, categoria_macro
ORDER BY año ASC
```

```sql serie_gastos_funcion
SELECT
    año,
    funcion_cofog,
    millones_euros / 1000.0 AS miles_millones
FROM cuentas.gastos
ORDER BY año ASC, millones_euros DESC
```

<Grid cols=3>
    <KpiCard
        title="Pensiones y Protección Social"
        value={251200}
        formattedValue="251,2 mil M€"
        unit="5.137 € / hab."
        period="36,8% del gasto total"
        direction="neutral"
        source="Seguridad Social / IGAE"
    />

    <KpiCard
        title="Sanidad Pública"
        value={103500}
        formattedValue="103,5 mil M€"
        unit="2.117 € / hab."
        period="15,1% del gasto total"
        direction="neutral"
        source="Min. Sanidad / CC.AA."
    />

    <KpiCard
        title="Educación"
        value={65200}
        formattedValue="65,2 mil M€"
        unit="1.333 € / hab."
        period="9,5% del gasto total"
        direction="neutral"
        source="Min. Educación / CC.AA."
    />
</Grid>

---

## 1. Gasto Anual por Habitante en España (2024)

Dividiendo el gasto total entre los ~48,9 millones de residentes en España, este es el coste promedio anual por habitante de cada servicio público:

<BarChart
    data={gastos_2024}
    x=funcion_cofog
    y=gasto_por_habitante_eur
    yAxisTitle="Euros (€) por habitante al año"
    title="Gasto público por habitante al año según función (2024)"
    swapXY={true}
/>

<DataTable data={gastos_2024} title="Clasificación Funcional del Gasto (COFOG 2024)">
    <Column id=funcion_cofog title="Función de Gasto" />
    <Column id=categoria_macro title="Macro-Categoría" />
    <Column id=millones_euros title="Total (M€)" fmt='#,##0 M€' />
    <Column id=porcentaje_gasto_total title="% Gasto Total" fmt='0.0"%"' />
    <Column id=gasto_por_habitante_eur title="Por Habitante" fmt='#,##0 €' />
    <Column id=porcentaje_pib title="% sobre el PIB" fmt='0.0"%"' />
</DataTable>

---

## 2. Evolución del Gasto por Grandes Bloques (2019-2024)

<AreaChart
    data={serie_gastos_macro}
    x=año
    y=miles_millones
    series=categoria_macro
    yAxisTitle="Miles de Millones de Euros (Mrd €)"
    title="Evolución del Gasto Público por Bloque Funcional"
/>

---

## 3. Desglose de las Principales Funciones de Gasto

- **Protección Social y Pensiones (36,8%):** El mayor desembolso del sector público, que incluye pensiones contributivas de jubilación, viudedad e incapacidad, así como subsidios de desempleo y dependencia.
- **Sanidad Pública (15,1%):** Gestionada fundamentalmente por las 17 Comunidades Autónomas para financiar hospitales, centros de salud, personal médico y gasto farmacéutico.
- **Educación (9,5%):** Financiación de la enseñanza infantil, primaria, secundaria, formación profesional y universidades públicas.
- **Intereses de la Deuda Pública (5,6%):** Pago periódico de intereses a los inversores tenedores de bonos y obligaciones del Estado, un coste financiero que no genera servicio directo pero condiciona la capacidad presupuestaria.
- **Economía, Transporte e Infraestructuras (10,6%):** Inversión en red ferroviaria (AVE/Cercanías), carreteras, aeropuertos, agricultura y transición energética.
- **Seguridad Ciudadana y Justicia (4,2%):** Mantenimiento de las Fuerzas y Cuerpos de Seguridad (Policía Nacional, Guardia Civil, Policías Autonómicas), tribunales y centros penitenciarios.
- **Defensa (2,5%):** Mantenimiento de las Fuerzas Armadas (Ejército de Tierra, Armada y Ejército del Aire y del Espacio) y programas de modernización militar.

---

## Fuentes Oficiales
- **[Clasificación Funcional del Gasto COFOG (Eurostat / IGAE)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp):** Clasificación estandarizada de las funciones de gobierno según Naciones Unidas y la Unión Europea.
- **[Presupuestos Generales del Estado (Ministerio de Hacienda)](https://www.sepg.pap.hacienda.gob.es/):** Series de gasto de los ministerios y organismos públicos.
