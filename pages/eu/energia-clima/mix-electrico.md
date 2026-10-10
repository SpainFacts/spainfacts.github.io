---
title: Sorkuntza elektrikoaren mixa
description: "Espainiako elektrizitate-mixa 2007tik, Red Eléctricaren arabera: berriztagarrien kuota, ikatzaren itxiera, sortutako kWh bakoitzeko isuriak eta biztanleko kontsumo elektrikoa."
i18n_origen: 7cce8c387246
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import DownloadCsvButton from '../../../../../../../src/lib/components/DownloadCsvButton.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql elec
SELECT *
FROM mother.clima_electricidad_anual
ORDER BY anio
```

```sql elec_kpi
WITH e AS (
    SELECT
        *,
        lag(cuota_renovable_pct) OVER (ORDER BY anio) AS renov_prev,
        lag(g_co2_kwh) OVER (ORDER BY anio) AS g_prev,
        lag(demanda_kwh_hab) OVER (ORDER BY anio) AS dem_prev,
        first_value(g_co2_kwh) OVER (ORDER BY anio) AS g_inicio,
        first_value(cuota_carbon_pct) OVER (ORDER BY anio) AS carbon_inicio,
        first_value(cuota_renovable_pct) OVER (ORDER BY anio) AS renov_inicio,
        first_value(demanda_kwh_hab) OVER (ORDER BY anio) AS dem_inicio,
        CAST(first_value(anio) OVER (ORDER BY anio) AS INTEGER) AS anio_inicio
    FROM mother.clima_electricidad_anual
)
SELECT
    CAST(anio AS INTEGER) AS anio,
    anio_inicio,
    cuota_renovable_pct,
    cuota_renovable_pct - renov_prev AS renov_var_pp,
    renov_inicio,
    cuota_libre_emisiones_pct,
    g_co2_kwh,
    100 * (g_co2_kwh / g_prev - 1) AS g_var,
    g_inicio,
    100 * (g_co2_kwh / g_inicio - 1) AS g_var_inicio,
    emisiones_mt,
    emisiones_t_hab,
    demanda_kwh_hab,
    100 * (demanda_kwh_hab / dem_prev - 1) AS dem_var,
    100 * (demanda_kwh_hab / dem_inicio - 1) AS dem_var_inicio,
    dem_inicio,
    demanda_twh,
    generacion_twh,
    cuota_carbon_pct,
    carbon_inicio
FROM e
WHERE anio = (SELECT max(anio) FROM mother.clima_electricidad_anual)
```

```sql hitos_renov
SELECT
    CAST(min(anio) FILTER (WHERE cuota_renovable_pct > 50) AS INTEGER) AS primer_anio_50,
    max(cuota_renovable_pct) AS renov_max,
    CAST(arg_max(anio, cuota_renovable_pct) AS INTEGER) AS anio_renov_max,
    min(g_co2_kwh) AS g_min,
    CAST(arg_min(anio, g_co2_kwh) AS INTEGER) AS anio_g_min
FROM mother.clima_electricidad_anual
```

```sql mix_completo
SELECT
    anio,
    tecnologia,
    tipo_fuente,
    generacion_twh,
    cuota_pct
FROM mother.energia_mix_electrico
ORDER BY anio ASC, tecnologia ASC
```

```sql mix_pct
SELECT
    CAST(anio AS INTEGER) AS anio,
    tecnologia,
    cuota_pct,
    generacion_twh
