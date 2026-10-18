---
title: "A transformación eléctrica de España: do carbón a superar o 50 % renovable"
description: "Como cambiou o mix eléctrico español desde 2007 segundo Red Eléctrica: o despregamento eólico e solar, o peche do carbón e o esfarelamento das emisións de CO₂ por kWh."
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
    <a href="/gl/analisis" class="text-blue-600 dark:text-blue-400 hover:underline no-underline">← Análise en datos</a>
    <span>·</span>
    <span class="rounded-full bg-emerald-100 dark:bg-emerald-950/60 px-2.5 py-0.5 text-emerald-800 dark:text-emerald-300">Enerxía e Transición</span>
    <span>·</span>
    <a href="/gl/energia-clima/mix-electrico" class="hover:underline text-gray-600 dark:text-gray-400 no-underline">Ver panel permanente do mix eléctrico →</a>
</div>

# ⚡ A transformación eléctrica de España: do carbón a superar o 50 % renovable

En menos de dúas décadas, o sistema eléctrico español viviu un dos cambios estruturais máis rápidos de Europa. Segundo as series oficiais de **Red Eléctrica de España (REE)** desde {hitos[0]?.anio_inicio}, a xeración renovable pasou do **{formatNumber(hitos[0]?.renov_inicio, 1)} %** ao **{formatNumber(hitos[0]?.cuota_renovable_pct, 1)} %** en {hitos[0]?.anio}, mentres que o carbón —que achegaba unha cuarta parte da electricidade do país ({formatNumber(hitos[0]?.carbon_inicio, 1)} %)— se volveu testemuñal ({formatNumber(hitos[0]?.cuota_carbon_pct, 1)} %).

