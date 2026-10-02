---
title: Hauteskundeak
description: "1977az geroztiko hauteskunde orokorren, europarren eta udal-hauteskundeen emaitzak: parte-hartzea, botoa alderdika eta blokeka, zatiketa, eserlekuko botoak eta irabazlea probintzia eta udalerri bakoitzean, Barne Ministerioaren datu ofizialekin."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: c6f8193148e9
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // Hilabeteen laburdurak (datuetan gaztelaniaz datoz): 'abr. 2019' -> 'api. 2019'
    const HIL = { 'ene.': 'urt.', 'feb.': 'ots.', 'mar.': 'mar.', 'abr.': 'api.', 'may.': 'mai.', 'jun.': 'eka.', 'jul.': 'uzt.', 'ago.': 'abu.', 'sep.': 'ira.', 'oct.': 'urr.', 'nov.': 'aza.', 'dic.': 'abe.' };
    const hil = (s) => (s == null ? String() : String(s).replace(/^[a-z]+\./, (m) => HIL[m] ?? m));
</script>

```sql generales
SELECT
    proceso, fecha, CAST(anio AS INTEGER) AS anio,
    CASE WHEN count(*) OVER (PARTITION BY anio) > 1
        THEN ['ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.', 'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'][month(fecha)] || ' ' || CAST(CAST(anio AS INTEGER) AS VARCHAR)
        ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR)
    END AS etiqueta,
    strftime(fecha, '%-d/%-m/%Y') AS fecha_txt,
    censo, votantes, participacion, pct_blancos, nep_votos, nep_escanos, gallagher,
    ganador_siglas, ganador_pct, ganador_escanos, segundo_siglas, segundo_pct,
    ganador_pct + segundo_pct AS dos_primeros,
    participacion AS valor
FROM mother.elecciones_participacion
WHERE nivel = 'pais' AND tipo = '02'
ORDER BY fecha
```

```sql resumen
-- Última elección y cambios frente a la anterior; máximos y mínimos de la serie
WITH g AS (SELECT * FROM ${generales})
SELECT
    u.*,
    round(u.participacion - a.participacion, 1) AS dif_participacion,
    round(u.nep_votos - a.nep_votos, 1) AS dif_nep,
    round(u.dos_primeros - a.dos_primeros, 1) AS dif_dos,
    a.etiqueta AS etiqueta_anterior,
    (SELECT arg_max(etiqueta, participacion) FROM g) AS max_part_etiqueta,
    (SELECT max(participacion) FROM g) AS max_part,
    (SELECT arg_min(etiqueta, participacion) FROM g) AS min_part_etiqueta,
    (SELECT min(participacion) FROM g) AS min_part,
    (SELECT arg_max(etiqueta, nep_votos) FROM g) AS max_nep_etiqueta,
    (SELECT max(nep_votos) FROM g) AS max_nep,
    (SELECT arg_min(etiqueta, nep_votos) FROM g) AS min_nep_etiqueta,
    (SELECT min(nep_votos) FROM g) AS min_nep
FROM (SELECT * FROM g ORDER BY fecha DESC LIMIT 1) u
CROSS JOIN (SELECT * FROM g ORDER BY fecha DESC LIMIT 1 OFFSET 1) a
```

# 🗳️ Hauteskundeak

Zenbat jendek bozkatzen duen, nori eta nola banatzen diren eserlekuak: 1977az geroztiko hauteskunde orokor guztiak, baita europarrak eta udal-hauteskundeak ere, Barne Ministerioaren emaitza ofizialekin, erkidego, probintzia eta udalerriaren arabera.

