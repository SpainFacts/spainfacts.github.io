---
title: Soldatak
description: "Espainiako batez besteko soldata inflazioa kenduta, haren hazkunde erreala eta nominala, sektorearen eta lanaldiaren arabera, eta dezilen araberako banaketa."
i18n_origen: a16ce5b323ef
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql anual
SELECT *
FROM mother.economia_salarios_anual
WHERE jornada = 'Todas' AND sector = 'Total'
ORDER BY anio
```

```sql anual_largo
SELECT anio, 'Descontada la inflación' AS serie, salario_real AS salario FROM mother.economia_salarios_anual WHERE jornada = 'Todas' AND sector = 'Total'
UNION ALL
SELECT anio, 'Sin descontar (euros de cada año)' AS serie, salario_nominal AS salario FROM mother.economia_salarios_anual WHERE jornada = 'Todas' AND sector = 'Total'
ORDER BY anio, serie
```

```sql crecimientos
SELECT anio, 'Nominal' AS tipo, crecimiento_nominal AS crecimiento FROM mother.economia_salarios_anual WHERE jornada = 'Todas' AND sector = 'Total' AND crecimiento_nominal IS NOT NULL
UNION ALL
SELECT anio, 'Real' AS tipo, crecimiento_real AS crecimiento FROM mother.economia_salarios_anual WHERE jornada = 'Todas' AND sector = 'Total' AND crecimiento_real IS NOT NULL
ORDER BY anio, tipo
```

```sql trimestral
SELECT trimestre, CAST(anio AS INTEGER) || '-T' || CAST(trim AS INTEGER) AS periodo, salario_total, salario_total_real, interanual_nominal, interanual_real, anio_euros
FROM mother.economia_salarios
WHERE jornada = 'Todas' AND sector = 'Total'
ORDER BY trimestre
```

```sql interanual_largo
SELECT trimestre, 'Nominal' AS tipo, interanual_nominal AS variacion FROM mother.economia_salarios WHERE jornada = 'Todas' AND sector = 'Total' AND interanual_nominal IS NOT NULL
UNION ALL
SELECT trimestre, 'Real' AS tipo, interanual_real AS variacion FROM mother.economia_salarios WHERE jornada = 'Todas' AND sector = 'Total' AND interanual_real IS NOT NULL
ORDER BY trimestre, tipo
```

```sql por_sector
SELECT anio, sector, salario_real
FROM mother.economia_salarios_anual
WHERE jornada = 'Todas'
ORDER BY anio, sector
```

```sql por_jornada
SELECT anio, jornada, salario_real
FROM mother.economia_salarios_anual
WHERE sector = 'Total'
ORDER BY anio, jornada
```

```sql hitos_salario
SELECT
    max(CASE WHEN anio = 2008 THEN salario_real END) AS r2008,
    max(salario_real) FILTER (WHERE anio = (SELECT max(anio) FROM ${anual})) AS r_ult,
    max(salario_nominal) FILTER (WHERE anio = (SELECT max(anio) FROM ${anual})) AS n_ult,
    max(CASE WHEN anio = 2008 THEN salario_nominal END) AS n2008,
    100 * (max(salario_real) FILTER (WHERE anio = (SELECT max(anio) FROM ${anual})) / max(CASE WHEN anio = 2008 THEN salario_real END) - 1) AS real_vs2008,
    100 * (max(salario_nominal) FILTER (WHERE anio = (SELECT max(anio) FROM ${anual})) / max(CASE WHEN anio = 2008 THEN salario_nominal END) - 1) AS nominal_vs2008,
    max(salario_real) AS r_max,
    arg_max(anio, salario_real) AS anio_max,
    max(anio) AS anio_ult
FROM ${anual}
```

```sql deciles
SELECT
    d.anio,
    d.decil,
    'D' || d.decil AS nombre_decil,
    d.salario_mensual,
    d.salario_mensual * f.factor AS salario_real,
    f.anio_base
