---
title: Isuriak eta deskarbonizazioa
description: "Espainiako berotegi-efektuko gasen (BEG) isuri ofizialak 1990etik, biztanleko, BPG errealaren euro bakoitzeko eta sektoreka, 2030eko helburuekin eta Europako batez bestekoarekin alderatuta."
i18n_origen: 100c2894f1bf
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import DownloadCsvButton from '../../../../../../../src/lib/components/DownloadCsvButton.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql anual
SELECT *
FROM mother.clima_emisiones_anual
ORDER BY anio
```

```sql kpi
WITH a AS (
    SELECT *, lag(t_hab) OVER (ORDER BY anio) AS t_hab_prev, lag(total_mt) OVER (ORDER BY anio) AS total_prev
    FROM mother.clima_emisiones_anual
)
SELECT
    CAST(anio AS INTEGER) AS anio,
    provisional,
    fuente,
    t_hab,
    total_mt,
    netas_mt,
    var_1990_pct,
    var_2005_pct,
    100 * (t_hab / t_hab_prev - 1) AS t_hab_var,
    100 * (total_mt / total_prev - 1) AS total_var
FROM a
WHERE anio = (SELECT max(anio) FROM mother.clima_emisiones_anual)
```

```sql hitos
SELECT
    max(total_mt) FILTER (WHERE anio = 1990) AS mt_1990,
    max(t_hab) FILTER (WHERE anio = 1990) AS t_hab_1990,
    max(total_mt) AS mt_max,
    CAST(arg_max(anio, total_mt) AS INTEGER) AS anio_max,
    max(t_hab) AS t_hab_max,
    CAST(arg_max(anio, t_hab) AS INTEGER) AS anio_t_hab_max,
    0.68 * max(total_mt) FILTER (WHERE anio = 1990) AS objetivo_pniec_mt,
    100 * (0.68 * max(total_mt) FILTER (WHERE anio = 1990) / arg_max(total_mt, anio) - 1) AS falta_pniec_pct,
    CAST(max(anio) FILTER (WHERE NOT provisional) AS INTEGER) AS anio_def
FROM mother.clima_emisiones_anual
```

```sql intensidad
SELECT
    CAST(anio AS INTEGER) AS anio,
    kg_por_euro,
    pib_real_hab,
    provisional,
    100 * (kg_por_euro / first_value(kg_por_euro) OVER (ORDER BY anio) - 1) AS var_desde_inicio,
    CAST(first_value(anio) OVER (ORDER BY anio) AS INTEGER) AS anio_inicio
FROM mother.clima_emisiones_anual
WHERE kg_por_euro IS NOT NULL
ORDER BY anio
```

```sql ue_ratio
SELECT
    CAST(anio AS INTEGER) AS anio,
    t_hab,
    t_hab_ue,
    100 * t_hab / t_hab_ue AS pct_ue
FROM mother.clima_emisiones_anual
WHERE t_hab_ue IS NOT NULL
ORDER BY anio
```

```sql hab_largo
SELECT anio, 'España (sin LULUCF)' AS serie, t_hab AS t FROM mother.clima_emisiones_anual
UNION ALL
SELECT anio, 'Media UE-27 (sin LULUCF)' AS serie, t_hab_ue AS t FROM mother.clima_emisiones_anual WHERE t_hab_ue IS NOT NULL
UNION ALL
SELECT anio, 'España, emisiones netas (con sumideros LULUCF)' AS serie, t_hab_netas AS t FROM mother.clima_emisiones_anual
ORDER BY anio, serie
```

```sql indice_1990
SELECT anio, 100 * total_mt / (SELECT total_mt FROM mother.clima_emisiones_anual WHERE anio = 1990) AS indice
FROM mother.clima_emisiones_anual
ORDER BY anio
```

```sql desacople
WITH b AS (
    SELECT * FROM mother.clima_emisiones_anual WHERE kg_por_euro IS NOT NULL
), base AS (
    SELECT * FROM b WHERE anio = (SELECT min(anio) FROM b)
)
SELECT b.anio, 'PIB real por habitante' AS serie, 100 * b.pib_real_hab / base.pib_real_hab AS indice FROM b, base
UNION ALL
SELECT b.anio, 'Emisiones por habitante' AS serie, 100 * b.t_hab / base.t_hab AS indice FROM b, base
UNION ALL
SELECT b.anio, 'Emisiones por euro de PIB' AS serie, 100 * b.kg_por_euro / base.kg_por_euro AS indice FROM b, base
ORDER BY anio, serie
```

```sql sectores
SELECT anio, sector, kg_hab, mt_co2eq, pct_total, provisional
FROM mother.clima_emisiones_sectores
ORDER BY anio, sector
```

```sql sectores_tabla
SELECT
    s.sector,
    max(s.kg_hab) FILTER (WHERE s.anio = 1990) AS kg_1990,
    max(s.kg_hab) FILTER (WHERE s.anio = 2005) AS kg_2005,
    max(s.kg_hab) FILTER (WHERE s.anio = u.anio) AS kg_ult,
    max(s.mt_co2eq) FILTER (WHERE s.anio = u.anio) AS mt_ult,
    max(s.pct_total) FILTER (WHERE s.anio = u.anio) / 100.0 AS peso_ult,
    max(s.mt_co2eq) FILTER (WHERE s.anio = u.anio) / max(s.mt_co2eq) FILTER (WHERE s.anio = 1990) - 1 AS var_1990
