---
title: Evolución da poboación
description: "Poboación de España desde 1971 e o seu crecemento anual por 1.000 habitantes, separado en nacementos menos defuncións e migración, por comunidade e provincia (INE)."
i18n_origen: f9535ffb3b9d
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql poblacion
SELECT CAST(anio AS INTEGER) AS anio, poblacion, poblacion / 1e6 AS millones
FROM mother.demografia_envejecimiento
WHERE nivel = 'pais'
ORDER BY anio
```

```sql anual
SELECT CAST(anio AS INTEGER) AS anio, crecimiento, crecimiento_1000, vegetativo_1000, resto_1000,
    crecimiento_vegetativo, resto, saldo_exterior_1000
FROM mother.demografia_anual
WHERE nivel = 'pais' AND crecimiento_1000 IS NOT NULL
ORDER BY anio
```

```sql resumen
SELECT
    (SELECT anio FROM ${poblacion} ORDER BY anio DESC LIMIT 1) AS anio_pob,
    (SELECT poblacion FROM ${poblacion} ORDER BY anio DESC LIMIT 1) AS pob,
    (SELECT anio FROM ${poblacion} ORDER BY anio LIMIT 1) AS anio_ini,
    (SELECT poblacion FROM ${poblacion} ORDER BY anio LIMIT 1) AS pob_ini,
    (SELECT poblacion FROM ${poblacion} WHERE anio = (SELECT max(anio) - 10 FROM ${poblacion})) AS pob_10
```

# 📈 Evolución da poboación

Como cambiou o número de habitantes de España desde 1971 e que parte do crecemento se debe aos nacementos e defuncións e que parte á migración.

<Grid cols=4>
    <KpiCard
        title="Poboación"
        value={resumen[0]?.pob}
        formattedValue="{formatNumber(resumen[0]?.pob / 1e6, 2)} millóns"
        period="a 1 de xaneiro de {resumen[0]?.anio_pob} · {formatNumber(resumen[0]?.pob_ini / 1e6, 1)} millóns en {resumen[0]?.anio_ini}"
        change={100 * (resumen[0]?.pob / resumen[0]?.pob_10 - 1)}
        changeUnit="%"
        changePeriod="en 10 anos"
        source="INE"
        sparklineData={poblacion.map(d => ({anio: d.anio, valor: d.millones}))}
    />
    <KpiCard
        title="Crecemento anual"
        value={anual.slice(-1)[0]?.crecimiento_1000}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.crecimiento_1000, 1)} por 1.000 hab."
        period="{formatNumber(anual.slice(-1)[0]?.crecimiento, 0)} persoas máis en {anual.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.crecimiento_1000}))}
    />
    <KpiCard
        title="Nacementos menos defuncións"
        value={anual.slice(-1)[0]?.vegetativo_1000}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.vegetativo_1000, 1)} por 1.000 hab."
        period="{formatNumber(anual.slice(-1)[0]?.crecimiento_vegetativo, 0)} persoas en {anual.slice(-1)[0]?.anio}"
        source="INE"
        href="/gl/demografia/natalidad"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.vegetativo_1000}))}
    />
    <KpiCard
        title="Migración e axustes"
        value={anual.slice(-1)[0]?.resto_1000}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.resto_1000, 1)} por 1.000 hab."
        period="{formatNumber(anual.slice(-1)[0]?.resto, 0)} persoas en {anual.slice(-1)[0]?.anio}"
        source="INE"
        href="/gl/sociedad/inmigracion"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.resto_1000}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('crecimiento_poblacion')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'crecimiento_poblacion')} />


## Poboación desde 1971

<LineChart
    data={poblacion}
    x=anio
    y=millones
    yFmt=num1
    xFmt="####"
    lineColor="#1d4ed8"
    yAxisTitle="millóns de habitantes"
    title="Poboación residente en España a 1 de xaneiro (millóns)"
/>

<p class="text-xs text-gray-500">Estatística Continua de Poboación do INE, que reconstrúe a serie desde 1971 con criterios homoxéneos. Entre {resumen[0]?.anio_ini} e {resumen[0]?.anio_pob} a poboación pasou de {formatNumber(resumen[0]?.pob_ini / 1e6, 1)} a {formatNumber(resumen[0]?.pob / 1e6, 1)} millóns.</p>

## Nacementos, defuncións e migración

```sql componentes
SELECT anio, 'Nacimientos menos defunciones' AS componente, vegetativo_1000 AS por_1000 FROM ${anual}
UNION ALL
SELECT anio, 'Migración y ajustes', resto_1000 FROM ${anual}
ORDER BY anio
```

```sql anios_baja
SELECT count(*) AS n, string_agg(CAST(anio AS VARCHAR), ', ' ORDER BY anio) AS lista,
    count(*) FILTER (WHERE resto_1000 < 0) AS con_migracion_negativa
