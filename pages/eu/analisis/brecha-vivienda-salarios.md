---
title: "Etxebizitzaren eta soldaten arteko arrakala: zenbat urteko soldata behar da erosteko edo alokatzeko"
description: "Erosketa- eta alokairu-prezioen benetako bilakaeraren analisia soldata gordinen aldean Espainian eta autonomia-erkidegoz erkidego, Etxebizitza Ministerioaren eta INEren datuekin."
i18n_origen: 3001d864626b
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql espana
SELECT
    anio,
    anios_salario,
    pct_alquiler,
    precio_90m2,
    salario_anual,
    alquiler_mes_mediana,
    precio_90m2_real,
    salario_anual_real,
    CAST(anio_base AS INTEGER) AS anio_base,
    100.0 * precio_90m2_real / first_value(precio_90m2_real) OVER (ORDER BY anio) AS idx_precio_real,
    100.0 * salario_anual_real / first_value(salario_anual_real) OVER (ORDER BY anio) AS idx_salario_real
FROM mother.vivienda_esfuerzo
WHERE nivel = 'pais' AND anios_salario IS NOT NULL
ORDER BY anio
```

```sql indices
SELECT anio, 'Vivienda 90 m² (euros reales)' AS serie, idx_precio_real AS indice FROM ${espana}
UNION ALL
SELECT anio, 'Salario bruto medio (euros reales)' AS serie, idx_salario_real AS indice FROM ${espana}
ORDER BY anio, serie
```

```sql alquiler
SELECT anio, pct_alquiler, alquiler_mes_mediana, alquiler_mes_mediana_real
FROM mother.vivienda_esfuerzo
WHERE nivel = 'pais' AND pct_alquiler IS NOT NULL
ORDER BY anio
```

```sql hitos
SELECT
    max(anio) AS anio_ult,
    min(anio) AS anio_ini,
    arg_max(anios_salario, anio) AS anios_ult,
    arg_max(precio_90m2, anio) AS precio_ult,
    arg_max(salario_anual, anio) AS salario_ult,
    max(anios_salario) AS anios_max,
    arg_max(anio, anios_salario) AS anio_max,
    min(anios_salario) AS anios_min,
    arg_min(anio, anios_salario) AS anio_min,
    100.0 * (arg_max(precio_90m2_real, anio) / arg_min(precio_90m2_real, anio) - 1) AS var_precio_real,
    100.0 * (arg_max(salario_anual_real, anio) / arg_min(salario_anual_real, anio) - 1) AS var_salario_real,
    max(anio_base) AS anio_base
FROM ${espana}
```

```sql ccaa
SELECT
    e.cod,
    e.nombre AS comunidad,
    '/eu' || t.ruta AS ruta,
    e.anio,
    e.anios_salario,
    e.precio_90m2,
    e.salario_anual,
    a.anio AS anio_alquiler,
    a.pct_alquiler,
    a.alquiler_mes_mediana,
    e.anios_salario - (SELECT anios_ult FROM ${hitos}) AS dif_vs_espana
FROM mother.vivienda_esfuerzo e
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = e.cod
LEFT JOIN mother.vivienda_esfuerzo a
  ON a.nivel = 'ccaa' AND a.cod = e.cod
 AND a.anio = (SELECT max(anio) FROM mother.vivienda_esfuerzo WHERE nivel = 'ccaa' AND pct_alquiler IS NOT NULL)
WHERE e.nivel = 'ccaa'
  AND e.anio = (SELECT max(anio) FROM mother.vivienda_esfuerzo WHERE nivel = 'ccaa' AND anios_salario IS NOT NULL)
ORDER BY e.anios_salario DESC
```

```sql ccaa_extremos
SELECT anio, nombre, anios_salario
FROM mother.vivienda_esfuerzo
WHERE anios_salario IS NOT NULL
  AND (nivel = 'pais' OR cod IN (SELECT cod FROM ${ccaa} ORDER BY anios_salario DESC LIMIT 3) OR cod IN (SELECT cod FROM ${ccaa} ORDER BY anios_salario ASC LIMIT 2))
