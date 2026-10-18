---
title: "La transformació elèctrica d'Espanya: del carbó a superar el 50 % renovable"
description: "Com ha canviat el mix elèctric espanyol des del 2007 segons Red Eléctrica: el desplegament eòlic i solar, el tancament del carbó i l'enfonsament de les emissions de CO₂ per kWh."
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
    <a href="/ca/analisis" class="text-blue-600 dark:text-blue-400 hover:underline no-underline">← Anàlisi en dades</a>
    <span>·</span>
    <span class="rounded-full bg-emerald-100 dark:bg-emerald-950/60 px-2.5 py-0.5 text-emerald-800 dark:text-emerald-300">Energia i Transició</span>
    <span>·</span>
    <a href="/ca/energia-clima/mix-electrico" class="hover:underline text-gray-600 dark:text-gray-400 no-underline">Veure panell permanent del mix elèctric →</a>
</div>

# ⚡ La transformació elèctrica d'Espanya: del carbó a superar el 50 % renovable

En menys de dues dècades, el sistema elèctric espanyol ha viscut un dels canvis estructurals més ràpids d'Europa. Segons les sèries oficials de **Red Eléctrica de España (REE)** des del {hitos[0]?.anio_inicio}, la generació renovable ha passat del **{formatNumber(hitos[0]?.renov_inicio, 1)} %** al **{formatNumber(hitos[0]?.cuota_renovable_pct, 1)} %** el {hitos[0]?.anio}, mentre que el carbó —que aportava una quarta part de l'electricitat del país ({formatNumber(hitos[0]?.carbon_inicio, 1)} %)— s'ha tornat testimonial ({formatNumber(hitos[0]?.cuota_carbon_pct, 1)} %).

