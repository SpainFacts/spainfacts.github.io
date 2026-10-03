---
title: Turisme
description: "Turistes internacionals per habitant, la seva despesa descomptada la inflació i en % del PIB, pernoctacions i ocupació hotelera per comunitat, països d'origen, estacionalitat i habitatges turístics per municipi, amb dades de l'INE."
i18n_origen: 6bfff987dc63
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';

    // Noms dels mesos en català (les consultes els construeixen en castellà)
    const mesosCa = ['gener', 'febrer', 'març', 'abril', 'maig', 'juny', 'juliol', 'agost', 'setembre', 'octubre', 'novembre', 'desembre'];
    const mesCa = (d) => {
        if (!d) return '';
        const f = new Date(d);
        return mesosCa[f.getUTCMonth()] + ' del ' + f.getUTCFullYear();
    };
    const abrevCa = { ene: 'gener', feb: 'febrer', mar: 'març', abr: 'abril', may: 'maig', jun: 'juny', jul: 'juliol', ago: 'agost', sep: 'setembre', oct: 'octubre', nov: 'novembre', dic: 'desembre' };
    const mesNombreCa = (m) => abrevCa[m] ?? m ?? '';
    // «al maig», «a l'abril»
    const alMes = (nom) => !nom ? '' : (/^[aeiou]/.test(nom) ? "a l'" : 'al ') + nom;
    const alMesAny = (d) => alMes(mesCa(d));
    const majuscula = (t) => t ? t.charAt(0).toUpperCase() + t.slice(1) : '';
</script>

```sql mensual
SELECT
    *,
    ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'][CAST(mes_num AS INTEGER)] || ' de ' || CAST(anio AS INTEGER) AS mes_txt,
    100 * (turistas_12m / lag(turistas_12m, 12) OVER (ORDER BY mes) - 1) AS turistas_12m_var,
    100 * (gasto_medio_persona_real_12m / lag(gasto_medio_persona_real_12m, 12) OVER (ORDER BY mes) - 1) AS gasto_persona_12m_var,
    gasto_pct_pib_12m - lag(gasto_pct_pib_12m, 12) OVER (ORDER BY mes) AS pct_pib_12m_var,
    100 * (pernoct_hotel_1000hab_12m / lag(pernoct_hotel_1000hab_12m, 12) OVER (ORDER BY mes) - 1) AS pernoct_12m_var
FROM mother.turismo_mensual
ORDER BY mes
```

```sql kpi_turistas
SELECT * FROM ${mensual} WHERE turistas_12m IS NOT NULL ORDER BY mes
```

```sql kpi_pib
SELECT * FROM ${mensual} WHERE gasto_pct_pib_12m IS NOT NULL ORDER BY mes
```

```sql kpi_hotel
SELECT * FROM ${mensual} WHERE pernoct_hotel_1000hab_12m IS NOT NULL ORDER BY mes
```

```sql anual
SELECT * FROM mother.turismo_anual ORDER BY anio
```

```sql anual_completo
SELECT * FROM mother.turismo_anual WHERE meses_frontur = 12 ORDER BY anio
```

