<script>
    import { localeActual } from "../utils.js";
    import { page } from "$app/stores";
    import { idiomaDeRuta, t } from "../i18n.js";
    $: lang = idiomaDeRuta($page.url.pathname);
    // Mapa "embalse por embalse": cada embalse es un depósito cuadrado cuya
    // ÁREA es proporcional a su capacidad, relleno hasta su % de llenado y
    // coloreado según la diferencia con lo habitual (media de la misma semana
    // en los 10 años anteriores). Inspirado en eldiario.es.
    import { onMount } from 'svelte';

    /** Filas con: embalse, cuenca, lat, lon, capacidad_hm3, pct_llenado, dif_vs_habitual, uso_electrico */
    export let data = [];
    export let geoUrl = '/geo/provincias.geojson';
    /** Embalses con capacidad >= este valor muestran su % dentro del depósito */
    export let etiquetaDesde = 400;
    export let fuente = 'MITECO – Boletín Hidrológico';

    // Encuadre fijo: península y Baleares (el boletín no incluye Canarias)
    const LON_MIN = -9.5, LON_MAX = 4.5, LAT_MIN = 35.9, LAT_MAX = 43.9;
    const COS = Math.cos((40 * Math.PI) / 180);
    const ANCHO = 800;
    const ESCALA = ANCHO / ((LON_MAX - LON_MIN) * COS);
    const ALTO = (LAT_MAX - LAT_MIN) * ESCALA;
    const LADO_MAX = 58; // lado del mayor embalse, en unidades del viewBox

    const px = (lon) => (lon - LON_MIN) * COS * ESCALA;
    const py = (lat) => (LAT_MAX - lat) * ESCALA;

    // Paleta divergente (ColorBrewer BrBG) en tramos de 5 puntos: marrón = por
    // debajo de lo habitual, verde azulado = por encima.
    const COLORES = ['#543005', '#8c510a', '#bf812d', '#dfc27d', '#f6e8c3', '#c7eae5', '#80cdc1', '#35978f', '#01665e', '#003c30'];
    const CORTES = [-20, -15, -10, -5, 0, 5, 10, 15, 20];
    function color(dif) {
        if (dif === null || dif === undefined || Number.isNaN(dif)) return '#cbd5e1';
        const i = CORTES.findIndex((c) => dif < c);
        return COLORES[i === -1 ? COLORES.length - 1 : i];
    }

    let uso = 'todos'; // 'consumo' | 'todos' | 'hidro'
    let estado = 'todos'; // 'peor' | 'todos' | 'mejor'
    let caminos = [];
    let hover = null;

    function anillo(coords) {
        return coords.map(([lon, lat], i) => `${i ? 'L' : 'M'}${px(lon).toFixed(1)},${py(lat).toFixed(1)}`).join('') + 'Z';
    }

    onMount(async () => {
        try {
            const geo = await (await fetch(geoUrl)).json();
            caminos = geo.features
                .filter((f) => f.properties?.cod_ccaa !== '05') // sin Canarias
                .map((f) => {
                    const g = f.geometry;
                    const polys = g.type === 'Polygon' ? [g.coordinates] : g.coordinates;
                    return polys.map((p) => p.map(anillo).join('')).join('');
                });
        } catch (e) {
            caminos = [];
        }
    });

    $: capMax = Math.max(1, ...data.map((d) => d.capacidad_hm3 || 0));
    $: depositos = data
        .filter((d) => d.lat != null && d.lon != null && d.capacidad_hm3 > 0)
        .map((d) => {
            const lado = Math.max(3, Math.sqrt(d.capacidad_hm3 / capMax) * LADO_MAX);
            const pct = Math.min(100, Math.max(0, d.pct_llenado ?? 0));
            const esHidro = d.uso_electrico === true || d.uso_electrico === 'true' || d.uso_electrico === 1;
            const visible =
                (uso === 'todos' || (uso === 'hidro') === esHidro) &&
                (estado === 'todos' || (d.dif_vs_habitual != null && (estado === 'mejor') === d.dif_vs_habitual >= 0));
            return { ...d, lado, pct, esHidro, visible, x: px(d.lon) - lado / 2, y: py(d.lat) - lado / 2, fill: color(d.dif_vs_habitual) };
        })
        // los grandes primero para que los pequeños queden encima y se puedan señalar
        .sort((a, b) => b.capacidad_hm3 - a.capacidad_hm3);

    const fmt = (v, dec = 1) => (v === null || v === undefined ? '—' : new Intl.NumberFormat(localeActual(), { maximumFractionDigits: dec, minimumFractionDigits: dec }).format(v));
</script>

