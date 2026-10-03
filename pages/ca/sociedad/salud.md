---
title: Salut
description: "Esperança de vida a Espanya per comunitat i província, de què es mor la gent, suïcidis, accidents de trànsit, excés de mortalitat i el sistema sanitari: llistes d'espera, metges, infermeres, llits i despesa per habitant davant la UE."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 997db93797ae
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // Les dates de tall arriben de SQL en castellà ('30 de junio de 2025')
    const fechaCa = (s) => s == null ? s : String(s).replace('junio', 'juny').replace('diciembre', 'desembre');
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
SELECT anio, sum(defunciones) AS defunciones, sum(defunciones) / sum(media_2015_2019) - 1 AS exceso, count(*) AS semanas
FROM mother.salud_mortalidad_semanal
WHERE nivel = 'pais' AND anio >= 2015
GROUP BY anio
ORDER BY anio
```

# 🩺 Salut

Quant vivim, de què morim i com han canviat les coses, amb les estadístiques vitals de l'INE. Més avall, el <a href="#sistema-sanitari">sistema sanitari</a>: llistes d'espera, metges, infermeres, llits i despesa.

<Grid cols=4>
    <KpiCard
        title="Esperança de vida en néixer"
        value={ev_ultimo[0]?.total}
        formattedValue="{formatNumber(ev_ultimo[0]?.total, 1)} anys"
        period="dones {formatNumber(ev_ultimo[0]?.mujeres, 1)} · homes {formatNumber(ev_ultimo[0]?.hombres, 1)} · {ev_ultimo[0]?.anio}"
        source="INE / Eurostat"
        sparklineData={ev_serie}
    />
    <KpiCard
        title="Taxa de mortalitat"
        value={causas_ultimo[0]?.mortalidad_1000}
        formattedValue="{formatNumber(causas_ultimo[0]?.mortalidad_1000, 1)} per 1.000 hab."
        period="{formatNumber(causas_ultimo[0]?.total, 0)} defuncions el {causas_ultimo[0]?.anio} · taxa bruta"
        source="INE"
        sparklineData={causas_clave.filter(d => d.codigo_causa === '001-102' && d.anio >= 2000).map(d => ({anio: d.anio, valor: d.tasa_100k / 100}))}
    />
    <KpiCard
        title="Suïcidis"
        value={causas_ultimo[0]?.suicidios_tasa}
        formattedValue="{formatNumber(causas_ultimo[0]?.suicidios_tasa, 1)} per 100.000 hab."
        period="{formatNumber(causas_ultimo[0]?.suicidios, 0)} el {causas_ultimo[0]?.anio} · primera causa externa de mort"
        source="INE"
        sparklineData={causas_clave.filter(d => d.codigo_causa === '098' && d.anio >= 2000).map(d => ({anio: d.anio, valor: d.tasa_100k}))}
    />
    <KpiCard
        title="Morts en accidents de trànsit"
        value={causas_ultimo[0]?.trafico_tasa}
        formattedValue="{formatNumber(causas_ultimo[0]?.trafico_tasa, 1)} per 100.000 hab."
        period="{formatNumber(causas_ultimo[0]?.trafico, 0)} residents morts el {causas_ultimo[0]?.anio}"
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


<p class="text-xs text-gray-500">Si necessites ajuda o coneixes algú que la pugui necessitar, truca al <b>024</b>, la línia d'atenció a la conducta suïcida (gratuïta, confidencial, 24 hores).</p>

## Quant vivim

<LineChart
    data={ev_espana}
    x=anio
    y=anios
    series=sexo
    yFmt=num1
    xFmt="####"
    legend=true
    colorPalette={['#0f766e', '#1d4ed8', '#be185d']}
    yAxisTitle="anys"
    title="Esperança de vida en néixer a Espanya"
/>

<p class="text-xs text-gray-500">La caiguda del 2020 és la pandèmia de COVID-19 (més d'un any d'esperança de vida perdut); no es va recuperar el nivell del 2019 fins al 2023. Espanya és entre els països amb més esperança de vida del món.</p>

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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'anios', title: 'Esperança de vida (anys)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Esperança de vida en néixer per província de residència el {ev_ultimo[0]?.anio}. Les més altes són a Madrid i a l'interior nord; les més baixes, al sud, a les Canàries, a Ceuta i a Melilla.</p>

## De què morim

```sql capitulos
SELECT causa, defunciones, tasa_100k
FROM mother.salud_causas_muerte
WHERE nivel = 'pais' AND sexo = 'Total' AND es_capitulo AND codigo_causa <> '001-102'
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
    yAxisTitle="per 100.000 habitants"
    fillColor="#0f766e"
    title="Defuncions per grans grups de causes per 100.000 habitants ({causas_ultimo[0]?.anio})"
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
    yAxisTitle="per 100.000 habitants"
    title="Principals causes de mort des del 2000 (taxa bruta)"