<Grid cols=4>
    <KpiCard
        title="Cota renovable"
        value={hitos[0]?.cuota_renovable_pct}
        formattedValue="{formatNumber(hitos[0]?.cuota_renovable_pct, 1)} %"
        period="xeración anual ({hitos[0]?.anio}) · {formatNumber(hitos[0]?.renov_inicio, 1)} % en {hitos[0]?.anio_inicio}"
        change={hitos[0]?.renov_var_pp?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="vs ano anterior"
        direction="positive-up"
        source="REE"
        href="/gl/energia-clima/mix-electrico"
        sparklineData={elec.map(d => ({...d, y: d.cuota_renovable_pct}))}
    />
    <KpiCard
        title="Libre de emisións"
        value={hitos[0]?.cuota_libre_emisiones_pct}
        formattedValue="{formatNumber(hitos[0]?.cuota_libre_emisiones_pct, 1)} %"
        period="renovable + nuclear ({hitos[0]?.anio})"
        direction="positive-up"
        source="REE"
        href="/gl/energia-clima/mix-electrico"
        sparklineData={elec.map(d => ({...d, y: d.cuota_libre_emisiones_pct}))}
    />
    <KpiCard
        title="Intensidade de CO₂"
        value={hitos[0]?.g_co2_kwh}
        formattedValue="{formatNumber(hitos[0]?.g_co2_kwh, 0)} g/kWh"
        period="{formatNumber(hitos[0]?.g_var_inicio, 0)} % desde {hitos[0]?.anio_inicio} ({formatNumber(hitos[0]?.g_inicio, 0)} g/kWh)"
        change={hitos[0]?.g_var?.toFixed(1)}
        changePeriod="vs ano anterior"
        direction="positive-down"
        source="REE"
        href="/gl/energia-clima/emisiones"
        sparklineData={elec.map(d => ({...d, y: d.g_co2_kwh}))}
    />
    <KpiCard
        title="Cota do carbón"
        value={hitos[0]?.cuota_carbon_pct}
        formattedValue="{formatNumber(hitos[0]?.cuota_carbon_pct, 1)} %"
        period="en {hitos[0]?.anio} · fronte ao {formatNumber(hitos[0]?.carbon_inicio, 1)} % en {hitos[0]?.anio_inicio}"
        direction="positive-down"
        source="REE"
        href="/gl/energia-clima/centrales"
        sparklineData={elec.map(d => ({...d, y: d.cuota_carbon_pct}))}
    />
</Grid>

## 1. O relevo tecnolóxico: dúas ondas renovables e o peche do carbón

A transición eléctrica española explícase por dous impulsos sucesivos e un peche programado:

1. **A primeira onda foi eólica:** xa consolidada como primeira fonte de xeración do país, achega o **{formatNumber(hitos[0]?.cuota_eolica_pct, 1)} %** de toda a electricidade en {hitos[0]?.anio}.
2. **A segunda onda é solar fotovoltaica:** pasou de apenas o {formatNumber(hitos[0]?.solar_inicio, 1)} % en {hitos[0]?.anio_inicio} ao **{formatNumber(hitos[0]?.cuota_solar_fv_pct, 1)} %** en {hitos[0]?.anio}, superando por primeira vez o carbón en {hitos[0]?.anio_cruce_solar}.
3. **O peche das térmicas de carbón:** entre 2019 e 2020 desconectouse o groso do parque carboeiro polo encarecemento dos dereitos de emisión de CO₂ europeos e o fin da súa vida útil regulatoria.

<LineChart
    data={tecnologias_clave}
    x=anio
    y=pct
    series=tecnologia
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% da xeración nacional"
    title="O cruzamento histórico: eólica e solar fotovoltaica fronte a carbón e ciclos combinados (gas)"
    colorPalette={['#6b7280', '#f97316', '#16a34a', '#eab308']}
/>

## 2. Máis da metade renovable e máis de tres cuartas partes sen emisións

En **{hitos[0]?.primer_anio_50}** España superou por primeira vez a barreira do **50 % de xeración anual renovable**. Se se suma a xeración nuclear (que non emite gases de efecto invernadoiro pero xera residuos radioactivos), o **{formatNumber(hitos[0]?.cuota_libre_emisiones_pct, 1)} %** dos quilowatts hora producidos en {hitos[0]?.anio} estiveron libres de emisións directas de CO₂.

<LineChart
    data={cuota_limpia}
    x=anio
    y=pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yMin=0
    yMax=100
    yAxisTitle="% da xeración"
    title="Porcentaxe de xeración renovable e libre de emisións directas en España"
    colorPalette={['#3b82f6', '#16a34a']}
/>

<Comparativa data={comparativa_ue} />

## 3. O impacto directo no clima: cada kWh emite unha terceira parte de CO₂ ca en {hitos[0]?.anio_inicio}

A substitución de carbón e gas por vento e sol afundiu a pegada de carbono da electricidade en España:

- En {hitos[0]?.anio_inicio}, xerar un quilowatt hora emitía **{formatNumber(hitos[0]?.g_inicio, 0)} gramos de CO₂ equivalente**.
- En {hitos[0]?.anio}, esa cifra caeu a **{formatNumber(hitos[0]?.g_co2_kwh, 0)} g CO₂eq/kWh** (unha redución do **{formatNumber(Math.abs(hitos[0]?.g_var_inicio), 0)} %**).
- Isto multiplica o beneficio climático de electrificar o transporte ([coche eléctrico](/gl/movilidad/coche-electrico)) ou a climatización (bombas de calor), porque cada ano que pasa a rede eléctrica que os alimenta é máis limpa.

<BarChart
    data={elec}
    x=anio
    y=g_co2_kwh
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="g CO₂eq por kWh"
    title="Intensidade de emisións de CO₂ da xeración eléctrica en España (g CO₂eq/kWh)"
    colorPalette={['#dc2626']}
/>

## 4. Radiografía completa do último ano ({hitos[0]?.anio})

<DataTable data={mix_ultimo} search=false>
    <Column id=tecnologia title="Tecnoloxía" />
    <Column id=tipo_fuente title="Tipo" />
    <Column id=cuota_pct title="% da xeración" fmt='0.0"%"' />
    <Column id=generacion_twh title="Xeración (TWh)" fmt='0.0' />
</DataTable>

---

**Metodoloxía e fontes:**
- **Datos de xeración e emisións:** [Red Eléctrica de España (REE) — REData](https://www.ree.es/es/datos/apidatos), balance eléctrico nacional en barras de central (anos completos).
- **Comparativa europea:** [Eurostat (`nrg_ind_ren`)](https://ec.europa.eu/eurostat/databrowser/view/nrg_ind_ren/default/table).
- **Para seguir explorando:** Consulta [A electricidade en directo](/gl/energia-clima/directo), [Mix eléctrico](/gl/energia-clima/mix-electrico), [Almacenamento e bombeo](/gl/energia-clima/almacenamiento), [Electrificación](/gl/energia-clima/electrificacion) e [Emisións totais de España](/gl/energia-clima/emisiones).
