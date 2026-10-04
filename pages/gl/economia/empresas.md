---
i18n_origen: c23d9e81ee16
title: Empresas, emprendemento e I+D
description: "Cantas empresas hai en España por habitante e de que tamaño, cantas sociedades se crean e se disolven, os concursos de acredores, os autónomos e o gasto en I+D comparado con Europa e por comunidade."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql emp_pais
SELECT CAST(anio AS INTEGER) AS anio, empresas, empresas_1000hab, pct_personas_fisicas, crecimiento_pct
FROM mother.empresas_dirce_territorio
WHERE nivel = 'pais'
ORDER BY anio
```

```sql emp_hitos
SELECT
    max(empresas_1000hab) FILTER (WHERE anio = 2008) AS e2008,
    max(anio) AS anio_ult,
    max(empresas_1000hab) FILTER (WHERE anio = (SELECT max(anio) FROM mother.empresas_dirce_territorio)) AS e_ult,
    max(empresas_1000hab) FILTER (WHERE anio = (SELECT max(anio) FROM mother.empresas_dirce_territorio) - 1) AS e_ant,
    max(empresas) FILTER (WHERE anio = (SELECT max(anio) FROM mother.empresas_dirce_territorio)) AS empresas_ult
FROM mother.empresas_dirce_territorio
WHERE nivel = 'pais'
```

```sql soc_12m
SELECT fecha, constituidas_12m_100k, disueltas_12m_100k, constituidas_12m, disueltas_12m,
    CAST(anio AS INTEGER) AS anio, CAST(mes AS INTEGER) AS mes
FROM mother.empresas_sociedades_mensual
WHERE cod = '00' AND constituidas_12m_100k IS NOT NULL
ORDER BY fecha
```

```sql soc_12m_ult
SELECT
    s.*,
    strftime(s.fecha, '%m/%Y') AS mes_texto,
    100 * (s.constituidas_12m / a.constituidas_12m - 1) AS cambio_anual
FROM ${soc_12m} s
LEFT JOIN ${soc_12m} a ON a.fecha = s.fecha - INTERVAL 1 YEAR
ORDER BY s.fecha DESC
LIMIT 1
```

```sql autonomos_pais
SELECT periodo, CAST(anio AS INTEGER) AS anio, trimestre, fecha, ocupados, cuenta_propia, empleadores, independientes,
    pct_cuenta_propia, pct_empleadores, pct_independientes
FROM mother.empresas_autonomos
WHERE cod = '00'
ORDER BY fecha
```

```sql autonomos_anual
SELECT CAST(anio AS INTEGER) AS anio, ocupados, cuenta_propia, empleadores, independientes,
    pct_cuenta_propia, pct_empleadores, pct_independientes
FROM mother.empresas_autonomos_anual
WHERE cod = '00'
ORDER BY anio
```

```sql autonomos_ult
SELECT * FROM ${autonomos_pais} ORDER BY fecha DESC LIMIT 1
```

```sql id_es
SELECT CAST(anio AS INTEGER) AS anio, pct_pib, eur_hab_real, investigadores_1000ocup, CAST(anio_euros AS INTEGER) AS anio_euros
FROM mother.empresas_id_paises
WHERE geo = 'ES' AND sector = 'Total' AND pct_pib IS NOT NULL
ORDER BY anio
```

```sql id_ue_ult
SELECT
    e.anio,
    e.pct_pib AS es,
    u.pct_pib AS ue,
    e.eur_hab_real AS es_hab,
    u.eur_hab_real AS ue_hab,
    e.investigadores_1000ocup AS es_inv,
    u.investigadores_1000ocup AS ue_inv