FROM mother.empleo_salarios_deciles d
JOIN mother.deflactor f ON f.anio = d.anio
WHERE d.jornada = 'Total' AND d.sector = 'Total' AND d.decil > 0
ORDER BY d.anio, d.decil
```

```sql deciles_ult
SELECT * FROM ${deciles} WHERE anio = (SELECT max(anio) FROM ${deciles}) ORDER BY decil
```

```sql deciles_evol
SELECT anio, CASE decil WHEN 1 THEN '10 % peor pagado (D1)' WHEN 5 THEN 'Mitad de la tabla (D5)' ELSE '10 % mejor pagado (D10)' END AS grupo, salario_real
FROM ${deciles}
WHERE decil IN (1, 5, 10)
ORDER BY anio, grupo
```

# 💶 Soldatak

Zenbat kobratzen den Espainian eta soldatak lehen baino gehiagorako edo gutxiagorako ematen duen. Zenbateko guztiak **langile bakoitzeko eta hileko soldata-kostu gordina** dira, aparteko ordainsariak hainbanatuta, eta **inflazioa kenduta** erakusten dira, {trimestral[0]?.anio_euros}. urteko eurotan.

<Grid cols=4>
    <KpiCard
        title="Batez besteko soldata"
        value={anual.slice(-1)[0]?.salario_real}
        formattedValue="{formatNumber(anual.slice(-1)[0]?.salario_real, 0)} €/hilean"
        period="gordina, {anual.slice(-1)[0]?.anio}. urtean · {formatNumber(anual.slice(-1)[0]?.salario_anual_real, 0)} € urtean"
        change={anual.slice(-1)[0]?.crecimiento_real?.toFixed(1)}
        changePeriod="erreala, aurreko urtearekin alderatuta"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={anual.map(d => d.salario_real)}
    />
    <KpiCard
        title="Azken hiruhilekoko igoera erreala"
        value={trimestral.slice(-1)[0]?.interanual_real}
        formattedValue="{trimestral.slice(-1)[0]?.interanual_real >= 0 ? '+' : ''}{formatNumber(trimestral.slice(-1)[0]?.interanual_real, 1)} %"
        period="{trimestral.slice(-1)[0]?.periodo}, duela urtebeterekin alderatuta · {formatNumber(trimestral.slice(-1)[0]?.interanual_nominal, 1)} % inflazioa kendu gabe"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={trimestral.filter(d => d.interanual_real != null).slice(-20).map(d => d.interanual_real)}
    />
    <KpiCard
        title="2008arekin alderatuta"
        value={hitos_salario[0]?.real_vs2008}
        formattedValue="{hitos_salario[0]?.real_vs2008 >= 0 ? '+' : ''}{formatNumber(hitos_salario[0]?.real_vs2008, 1)} %"
        period="batez besteko soldataren erosahalmena {hitos_salario[0]?.anio_ult}. urtean · +{formatNumber(hitos_salario[0]?.nominal_vs2008, 0)} % urte bakoitzeko eurotan"
        direction="positive-up"
        source="INE / ETCL"
        sparklineData={anual.map(d => d.salario_real)}
    />
    <KpiCard
        title="Erdiko dezilaren soldata"
        value={deciles_ult.find(d => d.decil === 5)?.salario_real}
        formattedValue="{formatNumber(deciles_ult.find(d => d.decil === 5)?.salario_real, 0)} €/hilean"
        period="soldatapeko tipikoak kobratzen duena (EPAren 5. dezila) {deciles_ult[0]?.anio}. urtean, {deciles_ult[0]?.anio_base}. urteko eurotan"
        source="INE / EPA"
        sparklineData={deciles.filter(d => d.decil === 5).map(d => d.salario_real)}
    />
</Grid>

## Batez besteko soldata, inflazioarekin eta inflaziorik gabe

Inflazioa kendu gabe, batez besteko soldata {formatNumber(hitos_salario[0]?.nominal_vs2008, 0)} % igo zen 2008tik {hitos_salario[0]?.anio_ult}. urtera bitartean. Inflazioa kenduta, batez besteko soldatak 2008an baino {#if hitos_salario[0]?.real_vs2008 < 0}{formatNumber(-hitos_salario[0]?.real_vs2008, 1)} % gutxiago{:else}{formatNumber(hitos_salario[0]?.real_vs2008, 1)} % gehiago{/if} erosten du, eta serieko gehieneko erreala {hitos_salario[0]?.anio_max}. urtekoa da.

<LineChart
    data={anual_largo}
    x=anio
    y=salario
    series=serie
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ gordin hilean"
    startingAtZero={false}
    title="Hileko batez besteko soldata: {trimestral[0]?.anio_euros}. urteko euroak eta urte bakoitzeko euroak"
/>

## Soldaten hazkundea

Batez besteko soldataren urteko igoera, inflazioa kenduta eta kendu gabe. Barra erreala negatiboa denean, soldatak aurreko urtean baino gutxiago erosten du, nahiz eta eurotan igo.

<BarChart
    data={crecimientos}
    x=anio
    y=crecimiento
    series=tipo
    type=grouped
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% urtean"
    title="Batez besteko soldataren urteko hazkundea: nominala eta erreala"
/>

<LineChart
    data={interanual_largo}
    x=trimestre
    y=variacion
    series=tipo
    yFmt='0.0"%"'
    yAxisTitle="% urtetik urtera"
    title="Soldataren urtetik urterako aldakuntza hiruhilekoka"
/>

## Sektorearen eta lanaldiaren arabera

Hileko batez besteko soldata {trimestral[0]?.anio_euros}. urteko eurotan. Sektoreen arteko aldearen zati bat zenbait sektorek lanaldi partzialeko enplegu askoz gehiago izateari zor zaio.

<LineChart
    data={por_sector}
    x=anio
    y=salario_real
    series=sector
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ hilean (errealak)"
    startingAtZero={false}
    title="Batez besteko soldata erreala sektoreka"
/>

<LineChart
    data={por_jornada}
    x=anio
    y=salario_real
    series=jornada
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ hilean (errealak)"
    title="Batez besteko soldata erreala lanaldi motaren arabera"
/>

```sql por_ccaa
SELECT
    s.cod,
    t.nombre AS comunidad,
    '/eu' || t.ruta AS ruta,
    s.salario_real,
    s.coste_laboral_real,
    s.crecimiento_real,
    s.indice_espana,
    100 * (s.salario_real / b.salario_real - 1) AS cambio_2008,
    CAST(s.anio AS INTEGER) AS anio,
    CAST(s.anio_euros AS INTEGER) AS anio_euros
