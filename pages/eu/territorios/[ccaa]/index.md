---
description: "Autonomia-erkidegoaren fitxa: biztanleria, ekonomia, kontu publikoak, zorra, enplegu publikoa, segurtasuna eta gehiago, datu ofizialekin eta Espainiarekin alderatuta."
i18n_origen: b9c51634f0cb
breadcrumb: "SELECT nombre AS breadcrumb FROM mother.territorios WHERE nivel = 'ccaa' AND slug = '${params.ccaa}'"
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // Urteei euskal atzizkia eransten die (2021eko, 2023ko, 1979tik...)
    const urte = (n, s) => (n == null || n === '' ? '' : n + ([1, 5, 10, 15].includes(Number(n) % 20) ? 'e' : '') + s);
    // Datuetatik gaztelaniaz datozen datak euskaratzen ditu («mayo de 2024» → «2024ko maiatza»)
    const HILAK = {enero: 'urtarrila', febrero: 'otsaila', marzo: 'martxoa', abril: 'apirila', mayo: 'maiatza', junio: 'ekaina', julio: 'uztaila', agosto: 'abuztua', septiembre: 'iraila', octubre: 'urria', noviembre: 'azaroa', diciembre: 'abendua'};
    const dataEu = (t) => {
        const s = String(t ?? '');
        let m = s.match(/^(\d{1,2}) de (\p{L}+) de (\d{4})$/u);
        if (m && HILAK[m[2].toLowerCase()]) return urte(m[3], 'ko') + ' ' + HILAK[m[2].toLowerCase()].slice(0, -1) + 'aren ' + m[1];
        m = s.match(/^(\p{L}+) de (\d{4})$/u);
        if (m && HILAK[m[1].toLowerCase()]) return urte(m[2], 'ko') + ' ' + HILAK[m[1].toLowerCase()];
        return s;
    };
</script>

```sql terr
SELECT * FROM mother.territorios WHERE nivel = 'ccaa' AND slug = '${params.ccaa}'
```

```sql espana
SELECT poblacion_ultima FROM mother.territorios WHERE nivel = 'pais'
```

```sql base
-- Año de los euros constantes (último año completo de IPC)
SELECT max(anio_base) AS anio_base FROM mother.deflactor
```

```sql serie_poblacion
SELECT make_date(CAST(anio AS INTEGER), 1, 1) AS fecha, poblacion AS valor
FROM mother.poblacion_territorios
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND sexo = 'Total'
ORDER BY anio
```

```sql peso_serie
SELECT c.anio, 100.0 * c.poblacion / e.poblacion AS valor
FROM mother.poblacion_territorios c
JOIN mother.poblacion_territorios e
  ON e.nivel = 'pais' AND e.sexo = 'Total' AND e.anio = c.anio
WHERE c.nivel = 'ccaa' AND c.cod = '${terr[0]?.cod}' AND c.sexo = 'Total'
ORDER BY c.anio
```

```sql poblacion_sexo
SELECT sexo, poblacion
FROM mother.poblacion_territorios
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND sexo <> 'Total'
  AND anio = (SELECT max(anio) FROM mother.poblacion_territorios)
```

```sql provincias
SELECT
    t.cod, t.nombre, '/eu' || t.ruta AS ruta, t.poblacion_ultima AS poblacion,
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
    '/eu/territorios/municipios?m=' || a.cod_mun AS enlace
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

<p class="text-sm text-gray-500"><a href="/eu/territorios">Lurraldeak</a> › {terr[0]?.nombre}</p>

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
        title="Pisua Espainian"
        value={100 * terr[0]?.poblacion_ultima / espana[0]?.poblacion_ultima}
        formattedValue={formatNumber(terr[0]?.poblacion_ultima / espana[0]?.poblacion_ultima / 0.01, 1)}
        unit="%"
        period="Espainiako biztanleriaren gainean"
        sparklineData={peso_serie}
    />
    <KpiCard
        title="Udalerriak"
        value={resumen_municipios[0]?.n}
        formattedValue={formatNumber(resumen_municipios[0]?.n, 0)}
        period="{formatNumber(resumen_municipios[0]?.menos_1000, 0)} 1.000 biz. baino gutxiagokoak · 10 urtean biztanleria galdu dutenak: {formatNumber(resumen_municipios[0]?.pierden, 0)}"
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
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND tasa_natalidad IS NOT NULL
ORDER BY anio
```

```sql demo_edades
SELECT CAST(anio AS INTEGER) AS anio, pct_65, pct_80, dependencia, edad_media, pct_nacidos_extranjero
FROM mother.demografia_envejecimiento
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}'
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
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}'
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

<p class="text-xs text-gray-500">{urte(demo_anual.slice(-1)[0]?.anio, 'an')}, {terr[0]?.nombre} lurraldeko biztanleria {formatNumber(demo_anual.slice(-1)[0]?.crecimiento_1000, 1)} aldatu zen 1.000 biztanleko: {formatNumber(demo_anual.slice(-1)[0]?.vegetativo_1000, 1)} jaiotzak ken heriotzak direla eta, eta {formatNumber(demo_anual.slice(-1)[0]?.resto_1000, 1)} migrazioa (atzerriarekin eta beste erkidego batzuekin) eta doikuntzak direla eta. Biztanleen {formatNumber(demo_edades.slice(-1)[0]?.pct_nacidos_extranjero, 1)} % atzerrian jaio zen. Iturria: INE (Biztanleriaren Mugimendu Naturala, Oinarrizko Adierazle Demografikoak eta Biztanleriaren Etengabeko Estatistika).</p>

{#if provincias.length > 1}

## Probintziak

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 not-prose">
{#each provincias as p}
    <a href={p.ruta} class="block rounded-lg border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-3 hover:border-blue-400 no-underline">
        <span class="font-semibold text-gray-900 dark:text-white">{p.nombre}</span>
        <span class="block text-xs text-gray-500">{formatNumber(p.poblacion, 0)} biz. · {p.municipios} udalerri</span>
    </a>
{/each}
</div>

{:else}

<p>{terr[0]?.nombre} probintzia bakarreko erkidegoa da. <a href={provincias[0]?.ruta}>Ikusi {provincias[0]?.nombre} probintziaren fitxa</a>.</p>

{/if}

## Udalerriak

<MapaEspana
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
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Mugak © Instituto Geográfico Nacional"
    tooltip={[
        {id: 'municipio', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'poblacion', title: 'Biztanleria', fmt: 'num0'},
        {id: 'crecimiento', title: 'Hazkundea 10 urtean (%)', fmt: 'num1'}
    ]}
/>

<p class="text-xs text-gray-500">Kolore-eskala biztanle gehien dituzten udalerrien % 10ean asetzen da, txikiak bereiz daitezen.</p>

<DataTable data={municipios} search=true rows=15 link=enlace showLinkCol=false>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=poblacion title="Biztanleria" fmt=num0 />
    <Column id=crecimiento title="Hazkundea 10 urtean (%)" fmt=num1 contentType=delta />
</DataTable>

```sql cuentas
SELECT
    r.anio,
    make_date(CAST(r.anio AS INTEGER), 1, 1) AS fecha,
    r.ingresos_no_financieros,
    r.gastos_no_financieros,
    r.saldo_no_financiero,
    -- Euros por habitante constantes (euros del último año completo)
    r.gastos_nf_eur_hab_real AS gasto_hab_real,
    r.ingresos_nf_eur_hab_real AS ingreso_hab_real,
    r.saldo_nf_eur_hab_real AS saldo_hab_real
FROM mother.ccaa_cuentas_resumen r
WHERE r.cod_ccaa = '${terr[0]?.cod}'
ORDER BY r.anio
```

```sql cuentas_ultimo
SELECT * FROM ${cuentas} ORDER BY anio DESC LIMIT 1
```

```sql cuentas_evolucion
SELECT fecha, 'Ingresos' AS concepto, ingreso_hab_real AS importe FROM ${cuentas}
UNION ALL
SELECT fecha, 'Gastos', gasto_hab_real FROM ${cuentas}
ORDER BY fecha
```

```sql gasto_ranking
WITH ultimo AS (SELECT max(anio) AS anio FROM mother.ccaa_cuentas_resumen WHERE cod_ccaa <= '17')
SELECT
    r.ccaa AS comunidad,
    r.gastos_nf_eur_hab_real AS gasto_hab,
    CASE WHEN r.cod_ccaa = '${terr[0]?.cod}' THEN 'Esta comunidad' ELSE 'Resto' END AS grupo
FROM mother.ccaa_cuentas_resumen r
WHERE r.anio = (SELECT anio FROM ultimo) AND r.cod_ccaa <= '17'
ORDER BY gasto_hab DESC
```

```sql politicas
-- Gasto por política (depurado de transferencias a ayuntamientos y fondos
-- PAC) por habitante, frente a la media de las 17 comunidades. Los importes
-- por habitante van en euros constantes del último año completo.
WITH anio AS (SELECT max(anio) AS anio FROM mother.ccaa_gasto_politicas WHERE cod_ccaa = '${terr[0]?.cod}'),
por_ccaa AS (
    SELECT g.cod_ccaa, g.cod_politica, g.politica_nombre,
        sum(g.obligaciones) AS obligaciones,
        sum(g.obligaciones_eur_hab_real) AS hab_real,
        any_value(g.poblacion) AS poblacion
    FROM mother.ccaa_gasto_politicas g
    WHERE g.anio = (SELECT anio FROM anio) AND g.cod_ccaa <= '17'
    GROUP BY ALL
),
media AS (
    SELECT cod_politica, sum(hab_real * poblacion) / sum(poblacion) AS media_hab_real
    FROM por_ccaa GROUP BY cod_politica
)
SELECT
    c.politica_nombre AS politica,
    c.obligaciones,
    c.hab_real AS por_habitante,
    m.media_hab_real AS media_ccaa,
    100.0 * (c.hab_real - m.media_hab_real) / nullif(m.media_hab_real, 0) AS dif_pct,
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
    CASE c.tipo WHEN 'ingreso' THEN 'Ingresos' ELSE 'Gastos' END AS tipo,
    c.capitulo,
    c.capitulo_nombre,
    c.anio,
    c.ejecutado_eur_hab_real AS ejecutado_hab,
    c.presupuesto_definitivo,
    c.ejecutado,
    c.ejecutado / nullif(c.presupuesto_definitivo, 0) AS grado_ejecucion
