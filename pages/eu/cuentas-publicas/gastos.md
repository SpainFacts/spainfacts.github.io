---
description: "Zertan gastatzen duen Espainiak diru publikoa: gastua funtzioen arabera (pentsioak, osasuna, hezkuntza...), biztanleko eta inflazioa kenduta, eta haren pisua BPGan."
title: Gastu Publikoa eta Aurrekontuaren Norakoa
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: ffd69e06b546
---

<script>
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
</script>

```sql base_deflactor
-- Año cuyos euros se usan como referencia (último año completo con IPC)
SELECT CAST(max(anio_base) AS INTEGER) AS anio_base FROM mother.deflactor
```

```sql gastos_ultimo
SELECT
    g.anio,
    g.funcion_cofog,
    g.categoria_macro,
    g.millones_euros,
    g.porcentaje_gasto_total,
    g.porcentaje_pib,
    g.gasto_eur_hab_real AS gasto_hab_real
FROM mother.cuentas_gastos g
WHERE g.anio = (SELECT max(anio) FROM mother.cuentas_gastos)
ORDER BY g.millones_euros DESC
```

```sql resumen_gastos
-- Por habitante en euros constantes (gasto_eur_hab_real, ya calculado en la tabla)
SELECT
    g.anio,
    sum(g.millones_euros) AS total_mio,
    sum(g.gasto_eur_hab_real) AS total_hab_real,
    sum(g.porcentaje_pib) AS total_pib,
    sum(CASE WHEN g.categoria_macro = 'Gasto Social' THEN g.porcentaje_gasto_total END) AS social_pct,
    max(CASE WHEN g.funcion_cofog = 'Protección Social y Pensiones' THEN g.millones_euros END) AS pens_mio,
    max(CASE WHEN g.funcion_cofog = 'Protección Social y Pensiones' THEN g.gasto_eur_hab_real END) AS pens_hab,
    max(CASE WHEN g.funcion_cofog = 'Protección Social y Pensiones' THEN g.porcentaje_gasto_total END) AS pens_pct,
    max(CASE WHEN g.funcion_cofog = 'Sanidad Pública' THEN g.millones_euros END) AS san_mio,
    max(CASE WHEN g.funcion_cofog = 'Sanidad Pública' THEN g.gasto_eur_hab_real END) AS san_hab,
    max(CASE WHEN g.funcion_cofog = 'Sanidad Pública' THEN g.porcentaje_gasto_total END) AS san_pct,
    max(CASE WHEN g.funcion_cofog = 'Educación' THEN g.millones_euros END) AS edu_mio,
    max(CASE WHEN g.funcion_cofog = 'Educación' THEN g.gasto_eur_hab_real END) AS edu_hab,
    max(CASE WHEN g.funcion_cofog = 'Educación' THEN g.porcentaje_gasto_total END) AS edu_pct,
    max(CASE WHEN g.funcion_cofog = 'Intereses de la Deuda' THEN g.porcentaje_gasto_total END) AS int_pct,
    max(CASE WHEN g.funcion_cofog = 'Asuntos Económicos y Transporte' THEN g.porcentaje_gasto_total END) AS eco_pct,
    max(CASE WHEN g.funcion_cofog = 'Orden Público y Seguridad' THEN g.porcentaje_gasto_total END) AS seg_pct,
    max(CASE WHEN g.funcion_cofog = 'Defensa' THEN g.porcentaje_gasto_total END) AS def_pct
FROM mother.cuentas_gastos g
WHERE g.anio = (SELECT max(anio) FROM mother.cuentas_gastos)
GROUP BY g.anio
```

```sql poblacion_ultimo
SELECT poblacion / 1e6 AS poblacion_m
FROM mother.cuentas_balance_anual
WHERE anio = (SELECT max(anio) FROM mother.cuentas_gastos)
```

```sql serie_gastos_macro
-- Euros por habitante a precios constantes (el deflactor empieza en 1996)
SELECT
    g.anio AS año,
    g.categoria_macro,
    sum(g.gasto_eur_hab_real) AS eur_hab_real
FROM mother.cuentas_gastos g
WHERE g.gasto_eur_hab_real IS NOT NULL
GROUP BY 1, 2
ORDER BY 1 ASC
```

```sql serie_gastos_funcion
SELECT
    g.anio AS año,
    g.funcion_cofog,
    g.gasto_eur_hab_real AS eur_hab_real
FROM mother.cuentas_gastos g
WHERE g.gasto_eur_hab_real IS NOT NULL
ORDER BY 1 ASC, 3 DESC
```