<div class="not-prose my-4">
    <div class="flex flex-wrap gap-3 justify-center mb-3 text-sm">
        <div class="inline-flex rounded-md border border-gray-300 dark:border-gray-700 overflow-hidden" role="group" aria-label={t('embalses.uso', lang)}>
            {#each [['consumo', t('embalses.consumo', lang)], ['todos', t('embalses.todos', lang)], ['hidro', t('embalses.hidroAbr', lang)]] as [v, etq]}
                <button type="button" aria-pressed={uso === v} class="px-3 py-1 {uso === v ? 'bg-teal-800 text-white' : 'bg-white dark:bg-gray-900 text-gray-700 dark:text-gray-300'}" on:click={() => (uso = v)}>{etq}</button>
            {/each}
        </div>
        <div class="inline-flex rounded-md border border-gray-300 dark:border-gray-700 overflow-hidden" role="group" aria-label={t('embalses.estado', lang)}>
            {#each [['peor', t('embalses.peor', lang)], ['todos', t('embalses.todos', lang)], ['mejor', t('embalses.mejor', lang)]] as [v, etq]}
                <button type="button" aria-pressed={estado === v} class="px-3 py-1 {estado === v ? 'bg-teal-800 text-white' : 'bg-white dark:bg-gray-900 text-gray-700 dark:text-gray-300'}" on:click={() => (estado = v)}>{etq}</button>
            {/each}
        </div>
    </div>

    <div class="relative">
        <svg viewBox="0 0 {ANCHO} {ALTO.toFixed(0)}" class="w-full h-auto" role="img" aria-label={t('embalses.aria', lang)}>
            {#each caminos as d}
                <path {d} class="fill-gray-100 stroke-gray-300 dark:fill-gray-800 dark:stroke-gray-700" stroke-width="0.6" />
            {/each}

            {#each depositos as e (e.embalse + e.cuenca)}
                <g
                    opacity={e.visible ? 1 : 0.08}
                    on:mouseenter={() => (hover = e)}
                    on:mouseleave={() => (hover = null)}
                    role="presentation"
                >
                    <rect x={e.x} y={e.y} width={e.lado} height={e.lado} class="fill-white dark:fill-gray-900" stroke="#111827" stroke-width={e.lado > 8 ? 1 : 0.6} />
                    <rect x={e.x} y={e.y + e.lado * (1 - e.pct / 100)} width={e.lado} height={e.lado * e.pct / 100} fill={e.fill} />
                    <rect x={e.x} y={e.y} width={e.lado} height={e.lado} fill="none" stroke="#111827" stroke-width={e.lado > 8 ? 1 : 0.6} />
                    {#if e.capacidad_hm3 >= etiquetaDesde && e.visible}
                        <text x={e.x + e.lado / 2} y={e.y + Math.min(e.lado * 0.55, 16)} text-anchor="middle" font-size="11" class="fill-gray-900" paint-order="stroke" stroke="white" stroke-width="2.5">{fmt(e.pct_llenado, 0)}%</text>
                    {/if}
                </g>
            {/each}
        </svg>

        {#if hover}
            <div class="absolute top-2 right-2 max-w-xs rounded-lg border border-gray-200 dark:border-gray-700 bg-white/95 dark:bg-gray-900/95 p-3 text-sm shadow">
                <p class="font-semibold text-gray-900 dark:text-white mb-1">{hover.embalse}</p>
                <p class="text-xs text-gray-600 dark:text-gray-400 mb-2">{hover.cuenca} · {hover.esHidro ? t('embalses.hidro', lang) : t('embalses.consumo', lang)}</p>
                <p class="mb-0">{t('embalses.llenado', lang)} <b>{fmt(hover.pct_llenado)} %</b> ({fmt(hover.volumen_hm3, 0)} {t('de', lang)} {fmt(hover.capacidad_hm3, 0)} hm³)</p>
                <p class="mb-0">{t('embalses.habitual', lang)} {fmt(hover.pct_habitual)} %</p>
                <p class="mb-0">{t('embalses.diferencia', lang)} <b>{hover.dif_vs_habitual > 0 ? '+' : ''}{fmt(hover.dif_vs_habitual)} pp</b></p>
            </div>
        {/if}
    </div>

    <div class="flex flex-wrap items-end gap-6 mt-2 text-xs text-gray-600 dark:text-gray-400">
        <div>
            <p class="font-semibold mb-1">{t('embalses.leyenda', lang)}</p>
            <div class="flex">
                {#each COLORES as c}<span class="inline-block w-5 h-3" style="background:{c}"></span>{/each}
            </div>
            <div class="flex justify-between w-[200px]"><span>−20 pp</span><span>{t('embalses.igual', lang)}</span><span>+20 pp</span></div>
        </div>
        <p class="mb-0 max-w-md">{t('embalses.nota', lang)} {fuente}.</p>
    </div>
</div>
