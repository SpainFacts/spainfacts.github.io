<script>
    import { ECharts } from "@evidence-dev/core-components";

    export let dataIngresos = [];
    export let dataGastos = [];
    export let title = "Flujo de los Presupuestos Consolidados de España";
    export let subtitle = "Recaudación de ingresos tributarios y destino del gasto público (Millones de €)";
    export let height = "520px";

    // Format utility for tooltip
    function formatMrd(val) {
        if (!val) return "0 M€";
        return new Intl.NumberFormat('es-ES', { maximumFractionDigits: 0 }).format(val) + " M€";
    }

    $: totalIngresos = (dataIngresos || []).reduce((acc, row) => acc + (parseFloat(row.millones_euros) || 0), 0);
    $: totalGastos = (dataGastos || []).reduce((acc, row) => acc + (parseFloat(row.millones_euros) || 0), 0);

    const CENTRAL_NODE = "Presupuesto Consolidado AAPP";

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
        title: {
            text: title,
            subtext: subtitle,
            left: "center",
            textStyle: {
                fontSize: 16,
                fontWeight: "bold",
                color: "#1e293b"
            },
            subtextStyle: {
                fontSize: 12,
                color: "#64748b"
            }
        },
        tooltip: {
            trigger: "item",
            triggerOn: "mousemove",
            formatter: function (params) {
                if (params.dataType === "edge") {
                    const pct = totalIngresos > 0 ? ((params.data.value / totalIngresos) * 100).toFixed(1) : 0;
                    return `
                        <div style="font-family: sans-serif; padding: 4px;">
                            <div style="font-size: 11px; color: #64748b; margin-bottom: 2px;">Flujo Presupuestario</div>
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
                        <div style="font-size: 11px; color: #64748b; margin-bottom: 2px;">Partida</div>
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
                    color: "#334155",
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
        <div class="flex items-center justify-center h-64 text-gray-400 text-sm">
            Cargando diagrama de flujo presupuestario...
        </div>
    {/if}
</div>
