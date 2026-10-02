---
title: Marcas y modelos más vendidos
description: "Ranking mensual de marcas, modelos y grupos de coches, motos, furgonetas, camiones y autobuses matriculados en España, filtrable por tipo de motor y por canal: particulares, empresas, renting y alquiler."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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

# 🚗 Marcas y modelos más vendidos

Qué se matricula en España cada mes, marca a marca y modelo a modelo, según los microdatos de la Dirección General de Tráfico. Filtra por tipo de motor para ver, por ejemplo, solo los **eléctricos puros**, y por canal para separar lo que compran los **particulares** de las flotas de empresas, renting y alquiler, que en los turismos son más de la mitad.

<div class="not-prose flex flex-wrap gap-4 items-end my-4">
<ButtonGroup name=grupo title="Vehículo">
    <ButtonGroupItem valueLabel="Turismos" value="turismo" default />
    <ButtonGroupItem valueLabel="Motos" value="motocicleta" />
    <ButtonGroupItem valueLabel="Furgonetas" value="furgoneta" />
    <ButtonGroupItem valueLabel="Camiones" value="camion" />
    <ButtonGroupItem valueLabel="Autobuses" value="autobus" />
</ButtonGroup>

<Dropdown name=energia title="Motor" data={energias} value=energia label=energia_etiqueta order=energia_orden>
    <DropdownOption value="todas" valueLabel="Todos los motores" />
</Dropdown>

<Dropdown name=canal title="Canal">
    <DropdownOption value="todos" valueLabel="Todos los canales" />
    <DropdownOption value="particular" valueLabel="Particulares" />
    <DropdownOption value="flotas" valueLabel="Flotas (todo menos particulares)" />
    <DropdownOption value="empresa" valueLabel="Empresas" />
    <DropdownOption value="renting" valueLabel="Renting" />
    <DropdownOption value="alquiler" valueLabel="Alquiler (rent a car)" />
    <DropdownOption value="servicio_publico" valueLabel="Taxi, VTC y otros servicios" />
</Dropdown>

<Dropdown name=periodo title="Periodo" data={periodos} value=valor label=etiqueta order=orden>
    <DropdownOption value="ULTIMO" valueLabel="Último mes publicado" />
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

<p class="text-sm text-gray-600 dark:text-gray-400">{formatNumber(total[0]?.unidades, 0)} unidades nuevas matriculadas de {formatNumber(total[0]?.marcas, 0)} marcas y {formatNumber(total[0]?.modelos, 0)} modelos con los filtros elegidos.</p>

## Grupos

Muchas marcas pertenecen al mismo fabricante y comparten plataformas, motores y fábricas: Peugeot, Citroën, Opel, Fiat o Jeep son de **Stellantis**; Seat, Cupra, Skoda o Audi, de **Volkswagen**; Volvo, Polestar o Lynk & Co, del chino **Geely**; y MG, de **SAIC**. Agrupadas por dueño, el reparto del mercado cambia bastante.

<BarChart
    data={top_grupos_grafico}
    x=grupo
    y=unidades
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#7c3aed"
    title="Los 15 grupos con más matriculaciones"
/>

<DataTable data={grupos} rows=15 search=true>
    <Column id=puesto title="#" />
    <Column id=grupo title="Grupo" />
    <Column id=marcas title="Marcas (de más a menos ventas)" wrap=true />
    <Column id=unidades title="Unidades" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=cuota title="Cuota" fmt=pct1 />
    <Column id=variacion title="Vs. un año antes" fmt=pct0 contentType=delta />
</DataTable>

<p class="text-xs text-gray-500">Grupo según el dueño mayoritario de cada marca. Las participaciones del 50 % o menos no cuentan: Smart (50 % Mercedes-Benz y 50 % Geely) va con Geely y Leapmotor (21 % de Stellantis) es su propio grupo. Las marcas que solo ponen su logo a un coche fabricado por otro, como Ebro (coches de Chery) o DR (de Chery y otros fabricantes chinos), cuentan como grupo propio porque la empresa es otra. En camiones y autobuses, Volvo y Renault son del grupo AB Volvo y Mercedes-Benz, de Daimler Truck, empresas distintas de las de los coches. Las marcas sin grupo en la tabla son su propio grupo.</p>

## Marcas

<BarChart
    data={top_marcas_grafico}
    x=marca
    y=unidades
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Las 20 marcas con más matriculaciones"
/>

<DataTable data={marcas} rows=20 search=true>
    <Column id=puesto title="#" />
    <Column id=marca title="Marca" />
    <Column id=unidades title="Unidades" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota title="Cuota" fmt=pct1 />
    <Column id=variacion title="Vs. un año antes" fmt=pct0 contentType=delta />
</DataTable>

## Modelos

<DataTable data={modelos} rows=25 search=true>
    <Column id=puesto title="#" />
    <Column id=marca title="Marca" />
    <Column id=modelo title="Modelo" />
    <Column id=unidades title="Unidades" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota title="Cuota" fmt=pct1 />
    <Column id=variacion title="Vs. un año antes" fmt=pct0 contentType=delta />
</DataTable>

<p class="text-xs text-gray-500">Solo vehículos nuevos (no se cuentan los usados importados). La variación compara con el mismo periodo del año anterior y se omite cuando entonces había menos de 20 unidades. El nombre del modelo es el de la ficha técnica: algunos coches aparecen con variantes (p. ej. «SANDERO» y «SANDERO STEPWAY»). En los vehículos que termina un carrocero (camiones, autobuses, furgonetas camperizadas) se cuenta la marca del chasis, no la del carrocero.</p>

<p class="text-xs text-gray-500">Canal: los coches de particulares son los matriculados a nombre de una persona física (incluye autónomos) sin renting; empresas, los de personas jurídicas, incluidas las automatriculaciones de concesionarios y marcas que luego se venden como «kilómetro cero»; alquiler, los de servicio de alquiler sin conductor (rent a car); y taxi, VTC y otros, los de servicio público.</p>

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

## ¿Con qué motor vende cada marca?

Reparto por tipo de motor de las 15 marcas que más venden en el periodo elegido (sin tener en cuenta el filtro de motor).

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

**Fuente:** [DGT – Microdatos de matriculaciones de vehículos (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html). Tipo de motor según la categoría de vehículo eléctrico y la propulsión de la ficha técnica: los híbridos no enchufables (HEV) incluyen los *mild hybrid*; los de autonomía extendida (REEV) se cuentan con los enchufables. Más detalles en [Coche eléctrico](/movilidad/coche-electrico).

<LastRefreshed prefix="Datos actualizados" />
