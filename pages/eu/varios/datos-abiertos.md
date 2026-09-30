---
title: Datu irekiak Espainian
description: "Espainiako datu irekien proiektuen gida: atari eta erakunde publikoak (INE, BOE, AEMET, REE, Katastroa, Ogasuna...), autonomia-erkidegoetako eta udaletako atariak, eta gizarte zibilaren eta datu-kazetaritzaren proiektuak, SpainFactsek erabiltzen dituenekin."
i18n_origen: 0d2b0699582c
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    // Datuetako proiektu-motak (iragazkiaren gakoak) euskaratzen ditu txarteletan
    const MOTA = { 'Estado': 'Estatua', 'Autonómico y local': 'Erkidegoak eta udalak', 'Sociedad civil': 'Gizarte zibila', 'Periodismo de datos': 'Datu-kazetaritza' };
    const mota = (s) => MOTA[s] ?? s;
</script>

```sql proyectos
SELECT *
FROM (VALUES
    -- Administración General del Estado
    (1, 'Estado', 'datos.gob.es', 'https://datos.gob.es/', 'Eraldaketa Digitalerako eta Funtzio Publikoko Ministerioa (Aporta ekimena)', 'Ministerioen, erkidegoen, udalen eta unibertsitateen datu irekien multzoak biltzen dituen katalogo nazionala, gidekin eta berrerabilpen-kasuekin.', 'DCAT-AP-ES katalogoa, APIa eta SPARQL; formatuak erakundearen arabera', 'Argitaratzen duen erakunde bakoitzaren arabera', NULL, NULL),
    (2, 'Estado', 'INE: INEbase eta JSON APIa', 'https://www.ine.es/dyngs/DAB/index.htm?cid=1099', 'Estatistikako Institutu Nazionala', 'INEren estatistika ofizial guztiak (KPIa, BJA, errolda, BPG, jaiotzak, turismoa...), webean eta JSON itzultzen duen API baten bidez kontsulta daitezkeenak.', 'JSON APIa (Tempus3), PC-Axis, CSV, Excel', 'Berrerabilpen librea, iturria aipatuta', 'Iturri nagusia da: KPIa, langabezia (BJA), biztanleria, BPG eta webguneko serieen erdia baino gehiago.', '/eu/economia/ipc'),
    (3, 'Estado', 'BOE: datu irekiak eta APIa', 'https://www.boe.es/datosabiertos/api/api.php', 'Estatuko Aldizkari Ofizialaren Estatu Agentzia', 'BOEren eta BORMEren eguneroko sumarioak eta legeria bateratua, modu automatizatuan eskuragarri.', 'XML edo JSON erantzuna duen APIa', 'Berrerabilpen librea, iturria aipatuta', 'Udalen betebeharrak azaltzen dituen araudia estekatzen dugu (ez da datu-iturria).', '/eu/transparencia/cuentas-municipales'),
    (4, 'Estado', 'AEMET OpenData', 'https://opendata.aemet.es/', 'Meteorologiako Estatu Agentzia', 'AEMETen estazio guztien behaketak, eguneko eta hileko balio klimatologikoak, iragarpenak eta abisuak.', 'REST APIa JSONen; doako gako bat behar da', 'Berrerabilpena, AEMET aipatuta', 'Erreferentziazko estazioen eguneroko tenperaturak, beroaren maparako.', '/eu/energia-clima/calor'),
    (5, 'Estado', 'REData (Red Eléctrica)', 'https://www.ree.es/es/datos/apidatos', 'Red Eléctrica de España', 'Sorkuntza teknologiaka, eskaria, trukeak, isuriak eta balantze elektrikoa, estatu mailan eta erkidegoka.', 'REST APIa JSONen, gakorik gabe', 'Berrerabilpena, Red Eléctrica aipatuta', 'Sorkuntza-nahasketa, sektore elektrikoaren isuriak eta biltegiratzea.', '/eu/energia-clima/mix-electrico'),
    (6, 'Estado', 'ESIOS', 'https://www.esios.ree.es/', 'Red Eléctrica de España (sistemaren operadorea)', 'Sistemaren operadorearen informazio-sistema: prezioak, eskaria eta sorkuntza denbora errealean, minutu gutxiro.', 'APIa JSONen, doako tokenarekin', 'Berrerabilpena, Red Eléctrica aipatuta', 'Sistema elektrikoaren denbora errealeko datuak eta errekorrak.', '/eu/energia-clima/records'),
    (7, 'Estado', 'CNMC Data', 'https://data.cnmc.es/', 'Merkatuen eta Lehiaren Batzorde Nazionala', 'CNMCk gainbegiratzen dituen merkatuen estatistikak: energia, telekomunikazioak, ikus-entzunezkoak, posta eta garraioa.', 'Deskargak eta panel interaktiboak', 'Ikus lege-oharra', NULL, NULL),
    (8, 'Estado', 'Katastroaren Egoitza Elektronikoa', 'https://www.sedecatastro.gob.es/', 'Katastroaren Zuzendaritza Nagusia (Ogasun Ministerioa)', 'Espainiako higiezin guztien kartografia eta datuak (Euskadi eta Nafarroa izan ezik, katastro propioa baitute): lursailak, eraikinak, azalerak eta erabilerak.', 'INSPIRE deskarga masiboa (GML), WMS mapa-zerbitzuak; fitxategi alfanumerikoek erregistroa eskatzen dute', 'Erabilera librea, iturria aipatuta (babestu gabeko datuak)', 'Zeharka: Etxebizitza Ministerioaren alokairu-indizeak PFEZa eta Katastroa gurutzatzen ditu.', '/eu/vivienda/alquiler'),
    (9, 'Estado', 'IGN eta CNIGren Deskarga Zentroa', 'https://centrodedescargas.cnig.es/', 'Institutu Geografiko Nazionala eta Informazio Geografikoko Zentro Nazionala', 'Mapa topografikoak, ortoargazkiak (PNOA), lursail-ereduak, muga administratiboak eta izendegia.', 'Shapefile, GeoPackage, GeoTIFF, LiDAR eta web-zerbitzuak', 'CC BY 4.0', 'Mapetako erkidegoen eta probintzien mugak.', '/eu/energia-clima/calor'),
    (10, 'Estado', 'Sektore Publikoko Kontratazio Plataforma', 'https://contrataciondelestado.es/', 'Ogasun Ministerioa', 'Estatuko Administrazio Orokorraren eta beste administrazio askoren lizitazioak, esleipenak eta kontratuak.', 'Datu ireki sindikatuak (ATOM, CODICE XMLarekin)', 'Berrerabilpen librea, iturria aipatuta', NULL, NULL),
    (11, 'Estado', 'Diru-laguntzen Datu-base Nazionala (BDNS)', 'https://www.infosubvenciones.es/', 'Estatuko Administrazioaren Kontu-hartzailetza Nagusia (Ogasun Ministerioa)', 'Administrazio guztien diru-laguntza eta laguntza publikoen deialdiak eta emakidak, onuradunarekin eta zenbatekoarekin.', 'Web-bilatzailea, emaitzak esportatzeko aukerarekin', 'Ikus lege-oharra', NULL, NULL),
    (12, 'Estado', 'Gardentasun Ataria', 'https://transparencia.gob.es/', 'Estatuko Administrazio Orokorra (Eraldaketa Digitalerako eta Funtzio Publikoko Ministerioa)', 'Estatuko Administrazio Orokorraren publizitate aktiboa (antolaketa, goi-karguak, kontratuak, hitzarmenak, aurrekontuak) eta informazioa eskuratzeko eskubidea baliatzeko bidea.', 'Web-orriak eta deskargak', 'Gardentasunari buruzko 19/2013 Legea', NULL, NULL),
    (13, 'Estado', 'Espainiako Bankua: estatistikak', 'https://www.bde.es/wbe/es/estadisticas/', 'Espainiako Bankua', 'Buletin Estatistikoa, interes-tasen, kredituaren, ordainketa-balantzaren eta administrazio publikoen zorraren serieekin.', 'CSV eta Excel formatuan deskarga daitezkeen serieak', 'Berrerabilpena, iturria aipatuta', 'Administrazio publikoen eta udalen zorra.', '/eu/territorios/municipios'),
    (14, 'Estado', 'SEPE: datu irekiak', 'https://sede.sepe.gob.es/portalSede/datos-abiertos.html', 'Estatuko Enplegu Zerbitzu Publikoa', 'Erregistratutako langabezia, kontratuak eta langabezia-prestazioak, hileko xehetasunarekin udalerrika.', 'CSV eta Excel', 'Berrerabilpena, iturria aipatuta', 'Erregistratutako langabezia udalerrika eta probintziaka.', '/eu/economia/paro'),
    (15, 'Estado', 'DGT en cifras', 'https://www.dgt.es/menusecundario/dgt-en-cifras/', 'Trafikoko Zuzendaritza Nagusia', 'Matrikulazioen, bajen, transferentzien eta ibilgailu-parkearen mikrodatuak, baita istripuei eta gidariei buruzko estatistikak ere.', 'Zabalera finkoko testu-fitxategiak (MATRABA) eta taulak', 'Berrerabilpena, iturria aipatuta', 'Matrikulazioak, auto elektrikoa eta ibilgailu-parkea.', '/eu/movilidad/parque'),
    (16, 'Estado', 'Trafikoaren eta mugikortasunaren Sarbide Puntu Nazionala (NAP)', 'https://nap.dgt.es/', 'DGT eta Garraio Ministerioa', 'Trafikoari, gorabeherei, karga elektrikoko puntuei eta mugikortasuneko beste zerbitzu batzuei buruzko datuak, garraio adimendunari buruzko Europako araudiaren arabera.', 'DATEX II, JSON eta CSV', 'Multzo bakoitzaren arabera', 'Auto elektrikoak kargatzeko puntuak.', '/eu/movilidad/recarga'),
    (17, 'Estado', 'MITECO', 'https://www.miteco.gob.es/', 'Trantsizio Ekologikorako eta Erronka Demografikorako Ministerioa', 'Urtegien buletin hidrologikoa, berotegi-efektuko gasen isurien inbentarioa, airearen kalitatea, ingurumen-kartografia eta energia.', 'Excel, CSV, Access eta zerbitzu kartografikoak', 'Berrerabilpena, iturria aipatuta', 'Urtegien erreserba eta berotegi-efektuko gasen isuriak.', '/eu/energia-clima/embalses'),
    (18, 'Estado', 'Ogasuna: CONPREL (toki-aurrekontuak eta likidazioak)', 'https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL', 'Autonomia eta Toki Finantzaketako Idazkaritza Nagusia (Ogasun Ministerioa)', 'Udal, foru aldundi eta erkidego guztien aurrekontuak eta likidazioak, kapituluka eta gastu-politikaka.', 'Web-kontsulta eta deskarga Access edo Excel formatuan', 'Berrerabilpena, iturria aipatuta', 'Udalerri bakoitzeko biztanleko gastua eta diru-sarrerak, eta nork ez dituen bere kontuak bidaltzen.', '/eu/transparencia/cuentas-municipales'),
    (19, 'Estado', 'Kontu-emateko Plataforma', 'https://www.rendiciondecuentas.es/', 'Kontuen Auzitegia eta autonomia-erkidegoetako kanpo-kontroleko organoak', 'Toki-erakunde bakoitzaren Kontu Orokorraren emate-egoera eta aurkeztutako kontuen kontsulta.', 'Web-kontsulta', 'Ikus lege-oharra', 'Zein udalek aurkezten duten garaiz beren Kontu Orokorra.', '/eu/transparencia/cuentas-municipales'),
    (20, 'Estado', 'Infoelectoral', 'https://infoelectoral.interior.gob.es/', 'Barne Ministerioa', 'Hauteskunde orokorren (1977tik), udal-hauteskundeen (1979tik) eta Europako hauteskundeen (1987tik) emaitza ofizialak, mahaika, udalerrika eta probintziaka.', 'Testu-fitxategiak eta Excel, deskargen atalean', 'Berrerabilpena, iturria aipatuta', 'Hauteskunde orokorren, udal-hauteskundeen eta Europako hauteskundeen emaitzak.', '/eu/sociedad/elecciones'),
    -- Comunidades autónomas y ayuntamientos
    (30, 'Autonómico y local', 'Open Data Euskadi', 'https://opendata.euskadi.eus/', 'Eusko Jaurlaritza', 'Espainiako datu irekien atari aitzindarietako bat (2010): aurrekontuak, ingurumena, garraioa, kultura, airearen kalitatea eta gehiago.', 'CSV, JSON, XML eta APIa', 'Berrerabilpena, iturria aipatuta', NULL, NULL),
    (31, 'Autonómico y local', 'Datos abiertos de Castilla y León', 'https://datosabiertos.jcyl.es/', 'Gaztela eta Leongo Juntak', 'Osasunari, hezkuntzari, ingurumenari, enpleguari eta erregistro administratiboei buruzko datuak dituen autonomia-katalogoa.', 'CSV, JSON eta APIa', 'Multzo bakoitzaren arabera', NULL, NULL),
    (32, 'Autonómico y local', 'Aragón Open Data', 'https://opendata.aragon.es/', 'Aragoiko Gobernua', 'Autonomia-ataria, datu-katalogoarekin, datu estekatuekin (Aragopedia) eta erkidegoaren eta haren udalerrien analisiekin.', 'CSV, JSON, APIa eta SPARQL', 'Multzo bakoitzaren arabera', NULL, NULL),
    (33, 'Autonómico y local', 'Datos abiertos de la Junta de Andalucía', 'https://www.juntadeandalucia.es/datosabiertos/portal.html', 'Andaluziako Junta', 'Andaluziako administrazioaren datu-katalogoa: estatistika, osasuna, enplegua, ingurumena eta zerbitzuak.', 'CSV, JSON, XML', 'Multzo bakoitzaren arabera', NULL, NULL),
    (34, 'Autonómico y local', 'Dades obertes de la Generalitat Valenciana', 'https://dadesobertes.gva.es/', 'Generalitat Valenciana', 'Valentziako administrazioaren datuak: osasuna, hezkuntza, ingurumena, garraioa eta sektore publikoa.', 'CSV, JSON, XML', 'Multzo bakoitzaren arabera', NULL, NULL),
    (35, 'Autonómico y local', 'Dades obertes de Catalunya', 'https://analisi.transparenciacatalunya.cat/', 'Generalitat de Catalunya', 'Generalitatearen datu irekien eta gardentasunaren ataria, bistaratzeekin eta multzo bakoitzaren zuzeneko kontsultarekin.', 'CSV, JSON eta APIa (Socrata)', 'Multzo bakoitzaren arabera', NULL, NULL),
    (36, 'Autonómico y local', 'Datos abiertos de la Comunidad de Madrid', 'https://datos.comunidad.madrid/', 'Madrilgo Erkidegoa', 'Osasunari, hezkuntzari, garraioari, ingurumenari eta eskualdeko estatistikari buruzko datuak dituen autonomia-katalogoa.', 'CSV, JSON, XML', 'Multzo bakoitzaren arabera', NULL, NULL),
    (37, 'Autonómico y local', 'Portal de datos abiertos del Ayuntamiento de Madrid', 'https://datos.madrid.es/', 'Madrilgo Udala', 'Trafikoa denbora errealean, airearen kalitatea, errolda, aurrekontuak, kontratuak, aparkalekuak, BiciMAD eta beste ehunka multzo.', 'CSV, JSON, XML eta APIa', 'Berrerabilpena, iturria aipatuta', NULL, NULL),
    (38, 'Autonómico y local', 'Open Data BCN', 'https://opendata-ajuntament.barcelona.cat/', 'Bartzelonako Udala', 'Bartzelonako biztanleriari, mugikortasunari, ingurumenari, ekonomiari, ekipamenduei eta turismoari buruzko datuak.', 'CSV, JSON eta APIa', 'CC BY 4.0', NULL, NULL),
    -- Sociedad civil
    (50, 'Sociedad civil', 'Civio', 'https://civio.es/', 'Fundación Ciudadana Civio', 'Botere publikoak datu-kazetaritzarekin eta tresna propioekin zaintzen dituen fundazio independentea; bere kodea GitHuben argitaratzen du.', 'Bilatzaileak eta, proiektu batzuetan, datu deskargagarriak', 'Proiektuaren arabera', NULL, NULL),
    (51, 'Sociedad civil', 'El BOE nuestro de cada día (Civio)', 'https://civio.es/el-boe-nuestro-de-cada-dia/', 'Fundación Ciudadana Civio', 'Estatuko Aldizkari Ofizialak argitaratzen duen garrantzitsuena azaltzen du egunero, hizkera argian; Decretómetro barne hartzen du, lege-dekretuak zenbatzen dituena.', 'Artikuluak eta bistaratzeak', 'Civioren edukiak', NULL, NULL),
    (52, 'Sociedad civil', '¿Dónde van mis impuestos? (Civio)', 'https://dondevanmisimpuestos.es/', 'Fundación Ciudadana Civio', 'Estatuaren, erkidegoen eta udalen aurrekontuak gastu-politikaka azalduta, haien bilakaerarekin.', 'Bistaratze interaktiboak eta deskargak', 'Civioren edukiak', NULL, NULL),
    (53, 'Sociedad civil', 'El Indultómetro (Civio)', 'https://civio.es/justicia/buscador-de-indultos/', 'Fundación Ciudadana Civio', 'Espainian emandako indultuen bilatzailea, BOEn argitaratutako errege-dekretuetan oinarritua.', 'Web-bilatzailea', 'Civioren edukiak', NULL, NULL),
    (54, 'Sociedad civil', 'Medicamentalia (Civio)', 'https://medicamentalia.org/', 'Fundación Ciudadana Civio', 'Munduan sendagaiak, txertoak eta antisorgailuak eskuratzeari buruzko nazioarteko ikerketa. 2018tik eguneratu gabe.', 'Proiektuaren bistaratzeak eta datuak', 'Civioren edukiak', NULL, NULL),
    (55, 'Sociedad civil', 'Access Info Europe', 'https://www.access-info.org/', 'Madrilen egoitza duen erakundea', 'Informazio publikoa eskuratzeko eskubidea defendatu eta sustatzen du Espainian eta Europan, auzien, giden eta gardentasun-legearen jarraipenaren bidez.', 'Txostenak eta gidak', 'Eduki propioak', NULL, NULL),
    (56, 'Sociedad civil', 'Transparencia Internacional España', 'https://transparencia.org.es/', 'Transparency Internationalen Espainiako kapitulua', 'Ustelkeriaren Pertzepzio Indizea eta erakundeen eta enpresen gardentasun-ebaluazioak argitaratzen ditu Espainian.', 'Txostenak eta indizeak', 'Eduki propioak', NULL, NULL),
    (57, 'Sociedad civil', 'Fundación Hay Derecho', 'https://www.hayderecho.com/', 'Fundación Hay Derecho', 'Zuzenbide-estatuari eta kalitate instituzionalari buruzko azterlanak, hala nola Dedómetro, sektore publikoko izendapenak aztertzen dituena.', 'Txostenak', 'Eduki propioak', NULL, NULL),
    (58, 'Sociedad civil', 'Qué hacen los diputados', 'https://quehacenlosdiputados.es/', 'Political Watch', 'Diputatuen Kongresuko ekimen guztiei jarraitzen die eta gaika eta talde parlamentarioka sailkatzen ditu.', 'Weba, APIa eta kode irekia', 'Ikus weba', NULL, NULL),
    (59, 'Sociedad civil', 'ObservatoriosPublicos.es', 'https://observatoriospublicos.es/', 'Jaime Gómez-Obregón (ekimen pertsonala)', 'Espainiako behatoki publikoen eta publiko-pribatuen erroldak, haien administrazioarekin, sorrera-urtearekin eta egoerarekin; komunitatearen zuzenketak onartzen ditu.', 'Weba eta kode irekia GitHuben', 'Ikus weba', 'Behatoki publikoei buruzko gure analisiaren oinarria da.', '/eu/varios/observatorios'),
    -- Periodismo de datos y verificación
    (70, 'Periodismo de datos', 'Maldita.es eta Maldito Dato', 'https://maldita.es/malditodato/', 'Fundación Maldita.es', 'Datuen eta gezurren egiaztapena; Maldito Dato atalak zifra ofizialekin azaltzen du gaurkotasun politikoa eta ekonomikoa.', 'Artikuluak eta grafikoak', 'Eduki propioak', NULL, NULL),
    (71, 'Periodismo de datos', 'Newtral', 'https://www.newtral.es/', 'Newtral Media Audiovisual', 'Adierazpen publikoak egiaztatzen dituen eta gaurkotasunaren atzeko datuak azaltzen dituen egiaztapen- eta datu-kazetaritzako hedabidea.', 'Artikuluak eta grafikoak', 'Eduki propioak', NULL, NULL),
    (72, 'Periodismo de datos', 'Datadista', 'https://www.datadista.com/', 'Datu-kazetaritzako hedabide independentea', 'Datuekin egindako ibilbide luzeko ikerketak (etxebizitza, osasuna, energia...); pandemian, COVID-19aren datu-serieak argitaratu zituen GitHuben autonomia-erkidegoka.', 'Artikuluak eta datuak GitHuben', 'Ikus biltegi bakoitza', NULL, NULL),
    (73, 'Periodismo de datos', 'EpData', 'https://www.epdata.es/', 'Europa Press', 'Europa Pressen datu-ataria: estatistika publikoen grafikoak, kontsultatzeko eta beste webgune batzuetan txertatzeko prest.', 'Txerta daitezkeen grafikoak eta taulak', 'Europa Pressen baldintzak', NULL, NULL),
    (60, 'Sociedad civil', 'Montera34', 'https://montera34.com/', 'Pablo Rey Mazón eta Alfonso Sánchez Uzábal', 'Ondasun komun gisa ulertutako datu-proiektuak, software librearekin eginak: hiri-datuen bistaratzea eta analisia, eskola-segregazioa, alokairu turistikoa eta udal-datu-baseen irekiera.', 'Bistaratzeak eta kode irekia', 'Ikus proiektu bakoitza', NULL, NULL)
) AS t(orden, tipo, nombre, url, quien, que, formato, licencia, uso, uso_url)
ORDER BY orden
```

