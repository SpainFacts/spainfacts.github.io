---
title: Emmagatzematge d'electricitat
description: "Bombament hidràulic i bateries a Espanya: quanta energia emmagatzemen i retornen, potència instal·lada per comunitat, rendiment i projectes amb permís d'accés a la xarxa davant l'objectiu de 22,5 GW del PNIEC per al 2030."
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

# 🔋 Emmagatzematge d'electricitat

Amb cada vegada més solar i eòlica, el sistema elèctric necessita guardar l'energia que sobra quan fa sol o vent per retornar-la quan no en fa. Avui a Espanya això ho fan sobretot les **centrals de bombament** (pugen aigua a un embassament superior i després la turbinen), i comencen a arribar les **bateries**.

<Grid cols=4>
    <KpiCard
        title="Bombament pur instal·lat"
        value={potencia_ultima[0]?.bombeo_mw}
        formattedValue="{formatNumber(potencia_ultima[0]?.bombeo_mw, 0)} MW"
        period="sense comptar el bombament mixt · {potencia_ultima[0]?.mes_texto}"
        source="REE (ESIOS)"
    />
    <KpiCard
        title="Bateries al costat de renovables"
        value={potencia_ultima[0]?.baterias_mw}
        formattedValue="{formatNumber(potencia_ultima[0]?.baterias_mw, 0)} MW"
        period="hibridades amb parcs solars o eòlics · {potencia_ultima[0]?.mes_texto}"
        source="REE (ESIOS)"
        sparklineData={baterias_serie}
    />
    <KpiCard
        title="Energia retornada pel bombament"
        value={ultimo_anio[0]?.bombeo_turbinado_gwh}
        formattedValue="{formatNumber(ultimo_anio[0]?.bombeo_turbinado_gwh / 1000, 1)} TWh"
        period="el {ultimo_anio[0]?.anio} · {formatNumber(ultimo_anio[0]?.bombeo_turbinado_gwh / anio_2019[0]?.bombeo_turbinado_gwh, 1)} vegades la del 2019"
        source="REE (balanç)"
        sparklineData={anual.filter(d => Number(d.meses) === 12).map(d => ({valor: d.bombeo_turbinado_gwh / 1000}))}
    />
    <KpiCard
        title="Emmagatzematge amb permís d'accés"
        value={acceso_total[0]?.otorgada_mw}
        formattedValue="{formatNumber(acceso_total[0]?.otorgada_mw / 1000, 1)} GW"
        period="i {formatNumber(acceso_total[0]?.en_tramitacion_mw / 1000, 1)} GW més en tramitació · objectiu PNIEC 2030: 22,5 GW"
        source="REE"
    />
</Grid>

## Quanta energia s'emmagatzema

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
    title="Bombament i bateries: energia consumida i retornada cada any"
/>

<p class="text-xs text-gray-500">L'últim any és incomplet. L'emmagatzematge és un consumidor net: per cada 100 kWh que es fan servir per bombar aigua se'n recuperen uns {formatNumber(100 * ultimo_anio[0]?.rendimiento, 0)} ({ultimo_anio[0]?.anio}). Surt a compte perquè es bomba quan l'electricitat sobra i és barata (al migdia, amb la solar) i es turbina quan escasseja i és cara. L'energia turbinada s'ha més que duplicat des del 2021 (de 2,6 a 5,9 TWh el 2025): hi ha cada vegada més hores d'excedent solar per aprofitar.</p>

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
    seriesLabels={{bombeo_consumido_gwh: 'Consum per bombar', bombeo_turbinado_gwh: 'Turbinació'}}
    colorPalette={['#94a3b8', '#0f766e']}
    legend=true
    yAxisTitle="GWh al mes"
    title="Bombament mes a mes"
/>