<Grid cols=4>
    <KpiCard
        title="Parte-hartzea hauteskunde orokorretan"
        value={resumen[0]?.participacion}
        formattedValue="{formatNumber(resumen[0]?.participacion, 1)} %"
        period="{resumen[0]?.fecha_txt} · {formatCompact(resumen[0]?.votantes, 3)} boto-emaile, {formatCompact(resumen[0]?.censo, 3)} hautesleetatik"
        change={resumen[0]?.dif_participacion}
        changeUnit="p.p."
        changePeriod="aurrekoarekiko ({hil(resumen[0]?.etiqueta_anterior)})"
        direction="positive-up"
        source="Barne Ministerioa"
        sparklineData={generales}
    />
    <KpiCard
        title="Boto gehien jaso zituen hautagaitza"
        value={resumen[0]?.ganador_pct}
        formattedValue="{resumen[0]?.ganador_siglas} · {formatNumber(resumen[0]?.ganador_pct, 1)} %"
        period="350 eserlekutik {formatNumber(resumen[0]?.ganador_escanos, 0)} · bigarrena: {resumen[0]?.segundo_siglas} ({formatNumber(resumen[0]?.segundo_pct, 1)} %)"
        source="Barne Ministerioa"
        sparklineData={generales.map(d => ({valor: d.ganador_pct}))}
    />
    <KpiCard
        title="Alderdien kopuru efektiboa"
        value={resumen[0]?.nep_votos}
        formattedValue={formatNumber(resumen[0]?.nep_votos, 1)}
        period="botoetan ({formatNumber(resumen[0]?.nep_escanos, 1)} eserlekuetan) · 2 = bi alderdiko sistema hutsa"
        change={resumen[0]?.dif_nep}
        changeUnit=""
        changePeriod="aurrekoarekiko ({hil(resumen[0]?.etiqueta_anterior)})"
        source="Geure kalkulua"
        sparklineData={generales.map(d => ({valor: d.nep_votos}))}
    />
    <KpiCard
        title="Boto gehien jaso zituzten bien botoa"
        value={resumen[0]?.dos_primeros}
        formattedValue="{formatNumber(resumen[0]?.dos_primeros, 1)} %"
        period="{resumen[0]?.ganador_siglas} + {resumen[0]?.segundo_siglas}, baliozko botoen gainean"
        change={resumen[0]?.dif_dos}
        changeUnit="p.p."
        changePeriod="aurrekoarekiko ({hil(resumen[0]?.etiqueta_anterior)})"
        source="Barne Ministerioa"
        sparklineData={generales.map(d => ({valor: d.dos_primeros}))}
    />
</Grid>

<p class="text-xs text-gray-500">Botoen ehunekoak baliozko botoen gainean kalkulatzen dira (hautagaitzei emandakoak eta zuriak), emaitza ofizialetan bezala. Parte-hartzeak atzerrian bizi diren espainiarren botoa barne hartzen du (CERA).</p>

## Parte-hartzea

Hauteskunde orokorretako parte-hartzea {formatNumber(resumen[0]?.min_part, 1)} %-tik ({hil(resumen[0]?.min_part_etiqueta)}) {formatNumber(resumen[0]?.max_part, 1)} %-ra ({hil(resumen[0]?.max_part_etiqueta)}) bitartekoa izan da. Europako hauteskundeetan eta udal-hauteskundeetan parte-hartzea txikiagoa izan ohi da.

```sql participacion_tipos
SELECT fecha, tipo_nombre AS eleccion, participacion
FROM mother.elecciones_participacion
WHERE nivel = 'pais'
ORDER BY fecha
```

<LineChart
    data={participacion_tipos}
    x=fecha
    y=participacion
    series=eleccion
    yFmt='0.0"%"'
    yMin={30}
    markers=true
    seriesColors={{'Congreso': '#1d4ed8', 'Municipales': '#0f766e', 'Parlamento Europeo': '#a16207'}}
    title="Parte-hartzea erroldaren gainean (%)"
/>

## Botoa blokeka

<ButtonGroup name=tipo title="Hauteskundeak">
    <ButtonGroupItem valueLabel="Orokorrak" value="02" default />
    <ButtonGroupItem valueLabel="Europarrak" value="07" />
    <ButtonGroupItem valueLabel="Udalekoak" value="04" />
</ButtonGroup>

```sql etiquetas
SELECT
    proceso, fecha,
    CASE WHEN count(*) OVER (PARTITION BY anio) > 1
        THEN ['ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.', 'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'][month(fecha)] || ' ' || CAST(CAST(anio AS INTEGER) AS VARCHAR)
        ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR)
    END AS etiqueta
FROM mother.elecciones_participacion
WHERE nivel = 'pais' AND tipo = '${inputs.tipo}'
```

```sql bloques
SELECT fecha, etiqueta, bloque, pct, escanos
FROM (
    SELECT e.fecha, e.etiqueta, f.bloque, sum(f.pct) AS pct, sum(f.escanos) AS escanos, min(f.orden_familia) AS orden
    FROM mother.elecciones_familias f
    JOIN ${etiquetas} e USING (proceso)
    WHERE f.nivel = 'pais' AND f.tipo = '${inputs.tipo}'
    GROUP BY e.fecha, e.etiqueta, f.bloque
)
ORDER BY fecha, orden
```

