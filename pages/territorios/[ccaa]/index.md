---
breadcrumb: "SELECT nombre AS breadcrumb FROM mother.territorios WHERE nivel = 'ccaa' AND slug = '${params.ccaa}'"
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql terr
SELECT * FROM mother.territorios WHERE nivel = 'ccaa' AND slug = '${params.ccaa}'
```

```sql espana
SELECT poblacion_ultima FROM mother.territorios WHERE nivel = 'pais'
```

```sql serie_poblacion
SELECT make_date(CAST(anio AS INTEGER), 1, 1) AS fecha, poblacion AS valor
FROM mother.poblacion_territorios
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND sexo = 'Total'
ORDER BY anio
```

```sql poblacion_sexo
SELECT sexo, poblacion
FROM mother.poblacion_territorios
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND sexo <> 'Total'
  AND anio = (SELECT max(anio) FROM mother.poblacion_territorios)
```

```sql provincias
SELECT
    t.cod, t.nombre, t.ruta, t.poblacion_ultima AS poblacion,
    count(m.cod_mun) AS municipios
FROM mother.territorios t
LEFT JOIN mother.poblacion_municipios m
  ON m.cod_prov = t.cod AND m.anio = t.anio_poblacion
WHERE t.nivel = 'provincia' AND t.cod_ccaa = '${terr[0]?.cod}'
GROUP BY ALL
ORDER BY poblacion DESC
```

```sql municipios
WITH ultimo AS (SELECT max(anio) AS anio FROM mother.poblacion_municipios),
actual AS (
    SELECT cod_mun, municipio, cod_prov, poblacion
    FROM mother.poblacion_municipios
    WHERE cod_ccaa = '${terr[0]?.cod}' AND anio = (SELECT anio FROM ultimo)
),
antes AS (
    SELECT cod_mun, poblacion AS poblacion_antes
    FROM mother.poblacion_municipios
    WHERE cod_ccaa = '${terr[0]?.cod}' AND anio = (SELECT anio - 9 FROM ultimo)
)
SELECT
    a.cod_mun, a.municipio, p.nombre AS provincia, a.poblacion,
    100.0 * (a.poblacion - b.poblacion_antes) / nullif(b.poblacion_antes, 0) AS crecimiento,
    '/territorios/municipios?m=' || a.cod_mun AS enlace
FROM actual a
LEFT JOIN antes b USING (cod_mun)
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = a.cod_prov
ORDER BY a.poblacion DESC
```

```sql resumen_municipios
SELECT
    count(*) AS n,
    count(*) FILTER (WHERE poblacion < 1000) AS menos_1000,
    count(*) FILTER (WHERE crecimiento < 0) AS pierden,
    quantile_cont(poblacion, 0.9) AS p90
