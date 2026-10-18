---
description: "SpainFactsek erabiltzen dituen iturri ofizialen katalogoa (INE, Eurostat, ministerioak, REE...), haien metodologia, lizentzia eta datu bakoitza berreraikitzeko GitHubeko kodearekin."
title: Iturrien Trazabilitatea eta Auditoria
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: bc32e4e4d483
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import CatalogoFuentes from '../../../../../../src/lib/components/CatalogoFuentes.svelte';
</script>

# Iturri Ofizialen Trazabilitatea eta Auditoria

**SpainFacts**en datu, grafiko eta kalkulu bakoitza jatorrizko argitalpen ofizialeraino jarraitu daiteke. Ez dugu zifrarik asmatzen: erakunde publikoen datuak kode irekiarekin deskargatzen ditugu, eta edonork errepika dezake prozesua bere kabuz. Webgune osoko txarteletako iturri-etiketek hona daramate, beren iturriaren fitxara.

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
        title="Datu-multzoak"
        value={stats_organismos[0].total_datasets}
        formattedValue="{stats_organismos[0].total_datasets}"
        unit="katalogoan"
        period="Bakoitza bere fitxa eta kodearekin"
        direction="neutral"
    />

    <KpiCard
        title="Erakundeak"
        value={stats_organismos[0].total_organismos}
        formattedValue="{stats_organismos[0].total_organismos}"
        unit="iturri ofizial"
        period="INE, Eurostat, ministerioak, REE…"
        direction="neutral"
    />
</Grid>

## Nola berreraiki datu bat

Prozesu osoa [GitHubeko biltegi publikoan](https://github.com/SpainFacts/spainfacts.github.io) dago. Datu bakoitzak bost urrats igarotzen ditu, eta urrats bakoitza irakur daitekeen fitxategi bat da:

1. **Erakundetik deskargatzea.** Datuak atari ofizialetik datoz (fitxa bakoitzeko «Ikusi jatorrian» esteka).
2. **Karga** ([`ingestion/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/ingestion)). [dlt](https://dlthub.com) erabiltzen duten Python scriptak, APIari deitzen diotenak edo fitxategia deskargatzen dutenak, eta `raw` eskeman dagoen bezala gordetzen dutenak, balioak ukitu gabe.
3. **Eraldaketa** ([`transform/models/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/transform/models)). [dbt](https://www.getdbt.com)-ren SQL ereduak, garbitu, elkartu eta kalkulatzen dutenak (biztanleko, euro konstantetan…). Eskuz egindako datuak, katalogo hau adibidez, [`transform/seeds/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/transform/seeds) karpetan daude.
4. **Webguneko kontsultak** ([`sources/mother/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/sources/mother)). Orri bakoitzak irakurtzen duena.
5. **Orria** ([`pages/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/pages)). Testua, grafiko bakoitzaren SQLa eta azken kalkuluak.

Ireki katalogoko edozein datu-multzo haren scripta, taulak, dbt ereduak eta erabiltzen duten orriak ikusteko, errepikatzeko aginduekin batera.

### Zure ordenagailuan errepikatu

Ez da konturik behar: dena DuckDB fitxategi lokal baten aurka dabil. [Python uv-rekin](https://docs.astral.sh/uv/), [Node.js](https://nodejs.org) eta git behar dituzu.

```bash
git clone https://github.com/SpainFacts/spainfacts.github.io.git
cd spainfacts.github.io
uv venv
uv pip install -r orchestration/requirements.txt

# data/spainfacts.duckdb fitxategian idatzi, ekoizpeneko datu-basean idatzi beharrean
export SPAINFACTS_DESTINO=local

# karga-script bat (fitxa bakoitzekoa) eta haren dbt ereduak
uv run python -m ingestion.aena
uv run dbt build --project-dir transform --profiles-dir transform --select movilidad_aeropuertos_mensual+

# edo kate osoa batera
uv run dagster asset materialize -m orchestration.definitions --select "*"
```

Gida osoa, webgunea lokalean abiarazteko urratsekin, [docs/desarrollo-local.md](https://github.com/SpainFacts/spainfacts.github.io/blob/main/docs/desarrollo-local.md) fitxategian dago, eta iturri berri bat nola gehitzen den, [docs/GUIA_INGESTA_Y_METRICAS.md](https://github.com/SpainFacts/spainfacts.github.io/blob/main/docs/GUIA_INGESTA_Y_METRICAS.md) fitxategian.

## Iturrien katalogoa

Bilatu erakundearen, izenaren, kode ofizialaren edo metodologiako hitzen arabera. Fitxa bakoitzak bere esteka du partekatu ahal izateko.

<CatalogoFuentes data={fuentes_list} />

## Erakunde nagusien esparrua

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

## Kalitate-bermeak

1. **Balioak ez dira ukitzen kargatzean.** Karga-scriptek erakundearen erantzuna dagoen bezala gordetzen dute; kalkuluak (biztanleko, inflazioaren arabera doituta…) geroago egiten dira, edonork ikus dezakeen SQLan.
2. **Probak eguneraketa bakoitzean.** Katea bere kabuz eguneratzen da egunero 06:00etan (Madrilgo ordua), [Dagster](https://dagster.io) bidez. dbt ereduek balio ez-nuluen, bakartasunaren eta daten koherentziaren probak dituzte; huts egiten badute, eguneraketa gelditu egiten da ezer argitaratu aurretik.
3. **Webgunearen probak.** Argitalpen bakoitzaren aurretik, proba automatikoek orriak ireki eta kargatzen direla eta datuak erakusten dituztela egiaztatzen dute.
4. **Kode irekia.** Karga, eraldaketak, kontsultak eta orriak [GitHuben](https://github.com/SpainFacts/spainfacts.github.io) daude. Akatsen bat ikusten baduzu, [arazo bat ireki](https://github.com/SpainFacts/spainfacts.github.io/issues) dezakezu.

<LastRefreshed prefix="Iturrien katalogoa egiaztatuta" />
