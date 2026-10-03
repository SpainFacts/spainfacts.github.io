---
title: Zenbat diputatu dira etxe-jabe errentatzaile?
description: "Kongresuko zenbat diputatuk aitortzen dituzten alokairuagatiko diru-sarrerak edo dituzten hainbat etxebizitza, beren ondasun eta errenten aitorpenen arabera, talde parlamentarioka eta PFEZaren aitortzaile guztiekin alderatuta."
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
# <span aria-hidden="true">🏘️</span> Zenbat diputatu dira etxe-jabe errentatzaile?

Kongresuko diputatuek, kargua hartzean, ondasun eta errenten aitorpen bat aurkezten dute, eta haien fitxan argitaratzen da. XV. Legegintzaldiko {kpi[0]?.n_diputados} diputatu aktiboenak irakurri ditugu, zenbatek aitortzen dituzten higiezinak alokatzeagatiko diru-sarrerak eta zenbatek duten etxebizitza bat baino gehiago zenbatzeko. Ondoren datorren guztia haien aitorpenetan jasotakoa da.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if kpi.length && irpf.length}
    <KpiCard
        title="Alokairuagatiko diru-sarrerak aitortzen dituzte"
        value={kpi[0].pct_alquila}
        formattedValue={formatNumber(kpi[0].pct_alquila, 1) + ' %'}
        unit="diputatuena"
        period={`${kpi[0].n_alquila}/${kpi[0].n_validos} diputatu · PFEZ: aitortzaileen ${formatNumber(irpf[0].pct_todos, 1)} %`}
        source="Diputatuen Kongresua"
        sparklineData={resumen.map(d => d.pct)}
    />
    <KpiCard
        title="2 etxebizitza edo gehiago dituzte"
        value={kpi[0].pct_dos_viviendas}
        formattedValue={formatNumber(kpi[0].pct_dos_viviendas, 1) + ' %'}
        unit="diputatuena"
        period={`${kpi[0].n_dos_viviendas} diputatu`}
        source="Diputatuen Kongresua"
        sparklineData={resumen.map(d => d.pct)}
    />
    <KpiCard
        title="2 hiri-higiezin oso edo gehiago"
        value={kpi[0].pct_dos_equivalentes}
        formattedValue={formatNumber(kpi[0].pct_dos_equivalentes, 1) + ' %'}
        unit="diputatuena"
        period={`Higiezin bakoitzean duten zatia batuta · ${kpi[0].n_dos_equivalentes} diputatu`}
        source="Diputatuen Kongresua"
        sparklineData={resumen.map(d => d.pct)}
    />
    <KpiCard
        title="Hiri-higiezinik batere gabe"
        value={kpi[0].pct_sin_urbanos}
        formattedValue={formatNumber(kpi[0].pct_sin_urbanos, 1) + ' %'}
        unit="diputatuena"
        period={`Mediana: ${formatNumber(kpi[0].mediana_urbanos, 0)} hiri-higiezin diputatu bakoitzeko`}
        source="Diputatuen Kongresua"
        sparklineData={resumen.map(d => d.pct)}
    />
    {/if}
</div>

## Zer da etxe-jabe errentatzaile izatea

Ez dago neurtzeko modu bakar bat; beraz, hainbat ematen dira. Zorrotzena alokairuagatiko diru-sarrerak aitortzea da: diputatuen {formatNumber(kpi[0]?.pct_alquila, 1)} %-k egiten du. Gutxienez bi etxebizitza dituztenak zenbatzen badira (alokatzen dituztela aitortu ez arren: bigarren etxebizitzak izan daitezke edo hutsik egon), {formatNumber(kpi[0]?.pct_dos_viviendas, 1)} % dira. Garajeak, trastelekuak eta lokalak ere zenbatuta, {formatNumber(kpi[0]?.pct_dos_urbanos, 1)} %-k aitortzen ditu bi hiri-higiezin edo gehiago; baina askok bikotekidearekin edo anai-arrebekin partekatzen dituzte, eta bakoitzean duten zatia bakarrik batuta, {formatNumber(kpi[0]?.pct_dos_equivalentes, 1)} % iristen da bi higiezin osotara.

<DataTable data={resumen} rows=6>
    <Column id=definicion title="Definizioa" />
    <Column id=n_cumplen title="Diputatuak" fmt='0' />
    <Column id=pct title="Diputatuen %" fmt='0.0' />
