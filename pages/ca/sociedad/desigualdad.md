---
title: Renda, pobresa i desigualtat
description: "Renda mitjana de les llars descomptada la inflació, risc de pobresa, AROPE, carència material, índex de Gini i S80/S20 a Espanya, per comunitat, edat i municipi, i comparació amb la UE."
i18n_origen: 9c8ab30724e4
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql nac
SELECT *
FROM mother.renta_ecv_ccaa
WHERE cod = '00' AND anio >= 2008
ORDER BY anio
```

```sql ue_ultimo
SELECT
    max(valor) FILTER (WHERE geo = 'ES' AND indicador = 'gini') AS gini_es,
    max(valor) FILTER (WHERE geo = 'EU27_2020' AND indicador = 'gini') AS gini_ue,
    max(valor) FILTER (WHERE geo = 'ES' AND indicador = 'arope') AS arope_es,
    max(valor) FILTER (WHERE geo = 'EU27_2020' AND indicador = 'arope') AS arope_ue,
    max(valor) FILTER (WHERE geo = 'ES' AND indicador = 's80_s20') AS s80_es,
    max(valor) FILTER (WHERE geo = 'EU27_2020' AND indicador = 's80_s20') AS s80_ue,
    CAST(max(anio) AS INTEGER) AS anio
FROM mother.renta_ue
WHERE anio = (SELECT max(anio) FROM mother.renta_ue WHERE geo = 'EU27_2020' AND indicador = 'gini')
```

```sql hitos
WITH n AS (SELECT * FROM mother.renta_ecv_ccaa WHERE cod = '00' AND renta_persona_real IS NOT NULL),
u AS (SELECT * FROM n WHERE anio = (SELECT max(anio) FROM n)),
p AS (SELECT * FROM n WHERE anio = 2008),
m AS (SELECT * FROM n ORDER BY renta_persona_real LIMIT 1)
SELECT
    CAST(u.anio AS INTEGER) AS anio,
    CAST(u.anio_renta AS INTEGER) AS anio_renta,
    CAST(u.anio_base AS INTEGER) AS anio_base,
    u.renta_persona_real, u.renta_persona, u.renta_hogar_real, u.renta_uc_real,
    u.tasa_pobreza, u.arope, u.carencia_severa, u.fin_mes_dificultad, u.gini, u.s80_s20,
    CAST(p.anio_renta AS INTEGER) AS anio_renta_2008,
    100 * (u.renta_persona_real / p.renta_persona_real - 1) AS var_real_2008,
    CAST(m.anio_renta AS INTEGER) AS anio_renta_min,
    m.renta_persona_real AS renta_min,
    100 * (u.renta_persona_real / m.renta_persona_real - 1) AS var_real_min,
    p.tasa_pobreza AS pobreza_2008,
    p.gini AS gini_2008,
    (SELECT max(tasa_pobreza) FROM n) AS pobreza_max,
    (SELECT CAST(arg_max(anio, tasa_pobreza) AS INTEGER) FROM n) AS anio_pobreza_max,
    (SELECT max(gini) FROM n) AS gini_max,
    (SELECT CAST(arg_max(anio, gini) AS INTEGER) FROM n) AS anio_gini_max
