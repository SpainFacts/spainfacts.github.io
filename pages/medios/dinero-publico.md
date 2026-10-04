---
title: Dinero público en los medios
description: "Cuánto dinero público reciben los medios de comunicación en España: aportación a RTVE y a las televisiones autonómicas, publicidad institucional y comercial del Estado por grupo mediático y subvenciones a medios privados, por habitante y descontada la inflación, por comunidad y por partido."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
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
       c.ruta
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
       max(c.ruta) AS ruta
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

# <span aria-hidden="true">📰</span> Dinero público en los medios

Las administraciones españolas financian a los medios de comunicación por tres vías: pagan las radiotelevisiones públicas (RTVE y los entes autonómicos), compran publicidad en los medios (también a través de sus empresas públicas) y conceden subvenciones directas a empresas editoras. Todas las cifras se dan **por habitante y descontada la inflación**, en euros de {tv_espana_ult[0]?.anio_base}. Para ver lo que ha recibido un medio concreto, usa el [buscador «Quién recibe qué»](/medios/buscador).

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if tv_espana_ult.length && pub_age_ult.length && sub_ult.length}
    <KpiCard
        title="Radiotelevisiones públicas"
        value={tv_espana_ult[0].total_eur_hab_real}
        formattedValue={formatNumber(tv_espana_ult[0].total_eur_hab_real, 1) + ' €'}
        unit="por habitante"
        period={`${tv_espana_ult[0].anio} · ${formatCompact(tv_espana_ult[0].total_meur_nominal * 1e6, 2)} € entre RTVE y las autonómicas`}
        source="CNMC, RTVE y Generalitat Valenciana"
        direction="positive-down"
        sparklineData={tv_espana.filter(d => d.total_eur_hab_real !== null).map(d => d.total_eur_hab_real)}
    />
    <KpiCard
        title="Publicidad institucional del Estado"
        value={pub_age_ult[0].institucional_eur_hab_real}
        formattedValue={formatNumber(pub_age_ult[0].institucional_eur_hab_real, 2) + ' €'}
        unit="por habitante"
        period={`${pub_age_ult[0].anio} · ${formatCompact(pub_age_ult[0].institucional_eur_nominal, 2)} € en campañas de los ministerios`}
        source="Comisión de Publicidad Institucional"
        direction="positive-down"
        sparklineData={pub_age.map(d => d.institucional_eur_hab_real)}
    />
    <KpiCard
        title="Publicidad de empresas del Estado"
        value={pub_age_ult[0].comercial_eur_hab_real}
        formattedValue={formatNumber(pub_age_ult[0].comercial_eur_hab_real, 2) + ' €'}
        unit="por habitante"
        period={`${pub_age_ult[0].anio} · ${formatCompact(pub_age_ult[0].comercial_eur_nominal, 2)} € (Loterías, AENA, Correos, Renfe...)`}
        source="Comisión de Publicidad Institucional"
        direction="positive-down"
        sparklineData={pub_age.map(d => d.comercial_eur_hab_real)}
    />
    <KpiCard
        title="Subvenciones a medios privados"
        value={sub_ult[0].eur_hab_real}
        formattedValue={formatNumber(sub_ult[0].eur_hab_real, 2) + ' €'}
        unit="por habitante"
        period={`${sub_ult[0].anio} · ${formatCompact(sub_ult[0].eur_nominal, 2)} € en ${formatNumber(sub_ult[0].concesiones, 0)} concesiones`}
        source="Base de Datos Nacional de Subvenciones"
        direction="positive-down"
        sparklineData={sub_espana.filter(d => !d.parcial).map(d => d.eur_hab_real)}
    />
    {/if}
</div>

## Radiotelevisiones públicas

Lo que paga el Estado a RTVE y lo que pagan las comunidades a sus entes de radio y televisión: compensación por servicio público, subvenciones, contratos-programa y aportaciones al capital. En {tv_espana_ult[0]?.anio} fueron {formatNumber(tv_espana_ult[0]?.rtve_eur_hab_real, 1)} € por habitante para RTVE y {formatNumber(tv_espana_ult[0]?.autonomicas_eur_hab_real, 1)} € para los entes autonómicos (calculado sobre toda la población de España, también la de las comunidades que no tienen televisión propia).

