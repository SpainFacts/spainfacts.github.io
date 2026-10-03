---
description: "Fitxa de la província: població, municipis, comptes dels ajuntaments, deute, seguretat i vehicles, amb dades oficials."
i18n_origen: ddca92253749
breadcrumb: "SELECT nombre AS breadcrumb FROM mother.territorios WHERE nivel = 'provincia' AND slug = '${params.provincia}'"
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../../src/lib/utils.js';
</script>

```sql terr
SELECT p.*, c.nombre AS ccaa_nombre, '/ca' || c.ruta AS ccaa_ruta, c.poblacion_ultima AS ccaa_poblacion
FROM mother.territorios p
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = p.cod_ccaa
WHERE p.nivel = 'provincia' AND p.slug = '${params.provincia}' AND c.slug = '${params.ccaa}'
```

```sql base
-- Año de los euros constantes (último año completo de IPC)
SELECT max(anio_base) AS anio_base FROM mother.deflactor
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
    '/ca/territorios/municipios?m=' || a.cod_mun AS enlace
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

```sql mayor_serie
WITH ult AS (SELECT max(anio) AS anio FROM mother.poblacion_municipios),
mayor AS (
    SELECT arg_max(cod_mun, poblacion) AS cod_mun
    FROM mother.poblacion_municipios
    WHERE cod_prov = '${terr[0]?.cod}' AND anio = (SELECT anio FROM ult)
)
SELECT
    m.anio,
    100.0 * sum(m.poblacion) FILTER (WHERE m.cod_mun = (SELECT cod_mun FROM mayor)) / sum(m.poblacion) AS valor
FROM mother.poblacion_municipios m
WHERE m.cod_prov = '${terr[0]?.cod}'
GROUP BY m.anio
ORDER BY m.anio
```

# {terr[0]?.nombre}

<p class="text-sm text-gray-500"><a href="/ca/territorios">Territoris</a> › <a href={terr[0]?.ccaa_ruta}>{terr[0]?.ccaa_nombre}</a> › {terr[0]?.nombre}</p>

<Grid cols=3>
    <KpiCard
        title="Població"
        value={terr[0]?.poblacion_ultima}
        formattedValue={formatNumber(terr[0]?.poblacion_ultima, 0)}
        unit="hab."
        period="1 de gener de {terr[0]?.anio_poblacion}"
        source="INE – Padró"
        sparklineData={serie_poblacion}
    />
    <KpiCard
        title="Municipis"
        value={resumen_municipios[0]?.n}
        formattedValue={formatNumber(resumen_municipios[0]?.n, 0)}
        period="{formatNumber(resumen_municipios[0]?.menos_1000, 0)} amb menys de 1.000 hab. · {formatNumber(resumen_municipios[0]?.pierden, 0)} perden població en 10 anys"
    />
    <KpiCard
        title="Municipi més gran"
        value={resumen_municipios[0]?.peso_mayor}
        formattedValue={formatNumber(resumen_municipios[0]?.peso_mayor, 1)}
        unit="%"
        period="de la població viu a {resumen_municipios[0]?.mayor}"
        sparklineData={mayor_serie}
    />
</Grid>

## Població

<LineChart
    data={serie_poblacion}
    x=fecha
    y=valor
    yFmt=num0
    title="Població a 1 de gener (Padró)"
    lineColor="#1d4ed8"
/>

```sql demo_anual
SELECT CAST(anio AS INTEGER) AS anio, nacimientos, defunciones, tasa_natalidad, tasa_mortalidad,
    vegetativo_1000, fecundidad, edad_maternidad, pct_madre_extranjera, crecimiento_1000, resto_1000
FROM mother.demografia_anual
WHERE nivel = 'provincia' AND cod = '${terr[0]?.cod}' AND tasa_natalidad IS NOT NULL
ORDER BY anio
```

```sql demo_edades
SELECT CAST(anio AS INTEGER) AS anio, pct_65, pct_80, dependencia, edad_media, pct_nacidos_extranjero
FROM mother.demografia_envejecimiento
WHERE nivel = 'provincia' AND cod = '${terr[0]?.cod}'
ORDER BY anio
```

```sql demo_espana
SELECT a.tasa_natalidad, a.fecundidad, e.pct_65, e.edad_media
FROM mother.demografia_anual a
JOIN mother.demografia_envejecimiento e ON e.nivel = 'pais' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
WHERE a.nivel = 'pais' AND a.anio = (SELECT max(anio) FROM mother.demografia_anual WHERE tasa_natalidad IS NOT NULL)
```

```sql demo_piramide
SELECT grupo, edad_desde, sexo, CASE WHEN sexo = 'Hombres' THEN -pct ELSE pct END AS pct
FROM mother.demografia_piramide
WHERE nivel = 'provincia' AND cod = '${terr[0]?.cod}'
  AND anio = (SELECT max(anio) FROM mother.demografia_piramide)
