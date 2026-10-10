---
title: Quants diputats són arrendadors?
description: "Quants diputats del Congrés declaren ingressos per lloguer o tenen diversos habitatges, segons les seves declaracions de béns i rendes, per grup parlamentari i davant el conjunt de declarants de l'IRPF."
i18n_origen: b1840c4f7433
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

# <span aria-hidden="true">🏘️</span> Quants diputats són arrendadors?

Els diputats del Congrés presenten en prendre possessió una declaració de béns i rendes que es publica a la seva fitxa. Hem llegit les dels {kpi[0]?.n_diputados} diputats en actiu de la XV Legislatura per comptar quants declaren ingressos per llogar immobles i quants tenen més d'un habitatge. Tot el que segueix és el que consta en les seves declaracions.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if kpi.length && irpf.length}
    <KpiCard
        title="Declaren ingressos per lloguer"
        value={kpi[0].pct_alquila}
        formattedValue={formatNumber(kpi[0].pct_alquila, 1) + ' %'}
        unit="dels diputats"
        period={`${kpi[0].n_alquila} de ${kpi[0].n_validos} · IRPF: ${formatNumber(irpf[0].pct_todos, 1)} % dels declarants`}
        source="Congrés dels Diputats"
        sparklineData={resumen.map(d => ({...d, y: d.pct}))}
    />
    <KpiCard
        title="Tenen 2 o més habitatges"
        value={kpi[0].pct_dos_viviendas}
        formattedValue={formatNumber(kpi[0].pct_dos_viviendas, 1) + ' %'}
        unit="dels diputats"
        period={`${kpi[0].n_dos_viviendas} diputats`}
        source="Congrés dels Diputats"
        sparklineData={resumen.map(d => ({...d, y: d.pct}))}
    />
    <KpiCard
        title="2 o més immobles urbans complets"
        value={kpi[0].pct_dos_equivalentes}
        formattedValue={formatNumber(kpi[0].pct_dos_equivalentes, 1) + ' %'}
        unit="dels diputats"
        period={`Sumant la seva part de cada immoble · ${kpi[0].n_dos_equivalentes} diputats`}
        source="Congrés dels Diputats"
        sparklineData={resumen.map(d => ({...d, y: d.pct}))}
    />
    <KpiCard
        title="Sense cap immoble urbà"
        value={kpi[0].pct_sin_urbanos}
        formattedValue={formatNumber(kpi[0].pct_sin_urbanos, 1) + ' %'}
        unit="dels diputats"
        period={`Mediana: ${formatNumber(kpi[0].mediana_urbanos, 0)} immobles urbans per diputat`}
        source="Congrés dels Diputats"
        sparklineData={resumen.map(d => ({...d, y: d.pct}))}
    />
    {/if}
</div>

## Què és ser arrendador

No hi ha una única manera de mesurar-ho, així que se'n donen diverses. La més estricta és declarar ingressos per lloguer: el {formatNumber(kpi[0]?.pct_alquila, 1)} % dels diputats ho fa. Si es compta els qui tenen almenys dos habitatges (encara que no declarin que els lloguen: poden ser segones residències o estar buits), són el {formatNumber(kpi[0]?.pct_dos_viviendas, 1)} %. Comptant també garatges, trasters i locals, el {formatNumber(kpi[0]?.pct_dos_urbanos, 1)} % declara dos o més immobles urbans; però molts els comparteixen amb la seva parella o amb germans, i sumant només la seva part de cadascun, el {formatNumber(kpi[0]?.pct_dos_equivalentes, 1)} % arriba a dos immobles complets.

<DataTable data={resumen} rows=6>
    <Column id=definicion title="Definició" />
    <Column id=n_cumplen title="Diputats" fmt='0' />
    <Column id=pct title="% dels diputats" fmt='0.0' />
</DataTable>

## Davant la resta de contribuents

