---
title: Empreses, emprenedoria i R+D
description: "Quantes empreses hi ha a Espanya per habitant i de quina mida, quantes societats es creen i es dissolen, els concursos de creditors, els autònoms i la despesa en R+D comparada amb Europa i per comunitat."
i18n_origen: ba0336af2883
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql emp_pais
SELECT CAST(anio AS INTEGER) AS anio, empresas, empresas_1000hab, pct_personas_fisicas, crecimiento
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
ORDER BY fecha, trimestre
```

```sql autonomos_anual
SELECT * FROM ${autonomos_pais} WHERE trimestre = 0 ORDER BY anio
```

```sql autonomos_ult
SELECT * FROM ${autonomos_pais} WHERE trimestre > 0 ORDER BY fecha DESC LIMIT 1
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

# 🏭 Empreses, emprenedoria i R+D

Quantes empreses hi ha a Espanya i de quina mida són, quantes societats es creen i quantes tanquen, quants treballadors són autònoms i quant s'inverteix en recerca i desenvolupament (R+D) en comparació amb Europa. Les xifres es donen per habitant, en percentatge o, si són euros, descomptada la inflació.

<Grid cols=4>
    <KpiCard
        title="Empreses per 1.000 habitants"
        value={emp_hitos[0]?.e_ult}
        formattedValue={formatNumber(emp_hitos[0]?.e_ult, 1)}
        period="actives a 1 de gener de {emp_hitos[0]?.anio_ult} · {formatCompact(emp_hitos[0]?.empresas_ult, 2)} empreses, inclosos autònoms"
        change={(emp_hitos[0]?.e_ult - emp_hitos[0]?.e_ant)?.toFixed(1)}
        changeUnit=""
        changePeriod="respecte a l'any anterior"
        direction="positive-up"
        source="INE / DIRCE"
        sparklineData={emp_pais.map(d => d.empresas_1000hab)}
    />
    <KpiCard
        title="Societats creades"
        value={soc_12m_ult[0]?.constituidas_12m_100k}
        formattedValue="{formatNumber(soc_12m_ult[0]?.constituidas_12m_100k, 0)} per 100.000 hab."
        period="en els 12 mesos fins a {soc_12m_ult[0]?.mes_texto} · {formatNumber(soc_12m_ult[0]?.constituidas_12m, 0)} societats mercantils"
        change={soc_12m_ult[0]?.cambio_anual?.toFixed(1)}
        changePeriod="respecte als 12 mesos anteriors"
        direction="positive-up"
        source="INE / Societats Mercantils"
        sparklineData={soc_12m.slice(-120).map(d => d.constituidas_12m_100k)}
    />
    <KpiCard
        title="Autònoms"
        value={autonomos_ult[0]?.pct_cuenta_propia}
        formattedValue="{formatNumber(autonomos_ult[0]?.pct_cuenta_propia, 1)} % dels ocupats"
        period="treballen per compte propi ({autonomos_ult[0]?.periodo}) · {formatNumber(autonomos_ult[0]?.cuenta_propia / 1000, 2)} milions de persones"
        direction="neutral"
        source="INE / EPA"
        sparklineData={autonomos_anual.map(d => d.pct_cuenta_propia)}
    />
    <KpiCard
        title="Despesa en R+D"
        value={id_ue_ult[0]?.es}
        formattedValue="{formatNumber(id_ue_ult[0]?.es, 2)} % del PIB"
        period="el {id_ue_ult[0]?.anio} · UE-27: {formatNumber(id_ue_ult[0]?.ue, 2)} % · {formatNumber(id_ue_ult[0]?.es_hab, 0)} € per habitant (euros de {id_es.slice(-1)[0]?.anio_euros})"
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


## Quantes empreses hi ha