ORDER BY anio, nombre
```

<div class="not-prose mb-4 flex flex-wrap items-center gap-2 text-xs font-semibold text-gray-500 dark:text-gray-400">
    <a href="/eu/analisis" class="text-blue-600 dark:text-blue-400 hover:underline no-underline">← Datuetan oinarritutako analisia</a>
    <span>·</span>
    <span class="rounded-full bg-amber-100 dark:bg-amber-950/60 px-2.5 py-0.5 text-amber-800 dark:text-amber-300">Etxebizitza eta Soldatak</span>
    <span>·</span>
    <a href="/eu/vivienda/esfuerzo" class="hover:underline text-gray-600 dark:text-gray-400 no-underline">Ikusi ahaleginaren panel iraunkorra →</a>
</div>

# 🏠 Etxebizitzaren eta soldaten arteko arrakala: zenbat urteko soldata behar da erosteko edo alokatzeko

Espainian etxebizitza eskuratzeari buruzko eztabaidan maiz nahasten dira inflazioa kentzen ez duten zifra nominalak eta autonomia-erkidegoen arteko alde handiak ezkutatzen dituzten batez besteko nazionalak. **90 m²-ko etxebizitza baten tasazio-balioa** (Etxebizitza Ministerioa), **PFEZan aitortutako alokairu medianoa** (SERPAVI) eta lurralde bakoitzeko **urteko batez besteko soldata gordina** (INEren Hiruhilekoko Lan Kostuaren Inkesta) gurutzatuz, zehazki neur daiteke zenbateko soldata-ahalegina eskatzen duen gaur etxea izateak azken bi hamarkaden aldean.

<Grid cols=4>
    <KpiCard
        title="Soldata-urteak 90 m² erosteko"
        value={hitos[0]?.anios_ult}
        formattedValue="{formatNumber(hitos[0]?.anios_ult, 1)} urte"
        period="soldata gordin osoa {hitos[0]?.anio_ult}(e)n · gailurra: {formatNumber(hitos[0]?.anios_max, 1)} ({hitos[0]?.anio_max})"
        direction="positive-down"
        source="MIVAU / INE"
        href="/eu/vivienda/esfuerzo"
        sparklineData={espana.map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Alokairura bideratutako soldata"
        value={alquiler.slice(-1)[0]?.pct_alquiler}
        formattedValue="% {formatNumber(alquiler.slice(-1)[0]?.pct_alquiler, 1)}"
        period="batez besteko soldata gordinetik ({alquiler.slice(-1)[0]?.anio}) · {formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana, 0)} €/hileko"
        direction="positive-down"
        source="SERPAVI / INE"
        href="/eu/vivienda/alquiler"
        sparklineData={alquiler.map(d => ({...d, y: d.pct_alquiler}))}
    />
    <KpiCard
        title="Ahalegin handieneko erkidegoa"
        value={ccaa[0]?.anios_salario}
        formattedValue="{formatNumber(ccaa[0]?.anios_salario, 1)} urte"
        period="{ccaa[0]?.comunidad} ({ccaa[0]?.anio}) · {ccaa.slice(-1)[0]?.comunidad}(e)n: {formatNumber(ccaa.slice(-1)[0]?.anios_salario, 1)}"
        direction="positive-down"
        source="MIVAU / INE"
        sparklineData={ccaa_extremos.filter(d => d.nombre === ccaa[0]?.comunidad).map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Batez besteko soldata gordina"
        value={hitos[0]?.salario_ult}
        formattedValue="{formatNumber(hitos[0]?.salario_ult, 0)} €/urteko"
        period="Espainia ({hitos[0]?.anio_ult}) · 90 m²-ko etxea: {formatNumber(hitos[0]?.precio_ult, 0)} €"
        direction="positive-up"
        source="INE (ETCL)"
        href="/eu/economia/salarios"
        sparklineData={espana.map(d => ({...d, y: d.salario_anual_real}))}
    />
</Grid>

## 1. Hiru etapa bi hamarkadatan: burbuila, doikuntza eta garestitze berria

Inflazioa kenduta ({hitos[0]?.anio_base}ko euro konstanteak) eta {hitos[0]?.anio_ini}. urtea 100 oinarri gisa ezarrita, Espainiako etxebizitza-merkatuak oso fase markatuak igaro ditu:

1. **Burbuilaren gailurra ({hitos[0]?.anio_max}):** 90 m²-ko etxebizitza bat erosteko **{formatNumber(hitos[0]?.anios_max, 1)} urteko** soldata gordin osoa behar izatera iritsi zen.
2. **Finantza-krisiaren ondorengo doikuntza ({hitos[0]?.anio_min}):** prezioen benetako jaitsierak **{formatNumber(hitos[0]?.anios_min, 1)} urteko** soldataraino murriztu zuen ahalegina.
3. **Azken hamarkada ({hitos[0]?.anio_min}–{hitos[0]?.anio_ult}):** soldata gordin erreala ia geldirik mantendu den bitartean (% {formatNumber(hitos[0]?.var_salario_real, 1)}ko aldaketa metatua {hitos[0]?.anio_ini}tik), etxebizitzaren eta alokairuaren prezio erreala berriz igo da hirigune handietan eta eremu turistikoetan, batez besteko nazionala **{formatNumber(hitos[0]?.anios_ult, 1)} urteko** soldata gordinean kokatuz.

<LineChart
    data={indices}
    x=anio
    y=indice
    series=serie
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Indize erreala (100 oinarria = lehen urtea)"
    startingAtZero={false}
    title="90 m²-ko etxebizitza baten prezio errealaren bilakaera batez besteko soldata gordinaren aldean (100 oinarria)"
/>

<LineChart
    data={espana}
    x=anio
    y=anios_salario
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Soldata gordinaren urteak"
    startingAtZero={false}
    title="Espainian 90 m²-ko etxebizitza bat erosteko behar diren soldata gordin osoko urteak"
/>

## 2. Lurralde-arrakala bikoiztu egiten da kostalde/hiriburuen eta barnealdearen artean

Batez besteko nazionalak ({formatNumber(hitos[0]?.anios_ult, 1)} urte) bikoitza baino gehiagoko arrakala ezkutatzen du autonomia-erkidegoen artean, nahiz eta soldatak handiagoak izan Madrilen, Euskal Autonomia Erkidegoan edo Katalunian:

- **{ccaa[0]?.comunidad}** ({formatNumber(ccaa[0]?.anios_salario, 1)} urte), **{ccaa[1]?.comunidad}** ({formatNumber(ccaa[1]?.anios_salario, 1)} urte) eta **{ccaa[2]?.comunidad}** ({formatNumber(ccaa[2]?.anios_salario, 1)} urte) erkidegoetan, 90 m²-ko batez besteko etxebizitza bat erosteak hamarkada bat baino askoz gehiagoko soldata garbi baliokidea eskatzen du.
- Aurkako muturrean, **{ccaa.slice(-1)[0]?.comunidad}** ({formatNumber(ccaa.slice(-1)[0]?.anios_salario, 1)} urte) eta **{ccaa.slice(-2)[0]?.comunidad}** ({formatNumber(ccaa.slice(-2)[0]?.anios_salario, 1)} urte) erkidegoetan, beharrezko ahalegina merkatu tentsionatuenetakoaren erdia baino txikiagoa da.

<LineChart
    data={ccaa_extremos}
    x=anio
    y=anios_salario
    series=nombre
    xFmt='0'
    yFmt='0.0'
    yAxisTitle="Soldata gordinaren urteak"
    startingAtZero={false}
    title="Erosketa-ahaleginaren bilakaera: 3 erkidego garestienak, 2 eskuragarrienak eta Espainia"
/>

<BarChart
    data={ccaa}
    x=comunidad
    y=anios_salario
    swapXY=true
    yFmt='0.0'
    yAxisTitle="Soldata gordinaren urteak"
    title="Tokiko soldata gordinaren urteak 90 m²-ko etxebizitza bat erosteko ({ccaa[0]?.anio})"
/>

## 3. Alokairuak soldata gordin medianoaren laurdena xurgatzen du jada

Alokairuan bizi direnentzat, Etxebizitza Ministerioaren erreferentziazko adierazleak (PFEZan aitortutako benetako kontratuak) erakusten du etxebizitza kolektibo baten alokairu medianoa estatuko batez besteko soldata gordinaren **% {formatNumber(alquiler.slice(-1)[0]?.pct_alquiler, 1)}** dela ({formatNumber(alquiler.slice(-1)[0]?.alquiler_mes_mediana, 0)} €/hileko), eta % 30eko atalasea gainditzen duela erkidego tentsionatuenetan soldata garbiaren gainean kalkulatzen denean.

<LineChart
    data={alquiler}
    x=anio
    y=pct_alquiler
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="Soldata gordinaren %a"
    startingAtZero={false}
    title="Espainian alokairu medianora bideratutako batez besteko soldata gordinaren ehunekoa"
/>

## 4. Autonomia-erkidegoen araberako taula konparatiboa

<DataTable data={ccaa} rows=19 link=ruta>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=anios_salario title="Soldata-urteak (90 m²)" fmt='0.0' />
    <Column id=dif_vs_espana title="Vs. Espainiako b.b. (urteak)" fmt='+0.0;-0.0;0.0' contentType=delta />
    <Column id=precio_90m2 title="90 m²-ko etxea (€)" fmt='#,##0' />
    <Column id=salario_anual title="Urteko soldata gordina (€)" fmt='#,##0' />
    <Column id=pct_alquiler title="Alokairua / soldata (%)" fmt='0.0"%"' />
    <Column id=alquiler_mes_mediana title="Alokairu medianoa (€/hil)" fmt='#,##0' />
</DataTable>

---

**Metodologia eta iturriak:**
- **Erosketa-prezioa:** Etxebizitza librearen batez besteko tasazio-balioa ([Etxebizitza eta Hiri Agenda Ministerioa](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000)), 90 m²-ko azalera estandarrarekin biderkatuta (eskualdatze-zergak eta hipoteka-interesak kontuan hartu gabe).
- **Alokairua:** Etxebizitza kolektiboaren hileko errenta medianoa, Etxebizitzaren Alokairuaren Prezioaren Erreferentzia Sistema Estataletik ([SERPAVI](https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi)), AEATen datu fiskaletan oinarrituta.
- **Soldatak:** Langile eta urte bakoitzeko soldata-kostu gordin osoa, Hiruhilekoko Lan Kostuaren Inkestatik ([INE, 6061 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=6061)).
- **Arakatzen jarraitzeko:** Kontsultatu [Etxebizitza](/eu/vivienda), [Ahalegina probintziaka](/eu/vivienda/esfuerzo), [Alokairuko etxebizitza publikoa](/eu/vivienda/vivienda-publica) eta [Soldata errealak](/eu/economia/salarios) ataletako panel iraunkorrak.
