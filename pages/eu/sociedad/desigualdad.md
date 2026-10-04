---
title: Errenta, pobrezia eta desberdintasuna
description: "Etxeen batez besteko errenta inflazioa kenduta, pobrezia-arriskua, AROPE, gabezia materiala, Gini indizea eta S80/S20 Espainian, erkidegoaren, adinaren eta udalerriaren arabera, eta EBrekiko konparazioa."
i18n_origen: 074b220d7ed5
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
</script>

```sql nac
SELECT *
FROM mother.renta_ecv_ccaa
WHERE cod = '00' AND anio >= 2008
ORDER BY anio
```

```sql ue_ultimo
SELECT
    max(valor) FILTER (WHERE cod_pais = 'ES' AND indicador = 'gini') AS gini_es,
    max(valor) FILTER (WHERE cod_pais = 'EU27_2020' AND indicador = 'gini') AS gini_ue,
    max(valor) FILTER (WHERE cod_pais = 'ES' AND indicador = 'arope') AS arope_es,
    max(valor) FILTER (WHERE cod_pais = 'EU27_2020' AND indicador = 'arope') AS arope_ue,
    max(valor) FILTER (WHERE cod_pais = 'ES' AND indicador = 's80_s20') AS s80_es,
    max(valor) FILTER (WHERE cod_pais = 'EU27_2020' AND indicador = 's80_s20') AS s80_ue,
    CAST(max(anio) AS INTEGER) AS anio
FROM mother.renta_ue
WHERE anio = (SELECT max(anio) FROM mother.renta_ue WHERE cod_pais = 'EU27_2020' AND indicador = 'gini')
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

# 💶 Errenta, pobrezia eta desberdintasuna

Zenbat irabazten duten batez beste Espainiako etxeek inflazioa kendu ondoren, biztanleriaren zer zati bizi den pobrezia- edo bazterkeria-arriskuan, zenbateraino banatzen den errenta modu desberdinean eta nola aldatzen den hori guztia erkidego, adin eta udalerrien artean.

<Grid cols=4>
    <KpiCard
        title="Pertsonako errenta garbia"
        value={hitos[0]?.renta_persona_real}
        formattedValue="{formatNumber(hitos[0]?.renta_persona_real, 0)} €"
        period="urtean, {urteko(hitos[0]?.anio_renta)} errenta {urteko(hitos[0]?.anio_base)} eurotan · {formatNumber(hitos[0]?.renta_persona, 0)} € korronte"
        change={hitos[0]?.var_real_2008}
        changeUnit="%"
        changePeriod="{urteko(hitos[0]?.anio_renta_2008)} errentarekiko, inflazioa kenduta"
        direction="positive-up"
        source="INE – ECV"
        sparklineData={nac.map(d => ({anio: d.anio_renta, valor: d.renta_persona_real}))}
    />
    <KpiCard
        title="Pobrezia-arriskua"
        value={hitos[0]?.tasa_pobreza}
        formattedValue="{formatNumber(hitos[0]?.tasa_pobreza, 1)} %"
        period="biztanleriarena, errenta medianaren 60 % baino gutxiagorekin (ECV {hitos[0]?.anio})"
        change={hitos[0]?.tasa_pobreza - hitos[0]?.pobreza_2008}
        changeUnit=" pp"
        changePeriod="2008ko ECVrekiko"
        direction="positive-down"
        source="INE – ECV"
        sparklineData={nac.map(d => ({anio: d.anio, valor: d.tasa_pobreza}))}
    />
    <KpiCard
        title="Pobrezia- edo bazterkeria-arriskua (AROPE)"
        value={hitos[0]?.arope}
        formattedValue="{formatNumber(hitos[0]?.arope, 1)} %"
        period="biztanleriarena {urtean(hitos[0]?.anio)} · EB-27: {formatNumber(ue_ultimo[0]?.arope_ue, 1)} % ({ue_ultimo[0]?.anio})"
        direction="positive-down"
        source="INE – ECV / Eurostat"
        sparklineData={arope_serie}
    />
    <KpiCard
        title="Gini indizea"
        value={hitos[0]?.gini}
        formattedValue={formatNumber(hitos[0]?.gini, 1)}
        period="0 = denak berdin, 100 = batek dena du · EB-27: {formatNumber(ue_ultimo[0]?.gini_ue, 1)} ({ue_ultimo[0]?.anio})"
        change={hitos[0]?.gini - hitos[0]?.gini_2008}
        changeUnit=" puntu"
        changePeriod="2008ko ECVrekiko"
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


<p class="text-xs text-gray-500">Urte bakoitzeko Bizi Baldintzen Inkestak (ECV) aurreko urteko errentari buruz galdetzen du: ECV {hitos[0]?.anio} inkestak {urteko(hitos[0]?.anio_renta)} errenta jasotzen du. Pobrezia, Gini eta S80/S20 errenta horrekin kalkulatzen dira. Zenbateko guztiak {urteko(hitos[0]?.anio_base)} eurotan daude, inflazioa KPIarekin kenduta.</p>

## Etxeen errenta erreala

```sql renta_grafico
SELECT anio_renta AS anio, 'Por persona' AS medida, renta_persona_real AS euros FROM ${nac} WHERE renta_persona_real IS NOT NULL
UNION ALL
SELECT anio_renta, 'Por unidad de consumo', renta_uc_real FROM ${nac} WHERE renta_uc_real IS NOT NULL
ORDER BY anio, medida
```

Pertsonako errenta garbiak, inflazioa kenduta, hondoa jo zuen {urteko(hitos[0]?.anio_renta_min)} errentarekin ({formatNumber(hitos[0]?.renta_min, 0)} €), eta ordutik {formatNumber(hitos[0]?.var_real_min, 1)} % igo da. {urteko(hitos[0]?.anio_renta_2008)} errentarekin alderatuta, aldea {formatNumber(hitos[0]?.var_real_2008, 1)} %-koa da.

<LineChart
    data={renta_grafico}
    x=anio
    y=euros
    series=medida
    xFmt="0"
    yFmt='#,##0" €"'
    colorPalette={['#1d4ed8', '#0f766e']}
    title="Urteko batez besteko errenta garbia, {urteko(hitos[0]?.anio_base)} eurotan (errentaren urtea)"
/>

<p class="text-xs text-gray-500">Kontsumo-unitateko errentak kontuan hartzen du etxe batean gastuak partekatzen direla: lehen helduak 1 balio du, 14 urtetik gorako gainerakoek 0,5 eta adingabeek 0,3. Tamaina desberdineko etxeak alderatzeko eta pobrezia kalkulatzeko erabiltzen den neurria da. Etxeko batez besteko errenta {formatNumber(hitos[0]?.renta_hogar_real, 0)} € izan zen.</p>

## Pobrezia eta bazterkeria

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

ECV {hitos[0]?.anio} inkestan, biztanleriaren {formatNumber(hitos[0]?.tasa_pobreza, 1)} % pobrezia-arriskuan zegoen (seriearen gehienekoa {formatNumber(hitos[0]?.pobreza_max, 1)} % izan zen, {urtean(hitos[0]?.anio_pobreza_max)}), {formatNumber(hitos[0]?.carencia_severa, 1)} %-k gabezia material eta sozial larria zuen, eta {formatNumber(hitos[0]?.fin_mes_dificultad, 1)} %-k zioen zailtasunez edo zailtasun handiz iristen zela hilabete-amaierara.

<LineChart
    data={pobreza_grafico}
    x=anio
    y=pct
    series=indicador
    xFmt="0"
    yFmt='0.0"%"'
    colorPalette={['#b91c1c', '#f59e0b', '#7c3aed', '#64748b']}
    title="Biztanleriaren % (inkestaren urtea)"
/>

<p class="text-xs text-gray-500">Pobrezia-arriskua: kontsumo-unitateko errenta Espainiako medianaren 60 %-tik behera; neurri erlatiboa da, beraz, pobreak medianara hurbiltzen badira jaisten da, ez denen errenta igotzen bada. AROPEk batzen ditu pobrezia-arriskuan daudenak, gabezia material eta sozial larria dutenak edo lan-intentsitate oso txikiko etxeetan bizi direnak (Europa 2030 definizioa, 2014tik). Gabezia material eta sozial larria: 13 oinarrizko kontzeptuetatik gutxienez 7 ezin ordaintzea (etxea berotzea, ustekabeko gastu bat, bi egunean behin haragia edo arraina jatea, arropa berria...).</p>

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

### Adinaren arabera

ECV {edad[0]?.anio} inkestan, pobrezia-arrisku handiena zuen adin-taldea hau zen: {edad_extremos[0]?.edad_max} ({formatNumber(edad_extremos[0]?.pobreza_max, 1)} %); eta txikiena, hau: {edad_extremos[0]?.edad_min} ({formatNumber(edad_extremos[0]?.pobreza_min, 1)} %).

<BarChart
    data={edad_grafico}
    x=edad
    y=pct
    series=indicador
    type=grouped
    sort=false
    yFmt='0.0"%"'
    colorPalette={['#f59e0b', '#b91c1c', '#7c3aed']}
    title="Adin-talde bakoitzaren % (ECV {edad[0]?.anio})"
/>

<p class="text-xs text-gray-500">Adinekoen errentak haien pentsioak zenbatzen ditu, baina ez metatutako aurrezkia, ezta etxea ordainduta dutenek aurrezten duten alokairua ere (zifra hauek egotzitako alokairurik gabekoak dira).</p>

## Desberdintasuna

```sql desigualdad_grafico
SELECT anio, 'España (INE)' AS territorio, gini FROM ${nac} WHERE gini IS NOT NULL
UNION ALL
SELECT anio, 'UE-27 (Eurostat)', valor FROM mother.renta_ue WHERE cod_pais = 'EU27_2020' AND indicador = 'gini'
ORDER BY anio, territorio
```

Espainiako Gini indizea {formatNumber(hitos[0]?.gini, 1)} izan zen ECV {hitos[0]?.anio} inkestan (seriearen gehienekoa: {formatNumber(hitos[0]?.gini_max, 1)}, {urtean(hitos[0]?.anio_gini_max)}). Errenta handiena duen biztanleriaren 20 %-k errenta txikiena duen 20 %-k baino {formatNumber(hitos[0]?.s80_s20, 1)} aldiz gehiago irabazten du (S80/S20 ratioa; EB-27: {formatNumber(ue_ultimo[0]?.s80_ue, 1)}, {urtean(ue_ultimo[0]?.anio)}).

<LineChart
    data={desigualdad_grafico}
    x=anio
    y=gini
    series=territorio
    xFmt="0"
    yFmt="0.0"
    yMin=25
    colorPalette={['#b91c1c', '#94a3b8']}
    title="Errenta erabilgarri baliokidearen Gini indizea (0-100)"
/>

```sql gini_paises
SELECT pais, valor AS gini, CASE WHEN cod_pais = 'ES' THEN 'España' WHEN cod_pais = 'EU27_2020' THEN 'UE-27' ELSE 'Otros' END AS grupo
FROM mother.renta_ue
WHERE indicador = 'gini' AND anio = (SELECT max(anio) FROM mother.renta_ue WHERE cod_pais = 'EU27_2020' AND indicador = 'gini')
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
    title="Gini indizea EBn ({ue_ultimo[0]?.anio})"
