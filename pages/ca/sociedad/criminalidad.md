---
title: Criminalitat
description: "Delictes coneguts a Espanya per tipus, comunitat, província i municipi des de 2010, evolució de la cibercriminalitat i condemnats per nacionalitat amb el seu context."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 7a9a98e7cc4a
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT anio, categoria, infracciones, tasa_1000
FROM mother.crimen_balance
WHERE nivel = 'pais'
ORDER BY anio
```

```sql resumen
WITH u AS (SELECT max(anio) AS anio FROM ${espana})
SELECT
    u.anio,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Total infracciones penales' AND e.anio = u.anio) AS total,
    max(e.tasa_1000) FILTER (WHERE e.categoria = 'Total infracciones penales' AND e.anio = u.anio) AS tasa,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Total infracciones penales' AND e.anio = 2019) AS total_2019,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Homicidios y asesinatos consumados' AND e.anio = u.anio) AS homicidios,
    max(e.tasa_1000) FILTER (WHERE e.categoria = 'Homicidios y asesinatos consumados' AND e.anio = u.anio) * 100 AS homicidios_100k,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Cibercriminalidad' AND e.anio = u.anio) AS ciber
FROM ${espana} e, u
GROUP BY u.anio
```

```sql serie_kpi
-- Historia para los sparklines, en tasa por 1.000 habitantes: Balance (2019-) y, antes, la serie larga (2010-2018)
WITH b AS (
    SELECT anio, categoria, tasa_1000
    FROM mother.crimen_balance
    WHERE nivel = 'pais' AND categoria IN ('Total infracciones penales', 'Homicidios y asesinatos consumados')
),
l AS (
    SELECT
        anio,
        CASE WHEN tipologia = 'TOTAL INFRACCIONES PENALES' THEN 'Total infracciones penales' ELSE 'Homicidios y asesinatos consumados' END AS categoria,
        max(tasa_1000) AS tasa_1000
    FROM mother.crimen_serie_larga
    WHERE nivel = 'pais' AND (tipologia = 'TOTAL INFRACCIONES PENALES' OR codigo_tipologia = '1.1.1')
    GROUP BY 1, 2
)
SELECT anio, categoria, tasa_1000 FROM b
UNION ALL
SELECT anio, categoria, tasa_1000 FROM l WHERE anio < (SELECT min(anio) FROM b)
ORDER BY categoria, anio
```

```sql semestre
SELECT periodo, anio, infracciones, infracciones_anio_anterior, variacion_pct / 100 AS variacion
FROM mother.crimen_ultimo_periodo
WHERE nivel = 'pais' AND categoria = 'Total infracciones penales'
```

# 🚨 Criminalitat

Els delictes que coneixen la Policia Nacional, la Guàrdia Civil, els Mossos d'Esquadra, l'Ertzaintza, la Policia Foral de Navarra i les policies locals, segons el Ministeri de l'Interior.

<Grid cols=4>
    <KpiCard
        title="Infraccions penals conegudes"
        value={resumen[0]?.total}
        formattedValue="{formatNumber(resumen[0]?.tasa, 1)} per 1.000 hab."
        period="{formatCompact(resumen[0]?.total, 2)} en total · {resumen[0]?.anio}"
        change={resumen[0]?.total_2019 ? (100 * (resumen[0].total / resumen[0].total_2019 - 1)).toFixed(1) : null}
        changeUnit=" %"
        changePeriod="vs. 2019"
        direction="positive-down"
        source="Ministeri de l'Interior"
        sparklineData={serie_kpi.filter(d => d.categoria === 'Total infracciones penales').map(d => ({...d, y: d.tasa_1000}))}
    />
    <KpiCard
        title="Homicidis i assassinats"
        value={resumen[0]?.homicidios}
        formattedValue="{formatNumber(resumen[0]?.homicidios_100k, 2)} per 100.000 hab."
        period="{formatNumber(resumen[0]?.homicidios, 0)} consumats el {resumen[0]?.anio}"
        source="Ministeri de l'Interior"
        sparklineData={serie_kpi.filter(d => d.categoria === 'Homicidios y asesinatos consumados').map(d => ({...d, y: d.tasa_1000 * 100}))}
    />
    <KpiCard
        title="Cibercriminalitat"
        value={resumen[0]?.ciber}
        formattedValue="{formatNumber(resumen[0]?.ciber / resumen[0]?.total / 0.01, 0)} %"
        period="{formatNumber(resumen[0]?.ciber / 1000, 0)} mil infraccions per internet, sobretot estafes"
        source="Ministeri de l'Interior"
        sparklineData={espana.filter(d => d.categoria === 'Cibercriminalidad').map(d => 100 * d.infracciones / (espana.find(t => t.anio === d.anio && t.categoria === 'Total infracciones penales')?.infracciones ?? NaN)).filter(v => Number.isFinite(v))}
    />
    <KpiCard
        title="Aquest any ({semestre[0]?.periodo})"
        value={semestre[0]?.infracciones}
        formattedValue={formatCompact(semestre[0]?.infracciones, 2)}
        change={semestre[0]?.variacion != null ? (100 * semestre[0].variacion).toFixed(1) : null}
        changeUnit=" %"
        changePeriod="vs. el mateix període de {semestre[0]?.anio - 1}"
        direction="positive-down"
        source="Balanç de Criminalitat"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('homicidios')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'homicidios')} />


<p class="text-xs text-gray-500">Totes les xifres es donen per habitant perquè l'evolució no reflecteixi només el creixement de la població (Espanya va guanyar uns 2 milions d'habitants entre 2019 i 2025); el total apareix com a dada secundària. Són fets <b>coneguts</b> (denunciats o descoberts per la policia), no tots els delictes comesos: una pujada pot ser deguda al fet que es denuncia més (com ha passat amb els delictes sexuals o les estafes per internet). La taxa per habitant no té en compte els turistes i visitants, que també pateixen i cometen delictes: per això surt alta a les zones més turístiques.</p>

## Quins delictes i com evolucionen

```sql categorias
SELECT categoria, infracciones, tasa_1000 * 100 AS tasa_100k
FROM ${espana}
WHERE anio = (SELECT max(anio) FROM ${espana})
  AND categoria NOT IN ('Total infracciones penales', 'Criminalidad convencional', 'Cibercriminalidad', 'Resto de infracciones',
                        'Robos con fuerza en domicilios', 'Delitos contra la libertad sexual')
