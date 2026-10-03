---
title: Lloguer d'habitatge
description: "Lloguer medià de l'habitatge a Espanya descomptada la inflació, per comunitat, província i municipi, amb les dades de l'IRPF del Sistema Estatal de Referència del Preu del Lloguer i l'índex de l'INE."
i18n_origen: 15b55dba3f41
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
SELECT a.cod, a.nombre AS comunidad, '/ca' || t.ruta AS ruta, a.anio, a.alquiler_mes_mediana_real, a.alquiler_m2_mediana_real,
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
SELECT a.cod AS cod_prov, a.nombre AS provincia, '/ca' || t.ruta AS ruta, a.alquiler_mes_mediana_real, a.alquiler_m2_mediana_real,
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

# 🔑 Lloguer

Quant es paga per llogar un habitatge a Espanya. Les dades surten de les **declaracions de l'IRPF dels propietaris** (Sistema Estatal de Referència del Preu del Lloguer del Ministeri d'Habitatge): són rendes de contractes d'habitatge habitual en vigor, no els preus dels anuncis, que solen ser més alts. Les xifres són de pisos (habitatge col·lectiu) i estan **descomptada la inflació**, en euros de {espana[0]?.anio_base}.

<Grid cols=4>
    <KpiCard
        title="Lloguer medià d'un pis"
        value={espana.slice(-1)[0]?.alquiler_mes_mediana_real}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.alquiler_mes_mediana_real, 0)} €/mes"
        period="{espana.slice(-1)[0]?.anio} · {formatNumber(espana.slice(-1)[0]?.alquiler_mes_mediana, 0)} € en euros d'aquell any"
        change={espana.slice(-1)[0]?.variacion_real?.toFixed(1)}
        changePeriod="real vs. any anterior"
        source="Ministeri d'Habitatge (SERPAVI)"
        sparklineData={espana.map(d => d.alquiler_mes_mediana_real)}
    />
    <KpiCard
        title="Per metre quadrat"
        value={espana.slice(-1)[0]?.alquiler_m2_mediana_real}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.alquiler_m2_mediana_real, 2)} €/m² al mes"
        period="superfície mediana del pis llogat: {formatNumber(espana.slice(-1)[0]?.superficie_mediana, 0)} m²"
        source="Ministeri d'Habitatge (SERPAVI)"
        sparklineData={espana.map(d => d.alquiler_m2_mediana_real)}
    />
    <KpiCard
        title="Pisos llogats"
        value={espana.slice(-1)[0]?.alquiladas_1000}
        formattedValue="{formatNumber(espana.slice(-1)[0]?.alquiladas_1000, 1)} per 1.000 hab."
        period="declarats a l'IRPF el {espana.slice(-1)[0]?.anio} · {formatCompact(espana.slice(-1)[0]?.viviendas_alquiladas, 1)} en total"
        source="Ministeri d'Habitatge (SERPAVI)"
        sparklineData={espana.map(d => d.alquiladas_1000)}
    />
    <KpiCard
        title="Part del salari"
        value={esfuerzo.slice(-1)[0]?.pct_alquiler}
        formattedValue="{formatNumber(esfuerzo.slice(-1)[0]?.pct_alquiler, 1)} %"
        period="del salari brut mitjà se'n va en el lloguer medià, {esfuerzo.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="Ministeri d'Habitatge / INE"
        href="/ca/vivienda/esfuerzo"
        sparklineData={esfuerzo.map(d => d.pct_alquiler)}
    />
</Grid>

## Amb inflació i sense

