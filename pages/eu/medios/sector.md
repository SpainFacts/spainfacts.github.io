---
title: Komunikabideen negozioa
description: "Zenbat irakurtzen, ikusten eta entzuten diren komunikabideak Espainian, zerez bizi diren (publizitate-inbertsioa euskarrika) eta zenbat jendek egiten duen lan haietan, biztanleko eta inflazioa kenduta, EBrekin eta jasotzen duten diru publikoarekin alderatuta."
i18n_origen: e0531df8ebcc
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
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
SELECT CAST(anio AS INTEGER) AS anio, grupo, ingresos_meur_real, resultado_neto_meur_real, ingresos_eur_hab_real,
       ingresos_meur_nominal, resultado_neto_meur_nominal, margen_neto_pct
FROM mother.medios_sector_grupos
ORDER BY anio
```

```sql grupos_resumen
SELECT
    (SELECT ingresos_meur_real FROM ${grupos} WHERE anio = 2007) AS ing_2007,
    (SELECT ingresos_meur_real FROM ${grupos} ORDER BY anio DESC LIMIT 1) AS ing_ult,
    (SELECT CAST(anio AS INTEGER) FROM ${grupos} ORDER BY anio DESC LIMIT 1) AS anio_ult,
    (SELECT CAST(anio AS INTEGER) FROM ${grupos} ORDER BY ingresos_meur_real ASC LIMIT 1) AS anio_min,
    (SELECT ingresos_meur_real FROM ${grupos} ORDER BY ingresos_meur_real ASC LIMIT 1) AS ing_min
```

```sql grupos_series
SELECT anio, 'Ingresos' AS concepto, ingresos_meur_real AS meur_real FROM ${grupos}
UNION ALL
SELECT anio, 'Beneficio neto' AS concepto, resultado_neto_meur_real AS meur_real FROM ${grupos}
ORDER BY anio, concepto
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

# <span aria-hidden="true">📈</span> Komunikabideen negozioa

Zenbat irakurtzen, ikusten eta entzuten diren komunikabideak Espainian, zerez bizi diren eta zenbat jendek egiten duen lan haietan. Audientziak Estudio General de Medios-ekoak dira, publizitatea InfoAdex azterlanekoa, eta enplegua eta fakturazioa INEren eta Eurostaten enpresa-estatistikakoak. Zifra guztiak **biztanleko eta inflazioa kenduta** daude, {urteko(pub_resumen[0]?.anio_base)} eurotan. Administrazioek komunikabideei ordaintzen dietena [Diru publikoa komunikabideetan](/eu/medios/dinero-publico) orrian dago.

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if papel_resumen.length && pub_resumen.length && empleo_ult.length && publico_ult_age.length}
    <KpiCard
        title="Paperezko egunkarien irakurleak"
        value={papel_resumen[0].por_1000}
        formattedValue={formatNumber(papel_resumen[0].por_1000, 0)}
        unit="1.000 biztanleko"
        period={`${papel_resumen[0].anio} · ${formatNumber(papel_resumen[0].miles / 1000, 1)} milioi irakurle egunean`}
        source="AIMC (EGM)"
        direction="positive-up"
        sparklineData={papel.filter(d => d.por_1000_hab !== null).map(d => d.por_1000_hab)}
    />
    <KpiCard
        title="Publizitate-inbertsioa komunikabideetan"
        value={pub_resumen[0].eur_hab}
        formattedValue={formatNumber(pub_resumen[0].eur_hab, 0) + ' €'}
        unit="biztanleko"
        period={`${pub_resumen[0].anio} · ${formatCompact(pub_resumen[0].meur * 1e6, 2)} € telebistan, prentsan, irratian, digitalean, kanpoaldean eta zineman`}
        source="InfoAdex"
        direction="positive-up"
        sparklineData={pub_mercado.map(d => d.eur_hab_real)}
    />
    <KpiCard
        title="Enplegua egunkarien edizioan"
        value={empleo_ult[0].periodicos_100k}
        formattedValue={formatNumber(empleo_ult[0].periodicos_100k, 1)}
        unit="landun 100.000 biztanleko"
        period={`${empleo_ult[0].anio} · ${formatNumber(empleo_ult[0].periodicos, 0)} pertsona ${formatNumber(empleo_ult[0].periodicos_empresas, 0)} enpresatan`}
        source="INE eta Eurostat (SBS)"
        direction="positive-up"
        sparklineData={empleo_spark.map(d => d.ocupados_100k_hab)}
    />
    <KpiCard
        title="Estatuaren publizitatea merkatuaren aldean"
        value={publico_ult_age[0].publicidad_estado_pct_mercado}
        formattedValue={formatNumber(publico_ult_age[0].publicidad_estado_pct_mercado, 1) + ' %'}
        unit="komunikabideetako inbertsioarena"
        period={`${publico_ult_age[0].anio} · ${formatCompact(publico_ult_age[0].publicidad_estado_meur * 1e6, 2)} € Estatuaren eta haren enpresen kanpainetan`}
        source="Moncloa eta InfoAdex"
        direction="positive-down"
        sparklineData={publico.map(d => d.publicidad_estado_pct_mercado)}
    />
    {/if}
