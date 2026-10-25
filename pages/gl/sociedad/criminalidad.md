---
title: Criminalidade
description: "Delitos coñecidos en España por tipo, comunidade, provincia e municipio desde 2010, evolución da cibercriminalidade e condenados por nacionalidade co seu contexto."
i18n_origen: 7a9a98e7cc4a
og:
  image: https://spainfacts.org/og-spainfacts.png
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

# 🚨 Criminalidade

Os delitos que coñecen a Policía Nacional, a Garda Civil, os Mossos d'Esquadra, a Ertzaintza, a Policía Foral de Navarra e as policías locais, segundo o Ministerio do Interior.

<Grid cols=4>
    <KpiCard
        title="Infraccións penais coñecidas"
        value={resumen[0]?.total}
        formattedValue="{formatNumber(resumen[0]?.tasa, 1)} por 1.000 hab."
        period="{formatCompact(resumen[0]?.total, 2)} en total · {resumen[0]?.anio}"
        change={resumen[0]?.total_2019 ? (100 * (resumen[0].total / resumen[0].total_2019 - 1)).toFixed(1) : null}
        changeUnit=" %"
        changePeriod="fronte a 2019"
        direction="positive-down"
        source="Ministerio do Interior"
        sparklineData={serie_kpi.filter(d => d.categoria === 'Total infracciones penales').map(d => ({...d, y: d.tasa_1000}))}
    />
    <KpiCard
        title="Homicidios e asasinatos"
        value={resumen[0]?.homicidios}
        formattedValue="{formatNumber(resumen[0]?.homicidios_100k, 2)} por 100.000 hab."
        period="{formatNumber(resumen[0]?.homicidios, 0)} consumados en {resumen[0]?.anio}"
        source="Ministerio do Interior"
        sparklineData={serie_kpi.filter(d => d.categoria === 'Homicidios y asesinatos consumados').map(d => ({...d, y: d.tasa_1000 * 100}))}
    />
    <KpiCard
        title="Cibercriminalidade"
        value={resumen[0]?.ciber}
        formattedValue="{formatNumber(resumen[0]?.ciber / resumen[0]?.total / 0.01, 0)} %"
        period="{formatNumber(resumen[0]?.ciber / 1000, 0)} mil infraccións por internet, sobre todo estafas"
        source="Ministerio do Interior"
        sparklineData={espana.filter(d => d.categoria === 'Cibercriminalidad').map(d => 100 * d.infracciones / (espana.find(t => t.anio === d.anio && t.categoria === 'Total infracciones penales')?.infracciones ?? NaN)).filter(v => Number.isFinite(v))}
    />
    <KpiCard
        title="Este ano ({semestre[0]?.periodo})"
        value={semestre[0]?.infracciones}
        formattedValue={formatCompact(semestre[0]?.infracciones, 2)}
        change={semestre[0]?.variacion != null ? (100 * semestre[0].variacion).toFixed(1) : null}
        changeUnit=" %"
        changePeriod="fronte ao mesmo período de {semestre[0]?.anio - 1}"
        direction="positive-down"
        source="Balance de Criminalidade"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('homicidios')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'homicidios')} />


<p class="text-xs text-gray-500">Todas as cifras danse por habitante para que a evolución non reflicta só o crecemento da poboación (España gañou uns 2 millóns de habitantes entre 2019 e 2025); o total aparece como dato secundario. Son feitos <b>coñecidos</b> (denunciados ou descubertos pola policía), non todos os delitos cometidos: unha suba pode deberse a que se denuncia máis (como pasou cos delitos sexuais ou as estafas por internet). A taxa por habitante non ten en conta os turistas e visitantes, que tamén sofren e cometen delitos: por iso sae alta nas zonas máis turísticas.</p>

## Que delitos e como evolucionan

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
    yAxisTitle="por 100.000 habitantes"
    fillColor="#b91c1c"
    title="Principais delitos coñecidos en {resumen[0]?.anio}, por 100.000 habitantes"
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
    yAxisTitle="por 1.000 habitantes"
    xFmt="####"
    colorPalette={['#b91c1c', '#7c3aed']}
    title="Criminalidade convencional e por internet, por 1.000 habitantes"
/>

