---
title: Estradas
description: "Mapa de todas as estradas de España segundo quen as xestiona (Estado, comunidades autónomas, deputacións, cabidos e consells) e o seu tipo (autoestradas de peaxe, autovías, multicarril e convencionais), os coches e camións que pasan cada día por cada tramo da rede do Estado, os km por habitante e por superficie de cada provincia desde 1970 e a comparación con Europa."
i18n_origen: 2b3f03137772
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const TITULAR = {
        estado: 'Estado',
        comunidad: 'Comunidades autónomas',
        diputacion: 'Deputacións, cabidos e consells'
    };
    const TIPO = {
        peaje: 'Autoestradas de peaxe',
        autovia: 'Autoestradas libres e autovías',
        multicarril: 'Estradas multicarril',
        convencional: 'Estradas convencionais'
    };
    const COLOR_TITULAR = { estado: '#dc2626', comunidad: '#2563eb', diputacion: '#a3a3a3' };
    const COLOR_TIPO = { peaje: '#7c3aed', autovia: '#f97316', multicarril: '#0f766e', convencional: '#a3a3a3' };
    // Grosor del trazo en el mapa de la red según el tipo de vía
    const GROSOR = { peaje: 4, autovia: 4, multicarril: 2.5, convencional: 1 };
    // Tramos de vehículos al día para el color del mapa de tráfico
    const TRAMOS = [[2000, 'Menos de 2.000 vehículos ao día', '#fde68a'], [10000, '2.000 a 10.000', '#fbbf24'], [30000, '10.000 a 30.000', '#f97316'], [70000, '30.000 a 70.000', '#dc2626'], [Infinity, 'Máis de 70.000', '#7e22ce']];
    const tramoDe = (n) => TRAMOS.find((t) => n < t[0]);
    const etiquetar = (filas, columna, f) => Array.from(filas ?? []).map((d) => ({ ...d, [columna]: f(d) }));
    const enRed = (filas, vista) => Array.from(filas ?? [])
        .map((d) => ({
            ...d,
            categoria: vista === 'tipo' ? TIPO[d.tipo] : TITULAR[d.titular],
            color: vista === 'tipo' ? COLOR_TIPO[d.tipo] : COLOR_TITULAR[d.titular],
            orden: vista === 'tipo' ? d.tipo_orden : d.titular_orden,
            grosor: GROSOR[d.tipo],
            titular_texto: TITULAR[d.titular],
            tipo_texto: TIPO[d.tipo]
        }))
        .toSorted((a, b) => a.orden - b.orden);
</script>

```sql provincias
SELECT * FROM mother.movilidad_carreteras_provincia
```

```sql espana
-- Totales de España del último año: suma de las provincias
SELECT
    max(anio) AS anio,
    sum(km_total) AS km_total,
    sum(km_estado) AS km_estado,
    sum(km_comunidad) AS km_comunidad,
    sum(km_diputacion) AS km_diputacion,
    sum(km_gran_capacidad) AS km_gran_capacidad,
    sum(km_peaje) AS km_peaje,
    sum(km_peaje_estado) AS km_peaje_estado,
    100000.0 * sum(km_total) / sum(poblacion) AS km_por_100k_hab,
    100000.0 * sum(km_gran_capacidad) / sum(poblacion) AS km_gran_capacidad_por_100k_hab,
    100.0 * sum(km_peaje) / sum(km_gran_capacidad) AS peaje_pct
FROM ${provincias}
```

```sql tramo_max
SELECT carretera, imd, anio FROM mother.movilidad_carreteras_trafico ORDER BY imd DESC LIMIT 1
```

# 🛣️ Estradas

Os {formatNumber(espana[0]?.km_total, 0)} km de estradas interurbanas de España segundo quen as paga e as mantén: o Estado, as comunidades autónomas ou as deputacións (coas deputacións forais vascas, os cabidos canarios e os consells de Baleares), e cales son autoestradas de peaxe, autovías gratuítas ou estradas normais. Ademais, cantos vehículos pasan cada día por cada tramo da rede do Estado.

