---
title: Inmigración
description: "Población extranjera en España por comunidad y nacionalidad, saldo migratorio, llegadas irregulares por vía, solicitudes de asilo y nacionalizaciones, con datos oficiales."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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

# 🌍 Inmigración

Cuántos extranjeros viven en España, cuántas personas llegan y se van cada año, por dónde entran quienes lo hacen de forma irregular, cuántos piden asilo y cuántos obtienen la nacionalidad.

<Grid cols=4>
    <KpiCard
        title="Residentes extranjeros"
        value={pob_espana.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pob_espana.slice(-1)[0]?.valor, 1)} %"
        period="de la población · {formatCompact(pob_espana.slice(-1)[0]?.extranjeros, 2)} personas a 1 de enero de {pob_espana.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={pob_espana}
    />
    <KpiCard
        title="Saldo migratorio con el extranjero"
        value={flujos.slice(-1)[0]?.saldo_1000}
        formattedValue="+{formatNumber(flujos.slice(-1)[0]?.saldo_1000, 1)} por 1.000 hab."
        period="{formatNumber(flujos.slice(-1)[0]?.saldo, 0)} personas más llegaron que se fueron en {flujos.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={flujos.map(d => ({anio: d.anio, valor: d.saldo_1000}))}
    />
    <KpiCard
        title="Llegadas irregulares"
        value={llegadas_total.filter(d => d.meses === 12).slice(-1)[0]?.valor}
        formattedValue={formatNumber(llegadas_total.filter(d => d.meses === 12).slice(-1)[0]?.valor, 0)}
        period="por mar y tierra en {llegadas_total.filter(d => d.meses === 12).slice(-1)[0]?.anio}"
        source="Interior / ACNUR"
        sparklineData={llegadas_total.filter(d => d.meses === 12)}
    />
    <KpiCard
        title="Nacionalizaciones"
        value={nacionalizaciones.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(nacionalizaciones.slice(-1)[0]?.valor, 0)} por 1.000 extranjeros"
        period="{formatNumber(nacionalizaciones.slice(-1)[0]?.nacionalizaciones, 0)} personas obtuvieron la nacionalidad en {nacionalizaciones.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={nacionalizaciones}
    />
</Grid>

<p class="text-xs text-gray-500">Las cifras que dependen del tamaño de la población se dan por habitante. Las llegadas irregulares y las solicitudes de asilo se dan en número de personas porque son hechos que no crecen con la población de España.</p>

## La población extranjera

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
    title="Residentes extranjeros en % de la población, por origen"
/>

<p class="text-xs text-gray-500">Por nacionalidad a 1 de enero (Estadística Continua de Población). Quien nació fuera y ya tiene la nacionalidad española cuenta como español, así que la población nacida en el extranjero es bastante mayor. Tras la crisis económica el número de extranjeros bajó de 5,4 millones en 2010 a 4,4 millones en 2017; desde entonces crece, sobre todo con latinoamericanos, que han pasado del 2,0 % al 4,9 % de la población.</p>

```sql ccaa
SELECT i.cod, t.nombre AS comunidad, t.ruta, i.extranjeros, i.pct_extranjeros
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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_extranjeros', title: 'Extranjeros', fmt: 'pct1'},
        {id: 'extranjeros', title: 'Personas', fmt: 'num0'}
    ]}
/>

## Quién llega y quién se va

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
    yAxisTitle="por 1.000 habitantes"
    title="Migraciones con el extranjero por 1.000 habitantes (españoles y extranjeros)"
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
        title="Saldo migratorio por nacionalidad (por 1.000 habitantes de España)"
    />
    <BarChart
        data={saldo_paises}
        x=pais
        y=saldo_exterior
        swapXY=true
        sort=false
        yFmt=num0
        fillColor="#14b8a6"
        title="Países con mayor saldo (personas, {flujos.slice(-1)[0]?.anio})"
    />
</Grid>

<p class="text-xs text-gray-500">Saldo = personas que llegan del extranjero menos las que se van a él, en el año. La Estadística de Migraciones y Cambios de Residencia del INE empieza en 2021 con su método actual; 2021 aún estaba afectado por la pandemia. Colombia, Venezuela y Marruecos son las nacionalidades que más aportan.</p>

```sql saldo_ccaa
SELECT s.cod, t.nombre AS comunidad, t.ruta,
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
    <Column id=comunidad title="Comunidad" />
    <Column id=total_1000 title="Saldo por 1.000 hab." fmt=num1 contentType=bar barColor="#99f6e4" />
    <Column id=extranjeros_1000 title="…de extranjeros" fmt=num1 />
    <Column id=espanoles_1000 title="…de españoles" fmt=num1 />
    <Column id=saldo title="Saldo (personas)" fmt=num0 />
