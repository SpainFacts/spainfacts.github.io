---
description: "En què gasta els diners públics Espanya: despesa per funcions (pensions, sanitat, educació...), per habitant i descomptada la inflació, i el seu pes en el PIB."
title: Despesa pública i destinació del pressupost
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 6188b57b56b6
---

<script>
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
</script>

```sql base_deflactor
-- Año cuyos euros se usan como referencia (último año completo con IPC)
SELECT CAST(max(anio_base) AS INTEGER) AS anio_base FROM mother.deflactor
```

```sql gastos_ultimo
SELECT
    CAST(g.año AS INTEGER) AS anio,
    g.funcion_cofog,
    g.categoria_macro,
    g.millones_euros,
    g.porcentaje_gasto_total,
    g.porcentaje_pib,
    g.gasto_por_habitante_eur,
    g.gasto_por_habitante_eur * d.factor AS gasto_hab_real
FROM mother.cuentas_gastos g
LEFT JOIN mother.deflactor d ON CAST(d.anio AS INTEGER) = CAST(g.año AS INTEGER)
WHERE g.año = (SELECT max(año) FROM mother.cuentas_gastos)
ORDER BY g.millones_euros DESC
```

```sql resumen_gastos
-- Por habitante en euros constantes (gasto_por_habitante_eur por el factor del deflactor)
SELECT
    CAST(g.año AS INTEGER) AS anio,
    sum(g.millones_euros) AS total_mio,
    sum(g.gasto_por_habitante_eur * d.factor) AS total_hab_real,
    sum(g.porcentaje_pib) AS total_pib,
    sum(CASE WHEN g.categoria_macro = 'Gasto Social' THEN g.porcentaje_gasto_total END) AS social_pct,
    max(CASE WHEN g.funcion_cofog = 'Protección Social y Pensiones' THEN g.millones_euros END) AS pens_mio,
    max(CASE WHEN g.funcion_cofog = 'Protección Social y Pensiones' THEN g.gasto_por_habitante_eur * d.factor END) AS pens_hab,
    max(CASE WHEN g.funcion_cofog = 'Protección Social y Pensiones' THEN g.porcentaje_gasto_total END) AS pens_pct,
    max(CASE WHEN g.funcion_cofog = 'Sanidad Pública' THEN g.millones_euros END) AS san_mio,
    max(CASE WHEN g.funcion_cofog = 'Sanidad Pública' THEN g.gasto_por_habitante_eur * d.factor END) AS san_hab,
    max(CASE WHEN g.funcion_cofog = 'Sanidad Pública' THEN g.porcentaje_gasto_total END) AS san_pct,
    max(CASE WHEN g.funcion_cofog = 'Educación' THEN g.millones_euros END) AS edu_mio,
    max(CASE WHEN g.funcion_cofog = 'Educación' THEN g.gasto_por_habitante_eur * d.factor END) AS edu_hab,
    max(CASE WHEN g.funcion_cofog = 'Educación' THEN g.porcentaje_gasto_total END) AS edu_pct,
    max(CASE WHEN g.funcion_cofog = 'Intereses de la Deuda' THEN g.porcentaje_gasto_total END) AS int_pct,
    max(CASE WHEN g.funcion_cofog = 'Asuntos Económicos y Transporte' THEN g.porcentaje_gasto_total END) AS eco_pct,
    max(CASE WHEN g.funcion_cofog = 'Orden Público y Seguridad' THEN g.porcentaje_gasto_total END) AS seg_pct,
    max(CASE WHEN g.funcion_cofog = 'Defensa' THEN g.porcentaje_gasto_total END) AS def_pct
FROM mother.cuentas_gastos g
LEFT JOIN mother.deflactor d ON CAST(d.anio AS INTEGER) = CAST(g.año AS INTEGER)
WHERE g.año = (SELECT max(año) FROM mother.cuentas_gastos)
GROUP BY g.año
```

```sql poblacion_ultimo
SELECT poblacion_m
FROM mother.cuentas_balance_anual
WHERE año = (SELECT max(año) FROM mother.cuentas_gastos)
```

