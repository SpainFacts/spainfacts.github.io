---
title: Salud
description: "Esperanza de vida en España por comunidad y provincia, de qué se muere la gente, suicidios, accidentes de tráfico, exceso de mortalidad y el sistema sanitario: listas de espera, médicos, enfermeras, camas y gasto por habitante frente a la UE."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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

# 🩺 Salud

Cuánto vivimos, de qué morimos y cómo han cambiado las cosas, con las estadísticas vitales del INE. Más abajo, el <a href="#sistema-sanitario">sistema sanitario</a>: listas de espera, médicos, enfermeras, camas y gasto.

<Grid cols=4>
    <KpiCard
        title="Esperanza de vida al nacer"
        value={ev_ultimo[0]?.total}
        formattedValue="{formatNumber(ev_ultimo[0]?.total, 1)} años"
        period="mujeres {formatNumber(ev_ultimo[0]?.mujeres, 1)} · hombres {formatNumber(ev_ultimo[0]?.hombres, 1)} · {ev_ultimo[0]?.anio}"
        source="INE / Eurostat"
        sparklineData={ev_serie}
    />
    <KpiCard
        title="Tasa de mortalidad"
        value={causas_ultimo[0]?.mortalidad_1000}
        formattedValue="{formatNumber(causas_ultimo[0]?.mortalidad_1000, 1)} por 1.000 hab."
        period="{formatNumber(causas_ultimo[0]?.total, 0)} defunciones en {causas_ultimo[0]?.anio} · tasa bruta"
        source="INE"
        sparklineData={causas_clave.filter(d => d.codigo_causa === '001-102' && d.anio >= 2000).map(d => ({anio: d.anio, valor: d.tasa_100k / 100}))}
    />
    <KpiCard
        title="Suicidios"
        value={causas_ultimo[0]?.suicidios_tasa}
        formattedValue="{formatNumber(causas_ultimo[0]?.suicidios_tasa, 1)} por 100.000 hab."
        period="{formatNumber(causas_ultimo[0]?.suicidios, 0)} en {causas_ultimo[0]?.anio} · primera causa externa de muerte"
        source="INE"
        sparklineData={causas_clave.filter(d => d.codigo_causa === '098' && d.anio >= 2000).map(d => ({anio: d.anio, valor: d.tasa_100k}))}
    />
    <KpiCard
        title="Muertos en accidentes de tráfico"
        value={causas_ultimo[0]?.trafico_tasa}
        formattedValue="{formatNumber(causas_ultimo[0]?.trafico_tasa, 1)} por 100.000 hab."
        period="{formatNumber(causas_ultimo[0]?.trafico, 0)} residentes fallecidos en {causas_ultimo[0]?.anio}"
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


<p class="text-xs text-gray-500">Si necesitas ayuda o conoces a alguien que pueda necesitarla, llama al <b>024</b>, la línea de atención a la conducta suicida (gratuita, confidencial, 24 horas).</p>

## Cuánto vivimos

<LineChart
    data={ev_espana}
    x=anio
    y=anios
    series=sexo
    yFmt=num1
    xFmt="####"
    legend=true
    colorPalette={['#0f766e', '#1d4ed8', '#be185d']}
    yAxisTitle="años"
    title="Esperanza de vida al nacer en España"
/>

<p class="text-xs text-gray-500">La caída de 2020 es la pandemia de COVID-19 (más de un año de esperanza de vida perdido); no se recuperó el nivel de 2019 hasta 2023. España está entre los países con mayor esperanza de vida del mundo.</p>

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'anios', title: 'Esperanza de vida (años)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Esperanza de vida al nacer por provincia de residencia en {ev_ultimo[0]?.anio}. Las más altas están en Madrid y el interior norte; las más bajas, en el sur, Canarias, Ceuta y Melilla.</p>

