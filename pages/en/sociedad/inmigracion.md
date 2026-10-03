---
title: Immigration
description: "Foreign population in Spain by region and nationality, net migration, irregular arrivals by route, asylum applications and naturalisations, with official data."
i18n_origen: 198ef257d0f8
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
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

# 🌍 Immigration

How many foreign nationals live in Spain, how many people arrive and leave each year, which routes are used by those who arrive irregularly, how many apply for asylum and how many acquire Spanish nationality.

<Grid cols=4>
    <KpiCard
        title="Foreign residents"
        value={pob_espana.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pob_espana.slice(-1)[0]?.valor, 1)} %"
        period="of the population · {formatCompact(pob_espana.slice(-1)[0]?.extranjeros, 2)} people at 1 January {pob_espana.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={pob_espana}
    />
    <KpiCard
        title="Net migration with other countries"
        value={flujos.slice(-1)[0]?.saldo_1000}
        formattedValue="+{formatNumber(flujos.slice(-1)[0]?.saldo_1000, 1)} per 1,000 inhabitants"
        period="{formatNumber(flujos.slice(-1)[0]?.saldo, 0)} more people arrived than left in {flujos.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={flujos.map(d => ({anio: d.anio, valor: d.saldo_1000}))}
    />
    <KpiCard
        title="Irregular arrivals"
        value={llegadas_total.filter(d => d.meses === 12).slice(-1)[0]?.valor}
        formattedValue={formatNumber(llegadas_total.filter(d => d.meses === 12).slice(-1)[0]?.valor, 0)}
        period="by sea and land in {llegadas_total.filter(d => d.meses === 12).slice(-1)[0]?.anio}"
        source="Interior / UNHCR"
        sparklineData={llegadas_total.filter(d => d.meses === 12)}
    />
    <KpiCard
        title="Naturalisations"
        value={nacionalizaciones.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(nacionalizaciones.slice(-1)[0]?.valor, 0)} per 1,000 foreign nationals"
        period="{formatNumber(nacionalizaciones.slice(-1)[0]?.nacionalizaciones, 0)} people acquired Spanish nationality in {nacionalizaciones.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={nacionalizaciones}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('migrantes')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'migrantes')} />


<p class="text-xs text-gray-500">Figures that depend on the size of the population are given per inhabitant. Irregular arrivals and asylum applications are given as numbers of people because they do not grow with Spain's population.</p>

## The foreign population

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
    title="Foreign residents as a % of the population, by origin"
/>

<p class="text-xs text-gray-500">By nationality at 1 January (Continuous Population Statistics). People born abroad who already hold Spanish nationality count as Spanish, so the foreign-born population is considerably larger. After the economic crisis the number of foreign nationals fell from 5.4 million in 2010 to 4.4 million in 2017; since then it has been rising, above all with Latin Americans, who have gone from 2.0 % to 4.9 % of the population.</p>

```sql ccaa
SELECT i.cod, t.nombre AS comunidad, '/en' || t.ruta AS ruta, i.extranjeros, i.pct_extranjeros
FROM mother.inmigracion_poblacion i
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = i.cod
WHERE i.nivel = 'ccaa' AND i.anio = (SELECT max(anio) FROM mother.inmigracion_poblacion)
ORDER BY i.pct_extranjeros DESC
```

<MapaEspana
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
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_extranjeros', title: 'Foreign nationals', fmt: 'pct1'},
        {id: 'extranjeros', title: 'People', fmt: 'num0'}
    ]}
/>

## Who arrives and who leaves

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
    yAxisTitle="per 1,000 inhabitants"
    title="Migration to and from abroad per 1,000 inhabitants (Spanish and foreign nationals)"
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
        title="Net migration by nationality (per 1,000 inhabitants of Spain)"
    />
    <BarChart
        data={saldo_paises}
        x=pais
        y=saldo_exterior
        swapXY=true
        sort=false
        yFmt=num0
        fillColor="#14b8a6"
        title="Countries with the highest net migration (people, {flujos.slice(-1)[0]?.anio})"
    />