</div>

## Zenbat irakurtzen, ikusten eta entzuten den

{urtean(papel_resumen[0]?.anio)} 1.000 biztanleko {formatNumber(papel_resumen[0]?.por_1000, 0)}k irakurtzen zuten paperezko egunkari bat egunero, 14 urtetik gorakoen {formatNumber(papel_resumen[0]?.pct, 1)} %-k. Serieko maximoa {urtean(papel_resumen[0]?.anio_pct_max)} izan zen, {formatNumber(papel_resumen[0]?.pct_max, 1)} %-rekin. 2017ra arte EGMk papera bakarrik zenbatzen du; 2018tik, egunkariaren erreplika digitala (PDFa edo bisorea) irakurtzen dutenak ere gehitzen ditu.

<LineChart
    data={papel}
    x=anio
    y=por_1000_hab
    xFmt='0'
    yFmt='0'
    yAxisTitle="Irakurleak 1.000 biztanleko"
    title="Paperezko egunkarien eguneroko irakurleak, 1.000 biztanleko"
/>

Irakurketa ez da desagertu: webera joan da. {urtean(audiencia_ult[0]?.anio)} 14 urtetik gorakoen {formatNumber(audiencia_ult[0]?.internet, 1)} % sartzen zen egunero egunkariren baten webgunean, papera irakurtzen zuten {formatNumber(audiencia_ult[0]?.papel, 1)} %-aren aldean; bi moduak batuta, {formatNumber(audiencia_ult[0]?.diarios_total, 1)} %. Telebistak biztanleriaren {formatNumber(audiencia_ult[0]?.tv, 1)} %-ra iristen da egunero, eta irratiak {formatNumber(audiencia_ult[0]?.radio, 1)} %-ra.

<LineChart
    data={audiencia}
    x=anio
    y=penetracion_pct
    series=medio
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="14 urte edo gehiagoko biztanleriaren %"
    seriesColors={{'Diarios en papel': '#2563eb', 'Diarios en internet': '#93c5fd', 'Revistas en papel': '#a855f7', 'Radio': '#f59e0b', 'Televisión': '#ef4444'}}
    title="Komunikabide bakoitzaren eguneroko audientzia (aldizkariak: beren argitaratze-aldian), 14 urte edo gehiagoko biztanleriaren %"
/>

14 urte edo gehiagoko pertsona bakoitzak, batez beste, {minutos_resumen[0]?.ult_tv} minutu telebista ikusten ditu egunean eta {minutos_resumen[0]?.ult_radio} minutu irrati entzuten. Telebistaren maximoa {urtean(minutos_resumen[0]?.anio_max_tv)} izan zen, {minutos_resumen[0]?.max_tv} minuturekin.

<LineChart
    data={minutos}
    x=anio
    y=minutos_dia
    series=medio
    xFmt='0'
    yFmt='0'
    yAxisTitle="Minutuak pertsonako eta eguneko"
    seriesColors={{'Radio': '#f59e0b', 'Televisión': '#ef4444'}}
    title="Irratiaren eta telebistaren eguneroko minutuak pertsonako"
/>

### Paperean gehien irakurtzen diren egunkariak

Egunkari bakoitzaren eguneroko irakurleak paperean eta erreplika digitalean {urtean(cabeceras[0]?.anio)}, 2009arekin alderatuta. Ez ditu barne hartzen egunkaria bere webgunean irakurtzen dutenak.

<LineChart
    data={cabeceras_serie}
    x=anio
    y=por_1000_hab
    series=cabecera
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Irakurleak 1.000 biztanleko"
    title="Paperezko egunkari nagusien eguneroko irakurleak, 1.000 biztanleko"
/>

<DataTable data={cabeceras} rows=15 search=true>
    <Column id=puesto title="Postua" fmt='0' />
    <Column id=cabecera title="Egunkaria" />
    <Column id=por_1000_hab title="Irakurleak 1.000 biz." fmt='0.0' />
    <Column id=lectores_miles title="Irakurleak (milaka)" fmt='#,##0' />
    <Column id=lectores_miles_ini title="Irakurleak 2009an (milaka)" fmt='#,##0' />
    <Column id=variacion_desde_inicio_pct title="Aldaketa 2009tik %" fmt='0' contentType=delta />
