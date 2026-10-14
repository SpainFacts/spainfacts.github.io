---
title: ¿Cuántos diputados son caseros?
description: "Cuántos diputados del Congreso declaran ingresos por alquiler o tienen varias viviendas, cuántos inmuebles declara cada uno y cada partido, según sus declaraciones de bienes y rentas, y frente al conjunto de declarantes del IRPF."
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
    max(pct) FILTER (WHERE definicion_id = 'alquila') AS pct_alquila,
    max(n_cumplen) FILTER (WHERE definicion_id = 'alquila') AS n_alquila,
    max(pct) FILTER (WHERE definicion_id = 'dos_viviendas') AS pct_dos_viviendas,
    max(n_cumplen) FILTER (WHERE definicion_id = 'dos_viviendas') AS n_dos_viviendas,
    max(pct) FILTER (WHERE definicion_id = 'dos_urbanos') AS pct_dos_urbanos,
    max(pct) FILTER (WHERE definicion_id = 'dos_equivalentes') AS pct_dos_equivalentes,
    max(n_cumplen) FILTER (WHERE definicion_id = 'dos_equivalentes') AS n_dos_equivalentes,
    max(pct) FILTER (WHERE definicion_id = 'sin_urbanos') AS pct_sin_urbanos,
    max(n_validos) AS n_validos, max(n_diputados) AS n_diputados, max(n_excluidos) AS n_excluidos,
    max(mediana_urbanos) AS mediana_urbanos
FROM mother.diputados_inmuebles_resumen
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
SELECT grupo, 'Declara alquileres' AS medida, pct_alquila AS pct, n_validos FROM mother.diputados_inmuebles_grupos WHERE grupo <> 'Total' AND n_validos >= 20
UNION ALL
SELECT grupo, '2 o más viviendas', pct_dos_viviendas, n_validos FROM mother.diputados_inmuebles_grupos WHERE grupo <> 'Total' AND n_validos >= 20
ORDER BY n_validos DESC, medida
```

```sql partidos
SELECT partido, CAST(n_validos AS INTEGER) AS diputados, media_inmuebles, mediana_inmuebles, media_urbanos,
       media_viviendas, media_rusticos, pct_dos_viviendas, max_inmuebles, suma_inmuebles
FROM mother.diputados_inmuebles_partidos
WHERE partido <> 'Total'
ORDER BY media_inmuebles DESC
```

```sql partidos_largo
SELECT partido, 'Viviendas' AS tipo, media_viviendas AS media, 1 AS orden_tipo, media_inmuebles, n_validos FROM mother.diputados_inmuebles_partidos WHERE partido <> 'Total' AND n_validos >= 5
UNION ALL
SELECT partido, 'Garajes, locales y otros urbanos', round(media_urbanos - media_viviendas, 2), 2, media_inmuebles, n_validos FROM mother.diputados_inmuebles_partidos WHERE partido <> 'Total' AND n_validos >= 5
UNION ALL
SELECT partido, 'Fincas rústicas', media_rusticos, 3, media_inmuebles, n_validos FROM mother.diputados_inmuebles_partidos WHERE partido <> 'Total' AND n_validos >= 5
ORDER BY media_inmuebles DESC, orden_tipo
```

```sql ranking
SELECT row_number() OVER (ORDER BY n_inmuebles DESC, n_urbanos DESC, nombre) AS puesto,
       nombre, partido, circunscripcion, n_inmuebles, n_urbanos, n_viviendas_urbanas, n_rusticos,
       n_inmuebles_sociedad, urbanos_equivalentes,
       CASE WHEN alquila THEN 'Sí' ELSE 'No' END AS alquila,
       CASE WHEN revisado_a_mano THEN 'Sí' WHEN inmuebles_sin_contar THEN 'No: hay más en Observaciones' ELSE '' END AS revisado,
       url_pdf