```sql emp_ccaa
SELECT
    t.nombre AS comunidad,
    '/ca' || t.ruta AS ruta,
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

El Directori Central d'Empreses de l'INE compta a 1 de gener totes les empreses actives, inclosos els autònoms, excepte les del camp i la pesca, les administracions i el servei domèstic. El {emp_hitos[0]?.anio_ult} n'hi havia {formatNumber(emp_hitos[0]?.e_ult, 1)} per cada 1.000 habitants, davant de {formatNumber(emp_hitos[0]?.e2008, 1)} el 2008. El 2023 l'INE va passar a comptar només les empreses econòmicament actives: la caiguda d'aquell any és un canvi de criteri (en termes homogenis el nombre d'empreses va créixer un 0,5 % segons l'INE).

<LineChart
    data={emp_pais}
    x=anio
    y=empresas_1000hab
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="empreses per 1.000 hab."
    startingAtZero={false}
    title="Empreses actives per 1.000 habitants"
/>

<BarChart
    data={emp_pais}
    x=anio
    y=pct_personas_fisicas
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% de les empreses"
    title="Empreses que són persones físiques (autònoms amb activitat empresarial), % del total"
/>

Per comunitat, {emp_ccaa[0]?.comunidad} té la densitat empresarial més alta, amb {formatNumber(emp_ccaa[0]?.empresas_1000hab, 1)} empreses per 1.000 habitants, i {emp_ccaa.slice(-1)[0]?.comunidad} la més baixa, amb {formatNumber(emp_ccaa.slice(-1)[0]?.empresas_1000hab, 1)}. Les empreses es compten a la comunitat de la seu, no allà on tenen els establiments.

<AreaMap
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
    attribution="Tessel·les © Esri · Límits © Institut Geogràfic Nacional · Dades: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'empresas_1000hab', title: 'Empreses per 1.000 hab.', fmt: '0.0'},
        {id: 'empresas', title: 'Empreses', fmt: '#,##0'}
    ]}
/>

## Mida: gairebé totes són molt petites

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

El {tamano_resumen[0]?.anio}, el {formatNumber(tamano_resumen[0]?.sin_asal, 1)} % de les empreses no tenia cap assalariat i el {formatNumber(tamano_resumen[0]?.hasta_9, 1)} % en tenia menys de 10. Només el {formatNumber(tamano_resumen[0]?.medianas_grandes, 2)} % tenia 50 assalariats o més; les grans, amb 250 o més, eren {formatNumber(tamano_resumen[0]?.grandes, 0)}.

<BarChart
    data={tamano_es}
    x=tamano
    y=pct
    sort=false
    swapXY=true
    yFmt='0.00"%"'
    title="Empreses per nombre d'assalariats, % del total ({tamano_es[0]?.anio})"
/>

```sql tamano_ue
SELECT pais, tamano, orden, pct_empresas, pct_empleo, pct_vab, CAST(anio AS INTEGER) AS anio
FROM mother.empresas_tamano_ue
WHERE anio = (SELECT max(anio) FROM mother.empresas_tamano_ue WHERE geo = 'EU27_2020' AND pct_vab IS NOT NULL)
  AND geo IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT')
ORDER BY orden, pais
```

```sql tamano_ue_resumen
SELECT
    max(pct_empleo) FILTER (WHERE pais = 'España' AND orden = 1) AS es_micro,
    max(pct_empleo) FILTER (WHERE pais = 'UE-27' AND orden = 1) AS ue_micro,
    max(pct_empleo) FILTER (WHERE pais = 'España' AND orden = 4) AS es_grandes,
    max(pct_empleo) FILTER (WHERE pais = 'UE-27' AND orden = 4) AS ue_grandes,
    max(pct_empleo) FILTER (WHERE pais = 'Alemania' AND orden = 4) AS de_grandes,
    max(anio) AS anio
