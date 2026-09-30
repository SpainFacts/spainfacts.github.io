---
title: Electricity storage
description: "Pumped hydro and batteries in Spain: how much energy they store and return, installed capacity by region, round-trip efficiency and projects with grid access permits against the PNIEC target of 22.5 GW for 2030."
i18n_origen: 664df261ab3d
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql potencia_ultima
SELECT
    strftime(max(mes), '%m/%Y') AS mes_texto,
    sum(mw) FILTER (WHERE tipo = 'bombeo_puro') AS bombeo_mw,
    sum(mw) FILTER (WHERE tipo = 'baterias_hibridadas') AS baterias_mw
FROM mother.almacenamiento_potencia
WHERE mes = (SELECT max(mes) FROM mother.almacenamiento_potencia)
```

```sql baterias_serie
SELECT mes, sum(mw) AS valor
FROM mother.almacenamiento_potencia
WHERE tipo = 'baterias_hibridadas'
GROUP BY mes
ORDER BY mes ASC
```

```sql acceso_total
SELECT
    strftime(max(fecha_fichero), '%d/%m/%Y') AS fecha_texto,
    sum(otorgada_mw) AS otorgada_mw,
    sum(en_tramitacion_mw) AS en_tramitacion_mw
FROM mother.almacenamiento_acceso
WHERE fecha_fichero = (SELECT max(fecha_fichero) FROM mother.almacenamiento_acceso)
```

```sql anual
SELECT
    CAST(year(mes) AS INTEGER) AS anio,
    count(*) AS meses,
    sum(bombeo_turbinado_gwh) AS bombeo_turbinado_gwh,
    sum(bombeo_consumido_gwh) AS bombeo_consumido_gwh,
    sum(baterias_entregado_gwh) AS baterias_entregado_gwh,
    sum(baterias_cargado_gwh) AS baterias_cargado_gwh,
    sum(bombeo_turbinado_gwh) / sum(bombeo_consumido_gwh) AS rendimiento