ORDER BY edad_desde, sexo
```

```sql demo_tasas
SELECT anio, 'Nacimientos' AS fenomeno, tasa_natalidad AS por_1000 FROM ${demo_anual}
UNION ALL
SELECT anio, 'Defunciones', tasa_mortalidad FROM ${demo_anual}
ORDER BY anio
```

## Natalitat i envelliment

<Grid cols=4>
    <KpiCard
        title="Natalitat"
        value={demo_anual.slice(-1)[0]?.tasa_natalidad}
        formattedValue="{formatNumber(demo_anual.slice(-1)[0]?.tasa_natalidad, 1)} per 1.000 hab."
        period="{formatNumber(demo_anual.slice(-1)[0]?.nacimientos, 0)} naixements el {demo_anual.slice(-1)[0]?.anio} · Espanya: {formatNumber(demo_espana[0]?.tasa_natalidad, 1)}"
        source="INE"
        href="/ca/demografia/natalidad"
        sparklineData={demo_anual.map(d => ({anio: d.anio, valor: d.tasa_natalidad}))}
    />
    <KpiCard
        title="Fills per dona"
        value={demo_anual.slice(-1)[0]?.fecundidad}
        formattedValue={formatNumber(demo_anual.slice(-1)[0]?.fecundidad, 2)}
        period="{demo_anual.slice(-1)[0]?.anio} · Espanya: {formatNumber(demo_espana[0]?.fecundidad, 2)}"
        source="INE"
        href="/ca/demografia/natalidad"
        sparklineData={demo_anual.map(d => ({anio: d.anio, valor: d.fecundidad}))}
    />
    <KpiCard
        title="Més grans de 65 anys"
        value={demo_edades.slice(-1)[0]?.pct_65}
        formattedValue="{formatNumber(demo_edades.slice(-1)[0]?.pct_65, 1)} %"
        period="de la població el {demo_edades.slice(-1)[0]?.anio} · Espanya: {formatNumber(demo_espana[0]?.pct_65, 1)} %"
        source="INE"
        href="/ca/demografia/estructura-edades"
        sparklineData={demo_edades.map(d => ({anio: d.anio, valor: d.pct_65}))}
    />
    <KpiCard
        title="Edat mitjana"
        value={demo_edades.slice(-1)[0]?.edad_media}
        formattedValue="{formatNumber(demo_edades.slice(-1)[0]?.edad_media, 1)} anys"
        period="{demo_edades.slice(-1)[0]?.anio} · Espanya: {formatNumber(demo_espana[0]?.edad_media, 1)} anys"
        source="INE"
        href="/ca/demografia/estructura-edades"
        sparklineData={demo_edades.map(d => ({anio: d.anio, valor: d.edad_media}))}
    />
</Grid>

<Grid cols=2>
    <BarChart
        data={demo_piramide}
        x=grupo
        y=pct
        series=sexo
        swapXY=true
        type=stacked
        sort=false
        yFmt='0.0"%";0.0"%"'
        colorPalette={['#0f766e', '#7c3aed']}
        title="Piràmide de població, {demo_edades.slice(-1)[0]?.anio} (% del total)"
    />
    <LineChart
        data={demo_tasas}
        x=anio
        y=por_1000
        series=fenomeno
        yFmt=num1
        xFmt="####"
        colorPalette={['#db2777', '#475569']}
        yAxisTitle="per 1.000 habitants"
        title="Naixements i defuncions per 1.000 habitants"
    />
</Grid>

<p class="text-xs text-gray-500">El {demo_anual.slice(-1)[0]?.anio} la població de {terr[0]?.nombre} va canviar {formatNumber(demo_anual.slice(-1)[0]?.crecimiento_1000, 1)} per 1.000 habitants: {formatNumber(demo_anual.slice(-1)[0]?.vegetativo_1000, 1)} per naixements menys defuncions i {formatNumber(demo_anual.slice(-1)[0]?.resto_1000, 1)} per migració (amb l'estranger i amb altres províncies) i ajustos. El {formatNumber(demo_edades.slice(-1)[0]?.pct_nacidos_extranjero, 1)} % dels seus habitants va néixer a l'estranger. Font: INE (Moviment Natural de la Població, Indicadors Demogràfics Bàsics i Estadística Contínua de Població).</p>

## Municipis

<MapaEspana
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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Límits © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'municipio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'poblacion', title: 'Població', fmt: 'num0'},
        {id: 'crecimiento', title: 'Creixement 10 anys (%)', fmt: 'num1'}
    ]}
/>

<DataTable data={municipios} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Municipi" />
    <Column id=poblacion title="Població" fmt=num0 />
    <Column id=crecimiento title="Creixement 10 anys (%)" fmt=num1 contentType=delta />
</DataTable>

```sql deuda_local
-- Deuda a 31 de diciembre; por habitante (Padrón de cada año, el último para
-- los años sin Padrón) y en euros constantes del último año completo
SELECT
    make_date(CAST(d.anio AS INTEGER), 12, 31) AS fecha,
    d.anio,
    d.deuda_eur,
    d.deuda_ayuntamientos_eur,
    d.deuda_diputaciones_eur,
    d.deuda_resto_eell_eur,
    100.0 * d.deuda_ayuntamientos_eur / nullif(d.deuda_eur, 0) AS pct_ayuntamientos,
    d.deuda_eur / p.poblacion * coalesce(f.factor, 1) AS deuda_hab_real,
    d.deuda_ayuntamientos_eur / p.poblacion * coalesce(f.factor, 1) AS aytos_hab_real,
    d.deuda_diputaciones_eur / p.poblacion * coalesce(f.factor, 1) AS dip_hab_real,
    d.deuda_resto_eell_eur / p.poblacion * coalesce(f.factor, 1) AS resto_hab_real
FROM mother.local_deuda_provincia d
JOIN mother.poblacion_territorios p
  ON p.nivel = 'provincia' AND p.cod = d.cod_prov AND p.sexo = 'Total'
 AND p.anio = least(d.anio, (SELECT max(anio) FROM mother.poblacion_territorios))