</DataTable>

## Llegadas irregulares

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
    title="Llegadas irregulares a España por vía (personas al año)"
/>

<p class="text-xs text-gray-500">Personas llegadas por mar a las costas de la península y Baleares o a Canarias, y por tierra a Ceuta y Melilla fuera de los pasos fronterizos, según el Ministerio del Interior (recopilado por ACNUR). El último año está incompleto. La ruta canaria marcó un récord en 2024 y cayó a menos de la mitad en 2025. Son una parte pequeña de la inmigración: la gran mayoría de quienes llegan a vivir a España lo hacen por aeropuertos y de forma regular (por ejemplo, con visado de estudios o turista y regularizándose después).</p>

## Asilo

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
        title="Primeras solicitudes de asilo por año"
    />
    <BarChart
        data={asilo_nac}
        x=nacionalidad
        y=solicitudes
        swapXY=true
        sort=false
        yFmt=num0
        fillColor="#a78bfa"
        title="Nacionalidades que más asilo piden ({asilo_nac.length > 0 ? 'último año' : ''})"
    />
</Grid>

<p class="text-xs text-gray-500">Primeras solicitudes de protección internacional registradas en España (Eurostat). Pedir asilo no significa obtenerlo: una parte importante se deniega. Venezolanos y colombianos presentan la mayoría de las solicitudes.</p>

## Nacionalizaciones

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
        yAxisTitle="por 1.000 extranjeros residentes"
        title="Nacionalizaciones por 1.000 extranjeros residentes"
    />
    <BarChart
        data={nac_origen}
        x=nacionalidad_previa
        y=nacionalizaciones
        swapXY=true
        sort=false
        yFmt=num0
        fillColor="#14b8a6"
        title="Nacionalidad anterior de quienes se nacionalizaron ({nacionalizaciones.slice(-1)[0]?.anio})"
    />
</Grid>

<p class="text-xs text-gray-500">Adquisiciones de la nacionalidad española por residencia, opción o carta de naturaleza. Los latinoamericanos pueden pedirla tras dos años de residencia legal (frente a diez con carácter general), por eso son la mayoría.</p>

---

## Fuentes y notas

- **[INE – Estadística Continua de Población](https://www.ine.es/jaxiT3/Tabla.htm?t=56942)** (tabla 56942): población por nacionalidad a 1 de enero.
- **[INE – Estadística de Migraciones y Cambios de Residencia](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177000)** (tablas 69687, 69702, 69758 y 69762): inmigraciones, emigraciones y saldos desde 2021.
- **Ministerio del Interior**, informe quincenal de inmigración irregular, a través del **[portal de datos de ACNUR](https://data.unhcr.org/en/situations/europe-sea-arrivals/location/24522)**.
- **[Eurostat – migr_asyappctzm y migr_asyappctza](https://ec.europa.eu/eurostat/databrowser/view/migr_asyappctzm/default/table)**: primeras solicitudes de asilo.
- **[INE – Adquisiciones de nacionalidad española de residentes](https://www.ine.es/jaxiT3/Tabla.htm?t=70012)** (tabla 70012).
- Los datos de criminalidad por nacionalidad están en [Criminalidad](/sociedad/criminalidad), con su contexto.

<LastRefreshed prefix="Datos actualizados" />
