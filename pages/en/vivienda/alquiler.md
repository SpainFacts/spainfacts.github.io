---
title: Housing rents
description: "Median housing rent in Spain adjusted for inflation, by region, province and municipality, using income tax data from the State Rental Price Reference System and the INE index."
i18n_origen: 851526a83095
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT anio, alquiler_mes_mediana, alquiler_mes_mediana_real, alquiler_m2_mediana, alquiler_m2_mediana_real,
       alquiler_mes_p25_real, alquiler_mes_p75_real, superficie_mediana, viviendas_alquiladas, alquiladas_1000, variacion_real, anio_base
FROM mother.vivienda_alquiler
WHERE nivel = 'pais' AND tipologia = 'Colectiva'
ORDER BY anio
```

```sql espana_largo
SELECT anio, 'Descontada la inflación' AS serie, alquiler_mes_mediana_real AS alquiler FROM ${espana}
UNION ALL
SELECT anio, 'Sin descontar (euros de cada año)' AS serie, alquiler_mes_mediana AS alquiler FROM ${espana}
ORDER BY anio, serie
```

```sql percentiles
SELECT anio, 'El 25 % más barato paga menos de' AS tramo, alquiler_mes_p25_real AS alquiler FROM ${espana}
UNION ALL
SELECT anio, 'Mediana' AS tramo, alquiler_mes_mediana_real AS alquiler FROM ${espana}
UNION ALL
SELECT anio, 'El 25 % más caro paga más de' AS tramo, alquiler_mes_p75_real AS alquiler FROM ${espana}
ORDER BY anio, tramo
```

```sql hitos
SELECT
    min(anio) AS anio_ini,
    max(anio) AS anio_fin,
    100 * (arg_max(alquiler_mes_mediana_real, anio) / arg_min(alquiler_mes_mediana_real, anio) - 1) AS var_real,
    100 * (arg_max(alquiler_mes_mediana, anio) / arg_min(alquiler_mes_mediana, anio) - 1) AS var_nominal,
    arg_max(alquiladas_1000, anio) / arg_min(alquiladas_1000, anio) AS veces_alquiladas,
    arg_min(alquiler_mes_mediana_real, alquiler_mes_mediana_real) AS min_real,
    arg_min(anio, alquiler_mes_mediana_real) AS anio_min
FROM ${espana}
```

```sql esfuerzo
SELECT anio, pct_alquiler FROM mother.vivienda_esfuerzo WHERE nivel = 'pais' AND pct_alquiler IS NOT NULL ORDER BY anio
```

```sql ipva
SELECT anio, indice_real, variacion_real, variacion_nominal FROM mother.vivienda_ipva WHERE nivel = 'pais' ORDER BY anio
```

```sql ccaa
SELECT a.cod, a.nombre AS comunidad, '/en' || t.ruta AS ruta, a.anio, a.alquiler_mes_mediana_real, a.alquiler_m2_mediana_real,
       a.superficie_mediana, a.alquiladas_1000, r.alquiler_var_5a, e.pct_alquiler
FROM mother.vivienda_alquiler a
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = a.cod
LEFT JOIN mother.vivienda_resumen_territorios r ON r.nivel = 'ccaa' AND r.cod = a.cod
LEFT JOIN mother.vivienda_esfuerzo e ON e.nivel = 'ccaa' AND e.cod = a.cod AND e.anio = a.anio
WHERE a.nivel = 'ccaa' AND a.tipologia = 'Colectiva'
  AND a.anio = (SELECT max(anio) FROM mother.vivienda_alquiler)
ORDER BY a.alquiler_mes_mediana_real DESC
```

```sql provincias
SELECT a.cod AS cod_prov, a.nombre AS provincia, '/en' || t.ruta AS ruta, a.alquiler_mes_mediana_real, a.alquiler_m2_mediana_real,
       a.alquiladas_1000, r.alquiler_var_5a
