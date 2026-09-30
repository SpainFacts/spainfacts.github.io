---
i18n_origen: 6594083ed575
title: Exemplos inspiradores doutros países
description: "Proxectos de datos abertos e transparencia doutros países que serven de modelo: USAFacts, Our World in Data, Gapminder, TheyWorkForYou, ProZorro, X-Road, g0v, Chequeado e máis, co que España podería aprender de cada un."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    const etiquetasTipo = {
        'Estadística y divulgación': 'Estatística e divulgación',
        'Portales de datos': 'Portais de datos',
        'Parlamento y política': 'Parlamento e política',
        'Contratación y gobierno digital': 'Contratación e goberno dixital',
        'Tecnología cívica': 'Tecnoloxía cívica',
        'Verificación': 'Verificación'
    };
</script>

```sql ejemplos
SELECT *
FROM (VALUES
    -- Estadística y divulgación
    (1, 'Estadística y divulgación', 'USAFacts', 'https://usafacts.org/', 'Estados Unidos', 'Organización sen ánimo de lucro fundada en 2017 por Steve Ballmer que reúne nun só sitio os datos oficiais sobre poboación, economía, orzamento e servizos públicos dos Estados Unidos, sen opinión nin afiliación partidista.', 'É a inspiración directa de SpainFacts: demostra que se poden contar as contas dun país con datos oficiais e de forma neutral, para calquera cidadán.', 'Un punto de entrada único e comprensible ás cifras públicas, en lugar de centos de portais dispersos por organismo.', 'Inspiración directa deste sitio', '/gl/'),
    (2, 'Estadística y divulgación', 'Our World in Data', 'https://ourworldindata.org/', 'Reino Unido (Universidade de Oxford)', 'Publicación de investigación do Global Change Data Lab e a Universidade de Oxford con miles de gráficos sobre saúde, pobreza, enerxía, clima ou educación en todos os países.', 'Cada gráfico leva a súa fonte, a súa metodoloxía e a descarga dos datos, e todo o seu contido e o seu código son abertos (CC BY).', 'Documentar cada cifra e permitir descargala desde o propio gráfico.', 'SpainFacts usa as súas series na comparativa internacional', '/gl/economia/turismo'),
    (3, 'Estadística y divulgación', 'Gapminder', 'https://www.gapminder.org/', 'Suecia', 'Fundación creada por Hans Rosling, Ola Rosling e Anna Rosling Rönnlund para combater as ideas equivocadas sobre o mundo con estatísticas doadas de entender.', 'Os seus gráficos animados de burbullas e os seus tests de coñecemento mostran que mesmo a xente informada adoita equivocarse sobre a evolución do mundo.', 'Medir os erros de percepción da cidadanía e deseñar a divulgación para corrixilos.', NULL, NULL),
    (4, 'Estadística y divulgación', 'Statistics Netherlands (CBS)', 'https://www.cbs.nl/', 'Países Baixos', 'Oficina estatística neerlandesa. O seu banco de datos StatLine ofrece miles de táboas como datos abertos, cunha API OData.', 'Toda a súa información estatística se publica como datos abertos, con API e baixo licenza CC BY 4.0.', 'API estándar e licenza aberta explícita para todas as táboas estatísticas.', NULL, NULL),
    (5, 'Estadística y divulgación', 'Statistics Norway (SSB)', 'https://www.ssb.no/', 'Noruega', 'Oficina estatística norueguesa. O seu StatBank dá acceso ás series oficiais, tamén mediante unha API aberta e gratuíta.', 'Combina estatísticas moi completas cunha API sinxela e noticias que explican cada dato publicado.', 'Acompañar cada publicación estatística dunha explicación breve e dos datos descargables.', NULL, NULL),
    (6, 'Estadística y divulgación', 'Stats NZ e data.govt.nz', 'https://www.stats.govt.nz/', 'Nova Zelandia', 'A oficina estatística neozelandesa e o portal nacional de datos abertos (data.govt.nz). Stats NZ xestiona a Integrated Data Infrastructure, que liga de forma anonimizada datos de distintas administracións para investigación.', 'Permite a investigadores acreditados estudar traxectorias reais (educación, emprego, saúde, prestacións) con garantías de privacidade.', 'Un contorno seguro para investigar con rexistros administrativos ligados, sen expor datos persoais.', NULL, NULL),
    -- Portales de datos
    (10, 'Portales de datos', 'data.gov.sg', 'https://data.gov.sg/', 'Singapur', 'Portal de datos abertos do Goberno de Singapur, con APIs en tempo real (meteoroloxía, calidade do aire, transporte) ademais de miles de conxuntos de datos.', 'Pon o acento en APIs fiables e documentadas que os desenvolvedores poden usar directamente nos seus servizos.', 'Priorizar datos en tempo real con APIs estables e documentación clara.', NULL, NULL),
    (11, 'Portales de datos', 'data.europa.eu', 'https://data.europa.eu/', 'Unión Europea', 'Portal oficial de datos da Unión Europea, que reúne os datos das institucións europeas e dos portais nacionais, entre eles datos.gob.es. Publica cada ano o informe Open Data Maturity.', 'Permite comparar o grao de apertura de cada país europeo coa mesma metodoloxía.', 'Usar esa comparación anual para fixar obxectivos concretos de apertura.', 'SpainFacts usa Eurostat, a oficina estatística da UE, en moitas comparativas', '/gl/economia/paro'),
    -- Parlamento y política
    (20, 'Parlamento y política', 'TheyWorkForYou e mySociety', 'https://www.theyworkforyou.com/', 'Reino Unido', 'TheyWorkForYou, da organización benéfica mySociety, mostra que di e que vota cada parlamentario británico. mySociety tamén creou WhatDoTheyKnow (solicitudes de información pública feitas en aberto) e FixMyStreet (avisos de desperfectos urbanos).', 'Converte os diarios de sesións e as votacións en fichas por deputado fáciles de seguir, con API e código aberto reutilizado noutros países.', 'Publicar votacións nominais e intervencións do Congreso e do Senado en formatos reutilizables.', NULL, NULL),
    (21, 'Parlamento y política', 'GovTrack.us', 'https://www.govtrack.us/', 'Estados Unidos', 'Web independente que segue desde 2004 as leis e as votacións do Congreso dos Estados Unidos.', 'Permite seguir cada proxecto de lei, recibir avisos e ver estatísticas de actividade de cada congresista.', 'Seguimento público e en tempo real da tramitación de cada lei.', NULL, NULL),
    (22, 'Parlamento y política', 'OpenSecrets', 'https://www.opensecrets.org/', 'Estados Unidos', 'Organización independente que segue o diñeiro na política estadounidense: doazóns a campañas, gasto en lobby e patrimonio dos cargos electos.', 'Cruza fontes oficiais dispersas para responder quen financia a quen.', 'Rexistros de grupos de interese e de financiamento de partidos máis completos e en formato aberto.', NULL, NULL),
    (23, 'Parlamento y política', 'abgeordnetenwatch.de', 'https://www.abgeordnetenwatch.de/', 'Alemaña', 'Plataforma na que calquera pode preguntarlles publicamente aos seus deputados e consultar as súas respostas, votacións e ingresos adicionais.', 'As preguntas e respostas quedan publicadas, o que crea un rexistro permanente do que di cada representante.', 'Unha canle pública de preguntas da cidadanía aos seus representantes.', NULL, NULL),
    -- Contratación y gobierno digital
    (30, 'Contratación y gobierno digital', 'ProZorro', 'https://prozorro.gov.ua/', 'Ucraína', 'Sistema de contratación pública electrónica, obrigatorio desde 2016, no que todas as licitacións e adxudicacións se publican como datos abertos segundo o estándar internacional OCDS.', 'Naceu da colaboración entre Goberno, empresas e sociedade civil, e calquera pode vixiar os contratos, por exemplo coa plataforma de seguimento DOZORRO.', 'Publicar toda a contratación pública, de todas as administracións, nun formato único e aberto.', NULL, NULL),
    (31, 'Contratación y gobierno digital', 'Open Contracting Partnership', 'https://www.open-contracting.org/', 'Internacional', 'Organización que impulsa a contratación pública aberta e mantén o Open Contracting Data Standard (OCDS), usado por gobernos de todo o mundo.', 'Un estándar común permite comparar contratos entre administracións e países e detectar anomalías.', 'Adoptar un estándar común para os datos de contratación de todas as administracións.', NULL, NULL),
    (32, 'Contratación y gobierno digital', 'X-Road', 'https://x-road.global/', 'Estonia', 'Capa de intercambio de datos entre administracións que Estonia usa desde 2001, de código aberto e hoxe mantida polo Nordic Institute for Interoperability Solutions (NIIS).', 'As administracións pídense os datos entre si de forma segura, así que o cidadán non ten que entregar dúas veces o mesmo documento, e cada acceso queda rexistrado, o que lles permite aos estonios comprobar que organismo consultou os seus datos.', 'Interoperabilidade real entre administracións e rexistro visible de quen consulta os datos de cada cidadán.', NULL, NULL),
    (33, 'Contratación y gobierno digital', 'Code for America', 'https://codeforamerica.org/', 'Estados Unidos', 'Organización sen ánimo de lucro, fundada en 2009, que colabora con administracións para que os seus servizos dixitais sexan sinxelos, por exemplo con GetCalFresh para solicitar axudas alimentarias en California.', 'Mide o éxito polo fácil que lle resulta á xente acceder aos servizos públicos.', 'Deseñar os trámites cos usuarios e medir cantos os completan.', NULL, NULL),
    -- Tecnología cívica y gobierno abierto
    (40, 'Tecnología cívica', 'g0v e vTaiwan', 'https://g0v.tw/', 'Taiwán', 'Comunidade aberta de tecnoloxía cívica nacida en 2012, que crea versións máis claras de webs e datos públicos. Dela saíu vTaiwan, un proceso de consulta en liña que usou a ferramenta Pol.is para buscar consensos sobre regulacións dixitais; a súa actividade foi máis irregular nos últimos anos.', 'Demostra que a sociedade civil pode colaborar co Goberno para abrir datos e deliberar sobre políticas concretas.', 'Espazos estables de colaboración entre administracións e comunidades de voluntarios.', NULL, NULL),
    (41, 'Tecnología cívica', 'Open Knowledge Foundation', 'https://okfn.org/', 'Internacional (Reino Unido)', 'Organización pioneira do coñecemento aberto, fundada en 2004. Creou CKAN, o software de catálogos de datos que usan moitos portais públicos, e a Open Definition, que define que é un dato aberto.', 'Puxo as bases técnicas e conceptuais de boa parte dos portais de datos do mundo.', 'Usar software e definicións comúns en lugar de solucións propietarias distintas en cada portal.', NULL, NULL),
    (42, 'Tecnología cívica', 'Open Government Partnership', 'https://www.opengovpartnership.org/', 'Internacional', 'Alianza de gobernos e sociedade civil polo goberno aberto. España participa desde 2011 con plans de acción que elaboran administracións e organizacións sociais.', 'Obriga a fixar compromisos concretos de transparencia e a sometelos a unha avaliación independente.', 'Compromisos medibles e avaliados de forma independente.', NULL, NULL),
    (43, 'Tecnología cívica', 'Operação Serenata de Amor', 'https://serenata.ai/', 'Brasil', 'Proxecto de Open Knowledge Brasil nacido en 2016 que usa un sistema de intelixencia artificial (Rosie) para revisar os reembolsos de gastos dos deputados federais e sinalar os sospeitosos. O seu código é aberto (licenza MIT); hoxe actualízase con menos frecuencia.', 'Mostrou que uns poucos voluntarios con datos abertos e código poden auditar miles de gastos públicos.', 'Publicar os gastos de representación dos cargos públicos con detalle suficiente para poder auditalos.', NULL, NULL),
    -- Verificación
    (50, 'Verificación', 'Full Fact', 'https://fullfact.org/', 'Reino Unido', 'Organización benéfica independente de verificación de datos, que tamén desenvolve ferramentas de intelixencia artificial para detectar afirmacións que paga a pena verificar.', 'Ademais de verificar, pídelle correccións a quen difundiu o erro e propón melloras en como se publican as estatísticas.', 'Que os organismos corrixan publicamente cando se usan mal os seus datos.', NULL, NULL),
    (51, 'Verificación', 'Chequeado', 'https://chequeado.com/', 'Arxentina', 'Medio sen ánimo de lucro fundado en 2010, pioneiro da verificación de datos en América Latina, con ferramentas propias como Chequeabot.', 'Combina verificación, xornalismo de datos e educación, e comparte métodos e ferramentas con medios de toda a rexión.', 'Colaboración entre verificadores e formación no uso de datos públicos.', NULL, NULL)
) AS t(orden, tipo, nombre, url, pais, que, por_que, leccion, uso, uso_url)
ORDER BY orden
```

