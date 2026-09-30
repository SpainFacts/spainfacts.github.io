---
title: Turismoa
description: "Nazioarteko turistak biztanleko, haien gastua inflazioa kenduta eta BPGaren % gisa, gaualdiak eta hotelen okupazioa erkidegoka, jatorrizko herrialdeak, urtarokotasuna eta etxebizitza turistikoak udalerrika, INEren datuekin."
i18n_origen: caa9f015f151
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';

    // Hilabeteak SQLtik gaztelaniaz datoz ('enero de 2024', 'ene'): euskaratu.
    const MESES = {
        enero: ['urtarrila', 'urtarrilean'], febrero: ['otsaila', 'otsailean'], marzo: ['martxoa', 'martxoan'],
        abril: ['apirila', 'apirilean'], mayo: ['maiatza', 'maiatzean'], junio: ['ekaina', 'ekainean'],
        julio: ['uztaila', 'uztailean'], agosto: ['abuztua', 'abuztuan'], septiembre: ['iraila', 'irailean'],
        octubre: ['urria', 'urrian'], noviembre: ['azaroa', 'azaroan'], diciembre: ['abendua', 'abenduan']
    };
    const ABREV = {
        ene: 'enero', feb: 'febrero', mar: 'marzo', abr: 'abril', may: 'mayo', jun: 'junio',
        jul: 'julio', ago: 'agosto', sep: 'septiembre', oct: 'octubre', nov: 'noviembre', dic: 'diciembre'
    };
    const sufijoKo = (y) => {
        const d = y % 10;
        return d === 1 || d === 5 || (d === 0 && Math.floor(y / 10) % 2 === 1) ? 'eko' : 'ko';
    };
    // caso 0: '2024ko urtarrila'; caso 1: '2024ko urtarrilean'
    const mesEu = (t, caso = 0) => {
        const m = /^(\S+) de (\d{4})$/.exec(t ?? '');
        if (!m || !MESES[m[1]]) return t;
        const y = Number(m[2]);
        return `${y}${sufijoKo(y)} ${MESES[m[1]][caso]}`;
    };
    const mesCorto = (a, caso = 0) => (ABREV[a] ? MESES[ABREV[a]][caso] : a);
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
SELECT *
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
SELECT cod, nombre, '/eu' || ruta AS ruta, viviendas, pct_viviendas / 100 AS pct, viviendas_1000hab
FROM mother.turismo_viviendas
WHERE nivel = 'ccaa' AND periodo = (SELECT max(periodo) FROM mother.turismo_viviendas)
ORDER BY pct_viviendas DESC
```

```sql vut_prov
SELECT nombre, '/eu' || ruta AS ruta, viviendas, pct_viviendas / 100 AS pct, viviendas_1000hab
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

# 🏖️ Turismoa

Zenbat turista atzerritar iristen diren Espainiara biztanleriaren arabera, zenbat gastatzen duten inflazioa kenduta, gastu horrek zer pisu duen ekonomian, non egiten duten lo eta zenbat etxebizitza iragartzen diren ostatu turistiko gisa.

