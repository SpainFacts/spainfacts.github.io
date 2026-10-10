---
title: Gizartea
description: "Kriminalitatea, osasuna, immigrazioa, errenta eta pobrezia, hezkuntza eta hauteskundeak Espainian, datu ofizialekin, biztanleko eta EBrekin alderatuta."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: b5a51b86957e
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
</script>

```sql crimen
SELECT anio, infracciones, tasa_1000
FROM mother.crimen_balance
WHERE nivel = 'pais' AND categoria = 'Total infracciones penales'
ORDER BY anio DESC
LIMIT 1
```

```sql crimen_serie
-- Tasa por 1.000 habitantes: Balance (2019-) y, antes, la serie larga (2010-2018), en orden cronológico
WITH b AS (
    SELECT anio, tasa_1000
    FROM mother.crimen_balance
    WHERE nivel = 'pais' AND categoria = 'Total infracciones penales'
),
l AS (
    SELECT anio, max(tasa_1000) AS tasa_1000
    FROM mother.crimen_serie_larga
    WHERE nivel = 'pais' AND tipologia = 'TOTAL INFRACCIONES PENALES'
    GROUP BY 1
)
SELECT anio, tasa_1000 AS valor FROM b
UNION ALL
SELECT anio, tasa_1000 AS valor FROM l WHERE anio < (SELECT min(anio) FROM b)
ORDER BY anio
```

```sql vida
SELECT CAST(anio AS INTEGER) AS anio, anios AS valor
FROM mother.salud_esperanza_vida
WHERE (nivel = 'pais' OR cod = '00') AND sexo = 'Ambos sexos'
ORDER BY anio
```

```sql nacionalizaciones
SELECT CAST(anio AS INTEGER) AS anio, nacionalizaciones, por_1000_extranjeros AS valor
FROM mother.inmigracion_nacionalizaciones
WHERE cod = '00' AND nacionalidad_previa = 'Total'
ORDER BY anio
```

```sql renta
SELECT CAST(anio AS INTEGER) AS anio, CAST(anio_renta AS INTEGER) AS anio_renta, renta_persona_real AS valor
FROM mother.renta_ecv_ccaa
WHERE cod = '00' AND renta_persona_real IS NOT NULL
ORDER BY anio
```

```sql abandono
SELECT CAST(anio AS INTEGER) AS anio, valor
FROM mother.educacion_indicadores
WHERE nivel = 'pais' AND indicador = 'abandono'
ORDER BY anio
```

```sql participacion
SELECT fecha, CAST(anio AS INTEGER) AS anio, participacion AS valor
FROM mother.elecciones_participacion
WHERE nivel = 'pais' AND tipo = '02'
ORDER BY fecha
```

# 👥 Gizartea

Nola bizi garen Espainian: segurtasuna, osasuna, kanpotik datorren biztanleria, errenta, hezkuntza eta botoa, zifra ofizialekin eta ondo irakurtzeko behar den testuinguruarekin.