```sql resumen
SELECT
    CAST(count(*) AS INTEGER) AS total,
    CAST(count(*) FILTER (WHERE tipo = 'Estado') AS INTEGER) AS estado,
    CAST(count(*) FILTER (WHERE tipo = 'Autonómico y local') AS INTEGER) AS autonomico,
    CAST(count(*) FILTER (WHERE tipo IN ('Sociedad civil', 'Periodismo de datos')) AS INTEGER) AS civil,
    CAST(count(*) FILTER (WHERE uso_url IS NOT NULL) AS INTEGER) AS usados
FROM ${proyectos}
```

# 🔓 Datu irekiak Espainian

**Datu irekiak** edonork baimenik eskatu gabe deskargatu, berrerabili eta birbanatu dezakeen informazio publikoa dira, programa batek irakur ditzakeen formatuetan. Garrantzitsuak dira gobernuek, alderdiek eta enpresek esaten dutena egiaztatzeko aukera ematen dutelako, herritarrek eta hedabideek beren analisiak egin ditzaketelako besteen laburpenen mende egon beharrean, eta haien gainean zerbitzu erabilgarriak, ikerketa eta enpresak eraikitzen direlako. SpainFacts haiei esker dago: gure zifra guztiak edonork kontsulta ditzakeen iturri publikoetatik datoz.

