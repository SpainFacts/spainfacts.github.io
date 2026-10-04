---
title: Observatoris públics
description: "Cens dels observatoris públics d'Espanya: quants n'hi ha, quina administració els crea, quan van néixer, quants continuen actius, quants n'hi ha per habitant a cada comunitat i quin partit governava quan es van crear."
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
    '/ca' || t.ruta AS ruta,
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

# 🔍 Observatoris públics

Les administracions creen observatoris per seguir un tema (la violència de gènere, l'habitatge, el canvi climàtic, el comerç...) i publicar-ne informes. Aquesta pàgina resumeix el cens que manté [observatoriospublicos.es](https://observatoriospublicos.es/): quants n'hi ha, qui els crea, quan van néixer i si continuen actius.

<Grid cols=4>
    <KpiCard
        title="Observatoris censats"
        value={resumen[0]?.total}
        formattedValue={formatNumber(resumen[0]?.total, 0)}
        period="{formatNumber(resumen[0]?.estatales, 0)} de l'Administració General de l'Estat"
        source="observatoriospublicos.es"
        sparklineData={por_anio.map(d => d.acumulados)}
    />
    <KpiCard
        title="Actius"
        value={resumen[0]?.pct_activos}
        formattedValue="{formatNumber(resumen[0]?.pct_activos, 0)} %"
        period="{formatNumber(resumen[0]?.activos, 0)} confirmats · {formatNumber(resumen[0]?.inactivos, 0)} tancats · {formatNumber(resumen[0]?.sin_info, 0)} sense informació"
        source="observatoriospublicos.es"
    />
    <KpiCard
        title="Creats des del 2015"
        value={resumen[0]?.pct_desde_2015}
        formattedValue="{formatNumber(resumen[0]?.pct_desde_2015, 0)} %"
        period="{formatNumber(resumen[0]?.desde_2015, 0)} dels {formatNumber(resumen[0]?.con_anio, 0)} amb any de creació conegut"
        source="observatoriospublicos.es"
        sparklineData={por_anio.map(d => d.creados)}
    />
    <KpiCard
        title="Amb participació privada"
        value={resumen[0]?.mixtos}
        formattedValue="{formatNumber(resumen[0]?.mixtos / resumen[0]?.total / 0.01, 1)} %"
        period="{formatNumber(resumen[0]?.mixtos, 0)} observatoris mixtos (publicoprivats)"
        source="observatoriospublicos.es"
    />
</Grid>

## Quan es van crear

Observatoris creats cada any i total acumulat. Només {formatNumber(resumen[0]?.con_anio, 0)} dels {formatNumber(resumen[0]?.total, 0)} tenen data de creació al cens, de manera que les barres es queden curtes. Entre els que tenen data, el {formatNumber(resumen[0]?.pct_desde_2015, 0)} % va néixer el 2015 o després (els més recents també solen tenir la data més ben documentada).

<BarChart
    data={por_anio}
    x=anio
    y=creados
    y2=acumulados
    y2SeriesType=line
    xFmt='0'
    yAxisTitle="Creats en l'any"
    y2AxisTitle="Acumulats"
    title="Observatoris públics creats per any (amb data coneguda)"
/>

## Qui els crea i quants continuen actius

Per nivell de l'administració. El cens només marca com a tancats {formatNumber(resumen[0]?.inactivos, 0)} observatoris; del total, el {formatNumber(resumen[0]?.pct_sin_info, 0)} % no té informació sobre si continua funcionant.

<BarChart
    data={por_nivel}
    x=nivel
    y=observatorios
    series=estado
    swapXY=true
    sort=false
    colorPalette={['#16a34a', '#dc2626', '#94a3b8']}
    title="Observatoris per nivell de l'administració i estat"
/>

## Per comunitat autònoma

Observatoris autonòmics, provincials i locals de cada comunitat, per milió d'habitants. La comunitat surt de l'àmbit que indica el cens o, si no ho diu, del nom de l'observatori: el municipi (creuat amb els de l'INE), l'illa o la província, o el gentilici ("Andaluz", "Galego"...). En queden {formatNumber(resumen[0]?.sin_comunidad, 0)} sense ubicar perquè el nom no permet saber-ho ("Observatorio Social", "Observatorio del Agua"...).

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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: observatoriospublicos.es"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'por_millon', title: "Per milió d'hab.", fmt: '0.0'},
        {id: 'observatorios', title: 'Observatoris', fmt: '0'}
    ]}
/>

