---
title: Kamioiak eta autobusak
description: "Kamioiak eta autobusak Espainian: matrikulazioak motor motaren arabera 2015etik, autobus elektrikoaren aurrerapena, marka eta talde salduenak eta zirkulatzen dutenen antzinatasuna."
i18n_origen: f423a33aa6c8
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql energias
SELECT DISTINCT energia, energia_etiqueta, energia_orden
FROM mother.movilidad_matriculaciones_mensual
ORDER BY energia_orden
```

```sql anual
-- Camiones y autobuses nuevos por año y motor, por 100.000 habitantes
WITH pob AS (
    SELECT CAST(anio AS INTEGER) AS anio, poblacion
    FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total'
)
SELECT
    CAST(year(m.mes) AS INTEGER) AS anio,
    m.grupo,
    m.energia,
    m.energia_etiqueta AS motor,
    m.energia_orden,
    sum(m.matriculaciones) AS unidades,
    100000.0 * sum(m.matriculaciones) / any_value(p.poblacion) AS por_100000
FROM mother.movilidad_matriculaciones_mensual m
JOIN pob p ON p.anio = least(CAST(year(m.mes) AS INTEGER), (SELECT max(anio) FROM pob))
WHERE m.grupo IN ('camion', 'autobus') AND m.nuevo_usado = 'N'
GROUP BY ALL
ORDER BY anio, m.energia_orden
```

```sql cero_emisiones
-- Cuota de cero emisiones (eléctricos puros e hidrógeno) en los últimos 12 meses y un año antes
WITH ult AS (SELECT max(mes) AS mes FROM mother.movilidad_matriculaciones_mensual),
base AS (
    SELECT
        m.grupo,
        m.mes > u.mes - INTERVAL 12 MONTH AS actual,
        sum(m.matriculaciones) AS total,
        sum(m.matriculaciones) FILTER (WHERE m.energia IN ('bev', 'hidrogeno')) AS cero,
        sum(m.matriculaciones) FILTER (WHERE m.energia = 'diesel') AS diesel
    FROM mother.movilidad_matriculaciones_mensual m, ult u
    WHERE m.grupo IN ('camion', 'autobus') AND m.nuevo_usado = 'N'
      AND m.mes > u.mes - INTERVAL 24 MONTH
    GROUP BY ALL
)
SELECT
    a.grupo,
    a.total,
    a.cero / a.total AS cuota_cero,
    a.diesel / a.total AS cuota_diesel,
    b.cero / b.total AS cuota_cero_antes,
    (SELECT strftime(mes, '%m/%Y') FROM ult) AS mes_texto
FROM base a
JOIN base b ON b.grupo = a.grupo AND NOT b.actual
WHERE a.actual
```

```sql anual_cuota
SELECT anio, grupo,
    sum(unidades) FILTER (WHERE energia IN ('bev', 'hidrogeno')) / sum(unidades) AS cuota_cero,
    CASE grupo WHEN 'camion' THEN 'Camiones' ELSE 'Autobuses' END AS vehiculo
