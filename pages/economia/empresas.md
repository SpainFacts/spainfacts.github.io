---
title: Empresas, emprendimiento e I+D
description: "Cuántas empresas hay en España por habitante y de qué tamaño, cuántas sociedades se crean y se disuelven, los concursos de acreedores, los autónomos y el gasto en I+D comparado con Europa y por comunidad."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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

# 🏭 Empresas, emprendimiento e I+D

Cuántas empresas hay en España y de qué tamaño son, cuántas sociedades se crean y cuántas cierran, cuántos trabajadores son autónomos y cuánto se invierte en investigación y desarrollo (I+D) comparado con Europa. Las cifras se dan por habitante, en porcentaje o, si son euros, descontada la inflación.

<Grid cols=4>
    <KpiCard
        title="Empresas por 1.000 habitantes"
        value={emp_hitos[0]?.e_ult}
        formattedValue={formatNumber(emp_hitos[0]?.e_ult, 1)}
        period="activas a 1 de enero de {emp_hitos[0]?.anio_ult} · {formatCompact(emp_hitos[0]?.empresas_ult, 2)} empresas, incluidos autónomos"
        change={(emp_hitos[0]?.e_ult - emp_hitos[0]?.e_ant)?.toFixed(1)}
        changeUnit=""
        changePeriod="vs año anterior"
        direction="positive-up"
        source="INE / DIRCE"
        sparklineData={emp_pais.map(d => ({...d, y: d.empresas_1000hab}))}
    />
    <KpiCard
        title="Sociedades creadas"
        value={soc_12m_ult[0]?.constituidas_12m_100k}
        formattedValue="{formatNumber(soc_12m_ult[0]?.constituidas_12m_100k, 0)} por 100.000 hab."
        period="en los 12 meses hasta {soc_12m_ult[0]?.mes_texto} · {formatNumber(soc_12m_ult[0]?.constituidas_12m, 0)} sociedades mercantiles"
        change={soc_12m_ult[0]?.cambio_anual?.toFixed(1)}
        changePeriod="vs 12 meses antes"
        direction="positive-up"
        source="INE / Sociedades Mercantiles"
        sparklineData={soc_12m.slice(-120).map(d => ({...d, y: d.constituidas_12m_100k}))}
    />
    <KpiCard
        title="Autónomos"
        value={autonomos_ult[0]?.pct_cuenta_propia}
        formattedValue="{formatNumber(autonomos_ult[0]?.pct_cuenta_propia, 1)} % de los ocupados"
        period="trabajan por cuenta propia ({autonomos_ult[0]?.periodo}) · {formatNumber(autonomos_ult[0]?.cuenta_propia / 1000, 2)} millones de personas"
        direction="neutral"
        source="INE / EPA"
        sparklineData={autonomos_anual.map(d => ({...d, y: d.pct_cuenta_propia}))}
    />
    <KpiCard
        title="Gasto en I+D"
        value={id_ue_ult[0]?.es}
        formattedValue="{formatNumber(id_ue_ult[0]?.es, 2)} % del PIB"
        period="en {id_ue_ult[0]?.anio} · UE-27: {formatNumber(id_ue_ult[0]?.ue, 2)} % · {formatNumber(id_ue_ult[0]?.es_hab, 0)} € por habitante (euros de {id_es.slice(-1)[0]?.anio_euros})"
        direction="positive-up"
        source="Eurostat / INE"
        sparklineData={id_es.map(d => ({...d, y: d.pct_pib}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('id_pib')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'id_pib')} />


## Cuántas empresas hay

```sql emp_ccaa
SELECT
    t.nombre AS comunidad,
    t.ruta,
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

El Directorio Central de Empresas del INE cuenta a 1 de enero todas las empresas activas, incluidos los autónomos, salvo las del campo y la pesca, las administraciones y el servicio doméstico. En {emp_hitos[0]?.anio_ult} había {formatNumber(emp_hitos[0]?.e_ult, 1)} por cada 1.000 habitantes, frente a {formatNumber(emp_hitos[0]?.e2008, 1)} en 2008. En 2023 el INE pasó a contar solo las empresas económicamente activas: la caída de ese año es un cambio de criterio (en términos homogéneos el número de empresas creció un 0,5 % según el INE).

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
    yAxisTitle="% de las empresas"
    title="Empresas que son personas físicas (autónomos con actividad empresarial), % del total"
/>

Por comunidad, {emp_ccaa[0]?.comunidad} tiene la mayor densidad empresarial, con {formatNumber(emp_ccaa[0]?.empresas_1000hab, 1)} empresas por 1.000 habitantes, y {emp_ccaa.slice(-1)[0]?.comunidad} la menor, con {formatNumber(emp_ccaa.slice(-1)[0]?.empresas_1000hab, 1)}. Las empresas se cuentan en la comunidad de su sede, no donde tienen sus establecimientos.

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'empresas_1000hab', title: 'Empresas por 1.000 hab.', fmt: '0.0'},
        {id: 'empresas', title: 'Empresas', fmt: '#,##0'}
    ]}
/>

## Tamaño: casi todas son muy pequeñas

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

En {tamano_resumen[0]?.anio}, el {formatNumber(tamano_resumen[0]?.sin_asal, 1)} % de las empresas no tenía ningún asalariado y el {formatNumber(tamano_resumen[0]?.hasta_9, 1)} % tenía menos de 10. Solo el {formatNumber(tamano_resumen[0]?.medianas_grandes, 2)} % tenía 50 asalariados o más; las grandes, con 250 o más, eran {formatNumber(tamano_resumen[0]?.grandes, 0)}.

<BarChart
    data={tamano_es}
    x=tamano
    y=pct
    sort=false
    swapXY=true
    yFmt='0.00"%"'
    title="Empresas por número de asalariados, % del total ({tamano_es[0]?.anio})"
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

Para comparar con Europa, Eurostat mide el tamaño por personas ocupadas (incluidos los dueños) y deja fuera las finanzas. En {tamano_ue_resumen[0]?.anio}, las microempresas (menos de 10 ocupados) daban el {formatNumber(tamano_ue_resumen[0]?.es_micro, 1)} % del empleo empresarial en España frente al {formatNumber(tamano_ue_resumen[0]?.ue_micro, 1)} % en la UE-27; las grandes, el {formatNumber(tamano_ue_resumen[0]?.es_grandes, 1)} % frente al {formatNumber(tamano_ue_resumen[0]?.ue_grandes, 1)} % (en Alemania, el {formatNumber(tamano_ue_resumen[0]?.de_grandes, 1)} %).

<BarChart
    data={tamano_ue}
    x=pais
    y=pct_empleo
    series=tamano
    type=stacked
    swapXY=true
    yFmt='0.0"%"'
    colorPalette={['#bfdbfe', '#60a5fa', '#2563eb', '#1e3a8a']}
    title="Reparto del empleo empresarial por tamaño de empresa ({tamano_ue[0]?.anio})"
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
    title="Reparto del valor añadido por tamaño de empresa ({tamano_ue[0]?.anio})"
/>

## A qué se dedican

```sql sector_es
SELECT sector, empresas, pct, por_1000_hab, CAST(anio AS INTEGER) AS anio
FROM mother.empresas_dirce_sector
WHERE cod = '00' AND anio = (SELECT max(anio) FROM mother.empresas_dirce_sector)
ORDER BY pct DESC
```

Empresas activas por gran sector en {sector_es[0]?.anio}. {sector_es[0]?.sector} es el sector con más empresas: {formatNumber(sector_es[0]?.pct, 1)} % del total, {formatNumber(sector_es[0]?.por_1000hab, 1)} por 1.000 habitantes.

<BarChart
    data={sector_es}
    x=sector
    y=por_1000_hab
    swapXY=true
    yFmt='0.0'
    title="Empresas por 1.000 habitantes según su actividad ({sector_es[0]?.anio})"
/>

## Sociedades que se crean y se disuelven

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

Sociedades mercantiles (sobre todo limitadas y anónimas) inscritas y disueltas en el Registro Mercantil, sumando los 12 meses anteriores y por cada 100.000 habitantes. En {soc_hitos[0]?.anio_ult} se crearon {formatNumber(soc_hitos[0]?.c_ult, 0)} por 100.000 habitantes, frente a {formatNumber(soc_hitos[0]?.c2006, 0)} en 2006 y {formatNumber(soc_hitos[0]?.c2009, 0)} en 2009; se disolvieron {formatNumber(soc_hitos[0]?.d_ult, 0)} por 100.000, es decir, {formatNumber(soc_hitos[0]?.ratio_ult, 0)} por cada 100 creadas. Los autónomos no aparecen aquí.

<LineChart
    data={soc_largo}
    x=fecha
    y=valor
    series=tipo
    yFmt='0'
    yAxisTitle="por 100.000 hab. (12 meses)"
    colorPalette={['#2563eb', '#dc2626']}
    title="Sociedades mercantiles creadas y disueltas en los últimos 12 meses, por 100.000 habitantes"
/>

El capital con el que nacen las sociedades, descontada la inflación, ha bajado: el capital medio suscrito fue de {formatNumber(soc_hitos[0]?.cap_medio_ult, 0)} € en {soc_hitos[0]?.anio_ult}, frente a {formatNumber(soc_hitos[0]?.cap_medio_2006, 0)} € en 2006 (euros de {soc_anual.slice(-1)[0]?.anio_euros}). Es una media: unas pocas sociedades con mucho capital pesan mucho en ella.

<LineChart
    data={soc_anual.filter(d => d.capital_real_hab != null)}
    x=anio
    y=capital_real_hab
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ por habitante"
    title="Capital suscrito por las nuevas sociedades, euros de {soc_anual.slice(-1)[0]?.anio_euros} por habitante"
/>

```sql soc_ccaa
SELECT
    t.nombre AS comunidad,
    t.ruta,
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

Por comunidad, en {soc_ccaa[0]?.anio}. Cada sociedad se cuenta en la comunidad de su domicilio social.

<DataTable data={soc_ccaa} rows=20 link=ruta>
    <Column id=comunidad title="Comunidad"/>
    <Column id=constituidas_100k title="Creadas por 100.000 hab." fmt='0'/>
    <Column id=disueltas_100k title="Disueltas por 100.000 hab." fmt='0'/>
    <Column id=saldo_100k title="Saldo por 100.000 hab." fmt='0' contentType=delta/>
    <Column id=capital_real_hab title="Capital suscrito (€ por hab.)" fmt='#,##0'/>
</DataTable>

## Concursos de acreedores

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

Empresas y personas que entran en concurso de acreedores (la antigua quiebra o suspensión de pagos), por cada 1.000 empresas activas. Pasaron de {formatNumber(concursos_hitos[0]?.r2007, 2)} en 2007 a {formatNumber(concursos_hitos[0]?.r_max, 2)} en {concursos_hitos[0]?.anio_max}. En 2020 fueron {formatNumber(concursos_hitos[0]?.r2020, 2)} por 1.000 empresas ({formatNumber(concursos_hitos[0]?.h2020, 1)} por 100.000 habitantes). El INE no ha publicado esta estadística después de 2020.

<BarChart
    data={concursos}
    x=anio
    y=concursos_1000emp
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="por 1.000 empresas"
    title="Deudores concursados por cada 1.000 empresas activas (2005-2020)"
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

Para ver la tendencia reciente sirve el índice de declaraciones de quiebra de Eurostat, que compara cada país consigo mismo (2021 = 100) y no permite comparar niveles entre países. En {quiebras_ult[0]?.periodo}, el índice de España estaba en {formatNumber(quiebras_ult[0]?.es, 0)} y el de la UE-27 en {formatNumber(quiebras_ult[0]?.ue, 0)}.

<LineChart
    data={quiebras}
    x=fecha
    y=indice
    series=pais
    yFmt='0'
    yAxisTitle="índice 2021 = 100"
    title="Declaraciones de quiebra (índice 2021 = 100, desestacionalizado)"
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

La Encuesta de Población Activa pregunta a cada ocupado si trabaja por cuenta propia o ajena. El número de trabajadores por cuenta propia ha cambiado poco ({formatNumber(autonomos_hitos[0]?.n2002 / 1000, 2)} millones en 2002 y {formatNumber(autonomos_hitos[0]?.n_ult / 1000, 2)} millones en {autonomos_hitos[0]?.anio_ult}), pero como el empleo asalariado ha crecido más, su peso ha bajado del {formatNumber(autonomos_hitos[0]?.p2002, 1)} % al {formatNumber(autonomos_hitos[0]?.p_ult, 1)} % de los ocupados. Son personas, no altas en la Seguridad Social: la cifra de afiliados al régimen de autónomos es distinta.

<BarChart
    data={autonomos_tipo}
    x=anio
    y=pct
    series=tipo
    type=stacked
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% de los ocupados"
    colorPalette={['#1d4ed8', '#94a3b8', '#60a5fa']}
    title="Trabajadores por cuenta propia en % de los ocupados (media anual)"
/>

```sql autonomos_ccaa
SELECT
    t.nombre AS comunidad,
    t.ruta,
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

En {autonomos_ccaa[0]?.anio}, {autonomos_ccaa[0]?.comunidad} tenía la mayor proporción de trabajadores por cuenta propia ({formatNumber(autonomos_ccaa[0]?.pct_cuenta_propia, 1)} % de los ocupados) y {autonomos_ccaa.slice(-1)[0]?.comunidad} la menor ({formatNumber(autonomos_ccaa.slice(-1)[0]?.pct_cuenta_propia, 1)} %).

<BarChart
    data={autonomos_ccaa}
    x=comunidad
    y=pct_cuenta_propia
    swapXY=true
    yFmt='0.0"%"'
    title="Trabajadores por cuenta propia, % de los ocupados ({autonomos_ccaa[0]?.anio})"
/>

## Investigación y desarrollo (I+D)

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

El gasto en I+D incluye lo que investigan las empresas, las administraciones, las universidades y las entidades sin ánimo de lucro, y se mide en porcentaje del PIB. En {id_ue_ult[0]?.anio}, España gastó el {formatNumber(id_ue_ult[0]?.es, 2)} % del PIB, frente al {formatNumber(id_ue_ult[0]?.ue, 2)} % de la UE-27, y ocupaba el puesto {id_rank[0]?.puesto} de los {id_rank[0]?.paises} países de la Unión.

<BarChart
    data={id_paises}
    x=pais
    y=pct_pib
    series=grupo
    swapXY=true
    yFmt='0.00"%"'
    colorPalette={['#dc2626', '#94a3b8', '#1d4ed8']}
    title="Gasto en I+D en % del PIB ({id_paises[0]?.anio})"
/>

Con la crisis el gasto retrocedió: del {formatNumber(id_hitos[0]?.p_max, 2)} % del PIB en {id_hitos[0]?.anio_pmax} al {formatNumber(id_hitos[0]?.p_min, 2)} % en {id_hitos[0]?.anio_min}. Descontada la inflación, bajó de {formatNumber(id_hitos[0]?.h_max, 0)} € por habitante en {id_hitos[0]?.anio_hmax} a {formatNumber(id_hitos[0]?.h_min, 0)} € en {id_hitos[0]?.anio_hmin}, y en {id_hitos[0]?.anio_ult} fue de {formatNumber(id_hitos[0]?.h_ult, 0)} € (euros de {id_es.slice(-1)[0]?.anio_euros}).

<LineChart
    data={id_evol}
    x=anio
    y=pct_pib
    series=pais
    xFmt='0'
    yFmt='0.00"%"'
    yAxisTitle="% del PIB"
    title="Gasto en I+D en % del PIB: España y otros países"
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

Quién ejecuta el gasto. En {id_sector_ue[0]?.anio}, las empresas gastaron en I+D el {formatNumber(id_sector_ue[0]?.es_emp, 2)} % del PIB en España y el {formatNumber(id_sector_ue[0]?.ue_emp, 2)} % en la UE-27; las administraciones, el {formatNumber(id_sector_ue[0]?.es_aapp, 2)} % frente al {formatNumber(id_sector_ue[0]?.ue_aapp, 2)} %, y las universidades, el {formatNumber(id_sector_ue[0]?.es_uni, 2)} % frente al {formatNumber(id_sector_ue[0]?.ue_uni, 2)} %. La diferencia con Europa está sobre todo en las empresas.

<BarChart
    data={id_sector}
    x=anio
    y=pct_pib
    series=sector
    type=stacked
    xFmt='0'
    yFmt='0.00"%"'
    yAxisTitle="% del PIB"
    colorPalette={['#0f766e', '#1d4ed8', '#cbd5e1', '#f59e0b']}
    title="Gasto en I+D en España por sector que lo ejecuta, % del PIB"
/>

```sql inv_evol
SELECT CAST(anio AS INTEGER) AS anio, pais, investigadores_1000ocup
FROM mother.empresas_id_paises
WHERE sector = 'Total' AND geo IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT') AND investigadores_1000ocup IS NOT NULL AND anio >= 2005
ORDER BY anio, pais
```

Investigadores en equivalencia a jornada completa por cada 1.000 ocupados: {formatNumber(id_ue_ult[0]?.es_inv, 1)} en España y {formatNumber(id_ue_ult[0]?.ue_inv, 1)} en la UE-27 en {id_ue_ult[0]?.anio}.

<LineChart
    data={inv_evol}
    x=anio
    y=investigadores_1000ocup
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="por 1.000 ocupados"
    title="Investigadores (jornada completa) por 1.000 ocupados"
/>

```sql id_ccaa
SELECT
    t.nombre AS comunidad,
    t.ruta,
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

Por comunidad, en {id_ccaa[0]?.anio} (último año con datos regionales). {id_ccaa[0]?.comunidad} dedicó a I+D el {formatNumber(id_ccaa[0]?.pct_pib, 2)} % de su PIB y {id_ccaa.slice(-1)[0]?.comunidad} el {formatNumber(id_ccaa.slice(-1)[0]?.pct_pib, 2)} %.

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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: Eurostat / INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_pib', title: 'I+D, % del PIB', fmt: '0.00"%"'},
        {id: 'eur_hab_real', title: '€ por habitante', fmt: '#,##0'}
    ]}
