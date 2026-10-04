---
title: Diñeiro público nos medios
description: "Canto diñeiro público reciben os medios de comunicación en España: achega a RTVE e ás televisións autonómicas, publicidade institucional e comercial do Estado por grupo mediático e subvencións a medios privados, por habitante e descontada a inflación, por comunidade e por partido."
i18n_origen: f695df823f3f
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
       '/gl' || c.ruta AS ruta
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
       CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (incompleto)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo,
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
       CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (incompleto)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo
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
       '/gl' || max(c.ruta) AS ruta
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

# <span aria-hidden="true">📰</span> Diñeiro público nos medios

As administracións españolas financian os medios de comunicación por tres vías: pagan as radiotelevisións públicas (RTVE e os entes autonómicos), compran publicidade nos medios (tamén a través das súas empresas públicas) e conceden subvencións directas a empresas editoras. Todas as cifras danse **por habitante e descontada a inflación**, en euros de {tv_espana_ult[0]?.anio_base}. Para ver o que recibiu un medio concreto, usa o [buscador «Quen recibe que»](/gl/medios/buscador).

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if tv_espana_ult.length && pub_age_ult.length && sub_ult.length}
    <KpiCard
        title="Radiotelevisións públicas"
        value={tv_espana_ult[0].total_eur_hab_real}
        formattedValue={formatNumber(tv_espana_ult[0].total_eur_hab_real, 1) + ' €'}
        unit="por habitante"
        period={`${tv_espana_ult[0].anio} · ${formatCompact(tv_espana_ult[0].total_meur_nominal * 1e6, 2)} € entre RTVE e as autonómicas`}
        source="CNMC, RTVE e Generalitat Valenciana"
        direction="positive-down"
        sparklineData={tv_espana.filter(d => d.total_eur_hab_real !== null).map(d => d.total_eur_hab_real)}
    />
    <KpiCard
        title="Publicidade institucional do Estado"
        value={pub_age_ult[0].institucional_eur_hab_real}
        formattedValue={formatNumber(pub_age_ult[0].institucional_eur_hab_real, 2) + ' €'}
        unit="por habitante"
        period={`${pub_age_ult[0].anio} · ${formatCompact(pub_age_ult[0].institucional_eur_nominal, 2)} € en campañas dos ministerios`}
        source="Comisión de Publicidade Institucional"
        direction="positive-down"
        sparklineData={pub_age.map(d => d.institucional_eur_hab_real)}
    />
    <KpiCard
        title="Publicidade de empresas do Estado"
        value={pub_age_ult[0].comercial_eur_hab_real}
        formattedValue={formatNumber(pub_age_ult[0].comercial_eur_hab_real, 2) + ' €'}
        unit="por habitante"
        period={`${pub_age_ult[0].anio} · ${formatCompact(pub_age_ult[0].comercial_eur_nominal, 2)} € (Loterías, AENA, Correos, Renfe...)`}
        source="Comisión de Publicidade Institucional"
        direction="positive-down"
        sparklineData={pub_age.map(d => d.comercial_eur_hab_real)}
    />
    <KpiCard
        title="Subvencións a medios privados"
        value={sub_ult[0].eur_hab_real}
        formattedValue={formatNumber(sub_ult[0].eur_hab_real, 2) + ' €'}
        unit="por habitante"
        period={`${sub_ult[0].anio} · ${formatCompact(sub_ult[0].eur_nominal, 2)} € en ${formatNumber(sub_ult[0].concesiones, 0)} concesións`}
        source="Base de Datos Nacional de Subvencións"
        direction="positive-down"
        sparklineData={sub_espana.filter(d => !d.parcial).map(d => d.eur_hab_real)}
    />
    {/if}
</div>

## Radiotelevisións públicas

O que lle paga o Estado a RTVE e o que lles pagan as comunidades aos seus entes de radio e televisión: compensación por servizo público, subvencións, contratos-programa e achegas ao capital. En {tv_espana_ult[0]?.anio} foron {formatNumber(tv_espana_ult[0]?.rtve_eur_hab_real, 1)} € por habitante para RTVE e {formatNumber(tv_espana_ult[0]?.autonomicas_eur_hab_real, 1)} € para os entes autonómicos (calculado sobre toda a poboación de España, tamén a das comunidades que non teñen televisión propia).

