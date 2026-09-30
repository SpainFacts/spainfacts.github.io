<script>
    import { localeActual } from "../utils.js";
    import { onMount } from "svelte";
    import { ECharts } from "@evidence-dev/core-components";
    import { page } from "$app/stores";
    import { idiomaDeRuta, t } from "../i18n.js";

    export let dataIngresos = [];
    export let dataGastos = [];
    /** Por defecto, el título y subtítulo del idioma de la página */
    export let title = undefined;
    export let subtitle = undefined;
    export let height = "520px";

    $: lang = idiomaDeRuta($page.url.pathname);
    $: titulo = title ?? t("sankey.titulo", lang);
    $: subtitulo = subtitle ?? t("sankey.subtitulo", lang);

    // Format utility for tooltip
    $: unidad = t("sankey.unidad", lang);
    $: formatMrd = (val) => {
        if (!val) return `0 ${unidad}`;
        return new Intl.NumberFormat(localeActual(), { maximumFractionDigits: 0 }).format(val) + ` ${unidad}`;
    };

    $: totalIngresos = (dataIngresos || []).reduce((acc, row) => acc + (parseFloat(row.millones_euros) || 0), 0);
    $: totalGastos = (dataGastos || []).reduce((acc, row) => acc + (parseFloat(row.millones_euros) || 0), 0);

    // Nombre del nodo central (solo se usa dentro del diagrama, así que se traduce)
    $: CENTRAL_NODE = t("sankey.central", lang);

    // Modo oscuro: los textos del diagrama llevan colores fijos, así que se eligen según
    // el tema (clase theme-dark en <html>) para que no queden oscuros sobre fondo oscuro.
    let oscuro = false;
    onMount(() => {
        const html = document.documentElement;
        const leer = () => (oscuro = html.classList.contains("theme-dark"));
        leer();
        const obs = new MutationObserver(leer);
        obs.observe(html, { attributes: true, attributeFilter: ["class"] });
        return () => obs.disconnect();
    });

    // Alternativa textual del diagrama (ECharts la pone como aria-label del gráfico)
    const principales = (filas, col, fmt) =>
        [...(filas || [])]
            .sort((a, b) => (parseFloat(b.millones_euros) || 0) - (parseFloat(a.millones_euros) || 0))
            .slice(0, 3)
            .map((r) => `${r[col]} (${fmt(parseFloat(r.millones_euros) || 0)})`)
            .join(", ");
    $: descripcion = `${titulo}. ${t("sankey.ingresos", lang)}: ${formatMrd(totalIngresos)}; ${t("sankey.mayores", lang)}, ${principales(dataIngresos, "categoria", formatMrd)}. ` +
        `${t("sankey.gastos", lang)}: ${formatMrd(totalGastos)}; ${t("sankey.mayores", lang)}, ${principales(dataGastos, "funcion_cofog", formatMrd)}.`;

    $: nodes = [
        // Central node
        { 
            name: CENTRAL_NODE,
            itemStyle: { color: "#1e3a8a", borderColor: "#172554", borderWidth: 1 }
        },
        // Income nodes
        ...(dataIngresos || []).map((row, idx) => {
            const palette = ["#0284c7", "#0ea5e9", "#38bdf8", "#0d9488", "#14b8a6", "#2dd4bf", "#64748b"];
            return {
                name: row.categoria,
                itemStyle: { color: palette[idx % palette.length] }
            };
        }),
        // Expense nodes
        ...(dataGastos || []).map((row, idx) => {
            const palette = ["#7c3aed", "#ec4899", "#f59e0b", "#ef4444", "#10b981", "#6366f1", "#f97316", "#84cc16", "#06b6d4"];
            return {
                name: row.funcion_cofog,
                itemStyle: { color: palette[idx % palette.length] }
            };
        })
    ];

    $: links = [
        // Inflow links: Income -> Central Node
        ...(dataIngresos || []).map(row => {
            const val = parseFloat(row.millones_euros) || 0;
            return {
                source: row.categoria,
                target: CENTRAL_NODE,
                value: val
            };
        }),
        // Outflow links: Central Node -> Expense functions
        ...(dataGastos || []).map(row => {
            const val = parseFloat(row.millones_euros) || 0;
            return {
                source: CENTRAL_NODE,
                target: row.funcion_cofog,
                value: val
            };
        })
    ];

    $: config = {
        aria: { enabled: true, label: { description: descripcion } },
        title: {
            text: titulo,
            subtext: subtitulo,
            left: "center",
            textStyle: {
                fontSize: 16,
                fontWeight: "bold",
                color: oscuro ? "#f1f5f9" : "#1e293b"
            },
            subtextStyle: {
                fontSize: 12,
                color: oscuro ? "#94a3b8" : "#64748b"
            }
        },
        tooltip: {
            // fondo claro fijo: el contenido lleva colores oscuros también en modo oscuro
            backgroundColor: "#ffffff",
            borderColor: "#e2e8f0",
            trigger: "item",
            triggerOn: "mousemove",
            formatter: function (params) {
                if (params.dataType === "edge") {
                    const pct = totalIngresos > 0 ? ((params.data.value / totalIngresos) * 100).toFixed(1) : 0;
                    return `
                        <div style="font-family: sans-serif; padding: 4px;">
                            <div style="font-size: 11px; color: #64748b; margin-bottom: 2px;">${t("sankey.flujo", lang)}</div>
                            <div style="font-weight: 600; color: #0f172a; margin-bottom: 4px;">
                                ${params.data.source} → ${params.data.target}
                            </div>
                            <div style="font-size: 14px; font-weight: bold; color: #2563eb;">
                                ${formatMrd(params.data.value)} <span style="font-size: 12px; font-weight: normal; color: #64748b;">(${pct}%)</span>
                            </div>
                        </div>
                    `;
                }
                const pctOfTotal = totalIngresos > 0 ? ((params.value / totalIngresos) * 100).toFixed(1) : 0;
                return `
                    <div style="font-family: sans-serif; padding: 4px;">
                        <div style="font-size: 11px; color: #64748b; margin-bottom: 2px;">${t("sankey.partida", lang)}</div>
                        <div style="font-weight: 600; color: #0f172a; margin-bottom: 4px;">${params.name}</div>
                        <div style="font-size: 14px; font-weight: bold; color: #0f172a;">
                            ${formatMrd(params.value)} <span style="font-size: 12px; font-weight: normal; color: #64748b;">(${pctOfTotal}%)</span>
                        </div>
                    </div>
                `;
            }
        },
        series: [
            {
                type: "sankey",
                layout: "none",
                top: "14%",
                bottom: "5%",
                left: "2%",
                right: "18%",
                nodeWidth: 20,
                nodeGap: 14,
                draggable: false,
                emphasis: {
                    focus: "adjacency"
                },
                data: nodes,
                links: links,
                lineStyle: {
                    color: "gradient",
                    curveness: 0.5,
                    opacity: 0.35
                },
                label: {
                    position: "right",
                    fontSize: 11,
                    fontWeight: 500,
                    color: oscuro ? "#e2e8f0" : "#334155",
                    formatter: function (param) {
                        return param.name;
                    }
                }
            }
        ]
    };
</script>

<div class="sankey-container my-6 p-4 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 shadow-sm" style="min-height: {height};">
    {#if dataIngresos && dataIngresos.length > 0 && dataGastos && dataGastos.length > 0}
        <ECharts {config} height={height} />
    {:else}
        <div class="flex items-center justify-center h-64 text-gray-500 dark:text-gray-400 text-sm" role="status">
            {t("sankey.cargando", lang)}
        </div>
    {/if}
</div>
