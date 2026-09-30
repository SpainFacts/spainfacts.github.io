---
description: "Catàleg de les fonts oficials que utilitza SpainFacts (INE, Eurostat, ministeris, REE...), amb la freqüència, la llicència i la metodologia."
title: Traçabilitat i auditoria de fonts
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 238721c8a7b0
---

<script>
    import { formatNumber } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
</script>

# Traçabilitat i auditoria de fonts oficials

A **SpainFacts**, cada dada, gràfic i càlcul és **100% verificable i traçable** fins a la seva publicació oficial original. No generem estimacions pròpies ni manipulem les sèries: les dades provenen d'organismes públics i s'extreuen mitjançant processos automatitzats i auditables.

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
        title="Conjunts de dades oficials"
        value={stats_organismos[0].total_datasets}
        formattedValue="{stats_organismos[0].total_datasets}"
        unit="fonts actives"
        period="Catàleg actual"
        direction="neutral"
        source="MotherDuck"
    />

    <KpiCard
        title="Organismes connectats"
        value={stats_organismos[0].total_organismos}
        formattedValue="{stats_organismos[0].total_organismos}"
        unit="institucions"
        period="INE, Eurostat, IGAE, BdE"
        direction="neutral"
        source="Catàleg oficial"
    />

    <KpiCard
        title="Tipus de llicència"
        value="100%"
        formattedValue="100%"
        unit="Dades obertes"
        period="Llei 37/2007 / CC-BY 4.0"
        direction="positive-up"
        source="Sector públic"
    />

    <KpiCard
        title="Sincronització"
        value="Diaria"
        formattedValue="Diària"
        unit="Automàtica"
        period="06:00 hora de Madrid (Dagster)"
        direction="positive-up"
        source="GitHub Actions"
    />
</Grid>

---

## 1. Directori complet de fonts i conjunts de dades

A continuació es detallen totes les fonts integrades a la base de dades de SpainFacts, incloent-hi el codi oficial del conjunt de dades, la freqüència de publicació, la metodologia i l'enllaç directe al portal emissor:

<DataTable data={fuentes_list} search=true rows=10>
    <Column id=organismo title="Organisme" />
    <Column id=nombre_dataset title="Nom del conjunt de dades" />
    <Column id=cod_oficial title="Codi oficial" />
    <Column id=frecuencia title="Freqüència" />
    <Column id=formato_ingesta title="Format API" />
    <Column id=tipo_licencia title="Llicència d'ús" />
    <Column id=url_oficial title="Font oficial" contentType=link linkText="Mostra a l'origen ↗" />
</DataTable>

---

## 2. Metodologia de les fonts oficials

Cada organisme utilitza marcs estadístics rigorosos i estandarditzats en l'àmbit nacional i internacional:

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

---

## 3. Garantia de qualitat i no manipulació

SpainFacts aplica un protocol estricte d'integritat tècnica:

1. **Ingesta idempotent:** Els scripts de Python ([`ingestion/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/ingestion)) descarreguen les respostes directes de les API públiques sense modificar els valors numèrics.
2. **Validació automàtica amb dbt (`dbt test`):** Cada transformació passa proves automàtiques de valors no nuls, unicitat i coherència de dates. Si una font externa retorna dades corruptes, el desplegament s'atura automàticament.
3. **Codi 100% obert:** Tota la infraestructura, les consultes SQL i els models de transformació estan disponibles públicament a [GitHub](https://github.com/SpainFacts/spainfacts.github.io).

<LastRefreshed prefix="Catàleg de fonts verificat" />