/>

## Autonomia-erkidegoka

```sql ccaa
SELECT e.cod, t.nombre AS comunidad, '/eu' || t.ruta AS ruta,
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

Erkidegoen arteko aldeak handiak dira: ECV {ccaa[0]?.anio} inkestan, pobrezia-arriskuaren tasa {formatNumber(ccaa_extremos[0]?.min_pobreza, 1)} %-tik ({ccaa_extremos[0]?.menos_pobreza}) {formatNumber(ccaa_extremos[0]?.max_pobreza, 1)} %-ra ({ccaa_extremos[0]?.mas_pobreza}) bitartekoa zen, eta pertsonako errenta garbia {formatNumber(ccaa_extremos[0]?.min_renta, 0)} €-tik ({ccaa_extremos[0]?.menos_renta}) {formatNumber(ccaa_extremos[0]?.max_renta, 0)} €-ra ({ccaa_extremos[0]?.mas_renta}) bitartekoa. Pobrezia-atalasea bera da Espainia osorako, eskualde bakoitzeko bizi-kostuaren arabera doitu gabe.

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
        attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
        tooltip={[
            {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'tasa_pobreza', title: 'Pobrezia-arriskua', fmt: '0.0"%"'},
            {id: 'arope', title: 'AROPE', fmt: '0.0"%"'},
            {id: 'renta_persona_real', title: 'Pertsonako errenta', fmt: '#,##0" €"'}
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
        title="Pertsonako errenta garbia ({urteko(ccaa[0]?.anio_renta)} errenta, {urteko(hitos[0]?.anio_base)} euroak)"
    />
</Grid>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=renta_persona_real title="Pertsonako errenta" fmt='#,##0" €"' />
    <Column id=tasa_pobreza title="Pobrezia-arriskua" fmt='0.0"%"' contentType=bar barColor="#fecaca" />
    <Column id=arope title="AROPE" fmt='0.0"%"' />
    <Column id=carencia_severa title="Gabezia larria" fmt='0.0"%"' />
    <Column id=fin_mes_dificultad title="Hilabete-amaiera zailtasunez" fmt='0.0"%"' />
    <Column id=gini title="Gini" fmt="0.0" />
</DataTable>

<p class="text-xs text-gray-500">Mapa: pobrezia-arriskuaren tasa (%). Ceutako eta Melillako laginak txikiak dira; beraz, haien zifrek errore-marjina zabala dute.</p>

## Udalerri aberatsenak eta pobreenak

```sql mun_base
SELECT m.cod_mun, m.municipio, p.nombre AS provincia, m.poblacion, m.renta_persona_real, m.renta_hogar_real,
    m.renta_uc_mediana_real, CAST(m.anio AS INTEGER) AS anio, '/eu/territorios/municipios?m=' || m.cod_mun AS enlace
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