```sql serie_gastos_real
-- Para las mini-gráficas: euros por habitante a precios constantes (mother.deflactor)
SELECT
    año AS anio,
    funcion_cofog,
    eur_hab_real
FROM ${serie_gastos_funcion}
WHERE funcion_cofog IN ('Protección Social y Pensiones', 'Sanidad Pública', 'Educación')
  AND eur_hab_real IS NOT NULL
ORDER BY anio
```

# Zertan gastatzen du Estatuak eta zenbat balio du herritar bakoitzeko?

Espainiako gastu publiko bateratua **{formatNumber(resumen_gastos[0]?.total_hab_real, 0)} euro biztanleko** izan zen {urtean(resumen_gastos[0]?.anio)} ({formatNumber(resumen_gastos[0]?.total_mio / 1000, 1)} mila milioi guztira, BPGaren {formatNumber(resumen_gastos[0]?.total_pib, 1)}%). Aurrekontuaren zatirik handiena **Ongizate Estatuaren** funtzioetara bideratzen da: gizarte-babesak eta pentsioek, osasunak eta hezkuntzak **gastu publiko osoaren {formatNumber(resumen_gastos[0].social_pct, 1)}%** hartzen dute.

<Grid cols=3>
    <KpiCard
        title="Pentsioak eta Gizarte Babesa"
        value={resumen_gastos[0]?.pens_hab}
        formattedValue="{formatNumber(resumen_gastos[0]?.pens_hab, 0)} €"
        unit="/ biz."
        period="{formatNumber(resumen_gastos[0]?.pens_mio / 1000, 1)} mila M€ guztira · gastuaren {formatNumber(resumen_gastos[0]?.pens_pct, 1)}% · {resumen_gastos[0]?.anio}"
        direction="neutral"
        source="Eurostat (COFOG GF10)"
        sparklineData={serie_gastos_real.filter(d => d.funcion_cofog === 'Protección Social y Pensiones').map(d => ({...d, y: d.eur_hab_real}))}
    />

    <KpiCard
        title="Osasun Publikoa"
        value={resumen_gastos[0]?.san_hab}
        formattedValue="{formatNumber(resumen_gastos[0]?.san_hab, 0)} €"
        unit="/ biz."
        period="{formatNumber(resumen_gastos[0]?.san_mio / 1000, 1)} mila M€ guztira · gastuaren {formatNumber(resumen_gastos[0]?.san_pct, 1)}% · {resumen_gastos[0]?.anio}"
        direction="neutral"
        source="Eurostat (COFOG GF07)"
        sparklineData={serie_gastos_real.filter(d => d.funcion_cofog === 'Sanidad Pública').map(d => ({...d, y: d.eur_hab_real}))}
    />

    <KpiCard
        title="Hezkuntza"
        value={resumen_gastos[0]?.edu_hab}
        formattedValue="{formatNumber(resumen_gastos[0]?.edu_hab, 0)} €"
        unit="/ biz."
        period="{formatNumber(resumen_gastos[0]?.edu_mio / 1000, 1)} mila M€ guztira · gastuaren {formatNumber(resumen_gastos[0]?.edu_pct, 1)}% · {resumen_gastos[0]?.anio}"
        direction="neutral"
        source="Eurostat (COFOG GF09)"
        sparklineData={serie_gastos_real.filter(d => d.funcion_cofog === 'Educación').map(d => ({...d, y: d.eur_hab_real}))}
    />
</Grid>

<p class="text-xs text-gray-500">Webgune honen printzipioa: zenbatekoak <b>biztanleko</b> eta <b>inflazioa kenduta</b> erakusten dira, {urteko(base_deflactor[0]?.anio_base)} eurotan, INEren urteko batez besteko KPIaren arabera, urte desberdinetako zifrak alderagarriak izan daitezen. Euro korronteetako guztizkoak bigarren mailako datu gisa agertzen dira; ehunekoek (gastuarenak edo BPGarenak) ez dute doikuntzarik behar.</p>

---

## 1. Urteko Gastua Biztanleko Espainian ({resumen_gastos[0].anio})

Funtzio bakoitzaren gastua Espainiako ~{formatNumber(poblacion_ultimo[0].poblacion_m, 1)} milioi egoiliarren artean zatituta (urteko batez besteko biztanleria), hau da zerbitzu publiko bakoitzak biztanleko duen urteko batez besteko kostua:

<BarChart
    data={gastos_ultimo}
    x=funcion_cofog
    y=gasto_hab_real
    yAxisTitle="Euro biztanleko urtean ({urteko(base_deflactor[0]?.anio_base)} euroak)"
    yFmt=num0
    title="Gastu publikoa biztanleko urtean, funtzioaren arabera ({resumen_gastos[0]?.anio}, {urteko(base_deflactor[0]?.anio_base)} euroak)"
    swapXY={true}
