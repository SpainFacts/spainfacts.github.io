---
title: Renda, pobreza e desigualdade
description: "Renda media dos fogares descontada a inflación, risco de pobreza, AROPE, carencia material, índice de Gini e S80/S20 en España, por comunidade, idade e municipio, e comparación coa UE."
i18n_origen: 9952ace4d46b
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql nac
SELECT *
FROM mother.renta_ecv_ccaa
WHERE cod = '00' AND anio >= 2008
ORDER BY anio
```

```sql ue_ultimo
SELECT
    max(valor) FILTER (WHERE geo = 'ES' AND indicador = 'gini') AS gini_es,
    max(valor) FILTER (WHERE geo = 'EU27_2020' AND indicador = 'gini') AS gini_ue,
    max(valor) FILTER (WHERE geo = 'ES' AND indicador = 'arope') AS arope_es,
    max(valor) FILTER (WHERE geo = 'EU27_2020' AND indicador = 'arope') AS arope_ue,
    max(valor) FILTER (WHERE geo = 'ES' AND indicador = 's80_s20') AS s80_es,
    max(valor) FILTER (WHERE geo = 'EU27_2020' AND indicador = 's80_s20') AS s80_ue,
    CAST(max(anio) AS INTEGER) AS anio
FROM mother.renta_ue
WHERE anio = (SELECT max(anio) FROM mother.renta_ue WHERE geo = 'EU27_2020' AND indicador = 'gini')
```

```sql hitos
WITH n AS (SELECT * FROM mother.renta_ecv_ccaa WHERE cod = '00' AND renta_persona_real IS NOT NULL),
u AS (SELECT * FROM n WHERE anio = (SELECT max(anio) FROM n)),
p AS (SELECT * FROM n WHERE anio = 2008),
m AS (SELECT * FROM n ORDER BY renta_persona_real LIMIT 1)
SELECT
    CAST(u.anio AS INTEGER) AS anio,
    CAST(u.anio_renta AS INTEGER) AS anio_renta,
    CAST(u.anio_base AS INTEGER) AS anio_base,
    u.renta_persona_real, u.renta_persona, u.renta_hogar_real, u.renta_uc_real,
    u.tasa_pobreza, u.arope, u.carencia_severa, u.fin_mes_dificultad, u.gini, u.s80_s20,
    CAST(p.anio_renta AS INTEGER) AS anio_renta_2008,
    100 * (u.renta_persona_real / p.renta_persona_real - 1) AS var_real_2008,
    CAST(m.anio_renta AS INTEGER) AS anio_renta_min,
    m.renta_persona_real AS renta_min,
    100 * (u.renta_persona_real / m.renta_persona_real - 1) AS var_real_min,
    p.tasa_pobreza AS pobreza_2008,
    p.gini AS gini_2008,
    (SELECT max(tasa_pobreza) FROM n) AS pobreza_max,
    (SELECT CAST(arg_max(anio, tasa_pobreza) AS INTEGER) FROM n) AS anio_pobreza_max,
    (SELECT max(gini) FROM n) AS gini_max,
    (SELECT CAST(arg_max(anio, gini) AS INTEGER) FROM n) AS anio_gini_max
