---
title: Observatorios públicos
description: "Censo dos observatorios públicos de España: cantos hai, que administración os crea, cando naceron, cantos seguen activos, cantos hai por habitante en cada comunidade e que partido gobernaba cando se crearon."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: ff0c7540da64
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
    '/gl' || t.ruta AS ruta,
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

# 🔍 Observatorios públicos

As administracións crean observatorios para seguir un tema (a violencia de xénero, a vivenda, o cambio climático, o comercio...) e publicar informes sobre el. Esta páxina resume o censo que mantén [observatoriospublicos.es](https://observatoriospublicos.es/): cantos hai, quen os crea, cando naceron e se seguen activos.

<Grid cols=4>
    <KpiCard
        title="Observatorios censados"
        value={resumen[0]?.total}
        formattedValue={formatNumber(resumen[0]?.total, 0)}
        period="{formatNumber(resumen[0]?.estatales, 0)} da Administración Xeral do Estado"
        source="observatoriospublicos.es"
        sparklineData={por_anio.map(d => ({...d, y: d.acumulados}))}
    />
    <KpiCard
        title="Activos"
        value={resumen[0]?.pct_activos}
        formattedValue="{formatNumber(resumen[0]?.pct_activos, 0)} %"
        period="{formatNumber(resumen[0]?.activos, 0)} confirmados · {formatNumber(resumen[0]?.inactivos, 0)} pechados · {formatNumber(resumen[0]?.sin_info, 0)} sen información"
        source="observatoriospublicos.es"
    />
    <KpiCard
        title="Creados desde 2015"
        value={resumen[0]?.pct_desde_2015}
        formattedValue="{formatNumber(resumen[0]?.pct_desde_2015, 0)} %"
        period="{formatNumber(resumen[0]?.desde_2015, 0)} dos {formatNumber(resumen[0]?.con_anio, 0)} con ano de creación coñecido"
        source="observatoriospublicos.es"
        sparklineData={por_anio.map(d => ({...d, y: d.creados}))}
    />
    <KpiCard
        title="Con participación privada"
        value={resumen[0]?.mixtos}
        formattedValue="{formatNumber(resumen[0]?.mixtos / resumen[0]?.total / 0.01, 1)} %"
        period="{formatNumber(resumen[0]?.mixtos, 0)} observatorios mixtos (público-privados)"
        source="observatoriospublicos.es"
    />
</Grid>

## Cando se crearon

Observatorios creados cada ano e total acumulado. Só {formatNumber(resumen[0]?.con_anio, 0)} dos {formatNumber(resumen[0]?.total, 0)} teñen data de creación no censo, así que as barras quedan curtas. Entre os que teñen data, o {formatNumber(resumen[0]?.pct_desde_2015, 0)} % naceu en 2015 ou despois (os máis recentes tamén adoitan ter a data mellor documentada).

<BarChart
    data={por_anio}
    x=anio
    y=creados
    y2=acumulados
    y2SeriesType=line
    xFmt='0'
    yAxisTitle="Creados no ano"
    y2AxisTitle="Acumulados"
    title="Observatorios públicos creados por ano (con data coñecida)"
/>

## Quen os crea e cantos seguen activos

Por nivel da administración. O censo só marca como pechados {formatNumber(resumen[0]?.inactivos, 0)} observatorios; do total, o {formatNumber(resumen[0]?.pct_sin_info, 0)} % non ten información sobre se segue funcionando.

<BarChart
    data={por_nivel}
    x=nivel
    y=observatorios
    series=estado
    swapXY=true
    sort=false
    colorPalette={['#16a34a', '#dc2626', '#94a3b8']}
    title="Observatorios por nivel da administración e estado"
/>

## Por comunidade autónoma

Observatorios autonómicos, provinciais e locais de cada comunidade, por millón de habitantes. A comunidade sae do ámbito que indica o censo ou, se non o di, do nome do observatorio: o municipio (cruzado cos do INE), a illa ou provincia, ou o xentilicio ("Andaluz", "Galego"...). Quedan {formatNumber(resumen[0]?.sin_comunidad, 0)} sen situar porque o seu nome non permite sabelo ("Observatorio Social", "Observatorio del Agua"...).

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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: observatoriospublicos.es"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'por_millon', title: 'Por millón de hab.', fmt: '0.0'},
        {id: 'observatorios', title: 'Observatorios', fmt: '0'}
    ]}
/>

