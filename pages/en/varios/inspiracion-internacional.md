---
title: Inspiring examples from other countries
description: "Open data and transparency projects from other countries that serve as models: USAFacts, Our World in Data, Gapminder, TheyWorkForYou, ProZorro, X-Road, g0v, Chequeado and more, with what Spain could learn from each."
i18n_origen: 6594083ed575
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    // English labels for the project types (the values in the data stay in Spanish because they drive the filter)
    const tipoEn = { 'Estadística y divulgación': 'Statistics and public outreach', 'Portales de datos': 'Data portals', 'Parlamento y política': 'Parliament and politics', 'Contratación y gobierno digital': 'Procurement and digital government', 'Tecnología cívica': 'Civic technology', 'Verificación': 'Fact-checking' };
</script>

```sql ejemplos
SELECT *
FROM (VALUES
    -- Estadística y divulgación
    (1, 'Estadística y divulgación', 'USAFacts', 'https://usafacts.org/', 'United States', 'Non-profit organisation founded in 2017 by Steve Ballmer that brings together in one place the official data on the population, economy, budget and public services of the United States, without opinion or party affiliation.', 'It is the direct inspiration for SpainFacts: it shows that a country''s accounts can be told with official data and in a neutral way, for any citizen.', 'A single, understandable entry point to public figures, instead of hundreds of portals scattered across different bodies.', 'Direct inspiration for this site', '/en'),
    (2, 'Estadística y divulgación', 'Our World in Data', 'https://ourworldindata.org/', 'United Kingdom (University of Oxford)', 'Research publication by the Global Change Data Lab and the University of Oxford with thousands of charts on health, poverty, energy, climate and education in every country.', 'Every chart comes with its source, its methodology and a data download, and all its content and code are open (CC BY).', 'Document every figure and allow it to be downloaded from the chart itself.', 'SpainFacts uses its series in the international comparison', '/en/economia/turismo'),
    (3, 'Estadística y divulgación', 'Gapminder', 'https://www.gapminder.org/', 'Sweden', 'Foundation created by Hans Rosling, Ola Rosling and Anna Rosling Rönnlund to fight misconceptions about the world with easy-to-understand statistics.', 'Its animated bubble charts and knowledge tests show that even well-informed people are often wrong about how the world is changing.', 'Measure the public''s misperceptions and design outreach to correct them.', NULL, NULL),
    (4, 'Estadística y divulgación', 'Statistics Netherlands (CBS)', 'https://www.cbs.nl/', 'Netherlands', 'The Dutch statistics office. Its StatLine database offers thousands of tables as open data, with an OData API.', 'All its statistical information is published as open data, with an API and under a CC BY 4.0 licence.', 'A standard API and an explicit open licence for all statistical tables.', NULL, NULL),
    (5, 'Estadística y divulgación', 'Statistics Norway (SSB)', 'https://www.ssb.no/', 'Norway', 'The Norwegian statistics office. Its StatBank gives access to the official series, also through a free, open API.', 'It combines very comprehensive statistics with a simple API and news stories explaining each figure it publishes.', 'Accompany each statistical release with a short explanation and downloadable data.', NULL, NULL),
    (6, 'Estadística y divulgación', 'Stats NZ and data.govt.nz', 'https://www.stats.govt.nz/', 'New Zealand', 'The New Zealand statistics office and the national open data portal (data.govt.nz). Stats NZ runs the Integrated Data Infrastructure, which links anonymised data from different agencies for research.', 'It allows accredited researchers to study real life paths (education, employment, health, benefits) with privacy safeguards.', 'A secure environment for research with linked administrative records, without exposing personal data.', NULL, NULL),
    -- Portales de datos
    (10, 'Portales de datos', 'data.gov.sg', 'https://data.gov.sg/', 'Singapore', 'The Singapore Government''s open data portal, with real-time APIs (weather, air quality, transport) as well as thousands of datasets.', 'It puts the emphasis on reliable, documented APIs that developers can use directly in their services.', 'Prioritise real-time data with stable APIs and clear documentation.', NULL, NULL),
    (11, 'Portales de datos', 'data.europa.eu', 'https://data.europa.eu/', 'European Union', 'The European Union''s official data portal, which brings together data from the European institutions and the national portals, including datos.gob.es. It publishes the Open Data Maturity report every year.', 'It allows the degree of openness of each European country to be compared using the same methodology.', 'Use that annual comparison to set specific openness targets.', 'SpainFacts uses Eurostat, the EU statistics office, in many comparisons', '/en/economia/paro'),
    -- Parlamento y política
    (20, 'Parlamento y política', 'TheyWorkForYou and mySociety', 'https://www.theyworkforyou.com/', 'United Kingdom', 'TheyWorkForYou, from the charity mySociety, shows what each British MP says and how they vote. mySociety also created WhatDoTheyKnow (freedom of information requests made in the open) and FixMyStreet (reports of street problems).', 'It turns parliamentary records and votes into easy-to-follow profiles for each MP, with an API and open source code reused in other countries.', 'Publish roll-call votes and speeches in Congress and the Senate in reusable formats.', NULL, NULL),
    (21, 'Parlamento y política', 'GovTrack.us', 'https://www.govtrack.us/', 'United States', 'Independent website that has tracked the bills and votes of the United States Congress since 2004.', 'It lets people follow every bill, receive alerts and see activity statistics for each member of Congress.', 'Public, real-time tracking of the progress of every bill.', NULL, NULL),
    (22, 'Parlamento y política', 'OpenSecrets', 'https://www.opensecrets.org/', 'United States', 'Independent organisation that follows the money in US politics: campaign donations, lobbying spending and the personal finances of elected officials.', 'It cross-references scattered official sources to answer who funds whom.', 'More complete registers of lobbyists and party funding, in open format.', NULL, NULL),
    (23, 'Parlamento y política', 'abgeordnetenwatch.de', 'https://www.abgeordnetenwatch.de/', 'Germany', 'Platform where anyone can publicly ask their MPs questions and look up their answers, votes and additional income.', 'Questions and answers stay published, creating a permanent record of what each representative says.', 'A public channel for citizens'' questions to their representatives.', NULL, NULL),
    -- Contratación y gobierno digital
    (30, 'Contratación y gobierno digital', 'ProZorro', 'https://prozorro.gov.ua/', 'Ukraine', 'Electronic public procurement system, mandatory since 2016, in which all tenders and awards are published as open data following the international OCDS standard.', 'It grew out of collaboration between government, business and civil society, and anyone can monitor contracts, for example with the DOZORRO monitoring platform.', 'Publish all public procurement, from every administration, in a single open format.', NULL, NULL),
    (31, 'Contratación y gobierno digital', 'Open Contracting Partnership', 'https://www.open-contracting.org/', 'International', 'Organisation that promotes open public contracting and maintains the Open Contracting Data Standard (OCDS), used by governments around the world.', 'A common standard makes it possible to compare contracts across administrations and countries and to detect anomalies.', 'Adopt a common standard for procurement data from all administrations.', NULL, NULL),
    (32, 'Contratación y gobierno digital', 'X-Road', 'https://x-road.global/', 'Estonia', 'Data exchange layer between administrations that Estonia has used since 2001, open source and now maintained by the Nordic Institute for Interoperability Solutions (NIIS).', 'Administrations request data from each other securely, so citizens do not have to hand over the same document twice, and every access is logged, allowing Estonians to check which body has consulted their data.', 'Real interoperability between administrations and a visible log of who consults each citizen''s data.', NULL, NULL),
    (33, 'Contratación y gobierno digital', 'Code for America', 'https://codeforamerica.org/', 'United States', 'Non-profit organisation, founded in 2009, that works with governments to make their digital services simple, for example with GetCalFresh for applying for food assistance in California.', 'It measures success by how easy it is for people to access public services.', 'Design procedures with users and measure how many complete them.', NULL, NULL),
    -- Tecnología cívica y gobierno abierto
    (40, 'Tecnología cívica', 'g0v and vTaiwan', 'https://g0v.tw/', 'Taiwan', 'Open civic technology community born in 2012 that creates clearer versions of public websites and data. It gave rise to vTaiwan, an online consultation process that used the Pol.is tool to seek consensus on digital regulations; its activity has been more irregular in recent years.', 'It shows that civil society can work with government to open up data and deliberate on specific policies.', 'Stable spaces for collaboration between administrations and volunteer communities.', NULL, NULL),
    (41, 'Tecnología cívica', 'Open Knowledge Foundation', 'https://okfn.org/', 'International (United Kingdom)', 'Pioneering open knowledge organisation, founded in 2004. It created CKAN, the data catalogue software used by many public portals, and the Open Definition, which defines what open data is.', 'It has laid the technical and conceptual foundations of many of the world''s data portals.', 'Use common software and definitions instead of different proprietary solutions in each portal.', NULL, NULL),
    (42, 'Tecnología cívica', 'Open Government Partnership', 'https://www.opengovpartnership.org/', 'International', 'Partnership of governments and civil society for open government. Spain has taken part since 2011 with action plans drawn up by administrations and civil society organisations.', 'It requires specific transparency commitments to be set and subjected to independent assessment.', 'Measurable, independently assessed commitments.', NULL, NULL),
    (43, 'Tecnología cívica', 'Operação Serenata de Amor', 'https://serenata.ai/', 'Brazil', 'Open Knowledge Brasil project launched in 2016 that uses an artificial intelligence system (Rosie) to review federal deputies'' expense claims and flag suspicious ones. Its code is open (MIT licence); today it is updated less often.', 'It showed that a few volunteers with open data and code can audit thousands of public expenses.', 'Publish public officials'' expenses in enough detail for them to be audited.', NULL, NULL),
    -- Verificación
    (50, 'Verificación', 'Full Fact', 'https://fullfact.org/', 'United Kingdom', 'Independent fact-checking charity that also develops artificial intelligence tools to detect claims worth checking.', 'As well as fact-checking, it asks those who spread an error to correct it and proposes improvements in how statistics are published.', 'Public bodies publicly correcting misuse of their data.', NULL, NULL),
    (51, 'Verificación', 'Chequeado', 'https://chequeado.com/', 'Argentina', 'Non-profit outlet founded in 2010, a pioneer of fact-checking in Latin America, with its own tools such as Chequeabot.', 'It combines fact-checking, data journalism and education, and shares methods and tools with media across the region.', 'Collaboration between fact-checkers and training in the use of public data.', NULL, NULL)
) AS t(orden, tipo, nombre, url, pais, que, por_que, leccion, uso, uso_url)
ORDER BY orden
```