<p class="text-xs text-gray-500">2020 é o ano do confinamento. Desde 2019 o Ministerio conta á parte a cibercriminalidade (estafas e outros delitos cometidos por internet), que medrou moito máis ca o resto.</p>

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
    yAxisTitle="por 100.000 habitantes"
    xFmt="####"
    yLog=true
    legend=true
    title="Algúns delitos desde 2010 por 100.000 habitantes (escala logarítmica)"
/>

<p class="text-xs text-gray-500">Escala logarítmica para ver xuntos delitos moi distintos en número: unha pendente igual é un mesmo ritmo de crecemento. As estafas informáticas multiplicáronse desde 2016, os roubos en vivendas baixaron e as agresións sexuais con penetración coñecidas aumentaron, en parte porque se denuncian máis.</p>

## España en Europa e no mundo

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

En homicidios, que é a cifra que mellor se compara entre países, España está entre os países con menos casos do mundo: {formatNumber(mundo_resumen[0]?.homicidios, 1)} por cada 100.000 habitantes en {mundo_resumen[0]?.homicidios_anio} (mediana da UE: {formatNumber(mundo_resumen[0]?.homicidios_ue, 1)}), o posto {mundo_resumen[0]?.homicidios_puesto} entre {mundo_resumen[0]?.homicidios_paises} países e o {mundo_resumen[0]?.homicidios_puesto_ue} da UE comezando polo máis baixo. Nos demais delitos que rexistra a policía, España está por baixo da mediana da UE en {mundo_resumen[0]?.por_debajo} e por riba en {mundo_resumen[0]?.por_encima}. Ten {formatNumber(mundo_resumen[0]?.presos, 0)} presos por cada 100.000 habitantes (mediana da UE: {formatNumber(mundo_resumen[0]?.presos_ue, 0)}).

<DataTable data={mundo_espana} rows=all>
    <Column id=delito title="Delito" />
    <Column id=anio title="Ano" fmt="####" />
    <Column id=espana title="España" fmt=num1 />
    <Column id=mediana_ue title="Mediana UE" fmt=num1 />
    <Column id=mediana_ocde title="Mediana OCDE" fmt=num1 />
    <Column id=veces_ue title="España / mediana UE" fmt='0.0"×"' />
    <Column id=puesto_ue_texto title="Posto na UE" />
    <Column id=puesto_mundo_texto title="Posto no mundo" />
</DataTable>

<p class="text-xs text-gray-500">Por 100.000 habitantes, último ano de cada país nos últimos sete. Posto 1 = o país con menos. Delitos rexistrados pola policía que cada país comunica ás Nacións Unidas (UNODC; en Europa é a mesma recollida que a de Eurostat); homicidios do Banco Mundial con datos de UNODC; presos, de UNODC.</p>

<Dropdown data={delitos_lista} name=delito_mundo value=delito title="Delito" defaultValue="Homicidios intencionados" />

<BarChart
    data={mundo_ranking}
    x=pais
    y=por_100k_hab
    series=grupo
    swapXY=true
    sort=false
    yFmt=num1
    seriesColors={{'España': '#b91c1c', 'Otros países': '#9ca3af'}}
    yAxisTitle="por 100.000 habitantes"
    title="{inputs.delito_mundo.value}: países de Europa e da OCDE (último ano de cada país)"
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
    yAxisTitle="por 100.000 habitantes"
    title="{inputs.delito_mundo.value}: evolución en España e outros países"
/>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">Por que hai que comparar con coidado</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>Os homicidios son a cifra máis fiable</b>: case sempre se rexistran e a definición é parecida en todas partes.</li>
<li><b>O resto son delitos rexistrados, non cometidos.</b> Dependen de canto se denuncia, que é máis onde a xente confía na policía ou o seguro esixe a denuncia (por iso os países nórdicos rexistran moitos furtos), e de como os conta cada país.</li>
<li><b>As definicións cambian.</b> En España, o roubo con violencia ou intimidación inclúe os tiróns, que noutros países poden contarse como furtos. Suecia ten unha das definicións de violación máis amplas de Europa. España rexistra como estafa cada denuncia de estafa por internet, e estas creceron moito desde 2019.</li>
<li><b>Poucos casos rexistrados de corrupción ou branqueo non queren dicir pouca corrupción</b>: miden sobre todo canto se investiga.</li>
<li>Non hai unha cifra total de delitos comparable entre países: cada un inclúe faltas e delitos leves distintos. Por iso se compara delito a delito.</li>
</ul>
</div>


## Por territorio