FROM ${anual}
GROUP BY ALL
ORDER BY anio
```

```sql orden_motores
SELECT DISTINCT motor, energia_orden FROM ${anual} ORDER BY energia_orden
```

# 🚚 Kamioiak eta autobusak

Kamioiak eta autobusak gutxi dira autoekin alderatuta, baina askoz kilometro gehiago egiten dituzte eta batez ere gasolioa erretzen dute: garraio astuna errepideko garraioaren isurien zati garrantzitsua da. Hemen ikusten da zenbat saltzen diren, zer motorrekin eta zenbat urte dituzten zirkulatzen dutenek.

<Grid cols=2>
    <KpiCard
        title="Zero isuriko autobus berriak"
        value={cero_emisiones.filter(d => d.grupo === 'autobus')[0]?.cuota_cero * 100}
        formattedValue={formatNumber(cero_emisiones.filter(d => d.grupo === 'autobus')[0]?.cuota_cero * 100, 1)}
        unit="%"
        period="elektrikoak eta hidrogenoa · {cero_emisiones[0]?.mes_texto} arteko 12 hilabeteak"
        change={cero_emisiones.filter(d => d.grupo === 'autobus')[0]?.cuota_cero_antes != null ? ((cero_emisiones.filter(d => d.grupo === 'autobus')[0].cuota_cero - cero_emisiones.filter(d => d.grupo === 'autobus')[0].cuota_cero_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="aurreko 12 hilabeteekin alderatuta"
        direction="positive-up"
        source="DGT"
    />
    <KpiCard
        title="Zero isuriko kamioi berriak"
        value={cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_cero * 100}
        formattedValue={formatNumber(cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_cero * 100, 1)}
        unit="%"
        period="elektrikoak eta hidrogenoa · % {formatNumber(cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_diesel * 100, 0)} diesela · 12 hilabete"
        change={cero_emisiones.filter(d => d.grupo === 'camion')[0]?.cuota_cero_antes != null ? ((cero_emisiones.filter(d => d.grupo === 'camion')[0].cuota_cero - cero_emisiones.filter(d => d.grupo === 'camion')[0].cuota_cero_antes) * 100).toFixed(1) : null}
        changeUnit=" pp"
        changePeriod="aurreko 12 hilabeteekin alderatuta"
        direction="positive-up"
        source="DGT"
    />
</Grid>

## Zero isurien kuota ibilgailu berrietan

<LineChart
    data={anual_cuota}
    x=anio
    y=cuota_cero
    series=vehiculo
    yFmt=pct0
    xFmt="####"
    markers=true
    colorPalette={['#0f766e', '#f59e0b']}
    title="Elektriko hutsak eta hidrogenoa, urtero matrikulatutakoen %"
/>

<p class="text-xs text-gray-500">Hiri-autobusak lehenago elektrifikatzen dira, ibilbide laburrak egiten dituztelako eta gauero gordetegira itzultzen direlako, eta han kargatzen dira; Europako laguntzek eta hirietako emisio gutxiko eremuek ere bultzatzen dute. Distantzia luzeko kamioia ia osorik dieselean dabil oraindik: bateriek asko pisatzen dute eta ibilgailu astunentzako karga-sarea hasi besterik ez da egin. Azken urtea osatu gabe dago.</p>

## Autobus berriak motor motaren arabera

<BarChart
    data={anual.filter(d => d.grupo === 'autobus')}
    x=anio
    y=unidades
    series=motor
    type=stacked100
    yFmt=pct0
    xFmt="####"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
/>

## Kamioi berriak motor motaren arabera

<BarChart
    data={anual.filter(d => d.grupo === 'camion')}
    x=anio
    y=por_100000
    series=motor
    type=stacked
    yFmt=num0
    yAxisTitle="100.000 biztanleko"
    xFmt="####"
    seriesOrder={orden_motores.map(d => d.motor)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
    title="Urtean matrikulatutako kamioi berriak, 100.000 biztanleko"
/>

<p class="text-xs text-gray-500">Kamioien salmentek ziklo ekonomikoari jarraitzen diote: krisietan jaisten dira (2020) eta jarduerarekin batera berreskuratzen dira. Pisu guztietako kamioiak eta trakzio-buruak barne hartzen ditu; furgonetak aparte zenbatzen dira.</p>

## Marka eta talde salduenak

```sql marcas
WITH ult AS (SELECT max(mes) AS mes FROM mother.movilidad_marcas_mensual)
SELECT
    m.grupo,
    m.grupo_etiqueta AS vehiculo,
    m.grupo_empresarial,
    m.marca,
    sum(m.matriculaciones) AS unidades
FROM mother.movilidad_marcas_mensual m, ult u
WHERE m.grupo IN ('camion', 'autobus')
  AND m.mes > u.mes - INTERVAL 12 MONTH
