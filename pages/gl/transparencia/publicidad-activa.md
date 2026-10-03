---
i18n_origen: 3f26672a5738
title: Publicidade activa
description: "Publican as administracións nos seus portais de transparencia o que lles obriga a lei? Avaliacións oficiais por entidade (Consello de Transparencia e Bo Goberno e Comisionado de Transparencia de Canarias), a súa evolución, a comparación por partido e o que aínda non se pode medir."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql age
SELECT CAST(anio AS VARCHAR) AS anio, puntuacion AS icio, gobernante, familia, url_fuente
FROM mother.transparencia_publicidad_activa
WHERE tipo_administracion = 'Administración General del Estado'
ORDER BY anio
```

```sql ctbg_ccaa
SELECT entidad, familia,
    max(CASE WHEN anio = 2020 THEN puntuacion END) AS icio_2020,
    max(CASE WHEN anio = 2021 THEN puntuacion END) AS icio_2021,
    max(CASE WHEN anio = 2021 THEN puntuacion END) - max(CASE WHEN anio = 2020 THEN puntuacion END) AS mejora
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno' AND tipo_administracion = 'Comunidad autónoma'
GROUP BY entidad, familia
ORDER BY icio_2021 DESC
```

```sql ctbg_ccaa_largo
SELECT entidad, CAST(anio AS VARCHAR) AS evaluacion, puntuacion AS icio
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno' AND tipo_administracion = 'Comunidad autónoma'
ORDER BY entidad, anio
```

```sql ctbg_ayto
SELECT entidad,
    max(familia) FILTER (WHERE anio = 2021) AS familia,
    max(poblacion) AS poblacion,
    max(CASE WHEN anio = 2020 THEN puntuacion END) AS icio_2020,
    max(CASE WHEN anio = 2021 THEN puntuacion END) AS icio_2021,
    max(url_fuente) FILTER (WHERE anio = 2021) AS informe
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno' AND tipo_administracion = 'Ayuntamiento'
GROUP BY entidad
ORDER BY icio_2021 DESC
```

```sql ctbg_resumen
SELECT
    avg(puntuacion) FILTER (WHERE tipo_administracion = 'Comunidad autónoma' AND anio = 2021) AS media_ccaa,
    avg(puntuacion) FILTER (WHERE tipo_administracion = 'Ayuntamiento' AND anio = 2021) AS media_ayto,
    count(*) FILTER (WHERE tipo_administracion = 'Ayuntamiento' AND anio = 2021) AS n_ayto,
    count(*) FILTER (WHERE tipo_administracion = 'Ayuntamiento' AND anio = 2021 AND puntuacion < 50) AS ayto_menos_50
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Consejo de Transparencia y Buen Gobierno'
```

```sql itc
-- ITCanarias con etiqueta corta de periodo (los dos últimos no son años naturales)
SELECT *,
    CASE WHEN periodo LIKE '2022%' THEN '2022/23'
         WHEN periodo LIKE '%2023%2024%' THEN '2023/24'
         ELSE periodo END AS etiqueta
FROM mother.transparencia_publicidad_activa
WHERE evaluador = 'Comisionado de Transparencia de Canarias'
```

```sql itc_ultimo
SELECT max(orden_periodo) AS orden, max(etiqueta) FILTER (WHERE orden_periodo = (SELECT max(orden_periodo) FROM ${itc})) AS etiqueta
FROM ${itc}
```

```sql itc_evolucion
SELECT CAST(orden_periodo AS INTEGER) AS orden, etiqueta, tipo_administracion,
    avg(puntuacion) AS media,
    count(*) FILTER (WHERE estado = 'evaluada') AS evaluadas,
    count(*) FILTER (WHERE estado = 'incumplidora') AS incumplidoras