```sql hitos
WITH a AS (SELECT * FROM mother.turismo_anual WHERE meses_frontur = 12),
ult AS (SELECT * FROM a ORDER BY anio DESC LIMIT 1),
a19 AS (SELECT * FROM a WHERE anio = 2019),
a20 AS (SELECT * FROM a WHERE anio = 2020)
SELECT
    CAST((SELECT anio FROM ult) AS INTEGER) AS anio_ult,
    (SELECT turistas FROM a19) AS t2019,
    (SELECT turistas FROM a20) AS t2020,
    (SELECT turistas FROM ult) AS t_ult,
    (SELECT turistas_por_hab FROM a19) AS tph2019,
    (SELECT turistas_por_hab FROM a20) AS tph2020,
    (SELECT turistas_por_hab FROM ult) AS tph_ult,
    100 * ((SELECT turistas FROM a20) / (SELECT turistas FROM a19) - 1) AS caida_turistas,
    100 * ((SELECT gasto_real_meur FROM a20) / (SELECT gasto_real_meur FROM a19) - 1) AS caida_gasto,
    100 * ((SELECT pernoct_hotel FROM a20) / (SELECT pernoct_hotel FROM a19) - 1) AS caida_hotel,
    (SELECT gasto_pct_pib FROM a19) AS pib2019,
    (SELECT gasto_pct_pib FROM a20) AS pib2020,
    (SELECT gasto_pct_pib FROM ult) AS pib_ult,
    (SELECT count(*) FROM mother.turismo_mensual WHERE anio = 2020 AND turistas = 0) AS meses_cero,
    CAST((SELECT min(anio) FROM a WHERE anio > 2020 AND turistas >= (SELECT turistas FROM a19)) AS INTEGER) AS anio_recupera,
    100 * ((SELECT turistas FROM ult) / (SELECT turistas FROM a19) - 1) AS var_turistas_2019,
    100 * ((SELECT turistas_por_hab FROM ult) / (SELECT turistas_por_hab FROM a19) - 1) AS var_tph_2019,
    100 * ((SELECT gasto_real_meur FROM ult) / (SELECT gasto_real_meur FROM a19) - 1) AS var_gasto_2019,
    100 * ((SELECT gasto_medio_persona_real FROM ult) / (SELECT gasto_medio_persona_real FROM a19) - 1) AS var_gasto_persona_2019,
    (SELECT gasto_medio_persona_real FROM a19) AS gmp2019,
    (SELECT gasto_medio_persona_real FROM ult) AS gmp_ult,
    (SELECT gasto_medio_diario_real FROM a19) AS gmd2019,
    (SELECT gasto_medio_diario_real FROM ult) AS gmd_ult,
    (SELECT duracion_media FROM a19) AS dur2019,
    (SELECT duracion_media FROM ult) AS dur_ult,
    (SELECT gasto_real_por_hab FROM ult) AS gph_ult,
    CAST((SELECT anio_base FROM ult) AS INTEGER) AS anio_base
```

```sql evol_mensual
SELECT mes, turistas_1000hab, turistas
FROM mother.turismo_mensual
WHERE turistas IS NOT NULL
ORDER BY mes
```

```sql gasto_persona
SELECT anio, 'Gasto por turista y viaje' AS serie, gasto_medio_persona_real AS euros FROM ${anual_completo}
ORDER BY anio
```

```sql gasto_dia
SELECT anio, gasto_medio_diario_real AS euros, duracion_media FROM ${anual_completo} ORDER BY anio
```

```sql hotel_anual
SELECT anio, 'Hoteles' AS alojamiento, pernoct_hotel_1000hab AS por_1000 FROM mother.turismo_anual WHERE meses_hotel = 12
UNION ALL
SELECT anio, 'Apartamentos turísticos', pernoct_apart_1000hab FROM mother.turismo_anual WHERE meses_apart = 12
ORDER BY anio
```

```sql ocupacion_anual
SELECT anio, 'Hoteles' AS alojamiento, ocupacion_hotel AS ocupacion FROM mother.turismo_anual WHERE meses_hotel = 12
UNION ALL
SELECT anio, 'Apartamentos turísticos', ocupacion_apart FROM mother.turismo_anual WHERE meses_apart = 12
ORDER BY anio
```

```sql estacional
SELECT
    m.mes_num,
    ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'][CAST(m.mes_num AS INTEGER)] AS mes_nombre,
    CAST(m.anio AS VARCHAR) AS anio_txt,
    m.turistas_1000hab,
    1000.0 * m.pernoct_hotel_residentes / m.poblacion AS residentes_1000,
    1000.0 * m.pernoct_hotel_extranjeros / m.poblacion AS extranjeros_1000,
    m.ocupacion_hotel
FROM mother.turismo_mensual m
WHERE m.anio IN (2019, (SELECT max(anio) FROM mother.turismo_anual WHERE meses_frontur = 12))
ORDER BY m.anio, m.mes_num
```