ORDER BY infracciones DESC
```

<BarChart
    data={categorias}
    x=categoria
    y=tasa_100k
    swapXY=true
    sort=false
    yFmt=num0
    yAxisTitle="per 100.000 habitants"
    fillColor="#b91c1c"
    title="Principals delictes coneguts el {resumen[0]?.anio}, per 100.000 habitants"
/>

```sql convencional_ciber
SELECT anio, categoria, infracciones, tasa_1000
FROM ${espana}
WHERE categoria IN ('Criminalidad convencional', 'Cibercriminalidad')
ORDER BY anio
```

<BarChart
    data={convencional_ciber}
    x=anio
    y=tasa_1000
    series=categoria
    type=stacked
    yFmt=num1
    yAxisTitle="per 1.000 habitants"
    xFmt="####"
    colorPalette={['#b91c1c', '#7c3aed']}
    title="Criminalitat convencional i per internet, per 1.000 habitants"
/>

<p class="text-xs text-gray-500">El 2020 és l'any del confinament. Des del 2019 el Ministeri compta a part la cibercriminalitat (estafes i altres delictes comesos per internet), que ha crescut molt més que la resta.</p>

```sql serie_larga
SELECT anio, tipologia, infracciones, tasa_1000 * 100 AS tasa_100k
FROM mother.crimen_serie_larga
WHERE nivel = 'pais' AND codigo_tipologia IN ('1.1.1', '3.2', '5.1', '5.2.2', '5.3', '5.5.1', '6.1')
ORDER BY anio
```

<LineChart
    data={serie_larga}
    x=anio
    y=tasa_100k
    series=tipologia
    yFmt=num1
    yAxisTitle="per 100.000 habitants"
    xFmt="####"
    yLog=true
    legend=true
    title="Alguns delictes des de 2010 per 100.000 habitants (escala logarítmica)"
/>

<p class="text-xs text-gray-500">Escala logarítmica per veure junts delictes molt diferents en nombre: un mateix pendent és un mateix ritme de creixement. Les estafes informàtiques s'han multiplicat des del 2016, els robatoris en habitatges han baixat i les agressions sexuals amb penetració conegudes han augmentat, en part perquè es denuncien més.</p>

## Espanya a Europa i al món

```sql mundo_ultimo
WITH u AS (
    SELECT delito_id, cod_pais, max(anio) AS anio
    FROM mother.crimen_mundo_delitos
    WHERE anio >= (SELECT max(anio) FROM mother.crimen_mundo_delitos) - 6
    GROUP BY ALL
)
SELECT m.*
FROM mother.crimen_mundo_delitos m
JOIN u USING (delito_id, cod_pais, anio)
```

```sql mundo_espana
WITH r AS (
    SELECT *, rank() OVER (PARTITION BY delito_id ORDER BY por_100k_hab) AS puesto_mundo,
           count(*) OVER (PARTITION BY delito_id) AS paises_mundo
    FROM ${mundo_ultimo}
),
e AS (
    SELECT delito_id, cod_pais, rank() OVER (PARTITION BY delito_id ORDER BY por_100k_hab) AS puesto_ue,
           count(*) OVER (PARTITION BY delito_id) AS paises_ue
    FROM ${mundo_ultimo}
    WHERE es_ue
),
m AS (
    SELECT delito_id,
           median(por_100k_hab) FILTER (WHERE es_ue) AS mediana_ue,
           median(por_100k_hab) FILTER (WHERE es_ocde) AS mediana_ocde
    FROM ${mundo_ultimo}
    GROUP BY delito_id
)
SELECT r.delito, r.orden, r.anio, r.por_100k_hab AS espana, m.mediana_ue, m.mediana_ocde,
       r.por_100k_hab / m.mediana_ue AS veces_ue,
       e.puesto_ue, e.paises_ue, r.puesto_mundo, r.paises_mundo,
       e.puesto_ue || ' de ' || e.paises_ue AS puesto_ue_texto,
       r.puesto_mundo || ' de ' || r.paises_mundo AS puesto_mundo_texto
FROM r
JOIN e USING (delito_id, cod_pais)
JOIN m USING (delito_id)
WHERE r.cod_pais = 'ES'
ORDER BY r.orden
```

```sql mundo_resumen
SELECT
    max(espana) FILTER (WHERE orden = 1) AS homicidios,
    max(anio) FILTER (WHERE orden = 1) AS homicidios_anio,
    max(mediana_ue) FILTER (WHERE orden = 1) AS homicidios_ue,
    max(puesto_mundo) FILTER (WHERE orden = 1) AS homicidios_puesto,
    max(paises_mundo) FILTER (WHERE orden = 1) AS homicidios_paises,
    max(puesto_ue) FILTER (WHERE orden = 1) AS homicidios_puesto_ue,
    max(espana) FILTER (WHERE orden = 16) AS presos,
    max(mediana_ue) FILTER (WHERE orden = 16) AS presos_ue,
    count(*) FILTER (WHERE veces_ue < 1 AND orden NOT IN (1, 16)) AS por_debajo,
    count(*) FILTER (WHERE veces_ue >= 1 AND orden NOT IN (1, 16)) AS por_encima
FROM ${mundo_espana}
```

```sql delitos_lista
SELECT DISTINCT delito, orden FROM ${mundo_ultimo} ORDER BY orden
```

```sql mundo_ranking
SELECT pais, por_100k_hab, anio,
       CASE WHEN cod_pais = 'ES' THEN 'España' ELSE 'Otros países' END AS grupo
FROM ${mundo_ultimo}
WHERE delito = '${inputs.delito_mundo.value}' AND (es_europa OR es_ocde)
ORDER BY por_100k_hab DESC
```

```sql mundo_serie
SELECT pais, anio, por_100k_hab
FROM mother.crimen_mundo_delitos
WHERE delito = '${inputs.delito_mundo.value}'
  AND cod_pais IN ('ES', 'FR', 'DE', 'IT', 'PT', 'GB', 'US', 'SE')
  AND anio >= 2005
