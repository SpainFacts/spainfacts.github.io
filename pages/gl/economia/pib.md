---
i18n_origen: 7ab507e83338
title: PIB e crecemento
description: "Evolución do PIB de España por habitante e descontada a inflación, crecemento trimestral, compoñentes da demanda e comparación coa UE."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
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

# 📈 PIB e crecemento

O produto interior bruto mide todo o que produce a economía. Para ver se o país se enriquece de verdade, aquí móstrase **por habitante** (se non, medra só con sumar poboación) e **descontada a inflación**, en euros de {pib_trim[0]?.anio_euros}.

<Grid cols=4>
    <KpiCard
        title="PIB por habitante"
        value={pib_hab.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pib_hab.slice(-1)[0]?.valor, 0)} €"
        period="en {pib_hab.slice(-1)[0]?.anio}, en euros de {pib_trim[0]?.anio_euros}"
        change={pib_hab.slice(-1)[0]?.crecimiento?.toFixed(1)}
        changePeriod="real vs. ano anterior"
        direction="positive-up"
        source="Eurostat"
        sparklineData={pib_hab}
    />
    <KpiCard
        title="Crecemento do PIB"
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
        period="último trimestre ({pib_trim.slice(-1)[0]?.periodo}) multiplicado por catro · PIB total {formatNumber(pib_trim.slice(-1)[0]?.real_meur / 1000, 0)} mil M€ no trimestre"
        source="Eurostat"
        sparklineData={pib_trim.slice(-40)}
    />
    <KpiCard
        title="Nivel de vida fronte á UE"
        value={pib_hab.filter(d => d.indice_ue != null).slice(-1)[0]?.indice_ue}
        formattedValue={formatNumber(pib_hab.filter(d => d.indice_ue != null).slice(-1)[0]?.indice_ue, 1)}
        period="PIB por habitante en paridade de poder de compra, UE = 100"
        source="Eurostat"
        sparklineData={pib_hab.filter(d => d.indice_ue != null).map(d => d.indice_ue)}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('pib_pc_ppa', 'crecimiento_pib')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'pib_pc_ppa')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'crecimiento_pib')} />


## PIB por habitante desde 1995

En euros constantes de {pib_trim[0]?.anio_euros}. A crise de 2008 recortou o PIB por habitante un {formatNumber(-hitos[0]?.caida_crisis, 1)} % ata 2013; a pandemia afundiuno en 2020 e en {hitos[0]?.anio_ult} está un {formatNumber(hitos[0]?.vs2007, 1)} % por riba do máximo de 2007.

<LineChart
    data={pib_hab}
    x=anio
    y=valor
    yAxisTitle="€ por habitante (reais)"
    yFmt='#,##0" €"'
    xFmt='0'
    startingAtZero={false}
    title="PIB por habitante en euros de {pib_trim[0]?.anio_euros}"
/>

## Crecemento trimestral

Variación do PIB real fronte ao mesmo trimestre do ano anterior, desestacionalizada. A caída de 2020 e o rebote de 2021 saen de escala.

<BarChart
    data={pib_trim.filter(d => d.interanual != null)}
    x=trimestre
    y=interanual
    yAxisTitle="% interanual"
    yFmt='0.0"%"'
    title="PIB real, variación interanual (%)"
/>

## En que se gasta o que se produce

Consumo dos fogares, consumo público e investimento por habitante, en euros constantes e a ritmo anual (o trimestre multiplicado por catro). O comercio exterior ten a súa propia páxina: [exportacións e importacións](/gl/economia/comercio-exterior).

<LineChart
    data={demanda}
    x=trimestre
    y=euros_hab
    series=nombre
    yAxisTitle="€ por habitante (reais)"
    yFmt='#,##0" €"'
    title="Demanda por habitante, euros de {pib_trim[0]?.anio_euros} a ritmo anual"
/>

## Comparación con Europa

PIB por habitante en paridade de poder de compra, que corrixe que os prezos non son iguais en todos os países (UE-27 = 100). En {ue_ult[0]?.anio} España está en {formatNumber(pib_hab.filter(d => d.indice_ue != null).slice(-1)[0]?.indice_ue, 1)}.

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

**Fontes:** [Eurostat, namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table) (contabilidade nacional trimestral, desestacionalizada) e [nama_10_pc](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table) (PIB por habitante). Os volumes encadeados reexprésanse en euros de {pib_trim[0]?.anio_euros}; a poboación é a media anual de Eurostat.
