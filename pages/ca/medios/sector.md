---
title: El negoci dels mitjans
description: "Quant es llegeixen, es veuen i s'escolten els mitjans a Espanya, de què viuen (la inversió publicitària per suport) i quanta gent hi treballa, per habitant i descomptada la inflació, en comparació amb la UE i amb els diners públics que reben."
i18n_origen: 5178b34ed295
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql papel
SELECT CAST(anio AS INTEGER) AS anio, penetracion_pct, personas_miles, por_1000_hab
FROM mother.medios_sector_audiencia
WHERE medio = 'diarios_papel'
ORDER BY anio
```

```sql papel_resumen
SELECT
    (SELECT CAST(anio AS INTEGER) FROM ${papel} ORDER BY anio DESC LIMIT 1) AS anio,
    (SELECT por_1000_hab FROM ${papel} ORDER BY anio DESC LIMIT 1) AS por_1000,
    (SELECT personas_miles FROM ${papel} ORDER BY anio DESC LIMIT 1) AS miles,
    (SELECT penetracion_pct FROM ${papel} ORDER BY anio DESC LIMIT 1) AS pct,
    (SELECT CAST(anio AS INTEGER) FROM ${papel} WHERE por_1000_hab IS NOT NULL ORDER BY por_1000_hab DESC LIMIT 1) AS anio_max,
    (SELECT por_1000_hab FROM ${papel} WHERE por_1000_hab IS NOT NULL ORDER BY por_1000_hab DESC LIMIT 1) AS por_1000_max,
    (SELECT penetracion_pct FROM ${papel} ORDER BY penetracion_pct DESC LIMIT 1) AS pct_max,
    (SELECT CAST(anio AS INTEGER) FROM ${papel} ORDER BY penetracion_pct DESC LIMIT 1) AS anio_pct_max
```

```sql audiencia
SELECT CAST(anio AS INTEGER) AS anio, medio_nombre AS medio, penetracion_pct
FROM mother.medios_sector_audiencia
WHERE medio IN ('diarios_papel', 'diarios_internet', 'revistas_papel', 'radio', 'television')
  AND anio >= 2000
ORDER BY anio, medio
```

```sql audiencia_ult
SELECT
    max(penetracion_pct) FILTER (WHERE medio = 'diarios_internet') AS internet,
    max(penetracion_pct) FILTER (WHERE medio = 'diarios_papel') AS papel,
    max(penetracion_pct) FILTER (WHERE medio = 'diarios') AS diarios_total,
    max(penetracion_pct) FILTER (WHERE medio = 'radio') AS radio,
    max(penetracion_pct) FILTER (WHERE medio = 'television') AS tv,
    CAST(max(anio) AS INTEGER) AS anio
FROM mother.medios_sector_audiencia
WHERE anio = (SELECT max(anio) FROM mother.medios_sector_audiencia)
```

```sql minutos
SELECT CAST(anio AS INTEGER) AS anio, medio_nombre AS medio, minutos_dia
FROM mother.medios_sector_audiencia
WHERE medio IN ('radio', 'television') AND minutos_dia IS NOT NULL
ORDER BY anio, medio
```

```sql minutos_resumen
SELECT
    (SELECT CAST(anio AS INTEGER) FROM ${minutos} WHERE medio = 'Televisión' ORDER BY minutos_dia DESC LIMIT 1) AS anio_max_tv,
    (SELECT minutos_dia FROM ${minutos} WHERE medio = 'Televisión' ORDER BY minutos_dia DESC LIMIT 1) AS max_tv,
    (SELECT minutos_dia FROM ${minutos} WHERE medio = 'Televisión' ORDER BY anio DESC LIMIT 1) AS ult_tv,
    (SELECT minutos_dia FROM ${minutos} WHERE medio = 'Radio' ORDER BY anio DESC LIMIT 1) AS ult_radio
```

```sql cabeceras
SELECT u.puesto, u.cabecera, u.penetracion_pct, u.lectores_miles, u.por_1000_hab,
       i.lectores_miles AS lectores_miles_ini, u.variacion_desde_inicio_pct,
       CAST(u.anio AS INTEGER) AS anio
FROM mother.medios_sector_cabeceras u
JOIN mother.medios_sector_cabeceras i ON i.cabecera = u.cabecera AND i.anio = (SELECT min(anio) FROM mother.medios_sector_cabeceras)
WHERE u.anio = (SELECT max(anio) FROM mother.medios_sector_cabeceras)
ORDER BY u.penetracion_pct DESC, u.cabecera
```

```sql cabeceras_serie
SELECT CAST(anio AS INTEGER) AS anio, cabecera, por_1000_hab
FROM mother.medios_sector_cabeceras
WHERE cabecera IN ('Marca', 'El País', 'El Mundo', 'As', 'La Vanguardia', 'ABC', 'La Voz de Galicia')
ORDER BY anio, cabecera
```

```sql pub_mercado
SELECT anio, metodologia, inversion_meur_nominal, eur_hab_real, anio_base
FROM mother.medios_sector_publicidad
WHERE medio = 'subtotal_controlados'
QUALIFY row_number() OVER (PARTITION BY anio ORDER BY CASE WHEN metodologia = 'controlados' THEN 1 ELSE 2 END) = 1
ORDER BY anio
```

```sql pub_resumen
SELECT
    (SELECT CAST(anio AS INTEGER) FROM ${pub_mercado} ORDER BY anio DESC LIMIT 1) AS anio,
    (SELECT eur_hab_real FROM ${pub_mercado} ORDER BY anio DESC LIMIT 1) AS eur_hab,
    (SELECT inversion_meur_nominal FROM ${pub_mercado} ORDER BY anio DESC LIMIT 1) AS meur,
    (SELECT CAST(anio AS INTEGER) FROM ${pub_mercado} ORDER BY eur_hab_real DESC LIMIT 1) AS anio_max,
    (SELECT eur_hab_real FROM ${pub_mercado} ORDER BY eur_hab_real DESC LIMIT 1) AS eur_hab_max,
    (SELECT anio_base FROM ${pub_mercado} ORDER BY anio DESC LIMIT 1) AS anio_base
