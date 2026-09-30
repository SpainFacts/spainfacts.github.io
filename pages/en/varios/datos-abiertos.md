---
title: Open data in Spain
description: "A guide to Spain's open data projects: public portals and bodies (INE, BOE, AEMET, REE, Cadastre, Ministry of Finance...), regional and municipal portals, and civil society and data journalism projects, including the ones SpainFacts uses."
i18n_origen: 0d2b0699582c
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    // English labels for the project types (the values in the data stay in Spanish because they drive the filter)
    const tipoEn = { 'Estado': 'State', 'Autonómico y local': 'Regional and local', 'Sociedad civil': 'Civil society', 'Periodismo de datos': 'Data journalism' };
</script>

```sql proyectos
SELECT *
FROM (VALUES
    -- Administración General del Estado
    (1, 'Estado', 'datos.gob.es', 'https://datos.gob.es/', 'Ministry for Digital Transformation and the Civil Service (Aporta Initiative)', 'National catalogue bringing together the open datasets of ministries, regions, councils and universities, with guides and reuse cases.', 'DCAT-AP-ES catalogue, API and SPARQL; formats depend on the publisher', 'Depends on each publishing body', NULL, NULL),
    (2, 'Estado', 'INE: INEbase and JSON API', 'https://www.ine.es/dyngs/DAB/index.htm?cid=1099', 'National Statistics Institute (INE)', 'All INE official statistics (CPI, Labour Force Survey, municipal register, GDP, births, tourism...) available on the website and through an API that returns JSON.', 'JSON API (Tempus3), PC-Axis, CSV, Excel', 'Free reuse with attribution', 'It is the main source: CPI, unemployment (Labour Force Survey), population, GDP and more than half the series on the site.', '/en/economia/ipc'),
    (3, 'Estado', 'BOE: open data and API', 'https://www.boe.es/datosabiertos/api/api.php', 'Official State Gazette Agency (BOE)', 'Daily summaries of the BOE and the BORME (Official Gazette of the Companies Register) and consolidated legislation, accessible in an automated way.', 'API returning XML or JSON', 'Free reuse with attribution', 'We link the regulations that set out councils'' obligations (it is not a data source).', '/en/transparencia/cuentas-municipales'),
    (4, 'Estado', 'AEMET OpenData', 'https://opendata.aemet.es/', 'State Meteorological Agency (AEMET)', 'Observations, daily and monthly climate values, forecasts and warnings from all AEMET stations.', 'REST API in JSON; requires a free key', 'Reuse with attribution to AEMET', 'Daily temperatures from the reference stations for the heat map.', '/en/energia-clima/calor'),
    (5, 'Estado', 'REData (Red Eléctrica)', 'https://www.ree.es/es/datos/apidatos', 'Red Eléctrica de España', 'Generation by technology, demand, exchanges, emissions and electricity balance, national and by region.', 'REST API in JSON, no key', 'Reuse with attribution to Red Eléctrica', 'Generation mix, power sector emissions and storage.', '/en/energia-clima/mix-electrico'),
    (6, 'Estado', 'ESIOS', 'https://www.esios.ree.es/', 'Red Eléctrica de España (system operator)', 'The system operator''s information system: prices, demand and generation in real time, every few minutes.', 'JSON API with a free token', 'Reuse with attribution to Red Eléctrica', 'Real-time data and records for the electricity system.', '/en/energia-clima/records'),
    (7, 'Estado', 'CNMC Data', 'https://data.cnmc.es/', 'National Markets and Competition Commission (CNMC)', 'Statistics on the markets the CNMC supervises: energy, telecommunications, audiovisual, postal and transport.', 'Downloads and interactive dashboards', 'See the legal notice', NULL, NULL),
    (8, 'Estado', 'Cadastre e-Office (Sede Electrónica del Catastro)', 'https://www.sedecatastro.gob.es/', 'Directorate-General for the Cadastre (Ministry of Finance)', 'Maps and data on every property in Spain (except the Basque Country and Navarre, which have their own cadastre): plots, buildings, floor areas and uses.', 'INSPIRE bulk download (GML), WMS map services; alphanumeric files require registration', 'Free use with attribution (non-protected data)', 'Indirectly: the Ministry of Housing rent index cross-references income tax and Cadastre data.', '/en/vivienda/alquiler'),
    (9, 'Estado', 'IGN and CNIG Download Centre', 'https://centrodedescargas.cnig.es/', 'National Geographic Institute and National Centre for Geographic Information', 'Topographic maps, orthophotos (PNOA), terrain models, administrative boundaries and gazetteer.', 'Shapefile, GeoPackage, GeoTIFF, LiDAR and web services', 'CC BY 4.0', 'The boundaries of regions and provinces in the maps.', '/en/energia-clima/calor'),
    (10, 'Estado', 'Public Sector Procurement Platform', 'https://contrataciondelestado.es/', 'Ministry of Finance', 'Tenders, awards and contracts of the General State Administration and many other administrations.', 'Syndicated open data (ATOM with CODICE XML)', 'Free reuse with attribution', NULL, NULL),
    (11, 'Estado', 'National Grants Database (BDNS)', 'https://www.infosubvenciones.es/', 'General Comptroller of the State Administration (Ministry of Finance)', 'Calls for and awards of grants and public aid from all administrations, with beneficiary and amount.', 'Web search with export of results', 'See the legal notice', NULL, NULL),
    (12, 'Estado', 'Transparency Portal', 'https://transparencia.gob.es/', 'General State Administration (Ministry for Digital Transformation and the Civil Service)', 'Proactive disclosure by the General State Administration (organisation, senior officials, contracts, agreements, budgets) and the channel for exercising the right of access to information.', 'Web pages and downloads', 'Transparency Act 19/2013', NULL, NULL),
    (13, 'Estado', 'Bank of Spain: statistics', 'https://www.bde.es/wbe/es/estadisticas/', 'Bank of Spain', 'Statistical Bulletin with series on interest rates, credit, balance of payments and general government debt.', 'Series downloadable in CSV and Excel', 'Reuse with attribution', 'General government and council debt.', '/en/territorios/municipios'),
    (14, 'Estado', 'SEPE: open data', 'https://sede.sepe.gob.es/portalSede/datos-abiertos.html', 'Public Employment Service (SEPE)', 'Registered unemployment, contracts and unemployment benefits, with monthly detail by municipality.', 'CSV and Excel', 'Reuse with attribution', 'Registered unemployment by municipality and province.', '/en/economia/paro'),
    (15, 'Estado', 'DGT in figures', 'https://www.dgt.es/menusecundario/dgt-en-cifras/', 'Directorate-General for Traffic (DGT)', 'Microdata on registrations, deregistrations, transfers and the vehicle fleet, plus statistics on road accidents and drivers.', 'Fixed-width text files (MATRABA) and tables', 'Reuse with attribution', 'Registrations, electric cars and the vehicle fleet.', '/en/movilidad/parque'),
    (16, 'Estado', 'National Access Point for traffic and mobility (NAP)', 'https://nap.dgt.es/', 'DGT and Ministry of Transport', 'Data on traffic, incidents, electric charging points and other mobility services, under European intelligent transport rules.', 'DATEX II, JSON and CSV', 'Depends on each dataset', 'Charging points for electric cars.', '/en/movilidad/recarga'),
    (17, 'Estado', 'MITECO', 'https://www.miteco.gob.es/', 'Ministry for the Ecological Transition and the Demographic Challenge', 'Reservoir hydrological bulletin, greenhouse gas emissions inventory, air quality, environmental mapping and energy.', 'Excel, CSV, Access and mapping services', 'Reuse with attribution', 'Reservoir levels and greenhouse gas emissions.', '/en/energia-clima/embalses'),
    (18, 'Estado', 'Ministry of Finance: CONPREL (local budgets and outturns)', 'https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL', 'General Secretariat for Regional and Local Financing (Ministry of Finance)', 'Budgets and outturns of every council, provincial council and region, by chapter and by spending policy.', 'Web queries and download in Access or Excel', 'Reuse with attribution', 'Spending and revenue per resident in each municipality and who fails to submit their accounts.', '/en/transparencia/cuentas-municipales'),
    (19, 'Estado', 'Accounts Reporting Platform', 'https://www.rendiciondecuentas.es/', 'Court of Audit and regional external audit bodies', 'Status of submission of each local authority''s General Account and access to the accounts submitted.', 'Web queries', 'See the legal notice', 'Which councils submit their General Account on time.', '/en/transparencia/cuentas-municipales'),
    (20, 'Estado', 'Infoelectoral', 'https://infoelectoral.interior.gob.es/', 'Ministry of the Interior', 'Official results of general elections (since 1977), municipal elections (since 1979) and European elections (since 1987), by polling station, municipality and province.', 'Text and Excel files in the downloads area', 'Reuse with attribution', 'Results of general, municipal and European elections.', '/en/sociedad/elecciones'),
    -- Comunidades autónomas y ayuntamientos
    (30, 'Autonómico y local', 'Open Data Euskadi', 'https://opendata.euskadi.eus/', 'Basque Government', 'One of the pioneering open data portals in Spain (2010): budgets, environment, transport, culture, air quality and more.', 'CSV, JSON, XML and API', 'Reuse with attribution', NULL, NULL),
    (31, 'Autonómico y local', 'Castile and León open data', 'https://datosabiertos.jcyl.es/', 'Regional Government of Castile and León', 'Regional catalogue with data on health, education, environment, employment and administrative registers.', 'CSV, JSON and API', 'Depends on each dataset', NULL, NULL),
    (32, 'Autonómico y local', 'Aragón Open Data', 'https://opendata.aragon.es/', 'Government of Aragon', 'Regional portal with a data catalogue, linked data (Aragopedia) and analysis of the region and its municipalities.', 'CSV, JSON, API and SPARQL', 'Depends on each dataset', NULL, NULL),
    (33, 'Autonómico y local', 'Andalusian Regional Government open data', 'https://www.juntadeandalucia.es/datosabiertos/portal.html', 'Regional Government of Andalusia', 'Data catalogue of the Andalusian administration: statistics, health, employment, environment and services.', 'CSV, JSON, XML', 'Depends on each dataset', NULL, NULL),
    (34, 'Autonómico y local', 'Dades obertes de la Generalitat Valenciana', 'https://dadesobertes.gva.es/', 'Valencian Regional Government', 'Data from the Valencian administration: health, education, environment, transport and public sector.', 'CSV, JSON, XML', 'Depends on each dataset', NULL, NULL),
    (35, 'Autonómico y local', 'Dades obertes de Catalunya', 'https://analisi.transparenciacatalunya.cat/', 'Government of Catalonia', 'Open data and transparency portal of the Catalan Government, with visualisations and direct querying of each dataset.', 'CSV, JSON and API (Socrata)', 'Depends on each dataset', NULL, NULL),
    (36, 'Autonómico y local', 'Community of Madrid open data', 'https://datos.comunidad.madrid/', 'Community of Madrid', 'Regional catalogue with data on health, education, transport, environment and regional statistics.', 'CSV, JSON, XML', 'Depends on each dataset', NULL, NULL),
    (37, 'Autonómico y local', 'Madrid City Council open data portal', 'https://datos.madrid.es/', 'Madrid City Council', 'Real-time traffic, air quality, municipal register, budgets, contracts, car parks, BiciMAD and hundreds more datasets.', 'CSV, JSON, XML and API', 'Reuse with attribution', NULL, NULL),
    (38, 'Autonómico y local', 'Open Data BCN', 'https://opendata-ajuntament.barcelona.cat/', 'Barcelona City Council', 'Data on Barcelona''s population, mobility, environment, economy, facilities and tourism.', 'CSV, JSON and API', 'CC BY 4.0', NULL, NULL),
    -- Sociedad civil
    (50, 'Sociedad civil', 'Civio', 'https://civio.es/', 'Fundación Ciudadana Civio', 'Independent foundation that monitors public authorities through data journalism and its own tools; publishes its code on GitHub.', 'Search tools and downloadable data in some projects', 'Varies by project', NULL, NULL),
    (51, 'Sociedad civil', 'El BOE nuestro de cada día (Civio)', 'https://civio.es/el-boe-nuestro-de-cada-dia/', 'Fundación Ciudadana Civio', 'Explains every day, in plain language, the most relevant items published in the Official State Gazette; includes the Decretómetro, which counts decree-laws.', 'Articles and visualisations', 'Civio content', NULL, NULL),
    (52, 'Sociedad civil', '¿Dónde van mis impuestos? (Civio)', 'https://dondevanmisimpuestos.es/', 'Fundación Ciudadana Civio', 'State, regional and council budgets explained by spending policy, with how they have changed.', 'Interactive visualisations and downloads', 'Civio content', NULL, NULL),
    (53, 'Sociedad civil', 'El Indultómetro (Civio)', 'https://civio.es/justicia/buscador-de-indultos/', 'Fundación Ciudadana Civio', 'Search tool for pardons granted in Spain, based on the royal decrees published in the BOE.', 'Web search', 'Civio content', NULL, NULL),
    (54, 'Sociedad civil', 'Medicamentalia (Civio)', 'https://medicamentalia.org/', 'Fundación Ciudadana Civio', 'International investigation into access to medicines, vaccines and contraceptives around the world. Not updated since 2018.', 'Visualisations and project data', 'Civio content', NULL, NULL),
    (55, 'Sociedad civil', 'Access Info Europe', 'https://www.access-info.org/', 'Madrid-based organisation', 'Defends and promotes the right of access to public information in Spain and in Europe, through litigation, guides and monitoring of the transparency law.', 'Reports and guides', 'Own content', NULL, NULL),
    (56, 'Sociedad civil', 'Transparency International Spain', 'https://transparencia.org.es/', 'Spanish chapter of Transparency International', 'Publishes the Corruption Perceptions Index in Spain and transparency assessments of institutions and companies.', 'Reports and indices', 'Own content', NULL, NULL),
    (57, 'Sociedad civil', 'Fundación Hay Derecho', 'https://www.hayderecho.com/', 'Fundación Hay Derecho', 'Studies on the rule of law and institutional quality, such as the Dedómetro, which analyses appointments in the public sector.', 'Reports', 'Own content', NULL, NULL),
    (58, 'Sociedad civil', 'Qué hacen los diputados', 'https://quehacenlosdiputados.es/', 'Political Watch', 'Tracks every initiative in the Congress of Deputies and classifies them by topic and parliamentary group.', 'Website, API and open source code', 'See the website', NULL, NULL),
    (59, 'Sociedad civil', 'ObservatoriosPublicos.es', 'https://observatoriospublicos.es/', 'Jaime Gómez-Obregón (personal initiative)', 'Census of Spain''s public and public-private observatories, with their administration, year of creation and status; accepts corrections from the community.', 'Website and open source code on GitHub', 'See the website', 'It is the basis of our analysis of public observatories.', '/en/varios/observatorios'),
    -- Periodismo de datos y verificación
    (70, 'Periodismo de datos', 'Maldita.es and Maldito Dato', 'https://maldita.es/malditodato/', 'Fundación Maldita.es', 'Fact-checking and hoax debunking; the Maldito Dato section uses official figures to explain political and economic news.', 'Articles and charts', 'Own content', NULL, NULL),
    (71, 'Periodismo de datos', 'Newtral', 'https://www.newtral.es/', 'Newtral Media Audiovisual', 'Fact-checking and data journalism outlet that checks public statements and explains the data behind the news.', 'Articles and charts', 'Own content', NULL, NULL),
    (72, 'Periodismo de datos', 'Datadista', 'https://www.datadista.com/', 'Independent data journalism outlet', 'Long-form data investigations (housing, health, energy...); during the pandemic it published COVID-19 data series by region on GitHub.', 'Articles and data on GitHub', 'See each repository', NULL, NULL),
    (73, 'Periodismo de datos', 'EpData', 'https://www.epdata.es/', 'Europa Press', 'Europa Press data portal: charts of public statistics, ready to consult and embed in other websites.', 'Embeddable charts and tables', 'Europa Press terms', NULL, NULL),
    (60, 'Sociedad civil', 'Montera34', 'https://montera34.com/', 'Pablo Rey Mazón and Alfonso Sánchez Uzábal', 'Data-as-a-commons projects built with free software: visualisation and analysis of urban data, school segregation, tourist rentals and opening up municipal databases.', 'Visualisations and open source code', 'See each project', NULL, NULL)
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

# 🔓 Open data in Spain

**Open data** is public information that anyone can download, reuse and redistribute without asking permission, in formats a program can read. It matters because it allows what governments, parties and companies say to be checked, because citizens and the media can carry out their own analyses instead of relying on other people's summaries, and because useful services, research and businesses are built on it. SpainFacts exists thanks to open data: all our figures come from public sources that anyone can consult.

This page brings together **{resumen[0].total} projects**: {resumen[0].estado} from the General State Administration, {resumen[0].autonomico} regional and municipal portals and {resumen[0].civil} civil society and data journalism initiatives. For **{resumen[0].usados}** of them we link to the SpainFacts page where we use them.

<ButtonGroup name=tipo title="Type of project">
    <ButtonGroupItem valueLabel="All" value="Todos" default />
    <ButtonGroupItem valueLabel="State" value="Estado" />
    <ButtonGroupItem valueLabel="Regions and councils" value="Autonómico y local" />
    <ButtonGroupItem valueLabel="Civil society" value="Sociedad civil" />
    <ButtonGroupItem valueLabel="Data journalism" value="Periodismo de datos" />
    <ButtonGroupItem valueLabel="Used by SpainFacts" value="Usados" />
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
            <span class="shrink-0 rounded-full bg-purple-50 dark:bg-purple-950/40 text-purple-700 dark:text-purple-300 text-xs font-semibold px-2 py-0.5">{tipoEn[p.tipo] ?? p.tipo}</span>
        </div>
        <div class="text-xs text-gray-500 dark:text-gray-400">{p.quien}</div>
        <p class="text-sm text-gray-700 dark:text-gray-300 m-0">{p.que}</p>
        <div class="text-xs text-gray-600 dark:text-gray-400"><span class="font-semibold">Format:</span> {p.formato} · <span class="font-semibold">Licence:</span> {p.licencia}</div>
        {#if p.uso_url}
            <div class="mt-1 rounded-lg bg-purple-50/70 dark:bg-purple-950/30 border border-purple-200 dark:border-purple-800 px-3 py-2 text-xs text-purple-900 dark:text-purple-200">
                <span class="font-semibold">On SpainFacts:</span> {p.uso} <a href={p.uso_url} class="font-semibold text-purple-700 dark:text-purple-400">See the page →</a>
            </div>
        {/if}
    </div>
{/each}
</div>

---

## How to read this guide

- **Format** shows how the data can be obtained: an **API** lets a program request them automatically; **CSV**, **JSON** or **XML** files can be opened and processed directly; a **web search** only allows manual queries.
- **Licence** summarises the reuse conditions. In Spain, public sector information is reusable as a general rule (Act 37/2007 and Royal Decree 1495/2011), with the obligation to cite the source and not distort the data; each portal sets out its conditions in its legal notice. Civil society projects and the media have their own conditions.
- Civil society and data journalism projects are included for their work in explaining or scrutinising public data, which does not imply endorsing their conclusions.

## Methodology and sources

A selection compiled by SpainFacts with the main public data portals and the best-known citizen initiatives; it is not intended to be a complete census. All links were checked in September 2026. Projects that no longer exist have been removed and those that remain online but are no longer updated are flagged in their description. The full catalogue of the sources this site uses, with their licences and methodology, is in [Sources](/en/fuentes). Missing a project? See also the [inspiring examples from other countries](/en/varios/inspiracion-internacional).
