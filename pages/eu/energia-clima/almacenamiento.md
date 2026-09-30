---
title: Elektrizitatearen biltegiratzea
description: "Ponpaketa hidraulikoa eta bateriak Espainian: zenbat energia biltegiratzen eta itzultzen duten, instalatutako potentzia autonomia-erkidegoka, errendimendua eta sarerako sarbide-baimena duten proiektuak, PNIECek 2030erako ezarritako 22,5 GWko helburuaren aldean."
i18n_origen: 664df261ab3d
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql potencia_ultima
SELECT
    strftime(max(mes), '%m/%Y') AS mes_texto,
    sum(mw) FILTER (WHERE tipo = 'bombeo_puro') AS bombeo_mw,
    sum(mw) FILTER (WHERE tipo = 'baterias_hibridadas') AS baterias_mw
FROM mother.almacenamiento_potencia
WHERE mes = (SELECT max(mes) FROM mother.almacenamiento_potencia)
```

```sql baterias_serie
SELECT mes, sum(mw) AS valor
FROM mother.almacenamiento_potencia
WHERE tipo = 'baterias_hibridadas'
GROUP BY mes
ORDER BY mes ASC
```

```sql acceso_total
SELECT
    strftime(max(fecha_fichero), '%d/%m/%Y') AS fecha_texto,
    sum(otorgada_mw) AS otorgada_mw,
    sum(en_tramitacion_mw) AS en_tramitacion_mw
FROM mother.almacenamiento_acceso
WHERE fecha_fichero = (SELECT max(fecha_fichero) FROM mother.almacenamiento_acceso)
```

```sql anual
SELECT
    CAST(year(mes) AS INTEGER) AS anio,
    count(*) AS meses,
    sum(bombeo_turbinado_gwh) AS bombeo_turbinado_gwh,
    sum(bombeo_consumido_gwh) AS bombeo_consumido_gwh,
    sum(baterias_entregado_gwh) AS baterias_entregado_gwh,
    sum(baterias_cargado_gwh) AS baterias_cargado_gwh,
    sum(bombeo_turbinado_gwh) / sum(bombeo_consumido_gwh) AS rendimiento