FROM ${tamano_ue}
```

Per comparar amb Europa, Eurostat mesura la mida per persones ocupades (inclosos els propietaris) i deixa fora les finances. El {tamano_ue_resumen[0]?.anio}, les microempreses (menys de 10 ocupats) aportaven el {formatNumber(tamano_ue_resumen[0]?.es_micro, 1)} % de l'ocupació empresarial a Espanya davant del {formatNumber(tamano_ue_resumen[0]?.ue_micro, 1)} % a la UE-27; les grans, el {formatNumber(tamano_ue_resumen[0]?.es_grandes, 1)} % davant del {formatNumber(tamano_ue_resumen[0]?.ue_grandes, 1)} % (a Alemanya, el {formatNumber(tamano_ue_resumen[0]?.de_grandes, 1)} %).

<BarChart
    data={tamano_ue}
    x=pais
    y=pct_empleo
    series=tamano
    type=stacked
    swapXY=true
    yFmt='0.0"%"'
    colorPalette={['#bfdbfe', '#60a5fa', '#2563eb', '#1e3a8a']}
    title="Repartiment de l'ocupació empresarial per mida d'empresa ({tamano_ue[0]?.anio})"
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
    title="Repartiment del valor afegit per mida d'empresa ({tamano_ue[0]?.anio})"
/>

## A què es dediquen

```sql sector_es
SELECT sector, empresas, pct, por_1000hab, CAST(anio AS INTEGER) AS anio
FROM mother.empresas_dirce_sector
WHERE cod = '00' AND anio = (SELECT max(anio) FROM mother.empresas_dirce_sector)
ORDER BY pct DESC
```

Empreses actives per gran sector el {sector_es[0]?.anio}. {sector_es[0]?.sector} és el sector amb més empreses: {formatNumber(sector_es[0]?.pct, 1)} % del total, {formatNumber(sector_es[0]?.por_1000hab, 1)} per 1.000 habitants.

<BarChart
    data={sector_es}
    x=sector
    y=por_1000hab
    swapXY=true
    yFmt='0.0'
    title="Empreses per 1.000 habitants segons l'activitat ({sector_es[0]?.anio})"
/>

## Societats que es creen i es dissolen

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

Societats mercantils (sobretot limitades i anònimes) inscrites i dissoltes al Registre Mercantil, sumant els 12 mesos anteriors i per cada 100.000 habitants. El {soc_hitos[0]?.anio_ult} se'n van crear {formatNumber(soc_hitos[0]?.c_ult, 0)} per 100.000 habitants, davant de {formatNumber(soc_hitos[0]?.c2006, 0)} el 2006 i {formatNumber(soc_hitos[0]?.c2009, 0)} el 2009; se'n van dissoldre {formatNumber(soc_hitos[0]?.d_ult, 0)} per 100.000, és a dir, {formatNumber(soc_hitos[0]?.ratio_ult, 0)} per cada 100 de creades. Els autònoms no hi apareixen.

<LineChart
    data={soc_largo}
    x=fecha
    y=valor
    series=tipo
    yFmt='0'
    yAxisTitle="per 100.000 hab. (12 mesos)"
    colorPalette={['#2563eb', '#dc2626']}
    title="Societats mercantils creades i dissoltes en els últims 12 mesos, per 100.000 habitants"
/>

El capital amb què neixen les societats, descomptada la inflació, ha baixat: el capital mitjà subscrit va ser de {formatNumber(soc_hitos[0]?.cap_medio_ult, 0)} € el {soc_hitos[0]?.anio_ult}, davant de {formatNumber(soc_hitos[0]?.cap_medio_2006, 0)} € el 2006 (euros de {soc_anual.slice(-1)[0]?.anio_euros}). És una mitjana: unes poques societats amb molt de capital hi pesen molt.

<LineChart
    data={soc_anual.filter(d => d.capital_real_hab != null)}
    x=anio
    y=capital_real_hab
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per habitant"
    title="Capital subscrit per les noves societats, euros de {soc_anual.slice(-1)[0]?.anio_euros} per habitant"
/>

```sql soc_ccaa
SELECT
    t.nombre AS comunidad,
    '/ca' || t.ruta AS ruta,
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