```sql estacional_ult
SELECT * FROM ${estacional} WHERE anio_txt = (SELECT max(anio_txt) FROM ${estacional}) ORDER BY mes_num
```

```sql estacional_hotel
SELECT mes_num, mes_nombre, 'Residentes en España' AS residencia, residentes_1000 AS por_1000 FROM ${estacional_ult}
UNION ALL
SELECT mes_num, mes_nombre, 'Residentes en el extranjero', extranjeros_1000 FROM ${estacional_ult}
ORDER BY mes_num
```

```sql estacional_resumen
SELECT
    arg_max(mes_nombre, turistas_1000hab) AS mes_max,
    arg_min(mes_nombre, turistas_1000hab) AS mes_min,
    max(turistas_1000hab) / min(turistas_1000hab) AS ratio,
    max(ocupacion_hotel) AS ocup_max,
    arg_max(mes_nombre, ocupacion_hotel) AS mes_ocup_max,
    min(ocupacion_hotel) AS ocup_min,
    arg_min(mes_nombre, ocupacion_hotel) AS mes_ocup_min,
    max(anio_txt) AS anio
FROM ${estacional_ult}
```

```sql paises
SELECT *, CAST(anio AS INTEGER) AS anio_int
FROM mother.turismo_paises
WHERE pais <> 'Total' AND anio = (SELECT max(anio) FROM mother.turismo_paises WHERE meses = 12)
ORDER BY turistas DESC
```

```sql paises_gasto
SELECT pais, gasto_medio_persona_real FROM ${paises} WHERE gasto_medio_persona_real IS NOT NULL ORDER BY gasto_medio_persona_real DESC
```

```sql paises_evol
SELECT anio, pais, cuota
FROM mother.turismo_paises
WHERE meses = 12 AND pais IN ('Reino Unido', 'Francia', 'Alemania', 'Italia', 'Países Nórdicos', 'Estados Unidos de América', 'Países Bajos')
ORDER BY anio
```

```sql ccaa
SELECT * REPLACE ('/ca' || ruta AS ruta)
FROM mother.turismo_ccaa
WHERE cod_ccaa NOT IN ('00', 'otras') AND anio = (SELECT max(anio) FROM mother.turismo_ccaa WHERE meses_hotel = 12)
ORDER BY pernoct_1000hab DESC
```

```sql ccaa_espana
SELECT * FROM mother.turismo_ccaa
WHERE cod_ccaa = '00' AND anio = (SELECT max(anio) FROM mother.turismo_ccaa WHERE meses_hotel = 12)
```

```sql ccaa_frontur
SELECT comunidad, turistas_por_hab, gasto_real_por_hab, gasto_medio_persona_real, turistas, CAST(anio AS INTEGER) AS anio
FROM mother.turismo_ccaa
WHERE turistas IS NOT NULL AND cod_ccaa <> '00' AND meses_frontur = 12
  AND anio = (SELECT max(anio) FROM mother.turismo_ccaa WHERE meses_frontur = 12)
ORDER BY turistas_por_hab DESC
```

```sql vut_espana
SELECT *, ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'][CAST(month(periodo) AS INTEGER)] || ' de ' || CAST(anio AS INTEGER) AS periodo_txt
FROM mother.turismo_viviendas
WHERE nivel = 'pais'
ORDER BY periodo
```

```sql vut_ccaa
SELECT cod, nombre, '/ca' || ruta AS ruta, viviendas, pct_viviendas / 100 AS pct, viviendas_1000hab
FROM mother.turismo_viviendas
WHERE nivel = 'ccaa' AND periodo = (SELECT max(periodo) FROM mother.turismo_viviendas)
ORDER BY pct_viviendas DESC
```

```sql vut_prov
SELECT nombre, ruta, viviendas, pct_viviendas / 100 AS pct, viviendas_1000hab
FROM mother.turismo_viviendas
WHERE nivel = 'provincia' AND periodo = (SELECT max(periodo) FROM mother.turismo_viviendas)
ORDER BY pct_viviendas DESC
LIMIT 15
```