FROM u, p, m
```

```sql arope_serie
SELECT anio, arope AS valor FROM ${nac} WHERE arope IS NOT NULL ORDER BY anio
```

```sql gini_serie
SELECT anio, gini AS valor FROM ${nac} WHERE gini IS NOT NULL ORDER BY anio
```

# 💶 Renda, pobreza e desigualdade

Canto ingresan de media os fogares en España unha vez descontada a inflación, que parte da poboación vive en risco de pobreza ou exclusión, canto se reparte de forma desigual a renda e como cambia todo iso entre comunidades, idades e municipios.

<Grid cols=4>
    <KpiCard
        title="Renda neta por persoa"
        value={hitos[0]?.renta_persona_real}
        formattedValue="{formatNumber(hitos[0]?.renta_persona_real, 0)} €"
        period="ao ano, renda de {hitos[0]?.anio_renta} en euros de {hitos[0]?.anio_base} · {formatNumber(hitos[0]?.renta_persona, 0)} € correntes"
        change={hitos[0]?.var_real_2008}
        changeUnit="%"
        changePeriod="fronte a {hitos[0]?.anio_renta_2008}, descontada a inflación"
        direction="positive-up"
        source="INE – ECV"
        sparklineData={nac.map(d => ({anio: d.anio_renta, valor: d.renta_persona_real}))}
    />
    <KpiCard
        title="Risco de pobreza"
        value={hitos[0]?.tasa_pobreza}
        formattedValue="{formatNumber(hitos[0]?.tasa_pobreza, 1)} %"
        period="da poboación, con menos do 60 % da renda mediana (ECV {hitos[0]?.anio})"
        change={hitos[0]?.tasa_pobreza - hitos[0]?.pobreza_2008}
        changeUnit=" pp"
        changePeriod="fronte á ECV 2008"
        direction="positive-down"
        source="INE – ECV"
        sparklineData={nac.map(d => ({anio: d.anio, valor: d.tasa_pobreza}))}
    />
    <KpiCard
        title="Risco de pobreza ou exclusión (AROPE)"
        value={hitos[0]?.arope}
        formattedValue="{formatNumber(hitos[0]?.arope, 1)} %"
        period="da poboación en {hitos[0]?.anio} · UE-27: {formatNumber(ue_ultimo[0]?.arope_ue, 1)} % ({ue_ultimo[0]?.anio})"
        direction="positive-down"
        source="INE – ECV / Eurostat"
        sparklineData={arope_serie}
    />
    <KpiCard
        title="Índice de Gini"
        value={hitos[0]?.gini}
        formattedValue={formatNumber(hitos[0]?.gini, 1)}
        period="0 = todos igual, 100 = un teno todo · UE-27: {formatNumber(ue_ultimo[0]?.gini_ue, 1)} ({ue_ultimo[0]?.anio})"
        change={hitos[0]?.gini - hitos[0]?.gini_2008}
        changeUnit=" puntos"
        changePeriod="fronte á ECV 2008"
        direction="positive-down"
        source="INE – ECV / Eurostat"
        sparklineData={gini_serie}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('riesgo_pobreza', 'gini')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'riesgo_pobreza')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'gini')} />


<p class="text-xs text-gray-500">A Enquisa de Condicións de Vida (ECV) de cada ano pregunta pola renda do ano anterior: a ECV {hitos[0]?.anio} recolle a renda de {hitos[0]?.anio_renta}. A pobreza, o Gini e o S80/S20 calcúlanse con esa renda. Todos os importes están en euros de {hitos[0]?.anio_base}, descontada a inflación co IPC.</p>

## A renda real dos fogares

```sql renta_grafico
SELECT anio_renta AS anio, 'Por persona' AS medida, renta_persona_real AS euros FROM ${nac} WHERE renta_persona_real IS NOT NULL
UNION ALL
SELECT anio_renta, 'Por unidad de consumo', renta_uc_real FROM ${nac} WHERE renta_uc_real IS NOT NULL
ORDER BY anio, medida
```

A renda neta por persoa, descontada a inflación, tocou fondo coa renda de {hitos[0]?.anio_renta_min} ({formatNumber(hitos[0]?.renta_min, 0)} €) e desde entón subiu un {formatNumber(hitos[0]?.var_real_min, 1)} %. Fronte á renda de {hitos[0]?.anio_renta_2008}, a diferenza é do {formatNumber(hitos[0]?.var_real_2008, 1)} %.

<LineChart
    data={renta_grafico}
    x=anio
    y=euros
    series=medida
    xFmt="0"
    yFmt='#,##0" €"'
    colorPalette={['#1d4ed8', '#0f766e']}
    title="Renda neta media anual, en euros de {hitos[0]?.anio_base} (ano da renda)"
/>

<p class="text-xs text-gray-500">A renda por unidade de consumo ten en conta que nun fogar se comparten gastos: o primeiro adulto conta 1, os demais maiores de 14 anos 0,5 e os menores 0,3. É a medida que se usa para comparar fogares de distinto tamaño e para calcular a pobreza. A renda media por fogar foi de {formatNumber(hitos[0]?.renta_hogar_real, 0)} €.</p>

## Pobreza e exclusión

```sql pobreza_grafico
SELECT anio, 'Riesgo de pobreza' AS indicador, tasa_pobreza AS pct FROM ${nac} WHERE tasa_pobreza IS NOT NULL
UNION ALL
SELECT anio, 'AROPE (pobreza o exclusión)', arope FROM ${nac} WHERE arope IS NOT NULL
UNION ALL
SELECT anio, 'Carencia material y social severa', carencia_severa FROM ${nac} WHERE carencia_severa IS NOT NULL
UNION ALL
SELECT anio, 'Llega a fin de mes con dificultad', fin_mes_dificultad FROM ${nac} WHERE fin_mes_dificultad IS NOT NULL
ORDER BY anio, indicador
```

Na ECV {hitos[0]?.anio}, o {formatNumber(hitos[0]?.tasa_pobreza, 1)} % da poboación estaba en risco de pobreza (o máximo da serie foi {formatNumber(hitos[0]?.pobreza_max, 1)} % en {hitos[0]?.anio_pobreza_max}), o {formatNumber(hitos[0]?.carencia_severa, 1)} % sufría carencia material e social severa e o {formatNumber(hitos[0]?.fin_mes_dificultad, 1)} % dicía chegar a fin de mes con dificultade ou con moita dificultade.

<LineChart
    data={pobreza_grafico}
    x=anio
    y=pct
    series=indicador
    xFmt="0"
    yFmt='0.0"%"'
    colorPalette={['#b91c1c', '#f59e0b', '#7c3aed', '#64748b']}
    title="% da poboación (ano da enquisa)"
/>

<p class="text-xs text-gray-500">Risco de pobreza: renda por unidade de consumo por debaixo do 60 % da mediana de España; é unha medida relativa, así que baixa se os pobres se achegan á mediana, non se sobe a renda de todos. AROPE suma a quen está en risco de pobreza, sofre carencia material e social severa ou vive en fogares con moi baixa intensidade de traballo (definición Europa 2030, desde 2014). Carencia material e social severa: non poder permitirse polo menos 7 de 13 conceptos básicos (quentar a casa, un imprevisto, comer carne ou peixe cada dous días, roupa nova...).</p>

```sql edad
SELECT edad, orden, arope, tasa_pobreza, carencia_severa, renta_uc_real, CAST(anio AS INTEGER) AS anio
FROM mother.renta_ecv_edad
WHERE anio = (SELECT max(anio) FROM mother.renta_ecv_edad) AND orden BETWEEN 1 AND 5
ORDER BY orden
```

```sql edad_grafico
SELECT edad, orden, 'AROPE' AS indicador, arope AS pct FROM ${edad}
UNION ALL
SELECT edad, orden, 'Riesgo de pobreza', tasa_pobreza FROM ${edad}
UNION ALL
SELECT edad, orden, 'Carencia severa', carencia_severa FROM ${edad}
ORDER BY orden
```

```sql edad_extremos
SELECT lower(arg_max(edad, tasa_pobreza)) AS edad_max, max(tasa_pobreza) AS pobreza_max,
    lower(arg_min(edad, tasa_pobreza)) AS edad_min, min(tasa_pobreza) AS pobreza_min