<LineChart
    data={tv_series}
    x=anio
    y=eur_hab
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="€ por habitante (euros de {tv_espana_ult[0]?.anio_base})"
    seriesColors={{'RTVE': '#2563eb', 'Radios y televisiones autonómicas': '#f59e0b'}}
    title="Diñeiro público para as radiotelevisións públicas, € por habitante descontada a inflación"
/>

A de RTVE inclúe desde 2010, cando deixou de emitir publicidade, a taxa que pagan as operadoras de telecomunicacións e televisión e a do uso do espectro radioeléctrico. Os anos con pagamentos extraordinarios (a subvención de capital de 2021 para RTVE Play, os 100 millóns adicionais de 2024) vense como picos.

### Por comunidade

Achega pública a cada ente autonómico en {tv_ccaa[0]?.anio}, por habitante da comunidade. Vai de {formatNumber(tv_extremos[0]?.mas_eur, 1)} € en {tv_extremos[0]?.mas} a {formatNumber(tv_extremos[0]?.menos_eur, 1)} € en {tv_extremos[0]?.menos}. Navarra, Cantabria, A Rioxa, Ceuta e Melilla non teñen ente propio.

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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: CNMC, Generalitat Valenciana"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'ente', showColumnName: false},
        {id: 'eur_hab_real', title: '€ por habitante', fmt: '0.0'},
        {id: 'meur_nominal', title: 'Millóns de euros', fmt: '#,##0.0'},
        {id: 'cuota_audiencia', title: 'Cota de pantalla (%)', fmt: '0.0'}
    ]}
/>

Para comparar o que custa cada televisión co que se ve, a táboa divide os euros por habitante entre a cota de pantalla das súas canles na comunidade (suma de todas as súas canles de televisión). É unha aproximación: o diñeiro tamén paga a radio, a web e a produción propia. O que menos custa por punto de audiencia é {tv_extremos[0]?.barata} e o que máis, {tv_extremos[0]?.cara}.