<LineChart
    data={tv_series}
    x=anio
    y=eur_hab
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="€ por habitante (euros de {tv_espana_ult[0]?.anio_base})"
    seriesColors={{'RTVE': '#2563eb', 'Radios y televisiones autonómicas': '#f59e0b'}}
    title="Dinero público para las radiotelevisiones públicas, € por habitante descontada la inflación"
/>

La de RTVE incluye desde 2010, cuando dejó de emitir publicidad, la tasa que pagan las operadoras de telecomunicaciones y televisión y la del uso del espectro radioeléctrico. Los años con pagos extraordinarios (la subvención de capital de 2021 para RTVE Play, los 100 millones adicionales de 2024) se ven como picos.

### Por comunidad

Aportación pública a cada ente autonómico en {tv_ccaa[0]?.anio}, por habitante de la comunidad. Va de {formatNumber(tv_extremos[0]?.mas_eur, 1)} € en {tv_extremos[0]?.mas} a {formatNumber(tv_extremos[0]?.menos_eur, 1)} € en {tv_extremos[0]?.menos}. Navarra, Cantabria, La Rioja, Ceuta y Melilla no tienen ente propio.

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: CNMC, Generalitat Valenciana"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'ente', showColumnName: false},
        {id: 'eur_hab_real', title: '€ por habitante', fmt: '0.0'},
        {id: 'meur_nominal', title: 'Millones de euros', fmt: '#,##0.0'},
        {id: 'cuota_audiencia', title: 'Cuota de pantalla (%)', fmt: '0.0'}
    ]}
/>

Para comparar lo que cuesta cada televisión con lo que se ve, la tabla divide los euros por habitante entre la cuota de pantalla de sus cadenas en la comunidad (suma de todos sus canales de televisión). Es una aproximación: el dinero también paga la radio, la web y la producción propia. El que menos cuesta por punto de audiencia es {tv_extremos[0]?.barata} y el que más, {tv_extremos[0]?.cara}.