Per comunitat, el {soc_ccaa[0]?.anio}. Cada societat es compta a la comunitat del seu domicili social.

<DataTable data={soc_ccaa} rows=20 link=ruta>
    <Column id=comunidad title="Comunitat"/>
    <Column id=constituidas_100k title="Creades per 100.000 hab." fmt='0'/>
    <Column id=disueltas_100k title="Dissoltes per 100.000 hab." fmt='0'/>
    <Column id=saldo_100k title="Saldo per 100.000 hab." fmt='0' contentType=delta/>
    <Column id=capital_real_hab title="Capital subscrit (€ per hab.)" fmt='#,##0'/>
</DataTable>

## Concursos de creditors

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

Empreses i persones que entren en concurs de creditors (l'antiga fallida o suspensió de pagaments), per cada 1.000 empreses actives. Van passar de {formatNumber(concursos_hitos[0]?.r2007, 2)} el 2007 a {formatNumber(concursos_hitos[0]?.r_max, 2)} el {concursos_hitos[0]?.anio_max}. El 2020 van ser {formatNumber(concursos_hitos[0]?.r2020, 2)} per 1.000 empreses ({formatNumber(concursos_hitos[0]?.h2020, 1)} per 100.000 habitants). L'INE no ha publicat aquesta estadística després del 2020.

<BarChart
    data={concursos}
    x=anio
    y=concursos_1000emp
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="per 1.000 empreses"
    title="Deutors concursats per cada 1.000 empreses actives (2005-2020)"
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

Per veure la tendència recent serveix l'índex de declaracions de fallida d'Eurostat, que compara cada país amb si mateix (2021 = 100) i no permet comparar nivells entre països. El {quiebras_ult[0]?.periodo}, l'índex d'Espanya era a {formatNumber(quiebras_ult[0]?.es, 0)} i el de la UE-27 a {formatNumber(quiebras_ult[0]?.ue, 0)}.

<LineChart
    data={quiebras}
    x=fecha
    y=indice
    series=pais
    yFmt='0'
    yAxisTitle="índex 2021 = 100"
    title="Declaracions de fallida (índex 2021 = 100, desestacionalitzat)"
/>

## Autònoms

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

L'Enquesta de Població Activa pregunta a cada ocupat si treballa per compte propi o d'altri. El nombre de treballadors per compte propi ha canviat poc ({formatNumber(autonomos_hitos[0]?.n2002 / 1000, 2)} milions el 2002 i {formatNumber(autonomos_hitos[0]?.n_ult / 1000, 2)} milions el {autonomos_hitos[0]?.anio_ult}), però com que l'ocupació assalariada ha crescut més, el seu pes ha baixat del {formatNumber(autonomos_hitos[0]?.p2002, 1)} % al {formatNumber(autonomos_hitos[0]?.p_ult, 1)} % dels ocupats. Són persones, no altes a la Seguretat Social: la xifra d'afiliats al règim d'autònoms és diferent.

<BarChart
    data={autonomos_tipo}
    x=anio
    y=pct
    series=tipo
    type=stacked
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% dels ocupats"
    colorPalette={['#1d4ed8', '#94a3b8', '#60a5fa']}
    title="Treballadors per compte propi en % dels ocupats (mitjana anual)"
/>

```sql autonomos_ccaa
SELECT
    t.nombre AS comunidad,
    '/ca' || t.ruta AS ruta,
    a.cod,
    a.pct_cuenta_propia,
    a.pct_empleadores,
    a.cuenta_propia,
    CAST(a.anio AS INTEGER) AS anio
FROM mother.empresas_autonomos a
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = a.cod
WHERE a.trimestre = 0 AND a.anio = (SELECT max(anio) FROM mother.empresas_autonomos WHERE trimestre = 0)
ORDER BY a.pct_cuenta_propia DESC
```

El {autonomos_ccaa[0]?.anio}, {autonomos_ccaa[0]?.comunidad} tenia la proporció més alta de treballadors per compte propi ({formatNumber(autonomos_ccaa[0]?.pct_cuenta_propia, 1)} % dels ocupats) i {autonomos_ccaa.slice(-1)[0]?.comunidad} la més baixa ({formatNumber(autonomos_ccaa.slice(-1)[0]?.pct_cuenta_propia, 1)} %).

<BarChart
    data={autonomos_ccaa}
    x=comunidad
    y=pct_cuenta_propia
    swapXY=true
    yFmt='0.0"%"'
    title="Treballadors per compte propi, % dels ocupats ({autonomos_ccaa[0]?.anio})"
/>

## Recerca i desenvolupament (R+D)

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

La despesa en R+D inclou el que investiguen les empreses, les administracions, les universitats i les entitats sense ànim de lucre, i es mesura en percentatge del PIB. El {id_ue_ult[0]?.anio}, Espanya va gastar el {formatNumber(id_ue_ult[0]?.es, 2)} % del PIB, davant del {formatNumber(id_ue_ult[0]?.ue, 2)} % de la UE-27, i ocupava el lloc {id_rank[0]?.puesto} dels {id_rank[0]?.paises} països de la Unió.

<BarChart
    data={id_paises}
    x=pais
    y=pct_pib
    series=grupo
    swapXY=true
    yFmt='0.00"%"'
    colorPalette={['#dc2626', '#94a3b8', '#1d4ed8']}
    title="Despesa en R+D en % del PIB ({id_paises[0]?.anio})"
/>

Amb la crisi la despesa va retrocedir: del {formatNumber(id_hitos[0]?.p_max, 2)} % del PIB el {id_hitos[0]?.anio_pmax} al {formatNumber(id_hitos[0]?.p_min, 2)} % el {id_hitos[0]?.anio_min}. Descomptada la inflació, va baixar de {formatNumber(id_hitos[0]?.h_max, 0)} € per habitant el {id_hitos[0]?.anio_hmax} a {formatNumber(id_hitos[0]?.h_min, 0)} € el {id_hitos[0]?.anio_hmin}, i el {id_hitos[0]?.anio_ult} va ser de {formatNumber(id_hitos[0]?.h_ult, 0)} € (euros de {id_es.slice(-1)[0]?.anio_euros}).

<LineChart
    data={id_evol}
    x=anio
    y=pct_pib
    series=pais
    xFmt='0'
    yFmt='0.00"%"'
    yAxisTitle="% del PIB"
    title="Despesa en R+D en % del PIB: Espanya i altres països"
/>

<LineChart
    data={id_es}
    x=anio
    y=eur_hab_real
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per habitant"
    title="Despesa en R+D per habitant a Espanya, euros de {id_es.slice(-1)[0]?.anio_euros}"
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

Qui executa la despesa. El {id_sector_ue[0]?.anio}, les empreses van gastar en R+D el {formatNumber(id_sector_ue[0]?.es_emp, 2)} % del PIB a Espanya i el {formatNumber(id_sector_ue[0]?.ue_emp, 2)} % a la UE-27; les administracions, el {formatNumber(id_sector_ue[0]?.es_aapp, 2)} % davant del {formatNumber(id_sector_ue[0]?.ue_aapp, 2)} %, i les universitats, el {formatNumber(id_sector_ue[0]?.es_uni, 2)} % davant del {formatNumber(id_sector_ue[0]?.ue_uni, 2)} %. La diferència amb Europa és sobretot a les empreses.

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
    title="Despesa en R+D a Espanya per sector que l'executa, % del PIB"
/>

```sql inv_evol
SELECT CAST(anio AS INTEGER) AS anio, pais, investigadores_1000ocup
FROM mother.empresas_id_paises
WHERE sector = 'Total' AND geo IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT') AND investigadores_1000ocup IS NOT NULL AND anio >= 2005
ORDER BY anio, pais
```

Investigadors en equivalència a jornada completa per cada 1.000 ocupats: {formatNumber(id_ue_ult[0]?.es_inv, 1)} a Espanya i {formatNumber(id_ue_ult[0]?.ue_inv, 1)} a la UE-27 el {id_ue_ult[0]?.anio}.

<LineChart
    data={inv_evol}
    x=anio
    y=investigadores_1000ocup
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="per 1.000 ocupats"
    title="Investigadors (jornada completa) per 1.000 ocupats"
/>

```sql id_ccaa
SELECT
    t.nombre AS comunidad,
    '/ca' || t.ruta AS ruta,
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

Per comunitat, el {id_ccaa[0]?.anio} (últim any amb dades regionals). {id_ccaa[0]?.comunidad} va dedicar a R+D el {formatNumber(id_ccaa[0]?.pct_pib, 2)} % del seu PIB i {id_ccaa.slice(-1)[0]?.comunidad} el {formatNumber(id_ccaa.slice(-1)[0]?.pct_pib, 2)} %.

<AreaMap
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
    attribution="Tessel·les © Esri · Límits © Institut Geogràfic Nacional · Dades: Eurostat / INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_pib', title: 'R+D, % del PIB', fmt: '0.00"%"'},
        {id: 'eur_hab_real', title: '€ per habitant', fmt: '#,##0'}
    ]}
/>

<DataTable data={id_ccaa} rows=20 link=ruta>
    <Column id=comunidad title="Comunitat"/>
    <Column id=pct_pib title="R+D (% del PIB)" fmt='0.00'/>
    <Column id=pct_pib_empresas title="D'això, empreses (% del PIB)" fmt='0.00'/>
    <Column id=eur_hab_real title="€ per habitant (reals)" fmt='#,##0'/>
    <Column id=investigadores_1000ocup title="Investigadors per 1.000 ocupats" fmt='0.0'/>
</DataTable>

La producció de les empreses per sector és a [Sectors](/ca/economia/sectores) i els salaris a [Salaris](/ca/economia/salarios).

---

**Fonts:** INE, [Directori Central d'Empreses (DIRCE)](https://www.ine.es/dyngs/INEbase/operacion.htm?c=Estadistica_C&cid=1254736160707&idp=1254735576550), taules [302](https://www.ine.es/jaxiT3/Tabla.htm?t=302) (empreses per província des del 1999) i [39372](https://www.ine.es/jaxiT3/Tabla.htm?t=39372) (per comunitat, activitat i assalariats); [Estadística de Societats Mercantils, taula 13912](https://www.ine.es/jaxiT3/Tabla.htm?t=13912); [Estadística del Procediment Concursal, taula 2992](https://www.ine.es/jaxiT3/Tabla.htm?t=2992); [EPA, ocupats per situació professional, taula 65316](https://www.ine.es/jaxiT3/Tabla.htm?t=65316). Eurostat: despesa en R+D [rd_e_gerdtot](https://ec.europa.eu/eurostat/databrowser/view/rd_e_gerdtot/default/table) i [rd_e_gerdreg](https://ec.europa.eu/eurostat/databrowser/view/rd_e_gerdreg/default/table), investigadors [rd_p_perslf](https://ec.europa.eu/eurostat/databrowser/view/rd_p_perslf/default/table) i [rd_p_persreg](https://ec.europa.eu/eurostat/databrowser/view/rd_p_persreg/default/table) (elaborats amb l'Estadística sobre Activitats d'R+D de l'INE), empreses per mida [sbs_sc_ovw](https://ec.europa.eu/eurostat/databrowser/view/sbs_sc_ovw/default/table) i altes i fallides [sts_rb_q](https://ec.europa.eu/eurostat/databrowser/view/sts_rb_q/default/table). Població: padró de l'INE. Euros constants amb l'IPC general de l'INE (base 2025).