```

```sql pub_larga
SELECT CAST(anio AS INTEGER) AS anio, medio_nombre AS medio, eur_hab_real
FROM mother.medios_sector_publicidad
WHERE metodologia = 'convencionales' AND es_desglose
ORDER BY anio, medio
```

```sql pub_prensa
SELECT
    max(eur_hab_real) FILTER (WHERE medio = 'diarios' AND anio = 2007) AS diarios_2007,
    max(eur_hab_real) FILTER (WHERE medio = 'diarios' AND anio = 2023) AS diarios_2023,
    max(pct_controlados) FILTER (WHERE medio = 'diarios' AND anio = 2007) AS pct_2007,
    max(pct_controlados) FILTER (WHERE medio = 'diarios' AND anio = 2023) AS pct_2023,
    max(eur_hab_real) FILTER (WHERE medio = 'television' AND anio = 2007) AS tv_2007,
    max(eur_hab_real) FILTER (WHERE medio = 'television' AND anio = 2023) AS tv_2023,
    max(eur_hab_real) FILTER (WHERE medio = 'internet' AND anio = 2023) AS internet_2023
FROM mother.medios_sector_publicidad
WHERE metodologia = 'convencionales'
```

```sql pub_nueva
SELECT medio_nombre AS medio, eur_hab_real, inversion_meur_nominal, pct_controlados, CAST(anio AS INTEGER) AS anio
FROM mother.medios_sector_publicidad
WHERE metodologia = 'controlados' AND es_desglose
  AND anio = (SELECT max(anio) FROM mother.medios_sector_publicidad WHERE metodologia = 'controlados')
ORDER BY eur_hab_real DESC
```

```sql pub_papel_web
SELECT
    max(inversion_meur_nominal) FILTER (WHERE medio = 'diarios_dominicales_papel') AS papel,
    max(inversion_meur_nominal) FILTER (WHERE medio = 'diarios_dominicales_digital') AS web,
    max(pct_controlados) FILTER (WHERE medio IN ('redes_sociales')) AS pct_redes,
    max(pct_controlados) FILTER (WHERE medio IN ('search')) AS pct_search,
    CAST(max(anio) AS INTEGER) AS anio
FROM mother.medios_sector_publicidad
WHERE metodologia = 'controlados' AND anio = (SELECT max(anio) FROM mother.medios_sector_publicidad WHERE metodologia = 'controlados')
```

```sql empleo
SELECT CAST(anio AS INTEGER) AS anio, rama_nombre AS rama, ocupados_100k_hab, ocupados, serie
FROM mother.medios_sector_empresas
WHERE pais = 'ES' AND rama IN ('J5813', 'J5814', 'J601', 'J602', 'J6391') AND ocupados IS NOT NULL
ORDER BY anio, rama
```

```sql empleo_largo
SELECT CAST(anio AS INTEGER) AS anio, rama_nombre AS rama, ocupados_100k_hab, cifra_negocios_eur_hab_real
FROM mother.medios_sector_empresas
WHERE pais = 'ES' AND rama IN ('J60', 'J58') AND ocupados IS NOT NULL
ORDER BY anio, rama
```

```sql empleo_ult
SELECT
    CAST(max(anio) AS INTEGER) AS anio,
    max(ocupados) FILTER (WHERE rama = 'J5813') AS periodicos,
    max(ocupados_100k_hab) FILTER (WHERE rama = 'J5813') AS periodicos_100k,
    max(empresas) FILTER (WHERE rama = 'J5813') AS periodicos_empresas,
    max(cifra_negocios_eur_hab_real) FILTER (WHERE rama = 'J5813') AS periodicos_eur_hab,
    max(ocupados) FILTER (WHERE rama = 'J601') AS radio,
    max(ocupados) FILTER (WHERE rama = 'J602') AS tv,
    max(ocupados) FILTER (WHERE rama = 'J6391') AS agencias,
    max(cifra_negocios_eur_hab_real) FILTER (WHERE rama = 'J602') AS tv_eur_hab