</Grid>

<p class="text-xs text-gray-500">Net migration = people arriving from abroad minus those leaving for abroad, during the year. The INE's Migration and Change of Residence Statistics start in 2021 with their current method; 2021 was still affected by the pandemic. Colombia, Venezuela and Morocco are the nationalities that contribute the most.</p>

```sql saldo_ccaa
SELECT s.cod, t.nombre AS comunidad, '/en' || t.ruta AS ruta,
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
    <Column id=comunidad title="Region" />
    <Column id=total_1000 title="Net migration per 1,000 inhabitants" fmt=num1 contentType=bar barColor="#99f6e4" />
    <Column id=extranjeros_1000 title="…of foreign nationals" fmt=num1 />
    <Column id=espanoles_1000 title="…of Spanish nationals" fmt=num1 />
    <Column id=saldo title="Net migration (people)" fmt=num0 />
</DataTable>

## Irregular arrivals

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
    title="Irregular arrivals in Spain by route (people per year)"
/>

<p class="text-xs text-gray-500">People arriving by sea on the coasts of the mainland and the Balearic Islands or in the Canary Islands, and by land in Ceuta and Melilla outside border crossings, according to the Ministry of the Interior (compiled by UNHCR). The latest year is incomplete. The Canary Islands route hit a record in 2024 and fell to less than half that in 2025. These arrivals are a small part of immigration: the vast majority of those who come to live in Spain do so through airports and by regular means (for example, on a student or tourist visa and regularising their status later).</p>

## Asylum

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
        title="First-time asylum applications per year"
    />
    <BarChart
        data={asilo_nac}
        x=nacionalidad
        y=solicitudes
        swapXY=true
        sort=false
        yFmt=num0
        fillColor="#a78bfa"
        title="Nationalities with the most asylum applications ({asilo_nac.length > 0 ? 'latest year' : ''})"
    />
</Grid>

<p class="text-xs text-gray-500">First-time applications for international protection registered in Spain (Eurostat). Applying for asylum does not mean obtaining it: a significant share are rejected. Venezuelans and Colombians submit most of the applications.</p>

## Naturalisations

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
        yAxisTitle="per 1,000 foreign residents"
        title="Naturalisations per 1,000 foreign residents"
    />
    <BarChart
        data={nac_origen}
        x=nacionalidad_previa
        y=nacionalizaciones
        swapXY=true
        sort=false
        yFmt=num0
        fillColor="#14b8a6"
        title="Previous nationality of those naturalised ({nacionalizaciones.slice(-1)[0]?.anio})"
    />
</Grid>

<p class="text-xs text-gray-500">Acquisitions of Spanish nationality by residence, option or naturalisation letter (carta de naturaleza). Latin Americans can apply after two years of legal residence (compared with ten as a general rule), which is why they are the majority.</p>

---

## Sources and notes

- **[INE – Continuous Population Statistics](https://www.ine.es/jaxiT3/Tabla.htm?t=56942)** (table 56942): population by nationality at 1 January.
- **[INE – Migration and Change of Residence Statistics](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177000)** (tables 69687, 69702, 69758 and 69762): immigration, emigration and net migration since 2021.
- **Ministry of the Interior**, fortnightly report on irregular immigration, via the **[UNHCR data portal](https://data.unhcr.org/en/situations/europe-sea-arrivals/location/24522)**.
- **[Eurostat – migr_asyappctzm and migr_asyappctza](https://ec.europa.eu/eurostat/databrowser/view/migr_asyappctzm/default/table)**: first-time asylum applications.
- **[INE – Acquisitions of Spanish nationality by residents](https://www.ine.es/jaxiT3/Tabla.htm?t=70012)** (table 70012).
- Crime data by nationality can be found in [Crime](/en/sociedad/criminalidad), with context.

<LastRefreshed prefix="Data updated" />
