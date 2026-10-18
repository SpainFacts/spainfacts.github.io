---
title: Análisis y reportajes en datos
description: "Investigaciones y reportajes de datos sobre España con fuentes oficiales: vivienda y salarios, diputados caseros, paraísos fiscales de flotas, decretos-ley, sanidad y educación público-privada y transición energética."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../src/lib/utils.js';
</script>

```sql caseros_kpi
SELECT
    max(pct) FILTER (WHERE definicion_id = 'alquila') AS pct_alquila,
    max(n_cumplen) FILTER (WHERE definicion_id = 'alquila') AS n_alquila,
    max(pct) FILTER (WHERE definicion_id = 'dos_viviendas') AS pct_dos_viviendas
FROM mother.diputados_inmuebles_resumen
```

```sql esfuerzo_kpi
SELECT anio, anios_salario, pct_alquiler
FROM mother.vivienda_esfuerzo
WHERE nivel = 'pais' AND anios_salario IS NOT NULL
ORDER BY anio
```

```sql renovables_kpi
SELECT anio, cuota_renovable_pct AS valor
FROM mother.energia_resumen_anual_mix
ORDER BY anio
```

```sql decretos_kpi
SELECT anio, rdl, leyes, pct_rdl
FROM mother.gobierno_actos_anual
WHERE NOT anio_en_curso
ORDER BY anio
```

# 📰 Análisis y reportajes en datos

Mientras que las secciones principales de SpainFacts mantienen siempre visibles las series estructurales del país, este espacio reúne **investigaciones a fondo y cruces de datos** sobre cuestiones concretas del debate público. Todas las piezas siguen la misma regla: fuentes oficiales documentadas, datos ajustados por población e inflación y contexto sin opinión partidista.