FROM mother.economia_salarios_ccaa s
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = s.cod
LEFT JOIN mother.economia_salarios_ccaa b ON b.cod = s.cod AND b.anio = 2008
WHERE s.cod <> '00' AND s.anio = (SELECT max(anio) FROM mother.economia_salarios_ccaa)
ORDER BY s.salario_real DESC
```

## Autonomia-erkidegoen arabera

Hileko batez besteko soldata gordina {por_ccaa[0]?.anio}. urtean, {por_ccaa[0]?.anio_euros}. urteko eurotan. Zerrendaren buruan {por_ccaa[0]?.comunidad} dago, {formatNumber(por_ccaa[0]?.salario_real, 0)} €-rekin, eta azkenean {por_ccaa.slice(-1)[0]?.comunidad}, {formatNumber(por_ccaa.slice(-1)[0]?.salario_real, 0)} €-rekin. Bizi-kostuaren arabera zuzendu gabeko euroak dira, eta bizi-kostua ere aldatu egiten da erkidego batetik bestera. Ceuta eta Melilla ez dira bereiz argitaratzen.

<MapaEspana
    data={por_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="salario_real"
    valueFmt='#,##0" €"'
    link="ruta"
    colorPalette={['#fef3c7', '#f59e0b', '#92400e']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'salario_real', title: 'Batez besteko soldata', fmt: '#,##0" €"'},
        {id: 'indice_espana', title: 'Espainia = 100', fmt: '0.0'}
    ]}
/>

<DataTable data={por_ccaa} rows=20>
    <Column id=comunidad title="Erkidegoa"/>
    <Column id=salario_real title="Soldata (€/hilean)" fmt='#,##0'/>
    <Column id=indice_espana title="Espainia = 100" fmt='0.0'/>
    <Column id=crecimiento_real title="Azken urteko hazkunde erreala (%)" fmt='0.0' contentType=delta/>
    <Column id=cambio_2008 title="Erreala 2008tik (%)" fmt='0.0' contentType=delta/>
    <Column id=coste_laboral_real title="Enpresarentzako kostu osoa (€/hilean)" fmt='#,##0'/>
</DataTable>

## Nola banatzen den: dezilak

Soldata altuenek puzten dute batez bestekoa. EPAk soldatapeko guztiak soldata txikienetik handienera ordenatzen ditu eta hamar talde berdinetan banatzen ditu (dezilak); 5. dezila da soldata tipikoa. {deciles_ult[0]?.anio}. urteko datuak, inflazioa kenduta.

<BarChart
    data={deciles_ult}
    x=nombre_decil
    y=salario_real
    yFmt='#,##0" €"'
    yAxisTitle="€ gordin hilean"
    title="Dezil bakoitzaren batez besteko soldata {deciles_ult[0]?.anio}. urtean ({deciles_ult[0]?.anio_base}. urteko eurotan)"
/>

<LineChart
    data={deciles_evol}
    x=anio
    y=salario_real
    series=grupo
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ hilean (errealak)"
    title="Soldata baxuen, ertainen eta altuen bilakaera erreala"
/>

Soldata publikoak eta haien kostua [Enplegu publikoa](/eu/cuentas-publicas/empleo-publico) atalean daude.

---

**Iturriak:** [INE, Lan Kostuaren Hiruhileko Inkesta, 6038 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=6038) (langile bakoitzeko eta hileko soldata-kostua industrian, eraikuntzan eta zerbitzuetan; urteko batez bestekoa lau hiruhilekoena da) eta [INE, EPA, soldatak dezilka, 66250 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=66250); erkidegoka, [ETCL, 6061 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=6061). INEren KPI orokorrarekin deflaktatuta (2025 oinarria).