<Grid cols=4>
    <KpiCard
        title="Rede de estradas"
        value={espana[0]?.km_total}
        formattedValue="{formatNumber(espana[0]?.km_total, 0)} km"
        period="{formatNumber(espana[0]?.km_por_100k_hab, 0)} km por 100.000 hab. en {espana[0]?.anio}"
        source="Ministerio de Transportes"
    />
    <KpiCard
        title="Autoestradas, autovías e multicarril"
        value={espana[0]?.km_gran_capacidad}
        formattedValue="{formatNumber(espana[0]?.km_gran_capacidad, 0)} km"
        period="{formatNumber(espana[0]?.km_gran_capacidad_por_100k_hab, 1)} km por 100.000 hab."
        source="Ministerio de Transportes"
    />
    <KpiCard
        title="De peaxe"
        value={espana[0]?.km_peaje}
        formattedValue="{formatNumber(espana[0]?.km_peaje, 0)} km"
        period="o {formatNumber(espana[0]?.peaje_pct, 0)} % da rede de gran capacidade; {formatNumber(espana[0]?.km_peaje_estado, 0)} km do Estado"
        source="Ministerio de Transportes"
    />
    <KpiCard
        title="O tramo con máis tráfico"
        value={tramo_max[0]?.imd}
        formattedValue={formatNumber(tramo_max[0]?.imd, 0)}
        unit=" vehículos ao día"
        period="{tramo_max[0]?.carretera ?? ''} ({tramo_max[0]?.anio})"
        source="Ministerio de Transportes"
    />
</Grid>

## O mapa

<ButtonGroup name=vista title="Colorear por">
    <ButtonGroupItem valueLabel="Quen a xestiona" value="titular" default />
    <ButtonGroupItem valueLabel="Tipo de vía" value="tipo" />
</ButtonGroup>

<ButtonGroup name=filtro title="Mostrar">
    <ButtonGroupItem valueLabel="Todas" value="todas" />
    <ButtonGroupItem valueLabel="Só autoestradas, autovías e multicarril" value="gran_capacidad" default />
    <ButtonGroupItem valueLabel="Só de peaxe" value="peaje" />
</ButtonGroup>

```sql red
SELECT titular, titular_orden, tipo, tipo_orden, carretera, provincia, longitud_km, trazado
FROM mother.movilidad_carreteras_red
WHERE '${inputs.filtro}' = 'todas'
    OR ('${inputs.filtro}' = 'gran_capacidad' AND tipo <> 'convencional')
    OR ('${inputs.filtro}' = 'peaje' AND tipo = 'peaje')
```

<MapaEspana
    data={enRed(red, String(inputs.vista?.value ?? inputs.vista))}
    geom=trazado
    value=categoria
    colorCol=color
    legendType=categorical
    width=grosor
    minWidth={0.6}
    maxWidth={2.6}
    opacity={0.85}
    pointName=carretera
    height={680}
    tooltip={[
        {id: 'carretera', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'titular_texto', title: 'Quen a xestiona'},
        {id: 'tipo_texto', title: 'Tipo'},
        {id: 'provincia', title: 'Provincia'}
    ]}
/>

<p class="text-xs text-gray-500">Rede do Estado: catálogo oficial do Ministerio de Transportes (2025). Comunidades, deputacións, cabidos e consells: OpenStreetMap, coa titularidade deducida da matrícula de cada estrada (CL- da Junta de Castela e León, BV- da Diputació de Barcelona, DP- dunha deputación galega...) e a peaxe marcada no mapa; pode fallar nalgunha estrada solta. No País Vasco todas as estradas, tamén a A-8 e a AP-8, son das deputacións forais, e en Navarra, da Comunidade Foral. Non están as rúas nin os camiños dos concellos (uns 360.000 km máis, co 10 % do tráfico).</p>

```sql km_titular_tipo
SELECT k.titular, k.tipo, k.titular_orden, k.tipo_orden, k.km, k.anio
FROM mother.movilidad_carreteras_espana k
WHERE k.anio = (SELECT max(anio) FROM mother.movilidad_carreteras_espana)
ORDER BY k.titular_orden, k.tipo_orden
```

