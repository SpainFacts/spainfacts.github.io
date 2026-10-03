---
title: Criminalidade
description: "Delitos coñecidos en España por tipo, comunidade, provincia e municipio desde 2010, evolución da cibercriminalidade e condenados por nacionalidade co seu contexto."
i18n_origen: 865a8f911a6a
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT anio, categoria, infracciones, tasa_1000
FROM mother.crimen_balance
WHERE nivel = 'pais'
ORDER BY anio
```

```sql resumen
WITH u AS (SELECT max(anio) AS anio FROM ${espana})
SELECT
    u.anio,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Total infracciones penales' AND e.anio = u.anio) AS total,
    max(e.tasa_1000) FILTER (WHERE e.categoria = 'Total infracciones penales' AND e.anio = u.anio) AS tasa,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Total infracciones penales' AND e.anio = 2019) AS total_2019,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Homicidios y asesinatos consumados' AND e.anio = u.anio) AS homicidios,
    max(e.tasa_1000) FILTER (WHERE e.categoria = 'Homicidios y asesinatos consumados' AND e.anio = u.anio) * 100 AS homicidios_100k,
    max(e.infracciones) FILTER (WHERE e.categoria = 'Cibercriminalidad' AND e.anio = u.anio) AS ciber
FROM ${espana} e, u
GROUP BY u.anio
```

```sql serie_kpi
-- Historia para los sparklines, en tasa por 1.000 habitantes: Balance (2019-) y, antes, la serie larga (2010-2018)
WITH b AS (
    SELECT anio, categoria, tasa_1000
    FROM mother.crimen_balance
    WHERE nivel = 'pais' AND categoria IN ('Total infracciones penales', 'Homicidios y asesinatos consumados')
),
l AS (
    SELECT
        anio,
        CASE WHEN tipologia = 'TOTAL INFRACCIONES PENALES' THEN 'Total infracciones penales' ELSE 'Homicidios y asesinatos consumados' END AS categoria,
        max(tasa_1000) AS tasa_1000
    FROM mother.crimen_serie_larga
    WHERE nivel = 'pais' AND (tipologia = 'TOTAL INFRACCIONES PENALES' OR codigo_tipologia = '1.1.1')
    GROUP BY 1, 2
)
SELECT anio, categoria, tasa_1000 FROM b
UNION ALL
SELECT anio, categoria, tasa_1000 FROM l WHERE anio < (SELECT min(anio) FROM b)
ORDER BY categoria, anio
```

```sql semestre
SELECT periodo, anio, infracciones, infracciones_anio_anterior, infracciones / infracciones_anio_anterior - 1 AS variacion
FROM mother.crimen_ultimo_periodo
WHERE nivel = 'pais' AND categoria = 'Total infracciones penales'
```

# 🚨 Criminalidade

Os delitos que coñecen a Policía Nacional, a Garda Civil, os Mossos d'Esquadra, a Ertzaintza, a Policía Foral de Navarra e as policías locais, segundo o Ministerio do Interior.

<Grid cols=4>
    <KpiCard
        title="Infraccións penais coñecidas"
        value={resumen[0]?.total}
        formattedValue="{formatNumber(resumen[0]?.tasa, 1)} por 1.000 hab."
        period="{formatCompact(resumen[0]?.total, 2)} en total · {resumen[0]?.anio}"
        change={resumen[0]?.total_2019 ? (100 * (resumen[0].total / resumen[0].total_2019 - 1)).toFixed(1) : null}
        changeUnit=" %"
        changePeriod="fronte a 2019"
        direction="positive-down"
        source="Ministerio do Interior"
        sparklineData={serie_kpi.filter(d => d.categoria === 'Total infracciones penales').map(d => d.tasa_1000)}
    />
    <KpiCard
        title="Homicidios e asasinatos"
        value={resumen[0]?.homicidios}
        formattedValue="{formatNumber(resumen[0]?.homicidios_100k, 2)} por 100.000 hab."
        period="{formatNumber(resumen[0]?.homicidios, 0)} consumados en {resumen[0]?.anio}"
        source="Ministerio do Interior"
        sparklineData={serie_kpi.filter(d => d.categoria === 'Homicidios y asesinatos consumados').map(d => d.tasa_1000 * 100)}
    />
    <KpiCard
        title="Cibercriminalidade"
        value={resumen[0]?.ciber}
        formattedValue="{formatNumber(resumen[0]?.ciber / resumen[0]?.total / 0.01, 0)} %"
        period="{formatNumber(resumen[0]?.ciber / 1000, 0)} mil infraccións por internet, sobre todo estafas"
        source="Ministerio do Interior"
        sparklineData={espana.filter(d => d.categoria === 'Cibercriminalidad').map(d => 100 * d.infracciones / (espana.find(t => t.anio === d.anio && t.categoria === 'Total infracciones penales')?.infracciones ?? NaN)).filter(v => Number.isFinite(v))}
    />
    <KpiCard
        title="Este ano ({semestre[0]?.periodo})"
        value={semestre[0]?.infracciones}
        formattedValue={formatCompact(semestre[0]?.infracciones, 2)}
        change={semestre[0]?.variacion != null ? (100 * semestre[0].variacion).toFixed(1) : null}
        changeUnit=" %"
        changePeriod="fronte ao mesmo período de {semestre[0]?.anio - 1}"
        direction="positive-down"
        source="Balance de Criminalidade"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('homicidios')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'homicidios')} />


<p class="text-xs text-gray-500">Todas as cifras danse por habitante para que a evolución non reflicta só o crecemento da poboación (España gañou uns 2 millóns de habitantes entre 2019 e 2025); o total aparece como dato secundario. Son feitos <b>coñecidos</b> (denunciados ou descubertos pola policía), non todos os delitos cometidos: unha suba pode deberse a que se denuncia máis (como pasou cos delitos sexuais ou as estafas por internet). A taxa por habitante non ten en conta os turistas e visitantes, que tamén sofren e cometen delitos: por iso sae alta nas zonas máis turísticas.</p>

## Que delitos e como evolucionan

```sql categorias
SELECT categoria, infracciones, tasa_1000 * 100 AS tasa_100k
FROM ${espana}
WHERE anio = (SELECT max(anio) FROM ${espana})
  AND categoria NOT IN ('Total infracciones penales', 'Criminalidad convencional', 'Cibercriminalidad', 'Resto de infracciones',
                        'Robos con fuerza en domicilios', 'Delitos contra la libertad sexual')
