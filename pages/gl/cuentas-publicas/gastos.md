---
description: "En que gasta España o diñeiro público: gasto por funcións (pensións, sanidade, educación...), por habitante e descontada a inflación, e o seu peso no PIB."
title: Gasto público e destino do orzamento
i18n_origen: ffd69e06b546
og:
  image: https://spainfacts.org/og-spainfacts.png
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

# En que gasta o Estado e canto custa por cidadán?

O gasto público consolidado en España alcanzou en {resumen_gastos[0]?.anio} **{formatNumber(resumen_gastos[0]?.total_hab_real, 0)} euros por habitante** ({formatNumber(resumen_gastos[0]?.total_mio / 1000, 1)} mil millóns en total, o {formatNumber(resumen_gastos[0]?.total_pib, 1)}% do PIB). A maior parte do orzamento destínase ás funcións do **Estado do benestar**: protección social e pensións, sanidade e educación representan o **{formatNumber(resumen_gastos[0].social_pct, 1)}% de todo o gasto público**.

<Grid cols=3>
    <KpiCard
        title="Pensións e protección social"
        value={resumen_gastos[0]?.pens_hab}
        formattedValue="{formatNumber(resumen_gastos[0]?.pens_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_gastos[0]?.pens_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_gastos[0]?.pens_pct, 1)}% do gasto · {resumen_gastos[0]?.anio}"
        direction="neutral"
        source="Eurostat (COFOG GF10)"
        sparklineData={serie_gastos_real.filter(d => d.funcion_cofog === 'Protección Social y Pensiones').map(d => ({...d, y: d.eur_hab_real}))}
    />

    <KpiCard
        title="Sanidade pública"
        value={resumen_gastos[0]?.san_hab}
        formattedValue="{formatNumber(resumen_gastos[0]?.san_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_gastos[0]?.san_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_gastos[0]?.san_pct, 1)}% do gasto · {resumen_gastos[0]?.anio}"
        direction="neutral"
        source="Eurostat (COFOG GF07)"
        sparklineData={serie_gastos_real.filter(d => d.funcion_cofog === 'Sanidad Pública').map(d => ({...d, y: d.eur_hab_real}))}
    />

    <KpiCard
        title="Educación"
        value={resumen_gastos[0]?.edu_hab}
        formattedValue="{formatNumber(resumen_gastos[0]?.edu_hab, 0)} €"
        unit="/ hab."
        period="{formatNumber(resumen_gastos[0]?.edu_mio / 1000, 1)} mil M€ en total · {formatNumber(resumen_gastos[0]?.edu_pct, 1)}% do gasto · {resumen_gastos[0]?.anio}"
        direction="neutral"
        source="Eurostat (COFOG GF09)"
        sparklineData={serie_gastos_real.filter(d => d.funcion_cofog === 'Educación').map(d => ({...d, y: d.eur_hab_real}))}
    />
</Grid>

<p class="text-xs text-gray-500">Principio desta web: os importes móstranse <b>por habitante</b> e <b>descontada a inflación</b>, en euros de {base_deflactor[0]?.anio_base} segundo o IPC medio anual do INE, para que as cifras de anos distintos sexan comparables. Os totais en euros correntes aparecen como dato secundario; as porcentaxes (do gasto ou do PIB) non precisan axuste.</p>

---

## 1. Gasto anual por habitante en España ({resumen_gastos[0].anio})

Dividindo o gasto de cada función entre os ~{formatNumber(poblacion_ultimo[0].poblacion_m, 1)} millóns de residentes en España (poboación media anual), este é o custo medio anual por habitante de cada servizo público:

<BarChart
    data={gastos_ultimo}
    x=funcion_cofog
    y=gasto_hab_real
    yAxisTitle="Euros por habitante ao ano (euros de {base_deflactor[0]?.anio_base})"
    yFmt=num0
    title="Gasto público por habitante ao ano segundo a función ({resumen_gastos[0]?.anio}, euros de {base_deflactor[0]?.anio_base})"
    swapXY={true}