ORDER BY anio
```

En homicidis, que és la xifra que millor es compara entre països, Espanya és entre els països amb menys casos del món: {formatNumber(mundo_resumen[0]?.homicidios, 1)} per cada 100.000 habitants el {mundo_resumen[0]?.homicidios_anio} (mediana de la UE: {formatNumber(mundo_resumen[0]?.homicidios_ue, 1)}), el lloc {mundo_resumen[0]?.homicidios_puesto} entre {mundo_resumen[0]?.homicidios_paises} països i el {mundo_resumen[0]?.homicidios_puesto_ue} de la UE començant pel més baix. En els altres delictes que registra la policia, Espanya és per sota de la mediana de la UE en {mundo_resumen[0]?.por_debajo} i per sobre en {mundo_resumen[0]?.por_encima}. Té {formatNumber(mundo_resumen[0]?.presos, 0)} presos per cada 100.000 habitants (mediana de la UE: {formatNumber(mundo_resumen[0]?.presos_ue, 0)}).

<DataTable data={mundo_espana} rows=all>
    <Column id=delito title="Delicte" />
    <Column id=anio title="Any" fmt="####" />
    <Column id=espana title="Espanya" fmt=num1 />
    <Column id=mediana_ue title="Mediana UE" fmt=num1 />
    <Column id=mediana_ocde title="Mediana OCDE" fmt=num1 />
    <Column id=veces_ue title="Espanya / mediana UE" fmt='0.0"×"' />
    <Column id=puesto_ue_texto title="Lloc a la UE" />
    <Column id=puesto_mundo_texto title="Lloc al món" />
</DataTable>

<p class="text-xs text-gray-500">Per 100.000 habitants, últim any de cada país en els últims set. Lloc 1 = el país amb menys. Delictes registrats per la policia que cada país comunica a Nacions Unides (UNODC; a Europa és la mateixa recollida que la d'Eurostat); homicidis del Banc Mundial amb dades d'UNODC; presos, d'UNODC.</p>

<Dropdown data={delitos_lista} name=delito_mundo value=delito title="Delicte" defaultValue="Homicidios intencionados" />

<BarChart
    data={mundo_ranking}
    x=pais
    y=por_100k_hab
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    seriesColors={{'España': '#b91c1c', 'Otros países': '#9ca3af'}}
    yAxisTitle="per 100.000 habitants"
    title="{inputs.delito_mundo.value}: països d'Europa i de l'OCDE (últim any de cada país)"
/>

<LineChart
    data={mundo_serie}
    x=anio
    y=por_100k_hab
    series=pais
    yFmt=num1
    xFmt="####"
    legend=true
    yMin=0
    yAxisTitle="per 100.000 habitants"
    title="{inputs.delito_mundo.value}: evolució a Espanya i a altres països"
/>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">Per què cal comparar amb cura</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>Els homicidis són la xifra més fiable</b>: gairebé sempre es registren i la definició és semblant a tot arreu.</li>
<li><b>La resta són delictes registrats, no comesos.</b> Depenen de quant es denuncia, que és més on la gent confia en la policia o l'assegurança exigeix la denúncia (per això els països nòrdics registren molts furts), i de com els compta cada país.</li>
<li><b>Les definicions canvien.</b> A Espanya, el robatori amb violència o intimidació inclou les estrebades, que en altres països es poden comptar com a furts. Suècia té una de les definicions de violació més àmplies d'Europa. Espanya registra com a estafa cada denúncia d'estafa per internet, i aquestes han crescut molt des del 2019.</li>
<li><b>Pocs casos registrats de corrupció o blanqueig no volen dir poca corrupció</b>: mesuren sobretot quant s'investiga.</li>
<li>No hi ha una xifra total de delictes comparable entre països: cada un inclou faltes i delictes lleus diferents. Per això es compara delicte a delicte.</li>
</ul>
</div>

## Per territori

```sql ccaa
SELECT b.cod, t.nombre AS comunidad, '/ca' || t.ruta AS ruta, b.infracciones, b.tasa_1000
FROM mother.crimen_balance b
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = b.cod
WHERE b.nivel = 'ccaa' AND b.categoria = 'Total infracciones penales' AND b.anio = (SELECT max(anio) FROM mother.crimen_balance)
ORDER BY b.tasa_1000 DESC
```

```sql provincias
SELECT b.cod, t.nombre AS provincia, b.infracciones, b.tasa_1000
FROM mother.crimen_balance b
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = b.cod
WHERE b.nivel = 'provincia' AND b.categoria = 'Total infracciones penales' AND b.anio = (SELECT max(anio) FROM mother.crimen_balance)
```

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod"
    value="tasa_1000"
    valueFmt="num1"
    colorPalette={['#fef2f2', '#f87171', '#7f1d1d']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: Ministeri de l'Interior"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_1000', title: 'Infraccions per 1.000 hab.', fmt: 'num1'},
        {id: 'infracciones', title: 'Infraccions', fmt: 'num0'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=infracciones title="Infraccions conegudes" fmt=num0 />
    <Column id=tasa_1000 title="Per 1.000 hab." fmt=num1 contentType=bar barColor="#fecaca" />
</DataTable>

```sql municipios
WITH u AS (SELECT max(anio) AS anio FROM mother.crimen_balance WHERE nivel = 'municipio')
SELECT
    b.cod AS cod_mun,
    b.nombre AS municipio,
    p.nombre AS provincia,
    b.poblacion,
    max(b.infracciones) FILTER (WHERE b.categoria = 'Total infracciones penales') AS infracciones,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Total infracciones penales') AS tasa_1000,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Hurtos') AS hurtos_1000,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Robos con violencia o intimidación') AS robos_violencia_1000,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Robos con fuerza en domicilios') AS robos_domicilios_1000,
    '/ca/territorios/municipios?m=' || b.cod AS enlace
FROM mother.crimen_balance b
JOIN u ON b.anio = u.anio
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = left(b.cod, 2)
WHERE b.nivel = 'municipio'
GROUP BY ALL
ORDER BY tasa_1000 DESC
```

### Municipis de més de 20.000 habitants ({resumen[0]?.anio})

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=poblacion title="Habitants" fmt=num0 />
    <Column id=tasa_1000 title="Infraccions per 1.000 hab." fmt=num1 contentType=bar barColor="#fecaca" />
    <Column id=hurtos_1000 title="Furts" fmt=num1 />
    <Column id=robos_violencia_1000 title="Robatoris amb violència" fmt=num1 />
    <Column id=robos_domicilios_1000 title="Robatoris en domicilis" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">Encapçalen la llista municipis amb aeroport, port o molt de turisme (el Prat de Llobregat, Adeje, Sant Josep de sa Talaia, Calvià...): allà es denuncien molts delictes contra visitants i passatgers, però la taxa es divideix només entre els veïns empadronats. Taxes per 1.000 habitants empadronats.</p>

## Condemnats per nacionalitat

```sql condenados
SELECT anio, sexo, nacionalidad, condenados, poblacion_18, tasa_1000
FROM mother.crimen_condenados
WHERE nivel = 'pais' AND nacionalidad IN ('Española', 'Extranjera')
ORDER BY anio
```

```sql condenados_ultimo
SELECT
    max(anio) AS anio,
    max(condenados) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera') AS extranjeros,
    max(condenados) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Española') AS espanoles,
    max(poblacion_18) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera') AS pob_extranjera,
    max(poblacion_18) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Española') AS pob_espanola,
    max(tasa_1000) FILTER (WHERE sexo = 'Hombres' AND nacionalidad = 'Extranjera') AS h_ext,
    max(tasa_1000) FILTER (WHERE sexo = 'Hombres' AND nacionalidad = 'Española') AS h_esp,
    max(tasa_1000) FILTER (WHERE sexo = 'Mujeres' AND nacionalidad = 'Extranjera') AS m_ext,
    max(tasa_1000) FILTER (WHERE sexo = 'Mujeres' AND nacionalidad = 'Española') AS m_esp,
    100.0 * max(condenados) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera')
        / sum(condenados) FILTER (WHERE sexo = 'Total') AS pct_condenados_extranjeros,
    100.0 * max(poblacion_18) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera')
        / sum(poblacion_18) FILTER (WHERE sexo = 'Total') AS pct_poblacion_extranjera