ORDER BY infracciones DESC
```

<BarChart
    data={categorias}
    x=categoria
    y=tasa_100k
    swapXY=true
    sort=false
    yFmt=num0
    yAxisTitle="por 100.000 habitantes"
    fillColor="#b91c1c"
    title="Principais delitos coñecidos en {resumen[0]?.anio}, por 100.000 habitantes"
/>

```sql convencional_ciber
SELECT anio, categoria, infracciones, tasa_1000
FROM ${espana}
WHERE categoria IN ('Criminalidad convencional', 'Cibercriminalidad')
ORDER BY anio
```

<BarChart
    data={convencional_ciber}
    x=anio
    y=tasa_1000
    series=categoria
    type=stacked
    yFmt=num1
    yAxisTitle="por 1.000 habitantes"
    xFmt="####"
    colorPalette={['#b91c1c', '#7c3aed']}
    title="Criminalidade convencional e por internet, por 1.000 habitantes"
/>

<p class="text-xs text-gray-500">2020 é o ano do confinamento. Desde 2019 o Ministerio conta á parte a cibercriminalidade (estafas e outros delitos cometidos por internet), que medrou moito máis ca o resto.</p>

```sql serie_larga
SELECT anio, tipologia, infracciones, tasa_1000 * 100 AS tasa_100k
FROM mother.crimen_serie_larga
WHERE nivel = 'pais' AND codigo_tipologia IN ('1.1.1', '3.2', '5.1', '5.2.2', '5.3', '5.5.1', '6.1')
ORDER BY anio
```

<LineChart
    data={serie_larga}
    x=anio
    y=tasa_100k
    series=tipologia
    yFmt=num1
    yAxisTitle="por 100.000 habitantes"
    xFmt="####"
    yLog=true
    legend=true
    title="Algúns delitos desde 2010 por 100.000 habitantes (escala logarítmica)"
/>

<p class="text-xs text-gray-500">Escala logarítmica para ver xuntos delitos moi distintos en número: unha pendente igual é un mesmo ritmo de crecemento. As estafas informáticas multiplicáronse desde 2016, os roubos en vivendas baixaron e as agresións sexuais con penetración coñecidas aumentaron, en parte porque se denuncian máis.</p>

## Por territorio

```sql ccaa
SELECT b.cod, t.nombre AS comunidad, '/gl' || t.ruta AS ruta, b.infracciones, b.tasa_1000
FROM mother.crimen_balance b
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = b.cod
WHERE b.nivel = 'ccaa' AND b.categoria = 'Total infracciones penales' AND b.anio = (SELECT max(anio) FROM mother.crimen_balance)
ORDER BY b.tasa_1000 DESC
```

```sql provincias
SELECT b.cod, t.nombre AS provincia, b.infracciones, b.tasa_1000
FROM mother.crimen_balance b
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = b.cod
WHERE b.nivel = 'provincia' AND b.categoria = 'Total infracciones penales' AND b.anio = (SELECT max(anio) FROM mother.crimen_balance)
```

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod"
    value="tasa_1000"
    valueFmt="num1"
    colorPalette={['#fef2f2', '#f87171', '#7f1d1d']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: Ministerio do Interior"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_1000', title: 'Infraccións por 1.000 hab.', fmt: 'num1'},
        {id: 'infracciones', title: 'Infraccións', fmt: 'num0'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidade" />
    <Column id=infracciones title="Infraccións coñecidas" fmt=num0 />
    <Column id=tasa_1000 title="Por 1.000 hab." fmt=num1 contentType=bar barColor="#fecaca" />
</DataTable>

```sql municipios
WITH u AS (SELECT max(anio) AS anio FROM mother.crimen_balance WHERE nivel = 'municipio')
SELECT
    b.cod AS cod_mun,
    b.territorio AS municipio,
    p.nombre AS provincia,
    b.poblacion,
    max(b.infracciones) FILTER (WHERE b.categoria = 'Total infracciones penales') AS infracciones,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Total infracciones penales') AS tasa_1000,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Hurtos') AS hurtos_1000,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Robos con violencia o intimidación') AS robos_violencia_1000,
    max(b.tasa_1000) FILTER (WHERE b.categoria = 'Robos con fuerza en domicilios') AS robos_domicilios_1000,
    '/gl/territorios/municipios?m=' || b.cod AS enlace