```sql vut_mun
SELECT v.municipio, p.nombre AS provincia, v.poblacion, v.viviendas, v.pct_viviendas / 100 AS pct, v.viviendas_1000hab, v.puesto
FROM mother.turismo_viviendas_municipios v
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = v.cod_prov
WHERE v.periodo = (SELECT max(periodo) FROM mother.turismo_viviendas_municipios)
  AND v.poblacion >= 1000
ORDER BY v.pct_viviendas DESC
LIMIT 25
```

```sql vut_grandes
SELECT v.municipio, v.poblacion, v.viviendas, v.pct_viviendas / 100 AS pct, v.viviendas_1000hab
FROM mother.turismo_viviendas_municipios v
WHERE v.periodo = (SELECT max(periodo) FROM mother.turismo_viviendas_municipios)
  AND v.poblacion >= 500000
ORDER BY v.pct_viviendas DESC
```

# 🏖️ Turisme

Quants turistes estrangers arriben a Espanya en proporció a la seva població, quant gasten descomptada la inflació, quin pes té aquesta despesa en l'economia, on dormen i quants habitatges s'anuncien com a allotjament turístic.

<Grid cols=4>
    <KpiCard
        title="Turistes internacionals"
        value={kpi_turistas.slice(-1)[0]?.turistas_por_hab_12m}
        formattedValue="{formatNumber(kpi_turistas.slice(-1)[0]?.turistas_por_hab_12m, 2)} per habitant"
        period="{formatCompact(kpi_turistas.slice(-1)[0]?.turistas_12m, 3)} turistes en els 12 mesos fins {alMesAny(kpi_turistas.slice(-1)[0]?.mes)}"
        change={kpi_turistas.slice(-1)[0]?.turistas_12m_var?.toFixed(1)}
        changePeriod="respecte als 12 mesos anteriors"
        direction="neutral"
        source="INE / FRONTUR"
        sparklineData={kpi_turistas.map(d => ({x: d.mes, y: d.turistas_por_hab_12m}))}
    />
    <KpiCard
        title="Despesa per turista"
        value={kpi_turistas.slice(-1)[0]?.gasto_medio_persona_real_12m}
        formattedValue="{formatNumber(kpi_turistas.slice(-1)[0]?.gasto_medio_persona_real_12m, 0)} €"
        period="per viatge, en euros del {kpi_turistas.slice(-1)[0]?.anio_base}, 12 mesos fins {alMesAny(kpi_turistas.slice(-1)[0]?.mes)}"
        change={kpi_turistas.slice(-1)[0]?.gasto_persona_12m_var?.toFixed(1)}
        changePeriod="real respecte als 12 mesos anteriors"
        direction="positive-up"
        source="INE / EGATUR"
        sparklineData={kpi_turistas.map(d => ({x: d.mes, y: d.gasto_medio_persona_real_12m}))}
    />
    <KpiCard
        title="Despesa dels turistes"
        value={kpi_pib.slice(-1)[0]?.gasto_pct_pib_12m}
        formattedValue="{formatNumber(kpi_pib.slice(-1)[0]?.gasto_pct_pib_12m, 1)} % del PIB"
        period="{formatNumber(kpi_pib.slice(-1)[0]?.gasto_real_por_hab_12m, 0)} € per habitant en els 12 mesos fins {alMesAny(kpi_pib.slice(-1)[0]?.mes)}"
        change={kpi_pib.slice(-1)[0]?.pct_pib_12m_var?.toFixed(1)}
        changeUnit="pp"
        changePeriod="respecte a un any abans"
        direction="neutral"
        source="INE / EGATUR, Eurostat"
        sparklineData={kpi_pib.map(d => ({x: d.mes, y: d.gasto_pct_pib_12m}))}
    />
    <KpiCard
        title="Nits d'hotel"
        value={kpi_hotel.slice(-1)[0]?.pernoct_hotel_1000hab_12m}
        formattedValue="{formatNumber(kpi_hotel.slice(-1)[0]?.pernoct_hotel_1000hab_12m, 0)} per 1.000 hab."
        period="{formatCompact(kpi_hotel.slice(-1)[0]?.pernoct_hotel_12m, 3)} pernoctacions en els 12 mesos fins {alMesAny(kpi_hotel.slice(-1)[0]?.mes)}"
        change={kpi_hotel.slice(-1)[0]?.pernoct_12m_var?.toFixed(1)}
        changePeriod="respecte als 12 mesos anteriors"
        direction="neutral"
        source="INE / EOH"
        sparklineData={kpi_hotel.slice(-120).map(d => ({x: d.mes, y: d.pernoct_hotel_1000hab_12m}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('turistas_por_habitante')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'turistas_por_habitante')} />


<p class="text-xs text-gray-500">Turistes: visitants no residents que passen almenys una nit a Espanya (FRONTUR). La despesa (EGATUR) inclou el transport internacional, l'allotjament, el menjar i la resta de compres del viatge, i es dona en euros constants del {hitos[0]?.anio_base}. El percentatge del PIB compara aquesta despesa amb el PIB nominal: és una referència de mida, no l'aportació del turisme al PIB, perquè part de la despesa es paga a empreses de fora d'Espanya (bitllets d'avió, paquets). Els totals absoluts apareixen només com a referència en el text petit.</p>

