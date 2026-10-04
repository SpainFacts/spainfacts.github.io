---
i18n_origen: af0dd2e402bd
title: Almacenamento de electricidade
description: "Bombeo hidráulico e baterías en España: canta enerxía almacenan e devolven, potencia instalada por comunidade, rendemento e proxectos con permiso de acceso á rede fronte ao obxectivo de 22,5 GW do PNIEC para 2030."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql potencia_ultima
SELECT
    strftime(max(fecha), '%m/%Y') AS mes_texto,
    sum(mw) FILTER (WHERE tipo = 'bombeo_puro') AS bombeo_mw,
    sum(mw) FILTER (WHERE tipo = 'baterias_hibridadas') AS baterias_mw
FROM mother.almacenamiento_potencia
WHERE es_ultimo
```

```sql baterias_serie
SELECT fecha AS mes, sum(mw) AS valor
FROM mother.almacenamiento_potencia
WHERE tipo = 'baterias_hibridadas'
GROUP BY fecha
ORDER BY fecha ASC
```

```sql acceso_total
SELECT
    strftime(max(fecha), '%d/%m/%Y') AS fecha_texto,
    sum(otorgada_mw) AS otorgada_mw,
    sum(en_tramitacion_mw) AS en_tramitacion_mw
FROM mother.almacenamiento_acceso
WHERE es_ultimo
```

```sql anual
SELECT
    anio,
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

# 🔋 Almacenamento de electricidade

Con cada vez máis solar e eólica, o sistema eléctrico necesita gardar a enerxía que sobra cando fai sol ou vento para devolvela cando non. Hoxe en España iso fano sobre todo as **centrais de bombeo** (soben auga a un encoro superior e turbínana despois), e empezan a chegar as **baterías**.

<Grid cols=4>
    <KpiCard
        title="Bombeo puro instalado"
        value={potencia_ultima[0]?.bombeo_mw}
        formattedValue="{formatNumber(potencia_ultima[0]?.bombeo_mw, 0)} MW"
        period="sen contar o bombeo mixto · {potencia_ultima[0]?.mes_texto}"
        source="REE (ESIOS)"
    />
    <KpiCard
        title="Baterías xunto a renovables"
        value={potencia_ultima[0]?.baterias_mw}
        formattedValue="{formatNumber(potencia_ultima[0]?.baterias_mw, 0)} MW"
        period="hibridadas con parques solares ou eólicos · {potencia_ultima[0]?.mes_texto}"
        source="REE (ESIOS)"
        sparklineData={baterias_serie}
    />
    <KpiCard
        title="Enerxía devolta polo bombeo"
        value={ultimo_anio[0]?.bombeo_turbinado_gwh}
        formattedValue="{formatNumber(ultimo_anio[0]?.bombeo_turbinado_gwh / 1000, 1)} TWh"
        period="en {ultimo_anio[0]?.anio} · {formatNumber(ultimo_anio[0]?.bombeo_turbinado_gwh / anio_2019[0]?.bombeo_turbinado_gwh, 1)} veces a de 2019"
        source="REE (balance)"
        sparklineData={anual.filter(d => Number(d.meses) === 12).map(d => ({valor: d.bombeo_turbinado_gwh / 1000}))}
    />
    <KpiCard
        title="Almacenamento con permiso de acceso"
        value={acceso_total[0]?.otorgada_mw}
        formattedValue="{formatNumber(acceso_total[0]?.otorgada_mw / 1000, 1)} GW"
        period="e {formatNumber(acceso_total[0]?.en_tramitacion_mw / 1000, 1)} GW máis en tramitación · obxectivo PNIEC 2030: 22,5 GW"
        source="REE"
    />
</Grid>

## Canta enerxía se almacena

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
    title="Bombeo e baterías: enerxía consumida e devolta cada ano"
/>

