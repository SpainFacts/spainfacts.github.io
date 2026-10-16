---
title: Gasolindegiak eta erregaiak
description: "Espainiako gasolindegien mapa markaren eta taldearen arabera, probintzia bakoitzean biztanleko zenbat dauden, bat ere ez duten udalerriak, gasolioaren eta gasolinaren prezioa 2007tik euro errealetan, zergak EBko gainerako herrialdeekin alderatuta eta biztanleko erregai-litroak."
i18n_origen: 3712aa9c0eaa
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';

    // Etiquetas visibles: aquí y no en el SQL, que es idéntico en todas las traducciones
    const CARBURANTE = { gasoleo_a: 'A gasolioa', gasolina_95: '95 gasolina', glp: 'GLPa (autogasa)' };
    const TIPO = {
        'Petrolera': 'Petrolio-konpainiak',
        'Bajo coste': 'Kostu baxukoak',
        'Supermercado': 'Supermerkatuak',
        'Cooperativa': 'Kooperatibak',
        'Independiente con marca': 'Independenteak',
        'Independiente u otra': 'Independenteak'
    };
    const COLOR_TIPO = { 'Petrolio-konpainiak': '#0f766e', 'Kostu baxukoak': '#f59e0b', 'Supermerkatuak': '#7c3aed', 'Kooperatibak': '#65a30d', 'Independenteak': '#94a3b8' };
    const PARTE = { 'Sin impuestos': 'Zergarik gabe', 'Impuestos (IVA e impuesto especial)': 'Zergak (BEZa eta zerga berezia)' };
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

# ⛽ Gasolindegiak eta erregaiak

Non dauden Espainiako gasolindegiak eta noren jabetzakoak diren, zenbat kostatzen den depositua betetzea aurreko urteekin eta Europako gainerako herrialdeekin alderatuta, eta biztanle bakoitzak zenbat erregai erabiltzen duen. Prezioak eta estazioak Trantsizio Ekologikorako Ministerioaren gasolindegien geoatarikoak dira; estazio guztiek eguneratuta eduki behar dute.

<Grid cols=4>
    <KpiCard
        title="Gasolindegiak"
        value={totales[0]?.estaciones}
        formattedValue={formatNumber(10000 * totales[0]?.estaciones / totales[0]?.poblacion, 1)}
        unit=" 10.000 biz. bakoitzeko"
        period="jendaurrean saltzen duten {formatNumber(totales[0]?.estaciones, 0)} estazio"
        source="MITECO"
    />
    <KpiCard
        title="A gasolioa"
        value={totales[0]?.gasoleo_a}
        formattedValue="{formatNumber(totales[0]?.gasoleo_a, 3)} €/l"
        period="batez besteko prezioa, {totales[0]?.fecha}"
        source="MITECO"
    />
    <KpiCard
        title="95 gasolina"
        value={totales[0]?.gasolina_95}
        formattedValue="{formatNumber(totales[0]?.gasolina_95, 3)} €/l"
        period="batez besteko prezioa, {totales[0]?.fecha}"
        source="MITECO"
    />
    <KpiCard
        title="Udalerrian gasolindegirik ez duten biztanleak"
        value={totales[0]?.poblacion_sin}
        formattedValue="% {formatNumber(100 * totales[0]?.poblacion_sin / totales[0]?.poblacion, 1)}"
        period="{formatNumber(totales[0]?.municipios, 0)} udalerritatik {formatNumber(totales[0]?.municipios_sin, 0)}k ez dute bat ere"
        source="MITECO eta INE"
    />
</Grid>

## Gasolindegien mapa

<ButtonGroup name=tipo_mapa title="Mota">
    <ButtonGroupItem valueLabel="Guztiak" value="todas" default />
    <ButtonGroupItem valueLabel="Petrolio-konpainiak" value="Petrolera" />
    <ButtonGroupItem valueLabel="Kostu baxukoak" value="Bajo coste" />
    <ButtonGroupItem valueLabel="Supermerkatuak" value="Supermercado" />
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
        {id: 'grupo', title: 'Taldea'},
        {id: 'municipio', title: 'Udalerria'},
        {id: 'precio_gasoleo_a', title: 'A gasolioa (€/l)', fmt: '#,##0.000'},
        {id: 'precio_gasolina_95', title: '95 gasolina (€/l)', fmt: '#,##0.000'}
    ]}
/>

<p class="text-xs text-gray-500">Puntu bakoitza jendaurrean saltzen duen gasolindegi bat da; prezioa azken datu-kargakoa da. Kanariak behean ezkerreko laukian daude.</p>

## Noren eskuetan dauden gasolindegiak

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
    title="Gasolindegi gehien dituzten 15 taldeak"
/>

Lau gasolindegitik bat Repsolena da (Campsa eta Petronor barne). Kostu baxuko kateek, ia beti langilerik gabe, batez bestekoa baino zenbait zentimo merkeago saltzen dute gasolioa:

<DataTable data={grupos} rows=15 search=true>
    <Column id=grupo title="Taldea" />
    <Column id=estaciones title="Gasolindegiak" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_pct title="Sarearen %" fmt=num1 />
    <Column id=precio_gasoleo_a title="A gasolioa (€/l)" fmt="#,##0.000" />
    <Column id=dif_gasoleo_a title="Batez bestekoarekin alderatuta (€/l)" fmt="+#,##0.000;-#,##0.000" contentType=delta downIsGood=true />
    <Column id=precio_gasolina_95 title="95 gasolina (€/l)" fmt="#,##0.000" />
    <Column id=dif_gasolina_95 title="Batez bestekoarekin alderatuta (€/l)" fmt="+#,##0.000;-#,##0.000" contentType=delta downIsGood=true />
</DataTable>

<p class="text-xs text-gray-500">Taldea estazioaren errotuluaren araberakoa da: Campsa eta Petronor Repsolenak dira; Espainiako Shell estazioak DISAk ustiatzen ditu markaren lizentziarekin; Cepsak Moeve du izena 2024tik. Estazioen batez besteko soila, saldutako litroen arabera haztatu gabe (Ministerioak ez ditu argitaratzen). 20 gasolindegi edo gehiago dituzten taldeak bakarrik.</p>

## Probintziaka

```sql provincias
SELECT * FROM mother.movilidad_gasolineras_provincia ORDER BY estaciones_por_10k_hab DESC
```

<ButtonGroup name=indicador_prov title="Erakutsi">
    <ButtonGroupItem valueLabel="Gasolindegiak biztanleko" value="estaciones_por_10k_hab" default />
    <ButtonGroupItem valueLabel="Gasolindegirik gabeko biztanleak" value="poblacion_sin_gasolinera_pct" />
    <ButtonGroupItem valueLabel="Gasolioaren prezioa" value="precio_gasoleo_a" />
    <ButtonGroupItem valueLabel="Litroak biztanleko" value="litros_automocion_hab" />
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
        {id: 'estaciones_por_10k_hab', title: 'Gasolindegiak 10.000 biz. bakoitzeko', fmt: 'num1'},
        {id: 'poblacion_sin_gasolinera_pct', title: 'Udalerrian gasolindegirik ez duten biztanleen %', fmt: 'num1'},
        {id: 'precio_gasoleo_a', title: 'A gasolioa (€/l)', fmt: '#,##0.000'},
        {id: 'litros_automocion_hab', title: 'Erregai-litroak biztanleko eta urteko', fmt: 'num0'}
    ]}
/>

<p class="text-xs text-gray-500">Biztanle gutxiko probintziek gasolindegi gehiago dituzte biztanleko, baina baita bat ere ez duen udalerri batean bizi diren biztanle gehiago ere. Probintzia bakoitzeko biztanleko kontsumoan kamioiak eta bidean erregaia hartzen dutenak ere sartzen dira; horregatik da handiagoa igarobide diren probintzietan.</p>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Probintzia" />
    <Column id=estaciones title="Gasolindegiak" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=estaciones_por_10k_hab title="10.000 biz. bakoitzeko" fmt=num1 />
    <Column id=municipios_sin_gasolinera title="Gasolindegirik gabeko udalerriak" fmt=num0 />
    <Column id=poblacion_sin_gasolinera_pct title="Gasolindegirik gabeko biztanleen %" fmt=num1 />
    <Column id=bajo_coste_pct title="Kostu baxukoen %" fmt=num1 />
    <Column id=grupo_principal title="Talde nagusia" />
    <Column id=grupo_principal_pct title="Talde nagusiaren %" fmt=num0 />
    <Column id=precio_gasoleo_a title="A gasolioa (€/l)" fmt="#,##0.000" />
    <Column id=precio_gasolina_95 title="95 gasolina (€/l)" fmt="#,##0.000" />
</DataTable>

## Prezioa 2007tik

```sql provincias_lista
SELECT DISTINCT cod, nombre, CASE WHEN cod = '00' THEN 0 ELSE 1 END AS orden
FROM mother.movilidad_carburantes_precios
ORDER BY orden, nombre
```

<Dropdown name=territorio_precio title="Lurraldea" data={provincias_lista} value=cod label=nombre order=orden defaultValue="00" />

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
    yAxisTitle="€ litroko, euro konstanteetan (oinarria: {precios[0]?.anio_base ?? 'gaur'})"
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#f59e0b', '#7c3aed']}
    legend=true
/>

<p class="text-xs text-gray-500">Jendaurreko batez besteko salmenta-prezioa euro konstanteetan (inflazioa KPIarekin kenduta), hilabete bakoitzeko 1, 8, 15 eta 22an prezioa zuten gasolindegien batez bestekoa. 2008ko, 2012ko eta 2022ko gailurrek petrolioaren prezioari jarraitzen diote; 2022an Gobernuak litroko 20 zentimoko deskontua egin zuen kutxan, eta hori ez da argitaratutako prezioan agertzen.</p>