FROM ${condenados}
WHERE anio = (SELECT max(anio) FROM ${condenados})
```

Segons l'Estadística de Condemnats de l'INE, el {condenados_ultimo[0]?.anio} van ser condemnats en ferm {formatNumber(condenados_ultimo[0]?.espanoles, 0)} adults de nacionalitat espanyola i {formatNumber(condenados_ultimo[0]?.extranjeros, 0)} de nacionalitat estrangera ({formatNumber(condenados_ultimo[0]?.pct_condenados_extranjeros, 0)} % del total), mentre que els estrangers són el {formatNumber(condenados_ultimo[0]?.pct_poblacion_extranjera, 0)} % dels residents adults.

```sql tasas_sexo
SELECT anio, sexo || ', ' || lower(nacionalidad) AS grupo, tasa_1000
FROM ${condenados}
WHERE sexo IN ('Hombres', 'Mujeres')
ORDER BY anio
```

<LineChart
    data={tasas_sexo}
    x=anio
    y=tasa_1000
    series=grupo
    yFmt=num1
    xFmt="####"
    legend=true
    colorPalette={['#1d4ed8', '#93c5fd', '#b91c1c', '#fca5a5']}
    yAxisTitle="condemnats per 1.000 residents de 18+ anys"
    title="Condemnats per 1.000 residents adults del mateix sexe i nacionalitat"
/>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">Com cal llegir aquesta comparació</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>Aquesta taxa dels estrangers està sobreestimada.</b> Entre els condemnats de nacionalitat estrangera hi ha turistes i persones de pas que no viuen a Espanya: són al numerador però no al denominador, que només compta els residents. Els estrangers en situació irregular, en canvi, sí que solen ser al denominador, perquè el padró no demana permís de residència.</li>
<li><b>L'edat i el sexe pesen molt.</b> En qualsevol país la gran majoria dels condemnats són homes joves, i la població estrangera té més homes joves que l'espanyola. Per això aquí es comparen homes amb homes i dones amb dones ({formatNumber(condenados_ultimo[0]?.h_ext, 1)} davant de {formatNumber(condenados_ultimo[0]?.h_esp, 1)} per mil en homes; {formatNumber(condenados_ultimo[0]?.m_ext, 1)} davant de {formatNumber(condenados_ultimo[0]?.m_esp, 1)} en dones). Més avall s'ajusta també per edat i pels estrangers que no viuen a Espanya.</li>
<li><b>Altres factors</b> que aquesta estadística no recull i que en els estudis expliquen part de la diferència: nivell de renda, ocupació, nivell d'estudis o el barri de residència.</li>
<li>Són persones condemnades, no detingudes ni investigades: ja hi ha hagut un judici. Es compten a la comunitat del jutjat que condemna.</li>
</ul>
</div>

### Ajustant per edat, sexe i estrangers no residents

```sql ajuste
SELECT anio, orden, ajuste, espanoles_por_1000_hab, extranjeros_por_1000_hab, veces,
       condenados_extranjeros, poblacion_extranjera_18, no_residentes_presentes
FROM mother.crimen_condenados_ajuste
WHERE procedencia = 'Total'
ORDER BY anio, orden
```

```sql ajuste_ultimo
SELECT
    max(anio) AS anio,
    max(veces) FILTER (WHERE orden = 1) AS v1,
    max(veces) FILTER (WHERE orden = 2) AS v2,
    max(veces) FILTER (WHERE orden = 3) AS v3,
    max(espanoles_por_1000_hab) FILTER (WHERE orden = 1) AS esp1,
    max(extranjeros_por_1000_hab) FILTER (WHERE orden = 1) AS ext1,
    max(espanoles_por_1000_hab) FILTER (WHERE orden = 2) AS esp2,
    max(extranjeros_por_1000_hab) FILTER (WHERE orden = 2) AS ext2,
    max(extranjeros_por_1000_hab) FILTER (WHERE orden = 3) AS ext3,
    max(poblacion_extranjera_18) AS pob_ext,
    max(no_residentes_presentes) AS visitantes
FROM ${ajuste}
WHERE anio = (SELECT max(anio) FROM ${ajuste})
```

```sql ajuste_barras
SELECT ajuste, veces
FROM ${ajuste}
WHERE anio = (SELECT max(anio) FROM ${ajuste})
ORDER BY orden
```

```sql edad_estructura
SELECT
    100.0 * sum(poblacion) FILTER (WHERE nacionalidad = 'Extranjera' AND edad_desde <= 26) / sum(poblacion) FILTER (WHERE nacionalidad = 'Extranjera') AS ext_jovenes,
    100.0 * sum(poblacion) FILTER (WHERE nacionalidad = 'Española' AND edad_desde <= 26) / sum(poblacion) FILTER (WHERE nacionalidad = 'Española') AS esp_jovenes
