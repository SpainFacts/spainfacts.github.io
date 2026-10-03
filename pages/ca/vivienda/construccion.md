---
title: Obra nova
description: "Habitatges lliures que es comencen i s'acaben cada any a Espanya per 1.000 habitants des del 1996, per comunitat i província, amb dades del Ministeri d'Habitatge."
i18n_origen: 6b1ad71c87ca
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT anio, iniciadas, terminadas, iniciadas_1000, terminadas_1000
FROM mother.vivienda_obra_nueva
WHERE nivel = 'pais' AND iniciadas_1000 IS NOT NULL
ORDER BY anio
```

```sql espana_largo
SELECT anio, 'Iniciadas' AS fase, iniciadas_1000 AS por_1000 FROM ${espana}
UNION ALL
SELECT anio, 'Terminadas' AS fase, terminadas_1000 AS por_1000 FROM ${espana}
ORDER BY anio, fase
```

```sql hitos
SELECT
    max(anio) AS anio_ult,
    arg_max(terminadas_1000, anio) AS term_ult,
    arg_max(iniciadas_1000, anio) AS ini_ult,
    arg_max(terminadas, anio) AS term_total,
    arg_max(iniciadas, anio) AS ini_total,
    max(terminadas_1000) AS term_max,
    arg_max(anio, terminadas_1000) AS anio_term_max,
    max(iniciadas_1000) AS ini_max,
    arg_max(anio, iniciadas_1000) AS anio_ini_max,
    min(terminadas_1000) AS term_min,
    arg_min(anio, terminadas_1000) AS anio_term_min,
    arg_max(terminadas_1000, anio) / max(terminadas_1000) AS fraccion_max,
    avg(terminadas_1000) FILTER (WHERE anio BETWEEN 1996 AND 2000) AS media_9600
FROM ${espana}
```

```sql mercado
SELECT o.anio, o.terminadas_1000, m.compraventas_nueva_1000
FROM mother.vivienda_obra_nueva o
JOIN mother.vivienda_mercado_anual m ON m.nivel = 'pais' AND m.anio = o.anio AND m.meses = 12
WHERE o.nivel = 'pais'
ORDER BY o.anio
```

```sql mercado_largo
SELECT anio, 'Viviendas libres terminadas' AS serie, terminadas_1000 AS por_1000 FROM ${mercado}
UNION ALL
SELECT anio, 'Compraventas de vivienda nueva' AS serie, compraventas_nueva_1000 AS por_1000 FROM ${mercado}
ORDER BY anio, serie
```

```sql ccaa
SELECT o.cod, o.nombre AS comunidad, '/ca' || t.ruta AS ruta, o.anio, o.iniciadas_1000, o.terminadas_1000, o.iniciadas, o.terminadas,
       (SELECT avg(x.terminadas_1000) FROM mother.vivienda_obra_nueva x WHERE x.nivel = 'ccaa' AND x.cod = o.cod AND x.anio BETWEEN o.anio - 4 AND o.anio) AS terminadas_1000_5a