```sql ccaa
SELECT b.cod, t.nombre AS comunidad, '/gl' || t.ruta AS ruta, b.infracciones, b.tasa_1000
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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio do Interior"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_1000', title: 'Infraccións por 1.000 hab.', fmt: 'num1'},
        {id: 'infracciones', title: 'Infraccións', fmt: 'num0'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidade" />
    <Column id=infracciones title="Infraccións coñecidas" fmt=num0 />
    <Column id=tasa_1000 title="Por 1.000 hab." fmt=num1 contentType=bar barColor="#fecaca" />
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
    '/gl/territorios/municipios?m=' || b.cod AS enlace
FROM mother.crimen_balance b
JOIN u ON b.anio = u.anio
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = left(b.cod, 2)
WHERE b.nivel = 'municipio'
GROUP BY ALL
ORDER BY tasa_1000 DESC
```

### Municipios de máis de 20.000 habitantes ({resumen[0]?.anio})

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=tasa_1000 title="Infraccións por 1.000 hab." fmt=num1 contentType=bar barColor="#fecaca" />
    <Column id=hurtos_1000 title="Furtos" fmt=num1 />
    <Column id=robos_violencia_1000 title="Roubos con violencia" fmt=num1 />
    <Column id=robos_domicilios_1000 title="Roubos en domicilios" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">Encabezan a lista municipios con aeroporto, porto ou moito turismo (El Prat de Llobregat, Adeje, Sant Josep de sa Talaia, Calvià...): alí denúncianse moitos delitos contra visitantes e pasaxeiros, pero a taxa divídese só entre os veciños empadroados. Taxas por 1.000 habitantes empadroados.</p>

## Condenados por nacionalidade

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

Segundo a Estatística de Condenados do INE, en {condenados_ultimo[0]?.anio} foron condenados en firme {formatNumber(condenados_ultimo[0]?.espanoles, 0)} adultos de nacionalidade española e {formatNumber(condenados_ultimo[0]?.extranjeros, 0)} de nacionalidade estranxeira ({formatNumber(condenados_ultimo[0]?.pct_condenados_extranjeros, 0)} % do total), cando os estranxeiros son o {formatNumber(condenados_ultimo[0]?.pct_poblacion_extranjera, 0)} % dos residentes adultos.

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
    yAxisTitle="condenados por 1.000 residentes de 18+ anos"
    title="Condenados por 1.000 residentes adultos do seu mesmo sexo e nacionalidade"
/>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">Como ler esta comparación</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>Esta taxa dos estranxeiros está sobreestimada.</b> Entre os condenados de nacionalidade estranxeira hai turistas e persoas de paso que non viven en España: están no numerador pero non no denominador, que só conta os residentes. Os estranxeiros en situación irregular, en cambio, si adoitan estar no denominador, porque o padrón non pide permiso de residencia.</li>
<li><b>A idade e o sexo pesan moito.</b> En calquera país a gran maioría dos condenados son homes novos, e a poboación estranxeira ten máis homes novos ca a española. Por iso aquí compáranse homes con homes e mulleres con mulleres ({formatNumber(condenados_ultimo[0]?.h_ext, 1)} fronte a {formatNumber(condenados_ultimo[0]?.h_esp, 1)} por mil en homes; {formatNumber(condenados_ultimo[0]?.m_ext, 1)} fronte a {formatNumber(condenados_ultimo[0]?.m_esp, 1)} en mulleres). Máis abaixo axústase tamén por idade e polos estranxeiros que non viven en España.</li>
<li><b>Outros factores</b> que esta estatística non recolle e que nos estudos explican parte da diferenza: nivel de renda, emprego, nivel de estudos ou o barrio de residencia.</li>
<li>Son persoas condenadas, non detidas nin investigadas: xa houbo un xuízo. Cóntase na comunidade do xulgado que condena.</li>
</ul>
</div>

### Axustando por idade, sexo e estranxeiros non residentes

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

O INE si publica os condenados por sexo, idade e nacionalidade á vez, así que se pode comparar cada grupo cos seus iguais. Con todos os axustes posibles, en {ajuste_ultimo[0]?.anio} a taxa de condenados dos estranxeiros adultos pasa de ser {formatNumber(ajuste_ultimo[0]?.v1, 1)} veces a dos españois a {formatNumber(ajuste_ultimo[0]?.v3, 1)} veces.

