---
description: "En qué gasta el dinero público España: gasto por funciones (pensiones, sanidad, educación...), por habitante y descontada la inflación, y su peso en el PIB."
title: Gasto Público y Destino del Presupuesto
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
</script>

```sql base_deflactor
-- Año cuyos euros se usan como referencia (último año completo con IPC)
SELECT CAST(max(anio_base) AS INTEGER) AS anio_base FROM mother.deflactor
```

```sql gastos_ultimo
SELECT
    g.anio,
    g.funcion_cofog,
    g.categoria_macro,
    g.millones_euros,
    g.porcentaje_gasto_total,
    g.porcentaje_pib,
    g.gasto_eur_hab_real AS gasto_hab_real
FROM mother.cuentas_gastos g
WHERE g.anio = (SELECT max(anio) FROM mother.cuentas_gastos)
ORDER BY g.millones_euros DESC
```

```sql resumen_gastos
-- Por habitante en euros constantes (gasto_eur_hab_real, ya calculado en la tabla)
SELECT
    g.anio,
    sum(g.millones_euros) AS total_mio,
    sum(g.gasto_eur_hab_real) AS total_hab_real,
    sum(g.porcentaje_pib) AS total_pib,
    sum(CASE WHEN g.categoria_macro = 'Gasto Social' THEN g.porcentaje_gasto_total END) AS social_pct,
    max(CASE WHEN g.funcion_cofog = 'Protección Social y Pensiones' THEN g.millones_euros END) AS pens_mio,
    max(CASE WHEN g.funcion_cofog = 'Protección Social y Pensiones' THEN g.gasto_eur_hab_real END) AS pens_hab,
    max(CASE WHEN g.funcion_cofog = 'Protección Social y Pensiones' THEN g.porcentaje_gasto_total END) AS pens_pct,
    max(CASE WHEN g.funcion_cofog = 'Sanidad Pública' THEN g.millones_euros END) AS san_mio,
    max(CASE WHEN g.funcion_cofog = 'Sanidad Pública' THEN g.gasto_eur_hab_real END) AS san_hab,
    max(CASE WHEN g.funcion_cofog = 'Sanidad Pública' THEN g.porcentaje_gasto_total END) AS san_pct,
    max(CASE WHEN g.funcion_cofog = 'Educación' THEN g.millones_euros END) AS edu_mio,
    max(CASE WHEN g.funcion_cofog = 'Educación' THEN g.gasto_eur_hab_real END) AS edu_hab,
    max(CASE WHEN g.funcion_cofog = 'Educación' THEN g.porcentaje_gasto_total END) AS edu_pct,
    max(CASE WHEN g.funcion_cofog = 'Intereses de la Deuda' THEN g.porcentaje_gasto_total END) AS int_pct,
    max(CASE WHEN g.funcion_cofog = 'Asuntos Económicos y Transporte' THEN g.porcentaje_gasto_total END) AS eco_pct,
    max(CASE WHEN g.funcion_cofog = 'Orden Público y Seguridad' THEN g.porcentaje_gasto_total END) AS seg_pct,
    max(CASE WHEN g.funcion_cofog = 'Defensa' THEN g.porcentaje_gasto_total END) AS def_pct
FROM mother.cuentas_gastos g
WHERE g.anio = (SELECT max(anio) FROM mother.cuentas_gastos)
GROUP BY g.anio
```

```sql poblacion_ultimo
SELECT poblacion / 1e6 AS poblacion_m
FROM mother.cuentas_balance_anual
WHERE anio = (SELECT max(anio) FROM mother.cuentas_gastos)
```

```sql serie_gastos_macro
-- Euros por habitante a precios constantes (el deflactor empieza en 1996)
SELECT
    g.anio AS año,
    g.categoria_macro,
    sum(g.gasto_eur_hab_real) AS eur_hab_real
FROM mother.cuentas_gastos g
WHERE g.gasto_eur_hab_real IS NOT NULL
GROUP BY 1, 2
ORDER BY 1 ASC
```

```sql serie_gastos_funcion
SELECT
    g.anio AS año,
    g.funcion_cofog,
    g.gasto_eur_hab_real AS eur_hab_real
FROM mother.cuentas_gastos g
WHERE g.gasto_eur_hab_real IS NOT NULL
ORDER BY 1 ASC, 3 DESC
```

```sql serie_gastos_real
-- Para las mini-gráficas: euros por habitante a precios constantes (mother.deflactor)
SELECT
    año AS anio,
    funcion_cofog,
    eur_hab_real
FROM ${serie_gastos_funcion}
WHERE funcion_cofog IN ('Protección Social y Pensiones', 'Sanidad Pública', 'Educación')
  AND eur_hab_real IS NOT NULL
ORDER BY anio
```