# 🌍 Inspiring examples from other countries

Many countries have spent years publishing their public data openly and building tools on top of it that anyone can use: to understand the economy, follow the work of parliaments, keep an eye on public money or check what politicians say. Here we bring together **{ejemplos.length} projects** by governments, foundations, media outlets and volunteer communities that serve as models, with what each one contributes and what **Spain could learn** from it. SpainFacts itself was born from one of them, USAFacts. For Spanish projects, see [Open data in Spain](/en/varios/datos-abiertos).

<ButtonGroup name=tipo title="Type of project">
    <ButtonGroupItem valueLabel="All" value="Todos" default />
    <ButtonGroupItem valueLabel="Statistics and public outreach" value="Estadística y divulgación" />
    <ButtonGroupItem valueLabel="Data portals" value="Portales de datos" />
    <ButtonGroupItem valueLabel="Parliament and politics" value="Parlamento y política" />
    <ButtonGroupItem valueLabel="Procurement and digital government" value="Contratación y gobierno digital" />
    <ButtonGroupItem valueLabel="Civic technology" value="Tecnología cívica" />
    <ButtonGroupItem valueLabel="Fact-checking" value="Verificación" />
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
        <div class="text-xs text-gray-500 dark:text-gray-400">{tipoEn[e.tipo] ?? e.tipo}</div>
        <p class="text-sm text-gray-700 dark:text-gray-300 m-0">{e.que}</p>
        <p class="text-sm text-gray-700 dark:text-gray-300 m-0"><span class="font-semibold">Why it inspires:</span> {e.por_que}</p>
        <div class="mt-1 rounded-lg bg-purple-50/70 dark:bg-purple-950/30 border border-purple-200 dark:border-purple-800 px-3 py-2 text-xs text-purple-900 dark:text-purple-200">
            <span class="font-semibold">What Spain could learn:</span> {e.leccion}
        </div>
        {#if e.uso_url}
            <div class="text-xs text-gray-600 dark:text-gray-400"><span class="font-semibold">On SpainFacts:</span> {e.uso}. <a href={e.uso_url} class="font-semibold text-purple-700 dark:text-purple-400">See →</a></div>
        {/if}
    </div>
{/each}
</div>

---

## What they have in common

- **One place for each question.** The best examples do not require you to know which body publishes each figure: they bring it together and explain it.
- **Every figure with its source and a download.** Our World in Data, USAFacts and the Dutch and Norwegian statistics offices let you reach the original data and reuse it.
- **Common standards.** OCDS in procurement, CKAN in catalogues and X-Road in data exchange between administrations make data from different sources fit together.
- **Collaboration with civil society.** ProZorro, g0v and mySociety show that open data delivers more when administrations, volunteers, media and universities work on it.

## Methodology and sources

A selection compiled by SpainFacts with well-known, established projects from other countries; it is neither a ranking nor a complete census. The description of each project comes from its own website. All links were checked in September 2026; some websites (OpenSecrets, Open Government Partnership) block automated checks, but these are their official addresses. Projects whose activity has declined say so in their description. The lessons for Spain are SpainFacts' suggestions, not assessments of any particular administration.
