---
title: Aluguer de vivenda
description: "Aluguer mediano da vivenda en España descontada a inflación, por comunidade, provincia e municipio, cos datos do IRPF do Sistema Estatal de Referencia do Prezo do Aluguer e o índice do INE."
i18n_origen: deee5f4dedc1
---

<script>
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
SELECT a.cod, a.nombre AS comunidad, '/gl' || t.ruta AS ruta, a.anio, a.alquiler_mes_mediana_real, a.alquiler_m2_mediana_real,
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
SELECT a.cod AS cod_prov, a.nombre AS provincia, '/gl' || t.ruta AS ruta, a.alquiler_mes_mediana_real, a.alquiler_m2_mediana_real,
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

# 🔑 Aluguer

Canto se paga por alugar unha vivenda en España. Os datos saen das **declaracións do IRPF dos arrendadores** (Sistema Estatal de Referencia do Prezo do Aluguer do Ministerio de Vivenda): son rendas de contratos de vivenda habitual en vigor, non os prezos dos anuncios, que adoitan ser máis altos. As cifras son de pisos (vivenda colectiva) e están **descontada a inflación**, en euros de {espana[0]?.anio_base}.

<Grid cols=4>
    <KpiCard
        title="Aluguer mediano dun piso"
        value={espana.slice(-1)[0]?.alquiler_mes_mediana_real}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.alquiler_mes_mediana_real, 0)} €/mes"
        period="{espana.slice(-1)[0]?.anio} · {formatNumber(espana.slice(-1)[0]?.alquiler_mes_mediana, 0)} € en euros dese ano"
        change={espana.slice(-1)[0]?.variacion_real?.toFixed(1)}
        changePeriod="real fronte ao ano anterior"
        source="Ministerio de Vivenda (SERPAVI)"
        sparklineData={espana.map(d => d.alquiler_mes_mediana_real)}
    />
    <KpiCard
        title="Por metro cadrado"
        value={espana.slice(-1)[0]?.alquiler_m2_mediana_real}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.alquiler_m2_mediana_real, 2)} €/m² ao mes"
        period="superficie mediana do piso alugado: {formatNumber(espana.slice(-1)[0]?.superficie_mediana, 0)} m²"
        source="Ministerio de Vivenda (SERPAVI)"
        sparklineData={espana.map(d => d.alquiler_m2_mediana_real)}
    />
    <KpiCard
        title="Pisos alugados"
        value={espana.slice(-1)[0]?.alquiladas_1000}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.alquiladas_1000, 1)} por 1.000 hab."
        period="declarados no IRPF en {espana.slice(-1)[0]?.anio} · {formatCompact(espana.slice(-1)[0]?.viviendas_alquiladas, 1)} en total"
        source="Ministerio de Vivenda (SERPAVI)"
        sparklineData={espana.map(d => d.alquiladas_1000)}
    />
    <KpiCard
        title="Parte do salario"
        value={esfuerzo.slice(-1)[0]?.pct_alquiler}
        formattedValue="{formatNumber(esfuerzo.slice(-1)[0]?.pct_alquiler, 1)} %"
        period="do salario bruto medio vai no aluguer mediano, {esfuerzo.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="Ministerio de Vivenda / INE"
        href="/gl/vivienda/esfuerzo"
        sparklineData={esfuerzo.map(d => d.pct_alquiler)}
    />
</Grid>

## Con e sen inflación