FROM mother.crimen_balance b
JOIN u ON b.anio = u.anio
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = left(b.cod, 2)
WHERE b.nivel = 'municipio'
GROUP BY ALL
ORDER BY tasa_1000 DESC
```

### Municipios de máis de 20.000 habitantes ({resumen[0]?.anio})

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=tasa_1000 title="Infraccións por 1.000 hab." fmt=num1 contentType=bar barColor="#fecaca" />
    <Column id=hurtos_1000 title="Furtos" fmt=num1 />
    <Column id=robos_violencia_1000 title="Roubos con violencia" fmt=num1 />
    <Column id=robos_domicilios_1000 title="Roubos en domicilios" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">Encabezan a lista municipios con aeroporto, porto ou moito turismo (El Prat de Llobregat, Adeje, Sant Josep de sa Talaia, Calvià...): alí denúncianse moitos delitos contra visitantes e pasaxeiros, pero a taxa divídese só entre os veciños empadroados. Taxas por 1.000 habitantes empadroados.</p>

## Condenados por nacionalidade

```sql condenados
SELECT anio, sexo, nacionalidad, condenados, poblacion_18, tasa_1000
FROM mother.crimen_condenados
WHERE cod_ccaa = '00' AND nacionalidad IN ('Española', 'Extranjera')
ORDER BY anio
```

```sql condenados_ultimo
SELECT
    max(anio) AS anio,
    max(condenados) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera') AS extranjeros,
    max(condenados) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Española') AS espanoles,
    max(poblacion_18) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera') AS pob_extranjera,
    max(poblacion_18) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Española') AS pob_espanola,
    max(tasa_1000) FILTER (WHERE sexo = 'Hombres' AND nacionalidad = 'Extranjera') AS h_ext,
    max(tasa_1000) FILTER (WHERE sexo = 'Hombres' AND nacionalidad = 'Española') AS h_esp,
    max(tasa_1000) FILTER (WHERE sexo = 'Mujeres' AND nacionalidad = 'Extranjera') AS m_ext,
    max(tasa_1000) FILTER (WHERE sexo = 'Mujeres' AND nacionalidad = 'Española') AS m_esp,
    100.0 * max(condenados) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera')
        / sum(condenados) FILTER (WHERE sexo = 'Total') AS pct_condenados_extranjeros,
    100.0 * max(poblacion_18) FILTER (WHERE sexo = 'Total' AND nacionalidad = 'Extranjera')
        / sum(poblacion_18) FILTER (WHERE sexo = 'Total') AS pct_poblacion_extranjera