FROM ${edad}
```

### Por idade

Na ECV {edad[0]?.anio}, o grupo de idade con máis risco de pobreza era o de {edad_extremos[0]?.edad_max} ({formatNumber(edad_extremos[0]?.pobreza_max, 1)} %) e o que menos, o de {edad_extremos[0]?.edad_min} ({formatNumber(edad_extremos[0]?.pobreza_min, 1)} %).

<BarChart
    data={edad_grafico}
    x=edad
    y=pct
    series=indicador
    type=grouped
    sort=false
    yFmt='0.0"%"'
    colorPalette={['#f59e0b', '#b91c1c', '#7c3aed']}
    title="% de cada grupo de idade (ECV {edad[0]?.anio})"
/>

<p class="text-xs text-gray-500">A renda dos maiores conta as súas pensións, pero non o aforro acumulado nin o aluguer que se aforran os que teñen a casa pagada (estas cifras son sen aluguer imputado).</p>

## Desigualdade

```sql desigualdad_grafico
SELECT anio, 'España (INE)' AS territorio, gini FROM ${nac} WHERE gini IS NOT NULL
UNION ALL
SELECT anio, 'UE-27 (Eurostat)', valor FROM mother.renta_ue WHERE geo = 'EU27_2020' AND indicador = 'gini'
ORDER BY anio, territorio
```

O índice de Gini de España foi {formatNumber(hitos[0]?.gini, 1)} na ECV {hitos[0]?.anio} (máximo da serie: {formatNumber(hitos[0]?.gini_max, 1)} en {hitos[0]?.anio_gini_max}). O 20 % da poboación con máis renda ingresa {formatNumber(hitos[0]?.s80_s20, 1)} veces o que o 20 % con menos (ratio S80/S20; UE-27: {formatNumber(ue_ultimo[0]?.s80_ue, 1)} en {ue_ultimo[0]?.anio}).

<LineChart
    data={desigualdad_grafico}
    x=anio
    y=gini
    series=territorio
    xFmt="0"
    yFmt="0.0"
    yMin=25
    colorPalette={['#b91c1c', '#94a3b8']}
    title="Índice de Gini da renda dispoñible equivalente (0-100)"
/>

```sql gini_paises
SELECT pais, valor AS gini, CASE WHEN geo = 'ES' THEN 'España' WHEN geo = 'EU27_2020' THEN 'UE-27' ELSE 'Otros' END AS grupo
FROM mother.renta_ue
WHERE indicador = 'gini' AND anio = (SELECT max(anio) FROM mother.renta_ue WHERE geo = 'EU27_2020' AND indicador = 'gini')
ORDER BY valor DESC
```

<BarChart
    data={gini_paises}
    x=pais
    y=gini
    series=grupo
    swapXY=true
    sort=false
    yFmt="0.0"
    colorPalette={['#94a3b8', '#b91c1c', '#1d4ed8']}
    height={560}
    title="Índice de Gini na UE ({ue_ultimo[0]?.anio})"
/>

## Por comunidade autónoma

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/gl' || t.ruta AS ruta,
    e.renta_persona_real, e.renta_uc_real, e.tasa_pobreza, e.arope, e.carencia_severa, e.fin_mes_dificultad, e.gini,
    CAST(e.anio AS INTEGER) AS anio, CAST(e.anio_renta AS INTEGER) AS anio_renta
FROM mother.renta_ecv_ccaa e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.renta_ecv_ccaa WHERE tasa_pobreza IS NOT NULL)
ORDER BY e.tasa_pobreza DESC
```