FROM mother.clima_emisiones_sectores s
CROSS JOIN (SELECT max(anio) AS anio FROM mother.clima_emisiones_sectores) u
GROUP BY s.sector
ORDER BY kg_ult DESC
```

```sql transporte
SELECT
    CAST(u.anio AS INTEGER) AS anio_ult,
    max(s.pct_total) FILTER (WHERE s.sector = 'Transporte' AND s.anio = u.anio) AS pct_transporte,
    100 * (max(s.mt_co2eq) FILTER (WHERE s.sector = 'Transporte' AND s.anio = u.anio) / max(s.mt_co2eq) FILTER (WHERE s.sector = 'Transporte' AND s.anio = 1990) - 1) AS var_transporte,
    100 * (max(s.mt_co2eq) FILTER (WHERE s.sector = 'Generación Eléctrica' AND s.anio = u.anio) / max(s.mt_co2eq) FILTER (WHERE s.sector = 'Generación Eléctrica' AND s.anio = 1990) - 1) AS var_electrica,
    100 * (max(s.mt_co2eq) FILTER (WHERE s.sector = 'Generación Eléctrica' AND s.anio = u.anio) / max(s.mt_co2eq) FILTER (WHERE s.sector = 'Generación Eléctrica' AND s.anio = 2005) - 1) AS var_electrica_2005
FROM mother.clima_emisiones_sectores s
CROSS JOIN (SELECT max(anio) AS anio FROM mother.clima_emisiones_sectores) u
GROUP BY u.anio
```

```sql transporte_vs_electrica
SELECT anio, sector, kg_hab
FROM mother.clima_emisiones_sectores
WHERE sector IN ('Transporte', 'Generación Eléctrica')
ORDER BY anio, sector
```

```sql paises
SELECT anio, nombre, t_hab
FROM mother.clima_emisiones_paises
ORDER BY anio, nombre
```

```sql paises_ult
SELECT
    CAST(anio AS INTEGER) AS anio,
    nombre,
    t_hab,
    var_1990_pct / 100.0 AS var_1990,
    mt_co2eq,
    CASE WHEN geo = 'ES' THEN 'España' WHEN geo = 'EU27_2020' THEN 'UE-27' ELSE 'Otros' END AS grupo
FROM mother.clima_emisiones_paises
WHERE anio = (SELECT max(anio) FROM mother.clima_emisiones_paises)
ORDER BY t_hab DESC
```

```sql paises_rank
WITH u AS (
    SELECT * FROM mother.clima_emisiones_paises
    WHERE anio = (SELECT max(anio) FROM mother.clima_emisiones_paises)
), es AS (
    SELECT t_hab AS t_es, var_1990_pct AS var_es FROM u WHERE geo = 'ES'
)
SELECT
    CAST(max(u.anio) AS INTEGER) AS anio,
    count(*) FILTER (WHERE u.geo NOT IN ('ES', 'EU27_2020') AND u.t_hab < es.t_es) AS menos_que_es,
    max(u.var_1990_pct) FILTER (WHERE u.geo = 'EU27_2020') AS var_ue,
    max(es.var_es) AS var_es
