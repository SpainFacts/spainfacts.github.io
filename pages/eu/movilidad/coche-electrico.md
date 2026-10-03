---
title: Auto elektrikoa
description: "Auto elektrikorako trantsizioa Espainian: turismoen matrikulazioak motor motaren arabera hilero 2015etik, elektrikoen eta hibrido entxufagarrien kuota probintziaka eta CO2 isuriak."
i18n_origen: ed78ed2e1c5f
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql mensual
SELECT
    mes,
    energia,
    energia_etiqueta AS motor,
    energia_orden,
    sum(matriculaciones) AS turismos
FROM mother.movilidad_matriculaciones_mensual
WHERE grupo = 'turismo' AND nuevo_usado = 'N'
GROUP BY ALL
ORDER BY mes, energia_orden
```

```sql cuota_mensual
SELECT
    mes,
    sum(turismos) FILTER (WHERE energia = 'bev') / sum(turismos) AS cuota_bev,
    sum(turismos) FILTER (WHERE energia IN ('bev', 'phev')) / sum(turismos) AS cuota_enchufables,
    sum(turismos) FILTER (WHERE energia IN ('bev', 'phev', 'hev')) / sum(turismos) AS cuota_electrificados,
    sum(turismos) AS total
FROM ${mensual}
GROUP BY mes
ORDER BY mes
```

```sql ultimo
SELECT
    c.*,
    strftime(c.mes, '%m/%Y') AS mes_texto,
    a.cuota_enchufables AS cuota_enchufables_anio_antes,
    a.cuota_bev AS cuota_bev_anio_antes
FROM ${cuota_mensual} c
LEFT JOIN ${cuota_mensual} a ON a.mes = c.mes - INTERVAL 12 MONTH
ORDER BY c.mes DESC
LIMIT 1
```

```sql anual
-- Turismos nuevos por 1.000 habitantes (padrón del año; el último para los más recientes)
WITH pob AS (
    SELECT CAST(anio AS INTEGER) AS anio, poblacion
    FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total'
)
SELECT
    CAST(year(m.mes) AS INTEGER) AS anio,
    m.motor,
    m.energia_orden,
    sum(m.turismos) AS turismos,
    1000.0 * sum(m.turismos) / any_value(p.poblacion) AS por_1000
FROM ${mensual} m
JOIN pob p ON p.anio = least(CAST(year(m.mes) AS INTEGER), (SELECT max(anio) FROM pob))
GROUP BY ALL
ORDER BY anio, m.energia_orden
```

```sql co2
SELECT
    mes,
    sum(co2_medio * matriculaciones) / sum(matriculaciones) AS co2_medio
FROM mother.movilidad_matriculaciones_mensual
WHERE grupo = 'turismo' AND nuevo_usado = 'N' AND co2_medio IS NOT NULL
GROUP BY mes
ORDER BY mes
```

```sql orden_motores
SELECT DISTINCT motor, energia_orden FROM ${mensual} ORDER BY energia_orden
```

# ⚡ Auto elektrikorako trantsizioa

Espainian saltzen diren autoetatik zenbat dira dagoeneko elektrikoak? Erantzuna Trafiko Zuzendaritza Nagusiaren mikrodatuetatik dator: matrikulatutako turismo bakoitza bere motor motarekin erregistratzen dute.

<Grid cols=3>
    <KpiCard
        title="Elektriko hutsak"
        value={ultimo[0]?.cuota_bev * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_bev * 100, 1)}
        unit="%"
        period="turismo berrien artean · {ultimo[0]?.mes_texto}"
        change={ultimo[0]?.cuota_bev_anio_antes != null ? ((ultimo[0].cuota_bev - ultimo[0].cuota_bev_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" p.p."
        changePeriod="duela urtebeterekin alderatuta"
        direction="positive-up"
        source="DGT"
        sparklineData={cuota_mensual.map(d => ({valor: d.cuota_bev * 100}))}
    />
    <KpiCard
        title="Entxufagarriak (elektrikoak + hibrido entxufagarriak)"
        value={ultimo[0]?.cuota_enchufables * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_enchufables * 100, 1)}
        unit="%"
        period="turismo berrien artean · {ultimo[0]?.mes_texto}"
        change={ultimo[0]?.cuota_enchufables_anio_antes != null ? ((ultimo[0].cuota_enchufables - ultimo[0].cuota_enchufables_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" p.p."
        changePeriod="duela urtebeterekin alderatuta"
        direction="positive-up"
        source="DGT"
        sparklineData={cuota_mensual.map(d => ({valor: d.cuota_enchufables * 100}))}
    />
    <KpiCard
        title="Elektrifikatuak (hibridoak barne)"
        value={ultimo[0]?.cuota_electrificados * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_electrificados * 100, 1)}
        unit="%"
        period="turismo berrien artean · {ultimo[0]?.mes_texto}"
        source="DGT"
        sparklineData={cuota_mensual.map(d => ({valor: d.cuota_electrificados * 100}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'coche_electrico_cuota'
```

