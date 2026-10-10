---
title: Diners públics als mitjans
description: "Quants diners públics reben els mitjans de comunicació a Espanya: aportació a RTVE i a les televisions autonòmiques, publicitat institucional i comercial de l'Estat per grup mediàtic i subvencions a mitjans privats, per habitant i descomptada la inflació, per comunitat i per partit."
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
       '/ca' || c.ruta AS ruta
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
       CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (incomplet)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo,
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
       CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (incomplet)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo
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
       '/ca' || max(c.ruta) AS ruta
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

# <span aria-hidden="true">📰</span> Diners públics als mitjans

Les administracions espanyoles financen els mitjans de comunicació per tres vies: paguen les ràdios i televisions públiques (RTVE i els ens autonòmics), compren publicitat als mitjans (també a través de les seves empreses públiques) i concedeixen subvencions directes a empreses editores. Totes les xifres es donen **per habitant i descomptada la inflació**, en euros del {tv_espana_ult[0]?.anio_base}. Per veure el que ha rebut un mitjà concret, fes servir el [cercador «Qui rep què»](/ca/medios/buscador).

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if tv_espana_ult.length && pub_age_ult.length && sub_ult.length}
    <KpiCard
        title="Ràdios i televisions públiques"
        value={tv_espana_ult[0].total_eur_hab_real}
        formattedValue={formatNumber(tv_espana_ult[0].total_eur_hab_real, 1) + ' €'}
        unit="per habitant"
        period={`${tv_espana_ult[0].anio} · ${formatCompact(tv_espana_ult[0].total_meur_nominal * 1e6, 2)} € entre RTVE i les autonòmiques`}
        source="CNMC, RTVE i Generalitat Valenciana"
        direction="positive-down"
        sparklineData={tv_espana.filter(d => d.total_eur_hab_real !== null).map(d => ({...d, y: d.total_eur_hab_real}))}
    />
    <KpiCard
        title="Publicitat institucional de l'Estat"
        value={pub_age_ult[0].institucional_eur_hab_real}
        formattedValue={formatNumber(pub_age_ult[0].institucional_eur_hab_real, 2) + ' €'}
        unit="per habitant"
        period={`${pub_age_ult[0].anio} · ${formatCompact(pub_age_ult[0].institucional_eur_nominal, 2)} € en campanyes dels ministeris`}
        source="Comissió de Publicitat Institucional"
        direction="positive-down"
        sparklineData={pub_age.map(d => ({...d, y: d.institucional_eur_hab_real}))}
    />
    <KpiCard
        title="Publicitat d'empreses de l'Estat"
        value={pub_age_ult[0].comercial_eur_hab_real}
        formattedValue={formatNumber(pub_age_ult[0].comercial_eur_hab_real, 2) + ' €'}
        unit="per habitant"
        period={`${pub_age_ult[0].anio} · ${formatCompact(pub_age_ult[0].comercial_eur_nominal, 2)} € (Loterías, AENA, Correos, Renfe...)`}
        source="Comissió de Publicitat Institucional"
        direction="positive-down"
        sparklineData={pub_age.map(d => ({...d, y: d.comercial_eur_hab_real}))}
    />
    <KpiCard
        title="Subvencions a mitjans privats"
        value={sub_ult[0].eur_hab_real}
        formattedValue={formatNumber(sub_ult[0].eur_hab_real, 2) + ' €'}
        unit="per habitant"
        period={`${sub_ult[0].anio} · ${formatCompact(sub_ult[0].eur_nominal, 2)} € en ${formatNumber(sub_ult[0].concesiones, 0)} concessions`}
        source="Base de Dades Nacional de Subvencions"
        direction="positive-down"
        sparklineData={sub_espana.filter(d => !d.parcial).map(d => ({...d, y: d.eur_hab_real}))}
    />
    {/if}
</div>

## Ràdios i televisions públiques