Entre {hitos[0]?.anio_ini} e {hitos[0]?.anio_fin} o aluguer mediano subiu un {formatNumber(hitos[0]?.var_nominal, 0)} % en euros de cada ano; descontada a inflación, {#if hitos[0]?.var_real < 0}baixou un {formatNumber(-hitos[0]?.var_real, 1)} %{:else}subiu un {formatNumber(hitos[0]?.var_real, 1)} %{/if}. O mínimo real foi en {hitos[0]?.anio_min}. Neses anos o número de pisos cuxo aluguer se declara no IRPF, por habitante, multiplicouse por {formatNumber(hitos[0]?.veces_alquiladas, 1)}.

<LineChart
    data={espana_largo}
    x=anio
    y=alquiler
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ ao mes"
    startingAtZero={false}
    title="Aluguer mensual mediano dun piso en España"
/>

<LineChart
    data={percentiles}
    x=anio
    y=alquiler
    series=tramo
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ ao mes (reais)"
    title="Reparto dos alugueres: cuartís, en euros de {espana[0]?.anio_base}"
/>

España non aparece como tal no ficheiro do Ministerio: a cifra nacional é a media das medianas de cada comunidade ponderada polo número de pisos alugados.

O INE publica ademais un índice que segue a renda dos mesmos contratos ano a ano (sen o País Vasco nin Navarra):

<LineChart
    data={ipva}
    x=anio
    y=indice_real
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="índice real, 2015 = 100"
    startingAtZero={false}
    title="Índice de Prezos de Vivenda en Aluguer descontada a inflación (INE, 2015 = 100)"
/>

## Por comunidade

Aluguer mediano dun piso en {ccaa[0]?.anio}, en euros de {espana[0]?.anio_base}.

<AreaMap
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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio de Vivenda"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'alquiler_mes_mediana_real', title: '€/mes', fmt: '#,##0'},
        {id: 'alquiler_m2_mediana_real', title: '€/m²', fmt: '0.00'},
        {id: 'pct_alquiler', title: '% do salario', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidade" />
    <Column id=alquiler_mes_mediana_real title="€/mes (real)" fmt='#,##0' />
    <Column id=alquiler_m2_mediana_real title="€/m² (real)" fmt='0.00' />
    <Column id=alquiler_var_5a title="Var. real en 5 anos %" fmt='0.0' contentType=delta />
    <Column id=pct_alquiler title="% do salario" fmt='0.0' />
    <Column id=alquiladas_1000 title="Pisos alugados por 1.000 hab." fmt='0.0' />
</DataTable>

## Por provincia

<AreaMap
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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio de Vivenda"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'alquiler_mes_mediana_real', title: '€/mes', fmt: '#,##0'},
        {id: 'alquiler_var_5a', title: 'Var. real en 5 anos (%)', fmt: '0.0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Provincia" />
    <Column id=alquiler_mes_mediana_real title="€/mes (real)" fmt='#,##0' />
    <Column id=alquiler_m2_mediana_real title="€/m² (real)" fmt='0.00' />
    <Column id=alquiler_var_5a title="Var. real en 5 anos %" fmt='0.0' contentType=delta />
    <Column id=alquiladas_1000 title="Pisos alugados por 1.000 hab." fmt='0.0' />
</DataTable>

## Por municipio

Municipios de 20.000 habitantes ou máis con polo menos 100 pisos alugados declarados, {municipios[0]?.anio}.

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=alquiler_mes_mediana_real title="€/mes (real)" fmt='#,##0' />
    <Column id=alquiler_m2_mediana_real title="€/m² (real)" fmt='0.00' />
    <Column id=superficie_mediana title="m² medianos" fmt='0' />
    <Column id=variacion_real_5a title="Var. real en 5 anos %" fmt='0.0' contentType=delta />
    <Column id=alquiladas_1000 title="Alugados por 1.000 hab." fmt='0.0' />
</DataTable>

---

**Fontes:** [Ministerio de Vivenda e Axenda Urbana, Sistema Estatal de Referencia do Prezo do Aluguer de Vivenda](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi) (explotación dos modelos 100 do IRPF e do Catastro, 2011-2024; País Vasco e Navarra só por comunidade) e [INE, Índice de Prezos de Vivenda en Aluguer, táboa 59057](https://www.ine.es/jaxiT3/Tabla.htm?t=59057). Deflactados co IPC xeral do INE (base 2025).
