---
title: O negocio dos medios
description: "Canto se len, se ven e se escoitan os medios en España, de que viven (o investimento publicitario por soporte) e canta xente traballa neles, por habitante e descontada a inflación, comparado coa UE e co diñeiro público que reciben."
i18n_origen: e0531df8ebcc
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

# <span aria-hidden="true">📈</span> O negocio dos medios

Canto se len, se ven e se escoitan os medios en España, de que viven e canta xente traballa neles. As audiencias son do Estudo Xeral de Medios, a publicidade do Estudo InfoAdex e o emprego e a facturación da estatística de empresas do INE e Eurostat. Todas as cifras van **por habitante e descontada a inflación**, en euros de {pub_resumen[0]?.anio_base}. O que lles pagan as administracións aos medios está en [Diñeiro público nos medios](/gl/medios/dinero-publico).

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    {#if papel_resumen.length && pub_resumen.length && empleo_ult.length && publico_ult_age.length}
    <KpiCard
        title="Lectores de diarios en papel"
        value={papel_resumen[0].por_1000}
        formattedValue={formatNumber(papel_resumen[0].por_1000, 0)}
        unit="por 1.000 habitantes"
        period={`${papel_resumen[0].anio} · ${formatNumber(papel_resumen[0].miles / 1000, 1)} millóns de lectores ao día`}
        source="AIMC (EGM)"
        direction="positive-up"
        sparklineData={papel.filter(d => d.por_1000_hab !== null).map(d => d.por_1000_hab)}
    />
    <KpiCard
        title="Investimento publicitario en medios"
        value={pub_resumen[0].eur_hab}
        formattedValue={formatNumber(pub_resumen[0].eur_hab, 0) + ' €'}
        unit="por habitante"
        period={`${pub_resumen[0].anio} · ${formatCompact(pub_resumen[0].meur * 1e6, 2)} € en televisión, prensa, radio, dixital, exterior e cine`}
        source="InfoAdex"
        direction="positive-up"
        sparklineData={pub_mercado.map(d => d.eur_hab_real)}
    />
    <KpiCard
        title="Emprego na edición de xornais"
        value={empleo_ult[0].periodicos_100k}
        formattedValue={formatNumber(empleo_ult[0].periodicos_100k, 1)}
        unit="ocupados por 100.000 habitantes"
        period={`${empleo_ult[0].anio} · ${formatNumber(empleo_ult[0].periodicos, 0)} persoas en ${formatNumber(empleo_ult[0].periodicos_empresas, 0)} empresas`}
        source="INE e Eurostat (SBS)"
        direction="positive-up"
        sparklineData={empleo_spark.map(d => d.ocupados_100k_hab)}
    />
    <KpiCard
        title="Publicidade do Estado fronte ao mercado"
        value={publico_ult_age[0].publicidad_estado_pct_mercado}
        formattedValue={formatNumber(publico_ult_age[0].publicidad_estado_pct_mercado, 1) + ' %'}
        unit="do investimento en medios"
        period={`${publico_ult_age[0].anio} · ${formatCompact(publico_ult_age[0].publicidad_estado_meur * 1e6, 2)} € en campañas do Estado e as súas empresas`}
        source="Moncloa e InfoAdex"
        direction="positive-down"
        sparklineData={publico.map(d => d.publicidad_estado_pct_mercado)}
    />
    {/if}
</div>

## Canto se le, se ve e se escoita

En {papel_resumen[0]?.anio} lían un diario en papel cada día {formatNumber(papel_resumen[0]?.por_1000, 0)} de cada 1.000 habitantes, o {formatNumber(papel_resumen[0]?.pct, 1)} % dos maiores de 14 anos. O máximo da serie foi en {papel_resumen[0]?.anio_pct_max}, co {formatNumber(papel_resumen[0]?.pct_max, 1)} %. Ata 2017 o EGM conta só o papel; desde 2018 suma a quen le a réplica dixital (PDF ou visor) do xornal.

<LineChart
    data={papel}
    x=anio
    y=por_1000_hab
    xFmt='0'
    yFmt='0'
    yAxisTitle="Lectores por 1.000 habitantes"
    title="Lectores diarios de xornais en papel, por cada 1.000 habitantes"
/>

A lectura non desapareceu: foise á web. En {audiencia_ult[0]?.anio} o {formatNumber(audiencia_ult[0]?.internet, 1)} % dos maiores de 14 anos entraba cada día na web dalgún diario, fronte ao {formatNumber(audiencia_ult[0]?.papel, 1)} % que o lía en papel; sumando as dúas formas, o {formatNumber(audiencia_ult[0]?.diarios_total, 1)} %. A televisión chega ao {formatNumber(audiencia_ult[0]?.tv, 1)} % da poboación cada día e a radio ao {formatNumber(audiencia_ult[0]?.radio, 1)} %.

<LineChart
    data={audiencia}
    x=anio
    y=penetracion_pct
    series=medio
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% da poboación de 14 ou máis anos"
    seriesColors={{'Diarios en papel': '#2563eb', 'Diarios en internet': '#93c5fd', 'Revistas en papel': '#a855f7', 'Radio': '#f59e0b', 'Televisión': '#ef4444'}}
    title="Audiencia diaria de cada medio (revistas: no seu período de publicación), % da poboación de 14 ou máis anos"
/>

Cada persoa de 14 anos ou máis ve de media {minutos_resumen[0]?.ult_tv} minutos de televisión ao día e escoita {minutos_resumen[0]?.ult_radio} minutos de radio. O máximo da televisión foi en {minutos_resumen[0]?.anio_max_tv}, con {minutos_resumen[0]?.max_tv} minutos.

<LineChart
    data={minutos}
    x=anio
    y=minutos_dia
    series=medio
    xFmt='0'
    yFmt='0'
    yAxisTitle="Minutos por persoa e día"
    seriesColors={{'Radio': '#f59e0b', 'Televisión': '#ef4444'}}
    title="Minutos diarios de radio e televisión por persoa"
/>

### Os diarios máis lidos en papel

Lectores diarios de cada xornal en papel e réplica dixital en {cabeceras[0]?.anio}, comparados con 2009. Non inclúe a quen le o xornal na súa web.

<LineChart
    data={cabeceras_serie}
    x=anio
    y=por_1000_hab
    series=cabecera
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Lectores por 1.000 habitantes"
    title="Lectores diarios dos principais xornais en papel, por 1.000 habitantes"
/>

<DataTable data={cabeceras} rows=15 search=true>
    <Column id=puesto title="Posto" fmt='0' />
    <Column id=cabecera title="Diario" />
    <Column id=por_1000_hab title="Lectores por 1.000 hab." fmt='0.0' />
    <Column id=lectores_miles title="Lectores (miles)" fmt='#,##0' />
    <Column id=lectores_miles_ini title="Lectores en 2009 (miles)" fmt='#,##0' />
    <Column id=variacion_desde_inicio_pct title="Variación desde 2009 %" fmt='0' contentType=delta />
</DataTable>

## De que viven: a publicidade

En {pub_resumen[0]?.anio} os anunciantes investiron {formatNumber(pub_resumen[0]?.eur_hab, 0)} € por habitante nos medios convencionais (televisión, prensa, revistas, radio, internet, exterior e cine), descontada a inflación. O máximo foi en {pub_resumen[0]?.anio_max}, con {formatNumber(pub_resumen[0]?.eur_hab_max, 0)} €. A prensa diaria en papel pasou de {formatNumber(pub_prensa[0]?.diarios_2007, 1)} € por habitante en 2007 ({formatNumber(pub_prensa[0]?.pct_2007, 0)} % do investimento) a {formatNumber(pub_prensa[0]?.diarios_2023, 1)} € en 2023 ({formatNumber(pub_prensa[0]?.pct_2023, 0)} %), e a televisión de {formatNumber(pub_prensa[0]?.tv_2007, 0)} € a {formatNumber(pub_prensa[0]?.tv_2023, 0)} €, mentres internet chegaba a {formatNumber(pub_prensa[0]?.internet_2023, 0)} €.

<BarChart
    data={pub_larga}
    x=anio
    y=eur_hab_real
    series=medio
    xFmt='0'
    yFmt='0'
    yAxisTitle="€ por habitante (descontada a inflación)"
    seriesColors={{'Televisión': '#ef4444', 'Diarios (papel)': '#2563eb', 'Internet': '#22c55e', 'Radio': '#f59e0b', 'Revistas': '#a855f7', 'Exterior': '#64748b', 'Dominicales': '#93c5fd', 'Cine': '#0f172a'}}
    title="Investimento publicitario en medios convencionais por soporte, € por habitante descontada a inflación (serie longa, 2004-2023)"
/>

Nesta serie longa «Diarios» é só o papel e toda a publicidade dixital, tamén a das webs dos xornais, vai en «Internet», que inclúe Google, Meta e demais plataformas. Desde o estudo de 2025, InfoAdex súmalle a cada medio a súa parte dixital e separa buscadores, redes sociais e outras webs. Con ese criterio, en {pub_papel_web[0]?.anio} os diarios e dominicais ingresaron {formatNumber(pub_papel_web[0]?.web, 0)} millóns de euros por publicidade nas súas webs e {formatNumber(pub_papel_web[0]?.papel, 0)} millóns en papel, e as redes sociais e os buscadores leváronse o {formatNumber(pub_papel_web[0]?.pct_redes + pub_papel_web[0]?.pct_search, 0)} % de todo o investimento.

<BarChart
    data={pub_nueva}
    x=medio
    y=eur_hab_real
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="€ por habitante"
    title="Investimento publicitario por medio en {pub_nueva[0]?.anio}, cada medio coa súa parte dixital (€ por habitante)"
/>

## Canta xente traballa nos medios

Persoas ocupadas (asalariadas e por conta propia) nas empresas de cada rama segundo a estatística estrutural de empresas. En {empleo_ult[0]?.anio} a edición de xornais ocupaba {formatNumber(empleo_ult[0]?.periodicos, 0)} persoas, as radios {formatNumber(empleo_ult[0]?.radio, 0)}, as televisións {formatNumber(empleo_ult[0]?.tv, 0)} e as axencias de noticias {formatNumber(empleo_ult[0]?.agencias, 0)}. Eurostat só dá estas ramas por separado desde 2016 (cunha ruptura de método en 2021).

<LineChart
    data={empleo}
    x=anio
    y=ocupados_100k_hab
    series=rama
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Ocupados por 100.000 habitantes"
    seriesColors={{'Periódicos': '#2563eb', 'Revistas': '#a855f7', 'Radio': '#f59e0b', 'Televisión': '#ef4444', 'Agencias de noticias': '#64748b'}}
    title="Persoas ocupadas nas empresas de medios, por 100.000 habitantes"
/>

Para ver desde 2005 hai que usar ramas máis amplas: radio e televisión xuntas, e toda a edición (que inclúe libros e software). Radio e televisión pasaron de {formatNumber(j60_extremos[0]?.tv_radio_2008, 0)} ocupados por 100.000 habitantes en 2008 a {formatNumber(j60_extremos[0]?.tv_radio_ult, 0)}.

<LineChart
    data={empleo_largo}
    x=anio
    y=ocupados_100k_hab
    series=rama
    xFmt='0'
    yFmt='0'
    yAxisTitle="Ocupados por 100.000 habitantes"
    title="Ocupados en edición e en radio e televisión, por 100.000 habitantes (2005-último)"
/>

<LineChart
    data={empleo_largo}
    x=anio
    y=cifra_negocios_eur_hab_real
    series=rama
    xFmt='0'
    yFmt='0'
    yAxisTitle="€ por habitante (descontada a inflación)"
    title="Cifra de negocios da edición e da radio e televisión, € por habitante descontada a inflación"
/>

### Comparado con Europa

En {ue[0]?.anio} España tiña {formatNumber(ue_es[0]?.es, 1)} ocupados na edición de xornais por cada 100.000 habitantes, fronte a {formatNumber(ue_es[0]?.ue, 1)} de media na UE (posto {ue_es[0]?.puesto} de {ue_es[0]?.n} países con dato). En radio e televisión, {formatNumber(ue_es[0]?.es_tv, 1)} fronte a {formatNumber(ue_es[0]?.ue_tv, 1)}.

<BarChart
    data={ue}
    x=pais_nombre
    y=periodicos_100k
    series=grupo
    swapXY=true
    sort=false
    yFmt='0.0'
    yAxisTitle="Ocupados por 100.000 habitantes"
    seriesColors={{'España': '#dc2626', 'UE-27': '#0f172a', 'Otros países': '#94a3b8'}}
    title="Ocupados na edición de xornais por 100.000 habitantes, {ue[0]?.anio}"
/>

<DataTable data={ue} rows=27>
    <Column id=pais_nombre title="País" />
    <Column id=periodicos_100k title="Xornais: ocupados por 100.000 hab." fmt='0.0' />
    <Column id=periodicos_eur_hab title="Xornais: facturación € por hab." fmt='0.0' />
    <Column id=radio_tv_100k title="Radio e TV: ocupados por 100.000 hab." fmt='0.0' />
    <Column id=radio_tv_eur_hab title="Radio e TV: facturación € por hab." fmt='0.0' />
</DataTable>

## Un gran grupo cotizado: Atresmedia

Ingresos e beneficio neto de Atresmedia (Antena 3, laSexta, Onda Cero), en millóns de euros descontada a inflación. En {grupos_resumen[0]?.anio_ult} ingresou {formatNumber(grupos_resumen[0]?.ing_ult, 0)} millóns, fronte a {formatNumber(grupos_resumen[0]?.ing_2007, 0)} millóns de 2007; o mínimo foi en {grupos_resumen[0]?.anio_min}, con {formatNumber(grupos_resumen[0]?.ing_min, 0)} millóns.

<BarChart
    data={grupos_series}
    x=anio
    y=meur_real
    series=concepto
    type=grouped
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="Millóns de euros (descontada a inflación)"
    seriesColors={{'Ingresos': '#2563eb', 'Beneficio neto': '#16a34a'}}
    title="Atresmedia: ingresos e beneficio neto, millóns de euros descontada a inflación"
/>

## O diñeiro público fronte ao mercado publicitario

Para situar o diñeiro público no tamaño do negocio, o gráfico divide o que gastan o Estado e as súas empresas en campañas de publicidade, e o que reciben RTVE e as radiotelevisións autonómicas, entre o investimento publicitario total en medios dese ano. En {publico_ult_age[0]?.anio} a publicidade do Estado equivaleu ao {formatNumber(publico_ult_age[0]?.publicidad_estado_pct_mercado, 1)} % do investimento publicitario en medios. En {publico_ult[0]?.anio} o financiamento público das radiotelevisións equivaleu ao {formatNumber(publico_ult[0]?.tv_publica_pct_mercado, 0)} % de todo ese investimento e ao {formatNumber(publico_ult[0]?.tv_publica_pct_publicidad_tv, 0)} % da publicidade en televisión.

<LineChart
    data={publico_series}
    x=anio
    y=pct
    series=concepto
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% do investimento publicitario en medios"
    seriesColors={{'Publicidad del Estado y sus empresas': '#2563eb', 'RTVE y radiotelevisiones autonómicas': '#f59e0b'}}
    title="Diñeiro público en % do investimento publicitario en medios"
/>

<DataTable data={publico} rows=20>
    <Column id=anio title="Ano" fmt='0' />
    <Column id=controlados_eur_hab_real title="Investimento publicitario en medios, €/hab." fmt='0.0' />
    <Column id=publicidad_estado_eur_hab_real title="Publicidade do Estado, €/hab." fmt='0.00' />
    <Column id=tv_publica_eur_hab_real title="RTVE e autonómicas, €/hab." fmt='0.0' />
    <Column id=subvenciones_eur_hab_real title="Subvencións a medios privados, €/hab." fmt='0.00' />
    <Column id=contratos_eur_hab_real title="Contratos con medios privados, €/hab." fmt='0.00' />
</DataTable>

Son magnitudes que non miden exactamente o mesmo: InfoAdex estima o que reciben os medios polos espazos publicitarios, neto de descontos, mentres que o custo das campañas do Estado inclúe a creatividade, a produción e, segundo parece, o IVE. O financiamento das radiotelevisións públicas non é publicidade, pero é diñeiro que entra no mesmo mercado audiovisual. O financiamento das autonómicas só está desde 2017 e falta a publicidade de comunidades e concellos, que só publican algúns.

## Metodoloxía e fontes

- **Audiencias**: [AIMC, Marco General de los Medios en España 2026](https://www.aimc.es/a1mc-c0nt3nt/uploads/2026/02/Marco_General_Medios_2026.pdf) (publicación gratuíta con datos do Estudo Xeral de Medios): evolución da audiencia xeral 1980-2025, minutos de radio e televisión 1991-2025 e lectores por diario 2009-2025. Penetración sobre a poboación de 14 ou máis anos; para pasar a lectores por 1.000 habitantes multiplícase polo universo do EGM e divídese por toda a poboación do padrón do INE. Ata 2017 a lectura de diarios é só papel; desde 2018 inclúe a réplica dixital.
- **Investimento publicitario**: resumos públicos do [Estudo InfoAdex do investimento publicitario en España](https://www.infoadex.es/) (edicións 2010-2026; o estudo completo é de pagamento). Para cada ano úsase a última revisión publicada. A serie 2004-2023 segue o criterio antigo (diarios = papel; o dixital, en internet) e a de 2022-2025 o novo (cada medio coa súa web); non se mesturan. Internet reestimouse á alza desde 2014 e exterior desde 2018.
- **Empresas e emprego**: Eurostat, estatísticas estruturais de empresas ([sbs_na_1a_se_r2](https://ec.europa.eu/eurostat/databrowser/view/sbs_na_1a_se_r2/default/table) ata 2020 e [sbs_ovw_act](https://ec.europa.eu/eurostat/databrowser/view/sbs_ovw_act/default/table) desde 2021), que para España elabora o INE coa Estatística Estrutural de Empresas do sector servizos. Ramas CNAE 58.13 (xornais), 58.14 (revistas), 60.1 (radio), 60.2 (televisión) e 63.91 (axencias de noticias). En 2021 cambiou o método (regulamento FRIBS).
- **Atresmedia**: [Principales magnitudes](https://www.atresmediacorporacion.com/accionistas-inversores/informacion-economico-financiera/principales-magnitudes/) da súa web de accionistas (contas consolidadas).
- **Diñeiro público**: marts da sección [Diñeiro público nos medios](/gl/medios/dinero-publico) (Comisión de Publicidade e Comunicación Institucional, CNMC, contas de RTVE, BDNS e Plataforma de Contratación).
- **Euros constantes** co IPC do INE e **poboación** do padrón.
