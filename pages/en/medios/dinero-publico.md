---
title: Public money in the media
description: "How much public money the media in Spain receive: funding for RTVE and the regional broadcasters, central government institutional and commercial advertising by media group and subsidies to private media, per inhabitant and adjusted for inflation, by region and by party."
i18n_origen: 99497b7340e4
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
</script>

```sql tv_espana
SELECT CAST(anio AS INTEGER) AS anio, rtve_eur_hab_real, autonomicas_eur_hab_real, total_eur_hab_real,
       rtve_meur_nominal, autonomicas_meur_nominal, total_meur_nominal, cuota_la1, anio_base
FROM mother.medios_tv_espana_anual
ORDER BY anio
```

```sql tv_espana_ult
SELECT * FROM ${tv_espana} WHERE total_eur_hab_real IS NOT NULL ORDER BY anio DESC LIMIT 1
```

```sql tv_series
SELECT anio, 'RTVE' AS serie, rtve_eur_hab_real AS eur_hab FROM ${tv_espana}
UNION ALL
SELECT anio, 'Radios y televisiones autonómicas' AS serie, autonomicas_eur_hab_real AS eur_hab FROM ${tv_espana} WHERE autonomicas_eur_hab_real IS NOT NULL
ORDER BY anio, serie
```

```sql tv_ccaa
SELECT t.cod_ccaa, t.nombre AS comunidad, t.ente, CAST(t.anio AS INTEGER) AS anio,
       t.eur_hab_real, t.meur_nominal, t.cuota_audiencia, t.canal_principal,
       t.eur_hab_real_por_punto_cuota, t.familia, t.presidente,
       '/en' || c.ruta AS ruta
FROM mother.medios_tv_ccaa_anual t
LEFT JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = t.cod_ccaa
WHERE t.anio = (SELECT max(anio) FROM mother.medios_tv_ccaa_anual)
ORDER BY t.eur_hab_real DESC
```

```sql tv_ccaa_serie
SELECT CAST(anio AS INTEGER) AS anio, nombre AS comunidad, eur_hab_real
FROM mother.medios_tv_ccaa_anual
WHERE eur_hab_real IS NOT NULL
ORDER BY anio, comunidad
```

```sql tv_extremos
SELECT
    (SELECT comunidad FROM ${tv_ccaa} ORDER BY eur_hab_real DESC LIMIT 1) AS mas,
    (SELECT eur_hab_real FROM ${tv_ccaa} ORDER BY eur_hab_real DESC LIMIT 1) AS mas_eur,
    (SELECT comunidad FROM ${tv_ccaa} ORDER BY eur_hab_real ASC LIMIT 1) AS menos,
    (SELECT eur_hab_real FROM ${tv_ccaa} ORDER BY eur_hab_real ASC LIMIT 1) AS menos_eur,
    (SELECT ente || ' (' || comunidad || ')' FROM ${tv_ccaa} ORDER BY eur_hab_real_por_punto_cuota ASC LIMIT 1) AS barata,
    (SELECT ente || ' (' || comunidad || ')' FROM ${tv_ccaa} ORDER BY eur_hab_real_por_punto_cuota DESC LIMIT 1) AS cara
```

```sql tv_gobiernos
SELECT familia AS partido, color, CAST(anios_comunidad AS INTEGER) AS anios_comunidad,
       CAST(comunidades AS INTEGER) AS comunidades, eur_hab_real_anio, cuota_dinero, cuota_poblacion,
       ratio_observado_esperado, CAST(anio_desde AS INTEGER) AS anio_desde, CAST(anio_hasta AS INTEGER) AS anio_hasta
FROM mother.medios_tv_gobiernos
ORDER BY anios_comunidad DESC
```

```sql tv_pp_psoe
SELECT
    max(eur_hab_real_anio) FILTER (WHERE partido = 'PP') AS pp,
    max(eur_hab_real_anio) FILTER (WHERE partido = 'PSOE') AS psoe
FROM ${tv_gobiernos}
```

```sql pub_age
SELECT CAST(anio AS INTEGER) AS anio, institucional_eur_hab_real, comercial_eur_hab_real, total_eur_hab_real,
       institucional_eur_nominal, comercial_eur_nominal, planificado_eur_nominal, ejecucion_pct,
       familia, presidente, color
FROM mother.medios_publicidad_age_anual
WHERE institucional_eur_nominal IS NOT NULL
ORDER BY anio
```

```sql pub_age_ult
SELECT * FROM ${pub_age} ORDER BY anio DESC LIMIT 1
```

```sql pub_age_max
SELECT anio, institucional_eur_hab_real FROM ${pub_age} ORDER BY institucional_eur_hab_real DESC LIMIT 1
```

```sql pub_age_series
SELECT anio, 'Campañas institucionales' AS tipo, institucional_eur_hab_real AS eur_hab FROM ${pub_age}
UNION ALL
SELECT anio, 'Campañas comerciales (empresas y entidades públicas)' AS tipo, comercial_eur_hab_real AS eur_hab FROM ${pub_age}
ORDER BY anio, tipo
```

```sql pub_gobiernos
SELECT presidente, familia AS partido, CAST(anio_desde AS INTEGER) AS anio_desde, CAST(anio_hasta AS INTEGER) AS anio_hasta,
       CAST(anios AS INTEGER) AS anios, institucional_eur_hab_real_media, comercial_eur_hab_real_media,
       total_eur_hab_real_media, ejecucion_pct_media
FROM mother.medios_publicidad_gobiernos
ORDER BY anio_desde
```

```sql pub_medios
SELECT CAST(anio AS INTEGER) AS anio, medio_nombre AS medio, pct
FROM mother.medios_publicidad_age_medios
WHERE ambito = 'institucional' AND medio IN ('television', 'medios_graficos', 'radio', 'digital', 'exterior', 'cine')
ORDER BY anio, medio
```