LEFT JOIN mother.deflactor f ON f.anio = CAST(d.anio AS INTEGER)
WHERE d.cod_prov = '${terr[0]?.cod}'
ORDER BY d.anio
```

```sql deuda_local_ultima
SELECT * FROM ${deuda_local}
ORDER BY anio DESC
LIMIT 1
```

```sql deuda_local_hab
SELECT anio, deuda_hab_real AS valor FROM ${deuda_local} ORDER BY anio
```

```sql deuda_local_tipo
SELECT fecha, 'Ayuntamientos' AS tipo, aytos_hab_real AS deuda FROM ${deuda_local}
UNION ALL SELECT fecha, 'Diputación / cabildo / consell', dip_hab_real FROM ${deuda_local}
UNION ALL SELECT fecha, 'Otras entidades locales', resto_hab_real FROM ${deuda_local}
ORDER BY fecha
```

```sql deuda_ciudades
-- Deuda de los grandes ayuntamientos por habitante y en euros constantes.
-- La fuente de población municipal solo trae los últimos 10 años: fuera de ese
-- rango se usa el año más cercano disponible.
WITH pob AS (
    SELECT cod_mun, anio, poblacion FROM mother.poblacion_municipios
    WHERE cod_prov = '${terr[0]?.cod}'
),
rango AS (SELECT min(anio) AS ini, max(anio) AS fin FROM pob)
SELECT
    d.municipio,
    d.fecha,
    d.deuda_eur,
    d.deuda_eur / p.poblacion * coalesce(f.factor, 1) AS deuda_hab_real
FROM mother.local_deuda_municipio d
CROSS JOIN rango r
JOIN pob p
  ON p.cod_mun = d.cod_mun
 AND p.anio = greatest(least(CAST(year(d.fecha) AS INTEGER), r.fin), r.ini)
-- Sin IPC anual antes de 2002: la serie real empieza ese año
JOIN mother.deflactor f ON f.anio = CAST(year(d.fecha) AS INTEGER)
WHERE substr(d.cod_mun, 1, 2) = '${terr[0]?.cod}'
ORDER BY d.fecha
```

{#if deuda_local.length > 0}

## Deute de les administracions locals

<Grid cols=2>
    <KpiCard
        title="Deute viu local per habitant"
        value={deuda_local_ultima[0]?.deuda_hab_real}
        formattedValue={formatNumber(deuda_local_ultima[0]?.deuda_hab_real, 0)}
        unit="€"
        period="31 de desembre de {deuda_local_ultima[0]?.anio}, en euros de {base[0]?.anio_base} · total: {formatCompact(deuda_local_ultima[0]?.deuda_eur, 0)} € corrents"
        source="Ministeri d'Hisenda"
        sparklineData={deuda_local_hab}
    />
    <KpiCard
        title="Deute dels ajuntaments"
        value={deuda_local_ultima[0]?.pct_ayuntamientos}
        formattedValue={formatNumber(deuda_local_ultima[0]?.pct_ayuntamientos, 0)}
        unit="%"
        period="del deute local; la resta és de la diputació (cabildo, consell) i altres entitats"
        sparklineData={deuda_local.filter(d => d.pct_ayuntamientos != null).map(d => ({anio: d.anio, valor: d.pct_ayuntamientos}))}
    />
</Grid>

<AreaChart
    data={deuda_local_tipo}
    x=fecha
    y=deuda
    series=tipo
    yFmt=num0
    yAxisTitle="€ per habitant"
    title="Deute viu de les entitats locals per habitant (euros de {base[0]?.anio_base}, descomptada la inflació)"
    colorPalette={['#1d4ed8', '#60a5fa', '#cbd5e1']}
/>

{#if deuda_ciudades.length > 0}

<LineChart
    data={deuda_ciudades}
    x=fecha
    y=deuda_hab_real
    series=municipio
    yFmt=num0
    yAxisTitle="€ per habitant"
    title="Deute dels grans ajuntaments per habitant (euros de {base[0]?.anio_base}, Banc d'Espanya)"
/>

{/if}

<p class="text-xs text-gray-500">Imports per habitant (Padró de cada any) i descomptada la inflació amb l'IPC mitjà anual, en euros de {base[0]?.anio_base}: així la sèrie no creix només perquè hi hagi més veïns o pugin els preus. El deute dels grans ajuntaments comença el 2002, primer any amb IPC anual a la base.</p>

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
-- Por 1.000 habitantes, con la última población del Padrón
SELECT
    sector, administracion,
    1000.0 * sum(efectivos) / (SELECT poblacion_ultima FROM mother.territorios WHERE nivel = 'provincia' AND cod = '${terr[0]?.cod}') AS por_1000,
    sum(efectivos) AS efectivos
FROM mother.empleo_efectivos
WHERE cod_prov = '${terr[0]?.cod}' AND fecha = (SELECT max(fecha) FROM mother.empleo_efectivos)
GROUP BY ALL
ORDER BY efectivos DESC
```

```sql empleo_prov_serie
SELECT fecha, efectivos, por_1000_hab
FROM mother.empleo_territorio
WHERE nivel = 'provincia' AND cod = '${terr[0]?.cod}' AND administracion = 'Total'
ORDER BY fecha
```

