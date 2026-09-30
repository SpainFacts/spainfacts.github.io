---
title: Preu de l'habitatge
description: "Preu de l'habitatge a Espanya descomptada la inflació: valor taxat per metre quadrat per comunitat, província i municipi i l'Índex de Preus d'Habitatge de l'INE, nou i de segona mà."
i18n_origen: 50400dad918f
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql precio
SELECT fecha, periodo, anio, euros_m2, euros_m2_real, precio_90m2_real, interanual_real, interanual_nominal, anio_base
FROM mother.vivienda_precio_tasado
WHERE nivel = 'pais' AND euros_m2_real IS NOT NULL
ORDER BY fecha
```

```sql ipv
SELECT fecha, periodo, tipo, indice, indice_real, interanual_real, interanual_nominal
FROM mother.vivienda_ipv
WHERE nivel = 'pais'
ORDER BY fecha, tipo
```

```sql ipv_general
SELECT * FROM ${ipv} WHERE tipo = 'General' ORDER BY fecha
```

```sql ipv_interanual
SELECT fecha, 'Nominal' AS tipo, interanual_nominal AS variacion FROM ${ipv_general} WHERE interanual_nominal IS NOT NULL
UNION ALL
SELECT fecha, 'Real' AS tipo, interanual_real AS variacion FROM ${ipv_general} WHERE interanual_real IS NOT NULL
ORDER BY fecha, tipo
```

```sql ipv_hitos
SELECT
    arg_max(periodo, fecha) AS periodo_ult,
    arg_max(indice_real, fecha) AS real_ult,
    max(indice_real) AS real_max,
    arg_max(periodo, indice_real) AS periodo_max,
    100 * (arg_max(indice_real, fecha) / max(indice_real) - 1) AS vs_max,
    100 * (arg_max(indice, fecha) / max(indice) - 1) AS vs_max_nominal
FROM ${ipv_general}
```

```sql nueva_usada
SELECT
    max(interanual_real) FILTER (WHERE tipo = 'Nueva') AS nueva,
    max(interanual_real) FILTER (WHERE tipo = 'Segunda mano') AS usada,
    max(periodo) AS periodo
FROM ${ipv}
WHERE fecha = (SELECT max(fecha) FROM ${ipv})
```

```sql lista_ccaa
SELECT cod, nombre FROM mother.vivienda_resumen_territorios WHERE nivel = 'ccaa' ORDER BY nombre
```

<Dropdown name=ccaa_precio data={lista_ccaa} value=cod label=nombre defaultValue="13" title="Comunitat" />

```sql ccaa_serie
SELECT fecha, nombre, euros_m2_real
FROM mother.vivienda_precio_tasado
WHERE euros_m2_real IS NOT NULL
  AND ((nivel = 'ccaa' AND cod = '${inputs.ccaa_precio.value}') OR nivel = 'pais')
ORDER BY fecha, nombre
```

```sql provincias
SELECT r.cod AS cod_prov, r.nombre AS provincia, '/ca' || r.ruta AS ruta, r.precio_periodo, r.euros_m2_real, r.precio_90m2_real,
       r.precio_interanual_real, r.precio_vs_maximo_real, r.precio_periodo_maximo
FROM mother.vivienda_resumen_territorios r
WHERE r.nivel = 'provincia'
ORDER BY r.euros_m2_real DESC
```

```sql prov_extremos
SELECT
    arg_max(provincia, euros_m2_real) AS cara,
    max(euros_m2_real) AS cara_valor,
    arg_min(provincia, euros_m2_real) AS barata,
    min(euros_m2_real) AS barata_valor,
    max(euros_m2_real) / min(euros_m2_real) AS veces,
    count(*) FILTER (WHERE precio_vs_maximo_real >= 0) AS en_maximos,
    max(precio_periodo) AS periodo
