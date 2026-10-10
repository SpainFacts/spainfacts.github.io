---
title: Vivenda pública en aluguer
description: "Cantas vivendas públicas en aluguer hai en España por habitante e en % dos fogares, por comunidade, provincia e municipio, comparadas cos Países Baixos, Austria, Dinamarca, Francia e a media europea, e segundo o partido que gobernaba."
i18n_origen: 911f5f63d748
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import EnConstruccion from '../../../../../../../src/lib/components/EnConstruccion.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT anio, ecv_pct_alquiler_inferior, ecv_pct_alquiler_mercado, calif_alquiler, calif_total, pct_calif_alquiler,
       calif_alquiler_100k, parque_autonomico_alquiler, parque_autonomico_1000hab, parque_publico_alquiler,
       parque_municipal_estimado, parque_publico_1000hab, pct_hogares_mivau, ocde_viviendas_sociales, ocde_pct_parque
FROM mother.vivienda_publica_espana
ORDER BY anio
```

```sql ecv
SELECT anio, 'Alquiler por debajo del precio de mercado' AS regimen, ecv_pct_alquiler_inferior AS pct FROM mother.vivienda_publica_espana WHERE ecv_pct_alquiler_inferior IS NOT NULL
UNION ALL
SELECT anio, 'Alquiler a precio de mercado' AS regimen, ecv_pct_alquiler_mercado AS pct FROM mother.vivienda_publica_espana WHERE ecv_pct_alquiler_mercado IS NOT NULL
ORDER BY anio, regimen
```

```sql calif
SELECT anio, calif_alquiler, calif_total, pct_calif_alquiler, calif_alquiler_100k
FROM mother.vivienda_publica_espana
WHERE calif_alquiler IS NOT NULL
ORDER BY anio
```

```sql resumen
SELECT
    max(parque_publico_alquiler) AS parque,
    max(parque_publico_1000hab) AS parque_1000,
    max(pct_hogares_mivau) AS pct_hogares,
    max(parque_municipal_estimado) AS municipal,
    max(parque_autonomico_alquiler) FILTER (WHERE anio = 2023) AS autonomico_2023,
    max(parque_autonomico_alquiler) FILTER (WHERE anio = 2019) AS autonomico_2019,
    max(parque_autonomico_1000hab) FILTER (WHERE anio = 2023) AS autonomico_1000_2023,
    100 * (max(parque_autonomico_alquiler) FILTER (WHERE anio = 2023) / max(parque_autonomico_alquiler) FILTER (WHERE anio = 2019) - 1) AS autonomico_var,
    max(ocde_pct_parque) AS ocde_pct,
    max(ocde_viviendas_sociales) AS ocde_viviendas,
    arg_max(ecv_pct_alquiler_inferior, anio) FILTER (WHERE ecv_pct_alquiler_inferior IS NOT NULL) AS ecv_ultimo,
    max(anio) FILTER (WHERE ecv_pct_alquiler_inferior IS NOT NULL) AS ecv_anio,
    sum(calif_alquiler) FILTER (WHERE anio BETWEEN 2005 AND 2008) / 4 AS calif_media_boom,
    sum(calif_alquiler) FILTER (WHERE anio BETWEEN 2013 AND 2017) / 5 AS calif_media_crisis,
    sum(calif_alquiler) FILTER (WHERE anio BETWEEN 2019 AND 2023) / 5 AS calif_media_reciente,
    arg_max(calif_alquiler, anio) FILTER (WHERE calif_alquiler IS NOT NULL) AS calif_ultimo,
    arg_max(calif_alquiler_100k, anio) FILTER (WHERE calif_alquiler IS NOT NULL) AS calif_ultimo_100k,
    max(anio) FILTER (WHERE calif_alquiler IS NOT NULL) AS calif_anio
FROM mother.vivienda_publica_espana
```

```sql ccaa
SELECT c.cod_ccaa, c.comunidad, '/gl' || t.ruta AS ruta, c.autonomico_2019, c.autonomico_2023, c.variacion_pct_2019_2023,
       c.autonomico_titularidad_2023, c.autonomico_ppp_2023, c.municipal_declarado, c.alquiler_publico_conocido,
       c.autonomico_1000hab, c.conocido_1000hab, c.conocido_pct_hogares, c.cobertura_municipal_pct,
       c.ecv_pct_alquiler_inferior_3a, c.ecv_anio, c.calif_alquiler_2005_2023, c.calif_alquiler_2005_2023_1000hab,
       c.venta_2023, c.opcion_compra_2023, c.otras_2023, c.familia_2019_2023, c.presidente_2019_2023
