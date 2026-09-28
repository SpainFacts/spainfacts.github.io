---
breadcrumb: "SELECT nombre AS breadcrumb FROM mother.territorios WHERE nivel = 'provincia' AND slug = '${params.provincia}'"
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql terr
SELECT p.*, c.nombre AS ccaa_nombre, c.ruta AS ccaa_ruta, c.poblacion_ultima AS ccaa_poblacion
FROM mother.territorios p
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = p.cod_ccaa
WHERE p.nivel = 'provincia' AND p.slug = '${params.provincia}' AND c.slug = '${params.ccaa}'
```

```sql serie_poblacion
SELECT make_date(CAST(anio AS INTEGER), 1, 1) AS fecha, poblacion AS valor
FROM mother.poblacion_territorios
WHERE nivel = 'provincia' AND cod = '${terr[0]?.cod}' AND sexo = 'Total'
ORDER BY anio
```

```sql municipios
WITH ultimo AS (SELECT max(anio) AS anio FROM mother.poblacion_municipios),
actual AS (
    SELECT cod_mun, municipio, poblacion
    FROM mother.poblacion_municipios
    WHERE cod_prov = '${terr[0]?.cod}' AND anio = (SELECT anio FROM ultimo)
),
antes AS (
    SELECT cod_mun, poblacion AS poblacion_antes
    FROM mother.poblacion_municipios
    WHERE cod_prov = '${terr[0]?.cod}' AND anio = (SELECT anio - 9 FROM ultimo)
)
SELECT
    a.cod_mun, a.municipio, a.poblacion,
    100.0 * (a.poblacion - b.poblacion_antes) / nullif(b.poblacion_antes, 0) AS crecimiento,
    '/territorios/municipios?m=' || a.cod_mun AS enlace
FROM actual a
LEFT JOIN antes b USING (cod_mun)
ORDER BY a.poblacion DESC
```

```sql resumen_municipios
SELECT
    count(*) AS n,
    count(*) FILTER (WHERE poblacion < 1000) AS menos_1000,
    count(*) FILTER (WHERE crecimiento < 0) AS pierden,
    quantile_cont(poblacion, 0.9) AS p90,
    max(poblacion) / sum(poblacion) * 100 AS peso_mayor,
    arg_max(municipio, poblacion) AS mayor
FROM ${municipios}
```

# {terr[0]?.nombre}

<p class="text-sm text-gray-500"><a href="/territorios">Territorios</a> › <a href={terr[0]?.ccaa_ruta}>{terr[0]?.ccaa_nombre}</a> › {terr[0]?.nombre}</p>

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
        title="Municipios"
        value={resumen_municipios[0]?.n}
        formattedValue={formatNumber(resumen_municipios[0]?.n, 0)}
        period="{formatNumber(resumen_municipios[0]?.menos_1000, 0)} con menos de 1.000 hab. · {formatNumber(resumen_municipios[0]?.pierden, 0)} pierden población en 10 años"
    />
    <KpiCard
        title="Mayor municipio"
        value={resumen_municipios[0]?.peso_mayor}
        formattedValue={formatNumber(resumen_municipios[0]?.peso_mayor, 1)}
        unit="%"
        period="de la población vive en {resumen_municipios[0]?.mayor}"
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

## Municipios

<AreaMap
    data={municipios}
    geoJsonUrl="/geo/municipios/{terr[0]?.cod_ccaa}.geojson"
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

<DataTable data={municipios} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipio" />
    <Column id=poblacion title="Población" fmt=num0 />
    <Column id=crecimiento title="Crecimiento 10 años (%)" fmt=num1 contentType=delta />
</DataTable>

```sql deuda_local
SELECT
    make_date(CAST(anio AS INTEGER), 12, 31) AS fecha,
    anio,
    deuda_eur,
    deuda_ayuntamientos_eur,
    deuda_diputaciones_eur,
    deuda_resto_eell_eur
FROM mother.local_deuda_provincia
WHERE cod_prov = '${terr[0]?.cod}'
ORDER BY anio
```

```sql deuda_local_ultima
SELECT *, deuda_eur / nullif(${terr[0]?.poblacion_ultima}, 0) AS por_habitante
FROM ${deuda_local}
ORDER BY anio DESC
LIMIT 1
```

```sql deuda_local_tipo
SELECT fecha, 'Ayuntamientos' AS tipo, deuda_ayuntamientos_eur AS deuda FROM ${deuda_local}
UNION ALL SELECT fecha, 'Diputación / cabildo / consell', deuda_diputaciones_eur FROM ${deuda_local}
UNION ALL SELECT fecha, 'Otras entidades locales', deuda_resto_eell_eur FROM ${deuda_local}
ORDER BY fecha
```

```sql deuda_ciudades
SELECT municipio, fecha, deuda_eur
FROM mother.local_deuda_municipio
WHERE substr(cod_mun, 1, 2) = '${terr[0]?.cod}'
ORDER BY fecha
```

{#if deuda_local.length > 0}

## Deuda de las administraciones locales

<Grid cols=2>
    <KpiCard
        title="Deuda viva local"
        value={deuda_local_ultima[0]?.deuda_eur}
        formattedValue={formatCompact(deuda_local_ultima[0]?.deuda_eur, 1)}
        unit="€"
        period="31 de diciembre de {deuda_local_ultima[0]?.anio} · ayuntamientos, diputación y otras entidades"
        source="Ministerio de Hacienda"
    />
    <KpiCard
        title="Por habitante"
        value={deuda_local_ultima[0]?.por_habitante}
        formattedValue={formatNumber(deuda_local_ultima[0]?.por_habitante, 0)}
        unit="€"
        period="con la población del Padrón {terr[0]?.anio_poblacion}"
    />
</Grid>

<AreaChart
    data={deuda_local_tipo}
    x=fecha
    y=deuda
    series=tipo
    yFmt=num0
    title="Deuda viva de las entidades locales de la provincia (€)"
    colorPalette={['#1d4ed8', '#60a5fa', '#cbd5e1']}
/>

{#if deuda_ciudades.length > 0}

<LineChart
    data={deuda_ciudades}
    x=fecha
    y=deuda_eur
    series=municipio
    yFmt=num0
    title="Deuda de los grandes ayuntamientos (€, Banco de España)"
/>

{/if}

{/if}

```sql empleo_prov
WITH ult AS (SELECT max(fecha) AS fecha FROM mother.empleo_territorio)
SELECT
    strftime(t.fecha, '%d/%m/%Y') AS fecha_texto,
    max(t.efectivos) FILTER (WHERE t.administracion = 'Total') AS efectivos,
    max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Total') AS por_1000,
    (SELECT por_1000_hab FROM mother.empleo_territorio WHERE nivel = 'pais' AND administracion = 'Total' AND fecha = t.fecha) AS por_1000_espana