```sql bloques_ultima
SELECT
    etiqueta,
    max(pct) FILTER (WHERE bloque = 'Izquierda') AS izq,
    max(pct) FILTER (WHERE bloque = 'Derecha') AS der,
    coalesce(max(pct) FILTER (WHERE bloque = 'Centro'), 0) AS cen,
    max(pct) FILTER (WHERE bloque = 'Nacionalistas y regionalistas') AS nac
FROM ${bloques}
WHERE fecha = (SELECT max(fecha) FROM ${bloques})
GROUP BY etiqueta
```

Hautagaitza bakoitza familia politiko bati esleitzen zaio, eta familia bakoitza bost blokeetako bati. Mota honetako azken hauteskundeetan ({hil(bloques_ultima[0]?.etiqueta)}), estatu mailako ezkerrak baliozko botoen {formatNumber(bloques_ultima[0]?.izq, 1)} % lortu zuen, estatu mailako eskuinak {formatNumber(bloques_ultima[0]?.der, 1)} %, zentroko alderdiek {formatNumber(bloques_ultima[0]?.cen, 1)} %, eta alderdi nazionalistek eta erregionalistek {formatNumber(bloques_ultima[0]?.nac, 1)} %.

<BarChart
    data={bloques}
    x=etiqueta
    y=pct
    series=bloque
    type=stacked
    sort=false
    yFmt='0"%"'
    yMax={100}
    seriesColors={{'Izquierda': '#dc2626', 'Derecha': '#2563eb', 'Centro': '#f97316', 'Nacionalistas y regionalistas': '#ca8a04', 'Otros': '#9ca3af'}}
    title="Botoa blokeka, baliozko botoen ehunekotan (100era arteko gainerakoa boto zuria da)"
/>

<p class="text-xs text-gray-500">Ezkerra: PSOE eta IU, Podemos eta Sumarren familia (PCE, ICV, konfluentziak eta Más País barne). Eskuina: AP-PP, Vox eta UPN. Zentroa: UCD, CDS, Ciudadanos eta UPyD. Nazionalistak eta erregionalistak: autonomia-eremuko alderdiak (CiU-Junts, ERC, EAJ-PNV, EH Bildu, BNG, Coalición Canaria, Compromís, PAR, PRC, Teruel Existe...). Beste batzuk: gainerako hautagaitzak, batez ere txikiak eta, udal-hauteskundeetan, hautesle-elkarteak eta independenteak. SpainFactsen sailkapena da: zein siglak zein familiatara doazen webgunearen kodean dago zehaztuta (seed elecciones_partidos_reglas).</p>

## Botoa alderdika

```sql familias_evol
SELECT e.fecha, e.etiqueta, f.familia, f.siglas_familia, f.color, f.orden_familia, f.pct, f.escanos, f.votos
FROM mother.elecciones_familias f
JOIN ${etiquetas} e USING (proceso)
WHERE f.nivel = 'pais' AND f.tipo = '${inputs.tipo}'
  AND f.familia IN (
      SELECT familia FROM mother.elecciones_familias
      WHERE nivel = 'pais' AND tipo = '${inputs.tipo}' AND bloque <> 'Otros'
      GROUP BY familia HAVING max(pct) >= 3
  )
ORDER BY e.fecha, f.orden_familia
```

```sql colores_familias
SELECT DISTINCT familia, color, orden_familia FROM ${familias_evol} ORDER BY orden_familia
```

Familia politiko bakoitzaren boto-ehunekoa (Espainia osoan noizbait 3 % gainditu dutenak). Alderdiak beren federazioekin eta aurrekoekin taldekatzen dira: PSOEk PSC barne hartzen du; PPk, AP eta haren koalizioak; IU, Podemos eta Sumarrek, PCE eta haien konfluentzia guztiak.

<LineChart
    data={familias_evol}
    x=fecha
    y=pct
    series=familia
    yFmt='0.0"%"'
    markers=true
    seriesColors={Object.fromEntries(colores_familias.map(d => [d.familia, d.color]))}
    title="Botoa familia politikoka, baliozko botoen ehunekotan"
/>

## Zatiketa

