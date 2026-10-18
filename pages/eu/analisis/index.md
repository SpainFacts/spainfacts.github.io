---
title: Datu-analisiak eta erreportajeak
description: "Espainiari buruzko datu-ikerketak eta erreportajeak iturri ofizialekin: etxebizitza eta soldatak, diputatu errentatzaileak, floten zerga-paradisuak, lege-dekretuak, zerbitzu publikoak eta trantsizio energetikoa."
i18n_origen: 39f9545ba89f
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

# 📰 Datu-analisiak eta erreportajeak

SpainFactsen atal nagusiek herrialdearen egiturazko serieak beti ikusgai mantentzen dituzten bitartean, gune honek eztabaida publikoko gai zehatzei buruzko **ikerketa sakonak eta datu-gurutzaketak** biltzen ditu. Pieza guztiek arau bera jarraitzen dute: dokumentatutako iturri ofizialak, biztanleriaren eta inflazioaren arabera doitutako datuak eta iritzi alderdikoirik gabeko testuingurua.

<Grid cols=4>
    <KpiCard
        title="Alokairuak aitortzen dituzten diputatuak"
        value={caseros_kpi[0]?.pct_alquila}
        formattedValue="{formatNumber(caseros_kpi[0]?.pct_alquila, 1)} %"
        period="{formatNumber(caseros_kpi[0]?.n_alquila, 0)} diputatu · {formatNumber(caseros_kpi[0]?.pct_dos_viviendas, 1)} %-k 2+ etxebizitza ditu"
        source="Kongresua / AEAT"
        href="/eu/varios/diputados-caseros"
    />
    <KpiCard
        title="Etxebizitza erosteko ahalegina"
        value={esfuerzo_kpi.slice(-1)[0]?.anios_salario}
        formattedValue="{formatNumber(esfuerzo_kpi.slice(-1)[0]?.anios_salario, 1)} urte"
        period="soldata gordin osoaren urteak 90 m² erosteko ({esfuerzo_kpi.slice(-1)[0]?.anio})"
        direction="positive-down"
        source="MIVAU / INE"
        href="/eu/analisis/brecha-vivienda-salarios"
        sparklineData={esfuerzo_kpi.map(d => ({...d, y: d.anios_salario}))}
    />
    <KpiCard
        title="Jatorri berriztagarriko elektrizitatea"
        value={renovables_kpi.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(renovables_kpi.slice(-1)[0]?.valor, 1)} %"
        period="urteko mixaren % ({renovables_kpi.slice(-1)[0]?.anio}, {renovables_kpi[0]?.anio}ko {formatNumber(renovables_kpi[0]?.valor, 1)} %-aren aldean)"
        direction="positive-up"
        source="REE"
        href="/eu/analisis/revolucion-renovable"
        sparklineData={renovables_kpi}
    />
    <KpiCard
        title="Lege-dekretuz onartutako legeak"
        value={decretos_kpi.slice(-1)[0]?.pct_rdl}
        formattedValue="{formatNumber(decretos_kpi.slice(-1)[0]?.pct_rdl, 0)} %"
        period="{formatNumber(decretos_kpi.slice(-1)[0]?.rdl, 0)} errege lege-dekretu ({decretos_kpi.slice(-1)[0]?.anio})"
        direction="positive-down"
        source="BOE"
        href="/eu/transparencia/decretos-ley"
        sparklineData={decretos_kpi.map(d => ({...d, y: d.pct_rdl}))}
    />
</Grid>

## Fokuan · Analisi berriak

