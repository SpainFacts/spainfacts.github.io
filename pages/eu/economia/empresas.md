---
title: Enpresak, ekintzailetza eta I+G
description: "Zenbat enpresa dauden Espainian biztanleko eta zer tamainatakoak, zenbat sozietate sortzen eta desegiten diren, hartzekodunen konkurtsoak, autonomoak eta I+Gko gastua Europarekin eta erkidegoka alderatuta."
i18n_origen: c23d9e81ee16
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

# 🏭 Enpresak, ekintzailetza eta I+G

Zenbat enpresa dauden Espainian eta zer tamainatakoak diren, zenbat sozietate sortzen diren eta zenbat ixten diren, zenbat langile diren autonomoak eta zenbat inbertitzen den ikerketan eta garapenean (I+G) Europarekin alderatuta. Zifrak biztanleko ematen dira, ehunekotan edo, eurotan badira, inflazioa kenduta.

<Grid cols=4>
    <KpiCard
        title="Enpresak 1.000 biztanleko"
        value={emp_hitos[0]?.e_ult}
        formattedValue={formatNumber(emp_hitos[0]?.e_ult, 1)}
        period="aktiboak {emp_hitos[0]?.anio_ult}. urteko urtarrilaren 1ean · {formatCompact(emp_hitos[0]?.empresas_ult, 2)} enpresa, autonomoak barne"
        change={(emp_hitos[0]?.e_ult - emp_hitos[0]?.e_ant)?.toFixed(1)}
        changeUnit=""
        changePeriod="aurreko urtearekin alderatuta"
        direction="positive-up"
        source="INE / DIRCE"
        sparklineData={emp_pais.map(d => d.empresas_1000hab)}
    />
    <KpiCard
        title="Sortutako sozietateak"
        value={soc_12m_ult[0]?.constituidas_12m_100k}
        formattedValue="{formatNumber(soc_12m_ult[0]?.constituidas_12m_100k, 0)} 100.000 biztanleko"
        period="12 hilabetean, {soc_12m_ult[0]?.mes_texto} arte · {formatNumber(soc_12m_ult[0]?.constituidas_12m, 0)} merkataritza-sozietate"
        change={soc_12m_ult[0]?.cambio_anual?.toFixed(1)}
        changePeriod="12 hilabete lehenagorekin alderatuta"
        direction="positive-up"
        source="INE / Merkataritza Sozietateak"
        sparklineData={soc_12m.slice(-120).map(d => d.constituidas_12m_100k)}
    />
    <KpiCard
        title="Autonomoak"
        value={autonomos_ult[0]?.pct_cuenta_propia}
        formattedValue="Landunen {formatNumber(autonomos_ult[0]?.pct_cuenta_propia, 1)} %"
        period="beren kontura ari dira lanean ({autonomos_ult[0]?.periodo}) · {formatNumber(autonomos_ult[0]?.cuenta_propia / 1000, 2)} milioi pertsona"
        direction="neutral"
        source="INE / EPA"
        sparklineData={autonomos_anual.map(d => d.pct_cuenta_propia)}
    />
    <KpiCard
        title="I+Gko gastua"
        value={id_ue_ult[0]?.es}
        formattedValue="BPGaren {formatNumber(id_ue_ult[0]?.es, 2)} %"
        period="{id_ue_ult[0]?.anio}. urtean · EB-27: {formatNumber(id_ue_ult[0]?.ue, 2)} % · {formatNumber(id_ue_ult[0]?.es_hab, 0)} € biztanleko ({id_es.slice(-1)[0]?.anio_euros}. urteko eurotan)"
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


## Zenbat enpresa dauden