## Evolució: de l'enfonsament del 2020 al rècord

El 2019 van arribar {formatNumber(hitos[0]?.tph2019, 2)} turistes internacionals per habitant. El 2020 la xifra va caure un {formatNumber(-hitos[0]?.caida_turistas, 0)} %, fins a {formatNumber(hitos[0]?.tph2020, 2)} per habitant, amb {hitos[0]?.meses_cero} mesos (abril i maig) sense cap arribada registrada; la despesa real es va enfonsar un {formatNumber(-hitos[0]?.caida_gasto, 0)} % i les nits d'hotel, un {formatNumber(-hitos[0]?.caida_hotel, 0)} %. {#if hitos[0]?.anio_recupera}El nombre de turistes va tornar a superar el del 2019 el {hitos[0]?.anio_recupera}{/if} i el {hitos[0]?.anio_ult} va ser un {formatNumber(hitos[0]?.var_turistas_2019, 1)} % més alt que abans de la pandèmia ({formatNumber(hitos[0]?.tph_ult, 2)} per habitant, un {formatNumber(hitos[0]?.var_tph_2019, 1)} % més, perquè la població també ha crescut). Descomptada la inflació, la seva despesa va ser un {formatNumber(hitos[0]?.var_gasto_2019, 1)} % superior a la del 2019.

<BarChart
    data={anual_completo}
    x=anio
    y=turistas_por_hab
    xFmt='0'
    yFmt='0.00'
    fillColor="#0f766e"
    yAxisTitle="Turistes per habitant"
    title="Turistes internacionals per habitant i any"
/>

<LineChart
    data={evol_mensual}
    x=mes
    y=turistas_1000hab
    yFmt='#,##0'
    lineColor="#0f766e"
    yAxisTitle="Per 1.000 habitants"
    title="Turistes internacionals arribats cada mes, per 1.000 habitants"
/>

<p class="text-xs text-gray-500">FRONTUR comença l'octubre del 2015. L'abril i el maig del 2020 l'INE va registrar zero turistes pel tancament de fronteres.</p>

## Quant gasten

El {hitos[0]?.anio_ult} cada turista va gastar de mitjana {formatNumber(hitos[0]?.gmp_ult, 0)} € per viatge (euros del {hitos[0]?.anio_base}), davant de {formatNumber(hitos[0]?.gmp2019, 0)} € el 2019, i {formatNumber(hitos[0]?.gmd_ult, 0)} € per dia, davant de {formatNumber(hitos[0]?.gmd2019, 0)} €. L'estada mitjana va passar de {formatNumber(hitos[0]?.dur2019, 1)} a {formatNumber(hitos[0]?.dur_ult, 1)} dies. En conjunt, la despesa dels turistes estrangers va equivaler al {formatNumber(hitos[0]?.pib_ult, 1)} % del PIB ({formatNumber(hitos[0]?.pib2019, 1)} % el 2019 i {formatNumber(hitos[0]?.pib2020, 1)} % el 2020), uns {formatNumber(hitos[0]?.gph_ult, 0)} € per habitant.

