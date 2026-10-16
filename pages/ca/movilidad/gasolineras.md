---
title: Gasolineres i carburants
description: "Mapa de les gasolineres d'Espanya per marca i grup, quantes n'hi ha per habitant a cada província, municipis sense cap, preu del gasoil i la gasolina des del 2007 en euros reals, impostos davant la resta de la UE i litres de carburant per habitant."
i18n_origen: 3712aa9c0eaa
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const CARBURANTE = { gasoleo_a: 'Gasoil A', gasolina_95: 'Gasolina 95', glp: 'GLP (autogas)' };
    const TIPO = {
        'Petrolera': 'Petroleres',
        'Bajo coste': 'Baix cost',
        'Supermercado': 'Supermercats',
        'Cooperativa': 'Cooperatives',
        'Independiente con marca': 'Independents',
        'Independiente u otra': 'Independents'
    };
    const COLOR_TIPO = { 'Petroleres': '#0f766e', 'Baix cost': '#f59e0b', 'Supermercats': '#7c3aed', 'Cooperatives': '#65a30d', 'Independents': '#94a3b8' };
    const PARTE = { 'Sin impuestos': 'Sense impostos', 'Impuestos (IVA e impuesto especial)': 'Impostos (IVA i impost especial)' };
    const etiquetar = (filas, columna, f) => Array.from(filas ?? []).map((d) => ({ ...d, [columna]: f(d) }));
</script>

```sql totales
SELECT
    count(*) AS estaciones,
    count(*) FILTER (WHERE tipo = 'Bajo coste') AS bajo_coste,
    avg(precio_gasoleo_a) AS gasoleo_a,
    avg(precio_gasolina_95) AS gasolina_95,
    strftime(max(fecha_precios), '%d/%m/%Y') AS fecha,
    (SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total' ORDER BY anio DESC LIMIT 1) AS poblacion,
    (SELECT sum(poblacion_sin_gasolinera) FROM mother.movilidad_gasolineras_provincia) AS poblacion_sin,
    (SELECT sum(municipios_sin_gasolinera) FROM mother.movilidad_gasolineras_provincia) AS municipios_sin,
    (SELECT sum(municipios) FROM mother.movilidad_gasolineras_provincia) AS municipios
FROM mother.movilidad_gasolineras
```

```sql consumo_pais
SELECT anio, litros_automocion_hab, gasoleo_pct_automocion
FROM mother.movilidad_carburantes_consumo
WHERE nivel = 'pais' AND meses = 12
ORDER BY anio
```

```sql consumo_ultimo
SELECT c.anio, c.litros_automocion_hab, m.litros_automocion_hab AS maximo, m.anio AS anio_maximo
FROM ${consumo_pais} c
CROSS JOIN (SELECT * FROM ${consumo_pais} ORDER BY litros_automocion_hab DESC LIMIT 1) m
ORDER BY c.anio DESC
LIMIT 1
```

# ⛽ Gasolineres i carburants

On són les gasolineres d'Espanya i de qui són, quant costa omplir el dipòsit comparat amb anys anteriors i amb la resta d'Europa, i quant carburant es gasta per habitant. Preus i estacions del geoportal de gasolineres del Ministeri per a la Transició Ecològica, que totes les estacions estan obligades a mantenir al dia.

<Grid cols=4>
    <KpiCard
        title="Gasolineres"
        value={totales[0]?.estaciones}
        formattedValue={formatNumber(10000 * totales[0]?.estaciones / totales[0]?.poblacion, 1)}
        unit=" per 10.000 hab."
        period="{formatNumber(totales[0]?.estaciones, 0)} estacions de venda al públic"
        source="MITECO"
    />
    <KpiCard
        title="Gasoil A"
        value={totales[0]?.gasoleo_a}
        formattedValue="{formatNumber(totales[0]?.gasoleo_a, 3)} €/l"
        period="preu mitjà el {totales[0]?.fecha}"
        source="MITECO"
    />
    <KpiCard
        title="Gasolina 95"
        value={totales[0]?.gasolina_95}
        formattedValue="{formatNumber(totales[0]?.gasolina_95, 3)} €/l"
        period="preu mitjà el {totales[0]?.fecha}"
        source="MITECO"
    />
    <KpiCard
        title="Veïns sense gasolinera al seu municipi"
        value={totales[0]?.poblacion_sin}
        formattedValue="{formatNumber(100 * totales[0]?.poblacion_sin / totales[0]?.poblacion, 1)} %"
        period="{formatNumber(totales[0]?.municipios_sin, 0)} de {formatNumber(totales[0]?.municipios, 0)} municipis no en tenen cap"
        source="MITECO i INE"
    />