FROM mother.empresas_id_paises e
JOIN mother.empresas_id_paises u ON u.geo = 'EU27_2020' AND u.anio = e.anio AND u.sector = 'Total'
WHERE e.geo = 'ES' AND e.sector = 'Total' AND e.pct_pib IS NOT NULL AND u.pct_pib IS NOT NULL
ORDER BY e.anio DESC
LIMIT 1
```

# 🏭 Empresas, emprendemento e I+D

Cantas empresas hai en España e de que tamaño son, cantas sociedades se crean e cantas pechan, cantos traballadores son autónomos e canto se inviste en investigación e desenvolvemento (I+D) comparado con Europa. As cifras dánse por habitante, en porcentaxe ou, se son euros, descontada a inflación.

<Grid cols=4>
    <KpiCard
        title="Empresas por 1.000 habitantes"
        value={emp_hitos[0]?.e_ult}
        formattedValue={formatNumber(emp_hitos[0]?.e_ult, 1)}
        period="activas a 1 de xaneiro de {emp_hitos[0]?.anio_ult} · {formatCompact(emp_hitos[0]?.empresas_ult, 2)} empresas, incluídos autónomos"
        change={(emp_hitos[0]?.e_ult - emp_hitos[0]?.e_ant)?.toFixed(1)}
        changeUnit=""
        changePeriod="vs. ano anterior"
        direction="positive-up"
        source="INE / DIRCE"
        sparklineData={emp_pais.map(d => d.empresas_1000hab)}
    />
    <KpiCard
        title="Sociedades creadas"
        value={soc_12m_ult[0]?.constituidas_12m_100k}
        formattedValue="{formatNumber(soc_12m_ult[0]?.constituidas_12m_100k, 0)} por 100.000 hab."
        period="nos 12 meses ata {soc_12m_ult[0]?.mes_texto} · {formatNumber(soc_12m_ult[0]?.constituidas_12m, 0)} sociedades mercantís"
        change={soc_12m_ult[0]?.cambio_anual?.toFixed(1)}
        changePeriod="vs. 12 meses antes"
        direction="positive-up"
        source="INE / Sociedades Mercantiles"
        sparklineData={soc_12m.slice(-120).map(d => d.constituidas_12m_100k)}
    />
    <KpiCard
        title="Autónomos"
        value={autonomos_ult[0]?.pct_cuenta_propia}
        formattedValue="{formatNumber(autonomos_ult[0]?.pct_cuenta_propia, 1)} % dos ocupados"
        period="traballan por conta propia ({autonomos_ult[0]?.periodo}) · {formatNumber(autonomos_ult[0]?.cuenta_propia / 1000, 2)} millóns de persoas"
        direction="neutral"
        source="INE / EPA"
        sparklineData={autonomos_anual.map(d => d.pct_cuenta_propia)}
    />
    <KpiCard
        title="Gasto en I+D"
        value={id_ue_ult[0]?.es}
        formattedValue="{formatNumber(id_ue_ult[0]?.es, 2)} % do PIB"
        period="en {id_ue_ult[0]?.anio} · UE-27: {formatNumber(id_ue_ult[0]?.ue, 2)} % · {formatNumber(id_ue_ult[0]?.es_hab, 0)} € por habitante (euros de {id_es.slice(-1)[0]?.anio_euros})"
        direction="positive-up"
        source="Eurostat / INE"
        sparklineData={id_es.map(d => d.pct_pib)}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('id_pib')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'id_pib')} />


## Cantas empresas hai

```sql emp_ccaa
SELECT
    t.nombre AS comunidad,
    '/gl' || t.ruta AS ruta,
    e.cod,
    e.empresas,
    e.empresas_1000hab,
    e.pct_personas_fisicas,
    100 * e.empresas_1000hab / es.empresas_1000hab AS indice_espana,
    CAST(e.anio AS INTEGER) AS anio
FROM mother.empresas_dirce_territorio e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
JOIN mother.empresas_dirce_territorio es ON es.nivel = 'pais' AND es.anio = e.anio
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.empresas_dirce_territorio)
ORDER BY e.empresas_1000hab DESC
```

O Directorio Central de Empresas do INE conta a 1 de xaneiro todas as empresas activas, incluídos os autónomos, agás as do campo e a pesca, as administracións e o servizo doméstico. En {emp_hitos[0]?.anio_ult} había {formatNumber(emp_hitos[0]?.e_ult, 1)} por cada 1.000 habitantes, fronte a {formatNumber(emp_hitos[0]?.e2008, 1)} en 2008. En 2023 o INE pasou a contar só as empresas economicamente activas: a caída dese ano é un cambio de criterio (en termos homoxéneos o número de empresas medrou un 0,5 % segundo o INE).

<LineChart
    data={emp_pais}
    x=anio
    y=empresas_1000hab
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="empresas por 1.000 hab."
    startingAtZero={false}
    title="Empresas activas por 1.000 habitantes"
/>

<BarChart
    data={emp_pais}
    x=anio
    y=pct_personas_fisicas
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% das empresas"
    title="Empresas que son persoas físicas (autónomos con actividade empresarial), % do total"
/>

Por comunidade, {emp_ccaa[0]?.comunidad} ten a maior densidade empresarial, con {formatNumber(emp_ccaa[0]?.empresas_1000hab, 1)} empresas por 1.000 habitantes, e {emp_ccaa.slice(-1)[0]?.comunidad} a menor, con {formatNumber(emp_ccaa.slice(-1)[0]?.empresas_1000hab, 1)}. As empresas cóntanse na comunidade da súa sede, non onde teñen os seus establecementos.

<MapaEspana
    data={emp_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="empresas_1000hab"
    valueFmt='0.0'
    link="ruta"
    colorPalette={['#eff6ff', '#60a5fa', '#1e3a8a']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'empresas_1000hab', title: 'Empresas por 1.000 hab.', fmt: '0.0'},
        {id: 'empresas', title: 'Empresas', fmt: '#,##0'}
    ]}
/>

## Tamaño: case todas son moi pequenas

```sql tamano_es
SELECT tamano, orden, empresas, pct, CAST(anio AS INTEGER) AS anio
FROM mother.empresas_dirce_tamano
WHERE cod = '00' AND anio = (SELECT max(anio) FROM mother.empresas_dirce_tamano)
ORDER BY orden
```

```sql tamano_resumen
SELECT
    max(pct) FILTER (WHERE tamano = 'Sin asalariados') AS sin_asal,
    sum(pct) FILTER (WHERE orden <= 2) AS hasta_9,
    sum(pct) FILTER (WHERE orden >= 4) AS medianas_grandes,
    max(empresas) FILTER (WHERE tamano = 'Grandes (250 o más)') AS grandes,
    max(anio) AS anio