<div class="not-prose grid grid-cols-1 lg:grid-cols-2 gap-6 my-6">
    <a href="/eu/analisis/brecha-vivienda-salarios" class="group flex flex-col justify-between rounded-2xl border border-amber-200 dark:border-amber-800/80 bg-gradient-to-br from-amber-50/70 via-white to-white dark:from-amber-950/30 dark:via-gray-900 dark:to-gray-900 p-6 hover:border-amber-400 hover:shadow-lg transition no-underline">
        <div>
            <div class="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-amber-700 dark:text-amber-400">
                <span>🔑 Etxebizitza eta soldatak</span>
                <span>·</span>
                <span>Datu-berezia</span>
            </div>
            <h3 class="mt-3 text-xl font-extrabold text-gray-900 dark:text-white group-hover:text-amber-700 dark:group-hover:text-amber-400">
                Etxebizitzaren arrakala: zenbat soldata-urte behar diren pisu bat erosi edo alokatzeko
            </h3>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                Soldaten bilakaera erreala metro karratuaren prezio tasatuarekin eta PFEZko alokairu medianoarekin alderatzen dugu autonomia-erkidego bakoitzean.
            </p>
        </div>
        <span class="mt-5 inline-flex items-center text-sm font-bold text-amber-700 dark:text-amber-400">
            Irakurri analisi osoa →
        </span>
    </a>

    <a href="/eu/analisis/revolucion-renovable" class="group flex flex-col justify-between rounded-2xl border border-emerald-200 dark:border-emerald-800/80 bg-gradient-to-br from-emerald-50/70 via-white to-white dark:from-emerald-950/30 dark:via-gray-900 dark:to-gray-900 p-6 hover:border-emerald-400 hover:shadow-lg transition no-underline">
        <div>
            <div class="flex items-center gap-2 text-xs font-bold uppercase tracking-wider text-emerald-700 dark:text-emerald-400">
                <span>☀️ Energia eta klima</span>
                <span>·</span>
                <span>Datu-berezia</span>
            </div>
            <h3 class="mt-3 text-xl font-extrabold text-gray-900 dark:text-white group-hover:text-emerald-700 dark:group-hover:text-emerald-400">
                Eraldaketa elektriko handia: eguzkiak eta haizeak ikatza nola ordezkatu zuten
            </h3>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                Hamabost urtean Espainiak ia ikatz guztia itxi eta eguzki- eta haize-sorkuntza biderkatu zuen, isuri elektrikoak amilduz; garraioak, aldiz, CO₂ guztiaren ia herena hartzen du.
            </p>
        </div>
        <span class="mt-5 inline-flex items-center text-sm font-bold text-emerald-700 dark:text-emerald-400">
            Irakurri analisi osoa →
        </span>
    </a>
</div>

## Erakundeei, zergei eta zerbitzu publikoei buruzko ikerketak