<BarChart
    data={etiquetar(etiquetar(km_titular_tipo, 'titular_texto', (d) => TITULAR[d.titular]), 'tipo_texto', (d) => TIPO[d.tipo])}
    x=titular_texto
    y=km
    series=tipo_texto
    type=stacked
    swapXY=true
    sort=false
    yFmt=num0
    seriesOrder={[TIPO.peaje, TIPO.autovia, TIPO.multicarril, TIPO.convencional]}
    colorPalette={[COLOR_TIPO.peaje, COLOR_TIPO.autovia, COLOR_TIPO.multicarril, COLOR_TIPO.convencional]}
    title="Km de estrada segundo quen a xestiona e tipo de vía ({km_titular_tipo[0]?.anio})"
/>

<p class="text-xs text-gray-500">O Estado xestiona só o {formatNumber(100 * espana[0]?.km_estado / espana[0]?.km_total, 0)} % dos km, pero case todas as autovías e autoestradas, que levan a metade do tráfico. As comunidades teñen o {formatNumber(100 * espana[0]?.km_comunidad / espana[0]?.km_total, 0)} % e as deputacións, cabidos e consells, o {formatNumber(100 * espana[0]?.km_diputacion / espana[0]?.km_total, 0)} %, case todo estradas convencionais.</p>

## As de pago

```sql peajes
SELECT carretera, titular,
    string_agg(DISTINCT provincia, ', ' ORDER BY provincia) AS provincias,
    sum(longitud_km) AS km
FROM mother.movilidad_carreteras_red
WHERE tipo = 'peaje'
GROUP BY carretera, titular
HAVING sum(longitud_km) >= 1
ORDER BY km DESC
```

<DataTable data={etiquetar(peajes, 'titular_texto', (d) => TITULAR[d.titular])} rows=15 search=true>
    <Column id=carretera title="Estrada" />
    <Column id=titular_texto title="Quen a xestiona" />
    <Column id=km title="Km de peaxe" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=provincias title="Provincias" />
</DataTable>

<p class="text-xs text-gray-500">Km de peaxe do catálogo do Estado e, no resto, medidos sobre OpenStreetMap (aproximados: ás veces contan as dúas calzadas ou os enlaces). As autoestradas do Estado que vencían entre 2018 e 2021 (AP-1, AP-4, a AP-7 da Jonquera a Alacante e a AP-2) pasaron a ser autovías gratuítas; quedan de peaxe, entre outras, a AP-6, a AP-9, a AP-68 e as radiais de Madrid. As forais vascas (AP-1, AP-8), a AP-15 de Navarra as da Generalitat (C-16, C-32) e as da Xunta (AG-55, AG-57) cóbranas os seus gobernos ou as súas concesionarias.</p>

```sql serie_tipo
SELECT anio, tipo, tipo_orden, sum(km) AS km
FROM mother.movilidad_carreteras_espana
WHERE tipo <> 'convencional'
GROUP BY anio, tipo, tipo_orden
ORDER BY anio, tipo_orden
```

<BarChart
    data={etiquetar(serie_tipo, 'tipo_texto', (d) => TIPO[d.tipo])}
    x=anio
    y=km
    series=tipo_texto
    type=stacked
    xFmt="0"
    yFmt=num0
    seriesOrder={[TIPO.peaje, TIPO.autovia, TIPO.multicarril]}
    colorPalette={[COLOR_TIPO.peaje, COLOR_TIPO.autovia, COLOR_TIPO.multicarril]}
    title="Km de autoestradas, autovías e multicarril desde 1970"
/>

<p class="text-xs text-gray-500">As primeiras autoestradas (anos 70) foron de peaxe; desde os 80 case todo o que se constrúe son autovías gratuítas. A peaxe baixou duns 3.000 km en 2017 a menos de 2.000 ao acabar as concesións das grandes autoestradas do Estado. Ata 1985 a serie publica datos cada cinco anos e ata 1990 non conta as estradas das deputacións.</p>

