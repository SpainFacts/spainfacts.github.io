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
    export let chartUnit = "";
    export let chartMultiplier = null;

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
    // Los números (o cadenas como "35.8" de toFixed) salen con el separador decimal del idioma;
    // en cadenas se respetan sus decimales y en números se dejan 1-2.
    function valorEnIdioma(v, _lang) {
        if (v === null || v === undefined || v === "") return "-";
        const texto = String(v).trim();
        if (typeof v !== "number" && !/^-?\d+(\.\d+)?$/.test(texto)) return texto;
        const n = Number(texto);
        if (!Number.isFinite(n)) return texto;
        const decimales = typeof v === "number"
            ? (Math.abs(n) >= 100 ? 1 : 2)
            : (texto.split(".")[1]?.length ?? 0);
        return n.toLocaleString(localeActual(), { maximumFractionDigits: decimales, useGrouping: "min2" });
    }
    $: displayValue = formattedValue || valorEnIdioma(value, lang);
    $: periodoTexto = [period, changePeriod].filter(Boolean).join(" · ");

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

    function valorNumerico(v) {
        if (v === null || v === undefined || v === "") return null;
        const n = Number(v);
        return Number.isFinite(n) ? n : null;
    }

    const vacio = (v) => v === null || v === undefined || v === "";
    const CLAVE_FECHA = /^(fecha|date|periodo|period|mes|month|trimestre|anio|ano|año|year)(_|$)/i;

    // Fecha del punto: x/fecha/periodo si vienen; si no, anio (+ mes o trimestre numéricos);
    // si no, cualquier columna con nombre de fecha o con un Date. Así las filas completas
    // ({...d, y: ...}) siempre etiquetan el eje con fechas cortas.
    function fechaDeDato(d) {
        if (!d || typeof d !== "object") return "";
        for (const clave of ["x", "fecha", "date", "periodo"]) {
            if (!vacio(d[clave])) return d[clave];
        }
        const anio = d.anio ?? d.year;
        if (!vacio(anio)) {
            if (/^[1-4]$/.test(String(d.trimestre ?? ""))) return `${anio}-T${d.trimestre}`;
            if (/^\d{1,2}$/.test(String(d.mes ?? "")) && Number(d.mes) >= 1 && Number(d.mes) <= 12) return `${anio}-${String(d.mes).padStart(2, "0")}`;
            return anio;
        }
        if (!vacio(d.mes) && !/^\d{1,2}$/.test(String(d.mes))) return d.mes;
        for (const [clave, v] of Object.entries(d)) {
            if (v instanceof Date || (CLAVE_FECHA.test(clave) && !vacio(v) && descomponerFecha(v))) return v;
        }
        return "";
    }

    function descomponerFecha(raw) {
        if (raw instanceof Date && Number.isFinite(raw.getTime())) {
            return { anio: raw.getUTCFullYear(), mes: raw.getUTCMonth(), trimestre: null };
        }
        const texto = String(raw ?? "").trim();
        const trimestre = texto.match(/^(\d{4})[-\s]?(?:T|Q)([1-4])$/i);
        if (trimestre) {
            const numero = Number(trimestre[2]);
            return { anio: Number(trimestre[1]), mes: (numero - 1) * 3, trimestre: numero };
        }
        const anio = texto.match(/^(\d{4})$/);
        if (anio) return { anio: Number(anio[1]), mes: 0, trimestre: null };
        const anioMes = texto.match(/^(\d{4})-(\d{1,2})/);
        if (anioMes && Number(anioMes[2]) >= 1 && Number(anioMes[2]) <= 12) {
            return { anio: Number(anioMes[1]), mes: Number(anioMes[2]) - 1, trimestre: null };
        }
        const fecha = new Date(texto);
        return Number.isFinite(fecha.getTime())
            ? { anio: fecha.getUTCFullYear(), mes: fecha.getUTCMonth(), trimestre: null }
            : null;
    }

    function formatoFechas(datos) {
        const fechas = datos.map((dato) => descomponerFecha(dato.fecha)).filter(Boolean);
        if (fechas.some((fecha) => fecha.trimestre !== null)) return "trimestre";
        const intervalos = fechas.slice(1).map((fecha, i) => (fecha.anio - fechas[i].anio) * 12 + fecha.mes - fechas[i].mes)
            .filter((meses) => meses > 0)
            .sort((a, b) => a - b);
        const mediana = intervalos.length ? intervalos[Math.floor(intervalos.length / 2)] : 0;
        if (mediana >= 2 && mediana <= 4) return "trimestre";
        return mediana >= 10 ? "anio" : "mes";
    }

    function fechaCompacta(raw, formato) {
        const fecha = descomponerFecha(raw);
        if (!fecha) return String(raw ?? "").trim().slice(0, 12);
        if (formato === "trimestre") {
            const prefijo = lang === "en" ? "Q" : "T";
            return `${fecha.anio}-${prefijo}${fecha.trimestre ?? Math.floor(fecha.mes / 3) + 1}`;
        }
        if (formato === "anio") return String(fecha.anio);
        return `${fecha.anio}-${String(fecha.mes + 1).padStart(2, "0")}`;
    }

    function numeroEnTexto(texto) {
        const match = String(texto ?? "").match(/[+-]?\d[\d.,'’\u00a0\u202f ]*/u);
        if (!match) return null;
        const locale = localeActual();
        const decimal = new Intl.NumberFormat(locale).formatToParts(1.1).find((p) => p.type === "decimal")?.value ?? ".";
        const group = new Intl.NumberFormat(locale).formatToParts(1000).find((p) => p.type === "group")?.value ?? ",";
        const normalized = match[0]
            .trim()
            .split(group).join("")
            .replace(/[’'\u00a0\u202f ]/g, "")
            .replace(decimal, ".");
        const n = Number(normalized);
        return Number.isFinite(n) ? n : null;
    }

    function unidadDeTexto(texto) {
        const match = String(texto ?? "").match(/[+-]?\d[\d.,'’\u00a0\u202f ]*/u);
        return match ? String(texto).slice(match.index + match[0].length).trim() : "";
    }

    // Keep valid samples and their original dates so missing values never shift the timeline.
    $: datosSparkline = !Array.isArray(sparklineData)
        ? []
        : sparklineData
              .map((d, i) => {
                  // Con «y» presente (filas {...d, y: ...}) manda «y» aunque sea null: no cae a otra columna.
                  const raw = d == null ? null : typeof d === "number" || typeof d === "string" ? d : ("y" in d ? d.y : (d.valor ?? d.value ?? null));
                  return { raw: valorNumerico(raw), fecha: fechaDeDato(d), indice: i };
              })
              .filter((d) => d.raw !== null);

    // Alternativa textual de la mini-gráfica para lectores de pantalla
    const numeroCorto = (v) =>
        v.toLocaleString(localeActual(), { maximumFractionDigits: Math.abs(v) >= 100 ? 0 : 2, notation: Math.abs(v) >= 1e6 ? "compact" : "standard" });
    const numeroEje = (v) =>
        v.toLocaleString(localeActual(), { maximumFractionDigits: 1, notation: Math.abs(v) >= 1e6 ? "compact" : "standard" });
    $: escalaGrafica = chartMultiplier !== null && chartMultiplier !== undefined && Number.isFinite(Number(chartMultiplier))
        ? Number(chartMultiplier)
        : (() => {
              const actual = valorNumerico(value);
              const mostrado = numeroEnTexto(displayValue);
              if (!/%/.test(`${displayValue} ${unit} ${chartUnit}`) || mostrado === null) return 1;
              const referencias = [actual, datosSparkline.at(-1)?.raw].filter((v) => v !== null && v !== undefined && v !== 0);
              return referencias.some((v) => Math.abs(mostrado / v - 100) < 0.5) ? 100 : 1;
          })();
    $: valoresGrafica = datosSparkline.map((d) => d.raw * escalaGrafica);
    $: unidadGrafica = chartUnit || unit || unidadDeTexto(displayValue);
    $: tituloGrafica = `${t('kpi.serie', lang)}${unidadGrafica ? ` · ${unidadGrafica === '%' ? t('kpi.porcentaje', lang) : unidadGrafica}` : ""}`;
    $: minGrafica = valoresGrafica.length ? Math.min(...valoresGrafica) : null;
    $: maxGrafica = valoresGrafica.length ? Math.max(...valoresGrafica) : null;
    $: minimoTexto = minGrafica === null ? "" : numeroEje(minGrafica);
    $: maximoTexto = maxGrafica === null ? "" : numeroEje(maxGrafica);
    $: minimoCompleto = minGrafica === null ? "" : `${minimoTexto}${unidadGrafica ? ` ${unidadGrafica}` : ""}`;
    $: maximoCompleto = maxGrafica === null ? "" : `${maximoTexto}${unidadGrafica ? ` ${unidadGrafica}` : ""}`;
    $: formatoFechaGrafica = formatoFechas(datosSparkline);
    $: fechaInicio = datosSparkline[0]?.fecha ? fechaCompacta(datosSparkline[0].fecha, formatoFechaGrafica) : "";
    $: fechaFinal = datosSparkline.at(-1)?.fecha ? fechaCompacta(datosSparkline.at(-1).fecha, formatoFechaGrafica) : "";
    $: descripcionSparkline = valoresGrafica.length >= 2
        ? `${t('kpi.evolucion', lang)} ${title}: ${t('kpi.minimo', lang)} ${minimoCompleto}, ${t('kpi.maximo', lang)} ${maximoCompleto}${fechaInicio && fechaFinal ? `, ${fechaInicio} ${t('kpi.a', lang)} ${fechaFinal}` : ""}`
        : "";

    // Keep the plotted range readable while labeling the true data minimum and maximum.
    $: sparklineGeometry = (() => {
        if (valoresGrafica.length < 2) return null;
        const width = 320;
        const height = 80;
        const padding = 5;
        const min = minGrafica;
        const max = maxGrafica;
        const range = max - min || Math.max(Math.abs(max) * 0.1, 1);
        const plotMin = max === min ? min - range / 2 : min;
        const plotMax = max === min ? max + range / 2 : max;
        const y = (v) => height - padding - ((v - plotMin) / (plotMax - plotMin)) * (height - padding * 2);
        const points = valoresGrafica.map((v, i) => ({
            x: (i / (valoresGrafica.length - 1)) * width,
            y: y(v),
        }));
        return {
            points: points.map((p) => `${p.x.toFixed(1)},${p.y.toFixed(1)}`).join(" "),
            last: points.at(-1),
            zeroY: min < 0 && max > 0 ? y(0) : null,
            minY: y(min),
            maxY: y(max),
        };
    })();

    $: sparklineDisponible = !!sparklineGeometry;
</script>

<div class="kpi-card group relative flex min-w-0 flex-col rounded-xl border border-gray-200 bg-white p-4 shadow-sm transition-all duration-200 hover:shadow-md hover:border-gray-300 sm:p-5 dark:border-gray-800 dark:bg-gray-900">
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
        <div class="flex min-w-0 items-baseline gap-1.5 my-1">
            <span class="min-w-0 break-words text-3xl font-extrabold tracking-tight text-gray-900 dark:text-white sm:text-4xl">
                {displayValue}
            </span>
            {#if unit}
                <span class="shrink-0 text-base font-medium text-gray-500 dark:text-gray-400">
                    {unit}
                </span>
            {/if}
        </div>

        <!-- Variation / Change Badge & Comparison Text -->
        <div class="mt-2 flex min-w-0 items-center gap-2">
            {#if isChangeValid}
                <span class="inline-flex shrink-0 items-center gap-0.5 rounded-md px-2 py-0.5 text-xs font-semibold {changeColorClass}">
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
            {#if periodoTexto}
                <span class="min-w-0 text-sm text-gray-500 dark:text-gray-400" class:truncate={sparklineDisponible} title={periodoTexto}>
                    {periodoTexto}
                </span>
            {/if}
        </div>
    </div>

    {#if sparklineDisponible}
        <div class="mt-3 border-t border-gray-100 pt-3 dark:border-gray-800/80">
            <p class="mb-2 text-xs text-gray-500 dark:text-gray-400">{tituloGrafica}</p>
            <div class="grid w-full min-w-0 grid-cols-[max-content_minmax(0,1fr)] items-stretch gap-2">
                <div class="flex shrink-0 flex-col justify-between py-0.5 text-right text-[10px] leading-tight text-gray-500 dark:text-gray-400">
                    <span class="whitespace-nowrap" title="{t('kpi.maximo', lang)}: {maximoCompleto}">{maximoTexto}</span>
                    <span class="whitespace-nowrap" title="{t('kpi.minimo', lang)}: {minimoCompleto}">{minimoTexto}</span>
                </div>
                <div class="w-full min-w-0">
                    <svg class="block h-20 w-full overflow-visible" viewBox="0 0 320 80" preserveAspectRatio="none" role="img" aria-label={descripcionSparkline}>
                        <line x1="0" x2="320" y1={sparklineGeometry.maxY} y2={sparklineGeometry.maxY} class="stroke-gray-200 dark:stroke-gray-700" stroke-width="1" stroke-dasharray="2 4" />
                        <line x1="0" x2="320" y1={sparklineGeometry.minY} y2={sparklineGeometry.minY} class="stroke-gray-200 dark:stroke-gray-700" stroke-width="1" stroke-dasharray="2 4" />
                        {#if sparklineGeometry.zeroY !== null}
                            <line x1="0" x2="320" y1={sparklineGeometry.zeroY} y2={sparklineGeometry.zeroY} class="stroke-gray-400 dark:stroke-gray-500" stroke-width="1" stroke-dasharray="3 3" />
                        {/if}
                        <polyline
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2.5"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="text-blue-600 dark:text-blue-400"
                            points={sparklineGeometry.points}
                        />
                        <circle cx={sparklineGeometry.last.x} cy={sparklineGeometry.last.y} r="3.5" class="fill-blue-600 stroke-white dark:fill-blue-400 dark:stroke-gray-900" stroke-width="2" />
                    </svg>
                    <div class="mt-1 flex justify-between gap-2 text-[10px] leading-tight text-gray-500 dark:text-gray-400">
                        <span class="max-w-[48%] truncate" title={fechaInicio || t('kpi.inicio', lang)}>{fechaInicio || t('kpi.inicio', lang)}</span>
                        <span class="max-w-[48%] truncate text-right" title={fechaFinal || t('kpi.ultimo', lang)}>{fechaFinal || t('kpi.ultimo', lang)}</span>
                    </div>
                </div>
            </div>
        </div>
    {/if}

    <div class="mt-auto flex items-center justify-between gap-2 border-t border-gray-100 pt-3 dark:border-gray-800/80">
        <div class="flex items-center gap-1.5">
        {#if sparklineDisponible}
            <button
                type="button"
                on:click|stopPropagation={descargarCsv}
                title={t('kpi.csv', lang)}
                aria-label={`${t('kpi.csv', lang)}: ${title}`}
                class="inline-flex min-h-8 min-w-8 items-center justify-center rounded-md border border-gray-200 p-1 text-gray-500 transition-colors hover:border-blue-500 hover:text-blue-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 dark:border-gray-700 dark:text-gray-400 dark:hover:text-blue-400"
            >
                <svg class="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M3 15v4c0 1.1.9 2 2 2h14a2 2 0 0 0 2-2v-4M17 9l-5 5-5-5M12 12.8V2.5" /></svg>
            </button>
        {/if}
        <Compartir compacto={true} titulo={title} {textoCompartir} />
        </div>
        {#if href}
            <a
                href={enlace(href, lang)}
                class="inline-flex min-h-8 items-center text-sm font-semibold text-blue-600 transition-colors hover:text-blue-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 dark:text-blue-400 dark:hover:text-blue-300"
            >
                {t('kpi.detalle', lang)}<span class="sr-only">: {title}</span>
                <svg class="ml-1 h-3.5 w-3.5 transition-transform group-hover:translate-x-0.5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true" focusable="false">
                    <path fill-rule="evenodd" d="M3 10a.75.75 0 01.75-.75h10.638L10.23 5.09a.75.75 0 011.04-1.08l5.5 5.25a.75.75 0 010 1.08l-5.5 5.25a.75.75 0 11-1.04-1.08l4.158-3.96H3.75A.75.75 0 013 10z" clip-rule="evenodd" />
                </svg>
            </a>
        {/if}
    </div>
</div>