```sql empleo_prov_aytos_serie
-- Gasto de personal de los ayuntamientos por habitante, en euros constantes
SELECT g.anio, g.gasto_personal_ayuntamientos_hab * coalesce(f.factor, 1) AS valor
FROM mother.empleo_gasto_personal_territorio g
LEFT JOIN mother.deflactor f ON f.anio = CAST(g.anio AS INTEGER)
WHERE g.nivel = 'provincia' AND g.cod = '${terr[0]?.cod}' AND g.gasto_personal_ayuntamientos_hab IS NOT NULL
ORDER BY g.anio
```

```sql empleo_prov_aytos
-- Importes por habitante en euros constantes del último año completo
SELECT
    g.anio,
    g.gasto_personal_ayuntamientos,
    g.gasto_personal_ayuntamientos_hab * coalesce(f.factor, 1) AS gasto_personal_ayuntamientos_hab,
    g.ayuntamientos_con_datos,
    coalesce(f.factor, 1) * (SELECT gasto_personal_ayuntamientos_hab FROM mother.empleo_gasto_personal_territorio x WHERE x.nivel = 'pais' AND x.anio = g.anio) AS espana_hab
FROM mother.empleo_gasto_personal_territorio g
LEFT JOIN mother.deflactor f ON f.anio = CAST(g.anio AS INTEGER)
WHERE g.nivel = 'provincia' AND g.cod = '${terr[0]?.cod}'
ORDER BY g.anio DESC
LIMIT 1
```

