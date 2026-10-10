---
title: Alquiler de vivienda
description: "Alquiler mediano de la vivienda en España descontada la inflación, por comunidad, provincia y municipio, con los datos del IRPF del Sistema Estatal de Referencia del Precio del Alquiler y el índice del INE."
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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
SELECT a.cod, a.nombre AS comunidad, t.ruta, a.anio, a.alquiler_mes_mediana_real, a.alquiler_m2_mediana_real,
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
SELECT a.cod AS cod_prov, a.nombre AS provincia, t.ruta, a.alquiler_mes_mediana_real, a.alquiler_m2_mediana_real,
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

# 🔑 Alquiler

Cuánto se paga por alquilar una vivienda en España. Los datos salen de las **declaraciones del IRPF de los caseros** (Sistema Estatal de Referencia del Precio del Alquiler del Ministerio de Vivienda): son rentas de contratos de vivienda habitual en vigor, no los precios de los anuncios, que suelen ser más altos. Las cifras son de pisos (vivienda colectiva) y están **descontada la inflación**, en euros de {espana[0]?.anio_base}.

<Grid cols=4>
    <KpiCard
        title="Alquiler mediano de un piso"
        value={espana.slice(-1)[0]?.alquiler_mes_mediana_real}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.alquiler_mes_mediana_real, 0)} €/mes"
        period="{espana.slice(-1)[0]?.anio} · {formatNumber(espana.slice(-1)[0]?.alquiler_mes_mediana, 0)} € en euros de ese año"
        change={espana.slice(-1)[0]?.variacion_real?.toFixed(1)}
        changePeriod="real vs año anterior"
        source="Ministerio de Vivienda (SERPAVI)"
        sparklineData={espana.map(d => ({...d, y: d.alquiler_mes_mediana_real}))}
    />
    <KpiCard
        title="Por metro cuadrado"
        value={espana.slice(-1)[0]?.alquiler_m2_mediana_real}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.alquiler_m2_mediana_real, 2)} €/m² al mes"
        period="superficie mediana del piso alquilado: {formatNumber(espana.slice(-1)[0]?.superficie_mediana, 0)} m²"
        source="Ministerio de Vivienda (SERPAVI)"
        sparklineData={espana.map(d => ({...d, y: d.alquiler_m2_mediana_real}))}
    />
    <KpiCard
        title="Pisos alquilados"
        value={espana.slice(-1)[0]?.alquiladas_1000}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.alquiladas_1000, 1)} por 1.000 hab."
        period="declarados en el IRPF en {espana.slice(-1)[0]?.anio} · {formatCompact(espana.slice(-1)[0]?.viviendas_alquiladas, 1)} en total"
        source="Ministerio de Vivienda (SERPAVI)"
        sparklineData={espana.map(d => ({...d, y: d.alquiladas_1000}))}
    />
    <KpiCard
        title="Parte del salario"
        value={esfuerzo.slice(-1)[0]?.pct_alquiler}
        formattedValue="{formatNumber(esfuerzo.slice(-1)[0]?.pct_alquiler, 1)} %"
        period="del salario bruto medio se va en el alquiler mediano, {esfuerzo.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="Ministerio de Vivienda / INE"
        href="/vivienda/esfuerzo"
        sparklineData={esfuerzo.map(d => ({...d, y: d.pct_alquiler}))}
    />
</Grid>

## Con y sin inflación

Entre {hitos[0]?.anio_ini} y {hitos[0]?.anio_fin} el alquiler mediano subió un {formatNumber(hitos[0]?.var_nominal, 0)} % en euros de cada año; descontada la inflación, {#if hitos[0]?.var_real < 0}bajó un {formatNumber(-hitos[0]?.var_real, 1)} %{:else}subió un {formatNumber(hitos[0]?.var_real, 1)} %{/if}. El mínimo real fue en {hitos[0]?.anio_min}. En esos años el número de pisos cuyo alquiler se declara en el IRPF, por habitante, se multiplicó por {formatNumber(hitos[0]?.veces_alquiladas, 1)}.

<LineChart
    data={espana_largo}
    x=anio
    y=alquiler
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ al mes"
    startingAtZero={false}
    title="Alquiler mensual mediano de un piso en España"
/>

<LineChart
    data={percentiles}
    x=anio
    y=alquiler
    series=tramo
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ al mes (reales)"
    title="Reparto de los alquileres: cuartiles, en euros de {espana[0]?.anio_base}"
/>

España no aparece como tal en el fichero del Ministerio: la cifra nacional es la media de las medianas de cada comunidad ponderada por el número de pisos alquilados.

El INE publica además un índice que sigue la renta de los mismos contratos año a año (sin País Vasco ni Navarra):

<LineChart
    data={ipva}
    x=anio
    y=indice_real
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="índice real, 2015 = 100"
    startingAtZero={false}
    title="Índice de Precios de Vivienda en Alquiler descontada la inflación (INE, 2015 = 100)"
/>

## Por comunidad

Alquiler mediano de un piso en {ccaa[0]?.anio}, en euros de {espana[0]?.anio_base}.

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio de Vivienda"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'alquiler_mes_mediana_real', title: '€/mes', fmt: '#,##0'},
        {id: 'alquiler_m2_mediana_real', title: '€/m²', fmt: '0.00'},
        {id: 'pct_alquiler', title: '% del salario', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidad" />
    <Column id=alquiler_mes_mediana_real title="€/mes (real)" fmt='#,##0' />
    <Column id=alquiler_m2_mediana_real title="€/m² (real)" fmt='0.00' />
    <Column id=alquiler_var_5a title="Var. real en 5 años %" fmt='0.0' contentType=delta />
    <Column id=pct_alquiler title="% del salario" fmt='0.0' />
    <Column id=alquiladas_1000 title="Pisos alquilados por 1.000 hab." fmt='0.0' />
</DataTable>

## Por provincia

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio de Vivienda"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'alquiler_mes_mediana_real', title: '€/mes', fmt: '#,##0'},
        {id: 'alquiler_var_5a', title: 'Var. real en 5 años (%)', fmt: '0.0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Provincia" />
    <Column id=alquiler_mes_mediana_real title="€/mes (real)" fmt='#,##0' />
    <Column id=alquiler_m2_mediana_real title="€/m² (real)" fmt='0.00' />
    <Column id=alquiler_var_5a title="Var. real en 5 años %" fmt='0.0' contentType=delta />
    <Column id=alquiladas_1000 title="Pisos alquilados por 1.000 hab." fmt='0.0' />
</DataTable>

## Por municipio

Municipios de 20.000 habitantes o más con al menos 100 pisos alquilados declarados, {municipios[0]?.anio}.

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=alquiler_mes_mediana_real title="€/mes (real)" fmt='#,##0' />
    <Column id=alquiler_m2_mediana_real title="€/m² (real)" fmt='0.00' />
    <Column id=superficie_mediana title="m² medianos" fmt='0' />
    <Column id=variacion_real_5a title="Var. real en 5 años %" fmt='0.0' contentType=delta />
    <Column id=alquiladas_1000 title="Alquilados por 1.000 hab." fmt='0.0' />
</DataTable>

---

**Fuentes:** [Ministerio de Vivienda y Agenda Urbana, Sistema Estatal de Referencia del Precio del Alquiler de Vivienda](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi) (explotación de los modelos 100 del IRPF y del Catastro, 2011-2024; País Vasco y Navarra solo por comunidad) e [INE, Índice de Precios de Vivienda en Alquiler, tabla 59057](https://www.ine.es/jaxiT3/Tabla.htm?t=59057). Deflactados con el IPC general del INE (base 2025).