El que paga l'Estat a RTVE i el que paguen les comunitats als seus ens de ràdio i televisió: compensació per servei públic, subvencions, contractes programa i aportacions al capital. El {tv_espana_ult[0]?.anio} van ser {formatNumber(tv_espana_ult[0]?.rtve_eur_hab_real, 1)} € per habitant per a RTVE i {formatNumber(tv_espana_ult[0]?.autonomicas_eur_hab_real, 1)} € per als ens autonòmics (calculat sobre tota la població d'Espanya, també la de les comunitats que no tenen televisió pròpia).

<LineChart
    data={tv_series}
    x=anio
    y=eur_hab
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="€ per habitant (euros del {tv_espana_ult[0]?.anio_base})"
    seriesColors={{'RTVE': '#2563eb', 'Radios y televisiones autonómicas': '#f59e0b'}}
    title="Diners públics per a les ràdios i televisions públiques, € per habitant descomptada la inflació"
/>

La de RTVE inclou des del 2010, quan va deixar d'emetre publicitat, la taxa que paguen les operadores de telecomunicacions i televisió i la de l'ús de l'espectre radioelèctric. Els anys amb pagaments extraordinaris (la subvenció de capital del 2021 per a RTVE Play, els 100 milions addicionals del 2024) es veuen com a pics.

### Per comunitat

Aportació pública a cada ens autonòmic el {tv_ccaa[0]?.anio}, per habitant de la comunitat. Va de {formatNumber(tv_extremos[0]?.mas_eur, 1)} € a {tv_extremos[0]?.mas} a {formatNumber(tv_extremos[0]?.menos_eur, 1)} € a {tv_extremos[0]?.menos}. Navarra, Cantàbria, La Rioja, Ceuta i Melilla no tenen ens propi.

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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: CNMC, Generalitat Valenciana"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'ente', showColumnName: false},
        {id: 'eur_hab_real', title: '€ per habitant', fmt: '0.0'},
        {id: 'meur_nominal', title: "Milions d'euros", fmt: '#,##0.0'},
        {id: 'cuota_audiencia', title: 'Quota de pantalla (%)', fmt: '0.0'}
    ]}
/>

Per comparar el que costa cada televisió amb el que es veu, la taula divideix els euros per habitant entre la quota de pantalla dels seus canals a la comunitat (suma de tots els seus canals de televisió). És una aproximació: els diners també paguen la ràdio, el web i la producció pròpia. El que menys costa per punt d'audiència és {tv_extremos[0]?.barata} i el que més, {tv_extremos[0]?.cara}.

