---
title: Ekonomia-sektoreak
description: "Espainiako ekonomiaren sektore bakoitzak zenbat ekoizten duen eta zenbat pertsona enplegatzen dituen, haren hazkunde erreala eta produktibitatea, 1995etik."
i18n_origen: e8ce24d9ad4d
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql sectores
SELECT *
FROM mother.economia_sectores
ORDER BY anio, sector
```

```sql ultimo
SELECT
    s.sector,
    s.rama,
    s.es_subrama,
    s.peso_vab,
    s.crecimiento_real,
    s.ocupados_miles,
    s.ocupados_1000_hab,
    s.peso_empleo,
    s.productividad_real,
    100 * (s.vab_real_meur / b.vab_real_meur - 1) AS crec_desde_2019,
    s.anio,
    s.anio_euros
FROM mother.economia_sectores s
LEFT JOIN mother.economia_sectores b ON b.rama = s.rama AND b.anio = 2019
WHERE s.anio = (SELECT max(anio) FROM mother.economia_sectores)
ORDER BY s.rama = 'TOTAL', s.peso_vab DESC
```

```sql total
SELECT anio, crecimiento_real, ocupados_1000_hab, productividad_real, ocupados_miles
FROM mother.economia_sectores
WHERE rama = 'TOTAL'
ORDER BY anio
```

```sql sin_total
SELECT *
FROM mother.economia_sectores
WHERE rama <> 'TOTAL' AND NOT es_subrama
ORDER BY anio, sector
```

```sql indice_vab
SELECT
    s.anio,
    s.sector,
    100 * s.vab_real_meur / b.vab_real_meur AS indice
