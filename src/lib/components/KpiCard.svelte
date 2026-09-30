<script>
    import { localeActual } from "../utils.js";
    import { page } from "$app/stores";
    import { idiomaDeRuta, enlace, t } from "../i18n.js";
    $: lang = idiomaDeRuta($page.url.pathname);

    import Compartir from "./Compartir.svelte";
    export let title = "";
    export let value = null;
    export let formattedValue = "";
    export let unit = "";
    export let period = "";
    export let change = null;
    export let changeUnit = "%";
    export let changePeriod = "";
    /**
     * direction determines whether an increase is good or bad:
     * 'positive-up': increase is good (green), decrease is bad (red) -> e.g. GDP, Population, Employment
     * 'positive-down': decrease is good (green), increase is bad (red) -> e.g. Unemployment, Inflation, Public Debt
     * 'neutral': no positive/negative color semantics, uses neutral accent
     */
    export let direction = "neutral";
    export let href = "";
    export let source = "";
    export let sparklineData = []; // Array of numbers or objects { x, y }

    // Texto que se comparte en redes: el dato con su título y periodo
    $: textoCompartir = `${title}: ${formattedValue || value}${period ? ` (${period})` : ""} · SpainFacts`;

    // Descarga en CSV de la serie de la mini-gráfica
    function descargarCsv() {
        const filas = (Array.isArray(sparklineData) ? sparklineData : []).filter((d) => d != null);
        if (!filas.length) return;
        const esObjeto = typeof filas[0] === "object";
        const columnas = esObjeto ? Object.keys(filas[0]) : ["posicion", "valor"];
        const celda = (v) => {
            if (v === null || v === undefined) return "";
            if (v instanceof Date) return v.toISOString().slice(0, 10);
            const t = String(v);
            return /[",\n;]/.test(t) ? `"${t.replace(/"/g, '""')}"` : t;
        };
        const lineas = [columnas.join(",")].concat(
            filas.map((d, i) => (esObjeto ? columnas.map((c) => celda(d[c])) : [i + 1, celda(d)]).join(","))
        );
        // ﻿ (BOM) para que Excel abra bien las tildes
        const blob = new Blob(["﻿" + lineas.join("\n")], { type: "text/csv;charset=utf-8" });
        const a = document.createElement("a");
        a.href = URL.createObjectURL(blob);
        a.download = `${(title || "dato").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[^a-z0-9]+/g, "_")}.csv`;
        a.click();
        setTimeout(() => URL.revokeObjectURL(a.href), 1000);
    }

    // Format display value
    $: displayValue = formattedValue || (value !== null && value !== undefined ? value.toString() : "-");

    // Compute change sign & number
    $: numChange = typeof change === "number" ? change : parseFloat(change);
    $: isChangeValid = !isNaN(numChange) && change !== null && change !== undefined;
    // Texto del cambio con coma decimal y como mucho un decimal (evita 4.714090167984009)
    $: cambioTexto = isChangeValid
        ? numChange.toLocaleString(localeActual(), { maximumFractionDigits: Math.abs(numChange) >= 100 ? 0 : 1 })
        : "";
    $: isPositiveChange = numChange > 0;
    $: isZeroChange = numChange === 0;

    // Color logic based on direction
    $: changeColorClass = (() => {
        if (!isChangeValid || isZeroChange) return "bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300";
        if (direction === "positive-up") {
            return isPositiveChange
                ? "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800/50"
                : "bg-rose-50 text-rose-700 dark:bg-rose-950/40 dark:text-rose-400 border border-rose-200 dark:border-rose-800/50";
        }
        if (direction === "positive-down") {
            return isPositiveChange
                ? "bg-rose-50 text-rose-700 dark:bg-rose-950/40 dark:text-rose-400 border border-rose-200 dark:border-rose-800/50"
                : "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800/50";
        }
        return "bg-blue-50 text-blue-700 dark:bg-blue-950/40 dark:text-blue-400 border border-blue-200 dark:border-blue-800/50";
    })();

    // Valores de la mini-gráfica. Ignora huecos (null/undefined/NaN): una serie con
    // años sin dato no debe romper la tarjeta
    $: valoresSparkline = !Array.isArray(sparklineData)
        ? []
        : sparklineData
              .map((d) => (d == null ? null : typeof d === "number" ? d : (d.y ?? d.valor ?? d.value ?? null)))
              .map((v) => (v == null ? null : Number(v)))
              .filter((v) => v !== null && Number.isFinite(v));

    // Alternativa textual de la mini-gráfica para lectores de pantalla
    const numeroCorto = (v) =>
        v.toLocaleString(localeActual(), { maximumFractionDigits: Math.abs(v) >= 100 ? 0 : 2, notation: Math.abs(v) >= 1e6 ? "compact" : "standard" });
    $: descripcionSparkline = valoresSparkline.length >= 2
        ? `${t('kpi.evolucion', lang)} ${title}: ${t('kpi.de', lang)} ${numeroCorto(valoresSparkline[0])} ${t('kpi.a', lang)} ${numeroCorto(valoresSparkline[valoresSparkline.length - 1])}`
        : "";

    // Generate SVG path for sparkline if data is available
    $: sparklinePoints = (() => {
        const valores = valoresSparkline;
        if (valores.length < 2) return "";
        const points = valores.map((y, i) => ({ x: i, y }));
        const yValues = points.map(p => p.y);
        const minY = Math.min(...yValues);
        const maxY = Math.max(...yValues);
        const rangeY = maxY - minY || 1;
        const width = 100;
        const height = 28;
        const padding = 2;

        const scaled = points.map((p, i) => {
            const x = (i / (points.length - 1)) * width;
            const y = height - padding - ((p.y - minY) / rangeY) * (height - padding * 2);
            return `${x.toFixed(1)},${y.toFixed(1)}`;
        });
        return scaled.join(" ");
    })();
</script>

<div class="kpi-card group relative flex flex-col justify-between rounded-xl border border-gray-200 bg-white p-5 shadow-sm transition-all duration-200 hover:shadow-md hover:border-gray-300 dark:border-gray-800 dark:bg-gray-900">
    <div>
        <!-- Card Header: Title & Source -->
        <div class="flex items-center justify-between gap-2 mb-2">
            <span class="text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                {title}
            </span>
            {#if source}
                <span class="inline-flex items-center rounded px-1.5 py-0.5 text-[10px] font-medium bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-300">
                    {source}
                </span>
            {/if}
        </div>

        <!-- Main Metric Value & Unit -->
        <div class="flex items-baseline gap-1.5 my-1">
            <span class="text-3xl font-extrabold tracking-tight text-gray-900 dark:text-white">
                {displayValue}
            </span>
            {#if unit}
                <span class="text-sm font-medium text-gray-500 dark:text-gray-400">
                    {unit}
                </span>
            {/if}
        </div>

        <!-- Variation / Change Badge & Comparison Text -->
        <div class="flex flex-wrap items-center gap-2 mt-2">
            {#if isChangeValid}
                <span class="inline-flex items-center gap-0.5 rounded-md px-2 py-0.5 text-xs font-semibold {changeColorClass}">
                    <span class="sr-only">{t('kpi.variacion', lang)}:</span>
                    {#if isPositiveChange}
                        <svg class="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true" focusable="false">
                            <path fill-rule="evenodd" d="M10 17a.75.75 0 01-.75-.75V5.612L5.29 9.77a.75.75 0 01-1.08-1.04l5.25-5.5a.75.75 0 011.08 0l5.25 5.5a.75.75 0 11-1.08 1.04l-3.96-4.158V16.25A.75.75 0 0110 17z" clip-rule="evenodd" />
                        </svg>
                    {:else if numChange < 0}
                        <svg class="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true" focusable="false">
                            <path fill-rule="evenodd" d="M10 3a.75.75 0 01.75.75v10.638l3.96-4.158a.75.75 0 111.08 1.04l-5.25 5.5a.75.75 0 01-1.08 0l-5.25-5.5a.75.75 0 111.08-1.04l3.96 4.158V3.75A.75.75 0 0110 3z" clip-rule="evenodd" />
                        </svg>
                    {/if}
                    {isPositiveChange ? '+' : ''}{cambioTexto}{changeUnit ? ` ${changeUnit}` : ''}
                </span>
            {/if}
            {#if period || changePeriod}
                <span class="text-xs text-gray-500 dark:text-gray-400">
                    {period}{changePeriod ? ` · ${changePeriod}` : ''}
                </span>
            {/if}
        </div>
    </div>

    <!-- Optional Sparkline and Footer Link -->
    <div class="mt-4 pt-3 border-t border-gray-100 dark:border-gray-800/80 flex items-center justify-between">
        {#if sparklinePoints}
            <div class="w-24 h-7">
                <svg class="w-full h-full overflow-visible" viewBox="0 0 100 28" role="img" aria-label={descripcionSparkline}>
                    <polyline
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        class="text-blue-500 dark:text-blue-400"
                        points={sparklinePoints}
                    />
                </svg>
            </div>
        {:else}
            <div></div>
        {/if}

        <div class="flex items-center gap-1.5">
        {#if sparklinePoints}
            <button
                type="button"
                on:click|stopPropagation={descargarCsv}
                title={t('kpi.csv', lang)}
                aria-label={`${t('kpi.csv', lang)}: ${title}`}
                class="inline-flex min-h-6 min-w-6 items-center justify-center rounded-md border border-gray-200 dark:border-gray-700 p-1 text-gray-500 hover:text-blue-600 hover:border-blue-500 dark:text-gray-400 dark:hover:text-blue-400 transition-colors"
            >
                <svg class="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M3 15v4c0 1.1.9 2 2 2h14a2 2 0 0 0 2-2v-4M17 9l-5 5-5-5M12 12.8V2.5" /></svg>
            </button>
        {/if}
        <Compartir compacto={true} titulo={title} {textoCompartir} />
        {#if href}
            <a
                href={enlace(href, lang)}
                class="inline-flex min-h-6 items-center text-xs font-semibold text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300 transition-colors"
            >
                {t('kpi.detalle', lang)}<span class="sr-only">: {title}</span>
                <svg class="ml-1 h-3.5 w-3.5 transition-transform group-hover:translate-x-0.5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true" focusable="false">
                    <path fill-rule="evenodd" d="M3 10a.75.75 0 01.75-.75h10.638L10.23 5.09a.75.75 0 011.04-1.08l5.5 5.25a.75.75 0 010 1.08l-5.5 5.25a.75.75 0 11-1.04-1.08l4.158-3.96H3.75A.75.75 0 013 10z" clip-rule="evenodd" />
                </svg>
            </a>
        {/if}
        </div>
    </div>
</div>
