---
title: ¿Cuántos diputados son caseros?
description: "Cuántos diputados del Congreso declaran ingresos por alquiler o tienen varias viviendas, qué patrimonio inmobiliario declaran, cuántos inmuebles urbanos completos tiene cada uno y cada partido, según sus declaraciones de bienes y rentas, y frente al conjunto de declarantes del IRPF."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
</script>

```sql resumen
SELECT orden, definicion_id, definicion, n_cumplen, pct, n_diputados, n_validos, n_excluidos,
       mediana_urbanos, CAST(ejercicio_rentas AS INTEGER) AS ejercicio_rentas,
       strftime(primera_declaracion, '%d/%m/%Y') AS primera, strftime(ultima_declaracion, '%d/%m/%Y') AS ultima
FROM mother.diputados_inmuebles_resumen
ORDER BY orden
```

```sql kpi
SELECT
    max(r.pct) FILTER (WHERE r.definicion_id = 'alquila') AS pct_alquila,
    max(r.n_cumplen) FILTER (WHERE r.definicion_id = 'alquila') AS n_alquila,
    max(r.pct) FILTER (WHERE r.definicion_id = 'dos_viviendas') AS pct_dos_viviendas,
    max(r.n_cumplen) FILTER (WHERE r.definicion_id = 'dos_viviendas') AS n_dos_viviendas,
    max(r.pct) FILTER (WHERE r.definicion_id = 'dos_urbanos') AS pct_dos_urbanos,
    max(r.pct) FILTER (WHERE r.definicion_id = 'dos_equivalentes') AS pct_dos_equivalentes,
    max(r.n_cumplen) FILTER (WHERE r.definicion_id = 'dos_equivalentes') AS n_dos_equivalentes,
    max(r.pct) FILTER (WHERE r.definicion_id = 'sin_urbanos') AS pct_sin_urbanos,
    max(r.n_cumplen) FILTER (WHERE r.definicion_id = 'sin_urbanos') AS n_sin_urbanos,
    max(r.n_validos) AS n_validos, max(r.n_diputados) AS n_diputados, max(r.n_excluidos) AS n_excluidos,
    max(r.mediana_urbanos) AS mediana_urbanos,
    max(p.media_urbanos_equivalentes) AS media_completos,
    max(p.mediana_urbanos_equivalentes) AS mediana_completos
FROM mother.diputados_inmuebles_resumen r
CROSS JOIN (SELECT * FROM mother.diputados_inmuebles_partidos WHERE partido = 'Total') p
```

```sql irpf
SELECT
    max(pct) FILTER (WHERE colectivo = 'Declarantes IRPF (todos)' AND indicador_id = 'alquila') AS pct_todos,
    max(pct) FILTER (WHERE tramo = '(60 - 150]' AND indicador_id = 'alquila') AS pct_tramo,
    max(pct) FILTER (WHERE colectivo = 'Declarantes IRPF (todos)' AND indicador_id = 'inmuebles_a_disposicion') AS pct_disposicion
FROM mother.diputados_inmuebles_poblacion
WHERE anio = 2022
```

```sql irpf_tramos
SELECT tramo, pct, n, total
FROM mother.diputados_inmuebles_poblacion
WHERE anio = 2022 AND indicador_id = 'alquila' AND colectivo LIKE 'Declarantes IRPF, rendimientos%' AND tramo <> 'Negativo y Cero'
ORDER BY CASE tramo WHEN '(0 - 1,5]' THEN 1 WHEN '(1,5 - 6]' THEN 2 WHEN '(6 - 12]' THEN 3 WHEN '(12 - 21]' THEN 4 WHEN '(21 - 30]' THEN 5
                    WHEN '(30 - 60]' THEN 6 WHEN '(60 - 150]' THEN 7 WHEN '(150 - 601]' THEN 8 ELSE 9 END
```

```sql comparacion
SELECT 'Diputados del Congreso' AS colectivo, pct, 1 AS orden FROM mother.diputados_inmuebles_poblacion WHERE anio = 2022 AND colectivo LIKE 'Diputados%' AND indicador_id = 'alquila'
UNION ALL
SELECT 'Todos los declarantes del IRPF', pct, 2 FROM mother.diputados_inmuebles_poblacion WHERE anio = 2022 AND colectivo = 'Declarantes IRPF (todos)' AND indicador_id = 'alquila'
UNION ALL
SELECT 'Declarantes con rendimientos de 60.000 a 150.000 €', pct, 3 FROM mother.diputados_inmuebles_poblacion WHERE anio = 2022 AND tramo = '(60 - 150]' AND indicador_id = 'alquila'
ORDER BY orden
```

