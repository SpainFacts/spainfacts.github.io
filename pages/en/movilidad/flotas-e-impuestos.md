---
title: The fleet tax havens
description: "Villages of a few dozen inhabitants where thousands of company cars are registered: renting and rental fleets are domiciled where vehicle tax is cheapest. Data from the DGT and the Ministry of Finance."
i18n_origen: ad7c7e41b297
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql anios
SELECT DISTINCT anio FROM mother.movilidad_flotas_municipios ORDER BY anio DESC
```

```sql ultimo_completo
-- Último año con los doce meses (el año en curso se queda fuera de los rankings)
SELECT max(anio) AS anio
FROM mother.movilidad_flotas_municipios
WHERE anio < (SELECT max(year(mes)) FROM mother.movilidad_matriculaciones_mensual)
```

```sql municipios
SELECT
    municipio, provincia, poblacion, flota, flota_por_habitante, cuota_flota_espana,
    ivtm_turismo, capital, ivtm_turismo_capital, ahorro_por_coche, ahorro_estimado
FROM mother.movilidad_flotas_municipios
WHERE anio = (SELECT anio FROM ${ultimo_completo})
ORDER BY flota DESC
```

```sql resumen
WITH m AS (SELECT * FROM ${municipios})
SELECT
    (SELECT anio FROM ${ultimo_completo}) AS anio,
    (SELECT sum(cuota_flota_espana) FROM (SELECT cuota_flota_espana FROM m ORDER BY flota DESC LIMIT 10)) AS cuota_top10,
    sum(flota) FILTER (WHERE poblacion < 5000) AS flota_pueblos,
    sum(cuota_flota_espana) FILTER (WHERE poblacion < 5000) AS cuota_pueblos,
    sum(poblacion) FILTER (WHERE poblacion < 5000) / (SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total' ORDER BY anio DESC LIMIT 1) AS peso_pueblos,
    arg_max(municipio, flota_por_habitante) FILTER (WHERE flota >= 1000) AS record_municipio,
    max(flota_por_habitante) FILTER (WHERE flota >= 1000) AS record_por_hab,
    arg_max(poblacion, flota_por_habitante) FILTER (WHERE flota >= 1000) AS record_poblacion,
    arg_max(flota, flota_por_habitante) FILTER (WHERE flota >= 1000) AS record_flota,
    sum(ahorro_estimado) FILTER (WHERE ahorro_estimado > 0) AS ahorro_total
FROM m
```

```sql por_habitante
SELECT municipio, flota_por_habitante, poblacion, flota
FROM ${municipios}
WHERE flota >= 1000
ORDER BY flota_por_habitante DESC
LIMIT 15
```

```sql evolucion
-- Peso de los pueblos de menos de 5.000 habitantes en las flotas matriculadas cada año
SELECT
    anio,
    sum(cuota_flota_espana) FILTER (WHERE poblacion < 5000) AS cuota_pueblos,
    sum(cuota_flota_espana) FILTER (WHERE municipio IN ('Madrid', 'Barcelona')) AS cuota_madrid_barcelona
FROM mother.movilidad_flotas_municipios
GROUP BY anio
ORDER BY anio
```

# 🏝️ The fleet tax havens

A car is registered in the municipality where its owner is domiciled. For a private individual that is their home; for a renting or car rental company, any branch it opens. And the vehicle tax (IVTM) is set by each town council: the law sets a minimum rate and allows councils to multiply it by up to two. The result is that thousands of company cars driven in Madrid, Barcelona or tourist areas are domiciled in villages of a few dozen or a few hundred inhabitants with the lowest tax. It is legal, but those councils collect tax on cars that do not drive on their streets, and the cities where they do drive do not collect it.

<Grid cols=3>
    <KpiCard
        title="Fleet cars in the top 10 municipalities"
        value={resumen[0]?.cuota_top10 * 100}
        formattedValue={formatNumber(resumen[0]?.cuota_top10 * 100, 0)}
        unit="%"
        period="of new passenger cars of companies, renting and rental · {resumen[0]?.anio}"
        source="DGT"
    />
    <KpiCard
        title="In villages under 5,000 inhabitants"
        value={resumen[0]?.cuota_pueblos * 100}
        formattedValue={formatNumber(resumen[0]?.cuota_pueblos * 100, 0)}
        unit="%"
        period="{formatNumber(resumen[0]?.flota_pueblos, 0)} fleet cars in municipalities home to {formatNumber(resumen[0]?.peso_pueblos * 100, 2)}% of the population · {resumen[0]?.anio}"
        source="DGT / INE"
    />
    <KpiCard
        title="Record: {resumen[0]?.record_municipio}"
        value={resumen[0]?.record_por_hab}
        formattedValue="{formatNumber(resumen[0]?.record_por_hab, 0)} cars per inhabitant"
        period="{formatNumber(resumen[0]?.record_flota, 0)} new fleet cars for {formatNumber(resumen[0]?.record_poblacion, 0)} residents · {resumen[0]?.anio}"
        source="DGT / INE"
    />
</Grid>

## Company cars per resident

<BarChart
    data={por_habitante}
    x=municipio
    y=flota_por_habitante
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#b91c1c"
    title="New fleet passenger cars registered in {resumen[0]?.anio} per inhabitant (municipalities with 1,000 or more)"
/>

## The municipalities where most fleet cars are registered

<DataTable data={municipios} rows=20 search=true>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=poblacion title="Inhabitants" fmt=num0 />
    <Column id=flota title="Fleet cars" fmt=num0 contentType=bar barColor="#fecaca" />
    <Column id=flota_por_habitante title="Per inhabitant" fmt=num1 />
    <Column id=cuota_flota_espana title="% of Spain" fmt=pct1 />
    <Column id=ivtm_turismo title="IVTM (€/year)" fmt=num2 />
    <Column id=ivtm_turismo_capital title="IVTM in the capital" fmt=num2 />
    <Column id=ahorro_estimado title="Estimated saving (€)" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Fleet cars: new passenger cars registered to companies (including dealer self-registrations), renting or rental without driver. IVTM: annual rate for a passenger car of 8 to 11.99 fiscal horsepower, the band of most current cars, according to each municipality's bylaw (without discounts by engine type). Estimated saving: how much less those cars pay in the first year compared with the capital of their province; the car keeps saving that every year it stays domiciled there. Rates are only available for the municipalities with the most fleet cars and their capitals.</p>

With the fleet cars registered in {resumen[0]?.anio} in the municipalities in the table alone, companies pay about **€{formatNumber(resumen[0]?.ahorro_total / 1e6, 1)} million less per year** in vehicle tax than if they had domiciled them in the capital of their province.

## How has it changed?

<LineChart
    data={evolucion}
    x=anio
    y={['cuota_pueblos', 'cuota_madrid_barcelona']}
    yFmt=pct0
    xFmt="####"
    markers=true
    colorPalette={['#b91c1c', '#2563eb']}
    seriesLabels={{cuota_pueblos: 'Villages under 5,000 inhabitants', cuota_madrid_barcelona: 'Madrid and Barcelona cities'}}
    title="Share of Spain's new fleet passenger cars"
/>

<p class="text-xs text-gray-500">Small villages carry less and less weight: part of the fleets has moved to large municipalities around Madrid that also cut the tax, such as Alcobendas, Majadahonda or Boadilla del Monte. Only municipalities with 100 or more fleet cars in the year are counted. The latest year is incomplete.</p>

## Why it happens

- **It is legal.** A vehicle is taxed where its owner is domiciled, and a company can domicile its cars at any branch. Since number plates stopped carrying the province letters (2000), nothing shows at a glance where a car is registered.
- **Cities are the big losers**: they bear the traffic, parking and emissions of those cars without collecting their tax. Meanwhile, villages with a few dozen residents collect tax on cars that never pass through their streets, albeit at a low rate.
- **It distorts the statistics**: registrations by province or municipality say more about where fleets have their headquarters than about where cars are bought or driven. That is why in [Electric cars](/en/movilidad/coche-electrico) the map shows only private buyers' cars by default.
- The drivers' association AEA has been documenting this for years: according to its 2026 study, ten municipalities account for around 35% of company-vehicle registrations.

---

## Sources and notes

- **[DGT – Registration microdata (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**: municipality of the owner's domicile, type of owner, renting and service of each new passenger car.
- **[INE – Municipal register](https://www.ine.es/dynt3/inebase/index.htm?padre=517)**: inhabitants of each municipality (latest year published for the most recent ones).
- **[Ministry of Finance – Municipal tax information lookup](https://serviciostelematicosext.hacienda.gob.es/SGFAL/ConsultaTipos/html/portadaconsultasm.aspx)**: IVTM rates approved by each town council.
- **[AEA – Study on the IVTM and vehicle tax "tax havens" (2026)](https://aeaclub.org/ivtm-impuesto-municipal-vehiculos-paraisos-fiscales/)**.

<LastRefreshed prefix="Data updated" />