FROM ${condenados}
WHERE anio = (SELECT max(anio) FROM ${condenados})
```

Segundo a Estatística de Condenados do INE, en {condenados_ultimo[0]?.anio} foron condenados en firme {formatNumber(condenados_ultimo[0]?.espanoles, 0)} adultos de nacionalidade española e {formatNumber(condenados_ultimo[0]?.extranjeros, 0)} de nacionalidade estranxeira ({formatNumber(condenados_ultimo[0]?.pct_condenados_extranjeros, 0)} % do total), cando os estranxeiros son o {formatNumber(condenados_ultimo[0]?.pct_poblacion_extranjera, 0)} % dos residentes adultos.

```sql tasas_sexo
SELECT anio, sexo || ', ' || lower(nacionalidad) AS grupo, tasa_1000
FROM ${condenados}
WHERE sexo IN ('Hombres', 'Mujeres')
ORDER BY anio
```

<LineChart
    data={tasas_sexo}
    x=anio
    y=tasa_1000
    series=grupo
    yFmt=num1
    xFmt="####"
    legend=true
    colorPalette={['#1d4ed8', '#93c5fd', '#b91c1c', '#fca5a5']}
    yAxisTitle="condenados por 1.000 residentes de 18+ anos"
    title="Condenados por 1.000 residentes adultos do seu mesmo sexo e nacionalidade"
/>

<div class="not-prose rounded-lg border border-amber-300 bg-amber-50 dark:bg-amber-950/40 dark:border-amber-700 p-4 my-4 text-sm text-amber-900 dark:text-amber-100">
<p class="font-semibold mb-1">Como ler esta comparación</p>
<ul class="list-disc ml-5 space-y-1">
<li><b>A taxa dos estranxeiros está sobreestimada.</b> Entre os condenados de nacionalidade estranxeira hai turistas, persoas en tránsito e persoas en situación irregular que non figuran no padrón, así que están no numerador pero non no denominador.</li>
<li><b>A idade e o sexo pesan moito.</b> En calquera país a gran maioría dos condenados son homes novos, e a poboación estranxeira ten máis homes novos ca a española. Por iso aquí compáranse homes con homes e mulleres con mulleres ({formatNumber(condenados_ultimo[0]?.h_ext, 1)} fronte a {formatNumber(condenados_ultimo[0]?.h_esp, 1)} por mil en homes; {formatNumber(condenados_ultimo[0]?.m_ext, 1)} fronte a {formatNumber(condenados_ultimo[0]?.m_esp, 1)} en mulleres). Non é posible axustar por idade: o INE non cruza a idade e a nacionalidade dos condenados.</li>
<li><b>Outros factores</b> que esta estatística non recolle e que nos estudos explican parte da diferenza: nivel de renda, emprego, nivel de estudos ou o barrio de residencia.</li>
<li>Son persoas condenadas, non detidas nin investigadas: xa houbo un xuízo. Cóntase na comunidade do xulgado que condena.</li>
</ul>
</div>

```sql delitos_nacionalidad
SELECT delito, total, extranjera / total AS cuota_extranjera
FROM mother.crimen_condenas_delito
WHERE anio = (SELECT max(anio) FROM mother.crimen_condenas_delito)
  AND delito IN ('Homicidio y sus formas', 'Lesiones', 'Contra la libertad', 'Contra la libertad e indemnidad sexuales', 'Hurtos', 'Robos',
                 'Contra la seguridad vial', 'Contra la salud pública', 'Defraudaciones', 'Contra la Administración de Justicia', 'Quebrantamiento de condena',
                 'Contra las relaciones familiares', 'Falsedades')
ORDER BY total DESC
```

<DataTable data={delitos_nacionalidad} rows=all>
    <Column id=delito title="Delito" />
    <Column id=total title="Delitos condenados" fmt=num0 />
    <Column id=cuota_extranjera title="Con condenado estranxeiro" fmt=pct0 contentType=bar barColor="#fecaca" />
</DataTable>

<p class="text-xs text-gray-500">Delitos polos que se condenou en {condenados_ultimo[0]?.anio} (un condenado pode selo por varios delitos) e porcentaxe nos que o condenado tiña nacionalidade estranxeira. Os nacionalizados españois contan como españois.</p>

---

## Fontes e notas

- **[Ministerio do Interior – Portal Estatístico de Criminalidade](https://estadisticasdecriminalidad.ses.mir.es/)**: serie anual de infraccións penais coñecidas por comunidade e provincia desde 2010, e Balance de Criminalidade trimestral cos municipios de máis de 20.000 habitantes (ano completo desde 2019). En 2019 cambiou a clasificación do Balance, así que non se compara cos anos anteriores.
- **[INE – Estatística de Condenados: adultos](https://www.ine.es/jaxiT3/Tabla.htm?t=25704)** (táboas 25704 e 49050), a partir do Rexistro Central de Penados, e **[INE – Estatística Continua de Poboación](https://www.ine.es/jaxiT3/Tabla.htm?t=56942)** (táboa 56942) para a poboación por nacionalidade, sexo e idade a 1 de xaneiro. Poboación de 18 ou máis anos aproximada a partir de grupos de idade de cinco anos.

<LastRefreshed prefix="Datos actualizados" />
