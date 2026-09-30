---
title: Sociedade
description: "Criminalidade, saúde, inmigración, renda e pobreza, educación e eleccións en España con datos oficiais, por habitante e comparados coa UE."
i18n_origen: a221d925c4c4
og:
  image: https://spainfacts.org/og-spainfacts.png
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

# 👥 Sociedade

Como vivimos en España: a seguridade, a saúde, a poboación que chega de fóra, a renda, a educación e o voto, coas cifras oficiais e o contexto necesario para lelas ben.

<Grid cols=3>
    <KpiCard
        title="Infraccións penais coñecidas"
        value={crimen[0]?.infracciones}
        formattedValue="{formatNumber(crimen[0]?.tasa_1000, 1)} por 1.000 hab."
        period="{formatCompact(crimen[0]?.infracciones, 2)} en total · {crimen[0]?.anio}"
        source="Ministerio do Interior"
        href="/gl/sociedad/criminalidad"
        sparklineData={crimen_serie}
    />
    <KpiCard
        title="Esperanza de vida ao nacer"
        value={vida.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(vida.slice(-1)[0]?.valor, 1)} anos"
        period="en {vida.slice(-1)[0]?.anio}, unha das máis altas do mundo"
        change={vida.length > 1 ? vida.slice(-1)[0]?.valor - vida.slice(-2)[0]?.valor : null}
        changeUnit="anos"
        changePeriod="fronte ao ano anterior"
        direction="positive-up"
        source="INE"
        href="/gl/sociedad/salud"
        sparklineData={vida}
    />
    <KpiCard
        title="Novos españois"
        value={nacionalizaciones.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(nacionalizaciones.slice(-1)[0]?.valor, 1)} por 1.000 estranxeiros"
        period="{formatNumber(nacionalizaciones.slice(-1)[0]?.nacionalizaciones, 0)} residentes obtiveron a nacionalidade en {nacionalizaciones.slice(-1)[0]?.anio}"
        direction="positive-up"
        source="INE"
        href="/gl/sociedad/inmigracion"
        sparklineData={nacionalizaciones}
    />
    <KpiCard
        title="Renda media por persoa"
        value={renta.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(renta.slice(-1)[0]?.valor, 0)} € ao ano"
        period="renda de {renta.slice(-1)[0]?.anio_renta}, descontada a inflación"
        change={renta.length > 1 ? 100 * (renta.slice(-1)[0]?.valor / renta.slice(-2)[0]?.valor - 1) : null}
        changePeriod="real fronte ao ano anterior"
        direction="positive-up"
        source="INE / ECV"
        href="/gl/sociedad/desigualdad"
        sparklineData={renta}
    />
    <KpiCard
        title="Abandono escolar temperán"
        value={abandono.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(abandono.slice(-1)[0]?.valor, 1)} %"
        period="dos mozos de 18 a 24 anos en {abandono.slice(-1)[0]?.anio} · en {abandono[0]?.anio} era o {formatNumber(abandono[0]?.valor, 1)} %"
        direction="positive-down"
        source="Eurostat / EPA"
        href="/gl/sociedad/educacion"
        sparklineData={abandono}
    />
    <KpiCard
        title="Participación nas xerais"
        value={participacion.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(participacion.slice(-1)[0]?.valor, 1)} %"
        period="do censo votou en {participacion.slice(-1)[0]?.anio}"
        direction="positive-up"
        source="Ministerio do Interior"
        href="/gl/sociedad/elecciones"
        sparklineData={participacion}
    />
</Grid>

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/gl/sociedad/criminalidad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-red-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚨</span> Criminalidade</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Delitos coñecidos por tipo, comunidade, provincia e municipio desde 2010, cibercriminalidade e condenados por nacionalidade co seu contexto.</p>
    </a>
    <a href="/gl/sociedad/salud" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🩺</span> Saúde</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Esperanza de vida, causas de morte e exceso de mortalidade, e o sistema sanitario: listas de espera, médicos, camas e gasto.</p>
    </a>
    <a href="/gl/sociedad/inmigracion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🌍</span> Inmigración</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Poboación estranxeira por comunidade e orixe, saldo migratorio, chegadas irregulares, asilo e nacionalizacións.</p>
    </a>
    <a href="/gl/sociedad/desigualdad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">💶</span> Renda, pobreza e desigualdade</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Renda dos fogares descontada a inflación, risco de pobreza, AROPE, Gini e S80/S20 por comunidade, idade e municipio, e comparación coa UE.</p>
    </a>
    <a href="/gl/sociedad/educacion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-indigo-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🎓</span> Educación</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Abandono escolar temperán, nivel de estudos dos adultos, mozos que nin estudan nin traballan, gasto por habitante e por alumno, FP e PISA, fronte á UE e por comunidade.</p>
    </a>
    <a href="/gl/sociedad/elecciones" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🗳️</span> Eleccións</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Xerais desde 1977, europeas e municipais: participación, voto por partido e bloque, fragmentación, votos por escano e gañador en cada provincia e municipio.</p>
    </a>
</div>

<LastRefreshed prefix="Datos actualizados" />