</Grid>

## Mapa de gasolineres

<ButtonGroup name=tipo_mapa title="Tipus">
    <ButtonGroupItem valueLabel="Totes" value="todas" default />
    <ButtonGroupItem valueLabel="Petroleres" value="Petrolera" />
    <ButtonGroupItem valueLabel="Baix cost" value="Bajo coste" />
    <ButtonGroupItem valueLabel="Supermercats" value="Supermercado" />
</ButtonGroup>

```sql mapa
-- Primero una estación de cada tipo, en orden fijo, para que los colores de la leyenda no
-- cambien con el filtro; después el resto, con las petroleras debajo para que se vean las demás
SELECT * FROM (
    SELECT
        ideess, rotulo, grupo, tipo, municipio, provincia, latitud, longitud,
        precio_gasoleo_a, precio_gasolina_95,
        CASE tipo WHEN 'Petrolera' THEN 1 WHEN 'Bajo coste' THEN 2 WHEN 'Supermercado' THEN 3 WHEN 'Cooperativa' THEN 4 ELSE 5 END AS orden,
        row_number() OVER (PARTITION BY tipo ORDER BY ideess) = 1 AS primera
    FROM mother.movilidad_gasolineras
    WHERE latitud IS NOT NULL
      AND ('${inputs.tipo_mapa}' = 'todas' OR tipo = '${inputs.tipo_mapa}')
)
ORDER BY primera DESC, CASE WHEN primera THEN orden END, orden
```

<MapaEspana
    data={etiquetar(mapa, 'tipo_texto', (d) => TIPO[d.tipo] ?? d.tipo)}
    lat=latitud
    long=longitud
    value=tipo_texto
    legendType=categorical
    colorPalette={[...new Set(etiquetar(mapa, 'tipo_texto', (d) => TIPO[d.tipo] ?? d.tipo).map((d) => d.tipo_texto))].map((t) => COLOR_TIPO[t] ?? '#94a3b8')}
    maxSize={4}
    opacity={0.75}
    pointName=rotulo
    height={620}
    tooltip={[
        {id: 'rotulo', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'grupo', title: 'Grup'},
        {id: 'municipio', title: 'Municipi'},
        {id: 'precio_gasoleo_a', title: 'Gasoil A (€/l)', fmt: '#,##0.000'},
        {id: 'precio_gasolina_95', title: 'Gasolina 95 (€/l)', fmt: '#,##0.000'}
    ]}
/>

<p class="text-xs text-gray-500">Cada punt és una gasolinera de venda al públic; preu del moment de l'última càrrega de dades. Les Canàries, al requadre de baix a l'esquerra.</p>

## Qui té les gasolineres

```sql grupos
SELECT grupo, tipo, estaciones, cuota_pct, precio_gasoleo_a, precio_gasolina_95, dif_gasoleo_a, dif_gasolina_95
FROM mother.movilidad_gasolineras_grupos
WHERE estaciones >= 20
ORDER BY estaciones DESC
```

```sql por_tipo
SELECT tipo, sum(estaciones) AS estaciones, sum(estaciones) * 1.0 / (SELECT sum(estaciones) FROM mother.movilidad_gasolineras_grupos) AS cuota,
    sum(precio_gasoleo_a * estaciones) / sum(estaciones) AS precio_gasoleo_a
FROM mother.movilidad_gasolineras_grupos
GROUP BY tipo
ORDER BY estaciones DESC
```