## Cantos vehículos pasan por cada tramo

<ButtonGroup name=vehiculos title="Vehículos">
    <ButtonGroupItem valueLabel="Todos" value="imd" default />
    <ButtonGroupItem valueLabel="Só pesados (camións e autobuses)" value="imd_pesados" />
</ButtonGroup>

```sql trafico
SELECT carretera, pk_inicio, pk_fin, imd, imd_pesados, pesados_pct, anio, titular,
    ${inputs.vehiculos} AS vehiculos, trazado
FROM mother.movilidad_carreteras_trafico
WHERE ${inputs.vehiculos} > 0
ORDER BY vehiculos
```

<MapaEspana
    data={etiquetar(trafico, 'tramo', (d) => tramoDe(d.vehiculos)[1])}
    geom=trazado
    value=tramo
    legendType=categorical
    colorPalette={TRAMOS.filter((t) => trafico.some((d) => tramoDe(d.vehiculos) === t)).map((t) => t[2])}
    width=vehiculos
    widthFmt=num0
    minWidth={0.8}
    maxWidth={7}
    opacity={0.9}
    pointName=carretera
    height={680}
    tooltip={[
        {id: 'carretera', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'imd', title: 'Vehículos ao día', fmt: 'num0'},
        {id: 'imd_pesados', title: 'Camións e autobuses ao día', fmt: 'num0'},
        {id: 'pesados_pct', title: '% de pesados', fmt: 'num1'},
        {id: 'pk_inicio', title: 'Desde o km', fmt: 'num1'},
        {id: 'pk_fin', title: 'Ata o km', fmt: 'num1'},
        {id: 'anio', title: 'Ano do dato', fmt: '0'}
    ]}
/>

<p class="text-xs text-gray-500">Intensidade media diaria (IMD): vehículos que pasan nun día medio do ano sumando os dous sentidos, medida polas estacións de aforo do Ministerio na Rede de Estradas do Estado. Máis groso = máis vehículos. As comunidades e deputacións publican os seus aforos cada unha pola súa banda (ou non os publican), así que a súa rede non aparece; segundo o Ministerio, pola rede do Estado pasa o 53 % do tráfico e o 66 % do de camións.</p>

```sql tramos_tabla
-- Tramos seguidos con la misma estación de aforo (misma IMD) en una sola fila
SELECT carretera, min(pk_inicio) AS pk_inicio, max(pk_fin) AS pk_fin, imd, max(imd_pesados) AS imd_pesados,
    max(pesados_pct) AS pesados_pct, anio
FROM mother.movilidad_carreteras_trafico
GROUP BY carretera, imd, anio
ORDER BY imd DESC
```

### Os tramos con máis tráfico

<DataTable data={tramos_tabla} rows=15 search=true>
    <Column id=carretera title="Estrada" />
    <Column id=pk_inicio title="Do km" fmt=num1 />
    <Column id=pk_fin title="Ao km" fmt=num1 />
    <Column id=imd title="Vehículos ao día" fmt=num0 contentType=bar barColor="#fed7aa" />
    <Column id=imd_pesados title="Pesados ao día" fmt=num0 />
    <Column id=pesados_pct title="% pesados" fmt=num1 />
    <Column id=anio title="Ano" fmt="0" />
</DataTable>

## Por provincia

<ButtonGroup name=medida title="Medir">
    <ButtonGroupItem valueLabel="Km por 100 km² de superficie" value="km_por_100_km2" default />
    <ButtonGroupItem valueLabel="Km por 100.000 habitantes" value="km_por_100k_hab" />
    <ButtonGroupItem valueLabel="Autovías e autoestradas por 100 km²" value="km_gran_capacidad_por_100_km2" />
    <ButtonGroupItem valueLabel="Autovías e autoestradas por 100.000 hab." value="km_gran_capacidad_por_100k_hab" />
</ButtonGroup>

```sql provincias_mapa
-- Sin Ceuta y Melilla: con 20 km² de superficie se salen de la escala
SELECT *, ${inputs.medida} AS medida FROM ${provincias} WHERE cod_prov NOT IN ('51', '52')
```