/>

<DataTable data={gastos_ultimo} title="Gastuaren Sailkapen Funtzionala (COFOG {resumen_gastos[0].anio})">
    <Column id=funcion_cofog title="Gastu-funtzioa" />
    <Column id=categoria_macro title="Makro-kategoria" />
    <Column id=gasto_hab_real title="Biztanleko" fmt='#,##0 €' />
    <Column id=porcentaje_gasto_total title="Gastu osoaren %" fmt='0.0"%"' />
    <Column id=porcentaje_pib title="BPGaren %" fmt='0.0"%"' />
    <Column id=millones_euros title="Guztira (M€ korronteak)" fmt='#,##0' />
</DataTable>

---

## 2. Gastuaren Bilakaera Bloke Handien arabera

Bloke bakoitzaren gastua biztanleko, {urteko(base_deflactor[0]?.anio_base)} eurotan (inflazioa kenduta), 1996tik, urteko KPIa eskuragarri duen lehen urtetik:

<AreaChart
    data={serie_gastos_macro}
    x=año
    y=eur_hab_real
    series=categoria_macro
    yAxisTitle="Euro biztanleko ({urteko(base_deflactor[0]?.anio_base)} euroak)"
    yFmt=num0
    title="Gastu publikoa biztanleko eta bloke funtzionalaren arabera ({urteko(base_deflactor[0]?.anio_base)} euroak, inflazioa kenduta)"
/>

---

## 3. Gastu-funtzio Nagusien Banakapena ({resumen_gastos[0].anio})

- **Gizarte Babesa eta Pentsioak ({formatNumber(resumen_gastos[0].pens_pct, 1)}%):** sektore publikoaren ordainketarik handiena; erretiro-, alarguntasun- eta ezintasun-pentsio kotizaziodunak barne hartzen ditu, baita langabezia- eta mendekotasun-sorospenak ere.
- **Osasun Publikoa ({formatNumber(resumen_gastos[0].san_pct, 1)}%):** batez ere 17 autonomia-erkidegoek kudeatzen dute, ospitaleak, osasun-zentroak, mediku-langileak eta farmazia-gastua finantzatzeko.
- **Hezkuntza ({formatNumber(resumen_gastos[0].edu_pct, 1)}%):** haur, lehen eta bigarren hezkuntzaren, lanbide-heziketaren eta unibertsitate publikoen finantzaketa.
- **Zor Publikoaren Interesak ({formatNumber(resumen_gastos[0].int_pct, 1)}%):** Estatuaren bonu eta obligazioen jabe diren inbertitzaileei interesen aldizkako ordainketa (COFOG GF0107, hemen Zerbitzu Publiko Orokorretatik bereizia); zerbitzu zuzenik sortzen ez duen finantza-kostua da, baina aurrekontu-ahalmena baldintzatzen du.
- **Ekonomia, Garraioa eta Azpiegiturak ({formatNumber(resumen_gastos[0].eco_pct, 1)}%):** inbertsioa trenbide-sarean (AVE/Aldiriak), errepideetan, aireportuetan, nekazaritzan eta trantsizio energetikoan.
- **Herritarren Segurtasuna eta Justizia ({formatNumber(resumen_gastos[0].seg_pct, 1)}%):** Segurtasun Indar eta Kidegoen mantentzea (Polizia Nazionala, Guardia Civil, polizia autonomikoak), auzitegiak eta espetxeak.
- **Defentsa ({formatNumber(resumen_gastos[0].def_pct, 1)}%):** Indar Armatuen mantentzea (Lehorreko Armada, Itsas Armada eta Aire eta Espazio Armada) eta modernizazio militarreko programak.

---

## Iturri Ofizialak
- **[Gastuaren COFOG Sailkapen Funtzionala (Eurostat gov_10a_exp)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp):** administrazio publikoen gastu bateratua funtzioaren arabera, Nazio Batuen eta Europar Batasunaren sailkapen estandarizatuaren arabera.
- **[BPG prezio korronteetan (Eurostat nama_10_gdp)](https://ec.europa.eu/eurostat/databrowser/view/nama_10_gdp) eta [batez besteko biztanleria (nama_10_pe)](https://ec.europa.eu/eurostat/databrowser/view/nama_10_pe):** BPGaren gaineko ehunekoen eta biztanleko gastuaren izendatzaileak.
- **[Estatuko Aurrekontu Orokorrak (Ogasun Ministerioa)](https://www.sepg.pap.hacienda.gob.es/):** ministerioen eta erakunde publikoen gastu-serieak.