# 🌍 Exemplos inspiradores doutros países

Moitos países levan anos publicando os seus datos públicos de forma aberta e construíndo sobre eles ferramentas que calquera pode usar: para entender a economía, seguir o traballo dos parlamentos, vixiar o diñeiro público ou comprobar o que din os políticos. Aquí reunimos **{ejemplos.length} proxectos** de gobernos, fundacións, medios e comunidades de voluntarios que serven de modelo, co que achega cada un e o que **España podería aprender** del. SpainFacts nace precisamente dun deles, USAFacts. Para os proxectos españois, mira [Datos abertos en España](/gl/varios/datos-abiertos).

<ButtonGroup name=tipo title="Tipo de proxecto">
    <ButtonGroupItem valueLabel="Todos" value="Todos" default />
    <ButtonGroupItem valueLabel="Estatística e divulgación" value="Estadística y divulgación" />
    <ButtonGroupItem valueLabel="Portais de datos" value="Portales de datos" />
    <ButtonGroupItem valueLabel="Parlamento e política" value="Parlamento y política" />
    <ButtonGroupItem valueLabel="Contratación e goberno dixital" value="Contratación y gobierno digital" />
    <ButtonGroupItem valueLabel="Tecnoloxía cívica" value="Tecnología cívica" />
    <ButtonGroupItem valueLabel="Verificación" value="Verificación" />
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
        <div class="text-xs text-gray-500 dark:text-gray-400">{etiquetasTipo[e.tipo] ?? e.tipo}</div>
        <p class="text-sm text-gray-700 dark:text-gray-300 m-0">{e.que}</p>
        <p class="text-sm text-gray-700 dark:text-gray-300 m-0"><span class="font-semibold">Por que inspira:</span> {e.por_que}</p>
        <div class="mt-1 rounded-lg bg-purple-50/70 dark:bg-purple-950/30 border border-purple-200 dark:border-purple-800 px-3 py-2 text-xs text-purple-900 dark:text-purple-200">
            <span class="font-semibold">Que podería aprender España:</span> {e.leccion}
        </div>
        {#if e.uso_url}
            <div class="text-xs text-gray-600 dark:text-gray-400"><span class="font-semibold">En SpainFacts:</span> {e.uso}. <a href={e.uso_url} class="font-semibold text-purple-700 dark:text-purple-400">Ver →</a></div>
        {/if}
    </div>
{/each}
</div>

---

## O que teñen en común

- **Un só sitio para cada pregunta.** Os mellores exemplos non obrigan a saber que organismo publica cada dato: reúneno e explícano.
- **Cada cifra coa súa fonte e a súa descarga.** Our World in Data, USAFacts ou as oficinas estatísticas dos Países Baixos e Noruega permiten chegar ao dato orixinal e reutilizalo.
- **Estándares comúns.** OCDS en contratación, CKAN en catálogos ou X-Road no intercambio entre administracións fan que os datos de distintas fontes encaixen.
- **Colaboración coa sociedade civil.** ProZorro, g0v ou mySociety mostran que os datos abertos renden máis cando administracións, voluntarios, medios e universidades traballan sobre eles.

## Metodoloxía e fontes

Selección elaborada por SpainFacts con proxectos coñecidos e consolidados doutros países; non é unha clasificación nin un censo completo. A descrición de cada proxecto procede da súa propia web. Todas as ligazóns se comprobaron en setembro de 2026; algunhas webs (OpenSecrets, Open Government Partnership) bloquean as comprobacións automáticas, pero son os seus enderezos oficiais. Os proxectos cuxa actividade diminuíu indícano na súa descrición. As leccións para España son suxestións de SpainFacts, non avaliacións de ningunha administración concreta.
