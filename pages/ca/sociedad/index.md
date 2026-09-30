---
title: Societat
description: "Criminalitat, salut, immigració, renda i pobresa, educació i eleccions a Espanya amb dades oficials, per habitant i comparades amb la UE."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: a221d925c4c4
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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

# 👥 Societat

Com vivim a Espanya: la seguretat, la salut, la població que arriba de fora, la renda, l'educació i el vot, amb les xifres oficials i el context necessari per llegir-les bé.

<Grid cols=3>
    <KpiCard
        title="Infraccions penals conegudes"
        value={crimen[0]?.infracciones}
        formattedValue="{formatNumber(crimen[0]?.tasa_1000, 1)} per 1.000 hab."
        period="{formatCompact(crimen[0]?.infracciones, 2)} en total · {crimen[0]?.anio}"
        source="Ministeri de l'Interior"
        href="/ca/sociedad/criminalidad"
        sparklineData={crimen_serie}
    />
    <KpiCard
        title="Esperança de vida en néixer"
        value={vida.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(vida.slice(-1)[0]?.valor, 1)} anys"
        period="el {vida.slice(-1)[0]?.anio}, una de les més altes del món"
        change={vida.length > 1 ? vida.slice(-1)[0]?.valor - vida.slice(-2)[0]?.valor : null}
        changeUnit="anys"
        changePeriod="vs. any anterior"
        direction="positive-up"
        source="INE"
        href="/ca/sociedad/salud"
        sparklineData={vida}
    />
    <KpiCard
        title="Nous espanyols"
        value={nacionalizaciones.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(nacionalizaciones.slice(-1)[0]?.valor, 1)} per 1.000 estrangers"
        period="{formatNumber(nacionalizaciones.slice(-1)[0]?.nacionalizaciones, 0)} residents van obtenir la nacionalitat el {nacionalizaciones.slice(-1)[0]?.anio}"
        direction="positive-up"
        source="INE"
        href="/ca/sociedad/inmigracion"
        sparklineData={nacionalizaciones}
    />
    <KpiCard
        title="Renda mitjana per persona"
        value={renta.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(renta.slice(-1)[0]?.valor, 0)} € l'any"
        period="renda de {renta.slice(-1)[0]?.anio_renta}, descomptada la inflació"
        change={renta.length > 1 ? 100 * (renta.slice(-1)[0]?.valor / renta.slice(-2)[0]?.valor - 1) : null}
        changePeriod="real vs. any anterior"
        direction="positive-up"
        source="INE / ECV"
        href="/ca/sociedad/desigualdad"
        sparklineData={renta}
    />
    <KpiCard
        title="Abandonament escolar prematur"
        value={abandono.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(abandono.slice(-1)[0]?.valor, 1)} %"
        period="dels joves de 18 a 24 anys el {abandono.slice(-1)[0]?.anio} · el {abandono[0]?.anio} era el {formatNumber(abandono[0]?.valor, 1)} %"
        direction="positive-down"
        source="Eurostat / EPA"
        href="/ca/sociedad/educacion"
        sparklineData={abandono}
    />
    <KpiCard
        title="Participació en les generals"
        value={participacion.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(participacion.slice(-1)[0]?.valor, 1)} %"
        period="del cens va votar el {participacion.slice(-1)[0]?.anio}"
        direction="positive-up"
        source="Ministeri de l'Interior"
        href="/ca/sociedad/elecciones"
        sparklineData={participacion}
    />
</Grid>

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/ca/sociedad/criminalidad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-red-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚨</span> Criminalitat</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Delictes coneguts per tipus, comunitat, província i municipi des de 2010, cibercriminalitat i condemnats per nacionalitat amb el seu context.</p>
    </a>
    <a href="/ca/sociedad/salud" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🩺</span> Salut</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Esperança de vida, causes de mort i excés de mortalitat, i el sistema sanitari: llistes d'espera, metges, llits i despesa.</p>
    </a>
    <a href="/ca/sociedad/inmigracion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🌍</span> Immigració</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Població estrangera per comunitat i origen, saldo migratori, arribades irregulars, asil i nacionalitzacions.</p>
    </a>
    <a href="/ca/sociedad/desigualdad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">💶</span> Renda, pobresa i desigualtat</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Renda de les llars descomptada la inflació, risc de pobresa, AROPE, Gini i S80/S20 per comunitat, edat i municipi, i comparació amb la UE.</p>
    </a>
    <a href="/ca/sociedad/educacion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-indigo-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🎓</span> Educació</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Abandonament escolar prematur, nivell d'estudis dels adults, joves que ni estudien ni treballen, despesa per habitant i per alumne, FP i PISA, davant la UE i per comunitat.</p>
    </a>
    <a href="/ca/sociedad/elecciones" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🗳️</span> Eleccions</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Generals des de 1977, europees i municipals: participació, vot per partit i bloc, fragmentació, vots per escó i guanyador a cada província i municipi.</p>
    </a>
</div>

<LastRefreshed prefix="Dades actualitzades" />