Alderdien kopuru efektiboak zifra bakar batean laburtzen du zenbat alderdik «kontatzen» duten: 2 balio du bi alderdik botoa erdibana banatzen badute, eta hazi egiten da zenbat eta banatuago egon. Hauteskunde orokorretan {formatNumber(resumen[0]?.min_nep, 1)} ({hil(resumen[0]?.min_nep_etiqueta)}) eta {formatNumber(resumen[0]?.max_nep, 1)} ({hil(resumen[0]?.max_nep_etiqueta)}) artean ibili da.

```sql fragmentacion
SELECT fecha, 'En votos' AS medida, nep_votos AS nep FROM ${generales}
UNION ALL
SELECT fecha, 'En escaños' AS medida, nep_escanos AS nep FROM ${generales}
ORDER BY fecha
```

<LineChart
    data={fragmentacion}
    x=fecha
    y=nep
    series=medida
    yFmt='0.0'
    markers=true
    seriesColors={{'En votos': '#7c3aed', 'En escaños': '#c4b5fd'}}
    title="Alderdien kopuru efektiboa hauteskunde orokorretan (Laakso-Taagepera)"
/>

<p class="text-xs text-gray-500">Alderdien kopuru efektiboa = 1 / hautagaitza bakoitzaren boto- (edo eserleku-) kuoten karratuen batura. Estatu mailako zenbaketan bezala taldekatutako hautagaitzekin kalkulatzen da (PSC PSOEren barruan, Sumarren probintzia-zerrendak Sumarren barruan...). Eserlekuetan botoetan baino txikiagoa izateak esan nahi du banaketak alderdi handien alde egiten duela.</p>

## Eserlekuko botoak

```sql ultima_partidos
SELECT siglas, familia, color, votos, pct, escanos, pct_escanos, votos_por_escano, ventaja
FROM mother.elecciones_partidos
WHERE tipo = '02' AND proceso = (SELECT max(proceso) FROM mother.elecciones_partidos WHERE tipo = '02')
  AND escanos > 0
ORDER BY votos DESC
```

```sql vpe_resumen
SELECT
    arg_min(siglas, votos_por_escano) AS min_siglas, min(votos_por_escano) AS min_vpe,
    arg_max(siglas, votos_por_escano) AS max_siglas, max(votos_por_escano) AS max_vpe,
    (SELECT votos_candidaturas FROM mother.elecciones_participacion WHERE nivel = 'pais' AND tipo = '02'
       ORDER BY proceso DESC LIMIT 1) - sum(votos) AS votos_sin_escano,
    (SELECT validos FROM mother.elecciones_participacion WHERE nivel = 'pais' AND tipo = '02'
       ORDER BY proceso DESC LIMIT 1) AS validos
FROM ${ultima_partidos}
```

```sql vpe_sin
SELECT 100.0 * votos_sin_escano / validos AS pct_sin_escano FROM ${vpe_resumen}
```

350 eserlekuak probintziaka banatzen dira D'Hondt arauarekin; beraz, eserleku bakoitzak zenbat boto kostatzen duen asko aldatzen da alderdi batetik bestera. Azken hauteskunde orokorretan ({resumen[0]?.fecha_txt}), {formatNumber(vpe_resumen[0]?.min_vpe, 0)} boto kostatu zuen eserleku bakoitzak alderdi batean ({vpe_resumen[0]?.min_siglas}) eta {formatNumber(vpe_resumen[0]?.max_vpe, 0)} beste batean ({vpe_resumen[0]?.max_siglas}). Eserlekurik gabe geratu ziren hautagaitzek baliozko botoen {formatNumber(vpe_sin[0]?.pct_sin_escano, 1)} % bildu zuten.

<BarChart
    data={ultima_partidos}
    x=siglas
    y=votos_por_escano
    yFmt=num0
    swapXY=true
    fillColor="#1d4ed8"
    title="Eserlekuko botoak azken hauteskunde orokorretan"
/>

<DataTable data={ultima_partidos} rows=20>
    <Column id=siglas title="Hautagaitza" />
    <Column id=pct title="Botoen %" fmt='0.00"%"' />
    <Column id=escanos title="Eserlekuak" fmt=num0 />
    <Column id=pct_escanos title="Eserlekuen %" fmt='0.00"%"' />
    <Column id=ventaja title="Eserlekuak − botoa (p.p.)" fmt='+0.00;-0.00' contentType=delta />
    <Column id=votos_por_escano title="Eserlekuko botoak" fmt=num0 />
</DataTable>

```sql gallagher
SELECT fecha, gallagher FROM ${generales} ORDER BY fecha
```