</DataTable>

## Zerez bizi diren: publizitatea

{urtean(pub_resumen[0]?.anio)} iragarleek {formatNumber(pub_resumen[0]?.eur_hab, 0)} € inbertitu zituzten biztanleko komunikabide konbentzionaletan (telebista, prentsa, aldizkariak, irratia, internet, kanpoaldea eta zinema), inflazioa kenduta. Maximoa {urtean(pub_resumen[0]?.anio_max)} izan zen, {formatNumber(pub_resumen[0]?.eur_hab_max, 0)} €-rekin. Paperezko eguneko prentsa 2007ko {formatNumber(pub_prensa[0]?.diarios_2007, 1)} € biztanleko izatetik (inbertsioaren {formatNumber(pub_prensa[0]?.pct_2007, 0)} %) 2023ko {formatNumber(pub_prensa[0]?.diarios_2023, 1)} € izatera igaro da ({formatNumber(pub_prensa[0]?.pct_2023, 0)} %), eta telebista {formatNumber(pub_prensa[0]?.tv_2007, 0)} €-tik {formatNumber(pub_prensa[0]?.tv_2023, 0)} €-ra; bitartean, internet {formatNumber(pub_prensa[0]?.internet_2023, 0)} €-ra iritsi da.

<BarChart
    data={pub_larga}
    x=anio
    y=eur_hab_real
    series=medio
    xFmt='0'
    yFmt='0'
    yAxisTitle="€ biztanleko (inflazioa kenduta)"
    seriesColors={{'Televisión': '#ef4444', 'Diarios (papel)': '#2563eb', 'Internet': '#22c55e', 'Radio': '#f59e0b', 'Revistas': '#a855f7', 'Exterior': '#64748b', 'Dominicales': '#93c5fd', 'Cine': '#0f172a'}}
    title="Publizitate-inbertsioa komunikabide konbentzionaletan euskarrika, € biztanleko inflazioa kenduta (serie luzea, 2004-2023)"
/>

Serie luze honetan «Egunkariak» papera bakarrik da, eta publizitate digital guztia, egunkarien webgunekoa ere bai, «Internet» atalean doa, Google, Meta eta gainerako plataformak barne. 2025eko azterlanetik aurrera, InfoAdexek komunikabide bakoitzari bere zati digitala gehitzen dio eta bilatzaileak, sare sozialak eta beste webgune batzuk bereizten ditu. Irizpide horrekin, {urtean(pub_papel_web[0]?.anio)} egunkariek eta igandekariek {formatNumber(pub_papel_web[0]?.web, 0)} milioi euro jaso zituzten beren webguneetako publizitateagatik eta {formatNumber(pub_papel_web[0]?.papel, 0)} milioi paperean, eta sare sozialek eta bilatzaileek inbertsio osoaren {formatNumber(pub_papel_web[0]?.pct_redes + pub_papel_web[0]?.pct_search, 0)} % eraman zuten.

<BarChart
    data={pub_nueva}
    x=medio
    y=eur_hab_real
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="€ biztanleko"
    title="Publizitate-inbertsioa komunikabideka {urtean(pub_nueva[0]?.anio)}, bakoitza bere zati digitalarekin (€ biztanleko)"
/>

## Zenbat jendek egiten duen lan komunikabideetan

Adar bakoitzeko enpresetan lanean ari diren pertsonak (soldatapekoak eta norberaren kontura ari direnak), enpresen egitura-estatistikaren arabera. {urtean(empleo_ult[0]?.anio)} egunkarien edizioak {formatNumber(empleo_ult[0]?.periodicos, 0)} pertsona enplegatzen zituen, irratiek {formatNumber(empleo_ult[0]?.radio, 0)}, telebistek {formatNumber(empleo_ult[0]?.tv, 0)} eta albiste-agentziek {formatNumber(empleo_ult[0]?.agencias, 0)}. Eurostatek 2016tik bakarrik ematen ditu adar hauek bereizita (metodo-haustura batekin 2021ean).

<LineChart
    data={empleo}
    x=anio
    y=ocupados_100k_hab
    series=rama
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Landunak 100.000 biztanleko"
    seriesColors={{'Periódicos': '#2563eb', 'Revistas': '#a855f7', 'Radio': '#f59e0b', 'Televisión': '#ef4444', 'Agencias de noticias': '#64748b'}}
    title="Komunikabide-enpresetan lanean ari diren pertsonak, 100.000 biztanleko"
/>