FROM mother.vivienda_publica_ccaa c
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = c.cod_ccaa
ORDER BY c.conocido_1000hab DESC
```

```sql ccaa_extremos
SELECT
    string_agg(comunidad, ', ' ORDER BY autonomico_1000hab DESC) FILTER (WHERE rk_mas <= 4) AS mas,
    string_agg(comunidad, ', ' ORDER BY autonomico_1000hab) FILTER (WHERE rk_menos <= 4) AS menos,
    string_agg(comunidad, ' y ' ORDER BY comunidad) FILTER (WHERE venta_2023 > autonomico_2023) AS mas_venta,
    max(100 * autonomico_ppp_2023 / autonomico_2023) FILTER (WHERE cod_ccaa = '16') AS ppp_pv,
    max(100 * autonomico_ppp_2023 / autonomico_2023) FILTER (WHERE cod_ccaa = '13') AS ppp_madrid
FROM (
    SELECT *,
        row_number() OVER (ORDER BY autonomico_1000hab DESC) AS rk_mas,
        row_number() OVER (ORDER BY autonomico_1000hab) AS rk_menos
    FROM mother.vivienda_publica_ccaa
    WHERE cod_ccaa NOT IN ('18', '19')
)
```

```sql ocde_ue
SELECT max(pct_parque_total) FILTER (WHERE cod_pais = 'EU27_2020') AS ue, max(pct_parque_total) FILTER (WHERE cod_pais = 'OECD') AS ocde
FROM mother.vivienda_publica_internacional
WHERE pct_parque_total IS NOT NULL AND es_ultimo
```

```sql provincias
SELECT p.cod_prov, p.provincia, p.comunidad, '/gl' || t.ruta AS ruta, p.municipal_declarado, p.municipios_con_dato, p.municipios_20k,
       p.cobertura_pct, p.municipal_1000hab, p.municipal_1000hab_con_dato, p.autonomico_2023, p.conocido_1000hab,
       CASE WHEN p.uniprovincial THEN 'Sí' ELSE 'No' END AS uniprovincial
FROM mother.vivienda_publica_provincias p
LEFT JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = p.cod_prov
ORDER BY p.municipal_1000hab DESC
```

```sql uniprovinciales
SELECT provincia, autonomico_2023, municipal_declarado, conocido_1000hab
FROM ${provincias}
WHERE uniprovincial = 'Sí'
ORDER BY conocido_1000hab DESC
```

```sql municipios
SELECT municipio, provincia, CAST(poblacion AS INTEGER) AS poblacion, alquiler, alquiler_1000hab, total,
       CASE origen WHEN 'encuesta_2023' THEN '2023' ELSE '2019 (no respondió en 2023)' END AS dato
FROM mother.vivienda_publica_municipios
WHERE origen <> 'sin_respuesta'
ORDER BY alquiler DESC
```

```sql cobertura_mun
SELECT
    CAST(count(*) AS INTEGER) AS municipios,
    CAST(count(*) FILTER (WHERE origen = 'encuesta_2023') AS INTEGER) AS respondieron,
    CAST(count(*) FILTER (WHERE origen = 'boletin_2020') AS INTEGER) AS dato_2019,
    CAST(count(*) FILTER (WHERE origen = 'sin_respuesta') AS INTEGER) AS sin_dato,
    CAST(sum(alquiler) AS INTEGER) AS alquiler
FROM mother.vivienda_publica_municipios
WHERE cod_prov NOT IN ('51', '52')
```

```sql ocde
SELECT pais, anio, pct_parque_total AS valor, CAST(viviendas_sociales AS INTEGER) AS viviendas_sociales,
       CASE WHEN es_espana THEN 'España' WHEN es_agregado THEN 'Media UE / OCDE' ELSE 'Otros países' END AS grupo