```sql pub_medios_extremos
SELECT
    max(pct) FILTER (WHERE medio = 'Digital' AND anio = (SELECT min(anio) FROM ${pub_medios})) AS digital_ini,
    max(pct) FILTER (WHERE medio = 'Digital' AND anio = (SELECT max(anio) FROM ${pub_medios})) AS digital_fin,
    max(pct) FILTER (WHERE medio = 'Prensa y revistas' AND anio = (SELECT min(anio) FROM ${pub_medios})) AS prensa_ini,
    max(pct) FILTER (WHERE medio = 'Prensa y revistas' AND anio = (SELECT max(anio) FROM ${pub_medios})) AS prensa_fin,
    CAST(min(anio) AS INTEGER) AS anio_ini,
    CAST(max(anio) AS INTEGER) AS anio_fin
FROM ${pub_medios}
```

```sql pub_grupos
SELECT CAST(anio AS INTEGER) AS anio, tipo, grupo, importe_eur_nominal, eur_hab_real, pct, CAST(puesto AS INTEGER) AS puesto,
       CASE WHEN es_plataforma THEN 'Plataforma digital' WHEN es_publico THEN 'Medio público' ELSE 'Grupo de medios' END AS clase
FROM mother.medios_publicidad_grupos
ORDER BY tipo DESC, puesto
```

```sql pub_grupos_inst
SELECT * FROM ${pub_grupos} WHERE tipo = 'institucional' AND puesto <= 15 ORDER BY puesto
```

```sql pub_grupos_com
SELECT * FROM ${pub_grupos} WHERE tipo = 'comercial' AND puesto <= 15 ORDER BY puesto
```

```sql pub_grupos_resumen
SELECT
    CAST(max(anio) AS INTEGER) AS anio,
    sum(pct) FILTER (WHERE tipo = 'institucional' AND clase = 'Plataforma digital') AS pct_plataformas,
    sum(pct) FILTER (WHERE tipo = 'institucional' AND puesto <= 3) AS pct_top3,
    count(*) FILTER (WHERE tipo = 'institucional') AS n_grupos
FROM ${pub_grupos}
```

```sql terr_serie
SELECT CAST(anio AS INTEGER) AS anio, CASE WHEN nivel = 'local' THEN 'Ayuntamiento de ' || territorio ELSE territorio END AS territorio, total_eur_hab_real
FROM mother.medios_publicidad_territorial_anual
WHERE administracion_eur_hab_real IS NOT NULL
ORDER BY anio, territorio
```

```sql terr_ult
SELECT CASE WHEN nivel = 'local' THEN 'Ayuntamiento de ' || territorio ELSE territorio END AS territorio, CASE nivel WHEN 'local' THEN 'Ayuntamiento' ELSE 'Comunidad' END AS administracion,
       CAST(anio AS INTEGER) AS anio, total_eur_hab_real, administracion_eur_hab_real, empresas_publicas_eur_hab_real,
       total_eur_nominal,
       CASE WHEN iva_incluido THEN 'Con IVA' WHEN NOT iva_incluido THEN 'Sin IVA' ELSE 'No consta' END AS iva,
       CASE base WHEN 'ejecutado' THEN 'Gastado' WHEN 'contratado' THEN 'Contratado' ELSE base END AS base,
       CASE WHEN comparable_entre_territorios THEN 'Sí' ELSE 'No' END AS comparable,
       familia AS partido
FROM mother.medios_publicidad_territorial_anual
WHERE administracion_eur_hab_real IS NOT NULL
QUALIFY row_number() OVER (PARTITION BY territorio ORDER BY anio DESC) = 1
ORDER BY total_eur_hab_real DESC
```

```sql terr_grupos
SELECT CASE WHEN nivel = 'local' THEN 'Ayuntamiento de ' || territorio ELSE territorio END AS territorio, CAST(anio AS INTEGER) AS anio, CAST(rango AS INTEGER) AS rango, grupo,
       CASE WHEN es_medio_publico THEN 'Público' ELSE 'Privado' END AS titularidad,
       pct_medios, importe_eur_nominal
FROM mother.medios_publicidad_territorial_medios
WHERE rango <= 5
QUALIFY anio = max(anio) OVER (PARTITION BY territorio)
ORDER BY territorio, rango
```

```sql empresas
SELECT CASE ambito WHEN 'estatal' THEN 'Estado' WHEN 'autonomico' THEN 'Comunidad' ELSE 'Ayuntamiento' END AS ambito,
       territorio, entidad, CAST(anio AS INTEGER) AS anio, importe_eur_nominal, eur_hab_real,
       CASE magnitud WHEN 'coste_campanas_comerciales' THEN 'Coste de campañas comerciales'
                     WHEN 'cuenta_627' THEN 'Publicidad, propaganda y relaciones públicas (cuentas anuales)'
                     ELSE 'Compra de espacios en medios' END AS que_mide
FROM mother.medios_publicidad_empresas_anual
WHERE tipo_entidad IS DISTINCT FROM 'organismo' AND tipo_entidad IS DISTINCT FROM 'rtve'
QUALIFY anio = max(anio) OVER (PARTITION BY ambito, territorio)
ORDER BY importe_eur_nominal DESC
```

```sql loterias
SELECT CAST(anio AS INTEGER) AS anio,
       CASE WHEN es_loterias THEN 'Loterías y Apuestas del Estado' ELSE 'Resto de empresas y entidades del Estado' END AS entidad,
       sum(eur_hab_real) AS eur_hab_real
FROM mother.medios_publicidad_empresas_anual
WHERE ambito = 'estatal' AND tipo_entidad = 'empresa_publica'
GROUP BY ALL
ORDER BY anio, entidad
```

