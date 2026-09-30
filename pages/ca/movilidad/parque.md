---
title: Parc de vehicles
description: "Els vehicles que circulen a Espanya: turismes per tipus de motor, etiqueta ambiental de la DGT i antiguitat, models més comuns i comparació per província i municipi."
i18n_origen: e10a6f5a05a5
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

# 🅿️ El parc de vehicles

Els vehicles que estan donats d'alta a la Direcció General de Trànsit, és a dir, els que poden circular avui per Espanya: quin motor porten, quina etiqueta ambiental tenen i quants anys acumulen.

```sql parque_mensual
SELECT mes, turismos_1000, pct_enchufables, pct_bev, pct_sin_distintivo
FROM mother.movilidad_parque_resumen
ORDER BY mes
```

<Grid cols=3>
    <KpiCard
        title="Turismes en circulació"
        value={resumen[0]?.turismos}
        formattedValue="{formatNumber(1000 * resumen[0]?.turismos / resumen[0]?.poblacion, 0)} per 1.000 hab."
        period="{formatCompact(resumen[0]?.turismos, 1)} turismes i {formatCompact(resumen[0]?.vehiculos, 1)} vehicles de tota mena · {resumen[0]?.mes_texto}"
        source="DGT"
        sparklineData={parque_mensual.map(d => d.turismos_1000)}
    />
    <KpiCard
        title="Turismes endollables"
        value={parque_mensual.slice(-1)[0]?.pct_enchufables}
        formattedValue="{formatNumber(parque_mensual.slice(-1)[0]?.pct_enchufables, 1)} %"
        period="dels turismes · {formatNumber(resumen[0]?.enchufables, 0)} endollables, {formatNumber(resumen[0]?.bev, 0)} elèctrics purs"
        source="DGT"
        sparklineData={parque_mensual.map(d => d.pct_enchufables)}
    />
    <KpiCard
        title="Turismes sense etiqueta ambiental"
        value={parque_mensual.slice(-1)[0]?.pct_sin_distintivo}
        formattedValue="{formatNumber(parque_mensual.slice(-1)[0]?.pct_sin_distintivo, 1)} %"
        period="dels turismes · {formatCompact(resumen[0]?.sin_distintivo, 1)} cotxes · gasolina anterior al 2000 i dièsel anterior al 2006"
        direction="positive-down"
        source="DGT"
        sparklineData={parque_mensual.map(d => d.pct_sin_distintivo)}
    />
</Grid>

<p class="text-xs text-gray-500">Els minigràfics comencen el març del 2025: la DGT només conserva els fitxers de parc dels últims mesos, i la sèrie creix amb cada publicació mensual.</p>

<ButtonGroup name=grupo title="Vehicle">
    <ButtonGroupItem valueLabel="Turismes" value="turismo" default />
    <ButtonGroupItem valueLabel="Motos" value="motocicleta" />
    <ButtonGroupItem valueLabel="Furgonetes" value="furgoneta" />
    <ButtonGroupItem valueLabel="Camions" value="camion" />
    <ButtonGroupItem valueLabel="Autobusos" value="autobus" />
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
    <BarChart data={por_energia} x=motor y=vehiculos sort=false swapXY=true yFmt=num0 fillColor="#0f766e" title="Per tipus de motor" />
    <BarChart data={por_distintivo} x=etiqueta y=vehiculos sort=false swapXY=true yFmt=num0 fillColor="#14b8a6" title="Per etiqueta ambiental" />
    <BarChart data={por_antiguedad} x=antiguedad y=vehiculos sort=false swapXY=true yFmt=num0 fillColor="#78716c" title="Per antiguitat" />
</Grid>

<p class="text-xs text-gray-500">Antiguitat des de la data de matriculació a Espanya (en els usats importats, des que s'hi van matricular). L'etiqueta ambiental és la que la DGT assigna a cada vehicle segons el motor i la norma Euro.</p>

## Models més comuns

<Dropdown name=energia title="Motor" data={energias} value=energia label=energia_etiqueta order=energia_orden>
    <DropdownOption value="todas" valueLabel="Tots els motors" />
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
<DataTable data={modelos} rows=20 search=true title="Models">
    <Column id=puesto title="#" />
    <Column id=marca title="Marca" />
    <Column id=modelo title="Model" />
    <Column id=vehiculos title="En circulació" fmt=num0 contentType=bar barColor="#99f6e4" />
</DataTable>
<DataTable data={marcas_parque} rows=20 search=true title="Marques">
    <Column id=puesto title="#" />
    <Column id=marca title="Marca" />
    <Column id=vehiculos title="En circulació" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota title="Quota" fmt=pct1 />
</DataTable>
</Grid>

<p class="text-xs text-gray-500">En molts vehicles antics la DGT no té el model (només la marca): compten en el rànquing de marques però no en el de models. Els models amb menys de 100 unitats no es mostren.</p>

## Per província

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
    <ButtonGroupItem valueLabel="% sense etiqueta ambiental" value="cuota_sin_etiqueta" default />
    <ButtonGroupItem valueLabel="% amb més de 20 anys" value="cuota_mas_20" />
    <ButtonGroupItem valueLabel="% endollables" value="cuota_enchufables" />
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
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: DGT"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'turismos', title: 'Turismes', fmt: 'num0'},
        {id: 'cuota_sin_etiqueta', title: 'Sense etiqueta', fmt: 'pct1'},
        {id: 'cuota_mas_20', title: 'Més de 20 anys', fmt: 'pct1'},
        {id: 'cuota_enchufables', title: 'Endollables', fmt: 'pct1'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Província" />
    <Column id=turismos title="Turismes" fmt=num0 />
    <Column id=cuota_sin_etiqueta title="Sense etiqueta" fmt=pct1 />
    <Column id=cuota_mas_20 title="Més de 20 anys" fmt=pct1 />
    <Column id=cuota_enchufables title="Endollables" fmt=pct1 />
</DataTable>

## Municipis de més de 10.000 habitants

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
    <Column id=municipio title="Municipi" />
    <Column id=turismos title="Turismes" fmt=num0 />
    <Column id=turismos_por_1000_hab title="Per 1.000 hab." fmt=num0 />
    <Column id=cuota_enchufables title="Endollables" fmt=pct1 />
    <Column id=cuota_sin_etiqueta title="Sense etiqueta" fmt=pct1 />
    <Column id=cuota_mas_15 title="Més de 15 anys" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">La DGT no publica el municipi dels vehicles domiciliats en municipis de menys de 10.000 habitants. Els municipis amb seus d'empreses de rènting o lloguer (Madrid, Alcobendas...) acumulen vehicles que circulen per tot el país, cosa que dispara els seus turismes per habitant.</p>

---

## Fonts i notes

- **[DGT – Microdades del parc de vehicles](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/parque-vehiculos-mensual.html)**: un registre per vehicle d'alta al final de cada mes (~39 milions). SpainFacts desa una foto agregada de cada mes des de l'agost del 2026.
- Motor segons la propulsió i la categoria elèctrica de la fitxa tècnica; etiqueta segons el distintiu ambiental assignat per la DGT.

<LastRefreshed prefix="Dades actualitzades" />