FROM ${municipios}
```

# {terr[0]?.nombre}

<p class="text-sm text-gray-500"><a href="/territorios">Territorios</a> › {terr[0]?.nombre}</p>

<Grid cols=3>
    <KpiCard
        title="Población"
        value={terr[0]?.poblacion_ultima}
        formattedValue={formatNumber(terr[0]?.poblacion_ultima, 0)}
        unit="hab."
        period="1 de enero de {terr[0]?.anio_poblacion}"
        source="INE – Padrón"
        sparklineData={serie_poblacion}
    />
    <KpiCard
        title="Peso en España"
        value={100 * terr[0]?.poblacion_ultima / espana[0]?.poblacion_ultima}
        formattedValue={formatNumber(100 * terr[0]?.poblacion_ultima / espana[0]?.poblacion_ultima, 1)}
        unit="%"
        period="de la población española"
    />
    <KpiCard
        title="Municipios"
        value={resumen_municipios[0]?.n}
        formattedValue={formatNumber(resumen_municipios[0]?.n, 0)}
        period="{formatNumber(resumen_municipios[0]?.menos_1000, 0)} con menos de 1.000 hab. · {formatNumber(resumen_municipios[0]?.pierden, 0)} pierden población en 10 años"
    />
</Grid>

## Población

<LineChart
    data={serie_poblacion}
    x=fecha
    y=valor
    yFmt=num0
    title="Población a 1 de enero (Padrón)"
    lineColor="#1d4ed8"
/>

{#if provincias.length > 1}

## Provincias

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 not-prose">
{#each provincias as p}
    <a href={p.ruta} class="block rounded-lg border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-3 hover:border-blue-400 no-underline">
        <span class="font-semibold text-gray-900 dark:text-white">{p.nombre}</span>
        <span class="block text-xs text-gray-500">{formatNumber(p.poblacion, 0)} hab. · {p.municipios} municipios</span>
    </a>
{/each}
</div>

{:else}

<p>{terr[0]?.nombre} es una comunidad uniprovincial. <a href={provincias[0]?.ruta}>Ver la ficha provincial de {provincias[0]?.nombre}</a>.</p>

{/if}

## Municipios

<AreaMap
    data={municipios}
    geoJsonUrl="/geo/municipios/{terr[0]?.cod}.geojson"
    geoId="cod_mun"
    areaCol="cod_mun"
    value="poblacion"
    valueFmt="num0"
    max={resumen_municipios[0]?.p90}
    colorPalette={['#eff6ff', '#60a5fa', '#1e3a8a']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Límites © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'municipio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'poblacion', title: 'Población', fmt: 'num0'},
        {id: 'crecimiento', title: 'Crecimiento 10 años (%)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">La escala de color satura en el 10 % de municipios más poblados para que se distingan los pequeños.</p>

<DataTable data={municipios} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Población" fmt=num0 />
    <Column id=crecimiento title="Crecimiento 10 años (%)" fmt=num1 contentType=delta />
</DataTable>

```sql cuentas
SELECT
    r.anio,
    make_date(CAST(r.anio AS INTEGER), 1, 1) AS fecha,
    r.ingresos_no_financieros,
    r.gastos_no_financieros,
    r.saldo_no_financiero,
    r.gastos_totales,
    p.poblacion,
    r.gastos_no_financieros / p.poblacion AS gasto_hab,
    r.ingresos_no_financieros / p.poblacion AS ingreso_hab
FROM mother.ccaa_cuentas_resumen r
JOIN mother.poblacion_territorios p
  ON p.nivel = 'ccaa' AND p.cod = r.cod_ccaa AND p.anio = r.anio AND p.sexo = 'Total'
WHERE r.cod_ccaa = '${terr[0]?.cod}'
ORDER BY r.anio
```

```sql cuentas_ultimo
SELECT * FROM ${cuentas} ORDER BY anio DESC LIMIT 1
```

```sql cuentas_evolucion
SELECT fecha, 'Ingresos' AS concepto, ingresos_no_financieros AS importe FROM ${cuentas}
UNION ALL
SELECT fecha, 'Gastos', gastos_no_financieros FROM ${cuentas}
ORDER BY fecha
```

```sql gasto_ranking
WITH ultimo AS (SELECT max(anio) AS anio FROM mother.ccaa_cuentas_resumen WHERE cod_ccaa <= '17')
SELECT
    t.nombre AS comunidad,
    r.gastos_no_financieros / p.poblacion AS gasto_hab,
    CASE WHEN r.cod_ccaa = '${terr[0]?.cod}' THEN 'Esta comunidad' ELSE 'Resto' END AS grupo