<p class="text-xs text-gray-500">O último ano está incompleto. O almacenamento é un consumidor neto: por cada 100 kWh que se usan para bombear auga recupéranse uns {formatNumber(100 * ultimo_anio[0]?.rendimiento, 0)} ({ultimo_anio[0]?.anio}). Compensa porque se bombea cando a electricidade sobra e é barata (ao mediodía, coa solar) e se turbina cando escasea e é cara. A enerxía turbinada máis que se duplicou desde 2021 (de 2,6 a 5,9 TWh en 2025): hai cada vez máis horas de excedente solar que aproveitar.</p>

```sql mensual
SELECT fecha AS mes, bombeo_turbinado_gwh, bombeo_consumido_gwh
FROM mother.almacenamiento_mensual
ORDER BY fecha
```

<LineChart
    data={mensual}
    x=mes
    y={['bombeo_consumido_gwh', 'bombeo_turbinado_gwh']}
    yFmt=num0
    xFmt="mmm yyyy"
    seriesLabels={{bombeo_consumido_gwh: 'Consumo para bombear', bombeo_turbinado_gwh: 'Turbinación'}}
    colorPalette={['#94a3b8', '#0f766e']}
    legend=true
    yAxisTitle="GWh ao mes"
    title="Bombeo mes a mes"
/>

## Baterías

```sql baterias_mensual
SELECT fecha AS mes, baterias_entregado_gwh * 1000 AS entregado_mwh, baterias_cargado_gwh * 1000 AS cargado_mwh
FROM mother.almacenamiento_mensual
WHERE baterias_entregado_gwh IS NOT NULL OR baterias_cargado_gwh IS NOT NULL
ORDER BY fecha
```

```sql baterias_potencia
SELECT fecha AS mes, sum(mw) AS mw
FROM mother.almacenamiento_potencia
WHERE tipo = 'baterias_hibridadas'
GROUP BY fecha
ORDER BY fecha
```

<Grid cols=2>
    <BarChart
        data={baterias_mensual}
        x=mes
        y={['cargado_mwh', 'entregado_mwh']}
        type=grouped
        yFmt=num0
        xFmt="mmm yyyy"
        seriesLabels={{cargado_mwh: 'Cargado', entregado_mwh: 'Entregado'}}
        colorPalette={['#94a3b8', '#7c3aed']}
        yAxisTitle="MWh"
        title="Enerxía das baterías cada mes"
    />
    <LineChart
        data={baterias_potencia}
        x=mes
        y=mw
        yFmt=num0
        xFmt="mmm yyyy"
        lineColor="#7c3aed"
        yAxisTitle="MW"
        title="Potencia de baterías hibridadas con renovables"
    />
</Grid>

<p class="text-xs text-gray-500">As baterías aínda son pequenas fronte ao bombeo (en 2025 moveron unhas 800 veces menos enerxía), pero a potencia instalada medra e hai miles de megavatios con permiso de acceso á rede. REE só publica por separado as baterías hibridadas con parques renovables; as independentes (conectadas soas á rede) e as de autoconsumo en vivendas e empresas non teñen estatística oficial aberta.</p>

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

## O último ano, día a día

<LineChart
    data={diario}
    x=fecha
    y={['consumo_gwh', 'turbinado_gwh']}
    yFmt=num1
    seriesLabels={{consumo_gwh: 'Consumo para bombear', turbinado_gwh: 'Turbinación'}}
    colorPalette={['#94a3b8', '#0f766e']}
    legend=true
    yAxisTitle="GWh ao día"
/>