FROM mother.almacenamiento_mensual
GROUP BY 1
ORDER BY 1
```

```sql ultimo_anio
SELECT * FROM ${anual} WHERE meses = 12 ORDER BY anio DESC LIMIT 1
```

```sql anio_2019
SELECT * FROM ${anual} WHERE anio = 2019
```

# 🔋 Elektrizitatearen biltegiratzea

Gero eta eguzki-energia eta energia eolikoa gehiago dagoenez, sistema elektrikoak eguzkia edo haizea dagoenean soberan dagoen energia gorde behar du, falta denean itzultzeko. Gaur egun Espainian, batez ere **ponpaketa-zentralek** egiten dute hori (ura goiko urtegi batera igotzen dute eta gero turbinatu egiten dute), eta **bateriak** iristen hasi dira.

<Grid cols=4>
    <KpiCard
        title="Instalatutako ponpaketa hutsa"
        value={potencia_ultima[0]?.bombeo_mw}
        formattedValue="{formatNumber(potencia_ultima[0]?.bombeo_mw, 0)} MW"
        period="ponpaketa mistoa kontuan hartu gabe · {potencia_ultima[0]?.mes_texto}"
        source="REE (ESIOS)"
    />
    <KpiCard
        title="Berriztagarrien ondoko bateriak"
        value={potencia_ultima[0]?.baterias_mw}
        formattedValue="{formatNumber(potencia_ultima[0]?.baterias_mw, 0)} MW"
        period="eguzki- edo eoliko-parkeekin hibridatuak · {potencia_ultima[0]?.mes_texto}"
        source="REE (ESIOS)"
        sparklineData={baterias_serie}
    />
    <KpiCard
        title="Ponpaketak itzulitako energia"
        value={ultimo_anio[0]?.bombeo_turbinado_gwh}
        formattedValue="{formatNumber(ultimo_anio[0]?.bombeo_turbinado_gwh / 1000, 1)} TWh"
        period="{ultimo_anio[0]?.anio}. urtean · 2019koa baino {formatNumber(ultimo_anio[0]?.bombeo_turbinado_gwh / anio_2019[0]?.bombeo_turbinado_gwh, 1)} aldiz gehiago"
        source="REE (balantzea)"
        sparklineData={anual.filter(d => Number(d.meses) === 12).map(d => ({valor: d.bombeo_turbinado_gwh / 1000}))}
    />
    <KpiCard
        title="Sarbide-baimena duen biltegiratzea"
        value={acceso_total[0]?.otorgada_mw}
        formattedValue="{formatNumber(acceso_total[0]?.otorgada_mw / 1000, 1)} GW"
        period="eta beste {formatNumber(acceso_total[0]?.en_tramitacion_mw / 1000, 1)} GW izapidetzen · PNIEC 2030 helburua: 22,5 GW"
        source="REE"
    />
</Grid>

## Zenbat energia biltegiratzen den

```sql anual_grafico
SELECT anio, 'Consumida para almacenar' AS flujo, bombeo_consumido_gwh + coalesce(baterias_cargado_gwh, 0) AS gwh FROM ${anual}
UNION ALL
SELECT anio, 'Devuelta a la red', bombeo_turbinado_gwh + coalesce(baterias_entregado_gwh, 0) FROM ${anual}
ORDER BY anio
```

<BarChart
    data={anual_grafico}
    x=anio
    y=gwh
    series=flujo
    type=grouped
    yFmt=num0
    xFmt="####"
    yAxisTitle="GWh"
    colorPalette={['#94a3b8', '#0f766e']}
    title="Ponpaketa eta bateriak: urtero kontsumitutako eta itzulitako energia"
/>

<p class="text-xs text-gray-500">Azken urtea osatu gabe dago. Biltegiratzea kontsumitzaile garbia da: ura ponpatzeko erabiltzen diren 100 kWh bakoitzeko {formatNumber(100 * ultimo_anio[0]?.rendimiento, 0)} inguru berreskuratzen dira (urtea: {ultimo_anio[0]?.anio}). Merezi du, elektrizitatea soberan eta merke dagoenean ponpatzen delako (eguerdian, eguzki-energiarekin) eta urria eta garestia denean turbinatzen delako. Turbinatutako energia bikoiztu baino gehiago egin da 2021etik (2,6 TWh-tik 5,9 TWh-ra 2025ean): gero eta ordu gehiago daude aprobetxatzeko moduko eguzki-soberakinarekin.</p>

```sql mensual
SELECT mes, bombeo_turbinado_gwh, bombeo_consumido_gwh
FROM mother.almacenamiento_mensual
ORDER BY mes
```

<LineChart
    data={mensual}
    x=mes
    y={['bombeo_consumido_gwh', 'bombeo_turbinado_gwh']}
    yFmt=num0
    xFmt="mmm yyyy"
    seriesLabels={{bombeo_consumido_gwh: 'Ponpatzeko kontsumoa', bombeo_turbinado_gwh: 'Turbinazioa'}}
    colorPalette={['#94a3b8', '#0f766e']}
    legend=true
    yAxisTitle="GWh hilean"
    title="Ponpaketa hilabetez hilabete"
/>

## Bateriak

```sql baterias_mensual
SELECT mes, baterias_entregado_gwh * 1000 AS entregado_mwh, baterias_cargado_gwh * 1000 AS cargado_mwh
FROM mother.almacenamiento_mensual
WHERE baterias_entregado_gwh IS NOT NULL OR baterias_cargado_gwh IS NOT NULL
ORDER BY mes
```

```sql baterias_potencia
SELECT mes, sum(mw) AS mw
FROM mother.almacenamiento_potencia
WHERE tipo = 'baterias_hibridadas'
GROUP BY mes
ORDER BY mes
```

<Grid cols=2>
    <BarChart
        data={baterias_mensual}
        x=mes
        y={['cargado_mwh', 'entregado_mwh']}
        type=grouped
        yFmt=num0
        xFmt="mmm yyyy"
        seriesLabels={{cargado_mwh: 'Kargatua', entregado_mwh: 'Emana'}}
        colorPalette={['#94a3b8', '#7c3aed']}
        yAxisTitle="MWh"
        title="Baterien energia hilero"
    />
    <LineChart
        data={baterias_potencia}
        x=mes
        y=mw
        yFmt=num0
        xFmt="mmm yyyy"
        lineColor="#7c3aed"
        yAxisTitle="MW"
        title="Berriztagarriekin hibridatutako baterien potentzia"
    />
</Grid>

<p class="text-xs text-gray-500">Bateriak txikiak dira oraindik ponpaketaren aldean (2025ean 800 aldiz energia gutxiago mugitu zuten, gutxi gorabehera), baina instalatutako potentzia hazten ari da eta milaka megawatt daude sarerako sarbide-baimenarekin. REEk parke berriztagarriekin hibridatutako bateriak baino ez ditu argitaratzen bereizita; independenteek (sarera bakarrik konektatuak) eta etxebizitzetako eta enpresetako autokontsumokoek ez dute estatistika ofizial irekirik.</p>

```sql diario
SELECT fecha,
    bombeo_consumido_mwh / 1000 AS consumo_gwh,
    bombeo_turbinado_mwh / 1000 AS turbinado_gwh,
    bombeo_consumido_pico_mw, bombeo_turbinado_pico_mw