<BarChart
    data={ajuste_barras}
    x=ajuste
    y=veces
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    labels=true
    fillColor="#b91c1c"
    yAxisTitle="veces a taxa dos españois"
    title="Cantas veces é maior a taxa de condenados dos estranxeiros, segundo o axuste ({ajuste_ultimo[0]?.anio})"
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
    yAxisTitle="condenados por 1.000 residentes"
    title="Condenados por 1.000 residentes do seu mesmo sexo, idade e nacionalidade ({ajuste_ultimo[0]?.anio})"
/>

<p class="text-xs text-gray-500">En todas as idades a taxa dos estranxeiros é máis alta, pero a distancia é maior entre os novos e vaise estreitando coa idade. O {formatNumber(edad_estructura[0]?.ext_jovenes, 0)} % dos estranxeiros adultos ten entre 18 e 30 anos, fronte ao {formatNumber(edad_estructura[0]?.esp_jovenes, 0)} % dos españois adultos.</p>

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
    yAxisTitle="veces a taxa dos españois"
    title="Taxa de condenados dos estranxeiros fronte á dos españois, con cada axuste"
/>

<div class="not-prose rounded-lg border border-gray-300 bg-gray-50 dark:bg-gray-900/40 dark:border-gray-700 p-4 my-4 text-sm text-gray-800 dark:text-gray-100">
<p class="font-semibold mb-1">Que se axustou e como</p>
<ol class="list-decimal ml-5 space-y-1">
<li><b>Sen axustar</b> ({formatNumber(ajuste_ultimo[0]?.v1, 1)} veces): condenados entre residentes de 18 ou máis anos a metade de ano ({formatNumber(ajuste_ultimo[0]?.ext1, 1)} por mil estranxeiros fronte a {formatNumber(ajuste_ultimo[0]?.esp1, 1)} por mil españois). É a cifra de arriba coa poboación a metade de ano en vez de a 1 de xaneiro, porque os condenados cóntanse durante todo o ano e a poboación estranxeira medra axiña.</li>
<li><b>Idade e sexo</b> ({formatNumber(ajuste_ultimo[0]?.v2, 1)} veces): calcúlase a taxa de cada grupo de sexo e idade (homes de 18 a 20 anos, mulleres de 21 a 25...) e recompónse coma se españois e estranxeiros tivesen a mesma pirámide, a de toda a poboación adulta de España en {ajuste_ultimo[0]?.anio}. Así quedan {formatNumber(ajuste_ultimo[0]?.ext2, 1)} fronte a {formatNumber(ajuste_ultimo[0]?.esp2, 1)} por mil. Este axuste só quita a parte da diferenza que se debe a que os estranxeiros son máis novos e hai máis homes.</li>
<li><b>Estranxeiros non residentes</b> ({formatNumber(ajuste_ultimo[0]?.v3, 1)} veces): súmanse ao denominador os visitantes estranxeiros que hai en España nun día medio, que poden ser condenados pero non están empadroados. Con Frontur súmanse as noites que pasan en España todos os visitantes non residentes do ano e divídense entre 365: saen uns {formatNumber(ajuste_ultimo[0]?.visitantes / 1e6, 1)} millóns de adultos presentes nun día medio, fronte a {formatNumber(ajuste_ultimo[0]?.pob_ext / 1e6, 1)} millóns de estranxeiros adultos empadroados. Así quedan {formatNumber(ajuste_ultimo[0]?.ext3, 1)} por mil. Só hai datos desde 2016.</li>
</ol>
<p class="font-semibold mt-3 mb-1">Supostos do terceiro axuste</p>
<ul class="list-disc ml-5 space-y-1">
<li>Frontur dá cantos visitantes se quedan 1 noite, de 2 a 3, de 4 a 7, de 8 a 15 ou máis de 15. Tómase o punto medio de cada tramo, 25 noites para «máis de 15» e media xornada para quen non pernocta.</li>
<li>Frontur non publica a idade dos visitantes: suponse que o 85 % son adultos e que se reparten por sexo e idade como a poboación adulta de España.</li>
<li>Cada día dun visitante conta igual que un día dun residente. Un turista dunha semana seguramente ten menos ocasións de delinquir (e de ser xulgado aquí) ca un residente, así que este axuste pode quedar longo.</li>
<li>Frontur conta por país de residencia, non por nacionalidade: inclúe españois que viven fóra e veñen de visita. Tamén por iso pode quedar longo.</li>
<li>En sentido contrario, os estranxeiros que viven en España sen empadroarse non están en ningún denominador. Non hai unha cifra oficial. A estimación duns 840.000 estranxeiros en situación irregular a 1 de xaneiro de 2025 (<a class="underline" href="https://www.funcas.es/wp-content/uploads/2026/01/Nota-Coyuntura-Social_Enero-2026.pdf">Funcas</a>) faise precisamente coa poboación empadroada, así que esas persoas xa están contadas.</li>
</ul>
<p class="mt-3">Con estes datos, a taxa de condenados dos estranxeiros está entre {formatNumber(ajuste_ultimo[0]?.v3, 1)} e {formatNumber(ajuste_ultimo[0]?.v2, 1)} veces a dos españois, segundo canto se conte os visitantes. O que estas estatísticas non permiten axustar: renda, emprego, nivel de estudos ou barrio de residencia, que nos estudos explican outra parte da diferenza, nin as posibles diferenzas de trato na detención, a investigación ou o xuízo.</p>
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
    <Column id=delito title="Delito" />
    <Column id=total title="Delitos condenados" fmt=num0 />
    <Column id=cuota_extranjera title="Con condenado estranxeiro" fmt=pct0 contentType=bar barColor="#fecaca" />
