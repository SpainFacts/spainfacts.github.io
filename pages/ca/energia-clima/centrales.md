---
title: Centrals elèctriques
description: "Mapa de les centrals elèctriques d'Espanya: en operació, en construcció, en tramitació i retirades, per tecnologia, potència i propietari."
i18n_origen: b7b5b135c238
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import DownloadCsvButton from '../../../../../../../src/lib/components/DownloadCsvButton.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql tecnologias
SELECT tecnologia, any_value(color) AS color, min(orden_tecnologia) AS orden
FROM mother.centrales_resumen
GROUP BY tecnologia
ORDER BY orden
```

```sql kpis
SELECT
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En operación') / 1000 AS gw_operacion,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En operación' AND renovable) * 100
        / sum(potencia_mw) FILTER (WHERE estado_grupo = 'En operación') AS pct_renovable,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En construcción') / 1000 AS gw_construccion,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'En tramitación') / 1000 AS gw_tramitacion,
    sum(potencia_mw) FILTER (WHERE estado_grupo = 'Anunciada') / 1000 AS gw_anunciada,
    (SELECT count(*) FROM mother.centrales WHERE estado_grupo = 'En operación') AS n_operacion
FROM mother.centrales_resumen
```

```sql carbon
SELECT sum(mw_baja) / 1000 AS gw_carbon_retirado
FROM mother.centrales_por_anio
WHERE tecnologia = 'Carbón' AND anio >= 2018
```

```sql operacion_serie
SELECT anio, valor
FROM (
    SELECT anio, sum(sum(mw_alta - mw_baja)) OVER (ORDER BY anio) / 1000 AS valor
    FROM mother.centrales_por_anio
    WHERE anio <= year(current_date)
    GROUP BY anio
)
WHERE anio >= 2000
ORDER BY anio
```

```sql carbon_serie
SELECT anio, sum(sum(mw_baja)) OVER (ORDER BY anio) / 1000 AS valor
FROM mother.centrales_por_anio
WHERE tecnologia = 'Carbón' AND anio >= 2018 AND anio <= year(current_date)
GROUP BY anio
ORDER BY anio
```

# ⚡ Centrals elèctriques d'Espanya

Espanya té **{formatNumber(kpis[0]?.gw_operacion, 1)} GW** de potència en **{formatNumber(kpis[0]?.n_operacion, 0)} centrals** de més d'1 MW en funcionament, i uns altres **{formatNumber(kpis[0]?.gw_construccion, 1)} GW** en construcció. Al darrere esperen **{formatNumber(kpis[0]?.gw_tramitacion, 0)} GW** de projectes en tramitació, més que tota la potència que ja funciona, tot i que només una part s'arribarà a construir. Aquest mapa recull cada central (en operació, en obres, en tramitació, anunciada o ja tancada) segons l'inventari mundial de Global Energy Monitor.

<Grid cols=4>
    <KpiCard
        title="En operació"
        value={kpis[0]?.gw_operacion}
        formattedValue={formatNumber(kpis[0]?.gw_operacion, 1)}
        unit=" GW"
        period="{formatNumber(kpis[0]?.pct_renovable, 0)} % renovable"
        source="Global Energy Monitor"
        sparklineData={operacion_serie}
    />
    <KpiCard
        title="En construcció"
        value={kpis[0]?.gw_construccion}
        formattedValue={formatNumber(kpis[0]?.gw_construccion, 1)}
        unit=" GW"
        period="Obres iniciades"
        source="Global Energy Monitor"
    />
    <KpiCard
        title="En tramitació"
        value={kpis[0]?.gw_tramitacion}
        formattedValue={formatNumber(kpis[0]?.gw_tramitacion, 0)}
        unit=" GW"
        period="Amb permisos en curs"
        source="Global Energy Monitor"
    />
    <KpiCard
        title="Carbó tancat des del 2018"
        value={carbon[0]?.gw_carbon_retirado}
        formattedValue={formatNumber(carbon[0]?.gw_carbon_retirado, 1)}
        unit=" GW"
        period="Potència de carbó retirada"
        source="Global Energy Monitor"
        sparklineData={carbon_serie}
    />
</Grid>

---

## El mapa

Cada cercle és una central: la seva àrea és proporcional a la potència i el color indica la tecnologia. Tria l'estat, les tecnologies i la comunitat autònoma; passa el ratolí per sobre d'un cercle per veure'n les dades.

```sql opciones_ccaa
SELECT DISTINCT cod_ccaa, ccaa
FROM mother.centrales
WHERE ccaa IS NOT NULL
ORDER BY ccaa
```

<ButtonGroup name=estado title="Estat">
    <ButtonGroupItem valueLabel="En operació" value="En operación" default />
    <ButtonGroupItem valueLabel="En construcció" value="En construcción" />
    <ButtonGroupItem valueLabel="En tramitació" value="En tramitación" />
    <ButtonGroupItem valueLabel="Anunciada" value="Anunciada" />
    <ButtonGroupItem valueLabel="Paralitzada" value="Paralizada" />
    <ButtonGroupItem valueLabel="Retirada" value="Retirada" />
    <ButtonGroupItem valueLabel="Cancel·lada" value="Cancelada" />
    <ButtonGroupItem valueLabel="Totes" value="Todas" />
</ButtonGroup>

<Dropdown data={tecnologias} name=tec value=tecnologia order=orden title="Tecnologia" multiple=true selectAllByDefault=true />

<Dropdown data={opciones_ccaa} name=ccaa value=cod_ccaa label=ccaa title="Comunitat autònoma" defaultValue="Todas">
    <DropdownOption value="Todas" valueLabel="Tot Espanya" />
</Dropdown>

```sql filtradas
SELECT
    nombre,
    tecnologia,
    color,
    orden_tecnologia,
    estado_grupo,
    estados,
    potencia_mw,
    n_unidades,
    CASE
        WHEN estado_grupo = 'Retirada' AND anio_retiro IS NOT NULL THEN 'Cerrada en ' || CAST(CAST(anio_retiro AS INTEGER) AS VARCHAR)
        WHEN anio_inicio_min IS NULL THEN 'Sin fecha'
        WHEN anio_inicio_min = anio_inicio_max THEN CAST(CAST(anio_inicio_min AS INTEGER) AS VARCHAR)
        ELSE CAST(CAST(anio_inicio_min AS INTEGER) AS VARCHAR) || '–' || CAST(CAST(anio_inicio_max AS INTEGER) AS VARCHAR)
    END AS fechas,
    anio_inicio_min,
    coalesce(propietario, 'Sin datos') AS propietario,
    coalesce(municipio || ' (' || provincia || ')', provincia) AS ubicacion,
    provincia,
    ccaa,
    precision_ubicacion,
    lat,
    lon,
    url_gem
