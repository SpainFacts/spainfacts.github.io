---
title: Public employment
description: "How many public employees there are in Spain, which administration and sector they work in (health, education, town councils, security forces...), how their number has changed, what they earn compared with the private sector and how much they cost."
i18n_origen: a9194bd3ec9e
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql ultima
SELECT
    max(fecha) AS fecha,
    strftime(max(fecha), '%d/%m/%Y') AS fecha_texto
FROM mother.empleo_efectivos
```

```sql resumen
SELECT
    sum(efectivos) AS total,
    sum(efectivos) FILTER (WHERE administracion = 'Estado') AS estado,
    sum(efectivos) FILTER (WHERE administracion = 'Comunidades autónomas') AS ccaa,
    sum(efectivos) FILTER (WHERE administracion = 'Entidades locales') AS local,
    sum(efectivos) FILTER (WHERE sexo = 'Mujeres') AS mujeres,
    sum(efectivos) FILTER (WHERE tipo_personal IN ('Funcionario interino', 'Laboral temporal')) AS temporales
FROM mother.empleo_efectivos
WHERE fecha = (SELECT fecha FROM ${ultima})
```

```sql por_1000
SELECT por_1000_hab FROM mother.empleo_territorio
WHERE nivel = 'pais' AND administracion = 'Total' AND fecha = (SELECT fecha FROM ${ultima})
```

```sql coste_ultimo
SELECT anio, millones_eur, pct_pib, eur_por_habitante
FROM mother.empleo_coste
WHERE cod_sector = 'S13'
ORDER BY anio DESC
LIMIT 1
```

```sql salario_ultimo
SELECT
    anio,
    max(salario_mensual) FILTER (WHERE sector = 'Público') AS publico,
    max(salario_mensual) FILTER (WHERE sector = 'Privado') AS privado
FROM mother.empleo_salarios_deciles
WHERE jornada = 'Jornada a tiempo completo' AND decil = 0
GROUP BY anio
ORDER BY anio DESC
LIMIT 1
```

```sql serie_cuota_ccaa
SELECT
    fecha,
    100 * sum(efectivos) FILTER (WHERE administracion = 'Comunidades autónomas') / sum(efectivos) AS cuota_ccaa
FROM mother.empleo_efectivos
GROUP BY fecha
ORDER BY fecha
```

```sql serie_por_1000
SELECT fecha, por_1000_hab
FROM mother.empleo_territorio
WHERE nivel = 'pais' AND administracion = 'Total' AND por_1000_hab IS NOT NULL
ORDER BY fecha
```

```sql coste_serie_real
-- Para las mini-gráficas: euros por habitante a precios constantes del último año completo con IPC (media anual de ipc_indice)
WITH ipc AS (
    SELECT CAST(year(periodo) AS INTEGER) AS anio, avg(valor) AS ipc
    FROM mother.metricas
    WHERE metrica_id = 'ipc_indice'
    GROUP BY 1
    HAVING count(*) = 12
),
base AS (
    SELECT ipc AS ipc_base FROM ipc ORDER BY anio DESC LIMIT 1
)
SELECT
    c.anio,
    c.eur_por_habitante * base.ipc_base / ipc.ipc AS eur_hab_real
