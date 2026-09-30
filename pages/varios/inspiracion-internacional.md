---
title: Ejemplos inspiradores de otros países
description: "Proyectos de datos abiertos y transparencia de otros países que sirven de modelo: USAFacts, Our World in Data, Gapminder, TheyWorkForYou, ProZorro, X-Road, g0v, Chequeado y más, con lo que España podría aprender de cada uno."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

```sql ejemplos
SELECT *
FROM (VALUES
    -- Estadística y divulgación
    (1, 'Estadística y divulgación', 'USAFacts', 'https://usafacts.org/', 'Estados Unidos', 'Organización sin ánimo de lucro fundada en 2017 por Steve Ballmer que reúne en un solo sitio los datos oficiales sobre población, economía, presupuesto y servicios públicos de Estados Unidos, sin opinión ni afiliación partidista.', 'Es la inspiración directa de SpainFacts: demuestra que se pueden contar las cuentas de un país con datos oficiales y de forma neutral, para cualquier ciudadano.', 'Un punto de entrada único y comprensible a las cifras públicas, en lugar de cientos de portales dispersos por organismo.', 'Inspiración directa de este sitio', '/'),
    (2, 'Estadística y divulgación', 'Our World in Data', 'https://ourworldindata.org/', 'Reino Unido (Universidad de Oxford)', 'Publicación de investigación del Global Change Data Lab y la Universidad de Oxford con miles de gráficos sobre salud, pobreza, energía, clima o educación en todos los países.', 'Cada gráfico lleva su fuente, su metodología y la descarga de los datos, y todo su contenido y su código son abiertos (CC BY).', 'Documentar cada cifra y permitir descargarla desde el propio gráfico.', 'SpainFacts usa sus series en la comparativa internacional', '/economia/turismo'),
    (3, 'Estadística y divulgación', 'Gapminder', 'https://www.gapminder.org/', 'Suecia', 'Fundación creada por Hans Rosling, Ola Rosling y Anna Rosling Rönnlund para combatir las ideas equivocadas sobre el mundo con estadísticas fáciles de entender.', 'Sus gráficos animados de burbujas y sus tests de conocimiento muestran que incluso la gente informada suele equivocarse sobre la evolución del mundo.', 'Medir los errores de percepción de la ciudadanía y diseñar la divulgación para corregirlos.', NULL, NULL),
    (4, 'Estadística y divulgación', 'Statistics Netherlands (CBS)', 'https://www.cbs.nl/', 'Países Bajos', 'Oficina estadística neerlandesa. Su banco de datos StatLine ofrece miles de tablas como datos abiertos, con una API OData.', 'Toda su información estadística se publica como datos abiertos, con API y bajo licencia CC BY 4.0.', 'API estándar y licencia abierta explícita para todas las tablas estadísticas.', NULL, NULL),
    (5, 'Estadística y divulgación', 'Statistics Norway (SSB)', 'https://www.ssb.no/', 'Noruega', 'Oficina estadística noruega. Su StatBank da acceso a las series oficiales, también mediante una API abierta y gratuita.', 'Combina estadísticas muy completas con una API sencilla y noticias que explican cada dato publicado.', 'Acompañar cada publicación estadística de una explicación breve y de los datos descargables.', NULL, NULL),
    (6, 'Estadística y divulgación', 'Stats NZ y data.govt.nz', 'https://www.stats.govt.nz/', 'Nueva Zelanda', 'La oficina estadística neozelandesa y el portal nacional de datos abiertos (data.govt.nz). Stats NZ gestiona la Integrated Data Infrastructure, que enlaza de forma anonimizada datos de distintas administraciones para investigación.', 'Permite a investigadores acreditados estudiar trayectorias reales (educación, empleo, salud, prestaciones) con garantías de privacidad.', 'Un entorno seguro para investigar con registros administrativos enlazados, sin exponer datos personales.', NULL, NULL),
    -- Portales de datos
    (10, 'Portales de datos', 'data.gov.sg', 'https://data.gov.sg/', 'Singapur', 'Portal de datos abiertos del Gobierno de Singapur, con APIs en tiempo real (meteorología, calidad del aire, transporte) además de miles de conjuntos de datos.', 'Pone el acento en APIs fiables y documentadas que los desarrolladores pueden usar directamente en sus servicios.', 'Priorizar datos en tiempo real con APIs estables y documentación clara.', NULL, NULL),
    (11, 'Portales de datos', 'data.europa.eu', 'https://data.europa.eu/', 'Unión Europea', 'Portal oficial de datos de la Unión Europea, que reúne los datos de las instituciones europeas y de los portales nacionales, entre ellos datos.gob.es. Publica cada año el informe Open Data Maturity.', 'Permite comparar el grado de apertura de cada país europeo con la misma metodología.', 'Usar esa comparación anual para fijar objetivos concretos de apertura.', 'SpainFacts usa Eurostat, la oficina estadística de la UE, en muchas comparativas', '/economia/paro'),
    -- Parlamento y política
    (20, 'Parlamento y política', 'TheyWorkForYou y mySociety', 'https://www.theyworkforyou.com/', 'Reino Unido', 'TheyWorkForYou, de la organización benéfica mySociety, muestra qué dice y qué vota cada parlamentario británico. mySociety también creó WhatDoTheyKnow (solicitudes de información pública hechas en abierto) y FixMyStreet (avisos de desperfectos urbanos).', 'Convierte los diarios de sesiones y las votaciones en fichas por diputado fáciles de seguir, con API y código abierto reutilizado en otros países.', 'Publicar votaciones nominales e intervenciones del Congreso y del Senado en formatos reutilizables.', NULL, NULL),
    (21, 'Parlamento y política', 'GovTrack.us', 'https://www.govtrack.us/', 'Estados Unidos', 'Web independiente que sigue desde 2004 las leyes y las votaciones del Congreso de Estados Unidos.', 'Permite seguir cada proyecto de ley, recibir avisos y ver estadísticas de actividad de cada congresista.', 'Seguimiento público y en tiempo real de la tramitación de cada ley.', NULL, NULL),
    (22, 'Parlamento y política', 'OpenSecrets', 'https://www.opensecrets.org/', 'Estados Unidos', 'Organización independiente que sigue el dinero en la política estadounidense: donaciones a campañas, gasto en lobby y patrimonio de los cargos electos.', 'Cruza fuentes oficiales dispersas para responder quién financia a quién.', 'Registros de grupos de interés y de financiación de partidos más completos y en formato abierto.', NULL, NULL),
    (23, 'Parlamento y política', 'abgeordnetenwatch.de', 'https://www.abgeordnetenwatch.de/', 'Alemania', 'Plataforma en la que cualquiera puede preguntar públicamente a sus diputados y consultar sus respuestas, votaciones e ingresos adicionales.', 'Las preguntas y respuestas quedan publicadas, lo que crea un registro permanente de lo que dice cada representante.', 'Un canal público de preguntas de la ciudadanía a sus representantes.', NULL, NULL),
    -- Contratación y gobierno digital
    (30, 'Contratación y gobierno digital', 'ProZorro', 'https://prozorro.gov.ua/', 'Ucrania', 'Sistema de contratación pública electrónica, obligatorio desde 2016, en el que todas las licitaciones y adjudicaciones se publican como datos abiertos según el estándar internacional OCDS.', 'Nació de la colaboración entre Gobierno, empresas y sociedad civil, y cualquiera puede vigilar los contratos, por ejemplo con la plataforma de seguimiento DOZORRO.', 'Publicar toda la contratación pública, de todas las administraciones, en un formato único y abierto.', NULL, NULL),
    (31, 'Contratación y gobierno digital', 'Open Contracting Partnership', 'https://www.open-contracting.org/', 'Internacional', 'Organización que impulsa la contratación pública abierta y mantiene el Open Contracting Data Standard (OCDS), usado por gobiernos de todo el mundo.', 'Un estándar común permite comparar contratos entre administraciones y países y detectar anomalías.', 'Adoptar un estándar común para los datos de contratación de todas las administraciones.', NULL, NULL),
    (32, 'Contratación y gobierno digital', 'X-Road', 'https://x-road.global/', 'Estonia', 'Capa de intercambio de datos entre administraciones que Estonia usa desde 2001, de código abierto y hoy mantenida por el Nordic Institute for Interoperability Solutions (NIIS).', 'Las administraciones se piden los datos entre sí de forma segura, así que el ciudadano no tiene que entregar dos veces el mismo documento, y cada acceso queda registrado, lo que permite a los estonios comprobar qué organismo ha consultado sus datos.', 'Interoperabilidad real entre administraciones y registro visible de quién consulta los datos de cada ciudadano.', NULL, NULL),
    (33, 'Contratación y gobierno digital', 'Code for America', 'https://codeforamerica.org/', 'Estados Unidos', 'Organización sin ánimo de lucro, fundada en 2009, que colabora con administraciones para que sus servicios digitales sean sencillos, por ejemplo con GetCalFresh para solicitar ayudas alimentarias en California.', 'Mide el éxito por lo fácil que resulta a la gente acceder a los servicios públicos.', 'Diseñar los trámites con los usuarios y medir cuántos los completan.', NULL, NULL),
    -- Tecnología cívica y gobierno abierto
    (40, 'Tecnología cívica', 'g0v y vTaiwan', 'https://g0v.tw/', 'Taiwán', 'Comunidad abierta de tecnología cívica nacida en 2012, que crea versiones más claras de webs y datos públicos. De ella salió vTaiwan, un proceso de consulta en línea que usó la herramienta Pol.is para buscar consensos sobre regulaciones digitales; su actividad ha sido más irregular en los últimos años.', 'Demuestra que la sociedad civil puede colaborar con el Gobierno para abrir datos y deliberar sobre políticas concretas.', 'Espacios estables de colaboración entre administraciones y comunidades de voluntarios.', NULL, NULL),
    (41, 'Tecnología cívica', 'Open Knowledge Foundation', 'https://okfn.org/', 'Internacional (Reino Unido)', 'Organización pionera del conocimiento abierto, fundada en 2004. Creó CKAN, el software de catálogos de datos que usan muchos portales públicos, y la Open Definition, que define qué es un dato abierto.', 'Ha puesto las bases técnicas y conceptuales de buena parte de los portales de datos del mundo.', 'Usar software y definiciones comunes en lugar de soluciones propietarias distintas en cada portal.', NULL, NULL),
    (42, 'Tecnología cívica', 'Open Government Partnership', 'https://www.opengovpartnership.org/', 'Internacional', 'Alianza de gobiernos y sociedad civil por el gobierno abierto. España participa desde 2011 con planes de acción que elaboran administraciones y organizaciones sociales.', 'Obliga a fijar compromisos concretos de transparencia y a someterlos a una evaluación independiente.', 'Compromisos medibles y evaluados de forma independiente.', NULL, NULL),
    (43, 'Tecnología cívica', 'Operação Serenata de Amor', 'https://serenata.ai/', 'Brasil', 'Proyecto de Open Knowledge Brasil nacido en 2016 que usa un sistema de inteligencia artificial (Rosie) para revisar los reembolsos de gastos de los diputados federales y señalar los sospechosos. Su código es abierto (licencia MIT); hoy se actualiza con menos frecuencia.', 'Mostró que unos pocos voluntarios con datos abiertos y código pueden auditar miles de gastos públicos.', 'Publicar los gastos de representación de los cargos públicos con detalle suficiente para poder auditarlos.', NULL, NULL),
    -- Verificación
    (50, 'Verificación', 'Full Fact', 'https://fullfact.org/', 'Reino Unido', 'Organización benéfica independiente de verificación de datos, que también desarrolla herramientas de inteligencia artificial para detectar afirmaciones que merece la pena verificar.', 'Además de verificar, pide correcciones a quien difundió el error y propone mejoras en cómo se publican las estadísticas.', 'Que los organismos corrijan públicamente cuando se usan mal sus datos.', NULL, NULL),
    (51, 'Verificación', 'Chequeado', 'https://chequeado.com/', 'Argentina', 'Medio sin ánimo de lucro fundado en 2010, pionero de la verificación de datos en América Latina, con herramientas propias como Chequeabot.', 'Combina verificación, periodismo de datos y educación, y comparte métodos y herramientas con medios de toda la región.', 'Colaboración entre verificadores y formación en el uso de datos públicos.', NULL, NULL)
) AS t(orden, tipo, nombre, url, pais, que, por_que, leccion, uso, uso_url)
ORDER BY orden
```