FROM mother.medios_sector_empresas
WHERE pais = 'ES' AND anio = (SELECT max(anio) FROM mother.medios_sector_empresas WHERE pais = 'ES' AND rama = 'J5813' AND ocupados IS NOT NULL)
```

```sql empleo_spark
SELECT CAST(anio AS INTEGER) AS anio, ocupados_100k_hab
FROM mother.medios_sector_empresas
WHERE pais = 'ES' AND rama = 'J5813' AND ocupados IS NOT NULL
ORDER BY anio
```

```sql j60_extremos
SELECT
    max(ocupados_100k_hab) FILTER (WHERE anio = 2008) AS tv_radio_2008,
    max(ocupados_100k_hab) FILTER (WHERE anio = (SELECT max(anio) FROM mother.medios_sector_empresas WHERE pais = 'ES' AND rama = 'J60' AND ocupados IS NOT NULL)) AS tv_radio_ult
FROM mother.medios_sector_empresas
WHERE pais = 'ES' AND rama = 'J60'
```

```sql ue
SELECT CASE pais WHEN 'EU27_2020' THEN 'UE-27' WHEN 'ES' THEN 'España' WHEN 'DE' THEN 'Alemania' WHEN 'FR' THEN 'Francia'
            WHEN 'IT' THEN 'Italia' WHEN 'NL' THEN 'Países Bajos' WHEN 'PT' THEN 'Portugal' WHEN 'PL' THEN 'Polonia'
            WHEN 'SE' THEN 'Suecia' WHEN 'BE' THEN 'Bélgica' WHEN 'AT' THEN 'Austria' WHEN 'DK' THEN 'Dinamarca'
            WHEN 'FI' THEN 'Finlandia' WHEN 'IE' THEN 'Irlanda' WHEN 'EL' THEN 'Grecia' WHEN 'CZ' THEN 'Chequia'
            WHEN 'RO' THEN 'Rumanía' WHEN 'HU' THEN 'Hungría' ELSE pais END AS pais_nombre,
       pais, CAST(anio AS INTEGER) AS anio,
       max(ocupados_100k_hab) FILTER (WHERE rama = 'J5813') AS periodicos_100k,
       max(ocupados_100k_hab) FILTER (WHERE rama = 'J60') AS radio_tv_100k,
       max(cifra_negocios_eur_hab) FILTER (WHERE rama = 'J5813') AS periodicos_eur_hab,
       max(cifra_negocios_eur_hab) FILTER (WHERE rama = 'J60') AS radio_tv_eur_hab,
       CASE WHEN pais = 'ES' THEN 'España' WHEN pais = 'EU27_2020' THEN 'UE-27' ELSE 'Otros países' END AS grupo
FROM mother.medios_sector_empresas
WHERE serie = 'desde_2021' AND pais NOT IN ('EU28', 'LU', 'MT', 'CY')
  AND anio = (SELECT max(anio) FROM mother.medios_sector_empresas WHERE pais = 'ES' AND rama = 'J5813' AND ocupados IS NOT NULL)
GROUP BY ALL
HAVING max(ocupados_100k_hab) FILTER (WHERE rama = 'J5813') IS NOT NULL
ORDER BY periodicos_100k DESC
```

```sql ue_es
SELECT
    (SELECT periodicos_100k FROM ${ue} WHERE pais = 'ES') AS es,
    (SELECT periodicos_100k FROM ${ue} WHERE pais = 'EU27_2020') AS ue,
    (SELECT count(*) FROM ${ue} WHERE pais NOT IN ('EU27_2020')) AS n,
    (SELECT count(*) FROM ${ue} WHERE pais NOT IN ('EU27_2020') AND periodicos_100k > (SELECT periodicos_100k FROM ${ue} WHERE pais = 'ES')) + 1 AS puesto,
    (SELECT radio_tv_100k FROM ${ue} WHERE pais = 'ES') AS es_tv,
    (SELECT radio_tv_100k FROM ${ue} WHERE pais = 'EU27_2020') AS ue_tv
```

```sql grupos
SELECT CAST(anio AS INTEGER) AS anio, grupo, perimetro, ingresos_eur_hab_real, publicidad_eur_hab_real,
       resultado_neto_eur_hab_real, publicidad_pct_ingresos, margen_neto_pct, plantilla_media,
       ingresos_meur_real, publicidad_meur_real, resultado_neto_meur_real, anio_base
FROM mother.medios_sector_grupos
ORDER BY grupo, anio
```

```sql grupos_cambio
SELECT grupo,
    min(anio) AS anio_ini,
    max(anio) AS anio_ult,
    max(CASE WHEN anio = 2007 THEN ingresos_eur_hab_real END) AS ing_hab_2007,
    arg_max(ingresos_eur_hab_real, anio) AS ing_hab_ult,
    100.0 * (arg_max(ingresos_eur_hab_real, anio) / max(CASE WHEN anio = 2007 THEN ingresos_eur_hab_real END) - 1) AS ing_var_pct,
    max(CASE WHEN anio = 2007 THEN publicidad_eur_hab_real END) AS pub_hab_2007,
    arg_max(publicidad_eur_hab_real, anio) AS pub_hab_ult,
    arg_max(publicidad_pct_ingresos, anio) AS pub_pct_ult,
    arg_max(resultado_neto_eur_hab_real, anio) AS res_hab_ult,
    arg_max(ingresos_meur_real, anio) AS ing_meur_ult