<Grid cols=4>
    <KpiCard
        title="Diputados que declaran alquileres"
        value={caseros_kpi[0]?.pct_alquila}
        formattedValue="{formatNumber(caseros_kpi[0]?.pct_alquila, 1)} %"
        period="{formatNumber(caseros_kpi[0]?.n_alquila, 0)} diputados · {formatNumber(caseros_kpi[0]?.pct_dos_viviendas, 1)} % tiene 2+ viviendas"
        source="Congreso / AEAT"
        href="/varios/diputados-caseros"
    />
    <KpiCard
        title="Esfuerzo para comprar vivienda"
        value={esfuerzo_kpi.slice(-1)[0]?.anios_salario}
        formattedValue="{formatNumber(esfuerzo_kpi.slice(-1)[0]?.anios_salario, 1)} años"
        period="de salario bruto íntegro para 90 m² ({esfuerzo_kpi.slice(-1)[0]?.anio})"
        direction="positive-down"
        source="MIVAU / INE"
        href="/analisis/brecha-vivienda-salarios"
        sparklineData={esfuerzo_kpi.map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Electricidad de origen renovable"
        value={renovables_kpi.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(renovables_kpi.slice(-1)[0]?.valor, 1)} %"
        period="del mix anual en {renovables_kpi.slice(-1)[0]?.anio} (frente al {formatNumber(renovables_kpi[0]?.valor, 1)} % en {renovables_kpi[0]?.anio})"
        direction="positive-up"
        source="REE"
        href="/analisis/revolucion-renovable"
        sparklineData={renovables_kpi}
    />
    <KpiCard
        title="Leyes aprobadas por decreto-ley"
        value={decretos_kpi.slice(-1)[0]?.pct_rdl}
        formattedValue="{formatNumber(decretos_kpi.slice(-1)[0]?.pct_rdl, 0)} %"
        period="{formatNumber(decretos_kpi.slice(-1)[0]?.rdl, 0)} reales decretos-ley en {decretos_kpi.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="BOE"
        href="/transparencia/decretos-ley"
        sparklineData={decretos_kpi.map(d => ({...d, y: d.pct_rdl}))}
    />
</Grid>

## En foco · Nuevos análisis

<div class="not-prose grid grid-cols-1 lg:grid-cols-2 gap-6 my-6">
    <a href="/analisis/brecha-vivienda-salarios" class="group flex flex-col justify-between rounded-2xl border border-amber-200 dark:border-amber-800/80 bg-gradient-to-br from-amber-50/70 via-white to-white dark:from-amber-950/30 dark:via-gray-900 dark:to-gray-900 p-6 hover:border-amber-400 hover:shadow-lg transition no-underline">
        <div>
            <div class="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-amber-700 dark:text-amber-400">
                <span>🔑 Vivienda y salarios</span>
                <span>·</span>
                <span>Especial en datos</span>
            </div>
            <h3 class="mt-3 text-xl font-extrabold text-gray-900 dark:text-white group-hover:text-amber-700 dark:group-hover:text-amber-400">
                La brecha de la vivienda: cuántos años de sueldo cuesta comprar o alquilar un piso
            </h3>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                Comparamos la evolución real de los salarios con el precio tasado del metro cuadrado y el alquiler mediano del IRPF: por qué en Baleares, Madrid o Canarias el esfuerzo multiplica al del interior peninsular.
            </p>
        </div>
        <span class="mt-5 inline-flex items-center text-sm font-bold text-amber-700 dark:text-amber-400">
            Leer el análisis completo →
        </span>
    </a>

    <a href="/analisis/revolucion-renovable" class="group flex flex-col justify-between rounded-2xl border border-emerald-200 dark:border-emerald-800/80 bg-gradient-to-br from-emerald-50/70 via-white to-white dark:from-emerald-950/30 dark:via-gray-900 dark:to-gray-900 p-6 hover:border-emerald-400 hover:shadow-lg transition no-underline">
        <div>
            <div class="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-emerald-700 dark:text-emerald-400">
                <span>☀️ Energía y clima</span>
                <span>·</span>
                <span>Especial en datos</span>
            </div>
            <h3 class="mt-3 text-xl font-extrabold text-gray-900 dark:text-white group-hover:text-emerald-700 dark:group-hover:text-emerald-400">
                La gran transformación eléctrica: cómo el sol y el viento desplazaron al carbón
            </h3>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                En quince años España cerró casi todo su carbón y multiplicó la generación solar y eólica, desplomando las emisiones eléctricas. Sin embargo, el transporte concentra ya casi un tercio de todo el CO₂ del país.
            </p>
        </div>
        <span class="mt-5 inline-flex items-center text-sm font-bold text-emerald-700 dark:text-emerald-400">
            Leer el análisis completo →
        </span>
    </a>
</div>

## Investigaciones sobre instituciones, impuestos y servicios públicos

<div class="not-prose grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 my-6">
    <a href="/varios/diputados-caseros" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-blue-50 dark:bg-blue-950/60 px-2.5 py-0.5 text-xs font-semibold text-blue-700 dark:text-blue-300">Congreso e IRPF</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏘️ ¿Cuántos diputados son caseros?</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Declaraciones de bienes y rentas de los 350 diputados cruzadas por partido y comparadas con los tramos de renta de la Agencia Tributaria.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/movilidad/flotas-e-impuestos" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-teal-50 dark:bg-teal-950/60 px-2.5 py-0.5 text-xs font-semibold text-teal-700 dark:text-teal-300">Fiscalidad municipal · DGT</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏝️ Los paraísos fiscales de las flotas</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Por qué municipios de menos de 500 habitantes matriculan decenas de miles de coches de alquiler y empresa gracias a rebajas del IVTM.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/sociedad/publico-privado" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-purple-50 dark:bg-purple-950/60 px-2.5 py-0.5 text-xs font-semibold text-purple-700 dark:text-purple-300">Sanidad y educación</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏥 Público y privado en los servicios públicos</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Conciertos sanitarios, seguros privados, enseñanza concertada, FP y auge de las universidades privadas por comunidad autónoma.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/transparencia/decretos-ley" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-indigo-50 dark:bg-indigo-950/60 px-2.5 py-0.5 text-xs font-semibold text-indigo-700 dark:text-indigo-300">Poder ejecutivo · BOE</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">📜 Gobernar por decreto desde 1977</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Cuántos reales decretos-ley aprueba cada presidente del Gobierno por año de mandato y qué peso tienen sobre el total de leyes.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/medios/publicidad-institucional" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-rose-50 dark:bg-rose-950/60 px-2.5 py-0.5 text-xs font-semibold text-rose-700 dark:text-rose-300">Medios y dinero público</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">📢 Publicidad institucional y medios</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Cuánto gastan el Estado y las comunidades autónomas en campañas de publicidad institucional y cómo se reparte entre medios.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/varios/observatorios" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-slate-100 dark:bg-slate-800 px-2.5 py-0.5 text-xs font-semibold text-slate-700 dark:text-slate-300">Administración pública</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🔭 Censo de observatorios públicos</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Cuántos observatorios existen en España, qué administración los creó y cuántos mantienen actividad real.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/transparencia/contratacion" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-amber-50 dark:bg-amber-950/60 px-2.5 py-0.5 text-xs font-semibold text-amber-700 dark:text-amber-300">Contratación · OIReScon</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">📑 Licitaciones, único licitador y contratos menores</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Más del 9 % del PIB pasa por la contratación pública: qué parte se adjudica sin publicidad o con una sola oferta.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/transparencia/subvenciones" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-emerald-50 dark:bg-emerald-950/60 px-2.5 py-0.5 text-xs font-semibold text-emerald-700 dark:text-emerald-300">Subvenciones · BDNS</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">💶 Subvenciones: concurrencia frente a concesión directa</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Cómo se reparten las ayudas públicas entre Estado, comunidades y ayuntamientos y qué porcentaje se concede de forma directa.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/vivienda/vivienda-publica" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-cyan-50 dark:bg-cyan-950/60 px-2.5 py-0.5 text-xs font-semibold text-cyan-700 dark:text-cyan-300">Comparativa europea</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏗️ ¿Por qué España tiene tan poca vivienda pública en alquiler?</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                España pasó de construir cientos de miles de VPO en propiedad a tener uno de los parques de alquiler social más pequeños de Europa.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>
</div>

---

## ¿Buscas las series permanentes por tema?

Los grandes bloques de seguimiento continuo están siempre disponibles en la barra superior: [Territorios](/territorios), [Demografía](/demografia), [Economía](/economia), [Vivienda](/vivienda), [Cuentas públicas](/cuentas-publicas), [Energía y clima](/energia-clima), [Movilidad](/movilidad), [Sociedad](/sociedad), [Medios](/medios) y [Transparencia](/transparencia), o puedes hacer cualquier consulta abierta en [Pregunta a los datos](/chat).