Orri honek **{resumen[0].total} proiektu** biltzen ditu: Estatuko Administrazio Orokorraren {resumen[0].estado}, autonomia-erkidegoetako eta udaletako {resumen[0].autonomico} atari eta gizarte zibilaren eta datu-kazetaritzaren {resumen[0].civil} ekimen. Horietako **{resumen[0].usados}** proiektutan, erabiltzen ditugun SpainFactseko orrirako esteka ematen dizugu.

<ButtonGroup name=tipo title="Proiektu mota">
    <ButtonGroupItem valueLabel="Guztiak" value="Todos" default />
    <ButtonGroupItem valueLabel="Estatua" value="Estado" />
    <ButtonGroupItem valueLabel="Erkidegoak eta udalak" value="Autonómico y local" />
    <ButtonGroupItem valueLabel="Gizarte zibila" value="Sociedad civil" />
    <ButtonGroupItem valueLabel="Datu-kazetaritza" value="Periodismo de datos" />
    <ButtonGroupItem valueLabel="SpainFactsek erabiltzen dituenak" value="Usados" />
</ButtonGroup>

```sql proyectos_sel
SELECT *
FROM ${proyectos}
WHERE '${inputs.tipo}' = 'Todos'
   OR tipo = '${inputs.tipo}'
   OR ('${inputs.tipo}' = 'Usados' AND uso_url IS NOT NULL)
ORDER BY orden
```

