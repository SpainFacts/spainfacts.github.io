---
title: Publicidad activa
description: "¿Publican las administraciones en sus portales de transparencia lo que les obliga la ley? Evaluaciones oficiales por entidad (Consejo de Transparencia y Buen Gobierno y Comisionado de Transparencia de Canarias), su evolución, la comparación por partido y lo que todavía no se puede medir."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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

# 📋 Publicidad activa: ¿publican las administraciones lo que les obliga la ley?

Desde 2014, la [Ley 19/2013 de transparencia](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887) obliga a todas las administraciones a **publicar por su cuenta**, sin que nadie lo pida, una lista de informaciones en su portal de transparencia: quién manda y cuánto cobra, qué normas prepara, qué contratos y subvenciones concede, sus presupuestos y cuentas, su patrimonio. Es lo que se llama **publicidad activa**. Esta página reúne las **evaluaciones oficiales** que dicen, entidad por entidad, en qué medida se cumple.

<div class="not-prose rounded-lg border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 p-4 my-4 text-sm text-gray-700 dark:text-gray-300">
<p class="font-semibold mb-1">La respuesta corta</p>
<p class="mb-1">No existe una evaluación <b>única y homogénea</b> para todas las administraciones de España. Cada órgano de control (el Consejo de Transparencia y Buen Gobierno y los consejos o comisionados autonómicos) evalúa a <b>su ámbito</b>, con su propio método y calendario, y casi todos publican los resultados en informes en PDF o Word, no en datos.</p>
<p class="mb-0">Con datos oficiales reutilizables se puede ver hoy: el <b>Portal de Transparencia de la Administración General del Estado</b> (2021-2025), <b>ocho comunidades y ciudades autónomas</b> y <b>once ayuntamientos</b> evaluados por el Consejo de Transparencia (2020-2021), y <b>todo el sector público de Canarias</b>, incluidos sus 88 ayuntamientos, desde 2016. Las puntuaciones de evaluadores distintos <b>no son comparables entre sí</b>.</p>
</div>

<Grid cols=4>
    <KpiCard
        title="Portal de la AGE"
        value={age[age.length - 1]?.icio}
        formattedValue="{formatNumber(age[age.length - 1]?.icio, 1)} %"
        period="de la información obligatoria cumplida en {age[age.length - 1]?.anio} (ICIO)"
        source="Consejo de Transparencia y Buen Gobierno"
        sparklineData={age.map(d => d.icio)}
    />
    <KpiCard
        title="Comunidades evaluadas por el CTBG"
        value={ctbg_resumen[0]?.media_ccaa}
        formattedValue="{formatNumber(ctbg_resumen[0]?.media_ccaa, 1)} %"
        period="ICIO medio de las 8 con convenio, revisión de 2021"
        source="Consejo de Transparencia y Buen Gobierno"
    />
    <KpiCard
        title="Ayuntamientos canarios"
        value={itc_resumen[0]?.media}
        formattedValue="{formatNumber(itc_resumen[0]?.media / 10, 2)} de 10"
        period="nota media en el Índice de Transparencia de Canarias ({itc_ultimo[0]?.etiqueta})"
        source="Comisionado de Transparencia de Canarias"
        sparklineData={itc_aytos_serie.map(d => d.media / 10)}
    />
    <KpiCard
        title="Ayuntamientos canarios con nota baja"
        value={itc_resumen[0]?.bajos}
        formattedValue={formatNumber(itc_resumen[0]?.bajos, 0)}
        period="de {formatNumber(itc_resumen[0]?.total, 0)}: por debajo de 5 o sin rendir la evaluación ({itc_ultimo[0]?.etiqueta})"
        sparklineData={itc_aytos_serie.map(d => d.suspenso)}
    />
</Grid>

## Qué obliga la ley

La Ley 19/2013 (arts. 5 a 8) agrupa las obligaciones en tres bloques, y las leyes autonómicas de transparencia añaden otras para sus administraciones y ayuntamientos:

- **Información institucional, organizativa y de planificación**: funciones, normativa, organigrama, responsables y su trayectoria, planes y programas con su grado de cumplimiento.
- **Información de relevancia jurídica**: directrices e instrucciones, anteproyectos de ley y proyectos de reglamento, memorias e informes de los expedientes normativos.
- **Información económica, presupuestaria y estadística**: contratos (incluidos los menores), convenios, encomiendas, subvenciones y ayudas, presupuestos y su ejecución, cuentas e informes de auditoría, retribuciones de altos cargos, compatibilidades, bienes patrimoniales y estadísticas de calidad de los servicios.

La información debe ser **clara, estructurada, actualizada y reutilizable** (art. 5). Incumplir estas obligaciones de forma reiterada es infracción grave según la ley estatal (art. 9.3), pero en la práctica las sanciones son excepcionales: los órganos de control **recomiendan y evalúan**, no multan.

## Quién evalúa y qué publica

| Órgano de control | A quién evalúa | Qué publica por entidad | ¿Se usa aquí? |
|---|---|---|---|
| [Consejo de Transparencia y Buen Gobierno](https://consejodetransparencia.es/evaluacion) (CTBG) | AGE y sector público estatal, órganos constitucionales, partidos, sindicatos, entidades subvencionadas; y las comunidades y ciudades autónomas con convenio (Asturias, Cantabria, Castilla-La Mancha, Extremadura, La Rioja, Ceuta y Melilla; Madrid en 2020-2021) y algunos de sus ayuntamientos | Índice de Cumplimiento de la Información Obligatoria (ICIO, 0-100 %, metodología MESTA) en un informe Word por entidad; sin tabla de datos | Sí: Portal de la AGE, 8 comunidades y 11 ayuntamientos |
| [Comisionado de Transparencia de Canarias](https://transparenciacanarias.org/evaluacion/puntuaciones/) | Todo el sector público canario (Gobierno, cabildos, ayuntamientos, universidades y sus entes) y entidades privadas subvencionadas | Índice de Transparencia de Canarias (ITCanarias, 0-10) en una tabla Excel con todas las entidades desde 2016 (CC BY 4.0) | Sí: sector público |
| [Consejo de la Transparencia de la Región de Murcia](https://comisionadotransparencia.carm.es/) | Administración regional, ayuntamientos y su sector público (autoevaluación verificada, basada en MESTA) | Informe ejecutivo en PDF con resultados agregados por tipo de entidad; las notas por ayuntamiento solo aparecen en gráficos | No: no hay datos por entidad reutilizables |
| [Síndic de Greuges de Catalunya](https://www.sindic.cat/) | Administraciones catalanas (Ley 19/2014) | Informe anual e informes individuales en PDF; índice de desarrollo de la publicidad activa (IDPAC) en fase piloto desde 2024 | No: informes en PDF por entidad, sin tabla |
| Consejos y comisionados de Andalucía, Aragón, Castilla y León, Comunitat Valenciana, Galicia, Navarra, País Vasco y otros | Su comunidad y sus entidades locales | Memorias anuales, planes de control e inspección y resoluciones, en PDF; no hemos encontrado un índice de cumplimiento publicado por entidad | No |

También hay rankings de la sociedad civil (Dyntra, el Mapa Infoparticipa de la Universitat Autònoma de Barcelona, los antiguos índices de Transparencia Internacional España). **No se usan aquí**: no son fuentes oficiales y no hemos comprobado que su licencia permita reutilizar los datos.

## Administración General del Estado

El CTBG evalúa cada año el [Portal de la Transparencia](https://transparencia.gob.es/) de la AGE. El ICIO mide, para cada obligación, si la información se publica y con qué calidad (forma, fecha de actualización, accesibilidad, reutilización).

<LineChart
    data={age}
    x=anio
    y=icio
    yFmt=num1
    yMin=0
    yMax=100
    title="Portal de la Transparencia de la AGE: índice de cumplimiento (%)"
    markers=true
    sort=false
/>

Las cinco evaluaciones corresponden a Gobiernos de Pedro Sánchez, así que **no permiten comparar partidos** en el Gobierno central. El CTBG evalúa además cada año, por separado, a cientos de organismos, empresas y fundaciones del sector público estatal; sus notas están en informes individuales y no se han incorporado todavía.

## Comunidades autónomas y ayuntamientos evaluados por el CTBG

Las comunidades que no crearon su propio órgano de control firmaron un convenio para que el CTBG vigile su transparencia. En 2020 el CTBG evaluó sus portales y en 2021 revisó si habían aplicado sus recomendaciones.

<BarChart
    data={ctbg_ccaa_largo}
    x=entidad
    y=icio
    series=evaluacion
    type=grouped
    swapXY=true
    yFmt=num1
    yMax=100
    title="Índice de cumplimiento de la información obligatoria (%)"
    sort=false
/>

<DataTable data={ctbg_ccaa} rows=all>
    <Column id=entidad title="Comunidad o ciudad autónoma" />
    <Column id=familia title="Partido del presidente" />
    <Column id=icio_2020 title="ICIO 2020 (%)" fmt=num1 />
    <Column id=icio_2021 title="ICIO 2021 (%)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=mejora title="Mejora (puntos)" fmt=num1 contentType=delta />
</DataTable>

Todas mejoraron tras las recomendaciones. Con solo ocho comunidades, gobernadas por cuatro partidos distintos, **no tiene sentido comparar partidos**: cualquier diferencia puede deberse a una sola comunidad.

Los ayuntamientos evaluados por el CTBG son pocos y no forman una muestra representativa (los eligió el Consejo). Aun así, muestran lo lejos que puede quedar un ayuntamiento grande de cumplir: {formatNumber(ctbg_resumen[0]?.ayto_menos_50, 0)} de {formatNumber(ctbg_resumen[0]?.n_ayto, 0)} seguían por debajo del 50 % en la revisión de 2021.

<DataTable data={ctbg_ayto} rows=all link=informe showLinkCol=false>
    <Column id=entidad title="Ayuntamiento" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=familia title="Partido del alcalde (2021)" />
    <Column id=icio_2020 title="ICIO 2020 (%)" fmt=num1 />
    <Column id=icio_2021 title="ICIO 2021 (%)" fmt=num1 contentType=colorscale colorMin=0 colorMax=100 />
</DataTable>

## Canarias: todo el sector público, entidad por entidad

Canarias es la única comunidad que publica **cada año y en datos abiertos** la nota de todas sus administraciones. El Comisionado de Transparencia envía un cuestionario sobre las obligaciones de la ley canaria (más exigente que la estatal), comprueba las respuestas en los portales y calcula el Índice de Transparencia de Canarias (0 a 10). Una entidad que no rellena la evaluación figura como **incumplidora**.

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

<p class="text-xs text-gray-500">Las dos últimas evaluaciones no son años naturales: «2022/23» cubre 2022 y el primer semestre de 2023; «2023/24», el segundo semestre de 2023 y 2024. La nota se muestra sobre 100 para compararla con la escala de la gráfica (7,5 de 10 = 75).</p>

La mejora es clara: la nota media de los ayuntamientos pasó de {formatNumber(itc_aytos_serie[0]?.media / 10, 1)} en la primera evaluación a {formatNumber(itc_aytos_serie[itc_aytos_serie.length - 1]?.media / 10, 1)} en la última. Parte de la subida refleja que las entidades aprenden a responder el cuestionario, y muchas ya están en el máximo, así que las notas altas distinguen poco entre ellas.

### Ayuntamientos, {itc_ultimo[0]?.etiqueta}

<AreaMap
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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Límites © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'municipio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'puntuacion', title: 'Nota (sobre 100)', fmt: 'num1'},
        {id: 'familia', title: 'Partido del alcalde'},
        {id: 'situacion', title: 'Situación'}
    ]}
/>

<p class="text-xs text-gray-500">La escala de color empieza en 50: por debajo, todos se ven en rojo. Un municipio en gris no rindió la evaluación.</p>

<DataTable data={itc_aytos_ultimo} search=true rows=15>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=puntuacion_original title="Nota (0-10)" fmt=num2 contentType=colorscale colorMin=0 colorMax=10 />
    <Column id=situacion title="Situación" />
    <Column id=familia title="Partido del alcalde" />
</DataTable>

### Gobierno de Canarias y cabildos

<DataTable data={itc_institucionales} rows=all>
    <Column id=entidad title="Entidad" />
    <Column id=tipo_administracion title="Tipo" />
    <Column id=en_2017 title="Nota 2017 (sobre 100)" fmt=num1 />
    <Column id=ultima title="Última nota (sobre 100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=familia title="Partido del presidente" />
</DataTable>

<p class="text-xs text-gray-500">Los cabildos no se atribuyen a un partido: no hay todavía un registro oficial de sus presidentes en SpainFacts.</p>

### Empresas, organismos y fundaciones públicas

Donde más se incumple no es en las administraciones, sino en sus **entes dependientes**: empresas públicas, fundaciones, consorcios y corporaciones de derecho público, que también están obligados.

<DataTable data={itc_entes} rows=all>
    <Column id=tipo_entidad title="Tipo de entidad" />
    <Column id=entidades title="Entidades" fmt=num0 />
    <Column id=media title="Nota media (sobre 100)" fmt=num1 contentType=colorscale colorMin=50 colorMax=100 />
    <Column id=incumplidoras title="No rindieron la evaluación" fmt=num0 />
</DataTable>

<details>
<summary>Entidades que no rindieron la evaluación en las dos últimas ediciones</summary>

<DataTable data={itc_incumplidoras} search=true rows=15>
    <Column id=evaluacion title="Evaluación" />
    <Column id=entidad title="Entidad" />
    <Column id=tipo_entidad title="Tipo" />
    <Column id=entidad_principal title="Depende de" />
</DataTable>

</details>

## Por partido

La comparación solo es posible con los **ayuntamientos canarios**: son 88, se evalúan todos, con el mismo método, desde 2016. Para cada ayuntamiento y evaluación se calcula la nota **esperable**: la media de los ayuntamientos canarios de su mismo tamaño (menos de 5.000, de 5.000 a 20.000 y más de 20.000 habitantes) en esa misma evaluación. Después se compara la nota media de los gobernados por cada partido con su esperable.

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
    <Column id=familia title="Partido del alcalde" />
    <Column id=evaluaciones title="Evaluaciones" fmt=num0 />
    <Column id=municipios title="Municipios distintos" fmt=num0 />
    <Column id=observada title="Nota media" fmt=num1 />
    <Column id=esperada title="Esperable" fmt=num1 />
    <Column id=diferencia title="Diferencia" fmt=num1 contentType=delta />
    <Column id=ic_bajo title="IC 95 % (mín.)" fmt=num1 />
    <Column id=ic_alto title="IC 95 % (máx.)" fmt=num1 />
    <Column id=lectura title="Lectura" />
</DataTable>

<p class="text-xs text-gray-500">Solo partidos con al menos 20 evaluaciones; los ayuntamientos que no rindieron la evaluación no tienen nota y no entran en el cálculo. El intervalo de confianza se calcula con el número de municipios distintos, no de evaluaciones, porque las notas de un mismo ayuntamiento en años seguidos no son independientes. «Sin detalle en la fuente» agrupa alcaldías elegidas en listas que el registro oficial etiqueta de forma genérica; «Independientes y locales», agrupaciones de electores. Una diferencia entre partidos no prueba que se deba al partido: influyen la plantilla, los medios técnicos, la isla y la persona que gobierna.</p>

Para las comunidades autónomas y el Gobierno central **no hay muestra suficiente**: una sola evaluación por comunidad y año, y en el caso del Estado un único Gobierno en todo el periodo evaluado.

## Qué falta

- **No hay una evaluación homogénea para toda España.** Cada órgano de control evalúa a su ámbito con su método: la nota de un ayuntamiento canario (ITCanarias) y la de uno cántabro (ICIO del CTBG) no se pueden comparar.
- **La mayoría de los órganos autonómicos no publica notas por entidad en datos abiertos.** Murcia, Cataluña, Andalucía, Castilla y León y otros publican memorias e informes en PDF, a veces con las notas solo en gráficos. Si alguno publica sus resultados por entidad en un formato reutilizable, se incorporará.
- **Los más de 8.100 ayuntamientos de España no se evalúan de forma sistemática**, salvo en Canarias. El CTBG evaluó a 11 en 2020-2021.
- **El sector público estatal** (organismos, empresas y fundaciones) sí tiene nota por entidad en los informes del CTBG, pero en documentos individuales. En 2025 el CTBG evaluó a 225 de estas entidades, con un ICIO medio de solo el 38,9 % ([nota del CTBG](https://consejodetransparencia.es/comunicacion/noticias/hemeroteca/2025/20251114)). Es la próxima ampliación viable.
- Las evaluaciones miden **si la información está publicada y cómo**, no si es veraz ni completa en su contenido.

---

## Metodología y fuentes

- **[Consejo de Transparencia y Buen Gobierno – Evaluación](https://consejodetransparencia.es/evaluacion)**: Índice de Cumplimiento de la Información Obligatoria (ICIO) de la [metodología MESTA](https://consejodetransparencia.es/content/dam/ctransparencia/portal-ctbg/publicaciones/documentacion/metodologia/MESTA-informefinal.pdf), leído del texto de cada **informe definitivo** (.docx): Portal de la Transparencia de la AGE (2021-2025), comunidades y ciudades autónomas con convenio (evaluación de 2020 y revisión de 2021) y sus ayuntamientos evaluados. El CTBG revisa directamente cada portal y puntúa, para cada obligación, si se publica el contenido y sus atributos de calidad (forma, actualización, accesibilidad, reutilización). Origen de los datos: Consejo de Transparencia y Buen Gobierno (reutilización según la Ley 37/2007).
- **[Comisionado de Transparencia de Canarias – Puntuaciones](https://transparenciacanarias.org/evaluacion/puntuaciones/)**: tabla maestra de puntuaciones del sector público del Índice de Transparencia de Canarias (XLSX, [CC BY 4.0](https://transparenciacanarias.org/datos/)), desde la evaluación de 2016. Combina el cumplimiento de la información obligatoria, la calidad del soporte web y la transparencia voluntaria ([metodología](https://transparenciacanarias.org/evaluacion/sector-publico/metodologia/)). La entidad rellena un cuestionario y el Comisionado lo verifica. Se muestra sobre 100 (nota por 10) solo para dibujarla junto al ICIO; **las dos escalas no son equivalentes**.
- **Municipios**: los nombres del Comisionado se casan con el código INE por nombre (seis con una forma distinta, a mano). Población del padrón del INE del año evaluado.
- **Atribución a partidos**: ayuntamientos, alcalde en funciones al final del periodo evaluado según el [registro de alcaldes del Ministerio de Política Territorial](https://concejales.redsara.es/consulta/) (para la evaluación «2022/23», el 1 de junio de 2023, antes de las corporaciones salidas de las elecciones de mayo); comunidades y Estado, presidente en funciones el 31 de diciembre del año evaluado (ITCanarias) o el 30 de junio del año de la evaluación (CTBG). Los partidos se agrupan en familias políticas.
- **Obligaciones legales**: arts. 5 a 9 de la [Ley 19/2013, de transparencia, acceso a la información pública y buen gobierno](https://www.boe.es/buscar/act.php?id=BOE-A-2013-12887); en Canarias, la [Ley 12/2014, de transparencia y de acceso a la información pública](https://www.boe.es/buscar/act.php?id=BOE-A-2015-1114).

<LastRefreshed prefix="Datos actualizados" />
