---
title: Evolució de la població
description: "Població d'Espanya des de 1971 i el seu creixement anual per 1.000 habitants, separat en naixements menys defuncions i migració, per comunitat i província (INE)."
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

# 📈 Evolució de la població

Com ha canviat el nombre d'habitants d'Espanya des de 1971 i quina part del creixement es deu als naixements i les defuncions i quina a la migració.

<Grid cols=4>
    <KpiCard
        title="Població"
        value={resumen[0]?.pob}
        formattedValue="{formatNumber(resumen[0]?.pob / 1e6, 2)} milions"
        period="a 1 de gener de {resumen[0]?.anio_pob} · {formatNumber(resumen[0]?.pob_ini / 1e6, 1)} milions el {resumen[0]?.anio_ini}"
        change={100 * (resumen[0]?.pob / resumen[0]?.pob_10 - 1)}
        changeUnit="%"
        changePeriod="en 10 anys"
        source="INE"
        sparklineData={poblacion.map(d => ({anio: d.anio, valor: d.millones}))}
    />
    <KpiCard
        title="Creixement anual"
        value={anual.slice(-1)[0]?.crecimiento_1000}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.crecimiento_1000, 1)} per 1.000 hab."
        period="{formatNumber(anual.slice(-1)[0]?.crecimiento, 0)} persones més el {anual.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.crecimiento_1000}))}
    />
    <KpiCard
        title="Naixements menys defuncions"
        value={anual.slice(-1)[0]?.vegetativo_1000}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.vegetativo_1000, 1)} per 1.000 hab."
        period="{formatNumber(anual.slice(-1)[0]?.crecimiento_vegetativo, 0)} persones el {anual.slice(-1)[0]?.anio}"
        source="INE"
        href="/ca/demografia/natalidad"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.vegetativo_1000}))}
    />
    <KpiCard
        title="Migració i ajustos"
        value={anual.slice(-1)[0]?.resto_1000}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.resto_1000, 1)} per 1.000 hab."
        period="{formatNumber(anual.slice(-1)[0]?.resto, 0)} persones el {anual.slice(-1)[0]?.anio}"
        source="INE"
        href="/ca/sociedad/inmigracion"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.resto_1000}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('crecimiento_poblacion')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'crecimiento_poblacion')} />


## Població des de 1971

<LineChart
    data={poblacion}
    x=anio
    y=millones
    yFmt=num1
    xFmt="####"
    lineColor="#1d4ed8"
    yAxisTitle="milions d'habitants"
    title="Població resident a Espanya a 1 de gener (milions)"
/>

<p class="text-xs text-gray-500">Estadística Contínua de Població de l'INE, que reconstrueix la sèrie des de 1971 amb criteris homogenis. Entre el {resumen[0]?.anio_ini} i el {resumen[0]?.anio_pob} la població ha passat de {formatNumber(resumen[0]?.pob_ini / 1e6, 1)} a {formatNumber(resumen[0]?.pob / 1e6, 1)} milions.</p>

## Naixements, defuncions i migració

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
    yAxisTitle="per 1.000 habitants"
    title="Creixement anual per 1.000 habitants i els seus components"
/>

<DataTable data={decadas_media} rows=all>
    <Column id=periodo title="Període" />
    <Column id=total title="Creixement mitjà anual per 1.000 hab." fmt=num1 />
    <Column id=vegetativo title="…per naixements menys defuncions" fmt=num1 contentType=delta />
    <Column id=migracion title="…per migració i ajustos" fmt=num1 contentType=delta />
</DataTable>

