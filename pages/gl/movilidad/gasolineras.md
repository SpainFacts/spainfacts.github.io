---
title: Gasolineiras e carburantes
description: "Mapa das gasolineiras de España por marca e grupo, cantas hai por habitante en cada provincia, concellos sen ningunha, prezo do gasóleo e da gasolina desde 2007 en euros reais, impostos fronte ao resto da UE e litros de carburante por habitante."
i18n_origen: 3712aa9c0eaa
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const CARBURANTE = { gasoleo_a: 'Gasóleo A', gasolina_95: 'Gasolina 95', glp: 'GLP (autogás)' };
    const TIPO = {
        'Petrolera': 'Petroleiras',
        'Bajo coste': 'Baixo custo',
        'Supermercado': 'Supermercados',
        'Cooperativa': 'Cooperativas',
        'Independiente con marca': 'Independentes',
        'Independiente u otra': 'Independentes'
    };
    const COLOR_TIPO = { 'Petroleiras': '#0f766e', 'Baixo custo': '#f59e0b', 'Supermercados': '#7c3aed', 'Cooperativas': '#65a30d', 'Independentes': '#94a3b8' };
    const PARTE = { 'Sin impuestos': 'Sen impostos', 'Impuestos (IVA e impuesto especial)': 'Impostos (IVE e imposto especial)' };
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

# ⛽ Gasolineiras e carburantes

Onde están as gasolineiras de España e de quen son, canto custa encher o depósito comparado con anos anteriores e co resto de Europa, e canto carburante se gasta por habitante. Prezos e estacións do xeoportal de gasolineiras do Ministerio para a Transición Ecolóxica, que todas as estacións están obrigadas a manter ao día.

<Grid cols=4>
    <KpiCard
        title="Gasolineiras"
        value={totales[0]?.estaciones}
        formattedValue={formatNumber(10000 * totales[0]?.estaciones / totales[0]?.poblacion, 1)}
        unit=" por 10.000 hab."
        period="{formatNumber(totales[0]?.estaciones, 0)} estacións de venda ao público"
        source="MITECO"
    />
    <KpiCard
        title="Gasóleo A"
        value={totales[0]?.gasoleo_a}
        formattedValue="{formatNumber(totales[0]?.gasoleo_a, 3)} €/l"
        period="prezo medio o {totales[0]?.fecha}"
        source="MITECO"
    />
    <KpiCard
        title="Gasolina 95"
        value={totales[0]?.gasolina_95}
        formattedValue="{formatNumber(totales[0]?.gasolina_95, 3)} €/l"
        period="prezo medio o {totales[0]?.fecha}"
        source="MITECO"
    />
    <KpiCard
        title="Veciños sen gasolineira no seu concello"
        value={totales[0]?.poblacion_sin}
        formattedValue="{formatNumber(100 * totales[0]?.poblacion_sin / totales[0]?.poblacion, 1)} %"
        period="{formatNumber(totales[0]?.municipios_sin, 0)} de {formatNumber(totales[0]?.municipios, 0)} concellos non teñen ningunha"
        source="MITECO e INE"
    />
</Grid>

## Mapa de gasolineiras

<ButtonGroup name=tipo_mapa title="Tipo">
    <ButtonGroupItem valueLabel="Todas" value="todas" default />
    <ButtonGroupItem valueLabel="Petroleiras" value="Petrolera" />
    <ButtonGroupItem valueLabel="Baixo custo" value="Bajo coste" />
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
        {id: 'municipio', title: 'Concello'},
        {id: 'precio_gasoleo_a', title: 'Gasóleo A (€/l)', fmt: '#,##0.000'},
        {id: 'precio_gasolina_95', title: 'Gasolina 95 (€/l)', fmt: '#,##0.000'}
    ]}
/>

<p class="text-xs text-gray-500">Cada punto é unha gasolineira de venda ao público; prezo do momento da última carga de datos. Canarias, no recadro de abaixo á esquerda.</p>

## Quen ten as gasolineiras

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
    title="Os 15 grupos con máis gasolineiras"
/>