INEren Etxeen Errenta Banaketaren Atlasa, Ogasunaren datuekin egina, udalerri bakoitzeraino iristen da. 20.000 biztanletik gorako {formatNumber(mun_resumen[0]?.n, 0)} udalerrien artean, pertsonako errenta handiena duen udalerria ({mun_resumen[0]?.mas_rico}) txikiena duena ({mun_resumen[0]?.mas_pobre}) baino {formatNumber(mun_resumen[0]?.ratio, 1)} aldiz aberatsagoa da ({urteko(mun_ricos[0]?.anio)} errenta).

<Grid cols=2>
    <DataTable data={mun_ricos} link=enlace rows=15 showLinkCol=false title="Pertsonako errenta handiena">
        <Column id=municipio title="Udalerria" />
        <Column id=provincia title="Probintzia" />
        <Column id=renta_persona_real title="Pertsonako" fmt='#,##0" €"' contentType=bar barColor="#bfdbfe" />
        <Column id=renta_hogar_real title="Etxeko" fmt='#,##0" €"' />
    </DataTable>
    <DataTable data={mun_pobres} link=enlace rows=15 showLinkCol=false title="Pertsonako errenta txikiena">
        <Column id=municipio title="Udalerria" />
        <Column id=provincia title="Probintzia" />
        <Column id=renta_persona_real title="Pertsonako" fmt='#,##0" €"' contentType=bar barColor="#fecaca" />
        <Column id=renta_hogar_real title="Etxeko" fmt='#,##0" €"' />
    </DataTable>
