---
description: "Probintziaren fitxa: biztanleria, udalerriak, udalen kontuak, zorra, segurtasuna eta ibilgailuak, datu ofizialekin."
i18n_origen: 48c2df64eecc
breadcrumb: "SELECT nombre AS breadcrumb FROM mother.territorios WHERE nivel = 'provincia' AND slug = '${params.provincia}'"
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../../src/lib/utils.js';
    // Urteei euskal atzizkia eransten die (2021eko, 2023ko, 2025eko...)
    const urte = (n, s) => (n == null || n === '' ? '' : n + ([1, 5, 10, 15].includes(Number(n) % 20) ? 'e' : '') + s);
</script>

```sql terr
SELECT p.*, c.nombre AS ccaa_nombre, '/eu' || c.ruta AS ccaa_ruta, c.poblacion_ultima AS ccaa_poblacion
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
    '/eu/territorios/municipios?m=' || a.cod_mun AS enlace
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

<p class="text-sm text-gray-500"><a href="/eu/territorios">Lurraldeak</a> › <a href={terr[0]?.ccaa_ruta}>{terr[0]?.ccaa_nombre}</a> › {terr[0]?.nombre}</p>

<Grid cols=3>
    <KpiCard
        title="Biztanleria"
        value={terr[0]?.poblacion_ultima}
        formattedValue={formatNumber(terr[0]?.poblacion_ultima, 0)}
        unit="biz."
        period="{urte(terr[0]?.anio_poblacion, 'ko')} urtarrilaren 1a"
        source="INE – Udal Erroldak"
        sparklineData={serie_poblacion}
    />
    <KpiCard
        title="Udalerriak"
        value={resumen_municipios[0]?.n}
        formattedValue={formatNumber(resumen_municipios[0]?.n, 0)}
        period="{formatNumber(resumen_municipios[0]?.menos_1000, 0)} 1.000 biz. baino gutxiagokoak · 10 urtean biztanleria galdu dutenak: {formatNumber(resumen_municipios[0]?.pierden, 0)}"
    />
    <KpiCard
        title="Udalerririk handiena"
        value={resumen_municipios[0]?.peso_mayor}
        formattedValue={formatNumber(resumen_municipios[0]?.peso_mayor, 1)}
        unit="%"
        period="{resumen_municipios[0]?.mayor} udalerrian bizi den biztanleria"
        sparklineData={mayor_serie}
    />
</Grid>

## Biztanleria

<LineChart
    data={serie_poblacion}
    x=fecha
    y=valor
    yFmt=num0
    title="Biztanleria urtarrilaren 1ean (Udal Erroldak)"
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

## Jaiotzak eta zahartzea

<Grid cols=4>
    <KpiCard
        title="Jaiotza-tasa"
        value={demo_anual.slice(-1)[0]?.tasa_natalidad}
        formattedValue="{formatNumber(demo_anual.slice(-1)[0]?.tasa_natalidad, 1)} 1.000 biz. bakoitzeko"
        period="{formatNumber(demo_anual.slice(-1)[0]?.nacimientos, 0)} jaiotza {urte(demo_anual.slice(-1)[0]?.anio, 'an')} · Espainia: {formatNumber(demo_espana[0]?.tasa_natalidad, 1)}"
        source="INE"
        href="/eu/demografia/natalidad"
        sparklineData={demo_anual.map(d => ({anio: d.anio, valor: d.tasa_natalidad}))}
    />
    <KpiCard
        title="Seme-alabak emakumeko"
        value={demo_anual.slice(-1)[0]?.fecundidad}
        formattedValue={formatNumber(demo_anual.slice(-1)[0]?.fecundidad, 2)}
        period="{demo_anual.slice(-1)[0]?.anio} · Espainia: {formatNumber(demo_espana[0]?.fecundidad, 2)}"
        source="INE"
        href="/eu/demografia/natalidad"
        sparklineData={demo_anual.map(d => ({anio: d.anio, valor: d.fecundidad}))}
    />
    <KpiCard
        title="65 urtetik gorakoak"
        value={demo_edades.slice(-1)[0]?.pct_65}
        formattedValue="{formatNumber(demo_edades.slice(-1)[0]?.pct_65, 1)} %"
        period="biztanleriaren gainean, {demo_edades.slice(-1)[0]?.anio} · Espainia: {formatNumber(demo_espana[0]?.pct_65, 1)} %"
        source="INE"
        href="/eu/demografia/estructura-edades"
        sparklineData={demo_edades.map(d => ({anio: d.anio, valor: d.pct_65}))}
    />
    <KpiCard
        title="Batez besteko adina"
        value={demo_edades.slice(-1)[0]?.edad_media}
        formattedValue="{formatNumber(demo_edades.slice(-1)[0]?.edad_media, 1)} urte"
        period="{demo_edades.slice(-1)[0]?.anio} · Espainia: {formatNumber(demo_espana[0]?.edad_media, 1)} urte"
        source="INE"
        href="/eu/demografia/estructura-edades"
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
        title="Biztanleria-piramidea, {demo_edades.slice(-1)[0]?.anio} (guztizkoaren %)"
    />
    <LineChart
        data={demo_tasas}
        x=anio
        y=por_1000
        series=fenomeno
        yFmt=num1
        xFmt="####"
        colorPalette={['#db2777', '#475569']}
        yAxisTitle="1.000 biztanleko"
        title="Jaiotzak eta heriotzak 1.000 biztanleko"
    />
</Grid>

<p class="text-xs text-gray-500">{urte(demo_anual.slice(-1)[0]?.anio, 'an')}, {terr[0]?.nombre} probintziako biztanleria {formatNumber(demo_anual.slice(-1)[0]?.crecimiento_1000, 1)} aldatu zen 1.000 biztanleko: {formatNumber(demo_anual.slice(-1)[0]?.vegetativo_1000, 1)} jaiotzak ken heriotzak direla eta, eta {formatNumber(demo_anual.slice(-1)[0]?.resto_1000, 1)} migrazioa (atzerriarekin eta beste probintzia batzuekin) eta doikuntzak direla eta. Biztanleen {formatNumber(demo_edades.slice(-1)[0]?.pct_nacidos_extranjero, 1)} % atzerrian jaio zen. Iturria: INE (Biztanleriaren Mugimendu Naturala, Oinarrizko Adierazle Demografikoak eta Biztanleriaren Etengabeko Estatistika).</p>

## Udalerriak

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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Mugak © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'municipio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'poblacion', title: 'Biztanleria', fmt: 'num0'},
        {id: 'crecimiento', title: 'Hazkundea 10 urtean (%)', fmt: 'num1'}
    ]}
/>

<DataTable data={municipios} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Udalerria" />
    <Column id=poblacion title="Biztanleria" fmt=num0 />
    <Column id=crecimiento title="Hazkundea 10 urtean (%)" fmt=num1 contentType=delta />
</DataTable>

```sql deuda_local
-- Deuda a 31 de diciembre: total y por habitante en euros constantes (el modelo ya
-- trae el Padrón de cada año, el último para los años sin Padrón, y el deflactor)
SELECT
    fecha,
    anio,
    deuda_eur,
    deuda_ayuntamientos_eur,
    deuda_diputaciones_eur,
    deuda_resto_eell_eur,
    pct_ayuntamientos,
    deuda_eur_hab_real,
    deuda_ayuntamientos_eur_hab_real,
    deuda_diputaciones_eur_hab_real,
    deuda_resto_eell_eur_hab_real