FROM u, p, m
```

```sql arope_serie
SELECT anio, arope AS valor FROM ${nac} WHERE arope IS NOT NULL ORDER BY anio
```

```sql gini_serie
SELECT anio, gini AS valor FROM ${nac} WHERE gini IS NOT NULL ORDER BY anio
```

# 💶 Renda, pobresa i desigualtat

Quant ingressen de mitjana les llars a Espanya un cop descomptada la inflació, quina part de la població viu en risc de pobresa o exclusió, fins a quin punt la renda es reparteix de manera desigual i com canvia tot plegat entre comunitats, edats i municipis.

<Grid cols=4>
    <KpiCard
        title="Renda neta per persona"
        value={hitos[0]?.renta_persona_real}
        formattedValue="{formatNumber(hitos[0]?.renta_persona_real, 0)} €"
        period="l'any, renda de {hitos[0]?.anio_renta} en euros de {hitos[0]?.anio_base} · {formatNumber(hitos[0]?.renta_persona, 0)} € corrents"
        change={hitos[0]?.var_real_2008}
        changeUnit="%"
        changePeriod="vs. {hitos[0]?.anio_renta_2008}, descomptada la inflació"
        direction="positive-up"
        source="INE – ECV"
        sparklineData={nac.map(d => ({anio: d.anio_renta, valor: d.renta_persona_real}))}
    />
    <KpiCard
        title="Risc de pobresa"
        value={hitos[0]?.tasa_pobreza}
        formattedValue="{formatNumber(hitos[0]?.tasa_pobreza, 1)} %"
        period="de la població, amb menys del 60 % de la renda mediana (ECV {hitos[0]?.anio})"
        change={hitos[0]?.tasa_pobreza - hitos[0]?.pobreza_2008}
        changeUnit=" pp"
        changePeriod="vs. ECV 2008"
        direction="positive-down"
        source="INE – ECV"
        sparklineData={nac.map(d => ({anio: d.anio, valor: d.tasa_pobreza}))}
    />
    <KpiCard
        title="Risc de pobresa o exclusió (AROPE)"
        value={hitos[0]?.arope}
        formattedValue="{formatNumber(hitos[0]?.arope, 1)} %"
        period="de la població el {hitos[0]?.anio} · UE-27: {formatNumber(ue_ultimo[0]?.arope_ue, 1)} % ({ue_ultimo[0]?.anio})"
        direction="positive-down"
        source="INE – ECV / Eurostat"
        sparklineData={arope_serie}
    />
    <KpiCard
        title="Índex de Gini"
        value={hitos[0]?.gini}
        formattedValue={formatNumber(hitos[0]?.gini, 1)}
        period="0 = tothom igual, 100 = un ho té tot · UE-27: {formatNumber(ue_ultimo[0]?.gini_ue, 1)} ({ue_ultimo[0]?.anio})"
        change={hitos[0]?.gini - hitos[0]?.gini_2008}
        changeUnit=" punts"
        changePeriod="vs. ECV 2008"
        direction="positive-down"
        source="INE – ECV / Eurostat"
        sparklineData={gini_serie}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('riesgo_pobreza', 'gini')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'riesgo_pobreza')} />
<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'gini')} />


<p class="text-xs text-gray-500">L'Enquesta de Condicions de Vida (ECV) de cada any pregunta per la renda de l'any anterior: l'ECV {hitos[0]?.anio} recull la renda de {hitos[0]?.anio_renta}. La pobresa, el Gini i l'S80/S20 es calculen amb aquesta renda. Tots els imports són en euros de {hitos[0]?.anio_base}, descomptada la inflació amb l'IPC.</p>

## La renda real de les llars

```sql renta_grafico
SELECT anio_renta AS anio, 'Por persona' AS medida, renta_persona_real AS euros FROM ${nac} WHERE renta_persona_real IS NOT NULL
UNION ALL
SELECT anio_renta, 'Por unidad de consumo', renta_uc_real FROM ${nac} WHERE renta_uc_real IS NOT NULL
ORDER BY anio, medida
```

La renda neta per persona, descomptada la inflació, va tocar fons amb la renda de {hitos[0]?.anio_renta_min} ({formatNumber(hitos[0]?.renta_min, 0)} €) i des d'aleshores ha pujat un {formatNumber(hitos[0]?.var_real_min, 1)} %. Respecte a la renda de {hitos[0]?.anio_renta_2008}, la diferència és del {formatNumber(hitos[0]?.var_real_2008, 1)} %.

<LineChart
    data={renta_grafico}
    x=anio
    y=euros
    series=medida
    xFmt="0"
    yFmt='#,##0" €"'
    colorPalette={['#1d4ed8', '#0f766e']}
    title="Renda neta mitjana anual, en euros de {hitos[0]?.anio_base} (any de la renda)"
/>

<p class="text-xs text-gray-500">La renda per unitat de consum té en compte que en una llar es comparteixen despeses: el primer adult compta 1, els altres majors de 14 anys 0,5 i els menors 0,3. És la mesura que s'utilitza per comparar llars de mida diferent i per calcular la pobresa. La renda mitjana per llar va ser de {formatNumber(hitos[0]?.renta_hogar_real, 0)} €.</p>

## Pobresa i exclusió

```sql pobreza_grafico
SELECT anio, 'Riesgo de pobreza' AS indicador, tasa_pobreza AS pct FROM ${nac} WHERE tasa_pobreza IS NOT NULL
UNION ALL
SELECT anio, 'AROPE (pobreza o exclusión)', arope FROM ${nac} WHERE arope IS NOT NULL
UNION ALL
SELECT anio, 'Carencia material y social severa', carencia_severa FROM ${nac} WHERE carencia_severa IS NOT NULL
UNION ALL
SELECT anio, 'Llega a fin de mes con dificultad', fin_mes_dificultad FROM ${nac} WHERE fin_mes_dificultad IS NOT NULL
ORDER BY anio, indicador
```

A l'ECV {hitos[0]?.anio}, el {formatNumber(hitos[0]?.tasa_pobreza, 1)} % de la població estava en risc de pobresa (el màxim de la sèrie va ser el {formatNumber(hitos[0]?.pobreza_max, 1)} % el {hitos[0]?.anio_pobreza_max}), el {formatNumber(hitos[0]?.carencia_severa, 1)} % patia carència material i social severa i el {formatNumber(hitos[0]?.fin_mes_dificultad, 1)} % deia que arribava a final de mes amb dificultat o amb molta dificultat.

<LineChart
    data={pobreza_grafico}
    x=anio
    y=pct
    series=indicador
    xFmt="0"
    yFmt='0.0"%"'
    colorPalette={['#b91c1c', '#f59e0b', '#7c3aed', '#64748b']}
    title="% de la població (any de l'enquesta)"
/>

<p class="text-xs text-gray-500">Risc de pobresa: renda per unitat de consum per sota del 60 % de la mediana d'Espanya; és una mesura relativa, de manera que baixa si els pobres s'acosten a la mediana, no si puja la renda de tothom. L'AROPE suma els qui estan en risc de pobresa, pateixen carència material i social severa o viuen en llars amb una intensitat de treball molt baixa (definició Europa 2030, des del 2014). Carència material i social severa: no poder permetre's almenys 7 de 13 conceptes bàsics (escalfar la casa, una despesa imprevista, menjar carn o peix cada dos dies, roba nova...).</p>

```sql edad
SELECT edad, orden, arope, tasa_pobreza, carencia_severa, renta_uc_real, CAST(anio AS INTEGER) AS anio
FROM mother.renta_ecv_edad
WHERE anio = (SELECT max(anio) FROM mother.renta_ecv_edad) AND orden BETWEEN 1 AND 5
ORDER BY orden
```

```sql edad_grafico
SELECT edad, orden, 'AROPE' AS indicador, arope AS pct FROM ${edad}
UNION ALL
SELECT edad, orden, 'Riesgo de pobreza', tasa_pobreza FROM ${edad}
UNION ALL
SELECT edad, orden, 'Carencia severa', carencia_severa FROM ${edad}
ORDER BY orden
```

```sql edad_extremos
SELECT lower(arg_max(edad, tasa_pobreza)) AS edad_max, max(tasa_pobreza) AS pobreza_max,
    lower(arg_min(edad, tasa_pobreza)) AS edad_min, min(tasa_pobreza) AS pobreza_min