FROM mother.energia_mix_electrico
ORDER BY anio, tecnologia
```

# ⚡ Sorkuntza elektrikoaren mixa Espainian

Nondik datorren Espainian sortzen den elektrizitatea eta zenbat CO₂ kostatzen duen kWh bakoitzak, urtez urte, {elec_kpi[0]?.anio_inicio}. urteaz geroztik, Red Eléctricaren datu-APIak argitaratzen duen lehen urtetik. Zifrak zentralen barretan neurtutako balantze nazionala dira (Penintsula, Balear Uharteak, Kanariak, Ceuta eta Melilla), urte osoekin soilik. Bolumen osoa herrialdearen tamainaren araberakoa denez, teknologiak **sorkuntzaren ehunekotan** erakusten dira, eta kontsumoa **biztanleko**.

<Grid cols=4>
    <KpiCard
        title="Elektrizitate berriztagarria"
        value={elec_kpi[0]?.cuota_renovable_pct}
        formattedValue="{formatNumber(elec_kpi[0]?.cuota_renovable_pct, 1)} %"
        period="sorkuntzarena, {elec_kpi[0]?.anio}. urtean · {formatNumber(elec_kpi[0]?.renov_inicio, 1)} %, {elec_kpi[0]?.anio_inicio}. urtean"
        change={elec_kpi[0]?.renov_var_pp?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="aurreko urtearekin alderatuta"
        direction="positive-up"
        source="REE"
        sparklineData={elec.map(d => ({...d, y: d.cuota_renovable_pct}))}
    />
    <KpiCard
        title="CO₂ sortutako kWh bakoitzeko"
        value={elec_kpi[0]?.g_co2_kwh}
        formattedValue="{formatNumber(elec_kpi[0]?.g_co2_kwh, 0)} g CO₂eq/kWh"
        period="{elec_kpi[0]?.anio}. urtean · {formatNumber(elec_kpi[0]?.g_inicio, 0)} g, {elec_kpi[0]?.anio_inicio}. urtean · {formatNumber(elec_kpi[0]?.emisiones_mt, 1)} Mt guztira"
        change={elec_kpi[0]?.g_var?.toFixed(1)}
        changePeriod="aurreko urtearekin alderatuta"
        direction="positive-down"
        source="REE"
        sparklineData={elec.map(d => ({...d, y: d.g_co2_kwh}))}
    />
    <KpiCard
        title="Kontsumoa biztanleko"
        value={elec_kpi[0]?.demanda_kwh_hab}
        formattedValue="{formatNumber(elec_kpi[0]?.demanda_kwh_hab, 0)} kWh"
        period="eskari elektrikoa biztanleko, {elec_kpi[0]?.anio}. urtean · {formatNumber(elec_kpi[0]?.demanda_twh, 1)} TWh guztira"
        change={elec_kpi[0]?.dem_var?.toFixed(1)}
        changePeriod="aurreko urtearekin alderatuta"
        direction="neutral"
        source="REE / Eurostat"
        sparklineData={elec.map(d => ({...d, y: d.demanda_kwh_hab}))}
    />
    <KpiCard
        title="Ikatza"
        value={elec_kpi[0]?.cuota_carbon_pct}
        formattedValue="{formatNumber(elec_kpi[0]?.cuota_carbon_pct, 1)} %"
        period="sorkuntzarena, {elec_kpi[0]?.anio}. urtean · {formatNumber(elec_kpi[0]?.carbon_inicio, 1)} %, {elec_kpi[0]?.anio_inicio}. urtean"
        direction="positive-down"
        source="REE"
        sparklineData={elec.map(d => ({...d, y: d.cuota_carbon_pct}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('electricidad_renovable', 'consumo_electrico_pc')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'electricidad_renovable')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'consumo_electrico_pc')} />


## Teknologia bakoitzaren pisua sorkuntzan

Berriztagarriek {hitos_renov[0]?.primer_anio_50}. urtean gainditu zuten lehen aldiz sorkuntzaren erdia, eta haien urteko maximoa {formatNumber(hitos_renov[0]?.renov_max, 1)} % da ({hitos_renov[0]?.anio_renov_max}). {elec_kpi[0]?.anio}. urtean, elektrizitatearen {formatNumber(elec_kpi[0]?.cuota_libre_emisiones_pct, 1)} % zuzeneko isuririk gabea izan zen (berriztagarriak gehi nuklearra).

<AreaChart
    data={mix_pct}
    x=anio
    y=cuota_pct
    series=tecnologia
    type=stacked
    xFmt='0'
    yFmt='0"%"'
    yMax=100
    yAxisTitle="Sorkuntzaren %"
    title="Sorkuntza elektrikoaren egitura teknologiaka"
/>

<DownloadCsvButton data={mix_completo} filename="spainfacts_mix_electrico_detalle.csv" label="Deskargatu mixaren datu osoak (CSV)" />

```sql cuota
SELECT anio, 'Renovable' AS serie, cuota_renovable_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT anio, 'Libre de emisiones (renovable + nuclear)' AS serie, cuota_libre_emisiones_pct AS pct FROM mother.clima_electricidad_anual
ORDER BY anio, serie
```

<LineChart
    data={cuota}
    x=anio
    y=pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yMin=0
    yMax=100
    yAxisTitle="Sorkuntzaren %"
    title="Sorkuntza garbiaren kuota"
    colorPalette={['#3b82f6', '#16a34a']}
/>

## Zenbat CO₂ isurtzen duen kWh bakoitzak

Sisteman sortutako kWh bakoitzeko zentralek isuritako CO₂ baliokidearen gramoak. Red Eléctricak zentral termikoei esleitzen dizkie isuriak (ikatza, ziklo konbinatuak, kogenerazioa, motorrak, turbinak eta hondakin ez-berriztagarriak); nuklearrak eta berriztagarriek zero zenbatzen dute. Seriearen minimoa {formatNumber(hitos_renov[0]?.g_min, 0)} g/kWh da, {hitos_renov[0]?.anio_g_min}. urtean; {elec_kpi[0]?.anio_inicio}. urteaz geroztik, faktorea {formatNumber(elec_kpi[0]?.g_var_inicio, 0)} % aldatu da.

<BarChart
    data={elec}
    x=anio
    y=g_co2_kwh
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="g CO₂eq kWh bakoitzeko"
    title="Sorkuntza elektrikoaren isuri-intentsitatea"
    colorPalette={['#dc2626']}
/>

<LineChart
    data={elec}
    x=anio
    y=emisiones_t_hab
    xFmt='0'
    yFmt='0.00'
    yAxisTitle="t CO₂eq biztanleko"
    title="Sorkuntza elektrikoaren isuriak biztanleko"
    colorPalette={['#f97316']}
/>

## Ikatzaren amildegia eta eguzki-energiaren gorakada

```sql carbon_vs_solar
SELECT anio, 'Carbón' AS tecnologia, cuota_carbon_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT anio, 'Solar fotovoltaica' AS tecnologia, cuota_solar_fv_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT anio, 'Eólica' AS tecnologia, cuota_eolica_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT anio, 'Ciclos combinados (gas)' AS tecnologia, cuota_ciclo_pct AS pct FROM mother.clima_electricidad_anual
ORDER BY anio, tecnologia
```

```sql cruce_solar_carbon
SELECT
    CAST(min(anio) FILTER (WHERE cuota_solar_fv_pct > cuota_carbon_pct) AS INTEGER) AS primer_anio,
    CAST(max(anio) AS INTEGER) AS ultimo_anio,
    round(arg_max(cuota_solar_fv_pct / nullif(cuota_carbon_pct, 0), anio), 0) AS ratio_ultimo