/>

<DataTable data={id_ccaa} rows=20 link=ruta>
    <Column id=comunidad title="Comunidad"/>
    <Column id=pct_pib title="I+D (% del PIB)" fmt='0.00'/>
    <Column id=pct_pib_empresas title="De ello, empresas (% del PIB)" fmt='0.00'/>
    <Column id=eur_hab_real title="€ por habitante (reales)" fmt='#,##0'/>
    <Column id=investigadores_1000ocup title="Investigadores por 1.000 ocupados" fmt='0.0'/>
</DataTable>

La producción de las empresas por sector está en [Sectores](/economia/sectores) y los salarios en [Salarios](/economia/salarios).

---

**Fuentes:** INE, [Directorio Central de Empresas (DIRCE)](https://www.ine.es/dyngs/INEbase/operacion.htm?c=Estadistica_C&cid=1254736160707&idp=1254735576550), tablas [302](https://www.ine.es/jaxiT3/Tabla.htm?t=302) (empresas por provincia desde 1999) y [39372](https://www.ine.es/jaxiT3/Tabla.htm?t=39372) (por comunidad, actividad y asalariados); [Estadística de Sociedades Mercantiles, tabla 13912](https://www.ine.es/jaxiT3/Tabla.htm?t=13912); [Estadística del Procedimiento Concursal, tabla 2992](https://www.ine.es/jaxiT3/Tabla.htm?t=2992); [EPA, ocupados por situación profesional, tabla 65316](https://www.ine.es/jaxiT3/Tabla.htm?t=65316). Eurostat: gasto en I+D [rd_e_gerdtot](https://ec.europa.eu/eurostat/databrowser/view/rd_e_gerdtot/default/table) y [rd_e_gerdreg](https://ec.europa.eu/eurostat/databrowser/view/rd_e_gerdreg/default/table), investigadores [rd_p_perslf](https://ec.europa.eu/eurostat/databrowser/view/rd_p_perslf/default/table) y [rd_p_persreg](https://ec.europa.eu/eurostat/databrowser/view/rd_p_persreg/default/table) (elaborados con la Estadística sobre Actividades de I+D del INE), empresas por tamaño [sbs_sc_ovw](https://ec.europa.eu/eurostat/databrowser/view/sbs_sc_ovw/default/table) y altas y quiebras [sts_rb_q](https://ec.europa.eu/eurostat/databrowser/view/sts_rb_q/default/table). Población: padrón del INE. Euros constantes con el IPC general del INE (base 2025).
