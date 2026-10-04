---
title: Health
description: "Life expectancy in Spain by region and province, what people die of, suicides, road deaths, excess mortality and the health system: waiting lists, doctors, nurses, beds and spending per person compared with the EU."
i18n_origen: 89c1708d4d47
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';

    $: le_q = san_le.filter(d => d.tipo === 'quirurgica');
    $: le_u = le_q[le_q.length - 1];
    $: fecha_txt_en = le_u ? (le_u.corte === 'junio' ? '30 June ' : '31 December ') + le_u.anio : '';
</script>

```sql ev_espana
SELECT anio, sexo, anios
FROM mother.salud_esperanza_vida
WHERE nivel = 'pais'
ORDER BY anio
```

```sql ev_ultimo
SELECT
    max(anio) AS anio,
    max(anios) FILTER (WHERE sexo = 'Ambos sexos') AS total,
    max(anios) FILTER (WHERE sexo = 'Mujeres') AS mujeres,
    max(anios) FILTER (WHERE sexo = 'Hombres') AS hombres
FROM ${ev_espana}
WHERE anio = (SELECT max(anio) FROM ${ev_espana})
```

```sql ev_serie
SELECT anio, anios AS valor FROM ${ev_espana} WHERE sexo = 'Ambos sexos' AND anio >= 2000 ORDER BY anio
```

```sql causas_clave
SELECT anio, codigo_causa, defunciones, tasa_100k
FROM mother.salud_causas_muerte
WHERE nivel = 'pais' AND sexo = 'Total' AND codigo_causa IN ('001-102', '098', '090', '099')
ORDER BY anio
```

```sql causas_ultimo
SELECT
    max(anio) AS anio,
    max(defunciones) FILTER (WHERE codigo_causa = '001-102') AS total,
    max(defunciones) FILTER (WHERE codigo_causa = '098') AS suicidios,
    max(tasa_100k) FILTER (WHERE codigo_causa = '098') AS suicidios_tasa,
    max(defunciones) FILTER (WHERE codigo_causa = '090') AS trafico,
    max(tasa_100k) FILTER (WHERE codigo_causa = '090') AS trafico_tasa,
    max(tasa_100k) FILTER (WHERE codigo_causa = '001-102') / 100 AS mortalidad_1000
FROM ${causas_clave}
WHERE anio = (SELECT max(anio) FROM ${causas_clave})
```

```sql exceso_anual
SELECT anio, sum(defunciones) AS defunciones, 100 * (sum(defunciones_por_100k_hab) / sum(media_2015_2019_por_100k_hab) - 1) AS exceso_hab_pct, count(*) AS semanas
FROM mother.salud_mortalidad_semanal
WHERE nivel = 'pais' AND anio >= 2015
GROUP BY anio
ORDER BY anio
```

# 🩺 Health

How long we live, what we die of and how things have changed, based on INE vital statistics. Further down, the <a href="#health-system">health system</a>: waiting lists, doctors, nurses, beds and spending.

<Grid cols=4>
    <KpiCard
        title="Life expectancy at birth"
        value={ev_ultimo[0]?.total}
        formattedValue="{formatNumber(ev_ultimo[0]?.total, 1)} years"
        period="women {formatNumber(ev_ultimo[0]?.mujeres, 1)} · men {formatNumber(ev_ultimo[0]?.hombres, 1)} · {ev_ultimo[0]?.anio}"
        source="INE / Eurostat"
        sparklineData={ev_serie}
    />
    <KpiCard
        title="Death rate"
        value={causas_ultimo[0]?.mortalidad_1000}
        formattedValue="{formatNumber(causas_ultimo[0]?.mortalidad_1000, 1)} per 1,000 pop."
        period="{formatNumber(causas_ultimo[0]?.total, 0)} deaths in {causas_ultimo[0]?.anio} · crude rate"
        source="INE"
        sparklineData={causas_clave.filter(d => d.codigo_causa === '001-102' && d.anio >= 2000).map(d => ({anio: d.anio, valor: d.tasa_100k / 100}))}
    />
    <KpiCard
        title="Suicides"
        value={causas_ultimo[0]?.suicidios_tasa}
        formattedValue="{formatNumber(causas_ultimo[0]?.suicidios_tasa, 1)} per 100,000 pop."
        period="{formatNumber(causas_ultimo[0]?.suicidios, 0)} in {causas_ultimo[0]?.anio} · leading external cause of death"
        source="INE"
        sparklineData={causas_clave.filter(d => d.codigo_causa === '098' && d.anio >= 2000).map(d => ({anio: d.anio, valor: d.tasa_100k}))}
    />
    <KpiCard
        title="Road traffic deaths"
        value={causas_ultimo[0]?.trafico_tasa}
        formattedValue="{formatNumber(causas_ultimo[0]?.trafico_tasa, 1)} per 100,000 pop."
        period="{formatNumber(causas_ultimo[0]?.trafico, 0)} residents killed in {causas_ultimo[0]?.anio}"
        source="INE"
        direction="positive-down"
        sparklineData={causas_clave.filter(d => d.codigo_causa === '090' && d.anio >= 2000).map(d => ({anio: d.anio, valor: d.tasa_100k}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('esperanza_vida', 'mortalidad_infantil', 'gasto_sanitario_pc_ppa', 'medicos', 'camas', 'suicidios')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'esperanza_vida')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'mortalidad_infantil')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'gasto_sanitario_pc_ppa')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'medicos')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'camas')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'suicidios')} />