FROM ${grupos}
GROUP BY grupo
ORDER BY ing_hab_ult DESC
```

```sql grupos_resumen
SELECT
    (SELECT max(anio_base) FROM ${grupos}) AS anio_base,
    (SELECT max(anio_ult) FROM ${grupos_cambio}) AS anio_ult,
    (SELECT sum(ing_hab_2007) FROM ${grupos_cambio} WHERE ing_hab_2007 IS NOT NULL AND anio_ult = (SELECT max(anio_ult) FROM ${grupos_cambio})) AS ing_hab_2007,
    (SELECT sum(ing_hab_ult) FROM ${grupos_cambio} WHERE ing_hab_2007 IS NOT NULL AND anio_ult = (SELECT max(anio_ult) FROM ${grupos_cambio})) AS ing_hab_ult,
    (SELECT count(*) FROM ${grupos_cambio} WHERE ing_hab_2007 IS NOT NULL AND anio_ult = (SELECT max(anio_ult) FROM ${grupos_cambio})) AS n_grupos
```

```sql publico
SELECT CAST(anio AS INTEGER) AS anio, controlados_eur_hab_real, publicidad_estado_eur_hab_real, tv_publica_eur_hab_real,
       subvenciones_eur_hab_real, contratos_eur_hab_real, publicidad_estado_pct_mercado, tv_publica_pct_mercado,
       tv_publica_pct_publicidad_tv, controlados_meur, publicidad_estado_meur, tv_publica_meur
FROM mother.medios_sector_dinero_publico
WHERE publicidad_estado_meur IS NOT NULL
ORDER BY anio
```

```sql publico_series
SELECT anio, 'Publicidad del Estado y sus empresas' AS concepto, publicidad_estado_pct_mercado AS pct FROM ${publico}
UNION ALL
SELECT anio, 'RTVE y radiotelevisiones autonómicas' AS concepto, tv_publica_pct_mercado AS pct FROM ${publico} WHERE tv_publica_pct_mercado IS NOT NULL
ORDER BY anio, concepto
```

```sql publico_ult
SELECT * FROM ${publico} WHERE tv_publica_eur_hab_real IS NOT NULL ORDER BY anio DESC LIMIT 1
```

```sql publico_ult_age
SELECT * FROM ${publico} ORDER BY anio DESC LIMIT 1
```

# <span aria-hidden="true">📈</span> El negoci dels mitjans

Quant es llegeixen, es veuen i s'escolten els mitjans a Espanya, de què viuen i quanta gent hi treballa. Les audiències són de l'Estudio General de Medios, la publicitat de l'Estudio InfoAdex i l'ocupació i la facturació de l'estadística d'empreses de l'INE i Eurostat. Totes les xifres van **per habitant i descomptada la inflació**, en euros del {pub_resumen[0]?.anio_base}. El que paguen les administracions als mitjans és a [Diners públics als mitjans](/ca/medios/dinero-publico).

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if papel_resumen.length && pub_resumen.length && empleo_ult.length && publico_ult_age.length}
    <KpiCard
        title="Lectors de diaris en paper"
        value={papel_resumen[0].por_1000}
        formattedValue={formatNumber(papel_resumen[0].por_1000, 0)}
        unit="per 1.000 habitants"
        period={`${papel_resumen[0].anio} · ${formatNumber(papel_resumen[0].miles / 1000, 1)} milions de lectors al dia`}
        source="AIMC (EGM)"
        direction="positive-up"
        sparklineData={papel.filter(d => d.por_1000_hab !== null).map(d => ({...d, y: d.por_1000_hab}))}
    />
    <KpiCard
        title="Inversió publicitària en mitjans"
        value={pub_resumen[0].eur_hab}
        formattedValue={formatNumber(pub_resumen[0].eur_hab, 0) + ' €'}
        unit="per habitant"
        period={`${pub_resumen[0].anio} · ${formatCompact(pub_resumen[0].meur * 1e6, 2)} € en televisió, premsa, ràdio, digital, exterior i cinema`}
        source="InfoAdex"
        direction="positive-up"
        sparklineData={pub_mercado.map(d => ({...d, y: d.eur_hab_real}))}
    />
    <KpiCard
        title="Ocupació en l'edició de diaris"
        value={empleo_ult[0].periodicos_100k}
        formattedValue={formatNumber(empleo_ult[0].periodicos_100k, 1)}
        unit="ocupats per 100.000 habitants"
        period={`${empleo_ult[0].anio} · ${formatNumber(empleo_ult[0].periodicos, 0)} persones en ${formatNumber(empleo_ult[0].periodicos_empresas, 0)} empreses`}
        source="INE i Eurostat (SBS)"
        direction="positive-up"
        sparklineData={empleo_spark.map(d => ({...d, y: d.ocupados_100k_hab}))}
    />
    <KpiCard
        title="Publicitat de l'Estat respecte al mercat"
        value={publico_ult_age[0].publicidad_estado_pct_mercado}
        formattedValue={formatNumber(publico_ult_age[0].publicidad_estado_pct_mercado, 1) + ' %'}
        unit="de la inversió en mitjans"
        period={`${publico_ult_age[0].anio} · ${formatCompact(publico_ult_age[0].publicidad_estado_meur * 1e6, 2)} € en campanyes de l'Estat i les seves empreses`}
        source="Moncloa i InfoAdex"
        direction="positive-down"
        sparklineData={publico.map(d => ({...d, y: d.publicidad_estado_pct_mercado}))}
    />
    {/if}
