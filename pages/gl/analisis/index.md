---
title: Análises e reportaxes en datos
description: "Investigacións e reportaxes de datos sobre España con fontes oficiais: vivenda e salarios, deputados caseiros, paraísos fiscais de frotas, decretos-lei, servizos públicos e transición enerxética."
i18n_origen: f46b1181e86a
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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

# 📰 Análises e reportaxes en datos

Mentres que as seccións principais de SpainFacts manteñen sempre visibles as series estruturais do país, este espazo reúne **investigacións a fondo e cruzamentos de datos** sobre cuestións concretas do debate público. Todas as pezas seguen a mesma regra: fontes oficiais documentadas, datos axustados por poboación e inflación e contexto sen opinión partidista.

<Grid cols=4>
    <KpiCard
        title="Deputados que declaran alugueiros"
        value={caseros_kpi[0]?.pct_alquila}
        formattedValue="{formatNumber(caseros_kpi[0]?.pct_alquila, 1)} %"
        period="{formatNumber(caseros_kpi[0]?.n_alquila, 0)} deputados · {formatNumber(caseros_kpi[0]?.pct_dos_viviendas, 1)} % ten 2+ vivendas"
        source="Congreso / AEAT"
        href="/gl/varios/diputados-caseros"
    />
    <KpiCard
        title="Esforzo para mercar vivenda"
        value={esfuerzo_kpi.slice(-1)[0]?.anios_salario}
        formattedValue="{formatNumber(esfuerzo_kpi.slice(-1)[0]?.anios_salario, 1)} anos"
        period="de salario bruto íntegro para 90 m² ({esfuerzo_kpi.slice(-1)[0]?.anio})"
        direction="positive-down"
        source="MIVAU / INE"
        href="/gl/analisis/brecha-vivienda-salarios"
        sparklineData={esfuerzo_kpi.map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Electricidade de orixe renovable"
        value={renovables_kpi.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(renovables_kpi.slice(-1)[0]?.valor, 1)} %"
        period="do mix anual en {renovables_kpi.slice(-1)[0]?.anio} (fronte ao {formatNumber(renovables_kpi[0]?.valor, 1)} % en {renovables_kpi[0]?.anio})"
        direction="positive-up"
        source="REE"
        href="/gl/analisis/revolucion-renovable"
        sparklineData={renovables_kpi}
    />
    <KpiCard
        title="Leis aprobadas por decreto-lei"
        value={decretos_kpi.slice(-1)[0]?.pct_rdl}
        formattedValue="{formatNumber(decretos_kpi.slice(-1)[0]?.pct_rdl, 0)} %"
        period="{formatNumber(decretos_kpi.slice(-1)[0]?.rdl, 0)} reais decretos-lei en {decretos_kpi.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="BOE"
        href="/gl/transparencia/decretos-ley"
        sparklineData={decretos_kpi.map(d => ({...d, y: d.pct_rdl}))}
    />
</Grid>

## En foco · Novas análises

<div class="not-prose grid grid-cols-1 lg:grid-cols-2 gap-6 my-6">
    <a href="/gl/analisis/brecha-vivienda-salarios" class="group flex flex-col justify-between rounded-2xl border border-amber-200 dark:border-amber-800/80 bg-gradient-to-br from-amber-50/70 via-white to-white dark:from-amber-950/30 dark:via-gray-900 dark:to-gray-900 p-6 hover:border-amber-400 hover:shadow-lg transition no-underline">
        <div>
            <div class="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-amber-700 dark:text-amber-400">
                <span>🔑 Vivenda e salarios</span>
                <span>·</span>
                <span>Especial en datos</span>
            </div>
            <h3 class="mt-3 text-xl font-extrabold text-gray-900 dark:text-white group-hover:text-amber-700 dark:group-hover:text-amber-400">
                A fenda da vivenda: cantos anos de soldo custa mercar ou alugar un piso
            </h3>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                Comparamos a evolución real dos salarios co prezo taxado do metro cadrado e o alugueiro mediano do IRPF en cada comunidade autónoma.
            </p>
        </div>
        <span class="mt-5 inline-flex items-center text-sm font-bold text-amber-700 dark:text-amber-400">
            Ler a análise completa →
        </span>
    </a>

    <a href="/gl/analisis/revolucion-renovable" class="group flex flex-col justify-between rounded-2xl border border-emerald-200 dark:border-emerald-800/80 bg-gradient-to-br from-emerald-50/70 via-white to-white dark:from-emerald-950/30 dark:via-gray-900 dark:to-gray-900 p-6 hover:border-emerald-400 hover:shadow-lg transition no-underline">
        <div>
            <div class="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-emerald-700 dark:text-emerald-400">
                <span>☀️ Enerxía e clima</span>
                <span>·</span>
                <span>Especial en datos</span>
            </div>
            <h3 class="mt-3 text-xl font-extrabold text-gray-900 dark:text-white group-hover:text-emerald-700 dark:group-hover:text-emerald-400">
                A gran transformación eléctrica: como o sol e o vento desprazaron o carbón
            </h3>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                En quince anos España pechou case todo o seu carbón e multiplicou a xeración solar e eólica, derrubando as emisións eléctricas, mentres o transporte concentra xa case un terzo do CO₂.
            </p>
        </div>
        <span class="mt-5 inline-flex items-center text-sm font-bold text-emerald-700 dark:text-emerald-400">
            Ler a análise completa →
        </span>
    </a>
</div>

## Investigacións sobre institucións, impostos e servizos públicos

<div class="not-prose grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 my-6">
    <a href="/gl/varios/diputados-caseros" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-blue-50 dark:bg-blue-950/60 px-2.5 py-0.5 text-xs font-semibold text-blue-700 dark:text-blue-300">Congreso e IRPF</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏘️ Cantos deputados son caseiros?</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Declaracións de bens e rendas dos 350 deputados por partido e comparadas cos tramos de renda da Axencia Tributaria.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/gl/movilidad/flotas-e-impuestos" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-teal-50 dark:bg-teal-950/60 px-2.5 py-0.5 text-xs font-semibold text-teal-700 dark:text-teal-300">Fiscalidade municipal · DGT</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏝️ Os paraísos fiscais das frotas</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Por que concellos de menos de 500 habitantes matriculan decenas de milleiros de coches de alugueiro e empresa.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/gl/sociedad/publico-privado" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-purple-50 dark:bg-purple-950/60 px-2.5 py-0.5 text-xs font-semibold text-purple-700 dark:text-purple-300">Sanidade e educación</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏥 Público e privado nos servizos públicos</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Concertos sanitarios, seguros privados, ensino concertado, FP e universidades privadas por comunidade autónoma.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/gl/transparencia/decretos-ley" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-indigo-50 dark:bg-indigo-950/60 px-2.5 py-0.5 text-xs font-semibold text-indigo-700 dark:text-indigo-300">Poder executivo · BOE</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">📜 Gobernar por decreto desde 1977</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Cantos reais decretos-lei aproba cada presidente do Goberno por ano de mandato e que peso teñen sobre o total de leis.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/gl/medios/publicidad-institucional" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-rose-50 dark:bg-rose-950/60 px-2.5 py-0.5 text-xs font-semibold text-rose-700 dark:text-rose-300">Medios e diñeiro público</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">📢 Publicidade institucional e medios</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Canto gastan o Estado e as comunidades autónomas en campañas de publicidade institucional e como se reparte.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/gl/varios/observatorios" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-slate-100 dark:bg-slate-800 px-2.5 py-0.5 text-xs font-semibold text-slate-700 dark:text-slate-300">Administración pública</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🔭 Censo de observatorios públicos</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Cantos observatorios existen en España, que administración os creou e cantos manteñen actividade real.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/gl/transparencia/contratacion" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-amber-50 dark:bg-amber-950/60 px-2.5 py-0.5 text-xs font-semibold text-amber-700 dark:text-amber-300">Contratación · OIReScon</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">📑 Licitacións, único licitador e contratos menores</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Máis do 9 % do PIB pasa pola contratación pública: que parte se adxudica sen publicidade ou cunha soa oferta.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/gl/transparencia/subvenciones" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-emerald-50 dark:bg-emerald-950/60 px-2.5 py-0.5 text-xs font-semibold text-emerald-700 dark:text-emerald-300">Subvencións · BDNS</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">💶 Subvencións: concorrencia fronte a concesión directa</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Como se reparten as axudas públicas entre Estado, comunidades e concellos e que porcentaxe se concede de forma directa.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>

    <a href="/gl/vivienda/vivienda-publica" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-cyan-50 dark:bg-cyan-950/60 px-2.5 py-0.5 text-xs font-semibold text-cyan-700 dark:text-cyan-300">Comparativa europea</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏗️ Por que España ten tan pouca vivenda pública en alugueiro?</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                España pasou de construír centos de milleiros de VPO en propiedade a ter un dos parques de alugueiro social máis pequenos de Europa.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ver investigación →</span>
    </a>
</div>

---

## Buscas as series permanentes por tema?

Os grandes bloques de seguimento continuo están sempre dispoñibles na barra superior: [Territorios](/gl/territorios), [Demografía](/gl/demografia), [Economía](/gl/economia), [Vivenda](/gl/vivienda), [Contas públicas](/gl/cuentas-publicas), [Enerxía e clima](/gl/energia-clima), [Mobilidade](/gl/movilidad), [Sociedade](/gl/sociedad), [Medios](/gl/medios) e [Transparencia](/gl/transparencia), ou podes facer calquera consulta aberta en [Pregúntalles aos datos](/gl/chat).