</Grid>

<DataTable data={mun_base} link=enlace rows=10 search=true showLinkCol=false title="20.000 biztanletik gorako udalerri guztiak">
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=poblacion title="Biztanleak" fmt=num0 />
    <Column id=renta_persona_real title="Pertsonako errenta" fmt='#,##0" €"' />
    <Column id=renta_hogar_real title="Etxeko errenta" fmt='#,##0" €"' />
    <Column id=renta_uc_mediana_real title="Mediana kontsumo-unitateko" fmt='#,##0" €"' />
</DataTable>

<p class="text-xs text-gray-500">Errenta garbia (zergen eta kotizazioen ondoren), INEk zerga-datuetatik abiatuta kalkulatua, {urteko(hitos[0]?.anio_base)} eurotan; urtarrilaren 1eko erroldako biztanleria. Udalerri txiki batzuetan INEk ez du datua argitaratzen, batez ere 2020 aurretik. Bilatu edozein udalerri hemen: <a href="/eu/territorios/municipios">Zure udalerria datuetan</a>.</p>

---

## Iturri ofizialak

- **[INE – Bizi Baldintzen Inkesta (ECV)](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176807&menu=ultiDatos&idp=1254735976608)**: [9947](https://www.ine.es/jaxiT3/Tabla.htm?t=9947) eta [9949](https://www.ine.es/jaxiT3/Tabla.htm?t=9949) taulak (errenta), [9963](https://www.ine.es/jaxiT3/Tabla.htm?t=9963) (pobrezia-arriskua), [76847](https://www.ine.es/jaxiT3/Tabla.htm?t=76847) eta [67240](https://www.ine.es/jaxiT3/Tabla.htm?t=67240) (AROPE), [9990](https://www.ine.es/jaxiT3/Tabla.htm?t=9990) (hilabete-amaiera), [76846](https://www.ine.es/jaxiT3/Tabla.htm?t=76846) (Gini eta S80/S20) eta [76844](https://www.ine.es/jaxiT3/Tabla.htm?t=76844) (errenta adinaren arabera).
- **[INE – Etxeen Errenta Banaketaren Atlasa](https://www.ine.es/jaxiT3/Tabla.htm?t=30824)**: errenta udalerri eta barrutiaren arabera ([30824 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=30824)) eta erkidego eta probintziaren arabera ([53689 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=53689)).
- **[Eurostat – EU-SILC](https://ec.europa.eu/eurostat/web/income-and-living-conditions)**: Gini ([ilc_di12](https://ec.europa.eu/eurostat/databrowser/view/ilc_di12/default/table)), S80/S20 ([ilc_di11](https://ec.europa.eu/eurostat/databrowser/view/ilc_di11/default/table)) eta AROPE ([ilc_peps01n](https://ec.europa.eu/eurostat/databrowser/view/ilc_peps01n/default/table)).
- **INE – Kontsumoko Prezioen Indizea**: zenbatekoak euro konstanteetan adierazteko.

<LastRefreshed prefix="Datuak eguneratuta" />