FROM ${anual}
WHERE crecimiento_1000 < 0
```

```sql decadas
SELECT
    CASE WHEN anio < 1985 THEN '1975-1984' WHEN anio < 1995 THEN '1985-1994' WHEN anio < 2005 THEN '1995-2004'
         WHEN anio < 2015 THEN '2005-2014' ELSE '2015-' || max(anio) OVER () END AS periodo,
    vegetativo_1000, resto_1000, crecimiento_1000
FROM ${anual}
```

```sql decadas_media
SELECT periodo, avg(vegetativo_1000) AS vegetativo, avg(resto_1000) AS migracion, avg(crecimiento_1000) AS total
FROM ${decadas}
GROUP BY 1
ORDER BY 1
```

<BarChart
    data={componentes}
    x=anio
    y=por_1000
    series=componente
    type=stacked
    yFmt=num1
    xFmt="####"
    colorPalette={['#be185d', '#0f766e']}
    yAxisTitle="por 1.000 habitantes"
    title="Crecemento anual por 1.000 habitantes e os seus compoñentes"
/>

<DataTable data={decadas_media} rows=all>
    <Column id=periodo title="Período" />
    <Column id=total title="Crecemento medio anual por 1.000 hab." fmt=num1 />
    <Column id=vegetativo title="…por nacementos menos defuncións" fmt=num1 contentType=delta />
    <Column id=migracion title="…por migración e axustes" fmt=num1 contentType=delta />
</DataTable>

<p class="text-xs text-gray-500">"Migración e axustes" = crecemento total menos crecemento vexetativo. Desde 2021 pode compararse co saldo migratorio co estranxeiro que mide directamente a Estatística de Migracións: en {anual.slice(-1)[0]?.anio}, {formatNumber(anual.slice(-1)[0]?.resto_1000, 1)} fronte a {formatNumber(anual.slice(-1)[0]?.saldo_exterior_1000, 1)} por 1.000 habitantes. {#if anios_baja[0]?.n > 0}Desde 1975 a poboación só baixou en {anios_baja[0]?.n} anos ({anios_baja[0]?.lista}){#if anios_baja[0]?.con_migracion_negativa === anios_baja[0]?.n}, e en todos eles o compoñente de migración foi negativo{/if}.{/if}</p>

## Por comunidade autónoma

```sql ccaa
SELECT a.cod, t.nombre AS comunidad, '/gl' || t.ruta AS ruta,
    a.crecimiento_1000, a.vegetativo_1000, a.resto_1000, a.saldo_exterior_1000,
    e.poblacion, 100.0 * (e.poblacion / e10.poblacion - 1) AS crec_10