FROM mother.clima_electricidad_anual
```

{cruce_solar_carbon[0]?.primer_anio}. urtean, eguzki-energia fotovoltaikoak lehen aldiz gainditu zuen ikatza urteko sorkuntzan. {cruce_solar_carbon[0]?.ultimo_anio}. urtean, eguzki-energiak ikatzak baino **{cruce_solar_carbon[0]?.ratio_ultimo} aldiz** elektrizitate gehiago ekoiztu zuen.

<LineChart
    data={carbon_vs_solar}
    x=anio
    y=pct
    series=tecnologia
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="Sorkuntzaren %"
    title="Ikatza, gasa, eolikoa eta eguzki-energia fotovoltaikoa"
    colorPalette={['#6b7280', '#f97316', '#16a34a', '#facc15']}
/>

## Kontsumo elektrikoa biztanleko

Zentralen barretan neurtutako eskari nazionala zati urteko batez besteko biztanleria. {elec_kpi[0]?.anio}. urtean {formatNumber(elec_kpi[0]?.demanda_kwh_hab, 0)} kWh izan zen biztanleko, {formatNumber(Math.abs(elec_kpi[0]?.dem_var_inicio), 0)} % {#if elec_kpi[0]?.dem_var_inicio < 0}gutxiago{:else}gehiago{/if} {elec_kpi[0]?.anio_inicio}. urtean baino ({formatNumber(elec_kpi[0]?.dem_inicio, 0)} kWh).

<LineChart
    data={elec}
    x=anio
    y=demanda_kwh_hab
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="kWh biztanleko"
    startingAtZero={false}
    title="Eskari elektrikoa biztanleko"
    colorPalette={['#2563eb']}
/>

## Teknologia bakoitzaren pisua (azken urte osoa)

```sql mix_ultimo
SELECT
    anio,
    tecnologia,
    generacion_twh,
    cuota_pct / 100.0 AS cuota_pct