GROUP BY ALL
```

```sql grupos
WITH g AS (
    SELECT
        vehiculo,
        grupo_empresarial AS grupo,
        string_agg(marca, ', ' ORDER BY unidades DESC) AS marcas,
        sum(unidades) AS unidades
    FROM ${marcas}
    GROUP BY vehiculo, grupo_empresarial
)
SELECT *
FROM (
    SELECT *,
        unidades / sum(unidades) OVER (PARTITION BY vehiculo) AS cuota,
        row_number() OVER (PARTITION BY vehiculo ORDER BY unidades DESC) AS puesto
    FROM g
)
WHERE puesto <= 10
ORDER BY vehiculo DESC, unidades DESC
```

Azken 12 hilabeteetan matrikulazio gehien izan dituzten hamar taldeak. Karrozagile batek amaitzen dituen ibilgailuetan (autobus gehienak eta kamioi asko) txasiaren marka zenbatzen da: Scania txasi baten gainean Irizar edo Castrosua karrozeria duen autobus bat Scania gisa zenbatzen da.

<DataTable data={grupos} rows=20 groupBy=vehiculo groupsOpen=true>
    <Column id=grupo title="Taldea" />
    <Column id=marcas title="Markak" wrap=true />
    <Column id=unidades title="Unitateak" fmt=num0 />
    <Column id=cuota title="Kuota" fmt=pct1 contentType=bar barColor="#ddd6fe" />
</DataTable>

<p class="text-xs text-gray-500">Taldea, jabe nagusiaren arabera: Scania eta MAN Volkswagen taldekoak dira (Traton); Volvo eta Renault Trucks, AB Volvokoak (Volvo Cars-ez bestelakoa, hori Geelyrena baita); Mercedes-Benz, Setra eta Fuso, Daimler Truckekoak. Sailkapen osoa, hilabeteka eta motor motaren arabera, <a href="/eu/movilidad/marcas-y-modelos">Marka eta modelo salduenak</a> orrian dago.</p>

## Zirkulatzen dutenen antzinatasuna

```sql antiguedad
SELECT
    CASE grupo WHEN 'camion' THEN 'Camiones' WHEN 'autobus' THEN 'Autobuses' ELSE 'Turismos' END AS vehiculo,
    antiguedad,
    CASE antiguedad WHEN '0-4' THEN 1 WHEN '5-9' THEN 2 WHEN '10-14' THEN 3 WHEN '15-19' THEN 4 WHEN '20+' THEN 5 ELSE 6 END AS orden,
    CASE antiguedad WHEN '0-4' THEN 'Menos de 5 años' WHEN '5-9' THEN '5 a 9 años' WHEN '10-14' THEN '10 a 14 años'
        WHEN '15-19' THEN '15 a 19 años' WHEN '20+' THEN '20 años o más' ELSE 'Sin dato' END AS tramo,
    sum(vehiculos) AS vehiculos
FROM mother.movilidad_parque_provincia
WHERE grupo IN ('camion', 'autobus', 'turismo')
  AND mes = (SELECT max(mes) FROM mother.movilidad_parque_provincia)
GROUP BY ALL
ORDER BY orden
```

```sql tramos
SELECT DISTINCT tramo, orden FROM ${antiguedad} ORDER BY orden
```

<BarChart
    data={antiguedad}
    x=vehiculo
    y=vehiculos
    series=tramo
    type=stacked100
    swapXY=true
    yFmt=pct0
    seriesOrder={tramos.map(d => d.tramo)}
    colorPalette={['#0f766e', '#5eead4', '#fde68a', '#f59e0b', '#b91c1c', '#d1d5db']}
    title="Zirkulazioan dauden ibilgailuak antzinatasunaren arabera (turismoak, erreferentzia gisa)"
/>

<p class="text-xs text-gray-500">DGTren altan dauden ibilgailuen parkea, argitaratutako azken hilabetea. Xehetasun gehiago, probintziaka eta udalerrika, <a href="/eu/movilidad/parque">Ibilgailu-parkea</a> orrian.</p>

---

## Iturriak eta oharrak

- **[DGT – Ibilgailuen matrikulazioen mikrodatuak (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**, hilero 2015eko urtarriletik. Ibilgailu berrien matrikulazio arruntak soilik.
- **[DGT – Ibilgailu-parkea](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/parque-vehiculos-mensual.html)**, argitaratutako azken hilabetea.
- Kamioiak: DGTren kamioi eta trakzio-buru motak, edozein pisutakoak. Autobusak: autobusak eta autokarrak, artikulatuak eta bi solairukoak barne. Zero isuriak: elektriko hutsak (BEV) eta hidrogeno-pilakoak.

<LastRefreshed prefix="Datuak eguneratuta" />