FROM ${tamano_es}
```

En {tamano_resumen[0]?.anio}, o {formatNumber(tamano_resumen[0]?.sin_asal, 1)} % das empresas non tiña ningún asalariado e o {formatNumber(tamano_resumen[0]?.hasta_9, 1)} % tiña menos de 10. Só o {formatNumber(tamano_resumen[0]?.medianas_grandes, 2)} % tiña 50 asalariados ou máis; as grandes, con 250 ou máis, eran {formatNumber(tamano_resumen[0]?.grandes, 0)}.

<BarChart
    data={tamano_es}
    x=tamano
    y=pct
    sort=false
    swapXY=true
    yFmt='0.00"%"'
    title="Empresas por número de asalariados, % do total ({tamano_es[0]?.anio})"
/>

```sql tamano_ue
SELECT cod_pais, pais, tamano, orden, pct_empresas, pct_empleo, pct_vab, CAST(anio AS INTEGER) AS anio
FROM mother.empresas_tamano_ue
WHERE anio = (SELECT max(anio) FROM mother.empresas_tamano_ue WHERE cod_pais = 'EU27_2020' AND pct_vab IS NOT NULL)
  AND cod_pais IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT')
ORDER BY orden, pais
```

```sql tamano_ue_resumen
SELECT
    max(pct_empleo) FILTER (WHERE cod_pais = 'ES' AND orden = 1) AS es_micro,
    max(pct_empleo) FILTER (WHERE cod_pais = 'EU27_2020' AND orden = 1) AS ue_micro,
    max(pct_empleo) FILTER (WHERE cod_pais = 'ES' AND orden = 4) AS es_grandes,
    max(pct_empleo) FILTER (WHERE cod_pais = 'EU27_2020' AND orden = 4) AS ue_grandes,
    max(pct_empleo) FILTER (WHERE cod_pais = 'DE' AND orden = 4) AS de_grandes,
    max(anio) AS anio
FROM ${tamano_ue}
```

Para comparar con Europa, Eurostat mide o tamaño por persoas ocupadas (incluídos os donos) e deixa fóra as finanzas. En {tamano_ue_resumen[0]?.anio}, as microempresas (menos de 10 ocupados) daban o {formatNumber(tamano_ue_resumen[0]?.es_micro, 1)} % do emprego empresarial en España fronte ao {formatNumber(tamano_ue_resumen[0]?.ue_micro, 1)} % na UE-27; as grandes, o {formatNumber(tamano_ue_resumen[0]?.es_grandes, 1)} % fronte ao {formatNumber(tamano_ue_resumen[0]?.ue_grandes, 1)} % (en Alemaña, o {formatNumber(tamano_ue_resumen[0]?.de_grandes, 1)} %).

<BarChart
    data={tamano_ue}
    x=pais
    y=pct_empleo
    series=tamano
    type=stacked
    swapXY=true
    yFmt='0.0"%"'
    colorPalette={['#bfdbfe', '#60a5fa', '#2563eb', '#1e3a8a']}
    title="Repartición do emprego empresarial por tamaño de empresa ({tamano_ue[0]?.anio})"
/>

<BarChart
    data={tamano_ue}
    x=pais
    y=pct_vab
    series=tamano
    type=stacked
    swapXY=true
    yFmt='0.0"%"'
    colorPalette={['#bfdbfe', '#60a5fa', '#2563eb', '#1e3a8a']}
    title="Repartición do valor engadido por tamaño de empresa ({tamano_ue[0]?.anio})"
/>

## A que se dedican

```sql sector_es
SELECT sector, empresas, pct, por_1000_hab, CAST(anio AS INTEGER) AS anio
FROM mother.empresas_dirce_sector
WHERE cod = '00' AND anio = (SELECT max(anio) FROM mother.empresas_dirce_sector)
ORDER BY pct DESC
```

Empresas activas por gran sector en {sector_es[0]?.anio}. {sector_es[0]?.sector} é o sector con máis empresas: {formatNumber(sector_es[0]?.pct, 1)} % do total, {formatNumber(sector_es[0]?.por_1000hab, 1)} por 1.000 habitantes.

<BarChart
    data={sector_es}
    x=sector
    y=por_1000_hab
    swapXY=true
    yFmt='0.0'
    title="Empresas por 1.000 habitantes segundo a súa actividade ({sector_es[0]?.anio})"
/>

## Sociedades que se crean e se disolven

```sql soc_largo
SELECT fecha, 'Creadas' AS tipo, constituidas_12m_100k AS valor FROM ${soc_12m}
UNION ALL
SELECT fecha, 'Disueltas' AS tipo, disueltas_12m_100k AS valor FROM ${soc_12m}
ORDER BY fecha, tipo
```

```sql soc_anual
SELECT CAST(anio AS INTEGER) AS anio, constituidas, disueltas, constituidas_100k, disueltas_100k, saldo_100k,
    ratio_disueltas, capital_real, capital_medio_real, capital_real_hab, CAST(anio_euros AS INTEGER) AS anio_euros