/>

<p class="text-xs text-gray-500">El 2024, per primera vegada, els tumors van superar les malalties del cor i dels vasos sanguinis com a primera causa de mort. Els trastorns mentals creixen sobretot per les demències (alzheimer i altres), lligades a l'envelliment. Taxes brutes: amb una població cada vegada més gran, pugen encara que la probabilitat de morir a cada edat baixi.</p>

## Suïcidis, trànsit i homicidis

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
    yAxisTitle="per 100.000 habitants"
    xFmt="####"
    legend=true
    colorPalette={['#f59e0b', '#7c3aed', '#b91c1c']}
    title="Morts per suïcidi, accidents de trànsit i homicidi, per 100.000 habitants"
/>

<p class="text-xs text-gray-500">Des del 2008 moren a Espanya més persones per suïcidi que en accidents de trànsit, que han caigut a menys d'un terç des del 2000. Xifres per residència del mort i segons la causa del certificat de defunció (els morts en carretera de la DGT, comptats a 30 dies, són una mica diferents).</p>

```sql suicidio_ccaa
SELECT c.cod, t.nombre AS comunidad, '/ca' || t.ruta AS ruta,
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
    <Column id=comunidad title="Comunitat" />
    <Column id=defunciones title="Suïcidis" fmt=num0 />
    <Column id=tasa title="Per 100.000 hab." fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=tasa_hombres title="Homes" fmt=num1 />
    <Column id=tasa_mujeres title="Dones" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">Tres de cada quatre suïcidis són d'homes. Les taxes més altes es donen al nord-oest (Astúries, Galícia), amb població més envellida.</p>

## Excés de mortalitat

<BarChart
    data={exceso_anual}
    x=anio
    y=exceso
    yFmt=pct0
    xFmt="####"
    fillColor="#b91c1c"
    title="Morts de cada any respecte a la mitjana del 2015-2019"
/>

```sql semanal
SELECT semana, defunciones, media_2015_2019
FROM mother.salud_mortalidad_semanal
WHERE nivel = 'pais' AND semana >= (SELECT max(semana) FROM mother.salud_mortalidad_semanal) - INTERVAL 3 YEAR
ORDER BY semana
```

<LineChart
    data={semanal}
    x=semana
    y={['defunciones', 'media_2015_2019']}
    yFmt=num0
    seriesLabels={{defunciones: 'Defuncions', media_2015_2019: 'Mitjana de la mateixa setmana el 2015-2019'}}
    colorPalette={['#b91c1c', '#94a3b8']}
    legend=true
    title="Defuncions setmana a setmana (últims tres anys)"
/>

<p class="text-xs text-gray-500">La comparació amb el 2015-2019 és senzilla i no corregeix que la població és cada any més gran i més nombrosa, de manera que des del 2023 part de l'"excés" és simplement envelliment. Els pics coincideixen amb les onades de grip a l'hivern i amb les onades de calor (vegeu <a href="/ca/energia-clima/calor">Calor</a>). Les últimes setmanes poden ser incompletes.</p>

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
SELECT t.nombre AS comunidad, '/ca' || t.ruta AS ruta,
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
SELECT anio, geo, recurso,
    CASE recurso WHEN 'medicos' THEN 'Médicos' WHEN 'enfermeras' THEN 'Enfermeras' ELSE 'Camas' END
        || CASE WHEN geo = 'ES' THEN ' · España' ELSE ' · media UE-27' END AS serie,
    por_1000
FROM mother.sanidad_recursos
WHERE geo IN ('ES', 'UE') AND anio >= 2000
ORDER BY anio
```

