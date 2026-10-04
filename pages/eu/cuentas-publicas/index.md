---
description: "Espainiako administrazio publikoen diru-sarrerak, gastuak, defizita eta zorra, biztanleko, inflazioa kenduta eta BPGaren ehunekotan."
title: Kontu Publikoak · Espainiaren Urteko Txostena
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 522e6f9ccc1f
---

<script>
    import { formatNumber, formatCurrency, formatCompact } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../src/lib/components/Comparativa.svelte';
    import SankeyPresupuesto from '../../../../../../src/lib/components/SankeyPresupuesto.svelte';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
</script>

# Espainiako Kontu Publikoen "10-K" txostena

Burtsan kotizatzen duten enpresek merkatuen aurrean aurkezten duten urteko txostenean oinarrituta, atal honek **Espainiako Erresumaren balantze bateratua** aurkezten du: *zenbat sartzen du Estatuak? zertan gastatzen da zergadunen dirua? zein da urteko defizita eta nola aldatzen da zor publikoa?*

```sql base_deflactor
-- Año cuyos euros se usan como referencia (último año completo con IPC)
SELECT CAST(max(anio_base) AS INTEGER) AS anio_base FROM mother.deflactor
```

```sql balance_reciente
-- Importes por habitante y en euros constantes (ya calculados en la tabla)
SELECT
    b.anio,
    b.ingresos_totales_mrd,
    b.gastos_totales_mrd,
    b.saldo_deficit_mrd,
    b.saldo_deficit_pib,
    b.deuda_publica_mrd,
    b.deuda_pib,
    b.ingresos_eur_hab_real AS ingresos_hab_real,
    b.gastos_eur_hab_real AS gastos_hab_real
FROM mother.cuentas_balance_anual b
ORDER BY b.anio DESC
LIMIT 2
```

```sql serie_balance_historico
-- Euros por habitante a precios constantes (el deflactor empieza en 1996)
SELECT
    b.anio AS año,
    b.ingresos_eur_hab_real AS "Ingresos por habitante",
    b.gastos_eur_hab_real AS "Gastos por habitante",
    b.saldo_eur_hab_real AS "Déficit / Superávit por habitante"
FROM mother.cuentas_balance_anual b
WHERE b.ingresos_eur_hab_real IS NOT NULL
ORDER BY año ASC
```

```sql serie_deficit_pib
SELECT
    anio AS año,
    saldo_deficit_pib AS deficit_pib
FROM mother.cuentas_balance_anual
ORDER BY año ASC
```

```sql serie_deuda_pib
SELECT
    anio AS año,
    deuda_pib
FROM mother.cuentas_balance_anual
ORDER BY año ASC
```

```sql sankey_anio
-- Último ejercicio con desglose publicado tanto de ingresos como de gastos
SELECT least(
    (SELECT max(anio) FROM mother.cuentas_ingresos),
    (SELECT max(anio) FROM mother.cuentas_gastos)
) AS anio
```

```sql ingresos_sankey
SELECT
    categoria,
    millones_euros
FROM mother.cuentas_ingresos
WHERE anio = (SELECT least(max(i.anio), (SELECT max(g.anio) FROM mother.cuentas_gastos g)) FROM mother.cuentas_ingresos i)
ORDER BY millones_euros DESC
```

```sql gastos_sankey
SELECT
    funcion_cofog,
    millones_euros
FROM mother.cuentas_gastos
WHERE anio = (SELECT least(max(g.anio), (SELECT max(i.anio) FROM mother.cuentas_ingresos i)) FROM mother.cuentas_gastos g)
ORDER BY millones_euros DESC
```

```sql subsectores_ultimo
SELECT
    s.anio,
    s.subsector,
    s.gasto_mrd,
    s.ingreso_mrd,
    s.saldo_deficit_mrd,
    s.peso_gasto_pct,
    s.gasto_eur_hab_real AS gasto_hab_real,
    s.saldo_eur_hab_real AS saldo_hab_real
FROM mother.cuentas_subsectores s
WHERE s.anio = (SELECT max(anio) FROM mother.cuentas_subsectores)
ORDER BY s.gasto_mrd DESC
```

```sql rango_historico
-- Rango de la serie en euros constantes por habitante
SELECT min(año) AS desde, max(año) AS hasta
FROM ${serie_balance_historico}
```

