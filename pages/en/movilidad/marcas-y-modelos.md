---
title: Best-selling makes and models
description: "Monthly ranking of makes, models and groups of cars, motorbikes, vans, trucks and buses registered in Spain, filterable by engine type and by channel: private buyers, companies, renting and rental."
i18n_origen: ae4008cde621
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql energias
SELECT DISTINCT energia, energia_etiqueta, energia_orden
FROM mother.movilidad_matriculaciones_mensual
ORDER BY energia_orden
```

```sql periodos
WITH meses AS (
    SELECT DISTINCT mes FROM mother.movilidad_modelos_mensual
)
SELECT valor, etiqueta, orden FROM (
    SELECT
        'M' || strftime(mes, '%Y-%m') AS valor,
        strftime(mes, '%m/%Y') AS etiqueta,
        -CAST(epoch(mes) AS BIGINT) AS orden
    FROM meses
    UNION ALL
    SELECT
        'A' || CAST(CAST(year(mes) AS INTEGER) AS VARCHAR) AS valor,
        'Año ' || CAST(CAST(year(mes) AS INTEGER) AS VARCHAR) || ' (' || CAST(count(*) AS VARCHAR) || ' meses)' AS etiqueta,
        -CAST(epoch(max(mes)) AS BIGINT) - 1 AS orden
    FROM meses
    GROUP BY year(mes)
)
ORDER BY orden
```

# 🚗 Best-selling makes and models

What gets registered in Spain every month, make by make and model by model, according to the microdata of the Directorate-General for Traffic (DGT). Filter by engine type to see, for example, only **battery electric** cars, and by channel to separate what **private buyers** purchase from the fleets of companies, renting and rental, which account for more than half of passenger cars.

<div class="not-prose flex flex-wrap gap-4 items-end my-4">
<ButtonGroup name=grupo title="Vehicle">
    <ButtonGroupItem valueLabel="Cars" value="turismo" default />
    <ButtonGroupItem valueLabel="Motorbikes" value="motocicleta" />
    <ButtonGroupItem valueLabel="Vans" value="furgoneta" />
    <ButtonGroupItem valueLabel="Trucks" value="camion" />
    <ButtonGroupItem valueLabel="Buses" value="autobus" />
</ButtonGroup>

<Dropdown name=energia title="Engine" data={energias} value=energia label=energia_etiqueta order=energia_orden>
    <DropdownOption value="todas" valueLabel="All engines" />
</Dropdown>

<Dropdown name=canal title="Channel">
    <DropdownOption value="todos" valueLabel="All channels" />
    <DropdownOption value="particular" valueLabel="Private buyers" />
    <DropdownOption value="flotas" valueLabel="Fleets (all except private buyers)" />
    <DropdownOption value="empresa" valueLabel="Companies" />
    <DropdownOption value="renting" valueLabel="Renting" />
    <DropdownOption value="alquiler" valueLabel="Rental (rent a car)" />
    <DropdownOption value="servicio_publico" valueLabel="Taxi, VTC and other services" />
</Dropdown>

<Dropdown name=periodo title="Period" data={periodos} value=valor label=etiqueta order=orden>
    <DropdownOption value="ULTIMO" valueLabel="Latest month published" />
</Dropdown>
</div>

```sql periodo_sel
-- "Último mes publicado" se traduce al código del mes más reciente (M2026-08)
SELECT CASE WHEN '${inputs.periodo.value}' = 'ULTIMO'
            THEN 'M' || strftime(max(mes), '%Y-%m')
            ELSE '${inputs.periodo.value}' END AS p
FROM mother.movilidad_modelos_mensual
```

```sql filtro
SELECT *
FROM mother.movilidad_modelos_mensual
WHERE grupo = '${inputs.grupo}'
  AND ('${inputs.energia.value}' = 'todas' OR energia = '${inputs.energia.value}')
  AND ('${inputs.canal.value}' = 'todos' OR ('${inputs.canal.value}' = 'flotas' AND canal <> 'particular') OR canal = '${inputs.canal.value}')
  AND (
    ((SELECT p FROM ${periodo_sel}) LIKE 'M%' AND strftime(mes, '%Y-%m') = substr((SELECT p FROM ${periodo_sel}), 2))
    OR ((SELECT p FROM ${periodo_sel}) LIKE 'A%' AND CAST(year(mes) AS INTEGER) = TRY_CAST(substr((SELECT p FROM ${periodo_sel}), 2) AS INTEGER))
  )