FROM mother.almacenamiento_mensual
GROUP BY 1
ORDER BY 1
```

```sql ultimo_anio
SELECT * FROM ${anual} WHERE meses = 12 ORDER BY anio DESC LIMIT 1
```

```sql anio_2019
SELECT * FROM ${anual} WHERE anio = 2019
```

# 🔋 Electricity storage

With ever more solar and wind power, the electricity system needs to store the surplus energy produced when the sun shines or the wind blows and return it when they do not. In Spain today this is done mainly by **pumped-storage plants** (which pump water up to an upper reservoir and run it through turbines later), and **batteries** are starting to arrive.

<Grid cols=4>
    <KpiCard
        title="Pure pumped storage installed"
        value={potencia_ultima[0]?.bombeo_mw}
        formattedValue="{formatNumber(potencia_ultima[0]?.bombeo_mw, 0)} MW"
        period="excluding mixed pumped storage · {potencia_ultima[0]?.mes_texto}"
        source="REE (ESIOS)"
    />
    <KpiCard
        title="Batteries alongside renewables"
        value={potencia_ultima[0]?.baterias_mw}
        formattedValue="{formatNumber(potencia_ultima[0]?.baterias_mw, 0)} MW"
        period="hybridised with solar or wind farms · {potencia_ultima[0]?.mes_texto}"
        source="REE (ESIOS)"
        sparklineData={baterias_serie}
    />
    <KpiCard
        title="Energy returned by pumped storage"
        value={ultimo_anio[0]?.bombeo_turbinado_gwh}
        formattedValue="{formatNumber(ultimo_anio[0]?.bombeo_turbinado_gwh / 1000, 1)} TWh"
        period="in {ultimo_anio[0]?.anio} · {formatNumber(ultimo_anio[0]?.bombeo_turbinado_gwh / anio_2019[0]?.bombeo_turbinado_gwh, 1)} times the 2019 figure"
        source="REE (balance)"
        sparklineData={anual.filter(d => Number(d.meses) === 12).map(d => ({valor: d.bombeo_turbinado_gwh / 1000}))}
    />
    <KpiCard
        title="Storage with grid access permits"
        value={acceso_total[0]?.otorgada_mw}
        formattedValue="{formatNumber(acceso_total[0]?.otorgada_mw / 1000, 1)} GW"
        period="plus {formatNumber(acceso_total[0]?.en_tramitacion_mw / 1000, 1)} GW being processed · PNIEC 2030 target: 22.5 GW"
        source="REE"
    />
</Grid>

## How much energy is stored

```sql anual_grafico
SELECT anio, 'Consumida para almacenar' AS flujo, bombeo_consumido_gwh + coalesce(baterias_cargado_gwh, 0) AS gwh FROM ${anual}
UNION ALL
SELECT anio, 'Devuelta a la red', bombeo_turbinado_gwh + coalesce(baterias_entregado_gwh, 0) FROM ${anual}
ORDER BY anio
```

<BarChart
    data={anual_grafico}
    x=anio
    y=gwh
    series=flujo
    type=grouped
    yFmt=num0
    xFmt="####"
    yAxisTitle="GWh"
    colorPalette={['#94a3b8', '#0f766e']}
    title="Pumped storage and batteries: energy consumed and returned each year"
/>

<p class="text-xs text-gray-500">The latest year is incomplete. Storage is a net consumer: for every 100 kWh used to pump water, about {formatNumber(100 * ultimo_anio[0]?.rendimiento, 0)} are recovered ({ultimo_anio[0]?.anio}). It pays off because water is pumped when electricity is plentiful and cheap (at midday, with solar) and run through the turbines when it is scarce and expensive. Pumped-storage generation has more than doubled since 2021 (from 2.6 to 5.9 TWh in 2025): there are more and more hours of solar surplus to make use of.</p>

```sql mensual
SELECT mes, bombeo_turbinado_gwh, bombeo_consumido_gwh
FROM mother.almacenamiento_mensual
ORDER BY mes
```

<LineChart
    data={mensual}
    x=mes
    y={['bombeo_consumido_gwh', 'bombeo_turbinado_gwh']}
    yFmt=num0
    xFmt="mmm yyyy"
    seriesLabels={{bombeo_consumido_gwh: 'Consumption for pumping', bombeo_turbinado_gwh: 'Turbine generation'}}
    colorPalette={['#94a3b8', '#0f766e']}
    legend=true
    yAxisTitle="GWh per month"
    title="Pumped storage month by month"
/>

## Batteries

```sql baterias_mensual
SELECT mes, baterias_entregado_gwh * 1000 AS entregado_mwh, baterias_cargado_gwh * 1000 AS cargado_mwh
FROM mother.almacenamiento_mensual
WHERE baterias_entregado_gwh IS NOT NULL OR baterias_cargado_gwh IS NOT NULL
ORDER BY mes
```

```sql baterias_potencia
SELECT mes, sum(mw) AS mw
FROM mother.almacenamiento_potencia
WHERE tipo = 'baterias_hibridadas'
GROUP BY mes
ORDER BY mes
```

<Grid cols=2>
    <BarChart
        data={baterias_mensual}
        x=mes
        y={['cargado_mwh', 'entregado_mwh']}
        type=grouped
        yFmt=num0
        xFmt="mmm yyyy"
        seriesLabels={{cargado_mwh: 'Charged', entregado_mwh: 'Discharged'}}
        colorPalette={['#94a3b8', '#7c3aed']}
        yAxisTitle="MWh"
        title="Battery energy each month"
    />
    <LineChart
        data={baterias_potencia}
        x=mes
        y=mw
        yFmt=num0
        xFmt="mmm yyyy"
        lineColor="#7c3aed"
        yAxisTitle="MW"
        title="Capacity of batteries hybridised with renewables"
    />
</Grid>

<p class="text-xs text-gray-500">Batteries are still small compared with pumped storage (in 2025 they moved about 800 times less energy), but installed capacity is growing and there are thousands of megawatts with grid access permits. REE only publishes separate figures for batteries hybridised with renewable plants; standalone batteries (connected to the grid on their own) and those used for self-consumption in homes and businesses have no open official statistics.</p>

```sql diario
SELECT fecha,
    bombeo_consumido_mwh / 1000 AS consumo_gwh,
    bombeo_turbinado_mwh / 1000 AS turbinado_gwh,
    bombeo_consumido_pico_mw, bombeo_turbinado_pico_mw
FROM mother.almacenamiento_diario
WHERE fecha >= (SELECT max(fecha) FROM mother.almacenamiento_diario) - INTERVAL 365 DAY
ORDER BY fecha
```

```sql picos
SELECT
    max(bombeo_consumido_pico_mw) AS max_consumo_mw,
    arg_max(strftime(fecha, '%d/%m/%Y'), bombeo_consumido_pico_mw) AS dia_max_consumo,
    max(bombeo_turbinado_pico_mw) AS max_turbinado_mw,
    arg_max(strftime(fecha, '%d/%m/%Y'), bombeo_turbinado_pico_mw) AS dia_max_turbinado