{#if picos.length > 0 && picos[0]?.max_consumo_mw}
<p class="text-xs text-gray-500">Récords desde que hai datos diarios (finais de 2024): {formatNumber(picos[0].max_consumo_mw, 0)} MW bombeando á vez ({picos[0].dia_max_consumo}) e {formatNumber(picos[0].max_turbinado_mw, 0)} MW turbinando ({picos[0].dia_max_turbinado}). De marzo a maio, con moita solar e auga, é cando máis se bombea. Datos de ESIOS en tempo real (poden diferir algo do balance definitivo).</p>
{/if}

## Onde está

```sql potencia_ccaa
SELECT
    p.cod_ccaa,
    p.ccaa,
    sum(p.mw) FILTER (WHERE p.tipo = 'bombeo_puro') AS bombeo_mw,
    sum(p.mw) FILTER (WHERE p.tipo = 'baterias_hibridadas') AS baterias_mw
FROM mother.almacenamiento_potencia p
WHERE p.es_ultimo
GROUP BY ALL
```

```sql acceso_ccaa
SELECT
    a.cod_ccaa,
    a.ccaa,
    a.otorgada_mw,
    a.en_tramitacion_mw,
    a.nudos,
    coalesce(p.bombeo_mw, 0) AS bombeo_mw,
    coalesce(p.baterias_mw, 0) AS baterias_mw
FROM mother.almacenamiento_acceso a
LEFT JOIN ${potencia_ccaa} p ON p.cod_ccaa = a.cod_ccaa
WHERE a.es_ultimo
  AND (a.otorgada_mw > 0 OR a.en_tramitacion_mw > 0 OR p.bombeo_mw > 0)
ORDER BY a.otorgada_mw DESC
```

```sql acceso_grafico
SELECT ccaa, 'Con permiso de acceso' AS estado, otorgada_mw / 1000 AS gw FROM ${acceso_ccaa}
UNION ALL
SELECT ccaa, 'En tramitación', en_tramitacion_mw / 1000 FROM ${acceso_ccaa}
```

<BarChart
    data={acceso_grafico}
    x=ccaa
    y=gw
    series=estado
    swapXY=true
    yFmt=num1
    colorPalette={['#0f766e', '#99f6e4']}
    title="Proxectos de almacenamento con acceso á rede de transporte (GW)"
/>

<DataTable data={acceso_ccaa} rows=all>
    <Column id=ccaa title="Comunidade" />
    <Column id=bombeo_mw title="Bombeo puro instalado (MW)" fmt=num0 />
    <Column id=baterias_mw title="Baterías hibridadas (MW)" fmt=num0 />
    <Column id=otorgada_mw title="Acceso concedido (MW)" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=en_tramitacion_mw title="En tramitación (MW)" fmt=num0 />
    <Column id=nudos title="Subestaciones" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">O permiso de acceso reserva capacidade nunha subestación da rede de transporte de REE; non significa que o proxecto estea construído nin que se vaia construír. Non inclúe os proxectos conectados á rede de distribución. O Plan Nacional Integrado de Enerxía e Clima (PNIEC 2023-2030) prevé 22,5 GW de almacenamento en 2030.</p>

---

## Fontes e notas

- **[REE – Balance eléctrico (REData)](https://www.ree.es/es/datos/balance/balance-electrico)**: turbinación e consumo de bombeo, entrega e carga de baterías, mensual desde 2015. É a cifra oficial.
- **[REE – ESIOS](https://www.esios.ree.es/)**: indicadores 2066/2065 (bombeo) e 2198/2199 (baterías) en tempo real, e potencia instalada de bombeo puro (1476) e de baterías hibridadas (2275) por comunidade.
- **[REE – Capacidade de acceso da rede de transporte](https://www.ree.es/es/clientes/generador/acceso-conexion/conoce-la-capacidad-de-acceso)**: capacidade concedida e en tramitación para almacenamento por nodo; SpainFacts garda unha foto de cada ficheiro mensual.
- **[MITECO – PNIEC 2023-2030](https://www.miteco.gob.es/es/prensa/pniec.html)**: obxectivo de almacenamento.
- A potencia de bombeo puro non inclúe as centrais de bombeo mixto (que tamén reciben achegas naturais dun río), que ESIOS non desagrega: a capacidade total de bombeo é maior.

<LastRefreshed prefix="Datos actualizados" />