# ¿En qué gasta el Estado y cuánto cuesta por ciudadano?

El gasto público consolidado en España alcanzó en {resumen_gastos[0]?.anio} **{formatNumber(resumen_gastos[0]?.total_hab_real, 0)} euros por habitante** ({formatNumber(resumen_gastos[0]?.total_mio / 1000, 1)} mil millones en total, el {formatNumber(resumen_gastos[0]?.total_pib, 1)}% del PIB). La mayor parte del presupuesto se destina a las funciones del **Estado del Bienestar**: protección social y pensiones, sanidad y educación representan el **{formatNumber(resumen_gastos[0].social_pct, 1)}% de todo el gasto público**.

<Grid cols=3>
    <KpiCard
        title="Pensiones y Protección Social"
        value={resumen_gastos[0]?.pens_hab}
        formattedValue="{formatNumber(resumen_gastos[0]?.pens_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_gastos[0]?.pens_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_gastos[0]?.pens_pct, 1)}% del gasto · {resumen_gastos[0]?.anio}"
        direction="neutral"
        source="Eurostat (COFOG GF10)"
        sparklineData={serie_gastos_real.filter(d => d.funcion_cofog === 'Protección Social y Pensiones').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="Sanidad Pública"
        value={resumen_gastos[0]?.san_hab}
        formattedValue="{formatNumber(resumen_gastos[0]?.san_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_gastos[0]?.san_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_gastos[0]?.san_pct, 1)}% del gasto · {resumen_gastos[0]?.anio}"
        direction="neutral"
        source="Eurostat (COFOG GF07)"
        sparklineData={serie_gastos_real.filter(d => d.funcion_cofog === 'Sanidad Pública').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="Educación"
        value={resumen_gastos[0]?.edu_hab}
        formattedValue="{formatNumber(resumen_gastos[0]?.edu_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_gastos[0]?.edu_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_gastos[0]?.edu_pct, 1)}% del gasto · {resumen_gastos[0]?.anio}"
        direction="neutral"
        source="Eurostat (COFOG GF09)"
        sparklineData={serie_gastos_real.filter(d => d.funcion_cofog === 'Educación').map(d => d.eur_hab_real)}
    />
</Grid>

<p class="text-xs text-gray-500">Principio de esta web: los importes se muestran <b>por habitante</b> y <b>descontada la inflación</b>, en euros de {base_deflactor[0]?.anio_base} según el IPC medio anual del INE, para que las cifras de años distintos sean comparables. Los totales en euros corrientes aparecen como dato secundario; los porcentajes (del gasto o del PIB) no necesitan ajuste.</p>

---

## 1. Gasto Anual por Habitante en España ({resumen_gastos[0].anio})

Dividiendo el gasto de cada función entre los ~{formatNumber(poblacion_ultimo[0].poblacion_m, 1)} millones de residentes en España (población media anual), este es el coste promedio anual por habitante de cada servicio público:

<BarChart
    data={gastos_ultimo}
    x=funcion_cofog
    y=gasto_hab_real
    yAxisTitle="Euros por habitante al año (euros de {base_deflactor[0]?.anio_base})"
    yFmt=num0
    title="Gasto público por habitante al año según función ({resumen_gastos[0]?.anio}, euros de {base_deflactor[0]?.anio_base})"
    swapXY={true}
/>

<DataTable data={gastos_ultimo} title="Clasificación Funcional del Gasto (COFOG {resumen_gastos[0].anio})">
    <Column id=funcion_cofog title="Función de Gasto" />
    <Column id=categoria_macro title="Macro-Categoría" />
    <Column id=gasto_hab_real title="Por Habitante" fmt='#,##0 €' />
    <Column id=porcentaje_gasto_total title="% Gasto Total" fmt='0.0"%"' />
    <Column id=porcentaje_pib title="% sobre el PIB" fmt='0.0"%"' />
    <Column id=millones_euros title="Total (M€ corrientes)" fmt='#,##0' />
</DataTable>

---

## 2. Evolución del Gasto por Grandes Bloques

Gasto por habitante de cada bloque, en euros de {base_deflactor[0]?.anio_base} (descontada la inflación), desde 1996, primer año con IPC anual disponible:

<AreaChart
    data={serie_gastos_macro}
    x=año
    y=eur_hab_real
    series=categoria_macro
    yAxisTitle="Euros por habitante (euros de {base_deflactor[0]?.anio_base})"
    yFmt=num0
    title="Gasto público por habitante y bloque funcional (euros de {base_deflactor[0]?.anio_base}, descontada la inflación)"
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
