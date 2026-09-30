---
description: "Catalogue of the official sources used by SpainFacts (INE, Eurostat, ministries, REE...), with their frequency, licence and methodology."
title: Source Traceability and Audit
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 238721c8a7b0
---

<script>
    import { formatNumber } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
</script>

# Traceability and Audit of Official Sources

At **SpainFacts**, every figure, chart and calculation is **100% verifiable and traceable** back to its original official publication. We do not produce our own estimates or manipulate the series: the data come from public bodies and are extracted through automated, auditable pipelines.

```sql fuentes_list
SELECT
    fuente_id,
    organismo,
    nombre_dataset,
    cod_oficial,
    frecuencia,
    formato_ingesta,
    tipo_licencia,
    url_oficial,
    metodologia,
    estado_pipeline
FROM mother.trazabilidad_fuentes
ORDER BY organismo ASC, nombre_dataset ASC
```

```sql stats_organismos
SELECT
    count(distinct organismo) AS total_organismos,
    count(*) AS total_datasets
FROM mother.trazabilidad_fuentes
```

<Grid cols=4>
    <KpiCard
        title="Official Datasets"
        value={stats_organismos[0].total_datasets}
        formattedValue="{stats_organismos[0].total_datasets}"
        unit="active sources"
        period="Current catalogue"
        direction="neutral"
        source="MotherDuck"
    />

    <KpiCard
        title="Connected Bodies"
        value={stats_organismos[0].total_organismos}
        formattedValue="{stats_organismos[0].total_organismos}"
        unit="institutions"
        period="INE, Eurostat, IGAE, BdE"
        direction="neutral"
        source="Official Catalogue"
    />

    <KpiCard
        title="Licence Type"
        value="100%"
        formattedValue="100%"
        unit="Open Data"
        period="Law 37/2007 / CC-BY 4.0"
        direction="positive-up"
        source="Public Sector"
    />

    <KpiCard
        title="Synchronisation"
        value="Diaria"
        formattedValue="Daily"
        unit="Automatic"
        period="06:00 Madrid time (Dagster)"
        direction="positive-up"
        source="GitHub Actions"
    />
</Grid>

---

## 1. Full Directory of Sources and Datasets

Below are all the sources integrated into the SpainFacts database, including the dataset's official code, publication frequency, methodology and a direct link to the publishing portal:

<DataTable data={fuentes_list} search=true rows=10>
    <Column id=organismo title="Body" />
    <Column id=nombre_dataset title="Dataset Name" />
    <Column id=cod_oficial title="Official Code" />
    <Column id=frecuencia title="Frequency" />
    <Column id=formato_ingesta title="API Format" />
    <Column id=tipo_licencia title="Licence" />
    <Column id=url_oficial title="Official Source" contentType=link linkText="View at source ↗" />
</DataTable>

---

## 2. Methodology of the Official Sources

Each body uses rigorous statistical frameworks, standardised at national and international level:

<Accordion>
  <AccordionItem title="National Statistics Institute (INE)">
    <p><b>Legal and methodological framework:</b> Governed by the Public Statistical Function Act (Law 12/1989). All operations form part of the National Statistical Plan.</p>
    <ul class="list-disc pl-5 mt-2 space-y-1">
      <li><b>CPI (Consumer Price Index):</b> Weighting of a basket of more than 400 items based on the Household Budget Survey. Base 2021.</li>
      <li><b>EPA (Labour Force Survey):</b> Quarterly sample of 65,000 households (approx. 160,000 people) following the guidelines of the International Labour Organization (ILO).</li>
      <li><b>Continuous Municipal Register:</b> Consolidated administrative register as of 1 January, with the information submitted by Spain's 8,131 municipal councils.</li>
    </ul>
  </AccordionItem>

  <AccordionItem title="Eurostat (Statistical Office of the European Union)">
    <p><b>Legal and methodological framework:</b> Statistics harmonised under the European System of National and Regional Accounts (ESA 2010).</p>
    <ul class="list-disc pl-5 mt-2 space-y-1">
      <li><b>Government finance accounts (gov_10a_main):</b> Record of the non-financial revenue and expenditure transactions of EU member states.</li>
      <li><b>COFOG functional classification (gov_10a_exp):</b> Breakdown of public spending into 10 functional divisions agreed internationally by the UN and the OECD.</li>
      <li><b>EDP debt (gov_10q_ggdebt):</b> Consolidated gross general government debt at nominal value under the Excessive Deficit Procedure of the Maastricht Treaty.</li>
    </ul>
  </AccordionItem>

  <AccordionItem title="General Comptroller of the State Administration (IGAE)">
    <p><b>Legal and methodological framework:</b> Internal control body of the central public sector and managing centre for public accounting, reporting to the Ministry of Finance.</p>
    <p class="mt-1">It publishes monthly budget execution data for the Central Government, the Autonomous Communities, Social Security and Local Authorities.</p>
  </AccordionItem>

  <AccordionItem title="Bank of Spain (BdE)">
    <p><b>Legal and methodological framework:</b> Part of the European System of Central Banks (ESCB). Responsible for compiling the Financial Accounts of the Spanish economy and public debt by instrument and maturity.</p>
  </AccordionItem>
</Accordion>

---

## 3. Quality Assurance and No Manipulation

SpainFacts applies a strict technical integrity protocol:

1. **Idempotent Ingestion:** The Python scripts ([`ingestion/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/ingestion)) download the responses directly from public APIs without altering the numerical values.
2. **Automatic Validation with dbt (`dbt test`):** Every transformation passes automated tests for non-null values, uniqueness and date consistency. If an external source returns corrupt data, deployment stops automatically.
3. **100% Open Code:** All the infrastructure, SQL queries and transformation models are publicly available on [GitHub](https://github.com/SpainFacts/spainfacts.github.io).

<LastRefreshed prefix="Source catalogue verified" />
