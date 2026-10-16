---
title: Gasolineras y carburantes
description: "Mapa de las gasolineras de España por marca y grupo, cuántas hay por habitante en cada provincia, municipios sin ninguna, precio del gasóleo y la gasolina desde 2007 en euros reales, impuestos frente al resto de la UE y litros de carburante por habitante."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const CARBURANTE = { gasoleo_a: 'Gasóleo A', gasolina_95: 'Gasolina 95', glp: 'GLP (autogás)' };
    const TIPO = {
        'Petrolera': 'Petroleras',
        'Bajo coste': 'Bajo coste',
        'Supermercado': 'Supermercados',
        'Cooperativa': 'Cooperativas',
        'Independiente con marca': 'Independientes',
        'Independiente u otra': 'Independientes'
    };
    const COLOR_TIPO = { 'Petroleras': '#0f766e', 'Bajo coste': '#f59e0b', 'Supermercados': '#7c3aed', 'Cooperativas': '#65a30d', 'Independientes': '#94a3b8' };
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

# ⛽ Gasolineras y carburantes

Dónde están las gasolineras de España y de quién son, cuánto cuesta llenar el depósito comparado con años anteriores y con el resto de Europa, y cuánto carburante se gasta por habitante. Precios y estaciones del geoportal de gasolineras del Ministerio para la Transición Ecológica, que todas las estaciones están obligadas a mantener al día.

<Grid cols=4>
    <KpiCard
        title="Gasolineras"
        value={totales[0]?.estaciones}
        formattedValue={formatNumber(10000 * totales[0]?.estaciones / totales[0]?.poblacion, 1)}
        unit=" por 10.000 hab."
        period="{formatNumber(totales[0]?.estaciones, 0)} estaciones de venta al público"
        source="MITECO"
    />
    <KpiCard
        title="Gasóleo A"
        value={totales[0]?.gasoleo_a}
        formattedValue="{formatNumber(totales[0]?.gasoleo_a, 3)} €/l"
        period="precio medio el {totales[0]?.fecha}"
        source="MITECO"
    />
    <KpiCard
        title="Gasolina 95"
        value={totales[0]?.gasolina_95}
        formattedValue="{formatNumber(totales[0]?.gasolina_95, 3)} €/l"
        period="precio medio el {totales[0]?.fecha}"
        source="MITECO"
    />
    <KpiCard
        title="Vecinos sin gasolinera en su municipio"
        value={totales[0]?.poblacion_sin}
        formattedValue="{formatNumber(100 * totales[0]?.poblacion_sin / totales[0]?.poblacion, 1)} %"
        period="{formatNumber(totales[0]?.municipios_sin, 0)} de {formatNumber(totales[0]?.municipios, 0)} municipios no tienen ninguna"
        source="MITECO e INE"
    />
</Grid>

## Mapa de gasolineras

<ButtonGroup name=tipo_mapa title="Tipo">
    <ButtonGroupItem valueLabel="Todas" value="todas" default />
    <ButtonGroupItem valueLabel="Petroleras" value="Petrolera" />
    <ButtonGroupItem valueLabel="Bajo coste" value="Bajo coste" />
    <ButtonGroupItem valueLabel="Supermercados" value="Supermercado" />
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
        {id: 'grupo', title: 'Grupo'},
        {id: 'municipio', title: 'Municipio'},
        {id: 'precio_gasoleo_a', title: 'Gasóleo A (€/l)', fmt: '#,##0.000'},
        {id: 'precio_gasolina_95', title: 'Gasolina 95 (€/l)', fmt: '#,##0.000'}
    ]}
/>

<p class="text-xs text-gray-500">Cada punto es una gasolinera de venta al público; precio del momento de la última carga de datos. Canarias, en el recuadro de abajo a la izquierda.</p>

## Quién tiene las gasolineras

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
    title="Los 15 grupos con más gasolineras"
/>

Una de cada cuatro gasolineras es de Repsol (con Campsa y Petronor). Las cadenas de bajo coste, casi siempre sin personal, venden el gasóleo varios céntimos por debajo de la media:

<DataTable data={grupos} rows=15 search=true>
    <Column id=grupo title="Grupo" />
    <Column id=estaciones title="Gasolineras" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_pct title="% de la red" fmt=num1 />
    <Column id=precio_gasoleo_a title="Gasóleo A (€/l)" fmt="#,##0.000" />
    <Column id=dif_gasoleo_a title="Frente a la media (€/l)" fmt="+#,##0.000;-#,##0.000" contentType=delta downIsGood=true />
    <Column id=precio_gasolina_95 title="Gasolina 95 (€/l)" fmt="#,##0.000" />
    <Column id=dif_gasolina_95 title="Frente a la media (€/l)" fmt="+#,##0.000;-#,##0.000" contentType=delta downIsGood=true />
</DataTable>

<p class="text-xs text-gray-500">Grupo por el rótulo de la estación: Campsa y Petronor son de Repsol; las Shell de España las explota DISA con licencia de la marca; Cepsa se llama Moeve desde 2024. Media simple de las estaciones, sin pesar por litros vendidos (el Ministerio no los publica). Solo grupos con 20 gasolineras o más.</p>

## Por provincia

```sql provincias
SELECT * FROM mother.movilidad_gasolineras_provincia ORDER BY estaciones_por_10k_hab DESC
```

<ButtonGroup name=indicador_prov title="Mostrar">
    <ButtonGroupItem valueLabel="Gasolineras por habitante" value="estaciones_por_10k_hab" default />
    <ButtonGroupItem valueLabel="Vecinos sin gasolinera" value="poblacion_sin_gasolinera_pct" />
    <ButtonGroupItem valueLabel="Precio del gasóleo" value="precio_gasoleo_a" />
    <ButtonGroupItem valueLabel="Litros por habitante" value="litros_automocion_hab" />
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
        {id: 'estaciones_por_10k_hab', title: 'Gasolineras por 10.000 hab.', fmt: 'num1'},
        {id: 'poblacion_sin_gasolinera_pct', title: '% de vecinos sin gasolinera en su municipio', fmt: 'num1'},
        {id: 'precio_gasoleo_a', title: 'Gasóleo A (€/l)', fmt: '#,##0.000'},
        {id: 'litros_automocion_hab', title: 'Litros de carburante por habitante y año', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Las provincias despobladas tienen más gasolineras por habitante, pero también más vecinos que viven en un municipio sin ninguna. El consumo por habitante de cada provincia incluye a los camiones y a quienes repostan de paso, por eso es mayor en las provincias de tránsito.</p>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Provincia" />
    <Column id=estaciones title="Gasolineras" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=estaciones_por_10k_hab title="Por 10.000 hab." fmt=num1 />
    <Column id=municipios_sin_gasolinera title="Municipios sin gasolinera" fmt=num0 />
    <Column id=poblacion_sin_gasolinera_pct title="% de vecinos sin gasolinera" fmt=num1 />
    <Column id=bajo_coste_pct title="% de bajo coste" fmt=num1 />
    <Column id=grupo_principal title="Grupo con más" />
    <Column id=grupo_principal_pct title="% del grupo con más" fmt=num0 />
    <Column id=precio_gasoleo_a title="Gasóleo A (€/l)" fmt="#,##0.000" />
    <Column id=precio_gasolina_95 title="Gasolina 95 (€/l)" fmt="#,##0.000" />
</DataTable>

## Precio desde 2007

```sql provincias_lista
SELECT DISTINCT cod, nombre, CASE WHEN cod = '00' THEN 0 ELSE 1 END AS orden
FROM mother.movilidad_carburantes_precios
ORDER BY orden, nombre
```

<Dropdown name=territorio_precio title="Territorio" data={provincias_lista} value=cod label=nombre order=orden defaultValue="00" />

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
    yAxisTitle="€ por litro, en euros de {precios[0]?.anio_base ?? 'hoy'}"
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#f59e0b', '#7c3aed']}
    legend=true
/>

<p class="text-xs text-gray-500">Precio medio de venta al público en euros constantes (descontada la inflación con el IPC), media de las gasolineras con precio los días 1, 8, 15 y 22 de cada mes. Los picos de 2008, 2012 y 2022 siguen al precio del petróleo; en 2022 el Gobierno descontó 20 céntimos por litro en caja, que no aparecen en el precio publicado.</p>

<LineChart
    data={etiquetar(precios, 'carburante', (d) => CARBURANTE[d.producto] ?? d.producto)}
    x=fecha
    y=precio_litro
    series=carburante
    yFmt="#,##0.00"
    yAxisTitle="€ por litro (euros de cada año)"
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#f59e0b', '#7c3aed']}
    legend=true
    title="En euros de cada momento"
/>

## Frente al resto de Europa

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
    data={ue_barras}
    x=pais
    y=euros
    series=parte
    swapXY=true
    sort=false
    yFmt="#,##0.00"
    colorPalette={['#0f766e', '#fca5a5']}
    title="Gasóleo de automoción: precio por litro en {ue_ultimo[0]?.mes_texto}"
/>

<p class="text-xs text-gray-500">El gasóleo español está entre los más baratos de la UE sobre todo porque paga menos impuestos: en {ue_ultimo[0]?.mes_texto} los impuestos eran el {formatNumber(ue_ultimo.find((d) => d.cod_pais === 'ES')?.impuestos_pct, 0)} % del precio en España y el {formatNumber(ue_ultimo.find((d) => d.cod_pais === 'EU27_2020')?.impuestos_pct, 0)} % de media en la UE. Fuente: Weekly Oil Bulletin de la Comisión Europea.</p>

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
    yAxisTitle="€ por litro, euros constantes de cada país"
    xFmt="mmm yyyy"
    legend=true
    title="Gasóleo de automoción desde 2005, descontada la inflación de cada país"
/>

## Cuánto carburante gastamos

<KpiCard
    title="Gasolina y gasóleo de automoción por habitante"
    value={consumo_ultimo[0]?.litros_automocion_hab}
    formattedValue="{formatNumber(consumo_ultimo[0]?.litros_automocion_hab, 0)} litros al año"
    period="en {consumo_ultimo[0]?.anio}; el máximo fue {formatNumber(consumo_ultimo[0]?.maximo, 0)} litros en {consumo_ultimo[0]?.anio_maximo}"
    source="CORES"
/>

<BarChart
    data={consumo_pais}
    x=anio
    y=litros_automocion_hab
    yFmt=num0
    fillColor="#0f766e"
    title="Litros de gasolina y gasóleo A por habitante y año"
/>

<p class="text-xs text-gray-500">Ventas de gasolinas y gasóleo de automoción (incluye camiones, autobuses y furgonetas), pasadas de toneladas a litros con la densidad media de cada carburante. El consumo por habitante tocó techo en 2007 y cayó un 26 % hasta 2013 con la crisis; en 2020 se hundió por los confinamientos. El gasóleo pasó de ser el 56 % del carburante de automoción en 1997 a cerca del 80 %, y ahora baja.</p>

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
    title="Litros por habitante en {consumo_ccaa[0]?.anio}, por comunidad"
/>

<p class="text-xs text-gray-500">Las ventas cuentan donde se reposta, no donde vive el conductor: Navarra, Castilla y León y el País Vasco están arriba porque por ellas pasan las grandes rutas de camiones, y en las provincias de frontera (Girona, Gipuzkoa, Navarra) repostan muchos conductores franceses, porque en España el carburante es más barato. Madrid, Ceuta y Melilla son las que menos venden por habitante.</p>

---

## Fuentes y notas

- **[Geoportal de gasolineras del Ministerio para la Transición Ecológica](https://geoportalgasolineras.es/)**, a través de su [servicio REST de precios de carburantes](https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/): todas las estaciones de servicio están obligadas a comunicar sus precios (Orden ITC/2308/2007). Solo estaciones de venta al público; las de venta restringida (cooperativas, flotas) no entran. El histórico empieza en enero de 2007.
- Municipio de cada gasolinera asignado por sus coordenadas; población del padrón del INE.
- **[CORES, consumos de productos petrolíferos por provincia](https://www.cores.es/es/estadisticas)**, mensuales desde 1997, en toneladas; pasadas a litros con 0,745 kg/l para la gasolina y 0,835 kg/l para el gasóleo.
- **[Comisión Europea, Weekly Oil Bulletin](https://energy.ec.europa.eu/data-and-analysis/weekly-oil-bulletin_en)**: precios semanales con y sin impuestos de cada país de la UE desde 2005; euros constantes con el IPCA de cada país (Eurostat).
- Euros constantes de España con el IPC del INE.

<LastRefreshed prefix="Datos actualizados" />