</div>

## Quant es llegeix, es veu i s'escolta

El {papel_resumen[0]?.anio} llegien un diari en paper cada dia {formatNumber(papel_resumen[0]?.por_1000, 0)} de cada 1.000 habitants, el {formatNumber(papel_resumen[0]?.pct, 1)} % dels majors de 14 anys. El màxim de la sèrie va ser el {papel_resumen[0]?.anio_pct_max}, amb el {formatNumber(papel_resumen[0]?.pct_max, 1)} %. Fins al 2017 l'EGM compta només el paper; des del 2018 hi suma qui llegeix la rèplica digital (PDF o visor) del diari.

<LineChart
    data={papel}
    x=anio
    y=por_1000_hab
    xFmt='0'
    yFmt='0'
    yAxisTitle="Lectors per 1.000 habitants"
    title="Lectors diaris de diaris en paper, per cada 1.000 habitants"
/>

La lectura no ha desaparegut: s'ha traslladat al web. El {audiencia_ult[0]?.anio} el {formatNumber(audiencia_ult[0]?.internet, 1)} % dels majors de 14 anys entrava cada dia al web d'algun diari, enfront del {formatNumber(audiencia_ult[0]?.papel, 1)} % que el llegia en paper; sumant les dues formes, el {formatNumber(audiencia_ult[0]?.diarios_total, 1)} %. La televisió arriba al {formatNumber(audiencia_ult[0]?.tv, 1)} % de la població cada dia i la ràdio al {formatNumber(audiencia_ult[0]?.radio, 1)} %.

<LineChart
    data={audiencia}
    x=anio
    y=penetracion_pct
    series=medio
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% de la població de 14 anys o més"
    seriesColors={{'Diarios en papel': '#2563eb', 'Diarios en internet': '#93c5fd', 'Revistas en papel': '#a855f7', 'Radio': '#f59e0b', 'Televisión': '#ef4444'}}
    title="Audiència diària de cada mitjà (revistes: en el seu període de publicació), % de la població de 14 anys o més"
/>

Cada persona de 14 anys o més veu de mitjana {minutos_resumen[0]?.ult_tv} minuts de televisió al dia i escolta {minutos_resumen[0]?.ult_radio} minuts de ràdio. El màxim de la televisió va ser el {minutos_resumen[0]?.anio_max_tv}, amb {minutos_resumen[0]?.max_tv} minuts.

<LineChart
    data={minutos}
    x=anio
    y=minutos_dia
    series=medio
    xFmt='0'
    yFmt='0'
    yAxisTitle="Minuts per persona i dia"
    seriesColors={{'Radio': '#f59e0b', 'Televisión': '#ef4444'}}
    title="Minuts diaris de ràdio i televisió per persona"
/>

### Els diaris més llegits en paper

Lectors diaris de cada diari en paper i rèplica digital el {cabeceras[0]?.anio}, comparats amb el 2009. No inclou qui llegeix el diari al seu web.

<LineChart
    data={cabeceras_serie}
    x=anio
    y=por_1000_hab
    series=cabecera
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Lectors per 1.000 habitants"
    title="Lectors diaris dels principals diaris en paper, per 1.000 habitants"
/>

<DataTable data={cabeceras} rows=15 search=true>
    <Column id=puesto title="Posició" fmt='0' />
    <Column id=cabecera title="Diari" />
    <Column id=por_1000_hab title="Lectors per 1.000 hab." fmt='0.0' />
    <Column id=lectores_miles title="Lectors (milers)" fmt='#,##0' />
    <Column id=lectores_miles_ini title="Lectors el 2009 (milers)" fmt='#,##0' />
    <Column id=variacion_desde_inicio_pct title="Variació des del 2009 %" fmt='0' contentType=delta />
</DataTable>

## De què viuen: la publicitat

El {pub_resumen[0]?.anio} els anunciants van invertir {formatNumber(pub_resumen[0]?.eur_hab, 0)} € per habitant en els mitjans convencionals (televisió, premsa, revistes, ràdio, internet, exterior i cinema), descomptada la inflació. El màxim va ser el {pub_resumen[0]?.anio_max}, amb {formatNumber(pub_resumen[0]?.eur_hab_max, 0)} €. La premsa diària en paper ha passat de {formatNumber(pub_prensa[0]?.diarios_2007, 1)} € per habitant el 2007 ({formatNumber(pub_prensa[0]?.pct_2007, 0)} % de la inversió) a {formatNumber(pub_prensa[0]?.diarios_2023, 1)} € el 2023 ({formatNumber(pub_prensa[0]?.pct_2023, 0)} %), i la televisió de {formatNumber(pub_prensa[0]?.tv_2007, 0)} € a {formatNumber(pub_prensa[0]?.tv_2023, 0)} €, mentre que internet arribava a {formatNumber(pub_prensa[0]?.internet_2023, 0)} €.