FROM mother.empresas_sociedades_anual
WHERE cod = '00'
ORDER BY anio
```

```sql soc_hitos
SELECT
    max(constituidas_100k) FILTER (WHERE anio = 2006) AS c2006,
    max(constituidas_100k) FILTER (WHERE anio = 2009) AS c2009,
    max(constituidas_100k) FILTER (WHERE anio = (SELECT max(anio) FROM ${soc_anual})) AS c_ult,
    max(disueltas_100k) FILTER (WHERE anio = (SELECT max(anio) FROM ${soc_anual})) AS d_ult,
    max(ratio_disueltas) FILTER (WHERE anio = (SELECT max(anio) FROM ${soc_anual})) AS ratio_ult,
    max(capital_medio_real) FILTER (WHERE anio = (SELECT max(anio) FROM ${soc_anual})) AS cap_medio_ult,
    max(capital_medio_real) FILTER (WHERE anio = 2006) AS cap_medio_2006,
    max(anio) AS anio_ult
FROM ${soc_anual}
```

Sociedades mercantís (sobre todo limitadas e anónimas) inscritas e disoltas no Rexistro Mercantil, sumando os 12 meses anteriores e por cada 100.000 habitantes. En {soc_hitos[0]?.anio_ult} creáronse {formatNumber(soc_hitos[0]?.c_ult, 0)} por 100.000 habitantes, fronte a {formatNumber(soc_hitos[0]?.c2006, 0)} en 2006 e {formatNumber(soc_hitos[0]?.c2009, 0)} en 2009; disolvéronse {formatNumber(soc_hitos[0]?.d_ult, 0)} por 100.000, é dicir, {formatNumber(soc_hitos[0]?.ratio_ult, 0)} por cada 100 creadas. Os autónomos non aparecen aquí.

<LineChart
    data={soc_largo}
    x=fecha
    y=valor
    series=tipo
    yFmt='0'
    yAxisTitle="por 100.000 hab. (12 meses)"
    colorPalette={['#2563eb', '#dc2626']}
    title="Sociedades mercantís creadas e disoltas nos últimos 12 meses, por 100.000 habitantes"
/>

O capital co que nacen as sociedades, descontada a inflación, baixou: o capital medio subscrito foi de {formatNumber(soc_hitos[0]?.cap_medio_ult, 0)} € en {soc_hitos[0]?.anio_ult}, fronte a {formatNumber(soc_hitos[0]?.cap_medio_2006, 0)} € en 2006 (euros de {soc_anual.slice(-1)[0]?.anio_euros}). É unha media: unhas poucas sociedades con moito capital pesan moito nela.

<LineChart
    data={soc_anual.filter(d => d.capital_real_hab != null)}
    x=anio
    y=capital_real_hab
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ por habitante"
    title="Capital subscrito polas novas sociedades, euros de {soc_anual.slice(-1)[0]?.anio_euros} por habitante"
/>

```sql soc_ccaa
SELECT
    t.nombre AS comunidad,
    '/gl' || t.ruta AS ruta,
    s.cod,
    s.constituidas_100k,
    s.disueltas_100k,
    s.saldo_100k,
    s.capital_real_hab,
    CAST(s.anio AS INTEGER) AS anio