Entre el {hitos[0]?.anio_ini} i el {hitos[0]?.anio_fin} el lloguer medià va pujar un {formatNumber(hitos[0]?.var_nominal, 0)} % en euros de cada any; descomptada la inflació, {#if hitos[0]?.var_real < 0}va baixar un {formatNumber(-hitos[0]?.var_real, 1)} %{:else}va pujar un {formatNumber(hitos[0]?.var_real, 1)} %{/if}. El mínim real va ser el {hitos[0]?.anio_min}. En aquests anys el nombre de pisos el lloguer dels quals es declara a l'IRPF, per habitant, es va multiplicar per {formatNumber(hitos[0]?.veces_alquiladas, 1)}.

<LineChart
    data={espana_largo}
    x=anio
    y=alquiler
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ al mes"
    startingAtZero={false}
    title="Lloguer mensual medià d'un pis a Espanya"
/>

<LineChart
    data={percentiles}
    x=anio
    y=alquiler
    series=tramo
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ al mes (reals)"
    title="Repartiment dels lloguers: quartils, en euros de {espana[0]?.anio_base}"
/>

Espanya no apareix com a tal al fitxer del Ministeri: la xifra nacional és la mitjana de les medianes de cada comunitat ponderada pel nombre de pisos llogats.

L'INE publica a més un índex que segueix la renda dels mateixos contractes any rere any (sense el País Basc ni Navarra):

<LineChart
    data={ipva}
    x=anio
    y=indice_real
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="índex real, 2015 = 100"
    startingAtZero={false}
    title="Índex de Preus d'Habitatge en Lloguer descomptada la inflació (INE, 2015 = 100)"
/>

## Per comunitat

Lloguer medià d'un pis el {ccaa[0]?.anio}, en euros de {espana[0]?.anio_base}.

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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: Ministeri d'Habitatge"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'alquiler_mes_mediana_real', title: '€/mes', fmt: '#,##0'},
        {id: 'alquiler_m2_mediana_real', title: '€/m²', fmt: '0.00'},
        {id: 'pct_alquiler', title: '% del salari', fmt: '0.0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=alquiler_mes_mediana_real title="€/mes (real)" fmt='#,##0' />
    <Column id=alquiler_m2_mediana_real title="€/m² (real)" fmt='0.00' />
    <Column id=alquiler_var_5a title="Var. real en 5 anys %" fmt='0.0' contentType=delta />
    <Column id=pct_alquiler title="% del salari" fmt='0.0' />
    <Column id=alquiladas_1000 title="Pisos llogats per 1.000 hab." fmt='0.0' />
</DataTable>

## Per província

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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: Ministeri d'Habitatge"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'alquiler_mes_mediana_real', title: '€/mes', fmt: '#,##0'},
        {id: 'alquiler_var_5a', title: 'Var. real en 5 anys (%)', fmt: '0.0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Província" />
    <Column id=alquiler_mes_mediana_real title="€/mes (real)" fmt='#,##0' />
    <Column id=alquiler_m2_mediana_real title="€/m² (real)" fmt='0.00' />
    <Column id=alquiler_var_5a title="Var. real en 5 anys %" fmt='0.0' contentType=delta />
    <Column id=alquiladas_1000 title="Pisos llogats per 1.000 hab." fmt='0.0' />
</DataTable>

## Per municipi

Municipis de 20.000 habitants o més amb almenys 100 pisos llogats declarats, {municipios[0]?.anio}.

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=alquiler_mes_mediana_real title="€/mes (real)" fmt='#,##0' />
    <Column id=alquiler_m2_mediana_real title="€/m² (real)" fmt='0.00' />
    <Column id=superficie_mediana title="m² medians" fmt='0' />
    <Column id=variacion_real_5a title="Var. real en 5 anys %" fmt='0.0' contentType=delta />
    <Column id=alquiladas_1000 title="Llogats per 1.000 hab." fmt='0.0' />
</DataTable>

---

**Fonts:** [Ministeri d'Habitatge i Agenda Urbana, Sistema Estatal de Referència del Preu del Lloguer d'Habitatge](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi) (explotació dels models 100 de l'IRPF i del Cadastre, 2011-2024; País Basc i Navarra només per comunitat) i [INE, Índex de Preus d'Habitatge en Lloguer, taula 59057](https://www.ine.es/jaxiT3/Tabla.htm?t=59057). Deflactats amb l'IPC general de l'INE (base 2025).