```sql serie_balance_real
-- Para las mini-gráficas: euros por habitante a precios constantes (mother.deflactor)
SELECT
    año AS anio,
    "Ingresos por habitante" AS ingresos_hab_real,
    "Gastos por habitante" AS gastos_hab_real
FROM ${serie_balance_historico}
ORDER BY anio
```

<!-- KPI Ribbon: Resumen Anual del Estado -->
<Grid cols=4>
    <KpiCard
        title="Diru-sarrerak biztanleko"
        value={balance_reciente[0]?.ingresos_hab_real}
        formattedValue="{formatNumber(balance_reciente[0]?.ingresos_hab_real, 0)} €"
        unit="/ biz."
        period="{formatNumber(balance_reciente[0]?.ingresos_totales_mrd, 1)} mila M€ guztira · {balance_reciente[0]?.anio} ({urteko(base_deflactor[0]?.anio_base)} euroak)"
        change={(((balance_reciente[0]?.ingresos_hab_real - balance_reciente[1]?.ingresos_hab_real) / balance_reciente[1]?.ingresos_hab_real) * 100).toFixed(1)}
        changeUnit="%"
        changePeriod="urte artekoa, inflazioa kenduta"
        direction="positive-up"
        source="Eurostat (gov_10a_main)"
        sparklineData={serie_balance_real.filter(d => d.ingresos_hab_real != null).map(d => d.ingresos_hab_real)}
        href="/eu/cuentas-publicas/ingresos"
    />

    <KpiCard
        title="Gastua biztanleko"
        value={balance_reciente[0]?.gastos_hab_real}
        formattedValue="{formatNumber(balance_reciente[0]?.gastos_hab_real, 0)} €"
        unit="/ biz."
        period="{formatNumber(balance_reciente[0]?.gastos_totales_mrd, 1)} mila M€ guztira · {balance_reciente[0]?.anio} ({urteko(base_deflactor[0]?.anio_base)} euroak)"
        change={(((balance_reciente[0]?.gastos_hab_real - balance_reciente[1]?.gastos_hab_real) / balance_reciente[1]?.gastos_hab_real) * 100).toFixed(1)}
        changeUnit="%"
        changePeriod="urte artekoa, inflazioa kenduta"
        direction="neutral"
        source="Eurostat (gov_10a_main)"
        sparklineData={serie_balance_real.filter(d => d.gastos_hab_real != null).map(d => d.gastos_hab_real)}
        href="/eu/cuentas-publicas/gastos"
    />

    <KpiCard
        title="Urteko Defizit Fiskala"
        value={balance_reciente[0].saldo_deficit_pib}
        formattedValue="BPGaren {formatNumber(balance_reciente[0].saldo_deficit_pib, 1)}%"
        period="{balance_reciente[0].anio} ekitaldia"
        change={(balance_reciente[0].saldo_deficit_pib - balance_reciente[1].saldo_deficit_pib).toFixed(1)}
        changeUnit="pp"
        changePeriod="aurreko urtearekiko"
        direction="positive-down"
        source="Eurostat (gov_10a_main)"
        sparklineData={serie_deficit_pib.filter(d => d.deficit_pib != null).map(d => d.deficit_pib)}
    />

    <KpiCard
        title="Zor Publikoa / BPG"
        value={balance_reciente[0].deuda_pib}
        formattedValue="{formatNumber(balance_reciente[0].deuda_pib, 1)}%"
        period="{formatNumber(balance_reciente[0].deuda_publica_mrd, 1)} mila M€ · {balance_reciente[0].anio}"
        change={(balance_reciente[0].deuda_pib - balance_reciente[1].deuda_pib).toFixed(1)}
        changeUnit="pp"
        changePeriod="aurreko urtearekiko"
        direction="positive-down"
        source="Eurostat (PDE)"
        sparklineData={serie_deuda_pib.filter(d => d.deuda_pib != null).map(d => d.deuda_pib)}
        href="/eu/varios/indicadores/deuda_publica_pib"
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('deuda_publica')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'deuda_publica')} />


<p class="text-xs text-gray-500">Webgune honen printzipioa: euroetako zenbatekoak <b>biztanleko</b> erakusten dira (biztanleria hazten delako soilik hazi ez daitezen) eta <b>inflazioa kenduta</b>, {urteko(base_deflactor[0]?.anio_base)} eurotan, INEren urteko batez besteko KPIaren arabera. Euro korronteetako guztizkoak bigarren mailako datu gisa agertzen dira. BPGaren ehunekoek ez dute doikuntzarik behar.</p>

---