FROM mother.local_deuda_provincia
WHERE cod_prov = '${terr[0]?.cod}'
ORDER BY anio
```

```sql deuda_local_ultima
SELECT * FROM ${deuda_local}
ORDER BY anio DESC
LIMIT 1
```

```sql deuda_local_hab
SELECT anio, deuda_eur_hab_real AS valor FROM ${deuda_local} ORDER BY anio
```

```sql deuda_local_tipo
SELECT fecha, 'Ayuntamientos' AS tipo, deuda_ayuntamientos_eur_hab_real AS deuda FROM ${deuda_local}
UNION ALL SELECT fecha, 'Diputación / cabildo / consell', deuda_diputaciones_eur_hab_real FROM ${deuda_local}
UNION ALL SELECT fecha, 'Otras entidades locales', deuda_resto_eell_eur_hab_real FROM ${deuda_local}
ORDER BY fecha
```

```sql deuda_ciudades
-- Deuda de los grandes ayuntamientos por habitante y en euros constantes
SELECT
    municipio,
    fecha,
    deuda_eur,
    deuda_eur_hab_real
FROM mother.local_deuda_municipio
WHERE cod_prov = '${terr[0]?.cod}' AND deuda_eur_hab_real IS NOT NULL
ORDER BY fecha
```

{#if deuda_local.length > 0}

## Toki-administrazioen zorra

<Grid cols=2>
    <KpiCard
        title="Tokiko zor bizia biztanleko"
        value={deuda_local_ultima[0]?.deuda_eur_hab_real}
        formattedValue={formatNumber(deuda_local_ultima[0]?.deuda_eur_hab_real, 0)}
        unit="€"
        period="{urte(deuda_local_ultima[0]?.anio, 'ko')} abenduaren 31, {urte(base[0]?.anio_base, 'ko')} eurotan · guztira: {formatCompact(deuda_local_ultima[0]?.deuda_eur, 0)} € korronte"
        source="Ogasun Ministerioa"
        sparklineData={deuda_local_hab}
    />
    <KpiCard
        title="Udalen zorra"
        value={deuda_local_ultima[0]?.pct_ayuntamientos}
        formattedValue={formatNumber(deuda_local_ultima[0]?.pct_ayuntamientos, 0)}
        unit="%"
        period="tokiko zorraren gainean; gainerakoa diputazioarena (kabildoa, consell) eta beste erakunde batzuena da"
        sparklineData={deuda_local.filter(d => d.pct_ayuntamientos != null).map(d => ({anio: d.anio, valor: d.pct_ayuntamientos}))}
    />
</Grid>

<AreaChart
    data={deuda_local_tipo}
    x=fecha
    y=deuda
    series=tipo
    yFmt=num0
    yAxisTitle="€ biztanleko"
    title="Toki-erakundeen zor bizia biztanleko ({urte(base[0]?.anio_base, 'ko')} eurotan, inflazioa kenduta)"
    colorPalette={['#1d4ed8', '#60a5fa', '#cbd5e1']}
/>

{#if deuda_ciudades.length > 0}

<LineChart
    data={deuda_ciudades}
    x=fecha
    y=deuda_eur_hab_real
    series=municipio
    yFmt=num0
    yAxisTitle="€ biztanleko"
    title="Udal handien zorra biztanleko ({urte(base[0]?.anio_base, 'ko')} eurotan, Espainiako Bankua)"
/>

{/if}

<p class="text-xs text-gray-500">Zenbatekoak biztanleko (urte bakoitzeko Udal Erroldarekin) eta inflazioa kenduta, urteko batez besteko KPIarekin, {urte(base[0]?.anio_base, 'ko')} eurotan: horrela, seriea ez da hazten auzotar gehiago egoteagatik edo prezioak igotzeagatik soilik.</p>

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
SELECT g.anio, g.gasto_personal_ayuntamientos_eur_hab_real AS valor
FROM mother.empleo_gasto_personal_territorio g
WHERE g.nivel = 'provincia' AND g.cod = '${terr[0]?.cod}' AND g.gasto_personal_ayuntamientos_eur_hab_real IS NOT NULL
ORDER BY g.anio
```