```sql san_rec_ultimo
WITH es AS (SELECT recurso, max(anio) AS anio FROM mother.sanidad_recursos WHERE geo = 'ES' GROUP BY recurso)
SELECT e.recurso, CAST(e.anio AS INTEGER) AS anio, r.por_1000 AS es, r.numero AS numero_es, u.por_1000 AS ue, u.n_paises
FROM es e
JOIN mother.sanidad_recursos r ON r.geo = 'ES' AND r.recurso = e.recurso AND r.anio = e.anio
LEFT JOIN mother.sanidad_recursos u ON u.geo = 'UE' AND u.recurso = e.recurso AND u.anio = e.anio
```

```sql san_rec_paises
WITH ultimo AS (
    SELECT geo, recurso, max(anio) AS anio
    FROM mother.sanidad_recursos
    WHERE geo <> 'UE' AND anio <= (SELECT max(anio) FROM mother.sanidad_recursos WHERE geo = 'ES')
    GROUP BY ALL
)
SELECT r.pais,
    max(r.por_1000) FILTER (WHERE r.recurso = 'medicos') AS medicos,
    max(r.por_1000) FILTER (WHERE r.recurso = 'enfermeras') AS enfermeras,
    max(r.por_1000) FILTER (WHERE r.recurso = 'camas') AS camas,
    CAST(max(r.anio) AS INTEGER) AS anio
FROM mother.sanidad_recursos r
JOIN ultimo u ON u.geo = r.geo AND u.recurso = r.recurso AND u.anio = r.anio
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
SELECT t.nombre AS comunidad, '/ca' || t.ruta AS ruta,
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
WHERE geo = 'ES'
ORDER BY anio
```

```sql san_gasto_ultimo
WITH es AS (SELECT * FROM mother.sanidad_gasto WHERE geo = 'ES'),
ue AS (SELECT * FROM mother.sanidad_gasto WHERE geo = 'UE'),
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
WHERE geo IN ('ES', 'UE') AND financiacion IN ('Público', 'Seguros voluntarios', 'Pago directo de los hogares')
GROUP BY ALL
ORDER BY anio, serie
```

```sql san_gasto_paises
SELECT pais, pps_hab,
    CASE WHEN geo = 'ES' THEN 'España' WHEN geo = 'UE' THEN 'Media UE-27' ELSE 'Resto de países' END AS grupo
FROM mother.sanidad_gasto
WHERE financiacion = 'Total' AND pps_hab IS NOT NULL
  AND anio = (SELECT max(anio) FROM mother.sanidad_gasto WHERE geo = 'UE' AND financiacion = 'Total' AND pps_hab IS NOT NULL)
ORDER BY pps_hab DESC
```