FROM mother.empleo_coste c
JOIN ipc ON ipc.anio = c.anio
CROSS JOIN base
WHERE c.cod_sector = 'S13' AND c.eur_por_habitante IS NOT NULL
ORDER BY c.anio
```

```sql salario_serie_real
-- Salario medio público a precios constantes del último año completo (IPC, media anual de ipc_indice)
WITH ipc AS (
    SELECT CAST(year(periodo) AS INTEGER) AS anio, avg(valor) AS ipc
    FROM mother.metricas
    WHERE metrica_id = 'ipc_indice'
    GROUP BY 1
    HAVING count(*) = 12
),
base AS (
    SELECT ipc AS ipc_base FROM ipc ORDER BY anio DESC LIMIT 1
),
sal AS (
    SELECT anio, max(salario_mensual) FILTER (WHERE sector = 'Público') AS publico
    FROM mother.empleo_salarios_deciles
    WHERE jornada = 'Jornada a tiempo completo' AND decil = 0
    GROUP BY anio
)
SELECT s.anio, s.publico * base.ipc_base / ipc.ipc AS publico_real
FROM sal s
JOIN ipc ON ipc.anio = s.anio
CROSS JOIN base
WHERE s.publico IS NOT NULL
ORDER BY s.anio
```

# 🏛️ Public employment

Who works for Spain's public administrations: how many there are, in which administration and which services, where, what they earn and how much they cost.

<Grid cols=4>
    <KpiCard
        title="Public employees"
        value={resumen[0]?.total}
        formattedValue="{formatNumber(por_1000[0]?.por_1000_hab, 1)} per 1,000 inhab."
        period="{formatCompact(resumen[0]?.total, 2)} in total · {ultima[0]?.fecha_texto}"
        source="Registro Central de Personal"
        sparklineData={serie_por_1000.map(d => d.por_1000_hab)}
    />
    <KpiCard
        title="In the autonomous communities"
        value={resumen[0]?.ccaa}
        formattedValue="{formatNumber(resumen[0]?.ccaa / resumen[0]?.total / 0.01, 0)}%"
        period="{formatCompact(resumen[0]?.ccaa, 2)}: mainly health and education"
        source="Registro Central de Personal"
        sparklineData={serie_cuota_ccaa.map(d => d.cuota_ccaa)}
    />
    <KpiCard
        title="Annual cost per inhabitant"
        value={coste_ultimo[0]?.eur_por_habitante}
        formattedValue="€{formatNumber(coste_ultimo[0]?.eur_por_habitante, 0)}"
        period="€{formatNumber(coste_ultimo[0]?.millones_eur / 1000, 1)}bn in total · {formatNumber(coste_ultimo[0]?.pct_pib, 1)}% of GDP · {coste_ultimo[0]?.anio}"
        source="Eurostat"
        sparklineData={coste_serie_real.map(d => d.eur_hab_real)}
    />
    <KpiCard
        title="Average wage (full-time)"
        value={salario_ultimo[0]?.publico}
        formattedValue="€{formatNumber(salario_ultimo[0]?.publico, 0)}/month"
        period="vs €{formatNumber(salario_ultimo[0]?.privado, 0)} in the private sector · {salario_ultimo[0]?.anio}"
        source="INE (EPA)"
        sparklineData={salario_serie_real.map(d => d.publico_real)}
    />
</Grid>

## Where do they work?

```sql sectores
SELECT administracion, sector, sum(efectivos) AS efectivos
FROM mother.empleo_efectivos
WHERE fecha = (SELECT fecha FROM ${ultima})
GROUP BY ALL
ORDER BY efectivos DESC
```

<BarChart
    data={sectores}
    x=sector
    y=efectivos
    series=administracion
    swapXY=true
    yFmt=num0
    sort=false
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b']}
    title="Public employees by sector and administration"
/>

<p class="text-xs text-gray-500">Almost half of public employment is in healthcare and non-university education, which the autonomous communities have managed since the transfers of powers between the 1980s and 2002. Central government mainly retains the Armed Forces, the National Police, the Guardia Civil, the Tax Agency, prisons and ministry services.</p>

```sql tipos
SELECT tipo_personal, sum(efectivos) AS efectivos,
    CASE tipo_personal WHEN 'Funcionario de carrera' THEN 1 WHEN 'Funcionario interino' THEN 2 WHEN 'Laboral fijo' THEN 3 WHEN 'Laboral temporal' THEN 4 WHEN 'Laboral (sin detalle)' THEN 5 ELSE 6 END AS orden
FROM mother.empleo_efectivos
WHERE fecha = (SELECT fecha FROM ${ultima})
GROUP BY ALL
ORDER BY orden
```

```sql sexo_sector
SELECT sector, sum(efectivos) FILTER (WHERE sexo = 'Mujeres') / sum(efectivos) AS cuota_mujeres, sum(efectivos) AS efectivos
FROM mother.empleo_efectivos
WHERE fecha = (SELECT fecha FROM ${ultima})
GROUP BY sector
HAVING sum(efectivos) > 10000
ORDER BY cuota_mujeres DESC
```

<Grid cols=2>
    <BarChart data={tipos} x=tipo_personal y=efectivos sort=false yFmt=num0 fillColor="#0f766e" title="By type of employment relationship" />
    <BarChart data={sexo_sector} x=sector y=cuota_mujeres swapXY=true sort=false yFmt=pct0 fillColor="#a78bfa" title="Share of women by sector" />
</Grid>

<p class="text-xs text-gray-500">{formatNumber(100 * resumen[0]?.temporales / resumen[0]?.total, 0)}% are interim civil servants (interinos) or temporary contract staff. Career civil servant (funcionario de carrera): holds a permanent post after passing a competitive exam (oposición). Interim: fills a vacant post or covers a replacement. Contract staff (laboral): employed under an employment contract (permanent or temporary). In healthcare, statutory staff of the health services are counted as civil servants.</p>

```sql organismos
SELECT
    row_number() OVER (ORDER BY efectivos DESC) AS puesto,
    organismo,
    administracion,
    nullif(ministerio, '') AS ministerio,
    efectivos,
    mujeres / efectivos AS cuota_mujeres
