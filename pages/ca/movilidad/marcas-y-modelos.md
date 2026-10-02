---
title: Marques i models més venuts
description: "Rànquing mensual de marques, models i grups de cotxes, motos, furgonetes, camions i autobusos matriculats a Espanya, filtrable per tipus de motor i per canal: particulars, empreses, rènting i lloguer."
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

# 🚗 Marques i models més venuts

Què es matricula a Espanya cada mes, marca a marca i model a model, segons les microdades de la Direcció General de Trànsit. Filtra per tipus de motor per veure, per exemple, només els **elèctrics purs**, i per canal per separar el que compren els **particulars** de les flotes d'empreses, rènting i lloguer, que en els turismes són més de la meitat.

<div class="not-prose flex flex-wrap gap-4 items-end my-4">
<ButtonGroup name=grupo title="Vehicle">
    <ButtonGroupItem valueLabel="Turismes" value="turismo" default />
    <ButtonGroupItem valueLabel="Motos" value="motocicleta" />
    <ButtonGroupItem valueLabel="Furgonetes" value="furgoneta" />
    <ButtonGroupItem valueLabel="Camions" value="camion" />
    <ButtonGroupItem valueLabel="Autobusos" value="autobus" />
</ButtonGroup>

<Dropdown name=energia title="Motor" data={energias} value=energia label=energia_etiqueta order=energia_orden>
    <DropdownOption value="todas" valueLabel="Tots els motors" />
</Dropdown>

<Dropdown name=canal title="Canal">
    <DropdownOption value="todos" valueLabel="Tots els canals" />
    <DropdownOption value="particular" valueLabel="Particulars" />
    <DropdownOption value="flotas" valueLabel="Flotes (tot menys particulars)" />
    <DropdownOption value="empresa" valueLabel="Empreses" />
    <DropdownOption value="renting" valueLabel="Rènting" />
    <DropdownOption value="alquiler" valueLabel="Lloguer (rent a car)" />
    <DropdownOption value="servicio_publico" valueLabel="Taxi, VTC i altres serveis" />
</Dropdown>

<Dropdown name=periodo title="Període" data={periodos} value=valor label=etiqueta order=orden>
    <DropdownOption value="ULTIMO" valueLabel="Últim mes publicat" />
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

<p class="text-sm text-gray-600 dark:text-gray-400">{formatNumber(total[0]?.unidades, 0)} unitats noves matriculades de {formatNumber(total[0]?.marcas, 0)} marques i {formatNumber(total[0]?.modelos, 0)} models amb els filtres triats.</p>

## Grups

Moltes marques pertanyen al mateix fabricant i comparteixen plataformes, motors i fàbriques: Peugeot, Citroën, Opel, Fiat o Jeep són de **Stellantis**; Seat, Cupra, Skoda o Audi, de **Volkswagen**; Volvo, Polestar o Lynk & Co, del xinès **Geely**; i MG, de **SAIC**. Agrupades per propietari, el repartiment del mercat canvia força.

<BarChart
    data={top_grupos_grafico}
    x=grupo
    y=unidades
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#7c3aed"
    title="Els 15 grups amb més matriculacions"
/>

<DataTable data={grupos} rows=15 search=true>
    <Column id=puesto title="#" />
    <Column id=grupo title="Grup" />
    <Column id=marcas title="Marques (de més a menys vendes)" wrap=true />
    <Column id=unidades title="Unitats" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=cuota title="Quota" fmt=pct1 />
    <Column id=variacion title="Vs. un any abans" fmt=pct0 contentType=delta />
</DataTable>

<p class="text-xs text-gray-500">Grup segons el propietari majoritari de cada marca. Les participacions del 50 % o menys no compten: Smart (50 % Mercedes-Benz i 50 % Geely) va amb Geely i Leapmotor (21 % de Stellantis) és el seu propi grup. Les marques que només posen el seu logotip a un cotxe fabricat per un altre, com Ebro (cotxes de Chery) o DR (de Chery i altres fabricants xinesos), compten com a grup propi perquè l'empresa és una altra. En camions i autobusos, Volvo i Renault són del grup AB Volvo i Mercedes-Benz, de Daimler Truck, empreses diferents de les dels cotxes. Les marques sense grup a la taula són el seu propi grup.</p>

## Marques

<BarChart
    data={top_marcas_grafico}
    x=marca
    y=unidades
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Les 20 marques amb més matriculacions"
/>

<DataTable data={marcas} rows=20 search=true>
    <Column id=puesto title="#" />
    <Column id=marca title="Marca" />
    <Column id=unidades title="Unitats" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota title="Quota" fmt=pct1 />
    <Column id=variacion title="Vs. un any abans" fmt=pct0 contentType=delta />
</DataTable>

## Models

<DataTable data={modelos} rows=25 search=true>
    <Column id=puesto title="#" />
    <Column id=marca title="Marca" />
    <Column id=modelo title="Model" />
    <Column id=unidades title="Unitats" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota title="Quota" fmt=pct1 />
    <Column id=variacion title="Vs. un any abans" fmt=pct0 contentType=delta />
</DataTable>

<p class="text-xs text-gray-500">Només vehicles nous (no es compten els usats importats). La variació compara amb el mateix període de l'any anterior i s'omet quan llavors hi havia menys de 20 unitats. El nom del model és el de la fitxa tècnica: alguns cotxes apareixen amb variants (p. ex. «SANDERO» i «SANDERO STEPWAY»). En els vehicles que acaba un carrosser (camions, autobusos, furgonetes camperitzades) es compta la marca del xassís, no la del carrosser.</p>

<p class="text-xs text-gray-500">Canal: els cotxes de particulars són els matriculats a nom d'una persona física (inclou autònoms) sense rènting; empreses, els de persones jurídiques, incloses les automatriculacions de concessionaris i marques que després es venen com a «quilòmetre zero»; lloguer, els de servei de lloguer sense conductor (<em>rent a car</em>); i taxi, VTC i altres, els de servei públic.</p>

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

## Amb quin motor ven cada marca?

Repartiment per tipus de motor de les 15 marques que més venen en el període triat (sense tenir en compte el filtre de motor).

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

**Font:** [DGT – Microdades de matriculacions de vehicles (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html). Tipus de motor segons la categoria de vehicle elèctric i la propulsió de la fitxa tècnica: els híbrids no endollables (HEV) inclouen els *mild hybrid*; els d'autonomia estesa (REEV) es compten amb els endollables. Més detalls a [Cotxe elèctric](/ca/movilidad/coche-electrico).

<LastRefreshed prefix="Dades actualitzades" />