FROM mother.centrales
WHERE ('${inputs.estado}' = 'Todas' OR estado_grupo = '${inputs.estado}')
  AND tecnologia IN ${inputs.tec.value}
  AND ('${inputs.ccaa.value}' = 'Todas' OR cod_ccaa = '${inputs.ccaa.value}')
```

```sql mapa
-- La paleta categórica de BubbleMap se asigna por orden de aparición: primero
-- va la mayor central de cada tecnología (en el orden de la paleta) y luego el
-- resto de mayor a menor, para que las pequeñas queden encima.
SELECT *
FROM (
    SELECT *, row_number() OVER (PARTITION BY tecnologia ORDER BY potencia_mw DESC NULLS LAST, nombre) = 1 AS primera
    FROM ${filtradas}
    WHERE potencia_mw > 0
)
ORDER BY primera DESC, CASE WHEN primera THEN orden_tecnologia END, potencia_mw DESC
```

```sql colores_mapa
SELECT tecnologia, any_value(color) AS color, min(orden_tecnologia) AS orden
FROM ${filtradas}
WHERE potencia_mw > 0
GROUP BY tecnologia
ORDER BY orden
```

```sql totales_filtro
SELECT count(*) AS n_centrales, sum(potencia_mw) / 1000 AS gw
FROM ${filtradas}
```

<p class="text-sm text-gray-600 dark:text-gray-400">{formatNumber(totales_filtro[0]?.n_centrales, 0)} centrals amb {formatNumber(totales_filtro[0]?.gw, 1)} GW amb els filtres triats.</p>

<MapaEspana
    data={mapa}
    lat=lat
    long=lon
    size=potencia_mw
    maxSize={26}
    value=tecnologia
    legendType=categorical
    colorPalette={[...new Map(Array.from(mapa ?? []).map(d => [d.tecnologia, d.color])).values()]}
    opacity={0.75}
    pointName=nombre
    height={600}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri — Esri, HERE, Garmin, © OpenStreetMap contributors · Centrals: Global Energy Monitor (CC BY 4.0)"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tecnologia', title: 'Tecnologia'},
        {id: 'potencia_mw', title: 'Potència (MW)', fmt: 'num0'},
        {id: 'estados', title: 'Estat'},
        {id: 'fechas', title: 'Posada en marxa'},
        {id: 'propietario', title: 'Propietari'},
        {id: 'ubicacion', title: 'Ubicació'}
    ]}
/>

<p class="text-xs text-gray-500">Les coordenades d'unes 2.900 unitats (sobretot parcs solars i eòlics en tramitació) són aproximades: acostumen a situar-se al municipi, no a la parcel·la exacta. Les Canàries apareixen al sud-oest: amplia el mapa o tria la comunitat al filtre.</p>

---

## El que funciona i el que ve

La potència en tramitació i anunciada multiplica la instal·lada, però no és una previsió: una gran part d'aquests projectes no es construirà mai (el mateix inventari marca com a paralitzats o cancel·lats els que fa anys que no tenen notícies). La potència **en construcció** és la millor pista del que entrarà en servei en els pròxims dos o tres anys.

```sql por_estado
SELECT
    estado_grupo,
    min(orden_estado) AS orden_estado,
    tecnologia,
    sum(potencia_mw) / 1000 AS gw
