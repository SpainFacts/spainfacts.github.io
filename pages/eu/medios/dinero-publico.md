---
title: Diru publikoa komunikabideetan
description: "Zenbat diru publiko jasotzen duten Espainiako komunikabideek: RTVEri eta telebista autonomikoei egindako ekarpena, Estatuaren erakunde- eta merkataritza-publizitatea komunikazio-taldeka eta komunikabide pribatuentzako diru-laguntzak, biztanleko eta inflazioa kenduta, erkidegoka eta alderdika."
i18n_origen: 99497b7340e4
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
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
       '/eu' || c.ruta AS ruta
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
       CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (osatu gabea)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo,
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
       CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (osatu gabea)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo
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
       max('/eu' || c.ruta) AS ruta
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
# <span aria-hidden="true">📰</span> Diru publikoa komunikabideetan

Espainiako administrazioek hiru bidetatik finantzatzen dituzte komunikabideak: irrati-telebista publikoak ordaintzen dituzte (RTVE eta erakunde autonomikoak), publizitatea erosten dute komunikabideetan (baita beren enpresa publikoen bidez ere) eta zuzeneko diru-laguntzak ematen dizkiete argitaletxeei. Zifra guztiak **biztanleko eta inflazioa kenduta** ematen dira, {urteko(tv_espana_ult[0]?.anio_base)} euroetan. Komunikabide jakin batek jaso duena ikusteko, erabili [«Nork zer jasotzen duen» bilatzailea](/eu/medios/buscador).

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if tv_espana_ult.length && pub_age_ult.length && sub_ult.length}
    <KpiCard
        title="Irrati-telebista publikoak"
        value={tv_espana_ult[0].total_eur_hab_real}
        formattedValue={formatNumber(tv_espana_ult[0].total_eur_hab_real, 1) + ' €'}
        unit="biztanleko"
        period={`${tv_espana_ult[0].anio} · ${formatCompact(tv_espana_ult[0].total_meur_nominal * 1e6, 2)} € RTVEren eta autonomikoen artean`}
        source="CNMC, RTVE eta Generalitat Valenciana"
        direction="positive-down"
        sparklineData={tv_espana.filter(d => d.total_eur_hab_real !== null).map(d => ({...d, y: d.total_eur_hab_real}))}
    />
    <KpiCard
        title="Estatuaren erakunde-publizitatea"
        value={pub_age_ult[0].institucional_eur_hab_real}
        formattedValue={formatNumber(pub_age_ult[0].institucional_eur_hab_real, 2) + ' €'}
        unit="biztanleko"
        period={`${pub_age_ult[0].anio} · ${formatCompact(pub_age_ult[0].institucional_eur_nominal, 2)} € ministerioen kanpainetan`}
        source="Erakunde Publizitatearen Batzordea"
        direction="positive-down"
        sparklineData={pub_age.map(d => ({...d, y: d.institucional_eur_hab_real}))}
    />
    <KpiCard
        title="Estatuko enpresen publizitatea"
        value={pub_age_ult[0].comercial_eur_hab_real}
        formattedValue={formatNumber(pub_age_ult[0].comercial_eur_hab_real, 2) + ' €'}
        unit="biztanleko"
        period={`${pub_age_ult[0].anio} · ${formatCompact(pub_age_ult[0].comercial_eur_nominal, 2)} € (Loterías, AENA, Correos, Renfe...)`}
        source="Erakunde Publizitatearen Batzordea"
        direction="positive-down"
        sparklineData={pub_age.map(d => ({...d, y: d.comercial_eur_hab_real}))}
    />
    <KpiCard
        title="Diru-laguntzak komunikabide pribatuei"
        value={sub_ult[0].eur_hab_real}
        formattedValue={formatNumber(sub_ult[0].eur_hab_real, 2) + ' €'}
        unit="biztanleko"
        period={`${sub_ult[0].anio} · ${formatCompact(sub_ult[0].eur_nominal, 2)} € ${formatNumber(sub_ult[0].concesiones, 0)} emakidatan`}
        source="Diru-laguntzen Datu-base Nazionala"
        direction="positive-down"
        sparklineData={sub_espana.filter(d => !d.parcial).map(d => ({...d, y: d.eur_hab_real}))}
    />
    {/if}
</div>

## Irrati-telebista publikoak

