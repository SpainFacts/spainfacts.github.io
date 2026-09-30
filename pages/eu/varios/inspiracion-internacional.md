---
title: Beste herrialdeetako adibide inspiratzaileak
description: "Eredu gisa balio duten beste herrialdeetako datu irekien eta gardentasunaren proiektuak: USAFacts, Our World in Data, Gapminder, TheyWorkForYou, ProZorro, X-Road, g0v, Chequeado eta gehiago, eta Espainiak bakoitzetik zer ikas lezakeen."
i18n_origen: 6594083ed575
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    // Datuetako proiektu-motak (iragazkiaren gakoak) euskaratzen ditu txarteletan
    const MOTA = {
        'Estadística y divulgación': 'Estatistika eta dibulgazioa',
        'Portales de datos': 'Datu-atariak',
        'Parlamento y política': 'Parlamentua eta politika',
        'Contratación y gobierno digital': 'Kontratazioa eta gobernu digitala',
        'Tecnología cívica': 'Teknologia zibikoa',
        'Verificación': 'Egiaztapena'
    };
    const mota = (s) => MOTA[s] ?? s;
</script>

```sql ejemplos
SELECT *
FROM (VALUES
    -- Estadística y divulgación
    (1, 'Estadística y divulgación', 'USAFacts', 'https://usafacts.org/', 'Ameriketako Estatu Batuak', 'Steve Ballmerrek 2017an sortutako irabazi-asmorik gabeko erakundea; Ameriketako Estatu Batuetako biztanleriari, ekonomiari, aurrekontuari eta zerbitzu publikoei buruzko datu ofizialak leku bakarrean biltzen ditu, iritzirik eta alderdi-atxikimendurik gabe.', 'SpainFactsen inspirazio zuzena da: erakusten du herrialde baten kontuak datu ofizialekin eta modu neutralean konta daitezkeela, edozein herritarrentzat.', 'Zifra publikoetarako sarrera-puntu bakar eta ulergarria, erakundeka sakabanatutako ehunka atariren ordez.', 'Webgune honen inspirazio zuzena', '/eu'),
    (2, 'Estadística y divulgación', 'Our World in Data', 'https://ourworldindata.org/', 'Erresuma Batua (Oxfordeko Unibertsitatea)', 'Global Change Data Laben eta Oxfordeko Unibertsitatearen ikerketa-argitalpena, herrialde guztietako osasunari, pobreziari, energiari, klimari edo hezkuntzari buruzko milaka grafikorekin.', 'Grafiko bakoitzak bere iturria, metodologia eta datuen deskarga ditu, eta haren eduki eta kode guztia irekia da (CC BY).', 'Zifra bakoitza dokumentatzea eta grafikotik bertatik deskargatzeko aukera ematea.', 'SpainFactsek haren serieak erabiltzen ditu nazioarteko alderaketan', '/eu/economia/turismo'),
    (3, 'Estadística y divulgación', 'Gapminder', 'https://www.gapminder.org/', 'Suedia', 'Hans Roslingek, Ola Roslingek eta Anna Rosling Rönnlundek sortutako fundazioa, munduari buruzko ideia okerrei ulertzeko errazak diren estatistikekin aurre egiteko.', 'Haren burbuila-grafiko animatuek eta ezagutza-testek erakusten dute jende informatua ere oker ibili ohi dela munduaren bilakaerari buruz.', 'Herritarren pertzepzio-akatsak neurtzea eta dibulgazioa haiek zuzentzeko diseinatzea.', NULL, NULL),
    (4, 'Estadística y divulgación', 'Statistics Netherlands (CBS)', 'https://www.cbs.nl/', 'Herbehereak', 'Herbehereetako estatistika-bulegoa. Haren StatLine datu-bankuak milaka taula eskaintzen ditu datu ireki gisa, OData API batekin.', 'Haren informazio estatistiko guztia datu ireki gisa argitaratzen da, APIarekin eta CC BY 4.0 lizentziapean.', 'API estandarra eta lizentzia ireki esplizitua taula estatistiko guztietarako.', NULL, NULL),
    (5, 'Estadística y divulgación', 'Statistics Norway (SSB)', 'https://www.ssb.no/', 'Norvegia', 'Norvegiako estatistika-bulegoa. Haren StatBankek serie ofizialetarako sarbidea ematen du, baita API ireki eta doako baten bidez ere.', 'Estatistika oso osoak API erraz batekin eta argitaratutako datu bakoitza azaltzen duten albisteekin konbinatzen ditu.', 'Argitalpen estatistiko bakoitzarekin batera azalpen labur bat eta datu deskargagarriak ematea.', NULL, NULL),
    (6, 'Estadística y divulgación', 'Stats NZ eta data.govt.nz', 'https://www.stats.govt.nz/', 'Zeelanda Berria', 'Zeelanda Berriko estatistika-bulegoa eta datu irekien atari nazionala (data.govt.nz). Stats NZk Integrated Data Infrastructure kudeatzen du, administrazio desberdinetako datuak modu anonimizatuan lotzen dituena ikerketarako.', 'Ikertzaile akreditatuei ibilbide errealak (hezkuntza, enplegua, osasuna, prestazioak) aztertzeko aukera ematen die, pribatutasun-bermeekin.', 'Lotutako erregistro administratiboekin ikertzeko ingurune segurua, datu pertsonalak agerian utzi gabe.', NULL, NULL),
    -- Portales de datos
    (10, 'Portales de datos', 'data.gov.sg', 'https://data.gov.sg/', 'Singapur', 'Singapurko Gobernuaren datu irekien ataria, denbora errealeko APIekin (meteorologia, airearen kalitatea, garraioa) eta milaka datu-multzorekin.', 'Garatzaileek beren zerbitzuetan zuzenean erabil ditzaketen API fidagarri eta dokumentatuetan jartzen du arreta.', 'Denbora errealeko datuei lehentasuna ematea, API egonkorrekin eta dokumentazio argiarekin.', NULL, NULL),
    (11, 'Portales de datos', 'data.europa.eu', 'https://data.europa.eu/', 'Europar Batasuna', 'Europar Batasunaren datu-atari ofiziala; Europako erakundeen eta atari nazionalen datuak biltzen ditu, datos.gob.es barne. Urtero Open Data Maturity txostena argitaratzen du.', 'Europako herrialde bakoitzaren irekitze-maila metodologia berarekin alderatzeko aukera ematen du.', 'Urteko alderaketa hori irekitze-helburu zehatzak finkatzeko erabiltzea.', 'SpainFactsek Eurostat, EBko estatistika-bulegoa, erabiltzen du alderaketa askotan', '/eu/economia/paro'),
    -- Parlamento y política
    (20, 'Parlamento y política', 'TheyWorkForYou eta mySociety', 'https://www.theyworkforyou.com/', 'Erresuma Batua', 'TheyWorkForYouk, mySociety ongintzako erakundearenak, parlamentari britainiar bakoitzak zer esaten eta zer bozkatzen duen erakusten du. mySocietyk WhatDoTheyKnow (modu irekian egindako informazio publikoko eskaerak) eta FixMyStreet (hiriko hondatzeen abisuak) ere sortu zituen.', 'Saioen egunkariak eta bozketak diputatu bakoitzaren fitxa erraz jarraitzeko bihurtzen ditu, beste herrialde batzuetan berrerabilitako APIarekin eta kode irekiarekin.', 'Kongresuko eta Senatuko izenezko bozketak eta esku-hartzeak formatu berrerabilgarrietan argitaratzea.', NULL, NULL),
    (21, 'Parlamento y política', 'GovTrack.us', 'https://www.govtrack.us/', 'Ameriketako Estatu Batuak', 'Ameriketako Estatu Batuetako Kongresuaren legeei eta bozketei 2004tik jarraitzen dien web independentea.', 'Lege-proiektu bakoitzari jarraitzeko, abisuak jasotzeko eta kongresukide bakoitzaren jarduera-estatistikak ikusteko aukera ematen du.', 'Lege bakoitzaren izapidetzearen jarraipen publikoa eta denbora errealekoa.', NULL, NULL),
    (22, 'Parlamento y política', 'OpenSecrets', 'https://www.opensecrets.org/', 'Ameriketako Estatu Batuak', 'Politika estatubatuarreko diruari jarraitzen dion erakunde independentea: kanpainetarako dohaintzak, lobby-gastua eta hautetsien ondarea.', 'Iturri ofizial sakabanatuak gurutzatzen ditu nork nor finantzatzen duen erantzuteko.', 'Interes-taldeen eta alderdien finantzaketaren erregistro osoagoak eta formatu irekian.', NULL, NULL),
    (23, 'Parlamento y política', 'abgeordnetenwatch.de', 'https://www.abgeordnetenwatch.de/', 'Alemania', 'Edonork bere diputatuei publikoki galdetu eta haien erantzunak, bozketak eta diru-sarrera gehigarriak kontsulta ditzakeen plataforma.', 'Galderak eta erantzunak argitaratuta geratzen dira, eta horrek ordezkari bakoitzak esaten duenaren erregistro iraunkorra sortzen du.', 'Herritarrek beren ordezkariei galderak egiteko bide publikoa.', NULL, NULL),
    -- Contratación y gobierno digital
    (30, 'Contratación y gobierno digital', 'ProZorro', 'https://prozorro.gov.ua/', 'Ukraina', 'Kontratazio publiko elektronikoaren sistema, 2016tik derrigorrezkoa, zeinean lizitazio eta esleipen guztiak datu ireki gisa argitaratzen diren OCDS nazioarteko estandarraren arabera.', 'Gobernuaren, enpresen eta gizarte zibilaren arteko lankidetzatik sortu zen, eta edonork zain ditzake kontratuak, adibidez DOZORRO jarraipen-plataformarekin.', 'Administrazio guztien kontratazio publiko osoa formatu bakar eta ireki batean argitaratzea.', NULL, NULL),
    (31, 'Contratación y gobierno digital', 'Open Contracting Partnership', 'https://www.open-contracting.org/', 'Nazioartekoa', 'Kontratazio publiko irekia bultzatzen duen eta Open Contracting Data Standard (OCDS) mantentzen duen erakundea, mundu osoko gobernuek erabiltzen dutena.', 'Estandar komun batek administrazioen eta herrialdeen arteko kontratuak alderatzeko eta anomaliak detektatzeko aukera ematen du.', 'Administrazio guztien kontratazio-datuetarako estandar komun bat hartzea.', NULL, NULL),
    (32, 'Contratación y gobierno digital', 'X-Road', 'https://x-road.global/', 'Estonia', 'Estoniak 2001etik erabiltzen duen administrazioen arteko datu-trukerako geruza, kode irekikoa eta gaur egun Nordic Institute for Interoperability Solutions (NIIS) erakundeak mantentzen duena.', 'Administrazioek elkarri eskatzen dizkiote datuak modu seguruan, herritarrak ez du dokumentu bera bi aldiz eman behar, eta sarbide bakoitza erregistratuta geratzen da; horri esker, estoniarrek egiazta dezakete zer erakundek kontsultatu dituen haien datuak.', 'Administrazioen arteko benetako elkarreragingarritasuna eta herritar bakoitzaren datuak nork kontsultatzen dituen erakusten duen erregistro ikusgarria.', NULL, NULL),
    (33, 'Contratación y gobierno digital', 'Code for America', 'https://codeforamerica.org/', 'Ameriketako Estatu Batuak', 'Irabazi-asmorik gabeko erakundea, 2009an sortua, administrazioekin lankidetzan aritzen dena haien zerbitzu digitalak errazak izan daitezen, adibidez GetCalFresh-ekin, Kalifornian elikadura-laguntzak eskatzeko.', 'Arrakasta jendeak zerbitzu publikoak zein erraz eskuratzen dituen neurtzen du.', 'Izapideak erabiltzaileekin diseinatzea eta zenbatek osatzen dituzten neurtzea.', NULL, NULL),
    -- Tecnología cívica y gobierno abierto
    (40, 'Tecnología cívica', 'g0v eta vTaiwan', 'https://g0v.tw/', 'Taiwan', 'Teknologia zibikoaren komunitate irekia, 2012an sortua, web eta datu publikoen bertsio argiagoak sortzen dituena. Hortik atera zen vTaiwan, Pol.is tresna erabili zuen lineako kontsulta-prozesua, erregulazio digitalei buruzko adostasunak bilatzeko; haren jarduera irregularragoa izan da azken urteetan.', 'Erakusten du gizarte zibilak Gobernuarekin lankidetzan aritu daitekeela datuak irekitzeko eta politika zehatzei buruz eztabaidatzeko.', 'Administrazioen eta boluntario-komunitateen arteko lankidetza-gune egonkorrak.', NULL, NULL),
    (41, 'Tecnología cívica', 'Open Knowledge Foundation', 'https://okfn.org/', 'Nazioartekoa (Erresuma Batua)', 'Ezagutza irekiaren erakunde aitzindaria, 2004an sortua. CKAN sortu zuen, atari publiko askok erabiltzen duten datu-katalogoen softwarea, eta Open Definition, datu irekia zer den definitzen duena.', 'Munduko datu-atari askoren oinarri tekniko eta kontzeptualak ezarri ditu.', 'Software eta definizio komunak erabiltzea, atari bakoitzean irtenbide jabedun desberdinen ordez.', NULL, NULL),
    (42, 'Tecnología cívica', 'Open Government Partnership', 'https://www.opengovpartnership.org/', 'Nazioartekoa', 'Gobernu irekiaren aldeko gobernuen eta gizarte zibilaren aliantza. Espainiak 2011tik parte hartzen du, administrazioek eta gizarte-erakundeek prestatutako ekintza-planekin.', 'Gardentasun-konpromiso zehatzak finkatzera eta ebaluazio independente baten mende jartzera behartzen du.', 'Konpromiso neurgarriak, modu independentean ebaluatuak.', NULL, NULL),
    (43, 'Tecnología cívica', 'Operação Serenata de Amor', 'https://serenata.ai/', 'Brasil', 'Open Knowledge Brasilen proiektua, 2016an sortua; adimen artifizialeko sistema bat (Rosie) erabiltzen du diputatu federalen gastu-itzulketak berrikusteko eta susmagarriak seinalatzeko. Haren kodea irekia da (MIT lizentzia); gaur egun maiztasun txikiagoz eguneratzen da.', 'Erakutsi zuen boluntario gutxi batzuek, datu irekiekin eta kodearekin, milaka gastu publiko audita ditzaketela.', 'Kargu publikoen ordezkaritza-gastuak auditatu ahal izateko adinako xehetasunarekin argitaratzea.', NULL, NULL),
    -- Verificación
    (50, 'Verificación', 'Full Fact', 'https://fullfact.org/', 'Erresuma Batua', 'Datuak egiaztatzen dituen ongintzako erakunde independentea; egiaztatzea merezi duten baieztapenak detektatzeko adimen artifizialeko tresnak ere garatzen ditu.', 'Egiaztatzeaz gain, akatsa zabaldu zuenari zuzenketak eskatzen dizkio eta estatistikak argitaratzeko moduan hobekuntzak proposatzen ditu.', 'Erakundeek publikoki zuzentzea haien datuak gaizki erabiltzen direnean.', NULL, NULL),
    (51, 'Verificación', 'Chequeado', 'https://chequeado.com/', 'Argentina', 'Irabazi-asmorik gabeko hedabidea, 2010ean sortua, Latinoamerikan datuen egiaztapenean aitzindaria, Chequeabot bezalako tresna propioekin.', 'Egiaztapena, datu-kazetaritza eta hezkuntza konbinatzen ditu, eta metodoak eta tresnak eskualde osoko hedabideekin partekatzen ditu.', 'Egiaztatzaileen arteko lankidetza eta datu publikoen erabilerari buruzko prestakuntza.', NULL, NULL)
) AS t(orden, tipo, nombre, url, pais, que, por_que, leccion, uso, uso_url)
ORDER BY orden
```