```sql con_anual
SELECT CAST(anio AS INTEGER) AS anio,
       CASE nivel WHEN 'estatal' THEN 'Estado' WHEN 'autonomico' THEN 'Comunidades autónomas' WHEN 'local' THEN 'Ayuntamientos, diputaciones y cabildos'
                  WHEN 'empresa_publica' THEN 'Empresas y entes públicos' ELSE 'Otros' END AS contratante,
       CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (incomplete)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo,
       sum(importe_eur_real) / 1e6 AS meur_real
FROM mother.medios_contratos_anual
WHERE anio >= 2019
GROUP BY ALL
ORDER BY anio, contratante
```

```sql con_total
SELECT a.anio, sum(a.importe_eur_real) AS eur_real, sum(a.importe_eur_real) / max(p.poblacion) AS eur_hab_real,
       sum(a.n_contratos) AS contratos, sum(a.n_menores) AS menores
FROM mother.medios_contratos_anual a
JOIN mother.poblacion_territorios p ON p.nivel = 'pais' AND p.cod = '00' AND p.sexo = 'Total' AND p.anio = a.anio
WHERE a.anio >= 2019 AND NOT a.parcial
GROUP BY a.anio
ORDER BY a.anio
```

```sql con_ult
SELECT CAST(anio AS INTEGER) AS anio, eur_real, eur_hab_real, contratos, 100.0 * menores / contratos AS pct_menores
FROM ${con_total} ORDER BY anio DESC LIMIT 1
```

```sql con_categorias
SELECT CASE categoria WHEN 'publicidad_inserciones' THEN 'Publicidad e inserciones'
                      WHEN 'patrocinio_eventos' THEN 'Patrocinios, foros, jornadas y premios'
                      WHEN 'suscripciones_servicios_informativos' THEN 'Suscripciones y servicios informativos'
                      WHEN 'especiales_suplementos_revistas' THEN 'Especiales, suplementos y revistas'
                      ELSE 'Otros' END AS categoria,
       sum(importe_eur_real) / 1e6 AS meur_real
FROM mother.medios_contratos_anual
WHERE anio >= 2019 AND NOT parcial
GROUP BY 1
ORDER BY meur_real DESC
```

```sql con_grupos
SELECT grupo, sum(importe_eur_real) / 1e6 AS meur_real, sum(n_contratos) AS contratos
FROM mother.medios_contratos_grupos
WHERE titularidad = 'privada' AND anio >= 2019
GROUP BY grupo
ORDER BY meur_real DESC
LIMIT 15
```

```sql con_municipios
SELECT municipio, arg_max(familia, anio) AS partido, avg(eur_hab_real) AS eur_hab_real, sum(importe_eur_real) AS eur_real,
       sum(n_contratos) AS contratos, max(poblacion) AS poblacion
FROM mother.medios_contratos_municipios
WHERE anio BETWEEN 2022 AND 2025
GROUP BY cod_municipio, municipio
HAVING max(poblacion) >= 100000
ORDER BY eur_hab_real DESC
LIMIT 25
```

```sql con_ejemplos
SELECT CAST(anio AS INTEGER) AS anio, objeto, organo, adjudicatario, grupo, importe_eur_nominal, url
FROM mother.medios_contratos_ejemplos
WHERE titularidad = 'privada'
ORDER BY importe_eur_real DESC
LIMIT 30
```

```sql sub_anual
SELECT CAST(anio AS INTEGER) AS anio,
       CASE nivel WHEN 'estatal' THEN 'Estado' WHEN 'autonomico' THEN 'Comunidades autónomas' ELSE 'Ayuntamientos, diputaciones y cabildos' END AS concedente,
       sum(importe_eur_real) / 1e6 AS meur_real,
       bool_or(parcial) AS parcial,
       CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (incomplete)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo
FROM mother.medios_subvenciones_anual
GROUP BY ALL
ORDER BY anio, concedente
```

```sql sub_espana
SELECT s.anio, sum(s.importe_eur_real) AS eur_real, sum(s.importe_eur_nominal) AS eur_nominal,
       sum(s.importe_eur_real) / max(p.poblacion) AS eur_hab_real, bool_or(s.parcial) AS parcial,
       sum(s.n_concesiones) AS concesiones
FROM mother.medios_subvenciones_anual s
JOIN mother.poblacion_territorios p ON p.nivel = 'pais' AND p.cod = '00' AND p.sexo = 'Total' AND p.anio = s.anio
GROUP BY s.anio
ORDER BY s.anio
```

```sql sub_ult
SELECT CAST(anio AS INTEGER) AS anio, eur_hab_real, eur_real, eur_nominal, concesiones
FROM ${sub_espana} WHERE NOT parcial ORDER BY anio DESC LIMIT 1
```

```sql sub_ccaa
SELECT s.cod_ccaa, max(s.comunidad) AS comunidad,
       sum(s.eur_hab_real) AS eur_hab_real,
       sum(s.eur_hab_real) FILTER (WHERE s.nivel = 'autonomico') AS eur_hab_autonomico,
       sum(s.eur_hab_real) FILTER (WHERE s.nivel = 'local') AS eur_hab_local,
       sum(s.importe_eur_nominal) AS importe_nominal,
       sum(s.n_concesiones) AS concesiones,
       max(s.familia) FILTER (WHERE s.nivel = 'autonomico') AS partido,
       max(s.nota) AS nota,
       '/en' || max(c.ruta) AS ruta
FROM mother.medios_subvenciones_anual s
LEFT JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = s.cod_ccaa
WHERE s.nivel <> 'estatal' AND s.anio = (SELECT max(anio) FROM ${sub_espana} WHERE NOT parcial)
GROUP BY s.cod_ccaa
ORDER BY eur_hab_real DESC
```

