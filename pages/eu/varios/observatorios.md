---
title: Behatoki publikoak
description: "Espainiako behatoki publikoen errolda: zenbat dauden, zein administraziok sortzen dituen, noiz sortu ziren, zenbat dauden oraindik aktibo, zenbat dauden biztanleko erkidego bakoitzean eta zein alderdik gobernatzen zuen sortu zirenean."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: a544f976aca5
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql resumen
SELECT
    count(*) AS total,
    count(*) FILTER (WHERE estado = 'Activo') AS activos,
    count(*) FILTER (WHERE estado = 'Inactivo') AS inactivos,
    count(*) FILTER (WHERE estado = 'Sin información') AS sin_info,
    100.0 * count(*) FILTER (WHERE estado = 'Activo') / count(*) AS pct_activos,
    count(*) FILTER (WHERE nivel = 'Estatal') AS estatales,
    count(anio_creacion) AS con_anio,
    count(*) FILTER (WHERE anio_creacion >= 2015) AS desde_2015,
    100.0 * count(*) FILTER (WHERE anio_creacion >= 2015) / count(anio_creacion) AS pct_desde_2015,
    count(*) FILTER (WHERE tipo = 'Mixto (público-privado)') AS mixtos,
    max(anio_creacion) AS ultimo_anio,
    count(*) FILTER (WHERE nivel IN ('Autonómico', 'Provincial o insular', 'Local') AND cod_ccaa IS NULL) AS sin_comunidad,
    100.0 * count(*) FILTER (WHERE estado = 'Sin información') / count(*) AS pct_sin_info
FROM mother.observatorios_detalle
```

```sql por_anio
SELECT
    CAST(anio_creacion AS INTEGER) AS anio,
    count(*) AS creados,
    sum(count(*)) OVER (ORDER BY anio_creacion) AS acumulados
FROM mother.observatorios_detalle
WHERE anio_creacion IS NOT NULL
GROUP BY anio_creacion
ORDER BY anio_creacion
```

```sql por_nivel
SELECT
    nivel,
    estado,
    count(*) AS observatorios,
    CASE nivel WHEN 'Estatal' THEN 1 WHEN 'Autonómico' THEN 2 WHEN 'Provincial o insular' THEN 3 WHEN 'Local' THEN 4 ELSE 5 END AS orden
FROM mother.observatorios_detalle
GROUP BY ALL
ORDER BY orden, estado
```

```sql por_nivel_resumen
SELECT
    nivel,
    count(*) AS total,
    100.0 * count(*) FILTER (WHERE estado = 'Activo') / count(*) AS pct_activos
FROM mother.observatorios_detalle
GROUP BY nivel
ORDER BY total DESC
```

```sql por_ccaa
WITH pob AS (
    SELECT cod, poblacion
    FROM mother.poblacion_territorios
    WHERE nivel = 'ccaa' AND sexo = 'Total' AND anio = (SELECT max(anio) FROM mother.poblacion_territorios)
)
SELECT
    t.cod,
    t.nombre AS comunidad,
    '/eu' || t.ruta AS ruta,
    count(o.nombre) AS observatorios,
    count(o.nombre) FILTER (WHERE o.estado = 'Activo') AS activos,
    1e6 * count(o.nombre) / p.poblacion AS por_millon
FROM mother.territorios t
JOIN pob p ON p.cod = t.cod
LEFT JOIN mother.observatorios_detalle o ON o.cod_ccaa = t.cod
WHERE t.nivel = 'ccaa'
GROUP BY t.cod, t.nombre, t.ruta, p.poblacion
ORDER BY por_millon DESC
```

```sql listado
SELECT
    nombre,
    nivel,
    coalesce(ccaa, '') AS comunidad,
    coalesce(municipio, '') AS municipio,
    anio_creacion,
    coalesce(partido, '') AS partido,
    estado,
    tipo