# 🌍 Beste herrialdeetako adibide inspiratzaileak

Herrialde askok urteak daramatzate beren datu publikoak modu irekian argitaratzen eta haien gainean edonork erabil ditzakeen tresnak eraikitzen: ekonomia ulertzeko, parlamentuen lanari jarraitzeko, diru publikoa zaintzeko edo politikariek esaten dutena egiaztatzeko. Hemen **{ejemplos.length} proiektu** biltzen ditugu, eredu gisa balio dutenak, gobernu, fundazio, hedabide eta boluntario-komunitateenak, bakoitzak zer ekartzen duen eta **Espainiak zer ikas lezakeen** adierazita. SpainFacts, hain zuzen, horietako batetik jaio da, USAFactsetik. Espainiako proiektuetarako, ikus [Datu irekiak Espainian](/eu/varios/datos-abiertos).

<ButtonGroup name=tipo title="Proiektu mota">
    <ButtonGroupItem valueLabel="Guztiak" value="Todos" default />
    <ButtonGroupItem valueLabel="Estatistika eta dibulgazioa" value="Estadística y divulgación" />
    <ButtonGroupItem valueLabel="Datu-atariak" value="Portales de datos" />
    <ButtonGroupItem valueLabel="Parlamentua eta politika" value="Parlamento y política" />
    <ButtonGroupItem valueLabel="Kontratazioa eta gobernu digitala" value="Contratación y gobierno digital" />
    <ButtonGroupItem valueLabel="Teknologia zibikoa" value="Tecnología cívica" />
    <ButtonGroupItem valueLabel="Egiaztapena" value="Verificación" />