FROM u CROSS JOIN es
```

# 🏭 Berotegi-efektuko gasen isuriak Espainian

Zenbat berotegi-efektuko gas isurtzen duen Espainiak 1990etik, klima-konpromisoen erreferentzia-urtetik, **biztanleko** eta **BPG errealaren euro bakoitzeko** neurtuta, biztanleriaren eta ekonomiaren hazkundeak alderaketa distortsiona ez dezan. MITECOk Nazio Batuei eta EBri jakinarazten dien inbentario ofizialaren zifrak dira, lurzoru-erabileren eta basoen hustubideak (LULUCF) kontuan hartu gabe, besterik adierazten den lekuetan izan ezik.{#if kpi[0]?.provisional} {kpi[0]?.anio}. urteko datua MITECOren **behin-behineko aurrerapena** da; behin betiko zifra inbentarioaren hurrengo edizioarekin iritsiko da.{/if}

<Grid cols=4>
    <KpiCard
        title="Isuriak biztanleko"
        value={kpi[0]?.t_hab}
        formattedValue="{formatNumber(kpi[0]?.t_hab, 2)} t CO₂eq"
        period="{kpi[0]?.anio}{kpi[0]?.provisional ? ' (behin-behineko aurrerapena)' : ''} · {formatNumber(kpi[0]?.total_mt, 1)} Mt guztira"
        change={kpi[0]?.t_hab_var?.toFixed(1)}
        changePeriod="aurreko urtearekin alderatuta"
        direction="positive-down"
        source="MITECO / Eurostat"
        sparklineData={anual.map(d => ({...d, y: d.t_hab}))}
    />
    <KpiCard
        title="1990arekin alderatuta"
        value={kpi[0]?.var_1990_pct}
        formattedValue="{kpi[0]?.var_1990_pct >= 0 ? '+' : ''}{formatNumber(kpi[0]?.var_1990_pct, 1)} %"
        period="isuri guztiak, {kpi[0]?.anio}. urtean · {formatNumber(kpi[0]?.var_2005_pct, 1)} % 2005arekin alderatuta"
        direction="positive-down"
        source="MITECO / Eurostat"
        sparklineData={anual.map(d => ({...d, y: d.var_1990_pct}))}
    />
    <KpiCard
        title="Ekonomiaren intentsitatea"
        value={intensidad.slice(-1)[0]?.kg_por_euro}
        formattedValue="{formatNumber(intensidad.slice(-1)[0]?.kg_por_euro * 1000, 0)} g CO₂eq/€"
        period="BPG errealaren euro bakoitzeko (euro konstanteetan), {intensidad.slice(-1)[0]?.anio}. urtean"
        change={intensidad.slice(-1)[0]?.var_desde_inicio?.toFixed(0)}
        changePeriod="{intensidad[0]?.anio}. urteaz geroztik"
        direction="positive-down"
        source="Eurostat"
        sparklineData={intensidad.map(d => ({...d, y: d.kg_por_euro}))}
    />
    <KpiCard
        title="Espainia EBrekin alderatuta"
        value={ue_ratio.slice(-1)[0]?.pct_ue}
        formattedValue="batez bestekoaren {formatNumber(ue_ratio.slice(-1)[0]?.pct_ue, 0)} %"
        period="biztanleko, {ue_ratio.slice(-1)[0]?.anio}. urtean: {formatNumber(ue_ratio.slice(-1)[0]?.t_hab, 1)} t, EB-27ko {formatNumber(ue_ratio.slice(-1)[0]?.t_hab_ue, 1)} t-ren aldean"
        direction="positive-down"
        source="Eurostat"
        sparklineData={ue_ratio.map(d => ({...d, y: d.pct_ue}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('gei_pc')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'gei_pc')} />


## Isuriak biztanleko 1990etik

Espainiar batek {formatNumber(hitos[0]?.t_hab_1990, 1)} t CO₂ baliokide isurtzen zituen 1990ean; maximoa {formatNumber(hitos[0]?.t_hab_max, 1)} t izan zen, {hitos[0]?.anio_t_hab_max}. urtean, eta {kpi[0]?.anio}. urtean {formatNumber(kpi[0]?.t_hab, 1)} t dira. Isuri garbien lerroak basoek eta lurzoruek xurgatzen duten CO₂a kentzen du (LULUCF). Europako batez bestekoa behin betiko inbentarioaren azken urtera arte baino ez da iristen.

<LineChart
    data={hab_largo}
    x=anio
    y=t
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="t CO₂eq biztanleko"
    title="BEG isuriak biztanleko: Espainia eta EB-27"
    colorPalette={['#dc2626', '#16a34a', '#2563eb']}
/>

<DownloadCsvButton data={anual} filename="spainfacts_emisiones_gei_anual.csv" label="Deskargatu urteko seriea (CSV)" />

## 2030eko helburutik urrun

Isuri guztiek gailurra jo zuten {hitos[0]?.anio_max}. urtean ({formatNumber(hitos[0]?.mt_max, 0)} Mt), eta {kpi[0]?.anio}. urtean {formatNumber(Math.abs(kpi[0]?.var_1990_pct), 1)} % {#if kpi[0]?.var_1990_pct < 0}beherago{:else}gorago{/if} daude 1990ekoen aldean. Energia eta Klimaren Plan Nazional Integratuak (PNIEC 2023-2030) 32 %-ko murrizketa ezartzen du 1990arekiko 2030erako, {formatNumber(hitos[0]?.objetivo_pniec_mt, 0)} Mt inguru: {kpi[0]?.anio}. urteko mailatik, beste {formatNumber(Math.abs(hitos[0]?.falta_pniec_pct), 0)} % murriztu beharko litzateke.

<LineChart
    data={indice_1990}
    x=anio
    y=indice
    xFmt='0'
    yFmt='0'
    yAxisTitle="1990 = 100"
    title="BEG isuri guztiak (indizea, 1990 = 100)"
    colorPalette={['#dc2626']}
>
    <ReferenceLine y=68 label="PNIEC 2030 helburua (-32 %)" color="#16a34a" />
    <ReferenceLine y=100 label="1990eko maila" color="#6b7280" />
</LineChart>

## Hazi, gutxiago isurita

{intensidad[0]?.anio}. urteaz geroztik, biztanleko BPG errealak eta biztanleko isuriek bide desberdinak hartu dituzte: BPG errealaren euro bakoitza gaur {formatNumber(Math.abs(intensidad.slice(-1)[0]?.var_desde_inicio), 0)} % {#if intensidad.slice(-1)[0]?.var_desde_inicio < 0}isuri gutxiagorekin{:else}isuri gehiagorekin{/if} ekoizten da hasierako urtean baino. BPG euro konstanteetan neurtzen da, inflazioa kenduta.

<LineChart
    data={desacople}
    x=anio
    y=indice
    series=serie
    xFmt='0'
    yFmt='0'
    yAxisTitle="{intensidad[0]?.anio} = 100"
    title="BPG erreala eta isuriak biztanleko (indizea, {intensidad[0]?.anio} = 100)"
    colorPalette={['#16a34a', '#dc2626', '#2563eb']}
/>

## Nork isurtzen du? Isuriak sektoreka

CO₂ baliokidearen kiloak biztanleko eta urteko, isurtzen dituen sektorearen arabera.

<AreaChart
    data={sectores}
    x=anio
    y=kg_hab
    series=sector
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kg CO₂eq biztanleko"
    title="BEG isuriak sektoreka eta biztanleko"
/>

<DataTable data={sectores_tabla} search=false rows=10>
    <Column id=sector title="Sektorea" />
    <Column id=kg_1990 title="kg/biz. 1990" fmt="#,##0" />
    <Column id=kg_2005 title="kg/biz. 2005" fmt="#,##0" />
    <Column id=kg_ult title="kg/biz. azken urtea" fmt="#,##0" />
    <Column id=peso_ult title="Guztizkoaren %" fmt="pct1" contentType=colorscale colorScale={['#fef3c7', '#dc2626']} />
    <Column id=var_1990 title="Guztira 1990arekiko" fmt="pct0" contentType=delta downIsGood=true />
    <Column id=mt_ult title="Mt azken urtea" fmt="num1" />
</DataTable>

<DownloadCsvButton data={sectores} filename="spainfacts_emisiones_gei_sectorial.csv" label="Deskargatu isuriak sektoreka (CSV)" />

## Garraioa, jaisten ez den sektorea

Garraioak isurien **{formatNumber(transporte[0]?.pct_transporte, 1)} %** biltzen du {transporte[0]?.anio_ult}. urtean, eta {formatNumber(Math.abs(transporte[0]?.var_transporte), 0)} % {#if transporte[0]?.var_transporte >= 0}gehiago{:else}gutxiago{/if} isurtzen du 1990ean baino. Sorkuntza elektrikoak, aldiz, {formatNumber(Math.abs(transporte[0]?.var_electrica), 0)} % {#if transporte[0]?.var_electrica < 0}gutxiago{:else}gehiago{/if} isurtzen du 1990ean baino, eta {formatNumber(Math.abs(transporte[0]?.var_electrica_2005), 0)} % {#if transporte[0]?.var_electrica_2005 < 0}gutxiago{:else}gehiago{/if} 2005ean baino. Xehetasun gehiago [elektrizitate-mixean](/eu/energia-clima/mix-electrico).

<LineChart
    data={transporte_vs_electrica}
    x=anio
    y=kg_hab
    series=sector
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kg CO₂eq biztanleko"
    title="Garraioa sorkuntza elektrikoarekin alderatuta (kg biztanleko)"
    colorPalette={['#16a34a', '#f97316']}
/>

## Espainia Europan

Isuriak biztanleko LULUCF gabe, herrialde bakoitzaren behin betiko inbentarioekin. {paises_rank[0]?.anio}. urtean, alderatutako sei herrialde handietatik {paises_rank[0]?.menos_que_es}k isurtzen zuten Espainiak baino gutxiago biztanleko. 1990etik, Espainiaren isuri guztiak {formatNumber(paises_rank[0]?.var_es, 1)} % aldatu dira, EB-27 osoaren {formatNumber(paises_rank[0]?.var_ue, 1)} %-aren aldean.

<BarChart
    data={paises_ult}
    x=nombre
    y=t_hab
    series=grupo
    swapXY=true
    yFmt='0.0'
    yAxisTitle="t CO₂eq biztanleko"
    title="Isuriak biztanleko, {paises_ult[0]?.anio}. urtean"
    colorPalette={['#dc2626', '#94a3b8', '#2563eb']}
/>

<LineChart
    data={paises}
    x=anio
    y=t_hab
    series=nombre
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="t CO₂eq biztanleko"
    title="Biztanleko isurien bilakaera"
/>

<DataTable data={paises_ult} search=false rows=10>
    <Column id=nombre title="Herrialdea" />
    <Column id=t_hab title="t CO₂eq/biz." fmt="num1" />
    <Column id=var_1990 title="Isuri guztiak 1990arekiko" fmt="pct0" contentType=delta downIsGood=true />
    <Column id=mt_co2eq title="Mt guztira" fmt="num0" />
</DataTable>

## Murrizketa-helburuak

| Epea | Helburua | Erreferentzia |
|:---|:---|:---|
| **2030 (Espainia)** | Isurien -32 % 1990arekiko | PNIEC 2023-2030 |
| **2030 (Espainia, sektore lausoak)** | -37,7 % 2005arekiko garraioan, eraikinetan, nekazaritzan, hondakinetan eta gas fluordunetan (isuri-eskubideen merkataritzatik kanpo) | Ahalegin-banaketari buruzko Erregelamendua, (EB) 2023/857 |
| **2030 (EB)** | Isuri garbien -55 % 1990arekiko | Klimari buruzko Europako Legea, (EB) 2021/1119 Erregelamendua |
| **2050** | Neutraltasun klimatikoa (isuri garbi nuluak) | Klima-aldaketari buruzko 7/2021 Legea eta Klimari buruzko Europako Legea |

---

## Iturriak

- **BEG Isurien Inbentario Nazionala (MITECO)**, Nazio Batuen Klima Aldaketari buruzko Esparru Hitzarmenari jakinarazia, Eurostaten [env_air_gge](https://ec.europa.eu/eurostat/databrowser/view/env_air_gge/default/table) taulatik deskargatua CRF kategoriaka. Metodologia: IPCCren 2006ko jarraibideak. [MITECO – Inbentarioa](https://www.miteco.gob.es/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/inventario-gases-efecto-invernadero.html).
- Azken urteko **inbentarioaren aurrerapena** (behin-behinekoa): [MITECO, 2025eko BEG isurien aurrerapen-oharra](https://www.miteco.gob.es/content/dam/miteco/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/Nota-Avance-GEI-2025.pdf) (2026ko uztaila). Eurostatek argitaratzen duenean, behin betiko zifrarekin ordezkatzen da.
- **Urteko batez besteko biztanleria**: Eurostat [demo_gind](https://ec.europa.eu/eurostat/databrowser/view/demo_gind/default/table). **BPG erreala biztanleko**: Eurostat [nama_10_pc](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table), euro konstanteetan (ikus [BPG biztanleko](/eu/economia)).
- Sektoreka multzokatzea: Sorkuntza elektrikoa = 1A1a; Garraioa = 1A3 (nazionala, nazioarteko bunkerrik gabe); Industria eta prozesuak = 1A1b-c + 1A2 + 1B + 2 (2F eta 2G izan ezik); Egoitzak eta merkataritza = 1A4a-b; Nekazaritza eta abeltzaintza = 3 + 1A4c; Hondakinak = 5; Gas fluordunak eta bestelakoak = 2F + 2G + 1A5 + 6.

<LastRefreshed prefix="Datuen azken sinkronizazioa" />