FROM mother.empresas_sociedades_anual s
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = s.cod
WHERE s.anio = (SELECT max(anio) FROM mother.empresas_sociedades_anual)
ORDER BY s.constituidas_100k DESC
```

Por comunidade, en {soc_ccaa[0]?.anio}. Cada sociedade cóntase na comunidade do seu domicilio social.

<DataTable data={soc_ccaa} rows=20 link=ruta>
    <Column id=comunidad title="Comunidade"/>
    <Column id=constituidas_100k title="Creadas por 100.000 hab." fmt='0'/>
    <Column id=disueltas_100k title="Disoltas por 100.000 hab." fmt='0'/>
    <Column id=saldo_100k title="Saldo por 100.000 hab." fmt='0' contentType=delta/>
    <Column id=capital_real_hab title="Capital subscrito (€ por hab.)" fmt='#,##0'/>
</DataTable>

## Concursos de acredores

```sql concursos
SELECT CAST(anio AS INTEGER) AS anio, concursos, concursos_100k, concursos_1000emp
FROM mother.empresas_concursos
WHERE cod = '00' AND anio >= 2005
ORDER BY anio
```

```sql concursos_hitos
SELECT
    max(concursos_1000emp) FILTER (WHERE anio = 2007) AS r2007,
    max(concursos_1000emp) AS r_max,
    arg_max(anio, concursos_1000emp) AS anio_max,
    max(concursos_1000emp) FILTER (WHERE anio = 2020) AS r2020,
    max(concursos_100k) FILTER (WHERE anio = 2020) AS h2020
FROM ${concursos}
```

Empresas e persoas que entran en concurso de acredores (a antiga quebra ou suspensión de pagamentos), por cada 1.000 empresas activas. Pasaron de {formatNumber(concursos_hitos[0]?.r2007, 2)} en 2007 a {formatNumber(concursos_hitos[0]?.r_max, 2)} en {concursos_hitos[0]?.anio_max}. En 2020 foron {formatNumber(concursos_hitos[0]?.r2020, 2)} por 1.000 empresas ({formatNumber(concursos_hitos[0]?.h2020, 1)} por 100.000 habitantes). O INE non publicou esta estatística despois de 2020.

<BarChart
    data={concursos}
    x=anio
    y=concursos_1000emp
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="por 1.000 empresas"
    title="Debedores concursados por cada 1.000 empresas activas (2005-2020)"
/>

```sql quiebras
SELECT fecha, periodo, pais, indice
FROM mother.empresas_altas_quiebras
WHERE indicador = 'Quiebras' AND geo IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT')
ORDER BY fecha, pais
```

```sql quiebras_ult
SELECT
    max(periodo) AS periodo,
    max(indice) FILTER (WHERE geo = 'ES' AND fecha = (SELECT max(fecha) FROM mother.empresas_altas_quiebras)) AS es,
    max(indice) FILTER (WHERE geo = 'EU27_2020' AND fecha = (SELECT max(fecha) FROM mother.empresas_altas_quiebras)) AS ue
FROM mother.empresas_altas_quiebras
WHERE indicador = 'Quiebras'
```

Para ver a tendencia recente serve o índice de declaracións de quebra de Eurostat, que compara cada país consigo mesmo (2021 = 100) e non permite comparar niveis entre países. En {quiebras_ult[0]?.periodo}, o índice de España estaba en {formatNumber(quiebras_ult[0]?.es, 0)} e o da UE-27 en {formatNumber(quiebras_ult[0]?.ue, 0)}.

<LineChart
    data={quiebras}
    x=fecha
    y=indice
    series=pais
    yFmt='0'
    yAxisTitle="índice 2021 = 100"
    title="Declaracións de quebra (índice 2021 = 100, desestacionalizado)"
/>

## Autónomos

```sql autonomos_tipo
SELECT anio, 'Empleadores (con asalariados)' AS tipo, pct_empleadores AS pct FROM ${autonomos_anual}
UNION ALL
SELECT anio, 'Sin asalariados' AS tipo, pct_independientes AS pct FROM ${autonomos_anual}
UNION ALL
SELECT anio, 'Otros (cooperativistas, ayuda familiar)' AS tipo, pct_cuenta_propia - pct_empleadores - pct_independientes AS pct FROM ${autonomos_anual}
ORDER BY anio, tipo
```

```sql autonomos_hitos
SELECT
    max(pct_cuenta_propia) FILTER (WHERE anio = 2002) AS p2002,
    max(pct_cuenta_propia) FILTER (WHERE anio = (SELECT max(anio) FROM ${autonomos_anual})) AS p_ult,
    max(cuenta_propia) FILTER (WHERE anio = 2002) AS n2002,
    max(cuenta_propia) FILTER (WHERE anio = (SELECT max(anio) FROM ${autonomos_anual})) AS n_ult,
    max(anio) AS anio_ult