<MapaEspana
    data={provincias_mapa}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="medida"
    valueFmt="num1"
    colorPalette={['#fff7ed', '#fb923c', '#9a3412']}
    height={460}
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'km_total', title: 'Km de estrada', fmt: 'num0'},
        {id: 'km_por_100_km2', title: 'Por 100 km²', fmt: 'num1'},
        {id: 'km_por_100k_hab', title: 'Por 100.000 hab.', fmt: 'num0'},
        {id: 'km_gran_capacidad', title: 'Autovías, autoestradas e multicarril', fmt: 'num0'},
        {id: 'km_peaje', title: 'De peaxe', fmt: 'num0'}
    ]}
/>

```sql provincias_tabla
SELECT * FROM ${provincias} ORDER BY km_total DESC
```

<DataTable data={provincias_tabla} rows=10 search=true>
    <Column id=provincia title="Provincia" />
    <Column id=km_total title="Km" fmt=num0 contentType=bar barColor="#fed7aa" />
    <Column id=km_estado title="Estado" fmt=num0 />
    <Column id=km_comunidad title="Comunidade" fmt=num0 />
    <Column id=km_diputacion title="Deputación" fmt=num0 />
    <Column id=km_gran_capacidad title="Gran capacidade" fmt=num0 />
    <Column id=km_peaje title="Peaxe" fmt=num0 />
    <Column id=km_por_100_km2 title="Por 100 km²" fmt=num1 />
    <Column id=km_por_100k_hab title="Por 100.000 hab." fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Km do Anuario do Ministerio de Transportes (as comunidades e deputacións mandan os seus datos cun ano de atraso). Por superficie destacan Galicia (Pontevedra, Lugo, A Coruña), cunha rede de deputación moi densa polas súas miles de aldeas, Gipuzkoa, Bizkaia e Tenerife; por habitante, as provincias grandes e baleiras (Soria, Teruel, Cuenca, Zamora), onde hai moitas estradas para moi pouca xente.</p>

## Como creceu desde 1970

```sql serie_titular
SELECT anio, titular, titular_orden, sum(km) AS km, sum(km_por_100k_hab) AS km_por_100k_hab
FROM mother.movilidad_carreteras_espana
GROUP BY anio, titular, titular_orden
ORDER BY anio, titular_orden
```

<BarChart
    data={etiquetar(serie_titular, 'titular_texto', (d) => TITULAR[d.titular])}
    x=anio
    y=km
    series=titular_texto
    type=stacked
    xFmt="0"
    yFmt=num0
    seriesOrder={[TITULAR.estado, TITULAR.comunidad, TITULAR.diputacion]}
    colorPalette={[COLOR_TITULAR.estado, COLOR_TITULAR.comunidad, COLOR_TITULAR.diputacion]}
    title="Km de estrada segundo quen a xestiona"
/>

<p class="text-xs text-gray-500">En 1984 o Estado traspasou ás comunidades autónomas boa parte da súa rede: por iso pasa duns 80.000 km a 20.000. As estradas das deputacións só se contan desde 1990. Desde entón o total apenas cambia (uns 165.000 km); o que medra son as autovías.</p>

```sql serie_hab
SELECT anio, sum(km_por_100k_hab) FILTER (WHERE tipo <> 'convencional') AS km_por_100k_hab
FROM mother.movilidad_carreteras_espana
GROUP BY anio
HAVING sum(km_por_100k_hab) IS NOT NULL
ORDER BY anio
```

<LineChart
    data={serie_hab}
    x=anio
    y=km_por_100k_hab
    xFmt="0"
    yFmt=num1
    colorPalette={['#f97316']}
    title="Km de autoestradas, autovías e multicarril por 100.000 habitantes"
/>