FROM mother.crimen_condenados_edad
WHERE anio = (SELECT max(anio) FROM mother.crimen_condenados_edad) AND procedencia IN ('España', 'Total')
```

```sql tasas_edad
SELECT replace(replace(replace(tramo_edad, 'De ', ''), ' años', ''), ' a ', '-') AS edad, edad_desde, sexo || ', ' || lower(nacionalidad) AS grupo, condenados_por_1000_hab
FROM mother.crimen_condenados_edad
WHERE anio = (SELECT max(anio) FROM mother.crimen_condenados_edad) AND procedencia IN ('España', 'Total')
ORDER BY edad_desde, grupo
```

L'INE sí que publica els condemnats per sexe, edat i nacionalitat alhora, de manera que es pot comparar cada grup amb els seus iguals. Amb tots els ajustos possibles, el {ajuste_ultimo[0]?.anio} la taxa de condemnats dels estrangers adults passa de ser {formatNumber(ajuste_ultimo[0]?.v1, 1)} vegades la dels espanyols a {formatNumber(ajuste_ultimo[0]?.v3, 1)} vegades.

<BarChart
    data={ajuste_barras}
    x=ajuste
    y=veces
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    labels=true
    fillColor="#b91c1c"
    yAxisTitle="vegades la taxa dels espanyols"
    title="Quantes vegades és més gran la taxa de condemnats dels estrangers, segons l'ajust ({ajuste_ultimo[0]?.anio})"
/>

<BarChart
    data={tasas_edad}
    x=edad
    y=condenados_por_1000_hab
    series=grupo
    type=grouped
    sort=false
    yFmt=num1
    colorPalette={['#1d4ed8', '#93c5fd', '#b91c1c', '#fca5a5']}
    yAxisTitle="condemnats per 1.000 residents"
    title="Condemnats per 1.000 residents del mateix sexe, edat i nacionalitat ({ajuste_ultimo[0]?.anio})"
/>

<p class="text-xs text-gray-500">En totes les edats la taxa dels estrangers és més alta, però la distància és més gran entre els joves i s'estreny amb l'edat. El {formatNumber(edad_estructura[0]?.ext_jovenes, 0)} % dels estrangers adults té entre 18 i 30 anys, davant del {formatNumber(edad_estructura[0]?.esp_jovenes, 0)} % dels espanyols adults.</p>

<LineChart
    data={ajuste}
    x=anio
    y=veces
    series=ajuste
    yFmt='0.0"×"'
    xFmt="####"
    legend=true
    yMin=0
    seriesColors={{'Sin ajustar': '#9ca3af', 'Edad y sexo': '#f59e0b', 'Edad, sexo y visitantes': '#b91c1c'}}
    yAxisTitle="vegades la taxa dels espanyols"
    title="Taxa de condemnats dels estrangers davant de la dels espanyols, amb cada ajust"
/>

<div class="not-prose rounded-lg border border-gray-300 bg-gray-50 dark:bg-gray-900/40 dark:border-gray-700 p-4 my-4 text-sm text-gray-800 dark:text-gray-100">
<p class="font-semibold mb-1">Què s'ha ajustat i com</p>
<ol class="list-decimal ml-5 space-y-1">
<li><b>Sense ajustar</b> ({formatNumber(ajuste_ultimo[0]?.v1, 1)} vegades): condemnats entre residents de 18 anys o més a mitjan any ({formatNumber(ajuste_ultimo[0]?.ext1, 1)} per mil estrangers davant de {formatNumber(ajuste_ultimo[0]?.esp1, 1)} per mil espanyols). És la xifra de dalt amb la població a mitjan any en lloc d'a 1 de gener, perquè els condemnats es compten durant tot l'any i la població estrangera creix de pressa.</li>
<li><b>Edat i sexe</b> ({formatNumber(ajuste_ultimo[0]?.v2, 1)} vegades): es calcula la taxa de cada grup de sexe i edat (homes de 18 a 20 anys, dones de 21 a 25...) i es recompon com si espanyols i estrangers tinguessin la mateixa piràmide, la de tota la població adulta d'Espanya el {ajuste_ultimo[0]?.anio}. Així queden {formatNumber(ajuste_ultimo[0]?.ext2, 1)} davant de {formatNumber(ajuste_ultimo[0]?.esp2, 1)} per mil. Aquest ajust només treu la part de la diferència que es deu al fet que els estrangers són més joves i hi ha més homes.</li>
<li><b>Estrangers no residents</b> ({formatNumber(ajuste_ultimo[0]?.v3, 1)} vegades): se sumen al denominador els visitants estrangers que hi ha a Espanya en un dia mitjà, que poden ser condemnats però no estan empadronats. Amb Frontur se sumen les nits que passen a Espanya tots els visitants no residents de l'any i es divideixen entre 365: surten uns {formatNumber(ajuste_ultimo[0]?.visitantes / 1e6, 1)} milions d'adults presents en un dia mitjà, davant de {formatNumber(ajuste_ultimo[0]?.pob_ext / 1e6, 1)} milions d'estrangers adults empadronats. Així queden {formatNumber(ajuste_ultimo[0]?.ext3, 1)} per mil. Només hi ha dades des del 2016.</li>
</ol>
<p class="font-semibold mt-3 mb-1">Supòsits del tercer ajust</p>
<ul class="list-disc ml-5 space-y-1">
<li>Frontur dona quants visitants es queden 1 nit, de 2 a 3, de 4 a 7, de 8 a 15 o més de 15. Es pren el punt mitjà de cada tram, 25 nits per a «més de 15» i mitja jornada per als qui no pernocten.</li>
<li>Frontur no publica l'edat dels visitants: se suposa que el 85 % són adults i que es reparteixen per sexe i edat com la població adulta d'Espanya.</li>
<li>Cada dia d'un visitant compta igual que un dia d'un resident. Un turista d'una setmana segurament té menys ocasions de delinquir (i de ser jutjat aquí) que un resident, així que aquest ajust pot quedar-se llarg.</li>
<li>Frontur compta per país de residència, no per nacionalitat: inclou espanyols que viuen a l'estranger i vénen de visita. També per això pot quedar-se llarg.</li>
<li>En sentit contrari, els estrangers que viuen a Espanya sense empadronar-se no són a cap denominador. No hi ha una xifra oficial. L'estimació d'uns 840.000 estrangers en situació irregular a 1 de gener de 2025 (<a class="underline" href="https://www.funcas.es/wp-content/uploads/2026/01/Nota-Coyuntura-Social_Enero-2026.pdf">Funcas</a>) es fa precisament amb la població empadronada, així que aquestes persones ja hi són comptades.</li>
</ul>
<p class="mt-3">Amb aquestes dades, la taxa de condemnats dels estrangers és entre {formatNumber(ajuste_ultimo[0]?.v3, 1)} i {formatNumber(ajuste_ultimo[0]?.v2, 1)} vegades la dels espanyols, segons quant es comptin els visitants. El que aquestes estadístiques no permeten ajustar: renda, ocupació, nivell d'estudis o barri de residència, que en els estudis expliquen una altra part de la diferència, ni les possibles diferències de tracte en la detenció, la investigació o el judici.</p>
</div>

```sql delitos_nacionalidad
SELECT delito, total, extranjera / total AS cuota_extranjera
FROM mother.crimen_condenas_delito
WHERE anio = (SELECT max(anio) FROM mother.crimen_condenas_delito)
  AND delito IN ('Homicidio y sus formas', 'Lesiones', 'Contra la libertad', 'Contra la libertad e indemnidad sexuales', 'Hurtos', 'Robos',
                 'Contra la seguridad vial', 'Contra la salud pública', 'Defraudaciones', 'Contra la Administración de Justicia', 'Quebrantamiento de condena',
                 'Contra las relaciones familiares', 'Falsedades')