<LineChart
    data={etiquetar(precios, 'carburante', (d) => CARBURANTE[d.producto] ?? d.producto)}
    x=fecha
    y=precio_litro
    series=carburante
    yFmt="#,##0.00"
    yAxisTitle="€ litroko (urte bakoitzeko euroak)"
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#f59e0b', '#7c3aed']}
    legend=true
    title="Une bakoitzeko euroetan"
/>

## Europako gainerako herrialdeekin alderatuta

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
    title="Automobilgintzako gasolioa: litroaren prezioa, {ue_ultimo[0]?.mes_texto}"
/>

<p class="text-xs text-gray-500">Espainiako gasolioa EBko merkeenetakoa da, batez ere zerga gutxiago ordaintzen dituelako: {ue_ultimo[0]?.mes_texto} hilean zergak prezioaren % {formatNumber(ue_ultimo.find((d) => d.cod_pais === 'ES')?.impuestos_pct, 0)} ziren Espainian, eta % {formatNumber(ue_ultimo.find((d) => d.cod_pais === 'EU27_2020')?.impuestos_pct, 0)} batez beste EBn. Iturria: Europako Batzordearen Weekly Oil Bulletin.</p>

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
    yAxisTitle="€ litroko, herrialde bakoitzeko euro konstanteak"
    xFmt="mmm yyyy"
    legend=true
    title="Automobilgintzako gasolioa 2005etik, herrialde bakoitzeko inflazioa kenduta"
/>

## Zenbat erregai erabiltzen dugun

<KpiCard
    title="Automobilgintzako gasolina eta gasolioa biztanleko"
    value={consumo_ultimo[0]?.litros_automocion_hab}
    formattedValue="{formatNumber(consumo_ultimo[0]?.litros_automocion_hab, 0)} litro urtean"
    period="{consumo_ultimo[0]?.anio}. urtean; gehienekoa {formatNumber(consumo_ultimo[0]?.maximo, 0)} litro izan zen, {consumo_ultimo[0]?.anio_maximo}. urtean"
    source="CORES"
/>

<BarChart
    data={consumo_pais}
    x=anio
    y=litros_automocion_hab
    yFmt=num0
    fillColor="#0f766e"
    title="Gasolina eta A gasolio litroak biztanleko eta urteko"
/>

<p class="text-xs text-gray-500">Gasolinen eta automobilgintzako gasolioaren salmentak (kamioiak, autobusak eta furgonetak barne), tonetatik litrotara pasatuta erregai bakoitzaren batez besteko dentsitatearekin. Biztanleko kontsumoak 2007an jo zuen gailurra eta % 26 jaitsi zen 2013ra arte krisiarekin; 2020an hondoa jo zuen konfinamenduengatik. Gasolioa automobilgintzako erregaiaren % 56 izatetik (1997) % 80 ingurura igaro zen, eta orain jaisten ari da.</p>

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
    title="Litroak biztanleko {consumo_ccaa[0]?.anio}. urtean, erkidegoka"
/>

<p class="text-xs text-gray-500">Salmentak erregaia hartzen den tokian zenbatzen dira, ez gidaria bizi den tokian: Nafarroa, Gaztela eta Leon eta Euskadi goian daude kamioien ibilbide handiak haietatik igarotzen direlako, eta mugako probintzietan (Girona, Gipuzkoa, Nafarroa) gidari frantses askok hartzen dute erregaia, Espainian merkeagoa delako. Madrilek, Ceutak eta Melillak saltzen dute gutxien biztanleko.</p>

---

## Iturriak eta oharrak

- **[Trantsizio Ekologikorako Ministerioaren gasolindegien geoataria](https://geoportalgasolineras.es/)**, haren [erregaien prezioen REST zerbitzuaren](https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/) bidez: zerbitzugune guztiek beren prezioak jakinarazi behar dituzte (ITC/2308/2007 Agindua). Jendaurrean saltzen duten estazioak bakarrik; salmenta mugatukoak (kooperatibak, flotak) ez daude sartuta. Datu historikoak 2007ko urtarrilean hasten dira.
- Gasolindegi bakoitzaren udalerria haren koordenatuen arabera esleitu da; biztanleria INEren erroldakoa da.
- **[CORES, petrolio-produktuen kontsumoa probintziaka](https://www.cores.es/es/estadisticas)**, hilero 1997tik, tonetan; litrotara pasatuta 0,745 kg/l gasolinarentzat eta 0,835 kg/l gasolioarentzat.
- **[Europako Batzordea, Weekly Oil Bulletin](https://energy.ec.europa.eu/data-and-analysis/weekly-oil-bulletin_en)**: EBko herrialde bakoitzeko asteko prezioak, zergekin eta zergarik gabe, 2005etik; euro konstanteak herrialde bakoitzeko KPIHarekin (Eurostat).
- Espainiako euro konstanteak INEren KPIarekin.

<LastRefreshed prefix="Datuak eguneratuta" />
