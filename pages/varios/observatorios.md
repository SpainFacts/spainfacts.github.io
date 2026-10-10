---
title: Observatorios públicos
description: "Censo de los observatorios públicos de España: cuántos hay, qué administración los crea, cuándo nacieron, cuántos siguen activos, cuántos hay por habitante en cada comunidad y qué partido gobernaba cuando se crearon."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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
    t.ruta,
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

Las administraciones crean observatorios para seguir un tema (la violencia de género, la vivienda, el cambio climático, el comercio...) y publicar informes sobre él. Esta página resume el censo que mantiene [observatoriospublicos.es](https://observatoriospublicos.es/): cuántos hay, quién los crea, cuándo nacieron y si siguen activos.

<Grid cols=4>
    <KpiCard
        title="Observatorios censados"
        value={resumen[0]?.total}
        formattedValue={formatNumber(resumen[0]?.total, 0)}
        period="{formatNumber(resumen[0]?.estatales, 0)} de la Administración General del Estado"
        source="observatoriospublicos.es"
        sparklineData={por_anio.map(d => ({...d, y: d.acumulados}))}
    />
    <KpiCard
        title="Activos"
        value={resumen[0]?.pct_activos}
        formattedValue="{formatNumber(resumen[0]?.pct_activos, 0)} %"
        period="{formatNumber(resumen[0]?.activos, 0)} confirmados · {formatNumber(resumen[0]?.inactivos, 0)} cerrados · {formatNumber(resumen[0]?.sin_info, 0)} sin información"
        source="observatoriospublicos.es"
    />
    <KpiCard
        title="Creados desde 2015"
        value={resumen[0]?.pct_desde_2015}
        formattedValue="{formatNumber(resumen[0]?.pct_desde_2015, 0)} %"
        period="{formatNumber(resumen[0]?.desde_2015, 0)} de los {formatNumber(resumen[0]?.con_anio, 0)} con año de creación conocido"
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

## Cuándo se crearon

Observatorios creados cada año y total acumulado. Solo {formatNumber(resumen[0]?.con_anio, 0)} de los {formatNumber(resumen[0]?.total, 0)} tienen fecha de creación en el censo, así que las barras se quedan cortas. Entre los que tienen fecha, el {formatNumber(resumen[0]?.pct_desde_2015, 0)} % nació en 2015 o después (los más recientes también suelen tener la fecha mejor documentada).

<BarChart
    data={por_anio}
    x=anio
    y=creados
    y2=acumulados
    y2SeriesType=line
    xFmt='0'
    yAxisTitle="Creados en el año"
    y2AxisTitle="Acumulados"
    title="Observatorios públicos creados por año (con fecha conocida)"
/>

## Quién los crea y cuántos siguen activos

Por nivel de la administración. El censo solo marca como cerrados {formatNumber(resumen[0]?.inactivos, 0)} observatorios; del total, el {formatNumber(resumen[0]?.pct_sin_info, 0)} % no tiene información sobre si sigue funcionando.

<BarChart
    data={por_nivel}
    x=nivel
    y=observatorios
    series=estado
    swapXY=true
    sort=false
    colorPalette={['#16a34a', '#dc2626', '#94a3b8']}
    title="Observatorios por nivel de la administración y estado"
/>

## Por comunidad autónoma

Observatorios autonómicos, provinciales y locales de cada comunidad, por millón de habitantes. La comunidad sale del ámbito que indica el censo o, si no lo dice, del nombre del observatorio: el municipio (cruzado con los del INE), la isla o provincia, o el gentilicio ("Andaluz", "Galego"...). Quedan {formatNumber(resumen[0]?.sin_comunidad, 0)} sin ubicar porque su nombre no permite saberlo ("Observatorio Social", "Observatorio del Agua"...).

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: observatoriospublicos.es"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'por_millon', title: 'Por millón de hab.', fmt: '0.0'},
        {id: 'observatorios', title: 'Observatorios', fmt: '0'}
    ]}
/>

<DataTable data={por_ccaa} rows=20>
    <Column id=comunidad title="Comunidad"/>
    <Column id=por_millon title="Por millón de hab." fmt='0.0'/>
    <Column id=observatorios title="Observatorios" fmt='0'/>
    <Column id=activos title="Activos confirmados" fmt='0'/>