<Grid cols=4>
    <KpiCard
        title="Nazioarteko turistak"
        value={kpi_turistas.slice(-1)[0]?.turistas_por_hab_12m}
        formattedValue="{formatNumber(kpi_turistas.slice(-1)[0]?.turistas_por_hab_12m, 2)} biztanleko"
        period="{formatCompact(kpi_turistas.slice(-1)[0]?.turistas_12m, 3)} turista 12 hilabetean, {mesEu(kpi_turistas.slice(-1)[0]?.mes_txt)} arte"
        change={kpi_turistas.slice(-1)[0]?.turistas_12m_var?.toFixed(1)}
        changePeriod="aurreko 12 hilabeteekin alderatuta"
        direction="neutral"
        source="INE / FRONTUR"
        sparklineData={kpi_turistas.map(d => ({x: d.mes, y: d.turistas_por_hab_12m}))}
    />
    <KpiCard
        title="Gastua turista bakoitzeko"
        value={kpi_turistas.slice(-1)[0]?.gasto_medio_persona_real_12m}
        formattedValue="{formatNumber(kpi_turistas.slice(-1)[0]?.gasto_medio_persona_real_12m, 0)} €"
        period="bidaiako, {kpi_turistas.slice(-1)[0]?.anio_base}. urteko eurotan, 12 hilabete {mesEu(kpi_turistas.slice(-1)[0]?.mes_txt)} arte"
        change={kpi_turistas.slice(-1)[0]?.gasto_persona_12m_var?.toFixed(1)}
        changePeriod="erreala, aurreko 12 hilabeteekin alderatuta"
        direction="positive-up"
        source="INE / EGATUR"
        sparklineData={kpi_turistas.map(d => ({x: d.mes, y: d.gasto_medio_persona_real_12m}))}
    />
    <KpiCard
        title="Turisten gastua"
        value={kpi_pib.slice(-1)[0]?.gasto_pct_pib_12m}
        formattedValue="BPGaren {formatNumber(kpi_pib.slice(-1)[0]?.gasto_pct_pib_12m, 1)} %"
        period="{formatNumber(kpi_pib.slice(-1)[0]?.gasto_real_por_hab_12m, 0)} € biztanleko 12 hilabetean, {mesEu(kpi_pib.slice(-1)[0]?.mes_txt)} arte"
        change={kpi_pib.slice(-1)[0]?.pct_pib_12m_var?.toFixed(1)}
        changeUnit="p.p."
        changePeriod="duela urtebeterekin alderatuta"
        direction="neutral"
        source="INE / EGATUR, Eurostat"
        sparklineData={kpi_pib.map(d => ({x: d.mes, y: d.gasto_pct_pib_12m}))}
    />
    <KpiCard
        title="Hotel-gauak"
        value={kpi_hotel.slice(-1)[0]?.pernoct_hotel_1000hab_12m}
        formattedValue="{formatNumber(kpi_hotel.slice(-1)[0]?.pernoct_hotel_1000hab_12m, 0)} 1.000 biztanleko"
        period="{formatCompact(kpi_hotel.slice(-1)[0]?.pernoct_hotel_12m, 3)} gaualdi 12 hilabetean, {mesEu(kpi_hotel.slice(-1)[0]?.mes_txt)} arte"
        change={kpi_hotel.slice(-1)[0]?.pernoct_12m_var?.toFixed(1)}
        changePeriod="aurreko 12 hilabeteekin alderatuta"
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


<p class="text-xs text-gray-500">Turistak: Espainian gutxienez gau bat igarotzen duten bisitari ez-egoiliarrak (FRONTUR). Gastuak (EGATUR) nazioarteko garraioa, ostatua, janaria eta bidaiako gainerako erosketak barne hartzen ditu, eta {hitos[0]?.anio_base}. urteko euro konstanteetan ematen da. BPGaren ehunekoak gastu hori BPG nominalarekin alderatzen du: tamainaren erreferentzia bat da, ez turismoak BPGari egiten dion ekarpena, gastuaren zati bat Espainiatik kanpoko enpresei ordaintzen baitzaie (hegazkin-txartelak, paketeak). Zenbateko absolutuak testu txikian soilik agertzen dira, erreferentzia gisa.</p>

## Bilakaera: 2020ko amildegitik errekorrera