```sql emp_ccaa
SELECT
    t.nombre AS comunidad,
    '/eu' || t.ruta AS ruta,
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

INEren Enpresen Direktorio Zentralak urtarrilaren 1ean zenbatzen ditu enpresa aktibo guztiak, autonomoak barne, nekazaritzakoak eta arrantzakoak, administrazioak eta etxeko zerbitzua izan ezik. {emp_hitos[0]?.anio_ult}. urtean {formatNumber(emp_hitos[0]?.e_ult, 1)} zeuden 1.000 biztanleko, 2008ko {formatNumber(emp_hitos[0]?.e2008, 1)}-en aldean. 2023an INE ekonomikoki aktiboak diren enpresak soilik zenbatzen hasi zen: urte horretako jaitsiera irizpide-aldaketa bat da (termino homogeneoetan enpresa kopurua 0,5 % hazi zen, INEren arabera).

<LineChart
    data={emp_pais}
    x=anio
    y=empresas_1000hab
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="enpresak 1.000 biztanleko"
    startingAtZero={false}
    title="Enpresa aktiboak 1.000 biztanleko"
/>

<BarChart
    data={emp_pais}
    x=anio
    y=pct_personas_fisicas
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="Enpresen %"
    title="Pertsona fisikoak diren enpresak (enpresa-jarduera duten autonomoak), guztizkoaren %"
/>

Erkidegoei dagokienez, {emp_ccaa[0]?.comunidad} erkidegoak du enpresa-dentsitaterik handiena, 1.000 biztanleko {formatNumber(emp_ccaa[0]?.empresas_1000hab, 1)} enpresarekin, eta {emp_ccaa.slice(-1)[0]?.comunidad} erkidegoak txikiena, {formatNumber(emp_ccaa.slice(-1)[0]?.empresas_1000hab, 1)} enpresarekin. Enpresak egoitza duten erkidegoan zenbatzen dira, ez establezimenduak dituzten tokian.

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
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'empresas_1000hab', title: 'Enpresak 1.000 biztanleko', fmt: '0.0'},
        {id: 'empresas', title: 'Enpresak', fmt: '#,##0'}
    ]}
/>

## Tamaina: ia denak oso txikiak dira

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

{tamano_resumen[0]?.anio}. urtean, enpresen {formatNumber(tamano_resumen[0]?.sin_asal, 1)} %-k ez zuen soldatapeko bakar bat ere, eta {formatNumber(tamano_resumen[0]?.hasta_9, 1)} %-k 10 baino gutxiago zituen. {formatNumber(tamano_resumen[0]?.medianas_grandes, 2)} %-k baino ez zituen 50 soldatapeko edo gehiago; enpresa handiak, 250 edo gehiagorekin, {formatNumber(tamano_resumen[0]?.grandes, 0)} ziren.

<BarChart
    data={tamano_es}
    x=tamano
    y=pct
    sort=false
    swapXY=true
    yFmt='0.00"%"'
    title="Enpresak soldatapeko kopuruaren arabera, guztizkoaren % ({tamano_es[0]?.anio})"
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

Europarekin alderatzeko, Eurostatek landunen arabera neurtzen du tamaina (jabeak barne) eta finantzak kanpoan uzten ditu. {tamano_ue_resumen[0]?.anio}. urtean, mikroenpresek (10 landun baino gutxiago) enpresa-enpleguaren {formatNumber(tamano_ue_resumen[0]?.es_micro, 1)} % ematen zuten Espainian, EB-27ko {formatNumber(tamano_ue_resumen[0]?.ue_micro, 1)} %-aren aldean; enpresa handiek, {formatNumber(tamano_ue_resumen[0]?.es_grandes, 1)} %, {formatNumber(tamano_ue_resumen[0]?.ue_grandes, 1)} %-aren aldean (Alemanian, {formatNumber(tamano_ue_resumen[0]?.de_grandes, 1)} %).

<BarChart
    data={tamano_ue}
    x=pais
    y=pct_empleo
    series=tamano
    type=stacked
    swapXY=true
    yFmt='0.0"%"'
    colorPalette={['#bfdbfe', '#60a5fa', '#2563eb', '#1e3a8a']}
    title="Enpresa-enpleguaren banaketa enpresaren tamainaren arabera ({tamano_ue[0]?.anio})"
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
    title="Balio erantsiaren banaketa enpresaren tamainaren arabera ({tamano_ue[0]?.anio})"
/>

## Zertan diharduten

```sql sector_es
SELECT sector, empresas, pct, por_1000_hab, CAST(anio AS INTEGER) AS anio
FROM mother.empresas_dirce_sector
WHERE cod = '00' AND anio = (SELECT max(anio) FROM mother.empresas_dirce_sector)
ORDER BY pct DESC
```

Enpresa aktiboak sektore handika, {sector_es[0]?.anio}. urtean. Enpresa gehien dituen sektorea hau da: {sector_es[0]?.sector}; guztizkoaren {formatNumber(sector_es[0]?.pct, 1)} %, 1.000 biztanleko {formatNumber(sector_es[0]?.por_1000hab, 1)}.

<BarChart
    data={sector_es}
    x=sector
    y=por_1000_hab
    swapXY=true
    yFmt='0.0'
    title="Enpresak 1.000 biztanleko, jardueraren arabera ({sector_es[0]?.anio})"
/>

## Sortzen eta desegiten diren sozietateak

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

Merkataritza Erregistroan inskribatutako eta desegindako merkataritza-sozietateak (batez ere mugatuak eta anonimoak), aurreko 12 hilabeteak batuta eta 100.000 biztanleko. {soc_hitos[0]?.anio_ult}. urtean {formatNumber(soc_hitos[0]?.c_ult, 0)} sortu ziren 100.000 biztanleko, 2006ko {formatNumber(soc_hitos[0]?.c2006, 0)} eta 2009ko {formatNumber(soc_hitos[0]?.c2009, 0)} sozietateen aldean; {formatNumber(soc_hitos[0]?.d_ult, 0)} desegin ziren 100.000 biztanleko, hau da, {formatNumber(soc_hitos[0]?.ratio_ult, 0)} sortutako 100 bakoitzeko. Autonomoak ez dira hemen agertzen.

<LineChart
    data={soc_largo}
    x=fecha
    y=valor
    series=tipo
    yFmt='0'
    yAxisTitle="100.000 biztanleko (12 hilabete)"
    colorPalette={['#2563eb', '#dc2626']}
    title="Azken 12 hilabeteetan sortutako eta desegindako merkataritza-sozietateak, 100.000 biztanleko"
/>

Sozietateak sortzen diren kapitala, inflazioa kenduta, jaitsi egin da: harpidetutako batez besteko kapitala {formatNumber(soc_hitos[0]?.cap_medio_ult, 0)} € izan zen {soc_hitos[0]?.anio_ult}. urtean, 2006ko {formatNumber(soc_hitos[0]?.cap_medio_2006, 0)} €-en aldean ({soc_anual.slice(-1)[0]?.anio_euros}. urteko eurotan). Batez bestekoa da: kapital handiko sozietate gutxi batzuek asko eragiten dute bertan.

<LineChart
    data={soc_anual.filter(d => d.capital_real_hab != null)}
    x=anio
    y=capital_real_hab
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ biztanleko"
    title="Sozietate berriek harpidetutako kapitala, {soc_anual.slice(-1)[0]?.anio_euros}. urteko eurotan biztanleko"
/>

```sql soc_ccaa
SELECT
    t.nombre AS comunidad,
    '/eu' || t.ruta AS ruta,
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

