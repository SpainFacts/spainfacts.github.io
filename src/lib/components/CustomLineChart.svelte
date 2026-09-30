<script>
    import { localeActual } from "../utils.js";
    import { ECharts } from "@evidence-dev/core-components";
    import { getNumberFormatter, getCompactFormatter } from "../chart-utils.js";

    export let data;
    export let x;
    export let y; // Puede ser string o array de strings
    export let y2 = undefined;
    export let title = undefined;
    export let yAxisTitle = undefined;
    export let locale = localeActual();
    export let startingAtZero = true;

    // Preparar datos
    $: xData = data.map((d) => d[x]);
    $: yKeys = Array.isArray(y) ? y : [y];

    // Formateadores
    $: numFmt = getNumberFormatter(locale, {
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
    });
    $: compactFmt = getCompactFormatter(locale, 1);
    $: ratioFmt = getNumberFormatter(locale, {
        minimumFractionDigits: 3,
        maximumFractionDigits: 3,
    });

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
                        let valStr;
                        // Si es el eje secundario (y2), usamos formato específico (ratio en tu caso)
                        if (y2 && p.seriesName === y2) {
                            valStr = ratioFmt(p.value);
                        } else {
                            valStr = compactFmt(p.value);
                        }
                        return `${p.marker} ${p.seriesName}: <b>${valStr}</b>`;
                    })
                    .join("<br/>");
            },
        },
        legend: {
            data: [...yKeys, y2].filter(Boolean),
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
                scale: !startingAtZero,
                axisLabel: {
                    formatter: (value) => compactFmt(value),
                },
            },
            y2
                ? {
                      type: "value",
                      position: "right",
                      scale: !startingAtZero,
                      axisLabel: {
                          formatter: (value) => ratioFmt(value),
                      },
                      splitLine: { show: false },
                  }
                : undefined,
        ].filter(Boolean),
        series: [
            ...yKeys.map((key) => ({
                name: key,
                type: "line",
                data: data.map((d) => d[key]),
                symbol: "none",
            })),
            y2
                ? {
                      name: y2,
                      type: "line",
                      yAxisIndex: 1,
                      data: data.map((d) => d[y2]),
                      symbol: "none",
                      lineStyle: { type: "dashed" },
                  }
                : undefined,
        ].filter(Boolean),
    };
</script>

<div class="w-full h-80">
    <ECharts {config} />
</div>