FROM mother.demografia_anual a
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = a.cod
JOIN mother.demografia_envejecimiento e ON e.nivel = 'ccaa' AND e.cod = a.cod AND e.anio = a.anio + 1
JOIN mother.demografia_envejecimiento e10 ON e10.nivel = 'ccaa' AND e10.cod = a.cod AND e10.anio = a.anio - 9
WHERE a.nivel = 'ccaa' AND a.anio = (SELECT max(anio) FROM mother.demografia_anual WHERE crecimiento_1000 IS NOT NULL)
ORDER BY a.crecimiento_1000 DESC
```

En {anual.slice(-1)[0]?.anio} as comunidades que máis medraron en proporción á súa poboación foron {ccaa[0]?.comunidad} ({formatNumber(ccaa[0]?.crecimiento_1000, 1)} por 1.000 hab.) e {ccaa[1]?.comunidad} ({formatNumber(ccaa[1]?.crecimiento_1000, 1)}); a que menos, {ccaa.slice(-1)[0]?.comunidad} ({formatNumber(ccaa.slice(-1)[0]?.crecimiento_1000, 1)}).

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidade" />
    <Column id=crecimiento_1000 title="Crecemento por 1.000 hab." fmt=num1 contentType=bar barColor="#bfdbfe" />
    <Column id=vegetativo_1000 title="…nacementos menos defuncións" fmt=num1 contentType=delta />
    <Column id=resto_1000 title="…migración e axustes" fmt=num1 />
    <Column id=saldo_exterior_1000 title="Saldo co estranxeiro" fmt=num1 />
    <Column id=crec_10 title="Crecemento en 10 anos (%)" fmt=num1 />
    <Column id=poblacion title="Poboación" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Nunha comunidade, "migración e axustes" inclúe tamén os cambios de residencia desde e cara a outras comunidades; por iso non coincide co saldo co estranxeiro. Poboación a 1 de xaneiro de {anual.slice(-1)[0]?.anio + 1}.</p>

## Por provincia

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/gl' || t.ruta AS ruta, e.poblacion,
    100.0 * (e.poblacion / e10.poblacion - 1) AS crec_10,
    100.0 * (e.poblacion / e00.poblacion - 1) AS crec_2000
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
JOIN mother.demografia_envejecimiento e10 ON e10.nivel = 'provincia' AND e10.cod = e.cod AND e10.anio = e.anio - 10
JOIN mother.demografia_envejecimiento e00 ON e00.nivel = 'provincia' AND e00.cod = e.cod AND e00.anio = 2000
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY crec_10 DESC
```

```sql provincias_resumen
SELECT count(*) FILTER (WHERE crec_10 < 0) AS pierden_10, count(*) FILTER (WHERE crec_2000 < 0) AS pierden_2000
FROM ${provincias}
```

Hoxe hai {provincias_resumen[0]?.pierden_10} provincias con menos habitantes ca hai dez anos, e {provincias_resumen[0]?.pierden_2000} con menos ca en 2000.

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="crec_10"
    valueFmt="num1"
    link="ruta"
    colorPalette={['#b91c1c', '#f8fafc', '#1d4ed8']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    title="Variación da poboación nos últimos 10 anos (%)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'crec_10', title: 'Variación en 10 anos (%)', fmt: 'num1'},
        {id: 'crec_2000', title: 'Variación desde 2000 (%)', fmt: 'num1'},
        {id: 'poblacion', title: 'Poboación', fmt: 'num0'}
    ]}
/>

---

## Fontes e notas

- **[INE – Estatística Continua de Poboación](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (táboa 56945): poboación a 1 de xaneiro por provincia desde 1971. É a serie oficial homoxénea; pode diferir lixeiramente das cifras do padrón municipal que se usan nas fichas de [territorios](/gl/territorios).
- **[INE – Movemento Natural da Poboación](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177007)** (táboas 6524 e 6561): nacementos e defuncións por provincia de residencia.
- **[INE – Estatística de Migracións e Cambios de Residencia](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177000)** (táboas 69758 e 69762): saldo co estranxeiro desde 2021.
- Crecemento por 1.000 hab. = (poboación a 1 de xaneiro do ano seguinte − poboación a 1 de xaneiro) / poboación media do ano × 1.000.

<LastRefreshed prefix="Datos actualizados" />