<Comparativa data={comparativa_internacional} decimales={0} />

## Turismo berrien merkatu-kuota hilero

<LineChart
    data={cuota_mensual}
    x=mes
    y={['cuota_bev', 'cuota_enchufables', 'cuota_electrificados']}
    yFmt=pct0
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#14b8a6', '#a3e635']}
    legend=true
    seriesLabels={{cuota_bev: 'Elektriko hutsak', cuota_enchufables: 'Elektrikoak + entxufagarriak', cuota_electrificados: 'Elektrifikatu guztiak (hibridoekin)'}}
/>

## Turismo berriak motor motaren arabera

<BarChart
    data={mensual}
    x=mes
    y=turismos
    series=motor
    type=stacked100
    yFmt=pct0
    xFmt="mmm yyyy"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
/>

<p class="text-xs text-gray-500">Diesela 2015ean salmenten erdia baino gehiago izatetik hondar-zati bat izatera igaro zen; haren hutsunea lehenik gasolinak bete zuen, eta gero hibridoek. Hibrido ez-entxufagarriek (HEV) <em>mild hybrid</em> direlakoak barne hartzen dituzte (ECO etiketa); autonomia hedatukoak (REEV) entxufagarriekin batera zenbatzen dira.</p>

<BarChart
    data={anual}
    x=anio
    y=por_1000
    series=motor
    type=stacked
    yFmt=num1
    yAxisTitle="1.000 biztanleko"
    xFmt="####"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
    title="Urtean matrikulatutako turismo berriak, 1.000 biztanleko"
/>

<p class="text-xs text-gray-500">Azken urtea osatu gabe dago (argitaratutako azken hilabetera arte).</p>

## Nork erosten ditu auto berriak?

```sql canales_anual
SELECT
    CAST(year(mes) AS INTEGER) AS anio,
    canal_etiqueta AS canal,
    canal_orden,
    sum(matriculaciones) AS turismos,
    sum(matriculaciones) FILTER (WHERE energia IN ('bev', 'phev')) / sum(matriculaciones) AS cuota_enchufables
FROM mother.movilidad_matriculaciones_mensual
WHERE grupo = 'turismo' AND nuevo_usado = 'N'
GROUP BY ALL
ORDER BY anio, canal_orden
```

```sql canales_orden
SELECT DISTINCT canal, canal_orden FROM ${canales_anual} ORDER BY canal_orden
```

```sql canales_ultimo
SELECT
    any_value(anio) AS anio,
    100 * sum(turismos) FILTER (WHERE canal_orden = 1) / sum(turismos) AS pct_particulares,
    100 * max(cuota_enchufables) FILTER (WHERE canal_orden = 1) AS pct_enchufables_particulares,
    100 * sum(turismos * cuota_enchufables) FILTER (WHERE canal_orden > 1) / sum(turismos) FILTER (WHERE canal_orden > 1) AS pct_enchufables_flotas
FROM ${canales_anual}
-- Último año completo (con diciembre publicado)
WHERE anio = (SELECT CAST(year(max(mes)) AS INTEGER) - CASE WHEN month(max(mes)) = 12 THEN 0 ELSE 1 END FROM mother.movilidad_matriculaciones_mensual)
```

