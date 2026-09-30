---
description: "SpainFactsek erabiltzen dituen iturri ofizialen katalogoa (INE, Eurostat, ministerioak, REE...), haien maiztasuna, lizentzia eta metodologiarekin."
title: Iturrien Trazabilitatea eta Auditoria
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 238721c8a7b0
---

<script>
    import { formatNumber } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
</script>

# Iturri Ofizialen Trazabilitatea eta Auditoria

**SpainFacts**en, datu, grafiko eta kalkulu bakoitza **100% egiaztagarria eta trazagarria** da jatorrizko argitalpen ofizialeraino. Ez dugu geure estimaziorik egiten, ezta serieak manipulatzen ere: datuak erakunde publikoetatik datoz eta pipeline automatizatu eta auditagarrien bidez ateratzen dira.

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
        title="Datu-multzo Ofizialak"
        value={stats_organismos[0].total_datasets}
        formattedValue="{stats_organismos[0].total_datasets}"
        unit="iturri aktibo"
        period="Egungo katalogoa"
        direction="neutral"
        source="MotherDuck"
    />

    <KpiCard
        title="Konektatutako Erakundeak"
        value={stats_organismos[0].total_organismos}
        formattedValue="{stats_organismos[0].total_organismos}"
        unit="erakunde"
        period="INE, Eurostat, IGAE, BdE"
        direction="neutral"
        source="Katalogo Ofiziala"
    />

    <KpiCard
        title="Lizentzia Mota"
        value="100%"
        formattedValue="100%"
        unit="Datu Irekiak"
        period="37/2007 Legea / CC-BY 4.0"
        direction="positive-up"
        source="Sektore Publikoa"
    />

    <KpiCard
        title="Sinkronizazioa"
        value="Diaria"
        formattedValue="Egunero"
        unit="Automatikoa"
        period="06:00, Madrilgo ordua (Dagster)"
        direction="positive-up"
        source="GitHub Actions"
    />
</Grid>

---

## 1. Iturri eta Datu-multzoen Direktorio Osoa

Jarraian zehazten dira SpainFactsen datu-basean integratutako iturri guztiak, datu-multzoaren kode ofiziala, argitalpen-maiztasuna, metodologia eta argitaratzen duen atariko esteka zuzena barne:

<DataTable data={fuentes_list} search=true rows=10>
    <Column id=organismo title="Erakundea" />
    <Column id=nombre_dataset title="Datu-multzoaren izena" />
    <Column id=cod_oficial title="Kode Ofiziala" />
    <Column id=frecuencia title="Maiztasuna" />
    <Column id=formato_ingesta title="API Formatua" />
    <Column id=tipo_licencia title="Erabilera-lizentzia" />
    <Column id=url_oficial title="Iturri Ofiziala" contentType=link linkText="Ikusi jatorrian ↗" />
</DataTable>

---

## 2. Iturri Ofizialen Metodologia

Erakunde bakoitzak esparru estatistiko zorrotzak eta estandarizatuak erabiltzen ditu, nazio mailan eta nazioartean:

<Accordion>
  <AccordionItem title="Estatistikako Institutu Nazionala (INE)">
    <p><b>Lege- eta metodologia-esparrua:</b> Estatistika Publikoaren Funtzioari buruzko Legeak (12/1989 Legea) arautua. Eragiketa guztiak Estatistika Plan Nazionalaren parte dira.</p>
    <ul class="list-disc pl-5 mt-2 space-y-1">
      <li><b>KPI (Kontsumoko Prezioen Indizea):</b> 400 artikulu baino gehiagoko saski baten haztapena, Familien Aurrekontuei buruzko Inkestan oinarritua. 2021 oinarria.</li>
      <li><b>EPA (Biztanleria Aktiboaren Inkesta):</b> Hiruhileko laginketa, 65.000 etxetan (160.000 pertsona inguru), Lanaren Nazioarteko Erakundearen (LANE) jarraibideei jarraituz.</li>
      <li><b>Etengabeko Errolda:</b> Urtarrilaren 1ean bateratutako erregistro administratiboa, Espainiako 8.131 udalek bidalitako informazioarekin.</li>
    </ul>
  </AccordionItem>

  <AccordionItem title="Eurostat (Europar Batasuneko Estatistika Bulegoa)">
    <p><b>Lege- eta metodologia-esparrua:</b> Kontu Nazional eta Erregionalen Europako Sistemaren (SEC 2010) arabera harmonizatutako estatistikak.</p>
    <ul class="list-disc pl-5 mt-2 space-y-1">
      <li><b>Administrazio Publikoen Kontuak (gov_10a_main):</b> EBko estatu kideen diru-sarrera eta gastuen finantzakoak ez diren eragiketen erregistroa.</li>
      <li><b>COFOG Sailkapen Funtzionala (gov_10a_exp):</b> Gastu publikoaren banakapena, NBEk eta ELGAk nazioartean adostutako 10 dibisio funtzionaletan.</li>
      <li><b>GDPren araberako zorra (gov_10q_ggdebt):</b> Administrazio publikoen zor gordin bateratua, balio nominalean baloratua, Maastrichteko Itunaren Gehiegizko Defizitaren Prozeduraren arabera.</li>
    </ul>
  </AccordionItem>

  <AccordionItem title="Estatuko Administrazioaren Kontu-hartzailetza Nagusia (IGAE)">
    <p><b>Lege- eta metodologia-esparrua:</b> Estatuko sektore publikoaren barne-kontroleko organoa eta kontabilitate publikoaren zentro kudeatzailea, Ogasun Ministerioaren mendekoa.</p>
    <p class="mt-1">Hilero argitaratzen du Administrazio Zentralaren, Autonomia Erkidegoen, Gizarte Segurantzaren eta Toki Korporazioen aurrekontu-betearazpena.</p>
  </AccordionItem>

  <AccordionItem title="Espainiako Bankua (BdE)">
    <p><b>Lege- eta metodologia-esparrua:</b> Banku Zentralen Europako Sisteman (BZES) integratua. Espainiako ekonomiaren Finantza Kontuak eta zor publikoa tresna eta epeen arabera lantzeaz arduratzen da.</p>
  </AccordionItem>
</Accordion>

---

## 3. Kalitatearen Bermea eta Manipulaziorik Eza

SpainFactsek osotasun teknikoko protokolo zorrotz bat aplikatzen du:

1. **Karga Idenpotentea:** Python scriptek ([`ingestion/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/ingestion)) API publikoen erantzun zuzenak deskargatzen dituzte, balio numerikoak aldatu gabe.
2. **Balidazio Automatikoa dbt-rekin (`dbt test`):** Eraldaketa bakoitzak proba automatikoak gainditzen ditu: balio ez-nuluak, bakartasuna eta daten koherentzia. Kanpoko iturri batek datu hondatuak itzultzen baditu, hedapena automatikoki gelditzen da.
3. **100% Kode Irekia:** Azpiegitura osoa, SQL kontsultak eta eraldaketa-ereduak publikoki daude eskuragarri [GitHub](https://github.com/SpainFacts/spainfacts.github.io)en.

<LastRefreshed prefix="Iturrien katalogoa egiaztatuta" />
