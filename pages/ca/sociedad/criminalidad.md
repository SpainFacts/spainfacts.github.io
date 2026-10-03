---
title: Criminalitat
description: "Delictes coneguts a Espanya per tipus, comunitat, província i municipi des de 2010, evolució de la cibercriminalitat i condemnats per nacionalitat amb el seu context."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 865a8f911a6a
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
SELECT periodo, anio, infracciones, infracciones_anio_anterior, infracciones / infracciones_anio_anterior - 1 AS variacion
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
        sparklineData={serie_kpi.filter(d => d.categoria === 'Total infracciones penales').map(d => d.tasa_1000)}
    />
    <KpiCard
        title="Homicidis i assassinats"
        value={resumen[0]?.homicidios}
        formattedValue="{formatNumber(resumen[0]?.homicidios_100k, 2)} per 100.000 hab."
        period="{formatNumber(resumen[0]?.homicidios, 0)} consumats el {resumen[0]?.anio}"
        source="Ministeri de l'Interior"
        sparklineData={serie_kpi.filter(d => d.categoria === 'Homicidios y asesinatos consumados').map(d => d.tasa_1000 * 100)}
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
    b.territorio AS municipio,
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
WHERE cod_ccaa = '00' AND nacionalidad IN ('Española', 'Extranjera')
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
<li><b>La taxa dels estrangers està sobreestimada.</b> Entre els condemnats de nacionalitat estrangera hi ha turistes, persones en trànsit i persones en situació irregular que no figuren al padró, de manera que són al numerador però no al denominador.</li>
<li><b>L'edat i el sexe pesen molt.</b> En qualsevol país la gran majoria dels condemnats són homes joves, i la població estrangera té més homes joves que l'espanyola. Per això aquí es comparen homes amb homes i dones amb dones ({formatNumber(condenados_ultimo[0]?.h_ext, 1)} davant de {formatNumber(condenados_ultimo[0]?.h_esp, 1)} per mil en homes; {formatNumber(condenados_ultimo[0]?.m_ext, 1)} davant de {formatNumber(condenados_ultimo[0]?.m_esp, 1)} en dones). No és possible ajustar per edat: l'INE no creua l'edat i la nacionalitat dels condemnats.</li>
<li><b>Altres factors</b> que aquesta estadística no recull i que en els estudis expliquen part de la diferència: nivell de renda, ocupació, nivell d'estudis o el barri de residència.</li>
<li>Són persones condemnades, no detingudes ni investigades: ja hi ha hagut un judici. Es compten a la comunitat del jutjat que condemna.</li>
</ul>
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

---

## Fonts i notes

- **[Ministeri de l'Interior – Portal Estadístic de Criminalitat](https://estadisticasdecriminalidad.ses.mir.es/)**: sèrie anual d'infraccions penals conegudes per comunitat i província des del 2010, i Balanç de Criminalitat trimestral amb els municipis de més de 20.000 habitants (any complet des del 2019). El 2019 va canviar la classificació del Balanç, de manera que no es compara amb anys anteriors.
- **[INE – Estadística de Condemnats: adults](https://www.ine.es/jaxiT3/Tabla.htm?t=25704)** (taules 25704 i 49050), a partir del Registre Central de Penats, i **[INE – Estadística Contínua de Població](https://www.ine.es/jaxiT3/Tabla.htm?t=56942)** (taula 56942) per a la població per nacionalitat, sexe i edat a 1 de gener. Població de 18 anys o més aproximada a partir de grups d'edat de cinc anys.

<LastRefreshed prefix="Dades actualitzades" />
