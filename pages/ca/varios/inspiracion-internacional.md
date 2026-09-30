---
title: Exemples inspiradors d'altres països
description: "Projectes de dades obertes i transparència d'altres països que serveixen de model: USAFacts, Our World in Data, Gapminder, TheyWorkForYou, ProZorro, X-Road, g0v, Chequeado i més, amb el que Espanya podria aprendre de cadascun."
i18n_origen: 6594083ed575
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    const tipoCa = { 'Estadística y divulgación': 'Estadística i divulgació', 'Portales de datos': 'Portals de dades', 'Parlamento y política': 'Parlament i política', 'Contratación y gobierno digital': 'Contractació i govern digital', 'Tecnología cívica': 'Tecnologia cívica', 'Verificación': 'Verificació' };
</script>

```sql ejemplos
SELECT *
FROM (VALUES
    -- Estadística y divulgación
    (1, 'Estadística y divulgación', 'USAFacts', 'https://usafacts.org/', 'Estats Units', 'Organització sense ànim de lucre fundada el 2017 per Steve Ballmer que reuneix en un sol lloc les dades oficials sobre població, economia, pressupost i serveis públics dels Estats Units, sense opinió ni afiliació partidista.', 'És la inspiració directa de SpainFacts: demostra que es poden explicar els comptes d''un país amb dades oficials i de manera neutral, per a qualsevol ciutadà.', 'Un punt d''entrada únic i comprensible a les xifres públiques, en lloc de centenars de portals dispersos per organisme.', 'Inspiració directa d''aquest lloc', '/ca'),
    (2, 'Estadística y divulgación', 'Our World in Data', 'https://ourworldindata.org/', 'Regne Unit (Universitat d''Oxford)', 'Publicació de recerca del Global Change Data Lab i la Universitat d''Oxford amb milers de gràfics sobre salut, pobresa, energia, clima o educació a tots els països.', 'Cada gràfic porta la seva font, la seva metodologia i la descàrrega de les dades, i tot el seu contingut i el seu codi són oberts (CC BY).', 'Documentar cada xifra i permetre descarregar-la des del mateix gràfic.', 'SpainFacts fa servir les seves sèries en la comparativa internacional', '/ca/economia/turismo'),
    (3, 'Estadística y divulgación', 'Gapminder', 'https://www.gapminder.org/', 'Suècia', 'Fundació creada per Hans Rosling, Ola Rosling i Anna Rosling Rönnlund per combatre les idees equivocades sobre el món amb estadístiques fàcils d''entendre.', 'Els seus gràfics animats de bombolles i els seus tests de coneixement mostren que fins i tot la gent informada sol equivocar-se sobre l''evolució del món.', 'Mesurar els errors de percepció de la ciutadania i dissenyar la divulgació per corregir-los.', NULL, NULL),
    (4, 'Estadística y divulgación', 'Statistics Netherlands (CBS)', 'https://www.cbs.nl/', 'Països Baixos', 'Oficina estadística neerlandesa. El seu banc de dades StatLine ofereix milers de taules com a dades obertes, amb una API OData.', 'Tota la seva informació estadística es publica com a dades obertes, amb API i sota llicència CC BY 4.0.', 'API estàndard i llicència oberta explícita per a totes les taules estadístiques.', NULL, NULL),
    (5, 'Estadística y divulgación', 'Statistics Norway (SSB)', 'https://www.ssb.no/', 'Noruega', 'Oficina estadística noruega. El seu StatBank dona accés a les sèries oficials, també mitjançant una API oberta i gratuïta.', 'Combina estadístiques molt completes amb una API senzilla i notícies que expliquen cada dada publicada.', 'Acompanyar cada publicació estadística d''una explicació breu i de les dades descarregables.', NULL, NULL),
    (6, 'Estadística y divulgación', 'Stats NZ i data.govt.nz', 'https://www.stats.govt.nz/', 'Nova Zelanda', 'L''oficina estadística neozelandesa i el portal nacional de dades obertes (data.govt.nz). Stats NZ gestiona la Integrated Data Infrastructure, que enllaça de manera anonimitzada dades de diferents administracions per a la recerca.', 'Permet a investigadors acreditats estudiar trajectòries reals (educació, ocupació, salut, prestacions) amb garanties de privadesa.', 'Un entorn segur per investigar amb registres administratius enllaçats, sense exposar dades personals.', NULL, NULL),
    -- Portales de datos
    (10, 'Portales de datos', 'data.gov.sg', 'https://data.gov.sg/', 'Singapur', 'Portal de dades obertes del Govern de Singapur, amb API en temps real (meteorologia, qualitat de l''aire, transport) a més de milers de conjunts de dades.', 'Posa l''accent en API fiables i documentades que els desenvolupadors poden fer servir directament en els seus serveis.', 'Prioritzar dades en temps real amb API estables i documentació clara.', NULL, NULL),
    (11, 'Portales de datos', 'data.europa.eu', 'https://data.europa.eu/', 'Unió Europea', 'Portal oficial de dades de la Unió Europea, que reuneix les dades de les institucions europees i dels portals nacionals, entre els quals datos.gob.es. Publica cada any l''informe Open Data Maturity.', 'Permet comparar el grau d''obertura de cada país europeu amb la mateixa metodologia.', 'Fer servir aquesta comparació anual per fixar objectius concrets d''obertura.', 'SpainFacts fa servir Eurostat, l''oficina estadística de la UE, en moltes comparatives', '/ca/economia/paro'),
    -- Parlamento y política
    (20, 'Parlamento y política', 'TheyWorkForYou i mySociety', 'https://www.theyworkforyou.com/', 'Regne Unit', 'TheyWorkForYou, de l''organització benèfica mySociety, mostra què diu i què vota cada parlamentari britànic. mySociety també va crear WhatDoTheyKnow (sol·licituds d''informació pública fetes en obert) i FixMyStreet (avisos de desperfectes urbans).', 'Converteix els diaris de sessions i les votacions en fitxes per diputat fàcils de seguir, amb API i codi obert reutilitzat en altres països.', 'Publicar les votacions nominals i les intervencions del Congrés i del Senat en formats reutilitzables.', NULL, NULL),
    (21, 'Parlamento y política', 'GovTrack.us', 'https://www.govtrack.us/', 'Estats Units', 'Web independent que segueix des de 2004 les lleis i les votacions del Congrés dels Estats Units.', 'Permet seguir cada projecte de llei, rebre avisos i veure estadístiques d''activitat de cada congressista.', 'Seguiment públic i en temps real de la tramitació de cada llei.', NULL, NULL),
    (22, 'Parlamento y política', 'OpenSecrets', 'https://www.opensecrets.org/', 'Estats Units', 'Organització independent que segueix els diners en la política nord-americana: donacions a campanyes, despesa en lobby i patrimoni dels càrrecs electes.', 'Creua fonts oficials disperses per respondre qui finança qui.', 'Registres de grups d''interès i de finançament de partits més complets i en format obert.', NULL, NULL),
    (23, 'Parlamento y política', 'abgeordnetenwatch.de', 'https://www.abgeordnetenwatch.de/', 'Alemanya', 'Plataforma en què qualsevol pot preguntar públicament als seus diputats i consultar-ne les respostes, les votacions i els ingressos addicionals.', 'Les preguntes i respostes queden publicades, cosa que crea un registre permanent del que diu cada representant.', 'Un canal públic de preguntes de la ciutadania als seus representants.', NULL, NULL),
    -- Contratación y gobierno digital
    (30, 'Contratación y gobierno digital', 'ProZorro', 'https://prozorro.gov.ua/', 'Ucraïna', 'Sistema de contractació pública electrònica, obligatori des de 2016, en què totes les licitacions i adjudicacions es publiquen com a dades obertes segons l''estàndard internacional OCDS.', 'Va néixer de la col·laboració entre Govern, empreses i societat civil, i qualsevol pot vigilar els contractes, per exemple amb la plataforma de seguiment DOZORRO.', 'Publicar tota la contractació pública, de totes les administracions, en un format únic i obert.', NULL, NULL),
    (31, 'Contratación y gobierno digital', 'Open Contracting Partnership', 'https://www.open-contracting.org/', 'Internacional', 'Organització que impulsa la contractació pública oberta i manté l''Open Contracting Data Standard (OCDS), usat per governs de tot el món.', 'Un estàndard comú permet comparar contractes entre administracions i països i detectar anomalies.', 'Adoptar un estàndard comú per a les dades de contractació de totes les administracions.', NULL, NULL),
    (32, 'Contratación y gobierno digital', 'X-Road', 'https://x-road.global/', 'Estònia', 'Capa d''intercanvi de dades entre administracions que Estònia fa servir des de 2001, de codi obert i avui mantinguda pel Nordic Institute for Interoperability Solutions (NIIS).', 'Les administracions es demanen les dades entre si de manera segura, de manera que el ciutadà no ha de lliurar dues vegades el mateix document, i cada accés queda registrat, cosa que permet als estonians comprovar quin organisme ha consultat les seves dades.', 'Interoperabilitat real entre administracions i registre visible de qui consulta les dades de cada ciutadà.', NULL, NULL),
    (33, 'Contratación y gobierno digital', 'Code for America', 'https://codeforamerica.org/', 'Estats Units', 'Organització sense ànim de lucre, fundada el 2009, que col·labora amb administracions perquè els seus serveis digitals siguin senzills, per exemple amb GetCalFresh per sol·licitar ajuts alimentaris a Califòrnia.', 'Mesura l''èxit per com és de fàcil per a la gent accedir als serveis públics.', 'Dissenyar els tràmits amb els usuaris i mesurar quants els completen.', NULL, NULL),
    -- Tecnología cívica y gobierno abierto
    (40, 'Tecnología cívica', 'g0v i vTaiwan', 'https://g0v.tw/', 'Taiwan', 'Comunitat oberta de tecnologia cívica nascuda el 2012, que crea versions més clares de webs i dades públiques. En va sortir vTaiwan, un procés de consulta en línia que va fer servir l''eina Pol.is per buscar consensos sobre regulacions digitals; la seva activitat ha estat més irregular en els últims anys.', 'Demostra que la societat civil pot col·laborar amb el Govern per obrir dades i deliberar sobre polítiques concretes.', 'Espais estables de col·laboració entre administracions i comunitats de voluntaris.', NULL, NULL),
    (41, 'Tecnología cívica', 'Open Knowledge Foundation', 'https://okfn.org/', 'Internacional (Regne Unit)', 'Organització pionera del coneixement obert, fundada el 2004. Va crear CKAN, el programari de catàlegs de dades que fan servir molts portals públics, i l''Open Definition, que defineix què és una dada oberta.', 'Ha posat les bases tècniques i conceptuals de bona part dels portals de dades del món.', 'Fer servir programari i definicions comunes en lloc de solucions propietàries diferents a cada portal.', NULL, NULL),
    (42, 'Tecnología cívica', 'Open Government Partnership', 'https://www.opengovpartnership.org/', 'Internacional', 'Aliança de governs i societat civil pel govern obert. Espanya hi participa des de 2011 amb plans d''acció que elaboren administracions i organitzacions socials.', 'Obliga a fixar compromisos concrets de transparència i a sotmetre''ls a una avaluació independent.', 'Compromisos mesurables i avaluats de manera independent.', NULL, NULL),
    (43, 'Tecnología cívica', 'Operação Serenata de Amor', 'https://serenata.ai/', 'Brasil', 'Projecte d''Open Knowledge Brasil nascut el 2016 que fa servir un sistema d''intel·ligència artificial (Rosie) per revisar els reemborsaments de despeses dels diputats federals i assenyalar els sospitosos. El seu codi és obert (llicència MIT); avui s''actualitza amb menys freqüència.', 'Va mostrar que uns quants voluntaris amb dades obertes i codi poden auditar milers de despeses públiques.', 'Publicar les despeses de representació dels càrrecs públics amb prou detall per poder-les auditar.', NULL, NULL),
    -- Verificación
    (50, 'Verificación', 'Full Fact', 'https://fullfact.org/', 'Regne Unit', 'Organització benèfica independent de verificació de dades, que també desenvolupa eines d''intel·ligència artificial per detectar afirmacions que val la pena verificar.', 'A més de verificar, demana correccions a qui va difondre l''error i proposa millores en com es publiquen les estadístiques.', 'Que els organismes corregeixin públicament quan es fan servir malament les seves dades.', NULL, NULL),
    (51, 'Verificación', 'Chequeado', 'https://chequeado.com/', 'Argentina', 'Mitjà sense ànim de lucre fundat el 2010, pioner de la verificació de dades a l''Amèrica Llatina, amb eines pròpies com Chequeabot.', 'Combina verificació, periodisme de dades i educació, i comparteix mètodes i eines amb mitjans de tota la regió.', 'Col·laboració entre verificadors i formació en l''ús de dades públiques.', NULL, NULL)
) AS t(orden, tipo, nombre, url, pais, que, por_que, leccion, uso, uso_url)
ORDER BY orden
```