<Grid cols=2>
<LineChart
    data={gasto_dia}
    x=anio
    y=euros
    xFmt='0'
    yFmt='#,##0" €"'
    lineColor="#b45309"
    startingAtZero={false}
    yAxisTitle="€ per dia (reals)"
    title="Despesa mitjana diària per turista, euros del {hitos[0]?.anio_base}"
/>
<BarChart
    data={anual_completo}
    x=anio
    y=gasto_pct_pib
    xFmt='0'
    yFmt='0.0"%"'
    fillColor="#b45309"
    yAxisTitle="% del PIB"
    title="Despesa dels turistes internacionals en % del PIB"
/>
</Grid>

<LineChart
    data={gasto_persona}
    x=anio
    y=euros
    xFmt='0'
    yFmt='#,##0" €"'
    lineColor="#b45309"
    startingAtZero={false}
    yAxisTitle="€ per viatge (reals)"
    title="Despesa mitjana per turista i viatge, euros del {hitos[0]?.anio_base}"
/>

## Hotels i apartaments

Pernoctacions de viatgers residents i no residents per cada 1.000 habitants. La sèrie hotelera comença el 1999 i permet veure la crisi del 2009 i l'enfonsament del 2020.

<LineChart
    data={hotel_anual}
    x=anio
    y=por_1000
    series=alojamiento
    xFmt='0'
    yFmt='#,##0'
    colorPalette={['#1d4ed8', '#60a5fa']}
    yAxisTitle="Pernoctacions per 1.000 hab."
    title="Pernoctacions l'any per 1.000 habitants"
/>

<LineChart
    data={ocupacion_anual}
    x=anio
    y=ocupacion
    series=alojamiento
    xFmt='0'
    yFmt='0.0"%"'
    colorPalette={['#1d4ed8', '#60a5fa']}
    yAxisTitle="% de places ocupades"
    title="Grau d'ocupació per places (mitjana anual ponderada)"
/>

<p class="text-xs text-gray-500">El {anual.filter(d => d.meses_hotel === 12).slice(-1)[0]?.anio} el {formatNumber(anual.filter(d => d.meses_hotel === 12).slice(-1)[0]?.pct_extranjeros_hotel, 1)} % de les nits d'hotel van ser de residents a l'estranger. Grau d'ocupació: pernoctacions dividides entre places disponibles per dies del mes. Les enquestes d'ocupació no cobreixen els habitatges turístics.</p>

## Estacionalitat

Turistes internacionals arribats cada mes per 1.000 habitants, el {estacional_resumen[0]?.anio} davant del 2019. El {estacional_resumen[0]?.anio} el mes amb més arribades ({mesNombreCa(estacional_resumen[0]?.mes_max)}) va rebre {formatNumber(estacional_resumen[0]?.ratio, 1)} vegades més turistes que el que en va tenir menys ({mesNombreCa(estacional_resumen[0]?.mes_min)}). L'ocupació hotelera va ser del {formatNumber(estacional_resumen[0]?.ocup_max, 0)} % {alMes(mesNombreCa(estacional_resumen[0]?.mes_ocup_max))} i del {formatNumber(estacional_resumen[0]?.ocup_min, 0)} % {alMes(mesNombreCa(estacional_resumen[0]?.mes_ocup_min))}.

<BarChart
    data={estacional}
    x=mes_nombre
    y=turistas_1000hab
    series=anio_txt
    type=grouped
    sort=false
    yFmt='#,##0'
    colorPalette={['#94a3b8', '#0f766e']}
    yAxisTitle="Per 1.000 habitants"
    title="Turistes internacionals per mes, per 1.000 habitants"
/>

