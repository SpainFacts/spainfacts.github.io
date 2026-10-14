---
title: Cantos deputados son caseiros?
description: "Cantos deputados do Congreso declaran ingresos por alugueiro ou teñen varias vivendas, que patrimonio inmobiliario declaran, cantos inmobles urbanos completos ten cada un e cada partido, segundo as súas declaracións de bens e rendas, e fronte ao conxunto de declarantes do IRPF."
i18n_origen: dbee8acb0fd6
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
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
       CASE WHEN revisado_a_mano THEN 'Sí' WHEN inmuebles_sin_contar THEN 'No: hay más en Observaciones' ELSE '' END AS revisado,
       url_pdf
FROM mother.diputados_inmuebles_diputados
WHERE extraccion_ok
ORDER BY puesto
```

```sql ranking_top
SELECT nombre || ' (' || partido || ')' AS diputado, urbanos_equivalentes, puesto FROM ${ranking} WHERE puesto <= 15 ORDER BY puesto
```

# <span aria-hidden="true">🏘️</span> Cantos deputados son caseiros?

Os deputados do Congreso presentan ao tomaren posesión unha declaración de bens e rendas que se publica na súa ficha. Lemos as dos {kpi[0]?.n_diputados} deputados en activo da XV Lexislatura para contar cantos declaran ingresos por alugueiro, cantos teñen máis dunha vivenda e que inmobles declara cada un. Todo o que segue é o que consta nas súas declaracións.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if kpi.length && irpf.length}
    <KpiCard
        title="Declaran ingresos por alugueiro"
        value={kpi[0].pct_alquila}
        formattedValue={formatNumber(kpi[0].pct_alquila, 1) + ' %'}
        unit="dos deputados"
        period={`${kpi[0].n_alquila} de ${kpi[0].n_validos} · IRPF: ${formatNumber(irpf[0].pct_todos, 1)} % dos declarantes`}
        source="Congreso dos Deputados"
    />
    <KpiCard
        title="Teñen 2 ou máis vivendas"
        value={kpi[0].pct_dos_viviendas}
        formattedValue={formatNumber(kpi[0].pct_dos_viviendas, 1) + ' %'}
        unit="dos deputados"
        period={`${kpi[0].n_dos_viviendas} de ${kpi[0].n_validos} deputados`}
        source="Congreso dos Deputados"
    />
    <KpiCard
        title="2 ou máis inmobles urbanos completos"
        value={kpi[0].pct_dos_equivalentes}
        formattedValue={formatNumber(kpi[0].pct_dos_equivalentes, 1) + ' %'}
        unit="dos deputados"
        period={`Sumando a súa parte de cada inmoble · ${kpi[0].n_dos_equivalentes} deputados`}
        source="Congreso dos Deputados"
    />
    <KpiCard
        title="Inmobles urbanos completos por deputado"
        value={kpi[0].media_completos}
        formattedValue={formatNumber(kpi[0].media_completos, 1)}
        unit="de media"
        period={`Mediana: ${formatNumber(kpi[0].mediana_completos, 1)} · ${kpi[0].n_sin_urbanos} deputados sen ningún`}
        source="Congreso dos Deputados"
    />
    {/if}
</div>

## Que é ser caseiro

Non hai unha única forma de medilo, así que se dan varias. A máis estrita é declarar ingresos por alugueiro, que non é exactamente o mesmo que ter algo alugado: alguén pode telo e non detallalo como renda á parte. Declárao o {formatNumber(kpi[0]?.pct_alquila, 1)} % dos deputados. Se se conta a quen ten polo menos dúas vivendas (aínda que non declare ingresos por elas: poden ser segundas residencias ou estar baleiras), son o {formatNumber(kpi[0]?.pct_dos_viviendas, 1)} %. Contando tamén garaxes, trasteiros e locais, o {formatNumber(kpi[0]?.pct_dos_urbanos, 1)} % declara dous ou máis inmobles urbanos; pero moitos compárteos coa parella ou con irmáns, e sumando só a súa parte de cada un, o {formatNumber(kpi[0]?.pct_dos_equivalentes, 1)} % chega a dous inmobles completos. No outro extremo, o {formatNumber(kpi[0]?.pct_sin_urbanos, 1)} % non declara ningún inmoble urbano.

<DataTable data={resumen} rows=6>
    <Column id=definicion title="Definición" />
    <Column id=n_cumplen title="Deputados" fmt='0' />
    <Column id=pct title="% dos deputados" fmt='0.0' />
</DataTable>

## Fronte ao resto de contribuíntes

A Axencia Tributaria publica cantas declaracións do IRPF inclúen rendementos por inmobles alugados. No exercicio 2022, o mesmo da maioría das declaracións dos deputados, foi o {formatNumber(irpf[0]?.pct_todos, 1)} % de todas. Pero declarar ingresos por alugueiro é moito máis frecuente canto máis se gaña: entre quen declara rendementos de 60.000 a 150.000 euros é o {formatNumber(irpf[0]?.pct_tramo, 1)} %. Os deputados declaran ingresos por alugueiro algo máis a miúdo que o conxunto dos contribuíntes e bastante menos que os dese tramo de ingresos.

<BarChart
    data={comparacion}
    x=colectivo
    y=pct
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    yAxisTitle="% que declara ingresos por alugueiro"
    title="Declaran ingresos por alugueiro de inmobles (exercicio 2022)"
/>

<BarChart
    data={irpf_tramos}
    x=tramo
    y=pct
    sort=false
    yFmt='0"%"'
    xAxisTitle="Rendementos declarados (miles de euros)"
    yAxisTitle="% das declaracións"
    title="Declaracións do IRPF con ingresos por alugueiro, segundo o que se gaña (2022)"
/>

## Que patrimonio inmobiliario declaran

O formulario do Congreso non pide o valor dos inmobles, só a súa clase, onde están, cando se adquiriron e en que proporción son do deputado. Por iso o patrimonio mídese polo que teñen, non polo que vale. A medida máis xusta é a de **inmobles urbanos completos**: a suma da súa parte de cada vivenda, garaxe, local ou soar (un piso a medias coa parella conta medio). As fincas rústicas cóntanse á parte, porque moitas son parcelas pequenas herdadas no rural, sobre todo en Galicia e Asturias, e non din moito do patrimonio de quen as ten.

<BarChart
    data={distribucion}
    x=tramo
    y=diputados
    sort=false
    yFmt='0'
    xAxisTitle="Inmobles urbanos completos"
    yAxisTitle="Deputados"
    title="Deputados segundo os inmobles urbanos completos que declaran"
/>

<BarChart
    data={tipos_total}
    x=categoria
    y=por_diputado
    swapXY=true
    sort=false
    yFmt='0.00'
    yAxisTitle="Inmobles por deputado (media)"
    title="Que inmobles declaran: media por deputado, contando cada inmoble aínda que sexa en parte"
/>

Herdados ou comprados? O {formatNumber(adquisicion_total[0]?.pct_compra, 0)} % dos inmobles urbanos declarados compráronse e o {formatNumber(adquisicion_total[0]?.pct_herencia, 0)} % chegaron por herdanza ou doazón; no resto a declaración non o di.

<BarChart
    data={adquisicion}
    x=partido
    y=pct
    series=categoria
    type=stacked
    sort=false
    yFmt='0"%"'
    yAxisTitle="% dos inmobles urbanos"
    seriesColors={{'Compra': '#2563eb', 'Herencia o donación': '#f59e0b', 'No consta': '#d4d4d4'}}
    title="Como adquiriron os seus inmobles urbanos, partidos con 5 ou máis deputados"
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
    yAxisTitle="% dos deputados do grupo"
    seriesColors={{'Declara ingresos por alquiler': '#2563eb', '2 o más viviendas': '#93c5fd'}}
    title="Deputados que declaran ingresos por alugueiro ou varias vivendas, grupos con 20 ou máis deputados"
/>

<DataTable data={grupos} rows=12>
    <Column id=grupo title="Grupo" />
    <Column id=diputados title="Deputados" fmt='0' />
    <Column id=pct_alquila title="% declara ingresos por alugueiro" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 ou máis vivendas" fmt='0.0' />
    <Column id=pct_dos_urbanos title="% 2 ou máis urbanos" fmt='0.0' />
    <Column id=pct_dos_equivalentes title="% 2 ou máis completos" fmt='0.0' />
    <Column id=pct_sin_urbanos title="% sen urbanos" fmt='0.0' />
    <Column id=mediana_urbanos title="Mediana de urbanos" fmt='0' />
</DataTable>

Nos grupos pequenos cada deputado move moito a porcentaxe: con sete deputados, un só son 14 puntos.

## Ranking por partido

Como os partidos teñen tamaños moi distintos, compáranse por deputado: cantos inmobles urbanos completos declara de media cada un dos seus deputados. Os deputados agrúpanse pola formación pola que foron elixidos, co PSC e as demais federacións dentro do PSOE.

<BarChart
    data={partidos_grafico}
    x=partido
    y=media_urbanos_equivalentes
    sort=false
    yFmt='0.0'
    yAxisTitle="Inmobles urbanos completos por deputado (media)"
    title="Inmobles urbanos completos por deputado, partidos con 5 ou máis deputados"
/>

<BarChart
    data={partidos_tipos}
    x=partido
    y=por_diputado
    series=categoria
    type=stacked
    sort=false
    yFmt='0.0'
    yAxisTitle="Inmobles por deputado (media)"
    seriesColors={{'Vivienda': '#1d4ed8', 'Garaje o trastero': '#60a5fa', 'Local, oficina o nave': '#7c3aed', 'Otros urbanos (solares, edificios...)': '#c4b5fd', 'Finca rústica': '#a3a3a3'}}
    title="Que inmobles declaran os seus deputados, contando cada inmoble aínda que sexa en parte"
/>

<DataTable data={partidos} rows=12>
    <Column id=partido title="Partido" />
    <Column id=diputados title="Deputados" fmt='0' />
    <Column id=media_urbanos_equivalentes title="Urbanos completos por deputado (media)" fmt='0.0' />
    <Column id=mediana_urbanos_equivalentes title="Mediana" fmt='0.0' />
    <Column id=media_urbanos title="Urbanos (media)" fmt='0.0' />
    <Column id=media_viviendas title="Vivendas (media)" fmt='0.0' />
    <Column id=media_rusticos title="Fincas rústicas (media)" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 ou máis vivendas" fmt='0.0' />
    <Column id=max_urbanos_equivalentes title="Máximo dun deputado" fmt='0.0' />
</DataTable>

A media sobe cuns poucos deputados con moitos inmobles: a mediana di cantos ten o deputado típico de cada partido. Os partidos cun ou dous deputados (BNG, UPN, CC) dependen por completo desa persoa.

## Os deputados con máis inmobles urbanos completos

<BarChart
    data={ranking_top}
    x=diputado
    y=urbanos_equivalentes
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="Inmobles urbanos completos (suma da súa parte de cada un)"
    title="Os 15 deputados con máis inmobles urbanos completos"
/>

<DataTable data={ranking} rows=25 search=true>
    <Column id=puesto title="#" fmt='0' />
    <Column id=nombre title="Deputado" />
    <Column id=partido title="Partido" />
    <Column id=circunscripcion title="Circunscrición" />
    <Column id=urbanos_equivalentes title="Urbanos completos" fmt='0.0' />
    <Column id=n_urbanos title="Urbanos (aínda que sexa en parte)" fmt='0' />
    <Column id=n_viviendas_urbanas title="Vivendas" fmt='0' />
    <Column id=n_rusticos title="Fincas rústicas" fmt='0' />
    <Column id=n_inmuebles_sociedad title="Das súas sociedades" fmt='0' />
    <Column id=alquila title="Declara ingresos por alugueiro" />
    <Column id=revisado title="Revisado a man" />
    <Column id=url_pdf title="Declaración" contentType=link linkLabel="PDF ↗" openInNewTab=true />
</DataTable>

A orde dáa a columna «Urbanos completos»: un piso herdado entre catro irmáns conta un cuarto, e un a medias coa parella, medio. As fincas rústicas e os inmobles de sociedades nas que participan móstranse pero non contan para o posto. Cada fila leva á declaración orixinal na web do Congreso.

## Metodoloxía e fontes

- **Declaracións**: [Congreso dos Deputados, fichas dos deputados](https://www.congreso.es/es/busqueda-de-diputados), declaración de bens e rendas inicial de cada deputado en activo da XV Lexislatura (presentadas entre o {resumen[0]?.primera} e o {resumen[0]?.ultima}). As modificacións posteriores non se usan porque adoitan ser parciais. Exclúense {kpi[0]?.n_excluidos} declaracións que non se poden ler ou que remiten a unha anterior.
- **Lectura**: os documentos son escaneos; léronse con recoñecemento óptico de caracteres. As filas que nomean varios bens («vivenda, praza de garaxe e trasteiro») cóntanse ben a ben. Todos os deputados que declaran sete ou máis inmobles ou catro ou máis urbanos completos, e os que seguen a lista no recadro de Observacións, comprobáronse a man no PDF («Revisado a man»), e as súas cifras substitúen as lidas automaticamente; no resto pode haber erros puntuais, e cada un leva á súa declaración para comprobalo. O desagregamento por tipo de inmoble e por forma de adquisición calcúlase fila a fila sobre a lectura automática, así que as súas sumas non cadran exactamente coas de cada deputado.
- **Ingresos por alugueiro**: o formulario non ten unha casa para eles; detéctanse polo concepto de cada renda («alquiler», «arrendamiento», «capital inmobiliario»...). Os importes son os declarados, que uns dan en neto, outros en bruto e algún ao mes, así que non se suman nin se comparan. As rendas imputadas por vivendas a disposición non contan como alugueiro.
- **Inmobles urbanos completos**: suma da parte de propiedade de cada inmoble urbano (vivendas, garaxes, trasteiros, locais, soares); cando consta como ganancial ou en proindiviso sen porcentaxe cóntase a metade. O formulario non pide o valor dos inmobles, así que un piso no centro de Madrid e unha casa nunha aldea contan igual.
- **Contribuíntes**: [Axencia Tributaria, Estatística dos declarantes do IRPF](https://sede.agenciatributaria.gob.es/AEAT/Contenidos_Comunes/La_Agencia_Tributaria/Estadisticas/Publicaciones/sites/irpf/2023/jrubikf3d7dfa31d2ce3af7d74ec0cde8d09ed9914891e7.html), partida 102 (rendementos de inmobles arrendados), territorio de réxime común. A unidade é a declaración, que pode ser conxunta, non a persoa.
