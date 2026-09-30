---
i18n_origen: 7dffaf225345
title: Coche eléctrico
description: "Transición ao coche eléctrico en España: matriculacións de turismos por tipo de motor cada mes desde 2015, cota de eléctricos e híbridos enchufables por provincia e emisións de CO2."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
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

# ⚡ A transición ao coche eléctrico

Cantos dos coches que se venden en España xa son eléctricos? A resposta sae dos microdatos da Dirección General de Tráfico, que rexistran cada turismo matriculado co seu tipo de motor.

<Grid cols=3>
    <KpiCard
        title="Eléctricos puros"
        value={ultimo[0]?.cuota_bev * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_bev * 100, 1)}
        unit="%"
        period="dos turismos novos · {ultimo[0]?.mes_texto}"
        change={ultimo[0]?.cuota_bev_anio_antes != null ? ((ultimo[0].cuota_bev - ultimo[0].cuota_bev_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. un ano antes"
        direction="positive-up"
        source="DGT"
        sparklineData={cuota_mensual.map(d => ({valor: d.cuota_bev * 100}))}
    />
    <KpiCard
        title="Enchufables (eléctricos + híbridos enchufables)"
        value={ultimo[0]?.cuota_enchufables * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_enchufables * 100, 1)}
        unit="%"
        period="dos turismos novos · {ultimo[0]?.mes_texto}"
        change={ultimo[0]?.cuota_enchufables_anio_antes != null ? ((ultimo[0].cuota_enchufables - ultimo[0].cuota_enchufables_anio_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="vs. un ano antes"
        direction="positive-up"
        source="DGT"
        sparklineData={cuota_mensual.map(d => ({valor: d.cuota_enchufables * 100}))}
    />
    <KpiCard
        title="Electrificados (incluídos híbridos)"
        value={ultimo[0]?.cuota_electrificados * 100}
        formattedValue={formatNumber(ultimo[0]?.cuota_electrificados * 100, 1)}
        unit="%"
        period="dos turismos novos · {ultimo[0]?.mes_texto}"
        source="DGT"
        sparklineData={cuota_mensual.map(d => ({valor: d.cuota_electrificados * 100}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id = 'coche_electrico_cuota'
```

<Comparativa data={comparativa_internacional} decimales={0} />

## Cota de mercado dos turismos novos cada mes

<LineChart
    data={cuota_mensual}
    x=mes
    y={['cuota_bev', 'cuota_enchufables', 'cuota_electrificados']}
    yFmt=pct0
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#14b8a6', '#a3e635']}
    legend=true
    seriesLabels={{cuota_bev: 'Eléctricos puros', cuota_enchufables: 'Eléctricos + enchufables', cuota_electrificados: 'Todos os electrificados (con híbridos)'}}
/>

## Turismos novos por tipo de motor

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

<p class="text-xs text-gray-500">O diésel pasou de ser máis da metade das vendas en 2015 a unha fracción residual; o seu oco ocupárono primeiro a gasolina e despois os híbridos. Híbridos non enchufables (HEV) inclúe os <em>mild hybrid</em> (etiqueta ECO); os de autonomía estendida (REEV) cóntanse cos enchufables.</p>

<BarChart
    data={anual}
    x=anio
    y=por_1000
    series=motor
    type=stacked
    yFmt=num1
    yAxisTitle="por 1.000 habitantes"
    xFmt="####"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
    title="Turismos novos matriculados por ano, por 1.000 habitantes"
/>

<p class="text-xs text-gray-500">O último ano está incompleto (ata o último mes publicado).</p>

## Emisións de CO2 dos coches novos

<LineChart
    data={co2}
    x=mes
    y=co2_medio
    yFmt=num0
    xFmt="mmm yyyy"
    yAxisTitle="g CO2/km"
    colorPalette={['#78716c']}
/>

<p class="text-xs text-gray-500">Media das emisións homologadas dos turismos novos (g/km, eléctricos incluídos con 0). A suba ata 2021 ten dúas causas: o paso do diésel (que emite menos CO2 por quilómetro) á gasolina e o cambio de ciclo de homologación de NEDC a WLTP, máis esixente, que eleva as cifras oficiais sen que os coches contaminen máis. Desde entón baixan coa chegada de híbridos e eléctricos.</p>

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
GROUP BY ALL
ORDER BY cuota_enchufables DESC
```

## Onde se compran máis coches enchufables?

Cota de eléctricos e híbridos enchufables nos turismos novos dos últimos 12 meses, segundo a provincia do domicilio do titular.

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="cuota_enchufables"
    valueFmt="pct1"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: DGT"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'cuota_enchufables', title: 'Enchufables', fmt: 'pct1'},
        {id: 'cuota_bev', title: 'Eléctricos puros', fmt: 'pct1'},
        {id: 'turismos', title: 'Turismos novos', fmt: 'num0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true>
    <Column id=provincia title="Provincia" />
    <Column id=turismos title="Turismos novos (12 meses)" fmt=num0 />
    <Column id=cuota_bev title="Eléctricos puros" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_enchufables title="Enchufables" fmt=pct1 contentType=bar barColor="#99f6e4" />
    <Column id=cuota_diesel title="Diésel" fmt=pct1 />
</DataTable>

<p class="text-xs text-gray-500">Atención a Madrid e outras provincias con sedes de empresas de renting e aluguer: alí matricúlanse frotas que despois circulan por todo o país, o que incha o seu volume e a súa cota.</p>

---

## Fontes e notas

- **[DGT – Microdatos de matriculacións de vehículos (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**, mensual desde xaneiro de 2015. Cóntanse só as matriculacións ordinarias de turismos (incluídos todoterreos) **novos**; os usados importados, que tamén se matriculan por primeira vez en España, exclúense.
- O tipo de motor combina a categoría de vehículo eléctrico (BEV, PHEV, REEV, HEV) e a propulsión da ficha técnica. Gas inclúe GLP e gas natural.
- As cifras poden diferir lixeiramente das das asociacións do sector (ANFAC, que usa os seus propios criterios de data e clasificación).
- A comparación internacional (ano completo, eléctricos puros máis híbridos enchufables) procede da **[AIE – Global EV Data Explorer](https://www.iea.org/data-and-statistics/data-tools/global-ev-data-explorer)** (CC BY 4.0), que arredonda a números enteiros as cotas recentes; por iso pode non coincidir exactamente coa da DGT. Noruega e Dinamarca aparecen como referencia (bordo descontinuo): son os países onde o coche eléctrico está máis estendido.

<LastRefreshed prefix="Datos actualizados" />