FROM mother.observatorios_detalle
ORDER BY nombre
```

```sql partidos
-- Observatorios con partido atribuido, por familia política y nivel
SELECT
    partido,
    any_value(color_partido) AS color,
    nivel,
    count(*) AS observatorios
FROM mother.observatorios_detalle
WHERE partido IS NOT NULL
GROUP BY partido, nivel
ORDER BY sum(count(*)) OVER (PARTITION BY partido) DESC, nivel
```

```sql partidos_colores
SELECT partido, any_value(color_partido) AS color, count(*) AS n
FROM mother.observatorios_detalle
WHERE partido IS NOT NULL
GROUP BY partido
ORDER BY n DESC
```

```sql cobertura
SELECT
    count(*) FILTER (WHERE partido IS NOT NULL) AS atribuidos,
    count(*) FILTER (WHERE anio_creacion IS NOT NULL) AS con_anio,
    count(*) AS total,
    count(*) FILTER (WHERE partido IS NOT NULL AND cambio_en_el_anio) AS dudosos,
    count(*) FILTER (WHERE metodo_partido = 'Diputación o cabildo (sin datos)') AS provinciales,
    min(anio_creacion) FILTER (WHERE partido IS NOT NULL) AS desde
FROM mother.observatorios_detalle
```

```sql esperados
-- Observados frente a esperados: la creación de observatorios crece con los años (y
-- el censo documenta mejor los recientes), así que quien gobierna ahora saldría
-- favorecido. La tendencia de cada año se toma de los observatorios con fecha de los
-- OTROS niveles (para los estatales, autonómicos y locales), y los observatorios de
-- cada nivel se reparten según esa tendencia y la parte de cada año que gobernó cada
-- partido. z: diferencia observada frente al azar (binomial, aproximación normal).
WITH obs AS (
    SELECT * FROM mother.observatorios_detalle WHERE anio_creacion IS NOT NULL
),
anios AS (SELECT CAST(unnest(range(1990, year(current_date) + 1)) AS INTEGER) AS anio),
tendencia AS (
    SELECT n.nivel, a.anio, count(o.nombre) AS n_ref
    FROM (VALUES ('Estatal'), ('Autonómico')) n(nivel)
    CROSS JOIN anios a
    LEFT JOIN obs o ON CAST(o.anio_creacion AS INTEGER) = a.anio AND o.nivel <> n.nivel
    GROUP BY ALL
),
pesos AS (
    SELECT nivel, anio, n_ref / sum(n_ref) OVER (PARTITION BY nivel) AS w FROM tendencia
),
gob AS (
    SELECT
        CASE g.nivel WHEN 'estatal' THEN 'Estatal' ELSE 'Autonómico' END AS nivel,
        g.familia AS partido,
        a.anio,
        greatest(0, date_diff('day', greatest(CAST(g.desde AS DATE), make_date(a.anio, 1, 1)),
            least(coalesce(CAST(g.hasta AS DATE), current_date), make_date(a.anio + 1, 1, 1)))) / 365.25
          / CASE g.nivel WHEN 'estatal' THEN 1 ELSE 19 END AS fraccion
    FROM mother.gobiernos_presidentes g
    CROSS JOIN anios a
),
esperado AS (
    SELECT g.nivel, g.partido, sum(p.w * g.fraccion) AS cuota
    FROM gob g JOIN pesos p USING (nivel, anio)
    GROUP BY ALL
),
observado AS (
    SELECT nivel, partido, count(*) AS observados
    FROM obs WHERE nivel IN ('Estatal', 'Autonómico') AND partido IS NOT NULL
    GROUP BY ALL
),
totales AS (SELECT nivel, sum(observados) AS total FROM observado GROUP BY nivel)
SELECT
    e.nivel,
    e.partido,
    coalesce(o.observados, 0) AS observados,
    t.total * e.cuota AS esperados,
    coalesce(o.observados, 0) / (t.total * e.cuota) AS ratio,
    (coalesce(o.observados, 0) - t.total * e.cuota) / sqrt(t.total * e.cuota * (1 - e.cuota)) AS z