<LineChart
    data={gallagher}
    x=fecha
    y=gallagher
    yFmt='0.0'
    markers=true
    lineColor="#b45309"
    title="Botoen eta eserlekuen arteko desproportzionaltasuna hauteskunde orokorretan (Gallagher indizea)"
/>

<p class="text-xs text-gray-500">Gallagher indizea = hautagaitza bakoitzaren boto-%aren eta eserleku-%aren arteko diferentzien karratuen baturaren erdiaren erro karratua. 0 banaketa guztiz proportzionala litzateke.</p>

## Irabazlea probintzia bakoitzean

```sql lista_generales
SELECT proceso, etiqueta, row_number() OVER (ORDER BY fecha DESC) AS orden FROM ${generales} ORDER BY fecha DESC
```

<Dropdown name=eleccion title="Hauteskunde orokorrak" data={lista_generales} value=proceso label=etiqueta order=orden />

```sql provincias
SELECT
    p.cod AS cod_prov, t.nombre AS provincia, '/eu' || t.ruta AS ruta,
    p.ganador_familia, p.ganador_siglas, p.ganador_pct / 100 AS ganador_pct,
    p.segundo_siglas, p.segundo_pct / 100 AS segundo_pct,
    p.participacion / 100 AS participacion, p.escanos,
    b.orden_familia, b.color
FROM mother.elecciones_participacion p
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = p.cod
LEFT JOIN (SELECT familia, any_value(orden_familia) AS orden_familia, any_value(color) AS color
           FROM mother.elecciones_familias GROUP BY familia) b ON b.familia = p.ganador_familia
WHERE p.nivel = 'provincia' AND p.proceso = '${inputs.eleccion.value}'
ORDER BY b.orden_familia, p.cod
```

```sql colores_mapa
SELECT p.ganador_familia, any_value(f.color) AS color, count(*) AS provincias, min(p.orden_familia) AS orden
FROM ${provincias} p
LEFT JOIN (SELECT DISTINCT familia, color FROM mother.elecciones_familias) f ON f.familia = p.ganador_familia
GROUP BY 1
ORDER BY orden
```

Probintzia bakoitzean (hauteskunde orokorretako barrutia) boto gehien jaso zituen hautagaitzaren familia politikoa.

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="ganador_familia"
    legendType=categorical
    colorPalette={[...new Map(Array.from(provincias ?? []).map(d => [d.ganador_familia, d.color])).values()]}
    link="ruta"
    height={480}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: Barne Ministerioa"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'ganador_siglas', title: 'Bozkatuena'},
        {id: 'ganador_pct', title: 'Botoen %', fmt: 'pct1'},
        {id: 'segundo_siglas', title: 'Bigarrena'},
        {id: 'segundo_pct', title: 'Botoen %', fmt: 'pct1'},
        {id: 'participacion', title: 'Parte-hartzea', fmt: 'pct1'},
        {id: 'escanos', title: 'Eserlekuak', fmt: 'num0'}
    ]}
/>

```sql ccaa
SELECT
    t.nombre AS comunidad, '/eu' || t.ruta AS ruta,
    p.participacion / 100 AS participacion,
    p.ganador_siglas, p.ganador_pct / 100 AS ganador_pct,
    coalesce(max(f.pct) FILTER (WHERE f.bloque = 'Izquierda'), 0) AS izq,
    coalesce(max(f.pct) FILTER (WHERE f.bloque = 'Derecha'), 0) AS der,
    coalesce(max(f.pct) FILTER (WHERE f.bloque = 'Centro'), 0) AS cen,
    coalesce(max(f.pct) FILTER (WHERE f.bloque = 'Nacionalistas y regionalistas'), 0) AS nac,
    p.nep_votos
FROM mother.elecciones_participacion p
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = p.cod
LEFT JOIN (
    SELECT cod, bloque, sum(pct) / 100 AS pct
    FROM mother.elecciones_familias
    WHERE nivel = 'ccaa' AND proceso = '${inputs.eleccion.value}'
    GROUP BY ALL
) f ON f.cod = p.cod
WHERE p.nivel = 'ccaa' AND p.proceso = '${inputs.eleccion.value}'
GROUP BY ALL
ORDER BY 3 DESC
```

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=participacion title="Parte-hartzea" fmt=pct1 />
    <Column id=ganador_siglas title="Bozkatuena" />
    <Column id=ganador_pct title="Botoen %" fmt=pct1 />
    <Column id=izq title="Ezkerra" fmt=pct1 />
    <Column id=der title="Eskuina" fmt=pct1 />
    <Column id=cen title="Zentroa" fmt=pct1 />
    <Column id=nac title="Nazionalistak eta erreg." fmt=pct1 />
    <Column id=nep_votos title="Alderdien kopuru efektiboa" fmt='0.0' />