ORDER BY total DESC
```

<DataTable data={delitos_nacionalidad} rows=all>
    <Column id=delito title="Delicte" />
    <Column id=total title="Delictes condemnats" fmt=num0 />
    <Column id=cuota_extranjera title="Amb condemnat estranger" fmt=pct0 contentType=bar barColor="#fecaca" />
</DataTable>

<p class="text-xs text-gray-500">Delictes pels quals es va condemnar el {condenados_ultimo[0]?.anio} (un condemnat ho pot ser per diversos delictes) i percentatge en què el condemnat tenia nacionalitat estrangera. Els nacionalitzats espanyols compten com a espanyols.</p>

### Per procedència

```sql procedencia_condenas
SELECT a.procedencia, a.ajuste, a.orden, a.veces, a.anio
FROM mother.crimen_condenados_ajuste a
JOIN (SELECT procedencia, veces AS v2 FROM mother.crimen_condenados_ajuste
      WHERE orden = 2 AND anio = (SELECT max(anio) FROM mother.crimen_condenados_ajuste)) r USING (procedencia)
WHERE a.procedencia <> 'Total' AND a.anio = (SELECT max(anio) FROM mother.crimen_condenados_ajuste)
ORDER BY r.v2 DESC, a.orden
```

```sql procedencia_resumen
SELECT
    max(anio) AS anio,
    max(veces) FILTER (WHERE procedencia = 'África' AND orden = 1) AS africa1,
    max(veces) FILTER (WHERE procedencia = 'África' AND orden = 3) AS africa3,
    max(veces) FILTER (WHERE procedencia = 'América' AND orden = 1) AS america1,
    max(veces) FILTER (WHERE procedencia = 'América' AND orden = 3) AS america3,
    max(veces) FILTER (WHERE procedencia = 'Unión Europea' AND orden = 1) AS ue1,
    max(veces) FILTER (WHERE procedencia = 'Unión Europea' AND orden = 3) AS ue3,
    max(veces) FILTER (WHERE procedencia = 'Resto de Europa' AND orden = 1) AS europa1,
    max(veces) FILTER (WHERE procedencia = 'Resto de Europa' AND orden = 3) AS europa3,
    max(veces) FILTER (WHERE procedencia = 'Asia y Oceanía' AND orden = 3) AS asia3
FROM ${procedencia_condenas}
```

No tota la immigració és igual. Amb els mateixos tres ajustos, el {procedencia_resumen[0]?.anio} la taxa de condemnats dels africans residents passa de {formatNumber(procedencia_resumen[0]?.africa1, 1)} a {formatNumber(procedencia_resumen[0]?.africa3, 1)} vegades la dels espanyols; la dels americans, de {formatNumber(procedencia_resumen[0]?.america1, 1)} a {formatNumber(procedencia_resumen[0]?.america3, 1)}; la dels ciutadans d'altres països de la UE, de {formatNumber(procedencia_resumen[0]?.ue1, 1)} a {formatNumber(procedencia_resumen[0]?.ue3, 1)}, i la de la resta d'Europa (amb el Regne Unit), de {formatNumber(procedencia_resumen[0]?.europa1, 1)} a {formatNumber(procedencia_resumen[0]?.europa3, 1)}. Els asiàtics queden per sota dels espanyols ({formatNumber(procedencia_resumen[0]?.asia3, 1)} vegades).

<BarChart
    data={procedencia_condenas}
    x=procedencia
    y=veces
    series=ajuste
    type=grouped
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    seriesColors={{'Sin ajustar': '#9ca3af', 'Edad y sexo': '#f59e0b', 'Edad, sexo y visitantes': '#b91c1c'}}
    yAxisTitle="vegades la taxa dels espanyols"
    title="Condemnats estrangers per procedència: vegades la taxa dels espanyols ({procedencia_resumen[0]?.anio})"
/>

<p class="text-xs text-gray-500">Estadística de Condemnats de l'INE, que només agrupa per continents: «Amèrica» ajunta Hispanoamèrica amb els EUA i el Canadà (pocs residents), i «Àfrica» el nord d'Àfrica amb la resta del continent. Els visitants es reparteixen per procedència segons el país de residència dels turistes de Frontur. Unió Europea i Resta d'Europa, des del 2020.</p>

#### Per país: detencions i investigats

```sql detenidos_regiones
SELECT procedencia, veces, veces_edad_sexo, veces_visitantes, detenidos_por_1000_hab, espanoles_por_1000_hab, anio,
       row_number() OVER (ORDER BY veces_edad_sexo DESC) AS puesto
FROM mother.crimen_detenidos_procedencia
WHERE tipo IN ('total', 'region') AND anio = (SELECT max(anio) FROM mother.crimen_detenidos_procedencia)
```

```sql detenidos_regiones_largo
SELECT procedencia, puesto, 'Sin ajustar' AS ajuste, 1 AS orden, veces AS valor FROM ${detenidos_regiones}
UNION ALL
SELECT procedencia, puesto, 'Edad y sexo', 2, veces_edad_sexo FROM ${detenidos_regiones}
UNION ALL
SELECT procedencia, puesto, 'Edad, sexo y visitantes', 3, veces_visitantes FROM ${detenidos_regiones} WHERE veces_visitantes IS NOT NULL
ORDER BY puesto, orden
```

```sql detenidos_resumen
SELECT
    max(anio) AS anio,
    max(espanoles_por_1000_hab) AS espanoles,
    max(detenidos_por_1000_hab) FILTER (WHERE procedencia = 'Todos los extranjeros') AS extranjeros,
    max(veces_edad_sexo) FILTER (WHERE procedencia = 'Todos los extranjeros') AS total2,
    max(veces_edad_sexo) FILTER (WHERE procedencia = 'Norte de África') AS norte_africa,
    max(veces_edad_sexo) FILTER (WHERE procedencia = 'África subsahariana') AS subsahariana,
    max(veces_edad_sexo) FILTER (WHERE procedencia = 'Hispanoamérica') AS hispanoamerica,
    max(veces_visitantes) FILTER (WHERE procedencia = 'Europa') AS europa3,
    max(veces_edad_sexo) FILTER (WHERE procedencia = 'Asia') AS asia