FROM mother.empleo_territorio t, ult
WHERE t.nivel = 'provincia' AND t.cod = '${terr[0]?.cod}' AND t.fecha = ult.fecha
GROUP BY t.fecha
```

```sql empleo_prov_sectores
SELECT sector, administracion, sum(efectivos) AS efectivos
FROM mother.empleo_efectivos
WHERE cod_prov = '${terr[0]?.cod}' AND fecha = (SELECT max(fecha) FROM mother.empleo_efectivos)
GROUP BY ALL
ORDER BY efectivos DESC
```

```sql empleo_prov_aytos
SELECT
    g.anio,
    g.gasto_personal_ayuntamientos,
    g.gasto_personal_ayuntamientos_hab,
    g.ayuntamientos_con_datos,
    (SELECT gasto_personal_ayuntamientos_hab FROM mother.empleo_gasto_personal_territorio x WHERE x.nivel = 'pais' AND x.anio = g.anio) AS espana_hab
FROM mother.empleo_gasto_personal_territorio g
WHERE g.nivel = 'provincia' AND g.cod = '${terr[0]?.cod}'
ORDER BY g.anio DESC
LIMIT 1
```

{#if empleo_prov.length > 0}

## Empleo público

<Grid cols=3>
    <KpiCard
        title="Empleados públicos"
        value={empleo_prov[0]?.efectivos}
        formattedValue={formatNumber(empleo_prov[0]?.efectivos, 0)}
        period="con puesto en la provincia · {empleo_prov[0]?.fecha_texto}"
        source="Registro Central de Personal"
    />
    <KpiCard
        title="Por cada 1.000 habitantes"
        value={empleo_prov[0]?.por_1000}
        formattedValue={formatNumber(empleo_prov[0]?.por_1000, 1)}
        period="España: {formatNumber(empleo_prov[0]?.por_1000_espana, 1)}"
        source="Registro Central de Personal"
    />
    {#if empleo_prov_aytos.length > 0}
    <KpiCard
        title="Gasto de personal de los ayuntamientos"
        value={empleo_prov_aytos[0]?.gasto_personal_ayuntamientos_hab}
        formattedValue="{formatNumber(empleo_prov_aytos[0]?.gasto_personal_ayuntamientos_hab, 0)} €/hab."
        period="{empleo_prov_aytos[0]?.anio} · España: {formatNumber(empleo_prov_aytos[0]?.espana_hab, 0)} € · {formatNumber(empleo_prov_aytos[0]?.ayuntamientos_con_datos, 0)} ayuntamientos con datos"
        source="Hacienda (CONPREL, capítulo 1)"
    />
    {/if}
</Grid>

<BarChart
    data={empleo_prov_sectores}
    x=sector
    y=efectivos
    series=administracion
    swapXY=true
    sort=false
    yFmt=num0
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b']}
    title="Empleados públicos en la provincia por sector y administración"
/>

<p class="text-xs text-gray-500">El Registro Central de Personal no publica el personal de cada ayuntamiento, solo el total de los ayuntamientos y de la diputación (o cabildo, consejo insular) de cada provincia. El gasto de personal de cada ayuntamiento está en su ficha de <a href="/territorios/municipios">municipios</a>. Más en <a href="/cuentas-publicas/empleo-publico">Empleo público</a>.</p>

{/if}

---

## Fuentes oficiales

- **[INE – Cifras oficiales de población de los municipios (Padrón)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**
- **[Ministerio de Hacienda – Deuda viva de las entidades locales](https://www.hacienda.gob.es/es-ES/CDI/Paginas/SistemasFinanciacionDeuda/InformacionEELLs/DeudaViva.aspx)**: deuda a 31 de diciembre de cada entidad, conciliada con el total del Banco de España.
- **[Banco de España – Boletín Estadístico, capítulo 14](https://www.bde.es/webbe/es/estadisticas/temas/administraciones-publicas.html)**: deuda de los ayuntamientos de más de 300.000 habitantes.
- **[Instituto Geográfico Nacional (vía es-atlas)](https://github.com/martgnz/es-atlas)**: límites municipales (CC BY 4.0).

<LastRefreshed prefix="Datos actualizados" />