FROM mother.ccaa_cuentas_resumen r
JOIN mother.poblacion_territorios p
  ON p.nivel = 'ccaa' AND p.cod = r.cod_ccaa AND p.anio = r.anio AND p.sexo = 'Total'
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = r.cod_ccaa
WHERE r.anio = (SELECT anio FROM ultimo) AND r.cod_ccaa <= '17'
ORDER BY gasto_hab DESC
```

```sql politicas
-- Gasto por política (depurado de transferencias a ayuntamientos y fondos
-- PAC) por habitante, frente a la media de las 17 comunidades.
WITH anio AS (SELECT max(anio) AS anio FROM mother.ccaa_gasto_politicas WHERE cod_ccaa = '${terr[0]?.cod}'),
por_ccaa AS (
    SELECT g.cod_ccaa, g.cod_politica, g.politica_nombre, sum(g.obligaciones) AS obligaciones, p.poblacion
    FROM mother.ccaa_gasto_politicas g
    JOIN mother.poblacion_territorios p
      ON p.nivel = 'ccaa' AND p.cod = g.cod_ccaa AND p.anio = g.anio AND p.sexo = 'Total'
    WHERE g.anio = (SELECT anio FROM anio) AND g.cod_ccaa <= '17'
    GROUP BY ALL
),
media AS (
    SELECT cod_politica, sum(obligaciones) / sum(poblacion) AS media_hab
    FROM por_ccaa GROUP BY cod_politica
)
SELECT
    c.politica_nombre AS politica,
    c.obligaciones,
    c.obligaciones / c.poblacion AS por_habitante,
    m.media_hab AS media_ccaa,
    100.0 * (c.obligaciones / c.poblacion - m.media_hab) / nullif(m.media_hab, 0) AS dif_pct,
    c.obligaciones / sum(c.obligaciones) OVER () AS peso
FROM por_ccaa c
JOIN media m USING (cod_politica)
WHERE c.cod_ccaa = '${terr[0]?.cod}' AND c.obligaciones > 0
ORDER BY c.obligaciones DESC
```

```sql politicas_grafico
SELECT politica, 'Esta comunidad' AS serie, por_habitante AS euros FROM ${politicas} WHERE peso >= 0.02
UNION ALL
SELECT politica, 'Media de las CCAA', media_ccaa FROM ${politicas} WHERE peso >= 0.02
```

```sql capitulos
SELECT
    CASE tipo WHEN 'ingreso' THEN 'Ingresos' ELSE 'Gastos' END AS tipo,
    capitulo,
    capitulo_nombre,
    presupuesto_definitivo,
    ejecutado,
    ejecutado / nullif(presupuesto_definitivo, 0) AS grado_ejecucion
FROM mother.ccaa_cuentas_capitulos
WHERE cod_ccaa = '${terr[0]?.cod}'
  AND anio = (SELECT max(anio) FROM mother.ccaa_cuentas_capitulos WHERE cod_ccaa = '${terr[0]?.cod}')