Turismo berrien erdia baino gutxiago erosten dituzte partikularrek. Gainerakoa flotetara doa: enpresak (kontzesionarioen eta marken automatrikulazioak barne, «zero kilometrokoak»), rentinga, auto-alokairua eta taxiak eta VTCak. {canales_ultimo[0]?.anio}. urtean, partikularrek matrikulazioen % {formatNumber(canales_ultimo[0]?.pct_particulares, 1)} hartu zuten; entxufagarriak haien erosketen % {formatNumber(canales_ultimo[0]?.pct_enchufables_particulares, 1)} izan ziren, flotetan % {formatNumber(canales_ultimo[0]?.pct_enchufables_flotas, 1)} izan ziren bitartean.

<BarChart
    data={canales_anual}
    x=anio
    y=turismos
    series=canal
    type=stacked100
    yFmt=pct0
    xFmt="####"
    seriesOrder={canales_orden.map(d => d.canal)}
    colorPalette={['#0d9488', '#2563eb', '#7c3aed', '#f59e0b', '#9ca3af']}
    title="Turismo berriak salmenta-kanalaren arabera"
/>

<LineChart
    data={canales_anual}
    x=anio
    y=cuota_enchufables
    series=canal
    yFmt=pct0
    xFmt="####"
    markers=true
    seriesOrder={canales_orden.map(d => d.canal)}
    colorPalette={['#0d9488', '#2563eb', '#7c3aed', '#f59e0b', '#9ca3af']}
    title="Entxufagarrien kuota (elektrikoak + hibrido entxufagarriak) kanal bakoitzean"
/>

<p class="text-xs text-gray-500">Partikularrak: pertsona fisiko baten izenean (autonomoak barne) rentingik gabe matrikulatutakoak. Enpresak: pertsona juridikoak, rentingik eta alokairurik gabe. Renting: epe luzeko errentamendu-kontratuak, enpresenak edo partikularrenak. Alokairua: gidaririk gabeko alokairu-zerbitzua (rent a car). Taxia, VTCa eta beste batzuk: zerbitzu publikoa (taxia, gidaridun alokairua, autoeskola...). Azken urtea osatu gabe dago.</p>

## Auto berrien CO2 isuriak

<LineChart
    data={co2}
    x=mes
    y=co2_medio
    yFmt=num0
    xFmt="mmm yyyy"
    yAxisTitle="g CO2/km"
    colorPalette={['#78716c']}
/>

<p class="text-xs text-gray-500">Turismo berrien isuri homologatuen batez bestekoa (g/km; elektrikoak 0rekin sartuta). 2021era arteko igoerak bi arrazoi ditu: dieseletik (kilometroko CO2 gutxiago isurtzen du) gasolinarako aldaketa, eta homologazio-zikloa NEDCtik WLTPra aldatu izana; azken hori zorrotzagoa da eta zifra ofizialak igotzen ditu autoek gehiago kutsatu gabe. Harrezkero jaisten ari dira, hibridoak eta elektrikoak iritsi ahala.</p>

```sql provincias
WITH ult AS (SELECT max(mes) AS mes FROM mother.movilidad_matriculaciones_provincia)
SELECT
    p.cod_prov,
    p.provincia,
    sum(p.matriculaciones) AS turismos,
    sum(p.matriculaciones) FILTER (WHERE p.energia = 'bev') / sum(p.matriculaciones) AS cuota_bev,
    sum(p.matriculaciones) FILTER (WHERE p.energia IN ('bev', 'phev')) / sum(p.matriculaciones) AS cuota_enchufables,
    sum(p.matriculaciones) FILTER (WHERE p.energia = 'diesel') / sum(p.matriculaciones) AS cuota_diesel
FROM mother.movilidad_matriculaciones_provincia p, ult
WHERE p.nuevo_usado = 'N'
  AND p.mes > ult.mes - INTERVAL 12 MONTH
  AND ('${inputs.canal_prov}' = 'todos' OR p.canal = 'particular')
GROUP BY ALL
ORDER BY cuota_enchufables DESC
```

## Non erosten dira auto entxufagarri gehien?

Elektrikoen eta hibrido entxufagarrien kuota azken 12 hilabeteetako turismo berrietan, titularraren helbideko probintziaren arabera. Lehenespenez, partikularrenak soilik zenbatzen dira: flotak egoitza duten tokian matrikulatzen dira eta mapa desitxuratzen dute (ikus beheko oharra).