<DataTable data={tv_ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidad" />
    <Column id=ente title="Ente" />
    <Column id=eur_hab_real title="€ por habitante" fmt='0.0' />
    <Column id=meur_nominal title="Millones de euros" fmt='#,##0.0' />
    <Column id=cuota_audiencia title="Cuota de pantalla %" fmt='0.0' />
    <Column id=eur_hab_real_por_punto_cuota title="€/hab. por punto de cuota" fmt='0.0' />
    <Column id=familia title="Gobierno" />
</DataTable>

<LineChart
    data={tv_ccaa_serie}
    x=anio
    y=eur_hab_real
    series=comunidad
    xFmt='0'
    yFmt='0'
    yAxisTitle="€ por habitante"
    title="Aportación pública a cada ente autonómico, € por habitante descontada la inflación"
/>

### Por partido

Sumando comunidades y años entre {tv_gobiernos[0]?.anio_desde} y {tv_gobiernos[0]?.anio_hasta}, y atribuyendo cada año al partido que gobernaba la comunidad el 1 de julio, la tabla compara la parte del dinero aportado con cada partido con la parte de la población que gobernó (si todos gastaran lo mismo por habitante, la razón sería 1). Solo cuentan las comunidades con ente propio. Con el PP las comunidades aportaron de media {formatNumber(tv_pp_psoe[0]?.pp, 1)} € por habitante y año; con el PSOE, {formatNumber(tv_pp_psoe[0]?.psoe, 1)} €.

<DataTable data={tv_gobiernos} rows=12>
    <Column id=partido title="Partido que gobernaba" />
    <Column id=anios_comunidad title="Años de gobierno (comunidad x año)" fmt='0' />
    <Column id=comunidades title="Comunidades" fmt='0' />
    <Column id=eur_hab_real_anio title="€ por habitante y año" fmt='0.0' />
    <Column id=cuota_dinero title="% del dinero" fmt='0.0' />
    <Column id=cuota_poblacion title="% de la población gobernada" fmt='0.0' />
    <Column id=ratio_observado_esperado title="Observado / esperado" fmt='0.00' />
</DataTable>

Hay que leerlo con cautela: los partidos nacionalistas solo gobiernan una comunidad cada uno, y tres de las comunidades que más aportan por habitante (País Vasco, Cataluña y Galicia) tienen lengua cooficial y sus leyes encargan al ente público la promoción de esa lengua. Además, los entes se crearon hace décadas, así que buena parte del gasto de cada gobierno es heredado.

## Publicidad del Estado

La Administración General del Estado informa cada año del coste de sus campañas de publicidad: las **institucionales** de los ministerios y organismos (Ley 29/2005) y las **comerciales** de sus empresas y entidades públicas (Loterías y Apuestas del Estado, AENA, Correos, Renfe, Paradores...). En {pub_age_ult[0]?.anio} gastó {formatNumber(pub_age_ult[0]?.institucional_eur_hab_real, 2)} € por habitante en campañas institucionales y {formatNumber(pub_age_ult[0]?.comercial_eur_hab_real, 2)} € en comerciales. El máximo de las institucionales fue {pub_age_max[0]?.anio}, con {formatNumber(pub_age_max[0]?.institucional_eur_hab_real, 2)} €.

<BarChart
    data={pub_age_series}
    x=anio
    y=eur_hab
    series=tipo
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="€ por habitante"
    seriesColors={{'Campañas institucionales': '#2563eb', 'Campañas comerciales (empresas y entidades públicas)': '#93c5fd'}}
    title="Publicidad de la Administración General del Estado, € por habitante descontada la inflación"
/>

Media anual de cada Gobierno (cada año cuenta para quien presidía el 1 de julio). El gasto ejecutado se queda siempre por debajo de lo planificado: la última columna es la parte del plan anual que se llegó a gastar.

<DataTable data={pub_gobiernos} rows=10>
    <Column id=presidente title="Presidente" />
    <Column id=partido title="Partido" />
    <Column id=anio_desde title="Desde" fmt='0' />
    <Column id=anio_hasta title="Hasta" fmt='0' />
    <Column id=institucional_eur_hab_real_media title="Institucional, €/hab. y año" fmt='0.00' />
    <Column id=comercial_eur_hab_real_media title="Comercial, €/hab. y año" fmt='0.00' />
    <Column id=ejecucion_pct_media title="% del plan ejecutado" fmt='0' />
</DataTable>

Algunos años incluyen campañas extraordinarias, como las de la pandemia en 2020-2022.

### En qué medios

Reparto de la compra de espacios de las campañas institucionales por tipo de medio. Lo digital ha pasado del {formatNumber(pub_medios_extremos[0]?.digital_ini, 1)} % en {pub_medios_extremos[0]?.anio_ini} al {formatNumber(pub_medios_extremos[0]?.digital_fin, 1)} % en {pub_medios_extremos[0]?.anio_fin}, y la prensa escrita del {formatNumber(pub_medios_extremos[0]?.prensa_ini, 1)} % al {formatNumber(pub_medios_extremos[0]?.prensa_fin, 1)} %.

<AreaChart
    data={pub_medios}
    x=anio
    y=pct
    series=medio
    xFmt='0'
    yFmt='0"%"'
    type=stacked100
    title="Publicidad institucional del Estado por tipo de medio, % de la compra de espacios"
/>

### Qué grupos la reciben

Desde el Informe de {pub_grupos_resumen[0]?.anio}, el primero bajo el Reglamento europeo de libertad de los medios, el Gobierno publica cuánto pagó a cada grupo mediático o plataforma. Los tres primeros grupos se llevaron el {formatNumber(pub_grupos_resumen[0]?.pct_top3, 0)} % de la compra de medios institucional, y las plataformas digitales (Google, Meta, TikTok...), el {formatNumber(pub_grupos_resumen[0]?.pct_plataformas, 0)} %.

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
    title="Publicidad institucional del Estado por grupo, {pub_grupos_resumen[0]?.anio} (€ por habitante)"
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
    title="Publicidad comercial de las empresas del Estado por grupo, {pub_grupos_resumen[0]?.anio} (€ por habitante)"
/>

<DataTable data={pub_grupos} rows=15 search=true>
    <Column id=tipo title="Campañas" />
    <Column id=puesto title="Puesto" fmt='0' />
    <Column id=grupo title="Grupo o empresa" />
    <Column id=clase title="Tipo" />
    <Column id=importe_eur_nominal title="Euros" fmt='#,##0' />
    <Column id=pct title="% del total" fmt='0.0' />
</DataTable>

## Publicidad de comunidades, ayuntamientos y empresas públicas

Las comunidades y los ayuntamientos también compran publicidad, y solo algunos publican cuánto y en qué medios. Estos son los que lo hacen en datos abiertos o en informes que se pueden extraer. No todos miden lo mismo: unos dan lo gastado y otros lo contratado, unos con IVA y otros sin él (la columna «Comparable» marca los que no se pueden comparar directamente con el resto). Cataluña da además el importe neto, sin la comisión de la agencia de medios.

<DataTable data={terr_ult} rows=15>
    <Column id=territorio title="Administración" />
    <Column id=administracion title="Tipo" />
    <Column id=anio title="Año" fmt='0' />
    <Column id=total_eur_hab_real title="€ por habitante" fmt='0.00' />
    <Column id=administracion_eur_hab_real title="De la administración" fmt='0.00' />
    <Column id=empresas_publicas_eur_hab_real title="De sus empresas públicas" fmt='0.00' />
    <Column id=total_eur_nominal title="Euros" fmt='#,##0' />
    <Column id=iva title="IVA" />
    <Column id=base title="Cifra" />
    <Column id=comparable title="Comparable" />
    <Column id=partido title="Gobierno" />
</DataTable>

<LineChart
    data={terr_serie}
    x=anio
    y=total_eur_hab_real
    series=territorio
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="€ por habitante"
    title="Publicidad institucional de comunidades y ayuntamientos, € por habitante descontada la inflación"
/>

Galicia, Canarias, Baleares, Asturias, Cantabria, Castilla-La Mancha y Andalucía no publican su gasto por medio; la Comunidad de Madrid publica sus planes de medios (desde 2020, lo previsto por campaña y medio, sin IVA), pero no lo ejecutado. El País Vasco sale de las memorias que el Gobierno Vasco presenta al Parlamento, reunidas por [gobiernovasco.marketing](https://gobiernovasco.marketing/).

Los cinco grupos que más reciben de cada administración, en el último año con dato:

<DataTable data={terr_grupos} rows=10 search=true>
    <Column id=territorio title="Administración" />
    <Column id=anio title="Año" fmt='0' />
    <Column id=rango title="Puesto" fmt='0' />
    <Column id=grupo title="Grupo o medio" />
    <Column id=titularidad title="Titularidad" />
    <Column id=pct_medios title="% de la publicidad en medios" fmt='0.0' />
    <Column id=importe_eur_nominal title="Euros" fmt='#,##0' />
</DataTable>

### Empresas públicas

Las empresas públicas hacen sus propias campañas, que no siempre aparecen en los informes de publicidad institucional. Las del Estado se recogen en el informe anual de publicidad comercial; Loterías y Apuestas del Estado es, con diferencia, la que más gasta.

<BarChart
    data={loterias}
    x=anio
    y=eur_hab_real
    series=entidad
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="€ por habitante"
    seriesColors={{'Loterías y Apuestas del Estado': '#16a34a', 'Resto de empresas y entidades del Estado': '#86efac'}}
    title="Publicidad comercial de las empresas del Estado, € por habitante descontada la inflación"
/>

De las autonómicas y municipales solo hay datos de las que los publican: Canal de Isabel II (sus planes de medios por campaña y medio desde 2019; sus cuentas anuales, que suman además relaciones públicas y patrocinios, quedan solo como referencia), FGC, Loteries de Catalunya, EMT y Madrid Destino, entre otras. Metro de Madrid no permite descargar sus datos.

<DataTable data={empresas} rows=15 search=true>
    <Column id=entidad title="Empresa o entidad" />
    <Column id=ambito title="De" />
    <Column id=territorio title="Territorio" />
    <Column id=anio title="Año" fmt='0' />
    <Column id=importe_eur_nominal title="Euros" fmt='#,##0' />
    <Column id=eur_hab_real title="€ por habitante del territorio" fmt='0.00' />
    <Column id=que_mide title="Qué mide" wrap=true />
</DataTable>

## Contratos con empresas de medios

Además de las campañas de publicidad, las administraciones contratan directamente con los medios: inserciones y anuncios, patrocinios de foros, jornadas, galas y premios que organizan los propios medios, suplementos especiales, revistas y suscripciones a agencias de noticias. Casi siempre son contratos menores, de pocos miles de euros, que no aparecen en los informes de publicidad institucional. Buscando en la Plataforma de Contratación del Sector Público los contratos adjudicados a una lista revisada de unas 800 empresas de medios privados, en {con_ult[0]?.anio} sumaron al menos {formatCompact(con_ult[0]?.eur_real, 2)} € ({formatNumber(con_ult[0]?.eur_hab_real, 2)} € por habitante) en {formatNumber(con_ult[0]?.contratos, 0)} contratos, el {formatNumber(con_ult[0]?.pct_menores, 0)} % de ellos menores.

<BarChart
    data={con_anual}
    x=periodo
    sort=false
    y=meur_real
    series=contratante
    yFmt='0.0'
    yAxisTitle="Millones de euros (descontada la inflación)"
    seriesColors={{'Estado': '#2563eb', 'Comunidades autónomas': '#10b981', 'Ayuntamientos, diputaciones y cabildos': '#a3e635', 'Empresas y entes públicos': '#f59e0b', 'Otros': '#94a3b8'}}
    title="Contratos adjudicados a empresas de medios privados, millones de euros descontada la inflación (mínimo documentado)"
/>

Es un **mínimo**: la Plataforma no recoge los contratos menores de las comunidades que tienen plataforma propia (Cataluña, País Vasco, Andalucía, Comunidad de Madrid, Galicia, Navarra y La Rioja) ni los de algunos ayuntamientos grandes que no los publican allí, y la publicidad que se compra a través de agencias de medios aparece a nombre de la agencia. Por eso no se comparan comunidades entre sí. Los importes son lo adjudicado, sin IVA, no lo pagado. La serie empieza en 2019 porque cada año publican más organismos.

<BarChart
    data={con_categorias}
    x=categoria
    y=meur_real
    swapXY=true
    sort=false
    yFmt='0'
    yAxisTitle="Millones de euros, 2019-{con_ult[0]?.anio}"
    title="En qué se gasta: contratos con medios por tipo, 2019-{con_ult[0]?.anio} (millones de euros de hoy)"
/>

<DataTable data={con_grupos} rows=15>
    <Column id=grupo title="Grupo" />
    <Column id=meur_real title="Millones de euros de hoy (desde 2019)" fmt='0.0' />
    <Column id=contratos title="Contratos" fmt='#,##0' />
</DataTable>

Ciudades de más de 100.000 habitantes que más contratan con medios por habitante (media 2022-2025, solo lo publicado en la Plataforma):

<DataTable data={con_municipios} rows=10 search=true>
    <Column id=municipio title="Municipio" />
    <Column id=partido title="Alcaldía (2025)" />
    <Column id=eur_hab_real title="€ por habitante y año" fmt='0.00' />
    <Column id=eur_real title="Total 2022-2025 (euros de hoy)" fmt='#,##0' />
    <Column id=contratos title="Contratos" fmt='#,##0' />
</DataTable>

Los mayores contratos de patrocinio y eventos con medios privados:

<DataTable data={con_ejemplos} rows=10 search=true link=url>
    <Column id=anio title="Año" fmt='0' />
    <Column id=objeto title="Objeto del contrato" wrap=true />
    <Column id=organo title="Órgano de contratación" wrap=true />
    <Column id=adjudicatario title="Adjudicatario" />
    <Column id=importe_eur_nominal title="Euros sin IVA" fmt='#,##0' />
</DataTable>

## Subvenciones a medios privados

Ayudas directas a empresas, cooperativas y asociaciones editoras de prensa, radio, televisión y medios digitales privados: ayudas estructurales, para el uso de lenguas cooficiales, para la digitalización y la inteligencia artificial o para proyectos concretos. No incluye a los medios públicos (ya contados arriba) ni ayudas a periodistas o universidades.

<BarChart
    data={sub_anual}
    x=periodo
    sort=false
    y=meur_real
    series=concedente
    yFmt='0.0'
    yAxisTitle="Millones de euros (descontada la inflación)"
    seriesColors={{'Estado': '#2563eb', 'Comunidades autónomas': '#10b981', 'Ayuntamientos, diputaciones y cabildos': '#a3e635'}}
    title="Subvenciones concedidas a medios privados, millones de euros descontada la inflación"
/>

La Base de Datos Nacional de Subvenciones solo deja consultar las concesiones de los últimos cuatro años, por eso la serie empieza en {sub_desde[0]?.desde}; SpainFacts guarda una copia propia para no perder los años que van saliendo. El año en curso aparece marcado como incompleto.

### Por comunidad

Subvenciones de la comunidad y de sus ayuntamientos, diputaciones o cabildos en {sub_ult[0]?.anio}, por habitante de la comunidad. Las del Estado se reparten por toda España y no se incluyen aquí.

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: BDNS"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'eur_hab_real', title: '€ por habitante', fmt: '0.00'},
        {id: 'eur_hab_autonomico', title: 'De la comunidad', fmt: '0.00'},
        {id: 'eur_hab_local', title: 'De ayuntamientos y diputaciones', fmt: '0.00'},
        {id: 'concesiones', title: 'Concesiones', fmt: '#,##0'}
    ]}