ORDER BY tipo DESC, capitulo
```

{#if cuentas.length > 0 && cuentas_ultimo[0]?.anio >= 2020}

## Ingresos y gastos de la comunidad

Cuentas ejecutadas (liquidación) de la administración autonómica consolidada. Se usa el gasto **no financiero** (capítulos 1 a 7), que deja fuera la compra de activos y la devolución de deuda, para comparar lo que cada comunidad gasta de verdad en servicios.

<Grid cols=3>
    <KpiCard
        title="Gasto no financiero"
        value={cuentas_ultimo[0]?.gastos_no_financieros}
        formattedValue={formatCompact(cuentas_ultimo[0]?.gastos_no_financieros, 1)}
        unit="€"
        period="Liquidación {cuentas_ultimo[0]?.anio}"
        source="Ministerio de Hacienda"
    />
    <KpiCard
        title="Gasto por habitante"
        value={cuentas_ultimo[0]?.gasto_hab}
        formattedValue={formatNumber(cuentas_ultimo[0]?.gasto_hab, 0)}
        unit="€"
        period="Ingresos no financieros: {formatNumber(cuentas_ultimo[0]?.ingreso_hab, 0)} € por habitante"
    />
    <KpiCard
        title="Saldo no financiero"
        value={cuentas_ultimo[0]?.saldo_no_financiero}
        formattedValue={formatCompact(cuentas_ultimo[0]?.saldo_no_financiero, 1)}
        unit="€"
        period="Ingresos − gastos no financieros (criterio presupuestario)"
        direction="positive-up"
    />
</Grid>

<BarChart
    data={gasto_ranking}
    x=comunidad
    y=gasto_hab
    series=grupo
    swapXY=true
    yFmt=num0
    title="Gasto no financiero por habitante en {cuentas_ultimo[0]?.anio} (€)"
    colorPalette={['#0f766e', '#cbd5e1']}
    sort=false
/>

### ¿En qué gasta?

<BarChart
    data={politicas_grafico}
    x=politica
    y=euros
    series=serie
    type=grouped
    swapXY=true
    yFmt=num0
    title="Euros por habitante en cada política (las que pesan al menos un 2 %)"
    colorPalette={['#0f766e', '#94a3b8']}
/>

<DataTable data={politicas} rows=all>
    <Column id=politica title="Política de gasto" />
    <Column id=obligaciones title="Gasto (€)" fmt=num0 />
    <Column id=peso title="Peso" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=por_habitante title="€/habitante" fmt=num0 />
    <Column id=media_ccaa title="Media CCAA (€/hab.)" fmt=num0 />
    <Column id=dif_pct title="Diferencia (%)" fmt=num0 contentType=delta />
</DataTable>

### Evolución

<LineChart
    data={cuentas_evolucion}
    x=fecha
    y=importe
    series=concepto
    yFmt=num0
    title="Ingresos y gastos no financieros (€)"
    colorPalette={['#0f766e', '#b45309']}
/>

<Details title="Detalle por capítulos del último año">

<DataTable data={capitulos} rows=all groupBy=tipo>
    <Column id=capitulo title="Cap." />
    <Column id=capitulo_nombre title="Capítulo" />
    <Column id=presupuesto_definitivo title="Presupuesto definitivo (€)" fmt=num0 />
    <Column id=ejecutado title="Ejecutado (€)" fmt=num0 />
    <Column id=grado_ejecucion title="Ejecución" fmt=pct0 />
</DataTable>

</Details>

{:else}

<p class="text-sm text-gray-500">Hacienda solo publica la liquidación de {terr[0]?.nombre} hasta 2012, por lo que no se muestra la comparación con el resto de comunidades.</p>

{/if}

```sql deuda
SELECT fecha, anio, trimestre, deuda_eur, deuda_pct_pib
FROM mother.ccaa_deuda
WHERE cod_ccaa = '${terr[0]?.cod}'
ORDER BY fecha
```

```sql deuda_ultima
SELECT
    d.fecha, d.anio, d.trimestre, d.deuda_eur, d.deuda_pct_pib,
    d.deuda_eur / nullif(${terr[0]?.poblacion_ultima}, 0) AS deuda_por_habitante,
    a.deuda_pct_pib AS pct_pib_hace_un_anio
FROM mother.ccaa_deuda d
LEFT JOIN mother.ccaa_deuda a
  ON a.cod_ccaa = d.cod_ccaa AND a.fecha = d.fecha - INTERVAL 1 YEAR
WHERE d.cod_ccaa = '${terr[0]?.cod}'
ORDER BY d.fecha DESC
LIMIT 1
```

```sql deuda_ranking
SELECT
    t.nombre AS comunidad,
    d.deuda_pct_pib / 100 AS deuda_pct_pib,
    CASE WHEN d.cod_ccaa = '${terr[0]?.cod}' THEN 'Esta comunidad' ELSE 'Resto' END AS grupo