FROM mother.vivienda_publica_internacional
WHERE pct_parque_total IS NOT NULL AND es_ultimo
ORDER BY valor DESC
```

```sql ocde_evolucion
SELECT pais, anio, pct_parque_total AS valor
FROM mother.vivienda_publica_internacional
WHERE pct_parque_total IS NOT NULL AND destacado AND NOT es_agregado
ORDER BY pais, anio
```

```sql ue_hogares
SELECT pais, anio, pct_viviendas_principales AS valor,
       CASE WHEN es_espana THEN 'España' WHEN es_agregado THEN 'Media UE' ELSE 'Otros países' END AS grupo
FROM mother.vivienda_publica_internacional
WHERE pct_viviendas_principales IS NOT NULL
ORDER BY valor DESC
```

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo WHERE indicador_id = 'vivienda_social_pct'
```

```sql gobiernos
SELECT familia AS partido, color, anios_comunidad, comunidades, calif_alquiler, calif_alquiler_100k_anio,
       cuota_calif, cuota_poblacion, ratio_observado_esperado, anio_desde, anio_hasta
FROM mother.vivienda_publica_gobiernos
ORDER BY cuota_poblacion DESC
```

```sql calif_partido_anio
SELECT anio, familia AS partido, CAST(sum(calif_alquiler) AS INTEGER) AS calif_alquiler
FROM mother.vivienda_publica_ccaa_anual
WHERE calif_alquiler IS NOT NULL AND familia IS NOT NULL
GROUP BY ALL
ORDER BY anio, partido
```

```sql parque_partido
SELECT
    familia_2019_2023 AS partido,
    CAST(count(*) AS INTEGER) AS comunidades,
    CAST(sum(autonomico_2019) AS INTEGER) AS parque_2019,
    CAST(sum(autonomico_2023) AS INTEGER) AS parque_2023,
    100 * (sum(autonomico_2023) / sum(autonomico_2019) - 1) AS variacion_pct,
    1000 * (sum(autonomico_2023) - sum(autonomico_2019)) / sum(poblacion) AS variacion_1000hab,
    string_agg(comunidad, ', ' ORDER BY comunidad) AS lista
FROM mother.vivienda_publica_ccaa
GROUP BY 1
ORDER BY sum(poblacion) DESC
```

```sql pp_psoe
SELECT
    max(ratio_observado_esperado) FILTER (WHERE familia = 'PP') AS pp,
    max(ratio_observado_esperado) FILTER (WHERE familia = 'PSOE') AS psoe,
    max(calif_alquiler_100k_anio) FILTER (WHERE familia = 'PP') AS pp_100k,
    max(calif_alquiler_100k_anio) FILTER (WHERE familia = 'PSOE') AS psoe_100k
FROM mother.vivienda_publica_gobiernos
```

# 🏘️ Vivenda pública en aluguer

Cantas vivendas das administracións se alugan a prezos por debaixo dos de mercado a quen cumpre certos requisitos: as das comunidades autónomas e as súas empresas públicas e as dos concellos. Todo se amosa **por cada 1.000 habitantes ou en % dos fogares**, para poder comparar comunidades e países de tamaño moi distinto.

<Grid cols=4>
    <KpiCard
        title="Vivendas públicas en aluguer"
        value={resumen[0]?.parque_1000}
        formattedValue="{formatNumber(resumen[0]?.parque_1000, 1)} por 1.000 hab."
        period="estimación do Ministerio, 2023 · {formatCompact(resumen[0]?.parque, 0)} en total, o {formatNumber(resumen[0]?.pct_hogares, 2)} % dos fogares"
        direction="neutral"
        source="Ministerio de Vivenda"
    />
    <KpiCard
        title="Das comunidades autónomas"
        value={resumen[0]?.autonomico_1000_2023}
        formattedValue="{formatNumber(resumen[0]?.autonomico_1000_2023, 1)} por 1.000 hab."
        period="2023 · {formatCompact(resumen[0]?.autonomico_2023, 0)} vivendas en aluguer"
        change={resumen[0]?.autonomico_var?.toFixed(1)}
        changePeriod="fronte a 2019"
        direction="neutral"
        source="Ministerio de Vivenda (enquisa de vivenda social)"
        sparklineData={espana.filter(d => d.parque_autonomico_1000hab != null).map(d => ({...d, y: d.parque_autonomico_1000hab}))}
    />
    <KpiCard
        title="Fogares con aluguer por debaixo de mercado"
        value={resumen[0]?.ecv_ultimo}
        formattedValue="{formatNumber(resumen[0]?.ecv_ultimo, 1)} %"
        period="dos fogares, {resumen[0]?.ecv_anio} · inclúe alugueres reducidos privados"
        direction="neutral"
        source="INE (Enquisa de Condicións de Vida)"
        sparklineData={espana.filter(d => d.ecv_pct_alquiler_inferior != null).map(d => ({...d, y: d.ecv_pct_alquiler_inferior}))}
    />
    <KpiCard
        title="Vivendas protexidas en aluguer"
        value={resumen[0]?.calif_ultimo_100k}
        formattedValue="{formatNumber(resumen[0]?.calif_ultimo_100k, 1)} por 100.000 hab."
        period="cualificacións provisionais, {resumen[0]?.calif_anio} · {formatNumber(resumen[0]?.calif_ultimo, 0)} vivendas"
        direction="neutral"
        source="Ministerio de Vivenda"
        sparklineData={calif.map(d => ({...d, y: d.calif_alquiler_100k}))}
    />