FROM mother.ccaa_cuentas_capitulos c
WHERE c.cod_ccaa = '${terr[0]?.cod}'
  AND c.anio = (SELECT max(anio) FROM mother.ccaa_cuentas_capitulos WHERE cod_ccaa = '${terr[0]?.cod}')
ORDER BY c.tipo DESC, c.capitulo
```

{#if cuentas.length > 0 && cuentas_ultimo[0]?.anio >= 2020}

## Erkidegoaren diru-sarrerak eta gastuak

Autonomia-administrazio bateratuaren kontu exekutatuak (likidazioa). Gastu **ez-finantzarioa** erabiltzen da (1etik 7rako kapituluak), aktiboen erosketa eta zorraren itzulketa kanpoan uzten dituena, erkidego bakoitzak zerbitzuetan benetan zenbat gastatzen duen alderatzeko. Zenbateko guztiak **biztanleko** eta **inflazioa kenduta** daude, {urte(base[0]?.anio_base, 'ko')} eurotan: horrela, bilakaera ez da hazten biztanle gehiago egoteagatik edo prezioak igotzeagatik soilik.

<Grid cols=3>
    <KpiCard
        title="Gastu ez-finantzarioa biztanleko"
        value={cuentas_ultimo[0]?.gasto_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.gasto_hab_real, 0)}
        unit="€"
        period="{urte(cuentas_ultimo[0]?.anio, 'ko')} likidazioa, {urte(base[0]?.anio_base, 'ko')} eurotan · guztira: {formatCompact(cuentas_ultimo[0]?.gastos_no_financieros, 0)} € korronte"
        source="Ogasun Ministerioa"
        sparklineData={cuentas.filter(d => d.gasto_hab_real != null).map(d => ({anio: d.anio, valor: d.gasto_hab_real}))}
    />
    <KpiCard
        title="Diru-sarrera ez-finantzarioak biztanleko"
        value={cuentas_ultimo[0]?.ingreso_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.ingreso_hab_real, 0)}
        unit="€"
        period="{urte(base[0]?.anio_base, 'ko')} eurotan · guztira: {formatCompact(cuentas_ultimo[0]?.ingresos_no_financieros, 0)} € korronte"
        sparklineData={cuentas.filter(d => d.ingreso_hab_real != null).map(d => ({anio: d.anio, valor: d.ingreso_hab_real}))}
    />
    <KpiCard
        title="Saldo ez-finantzarioa biztanleko"
        value={cuentas_ultimo[0]?.saldo_hab_real}
        formattedValue={formatNumber(cuentas_ultimo[0]?.saldo_hab_real, 0)}
        unit="€"
        period="Diru-sarrera − gastu ez-finantzarioak, {urte(base[0]?.anio_base, 'ko')} eurotan · guztira: {formatCompact(cuentas_ultimo[0]?.saldo_no_financiero, 0)} € korronte"
        direction="positive-up"
        sparklineData={cuentas.filter(d => d.saldo_hab_real != null).map(d => ({anio: d.anio, valor: d.saldo_hab_real}))}
    />
</Grid>

<BarChart
    data={gasto_ranking}
    x=comunidad
    y=gasto_hab
    series=grupo
    swapXY=true
    yFmt=num0
    title="Gastu ez-finantzarioa biztanleko, {cuentas_ultimo[0]?.anio} ({urte(base[0]?.anio_base, 'ko')} eurotan)"
    colorPalette={['#0f766e', '#cbd5e1']}
    sort=false
/>

### Zertan gastatzen du?

<BarChart
    data={politicas_grafico}
    x=politica
    y=euros
    series=serie
    type=grouped
    swapXY=true
    yFmt=num0
    title="Euroak biztanleko politika bakoitzean ({urte(base[0]?.anio_base, 'ko')} eurotan; gutxienez % 2ko pisua dutenak)"
    colorPalette={['#0f766e', '#94a3b8']}
/>

<DataTable data={politicas} rows=all>
    <Column id=politica title="Gastu-politika" />
    <Column id=por_habitante title="€/biztanle ({urte(base[0]?.anio_base, 'ko')} eurotan)" fmt=num0 />
    <Column id=media_ccaa title="AEen batez bestekoa (€/biz.)" fmt=num0 />
    <Column id=dif_pct title="Aldea (%)" fmt=num0 contentType=delta />
    <Column id=peso title="Pisua" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=obligaciones title="Gastua guztira (€ korronte)" fmt=num0 />
</DataTable>

### Bilakaera

<LineChart
    data={cuentas_evolucion}
    x=fecha
    y=importe
    series=concepto
    yFmt=num0
    yAxisTitle="€ biztanleko"
    title="Diru-sarrera eta gastu ez-finantzarioak biztanleko ({urte(base[0]?.anio_base, 'ko')} eurotan, inflazioa kenduta)"
    colorPalette={['#0f766e', '#b45309']}
/>

<Details title="Azken urteko xehetasuna kapituluka">

<DataTable data={capitulos} rows=all groupBy=tipo>
    <Column id=capitulo title="Kap." />
    <Column id=capitulo_nombre title="Kapitulua" />
    <Column id=ejecutado_hab title="Exekutatua biztanleko ({urte(base[0]?.anio_base, 'ko')} eurotan)" fmt=num0 />
    <Column id=presupuesto_definitivo title="Behin betiko aurrekontua (€)" fmt=num0 />
    <Column id=ejecutado title="Exekutatua (€)" fmt=num0 />
    <Column id=grado_ejecucion title="Exekuzioa" fmt=pct0 />
</DataTable>

</Details>

{:else}

<p class="text-sm text-gray-500">Ogasunak {terr[0]?.nombre} lurraldearen likidazioa 2012ra arte baino ez du argitaratzen; horregatik, ez da gainerako erkidegoekiko alderaketa erakusten.</p>

{/if}

```sql deuda
SELECT fecha, anio, trimestre, deuda_eur, deuda_pct_pib
FROM mother.ccaa_deuda
WHERE cod_ccaa = '${terr[0]?.cod}'
ORDER BY fecha
```

```sql deuda_ultima
-- Deuda por habitante en euros constantes (deuda_eur_hab_real)
SELECT
    d.fecha, d.anio, d.trimestre, d.deuda_eur, d.deuda_pct_pib,
    d.deuda_eur_hab_real AS deuda_hab_real,
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

```sql deuda_hab_serie
-- Deuda al cierre de cada año (último trimestre publicado) por habitante, en euros constantes
-- (sin deflactor antes de 1996: la serie real empieza ese año)
SELECT anio, deuda_eur_hab_real AS valor
FROM mother.ccaa_deuda
WHERE cod_ccaa = '${terr[0]?.cod}' AND deuda_eur_hab_real IS NOT NULL
QUALIFY row_number() OVER (PARTITION BY anio ORDER BY fecha DESC) = 1
ORDER BY anio
```

```sql saldo
SELECT make_date(CAST(anio AS INTEGER), 1, 1) AS fecha, anio, saldo_eur, saldo_pct_pib / 100 AS saldo_pct_pib, saldo_pct_pib AS saldo_pct
FROM mother.ccaa_saldo
WHERE cod_ccaa = '${terr[0]?.cod}'
ORDER BY anio
```

