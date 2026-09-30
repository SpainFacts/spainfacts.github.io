---
title: Immigració
description: "Població estrangera a Espanya per comunitat i nacionalitat, saldo migratori, arribades irregulars per via, sol·licituds d'asil i nacionalitzacions, amb dades oficials."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 4dc4692f98aa
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql pob_espana
SELECT anio, extranjeros, poblacion, 100 * pct_extranjeros AS valor
FROM mother.inmigracion_poblacion
WHERE nivel = 'pais'
ORDER BY anio
```

```sql flujos
SELECT * FROM mother.inmigracion_flujos_anuales ORDER BY anio
```

```sql llegadas_anual
SELECT CAST(year(mes) AS INTEGER) AS anio, via, sum(personas) AS personas, count(DISTINCT mes) AS meses
FROM mother.inmigracion_llegadas
GROUP BY ALL
ORDER BY anio
```

```sql llegadas_total
SELECT anio, sum(personas) AS valor, max(meses) AS meses
FROM ${llegadas_anual}
GROUP BY anio
ORDER BY anio
```

```sql asilo_anual
SELECT CAST(year(mes) AS INTEGER) AS anio, sum(solicitudes) AS valor, count(*) AS meses
FROM mother.inmigracion_asilo
GROUP BY 1
ORDER BY 1
```

```sql nacionalizaciones
SELECT anio, nacionalizaciones, por_1000_extranjeros AS valor
FROM mother.inmigracion_nacionalizaciones
WHERE cod = '00' AND nacionalidad_previa = 'Total'
ORDER BY anio
```

# 🌍 Immigració

Quants estrangers viuen a Espanya, quantes persones arriben i se'n van cada any, per on entren els qui ho fan de manera irregular, quants demanen asil i quants obtenen la nacionalitat.

<Grid cols=4>
    <KpiCard
        title="Residents estrangers"
        value={pob_espana.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pob_espana.slice(-1)[0]?.valor, 1)} %"
        period="de la població · {formatCompact(pob_espana.slice(-1)[0]?.extranjeros, 2)} persones a 1 de gener de {pob_espana.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={pob_espana}
    />
    <KpiCard
        title="Saldo migratori amb l'estranger"
        value={flujos.slice(-1)[0]?.saldo_1000}
        formattedValue="+{formatNumber(flujos.slice(-1)[0]?.saldo_1000, 1)} per 1.000 hab."
        period="{formatNumber(flujos.slice(-1)[0]?.saldo, 0)} persones més van arribar que no pas van marxar el {flujos.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={flujos.map(d => ({anio: d.anio, valor: d.saldo_1000}))}
    />
    <KpiCard
        title="Arribades irregulars"
        value={llegadas_total.filter(d => d.meses === 12).slice(-1)[0]?.valor}
        formattedValue={formatNumber(llegadas_total.filter(d => d.meses === 12).slice(-1)[0]?.valor, 0)}
        period="per mar i per terra el {llegadas_total.filter(d => d.meses === 12).slice(-1)[0]?.anio}"
        source="Interior / ACNUR"
        sparklineData={llegadas_total.filter(d => d.meses === 12)}
    />
    <KpiCard
        title="Nacionalitzacions"
        value={nacionalizaciones.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(nacionalizaciones.slice(-1)[0]?.valor, 0)} per 1.000 estrangers"
        period="{formatNumber(nacionalizaciones.slice(-1)[0]?.nacionalizaciones, 0)} persones van obtenir la nacionalitat el {nacionalizaciones.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={nacionalizaciones}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('migrantes')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'migrantes')} />


<p class="text-xs text-gray-500">Les xifres que depenen de la mida de la població es donen per habitant. Les arribades irregulars i les sol·licituds d'asil es donen en nombre de persones perquè són fets que no creixen amb la població d'Espanya.</p>

## La població estrangera

```sql grupos
SELECT anio, grupo, personas / poblacion AS cuota
FROM (
    SELECT anio, poblacion,
        unnest(['Unión Europea', 'Resto de Europa', 'África', 'Latinoamérica', 'Asia', 'América del Norte']) AS grupo,
        unnest([ue, resto_europa, africa, centroamerica_caribe + sudamerica, asia, america_norte]) AS personas
    FROM mother.inmigracion_poblacion
    WHERE nivel = 'pais'
)
ORDER BY anio
```

<BarChart
    data={grupos}
    x=anio
    y=cuota
    series=grupo
    type=stacked
    yFmt=pct0
    xFmt="####"
    colorPalette={['#1d4ed8', '#60a5fa', '#b45309', '#0f766e', '#a21caf', '#94a3b8']}
    title="Residents estrangers en % de la població, per origen"
/>

<p class="text-xs text-gray-500">Per nacionalitat a 1 de gener (Estadística Contínua de Població). Qui va néixer fora i ja té la nacionalitat espanyola compta com a espanyol, de manera que la població nascuda a l'estranger és força més gran. Després de la crisi econòmica el nombre d'estrangers va baixar de 5,4 milions el 2010 a 4,4 milions el 2017; des d'aleshores creix, sobretot amb llatinoamericans, que han passat del 2,0 % al 4,9 % de la població.</p>

```sql ccaa
SELECT i.cod, t.nombre AS comunidad, '/ca' || t.ruta AS ruta, i.extranjeros, i.pct_extranjeros
FROM mother.inmigracion_poblacion i
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = i.cod
WHERE i.nivel = 'ccaa' AND i.anio = (SELECT max(anio) FROM mother.inmigracion_poblacion)
ORDER BY i.pct_extranjeros DESC
```

<AreaMap
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="pct_extranjeros"
    valueFmt="pct1"
    link="ruta"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_extranjeros', title: 'Estrangers', fmt: 'pct1'},
        {id: 'extranjeros', title: 'Persones', fmt: 'num0'}
    ]}
/>

## Qui arriba i qui se'n va

```sql flujos_grafico
SELECT anio, 'Llegadas desde el extranjero' AS flujo, inmigraciones_1000 AS por_1000 FROM ${flujos}
UNION ALL
SELECT anio, 'Salidas al extranjero', emigraciones_1000 FROM ${flujos}
ORDER BY anio
```

<BarChart
    data={flujos_grafico}
    x=anio
    y=por_1000
    series=flujo
    type=grouped
    yFmt=num1
    xFmt="####"
    colorPalette={['#0f766e', '#94a3b8']}
    yAxisTitle="per 1.000 habitants"
    title="Migracions amb l'estranger per 1.000 habitants (espanyols i estrangers)"
/>

```sql saldo_origen
SELECT nacionalidad, saldo_exterior, saldo_1000
FROM mother.inmigracion_saldos
WHERE nivel = 'pais' AND anio = (SELECT max(anio) FROM mother.inmigracion_saldos)
  AND nacionalidad IN ('Española', 'UE27_2020 sin España', 'Europa menos UE27_2020', 'África', 'América del Norte',
                       'Centro América y Caribe', 'Sudamérica', 'Asia')
