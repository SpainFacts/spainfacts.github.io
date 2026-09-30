---
description: "Nondik ateratzen den diru publikoa: zergak eta gizarte-kotizazioak Espainian, biztanleko, inflazioa kenduta eta BPGaren ehunekotan."
title: Diru-sarrera Publikoak eta Zerga-bilketa
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 7fdaa026f188
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

# Nondik datoz Espainiako baliabide publikoak?

Espainiako sektore publikoa hiru bide nagusiren bidez finantzatzen da batez ere: langileek eta enpresek ordaindutako **gizarte-kotizazioak**, errentaren eta mozkinaren gaineko **zuzeneko zergak** (PFEZ eta Sozietateen gaineko Zerga) eta kontsumoaren eta ekoizpenaren gaineko **zeharkako zergak** (BEZ eta Zerga Bereziak).

```sql base_deflactor
-- Año cuyos euros se usan como referencia (último año completo con IPC)
SELECT CAST(max(anio_base) AS INTEGER) AS anio_base FROM mother.deflactor
```

```sql ingresos_hab
-- Ingresos por habitante en euros constantes: millones / población (millones) * factor del deflactor
SELECT
    CAST(i.año AS INTEGER) AS anio,
    i.categoria,
    i.tipo_ingreso,
    i.millones_euros,
    i.porcentaje_pib,
    i.porcentaje_ingreso_total,
    i.millones_euros / b.poblacion_m * d.factor AS eur_hab_real
FROM mother.cuentas_ingresos i
JOIN mother.cuentas_balance_anual b ON CAST(b.año AS INTEGER) = CAST(i.año AS INTEGER)
JOIN mother.deflactor d ON CAST(d.anio AS INTEGER) = CAST(i.año AS INTEGER)
WHERE b.poblacion_m > 0
```

```sql ultimos_ingresos_totales
SELECT
    anio,
    sum(millones_euros) AS total_ingresos,
    sum(eur_hab_real) AS total_hab_real,
    sum(porcentaje_pib) AS total_pib
FROM ${ingresos_hab}
WHERE anio = (SELECT max(año) FROM mother.cuentas_ingresos)
GROUP BY anio
```

```sql resumen_tipos
SELECT
    sum(CASE WHEN tipo_ingreso = 'Cotizaciones' THEN porcentaje_ingreso_total END) AS cot_pct,
    sum(CASE WHEN tipo_ingreso = 'Impuestos Directos' THEN porcentaje_ingreso_total END) AS dir_pct,
    sum(CASE WHEN tipo_ingreso = 'Impuestos Indirectos' THEN porcentaje_ingreso_total END) AS ind_pct,
    sum(CASE WHEN tipo_ingreso = 'No Tributarios' THEN porcentaje_ingreso_total END) AS notrib_pct,
    max(CASE WHEN categoria = 'Cotizaciones Sociales' THEN millones_euros END) AS cot_mio,
    max(CASE WHEN categoria = 'Cotizaciones Sociales' THEN eur_hab_real END) AS cot_hab,
    max(CASE WHEN categoria = 'IRPF y Patrimonio' THEN millones_euros END) AS irpf_mio,
    max(CASE WHEN categoria = 'IRPF y Patrimonio' THEN eur_hab_real END) AS irpf_hab,
    max(CASE WHEN categoria = 'IRPF y Patrimonio' THEN porcentaje_ingreso_total END) AS irpf_pct,
    max(CASE WHEN categoria = 'IVA' THEN millones_euros END) AS iva_mio,
    max(CASE WHEN categoria = 'IVA' THEN eur_hab_real END) AS iva_hab,
    max(CASE WHEN categoria = 'IVA' THEN porcentaje_ingreso_total END) AS iva_pct
FROM ${ingresos_hab}
WHERE anio = (SELECT max(año) FROM mother.cuentas_ingresos)
```

```sql ingresos_por_categoria_ultimo
SELECT
    categoria,
    tipo_ingreso,
    eur_hab_real,
    millones_euros,
    porcentaje_pib,
    porcentaje_ingreso_total
FROM ${ingresos_hab}
WHERE anio = (SELECT max(año) FROM mother.cuentas_ingresos)
ORDER BY millones_euros DESC
```

