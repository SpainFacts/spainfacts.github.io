---
description: "Catàleg de les fonts oficials que utilitza SpainFacts (INE, Eurostat, ministeris, REE...), amb la metodologia, la llicència i el codi a GitHub per reconstruir cada dada."
title: Traçabilitat i auditoria de fonts
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: bc32e4e4d483
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import CatalogoFuentes from '../../../../../../src/lib/components/CatalogoFuentes.svelte';
</script>

# Traçabilitat i auditoria de fonts oficials

A **SpainFacts** cada dada, gràfic i càlcul es pot seguir fins a la seva publicació oficial original. No ens inventem xifres: descarreguem les dades d'organismes públics amb codi obert i qualsevol persona pot repetir el procés pel seu compte. Les etiquetes de font de les targetes de tot el web enllacen aquí, a la fitxa de la seva font.

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
        title="Conjunts de dades"
        value={stats_organismos[0].total_datasets}
        formattedValue="{stats_organismos[0].total_datasets}"
        unit="al catàleg"
        period="Cadascun amb la seva fitxa i el seu codi"
        direction="neutral"
    />

    <KpiCard
        title="Organismes"
        value={stats_organismos[0].total_organismos}
        formattedValue="{stats_organismos[0].total_organismos}"
        unit="fonts oficials"
        period="INE, Eurostat, ministeris, REE…"
        direction="neutral"
    />
</Grid>

## Com es reconstrueix una dada