</DataTable>

<p class="text-xs text-gray-500">Delitos polos que se condenou en {condenados_ultimo[0]?.anio} (un condenado pode selo por varios delitos) e porcentaxe nos que o condenado tiña nacionalidade estranxeira. Os nacionalizados españois contan como españois.</p>

### Por orixe

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

Non toda a inmigración é igual. Cos mesmos tres axustes, en {procedencia_resumen[0]?.anio} a taxa de condenados dos africanos residentes pasa de {formatNumber(procedencia_resumen[0]?.africa1, 1)} a {formatNumber(procedencia_resumen[0]?.africa3, 1)} veces a dos españois; a dos americanos, de {formatNumber(procedencia_resumen[0]?.america1, 1)} a {formatNumber(procedencia_resumen[0]?.america3, 1)}; a dos cidadáns doutros países da UE, de {formatNumber(procedencia_resumen[0]?.ue1, 1)} a {formatNumber(procedencia_resumen[0]?.ue3, 1)}, e a do resto de Europa (co Reino Unido), de {formatNumber(procedencia_resumen[0]?.europa1, 1)} a {formatNumber(procedencia_resumen[0]?.europa3, 1)}. Os asiáticos quedan por baixo dos españois ({formatNumber(procedencia_resumen[0]?.asia3, 1)} veces).

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
    yAxisTitle="veces a taxa dos españois"
    title="Condenados estranxeiros por orixe: veces a taxa dos españois ({procedencia_resumen[0]?.anio})"
/>

<p class="text-xs text-gray-500">Estatística de Condenados do INE, que só agrupa por continentes: «América» xunta Hispanoamérica con EE. UU. e Canadá (poucos residentes), e «África» o norte de África co resto do continente. Os visitantes repártense por orixe segundo o país de residencia dos turistas de Frontur. Unión Europea e Resto de Europa, desde 2020.</p>

#### Por país: detencións e investigados

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

Para separar o norte de África do resto do continente, ou Hispanoamérica, hai que usar as detencións e investigados do Ministerio do Interior, que si dan o país (pero contan detencións, non condenas). En {detenidos_resumen[0]?.anio} houbo {formatNumber(detenidos_resumen[0]?.extranjeros, 0)} detencións ou investigacións por cada 1.000 estranxeiros de 15 ou máis anos e {formatNumber(detenidos_resumen[0]?.espanoles, 0)} por cada 1.000 españois. Corrixida por idade e sexo, a taxa dos estranxeiros é {formatNumber(detenidos_resumen[0]?.total2, 1)} veces a dos españois: {formatNumber(detenidos_resumen[0]?.norte_africa, 1)} veces a dos norteafricanos, {formatNumber(detenidos_resumen[0]?.subsahariana, 1)} a dos subsaharianos, {formatNumber(detenidos_resumen[0]?.hispanoamerica, 1)} a dos hispanoamericanos e {formatNumber(detenidos_resumen[0]?.asia, 1)} a dos asiáticos. A dos europeos, contando os turistas, é {formatNumber(detenidos_resumen[0]?.europa3, 1)} veces.

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
    yAxisTitle="veces a taxa dos españois"
    title="Detencións e investigados por rexión de orixe: veces a taxa dos españois ({detenidos_resumen[0]?.anio})"