FROM ${detenidos_regiones}
```

```sql detenidos_paises
SELECT procedencia AS pais, detenidos, poblacion_15, detenidos_por_1000_hab, veces, veces_edad_sexo, veces_visitantes
FROM mother.crimen_detenidos_procedencia
WHERE tipo = 'pais' AND anio = (SELECT max(anio) FROM mother.crimen_detenidos_procedencia)
  AND poblacion_15 >= 15000
ORDER BY veces_edad_sexo DESC
```

Per separar el nord d'Àfrica de la resta del continent, o Hispanoamèrica, cal fer servir les detencions i investigats del Ministeri de l'Interior, que sí que donen el país (però compten detencions, no condemnes). El {detenidos_resumen[0]?.anio} hi va haver {formatNumber(detenidos_resumen[0]?.extranjeros, 0)} detencions o investigacions per cada 1.000 estrangers de 15 anys o més i {formatNumber(detenidos_resumen[0]?.espanoles, 0)} per cada 1.000 espanyols. Corregida per edat i sexe, la taxa dels estrangers és {formatNumber(detenidos_resumen[0]?.total2, 1)} vegades la dels espanyols: {formatNumber(detenidos_resumen[0]?.norte_africa, 1)} vegades la dels nord-africans, {formatNumber(detenidos_resumen[0]?.subsahariana, 1)} la dels subsaharians, {formatNumber(detenidos_resumen[0]?.hispanoamerica, 1)} la dels hispanoamericans i {formatNumber(detenidos_resumen[0]?.asia, 1)} la dels asiàtics. La dels europeus, comptant els turistes, és {formatNumber(detenidos_resumen[0]?.europa3, 1)} vegades.

<BarChart
    data={detenidos_regiones_largo}
    x=procedencia
    y=valor
    series=ajuste
    type=grouped
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    seriesColors={{'Sin ajustar': '#9ca3af', 'Edad y sexo': '#f59e0b', 'Edad, sexo y visitantes': '#b91c1c'}}
    yAxisTitle="vegades la taxa dels espanyols"
    title="Detencions i investigats per regió de procedència: vegades la taxa dels espanyols ({detenidos_resumen[0]?.anio})"
/>

<DataTable data={detenidos_paises} rows=15 search=true>
    <Column id=pais title="Nacionalitat" />
    <Column id=detenidos title="Detencions i investigats" fmt=num0 />
    <Column id=poblacion_15 title="Residents de 15+ anys" fmt=num0 />
    <Column id=detenidos_por_1000_hab title="Per 1.000 residents" fmt=num1 />
    <Column id=veces title="Vegades la dels espanyols" fmt='0.0"×"' />
    <Column id=veces_edad_sexo title="Corregit per edat i sexe" fmt='0.0"×"' />
    <Column id=veces_visitantes title="I amb turistes" fmt='0.0"×"' />
</DataTable>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">Com llegir les detencions per país</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>Són detencions i investigacions, no condemnes ni persones.</b> Una mateixa persona pot comptar diverses vegades en un any, i no totes acaben en condemna. Els estrangers surten més sobrerepresentats en les detencions que en les condemnes.</li>
<li><b>Inclouen qui no viu aquí.</b> Turistes, persones de pas i estrangers acabats d'arribar que encara no estan empadronats compten en les detencions però no en la població. En nacionalitats amb moltes arribades irregulars recents, com l'algeriana, o amb molt de pas diari per Ceuta i Melilla, com la marroquina, la taxa està més sobreestimada. La columna «I amb turistes» només existeix per als països que Frontur separa.</li>
<li><b>Correcció per edat i sexe:</b> com que Interior no dona l'edat dels detinguts, s'aplica a la piràmide de cada nacionalitat la corba de condemnats per edat i sexe d'Espanya, i es compara el que s'ha observat amb el que s'esperaria.</li>
<li>Hispanoamèrica és Amèrica menys el Brasil. En les detencions inclou els EUA i el Canadà, que Interior no separa, però en la població es treuen: són uns 100.000 residents davant de gairebé 4 milions d'hispanoamericans. Només es mostren països amb almenys 15.000 residents de 15 anys o més.</li>
<li>El 2020 van entrar a l'estadística els Mossos d'Esquadra i el 2025 els investigats per l'Ertzaintza: les xifres pugen de cop aquests anys per a totes les nacionalitats.</li>
</ul>
</div>

### Espanya a Europa

```sql europa
SELECT pais, cod_pais, anio, veces, veces_edad_sexo, factor_edad_sexo, extranjeros_poblacion_pct, extranjeros_condenados_pct, veces_presos,
       CASE WHEN cod_pais = 'ES' THEN 'España' ELSE 'Otros países' END AS grupo
FROM mother.crimen_europa_nacionalidad e
WHERE anio = (SELECT max(anio) FROM mother.crimen_europa_nacionalidad x WHERE x.cod_pais = e.cod_pais)
  AND anio >= 2018 AND extranjeros_poblacion_pct >= 5 AND cod_pais <> 'LV'
ORDER BY veces_edad_sexo DESC
```

```sql europa_espana
SELECT
    max(anio) FILTER (WHERE cod_pais = 'ES') AS anio,
    max(veces) FILTER (WHERE cod_pais = 'ES') AS veces,
    max(veces_edad_sexo) FILTER (WHERE cod_pais = 'ES') AS ajustado,
    count(*) AS paises,
    count(*) FILTER (WHERE veces_edad_sexo > (SELECT veces_edad_sexo FROM ${europa} WHERE cod_pais = 'ES')) AS por_encima,
    median(veces_edad_sexo) AS mediana