<DataTable data={por_ccaa} rows=20>
    <Column id=comunidad title="Comunidade"/>
    <Column id=por_millon title="Por millón de hab." fmt='0.0'/>
    <Column id=observatorios title="Observatorios" fmt='0'/>
    <Column id=activos title="Activos confirmados" fmt='0'/>
</DataTable>

## Quen gobernaba cando se crearon

Cada observatorio con ano de creación atribúese ao partido que gobernaba a administración que o creou a metade dese ano: o Goberno de España para os estatais, a presidencia da comunidade para os autonómicos e a alcaldía para os municipais. Así atribúense {formatNumber(cobertura[0]?.atribuidos, 0)} dos {formatNumber(cobertura[0]?.total, 0)} observatorios do censo: o resto non ten data de creación, é dunha deputación ou cabido ({formatNumber(cobertura[0]?.provinciales, 0)}, sen datos de quen os presidía) ou non se pode situar. En {formatNumber(cobertura[0]?.dudosos, 0)} casos o goberno cambiou ese mesmo ano e a atribución é menos segura.

<BarChart
    data={partidos}
    x=partido
    y=observatorios
    series=nivel
    swapXY=true
    sort=false
    colorPalette={['#0f766e', '#6366f1', '#f59e0b', '#94a3b8']}
    title="Observatorios creados segundo o partido que gobernaba (con ano de creación coñecido)"
/>

Contar sen máis favorece a quen máis gobernou, e tamén a quen goberna agora: créanse cada vez máis observatorios (e o censo documenta mellor os recentes). Para descontalo, a táboa compara os observatorios **observados** cos **esperados** se cada partido seguise a tendencia do resto do censo nos anos en que gobernou (para os estatais, a dos autonómicos e locais, que non dependen do Goberno de España). Unha ratio de 1 é o esperable; 2, o dobre; 0,5, a metade.

<DataTable data={esperados} rows=20>
    <Column id=nivel title="Nivel"/>
    <Column id=partido title="Partido do presidente"/>
    <Column id=observados title="Observados" fmt='0'/>
    <Column id=esperados title="Esperados pola tendencia" fmt='0.0'/>
    <Column id=ratio title="Observados / esperados" fmt='0.00'/>
</DataTable>

Descontada a tendencia, no Goberno de España o PSOE crea {formatNumber(esperados_resumen[0]?.psoe_est, 2)} veces o esperado e o PP {formatNumber(esperados_resumen[0]?.pp_est, 2)} veces: {#if esperados_resumen[0]?.z_est >= 1.96}unha diferenza maior da que explicaría o azar, aínda que con poucos casos{:else}con tan poucos casos, a diferenza non é maior da que podería explicar o azar{/if}. Nas comunidades, o PSOE está en {formatNumber(esperados_resumen[0]?.psoe_aut, 2)} e o PP en {formatNumber(esperados_resumen[0]?.pp_aut, 2)}: {#if esperados_resumen[0]?.z_aut >= 1.96}unha diferenza maior da que explicaría o azar{:else}unha diferenza que o azar pode explicar{/if}.

<BarChart
    data={estatal_anio}
    x=anio
    y=observatorios
    series=partido
    xFmt='0'
    seriesColors={Object.fromEntries(partidos_colores.map(d => [d.partido, d.color]))}
    title="Observatorios estatais creados cada ano, segundo o partido do Goberno de España"
/>

## Todos os observatorios

<DataTable data={listado} rows=15 search=true>
    <Column id=nombre title="Observatorio" wrap=true/>
    <Column id=nivel title="Nivel"/>
    <Column id=comunidad title="Comunidade"/>
    <Column id=municipio title="Municipio"/>
    <Column id=anio_creacion title="Creado" fmt='0'/>
    <Column id=partido title="Gobernaba"/>
    <Column id=estado title="Estado"/>
    <Column id=tipo title="Tipo"/>
</DataTable>

---

**Fonte:** [observatoriospublicos.es](https://observatoriospublicos.es/), censo cidadán de observatorios das administracións públicas españolas. O nivel e a comunidade dedúcense do ámbito que indica o censo e, se non o indica, do nome do observatorio (municipios do INE, illas, provincias e xentilicios). O estado "Sin información" significa que o censo non di se o observatorio segue activo. Partido: presidencias do Goberno de España e das comunidades autónomas revisadas a partir de Wikidata e das fontes oficiais, e alcaldes do Sistema de Información Local do Ministerio de Política Territorial ([quen goberna cada municipio](/gl/territorios/municipios)).
