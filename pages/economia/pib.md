---
title: PIB y crecimiento
description: "Evolución del PIB de España por habitante y descontada la inflación, crecimiento trimestral, componentes de la demanda y comparación con la UE."
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

```sql pib_trim
SELECT
    trimestre,
    CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo,
    interanual,
    por_habitante_real AS valor,
    real_meur,
    nominal_meur,
    anio_euros
FROM mother.economia_pib_trimestral
WHERE componente = 'B1GQ'
ORDER BY trimestre
```

```sql pib_hab
SELECT
    anio,
    real_eur AS valor,
    100 * (real_eur / lag(real_eur) OVER (ORDER BY anio) - 1) AS crecimiento,
    indice_ue
FROM mother.economia_pib_per_capita
WHERE pais = 'ES'
ORDER BY anio
```

```sql hitos
SELECT
    max(CASE WHEN anio = 2007 THEN valor END) AS v2007,
    max(CASE WHEN anio = 2013 THEN valor END) AS v2013,
    max(CASE WHEN anio = 2019 THEN valor END) AS v2019,
    max(CASE WHEN anio = 2020 THEN valor END) AS v2020,
    max(valor) FILTER (WHERE anio = (SELECT max(anio) FROM ${pib_hab})) AS vult,
    max(anio) AS anio_ult,
    100 * (max(valor) FILTER (WHERE anio = (SELECT max(anio) FROM ${pib_hab})) / max(CASE WHEN anio = 2007 THEN valor END) - 1) AS vs2007,
    100 * (max(CASE WHEN anio = 2013 THEN valor END) / max(CASE WHEN anio = 2007 THEN valor END) - 1) AS caida_crisis
FROM ${pib_hab}
```

```sql demanda
SELECT trimestre, nombre, por_habitante_real AS euros_hab
FROM mother.economia_pib_trimestral
WHERE componente IN ('P31_S14_S15', 'P3_S13', 'P51G')
ORDER BY trimestre, nombre
```

```sql ue
SELECT anio, nombre, indice_ue
FROM mother.economia_pib_per_capita
WHERE indice_ue IS NOT NULL
ORDER BY anio, nombre
```

```sql ue_ult
SELECT anio, nombre, indice_ue
FROM mother.economia_pib_per_capita
WHERE anio = (SELECT max(anio) FROM mother.economia_pib_per_capita WHERE indice_ue IS NOT NULL)
  AND pais <> 'EU27_2020'
ORDER BY indice_ue DESC
```

# 📈 PIB y crecimiento

El producto interior bruto mide todo lo que produce la economía. Para ver si el país se enriquece de verdad, aquí se muestra **por habitante** (si no, crece con solo sumar población) y **descontada la inflación**, en euros de {pib_trim[0]?.anio_euros}.

<Grid cols=4>
    <KpiCard
        title="PIB por habitante"
        value={pib_hab.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pib_hab.slice(-1)[0]?.valor, 0)} €"
        period="en {pib_hab.slice(-1)[0]?.anio}, en euros de {pib_trim[0]?.anio_euros}"
        change={pib_hab.slice(-1)[0]?.crecimiento?.toFixed(1)}
        changePeriod="real vs año anterior"
        direction="positive-up"
        source="Eurostat"
        sparklineData={pib_hab}
    />
    <KpiCard
        title="Crecimiento del PIB"
        value={pib_trim.slice(-1)[0]?.interanual}
        formattedValue="{formatNumber(pib_trim.slice(-1)[0]?.interanual, 1)} %"
        period="interanual real, {pib_trim.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={pib_trim.slice(-24).map(d => d.interanual)}
    />
    <KpiCard
        title="PIB por habitante, ritmo anual"
        value={pib_trim.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pib_trim.slice(-1)[0]?.valor, 0)} €"
        period="último trimestre ({pib_trim.slice(-1)[0]?.periodo}) multiplicado por cuatro · PIB total {formatNumber(pib_trim.slice(-1)[0]?.real_meur / 1000, 0)} mil M€ en el trimestre"
        source="Eurostat"
        sparklineData={pib_trim.slice(-40)}
    />
    <KpiCard
        title="Nivel de vida frente a la UE"
        value={pib_hab.filter(d => d.indice_ue != null).slice(-1)[0]?.indice_ue}
        formattedValue={formatNumber(pib_hab.filter(d => d.indice_ue != null).slice(-1)[0]?.indice_ue, 1)}
        period="PIB por habitante en paridad de poder de compra, UE = 100"
        source="Eurostat"
        sparklineData={pib_hab.filter(d => d.indice_ue != null).map(d => d.indice_ue)}
    />
</Grid>

## PIB por habitante desde 1995

En euros constantes de {pib_trim[0]?.anio_euros}. La crisis de 2008 recortó el PIB por habitante un {formatNumber(-hitos[0]?.caida_crisis, 1)} % hasta 2013; la pandemia lo hundió en 2020 y en {hitos[0]?.anio_ult} está un {formatNumber(hitos[0]?.vs2007, 1)} % por encima del máximo de 2007.

<LineChart
    data={pib_hab}
    x=anio
    y=valor
    yAxisTitle="€ por habitante (reales)"
    yFmt='#,##0" €"'
    xFmt='0'
    startingAtZero={false}
    title="PIB por habitante en euros de {pib_trim[0]?.anio_euros}"
/>

## Crecimiento trimestral

Variación del PIB real frente al mismo trimestre del año anterior, desestacionalizada. El desplome de 2020 y el rebote de 2021 salen de escala.

<BarChart
    data={pib_trim.filter(d => d.interanual != null)}
    x=trimestre
    y=interanual
    yAxisTitle="% interanual"
    yFmt='0.0"%"'
    title="PIB real, variación interanual (%)"
/>

## En qué se gasta lo que se produce

Consumo de los hogares, consumo público e inversión por habitante, en euros constantes y a ritmo anual (el trimestre multiplicado por cuatro). El comercio exterior tiene su propia página: [exportaciones e importaciones](/economia/comercio-exterior).

<LineChart
    data={demanda}
    x=trimestre
    y=euros_hab
    series=nombre
    yAxisTitle="€ por habitante (reales)"
    yFmt='#,##0" €"'
    title="Demanda por habitante, euros de {pib_trim[0]?.anio_euros} a ritmo anual"
/>

## Comparación con Europa

PIB por habitante en paridad de poder de compra, que corrige que los precios no son iguales en todos los países (UE-27 = 100). En {ue_ult[0]?.anio} España está en {formatNumber(pib_hab.filter(d => d.indice_ue != null).slice(-1)[0]?.indice_ue, 1)}.

<LineChart
    data={ue}
    x=anio
    y=indice_ue
    series=nombre
    xFmt='0'
    yAxisTitle="UE-27 = 100"
    startingAtZero={false}
    title="PIB por habitante en PPS (UE-27 = 100)"
/>

<DataTable data={ue_ult} rows=10>
    <Column id=nombre title="País"/>
    <Column id=indice_ue title="Índice (UE = 100)" fmt='0.0'/>
</DataTable>

---

**Fuentes:** [Eurostat, namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table) (contabilidad nacional trimestral, desestacionalizada) y [nama_10_pc](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table) (PIB por habitante). Los volúmenes encadenados se reexpresan en euros de {pib_trim[0]?.anio_euros}; la población es la media anual de Eurostat.
