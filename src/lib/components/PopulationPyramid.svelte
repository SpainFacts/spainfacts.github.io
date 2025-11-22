<script>
    import { ECharts } from "@evidence-dev/core-components";
    import { formatCompact } from "../utils.js";

    export let data;
    export let year;
    export let title = undefined;

    // Default colors if not provided
    const colorFemale = "#6a1b9a"; // Purple
    const colorMale = "#388e3c"; // Green

    // Process data to get unique age ranges sorted
    $: ageRanges = [...new Set(data.map((r) => r.RangoEdad))].sort(
        (a, b) => parseInt(a.split("-")[0]) - parseInt(b.split("-")[0]),
    );

    $: dataFemale = ageRanges.map((rango) => {
        const row = data.find(
            (row) => row.Sexo === "Mujeres" && row.RangoEdad === rango,
        );
        return row ? row.Total : 0;
    });

    $: dataMale = ageRanges.map((rango) => {
        const row = data.find(
            (row) => row.Sexo === "Hombres" && row.RangoEdad === rango,
        );
        return row ? row.Total : 0;
    });

    $: config = {
        tooltip: {
            trigger: "axis",
            axisPointer: { type: "shadow" },
            formatter: function (params) {
                return params
                    .map(
                        (param) =>
                            `${param.seriesName}: ${formatCompact(Math.abs(param.value), 1)}`,
                    )
                    .join("<br>");
            },
        },
        legend: {
            top: "5%",
            left: "center",
            data: ["Mujeres", "Hombres"],
        },
        grid: [
            { left: "5%", width: "40%", bottom: "3%", containLabel: false },
            { left: "60%", width: "40%", bottom: "3%", containLabel: false },
        ],
        xAxis: [
            {
                type: "value",
                gridIndex: 0,
                inverse: true,
                axisTick: { show: false },
                axisLine: { show: false },
                splitLine: { show: false },
                axisLabel: {
                    formatter: (value) => formatCompact(Math.abs(value), 0),
                },
            },
            {
                type: "value",
                gridIndex: 1,
                axisTick: { show: false },
                axisLine: { show: false },
                splitLine: { show: false },
                axisLabel: {
                    formatter: (value) => formatCompact(Math.abs(value), 0),
                },
            },
        ],
        yAxis: [
            {
                type: "category",
                gridIndex: 0,
                position: "right",
                inverse: false,
                axisLabel: { show: true, inside: false, interval: 0 },
                axisTick: { show: false },
                axisLine: { show: false },
                splitLine: { show: false },
                data: ageRanges,
            },
            {
                type: "category",
                gridIndex: 1,
                position: "left",
                inverse: false,
                axisLabel: { show: false },
                axisTick: { show: false },
                axisLine: { show: false },
                splitLine: { show: false },
                data: ageRanges,
            },
        ],
        series: [
            {
                name: "Mujeres",
                type: "bar",
                xAxisIndex: 0,
                yAxisIndex: 0,
                itemStyle: { color: colorFemale },
                label: { show: false },
                emphasis: { focus: "series" },
                data: dataFemale,
            },
            {
                name: "Hombres",
                type: "bar",
                xAxisIndex: 1,
                yAxisIndex: 1,
                itemStyle: { color: colorMale },
                label: { show: false },
                emphasis: { focus: "series" },
                data: dataMale,
            },
        ],
    };
</script>

<div style="text-align:center; margin-bottom: 1rem;">
    {#if title}
        <h3 class="markdown">{title}</h3>
    {:else}
        Año {year}
    {/if}
</div>

<ECharts {config} />