FROM mother.vivienda_obra_nueva o
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = o.cod
WHERE o.nivel = 'ccaa' AND o.anio = (SELECT max(anio) FROM mother.vivienda_obra_nueva)
ORDER BY o.terminadas_1000 DESC
```

```sql provincias
SELECT o.cod AS cod_prov, o.nombre AS provincia, '/ca' || t.ruta AS ruta, o.iniciadas_1000, o.terminadas_1000, o.iniciadas, o.terminadas
FROM mother.vivienda_obra_nueva o
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = o.cod
WHERE o.nivel = 'provincia' AND o.anio = (SELECT max(anio) FROM mother.vivienda_obra_nueva)
ORDER BY o.terminadas_1000 DESC
```

# 🏗️ Obra nova

Quants habitatges es construeixen a Espanya. Són **habitatges lliures** (sense el protegit) que es comencen (**iniciats**) i s'acaben (**acabats**) cada any, estimats pel Ministeri d'Habitatge a partir dels certificats dels col·legis d'aparelladors, sempre **per cada 1.000 habitants**.

<Grid cols=4>
    <KpiCard
        title="Habitatges acabats"
        value={hitos[0]?.term_ult}
        formattedValue="{formatNumber(hitos[0]?.term_ult, 2)} per 1.000 hab."
        period="{hitos[0]?.anio_ult} · {formatCompact(hitos[0]?.term_total, 0)} habitatges lliures"
        source="Ministeri d'Habitatge"
        sparklineData={espana.map(d => d.terminadas_1000)}
    />
    <KpiCard
        title="Habitatges iniciats"
        value={hitos[0]?.ini_ult}
        formattedValue="{formatNumber(hitos[0]?.ini_ult, 2)} per 1.000 hab."
        period="{hitos[0]?.anio_ult} · {formatCompact(hitos[0]?.ini_total, 0)} habitatges lliures"
        source="Ministeri d'Habitatge"
        sparklineData={espana.map(d => d.iniciadas_1000)}
    />
    <KpiCard
        title="Respecte al màxim"
        value={hitos[0]?.fraccion_max}
        formattedValue="{formatNumber(hitos[0]?.fraccion_max / 0.01, 0)} %"
        period="dels habitatges acabats per habitant el {hitos[0]?.anio_term_max} ({formatNumber(hitos[0]?.term_max, 1)} per 1.000 hab.)"
        source="Ministeri d'Habitatge"
        sparklineData={espana.map(d => d.terminadas_1000)}
    />
    <KpiCard
        title="Respecte a finals dels 90"
        value={hitos[0]?.media_9600}
        formattedValue="{formatNumber(hitos[0]?.media_9600, 1)} per 1.000 hab."
        period="habitatges acabats l'any de mitjana el 1996-2000"
        source="Ministeri d'Habitatge"
        sparklineData={espana.filter(d => d.anio <= 2000).map(d => d.terminadas_1000)}
    />
</Grid>

## Evolució

El màxim d'habitatges acabats per habitant va ser el {hitos[0]?.anio_term_max} ({formatNumber(hitos[0]?.term_max, 1)} per 1.000 habitants) i el mínim, el {hitos[0]?.anio_term_min} ({formatNumber(hitos[0]?.term_min, 2)}). El {hitos[0]?.anio_ult} se'n van acabar {formatNumber(hitos[0]?.term_ult, 2)} per 1.000 habitants i se'n van començar {formatNumber(hitos[0]?.ini_ult, 2)}.

<LineChart
    data={espana_largo}
    x=anio
    y=por_1000
    series=fase
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="per 1.000 habitants"
    title="Habitatges lliures iniciats i acabats per 1.000 habitants"
/>

Els habitatges acabats es poden comparar amb les compravendes d'habitatge nou que registra l'INE (que inclouen també el protegit):

<LineChart
    data={mercado_largo}
    x=anio
    y=por_1000
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="per 1.000 habitants"
    title="Habitatges acabats i compravendes d'habitatge nou per 1.000 habitants"
/>

## Per comunitat

Habitatges lliures acabats per 1.000 habitants el {ccaa[0]?.anio}.

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="terminadas_1000"
    valueFmt="num2"
    link="ruta"
    colorPalette={['#ecfccb', '#84cc16', '#365314']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: Ministeri d'Habitatge"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'terminadas_1000', title: 'Acabats per 1.000 hab.', fmt: 'num2'},
        {id: 'iniciadas_1000', title: 'Iniciats per 1.000 hab.', fmt: 'num2'},
        {id: 'terminadas', title: 'Acabats', fmt: 'num0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=terminadas_1000 title="Acabats per 1.000 hab." fmt='0.00' />
    <Column id=terminadas_1000_5a title="Mitjana 5 anys" fmt='0.00' />
    <Column id=iniciadas_1000 title="Iniciats per 1.000 hab." fmt='0.00' />
    <Column id=terminadas title="Acabats" fmt='#,##0' />
</DataTable>

## Per província

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Província" />
    <Column id=terminadas_1000 title="Acabats per 1.000 hab." fmt='0.00' />
    <Column id=iniciadas_1000 title="Iniciats per 1.000 hab." fmt='0.00' />
    <Column id=terminadas title="Acabats" fmt='#,##0' />
    <Column id=iniciadas title="Iniciats" fmt='#,##0' />
</DataTable>

---

**Fonts:** [Ministeri d'Habitatge i Agenda Urbana, butlletí estadístic: habitatges lliures iniciats i acabats](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=32000000) (taules 3.1 i 3.2, anuals des del 1991, a partir dels certificats dels col·legis d'aparelladors; la sèrie per habitant comença el 1996, primer any de la població de l'INE) i [INE, Estadística de Transmissions de Drets de la Propietat](https://www.ine.es/jaxiT3/Tabla.htm?t=6150).