{#if empleo_prov.length > 0}

## Ocupació pública

<Grid cols=2>
    <KpiCard
        title="Empleats públics per 1.000 habitants"
        value={empleo_prov[0]?.por_1000}
        formattedValue={formatNumber(empleo_prov[0]?.por_1000, 1)}
        period="Espanya: {formatNumber(empleo_prov[0]?.por_1000_espana, 1)} · {formatNumber(empleo_prov[0]?.efectivos, 0)} empleats amb lloc de treball a la província a {empleo_prov[0]?.fecha_texto}"
        source="Registre Central de Personal"
        sparklineData={empleo_prov_serie.filter(d => d.por_1000_hab != null).map(d => ({fecha: d.fecha, valor: d.por_1000_hab}))}
    />
    {#if empleo_prov_aytos.length > 0}
    <KpiCard
        title="Despesa de personal dels ajuntaments"
        value={empleo_prov_aytos[0]?.gasto_personal_ayuntamientos_hab}
        formattedValue="{formatNumber(empleo_prov_aytos[0]?.gasto_personal_ayuntamientos_hab, 0)} €/hab."
        period="{empleo_prov_aytos[0]?.anio}, en euros de {base[0]?.anio_base} · Espanya: {formatNumber(empleo_prov_aytos[0]?.espana_hab, 0)} € · {formatNumber(empleo_prov_aytos[0]?.ayuntamientos_con_datos, 0)} ajuntaments amb dades"
        source="Hisenda (CONPREL, capítol 1)"
        sparklineData={empleo_prov_aytos_serie}
    />
    {/if}
</Grid>

<BarChart
    data={empleo_prov_sectores}
    x=sector
    y=por_1000
    series=administracion
    swapXY=true
    sort=false
    yFmt=num1
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b']}
    title="Empleats públics a la província per 1.000 habitants, per sector i administració"
/>

<p class="text-xs text-gray-500">El Registre Central de Personal no publica el personal de cada ajuntament, només el total dels ajuntaments i de la diputació (o cabildo, consell insular) de cada província. La despesa de personal de cada ajuntament és a la seva fitxa de <a href="/ca/territorios/municipios">municipis</a>. Més a <a href="/ca/cuentas-publicas/empleo-publico">Ocupació pública</a>.</p>

{/if}

---

```sql paro_terr
SELECT
    CAST(year(t.trimestre) AS INTEGER) || '-T' || CAST(quarter(t.trimestre) AS INTEGER) AS periodo,
    t.trimestre, t.tasa_paro, t.media_4t_tasa_paro, t.tasa_paro_menor25, t.media_4t_tasa_paro_menor25,
    t.pct_hogares_todos_parados, t.tasa_paro_dif_anual,
    e.tasa_paro AS tasa_paro_espana, e.tasa_paro_menor25 AS tasa_paro_menor25_espana
FROM mother.mercado_paro_territorios t
LEFT JOIN mother.mercado_paro_territorios e ON e.nivel = 'pais' AND e.trimestre = t.trimestre
WHERE t.nivel = 'provincia' AND t.cod = '${terr[0]?.cod}'
ORDER BY t.trimestre
```

```sql paro_reg_terr
SELECT mes, strftime(mes, '%m/%Y') AS mes_txt, paro_registrado, por_100_16_64, variacion_anual_pct
FROM mother.mercado_paro_registrado
WHERE nivel = 'provincia' AND cod = '${terr[0]?.cod}'
ORDER BY mes
```

{#if paro_terr.length > 0}

## Atur

<Grid cols=3>
    <KpiCard
        title="Taxa d'atur"
        value={paro_terr.slice(-1)[0]?.tasa_paro}
        formattedValue="{formatNumber(paro_terr.slice(-1)[0]?.tasa_paro, 1)} %"
        period="EPA {paro_terr.slice(-1)[0]?.periodo} (mostra petita: millor la mitjana) · mitjana de l'últim any {formatNumber(paro_terr.slice(-1)[0]?.media_4t_tasa_paro, 1)} % · Espanya {formatNumber(paro_terr.slice(-1)[0]?.tasa_paro_espana, 1)} %"
        direction="positive-down"
        source="INE / EPA"
        href="/ca/economia/paro"
        sparklineData={paro_terr.slice(-40).map(d => d.tasa_paro)}
    />
    <KpiCard
        title="Atur dels menors de 25 anys"
        value={paro_terr.slice(-1)[0]?.tasa_paro_menor25}
        formattedValue="{formatNumber(paro_terr.slice(-1)[0]?.tasa_paro_menor25, 1)} %"
        period="{paro_terr.slice(-1)[0]?.periodo} · Espanya {formatNumber(paro_terr.slice(-1)[0]?.tasa_paro_menor25_espana, 1)} %"
        direction="positive-down"
        source="INE / EPA"
        href="/ca/economia/paro"
        sparklineData={paro_terr.slice(-40).map(d => d.tasa_paro_menor25)}
    />
    <KpiCard
        title="Atur registrat"
        value={paro_reg_terr.slice(-1)[0]?.por_100_16_64}
        formattedValue="{formatNumber(paro_reg_terr.slice(-1)[0]?.por_100_16_64, 1)} per 100 hab."
        period="de 16 a 64 anys, {paro_reg_terr.slice(-1)[0]?.mes_txt} · {formatNumber(paro_reg_terr.slice(-1)[0]?.paro_registrado, 0)} persones ({formatNumber(paro_reg_terr.slice(-1)[0]?.variacion_anual_pct, 1)} % en un any)"
        direction="positive-down"
        source="SEPE"
        href="/ca/economia/paro"
        sparklineData={paro_reg_terr.slice(-36).map(d => d.por_100_16_64)}
    />
</Grid>

<LineChart
    data={paro_terr}
    x=trimestre
    y={['media_4t_tasa_paro', 'tasa_paro_espana']}
    seriesLabels={{media_4t_tasa_paro: terr[0]?.nombre + ' (mitjana de 4 trimestres)', tasa_paro_espana: 'Espanya'}}
    colorPalette={['#2563eb', '#94a3b8']}
    yFmt='0.0"%"'
    yAxisTitle="% de la població activa"
    title="Taxa d'atur (EPA; la provincial és la mitjana dels últims 4 trimestres)"
/>

{/if}

```sql renta_prov
SELECT
    CAST(p.anio AS INTEGER) AS anio,
    p.renta_persona_real, p.renta_hogar_real, p.renta_uc_mediana_real,
    c.renta_persona_real AS renta_persona_ccaa,
    e.renta_persona_real AS renta_persona_espana
FROM mother.renta_territorios p
LEFT JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = p.cod
LEFT JOIN mother.renta_territorios c ON c.nivel = 'ccaa' AND c.cod = t.cod_ccaa AND c.anio = p.anio
LEFT JOIN mother.renta_territorios e ON e.nivel = 'pais' AND e.anio = p.anio
WHERE p.nivel = 'provincia' AND p.cod = '${terr[0]?.cod}'
ORDER BY p.anio
```

```sql renta_prov_puesto
SELECT puesto FROM (
    SELECT cod, rank() OVER (ORDER BY renta_persona_real DESC) AS puesto
    FROM mother.renta_territorios
    WHERE nivel = 'provincia' AND anio = (SELECT max(anio) FROM mother.renta_territorios)
) WHERE cod = '${terr[0]?.cod}'
```

```sql renta_prov_municipios
SELECT m.municipio, m.poblacion, m.renta_persona_real, m.renta_hogar_real, CAST(m.anio AS INTEGER) AS anio,
    '/ca/territorios/municipios?m=' || m.cod_mun AS enlace
FROM mother.renta_municipios m
WHERE m.cod_prov = '${terr[0]?.cod}' AND m.anio = (SELECT max(anio) FROM mother.renta_municipios)
  AND m.renta_persona_real IS NOT NULL
ORDER BY m.renta_persona_real DESC
```

{#if renta_prov.length > 0}

## Renda de les llars

<Grid cols=2>
    <KpiCard
        title="Renda neta mitjana per persona"
        value={renta_prov.slice(-1)[0]?.renta_persona_real}
        formattedValue="{formatNumber(renta_prov.slice(-1)[0]?.renta_persona_real, 0)} €"
        period="l'any {renta_prov.slice(-1)[0]?.anio}, euros de 2025 · posició {renta_prov_puesto[0]?.puesto} de 52{renta_prov.slice(-1)[0]?.renta_persona_espana != null ? ` · Espanya ${formatNumber(renta_prov.slice(-1)[0]?.renta_persona_espana, 0)} €` : ''}"
        direction="positive-up"
        source="INE / Atles de Renda"
        href="/ca/sociedad/desigualdad"
        sparklineData={renta_prov.map(d => d.renta_persona_real)}
    />
    <KpiCard
        title="Renda neta mitjana per llar"
        value={renta_prov.slice(-1)[0]?.renta_hogar_real}
        formattedValue="{formatNumber(renta_prov.slice(-1)[0]?.renta_hogar_real, 0)} €"
        period="l'any {renta_prov.slice(-1)[0]?.anio}, euros de 2025"
        direction="positive-up"
        source="INE / Atles de Renda"
        href="/ca/sociedad/desigualdad"
        sparklineData={renta_prov.map(d => d.renta_hogar_real)}
    />
</Grid>

<DataTable data={renta_prov_municipios} link=enlace rows=10 search=true>
    <Column id=municipio title="Municipi"/>
    <Column id=renta_persona_real title="Renda per persona (€)" fmt='#,##0'/>
    <Column id=renta_hogar_real title="Renda per llar (€)" fmt='#,##0'/>
    <Column id=poblacion title="Habitants" fmt='#,##0'/>
</DataTable>

<p class="text-xs text-gray-500">Atles de Distribució de Renda de les Llars de l'INE (dades tributàries), descomptada la inflació. Més a <a href="/ca/sociedad/desigualdad">Renda, pobresa i desigualtat</a>.</p>

{/if}

```sql viv
SELECT r.*, e.euros_m2_real AS euros_m2_real_espana, e.alquiler_mes_mediana_real AS alquiler_espana,
       e.compraventas_12m_1000 AS compraventas_espana, e.terminadas_1000 AS terminadas_espana,
       strftime(r.mercado_fecha, '%m/%Y') AS mercado_mes
FROM mother.vivienda_resumen_territorios r
JOIN mother.vivienda_resumen_territorios e ON e.nivel = 'pais'
WHERE r.nivel = 'provincia' AND r.cod = '${terr[0]?.cod}'
```

```sql viv_precio
SELECT fecha, nombre, euros_m2_real
FROM mother.vivienda_precio_tasado
WHERE euros_m2_real IS NOT NULL
  AND ((nivel = 'provincia' AND cod = '${terr[0]?.cod}') OR nivel = 'pais')
ORDER BY fecha, nombre
```

```sql viv_serie
-- Series para las sparklines, en formato largo (Evidence no admite listas de DuckDB)
SELECT 'precio' AS serie, CAST(fecha AS DATE) AS orden, euros_m2_real AS valor FROM mother.vivienda_precio_tasado WHERE nivel = 'provincia' AND cod = '${terr[0]?.cod}' AND euros_m2_real IS NOT NULL
UNION ALL
SELECT 'alquiler', make_date(CAST(anio AS INTEGER), 1, 1), alquiler_mes_mediana_real FROM mother.vivienda_alquiler WHERE nivel = 'provincia' AND cod = '${terr[0]?.cod}' AND tipologia = 'Colectiva' AND alquiler_mes_mediana_real IS NOT NULL
UNION ALL
SELECT 'compraventas', CAST(fecha AS DATE), compraventas_12m_1000 FROM mother.vivienda_mercado_mensual WHERE nivel = 'provincia' AND cod = '${terr[0]?.cod}' AND compraventas_12m_1000 IS NOT NULL
UNION ALL
SELECT 'terminadas', make_date(CAST(anio AS INTEGER), 1, 1), terminadas_1000 FROM mother.vivienda_obra_nueva WHERE nivel = 'provincia' AND cod = '${terr[0]?.cod}' AND terminadas_1000 IS NOT NULL
ORDER BY serie, orden
```

```sql viv_municipios
SELECT coalesce(p.municipio, a.municipio) AS municipio,
       coalesce(p.poblacion, a.poblacion) AS poblacion,
       p.euros_m2_real, p.variacion_real AS precio_var_real,
       a.alquiler_mes_mediana_real, a.variacion_real_5a AS alquiler_var_5a
FROM (SELECT * FROM mother.vivienda_precio_municipios WHERE cod_prov = '${terr[0]?.cod}'
        AND anio = (SELECT max(anio) FROM mother.vivienda_precio_municipios WHERE trimestres = 4)) p
FULL OUTER JOIN (SELECT * FROM mother.vivienda_alquiler_municipios WHERE cod_prov = '${terr[0]?.cod}'
        AND anio = (SELECT max(anio) FROM mother.vivienda_alquiler_municipios)) a
  ON a.cod_mun = p.cod_mun
ORDER BY poblacion DESC
```

{#if viv.length > 0 && viv[0]?.euros_m2_real != null}

## Habitatge

<Grid cols=4>
    <KpiCard
        title="Preu de l'habitatge"
        value={viv[0]?.euros_m2_real}
        formattedValue="{formatNumber(viv[0]?.euros_m2_real, 0)} €/m²"
        period="valor taxat, {viv[0]?.precio_periodo} · Espanya: {formatNumber(viv[0]?.euros_m2_real_espana, 0)} €/m²"
        change={viv[0]?.precio_interanual_real?.toFixed(1)}
        changePeriod="real vs. un any abans"
        source="Ministeri d'Habitatge"
        href="/ca/vivienda/precios"
        sparklineData={viv_serie.filter(d => d.serie === 'precio').map(d => d.valor)}
    />
    <KpiCard
        title="Lloguer medià d'un pis"
        value={viv[0]?.alquiler_mes_mediana_real}
        formattedValue="{formatNumber(viv[0]?.alquiler_mes_mediana_real, 0)} €/mes"
        period="{viv[0]?.alquiler_anio} · Espanya: {formatNumber(viv[0]?.alquiler_espana, 0)} €/mes"
        source="Ministeri d'Habitatge (SERPAVI)"
        href="/ca/vivienda/alquiler"
        sparklineData={viv_serie.filter(d => d.serie === 'alquiler').map(d => d.valor)}
    />
    <KpiCard
        title="Compravendes per 1.000 hab."
        value={viv[0]?.compraventas_12m_1000}
        formattedValue={formatNumber(viv[0]?.compraventas_12m_1000, 1)}
        period="12 mesos fins a {viv[0]?.mercado_mes} · Espanya: {formatNumber(viv[0]?.compraventas_espana, 1)}"
        source="INE / ETDP"
        href="/ca/vivienda/compraventas"
        sparklineData={viv_serie.filter(d => d.serie === 'compraventas').map(d => d.valor)}
    />
    <KpiCard
        title="Habitatges acabats per 1.000 hab."
        value={viv[0]?.terminadas_1000}
        formattedValue={formatNumber(viv[0]?.terminadas_1000, 2)}
        period="habitatge lliure, {viv[0]?.obra_anio} · Espanya: {formatNumber(viv[0]?.terminadas_espana, 2)}"
        source="Ministeri d'Habitatge"
        href="/ca/vivienda/construccion"
        sparklineData={viv_serie.filter(d => d.serie === 'terminadas').map(d => d.valor)}
    />
</Grid>

<LineChart
    data={viv_precio}
    x=fecha
    y=euros_m2_real
    series=nombre
    yFmt='#,##0" €"'
    yAxisTitle="€/m² (euros de {viv[0]?.anio_base})"
    startingAtZero={false}
    title="Valor taxat de l'habitatge descomptada la inflació"
/>

{#if viv_municipios.length > 0}
<DataTable data={viv_municipios}>
    <Column id=municipio title="Municipi" />
    <Column id=euros_m2_real title="Valor taxat €/m² (real)" fmt='#,##0' />
    <Column id=precio_var_real title="Var. real anual %" fmt='0.0' contentType=delta />
    <Column id=alquiler_mes_mediana_real title="Lloguer pis €/mes" fmt='#,##0' />
    <Column id=alquiler_var_5a title="Lloguer: var. real 5 anys %" fmt='0.0' contentType=delta />
</DataTable>
<p class="text-xs text-gray-500">Valor taxat: municipis de més de 25.000 habitants. Lloguer (dades de l'IRPF): municipis de 20.000 o més.</p>
{/if}

<p class="text-xs text-gray-500">Preus i lloguers en euros de {viv[0]?.anio_base}. Més detall a <a href="/ca/vivienda">Habitatge</a>.</p>

{/if}

```sql pensiones_terr
SELECT
    CAST(p.anio AS INTEGER) AS anio, p.meses, p.pensiones,
    p.pension_media_jubilacion_real, p.pension_media_real,
    p.pensiones_por_1000_hab, p.pensiones_por_100_mayores, p.afiliados_por_pension,
    e.pension_media_jubilacion_real AS jub_espana, e.pensiones_por_1000_hab AS por_1000_espana,
    e.afiliados_por_pension AS ratio_espana, CAST(p.anio_euros AS INTEGER) AS anio_euros,
    (SELECT count(*) + 1 FROM mother.pensiones_territorio x
        WHERE x.nivel = p.nivel AND x.anio = p.anio AND x.pension_media_jubilacion_real > p.pension_media_jubilacion_real) AS puesto_pension,
    (SELECT count(*) FROM mother.pensiones_territorio x WHERE x.nivel = p.nivel AND x.anio = p.anio) AS n_territorios
FROM mother.pensiones_territorio p
JOIN mother.pensiones_territorio e ON e.nivel = 'pais' AND e.anio = p.anio
WHERE p.nivel = 'provincia' AND p.cod = '${terr[0]?.cod}'
  AND p.anio = (SELECT max(anio) FROM mother.pensiones_territorio)
```

```sql pensiones_terr_serie
SELECT CAST(anio AS INTEGER) AS anio, pension_media_jubilacion_real, pensiones_por_1000_hab, afiliados_por_pension
FROM mother.pensiones_territorio
WHERE nivel = 'provincia' AND cod = '${terr[0]?.cod}' AND meses = 12
ORDER BY anio
```

{#if pensiones_terr.length > 0}

## Pensions

<Grid cols=3>
    <KpiCard
        title="Pensió mitjana de jubilació"
        value={pensiones_terr[0]?.pension_media_jubilacion_real}
        formattedValue="{formatNumber(pensiones_terr[0]?.pension_media_jubilacion_real, 0)} €/mes"
        period="{pensiones_terr[0]?.anio} (mitjana de {pensiones_terr[0]?.meses} mesos), euros de {pensiones_terr[0]?.anio_euros} · Espanya: {formatNumber(pensiones_terr[0]?.jub_espana, 0)} € · posició {pensiones_terr[0]?.puesto_pension} de {pensiones_terr[0]?.n_territorios}"
        source="Seguretat Social"
        sparklineData={pensiones_terr_serie.map(d => d.pension_media_jubilacion_real)}
    />
    <KpiCard
        title="Pensions per 1.000 habitants"
        value={pensiones_terr[0]?.pensiones_por_1000_hab}
        formattedValue={formatNumber(pensiones_terr[0]?.pensiones_por_1000_hab, 0)}
        period="Espanya: {formatNumber(pensiones_terr[0]?.por_1000_espana, 0)} · {formatNumber(pensiones_terr[0]?.pensiones_por_100_mayores, 0)} per cada 100 persones de 65+ · {formatNumber(pensiones_terr[0]?.pensiones, 0)} pensions"
        source="Seguretat Social / INE"
        sparklineData={pensiones_terr_serie.map(d => d.pensiones_por_1000_hab)}
    />
    <KpiCard
        title="Afiliats per pensió"
        value={pensiones_terr[0]?.afiliados_por_pension}
        formattedValue={formatNumber(pensiones_terr[0]?.afiliados_por_pension, 2)}
        period="Espanya: {formatNumber(pensiones_terr[0]?.ratio_espana, 2)} (dades per província des del 2021)"
        source="Seguretat Social"
        sparklineData={pensiones_terr_serie.filter(d => d.afiliados_por_pension != null).map(d => d.afiliados_por_pension)}
    />
</Grid>

<p class="text-xs text-gray-500">Pensions contributives de la Seguretat Social. Imports bruts de cadascuna de les 14 pagues, descomptada la inflació. Més a <a href="/ca/cuentas-publicas/pensiones">Pensions</a>.</p>

{/if}

```sql elec
SELECT p.proceso, p.fecha, strftime(p.fecha, '%-d/%-m/%Y') AS fecha_txt,
    p.participacion, p.participacion AS valor, p.ganador_siglas, p.ganador_pct,
    p.segundo_siglas, p.segundo_pct, p.nep_votos, p.escanos, e.participacion AS participacion_espana
FROM mother.elecciones_participacion p
JOIN mother.elecciones_participacion e ON e.proceso = p.proceso AND e.nivel = 'pais'
WHERE p.nivel = 'provincia' AND p.cod = '${terr[0]?.cod}' AND p.tipo = '02'
ORDER BY p.fecha
```

```sql elec_part
SELECT fecha, '${terr[0]?.nombre}' AS ambito, participacion FROM ${elec}
UNION ALL
SELECT fecha, 'España' AS ambito, participacion_espana FROM ${elec}
ORDER BY fecha
```

```sql elec_familias
SELECT p.fecha, f.familia, f.color, f.orden_familia, f.pct, f.escanos
FROM mother.elecciones_familias f
JOIN mother.elecciones_participacion p ON p.proceso = f.proceso AND p.nivel = 'pais'
WHERE f.nivel = 'provincia' AND f.cod = '${terr[0]?.cod}' AND f.tipo = '02'
  AND f.familia IN (SELECT familia FROM mother.elecciones_familias
      WHERE nivel = 'provincia' AND cod = '${terr[0]?.cod}' AND tipo = '02' AND bloque <> 'Otros'
      GROUP BY familia HAVING max(pct) >= 5)
ORDER BY p.fecha, f.orden_familia
```

```sql elec_colores
SELECT DISTINCT familia, color, orden_familia FROM ${elec_familias} ORDER BY orden_familia
```

{#if elec.length > 0}

## Eleccions

<Grid cols=3>
    <KpiCard title="Participació a les generals" value={elec.slice(-1)[0]?.participacion}
        formattedValue="{formatNumber(elec.slice(-1)[0]?.participacion, 1)} %"
        period="{elec.slice(-1)[0]?.fecha_txt} · Espanya: {formatNumber(elec.slice(-1)[0]?.participacion_espana, 1)} %"
        source="Ministeri de l'Interior" href="/ca/sociedad/elecciones" sparklineData={elec} />
    <KpiCard title="Candidatura més votada" value={elec.slice(-1)[0]?.ganador_pct}
        formattedValue="{elec.slice(-1)[0]?.ganador_siglas} · {formatNumber(elec.slice(-1)[0]?.ganador_pct, 1)} %"
        period="segona: {elec.slice(-1)[0]?.segundo_siglas} ({formatNumber(elec.slice(-1)[0]?.segundo_pct, 1)} %) · {formatNumber(elec.slice(-1)[0]?.escanos, 0)} escons a la província"
        source="Ministeri de l'Interior" sparklineData={elec.map(d => ({valor: d.ganador_pct}))} />
    <KpiCard title="Nombre efectiu de partits" value={elec.slice(-1)[0]?.nep_votos}
        formattedValue={formatNumber(elec.slice(-1)[0]?.nep_votos, 1)} period="en vots, últimes generals"
        source="Càlcul propi" sparklineData={elec.map(d => ({valor: d.nep_votos}))} />
</Grid>

<LineChart data={elec_familias} x=fecha y=pct series=familia yFmt='0.0"%"' markers=true
    seriesColors={Object.fromEntries(elec_colores.map(d => [d.familia, d.color]))}
    title="Vot a les generals per família política, % dels vots vàlids" />

<LineChart data={elec_part} x=fecha y=participacion series=ambito yFmt='0.0"%"' markers=true
    seriesColors={{'España': '#94a3b8'}} title="Participació a les generals, %" />

{/if}

## Fonts oficials

- **Noves seccions**: EPA (INE) i atur registrat (SEPE); Atles de Distribució de Renda (INE); valor taxat i SERPAVI (Ministeri d'Habitatge); pensions contributives (Seguretat Social); natalitat i població (INE).

- **[INE – Xifres oficials de població dels municipis (Padró)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**
- **[Ministeri d'Hisenda – Deute viu de les entitats locals](https://www.hacienda.gob.es/es-ES/CDI/Paginas/SistemasFinanciacionDeuda/InformacionEELLs/DeudaViva.aspx)**: deute a 31 de desembre de cada entitat, conciliat amb el total del Banc d'Espanya.
- **[Banc d'Espanya – Butlletí Estadístic, capítol 14](https://www.bde.es/webbe/es/estadisticas/temas/administraciones-publicas.html)**: deute dels ajuntaments de més de 300.000 habitants.
- **[Instituto Geográfico Nacional (via es-atlas)](https://github.com/martgnz/es-atlas)**: límits municipals (CC BY 4.0).

<LastRefreshed prefix="Dades actualitzades" />
