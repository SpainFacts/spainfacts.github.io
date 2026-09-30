---
title: Repartiment territorial de la població
description: "Com es reparteix la població d'Espanya entre comunitats i províncies des de 1975: concentració, províncies que perden habitants i percentatge de nascuts a l'estranger a cada província (INE)."
i18n_origen: c8fbe04365c1
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql prov_serie
SELECT CAST(e.anio AS INTEGER) AS anio, e.cod, e.poblacion, a.poblacion AS poblacion_antes,
    e.poblacion / sum(e.poblacion) OVER (PARTITION BY e.anio) AS cuota,
    row_number() OVER (PARTITION BY e.anio ORDER BY e.poblacion DESC) AS puesto
FROM mother.demografia_envejecimiento e
LEFT JOIN mother.demografia_envejecimiento a ON a.nivel = 'provincia' AND a.cod = e.cod AND a.anio = e.anio - 1
WHERE e.nivel = 'provincia'
```

```sql concentracion
SELECT anio,
    count(*) FILTER (WHERE poblacion < poblacion_antes) AS pierden,
    100 * sum(cuota) FILTER (WHERE puesto <= 5) AS pct_top5,
    count(*) FILTER (WHERE acumulada - cuota < 0.5) AS provincias_mitad
FROM (SELECT *, sum(cuota) OVER (PARTITION BY anio ORDER BY puesto) AS acumulada FROM ${prov_serie})
WHERE anio >= 1975
GROUP BY anio
ORDER BY anio
```

```sql origen
SELECT CAST(anio AS INTEGER) AS anio, pct_nacidos_extranjero, nacidos_extranjero, pct_extranjeros
FROM mother.demografia_envejecimiento
WHERE nivel = 'pais' AND pct_nacidos_extranjero IS NOT NULL
ORDER BY anio
```

# 🗺️ Repartiment territorial de la població

On viu la població d'Espanya, quines comunitats i províncies guanyen i perden pes i en quines províncies és més alta la proporció de persones nascudes a l'estranger.

<Grid cols=4>
    <KpiCard
        title="La meitat de la població viu en"
        value={concentracion.slice(-1)[0]?.provincias_mitad}
        formattedValue="{concentracion.slice(-1)[0]?.provincias_mitad} províncies"
        period="de 52, a 1 de gener de {concentracion.slice(-1)[0]?.anio} · {concentracion[0]?.provincias_mitad} el {concentracion[0]?.anio}"
        source="INE"
        sparklineData={concentracion.map(d => ({anio: d.anio, valor: d.provincias_mitad}))}
    />
    <KpiCard
        title="Les 5 províncies més poblades"
        value={concentracion.slice(-1)[0]?.pct_top5}
        formattedValue="{formatNumber(concentracion.slice(-1)[0]?.pct_top5, 1)} %"
        period="de la població · {formatNumber(concentracion[0]?.pct_top5, 1)} % el {concentracion[0]?.anio}"
        source="INE"
        sparklineData={concentracion.map(d => ({anio: d.anio, valor: d.pct_top5}))}
    />
    <KpiCard
        title="Províncies que perden població"
        value={concentracion.slice(-1)[0]?.pierden}
        formattedValue="{concentracion.slice(-1)[0]?.pierden} de 52"
        period="tenien menys habitants a 1 de gener de {concentracion.slice(-1)[0]?.anio} que un any abans"
        direction="positive-down"
        source="INE"
        sparklineData={concentracion.map(d => ({anio: d.anio, valor: d.pierden}))}
    />
    <KpiCard
        title="Nascuts a l'estranger"
        value={origen.slice(-1)[0]?.pct_nacidos_extranjero}
        formattedValue="{formatNumber(origen.slice(-1)[0]?.pct_nacidos_extranjero, 1)} %"
        period="de la població · {formatCompact(origen.slice(-1)[0]?.nacidos_extranjero, 2)} persones el {origen.slice(-1)[0]?.anio}"
        source="INE"
        href="/ca/sociedad/inmigracion"
        sparklineData={origen.map(d => ({anio: d.anio, valor: d.pct_nacidos_extranjero}))}
    />
</Grid>

<p class="text-xs text-gray-500">Població a 1 de gener segons l'Estadística Contínua de Població. Les províncies s'ordenen de més a menys població per comptar quantes calen per sumar la meitat dels habitants.</p>

## El pes de cada comunitat

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/ca' || t.ruta AS ruta,
    e.poblacion / p.poblacion AS peso,
    e75.poblacion / p75.poblacion AS peso_1975,
    100.0 * (e.poblacion / p.poblacion - e75.poblacion / p75.poblacion) AS cambio_pp,
    100.0 * (e.poblacion / e75.poblacion - 1) AS crec_1975,
    e.poblacion
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
JOIN mother.demografia_envejecimiento p ON p.nivel = 'pais' AND p.anio = e.anio
JOIN mother.demografia_envejecimiento e75 ON e75.nivel = 'ccaa' AND e75.cod = e.cod AND e75.anio = 1975
JOIN mother.demografia_envejecimiento p75 ON p75.nivel = 'pais' AND p75.anio = 1975
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY cambio_pp DESC
```