<BarChart
    data={pub_larga}
    x=anio
    y=eur_hab_real
    series=medio
    xFmt='0'
    yFmt='0'
    yAxisTitle="€ per habitant (descomptada la inflació)"
    seriesColors={{'Televisión': '#ef4444', 'Diarios (papel)': '#2563eb', 'Internet': '#22c55e', 'Radio': '#f59e0b', 'Revistas': '#a855f7', 'Exterior': '#64748b', 'Dominicales': '#93c5fd', 'Cine': '#0f172a'}}
    title="Inversió publicitària en mitjans convencionals per suport, € per habitant descomptada la inflació (sèrie llarga, 2004-2023)"
/>

En aquesta sèrie llarga «Diaris» és només el paper i tota la publicitat digital, també la dels webs dels diaris, va a «Internet», que inclou Google, Meta i la resta de plataformes. Des de l'estudi del 2025, InfoAdex suma a cada mitjà la seva part digital i separa cercadors, xarxes socials i altres webs. Amb aquest criteri, el {pub_papel_web[0]?.anio} els diaris i dominicals van ingressar {formatNumber(pub_papel_web[0]?.web, 0)} milions d'euros per publicitat als seus webs i {formatNumber(pub_papel_web[0]?.papel, 0)} milions en paper, i les xarxes socials i els cercadors es van endur el {formatNumber(pub_papel_web[0]?.pct_redes + pub_papel_web[0]?.pct_search, 0)} % de tota la inversió.

<BarChart
    data={pub_nueva}
    x=medio
    y=eur_hab_real
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="€ per habitant"
    title="Inversió publicitària per mitjà el {pub_nueva[0]?.anio}, cada mitjà amb la seva part digital (€ per habitant)"
/>

## Quanta gent treballa als mitjans

Persones ocupades (assalariades i per compte propi) a les empreses de cada branca segons l'estadística estructural d'empreses. El {empleo_ult[0]?.anio} l'edició de diaris ocupava {formatNumber(empleo_ult[0]?.periodicos, 0)} persones, les ràdios {formatNumber(empleo_ult[0]?.radio, 0)}, les televisions {formatNumber(empleo_ult[0]?.tv, 0)} i les agències de notícies {formatNumber(empleo_ult[0]?.agencias, 0)}. Eurostat només dona aquestes branques per separat des del 2016 (amb una ruptura de mètode el 2021).

<LineChart
    data={empleo}
    x=anio
    y=ocupados_100k_hab
    series=rama
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Ocupats per 100.000 habitants"
    seriesColors={{'Periódicos': '#2563eb', 'Revistas': '#a855f7', 'Radio': '#f59e0b', 'Televisión': '#ef4444', 'Agencias de noticias': '#64748b'}}
    title="Persones ocupades a les empreses de mitjans, per 100.000 habitants"
/>

Per veure des del 2005 cal fer servir branques més àmplies: ràdio i televisió juntes, i tota l'edició (que inclou llibres i programari). Ràdio i televisió han passat de {formatNumber(j60_extremos[0]?.tv_radio_2008, 0)} ocupats per 100.000 habitants el 2008 a {formatNumber(j60_extremos[0]?.tv_radio_ult, 0)}.

<LineChart
    data={empleo_largo}
    x=anio
    y=ocupados_100k_hab
    series=rama
    xFmt='0'
    yFmt='0'
    yAxisTitle="Ocupats per 100.000 habitants"
    title="Ocupats en edició i en ràdio i televisió, per 100.000 habitants (2005-últim)"
/>

<LineChart
    data={empleo_largo}
    x=anio
    y=cifra_negocios_eur_hab_real
    series=rama
    xFmt='0'
    yFmt='0'
    yAxisTitle="€ per habitant (descomptada la inflació)"
    title="Xifra de negocis de l'edició i de la ràdio i televisió, € per habitant descomptada la inflació"
/>

### En comparació amb Europa

El {ue[0]?.anio} Espanya tenia {formatNumber(ue_es[0]?.es, 1)} ocupats en l'edició de diaris per cada 100.000 habitants, enfront de {formatNumber(ue_es[0]?.ue, 1)} de mitjana a la UE (posició {ue_es[0]?.puesto} de {ue_es[0]?.n} països amb dada). En ràdio i televisió, {formatNumber(ue_es[0]?.es_tv, 1)} enfront de {formatNumber(ue_es[0]?.ue_tv, 1)}.

<BarChart
    data={ue}
    x=pais_nombre
    y=periodicos_100k
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="Ocupats per 100.000 habitants"
    seriesColors={{'España': '#dc2626', 'UE-27': '#0f172a', 'Otros países': '#94a3b8'}}
    title="Ocupats en l'edició de diaris per 100.000 habitants, {ue[0]?.anio}"
/>

<DataTable data={ue} rows=27>
    <Column id=pais_nombre title="País" />
    <Column id=periodicos_100k title="Diaris: ocupats per 100.000 hab." fmt='0.0' />
    <Column id=periodicos_eur_hab title="Diaris: facturació € per hab." fmt='0.0' />
    <Column id=radio_tv_100k title="Ràdio i TV: ocupats per 100.000 hab." fmt='0.0' />
    <Column id=radio_tv_eur_hab title="Ràdio i TV: facturació € per hab." fmt='0.0' />