<BarChart
    data={etiquetar(grupos.slice(0, 15), 'tipo_texto', (d) => TIPO[d.tipo] ?? d.tipo)}
    x=grupo
    y=estaciones
    series=tipo_texto
    swapXY=true
    sort=false
    yFmt=num0
    colorPalette={['#0f766e', '#f59e0b', '#7c3aed', '#94a3b8', '#65a30d']}
    title="Els 15 grups amb més gasolineres"
/>

Una de cada quatre gasolineres és de Repsol (amb Campsa i Petronor). Les cadenes de baix cost, gairebé sempre sense personal, venen el gasoil uns quants cèntims per sota de la mitjana:

<DataTable data={grupos} rows=15 search=true>
    <Column id=grupo title="Grup" />
    <Column id=estaciones title="Gasolineres" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_pct title="% de la xarxa" fmt=num1 />
    <Column id=precio_gasoleo_a title="Gasoil A (€/l)" fmt="#,##0.000" />
    <Column id=dif_gasoleo_a title="Davant la mitjana (€/l)" fmt="+#,##0.000;-#,##0.000" contentType=delta downIsGood=true />
    <Column id=precio_gasolina_95 title="Gasolina 95 (€/l)" fmt="#,##0.000" />
    <Column id=dif_gasolina_95 title="Davant la mitjana (€/l)" fmt="+#,##0.000;-#,##0.000" contentType=delta downIsGood=true />
</DataTable>

<p class="text-xs text-gray-500">Grup segons el rètol de l'estació: Campsa i Petronor són de Repsol; les Shell d'Espanya les explota DISA amb llicència de la marca; Cepsa es diu Moeve des del 2024. Mitjana simple de les estacions, sense ponderar pels litres venuts (el Ministeri no els publica). Només grups amb 20 gasolineres o més.</p>

## Per província

```sql provincias
SELECT * FROM mother.movilidad_gasolineras_provincia ORDER BY estaciones_por_10k_hab DESC
```

<ButtonGroup name=indicador_prov title="Mostrar">
    <ButtonGroupItem valueLabel="Gasolineres per habitant" value="estaciones_por_10k_hab" default />
    <ButtonGroupItem valueLabel="Veïns sense gasolinera" value="poblacion_sin_gasolinera_pct" />
    <ButtonGroupItem valueLabel="Preu del gasoil" value="precio_gasoleo_a" />
    <ButtonGroupItem valueLabel="Litres per habitant" value="litros_automocion_hab" />
</ButtonGroup>

```sql prov_mapa
SELECT cod_prov, provincia, estaciones, estaciones_por_10k_hab, poblacion_sin_gasolinera_pct, precio_gasoleo_a, litros_automocion_hab,
    ${inputs.indicador_prov} AS valor
FROM ${provincias}
```

