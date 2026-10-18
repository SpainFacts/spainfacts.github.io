---
description: "Catalogue of the official sources used by SpainFacts (INE, Eurostat, ministries, REE...), with their methodology, licence and the code on GitHub to rebuild every figure."
title: Source Traceability and Audit
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: bc32e4e4d483
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import CatalogoFuentes from '../../../../../../src/lib/components/CatalogoFuentes.svelte';
</script>

# Traceability and Audit of Official Sources

At **SpainFacts**, every figure, chart and calculation can be traced back to its original official publication. We do not make up numbers: we download the data from public bodies with open code, and anyone can repeat the process on their own. The source labels on cards across the site link here, to the entry for their source.

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
    metodologia
FROM mother.trazabilidad_fuentes
ORDER BY organismo ASC, nombre_dataset ASC
```

```sql stats_organismos
SELECT
    count(distinct organismo) AS total_organismos,
    count(*) AS total_datasets
FROM mother.trazabilidad_fuentes
```

<Grid cols=2>
    <KpiCard
        title="Datasets"
        value={stats_organismos[0].total_datasets}
        formattedValue="{stats_organismos[0].total_datasets}"
        unit="in the catalogue"
        period="Each with its own entry and code"
        direction="neutral"
    />

    <KpiCard
        title="Bodies"
        value={stats_organismos[0].total_organismos}
        formattedValue="{stats_organismos[0].total_organismos}"
        unit="official sources"
        period="INE, Eurostat, ministries, REE…"
        direction="neutral"
    />
</Grid>

## How to rebuild a figure

The whole process is in the [public GitHub repository](https://github.com/SpainFacts/spainfacts.github.io). Every figure goes through five steps, and each step is a file you can read:

1. **Download from the body.** The data come from the official portal (the "View at source" link in each entry).
2. **Ingestion** ([`ingestion/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/ingestion)). Python scripts using [dlt](https://dlthub.com) that call the API or download the file and store it as is in the `raw` schema, without touching the values.
3. **Transformation** ([`transform/models/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/transform/models)). [dbt](https://www.getdbt.com) SQL models that clean, join and calculate (per person, in constant euros…). Hand-made data, such as this catalogue, live in [`transform/seeds/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/transform/seeds).
4. **Site queries** ([`sources/mother/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/sources/mother)). What each page reads.
5. **Page** ([`pages/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/pages)). The text, the SQL behind each chart and the final calculations.

Open any dataset in the catalogue to see its script, its tables, its dbt models and the pages that use it, along with the commands to repeat it.

### Repeat it on your computer

You don't need any account: everything runs against a local DuckDB file. You need [Python with uv](https://docs.astral.sh/uv/), [Node.js](https://nodejs.org) and git.

```bash
git clone https://github.com/SpainFacts/spainfacts.github.io.git
cd spainfacts.github.io
uv venv
uv pip install -r orchestration/requirements.txt

# write to data/spainfacts.duckdb instead of the production database
export SPAINFACTS_DESTINO=local

# one ingestion script (the one in each entry) and its dbt models
uv run python -m ingestion.aena
uv run dbt build --project-dir transform --profiles-dir transform --select movilidad_aeropuertos_mensual+

# or the whole chain at once
uv run dagster asset materialize -m orchestration.definitions --select "*"
```

The full guide, including running the site locally, is in [docs/desarrollo-local.md](https://github.com/SpainFacts/spainfacts.github.io/blob/main/docs/desarrollo-local.md), and how to add a new source is explained in [docs/GUIA_INGESTA_Y_METRICAS.md](https://github.com/SpainFacts/spainfacts.github.io/blob/main/docs/GUIA_INGESTA_Y_METRICAS.md).

## Source catalogue

Search by body, name, official code or words in the methodology. Each entry has its own link so you can share it.

<CatalogoFuentes data={fuentes_list} />

## Framework of the main bodies

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

## Quality guarantees

1. **Values are not touched when loaded.** The ingestion scripts store the body's response as is; the calculations (per person, adjusted for inflation…) come later, in SQL that anyone can see.
2. **Tests on every update.** The chain updates itself every day at 06:00 (Madrid time) with [Dagster](https://dagster.io). The dbt models carry tests for non-null values, uniqueness and date consistency; if they fail, the update stops before anything is published.
3. **Site tests.** Before each release, automated tests open the pages and check that they load and show data.
4. **Open code.** Ingestion, transformations, queries and pages are on [GitHub](https://github.com/SpainFacts/spainfacts.github.io). If you spot a mistake, you can [open an issue](https://github.com/SpainFacts/spainfacts.github.io/issues).

<LastRefreshed prefix="Source catalogue verified" />