# 🌍 Exemples inspiradors d'altres països

Molts països fa anys que publiquen les seves dades públiques de manera oberta i construeixen a partir d'aquestes dades eines que qualsevol pot fer servir: per entendre l'economia, seguir la feina dels parlaments, vigilar els diners públics o comprovar el que diuen els polítics. Aquí reunim **{ejemplos.length} projectes** de governs, fundacions, mitjans i comunitats de voluntaris que serveixen de model, amb el que aporta cadascun i el que **Espanya podria aprendre'n**. SpainFacts neix precisament d'un d'aquests, USAFacts. Per als projectes espanyols, mira [Dades obertes a Espanya](/ca/varios/datos-abiertos).

<ButtonGroup name=tipo title="Tipus de projecte">
    <ButtonGroupItem valueLabel="Tots" value="Todos" default />
    <ButtonGroupItem valueLabel="Estadística i divulgació" value="Estadística y divulgación" />
    <ButtonGroupItem valueLabel="Portals de dades" value="Portales de datos" />
    <ButtonGroupItem valueLabel="Parlament i política" value="Parlamento y política" />
    <ButtonGroupItem valueLabel="Contractació i govern digital" value="Contratación y gobierno digital" />
    <ButtonGroupItem valueLabel="Tecnologia cívica" value="Tecnología cívica" />
    <ButtonGroupItem valueLabel="Verificació" value="Verificación" />
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
        <div class="text-xs text-gray-500 dark:text-gray-400">{tipoCa[e.tipo] ?? e.tipo}</div>
        <p class="text-sm text-gray-700 dark:text-gray-300 m-0">{e.que}</p>
        <p class="text-sm text-gray-700 dark:text-gray-300 m-0"><span class="font-semibold">Per què inspira:</span> {e.por_que}</p>
        <div class="mt-1 rounded-lg bg-purple-50/70 dark:bg-purple-950/30 border border-purple-200 dark:border-purple-800 px-3 py-2 text-xs text-purple-900 dark:text-purple-200">
            <span class="font-semibold">Què podria aprendre Espanya:</span> {e.leccion}
        </div>
        {#if e.uso_url}
            <div class="text-xs text-gray-600 dark:text-gray-400"><span class="font-semibold">A SpainFacts:</span> {e.uso}. <a href={e.uso_url} class="font-semibold text-purple-700 dark:text-purple-400">Mostra →</a></div>
        {/if}
    </div>
{/each}
</div>

---

## El que tenen en comú

- **Un sol lloc per a cada pregunta.** Els millors exemples no obliguen a saber quin organisme publica cada dada: la reuneixen i l'expliquen.
- **Cada xifra amb la seva font i la seva descàrrega.** Our World in Data, USAFacts o les oficines estadístiques dels Països Baixos i Noruega permeten arribar a la dada original i reutilitzar-la.
- **Estàndards comuns.** OCDS en contractació, CKAN en catàlegs o X-Road en l'intercanvi entre administracions fan que les dades de fonts diferents encaixin.
- **Col·laboració amb la societat civil.** ProZorro, g0v o mySociety mostren que les dades obertes rendeixen més quan administracions, voluntaris, mitjans i universitats hi treballen.

## Metodologia i fonts

Selecció elaborada per SpainFacts amb projectes coneguts i consolidats d'altres països; no és una classificació ni un cens complet. La descripció de cada projecte procedeix del seu propi web. Tots els enllaços es van comprovar el setembre de 2026; alguns webs (OpenSecrets, Open Government Partnership) bloquegen les comprovacions automàtiques, però són les seves adreces oficials. Els projectes l'activitat dels quals ha disminuït ho indiquen en la seva descripció. Les lliçons per a Espanya són suggeriments de SpainFacts, no avaluacions de cap administració concreta.