Unha de cada catro gasolineiras é de Repsol (con Campsa e Petronor). As cadeas de baixo custo, case sempre sen persoal, venden o gasóleo varios céntimos por debaixo da media:

<DataTable data={grupos} rows=15 search=true>
    <Column id=grupo title="Grupo" />
    <Column id=estaciones title="Gasolineiras" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_pct title="% da rede" fmt=num1 />
    <Column id=precio_gasoleo_a title="Gasóleo A (€/l)" fmt="#,##0.000" />
    <Column id=dif_gasoleo_a title="Fronte á media (€/l)" fmt="+#,##0.000;-#,##0.000" contentType=delta downIsGood=true />
    <Column id=precio_gasolina_95 title="Gasolina 95 (€/l)" fmt="#,##0.000" />
    <Column id=dif_gasolina_95 title="Fronte á media (€/l)" fmt="+#,##0.000;-#,##0.000" contentType=delta downIsGood=true />
</DataTable>

<p class="text-xs text-gray-500">Grupo segundo o rótulo da estación: Campsa e Petronor son de Repsol; as Shell de España explótaas DISA con licenza da marca; Cepsa chámase Moeve desde 2024. Media simple das estacións, sen ponderar polos litros vendidos (o Ministerio non os publica). Só grupos con 20 gasolineiras ou máis.</p>

## Por provincia

```sql provincias
SELECT * FROM mother.movilidad_gasolineras_provincia ORDER BY estaciones_por_10k_hab DESC
```