```

```sql filtro_anterior
-- Mismo periodo un año antes, para la variación
SELECT marca, grupo_empresarial, modelo, sum(matriculaciones) AS unidades
FROM mother.movilidad_modelos_mensual
WHERE grupo = '${inputs.grupo}'
  AND ('${inputs.energia.value}' = 'todas' OR energia = '${inputs.energia.value}')
  AND ('${inputs.canal.value}' = 'todos' OR ('${inputs.canal.value}' = 'flotas' AND canal <> 'particular') OR canal = '${inputs.canal.value}')
  AND (
    ((SELECT p FROM ${periodo_sel}) LIKE 'M%' AND strftime(mes + INTERVAL 12 MONTH, '%Y-%m') = substr((SELECT p FROM ${periodo_sel}), 2))
    OR ((SELECT p FROM ${periodo_sel}) LIKE 'A%' AND CAST(year(mes) AS INTEGER) + 1 = TRY_CAST(substr((SELECT p FROM ${periodo_sel}), 2) AS INTEGER)
        AND month(mes) <= (SELECT max(month(mes)) FROM ${filtro}))
  )
GROUP BY marca, grupo_empresarial, modelo
```

```sql total
SELECT sum(matriculaciones) AS unidades, count(DISTINCT marca) AS marcas, count(DISTINCT marca || modelo) AS modelos
FROM ${filtro}
```

```sql marcas
WITH act AS (
    SELECT marca, sum(matriculaciones) AS unidades FROM ${filtro} GROUP BY marca
),
ant AS (
    SELECT marca, sum(unidades) AS unidades FROM ${filtro_anterior} GROUP BY marca
)
SELECT
    row_number() OVER (ORDER BY a.unidades DESC, a.marca) AS puesto,
    a.marca,
    a.unidades,
    a.unidades / sum(a.unidades) OVER () AS cuota,
    CASE WHEN p.unidades >= 20 THEN a.unidades / p.unidades - 1 END AS variacion
FROM act a
LEFT JOIN ant p ON p.marca = a.marca
ORDER BY a.unidades DESC, a.marca
```

```sql modelos
WITH act AS (
    SELECT marca, modelo, sum(matriculaciones) AS unidades FROM ${filtro} GROUP BY marca, modelo
)
SELECT
    row_number() OVER (ORDER BY a.unidades DESC, a.marca, a.modelo) AS puesto,
    a.marca,
    a.modelo,
    a.unidades,
    a.unidades / sum(a.unidades) OVER () AS cuota,
    CASE WHEN p.unidades >= 20 THEN a.unidades / p.unidades - 1 END AS variacion
FROM act a
LEFT JOIN ${filtro_anterior} p ON p.marca = a.marca AND p.modelo = a.modelo
ORDER BY a.unidades DESC, a.marca, a.modelo
```

```sql grupos
WITH act AS (
    SELECT grupo_empresarial AS grupo, marca, sum(matriculaciones) AS unidades
    FROM ${filtro} GROUP BY ALL
),
ant AS (
    SELECT grupo_empresarial AS grupo, sum(unidades) AS unidades FROM ${filtro_anterior} GROUP BY ALL
),
g AS (
    SELECT grupo, sum(unidades) AS unidades, count(*) AS n_marcas,
        string_agg(marca, ', ' ORDER BY unidades DESC) AS marcas
    FROM act GROUP BY grupo
)
SELECT
    row_number() OVER (ORDER BY g.unidades DESC, g.grupo) AS puesto,
    g.grupo, g.marcas, g.n_marcas, g.unidades,
    g.unidades / sum(g.unidades) OVER () AS cuota,
    CASE WHEN p.unidades >= 20 THEN g.unidades / p.unidades - 1 END AS variacion