FROM ${itc}
WHERE tipo_administracion IN ('Ayuntamiento', 'Cabildo insular', 'Comunidad autónoma', 'Entes dependientes y otros')
GROUP BY ALL
ORDER BY orden, tipo_administracion
```

```sql itc_aytos_serie
SELECT CAST(orden_periodo AS INTEGER) AS orden, etiqueta,
    avg(puntuacion) AS media,
    median(puntuacion) AS mediana,
    quantile_cont(puntuacion, 0.25) AS p25,
    quantile_cont(puntuacion, 0.75) AS p75,
    count(*) FILTER (WHERE puntuacion >= 90) AS notable_alto,
    count(*) FILTER (WHERE puntuacion < 50 OR estado = 'incumplidora') AS suspenso,
    count(*) AS total
FROM ${itc}
WHERE tipo_administracion = 'Ayuntamiento'
GROUP BY ALL
ORDER BY orden
```

```sql itc_aytos_ultimo
SELECT
    cod_mun, entidad, regexp_replace(entidad, '^Ayuntamiento de ', '') AS municipio,
    CASE WHEN cod_prov = '35' THEN 'Las Palmas' ELSE 'Santa Cruz de Tenerife' END AS provincia,
    poblacion, estado, puntuacion, puntuacion_original, familia, gobernante,
    CASE WHEN estado = 'incumplidora' THEN 'No rindió la evaluación' ELSE 'Evaluado' END AS situacion
FROM ${itc}
WHERE tipo_administracion = 'Ayuntamiento' AND orden_periodo = (SELECT orden FROM ${itc_ultimo})
ORDER BY puntuacion DESC NULLS LAST
```

```sql itc_resumen
SELECT
    avg(puntuacion) AS media,
    count(*) FILTER (WHERE puntuacion >= 90) AS altos,
    count(*) FILTER (WHERE puntuacion < 50 OR estado = 'incumplidora') AS bajos,
    count(*) FILTER (WHERE estado = 'incumplidora') AS incumplidoras,
    count(*) AS total
FROM ${itc_aytos_ultimo}
```

```sql itc_institucionales
SELECT entidad, tipo_administracion,
    max(puntuacion) FILTER (WHERE orden_periodo = (SELECT orden FROM ${itc_ultimo})) AS ultima,
    max(puntuacion) FILTER (WHERE orden_periodo = 2) AS en_2017,
    max(familia) FILTER (WHERE orden_periodo = (SELECT orden FROM ${itc_ultimo})) AS familia
FROM ${itc}
WHERE tipo_administracion IN ('Cabildo insular', 'Comunidad autónoma')
GROUP BY ALL
ORDER BY ultima DESC
```

```sql itc_entes
SELECT tipo_entidad,
    count(*) AS entidades,
    avg(puntuacion) AS media,
    count(*) FILTER (WHERE estado = 'incumplidora') AS incumplidoras
FROM ${itc}
WHERE tipo_administracion = 'Entes dependientes y otros' AND orden_periodo = (SELECT orden FROM ${itc_ultimo})
GROUP BY tipo_entidad
HAVING count(*) >= 3
ORDER BY media
```

```sql itc_familia
-- Observado frente a esperado: el esperado de cada ayuntamiento y evaluación es la media
-- de los ayuntamientos canarios de su mismo tramo de población en esa misma evaluación.
-- El intervalo usa el número de municipios distintos (no de evaluaciones), porque el
-- mismo ayuntamiento aparece varios años y sus notas no son independientes.
WITH base AS (
    SELECT *,
        CASE WHEN poblacion < 5000 THEN 'a' WHEN poblacion < 20000 THEN 'b' ELSE 'c' END AS tramo
    FROM ${itc}
    WHERE tipo_administracion = 'Ayuntamiento' AND estado = 'evaluada'
),
esperado AS (
    SELECT *, avg(puntuacion) OVER (PARTITION BY orden_periodo, tramo) AS esperada
    FROM base
)
SELECT
    coalesce(familia, 'Sin atribuir') AS familia,
    count(*) AS evaluaciones,
    count(DISTINCT cod_mun) AS municipios,
    avg(puntuacion) AS observada,
    avg(esperada) AS esperada,
    avg(puntuacion - esperada) AS diferencia,
    avg(puntuacion - esperada) - 1.96 * stddev_samp(puntuacion - esperada) / sqrt(count(DISTINCT cod_mun)) AS ic_bajo,
    avg(puntuacion - esperada) + 1.96 * stddev_samp(puntuacion - esperada) / sqrt(count(DISTINCT cod_mun)) AS ic_alto,
    CASE
        WHEN count(DISTINCT cod_mun) < 10 THEN 'Muestra pequeña: no concluyente'
        WHEN avg(puntuacion - esperada) + 1.96 * stddev_samp(puntuacion - esperada) / sqrt(count(DISTINCT cod_mun)) < 0 THEN 'Por debajo de lo esperable'
        WHEN avg(puntuacion - esperada) - 1.96 * stddev_samp(puntuacion - esperada) / sqrt(count(DISTINCT cod_mun)) > 0 THEN 'Por encima de lo esperable'
        ELSE 'Dentro de lo esperable'
    END AS lectura
