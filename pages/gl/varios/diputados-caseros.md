---
title: Cantos deputados son caseiros?
description: "Cantos deputados do Congreso declaran ingresos por alugueiro ou teñen varias vivendas, segundo as súas declaracións de bens e rendas, por grupo parlamentario e fronte ao conxunto de declarantes do IRPF."
i18n_origen: cfa645ec5bd9
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

# <span aria-hidden="true">🏘️</span> Cantos deputados son caseiros?

Os deputados do Congreso presentan ao tomaren posesión unha declaración de bens e rendas que se publica na súa ficha. Lemos as dos {kpi[0]?.n_diputados} deputados en activo da XV Lexislatura para contar cantos declaran ingresos por alugar inmobles e cantos teñen máis dunha vivenda. Todo o que segue é o que consta nas súas declaracións.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if kpi.length && irpf.length}
    <KpiCard
        title="Declaran ingresos por alugueiro"
        value={kpi[0].pct_alquila}
        formattedValue={formatNumber(kpi[0].pct_alquila, 1) + ' %'}
        unit="dos deputados"
        period={`${kpi[0].n_alquila} de ${kpi[0].n_validos} · IRPF: ${formatNumber(irpf[0].pct_todos, 1)} % dos declarantes`}
        source="Congreso dos Deputados"
        sparklineData={resumen.map(d => d.pct)}
    />
    <KpiCard
        title="Teñen 2 ou máis vivendas"
        value={kpi[0].pct_dos_viviendas}
        formattedValue={formatNumber(kpi[0].pct_dos_viviendas, 1) + ' %'}
        unit="dos deputados"
        period={`${kpi[0].n_dos_viviendas} deputados`}
        source="Congreso dos Deputados"
        sparklineData={resumen.map(d => d.pct)}
    />
    <KpiCard
        title="2 ou máis inmobles urbanos completos"
        value={kpi[0].pct_dos_equivalentes}
        formattedValue={formatNumber(kpi[0].pct_dos_equivalentes, 1) + ' %'}
        unit="dos deputados"
        period={`Sumando a súa parte de cada inmoble · ${kpi[0].n_dos_equivalentes} deputados`}
        source="Congreso dos Deputados"
        sparklineData={resumen.map(d => d.pct)}
    />
    <KpiCard
        title="Sen ningún inmoble urbano"
        value={kpi[0].pct_sin_urbanos}
        formattedValue={formatNumber(kpi[0].pct_sin_urbanos, 1) + ' %'}
        unit="dos deputados"
        period={`Mediana: ${formatNumber(kpi[0].mediana_urbanos, 0)} inmobles urbanos por deputado`}
        source="Congreso dos Deputados"
        sparklineData={resumen.map(d => d.pct)}
    />
    {/if}
</div>

## Que é ser caseiro

Non hai unha única forma de medilo, así que se dan varias. A máis estrita é declarar ingresos por alugueiro: o {formatNumber(kpi[0]?.pct_alquila, 1)} % dos deputados faino. Se se conta a quen ten polo menos dúas vivendas (aínda que non declare alugalas: poden ser segundas residencias ou estar baleiras), son o {formatNumber(kpi[0]?.pct_dos_viviendas, 1)} %. Contando tamén garaxes, trasteiros e locais, o {formatNumber(kpi[0]?.pct_dos_urbanos, 1)} % declara dous ou máis inmobles urbanos; pero moitos compárteos coa súa parella ou con irmáns, e sumando só a súa parte de cada un, o {formatNumber(kpi[0]?.pct_dos_equivalentes, 1)} % chega a dous inmobles completos.

<DataTable data={resumen} rows=6>
    <Column id=definicion title="Definición" />
    <Column id=n_cumplen title="Deputados" fmt='0' />
    <Column id=pct title="% dos deputados" fmt='0.0' />
</DataTable>

## Fronte ao resto de contribuíntes

A Axencia Tributaria publica cantas declaracións do IRPF inclúen rendementos por inmobles alugados. No exercicio 2022, o mesmo da maioría das declaracións dos deputados, foi o {formatNumber(irpf[0]?.pct_todos, 1)} % de todas. Pero alugar é moito máis frecuente canto máis se gaña: entre quen declara rendementos de 60.000 a 150.000 euros é o {formatNumber(irpf[0]?.pct_tramo, 1)} %. Os deputados declaran alugueiros algo máis a miúdo que o conxunto dos contribuíntes e bastante menos que os dese tramo de ingresos.

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
    seriesColors={{'Declara alquileres': '#2563eb', '2 o más viviendas': '#93c5fd'}}
    title="Deputados que declaran alugueiros ou varias vivendas, grupos con 20 ou máis deputados"
/>

<DataTable data={grupos} rows=12>
    <Column id=grupo title="Grupo" />
    <Column id=diputados title="Deputados" fmt='0' />
    <Column id=pct_alquila title="% declara alugueiros" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 ou máis vivendas" fmt='0.0' />
    <Column id=pct_dos_urbanos title="% 2 ou máis urbanos" fmt='0.0' />
    <Column id=pct_dos_equivalentes title="% 2 ou máis completos" fmt='0.0' />
    <Column id=pct_sin_urbanos title="% sen urbanos" fmt='0.0' />
    <Column id=mediana_urbanos title="Mediana de urbanos" fmt='0' />
</DataTable>

Nos grupos pequenos cada deputado move moito a porcentaxe: con sete deputados, un só son 14 puntos.

## Metodoloxía e fontes

- **Declaracións**: [Congreso dos Deputados, fichas dos deputados](https://www.congreso.es/es/busqueda-de-diputados), declaración de bens e rendas inicial de cada deputado en activo da XV Lexislatura (presentadas entre o {resumen[0]?.primera} e o {resumen[0]?.ultima}). As modificacións posteriores non se usan porque adoitan ser parciais. Exclúense {kpi[0]?.n_excluidos} declaracións que non se poden ler ou que remiten a unha anterior.
- **Lectura**: os documentos son escaneos; léronse con recoñecemento óptico de caracteres e comprobouse a man unha mostra de 22 declaracións de todos os grupos: o número de inmobles urbanos e se declara alugueiros coincidían en 21 das 22. Pode haber erros puntuais noutros campos; por iso só se publican os totais, non as cifras de cada deputado.
- **Alugueiros**: o formulario non ten unha casa para eles; detéctanse polo concepto de cada renda («alquiler», «arrendamiento», «capital inmobiliario»...). Os importes son os declarados, que uns dan en neto, outros en bruto e algún ao mes, así que non se suman nin se comparan. As rendas imputadas por vivendas a disposición non contan como alugueiro.
- **Inmobles completos**: suma da parte de propiedade de cada inmoble urbano; cando consta como ganancial ou en proindiviso sen porcentaxe cóntase a metade.
- **Contribuíntes**: [Axencia Tributaria, Estatística dos declarantes do IRPF](https://sede.agenciatributaria.gob.es/AEAT/Contenidos_Comunes/La_Agencia_Tributaria/Estadisticas/Publicaciones/sites/irpf/2023/jrubikf3d7dfa31d2ce3af7d74ec0cde8d09ed9914891e7.html), partida 102 (rendementos de inmobles arrendados), territorio de réxime común. A unidade é a declaración, que pode ser conxunta, non a persoa.
