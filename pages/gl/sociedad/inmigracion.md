---
title: Inmigración
description: "Poboación estranxeira en España por comunidade e nacionalidade, saldo migratorio, chegadas irregulares por vía, solicitudes de asilo e nacionalizacións, con datos oficiais."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 198ef257d0f8
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

# 🌍 Inmigración

Cantos estranxeiros viven en España, cantas persoas chegan e se van cada ano, por onde entran quen o fan de forma irregular, cantos piden asilo e cantos obteñen a nacionalidade.

<Grid cols=4>
    <KpiCard
        title="Residentes estranxeiros"
        value={pob_espana.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pob_espana.slice(-1)[0]?.valor, 1)} %"
        period="da poboación · {formatCompact(pob_espana.slice(-1)[0]?.extranjeros, 2)} persoas a 1 de xaneiro de {pob_espana.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={pob_espana}
    />
    <KpiCard
        title="Saldo migratorio co estranxeiro"
        value={flujos.slice(-1)[0]?.saldo_1000}
        formattedValue="+{formatNumber(flujos.slice(-1)[0]?.saldo_1000, 1)} por 1.000 hab."
        period="{formatNumber(flujos.slice(-1)[0]?.saldo, 0)} persoas máis chegaron das que se foron en {flujos.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={flujos.map(d => ({anio: d.anio, valor: d.saldo_1000}))}
    />
    <KpiCard
        title="Chegadas irregulares"
        value={llegadas_total.filter(d => d.meses === 12).slice(-1)[0]?.valor}
        formattedValue={formatNumber(llegadas_total.filter(d => d.meses === 12).slice(-1)[0]?.valor, 0)}
        period="por mar e terra en {llegadas_total.filter(d => d.meses === 12).slice(-1)[0]?.anio}"
        source="Interior / ACNUR"
        sparklineData={llegadas_total.filter(d => d.meses === 12)}
    />
    <KpiCard
        title="Nacionalizacións"
        value={nacionalizaciones.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(nacionalizaciones.slice(-1)[0]?.valor, 0)} por 1.000 estranxeiros"
        period="{formatNumber(nacionalizaciones.slice(-1)[0]?.nacionalizaciones, 0)} persoas obtiveron a nacionalidade en {nacionalizaciones.slice(-1)[0]?.anio}"
        source="INE"
        sparklineData={nacionalizaciones}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('migrantes')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'migrantes')} />


<p class="text-xs text-gray-500">As cifras que dependen do tamaño da poboación danse por habitante. As chegadas irregulares e as solicitudes de asilo danse en número de persoas porque son feitos que non medran coa poboación de España.</p>

## A poboación estranxeira

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
    title="Residentes estranxeiros en % da poboación, por orixe"
/>

<p class="text-xs text-gray-500">Por nacionalidade a 1 de xaneiro (Estatística Continua de Poboación). Quen naceu fóra e xa ten a nacionalidade española conta como español, así que a poboación nacida no estranxeiro é bastante maior. Tras a crise económica o número de estranxeiros baixou de 5,4 millóns en 2010 a 4,4 millóns en 2017; desde entón medra, sobre todo con latinoamericanos, que pasaron do 2,0 % ao 4,9 % da poboación.</p>

```sql ccaa
SELECT i.cod, t.nombre AS comunidad, '/gl' || t.ruta AS ruta, i.extranjeros, i.pct_extranjeros
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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_extranjeros', title: 'Estranxeiros', fmt: 'pct1'},
        {id: 'extranjeros', title: 'Persoas', fmt: 'num0'}
    ]}
/>

## Quen chega e quen se vai

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
    title="Migracións co estranxeiro por 1.000 habitantes (españois e estranxeiros)"
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
        title="Saldo migratorio por nacionalidade (por 1.000 habitantes de España)"
    />
    <BarChart
        data={saldo_paises}
        x=pais
        y=saldo_exterior
        swapXY=true
        sort=false
        yFmt=num0
        fillColor="#14b8a6"
        title="Países con maior saldo (persoas, {flujos.slice(-1)[0]?.anio})"
    />
</Grid>

<p class="text-xs text-gray-500">Saldo = persoas que chegan do estranxeiro menos as que se van a el, no ano. A Estatística de Migracións e Cambios de Residencia do INE comeza en 2021 co seu método actual; 2021 aínda estaba afectado pola pandemia. Colombia, Venezuela e Marrocos son as nacionalidades que máis achegan.</p>

```sql saldo_ccaa
SELECT s.cod, t.nombre AS comunidad, '/gl' || t.ruta AS ruta,
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
    <Column id=comunidad title="Comunidade" />
    <Column id=total_1000 title="Saldo por 1.000 hab." fmt=num1 contentType=bar barColor="#99f6e4" />
    <Column id=extranjeros_1000 title="…de estranxeiros" fmt=num1 />
    <Column id=espanoles_1000 title="…de españois" fmt=num1 />
    <Column id=saldo title="Saldo (persoas)" fmt=num0 />