```sql san_gasto_ccaa
SELECT t.nombre AS comunidad, '/ca' || t.ruta AS ruta, g.eur_hab_real, g.pct_pib / 100 AS pct_pib,
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

## Sistema sanitari

Quant s'espera per operar-se o veure l'especialista a la sanitat pública, quants metges, infermeres i llits hi ha per habitant i quant es gasta en salut, en comparació amb la resta de la Unió Europea.

<Grid cols=4>
    <KpiCard
        title="Llista d'espera quirúrgica"
        value={san_le_ultimo[0]?.tasa_1000}
        formattedValue="{formatNumber(san_le_ultimo[0]?.tasa_1000, 1)} per 1.000 hab."
        period="{formatNumber(san_le_ultimo[0]?.pacientes, 0)} pacients a {fechaCa(san_le_ultimo[0]?.fecha_txt)}"
        change={san_le_ultimo[0]?.tasa_var}
        changeUnit=""
        changePeriod="respecte a un any abans"
        direction="positive-down"
        source="Ministeri de Sanitat (SISLE)"
        sparklineData={san_le.filter(d => d.tipo === 'quirurgica').map(d => ({valor: d.tasa_1000}))}
    />
    <KpiCard
        title="Espera mitjana per operar-se"
        value={san_le_ultimo[0]?.dias_medio}
        formattedValue="{formatNumber(san_le_ultimo[0]?.dias_medio, 0)} dies"
        period="el {formatNumber(san_le_ultimo[0]?.pct_espera_larga, 1)} % fa més de 6 mesos que espera"
        change={san_le_ultimo[0]?.dias_var}
        changeUnit="dies"
        changePeriod="en un any"
        direction="positive-down"
        source="Ministeri de Sanitat (SISLE)"
        sparklineData={san_le.filter(d => d.tipo === 'quirurgica').map(d => ({valor: d.dias_medio}))}
    />
    <KpiCard
        title="Espera mitjana per a l'especialista"
        value={san_le_ultimo[0]?.c_dias}
        formattedValue="{formatNumber(san_le_ultimo[0]?.c_dias, 0)} dies"
        period="primera consulta · el {formatNumber(san_le_ultimo[0]?.c_pct, 1)} % espera més de 60 dies"
        change={san_le_ultimo[0]?.c_dias_var}
        changeUnit="dies"
        changePeriod="en un any"
        direction="positive-down"
        source="Ministeri de Sanitat (SISLE)"
        sparklineData={san_le.filter(d => d.tipo === 'consultas').map(d => ({valor: d.dias_medio}))}
    />
    <KpiCard
        title="Despesa sanitària pública"
        value={san_gasto_ultimo[0]?.pub_real}
        formattedValue="{formatNumber(san_gasto_ultimo[0]?.pub_real, 0)} € per hab."
        period="{formatNumber(san_gasto_ultimo[0]?.pub_pib, 1)} % del PIB el {san_gasto_ultimo[0]?.anio} · euros de {san_gasto_ultimo[0]?.anio_base}"
        source="Eurostat"
        sparklineData={san_gasto_es.filter(d => d.financiacion === 'Público').map(d => ({valor: d.eur_hab_real}))}
    />
    <KpiCard
        title="Metges"
        value={san_rec_ultimo.find(d => d.recurso === 'medicos')?.es}
        formattedValue="{formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.es, 1)} per 1.000 hab."
        period="mitjana UE: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.ue, 1)} · {san_rec_ultimo.find(d => d.recurso === 'medicos')?.anio}"
        source="Eurostat"
        sparklineData={san_rec.filter(d => d.geo === 'ES' && d.recurso === 'medicos').map(d => ({valor: d.por_1000}))}
    />
    <KpiCard
        title="Infermeres"
        value={san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.es}
        formattedValue="{formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.es, 1)} per 1.000 hab."
        period="mitjana UE: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.ue, 1)} · {san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.anio}"
        source="Eurostat"
        sparklineData={san_rec.filter(d => d.geo === 'ES' && d.recurso === 'enfermeras').map(d => ({valor: d.por_1000}))}
    />
    <KpiCard
        title="Llits d'hospital"
        value={san_rec_ultimo.find(d => d.recurso === 'camas')?.es}
        formattedValue="{formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.es, 1)} per 1.000 hab."
        period="mitjana UE: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.ue, 1)} · {san_rec_ultimo.find(d => d.recurso === 'camas')?.anio}"
        source="Eurostat"
        sparklineData={san_rec.filter(d => d.geo === 'ES' && d.recurso === 'camas').map(d => ({valor: d.por_1000}))}
    />
    <KpiCard
        title="Pagament directe de les llars"
        value={san_gasto_ultimo[0]?.hog_real}
        formattedValue="{formatNumber(san_gasto_ultimo[0]?.hog_real, 0)} € per hab."
        period="de la seva butxaca el {san_gasto_ultimo[0]?.anio} (farmàcia, dentista, consultes privades...) · més {formatNumber(san_gasto_ultimo[0]?.seg_real, 0)} € en assegurances"
        source="Eurostat"
        sparklineData={san_gasto_es.filter(d => d.financiacion === 'Pago directo de los hogares').map(d => ({valor: d.eur_hab_real}))}
    />
</Grid>

### Llistes d'espera

A {fechaCa(san_le_ultimo[0]?.fecha_txt)} hi havia {formatNumber(san_le_ultimo[0]?.tasa_1000, 1)} persones per cada 1.000 habitants esperant una operació programada a la sanitat pública, davant de {formatNumber(san_le_ultimo[0]?.tasa_ini, 1)} el desembre de {san_le_ultimo[0]?.anio_ini}. L'espera mitjana era de {formatNumber(san_le_ultimo[0]?.dias_medio, 0)} dies per operar-se i de {formatNumber(san_le_ultimo[0]?.c_dias, 0)} dies per a una primera consulta amb l'especialista.

<BarChart
    data={san_le.filter(d => d.tipo === 'quirurgica')}
    x=fecha
    y=tasa_1000
    yFmt=num1
    fillColor="#0f766e"
    yAxisTitle="per 1.000 habitants"
    title="Pacients en llista d'espera quirúrgica per 1.000 habitants (30 de juny i 31 de desembre)"
/>

<LineChart
    data={san_le_dias}
    x=fecha
    y=dias_medio
    series=lista
    yFmt=num0
    legend=true
    colorPalette={['#0f766e', '#7c3aed']}
    yAxisTitle="dies"
    title="Temps mitjà d'espera al Sistema Nacional de Salut"
/>

<p class="text-xs text-gray-500">Espera estructural: pacients pendents d'una operació no urgent o d'una primera consulta en atenció especialitzada l'espera dels quals s'atribueix a l'organització i els recursos del sistema (no inclou l'atenció primària). El temps mitjà és el que porten esperant, el dia del tall, els qui continuen a la llista; la taxa es calcula sobre la població amb targeta sanitària. Les dades les aporta cada comunitat i el Ministeri de Sanitat les agrega; hi ha hagut canvis de criteri: fins al juny del 2016 les dades d'una comunitat s'estimaven, el 2018 Andalusia va canviar el sistema de còmput (ruptura de sèrie, segons el ministeri) i el % de consultes a més de 60 dies inclou en les últimes edicions pacients encara sense cita. El pic del 2020 coincideix amb la pandèmia de COVID-19.</p>

<DataTable data={san_le_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=q_tasa title="Operació: per 1.000 hab." fmt=num1 />
    <Column id=q_dias title="Operació: dies" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=q_pct title="Operació: més de 6 mesos" fmt=pct1 />
    <Column id=c_tasa title="Especialista: per 1.000 hab." fmt=num1 />
    <Column id=c_dias title="Especialista: dies" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=c_pct title="Especialista: més de 60 dies" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Situació a {fechaCa(san_le_ultimo[0]?.fecha_txt)}. L'espera mitjana per operar-se va de {formatNumber(san_le_extremos[0]?.min_dias, 0)} dies a {san_le_extremos[0]?.min_com} a {formatNumber(san_le_extremos[0]?.max_dias, 0)} a {san_le_extremos[0]?.max_com}. Les comunitats no compten igual els seus pacients (el ministeri adverteix que cadascuna respon de les seves dades), de manera que les diferències entre elles s'han de llegir amb cautela.</p>

<BarChart
    data={san_le_esp}
    x=especialidad
    y=dias_medio
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    yAxisTitle="dies"
    title="Espera mitjana per operar-se per especialitat ({fechaCa(san_le_ultimo[0]?.fecha_txt)})"
/>

<DataTable data={san_le_esp_cons} rows=all>
    <Column id=especialidad title="Consultes externes: especialitat" />
    <Column id=tasa_1000 title="Pacients per 1.000 hab." fmt=num2 />
    <Column id=dias_medio title="Dies d'espera" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=pct title="Més de 60 dies" fmt=pct1 />
</DataTable>

### Metges, infermeres i llits

<LineChart
    data={san_rec.filter(d => d.recurso !== 'camas')}
    x=anio
    y=por_1000
    series=serie
    yFmt=num1
    xFmt="####"
    legend=true
    colorPalette={['#b45309', '#fcd34d', '#1d4ed8', '#93c5fd']}
    yAxisTitle="per 1.000 habitants"
    title="Metges i infermeres en exercici, per 1.000 habitants: Espanya i mitjana de la UE"
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
    yAxisTitle="per 1.000 habitants"
    title="Llits d'hospital per 1.000 habitants: Espanya i mitjana de la UE"
/>

<p class="text-xs text-gray-500">El {san_rec_ultimo.find(d => d.recurso === 'medicos')?.anio} Espanya tenia {formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.es, 1)} metges en exercici per 1.000 habitants ({#if san_rec_ultimo.find(d => d.recurso === 'medicos')?.es > san_rec_ultimo.find(d => d.recurso === 'medicos')?.ue}per sobre{:else}per sota{/if} de la mitjana de la UE, {formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.ue, 1)}), {formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.es, 1)} infermeres (mitjana UE: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.ue, 1)}; lloc {san_rec_rango[0]?.puesto_enf} de {san_rec_rango[0]?.n_enf} països amb dada) i {formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.es, 1)} llits d'hospital (mitjana UE: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.ue, 1)}; lloc {san_rec_rango[0]?.puesto_camas} de {san_rec_rango[0]?.n_camas}). La mitjana de la UE està ponderada per població i només es calcula els anys en què informen almenys 24 països; quan un país no dona el personal en exercici s'utilitza el professionalment actiu, de manera que les comparacions són aproximades.</p>

<DataTable data={san_rec_paises} rows=all>
    <Column id=pais title="País" />
    <Column id=medicos title="Metges per 1.000 hab." fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=enfermeras title="Infermeres per 1.000 hab." fmt=num1 contentType=bar barColor="#bfdbfe" />
    <Column id=camas title="Llits per 1.000 hab." fmt=num1 contentType=bar barColor="#99f6e4" />
    <Column id=anio title="Any" fmt="####" />
</DataTable>

<DataTable data={san_rec_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=medicos title="Metges per 1.000 hab." fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=camas title="Llits d'hospital per 1.000 hab." fmt=num1 contentType=bar barColor="#99f6e4" />
</DataTable>

<p class="text-xs text-gray-500">Metges i llits (públics i privats) per comunitat el {san_rec_ccaa[0]?.anio}, segons Eurostat. Compten els recursos situats a cada comunitat, que també atenen pacients d'altres comunitats.</p>

### Quant es gasta en salut

El {san_gasto_ultimo[0]?.anio} la despesa sanitària total a Espanya va ser de {formatNumber(san_gasto_ultimo[0]?.tot_real, 0)} euros per habitant (euros de {san_gasto_ultimo[0]?.anio_base}), el {formatNumber(san_gasto_ultimo[0]?.tot_pib, 1)} % del PIB. Les administracions en van pagar el {formatNumber(san_gasto_ultimo[0]?.pub_peso, 0)} %; la resta va sortir de la butxaca de les llars o d'assegurances privades. El {san_gasto_ultimo[0]?.anio_ue}, últim any amb dada europea, la despesa pública va ser del {formatNumber(san_gasto_ultimo[0]?.pub_pib_es_uu, 1)} % del PIB a Espanya i del {formatNumber(san_gasto_ultimo[0]?.pub_pib_ue, 1)} % en la mitjana de la UE.

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
    yAxisTitle="euros per habitant"
    title="Despesa sanitària per habitant segons qui la paga (euros de {san_gasto_ultimo[0]?.anio_base}, descomptada la inflació)"
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
    yAxisTitle="% del PIB"
    title="Despesa sanitària pública i privada en % del PIB: Espanya i UE-27"
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
    yAxisTitle="PPS per habitant"
    title="Despesa sanitària total per habitant a la UE ({san_gasto_ultimo[0]?.anio_ue}, en paritat de poder adquisitiu)"
/>

<p class="text-xs text-gray-500">Despesa sanitària corrent segons els comptes de salut (SHA 2011) d'Eurostat. El públic inclou les administracions i les assegurances socials obligatòries (també les mutualitats de funcionaris); el privat, les assegurances voluntàries i el pagament directe de les llars. La comparació entre països utilitza la paritat de poder adquisitiu (PPS), que descompta les diferències de preus.</p>

<DataTable data={san_gasto_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=eur_hab_real title="Despesa sanitària pública per habitant (€)" fmt='#,##0' contentType=bar barColor="#99f6e4" />
    <Column id=pct_pib title="% del PIB regional" fmt=pct1 />
    <Column id=var_2019 title="Variació real des del 2019" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Despesa sanitària de cada comunitat autònoma per habitant el {san_gasto_ccaa_total[0]?.anio}{#if san_gasto_ccaa_total[0]?.provisional} (xifres provisionals){/if}, en euros de {san_gasto_ultimo[0]?.anio_base}: de {formatNumber(san_gasto_ccaa_total[0]?.min_real, 0)} € a {san_gasto_ccaa_total[0]?.min_com} a {formatNumber(san_gasto_ccaa_total[0]?.max_real, 0)} € a {san_gasto_ccaa_total[0]?.max_com}; {formatNumber(san_gasto_ccaa_total[0]?.eur_hab_real, 0)} € en el conjunt de les comunitats. És la despesa dels serveis de salut autonòmics (Estadística de Despesa Sanitària Pública del Ministeri de Sanitat), més del 90 % de la despesa sanitària pública; no inclou mutualitats de funcionaris ni ajuntaments. Ceuta i Melilla no hi apareixen perquè la seva sanitat la gestiona l'Estat (INGESA).</p>

---

## Fonts i notes

- **[INE – Indicadors demogràfics bàsics](https://www.ine.es/jaxiT3/Tabla.htm?t=1448)**: esperança de vida en néixer per comunitat (taula 1448) i província (1485); **[Eurostat – demo_mlexpec](https://ec.europa.eu/eurostat/databrowser/view/demo_mlexpec/default/table)** per al total d'Espanya.
- **[INE – Defuncions segons la causa de mort](https://www.ine.es/jaxiT3/Tabla.htm?t=9936)** (taula 9936, llista reduïda de causes per província de residència, des de 1980; l'últim any publicat és definitiu amb un any de retard).
- **[INE – Estimació de Defuncions Setmanals (EDeS)](https://www.ine.es/jaxiT3/Tabla.htm?t=35177)** (taula 35177): defuncions per setmana i comunitat.
- **[Ministeri de Sanitat – Llistes d'espera del SNS (SISLE-SNS)](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEspera.htm)**: informes semestrals (30 de juny i 31 de desembre) de llista d'espera quirúrgica i de consultes externes per comunitat i especialitat, des del desembre del 2013 ([històric](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEsperaInfAnt.htm)). El ministeri només els publica en PDF; les xifres es llegeixen de les seves taules.
- **[Ministeri de Sanitat – Estadística de Despesa Sanitària Pública](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/gastoSanitario2005/home.htm)**: despesa sanitària pública per comunitat autònoma (euros per habitant i % del PIB, annexos I.1 i I.2).
- **[Eurostat – hlth_rs_prs2](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_prs2/default/table)** (metges i infermeres), **[hlth_rs_bds1](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_bds1/default/table)** (llits hospitalaris), **[hlth_rs_physreg](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_physreg/default/table)** i **[hlth_rs_bdsrg2](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_bdsrg2/default/table)** (per comunitat) i **[hlth_sha11_hf](https://ec.europa.eu/eurostat/databrowser/view/hlth_sha11_hf/default/table)** (despesa sanitària per font de finançament). Els euros per habitant d'Espanya es descompten d'inflació amb l'IPC de l'INE.
- La despesa sanitària dins del total de la despesa de les administracions és a [Despeses públiques](/ca/cuentas-publicas/gastos).

<LastRefreshed prefix="Dades actualitzades" />