<ButtonGroup name=canal_prov title="Erosleak">
    <ButtonGroupItem valueLabel="Partikularrak soilik" value="particular" default />
    <ButtonGroupItem valueLabel="Guztiak, flotak barne" value="todos" />
</ButtonGroup>

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="cuota_enchufables"
    valueFmt="pct1"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: DGT"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_enchufables', title: 'Entxufagarriak', fmt: 'pct1'},
        {id: 'cuota_bev', title: 'Elektriko hutsak', fmt: 'pct1'},
        {id: 'turismos', title: 'Turismo berriak', fmt: 'num0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Probintzia" />
    <Column id=turismos title="Turismo berriak (12 hilabete)" fmt=num0 />
    <Column id=cuota_bev title="Elektriko hutsak" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_enchufables title="Entxufagarriak" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_diesel title="Diesela" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500"><b>Non matrikulatzen dituzten flotak.</b> Auto bat titularraren helbideko udalerrian matrikulatzen da, eta renting eta alokairu enpresek aukeratzen dute non helbideratu beren flotak. Zirkulazio-zerga (IVTM) udalekoa da: udal bakoitzak gutxieneko tarifa bikoiztu arte igo dezake, eta, beraz, flota asko zerga baxuena duen udalerri batean irekitako ordezkaritza batean erregistratzen dira. Horregatik, La Hiruela, Venturada edo Patones (Madril) edo Aguilar de Segarra (Bartzelona) bezalako herriek biztanleak baino askoz auto gehiago matrikulatzen dituzte urtero, eta AEA elkartearen arabera hamar udalerrik biltzen dituzte enpresa-ibilgailuen matrikulazioen % 35 inguru. Auto horiek gero herrialde osoan zehar zirkulatzen dute; «Guztiak, flotak barne» aukerarekin, Madril eta Bartzelona beren bizilagunek erosten dutenaren oso gainetik agertzen dira. Iturria: <a href="https://aeaclub.org/ivtm-impuesto-municipal-vehiculos-paraisos-fiscales/">AEA, IVTMri buruzko azterlana (2026)</a>. Udalerriak, banan-banan, <a href="/eu/movilidad/flotas-e-impuestos">Flotentzako paradisu fiskalak</a> orrian.</p>

---

## Iturriak eta oharrak

- **[DGT – Ibilgailuen matrikulazioen mikrodatuak (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**, hilero 2015eko urtarriletik. Turismo **berrien** (lur orotako ibilgailuak barne) matrikulazio arruntak soilik zenbatzen dira; inportatutako erabilitakoak, Espainian lehen aldiz matrikulatzen badira ere, kanpoan uzten dira.
- Motor motak ibilgailu elektrikoaren kategoria (BEV, PHEV, REEV, HEV) eta fitxa teknikoko propultsioa konbinatzen ditu. Gasak GLPa eta gas naturala barne hartzen ditu.
- Zifrak apur bat desberdinak izan daitezke sektoreko elkarteenekin alderatuta (ANFAC, data- eta sailkapen-irizpide propioak erabiltzen dituena). ANFACek partikularrak, enpresak eta alokatzaileak ere bereizten ditu; hemen, kanala DGTren fitxategiko ibilgailu bakoitzaren titularretik (pertsona fisikoa edo juridikoa), renting-adierazletik eta zerbitzu motatik ateratzen da.
- Azken hilabetea, DGTk hileko fitxategia argitaratu arte (hurrengo hilabetearen 15. egunaren inguruan), haren eguneko fitxategiekin kalkulatzen da.
- Nazioarteko alderaketa (urte osoa, elektriko hutsak gehi hibrido entxufagarriak) **[IEA – Global EV Data Explorer](https://www.iea.org/data-and-statistics/data-tools/global-ev-data-explorer)** iturritik dator (CC BY 4.0), eta hark zenbaki osoetara biribiltzen ditu azken kuotak; horregatik, baliteke DGTrenarekin zehazki bat ez etortzea. Norvegia eta Danimarka erreferentzia gisa agertzen dira (ertz etena): auto elektrikoa gehien zabalduta dagoen herrialdeak dira.

<LastRefreshed prefix="Datuak eguneratuta" />