2005etik aurrera ikusteko adar zabalagoak erabili behar dira: irratia eta telebista batera, eta edizio osoa (liburuak eta softwarea barne). Irratia eta telebista 2008ko 100.000 biztanleko {formatNumber(j60_extremos[0]?.tv_radio_2008, 0)} landun izatetik {formatNumber(j60_extremos[0]?.tv_radio_ult, 0)} izatera igaro dira.

<LineChart
    data={empleo_largo}
    x=anio
    y=ocupados_100k_hab
    series=rama
    xFmt='0'
    yFmt='0'
    yAxisTitle="Landunak 100.000 biztanleko"
    title="Landunak edizioan eta irratian eta telebistan, 100.000 biztanleko (2005-azkena)"
/>

<LineChart
    data={empleo_largo}
    x=anio
    y=cifra_negocios_eur_hab_real
    series=rama
    xFmt='0'
    yFmt='0'
    yAxisTitle="€ biztanleko (inflazioa kenduta)"
    title="Edizioaren eta irratiaren eta telebistaren negozio-zifra, € biztanleko inflazioa kenduta"
/>

### Europarekin alderatuta

{urtean(ue[0]?.anio)} Espainiak {formatNumber(ue_es[0]?.es, 1)} landun zituen egunkarien edizioan 100.000 biztanleko, eta EBko batez bestekoa {formatNumber(ue_es[0]?.ue, 1)} zen (daturik duten {ue_es[0]?.n} herrialdeetatik {ue_es[0]?.puesto}. postua). Irratian eta telebistan, {formatNumber(ue_es[0]?.es_tv, 1)} Espainian eta {formatNumber(ue_es[0]?.ue_tv, 1)} EBn.

<BarChart
    data={ue}
    x=pais_nombre
    y=periodicos_100k
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="Landunak 100.000 biztanleko"
    seriesColors={{'España': '#dc2626', 'UE-27': '#0f172a', 'Otros países': '#94a3b8'}}
    title="Egunkarien edizioko landunak 100.000 biztanleko, {ue[0]?.anio}"
/>

<DataTable data={ue} rows=27>
    <Column id=pais_nombre title="Herrialdea" />
    <Column id=periodicos_100k title="Egunkariak: landunak 100.000 biz." fmt='0.0' />
    <Column id=periodicos_eur_hab title="Egunkariak: fakturazioa € biz." fmt='0.0' />
    <Column id=radio_tv_100k title="Irratia eta TB: landunak 100.000 biz." fmt='0.0' />
    <Column id=radio_tv_eur_hab title="Irratia eta TB: fakturazioa € biz." fmt='0.0' />
</DataTable>

## Burtsan kotizatzen duen talde handi bat: Atresmedia

Atresmediaren (Antena 3, laSexta, Onda Cero) diru-sarrerak eta mozkin garbia, milioi eurotan, inflazioa kenduta. {urtean(grupos_resumen[0]?.anio_ult)} {formatNumber(grupos_resumen[0]?.ing_ult, 0)} milioi jaso zituen, 2007ko {formatNumber(grupos_resumen[0]?.ing_2007, 0)} milioien aldean; minimoa {urtean(grupos_resumen[0]?.anio_min)} izan zen, {formatNumber(grupos_resumen[0]?.ing_min, 0)} milioirekin.

<BarChart
    data={grupos_series}
    x=anio
    y=meur_real
    series=concepto
    type=grouped
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="Milioi euro (inflazioa kenduta)"
    seriesColors={{'Ingresos': '#2563eb', 'Beneficio neto': '#16a34a'}}
    title="Atresmedia: diru-sarrerak eta mozkin garbia, milioi euro inflazioa kenduta"
/>

## Diru publikoa publizitate-merkatuaren aldean

Diru publikoa negozioaren tamainan kokatzeko, grafikoak Estatuak eta haren enpresek publizitate-kanpainetan gastatzen dutena, eta RTVEk eta irrati-telebista autonomikoek jasotzen dutena, urte horretako komunikabideetako publizitate-inbertsio osoarekin zatitzen ditu. {urtean(publico_ult_age[0]?.anio)} Estatuaren publizitatea komunikabideetako publizitate-inbertsioaren {formatNumber(publico_ult_age[0]?.publicidad_estado_pct_mercado, 1)} %-ren baliokidea izan zen. {urtean(publico_ult[0]?.anio)} irrati-telebisten finantzaketa publikoa inbertsio osoaren {formatNumber(publico_ult[0]?.tv_publica_pct_mercado, 0)} %-ren eta telebistako publizitatearen {formatNumber(publico_ult[0]?.tv_publica_pct_publicidad_tv, 0)} %-ren baliokidea izan zen.