FROM mother.energia_mix_electrico
WHERE anio = (SELECT max(anio) FROM mother.energia_mix_electrico)
ORDER BY generacion_twh DESC
```

<BarChart
    data={mix_ultimo}
    x=tecnologia
    y=cuota_pct
    yFmt='0.0%'
    yAxisTitle="Sorkuntzaren %"
    title="Sorkuntza teknologiaka, {elec_kpi[0]?.anio}. urtean"
    colorPalette={['#16a34a']}
    swapXY=true
/>

<DataTable data={mix_ultimo} search=false>
    <Column id=tecnologia title="Teknologia" />
    <Column id=cuota_pct title="Guztizkoaren %" fmt="pct1" contentType=colorscale colorScale={['#dbeafe', '#1d4ed8']} />
    <Column id=generacion_twh title="Sorkuntza (TWh)" fmt="num1" />
</DataTable>

## Instalatutako potentzia teknologiaka

Instalatutako ahalmenak inbertsio-erabakiak islatzen ditu. Eguzki FVa {formatNumber(solar_hitos[0]?.potencia_mw, 0)} MW izatetik ({solar_hitos[0]?.anio}) **{formatNumber(solar_hitos[1]?.potencia_mw, 0)} MW** izatera igaro da ({solar_hitos[1]?.anio}), {formatNumber(solar_hitos[1]?.potencia_mw / solar_hitos[0]?.potencia_mw, 1)} aldiz biderkatuta.

```sql solar_hitos
SELECT CAST(anio AS INTEGER) AS anio, potencia_mw
FROM mother.energia_potencia_instalada
WHERE tecnologia = 'Solar Fotovoltaica'
  AND anio IN ((SELECT min(anio) FROM mother.energia_potencia_instalada), (SELECT max(anio) FROM mother.energia_potencia_instalada))
ORDER BY anio ASC
```

```sql potencia
SELECT
    anio,
    tecnologia,
    potencia_mw,
    tipo,
    fuente
FROM mother.energia_potencia_instalada
ORDER BY anio ASC, potencia_mw DESC
```

<BarChart
    data={potencia}
    x=anio
    y=potencia_mw
    series=tecnologia
    type=grouped
    xFmt='0'
    yAxisTitle="Instalatutako MW"
    title="Instalatutako potentzia teknologiaka (MW)"
/>

<DownloadCsvButton data={potencia} filename="spainfacts_potencia_instalada.csv" label="Deskargatu instalatutako potentzia (CSV)" />

<DownloadCsvButton data={elec} filename="spainfacts_electricidad_anual.csv" label="Deskargatu kuotak, isuriak eta eskaria urteka (CSV)" />

---

## Iturriak

**Red Eléctrica de España (REE)**, sistema elektrikoaren operadorea, [REData](https://www.ree.es/es/datos/apidatos) APIa:
- Urteko sorkuntza teknologiaka (`generacion/estructura-generacion`) eta eskaria (`demanda/evolucion`), 2007tik, APIan eskuragarri dagoen lehen urtetik. Zentralen barretan neurtutako balantzea, sistema nazionala. Urte osoak soilik.
- Sorkuntza ez-berriztagarriaren CO₂ baliokidearen isuriak (`generacion/no-renovables-detalle-emisiones-CO2`); g/kWh-ko faktoreak isuri horiek sorkuntza osoaz zatitzen ditu.
- Lizentzia: sektore publikoko informazioaren berrerabilpena / datu irekiak.

**Urteko batez besteko biztanleria:** Eurostat [demo_gind](https://ec.europa.eu/eurostat/databrowser/view/demo_gind/default/table).

**Instalatutako potentzia:** Eurostat [nrg_inf_epc](https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_epc/default/table) (Espainiak jakinarazitako gehieneko ahalmen elektriko garbia), REEren APIko instalatutako potentziaren zerbitzua erabilgarri ez dagoen bitartean erabilia; CSVko `fuente` zutabeak jatorria adierazten du. Estatistika honetan, gas naturalak ziklo konbinatuak eta kogenerazioa biltzen ditu, eta eguzki FVak autokontsumoa barne hartzen du.

Herrialdearen isuri guztiak, biztanleko eta sektoreka, [Isuriak eta deskarbonizazioa](/eu/energia-clima/emisiones) orrian daude.

<LastRefreshed prefix="Datuen azken sinkronizazioa" />
