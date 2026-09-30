---
title: Dades obertes a Espanya
description: "Guia dels projectes de dades obertes d'Espanya: portals i organismes públics (INE, BOE, AEMET, REE, Cadastre, Hisenda...), portals autonòmics i municipals, i projectes de la societat civil i del periodisme de dades, amb els que fa servir SpainFacts."
i18n_origen: 0d2b0699582c
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    const tipoCa = { 'Estado': 'Estat', 'Autonómico y local': 'Autonòmic i local', 'Sociedad civil': 'Societat civil', 'Periodismo de datos': 'Periodisme de dades' };
</script>

```sql proyectos
SELECT *
FROM (VALUES
    -- Administración General del Estado
    (1, 'Estado', 'datos.gob.es', 'https://datos.gob.es/', 'Ministeri per a la Transformació Digital i de la Funció Pública (Iniciativa Aporta)', 'Catàleg nacional que reuneix els conjunts de dades obertes de ministeris, comunitats, ajuntaments i universitats, amb guies i casos de reutilització.', 'Catàleg DCAT-AP-ES, API i SPARQL; formats segons l''organisme', 'Segons cada organisme publicador', NULL, NULL),
    (2, 'Estado', 'INE: INEbase i API JSON', 'https://www.ine.es/dyngs/DAB/index.htm?cid=1099', 'Institut Nacional d''Estadística', 'Totes les estadístiques oficials de l''INE (IPC, EPA, padró, PIB, naixements, turisme...) consultables al web i per una API que retorna JSON.', 'API JSON (Tempus3), PC-Axis, CSV, Excel', 'Reutilització lliure citant la font', 'És la font principal: IPC, atur (EPA), població, PIB i més de la meitat de les sèries del lloc.', '/ca/economia/ipc'),
    (3, 'Estado', 'BOE: dades obertes i API', 'https://www.boe.es/datosabiertos/api/api.php', 'Agència Estatal Butlletí Oficial de l''Estat', 'Sumaris diaris del BOE i del BORME i legislació consolidada, accessibles de manera automatitzada.', 'API amb resposta XML o JSON', 'Reutilització lliure citant la font', 'Hi enllacem la normativa que explica les obligacions dels ajuntaments (no és font de dades).', '/ca/transparencia/cuentas-municipales'),
    (4, 'Estado', 'AEMET OpenData', 'https://opendata.aemet.es/', 'Agència Estatal de Meteorologia', 'Observacions, valors climatològics diaris i mensuals, prediccions i avisos de totes les estacions de l''AEMET.', 'API REST en JSON; requereix una clau gratuïta', 'Reutilització citant l''AEMET', 'Temperatures diàries de les estacions de referència per al mapa de la calor.', '/ca/energia-clima/calor'),
    (5, 'Estado', 'REData (Red Eléctrica)', 'https://www.ree.es/es/datos/apidatos', 'Red Eléctrica de España', 'Generació per tecnologia, demanda, intercanvis, emissions i balanç elèctric, estatal i per comunitat.', 'API REST en JSON, sense clau', 'Reutilització citant Red Eléctrica', 'Mix de generació, emissions del sector elèctric i emmagatzematge.', '/ca/energia-clima/mix-electrico'),
    (6, 'Estado', 'ESIOS', 'https://www.esios.ree.es/', 'Red Eléctrica de España (operador del sistema)', 'Sistema d''informació de l''operador del sistema: preus, demanda i generació en temps real, cada pocs minuts.', 'API en JSON amb token gratuït', 'Reutilització citant Red Eléctrica', 'Dades en temps real i rècords del sistema elèctric.', '/ca/energia-clima/records'),
    (7, 'Estado', 'CNMC Data', 'https://data.cnmc.es/', 'Comissió Nacional dels Mercats i la Competència', 'Estadístiques dels mercats que supervisa la CNMC: energia, telecomunicacions, audiovisual, postal i transport.', 'Descàrregues i taulers interactius', 'Consulteu l''avís legal', NULL, NULL),
    (8, 'Estado', 'Seu Electrònica del Cadastre', 'https://www.sedecatastro.gob.es/', 'Direcció General del Cadastre (Ministeri d''Hisenda)', 'Cartografia i dades de tots els immobles d''Espanya (excepte el País Basc i Navarra, amb cadastre propi): parcel·les, edificis, superfícies i usos.', 'Descàrrega massiva INSPIRE (GML), serveis de mapes WMS; els fitxers alfanumèrics requereixen registre', 'Ús lliure citant la font (dades no protegides)', 'De manera indirecta: l''índex de lloguers del Ministeri d''Habitatge creua l''IRPF i el Cadastre.', '/ca/vivienda/alquiler'),
    (9, 'Estado', 'IGN i Centre de Descàrregues del CNIG', 'https://centrodedescargas.cnig.es/', 'Institut Geogràfic Nacional i Centre Nacional d''Informació Geogràfica', 'Mapes topogràfics, ortofotos (PNOA), models del terreny, límits administratius i nomenclàtor.', 'Shapefile, GeoPackage, GeoTIFF, LiDAR i serveis web', 'CC BY 4.0', 'Els límits de comunitats i províncies dels mapes.', '/ca/energia-clima/calor'),
    (10, 'Estado', 'Plataforma de Contractació del Sector Públic', 'https://contrataciondelestado.es/', 'Ministeri d''Hisenda', 'Licitacions, adjudicacions i contractes de l''Administració General de l''Estat i de moltes altres administracions.', 'Dades obertes sindicades (ATOM amb XML CODICE)', 'Reutilització lliure citant la font', NULL, NULL),
    (11, 'Estado', 'Base de Dades Nacional de Subvencions (BDNS)', 'https://www.infosubvenciones.es/', 'Intervenció General de l''Administració de l''Estat (Ministeri d''Hisenda)', 'Convocatòries i concessions de subvencions i ajuts públics de totes les administracions, amb beneficiari i import.', 'Cercador web amb exportació de resultats', 'Consulteu l''avís legal', NULL, NULL),
    (12, 'Estado', 'Portal de la Transparència', 'https://transparencia.gob.es/', 'Administració General de l''Estat (Ministeri per a la Transformació Digital i de la Funció Pública)', 'Publicitat activa de l''Administració General de l''Estat (organització, alts càrrecs, contractes, convenis, pressupostos) i el canal per exercir el dret d''accés a la informació.', 'Pàgines web i descàrregues', 'Llei 19/2013 de transparència', NULL, NULL),
    (13, 'Estado', 'Banc d''Espanya: estadístiques', 'https://www.bde.es/wbe/es/estadisticas/', 'Banc d''Espanya', 'Butlletí Estadístic amb sèries de tipus d''interès, crèdit, balança de pagaments i deute de les administracions públiques.', 'Sèries descarregables en CSV i Excel', 'Reutilització citant la font', 'Deute de les administracions públiques i dels ajuntaments.', '/ca/territorios/municipios'),
    (14, 'Estado', 'SEPE: dades obertes', 'https://sede.sepe.gob.es/portalSede/datos-abiertos.html', 'Servei Públic d''Ocupació Estatal', 'Atur registrat, contractes i prestacions per desocupació, amb detall mensual per municipi.', 'CSV i Excel', 'Reutilització citant la font', 'Atur registrat per municipi i província.', '/ca/economia/paro'),
    (15, 'Estado', 'DGT en xifres', 'https://www.dgt.es/menusecundario/dgt-en-cifras/', 'Direcció General de Trànsit', 'Microdades de matriculacions, baixes, transferències i parc de vehicles, a més d''estadístiques de sinistralitat i conductors.', 'Fitxers de text d''amplada fixa (MATRABA) i taules', 'Reutilització citant la font', 'Matriculacions, cotxe elèctric i parc de vehicles.', '/ca/movilidad/parque'),
    (16, 'Estado', 'Punt d''Accés Nacional de trànsit i mobilitat (NAP)', 'https://nap.dgt.es/', 'DGT i Ministeri de Transports', 'Dades de trànsit, incidències, punts de recàrrega elèctrica i altres serveis de mobilitat, segons la normativa europea de transport intel·ligent.', 'DATEX II, JSON i CSV', 'Segons cada conjunt', 'Punts de recàrrega per a cotxes elèctrics.', '/ca/movilidad/recarga'),
    (17, 'Estado', 'MITECO', 'https://www.miteco.gob.es/', 'Ministeri per a la Transició Ecològica i el Repte Demogràfic', 'Butlletí hidrològic d''embassaments, inventari d''emissions de gasos d''efecte d''hivernacle, qualitat de l''aire, cartografia ambiental i energia.', 'Excel, CSV, Access i serveis cartogràfics', 'Reutilització citant la font', 'Reserva dels embassaments i emissions de gasos d''efecte d''hivernacle.', '/ca/energia-clima/embalses'),
    (18, 'Estado', 'Hisenda: CONPREL (pressupostos i liquidacions locals)', 'https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL', 'Secretaria General de Finançament Autonòmic i Local (Ministeri d''Hisenda)', 'Pressupostos i liquidacions de tots els ajuntaments, diputacions i comunitats, per capítol i per política de despesa.', 'Consulta web i descàrrega en Access o Excel', 'Reutilització citant la font', 'Despesa i ingressos per habitant de cada municipi i qui no envia els seus comptes.', '/ca/transparencia/cuentas-municipales'),
    (19, 'Estado', 'Plataforma de Retiment de Comptes', 'https://www.rendiciondecuentas.es/', 'Tribunal de Comptes i òrgans de control extern autonòmics', 'Estat de retiment del Compte General de cada entitat local i consulta dels comptes presentats.', 'Consulta web', 'Consulteu l''avís legal', 'Quins ajuntaments presenten a temps el seu Compte General.', '/ca/transparencia/cuentas-municipales'),
    (20, 'Estado', 'Infoelectoral', 'https://infoelectoral.interior.gob.es/', 'Ministeri de l''Interior', 'Resultats oficials de les eleccions generals (des de 1977), municipals (des de 1979) i europees (des de 1987), per mesa, municipi i província.', 'Fitxers de text i Excel a l''àrea de descàrregues', 'Reutilització citant la font', 'Resultats de les eleccions generals, municipals i europees.', '/ca/sociedad/elecciones'),
    -- Comunidades autónomas y ayuntamientos
    (30, 'Autonómico y local', 'Open Data Euskadi', 'https://opendata.euskadi.eus/', 'Govern Basc', 'Un dels portals de dades obertes pioners a Espanya (2010): pressupostos, medi ambient, transport, cultura, qualitat de l''aire i més.', 'CSV, JSON, XML i API', 'Reutilització citant la font', NULL, NULL),
    (31, 'Autonómico y local', 'Dades obertes de Castella i Lleó', 'https://datosabiertos.jcyl.es/', 'Junta de Castella i Lleó', 'Catàleg autonòmic amb dades de sanitat, educació, medi ambient, ocupació i registres administratius.', 'CSV, JSON i API', 'Segons cada conjunt', NULL, NULL),
    (32, 'Autonómico y local', 'Aragón Open Data', 'https://opendata.aragon.es/', 'Govern d''Aragó', 'Portal autonòmic amb catàleg de dades, dades enllaçades (Aragopedia) i anàlisi de la comunitat i dels seus municipis.', 'CSV, JSON, API i SPARQL', 'Segons cada conjunt', NULL, NULL),
    (33, 'Autonómico y local', 'Dades obertes de la Junta d''Andalusia', 'https://www.juntadeandalucia.es/datosabiertos/portal.html', 'Junta d''Andalusia', 'Catàleg de dades de l''administració andalusa: estadística, salut, ocupació, medi ambient i serveis.', 'CSV, JSON, XML', 'Segons cada conjunt', NULL, NULL),
    (34, 'Autonómico y local', 'Dades obertes de la Generalitat Valenciana', 'https://dadesobertes.gva.es/', 'Generalitat Valenciana', 'Dades de l''administració valenciana: sanitat, educació, medi ambient, transport i sector públic.', 'CSV, JSON, XML', 'Segons cada conjunt', NULL, NULL),
    (35, 'Autonómico y local', 'Dades obertes de Catalunya', 'https://analisi.transparenciacatalunya.cat/', 'Generalitat de Catalunya', 'Portal de dades obertes i transparència de la Generalitat, amb visualitzacions i consulta directa de cada conjunt.', 'CSV, JSON i API (Socrata)', 'Segons cada conjunt', NULL, NULL),
    (36, 'Autonómico y local', 'Dades obertes de la Comunitat de Madrid', 'https://datos.comunidad.madrid/', 'Comunitat de Madrid', 'Catàleg autonòmic amb dades de sanitat, educació, transport, medi ambient i estadística regional.', 'CSV, JSON, XML', 'Segons cada conjunt', NULL, NULL),
    (37, 'Autonómico y local', 'Portal de dades obertes de l''Ajuntament de Madrid', 'https://datos.madrid.es/', 'Ajuntament de Madrid', 'Trànsit en temps real, qualitat de l''aire, padró, pressupostos, contractes, aparcaments, BiciMAD i centenars de conjunts més.', 'CSV, JSON, XML i API', 'Reutilització citant la font', NULL, NULL),
    (38, 'Autonómico y local', 'Open Data BCN', 'https://opendata-ajuntament.barcelona.cat/', 'Ajuntament de Barcelona', 'Dades de població, mobilitat, medi ambient, economia, equipaments i turisme de Barcelona.', 'CSV, JSON i API', 'CC BY 4.0', NULL, NULL),
    -- Sociedad civil
    (50, 'Sociedad civil', 'Civio', 'https://civio.es/', 'Fundación Ciudadana Civio', 'Fundació independent que vigila els poders públics amb periodisme de dades i eines pròpies; publica el seu codi a GitHub.', 'Cercadors i dades descarregables en alguns projectes', 'Varia segons el projecte', NULL, NULL),
    (51, 'Sociedad civil', 'El BOE nuestro de cada día (Civio)', 'https://civio.es/el-boe-nuestro-de-cada-dia/', 'Fundación Ciudadana Civio', 'Explica cada dia, en llenguatge clar, el més rellevant que publica el Butlletí Oficial de l''Estat; inclou el Decretómetro, que compta els decrets llei.', 'Articles i visualitzacions', 'Continguts de Civio', NULL, NULL),
    (52, 'Sociedad civil', '¿Dónde van mis impuestos? (Civio)', 'https://dondevanmisimpuestos.es/', 'Fundación Ciudadana Civio', 'Pressupostos de l''Estat, de les comunitats i dels ajuntaments explicats per política de despesa, amb la seva evolució.', 'Visualitzacions interactives i descàrregues', 'Continguts de Civio', NULL, NULL),
    (53, 'Sociedad civil', 'El Indultómetro (Civio)', 'https://civio.es/justicia/buscador-de-indultos/', 'Fundación Ciudadana Civio', 'Cercador dels indults concedits a Espanya a partir dels reials decrets publicats al BOE.', 'Cercador web', 'Continguts de Civio', NULL, NULL),
    (54, 'Sociedad civil', 'Medicamentalia (Civio)', 'https://medicamentalia.org/', 'Fundación Ciudadana Civio', 'Investigació internacional sobre l''accés a medicaments, vacunes i anticonceptius al món. Sense actualitzar des de 2018.', 'Visualitzacions i dades del projecte', 'Continguts de Civio', NULL, NULL),
    (55, 'Sociedad civil', 'Access Info Europe', 'https://www.access-info.org/', 'Organització amb seu a Madrid', 'Defensa i promou el dret d''accés a la informació pública a Espanya i a Europa, amb litigis, guies i seguiment de la llei de transparència.', 'Informes i guies', 'Continguts propis', NULL, NULL),
    (56, 'Sociedad civil', 'Transparencia Internacional España', 'https://transparencia.org.es/', 'Capítol espanyol de Transparency International', 'Publica a Espanya l''Índex de Percepció de la Corrupció i avaluacions de transparència d''institucions i empreses.', 'Informes i índexs', 'Continguts propis', NULL, NULL),
    (57, 'Sociedad civil', 'Fundación Hay Derecho', 'https://www.hayderecho.com/', 'Fundación Hay Derecho', 'Estudis sobre l''estat de dret i la qualitat institucional, com el Dedómetro, que analitza els nomenaments al sector públic.', 'Informes', 'Continguts propis', NULL, NULL),
    (58, 'Sociedad civil', 'Qué hacen los diputados', 'https://quehacenlosdiputados.es/', 'Political Watch', 'Segueix totes les iniciatives del Congrés dels Diputats i les classifica per temes i per grup parlamentari.', 'Web, API i codi obert', 'Consulteu el web', NULL, NULL),
    (59, 'Sociedad civil', 'ObservatoriosPublicos.es', 'https://observatoriospublicos.es/', 'Jaime Gómez-Obregón (iniciativa personal)', 'Cens dels observatoris públics i publicoprivats d''Espanya, amb la seva administració, any de creació i estat; admet correccions de la comunitat.', 'Web i codi obert a GitHub', 'Consulteu el web', 'És la base de la nostra anàlisi dels observatoris públics.', '/ca/varios/observatorios'),
    -- Periodismo de datos y verificación
    (70, 'Periodismo de datos', 'Maldita.es i Maldito Dato', 'https://maldita.es/malditodato/', 'Fundación Maldita.es', 'Verificació de dades i falsedats; la secció Maldito Dato explica amb xifres oficials l''actualitat política i econòmica.', 'Articles i gràfics', 'Continguts propis', NULL, NULL),
    (71, 'Periodismo de datos', 'Newtral', 'https://www.newtral.es/', 'Newtral Media Audiovisual', 'Mitjà de verificació i periodisme de dades que comprova declaracions públiques i explica les dades que hi ha darrere l''actualitat.', 'Articles i gràfics', 'Continguts propis', NULL, NULL),
    (72, 'Periodismo de datos', 'Datadista', 'https://www.datadista.com/', 'Mitjà independent de periodisme de dades', 'Investigacions de llarg recorregut amb dades (habitatge, sanitat, energia...); durant la pandèmia va publicar a GitHub sèries de dades de COVID-19 per comunitats autònomes.', 'Articles i dades a GitHub', 'Consulteu cada repositori', NULL, NULL),
    (73, 'Periodismo de datos', 'EpData', 'https://www.epdata.es/', 'Europa Press', 'Portal de dades d''Europa Press: gràfics d''estadístiques públiques, a punt per consultar i inserir en altres webs.', 'Gràfics i taules inseribles', 'Condicions d''Europa Press', NULL, NULL),
    (60, 'Sociedad civil', 'Montera34', 'https://montera34.com/', 'Pablo Rey Mazón i Alfonso Sánchez Uzábal', 'Projectes de dades com a bé comú fets amb programari lliure: visualització i anàlisi de dades urbanes, segregació escolar, lloguer turístic i obertura de bases de dades municipals.', 'Visualitzacions i codi obert', 'Consulteu cada projecte', NULL, NULL)
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

# 🔓 Dades obertes a Espanya

Les **dades obertes** són informació pública que qualsevol pot descarregar, reutilitzar i redistribuir sense demanar permís, en formats que un programa pot llegir. Importen perquè permeten comprovar el que diuen governs, partits i empreses, perquè la ciutadania i els mitjans poden fer les seves pròpies anàlisis en lloc de dependre de resums aliens, i perquè sobre aquestes dades es construeixen serveis útils, recerca i empreses. SpainFacts existeix gràcies a elles: totes les nostres xifres surten de fonts públiques que qualsevol pot consultar.

Aquesta pàgina reuneix **{resumen[0].total} projectes**: {resumen[0].estado} de l'Administració General de l'Estat, {resumen[0].autonomico} portals autonòmics i municipals i {resumen[0].civil} iniciatives de la societat civil i del periodisme de dades. En **{resumen[0].usados}** d'aquests t'enllacem la pàgina de SpainFacts on els fem servir.

<ButtonGroup name=tipo title="Tipus de projecte">
    <ButtonGroupItem valueLabel="Tots" value="Todos" default />
    <ButtonGroupItem valueLabel="Estat" value="Estado" />
    <ButtonGroupItem valueLabel="Comunitats i ajuntaments" value="Autonómico y local" />
    <ButtonGroupItem valueLabel="Societat civil" value="Sociedad civil" />
    <ButtonGroupItem valueLabel="Periodisme de dades" value="Periodismo de datos" />
    <ButtonGroupItem valueLabel="Els que fa servir SpainFacts" value="Usados" />
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
            <span class="shrink-0 rounded-full bg-purple-50 dark:bg-purple-950/40 text-purple-700 dark:text-purple-300 text-xs font-semibold px-2 py-0.5">{tipoCa[p.tipo] ?? p.tipo}</span>
        </div>
        <div class="text-xs text-gray-500 dark:text-gray-400">{p.quien}</div>
        <p class="text-sm text-gray-700 dark:text-gray-300 m-0">{p.que}</p>
        <div class="text-xs text-gray-600 dark:text-gray-400"><span class="font-semibold">Format:</span> {p.formato} · <span class="font-semibold">Llicència:</span> {p.licencia}</div>
        {#if p.uso_url}
            <div class="mt-1 rounded-lg bg-purple-50/70 dark:bg-purple-950/30 border border-purple-200 dark:border-purple-800 px-3 py-2 text-xs text-purple-900 dark:text-purple-200">
                <span class="font-semibold">A SpainFacts:</span> {p.uso} <a href={p.uso_url} class="font-semibold text-purple-700 dark:text-purple-400">Mostra la pàgina →</a>
            </div>
        {/if}
    </div>
{/each}
</div>

---

## Com llegir aquesta guia

- **Format** indica com s'obtenen les dades: una **API** permet demanar-les automàticament des d'un programa; els fitxers **CSV**, **JSON** o **XML** es poden obrir i processar directament; un **cercador web** només permet consultes manuals.
- **Llicència** resumeix les condicions de reutilització. A Espanya, la informació del sector públic és reutilitzable per norma general (Llei 37/2007 i Reial decret 1495/2011), amb l'obligació de citar la font i no desvirtuar les dades; cada portal detalla les seves condicions en l'avís legal. Els projectes de la societat civil i els mitjans tenen les seves pròpies condicions.
- Els projectes de la societat civil i del periodisme de dades s'hi inclouen per la seva tasca d'explicar o vigilar dades públiques, sense que això suposi avalar-ne les conclusions.

## Metodologia i fonts

Selecció elaborada per SpainFacts amb els principals portals públics de dades i les iniciatives ciutadanes més conegudes; no pretén ser un cens complet. Tots els enllaços es van comprovar el setembre de 2026. Els projectes que ja no existeixen s'han retirat i els que continuen en línia però no s'actualitzen s'indiquen en la seva descripció. El catàleg complet de les fonts que fa servir aquest lloc, amb la seva llicència i la seva metodologia, és a [Fonts](/ca/fuentes). Hi trobes a faltar algun projecte? Consulta també els [exemples inspiradors d'altres països](/ca/varios/inspiracion-internacional).