FROM ${edad}
```

### Per edat

A l'ECV {edad[0]?.anio}, el grup d'edat amb més risc de pobresa era el de «{edad_extremos[0]?.edad_max}» ({formatNumber(edad_extremos[0]?.pobreza_max, 1)} %) i el que menys, el de «{edad_extremos[0]?.edad_min}» ({formatNumber(edad_extremos[0]?.pobreza_min, 1)} %).

<BarChart
    data={edad_grafico}
    x=edad
    y=pct
    series=indicador
    type=grouped
    sort=false
    yFmt='0.0"%"'
    colorPalette={['#f59e0b', '#b91c1c', '#7c3aed']}
    title="% de cada grup d'edat (ECV {edad[0]?.anio})"
/>

<p class="text-xs text-gray-500">La renda de la gent gran compta les pensions, però no l'estalvi acumulat ni el lloguer que s'estalvien els qui tenen la casa pagada (aquestes xifres són sense lloguer imputat).</p>

## Desigualtat

```sql desigualdad_grafico
SELECT anio, 'España (INE)' AS territorio, gini FROM ${nac} WHERE gini IS NOT NULL
UNION ALL
SELECT anio, 'UE-27 (Eurostat)', valor FROM mother.renta_ue WHERE geo = 'EU27_2020' AND indicador = 'gini'
ORDER BY anio, territorio
```

L'índex de Gini d'Espanya va ser {formatNumber(hitos[0]?.gini, 1)} a l'ECV {hitos[0]?.anio} (màxim de la sèrie: {formatNumber(hitos[0]?.gini_max, 1)} el {hitos[0]?.anio_gini_max}). El 20 % de la població amb més renda ingressa {formatNumber(hitos[0]?.s80_s20, 1)} vegades el que ingressa el 20 % amb menys (ràtio S80/S20; UE-27: {formatNumber(ue_ultimo[0]?.s80_ue, 1)} el {ue_ultimo[0]?.anio}).

<LineChart
    data={desigualdad_grafico}
    x=anio
    y=gini
    series=territorio
    xFmt="0"
    yFmt="0.0"
    yMin=25
    colorPalette={['#b91c1c', '#94a3b8']}
    title="Índex de Gini de la renda disponible equivalent (0-100)"
/>

```sql gini_paises
SELECT pais, valor AS gini, CASE WHEN geo = 'ES' THEN 'España' WHEN geo = 'EU27_2020' THEN 'UE-27' ELSE 'Otros' END AS grupo
FROM mother.renta_ue
WHERE indicador = 'gini' AND anio = (SELECT max(anio) FROM mother.renta_ue WHERE geo = 'EU27_2020' AND indicador = 'gini')
ORDER BY valor DESC
```

<BarChart
    data={gini_paises}
    x=pais
    y=gini
    series=grupo
    swapXY=true
    sort=false
    yFmt="0.0"
    colorPalette={['#94a3b8', '#b91c1c', '#1d4ed8']}
    height={560}
    title="Índex de Gini a la UE ({ue_ultimo[0]?.anio})"
/>

## Per comunitat autònoma

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/ca' || t.ruta AS ruta,
    e.renta_persona_real, e.renta_uc_real, e.tasa_pobreza, e.arope, e.carencia_severa, e.fin_mes_dificultad, e.gini,
    CAST(e.anio AS INTEGER) AS anio, CAST(e.anio_renta AS INTEGER) AS anio_renta
FROM mother.renta_ecv_ccaa e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
WHERE e.nivel = 'ccaa' AND e.anio = (SELECT max(anio) FROM mother.renta_ecv_ccaa WHERE tasa_pobreza IS NOT NULL)
ORDER BY e.tasa_pobreza DESC
```