Erkidegoka, {soc_ccaa[0]?.anio}. urtean. Sozietate bakoitza bere egoitza soziala dagoen erkidegoan zenbatzen da.

<DataTable data={soc_ccaa} rows=20 link=ruta>
    <Column id=comunidad title="Erkidegoa"/>
    <Column id=constituidas_100k title="Sortuak 100.000 biztanleko" fmt='0'/>
    <Column id=disueltas_100k title="Desegindakoak 100.000 biztanleko" fmt='0'/>
    <Column id=saldo_100k title="Saldoa 100.000 biztanleko" fmt='0' contentType=delta/>
    <Column id=capital_real_hab title="Harpidetutako kapitala (€ biztanleko)" fmt='#,##0'/>
</DataTable>

## Hartzekodunen konkurtsoak

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

Hartzekodunen konkurtsoan sartzen diren enpresak eta pertsonak (lehengo porrota edo ordainketa-etendura), 1.000 enpresa aktiboko. 2007an {formatNumber(concursos_hitos[0]?.r2007, 2)} ziren, eta {concursos_hitos[0]?.anio_max}. urtean {formatNumber(concursos_hitos[0]?.r_max, 2)}. 2020an {formatNumber(concursos_hitos[0]?.r2020, 2)} izan ziren 1.000 enpresako ({formatNumber(concursos_hitos[0]?.h2020, 1)} 100.000 biztanleko). INEk ez du estatistika hau argitaratu 2020az geroztik.