</DataTable>

## Chegadas irregulares

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
    title="Chegadas irregulares a España por vía (persoas ao ano)"
/>

<p class="text-xs text-gray-500">Persoas chegadas por mar ás costas da península e Baleares ou a Canarias, e por terra a Ceuta e Melilla fóra dos pasos fronteirizos, segundo o Ministerio do Interior (recompilado por ACNUR). O último ano está incompleto. A ruta canaria marcou un récord en 2024 e caeu a menos da metade en 2025. Son unha parte pequena da inmigración: a gran maioría de quen chega a vivir a España faino por aeroportos e de forma regular (por exemplo, con visado de estudos ou turista e regularizándose despois).</p>

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
        title="Primeiras solicitudes de asilo por ano"
    />
    <BarChart
        data={asilo_nac}
        x=nacionalidad
        y=solicitudes
        swapXY=true
        sort=false
        yFmt=num0
        fillColor="#a78bfa"
        title="Nacionalidades que máis asilo piden ({asilo_nac.length > 0 ? 'último ano' : ''})"
    />
</Grid>

<p class="text-xs text-gray-500">Primeiras solicitudes de protección internacional rexistradas en España (Eurostat). Pedir asilo non significa obtelo: unha parte importante deségase. Venezolanos e colombianos presentan a maioría das solicitudes.</p>

## Nacionalizacións

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
        yAxisTitle="por 1.000 estranxeiros residentes"
        title="Nacionalizacións por 1.000 estranxeiros residentes"
    />
    <BarChart
        data={nac_origen}
        x=nacionalidad_previa
        y=nacionalizaciones
        swapXY=true
        sort=false
        yFmt=num0
        fillColor="#14b8a6"
        title="Nacionalidade anterior de quen se nacionalizou ({nacionalizaciones.slice(-1)[0]?.anio})"
    />
</Grid>

<p class="text-xs text-gray-500">Adquisicións da nacionalidade española por residencia, opción ou carta de natureza. Os latinoamericanos poden pedila tras dous anos de residencia legal (fronte a dez con carácter xeral), por iso son a maioría.</p>

---

## Fontes e notas

- **[INE – Estatística Continua de Poboación](https://www.ine.es/jaxiT3/Tabla.htm?t=56942)** (táboa 56942): poboación por nacionalidade a 1 de xaneiro.
- **[INE – Estatística de Migracións e Cambios de Residencia](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177000)** (táboas 69687, 69702, 69758 e 69762): inmigracións, emigracións e saldos desde 2021.
- **Ministerio do Interior**, informe quincenal de inmigración irregular, a través do **[portal de datos de ACNUR](https://data.unhcr.org/en/situations/europe-sea-arrivals/location/24522)**.
- **[Eurostat – migr_asyappctzm e migr_asyappctza](https://ec.europa.eu/eurostat/databrowser/view/migr_asyappctzm/default/table)**: primeiras solicitudes de asilo.
- **[INE – Adquisicións de nacionalidade española de residentes](https://www.ine.es/jaxiT3/Tabla.htm?t=70012)** (táboa 70012).
- Os datos de criminalidade por nacionalidade están en [Criminalidade](/gl/sociedad/criminalidad), co seu contexto.

<LastRefreshed prefix="Datos actualizados" />