FROM esperado
GROUP BY ALL
HAVING count(*) >= 20
ORDER BY diferencia DESC
```

```sql itc_incumplidoras
SELECT etiqueta AS evaluacion, entidad, tipo_entidad, entidad_principal
FROM ${itc}
WHERE estado = 'incumplidora' AND orden_periodo >= (SELECT orden FROM ${itc_ultimo}) - 1
ORDER BY orden_periodo DESC, tipo_entidad, entidad
```

# 📋 Publicidade activa: publican as administracións o que lles obriga a lei?

Desde 2014, a [Lei 19/2013 de transparencia](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887) obriga todas as administracións a **publicar pola súa conta**, sen que ninguén o pida, unha lista de informacións no seu portal de transparencia: quen manda e canto cobra, que normas prepara, que contratos e subvencións concede, os seus orzamentos e contas, o seu patrimonio. É o que se chama **publicidade activa**. Esta páxina reúne as **avaliacións oficiais** que din, entidade por entidade, en que medida se cumpre.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">A resposta curta</p>
<p class="mb-1">Non existe unha avaliación <b>única e homoxénea</b> para todas as administracións de España. Cada órgano de control (o Consello de Transparencia e Bo Goberno e os consellos ou comisionados autonómicos) avalía o <b>seu ámbito</b>, co seu propio método e calendario, e case todos publican os resultados en informes en PDF ou Word, non en datos.</p>
<p class="mb-0">Con datos oficiais reutilizables pódese ver hoxe: o <b>Portal de Transparencia da Administración Xeral do Estado</b> (2021-2025), <b>oito comunidades e cidades autónomas</b> e <b>once concellos</b> avaliados polo Consello de Transparencia (2020-2021), e <b>todo o sector público de Canarias</b>, incluídos os seus 88 concellos, desde 2016. As puntuacións de avaliadores distintos <b>non son comparables entre si</b>.</p>
</div>

<Grid cols=4>
    <KpiCard
        title="Portal da AXE"
        value={age[age.length - 1]?.icio}
        formattedValue="{formatNumber(age[age.length - 1]?.icio, 1)} %"
        period="da información obrigatoria cumprida en {age[age.length - 1]?.anio} (ICIO)"
        source="Consello de Transparencia e Bo Goberno"
        sparklineData={age.map(d => d.icio)}
    />
    <KpiCard
        title="Comunidades avaliadas polo CTBG"
        value={ctbg_resumen[0]?.media_ccaa}
        formattedValue="{formatNumber(ctbg_resumen[0]?.media_ccaa, 1)} %"
        period="ICIO medio das 8 con convenio, revisión de 2021"
        source="Consello de Transparencia e Bo Goberno"
    />
    <KpiCard
        title="Concellos canarios"
        value={itc_resumen[0]?.media}
        formattedValue="{formatNumber(itc_resumen[0]?.media / 10, 2)} de 10"
        period="nota media no Índice de Transparencia de Canarias ({itc_ultimo[0]?.etiqueta})"
        source="Comisionado de Transparencia de Canarias"
        sparklineData={itc_aytos_serie.map(d => d.media / 10)}
    />
    <KpiCard
        title="Concellos canarios con nota baixa"
        value={itc_resumen[0]?.bajos}
        formattedValue={formatNumber(itc_resumen[0]?.bajos, 0)}
        period="de {formatNumber(itc_resumen[0]?.total, 0)}: por debaixo de 5 ou sen render a avaliación ({itc_ultimo[0]?.etiqueta})"
        sparklineData={itc_aytos_serie.map(d => d.suspenso)}
    />
</Grid>

## Que obriga a lei

A Lei 19/2013 (arts. 5 a 8) agrupa as obrigas en tres bloques, e as leis autonómicas de transparencia engaden outras para as súas administracións e concellos:

- **Información institucional, organizativa e de planificación**: funcións, normativa, organigrama, responsables e a súa traxectoria, plans e programas co seu grao de cumprimento.
- **Información de relevancia xurídica**: directrices e instrucións, anteproxectos de lei e proxectos de regulamento, memorias e informes dos expedientes normativos.
- **Información económica, orzamentaria e estatística**: contratos (incluídos os menores), convenios, encomendas, subvencións e axudas, orzamentos e a súa execución, contas e informes de auditoría, retribucións de altos cargos, compatibilidades, bens patrimoniais e estatísticas de calidade dos servizos.

A información debe ser **clara, estruturada, actualizada e reutilizable** (art. 5). Incumprir estas obrigas de forma reiterada é infracción grave segundo a lei estatal (art. 9.3), pero na práctica as sancións son excepcionais: os órganos de control **recomendan e avalían**, non multan.

## Quen avalía e que publica

| Órgano de control | A quen avalía | Que publica por entidade | Úsase aquí? |
|---|---|---|---|
| [Consello de Transparencia e Bo Goberno](https://consejodetransparencia.es/evaluacion) (CTBG) | AXE e sector público estatal, órganos constitucionais, partidos, sindicatos, entidades subvencionadas; e as comunidades e cidades autónomas con convenio (Asturias, Cantabria, Castela-A Mancha, Estremadura, A Rioxa, Ceuta e Melilla; Madrid en 2020-2021) e algúns dos seus concellos | Índice de Cumprimento da Información Obrigatoria (ICIO, 0-100 %, metodoloxía MESTA) nun informe Word por entidade; sen táboa de datos | Si: Portal da AXE, 8 comunidades e 11 concellos |
| [Comisionado de Transparencia de Canarias](https://transparenciacanarias.org/evaluacion/puntuaciones/) | Todo o sector público canario (Goberno, cabidos, concellos, universidades e os seus entes) e entidades privadas subvencionadas | Índice de Transparencia de Canarias (ITCanarias, 0-10) nunha táboa Excel con todas as entidades desde 2016 (CC BY 4.0) | Si: sector público |
| [Consello da Transparencia da Rexión de Murcia](https://comisionadotransparencia.carm.es/) | Administración rexional, concellos e o seu sector público (autoavaliación verificada, baseada en MESTA) | Informe executivo en PDF con resultados agregados por tipo de entidade; as notas por concello só aparecen en gráficos | Non: non hai datos por entidade reutilizables |
| [Síndic de Greuges de Catalunya](https://www.sindic.cat/) | Administracións catalás (Lei 19/2014) | Informe anual e informes individuais en PDF; índice de desenvolvemento da publicidade activa (IDPAC) en fase piloto desde 2024 | Non: informes en PDF por entidade, sen táboa |
| Consellos e comisionados de Andalucía, Aragón, Castela e León, Comunidade Valenciana, Galicia, Navarra, País Vasco e outros | A súa comunidade e as súas entidades locais | Memorias anuais, plans de control e inspección e resolucións, en PDF; non atopamos un índice de cumprimento publicado por entidade | Non |

Tamén hai rankings da sociedade civil (Dyntra, o Mapa Infoparticipa da Universitat Autònoma de Barcelona, os antigos índices de Transparencia Internacional España). **Non se usan aquí**: non son fontes oficiais e non comprobamos que a súa licenza permita reutilizar os datos.

## Administración Xeral do Estado

O CTBG avalía cada ano o [Portal da Transparencia](https://transparencia.gob.es/) da AXE. O ICIO mide, para cada obriga, se a información se publica e con que calidade (forma, data de actualización, accesibilidade, reutilización).

<LineChart
    data={age}
    x=anio
    y=icio
    yFmt=num1
    yMin=0
    yMax=100
    title="Portal da Transparencia da AXE: índice de cumprimento (%)"
    markers=true
    sort=false
/>

As cinco avaliacións corresponden a Gobernos de Pedro Sánchez, así que **non permiten comparar partidos** no Goberno central. O CTBG avalía ademais cada ano, por separado, centos de organismos, empresas e fundacións do sector público estatal; as súas notas están en informes individuais e aínda non se incorporaron.

## Comunidades autónomas e concellos avaliados polo CTBG

As comunidades que non crearon o seu propio órgano de control asinaron un convenio para que o CTBG vixíe a súa transparencia. En 2020 o CTBG avaliou os seus portais e en 2021 revisou se aplicaran as súas recomendacións.

<BarChart
    data={ctbg_ccaa_largo}
    x=entidad
    y=icio
    series=evaluacion
    type=grouped
    swapXY=true
    yFmt=num1
    yMax=100
    title="Índice de cumprimento da información obrigatoria (%)"
    sort=false
/>

<DataTable data={ctbg_ccaa} rows=all>
    <Column id=entidad title="Comunidade ou cidade autónoma" />
    <Column id=familia title="Partido do presidente" />
    <Column id=icio_2020 title="ICIO 2020 (%)" fmt=num1 />
    <Column id=icio_2021 title="ICIO 2021 (%)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=mejora title="Mellora (puntos)" fmt=num1 contentType=delta />
</DataTable>

Todas melloraron tras as recomendacións. Con só oito comunidades, gobernadas por catro partidos distintos, **non ten sentido comparar partidos**: calquera diferenza pode deberse a unha soa comunidade.

Os concellos avaliados polo CTBG son poucos e non forman unha mostra representativa (escolleunos o Consello). Aínda así, mostran o lonxe que pode quedar un concello grande de cumprir: {formatNumber(ctbg_resumen[0]?.ayto_menos_50, 0)} de {formatNumber(ctbg_resumen[0]?.n_ayto, 0)} seguían por debaixo do 50 % na revisión de 2021.

<DataTable data={ctbg_ayto} rows=all link=informe showLinkCol=false>
    <Column id=entidad title="Concello" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=familia title="Partido do alcalde (2021)" />
    <Column id=icio_2020 title="ICIO 2020 (%)" fmt=num1 />
    <Column id=icio_2021 title="ICIO 2021 (%)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
</DataTable>

## Canarias: todo o sector público, entidade por entidade

Canarias é a única comunidade que publica **cada ano e en datos abertos** a nota de todas as súas administracións. O Comisionado de Transparencia envía un cuestionario sobre as obrigas da lei canaria (máis esixente ca a estatal), comproba as respostas nos portais e calcula o Índice de Transparencia de Canarias (0 a 10). Unha entidade que non enche a avaliación figura como **incumpridora**.

<LineChart
    data={itc_evolucion}
    x=etiqueta
    y=media
    series=tipo_administracion
    yFmt=num1
    yMin=0
    yMax=100
    sort=false
    markers=true
    title="Índice de Transparencia de Canarias, nota media (sobre 100)"
/>

<p class="text-xs text-gray-500">As dúas últimas avaliacións non son anos naturais: «2022/23» abrangue 2022 e o primeiro semestre de 2023; «2023/24», o segundo semestre de 2023 e 2024. A nota móstrase sobre 100 para comparala coa escala da gráfica (7,5 de 10 = 75).</p>

A mellora é clara: a nota media dos concellos pasou de {formatNumber(itc_aytos_serie[0]?.media / 10, 1)} na primeira avaliación a {formatNumber(itc_aytos_serie[itc_aytos_serie.length - 1]?.media / 10, 1)} na última. Parte da subida reflicte que as entidades aprenden a responder o cuestionario, e moitas xa están no máximo, así que as notas altas distinguen pouco entre elas.

### Concellos, {itc_ultimo[0]?.etiqueta}

<MapaEspana
    data={itc_aytos_ultimo}
    geoJsonUrl="/geo/municipios/05.geojson"
    geoId="cod_mun"
    areaCol="cod_mun"
    value="puntuacion"
    valueFmt="num1"
    min={50}
    max={100}
    colorPalette={['#b91c1c', '#fde68a', '#15803d']}
    height={420}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Teselas © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Límites © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'municipio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'puntuacion', title: 'Nota (sobre 100)', fmt: 'num1'},
        {id: 'familia', title: 'Partido do alcalde'},
        {id: 'situacion', title: 'Situación'}
    ]}
/>

<p class="text-xs text-gray-500">A escala de cor comeza en 50: por debaixo, todos se ven en vermello. Un municipio en gris non rendeu a avaliación.</p>

<DataTable data={itc_aytos_ultimo} search=true rows=15>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=puntuacion_original title="Nota (0-10)" fmt=num2 contentType=colorscale colorMin=0 colorMax=10 />
    <Column id=situacion title="Situación" />
    <Column id=familia title="Partido do alcalde" />
</DataTable>

### Goberno de Canarias e cabidos

<DataTable data={itc_institucionales} rows=all>
    <Column id=entidad title="Entidade" />
    <Column id=tipo_administracion title="Tipo" />
    <Column id=en_2017 title="Nota 2017 (sobre 100)" fmt=num1 />
    <Column id=ultima title="Última nota (sobre 100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=familia title="Partido do presidente" />
</DataTable>

<p class="text-xs text-gray-500">Os cabidos non se atribúen a un partido: aínda non hai un rexistro oficial dos seus presidentes en SpainFacts.</p>

### Empresas, organismos e fundacións públicas

Onde máis se incumpre non é nas administracións, senón nos seus **entes dependentes**: empresas públicas, fundacións, consorcios e corporacións de dereito público, que tamén están obrigados.

<DataTable data={itc_entes} rows=all>
    <Column id=tipo_entidad title="Tipo de entidade" />
    <Column id=entidades title="Entidades" fmt=num0 />
    <Column id=media title="Nota media (sobre 100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=incumplidoras title="Non renderon a avaliación" fmt=num0 />
</DataTable>

<details>
<summary>Entidades que non renderon a avaliación nas dúas últimas edicións</summary>

<DataTable data={itc_incumplidoras} search=true rows=15>
    <Column id=evaluacion title="Avaliación" />
    <Column id=entidad title="Entidade" />
    <Column id=tipo_entidad title="Tipo" />
    <Column id=entidad_principal title="Depende de" />
</DataTable>

</details>

## Por partido

A comparación só é posible cos **concellos canarios**: son 88, avalíanse todos, co mesmo método, desde 2016. Para cada concello e avaliación calcúlase a nota **esperable**: a media dos concellos canarios do seu mesmo tamaño (menos de 5.000, de 5.000 a 20.000 e máis de 20.000 habitantes) nesa mesma avaliación. Despois compárase a nota media dos gobernados por cada partido coa súa esperable.

```sql itc_familia_grafico
SELECT familia, diferencia FROM ${itc_familia}
```

<BarChart
    data={itc_familia_grafico}
    x=familia
    y=diferencia
    swapXY=true
    yFmt=num1
    title="Nota observada menos esperable (puntos sobre 100)"
    fillColor="#0f766e"
    sort=false
/>

<DataTable data={itc_familia} rows=all>
    <Column id=familia title="Partido do alcalde" />
    <Column id=evaluaciones title="Avaliacións" fmt=num0 />
    <Column id=municipios title="Municipios distintos" fmt=num0 />
    <Column id=observada title="Nota media" fmt=num1 />
    <Column id=esperada title="Esperable" fmt=num1 />
    <Column id=diferencia title="Diferenza" fmt=num1 contentType=delta />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num1 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num1 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Só partidos con polo menos 20 avaliacións; os concellos que non renderon a avaliación non teñen nota e non entran no cálculo. O intervalo de confianza calcúlase co número de municipios distintos, non de avaliacións, porque as notas dun mesmo concello en anos seguidos non son independentes. «Sen detalle na fonte» agrupa alcaldías elixidas en listas que o rexistro oficial etiqueta de forma xenérica; «Independentes e locais», agrupacións de electores. Unha diferenza entre partidos non proba que se deba ao partido: inflúen o persoal, os medios técnicos, a illa e a persoa que goberna.</p>

Para as comunidades autónomas e o Goberno central **non hai mostra suficiente**: unha soa avaliación por comunidade e ano, e no caso do Estado un único Goberno en todo o período avaliado.

## Que falta

- **Non hai unha avaliación homoxénea para toda España.** Cada órgano de control avalía o seu ámbito co seu método: a nota dun concello canario (ITCanarias) e a dun cántabro (ICIO do CTBG) non se poden comparar.
- **A maioría dos órganos autonómicos non publica notas por entidade en datos abertos.** Murcia, Cataluña, Andalucía, Castela e León e outros publican memorias e informes en PDF, ás veces coas notas só en gráficos. Se algún publica os seus resultados por entidade nun formato reutilizable, incorporarase.
- **Os máis de 8.100 concellos de España non se avalían de forma sistemática**, agás en Canarias. O CTBG avaliou 11 en 2020-2021.
- **O sector público estatal** (organismos, empresas e fundacións) si ten nota por entidade nos informes do CTBG, pero en documentos individuais. En 2025 o CTBG avaliou 225 destas entidades, cun ICIO medio de só o 38,9 % ([nota do CTBG](https://consejodetransparencia.es/comunicacion/noticias/hemeroteca/2025/20251114)). É a próxima ampliación viable.
- As avaliacións miden **se a información está publicada e como**, non se é veraz nin completa no seu contido.

---

## Metodoloxía e fontes

- **[Consello de Transparencia e Bo Goberno – Avaliación](https://consejodetransparencia.es/evaluacion)**: Índice de Cumprimento da Información Obrigatoria (ICIO) da [metodoloxía MESTA](https://consejodetransparencia.es/content/dam/ctransparencia/portal-ctbg/publicaciones/documentacion/metodologia/MESTA-informefinal.pdf), lido do texto de cada **informe definitivo** (.docx): Portal da Transparencia da AXE (2021-2025), comunidades e cidades autónomas con convenio (avaliación de 2020 e revisión de 2021) e os seus concellos avaliados. O CTBG revisa directamente cada portal e puntúa, para cada obriga, se se publica o contido e os seus atributos de calidade (forma, actualización, accesibilidade, reutilización). Orixe dos datos: Consello de Transparencia e Bo Goberno (reutilización segundo a Lei 37/2007).
- **[Comisionado de Transparencia de Canarias – Puntuacións](https://transparenciacanarias.org/evaluacion/puntuaciones/)**: táboa mestra de puntuacións do sector público do Índice de Transparencia de Canarias (XLSX, [CC BY 4.0](https://transparenciacanarias.org/datos/)), desde a avaliación de 2016. Combina o cumprimento da información obrigatoria, a calidade do soporte web e a transparencia voluntaria ([metodoloxía](https://transparenciacanarias.org/evaluacion/sector-publico/metodologia/)). A entidade enche un cuestionario e o Comisionado verifícao. Móstrase sobre 100 (nota por 10) só para debuxala xunto ao ICIO; **as dúas escalas non son equivalentes**.
- **Municipios**: os nomes do Comisionado cásanse co código INE por nome (seis cunha forma distinta, a man). Poboación do padrón do INE do ano avaliado.
- **Atribución a partidos**: concellos, alcalde en funcións ao final do período avaliado segundo o [rexistro de alcaldes do Ministerio de Política Territorial](https://concejales.redsara.es/consulta/) (para a avaliación «2022/23», o 1 de xuño de 2023, antes das corporacións saídas das eleccións de maio); comunidades e Estado, presidente en funcións o 31 de decembro do ano avaliado (ITCanarias) ou o 30 de xuño do ano da avaliación (CTBG). Os partidos agrúpanse en familias políticas.
- **Obrigas legais**: arts. 5 a 9 da [Lei 19/2013, de transparencia, acceso á información pública e bo goberno](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887); en Canarias, a [Lei 12/2014, de transparencia e de acceso á información pública](https://www.boe.es/buscar/act.php?id=BOE-A-2015-1114).

<LastRefreshed prefix="Datos actualizados" />