<BarChart
    data={concursos}
    x=anio
    y=concursos_1000emp
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="1.000 enpresako"
    title="Konkurtsoan dauden zordunak 1.000 enpresa aktiboko (2005-2020)"
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

Azken joera ikusteko, Eurostaten porrot-deklarazioen indizea erabil daiteke; herrialde bakoitza bere buruarekin alderatzen du (2021 = 100), eta ez du herrialdeen arteko mailak alderatzeko balio. {quiebras_ult[0]?.periodo} aldian, Espainiako indizea {formatNumber(quiebras_ult[0]?.es, 0)} zen, eta EB-27koa {formatNumber(quiebras_ult[0]?.ue, 0)}.

<LineChart
    data={quiebras}
    x=fecha
    y=indice
    series=pais
    yFmt='0'
    yAxisTitle="indizea 2021 = 100"
    title="Porrot-deklarazioak (indizea 2021 = 100, urtaroko doikuntzarekin)"
/>

## Autonomoak

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

Biztanleria Aktiboaren Inkestak landun bakoitzari galdetzen dio bere kontura edo besteren kontura ari den lanean. Beren kontura ari diren langileen kopurua ez da asko aldatu ({formatNumber(autonomos_hitos[0]?.n2002 / 1000, 2)} milioi 2002an eta {formatNumber(autonomos_hitos[0]?.n_ult / 1000, 2)} milioi {autonomos_hitos[0]?.anio_ult}. urtean), baina soldatapeko enplegua gehiago hazi denez, haien pisua landunen {formatNumber(autonomos_hitos[0]?.p2002, 1)} %-tik {formatNumber(autonomos_hitos[0]?.p_ult, 1)} %-ra jaitsi da. Pertsonak dira, ez Gizarte Segurantzako altak: autonomoen araubideko afiliatuen kopurua bestelakoa da.

<BarChart
    data={autonomos_tipo}
    x=anio
    y=pct
    series=tipo
    type=stacked
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="Landunen %"
    colorPalette={['#1d4ed8', '#94a3b8', '#60a5fa']}
    title="Beren kontura ari diren langileak, landunen % (urteko batez bestekoa)"
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

{autonomos_ccaa[0]?.anio}. urtean, {autonomos_ccaa[0]?.comunidad} erkidegoak zuen beren kontura ari ziren langileen proportziorik handiena (landunen {formatNumber(autonomos_ccaa[0]?.pct_cuenta_propia, 1)} %), eta {autonomos_ccaa.slice(-1)[0]?.comunidad} erkidegoak txikiena ({formatNumber(autonomos_ccaa.slice(-1)[0]?.pct_cuenta_propia, 1)} %).

<BarChart
    data={autonomos_ccaa}
    x=comunidad
    y=pct_cuenta_propia
    swapXY=true
    yFmt='0.0"%"'
    title="Beren kontura ari diren langileak, landunen % ({autonomos_ccaa[0]?.anio})"