/>

<DataTable data={gastos_ultimo} title="Clasificación funcional do gasto (COFOG {resumen_gastos[0].anio})">
    <Column id=funcion_cofog title="Función de gasto" />
    <Column id=categoria_macro title="Macrocategoría" />
    <Column id=gasto_hab_real title="Por habitante" fmt='#,##0 €' />
    <Column id=porcentaje_gasto_total title="% gasto total" fmt='0.0"%"' />
    <Column id=porcentaje_pib title="% sobre o PIB" fmt='0.0"%"' />
    <Column id=millones_euros title="Total (M€ correntes)" fmt='#,##0' />
</DataTable>

---

## 2. Evolución do gasto por grandes bloques

Gasto por habitante de cada bloque, en euros de {base_deflactor[0]?.anio_base} (descontada a inflación), desde 1996, primeiro ano con IPC anual dispoñible:

<AreaChart
    data={serie_gastos_macro}
    x=año
    y=eur_hab_real
    series=categoria_macro
    yAxisTitle="Euros por habitante (euros de {base_deflactor[0]?.anio_base})"
    yFmt=num0
    title="Gasto público por habitante e bloque funcional (euros de {base_deflactor[0]?.anio_base}, descontada a inflación)"
/>

---

## 3. Desagregación das principais funcións de gasto ({resumen_gastos[0].anio})

- **Protección social e pensións ({formatNumber(resumen_gastos[0].pens_pct, 1)}%):** o maior desembolso do sector público, que inclúe pensións contributivas de xubilación, viuvez e incapacidade, así como subsidios de desemprego e dependencia.
- **Sanidade pública ({formatNumber(resumen_gastos[0].san_pct, 1)}%):** xestionada fundamentalmente polas 17 comunidades autónomas para financiar hospitais, centros de saúde, persoal médico e gasto farmacéutico.
- **Educación ({formatNumber(resumen_gastos[0].edu_pct, 1)}%):** financiamento do ensino infantil, primario, secundario, formación profesional e universidades públicas.
- **Xuros da débeda pública ({formatNumber(resumen_gastos[0].int_pct, 1)}%):** pagamento periódico de xuros aos investidores titulares de bonos e obrigas do Estado (COFOG GF0107, separado aquí dos servizos públicos xerais), un custo financeiro que non xera servizo directo pero condiciona a capacidade orzamentaria.
- **Economía, transporte e infraestruturas ({formatNumber(resumen_gastos[0].eco_pct, 1)}%):** investimento en rede ferroviaria (AVE/Cercanías), estradas, aeroportos, agricultura e transición enerxética.
- **Seguridade cidadá e xustiza ({formatNumber(resumen_gastos[0].seg_pct, 1)}%):** mantemento das Forzas e Corpos de Seguridade (Policía Nacional, Garda Civil, policías autonómicas), tribunais e centros penitenciarios.
- **Defensa ({formatNumber(resumen_gastos[0].def_pct, 1)}%):** mantemento das Forzas Armadas (Exército de Terra, Armada e Exército do Aire e do Espazo) e programas de modernización militar.

---

## Fontes oficiais
- **[Clasificación funcional do gasto COFOG (Eurostat gov_10a_exp)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp):** gasto consolidado das AAPP por función segundo a clasificación estandarizada das Nacións Unidas e a Unión Europea.
- **[PIB a prezos correntes (Eurostat nama_10_gdp)](https://ec.europa.eu/eurostat/databrowser/view/nama_10_gdp) e [poboación media (nama_10_pe)](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe):** denominadores para as porcentaxes sobre o PIB e o gasto por habitante.
- **[Orzamentos Xerais do Estado (Ministerio de Facenda)](https://www.sepg.pap.hacienda.gob.es/):** series de gasto dos ministerios e organismos públicos.