<LineChart
    data={publico_series}
    x=anio
    y=pct
    series=concepto
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="Komunikabideetako publizitate-inbertsioaren %"
    seriesColors={{'Publicidad del Estado y sus empresas': '#2563eb', 'RTVE y radiotelevisiones autonómicas': '#f59e0b'}}
    title="Diru publikoa, komunikabideetako publizitate-inbertsioaren %"
/>

<DataTable data={publico} rows=20>
    <Column id=anio title="Urtea" fmt='0' />
    <Column id=controlados_eur_hab_real title="Publizitate-inbertsioa komunikabideetan, €/biz." fmt='0.0' />
    <Column id=publicidad_estado_eur_hab_real title="Estatuaren publizitatea, €/biz." fmt='0.00' />
    <Column id=tv_publica_eur_hab_real title="RTVE eta autonomikoak, €/biz." fmt='0.0' />
    <Column id=subvenciones_eur_hab_real title="Diru-laguntzak komunikabide pribatuei, €/biz." fmt='0.00' />
    <Column id=contratos_eur_hab_real title="Kontratuak komunikabide pribatuekin, €/biz." fmt='0.00' />
</DataTable>

Ez dute zehazki gauza bera neurtzen: InfoAdexek komunikabideek publizitate-espazioengatik jasotzen dutena kalkulatzen du, deskontuak kenduta; Estatuaren kanpainen kostuak, berriz, sormena, ekoizpena eta, antza denez, BEZa barne hartzen ditu. Irrati-telebista publikoen finantzaketa ez da publizitatea, baina ikus-entzunezko merkatu berean sartzen den dirua da. Autonomikoen finantzaketa 2017tik bakarrik dago, eta falta da erkidegoen eta udalen publizitatea, batzuek baino ez baitute argitaratzen.

## Metodologia eta iturriak

- **Audientziak**: [AIMC, Marco General de los Medios en España 2026](https://www.aimc.es/a1mc-c0nt3nt/uploads/2026/02/Marco_General_Medios_2026.pdf) (Estudio General de Medios-en datuekin doako argitalpena): audientzia orokorraren bilakaera 1980-2025, irrati eta telebistako minutuak 1991-2025 eta egunkariko irakurleak 2009-2025. Penetrazioa 14 urte edo gehiagoko biztanleriaren gainean; 1.000 biztanleko irakurleetara pasatzeko, EGMren unibertsoarekin biderkatzen da eta INEren erroldako biztanleria osoarekin zatitzen. 2017ra arte egunkarien irakurketa papera bakarrik da; 2018tik erreplika digitala ere barne hartzen du.
- **Publizitate-inbertsioa**: [Estudio InfoAdex de la inversión publicitaria en España](https://www.infoadex.es/) azterlanaren laburpen publikoak (2010-2026 edizioak; azterlan osoa ordainpekoa da). Urte bakoitzerako argitaratutako azken berrikuspena erabiltzen da. 2004-2023 serieak irizpide zaharra jarraitzen du (egunkariak = papera; digitala, interneten) eta 2022-2025ekoak berria (komunikabide bakoitza bere webgunearekin); ez dira nahasten. Internet gora birkalkulatu zen 2014tik aurrera, eta kanpoaldea 2018tik aurrera.
- **Enpresak eta enplegua**: Eurostat, enpresen egitura-estatistikak ([sbs_na_1a_se_r2](https://ec.europa.eu/eurostat/databrowser/view/sbs_na_1a_se_r2/default/table) 2020ra arte eta [sbs_ovw_act](https://ec.europa.eu/eurostat/databrowser/view/sbs_ovw_act/default/table) 2021etik), Espainiarako INEk zerbitzu-sektoreko Enpresen Egitura Estatistikarekin egiten dituenak. CNAE adarrak: 58.13 (egunkariak), 58.14 (aldizkariak), 60.1 (irratia), 60.2 (telebista) eta 63.91 (albiste-agentziak). 2021ean metodoa aldatu zen (FRIBS araudia).
- **Atresmedia**: akziodunentzako bere webguneko [Principales magnitudes](https://www.atresmediacorporacion.com/accionistas-inversores/informacion-economico-financiera/principales-magnitudes/) (kontu bateratuak).
- **Diru publikoa**: [Diru publikoa komunikabideetan](/eu/medios/dinero-publico) ataleko mart-ak (Erakunde Publizitate eta Komunikazioaren Batzordea, CNMC, RTVEren kontuak, BDNS eta Kontratazio Plataforma).
- **Euro konstanteak** INEren KPIarekin eta **biztanleria** erroldakoa.