</DataTable>

## Els grans grups de comunicació

Ingressos, publicitat, resultat i plantilla dels grans grups de comunicació espanyols segons els seus propis comptes anuals, per habitant d'Espanya i en euros de {grupos_resumen[0]?.anio_base} (descomptada la inflació). Entre el 2007 i el {grupos_resumen[0]?.anio_ult}, els {grupos_resumen[0]?.n_grupos} grups amb dades dels dos anys van passar d'ingressar entre tots {formatNumber(grupos_resumen[0]?.ing_hab_2007, 0)} € per habitant a {formatNumber(grupos_resumen[0]?.ing_hab_ult, 0)} €.

No tots mesuren el mateix: Prisa inclou l'educació (Santillana) i les seves caigudes del 2014, el 2019 i el 2020 són vendes de negocis (Digital+, Media Capital i Santillana Espanya); Unidad Editorial (El Mundo, Marca, Expansión) és l'àrea espanyola de la italiana RCS MediaGroup, que no publica el seu resultat net ni, des del 2016, la seva plantilla; i Mediaset España (Telecinco, Cuatro) és una àrea del grup MFE-MediaForEurope des del 2023, sense resultat net propi i amb la plantilla en llocs de treball a jornada completa.

<LineChart
    data={grupos}
    x=anio
    y=ingresos_eur_hab_real
    series=grupo
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="€ per habitant (descomptada la inflació)"
    seriesColors={{'Atresmedia': '#ea580c', 'Mediaset España': '#2563eb', 'Prisa': '#9333ea', 'Unidad Editorial': '#dc2626', 'Vocento': '#16a34a'}}
    title="Ingressos de cada grup, € per habitant descomptada la inflació"
/>

<DataTable data={grupos_cambio} rows=10>
    <Column id=grupo title="Grup" />
    <Column id=ing_hab_2007 title="Ingressos 2007, €/hab." fmt='0.0' />
    <Column id=ing_hab_ult title="Ingressos darrer any, €/hab." fmt='0.0' />
    <Column id=ing_var_pct title="Variació des del 2007" fmt='0"%"' contentType=delta />
    <Column id=anio_ult title="Darrer any" fmt='0' />
    <Column id=ing_meur_ult title="Ingressos darrer any, milions d'€ reals" fmt='#,##0' />
</DataTable>

### Publicitat

La publicitat pesa molt més a les televisions que als grups de premsa, que viuen també de la venda d'exemplars, les subscripcions i altres negocis; i a les televisions pesa cada vegada menys.

<LineChart
    data={grupos}
    x=anio
    y=publicidad_eur_hab_real
    series=grupo
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="€ per habitant (descomptada la inflació)"
    seriesColors={{'Atresmedia': '#ea580c', 'Mediaset España': '#2563eb', 'Prisa': '#9333ea', 'Unidad Editorial': '#dc2626', 'Vocento': '#16a34a'}}
    title="Ingressos de publicitat de cada grup, € per habitant descomptada la inflació"
/>

<LineChart
    data={grupos}
    x=anio
    y=publicidad_pct_ingresos
    series=grupo
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% dels ingressos"
    seriesColors={{'Atresmedia': '#ea580c', 'Mediaset España': '#2563eb', 'Prisa': '#9333ea', 'Unidad Editorial': '#dc2626', 'Vocento': '#16a34a'}}
    title="Pes de la publicitat en els ingressos de cada grup"
/>

### Plantilla i resultats

<LineChart
    data={grupos}
    x=anio
    y=plantilla_media
    series=grupo
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="Empleats (mitjana de l'any)"
    seriesColors={{'Atresmedia': '#ea580c', 'Mediaset España': '#2563eb', 'Prisa': '#9333ea', 'Unidad Editorial': '#dc2626', 'Vocento': '#16a34a'}}
    title="Plantilla mitjana de cada grup"
/>

El resultat net és l'atribuït als accionistes de cada grup. Les pèrdues de Prisa el 2014 (2.237 milions d'euros corrents, 60 € per habitant) surten de l'escala de qualsevol gràfic, així que els resultats van a la taula.

<DataTable data={grupos} rows=15 search=true>
    <Column id=grupo title="Grup" />
    <Column id=anio title="Any" fmt='0' />
    <Column id=ingresos_eur_hab_real title="Ingressos, €/hab." fmt='0.00' />
    <Column id=publicidad_eur_hab_real title="Publicitat, €/hab." fmt='0.00' />
    <Column id=resultado_neto_eur_hab_real title="Resultat net, €/hab." fmt='0.00' contentType=delta />
    <Column id=margen_neto_pct title="Marge net" fmt='0.0"%"' />
    <Column id=plantilla_media title="Plantilla mitjana" fmt='#,##0' />
    <Column id=ingresos_meur_real title="Ingressos, milions d'€ reals" fmt='#,##0' />
    <Column id=resultado_neto_meur_real title="Resultat, milions d'€ reals" fmt='#,##0' />
</DataTable>

## Els diners públics respecte al mercat publicitari

