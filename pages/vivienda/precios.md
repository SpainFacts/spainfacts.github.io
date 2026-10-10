---
title: Precio de la vivienda
description: "Precio de la vivienda en España descontada la inflación: valor tasado por metro cuadrado por comunidad, provincia y municipio y el Índice de Precios de Vivienda del INE, nueva y de segunda mano."
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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

<Dropdown name=ccaa_precio data={lista_ccaa} value=cod label=nombre defaultValue="13" title="Comunidad" />

```sql ccaa_serie
SELECT fecha, nombre, euros_m2_real
FROM mother.vivienda_precio_tasado
WHERE euros_m2_real IS NOT NULL
  AND ((nivel = 'ccaa' AND cod = '${inputs.ccaa_precio.value}') OR nivel = 'pais')
ORDER BY fecha, nombre
```

```sql provincias
SELECT r.cod AS cod_prov, r.nombre AS provincia, r.ruta, r.precio_periodo, r.euros_m2_real, r.precio_90m2_real,
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

# 💶 Precio de la vivienda

Cuánto vale comprar una vivienda en España y cómo ha cambiado. Hay dos fuentes oficiales que se complementan: el **valor tasado** del Ministerio de Vivienda, que da euros por metro cuadrado y llega a provincias y municipios, y el **Índice de Precios de Vivienda** del INE, que sigue los precios de las compraventas escrituradas a calidad constante. Todo se muestra **descontada la inflación**, en euros de {precio[0]?.anio_base}.

<Grid cols=4>
    <KpiCard
        title="Valor tasado"
        value={precio.slice(-1)[0]?.euros_m2_real}
        formattedValue="{formatNumber(precio.slice(-1)[0]?.euros_m2_real, 0)} €/m²"
        period="España, {precio.slice(-1)[0]?.periodo} · {formatNumber(precio.slice(-1)[0]?.euros_m2, 0)} €/m² sin descontar la inflación"
        change={precio.slice(-1)[0]?.interanual_real?.toFixed(1)}
        changePeriod="real vs un año antes"
        source="Ministerio de Vivienda"
        sparklineData={precio.map(d => ({...d, y: d.euros_m2_real}))}
    />
    <KpiCard
        title="Subida real de los precios"
        value={ipv_general.slice(-1)[0]?.interanual_real}
        formattedValue="{ipv_general.slice(-1)[0]?.interanual_real >= 0 ? '+' : ''}{formatNumber(ipv_general.slice(-1)[0]?.interanual_real, 1)} %"
        period="IPV, {ipv_general.slice(-1)[0]?.periodo} vs un año antes · {formatNumber(ipv_general.slice(-1)[0]?.interanual_nominal, 1)} % sin descontar la inflación"
        source="INE / IPV"
        sparklineData={ipv_general.filter(d => d.interanual_real != null).map(d => ({...d, y: d.interanual_real}))}
    />
    <KpiCard
        title="Frente al máximo de la burbuja"
        value={ipv_hitos[0]?.vs_max}
        formattedValue="{ipv_hitos[0]?.vs_max >= 0 ? '+' : ''}{formatNumber(ipv_hitos[0]?.vs_max, 1)} %"
        period="precio real vs {ipv_hitos[0]?.periodo_max} (IPV) · {ipv_hitos[0]?.vs_max_nominal >= 0 ? '+' : ''}{formatNumber(ipv_hitos[0]?.vs_max_nominal, 1)} % en euros de cada año"
        source="INE / IPV"
        sparklineData={ipv_general.map(d => ({...d, y: d.indice_real}))}
    />
    <KpiCard
        title="Piso de 90 m²"
        value={precio.slice(-1)[0]?.precio_90m2_real}
        formattedValue="{formatNumber(precio.slice(-1)[0]?.precio_90m2_real / 1000, 0)} mil €"
        period="al valor tasado medio de España, {precio.slice(-1)[0]?.periodo}"
        source="Ministerio de Vivienda"
        sparklineData={precio.map(d => ({...d, y: d.precio_90m2_real}))}
    />
</Grid>

## Evolución real del precio

Índice de Precios de Vivienda del INE descontada la inflación (2015 = 100). El máximo real de la serie, que empieza en 2007, es de {ipv_hitos[0]?.periodo_max}; en {ipv_hitos[0]?.periodo_ult} el precio real está {#if ipv_hitos[0]?.vs_max < 0}un {formatNumber(-ipv_hitos[0]?.vs_max, 1)} % por debajo{:else}en máximos{/if}. En el último trimestre, la vivienda nueva subió un {formatNumber(nueva_usada[0]?.nueva, 1)} % real y la de segunda mano un {formatNumber(nueva_usada[0]?.usada, 1)} %.

<LineChart
    data={ipv}
    x=fecha
    y=indice_real
    series=tipo
    yFmt='0.0'
    yAxisTitle="índice real, 2015 = 100"
    startingAtZero={false}
    title="Índice de Precios de Vivienda descontada la inflación (2015 = 100)"
/>

<BarChart
    data={ipv_interanual}
    x=fecha
    y=variacion
    series=tipo
    type=grouped
    yFmt='0.0"%"'
    yAxisTitle="% interanual"
    title="Variación interanual del precio de la vivienda: nominal y real (IPV general)"
/>

## Por comunidad

Valor tasado por metro cuadrado de la comunidad elegida frente a España, en euros de {precio[0]?.anio_base}.

<LineChart
    data={ccaa_serie}
    x=fecha
    y=euros_m2_real
    series=nombre
    yFmt='#,##0" €"'
    yAxisTitle="€/m² (reales)"
    startingAtZero={false}
    title="Valor tasado real: comunidad frente a España"
/>

## Por provincia

En {prov_extremos[0]?.periodo} la provincia con el metro cuadrado más caro es {prov_extremos[0]?.cara} ({formatNumber(prov_extremos[0]?.cara_valor, 0)} €/m²) y la más barata, {prov_extremos[0]?.barata} ({formatNumber(prov_extremos[0]?.barata_valor, 0)} €/m²): en la primera el metro cuadrado cuesta {formatNumber(prov_extremos[0]?.veces, 1)} veces más. {#if prov_extremos[0]?.en_maximos == 1}Solo una provincia está{:else}{prov_extremos[0]?.en_maximos} provincias están{/if} en su máximo real desde 2002.

<MapaEspana
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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio de Vivienda"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'euros_m2_real', title: '€/m²', fmt: '#,##0'},
        {id: 'precio_interanual_real', title: 'Variación real anual (%)', fmt: '0.0'},
        {id: 'precio_vs_maximo_real', title: 'Frente a su máximo real (%)', fmt: '0.0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Provincia" />
    <Column id=euros_m2_real title="€/m² (real)" fmt='#,##0' />
    <Column id=precio_90m2_real title="Piso de 90 m² (€)" fmt='#,##0' />
    <Column id=precio_interanual_real title="Var. real anual %" fmt='0.0' contentType=delta />
    <Column id=precio_vs_maximo_real title="Vs. máximo real %" fmt='0.0' />
    <Column id=precio_periodo_maximo title="Máximo real en" />
</DataTable>

## Municipios de más de 25.000 habitantes

Valor tasado medio de {municipios[0]?.anio} (media de sus cuatro trimestres, ponderada por el número de tasaciones), en euros de {precio[0]?.anio_base}. Con pocas tasaciones el dato es menos fiable.

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=euros_m2_real title="€/m² (real)" fmt='#,##0' />
    <Column id=precio_90m2_real title="Piso de 90 m² (€)" fmt='#,##0' />
    <Column id=variacion_real title="Var. real anual %" fmt='0.0' contentType=delta />
    <Column id=tasaciones title="Tasaciones" fmt='#,##0' />
    <Column id=poblacion title="Habitantes" fmt='#,##0' />
</DataTable>

---

**Fuentes:** [Ministerio de Vivienda y Agenda Urbana, valor tasado de la vivienda libre](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000) (tablas 1 y 5, a partir de las tasaciones hipotecarias; valor medio de toda la vivienda libre, nueva y usada) e [INE, Índice de Precios de Vivienda, tabla 25171](https://www.ine.es/jaxiT3/Tabla.htm?t=25171) (base 2015, a partir de las compraventas notariales). Deflactados con el IPC general del INE (base 2025), trimestre a trimestre.