```sql empleo_prov_aytos
-- Importes por habitante en euros constantes del último año completo
SELECT
    g.anio,
    g.gasto_personal_ayuntamientos,
    g.gasto_personal_ayuntamientos_eur_hab_real AS gasto_personal_ayuntamientos_hab,
    g.ayuntamientos_con_datos,
    (SELECT gasto_personal_ayuntamientos_eur_hab_real FROM mother.empleo_gasto_personal_territorio x WHERE x.nivel = 'pais' AND x.anio = g.anio) AS espana_hab
FROM mother.empleo_gasto_personal_territorio g
WHERE g.nivel = 'provincia' AND g.cod = '${terr[0]?.cod}'
ORDER BY g.anio DESC
LIMIT 1
```

{#if empleo_prov.length > 0}

## Enplegu publikoa

<Grid cols=2>
    <KpiCard
        title="Enplegatu publikoak 1.000 biztanleko"
        value={empleo_prov[0]?.por_1000}
        formattedValue={formatNumber(empleo_prov[0]?.por_1000, 1)}
        period="Espainia: {formatNumber(empleo_prov[0]?.por_1000_espana, 1)} · probintzian lanpostua duten {formatNumber(empleo_prov[0]?.efectivos, 0)} enplegatu, {empleo_prov[0]?.fecha_texto} datan"
        source="Langileen Erregistro Zentrala"
        sparklineData={empleo_prov_serie.filter(d => d.por_1000_hab != null).map(d => ({fecha: d.fecha, valor: d.por_1000_hab}))}
    />
    {#if empleo_prov_aytos.length > 0}
    <KpiCard
        title="Udalen langile-gastua"
        value={empleo_prov_aytos[0]?.gasto_personal_ayuntamientos_hab}
        formattedValue="{formatNumber(empleo_prov_aytos[0]?.gasto_personal_ayuntamientos_hab, 0)} €/biz."
        period="{empleo_prov_aytos[0]?.anio}, {urte(base[0]?.anio_base, 'ko')} eurotan · Espainia: {formatNumber(empleo_prov_aytos[0]?.espana_hab, 0)} € · datuak dituzten {formatNumber(empleo_prov_aytos[0]?.ayuntamientos_con_datos, 0)} udal"
        source="Ogasuna (CONPREL, 1. kapitulua)"
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
    title="Enplegatu publikoak probintzian 1.000 biztanleko, sektorearen eta administrazioaren arabera"
/>

<p class="text-xs text-gray-500">Langileen Erregistro Zentralak ez ditu udal bakoitzeko langileak argitaratzen, probintzia bakoitzeko udal guztien eta diputazioaren (edo kabildoaren, uharte-kontseiluaren) guztizkoa baizik. Udal bakoitzaren langile-gastua bere <a href="/eu/territorios/municipios">udalerri</a>-fitxan dago. Gehiago: <a href="/eu/cuentas-publicas/empleo-publico">Enplegu publikoa</a>.</p>

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

## Langabezia

<Grid cols=3>
    <KpiCard
        title="Langabezia-tasa"
        value={paro_terr.slice(-1)[0]?.tasa_paro}
        formattedValue="{formatNumber(paro_terr.slice(-1)[0]?.tasa_paro, 1)} %"
        period="BJI {paro_terr.slice(-1)[0]?.periodo} (lagin txikia: hobe batez bestekoa) · azken urteko batez bestekoa {formatNumber(paro_terr.slice(-1)[0]?.media_4t_tasa_paro, 1)} % · Espainia {formatNumber(paro_terr.slice(-1)[0]?.tasa_paro_espana, 1)} %"
        direction="positive-down"
        source="INE / BJI"
        href="/eu/economia/paro"
        sparklineData={paro_terr.slice(-40).map(d => d.tasa_paro)}
    />
    <KpiCard
        title="25 urtetik beherakoen langabezia"
        value={paro_terr.slice(-1)[0]?.tasa_paro_menor25}
        formattedValue="{formatNumber(paro_terr.slice(-1)[0]?.tasa_paro_menor25, 1)} %"
        period="{paro_terr.slice(-1)[0]?.periodo} · Espainia {formatNumber(paro_terr.slice(-1)[0]?.tasa_paro_menor25_espana, 1)} %"
        direction="positive-down"
        source="INE / BJI"
        href="/eu/economia/paro"
        sparklineData={paro_terr.slice(-40).map(d => d.tasa_paro_menor25)}
    />
    <KpiCard
        title="Erregistratutako langabezia"
        value={paro_reg_terr.slice(-1)[0]?.por_100_16_64}
        formattedValue="{formatNumber(paro_reg_terr.slice(-1)[0]?.por_100_16_64, 1)} 100 biz. bakoitzeko"
        period="16 eta 64 urte bitartekoak, {paro_reg_terr.slice(-1)[0]?.mes_txt} · {formatNumber(paro_reg_terr.slice(-1)[0]?.paro_registrado, 0)} pertsona ({formatNumber(paro_reg_terr.slice(-1)[0]?.variacion_anual_pct, 1)} % urtebetean)"
        direction="positive-down"
        source="SEPE"
        href="/eu/economia/paro"
        sparklineData={paro_reg_terr.slice(-36).map(d => d.por_100_16_64)}
    />
</Grid>

<LineChart
    data={paro_terr}
    x=trimestre
    y={['media_4t_tasa_paro', 'tasa_paro_espana']}
    seriesLabels={{media_4t_tasa_paro: terr[0]?.nombre + ' (4 hiruhilekoren batez bestekoa)', tasa_paro_espana: 'Espainia'}}
    colorPalette={['#2563eb', '#94a3b8']}
    yFmt='0.0"%"'
    yAxisTitle="Biztanleria aktiboaren %"
    title="Langabezia-tasa (BJI; probintziakoa azken 4 hiruhilekoen batez bestekoa da)"
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
    '/eu/territorios/municipios?m=' || m.cod_mun AS enlace
FROM mother.renta_municipios m
WHERE m.cod_prov = '${terr[0]?.cod}' AND m.anio = (SELECT max(anio) FROM mother.renta_municipios)
  AND m.renta_persona_real IS NOT NULL
ORDER BY m.renta_persona_real DESC
```

{#if renta_prov.length > 0}

## Etxeen errenta

<Grid cols=2>
    <KpiCard
        title="Pertsonako batez besteko errenta garbia"
        value={renta_prov.slice(-1)[0]?.renta_persona_real}
        formattedValue="{formatNumber(renta_prov.slice(-1)[0]?.renta_persona_real, 0)} €"
        period="urtean, {renta_prov.slice(-1)[0]?.anio}, 2025eko eurotan · postua: {renta_prov_puesto[0]?.puesto}/52{renta_prov.slice(-1)[0]?.renta_persona_espana != null ? ` · Espainia ${formatNumber(renta_prov.slice(-1)[0]?.renta_persona_espana, 0)} €` : ''}"
        direction="positive-up"
        source="INE / Errentaren Atlasa"
        href="/eu/sociedad/desigualdad"
        sparklineData={renta_prov.map(d => d.renta_persona_real)}
    />
    <KpiCard
        title="Etxeko batez besteko errenta garbia"
        value={renta_prov.slice(-1)[0]?.renta_hogar_real}
        formattedValue="{formatNumber(renta_prov.slice(-1)[0]?.renta_hogar_real, 0)} €"
        period="urtean, {renta_prov.slice(-1)[0]?.anio}, 2025eko eurotan"
        direction="positive-up"
        source="INE / Errentaren Atlasa"
        href="/eu/sociedad/desigualdad"
        sparklineData={renta_prov.map(d => d.renta_hogar_real)}
    />
</Grid>

<DataTable data={renta_prov_municipios} link=enlace rows=10 search=true>
    <Column id=municipio title="Udalerria"/>
    <Column id=renta_persona_real title="Errenta pertsonako (€)" fmt='#,##0'/>
    <Column id=renta_hogar_real title="Errenta etxeko (€)" fmt='#,##0'/>
    <Column id=poblacion title="Biztanleak" fmt='#,##0'/>
</DataTable>

<p class="text-xs text-gray-500">INEren Etxeen Errenta Banaketaren Atlasa (zerga-datuak), inflazioa kenduta. Gehiago: <a href="/eu/sociedad/desigualdad">Errenta, pobrezia eta desberdintasuna</a>.</p>

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

## Etxebizitza

<Grid cols=4>
    <KpiCard
        title="Etxebizitzaren prezioa"
        value={viv[0]?.euros_m2_real}
        formattedValue="{formatNumber(viv[0]?.euros_m2_real, 0)} €/m²"
        period="tasatutako balioa, {viv[0]?.precio_periodo} · Espainia: {formatNumber(viv[0]?.euros_m2_real_espana, 0)} €/m²"
        change={viv[0]?.precio_interanual_real?.toFixed(1)}
        changePeriod="erreala, urtebete lehenagoko aldean"
        source="Etxebizitza Ministerioa"
        href="/eu/vivienda/precios"
        sparklineData={viv_serie.filter(d => d.serie === 'precio').map(d => d.valor)}
    />
    <KpiCard
        title="Pisu baten alokairu mediana"
        value={viv[0]?.alquiler_mes_mediana_real}
        formattedValue="{formatNumber(viv[0]?.alquiler_mes_mediana_real, 0)} €/hil."
        period="{viv[0]?.alquiler_anio} · Espainia: {formatNumber(viv[0]?.alquiler_espana, 0)} €/hil."
        source="Etxebizitza Ministerioa (SERPAVI)"
        href="/eu/vivienda/alquiler"
        sparklineData={viv_serie.filter(d => d.serie === 'alquiler').map(d => d.valor)}
    />
    <KpiCard
        title="Salerosketak 1.000 biz. bakoitzeko"
        value={viv[0]?.compraventas_12m_1000}
        formattedValue={formatNumber(viv[0]?.compraventas_12m_1000, 1)}
        period="{viv[0]?.mercado_mes} arteko 12 hilabeteak · Espainia: {formatNumber(viv[0]?.compraventas_espana, 1)}"
        source="INE / ETDP"
        href="/eu/vivienda/compraventas"
        sparklineData={viv_serie.filter(d => d.serie === 'compraventas').map(d => d.valor)}
    />
    <KpiCard
        title="Amaitutako etxebizitzak 1.000 biz. bakoitzeko"
        value={viv[0]?.terminadas_1000}
        formattedValue={formatNumber(viv[0]?.terminadas_1000, 2)}
        period="etxebizitza librea, {viv[0]?.obra_anio} · Espainia: {formatNumber(viv[0]?.terminadas_espana, 2)}"
        source="Etxebizitza Ministerioa"
        href="/eu/vivienda/construccion"
        sparklineData={viv_serie.filter(d => d.serie === 'terminadas').map(d => d.valor)}
    />
</Grid>

<LineChart
    data={viv_precio}
    x=fecha
    y=euros_m2_real
    series=nombre
    yFmt='#,##0" €"'
    yAxisTitle="€/m² ({urte(viv[0]?.anio_base, 'ko')} eurotan)"
    startingAtZero={false}
    title="Etxebizitzaren tasatutako balioa, inflazioa kenduta"
/>

{#if viv_municipios.length > 0}
<DataTable data={viv_municipios}>
    <Column id=municipio title="Udalerria" />
    <Column id=euros_m2_real title="Tasatutako balioa €/m² (erreala)" fmt='#,##0' />
    <Column id=precio_var_real title="Urteko aldakuntza erreala %" fmt='0.0' contentType=delta />
    <Column id=alquiler_mes_mediana_real title="Pisuaren alokairua €/hil." fmt='#,##0' />
    <Column id=alquiler_var_5a title="Alokairua: 5 urteko aldakuntza erreala %" fmt='0.0' contentType=delta />
</DataTable>
<p class="text-xs text-gray-500">Tasatutako balioa: 25.000 biztanletik gorako udalerriak. Alokairua (PFEZaren datuak): 20.000 biztanle edo gehiagoko udalerriak.</p>
{/if}

<p class="text-xs text-gray-500">Prezioak eta alokairuak {urte(viv[0]?.anio_base, 'ko')} eurotan. Xehetasun gehiago: <a href="/eu/vivienda">Etxebizitza</a>.</p>

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

## Pentsioak

<Grid cols=3>
    <KpiCard
        title="Erretiro-pentsioaren batez bestekoa"
        value={pensiones_terr[0]?.pension_media_jubilacion_real}
        formattedValue="{formatNumber(pensiones_terr[0]?.pension_media_jubilacion_real, 0)} €/hil."
        period="{pensiones_terr[0]?.anio} ({pensiones_terr[0]?.meses} hilabeteren batez bestekoa), {urte(pensiones_terr[0]?.anio_euros, 'ko')} eurotan · Espainia: {formatNumber(pensiones_terr[0]?.jub_espana, 0)} € · postua: {pensiones_terr[0]?.puesto_pension}/{pensiones_terr[0]?.n_territorios}"
        source="Gizarte Segurantza"
        sparklineData={pensiones_terr_serie.map(d => d.pension_media_jubilacion_real)}
    />
    <KpiCard
        title="Pentsioak 1.000 biztanleko"
        value={pensiones_terr[0]?.pensiones_por_1000_hab}
        formattedValue={formatNumber(pensiones_terr[0]?.pensiones_por_1000_hab, 0)}
        period="Espainia: {formatNumber(pensiones_terr[0]?.por_1000_espana, 0)} · {formatNumber(pensiones_terr[0]?.pensiones_por_100_mayores, 0)} 65+ urteko 100 pertsonako · {formatNumber(pensiones_terr[0]?.pensiones, 0)} pentsio"
        source="Gizarte Segurantza / INE"
        sparklineData={pensiones_terr_serie.map(d => d.pensiones_por_1000_hab)}
    />
    <KpiCard
        title="Afiliatuak pentsioko"
        value={pensiones_terr[0]?.afiliados_por_pension}
        formattedValue={formatNumber(pensiones_terr[0]?.afiliados_por_pension, 2)}
        period="Espainia: {formatNumber(pensiones_terr[0]?.ratio_espana, 2)} (probintziako datuak 2021etik)"
        source="Gizarte Segurantza"
        sparklineData={pensiones_terr_serie.filter(d => d.afiliados_por_pension != null).map(d => d.afiliados_por_pension)}
    />
</Grid>

<p class="text-xs text-gray-500">Gizarte Segurantzaren kotizazio-pentsioak. 14 ordainsarietako bakoitzaren zenbateko gordinak, inflazioa kenduta. Gehiago: <a href="/eu/cuentas-publicas/pensiones">Pentsioak</a>.</p>

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
SELECT f.fecha, f.familia, f.color, f.orden_familia, f.pct, f.escanos
FROM mother.elecciones_familias f
WHERE f.nivel = 'provincia' AND f.cod = '${terr[0]?.cod}' AND f.tipo = '02'
  AND f.familia IN (SELECT familia FROM mother.elecciones_familias
      WHERE nivel = 'provincia' AND cod = '${terr[0]?.cod}' AND tipo = '02' AND bloque <> 'Otros'
      GROUP BY familia HAVING max(pct) >= 5)
ORDER BY f.fecha, f.orden_familia
```

```sql elec_colores
SELECT DISTINCT familia, color, orden_familia FROM ${elec_familias} ORDER BY orden_familia
```

{#if elec.length > 0}

## Hauteskundeak

<Grid cols=3>
    <KpiCard title="Parte-hartzea hauteskunde orokorretan" value={elec.slice(-1)[0]?.participacion}
        formattedValue="{formatNumber(elec.slice(-1)[0]?.participacion, 1)} %"
        period="{elec.slice(-1)[0]?.fecha_txt} · Espainia: {formatNumber(elec.slice(-1)[0]?.participacion_espana, 1)} %"
        source="Barne Ministerioa" href="/eu/sociedad/elecciones" sparklineData={elec} />
    <KpiCard title="Boto gehien jaso duen hautagaitza" value={elec.slice(-1)[0]?.ganador_pct}
        formattedValue="{elec.slice(-1)[0]?.ganador_siglas} · {formatNumber(elec.slice(-1)[0]?.ganador_pct, 1)} %"
        period="bigarrena: {elec.slice(-1)[0]?.segundo_siglas} ({formatNumber(elec.slice(-1)[0]?.segundo_pct, 1)} %) · {formatNumber(elec.slice(-1)[0]?.escanos, 0)} eserleku probintzian"
        source="Barne Ministerioa" sparklineData={elec.map(d => ({valor: d.ganador_pct}))} />
    <KpiCard title="Alderdien kopuru eraginkorra" value={elec.slice(-1)[0]?.nep_votos}
        formattedValue={formatNumber(elec.slice(-1)[0]?.nep_votos, 1)} period="botoetan, azken hauteskunde orokorrak"
        source="Kalkulu propioa" sparklineData={elec.map(d => ({valor: d.nep_votos}))} />
</Grid>

<LineChart data={elec_familias} x=fecha y=pct series=familia yFmt='0.0"%"' markers=true
    seriesColors={Object.fromEntries(elec_colores.map(d => [d.familia, d.color]))}
    title="Botoa hauteskunde orokorretan familia politikoaren arabera, baliozko botoen %" />

<LineChart data={elec_part} x=fecha y=participacion series=ambito yFmt='0.0"%"' markers=true
    seriesColors={{'España': '#94a3b8'}} title="Parte-hartzea hauteskunde orokorretan, %" />

{/if}

## Iturri ofizialak

- **Atal berriak**: BJI (INE) eta erregistratutako langabezia (SEPE); Errentaren Banaketaren Atlasa (INE); tasatutako balioa eta SERPAVI (Etxebizitza Ministerioa); kotizazio-pentsioak (Gizarte Segurantza); jaiotzak eta biztanleria (INE).

- **[INE – Udalerrien biztanleria-zifra ofizialak (Udal Erroldak)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**
- **[Ogasun Ministerioa – Toki-erakundeen zor bizia](https://www.hacienda.gob.es/es-ES/CDI/Paginas/SistemasFinanciacionDeuda/InformacionEELLs/DeudaViva.aspx)**: erakunde bakoitzaren zorra abenduaren 31n, Espainiako Bankuaren guztizkoarekin bateratuta.
- **[Espainiako Bankua – Buletin Estatistikoa, 14. kapitulua](https://www.bde.es/webbe/es/estadisticas/temas/administraciones-publicas.html)**: 300.000 biztanletik gorako udalen zorra.
- **[Instituto Geográfico Nacional (es-atlas bidez)](https://github.com/martgnz/es-atlas)**: udal-mugak (CC BY 4.0).

<LastRefreshed prefix="Datuak eguneratuta" />