Des del 1975, la comunitat que més pes ha guanyat en la població espanyola és {ccaa[0]?.comunidad} ({formatNumber(ccaa[0]?.cambio_pp, 1)} punts) i la que més n'ha perdut, {ccaa.slice(-1)[0]?.comunidad} ({formatNumber(ccaa.slice(-1)[0]?.cambio_pp, 1)} punts).

<BarChart
    data={ccaa}
    x=comunidad
    y=cambio_pp
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#059669"
    title="Canvi del pes de cada comunitat en la població d'Espanya des del 1975 (punts percentuals)"
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=peso title="Pes actual" fmt=pct1 contentType=bar barColor="#a7f3d0" />
    <Column id=peso_1975 title="Pes el 1975" fmt=pct1 />
    <Column id=cambio_pp title="Canvi (p.p.)" fmt=num2 contentType=delta />
    <Column id=crec_1975 title="Creixement des del 1975 (%)" fmt=num1 />
    <Column id=poblacion title="Població" fmt=num0 />
</DataTable>

## Províncies que guanyen i perden població

```sql provincias
SELECT e.cod AS cod_prov, t.nombre AS provincia, '/ca' || t.ruta AS ruta, e.poblacion,
    100.0 * (e.poblacion / e75.poblacion - 1) AS crec_1975,
    e.pct_nacidos_extranjero / 100 AS nacidos_extranjero,
    e.pct_extranjeros / 100 AS extranjeros
FROM mother.demografia_envejecimiento e
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = e.cod
JOIN mother.demografia_envejecimiento e75 ON e75.nivel = 'provincia' AND e75.cod = e.cod AND e75.anio = 1975
WHERE e.nivel = 'provincia' AND e.anio = (SELECT max(anio) FROM mother.demografia_envejecimiento)
ORDER BY crec_1975 DESC
```

```sql provincias_resumen
SELECT count(*) FILTER (WHERE crec_1975 < 0) AS pierden_1975,
    arg_max(provincia, nacidos_extranjero) AS max_prov, max(nacidos_extranjero) AS max_pct,
    arg_min(provincia, nacidos_extranjero) AS min_prov, min(nacidos_extranjero) AS min_pct
FROM ${provincias}
```

{provincias_resumen[0]?.pierden_1975} províncies tenen avui menys habitants que el 1975. La que més ha crescut és {provincias[0]?.provincia} ({formatNumber(provincias[0]?.crec_1975, 0)} %) i la que més n'ha perdut, {provincias.slice(-1)[0]?.provincia} ({formatNumber(provincias.slice(-1)[0]?.crec_1975, 0)} %).

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="crec_1975"
    valueFmt="num0"
    link="ruta"
    colorPalette={['#b91c1c', '#f8fafc', '#1d4ed8']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
    title="Variació de la població des del 1975 (%)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'crec_1975', title: 'Variació des del 1975 (%)', fmt: 'num1'},
        {id: 'poblacion', title: 'Població', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">L'evolució més recent (últims 10 anys) és a <a href="/ca/demografia/evolucion-poblacion">Evolució de la població</a>, i el detall per municipi, a les fitxes de <a href="/ca/territorios">territoris</a>.</p>

## Nascuts a l'estranger per província

La proporció de residents nascuts en un altre país va del {formatNumber(provincias_resumen[0]?.max_pct / 0.01, 1)} % de {provincias_resumen[0]?.max_prov} al {formatNumber(provincias_resumen[0]?.min_pct / 0.01, 1)} % de {provincias_resumen[0]?.min_prov}.

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="nacidos_extranjero"
    valueFmt="pct1"
    link="ruta"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
    title="Població nascuda a l'estranger (% de la població)"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'nacidos_extranjero', title: "Nascuts a l'estranger", fmt: 'pct1'},
        {id: 'extranjeros', title: 'Amb nacionalitat estrangera', fmt: 'pct1'}
    ]}
/>

<p class="text-xs text-gray-500">Nascut a l'estranger no equival a estranger: inclou els qui han obtingut la nacionalitat espanyola i els fills d'espanyols nascuts fora. A Espanya, el {formatNumber(origen.slice(-1)[0]?.pct_nacidos_extranjero, 1)} % de la població va néixer fora i el {formatNumber(origen.slice(-1)[0]?.pct_extranjeros, 1)} % té nacionalitat estrangera.</p>

---

## Fonts i notes

- **[INE – Estadística Contínua de Població](https://www.ine.es/jaxiT3/Tabla.htm?t=56945)** (taula 56945): població a 1 de gener per província des de 1971.
- **[INE – Població per lloc de naixement](https://www.ine.es/jaxiT3/Tabla.htm?t=56948)** (taula 56948) i **[per nacionalitat](https://www.ine.es/jaxiT3/Tabla.htm?t=56947)** (taula 56947), per província, des del 2002.

<LastRefreshed prefix="Dades actualitzades" />
