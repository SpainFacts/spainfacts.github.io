---
i18n_origen: e10a6f5a05a5
title: Parque de vehículos
description: "Os vehículos que circulan en España: turismos por tipo de motor, etiqueta ambiental da DGT e antigüidade, modelos máis comúns e comparación por provincia e concello."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql energias
SELECT DISTINCT energia, energia_etiqueta, energia_orden
FROM mother.movilidad_matriculaciones_mensual
ORDER BY energia_orden
```

```sql resumen
SELECT
    strftime(max(mes), '%m/%Y') AS mes_texto,
    sum(vehiculos) AS vehiculos,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo') AS turismos,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo' AND energia IN ('bev', 'phev')) AS enchufables,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo' AND energia = 'bev') AS bev,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo' AND distintivo = 'SIN') AS sin_distintivo,
    sum(vehiculos) FILTER (WHERE grupo = 'turismo' AND antiguedad = '20+') AS mas_de_20,
    (SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total' ORDER BY anio DESC LIMIT 1) AS poblacion
FROM mother.movilidad_parque_provincia
```

# 🅿️ O parque de vehículos

Os vehículos que están dados de alta na Dirección General de Tráfico, é dicir, os que poden circular hoxe por España: que motor levan, que etiqueta ambiental teñen e cantos anos acumulan.

```sql parque_mensual
SELECT mes, turismos_1000, pct_enchufables, pct_bev, pct_sin_distintivo
FROM mother.movilidad_parque_resumen
ORDER BY mes
```

<Grid cols=3>
    <KpiCard
        title="Turismos en circulación"
        value={resumen[0]?.turismos}
        formattedValue="{formatNumber(1000 * resumen[0]?.turismos / resumen[0]?.poblacion, 0)} por 1.000 hab."
        period="{formatCompact(resumen[0]?.turismos, 1)} turismos e {formatCompact(resumen[0]?.vehiculos, 1)} vehículos de todo tipo · {resumen[0]?.mes_texto}"
        source="DGT"
        sparklineData={parque_mensual.map(d => d.turismos_1000)}
    />
    <KpiCard
        title="Turismos enchufables"
        value={parque_mensual.slice(-1)[0]?.pct_enchufables}
        formattedValue="{formatNumber(parque_mensual.slice(-1)[0]?.pct_enchufables, 1)} %"
        period="dos turismos · {formatNumber(resumen[0]?.enchufables, 0)} enchufables, {formatNumber(resumen[0]?.bev, 0)} eléctricos puros"
        source="DGT"
        sparklineData={parque_mensual.map(d => d.pct_enchufables)}
    />
    <KpiCard
        title="Turismos sen etiqueta ambiental"
        value={parque_mensual.slice(-1)[0]?.pct_sin_distintivo}
        formattedValue="{formatNumber(parque_mensual.slice(-1)[0]?.pct_sin_distintivo, 1)} %"
        period="dos turismos · {formatCompact(resumen[0]?.sin_distintivo, 1)} coches · gasolina anterior a 2000 e diésel anterior a 2006"
        direction="positive-down"
        source="DGT"
        sparklineData={parque_mensual.map(d => d.pct_sin_distintivo)}
    />
</Grid>

<p class="text-xs text-gray-500">As minigráficas empezan en marzo de 2025: a DGT só conserva os ficheiros de parque dos últimos meses, e a serie medra con cada publicación mensual.</p>

<ButtonGroup name=grupo title="Vehículo">
    <ButtonGroupItem valueLabel="Turismos" value="turismo" default />
    <ButtonGroupItem valueLabel="Motos" value="motocicleta" />
    <ButtonGroupItem valueLabel="Furgonetas" value="furgoneta" />
    <ButtonGroupItem valueLabel="Camións" value="camion" />
    <ButtonGroupItem valueLabel="Autobuses" value="autobus" />
</ButtonGroup>

```sql por_energia
SELECT e.energia_etiqueta AS motor, e.energia_orden, sum(p.vehiculos) AS vehiculos
FROM mother.movilidad_parque_provincia p
JOIN ${energias} e ON e.energia = p.energia
WHERE p.grupo = '${inputs.grupo}'
GROUP BY ALL
ORDER BY e.energia_orden
```

```sql por_distintivo
SELECT
    CASE distintivo WHEN 'CERO' THEN '0 emisiones (azul)' WHEN 'ECO' THEN 'ECO' WHEN 'C' THEN 'C (verde)' WHEN 'B' THEN 'B (amarilla)' ELSE 'Sin etiqueta' END AS etiqueta,
    CASE distintivo WHEN 'CERO' THEN 1 WHEN 'ECO' THEN 2 WHEN 'C' THEN 3 WHEN 'B' THEN 4 ELSE 5 END AS orden,
    sum(vehiculos) AS vehiculos
FROM mother.movilidad_parque_provincia
WHERE grupo = '${inputs.grupo}'
GROUP BY ALL
ORDER BY orden
```

```sql por_antiguedad
SELECT antiguedad || ' años' AS antiguedad, sum(vehiculos) AS vehiculos
FROM mother.movilidad_parque_provincia
WHERE grupo = '${inputs.grupo}' AND antiguedad <> 'desconocida'
GROUP BY antiguedad
ORDER BY CASE antiguedad WHEN '0-4' THEN 1 WHEN '5-9' THEN 2 WHEN '10-14' THEN 3 WHEN '15-19' THEN 4 ELSE 5 END
```

<Grid cols=3>
    <BarChart data={por_energia} x=motor y=vehiculos sort=false swapXY=true yFmt=num0 fillColor="#0f766e" title="Por tipo de motor" />
    <BarChart data={por_distintivo} x=etiqueta y=vehiculos sort=false swapXY=true yFmt=num0 fillColor="#14b8a6" title="Por etiqueta ambiental" />
    <BarChart data={por_antiguedad} x=antiguedad y=vehiculos sort=false swapXY=true yFmt=num0 fillColor="#78716c" title="Por antigüidade" />
</Grid>

<p class="text-xs text-gray-500">Antigüidade desde a data de matriculación en España (nos usados importados, desde que se matricularon aquí). A etiqueta ambiental é a que a DGT asigna a cada vehículo segundo o seu motor e a súa norma Euro.</p>

## Modelos máis comúns

<Dropdown name=energia title="Motor" data={energias} value=energia label=energia_etiqueta order=energia_orden>
    <DropdownOption value="todas" valueLabel="Todos os motores" />
</Dropdown>

```sql modelos
SELECT
    row_number() OVER (ORDER BY sum(vehiculos) DESC, marca, modelo) AS puesto,
    marca,
    modelo,
    sum(vehiculos) AS vehiculos
FROM mother.movilidad_parque_modelos
WHERE grupo = '${inputs.grupo}'
  AND ('${inputs.energia.value}' = 'todas' OR energia = '${inputs.energia.value}')
  AND modelo <> '(modelo sin especificar)'
GROUP BY marca, modelo
ORDER BY vehiculos DESC
```

```sql marcas_parque
SELECT
    row_number() OVER (ORDER BY sum(vehiculos) DESC, marca) AS puesto,
    marca,
    sum(vehiculos) AS vehiculos,
    sum(vehiculos) / sum(sum(vehiculos)) OVER () AS cuota
FROM mother.movilidad_parque_modelos
WHERE grupo = '${inputs.grupo}'
  AND ('${inputs.energia.value}' = 'todas' OR energia = '${inputs.energia.value}')
GROUP BY marca
ORDER BY vehiculos DESC
```

<Grid cols=2>
<DataTable data={modelos} rows=20 search=true title="Modelos">
    <Column id=puesto title="#" />
    <Column id=marca title="Marca" />
    <Column id=modelo title="Modelo" />
    <Column id=vehiculos title="En circulación" fmt=num0 contentType=bar barColor="#99f6e4" />
</DataTable>
<DataTable data={marcas_parque} rows=20 search=true title="Marcas">
    <Column id=puesto title="#" />
    <Column id=marca title="Marca" />
    <Column id=vehiculos title="En circulación" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota title="Cota" fmt=pct1 />
</DataTable>
</Grid>

<p class="text-xs text-gray-500">En moitos vehículos antigos a DGT non ten o modelo (só a marca): contan na clasificación de marcas pero non na de modelos. Os modelos con menos de 100 unidades non se mostran.</p>

## Por provincia

```sql provincias
SELECT
    cod_prov,
    provincia,
    sum(vehiculos) AS turismos,
    sum(vehiculos) FILTER (WHERE energia IN ('bev', 'phev')) / sum(vehiculos) AS cuota_enchufables,
    sum(vehiculos) FILTER (WHERE distintivo = 'SIN') / sum(vehiculos) AS cuota_sin_etiqueta,
    sum(vehiculos) FILTER (WHERE antiguedad = '20+') / sum(vehiculos) AS cuota_mas_20
FROM mother.movilidad_parque_provincia
WHERE grupo = 'turismo'
GROUP BY ALL
ORDER BY turismos DESC
```

<ButtonGroup name=indicador_prov title="Indicador">
    <ButtonGroupItem valueLabel="% sen etiqueta ambiental" value="cuota_sin_etiqueta" default />
    <ButtonGroupItem valueLabel="% con máis de 20 anos" value="cuota_mas_20" />
    <ButtonGroupItem valueLabel="% enchufables" value="cuota_enchufables" />
</ButtonGroup>

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value={inputs.indicador_prov}
    valueFmt="pct1"
    colorPalette={inputs.indicador_prov === 'cuota_enchufables' ? ['#f0fdfa', '#5eead4', '#0f766e'] : ['#fef3c7', '#f59e0b', '#92400e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: DGT"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'turismos', title: 'Turismos', fmt: 'num0'},
        {id: 'cuota_sin_etiqueta', title: 'Sen etiqueta', fmt: 'pct1'},
        {id: 'cuota_mas_20', title: 'Máis de 20 anos', fmt: 'pct1'},
        {id: 'cuota_enchufables', title: 'Enchufables', fmt: 'pct1'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Provincia" />
    <Column id=turismos title="Turismos" fmt=num0 />
    <Column id=cuota_sin_etiqueta title="Sen etiqueta" fmt=pct1 />
    <Column id=cuota_mas_20 title="Máis de 20 anos" fmt=pct1 />
    <Column id=cuota_enchufables title="Enchufables" fmt=pct1 />
</DataTable>

## Concellos de máis de 10.000 habitantes

```sql municipios
SELECT
    m.cod_mun,
    p.municipio,
    p.poblacion,
    m.turismos,
    1000.0 * m.turismos / p.poblacion AS turismos_por_1000_hab,
    (m.bev + coalesce(m.phev, 0)) / m.turismos AS cuota_enchufables,
    m.sin_distintivo / m.turismos AS cuota_sin_etiqueta,
    m.mas_de_15_anios / m.turismos AS cuota_mas_15
FROM mother.movilidad_parque_municipio m
JOIN (
    SELECT cod_mun, municipio, poblacion
    FROM mother.poblacion_municipios
    WHERE anio = (SELECT max(anio) FROM mother.poblacion_municipios)
) p ON p.cod_mun = m.cod_mun
WHERE p.poblacion >= 10000
ORDER BY m.turismos DESC
```

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Concello" />
    <Column id=turismos title="Turismos" fmt=num0 />
    <Column id=turismos_por_1000_hab title="Por 1.000 hab." fmt=num0 />
    <Column id=cuota_enchufables title="Enchufables" fmt=pct1 />
    <Column id=cuota_sin_etiqueta title="Sen etiqueta" fmt=pct1 />
    <Column id=cuota_mas_15 title="Máis de 15 anos" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">A DGT non publica o concello dos vehículos domiciliados en concellos de menos de 10.000 habitantes. Os concellos con sedes de empresas de renting ou aluguer (Madrid, Alcobendas...) acumulan vehículos que circulan por todo o país, o que dispara os seus turismos por habitante.</p>

---

## Fontes e notas

- **[DGT – Microdatos do parque de vehículos](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/parque-vehiculos-mensual.html)**: un rexistro por vehículo en alta ao final de cada mes (~39 millóns). SpainFacts garda unha foto agregada de cada mes desde agosto de 2026.
- Motor segundo a propulsión e a categoría eléctrica da ficha técnica; etiqueta segundo o distintivo ambiental asignado pola DGT.

<LastRefreshed prefix="Datos actualizados" />
