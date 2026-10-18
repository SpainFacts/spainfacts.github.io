---
title: Anàlisis i reportatges en dades
description: "Investigacions i reportatges de dades sobre Espanya amb fonts oficials: habitatge i salaris, diputats arrendadors, paradisos fiscals de flotes, decrets llei, serveis públics i transició energètica."
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

# 📰 Anàlisis i reportatges en dades

Mentre que les seccions principals de SpainFacts mantenen sempre visibles les sèries estructurals del país, aquest espai reuneix **investigacions a fons i encreuaments de dades** sobre qüestions concretes del debat públic. Totes les peces segueixen la mateixa regla: fonts oficials documentades, dades ajustades per població i inflació i context sense opinió partidista.

<Grid cols=4>
    <KpiCard
        title="Diputats que declaren lloguers"
        value={caseros_kpi[0]?.pct_alquila}
        formattedValue="{formatNumber(caseros_kpi[0]?.pct_alquila, 1)} %"
        period="{formatNumber(caseros_kpi[0]?.n_alquila, 0)} diputats · {formatNumber(caseros_kpi[0]?.pct_dos_viviendas, 1)} % té 2+ habitatges"
        source="Congrés / AEAT"
        href="/ca/varios/diputados-caseros"
    />
    <KpiCard
        title="Esforç per comprar habitatge"
        value={esfuerzo_kpi.slice(-1)[0]?.anios_salario}
        formattedValue="{formatNumber(esfuerzo_kpi.slice(-1)[0]?.anios_salario, 1)} anys"
        period="de salari brut íntegre per a 90 m² ({esfuerzo_kpi.slice(-1)[0]?.anio})"
        direction="positive-down"
        source="MIVAU / INE"
        href="/ca/analisis/brecha-vivienda-salarios"
        sparklineData={esfuerzo_kpi.map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Electricitat d'origen renovable"
        value={renovables_kpi.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(renovables_kpi.slice(-1)[0]?.valor, 1)} %"
        period="del mix anual el {renovables_kpi.slice(-1)[0]?.anio} (enfront del {formatNumber(renovables_kpi[0]?.valor, 1)} % el {renovables_kpi[0]?.anio})"
        direction="positive-up"
        source="REE"
        href="/ca/analisis/revolucion-renovable"
        sparklineData={renovables_kpi}
    />
    <KpiCard
        title="Lleis aprovades per decret llei"
        value={decretos_kpi.slice(-1)[0]?.pct_rdl}
        formattedValue="{formatNumber(decretos_kpi.slice(-1)[0]?.pct_rdl, 0)} %"
        period="{formatNumber(decretos_kpi.slice(-1)[0]?.rdl, 0)} reials decrets llei el {decretos_kpi.slice(-1)[0]?.anio}"
        direction="positive-down"
        source="BOE"
        href="/ca/transparencia/decretos-ley"
        sparklineData={decretos_kpi.map(d => ({...d, y: d.pct_rdl}))}
    />
</Grid>

## En focus · Noves anàlisis

<div class="not-prose grid grid-cols-1 lg:grid-cols-2 gap-6 my-6">
    <a href="/ca/analisis/brecha-vivienda-salarios" class="group flex flex-col justify-between rounded-2xl border border-amber-200 dark:border-amber-800/80 bg-gradient-to-br from-amber-50/70 via-white to-white dark:from-amber-950/30 dark:via-gray-900 dark:to-gray-900 p-6 hover:border-amber-400 hover:shadow-lg transition no-underline">
        <div>
            <div class="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-amber-700 dark:text-amber-400">
                <span>🔑 Habitatge i salaris</span>
                <span>·</span>
                <span>Especial en dades</span>
            </div>
            <h3 class="mt-3 text-xl font-extrabold text-gray-900 dark:text-white group-hover:text-amber-700 dark:group-hover:text-amber-400">
                La bretxa de l'habitatge: quants anys de sou costa comprar o llogar un pis
            </h3>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                Comparem l'evolució real dels salaris amb el preu taxat del metre quadrat i el lloguer medià de l'IRPF a cada comunitat autònoma.
            </p>
        </div>
        <span class="mt-5 inline-flex items-center text-sm font-bold text-amber-700 dark:text-amber-400">
            Llegeix l'anàlisi completa →
        </span>
    </a>

    <a href="/ca/analisis/revolucion-renovable" class="group flex flex-col justify-between rounded-2xl border border-emerald-200 dark:border-emerald-800/80 bg-gradient-to-br from-emerald-50/70 via-white to-white dark:from-emerald-950/30 dark:via-gray-900 dark:to-gray-900 p-6 hover:border-emerald-400 hover:shadow-lg transition no-underline">
        <div>
            <div class="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-emerald-700 dark:text-emerald-400">
                <span>☀️ Energia i clima</span>
                <span>·</span>
                <span>Especial en dades</span>
            </div>
            <h3 class="mt-3 text-xl font-extrabold text-gray-900 dark:text-white group-hover:text-emerald-700 dark:group-hover:text-emerald-400">
                La gran transformació elèctrica: com el sol i el vent van desplaçar el carbó
            </h3>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                En quinze anys Espanya va tancar gairebé tot el carbó i va multiplicar la generació solar i eòlica, desplomant les emissions elèctriques, mentre el transport ja concentra gairebé un terç del CO₂.
            </p>
        </div>
        <span class="mt-5 inline-flex items-center text-sm font-bold text-emerald-700 dark:text-emerald-400">
            Llegeix l'anàlisi completa →
        </span>
    </a>
</div>

## Investigacions sobre institucions, impostos i serveis públics

<div class="not-prose grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 my-6">
    <a href="/ca/varios/diputados-caseros" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-blue-50 dark:bg-blue-950/60 px-2.5 py-0.5 text-xs font-semibold text-blue-700 dark:text-blue-300">Congrés i IRPF</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏘️ Quants diputats són arrendadors?</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Declaracions de béns i rendes dels 350 diputats per partit i comparades amb els trams de renda de l'Agència Tributària.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Mostra la investigació →</span>
    </a>

    <a href="/ca/movilidad/flotas-e-impuestos" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-teal-50 dark:bg-teal-950/60 px-2.5 py-0.5 text-xs font-semibold text-teal-700 dark:text-teal-300">Fiscalitat municipal · DGT</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏝️ Els paradisos fiscals de les flotes</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Per què municipis de menys de 500 habitants matriculen desenes de milers de cotxes de lloguer i empresa.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Mostra la investigació →</span>
    </a>

    <a href="/ca/sociedad/publico-privado" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-purple-50 dark:bg-purple-950/60 px-2.5 py-0.5 text-xs font-semibold text-purple-700 dark:text-purple-300">Sanitat i educació</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏥 Públic i privat als serveis públics</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Concerts sanitaris, assegurances privades, escola concertada, FP i universitats privades per comunitat autònoma.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Mostra la investigació →</span>
    </a>

    <a href="/ca/transparencia/decretos-ley" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-indigo-50 dark:bg-indigo-950/60 px-2.5 py-0.5 text-xs font-semibold text-indigo-700 dark:text-indigo-300">Poder executiu · BOE</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">📜 Governar per decret des del 1977</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Quants reials decrets llei aprova cada president del Govern per any de mandat i quin pes tenen sobre el total de lleis.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Mostra la investigació →</span>
    </a>

    <a href="/ca/medios/publicidad-institucional" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-rose-50 dark:bg-rose-950/60 px-2.5 py-0.5 text-xs font-semibold text-rose-700 dark:text-rose-300">Mitjans i diners públics</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">📢 Publicitat institucional i mitjans</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Quant gasten l'Estat i les comunitats autònomes en campanyes de publicitat institucional i com es reparteix.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Mostra la investigació →</span>
    </a>

    <a href="/ca/varios/observatorios" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-slate-100 dark:bg-slate-800 px-2.5 py-0.5 text-xs font-semibold text-slate-700 dark:text-slate-300">Administració pública</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🔭 Cens d'observatoris públics</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Quants observatoris existeixen a Espanya, quina administració els va crear i quants mantenen activitat real.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Mostra la investigació →</span>
    </a>

    <a href="/ca/transparencia/contratacion" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-amber-50 dark:bg-amber-950/60 px-2.5 py-0.5 text-xs font-semibold text-amber-700 dark:text-amber-300">Contractació · OIReScon</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">📑 Licitacions, únic licitador i contractes menors</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Més del 9 % del PIB passa per la contractació pública: quina part s'adjudica sense publicitat o amb una sola oferta.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Mostra la investigació →</span>
    </a>

    <a href="/ca/transparencia/subvenciones" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-emerald-50 dark:bg-emerald-950/60 px-2.5 py-0.5 text-xs font-semibold text-emerald-700 dark:text-emerald-300">Subvencions · BDNS</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">💶 Subvencions: concurrència enfront de concessió directa</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Com es reparteixen les ajudes públiques entre Estat, comunitats i ajuntaments i quin percentatge es concedeix de forma directa.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Mostra la investigació →</span>
    </a>

    <a href="/ca/vivienda/vivienda-publica" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-cyan-50 dark:bg-cyan-950/60 px-2.5 py-0.5 text-xs font-semibold text-cyan-700 dark:text-cyan-300">Comparativa europea</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏗️ Per què Espanya té tan poc habitatge públic de lloguer?</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Espanya va passar de construir centenars de milers d'HPO en propietat a tenir un dels parcs de lloguer social més petits d'Europa.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Mostra la investigació →</span>
    </a>
</div>

---

## Busques les sèries permanents per tema?

Els grans blocs de seguiment continu estan sempre disponibles a la barra superior: [Territoris](/ca/territorios), [Demografia](/ca/demografia), [Economia](/ca/economia), [Habitatge](/ca/vivienda), [Comptes públics](/ca/cuentas-publicas), [Energia i clima](/ca/energia-clima), [Mobilitat](/ca/movilidad), [Societat](/ca/sociedad), [Mitjans](/ca/medios) i [Transparència](/ca/transparencia), o pots fer qualsevol consulta oberta a [Pregunta a les dades](/ca/chat).