</DataTable>

## Quién gobernaba cuando se crearon

Cada observatorio con año de creación se atribuye al partido que gobernaba la administración que lo creó a mitad de ese año: el Gobierno de España para los estatales, la presidencia de la comunidad para los autonómicos y la alcaldía para los municipales. Así se atribuyen {formatNumber(cobertura[0]?.atribuidos, 0)} de los {formatNumber(cobertura[0]?.total, 0)} observatorios del censo: el resto no tiene fecha de creación, es de una diputación o cabildo ({formatNumber(cobertura[0]?.provinciales, 0)}, sin datos de quién los presidía) o no se puede ubicar. En {formatNumber(cobertura[0]?.dudosos, 0)} casos el gobierno cambió ese mismo año y la atribución es menos segura.

<BarChart
    data={partidos}
    x=partido
    y=observatorios
    series=nivel
    swapXY=true
    sort=false
    colorPalette={['#0f766e', '#6366f1', '#f59e0b', '#94a3b8']}
    title="Observatorios creados según el partido que gobernaba (con año de creación conocido)"
/>

Contar sin más favorece a quien más ha gobernado, y también a quien gobierna ahora: se crean cada vez más observatorios (y el censo documenta mejor los recientes). Para descontarlo, la tabla compara los observatorios **observados** con los **esperados** si cada partido hubiera seguido la tendencia del resto del censo en los años en que gobernó (para los estatales, la de los autonómicos y locales, que no dependen del Gobierno de España). Una ratio de 1 es lo esperable; 2, el doble; 0,5, la mitad.

<DataTable data={esperados} rows=20>
    <Column id=nivel title="Nivel"/>
    <Column id=partido title="Partido del presidente"/>
    <Column id=observados title="Observados" fmt='0'/>
    <Column id=esperados title="Esperados por la tendencia" fmt='0.0'/>
    <Column id=ratio title="Observados / esperados" fmt='0.00'/>
</DataTable>

Descontada la tendencia, en el Gobierno de España el PSOE crea {formatNumber(esperados_resumen[0]?.psoe_est, 2)} veces lo esperado y el PP {formatNumber(esperados_resumen[0]?.pp_est, 2)} veces: {#if esperados_resumen[0]?.z_est >= 1.96}una diferencia mayor de la que explicaría el azar, aunque con pocos casos{:else}con tan pocos casos, la diferencia no es mayor de la que podría explicar el azar{/if}. En las comunidades, el PSOE está en {formatNumber(esperados_resumen[0]?.psoe_aut, 2)} y el PP en {formatNumber(esperados_resumen[0]?.pp_aut, 2)}: {#if esperados_resumen[0]?.z_aut >= 1.96}una diferencia mayor de la que explicaría el azar{:else}una diferencia que el azar puede explicar{/if}.

<BarChart
    data={estatal_anio}
    x=anio
    y=observatorios
    series=partido
    xFmt='0'
    seriesColors={Object.fromEntries(partidos_colores.map(d => [d.partido, d.color]))}
    title="Observatorios estatales creados cada año, según el partido del Gobierno de España"
/>

## Todos los observatorios

<DataTable data={listado} rows=15 search=true>
    <Column id=nombre title="Observatorio" wrap=true/>
    <Column id=nivel title="Nivel"/>
    <Column id=comunidad title="Comunidad"/>
    <Column id=municipio title="Municipio"/>
    <Column id=anio_creacion title="Creado" fmt='0'/>
    <Column id=partido title="Gobernaba"/>
    <Column id=estado title="Estado"/>
    <Column id=tipo title="Tipo"/>
</DataTable>

---

**Fuente:** [observatoriospublicos.es](https://observatoriospublicos.es/), censo ciudadano de observatorios de las administraciones públicas españolas. El nivel y la comunidad se deducen del ámbito que indica el censo y, si no lo indica, del nombre del observatorio (municipios del INE, islas, provincias y gentilicios). El estado "Sin información" significa que el censo no dice si el observatorio sigue activo. Partido: presidencias del Gobierno de España y de las comunidades autónomas revisadas a partir de Wikidata y de las fuentes oficiales, y alcaldes del Sistema de Información Local del Ministerio de Política Territorial ([quién gobierna cada municipio](/territorios/municipios)).