FROM mother.empleo_organismos
ORDER BY efectivos DESC
```

<Details title="Central government bodies with the most staff">

<DataTable data={organismos} rows=20 search=true>
    <Column id=puesto title="#" />
    <Column id=organismo title="Body" />
    <Column id=ministerio title="Parent ministry" />
    <Column id=efectivos title="Staff" fmt=num0 contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_mujeres title="Women" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">Ministries, agencies and central government bodies with 100 or more staff in the latest edition. For the autonomous communities and local authorities the register does not break staff down by regional department or body.</p>

</Details>

## How many are there per inhabitant in each region?

```sql ccaa
SELECT
    t.cod AS cod_ccaa,
    c.nombre AS comunidad,
    '/en' || c.ruta AS ruta,
    max(t.efectivos) FILTER (WHERE t.administracion = 'Total') AS efectivos,
    max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Total') AS por_1000_hab,
    max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Estado') AS estado_1000,
    max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Comunidades autónomas') AS ccaa_1000,
    max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Entidades locales') AS local_1000
FROM mother.empleo_territorio t
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = t.cod
WHERE t.nivel = 'ccaa' AND t.fecha = (SELECT fecha FROM ${ultima})
GROUP BY ALL
ORDER BY por_1000_hab DESC
```

<AreaMap
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod_ccaa"
    value="por_1000_hab"
    valueFmt="num0"
    link="ruta"
    colorPalette={['#eff6ff', '#60a5fa', '#1e3a8a']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: Registro Central de Personal"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'por_1000_hab', title: 'Per 1,000 inhabitants', fmt: 'num0'},
        {id: 'efectivos', title: 'Public employees', fmt: 'num0'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=efectivos title="Public employees" fmt=num0 />
    <Column id=por_1000_hab title="Per 1,000 inhab." fmt=num1 contentType=bar barColor="#bfdbfe" />
    <Column id=estado_1000 title="…central government" fmt=num1 />
    <Column id=ccaa_1000 title="…regional government" fmt=num1 />
    <Column id=local_1000 title="…local government" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">By the region where the job is located. Ceuta and Melilla stand out because of the military and police stationed there, and Madrid because of the ministries' central services. Where a region provides services through contracted providers, consortia or public companies (much of healthcare in Catalonia, for example), those staff do not appear in the register and the rate comes out lower. Click on a region to see its provinces.</p>

## How has it changed?

```sql serie_registro
-- Empleados por 1.000 habitantes (padrón del año; el último disponible para los más recientes)
WITH pob AS (
    SELECT CAST(anio AS INTEGER) AS anio, poblacion
    FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total'
)
SELECT e.fecha, e.administracion, sum(e.efectivos) AS efectivos,
    1000.0 * sum(e.efectivos) / any_value(p.poblacion) AS por_1000
FROM mother.empleo_efectivos e
JOIN pob p ON p.anio = least(CAST(year(e.fecha) AS INTEGER), (SELECT max(anio) FROM pob))
GROUP BY e.fecha, e.administracion
ORDER BY e.fecha
```

<BarChart
    data={serie_registro}
    x=fecha
    y=por_1000
    series=administracion
    type=stacked
    yFmt=num1
    xFmt="mmm yyyy"
    yAxisTitle="per 1,000 inhabitants"
    colorPalette={['#0f766e', '#f59e0b', '#1d4ed8']}
    title="Public employees per 1,000 inhabitants (Central Personnel Register, 1 January and 1 July)"
/>

<p class="text-xs text-gray-500">Note the jump between July 2022 and January 2023 (~+240,000): in August 2026 the Ministry revised every edition since 2023 using new sources and classifications (especially in the autonomous communities), so part of the increase is methodological, not new hiring. Data before July 2019 are not published in open format.</p>

```sql serie_epa
WITH pob AS (
    SELECT CAST(anio AS INTEGER) AS anio, poblacion
    FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total'
)
SELECT e.trimestre, e.administracion, e.asalariados,
    1000.0 * e.asalariados / p.poblacion AS por_1000
