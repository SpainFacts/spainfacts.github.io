---
title: Prezo da vivenda
description: "Prezo da vivenda en España descontada a inflación: valor taxado por metro cadrado por comunidade, provincia e municipio e o Índice de Prezos de Vivenda do INE, nova e de segunda man."
i18n_origen: 058fd706b1df
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
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

<Dropdown name=ccaa_precio data={lista_ccaa} value=cod label=nombre defaultValue="13" title="Comunidade" />

```sql ccaa_serie
SELECT fecha, nombre, euros_m2_real
FROM mother.vivienda_precio_tasado
WHERE euros_m2_real IS NOT NULL
  AND ((nivel = 'ccaa' AND cod = '${inputs.ccaa_precio.value}') OR nivel = 'pais')
ORDER BY fecha, nombre
```

```sql provincias
SELECT r.cod AS cod_prov, r.nombre AS provincia, '/gl' || r.ruta AS ruta, r.precio_periodo, r.euros_m2_real, r.precio_90m2_real,
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

# 💶 Prezo da vivenda

Canto vale comprar unha vivenda en España e como cambiou. Hai dúas fontes oficiais que se complementan: o **valor taxado** do Ministerio de Vivenda, que dá euros por metro cadrado e chega a provincias e municipios, e o **Índice de Prezos de Vivenda** do INE, que segue os prezos das compravendas escrituradas a calidade constante. Todo se mostra **descontada a inflación**, en euros de {precio[0]?.anio_base}.

<Grid cols=4>
    <KpiCard
        title="Valor taxado"
        value={precio.slice(-1)[0]?.euros_m2_real}
        formattedValue="{formatNumber(precio.slice(-1)[0]?.euros_m2_real, 0)} €/m²"
        period="España, {precio.slice(-1)[0]?.periodo} · {formatNumber(precio.slice(-1)[0]?.euros_m2, 0)} €/m² sen descontar a inflación"
        change={precio.slice(-1)[0]?.interanual_real?.toFixed(1)}
        changePeriod="real fronte a un ano antes"
        source="Ministerio de Vivenda"
        sparklineData={precio.map(d => d.euros_m2_real)}
    />
    <KpiCard
        title="Suba real dos prezos"
        value={ipv_general.slice(-1)[0]?.interanual_real}
        formattedValue="{ipv_general.slice(-1)[0]?.interanual_real >= 0 ? '+' : ''}{formatNumber(ipv_general.slice(-1)[0]?.interanual_real, 1)} %"
        period="IPV, {ipv_general.slice(-1)[0]?.periodo} fronte a un ano antes · {formatNumber(ipv_general.slice(-1)[0]?.interanual_nominal, 1)} % sen descontar a inflación"
        source="INE / IPV"
        sparklineData={ipv_general.filter(d => d.interanual_real != null).map(d => d.interanual_real)}
    />
    <KpiCard
        title="Fronte ao máximo da burbulla"
        value={ipv_hitos[0]?.vs_max}
        formattedValue="{ipv_hitos[0]?.vs_max >= 0 ? '+' : ''}{formatNumber(ipv_hitos[0]?.vs_max, 1)} %"
        period="prezo real fronte a {ipv_hitos[0]?.periodo_max} (IPV) · {ipv_hitos[0]?.vs_max_nominal >= 0 ? '+' : ''}{formatNumber(ipv_hitos[0]?.vs_max_nominal, 1)} % en euros de cada ano"
        source="INE / IPV"
        sparklineData={ipv_general.map(d => d.indice_real)}
    />
    <KpiCard
        title="Piso de 90 m²"
        value={precio.slice(-1)[0]?.precio_90m2_real}
        formattedValue="{formatNumber(precio.slice(-1)[0]?.precio_90m2_real / 1000, 0)} mil €"
        period="ao valor taxado medio de España, {precio.slice(-1)[0]?.periodo}"
        source="Ministerio de Vivenda"
        sparklineData={precio.map(d => d.precio_90m2_real)}
    />
</Grid>

## Evolución real do prezo

Índice de Prezos de Vivenda do INE descontada a inflación (2015 = 100). O máximo real da serie, que comeza en 2007, é de {ipv_hitos[0]?.periodo_max}; en {ipv_hitos[0]?.periodo_ult} o prezo real está {#if ipv_hitos[0]?.vs_max < 0}un {formatNumber(-ipv_hitos[0]?.vs_max, 1)} % por debaixo{:else}en máximos{/if}. No último trimestre, a vivenda nova subiu un {formatNumber(nueva_usada[0]?.nueva, 1)} % real e a de segunda man un {formatNumber(nueva_usada[0]?.usada, 1)} %.

<LineChart
    data={ipv}
    x=fecha
    y=indice_real
    series=tipo
    yFmt='0.0'
    yAxisTitle="índice real, 2015 = 100"
    startingAtZero={false}
    title="Índice de Prezos de Vivenda descontada a inflación (2015 = 100)"
/>

<BarChart
    data={ipv_interanual}
    x=fecha
    y=variacion
    series=tipo
    type=grouped
    yFmt='0.0"%"'
    yAxisTitle="% interanual"
    title="Variación interanual do prezo da vivenda: nominal e real (IPV xeral)"
/>

## Por comunidade

Valor taxado por metro cadrado da comunidade elixida fronte a España, en euros de {precio[0]?.anio_base}.

<LineChart
    data={ccaa_serie}
    x=fecha
    y=euros_m2_real
    series=nombre
    yFmt='#,##0" €"'
    yAxisTitle="€/m² (reais)"
    startingAtZero={false}
    title="Valor taxado real: comunidade fronte a España"
/>

## Por provincia

En {prov_extremos[0]?.periodo} a provincia co metro cadrado máis caro é {prov_extremos[0]?.cara} ({formatNumber(prov_extremos[0]?.cara_valor, 0)} €/m²) e a máis barata, {prov_extremos[0]?.barata} ({formatNumber(prov_extremos[0]?.barata_valor, 0)} €/m²): na primeira o metro cadrado custa {formatNumber(prov_extremos[0]?.veces, 1)} veces máis. {#if prov_extremos[0]?.en_maximos == 1}Só unha provincia está{:else}{prov_extremos[0]?.en_maximos} provincias están{/if} no seu máximo real desde 2002.

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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio de Vivenda"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'euros_m2_real', title: '€/m²', fmt: '#,##0'},
        {id: 'precio_interanual_real', title: 'Variación real anual (%)', fmt: '0.0'},
        {id: 'precio_vs_maximo_real', title: 'Fronte ao seu máximo real (%)', fmt: '0.0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Provincia" />
    <Column id=euros_m2_real title="€/m² (real)" fmt='#,##0' />
    <Column id=precio_90m2_real title="Piso de 90 m² (€)" fmt='#,##0' />
    <Column id=precio_interanual_real title="Var. real anual %" fmt='0.0' contentType=delta />
    <Column id=precio_vs_maximo_real title="Fronte ao máximo real %" fmt='0.0' />
    <Column id=precio_periodo_maximo title="Máximo real en" />
</DataTable>

## Municipios de máis de 25.000 habitantes

Valor taxado medio de {municipios[0]?.anio} (media dos seus catro trimestres, ponderada polo número de taxacións), en euros de {precio[0]?.anio_base}. Con poucas taxacións o dato é menos fiable.

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=euros_m2_real title="€/m² (real)" fmt='#,##0' />
    <Column id=precio_90m2_real title="Piso de 90 m² (€)" fmt='#,##0' />
    <Column id=variacion_real title="Var. real anual %" fmt='0.0' contentType=delta />
    <Column id=tasaciones title="Taxacións" fmt='#,##0' />
    <Column id=poblacion title="Habitantes" fmt='#,##0' />
</DataTable>

---

**Fontes:** [Ministerio de Vivenda e Axenda Urbana, valor taxado da vivenda libre](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000) (táboas 1 e 5, a partir das taxacións hipotecarias; valor medio de toda a vivenda libre, nova e usada) e [INE, Índice de Prezos de Vivenda, táboa 25171](https://www.ine.es/jaxiT3/Tabla.htm?t=25171) (base 2015, a partir das compravendas notariais). Deflactados co IPC xeral do INE (base 2025), trimestre a trimestre.