</DataTable>

## Emaitzak udalerrika

```sql municipios
SELECT
    municipio, provincia, poblacion, ganador_siglas,
    ganador_pct / 100 AS ganador_pct,
    participacion / 100 AS participacion,
    (participacion - participacion_anterior) AS dif_participacion,
    pct_izquierda / 100 AS izq,
    pct_derecha / 100 AS der,
    pct_centro / 100 AS cen,
    pct_nacionalistas / 100 AS nac,
    '/eu' || enlace AS enlace
FROM mother.elecciones_municipios_congreso
ORDER BY poblacion DESC NULLS LAST
```

```sql municipios_resumen
SELECT
    CAST(max(anio) AS INTEGER) AS anio,
    count(*) AS n,
    arg_max(ganador_siglas, n_gana) AS mas_gana, max(n_gana) AS n_mas_gana
FROM (
    SELECT anio, ganador_siglas, count(*) OVER (PARTITION BY ganador_siglas) AS n_gana
    FROM mother.elecciones_municipios_congreso
)
```

Azken hauteskunde orokorren emaitza {formatNumber(municipios_resumen[0]?.n, 0)} udalerrietan. Horietako {formatNumber(municipios_resumen[0]?.n_mas_gana, 0)} udalerritan, boto gehien jaso zituen hautagaitza hau izan zen: {municipios_resumen[0]?.mas_gana}. Bilatu zurea eta sakatu haren fitxa ikusteko, 1977tik izandako bilakaerarekin.

<DataTable data={municipios} rows=15 search=true link=enlace>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=poblacion title="Biztanleak" fmt=num0 />
    <Column id=ganador_siglas title="Bozkatuena" />
    <Column id=ganador_pct title="Botoen %" fmt=pct1 />
    <Column id=participacion title="Parte-hartzea" fmt=pct1 />
    <Column id=dif_participacion title="aurrekoekiko (p.p.)" fmt='+0.0;-0.0' contentType=delta />
    <Column id=izq title="Ezkerra" fmt=pct1 />
    <Column id=der title="Eskuina" fmt=pct1 />
    <Column id=cen title="Zentroa" fmt=pct1 />
    <Column id=nac title="Nazionalistak eta erreg." fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Udalerrikako emaitzek ez dute barne hartzen atzerrian bizi direnen botoa (CERA), probintzia bakoitzean bereiz zenbatzen baita. 1977ko eta 1979ko udalerri txiki batzuetan, erregistratutako boto-emaileak erroldakoak baino gehiago dira, iturriaren akatsengatik: kasu horietan ez da parte-hartzerik ematen.</p>

---

## Iturriak eta oharrak

- **[Barne Ministerioa – Hauteskunde-emaitzen deskarga-gunea](https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/)**: prozesu bakoitzaren fitxategi ofizialak (luzera finkoko testu-formatua, deskarga bakoitzarekin datorren FICHEROS dokumentuan deskribatua). Hauteskunde orokorrak (Kongresua) 1977tik, europarrak 1987tik eta udal-hauteskundeak 1979tik, udalerri, probintzia eta erkidegoko datuekin.
- Udal-hauteskundeetan 250 biztanletik gorako udalerriak baino ez dira sartzen (zerrenda itxiak); kontzeju irekiko edo zerrenda irekiko udalerriak beste fitxategi batzuetan argitaratzen dira.
- Siglak familia politikotan taldekatzen dira, [alkateen](/eu/territorios/municipios) orriko irizpide eta kolore berberekin; hautagaitza bakoitza familia eta bloke bati esleitzea SpainFactsen erabakia da, eta eztabaidagarria izan daiteke koalizioetan (adibidez, UPN-PP UPN gisa zenbatzen da, eta Ahora Repúblicas, europarretan, ERC gisa estatu mailako guztizkoan).
- Boto-ehunekoak baliozko botoen gainean (hautagaitzak eta zuriak). Parte-hartzea = boto-emaileak / zenbaketako errolda.

<LastRefreshed prefix="Datuak eguneratuta" />