# 🌍 Ejemplos inspiradores de otros países

Muchos países llevan años publicando sus datos públicos de forma abierta y construyendo sobre ellos herramientas que cualquiera puede usar: para entender la economía, seguir el trabajo de los parlamentos, vigilar el dinero público o comprobar lo que dicen los políticos. Aquí reunimos **{ejemplos.length} proyectos** de gobiernos, fundaciones, medios y comunidades de voluntarios que sirven de modelo, con lo que cada uno aporta y lo que **España podría aprender** de él. SpainFacts nace precisamente de uno de ellos, USAFacts. Para los proyectos españoles, mira [Datos abiertos en España](/varios/datos-abiertos).

<ButtonGroup name=tipo title="Tipo de proyecto">
    <ButtonGroupItem valueLabel="Todos" value="Todos" default />
    <ButtonGroupItem valueLabel="Estadística y divulgación" value="Estadística y divulgación" />
    <ButtonGroupItem valueLabel="Portales de datos" value="Portales de datos" />
    <ButtonGroupItem valueLabel="Parlamento y política" value="Parlamento y política" />
    <ButtonGroupItem valueLabel="Contratación y gobierno digital" value="Contratación y gobierno digital" />
    <ButtonGroupItem valueLabel="Tecnología cívica" value="Tecnología cívica" />
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
        <div class="text-xs text-gray-500 dark:text-gray-400">{e.tipo}</div>
        <p class="text-sm text-gray-700 dark:text-gray-300 m-0">{e.que}</p>
        <p class="text-sm text-gray-700 dark:text-gray-300 m-0"><span class="font-semibold">Por qué inspira:</span> {e.por_que}</p>
        <div class="mt-1 rounded-lg bg-purple-50/70 dark:bg-purple-950/30 border border-purple-200 dark:border-purple-800 px-3 py-2 text-xs text-purple-900 dark:text-purple-200">
            <span class="font-semibold">Qué podría aprender España:</span> {e.leccion}
        </div>
        {#if e.uso_url}
            <div class="text-xs text-gray-600 dark:text-gray-400"><span class="font-semibold">En SpainFacts:</span> {e.uso}. <a href={e.uso_url} class="font-semibold text-purple-700 dark:text-purple-400">Ver →</a></div>
        {/if}
    </div>
{/each}
</div>

---

## Lo que tienen en común

- **Un solo sitio para cada pregunta.** Los mejores ejemplos no obligan a saber qué organismo publica cada dato: lo reúnen y lo explican.
- **Cada cifra con su fuente y su descarga.** Our World in Data, USAFacts o las oficinas estadísticas de Países Bajos y Noruega permiten llegar al dato original y reutilizarlo.
- **Estándares comunes.** OCDS en contratación, CKAN en catálogos o X-Road en el intercambio entre administraciones hacen que los datos de distintas fuentes encajen.
- **Colaboración con la sociedad civil.** ProZorro, g0v o mySociety muestran que los datos abiertos rinden más cuando administraciones, voluntarios, medios y universidades trabajan sobre ellos.

## Metodología y fuentes

Selección elaborada por SpainFacts con proyectos conocidos y consolidados de otros países; no es una clasificación ni un censo completo. La descripción de cada proyecto procede de su propia web. Todos los enlaces se comprobaron en septiembre de 2026; algunas webs (OpenSecrets, Open Government Partnership) bloquean las comprobaciones automáticas, pero son sus direcciones oficiales. Los proyectos cuya actividad ha disminuido lo indican en su descripción. Las lecciones para España son sugerencias de SpainFacts, no evaluaciones de ninguna administración concreta.