L'Agència Tributària publica quantes declaracions de l'IRPF inclouen rendiments per immobles llogats. En l'exercici 2022, el mateix de la majoria de les declaracions dels diputats, va ser el {formatNumber(irpf[0]?.pct_todos, 1)} % de totes. Però llogar és molt més freqüent com més es guanya: entre els qui declaren rendiments de 60.000 a 150.000 euros és el {formatNumber(irpf[0]?.pct_tramo, 1)} %. Els diputats declaren lloguers una mica més sovint que el conjunt dels contribuents i força menys que els d'aquest tram d'ingressos.

<BarChart
    data={comparacion}
    x=colectivo
    y=pct
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    yAxisTitle="% que declara ingressos per lloguer"
    title="Declaren ingressos per lloguer d'immobles (exercici 2022)"
/>

<BarChart
    data={irpf_tramos}
    x=tramo
    y=pct
    sort=false
    yFmt='0"%"'
    xAxisTitle="Rendiments declarats (milers d'euros)"
    yAxisTitle="% de les declaracions"
    title="Declaracions de l'IRPF amb ingressos per lloguer, segons el que es guanya (2022)"
/>

## Per grup parlamentari

<BarChart
    data={grupos_largo}
    x=grupo
    y=pct
    series=medida
    type=grouped
    sort=false
    yFmt='0"%"'
    yAxisTitle="% dels diputats del grup"
    seriesColors={{'Declara alquileres': '#2563eb', '2 o más viviendas': '#93c5fd'}}
    title="Diputats que declaren lloguers o diversos habitatges, grups amb 20 o més diputats"
/>

<DataTable data={grupos} rows=12>
    <Column id=grupo title="Grup" />
    <Column id=diputados title="Diputats" fmt='0' />
    <Column id=pct_alquila title="% declara lloguers" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 o més habitatges" fmt='0.0' />
    <Column id=pct_dos_urbanos title="% 2 o més urbans" fmt='0.0' />
    <Column id=pct_dos_equivalentes title="% 2 o més complets" fmt='0.0' />
    <Column id=pct_sin_urbanos title="% sense urbans" fmt='0.0' />
    <Column id=mediana_urbanos title="Mediana d'urbans" fmt='0' />
</DataTable>

En els grups petits cada diputat mou molt el percentatge: amb set diputats, un de sol són 14 punts.

## Metodologia i fonts

- **Declaracions**: [Congrés dels Diputats, fitxes dels diputats](https://www.congreso.es/es/busqueda-de-diputados), declaració de béns i rendes inicial de cada diputat en actiu de la XV Legislatura (presentades entre el {resumen[0]?.primera} i el {resumen[0]?.ultima}). Les modificacions posteriors no s'utilitzen perquè solen ser parcials. S'exclouen {kpi[0]?.n_excluidos} declaracions que no es poden llegir o que remeten a una d'anterior.
- **Lectura**: els documents són escanejos; s'han llegit amb reconeixement òptic de caràcters i s'ha comprovat a mà una mostra de 22 declaracions de tots els grups: el nombre d'immobles urbans i si declara lloguers coincidien en 21 de les 22. Hi pot haver errors puntuals en altres camps; per això només es publiquen els totals, no les xifres de cada diputat.
- **Lloguers**: el formulari no té una casella per a ells; es detecten pel concepte de cada renda («alquiler», «arrendamiento», «capital inmobiliario»...). Els imports són els declarats, que uns donen en net, altres en brut i algun al mes, així que no se sumen ni es comparen. Les rendes imputades per habitatges a disposició no compten com a lloguer.
- **Immobles complets**: suma de la part de propietat de cada immoble urbà; quan consta com a bé de guanys o en proindivís sense percentatge es compta la meitat.
- **Contribuents**: [Agència Tributària, Estadística dels declarants de l'IRPF](https://sede.agenciatributaria.gob.es/AEAT/Contenidos_Comunes/La_Agencia_Tributaria/Estadisticas/Publicaciones/sites/irpf/2023/jrubikf3d7dfa31d2ce3af7d74ec0cde8d09ed9914891e7.html), partida 102 (rendiments d'immobles arrendats), territori de règim comú. La unitat és la declaració, que pot ser conjunta, no la persona.