<DataTable data={tv_ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidade" />
    <Column id=ente title="Ente" />
    <Column id=eur_hab_real title="€ por habitante" fmt='0.0' />
    <Column id=meur_nominal title="Millóns de euros" fmt='#,##0.0' />
    <Column id=cuota_audiencia title="Cota de pantalla %" fmt='0.0' />
    <Column id=eur_hab_real_por_punto_cuota title="€/hab. por punto de cota" fmt='0.0' />
    <Column id=familia title="Goberno" />
</DataTable>

<LineChart
    data={tv_ccaa_serie}
    x=anio
    y=eur_hab_real
    series=comunidad
    xFmt='0'
    yFmt='0'
    yAxisTitle="€ por habitante"
    title="Achega pública a cada ente autonómico, € por habitante descontada a inflación"
/>

### Por partido

Sumando comunidades e anos entre {tv_gobiernos[0]?.anio_desde} e {tv_gobiernos[0]?.anio_hasta}, e atribuíndo cada ano ao partido que gobernaba a comunidade o 1 de xullo, a táboa compara a parte do diñeiro achegado con cada partido coa parte da poboación que gobernou (se todos gastasen o mesmo por habitante, a razón sería 1). Só contan as comunidades con ente propio. Co PP as comunidades achegaron de media {formatNumber(tv_pp_psoe[0]?.pp, 1)} € por habitante e ano; co PSOE, {formatNumber(tv_pp_psoe[0]?.psoe, 1)} €.

<DataTable data={tv_gobiernos} rows=12>
    <Column id=partido title="Partido que gobernaba" />
    <Column id=anios_comunidad title="Anos de goberno (comunidade x ano)" fmt='0' />
    <Column id=comunidades title="Comunidades" fmt='0' />
    <Column id=eur_hab_real_anio title="€ por habitante e ano" fmt='0.0' />
    <Column id=cuota_dinero title="% do diñeiro" fmt='0.0' />
    <Column id=cuota_poblacion title="% da poboación gobernada" fmt='0.0' />
    <Column id=ratio_observado_esperado title="Observado / esperado" fmt='0.00' />
</DataTable>

Hai que lelo con cautela: os partidos nacionalistas só gobernan unha comunidade cada un, e tres das comunidades que máis achegan por habitante (País Vasco, Cataluña e Galicia) teñen lingua cooficial e as súas leis encárganlle ao ente público a promoción desa lingua. Ademais, os entes creáronse hai décadas, así que boa parte do gasto de cada goberno é herdado.

## Publicidade do Estado

A Administración Xeral do Estado informa cada ano do custo das súas campañas de publicidade: as **institucionais** dos ministerios e organismos (Lei 29/2005) e as **comerciais** das súas empresas e entidades públicas (Loterías y Apuestas del Estado, AENA, Correos, Renfe, Paradores...). En {pub_age_ult[0]?.anio} gastou {formatNumber(pub_age_ult[0]?.institucional_eur_hab_real, 2)} € por habitante en campañas institucionais e {formatNumber(pub_age_ult[0]?.comercial_eur_hab_real, 2)} € en comerciais. O máximo das institucionais foi {pub_age_max[0]?.anio}, con {formatNumber(pub_age_max[0]?.institucional_eur_hab_real, 2)} €.

<BarChart
    data={pub_age_series}
    x=anio
    y=eur_hab
    series=tipo
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="€ por habitante"
    seriesColors={{'Campañas institucionales': '#2563eb', 'Campañas comerciales (empresas y entidades públicas)': '#93c5fd'}}
    title="Publicidade da Administración Xeral do Estado, € por habitante descontada a inflación"
/>

Media anual de cada Goberno (cada ano conta para quen presidía o 1 de xullo). O gasto executado queda sempre por debaixo do planificado: a última columna é a parte do plan anual que se chegou a gastar.

<DataTable data={pub_gobiernos} rows=10>
    <Column id=presidente title="Presidente" />
    <Column id=partido title="Partido" />
    <Column id=anio_desde title="Desde" fmt='0' />
    <Column id=anio_hasta title="Ata" fmt='0' />
    <Column id=institucional_eur_hab_real_media title="Institucional, €/hab. e ano" fmt='0.00' />
    <Column id=comercial_eur_hab_real_media title="Comercial, €/hab. e ano" fmt='0.00' />
    <Column id=ejecucion_pct_media title="% do plan executado" fmt='0' />
</DataTable>

Algúns anos inclúen campañas extraordinarias, como as da pandemia en 2020-2022.

### En que medios

Reparto da compra de espazos das campañas institucionais por tipo de medio. O dixital pasou do {formatNumber(pub_medios_extremos[0]?.digital_ini, 1)} % en {pub_medios_extremos[0]?.anio_ini} ao {formatNumber(pub_medios_extremos[0]?.digital_fin, 1)} % en {pub_medios_extremos[0]?.anio_fin}, e a prensa escrita do {formatNumber(pub_medios_extremos[0]?.prensa_ini, 1)} % ao {formatNumber(pub_medios_extremos[0]?.prensa_fin, 1)} %.

<AreaChart
    data={pub_medios}
    x=anio
    y=pct
    series=medio
    xFmt='0'
    yFmt='0"%"'
    type=stacked100
    title="Publicidade institucional do Estado por tipo de medio, % da compra de espazos"
/>

### Que grupos a reciben

Desde o Informe de {pub_grupos_resumen[0]?.anio}, o primeiro baixo o Regulamento europeo de liberdade dos medios, o Goberno publica canto lle pagou a cada grupo mediático ou plataforma. Os tres primeiros grupos levaron o {formatNumber(pub_grupos_resumen[0]?.pct_top3, 0)} % da compra de medios institucional, e as plataformas dixitais (Google, Meta, TikTok...), o {formatNumber(pub_grupos_resumen[0]?.pct_plataformas, 0)} %.

<BarChart
    data={pub_grupos_inst}
    x=grupo
    y=eur_hab_real
    series=clase
    swapXY=true
    sort=false
    yFmt='0.00'
    yAxisTitle="€ por habitante"
    seriesColors={{'Grupo de medios': '#2563eb', 'Plataforma digital': '#a855f7', 'Medio público': '#f59e0b'}}
    title="Publicidade institucional do Estado por grupo, {pub_grupos_resumen[0]?.anio} (€ por habitante)"
/>

<BarChart
    data={pub_grupos_com}
    x=grupo
    y=eur_hab_real
    series=clase
    swapXY=true
    sort=false
    yFmt='0.00'
    yAxisTitle="€ por habitante"
    seriesColors={{'Grupo de medios': '#2563eb', 'Plataforma digital': '#a855f7', 'Medio público': '#f59e0b'}}
    title="Publicidade comercial das empresas do Estado por grupo, {pub_grupos_resumen[0]?.anio} (€ por habitante)"
/>

<DataTable data={pub_grupos} rows=15 search=true>
    <Column id=tipo title="Campañas" />
    <Column id=puesto title="Posto" fmt='0' />
    <Column id=grupo title="Grupo ou empresa" />
    <Column id=clase title="Tipo" />
    <Column id=importe_eur_nominal title="Euros" fmt='#,##0' />
    <Column id=pct title="% do total" fmt='0.0' />
</DataTable>

## Publicidade de comunidades, concellos e empresas públicas

As comunidades e os concellos tamén compran publicidade, e só algúns publican canto e en que medios. Estes son os que o fan en datos abertos ou en informes que se poden extraer. Non todos miden o mesmo: uns dan o gastado e outros o contratado, uns con IVE e outros sen el (a columna «Comparable» marca os que non se poden comparar directamente co resto). Cataluña dá ademais o importe neto, sen a comisión da axencia de medios.

<DataTable data={terr_ult} rows=15>
    <Column id=territorio title="Administración" />
    <Column id=administracion title="Tipo" />
    <Column id=anio title="Ano" fmt='0' />
    <Column id=total_eur_hab_real title="€ por habitante" fmt='0.00' />
    <Column id=administracion_eur_hab_real title="Da administración" fmt='0.00' />
    <Column id=empresas_publicas_eur_hab_real title="Das súas empresas públicas" fmt='0.00' />
    <Column id=total_eur_nominal title="Euros" fmt='#,##0' />
    <Column id=iva title="IVE" />
    <Column id=base title="Cifra" />
    <Column id=comparable title="Comparable" />
    <Column id=partido title="Goberno" />
</DataTable>

<LineChart
    data={terr_serie}
    x=anio
    y=total_eur_hab_real
    series=territorio
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="€ por habitante"
    title="Publicidade institucional de comunidades e concellos, € por habitante descontada a inflación"
/>

Galicia, Canarias, Baleares, Asturias, Cantabria, Castela-A Mancha e Andalucía non publican o seu gasto por medio; a Comunidade de Madrid publica os seus plans de medios (desde 2020, o previsto por campaña e medio, sen IVE), pero non o executado. O País Vasco sae das memorias que o Goberno Vasco lle presenta ao Parlamento, reunidas por [gobiernovasco.marketing](https://gobiernovasco.marketing/).

Os cinco grupos que máis reciben de cada administración, no último ano con dato:

<DataTable data={terr_grupos} rows=10 search=true>
    <Column id=territorio title="Administración" />
    <Column id=anio title="Ano" fmt='0' />
    <Column id=rango title="Posto" fmt='0' />
    <Column id=grupo title="Grupo ou medio" />
    <Column id=titularidad title="Titularidade" />
    <Column id=pct_medios title="% da publicidade en medios" fmt='0.0' />
    <Column id=importe_eur_nominal title="Euros" fmt='#,##0' />
</DataTable>

### Empresas públicas

As empresas públicas fan as súas propias campañas, que non sempre aparecen nos informes de publicidade institucional. As do Estado recóllense no informe anual de publicidade comercial; Loterías y Apuestas del Estado é, con diferenza, a que máis gasta.

<BarChart
    data={loterias}
    x=anio
    y=eur_hab_real
    series=entidad
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="€ por habitante"
    seriesColors={{'Loterías y Apuestas del Estado': '#16a34a', 'Resto de empresas y entidades del Estado': '#86efac'}}
    title="Publicidade comercial das empresas do Estado, € por habitante descontada a inflación"
/>

Das autonómicas e municipais só hai datos das que os publican: Canal de Isabel II (os seus plans de medios por campaña e medio desde 2019; as contas anuais, que suman ademais relacións públicas e patrocinios, quedan só como referencia), FGC, Loteries de Catalunya, EMT e Madrid Destino, entre outras. Metro de Madrid non permite descargar os seus datos.

<DataTable data={empresas} rows=15 search=true>
    <Column id=entidad title="Empresa ou entidade" />
    <Column id=ambito title="De" />
    <Column id=territorio title="Territorio" />
    <Column id=anio title="Ano" fmt='0' />
    <Column id=importe_eur_nominal title="Euros" fmt='#,##0' />
    <Column id=eur_hab_real title="€ por habitante do territorio" fmt='0.00' />
    <Column id=que_mide title="Que mide" wrap=true />
</DataTable>

## Contratos con empresas de medios

Ademais das campañas de publicidade, as administracións contratan directamente cos medios: insercións e anuncios, patrocinios de foros, xornadas, galas e premios que organizan os propios medios, suplementos especiais, revistas e subscricións a axencias de noticias. Case sempre son contratos menores, de poucos miles de euros, que non aparecen nos informes de publicidade institucional. Buscando na Plataforma de Contratación do Sector Público os contratos adxudicados a unha lista revisada dunhas 800 empresas de medios privados, en {con_ult[0]?.anio} sumaron polo menos {formatCompact(con_ult[0]?.eur_real, 2)} € ({formatNumber(con_ult[0]?.eur_hab_real, 2)} € por habitante) en {formatNumber(con_ult[0]?.contratos, 0)} contratos, o {formatNumber(con_ult[0]?.pct_menores, 0)} % deles menores.

<BarChart
    data={con_anual}
    x=periodo
    sort=false
    y=meur_real
    series=contratante
    yFmt='0.0'
    yAxisTitle="Millóns de euros (descontada a inflación)"
    seriesColors={{'Estado': '#2563eb', 'Comunidades autónomas': '#10b981', 'Ayuntamientos, diputaciones y cabildos': '#a3e635', 'Empresas y entes públicos': '#f59e0b', 'Otros': '#94a3b8'}}
    title="Contratos adxudicados a empresas de medios privados, millóns de euros descontada a inflación (mínimo documentado)"
/>

É un **mínimo**: a Plataforma non recolle os contratos menores das comunidades que teñen plataforma propia (Cataluña, País Vasco, Andalucía, Comunidade de Madrid, Galicia, Navarra e A Rioxa) nin os dalgúns concellos grandes que non os publican alí, e a publicidade que se compra a través de axencias de medios aparece a nome da axencia. Por iso non se comparan comunidades entre si. Os importes son o adxudicado, sen IVE, non o pagado. A serie empeza en 2019 porque cada ano publican máis organismos.

<BarChart
    data={con_categorias}
    x=categoria
    y=meur_real
    swapXY=true
    sort=false
    yFmt='0'
    yAxisTitle="Millóns de euros, 2019-{con_ult[0]?.anio}"
    title="En que se gasta: contratos con medios por tipo, 2019-{con_ult[0]?.anio} (millóns de euros de hoxe)"
/>

<DataTable data={con_grupos} rows=15>
    <Column id=grupo title="Grupo" />
    <Column id=meur_real title="Millóns de euros de hoxe (desde 2019)" fmt='0.0' />
    <Column id=contratos title="Contratos" fmt='#,##0' />
</DataTable>

Cidades de máis de 100.000 habitantes que máis contratan con medios por habitante (media 2022-2025, só o publicado na Plataforma):

<DataTable data={con_municipios} rows=10 search=true>
    <Column id=municipio title="Municipio" />
    <Column id=partido title="Alcaldía (2025)" />
    <Column id=eur_hab_real title="€ por habitante e ano" fmt='0.00' />
    <Column id=eur_real title="Total 2022-2025 (euros de hoxe)" fmt='#,##0' />
    <Column id=contratos title="Contratos" fmt='#,##0' />
</DataTable>

Os maiores contratos de patrocinio e eventos con medios privados:

<DataTable data={con_ejemplos} rows=10 search=true link=url>
    <Column id=anio title="Ano" fmt='0' />
    <Column id=objeto title="Obxecto do contrato" wrap=true />
    <Column id=organo title="Órgano de contratación" wrap=true />
    <Column id=adjudicatario title="Adxudicatario" />
    <Column id=importe_eur_nominal title="Euros sen IVE" fmt='#,##0' />
</DataTable>

## Subvencións a medios privados

Axudas directas a empresas, cooperativas e asociacións editoras de prensa, radio, televisión e medios dixitais privados: axudas estruturais, para o uso de linguas cooficiais, para a dixitalización e a intelixencia artificial ou para proxectos concretos. Non inclúe os medios públicos (xa contados arriba) nin axudas a xornalistas ou universidades.

<BarChart
    data={sub_anual}
    x=periodo
    sort=false
    y=meur_real
    series=concedente
    yFmt='0.0'
    yAxisTitle="Millóns de euros (descontada a inflación)"
    seriesColors={{'Estado': '#2563eb', 'Comunidades autónomas': '#10b981', 'Ayuntamientos, diputaciones y cabildos': '#a3e635'}}
    title="Subvencións concedidas a medios privados, millóns de euros descontada a inflación"
/>

A Base de Datos Nacional de Subvencións só deixa consultar as concesións dos últimos catro anos, por iso a serie empeza en {sub_desde[0]?.desde}; SpainFacts garda unha copia propia para non perder os anos que van saíndo. O ano en curso aparece marcado como incompleto.

### Por comunidade

Subvencións da comunidade e dos seus concellos, deputacións ou cabidos en {sub_ult[0]?.anio}, por habitante da comunidade. As do Estado repártense por toda España e non se inclúen aquí.

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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: BDNS"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'eur_hab_real', title: '€ por habitante', fmt: '0.00'},
        {id: 'eur_hab_autonomico', title: 'Da comunidade', fmt: '0.00'},
        {id: 'eur_hab_local', title: 'De concellos e deputacións', fmt: '0.00'},
        {id: 'concesiones', title: 'Concesións', fmt: '#,##0'}
    ]}