FROM esperado e
JOIN totales t USING (nivel)
LEFT JOIN observado o USING (nivel, partido)
WHERE t.total * e.cuota >= 1
ORDER BY e.nivel DESC, esperados DESC
```

```sql esperados_resumen
SELECT
    max(ratio) FILTER (WHERE nivel = 'Estatal' AND partido = 'PSOE') AS psoe_est,
    max(ratio) FILTER (WHERE nivel = 'Estatal' AND partido = 'PP') AS pp_est,
    max(ratio) FILTER (WHERE nivel = 'Autonómico' AND partido = 'PSOE') AS psoe_aut,
    max(ratio) FILTER (WHERE nivel = 'Autonómico' AND partido = 'PP') AS pp_aut,
    max(abs(z)) FILTER (WHERE nivel = 'Estatal' AND partido IN ('PSOE', 'PP')) AS z_est,
    max(abs(z)) FILTER (WHERE nivel = 'Autonómico' AND partido IN ('PSOE', 'PP')) AS z_aut
FROM ${esperados}
```

```sql estatal_anio
SELECT CAST(anio_creacion AS INTEGER) AS anio, partido, count(*) AS observatorios
FROM mother.observatorios_detalle
WHERE nivel = 'Estatal' AND partido IS NOT NULL
GROUP BY ALL
ORDER BY anio
```

# 🔍 Behatoki publikoak

Administrazioek behatokiak sortzen dituzte gai bati jarraitzeko (genero-indarkeria, etxebizitza, klima-aldaketa, merkataritza...) eta gai horri buruzko txostenak argitaratzeko. Orri honek [observatoriospublicos.es](https://observatoriospublicos.es/) webguneak mantentzen duen errolda laburtzen du: zenbat dauden, nork sortzen dituen, noiz sortu ziren eta oraindik aktibo dauden.

<Grid cols=4>
    <KpiCard
        title="Erroldatutako behatokiak"
        value={resumen[0]?.total}
        formattedValue={formatNumber(resumen[0]?.total, 0)}
        period="{formatNumber(resumen[0]?.estatales, 0)} Estatuko Administrazio Orokorrarenak"
        source="observatoriospublicos.es"
        sparklineData={por_anio.map(d => d.acumulados)}
    />
    <KpiCard
        title="Aktiboak"
        value={resumen[0]?.pct_activos}
        formattedValue="{formatNumber(resumen[0]?.pct_activos, 0)} %"
        period="{formatNumber(resumen[0]?.activos, 0)} berretsiak · {formatNumber(resumen[0]?.inactivos, 0)} itxiak · {formatNumber(resumen[0]?.sin_info, 0)} informaziorik gabe"
        source="observatoriospublicos.es"
    />
    <KpiCard
        title="2015etik sortuak"
        value={resumen[0]?.pct_desde_2015}
        formattedValue="{formatNumber(resumen[0]?.pct_desde_2015, 0)} %"
        period="sorrera-urtea ezaguna duten {formatNumber(resumen[0]?.con_anio, 0)} behatokietatik {formatNumber(resumen[0]?.desde_2015, 0)}"
        source="observatoriospublicos.es"
        sparklineData={por_anio.map(d => d.creados)}
    />
    <KpiCard
        title="Parte-hartze pribatuarekin"
        value={resumen[0]?.mixtos}
        formattedValue="{formatNumber(resumen[0]?.mixtos / resumen[0]?.total / 0.01, 1)} %"
        period="{formatNumber(resumen[0]?.mixtos, 0)} behatoki misto (publiko-pribatuak)"
        source="observatoriospublicos.es"
    />
</Grid>

## Noiz sortu ziren

Urte bakoitzean sortutako behatokiak eta guztizko metatua. Erroldako {formatNumber(resumen[0]?.total, 0)} behatokietatik {formatNumber(resumen[0]?.con_anio, 0)} behatokik baino ez dute sorrera-data, beraz barrak laburrak dira. Data dutenen artean, {formatNumber(resumen[0]?.pct_desde_2015, 0)} % 2015ean edo geroago sortu zen (berrienek data hobeto dokumentatuta izan ohi dute).

<BarChart
    data={por_anio}
    x=anio
    y=creados
    y2=acumulados
    y2SeriesType=line
    xFmt='0'
    yAxisTitle="Urtean sortuak"
    y2AxisTitle="Metatuak"
    title="Urtero sortutako behatoki publikoak (data ezaguna dutenak)"
/>

## Nork sortzen dituen eta zenbat dauden oraindik aktibo

Administrazio-mailaren arabera. Erroldak {formatNumber(resumen[0]?.inactivos, 0)} behatoki baino ez ditu itxitzat jotzen; guztizkoaren {formatNumber(resumen[0]?.pct_sin_info, 0)} % informaziorik gabe dago oraindik jardunean dagoen ala ez jakiteko.

<BarChart
    data={por_nivel}
    x=nivel
    y=observatorios
    series=estado
    swapXY=true
    sort=false
    colorPalette={['#16a34a', '#dc2626', '#94a3b8']}
    title="Behatokiak, administrazio-mailaren eta egoeraren arabera"
/>

## Autonomia-erkidegoka

Erkidego bakoitzeko behatoki autonomikoak, probintzialak eta tokikoak, milioi biztanleko. Erkidegoa erroldak adierazten duen eremutik ateratzen da edo, hori adierazten ez badu, behatokiaren izenetik: udalerria (INEkoekin gurutzatuta), uhartea edo probintzia, edo herritar-izena ("Andaluz", "Galego"...). {formatNumber(resumen[0]?.sin_comunidad, 0)} kokatu gabe geratzen dira, haien izenak ez duelako jakiten uzten ("Observatorio Social", "Observatorio del Agua"...).

<MapaEspana
    data={por_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="por_millon"
    valueFmt='0.0'
    link="ruta"
    colorPalette={['#f5f3ff', '#a78bfa', '#5b21b6']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: observatoriospublicos.es"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'por_millon', title: 'Milioi biztanleko', fmt: '0.0'},
        {id: 'observatorios', title: 'Behatokiak', fmt: '0'}
    ]}
/>

<DataTable data={por_ccaa} rows=20>
    <Column id=comunidad title="Erkidegoa"/>
    <Column id=por_millon title="Milioi biztanleko" fmt='0.0'/>
    <Column id=observatorios title="Behatokiak" fmt='0'/>
    <Column id=activos title="Aktibo berretsiak" fmt='0'/>
</DataTable>

## Nork gobernatzen zuen sortu zirenean

Sorrera-urtea duen behatoki bakoitza urte horren erdian hura sortu zuen administrazioa gobernatzen zuen alderdiari egozten zaio: Espainiako Gobernuari estatukoak, erkidegoko lehendakaritzari autonomikoak eta alkatetzari udalekoak. Horrela, erroldako {formatNumber(cobertura[0]?.total, 0)} behatokietatik {formatNumber(cobertura[0]?.atribuidos, 0)} egozten dira: gainerakoek ez dute sorrera-datarik, diputazio edo kabildo batenak dira ({formatNumber(cobertura[0]?.provinciales, 0)}, nork zuzentzen zituen jakiteko daturik gabe) edo ezin dira kokatu. {formatNumber(cobertura[0]?.dudosos, 0)} kasutan gobernua urte berean aldatu zen, eta egozpena ez da hain segurua.

<BarChart
    data={partidos}
    x=partido
    y=observatorios
    series=nivel
    swapXY=true
    sort=false
    colorPalette={['#0f766e', '#6366f1', '#f59e0b', '#94a3b8']}
    title="Sortutako behatokiak, gobernatzen zuen alderdiaren arabera (sorrera-urtea ezaguna dutenak)"
/>

Besterik gabe zenbatzeak gehien gobernatu duenari egiten dio mesede, baita orain gobernatzen duenari ere: gero eta behatoki gehiago sortzen dira (eta erroldak hobeto dokumentatzen ditu berrienak). Hori kentzeko, taulak **ikusitako** behatokiak alderatzen ditu alderdi bakoitzak gobernatu zuen urteetan erroldaren gainerakoaren joerari jarraitu izan balio **espero** zitezkeenekin (estatukoentzat, autonomikoen eta tokikoen joera, ez baitira Espainiako Gobernuaren mende). 1eko ratioa da espero litekeena; 2, bikoitza; 0,5, erdia.

<DataTable data={esperados} rows=20>
    <Column id=nivel title="Maila"/>
    <Column id=partido title="Presidentearen alderdia"/>
    <Column id=observados title="Ikusitakoak" fmt='0'/>
    <Column id=esperados title="Joeraren arabera espero zirenak" fmt='0.0'/>
    <Column id=ratio title="Ikusitakoak / esperotakoak" fmt='0.00'/>
</DataTable>

Joera kenduta, Espainiako Gobernuan PSOEk esperotakoaren {formatNumber(esperados_resumen[0]?.psoe_est, 2)} halako sortzen ditu eta PPk {formatNumber(esperados_resumen[0]?.pp_est, 2)} halako: {#if esperados_resumen[0]?.z_est >= 1.96}zoriak azalduko lukeena baino alde handiagoa, kasu gutxirekin bada ere{:else}hain kasu gutxirekin, aldea ez da zoriak azal lezakeena baino handiagoa{/if}. Erkidegoetan, PSOEren ratioa {formatNumber(esperados_resumen[0]?.psoe_aut, 2)} da eta PPrena {formatNumber(esperados_resumen[0]?.pp_aut, 2)}: {#if esperados_resumen[0]?.z_aut >= 1.96}zoriak azalduko lukeena baino alde handiagoa{:else}zoriak azal dezakeen aldea{/if}.

<BarChart
    data={estatal_anio}
    x=anio
    y=observatorios
    series=partido
    xFmt='0'
    seriesColors={Object.fromEntries(partidos_colores.map(d => [d.partido, d.color]))}
    title="Urtero sortutako estatuko behatokiak, Espainiako Gobernuko alderdiaren arabera"
/>

## Behatoki guztiak

<DataTable data={listado} rows=15 search=true>
    <Column id=nombre title="Behatokia" wrap=true/>
    <Column id=nivel title="Maila"/>
    <Column id=comunidad title="Erkidegoa"/>
    <Column id=municipio title="Udalerria"/>
    <Column id=anio_creacion title="Sortua" fmt='0'/>
    <Column id=partido title="Gobernuan"/>
    <Column id=estado title="Egoera"/>
    <Column id=tipo title="Mota"/>
</DataTable>

---

**Iturria:** [observatoriospublicos.es](https://observatoriospublicos.es/), Espainiako administrazio publikoetako behatokien herritarren errolda. Maila eta erkidegoa erroldak adierazten duen eremutik ondorioztatzen dira eta, adierazten ez badu, behatokiaren izenetik (INEren udalerriak, uharteak, probintziak eta herritar-izenak). "Informaziorik gabe" egoerak esan nahi du erroldak ez duela esaten behatokia oraindik aktibo dagoen. Alderdia: Espainiako Gobernuko eta autonomia-erkidegoetako lehendakaritzak, Wikidatatik eta iturri ofizialetatik abiatuta berrikusiak, eta Lurralde Politikako Ministerioaren Toki Informazio Sistemako alkateak ([nork gobernatzen duen udalerri bakoitza](/eu/territorios/municipios)).