FROM mother.almacenamiento_diario
WHERE fecha >= (SELECT max(fecha) FROM mother.almacenamiento_diario) - INTERVAL 365 DAY
ORDER BY fecha
```

```sql picos
SELECT
    max(bombeo_consumido_pico_mw) AS max_consumo_mw,
    arg_max(strftime(fecha, '%d/%m/%Y'), bombeo_consumido_pico_mw) AS dia_max_consumo,
    max(bombeo_turbinado_pico_mw) AS max_turbinado_mw,
    arg_max(strftime(fecha, '%d/%m/%Y'), bombeo_turbinado_pico_mw) AS dia_max_turbinado
FROM mother.almacenamiento_diario
```

## Azken urtea, egunez egun

<LineChart
    data={diario}
    x=fecha
    y={['consumo_gwh', 'turbinado_gwh']}
    yFmt=num1
    seriesLabels={{consumo_gwh: 'Ponpatzeko kontsumoa', turbinado_gwh: 'Turbinazioa'}}
    colorPalette={['#94a3b8', '#0f766e']}
    legend=true
    yAxisTitle="GWh egunean"
/>

{#if picos.length > 0 && picos[0]?.max_consumo_mw}
<p class="text-xs text-gray-500">Eguneko datuak daudenetik (2024 amaieratik) izandako errekorrak: {formatNumber(picos[0].max_consumo_mw, 0)} MW aldi berean ponpatzen ({picos[0].dia_max_consumo}) eta {formatNumber(picos[0].max_turbinado_mw, 0)} MW turbinatzen ({picos[0].dia_max_turbinado}). Martxotik maiatzera, eguzki eta ur asko dagoenean, ponpatzen da gehien. ESIOSen denbora errealeko datuak (behin betiko balantzetik zertxobait alda daitezke).</p>
{/if}

## Non dagoen

```sql potencia_ccaa
SELECT
    p.cod_ccaa,
    p.comunidad,
    sum(p.mw) FILTER (WHERE p.tipo = 'bombeo_puro') AS bombeo_mw,
    sum(p.mw) FILTER (WHERE p.tipo = 'baterias_hibridadas') AS baterias_mw