```sql grupos
SELECT grupo, grupo_parlamentario, CAST(n_validos AS INTEGER) AS diputados, pct_alquila, pct_dos_viviendas, pct_dos_urbanos,
       pct_dos_equivalentes, pct_sin_urbanos, mediana_urbanos, mediana_alquiler_real_eur
FROM mother.diputados_inmuebles_grupos
WHERE grupo <> 'Total'
ORDER BY n_validos DESC
```

```sql grupos_largo
SELECT grupo, 'Declara ingresos por alquiler' AS medida, pct_alquila AS pct, n_validos FROM mother.diputados_inmuebles_grupos WHERE grupo <> 'Total' AND n_validos >= 20
UNION ALL
SELECT grupo, '2 o más viviendas', pct_dos_viviendas, n_validos FROM mother.diputados_inmuebles_grupos WHERE grupo <> 'Total' AND n_validos >= 20
ORDER BY n_validos DESC, medida
```

```sql distribucion
SELECT CASE WHEN urbanos_equivalentes = 0 THEN 'Ninguno'
            WHEN urbanos_equivalentes < 1 THEN 'Menos de 1'
            WHEN urbanos_equivalentes < 2 THEN 'De 1 a menos de 2'
            WHEN urbanos_equivalentes < 3 THEN 'De 2 a menos de 3'
            WHEN urbanos_equivalentes < 5 THEN 'De 3 a menos de 5'
            WHEN urbanos_equivalentes < 10 THEN 'De 5 a menos de 10'
            ELSE '10 o más' END AS tramo,
       CASE WHEN urbanos_equivalentes = 0 THEN 1 WHEN urbanos_equivalentes < 1 THEN 2 WHEN urbanos_equivalentes < 2 THEN 3
            WHEN urbanos_equivalentes < 3 THEN 4 WHEN urbanos_equivalentes < 5 THEN 5 WHEN urbanos_equivalentes < 10 THEN 6 ELSE 7 END AS orden,
       count(*) AS diputados
FROM mother.diputados_inmuebles_diputados
WHERE extraccion_ok
GROUP BY ALL
ORDER BY orden
```

```sql tipos_total
SELECT categoria, por_diputado, pct, unidades
FROM mother.diputados_inmuebles_composicion
WHERE partido = 'Total' AND desglose = 'tipo'
ORDER BY orden
```

```sql adquisicion
SELECT c.partido, c.categoria, c.pct, c.orden, p.media_urbanos_equivalentes
FROM mother.diputados_inmuebles_composicion c
JOIN mother.diputados_inmuebles_partidos p ON p.partido = c.partido
WHERE c.desglose = 'adquisicion' AND (p.n_validos >= 5 OR c.partido = 'Total')
ORDER BY c.orden_total, p.media_urbanos_equivalentes DESC, c.orden
```

```sql adquisicion_total
SELECT max(pct) FILTER (WHERE categoria = 'Herencia o donación') AS pct_herencia,
       max(pct) FILTER (WHERE categoria = 'Compra') AS pct_compra
FROM mother.diputados_inmuebles_composicion
WHERE partido = 'Total' AND desglose = 'adquisicion'
```

```sql partidos
SELECT partido, CAST(n_validos AS INTEGER) AS diputados, media_urbanos_equivalentes, mediana_urbanos_equivalentes,
       media_urbanos, media_viviendas, media_rusticos, pct_dos_viviendas, max_urbanos_equivalentes
FROM mother.diputados_inmuebles_partidos
WHERE partido <> 'Total'
ORDER BY media_urbanos_equivalentes DESC
```

```sql partidos_grafico
SELECT partido, media_urbanos_equivalentes FROM mother.diputados_inmuebles_partidos
WHERE partido <> 'Total' AND n_validos >= 5
ORDER BY media_urbanos_equivalentes DESC
```