</DataTable>

## Gainerako zergadunekin alderatuta

Zerga Agentziak argitaratzen du PFEZaren zenbat aitorpenek dituzten alokatutako higiezinen etekinak. 2022ko ekitaldian, diputatuen aitorpen gehienena bera, guztien {formatNumber(irpf[0]?.pct_todos, 1)} % izan zen. Baina alokatzea askoz ohikoagoa da zenbat eta gehiago irabazi: 60.000 eta 150.000 euro arteko etekinak aitortzen dituztenen artean, {formatNumber(irpf[0]?.pct_tramo, 1)} % da. Diputatuek zergadun guztiek baino pixka bat maizago aitortzen dituzte alokairuak, eta diru-sarreren tarte horretakoek baino dezente gutxiagotan.

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
    seriesColors={{'Declara alquileres': '#2563eb', '2 o más viviendas': '#93c5fd'}}
    title="Alokairuak edo hainbat etxebizitza aitortzen dituzten diputatuak, 20 diputatu edo gehiagoko taldeak"
/>

<DataTable data={grupos} rows=12>
    <Column id=grupo title="Taldea" />
    <Column id=diputados title="Diputatuak" fmt='0' />
    <Column id=pct_alquila title="% alokairuak aitortzen ditu" fmt='0.0' />
    <Column id=pct_dos_viviendas title="% 2 etxebizitza edo gehiago" fmt='0.0' />
    <Column id=pct_dos_urbanos title="% 2 hiri-higiezin edo gehiago" fmt='0.0' />
    <Column id=pct_dos_equivalentes title="% 2 oso edo gehiago" fmt='0.0' />
    <Column id=pct_sin_urbanos title="% hiri-higiezinik gabe" fmt='0.0' />
    <Column id=mediana_urbanos title="Hiri-higiezinen mediana" fmt='0' />
</DataTable>

Talde txikietan diputatu bakoitzak asko mugitzen du ehunekoa: zazpi diputaturekin, bakar bat 14 puntu da.

## Metodologia eta iturriak

- **Aitorpenak**: [Diputatuen Kongresua, diputatuen fitxak](https://www.congreso.es/es/busqueda-de-diputados), XV. Legegintzaldiko diputatu aktibo bakoitzaren hasierako ondasun eta errenten aitorpena ({resumen[0]?.primera} eta {resumen[0]?.ultima} artean aurkeztuak). Ondorengo aldaketak ez dira erabiltzen, partzialak izan ohi direlako. Irakurri ezin diren edo aurreko batera bidaltzen duten {kpi[0]?.n_excluidos} aitorpen baztertzen dira.
- **Irakurketa**: dokumentuak eskaneatuak dira; karaktere-ezagutze optikoarekin irakurri dira, eta talde guztietako 22 aitorpeneko lagin bat eskuz egiaztatu da: hiri-higiezinen kopurua eta alokairuak aitortzen dituen ala ez bat zetozen 22tik 21etan. Beste eremu batzuetan noizbehinkako akatsak egon daitezke; horregatik, guztizkoak baino ez dira argitaratzen, ez diputatu bakoitzaren zifrak.
- **Alokairuak**: inprimakiak ez du haientzako laukitxorik; errenta bakoitzaren kontzeptuaren bidez detektatzen dira («alquiler», «arrendamiento», «capital inmobiliario»...). Zenbatekoak aitortutakoak dira, eta batzuek garbian ematen dituzte, beste batzuek gordinean eta norbaitek hilean; beraz, ez dira batzen ezta alderatzen ere. Eskura dauden etxebizitzengatik egotzitako errentak ez dira alokairutzat hartzen.
- **Higiezin osoak**: hiri-higiezin bakoitzaren jabetza-zatiaren batura; irabazpidezkoa edo ehunekorik gabeko proindibisoa gisa ageri denean, erdia zenbatzen da.
- **Zergadunak**: [Zerga Agentzia, PFEZaren aitortzaileen estatistika](https://sede.agenciatributaria.gob.es/AEAT/Contenidos_Comunes/La_Agencia_Tributaria/Estadisticas/Publicaciones/sites/irpf/2023/jrubikf3d7dfa31d2ce3af7d74ec0cde8d09ed9914891e7.html), 102. partida (errentan emandako higiezinen etekinak), erregimen erkideko lurraldea. Unitatea aitorpena da, baterakoa izan daitekeena, ez pertsona.
