---
title: Informazioa eskuratzeko erreklamazioak
description: "Ukatutako informazioagatik edo administrazio-isiltasunagatik herritarrek jarritako zenbat erreklamazio ebazten dituen Gardentasunaren eta Gobernu Onaren Kontseiluak, zenbatetan ematen dion arrazoia herritarrari eta zein ministeriok pilatzen dituzten gehien."
i18n_origen: 654d28429763
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql reclamaciones_anual
SELECT * FROM (
    VALUES
        (2015, 513, 392, 145, 112, 135, 56.4),
        (2016, 520, 488, 212, 134, 142, 61.3),
        (2017, 709, 645, 298, 168, 179, 63.9),
        (2018, 922, 810, 384, 210, 216, 64.6),
        (2019, 987, 895, 428, 232, 235, 64.8),
        (2020, 1084, 940, 452, 248, 240, 64.6),
        (2021, 1168, 1025, 510, 265, 250, 65.8),
        (2022, 1342, 1180, 602, 294, 284, 67.2),
        (2023, 1590, 1345, 704, 331, 310, 68.0),
        (2024, 1740, 1490, 792, 362, 336, 68.6)
) AS t(anio, presentadas, resueltas, estimadas, desestimadas, inadmitidas_otras, pct_estimadas_fondo)
ORDER BY anio
```

```sql ultimo
SELECT * FROM ${reclamaciones_anual} ORDER BY anio DESC LIMIT 1
```

```sql sentido_resoluciones
SELECT anio, 'Estimadas (a favor del ciudadano)' AS sentido, estimadas AS resoluciones FROM ${reclamaciones_anual}
UNION ALL
SELECT anio, 'Desestimadas (a favor de la Administración)' AS sentido, desestimadas AS resoluciones FROM ${reclamaciones_anual}
UNION ALL
SELECT anio, 'Inadmitidas o archivadas' AS sentido, inadmitidas_otras AS resoluciones FROM ${reclamaciones_anual}
ORDER BY anio, sentido
```

```sql ministerios_reclamaciones
SELECT * FROM (
    VALUES
        ('Interior', 248, 69.4),
        ('Hacienda y Función Pública', 215, 66.5),
        ('Transportes y Movilidad Sostenible', 164, 71.3),
        ('Sanidad', 142, 68.3),
        ('Presidencia, Justicia y Relaciones con las Cortes', 138, 64.5),
        ('Trabajo y Economía Social', 112, 67.0),
        ('Transición Ecológica y Reto Demográfico', 104, 72.1),
        ('Educación, FP y Deportes', 86, 65.1)
) AS t(ministerio, reclamaciones, pct_estimadas)
ORDER BY reclamaciones DESC
```

# <span aria-hidden="true">📨</span> Informazioa eskuratzeko erreklamazioak

Gardentasunari buruzko 19/2013 Legeak edozein herritarrek informazio publikoa eskatzeko duen eskubidea aitortzen du, zergatik eskatzen duen arrazoitu beharrik gabe. Ministerio edo erakunde publiko batek datuak ukatzen dituenean edo administrazio-isiltasuna gordetzen duenean, eskatzaileak erreklamazioa aurkez dezake **Gardentasunaren eta Gobernu Onaren Kontseiluaren (CTBG)** aurrean. Bere urteko memoriek erakusten dute zenbat aldiz esku hartu behar duen erregulatzaileak Administrazioa informazio publikoa ematera behartzeko.

<Grid cols=4>
    <KpiCard
        title="Aurkeztutako erreklamazioak"
        value={ultimo[0]?.presentadas}
        formattedValue={formatNumber(ultimo[0]?.presentadas, 0)}
        unit="urtean"
        period="estatu-eremua (EAO) {ultimo[0]?.anio}(e)n"
        direction="neutral"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.presentadas}))}
    />
    <KpiCard
        title="Ebatzitako erreklamazioak"
        value={ultimo[0]?.resueltas}
        formattedValue={formatNumber(ultimo[0]?.resueltas, 0)}
        unit="ebazpen"
        period="CTBGk emanak {ultimo[0]?.anio}(e)n"
        direction="positive-up"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.resueltas}))}
    />
    <KpiCard
        title="Herritarraren alde"
        value={ultimo[0]?.pct_estimadas_fondo}
        formattedValue="% {formatNumber(ultimo[0]?.pct_estimadas_fondo, 1)}"
        period="funtsezko ebazpenetatik ({ultimo[0]?.anio})"
        direction="neutral"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.pct_estimadas_fondo}))}
    />
    <KpiCard
        title="Baietsiak urtean"
        value={ultimo[0]?.estimadas}
        formattedValue={formatNumber(ultimo[0]?.estimadas, 0)}
        unit="ebazpen"
        period="informazioa ematera behartzen dute ({ultimo[0]?.anio})"
        direction="neutral"
        source="CTBG"
        sparklineData={reclamaciones_anual.map(d => ({...d, y: d.estimadas}))}
    />
</Grid>

## 1. Funtsezko hiru errekurtsotik bitan, herritarrak arrazoia zuen

2015ean Gardentasun Kontseilua martxan jarri zenetik, Estatuko Administrazio Orokorraren aurka aurkeztutako erreklamazioen kopurua hirukoiztu baino gehiago egin da (2015eko 513tik {ultimo[0]?.anio}ko **{formatNumber(ultimo[0]?.presentadas, 0)}ra**). Kontseilua gaiaren funtsa baloratzera sartzen denean (epatik kanpo aurkezteagatik edo informazio publikoa ez izateagatik onartu gabeko erreklamazioak kenduta), **kasuen % {formatNumber(ultimo[0]?.pct_estimadas_fondo, 1)}etan herritarrari ematen dio arrazoia osorik edo zati batean**, eta Administrazioari ukatu edo isilarazi zituen datuak emateko agintzen dio.

<BarChart
    data={sentido_resoluciones}
    x=anio
    y=resoluciones
    series=sentido
    type=stacked
    xFmt='0'
    yFmt='#,##0'
    yAxisTitle="Urteko ebazpenak"
    title="Gardentasun Kontseiluak Estatuko Administrazioari buruz emandako ebazpenak, noranzkoaren arabera"
/>

<LineChart
    data={reclamaciones_anual}
    x=anio
    y=pct_estimadas_fondo
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="% herritarraren alde"
    startingAtZero={false}
    title="CTBGk herritarrari arrazoia ematen dion funtsezko ebazpenen ehunekoa (%)"
/>

## 2. Zein ministeriok pilatzen dituzten erreklamazio gehien

**Barne**, **Ogasun eta Funtzio Publiko** eta **Garraio** ministerioek biltzen dute Gardentasun Kontseiluaren aurreko erreklamazio-bolumen handiena, bai jasotzen duten eskaera-bolumenagatik, bai gero CTBGk baliogabetzen dituen administrazio-isiltasunaren edo ez-onartzeko arrazoien erabilera maizagatik.

<BarChart
    data={ministerios_reclamaciones}
    x=ministerio
    y=reclamaciones
    swapXY=true
    yFmt='#,##0'
    yAxisTitle="Urteko erreklamazioak"
    title="CTBGren aurrean erreklamazio gehien dituzten ministerio-sailak ({ultimo[0]?.anio})"
/>

<DataTable data={ministerios_reclamaciones} search=false>
    <Column id=ministerio title="Ministerioa (eta atxikitako erakundeak)" />
    <Column id=reclamaciones title="Erreklamazioak" fmt='#,##0' />
    <Column id=pct_estimadas title="% baietsiak (funtsari buruz)" fmt='0.0"%"' />
</DataTable>

---

**Iturriak eta metodologia:**
- [Gardentasunaren eta Gobernu Onaren Kontseilua (CTBG)](https://www.consejodetransparencia.es/) — *Urteko jarduera-memoriak* eta estatu-eremuko erreklamazioen estatistikak (19/2013 Legearen 24. art.).
- Atari publikoen publizitate aktiboko betebeharren betetze-maila kontsultatzeko, bisitatu [Gardentasun-atariak](/eu/transparencia/publicidad-activa).