<Grid cols=3>
    <KpiCard
        title="Arau-hauste penal ezagunak"
        value={crimen[0]?.infracciones}
        formattedValue="{formatNumber(crimen[0]?.tasa_1000, 1)} 1.000 biz."
        period="{formatCompact(crimen[0]?.infracciones, 2)} guztira · {crimen[0]?.anio}"
        source="Barne Ministerioa"
        href="/eu/sociedad/criminalidad"
        sparklineData={crimen_serie}
    />
    <KpiCard
        title="Bizi-itxaropena jaiotzean"
        value={vida.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(vida.slice(-1)[0]?.valor, 1)} urte"
        period="{urtean(vida.slice(-1)[0]?.anio)}, munduko altuenetako bat"
        change={vida.length > 1 ? vida.slice(-1)[0]?.valor - vida.slice(-2)[0]?.valor : null}
        changeUnit="urte"
        changePeriod="aurreko urtearekiko"
        direction="positive-up"
        source="INE"
        href="/eu/sociedad/salud"
        sparklineData={vida}
    />
    <KpiCard
        title="Nazionalitatea eskuratzeak"
        value={nacionalizaciones.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(nacionalizaciones.slice(-1)[0]?.valor, 1)} 1.000 atzerritarreko"
        period="{formatNumber(nacionalizaciones.slice(-1)[0]?.nacionalizaciones, 0)} egoiliarrek lortu zuten nazionalitatea {urtean(nacionalizaciones.slice(-1)[0]?.anio)}"
        direction="positive-up"
        source="INE"
        href="/eu/sociedad/inmigracion"
        sparklineData={nacionalizaciones}
    />
    <KpiCard
        title="Pertsonako batez besteko errenta"
        value={renta.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(renta.slice(-1)[0]?.valor, 0)} € urtean"
        period="{urteko(renta.slice(-1)[0]?.anio_renta)} errenta, inflazioa kenduta"
        change={renta.length > 1 ? 100 * (renta.slice(-1)[0]?.valor / renta.slice(-2)[0]?.valor - 1) : null}
        changePeriod="erreala, aurreko urtearekiko"
        direction="positive-up"
        source="INE / ECV"
        href="/eu/sociedad/desigualdad"
        sparklineData={renta}
    />
    <KpiCard
        title="Eskola-uzte goiztiarra"
        value={abandono.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(abandono.slice(-1)[0]?.valor, 1)} %"
        period="18 eta 24 urte bitarteko gazteena {urtean(abandono.slice(-1)[0]?.anio)} · {urtean(abandono[0]?.anio)} {formatNumber(abandono[0]?.valor, 1)} % zen"
        direction="positive-down"
        source="Eurostat / EPA"
        href="/eu/sociedad/educacion"
        sparklineData={abandono}
    />
    <KpiCard
        title="Parte-hartzea hauteskunde orokorretan"
        value={participacion.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(participacion.slice(-1)[0]?.valor, 1)} %"
        period="erroldakoek bozkatu zuten {urtean(participacion.slice(-1)[0]?.anio)}"
        direction="positive-up"
        source="Barne Ministerioa"
        href="/eu/sociedad/elecciones"
        sparklineData={participacion}
    />
</Grid>

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/eu/sociedad/criminalidad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-red-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚨</span> Kriminalitatea</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Delitu ezagunak motaren, erkidegoaren, probintziaren eta udalerriaren arabera 2010etik, zibergaizkilekeria eta kondenatuak nazionalitatearen arabera, haien testuinguruarekin.</p>
    </a>
    <a href="/eu/sociedad/salud" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🩺</span> Osasuna</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Bizi-itxaropena, heriotza-kausak eta gehiegizko hilkortasuna, eta osasun-sistema: itxaron-zerrendak, medikuak, oheak eta gastua.</p>
    </a>
    <a href="/eu/sociedad/inmigracion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🌍</span> Immigrazioa</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Atzerritar biztanleria erkidegoaren eta jatorriaren arabera, migrazio-saldoa, etorrera irregularrak, asiloa eta naturalizazioak.</p>
    </a>
    <a href="/eu/sociedad/desigualdad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">💶</span> Errenta, pobrezia eta desberdintasuna</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Etxeen errenta inflazioa kenduta, pobrezia-arriskua, AROPE, Gini eta S80/S20 erkidegoaren, adinaren eta udalerriaren arabera, eta EBrekiko konparazioa.</p>
    </a>
    <a href="/eu/sociedad/educacion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-indigo-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🎓</span> Hezkuntza</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Eskola-uzte goiztiarra, helduen ikasketa-maila, ez ikasten ez lanean ari diren gazteak, biztanleko eta ikasleko gastua, LH eta PISA, EBrekin alderatuta eta erkidegoka.</p>
    </a>
    <a href="/eu/sociedad/publico-privado" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-orange-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🏥</span> Publikoa eta pribatua</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Osasun eta hezkuntza publikoen zein zati ematen den enpresa eta zentro pribatuen bidez: itunak, emakida-ospitaleak, aseguruak, itunpekoa, LH eta unibertsitate pribatuak.</p>
    </a>
    <a href="/eu/sociedad/elecciones" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🗳️</span> Hauteskundeak</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Hauteskunde orokorrak 1977tik, europarrak eta udal-hauteskundeak: parte-hartzea, botoa alderdi eta blokearen arabera, zatiketa, eserlekuko botoak eta irabazlea probintzia eta udalerri bakoitzean.</p>
    </a>
</div>

<LastRefreshed prefix="Datuak eguneratuta" />