/>

<DataTable data={detenidos_paises} rows=15 search=true>
    <Column id=pais title="Nacionalidade" />
    <Column id=detenidos title="Detencións e investigados" fmt=num0 />
    <Column id=poblacion_15 title="Residentes de 15+ anos" fmt=num0 />
    <Column id=detenidos_por_1000_hab title="Por 1.000 residentes" fmt=num1 />
    <Column id=veces title="Veces a dos españois" fmt='0.0"×"' />
    <Column id=veces_edad_sexo title="Corrixido por idade e sexo" fmt='0.0"×"' />
    <Column id=veces_visitantes title="E con turistas" fmt='0.0"×"' />
</DataTable>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">Como ler as detencións por país</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>Son detencións e investigacións, non condenas nin persoas.</b> Unha mesma persoa pode contar varias veces nun ano, e non todas acaban en condena. Os estranxeiros saen máis sobrerrepresentados nas detencións que nas condenas.</li>
<li><b>Inclúen a quen non vive aquí.</b> Turistas, persoas de paso e estranxeiros recén chegados que aínda non están empadroados contan nas detencións pero non na poboación. En nacionalidades con moitas chegadas irregulares recentes, como a alxeriana, ou con moito paso diario por Ceuta e Melilla, como a marroquí, a taxa está máis sobreestimada. A columna «E con turistas» só existe para os países que Frontur separa.</li>
<li><b>Corrección por idade e sexo:</b> como Interior non dá a idade dos detidos, aplícase á pirámide de cada nacionalidade a curva de condenados por idade e sexo de España, e compárase o observado co esperado.</li>
<li>Hispanoamérica é América menos Brasil. Nas detencións inclúe EE. UU. e Canadá, que Interior non separa, pero na poboación quítanse: son uns 100.000 residentes fronte a case 4 millóns de hispanoamericanos. Só se amosan países con polo menos 15.000 residentes de 15 ou máis anos.</li>
<li>En 2020 entraron na estatística os Mossos d'Esquadra e en 2025 os investigados pola Ertzaintza: as cifras sobem de golpe eses anos para todas as nacionalidades.</li>
</ul>
</div>

### España en Europa

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

Eurostat reúne os condenados por nacionalidade que publican uns vinte países europeos. En {europa_espana[0]?.anio} a taxa de condenados dos estranxeiros en España era {formatNumber(europa_espana[0]?.veces, 1)} veces a dos españois, e {formatNumber(europa_espana[0]?.ajustado, 1)} veces corrixida por idade e sexo. Dos {formatNumber(europa_espana[0]?.paises, 0)} países con polo menos un 5 % de poboación estranxeira, {formatNumber(europa_espana[0]?.por_encima, 0)} teñen unha diferenza maior ca a de España (a mediana é {formatNumber(europa_espana[0]?.mediana, 1)} veces).

<BarChart
    data={europa}
    x=pais
    y=veces_edad_sexo
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0"×"'
    seriesColors={{'España': '#b91c1c', 'Otros países': '#9ca3af'}}
    yAxisTitle="veces a taxa dos nacionais, corrixida por idade e sexo"
    title="Condenados estranxeiros fronte a nacionais en Europa, corrixido por idade e sexo (último ano de cada país)"
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
    yAxisTitle="veces, corrixido por idade e sexo"
    title="Evolución nalgúns países: condenados estranxeiros fronte a nacionais, corrixido por idade e sexo"
/>

<DataTable data={europa} rows=all>
    <Column id=pais title="País" />
    <Column id=anio title="Ano" fmt="####" />
    <Column id=extranjeros_poblacion_pct title="Estranxeiros na poboación (15+)" fmt='0.0"%"' />
    <Column id=extranjeros_condenados_pct title="Estranxeiros entre os condenados" fmt='0.0"%"' />
    <Column id=veces title="Veces, sen axustar" fmt='0.0"×"' />
    <Column id=veces_edad_sexo title="Corrixido por idade e sexo" fmt='0.0"×"' />
    <Column id=veces_presos title="Presos: veces" fmt='0.0"×"' />
</DataTable>