<ButtonGroup name=indicador_prov title="Amosar">
    <ButtonGroupItem valueLabel="Gasolineiras por habitante" value="estaciones_por_10k_hab" default />
    <ButtonGroupItem valueLabel="Veciños sen gasolineira" value="poblacion_sin_gasolinera_pct" />
    <ButtonGroupItem valueLabel="Prezo do gasóleo" value="precio_gasoleo_a" />
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
        {id: 'estaciones_por_10k_hab', title: 'Gasolineiras por 10.000 hab.', fmt: 'num1'},
        {id: 'poblacion_sin_gasolinera_pct', title: '% de veciños sen gasolineira no seu concello', fmt: 'num1'},
        {id: 'precio_gasoleo_a', title: 'Gasóleo A (€/l)', fmt: '#,##0.000'},
        {id: 'litros_automocion_hab', title: 'Litros de carburante por habitante e ano', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">As provincias despoboadas teñen máis gasolineiras por habitante, pero tamén máis veciños que viven nun concello sen ningunha. O consumo por habitante de cada provincia inclúe os camións e quen reposta de paso, por iso é maior nas provincias de tránsito.</p>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Provincia" />
    <Column id=estaciones title="Gasolineiras" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=estaciones_por_10k_hab title="Por 10.000 hab." fmt=num1 />
    <Column id=municipios_sin_gasolinera title="Concellos sen gasolineira" fmt=num0 />
    <Column id=poblacion_sin_gasolinera_pct title="% de veciños sen gasolineira" fmt=num1 />
    <Column id=bajo_coste_pct title="% de baixo custo" fmt=num1 />
    <Column id=grupo_principal title="Grupo con máis" />
    <Column id=grupo_principal_pct title="% do grupo con máis" fmt=num0 />
    <Column id=precio_gasoleo_a title="Gasóleo A (€/l)" fmt="#,##0.000" />
    <Column id=precio_gasolina_95 title="Gasolina 95 (€/l)" fmt="#,##0.000" />
</DataTable>

## Prezo desde 2007

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
    yAxisTitle="€ por litro, en euros de {precios[0]?.anio_base ?? 'hoxe'}"
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#f59e0b', '#7c3aed']}
    legend=true
/>

<p class="text-xs text-gray-500">Prezo medio de venda ao público en euros constantes (descontada a inflación co IPC), media das gasolineiras con prezo os días 1, 8, 15 e 22 de cada mes. Os picos de 2008, 2012 e 2022 seguen o prezo do petróleo; en 2022 o Goberno descontou 20 céntimos por litro na caixa, que non aparecen no prezo publicado.</p>

<LineChart
    data={etiquetar(precios, 'carburante', (d) => CARBURANTE[d.producto] ?? d.producto)}
    x=fecha
    y=precio_litro
    series=carburante
    yFmt="#,##0.00"
    yAxisTitle="€ por litro (euros de cada ano)"
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#f59e0b', '#7c3aed']}
    legend=true
    title="En euros de cada momento"
/>

## Fronte ao resto de Europa

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
    title="Gasóleo de automoción: prezo por litro en {ue_ultimo[0]?.mes_texto}"
/>

<p class="text-xs text-gray-500">O gasóleo español está entre os máis baratos da UE sobre todo porque paga menos impostos: en {ue_ultimo[0]?.mes_texto} os impostos eran o {formatNumber(ue_ultimo.find((d) => d.cod_pais === 'ES')?.impuestos_pct, 0)} % do prezo en España e o {formatNumber(ue_ultimo.find((d) => d.cod_pais === 'EU27_2020')?.impuestos_pct, 0)} % de media na UE. Fonte: Weekly Oil Bulletin da Comisión Europea.</p>

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
    title="Gasóleo de automoción desde 2005, descontada a inflación de cada país"
/>

## Canto carburante gastamos

<KpiCard
    title="Gasolina e gasóleo de automoción por habitante"
    value={consumo_ultimo[0]?.litros_automocion_hab}
    formattedValue="{formatNumber(consumo_ultimo[0]?.litros_automocion_hab, 0)} litros ao ano"
    period="en {consumo_ultimo[0]?.anio}; o máximo foi de {formatNumber(consumo_ultimo[0]?.maximo, 0)} litros en {consumo_ultimo[0]?.anio_maximo}"
    source="CORES"
/>

<BarChart
    data={consumo_pais}
    x=anio
    y=litros_automocion_hab
    yFmt=num0
    fillColor="#0f766e"
    title="Litros de gasolina e gasóleo A por habitante e ano"
/>

<p class="text-xs text-gray-500">Vendas de gasolinas e gasóleo de automoción (inclúe camións, autobuses e furgonetas), pasadas de toneladas a litros coa densidade media de cada carburante. O consumo por habitante tocou teito en 2007 e caeu un 26 % ata 2013 coa crise; en 2020 afundiuse polos confinamentos. O gasóleo pasou de ser o 56 % do carburante de automoción en 1997 a preto do 80 %, e agora baixa.</p>

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
    title="Litros por habitante en {consumo_ccaa[0]?.anio}, por comunidade"
/>

<p class="text-xs text-gray-500">As vendas cóntanse onde se reposta, non onde vive o condutor: Navarra, Castela e León e o País Vasco están arriba porque por elas pasan as grandes rutas de camións, e nas provincias de fronteira (Girona, Gipuzkoa, Navarra) repostan moitos condutores franceses, porque en España o carburante é máis barato. Madrid, Ceuta e Melilla son as que menos venden por habitante.</p>

---

## Fontes e notas

- **[Xeoportal de gasolineiras do Ministerio para a Transición Ecolóxica](https://geoportalgasolineras.es/)**, a través do seu [servizo REST de prezos de carburantes](https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/): todas as estacións de servizo están obrigadas a comunicar os seus prezos (Orde ITC/2308/2007). Só estacións de venda ao público; as de venda restrinxida (cooperativas, frotas) non entran. O histórico comeza en xaneiro de 2007.
- Concello de cada gasolineira asignado polas súas coordenadas; poboación do padrón do INE.
- **[CORES, consumos de produtos petrolíferos por provincia](https://www.cores.es/es/estadisticas)**, mensuais desde 1997, en toneladas; pasadas a litros con 0,745 kg/l para a gasolina e 0,835 kg/l para o gasóleo.
- **[Comisión Europea, Weekly Oil Bulletin](https://energy.ec.europa.eu/data-and-analysis/weekly-oil-bulletin_en)**: prezos semanais con e sen impostos de cada país da UE desde 2005; euros constantes co IPCH de cada país (Eurostat).
- Euros constantes de España co IPC do INE.

<LastRefreshed prefix="Datos actualizados" />