<DataTable data={por_ccaa} rows=20>
    <Column id=comunidad title="Comunitat"/>
    <Column id=por_millon title="Per milió d'hab." fmt='0.0'/>
    <Column id=observatorios title="Observatoris" fmt='0'/>
    <Column id=activos title="Actius confirmats" fmt='0'/>
</DataTable>

## Qui governava quan es van crear

Cada observatori amb any de creació s'atribueix al partit que governava l'administració que el va crear a meitat d'aquell any: el Govern d'Espanya per als estatals, la presidència de la comunitat per als autonòmics i l'alcaldia per als municipals. Així s'atribueixen {formatNumber(cobertura[0]?.atribuidos, 0)} dels {formatNumber(cobertura[0]?.total, 0)} observatoris del cens: la resta no té data de creació, és d'una diputació o un cabildo ({formatNumber(cobertura[0]?.provinciales, 0)}, sense dades de qui els presidia) o no es pot ubicar. En {formatNumber(cobertura[0]?.dudosos, 0)} casos el govern va canviar aquell mateix any i l'atribució és menys segura.

<BarChart
    data={partidos}
    x=partido
    y=observatorios
    series=nivel
    swapXY=true
    sort=false
    colorPalette={['#0f766e', '#6366f1', '#f59e0b', '#94a3b8']}
    title="Observatoris creats segons el partit que governava (amb any de creació conegut)"
/>

Comptar sense més afavoreix qui més ha governat, i també qui governa ara: cada vegada es creen més observatoris (i el cens documenta millor els recents). Per descomptar-ho, la taula compara els observatoris **observats** amb els **esperats** si cada partit hagués seguit la tendència de la resta del cens els anys que va governar (per als estatals, la dels autonòmics i locals, que no depenen del Govern d'Espanya). Una ràtio d'1 és el que és esperable; 2, el doble; 0,5, la meitat.

<DataTable data={esperados} rows=20>
    <Column id=nivel title="Nivell"/>
    <Column id=partido title="Partit del president"/>
    <Column id=observados title="Observats" fmt='0'/>
    <Column id=esperados title="Esperats per la tendència" fmt='0.0'/>
    <Column id=ratio title="Observats / esperats" fmt='0.00'/>
</DataTable>

Descomptada la tendència, al Govern d'Espanya el PSOE crea {formatNumber(esperados_resumen[0]?.psoe_est, 2)} vegades el que és esperable i el PP, {formatNumber(esperados_resumen[0]?.pp_est, 2)} vegades: {#if esperados_resumen[0]?.z_est >= 1.96}una diferència més gran que la que explicaria l'atzar, tot i que amb pocs casos{:else}amb tan pocs casos, la diferència no és més gran que la que podria explicar l'atzar{/if}. A les comunitats, el PSOE és a {formatNumber(esperados_resumen[0]?.psoe_aut, 2)} i el PP, a {formatNumber(esperados_resumen[0]?.pp_aut, 2)}: {#if esperados_resumen[0]?.z_aut >= 1.96}una diferència més gran que la que explicaria l'atzar{:else}una diferència que l'atzar pot explicar{/if}.

<BarChart
    data={estatal_anio}
    x=anio
    y=observatorios
    series=partido
    xFmt='0'
    seriesColors={Object.fromEntries(partidos_colores.map(d => [d.partido, d.color]))}
    title="Observatoris estatals creats cada any, segons el partit del Govern d'Espanya"
/>

## Tots els observatoris

<DataTable data={listado} rows=15 search=true>
    <Column id=nombre title="Observatori" wrap=true/>
    <Column id=nivel title="Nivell"/>
    <Column id=comunidad title="Comunitat"/>
    <Column id=municipio title="Municipi"/>
    <Column id=anio_creacion title="Creat" fmt='0'/>
    <Column id=partido title="Governava"/>
    <Column id=estado title="Estat"/>
    <Column id=tipo title="Tipus"/>
</DataTable>

---

**Font:** [observatoriospublicos.es](https://observatoriospublicos.es/), cens ciutadà d'observatoris de les administracions públiques espanyoles. El nivell i la comunitat es dedueixen de l'àmbit que indica el cens i, si no l'indica, del nom de l'observatori (municipis de l'INE, illes, províncies i gentilicis). L'estat "Sense informació" significa que el cens no diu si l'observatori continua actiu. Partit: presidències del Govern d'Espanya i de les comunitats autònomes revisades a partir de Wikidata i de les fonts oficials, i alcaldes del Sistema d'Informació Local del Ministeri de Política Territorial ([qui governa cada municipi](/ca/territorios/municipios)).