FROM g
LEFT JOIN ant p ON p.grupo = g.grupo
ORDER BY g.unidades DESC, g.grupo
```

```sql top_grupos_grafico
SELECT grupo, unidades FROM ${grupos} WHERE puesto <= 15 ORDER BY unidades DESC
```

```sql top_marcas_grafico
SELECT marca, unidades FROM ${marcas} WHERE puesto <= 20 ORDER BY unidades DESC
```

<p class="text-sm text-gray-600 dark:text-gray-400">{formatNumber(total[0]?.unidades, 0)} new units registered across {formatNumber(total[0]?.marcas, 0)} makes and {formatNumber(total[0]?.modelos, 0)} models with the selected filters.</p>

## Groups

Many makes belong to the same manufacturer and share platforms, engines and factories: Peugeot, Citroën, Opel, Fiat and Jeep belong to **Stellantis**; Seat, Cupra, Skoda and Audi to **Volkswagen**; Volvo, Polestar and Lynk & Co to China's **Geely**; and MG to **SAIC**. Grouped by owner, the market split changes considerably.

<BarChart
    data={top_grupos_grafico}
    x=grupo
    y=unidades
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#7c3aed"
    title="The 15 groups with the most registrations"
/>

<DataTable data={grupos} rows=15 search=true>
    <Column id=puesto title="#" />
    <Column id=grupo title="Group" />
    <Column id=marcas title="Makes (from most to fewest sales)" wrap=true />
    <Column id=unidades title="Units" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=cuota title="Share" fmt=pct1 />
    <Column id=variacion title="Vs. a year earlier" fmt=pct0 contentType=delta />
</DataTable>

<p class="text-xs text-gray-500">Group according to the majority owner of each make. Stakes of 50% or less do not count: Smart (50% Mercedes-Benz and 50% Geely) goes with Geely, and Leapmotor (21% owned by Stellantis) is its own group. Makes that only put their badge on a car built by another manufacturer, such as Ebro (Chery cars) or DR (from Chery and other Chinese manufacturers), count as their own group because the company is different. In trucks and buses, Volvo and Renault belong to the AB Volvo group and Mercedes-Benz to Daimler Truck, companies separate from the car ones. Makes without a group in the table are their own group.</p>

## Makes

<BarChart
    data={top_marcas_grafico}
    x=marca
    y=unidades
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="The 20 makes with the most registrations"
/>

<DataTable data={marcas} rows=20 search=true>
    <Column id=puesto title="#" />
    <Column id=marca title="Make" />
    <Column id=unidades title="Units" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota title="Share" fmt=pct1 />
    <Column id=variacion title="Vs. a year earlier" fmt=pct0 contentType=delta />
</DataTable>

## Models

<DataTable data={modelos} rows=25 search=true>
    <Column id=puesto title="#" />
    <Column id=marca title="Make" />
    <Column id=modelo title="Model" />
    <Column id=unidades title="Units" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota title="Share" fmt=pct1 />
    <Column id=variacion title="Vs. a year earlier" fmt=pct0 contentType=delta />
</DataTable>

<p class="text-xs text-gray-500">New vehicles only (imported used vehicles are not counted). The change is measured against the same period a year earlier and is omitted when there were fewer than 20 units back then. The model name is the one on the technical data sheet: some cars appear with variants (e.g. «SANDERO» and «SANDERO STEPWAY»). For vehicles finished by a bodybuilder (trucks, buses, camper vans) the chassis make is counted, not the bodybuilder's.</p>

<p class="text-xs text-gray-500">Channel: private buyers' cars are those registered to a natural person (including the self-employed) without renting; companies, those of legal entities, including self-registrations by dealers and brands that are later sold as "zero-kilometre" cars; rental, those for rental service without driver (rent a car); and taxi, VTC and others, those for public service.</p>

```sql mix_marcas
-- Mezcla de motores de las 15 primeras marcas (sin filtrar por motor)
WITH base AS (
    SELECT m.marca, m.energia, sum(m.matriculaciones) AS unidades
    FROM mother.movilidad_modelos_mensual m
    WHERE m.grupo = '${inputs.grupo}'
  AND ('${inputs.canal.value}' = 'todos' OR ('${inputs.canal.value}' = 'flotas' AND m.canal <> 'particular') OR m.canal = '${inputs.canal.value}')
      AND (
        ((SELECT p FROM ${periodo_sel}) LIKE 'M%' AND strftime(m.mes, '%Y-%m') = substr((SELECT p FROM ${periodo_sel}), 2))
        OR ((SELECT p FROM ${periodo_sel}) LIKE 'A%' AND CAST(year(m.mes) AS INTEGER) = TRY_CAST(substr((SELECT p FROM ${periodo_sel}), 2) AS INTEGER))
      )
    GROUP BY ALL
),
top AS (
    SELECT marca FROM base GROUP BY marca ORDER BY sum(unidades) DESC LIMIT 15
)
SELECT b.marca, e.energia_etiqueta AS motor, e.energia_orden, b.unidades / sum(b.unidades) OVER (PARTITION BY b.marca) AS cuota
FROM base b
JOIN top t ON t.marca = b.marca
JOIN ${energias} e ON e.energia = b.energia
ORDER BY e.energia_orden
```

## Which engines does each make sell?

Breakdown by engine type of the 15 best-selling makes in the selected period (ignoring the engine filter).

<BarChart
    data={mix_marcas}
    x=marca
    y=cuota
    series=motor
    swapXY=true
    type=stacked100
    yFmt=pct0
    seriesOrder={energias.map(d => d.energia_etiqueta)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
/>

---

**Source:** [DGT – Vehicle registration microdata (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html). Engine type is based on the electric vehicle category and the propulsion recorded in the technical data sheet: non-plug-in hybrids (HEV) include *mild hybrids*; extended-range electric vehicles (REEV) are counted with plug-ins. More details in [Electric cars](/en/movilidad/coche-electrico).

<LastRefreshed prefix="Data updated" />