<div class="grid grid-cols-1 md:grid-cols-2 gap-4 my-6">
{#each proyectos_sel as p}
    <div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 shadow-sm flex flex-col gap-2">
        <div class="flex items-start justify-between gap-2">
            <h3 class="text-base font-bold text-gray-900 dark:text-white m-0"><a href={p.url} target="_blank" rel="noopener" class="hover:underline">{p.nombre}</a></h3>
            <span class="shrink-0 rounded-full bg-purple-50 dark:bg-purple-950/40 text-purple-700 dark:text-purple-300 text-xs font-semibold px-2 py-0.5">{mota(p.tipo)}</span>
        </div>
        <div class="text-xs text-gray-500 dark:text-gray-400">{p.quien}</div>
        <p class="text-sm text-gray-700 dark:text-gray-300 m-0">{p.que}</p>
        <div class="text-xs text-gray-600 dark:text-gray-400"><span class="font-semibold">Formatua:</span> {p.formato} · <span class="font-semibold">Lizentzia:</span> {p.licencia}</div>
        {#if p.uso_url}
            <div class="mt-1 rounded-lg bg-purple-50/70 dark:bg-purple-950/30 border border-purple-200 dark:border-purple-800 px-3 py-2 text-xs text-purple-900 dark:text-purple-200">
                <span class="font-semibold">SpainFactsen:</span> {p.uso} <a href={p.uso_url} class="font-semibold text-purple-700 dark:text-purple-400">Ikusi orria →</a>
            </div>
        {/if}
    </div>
{/each}
</div>

---

## Nola irakurri gida hau

- **Formatuak** datuak nola lortzen diren adierazten du: **API** batek programa batetik automatikoki eskatzeko aukera ematen du; **CSV**, **JSON** edo **XML** fitxategiak zuzenean ireki eta prozesa daitezke; **web-bilatzaile** batek eskuzko kontsultak baino ez ditu ahalbidetzen.
- **Lizentziak** berrerabiltzeko baldintzak laburtzen ditu. Espainian, sektore publikoaren informazioa berrerabilgarria da oro har (37/2007 Legea eta 1495/2011 Errege Dekretua), iturria aipatzeko eta datuak ez desitxuratzeko betebeharrarekin; atari bakoitzak bere lege-oharrean zehazten ditu baldintzak. Gizarte zibilaren proiektuek eta hedabideek beren baldintzak dituzte.
- Gizarte zibilaren eta datu-kazetaritzaren proiektuak datu publikoak azaltzeko edo zaintzeko egiten duten lanagatik sartzen dira, haien ondorioak babesten ditugula esan gabe.

## Metodologia eta iturriak

SpainFactsek egindako hautaketa, datu-atari publiko nagusiekin eta herritarren ekimen ezagunenekin; ez du errolda osoa izan nahi. Esteka guztiak 2026ko irailean egiaztatu ziren. Jada existitzen ez diren proiektuak kendu egin dira, eta sarean jarraitu arren eguneratzen ez direnak haien deskribapenean adierazten dira. Webgune honek erabiltzen dituen iturrien katalogo osoa, haien lizentzia eta metodologiarekin, [Iturriak](/eu/fuentes) orrian dago. Proiekturen bat faltan botatzen duzu? Ikus, halaber, [beste herrialdeetako adibide inspiratzaileak](/eu/varios/inspiracion-internacional).