FROM mother.centrales_ccaa
WHERE tecnologia IN ${inputs.tec.value}
  AND ('${inputs.ccaa.value}' = 'Todas' OR cod_ccaa = '${inputs.ccaa.value}')
GROUP BY estado_grupo, tecnologia
ORDER BY orden_estado, min(orden_tecnologia)
```

<BarChart
    data={por_estado}
    x=estado_grupo
    y=gw
    series=tecnologia
    type=stacked
    swapXY=true
    sort=false
    yFmt=num1
    yAxisTitle="GW"
    title="Potència per estat i tecnologia (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
    height={420}
/>

```sql por_ccaa
SELECT
    ccaa,
    tecnologia,
    sum(potencia_mw) / 1000 AS gw,
    sum(sum(potencia_mw)) OVER (PARTITION BY ccaa) AS total_ccaa
FROM mother.centrales_ccaa
WHERE ('${inputs.estado}' = 'Todas' OR estado_grupo = '${inputs.estado}')
  AND tecnologia IN ${inputs.tec.value}
GROUP BY ccaa, tecnologia
ORDER BY total_ccaa DESC, min(orden_tecnologia)
```

<BarChart
    data={por_ccaa}
    x=ccaa
    y=gw
    series=tecnologia
    type=stacked
    swapXY=true
    sort=false
    yFmt=num1
    yAxisTitle="GW"
    title="Potència per comunitat autònoma — {inputs.estado} (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
    height={520}
/>

---

## Com ha canviat el parc de generació

Potència que va entrar en servei i que es va tancar cada any segons la data de posada en marxa de cada unitat. S'hi veuen l'onada nuclear i del carbó dels anys vuitanta, els cicles combinats i l'eòlica dels anys 2000, l'aturada de la dècada del 2010 i la gran onada fotovoltaica des del 2019; i en el segon gràfic, el tancament de gairebé tot el carbó al voltant del 2020.

**Compte amb el 2017**: uns 790 parcs fotovoltaics petits (3,9 GW, mediana de 3 MW) figuren a l'inventari amb el 2017 com a any de posada en marxa. És gairebé segur una data assignada per defecte (tots són parcs la tecnologia dels quals GEM «suposa» fotovoltaica) i la majoria deuen ser del primer boom solar del 2007-2008. Aquest pic no reflecteix el que es va construir el 2017.

```sql altas_bajas
SELECT
    anio,
    tecnologia,
    min(orden_tecnologia) AS orden,
    sum(mw_alta) / 1000 AS gw_alta,
    sum(mw_baja) / 1000 AS gw_baja
FROM mother.centrales_por_anio
WHERE tecnologia IN ${inputs.tec.value}
  AND ('${inputs.ccaa.value}' = 'Todas' OR cod_ccaa = '${inputs.ccaa.value}')
  AND anio BETWEEN 1950 AND year(current_date)
GROUP BY anio, tecnologia
ORDER BY anio, orden
```

<BarChart
    data={altas_bajas}
    x=anio
    y=gw_alta
    series=tecnologia
    type=stacked
    xFmt="0"
    yFmt=num1
    yAxisTitle="GW"
    title="Potència posada en marxa cada any (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
/>

<BarChart
    data={altas_bajas}
    x=anio
    y=gw_baja
    series=tecnologia
    type=stacked
    xFmt="0"
    yFmt=num1
    yAxisTitle="GW"
    title="Potència tancada cada any (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
/>

```sql acumulada
WITH anios AS (
    SELECT range AS anio FROM range(1950, year(current_date) + 1)
),
tecs AS (
    SELECT DISTINCT tecnologia FROM ${altas_bajas}
),
neta AS (
    SELECT anio, tecnologia, sum(gw_alta - gw_baja) AS gw FROM ${altas_bajas} GROUP BY ALL
)
SELECT
    a.anio,
    t.tecnologia,
    sum(coalesce(n.gw, 0)) OVER (PARTITION BY t.tecnologia ORDER BY a.anio) AS gw