FROM mother.almacenamiento_potencia p
WHERE p.mes = (SELECT max(mes) FROM mother.almacenamiento_potencia)
GROUP BY ALL
```

```sql acceso_ccaa
SELECT
    a.cod_ccaa,
    a.comunidad,
    a.otorgada_mw,
    a.en_tramitacion_mw,
    a.nudos,
    coalesce(p.bombeo_mw, 0) AS bombeo_mw,
    coalesce(p.baterias_mw, 0) AS baterias_mw
FROM mother.almacenamiento_acceso a
LEFT JOIN ${potencia_ccaa} p ON p.cod_ccaa = a.cod_ccaa
WHERE a.fecha_fichero = (SELECT max(fecha_fichero) FROM mother.almacenamiento_acceso)
  AND (a.otorgada_mw > 0 OR a.en_tramitacion_mw > 0 OR p.bombeo_mw > 0)
ORDER BY a.otorgada_mw DESC
```

```sql acceso_grafico
SELECT comunidad, 'Con permiso de acceso' AS estado, otorgada_mw / 1000 AS gw FROM ${acceso_ccaa}
UNION ALL
SELECT comunidad, 'En tramitación', en_tramitacion_mw / 1000 FROM ${acceso_ccaa}
```

<BarChart
    data={acceso_grafico}
    x=comunidad
    y=gw
    series=estado
    swapXY=true
    yFmt=num1
    colorPalette={['#0f766e', '#99f6e4']}
    title="Garraio-sarerako sarbidea duten biltegiratze-proiektuak (GW)"
/>

<DataTable data={acceso_ccaa} rows=all>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=bombeo_mw title="Instalatutako ponpaketa hutsa (MW)" fmt=num0 />
    <Column id=baterias_mw title="Bateria hibridatuak (MW)" fmt=num0 />
    <Column id=otorgada_mw title="Emandako sarbidea (MW)" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=en_tramitacion_mw title="Izapidetzen (MW)" fmt=num0 />
    <Column id=nudos title="Azpiestazioak" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Sarbide-baimenak ahalmena erreserbatzen du REEren garraio-sareko azpiestazio batean; ez du esan nahi proiektua eraikita dagoenik, ezta eraikiko denik ere. Ez ditu barne hartzen banaketa-sarera konektatutako proiektuak. Energia eta Klimaren Plan Nazional Integratuak (PNIEC 2023-2030) 22,5 GWko biltegiratzea aurreikusten du 2030erako.</p>

---

## Iturriak eta oharrak

- **[REE – Balantze elektrikoa (REData)](https://www.ree.es/es/datos/balance/balance-electrico)**: ponpaketaren turbinazioa eta kontsumoa, baterien emana eta karga, hilean behin 2015etik. Zifra ofiziala da.
- **[REE – ESIOS](https://www.esios.ree.es/)**: 2066/2065 (ponpaketa) eta 2198/2199 (bateriak) adierazleak denbora errealean, eta ponpaketa hutsaren (1476) eta bateria hibridatuen (2275) instalatutako potentzia erkidegoka.
- **[REE – Garraio-sarerako sarbide-ahalmena](https://www.ree.es/es/clientes/generador/acceso-conexion/conoce-la-capacidad-de-acceso)**: biltegiratzerako emandako eta izapidetzen dagoen ahalmena korapiloka; SpainFactsek hileko fitxategi bakoitzaren argazki bat gordetzen du.
- **[MITECO – PNIEC 2023-2030](https://www.miteco.gob.es/es/prensa/pniec.html)**: biltegiratze-helburua.
- Ponpaketa hutsaren potentziak ez ditu barne hartzen ponpaketa mistoko zentralak (ibai baten ekarpen naturalak ere jasotzen dituztenak), ESIOSek bereizten ez dituenak: ponpaketa-ahalmen osoa handiagoa da.

<LastRefreshed prefix="Datuak eguneratuta" />