<DataTable data={tv_ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=ente title="Ens" />
    <Column id=eur_hab_real title="€ per habitant" fmt='0.0' />
    <Column id=meur_nominal title="Milions d'euros" fmt='#,##0.0' />
    <Column id=cuota_audiencia title="Quota de pantalla %" fmt='0.0' />
    <Column id=eur_hab_real_por_punto_cuota title="€/hab. per punt de quota" fmt='0.0' />
    <Column id=familia title="Govern" />
</DataTable>

<LineChart
    data={tv_ccaa_serie}
    x=anio
    y=eur_hab_real
    series=comunidad
    xFmt='0'
    yFmt='0'
    yAxisTitle="€ per habitant"
    title="Aportació pública a cada ens autonòmic, € per habitant descomptada la inflació"
/>

### Per partit

Sumant comunitats i anys entre el {tv_gobiernos[0]?.anio_desde} i el {tv_gobiernos[0]?.anio_hasta}, i atribuint cada any al partit que governava la comunitat l'1 de juliol, la taula compara la part dels diners aportats amb cada partit amb la part de la població que va governar (si tots gastessin el mateix per habitant, la raó seria 1). Només compten les comunitats amb ens propi. Amb el PP les comunitats van aportar de mitjana {formatNumber(tv_pp_psoe[0]?.pp, 1)} € per habitant i any; amb el PSOE, {formatNumber(tv_pp_psoe[0]?.psoe, 1)} €.

<DataTable data={tv_gobiernos} rows=12>
    <Column id=partido title="Partit que governava" />
    <Column id=anios_comunidad title="Anys de govern (comunitat x any)" fmt='0' />
    <Column id=comunidades title="Comunitats" fmt='0' />
    <Column id=eur_hab_real_anio title="€ per habitant i any" fmt='0.0' />
    <Column id=cuota_dinero title="% dels diners" fmt='0.0' />
    <Column id=cuota_poblacion title="% de la població governada" fmt='0.0' />
    <Column id=ratio_observado_esperado title="Observat / esperat" fmt='0.00' />
</DataTable>

Cal llegir-ho amb cautela: els partits nacionalistes només governen una comunitat cadascun, i tres de les comunitats que més aporten per habitant (País Basc, Catalunya i Galícia) tenen llengua cooficial i les seves lleis encarreguen a l'ens públic la promoció d'aquesta llengua. A més, els ens es van crear fa dècades, així que bona part de la despesa de cada govern és heretada.

## Publicitat de l'Estat

L'Administració General de l'Estat informa cada any del cost de les seves campanyes de publicitat: les **institucionals** dels ministeris i organismes (Llei 29/2005) i les **comercials** de les seves empreses i entitats públiques (Loterías y Apuestas del Estado, AENA, Correos, Renfe, Paradores...). El {pub_age_ult[0]?.anio} va gastar {formatNumber(pub_age_ult[0]?.institucional_eur_hab_real, 2)} € per habitant en campanyes institucionals i {formatNumber(pub_age_ult[0]?.comercial_eur_hab_real, 2)} € en comercials. El màxim de les institucionals va ser el {pub_age_max[0]?.anio}, amb {formatNumber(pub_age_max[0]?.institucional_eur_hab_real, 2)} €.

<BarChart
    data={pub_age_series}
    x=anio
    y=eur_hab
    series=tipo
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="€ per habitant"
    seriesColors={{'Campañas institucionales': '#2563eb', 'Campañas comerciales (empresas y entidades públicas)': '#93c5fd'}}
    title="Publicitat de l'Administració General de l'Estat, € per habitant descomptada la inflació"
/>

Mitjana anual de cada Govern (cada any compta per a qui presidia l'1 de juliol). La despesa executada queda sempre per sota de la planificada: l'última columna és la part del pla anual que es va arribar a gastar.

<DataTable data={pub_gobiernos} rows=10>
    <Column id=presidente title="President" />
    <Column id=partido title="Partit" />
    <Column id=anio_desde title="Des de" fmt='0' />
    <Column id=anio_hasta title="Fins a" fmt='0' />
    <Column id=institucional_eur_hab_real_media title="Institucional, €/hab. i any" fmt='0.00' />
    <Column id=comercial_eur_hab_real_media title="Comercial, €/hab. i any" fmt='0.00' />
    <Column id=ejecucion_pct_media title="% del pla executat" fmt='0' />
</DataTable>

Alguns anys inclouen campanyes extraordinàries, com les de la pandèmia el 2020-2022.

### En quins mitjans

Repartiment de la compra d'espais de les campanyes institucionals per tipus de mitjà. El digital ha passat del {formatNumber(pub_medios_extremos[0]?.digital_ini, 1)} % el {pub_medios_extremos[0]?.anio_ini} al {formatNumber(pub_medios_extremos[0]?.digital_fin, 1)} % el {pub_medios_extremos[0]?.anio_fin}, i la premsa escrita del {formatNumber(pub_medios_extremos[0]?.prensa_ini, 1)} % al {formatNumber(pub_medios_extremos[0]?.prensa_fin, 1)} %.

<AreaChart
    data={pub_medios}
    x=anio
    y=pct
    series=medio
    xFmt='0'
    yFmt='0"%"'
    type=stacked100
    title="Publicitat institucional de l'Estat per tipus de mitjà, % de la compra d'espais"
/>

### Quins grups la reben

Des de l'Informe del {pub_grupos_resumen[0]?.anio}, el primer sota el Reglament europeu de llibertat dels mitjans, el Govern publica quant va pagar a cada grup mediàtic o plataforma. Els tres primers grups es van endur el {formatNumber(pub_grupos_resumen[0]?.pct_top3, 0)} % de la compra de mitjans institucional, i les plataformes digitals (Google, Meta, TikTok...), el {formatNumber(pub_grupos_resumen[0]?.pct_plataformas, 0)} %.

<BarChart
    data={pub_grupos_inst}
    x=grupo
    y=eur_hab_real
    series=clase
    swapXY=true
    sort=false
    yFmt='0.00'
    yAxisTitle="€ per habitant"
    seriesColors={{'Grupo de medios': '#2563eb', 'Plataforma digital': '#a855f7', 'Medio público': '#f59e0b'}}
    title="Publicitat institucional de l'Estat per grup, {pub_grupos_resumen[0]?.anio} (€ per habitant)"
/>

<BarChart
    data={pub_grupos_com}
    x=grupo
    y=eur_hab_real
    series=clase
    swapXY=true
    sort=false
    yFmt='0.00'
    yAxisTitle="€ per habitant"
    seriesColors={{'Grupo de medios': '#2563eb', 'Plataforma digital': '#a855f7', 'Medio público': '#f59e0b'}}
    title="Publicitat comercial de les empreses de l'Estat per grup, {pub_grupos_resumen[0]?.anio} (€ per habitant)"
/>

<DataTable data={pub_grupos} rows=15 search=true>
    <Column id=tipo title="Campanyes" />
    <Column id=puesto title="Lloc" fmt='0' />
    <Column id=grupo title="Grup o empresa" />
    <Column id=clase title="Tipus" />
    <Column id=importe_eur_nominal title="Euros" fmt='#,##0' />
    <Column id=pct title="% del total" fmt='0.0' />
</DataTable>

## Publicitat de comunitats, ajuntaments i empreses públiques

Les comunitats i els ajuntaments també compren publicitat, i només alguns publiquen quant i en quins mitjans. Aquests són els que ho fan en dades obertes o en informes que es poden extreure. No tots mesuren el mateix: uns donen el que s'ha gastat i altres el que s'ha contractat, uns amb IVA i altres sense (la columna «Comparable» marca els que no es poden comparar directament amb la resta). Catalunya dona a més l'import net, sense la comissió de l'agència de mitjans.

<DataTable data={terr_ult} rows=15>
    <Column id=territorio title="Administració" />
    <Column id=administracion title="Tipus" />
    <Column id=anio title="Any" fmt='0' />
    <Column id=total_eur_hab_real title="€ per habitant" fmt='0.00' />
    <Column id=administracion_eur_hab_real title="De l'administració" fmt='0.00' />
    <Column id=empresas_publicas_eur_hab_real title="De les seves empreses públiques" fmt='0.00' />
    <Column id=total_eur_nominal title="Euros" fmt='#,##0' />
    <Column id=iva title="IVA" />
    <Column id=base title="Xifra" />
    <Column id=comparable title="Comparable" />
    <Column id=partido title="Govern" />
</DataTable>

<LineChart
    data={terr_serie}
    x=anio
    y=total_eur_hab_real
    series=territorio
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="€ per habitant"
    title="Publicitat institucional de comunitats i ajuntaments, € per habitant descomptada la inflació"
/>

Galícia, Canàries, Balears, Astúries, Cantàbria, Castella-la Manxa i Andalusia no publiquen la seva despesa per mitjà; la Comunitat de Madrid publica els seus plans de mitjans (des del 2020, el que es preveu per campanya i mitjà, sense IVA), però no el que s'ha executat. El País Basc surt de les memòries que el Govern Basc presenta al Parlament, recollides per [gobiernovasco.marketing](https://gobiernovasco.marketing/).

Els cinc grups que més reben de cada administració, en l'últim any amb dada:

<DataTable data={terr_grupos} rows=10 search=true>
    <Column id=territorio title="Administració" />
    <Column id=anio title="Any" fmt='0' />
    <Column id=rango title="Lloc" fmt='0' />
    <Column id=grupo title="Grup o mitjà" />
    <Column id=titularidad title="Titularitat" />
    <Column id=pct_medios title="% de la publicitat en mitjans" fmt='0.0' />
    <Column id=importe_eur_nominal title="Euros" fmt='#,##0' />
</DataTable>

### Empreses públiques

Les empreses públiques fan les seves pròpies campanyes, que no sempre apareixen en els informes de publicitat institucional. Les de l'Estat es recullen a l'informe anual de publicitat comercial; Loterías y Apuestas del Estado és, amb diferència, la que més gasta.

<BarChart
    data={loterias}
    x=anio
    y=eur_hab_real
    series=entidad
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="€ per habitant"
    seriesColors={{'Loterías y Apuestas del Estado': '#16a34a', 'Resto de empresas y entidades del Estado': '#86efac'}}
    title="Publicitat comercial de les empreses de l'Estat, € per habitant descomptada la inflació"
/>

De les autonòmiques i municipals només hi ha dades de les que les publiquen: Canal de Isabel II (els seus plans de mitjans per campanya i mitjà des del 2019; els comptes anuals, que sumen a més relacions públiques i patrocinis, queden només com a referència), FGC, Loteries de Catalunya, EMT i Madrid Destino, entre d'altres. Metro de Madrid no permet descarregar les seves dades.

<DataTable data={empresas} rows=15 search=true>
    <Column id=entidad title="Empresa o entitat" />
    <Column id=ambito title="De" />
    <Column id=territorio title="Territori" />
    <Column id=anio title="Any" fmt='0' />
    <Column id=importe_eur_nominal title="Euros" fmt='#,##0' />
    <Column id=eur_hab_real title="€ per habitant del territori" fmt='0.00' />
    <Column id=que_mide title="Què mesura" wrap=true />
</DataTable>

## Contractes amb empreses de mitjans

A més de les campanyes de publicitat, les administracions contracten directament amb els mitjans: insercions i anuncis, patrocinis de fòrums, jornades, gales i premis que organitzen els mateixos mitjans, suplements especials, revistes i subscripcions a agències de notícies. Gairebé sempre són contractes menors, de pocs milers d'euros, que no apareixen en els informes de publicitat institucional. Cercant a la Plataforma de Contractació del Sector Públic els contractes adjudicats a una llista revisada d'unes 800 empreses de mitjans privats, el {con_ult[0]?.anio} van sumar almenys {formatCompact(con_ult[0]?.eur_real, 2)} € ({formatNumber(con_ult[0]?.eur_hab_real, 2)} € per habitant) en {formatNumber(con_ult[0]?.contratos, 0)} contractes, el {formatNumber(con_ult[0]?.pct_menores, 0)} % d'ells menors.

<BarChart
    data={con_anual}
    x=periodo
    sort=false
    y=meur_real
    series=contratante
    yFmt='0.0'
    yAxisTitle="Milions d'euros (descomptada la inflació)"
    seriesColors={{'Estado': '#2563eb', 'Comunidades autónomas': '#10b981', 'Ayuntamientos, diputaciones y cabildos': '#a3e635', 'Empresas y entes públicos': '#f59e0b', 'Otros': '#94a3b8'}}
    title="Contractes adjudicats a empreses de mitjans privats, milions d'euros descomptada la inflació (mínim documentat)"
/>

És un **mínim**: la Plataforma no recull els contractes menors de les comunitats que tenen plataforma pròpia (Catalunya, País Basc, Andalusia, Comunitat de Madrid, Galícia, Navarra i La Rioja) ni els d'alguns ajuntaments grans que no els hi publiquen, i la publicitat que es compra a través d'agències de mitjans apareix a nom de l'agència. Per això no es comparen comunitats entre si. Els imports són el que s'ha adjudicat, sense IVA, no el que s'ha pagat. La sèrie comença el 2019 perquè cada any hi publiquen més organismes.

<BarChart
    data={con_categorias}
    x=categoria
    y=meur_real
    swapXY=true
    sort=false
    yFmt='0'
    yAxisTitle="Milions d'euros, 2019-{con_ult[0]?.anio}"
    title="En què es gasta: contractes amb mitjans per tipus, 2019-{con_ult[0]?.anio} (milions d'euros d'avui)"
/>

<DataTable data={con_grupos} rows=15>
    <Column id=grupo title="Grup" />
    <Column id=meur_real title="Milions d'euros d'avui (des del 2019)" fmt='0.0' />
    <Column id=contratos title="Contractes" fmt='#,##0' />
</DataTable>

Ciutats de més de 100.000 habitants que més contracten amb mitjans per habitant (mitjana 2022-2025, només el que s'ha publicat a la Plataforma):

<DataTable data={con_municipios} rows=10 search=true>
    <Column id=municipio title="Municipi" />
    <Column id=partido title="Alcaldia (2025)" />
    <Column id=eur_hab_real title="€ per habitant i any" fmt='0.00' />
    <Column id=eur_real title="Total 2022-2025 (euros d'avui)" fmt='#,##0' />
    <Column id=contratos title="Contractes" fmt='#,##0' />
</DataTable>

Els contractes més grans de patrocini i esdeveniments amb mitjans privats:

<DataTable data={con_ejemplos} rows=10 search=true link=url>
    <Column id=anio title="Any" fmt='0' />
    <Column id=objeto title="Objecte del contracte" wrap=true />
    <Column id=organo title="Òrgan de contractació" wrap=true />
    <Column id=adjudicatario title="Adjudicatari" />
    <Column id=importe_eur_nominal title="Euros sense IVA" fmt='#,##0' />
</DataTable>

## Subvencions a mitjans privats

Ajuts directes a empreses, cooperatives i associacions editores de premsa, ràdio, televisió i mitjans digitals privats: ajuts estructurals, per a l'ús de llengües cooficials, per a la digitalització i la intel·ligència artificial o per a projectes concrets. No inclou els mitjans públics (ja comptats a dalt) ni ajuts a periodistes o universitats.

<BarChart
    data={sub_anual}
    x=periodo
    sort=false
    y=meur_real
    series=concedente
    yFmt='0.0'
    yAxisTitle="Milions d'euros (descomptada la inflació)"
    seriesColors={{'Estado': '#2563eb', 'Comunidades autónomas': '#10b981', 'Ayuntamientos, diputaciones y cabildos': '#a3e635'}}
    title="Subvencions concedides a mitjans privats, milions d'euros descomptada la inflació"
/>

La Base de Dades Nacional de Subvencions només deixa consultar les concessions dels últims quatre anys, per això la sèrie comença el {sub_desde[0]?.desde}; SpainFacts en guarda una còpia pròpia per no perdre els anys que van sortint. L'any en curs apareix marcat com a incomplet.

### Per comunitat

Subvencions de la comunitat i dels seus ajuntaments, diputacions o cabildos el {sub_ult[0]?.anio}, per habitant de la comunitat. Les de l'Estat es reparteixen per tot Espanya i no s'inclouen aquí.

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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: BDNS"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'eur_hab_real', title: '€ per habitant', fmt: '0.00'},
        {id: 'eur_hab_autonomico', title: 'De la comunitat', fmt: '0.00'},
        {id: 'eur_hab_local', title: "D'ajuntaments i diputacions", fmt: '0.00'},
        {id: 'concesiones', title: 'Concessions', fmt: '#,##0'}
    ]}
/>

<DataTable data={sub_ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Comunitat" />
    <Column id=eur_hab_real title="€ per habitant" fmt='0.00' />
    <Column id=eur_hab_autonomico title="De la comunitat" fmt='0.00' />
    <Column id=eur_hab_local title="D'entitats locals" fmt='0.00' />
    <Column id=importe_nominal title="Euros" fmt='#,##0' />
    <Column id=concesiones title="Concessions" fmt='#,##0' />
    <Column id=partido title="Govern autonòmic" />
</DataTable>

Les comunitats que no hi apareixen no van concedir ajuts a mitjans privats aquell any o no els van publicar a la Base de Dades Nacional de Subvencions. **El Govern Basc no hi registra els seus ajuts a mitjans**, així que al País Basc només hi consten els de les diputacions forals i els ajuntaments.

### Qui les rep

Les 25 empreses i entitats que més han rebut des del {sub_desde[0]?.desde}, sumant tots els anys en euros d'avui. Els ajuts a persones físiques (periodistes autònoms, per exemple) es compten en els totals però no es mostren pel nom.

<DataTable data={sub_beneficiarios} rows=25 search=true>
    <Column id=rango title="Lloc" fmt='0' />
    <Column id=nombre title="Beneficiari" />
    <Column id=total_eur_real title="Total (euros d'avui)" fmt='#,##0' />
    <Column id=concesiones title="Concessions" fmt='0' />
    <Column id=administraciones title="Concedents" wrap=true />
</DataTable>

## Metodologia i fonts

- **Ràdios i televisions autonòmiques**: [CNMC, Informe Econòmic Sectorial de les Telecomunicacions i l'Audiovisual](https://www.cnmc.es/sectores-que-regulamos/telecomunicaciones/informes-economicos-sectoriales-anuales), subvencions i transferències percebudes per cada ens (ràdio i televisió juntes), 2017-2025; els gràfics per comunitat s'han transcrit a mà i la suma quadra amb el total de la CNMC. Des del 2022 la CNMC només dona euros per habitant: els milions es reconstrueixen amb la població de l'INE. La CNMC no inclou la Comunitat Valenciana: per a À Punt s'utilitzen les aportacions de socis dels comptes de la CVMC al [Compte General de la Generalitat](https://hisenda.gva.es/es/web/intervencion-general/laconselleria-infogeneral-laintervenciongeneral-cuentas) (2017-2023) i l'execució del programa 462D a [dadesobertes.gva.es](https://dadesobertes.gva.es/) (2024-2025). A Castella i Lleó i Múrcia la televisió és una empresa privada amb un contracte programa públic.
- **RTVE**: [comptes anuals de la Corporació RTVE](https://www.rtve.es/rtve/20231016/transparencia-cuentas/943360.shtml), nota de subvencions: compensació per servei públic dels Pressupostos Generals de l'Estat, altres subvencions, taxa de l'espectre i aportacions de les operadores (Llei 8/2009). El 2008-2009 són els comptes del grup, que encara emetia publicitat.
- **Audiències**: quota de pantalla anual de [Barlovento Comunicación](https://barloventocomunicacion.es/) amb dades de Kantar Media (individus de 4 anys o més, amb convidats).
- **Publicitat de l'Estat**: [Comissió de Publicitat i Comunicació Institucional, plans i informes anuals](https://www.lamoncloa.gob.es/serviciosdeprensa/cpci/paginas/planeseinformes.aspx) (Llei 29/2005), cost executat de les campanyes des del 2006, per tipus de mitjà, i des de l'Informe 2025 per grup mediàtic (annex IV de l'informe institucional i annex III del de publicitat comercial). El cost executat inclou producció i avaluació a més de la compra d'espais; el repartiment per grup és només compra de mitjans. Els informes no indiquen si els imports porten IVA (per com estan arrodonits, sembla que sí). El que cobra cada mitjà depèn a més dels descomptes que negocien les agències de mitjans que contracten les campanyes.
- **Publicitat de comunitats i ajuntaments**: dades obertes de la [Generalitat de Catalunya](https://analisi.transparenciacatalunya.cat/Sector-P-blic/Campanyes-i-promoci-institucional-de-la-Generalita/8d5a-6vsk), la [Junta de Castella i Lleó](https://analisis.datosabiertos.jcyl.es/explore/dataset/publicidad-institucional/), el [Govern d'Aragó](https://www.aragon.es/transparencia/gestion-fondos-publicos/campanas-publicidad-institucional), el [Govern de Navarra](https://datosabiertos.navarra.es/dataset/publicidad-institucional), la [Regió de Múrcia](https://transparencia.carm.es/publicidad-institucional), l'[Ajuntament de Madrid](https://datos.madrid.es/dataset/300024-0-publicidad-institucional) i l'[Ajuntament de Barcelona](https://opendata-ajuntament.barcelona.cat/data/ca/dataset/campanyes-publicitat-institucional); informes en PDF de la [Generalitat Valenciana](https://gvaoberta.gva.es/va/publicidad-y-promocion-institucional) (amb el seu sector públic instrumental) i, per al País Basc, el recull de les memòries del Govern Basc de [gobiernovasco.marketing](https://gobiernovasco.marketing/) (Jaime Gómez-Obregón, CC BY 4.0). Els noms dels mitjans s'agrupen per grup de comunicació amb una taula d'equivalències de SpainFacts.
- **Empreses públiques**: capítol de campanyes comercials dels informes anuals de la Comissió de Publicitat i Comunicació Institucional (per entitat, 2015-2025); [plans de mitjans i comptes anuals de Canal de Isabel II](https://www.canaldeisabelsegunda.es/en/informacion-economica) (plans per campanya i mitjà des del 2019; el compte 627, publicitat, propaganda i relacions públiques, només com a referència); [plans de mitjans de la Comunitat de Madrid](https://www.comunidad.madrid/transparencia/gastos-publicidad-y-comunicacion-institucional) (2020-2025, el que es preveu per campanya i mitjà, sense IVA); [portal de transparència de TMB](https://transparencia.tmb.cat/); i les empreses que apareixen a les dades de la seva comunitat o ajuntament. Des del 2024 la xifra de Renfe només inclou les campanyes de Renfe Operadora, no les comercials de Renfe Viajeros.
- **Contractes amb mitjans**: [Plataforma de Contractació del Sector Públic](https://www.hacienda.gob.es/es-ES/GobiernoAbierto/Datos%20Abiertos/Paginas/licitaciones_plataforma_contratacion.aspx) (licitacions dels perfils allotjats, plataformes autonòmiques agregades i contractes menors), des del 2018, i [registre d'òrgans de contractació](https://contrataciondelsectorpublico.gob.es/datosabiertos/OrganosContratacion.xlsx) per saber quina administració contracta. Només compten els adjudicataris d'un padró de NIF d'empreses de mitjans revisat a mà (editores de premsa, ràdios, televisions privades, digitals i agències de notícies; sense agències de publicitat, productores tècniques ni editorials de llibres). El tipus de contracte es dedueix del text de l'objecte. Es descarten imports absurds (acords marc amb l'import total).
- **Subvencions**: [Base de Dades Nacional de Subvencions](https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones) (IGAE). S'utilitza una llista revisada a mà de convocatòries d'ajuts a mitjans privats (criteri al repositori de SpainFacts); import concedit, no pagat, per any de concessió. S'exclouen els mitjans públics, les associacions de la premsa i les beques.
- **Euros constants** amb l'IPC de l'INE i **població** del padró; partit de cada Govern segons la taula de presidents de SpainFacts.