```sql serie_ingresos_categoria
-- Euros por habitante a precios constantes (el deflactor empieza en 2002)
SELECT
    anio AS año,
    categoria,
    eur_hab_real
FROM ${ingresos_hab}
ORDER BY año ASC, eur_hab_real DESC
```

```sql serie_ingresos_tipo
-- Euros por habitante a precios constantes (el deflactor empieza en 2002)
SELECT
    anio AS año,
    tipo_ingreso,
    sum(eur_hab_real) AS eur_hab_real
FROM ${ingresos_hab}
GROUP BY 1, 2
ORDER BY 1 ASC
```

```sql serie_ingresos_real
-- Para las mini-gráficas: euros por habitante a precios constantes (mother.deflactor)
SELECT
    anio,
    categoria,
    eur_hab_real
FROM ${ingresos_hab}
WHERE categoria IN ('Cotizaciones Sociales', 'IRPF y Patrimonio', 'IVA')
  AND eur_hab_real IS NOT NULL
ORDER BY anio
```

<Grid cols=3>
    <KpiCard
        title="Gizarte Kotizazioak"
        value={resumen_tipos[0]?.cot_hab}
        formattedValue="{formatNumber(resumen_tipos[0]?.cot_hab, 0)} €"
        unit="/ biz."
        period="{formatNumber(resumen_tipos[0]?.cot_mio / 1000, 1)} mila M€ guztira · diru-sarreren {formatNumber(resumen_tipos[0]?.cot_pct, 1)}% · {ultimos_ingresos_totales[0]?.anio}"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
        sparklineData={serie_ingresos_real.filter(d => d.categoria === 'Cotizaciones Sociales').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="PFEZ eta Ondarea"
        value={resumen_tipos[0]?.irpf_hab}
        formattedValue="{formatNumber(resumen_tipos[0]?.irpf_hab, 0)} €"
        unit="/ biz."
        period="{formatNumber(resumen_tipos[0]?.irpf_mio / 1000, 1)} mila M€ guztira · diru-sarreren {formatNumber(resumen_tipos[0]?.irpf_pct, 1)}% · {ultimos_ingresos_totales[0]?.anio}"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
        sparklineData={serie_ingresos_real.filter(d => d.categoria === 'IRPF y Patrimonio').map(d => d.eur_hab_real)}
    />

    <KpiCard
        title="BEZ (Kontsumoa)"
        value={resumen_tipos[0]?.iva_hab}
        formattedValue="{formatNumber(resumen_tipos[0]?.iva_hab, 0)} €"
        unit="/ biz."
        period="{formatNumber(resumen_tipos[0]?.iva_mio / 1000, 1)} mila M€ guztira · diru-sarreren {formatNumber(resumen_tipos[0]?.iva_pct, 1)}% · {ultimos_ingresos_totales[0]?.anio}"
        direction="neutral"
        source="Eurostat (gov_10a_taxag)"
        sparklineData={serie_ingresos_real.filter(d => d.categoria === 'IVA').map(d => d.eur_hab_real)}
    />
</Grid>

<p class="text-xs text-gray-500">Webgune honen printzipioa: zenbatekoak <b>biztanleko</b> eta <b>inflazioa kenduta</b> erakusten dira, {urteko(base_deflactor[0]?.anio_base)} eurotan, INEren urteko batez besteko KPIaren arabera, urte desberdinetako zifrak alderagarriak izan daitezen. Euro korronteetako guztizkoak bigarren mailako datu gisa agertzen dira; ehunekoek (diru-sarrerena edo BPGarena) ez dute doikuntzarik behar.</p>

---

## 1. Espainiako Diru-sarrera Publikoen Osaera ({ultimos_ingresos_totales[0].anio})

{urtean(ultimos_ingresos_totales[0]?.anio)}, Administrazio Publiko guztien diru-sarrerak **{formatNumber(ultimos_ingresos_totales[0]?.total_hab_real, 0)} euro biztanleko** izan ziren ({urteko(base_deflactor[0]?.anio_base)} eurotan; {formatNumber(ultimos_ingresos_totales[0]?.total_ingresos / 1000, 1)} mila milioi guztira, BPGaren {formatNumber(ultimos_ingresos_totales[0]?.total_pib, 1)}%).

<BarChart
    data={ingresos_por_categoria_ultimo}
    x=categoria
    y=eur_hab_real
    yAxisTitle="Euro biztanleko ({urteko(base_deflactor[0]?.anio_base)} euroak)"
    yFmt=num0
    title="Bilketa biztanleko, diru-sarrera motaren arabera ({ultimos_ingresos_totales[0]?.anio}, {urteko(base_deflactor[0]?.anio_base)} euroak)"
    swapXY={true}
/>

<DataTable data={ingresos_por_categoria_ultimo} title="Diru-sarreren xehetasuna ({ultimos_ingresos_totales[0].anio})">
    <Column id=categoria title="Diru-sarrera mota" />
    <Column id=tipo_ingreso title="Zerga mota" />
    <Column id=eur_hab_real title="Biztanleko" fmt='#,##0 €' />
    <Column id=porcentaje_ingreso_total title="Guztizkoaren %" fmt='0.0"%"' />
    <Column id=porcentaje_pib title="BPGaren %" fmt='0.0"%"' />
    <Column id=millones_euros title="Bilketa osoa (M€ korronteak)" fmt='#,##0' />
</DataTable>

---

## 2. Diru-sarreren Bilakaera Historikoa Zerga Motaren arabera

Mota bakoitzeko diru-sarrerak biztanleko, {urteko(base_deflactor[0]?.anio_base)} eurotan (inflazioa kenduta), 2002tik, urteko KPIa eskuragarri duen lehen urtetik:

<AreaChart
    data={serie_ingresos_tipo}
    x=año
    y=eur_hab_real
    series=tipo_ingreso
    yAxisTitle="Euro biztanleko ({urteko(base_deflactor[0]?.anio_base)} euroak)"
    yFmt=num0
    title="Diru-sarrera publikoak biztanleko eta zerga motaren arabera ({urteko(base_deflactor[0]?.anio_base)} euroak, inflazioa kenduta)"
/>

---

## 3. Nola banatzen da zerga-karga?

- **Gizarte Segurantzarako kotizazioak ({formatNumber(resumen_tipos[0].cot_pct, 1)}%):** diru-sarrera publikoen iturri nagusia, kotizaziopeko pentsioak eta langabezia-prestazioak mantentzeko erabiltzen dena.
- **Zuzeneko zergak ({formatNumber(resumen_tipos[0].dir_pct, 1)}%):** zuzenean zergapetzen dituzte herritarren errenta (PFEZ), merkataritza-sozietateek aitortutako mozkinak, ondarea eta oinordetzak.
- **Zeharkako zergak ({formatNumber(resumen_tipos[0].ind_pct, 1)}%):** kontsumo orokorra (BEZ) eta produktu espezifikoak zergapetzen dituzte, hala nola erregaiak, tabakoa, alkohola eta elektrizitatea (Zerga Bereziak), baita ekoizpenaren gaineko beste zerga batzuk ere.
- **Zergaz kanpoko diru-sarrerak eta EBko funtsak ({formatNumber(resumen_tipos[0].notrib_pct, 1)}%):** zerbitzu publikoen salmentak eta tasak, jabetzaren errentak (interesak, dibidenduak) eta jasotako transferentziak, Next Generation EU funts europarrak barne.

<small>Metodologia: zergak eta kotizazioak Eurostatetik datoz (gov_10a_taxag) eta diru-sarrera osoak gov_10a_main-etik. «Beste zerga batzuk» eta «Zergaz kanpoko diru-sarrerak eta EBko funtsak» kategoriak diferentziaz kalkulatzen dira, batura diru-sarrera oso ofizialekin bat etor dadin.</small>

---

## Iturri Ofizialak
- **[Eurostat - Zergak eta gizarte-kotizazioak figuraka (gov_10a_taxag)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_taxag):** SEC 2010aren arabera harmonizatutako bilketa.
- **[Eurostat - Administrazio publikoen kontuak (gov_10a_main)](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_main):** Administrazio Publikoen diru-sarrera osoak.
- **[Estatuko Zerga Administrazioaren Agentzia (AEAT)](https://sede.agenciatributaria.gob.es/Sede/estadisticas/recaudacion-tributaria.html):** bilketari buruzko urteko eta hileko txostenak.
- **[Estatuko Administrazioaren Kontu-hartzailetza Nagusia (IGAE)](https://www.igae.pap.hacienda.gob.es/):** Sektore Publikoaren Kontu Ekonomikoak eta Kontabilitate Nazionala.
