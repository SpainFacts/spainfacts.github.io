---
title: "La transformación eléctrica de España: del carbón a superar el 50 % renovable"
description: "Cómo ha cambiado el mix eléctrico español desde 2007 según Red Eléctrica: el despliegue eólico y solar, el cierre del carbón y el desplome de las emisiones de CO₂ por kWh."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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
    <a href="/analisis" class="text-blue-600 dark:text-blue-400 hover:underline no-underline">← Análisis en datos</a>
    <span>·</span>
    <span class="rounded-full bg-emerald-100 dark:bg-emerald-950/60 px-2.5 py-0.5 text-emerald-800 dark:text-emerald-300">Energía y Transición</span>
    <span>·</span>
    <a href="/energia-clima/mix-electrico" class="hover:underline text-gray-600 dark:text-gray-400 no-underline">Ver panel permanente del mix eléctrico →</a>
</div>

# ⚡ La transformación eléctrica de España: del carbón a superar el 50 % renovable

En menos de dos décadas, el sistema eléctrico español ha vivido uno de los cambios estructurales más rápidos de Europa. Según las series oficiales de **Red Eléctrica de España (REE)** desde {hitos[0]?.anio_inicio}, la generación renovable ha pasado del **{formatNumber(hitos[0]?.renov_inicio, 1)} %** al **{formatNumber(hitos[0]?.cuota_renovable_pct, 1)} %** en {hitos[0]?.anio}, mientras que el carbón —que aportaba una cuarta parte de la electricidad del país ({formatNumber(hitos[0]?.carbon_inicio, 1)} %)— se ha vuelto testimonial ({formatNumber(hitos[0]?.cuota_carbon_pct, 1)} %).

<Grid cols=4>
    <KpiCard
        title="Cuota renovable"
        value={hitos[0]?.cuota_renovable_pct}
        formattedValue="{formatNumber(hitos[0]?.cuota_renovable_pct, 1)} %"
        period="generación anual ({hitos[0]?.anio}) · {formatNumber(hitos[0]?.renov_inicio, 1)} % en {hitos[0]?.anio_inicio}"
        change={hitos[0]?.renov_var_pp?.toFixed(1)}
        changeUnit=" p.p."
        changePeriod="vs año anterior"
        direction="positive-up"
        source="REE"
        href="/energia-clima/mix-electrico"
        sparklineData={elec.map(d => ({...d, y: d.cuota_renovable_pct}))}
    />
    <KpiCard
        title="Libre de emisiones"
        value={hitos[0]?.cuota_libre_emisiones_pct}
        formattedValue="{formatNumber(hitos[0]?.cuota_libre_emisiones_pct, 1)} %"
        period="renovable + nuclear ({hitos[0]?.anio})"
        direction="positive-up"
        source="REE"
        href="/energia-clima/mix-electrico"
        sparklineData={elec.map(d => ({...d, y: d.cuota_libre_emisiones_pct}))}
    />
    <KpiCard
        title="Intensidad de CO₂"
        value={hitos[0]?.g_co2_kwh}
        formattedValue="{formatNumber(hitos[0]?.g_co2_kwh, 0)} g/kWh"
        period="{formatNumber(hitos[0]?.g_var_inicio, 0)} % desde {hitos[0]?.anio_inicio} ({formatNumber(hitos[0]?.g_inicio, 0)} g/kWh)"
        change={hitos[0]?.g_var?.toFixed(1)}
        changePeriod="vs año anterior"
        direction="positive-down"
        source="REE"
        href="/energia-clima/emisiones"
        sparklineData={elec.map(d => ({...d, y: d.g_co2_kwh}))}
    />
    <KpiCard
        title="Cuota del carbón"
        value={hitos[0]?.cuota_carbon_pct}
        formattedValue="{formatNumber(hitos[0]?.cuota_carbon_pct, 1)} %"
        period="en {hitos[0]?.anio} · frente al {formatNumber(hitos[0]?.carbon_inicio, 1)} % en {hitos[0]?.anio_inicio}"
        direction="positive-down"
        source="REE"
        href="/energia-clima/centrales"
        sparklineData={elec.map(d => ({...d, y: d.cuota_carbon_pct}))}
    />
</Grid>

## 1. El relevo tecnológico: dos olas renovables y el cierre del carbón

La transición eléctrica española se explica por dos impulsos sucesivos y un cierre programado:

1. **La primera ola fue eólica:** ya consolidada como primera fuente de generación del país, aporta el **{formatNumber(hitos[0]?.cuota_eolica_pct, 1)} %** de toda la electricidad en {hitos[0]?.anio}.
2. **La segunda ola es solar fotovoltaica:** pasó de apenas el {formatNumber(hitos[0]?.solar_inicio, 1)} % en {hitos[0]?.anio_inicio} al **{formatNumber(hitos[0]?.cuota_solar_fv_pct, 1)} %** en {hitos[0]?.anio}, superando por primera vez al carbón en {hitos[0]?.anio_cruce_solar}.
3. **El cierre de las térmicas de carbón:** entre 2019 y 2020 se desconectó el grueso del parque carbonero por el encarecimiento de los derechos de emisión de CO₂ europeos y el fin de su vida útil regulatoria.

<LineChart
    data={tecnologias_clave}
    x=anio
    y=pct
    series=tecnologia
    xFmt='0'
    yFmt='0"%"'
    yAxisTitle="% de la generación nacional"
    title="El cruce histórico: eólica y solar fotovoltaica frente a carbón y ciclos combinados (gas)"
    colorPalette={['#6b7280', '#f97316', '#16a34a', '#eab308']}
/>

## 2. Más de la mitad renovable y más de tres cuartas partes sin emisiones

En **{hitos[0]?.primer_anio_50}** España superó por primera vez la barrera del **50 % de generación anual renovable**. Si se suma la generación nuclear (que no emite gases de efecto invernadero pero genera residuos radiactivos), el **{formatNumber(hitos[0]?.cuota_libre_emisiones_pct, 1)} %** de los kilovatios hora producidos en {hitos[0]?.anio} estuvieron libres de emisiones directas de CO₂.

<LineChart
    data={cuota_limpia}
    x=anio
    y=pct
    series=serie
    xFmt='0'
    yFmt='0"%"'
    yMin=0
    yMax=100
    yAxisTitle="% de la generación"
    title="Porcentaje de generación renovable y libre de emisiones directas en España"
    colorPalette={['#3b82f6', '#16a34a']}
/>

<Comparativa data={comparativa_ue} />

## 3. El impacto directo en el clima: cada kWh emite una tercera parte de CO₂ que en {hitos[0]?.anio_inicio}

La sustitución de carbón y gas por viento y sol ha desplomado la huella de carbono de la electricidad en España:

- En {hitos[0]?.anio_inicio}, generar un kilovatio hora emitía **{formatNumber(hitos[0]?.g_inicio, 0)} gramos de CO₂ equivalente**.
- En {hitos[0]?.anio}, esa cifra cayó a **{formatNumber(hitos[0]?.g_co2_kwh, 0)} g CO₂eq/kWh** (una reducción del **{formatNumber(Math.abs(hitos[0]?.g_var_inicio), 0)} %**).
- Esto multiplica el beneficio climático de electrificar el transporte ([coche eléctrico](/movilidad/coche-electrico)) o la climatización (bombas de calor), porque cada año que pasa la red eléctrica que los alimenta es más limpia.

<BarChart
    data={elec}
    x=anio
    y=g_co2_kwh
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="g CO₂eq por kWh"
    title="Intensidad de emisiones de CO₂ de la generación eléctrica en España (g CO₂eq/kWh)"
    colorPalette={['#dc2626']}
/>

## 4. Radiografía completa del último año ({hitos[0]?.anio})

<DataTable data={mix_ultimo} search=false>
    <Column id=tecnologia title="Tecnología" />
    <Column id=tipo_fuente title="Tipo" />
    <Column id=cuota_pct title="% de la generación" fmt='0.0"%"' />
    <Column id=generacion_twh title="Generación (TWh)" fmt='0.0' />
</DataTable>

---

**Metodología y fuentes:**
- **Datos de generación y emisiones:** [Red Eléctrica de España (REE) — REData](https://www.ree.es/es/datos/apidatos), balance eléctrico nacional en barras de central (años completos).
- **Comparativa europea:** [Eurostat (`nrg_ind_ren`)](https://ec.europa.eu/eurostat/databrowser/view/nrg_ind_ren/default/table).
- **Para seguir explorando:** Consulta [La electricidad en directo](/energia-clima/directo), [Mix eléctrico](/energia-clima/mix-electrico), [Almacenamiento y bombeo](/energia-clima/almacenamiento), [Electrificación](/energia-clima/electrificacion) y [Emisiones totales de España](/energia-clima/emisiones).