```sql partidos_tipos
SELECT c.partido, c.categoria, c.por_diputado, c.orden, p.media_urbanos_equivalentes
FROM mother.diputados_inmuebles_composicion c
JOIN mother.diputados_inmuebles_partidos p ON p.partido = c.partido
WHERE c.desglose = 'tipo' AND c.partido <> 'Total' AND p.n_validos >= 5
ORDER BY p.media_urbanos_equivalentes DESC, c.orden
```

```sql ranking
SELECT row_number() OVER (ORDER BY urbanos_equivalentes DESC, n_urbanos DESC, nombre) AS puesto,
       nombre, partido, circunscripcion, urbanos_equivalentes, n_urbanos, n_viviendas_urbanas, n_rusticos,
       n_inmuebles_sociedad,
       CASE WHEN alquila THEN 'Sí' ELSE 'No' END AS alquila,
       url_pdf
FROM mother.diputados_inmuebles_diputados
WHERE extraccion_ok
ORDER BY puesto
```

```sql ranking_top
SELECT nombre || ' (' || partido || ')' AS diputado, urbanos_equivalentes, puesto FROM ${ranking} WHERE puesto <= 15 ORDER BY puesto
```

```sql sin_declaracion
SELECT id_diputado, nombre, partido, circunscripcion, strftime(fecha_alta, '%d/%m/%Y') AS alta, estado_declaracion, url_pdf,
       'https://www.congreso.es/es/busqueda-de-diputados?p_p_id=diputadomodule&p_p_lifecycle=0&p_p_state=normal&p_p_mode=view&_diputadomodule_mostrarFicha=true&codParlamentario=' || id_diputado || '&idLegislatura=XV' AS url_ficha
FROM mother.diputados_inmuebles_diputados
WHERE estado_declaracion <> 'valida'
ORDER BY CASE estado_declaracion WHEN 'sin_declaracion' THEN 1 ELSE 2 END, nombre
```

# <span aria-hidden="true">🏘️</span> ¿Cuántos diputados son caseros?