```sql ccaa_extremos
SELECT
    arg_max(comunidad, tasa_pobreza) AS mas_pobreza, max(tasa_pobreza) AS max_pobreza,
    arg_min(comunidad, tasa_pobreza) AS menos_pobreza, min(tasa_pobreza) AS min_pobreza,
    arg_max(comunidad, renta_persona_real) AS mas_renta, max(renta_persona_real) AS max_renta,
    arg_min(comunidad, renta_persona_real) AS menos_renta, min(renta_persona_real) AS min_renta
FROM ${ccaa}
```

Les diferències entre comunitats són grans: a l'ECV {ccaa[0]?.anio} la taxa de risc de pobresa anava del {formatNumber(ccaa_extremos[0]?.min_pobreza, 1)} % de {ccaa_extremos[0]?.menos_pobreza} al {formatNumber(ccaa_extremos[0]?.max_pobreza, 1)} % de {ccaa_extremos[0]?.mas_pobreza}, i la renda neta per persona, de {formatNumber(ccaa_extremos[0]?.min_renta, 0)} € a {ccaa_extremos[0]?.menos_renta} a {formatNumber(ccaa_extremos[0]?.max_renta, 0)} € a {ccaa_extremos[0]?.mas_renta}. El llindar de pobresa és el mateix per a tot Espanya, sense ajustar pel cost de la vida de cada regió.