</Grid>

<Comparativa data={comparativa_internacional} decimales={1} />

## Cantas hai

O Ministerio de Vivenda preguntoulles en 2023 ás comunidades autónomas e aos concellos de máis de 20.000 habitantes cantas vivendas teñen e en que réxime. Con esas respostas estima que en España hai unhas **{formatNumber(resumen[0]?.parque, 0)} vivendas públicas en aluguer**: {formatNumber(resumen[0]?.autonomico_2023, 0)} das comunidades (suma das súas respostas) e unhas {formatNumber(resumen[0]?.municipal, 0)} dos concellos (unha cifra escalada por poboación, porque moitos non responderon). Son {formatNumber(resumen[0]?.parque_1000, 1)} por cada 1.000 habitantes e chegan ao {formatNumber(resumen[0]?.pct_hogares, 2)} % dos fogares.

O parque das comunidades en aluguer pasou de {formatNumber(resumen[0]?.autonomico_2019, 0)} vivendas en 2019 a {formatNumber(resumen[0]?.autonomico_2023, 0)} en 2023, un {formatNumber(resumen[0]?.autonomico_var, 1)} % máis. Non hai unha serie anual: o Ministerio só fixo estas dúas enquisas.

A Enquisa de Condicións de Vida do INE dá unha serie longa, pero máis ampla: conta os fogares que pagan un aluguer **por debaixo do prezo de mercado**, o que inclúe a vivenda pública pero tamén pisos de empresa ou alugueres reducidos entre particulares (por iso sae máis alta).

<LineChart
    data={ecv}
    x=anio
    y=pct
    series=regimen
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% dos fogares"
    title="Fogares en aluguer segundo o prezo que pagan (% de todos os fogares)"
/>

## Cantas se promoven cada ano

As **cualificacións provisionais** son o primeiro paso administrativo dunha vivenda protexida: cantas se poñen en marcha cada ano e con que destino. Entre 2005 e 2008 cualificábanse de media {formatNumber(resumen[0]?.calif_media_boom, 0)} vivendas protexidas en aluguer ao ano; entre 2013 e 2017, {formatNumber(resumen[0]?.calif_media_crisis, 0)}; entre 2019 e 2023, {formatNumber(resumen[0]?.calif_media_reciente, 0)}. Non todas son públicas (tamén as promoven empresas privadas con axudas) nin todas acaban construíndose.

<BarChart
    data={calif}
    x=anio
    y=calif_alquiler_100k
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="por 100.000 habitantes"
    title="Vivendas protexidas en aluguer cualificadas cada ano por 100.000 habitantes"
/>

<LineChart
    data={calif}
    x=anio
    y=pct_calif_alquiler
    xFmt='0'
    yFmt='0'
    yAxisTitle="% das cualificacións"
    title="Peso do aluguer na vivenda protexida cualificada cada ano (%)"
/>

## España fronte a outros países

A OCDE reúne as cifras que dan os propios gobernos: vivendas sociais en aluguer (renda por debaixo de mercado e adxudicadas por regras, non por prezo) en **% de todo o parque de vivendas**. España declarou {formatNumber(resumen[0]?.ocde_viviendas, 0)} en 2019, o {formatNumber(resumen[0]?.ocde_pct, 1)} % do parque, entre os máis baixos da OCDE; a media da UE é o {formatNumber(ocde_ue[0]?.ue, 1)} % e a da OCDE, o {formatNumber(ocde_ue[0]?.ocde, 1)} %.