FROM mother.almacenamiento_diario
```

## The last year, day by day

<LineChart
    data={diario}
    x=fecha
    y={['consumo_gwh', 'turbinado_gwh']}
    yFmt=num1
    seriesLabels={{consumo_gwh: 'Consumption for pumping', turbinado_gwh: 'Turbine generation'}}
    colorPalette={['#94a3b8', '#0f766e']}
    legend=true
    yAxisTitle="GWh per day"
/>

{#if picos.length > 0 && picos[0]?.max_consumo_mw}
<p class="text-xs text-gray-500">Records since daily data became available (late 2024): {formatNumber(picos[0].max_consumo_mw, 0)} MW pumping simultaneously ({picos[0].dia_max_consumo}) and {formatNumber(picos[0].max_turbinado_mw, 0)} MW generating ({picos[0].dia_max_turbinado}). March to May, with plenty of sun and water, is when most pumping takes place. Real-time ESIOS data (may differ slightly from the final balance).</p>
{/if}

## Where it is

```sql potencia_ccaa
SELECT
    p.cod_ccaa,
    p.comunidad,
    sum(p.mw) FILTER (WHERE p.tipo = 'bombeo_puro') AS bombeo_mw,
    sum(p.mw) FILTER (WHERE p.tipo = 'baterias_hibridadas') AS baterias_mw
FROM mother.almacenamiento_potencia p
WHERE p.mes = (SELECT max(mes) FROM mother.almacenamiento_potencia)
GROUP BY ALL
```

```sql acceso_ccaa
SELECT
    a.cod_ccaa,
    a.comunidad,
    a.otorgada_mw,
    a.en_tramitacion_mw,
    a.nudos,
    coalesce(p.bombeo_mw, 0) AS bombeo_mw,
    coalesce(p.baterias_mw, 0) AS baterias_mw
FROM mother.almacenamiento_acceso a
LEFT JOIN ${potencia_ccaa} p ON p.cod_ccaa = a.cod_ccaa
WHERE a.fecha_fichero = (SELECT max(fecha_fichero) FROM mother.almacenamiento_acceso)
  AND (a.otorgada_mw > 0 OR a.en_tramitacion_mw > 0 OR p.bombeo_mw > 0)
ORDER BY a.otorgada_mw DESC
```

```sql acceso_grafico
SELECT comunidad, 'Con permiso de acceso' AS estado, otorgada_mw / 1000 AS gw FROM ${acceso_ccaa}
UNION ALL
SELECT comunidad, 'En tramitación', en_tramitacion_mw / 1000 FROM ${acceso_ccaa}
```

<BarChart
    data={acceso_grafico}
    x=comunidad
    y=gw
    series=estado
    swapXY=true
    yFmt=num1
    colorPalette={['#0f766e', '#99f6e4']}
    title="Storage projects with access to the transmission grid (GW)"
/>

<DataTable data={acceso_ccaa} rows=all>
    <Column id=comunidad title="Region" />
    <Column id=bombeo_mw title="Pure pumped storage installed (MW)" fmt=num0 />
    <Column id=baterias_mw title="Hybridised batteries (MW)" fmt=num0 />
    <Column id=otorgada_mw title="Access granted (MW)" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=en_tramitacion_mw title="Being processed (MW)" fmt=num0 />
    <Column id=nudos title="Substations" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">An access permit reserves capacity at a substation on REE's transmission grid; it does not mean that the project has been built or that it will be. Projects connected to the distribution grid are not included. Spain's National Integrated Energy and Climate Plan (PNIEC 2023-2030) envisages 22.5 GW of storage by 2030.</p>

---

## Sources and notes

- **[REE – Electricity balance (REData)](https://www.ree.es/es/datos/balance/balance-electrico)**: pumped-storage generation and consumption, battery discharge and charge, monthly since 2015. This is the official figure.
- **[REE – ESIOS](https://www.esios.ree.es/)**: indicators 2066/2065 (pumped storage) and 2198/2199 (batteries) in real time, and installed capacity of pure pumped storage (1476) and hybridised batteries (2275) by region.
- **[REE – Access capacity of the transmission grid](https://www.ree.es/es/clientes/generador/acceso-conexion/conoce-la-capacidad-de-acceso)**: capacity granted and being processed for storage by node; SpainFacts keeps a snapshot of each monthly file.
- **[MITECO – PNIEC 2023-2030](https://www.miteco.gob.es/es/prensa/pniec.html)**: storage target.
- Pure pumped-storage capacity does not include mixed pumped-storage plants (which also receive natural inflows from a river), which ESIOS does not break down: total pumped-storage capacity is higher.

<LastRefreshed prefix="Data updated" />