FROM mother.empleo_epa_administracion e
JOIN pob p ON p.anio = greatest(least(CAST(year(e.trimestre) AS INTEGER), (SELECT max(anio) FROM pob)), (SELECT min(anio) FROM pob))
WHERE e.administracion NOT IN ('Total', 'Otras / no sabe')
ORDER BY e.trimestre
```

<BarChart
    data={serie_epa}
    x=trimestre
    y=por_1000
    series=administracion
    type=stacked
    yFmt=num1
    xFmt="yyyy"
    yAxisTitle="per 1,000 inhabitants"
    title="Public sector employees per 1,000 inhabitants according to the Labour Force Survey (since 2002)"
/>

<p class="text-xs text-gray-500">The Labour Force Survey (EPA) provides a longer series (quarterly since 2002) and also counts public companies and institutions, but it is a survey: that is why it shows more public employees than the register (around 3.6 million) and its quarterly figure has a margin of error. It shows the cuts of 2011-2014 (from 3.28 to 2.93 million on an annual average, during the debt crisis) and the subsequent growth, faster since 2018.</p>

```sql cuota_ccaa
SELECT e.trimestre, c.nombre AS comunidad, e.cuota_publico
FROM mother.empleo_epa_ccaa e
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = e.cod_ccaa
WHERE e.trimestre = (SELECT max(trimestre) FROM mother.empleo_epa_ccaa)
ORDER BY e.cuota_publico DESC
```

<BarChart
    data={cuota_ccaa}
    x=comunidad
    y=cuota_publico
    swapXY=true
    sort=false
    yFmt=pct0
    fillColor="#1d4ed8"
    title="Public employment as a share of all employees (Labour Force Survey, latest quarter)"
/>

## What do they earn?

```sql deciles
SELECT
    decil,
    'D' || CAST(decil AS VARCHAR) AS decil_txt,
    sector,
    salario_mensual
FROM mother.empleo_salarios_deciles
WHERE jornada = 'Jornada a tiempo completo'
  AND anio = (SELECT max(anio) FROM mother.empleo_salarios_deciles)
  AND decil > 0
  AND sector IN ('Público', 'Privado')
ORDER BY decil
```

```sql brecha
-- En euros constantes del último año completo (descontada la inflación con el IPC)
SELECT
    s.anio,
    max(s.salario_mensual * d.factor) FILTER (WHERE s.sector = 'Público') AS publico,
    max(s.salario_mensual * d.factor) FILTER (WHERE s.sector = 'Privado') AS privado,
    any_value(d.anio_base) AS anio_base
FROM mother.empleo_salarios_deciles s
JOIN mother.deflactor d ON d.anio = CAST(s.anio AS INTEGER)
WHERE s.jornada = 'Jornada a tiempo completo' AND s.decil = 0
GROUP BY s.anio
ORDER BY s.anio
```

<LineChart
    data={brecha}
    x=anio
    y={['publico', 'privado']}
    yFmt=num0
    xFmt="####"
    colorPalette={['#1d4ed8', '#f59e0b']}
    seriesLabels={{publico: 'Public sector', privado: 'Private sector'}}
    legend=true
    yAxisTitle="Gross € per month (constant euros)"
    title="Average gross monthly wage, full-time, in {brecha[0]?.anio_base} euros adjusted for inflation"
/>

<BarChart
    data={deciles}
    x=decil_txt
    y=salario_mensual
    series=sector
    type=grouped
    yFmt=num0
    sort=false
    colorPalette={['#f59e0b', '#1d4ed8']}
    title="Average wage in each decile (from the lowest-paid 10% to the highest-paid 10%)"
/>

<p class="text-xs text-gray-500">Within each decile (each band of 10% of employees ranked by wage), the public and private sectors earn practically the same, and in the top decile the private sector earns more. The average gap comes from composition: there are proportionally many more public employees in the upper bands (doctors, teachers, university graduates, longer service) and almost none in the lowest-paid private-sector jobs (hospitality, retail, agriculture). Gross monthly wage from the main full-time job, before taxes and employee social contributions.</p>

```sql salarios_ccaa
SELECT c.nombre AS comunidad, s.salario_publico, s.salario_privado, s.salario_publico / s.salario_privado - 1 AS diferencia
FROM mother.empleo_salarios_ccaa s
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = s.cod_ccaa
ORDER BY s.salario_publico DESC
```

<DataTable data={salarios_ccaa} rows=all>
    <Column id=comunidad title="Region" />
    <Column id=salario_publico title="Public (€/year)" fmt=num0 />
    <Column id=salario_privado title="Private (€/year)" fmt=num0 />
    <Column id=diferencia title="Difference" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">Average gross annual wage in 2022 according to the INE's four-yearly Structure of Earnings Survey, by region of the workplace and by whether the company or body is publicly or privately controlled. It only covers those contributing to the General Social Security Scheme: it leaves out civil servants covered by mutual funds (MUFACE, ISFAS, MUGEJU).</p>

## How much do they cost?

```sql coste
-- Euros por habitante y constantes (descontada la inflación con el IPC)
SELECT c.anio, c.subsector, c.millones_eur / 1000 AS miles_millones, c.pct_pib,
    c.eur_por_habitante * d.factor AS eur_hab_real, d.anio_base