## Bateries

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
        seriesLabels={{cargado_mwh: 'Carregat', entregado_mwh: 'Lliurat'}}
        colorPalette={['#94a3b8', '#7c3aed']}
        yAxisTitle="MWh"
        title="Energia de les bateries cada mes"
    />
    <LineChart
        data={baterias_potencia}
        x=mes
        y=mw
        yFmt=num0
        xFmt="mmm yyyy"
        lineColor="#7c3aed"
        yAxisTitle="MW"
        title="Potència de bateries hibridades amb renovables"
    />
</Grid>

<p class="text-xs text-gray-500">Les bateries encara són petites davant del bombament (el 2025 van moure unes 800 vegades menys energia), però la potència instal·lada creix i hi ha milers de megawatts amb permís d'accés a la xarxa. REE només publica per separat les bateries hibridades amb parcs renovables; les independents (connectades soles a la xarxa) i les d'autoconsum en habitatges i empreses no tenen estadística oficial oberta.</p>

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

## L'últim any, dia a dia

<LineChart
    data={diario}
    x=fecha
    y={['consumo_gwh', 'turbinado_gwh']}
    yFmt=num1
    seriesLabels={{consumo_gwh: 'Consum per bombar', turbinado_gwh: 'Turbinació'}}
    colorPalette={['#94a3b8', '#0f766e']}
    legend=true
    yAxisTitle="GWh al dia"
/>

{#if picos.length > 0 && picos[0]?.max_consumo_mw}
<p class="text-xs text-gray-500">Rècords des que hi ha dades diàries (finals del 2024): {formatNumber(picos[0].max_consumo_mw, 0)} MW bombant alhora ({picos[0].dia_max_consumo}) i {formatNumber(picos[0].max_turbinado_mw, 0)} MW turbinant ({picos[0].dia_max_turbinado}). De març a maig, amb molta solar i aigua, és quan més es bomba. Dades d'ESIOS en temps real (poden diferir una mica del balanç definitiu).</p>
{/if}

## On és

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
    title="Projectes d'emmagatzematge amb accés a la xarxa de transport (GW)"
/>

<DataTable data={acceso_ccaa} rows=all>
    <Column id=comunidad title="Comunitat" />
    <Column id=bombeo_mw title="Bombament pur instal·lat (MW)" fmt=num0 />
    <Column id=baterias_mw title="Bateries hibridades (MW)" fmt=num0 />
    <Column id=otorgada_mw title="Accés concedit (MW)" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=en_tramitacion_mw title="En tramitació (MW)" fmt=num0 />
    <Column id=nudos title="Subestacions" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">El permís d'accés reserva capacitat en una subestació de la xarxa de transport de REE; no vol dir que el projecte estigui construït ni que s'hagi de construir. No inclou els projectes connectats a la xarxa de distribució. El Pla Nacional Integrat d'Energia i Clima (PNIEC 2023-2030) preveu 22,5 GW d'emmagatzematge el 2030.</p>

---

## Fonts i notes

- **[REE – Balanç elèctric (REData)](https://www.ree.es/es/datos/balance/balance-electrico)**: turbinació i consum de bombament, lliurament i càrrega de bateries, mensual des del 2015. És la xifra oficial.
- **[REE – ESIOS](https://www.esios.ree.es/)**: indicadors 2066/2065 (bombament) i 2198/2199 (bateries) en temps real, i potència instal·lada de bombament pur (1476) i de bateries hibridades (2275) per comunitat.
- **[REE – Capacitat d'accés de la xarxa de transport](https://www.ree.es/es/clientes/generador/acceso-conexion/conoce-la-capacidad-de-acceso)**: capacitat concedida i en tramitació per a emmagatzematge per nus; SpainFacts guarda una foto de cada fitxer mensual.
- **[MITECO – PNIEC 2023-2030](https://www.miteco.gob.es/es/prensa/pniec.html)**: objectiu d'emmagatzematge.
- La potència de bombament pur no inclou les centrals de bombament mixt (que també reben aportacions naturals d'un riu), que ESIOS no desglossa: la capacitat total de bombament és més gran.

<LastRefreshed prefix="Dades actualitzades" />