<BarChart
    data={estacional_hotel}
    x=mes_nombre
    y=por_1000
    series=residencia
    type=stacked
    sort=false
    yFmt='#,##0'
    colorPalette={['#60a5fa', '#1d4ed8']}
    yAxisTitle="Pernoctacions per 1.000 hab."
    title="Nits d'hotel per mes i residència del viatger el {estacional_resumen[0]?.anio}, per 1.000 habitants"
/>

## D'on vénen

Repartiment dels turistes del {paises[0]?.anio_int} per país de residència i variació respecte al 2019.

<Grid cols=2>
<BarChart
    data={paises}
    x=pais
    y=cuota
    swapXY=true
    yFmt='0.0"%"'
    fillColor="#0f766e"
    title="% dels turistes internacionals el {paises[0]?.anio_int}"
/>
<BarChart
    data={paises}
    x=pais
    y=var_2019
    swapXY=true
    yFmt='0.0"%"'
    fillColor="#94a3b8"
    title="Variació del nombre de turistes respecte al 2019"
/>
</Grid>

<BarChart
    data={paises_gasto}
    x=pais
    y=gasto_medio_persona_real
    swapXY=true
    yFmt='#,##0" €"'
    fillColor="#b45309"
    title="Despesa mitjana per turista i viatge el {paises[0]?.anio_int} (euros del {hitos[0]?.anio_base})"
/>

<p class="text-xs text-gray-500">EGATUR només desglossa la despesa del Regne Unit, França, Alemanya, Itàlia i els països nòrdics. "Resta d'Europa", "Resta d'Amèrica" i "Resta del món" són agrupacions de l'INE.</p>

<LineChart
    data={paises_evol}
    x=anio
    y=cuota
    series=pais
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% dels turistes"
    title="Pes dels principals mercats"
/>

## Per comunitat

