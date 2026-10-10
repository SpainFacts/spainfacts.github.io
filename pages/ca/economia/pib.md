---
title: PIB i creixement
description: "Evolució del PIB d'Espanya per habitant i descomptada la inflació, creixement trimestral, components de la demanda i comparació amb la UE."
i18n_origen: e052747ef102
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
    anio_base
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

# 📈 PIB i creixement

El producte interior brut mesura tot el que produeix l'economia. Per veure si el país s'enriqueix de debò, aquí es mostra **per habitant** (si no, creix només sumant població) i **descomptada la inflació**, en euros del {pib_trim[0]?.anio_base}.

<Grid cols=4>
    <KpiCard
        title="PIB per habitant"
        value={pib_hab.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pib_hab.slice(-1)[0]?.valor, 0)} €"
        period="el {pib_hab.slice(-1)[0]?.anio}, en euros del {pib_trim[0]?.anio_base}"
        change={pib_hab.slice(-1)[0]?.crecimiento?.toFixed(1)}
        changePeriod="real respecte a l'any anterior"
        direction="positive-up"
        source="Eurostat"
        sparklineData={pib_hab}
    />
    <KpiCard
        title="Creixement del PIB"
        value={pib_trim.slice(-1)[0]?.interanual}
        formattedValue="{formatNumber(pib_trim.slice(-1)[0]?.interanual, 1)} %"
        period="interanual real, {pib_trim.slice(-1)[0]?.periodo}"
        source="Eurostat"
        sparklineData={pib_trim.slice(-24).map(d => ({...d, y: d.interanual}))}
    />
    <KpiCard
        title="PIB per habitant, ritme anual"
        value={pib_trim.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pib_trim.slice(-1)[0]?.valor, 0)} €"
        period="últim trimestre ({pib_trim.slice(-1)[0]?.periodo}) multiplicat per quatre · PIB total {formatNumber(pib_trim.slice(-1)[0]?.real_meur / 1000, 0)} mil M€ en el trimestre"
        source="Eurostat"
        sparklineData={pib_trim.slice(-40)}
    />
    <KpiCard
        title="Nivell de vida davant la UE"
        value={pib_hab.filter(d => d.indice_ue != null).slice(-1)[0]?.indice_ue}
        formattedValue={formatNumber(pib_hab.filter(d => d.indice_ue != null).slice(-1)[0]?.indice_ue, 1)}
        period="PIB per habitant en paritat de poder adquisitiu, UE = 100"
        source="Eurostat"
        sparklineData={pib_hab.filter(d => d.indice_ue != null).map(d => ({...d, y: d.indice_ue}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('pib_pc_ppa', 'crecimiento_pib')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'pib_pc_ppa')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'crecimiento_pib')} />


## PIB per habitant des del 1995

En euros constants del {pib_trim[0]?.anio_base}. La crisi del 2008 va retallar el PIB per habitant un {formatNumber(-hitos[0]?.caida_crisis, 1)} % fins al 2013; la pandèmia el va enfonsar el 2020 i el {hitos[0]?.anio_ult} és un {formatNumber(hitos[0]?.vs2007, 1)} % per sobre del màxim del 2007.

<LineChart
    data={pib_hab}
    x=anio
    y=valor
    yAxisTitle="€ per habitant (reals)"
    yFmt='#,##0" €"'
    xFmt='0'
    startingAtZero={false}
    title="PIB per habitant en euros del {pib_trim[0]?.anio_base}"
/>

## Creixement trimestral

Variació del PIB real respecte al mateix trimestre de l'any anterior, desestacionalitzada. L'enfonsament del 2020 i el rebot del 2021 surten d'escala.

<BarChart
    data={pib_trim.filter(d => d.interanual != null)}
    x=trimestre
    y=interanual
    yAxisTitle="% interanual"
    yFmt='0.0"%"'
    title="PIB real, variació interanual (%)"
/>

## En què es gasta el que es produeix

Consum de les llars, consum públic i inversió per habitant, en euros constants i a ritme anual (el trimestre multiplicat per quatre). El comerç exterior té la seva pròpia pàgina: [exportacions i importacions](/ca/economia/comercio-exterior).

<LineChart
    data={demanda}
    x=trimestre
    y=euros_hab
    series=nombre
    yAxisTitle="€ per habitant (reals)"
    yFmt='#,##0" €"'
    title="Demanda per habitant, euros del {pib_trim[0]?.anio_base} a ritme anual"
/>

## Comparació amb Europa

PIB per habitant en paritat de poder adquisitiu, que corregeix que els preus no són iguals a tots els països (UE-27 = 100). El {ue_ult[0]?.anio} Espanya és a {formatNumber(pib_hab.filter(d => d.indice_ue != null).slice(-1)[0]?.indice_ue, 1)}.

<LineChart
    data={ue}
    x=anio
    y=indice_ue
    series=nombre
    xFmt='0'
    yAxisTitle="UE-27 = 100"
    startingAtZero={false}
    title="PIB per habitant en PPS (UE-27 = 100)"
/>

<DataTable data={ue_ult} rows=10>
    <Column id=nombre title="País"/>
    <Column id=indice_ue title="Índex (UE = 100)" fmt='0.0'/>
</DataTable>

---

**Fonts:** [Eurostat, namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table) (comptabilitat nacional trimestral, desestacionalitzada) i [nama_10_pc](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table) (PIB per habitant). Els volums encadenats es reexpressen en euros del {pib_trim[0]?.anio_base}; la població és la mitjana anual d'Eurostat.