```sql ccaa_extremos
SELECT
    arg_max(comunidad, tasa_pobreza) AS mas_pobreza, max(tasa_pobreza) AS max_pobreza,
    arg_min(comunidad, tasa_pobreza) AS menos_pobreza, min(tasa_pobreza) AS min_pobreza,
    arg_max(comunidad, renta_persona_real) AS mas_renta, max(renta_persona_real) AS max_renta,
    arg_min(comunidad, renta_persona_real) AS menos_renta, min(renta_persona_real) AS min_renta
FROM ${ccaa}
```

As diferenzas entre comunidades son grandes: na ECV {ccaa[0]?.anio} a taxa de risco de pobreza ía do {formatNumber(ccaa_extremos[0]?.min_pobreza, 1)} % de {ccaa_extremos[0]?.menos_pobreza} ao {formatNumber(ccaa_extremos[0]?.max_pobreza, 1)} % de {ccaa_extremos[0]?.mas_pobreza}, e a renda neta por persoa de {formatNumber(ccaa_extremos[0]?.min_renta, 0)} € en {ccaa_extremos[0]?.menos_renta} a {formatNumber(ccaa_extremos[0]?.max_renta, 0)} € en {ccaa_extremos[0]?.mas_renta}. O limiar de pobreza é o mesmo para toda España, sen axustar polo custo de vida de cada rexión.