Pernoctacions en hotels i apartaments turístics per 1.000 habitants el {ccaa[0]?.anio}. En el conjunt d'Espanya van ser {formatNumber(ccaa_espana[0]?.pernoct_1000hab, 0)}; {ccaa[0]?.comunidad} va arribar a {formatNumber(ccaa[0]?.pernoct_1000hab, 0)} i {ccaa.slice(-1)[0]?.comunidad} es va quedar en {formatNumber(ccaa.slice(-1)[0]?.pernoct_1000hab, 0)}.

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod_ccaa"
    value="pernoct_1000hab"
    valueFmt="num0"
    link="ruta"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pernoct_1000hab', title: 'Pernoctacions per 1.000 hab.', fmt: 'num0'},
        {id: 'ocupacion_hotel', title: 'Ocupació hotelera (%)', fmt: 'num1'},
        {id: 'pct_extranjeros_hotel', title: "Nits d'hotel de no residents (%)", fmt: 'num1'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=pernoct_1000hab title="Pernoctacions per 1.000 hab." fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=ocupacion_hotel title="Ocupació hotelera (%)" fmt=num1 />
    <Column id=pct_extranjeros_hotel title="Nits d'hotel de no residents (%)" fmt=num1 />
</DataTable>

FRONTUR i EGATUR només desglossen les sis comunitats que reben més turistes estrangers (destinació principal del viatge). Per habitant:

<Grid cols=2>
<BarChart
    data={ccaa_frontur}
    x=comunidad
    y=turistas_por_hab
    swapXY=true
    yFmt='0.0'
    fillColor="#0f766e"
    title="Turistes internacionals per habitant el {ccaa_frontur[0]?.anio}"
/>
<BarChart
    data={ccaa_frontur}
    x=comunidad
    y=gasto_real_por_hab
    swapXY=true
    yFmt='#,##0" €"'
    fillColor="#b45309"
    title="Despesa dels turistes per habitant el {ccaa_frontur[0]?.anio} (euros del {hitos[0]?.anio_base})"
/>
</Grid>

## Habitatges turístics

L'INE compta els habitatges anunciats com a allotjament turístic a les grans plataformes (estadística experimental). {majuscula(alMesAny(vut_espana.slice(-1)[0]?.periodo))} hi havia {formatNumber(vut_espana.slice(-1)[0]?.viviendas_1000hab, 1)} habitatges turístics per cada 1.000 habitants, el {formatNumber(vut_espana.slice(-1)[0]?.pct_viviendas, 2)} % del total d'habitatges ({formatNumber(vut_espana.slice(-1)[0]?.viviendas, 0)} habitatges). {#if vut_espana.slice(-1)[0]?.var_interanual < 0}Són un {formatNumber(-vut_espana.slice(-1)[0]?.var_interanual, 1)} % menys que el mateix mes de l'any anterior.{:else}Són un {formatNumber(vut_espana.slice(-1)[0]?.var_interanual, 1)} % més que el mateix mes de l'any anterior.{/if}

<LineChart
    data={vut_espana}
    x=periodo
    y=viviendas_1000hab
    yFmt='0.0'
    lineColor="#a21caf"
    startingAtZero={false}
    yAxisTitle="Per 1.000 habitants"
    title="Habitatges turístics per 1.000 habitants a Espanya"
/>

<p class="text-xs text-gray-500">Mesurament semestral: febrer i agost fins al 2024, maig i novembre des d'aleshores. Com que hi ha temporada (a l'estiu se n'anuncien més), convé comparar cada dada amb la del mateix mes d'un altre any.</p>

<MapaEspana
    data={vut_ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="pct"
    valueFmt="pct2"
    link="ruta"
    colorPalette={['#fdf4ff', '#e879f9', '#86198f']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
    title="Habitatges turístics en % del total d'habitatges, per comunitat"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct', title: '% dels habitatges', fmt: 'pct2'},
        {id: 'viviendas_1000hab', title: 'Per 1.000 habitants', fmt: 'num1'},
        {id: 'viviendas', title: 'Habitatges turístics', fmt: 'num0'}
    ]}
/>

<Grid cols=2>
<BarChart
    data={vut_prov}
    x=nombre
    y=pct
    swapXY=true
    yFmt=pct1
    fillColor="#a21caf"
    title="Les 15 províncies amb més habitatges turístics (% del total)"
/>
<BarChart
    data={vut_grandes}
    x=municipio
    y=pct
    swapXY=true
    yFmt=pct1
    fillColor="#d946ef"
    title="Ciutats de més de 500.000 habitants (% d'habitatges turístics)"
/>
</Grid>

Els municipis d'almenys 1.000 habitants amb més proporció d'habitatges turístics:

<DataTable data={vut_mun} rows=25>
    <Column id=puesto title="#" />
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=pct title="% dels habitatges" fmt=pct1 contentType=bar barColor="#f5d0fe" />
    <Column id=viviendas_1000hab title="Per 1.000 hab." fmt=num0 />
    <Column id=viviendas title="Habitatges turístics" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Cerca qualsevol municipi a <a href="/ca/territorios/municipios">El teu municipi en dades</a>.</p>

---

**Fonts:** INE — [FRONTUR, turistes per país de residència](https://www.ine.es/jaxiT3/Tabla.htm?t=10822) i [per comunitat de destinació](https://www.ine.es/jaxiT3/Tabla.htm?t=10823); [EGATUR, despesa per país](https://www.ine.es/jaxiT3/Tabla.htm?t=10838) i [per comunitat](https://www.ine.es/jaxiT3/Tabla.htm?t=10839); Conjuntura Turística Hotelera ([pernoctacions](https://www.ine.es/jaxiT3/Tabla.htm?t=2074), [ocupació](https://www.ine.es/jaxiT3/Tabla.htm?t=2066)); Enquesta d'Ocupació en Apartaments Turístics ([pernoctacions](https://www.ine.es/jaxiT3/Tabla.htm?t=1993), [ocupació](https://www.ine.es/jaxiT3/Tabla.htm?t=2021)); [habitatges turístics per municipi](https://www.ine.es/jaxiT3/Tabla.htm?t=39363) i [% sobre els habitatges](https://www.ine.es/jaxiT3/Tabla.htm?t=39366) (estadística experimental); [IPC](https://www.ine.es/jaxiT3/Tabla.htm?t=76125) i població. PIB: Eurostat ([namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table)).