FROM mother.empleo_coste c
JOIN mother.deflactor d ON d.anio = CAST(c.anio AS INTEGER)
WHERE c.cod_sector <> 'S13'
ORDER BY c.anio
```

```sql coste_total
SELECT anio, pct_pib FROM mother.empleo_coste WHERE cod_sector = 'S13' ORDER BY anio
```

<BarChart
    data={coste}
    x=anio
    y=eur_hab_real
    series=subsector
    type=stacked
    yFmt=num0
    xFmt="####"
    yAxisTitle="€ per inhabitant (constant)"
    title="Cost of public staff per inhabitant by administration, in {coste[0]?.anio_base} euros"
/>

<LineChart
    data={coste_total}
    x=anio
    y=pct_pib
    yFmt=num1
    xFmt="####"
    colorPalette={['#1d4ed8']}
    yAxisTitle="% of GDP"
    title="Cost of public staff as a share of GDP"
/>

<p class="text-xs text-gray-500">Per inhabitant and in constant euros, so that the trend does not merely reflect population and price growth. Compensation of general government employees (national accounts, Eurostat): wages and salaries plus the social contributions paid by the administration as employer. Transfers between administrations are not counted twice: each one pays its own staff.</p>

```sql coste_ccaa
SELECT
    c.nombre AS comunidad,
    '/en' || c.ruta AS ruta,
    g.anio,
    g.gasto_personal_ccaa / 1e6 AS gasto_ccaa_millones,
    g.gasto_personal_ccaa_hab,
    g.gasto_personal_ayuntamientos_hab
FROM mother.empleo_gasto_personal_territorio g
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = g.cod
WHERE g.nivel = 'ccaa'
  AND g.anio = (SELECT max(anio) FROM mother.empleo_gasto_personal_territorio WHERE nivel = 'ccaa' AND gasto_personal_ccaa IS NOT NULL AND gasto_personal_ayuntamientos IS NOT NULL)
ORDER BY g.gasto_personal_ccaa_hab DESC
```

### Staff spending by each region and its town councils ({coste_ccaa[0]?.anio})

<DataTable data={coste_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Region" />
    <Column id=gasto_ccaa_millones title="Regional government (€m)" fmt=num0 />
    <Column id=gasto_personal_ccaa_hab title="Regional government (€/inhab.)" fmt=num0 contentType=bar barColor="#bfdbfe" />
    <Column id=gasto_personal_ayuntamientos_hab title="Town councils (€/inhab.)" fmt=num0 contentType=bar barColor="#fde68a" />
</DataTable>

<p class="text-xs text-gray-500">Chapter 1 ("staff costs") of the outturn accounts: the region's figure from the Ministry of Finance; the town councils' figure is the sum of those that submitted their outturn accounts to the Ministry (CONPREL), per inhabitant of those municipalities. The Basque Country and Navarre collect their own taxes (the foral regime) and take on more responsibilities, which raises their spending; in Álava and Navarre town councils do not appear in CONPREL. Each town council's staff spending is on its page in <a href="/en/territorios/municipios">municipalities</a>.</p>

---

## Sources and notes

- **[Statistical Bulletin of Personnel in the Service of Public Administrations (Central Personnel Register)](https://digital.gob.es/funcion-publica/dgfp/registro-central-personal/boletin.html)**, Ministry for Digital Transformation and the Civil Service: staff as at 1 January and 1 July since 2019. It does not include public companies or foundations, nor does it go down to each town council (only by type of entity and province). Local authority staff figures come from Social Security registrations.
- **[INE – Labour Force Survey](https://www.ine.es/jaxiT3/Tabla.htm?t=65193)**: public sector employees by administration (table 65193) and by region (65327); wages by decile (66250).
- **[INE – Structure of Earnings Survey 2022](https://www.ine.es/jaxiT3/Tabla.htm?t=36887)**: annual wage by region and public or private control.
- **[Eurostat – gov_10a_main](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_main/default/table)**: compensation of employees (D1) of general government by subsector.
- **Ministry of Finance**: outturn accounts of the autonomous communities and local authorities (CONPREL), chapter 1.
- The three counts measure different things: the register counts people holding a post in an administration; the EPA estimates employees who say they work in the public sector (including public companies); the national accounts measure the cost.

<LastRefreshed prefix="Data updated" />
