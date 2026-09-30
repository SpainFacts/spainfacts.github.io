<script>
    import { localeActual } from "../utils.js";
    import { ECharts } from "@evidence-dev/core-components";
    import { getCompactFormatter } from "../chart-utils.js";

    export let data;
    export let title = undefined;
    export let locale = localeActual();
    export let name = "name"; // Key for the name property in data
    export let value = "value"; // Key for the value property in data

    // Formateadores
    $: compactFmt = getCompactFormatter(locale, 2);

    $: config = {
        tooltip: {
            trigger: "item",
            formatter: ({ name, value, percent }) => {
                return `${name}: ${compactFmt(value)} (${percent}%)`;
            },
        },
        legend: {
            top: "5%",
            left: "center",
        },
        series: [
            {
                type: "pie",
                radius: ["40%", "70%"],
                avoidLabelOverlap: false,
                itemStyle: {
                    borderRadius: 10,
                    borderColor: "#fff",
                    borderWidth: 2,
                },
                label: {
                    show: true,
                    position: "inside",
                    formatter: ({ value }) => {
                        return compactFmt(value);
                    },
                },
                emphasis: {
                    label: {
                        show: true,
                        fontSize: "16",
                        fontWeight: "bold",
                    },
                },
                labelLine: {
                    show: false,
                },
                data: data.map((d) => ({
                    name: d[name],
                    value: d[value],
                })),
            },
        ],
    };
</script>

<div class="w-full h-72 flex flex-col">
    {#if title}
        <div class="text-center font-medium mb-2 shrink-0">{title}</div>
    {/if}
    <div class="flex-grow min-h-0 relative">
        <ECharts {config} />
    </div>
</div>
