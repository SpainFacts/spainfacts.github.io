---
title: Zenbat diputatu dira etxe-jabe errentatzaile?
description: "Kongresuko zenbat diputatuk aitortzen dituzten alokairuagatiko diru-sarrerak edo dituzten hainbat etxebizitza, zer ondare higiezin aitortzen duten, zenbat hiri-higiezin oso dituen bakoitzak eta alderdi bakoitzak, beren ondasun eta errenten aitorpenen arabera, eta PFEZaren aitortzaile guztiekin alderatuta."
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

# <span aria-hidden="true">🏘️</span> Zenbat diputatu dira etxe-jabe errentatzaile?

{#if sin_declaracion.length}
<div role="alert" class="my-6 rounded-xl border-2 border-red-600 bg-red-50 p-5 dark:border-red-500 dark:bg-red-950/50">
    <p class="text-sm font-bold uppercase tracking-wider text-red-700 dark:text-red-300">⚠ Ondasun-aitorpenik gabeko diputatuak</p>
    {#each sin_declaracion as d}
    <div class="mt-4">
        <p class="text-2xl font-extrabold leading-tight text-red-700 dark:text-red-300">{d.nombre} <span class="whitespace-nowrap text-base font-semibold">({d.partido}, {d.circunscripcion})</span></p>
        {#if d.estado_declaracion === 'sin_declaracion'}
        <p class="mt-1 text-red-900 dark:text-red-100">Kongresuko bere fitxak ez du ondasun eta errenten aitorpenik estekatzen. Kongresuan noiztik: {d.alta}. <a class="font-semibold text-red-700 underline dark:text-red-300" href={d.url_ficha} target="_blank" rel="noopener">Ikusi fitxa ↗</a></p>
        {:else}
        <p class="mt-1 text-red-900 dark:text-red-100">Bere aitorpenak ez ditu bere ondasun guztiak zerrendatzen: hiri-higiezinetarako XIV. Legegintzaldiaren hasieran aurkeztutakora jotzen du, eta Kongresuak ez du hori argitaratzen dagoeneko. <a class="font-semibold text-red-700 underline dark:text-red-300" href={d.url_pdf} target="_blank" rel="noopener">Ikusi aitorpena ↗</a></p>
        {/if}
    </div>
    {/each}
    <p class="mt-4 text-sm text-red-800 dark:text-red-200">Ez dira orri honetako zifretan ezta rankingetan sartzen.</p>
</div>
{/if}

Kongresuko diputatuek, kargua hartzean, ondasun eta errenten aitorpen bat aurkezten dute, eta haien fitxan argitaratzen da. XV. Legegintzaldiko {kpi[0]?.n_diputados} diputatu aktiboenak irakurri ditugu, zenbatek aitortzen dituzten alokairuagatiko diru-sarrerak, zenbatek duten etxebizitza bat baino gehiago eta bakoitzak zer higiezin aitortzen dituen zenbatzeko. Ondoren datorren guztia haien aitorpenetan jasotakoa da.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if kpi.length && irpf.length}
    <KpiCard
        title="Alokairuagatiko diru-sarrerak aitortzen dituzte"
        value={kpi[0].pct_alquila}
        formattedValue={formatNumber(kpi[0].pct_alquila, 1) + ' %'}
        unit="diputatuena"
        period={`${kpi[0].n_alquila}/${kpi[0].n_validos} · PFEZ: aitortzaileen ${formatNumber(irpf[0].pct_todos, 1)} %`}
        source="Diputatuen Kongresua"
    />
    <KpiCard
        title="2 etxebizitza edo gehiago dituzte"
        value={kpi[0].pct_dos_viviendas}
        formattedValue={formatNumber(kpi[0].pct_dos_viviendas, 1) + ' %'}
        unit="diputatuena"
        period={`${kpi[0].n_dos_viviendas}/${kpi[0].n_validos} diputatu`}
        source="Diputatuen Kongresua"
    />
    <KpiCard
        title="2 hiri-higiezin oso edo gehiago"
        value={kpi[0].pct_dos_equivalentes}
        formattedValue={formatNumber(kpi[0].pct_dos_equivalentes, 1) + ' %'}
        unit="diputatuena"
        period={`Higiezin bakoitzean duten zatia batuta · ${kpi[0].n_dos_equivalentes} diputatu`}
        source="Diputatuen Kongresua"
    />
    <KpiCard
        title="Hiri-higiezin osoak diputatuko"
        value={kpi[0].media_completos}
        formattedValue={formatNumber(kpi[0].media_completos, 1)}
        unit="batez beste"
        period={`Mediana: ${formatNumber(kpi[0].mediana_completos, 1)} · ${kpi[0].n_sin_urbanos} diputatuk ez dute batere`}
        source="Diputatuen Kongresua"
    />
    {/if}
</div>

## Zer da etxe-jabe errentatzaile izatea

Ez dago neurtzeko modu bakar bat; beraz, hainbat ematen dira. Zorrotzena alokairuagatiko diru-sarrerak aitortzea da, eta hori ez da zehazki zerbait alokatuta izatearen berdina: norbaitek izan dezake eta ez zehaztu errenta bereizi gisa. Diputatuen {formatNumber(kpi[0]?.pct_alquila, 1)} %-k aitortzen ditu. Gutxienez bi etxebizitza dituztenak zenbatzen badira (haiengatik diru-sarrerarik aitortu ez arren: bigarren etxebizitzak izan daitezke edo hutsik egon), {formatNumber(kpi[0]?.pct_dos_viviendas, 1)} % dira. Garajeak, trastelekuak eta lokalak ere zenbatuta, {formatNumber(kpi[0]?.pct_dos_urbanos, 1)} %-k aitortzen ditu bi hiri-higiezin edo gehiago; baina askok bikotekidearekin edo anai-arrebekin partekatzen dituzte, eta bakoitzean duten zatia bakarrik batuta, {formatNumber(kpi[0]?.pct_dos_equivalentes, 1)} % iristen da bi higiezin osotara. Beste muturrean, {formatNumber(kpi[0]?.pct_sin_urbanos, 1)} %-k ez du hiri-higiezinik batere aitortzen.

<DataTable data={resumen} rows=6>
    <Column id=definicion title="Definizioa" />
    <Column id=n_cumplen title="Diputatuak" fmt='0' />
    <Column id=pct title="Diputatuen %" fmt='0.0' />
</DataTable>

## Gainerako zergadunekin alderatuta

Zerga Agentziak argitaratzen du PFEZaren zenbat aitorpenek dituzten alokatutako higiezinen etekinak. 2022ko ekitaldian, diputatuen aitorpen gehienena bera, guztien {formatNumber(irpf[0]?.pct_todos, 1)} % izan zen. Baina alokairuagatiko diru-sarrerak aitortzea askoz ohikoagoa da zenbat eta gehiago irabazi: 60.000 eta 150.000 euro arteko etekinak aitortzen dituztenen artean, {formatNumber(irpf[0]?.pct_tramo, 1)} % da. Diputatuek zergadun guztiek baino pixka bat maizago aitortzen dituzte alokairuagatiko diru-sarrerak, eta diru-sarreren tarte horretakoek baino dezente gutxiagotan.

<BarChart
    data={comparacion}
    x=colectivo
    y=pct
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    yAxisTitle="alokairuagatiko diru-sarrerak aitortzen dituenen %"
    title="Higiezinen alokairuagatiko diru-sarrerak aitortzen dituzte (2022ko ekitaldia)"
/>

<BarChart
    data={irpf_tramos}
    x=tramo
    y=pct
    sort=false
    yFmt='0"%"'
    xAxisTitle="Aitortutako etekinak (milaka euro)"
    yAxisTitle="aitorpenen %"
    title="Alokairuagatiko diru-sarrerak dituzten PFEZaren aitorpenak, irabazten denaren arabera (2022)"
/>

## Zer ondare higiezin aitortzen duten

Kongresuaren inprimakiak ez du higiezinen balioa eskatzen, haien mota, non dauden, noiz eskuratu ziren eta zer proportziotan diren diputatuarenak baizik. Horregatik, ondarea dutenaren arabera neurtzen da, ez balio duenaren arabera. Neurri bidezkoena **hiri-higiezin osoena** da: etxebizitza, garaje, lokal edo orube bakoitzean duten zatiaren batura (bikotekidearekin erdibana duten pisu batek erdia balio du). Landa-finkak aparte zenbatzen dira, asko landa-eremuan herentziaz jasotako lursail txikiak direlako, batez ere Galizian eta Asturiasen, eta ez dute askorik esaten jabearen ondareaz.

<BarChart
    data={distribucion}
    x=tramo
    y=diputados
    sort=false
    yFmt='0'
    xAxisTitle="Hiri-higiezin osoak"
    yAxisTitle="Diputatuak"
    title="Diputatuak, aitortzen dituzten hiri-higiezin osoen arabera"
/>

<BarChart
    data={tipos_total}
    x=categoria
    y=por_diputado
    swapXY=true
    sort=false
    yFmt='0.00'
    yAxisTitle="Higiezinak diputatuko (batez bestekoa)"
    title="Zer higiezin aitortzen dituzten: batez bestekoa diputatuko, higiezin bakoitza zenbatuta zati batean bakarrik izan arren"
/>

Herentziaz jasoak ala erosiak? Aitortutako hiri-higiezinen {formatNumber(adquisicion_total[0]?.pct_compra, 0)} % erosi ziren eta {formatNumber(adquisicion_total[0]?.pct_herencia, 0)} % herentziaz edo dohaintzaz iritsi ziren; gainerakoetan aitorpenak ez du esaten.

<BarChart
    data={adquisicion}
    x=partido
    y=pct
    series=categoria
    type=stacked
    sort=false
    yFmt='0"%"'
    yAxisTitle="hiri-higiezinen %"
    seriesColors={{'Compra': '#2563eb', 'Herencia o donación': '#f59e0b', 'Otro o no consta': '#d4d4d4'}}
    title="Nola eskuratu zituzten beren hiri-higiezinak, 5 diputatu edo gehiagoko alderdiak"
/>

## Talde parlamentarioka

<BarChart
    data={grupos_largo}
    x=grupo
    y=pct
    series=medida
    type=grouped
    sort=false
    yFmt='0"%"'
    yAxisTitle="taldeko diputatuen %"
    seriesColors={{'Declara ingresos por alquiler': '#2563eb', '2 o más viviendas': '#93c5fd'}}
    title="Alokairuagatiko diru-sarrerak edo hainbat etxebizitza aitortzen dituzten diputatuak, 20 diputatu edo gehiagoko taldeak"
/>

<DataTable data={grupos} rows=12>
    <Column id=grupo title="Taldea" />
    <Column id=diputados title="Diputatuak" fmt='0' />
    <Column id=pct_alquila title="% alokairuagatiko diru-sarrerak aitortzen ditu" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 etxebizitza edo gehiago" fmt='0.0' />
    <Column id=pct_dos_urbanos title="% 2 hiri-higiezin edo gehiago" fmt='0.0' />
    <Column id=pct_dos_equivalentes title="% 2 oso edo gehiago" fmt='0.0' />
    <Column id=pct_sin_urbanos title="% hiri-higiezinik gabe" fmt='0.0' />
    <Column id=mediana_urbanos title="Hiri-higiezinen mediana" fmt='0' />
</DataTable>

Talde txikietan diputatu bakoitzak asko mugitzen du ehunekoa: zazpi diputaturekin, bakar bat 14 puntu da.

## Alderdien rankinga

Alderdien tamainak oso desberdinak direnez, diputatuka alderatzen dira: diputatu bakoitzak batez beste zenbat hiri-higiezin oso aitortzen dituen. Diputatuak hautatu zituen alderdiaren arabera taldekatzen dira, PSC eta gainerako federazioak PSOEren barruan.

<BarChart
    data={partidos_grafico}
    x=partido
    y=media_urbanos_equivalentes
    sort=false
    yFmt='0.0'
    yAxisTitle="Hiri-higiezin osoak diputatuko (batez bestekoa)"
    title="Hiri-higiezin osoak diputatuko, 5 diputatu edo gehiagoko alderdiak"
/>

<BarChart
    data={partidos_tipos}
    x=partido
    y=por_diputado
    series=categoria
    type=stacked
    sort=false
    yFmt='0.0'
    yAxisTitle="Higiezinak diputatuko (batez bestekoa)"
    seriesColors={{'Vivienda': '#1d4ed8', 'Garaje o trastero': '#60a5fa', 'Local, oficina o nave': '#7c3aed', 'Otros urbanos (solares, edificios...)': '#c4b5fd', 'Finca rústica': '#a3a3a3'}}
    title="Zer higiezin aitortzen dituzten haien diputatuek, higiezin bakoitza zenbatuta zati batean bakarrik izan arren"
/>

<DataTable data={partidos} rows=12>
    <Column id=partido title="Alderdia" />
    <Column id=diputados title="Diputatuak" fmt='0' />
    <Column id=media_urbanos_equivalentes title="Hiri-higiezin osoak diputatuko (batez bestekoa)" fmt='0.0' />
    <Column id=mediana_urbanos_equivalentes title="Mediana" fmt='0.0' />
    <Column id=media_urbanos title="Hirikoak (batez bestekoa)" fmt='0.0' />
    <Column id=media_viviendas title="Etxebizitzak (batez bestekoa)" fmt='0.0' />
    <Column id=media_rusticos title="Landa-finkak (batez bestekoa)" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 etxebizitza edo gehiago" fmt='0.0' />
    <Column id=max_urbanos_equivalentes title="Diputatu baten gehienekoa" fmt='0.0' />
</DataTable>

Higiezin asko dituzten diputatu gutxi batzuek batez bestekoa gora botatzen dute: medianak adierazten du alderdi bakoitzeko diputatu tipikoak zenbat dituen. Diputatu bat edo bi dituzten alderdiak (BNG, UPN, CC) erabat pertsona horren mende daude.

## Hiri-higiezin oso gehien dituzten diputatuak

<BarChart
    data={ranking_top}
    x=diputado
    y=urbanos_equivalentes
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="Hiri-higiezin osoak (bakoitzean duten zatiaren batura)"
    title="Hiri-higiezin oso gehien dituzten 15 diputatuak"
/>

<DataTable data={ranking} rows=25 search=true>
    <Column id=puesto title="#" fmt='0' />
    <Column id=nombre title="Diputatua" />
    <Column id=partido title="Alderdia" />
    <Column id=circunscripcion title="Barrutia" />
    <Column id=urbanos_equivalentes title="Hiri-higiezin osoak" fmt='0.0' />
    <Column id=n_urbanos title="Hirikoak (zati batean bakarrik izan arren)" fmt='0' />
    <Column id=n_viviendas_urbanas title="Etxebizitzak" fmt='0' />
    <Column id=n_rusticos title="Landa-finkak" fmt='0' />
    <Column id=n_inmuebles_sociedad title="Haien sozietateenak" fmt='0' />
    <Column id=alquila title="Alokairuagatiko diru-sarrerak aitortzen ditu" />
    <Column id=url_pdf title="Aitorpena" contentType=link linkLabel="PDF ↗" openInNewTab=true />
</DataTable>

Ordena «Hiri-higiezin osoak» zutabeak ematen du: lau anai-arreben artean herentziaz jasotako pisu batek laurdena balio du, eta bikotekidearekin erdibana dagoen batek, erdia. Landa-finkak eta parte hartzen duten sozietateen higiezinak erakusten dira, baina ez dute postuan eraginik. Errenkada bakoitzak Kongresuaren webguneko jatorrizko aitorpenerako esteka du.

## Metodologia eta iturriak

- **Aitorpenak**: [Diputatuen Kongresua, diputatuen fitxak](https://www.congreso.es/es/busqueda-de-diputados), XV. Legegintzaldiko diputatu aktibo bakoitzaren hasierako ondasun eta errenten aitorpena ({resumen[0]?.primera} eta {resumen[0]?.ultima} artean aurkeztuak). Ondorengo aldaketak ez dira erabiltzen, partzialak izan ohi direlako. Irakurri ezin diren edo aurreko batera bidaltzen duten {kpi[0]?.n_excluidos} aitorpen baztertzen dira.
- **Irakurketa**: dokumentuak eskaneatuak dira. Aitorpen bakoitza eskuz berrikusi da PDFan, Oharren laukia barne, diputatu batzuek han jarraitzen baitute higiezinen zerrenda: zenbaketak, higiezin bakoitzaren jabetza-zatia, mota, oinordetzan jaso edo erosi zen eta alokairuagatiko diru-sarrerak aitortzen diren berrikuspen horretatik datoz, ez irakurketa automatikotik, akats gehiegi egiten baitzituen. Aipatutako ondasun bakoitzak bat balio du («etxebizitza, garaje-plaza eta trastelekua» hiru dira). Diputatu bakoitzak bere aitorpenerako esteka du egiaztatu ahal izateko.
- **Alokairuagatiko diru-sarrerak**: inprimakiak ez du haientzako laukitxorik; errenta bakoitzaren kontzeptuaren bidez detektatzen dira («alquiler», «arrendamiento», «capital inmobiliario»...). Zenbatekoak aitortutakoak dira, eta batzuek garbian ematen dituzte, beste batzuek gordinean eta norbaitek hilean; beraz, ez dira batzen ezta alderatzen ere. Eskura dauden etxebizitzengatik egotzitako errentak ez dira alokairutzat hartzen.
- **Hiri-higiezin osoak**: hiri-higiezin bakoitzaren (etxebizitzak, garajeak, trastelekuak, lokalak, orubeak) jabetza-zatiaren batura; irabazpidezkoa edo ehunekorik gabeko proindibisoa gisa ageri denean, erdia zenbatzen da. Inprimakiak ez du higiezinen balioa eskatzen; beraz, Madrilgo erdiguneko pisu bat eta herri bateko etxe bat berdin zenbatzen dira.
- **Zergadunak**: [Zerga Agentzia, PFEZaren aitortzaileen estatistika](https://sede.agenciatributaria.gob.es/AEAT/Contenidos_Comunes/La_Agencia_Tributaria/Estadisticas/Publicaciones/sites/irpf/2023/jrubikf3d7dfa31d2ce3af7d74ec0cde8d09ed9914891e7.html), 102. partida (errentan emandako higiezinen etekinak), erregimen erkideko lurraldea. Unitatea aitorpena da, baterakoa izan daitekeena, ez pertsona.
