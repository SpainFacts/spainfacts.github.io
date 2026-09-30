---
title: Ibilgailu-parkea
description: "Espainian zirkulatzen duten ibilgailuak: turismoak motor motaren, DGTren ingurumen-etiketaren eta antzinatasunaren arabera, modelo ohikoenak eta probintzien eta udalerrien arteko konparazioa."
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

# 🅿️ Ibilgailu-parkea

Trafiko Zuzendaritza Nagusian alta emanda dauden ibilgailuak, hau da, gaur egun Espainian zirkula dezaketenak: zer motor duten, zer ingurumen-etiketa duten eta zenbat urte dituzten.

```sql parque_mensual
SELECT mes, turismos_1000, pct_enchufables, pct_bev, pct_sin_distintivo
FROM mother.movilidad_parque_resumen
ORDER BY mes
```

<Grid cols=3>
    <KpiCard
        title="Zirkulazioan dauden turismoak"
        value={resumen[0]?.turismos}
        formattedValue="{formatNumber(1000 * resumen[0]?.turismos / resumen[0]?.poblacion, 0)} 1.000 biztanleko"
        period="{formatCompact(resumen[0]?.turismos, 1)} turismo eta mota guztietako {formatCompact(resumen[0]?.vehiculos, 1)} ibilgailu · {resumen[0]?.mes_texto}"
        source="DGT"
        sparklineData={parque_mensual.map(d => d.turismos_1000)}
    />
    <KpiCard
        title="Turismo entxufagarriak"
        value={parque_mensual.slice(-1)[0]?.pct_enchufables}
        formattedValue="{formatNumber(parque_mensual.slice(-1)[0]?.pct_enchufables, 1)} %"
        period="turismoen artean · {formatNumber(resumen[0]?.enchufables, 0)} entxufagarri, {formatNumber(resumen[0]?.bev, 0)} elektriko huts"
        source="DGT"
        sparklineData={parque_mensual.map(d => d.pct_enchufables)}
    />
    <KpiCard
        title="Ingurumen-etiketarik gabeko turismoak"
        value={parque_mensual.slice(-1)[0]?.pct_sin_distintivo}
        formattedValue="{formatNumber(parque_mensual.slice(-1)[0]?.pct_sin_distintivo, 1)} %"
        period="turismoen artean · {formatCompact(resumen[0]?.sin_distintivo, 1)} auto · 2000 aurreko gasolinazkoak eta 2006 aurreko dieselak"
        direction="positive-down"
        source="DGT"
        sparklineData={parque_mensual.map(d => d.pct_sin_distintivo)}
    />
</Grid>

<p class="text-xs text-gray-500">Mini-grafikoak 2025eko martxoan hasten dira: DGTk azken hilabeteetako parke-fitxategiak baino ez ditu gordetzen, eta seriea hazi egiten da hileko argitalpen bakoitzarekin.</p>

<ButtonGroup name=grupo title="Ibilgailua">
    <ButtonGroupItem valueLabel="Turismoak" value="turismo" default />
    <ButtonGroupItem valueLabel="Motoak" value="motocicleta" />
    <ButtonGroupItem valueLabel="Furgonetak" value="furgoneta" />
    <ButtonGroupItem valueLabel="Kamioiak" value="camion" />
    <ButtonGroupItem valueLabel="Autobusak" value="autobus" />
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
    <BarChart data={por_energia} x=motor y=vehiculos sort=false swapXY=true yFmt=num0 fillColor="#0f766e" title="Motor motaren arabera" />
    <BarChart data={por_distintivo} x=etiqueta y=vehiculos sort=false swapXY=true yFmt=num0 fillColor="#14b8a6" title="Ingurumen-etiketaren arabera" />
    <BarChart data={por_antiguedad} x=antiguedad y=vehiculos sort=false swapXY=true yFmt=num0 fillColor="#78716c" title="Antzinatasunaren arabera" />
</Grid>