<Grid cols=2>
    <AreaMap
        data={ccaa}
        geoJsonUrl="/geo/ccaa.geojson"
        geoId="cod_ccaa"
        areaCol="cod"
        value="tasa_pobreza"
        valueFmt='0.0"%"'
        link="ruta"
        colorPalette={['#fef2f2', '#f87171', '#991b1b']}
        height={420}
        basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
        attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
        tooltip={[
            {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'tasa_pobreza', title: 'Risco de pobreza', fmt: '0.0"%"'},
            {id: 'arope', title: 'AROPE', fmt: '0.0"%"'},
            {id: 'renta_persona_real', title: 'Renda por persoa', fmt: '#,##0" €"'}
        ]}
    />
    <BarChart
        data={ccaa}
        x=comunidad
        y=renta_persona_real
        swapXY=true
        yFmt='#,##0" €"'
        fillColor="#1d4ed8"
        height={420}
        title="Renda neta por persoa (renda de {ccaa[0]?.anio_renta}, euros de {hitos[0]?.anio_base})"
    />
</Grid>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidade" />
    <Column id=renta_persona_real title="Renda por persoa" fmt='#,##0" €"' />
    <Column id=tasa_pobreza title="Risco de pobreza" fmt='0.0"%"' contentType=bar barColor="#fecaca" />
    <Column id=arope title="AROPE" fmt='0.0"%"' />
    <Column id=carencia_severa title="Carencia severa" fmt='0.0"%"' />
    <Column id=fin_mes_dificultad title="Fin de mes con dificultade" fmt='0.0"%"' />
    <Column id=gini title="Gini" fmt="0.0" />
</DataTable>

<p class="text-xs text-gray-500">Mapa: taxa de risco de pobreza (%). As mostras de Ceuta e Melilla son pequenas, así que as súas cifras teñen unha marxe de erro ampla.</p>

## Municipios máis ricos e máis pobres

```sql mun_base
SELECT m.cod_mun, m.municipio, p.nombre AS provincia, m.poblacion, m.renta_persona_real, m.renta_hogar_real,
    m.renta_uc_mediana_real, CAST(m.anio AS INTEGER) AS anio, '/gl/territorios/municipios?m=' || m.cod_mun AS enlace
FROM mother.renta_municipios m
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
WHERE m.anio = (SELECT max(anio) FROM mother.renta_municipios) AND m.poblacion > 20000 AND m.renta_persona_real IS NOT NULL
ORDER BY m.renta_persona_real DESC
```

```sql mun_ricos
SELECT * FROM ${mun_base} ORDER BY renta_persona_real DESC LIMIT 15
```

```sql mun_pobres
SELECT * FROM ${mun_base} ORDER BY renta_persona_real ASC LIMIT 15
```

```sql mun_resumen
SELECT count(*) AS n, max(renta_persona_real) / min(renta_persona_real) AS ratio,
    arg_max(municipio, renta_persona_real) AS mas_rico, arg_min(municipio, renta_persona_real) AS mas_pobre
FROM ${mun_base}
```

O Atlas de Distribución de Renda dos Fogares do INE, elaborado con datos de Facenda, chega a cada municipio. Entre os {formatNumber(mun_resumen[0]?.n, 0)} municipios de máis de 20.000 habitantes, a renda por persoa de {mun_resumen[0]?.mas_rico} é {formatNumber(mun_resumen[0]?.ratio, 1)} veces a de {mun_resumen[0]?.mas_pobre} (renda de {mun_ricos[0]?.anio}).

