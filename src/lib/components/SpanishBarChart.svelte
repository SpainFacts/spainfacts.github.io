<script>
    import { ECharts } from "@evidence-dev/core-components";
    import { formatNumber, formatCompact } from "../utils.js";

    export let data;
    export let x;
    export let y;
    export let y2 = undefined;
    export let title = undefined;
    export let yAxisTitle = undefined;

    // Prepare data for ECharts
    $: xData = data.map((d) => d[x]);
    $: yData = data.map((d) => d[y]);
    $: y2Data = y2 ? data.map((d) => d[y2]) : [];

    $: config = {
        title: {
            text: title,
            left: "center",
            textStyle: { fontSize: 16 },
        },
        tooltip: {
            trigger: "axis",
            formatter: function (params) {
                return params
                    .map((p) => {
                        // Use formatNumber for percentage (y) and formatCompact for absolute (y2)
                        let valStr;
                        if (y2 && p.seriesIndex === 1) {
                            valStr = formatCompact(p.value, 1);
                        } else {
                            valStr = formatNumber(p.value, 1) + (y2 ? "%" : "");
                        }
                        return `${p.marker} ${p.seriesName}: <b>${valStr}</b>`;
                    })
                    .join("<br/>");
            },
        },
        legend: {
            data: [y, y2].filter(Boolean),
            bottom: 0,
        },
        grid: {
            left: "3%",
            right: "4%",
            bottom: "10%",
            containLabel: true,
        },
        xAxis: {
            type: "category",
            data: xData,
        },
        yAxis: [
            {
                type: "value",
                name: yAxisTitle,
                axisLabel: {
                    formatter: (value) =>
                        formatNumber(value, 0) + (y2 ? "%" : ""),
                },
            },
            y2
                ? {
                      type: "value",
                      position: "right",
                      axisLabel: {
                          formatter: (value) => formatCompact(value, 1),
                      },
                      splitLine: { show: false },
                  }
                : undefined,
        ].filter(Boolean),
        series: [
            {
                name: y,
                type: "bar",
                data: yData,
                itemStyle: { color: "#2563eb" }, // Blue
            },
            y2
                ? {
                      name: y2,
                      type: "bar",
                      yAxisIndex: 1,
                      data: y2Data,
                      itemStyle: {
                          color: "rgba(255, 165, 0, 0.3)",
                          borderColor: "rgba(255, 165, 0, 1)",
                          borderWidth: 2,
                          borderType: "dashed",
                      },
                  }
                : undefined,
        ].filter(Boolean),
    };
</script>

<div class="w-full h-80">
    <ECharts {config} />
</div>