<Grid cols=2>
    <MapaEspana
        data={ccaa}
        geoJsonUrl="/geo/ccaa.geojson"
        geoId="cod_ccaa"
        areaCol="cod"
        value="tasa_pobreza"
        valueFmt='0.0"%"'
        link="ruta"
        colorPalette={['#fef2f2', '#f87171', '#991b1b']}
        height={420}
        basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
        attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
        tooltip={[
            {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'tasa_pobreza', title: 'Risc de pobresa', fmt: '0.0"%"'},
            {id: 'arope', title: 'AROPE', fmt: '0.0"%"'},
            {id: 'renta_persona_real', title: 'Renda per persona', fmt: '#,##0" €"'}
        ]}
    />
    <BarChart
        data={ccaa}
        x=comunidad
        y=renta_persona_real
        swapXY=true
        yFmt='#,##0" €"'
        fillColor="#1d4ed8"
        height={420}
        title="Renda neta per persona (renda de {ccaa[0]?.anio_renta}, euros de {hitos[0]?.anio_base})"
    />
</Grid>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=renta_persona_real title="Renda per persona" fmt='#,##0" €"' />
    <Column id=tasa_pobreza title="Risc de pobresa" fmt='0.0"%"' contentType=bar barColor="#fecaca" />
    <Column id=arope title="AROPE" fmt='0.0"%"' />
    <Column id=carencia_severa title="Carència severa" fmt='0.0"%"' />
    <Column id=fin_mes_dificultad title="Final de mes amb dificultat" fmt='0.0"%"' />
    <Column id=gini title="Gini" fmt="0.0" />
</DataTable>

<p class="text-xs text-gray-500">Mapa: taxa de risc de pobresa (%). Les mostres de Ceuta i Melilla són petites, de manera que les seves xifres tenen un marge d'error ampli.</p>

## Municipis més rics i més pobres

```sql mun_base
SELECT m.cod_mun, m.municipio, p.nombre AS provincia, m.poblacion, m.renta_persona_real, m.renta_hogar_real,
    m.renta_uc_mediana_real, CAST(m.anio AS INTEGER) AS anio, '/ca/territorios/municipios?m=' || m.cod_mun AS enlace
FROM mother.renta_municipios m
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
WHERE m.anio = (SELECT max(anio) FROM mother.renta_municipios) AND m.poblacion > 20000 AND m.renta_persona_real IS NOT NULL
ORDER BY m.renta_persona_real DESC
```

```sql mun_ricos
SELECT * FROM ${mun_base} ORDER BY renta_persona_real DESC LIMIT 15
```

```sql mun_pobres
SELECT * FROM ${mun_base} ORDER BY renta_persona_real ASC LIMIT 15
```

```sql mun_resumen
SELECT count(*) AS n, max(renta_persona_real) / min(renta_persona_real) AS ratio,
    arg_max(municipio, renta_persona_real) AS mas_rico, arg_min(municipio, renta_persona_real) AS mas_pobre
FROM ${mun_base}
```

L'Atles de Distribució de Renda de les Llars de l'INE, elaborat amb dades d'Hisenda, arriba a cada municipi. Entre els {formatNumber(mun_resumen[0]?.n, 0)} municipis de més de 20.000 habitants, la renda per persona de {mun_resumen[0]?.mas_rico} és {formatNumber(mun_resumen[0]?.ratio, 1)} vegades la de {mun_resumen[0]?.mas_pobre} (renda de {mun_ricos[0]?.anio}).