<BarChart
    data={ocde}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% do parque total de vivendas"
    seriesColors={{'España': '#dc2626', 'Media UE / OCDE': '#64748b', 'Otros países': '#93c5fd'}}
    title="Vivendas sociais en aluguer, % do parque total (último dato de cada país)"
/>

Cada país define a vivenda social ao seu xeito (nos Países Baixos conta tamén aluguer privado por debaixo de mercado; en Austria, só vivendas principais), así que a comparación é orientativa. Nos países con máis vivenda social o peso baixou algo desde 2010:

<LineChart
    data={ocde_evolucion}
    x=anio
    y=valor
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="% do parque total"
    markers=true
    title="Vivenda social en aluguer arredor de 2010 e arredor de 2022 (% do parque total)"
/>

O Ministerio compara tamén en **% dos fogares** (vivendas principais) con datos de Housing Europe e Eurostat. Para España usa a ECV, que mide algo máis amplo; engádese a cifra do parque público do propio Ministerio para velas xuntas:

<BarChart
    data={ue_hogares}
    x=pais
    y=valor
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="% dos fogares"
    seriesColors={{'España': '#dc2626', 'Media UE': '#64748b', 'Otros países': '#93c5fd'}}
    title="Vivenda en aluguer social na UE, % das vivendas principais (2023 ou 2017)"
/>

## Por comunidade

Vivendas públicas en aluguer que se coñecen por cada 1.000 habitantes: as da comunidade (dato completo de 2023) máis as dos concellos de máis de 20.000 habitantes que responderon á enquisa (dato parcial). Preme nunha comunidade para ver a súa ficha.

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod_ccaa"
    value="conocido_1000hab"
    valueFmt='0.0'
    link="ruta"
    colorPalette={['#ecfdf5', '#10b981', '#064e3b']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio de Vivenda"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'conocido_1000hab', title: 'Por 1.000 hab. (comunidade + concellos)', fmt: '0.0'},
        {id: 'autonomico_1000hab', title: 'Só da comunidade, por 1.000 hab.', fmt: '0.0'},
        {id: 'conocido_pct_hogares', title: '% dos fogares', fmt: '0.00'},
        {id: 'variacion_pct_2019_2023', title: 'Parque autonómico, var. 2019-2023 (%)', fmt: '0'}
    ]}
/>

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidade" />
    <Column id=conocido_1000hab title="Por 1.000 hab." fmt='0.0' />
    <Column id=conocido_pct_hogares title="% fogares" fmt='0.00' />
    <Column id=autonomico_2023 title="Da comunidade (2023)" fmt='#,##0' />
    <Column id=variacion_pct_2019_2023 title="Var. 2019-2023 %" fmt='0' contentType=delta />
    <Column id=municipal_declarado title="De concellos (declarado)" fmt='#,##0' />
    <Column id=cobertura_municipal_pct title="% poboación con dato municipal" fmt='0' />
    <Column id=ecv_pct_alquiler_inferior_3a title="% fogares baixo mercado (ECV, 3 anos)" fmt='0.0' />
</DataTable>

Sen contar Ceuta e Melilla, os parques autonómicos en aluguer máis grandes por habitante son os de {ccaa_extremos[0]?.mas}; os máis pequenos, os de {ccaa_extremos[0]?.menos}. En {ccaa_extremos[0]?.mas_venta?.replace(' y ', ' e ')} a comunidade ten máis vivendas destinadas á venda ca ao aluguer, e noutras pesa a colaboración público-privada (solo público con dereito de superficie ou concesión): é o {formatNumber(ccaa_extremos[0]?.ppp_pv, 0)} % do parque autonómico en aluguer do País Vasco e o {formatNumber(ccaa_extremos[0]?.ppp_madrid, 0)} % do de Madrid.

<BarChart
    data={ccaa}
    x=comunidad
    y=calif_alquiler_2005_2023_1000hab
    swapXY=true
    yFmt='0.0'
    yAxisTitle="por 1.000 habitantes"
    title="Vivendas protexidas en aluguer cualificadas entre 2005 e 2023, por 1.000 habitantes de hoxe"