/>

<DataTable data={sub_ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunidad" />
    <Column id=eur_hab_real title="€ por habitante" fmt='0.00' />
    <Column id=eur_hab_autonomico title="De la comunidad" fmt='0.00' />
    <Column id=eur_hab_local title="De entidades locales" fmt='0.00' />
    <Column id=importe_nominal title="Euros" fmt='#,##0' />
    <Column id=concesiones title="Concesiones" fmt='#,##0' />
    <Column id=partido title="Gobierno autonómico" />
</DataTable>

Las comunidades que no aparecen no concedieron ayudas a medios privados ese año o no las publicaron en la Base de Datos Nacional de Subvenciones. **El Gobierno Vasco no registra allí sus ayudas a medios**, así que en el País Vasco solo constan las de las diputaciones forales y los ayuntamientos.

### Quién las recibe

Las 25 empresas y entidades que más han recibido desde {sub_desde[0]?.desde}, sumando todos los años en euros de hoy. Las ayudas a personas físicas (periodistas autónomos, por ejemplo) se cuentan en los totales pero no se muestran por nombre.

<DataTable data={sub_beneficiarios} rows=25 search=true>
    <Column id=rango title="Puesto" fmt='0' />
    <Column id=nombre title="Beneficiario" />
    <Column id=total_eur_real title="Total (euros de hoy)" fmt='#,##0' />
    <Column id=concesiones title="Concesiones" fmt='0' />
    <Column id=administraciones title="Concedentes" wrap=true />
</DataTable>

## Metodología y fuentes

- **Radiotelevisiones autonómicas**: [CNMC, Informe Económico Sectorial de las Telecomunicaciones y el Audiovisual](https://www.cnmc.es/sectores-que-regulamos/telecomunicaciones/informes-economicos-sectoriales-anuales), subvenciones y transferencias percibidas por cada ente (radio y televisión juntas), 2017-2025; los gráficos por comunidad se han transcrito a mano y la suma cuadra con el total de la CNMC. Desde 2022 la CNMC solo da euros por habitante: los millones se reconstruyen con la población del INE. La CNMC no incluye a la Comunitat Valenciana: para À Punt se usan las aportaciones de socios de las cuentas de la CVMC en la [Cuenta General de la Generalitat](https://hisenda.gva.es/es/web/intervencion-general/laconselleria-infogeneral-laintervenciongeneral-cuentas) (2017-2023) y la ejecución del programa 462D en [dadesobertes.gva.es](https://dadesobertes.gva.es/) (2024-2025). En Castilla y León y Murcia la televisión es una empresa privada con un contrato-programa público.
- **RTVE**: [cuentas anuales de la Corporación RTVE](https://www.rtve.es/rtve/20231016/transparencia-cuentas/943360.shtml), nota de subvenciones: compensación por servicio público de los Presupuestos Generales del Estado, otras subvenciones, tasa del espectro y aportaciones de las operadoras (Ley 8/2009). En 2008-2009 son las cuentas del grupo, que aún emitía publicidad.
- **Audiencias**: cuota de pantalla anual de [Barlovento Comunicación](https://barloventocomunicacion.es/) con datos de Kantar Media (individuos de 4 años o más, con invitados).
- **Publicidad del Estado**: [Comisión de Publicidad y Comunicación Institucional, planes e informes anuales](https://www.lamoncloa.gob.es/serviciosdeprensa/cpci/paginas/planeseinformes.aspx) (Ley 29/2005), coste ejecutado de las campañas desde 2006, por tipo de medio, y desde el Informe 2025 por grupo mediático (anexo IV del informe institucional y anexo III del de publicidad comercial). El coste ejecutado incluye producción y evaluación además de la compra de espacios; el reparto por grupo es solo compra de medios. Los informes no indican si los importes llevan IVA (por cómo están redondeados, parece que sí). Lo que cobra cada medio depende además de los descuentos que negocian las agencias de medios que contratan las campañas.
- **Publicidad de comunidades y ayuntamientos**: datos abiertos de la [Generalitat de Catalunya](https://analisi.transparenciacatalunya.cat/Sector-P-blic/Campanyes-i-promoci-institucional-de-la-Generalita/8d5a-6vsk), la [Junta de Castilla y León](https://analisis.datosabiertos.jcyl.es/explore/dataset/publicidad-institucional/), el [Gobierno de Aragón](https://www.aragon.es/transparencia/gestion-fondos-publicos/campanas-publicidad-institucional), el [Gobierno de Navarra](https://datosabiertos.navarra.es/dataset/publicidad-institucional), la [Región de Murcia](https://transparencia.carm.es/publicidad-institucional), el [Ayuntamiento de Madrid](https://datos.madrid.es/dataset/300024-0-publicidad-institucional) y el [Ajuntament de Barcelona](https://opendata-ajuntament.barcelona.cat/data/ca/dataset/campanyes-publicitat-institucional); informes en PDF de la [Generalitat Valenciana](https://gvaoberta.gva.es/va/publicidad-y-promocion-institucional) (con su sector público instrumental) y, para el País Vasco, la recopilación de las memorias del Gobierno Vasco de [gobiernovasco.marketing](https://gobiernovasco.marketing/) (Jaime Gómez-Obregón, CC BY 4.0). Los nombres de los medios se agrupan por grupo de comunicación con una tabla de equivalencias de SpainFacts.
- **Empresas públicas**: capítulo de campañas comerciales de los informes anuales de la Comisión de Publicidad y Comunicación Institucional (por entidad, 2015-2025); [planes de medios y cuentas anuales de Canal de Isabel II](https://www.canaldeisabelsegunda.es/en/informacion-economica) (planes por campaña y medio desde 2019; la cuenta 627, publicidad, propaganda y relaciones públicas, solo como referencia); [planes de medios de la Comunidad de Madrid](https://www.comunidad.madrid/transparencia/gastos-publicidad-y-comunicacion-institucional) (2020-2025, lo previsto por campaña y medio, sin IVA); [portal de transparencia de TMB](https://transparencia.tmb.cat/); y las empresas que aparecen en los datos de su comunidad o ayuntamiento. Desde 2024 la cifra de Renfe solo incluye las campañas de Renfe Operadora, no las comerciales de Renfe Viajeros.
- **Contratos con medios**: [Plataforma de Contratación del Sector Público](https://www.hacienda.gob.es/es-ES/GobiernoAbierto/Datos%20Abiertos/Paginas/licitaciones_plataforma_contratacion.aspx) (licitaciones de los perfiles alojados, plataformas autonómicas agregadas y contratos menores), desde 2018, y [registro de órganos de contratación](https://contrataciondelsectorpublico.gob.es/datosabiertos/OrganosContratacion.xlsx) para saber qué administración contrata. Solo cuentan los adjudicatarios de un padrón de NIF de empresas de medios revisado a mano (editoras de prensa, radios, televisiones privadas, digitales y agencias de noticias; sin agencias de publicidad, productoras técnicas ni editoriales de libros). El tipo de contrato se deduce del texto del objeto. Se descartan importes absurdos (acuerdos marco con el importe total).
- **Subvenciones**: [Base de Datos Nacional de Subvenciones](https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones) (IGAE). Se usa una lista revisada a mano de convocatorias de ayudas a medios privados (criterio en el repositorio de SpainFacts); importe concedido, no pagado, por año de concesión. Se excluyen los medios públicos, las asociaciones de la prensa y las becas.
- **Euros constantes** con el IPC del INE y **población** del padrón; partido de cada Gobierno según la tabla de presidentes de SpainFacts.