FROM ${europa}
```

```sql europa_serie
SELECT pais, anio, veces_edad_sexo
FROM mother.crimen_europa_nacionalidad
WHERE cod_pais IN ('ES', 'DE', 'FR', 'IT', 'PT', 'AT', 'CH', 'DK') AND anio >= 2010
ORDER BY anio
```

Eurostat reuneix els condemnats per nacionalitat que publiquen uns vint països europeus. El {europa_espana[0]?.anio} la taxa de condemnats dels estrangers a Espanya era {formatNumber(europa_espana[0]?.veces, 1)} vegades la dels espanyols, i {formatNumber(europa_espana[0]?.ajustado, 1)} vegades corregida per edat i sexe. Dels {formatNumber(europa_espana[0]?.paises, 0)} països amb almenys un 5 % de població estrangera, {formatNumber(europa_espana[0]?.por_encima, 0)} tenen una diferència més gran que la d'Espanya (la mediana és {formatNumber(europa_espana[0]?.mediana, 1)} vegades).

<BarChart
    data={europa}
    x=pais
    y=veces_edad_sexo
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    seriesColors={{'España': '#b91c1c', 'Otros países': '#9ca3af'}}
    yAxisTitle="vegades la taxa dels nacionals, corregida per edat i sexe"
    title="Condemnats estrangers davant de nacionals a Europa, corregit per edat i sexe (últim any de cada país)"
/>

<LineChart
    data={europa_serie}
    x=anio
    y=veces_edad_sexo
    series=pais
    yFmt='0.0"×"'
    xFmt="####"
    legend=true
    yMin=0
    yAxisTitle="vegades, corregit per edat i sexe"
    title="Evolució en alguns països: condemnats estrangers davant de nacionals, corregit per edat i sexe"
/>

<DataTable data={europa} rows=all>
    <Column id=pais title="País" />
    <Column id=anio title="Any" fmt="####" />
    <Column id=extranjeros_poblacion_pct title="Estrangers a la població (15+)" fmt='0.0"%"' />
    <Column id=extranjeros_condenados_pct title="Estrangers entre els condemnats" fmt='0.0"%"' />
    <Column id=veces title="Vegades, sense ajustar" fmt='0.0"×"' />
    <Column id=veces_edad_sexo title="Corregit per edat i sexe" fmt='0.0"×"' />
    <Column id=veces_presos title="Presos: vegades" fmt='0.0"×"' />
</DataTable>

<div class="not-prose rounded-lg border border-gray-300 bg-gray-50 dark:bg-gray-900/40 dark:border-gray-700 p-4 my-4 text-sm text-gray-800 dark:text-gray-100">
<p class="font-semibold mb-1">Com s'ha fet la comparació europea</p>
<ul class="list-disc ml-5 space-y-1">
<li>Condemnats per nacionalitat d'Eurostat (crim_just_ctz) dividits entre la població de 15 anys o més de la mateixa nacionalitat (migr_pop1ctz). Es compara «quantes vegades» dins de cada país, perquè cada país compta les condemnes a la seva manera (a Alemanya, per exemple, inclouen delictes d'estrangeria que només pot cometre un estranger; a Espanya estar en situació irregular no és delicte).</li>
<li>Eurostat no dona l'edat dels condemnats. Per corregir per edat i sexe s'aplica a la piràmide de nacionals i estrangers de cada país la corba de condemnats per edat i sexe d'Espanya. Així es calcula quants condemnats caldria esperar en cada grup només per la seva edat i el seu sexe. A Espanya, aquest mètode dona {formatNumber(europa_espana[0]?.ajustado, 1)} vegades, gairebé el mateix que l'ajust directe amb les dades complertes de l'INE.</li>
<li>No s'ajusta per turistes en cap país. Espanya, Àustria, Grècia o Portugal reben molts visitants per habitant, així que la seva xifra està una mica més inflada que la d'altres.</li>
<li>Només països amb almenys un 5 % d'estrangers i amb dades des del 2018. Queda fora Letònia: allà la majoria dels «estrangers» són residents de tota la vida sense nacionalitat letona. «Presos: vegades» compara els presos (inclosos els preventius) de la mateixa manera, sense corregir per edat.</li>
<li>Països com Suècia o els Països Baixos no publiquen aquesta dada a Eurostat. A més, allà molts immigrants es nacionalitzen aviat i deixen de comptar com a estrangers, igual que els nacionalitzats a Espanya compten com a espanyols.</li>
</ul>
</div>

---

## Fonts i notes

- **[Ministeri de l'Interior – Portal Estadístic de Criminalitat](https://estadisticasdecriminalidad.ses.mir.es/)**: sèrie anual d'infraccions penals conegudes per comunitat i província des del 2010, i Balanç de Criminalitat trimestral amb els municipis de més de 20.000 habitants (any complet des del 2019). El 2019 va canviar la classificació del Balanç, de manera que no es compara amb anys anteriors.
- **[INE – Estadística de Condemnats: adults](https://www.ine.es/jaxiT3/Tabla.htm?t=25704)** (taules 25704 i 49050), a partir del Registre Central de Penats, **[INE – Condemnats segons sexe, edat i nacionalitat](https://www.ine.es/jaxiT3/Tabla.htm?t=25645)** (taula 25645) per a l'ajust per edat, i **[INE – Estadística Contínua de Població](https://www.ine.es/jaxiT3/Tabla.htm?t=56942)** (taula 56942) per a la població per nacionalitat, sexe i edat a 1 de gener. Població de 18 anys o més i de cada tram d'edat aproximada a partir de grups d'edat de cinc anys.
- **[INE – Frontur](https://www.ine.es/jaxiT3/Tabla.htm?t=23987)** (taules 23987 i 23984): visitants no residents per durada de l'estada i turistes per país de residència, per estimar quants n'hi ha a Espanya en un dia mitjà i d'on vénen.
- **[Ministeri de l'Interior – Detencions i investigats](https://estadisticasdecriminalidad.ses.mir.es/)** (taules 03007 i 03001): detencions i investigats estrangers per nacionalitat i el total, i **[INE – Població per país de nacionalitat](https://www.ine.es/jaxiT3/Tabla.htm?t=56936)** (taula 56936) per al denominador.
- **[Nacions Unides – UNODC](https://dataunodc.un.org/)**: delictes registrats per la policia per tipus i presos en tots els països que responen a l'enquesta UN-CTS, i homicidis intencionats del **[Banc Mundial](https://data.worldbank.org/indicator/VC.IHR.PSRC.P5)** amb dades d'UNODC.
- **[Eurostat](https://ec.europa.eu/eurostat/databrowser/view/crim_just_ctz)**: condemnats (crim_just_ctz) i presos (crim_pris_ctz) per nacionalitat a cada país europeu, i població per nacionalitat, sexe i edat (migr_pop1ctz).

<LastRefreshed prefix="Dades actualitzades" />