<p class="text-xs text-gray-500">If you need help, or know someone who might, call <b>024</b>, Spain's suicide prevention helpline (free, confidential, 24 hours a day).</p>

## How long we live

<LineChart
    data={ev_espana}
    x=anio
    y=anios
    series=sexo
    yFmt=num1
    xFmt="####"
    legend=true
    colorPalette={['#0f766e', '#1d4ed8', '#be185d']}
    yAxisTitle="years"
    title="Life expectancy at birth in Spain"
/>

<p class="text-xs text-gray-500">The 2020 drop is the COVID-19 pandemic (more than a year of life expectancy lost); the 2019 level was not regained until 2023. Spain has one of the highest life expectancies in the world.</p>

```sql ev_provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, e.anios
FROM mother.salud_esperanza_vida e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
WHERE e.nivel = 'provincia' AND e.sexo = 'Ambos sexos'
  AND e.anio = (SELECT max(anio) FROM mother.salud_esperanza_vida WHERE nivel = 'provincia')
ORDER BY e.anios DESC
```

<MapaEspana
    data={ev_provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="anios"
    valueFmt="num1"
    colorPalette={['#fef3c7', '#5eead4', '#0f766e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: INE"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'anios', title: 'Life expectancy (years)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Life expectancy at birth by province of residence in {ev_ultimo[0]?.anio}. The highest figures are in Madrid and the northern interior; the lowest, in the south, the Canary Islands, Ceuta and Melilla.</p>

## What we die of

```sql capitulos
SELECT causa, defunciones, tasa_100k
FROM mother.salud_causas_muerte
WHERE nivel = 'pais' AND sexo = 'Total' AND tipo_causa = 'capitulo'
  AND anio = (SELECT max(anio) FROM mother.salud_causas_muerte)
ORDER BY defunciones DESC
LIMIT 10
```

<BarChart
    data={capitulos}
    x=causa
    y=tasa_100k
    swapXY=true
    sort=false
    yFmt=num0
    yAxisTitle="per 100,000 inhabitants"
    fillColor="#0f766e"
    title="Deaths by major cause group per 100,000 inhabitants ({causas_ultimo[0]?.anio})"
/>

```sql evolucion_capitulos
SELECT anio, causa, tasa_100k
FROM mother.salud_causas_muerte
WHERE nivel = 'pais' AND sexo = 'Total' AND codigo_causa IN ('009-041', '053-061', '062-067', '046-049', '090-102')
  AND anio >= 2000
ORDER BY anio
```

<LineChart
    data={evolucion_capitulos}
    x=anio
    y=tasa_100k
    series=causa
    yFmt=num0
    xFmt="####"
    legend=true
    yAxisTitle="per 100,000 inhabitants"
    title="Leading causes of death since 2000 (crude rate)"
/>

<p class="text-xs text-gray-500">In 2024, for the first time, cancers overtook diseases of the heart and blood vessels as the leading cause of death. Mental disorders are rising mainly because of dementia (Alzheimer's and others), linked to population ageing. These are crude rates: with an ever older population, they rise even if the probability of dying at each age falls.</p>

## Suicide, road deaths and homicide

```sql externas
SELECT anio,
    CASE codigo_causa WHEN '098' THEN 'Suicidios' WHEN '090' THEN 'Accidentes de tráfico' WHEN '099' THEN 'Homicidios' END AS causa,
    defunciones,
    tasa_100k
FROM ${causas_clave}
WHERE codigo_causa IN ('098', '090', '099') AND anio >= 1996
ORDER BY anio
```

<LineChart
    data={externas}
    x=anio
    y=tasa_100k
    series=causa
    yFmt=num1
    yAxisTitle="per 100,000 inhabitants"
    xFmt="####"
    legend=true
    colorPalette={['#f59e0b', '#7c3aed', '#b91c1c']}
    title="Deaths from suicide, road traffic accidents and homicide, per 100,000 inhabitants"
/>

<p class="text-xs text-gray-500">Since 2008 more people in Spain have died by suicide than in road traffic accidents, which have fallen to less than a third of their 2000 level. Figures are by the deceased's place of residence and based on the cause stated on the death certificate (the DGT's road death count, measured at 30 days, differs slightly).</p>

```sql suicidio_ccaa
SELECT c.cod, t.nombre AS comunidad, '/en' || t.ruta AS ruta,
    max(c.tasa_100k) FILTER (WHERE c.sexo = 'Total') AS tasa,
    max(c.tasa_100k) FILTER (WHERE c.sexo = 'Hombres') AS tasa_hombres,
    max(c.tasa_100k) FILTER (WHERE c.sexo = 'Mujeres') AS tasa_mujeres,
    max(c.defunciones) FILTER (WHERE c.sexo = 'Total') AS defunciones
FROM mother.salud_causas_muerte c
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = c.cod
WHERE c.nivel = 'ccaa' AND c.codigo_causa = '098' AND c.anio = (SELECT max(anio) FROM mother.salud_causas_muerte)
GROUP BY ALL
ORDER BY tasa DESC
```

<DataTable data={suicidio_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=defunciones title="Suicides" fmt=num0 />
    <Column id=tasa title="Per 100,000 pop." fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=tasa_hombres title="Men" fmt=num1 />
    <Column id=tasa_mujeres title="Women" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">Three out of four suicides are men. The highest rates are in the north-west (Asturias, Galicia), where the population is older.</p>

## Excess mortality

<BarChart
    data={exceso_anual}
    x=anio
    y=exceso_hab_pct
    yFmt='0"%"'
    xFmt="####"
    fillColor="#b91c1c"
    title="Deaths per inhabitant each year compared with the 2015-2019 average"
/>

```sql semanal
SELECT fecha, defunciones_por_100k_hab, media_2015_2019_por_100k_hab
FROM mother.salud_mortalidad_semanal
WHERE nivel = 'pais' AND fecha >= (SELECT max(fecha) FROM mother.salud_mortalidad_semanal) - INTERVAL 3 YEAR
ORDER BY fecha
```

<LineChart
    data={semanal}
    x=fecha
    y={['defunciones_por_100k_hab', 'media_2015_2019_por_100k_hab']}
    yFmt=num0
    seriesLabels={{defunciones_por_100k_hab: 'Deaths', media_2015_2019_por_100k_hab: 'Average for the same week in 2015-2019'}}
    colorPalette={['#b91c1c', '#94a3b8']}
    legend=true
    title="Deaths per 100,000 inhabitants week by week (last three years)"
/>

<p class="text-xs text-gray-500">The comparison with 2015-2019 is made per inhabitant, so it already discounts a population that grows larger every year, but it does not adjust for a population that grows older, so since 2023 part of the "excess" is simply ageing. The peaks coincide with winter flu seasons and with heatwaves (see <a href="/en/energia-clima/calor">Heat</a>). The most recent weeks may be incomplete.</p>

```sql san_le
SELECT fecha, CAST(anio AS INTEGER) AS anio, corte, tipo, pacientes, tasa_1000, pct_espera_larga, dias_medio
FROM mother.sanidad_listas_espera
WHERE nivel = 'pais'
ORDER BY fecha
```

```sql san_le_ultimo
WITH q AS (SELECT * FROM mother.sanidad_listas_espera WHERE nivel = 'pais' AND tipo = 'quirurgica'),
c AS (SELECT * FROM mother.sanidad_listas_espera WHERE nivel = 'pais' AND tipo = 'consultas'),
uq AS (SELECT * FROM q WHERE fecha = (SELECT max(fecha) FROM q)),
aq AS (SELECT * FROM q WHERE fecha = (SELECT max(fecha) - INTERVAL 1 YEAR FROM q)),
pq AS (SELECT * FROM q WHERE fecha = (SELECT min(fecha) FROM q)),
uc AS (SELECT * FROM c WHERE fecha = (SELECT max(fecha) FROM c)),
ac AS (SELECT * FROM c WHERE fecha = (SELECT max(fecha) - INTERVAL 1 YEAR FROM c))
SELECT
    CASE WHEN uq.corte = 'junio' THEN '30 de junio de ' ELSE '31 de diciembre de ' END || CAST(uq.anio AS INTEGER) AS fecha_txt,
    CASE WHEN uq.corte = 'junio' THEN 'junio de ' ELSE 'diciembre de ' END || CAST(uq.anio - 1 AS INTEGER) AS fecha_ant_txt,
    uq.pacientes, uq.tasa_1000, uq.pct_espera_larga, uq.dias_medio,
    round(uq.tasa_1000 - aq.tasa_1000, 2) AS tasa_var,
    round(uq.dias_medio - aq.dias_medio, 0) AS dias_var,
    CAST(pq.anio AS INTEGER) AS anio_ini, pq.tasa_1000 AS tasa_ini, pq.dias_medio AS dias_ini, pq.pct_espera_larga AS pct_ini,
    uc.tasa_1000 AS c_tasa, uc.dias_medio AS c_dias, uc.pct_espera_larga AS c_pct,
    round(uc.dias_medio - ac.dias_medio, 0) AS c_dias_var
FROM uq, aq, pq, uc, ac
```

```sql san_le_dias
SELECT fecha,
    CASE tipo WHEN 'quirurgica' THEN 'Operación programada' ELSE 'Primera consulta con el especialista' END AS lista,
    dias_medio
FROM mother.sanidad_listas_espera
WHERE nivel = 'pais'
ORDER BY fecha
```

```sql san_le_ccaa
SELECT t.nombre AS comunidad, '/en' || t.ruta AS ruta,
    max(l.tasa_1000) FILTER (WHERE l.tipo = 'quirurgica') AS q_tasa,
    max(l.dias_medio) FILTER (WHERE l.tipo = 'quirurgica') AS q_dias,
    max(l.pct_espera_larga) FILTER (WHERE l.tipo = 'quirurgica') / 100 AS q_pct,
    max(l.tasa_1000) FILTER (WHERE l.tipo = 'consultas') AS c_tasa,
    max(l.dias_medio) FILTER (WHERE l.tipo = 'consultas') AS c_dias,
    max(l.pct_espera_larga) FILTER (WHERE l.tipo = 'consultas') / 100 AS c_pct
FROM mother.sanidad_listas_espera l
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = l.cod
WHERE l.nivel = 'ccaa' AND l.fecha = (SELECT max(fecha) FROM mother.sanidad_listas_espera)
GROUP BY ALL
ORDER BY q_dias DESC
```

```sql san_le_extremos
SELECT
    arg_max(comunidad, q_dias) AS max_com, max(q_dias) AS max_dias,
    arg_min(comunidad, q_dias) AS min_com, min(q_dias) AS min_dias
FROM ${san_le_ccaa}
```

```sql san_le_esp
SELECT especialidad, tasa_1000, pct_espera_larga / 100 AS pct, dias_medio
FROM mother.sanidad_listas_especialidad
WHERE tipo = 'quirurgica' AND fecha = (SELECT max(fecha) FROM mother.sanidad_listas_especialidad)
ORDER BY dias_medio DESC
```

```sql san_le_esp_cons
SELECT especialidad, tasa_1000, pct_espera_larga / 100 AS pct, dias_medio
FROM mother.sanidad_listas_especialidad
WHERE tipo = 'consultas' AND fecha = (SELECT max(fecha) FROM mother.sanidad_listas_especialidad)
ORDER BY dias_medio DESC
```

```sql san_rec
SELECT anio, cod_pais, recurso,
    CASE recurso WHEN 'medicos' THEN 'Médicos' WHEN 'enfermeras' THEN 'Enfermeras' ELSE 'Camas' END
        || CASE WHEN cod_pais = 'ES' THEN ' · España' ELSE ' · media UE-27' END AS serie,
    por_1000
FROM mother.sanidad_recursos
WHERE cod_pais IN ('ES', 'EU27_2020') AND anio >= 2000
ORDER BY anio
```

```sql san_rec_ultimo
WITH es AS (SELECT recurso, max(anio) AS anio FROM mother.sanidad_recursos WHERE cod_pais = 'ES' GROUP BY recurso)
SELECT e.recurso, CAST(e.anio AS INTEGER) AS anio, r.por_1000 AS es, r.numero AS numero_es, u.por_1000 AS ue, u.n_paises
FROM es e
JOIN mother.sanidad_recursos r ON r.cod_pais = 'ES' AND r.recurso = e.recurso AND r.anio = e.anio
LEFT JOIN mother.sanidad_recursos u ON u.cod_pais = 'EU27_2020' AND u.recurso = e.recurso AND u.anio = e.anio
```

```sql san_rec_paises
WITH ultimo AS (
    SELECT cod_pais, recurso, max(anio) AS anio
    FROM mother.sanidad_recursos
    WHERE nivel = 'pais' AND anio <= (SELECT max(anio) FROM mother.sanidad_recursos WHERE cod_pais = 'ES')
    GROUP BY ALL
)
SELECT r.pais,
    max(r.por_1000) FILTER (WHERE r.recurso = 'medicos') AS medicos,
    max(r.por_1000) FILTER (WHERE r.recurso = 'enfermeras') AS enfermeras,
    max(r.por_1000) FILTER (WHERE r.recurso = 'camas') AS camas,
    CAST(max(r.anio) AS INTEGER) AS anio
FROM mother.sanidad_recursos r
JOIN ultimo u ON u.cod_pais = r.cod_pais AND u.recurso = r.recurso AND u.anio = r.anio
GROUP BY ALL
ORDER BY medicos DESC NULLS LAST
```

```sql san_rec_rango
SELECT
    count(*) FILTER (WHERE enfermeras IS NOT NULL) AS n_enf,
    count(*) FILTER (WHERE enfermeras > (SELECT enfermeras FROM ${san_rec_paises} WHERE pais = 'España')) + 1 AS puesto_enf,
    count(*) FILTER (WHERE camas IS NOT NULL) AS n_camas,
    count(*) FILTER (WHERE camas > (SELECT camas FROM ${san_rec_paises} WHERE pais = 'España')) + 1 AS puesto_camas
FROM ${san_rec_paises}
```

```sql san_rec_ccaa
SELECT t.nombre AS comunidad, '/en' || t.ruta AS ruta,
    max(r.por_1000) FILTER (WHERE r.recurso = 'medicos') AS medicos,
    max(r.por_1000) FILTER (WHERE r.recurso = 'camas') AS camas,
    CAST(max(r.anio) AS INTEGER) AS anio
FROM mother.sanidad_recursos_ccaa r
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = r.cod
WHERE r.nivel = 'ccaa' AND r.anio = (SELECT max(anio) FROM mother.sanidad_recursos_ccaa WHERE nivel = 'ccaa')
GROUP BY ALL
ORDER BY medicos DESC
```

```sql san_gasto_es
SELECT anio, financiacion, pct_pib, eur_hab_real, CAST(anio_base AS INTEGER) AS anio_base
FROM mother.sanidad_gasto
WHERE cod_pais = 'ES'
ORDER BY anio
```

```sql san_gasto_ultimo
WITH es AS (SELECT * FROM mother.sanidad_gasto WHERE cod_pais = 'ES'),
ue AS (SELECT * FROM mother.sanidad_gasto WHERE cod_pais = 'EU27_2020'),
u AS (SELECT max(anio) AS anio FROM es WHERE financiacion = 'Total'),
uu AS (SELECT max(anio) AS anio FROM ue WHERE financiacion = 'Total')
SELECT
    CAST((SELECT anio FROM u) AS INTEGER) AS anio,
    CAST((SELECT anio FROM uu) AS INTEGER) AS anio_ue,
    max(es.eur_hab_real) FILTER (WHERE es.financiacion = 'Público' AND es.anio = (SELECT anio FROM u)) AS pub_real,
    max(es.pct_pib) FILTER (WHERE es.financiacion = 'Público' AND es.anio = (SELECT anio FROM u)) AS pub_pib,
    max(es.pct_pib) FILTER (WHERE es.financiacion = 'Total' AND es.anio = (SELECT anio FROM u)) AS tot_pib,
    max(es.eur_hab_real) FILTER (WHERE es.financiacion = 'Pago directo de los hogares' AND es.anio = (SELECT anio FROM u)) AS hog_real,
    max(es.eur_hab_real) FILTER (WHERE es.financiacion = 'Seguros voluntarios' AND es.anio = (SELECT anio FROM u)) AS seg_real,
    max(es.eur_hab_real) FILTER (WHERE es.financiacion = 'Total' AND es.anio = (SELECT anio FROM u)) AS tot_real,
    max(es.pct_pib) FILTER (WHERE es.financiacion = 'Público' AND es.anio = (SELECT anio FROM uu)) AS pub_pib_es_uu,
    max(es.pct_pib) FILTER (WHERE es.financiacion = 'Total' AND es.anio = (SELECT anio FROM uu)) AS tot_pib_es_uu,
    (SELECT pct_pib FROM ue WHERE financiacion = 'Público' AND anio = (SELECT anio FROM uu)) AS pub_pib_ue,
    (SELECT pct_pib FROM ue WHERE financiacion = 'Total' AND anio = (SELECT anio FROM uu)) AS tot_pib_ue,
    100 * max(es.eur_hab_real) FILTER (WHERE es.financiacion = 'Público' AND es.anio = (SELECT anio FROM u))
        / max(es.eur_hab_real) FILTER (WHERE es.financiacion = 'Total' AND es.anio = (SELECT anio FROM u)) AS pub_peso,
    CAST(max(es.anio_base) AS INTEGER) AS anio_base
FROM es
```

```sql san_gasto_pib
SELECT anio,
    CASE WHEN financiacion = 'Público' THEN 'Público' ELSE 'Privado' END || ' · ' || pais AS serie,
    sum(pct_pib) AS pct_pib
FROM mother.sanidad_gasto
WHERE cod_pais IN ('ES', 'EU27_2020') AND financiacion IN ('Público', 'Seguros voluntarios', 'Pago directo de los hogares')
GROUP BY ALL
ORDER BY anio, serie
```

```sql san_gasto_paises
SELECT pais, pps_hab,
    CASE WHEN cod_pais = 'ES' THEN 'España' WHEN cod_pais = 'EU27_2020' THEN 'Media UE-27' ELSE 'Resto de países' END AS grupo
FROM mother.sanidad_gasto
WHERE financiacion = 'Total' AND pps_hab IS NOT NULL
  AND anio = (SELECT max(anio) FROM mother.sanidad_gasto WHERE cod_pais = 'EU27_2020' AND financiacion = 'Total' AND pps_hab IS NOT NULL)
ORDER BY pps_hab DESC
```

```sql san_gasto_ccaa
SELECT t.nombre AS comunidad, '/en' || t.ruta AS ruta, g.eur_hab_real, g.pct_pib,
    g.eur_hab_real / b.eur_hab_real - 1 AS var_2019,
    CAST(g.anio AS INTEGER) AS anio, g.provisional
FROM mother.sanidad_gasto_ccaa g
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = g.cod
JOIN mother.sanidad_gasto_ccaa b ON b.cod = g.cod AND b.anio = 2019
WHERE g.nivel = 'ccaa' AND g.anio = (SELECT max(anio) FROM mother.sanidad_gasto_ccaa)
ORDER BY g.eur_hab_real DESC
```

```sql san_gasto_ccaa_total
SELECT CAST(g.anio AS INTEGER) AS anio, g.eur_hab_real, g.provisional,
    (SELECT max(eur_hab_real) FROM ${san_gasto_ccaa}) AS max_real,
    (SELECT min(eur_hab_real) FROM ${san_gasto_ccaa}) AS min_real,
    (SELECT arg_max(comunidad, eur_hab_real) FROM ${san_gasto_ccaa}) AS max_com,
    (SELECT arg_min(comunidad, eur_hab_real) FROM ${san_gasto_ccaa}) AS min_com
FROM mother.sanidad_gasto_ccaa g
WHERE g.nivel = 'total_ccaa' AND g.anio = (SELECT max(anio) FROM mother.sanidad_gasto_ccaa)
```

## Health system

How long people wait for surgery or to see a specialist in the public health service, how many doctors, nurses and beds there are per inhabitant and how much is spent on health, compared with the rest of the European Union.

<Grid cols=4>
    <KpiCard
        title="Surgical waiting list"
        value={san_le_ultimo[0]?.tasa_1000}
        formattedValue="{formatNumber(san_le_ultimo[0]?.tasa_1000, 1)} per 1,000 pop."
        period="{formatNumber(san_le_ultimo[0]?.pacientes, 0)} patients at {fecha_txt_en}"
        change={san_le_ultimo[0]?.tasa_var}
        changeUnit=""
        changePeriod="vs a year earlier"
        direction="positive-down"
        source="Ministry of Health (SISLE)"
        sparklineData={san_le.filter(d => d.tipo === 'quirurgica').map(d => ({valor: d.tasa_1000}))}
    />
    <KpiCard
        title="Average wait for surgery"
        value={san_le_ultimo[0]?.dias_medio}
        formattedValue="{formatNumber(san_le_ultimo[0]?.dias_medio, 0)} days"
        period="{formatNumber(san_le_ultimo[0]?.pct_espera_larga, 1)} % waiting more than 6 months"
        change={san_le_ultimo[0]?.dias_var}
        changeUnit="days"
        changePeriod="in one year"
        direction="positive-down"
        source="Ministry of Health (SISLE)"
        sparklineData={san_le.filter(d => d.tipo === 'quirurgica').map(d => ({valor: d.dias_medio}))}
    />
    <KpiCard
        title="Average wait to see a specialist"
        value={san_le_ultimo[0]?.c_dias}
        formattedValue="{formatNumber(san_le_ultimo[0]?.c_dias, 0)} days"
        period="first appointment · {formatNumber(san_le_ultimo[0]?.c_pct, 1)} % wait more than 60 days"
        change={san_le_ultimo[0]?.c_dias_var}
        changeUnit="days"
        changePeriod="in one year"
        direction="positive-down"
        source="Ministry of Health (SISLE)"
        sparklineData={san_le.filter(d => d.tipo === 'consultas').map(d => ({valor: d.dias_medio}))}
    />
    <KpiCard
        title="Public health spending"
        value={san_gasto_ultimo[0]?.pub_real}
        formattedValue="€{formatNumber(san_gasto_ultimo[0]?.pub_real, 0)} per person"
        period="{formatNumber(san_gasto_ultimo[0]?.pub_pib, 1)} % of GDP in {san_gasto_ultimo[0]?.anio} · {san_gasto_ultimo[0]?.anio_base} euros"
        source="Eurostat"
        sparklineData={san_gasto_es.filter(d => d.financiacion === 'Público').map(d => ({valor: d.eur_hab_real}))}
    />
    <KpiCard
        title="Doctors"
        value={san_rec_ultimo.find(d => d.recurso === 'medicos')?.es}
        formattedValue="{formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.es, 1)} per 1,000 pop."
        period="EU average: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.ue, 1)} · {san_rec_ultimo.find(d => d.recurso === 'medicos')?.anio}"
        source="Eurostat"
        sparklineData={san_rec.filter(d => d.cod_pais === 'ES' && d.recurso === 'medicos').map(d => ({valor: d.por_1000}))}
    />
    <KpiCard
        title="Nurses"
        value={san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.es}
        formattedValue="{formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.es, 1)} per 1,000 pop."
        period="EU average: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.ue, 1)} · {san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.anio}"
        source="Eurostat"
        sparklineData={san_rec.filter(d => d.cod_pais === 'ES' && d.recurso === 'enfermeras').map(d => ({valor: d.por_1000}))}
    />
    <KpiCard
        title="Hospital beds"
        value={san_rec_ultimo.find(d => d.recurso === 'camas')?.es}
        formattedValue="{formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.es, 1)} per 1,000 pop."
        period="EU average: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.ue, 1)} · {san_rec_ultimo.find(d => d.recurso === 'camas')?.anio}"
        source="Eurostat"
        sparklineData={san_rec.filter(d => d.cod_pais === 'ES' && d.recurso === 'camas').map(d => ({valor: d.por_1000}))}
    />
    <KpiCard
        title="Out-of-pocket payments by households"
        value={san_gasto_ultimo[0]?.hog_real}
        formattedValue="€{formatNumber(san_gasto_ultimo[0]?.hog_real, 0)} per person"
        period="paid directly in {san_gasto_ultimo[0]?.anio} (pharmacy, dentist, private appointments...) · plus €{formatNumber(san_gasto_ultimo[0]?.seg_real, 0)} on insurance"
        source="Eurostat"
        sparklineData={san_gasto_es.filter(d => d.financiacion === 'Pago directo de los hogares').map(d => ({valor: d.eur_hab_real}))}
    />
</Grid>

### Waiting lists

At {fecha_txt_en}, {formatNumber(san_le_ultimo[0]?.tasa_1000, 1)} people per 1,000 inhabitants were waiting for a scheduled operation in the public health service, compared with {formatNumber(san_le_ultimo[0]?.tasa_ini, 1)} in December {san_le_ultimo[0]?.anio_ini}. The average wait was {formatNumber(san_le_ultimo[0]?.dias_medio, 0)} days for surgery and {formatNumber(san_le_ultimo[0]?.c_dias, 0)} days for a first appointment with a specialist.

<BarChart
    data={san_le.filter(d => d.tipo === 'quirurgica')}
    x=fecha
    y=tasa_1000
    yFmt=num1
    fillColor="#0f766e"
    yAxisTitle="per 1,000 inhabitants"
    title="Patients on the surgical waiting list per 1,000 inhabitants (30 June and 31 December)"
/>

<LineChart
    data={san_le_dias}
    x=fecha
    y=dias_medio
    series=lista
    yFmt=num0
    legend=true
    colorPalette={['#0f766e', '#7c3aed']}
    yAxisTitle="days"
    title="Average waiting time in the National Health System"
/>

<p class="text-xs text-gray-500">Structural waiting: patients awaiting a non-urgent operation or a first outpatient appointment in specialised care whose wait is attributable to the organisation and resources of the system (primary care is not included). The average time is how long those still on the list on the reference date have been waiting; the rate is calculated on the population holding a health card. Each region supplies its data and the Ministry of Health aggregates them; criteria have changed over time: until June 2016 one region's data were estimated, in 2018 Andalusia changed its counting system (a break in the series, according to the ministry) and in recent editions the share of appointments over 60 days includes patients who do not yet have an appointment date. The 2020 peak coincides with the COVID-19 pandemic.</p>

<DataTable data={san_le_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=q_tasa title="Surgery: per 1,000 pop." fmt=num1 />
    <Column id=q_dias title="Surgery: days" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=q_pct title="Surgery: over 6 months" fmt=pct1 />
    <Column id=c_tasa title="Specialist: per 1,000 pop." fmt=num1 />
    <Column id=c_dias title="Specialist: days" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=c_pct title="Specialist: over 60 days" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Situation at {fecha_txt_en}. The average wait for surgery ranges from {formatNumber(san_le_extremos[0]?.min_dias, 0)} days in {san_le_extremos[0]?.min_com} to {formatNumber(san_le_extremos[0]?.max_dias, 0)} in {san_le_extremos[0]?.max_com}. Regions do not count their patients in the same way (the ministry warns that each one is responsible for its own data), so differences between them should be read with caution.</p>

<BarChart
    data={san_le_esp}
    x=especialidad
    y=dias_medio
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    yAxisTitle="days"
    title="Average wait for surgery by specialty ({fecha_txt_en})"
/>

<DataTable data={san_le_esp_cons} rows=all>
    <Column id=especialidad title="Outpatient appointments: specialty" />
    <Column id=tasa_1000 title="Patients per 1,000 pop." fmt=num2 />
    <Column id=dias_medio title="Days waiting" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=pct title="Over 60 days" fmt=pct1 />
</DataTable>

### Doctors, nurses and beds

<LineChart
    data={san_rec.filter(d => d.recurso !== 'camas')}
    x=anio
    y=por_1000
    series=serie
    yFmt=num1
    xFmt="####"
    legend=true
    colorPalette={['#b45309', '#fcd34d', '#1d4ed8', '#93c5fd']}
    yAxisTitle="per 1,000 inhabitants"
    title="Practising doctors and nurses per 1,000 inhabitants: Spain and EU average"
/>

<LineChart
    data={san_rec.filter(d => d.recurso === 'camas')}
    x=anio
    y=por_1000
    series=serie
    yFmt=num1
    xFmt="####"
    legend=true
    colorPalette={['#0f766e', '#94a3b8']}
    yAxisTitle="per 1,000 inhabitants"
    title="Hospital beds per 1,000 inhabitants: Spain and EU average"
/>

<p class="text-xs text-gray-500">In {san_rec_ultimo.find(d => d.recurso === 'medicos')?.anio} Spain had {formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.es, 1)} practising doctors per 1,000 inhabitants ({#if san_rec_ultimo.find(d => d.recurso === 'medicos')?.es > san_rec_ultimo.find(d => d.recurso === 'medicos')?.ue}above{:else}below{/if} the EU average of {formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.ue, 1)}), {formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.es, 1)} nurses (EU average: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.ue, 1)}; ranked {san_rec_rango[0]?.puesto_enf} of {san_rec_rango[0]?.n_enf} countries with data) and {formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.es, 1)} hospital beds (EU average: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.ue, 1)}; ranked {san_rec_rango[0]?.puesto_camas} of {san_rec_rango[0]?.n_camas}). The EU average is population-weighted and is only calculated for years in which at least 24 countries report; where a country does not report practising staff, professionally active staff are used instead, so comparisons are approximate.</p>

<DataTable data={san_rec_paises} rows=all>
    <Column id=pais title="Country" />
    <Column id=medicos title="Doctors per 1,000 pop." fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=enfermeras title="Nurses per 1,000 pop." fmt=num1 contentType=bar barColor="#bfdbfe" />
    <Column id=camas title="Beds per 1,000 pop." fmt=num1 contentType=bar barColor="#99f6e4" />
    <Column id=anio title="Year" fmt="####" />
</DataTable>

<DataTable data={san_rec_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=medicos title="Doctors per 1,000 pop." fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=camas title="Hospital beds per 1,000 pop." fmt=num1 contentType=bar barColor="#99f6e4" />
</DataTable>

<p class="text-xs text-gray-500">Doctors and beds (public and private) by region in {san_rec_ccaa[0]?.anio}, according to Eurostat. These are the resources located in each region, which also treat patients from other regions.</p>

### How much is spent on health

In {san_gasto_ultimo[0]?.anio} total health spending in Spain was €{formatNumber(san_gasto_ultimo[0]?.tot_real, 0)} per person ({san_gasto_ultimo[0]?.anio_base} euros), {formatNumber(san_gasto_ultimo[0]?.tot_pib, 1)} % of GDP. Government paid {formatNumber(san_gasto_ultimo[0]?.pub_peso, 0)} %; the rest came out of households' own pockets or from private insurance. In {san_gasto_ultimo[0]?.anio_ue}, the latest year with European data, public spending was {formatNumber(san_gasto_ultimo[0]?.pub_pib_es_uu, 1)} % of GDP in Spain and {formatNumber(san_gasto_ultimo[0]?.pub_pib_ue, 1)} % on average across the EU.

<BarChart
    data={san_gasto_es.filter(d => d.financiacion !== 'Total')}
    x=anio
    y=eur_hab_real
    series=financiacion
    type=stacked
    xFmt="####"
    yFmt='#,##0" €"'
    colorPalette={['#0f766e', '#f59e0b', '#7c3aed']}
    legend=true
    yAxisTitle="euros per person"
    title="Health spending per person by who pays ({san_gasto_ultimo[0]?.anio_base} euros, adjusted for inflation)"
/>

<LineChart
    data={san_gasto_pib}
    x=anio
    y=pct_pib
    series=serie
    yFmt='0.0"%"'
    xFmt="####"
    legend=true
    colorPalette={['#b45309', '#fcd34d', '#0f766e', '#99f6e4']}
    yAxisTitle="% of GDP"
    title="Public and private health spending as % of GDP: Spain and EU-27"
/>

<BarChart
    data={san_gasto_paises}
    x=pais
    y=pps_hab
    series=grupo
    swapXY=true
    sort=false
    yFmt=num0
    colorPalette={['#94a3b8', '#b91c1c', '#1d4ed8']}
    yAxisTitle="PPS per person"
    title="Total health spending per person in the EU ({san_gasto_ultimo[0]?.anio_ue}, in purchasing power standards)"
/>

<p class="text-xs text-gray-500">Current health expenditure according to Eurostat's health accounts (SHA 2011). Public includes government and compulsory social insurance (including civil servants' mutual insurance schemes); private covers voluntary insurance and out-of-pocket payments by households. The cross-country comparison uses purchasing power standards (PPS), which remove differences in price levels.</p>

<DataTable data={san_gasto_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=eur_hab_real title="Public health spending per person (€)" fmt='#,##0' contentType=bar barColor="#99f6e4" />
    <Column id=pct_pib title="% of regional GDP" fmt='0.0"%"' />
    <Column id=var_2019 title="Real change since 2019" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Health spending by each autonomous community per person in {san_gasto_ccaa_total[0]?.anio}{#if san_gasto_ccaa_total[0]?.provisional} (provisional figures){/if}, in {san_gasto_ultimo[0]?.anio_base} euros: from €{formatNumber(san_gasto_ccaa_total[0]?.min_real, 0)} in {san_gasto_ccaa_total[0]?.min_com} to €{formatNumber(san_gasto_ccaa_total[0]?.max_real, 0)} in {san_gasto_ccaa_total[0]?.max_com}; €{formatNumber(san_gasto_ccaa_total[0]?.eur_hab_real, 0)} across all regions. This is spending by the regional health services (Ministry of Health's Public Health Expenditure Statistics), more than 90 % of public health spending; it does not include civil servants' mutual insurance schemes or local councils. Ceuta and Melilla do not appear because their health care is run by central government (INGESA).</p>

---

## Sources and notes

- **[INE – Basic demographic indicators](https://www.ine.es/jaxiT3/Tabla.htm?t=1448)**: life expectancy at birth by region (table 1448) and province (1485); **[Eurostat – demo_mlexpec](https://ec.europa.eu/eurostat/databrowser/view/demo_mlexpec/default/table)** for the Spain total.
- **[INE – Deaths by cause of death](https://www.ine.es/jaxiT3/Tabla.htm?t=9936)** (table 9936, short list of causes by province of residence, since 1980; the latest published year is final, with a one-year lag).
- **[INE – Weekly Death Estimates (EDeS)](https://www.ine.es/jaxiT3/Tabla.htm?t=35177)** (table 35177): deaths by week and region.
- **[Ministry of Health – NHS waiting lists (SISLE-SNS)](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEspera.htm)**: half-yearly reports (30 June and 31 December) on surgical and outpatient waiting lists by region and specialty, since December 2013 ([archive](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEsperaInfAnt.htm)). The ministry only publishes them as PDFs; the figures are read from their tables.
- **[Ministry of Health – Public Health Expenditure Statistics](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/gastoSanitario2005/home.htm)**: public health spending by autonomous community (euros per person and % of GDP, annexes I.1 and I.2).
- **[Eurostat – hlth_rs_prs2](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_prs2/default/table)** (doctors and nurses), **[hlth_rs_bds1](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_bds1/default/table)** (hospital beds), **[hlth_rs_physreg](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_physreg/default/table)** and **[hlth_rs_bdsrg2](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_bdsrg2/default/table)** (by region) and **[hlth_sha11_hf](https://ec.europa.eu/eurostat/databrowser/view/hlth_sha11_hf/default/table)** (health spending by financing scheme). Spain's euros per person are adjusted for inflation using INE's CPI.
- Health spending as part of total government spending is covered in [Public spending](/en/cuentas-publicas/gastos).

<LastRefreshed prefix="Data updated" />