Tot el procés és al [repositori públic de GitHub](https://github.com/SpainFacts/spainfacts.github.io). Cada dada passa per cinc passos i cada pas és un fitxer que es pot llegir:

1. **Descàrrega de l'organisme.** Les dades surten del portal oficial (l'enllaç «Mostra a l'origen» de cada fitxa).
2. **Ingesta** ([`ingestion/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/ingestion)). Scripts de Python amb [dlt](https://dlthub.com) que criden l'API o descarreguen el fitxer i el desen tal qual a l'esquema `raw`, sense tocar els valors.
3. **Transformació** ([`transform/models/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/transform/models)). Models SQL de [dbt](https://www.getdbt.com) que netegen, uneixen i calculen (per habitant, en euros constants…). Les dades fetes a mà, com aquest catàleg, són a [`transform/seeds/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/transform/seeds).
4. **Consultes del web** ([`sources/mother/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/sources/mother)). El que llegeix cada pàgina.
5. **Pàgina** ([`pages/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/pages)). El text, l'SQL de cada gràfic i els càlculs finals.

Obre qualsevol conjunt de dades del catàleg per veure'n l'script, les taules, els models dbt i les pàgines que l'utilitzen, amb les ordres per repetir-ho.

### Repetir-ho al teu ordinador

No cal cap compte: tot funciona contra un fitxer DuckDB local. Necessites [Python amb uv](https://docs.astral.sh/uv/), [Node.js](https://nodejs.org) i git.

```bash
git clone https://github.com/SpainFacts/spainfacts.github.io.git
cd spainfacts.github.io
uv venv
uv pip install -r orchestration/requirements.txt

# escriure a data/spainfacts.duckdb en lloc de a la base de producció
export SPAINFACTS_DESTINO=local

# un script d'ingesta (el de cada fitxa) i els seus models dbt
uv run python -m ingestion.aena
uv run dbt build --project-dir transform --profiles-dir transform --select movilidad_aeropuertos_mensual+

# o tota la cadena d'una vegada
uv run dagster asset materialize -m orchestration.definitions --select "*"
```

La guia completa, amb el web en local, és a [docs/desarrollo-local.md](https://github.com/SpainFacts/spainfacts.github.io/blob/main/docs/desarrollo-local.md), i com s'afegeix una font nova, a [docs/GUIA_INGESTA_Y_METRICAS.md](https://github.com/SpainFacts/spainfacts.github.io/blob/main/docs/GUIA_INGESTA_Y_METRICAS.md).

## Catàleg de fonts

Cerca per organisme, nom, codi oficial o paraules de la metodologia. Cada fitxa té un enllaç propi per compartir-la.

<CatalogoFuentes data={fuentes_list} />

## Marc dels principals organismes

<Accordion>
  <AccordionItem title="Institut Nacional d'Estadística (INE)">
    <p><b>Marc legal i metodològic:</b> Regulat per la Llei de la Funció Estadística Pública (Llei 12/1989). Totes les operacions formen part del Pla Estadístic Nacional.</p>
    <ul class="list-disc pl-5 mt-2 space-y-1">
      <li><b>IPC (Índex de Preus de Consum):</b> Ponderació d'una cistella de més de 400 articles basada en l'Enquesta de Pressupostos Familiars. Base 2021.</li>
      <li><b>EPA (Enquesta de Població Activa):</b> Mostreig trimestral sobre 65.000 llars (aprox. 160.000 persones) seguint les directrius de l'Organització Internacional del Treball (OIT).</li>
      <li><b>Padró continu:</b> Registre administratiu consolidat a 1 de gener amb la informació tramesa pels 8.131 ajuntaments d'Espanya.</li>
    </ul>
  </AccordionItem>

  <AccordionItem title="Eurostat (Oficina Estadística de la Unió Europea)">
    <p><b>Marc legal i metodològic:</b> Estadístiques harmonitzades segons el Sistema Europeu de Comptes Nacionals i Regionals (SEC 2010).</p>
    <ul class="list-disc pl-5 mt-2 space-y-1">
      <li><b>Comptes de les administracions públiques (gov_10a_main):</b> Registre d'operacions no financeres d'ingressos i despeses dels estats membres de la UE.</li>
      <li><b>Classificació funcional COFOG (gov_10a_exp):</b> Desglossament de la despesa pública en 10 divisions funcionals acordades internacionalment per l'ONU i l'OCDE.</li>
      <li><b>Deute segons el PDE (gov_10q_ggdebt):</b> Deute brut consolidat de les AP valorat a valor nominal segons el Protocol de Dèficit Excessiu del Tractat de Maastricht.</li>
    </ul>
  </AccordionItem>

  <AccordionItem title="Intervenció General de l'Administració de l'Estat (IGAE)">
    <p><b>Marc legal i metodològic:</b> Òrgan de control intern del sector públic estatal i centre gestor de la comptabilitat pública, dependent del Ministeri d'Hisenda.</p>
    <p class="mt-1">Publica mensualment l'execució pressupostària de l'Administració central, les comunitats autònomes, la Seguretat Social i les corporacions locals.</p>
  </AccordionItem>

  <AccordionItem title="Banc d'Espanya (BdE)">
    <p><b>Marc legal i metodològic:</b> Integrat en el Sistema Europeu de Bancs Centrals (SEBC). Responsable de l'elaboració dels Comptes Financers de l'economia espanyola i del deute públic per instruments i terminis.</p>
  </AccordionItem>
</Accordion>

## Garanties de qualitat

1. **Els valors no es toquen en carregar-los.** Els scripts d'ingesta desen la resposta de l'organisme tal qual; els càlculs (per habitant, deflactats…) es fan després, en SQL a la vista.
2. **Proves a cada actualització.** La cadena s'actualitza sola cada dia a les 06:00 (hora de Madrid) amb [Dagster](https://dagster.io). Els models dbt porten proves de valors no nuls, unicitat i coherència de dates; si fallen, l'actualització s'atura abans de publicar.
3. **Proves del web.** Abans de cada publicació, unes proves automàtiques obren les pàgines i comproven que carreguen i mostren dades.
4. **Codi obert.** Ingesta, transformacions, consultes i pàgines són a [GitHub](https://github.com/SpainFacts/spainfacts.github.io). Si hi veus un error, pots [obrir una incidència](https://github.com/SpainFacts/spainfacts.github.io/issues).

<LastRefreshed prefix="Catàleg de fonts verificat" />