/>

## Ikerketa eta garapena (I+G)

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

I+Gko gastuak enpresek, administrazioek, unibertsitateek eta irabazi-asmorik gabeko erakundeek ikertzen dutena hartzen du barne, eta BPGaren ehunekotan neurtzen da. {id_ue_ult[0]?.anio}. urtean, Espainiak BPGaren {formatNumber(id_ue_ult[0]?.es, 2)} % gastatu zuen, EB-27ko {formatNumber(id_ue_ult[0]?.ue, 2)} %-aren aldean, eta Batasuneko {id_rank[0]?.paises} herrialdeen artean {id_rank[0]?.puesto}. postuan zegoen.

<BarChart
    data={id_paises}
    x=pais
    y=pct_pib
    series=grupo
    swapXY=true
    yFmt='0.00"%"'
    colorPalette={['#dc2626', '#94a3b8', '#1d4ed8']}
    title="I+Gko gastua, BPGaren % ({id_paises[0]?.anio})"
/>

Krisiarekin gastuak atzera egin zuen: BPGaren {formatNumber(id_hitos[0]?.p_max, 2)} % zen {id_hitos[0]?.anio_pmax}. urtean, eta {formatNumber(id_hitos[0]?.p_min, 2)} % {id_hitos[0]?.anio_min}. urtean. Inflazioa kenduta, biztanleko {formatNumber(id_hitos[0]?.h_max, 0)} € izatetik ({id_hitos[0]?.anio_hmax}. urtean) {formatNumber(id_hitos[0]?.h_min, 0)} € izatera jaitsi zen ({id_hitos[0]?.anio_hmin}. urtean), eta {id_hitos[0]?.anio_ult}. urtean {formatNumber(id_hitos[0]?.h_ult, 0)} € izan zen ({id_es.slice(-1)[0]?.anio_euros}. urteko eurotan).

<LineChart
    data={id_evol}
    x=anio
    y=pct_pib
    series=pais
    xFmt='0'
    yFmt='0.00"%"'
    yAxisTitle="BPGaren %"
    title="I+Gko gastua, BPGaren %: Espainia eta beste herrialde batzuk"
/>

<LineChart
    data={id_es}
    x=anio
    y=eur_hab_real
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ biztanleko"
    title="I+Gko gastua biztanleko Espainian, {id_es.slice(-1)[0]?.anio_euros}. urteko eurotan"
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

Nork egiten duen gastua. {id_sector_ue[0]?.anio}. urtean, enpresek BPGaren {formatNumber(id_sector_ue[0]?.es_emp, 2)} % gastatu zuten I+Gn Espainian, eta {formatNumber(id_sector_ue[0]?.ue_emp, 2)} % EB-27n; administrazioek, {formatNumber(id_sector_ue[0]?.es_aapp, 2)} %, {formatNumber(id_sector_ue[0]?.ue_aapp, 2)} %-aren aldean, eta unibertsitateek, {formatNumber(id_sector_ue[0]?.es_uni, 2)} %, {formatNumber(id_sector_ue[0]?.ue_uni, 2)} %-aren aldean. Europarekiko aldea batez ere enpresetan dago.

<BarChart
    data={id_sector}
    x=anio
    y=pct_pib
    series=sector
    type=stacked
    xFmt='0'
    yFmt='0.00"%"'
    yAxisTitle="BPGaren %"
    colorPalette={['#0f766e', '#1d4ed8', '#cbd5e1', '#f59e0b']}
    title="I+Gko gastua Espainian, gauzatzen duen sektorearen arabera, BPGaren %"
/>

```sql inv_evol
SELECT CAST(anio AS INTEGER) AS anio, pais, investigadores_1000ocup
FROM mother.empresas_id_paises
WHERE sector = 'Total' AND geo IN ('ES', 'EU27_2020', 'DE', 'FR', 'IT', 'PT') AND investigadores_1000ocup IS NOT NULL AND anio >= 2005
ORDER BY anio, pais
```