FROM anios a
CROSS JOIN tecs t
LEFT JOIN neta n ON n.anio = a.anio AND n.tecnologia = t.tecnologia
ORDER BY a.anio
```

<AreaChart
    data={acumulada}
    x=anio
    y=gw
    series=tecnologia
    xFmt="0"
    yFmt=num0
    yAxisTitle="GW"
    title="Potència en servei acumulada segons les dates d'alta i tancament (GW)"
    seriesColors={Object.fromEntries(tecnologias.map(d => [d.tecnologia, d.color]))}
    seriesOrder={tecnologias.map(d => d.tecnologia)}
/>

<p class="text-xs text-gray-500">Uns 8 GW en operació (sobretot parcs solars i eòlics petits) no tenen any de posada en marxa a l'inventari i no apareixen en aquests gràfics, de manera que l'acumulat queda una mica per sota de la potència actual. Les repotenciacions i les centrals que van tancar abans que existís l'inventari poden no figurar-hi.</p>

---

## Totes les centrals

```sql tabla
SELECT
    nombre,
    tecnologia,
    potencia_mw,
    n_unidades,
    estados,
    fechas,
    provincia,
    propietario,
    url_gem
FROM ${filtradas}
ORDER BY potencia_mw DESC NULLS LAST
```

<DataTable data={tabla} search=true rows=20>
    <Column id=nombre title="Central" />
    <Column id=tecnologia title="Tecnologia" />
    <Column id=potencia_mw title="MW" fmt=num0 />
    <Column id=n_unidades title="Unitats" />
    <Column id=estados title="Estat" />
    <Column id=fechas title="Posada en marxa" />
    <Column id=provincia title="Província" />
    <Column id=propietario title="Propietari" />
    <Column id=url_gem title="Fitxa" contentType=link linkLabel="GEM ↗" openInNewTab=true />
</DataTable>

<DownloadCsvButton data={tabla} filename="spainfacts_centrales_electricas.csv" label="Descarregar les centrals (CSV)" />

---

## Metodologia i advertiments

- **Font**: [Global Integrated Power Tracker](https://globalenergymonitor.org/projects/global-integrated-power-tracker/) de Global Energy Monitor (GEM), edició de setembre del 2026, amb llicència CC BY 4.0. És l'únic inventari obert que reuneix, per a tot Espanya, la ubicació, la potència, l'estat, el propietari i les dates de cada central, incloses les que estan en obres, en tramitació o ja tancades.
- **Unitats i centrals**: GEM registra unitats o fases (cada grup d'una tèrmica, cada fase d'un parc). Aquí s'agrupen per central i estat: si una central té grups tancats i d'altres en funcionament, apareix dues vegades, una en cada estat. La tecnologia de cada punt és la de més potència.
- **Estats**: _en operació_; _en construcció_ (obres iniciades); _en tramitació_ (preconstrucció: amb permisos o finançament en curs); _anunciada_; _paralitzada_ (projectes aturats, els que GEM dona per paralitzats després de dos anys sense notícies i les centrals en reserva o hibernades); _cancel·lada_ (inclosos els projectes sense notícies en quatre anys) i _retirada_.
- **La cartera de projectes està inflada**: en tramitació figuren uns 92 GW solars i 47 GW eòlics, molt més del que el sistema pot absorbir i del que preveu el PNIEC. Molts projectes competeixen pel mateix accés a la xarxa i acabaran caducant. Per això es mostren per separat la potència en construcció i la potència en tramitació o anunciada.
- **El que no hi és**: l'autoconsum i la fotovoltaica sobre teulada (uns 8-9 GW), les instal·lacions petites (GEM recull solar des de ~1 MW, eòlica des de ~6 MW i deixa fora la minihidràulica i bona part de la cogeneració industrial) i les bateries, que l'inventari no inclou; el bombament sí que hi és, dins de la hidràulica.
- **Comparació amb REE**: la potència en operació per tecnologia s'assembla a l'oficial de Red Eléctrica: fotovoltaica ~34 GW (REE ~32 GW sense autoconsum), eòlica ~31 GW (~32 GW), hidràulica amb bombament ~16 GW (~17 GW), cicles combinats ~27 GW (~26 GW), nuclear 7,4 GW bruts (7,1 GW nets). La cogeneració queda molt per sota de l'oficial (~1,4 GW davant de ~5-6 GW) perquè GEM només recull les grans. Bombament reuneix les centrals hidràuliques amb bombament, pur o mixt.
- **Tecnologies**: _cogeneració_ són les unitats de gas natural de menys de 150 MW que també produeixen calor per a la indústria; _turbines de gas i motors_ i _turbines de vapor_ són sobretot els grups de fuel i gasoil de les Canàries, les Balears, Ceuta i Melilla. Els residus urbans es compten com a no renovables i el bombament, com a emmagatzematge, tampoc no suma en el percentatge renovable.
- **Ubicació**: la província i la comunitat s'assignen per les coordenades de cada unitat (els parcs eòlics marins, a la província costanera més propera).

Cita: _Global Integrated Power Tracker, Global Energy Monitor, setembre del 2026 (CC BY 4.0)_.

<LastRefreshed prefix="Dades actualitzades" />