{#if sin_declaracion.length}
<div role="alert" class="my-6 rounded-xl border-2 border-red-600 bg-red-50 p-5 dark:border-red-500 dark:bg-red-950/50">
    <p class="text-sm font-bold uppercase tracking-wider text-red-700 dark:text-red-300">⚠ Diputados sin declaración de bienes</p>
    {#each sin_declaracion as d}
    <div class="mt-4">
        <p class="text-2xl font-extrabold leading-tight text-red-700 dark:text-red-300">{d.nombre} <span class="whitespace-nowrap text-base font-semibold">({d.partido}, {d.circunscripcion})</span></p>
        {#if d.estado_declaracion === 'sin_declaracion'}
        <p class="mt-1 text-red-900 dark:text-red-100">Su ficha del Congreso no enlaza ninguna declaración de bienes y rentas. En el Congreso desde el {d.alta}. <a class="font-semibold text-red-700 underline dark:text-red-300" href={d.url_ficha} target="_blank" rel="noopener">Ver su ficha ↗</a></p>
        {:else}
        <p class="mt-1 text-red-900 dark:text-red-100">Su declaración no enumera todos sus bienes: para los inmuebles urbanos se remite a la que presentó al inicio de la XIV Legislatura, que el Congreso ya no publica. <a class="font-semibold text-red-700 underline dark:text-red-300" href={d.url_pdf} target="_blank" rel="noopener">Ver la declaración ↗</a></p>
        {/if}
    </div>
    {/each}
    <p class="mt-4 text-sm text-red-800 dark:text-red-200">No entran en las cifras ni en los rankings de esta página.</p>
</div>
{/if}

Los diputados del Congreso presentan al tomar posesión una declaración de bienes y rentas que se publica en su ficha. Hemos leído las de los {kpi[0]?.n_diputados} diputados en activo de la XV Legislatura para contar cuántos declaran ingresos por alquiler, cuántos tienen más de una vivienda y qué inmuebles declara cada uno. Todo lo que sigue es lo que consta en sus declaraciones.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if kpi.length && irpf.length}
    <KpiCard
        title="Declaran ingresos por alquiler"
        value={kpi[0].pct_alquila}
        formattedValue={formatNumber(kpi[0].pct_alquila, 1) + ' %'}
        unit="de los diputados"
        period={`${kpi[0].n_alquila} de ${kpi[0].n_validos} · IRPF: ${formatNumber(irpf[0].pct_todos, 1)} % de los declarantes`}
        source="Congreso de los Diputados"
    />
    <KpiCard
        title="Tienen 2 o más viviendas"
        value={kpi[0].pct_dos_viviendas}
        formattedValue={formatNumber(kpi[0].pct_dos_viviendas, 1) + ' %'}
        unit="de los diputados"
        period={`${kpi[0].n_dos_viviendas} de ${kpi[0].n_validos} diputados`}
        source="Congreso de los Diputados"
    />
    <KpiCard
        title="2 o más inmuebles urbanos completos"
        value={kpi[0].pct_dos_equivalentes}
        formattedValue={formatNumber(kpi[0].pct_dos_equivalentes, 1) + ' %'}
        unit="de los diputados"
        period={`Sumando su parte de cada inmueble · ${kpi[0].n_dos_equivalentes} diputados`}
        source="Congreso de los Diputados"
    />
    <KpiCard
        title="Inmuebles urbanos completos por diputado"
        value={kpi[0].media_completos}
        formattedValue={formatNumber(kpi[0].media_completos, 1)}
        unit="de media"
        period={`Mediana: ${formatNumber(kpi[0].mediana_completos, 1)} · ${kpi[0].n_sin_urbanos} diputados sin ninguno`}
        source="Congreso de los Diputados"
    />
    {/if}
</div>

## Qué es ser casero

No hay una única forma de medirlo, así que se dan varias. La más estricta es declarar ingresos por alquiler, que no es exactamente lo mismo que tener algo alquilado: alguien puede tenerlo y no detallarlo como renta aparte. Lo declara el {formatNumber(kpi[0]?.pct_alquila, 1)} % de los diputados. Si se cuenta a quienes tienen al menos dos viviendas (aunque no declaren ingresos por ellas: pueden ser segundas residencias o estar vacías), son el {formatNumber(kpi[0]?.pct_dos_viviendas, 1)} %. Contando también garajes, trasteros y locales, el {formatNumber(kpi[0]?.pct_dos_urbanos, 1)} % declara dos o más inmuebles urbanos; pero muchos los comparten con su pareja o con hermanos, y sumando solo su parte de cada uno, el {formatNumber(kpi[0]?.pct_dos_equivalentes, 1)} % llega a dos inmuebles completos. En el otro extremo, el {formatNumber(kpi[0]?.pct_sin_urbanos, 1)} % no declara ningún inmueble urbano.

<DataTable data={resumen} rows=6>
    <Column id=definicion title="Definición" />
    <Column id=n_cumplen title="Diputados" fmt='0' />
    <Column id=pct title="% de los diputados" fmt='0.0' />
</DataTable>

## Frente al resto de contribuyentes

La Agencia Tributaria publica cuántas declaraciones del IRPF incluyen rendimientos por inmuebles alquilados. En el ejercicio 2022, el mismo de la mayoría de las declaraciones de los diputados, fue el {formatNumber(irpf[0]?.pct_todos, 1)} % de todas. Pero declarar ingresos por alquiler es mucho más frecuente cuanto más se gana: entre quienes declaran rendimientos de 60.000 a 150.000 euros es el {formatNumber(irpf[0]?.pct_tramo, 1)} %. Los diputados declaran ingresos por alquiler algo más a menudo que el conjunto de los contribuyentes y bastante menos que los de ese tramo de ingresos.

<BarChart
    data={comparacion}
    x=colectivo
    y=pct
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    yAxisTitle="% que declara ingresos por alquiler"
    title="Declaran ingresos por alquiler de inmuebles (ejercicio 2022)"
/>

<BarChart
    data={irpf_tramos}
    x=tramo
    y=pct
    sort=false
    yFmt='0"%"'
    xAxisTitle="Rendimientos declarados (miles de euros)"
    yAxisTitle="% de las declaraciones"
    title="Declaraciones del IRPF con ingresos por alquiler, según lo que se gana (2022)"
/>

## Qué patrimonio inmobiliario declaran

El formulario del Congreso no pide el valor de los inmuebles, solo su clase, dónde están, cuándo se adquirieron y en qué proporción son del diputado. Por eso el patrimonio se mide por lo que tienen, no por lo que vale. La medida más justa es la de **inmuebles urbanos completos**: la suma de su parte de cada vivienda, garaje, local o solar (un piso a medias con la pareja cuenta medio). Las fincas rústicas se cuentan aparte, porque muchas son parcelas pequeñas heredadas en el rural, sobre todo en Galicia y Asturias, y no dicen mucho del patrimonio de quien las tiene.

<BarChart
    data={distribucion}
    x=tramo
    y=diputados
    sort=false
    yFmt='0'
    xAxisTitle="Inmuebles urbanos completos"
    yAxisTitle="Diputados"
    title="Diputados según los inmuebles urbanos completos que declaran"
/>

<BarChart
    data={tipos_total}
    x=categoria
    y=por_diputado
    swapXY=true
    sort=false
    yFmt='0.00'
    yAxisTitle="Inmuebles por diputado (media)"
    title="Qué inmuebles declaran: media por diputado, contando cada inmueble aunque sea en parte"
/>

¿Heredados o comprados? El {formatNumber(adquisicion_total[0]?.pct_compra, 0)} % de los inmuebles urbanos declarados se compraron y el {formatNumber(adquisicion_total[0]?.pct_herencia, 0)} % llegaron por herencia o donación; en el resto la declaración no lo dice.

<BarChart
    data={adquisicion}
    x=partido
    y=pct
    series=categoria
    type=stacked
    sort=false
    yFmt='0"%"'
    yAxisTitle="% de los inmuebles urbanos"
    seriesColors={{'Compra': '#2563eb', 'Herencia o donación': '#f59e0b', 'Otro o no consta': '#d4d4d4'}}
    title="Cómo adquirieron sus inmuebles urbanos, partidos con 5 o más diputados"
/>

## Por grupo parlamentario

<BarChart
    data={grupos_largo}
    x=grupo
    y=pct
    series=medida
    type=grouped
    sort=false
    yFmt='0"%"'
    yAxisTitle="% de los diputados del grupo"
    seriesColors={{'Declara ingresos por alquiler': '#2563eb', '2 o más viviendas': '#93c5fd'}}
    title="Diputados que declaran ingresos por alquiler o varias viviendas, grupos con 20 o más diputados"
/>

<DataTable data={grupos} rows=12>
    <Column id=grupo title="Grupo" />
    <Column id=diputados title="Diputados" fmt='0' />
    <Column id=pct_alquila title="% declara ingresos por alquiler" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 o más viviendas" fmt='0.0' />
    <Column id=pct_dos_urbanos title="% 2 o más urbanos" fmt='0.0' />
    <Column id=pct_dos_equivalentes title="% 2 o más completos" fmt='0.0' />
    <Column id=pct_sin_urbanos title="% sin urbanos" fmt='0.0' />
    <Column id=mediana_urbanos title="Mediana de urbanos" fmt='0' />
</DataTable>

En los grupos pequeños cada diputado mueve mucho el porcentaje: con siete diputados, uno solo son 14 puntos.

## Ranking por partido

Como los partidos tienen tamaños muy distintos, se comparan por diputado: cuántos inmuebles urbanos completos declara de media cada uno de sus diputados. Los diputados se agrupan por la formación por la que fueron elegidos, con el PSC y las demás federaciones dentro del PSOE.

<BarChart
    data={partidos_grafico}
    x=partido
    y=media_urbanos_equivalentes
    sort=false
    yFmt='0.0'
    yAxisTitle="Inmuebles urbanos completos por diputado (media)"
    title="Inmuebles urbanos completos por diputado, partidos con 5 o más diputados"
/>

<BarChart
    data={partidos_tipos}
    x=partido
    y=por_diputado
    series=categoria
    type=stacked
    sort=false
    yFmt='0.0'
    yAxisTitle="Inmuebles por diputado (media)"
    seriesColors={{'Vivienda': '#1d4ed8', 'Garaje o trastero': '#60a5fa', 'Local, oficina o nave': '#7c3aed', 'Otros urbanos (solares, edificios...)': '#c4b5fd', 'Finca rústica': '#a3a3a3'}}
    title="Qué inmuebles declaran sus diputados, contando cada inmueble aunque sea en parte"
/>

<DataTable data={partidos} rows=12>
    <Column id=partido title="Partido" />
    <Column id=diputados title="Diputados" fmt='0' />
    <Column id=media_urbanos_equivalentes title="Urbanos completos por diputado (media)" fmt='0.0' />
    <Column id=mediana_urbanos_equivalentes title="Mediana" fmt='0.0' />
    <Column id=media_urbanos title="Urbanos (media)" fmt='0.0' />
    <Column id=media_viviendas title="Viviendas (media)" fmt='0.0' />
    <Column id=media_rusticos title="Fincas rústicas (media)" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 o más viviendas" fmt='0.0' />
    <Column id=max_urbanos_equivalentes title="Máximo de un diputado" fmt='0.0' />
</DataTable>

La media sube con unos pocos diputados con muchos inmuebles: la mediana dice cuántos tiene el diputado típico de cada partido. Los partidos con uno o dos diputados (BNG, UPN, CC) dependen por completo de esa persona.

## Los diputados con más inmuebles urbanos completos

<BarChart
    data={ranking_top}
    x=diputado
    y=urbanos_equivalentes
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="Inmuebles urbanos completos (suma de su parte de cada uno)"
    title="Los 15 diputados con más inmuebles urbanos completos"
/>

<DataTable data={ranking} rows=25 search=true>
    <Column id=puesto title="#" fmt='0' />
    <Column id=nombre title="Diputado" />
    <Column id=partido title="Partido" />
    <Column id=circunscripcion title="Circunscripción" />
    <Column id=urbanos_equivalentes title="Urbanos completos" fmt='0.0' />
    <Column id=n_urbanos title="Urbanos (aunque sea en parte)" fmt='0' />
    <Column id=n_viviendas_urbanas title="Viviendas" fmt='0' />
    <Column id=n_rusticos title="Fincas rústicas" fmt='0' />
    <Column id=n_inmuebles_sociedad title="De sus sociedades" fmt='0' />
    <Column id=alquila title="Declara ingresos por alquiler" />
    <Column id=url_pdf title="Declaración" contentType=link linkLabel="PDF ↗" openInNewTab=true />
</DataTable>

El orden lo da la columna «Urbanos completos»: un piso heredado entre cuatro hermanos cuenta un cuarto, y uno a medias con la pareja, medio. Las fincas rústicas y los inmuebles de sociedades en las que participan se muestran pero no cuentan para el puesto. Cada fila enlaza a la declaración original en la web del Congreso.

## Metodología y fuentes

- **Declaraciones**: [Congreso de los Diputados, fichas de los diputados](https://www.congreso.es/es/busqueda-de-diputados), declaración de bienes y rentas inicial de cada diputado en activo de la XV Legislatura (presentadas entre el {resumen[0]?.primera} y el {resumen[0]?.ultima}). Las modificaciones posteriores no se usan porque suelen ser parciales. Se excluyen {kpi[0]?.n_excluidos} declaraciones que no se pueden leer o que remiten a una anterior.
- **Lectura**: los documentos son escaneos. Se ha revisado a mano cada declaración en el PDF, incluido el recuadro de Observaciones, donde algunos siguen la lista de inmuebles: los recuentos, la parte de propiedad de cada inmueble, su tipo, si se heredó o se compró y si se declaran ingresos por alquiler salen de esa revisión, no de la lectura automática, que se equivocaba demasiado. Cada bien nombrado cuenta uno («vivienda, plaza de garaje y trastero» son tres). Cada diputado enlaza a su declaración para comprobarlo.
- **Ingresos por alquiler**: el formulario no tiene una casilla para ellos; se detectan por el concepto de cada renta («alquiler», «arrendamiento», «capital inmobiliario»...). Los importes son los declarados, que unos dan en neto, otros en bruto y alguno al mes, así que no se suman ni se comparan. Las rentas imputadas por viviendas a disposición no cuentan como alquiler.
- **Inmuebles urbanos completos**: suma de la parte de propiedad de cada inmueble urbano (viviendas, garajes, trasteros, locales, solares); cuando consta como ganancial o en proindiviso sin porcentaje se cuenta la mitad. El formulario no pide el valor de los inmuebles, así que un piso en el centro de Madrid y una casa en un pueblo cuentan igual.
- **Contribuyentes**: [Agencia Tributaria, Estadística de los declarantes del IRPF](https://sede.agenciatributaria.gob.es/AEAT/Contenidos_Comunes/La_Agencia_Tributaria/Estadisticas/Publicaciones/sites/irpf/2023/jrubikf3d7dfa31d2ce3af7d74ec0cde8d09ed9914891e7.html), partida 102 (rendimientos de inmuebles arrendados), territorio de régimen común. La unidad es la declaración, que puede ser conjunta, no la persona.
