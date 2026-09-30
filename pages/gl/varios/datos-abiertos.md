---
i18n_origen: 0d2b0699582c
title: Datos abertos en España
description: "Guía dos proxectos de datos abertos de España: portais e organismos públicos (INE, BOE, AEMET, REE, Catastro, Facenda...), portais autonómicos e municipais, e proxectos da sociedade civil e do xornalismo de datos, cos que usa SpainFacts."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    const etiquetasTipo = {
        'Estado': 'Estado',
        'Autonómico y local': 'Autonómico e local',
        'Sociedad civil': 'Sociedade civil',
        'Periodismo de datos': 'Xornalismo de datos'
    };
</script>

```sql proyectos
SELECT *
FROM (VALUES
    -- Administración General del Estado
    (1, 'Estado', 'datos.gob.es', 'https://datos.gob.es/', 'Ministerio para a Transformación Dixital e da Función Pública (Iniciativa Aporta)', 'Catálogo nacional que reúne os conxuntos de datos abertos de ministerios, comunidades, concellos e universidades, con guías e casos de reutilización.', 'Catálogo DCAT-AP-ES, API e SPARQL; formatos segundo o organismo', 'Segundo cada organismo publicador', NULL, NULL),
    (2, 'Estado', 'INE: INEbase e API JSON', 'https://www.ine.es/dyngs/DAB/index.htm?cid=1099', 'Instituto Nacional de Estatística', 'Todas as estatísticas oficiais do INE (IPC, EPA, padrón, PIB, nacementos, turismo...) consultables na web e mediante unha API que devolve JSON.', 'API JSON (Tempus3), PC-Axis, CSV, Excel', 'Reutilización libre citando a fonte', 'É a fonte principal: IPC, paro (EPA), poboación, PIB e máis da metade das series do sitio.', '/gl/economia/ipc'),
    (3, 'Estado', 'BOE: datos abertos e API', 'https://www.boe.es/datosabiertos/api/api.php', 'Axencia Estatal Boletín Oficial do Estado', 'Sumarios diarios do BOE e do BORME e lexislación consolidada, accesibles de forma automatizada.', 'API con resposta XML ou JSON', 'Reutilización libre citando a fonte', 'Ligamos a normativa que explica as obrigas dos concellos (non é fonte de datos).', '/gl/transparencia/cuentas-municipales'),
    (4, 'Estado', 'AEMET OpenData', 'https://opendata.aemet.es/', 'Axencia Estatal de Meteoroloxía', 'Observacións, valores climatolóxicos diarios e mensuais, predicións e avisos de todas as estacións da AEMET.', 'API REST en JSON; require unha clave gratuíta', 'Reutilización citando a AEMET', 'Temperaturas diarias das estacións de referencia para o mapa da calor.', '/gl/energia-clima/calor'),
    (5, 'Estado', 'REData (Red Eléctrica)', 'https://www.ree.es/es/datos/apidatos', 'Red Eléctrica de España', 'Xeración por tecnoloxía, demanda, intercambios, emisións e balance eléctrico, nacional e por comunidade.', 'API REST en JSON, sen clave', 'Reutilización citando a Red Eléctrica', 'Mix de xeración, emisións do sector eléctrico e almacenamento.', '/gl/energia-clima/mix-electrico'),
    (6, 'Estado', 'ESIOS', 'https://www.esios.ree.es/', 'Red Eléctrica de España (operador do sistema)', 'Sistema de información do operador do sistema: prezos, demanda e xeración en tempo real, cada poucos minutos.', 'API en JSON con token gratuíto', 'Reutilización citando a Red Eléctrica', 'Datos en tempo real e récords do sistema eléctrico.', '/gl/energia-clima/records'),
    (7, 'Estado', 'CNMC Data', 'https://data.cnmc.es/', 'Comisión Nacional dos Mercados e a Competencia', 'Estatísticas dos mercados que supervisa a CNMC: enerxía, telecomunicacións, audiovisual, postal e transporte.', 'Descargas e paneis interactivos', 'Consultar o aviso legal', NULL, NULL),
    (8, 'Estado', 'Sede Electrónica do Catastro', 'https://www.sedecatastro.gob.es/', 'Dirección Xeral do Catastro (Ministerio de Facenda)', 'Cartografía e datos de todos os inmobles de España (agás País Vasco e Navarra, con catastro propio): parcelas, edificios, superficies e usos.', 'Descarga masiva INSPIRE (GML), servizos de mapas WMS; os ficheiros alfanuméricos requiren rexistro', 'Uso libre citando a fonte (datos non protexidos)', 'De forma indirecta: o índice de alugueres do Ministerio de Vivenda cruza IRPF e Catastro.', '/gl/vivienda/alquiler'),
    (9, 'Estado', 'IGN e Centro de Descargas do CNIG', 'https://centrodedescargas.cnig.es/', 'Instituto Xeográfico Nacional e Centro Nacional de Información Xeográfica', 'Mapas topográficos, ortofotos (PNOA), modelos do terreo, límites administrativos e nomenclátor.', 'Shapefile, GeoPackage, GeoTIFF, LiDAR e servizos web', 'CC BY 4.0', 'Os límites de comunidades e provincias dos mapas.', '/gl/energia-clima/calor'),
    (10, 'Estado', 'Plataforma de Contratación do Sector Público', 'https://contrataciondelestado.es/', 'Ministerio de Facenda', 'Licitacións, adxudicacións e contratos da Administración Xeral do Estado e de moitas outras administracións.', 'Datos abertos sindicados (ATOM con XML CODICE)', 'Reutilización libre citando a fonte', NULL, NULL),
    (11, 'Estado', 'Base de Datos Nacional de Subvencións (BDNS)', 'https://www.infosubvenciones.es/', 'Intervención Xeral da Administración do Estado (Ministerio de Facenda)', 'Convocatorias e concesións de subvencións e axudas públicas de todas as administracións, con beneficiario e importe.', 'Buscador web con exportación de resultados', 'Consultar o aviso legal', NULL, NULL),
    (12, 'Estado', 'Portal da Transparencia', 'https://transparencia.gob.es/', 'Administración Xeral do Estado (Ministerio para a Transformación Dixital e da Función Pública)', 'Publicidade activa da Administración Xeral do Estado (organización, altos cargos, contratos, convenios, orzamentos) e a canle para exercer o dereito de acceso á información.', 'Páxinas web e descargas', 'Lei 19/2013 de transparencia', NULL, NULL),
    (13, 'Estado', 'Banco de España: estatísticas', 'https://www.bde.es/wbe/es/estadisticas/', 'Banco de España', 'Boletín Estatístico con series de tipos de xuro, crédito, balanza de pagamentos e débeda das administracións públicas.', 'Series descargables en CSV e Excel', 'Reutilización citando a fonte', 'Débeda das administracións públicas e dos concellos.', '/gl/territorios/municipios'),
    (14, 'Estado', 'SEPE: datos abertos', 'https://sede.sepe.gob.es/portalSede/datos-abiertos.html', 'Servizo Público de Emprego Estatal', 'Paro rexistrado, contratos e prestacións por desemprego, con detalle mensual por municipio.', 'CSV e Excel', 'Reutilización citando a fonte', 'Paro rexistrado por municipio e provincia.', '/gl/economia/paro'),
    (15, 'Estado', 'DGT en cifras', 'https://www.dgt.es/menusecundario/dgt-en-cifras/', 'Dirección Xeral de Tráfico', 'Microdatos de matriculacións, baixas, transferencias e parque de vehículos, ademais de estatísticas de sinistralidade e condutores.', 'Ficheiros de texto de ancho fixo (MATRABA) e táboas', 'Reutilización citando a fonte', 'Matriculacións, coche eléctrico e parque de vehículos.', '/gl/movilidad/parque'),
    (16, 'Estado', 'Punto de Acceso Nacional de tráfico e mobilidade (NAP)', 'https://nap.dgt.es/', 'DGT e Ministerio de Transportes', 'Datos de tráfico, incidencias, puntos de recarga eléctrica e outros servizos de mobilidade, segundo a normativa europea de transporte intelixente.', 'DATEX II, JSON e CSV', 'Segundo cada conxunto', 'Puntos de recarga para coches eléctricos.', '/gl/movilidad/recarga'),
    (17, 'Estado', 'MITECO', 'https://www.miteco.gob.es/', 'Ministerio para a Transición Ecolóxica e o Reto Demográfico', 'Boletín hidrolóxico de encoros, inventario de emisións de gases de efecto invernadoiro, calidade do aire, cartografía ambiental e enerxía.', 'Excel, CSV, Access e servizos cartográficos', 'Reutilización citando a fonte', 'Reserva dos encoros e emisións de gases de efecto invernadoiro.', '/gl/energia-clima/embalses'),
    (18, 'Estado', 'Facenda: CONPREL (orzamentos e liquidacións locais)', 'https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL', 'Secretaría Xeral de Financiamento Autonómico e Local (Ministerio de Facenda)', 'Orzamentos e liquidacións de todos os concellos, deputacións e comunidades, por capítulo e por política de gasto.', 'Consulta web e descarga en Access ou Excel', 'Reutilización citando a fonte', 'Gasto e ingresos por habitante de cada municipio e quen non envía as súas contas.', '/gl/transparencia/cuentas-municipales'),
    (19, 'Estado', 'Plataforma de Rendición de Contas', 'https://www.rendiciondecuentas.es/', 'Tribunal de Contas e órganos de control externo autonómicos', 'Estado de rendición da Conta Xeral de cada entidade local e consulta das contas presentadas.', 'Consulta web', 'Consultar o aviso legal', 'Que concellos presentan a tempo a súa Conta Xeral.', '/gl/transparencia/cuentas-municipales'),
    (20, 'Estado', 'Infoelectoral', 'https://infoelectoral.interior.gob.es/', 'Ministerio do Interior', 'Resultados oficiais das eleccións xerais (desde 1977), municipais (desde 1979) e europeas (desde 1987), por mesa, municipio e provincia.', 'Ficheiros de texto e Excel na área de descargas', 'Reutilización citando a fonte', 'Resultados das eleccións xerais, municipais e europeas.', '/gl/sociedad/elecciones'),
    -- Comunidades autónomas y ayuntamientos
    (30, 'Autonómico y local', 'Open Data Euskadi', 'https://opendata.euskadi.eus/', 'Goberno Vasco', 'Un dos portais de datos abertos pioneiros en España (2010): orzamentos, medio ambiente, transporte, cultura, calidade do aire e máis.', 'CSV, JSON, XML e API', 'Reutilización citando a fonte', NULL, NULL),
    (31, 'Autonómico y local', 'Datos abertos de Castela e León', 'https://datosabiertos.jcyl.es/', 'Xunta de Castela e León', 'Catálogo autonómico con datos de sanidade, educación, medio ambiente, emprego e rexistros administrativos.', 'CSV, JSON e API', 'Segundo cada conxunto', NULL, NULL),
    (32, 'Autonómico y local', 'Aragón Open Data', 'https://opendata.aragon.es/', 'Goberno de Aragón', 'Portal autonómico con catálogo de datos, datos ligados (Aragopedia) e análise da comunidade e dos seus municipios.', 'CSV, JSON, API e SPARQL', 'Segundo cada conxunto', NULL, NULL),
    (33, 'Autonómico y local', 'Datos abertos da Junta de Andalucía', 'https://www.juntadeandalucia.es/datosabiertos/portal.html', 'Junta de Andalucía', 'Catálogo de datos da administración andaluza: estatística, saúde, emprego, medio ambiente e servizos.', 'CSV, JSON, XML', 'Segundo cada conxunto', NULL, NULL),
    (34, 'Autonómico y local', 'Dades obertes de la Generalitat Valenciana', 'https://dadesobertes.gva.es/', 'Generalitat Valenciana', 'Datos da administración valenciana: sanidade, educación, medio ambiente, transporte e sector público.', 'CSV, JSON, XML', 'Segundo cada conxunto', NULL, NULL),
    (35, 'Autonómico y local', 'Dades obertes de Catalunya', 'https://analisi.transparenciacatalunya.cat/', 'Generalitat de Catalunya', 'Portal de datos abertos e transparencia da Generalitat, con visualizacións e consulta directa de cada conxunto.', 'CSV, JSON e API (Socrata)', 'Segundo cada conxunto', NULL, NULL),
    (36, 'Autonómico y local', 'Datos abertos da Comunidade de Madrid', 'https://datos.comunidad.madrid/', 'Comunidade de Madrid', 'Catálogo autonómico con datos de sanidade, educación, transporte, medio ambiente e estatística rexional.', 'CSV, JSON, XML', 'Segundo cada conxunto', NULL, NULL),
    (37, 'Autonómico y local', 'Portal de datos abertos do Concello de Madrid', 'https://datos.madrid.es/', 'Concello de Madrid', 'Tráfico en tempo real, calidade do aire, padrón, orzamentos, contratos, aparcadoiros, BiciMAD e centos de conxuntos máis.', 'CSV, JSON, XML e API', 'Reutilización citando a fonte', NULL, NULL),
    (38, 'Autonómico y local', 'Open Data BCN', 'https://opendata-ajuntament.barcelona.cat/', 'Concello de Barcelona', 'Datos de poboación, mobilidade, medio ambiente, economía, equipamentos e turismo de Barcelona.', 'CSV, JSON e API', 'CC BY 4.0', NULL, NULL),
    -- Sociedad civil
    (50, 'Sociedad civil', 'Civio', 'https://civio.es/', 'Fundación Ciudadana Civio', 'Fundación independente que vixía os poderes públicos con xornalismo de datos e ferramentas propias; publica o seu código en GitHub.', 'Buscadores e datos descargables nalgúns proxectos', 'Varía segundo o proxecto', NULL, NULL),
    (51, 'Sociedad civil', 'El BOE nuestro de cada día (Civio)', 'https://civio.es/el-boe-nuestro-de-cada-dia/', 'Fundación Ciudadana Civio', 'Explica cada día, en linguaxe clara, o máis relevante que publica o Boletín Oficial do Estado; inclúe o Decretómetro, que conta os decretos lei.', 'Artigos e visualizacións', 'Contidos de Civio', NULL, NULL),
    (52, 'Sociedad civil', '¿Dónde van mis impuestos? (Civio)', 'https://dondevanmisimpuestos.es/', 'Fundación Ciudadana Civio', 'Orzamentos do Estado, das comunidades e dos concellos explicados por política de gasto, coa súa evolución.', 'Visualizacións interactivas e descargas', 'Contidos de Civio', NULL, NULL),
    (53, 'Sociedad civil', 'El Indultómetro (Civio)', 'https://civio.es/justicia/buscador-de-indultos/', 'Fundación Ciudadana Civio', 'Buscador dos indultos concedidos en España a partir dos reais decretos publicados no BOE.', 'Buscador web', 'Contidos de Civio', NULL, NULL),
    (54, 'Sociedad civil', 'Medicamentalia (Civio)', 'https://medicamentalia.org/', 'Fundación Ciudadana Civio', 'Investigación internacional sobre o acceso a medicamentos, vacinas e anticonceptivos no mundo. Sen actualizar desde 2018.', 'Visualizacións e datos do proxecto', 'Contidos de Civio', NULL, NULL),
    (55, 'Sociedad civil', 'Access Info Europe', 'https://www.access-info.org/', 'Organización con sede en Madrid', 'Defende e promove o dereito de acceso á información pública en España e en Europa, con litixios, guías e seguimento da lei de transparencia.', 'Informes e guías', 'Contidos propios', NULL, NULL),
    (56, 'Sociedad civil', 'Transparencia Internacional España', 'https://transparencia.org.es/', 'Capítulo español de Transparency International', 'Publica en España o Índice de Percepción da Corrupción e avaliacións de transparencia de institucións e empresas.', 'Informes e índices', 'Contidos propios', NULL, NULL),
    (57, 'Sociedad civil', 'Fundación Hay Derecho', 'https://www.hayderecho.com/', 'Fundación Hay Derecho', 'Estudos sobre o Estado de dereito e a calidade institucional, como o Dedómetro, que analiza os nomeamentos no sector público.', 'Informes', 'Contidos propios', NULL, NULL),
    (58, 'Sociedad civil', 'Qué hacen los diputados', 'https://quehacenlosdiputados.es/', 'Political Watch', 'Segue todas as iniciativas do Congreso dos Deputados e clasifícaas por temas e por grupo parlamentario.', 'Web, API e código aberto', 'Consultar a web', NULL, NULL),
    (59, 'Sociedad civil', 'ObservatoriosPublicos.es', 'https://observatoriospublicos.es/', 'Jaime Gómez-Obregón (iniciativa persoal)', 'Censo dos observatorios públicos e público-privados de España, coa súa administración, ano de creación e estado; admite correccións da comunidade.', 'Web e código aberto en GitHub', 'Consultar a web', 'É a base da nosa análise dos observatorios públicos.', '/gl/varios/observatorios'),
    -- Periodismo de datos y verificación
    (70, 'Periodismo de datos', 'Maldita.es e Maldito Dato', 'https://maldita.es/malditodato/', 'Fundación Maldita.es', 'Verificación de datos e bulos; a sección Maldito Dato explica con cifras oficiais a actualidade política e económica.', 'Artigos e gráficos', 'Contidos propios', NULL, NULL),
    (71, 'Periodismo de datos', 'Newtral', 'https://www.newtral.es/', 'Newtral Media Audiovisual', 'Medio de verificación e xornalismo de datos que comproba declaracións públicas e explica os datos detrás da actualidade.', 'Artigos e gráficos', 'Contidos propios', NULL, NULL),
    (72, 'Periodismo de datos', 'Datadista', 'https://www.datadista.com/', 'Medio independente de xornalismo de datos', 'Investigacións de longo percorrido con datos (vivenda, sanidade, enerxía...); durante a pandemia publicou en GitHub series de datos da COVID-19 por comunidades autónomas.', 'Artigos e datos en GitHub', 'Consultar cada repositorio', NULL, NULL),
    (73, 'Periodismo de datos', 'EpData', 'https://www.epdata.es/', 'Europa Press', 'Portal de datos de Europa Press: gráficos de estatísticas públicas, listos para consultar e inserir noutras webs.', 'Gráficos e táboas insertables', 'Condicións de Europa Press', NULL, NULL),
    (60, 'Sociedad civil', 'Montera34', 'https://montera34.com/', 'Pablo Rey Mazón e Alfonso Sánchez Uzábal', 'Proxectos de datos como ben común feitos con software libre: visualización e análise de datos urbanos, segregación escolar, aluguer turístico e apertura de bases de datos municipais.', 'Visualizacións e código aberto', 'Consultar cada proxecto', NULL, NULL)
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

# 🔓 Datos abertos en España

Os **datos abertos** son información pública que calquera pode descargar, reutilizar e redistribuír sen pedir permiso, en formatos que un programa pode ler. Importan porque permiten comprobar o que din gobernos, partidos e empresas, porque a cidadanía e os medios poden facer as súas propias análises en lugar de depender de resumos alleos, e porque sobre eles se constrúen servizos útiles, investigación e empresas. SpainFacts existe grazas a eles: todas as nosas cifras saen de fontes públicas que calquera pode consultar.

Esta páxina reúne **{resumen[0].total} proxectos**: {resumen[0].estado} da Administración Xeral do Estado, {resumen[0].autonomico} portais autonómicos e municipais e {resumen[0].civil} iniciativas da sociedade civil e do xornalismo de datos. En **{resumen[0].usados}** deles ligámosche a páxina de SpainFacts onde os usamos.

<ButtonGroup name=tipo title="Tipo de proxecto">
    <ButtonGroupItem valueLabel="Todos" value="Todos" default />
    <ButtonGroupItem valueLabel="Estado" value="Estado" />
    <ButtonGroupItem valueLabel="Comunidades e concellos" value="Autonómico y local" />
    <ButtonGroupItem valueLabel="Sociedade civil" value="Sociedad civil" />
    <ButtonGroupItem valueLabel="Xornalismo de datos" value="Periodismo de datos" />
    <ButtonGroupItem valueLabel="Os que usa SpainFacts" value="Usados" />
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
            <span class="shrink-0 rounded-full bg-purple-50 dark:bg-purple-950/40 text-purple-700 dark:text-purple-300 text-xs font-semibold px-2 py-0.5">{etiquetasTipo[p.tipo] ?? p.tipo}</span>
        </div>
        <div class="text-xs text-gray-500 dark:text-gray-400">{p.quien}</div>
        <p class="text-sm text-gray-700 dark:text-gray-300 m-0">{p.que}</p>
        <div class="text-xs text-gray-600 dark:text-gray-400"><span class="font-semibold">Formato:</span> {p.formato} · <span class="font-semibold">Licenza:</span> {p.licencia}</div>
        {#if p.uso_url}
            <div class="mt-1 rounded-lg bg-purple-50/70 dark:bg-purple-950/30 border border-purple-200 dark:border-purple-800 px-3 py-2 text-xs text-purple-900 dark:text-purple-200">
                <span class="font-semibold">En SpainFacts:</span> {p.uso} <a href={p.uso_url} class="font-semibold text-purple-700 dark:text-purple-400">Ver a páxina →</a>
            </div>
        {/if}
    </div>
{/each}
</div>

---

## Como ler esta guía

- **Formato** indica como se obteñen os datos: unha **API** permite pedilos automaticamente desde un programa; os ficheiros **CSV**, **JSON** ou **XML** pódense abrir e procesar directamente; un **buscador web** só permite consultas manuais.
- **Licenza** resume as condicións de reutilización. En España, a información do sector público é reutilizable por norma xeral (Lei 37/2007 e Real decreto 1495/2011), coa obriga de citar a fonte e non desvirtuar os datos; cada portal detalla as súas condicións no seu aviso legal. Os proxectos da sociedade civil e os medios teñen as súas propias condicións.
- Os proxectos da sociedade civil e do xornalismo de datos inclúense polo seu labor de explicar ou vixiar datos públicos, sen que isto supoña respaldar as súas conclusións.

## Metodoloxía e fontes

Selección elaborada por SpainFacts cos principais portais públicos de datos e as iniciativas cidadás máis coñecidas; non pretende ser un censo completo. Todas as ligazóns se comprobaron en setembro de 2026. Os proxectos que xa non existen retiráronse e os que seguen en liña pero non se actualizan indícanse na súa descrición. O catálogo completo das fontes que usa este sitio, coa súa licenza e a súa metodoloxía, está en [Fontes](/gl/fuentes). Botas en falta algún proxecto? Consulta tamén os [exemplos inspiradores doutros países](/gl/varios/inspiracion-internacional).