FROM mother.vivienda_alquiler a
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = a.cod
LEFT JOIN mother.vivienda_resumen_territorios r ON r.nivel = 'provincia' AND r.cod = a.cod
WHERE a.nivel = 'provincia' AND a.tipologia = 'Colectiva'
  AND a.anio = (SELECT max(anio) FROM mother.vivienda_alquiler)
ORDER BY a.alquiler_mes_mediana_real DESC
```

```sql municipios
SELECT m.municipio, p.nombre AS provincia, m.poblacion, m.alquiler_mes_mediana_real, m.alquiler_m2_mediana_real,
       m.superficie_mediana, m.alquiladas_1000, m.variacion_real_5a, m.anio
FROM mother.vivienda_alquiler_municipios m
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
WHERE m.anio = (SELECT max(anio) FROM mother.vivienda_alquiler_municipios)
ORDER BY m.alquiler_mes_mediana_real DESC
```

# 🔑 Rent

How much it costs to rent a home in Spain. The data come from **landlords' income tax returns** (the Ministry of Housing's State Rental Price Reference System): they are rents from current leases on main residences, not asking prices in listings, which tend to be higher. The figures are for flats (multi-family housing) and are **adjusted for inflation**, in {espana[0]?.anio_base} euros.

<Grid cols=4>
    <KpiCard
        title="Median rent for a flat"
        value={espana.slice(-1)[0]?.alquiler_mes_mediana_real}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.alquiler_mes_mediana_real, 0)} €/month"
        period="{espana.slice(-1)[0]?.anio} · {formatNumber(espana.slice(-1)[0]?.alquiler_mes_mediana, 0)} € in that year's euros"
        change={espana.slice(-1)[0]?.variacion_real?.toFixed(1)}
        changePeriod="real vs previous year"
        source="Ministry of Housing (SERPAVI)"
        sparklineData={espana.map(d => ({...d, y: d.alquiler_mes_mediana_real}))}
    />
    <KpiCard
        title="Per square metre"
        value={espana.slice(-1)[0]?.alquiler_m2_mediana_real}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.alquiler_m2_mediana_real, 2)} €/m² per month"
        period="median floor area of rented flats: {formatNumber(espana.slice(-1)[0]?.superficie_mediana, 0)} m²"
        source="Ministry of Housing (SERPAVI)"
        sparklineData={espana.map(d => ({...d, y: d.alquiler_m2_mediana_real}))}
    />
    <KpiCard
        title="Rented flats"
        value={espana.slice(-1)[0]?.alquiladas_1000}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.alquiladas_1000, 1)} per 1,000 inhab."
        period="declared in income tax returns in {espana.slice(-1)[0]?.anio} · {formatCompact(espana.slice(-1)[0]?.viviendas_alquiladas, 1)} in total"
        source="Ministry of Housing (SERPAVI)"
        sparklineData={espana.map(d => ({...d, y: d.alquiladas_1000}))}
    />
    <KpiCard
        title="Share of salary"
        value={esfuerzo.slice(-1)[0]?.pct_alquiler}
        formattedValue="{formatNumber(esfuerzo.slice(-1)[0]?.pct_alquiler, 1)} %"
        period="of the average gross salary goes on the median rent, {esfuerzo.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="Ministry of Housing / INE"
        href="/en/vivienda/esfuerzo"
        sparklineData={esfuerzo.map(d => ({...d, y: d.pct_alquiler}))}
    />
</Grid>

## With and without inflation

Between {hitos[0]?.anio_ini} and {hitos[0]?.anio_fin} the median rent rose by {formatNumber(hitos[0]?.var_nominal, 0)} % in euros of each year; adjusted for inflation, it {#if hitos[0]?.var_real < 0}fell by {formatNumber(-hitos[0]?.var_real, 1)} %{:else}rose by {formatNumber(hitos[0]?.var_real, 1)} %{/if}. The real low was in {hitos[0]?.anio_min}. Over those years the number of flats whose rent is declared in income tax returns, per inhabitant, multiplied by {formatNumber(hitos[0]?.veces_alquiladas, 1)}.

<LineChart
    data={espana_largo}
    x=anio
    y=alquiler
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per month"
    startingAtZero={false}
    title="Median monthly rent for a flat in Spain"
/>

<LineChart
    data={percentiles}
    x=anio
    y=alquiler
    series=tramo
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per month (real)"
    title="Distribution of rents: quartiles, in {espana[0]?.anio_base} euros"
/>

Spain as a whole does not appear in the Ministry's file: the national figure is the average of each region's median weighted by the number of rented flats.

The INE also publishes an index that tracks the rent of the same leases year by year (excluding the Basque Country and Navarre):

<LineChart
    data={ipva}
    x=anio
    y=indice_real
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="real index, 2015 = 100"
    startingAtZero={false}
    title="Housing Rental Price Index adjusted for inflation (INE, 2015 = 100)"
/>

## By region

Median rent for a flat in {ccaa[0]?.anio}, in {espana[0]?.anio_base} euros.

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="alquiler_mes_mediana_real"
    valueFmt='#,##0" €"'
    link="ruta"
    colorPalette={['#ede9fe', '#8b5cf6', '#4c1d95']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: Ministry of Housing"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'alquiler_mes_mediana_real', title: '€/month', fmt: '#,##0'},
        {id: 'alquiler_m2_mediana_real', title: '€/m²', fmt: '0.00'},
        {id: 'pct_alquiler', title: '% of salary', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=alquiler_mes_mediana_real title="€/month (real)" fmt='#,##0' />
    <Column id=alquiler_m2_mediana_real title="€/m² (real)" fmt='0.00' />
    <Column id=alquiler_var_5a title="Real chg. over 5 years %" fmt='0.0' contentType=delta />
    <Column id=pct_alquiler title="% of salary" fmt='0.0' />
    <Column id=alquiladas_1000 title="Rented flats per 1,000 inhab." fmt='0.0' />
</DataTable>

## By province

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="alquiler_mes_mediana_real"
    valueFmt='#,##0" €"'
    link="ruta"
    colorPalette={['#ede9fe', '#8b5cf6', '#4c1d95']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: Ministry of Housing"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'alquiler_mes_mediana_real', title: '€/month', fmt: '#,##0'},
        {id: 'alquiler_var_5a', title: 'Real chg. over 5 years (%)', fmt: '0.0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Province" />
    <Column id=alquiler_mes_mediana_real title="€/month (real)" fmt='#,##0' />
    <Column id=alquiler_m2_mediana_real title="€/m² (real)" fmt='0.00' />
    <Column id=alquiler_var_5a title="Real chg. over 5 years %" fmt='0.0' contentType=delta />
    <Column id=alquiladas_1000 title="Rented flats per 1,000 inhab." fmt='0.0' />
</DataTable>

## By municipality

Municipalities with 20,000 inhabitants or more and at least 100 declared rented flats, {municipios[0]?.anio}.

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipality" />
    <Column id=provincia title="Province" />
    <Column id=alquiler_mes_mediana_real title="€/month (real)" fmt='#,##0' />
    <Column id=alquiler_m2_mediana_real title="€/m² (real)" fmt='0.00' />
    <Column id=superficie_mediana title="Median m²" fmt='0' />
    <Column id=variacion_real_5a title="Real chg. over 5 years %" fmt='0.0' contentType=delta />
    <Column id=alquiladas_1000 title="Rented per 1,000 inhab." fmt='0.0' />
</DataTable>

---

**Sources:** [Ministry of Housing and Urban Agenda, State Rental Price Reference System (SERPAVI)](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi) (based on Form 100 income tax returns and the Cadastre, 2011-2024; Basque Country and Navarre by region only) and [INE, Housing Rental Price Index, table 59057](https://www.ine.es/jaxiT3/Tabla.htm?t=59057). Deflated with the INE general CPI (base 2025).
