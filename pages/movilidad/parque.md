---
title: Parque de vehículos
description: "Los vehículos que circulan en España: turismos por tipo de motor, etiqueta ambiental de la DGT y antigüedad, modelos más comunes y comparación por provincia y municipio."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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

# 🅿️ El parque de vehículos

Los vehículos que están dados de alta en la Dirección General de Tráfico, es decir, los que pueden circular hoy por España: qué motor llevan, qué etiqueta ambiental tienen y cuántos años acumulan.

<Grid cols=3>
    <KpiCard
        title="Turismos en circulación"
        value={resumen[0]?.turismos}
        formattedValue="{formatNumber(1000 * resumen[0]?.turismos / resumen[0]?.poblacion, 0)} por 1.000 hab."
        period="{formatCompact(resumen[0]?.turismos, 1)} turismos y {formatCompact(resumen[0]?.vehiculos, 1)} vehículos de todo tipo · {resumen[0]?.mes_texto}"
        source="DGT"
    />
    <KpiCard
        title="Turismos enchufables"
        value={resumen[0]?.enchufables}
        formattedValue={formatNumber(resumen[0]?.enchufables, 0)}
        period="{formatNumber(resumen[0]?.enchufables / resumen[0]?.turismos / 0.01, 1)} % del total · {formatNumber(resumen[0]?.bev, 0)} eléctricos puros"
        source="DGT"
    />
    <KpiCard
        title="Turismos sin etiqueta ambiental"
        value={resumen[0]?.sin_distintivo}
        formattedValue={formatCompact(resumen[0]?.sin_distintivo, 1)}
        period="{formatNumber(resumen[0]?.sin_distintivo / resumen[0]?.turismos / 0.01, 1)} % · gasolina anterior a 2000 y diésel anterior a 2006"
        source="DGT"
    />
</Grid>

<ButtonGroup name=grupo title="Vehículo">
    <ButtonGroupItem valueLabel="Turismos" value="turismo" default />
    <ButtonGroupItem valueLabel="Motos" value="motocicleta" />
    <ButtonGroupItem valueLabel="Furgonetas" value="furgoneta" />
    <ButtonGroupItem valueLabel="Camiones" value="camion" />
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
    <BarChart data={por_antiguedad} x=antiguedad y=vehiculos sort=false swapXY=true yFmt=num0 fillColor="#78716c" title="Por antigüedad" />
</Grid>

<p class="text-xs text-gray-500">Antigüedad desde la fecha de matriculación en España (en los usados importados, desde que se matricularon aquí). La etiqueta ambiental es la que la DGT asigna a cada vehículo según su motor y su norma Euro.</p>

## Modelos más comunes

<Dropdown name=energia title="Motor" data={energias} value=energia label=energia_etiqueta order=energia_orden>
    <DropdownOption value="todas" valueLabel="Todos los motores" />
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
    <Column id=cuota title="Cuota" fmt=pct1 />
</DataTable>
</Grid>

<p class="text-xs text-gray-500">En muchos vehículos antiguos la DGT no tiene el modelo (solo la marca): cuentan en el ranking de marcas pero no en el de modelos. Los modelos con menos de 100 unidades no se muestran.</p>

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
    <ButtonGroupItem valueLabel="% sin etiqueta ambiental" value="cuota_sin_etiqueta" default />
    <ButtonGroupItem valueLabel="% con más de 20 años" value="cuota_mas_20" />
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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: DGT"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'turismos', title: 'Turismos', fmt: 'num0'},
        {id: 'cuota_sin_etiqueta', title: 'Sin etiqueta', fmt: 'pct1'},
        {id: 'cuota_mas_20', title: 'Más de 20 años', fmt: 'pct1'},
        {id: 'cuota_enchufables', title: 'Enchufables', fmt: 'pct1'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Provincia" />
    <Column id=turismos title="Turismos" fmt=num0 />
    <Column id=cuota_sin_etiqueta title="Sin etiqueta" fmt=pct1 />
    <Column id=cuota_mas_20 title="Más de 20 años" fmt=pct1 />
    <Column id=cuota_enchufables title="Enchufables" fmt=pct1 />
</DataTable>

## Municipios de más de 10.000 habitantes

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
    <Column id=municipio title="Municipio" />
    <Column id=turismos title="Turismos" fmt=num0 />
    <Column id=turismos_por_1000_hab title="Por 1.000 hab." fmt=num0 />
    <Column id=cuota_enchufables title="Enchufables" fmt=pct1 />
    <Column id=cuota_sin_etiqueta title="Sin etiqueta" fmt=pct1 />
    <Column id=cuota_mas_15 title="Más de 15 años" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">La DGT no publica el municipio de los vehículos domiciliados en municipios de menos de 10.000 habitantes. Los municipios con sedes de empresas de renting o alquiler (Madrid, Alcobendas...) acumulan vehículos que circulan por todo el país, lo que dispara sus turismos por habitante.</p>

---

## Fuentes y notas

- **[DGT – Microdatos del parque de vehículos](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/parque-vehiculos-mensual.html)**: un registro por vehículo en alta al final de cada mes (~39 millones). SpainFacts guarda una foto agregada de cada mes desde agosto de 2026.
- Motor según la propulsión y la categoría eléctrica de la ficha técnica; etiqueta según el distintivo ambiental asignado por la DGT.

<LastRefreshed prefix="Datos actualizados" />