```sql serie_gastos_macro
-- Euros por habitante a precios constantes (el deflactor empieza en 2002)
SELECT
    CAST(g.año AS INTEGER) AS año,
    g.categoria_macro,
    sum(g.gasto_por_habitante_eur * d.factor) AS eur_hab_real
FROM mother.cuentas_gastos g
JOIN mother.deflactor d ON CAST(d.anio AS INTEGER) = CAST(g.año AS INTEGER)
GROUP BY 1, 2
ORDER BY 1 ASC
```

```sql serie_gastos_funcion
SELECT
    CAST(g.año AS INTEGER) AS año,
    g.funcion_cofog,
    g.gasto_por_habitante_eur * d.factor AS eur_hab_real
FROM mother.cuentas_gastos g
JOIN mother.deflactor d ON CAST(d.anio AS INTEGER) = CAST(g.año AS INTEGER)
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

# En què gasta l'Estat i quant costa per ciutadà?

La despesa pública consolidada a Espanya va arribar el {resumen_gastos[0]?.anio} a **{formatNumber(resumen_gastos[0]?.total_hab_real, 0)} euros per habitant** ({formatNumber(resumen_gastos[0]?.total_mio / 1000, 1)} mil milions en total, el {formatNumber(resumen_gastos[0]?.total_pib, 1)}% del PIB). La major part del pressupost es destina a les funcions de l'**estat del benestar**: protecció social i pensions, sanitat i educació representen el **{formatNumber(resumen_gastos[0].social_pct, 1)}% de tota la despesa pública**.

<Grid cols=3>
    <KpiCard
        title="Pensions i protecció social"
        value={resumen_gastos[0]?.pens_hab}
        formattedValue="{formatNumber(resumen_gastos[0]?.pens_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_gastos[0]?.pens_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_gastos[0]?.pens_pct, 1)}% de la despesa · {resumen_gastos[0]?.anio}"
        direction="neutral"
        source="Eurostat (COFOG GF10)"
        sparklineData={serie_gastos_real.filter(d => d.funcion_cofog === 'Protección Social y Pensiones').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="Sanitat pública"
        value={resumen_gastos[0]?.san_hab}
        formattedValue="{formatNumber(resumen_gastos[0]?.san_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_gastos[0]?.san_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_gastos[0]?.san_pct, 1)}% de la despesa · {resumen_gastos[0]?.anio}"
        direction="neutral"
        source="Eurostat (COFOG GF07)"
        sparklineData={serie_gastos_real.filter(d => d.funcion_cofog === 'Sanidad Pública').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="Educació"
        value={resumen_gastos[0]?.edu_hab}
        formattedValue="{formatNumber(resumen_gastos[0]?.edu_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_gastos[0]?.edu_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_gastos[0]?.edu_pct, 1)}% de la despesa · {resumen_gastos[0]?.anio}"
        direction="neutral"
        source="Eurostat (COFOG GF09)"
        sparklineData={serie_gastos_real.filter(d => d.funcion_cofog === 'Educación').map(d => d.eur_hab_real)}
    />
</Grid>

<p class="text-xs text-gray-500">Principi d'aquest web: els imports es mostren <b>per habitant</b> i <b>descomptada la inflació</b>, en euros de {base_deflactor[0]?.anio_base} segons l'IPC mitjà anual de l'INE, perquè les xifres d'anys diferents siguin comparables. Els totals en euros corrents apareixen com a dada secundària; els percentatges (de la despesa o del PIB) no necessiten ajust.</p>

---

## 1. Despesa anual per habitant a Espanya ({resumen_gastos[0].anio})

Dividint la despesa de cada funció entre els ~{formatNumber(poblacion_ultimo[0].poblacion_m, 1)} milions de residents a Espanya (població mitjana anual), aquest és el cost mitjà anual per habitant de cada servei públic:

<BarChart
    data={gastos_ultimo}
    x=funcion_cofog
    y=gasto_hab_real
    yAxisTitle="Euros per habitant l'any (euros de {base_deflactor[0]?.anio_base})"
    yFmt=num0
    title="Despesa pública per habitant l'any segons la funció ({resumen_gastos[0]?.anio}, euros de {base_deflactor[0]?.anio_base})"
    swapXY={true}
/>

<DataTable data={gastos_ultimo} title="Classificació funcional de la despesa (COFOG {resumen_gastos[0].anio})">
    <Column id=funcion_cofog title="Funció de despesa" />
    <Column id=categoria_macro title="Macrocategoria" />
    <Column id=gasto_hab_real title="Per habitant" fmt='#,##0 €' />
    <Column id=porcentaje_gasto_total title="% despesa total" fmt='0.0"%"' />
    <Column id=porcentaje_pib title="% sobre el PIB" fmt='0.0"%"' />
    <Column id=millones_euros title="Total (M€ corrents)" fmt='#,##0' />
</DataTable>

---

## 2. Evolució de la despesa per grans blocs

Despesa per habitant de cada bloc, en euros de {base_deflactor[0]?.anio_base} (descomptada la inflació), des del 2002, primer any amb IPC anual disponible:

<AreaChart
    data={serie_gastos_macro}
    x=año
    y=eur_hab_real
    series=categoria_macro
    yAxisTitle="Euros per habitant (euros de {base_deflactor[0]?.anio_base})"
    yFmt=num0
    title="Despesa pública per habitant i bloc funcional (euros de {base_deflactor[0]?.anio_base}, descomptada la inflació)"
/>

---

## 3. Desglossament de les principals funcions de despesa ({resumen_gastos[0].anio})

- **Protecció social i pensions ({formatNumber(resumen_gastos[0].pens_pct, 1)}%):** El desemborsament més gran del sector públic, que inclou pensions contributives de jubilació, viduïtat i incapacitat, així com subsidis d'atur i dependència.
- **Sanitat pública ({formatNumber(resumen_gastos[0].san_pct, 1)}%):** Gestionada fonamentalment per les 17 comunitats autònomes per finançar hospitals, centres de salut, personal mèdic i despesa farmacèutica.
- **Educació ({formatNumber(resumen_gastos[0].edu_pct, 1)}%):** Finançament de l'ensenyament infantil, primari, secundari, la formació professional i les universitats públiques.
- **Interessos del deute públic ({formatNumber(resumen_gastos[0].int_pct, 1)}%):** Pagament periòdic d'interessos als inversors tenidors de bons i obligacions de l'Estat (COFOG GF0107, separat aquí dels serveis públics generals), un cost financer que no genera cap servei directe però condiciona la capacitat pressupostària.
- **Economia, transport i infraestructures ({formatNumber(resumen_gastos[0].eco_pct, 1)}%):** Inversió en xarxa ferroviària (AVE/Rodalies), carreteres, aeroports, agricultura i transició energètica.
- **Seguretat ciutadana i justícia ({formatNumber(resumen_gastos[0].seg_pct, 1)}%):** Manteniment de les forces i cossos de seguretat (Policia Nacional, Guàrdia Civil, policies autonòmiques), tribunals i centres penitenciaris.
- **Defensa ({formatNumber(resumen_gastos[0].def_pct, 1)}%):** Manteniment de les Forces Armades (Exèrcit de Terra, Armada i Exèrcit de l'Aire i de l'Espai) i programes de modernització militar.

---

## Fonts oficials
- **[Classificació funcional de la despesa COFOG (Eurostat gov_10a_exp)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp):** Despesa consolidada de les AP per funció segons la classificació estandarditzada de les Nacions Unides i la Unió Europea.
- **[PIB a preus corrents (Eurostat nama_10_gdp)](https://ec.europa.eu/eurostat/databrowser/view/nama_10_gdp) i [població mitjana (nama_10_pe)](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe):** Denominadors per als percentatges sobre el PIB i la despesa per habitant.
- **[Pressupostos Generals de l'Estat (Ministeri d'Hisenda)](https://www.sepg.pap.hacienda.gob.es/):** Sèries de despesa dels ministeris i organismes públics.