FROM mother.ccaa_deuda d
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = d.cod_ccaa
WHERE d.fecha = (SELECT max(fecha) FROM mother.ccaa_deuda)
ORDER BY d.deuda_pct_pib DESC
```

```sql saldo
SELECT make_date(CAST(anio AS INTEGER), 1, 1) AS fecha, anio, saldo_eur, saldo_pct_pib / 100 AS saldo_pct_pib
FROM mother.ccaa_saldo
WHERE cod_ccaa = '${terr[0]?.cod}'
ORDER BY anio
```

{#if deuda.length > 0}

## Deuda y déficit

<Grid cols=3>
    <KpiCard
        title="Deuda pública"
        value={deuda_ultima[0]?.deuda_eur}
        formattedValue={formatCompact(deuda_ultima[0]?.deuda_eur, 1)}
        unit="€"
        period="{deuda_ultima[0]?.trimestre}.º trim. {deuda_ultima[0]?.anio}"
        source="Banco de España (PDE)"
    />
    <KpiCard
        title="Deuda sobre el PIB regional"
        value={deuda_ultima[0]?.deuda_pct_pib}
        formattedValue={formatNumber(deuda_ultima[0]?.deuda_pct_pib, 1)}
        unit="%"
        change={deuda_ultima[0]?.pct_pib_hace_un_anio != null ? (deuda_ultima[0].deuda_pct_pib - deuda_ultima[0].pct_pib_hace_un_anio).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. hace un año"
        direction="positive-down"
    />
    <KpiCard
        title="Deuda por habitante"
        value={deuda_ultima[0]?.deuda_por_habitante}
        formattedValue={formatNumber(deuda_ultima[0]?.deuda_por_habitante, 0)}
        unit="€"
        period="con la población del Padrón {terr[0]?.anio_poblacion}"
    />
</Grid>

<BarChart
    data={deuda_ranking}
    x=comunidad
    y=deuda_pct_pib
    series=grupo
    swapXY=true
    yFmt=pct0
    title="Deuda sobre el PIB regional, todas las comunidades"
    colorPalette={['#1d4ed8', '#cbd5e1']}
    sort=false
/>

<LineChart
    data={deuda}
    x=fecha
    y=deuda_pct_pib
    yFmt=num0
    yAxisTitle="% del PIB regional"
    title="Evolución de la deuda (% del PIB regional)"
    lineColor="#1d4ed8"
/>

{#if saldo.length > 0}

<BarChart
    data={saldo}
    x=anio
    y=saldo_pct_pib
    yFmt=pct1
    title="Superávit (+) o déficit (−) anual, % del PIB regional"
    fillColor="#64748b"
/>

<p class="text-xs text-gray-500">El saldo anual es la suma de los doce meses publicados por el Banco de España (solo años completos); el porcentaje se calcula con el PIB regional implícito en sus series de deuda.</p>

{/if}

{:else}

<p class="text-sm text-gray-500">El Banco de España no publica deuda propia de {terr[0]?.nombre}: en el Protocolo de Déficit Excesivo Ceuta y Melilla se contabilizan como administración local.</p>

{/if}

```sql empleo
WITH ult AS (SELECT max(fecha) AS fecha FROM mother.empleo_territorio)
SELECT
    strftime(t.fecha, '%d/%m/%Y') AS fecha_texto,
    max(t.efectivos) FILTER (WHERE t.administracion = 'Total') AS efectivos,
    max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Total') AS por_1000,
    max(t.efectivos) FILTER (WHERE t.administracion = 'Estado') AS estado,
    max(t.efectivos) FILTER (WHERE t.administracion = 'Comunidades autónomas') AS ccaa,
    max(t.efectivos) FILTER (WHERE t.administracion = 'Entidades locales') AS local,
    (SELECT por_1000_hab FROM mother.empleo_territorio WHERE nivel = 'pais' AND administracion = 'Total' AND fecha = t.fecha) AS por_1000_espana,
    (SELECT count(*) + 1 FROM mother.empleo_territorio o
      WHERE o.nivel = 'ccaa' AND o.administracion = 'Total' AND o.fecha = t.fecha
        AND o.por_1000_hab > max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Total')) AS puesto
FROM mother.empleo_territorio t, ult
WHERE t.nivel = 'ccaa' AND t.cod = '${terr[0]?.cod}' AND t.fecha = ult.fecha
GROUP BY t.fecha
```

```sql empleo_sectores
SELECT sector, administracion, sum(efectivos) AS efectivos
FROM mother.empleo_efectivos
WHERE cod_ccaa = '${terr[0]?.cod}' AND fecha = (SELECT max(fecha) FROM mother.empleo_efectivos)
GROUP BY ALL
ORDER BY efectivos DESC
```

```sql empleo_serie
SELECT fecha, administracion, efectivos
FROM mother.empleo_territorio
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND administracion <> 'Total'
ORDER BY fecha
```

```sql empleo_gasto
SELECT
    g.anio,
    g.gasto_personal_ccaa,
    g.gasto_personal_ccaa_hab,
    g.gasto_personal_ayuntamientos_hab,
    (SELECT avg(gasto_personal_ccaa_hab) FROM mother.empleo_gasto_personal_territorio x WHERE x.nivel = 'ccaa' AND x.anio = g.anio AND x.cod <= '17') AS media_ccaa_hab,
    (SELECT gasto_personal_ayuntamientos_hab FROM mother.empleo_gasto_personal_territorio x WHERE x.nivel = 'pais' AND x.anio = g.anio) AS aytos_espana_hab
FROM mother.empleo_gasto_personal_territorio g
WHERE g.nivel = 'ccaa' AND g.cod = '${terr[0]?.cod}' AND g.gasto_personal_ccaa IS NOT NULL
ORDER BY g.anio DESC
LIMIT 1
```

```sql empleo_salario
SELECT salario_publico, salario_privado FROM mother.empleo_salarios_ccaa WHERE cod_ccaa = '${terr[0]?.cod}'
```

```sql crimen_ccaa
SELECT
    b.anio,
    b.tasa_1000 AS tasa,
    b.infracciones,
    e.tasa_1000 AS tasa_espana
FROM mother.crimen_balance b
JOIN mother.crimen_balance e ON e.nivel = 'pais' AND e.anio = b.anio AND e.categoria = b.categoria
WHERE b.nivel = 'ccaa' AND b.cod = '${terr[0]?.cod}' AND b.categoria = 'Total infracciones penales'
ORDER BY b.anio
```

{#if crimen_ccaa.length > 0}

## Seguridad

<LineChart
    data={crimen_ccaa}
    x=anio
    y={['tasa', 'tasa_espana']}
    yFmt=num1
    xFmt="####"
    seriesLabels={{tasa: terr[0]?.nombre, tasa_espana: 'España'}}
    colorPalette={['#b91c1c', '#94a3b8']}
    legend=true
    yAxisTitle="por 1.000 habitantes"
    title="Infracciones penales conocidas por 1.000 habitantes"
/>

<p class="text-xs text-gray-500">{formatNumber(crimen_ccaa.slice(-1)[0]?.infracciones, 0)} infracciones conocidas en {crimen_ccaa.slice(-1)[0]?.anio} (Ministerio del Interior; incluye policías autonómicas). 2020 es el año del confinamiento. Detalle por tipo de delito y municipio en <a href="/sociedad/criminalidad">Criminalidad</a>.</p>

{/if}

{#if empleo.length > 0}

## Empleo público

<Grid cols=3>
    <KpiCard
        title="Empleados públicos"
        value={empleo[0]?.efectivos}
        formattedValue={formatNumber(empleo[0]?.efectivos, 0)}
        period="en {terr[0]?.nombre} · {empleo[0]?.fecha_texto}"
        source="Registro Central de Personal"
    />
    <KpiCard
        title="Por cada 1.000 habitantes"
        value={empleo[0]?.por_1000}
        formattedValue={formatNumber(empleo[0]?.por_1000, 1)}
        period="España: {formatNumber(empleo[0]?.por_1000_espana, 1)} · puesto {empleo[0]?.puesto} de 19"
        source="Registro Central de Personal"
    />
    {#if empleo_gasto.length > 0}
    <KpiCard
        title="Gasto de personal de la comunidad"
        value={empleo_gasto[0]?.gasto_personal_ccaa_hab}
        formattedValue="{formatNumber(empleo_gasto[0]?.gasto_personal_ccaa_hab, 0)} €/hab."
        period="{formatNumber(empleo_gasto[0]?.gasto_personal_ccaa / 1e9, 1)} mil M€ en {empleo_gasto[0]?.anio} · media de las comunidades: {formatNumber(empleo_gasto[0]?.media_ccaa_hab, 0)} €"
        source="Hacienda (capítulo 1)"
    />
    {/if}
</Grid>

<Grid cols=2>
    <BarChart
        data={empleo_sectores}
        x=sector
        y=efectivos
        series=administracion
        swapXY=true
        sort=false
        yFmt=num0
        colorPalette={['#1d4ed8', '#0f766e', '#f59e0b']}
        title="Por sector y administración"
    />
    <BarChart
        data={empleo_serie}
        x=fecha
        y=efectivos
        series=administracion
        type=stacked
        yFmt=num0
        xFmt="mmm yyyy"
        colorPalette={['#0f766e', '#f59e0b', '#1d4ed8']}
        title="Evolución (1 de enero y 1 de julio)"
    />
</Grid>

<p class="text-xs text-gray-500">Personal con puesto en {terr[0]?.nombre} de las tres administraciones: el Estado (Guardia Civil, Policía Nacional, militares, Agencia Tributaria...), la comunidad (sanidad, educación, universidades...) y las entidades locales. {#if empleo_gasto.length > 0 && empleo_gasto[0]?.gasto_personal_ayuntamientos_hab}Los ayuntamientos de la comunidad gastaron en personal {formatNumber(empleo_gasto[0].gasto_personal_ayuntamientos_hab, 0)} € por habitante en {empleo_gasto[0].anio} (media de España: {formatNumber(empleo_gasto[0].aytos_espana_hab, 0)} €).{/if} {#if empleo_salario.length > 0 && empleo_salario[0]?.salario_publico}Salario medio bruto en 2022: {formatNumber(empleo_salario[0].salario_publico, 0)} € al año en el sector público y {formatNumber(empleo_salario[0].salario_privado, 0)} € en el privado (INE).{/if} El salto de 2023 es en parte una revisión del registro. Más en <a href="/cuentas-publicas/empleo-publico">Empleo público</a>.</p>

{/if}

---

## Fuentes oficiales

- **[INE – Cifras oficiales de población de los municipios (Padrón)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**
- **[Ministerio de Hacienda – Liquidación de los presupuestos de las CCAA](https://serviciostelematicosext.hacienda.gob.es/sgcief/publicacionliquidaciones/aspx/menuinicio.aspx)**: datos consolidados; el gasto por políticas está depurado de la participación de las entidades locales en los tributos y de los fondos de la PAC, que solo transitan por las cuentas autonómicas.
- **[Banco de España – Boletín Estadístico, capítulo 13](https://www.bde.es/webbe/es/estadisticas/temas/administraciones-publicas.html)**: deuda según el Protocolo de Déficit Excesivo y capacidad/necesidad de financiación de las comunidades autónomas.
- **[Registro Central de Personal – Boletín Estadístico del Personal al Servicio de las AAPP](https://digital.gob.es/funcion-publica/dgfp/registro-central-personal/boletin.html)**: empleados públicos por administración y provincia del puesto; **[INE – Encuesta de Estructura Salarial 2022](https://www.ine.es/jaxiT3/Tabla.htm?t=36887)**: salarios públicos y privados.
- **[Instituto Geográfico Nacional (vía es-atlas)](https://github.com/martgnz/es-atlas)**: límites municipales (CC BY 4.0).

<LastRefreshed prefix="Datos actualizados" />