FROM mother.economia_sectores s
JOIN mother.economia_sectores b ON b.rama = s.rama AND b.anio = 2008
WHERE s.rama IN ('B-E', 'F', 'G-I', 'J', 'M_N', 'O-Q', 'TOTAL')
ORDER BY s.anio, s.sector
```

# 🏭 Ekonomia-sektoreak

Zer ekoizten duen Espainiako ekonomiak eta nork ekoizten duen. Sektore bakoitzaren balio erantsia {ultimo[0]?.anio_euros}. urteko euro konstanteetan neurtzen da, eta enplegua 1.000 biztanleko landunetan, biztanleria handiagoa izateagatik soilik hazi ez dadin.

<Grid cols=4>
    <KpiCard
        title="Ekonomiaren hazkunde erreala"
        value={total.slice(-1)[0]?.crecimiento_real}
        formattedValue="{formatNumber(total.slice(-1)[0]?.crecimiento_real, 1)} %"
        period="balio erantsi osoa, {total.slice(-1)[0]?.anio}. urtean"
        source="Eurostat"
        sparklineData={total.filter(d => d.crecimiento_real != null).map(d => ({...d, y: d.crecimiento_real}))}
    />
    <KpiCard
        title="Landunak 1.000 biztanleko"
        value={total.slice(-1)[0]?.ocupados_1000_hab}
        formattedValue={formatNumber(total.slice(-1)[0]?.ocupados_1000_hab, 0)}
        period="{formatNumber(total.slice(-1)[0]?.ocupados_miles / 1000, 1)} milioi landun {total.slice(-1)[0]?.anio}. urtean"
        source="Eurostat"
        sparklineData={total.map(d => ({...d, y: d.ocupados_1000_hab}))}
    />
    <KpiCard
        title="Produktibitatea landun bakoitzeko"
        value={total.slice(-1)[0]?.productividad_real}
        formattedValue="{formatNumber(total.slice(-1)[0]?.productividad_real, 0)} €"
        period="balio erantsia landun bakoitzeko {total.slice(-1)[0]?.anio}. urtean, {ultimo[0]?.anio_euros}. urteko eurotan"
        source="Eurostat"
        sparklineData={total.map(d => ({...d, y: d.productividad_real}))}
    />
    <KpiCard
        title="2019tik gehien hazi den sektorea"
        value={ultimo.filter(d => d.rama !== 'TOTAL' && !d.es_subrama).sort((a, b) => b.crec_desde_2019 - a.crec_desde_2019)[0]?.crec_desde_2019}
        formattedValue="+{formatNumber(ultimo.filter(d => d.rama !== 'TOTAL' && !d.es_subrama).sort((a, b) => b.crec_desde_2019 - a.crec_desde_2019)[0]?.crec_desde_2019, 1)} %"
        period="{ultimo.filter(d => d.rama !== 'TOTAL' && !d.es_subrama).sort((a, b) => b.crec_desde_2019 - a.crec_desde_2019)[0]?.sector}, balio erantsi erreala"
        source="Eurostat"
    />
</Grid>

## Erradiografia: {ultimo[0]?.anio}

Sektore bakoitzaren pisua ekoizpenean eta enpleguan. Ekoizpeneko pisua enplegukoa baino handiagoa den tokian, langile bakoitzak balio gehiago sortzen du (higiezinetan, batez ere alokairuengatik, norberaren etxebizitzan bizi denari egozten zaizkionak barne).

<DataTable data={ultimo} rows=20>
    <Column id=sector title="Sektorea"/>
    <Column id=peso_vab title="Ekoizpenaren %" fmt='0.0'/>
    <Column id=peso_empleo title="Enpleguaren %" fmt='0.0'/>
    <Column id=crecimiento_real title="Hazkunde erreala (%)" fmt='0.0' contentType=delta/>
    <Column id=crec_desde_2019 title="2019tik (%)" fmt='0.0' contentType=delta/>
    <Column id=ocupados_1000_hab title="Landunak 1.000 biztanleko" fmt='0.0'/>
    <Column id=productividad_real title="Balio erantsia landun bakoitzeko (€)" fmt='#,##0'/>
</DataTable>

Manufakturak Industria eta energiaren zati bat dira; horregatik ez dira bereiz batzen grafikoetan.

## Hazkunde erreala sektoreka

Sektore handi bakoitzaren balio erantsia euro konstanteetan, 2008 = 100 hartuta. Eraikuntzak oraindik ez du berreskuratu higiezinen burbuila lehertu aurreko maila.

<LineChart
    data={indice_vab}
    x=anio
    y=indice
    series=sector
    xFmt='0'
    yAxisTitle="2008 = 100"
    startingAtZero={false}
    title="Balio erantsi erreala sektoreka (2008 = 100)"
/>

## Enplegua sektoreka

Sektore bakoitzeko landunak 1.000 biztanleko; pilatuta, 1.000 biztanleko landun guztiak ematen dituzte. {total.slice(-1)[0]?.anio}. urtean {formatNumber(total.slice(-1)[0]?.ocupados_1000_hab, 0)} izan ziren, eta 2007an, berriz, {formatNumber(total.find(d => d.anio === 2007)?.ocupados_1000_hab, 0)}.

<AreaChart
    data={sin_total}
    x=anio
    y=ocupados_1000_hab
    series=sector
    xFmt='0'
    yAxisTitle="Landunak 1.000 biztanleko"
    title="Landunak 1.000 biztanleko, sektoreka"
/>

<LineChart
    data={sin_total}
    x=anio
    y=peso_empleo
    series=sector
    xFmt='0'
    yAxisTitle="Enpleguaren %"
    yFmt='0.0"%"'
    title="Sektore bakoitzaren pisua enpleguan (%)"
/>

## Produktibitatea

Balio erantsi erreala landun bakoitzeko ekonomia osoan, {ultimo[0]?.anio_euros}. urteko eurotan.

<LineChart
    data={total}
    x=anio
    y=productividad_real
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ landun bakoitzeko"
    startingAtZero={false}
    title="Lanaren itxurazko produktibitatea ({ultimo[0]?.anio_euros}. urteko eurotan)"
/>

---

**Iturriak:** [Eurostat, nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table) (balio erantsi gordina adarka) eta [nama_10_a10_e](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10_e/default/table) (landunak adarka, barne-kontzeptua). NACE sailkapeneko hamar adar handi; Eurostaten urteko batez besteko biztanleria.