ORDER BY saldo_1000 DESC
```

```sql saldo_paises
SELECT nacionalidad AS pais, saldo_exterior
FROM mother.inmigracion_saldos
WHERE nivel = 'pais' AND NOT es_grupo AND anio = (SELECT max(anio) FROM mother.inmigracion_saldos)
ORDER BY saldo_exterior DESC
LIMIT 12
```

<Grid cols=2>
    <BarChart
        data={saldo_origen}
        x=nacionalidad
        y=saldo_1000
        swapXY=true
        sort=false
        yFmt=num1
        fillColor="#0f766e"
        title="Saldo migratori per nacionalitat (per 1.000 habitants d'Espanya)"
    />
    <BarChart
        data={saldo_paises}
        x=pais
        y=saldo_exterior
        swapXY=true
        sort=false
        yFmt=num0
        fillColor="#14b8a6"
        title="Països amb més saldo (persones, {flujos.slice(-1)[0]?.anio})"
    />
</Grid>

<p class="text-xs text-gray-500">Saldo = persones que arriben de l'estranger menys les que hi marxen, en l'any. L'Estadística de Migracions i Canvis de Residència de l'INE comença el 2021 amb el mètode actual; el 2021 encara estava afectat per la pandèmia. Colòmbia, Veneçuela i el Marroc són les nacionalitats que més hi aporten.</p>

```sql saldo_ccaa
SELECT s.cod, t.nombre AS comunidad, '/ca' || t.ruta AS ruta,
    max(s.saldo_1000) FILTER (WHERE s.nacionalidad = 'Total') AS total_1000,
    max(s.saldo_1000) FILTER (WHERE s.nacionalidad = 'Extranjera') AS extranjeros_1000,
    max(s.saldo_1000) FILTER (WHERE s.nacionalidad = 'Española') AS espanoles_1000,
    max(s.saldo_exterior) FILTER (WHERE s.nacionalidad = 'Total') AS saldo