## Fronte a Europa

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'autopistas_100k'
```

<Comparativa data={comparativa_internacional} decimales={1} />

```sql europa
SELECT cod_pais, pais,
    arg_max(km_autopistas, anio) AS km_autopistas,
    arg_max(km_por_100k_hab, anio) FILTER (WHERE km_por_100k_hab IS NOT NULL) AS km_por_100k_hab,
    arg_max(km_por_1000_km2, anio) AS km_por_1000_km2,
    max(anio) AS anio
FROM mother.movilidad_carreteras_europa
WHERE anio >= 2015
    AND cod_pais IN ('ES', 'FR', 'DE', 'IT', 'PT', 'NL', 'BE', 'AT', 'SE', 'PL', 'CZ', 'CH', 'GB', 'DK', 'FI', 'NO', 'IE', 'GR', 'HU', 'RO', 'HR', 'SI', 'SK', 'LU')
GROUP BY cod_pais, pais
```

<BarChart
    data={europa.filter((d) => d.km_autopistas > 0).toSorted((a, b) => b.km_autopistas - a.km_autopistas)}
    x=pais
    y=km_autopistas
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#f97316"
    title="Km de autoestradas e autovías (último ano publicado)"
/>

<BarChart
    data={europa.filter((d) => d.km_por_100k_hab > 0).toSorted((a, b) => b.km_por_100k_hab - a.km_por_100k_hab)}
    x=pais
    y=km_por_100k_hab
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#c2410c"
    title="Km de autoestradas e autovías por 100.000 habitantes"
/>

<BarChart
    data={europa.filter((d) => d.km_por_1000_km2 > 0).toSorted((a, b) => b.km_por_1000_km2 - a.km_por_1000_km2)}
    x=pais
    y=km_por_1000_km2
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#9a3412"
    title="Km de autoestradas e autovías por 1.000 km² de superficie"
/>

```sql europa_serie
SELECT anio, pais, km_autopistas
FROM mother.movilidad_carreteras_europa
WHERE cod_pais IN ('ES', 'FR', 'DE', 'IT', 'PT', 'GB', 'PL') AND anio >= 1990
ORDER BY anio
```

<LineChart
    data={europa_serie}
    x=anio
    y=km_autopistas
    series=pais
    xFmt="0"
    yFmt=num0
    title="Km de autoestradas e autovías desde 1990"
/>

<p class="text-xs text-gray-500">España ten a rede de autoestradas e autovías máis longa da UE e unha das máis longas por habitante. Por superficie está na media: o país é grande e está pouco poboado polo interior. Eurostat conta como autoestrada tamén as autovías; o último ano publicado varía segundo o país.</p>

---

## Fontes e notas

- **Km por titularidade e tipo de vía: [Anuario Estadístico do Ministerio de Transportes](https://otle.transportes.gob.es/datos-graficos-mapas/datos-anuales/capital-infraestructuras/infraestructura-basica/carretera/conjunto-redes-carreteras-estado-comunidades-autonomas-diputaciones-cabildos)**, a través do Observatorio do Transporte e a Loxística (OTLE): por provincia desde 2012 e para toda España desde 1970. As deputacións inclúen as forais vascas, os cabidos de Canarias e os consells de Baleares.
- **Rede do Estado: [Catálogo da Rede de Estradas do Estado](https://www.transportes.gob.es/carreteras/catalogo-y-evolucion-de-la-red-de-carreteras)** (Ministerio de Transportes), co tipo de cada tramo e se é de peaxe.
- **Redes de comunidades, deputacións, cabidos e consells: [OpenStreetMap](https://www.openstreetmap.org/copyright)** (© colaboradores de OpenStreetMap, licenza ODbL), estradas con matrícula descargadas coa API Overpass. A titularidade dedúcese da matrícula; os km oficiais son os do Anuario.
- **Tráfico: IMD por tramo da rede do Estado** do visor [Hermes](https://hermes.transportes.gob.es/) do Ministerio de Transportes (mapa de tráfico; último ano publicado de cada estrada).
- **[Eurostat](https://ec.europa.eu/eurostat/web/transport/database)**: km de autoestradas por país (road_if_motorwa), poboación e superficie.

<LastRefreshed prefix="Datos actualizados" />