Estatuak RTVEri ordaintzen diona eta erkidegoek beren irrati eta telebista erakundeei ordaintzen dietena: zerbitzu publikoagatiko konpentsazioa, diru-laguntzak, programa-kontratuak eta kapital-ekarpenak. {urtean(tv_espana_ult[0]?.anio)}, {formatNumber(tv_espana_ult[0]?.rtve_eur_hab_real, 1)} € izan ziren biztanleko RTVErentzat eta {formatNumber(tv_espana_ult[0]?.autonomicas_eur_hab_real, 1)} € erakunde autonomikoentzat (Espainiako biztanleria osoaren gainean kalkulatua, telebista propiorik ez duten erkidegoetakoa barne).

<LineChart
    data={tv_series}
    x=anio
    y=eur_hab
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="€ biztanleko ({urteko(tv_espana_ult[0]?.anio_base)} euroak)"
    seriesColors={{'RTVE': '#2563eb', 'Radios y televisiones autonómicas': '#f59e0b'}}
    title="Diru publikoa irrati-telebista publikoentzat, € biztanleko inflazioa kenduta"
/>

RTVErenak, 2010etik —publizitatea emititzeari utzi zionetik—, telekomunikazio- eta telebista-operadoreek ordaintzen duten tasa eta espektro erradioelektrikoaren erabileragatikoa hartzen ditu barne. Aparteko ordainketak dituzten urteak (2021eko kapital-diru-laguntza RTVE Playrentzat, 2024ko 100 milioi gehigarriak) gailur gisa ikusten dira.

### Erkidegoka

Erakunde autonomiko bakoitzari egindako ekarpen publikoa {urtean(tv_ccaa[0]?.anio)}, erkidegoko biztanleko. {formatNumber(tv_extremos[0]?.mas_eur, 1)} €-tik ({tv_extremos[0]?.mas}) {formatNumber(tv_extremos[0]?.menos_eur, 1)} €-ra ({tv_extremos[0]?.menos}) bitartekoa da. Nafarroak, Kantabriak, Errioxak, Ceutak eta Melillak ez dute erakunde propiorik.

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
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: CNMC, Generalitat Valenciana"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'ente', showColumnName: false},
        {id: 'eur_hab_real', title: '€ biztanleko', fmt: '0.0'},
        {id: 'meur_nominal', title: 'Milioi euro', fmt: '#,##0.0'},
        {id: 'cuota_audiencia', title: 'Pantaila-kuota (%)', fmt: '0.0'}
    ]}
/>

Telebista bakoitzak zenbat kostatzen duen eta zenbat ikusten den alderatzeko, taulak biztanleko euroak zatitzen ditu haren kateek erkidegoan duten pantaila-kuotaz (haren telebista-kanal guztien batura). Hurbilketa bat da: diruak irratia, webgunea eta ekoizpen propioa ere ordaintzen ditu. Audientzia-puntuko gutxien kostatzen dena {tv_extremos[0]?.barata} da, eta gehien kostatzen dena, {tv_extremos[0]?.cara}.

