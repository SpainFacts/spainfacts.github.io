---
title: "Espainiako eraldaketa elektrikoa: ikatzetik % 50 berriztagarria gainditzera"
description: "Nola aldatu den Espainiako mix elektrikoa 2007tik Red Eléctricaren arabera: hedapen eoliko eta eguzki-fotovoltaikoa, ikatzaren itxiera eta kWh bakoitzeko CO₂ isurien amiltzea."
i18n_origen: db82420b35b1
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql elec
SELECT *
FROM mother.clima_electricidad_anual
ORDER BY anio
```

```sql hitos
WITH e AS (
    SELECT
        *,
        lag(cuota_renovable_pct) OVER (ORDER BY anio) AS renov_prev,
        lag(g_co2_kwh) OVER (ORDER BY anio) AS g_prev,
        first_value(g_co2_kwh) OVER (ORDER BY anio) AS g_inicio,
        first_value(cuota_carbon_pct) OVER (ORDER BY anio) AS carbon_inicio,
        first_value(cuota_renovable_pct) OVER (ORDER BY anio) AS renov_inicio,
        first_value(cuota_solar_fv_pct) OVER (ORDER BY anio) AS solar_inicio,
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
    100.0 * (g_co2_kwh / g_prev - 1) AS g_var,
    g_inicio,
    100.0 * (g_co2_kwh / g_inicio - 1) AS g_var_inicio,
    emisiones_mt,
    emisiones_t_hab,
    cuota_carbon_pct,
    carbon_inicio,
    cuota_solar_fv_pct,
    solar_inicio,
    cuota_eolica_pct,
    (SELECT CAST(min(anio) FILTER (WHERE cuota_renovable_pct > 50) AS INTEGER) FROM mother.clima_electricidad_anual) AS primer_anio_50,
    (SELECT CAST(min(anio) FILTER (WHERE cuota_solar_fv_pct > cuota_carbon_pct) AS INTEGER) FROM mother.clima_electricidad_anual) AS anio_cruce_solar
FROM e
WHERE anio = (SELECT max(anio) FROM mother.clima_electricidad_anual)
```

```sql tecnologias_clave
SELECT CAST(anio AS INTEGER) AS anio, 'Eólica' AS tecnologia, cuota_eolica_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT CAST(anio AS INTEGER) AS anio, 'Solar fotovoltaica' AS tecnologia, cuota_solar_fv_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT CAST(anio AS INTEGER) AS anio, 'Ciclos combinados (gas)' AS tecnologia, cuota_ciclo_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT CAST(anio AS INTEGER) AS anio, 'Carbón' AS tecnologia, cuota_carbon_pct AS pct FROM mother.clima_electricidad_anual
ORDER BY anio, tecnologia
```

```sql cuota_limpia
SELECT CAST(anio AS INTEGER) AS anio, 'Renovable' AS serie, cuota_renovable_pct AS pct FROM mother.clima_electricidad_anual
UNION ALL
SELECT CAST(anio AS INTEGER) AS anio, 'Libre de emisiones (renovable + nuclear)' AS serie, cuota_libre_emisiones_pct AS pct FROM mother.clima_electricidad_anual
ORDER BY anio, serie
```

```sql mix_ultimo
SELECT
    CAST(anio AS INTEGER) AS anio,
    tecnologia,
    tipo_fuente,
    generacion_twh,
    cuota_pct
FROM mother.energia_mix_electrico
WHERE anio = (SELECT max(anio) FROM mother.energia_mix_electrico)
ORDER BY generacion_twh DESC
```

```sql comparativa_ue
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'electricidad_renovable'
```

<div class="not-prose mb-4 flex flex-wrap items-center gap-2 text-xs font-semibold text-gray-500 dark:text-gray-400">
    <a href="/eu/analisis" class="text-blue-600 dark:text-blue-400 hover:underline no-underline">← Datuetan oinarritutako analisia</a>
    <span>·</span>
    <span class="rounded-full bg-emerald-100 dark:bg-emerald-950/60 px-2.5 py-0.5 text-emerald-800 dark:text-emerald-300">Energia eta Trantsizioa</span>
    <span>·</span>
    <a href="/eu/energia-clima/mix-electrico" class="hover:underline text-gray-600 dark:text-gray-400 no-underline">Ikusi mix elektrikoaren panel iraunkorra →</a>
</div>

# ⚡ Espainiako eraldaketa elektrikoa: ikatzetik % 50 berriztagarria gainditzera

Bi hamarkada baino gutxiagoan, Espainiako sistema elektrikoak Europako egiturazko aldaketa azkarrenetako bat bizi izan du. **Red Eléctrica de España (REE)** erakundearen serie ofizialen arabera ({hitos[0]?.anio_inicio}tik), sorkuntza berriztagarria **% {formatNumber(hitos[0]?.renov_inicio, 1)}tik** **% {formatNumber(hitos[0]?.cuota_renovable_pct, 1)}ra** igaro da {hitos[0]?.anio}(e)n; ikatza, berriz —herrialdeko elektrizitatearen laurdena ematen zuena (% {formatNumber(hitos[0]?.carbon_inicio, 1)})—, ia desagertu egin da (% {formatNumber(hitos[0]?.cuota_carbon_pct, 1)}).

<Grid cols=4>
    <KpiCard
        title="Kuota berriztagarria"
        value={hitos[0]?.cuota_renovable_pct}
        formattedValue="% {formatNumber(hitos[0]?.cuota_renovable_pct, 1)}"
        period="urteko sorkuntza ({hitos[0]?.anio}) · % {formatNumber(hitos[0]?.renov_inicio, 1)} {hitos[0]?.anio_inicio}(e)n"
        change={hitos[0]?.renov_var_pp?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="aurreko urtearen aldean"
        direction="positive-up"
        source="REE"
        href="/eu/energia-clima/mix-electrico"
        sparklineData={elec.map(d => ({...d, y: d.cuota_renovable_pct}))}
    />
    <KpiCard
        title="Isuririk gabea"
        value={hitos[0]?.cuota_libre_emisiones_pct}
        formattedValue="% {formatNumber(hitos[0]?.cuota_libre_emisiones_pct, 1)}"
        period="berriztagarria + nuklearra ({hitos[0]?.anio})"
        direction="positive-up"
        source="REE"
        href="/eu/energia-clima/mix-electrico"
        sparklineData={elec.map(d => ({...d, y: d.cuota_libre_emisiones_pct}))}
    />
    <KpiCard
        title="CO₂ intentsitatea"
        value={hitos[0]?.g_co2_kwh}
        formattedValue="{formatNumber(hitos[0]?.g_co2_kwh, 0)} g/kWh"
        period="% {formatNumber(hitos[0]?.g_var_inicio, 0)} {hitos[0]?.anio_inicio}tik ({formatNumber(hitos[0]?.g_inicio, 0)} g/kWh)"
        change={hitos[0]?.g_var?.toFixed(1)}
        changePeriod="aurreko urtearen aldean"
        direction="positive-down"
        source="REE"
        href="/eu/energia-clima/emisiones"
        sparklineData={elec.map(d => ({...d, y: d.g_co2_kwh}))}
    />
    <KpiCard
        title="Ikatzaren kuota"
        value={hitos[0]?.cuota_carbon_pct}
        formattedValue="% {formatNumber(hitos[0]?.cuota_carbon_pct, 1)}"
        period="{hitos[0]?.anio}(e)n · {hitos[0]?.anio_inicio}(e)ko % {formatNumber(hitos[0]?.carbon_inicio, 1)}aren aldean"
        direction="positive-down"
        source="REE"
        href="/eu/energia-clima/centrales"
        sparklineData={elec.map(d => ({...d, y: d.cuota_carbon_pct}))}
    />
</Grid>

## 1. Errelebo teknologikoa: bi olatu berriztagarri eta ikatzaren itxiera

Espainiako trantsizio elektrikoa ondoz ondoko bi bultzadek eta itxiera programatu batek azaltzen dute:

1. **Lehen olatua eolikoa izan zen:** herrialdeko lehen sorkuntza-iturri gisa finkatuta, elektrizitate guztiaren **% {formatNumber(hitos[0]?.cuota_eolica_pct, 1)}** ematen du {hitos[0]?.anio}(e)n.
2. **Bigarren olatua eguzki-energia fotovoltaikoa da:** {hitos[0]?.anio_inicio}(e)n % {formatNumber(hitos[0]?.solar_inicio, 1)} baino ez izatetik {hitos[0]?.anio}(e)n **% {formatNumber(hitos[0]?.cuota_solar_fv_pct, 1)}** izatera igaro da, {hitos[0]?.anio_cruce_solar}(e)n ikatza lehen aldiz gaindituz.
3. **Ikatz-zentral termikoen itxiera:** 2019 eta 2020 artean ikatz-parkearen zatirik handiena deskonektatu zen Europako CO₂ isurketa-eskubideen garestitzeagatik eta bere balio-bizitza erregulatzailearen amaieragatik.

<LineChart
    data={tecnologias_clave}
    x=anio
    y=pct
    series=tecnologia
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="Sorkuntza nazionalaren %a"
    title="Gurutzaketa historikoa: eolikoa eta eguzki-fotovoltaikoa ikatzaren eta ziklo konbinatuen (gasa) aldean"
    colorPalette={['#6b7280', '#f97316', '#16a34a', '#eab308']}
/>

## 2. Erdia baino gehiago berriztagarria eta hiru laurden baino gehiago isuririk gabe

**{hitos[0]?.primer_anio_50}**an Espainiak lehen aldiz gainditu zuen **urteko sorkuntza berriztagarriaren % 50eko** langa. Sorkuntza nuklearra gehitzen bada (berotegi-efektuko gasik isurtzen ez duena baina hondakin erradioaktiboak sortzen dituena), {hitos[0]?.anio}(e)n ekoitzitako kilowatt-orduen **% {formatNumber(hitos[0]?.cuota_libre_emisiones_pct, 1)}** zuzeneko CO₂ isuririk gabeak izan ziren.

<LineChart
    data={cuota_limpia}
    x=anio
    y=pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yMin=0
    yMax=100
    yAxisTitle="Sorkuntzaren %a"
    title="Espainian sorkuntza berriztagarriaren eta zuzeneko isuririk gabekoaren ehunekoa"
    colorPalette={['#3b82f6', '#16a34a']}
/>

<Comparativa data={comparativa_ue} />

## 3. Kliman duen eragin zuzena: kWh bakoitzak {hitos[0]?.anio_inicio}(e)n baino hiru aldiz CO₂ gutxiago isurtzen du

Ikatza eta gasa haizearekin eta eguzkiarekin ordezkatzeak Espainiako elektrizitatearen karbono-aztarna amildu du:

- {hitos[0]?.anio_inicio}(e)n, kilowatt-ordu bat sortzeak **{formatNumber(hitos[0]?.g_inicio, 0)} gramo CO₂ baliokide** isurtzen zituen.
- {hitos[0]?.anio}(e)n, zifra hori **{formatNumber(hitos[0]?.g_co2_kwh, 0)} g CO₂eq/kWh**-ra jaitsi zen (**% {formatNumber(Math.abs(hitos[0]?.g_var_inicio), 0)}ko** murrizketa).
- Horrek garraioa ([auto elektrikoa](/eu/movilidad/coche-electrico)) edo klimatizazioa (bero-ponpak) elektrifikatzearen klima-onura biderkatzen du, urtetik urtera horiek elikatzen dituen sare elektrikoa garbiagoa baita.

<BarChart
    data={elec}
    x=anio
    y=g_co2_kwh
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="g CO₂eq kWh bakoitzeko"
    title="Espainiako sorkuntza elektrikoaren CO₂ isurien intentsitatea (g CO₂eq/kWh)"
    colorPalette={['#dc2626']}
/>

## 4. Azken urte osoko erradiografia ({hitos[0]?.anio})

<DataTable data={mix_ultimo} search=false>
    <Column id=tecnologia title="Teknologia" />
    <Column id=tipo_fuente title="Mota" />
    <Column id=cuota_pct title="Sorkuntzaren %a" fmt='0.0"%"' />
    <Column id=generacion_twh title="Sorkuntza (TWh)" fmt='0.0' />
</DataTable>

---

**Metodologia eta iturriak:**
- **Sorkuntza- eta isurketa-datuak:** [Red Eléctrica de España (REE) — REData](https://www.ree.es/es/datos/apidatos), balantze elektriko nazionala zentraleko barretan (urte osoak).
- **Europako konparazioa:** [Eurostat (`nrg_ind_ren`)](https://ec.europa.eu/eurostat/databrowser/view/nrg_ind_ren/default/table).
- **Arakatzen jarraitzeko:** Kontsultatu [Elektrizitatea zuzenean](/eu/energia-clima/directo), [Mix elektrikoa](/eu/energia-clima/mix-electrico), [Biltegiratzea eta ponpaketa](/eu/energia-clima/almacenamiento), [Elektrifikazioa](/eu/energia-clima/electrificacion) eta [Espainiako isuri guztiak](/eu/energia-clima/emisiones).
