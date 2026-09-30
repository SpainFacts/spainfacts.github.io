---
title: Datos abiertos en España
description: "Guía de los proyectos de datos abiertos de España: portales y organismos públicos (INE, BOE, AEMET, REE, Catastro, Hacienda...), portales autonómicos y municipales, y proyectos de la sociedad civil y del periodismo de datos, con los que usa SpainFacts."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

```sql proyectos
SELECT *
FROM (VALUES
    -- Administración General del Estado
    (1, 'Estado', 'datos.gob.es', 'https://datos.gob.es/', 'Ministerio para la Transformación Digital y de la Función Pública (Iniciativa Aporta)', 'Catálogo nacional que reúne los conjuntos de datos abiertos de ministerios, comunidades, ayuntamientos y universidades, con guías y casos de reutilización.', 'Catálogo DCAT-AP-ES, API y SPARQL; formatos según el organismo', 'Según cada organismo publicador', NULL, NULL),
    (2, 'Estado', 'INE: INEbase y API JSON', 'https://www.ine.es/dyngs/DAB/index.htm?cid=1099', 'Instituto Nacional de Estadística', 'Todas las estadísticas oficiales del INE (IPC, EPA, padrón, PIB, nacimientos, turismo...) consultables en la web y por una API que devuelve JSON.', 'API JSON (Tempus3), PC-Axis, CSV, Excel', 'Reutilización libre citando la fuente', 'Es la fuente principal: IPC, paro (EPA), población, PIB y más de la mitad de las series del sitio.', '/economia/ipc'),
    (3, 'Estado', 'BOE: datos abiertos y API', 'https://www.boe.es/datosabiertos/api/api.php', 'Agencia Estatal Boletín Oficial del Estado', 'Sumarios diarios del BOE y del BORME y legislación consolidada, accesibles de forma automatizada.', 'API con respuesta XML o JSON', 'Reutilización libre citando la fuente', 'Enlazamos la normativa que explica las obligaciones de los ayuntamientos (no es fuente de datos).', '/transparencia/cuentas-municipales'),
    (4, 'Estado', 'AEMET OpenData', 'https://opendata.aemet.es/', 'Agencia Estatal de Meteorología', 'Observaciones, valores climatológicos diarios y mensuales, predicciones y avisos de todas las estaciones de AEMET.', 'API REST en JSON; requiere una clave gratuita', 'Reutilización citando a AEMET', 'Temperaturas diarias de las estaciones de referencia para el mapa del calor.', '/energia-clima/calor'),
    (5, 'Estado', 'REData (Red Eléctrica)', 'https://www.ree.es/es/datos/apidatos', 'Red Eléctrica de España', 'Generación por tecnología, demanda, intercambios, emisiones y balance eléctrico, nacional y por comunidad.', 'API REST en JSON, sin clave', 'Reutilización citando a Red Eléctrica', 'Mix de generación, emisiones del sector eléctrico y almacenamiento.', '/energia-clima/mix-electrico'),
    (6, 'Estado', 'ESIOS', 'https://www.esios.ree.es/', 'Red Eléctrica de España (operador del sistema)', 'Sistema de información del operador del sistema: precios, demanda y generación en tiempo real, cada pocos minutos.', 'API en JSON con token gratuito', 'Reutilización citando a Red Eléctrica', 'Datos en tiempo real y récords del sistema eléctrico.', '/energia-clima/records'),
    (7, 'Estado', 'CNMC Data', 'https://data.cnmc.es/', 'Comisión Nacional de los Mercados y la Competencia', 'Estadísticas de los mercados que supervisa la CNMC: energía, telecomunicaciones, audiovisual, postal y transporte.', 'Descargas y paneles interactivos', 'Consultar el aviso legal', NULL, NULL),
    (8, 'Estado', 'Sede Electrónica del Catastro', 'https://www.sedecatastro.gob.es/', 'Dirección General del Catastro (Ministerio de Hacienda)', 'Cartografía y datos de todos los inmuebles de España (salvo País Vasco y Navarra, con catastro propio): parcelas, edificios, superficies y usos.', 'Descarga masiva INSPIRE (GML), servicios de mapas WMS; los ficheros alfanuméricos requieren registro', 'Uso libre citando la fuente (datos no protegidos)', 'De forma indirecta: el índice de alquileres del Ministerio de Vivienda cruza IRPF y Catastro.', '/vivienda/alquiler'),
    (9, 'Estado', 'IGN y Centro de Descargas del CNIG', 'https://centrodedescargas.cnig.es/', 'Instituto Geográfico Nacional y Centro Nacional de Información Geográfica', 'Mapas topográficos, ortofotos (PNOA), modelos del terreno, límites administrativos y nomenclátor.', 'Shapefile, GeoPackage, GeoTIFF, LiDAR y servicios web', 'CC BY 4.0', 'Los límites de comunidades y provincias de los mapas.', '/energia-clima/calor'),
    (10, 'Estado', 'Plataforma de Contratación del Sector Público', 'https://contrataciondelestado.es/', 'Ministerio de Hacienda', 'Licitaciones, adjudicaciones y contratos de la Administración General del Estado y de muchas otras administraciones.', 'Datos abiertos sindicados (ATOM con XML CODICE)', 'Reutilización libre citando la fuente', NULL, NULL),
    (11, 'Estado', 'Base de Datos Nacional de Subvenciones (BDNS)', 'https://www.infosubvenciones.es/', 'Intervención General de la Administración del Estado (Ministerio de Hacienda)', 'Convocatorias y concesiones de subvenciones y ayudas públicas de todas las administraciones, con beneficiario e importe.', 'Buscador web con exportación de resultados', 'Consultar el aviso legal', NULL, NULL),
    (12, 'Estado', 'Portal de la Transparencia', 'https://transparencia.gob.es/', 'Administración General del Estado (Ministerio para la Transformación Digital y de la Función Pública)', 'Publicidad activa de la Administración General del Estado (organización, altos cargos, contratos, convenios, presupuestos) y el canal para ejercer el derecho de acceso a la información.', 'Páginas web y descargas', 'Ley 19/2013 de transparencia', NULL, NULL),
    (13, 'Estado', 'Banco de España: estadísticas', 'https://www.bde.es/wbe/es/estadisticas/', 'Banco de España', 'Boletín Estadístico con series de tipos de interés, crédito, balanza de pagos y deuda de las administraciones públicas.', 'Series descargables en CSV y Excel', 'Reutilización citando la fuente', 'Deuda de las administraciones públicas y de los ayuntamientos.', '/territorios/municipios'),
    (14, 'Estado', 'SEPE: datos abiertos', 'https://sede.sepe.gob.es/portalSede/datos-abiertos.html', 'Servicio Público de Empleo Estatal', 'Paro registrado, contratos y prestaciones por desempleo, con detalle mensual por municipio.', 'CSV y Excel', 'Reutilización citando la fuente', 'Paro registrado por municipio y provincia.', '/economia/paro'),
    (15, 'Estado', 'DGT en cifras', 'https://www.dgt.es/menusecundario/dgt-en-cifras/', 'Dirección General de Tráfico', 'Microdatos de matriculaciones, bajas, transferencias y parque de vehículos, además de estadísticas de siniestralidad y conductores.', 'Ficheros de texto de ancho fijo (MATRABA) y tablas', 'Reutilización citando la fuente', 'Matriculaciones, coche eléctrico y parque de vehículos.', '/movilidad/parque'),
    (16, 'Estado', 'Punto de Acceso Nacional de tráfico y movilidad (NAP)', 'https://nap.dgt.es/', 'DGT y Ministerio de Transportes', 'Datos de tráfico, incidencias, puntos de recarga eléctrica y otros servicios de movilidad, según la normativa europea de transporte inteligente.', 'DATEX II, JSON y CSV', 'Según cada conjunto', 'Puntos de recarga para coches eléctricos.', '/movilidad/recarga'),
    (17, 'Estado', 'MITECO', 'https://www.miteco.gob.es/', 'Ministerio para la Transición Ecológica y el Reto Demográfico', 'Boletín hidrológico de embalses, inventario de emisiones de gases de efecto invernadero, calidad del aire, cartografía ambiental y energía.', 'Excel, CSV, Access y servicios cartográficos', 'Reutilización citando la fuente', 'Reserva de los embalses y emisiones de gases de efecto invernadero.', '/energia-clima/embalses'),
    (18, 'Estado', 'Hacienda: CONPREL (presupuestos y liquidaciones locales)', 'https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL', 'Secretaría General de Financiación Autonómica y Local (Ministerio de Hacienda)', 'Presupuestos y liquidaciones de todos los ayuntamientos, diputaciones y comunidades, por capítulo y por política de gasto.', 'Consulta web y descarga en Access o Excel', 'Reutilización citando la fuente', 'Gasto e ingresos por habitante de cada municipio y quién no envía sus cuentas.', '/transparencia/cuentas-municipales'),
    (19, 'Estado', 'Plataforma de Rendición de Cuentas', 'https://www.rendiciondecuentas.es/', 'Tribunal de Cuentas y órganos de control externo autonómicos', 'Estado de rendición de la Cuenta General de cada entidad local y consulta de las cuentas presentadas.', 'Consulta web', 'Consultar el aviso legal', 'Qué ayuntamientos presentan a tiempo su Cuenta General.', '/transparencia/cuentas-municipales'),
    (20, 'Estado', 'Infoelectoral', 'https://infoelectoral.interior.gob.es/', 'Ministerio del Interior', 'Resultados oficiales de las elecciones generales (desde 1977), municipales (desde 1979) y europeas (desde 1987), por mesa, municipio y provincia.', 'Ficheros de texto y Excel en el área de descargas', 'Reutilización citando la fuente', 'Resultados de las elecciones generales, municipales y europeas.', '/sociedad/elecciones'),
    -- Comunidades autónomas y ayuntamientos
    (30, 'Autonómico y local', 'Open Data Euskadi', 'https://opendata.euskadi.eus/', 'Gobierno Vasco', 'Uno de los portales de datos abiertos pioneros en España (2010): presupuestos, medio ambiente, transporte, cultura, calidad del aire y más.', 'CSV, JSON, XML y API', 'Reutilización citando la fuente', NULL, NULL),
    (31, 'Autonómico y local', 'Datos abiertos de Castilla y León', 'https://datosabiertos.jcyl.es/', 'Junta de Castilla y León', 'Catálogo autonómico con datos de sanidad, educación, medio ambiente, empleo y registros administrativos.', 'CSV, JSON y API', 'Según cada conjunto', NULL, NULL),
    (32, 'Autonómico y local', 'Aragón Open Data', 'https://opendata.aragon.es/', 'Gobierno de Aragón', 'Portal autonómico con catálogo de datos, datos enlazados (Aragopedia) y análisis de la comunidad y de sus municipios.', 'CSV, JSON, API y SPARQL', 'Según cada conjunto', NULL, NULL),
    (33, 'Autonómico y local', 'Datos abiertos de la Junta de Andalucía', 'https://www.juntadeandalucia.es/datosabiertos/portal.html', 'Junta de Andalucía', 'Catálogo de datos de la administración andaluza: estadística, salud, empleo, medio ambiente y servicios.', 'CSV, JSON, XML', 'Según cada conjunto', NULL, NULL),
    (34, 'Autonómico y local', 'Dades obertes de la Generalitat Valenciana', 'https://dadesobertes.gva.es/', 'Generalitat Valenciana', 'Datos de la administración valenciana: sanidad, educación, medio ambiente, transporte y sector público.', 'CSV, JSON, XML', 'Según cada conjunto', NULL, NULL),
    (35, 'Autonómico y local', 'Dades obertes de Catalunya', 'https://analisi.transparenciacatalunya.cat/', 'Generalitat de Catalunya', 'Portal de datos abiertos y transparencia de la Generalitat, con visualizaciones y consulta directa de cada conjunto.', 'CSV, JSON y API (Socrata)', 'Según cada conjunto', NULL, NULL),
    (36, 'Autonómico y local', 'Datos abiertos de la Comunidad de Madrid', 'https://datos.comunidad.madrid/', 'Comunidad de Madrid', 'Catálogo autonómico con datos de sanidad, educación, transporte, medio ambiente y estadística regional.', 'CSV, JSON, XML', 'Según cada conjunto', NULL, NULL),
    (37, 'Autonómico y local', 'Portal de datos abiertos del Ayuntamiento de Madrid', 'https://datos.madrid.es/', 'Ayuntamiento de Madrid', 'Tráfico en tiempo real, calidad del aire, padrón, presupuestos, contratos, aparcamientos, BiciMAD y cientos de conjuntos más.', 'CSV, JSON, XML y API', 'Reutilización citando la fuente', NULL, NULL),
    (38, 'Autonómico y local', 'Open Data BCN', 'https://opendata-ajuntament.barcelona.cat/', 'Ajuntament de Barcelona', 'Datos de población, movilidad, medio ambiente, economía, equipamientos y turismo de Barcelona.', 'CSV, JSON y API', 'CC BY 4.0', NULL, NULL),
    -- Sociedad civil
    (50, 'Sociedad civil', 'Civio', 'https://civio.es/', 'Fundación Ciudadana Civio', 'Fundación independiente que vigila a los poderes públicos con periodismo de datos y herramientas propias; publica su código en GitHub.', 'Buscadores y datos descargables en algunos proyectos', 'Varía según el proyecto', NULL, NULL),
    (51, 'Sociedad civil', 'El BOE nuestro de cada día (Civio)', 'https://civio.es/el-boe-nuestro-de-cada-dia/', 'Fundación Ciudadana Civio', 'Explica cada día, en lenguaje claro, lo más relevante que publica el Boletín Oficial del Estado; incluye el Decretómetro, que cuenta los decretos ley.', 'Artículos y visualizaciones', 'Contenidos de Civio', NULL, NULL),
    (52, 'Sociedad civil', '¿Dónde van mis impuestos? (Civio)', 'https://dondevanmisimpuestos.es/', 'Fundación Ciudadana Civio', 'Presupuestos del Estado, de las comunidades y de los ayuntamientos explicados por política de gasto, con su evolución.', 'Visualizaciones interactivas y descargas', 'Contenidos de Civio', NULL, NULL),
    (53, 'Sociedad civil', 'El Indultómetro (Civio)', 'https://civio.es/justicia/buscador-de-indultos/', 'Fundación Ciudadana Civio', 'Buscador de los indultos concedidos en España a partir de los reales decretos publicados en el BOE.', 'Buscador web', 'Contenidos de Civio', NULL, NULL),
    (54, 'Sociedad civil', 'Medicamentalia (Civio)', 'https://medicamentalia.org/', 'Fundación Ciudadana Civio', 'Investigación internacional sobre el acceso a medicamentos, vacunas y anticonceptivos en el mundo. Sin actualizar desde 2018.', 'Visualizaciones y datos del proyecto', 'Contenidos de Civio', NULL, NULL),
    (55, 'Sociedad civil', 'Access Info Europe', 'https://www.access-info.org/', 'Organización con sede en Madrid', 'Defiende y promueve el derecho de acceso a la información pública en España y en Europa, con litigios, guías y seguimiento de la ley de transparencia.', 'Informes y guías', 'Contenidos propios', NULL, NULL),
    (56, 'Sociedad civil', 'Transparencia Internacional España', 'https://transparencia.org.es/', 'Capítulo español de Transparency International', 'Publica en España el Índice de Percepción de la Corrupción y evaluaciones de transparencia de instituciones y empresas.', 'Informes e índices', 'Contenidos propios', NULL, NULL),
    (57, 'Sociedad civil', 'Fundación Hay Derecho', 'https://www.hayderecho.com/', 'Fundación Hay Derecho', 'Estudios sobre el Estado de derecho y la calidad institucional, como el Dedómetro, que analiza los nombramientos en el sector público.', 'Informes', 'Contenidos propios', NULL, NULL),
    (58, 'Sociedad civil', 'Qué hacen los diputados', 'https://quehacenlosdiputados.es/', 'Political Watch', 'Sigue todas las iniciativas del Congreso de los Diputados y las clasifica por temas y por grupo parlamentario.', 'Web, API y código abierto', 'Consultar la web', NULL, NULL),
    (59, 'Sociedad civil', 'ObservatoriosPublicos.es', 'https://observatoriospublicos.es/', 'Jaime Gómez-Obregón (iniciativa personal)', 'Censo de los observatorios públicos y público-privados de España, con su administración, año de creación y estado; admite correcciones de la comunidad.', 'Web y código abierto en GitHub', 'Consultar la web', 'Es la base de nuestro análisis de los observatorios públicos.', '/varios/observatorios'),
    -- Periodismo de datos y verificación
    (70, 'Periodismo de datos', 'Maldita.es y Maldito Dato', 'https://maldita.es/malditodato/', 'Fundación Maldita.es', 'Verificación de datos y bulos; la sección Maldito Dato explica con cifras oficiales la actualidad política y económica.', 'Artículos y gráficos', 'Contenidos propios', NULL, NULL),
    (71, 'Periodismo de datos', 'Newtral', 'https://www.newtral.es/', 'Newtral Media Audiovisual', 'Medio de verificación y periodismo de datos que comprueba declaraciones públicas y explica los datos detrás de la actualidad.', 'Artículos y gráficos', 'Contenidos propios', NULL, NULL),
    (72, 'Periodismo de datos', 'Datadista', 'https://www.datadista.com/', 'Medio independiente de periodismo de datos', 'Investigaciones de largo recorrido con datos (vivienda, sanidad, energía...); durante la pandemia publicó en GitHub series de datos de COVID-19 por comunidades autónomas.', 'Artículos y datos en GitHub', 'Consultar cada repositorio', NULL, NULL),
    (73, 'Periodismo de datos', 'EpData', 'https://www.epdata.es/', 'Europa Press', 'Portal de datos de Europa Press: gráficos de estadísticas públicas, listos para consultar e insertar en otras webs.', 'Gráficos y tablas insertables', 'Condiciones de Europa Press', NULL, NULL),
    (60, 'Sociedad civil', 'Montera34', 'https://montera34.com/', 'Pablo Rey Mazón y Alfonso Sánchez Uzábal', 'Proyectos de datos como bien común hechos con software libre: visualización y análisis de datos urbanos, segregación escolar, alquiler turístico y apertura de bases de datos municipales.', 'Visualizaciones y código abierto', 'Consultar cada proyecto', NULL, NULL)
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

# 🔓 Datos abiertos en España

Los **datos abiertos** son información pública que cualquiera puede descargar, reutilizar y redistribuir sin pedir permiso, en formatos que un programa puede leer. Importan porque permiten comprobar lo que dicen gobiernos, partidos y empresas, porque la ciudadanía y los medios pueden hacer sus propios análisis en lugar de depender de resúmenes ajenos, y porque sobre ellos se construyen servicios útiles, investigación y empresas. SpainFacts existe gracias a ellos: todas nuestras cifras salen de fuentes públicas que cualquiera puede consultar.

Esta página reúne **{resumen[0].total} proyectos**: {resumen[0].estado} de la Administración General del Estado, {resumen[0].autonomico} portales autonómicos y municipales y {resumen[0].civil} iniciativas de la sociedad civil y del periodismo de datos. En **{resumen[0].usados}** de ellos te enlazamos la página de SpainFacts donde los usamos.

<ButtonGroup name=tipo title="Tipo de proyecto">
    <ButtonGroupItem valueLabel="Todos" value="Todos" default />
    <ButtonGroupItem valueLabel="Estado" value="Estado" />
    <ButtonGroupItem valueLabel="Comunidades y ayuntamientos" value="Autonómico y local" />
    <ButtonGroupItem valueLabel="Sociedad civil" value="Sociedad civil" />
    <ButtonGroupItem valueLabel="Periodismo de datos" value="Periodismo de datos" />
    <ButtonGroupItem valueLabel="Los que usa SpainFacts" value="Usados" />
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
            <span class="shrink-0 rounded-full bg-purple-50 dark:bg-purple-950/40 text-purple-700 dark:text-purple-300 text-xs font-semibold px-2 py-0.5">{p.tipo}</span>
        </div>
        <div class="text-xs text-gray-500 dark:text-gray-400">{p.quien}</div>
        <p class="text-sm text-gray-700 dark:text-gray-300 m-0">{p.que}</p>
        <div class="text-xs text-gray-600 dark:text-gray-400"><span class="font-semibold">Formato:</span> {p.formato} · <span class="font-semibold">Licencia:</span> {p.licencia}</div>
        {#if p.uso_url}
            <div class="mt-1 rounded-lg bg-purple-50/70 dark:bg-purple-950/30 border border-purple-200 dark:border-purple-800 px-3 py-2 text-xs text-purple-900 dark:text-purple-200">
                <span class="font-semibold">En SpainFacts:</span> {p.uso} <a href={p.uso_url} class="font-semibold text-purple-700 dark:text-purple-400">Ver la página →</a>
            </div>
        {/if}
    </div>
{/each}
</div>

---

## Cómo leer esta guía

- **Formato** indica cómo se obtienen los datos: una **API** permite pedirlos automáticamente desde un programa; los ficheros **CSV**, **JSON** o **XML** se pueden abrir y procesar directamente; un **buscador web** solo permite consultas manuales.
- **Licencia** resume las condiciones de reutilización. En España, la información del sector público es reutilizable por norma general (Ley 37/2007 y Real Decreto 1495/2011), con la obligación de citar la fuente y no desvirtuar los datos; cada portal detalla sus condiciones en su aviso legal. Los proyectos de la sociedad civil y los medios tienen sus propias condiciones.
- Los proyectos de la sociedad civil y del periodismo de datos se incluyen por su labor de explicar o vigilar datos públicos, sin que ello suponga respaldar sus conclusiones.

## Metodología y fuentes

Selección elaborada por SpainFacts con los principales portales públicos de datos y las iniciativas ciudadanas más conocidas; no pretende ser un censo completo. Todos los enlaces se comprobaron en septiembre de 2026. Los proyectos que ya no existen se han retirado y los que siguen en línea pero no se actualizan se indican en su descripción. El catálogo completo de las fuentes que usa este sitio, con su licencia y su metodología, está en [Fuentes](/fuentes). ¿Echas en falta algún proyecto? Consulta también los [ejemplos inspiradores de otros países](/varios/inspiracion-internacional).