<DataTable data={tv_ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=ente title="Erakundea" />
    <Column id=eur_hab_real title="€ biztanleko" fmt='0.0' />
    <Column id=meur_nominal title="Milioi euro" fmt='#,##0.0' />
    <Column id=cuota_audiencia title="Pantaila-kuota %" fmt='0.0' />
    <Column id=eur_hab_real_por_punto_cuota title="€/biz. kuota-puntuko" fmt='0.0' />
    <Column id=familia title="Gobernua" />
</DataTable>

<LineChart
    data={tv_ccaa_serie}
    x=anio
    y=eur_hab_real
    series=comunidad
    xFmt='0'
    yFmt='0'
    yAxisTitle="€ biztanleko"
    title="Erakunde autonomiko bakoitzari egindako ekarpen publikoa, € biztanleko inflazioa kenduta"
/>

### Alderdika

{urtetik(tv_gobiernos[0]?.anio_desde)} {urtera(tv_gobiernos[0]?.anio_hasta)} bitarteko erkidegoak eta urteak batuta, eta urte bakoitza uztailaren 1ean erkidegoa gobernatzen zuen alderdiari egotzita, taulak alderdi bakoitzarekin emandako diruaren zatia gobernatu zuen biztanleriaren zatiarekin alderatzen du (denek biztanleko gauza bera gastatuko balute, arrazoia 1 izango litzateke). Erakunde propioa duten erkidegoak bakarrik zenbatzen dira. PPrekin, erkidegoek batez beste {formatNumber(tv_pp_psoe[0]?.pp, 1)} € eman zituzten biztanleko eta urteko; PSOErekin, {formatNumber(tv_pp_psoe[0]?.psoe, 1)} €.

<DataTable data={tv_gobiernos} rows=12>
    <Column id=partido title="Gobernatzen zuen alderdia" />
    <Column id=anios_comunidad title="Gobernu-urteak (erkidegoa x urtea)" fmt='0' />
    <Column id=comunidades title="Erkidegoak" fmt='0' />
    <Column id=eur_hab_real_anio title="€ biztanleko eta urteko" fmt='0.0' />
    <Column id=cuota_dinero title="Diruaren %" fmt='0.0' />
    <Column id=cuota_poblacion title="Gobernatutako biztanleriaren %" fmt='0.0' />
    <Column id=ratio_observado_esperado title="Behatua / espero zena" fmt='0.00' />
</DataTable>

Kontuz irakurri behar da: alderdi nazionalistek erkidego bakarra gobernatzen dute bakoitzak, eta biztanleko gehien ematen duten erkidegoetako hiruk (Euskadi, Katalunia eta Galizia) hizkuntza koofiziala dute, eta haien legeek hizkuntza hori sustatzeko eginkizuna ematen diote erakunde publikoari. Gainera, erakundeak duela hamarkada batzuk sortu ziren; beraz, gobernu bakoitzaren gastuaren zati handi bat oinordetzan jasoa da.

## Estatuaren publizitatea

Estatuko Administrazio Orokorrak urtero ematen du bere publizitate-kanpainen kostuaren berri: ministerio eta erakundeen **erakunde-kanpainak** (29/2005 Legea) eta haren enpresa eta erakunde publikoen **merkataritza-kanpainak** (Loterías y Apuestas del Estado, AENA, Correos, Renfe, Paradores...). {urtean(pub_age_ult[0]?.anio)}, {formatNumber(pub_age_ult[0]?.institucional_eur_hab_real, 2)} € gastatu zituen biztanleko erakunde-kanpainetan eta {formatNumber(pub_age_ult[0]?.comercial_eur_hab_real, 2)} € merkataritza-kanpainetan. Erakunde-kanpainen gehienekoa {urteko(pub_age_max[0]?.anio)}a izan zen, {formatNumber(pub_age_max[0]?.institucional_eur_hab_real, 2)} €-rekin.

<BarChart
    data={pub_age_series}
    x=anio
    y=eur_hab
    series=tipo
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="€ biztanleko"
    seriesColors={{'Campañas institucionales': '#2563eb', 'Campañas comerciales (empresas y entidades públicas)': '#93c5fd'}}
    title="Estatuko Administrazio Orokorraren publizitatea, € biztanleko inflazioa kenduta"
/>

Gobernu bakoitzaren urteko batez bestekoa (urte bakoitza uztailaren 1ean presidente zenari dagokio). Gauzatutako gastua beti geratzen da planifikatutakoaren azpitik: azken zutabea urteko planetik gastatzera iritsi zen zatia da.

<DataTable data={pub_gobiernos} rows=10>
    <Column id=presidente title="Presidentea" />
    <Column id=partido title="Alderdia" />
    <Column id=anio_desde title="Noiztik" fmt='0' />
    <Column id=anio_hasta title="Noiz arte" fmt='0' />
    <Column id=institucional_eur_hab_real_media title="Erakundekoa, €/biz. eta urteko" fmt='0.00' />
    <Column id=comercial_eur_hab_real_media title="Merkataritzakoa, €/biz. eta urteko" fmt='0.00' />
    <Column id=ejecucion_pct_media title="Gauzatutako planaren %" fmt='0' />
</DataTable>

Urte batzuek aparteko kanpainak dituzte, hala nola 2020-2022ko pandemiakoak.

### Zein komunikabidetan

Erakunde-kanpainetako espazio-erosketaren banaketa komunikabide motaren arabera. Digitala {urteko(pub_medios_extremos[0]?.anio_ini)} {formatNumber(pub_medios_extremos[0]?.digital_ini, 1)} %-tik {urteko(pub_medios_extremos[0]?.anio_fin)} {formatNumber(pub_medios_extremos[0]?.digital_fin, 1)} %-ra igaro da, eta prentsa idatzia {formatNumber(pub_medios_extremos[0]?.prensa_ini, 1)} %-tik {formatNumber(pub_medios_extremos[0]?.prensa_fin, 1)} %-ra.

<AreaChart
    data={pub_medios}
    x=anio
    y=pct
    series=medio
    xFmt='0'
    yFmt='0"%"'
    type=stacked100
    title="Estatuaren erakunde-publizitatea komunikabide motaren arabera, espazio-erosketaren %"
/>

### Zein taldek jasotzen duten

{urteko(pub_grupos_resumen[0]?.anio)} Txostenetik —komunikabideen askatasunari buruzko Europako Erregelamenduaren pean egindako lehena—, Gobernuak argitaratzen du zenbat ordaindu zion komunikazio-talde edo plataforma bakoitzari. Lehen hiru taldeek erakunde-komunikabideen erosketaren {formatNumber(pub_grupos_resumen[0]?.pct_top3, 0)} % eraman zuten, eta plataforma digitalek (Google, Meta, TikTok...), {formatNumber(pub_grupos_resumen[0]?.pct_plataformas, 0)} %.

<BarChart
    data={pub_grupos_inst}
    x=grupo
    y=eur_hab_real
    series=clase
    swapXY=true
    sort=false
    yFmt='0.00'
    yAxisTitle="€ biztanleko"
    seriesColors={{'Grupo de medios': '#2563eb', 'Plataforma digital': '#a855f7', 'Medio público': '#f59e0b'}}
    title="Estatuaren erakunde-publizitatea taldeka, {pub_grupos_resumen[0]?.anio} (€ biztanleko)"
/>

<BarChart
    data={pub_grupos_com}
    x=grupo
    y=eur_hab_real
    series=clase
    swapXY=true
    sort=false
    yFmt='0.00'
    yAxisTitle="€ biztanleko"
    seriesColors={{'Grupo de medios': '#2563eb', 'Plataforma digital': '#a855f7', 'Medio público': '#f59e0b'}}
    title="Estatuko enpresen merkataritza-publizitatea taldeka, {pub_grupos_resumen[0]?.anio} (€ biztanleko)"
/>

<DataTable data={pub_grupos} rows=15 search=true>
    <Column id=tipo title="Kanpainak" />
    <Column id=puesto title="Postua" fmt='0' />
    <Column id=grupo title="Taldea edo enpresa" />
    <Column id=clase title="Mota" />
    <Column id=importe_eur_nominal title="Euroak" fmt='#,##0' />
    <Column id=pct title="Guztizkoaren %" fmt='0.0' />
</DataTable>

## Erkidegoen, udalen eta enpresa publikoen publizitatea

Erkidegoek eta udalek ere publizitatea erosten dute, eta horietako batzuek bakarrik argitaratzen dute zenbat eta zein komunikabidetan. Hauek dira datu irekietan edo atera daitezkeen txostenetan egiten dutenak. Ez dute denek gauza bera neurtzen: batzuek gastatutakoa ematen dute eta beste batzuek kontratatutakoa, batzuek BEZarekin eta beste batzuek gabe («Alderagarria» zutabeak gainerakoekin zuzenean alderatu ezin direnak markatzen ditu). Kataluniak, gainera, zenbateko garbia ematen du, komunikabide-agentziaren komisiorik gabe.

<DataTable data={terr_ult} rows=15>
    <Column id=territorio title="Administrazioa" />
    <Column id=administracion title="Mota" />
    <Column id=anio title="Urtea" fmt='0' />
    <Column id=total_eur_hab_real title="€ biztanleko" fmt='0.00' />
    <Column id=administracion_eur_hab_real title="Administrazioarena" fmt='0.00' />
    <Column id=empresas_publicas_eur_hab_real title="Haren enpresa publikoena" fmt='0.00' />
    <Column id=total_eur_nominal title="Euroak" fmt='#,##0' />
    <Column id=iva title="BEZ" />
    <Column id=base title="Zifra" />
    <Column id=comparable title="Alderagarria" />
    <Column id=partido title="Gobernua" />
</DataTable>

<LineChart
    data={terr_serie}
    x=anio
    y=total_eur_hab_real
    series=territorio
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="€ biztanleko"
    title="Erkidegoen eta udalen erakunde-publizitatea, € biztanleko inflazioa kenduta"
/>

Galiziak, Kanariek, Balearrek, Asturiasek, Kantabriak, Gaztela-Mantxak eta Andaluziak ez dute argitaratzen komunikabide bakoitzeko gastua; Madrilgo Erkidegoak bere komunikabide-planak argitaratzen ditu (2020tik, kanpainaka eta komunikabideka aurreikusitakoa, BEZik gabe), baina ez gauzatutakoa. Euskadiko datuak Eusko Jaurlaritzak Legebiltzarrari aurkezten dizkion memorietatik datoz, [gobiernovasco.marketing](https://gobiernovasco.marketing/) webguneak bilduak.

Administrazio bakoitzetik gehien jasotzen duten bost taldeak, datua duen azken urtean:

<DataTable data={terr_grupos} rows=10 search=true>
    <Column id=territorio title="Administrazioa" />
    <Column id=anio title="Urtea" fmt='0' />
    <Column id=rango title="Postua" fmt='0' />
    <Column id=grupo title="Taldea edo komunikabidea" />
    <Column id=titularidad title="Titulartasuna" />
    <Column id=pct_medios title="Komunikabideetako publizitatearen %" fmt='0.0' />
    <Column id=importe_eur_nominal title="Euroak" fmt='#,##0' />
</DataTable>

### Enpresa publikoak

Enpresa publikoek beren kanpainak egiten dituzte, eta ez dira beti agertzen erakunde-publizitateari buruzko txostenetan. Estatukoak merkataritza-publizitateari buruzko urteko txostenean jasotzen dira; Loterías y Apuestas del Estado da, alde handiz, gehien gastatzen duena.

<BarChart
    data={loterias}
    x=anio
    y=eur_hab_real
    series=entidad
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="€ biztanleko"
    seriesColors={{'Loterías y Apuestas del Estado': '#16a34a', 'Resto de empresas y entidades del Estado': '#86efac'}}
    title="Estatuko enpresen merkataritza-publizitatea, € biztanleko inflazioa kenduta"
/>

Autonomia eta udal mailakoetatik, argitaratzen dituztenen datuak baino ez daude: Canal de Isabel II (bere komunikabide-planak kanpainaka eta komunikabideka 2019tik; urteko kontuak, harreman publikoak eta babesletzak ere biltzen dituztenak, erreferentzia gisa baino ez), FGC, Loteries de Catalunya, EMT eta Madrid Destino, besteak beste. Metro de Madridek ez du uzten bere datuak deskargatzen.

<DataTable data={empresas} rows=15 search=true>
    <Column id=entidad title="Enpresa edo erakundea" />
    <Column id=ambito title="Norena" />
    <Column id=territorio title="Lurraldea" />
    <Column id=anio title="Urtea" fmt='0' />
    <Column id=importe_eur_nominal title="Euroak" fmt='#,##0' />
    <Column id=eur_hab_real title="€ lurraldeko biztanleko" fmt='0.00' />
    <Column id=que_mide title="Zer neurtzen duen" wrap=true />
</DataTable>

## Komunikabide-enpresekin egindako kontratuak

Publizitate-kanpainez gain, administrazioek zuzenean kontratatzen dute komunikabideekin: txertaketak eta iragarkiak, komunikabideek berek antolatutako foro, jardunaldi, gala eta sarien babesletzak, gehigarri bereziak, aldizkariak eta albiste-agentzietarako harpidetzak. Ia beti kontratu txikiak dira, mila euro gutxi batzuetakoak, eta ez dira agertzen erakunde-publizitateari buruzko txostenetan. Sektore Publikoko Kontratazio Plataforman komunikabide pribatuetako 800 enpresa inguruko zerrenda berrikusi bati esleitutako kontratuak bilatuta, {urtean(con_ult[0]?.anio)} gutxienez {formatCompact(con_ult[0]?.eur_real, 2)} € izan ziren ({formatNumber(con_ult[0]?.eur_hab_real, 2)} € biztanleko), {formatNumber(con_ult[0]?.contratos, 0)} kontratutan, eta horien {formatNumber(con_ult[0]?.pct_menores, 0)} % kontratu txikiak.

<BarChart
    data={con_anual}
    x=periodo
    sort=false
    y=meur_real
    series=contratante
    yFmt='0.0'
    yAxisTitle="Milioi euro (inflazioa kenduta)"
    seriesColors={{'Estado': '#2563eb', 'Comunidades autónomas': '#10b981', 'Ayuntamientos, diputaciones y cabildos': '#a3e635', 'Empresas y entes públicos': '#f59e0b', 'Otros': '#94a3b8'}}
    title="Komunikabide pribatuetako enpresei esleitutako kontratuak, milioi euro inflazioa kenduta (dokumentatutako gutxienekoa)"
/>

**Gutxieneko bat** da: Plataformak ez ditu jasotzen plataforma propioa duten erkidegoen kontratu txikiak (Katalunia, Euskadi, Andaluzia, Madrilgo Erkidegoa, Galizia, Nafarroa eta Errioxa), ezta han argitaratzen ez dituzten udal handi batzuenak ere, eta komunikabide-agentzien bidez erositako publizitatea agentziaren izenean agertzen da. Horregatik ez dira erkidegoak elkarren artean alderatzen. Zenbatekoak esleitutakoak dira, BEZik gabe, ez ordaindutakoak. Seriea 2019an hasten da, urtero erakunde gehiagok argitaratzen dutelako.

<BarChart
    data={con_categorias}
    x=categoria
    y=meur_real
    swapXY=true
    sort=false
    yFmt='0'
    yAxisTitle="Milioi euro, 2019-{con_ult[0]?.anio}"
    title="Zertan gastatzen den: komunikabideekin egindako kontratuak motaren arabera, 2019-{con_ult[0]?.anio} (gaurko milioi euro)"
/>

<DataTable data={con_grupos} rows=15>
    <Column id=grupo title="Taldea" />
    <Column id=meur_real title="Gaurko milioi euro (2019tik)" fmt='0.0' />
    <Column id=contratos title="Kontratuak" fmt='#,##0' />
</DataTable>

Biztanleko komunikabideekin gehien kontratatzen duten 100.000 biztanletik gorako hiriak (2022-2025eko batez bestekoa, Plataforman argitaratutakoa bakarrik):

<DataTable data={con_municipios} rows=10 search=true>
    <Column id=municipio title="Udalerria" />
    <Column id=partido title="Alkatetza (2025)" />
    <Column id=eur_hab_real title="€ biztanleko eta urteko" fmt='0.00' />
    <Column id=eur_real title="Guztira 2022-2025 (gaurko euroak)" fmt='#,##0' />
    <Column id=contratos title="Kontratuak" fmt='#,##0' />
</DataTable>

Komunikabide pribatuekin egindako babesletza eta ekitaldietako kontratu handienak:

<DataTable data={con_ejemplos} rows=10 search=true link=url>
    <Column id=anio title="Urtea" fmt='0' />
    <Column id=objeto title="Kontratuaren xedea" wrap=true />
    <Column id=organo title="Kontratazio-organoa" wrap=true />
    <Column id=adjudicatario title="Esleipenduna" />
    <Column id=importe_eur_nominal title="Euroak BEZik gabe" fmt='#,##0' />
</DataTable>

## Diru-laguntzak komunikabide pribatuei

Prentsa, irrati, telebista eta komunikabide digital pribatuetako enpresa, kooperatiba eta elkarte argitaratzaileentzako zuzeneko laguntzak: egiturazko laguntzak, hizkuntza koofizialak erabiltzeko, digitalizaziorako eta adimen artifizialerako edo proiektu zehatzetarako. Ez ditu barne hartzen komunikabide publikoak (goian zenbatuak) ezta kazetarientzako edo unibertsitateentzako laguntzak ere.

<BarChart
    data={sub_anual}
    x=periodo
    sort=false
    y=meur_real
    series=concedente
    yFmt='0.0'
    yAxisTitle="Milioi euro (inflazioa kenduta)"
    seriesColors={{'Estado': '#2563eb', 'Comunidades autónomas': '#10b981', 'Ayuntamientos, diputaciones y cabildos': '#a3e635'}}
    title="Komunikabide pribatuei emandako diru-laguntzak, milioi euro inflazioa kenduta"
/>

Diru-laguntzen Datu-base Nazionalak azken lau urteetako emakidak baino ez ditu kontsultatzen uzten; horregatik hasten da seriea {urtean(sub_desde[0]?.desde)}. SpainFactsek kopia propio bat gordetzen du, joan diren urteak ez galtzeko. Aurtengo urtea «osatu gabea» gisa markatuta agertzen da.

### Erkidegoka

Erkidegoaren eta haren udal, foru-aldundi edo kabildoen diru-laguntzak {urtean(sub_ult[0]?.anio)}, erkidegoko biztanleko. Estatukoak Espainia osoan banatzen dira, eta ez daude hemen sartuta.

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
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: BDNS"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'eur_hab_real', title: '€ biztanleko', fmt: '0.00'},
        {id: 'eur_hab_autonomico', title: 'Erkidegoarenak', fmt: '0.00'},
        {id: 'eur_hab_local', title: 'Udalenak eta aldundienak', fmt: '0.00'},
        {id: 'concesiones', title: 'Emakidak', fmt: '#,##0'}
    ]}
