---
title: Sociedad
description: "Criminalidad, salud e inmigración en España con datos oficiales: delitos por municipio, condenados, esperanza de vida, causas de muerte y población extranjera."
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

# 👥 Sociedad

Cómo vivimos en España: la seguridad, la salud y la población que llega de fuera, con las cifras oficiales y el contexto necesario para leerlas bien.

<Grid cols=3>
    <KpiCard
        title="Infracciones penales conocidas"
        value={crimen[0]?.infracciones}
        formattedValue={formatCompact(crimen[0]?.infracciones, 2)}
        period="{formatNumber(crimen[0]?.tasa_1000, 1)} por 1.000 habitantes · {crimen[0]?.anio}"
        source="Ministerio del Interior"
        href="/sociedad/criminalidad"
    />
</Grid>

<div class="grid grid-cols-1 md:grid-cols-3 gap-4 not-prose my-6">
    <a href="/sociedad/criminalidad" class="block rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-red-400 no-underline">
        <p class="text-lg font-bold text-gray-900 dark:text-white">🚨 Criminalidad</p>
        <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Delitos conocidos por tipo, comunidad, provincia y municipio desde 2010, cibercriminalidad y condenados por nacionalidad con su contexto.</p>
    </a>
</div>

<LastRefreshed prefix="Datos actualizados" />