<MapaEspana
    data={prov_mapa}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="valor"
    valueFmt={inputs.indicador_prov === 'precio_gasoleo_a' ? '#,##0.000' : inputs.indicador_prov === 'litros_automocion_hab' ? 'num0' : 'num1'}
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={460}
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'estaciones_por_10k_hab', title: 'Gasolineres per 10.000 hab.', fmt: 'num1'},
        {id: 'poblacion_sin_gasolinera_pct', title: '% de veïns sense gasolinera al seu municipi', fmt: 'num1'},
        {id: 'precio_gasoleo_a', title: 'Gasoil A (€/l)', fmt: '#,##0.000'},
        {id: 'litros_automocion_hab', title: 'Litres de carburant per habitant i any', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Les províncies despoblades tenen més gasolineres per habitant, però també més veïns que viuen en un municipi sense cap. El consum per habitant de cada província inclou els camions i els qui posen benzina de pas, i per això és més alt a les províncies de trànsit.</p>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Província" />
    <Column id=estaciones title="Gasolineres" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=estaciones_por_10k_hab title="Per 10.000 hab." fmt=num1 />
    <Column id=municipios_sin_gasolinera title="Municipis sense gasolinera" fmt=num0 />
    <Column id=poblacion_sin_gasolinera_pct title="% de veïns sense gasolinera" fmt=num1 />
    <Column id=bajo_coste_pct title="% de baix cost" fmt=num1 />
    <Column id=grupo_principal title="Grup amb més" />
    <Column id=grupo_principal_pct title="% del grup amb més" fmt=num0 />
    <Column id=precio_gasoleo_a title="Gasoil A (€/l)" fmt="#,##0.000" />
    <Column id=precio_gasolina_95 title="Gasolina 95 (€/l)" fmt="#,##0.000" />
</DataTable>

## Preu des del 2007

```sql provincias_lista
SELECT DISTINCT cod, nombre, CASE WHEN cod = '00' THEN 0 ELSE 1 END AS orden
FROM mother.movilidad_carburantes_precios
ORDER BY orden, nombre
```

<Dropdown name=territorio_precio title="Territori" data={provincias_lista} value=cod label=nombre order=orden defaultValue="00" />

```sql precios
SELECT fecha, producto, precio_litro, precio_litro_real, anio_base
FROM mother.movilidad_carburantes_precios
WHERE cod = '${inputs.territorio_precio.value}'
ORDER BY fecha, producto
```

<LineChart
    data={etiquetar(precios, 'carburante', (d) => CARBURANTE[d.producto] ?? d.producto)}
    x=fecha
    y=precio_litro_real
    series=carburante
    yFmt="#,##0.00"
    yAxisTitle="€ per litre, en euros de {precios[0]?.anio_base ?? 'avui'}"
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#f59e0b', '#7c3aed']}
    legend=true
/>

<p class="text-xs text-gray-500">Preu mitjà de venda al públic en euros constants (descomptada la inflació amb l'IPC), mitjana de les gasolineres amb preu els dies 1, 8, 15 i 22 de cada mes. Els pics del 2008, el 2012 i el 2022 segueixen el preu del petroli; el 2022 el Govern va descomptar 20 cèntims per litre a la caixa, que no apareixen en el preu publicat.</p>

<LineChart
    data={etiquetar(precios, 'carburante', (d) => CARBURANTE[d.producto] ?? d.producto)}
    x=fecha
    y=precio_litro
    series=carburante
    yFmt="#,##0.00"
    yAxisTitle="€ per litre (euros de cada any)"
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#f59e0b', '#7c3aed']}
    legend=true
    title="En euros de cada moment"
/>

## Davant la resta d'Europa

```sql ue_ultimo
SELECT pais, cod_pais, producto, precio_litro, precio_sin_impuestos_litro, impuestos_litro, impuestos_pct, strftime(fecha, '%m/%Y') AS mes_texto
FROM mother.movilidad_carburantes_ue
WHERE fecha = (SELECT max(fecha) FROM mother.movilidad_carburantes_ue WHERE cod_pais = 'ES')
  AND producto = 'gasoleo_a'
ORDER BY precio_litro DESC
```

```sql ue_barras
SELECT pais, 'Sin impuestos' AS parte, precio_sin_impuestos_litro AS euros, precio_litro FROM ${ue_ultimo}
UNION ALL
SELECT pais, 'Impuestos (IVA e impuesto especial)', impuestos_litro, precio_litro FROM ${ue_ultimo}
ORDER BY precio_litro DESC
```

<BarChart
    data={etiquetar(ue_barras, 'parte', (d) => PARTE[d.parte] ?? d.parte)}
    x=pais
    y=euros
    series=parte
    swapXY=true
    sort=false
    yFmt="#,##0.00"
    colorPalette={['#0f766e', '#fca5a5']}
    title="Gasoil d'automoció: preu per litre el {ue_ultimo[0]?.mes_texto}"
/>

<p class="text-xs text-gray-500">El gasoil espanyol és dels més barats de la UE sobretot perquè paga menys impostos: el {ue_ultimo[0]?.mes_texto} els impostos eren el {formatNumber(ue_ultimo.find((d) => d.cod_pais === 'ES')?.impuestos_pct, 0)} % del preu a Espanya i el {formatNumber(ue_ultimo.find((d) => d.cod_pais === 'EU27_2020')?.impuestos_pct, 0)} % de mitjana a la UE. Font: Weekly Oil Bulletin de la Comissió Europea.</p>

```sql ue_serie
SELECT fecha, pais, producto, precio_litro_real
FROM mother.movilidad_carburantes_ue
WHERE cod_pais IN ('ES', 'EU27_2020', 'FR', 'PT', 'DE', 'IT')
  AND producto = 'gasoleo_a'
  AND precio_litro_real IS NOT NULL
ORDER BY fecha, pais
```

<LineChart
    data={ue_serie}
    x=fecha
    y=precio_litro_real
    series=pais
    yFmt="#,##0.00"
    yAxisTitle="€ per litre, euros constants de cada país"
    xFmt="mmm yyyy"
    legend=true
    title="Gasoil d'automoció des del 2005, descomptada la inflació de cada país"
/>

## Quant carburant gastem

<KpiCard
    title="Gasolina i gasoil d'automoció per habitant"
    value={consumo_ultimo[0]?.litros_automocion_hab}
    formattedValue="{formatNumber(consumo_ultimo[0]?.litros_automocion_hab, 0)} litres l'any"
    period="el {consumo_ultimo[0]?.anio}; el màxim va ser de {formatNumber(consumo_ultimo[0]?.maximo, 0)} litres el {consumo_ultimo[0]?.anio_maximo}"
    source="CORES"
/>

<BarChart
    data={consumo_pais}
    x=anio
    y=litros_automocion_hab
    yFmt=num0
    fillColor="#0f766e"
    title="Litres de gasolina i gasoil A per habitant i any"
/>

<p class="text-xs text-gray-500">Vendes de gasolines i gasoil d'automoció (inclou camions, autobusos i furgonetes), passades de tones a litres amb la densitat mitjana de cada carburant. El consum per habitant va tocar sostre el 2007 i va caure un 26 % fins al 2013 amb la crisi; el 2020 es va enfonsar pels confinaments. El gasoil va passar de ser el 56 % del carburant d'automoció el 1997 a prop del 80 %, i ara baixa.</p>

```sql consumo_ccaa
SELECT nombre, anio, litros_automocion_hab
FROM mother.movilidad_carburantes_consumo
WHERE nivel = 'ccaa' AND meses = 12
  AND anio = (SELECT max(anio) FROM mother.movilidad_carburantes_consumo WHERE meses = 12)
ORDER BY litros_automocion_hab DESC
```

<BarChart
    data={consumo_ccaa}
    x=nombre
    y=litros_automocion_hab
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#5eead4"
    title="Litres per habitant el {consumo_ccaa[0]?.anio}, per comunitat"
/>

<p class="text-xs text-gray-500">Les vendes compten on es posa carburant, no on viu el conductor: Navarra, Castella i Lleó i el País Basc són a dalt perquè hi passen les grans rutes de camions, i a les províncies de frontera (Girona, Guipúscoa, Navarra) hi posen carburant molts conductors francesos, perquè a Espanya és més barat. Madrid, Ceuta i Melilla són les que menys venen per habitant.</p>

---

## Fonts i notes

- **[Geoportal de gasolineres del Ministeri per a la Transició Ecològica](https://geoportalgasolineras.es/)**, a través del seu [servei REST de preus de carburants](https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/): totes les estacions de servei estan obligades a comunicar els seus preus (Ordre ITC/2308/2007). Només estacions de venda al públic; les de venda restringida (cooperatives, flotes) no hi entren. L'històric comença el gener del 2007.
- Municipi de cada gasolinera assignat per les seves coordenades; població del padró de l'INE.
- **[CORES, consums de productes petrolífers per província](https://www.cores.es/es/estadisticas)**, mensuals des del 1997, en tones; passades a litres amb 0,745 kg/l per a la gasolina i 0,835 kg/l per al gasoil.
- **[Comissió Europea, Weekly Oil Bulletin](https://energy.ec.europa.eu/data-and-analysis/weekly-oil-bulletin_en)**: preus setmanals amb impostos i sense de cada país de la UE des del 2005; euros constants amb l'IPCH de cada país (Eurostat).
- Euros constants d'Espanya amb l'IPC de l'INE.

<LastRefreshed prefix="Dades actualitzades" />