<p class="text-xs text-gray-500">Antzinatasuna Espainiako matrikulazio-datatik kontatzen da (inportatutako erabilitakoetan, hemen matrikulatu zirenetik). Ingurumen-etiketa DGTk ibilgailu bakoitzari bere motorraren eta Euro arauaren arabera esleitzen diona da.</p>

## Modelo ohikoenak

<Dropdown name=energia title="Motorra" data={energias} value=energia label=energia_etiqueta order=energia_orden>
    <DropdownOption value="todas" valueLabel="Motor guztiak" />
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
<DataTable data={modelos} rows=20 search=true title="Modeloak">
    <Column id=puesto title="#" />
    <Column id=marca title="Marka" />
    <Column id=modelo title="Modeloa" />
    <Column id=vehiculos title="Zirkulazioan" fmt=num0 contentType=bar barColor="#99f6e4" />
</DataTable>
<DataTable data={marcas_parque} rows=20 search=true title="Markak">
    <Column id=puesto title="#" />
    <Column id=marca title="Marka" />
    <Column id=vehiculos title="Zirkulazioan" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota title="Kuota" fmt=pct1 />
</DataTable>
</Grid>

<p class="text-xs text-gray-500">Ibilgailu zahar askoren kasuan DGTk ez du modeloa (marka soilik): marken sailkapenean zenbatzen dira, baina ez modeloenean. 100 unitate baino gutxiago dituzten modeloak ez dira erakusten.</p>

## Probintziaka

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

<ButtonGroup name=indicador_prov title="Adierazlea">
    <ButtonGroupItem valueLabel="Ingurumen-etiketarik gabeko %" value="cuota_sin_etiqueta" default />
    <ButtonGroupItem valueLabel="20 urte baino gehiagoko %" value="cuota_mas_20" />
    <ButtonGroupItem valueLabel="Entxufagarrien %" value="cuota_enchufables" />
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
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: DGT"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'turismos', title: 'Turismoak', fmt: 'num0'},
        {id: 'cuota_sin_etiqueta', title: 'Etiketarik gabe', fmt: 'pct1'},
        {id: 'cuota_mas_20', title: '20 urte baino gehiago', fmt: 'pct1'},
        {id: 'cuota_enchufables', title: 'Entxufagarriak', fmt: 'pct1'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Probintzia" />
    <Column id=turismos title="Turismoak" fmt=num0 />
    <Column id=cuota_sin_etiqueta title="Etiketarik gabe" fmt=pct1 />
    <Column id=cuota_mas_20 title="20 urte baino gehiago" fmt=pct1 />
    <Column id=cuota_enchufables title="Entxufagarriak" fmt=pct1 />
</DataTable>

## 10.000 biztanletik gorako udalerriak

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
    <Column id=municipio title="Udalerria" />
    <Column id=turismos title="Turismoak" fmt=num0 />
    <Column id=turismos_por_1000_hab title="1.000 biztanleko" fmt=num0 />
    <Column id=cuota_enchufables title="Entxufagarriak" fmt=pct1 />
    <Column id=cuota_sin_etiqueta title="Etiketarik gabe" fmt=pct1 />
    <Column id=cuota_mas_15 title="15 urte baino gehiago" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">DGTk ez du argitaratzen 10.000 biztanletik beherako udalerrietan helbideratutako ibilgailuen udalerria. Renting edo alokairu enpresen egoitzak dituzten udalerriek (Madril, Alcobendas...) herrialde osoan zirkulatzen duten ibilgailuak metatzen dituzte, eta horrek biztanleko turismo-kopurua izugarri igotzen du.</p>

---

## Iturriak eta oharrak

- **[DGT – Ibilgailu-parkearen mikrodatuak](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/parque-vehiculos-mensual.html)**: erregistro bat hilabete bakoitzaren amaieran alta emanda dagoen ibilgailu bakoitzeko (~39 milioi). SpainFactsek hilabete bakoitzeko argazki agregatu bat gordetzen du 2026ko abuztutik.
- Motorra fitxa teknikoko propultsioaren eta kategoria elektrikoaren arabera; etiketa DGTk esleitutako ingurumen-bereizgarriaren arabera.

<LastRefreshed prefix="Datuak eguneratuta" />