## De qué morimos

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
    yAxisTitle="por 100.000 habitantes"
    fillColor="#0f766e"
    title="Defunciones por grandes grupos de causas por 100.000 habitantes ({causas_ultimo[0]?.anio})"
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
    yAxisTitle="por 100.000 habitantes"
    title="Principales causas de muerte desde 2000 (tasa bruta)"
/>

<p class="text-xs text-gray-500">En 2024, por primera vez, los tumores superaron a las enfermedades del corazón y los vasos sanguíneos como primera causa de muerte. Los trastornos mentales crecen sobre todo por las demencias (alzhéimer y otras), ligadas al envejecimiento. Tasas brutas: con una población cada vez más mayor, suben aunque la probabilidad de morir a cada edad baje.</p>

## Suicidios, tráfico y homicidios

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
    yAxisTitle="por 100.000 habitantes"
    xFmt="####"
    legend=true
    colorPalette={['#f59e0b', '#7c3aed', '#b91c1c']}
    title="Muertes por suicidio, accidentes de tráfico y homicidio, por 100.000 habitantes"
/>

<p class="text-xs text-gray-500">Desde 2008 mueren en España más personas por suicidio que en accidentes de tráfico, que han caído a menos de un tercio desde 2000. Cifras por residencia del fallecido y según la causa del certificado de defunción (los muertos en carretera de la DGT, contados a 30 días, son algo distintos).</p>