```sql sub_beneficiarios
SELECT CAST(rango AS INTEGER) AS rango, nombre, total_eur_real, CAST(total_concesiones AS INTEGER) AS concesiones,
       CAST(primer_anio AS INTEGER) AS primer_anio, CAST(ultimo_anio AS INTEGER) AS ultimo_anio, administraciones
FROM mother.medios_subvenciones_totales
WHERE rango <= 25
ORDER BY rango
```

```sql sub_desde
SELECT CAST(min(anio) AS INTEGER) AS desde, CAST(max(anio) AS INTEGER) AS hasta, bool_or(parcial) AS hay_parcial FROM ${sub_anual}
```

# <span aria-hidden="true">📰</span> Public money in the media

Spanish public administrations fund the media in three ways: they pay for the public broadcasters (RTVE and the regional corporations), they buy advertising in the media (also through their public companies) and they award direct subsidies to publishing companies. All figures are given **per inhabitant and adjusted for inflation**, in {tv_espana_ult[0]?.anio_base} euros. To see what a particular outlet has received, use the [«Who gets what» search](/en/medios/buscador).

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if tv_espana_ult.length && pub_age_ult.length && sub_ult.length}
    <KpiCard
        title="Public broadcasters"
        value={tv_espana_ult[0].total_eur_hab_real}
        formattedValue={formatNumber(tv_espana_ult[0].total_eur_hab_real, 1) + ' €'}
        unit="per inhabitant"
        period={`${tv_espana_ult[0].anio} · ${formatCompact(tv_espana_ult[0].total_meur_nominal * 1e6, 2)} € for RTVE and the regional broadcasters`}
        source="CNMC, RTVE and Generalitat Valenciana"
        direction="positive-down"
        sparklineData={tv_espana.filter(d => d.total_eur_hab_real !== null).map(d => ({...d, y: d.total_eur_hab_real}))}
    />
    <KpiCard
        title="Central government institutional advertising"
        value={pub_age_ult[0].institucional_eur_hab_real}
        formattedValue={formatNumber(pub_age_ult[0].institucional_eur_hab_real, 2) + ' €'}
        unit="per inhabitant"
        period={`${pub_age_ult[0].anio} · ${formatCompact(pub_age_ult[0].institucional_eur_nominal, 2)} € on ministry campaigns`}
        source="Institutional Advertising Commission"
        direction="positive-down"
        sparklineData={pub_age.map(d => ({...d, y: d.institucional_eur_hab_real}))}
    />
    <KpiCard
        title="Advertising by state-owned companies"
        value={pub_age_ult[0].comercial_eur_hab_real}
        formattedValue={formatNumber(pub_age_ult[0].comercial_eur_hab_real, 2) + ' €'}
        unit="per inhabitant"
        period={`${pub_age_ult[0].anio} · ${formatCompact(pub_age_ult[0].comercial_eur_nominal, 2)} € (Loterías, AENA, Correos, Renfe...)`}
        source="Institutional Advertising Commission"
        direction="positive-down"
        sparklineData={pub_age.map(d => ({...d, y: d.comercial_eur_hab_real}))}
    />
    <KpiCard
        title="Subsidies to private media"
        value={sub_ult[0].eur_hab_real}
        formattedValue={formatNumber(sub_ult[0].eur_hab_real, 2) + ' €'}
        unit="per inhabitant"
        period={`${sub_ult[0].anio} · ${formatCompact(sub_ult[0].eur_nominal, 2)} € in ${formatNumber(sub_ult[0].concesiones, 0)} grants`}
        source="National Subsidies Database"
        direction="positive-down"
        sparklineData={sub_espana.filter(d => !d.parcial).map(d => ({...d, y: d.eur_hab_real}))}
    />
    {/if}
</div>

## Public broadcasters

What central government pays RTVE and what the regions pay their radio and television corporations: public service compensation, subsidies, programme contracts and capital contributions. In {tv_espana_ult[0]?.anio} this came to {formatNumber(tv_espana_ult[0]?.rtve_eur_hab_real, 1)} € per inhabitant for RTVE and {formatNumber(tv_espana_ult[0]?.autonomicas_eur_hab_real, 1)} € for the regional corporations (calculated over the whole population of Spain, including the regions that have no broadcaster of their own).

<LineChart
    data={tv_series}
    x=anio
    y=eur_hab
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="€ per inhabitant ({tv_espana_ult[0]?.anio_base} euros)"
    seriesColors={{'RTVE': '#2563eb', 'Radios y televisiones autonómicas': '#f59e0b'}}
    title="Public money for public broadcasters, € per inhabitant adjusted for inflation"
/>

Since 2010, when it stopped carrying advertising, RTVE's figure includes the levy paid by telecoms and television operators and the fee for the use of the radio spectrum. Years with extraordinary payments (the 2021 capital grant for RTVE Play, the additional 100 million in 2024) show up as peaks.

### By region

Public funding for each regional corporation in {tv_ccaa[0]?.anio}, per inhabitant of the region. It ranges from {formatNumber(tv_extremos[0]?.mas_eur, 1)} € in {tv_extremos[0]?.mas} to {formatNumber(tv_extremos[0]?.menos_eur, 1)} € in {tv_extremos[0]?.menos}. Navarre, Cantabria, La Rioja, Ceuta and Melilla have no broadcaster of their own.

