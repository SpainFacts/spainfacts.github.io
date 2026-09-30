---
title: Sociedad
description: "Criminalidad, salud, inmigración, renta y pobreza, educación y elecciones en España con datos oficiales, por habitante y comparados con la UE."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../src/lib/utils.js';
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

# 👥 Sociedad

Cómo vivimos en España: la seguridad, la salud, la población que llega de fuera, la renta, la educación y el voto, con las cifras oficiales y el contexto necesario para leerlas bien.

<Grid cols=3>
    <KpiCard
        title="Infracciones penales conocidas"
        value={crimen[0]?.infracciones}
        formattedValue="{formatNumber(crimen[0]?.tasa_1000, 1)} por 1.000 hab."
        period="{formatCompact(crimen[0]?.infracciones, 2)} en total · {crimen[0]?.anio}"
        source="Ministerio del Interior"
        href="/sociedad/criminalidad"
        sparklineData={crimen_serie}
    />
    <KpiCard
        title="Esperanza de vida al nacer"
        value={vida.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(vida.slice(-1)[0]?.valor, 1)} años"
        period="en {vida.slice(-1)[0]?.anio}, una de las más altas del mundo"
        change={vida.length > 1 ? vida.slice(-1)[0]?.valor - vida.slice(-2)[0]?.valor : null}
        changeUnit="años"
        changePeriod="vs año anterior"
        direction="positive-up"
        source="INE"
        href="/sociedad/salud"
        sparklineData={vida}
    />
    <KpiCard
        title="Nuevos españoles"
        value={nacionalizaciones.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(nacionalizaciones.slice(-1)[0]?.valor, 1)} por 1.000 extranjeros"
        period="{formatNumber(nacionalizaciones.slice(-1)[0]?.nacionalizaciones, 0)} residentes obtuvieron la nacionalidad en {nacionalizaciones.slice(-1)[0]?.anio}"
        direction="positive-up"
        source="INE"
        href="/sociedad/inmigracion"
        sparklineData={nacionalizaciones}
    />
    <KpiCard
        title="Renta media por persona"
        value={renta.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(renta.slice(-1)[0]?.valor, 0)} € al año"
        period="renta de {renta.slice(-1)[0]?.anio_renta}, descontada la inflación"
        change={renta.length > 1 ? 100 * (renta.slice(-1)[0]?.valor / renta.slice(-2)[0]?.valor - 1) : null}
        changePeriod="real vs año anterior"
        direction="positive-up"
        source="INE / ECV"
        href="/sociedad/desigualdad"
        sparklineData={renta}
    />
    <KpiCard
        title="Abandono escolar temprano"
        value={abandono.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(abandono.slice(-1)[0]?.valor, 1)} %"
        period="de los jóvenes de 18 a 24 años en {abandono.slice(-1)[0]?.anio} · en {abandono[0]?.anio} era el {formatNumber(abandono[0]?.valor, 1)} %"
        direction="positive-down"
        source="Eurostat / EPA"
        href="/sociedad/educacion"
        sparklineData={abandono}
    />
    <KpiCard
        title="Participación en las generales"
        value={participacion.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(participacion.slice(-1)[0]?.valor, 1)} %"
        period="del censo votó en {participacion.slice(-1)[0]?.anio}"
        direction="positive-up"
        source="Ministerio del Interior"
        href="/sociedad/elecciones"
        sparklineData={participacion}
    />
</Grid>

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/sociedad/criminalidad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-red-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🚨</span> Criminalidad</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Delitos conocidos por tipo, comunidad, provincia y municipio desde 2010, cibercriminalidad y condenados por nacionalidad con su contexto.</p>
    </a>
    <a href="/sociedad/salud" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🩺</span> Salud</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Esperanza de vida, causas de muerte y exceso de mortalidad, y el sistema sanitario: listas de espera, médicos, camas y gasto.</p>
    </a>
    <a href="/sociedad/inmigracion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-teal-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🌍</span> Inmigración</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Población extranjera por comunidad y origen, saldo migratorio, llegadas irregulares, asilo y nacionalizaciones.</p>
    </a>
    <a href="/sociedad/desigualdad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">💶</span> Renta, pobreza y desigualdad</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Renta de los hogares descontada la inflación, riesgo de pobreza, AROPE, Gini y S80/S20 por comunidad, edad y municipio, y comparación con la UE.</p>
    </a>
    <a href="/sociedad/educacion" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-indigo-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🎓</span> Educación</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Abandono escolar temprano, nivel de estudios de los adultos, jóvenes que ni estudian ni trabajan, gasto por habitante y por alumno, FP y PISA, frente a la UE y por comunidad.</p>
    </a>
    <a href="/sociedad/elecciones" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-500 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white"><span aria-hidden="true">🗳️</span> Elecciones</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Generales desde 1977, europeas y municipales: participación, voto por partido y bloque, fragmentación, votos por escaño y ganador en cada provincia y municipio.</p>
    </a>
</div>

<LastRefreshed prefix="Datos actualizados" />