FROM mother.inmigracion_saldos s
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = s.cod
WHERE s.nivel = 'ccaa' AND s.anio = (SELECT max(anio) FROM mother.inmigracion_saldos)
GROUP BY ALL
ORDER BY total_1000 DESC
```

<DataTable data={saldo_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=total_1000 title="Saldo per 1.000 hab." fmt=num1 contentType=bar barColor="#99f6e4" />
    <Column id=extranjeros_1000 title="…d'estrangers" fmt=num1 />
    <Column id=espanoles_1000 title="…d'espanyols" fmt=num1 />
    <Column id=saldo title="Saldo (persones)" fmt=num0 />
</DataTable>

## Arribades irregulars

```sql llegadas_mes
SELECT mes, via, personas FROM mother.inmigracion_llegadas ORDER BY mes
```

<BarChart
    data={llegadas_anual}
    x=anio
    y=personas
    series=via
    type=stacked
    yFmt=num0
    xFmt="####"
    colorPalette={['#0f766e', '#1d4ed8', '#b45309']}
    title="Arribades irregulars a Espanya per via (persones l'any)"
/>

<p class="text-xs text-gray-500">Persones arribades per mar a les costes de la península i les Balears o a les Canàries, i per terra a Ceuta i Melilla fora dels passos fronterers, segons el Ministeri de l'Interior (recopilat per l'ACNUR). L'últim any és incomplet. La ruta canària va marcar un rècord el 2024 i va caure a menys de la meitat el 2025. Són una part petita de la immigració: la gran majoria dels qui arriben a viure a Espanya ho fan per aeroports i de manera regular (per exemple, amb visat d'estudis o de turista i regularitzant-se després).</p>

## Asil

```sql asilo_nac
SELECT nacionalidad, solicitudes
FROM mother.inmigracion_asilo_nacionalidad
WHERE anio = (SELECT max(anio) FROM mother.inmigracion_asilo_nacionalidad)
ORDER BY solicitudes DESC
LIMIT 10
```

<Grid cols=2>
    <BarChart
        data={asilo_anual.filter(d => d.meses === 12)}
        x=anio
        y=valor
        yFmt=num0
        xFmt="####"
        fillColor="#7c3aed"
        title="Primeres sol·licituds d'asil per any"
    />
    <BarChart
        data={asilo_nac}
        x=nacionalidad
        y=solicitudes
        swapXY=true
        sort=false
        yFmt=num0
        fillColor="#a78bfa"
        title="Nacionalitats que més asil demanen ({asilo_nac.length > 0 ? 'últim any' : ''})"
    />
</Grid>

<p class="text-xs text-gray-500">Primeres sol·licituds de protecció internacional registrades a Espanya (Eurostat). Demanar asil no vol dir obtenir-lo: una part important es denega. Veneçolans i colombians presenten la majoria de les sol·licituds.</p>

## Nacionalitzacions

```sql nac_origen
SELECT nacionalidad_previa, nacionalizaciones
FROM mother.inmigracion_nacionalizaciones
WHERE cod = '00' AND anio = (SELECT max(anio) FROM mother.inmigracion_nacionalizaciones)
  AND nacionalidad_previa NOT IN ('Total', 'País de la UE27_2020 sin España', 'País de la UE28 sin España')
  AND nacionalidad_previa NOT LIKE 'De %' AND nacionalidad_previa NOT LIKE 'Resto%' AND nacionalidad_previa NOT LIKE 'País de%' AND nacionalidad_previa NOT LIKE 'Otros%'
ORDER BY nacionalizaciones DESC
LIMIT 12
```

<Grid cols=2>
    <LineChart
        data={nacionalizaciones}
        x=anio
        y=valor
        yFmt=num1
        xFmt="####"
        lineColor="#0f766e"
        yAxisTitle="per 1.000 estrangers residents"
        title="Nacionalitzacions per 1.000 estrangers residents"
    />
    <BarChart
        data={nac_origen}
        x=nacionalidad_previa
        y=nacionalizaciones
        swapXY=true
        sort=false
        yFmt=num0
        fillColor="#14b8a6"
        title="Nacionalitat anterior dels qui es van nacionalitzar ({nacionalizaciones.slice(-1)[0]?.anio})"
    />
</Grid>

<p class="text-xs text-gray-500">Adquisicions de la nacionalitat espanyola per residència, opció o carta de naturalesa. Els llatinoamericans la poden demanar després de dos anys de residència legal (davant de deu amb caràcter general), per això en són la majoria.</p>

---

## Fonts i notes

- **[INE – Estadística Contínua de Població](https://www.ine.es/jaxiT3/Tabla.htm?t=56942)** (taula 56942): població per nacionalitat a 1 de gener.
- **[INE – Estadística de Migracions i Canvis de Residència](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177000)** (taules 69687, 69702, 69758 i 69762): immigracions, emigracions i saldos des del 2021.
- **Ministeri de l'Interior**, informe quinzenal d'immigració irregular, a través del **[portal de dades de l'ACNUR](https://data.unhcr.org/en/situations/europe-sea-arrivals/location/24522)**.
- **[Eurostat – migr_asyappctzm i migr_asyappctza](https://ec.europa.eu/eurostat/databrowser/view/migr_asyappctzm/default/table)**: primeres sol·licituds d'asil.
- **[INE – Adquisicions de nacionalitat espanyola de residents](https://www.ine.es/jaxiT3/Tabla.htm?t=70012)** (taula 70012).
- Les dades de criminalitat per nacionalitat són a [Criminalitat](/ca/sociedad/criminalidad), amb el seu context.

<LastRefreshed prefix="Dades actualitzades" />