FROM mother.diputados_inmuebles_diputados
WHERE extraccion_ok
ORDER BY puesto
```

```sql ranking_top
SELECT nombre || ' (' || partido || ')' AS diputado, n_inmuebles, puesto FROM ${ranking} WHERE puesto <= 15 ORDER BY puesto
```

# <span aria-hidden="true">🏘️</span> ¿Cuántos diputados son caseros?

Los diputados del Congreso presentan al tomar posesión una declaración de bienes y rentas que se publica en su ficha. Hemos leído las de los {kpi[0]?.n_diputados} diputados en activo de la XV Legislatura para contar cuántos declaran ingresos por alquilar inmuebles, cuántos tienen más de una vivienda y cuántos inmuebles declara cada uno. Todo lo que sigue es lo que consta en sus declaraciones.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if kpi.length && irpf.length}
    <KpiCard
        title="Declaran ingresos por alquiler"
        value={kpi[0].pct_alquila}
        formattedValue={formatNumber(kpi[0].pct_alquila, 1) + ' %'}
        unit="de los diputados"
        period={`${kpi[0].n_alquila} de ${kpi[0].n_validos} · IRPF: ${formatNumber(irpf[0].pct_todos, 1)} % de los declarantes`}
        source="Congreso de los Diputados"
        sparklineData={resumen.map(d => ({...d, y: d.pct}))}
    />
    <KpiCard
        title="Tienen 2 o más viviendas"
        value={kpi[0].pct_dos_viviendas}
        formattedValue={formatNumber(kpi[0].pct_dos_viviendas, 1) + ' %'}
        unit="de los diputados"
        period={`${kpi[0].n_dos_viviendas} diputados`}
        source="Congreso de los Diputados"
        sparklineData={resumen.map(d => ({...d, y: d.pct}))}
    />
    <KpiCard
        title="2 o más inmuebles urbanos completos"
        value={kpi[0].pct_dos_equivalentes}
        formattedValue={formatNumber(kpi[0].pct_dos_equivalentes, 1) + ' %'}
        unit="de los diputados"
        period={`Sumando su parte de cada inmueble · ${kpi[0].n_dos_equivalentes} diputados`}
        source="Congreso de los Diputados"
        sparklineData={resumen.map(d => ({...d, y: d.pct}))}
    />
    <KpiCard
        title="Sin ningún inmueble urbano"
        value={kpi[0].pct_sin_urbanos}
        formattedValue={formatNumber(kpi[0].pct_sin_urbanos, 1) + ' %'}
        unit="de los diputados"
        period={`Mediana: ${formatNumber(kpi[0].mediana_urbanos, 0)} inmuebles urbanos por diputado`}
        source="Congreso de los Diputados"
        sparklineData={resumen.map(d => ({...d, y: d.pct}))}
    />
    {/if}
</div>

## Qué es ser casero

No hay una única forma de medirlo, así que se dan varias. La más estricta es declarar ingresos por alquiler: el {formatNumber(kpi[0]?.pct_alquila, 1)} % de los diputados lo hace. Si se cuenta a quienes tienen al menos dos viviendas (aunque no declaren alquilarlas: pueden ser segundas residencias o estar vacías), son el {formatNumber(kpi[0]?.pct_dos_viviendas, 1)} %. Contando también garajes, trasteros y locales, el {formatNumber(kpi[0]?.pct_dos_urbanos, 1)} % declara dos o más inmuebles urbanos; pero muchos los comparten con su pareja o con hermanos, y sumando solo su parte de cada uno, el {formatNumber(kpi[0]?.pct_dos_equivalentes, 1)} % llega a dos inmuebles completos.

<DataTable data={resumen} rows=6>
    <Column id=definicion title="Definición" />
    <Column id=n_cumplen title="Diputados" fmt='0' />
    <Column id=pct title="% de los diputados" fmt='0.0' />
</DataTable>

## Frente al resto de contribuyentes

La Agencia Tributaria publica cuántas declaraciones del IRPF incluyen rendimientos por inmuebles alquilados. En el ejercicio 2022, el mismo de la mayoría de las declaraciones de los diputados, fue el {formatNumber(irpf[0]?.pct_todos, 1)} % de todas. Pero alquilar es mucho más frecuente cuanto más se gana: entre quienes declaran rendimientos de 60.000 a 150.000 euros es el {formatNumber(irpf[0]?.pct_tramo, 1)} %. Los diputados declaran alquileres algo más a menudo que el conjunto de los contribuyentes y bastante menos que los de ese tramo de ingresos.

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
    seriesColors={{'Declara alquileres': '#2563eb', '2 o más viviendas': '#93c5fd'}}
    title="Diputados que declaran alquileres o varias viviendas, grupos con 20 o más diputados"
/>

<DataTable data={grupos} rows=12>
    <Column id=grupo title="Grupo" />
    <Column id=diputados title="Diputados" fmt='0' />
    <Column id=pct_alquila title="% declara alquileres" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 o más viviendas" fmt='0.0' />
    <Column id=pct_dos_urbanos title="% 2 o más urbanos" fmt='0.0' />
    <Column id=pct_dos_equivalentes title="% 2 o más completos" fmt='0.0' />
    <Column id=pct_sin_urbanos title="% sin urbanos" fmt='0.0' />
    <Column id=mediana_urbanos title="Mediana de urbanos" fmt='0' />
</DataTable>

En los grupos pequeños cada diputado mueve mucho el porcentaje: con siete diputados, uno solo son 14 puntos.

## Ranking por partido

Como los partidos tienen tamaños muy distintos, se comparan por diputado: cuántos inmuebles declara de media cada uno de sus diputados. Se cuentan los inmuebles a su nombre, urbanos (viviendas, garajes, trasteros, locales, solares) y fincas rústicas, sea cual sea su parte de propiedad; los de sociedades en las que participan van aparte, en el ranking de diputados. Los diputados se agrupan por la formación por la que fueron elegidos, con el PSC y las demás federaciones dentro del PSOE.

<BarChart
    data={partidos_largo}
    x=partido
    y=media
    series=tipo
    type=stacked
    sort=false
    yFmt='0.0'
    yAxisTitle="Inmuebles por diputado (media)"
    seriesColors={{'Viviendas': '#1d4ed8', 'Garajes, locales y otros urbanos': '#60a5fa', 'Fincas rústicas': '#a3a3a3'}}
    title="Inmuebles declarados por diputado, partidos con 5 o más diputados"
/>

<DataTable data={partidos} rows=12>
    <Column id=partido title="Partido" />
    <Column id=diputados title="Diputados" fmt='0' />
    <Column id=media_inmuebles title="Inmuebles por diputado (media)" fmt='0.0' />
    <Column id=mediana_inmuebles title="Mediana" fmt='0.0' />
    <Column id=media_urbanos title="Urbanos (media)" fmt='0.0' />
    <Column id=media_viviendas title="Viviendas (media)" fmt='0.0' />
    <Column id=media_rusticos title="Rústicos (media)" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 o más viviendas" fmt='0.0' />
    <Column id=max_inmuebles title="Máximo de un diputado" fmt='0' />
    <Column id=suma_inmuebles title="Total del partido" fmt='0' />
</DataTable>

La media se dispara con unos pocos diputados con muchas fincas: la mediana dice cuántos inmuebles tiene el diputado típico de cada partido. Los partidos con uno o dos diputados (BNG, UPN, CC) dependen por completo de esa persona.

## Los diputados con más inmuebles

<BarChart
    data={ranking_top}
    x=diputado
    y=n_inmuebles
    swapXY=true
    sort=false
    yFmt='0'
    yAxisTitle="Inmuebles a su nombre (urbanos y rústicos)"
    title="Los 15 diputados que declaran más inmuebles"
/>

<DataTable data={ranking} rows=25 search=true>
    <Column id=puesto title="#" fmt='0' />
    <Column id=nombre title="Diputado" />
    <Column id=partido title="Partido" />
    <Column id=circunscripcion title="Circunscripción" />
    <Column id=n_inmuebles title="Inmuebles" fmt='0' />
    <Column id=n_urbanos title="Urbanos" fmt='0' />
    <Column id=n_viviendas_urbanas title="Viviendas" fmt='0' />
    <Column id=n_rusticos title="Rústicos" fmt='0' />
    <Column id=n_inmuebles_sociedad title="De sus sociedades" fmt='0' />
    <Column id=urbanos_equivalentes title="Urbanos completos" fmt='0.0' />
    <Column id=alquila title="Declara alquileres" />
    <Column id=revisado title="Revisado a mano" />
    <Column id=url_pdf title="Declaración" contentType=link linkLabel="PDF ↗" openInNewTab=true />
</DataTable>

Cuentan los inmuebles a su nombre aunque sean solo en parte: un piso heredado entre cuatro hermanos cuenta uno. La columna «Urbanos completos» suma solo su parte de cada inmueble urbano. Muchas fincas rústicas suelen ser parcelas pequeñas heredadas, sobre todo en Galicia y Asturias. Cada fila enlaza a la declaración original en la web del Congreso.

## Metodología y fuentes

- **Declaraciones**: [Congreso de los Diputados, fichas de los diputados](https://www.congreso.es/es/busqueda-de-diputados), declaración de bienes y rentas inicial de cada diputado en activo de la XV Legislatura (presentadas entre el {resumen[0]?.primera} y el {resumen[0]?.ultima}). Las modificaciones posteriores no se usan porque suelen ser parciales. Se excluyen {kpi[0]?.n_excluidos} declaraciones que no se pueden leer o que remiten a una anterior.
- **Lectura**: los documentos son escaneos; se han leído con reconocimiento óptico de caracteres y se ha comprobado a mano una muestra de 22 declaraciones de todos los grupos: el número de inmuebles urbanos y si declara alquileres coincidían en 21 de las 22. Las filas que nombran varios bienes («vivienda, plaza de garaje y trastero») se cuentan bien a bien. Los 42 diputados que declaran siete o más inmuebles, y los que siguen la lista en el recuadro de Observaciones, se han comprobado a mano en el PDF («Revisado a mano»), y sus cifras sustituyen a las leídas automáticamente; en el resto puede haber errores puntuales, y cada uno enlaza a su declaración para comprobarlo.
- **Alquileres**: el formulario no tiene una casilla para ellos; se detectan por el concepto de cada renta («alquiler», «arrendamiento», «capital inmobiliario»...). Los importes son los declarados, que unos dan en neto, otros en bruto y alguno al mes, así que no se suman ni se comparan. Las rentas imputadas por viviendas a disposición no cuentan como alquiler.
- **Inmuebles completos**: suma de la parte de propiedad de cada inmueble urbano; cuando consta como ganancial o en proindiviso sin porcentaje se cuenta la mitad.
- **Contribuyentes**: [Agencia Tributaria, Estadística de los declarantes del IRPF](https://sede.agenciatributaria.gob.es/AEAT/Contenidos_Comunes/La_Agencia_Tributaria/Estadisticas/Publicaciones/sites/irpf/2023/jrubikf3d7dfa31d2ce3af7d74ec0cde8d09ed9914891e7.html), partida 102 (rendimientos de inmuebles arrendados), territorio de régimen común. La unidad es la declaración, que puede ser conjunta, no la persona.