```sql suicidio_ccaa
SELECT c.cod, t.nombre AS comunidad, t.ruta,
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
    <Column id=comunidad title="Comunidad" />
    <Column id=defunciones title="Suicidios" fmt=num0 />
    <Column id=tasa title="Por 100.000 hab." fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=tasa_hombres title="Hombres" fmt=num1 />
    <Column id=tasa_mujeres title="Mujeres" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">Tres de cada cuatro suicidios son de hombres. Las tasas más altas se dan en el noroeste (Asturias, Galicia), con población más envejecida.</p>

## Exceso de mortalidad

<BarChart
    data={exceso_anual}
    x=anio
    y=exceso_hab_pct
    yFmt='0"%"'
    xFmt="####"
    fillColor="#b91c1c"
    title="Muertes por habitante de cada año frente a la media de 2015-2019"
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
    seriesLabels={{defunciones_por_100k_hab: 'Defunciones', media_2015_2019_por_100k_hab: 'Media de la misma semana en 2015-2019'}}
    colorPalette={['#b91c1c', '#94a3b8']}
    legend=true
    title="Defunciones por 100.000 habitantes semana a semana (últimos tres años)"
/>

<p class="text-xs text-gray-500">La comparación con 2015-2019 se hace por habitante, así que ya descuenta que la población es cada año más numerosa, pero no corrige que es más envejecida, y por eso desde 2023 parte del "exceso" es simplemente envejecimiento. Los picos coinciden con las olas de gripe en invierno y con las olas de calor (ver <a href="/energia-clima/calor">Calor</a>). Las últimas semanas pueden estar incompletas.</p>

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
SELECT t.nombre AS comunidad, t.ruta,
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
SELECT t.nombre AS comunidad, t.ruta,
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
SELECT t.nombre AS comunidad, t.ruta, g.eur_hab_real, g.pct_pib,
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

## Sistema sanitario

Cuánto se espera para operarse o ver al especialista en la sanidad pública, cuántos médicos, enfermeras y camas hay por habitante y cuánto se gasta en salud, comparado con el resto de la Unión Europea.

<Grid cols=4>
    <KpiCard
        title="Lista de espera quirúrgica"
        value={san_le_ultimo[0]?.tasa_1000}
        formattedValue="{formatNumber(san_le_ultimo[0]?.tasa_1000, 1)} por 1.000 hab."
        period="{formatNumber(san_le_ultimo[0]?.pacientes, 0)} pacientes a {san_le_ultimo[0]?.fecha_txt}"
        change={san_le_ultimo[0]?.tasa_var}
        changeUnit=""
        changePeriod="frente a un año antes"
        direction="positive-down"
        source="Ministerio de Sanidad (SISLE)"
        sparklineData={san_le.filter(d => d.tipo === 'quirurgica').map(d => ({valor: d.tasa_1000}))}
    />
    <KpiCard
        title="Espera media para operarse"
        value={san_le_ultimo[0]?.dias_medio}
        formattedValue="{formatNumber(san_le_ultimo[0]?.dias_medio, 0)} días"
        period="{formatNumber(san_le_ultimo[0]?.pct_espera_larga, 1)} % lleva más de 6 meses"
        change={san_le_ultimo[0]?.dias_var}
        changeUnit="días"
        changePeriod="en un año"
        direction="positive-down"
        source="Ministerio de Sanidad (SISLE)"
        sparklineData={san_le.filter(d => d.tipo === 'quirurgica').map(d => ({valor: d.dias_medio}))}
    />
    <KpiCard
        title="Espera media para el especialista"
        value={san_le_ultimo[0]?.c_dias}
        formattedValue="{formatNumber(san_le_ultimo[0]?.c_dias, 0)} días"
        period="primera consulta · {formatNumber(san_le_ultimo[0]?.c_pct, 1)} % espera más de 60 días"
        change={san_le_ultimo[0]?.c_dias_var}
        changeUnit="días"
        changePeriod="en un año"
        direction="positive-down"
        source="Ministerio de Sanidad (SISLE)"
        sparklineData={san_le.filter(d => d.tipo === 'consultas').map(d => ({valor: d.dias_medio}))}
    />
    <KpiCard
        title="Gasto sanitario público"
        value={san_gasto_ultimo[0]?.pub_real}
        formattedValue="{formatNumber(san_gasto_ultimo[0]?.pub_real, 0)} € por hab."
        period="{formatNumber(san_gasto_ultimo[0]?.pub_pib, 1)} % del PIB en {san_gasto_ultimo[0]?.anio} · euros de {san_gasto_ultimo[0]?.anio_base}"
        source="Eurostat"
        sparklineData={san_gasto_es.filter(d => d.financiacion === 'Público').map(d => ({valor: d.eur_hab_real}))}
    />
    <KpiCard
        title="Médicos"
        value={san_rec_ultimo.find(d => d.recurso === 'medicos')?.es}
        formattedValue="{formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.es, 1)} por 1.000 hab."
        period="media UE: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.ue, 1)} · {san_rec_ultimo.find(d => d.recurso === 'medicos')?.anio}"
        source="Eurostat"
        sparklineData={san_rec.filter(d => d.cod_pais === 'ES' && d.recurso === 'medicos').map(d => ({valor: d.por_1000}))}
    />
    <KpiCard
        title="Enfermeras"
        value={san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.es}
        formattedValue="{formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.es, 1)} por 1.000 hab."
        period="media UE: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.ue, 1)} · {san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.anio}"
        source="Eurostat"
        sparklineData={san_rec.filter(d => d.cod_pais === 'ES' && d.recurso === 'enfermeras').map(d => ({valor: d.por_1000}))}
    />
    <KpiCard
        title="Camas de hospital"
        value={san_rec_ultimo.find(d => d.recurso === 'camas')?.es}
        formattedValue="{formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.es, 1)} por 1.000 hab."
        period="media UE: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.ue, 1)} · {san_rec_ultimo.find(d => d.recurso === 'camas')?.anio}"
        source="Eurostat"
        sparklineData={san_rec.filter(d => d.cod_pais === 'ES' && d.recurso === 'camas').map(d => ({valor: d.por_1000}))}
    />
    <KpiCard
        title="Pago directo de los hogares"
        value={san_gasto_ultimo[0]?.hog_real}
        formattedValue="{formatNumber(san_gasto_ultimo[0]?.hog_real, 0)} € por hab."
        period="de su bolsillo en {san_gasto_ultimo[0]?.anio} (farmacia, dentista, consultas privadas...) · más {formatNumber(san_gasto_ultimo[0]?.seg_real, 0)} € en seguros"
        source="Eurostat"
        sparklineData={san_gasto_es.filter(d => d.financiacion === 'Pago directo de los hogares').map(d => ({valor: d.eur_hab_real}))}
    />
</Grid>

### Listas de espera

A {san_le_ultimo[0]?.fecha_txt} había {formatNumber(san_le_ultimo[0]?.tasa_1000, 1)} personas por cada 1.000 habitantes esperando una operación programada en la sanidad pública, frente a {formatNumber(san_le_ultimo[0]?.tasa_ini, 1)} en diciembre de {san_le_ultimo[0]?.anio_ini}. La espera media era de {formatNumber(san_le_ultimo[0]?.dias_medio, 0)} días para operarse y de {formatNumber(san_le_ultimo[0]?.c_dias, 0)} días para una primera consulta con el especialista.

<BarChart
    data={san_le.filter(d => d.tipo === 'quirurgica')}
    x=fecha
    y=tasa_1000
    yFmt=num1
    fillColor="#0f766e"
    yAxisTitle="por 1.000 habitantes"
    title="Pacientes en lista de espera quirúrgica por 1.000 habitantes (30 de junio y 31 de diciembre)"
/>

<LineChart
    data={san_le_dias}
    x=fecha
    y=dias_medio
    series=lista
    yFmt=num0
    legend=true
    colorPalette={['#0f766e', '#7c3aed']}
    yAxisTitle="días"
    title="Tiempo medio de espera en el Sistema Nacional de Salud"
/>

<p class="text-xs text-gray-500">Espera estructural: pacientes pendientes de una operación no urgente o de una primera consulta en atención especializada cuya espera se atribuye a la organización y los recursos del sistema (no incluye la atención primaria). El tiempo medio es lo que llevan esperando, el día del corte, quienes siguen en la lista; la tasa se calcula sobre la población con tarjeta sanitaria. Los datos los aporta cada comunidad y el Ministerio de Sanidad los agrega; ha habido cambios de criterio: hasta junio de 2016 los datos de una comunidad se estimaban, en 2018 Andalucía cambió su sistema de cómputo (rotura de serie, según el ministerio) y el % de consultas a más de 60 días incluye en las últimas ediciones a pacientes aún sin cita. El pico de 2020 coincide con la pandemia de COVID-19.</p>

<DataTable data={san_le_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=q_tasa title="Operación: por 1.000 hab." fmt=num1 />
    <Column id=q_dias title="Operación: días" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=q_pct title="Operación: más de 6 meses" fmt=pct1 />
    <Column id=c_tasa title="Especialista: por 1.000 hab." fmt=num1 />
    <Column id=c_dias title="Especialista: días" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=c_pct title="Especialista: más de 60 días" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Situación a {san_le_ultimo[0]?.fecha_txt}. La espera media para operarse va de {formatNumber(san_le_extremos[0]?.min_dias, 0)} días en {san_le_extremos[0]?.min_com} a {formatNumber(san_le_extremos[0]?.max_dias, 0)} en {san_le_extremos[0]?.max_com}. Las comunidades no cuentan igual a sus pacientes (el ministerio advierte de que cada una responde de sus datos), así que las diferencias entre ellas deben leerse con cautela.</p>

<BarChart
    data={san_le_esp}
    x=especialidad
    y=dias_medio
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    yAxisTitle="días"
    title="Espera media para operarse por especialidad ({san_le_ultimo[0]?.fecha_txt})"
/>

<DataTable data={san_le_esp_cons} rows=all>
    <Column id=especialidad title="Consultas externas: especialidad" />
    <Column id=tasa_1000 title="Pacientes por 1.000 hab." fmt=num2 />
    <Column id=dias_medio title="Días de espera" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=pct title="Más de 60 días" fmt=pct1 />
</DataTable>

### Médicos, enfermeras y camas

<LineChart
    data={san_rec.filter(d => d.recurso !== 'camas')}
    x=anio
    y=por_1000
    series=serie
    yFmt=num1
    xFmt="####"
    legend=true
    colorPalette={['#b45309', '#fcd34d', '#1d4ed8', '#93c5fd']}
    yAxisTitle="por 1.000 habitantes"
    title="Médicos y enfermeras que ejercen, por 1.000 habitantes: España y media de la UE"
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
    yAxisTitle="por 1.000 habitantes"
    title="Camas de hospital por 1.000 habitantes: España y media de la UE"
/>

<p class="text-xs text-gray-500">En {san_rec_ultimo.find(d => d.recurso === 'medicos')?.anio} España tenía {formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.es, 1)} médicos en ejercicio por 1.000 habitantes ({#if san_rec_ultimo.find(d => d.recurso === 'medicos')?.es > san_rec_ultimo.find(d => d.recurso === 'medicos')?.ue}por encima{:else}por debajo{/if} de la media de la UE, {formatNumber(san_rec_ultimo.find(d => d.recurso === 'medicos')?.ue, 1)}), {formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.es, 1)} enfermeras (media UE: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'enfermeras')?.ue, 1)}; puesto {san_rec_rango[0]?.puesto_enf} de {san_rec_rango[0]?.n_enf} países con dato) y {formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.es, 1)} camas de hospital (media UE: {formatNumber(san_rec_ultimo.find(d => d.recurso === 'camas')?.ue, 1)}; puesto {san_rec_rango[0]?.puesto_camas} de {san_rec_rango[0]?.n_camas}). La media de la UE está ponderada por población y solo se calcula los años en que informan al menos 24 países; donde un país no da el personal que ejerce se usa el profesionalmente activo, así que las comparaciones son aproximadas.</p>

<DataTable data={san_rec_paises} rows=all>
    <Column id=pais title="País" />
    <Column id=medicos title="Médicos por 1.000 hab." fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=enfermeras title="Enfermeras por 1.000 hab." fmt=num1 contentType=bar barColor="#bfdbfe" />
    <Column id=camas title="Camas por 1.000 hab." fmt=num1 contentType=bar barColor="#99f6e4" />
    <Column id=anio title="Año" fmt="####" />
</DataTable>

<DataTable data={san_rec_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=medicos title="Médicos por 1.000 hab." fmt=num1 contentType=bar barColor="#fde68a" />
    <Column id=camas title="Camas de hospital por 1.000 hab." fmt=num1 contentType=bar barColor="#99f6e4" />
</DataTable>

<p class="text-xs text-gray-500">Médicos y camas (públicos y privados) por comunidad en {san_rec_ccaa[0]?.anio}, según Eurostat. Cuentan los recursos situados en cada comunidad, que también atienden a pacientes de otras.</p>

### Cuánto se gasta en salud

En {san_gasto_ultimo[0]?.anio} el gasto sanitario total en España fue de {formatNumber(san_gasto_ultimo[0]?.tot_real, 0)} euros por habitante (euros de {san_gasto_ultimo[0]?.anio_base}), el {formatNumber(san_gasto_ultimo[0]?.tot_pib, 1)} % del PIB. Las administraciones pagaron el {formatNumber(san_gasto_ultimo[0]?.pub_peso, 0)} %; el resto salió del bolsillo de los hogares o de seguros privados. En {san_gasto_ultimo[0]?.anio_ue}, último año con dato europeo, el gasto público fue del {formatNumber(san_gasto_ultimo[0]?.pub_pib_es_uu, 1)} % del PIB en España y del {formatNumber(san_gasto_ultimo[0]?.pub_pib_ue, 1)} % en la media de la UE.

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
    yAxisTitle="euros por habitante"
    title="Gasto sanitario por habitante según quién lo paga (euros de {san_gasto_ultimo[0]?.anio_base}, descontada la inflación)"
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
    title="Gasto sanitario público y privado en % del PIB: España y UE-27"
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
    yAxisTitle="PPS por habitante"
    title="Gasto sanitario total por habitante en la UE ({san_gasto_ultimo[0]?.anio_ue}, en paridad de poder de compra)"
/>

<p class="text-xs text-gray-500">Gasto sanitario corriente según las cuentas de salud (SHA 2011) de Eurostat. Público incluye las administraciones y los seguros sociales obligatorios (también las mutualidades de funcionarios); privado, los seguros voluntarios y el pago directo de los hogares. La comparación entre países usa la paridad de poder de compra (PPS), que descuenta las diferencias de precios.</p>

<DataTable data={san_gasto_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=eur_hab_real title="Gasto sanitario público por habitante (€)" fmt='#,##0' contentType=bar barColor="#99f6e4" />
    <Column id=pct_pib title="% del PIB regional" fmt='0.0"%"' />
    <Column id=var_2019 title="Variación real desde 2019" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Gasto sanitario de cada comunidad autónoma por habitante en {san_gasto_ccaa_total[0]?.anio}{#if san_gasto_ccaa_total[0]?.provisional} (cifras provisionales){/if}, en euros de {san_gasto_ultimo[0]?.anio_base}: de {formatNumber(san_gasto_ccaa_total[0]?.min_real, 0)} € en {san_gasto_ccaa_total[0]?.min_com} a {formatNumber(san_gasto_ccaa_total[0]?.max_real, 0)} € en {san_gasto_ccaa_total[0]?.max_com}; {formatNumber(san_gasto_ccaa_total[0]?.eur_hab_real, 0)} € en el conjunto de las comunidades. Es el gasto de los servicios de salud autonómicos (Estadística de Gasto Sanitario Público del Ministerio de Sanidad), más del 90 % del gasto sanitario público; no incluye mutualidades de funcionarios ni ayuntamientos. Ceuta y Melilla no aparecen porque su sanidad la gestiona el Estado (INGESA).</p>

---

## Fuentes y notas

- **[INE – Indicadores demográficos básicos](https://www.ine.es/jaxiT3/Tabla.htm?t=1448)**: esperanza de vida al nacer por comunidad (tabla 1448) y provincia (1485); **[Eurostat – demo_mlexpec](https://ec.europa.eu/eurostat/databrowser/view/demo_mlexpec/default/table)** para el total de España.
- **[INE – Defunciones según la causa de muerte](https://www.ine.es/jaxiT3/Tabla.htm?t=9936)** (tabla 9936, lista reducida de causas por provincia de residencia, desde 1980; el último año publicado es definitivo con un año de retraso).
- **[INE – Estimación de Defunciones Semanales (EDeS)](https://www.ine.es/jaxiT3/Tabla.htm?t=35177)** (tabla 35177): defunciones por semana y comunidad.
- **[Ministerio de Sanidad – Listas de espera del SNS (SISLE-SNS)](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEspera.htm)**: informes semestrales (30 de junio y 31 de diciembre) de lista de espera quirúrgica y de consultas externas por comunidad y especialidad, desde diciembre de 2013 ([histórico](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEsperaInfAnt.htm)). El ministerio solo los publica en PDF; las cifras se leen de sus tablas.
- **[Ministerio de Sanidad – Estadística de Gasto Sanitario Público](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/gastoSanitario2005/home.htm)**: gasto sanitario público por comunidad autónoma (euros por habitante y % del PIB, anexos I.1 y I.2).
- **[Eurostat – hlth_rs_prs2](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_prs2/default/table)** (médicos y enfermeras), **[hlth_rs_bds1](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_bds1/default/table)** (camas hospitalarias), **[hlth_rs_physreg](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_physreg/default/table)** y **[hlth_rs_bdsrg2](https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_bdsrg2/default/table)** (por comunidad) y **[hlth_sha11_hf](https://ec.europa.eu/eurostat/databrowser/view/hlth_sha11_hf/default/table)** (gasto sanitario por fuente de financiación). Los euros por habitante de España se descuentan de inflación con el IPC del INE.
- El gasto sanitario dentro del total del gasto de las administraciones está en [Gastos públicos](/cuentas-publicas/gastos).

<LastRefreshed prefix="Datos actualizados" />