/>

<DataTable data={sub_ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidade" />
    <Column id=eur_hab_real title="€ por habitante" fmt='0.00' />
    <Column id=eur_hab_autonomico title="Da comunidade" fmt='0.00' />
    <Column id=eur_hab_local title="De entidades locais" fmt='0.00' />
    <Column id=importe_nominal title="Euros" fmt='#,##0' />
    <Column id=concesiones title="Concesións" fmt='#,##0' />
    <Column id=partido title="Goberno autonómico" />
</DataTable>

As comunidades que non aparecen non concederon axudas a medios privados ese ano ou non as publicaron na Base de Datos Nacional de Subvencións. **O Goberno Vasco non rexistra alí as súas axudas a medios**, así que no País Vasco só constan as das deputacións forais e os concellos.

### Quen as recibe

As 25 empresas e entidades que máis recibiron desde {sub_desde[0]?.desde}, sumando todos os anos en euros de hoxe. As axudas a persoas físicas (xornalistas autónomos, por exemplo) cóntanse nos totais pero non se mostran por nome.

<DataTable data={sub_beneficiarios} rows=25 search=true>
    <Column id=rango title="Posto" fmt='0' />
    <Column id=nombre title="Beneficiario" />
    <Column id=total_eur_real title="Total (euros de hoxe)" fmt='#,##0' />
    <Column id=concesiones title="Concesións" fmt='0' />
    <Column id=administraciones title="Concedentes" wrap=true />
</DataTable>

## Metodoloxía e fontes

- **Radiotelevisións autonómicas**: [CNMC, Informe Económico Sectorial de las Telecomunicaciones y el Audiovisual](https://www.cnmc.es/sectores-que-regulamos/telecomunicaciones/informes-economicos-sectoriales-anuales), subvencións e transferencias percibidas por cada ente (radio e televisión xuntas), 2017-2025; os gráficos por comunidade transcribíronse a man e a suma cadra co total da CNMC. Desde 2022 a CNMC só dá euros por habitante: os millóns reconstrúense coa poboación do INE. A CNMC non inclúe a Comunidade Valenciana: para À Punt úsanse as achegas de socios das contas da CVMC na [Conta Xeral da Generalitat](https://hisenda.gva.es/es/web/intervencion-general/laconselleria-infogeneral-laintervenciongeneral-cuentas) (2017-2023) e a execución do programa 462D en [dadesobertes.gva.es](https://dadesobertes.gva.es/) (2024-2025). En Castela e León e Murcia a televisión é unha empresa privada cun contrato-programa público.
- **RTVE**: [contas anuais da Corporación RTVE](https://www.rtve.es/rtve/20231016/transparencia-cuentas/943360.shtml), nota de subvencións: compensación por servizo público dos Orzamentos Xerais do Estado, outras subvencións, taxa do espectro e achegas das operadoras (Lei 8/2009). En 2008-2009 son as contas do grupo, que aínda emitía publicidade.
- **Audiencias**: cota de pantalla anual de [Barlovento Comunicación](https://barloventocomunicacion.es/) con datos de Kantar Media (individuos de 4 anos ou máis, con convidados).
- **Publicidade do Estado**: [Comisión de Publicidade e Comunicación Institucional, plans e informes anuais](https://www.lamoncloa.gob.es/serviciosdeprensa/cpci/paginas/planeseinformes.aspx) (Lei 29/2005), custo executado das campañas desde 2006, por tipo de medio, e desde o Informe 2025 por grupo mediático (anexo IV do informe institucional e anexo III do de publicidade comercial). O custo executado inclúe produción e avaliación ademais da compra de espazos; o reparto por grupo é só compra de medios. Os informes non indican se os importes levan IVE (polo xeito en que están redondeados, parece que si). O que cobra cada medio depende ademais dos descontos que negocian as axencias de medios que contratan as campañas.
- **Publicidade de comunidades e concellos**: datos abertos da [Generalitat de Catalunya](https://analisi.transparenciacatalunya.cat/Sector-P-blic/Campanyes-i-promoci-institucional-de-la-Generalita/8d5a-6vsk), da [Junta de Castilla y León](https://analisis.datosabiertos.jcyl.es/explore/dataset/publicidad-institucional/), do [Goberno de Aragón](https://www.aragon.es/transparencia/gestion-fondos-publicos/campanas-publicidad-institucional), do [Goberno de Navarra](https://datosabiertos.navarra.es/dataset/publicidad-institucional), da [Rexión de Murcia](https://transparencia.carm.es/publicidad-institucional), do [Concello de Madrid](https://datos.madrid.es/dataset/300024-0-publicidad-institucional) e do [Ajuntament de Barcelona](https://opendata-ajuntament.barcelona.cat/data/ca/dataset/campanyes-publicitat-institucional); informes en PDF da [Generalitat Valenciana](https://gvaoberta.gva.es/va/publicidad-y-promocion-institucional) (co seu sector público instrumental) e, para o País Vasco, a recompilación das memorias do Goberno Vasco de [gobiernovasco.marketing](https://gobiernovasco.marketing/) (Jaime Gómez-Obregón, CC BY 4.0). Os nomes dos medios agrúpanse por grupo de comunicación cunha táboa de equivalencias de SpainFacts.
- **Empresas públicas**: capítulo de campañas comerciais dos informes anuais da Comisión de Publicidade e Comunicación Institucional (por entidade, 2015-2025); [plans de medios e contas anuais de Canal de Isabel II](https://www.canaldeisabelsegunda.es/en/informacion-economica) (plans por campaña e medio desde 2019; a conta 627, publicidade, propaganda e relacións públicas, só como referencia); [plans de medios da Comunidade de Madrid](https://www.comunidad.madrid/transparencia/gastos-publicidad-y-comunicacion-institucional) (2020-2025, o previsto por campaña e medio, sen IVE); [portal de transparencia de TMB](https://transparencia.tmb.cat/); e as empresas que aparecen nos datos da súa comunidade ou concello. Desde 2024 a cifra de Renfe só inclúe as campañas de Renfe Operadora, non as comerciais de Renfe Viajeros.
- **Contratos con medios**: [Plataforma de Contratación do Sector Público](https://www.hacienda.gob.es/es-ES/GobiernoAbierto/Datos%20Abiertos/Paginas/licitaciones_plataforma_contratacion.aspx) (licitacións dos perfís aloxados, plataformas autonómicas agregadas e contratos menores), desde 2018, e [rexistro de órganos de contratación](https://contrataciondelsectorpublico.gob.es/datosabiertos/OrganosContratacion.xlsx) para saber que administración contrata. Só contan os adxudicatarios dun padrón de NIF de empresas de medios revisado a man (editoras de prensa, radios, televisións privadas, dixitais e axencias de noticias; sen axencias de publicidade, produtoras técnicas nin editoriais de libros). O tipo de contrato dedúcese do texto do obxecto. Descártanse importes absurdos (acordos marco co importe total).
- **Subvencións**: [Base de Datos Nacional de Subvencións](https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones) (IGAE). Úsase unha lista revisada a man de convocatorias de axudas a medios privados (criterio no repositorio de SpainFacts); importe concedido, non pagado, por ano de concesión. Exclúense os medios públicos, as asociacións da prensa e as bolsas.
- **Euros constantes** co IPC do INE e **poboación** do padrón; partido de cada Goberno segundo a táboa de presidentes de SpainFacts.