Per situar els diners públics en la mida del negoci, el gràfic divideix el que gasten l'Estat i les seves empreses en campanyes de publicitat, i el que reben RTVE i les ràdios i televisions autonòmiques, entre la inversió publicitària total en mitjans d'aquell any. El {publico_ult_age[0]?.anio} la publicitat de l'Estat va equivaler al {formatNumber(publico_ult_age[0]?.publicidad_estado_pct_mercado, 1)} % de la inversió publicitària en mitjans. El {publico_ult[0]?.anio} el finançament públic de les ràdios i televisions va equivaler al {formatNumber(publico_ult[0]?.tv_publica_pct_mercado, 0)} % de tota aquesta inversió i al {formatNumber(publico_ult[0]?.tv_publica_pct_publicidad_tv, 0)} % de la publicitat en televisió.

<LineChart
    data={publico_series}
    x=anio
    y=pct
    series=concepto
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% de la inversió publicitària en mitjans"
    seriesColors={{'Publicidad del Estado y sus empresas': '#2563eb', 'RTVE y radiotelevisiones autonómicas': '#f59e0b'}}
    title="Diners públics en % de la inversió publicitària en mitjans"
/>

<DataTable data={publico} rows=20>
    <Column id=anio title="Any" fmt='0' />
    <Column id=controlados_eur_hab_real title="Inversió publicitària en mitjans, €/hab." fmt='0.0' />
    <Column id=publicidad_estado_eur_hab_real title="Publicitat de l'Estat, €/hab." fmt='0.00' />
    <Column id=tv_publica_eur_hab_real title="RTVE i autonòmiques, €/hab." fmt='0.0' />
    <Column id=subvenciones_eur_hab_real title="Subvencions a mitjans privats, €/hab." fmt='0.00' />
    <Column id=contratos_eur_hab_real title="Contractes amb mitjans privats, €/hab." fmt='0.00' />
</DataTable>

Són magnituds que no mesuren exactament el mateix: InfoAdex estima el que reben els mitjans pels espais publicitaris, net de descomptes, mentre que el cost de les campanyes de l'Estat inclou la creativitat, la producció i, segons sembla, l'IVA. El finançament de les ràdios i televisions públiques no és publicitat, però són diners que entren al mateix mercat audiovisual. El finançament de les autonòmiques només hi és des del 2017 i hi falta la publicitat de comunitats i ajuntaments, que només publiquen alguns.

## Metodologia i fonts

- **Audiències**: [AIMC, Marco General de los Medios en España 2026](https://www.aimc.es/a1mc-c0nt3nt/uploads/2026/02/Marco_General_Medios_2026.pdf) (publicació gratuïta amb dades de l'Estudio General de Medios): evolució de l'audiència general 1980-2025, minuts de ràdio i televisió 1991-2025 i lectors per diari 2009-2025. Penetració sobre la població de 14 anys o més; per passar a lectors per 1.000 habitants es multiplica per l'univers de l'EGM i es divideix per tota la població del padró de l'INE. Fins al 2017 la lectura de diaris és només paper; des del 2018 inclou la rèplica digital.
- **Inversió publicitària**: resums públics de l'[Estudio InfoAdex de la inversión publicitaria en España](https://www.infoadex.es/) (edicions 2010-2026; l'estudi complet és de pagament). Per a cada any es fa servir l'última revisió publicada. La sèrie 2004-2023 segueix el criteri antic (diaris = paper; el digital, a internet) i la del 2022-2025 el nou (cada mitjà amb el seu web); no es barregen. Internet es va reestimar a l'alça des del 2014 i exterior des del 2018.
- **Empreses i ocupació**: Eurostat, estadístiques estructurals d'empreses ([sbs_na_1a_se_r2](https://ec.europa.eu/eurostat/databrowser/view/sbs_na_1a_se_r2/default/table) fins al 2020 i [sbs_ovw_act](https://ec.europa.eu/eurostat/databrowser/view/sbs_ovw_act/default/table) des del 2021), que per a Espanya elabora l'INE amb l'Estadística Estructural d'Empreses del sector serveis. Branques CNAE 58.13 (diaris), 58.14 (revistes), 60.1 (ràdio), 60.2 (televisió) i 63.91 (agències de notícies). El 2021 va canviar el mètode (reglament FRIBS).
- **Grups de comunicació**: comptes anuals consolidats d'Atresmedia, Mediaset España, Prisa i Vocento (webs d'accionistes), i informes anuals de RCS MediaGroup per a l'àrea Unidad Editorial; transcrits a mà, amb el PDF i les pàgines de cada xifra al seed `medios_sector_grupos_cuentas`. Ingressos = xifra de negocis més altres ingressos d'explotació; publicitat = vendes de publicitat de la nota d'ingressos o de la informació per segments; resultat = atribuït a la societat dominant. Cada any amb els comptes d'aquell any, sense les reexpressions posteriors.
- **Diners públics**: marts de la secció [Diners públics als mitjans](/ca/medios/dinero-publico) (Comisión de Publicidad y Comunicación Institucional, CNMC, comptes de RTVE, BDNS i Plataforma de Contratación).
- **Euros constants** amb l'IPC de l'INE i **població** del padró.