<MapaEspana
    data={tv_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod_ccaa"
    value="eur_hab_real"
    valueFmt='0.0'
    link="ruta"
    colorPalette={['#fef3c7', '#f59e0b', '#78350f']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: CNMC, Generalitat Valenciana"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'ente', showColumnName: false},
        {id: 'eur_hab_real', title: '€ per inhabitant', fmt: '0.0'},
        {id: 'meur_nominal', title: 'Millions of euros', fmt: '#,##0.0'},
        {id: 'cuota_audiencia', title: 'Audience share (%)', fmt: '0.0'}
    ]}
/>

To compare what each broadcaster costs with how much it is watched, the table divides the euros per inhabitant by the audience share of its channels in the region (the sum of all its television channels). It is an approximation: the money also pays for radio, the website and in-house production. The cheapest per audience share point is {tv_extremos[0]?.barata} and the most expensive, {tv_extremos[0]?.cara}.

<DataTable data={tv_ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=ente title="Broadcaster" />
    <Column id=eur_hab_real title="€ per inhabitant" fmt='0.0' />
    <Column id=meur_nominal title="Millions of euros" fmt='#,##0.0' />
    <Column id=cuota_audiencia title="Audience share %" fmt='0.0' />
    <Column id=eur_hab_real_por_punto_cuota title="€/inhab. per share point" fmt='0.0' />
    <Column id=familia title="Government" />
</DataTable>

<LineChart
    data={tv_ccaa_serie}
    x=anio
    y=eur_hab_real
    series=comunidad
    xFmt='0'
    yFmt='0'
    yAxisTitle="€ per inhabitant"
    title="Public funding for each regional broadcaster, € per inhabitant adjusted for inflation"
/>

### By party

Adding up regions and years between {tv_gobiernos[0]?.anio_desde} and {tv_gobiernos[0]?.anio_hasta}, and attributing each year to the party governing the region on 1 July, the table compares each party's share of the money contributed with its share of the population it governed (if all spent the same per inhabitant, the ratio would be 1). Only regions with their own broadcaster count. Under the PP, regions contributed an average of {formatNumber(tv_pp_psoe[0]?.pp, 1)} € per inhabitant per year; under the PSOE, {formatNumber(tv_pp_psoe[0]?.psoe, 1)} €.

<DataTable data={tv_gobiernos} rows=12>
    <Column id=partido title="Party in government" />
    <Column id=anios_comunidad title="Years in government (region x year)" fmt='0' />
    <Column id=comunidades title="Regions" fmt='0' />
    <Column id=eur_hab_real_anio title="€ per inhabitant per year" fmt='0.0' />
    <Column id=cuota_dinero title="% of the money" fmt='0.0' />
    <Column id=cuota_poblacion title="% of the population governed" fmt='0.0' />
    <Column id=ratio_observado_esperado title="Observed / expected" fmt='0.00' />
</DataTable>

It should be read with caution: the nationalist parties each govern only one region, and three of the regions that contribute most per inhabitant (Basque Country, Catalonia and Galicia) have a co-official language and their laws task the public broadcaster with promoting it. Moreover, the corporations were created decades ago, so much of each government's spending is inherited.

## Central government advertising

The General State Administration reports every year on the cost of its advertising campaigns: the **institutional** campaigns of ministries and agencies (Law 29/2005) and the **commercial** campaigns of its public companies and bodies (Loterías y Apuestas del Estado, AENA, Correos, Renfe, Paradores...). In {pub_age_ult[0]?.anio} it spent {formatNumber(pub_age_ult[0]?.institucional_eur_hab_real, 2)} € per inhabitant on institutional campaigns and {formatNumber(pub_age_ult[0]?.comercial_eur_hab_real, 2)} € on commercial ones. Institutional spending peaked in {pub_age_max[0]?.anio}, at {formatNumber(pub_age_max[0]?.institucional_eur_hab_real, 2)} €.

<BarChart
    data={pub_age_series}
    x=anio
    y=eur_hab
    series=tipo
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="€ per inhabitant"
    seriesColors={{'Campañas institucionales': '#2563eb', 'Campañas comerciales (empresas y entidades públicas)': '#93c5fd'}}
    title="General State Administration advertising, € per inhabitant adjusted for inflation"
/>

Annual average for each Government (each year counts for whoever was prime minister on 1 July). Actual spending always falls short of what was planned: the last column is the share of the annual plan that was actually spent.

<DataTable data={pub_gobiernos} rows=10>
    <Column id=presidente title="Prime minister" />
    <Column id=partido title="Party" />
    <Column id=anio_desde title="From" fmt='0' />
    <Column id=anio_hasta title="To" fmt='0' />
    <Column id=institucional_eur_hab_real_media title="Institutional, €/inhab. per year" fmt='0.00' />
    <Column id=comercial_eur_hab_real_media title="Commercial, €/inhab. per year" fmt='0.00' />
    <Column id=ejecucion_pct_media title="% of plan spent" fmt='0' />
</DataTable>

Some years include extraordinary campaigns, such as those during the pandemic in 2020-2022.

### In which media

Breakdown of media space purchased for institutional campaigns by type of media. Digital has gone from {formatNumber(pub_medios_extremos[0]?.digital_ini, 1)} % in {pub_medios_extremos[0]?.anio_ini} to {formatNumber(pub_medios_extremos[0]?.digital_fin, 1)} % in {pub_medios_extremos[0]?.anio_fin}, and print from {formatNumber(pub_medios_extremos[0]?.prensa_ini, 1)} % to {formatNumber(pub_medios_extremos[0]?.prensa_fin, 1)} %.

<AreaChart
    data={pub_medios}
    x=anio
    y=pct
    series=medio
    xFmt='0'
    yFmt='0"%"'
    type=stacked100
    title="Central government institutional advertising by type of media, % of media space purchased"
/>

### Which groups receive it

Since the {pub_grupos_resumen[0]?.anio} Report, the first under the European Media Freedom Act, the Government publishes how much it paid each media group or platform. The top three groups took {formatNumber(pub_grupos_resumen[0]?.pct_top3, 0)} % of institutional media buying, and the digital platforms (Google, Meta, TikTok...), {formatNumber(pub_grupos_resumen[0]?.pct_plataformas, 0)} %.

<BarChart
    data={pub_grupos_inst}
    x=grupo
    y=eur_hab_real
    series=clase
    swapXY=true
    sort=false
    yFmt='0.00'
    yAxisTitle="€ per inhabitant"
    seriesColors={{'Grupo de medios': '#2563eb', 'Plataforma digital': '#a855f7', 'Medio público': '#f59e0b'}}
    title="Central government institutional advertising by group, {pub_grupos_resumen[0]?.anio} (€ per inhabitant)"
/>

<BarChart
    data={pub_grupos_com}
    x=grupo
    y=eur_hab_real
    series=clase
    swapXY=true
    sort=false
    yFmt='0.00'
    yAxisTitle="€ per inhabitant"
    seriesColors={{'Grupo de medios': '#2563eb', 'Plataforma digital': '#a855f7', 'Medio público': '#f59e0b'}}
    title="Commercial advertising by state-owned companies by group, {pub_grupos_resumen[0]?.anio} (€ per inhabitant)"
/>

<DataTable data={pub_grupos} rows=15 search=true>
    <Column id=tipo title="Campaigns" />
    <Column id=puesto title="Rank" fmt='0' />
    <Column id=grupo title="Group or company" />
    <Column id=clase title="Type" />
    <Column id=importe_eur_nominal title="Euros" fmt='#,##0' />
    <Column id=pct title="% of total" fmt='0.0' />
</DataTable>

## Advertising by regions, town councils and public companies

Regions and town councils also buy advertising, and only some publish how much and in which media. These are the ones that do so as open data or in reports from which the data can be extracted. Not all measure the same thing: some give the amount spent and others the amount contracted, some including VAT and others not (the «Comparable» column marks those that cannot be compared directly with the rest). Catalonia also gives the net amount, without the media agency's commission.

<DataTable data={terr_ult} rows=15>
    <Column id=territorio title="Administration" />
    <Column id=administracion title="Type" />
    <Column id=anio title="Year" fmt='0' />
    <Column id=total_eur_hab_real title="€ per inhabitant" fmt='0.00' />
    <Column id=administracion_eur_hab_real title="By the administration" fmt='0.00' />
    <Column id=empresas_publicas_eur_hab_real title="By its public companies" fmt='0.00' />
    <Column id=total_eur_nominal title="Euros" fmt='#,##0' />
    <Column id=iva title="VAT" />
    <Column id=base title="Figure" />
    <Column id=comparable title="Comparable" />
    <Column id=partido title="Government" />
</DataTable>

<LineChart
    data={terr_serie}
    x=anio
    y=total_eur_hab_real
    series=territorio
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="€ per inhabitant"
    title="Institutional advertising by regions and town councils, € per inhabitant adjusted for inflation"
/>

Galicia, the Canary Islands, the Balearic Islands, Asturias, Cantabria, Castile-La Mancha and Andalusia do not publish their spending by outlet; the Community of Madrid publishes its media plans (since 2020, what was planned by campaign and outlet, excluding VAT), but not what was actually spent. The Basque Country figures come from the reports the Basque Government submits to Parliament, compiled by [gobiernovasco.marketing](https://gobiernovasco.marketing/).

The five groups that receive most from each administration, in the latest year with data:

<DataTable data={terr_grupos} rows=10 search=true>
    <Column id=territorio title="Administration" />
    <Column id=anio title="Year" fmt='0' />
    <Column id=rango title="Rank" fmt='0' />
    <Column id=grupo title="Group or outlet" />
    <Column id=titularidad title="Ownership" />
    <Column id=pct_medios title="% of media advertising" fmt='0.0' />
    <Column id=importe_eur_nominal title="Euros" fmt='#,##0' />
</DataTable>

### Public companies

Public companies run their own campaigns, which do not always appear in the institutional advertising reports. Those of central government are covered in the annual commercial advertising report; Loterías y Apuestas del Estado is by far the biggest spender.

<BarChart
    data={loterias}
    x=anio
    y=eur_hab_real
    series=entidad
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="€ per inhabitant"
    seriesColors={{'Loterías y Apuestas del Estado': '#16a34a', 'Resto de empresas y entidades del Estado': '#86efac'}}
    title="Commercial advertising by state-owned companies, € per inhabitant adjusted for inflation"
/>

For regional and municipal companies there are only data for those that publish them: Canal de Isabel II (its media plans by campaign and outlet since 2019; its annual accounts, which also include public relations and sponsorship, are kept only as a reference), FGC, Loteries de Catalunya, EMT and Madrid Destino, among others. Metro de Madrid does not allow its data to be downloaded.

<DataTable data={empresas} rows=15 search=true>
    <Column id=entidad title="Company or body" />
    <Column id=ambito title="Of" />
    <Column id=territorio title="Territory" />
    <Column id=anio title="Year" fmt='0' />
    <Column id=importe_eur_nominal title="Euros" fmt='#,##0' />
    <Column id=eur_hab_real title="€ per inhabitant of the territory" fmt='0.00' />
    <Column id=que_mide title="What it measures" wrap=true />
</DataTable>

## Contracts with media companies

In addition to advertising campaigns, administrations contract directly with the media: insertions and adverts, sponsorship of forums, conferences, galas and awards organised by the media themselves, special supplements, magazines and subscriptions to news agencies. They are almost always minor contracts, worth a few thousand euros, that do not appear in the institutional advertising reports. Searching the Public Sector Procurement Platform for contracts awarded to a reviewed list of some 800 private media companies, in {con_ult[0]?.anio} they added up to at least {formatCompact(con_ult[0]?.eur_real, 2)} € ({formatNumber(con_ult[0]?.eur_hab_real, 2)} € per inhabitant) in {formatNumber(con_ult[0]?.contratos, 0)} contracts, {formatNumber(con_ult[0]?.pct_menores, 0)} % of them minor contracts.

<BarChart
    data={con_anual}
    x=periodo
    sort=false
    y=meur_real
    series=contratante
    yFmt='0.0'
    yAxisTitle="Millions of euros (adjusted for inflation)"
    seriesColors={{'Estado': '#2563eb', 'Comunidades autónomas': '#10b981', 'Ayuntamientos, diputaciones y cabildos': '#a3e635', 'Empresas y entes públicos': '#f59e0b', 'Otros': '#94a3b8'}}
    title="Contracts awarded to private media companies, millions of euros adjusted for inflation (documented minimum)"
/>

It is a **minimum**: the Platform does not include minor contracts from the regions that have their own platform (Catalonia, Basque Country, Andalusia, Community of Madrid, Galicia, Navarre and La Rioja) nor those of some large town councils that do not publish them there, and advertising bought through media agencies appears in the agency's name. That is why regions are not compared with each other. The amounts are what was awarded, excluding VAT, not what was paid. The series starts in 2019 because more bodies publish every year.

<BarChart
    data={con_categorias}
    x=categoria
    y=meur_real
    swapXY=true
    sort=false
    yFmt='0'
    yAxisTitle="Millions of euros, 2019-{con_ult[0]?.anio}"
    title="What it is spent on: media contracts by type, 2019-{con_ult[0]?.anio} (millions of today's euros)"
/>

<DataTable data={con_grupos} rows=15>
    <Column id=grupo title="Group" />
    <Column id=meur_real title="Millions of today's euros (since 2019)" fmt='0.0' />
    <Column id=contratos title="Contracts" fmt='#,##0' />
</DataTable>

Cities of more than 100,000 inhabitants that contract most with the media per inhabitant (2022-2025 average, only what is published on the Platform):

<DataTable data={con_municipios} rows=10 search=true>
    <Column id=municipio title="Municipality" />
    <Column id=partido title="Mayor's party (2025)" />
    <Column id=eur_hab_real title="€ per inhabitant per year" fmt='0.00' />
    <Column id=eur_real title="Total 2022-2025 (today's euros)" fmt='#,##0' />
    <Column id=contratos title="Contracts" fmt='#,##0' />
</DataTable>

The largest sponsorship and event contracts with private media:

<DataTable data={con_ejemplos} rows=10 search=true link=url>
    <Column id=anio title="Year" fmt='0' />
    <Column id=objeto title="Purpose of the contract" wrap=true />
    <Column id=organo title="Contracting body" wrap=true />
    <Column id=adjudicatario title="Contractor" />
    <Column id=importe_eur_nominal title="Euros excl. VAT" fmt='#,##0' />
</DataTable>

## Subsidies to private media

Direct aid to companies, cooperatives and associations publishing private press, radio, television and digital media: structural aid, aid for the use of co-official languages, for digitalisation and artificial intelligence or for specific projects. It does not include public media (already counted above) or aid to journalists or universities.

<BarChart
    data={sub_anual}
    x=periodo
    sort=false
    y=meur_real
    series=concedente
    yFmt='0.0'
    yAxisTitle="Millions of euros (adjusted for inflation)"
    seriesColors={{'Estado': '#2563eb', 'Comunidades autónomas': '#10b981', 'Ayuntamientos, diputaciones y cabildos': '#a3e635'}}
    title="Subsidies awarded to private media, millions of euros adjusted for inflation"
/>

The National Subsidies Database only allows grants from the last four years to be consulted, which is why the series starts in {sub_desde[0]?.desde}; SpainFacts keeps its own copy so as not to lose the years as they drop out. The current year is marked as incomplete.

### By region

Subsidies from the region and from its town councils, provincial councils or island councils in {sub_ult[0]?.anio}, per inhabitant of the region. Central government subsidies are spread across the whole of Spain and are not included here.

<MapaEspana
    data={sub_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod_ccaa"
    value="eur_hab_real"
    valueFmt='0.00'
    link="ruta"
    colorPalette={['#ecfdf5', '#10b981', '#064e3b']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Boundaries © Instituto Geográfico Nacional · Data: BDNS"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'eur_hab_real', title: '€ per inhabitant', fmt: '0.00'},
        {id: 'eur_hab_autonomico', title: 'From the region', fmt: '0.00'},
        {id: 'eur_hab_local', title: 'From town and provincial councils', fmt: '0.00'},
        {id: 'concesiones', title: 'Grants', fmt: '#,##0'}
    ]}
/>

<DataTable data={sub_ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Region" />
    <Column id=eur_hab_real title="€ per inhabitant" fmt='0.00' />
    <Column id=eur_hab_autonomico title="From the region" fmt='0.00' />
    <Column id=eur_hab_local title="From local bodies" fmt='0.00' />
    <Column id=importe_nominal title="Euros" fmt='#,##0' />
    <Column id=concesiones title="Grants" fmt='#,##0' />
    <Column id=partido title="Regional government" />
</DataTable>

The regions that do not appear did not award aid to private media that year or did not publish it in the National Subsidies Database. **The Basque Government does not record its aid to the media there**, so in the Basque Country only that of the provincial councils and town councils is recorded.

### Who receives them

The 25 companies and organisations that have received most since {sub_desde[0]?.desde}, adding up all years in today's euros. Aid to individuals (self-employed journalists, for example) is counted in the totals but not shown by name.

<DataTable data={sub_beneficiarios} rows=25 search=true>
    <Column id=rango title="Rank" fmt='0' />
    <Column id=nombre title="Recipient" />
    <Column id=total_eur_real title="Total (today's euros)" fmt='#,##0' />
    <Column id=concesiones title="Grants" fmt='0' />
    <Column id=administraciones title="Awarding bodies" wrap=true />
</DataTable>

## Methodology and sources

- **Regional broadcasters**: [CNMC, Economic Report on the Telecommunications and Audiovisual Sector](https://www.cnmc.es/sectores-que-regulamos/telecomunicaciones/informes-economicos-sectoriales-anuales), subsidies and transfers received by each corporation (radio and television together), 2017-2025; the charts by region have been transcribed by hand and the sum matches the CNMC total. Since 2022 the CNMC only gives euros per inhabitant: the millions are reconstructed using INE population data. The CNMC does not include the Valencian Community: for À Punt, the shareholder contributions from the CVMC accounts in the [General Account of the Generalitat](https://hisenda.gva.es/es/web/intervencion-general/laconselleria-infogeneral-laintervenciongeneral-cuentas) (2017-2023) and the execution of programme 462D on [dadesobertes.gva.es](https://dadesobertes.gva.es/) (2024-2025) are used. In Castile and León and Murcia the television channel is a private company with a public programme contract.
- **RTVE**: [annual accounts of the RTVE Corporation](https://www.rtve.es/rtve/20231016/transparencia-cuentas/943360.shtml), subsidies note: public service compensation from the General State Budget, other subsidies, the spectrum fee and operators' contributions (Law 8/2009). For 2008-2009 these are the group accounts, when it still carried advertising.
- **Audiences**: annual audience share from [Barlovento Comunicación](https://barloventocomunicacion.es/) with Kantar Media data (individuals aged 4 and over, including guests).
- **Central government advertising**: [Institutional Advertising and Communication Commission, annual plans and reports](https://www.lamoncloa.gob.es/serviciosdeprensa/cpci/paginas/planeseinformes.aspx) (Law 29/2005), actual cost of campaigns since 2006, by type of media, and since the 2025 Report by media group (annex IV of the institutional report and annex III of the commercial advertising report). The actual cost includes production and evaluation as well as media buying; the breakdown by group is media buying only. The reports do not say whether the amounts include VAT (judging by how they are rounded, they appear to). What each outlet is paid also depends on the discounts negotiated by the media agencies that contract the campaigns.
- **Advertising by regions and town councils**: open data from the [Generalitat de Catalunya](https://analisi.transparenciacatalunya.cat/Sector-P-blic/Campanyes-i-promoci-institucional-de-la-Generalita/8d5a-6vsk), the [Junta de Castilla y León](https://analisis.datosabiertos.jcyl.es/explore/dataset/publicidad-institucional/), the [Government of Aragon](https://www.aragon.es/transparencia/gestion-fondos-publicos/campanas-publicidad-institucional), the [Government of Navarre](https://datosabiertos.navarra.es/dataset/publicidad-institucional), the [Region of Murcia](https://transparencia.carm.es/publicidad-institucional), [Madrid City Council](https://datos.madrid.es/dataset/300024-0-publicidad-institucional) and [Barcelona City Council](https://opendata-ajuntament.barcelona.cat/data/ca/dataset/campanyes-publicitat-institucional); PDF reports from the [Generalitat Valenciana](https://gvaoberta.gva.es/va/publicidad-y-promocion-institucional) (with its instrumental public sector) and, for the Basque Country, the compilation of the Basque Government's reports by [gobiernovasco.marketing](https://gobiernovasco.marketing/) (Jaime Gómez-Obregón, CC BY 4.0). Outlet names are grouped by media group using a SpainFacts concordance table.
- **Public companies**: the commercial campaigns chapter of the annual reports of the Institutional Advertising and Communication Commission (by body, 2015-2025); [media plans and annual accounts of Canal de Isabel II](https://www.canaldeisabelsegunda.es/en/informacion-economica) (plans by campaign and outlet since 2019; account 627, advertising, publicity and public relations, only as a reference); [media plans of the Community of Madrid](https://www.comunidad.madrid/transparencia/gastos-publicidad-y-comunicacion-institucional) (2020-2025, planned by campaign and outlet, excluding VAT); [TMB transparency portal](https://transparencia.tmb.cat/); and the companies that appear in the data of their region or town council. Since 2024 the Renfe figure only includes Renfe Operadora's campaigns, not Renfe Viajeros' commercial ones.
- **Contracts with the media**: [Public Sector Procurement Platform](https://www.hacienda.gob.es/es-ES/GobiernoAbierto/Datos%20Abiertos/Paginas/licitaciones_plataforma_contratacion.aspx) (tenders from hosted profiles, aggregated regional platforms and minor contracts), since 2018, and the [register of contracting bodies](https://contrataciondelsectorpublico.gob.es/datosabiertos/OrganosContratacion.xlsx) to identify which administration is contracting. Only contractors on a hand-reviewed list of tax IDs of media companies count (press publishers, radio stations, private television channels, digital outlets and news agencies; excluding advertising agencies, technical production companies and book publishers). The type of contract is inferred from the text of its purpose. Absurd amounts (framework agreements with the total amount) are discarded.
- **Subsidies**: [National Subsidies Database](https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones) (IGAE). A hand-reviewed list of calls for aid to private media is used (criteria in the SpainFacts repository); amount granted, not paid, by year of award. Public media, press associations and scholarships are excluded.
- **Constant euros** using the INE's CPI and **population** from the municipal register; each Government's party according to the SpainFacts table of presidents.