2019an {formatNumber(hitos[0]?.tph2019, 2)} nazioarteko turista iritsi ziren biztanleko. 2020an kopurua {formatNumber(-hitos[0]?.caida_turistas, 0)} % jaitsi zen, biztanleko {formatNumber(hitos[0]?.tph2020, 2)} izatera arte, eta {hitos[0]?.meses_cero} hilabetetan (apirilean eta maiatzean) ez zen inolako iritsierarik erregistratu; gastu erreala {formatNumber(-hitos[0]?.caida_gasto, 0)} % hondoratu zen, eta hotel-gauak, {formatNumber(-hitos[0]?.caida_hotel, 0)} %. {#if hitos[0]?.anio_recupera}Turisten kopuruak {hitos[0]?.anio_recupera}. urtean gainditu zuen berriro 2019koa,{/if} eta {hitos[0]?.anio_ult}. urtean pandemia aurretik baino {formatNumber(hitos[0]?.var_turistas_2019, 1)} % handiagoa izan zen (biztanleko {formatNumber(hitos[0]?.tph_ult, 2)}, {formatNumber(hitos[0]?.var_tph_2019, 1)} % gehiago, biztanleria ere hazi baita). Inflazioa kenduta, haien gastua 2019koa baino {formatNumber(hitos[0]?.var_gasto_2019, 1)} % handiagoa izan zen.

<BarChart
    data={anual_completo}
    x=anio
    y=turistas_por_hab
    xFmt='0'
    yFmt='0.00'
    fillColor="#0f766e"
    yAxisTitle="Turistak biztanleko"
    title="Nazioarteko turistak biztanleko eta urteko"
/>

<LineChart
    data={evol_mensual}
    x=mes
    y=turistas_1000hab
    yFmt='#,##0'
    lineColor="#0f766e"
    yAxisTitle="1.000 biztanleko"
    title="Hilero iritsitako nazioarteko turistak, 1.000 biztanleko"
/>

<p class="text-xs text-gray-500">FRONTUR 2015eko urrian hasten da. 2020ko apirilean eta maiatzean INEk zero turista erregistratu zituen, mugak itxi zirelako.</p>

## Zenbat gastatzen duten

{hitos[0]?.anio_ult}. urtean turista bakoitzak batez beste {formatNumber(hitos[0]?.gmp_ult, 0)} € gastatu zituen bidaiako ({hitos[0]?.anio_base}. urteko eurotan), 2019ko {formatNumber(hitos[0]?.gmp2019, 0)} €-en aldean, eta {formatNumber(hitos[0]?.gmd_ult, 0)} € eguneko, {formatNumber(hitos[0]?.gmd2019, 0)} €-en aldean. Batez besteko egonaldia {formatNumber(hitos[0]?.dur2019, 1)} egunetik {formatNumber(hitos[0]?.dur_ult, 1)} egunera igaro zen. Oro har, turista atzerritarren gastua BPGaren {formatNumber(hitos[0]?.pib_ult, 1)} % izan zen (2019an {formatNumber(hitos[0]?.pib2019, 1)} % eta 2020an {formatNumber(hitos[0]?.pib2020, 1)} %), {formatNumber(hitos[0]?.gph_ult, 0)} € inguru biztanleko.

<Grid cols=2>
<LineChart
    data={gasto_dia}
    x=anio
    y=euros
    xFmt='0'
    yFmt='#,##0" €"'
    lineColor="#b45309"
    startingAtZero={false}
    yAxisTitle="€ eguneko (errealak)"
    title="Turista bakoitzaren eguneko batez besteko gastua, {hitos[0]?.anio_base}. urteko eurotan"
/>
<BarChart
    data={anual_completo}
    x=anio
    y=gasto_pct_pib
    xFmt='0'
    yFmt='0.0"%"'
    fillColor="#b45309"
    yAxisTitle="BPGaren %"
    title="Nazioarteko turisten gastua, BPGaren %"
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
    yAxisTitle="€ bidaiako (errealak)"
    title="Batez besteko gastua turista eta bidaia bakoitzeko, {hitos[0]?.anio_base}. urteko eurotan"
/>

## Hotelak eta apartamentuak

Bidaiari egoiliarren eta ez-egoiliarren gaualdiak 1.000 biztanleko. Hotelen seriea 1999an hasten da, eta 2009ko krisia eta 2020ko amildegia ikusteko aukera ematen du.

<LineChart
    data={hotel_anual}
    x=anio
    y=por_1000
    series=alojamiento
    xFmt='0'
    yFmt='#,##0'
    colorPalette={['#1d4ed8', '#60a5fa']}
    yAxisTitle="Gaualdiak 1.000 biztanleko"
    title="Urteko gaualdiak 1.000 biztanleko"
/>

<LineChart
    data={ocupacion_anual}
    x=anio
    y=ocupacion
    series=alojamiento
    xFmt='0'
    yFmt='0.0"%"'
    colorPalette={['#1d4ed8', '#60a5fa']}
    yAxisTitle="Okupatutako plazen %"
    title="Okupazio-maila plazen arabera (urteko batez besteko haztatua)"
/>

<p class="text-xs text-gray-500">{anual.filter(d => d.meses_hotel === 12).slice(-1)[0]?.anio}. urtean hotel-gauen {formatNumber(anual.filter(d => d.meses_hotel === 12).slice(-1)[0]?.pct_extranjeros_hotel, 1)} % atzerrian bizi zirenenak izan ziren. Okupazio-maila: gaualdiak zati hilabeteko egunetan eskuragarri dauden plazak. Okupazio-inkestek ez dituzte etxebizitza turistikoak hartzen.</p>

## Urtarokotasuna

Hilero iritsitako nazioarteko turistak 1.000 biztanleko, {estacional_resumen[0]?.anio}. urtean eta 2019an. {estacional_resumen[0]?.anio}. urtean, iritsiera gehien izan zituen hilabeteak ({mesCorto(estacional_resumen[0]?.mes_max)}) gutxien izan zituenak ({mesCorto(estacional_resumen[0]?.mes_min)}) baino {formatNumber(estacional_resumen[0]?.ratio, 1)} aldiz turista gehiago jaso zituen. Hotelen okupazioa {formatNumber(estacional_resumen[0]?.ocup_max, 0)} % izan zen {mesCorto(estacional_resumen[0]?.mes_ocup_max, 1)}, eta {formatNumber(estacional_resumen[0]?.ocup_min, 0)} % {mesCorto(estacional_resumen[0]?.mes_ocup_min, 1)}.

<BarChart
    data={estacional}
    x=mes_nombre
    y=turistas_1000hab
    series=anio_txt
    type=grouped
    sort=false
    yFmt='#,##0'
    colorPalette={['#94a3b8', '#0f766e']}
    yAxisTitle="1.000 biztanleko"
    title="Nazioarteko turistak hilabeteka, 1.000 biztanleko"
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
    yAxisTitle="Gaualdiak 1.000 biztanleko"
    title="Hotel-gauak hilabeteka eta bidaiariaren bizilekuaren arabera, {estacional_resumen[0]?.anio}. urtean, 1.000 biztanleko"
/>

## Nondik datozen

{paises[0]?.anio_int}. urteko turisten banaketa bizileku-herrialdearen arabera, eta aldakuntza 2019arekin alderatuta.

<Grid cols=2>
<BarChart
    data={paises}
    x=pais
    y=cuota
    swapXY=true
    yFmt='0.0"%"'
    fillColor="#0f766e"
    title="Nazioarteko turisten %, {paises[0]?.anio_int}. urtean"
/>
<BarChart
    data={paises}
    x=pais
    y=var_2019
    swapXY=true
    yFmt='0.0"%"'
    fillColor="#94a3b8"
    title="Turista kopuruaren aldakuntza 2019arekin alderatuta"
/>
</Grid>

<BarChart
    data={paises_gasto}
    x=pais
    y=gasto_medio_persona_real
    swapXY=true
    yFmt='#,##0" €"'
    fillColor="#b45309"
    title="Batez besteko gastua turista eta bidaia bakoitzeko, {paises[0]?.anio_int}. urtean ({hitos[0]?.anio_base}. urteko eurotan)"
/>

<p class="text-xs text-gray-500">EGATURek Erresuma Batuaren, Frantziaren, Alemaniaren, Italiaren eta herrialde nordikoen gastua baino ez du xehatzen. "Resto de Europa", "Resto América" eta "Resto del Mundo" INEren multzokatzeak dira.</p>

<LineChart
    data={paises_evol}
    x=anio
    y=cuota
    series=pais
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="Turisten %"
    title="Merkatu nagusien pisua"
/>

## Erkidegoen arabera

Hoteletako eta apartamentu turistikoetako gaualdiak 1.000 biztanleko, {ccaa[0]?.anio}. urtean. Espainia osoan {formatNumber(ccaa_espana[0]?.pernoct_1000hab, 0)} izan ziren; {ccaa[0]?.comunidad} erkidegoan {formatNumber(ccaa[0]?.pernoct_1000hab, 0)} izatera iritsi ziren, eta {ccaa.slice(-1)[0]?.comunidad} erkidegoan {formatNumber(ccaa.slice(-1)[0]?.pernoct_1000hab, 0)} baino ez.

<AreaMap
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
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pernoct_1000hab', title: 'Gaualdiak 1.000 biztanleko', fmt: 'num0'},
        {id: 'ocupacion_hotel', title: 'Hotelen okupazioa (%)', fmt: 'num1'},
        {id: 'pct_extranjeros_hotel', title: 'Ez-egoiliarren hotel-gauak (%)', fmt: 'num1'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=pernoct_1000hab title="Gaualdiak 1.000 biztanleko" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=ocupacion_hotel title="Hotelen okupazioa (%)" fmt=num1 />
    <Column id=pct_extranjeros_hotel title="Ez-egoiliarren hotel-gauak (%)" fmt=num1 />
</DataTable>

FRONTURek eta EGATURek turista atzerritar gehien jasotzen dituzten sei erkidegoak baino ez dituzte xehatzen (bidaiaren helmuga nagusia). Biztanleko:

<Grid cols=2>
<BarChart
    data={ccaa_frontur}
    x=comunidad
    y=turistas_por_hab
    swapXY=true
    yFmt='0.0'
    fillColor="#0f766e"
    title="Nazioarteko turistak biztanleko, {ccaa_frontur[0]?.anio}. urtean"
/>
<BarChart
    data={ccaa_frontur}
    x=comunidad
    y=gasto_real_por_hab
    swapXY=true
    yFmt='#,##0" €"'
    fillColor="#b45309"
    title="Turisten gastua biztanleko, {ccaa_frontur[0]?.anio}. urtean ({hitos[0]?.anio_base}. urteko eurotan)"
/>
</Grid>

## Etxebizitza turistikoak

INEk plataforma handietan ostatu turistiko gisa iragarritako etxebizitzak zenbatzen ditu (neurketa esperimentala). {mesEu(vut_espana.slice(-1)[0]?.periodo_txt, 1)} {formatNumber(vut_espana.slice(-1)[0]?.viviendas_1000hab, 1)} etxebizitza turistiko zeuden 1.000 biztanleko, etxebizitza guztien {formatNumber(vut_espana.slice(-1)[0]?.pct_viviendas, 2)} % ({formatNumber(vut_espana.slice(-1)[0]?.viviendas, 0)} etxebizitza). {#if vut_espana.slice(-1)[0]?.var_interanual < 0}Aurreko urteko hilabete berean baino {formatNumber(-vut_espana.slice(-1)[0]?.var_interanual, 1)} % gutxiago dira.{:else}Aurreko urteko hilabete berean baino {formatNumber(vut_espana.slice(-1)[0]?.var_interanual, 1)} % gehiago dira.{/if}

<LineChart
    data={vut_espana}
    x=periodo
    y=viviendas_1000hab
    yFmt='0.0'
    lineColor="#a21caf"
    startingAtZero={false}
    yAxisTitle="1.000 biztanleko"
    title="Etxebizitza turistikoak 1.000 biztanleko Espainian"
/>

<p class="text-xs text-gray-500">Seihileko neurketa: otsaila eta abuztua 2024ra arte, eta maiatza eta azaroa geroztik. Denboraldia dagoenez (udan gehiago iragartzen dira), komeni da datu bakoitza beste urte bateko hilabete berekoarekin alderatzea.</p>

<AreaMap
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
    attribution="Tiles © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
    title="Etxebizitza turistikoak, etxebizitza guztien %, erkidegoka"
    tooltip={[
        {id: 'nombre', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'pct', title: 'Etxebizitzen %', fmt: 'pct2'},
        {id: 'viviendas_1000hab', title: '1.000 biztanleko', fmt: 'num1'},
        {id: 'viviendas', title: 'Etxebizitza turistikoak', fmt: 'num0'}
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
    title="Etxebizitza turistiko gehien dituzten 15 probintziak (guztizkoaren %)"
/>
<BarChart
    data={vut_grandes}
    x=municipio
    y=pct
    swapXY=true
    yFmt=pct1
    fillColor="#d946ef"
    title="500.000 biztanletik gorako hiriak (etxebizitza turistikoen %)"
/>
</Grid>

Etxebizitza turistikoen proportzio handiena duten gutxienez 1.000 biztanleko udalerriak:

<DataTable data={vut_mun} rows=25>
    <Column id=puesto title="#" />
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=pct title="Etxebizitzen %" fmt=pct1 contentType=bar barColor="#f5d0fe" />
    <Column id=viviendas_1000hab title="1.000 biztanleko" fmt=num0 />
    <Column id=viviendas title="Etxebizitza turistikoak" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Bilatu edozein udalerri hemen: <a href="/eu/territorios/municipios">Zure udalerria datuetan</a>.</p>

---

**Iturriak:** INE — [FRONTUR, turistak bizileku-herrialdearen arabera](https://www.ine.es/jaxiT3/Tabla.htm?t=10822) eta [helmuga-erkidegoaren arabera](https://www.ine.es/jaxiT3/Tabla.htm?t=10823); [EGATUR, gastua herrialdeka](https://www.ine.es/jaxiT3/Tabla.htm?t=10838) eta [erkidegoka](https://www.ine.es/jaxiT3/Tabla.htm?t=10839); Hotelen Egoera Turistikoa ([gaualdiak](https://www.ine.es/jaxiT3/Tabla.htm?t=2074), [okupazioa](https://www.ine.es/jaxiT3/Tabla.htm?t=2066)); Apartamentu Turistikoen Okupazio Inkesta ([gaualdiak](https://www.ine.es/jaxiT3/Tabla.htm?t=1993), [okupazioa](https://www.ine.es/jaxiT3/Tabla.htm?t=2021)); [etxebizitza turistikoak udalerrika](https://www.ine.es/jaxiT3/Tabla.htm?t=39363) eta [etxebizitzen gaineko %](https://www.ine.es/jaxiT3/Tabla.htm?t=39366) (neurketa esperimentala); [KPI](https://www.ine.es/jaxiT3/Tabla.htm?t=76125) eta biztanleria. BPG: Eurostat ([namq_10_gdp](https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table)).