## 1. Diru Publikoaren Ibilbidea ({urteko(sankey_anio[0].anio)} Aurrekontu-fluxua)

Fluxu-diagrama honek erakusten du nondik datozen Administrazio Publikoen diru-sarrerak eta zein partida zehatzetan erabiltzen diren (Eurostatek banakapen osoa argitaratu duen azken ekitaldia). Bi aldeen arteko aldea urteko defizita da, zorrarekin finantzatzen dena:

<SankeyPresupuesto
    dataIngresos={ingresos_sankey}
    dataGastos={gastos_sankey}
    title="Espainiako Kontu Publikoen fluxua ({sankey_anio[0].anio})"
    subtitle="Zerga eta kotizazioetatik Estatuaren gastu-funtzioetara (milioi €)"
    height="540px"
/>

<Grid cols=2>
    <div class="p-4 rounded-lg bg-blue-50 dark:bg-blue-950/40 border border-blue-200 dark:border-blue-800">
        <h3 class="font-bold text-blue-900 dark:text-blue-300 mb-1"><span aria-hidden="true">📥</span> Diru-sarreretan sakondu nahi duzu?</h3>
        <p class="text-xs text-blue-700 dark:text-blue-400 mb-2">Kontsultatu PFEZ, BEZ, Sozietateak, Kotizazioak eta tasa publikoen bidezko bilketa.</p>
        <a href="/eu/cuentas-publicas/ingresos" class="text-xs font-bold text-blue-600 dark:text-blue-300 hover:underline">
            Ikusi Diru-sarrera Publikoei buruzko txosten osoa →
        </a>
    </div>

    <div class="p-4 rounded-lg bg-purple-50 dark:bg-purple-950/40 border border-purple-200 dark:border-purple-800">
        <h3 class="font-bold text-purple-900 dark:text-purple-300 mb-1"><span aria-hidden="true">📤</span> Gastuen xehetasuna ikusi nahi duzu?</h3>
        <p class="text-xs text-purple-700 dark:text-purple-400 mb-2">Jakin zenbat gastatzen duen Estatuak biztanleko Osasunean, Pentsioetan, Hezkuntzan eta Defentsan.</p>
        <a href="/eu/cuentas-publicas/gastos" class="text-xs font-bold text-purple-600 dark:text-purple-300 hover:underline">
            Ikusi Gastuei eta Biztanleko Kostuari buruzko txosten osoa →
        </a>
    </div>

    <div class="p-4 rounded-lg bg-teal-50 dark:bg-teal-950/40 border border-teal-200 dark:border-teal-800">
        <h3 class="font-bold text-teal-900 dark:text-teal-300 mb-1"><span aria-hidden="true">🏛️</span> Zenbat enplegatu publiko daude?</h3>
        <p class="text-xs text-teal-700 dark:text-teal-400 mb-2">Zenbat diren administrazio eta lurralde bakoitzean, nola aldatu diren, zenbat kobratzen duten sektore pribatuarekin alderatuta eta zenbat balio duten.</p>
        <a href="/eu/cuentas-publicas/empleo-publico" class="text-xs font-bold text-teal-700 dark:text-teal-300 hover:underline">
            Ikusi Enplegu Publikoari buruzko txostena →
        </a>
    </div>

    <div class="p-4 rounded-lg bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-800">
        <h3 class="font-bold text-amber-900 dark:text-amber-300 mb-1"><span aria-hidden="true">👵</span> Zenbat balio dute pentsioek?</h3>
        <p class="text-xs text-amber-700 dark:text-amber-400 mb-2">Batez besteko pentsioa inflazioa kenduta, afiliatuak pentsioko, gastua BPGaren ehunekotan EBrekin alderatuta eta erkidegoen arteko aldeak.</p>
        <a href="/eu/cuentas-publicas/pensiones" class="text-xs font-bold text-amber-700 dark:text-amber-300 hover:underline">
            Ikusi Pentsioei buruzko txostena →
        </a>
    </div>
</Grid>

---

## 2. Balantze Historikoa: Diru-sarrerak eta Gastuak ({rango_historico[0].desde} - {rango_historico[0].hasta})

Sektore publikoak sartzen duenaren eta ordaintzen duenaren arteko urteko aldeak **aurrekontu-saldoa** zehazten du (superabita positiboa bada, defizita negatiboa bada). Urteen arteko konparazioa zuzena izan dadin, zifrak biztanleko eta {urteko(base_deflactor[0]?.anio_base)} eurotan adierazten dira (seriea {urtean(rango_historico[0]?.desde)} hasten da, urteko KPIa eskuragarri duen lehen urtean):