FROM ${autonomos_anual}
```

A Enquisa de Poboación Activa pregunta a cada ocupado se traballa por conta propia ou allea. O número de traballadores por conta propia cambiou pouco ({formatNumber(autonomos_hitos[0]?.n2002 / 1000, 2)} millóns en 2002 e {formatNumber(autonomos_hitos[0]?.n_ult / 1000, 2)} millóns en {autonomos_hitos[0]?.anio_ult}), pero como o emprego asalariado medrou máis, o seu peso baixou do {formatNumber(autonomos_hitos[0]?.p2002, 1)} % ao {formatNumber(autonomos_hitos[0]?.p_ult, 1)} % dos ocupados. Son persoas, non altas na Seguridade Social: a cifra de afiliados ao réxime de autónomos é distinta.

<BarChart
    data={autonomos_tipo}
    x=anio
    y=pct
    series=tipo
    type=stacked
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% dos ocupados"
    colorPalette={['#1d4ed8', '#94a3b8', '#60a5fa']}
    title="Traballadores por conta propia en % dos ocupados (media anual)"
/>

```sql autonomos_ccaa
SELECT
    t.nombre AS comunidad,
    '/gl' || t.ruta AS ruta,
    a.cod,
    a.pct_cuenta_propia,
    a.pct_empleadores,
    a.cuenta_propia,
    CAST(a.anio AS INTEGER) AS anio
FROM mother.empresas_autonomos_anual a
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = a.cod
WHERE a.anio = (SELECT max(anio) FROM mother.empresas_autonomos_anual)
ORDER BY a.pct_cuenta_propia DESC
```

En {autonomos_ccaa[0]?.anio}, {autonomos_ccaa[0]?.comunidad} tiña a maior proporción de traballadores por conta propia ({formatNumber(autonomos_ccaa[0]?.pct_cuenta_propia, 1)} % dos ocupados) e {autonomos_ccaa.slice(-1)[0]?.comunidad} a menor ({formatNumber(autonomos_ccaa.slice(-1)[0]?.pct_cuenta_propia, 1)} %).

<BarChart
    data={autonomos_ccaa}
    x=comunidad
    y=pct_cuenta_propia
    swapXY=true
    yFmt='0.0"%"'
    title="Traballadores por conta propia, % dos ocupados ({autonomos_ccaa[0]?.anio})"
/>

## Investigación e desenvolvemento (I+D)

```sql id_paises
SELECT pais, es_ue, pct_pib, investigadores_1000ocup, CAST(anio AS INTEGER) AS anio,
    CASE WHEN geo = 'ES' THEN 'España' WHEN geo = 'EU27_2020' THEN 'UE-27' ELSE 'Otros' END AS grupo
FROM mother.empresas_id_paises
WHERE sector = 'Total' AND pais IS NOT NULL AND pct_pib IS NOT NULL
  AND (es_ue OR geo IN ('EU27_2020', 'NO', 'CH', 'US', 'JP', 'KR', 'CN_X_HK', 'UK'))
  AND anio = (SELECT max(anio) FROM mother.empresas_id_paises WHERE geo = 'ES' AND pct_pib IS NOT NULL)
ORDER BY pct_pib DESC
```

```sql id_rank
SELECT
    count(*) FILTER (WHERE pct_pib > (SELECT pct_pib FROM ${id_paises} WHERE pais = 'España')) + 1 AS puesto,
    count(*) AS paises
FROM ${id_paises}
WHERE es_ue
```

```sql id_evol
SELECT CAST(anio AS INTEGER) AS anio, pais, pct_pib
FROM mother.empresas_id_paises
WHERE sector = 'Total' AND geo IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT') AND pct_pib IS NOT NULL AND anio >= 2000
ORDER BY anio, pais
```

```sql id_hitos
SELECT
    max(pct_pib) FILTER (WHERE anio BETWEEN 2000 AND 2012) AS p_max,
    arg_max(anio, pct_pib) FILTER (WHERE anio BETWEEN 2000 AND 2012) AS anio_pmax,
    min(pct_pib) FILTER (WHERE anio BETWEEN 2010 AND 2019) AS p_min,
    arg_min(anio, pct_pib) FILTER (WHERE anio BETWEEN 2010 AND 2019) AS anio_min,
    max(eur_hab_real) FILTER (WHERE anio BETWEEN 2000 AND 2012) AS h_max,
    arg_max(anio, eur_hab_real) FILTER (WHERE anio BETWEEN 2000 AND 2012) AS anio_hmax,
    min(eur_hab_real) FILTER (WHERE anio BETWEEN 2010 AND 2019) AS h_min,
    arg_min(anio, eur_hab_real) FILTER (WHERE anio BETWEEN 2010 AND 2019) AS anio_hmin,
    max(eur_hab_real) FILTER (WHERE anio = (SELECT max(anio) FROM ${id_es})) AS h_ult,
    max(investigadores_1000ocup) FILTER (WHERE anio = (SELECT max(anio) FROM ${id_es})) AS inv_ult,
    max(anio) AS anio_ult