<Grid cols=2>
    <DataTable data={mun_ricos} link=enlace rows=15 showLinkCol=false title="Maior renda por persoa">
        <Column id=municipio title="Municipio" />
        <Column id=provincia title="Provincia" />
        <Column id=renta_persona_real title="Por persoa" fmt='#,##0" €"' contentType=bar barColor="#bfdbfe" />
        <Column id=renta_hogar_real title="Por fogar" fmt='#,##0" €"' />
    </DataTable>
    <DataTable data={mun_pobres} link=enlace rows=15 showLinkCol=false title="Menor renda por persoa">
        <Column id=municipio title="Municipio" />
        <Column id=provincia title="Provincia" />
        <Column id=renta_persona_real title="Por persoa" fmt='#,##0" €"' contentType=bar barColor="#fecaca" />
        <Column id=renta_hogar_real title="Por fogar" fmt='#,##0" €"' />
    </DataTable>
</Grid>

<DataTable data={mun_base} link=enlace rows=10 search=true showLinkCol=false title="Todos os municipios de máis de 20.000 habitantes">
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=renta_persona_real title="Renda por persoa" fmt='#,##0" €"' />
    <Column id=renta_hogar_real title="Renda por fogar" fmt='#,##0" €"' />
    <Column id=renta_uc_mediana_real title="Mediana por unidade de consumo" fmt='#,##0" €"' />
</DataTable>

<p class="text-xs text-gray-500">Renda neta (despois de impostos e cotizacións) calculada polo INE a partir de datos tributarios, en euros de {hitos[0]?.anio_base}; poboación do padrón a 1 de xaneiro. Nalgúns municipios pequenos o INE non publica o dato, sobre todo antes de 2020. Busca calquera municipio en <a href="/gl/territorios/municipios">O teu municipio en datos</a>.</p>

---

## Fontes oficiais

- **[INE – Enquisa de Condicións de Vida (ECV)](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176807&menu=ultiDatos&idp=1254735976608)**: táboas [9947](https://www.ine.es/jaxiT3/Tabla.htm?t=9947) e [9949](https://www.ine.es/jaxiT3/Tabla.htm?t=9949) (renda), [9963](https://www.ine.es/jaxiT3/Tabla.htm?t=9963) (risco de pobreza), [76847](https://www.ine.es/jaxiT3/Tabla.htm?t=76847) e [67240](https://www.ine.es/jaxiT3/Tabla.htm?t=67240) (AROPE), [9990](https://www.ine.es/jaxiT3/Tabla.htm?t=9990) (fin de mes), [76846](https://www.ine.es/jaxiT3/Tabla.htm?t=76846) (Gini e S80/S20) e [76844](https://www.ine.es/jaxiT3/Tabla.htm?t=76844) (renda por idade).
- **[INE – Atlas de Distribución de Renda dos Fogares](https://www.ine.es/jaxiT3/Tabla.htm?t=30824)**: renda por municipio e distrito ([táboa 30824](https://www.ine.es/jaxiT3/Tabla.htm?t=30824)) e por comunidade e provincia ([táboa 53689](https://www.ine.es/jaxiT3/Tabla.htm?t=53689)).
- **[Eurostat – EU-SILC](https://ec.europa.eu/eurostat/web/income-and-living-conditions)**: Gini ([ilc_di12](https://ec.europa.eu/eurostat/databrowser/view/ilc_di12/default/table)), S80/S20 ([ilc_di11](https://ec.europa.eu/eurostat/databrowser/view/ilc_di11/default/table)) e AROPE ([ilc_peps01n](https://ec.europa.eu/eurostat/databrowser/view/ilc_peps01n/default/table)).
- **INE – Índice de Prezos de Consumo**: para expresar os importes en euros constantes.

<LastRefreshed prefix="Datos actualizados" />