<LineChart
    data={serie_balance_historico}
    x=año
    y={["Ingresos por habitante", "Gastos por habitante"]}
    yAxisTitle="Euro biztanleko ({urteko(base_deflactor[0]?.anio_base)} euroak)"
    yFmt=num0
    title="Diru-sarrera eta gastu publikoak biztanleko ({urteko(base_deflactor[0]?.anio_base)} euroak, inflazioa kenduta)"
    startingAtZero={false}
/>

<BarChart
    data={serie_deficit_pib}
    x=año
    y=deficit_pib
    yAxisTitle="Defizita / Superabita (BPGaren %)"
    title="Administrazio publikoen finantzaketa-ahalmena (+) edo -beharra (-) (BPGaren %)"
/>

---

## 3. Nork kudeatzen du gastu publikoa Espainian?

Espainia estatu deszentralizatua da, eta gastu-eskumenak lau azpisektore instituzionalen artean banatzen dira. Azpisektore bakoitzaren zifrak ez daude elkarren artean bateratuta (administrazioen arteko transferentziak barne hartzen dituzte); horregatik, gastu osoaren gaineko haien pisuek 100 % baino gehiago batzen dute:

<Grid cols=2>

<DataTable data={subsectores_ultimo} title="Banakapena Administrazio-mailaren arabera ({subsectores_ultimo[0]?.anio})">
    <Column id=subsector title="Azpisektore Instituzionala" />
    <Column id=gasto_hab_real title="Gastua biztanleko" fmt='#,##0 €' />
    <Column id=peso_gasto_pct title="Gastuaren %" fmt='0.0"%"' />
    <Column id=saldo_hab_real title="Saldoa biztanleko" fmt='#,##0 €' />
    <Column id=gasto_mrd title="Gastu osoa (mila M€)" fmt='#,##0.0' />
</DataTable>

<div>
    <BarChart
        data={subsectores_ultimo}
        x=subsector
        y=gasto_hab_real
        yAxisTitle="Euro biztanleko"
        yFmt=num0
        title="Azpisektore bakoitzaren gastua biztanleko ({subsectores_ultimo[0]?.anio}, {urteko(base_deflactor[0]?.anio_base)} euroak)"
        swapXY={true}
    />
</div>

</Grid>

- **Administrazio Zentrala (Estatua):** ministerioak, polizia nazionala, defentsa, interes orokorreko azpiegiturak eta zorraren interesen ordainketaren zatirik handiena finantzatzen ditu.
- **Autonomia Erkidegoak (AE):** herritarren ongizatearen bi zutabe nagusiak kudeatzen dituzte: **osasun publikoa** eta **hezkuntza**.
- **Gizarte Segurantzaren Funtsak:** langileei eta erretiratuei pentsioak eta sorospenak ordaintzen espezializatutako erakundea.
- **Toki Korporazioak (Udalak eta Diputazioak):** hirigintzaz, hondakinen bilketaz, hiri-garraioaz eta udal-zerbitzuez arduratzen dira.

---

## 4. Zor Publikoaren Bilakaera BPGaren gainean

Urteetan metatutako defizita **Zor Publikoa** jaulkiz finantzatzen da (Altxorraren letrak, bonuak eta obligazioak):

<LineChart
    data={serie_deuda_pib}
    x=año
    y=deuda_pib
    yAxisTitle="Zor Publikoa (BPGaren %)"
    title="Espainiako Zor Publikoaren bilakaera (BPGaren %, Gehiegizko Defizitaren Prozeduraren arabera)"
    startingAtZero={false}
/>

---

## Iturri Ofizialak eta Trazabilitatea
- **[Estatuko Administrazioaren Kontu-hartzailetza Nagusia (IGAE)](https://www.igae.pap.hacienda.gob.es/):** Espainiako Sektore Publikoaren Kontabilitate Nazionala.
- **[Espainiako Bankua - Buletin Estatistikoa](https://www.bde.es/):** zor publikoaren eta administrazio publikoen finantza-pasiboen serie historikoak.
- **[Eurostat - Government Finance Statistics (gov_10a_main)](https://ec.europa.eu/eurostat/web/government-finance-statistics):** Kontuen Europako Sistemaren (SEC 2010) arabera harmonizatutako kontu bateratuak.