<Grid cols=2>
    <DataTable data={mun_ricos} link=enlace rows=15 showLinkCol=false title="Més renda per persona">
        <Column id=municipio title="Municipi" />
        <Column id=provincia title="Província" />
        <Column id=renta_persona_real title="Per persona" fmt='#,##0" €"' contentType=bar barColor="#bfdbfe" />
        <Column id=renta_hogar_real title="Per llar" fmt='#,##0" €"' />
    </DataTable>
    <DataTable data={mun_pobres} link=enlace rows=15 showLinkCol=false title="Menys renda per persona">
        <Column id=municipio title="Municipi" />
        <Column id=provincia title="Província" />
        <Column id=renta_persona_real title="Per persona" fmt='#,##0" €"' contentType=bar barColor="#fecaca" />
        <Column id=renta_hogar_real title="Per llar" fmt='#,##0" €"' />
    </DataTable>
</Grid>

<DataTable data={mun_base} link=enlace rows=10 search=true showLinkCol=false title="Tots els municipis de més de 20.000 habitants">
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=poblacion title="Habitants" fmt=num0 />
    <Column id=renta_persona_real title="Renda per persona" fmt='#,##0" €"' />
    <Column id=renta_hogar_real title="Renda per llar" fmt='#,##0" €"' />
    <Column id=renta_uc_mediana_real title="Mediana per unitat de consum" fmt='#,##0" €"' />
</DataTable>

<p class="text-xs text-gray-500">Renda neta (després d'impostos i cotitzacions) calculada per l'INE a partir de dades tributàries, en euros de {hitos[0]?.anio_base}; població del padró a 1 de gener. En alguns municipis petits l'INE no publica la dada, sobretot abans del 2020. Cerca qualsevol municipi a <a href="/ca/territorios/municipios">El teu municipi en dades</a>.</p>

---

## Fonts oficials

- **[INE – Enquesta de Condicions de Vida (ECV)](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176807&menu=ultiDatos&idp=1254735976608)**: taules [9947](https://www.ine.es/jaxiT3/Tabla.htm?t=9947) i [9949](https://www.ine.es/jaxiT3/Tabla.htm?t=9949) (renda), [9963](https://www.ine.es/jaxiT3/Tabla.htm?t=9963) (risc de pobresa), [76847](https://www.ine.es/jaxiT3/Tabla.htm?t=76847) i [67240](https://www.ine.es/jaxiT3/Tabla.htm?t=67240) (AROPE), [9990](https://www.ine.es/jaxiT3/Tabla.htm?t=9990) (final de mes), [76846](https://www.ine.es/jaxiT3/Tabla.htm?t=76846) (Gini i S80/S20) i [76844](https://www.ine.es/jaxiT3/Tabla.htm?t=76844) (renda per edat).
- **[INE – Atles de Distribució de Renda de les Llars](https://www.ine.es/jaxiT3/Tabla.htm?t=30824)**: renda per municipi i districte ([taula 30824](https://www.ine.es/jaxiT3/Tabla.htm?t=30824)) i per comunitat i província ([taula 53689](https://www.ine.es/jaxiT3/Tabla.htm?t=53689)).
- **[Eurostat – EU-SILC](https://ec.europa.eu/eurostat/web/income-and-living-conditions)**: Gini ([ilc_di12](https://ec.europa.eu/eurostat/databrowser/view/ilc_di12/default/table)), S80/S20 ([ilc_di11](https://ec.europa.eu/eurostat/databrowser/view/ilc_di11/default/table)) i AROPE ([ilc_peps01n](https://ec.europa.eu/eurostat/databrowser/view/ilc_peps01n/default/table)).
- **INE – Índex de Preus de Consum**: per expressar els imports en euros constants.

<LastRefreshed prefix="Dades actualitzades" />