<div class="not-prose grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 my-6">
    <a href="/eu/varios/diputados-caseros" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-blue-50 dark:bg-blue-950/60 px-2.5 py-0.5 text-xs font-semibold text-blue-700 dark:text-blue-300">Kongresua eta PFEZ</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏘️ Zenbat diputatu dira etxe-jabe errentatzaile?</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                350 diputatuen ondasun- eta errenta-aitorpenak alderdika eta Zerga Agentziaren errenta-tarteekin alderatuta.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ikusi ikerketa →</span>
    </a>

    <a href="/eu/movilidad/flotas-e-impuestos" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-teal-50 dark:bg-teal-950/60 px-2.5 py-0.5 text-xs font-semibold text-teal-700 dark:text-teal-300">Udal-fiskalitatea · DGT</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏝️ Floten zerga-paradisuak</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Zergatik matrikulatzen dituzten 500 biztanle baino gutxiagoko udalerriek alokairuko eta enpresako dozenaka mila auto.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ikusi ikerketa →</span>
    </a>

    <a href="/eu/sociedad/publico-privado" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-purple-50 dark:bg-purple-950/60 px-2.5 py-0.5 text-xs font-semibold text-purple-700 dark:text-purple-300">Osasuna eta hezkuntza</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏥 Publikoa eta pribatua zerbitzu publikoetan</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Osasun-itunak, aseguru pribatuak, itunpeko irakaskuntza, LH eta unibertsitate pribatuak autonomia-erkidegoka.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ikusi ikerketa →</span>
    </a>

    <a href="/eu/transparencia/decretos-ley" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-indigo-50 dark:bg-indigo-950/60 px-2.5 py-0.5 text-xs font-semibold text-indigo-700 dark:text-indigo-300">Botere betearazlea · BOE</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">📜 Dekretuz gobernatzea 1977tik</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Zenbat errege lege-dekretu onartzen dituen Gobernuko presidente bakoitzak agintaldi-urteko eta zein pisu duten.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ikusi ikerketa →</span>
    </a>

    <a href="/eu/medios/dinero-publico" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-rose-50 dark:bg-rose-950/60 px-2.5 py-0.5 text-xs font-semibold text-rose-700 dark:text-rose-300">Hedabideak eta diru publikoa</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">📢 Publizitate instituzionala eta hedabideak</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Zenbat gastatzen duten Estatuak eta autonomia-erkidegoek publizitate instituzionaleko kanpainetan eta nola banatzen den.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ikusi ikerketa →</span>
    </a>

    <a href="/eu/varios/observatorios" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-slate-100 dark:bg-slate-800 px-2.5 py-0.5 text-xs font-semibold text-slate-700 dark:text-slate-300">Administrazio publikoa</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🔭 Behatoki publikoen errolda</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Zenbat behatoki dauden Espainian, zein administraziok sortu zituen eta zenbatek duten jarduera erreala.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ikusi ikerketa →</span>
    </a>

    <a href="/eu/transparencia/contratacion" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-amber-50 dark:bg-amber-950/60 px-2.5 py-0.5 text-xs font-semibold text-amber-700 dark:text-amber-300">Kontratazioa · OIReScon</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">📑 Lizitazioak, lizitatzaile bakarra eta kontratu txikiak</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                BPGd-aren % 9 baino gehiago kontratazio publikotik igarotzen da: zein zati esleitzen den publizitaterik gabe edo eskaintza bakarrarekin.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ikusi ikerketa →</span>
    </a>

    <a href="/eu/transparencia/subvenciones" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-emerald-50 dark:bg-emerald-950/60 px-2.5 py-0.5 text-xs font-semibold text-emerald-700 dark:text-emerald-300">Dirulaguntzak · BDNS</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">💶 Dirulaguntzak: lehia vs. zuzeneko emakida</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Nola banatzen diren laguntza publikoak Estatuaren, erkidegoen eta udalen artean eta zein ehuneko ematen den zuzenean.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ikusi ikerketa →</span>
    </a>

    <a href="/eu/vivienda/vivienda-publica" class="group flex flex-col justify-between rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-5 hover:border-blue-400 hover:shadow-md transition no-underline">
        <div>
            <span class="inline-block rounded-full bg-cyan-50 dark:bg-cyan-950/60 px-2.5 py-0.5 text-xs font-semibold text-cyan-700 dark:text-cyan-300">Europako alderaketa</span>
            <h3 class="mt-3 text-lg font-bold text-gray-900 dark:text-white">🏗️ Zergatik du Espainiak hain etxebizitza publiko gutxi alokairuan?</h3>
            <p class="mt-1.5 text-sm text-gray-600 dark:text-gray-400">
                Espainia jabetzako ehunka mila BOE eraikitzetik Europako alokairu sozialeko parke txikienetako bat izatera igaro zen.
            </p>
        </div>
        <span class="mt-4 text-sm font-semibold text-blue-600 dark:text-blue-400">Ikusi ikerketa →</span>
    </a>
</div>

---

## Gaikako serie iraunkorrak bilatzen dituzu?

Jarraipeneko bloke handiak beti daude eskuragarri goiko barran: [Lurraldeak](/eu/territorios), [Demografia](/eu/demografia), [Ekonomia](/eu/economia), [Etxebizitza](/eu/vivienda), [Kontu publikoak](/eu/cuentas-publicas), [Energia eta klima](/eu/energia-clima), [Mugikortasuna](/eu/movilidad), [Gizartea](/eu/sociedad), [Hedabideak](/eu/medios) eta [Gardentasuna](/eu/transparencia), edo egin edozein galdera ireki [Galdetu datuei](/eu/chat) atalean.