<p class="text-xs text-gray-500">"Migració i ajustos" = creixement total menys creixement vegetatiu. Des del 2021 es pot comparar amb el saldo migratori amb l'estranger que mesura directament l'Estadística de Migracions: el {anual.slice(-1)[0]?.anio}, {formatNumber(anual.slice(-1)[0]?.resto_1000, 1)} davant de {formatNumber(anual.slice(-1)[0]?.saldo_exterior_1000, 1)} per 1.000 habitants. {#if anios_baja[0]?.n > 0}Des del 1975 la població només ha baixat {anios_baja[0]?.n} anys ({anios_baja[0]?.lista}){#if anios_baja[0]?.con_migracion_negativa === anios_baja[0]?.n}, i en tots el component de migració va ser negatiu{/if}.{/if}</p>

## Per comunitat autònoma

```sql ccaa
SELECT a.cod, t.nombre AS comunidad, '/ca' || t.ruta AS ruta,
    a.crecimiento_1000, a.vegetativo_1000, a.resto_1000, a.saldo_exterior_1000,
    e.poblacion, 100.0 * (e.poblacion / e10.poblacion - 1) AS crec_10
FROM mother.demografia_anual a
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = a.cod
JOIN mother.demografia_envejecimiento e ON e.nivel = 'ccaa' AND e.cod = a.cod AND e.anio = a.anio + 1
JOIN mother.demografia_envejecimiento e10 ON e10.nivel = 'ccaa' AND e10.cod = a.cod AND e10.anio = a.anio - 9
WHERE a.nivel = 'ccaa' AND a.anio = (SELECT max(anio) FROM mother.demografia_anual WHERE crecimiento_1000 IS NOT NULL)
ORDER BY a.crecimiento_1000 DESC
```

El {anual.slice(-1)[0]?.anio} les comunitats que més van créixer en proporció a la seva població van ser {ccaa[0]?.comunidad} ({formatNumber(ccaa[0]?.crecimiento_1000, 1)} per 1.000 hab.) i {ccaa[1]?.comunidad} ({formatNumber(ccaa[1]?.crecimiento_1000, 1)}); la que menys, {ccaa.slice(-1)[0]?.comunidad} ({formatNumber(ccaa.slice(-1)[0]?.crecimiento_1000, 1)}).

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=crecimiento_1000 title="Creixement per 1.000 hab." fmt=num1 contentType=bar barColor="#bfdbfe" />
    <Column id=vegetativo_1000 title="…naixements menys defuncions" fmt=num1 contentType=delta />
    <Column id=resto_1000 title="…migració i ajustos" fmt=num1 />
    <Column id=saldo_exterior_1000 title="Saldo amb l'estranger" fmt=num1 />
    <Column id=crec_10 title="Creixement en 10 anys (%)" fmt=num1 />
    <Column id=poblacion title="Població" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">En una comunitat, "migració i ajustos" inclou també els canvis de residència des d'altres comunitats i cap a altres comunitats; per això no coincideix amb el saldo amb l'estranger. Població a 1 de gener de {anual.slice(-1)[0]?.anio + 1}.</p>

## Per província

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/ca' || t.ruta AS ruta, e.poblacion,
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

{provincias_resumen[0]?.pierden_10} províncies tenen avui menys habitants que fa deu anys, i {provincias_resumen[0]?.pierden_2000}, menys que el 2000.

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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
    title="Variació de la població en els últims 10 anys (%)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'crec_10', title: 'Variació en 10 anys (%)', fmt: 'num1'},
        {id: 'crec_2000', title: 'Variació des del 2000 (%)', fmt: 'num1'},
        {id: 'poblacion', title: 'Població', fmt: 'num0'}
    ]}
/>

---

## Fonts i notes

- **[INE – Estadística Contínua de Població](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (taula 56945): població a 1 de gener per província des de 1971. És la sèrie oficial homogènia; pot diferir lleugerament de les xifres del padró municipal que es fan servir a les fitxes de [territoris](/ca/territorios).
- **[INE – Moviment Natural de la Població](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177007)** (taules 6524 i 6561): naixements i defuncions per província de residència.
- **[INE – Estadística de Migracions i Canvis de Residència](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177000)** (taules 69758 i 69762): saldo amb l'estranger des del 2021.
- Creixement per 1.000 hab. = (població a 1 de gener de l'any següent − població a 1 de gener) / població mitjana de l'any × 1.000.

<LastRefreshed prefix="Dades actualitzades" />