FROM ${provincias}
```

```sql municipios
SELECT m.municipio, p.nombre AS provincia, m.poblacion, m.euros_m2_real, m.precio_90m2_real, m.variacion_real, m.tasaciones, m.anio
FROM mother.vivienda_precio_municipios m
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
WHERE m.anio = (SELECT max(anio) FROM mother.vivienda_precio_municipios WHERE trimestres = 4)
ORDER BY m.euros_m2_real DESC
```

# 💶 Preu de l'habitatge

Quant val comprar un habitatge a Espanya i com ha canviat. Hi ha dues fonts oficials que es complementen: el **valor taxat** del Ministeri d'Habitatge, que dona euros per metre quadrat i arriba a províncies i municipis, i l'**Índex de Preus d'Habitatge** de l'INE, que segueix els preus de les compravendes escripturades a qualitat constant. Tot es mostra **descomptada la inflació**, en euros de {precio[0]?.anio_base}.

<Grid cols=4>
    <KpiCard
        title="Valor taxat"
        value={precio.slice(-1)[0]?.euros_m2_real}
        formattedValue="{formatNumber(precio.slice(-1)[0]?.euros_m2_real, 0)} €/m²"
        period="Espanya, {precio.slice(-1)[0]?.periodo} · {formatNumber(precio.slice(-1)[0]?.euros_m2, 0)} €/m² sense descomptar la inflació"
        change={precio.slice(-1)[0]?.interanual_real?.toFixed(1)}
        changePeriod="real vs. un any abans"
        source="Ministeri d'Habitatge"
        sparklineData={precio.map(d => d.euros_m2_real)}
    />
    <KpiCard
        title="Pujada real dels preus"
        value={ipv_general.slice(-1)[0]?.interanual_real}
        formattedValue="{ipv_general.slice(-1)[0]?.interanual_real >= 0 ? '+' : ''}{formatNumber(ipv_general.slice(-1)[0]?.interanual_real, 1)} %"
        period="IPV, {ipv_general.slice(-1)[0]?.periodo} vs. un any abans · {formatNumber(ipv_general.slice(-1)[0]?.interanual_nominal, 1)} % sense descomptar la inflació"
        source="INE / IPV"
        sparklineData={ipv_general.filter(d => d.interanual_real != null).map(d => d.interanual_real)}
    />
    <KpiCard
        title="Respecte al màxim de la bombolla"
        value={ipv_hitos[0]?.vs_max}
        formattedValue="{ipv_hitos[0]?.vs_max >= 0 ? '+' : ''}{formatNumber(ipv_hitos[0]?.vs_max, 1)} %"
        period="preu real vs. {ipv_hitos[0]?.periodo_max} (IPV) · {ipv_hitos[0]?.vs_max_nominal >= 0 ? '+' : ''}{formatNumber(ipv_hitos[0]?.vs_max_nominal, 1)} % en euros de cada any"
        source="INE / IPV"
        sparklineData={ipv_general.map(d => d.indice_real)}
    />
    <KpiCard
        title="Pis de 90 m²"
        value={precio.slice(-1)[0]?.precio_90m2_real}
        formattedValue="{formatNumber(precio.slice(-1)[0]?.precio_90m2_real / 1000, 0)} mil €"
        period="al valor taxat mitjà d'Espanya, {precio.slice(-1)[0]?.periodo}"
        source="Ministeri d'Habitatge"
        sparklineData={precio.map(d => d.precio_90m2_real)}
    />
</Grid>

## Evolució real del preu

Índex de Preus d'Habitatge de l'INE descomptada la inflació (2015 = 100). El màxim real de la sèrie, que comença el 2007, és del {ipv_hitos[0]?.periodo_max}; el {ipv_hitos[0]?.periodo_ult} el preu real és {#if ipv_hitos[0]?.vs_max < 0}un {formatNumber(-ipv_hitos[0]?.vs_max, 1)} % per sota{:else}en màxims{/if}. En l'últim trimestre, l'habitatge nou va pujar un {formatNumber(nueva_usada[0]?.nueva, 1)} % real i el de segona mà, un {formatNumber(nueva_usada[0]?.usada, 1)} %.

<LineChart
    data={ipv}
    x=fecha
    y=indice_real
    series=tipo
    yFmt='0.0'
    yAxisTitle="índex real, 2015 = 100"
    startingAtZero={false}
    title="Índex de Preus d'Habitatge descomptada la inflació (2015 = 100)"
/>

<BarChart
    data={ipv_interanual}
    x=fecha
    y=variacion
    series=tipo
    type=grouped
    yFmt='0.0"%"'
    yAxisTitle="% interanual"
    title="Variació interanual del preu de l'habitatge: nominal i real (IPV general)"
/>

## Per comunitat

Valor taxat per metre quadrat de la comunitat triada davant d'Espanya, en euros de {precio[0]?.anio_base}.

<LineChart
    data={ccaa_serie}
    x=fecha
    y=euros_m2_real
    series=nombre
    yFmt='#,##0" €"'
    yAxisTitle="€/m² (reals)"
    startingAtZero={false}
    title="Valor taxat real: comunitat davant d'Espanya"
/>

## Per província

El {prov_extremos[0]?.periodo} la província amb el metre quadrat més car és {prov_extremos[0]?.cara} ({formatNumber(prov_extremos[0]?.cara_valor, 0)} €/m²) i la més barata, {prov_extremos[0]?.barata} ({formatNumber(prov_extremos[0]?.barata_valor, 0)} €/m²): a la primera el metre quadrat costa {formatNumber(prov_extremos[0]?.veces, 1)} vegades més. {#if prov_extremos[0]?.en_maximos == 1}Només una província és{:else}{prov_extremos[0]?.en_maximos} províncies són{/if} al seu màxim real des del 2002.

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="euros_m2_real"
    valueFmt='#,##0" €"'
    link="ruta"
    colorPalette={['#fef3c7', '#f59e0b', '#92400e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: Ministeri d'Habitatge"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'euros_m2_real', title: '€/m²', fmt: '#,##0'},
        {id: 'precio_interanual_real', title: 'Variació real anual (%)', fmt: '0.0'},
        {id: 'precio_vs_maximo_real', title: 'Respecte al seu màxim real (%)', fmt: '0.0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Província" />
    <Column id=euros_m2_real title="€/m² (real)" fmt='#,##0' />
    <Column id=precio_90m2_real title="Pis de 90 m² (€)" fmt='#,##0' />
    <Column id=precio_interanual_real title="Var. real anual %" fmt='0.0' contentType=delta />
    <Column id=precio_vs_maximo_real title="Vs. màxim real %" fmt='0.0' />
    <Column id=precio_periodo_maximo title="Màxim real el" />
</DataTable>

## Municipis de més de 25.000 habitants

Valor taxat mitjà del {municipios[0]?.anio} (mitjana dels seus quatre trimestres, ponderada pel nombre de taxacions), en euros de {precio[0]?.anio_base}. Amb poques taxacions la dada és menys fiable.

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=euros_m2_real title="€/m² (real)" fmt='#,##0' />
    <Column id=precio_90m2_real title="Pis de 90 m² (€)" fmt='#,##0' />
    <Column id=variacion_real title="Var. real anual %" fmt='0.0' contentType=delta />
    <Column id=tasaciones title="Taxacions" fmt='#,##0' />
    <Column id=poblacion title="Habitants" fmt='#,##0' />
</DataTable>

---

**Fonts:** [Ministeri d'Habitatge i Agenda Urbana, valor taxat de l'habitatge lliure](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000) (taules 1 i 5, a partir de les taxacions hipotecàries; valor mitjà de tot l'habitatge lliure, nou i usat) i [INE, Índex de Preus d'Habitatge, taula 25171](https://www.ine.es/jaxiT3/Tabla.htm?t=25171) (base 2015, a partir de les compravendes notarials). Deflactats amb l'IPC general de l'INE (base 2025), trimestre a trimestre.