</ButtonGroup>

```sql ejemplos_sel
SELECT *
FROM ${ejemplos}
WHERE '${inputs.tipo}' = 'Todos' OR tipo = '${inputs.tipo}'
ORDER BY orden
```

<div class="grid grid-cols-1 md:grid-cols-2 gap-4 my-6">
{#each ejemplos_sel as e}
    <div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 shadow-sm flex flex-col gap-2">
        <div class="flex items-start justify-between gap-2">
            <h3 class="text-base font-bold text-gray-900 dark:text-white m-0"><a href={e.url} target="_blank" rel="noopener" class="hover:underline">{e.nombre}</a></h3>
            <span class="shrink-0 rounded-full bg-purple-50 dark:bg-purple-950/40 text-purple-700 dark:text-purple-300 text-xs font-semibold px-2 py-0.5">{e.pais}</span>
        </div>
        <div class="text-xs text-gray-500 dark:text-gray-400">{mota(e.tipo)}</div>
        <p class="text-sm text-gray-700 dark:text-gray-300 m-0">{e.que}</p>
        <p class="text-sm text-gray-700 dark:text-gray-300 m-0"><span class="font-semibold">Zergatik da inspiragarria:</span> {e.por_que}</p>
        <div class="mt-1 rounded-lg bg-purple-50/70 dark:bg-purple-950/30 border border-purple-200 dark:border-purple-800 px-3 py-2 text-xs text-purple-900 dark:text-purple-200">
            <span class="font-semibold">Espainiak zer ikas lezakeen:</span> {e.leccion}
        </div>
        {#if e.uso_url}
            <div class="text-xs text-gray-600 dark:text-gray-400"><span class="font-semibold">SpainFactsen:</span> {e.uso}. <a href={e.uso_url} class="font-semibold text-purple-700 dark:text-purple-400">Ikusi →</a></div>
        {/if}
    </div>
{/each}
</div>

---

## Zer duten komunean

- **Leku bakarra galdera bakoitzerako.** Adibide onenek ez dute behartzen jakitera zer erakundek argitaratzen duen datu bakoitza: bildu eta azaldu egiten dute.
- **Zifra bakoitza bere iturriarekin eta deskargarekin.** Our World in Datak, USAFactsek edo Herbehereetako eta Norvegiako estatistika-bulegoek jatorrizko datura iristeko eta berrerabiltzeko aukera ematen dute.
- **Estandar komunak.** Kontratazioan OCDSk, katalogoetan CKANek edo administrazioen arteko trukean X-Roadek iturri desberdinetako datuak bat etortzea lortzen dute.
- **Lankidetza gizarte zibilarekin.** ProZorrok, g0vek edo mySocietyk erakusten dute datu irekiek etekin handiagoa ematen dutela administrazioak, boluntarioak, hedabideak eta unibertsitateak haien gainean lan egiten dutenean.

## Metodologia eta iturriak

SpainFactsek egindako hautaketa, beste herrialdeetako proiektu ezagun eta finkatuekin; ez da sailkapen bat, ezta errolda osoa ere. Proiektu bakoitzaren deskribapena haren webgunetik dator. Esteka guztiak 2026ko irailean egiaztatu ziren; webgune batzuek (OpenSecrets, Open Government Partnership) egiaztapen automatikoak blokeatzen dituzte, baina haien helbide ofizialak dira. Jarduera gutxitu zaien proiektuek haien deskribapenean adierazten dute. Espainiarako ikasgaiak SpainFactsen iradokizunak dira, ez inongo administrazio zehatzaren ebaluazioak.