FROM ${id_es}
```

O gasto en I+D inclúe o que investigan as empresas, as administracións, as universidades e as entidades sen ánimo de lucro, e mídese en porcentaxe do PIB. En {id_ue_ult[0]?.anio}, España gastou o {formatNumber(id_ue_ult[0]?.es, 2)} % do PIB, fronte ao {formatNumber(id_ue_ult[0]?.ue, 2)} % da UE-27, e ocupaba o posto {id_rank[0]?.puesto} dos {id_rank[0]?.paises} países da Unión.

<BarChart
    data={id_paises}
    x=pais
    y=pct_pib
    series=grupo
    swapXY=true
    yFmt='0.00"%"'
    colorPalette={['#dc2626', '#94a3b8', '#1d4ed8']}
    title="Gasto en I+D en % do PIB ({id_paises[0]?.anio})"
/>

Coa crise o gasto retrocedeu: do {formatNumber(id_hitos[0]?.p_max, 2)} % do PIB en {id_hitos[0]?.anio_pmax} ao {formatNumber(id_hitos[0]?.p_min, 2)} % en {id_hitos[0]?.anio_min}. Descontada a inflación, baixou de {formatNumber(id_hitos[0]?.h_max, 0)} € por habitante en {id_hitos[0]?.anio_hmax} a {formatNumber(id_hitos[0]?.h_min, 0)} € en {id_hitos[0]?.anio_hmin}, e en {id_hitos[0]?.anio_ult} foi de {formatNumber(id_hitos[0]?.h_ult, 0)} € (euros de {id_es.slice(-1)[0]?.anio_euros}).

<LineChart
    data={id_evol}
    x=anio
    y=pct_pib
    series=pais
    xFmt='0'
    yFmt='0.00"%"'
    yAxisTitle="% do PIB"
    title="Gasto en I+D en % do PIB: España e outros países"
/>

<LineChart
    data={id_es}
    x=anio
    y=eur_hab_real
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ por habitante"
    title="Gasto en I+D por habitante en España, euros de {id_es.slice(-1)[0]?.anio_euros}"
/>

```sql id_sector
SELECT CAST(anio AS INTEGER) AS anio, sector, pct_pib
FROM mother.empresas_id_paises
WHERE geo = 'ES' AND sector <> 'Total' AND pct_pib IS NOT NULL
ORDER BY anio, sector
```

```sql id_sector_ue
SELECT
    max(pct_pib) FILTER (WHERE geo = 'ES' AND sector = 'Empresas') AS es_emp,
    max(pct_pib) FILTER (WHERE geo = 'EU27_2020' AND sector = 'Empresas') AS ue_emp,
    max(pct_pib) FILTER (WHERE geo = 'ES' AND sector IN ('Administraciones públicas')) AS es_aapp,
    max(pct_pib) FILTER (WHERE geo = 'EU27_2020' AND sector IN ('Administraciones públicas')) AS ue_aapp,
    max(pct_pib) FILTER (WHERE geo = 'ES' AND sector IN ('Universidades')) AS es_uni,
    max(pct_pib) FILTER (WHERE geo = 'EU27_2020' AND sector IN ('Universidades')) AS ue_uni,
    max(anio) AS anio
FROM mother.empresas_id_paises
WHERE anio = (SELECT max(anio) FROM ${id_es})
```

Quen executa o gasto. En {id_sector_ue[0]?.anio}, as empresas gastaron en I+D o {formatNumber(id_sector_ue[0]?.es_emp, 2)} % do PIB en España e o {formatNumber(id_sector_ue[0]?.ue_emp, 2)} % na UE-27; as administracións, o {formatNumber(id_sector_ue[0]?.es_aapp, 2)} % fronte ao {formatNumber(id_sector_ue[0]?.ue_aapp, 2)} %, e as universidades, o {formatNumber(id_sector_ue[0]?.es_uni, 2)} % fronte ao {formatNumber(id_sector_ue[0]?.ue_uni, 2)} %. A diferenza con Europa está sobre todo nas empresas.

<BarChart
    data={id_sector}
    x=anio
    y=pct_pib
    series=sector
    type=stacked
    xFmt='0'
    yFmt='0.00"%"'
    yAxisTitle="% do PIB"
    colorPalette={['#0f766e', '#1d4ed8', '#cbd5e1', '#f59e0b']}
    title="Gasto en I+D en España por sector que o executa, % do PIB"
/>

```sql inv_evol
SELECT CAST(anio AS INTEGER) AS anio, pais, investigadores_1000ocup
FROM mother.empresas_id_paises
WHERE sector = 'Total' AND geo IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT') AND investigadores_1000ocup IS NOT NULL AND anio >= 2005
ORDER BY anio, pais
```

Investigadores en equivalencia a xornada completa por cada 1.000 ocupados: {formatNumber(id_ue_ult[0]?.es_inv, 1)} en España e {formatNumber(id_ue_ult[0]?.ue_inv, 1)} na UE-27 en {id_ue_ult[0]?.anio}.

<LineChart
    data={inv_evol}
    x=anio
    y=investigadores_1000ocup
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="por 1.000 ocupados"
    title="Investigadores (xornada completa) por 1.000 ocupados"
/>

```sql id_ccaa
SELECT
    t.nombre AS comunidad,
    '/gl' || t.ruta AS ruta,
    i.cod,
    i.pct_pib,
    i.eur_hab_real,
    i.investigadores_1000ocup,
    e.pct_pib AS pct_pib_empresas,
    CAST(i.anio AS INTEGER) AS anio,
    CAST(i.anio_euros AS INTEGER) AS anio_euros