/>

## Por provincia

Non existe un reconto oficial do parque autonómico por provincia: as comunidades declárano en bloque. O que si se coñece por provincia é o **parque municipal en aluguer que declararon os concellos de máis de 20.000 habitantes** ({cobertura_mun[0]?.respondieron} responderon en 2023, {cobertura_mun[0]?.dato_2019} repiten o seu dato de 2019 e {cobertura_mun[0]?.sin_dato} non deron cifras). O mapa amósao por 1.000 habitantes da provincia; unha provincia en branco pode ter parque autonómico, ou municipios que non responderon.

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="municipal_1000hab"
    valueFmt='0.00'
    link="ruta"
    colorPalette={['#ecfdf5', '#10b981', '#064e3b']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio de Vivenda"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'municipal_1000hab', title: 'Vivenda municipal en aluguer por 1.000 hab.', fmt: '0.00'},
        {id: 'municipal_declarado', title: 'Vivendas municipais declaradas', fmt: '#,##0'},
        {id: 'cobertura_pct', title: '% da poboación en municipios con dato', fmt: '0'},
        {id: 'conocido_1000hab', title: 'Co parque autonómico (uniprovinciais)', fmt: '0.0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Provincia" />
    <Column id=comunidad title="Comunidade" />
    <Column id=municipal_1000hab title="Municipal por 1.000 hab." fmt='0.00' />
    <Column id=municipal_declarado title="Vivendas municipais" fmt='#,##0' />
    <Column id=municipios_con_dato title="Municipios con dato" fmt='0' />
    <Column id=municipios_20k title="Municipios de máis de 20.000 hab." fmt='0' />
    <Column id=cobertura_pct title="% poboación con dato" fmt='0' />
</DataTable>

Nas comunidades dunha soa provincia (e en Ceuta e Melilla) o parque autonómico si é provincial e pódese sumar ao municipal:

<DataTable data={uniprovinciales} rows=9>
    <Column id=provincia title="Provincia" />
    <Column id=conocido_1000hab title="Por 1.000 hab. (comunidade + concellos)" fmt='0.0' />
    <Column id=autonomico_2023 title="Da comunidade" fmt='#,##0' />
    <Column id=municipal_declarado title="De concellos (declarado)" fmt='#,##0' />
</DataTable>

<EnConstruccion motivo="o parque de vivenda das comunidades por provincia non se publica: a enquisa do Ministerio recólleo só por comunidade. Algunhas empresas autonómicas (a Agència de l'Habitatge de Catalunya, Alokabide, a AVRA andaluza...) publican o seu parque por municipio en formatos distintos; integralas daría o mapa provincial completo." />

## Por municipio

Vivendas dos concellos e as súas empresas municipais (non inclúe as da comunidade situadas no municipio), nos municipios de máis de 20.000 habitantes con dato.

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=alquiler title="En aluguer" fmt='#,##0' />
    <Column id=alquiler_1000hab title="Por 1.000 hab." fmt='0.0' />
    <Column id=total title="Total do parque municipal" fmt='#,##0' />
    <Column id=poblacion title="Poboación" fmt='#,##0' />
    <Column id=dato title="Dato de" />
</DataTable>

## Por partido

A vivenda protexida cualifícana as comunidades autónomas, aínda que boa parte se financia cos plans estatais de vivenda. Sumando comunidades e anos entre {gobiernos[0]?.anio_desde} e {gobiernos[0]?.anio_hasta}, e atribuíndo cada ano ao partido que gobernaba a comunidade o 1 de xullo, compárase a parte das vivendas protexidas en aluguer cualificadas con cada partido coa parte da poboación que gobernou (se todos promovesen o mesmo por habitante, a razón sería 1). Co PP a razón é {formatNumber(pp_psoe[0]?.pp, 2)} ({formatNumber(pp_psoe[0]?.pp_100k, 1)} vivendas por 100.000 habitantes e ano) e co PSOE, {formatNumber(pp_psoe[0]?.psoe, 2)} ({formatNumber(pp_psoe[0]?.psoe_100k, 1)}).

<DataTable data={gobiernos} rows=12>
    <Column id=partido title="Partido que gobernaba" />
    <Column id=anios_comunidad title="Anos de goberno (comunidade x ano)" fmt='0' />
    <Column id=calif_alquiler title="Vivendas en aluguer cualificadas" fmt='#,##0' />
    <Column id=calif_alquiler_100k_anio title="Por 100.000 hab. e ano" fmt='0.0' />
    <Column id=cuota_calif title="% das cualificadas" fmt='0.0' />
    <Column id=cuota_poblacion title="% da poboación gobernada" fmt='0.0' />
    <Column id=ratio_observado_esperado title="Observado / esperado" fmt='0.00' />
</DataTable>

<BarChart
    data={calif_partido_anio}
    x=anio
    y=calif_alquiler
    series=partido
    xFmt='0'
    yFmt='#,##0'
    seriesColors={Object.fromEntries(gobiernos.map(d => [d.partido, d.color]))}
    title="Vivendas protexidas en aluguer cualificadas cada ano, segundo o partido que gobernaba cada comunidade"
/>

Cambio do parque autonómico en aluguer entre 2019 e 2023, agrupando as comunidades polo partido que as gobernaba a metade dese período:

<DataTable data={parque_partido} rows=10>
    <Column id=partido title="Partido (xullo de 2021)" />
    <Column id=comunidades title="Comunidades" fmt='0' />
    <Column id=parque_2019 title="Parque 2019" fmt='#,##0' />
    <Column id=parque_2023 title="Parque 2023" fmt='#,##0' />
    <Column id=variacion_pct title="Var. %" fmt='0.0' contentType=delta />
    <Column id=variacion_1000hab title="Var. por 1.000 hab." fmt='0.00' contentType=delta />
    <Column id=lista title="Comunidades" wrap=true />
</DataTable>

Hai que lelo con cautela: son poucos anos e poucas comunidades por partido, a vivenda tarda anos en pasar da cualificación á entrega (moitas vivendas dun mandato decidiunas o anterior), e o parque tamén cambia por vendas aos inquilinos, traspasos entre administracións ou recontos distintos en cada enquisa. As vivendas non chegan unha a unha senón en promocións, así que non ten sentido unha proba estatística como noutras páxinas.

## Metodoloxía e fontes

- **Parque público en aluguer**: [Ministerio de Vivenda e Axenda Urbana, Observatorio de Vivenda e Solo, Boletín especial Vivenda Social 2024](https://www.mivau.gob.es/urbanismo-y-suelo/suelo/observatorio-de-vivienda-y-suelo) (Enquisa sobre vivenda social de 2023 e, para 2019, a de 2019). «En aluguer» inclúe as vivendas de titularidade pública e as de colaboración público-privada (solo público con dereito de superficie ou concesión), a cesión a baixo prezo e o aloxamento temporal; non inclúe o aluguer con opción de compra nin a venda. O total nacional de 2023 é a suma das comunidades (o boletín dá unha cifra algo menor na súa táboa de evolución). O parque municipal só recolle os concellos de máis de 20.000 habitantes que responderon (ou o seu dato de 2019 se non o fixeron); o Ministerio escálao por poboación para a súa estimación nacional. En Ceuta e Melilla a cidade é á vez comunidade e concello e o seu parque cóntase unha vez.
- **Cualificacións provisionais** de vivenda protexida por réxime de uso e comunidade, 2005-2023, do mesmo boletín.
- **Fogares en aluguer por debaixo de mercado**: [INE, Enquisa de Condicións de Vida, táboa 9997](https://www.ine.es/jaxiT3/Tabla.htm?t=9997). É unha enquisa: nas comunidades pequenas a mostra é reducida e amósase a media dos tres últimos anos.
- **Comparación internacional**: [OCDE, Affordable Housing Database, indicador PH4.2](https://www.oecd.org/en/data/datasets/oecd-affordable-housing-database.html) (% do parque total de vivendas, arredor de 2010 e arredor de 2022, coas medias UE e OCDE da propia OCDE; para España pode incluír vivendas de empresa) e a táboa 2.1 do boletín do Ministerio (Housing Europe e Eurostat, % das vivendas principais).
- **Poboación** do padrón (INE) a 1 de xaneiro de 2023 e **fogares** da Estatística Continua de Poboación; partido de cada Goberno autonómico segundo a táboa de presidentes de SpainFacts.