/>

<DataTable data={sub_ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=eur_hab_real title="€ biztanleko" fmt='0.00' />
    <Column id=eur_hab_autonomico title="Erkidegoarenak" fmt='0.00' />
    <Column id=eur_hab_local title="Toki-erakundeenak" fmt='0.00' />
    <Column id=importe_nominal title="Euroak" fmt='#,##0' />
    <Column id=concesiones title="Emakidak" fmt='#,##0' />
    <Column id=partido title="Autonomia-gobernua" />
</DataTable>

Agertzen ez diren erkidegoek ez zieten laguntzarik eman komunikabide pribatuei urte hartan, edo ez zituzten Diru-laguntzen Datu-base Nazionalean argitaratu. **Eusko Jaurlaritzak ez ditu han erregistratzen komunikabideentzako bere laguntzak**; beraz, Euskadin foru-aldundienak eta udalenak baino ez daude jasota.

### Nork jasotzen dituen

{urtetik(sub_desde[0]?.desde)} gehien jaso duten 25 enpresa eta erakundeak, urte guztiak gaurko euroetan batuta. Pertsona fisikoentzako laguntzak (kazetari autonomoentzat, adibidez) guztizkoetan zenbatzen dira, baina ez dira izenez erakusten.

<DataTable data={sub_beneficiarios} rows=25 search=true>
    <Column id=rango title="Postua" fmt='0' />
    <Column id=nombre title="Onuraduna" />
    <Column id=total_eur_real title="Guztira (gaurko euroak)" fmt='#,##0' />
    <Column id=concesiones title="Emakidak" fmt='0' />
    <Column id=administraciones title="Emaileak" wrap=true />
</DataTable>

## Metodologia eta iturriak

- **Irrati-telebista autonomikoak**: [CNMC, Telekomunikazioen eta Ikus-entzunezkoen Sektoreko Txosten Ekonomikoa](https://www.cnmc.es/sectores-que-regulamos/telecomunicaciones/informes-economicos-sectoriales-anuales), erakunde bakoitzak jasotako diru-laguntzak eta transferentziak (irratia eta telebista batera), 2017-2025; erkidegoko grafikoak eskuz transkribatu dira, eta batura CNMCren guztizkoarekin bat dator. 2022tik, CNMCk biztanleko euroak baino ez ditu ematen: milioiak INEren biztanleriarekin berreraikitzen dira. CNMCk ez du Valentziako Erkidegoa barne hartzen: À Punterako, CVMCren kontuetako bazkideen ekarpenak erabiltzen dira, [Generalitateko Kontu Orokorrean](https://hisenda.gva.es/es/web/intervencion-general/laconselleria-infogeneral-laintervenciongeneral-cuentas) (2017-2023), eta 462D programaren gauzatzea [dadesobertes.gva.es](https://dadesobertes.gva.es/) webgunean (2024-2025). Gaztela eta Leonen eta Murtzian, telebista enpresa pribatu bat da, programa-kontratu publiko batekin.
- **RTVE**: [RTVE Korporazioaren urteko kontuak](https://www.rtve.es/rtve/20231016/transparencia-cuentas/943360.shtml), diru-laguntzen oharra: Estatuko Aurrekontu Orokorretako zerbitzu publikoagatiko konpentsazioa, beste diru-laguntza batzuk, espektroaren tasa eta operadoreen ekarpenak (8/2009 Legea). 2008-2009an taldearen kontuak dira, oraindik publizitatea emititzen baitzuen.
- **Audientziak**: [Barlovento Comunicación](https://barloventocomunicacion.es/) enpresaren urteko pantaila-kuota, Kantar Mediaren datuekin (4 urteko edo gehiagoko pertsonak, gonbidatuak barne).
- **Estatuaren publizitatea**: [Erakunde Publizitate eta Komunikaziorako Batzordea, urteko planak eta txostenak](https://www.lamoncloa.gob.es/serviciosdeprensa/cpci/paginas/planeseinformes.aspx) (29/2005 Legea), kanpainen kostu gauzatua 2006tik, komunikabide motaren arabera, eta 2025eko Txostenetik komunikazio-taldeka (erakunde-txostenaren IV. eranskina eta merkataritza-publizitatearenaren III. eranskina). Kostu gauzatuak ekoizpena eta ebaluazioa ere hartzen ditu barne, espazio-erosketaz gain; taldekako banaketa komunikabideen erosketa baino ez da. Txostenek ez dute adierazten zenbatekoek BEZa duten ala ez (biribiltzeko moduagatik, badirudi baietz). Komunikabide bakoitzak kobratzen duena, gainera, kanpainak kontratatzen dituzten komunikabide-agentziek negoziatzen dituzten deskontuen araberakoa da.
- **Erkidegoen eta udalen publizitatea**: datu irekiak: [Generalitat de Catalunya](https://analisi.transparenciacatalunya.cat/Sector-P-blic/Campanyes-i-promoci-institucional-de-la-Generalita/8d5a-6vsk), [Gaztela eta Leongo Junta](https://analisis.datosabiertos.jcyl.es/explore/dataset/publicidad-institucional/), [Aragoiko Gobernua](https://www.aragon.es/transparencia/gestion-fondos-publicos/campanas-publicidad-institucional), [Nafarroako Gobernua](https://datosabiertos.navarra.es/dataset/publicidad-institucional), [Murtziako Eskualdea](https://transparencia.carm.es/publicidad-institucional), [Madrilgo Udala](https://datos.madrid.es/dataset/300024-0-publicidad-institucional) eta [Bartzelonako Udala](https://opendata-ajuntament.barcelona.cat/data/ca/dataset/campanyes-publicitat-institucional); [Generalitat Valencianaren](https://gvaoberta.gva.es/va/publicidad-y-promocion-institucional) PDF txostenak (haren sektore publiko instrumentalarekin) eta, Euskadirako, [gobiernovasco.marketing](https://gobiernovasco.marketing/) webguneak bildutako Eusko Jaurlaritzaren memoriak (Jaime Gómez-Obregón, CC BY 4.0). Komunikabideen izenak komunikazio-taldeka biltzen dira, SpainFactsen baliokidetasun-taula batekin.
- **Enpresa publikoak**: Erakunde Publizitate eta Komunikaziorako Batzordearen urteko txostenetako merkataritza-kanpainen kapitulua (erakundeka, 2015-2025); [Canal de Isabel IIren komunikabide-planak eta urteko kontuak](https://www.canaldeisabelsegunda.es/en/informacion-economica) (planak kanpainaka eta komunikabideka 2019tik; 627 kontua, publizitatea, propaganda eta harreman publikoak, erreferentzia gisa baino ez); [Madrilgo Erkidegoaren komunikabide-planak](https://www.comunidad.madrid/transparencia/gastos-publicidad-y-comunicacion-institucional) (2020-2025, kanpainaka eta komunikabideka aurreikusitakoa, BEZik gabe); [TMBren gardentasun-ataria](https://transparencia.tmb.cat/); eta beren erkidegoko edo udaleko datuetan agertzen diren enpresak. 2024tik, Renferen zifrak Renfe Operadoraren kanpainak baino ez ditu barne hartzen, ez Renfe Viajerosen merkataritza-kanpainak.
- **Komunikabideekin egindako kontratuak**: [Sektore Publikoko Kontratazio Plataforma](https://www.hacienda.gob.es/es-ES/GobiernoAbierto/Datos%20Abiertos/Paginas/licitaciones_plataforma_contratacion.aspx) (ostatatutako profilen lizitazioak, plataforma autonomiko agregatuak eta kontratu txikiak), 2018tik, eta [kontratazio-organoen erregistroa](https://contrataciondelsectorpublico.gob.es/datosabiertos/OrganosContratacion.xlsx), zein administraziok kontratatzen duen jakiteko. Eskuz berrikusitako komunikabide-enpresen IFZ zerrenda bateko esleipendunak baino ez dira zenbatzen (prentsa-argitaletxeak, irratiak, telebista pribatuak, digitalak eta albiste-agentziak; publizitate-agentziarik, ekoiztetxe teknikorik eta liburu-argitaletxerik gabe). Kontratu mota xedearen testutik ondorioztatzen da. Zentzugabeko zenbatekoak baztertzen dira (zenbateko osoa duten esparru-akordioak).
- **Diru-laguntzak**: [Diru-laguntzen Datu-base Nazionala](https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones) (IGAE). Komunikabide pribatuentzako laguntza-deialdien eskuz berrikusitako zerrenda bat erabiltzen da (irizpidea SpainFactsen biltegian); emandako zenbatekoa, ez ordaindutakoa, emakida-urtearen arabera. Komunikabide publikoak, prentsa-elkarteak eta bekak baztertzen dira.
- **Euro konstanteak** INEren KPIarekin eta **biztanleria** erroldatik; Gobernu bakoitzaren alderdia SpainFactsen presidenteen taularen arabera.