FROM mother.empresas_id_ccaa i
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = i.cod
LEFT JOIN mother.empresas_id_ccaa e ON e.cod = i.cod AND e.anio = i.anio AND e.sector = 'Empresas'
WHERE i.sector = 'Total'
  AND i.anio = (SELECT max(anio) FROM mother.empresas_id_ccaa WHERE cod <> '00' AND sector = 'Total' AND pct_pib IS NOT NULL)
ORDER BY i.pct_pib DESC
```

Por comunidade, en {id_ccaa[0]?.anio} (último ano con datos rexionais). {id_ccaa[0]?.comunidad} dedicou a I+D o {formatNumber(id_ccaa[0]?.pct_pib, 2)} % do seu PIB e {id_ccaa.slice(-1)[0]?.comunidad} o {formatNumber(id_ccaa.slice(-1)[0]?.pct_pib, 2)} %.

<MapaEspana
    data={id_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="pct_pib"
    valueFmt='0.00"%"'
    link="ruta"
    colorPalette={['#f0fdf4', '#4ade80', '#14532d']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: Eurostat / INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_pib', title: 'I+D, % do PIB', fmt: '0.00"%"'},
        {id: 'eur_hab_real', title: '€ por habitante', fmt: '#,##0'}
    ]}
/>

<DataTable data={id_ccaa} rows=20 link=ruta>
    <Column id=comunidad title="Comunidade"/>
    <Column id=pct_pib title="I+D (% do PIB)" fmt='0.00'/>
    <Column id=pct_pib_empresas title="Diso, empresas (% do PIB)" fmt='0.00'/>
    <Column id=eur_hab_real title="€ por habitante (reais)" fmt='#,##0'/>
    <Column id=investigadores_1000ocup title="Investigadores por 1.000 ocupados" fmt='0.0'/>
</DataTable>

A produción das empresas por sector está en [Sectores](/gl/economia/sectores) e os salarios en [Salarios](/gl/economia/salarios).

---

**Fontes:** INE, [Directorio Central de Empresas (DIRCE)](https://www.ine.es/dyngs/INEbase/operacion.htm?c=Estadistica_C&cid=1254736160707&idp=1254735576550), táboas [302](https://www.ine.es/jaxiT3/Tabla.htm?t=302) (empresas por provincia desde 1999) e [39372](https://www.ine.es/jaxiT3/Tabla.htm?t=39372) (por comunidade, actividade e asalariados); [Estatística de Sociedades Mercantís, táboa 13912](https://www.ine.es/jaxiT3/Tabla.htm?t=13912); [Estatística do Procedemento Concursal, táboa 2992](https://www.ine.es/jaxiT3/Tabla.htm?t=2992); [EPA, ocupados por situación profesional, táboa 65316](https://www.ine.es/jaxiT3/Tabla.htm?t=65316). Eurostat: gasto en I+D [rd_e_gerdtot](https://ec.europa.eu/eurostat/databrowser/view/rd_e_gerdtot/default/table) e [rd_e_gerdreg](https://ec.europa.eu/eurostat/databrowser/view/rd_e_gerdreg/default/table), investigadores [rd_p_perslf](https://ec.europa.eu/eurostat/databrowser/view/rd_p_perslf/default/table) e [rd_p_persreg](https://ec.europa.eu/eurostat/databrowser/view/rd_p_persreg/default/table) (elaborados coa Estatística sobre Actividades de I+D do INE), empresas por tamaño [sbs_sc_ovw](https://ec.europa.eu/eurostat/databrowser/view/sbs_sc_ovw/default/table) e altas e quebras [sts_rb_q](https://ec.europa.eu/eurostat/databrowser/view/sts_rb_q/default/table). Poboación: padrón do INE. Euros constantes co IPC xeral do INE (base 2025).