<div class="not-prose rounded-lg border border-gray-300 bg-gray-50 dark:bg-gray-900/40 dark:border-gray-700 p-4 my-4 text-sm text-gray-800 dark:text-gray-100">
<p class="font-semibold mb-1">Como se fixo a comparación europea</p>
<ul class="list-disc ml-5 space-y-1">
<li>Condenados por nacionalidade de Eurostat (crim_just_ctz) divididos entre a poboación de 15 ou máis anos da mesma nacionalidade (migr_pop1ctz). Compárase «cantas veces» dentro de cada país, porque cada país conta as condenas á súa maneira (en Alemaña, por exemplo, inclúen delitos de estranxeiría que só pode cometer un estranxeiro; en España estar en situación irregular non é delito).</li>
<li>Eurostat non dá a idade dos condenados. Para corrixir por idade e sexo aplícase á pirámide de nacionais e estranxeiros de cada país a curva de condenados por idade e sexo de España. Así calcúlase cantos condenados cabería esperar en cada grupo só pola súa idade e o seu sexo. En España, este método dá {formatNumber(europa_espana[0]?.ajustado, 1)} veces, case o mesmo ca o axuste directo cos datos completos do INE.</li>
<li>Non se axusta por turistas en ningún país. España, Austria, Grecia ou Portugal reciben moitos visitantes por habitante, así que a súa cifra está algo máis inflada ca a doutros.</li>
<li>Só países con polo menos un 5 % de estranxeiros e con datos desde 2018. Queda fóra Letonia: alí a maioría dos «estranxeiros» son residentes de toda a vida sen nacionalidade letoa. «Presos: veces» compara os presos (incluídos os preventivos) da mesma forma, sen corrixir por idade.</li>
<li>Países como Suecia ou os Países Baixos non publican este dato en Eurostat. Ademais, alí moitos inmigrantes nacionalízanse axiña e deixan de contar como estranxeiros, igual que os nacionalizados en España contan como españois.</li>
</ul>
</div>

---

## Fontes e notas

- **[Ministerio do Interior – Portal Estatístico de Criminalidade](https://estadisticasdecriminalidad.ses.mir.es/)**: serie anual de infraccións penais coñecidas por comunidade e provincia desde 2010, e Balance de Criminalidade trimestral cos municipios de máis de 20.000 habitantes (ano completo desde 2019). En 2019 cambiou a clasificación do Balance, así que non se compara cos anos anteriores.
- **[INE – Estatística de Condenados: adultos](https://www.ine.es/jaxiT3/Tabla.htm?t=25704)** (táboas 25704 e 49050), a partir do Rexistro Central de Penados, **[INE – Condenados segundo sexo, idade e nacionalidade](https://www.ine.es/jaxiT3/Tabla.htm?t=25645)** (táboa 25645) para o axuste por idade, e **[INE – Estatística Continua de Poboación](https://www.ine.es/jaxiT3/Tabla.htm?t=56942)** (táboa 56942) para a poboación por nacionalidade, sexo e idade a 1 de xaneiro. Poboación de 18 ou máis anos e de cada tramo de idade aproximada a partir de grupos de idade de cinco anos.
- **[INE – Frontur](https://www.ine.es/jaxiT3/Tabla.htm?t=23987)** (táboas 23987 e 23984): visitantes non residentes segundo a duración da estadía e turistas por país de residencia, para estimar cantos hai en España nun día medio e de onde veñen.
- **[Ministerio do Interior – Detencións e investigados](https://estadisticasdecriminalidad.ses.mir.es/)** (táboas 03007 e 03001): detencións e investigados estranxeiros por nacionalidade e o total, e **[INE – Poboación por país de nacionalidade](https://www.ine.es/jaxiT3/Tabla.htm?t=56936)** (táboa 56936) para o denominador.
- **[Nacións Unidas – UNODC](https://dataunodc.un.org/)**: delitos rexistrados pola policía por tipo e presos en todos os países que responden á enquisa UN-CTS, e homicidios intencionados do **[Banco Mundial](https://data.worldbank.org/indicator/VC.IHR.PSRC.P5)** con datos de UNODC.
- **[Eurostat](https://ec.europa.eu/eurostat/databrowser/view/crim_just_ctz)**: condenados (crim_just_ctz) e presos (crim_pris_ctz) por nacionalidade en cada país europeo, e poboación por nacionalidade, sexo e idade (migr_pop1ctz).

<LastRefreshed prefix="Datos actualizados" />