<Grid cols=4>
    <KpiCard
        title="Quota renovable"
        value={hitos[0]?.cuota_renovable_pct}
        formattedValue="{formatNumber(hitos[0]?.cuota_renovable_pct, 1)} %"
        period="generació anual ({hitos[0]?.anio}) · {formatNumber(hitos[0]?.renov_inicio, 1)} % el {hitos[0]?.anio_inicio}"
        change={hitos[0]?.renov_var_pp?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="vs any anterior"
        direction="positive-up"
        source="REE"
        href="/ca/energia-clima/mix-electrico"
        sparklineData={elec.map(d => ({...d, y: d.cuota_renovable_pct}))}
    />
    <KpiCard
        title="Lliure d'emissions"
        value={hitos[0]?.cuota_libre_emisiones_pct}
        formattedValue="{formatNumber(hitos[0]?.cuota_libre_emisiones_pct, 1)} %"
        period="renovable + nuclear ({hitos[0]?.anio})"
        direction="positive-up"
        source="REE"
        href="/ca/energia-clima/mix-electrico"
        sparklineData={elec.map(d => ({...d, y: d.cuota_libre_emisiones_pct}))}
    />
    <KpiCard
        title="Intensitat de CO₂"
        value={hitos[0]?.g_co2_kwh}
        formattedValue="{formatNumber(hitos[0]?.g_co2_kwh, 0)} g/kWh"
        period="{formatNumber(hitos[0]?.g_var_inicio, 0)} % des del {hitos[0]?.anio_inicio} ({formatNumber(hitos[0]?.g_inicio, 0)} g/kWh)"
        change={hitos[0]?.g_var?.toFixed(1)}
        changePeriod="vs any anterior"
        direction="positive-down"
        source="REE"
        href="/ca/energia-clima/emisiones"
        sparklineData={elec.map(d => ({...d, y: d.g_co2_kwh}))}
    />
    <KpiCard
        title="Quota del carbó"
        value={hitos[0]?.cuota_carbon_pct}
        formattedValue="{formatNumber(hitos[0]?.cuota_carbon_pct, 1)} %"
        period="el {hitos[0]?.anio} · enfront del {formatNumber(hitos[0]?.carbon_inicio, 1)} % el {hitos[0]?.anio_inicio}"
        direction="positive-down"
        source="REE"
        href="/ca/energia-clima/centrales"
        sparklineData={elec.map(d => ({...d, y: d.cuota_carbon_pct}))}
    />
</Grid>

## 1. El relleu tecnològic: dues onades renovables i el tancament del carbó

La transició elèctrica espanyola s'explica per dos impulsos successius i un tancament programat:

1. **La primera onada va ser eòlica:** ja consolidada com a primera font de generació del país, aporta el **{formatNumber(hitos[0]?.cuota_eolica_pct, 1)} %** de tota l'electricitat el {hitos[0]?.anio}.
2. **La segona onada és solar fotovoltaica:** va passar de tot just el {formatNumber(hitos[0]?.solar_inicio, 1)} % el {hitos[0]?.anio_inicio} al **{formatNumber(hitos[0]?.cuota_solar_fv_pct, 1)} %** el {hitos[0]?.anio}, superant per primera vegada el carbó el {hitos[0]?.anio_cruce_solar}.
3. **El tancament de les tèrmiques de carbó:** entre el 2019 i el 2020 es va desconnectar el gruix del parc carboner per l'encariment dels drets d'emissió de CO₂ europeus i la fi de la seva vida útil regulatòria.

<LineChart
    data={tecnologias_clave}
    x=anio
    y=pct
    series=tecnologia
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% de la generació nacional"
    title="L'encreuament històric: eòlica i solar fotovoltaica enfront de carbó i cicles combinats (gas)"
    colorPalette={['#6b7280', '#f97316', '#16a34a', '#eab308']}
/>

## 2. Més de la meitat renovable i més de tres quartes parts sense emissions

El **{hitos[0]?.primer_anio_50}** Espanya va superar per primera vegada la barrera del **50 % de generació anual renovable**. Si s'hi suma la generació nuclear (que no emet gasos d'efecte d'hivernacle però genera residus radioactius), el **{formatNumber(hitos[0]?.cuota_libre_emisiones_pct, 1)} %** dels quilowatts hora produïts el {hitos[0]?.anio} van estar lliures d'emissions directes de CO₂.

<LineChart
    data={cuota_limpia}
    x=anio
    y=pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yMin=0
    yMax=100
    yAxisTitle="% de la generació"
    title="Percentatge de generació renovable i lliure d'emissions directes a Espanya"
    colorPalette={['#3b82f6', '#16a34a']}
/>

<Comparativa data={comparativa_ue} />

## 3. L'impacte directe en el clima: cada kWh emet una tercera part de CO₂ que el {hitos[0]?.anio_inicio}

La substitució de carbó i gas per vent i sol ha enfonsat la petjada de carboni de l'electricitat a Espanya:

- El {hitos[0]?.anio_inicio}, generar un quilowatt hora emetia **{formatNumber(hitos[0]?.g_inicio, 0)} grams de CO₂ equivalent**.
- El {hitos[0]?.anio}, aquesta xifra va caure a **{formatNumber(hitos[0]?.g_co2_kwh, 0)} g CO₂eq/kWh** (una reducció del **{formatNumber(Math.abs(hitos[0]?.g_var_inicio), 0)} %**).
- Això multiplica el benefici climàtic d'electrificar el transport ([cotxe elèctric](/ca/movilidad/coche-electrico)) o la climatització (bombes de calor), perquè cada any que passa la xarxa elèctrica que els alimenta és més neta.

<BarChart
    data={elec}
    x=anio
    y=g_co2_kwh
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="g CO₂eq per kWh"
    title="Intensitat d'emissions de CO₂ de la generació elèctrica a Espanya (g CO₂eq/kWh)"
    colorPalette={['#dc2626']}
/>

## 4. Radiografia completa de l'últim any ({hitos[0]?.anio})

<DataTable data={mix_ultimo} search=false>
    <Column id=tecnologia title="Tecnologia" />
    <Column id=tipo_fuente title="Tipus" />
    <Column id=cuota_pct title="% de la generació" fmt='0.0"%"' />
    <Column id=generacion_twh title="Generació (TWh)" fmt='0.0' />
</DataTable>

---

**Metodologia i fonts:**
- **Dades de generació i emissions:** [Red Eléctrica de España (REE) — REData](https://www.ree.es/es/datos/apidatos), balanç elèctric nacional en barres de central (anys complets).
- **Comparativa europea:** [Eurostat (`nrg_ind_ren`)](https://ec.europa.eu/eurostat/databrowser/view/nrg_ind_ren/default/table).
- **Per continuar explorant:** Consulta [L'electricitat en directe](/ca/energia-clima/directo), [Mix elèctric](/ca/energia-clima/mix-electrico), [Emmagatzematge i bombament](/ca/energia-clima/almacenamiento), [Electrificació](/ca/energia-clima/electrificacion) i [Emissions totals d'Espanya](/ca/energia-clima/emisiones).