{#if deuda.length > 0}

## Zorra eta defizita

<Grid cols=3>
    <KpiCard
        title="Zor publikoa biztanleko"
        value={deuda_ultima[0]?.deuda_hab_real}
        formattedValue={formatNumber(deuda_ultima[0]?.deuda_hab_real, 0)}
        unit="€"
        period="{urte(deuda_ultima[0]?.anio, 'ko')} {deuda_ultima[0]?.trimestre}. hiruhil., {urte(base[0]?.anio_base, 'ko')} eurotan · guztira: {formatCompact(deuda_ultima[0]?.deuda_eur, 0)} € korronte"
        source="Espainiako Bankua (GDP)"
        sparklineData={deuda_hab_serie}
    />
    <KpiCard
        title="Zorra eskualdeko BPGaren gainean"
        value={deuda_ultima[0]?.deuda_pct_pib}
        formattedValue={formatNumber(deuda_ultima[0]?.deuda_pct_pib, 1)}
        unit="%"
        change={deuda_ultima[0]?.pct_pib_hace_un_anio != null ? (deuda_ultima[0].deuda_pct_pib - deuda_ultima[0].pct_pib_hace_un_anio).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="duela urtebeteko aldean"
        direction="positive-down"
        sparklineData={deuda.filter(d => d.deuda_pct_pib != null).slice(-40).map(d => ({fecha: d.fecha, valor: d.deuda_pct_pib}))}
    />
    {#if saldo.length > 0}
    <KpiCard
        title="Defizita (−) edo superabita (+)"
        value={saldo[saldo.length - 1]?.saldo_pct}
        formattedValue={formatNumber(saldo[saldo.length - 1]?.saldo_pct, 1)}
        unit="BPGaren %"
        period="{urte(saldo[saldo.length - 1]?.anio, 'an')}"
        direction="positive-up"
        sparklineData={saldo.map(d => ({anio: d.anio, valor: d.saldo_pct}))}
    />
    {/if}
</Grid>

<p class="text-xs text-gray-500">Biztanleko zorrak urte bakoitzeko Udal Erroldako biztanleria erabiltzen du (Udal Errolda ez duten urteetan, eskuragarri dagoen azkena) eta inflazioa kenduta dago: {urte(base[0]?.anio_base, 'ko')} euroak (miniaturako seriea 1996an hasten da, deflaktorea duen lehen urtean).</p>

<BarChart
    data={deuda_ranking}
    x=comunidad
    y=deuda_pct_pib
    series=grupo
    swapXY=true
    yFmt=pct0
    title="Zorra eskualdeko BPGaren gainean, erkidego guztiak"
    colorPalette={['#1d4ed8', '#cbd5e1']}
    sort=false
/>

<LineChart
    data={deuda}
    x=fecha
    y=deuda_pct_pib
    yFmt=num0
    yAxisTitle="Eskualdeko BPGaren %"
    title="Zorraren bilakaera (eskualdeko BPGaren %)"
    lineColor="#1d4ed8"
/>

{#if saldo.length > 0}

<BarChart
    data={saldo}
    x=anio
    y=saldo_pct_pib
    yFmt=pct1
    title="Urteko superabita (+) edo defizita (−), eskualdeko BPGaren %"
    fillColor="#64748b"
/>

<p class="text-xs text-gray-500">Urteko saldoa Espainiako Bankuak argitaratutako hamabi hilabeteen batura da (urte osoak soilik); ehunekoa bere zor-serieetan inplizitu dagoen eskualdeko BPGarekin kalkulatzen da.</p>

{/if}

{:else}

<p class="text-sm text-gray-500">Espainiako Bankuak ez du {terr[0]?.nombre} hiriaren zor propiorik argitaratzen: Gehiegizko Defizitaren Prozeduran, Ceuta eta Melilla toki-administrazio gisa kontabilizatzen dira.</p>

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
    100.0 * max(t.efectivos) FILTER (WHERE t.administracion = 'Comunidades autónomas') / max(t.efectivos) FILTER (WHERE t.administracion = 'Total') AS pct_ccaa,
    100.0 * max(t.efectivos) FILTER (WHERE t.administracion = 'Estado') / max(t.efectivos) FILTER (WHERE t.administracion = 'Total') AS pct_estado,
    100.0 * max(t.efectivos) FILTER (WHERE t.administracion = 'Entidades locales') / max(t.efectivos) FILTER (WHERE t.administracion = 'Total') AS pct_local,
    (SELECT por_1000_hab FROM mother.empleo_territorio WHERE nivel = 'pais' AND administracion = 'Total' AND fecha = t.fecha) AS por_1000_espana,
    (SELECT count(*) + 1 FROM mother.empleo_territorio o
      WHERE o.nivel = 'ccaa' AND o.administracion = 'Total' AND o.fecha = t.fecha
        AND o.por_1000_hab > max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Total')) AS puesto
FROM mother.empleo_territorio t, ult
WHERE t.nivel = 'ccaa' AND t.cod = '${terr[0]?.cod}' AND t.fecha = ult.fecha
GROUP BY t.fecha
```

```sql empleo_sectores
-- Por 1.000 habitantes, con la última población del Padrón
SELECT
    sector, administracion,
    1000.0 * sum(efectivos) / (SELECT poblacion_ultima FROM mother.territorios WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}') AS por_1000,
    sum(efectivos) AS efectivos
FROM mother.empleo_efectivos
WHERE cod_ccaa = '${terr[0]?.cod}' AND fecha = (SELECT max(fecha) FROM mother.empleo_efectivos)
GROUP BY ALL
ORDER BY efectivos DESC
```

```sql empleo_serie
SELECT fecha, administracion, por_1000_hab, efectivos
FROM mother.empleo_territorio
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND administracion <> 'Total'
ORDER BY fecha
```

```sql empleo_total_serie
SELECT fecha, efectivos, por_1000_hab
FROM mother.empleo_territorio
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND administracion = 'Total'
ORDER BY fecha
```

```sql empleo_gasto_serie
-- Gasto de personal de la comunidad por habitante, en euros constantes
SELECT g.anio, g.gasto_personal_ccaa_eur_hab_real AS valor
FROM mother.empleo_gasto_personal_territorio g
WHERE g.nivel = 'ccaa' AND g.cod = '${terr[0]?.cod}' AND g.gasto_personal_ccaa_eur_hab_real IS NOT NULL
ORDER BY g.anio
```

```sql empleo_gasto
-- Importes por habitante en euros constantes del último año completo
SELECT
    g.anio,
    g.gasto_personal_ccaa,
    g.gasto_personal_ccaa_eur_hab_real AS gasto_personal_ccaa_hab,
    g.gasto_personal_ayuntamientos_eur_hab_real AS gasto_personal_ayuntamientos_hab,
    (SELECT avg(gasto_personal_ccaa_eur_hab_real) FROM mother.empleo_gasto_personal_territorio x WHERE x.nivel = 'ccaa' AND x.anio = g.anio AND x.cod <= '17') AS media_ccaa_hab,
    (SELECT gasto_personal_ayuntamientos_eur_hab_real FROM mother.empleo_gasto_personal_territorio x WHERE x.nivel = 'pais' AND x.anio = g.anio) AS aytos_espana_hab
FROM mother.empleo_gasto_personal_territorio g
WHERE g.nivel = 'ccaa' AND g.cod = '${terr[0]?.cod}' AND g.gasto_personal_ccaa IS NOT NULL
ORDER BY g.anio DESC
LIMIT 1
```

```sql empleo_salario
SELECT salario_publico, salario_privado FROM mother.empleo_salarios_ccaa WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}'
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

## Segurtasuna

<LineChart
    data={crimen_ccaa}
    x=anio
    y={['tasa', 'tasa_espana']}
    yFmt=num1
    xFmt="####"
    seriesLabels={{tasa: terr[0]?.nombre, tasa_espana: 'Espainia'}}
    colorPalette={['#b91c1c', '#94a3b8']}
    legend=true
    yAxisTitle="1.000 biztanleko"
    title="Arau-hauste penal ezagunak 1.000 biztanleko"
/>

<p class="text-xs text-gray-500">{formatNumber(crimen_ccaa.slice(-1)[0]?.infracciones, 0)} arau-hauste ezagun {urte(crimen_ccaa.slice(-1)[0]?.anio, 'an')} (Barne Ministerioa; polizia autonomikoak barne). 2020 konfinamenduaren urtea da. Delitu motaren eta udalerriaren araberako xehetasuna: <a href="/eu/sociedad/criminalidad">Kriminalitatea</a>.</p>

{/if}

{#if empleo.length > 0}

## Enplegu publikoa

<Grid cols=3>
    <KpiCard
        title="Enplegatu publikoak 1.000 biztanleko"
        value={empleo[0]?.por_1000}
        formattedValue={formatNumber(empleo[0]?.por_1000, 1)}
        period="Espainia: {formatNumber(empleo[0]?.por_1000_espana, 1)} · postua: {empleo[0]?.puesto}/19 · {formatNumber(empleo[0]?.efectivos, 0)} enplegatu, {empleo[0]?.fecha_texto} datan"
        source="Langileen Erregistro Zentrala"
        sparklineData={empleo_total_serie.filter(d => d.por_1000_hab != null).map(d => ({fecha: d.fecha, valor: d.por_1000_hab}))}
    />
    <KpiCard
        title="Erkidegoarentzat lan egiten dute"
        value={empleo[0]?.pct_ccaa}
        formattedValue={formatNumber(empleo[0]?.pct_ccaa, 0)}
        unit="%"
        period="enplegu publikoaren gainean · Estatua: {formatNumber(empleo[0]?.pct_estado, 0)} % · toki-erakundeak: {formatNumber(empleo[0]?.pct_local, 0)} %"
        source="Langileen Erregistro Zentrala"
    />
    {#if empleo_gasto.length > 0}
    <KpiCard
        title="Erkidegoaren langile-gastua"
        value={empleo_gasto[0]?.gasto_personal_ccaa_hab}
        formattedValue="{formatNumber(empleo_gasto[0]?.gasto_personal_ccaa_hab, 0)} €/biz."
        period="{empleo_gasto[0]?.anio}, {urte(base[0]?.anio_base, 'ko')} eurotan · erkidegoen batez bestekoa: {formatNumber(empleo_gasto[0]?.media_ccaa_hab, 0)} € · guztira: {formatNumber(empleo_gasto[0]?.gasto_personal_ccaa / 1e9, 1)} mila M€ korronte"
        source="Ogasuna (1. kapitulua)"
        sparklineData={empleo_gasto_serie}
    />
    {/if}
</Grid>

<Grid cols=2>
    <BarChart
        data={empleo_sectores}
        x=sector
        y=por_1000
        series=administracion
        swapXY=true
        sort=false
        yFmt=num1
        colorPalette={['#1d4ed8', '#0f766e', '#f59e0b']}
        title="Sektorearen eta administrazioaren arabera (1.000 biztanleko)"
    />
    <BarChart
        data={empleo_serie}
        x=fecha
        y=por_1000_hab
        series=administracion
        type=stacked
        yFmt=num1
        xFmt="mmm yyyy"
        colorPalette={['#0f766e', '#f59e0b', '#1d4ed8']}
        title="Bilakaera 1.000 biztanleko (urtarrilaren 1a eta uztailaren 1a)"
    />
</Grid>

<p class="text-xs text-gray-500">{terr[0]?.nombre} lurraldean lanpostua duten hiru administrazioetako langileak: Estatua (Guardia Civil, Polizia Nazionala, militarrak, Zerga Agentzia...), erkidegoa (osasuna, hezkuntza, unibertsitateak...) eta toki-erakundeak. {#if empleo_gasto.length > 0 && empleo_gasto[0]?.gasto_personal_ayuntamientos_hab}Erkidegoko udalek {formatNumber(empleo_gasto[0].gasto_personal_ayuntamientos_hab, 0)} € gastatu zituzten langileetan biztanleko {urte(empleo_gasto[0].anio, 'an')} (Espainiako batez bestekoa: {formatNumber(empleo_gasto[0].aytos_espana_hab, 0)} €; {urte(base[0]?.anio_base, 'ko')} eurotan).{/if} {#if empleo_salario.length > 0 && empleo_salario[0]?.salario_publico}Batez besteko soldata gordina 2022an: {formatNumber(empleo_salario[0].salario_publico, 0)} € urtean sektore publikoan eta {formatNumber(empleo_salario[0].salario_privado, 0)} € pribatuan (INE).{/if} 2023ko jauzia, neurri batean, erregistroaren berrikuspen bat da. Gehiago: <a href="/eu/cuentas-publicas/empleo-publico">Enplegu publikoa</a>.</p>

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
WHERE t.nivel = 'ccaa' AND t.cod = '${terr[0]?.cod}'
ORDER BY t.trimestre
```

```sql ipc_terr
SELECT i.mes, strftime(i.mes, '%m/%Y') AS mes_txt, i.var_anual, i.subida_desde_2019
FROM mother.mercado_ipc_ccaa i
WHERE i.cod_ccaa = '${terr[0]?.cod}'
ORDER BY i.mes
```

```sql paro_reg_terr
SELECT mes, strftime(mes, '%m/%Y') AS mes_txt, paro_registrado, por_100_16_64, variacion_anual_pct
FROM mother.mercado_paro_registrado
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}'
ORDER BY mes
```

{#if paro_terr.length > 0}

## Langabezia eta prezioak

<Grid cols=4>
    <KpiCard
        title="Langabezia-tasa"
        value={paro_terr.slice(-1)[0]?.tasa_paro}
        formattedValue="{formatNumber(paro_terr.slice(-1)[0]?.tasa_paro, 1)} %"
        period="BJI {paro_terr.slice(-1)[0]?.periodo} · azken urteko batez bestekoa {formatNumber(paro_terr.slice(-1)[0]?.media_4t_tasa_paro, 1)} % · Espainia {formatNumber(paro_terr.slice(-1)[0]?.tasa_paro_espana, 1)} %"
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
    <KpiCard
        title="Inflazioa"
        value={ipc_terr.slice(-1)[0]?.var_anual}
        formattedValue="{formatNumber(ipc_terr.slice(-1)[0]?.var_anual, 1)} %"
        period="Urte arteko KPIa, {ipc_terr.slice(-1)[0]?.mes_txt} · prezioak +{formatNumber(ipc_terr.slice(-1)[0]?.subida_desde_2019, 1)} % 2019 amaieratik"
        direction="positive-down"
        source="INE / KPI"
        href="/eu/economia/ipc"
        sparklineData={ipc_terr.slice(-36).map(d => d.var_anual)}
    />
</Grid>

<LineChart
    data={paro_terr}
    x=trimestre
    y={['tasa_paro', 'tasa_paro_espana']}
    seriesLabels={{tasa_paro: terr[0]?.nombre, tasa_paro_espana: 'Espainia'}}
    colorPalette={['#2563eb', '#94a3b8']}
    yFmt='0.0"%"'
    yAxisTitle="Biztanleria aktiboaren %"
    title="Langabezia-tasa (BJI)"
/>

{/if}

```sql renta_ccaa
SELECT
    CAST(e.anio AS INTEGER) AS anio,
    CAST(e.anio_renta AS INTEGER) AS anio_renta,
    e.renta_persona_real, e.renta_uc_real, e.tasa_pobreza, e.arope, e.carencia_severa, e.fin_mes_dificultad, e.gini,
    n.renta_persona_real AS renta_persona_espana, n.tasa_pobreza AS pobreza_espana, n.arope AS arope_espana, n.gini AS gini_espana
FROM mother.renta_ecv_ccaa e
LEFT JOIN mother.renta_ecv_ccaa n ON n.cod = '00' AND n.anio = e.anio
WHERE e.cod = '${terr[0]?.cod}' AND e.anio >= 2008
ORDER BY e.anio
```

```sql renta_ccaa_puesto
SELECT puesto_pobreza, puesto_renta, n FROM (
    SELECT cod,
        rank() OVER (ORDER BY tasa_pobreza DESC) AS puesto_pobreza,
        rank() OVER (ORDER BY renta_persona_real DESC) AS puesto_renta,
        count(*) OVER () AS n
    FROM mother.renta_ecv_ccaa
    WHERE nivel = 'ccaa' AND anio = (SELECT max(anio) FROM mother.renta_ecv_ccaa WHERE tasa_pobreza IS NOT NULL)
) WHERE cod = '${terr[0]?.cod}'
```

```sql renta_ccaa_municipios
SELECT m.municipio, m.poblacion, m.renta_persona_real, m.renta_hogar_real, CAST(m.anio AS INTEGER) AS anio,
    '/eu/territorios/municipios?m=' || m.cod_mun AS enlace
FROM mother.renta_municipios m
WHERE m.cod_ccaa = '${terr[0]?.cod}' AND m.anio = (SELECT max(anio) FROM mother.renta_municipios)
  AND m.poblacion > 20000 AND m.renta_persona_real IS NOT NULL
ORDER BY m.renta_persona_real DESC
```

{#if renta_ccaa.length > 0}

## Errenta eta pobrezia

<Grid cols=3>
    <KpiCard
        title="Pertsonako batez besteko errenta"
        value={renta_ccaa.slice(-1)[0]?.renta_persona_real}
        formattedValue="{formatNumber(renta_ccaa.slice(-1)[0]?.renta_persona_real, 0)} €"
        period="urtean, {urte(renta_ccaa.slice(-1)[0]?.anio_renta, 'ko')} errenta, inflazioa kenduta · Espainia {formatNumber(renta_ccaa.slice(-1)[0]?.renta_persona_espana, 0)} € · postua: {renta_ccaa_puesto[0]?.puesto_renta}/{renta_ccaa_puesto[0]?.n}"
        direction="positive-up"
        source="INE / BBI"
        href="/eu/sociedad/desigualdad"
        sparklineData={renta_ccaa.map(d => d.renta_persona_real)}
    />
    <KpiCard
        title="Pobrezia-arriskua"
        value={renta_ccaa.slice(-1)[0]?.tasa_pobreza}
        formattedValue="{formatNumber(renta_ccaa.slice(-1)[0]?.tasa_pobreza, 1)} %"
        period="biztanleriaren gainean, {urte(renta_ccaa.slice(-1)[0]?.anio, 'ko')} inkesta · Espainia {formatNumber(renta_ccaa.slice(-1)[0]?.pobreza_espana, 1)} % · postua: {renta_ccaa_puesto[0]?.puesto_pobreza}/{renta_ccaa_puesto[0]?.n} (1 = pobrezia handiena)"
        direction="positive-down"
        source="INE / BBI"
        href="/eu/sociedad/desigualdad"
        sparklineData={renta_ccaa.map(d => d.tasa_pobreza)}
    />
    <KpiCard
        title="Pobrezia edo bazterkeria (AROPE)"
        value={renta_ccaa.slice(-1)[0]?.arope}
        formattedValue="{formatNumber(renta_ccaa.slice(-1)[0]?.arope, 1)} %"
        period="{urte(renta_ccaa.slice(-1)[0]?.anio, 'ko')} inkesta · Espainia {formatNumber(renta_ccaa.slice(-1)[0]?.arope_espana, 1)} %"
        direction="positive-down"
        source="INE / BBI"
        href="/eu/sociedad/desigualdad"
        sparklineData={renta_ccaa.filter(d => d.arope != null).map(d => d.arope)}
    />
</Grid>

<LineChart
    data={renta_ccaa}
    x=anio
    y={['tasa_pobreza', 'pobreza_espana']}
    seriesLabels={{tasa_pobreza: terr[0]?.nombre, pobreza_espana: 'Espainia'}}
    colorPalette={['#b45309', '#94a3b8']}
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="Biztanleriaren %"
    title="Pobrezia-arriskuaren tasa (inkestaren urtea)"
/>

{#if renta_ccaa_municipios.length > 0}

Pertsonako batez besteko errenta garbia 20.000 biztanletik gorako udalerrietan (Errentaren Banaketaren Atlasa, {renta_ccaa_municipios[0]?.anio}, 2025eko eurotan).

<DataTable data={renta_ccaa_municipios} link=enlace rows=10 search=true>
    <Column id=municipio title="Udalerria"/>
    <Column id=renta_persona_real title="Errenta pertsonako (€)" fmt='#,##0'/>
    <Column id=renta_hogar_real title="Errenta etxeko (€)" fmt='#,##0'/>
    <Column id=poblacion title="Biztanleak" fmt='#,##0'/>
</DataTable>

{/if}

<p class="text-xs text-gray-500">INEren Bizi Baldintzei buruzko Inkesta: errenta inkestaren aurreko urtekoa da. Gehiago: <a href="/eu/sociedad/desigualdad">Errenta, pobrezia eta desberdintasuna</a>.</p>

{/if}

```sql viv
SELECT r.*, e.euros_m2_real AS euros_m2_real_espana, e.alquiler_mes_mediana_real AS alquiler_espana,
       e.compraventas_12m_1000 AS compraventas_espana, e.anios_salario AS anios_salario_espana,
       strftime(r.mercado_fecha, '%m/%Y') AS mercado_mes
FROM mother.vivienda_resumen_territorios r
JOIN mother.vivienda_resumen_territorios e ON e.nivel = 'pais'
WHERE r.nivel = 'ccaa' AND r.cod = '${terr[0]?.cod}'
```

```sql viv_precio
SELECT fecha, nombre, euros_m2_real
FROM mother.vivienda_precio_tasado
WHERE euros_m2_real IS NOT NULL
  AND ((nivel = 'ccaa' AND cod = '${terr[0]?.cod}') OR nivel = 'pais')
ORDER BY fecha, nombre
```

```sql viv_precio_ccaa
SELECT euros_m2_real FROM mother.vivienda_precio_tasado
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND euros_m2_real IS NOT NULL
ORDER BY fecha
```

```sql viv_alquiler
SELECT anio, alquiler_mes_mediana_real FROM mother.vivienda_alquiler
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND tipologia = 'Colectiva'
ORDER BY anio
```

```sql viv_mercado
SELECT fecha, compraventas_12m_1000 FROM mother.vivienda_mercado_mensual
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND compraventas_12m_1000 IS NOT NULL
ORDER BY fecha
```

```sql viv_esfuerzo
SELECT anio, anios_salario FROM mother.vivienda_esfuerzo
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND anios_salario IS NOT NULL
ORDER BY anio
```

```sql viv_provincias
SELECT nombre AS provincia, '/eu' || ruta AS ruta, euros_m2_real, precio_interanual_real, alquiler_mes_mediana_real, compraventas_12m_1000, terminadas_1000
FROM mother.vivienda_resumen_territorios
WHERE nivel = 'provincia' AND cod_ccaa = '${terr[0]?.cod}'
ORDER BY euros_m2_real DESC
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
        sparklineData={viv_precio_ccaa.map(d => d.euros_m2_real)}
    />
    <KpiCard
        title="Pisu baten alokairu mediana"
        value={viv[0]?.alquiler_mes_mediana_real}
        formattedValue="{formatNumber(viv[0]?.alquiler_mes_mediana_real, 0)} €/hil."
        period="{viv[0]?.alquiler_anio} · Espainia: {formatNumber(viv[0]?.alquiler_espana, 0)} €/hil."
        source="Etxebizitza Ministerioa (SERPAVI)"
        href="/eu/vivienda/alquiler"
        sparklineData={viv_alquiler.map(d => d.alquiler_mes_mediana_real)}
    />
    <KpiCard
        title="Salerosketak 1.000 biz. bakoitzeko"
        value={viv[0]?.compraventas_12m_1000}
        formattedValue={formatNumber(viv[0]?.compraventas_12m_1000, 1)}
        period="{viv[0]?.mercado_mes} arteko 12 hilabeteak · Espainia: {formatNumber(viv[0]?.compraventas_espana, 1)}"
        source="INE / ETDP"
        href="/eu/vivienda/compraventas"
        sparklineData={viv_mercado.map(d => d.compraventas_12m_1000)}
    />
    <KpiCard
        title="90 m²-rako soldata-urteak"
        value={viv[0]?.anios_salario}
        formattedValue="{formatNumber(viv[0]?.anios_salario, 1)} urte"
        period="{viv[0]?.esfuerzo_anio} · Espainia: {formatNumber(viv[0]?.anios_salario_espana, 1)}"
        direction="positive-down"
        source="Etxebizitza Ministerioa / INE"
        href="/eu/vivienda/esfuerzo"
        sparklineData={viv_esfuerzo.map(d => d.anios_salario)}
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

{#if viv_provincias.length > 1}
<DataTable data={viv_provincias} link=ruta>
    <Column id=provincia title="Probintzia" />
    <Column id=euros_m2_real title="€/m² (real)" fmt='#,##0' />
    <Column id=precio_interanual_real title="Urteko aldakuntza erreala %" fmt='0.0' contentType=delta />
    <Column id=alquiler_mes_mediana_real title="Alokairua €/hil." fmt='#,##0' />
    <Column id=compraventas_12m_1000 title="Salerosketak 1.000 biz. bakoitzeko" fmt='0.0' />
    <Column id=terminadas_1000 title="Amaitutako etxebizitzak 1.000 biz. bakoitzeko" fmt='0.00' />
</DataTable>
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
WHERE p.nivel = 'ccaa' AND p.cod = '${terr[0]?.cod}'
  AND p.anio = (SELECT max(anio) FROM mother.pensiones_territorio)
```

```sql pensiones_terr_serie
SELECT CAST(anio AS INTEGER) AS anio, pension_media_jubilacion_real, pensiones_por_1000_hab, afiliados_por_pension
FROM mother.pensiones_territorio
WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND meses = 12
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
        period="Espainia: {formatNumber(pensiones_terr[0]?.ratio_espana, 2)} (erkidegoko datuak 2021etik)"
        source="Gizarte Segurantza"
        sparklineData={pensiones_terr_serie.filter(d => d.afiliados_por_pension != null).map(d => d.afiliados_por_pension)}
    />
</Grid>

<p class="text-xs text-gray-500">Gizarte Segurantzaren kotizazio-pentsioak. 14 ordainsarietako bakoitzaren zenbateko gordinak, inflazioa kenduta. Gehiago: <a href="/eu/cuentas-publicas/pensiones">Pentsioak</a>.</p>

{/if}

```sql edu_ccaa
-- Indicadores educativos de la comunidad (último año disponible) frente a España y puesto entre las 19
WITH ult AS (
    SELECT indicador, cod, anio, valor
    FROM mother.educacion_indicadores
    WHERE nivel = 'ccaa' AND indicador IN ('abandono', 'superior_25_64', 'neet_15_29')
    QUALIFY row_number() OVER (PARTITION BY indicador, cod ORDER BY anio DESC) = 1
),
rk AS (
    SELECT *,
        rank() OVER (PARTITION BY indicador ORDER BY CASE WHEN indicador = 'superior_25_64' THEN -valor ELSE valor END) AS puesto,
        count(*) OVER (PARTITION BY indicador) AS n
    FROM ult
)
SELECT r.indicador, CAST(r.anio AS INTEGER) AS anio, r.valor, r.puesto, r.n, e.valor AS valor_espana
FROM rk r
LEFT JOIN mother.educacion_indicadores e ON e.nivel = 'pais' AND e.indicador = r.indicador AND e.anio = r.anio
WHERE r.cod = '${terr[0]?.cod}'
```

```sql edu_serie
SELECT c.anio, c.indicador, c.valor / 100 AS valor, e.valor / 100 AS valor_espana
FROM mother.educacion_indicadores c
JOIN mother.educacion_indicadores e ON e.nivel = 'pais' AND e.indicador = c.indicador AND e.anio = c.anio
WHERE c.nivel = 'ccaa' AND c.cod = '${terr[0]?.cod}' AND c.indicador IN ('abandono', 'superior_25_64', 'neet_15_29')
ORDER BY c.anio
```

{#if edu_ccaa.length > 0}

## Hezkuntza

<Grid cols=3>
    <KpiCard
        title="Eskola-uzte goiztiarra"
        value={edu_ccaa.find(d => d.indicador === 'abandono')?.valor}
        formattedValue="{formatNumber(edu_ccaa.find(d => d.indicador === 'abandono')?.valor, 1)} %"
        period="18-24 urtekoen artean, {edu_ccaa.find(d => d.indicador === 'abandono')?.anio} · Espainia: {formatNumber(edu_ccaa.find(d => d.indicador === 'abandono')?.valor_espana, 1)} % · postua: {edu_ccaa.find(d => d.indicador === 'abandono')?.puesto}/{edu_ccaa.find(d => d.indicador === 'abandono')?.n} (1 = txikiena)"
        direction="positive-down"
        source="Eurostat / BJI"
        href="/eu/sociedad/educacion"
        sparklineData={edu_serie.filter(d => d.indicador === 'abandono').map(d => d.valor)}
    />
    <KpiCard
        title="Goi-mailako ikasketak dituzten helduak"
        value={edu_ccaa.find(d => d.indicador === 'superior_25_64')?.valor}
        formattedValue="{formatNumber(edu_ccaa.find(d => d.indicador === 'superior_25_64')?.valor, 1)} %"
        period="25-64 urtekoen artean, {edu_ccaa.find(d => d.indicador === 'superior_25_64')?.anio} · Espainia: {formatNumber(edu_ccaa.find(d => d.indicador === 'superior_25_64')?.valor_espana, 1)} % · postua: {edu_ccaa.find(d => d.indicador === 'superior_25_64')?.puesto}/{edu_ccaa.find(d => d.indicador === 'superior_25_64')?.n}"
        direction="positive-up"
        source="Eurostat / BJI"
        href="/eu/sociedad/educacion"
        sparklineData={edu_serie.filter(d => d.indicador === 'superior_25_64').map(d => d.valor)}
    />
    <KpiCard
        title="Ez ikasten ez lanean ari ez diren gazteak"
        value={edu_ccaa.find(d => d.indicador === 'neet_15_29')?.valor}
        formattedValue="{formatNumber(edu_ccaa.find(d => d.indicador === 'neet_15_29')?.valor, 1)} %"
        period="15-29 urtekoen artean, {edu_ccaa.find(d => d.indicador === 'neet_15_29')?.anio} · Espainia: {formatNumber(edu_ccaa.find(d => d.indicador === 'neet_15_29')?.valor_espana, 1)} % · postua: {edu_ccaa.find(d => d.indicador === 'neet_15_29')?.puesto}/{edu_ccaa.find(d => d.indicador === 'neet_15_29')?.n} (1 = txikiena)"
        direction="positive-down"
        source="Eurostat / BJI"
        href="/eu/sociedad/educacion"
        sparklineData={edu_serie.filter(d => d.indicador === 'neet_15_29').map(d => d.valor)}
    />
</Grid>

<LineChart
    data={edu_serie.filter(d => d.indicador === 'abandono')}
    x=anio
    y={['valor', 'valor_espana']}
    yFmt=pct0
    xFmt="####"
    seriesLabels={{valor: terr[0]?.nombre, valor_espana: 'Espainia'}}
    colorPalette={['#b91c1c', '#94a3b8']}
    legend=true
    title="Hezkuntza eta prestakuntza goiz uztea (18-24 urtekoen %)"
/>

<p class="text-xs text-gray-500">Eurostatek harmonizatutako BJI (NUTS 2 eskualdeak). Eskualdeetako zifrak lagin txikietatik ateratzen dira eta urtetik urtera gorabeherak dituzte, batez ere Ceutan eta Melillan. Xehetasuna eta EBrekiko alderaketa: <a href="/eu/sociedad/educacion">Hezkuntza</a>.</p>

{/if}

```sql tur_ccaa
SELECT
    c.anio, c.pernoct_1000hab, c.ocupacion_hotel, c.pct_extranjeros_hotel, c.pernoct_hotel, c.pernoct_apart,
    c.turistas, c.turistas_por_hab, c.gasto_real_por_hab, c.anio_base,
    e.pernoct_1000hab AS pernoct_1000hab_espana,
    e.ocupacion_hotel AS ocupacion_hotel_espana,
    e.turistas_por_hab AS turistas_por_hab_espana
FROM mother.turismo_ccaa c
JOIN mother.turismo_ccaa e ON e.cod_ccaa = '00' AND e.anio = c.anio
WHERE c.cod_ccaa = '${terr[0]?.cod}' AND c.meses_hotel = 12 AND c.anio >= 2000
ORDER BY c.anio
```

```sql tur_ccaa_estacional
SELECT
    m.mes_num,
    ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'][CAST(m.mes_num AS INTEGER)] AS mes_nombre,
    m.pernoct_1000hab,
    e.pernoct_1000hab AS pernoct_1000hab_espana,
    CAST(m.anio AS INTEGER) AS anio
FROM mother.turismo_ccaa_mensual m
JOIN mother.turismo_ccaa_mensual e ON e.cod_ccaa = '00' AND e.mes = m.mes
WHERE m.cod_ccaa = '${terr[0]?.cod}'
  AND m.anio = (SELECT max(anio) FROM mother.turismo_ccaa WHERE meses_hotel = 12)
ORDER BY m.mes_num
```

```sql tur_vut_ccaa
SELECT
    v.periodo, v.viviendas, v.pct_viviendas, v.viviendas_1000hab, v.var_interanual,
    e.pct_viviendas AS pct_viviendas_espana,
    e.viviendas_1000hab AS viviendas_1000hab_espana,
    ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'][CAST(month(v.periodo) AS INTEGER)] || ' de ' || CAST(v.anio AS INTEGER) AS periodo_txt
FROM mother.turismo_viviendas v
JOIN mother.turismo_viviendas e ON e.nivel = 'pais' AND e.periodo = v.periodo
WHERE v.nivel = 'ccaa' AND v.cod = '${terr[0]?.cod}'
ORDER BY v.periodo
```

```sql tur_vut_mun_ccaa
SELECT v.municipio, v.poblacion, v.viviendas, v.pct_viviendas / 100 AS pct, v.viviendas_1000hab
FROM mother.turismo_viviendas_municipios v
WHERE v.cod_ccaa = '${terr[0]?.cod}'
  AND v.periodo = (SELECT max(periodo) FROM mother.turismo_viviendas_municipios)
  AND v.poblacion >= 1000
ORDER BY v.pct_viviendas DESC
LIMIT 10
```

{#if tur_ccaa.length > 0}

## Turismoa

<Grid cols=3>
    <KpiCard
        title="Gaualdi turistikoak"
        value={tur_ccaa.slice(-1)[0]?.pernoct_1000hab}
        formattedValue="{formatNumber(tur_ccaa.slice(-1)[0]?.pernoct_1000hab, 0)} 1.000 biz. bakoitzeko"
        period="hoteletan eta apartamentu turistikoetan, {urte(tur_ccaa.slice(-1)[0]?.anio, 'an')} · Espainia: {formatNumber(tur_ccaa.slice(-1)[0]?.pernoct_1000hab_espana, 0)}"
        source="INE / EOH, EOAP"
        href="/eu/economia/turismo"
        sparklineData={tur_ccaa.map(d => ({anio: d.anio, valor: d.pernoct_1000hab}))}
    />
    <KpiCard
        title="Hotel-okupazioa"
        value={tur_ccaa.slice(-1)[0]?.ocupacion_hotel}
        formattedValue="{formatNumber(tur_ccaa.slice(-1)[0]?.ocupacion_hotel, 1)} %"
        period="plazen gainean, {urte(tur_ccaa.slice(-1)[0]?.anio, 'ko')} batez bestekoa · Espainia: {formatNumber(tur_ccaa.slice(-1)[0]?.ocupacion_hotel_espana, 1)} %"
        source="INE / EOH"
        sparklineData={tur_ccaa.filter(d => d.ocupacion_hotel != null).map(d => ({anio: d.anio, valor: d.ocupacion_hotel}))}
    />
    {#if tur_vut_ccaa.length > 0}
    <KpiCard
        title="Etxebizitza turistikoak"
        value={tur_vut_ccaa.slice(-1)[0]?.pct_viviendas}
        formattedValue="Etxebizitzen {formatNumber(tur_vut_ccaa.slice(-1)[0]?.pct_viviendas, 2)} %"
        period="{formatNumber(tur_vut_ccaa.slice(-1)[0]?.viviendas_1000hab, 1)} 1.000 biz. bakoitzeko, {dataEu(tur_vut_ccaa.slice(-1)[0]?.periodo_txt)} · Espainia: {formatNumber(tur_vut_ccaa.slice(-1)[0]?.pct_viviendas_espana, 2)} %"
        source="INE (experimental)"
        sparklineData={tur_vut_ccaa.map(d => ({x: d.periodo, y: d.pct_viviendas}))}
    />
    {/if}
</Grid>

<LineChart
    data={tur_ccaa}
    x=anio
    y={['pernoct_1000hab', 'pernoct_1000hab_espana']}
    yFmt=num0
    xFmt="####"
    seriesLabels={{pernoct_1000hab: terr[0]?.nombre, pernoct_1000hab_espana: 'Espainia'}}
    colorPalette={['#0f766e', '#94a3b8']}
    legend=true
    yAxisTitle="1.000 biztanleko"
    title="Gaualdiak hoteletan eta apartamentu turistikoetan 1.000 biztanleko"
/>

<BarChart
    data={tur_ccaa_estacional}
    x=mes_nombre
    y={['pernoct_1000hab', 'pernoct_1000hab_espana']}
    type=grouped
    sort=false
    yFmt=num0
    seriesLabels={{pernoct_1000hab: terr[0]?.nombre, pernoct_1000hab_espana: 'Espainia'}}
    colorPalette={['#0f766e', '#94a3b8']}
    title="Urtaroko aldakortasuna: gaualdiak 1.000 biztanleko, {urte(tur_ccaa_estacional[0]?.anio, 'ko')} hilabete bakoitzean"
/>

<p class="text-xs text-gray-500">{formatNumber(tur_ccaa.slice(-1)[0]?.pernoct_hotel, 0)} gau hoteletan {urte(tur_ccaa.slice(-1)[0]?.anio, 'an')}; bidaiarien {formatNumber(tur_ccaa.slice(-1)[0]?.pct_extranjeros_hotel, 1)} % atzerrian bizi zen (INEren Hotel-okupazioaren Inkesta eta Apartamentu Turistikoetako Okupazio Inkesta; ez dituzte etxebizitza turistikoak barne hartzen).{#if tur_ccaa.slice(-1)[0]?.turistas_por_hab != null} {formatNumber(tur_ccaa.slice(-1)[0]?.turistas_por_hab, 1)} nazioarteko turista iritsi ziren biztanleko (Espainia: {formatNumber(tur_ccaa.slice(-1)[0]?.turistas_por_hab_espana, 1)}), eta {formatNumber(tur_ccaa.slice(-1)[0]?.gasto_real_por_hab, 0)} € gastatu zituzten biztanleko, {urte(tur_ccaa.slice(-1)[0]?.anio_base, 'ko')} eurotan (FRONTUR eta EGATUR).{/if} Xehetasun gehiago: <a href="/eu/economia/turismo">Turismoa</a>.</p>

{#if tur_vut_mun_ccaa.length > 0}

<BarChart
    data={tur_vut_mun_ccaa}
    x=municipio
    y=pct
    swapXY=true
    yFmt=pct1
    fillColor="#a21caf"
    title="Etxebizitza turistiko gehien dituzten udalerriak (etxebizitza guztien %; 1.000 biz. edo gehiagoko udalerriak)"
/>

{/if}

{/if}

```sql empresas_ccaa
SELECT
    e.empresas,
    e.empresas_1000hab,
    es.empresas_1000hab AS empresas_1000hab_espana,
    CAST(e.anio AS INTEGER) AS anio,
    (SELECT count(*) + 1 FROM mother.empresas_dirce_territorio o
      WHERE o.nivel = 'ccaa' AND o.anio = e.anio AND o.empresas_1000hab > e.empresas_1000hab) AS puesto
FROM mother.empresas_dirce_territorio e
JOIN mother.empresas_dirce_territorio es ON es.nivel = 'pais' AND es.anio = e.anio
WHERE e.nivel = 'ccaa' AND e.cod = '${terr[0]?.cod}'
  AND e.anio = (SELECT max(anio) FROM mother.empresas_dirce_territorio)
```

```sql empresas_ccaa_serie
SELECT CAST(e.anio AS INTEGER) AS anio, e.empresas_1000hab AS valor, es.empresas_1000hab AS valor_espana
FROM mother.empresas_dirce_territorio e
JOIN mother.empresas_dirce_territorio es ON es.nivel = 'pais' AND es.anio = e.anio
WHERE e.nivel = 'ccaa' AND e.cod = '${terr[0]?.cod}'
ORDER BY e.anio
```

```sql empresas_soc
SELECT
    s.constituidas_100k,
    s.disueltas_100k,
    es.constituidas_100k AS constituidas_100k_espana,
    s.constituidas,
    CAST(s.anio AS INTEGER) AS anio
FROM mother.empresas_sociedades_anual s
JOIN mother.empresas_sociedades_anual es ON es.cod = '00' AND es.anio = s.anio
WHERE s.cod = '${terr[0]?.cod}'
  AND s.anio = (SELECT max(anio) FROM mother.empresas_sociedades_anual)
```

```sql empresas_soc_serie
SELECT CAST(anio AS INTEGER) AS anio, constituidas_100k AS valor
FROM mother.empresas_sociedades_anual
WHERE cod = '${terr[0]?.cod}' AND constituidas_100k IS NOT NULL
ORDER BY anio
```

```sql empresas_aut
SELECT a.pct_cuenta_propia, es.pct_cuenta_propia AS pct_espana, CAST(a.anio AS INTEGER) AS anio
FROM mother.empresas_autonomos_anual a
JOIN mother.empresas_autonomos_anual es ON es.cod = '00' AND es.anio = a.anio
WHERE a.cod = '${terr[0]?.cod}'
ORDER BY a.anio
```

```sql empresas_id
SELECT i.pct_pib, i.eur_hab_real, i.investigadores_1000ocup, es.pct_pib AS pct_pib_espana,
    CAST(i.anio AS INTEGER) AS anio, CAST(i.anio_euros AS INTEGER) AS anio_euros
FROM mother.empresas_id_ccaa i
JOIN mother.empresas_id_ccaa es ON es.cod = '00' AND es.anio = i.anio AND es.sector = 'Total'
WHERE i.cod = '${terr[0]?.cod}' AND i.sector = 'Total' AND i.pct_pib IS NOT NULL
ORDER BY i.anio
```

{#if empresas_ccaa.length > 0}

## Enpresak

<Grid cols=4>
    <KpiCard
        title="Enpresak 1.000 biztanleko"
        value={empresas_ccaa[0]?.empresas_1000hab}
        formattedValue={formatNumber(empresas_ccaa[0]?.empresas_1000hab, 1)}
        period="Espainia: {formatNumber(empresas_ccaa[0]?.empresas_1000hab_espana, 1)} · postua: {empresas_ccaa[0]?.puesto}/19 · {formatNumber(empresas_ccaa[0]?.empresas, 0)} enpresa {urte(empresas_ccaa[0]?.anio, 'ko')} urtarrilaren 1ean"
        source="INE / DIRCE"
        sparklineData={empresas_ccaa_serie.map(d => d.valor)}
    />
    <KpiCard
        title="Sortutako sozietateak 100.000 biz. bakoitzeko"
        value={empresas_soc[0]?.constituidas_100k}
        formattedValue={formatNumber(empresas_soc[0]?.constituidas_100k, 0)}
        period="{urte(empresas_soc[0]?.anio, 'an')} · Espainia: {formatNumber(empresas_soc[0]?.constituidas_100k_espana, 0)} · desegindakoak: {formatNumber(empresas_soc[0]?.disueltas_100k, 0)}"
        source="INE / Merkataritza Sozietateak"
        sparklineData={empresas_soc_serie.map(d => d.valor)}
    />
    <KpiCard
        title="Autonomoak"
        value={empresas_aut.slice(-1)[0]?.pct_cuenta_propia}
        formattedValue="{formatNumber(empresas_aut.slice(-1)[0]?.pct_cuenta_propia, 1)} %"
        period="landunen artean, beren kontura lan egiten dutenak ({empresas_aut.slice(-1)[0]?.anio}) · Espainia: {formatNumber(empresas_aut.slice(-1)[0]?.pct_espana, 1)} %"
        source="INE / BJI"
        sparklineData={empresas_aut.map(d => d.pct_cuenta_propia)}
    />
    <KpiCard
        title="I+G gastua"
        value={empresas_id.slice(-1)[0]?.pct_pib}
        formattedValue="BPGaren {formatNumber(empresas_id.slice(-1)[0]?.pct_pib, 2)} %"
        period="{urte(empresas_id.slice(-1)[0]?.anio, 'an')} · Espainia: {formatNumber(empresas_id.slice(-1)[0]?.pct_pib_espana, 2)} % · {formatNumber(empresas_id.slice(-1)[0]?.eur_hab_real, 0)} € biztanleko ({urte(empresas_id.slice(-1)[0]?.anio_euros, 'ko')} eurotan)"
        source="Eurostat / INE"
        sparklineData={empresas_id.map(d => d.pct_pib)}
    />
</Grid>

<LineChart
    data={empresas_ccaa_serie}
    x=anio
    y={['valor', 'valor_espana']}
    xFmt='0'
    yFmt='0.0'
    seriesLabels={{valor: terr[0]?.nombre, valor_espana: 'Espainia'}}
    colorPalette={['#1d4ed8', '#94a3b8']}
    startingAtZero={false}
    yAxisTitle="1.000 biztanleko"
    title="Enpresa aktiboak 1.000 biztanleko"
/>

<p class="text-xs text-gray-500">Urtarrilaren 1eko enpresa aktiboak, Enpresen Direktorio Zentralaren arabera, autonomoak barne, egoitza duten erkidegoan zenbatuta. 2023an, INE ekonomikoki aktiboak diren enpresak soilik zenbatzen hasi zen, eta horrek azaltzen du urte horretako jaitsiera. Datu gehiago: <a href="/eu/economia/empresas">Enpresak, ekintzailetza eta I+G</a>.</p>

{/if}

```sql san_espera
SELECT l.fecha, l.tipo, l.tasa_1000, l.dias_medio, l.pct_espera_larga,
    CASE WHEN l.corte = 'junio' THEN '30 de junio de ' ELSE '31 de diciembre de ' END || CAST(l.anio AS INTEGER) AS fecha_txt,
    e.dias_medio AS dias_espana, e.tasa_1000 AS tasa_espana, e.pct_espera_larga AS pct_espana
FROM mother.sanidad_listas_espera l
LEFT JOIN mother.sanidad_listas_espera e ON e.nivel = 'pais' AND e.fecha = l.fecha AND e.tipo = l.tipo
WHERE l.nivel = 'ccaa' AND l.cod = '${terr[0]?.cod}'
ORDER BY l.fecha
```

```sql san_espera_dias
SELECT fecha, 'Operación · ' || '${terr[0]?.nombre}' AS serie, dias_medio FROM ${san_espera} WHERE tipo = 'quirurgica'
UNION ALL
SELECT fecha, 'Operación · España', dias_espana FROM ${san_espera} WHERE tipo = 'quirurgica'
UNION ALL
SELECT fecha, 'Especialista · ' || '${terr[0]?.nombre}', dias_medio FROM ${san_espera} WHERE tipo = 'consultas'
UNION ALL
SELECT fecha, 'Especialista · España', dias_espana FROM ${san_espera} WHERE tipo = 'consultas'
ORDER BY fecha
```

```sql san_espera_puesto
-- Puesto de la comunidad por espera media para operarse (1 = la que menos espera) en el último corte
WITH u AS (
    SELECT cod, dias_medio FROM mother.sanidad_listas_espera
    WHERE nivel = 'ccaa' AND tipo = 'quirurgica' AND fecha = (SELECT max(fecha) FROM mother.sanidad_listas_espera)
)
SELECT count(*) FILTER (WHERE dias_medio < (SELECT dias_medio FROM u WHERE cod = '${terr[0]?.cod}')) + 1 AS puesto, count(*) AS n
FROM u
```

```sql san_recursos
SELECT r.anio, r.recurso, r.por_1000, e.por_1000 AS por_1000_espana
FROM mother.sanidad_recursos_ccaa r
LEFT JOIN mother.sanidad_recursos_ccaa e ON e.nivel = 'pais' AND e.anio = r.anio AND e.recurso = r.recurso
WHERE r.nivel = 'ccaa' AND r.cod = '${terr[0]?.cod}'
ORDER BY r.anio
```

```sql san_gasto
SELECT g.anio, g.eur_hab_real, g.pct_pib, g.provisional, t.eur_hab_real AS eur_hab_real_ccaa
FROM mother.sanidad_gasto_ccaa g
LEFT JOIN mother.sanidad_gasto_ccaa t ON t.nivel = 'total_ccaa' AND t.anio = g.anio
WHERE g.nivel = 'ccaa' AND g.cod = '${terr[0]?.cod}'
ORDER BY g.anio
```

```sql san_gasto_serie
SELECT anio, '${terr[0]?.nombre}' AS serie, eur_hab_real FROM ${san_gasto}
UNION ALL
SELECT anio, 'Conjunto de las comunidades', eur_hab_real_ccaa FROM ${san_gasto}
ORDER BY anio
```

## Osasuna

{#if san_espera.length > 0}

<Grid cols=4>
    <KpiCard
        title="Ebakuntza egiteko batez besteko itxaronaldia"
        value={san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.dias_medio}
        formattedValue="{formatNumber(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.dias_medio, 0)} egun"
        period="Espainia: {formatNumber(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.dias_espana, 0)} · postua: {san_espera_puesto[0]?.puesto}/{san_espera_puesto[0]?.n} (1 = itxaronaldi laburrena) · {dataEu(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.fecha_txt)}"
        direction="positive-down"
        source="Osasun Ministerioa (SISLE)"
        href="/eu/sociedad/salud#itxaron-zerrendak"
        sparklineData={san_espera.filter(d => d.tipo === 'quirurgica').map(d => ({valor: d.dias_medio}))}
    />
    <KpiCard
        title="Ebakuntzetarako itxarote-zerrenda"
        value={san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.tasa_1000}
        formattedValue="{formatNumber(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.tasa_1000, 1)} 1.000 biz. bakoitzeko"
        period="Espainia: {formatNumber(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.tasa_espana, 1)} · {formatNumber(san_espera.filter(d => d.tipo === 'quirurgica').slice(-1)[0]?.pct_espera_larga, 1)} % 6 hilabete baino gehiago daramatza"
        direction="positive-down"
        source="Osasun Ministerioa (SISLE)"
        sparklineData={san_espera.filter(d => d.tipo === 'quirurgica').map(d => ({valor: d.tasa_1000}))}
    />
    <KpiCard
        title="Espezialistarako batez besteko itxaronaldia"
        value={san_espera.filter(d => d.tipo === 'consultas').slice(-1)[0]?.dias_medio}
        formattedValue="{formatNumber(san_espera.filter(d => d.tipo === 'consultas').slice(-1)[0]?.dias_medio, 0)} egun"
        period="Espainia: {formatNumber(san_espera.filter(d => d.tipo === 'consultas').slice(-1)[0]?.dias_espana, 0)} · lehen kontsulta"
        direction="positive-down"
        source="Osasun Ministerioa (SISLE)"
        sparklineData={san_espera.filter(d => d.tipo === 'consultas').map(d => ({valor: d.dias_medio}))}
    />
    {#if san_gasto.length > 0}
    <KpiCard
        title="Osasun-gastu publikoa"
        value={san_gasto.slice(-1)[0]?.eur_hab_real}
        formattedValue="{formatNumber(san_gasto.slice(-1)[0]?.eur_hab_real, 0)} € biztanleko"
        period="erkidego guztiak: {formatNumber(san_gasto.slice(-1)[0]?.eur_hab_real_ccaa, 0)} € · {san_gasto.slice(-1)[0]?.anio}{san_gasto.slice(-1)[0]?.provisional ? ' (behin-behinekoa)' : ''} · {urte(base[0]?.anio_base, 'ko')} eurotan"
        source="Osasun Ministerioa (EGSP)"
        sparklineData={san_gasto.map(d => ({valor: d.eur_hab_real}))}
    />
    {:else if san_recursos.some(d => d.recurso === 'medicos' && d.por_1000 != null)}
    <KpiCard
        title="Medikuak"
        value={san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.por_1000}
        formattedValue="{formatNumber(san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.por_1000, 1)} 1.000 biz. bakoitzeko"
        period="Espainia: {formatNumber(san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.por_1000_espana, 1)} · {san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.anio}"
        source="Eurostat"
        sparklineData={san_recursos.filter(d => d.recurso === 'medicos').map(d => ({valor: d.por_1000}))}
    />
    {/if}
</Grid>

<Grid cols=2>
    <LineChart
        data={san_espera_dias}
        x=fecha
        y=dias_medio
        series=serie
        yFmt=num0
        legend=true
        colorPalette={['#0f766e', '#99f6e4', '#7c3aed', '#ddd6fe']}
        yAxisTitle="egunak"
        title="Batez besteko itxaronaldia osasun publikoan"
    />
    {#if san_gasto.length > 0}
    <LineChart
        data={san_gasto_serie}
        x=anio
        y=eur_hab_real
        series=serie
        xFmt="####"
        yFmt='#,##0" €"'
        legend=true
        colorPalette={['#0f766e', '#94a3b8']}
        yAxisTitle="euro biztanleko"
        title="Osasun-gastu publikoa biztanleko ({urte(base[0]?.anio_base, 'ko')} eurotan)"
    />
    {/if}
</Grid>

{#if san_recursos.some(d => d.recurso === 'medicos' && d.por_1000 != null)}
<p class="text-sm">
{terr[0]?.nombre} lurraldeak {formatNumber(san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.por_1000, 1)} mediku eta {formatNumber(san_recursos.filter(d => d.recurso === 'camas').slice(-1)[0]?.por_1000, 1)} ospitale-ohe ditu 1.000 biztanleko (Espainia: {formatNumber(san_recursos.filter(d => d.recurso === 'medicos').slice(-1)[0]?.por_1000_espana, 1)} eta {formatNumber(san_recursos.filter(d => d.recurso === 'camas').slice(-1)[0]?.por_1000_espana, 1)}; Eurostat, {san_recursos.slice(-1)[0]?.anio}). <a href="/eu/sociedad/salud#osasun-sistema">Ikusi Espainiako osasun-sistema</a>.
</p>
{/if}

<p class="text-xs text-gray-500">OANaren itxarote-zerrendak (SISLE-SNS): erkidego bakoitzak bere zenbaketa-irizpideekin ematen ditu datuak; beraz, erkidegoen arteko alderaketak orientagarriak dira. Osasun-gastu publikoa: erkidegoko osasun-zerbitzuaren gastua (Osasun Gastu Publikoaren Estatistika), inflazioa kenduta.</p>

{/if}

```sql elec
SELECT p.proceso, p.fecha, strftime(p.fecha, '%-d/%-m/%Y') AS fecha_txt,
    p.participacion, p.participacion AS valor, p.ganador_siglas, p.ganador_pct,
    p.segundo_siglas, p.segundo_pct, p.nep_votos, p.escanos, e.participacion AS participacion_espana
FROM mother.elecciones_participacion p
JOIN mother.elecciones_participacion e ON e.proceso = p.proceso AND e.nivel = 'pais'
WHERE p.nivel = 'ccaa' AND p.cod = '${terr[0]?.cod}' AND p.tipo = '02'
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
WHERE f.nivel = 'ccaa' AND f.cod = '${terr[0]?.cod}' AND f.tipo = '02'
  AND f.familia IN (SELECT familia FROM mother.elecciones_familias
      WHERE nivel = 'ccaa' AND cod = '${terr[0]?.cod}' AND tipo = '02' AND bloque <> 'Otros'
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
        period="bigarrena: {elec.slice(-1)[0]?.segundo_siglas} ({formatNumber(elec.slice(-1)[0]?.segundo_pct, 1)} %) · {formatNumber(elec.slice(-1)[0]?.escanos, 0)} eserleku jokoan"
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

- **[Gizarte Segurantza – Indarreko kotizazio-pentsioak AEka eta probintziaka](https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/EST24)**
- **INE**: [BJI](https://www.ine.es/jaxiT3/Tabla.htm?t=65349), [KPI](https://www.ine.es/jaxiT3/Tabla.htm?t=76140), [Bizi Baldintzei buruzko Inkesta](https://www.ine.es/jaxiT3/Tabla.htm?t=9963), [Errentaren Banaketaren Atlasa](https://www.ine.es/jaxiT3/Tabla.htm?t=30824), [Biztanleriaren Mugimendu Naturala](https://www.ine.es/jaxiT3/Tabla.htm?t=6524), [Hotel-okupazioaren Inkesta](https://www.ine.es/jaxiT3/Tabla.htm?t=2074); **SEPE**: erregistratutako langabezia; **Etxebizitza Ministerioa**: tasatutako balioa eta SERPAVI; **Eurostat**: hezkuntza-adierazleak eskualdeka (NUTS 2).
- **[INE – Udalerrien biztanleria-zifra ofizialak (Udal Erroldak)](https://www.ine.es/jaxiT3/Tabla.htm?t=29005)**
- **[Ogasun Ministerioa – AEen aurrekontuen likidazioa](https://serviciostelematicosext.hacienda.gob.es/sgcief/publicacionliquidaciones/aspx/menuinicio.aspx)**: datu bateratuak; politiken araberako gastutik kendu egin dira toki-erakundeek zergetan duten partaidetza eta NPBko funtsak, autonomia-kontuetatik igaro besterik egiten ez dutenak.
- **[Espainiako Bankua – Buletin Estatistikoa, 13. kapitulua](https://www.bde.es/webbe/es/estadisticas/temas/administraciones-publicas.html)**: Gehiegizko Defizitaren Prozeduraren araberako zorra eta autonomia-erkidegoen finantzaketa-ahalmena/-beharra.
- **[Langileen Erregistro Zentrala – Administrazio Publikoen zerbitzuko langileen Buletin Estatistikoa](https://digital.gob.es/funcion-publica/dgfp/registro-central-personal/boletin.html)**: enplegatu publikoak administrazioaren eta lanpostuaren probintziaren arabera; **[INE – 2022ko Soldata Egituraren Inkesta](https://www.ine.es/jaxiT3/Tabla.htm?t=36887)**: soldata publikoak eta pribatuak.
- **[Instituto Geográfico Nacional (es-atlas bidez)](https://github.com/martgnz/es-atlas)**: udal-mugak (CC BY 4.0).

<LastRefreshed prefix="Datuak eguneratuta" />