Ikertzaileak lanaldi osoko baliokidetan 1.000 landuneko: {formatNumber(id_ue_ult[0]?.es_inv, 1)} Espainian eta {formatNumber(id_ue_ult[0]?.ue_inv, 1)} EB-27n, {id_ue_ult[0]?.anio}. urtean.

<LineChart
    data={inv_evol}
    x=anio
    y=investigadores_1000ocup
    series=pais
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="1.000 landuneko"
    title="Ikertzaileak (lanaldi osoa) 1.000 landuneko"
/>

```sql id_ccaa
SELECT
    t.nombre AS comunidad,
    '/eu' || t.ruta AS ruta,
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

Erkidegoka, {id_ccaa[0]?.anio}. urtean (eskualde-datuak dituen azken urtea). {id_ccaa[0]?.comunidad} erkidegoak bere BPGaren {formatNumber(id_ccaa[0]?.pct_pib, 2)} % bideratu zuen I+Gra, eta {id_ccaa.slice(-1)[0]?.comunidad} erkidegoak {formatNumber(id_ccaa.slice(-1)[0]?.pct_pib, 2)} %.

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
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: Eurostat / INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct_pib', title: 'I+G, BPGaren %', fmt: '0.00"%"'},
        {id: 'eur_hab_real', title: '€ biztanleko', fmt: '#,##0'}
    ]}
/>

<DataTable data={id_ccaa} rows=20 link=ruta>
    <Column id=comunidad title="Erkidegoa"/>
    <Column id=pct_pib title="I+G (BPGaren %)" fmt='0.00'/>
    <Column id=pct_pib_empresas title="Horietatik, enpresak (BPGaren %)" fmt='0.00'/>
    <Column id=eur_hab_real title="€ biztanleko (errealak)" fmt='#,##0'/>
    <Column id=investigadores_1000ocup title="Ikertzaileak 1.000 landuneko" fmt='0.0'/>
</DataTable>

Enpresen ekoizpena sektoreka [Sektoreak](/eu/economia/sectores) atalean dago, eta soldatak [Soldatak](/eu/economia/salarios) atalean.

---

**Iturriak:** INE, [Enpresen Direktorio Zentrala (DIRCE)](https://www.ine.es/dyngs/INEbase/operacion.htm?c=Estadistica_C&cid=1254736160707&idp=1254735576550), [302](https://www.ine.es/jaxiT3/Tabla.htm?t=302) taula (enpresak probintziaka 1999tik) eta [39372](https://www.ine.es/jaxiT3/Tabla.htm?t=39372) taula (erkidegoaren, jardueraren eta soldatapekoen arabera); [Merkataritza Sozietateen Estatistika, 13912 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=13912); [Konkurtso Prozeduraren Estatistika, 2992 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=2992); [EPA, landunak egoera profesionalaren arabera, 65316 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=65316). Eurostat: I+Gko gastua [rd_e_gerdtot](https://ec.europa.eu/eurostat/databrowser/view/rd_e_gerdtot/default/table) eta [rd_e_gerdreg](https://ec.europa.eu/eurostat/databrowser/view/rd_e_gerdreg/default/table), ikertzaileak [rd_p_perslf](https://ec.europa.eu/eurostat/databrowser/view/rd_p_perslf/default/table) eta [rd_p_persreg](https://ec.europa.eu/eurostat/databrowser/view/rd_p_persreg/default/table) (INEren I+G Jardueren Estatistikarekin landuak), enpresak tamainaren arabera [sbs_sc_ovw](https://ec.europa.eu/eurostat/databrowser/view/sbs_sc_ovw/default/table) eta altak eta porrotak [sts_rb_q](https://ec.europa.eu/eurostat/databrowser/view/sts_rb_q/default/table). Biztanleria: INEren errolda. Euro konstanteak INEren KPI orokorrarekin (2025 oinarria).
