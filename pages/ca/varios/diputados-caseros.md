---
title: Quants diputats són arrendadors?
description: "Quants diputats del Congrés declaren ingressos per lloguer o tenen diversos habitatges, quin patrimoni immobiliari declaren, quants immobles urbans complets té cadascun i cada partit, segons les seves declaracions de béns i rendes, i davant el conjunt de declarants de l'IRPF."
i18n_origen: 965f8dba6a2e
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

# <span aria-hidden="true">🏘️</span> Quants diputats són arrendadors?

{#if sin_declaracion.length}
<div role="alert" class="my-6 rounded-xl border-2 border-red-600 bg-red-50 p-5 dark:border-red-500 dark:bg-red-950/50">
    <p class="text-sm font-bold uppercase tracking-wider text-red-700 dark:text-red-300">⚠ Diputats sense declaració de béns</p>
    {#each sin_declaracion as d}
    <div class="mt-4">
        <p class="text-2xl font-extrabold leading-tight text-red-700 dark:text-red-300">{d.nombre} <span class="whitespace-nowrap text-base font-semibold">({d.partido}, {d.circunscripcion})</span></p>
        {#if d.estado_declaracion === 'sin_declaracion'}
        <p class="mt-1 text-red-900 dark:text-red-100">La seva fitxa del Congrés no enllaça cap declaració de béns i rendes. Al Congrés des del {d.alta}. <a class="font-semibold text-red-700 underline dark:text-red-300" href={d.url_ficha} target="_blank" rel="noopener">Veure la fitxa ↗</a></p>
        {:else}
        <p class="mt-1 text-red-900 dark:text-red-100">La seva declaració no enumera tots els seus béns: per als immobles urbans es remet a la que va presentar a l'inici de la XIV Legislatura, que el Congrés ja no publica. <a class="font-semibold text-red-700 underline dark:text-red-300" href={d.url_pdf} target="_blank" rel="noopener">Veure la declaració ↗</a></p>
        {/if}
    </div>
    {/each}
    <p class="mt-4 text-sm text-red-800 dark:text-red-200">No entren a les xifres ni als rànquings d'aquesta pàgina.</p>
</div>
{/if}

Els diputats del Congrés presenten en prendre possessió una declaració de béns i rendes que es publica a la seva fitxa. Hem llegit les dels {kpi[0]?.n_diputados} diputats en actiu de la XV Legislatura per comptar quants declaren ingressos per lloguer, quants tenen més d'un habitatge i quins immobles declara cadascun. Tot el que segueix és el que consta a les seves declaracions.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if kpi.length && irpf.length}
    <KpiCard
        title="Declaren ingressos per lloguer"
        value={kpi[0].pct_alquila}
        formattedValue={formatNumber(kpi[0].pct_alquila, 1) + ' %'}
        unit="dels diputats"
        period={`${kpi[0].n_alquila} de ${kpi[0].n_validos} · IRPF: ${formatNumber(irpf[0].pct_todos, 1)} % dels declarants`}
        source="Congrés dels Diputats"
    />
    <KpiCard
        title="Tenen 2 o més habitatges"
        value={kpi[0].pct_dos_viviendas}
        formattedValue={formatNumber(kpi[0].pct_dos_viviendas, 1) + ' %'}
        unit="dels diputats"
        period={`${kpi[0].n_dos_viviendas} de ${kpi[0].n_validos} diputats`}
        source="Congrés dels Diputats"
    />
    <KpiCard
        title="2 o més immobles urbans complets"
        value={kpi[0].pct_dos_equivalentes}
        formattedValue={formatNumber(kpi[0].pct_dos_equivalentes, 1) + ' %'}
        unit="dels diputats"
        period={`Sumant la seva part de cada immoble · ${kpi[0].n_dos_equivalentes} diputats`}
        source="Congrés dels Diputats"
    />
    <KpiCard
        title="Immobles urbans complets per diputat"
        value={kpi[0].media_completos}
        formattedValue={formatNumber(kpi[0].media_completos, 1)}
        unit="de mitjana"
        period={`Mediana: ${formatNumber(kpi[0].mediana_completos, 1)} · ${kpi[0].n_sin_urbanos} diputats sense cap`}
        source="Congrés dels Diputats"
    />
    {/if}
</div>

## Què és ser arrendador

No hi ha una única manera de mesurar-ho, així que se'n donen diverses. La més estricta és declarar ingressos per lloguer, que no és exactament el mateix que tenir alguna cosa llogada: algú pot tenir-la i no detallar-la com a renda a part. Ho declara el {formatNumber(kpi[0]?.pct_alquila, 1)} % dels diputats. Si es compta els qui tenen almenys dos habitatges (encara que no hi declarin ingressos: poden ser segones residències o estar buits), són el {formatNumber(kpi[0]?.pct_dos_viviendas, 1)} %. Comptant també garatges, trasters i locals, el {formatNumber(kpi[0]?.pct_dos_urbanos, 1)} % declara dos o més immobles urbans; però molts els comparteixen amb la parella o amb germans, i sumant només la seva part de cadascun, el {formatNumber(kpi[0]?.pct_dos_equivalentes, 1)} % arriba a dos immobles complets. A l'altre extrem, el {formatNumber(kpi[0]?.pct_sin_urbanos, 1)} % no declara cap immoble urbà.

<DataTable data={resumen} rows=6>
    <Column id=definicion title="Definició" />
    <Column id=n_cumplen title="Diputats" fmt='0' />
    <Column id=pct title="% dels diputats" fmt='0.0' />
</DataTable>

## Davant la resta de contribuents

L'Agència Tributària publica quantes declaracions de l'IRPF inclouen rendiments per immobles llogats. A l'exercici 2022, el mateix de la majoria de les declaracions dels diputats, va ser el {formatNumber(irpf[0]?.pct_todos, 1)} % de totes. Però declarar ingressos per lloguer és molt més freqüent com més es guanya: entre els qui declaren rendiments de 60.000 a 150.000 euros és el {formatNumber(irpf[0]?.pct_tramo, 1)} %. Els diputats declaren ingressos per lloguer una mica més sovint que el conjunt dels contribuents i força menys que els d'aquest tram d'ingressos.

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

## Quin patrimoni immobiliari declaren

El formulari del Congrés no demana el valor dels immobles, només la seva classe, on són, quan es van adquirir i en quina proporció són del diputat. Per això el patrimoni es mesura pel que tenen, no pel que val. La mesura més justa és la d'**immobles urbans complets**: la suma de la seva part de cada habitatge, garatge, local o solar (un pis a mitges amb la parella compta mig). Les finques rústiques es compten a part, perquè moltes són parcel·les petites heretades en el món rural, sobretot a Galícia i Astúries, i no diuen gaire del patrimoni de qui les té.

<BarChart
    data={distribucion}
    x=tramo
    y=diputados
    sort=false
    yFmt='0'
    xAxisTitle="Immobles urbans complets"
    yAxisTitle="Diputats"
    title="Diputats segons els immobles urbans complets que declaren"
/>

<BarChart
    data={tipos_total}
    x=categoria
    y=por_diputado
    swapXY=true
    sort=false
    yFmt='0.00'
    yAxisTitle="Immobles per diputat (mitjana)"
    title="Quins immobles declaren: mitjana per diputat, comptant cada immoble encara que sigui en part"
/>

Heretats o comprats? El {formatNumber(adquisicion_total[0]?.pct_compra, 0)} % dels immobles urbans declarats es van comprar i el {formatNumber(adquisicion_total[0]?.pct_herencia, 0)} % van arribar per herència o donació; en la resta la declaració no ho diu.

<BarChart
    data={adquisicion}
    x=partido
    y=pct
    series=categoria
    type=stacked
    sort=false
    yFmt='0"%"'
    yAxisTitle="% dels immobles urbans"
    seriesColors={{'Compra': '#2563eb', 'Herencia o donación': '#f59e0b', 'Otro o no consta': '#d4d4d4'}}
    title="Com van adquirir els seus immobles urbans, partits amb 5 o més diputats"
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
    seriesColors={{'Declara ingresos por alquiler': '#2563eb', '2 o más viviendas': '#93c5fd'}}
    title="Diputats que declaren ingressos per lloguer o diversos habitatges, grups amb 20 o més diputats"
/>

<DataTable data={grupos} rows=12>
    <Column id=grupo title="Grup" />
    <Column id=diputados title="Diputats" fmt='0' />
    <Column id=pct_alquila title="% declara ingressos per lloguer" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 o més habitatges" fmt='0.0' />
    <Column id=pct_dos_urbanos title="% 2 o més urbans" fmt='0.0' />
    <Column id=pct_dos_equivalentes title="% 2 o més complets" fmt='0.0' />
    <Column id=pct_sin_urbanos title="% sense urbans" fmt='0.0' />
    <Column id=mediana_urbanos title="Mediana d'urbans" fmt='0' />
</DataTable>

En els grups petits cada diputat mou molt el percentatge: amb set diputats, un de sol són 14 punts.

## Rànquing per partit

Com que els partits tenen mides molt diferents, es comparen per diputat: quants immobles urbans complets declara de mitjana cadascun dels seus diputats. Els diputats s'agrupen per la formació per la qual van ser elegits, amb el PSC i les altres federacions dins del PSOE.

<BarChart
    data={partidos_grafico}
    x=partido
    y=media_urbanos_equivalentes
    sort=false
    yFmt='0.0'
    yAxisTitle="Immobles urbans complets per diputat (mitjana)"
    title="Immobles urbans complets per diputat, partits amb 5 o més diputats"
/>

<BarChart
    data={partidos_tipos}
    x=partido
    y=por_diputado
    series=categoria
    type=stacked
    sort=false
    yFmt='0.0'
    yAxisTitle="Immobles per diputat (mitjana)"
    seriesColors={{'Vivienda': '#1d4ed8', 'Garaje o trastero': '#60a5fa', 'Local, oficina o nave': '#7c3aed', 'Otros urbanos (solares, edificios...)': '#c4b5fd', 'Finca rústica': '#a3a3a3'}}
    title="Quins immobles declaren els seus diputats, comptant cada immoble encara que sigui en part"
/>

<DataTable data={partidos} rows=12>
    <Column id=partido title="Partit" />
    <Column id=diputados title="Diputats" fmt='0' />
    <Column id=media_urbanos_equivalentes title="Urbans complets per diputat (mitjana)" fmt='0.0' />
    <Column id=mediana_urbanos_equivalentes title="Mediana" fmt='0.0' />
    <Column id=media_urbanos title="Urbans (mitjana)" fmt='0.0' />
    <Column id=media_viviendas title="Habitatges (mitjana)" fmt='0.0' />
    <Column id=media_rusticos title="Finques rústiques (mitjana)" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 o més habitatges" fmt='0.0' />
    <Column id=max_urbanos_equivalentes title="Màxim d'un diputat" fmt='0.0' />
</DataTable>

La mitjana puja amb uns pocs diputats amb molts immobles: la mediana diu quants en té el diputat típic de cada partit. Els partits amb un o dos diputats (BNG, UPN, CC) depenen del tot d'aquesta persona.

## Els diputats amb més immobles urbans complets

<BarChart
    data={ranking_top}
    x=diputado
    y=urbanos_equivalentes
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="Immobles urbans complets (suma de la seva part de cadascun)"
    title="Els 15 diputats amb més immobles urbans complets"
/>

<DataTable data={ranking} rows=25 search=true>
    <Column id=puesto title="#" fmt='0' />
    <Column id=nombre title="Diputat" />
    <Column id=partido title="Partit" />
    <Column id=circunscripcion title="Circumscripció" />
    <Column id=urbanos_equivalentes title="Urbans complets" fmt='0.0' />
    <Column id=n_urbanos title="Urbans (encara que sigui en part)" fmt='0' />
    <Column id=n_viviendas_urbanas title="Habitatges" fmt='0' />
    <Column id=n_rusticos title="Finques rústiques" fmt='0' />
    <Column id=n_inmuebles_sociedad title="De les seves societats" fmt='0' />
    <Column id=alquila title="Declara ingressos per lloguer" />
    <Column id=url_pdf title="Declaració" contentType=link linkLabel="PDF ↗" openInNewTab=true />
</DataTable>

L'ordre el dona la columna «Urbans complets»: un pis heretat entre quatre germans compta un quart, i un a mitges amb la parella, mig. Les finques rústiques i els immobles de societats en què participen es mostren però no compten per a la posició. Cada fila enllaça amb la declaració original al web del Congrés.

## Metodologia i fonts

- **Declaracions**: [Congrés dels Diputats, fitxes dels diputats](https://www.congreso.es/es/busqueda-de-diputados), declaració de béns i rendes inicial de cada diputat en actiu de la XV Legislatura (presentades entre el {resumen[0]?.primera} i el {resumen[0]?.ultima}). Les modificacions posteriors no s'utilitzen perquè solen ser parcials. S'exclouen {kpi[0]?.n_excluidos} declaracions que no es poden llegir o que remeten a una d'anterior.
- **Lectura**: els documents són escanejos. S'ha revisat a mà cada declaració al PDF, inclòs el requadre d'Observacions, on alguns continuen la llista d'immobles: els recomptes, la part de propietat de cada immoble, el seu tipus, si es va heretar o comprar i si es declaren ingressos per lloguer surten d'aquesta revisió, no de la lectura automàtica, que s'equivocava massa. Cada bé esmentat compta com un («habitatge, plaça de garatge i traster» són tres). Cada diputat enllaça amb la seva declaració per comprovar-ho.
- **Ingressos per lloguer**: el formulari no té cap casella per a ells; es detecten pel concepte de cada renda («alquiler», «arrendamiento», «capital inmobiliario»...). Els imports són els declarats, que uns donen en net, altres en brut i algun al mes, així que no se sumen ni es comparen. Les rendes imputades per habitatges a disposició no compten com a lloguer.
- **Immobles urbans complets**: suma de la part de propietat de cada immoble urbà (habitatges, garatges, trasters, locals, solars); quan consta com a bé de guanys o en proindivís sense percentatge es compta la meitat. El formulari no demana el valor dels immobles, així que un pis al centre de Madrid i una casa en un poble compten igual.
- **Contribuents**: [Agència Tributària, Estadística dels declarants de l'IRPF](https://sede.agenciatributaria.gob.es/AEAT/Contenidos_Comunes/La_Agencia_Tributaria/Estadisticas/Publicaciones/sites/irpf/2023/jrubikf3d7dfa31d2ce3af7d74ec0cde8d09ed9914891e7.html), partida 102 (rendiments d'immobles arrendats), territori de règim comú. La unitat és la declaració, que pot ser conjunta, no la persona.
